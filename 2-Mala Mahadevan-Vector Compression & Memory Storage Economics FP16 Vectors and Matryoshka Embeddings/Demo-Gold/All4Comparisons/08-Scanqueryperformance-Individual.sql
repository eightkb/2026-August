
DECLARE @QueryHnId BIGINT = 18346257;
DECLARE @NumberOfNeighbors INT = 10;

DECLARE @QueryVector VECTOR(768);
DECLARE @QueryTitle NVARCHAR(1000);


SELECT
    @QueryVector = e.embedding,
    @QueryTitle = s.title
FROM dbo.ArticlesEmbeddings_FP32 AS e
INNER JOIN dbo.HackerNewsStories AS s
    ON s.hn_id = e.hn_id
WHERE e.hn_id = @QueryHnId;




SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SELECT TOP (@NumberOfNeighbors)
    @QueryTitle AS query_title,
    ROW_NUMBER() OVER
    (
        ORDER BY
            VECTOR_DISTANCE
            (
                'cosine',
                @QueryVector,
                e.embedding
            ),
            s.hn_id
    ) AS neighbor_rank,
    s.title AS neighbor_title,
    CAST
    (
        VECTOR_DISTANCE
        (
            'cosine',
            @QueryVector,
            e.embedding
        )
        AS DECIMAL(9,6)
    ) AS cosine_distance
FROM dbo.ArticlesEmbeddings_FP32 AS e
INNER JOIN dbo.HackerNewsStories AS s
    ON s.hn_id = e.hn_id
ORDER BY
    neighbor_rank;
SET STATISTICS IO Off;
SET STATISTICS TIME Off;

GO
DECLARE @QueryHnId BIGINT = 18346257;
DECLARE @NumberOfNeighbors INT = 10;

DECLARE @QueryVector VECTOR(768, FLOAT16);
DECLARE @QueryTitle NVARCHAR(1000);


SELECT
    @QueryVector = e.embedding,
    @QueryTitle = s.title
FROM dbo.ArticlesEmbeddings_FP16 AS e
INNER JOIN dbo.HackerNewsStories AS s
    ON s.hn_id = e.hn_id
WHERE e.hn_id = @QueryHnId;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT TOP (@NumberOfNeighbors)
    @QueryTitle AS query_title,
    ROW_NUMBER() OVER
    (
        ORDER BY
            VECTOR_DISTANCE
            (
                'cosine',
                @QueryVector,
                e.embedding
            ),
            s.hn_id
    ) AS neighbor_rank,
    s.title AS neighbor_title,
    CAST
    (
        VECTOR_DISTANCE
        (
            'cosine',
            @QueryVector,
            e.embedding
        )
        AS DECIMAL(9,6)
    ) AS cosine_distance
FROM dbo.ArticlesEmbeddings_FP16 AS e
INNER JOIN dbo.HackerNewsStories AS s
    ON s.hn_id = e.hn_id
ORDER BY
    neighbor_rank;
SET STATISTICS IO Off;
SET STATISTICS TIME Off;

GO
DECLARE @QueryHnId BIGINT = 18346257;
DECLARE @NumberOfNeighbors INT = 10;

DECLARE @QueryVector VECTOR(512, FLOAT16);
DECLARE @QueryTitle NVARCHAR(1000);

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    @QueryVector = e.embedding,
    @QueryTitle = s.title
FROM dbo.ArticlesEmbeddings_Matryoshka512_FP16 AS e
INNER JOIN dbo.HackerNewsStories AS s
    ON s.hn_id = e.hn_id
WHERE e.hn_id = @QueryHnId;


SELECT TOP (@NumberOfNeighbors)
    @QueryTitle AS query_title,
    ROW_NUMBER() OVER
    (
        ORDER BY
            VECTOR_DISTANCE
            (
                'cosine',
                @QueryVector,
                e.embedding
            ),
            s.hn_id
    ) AS neighbor_rank,
    s.title AS neighbor_title,
    CAST
    (
        VECTOR_DISTANCE
        (
            'cosine',
            @QueryVector,
            e.embedding
        )
        AS DECIMAL(9,6)
    ) AS cosine_distance
FROM dbo.ArticlesEmbeddings_Matryoshka512_FP16 AS e
INNER JOIN dbo.HackerNewsStories AS s
    ON s.hn_id = e.hn_id
ORDER BY
    neighbor_rank;
SET STATISTICS IO Off;
SET STATISTICS TIME Off;

GO
DECLARE @QueryHnId BIGINT = 18346257;
DECLARE @NumberOfNeighbors INT = 10;

DECLARE @QueryVector VECTOR(256, FLOAT16);
DECLARE @QueryTitle NVARCHAR(1000);

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    @QueryVector = e.embedding,
    @QueryTitle = s.title
FROM dbo.ArticlesEmbeddings_Matryoshka256_FP16 AS e
INNER JOIN dbo.HackerNewsStories AS s
    ON s.hn_id = e.hn_id
WHERE e.hn_id = @QueryHnId;


SELECT TOP (@NumberOfNeighbors)
    @QueryTitle AS query_title,
    ROW_NUMBER() OVER
    (
        ORDER BY
            VECTOR_DISTANCE
            (
                'cosine',
                @QueryVector,
                e.embedding
            ),
            s.hn_id
    ) AS neighbor_rank,
    s.title AS neighbor_title,
    CAST
    (
        VECTOR_DISTANCE
        (
            'cosine',
            @QueryVector,
            e.embedding
        )
        AS DECIMAL(9,6)
    ) AS cosine_distance
FROM dbo.ArticlesEmbeddings_Matryoshka256_FP16 AS e
INNER JOIN dbo.HackerNewsStories AS s
    ON s.hn_id = e.hn_id
ORDER BY
    neighbor_rank;
SET STATISTICS IO Off;
SET STATISTICS TIME Off;

GO
