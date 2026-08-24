/*==============================================================================
    EXACT VECTOR SEARCH PERFORMANCE BENCHMARK
    NO VECTOR INDEX USED

    Method
    ------
    - Automatically chooses TOP 20 hn_id values
    - Same 20 query items used for every representation
    - 3 measured repetitions per query
    - TOP 10 nearest neighbors
    - Uses VECTOR_DISTANCE: exact brute-force search
    - VECTOR INDEX IS NOT USED
    - STATISTICS IO/TIME enabled ONLY for measured search
==============================================================================*/

SET NOCOUNT ON;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

DECLARE @K           INT = 10;
DECLARE @Repetitions INT = 3;


/*==============================================================================
    STEP 1
    Build benchmark query set

    TOP 20 hn_id values that exist in ALL FOUR representations.
==============================================================================*/

DROP TABLE IF EXISTS #BenchmarkQueries;

CREATE TABLE #BenchmarkQueries
(
    query_number INT    NOT NULL PRIMARY KEY,
    hn_id        BIGINT NOT NULL UNIQUE
);

INSERT INTO #BenchmarkQueries
(
    query_number,
    hn_id
)
SELECT TOP (20)

    ROW_NUMBER() OVER
    (
        ORDER BY fp32.hn_id
    ) AS query_number,

    fp32.hn_id

FROM dbo.ArticlesEmbeddings_FP32 AS fp32

INNER JOIN dbo.ArticlesEmbeddings_FP16 AS fp16
    ON fp16.hn_id = fp32.hn_id

INNER JOIN dbo.ArticlesEmbeddings_Matryoshka512_FP16 AS m512
    ON m512.hn_id = fp32.hn_id

INNER JOIN dbo.ArticlesEmbeddings_Matryoshka256_FP16 AS m256
    ON m256.hn_id = fp32.hn_id

ORDER BY
    fp32.hn_id;


/*==============================================================================
    Optional verification
==============================================================================*/

SELECT
    b.query_number,
    b.hn_id,
    s.title
FROM #BenchmarkQueries AS b
LEFT JOIN dbo.HackerNewsStories AS s
    ON s.hn_id = b.hn_id
ORDER BY
    b.query_number;


/*==============================================================================
    Variables
==============================================================================*/

DECLARE
    @QueryNumber INT,
    @QueryHnId   BIGINT,
    @QueryTitle  NVARCHAR(1000),
    @Rep         INT;


/*==============================================================================
    Loop through SAME 20 queries
==============================================================================*/

DECLARE QueryCursor CURSOR LOCAL FAST_FORWARD
FOR
SELECT
    query_number,
    hn_id
FROM #BenchmarkQueries
ORDER BY
    query_number;

OPEN QueryCursor;

FETCH NEXT FROM QueryCursor
INTO @QueryNumber, @QueryHnId;

WHILE @@FETCH_STATUS = 0
BEGIN

    SELECT
        @QueryTitle = s.title
    FROM dbo.HackerNewsStories AS s
    WHERE s.hn_id = @QueryHnId;


    /*==========================================================================
        FP32-768
        Exact search - no vector index
    ==========================================================================*/

    DECLARE @Vector_FP32 VECTOR(768);

    SELECT
        @Vector_FP32 = e.embedding
    FROM dbo.ArticlesEmbeddings_FP32 AS e
    WHERE e.hn_id = @QueryHnId;

    SET @Rep = 1;

    WHILE @Rep <= @Repetitions
    BEGIN

        PRINT '';
        PRINT '============================================================';
        PRINT CONCAT
        (
            'QUERY ', @QueryNumber,
            ' | RUN ', @Rep,
            ' | FP32-768',
            ' | EXACT / NO INDEX',
            ' | HN_ID = ', @QueryHnId
        );
        PRINT CONCAT('TITLE: ', COALESCE(@QueryTitle, N''));
        PRINT '============================================================';

        SET STATISTICS IO ON;
        SET STATISTICS TIME ON;

        SELECT TOP (@K + 1)
            e.hn_id,
            s.title,
            VECTOR_DISTANCE
            (
                'cosine',
                e.embedding,
                @Vector_FP32
            ) AS distance

        FROM dbo.ArticlesEmbeddings_FP32 AS e

        INNER JOIN dbo.HackerNewsStories AS s
            ON s.hn_id = e.hn_id

        ORDER BY
            VECTOR_DISTANCE
            (
                'cosine',
                e.embedding,
                @Vector_FP32
            );

        SET STATISTICS TIME OFF;
        SET STATISTICS IO OFF;

        SET @Rep += 1;

    END;


    /*==========================================================================
        FP16-768
        Exact search - no vector index
    ==========================================================================*/

    DECLARE @Vector_FP16 VECTOR(768, FLOAT16);

    SELECT
        @Vector_FP16 = e.embedding
    FROM dbo.ArticlesEmbeddings_FP16 AS e
    WHERE e.hn_id = @QueryHnId;

    SET @Rep = 1;

    WHILE @Rep <= @Repetitions
    BEGIN

        PRINT '';
        PRINT '============================================================';
        PRINT CONCAT
        (
            'QUERY ', @QueryNumber,
            ' | RUN ', @Rep,
            ' | FP16-768',
            ' | EXACT / NO INDEX',
            ' | HN_ID = ', @QueryHnId
        );
        PRINT CONCAT('TITLE: ', COALESCE(@QueryTitle, N''));
        PRINT '============================================================';

        SET STATISTICS IO ON;
        SET STATISTICS TIME ON;

        SELECT TOP (@K + 1)
            e.hn_id,
            s.title,
            VECTOR_DISTANCE
            (
                'cosine',
                e.embedding,
                @Vector_FP16
            ) AS distance

        FROM dbo.ArticlesEmbeddings_FP16 AS e

        INNER JOIN dbo.HackerNewsStories AS s
            ON s.hn_id = e.hn_id

        ORDER BY
            VECTOR_DISTANCE
            (
                'cosine',
                e.embedding,
                @Vector_FP16
            );

        SET STATISTICS TIME OFF;
        SET STATISTICS IO OFF;

        SET @Rep += 1;

    END;


    /*==========================================================================
        MRL-FP16-512
        Exact search - no vector index
    ==========================================================================*/

    DECLARE @Vector_MRL512 VECTOR(512, FLOAT16);

    SELECT
        @Vector_MRL512 = e.embedding
    FROM dbo.ArticlesEmbeddings_Matryoshka512_FP16 AS e
    WHERE e.hn_id = @QueryHnId;

    SET @Rep = 1;

    WHILE @Rep <= @Repetitions
    BEGIN

        PRINT '';
        PRINT '============================================================';
        PRINT CONCAT
        (
            'QUERY ', @QueryNumber,
            ' | RUN ', @Rep,
            ' | MRL-FP16-512',
            ' | EXACT / NO INDEX',
            ' | HN_ID = ', @QueryHnId
        );
        PRINT CONCAT('TITLE: ', COALESCE(@QueryTitle, N''));
        PRINT '============================================================';

        SET STATISTICS IO ON;
        SET STATISTICS TIME ON;

        SELECT TOP (@K + 1)
            e.hn_id,
            s.title,
            VECTOR_DISTANCE
            (
                'cosine',
                e.embedding,
                @Vector_MRL512
            ) AS distance

        FROM dbo.ArticlesEmbeddings_Matryoshka512_FP16 AS e

        INNER JOIN dbo.HackerNewsStories AS s
            ON s.hn_id = e.hn_id

        ORDER BY
            VECTOR_DISTANCE
            (
                'cosine',
                e.embedding,
                @Vector_MRL512
            );

        SET STATISTICS TIME OFF;
        SET STATISTICS IO OFF;

        SET @Rep += 1;

    END;


    /*==========================================================================
        MRL-FP16-256
        Exact search - no vector index
    ==========================================================================*/

    DECLARE @Vector_MRL256 VECTOR(256, FLOAT16);

    SELECT
        @Vector_MRL256 = e.embedding
    FROM dbo.ArticlesEmbeddings_Matryoshka256_FP16 AS e
    WHERE e.hn_id = @QueryHnId;

    SET @Rep = 1;

    WHILE @Rep <= @Repetitions
    BEGIN

        PRINT '';
        PRINT '============================================================';
        PRINT CONCAT
        (
            'QUERY ', @QueryNumber,
            ' | RUN ', @Rep,
            ' | MRL-FP16-256',
            ' | EXACT / NO INDEX',
            ' | HN_ID = ', @QueryHnId
        );
        PRINT CONCAT('TITLE: ', COALESCE(@QueryTitle, N''));
        PRINT '============================================================';

        SET STATISTICS IO ON;
        SET STATISTICS TIME ON;

        SELECT TOP (@K + 1)
            e.hn_id,
            s.title,
            VECTOR_DISTANCE
            (
                'cosine',
                e.embedding,
                @Vector_MRL256
            ) AS distance

        FROM dbo.ArticlesEmbeddings_Matryoshka256_FP16 AS e

        INNER JOIN dbo.HackerNewsStories AS s
            ON s.hn_id = e.hn_id

        ORDER BY
            VECTOR_DISTANCE
            (
                'cosine',
                e.embedding,
                @Vector_MRL256
            );

        SET STATISTICS TIME OFF;
        SET STATISTICS IO OFF;

        SET @Rep += 1;

    END;


    FETCH NEXT FROM QueryCursor
    INTO @QueryNumber, @QueryHnId;

END;


/*==============================================================================
    CLEANUP
==============================================================================*/

CLOSE QueryCursor;
DEALLOCATE QueryCursor;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

PRINT '';
PRINT '============================================================';
PRINT 'EXACT SEARCH BENCHMARK COMPLETE';
PRINT 'NO VECTOR INDEX USED';
PRINT '20 query items × 4 representations × 3 measured runs';
PRINT '============================================================';

GO