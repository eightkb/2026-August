/*==============================================================
  FP32 vs FP16 — INDEXED VECTOR SEARCH DEMO

  Same query
  Same dimensions
  Same TOP_N
  Different precision

  Runs:
      1. FP32 COLD
      2. FP16 COLD
      3. FP32 WARM
      4. FP16 WARM

  Uses VECTOR_SEARCH / Vector Index
==============================================================*/

SET NOCOUNT ON;

DECLARE @QueryHnId BIGINT = 18349232;

DECLARE @QueryVector_FP32 VECTOR(768, FLOAT32);
DECLARE @QueryVector_FP16 VECTOR(768, FLOAT16);


/*==============================================================
  LOAD BOTH QUERY VECTORS BEFORE MEASUREMENT
==============================================================*/

SELECT
    @QueryVector_FP32 = embedding
FROM dbo.ArticlesEmbeddings_FP32
WHERE hn_id = @QueryHnId;


SELECT
    @QueryVector_FP16 = embedding
FROM dbo.ArticlesEmbeddings_FP16
WHERE hn_id = @QueryHnId;


/*==============================================================
  1. FP32 — COLD
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
    SIMILAR_TO = @QueryVector_FP32,
    METRIC     = 'cosine',
    TOP_N      = 11
) AS vs
WHERE e.hn_id <> @QueryHnId
ORDER BY vs.distance;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;


/*==============================================================
  2. FP16 — COLD

  Clear cache again so FP16 also gets a true cold run.
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'FP16-768 — INDEXED SEARCH — COLD';
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


/*==============================================================
  PREPARE BOTH REPRESENTATIONS FOR WARM RUNS

  IMPORTANT:
  Because we cleared the cache immediately before the FP16 cold
  run, FP32 is no longer guaranteed to be warm.

  Run each search once with statistics OFF to warm both sets of
  pages before measuring the warm executions.
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'WARMING FP32 + FP16';
PRINT '============================================';


/* Warm FP32 */

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


/* Warm FP16 */

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


/*==============================================================
  3. FP32 — WARM
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
    SIMILAR_TO = @QueryVector_FP32,
    METRIC     = 'cosine',
    TOP_N      = 11
) AS vs
WHERE e.hn_id <> @QueryHnId
ORDER BY vs.distance;

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;


/*==============================================================
  4. FP16 — WARM
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'FP16-768 — INDEXED SEARCH — WARM';
PRINT '============================================';

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