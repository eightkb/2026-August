DECLARE @QueryHnId BIGINT = 18349232; -- replace
DECLARE @QueryVector32 VECTOR(768, FLOAT32),@QueryVector16 VECTOR(768, FLOAT16),
@QueryVector512 VECTOR(512, FLOAT16), @QueryVector256 VECTOR(256, FLOAT16);

DECLARE @CTR INT = 0;

DECLARE @QueryTitle NVARCHAR(MAX)

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT
    @QueryVector32 = embedding,
    @QueryTitle = p.title
FROM dbo.ArticlesEmbeddings_FP32 a
INNER JOIN dbo.HackerNewsStories AS p
ON a.hn_id = p.hn_id
WHERE a.hn_id = @QueryHnId;


CHECKPOINT;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SET @CTR = 1;
WHILE (@CTR <= 20)
BEGIN
SELECT 
            e.hn_id,
            @Querytitle as Reference,
            s.title,
            vs.distance
        FROM VECTOR_SEARCH
        (
            TABLE      = dbo.ArticlesEmbeddings_FP32 AS e,
            COLUMN     = embedding,
            SIMILAR_TO = @QueryVector32,
            METRIC     = 'cosine',
            TOP_N      = 11
        ) AS vs
        
        INNER JOIN dbo.HackerNewsStories AS s
            ON s.hn_id = e.hn_id
        WHERE s.hn_id <> @QueryHnId
        ORDER BY

           vs.distance;
    SET @CTR = @ctr + 1;
END
SET STATISTICS IO Off;
SET STATISTICS TIME Off;

GO
DECLARE @QueryHnId BIGINT = 18349232; -- replace
DECLARE @QueryVector16 VECTOR(768, FLOAT16)
DECLARE @QueryTitle NVARCHAR(MAX)

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT
    @QueryVector16 = embedding,
    @QueryTitle = p.title
FROM dbo.ArticlesEmbeddings_FP16 a
INNER JOIN dbo.HackerNewsStories AS p
ON a.hn_id = p.hn_id
WHERE a.hn_id = @QueryHnId;

DECLARE @CTR INT = 0;

CHECKPOINT;
DBCC DROPCLEANBUFFERS;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SET @CTR = 1;
WHILE (@CTR <= 20)
BEGIN
SELECT 
            e.hn_id,
            @Querytitle as Reference,
            s.title,
            vs.distance
        FROM VECTOR_SEARCH
        (
            TABLE      = dbo.ArticlesEmbeddings_FP16 AS e,
            COLUMN     = embedding,
            SIMILAR_TO = @QueryVector16,
            METRIC     = 'cosine',
            TOP_N      = 11
        ) AS vs
        
        INNER JOIN dbo.HackerNewsStories AS s
            ON s.hn_id = e.hn_id
        WHERE s.hn_id <> @QueryHnId
        ORDER BY
            vs.distance;

    SET @CTR = @ctr + 1;
END
SET STATISTICS IO Off;
SET STATISTICS TIME Off;

GO
DECLARE @QueryHnId BIGINT = 18349232; 
DECLARE @QueryVector512 VECTOR(512, FLOAT16)

DECLARE @CTR INT = 0;
DECLARE @QueryTitle NVARCHAR(MAX)

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT
    @QueryVector512 = embedding,
    @QueryTitle = p.title
FROM dbo.ArticlesEmbeddings_Matryoshka512_FP16 a
INNER JOIN dbo.HackerNewsStories AS p
ON a.hn_id = p.hn_id
WHERE a.hn_id = @QueryHnId;

CHECKPOINT;
DBCC DROPCLEANBUFFERS;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SET @CTR = 1;
WHILE (@CTR <= 20)
BEGIN
    SELECT 
            e.hn_id,
            @Querytitle as Reference,
            s.title,
            vs.distance
        FROM VECTOR_SEARCH
        (
            TABLE      = dbo.ArticlesEmbeddings_Matryoshka512_FP16 AS e,
            COLUMN     = embedding,
            SIMILAR_TO = @QueryVector512,
            METRIC     = 'cosine',
            TOP_N      = 11
        ) AS vs
        
        INNER JOIN dbo.HackerNewsStories AS s
            ON s.hn_id = e.hn_id
        WHERE s.hn_id <> @QueryHnId
        ORDER BY
            vs.distance;

    SET @CTR = @ctr + 1;
END
SET STATISTICS IO Off;
SET STATISTICS TIME Off;
