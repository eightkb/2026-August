DECLARE @QueryHnId BIGINT = 18349232; -- replace
DECLARE @QueryVector32 VECTOR(768, FLOAT32),@QueryVector16 VECTOR(768, FLOAT16);

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

DECLARE @CTR INT = 0;

SELECT
    @QueryVector32 = embedding
FROM dbo.ArticlesEmbeddings_FP32
WHERE hn_id = @QueryHnId;

CHECKPOINT;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;

SET @CTR = 1;
WHILE (@CTR <= 20)
BEGIN
    SELECT
    e.hn_id,
    r.distance
    FROM VECTOR_SEARCH
    (
        TABLE      = dbo.ArticlesEmbeddings_FP32 AS e,
        COLUMN     = embedding,
        SIMILAR_TO = @QueryVector32,
        METRIC     = 'cosine',
        TOP_N      = 11
    ) AS r
    WHERE e.hn_id <> @QueryHnId
    ORDER BY
        r.distance

    SET @CTR = @ctr + 1;
END
GO
DECLARE @QueryHnId BIGINT = 18349232; -- replace
DECLARE @QueryVector32 VECTOR(768, FLOAT32),@QueryVector16 VECTOR(768, FLOAT16);

DECLARE @CTR INT = 0;

SELECT
    @QueryVector16 = embedding
FROM dbo.ArticlesEmbeddings_FP16
WHERE hn_id = @QueryHnId;

CHECKPOINT;
DBCC DROPCLEANBUFFERS;

SET @CTR = 1;
WHILE (@CTR <= 20)
BEGIN
    SELECT
    e.hn_id,
    r.distance
    FROM VECTOR_SEARCH
    (
        TABLE      = dbo.ArticlesEmbeddings_FP16 AS e,
        COLUMN     = embedding,
        SIMILAR_TO = @QueryVector16,
        METRIC     = 'cosine',
        TOP_N      = 11
    ) AS r
    WHERE e.hn_id <> @QueryHnId
    ORDER BY
        r.distance

    SET @CTR = @ctr + 1;
END
GO
