/*==============================================================
  INDEXED VECTOR SEARCH BENCHMARK
  FP32 vs FP16 vs Matryoshka-512 vs Matryoshka-256

  20 queries
  3 runs per representation

      RUN 1 = COLD
          CHECKPOINT
          DBCC DROPCLEANBUFFERS

      RUN 2 = WARM
      RUN 3 = WARM

  Uses VECTOR_SEARCH / vector index

  No HackerNewsStories join during measurement.

  Metrics from STATISTICS IO / TIME:
      - embedding-table logical reads
      - embedding-table physical reads
      - vector-index graph logical reads
      - vector-index graph physical reads
      - CPU time
      - elapsed time
==============================================================*/

SET NOCOUNT ON;
GO


/*==============================================================
  BUILD COMMON QUERY SET
==============================================================*/

DROP TABLE IF EXISTS #BenchmarkQueries;

CREATE TABLE #BenchmarkQueries
(
    query_number INT IDENTITY(1,1) PRIMARY KEY,
    hn_id BIGINT NOT NULL
);

INSERT INTO #BenchmarkQueries (hn_id)
SELECT TOP (20)
       hn_id
FROM dbo.ArticlesEmbeddings_FP32
WHERE embedding IS NOT NULL
ORDER BY embedding_id;

SELECT *
FROM #BenchmarkQueries;
GO



/*==============================================================
  FP32-768
==============================================================*/

DECLARE
    @QueryNumber INT,
    @QueryHnId BIGINT,
    @QueryVector_FP32 VECTOR(768, FLOAT32),
    @Run INT;

DECLARE QueryCursor CURSOR LOCAL FAST_FORWARD FOR
SELECT query_number, hn_id
FROM #BenchmarkQueries
ORDER BY query_number;

OPEN QueryCursor;

FETCH NEXT FROM QueryCursor
INTO @QueryNumber, @QueryHnId;

WHILE @@FETCH_STATUS = 0
BEGIN

    /* Load query vector before benchmark */
    SELECT
        @QueryVector_FP32 = embedding
    FROM dbo.ArticlesEmbeddings_FP32
    WHERE hn_id = @QueryHnId;


    SET @Run = 1;

    WHILE @Run <= 3
    BEGIN

        PRINT '';
        PRINT '============================================================';
        PRINT CONCAT(
            'QUERY ', @QueryNumber,
            ' | RUN ', @Run,
            ' | FP32-768',
            ' | INDEXED',
            ' | HN_ID = ', @QueryHnId
        );
        PRINT '============================================================';


        /*--------------------------------------
          RUN 1 = COLD
        --------------------------------------*/

        IF @Run = 1
        BEGIN
            CHECKPOINT;
            DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
        END;


        SET STATISTICS IO ON;
        SET STATISTICS TIME ON;


        SELECT
            e.hn_id,
            vs.distance
        FROM VECTOR_SEARCH
        (
            TABLE      = dbo.ArticlesEmbeddings_FP32 AS e,
            COLUMN     = embedding,
            SIMILAR_TO = @QueryVector_FP32,
            METRIC     = 'cosine',
            TOP_N      = 11
        ) AS vs
        WHERE e.hn_id <> @QueryHnId
        ORDER BY vs.distance;


        SET STATISTICS TIME OFF;
        SET STATISTICS IO OFF;


        SET @Run += 1;

    END;


    FETCH NEXT FROM QueryCursor
    INTO @QueryNumber, @QueryHnId;

END;

CLOSE QueryCursor;
DEALLOCATE QueryCursor;
GO



/*==============================================================
  FP16-768
==============================================================*/

DECLARE
    @QueryNumber INT,
    @QueryHnId BIGINT,
    @QueryVector_FP16 VECTOR(768, FLOAT16),
    @Run INT;

DECLARE QueryCursor CURSOR LOCAL FAST_FORWARD FOR
SELECT query_number, hn_id
FROM #BenchmarkQueries
ORDER BY query_number;

OPEN QueryCursor;

FETCH NEXT FROM QueryCursor
INTO @QueryNumber, @QueryHnId;

WHILE @@FETCH_STATUS = 0
BEGIN

    SELECT
        @QueryVector_FP16 = embedding
    FROM dbo.ArticlesEmbeddings_FP16
    WHERE hn_id = @QueryHnId;


    SET @Run = 1;

    WHILE @Run <= 3
    BEGIN

        PRINT '';
        PRINT '============================================================';
        PRINT CONCAT(
            'QUERY ', @QueryNumber,
            ' | RUN ', @Run,
            ' | FP16-768',
            ' | INDEXED',
            ' | HN_ID = ', @QueryHnId
        );
        PRINT '============================================================';


        IF @Run = 1
        BEGIN
            CHECKPOINT;
            DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
        END;


        SET STATISTICS IO ON;
        SET STATISTICS TIME ON;


        SELECT
            e.hn_id,
            vs.distance
        FROM VECTOR_SEARCH
        (
            TABLE      = dbo.ArticlesEmbeddings_FP16 AS e,
            COLUMN     = embedding,
            SIMILAR_TO = @QueryVector_FP16,
            METRIC     = 'cosine',
            TOP_N      = 11
        ) AS vs
        WHERE e.hn_id <> @QueryHnId
        ORDER BY vs.distance;


        SET STATISTICS TIME OFF;
        SET STATISTICS IO OFF;


        SET @Run += 1;

    END;


    FETCH NEXT FROM QueryCursor
    INTO @QueryNumber, @QueryHnId;

END;

CLOSE QueryCursor;
DEALLOCATE QueryCursor;
GO



/*==============================================================
  MATRYOSHKA-512 FP16
==============================================================*/

DECLARE
    @QueryNumber INT,
    @QueryHnId BIGINT,
    @QueryVector_MRL512 VECTOR(512, FLOAT16),
    @Run INT;

DECLARE QueryCursor CURSOR LOCAL FAST_FORWARD FOR
SELECT query_number, hn_id
FROM #BenchmarkQueries
ORDER BY query_number;

OPEN QueryCursor;

FETCH NEXT FROM QueryCursor
INTO @QueryNumber, @QueryHnId;

WHILE @@FETCH_STATUS = 0
BEGIN

    SELECT
        @QueryVector_MRL512 = embedding
    FROM dbo.ArticlesEmbeddings_Matryoshka512_FP16
    WHERE hn_id = @QueryHnId;


    SET @Run = 1;

    WHILE @Run <= 3
    BEGIN

        PRINT '';
        PRINT '============================================================';
        PRINT CONCAT(
            'QUERY ', @QueryNumber,
            ' | RUN ', @Run,
            ' | MRL-FP16-512',
            ' | INDEXED',
            ' | HN_ID = ', @QueryHnId
        );
        PRINT '============================================================';


        IF @Run = 1
        BEGIN
            CHECKPOINT;
            DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
        END;


        SET STATISTICS IO ON;
        SET STATISTICS TIME ON;


        SELECT
            e.hn_id,
            vs.distance
        FROM VECTOR_SEARCH
        (
            TABLE      = dbo.ArticlesEmbeddings_Matryoshka512_FP16 AS e,
            COLUMN     = embedding,
            SIMILAR_TO = @QueryVector_MRL512,
            METRIC     = 'cosine',
            TOP_N      = 11
        ) AS vs
        WHERE e.hn_id <> @QueryHnId
        ORDER BY vs.distance;


        SET STATISTICS TIME OFF;
        SET STATISTICS IO OFF;


        SET @Run += 1;

    END;


    FETCH NEXT FROM QueryCursor
    INTO @QueryNumber, @QueryHnId;

END;

CLOSE QueryCursor;
DEALLOCATE QueryCursor;
GO



/*==============================================================
  MATRYOSHKA-256 FP16
==============================================================*/

DECLARE
    @QueryNumber INT,
    @QueryHnId BIGINT,
    @QueryVector_MRL256 VECTOR(256, FLOAT16),
    @Run INT;

DECLARE QueryCursor CURSOR LOCAL FAST_FORWARD FOR
SELECT query_number, hn_id
FROM #BenchmarkQueries
ORDER BY query_number;

OPEN QueryCursor;

FETCH NEXT FROM QueryCursor
INTO @QueryNumber, @QueryHnId;

WHILE @@FETCH_STATUS = 0
BEGIN

    SELECT
        @QueryVector_MRL256 = embedding
    FROM dbo.ArticlesEmbeddings_Matryoshka256_FP16
    WHERE hn_id = @QueryHnId;


    SET @Run = 1;

    WHILE @Run <= 3
    BEGIN

        PRINT '';
        PRINT '============================================================';
        PRINT CONCAT(
            'QUERY ', @QueryNumber,
            ' | RUN ', @Run,
            ' | MRL-FP16-256',
            ' | INDEXED',
            ' | HN_ID = ', @QueryHnId
        );
        PRINT '============================================================';


        IF @Run = 1
        BEGIN
            CHECKPOINT;
            DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
        END;


        SET STATISTICS IO ON;
        SET STATISTICS TIME ON;


        SELECT
            e.hn_id,
            vs.distance
        FROM VECTOR_SEARCH
        (
            TABLE      = dbo.ArticlesEmbeddings_Matryoshka256_FP16 AS e,
            COLUMN     = embedding,
            SIMILAR_TO = @QueryVector_MRL256,
            METRIC     = 'cosine',
            TOP_N      = 11
        ) AS vs
        WHERE e.hn_id <> @QueryHnId
        ORDER BY vs.distance;


        SET STATISTICS TIME OFF;
        SET STATISTICS IO OFF;


        SET @Run += 1;

    END;


    FETCH NEXT FROM QueryCursor
    INTO @QueryNumber, @QueryHnId;

END;

CLOSE QueryCursor;
DEALLOCATE QueryCursor;


PRINT '';
PRINT '============================================================';
PRINT 'INDEXED VECTOR SEARCH BENCHMARK COMPLETE';
PRINT '20 query items × 4 representations × 3 measured runs';
PRINT 'RUN 1 = COLD | RUNS 2 + 3 = WARM';
PRINT '============================================================';
GO