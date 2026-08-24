/*==============================================================
  FP32-768 INDEXED VECTOR SEARCH DEMO
  Single query
  Cold run + warm run
  Uses VECTOR_SEARCH / Vector Index
==============================================================*/

SET NOCOUNT ON;

DECLARE @QueryHnId BIGINT = 1--18349232;
DECLARE @QueryVector VECTOR(768, FLOAT32);


/*--------------------------------------------------------------
  Load query vector BEFORE measurement
--------------------------------------------------------------*/

SELECT
    @QueryVector = embedding
FROM dbo.ArticlesEmbeddings_FP32
WHERE hn_id = @QueryHnId;


/*==============================================================
  COLD RUN
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'FP32-768 — INDEXED SEARCH — COLD';
PRINT '============================================';

CHECKPOINT;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    e.hn_id,
    vs.distance
FROM VECTOR_SEARCH
(
    TABLE      = dbo.ArticlesEmbeddings_FP32 AS e,
    COLUMN     = embedding,
    SIMILAR_TO = @QueryVector,
    METRIC     = 'cosine',
    TOP_N      = 11
) AS vs
WHERE e.hn_id <> @QueryHnId
ORDER BY vs.distance;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;


/*==============================================================
  WARM RUN
  Same exact indexed search.
  No cache clear.
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'FP32-768 — INDEXED SEARCH — WARM';
PRINT '============================================';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT
    e.hn_id,
    vs.distance
FROM VECTOR_SEARCH
(
    TABLE      = dbo.ArticlesEmbeddings_FP32 AS e,
    COLUMN     = embedding,
    SIMILAR_TO = @QueryVector,
    METRIC     = 'cosine',
    TOP_N      = 11
) AS vs
WHERE e.hn_id <> @QueryHnId
ORDER BY vs.distance;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;