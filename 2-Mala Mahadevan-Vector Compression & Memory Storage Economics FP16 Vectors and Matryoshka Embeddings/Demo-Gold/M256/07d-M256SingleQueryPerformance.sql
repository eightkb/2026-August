/*==============================================================
  FP32 vs MATRYOSHKA-256 — INDEXED VECTOR SEARCH DEMO

  Same query
  Same TOP_N
  Different representation

  Runs:
      1. FP32 COLD
      2. MRL-256 COLD
      3. Warm both
      4. FP32 WARM
      5. MRL-256 WARM

  Uses VECTOR_SEARCH / Vector Index
==============================================================*/

SET NOCOUNT ON;

DECLARE @QueryHnId BIGINT = 18349232;

DECLARE @QueryVector_FP32   VECTOR(768, FLOAT32);
DECLARE @QueryVector_MRL256 VECTOR(256, FLOAT16);


/*==============================================================
  LOAD BOTH QUERY VECTORS BEFORE MEASUREMENT
==============================================================*/

SELECT
    @QueryVector_FP32 = embedding
FROM dbo.ArticlesEmbeddings_FP32
WHERE hn_id = @QueryHnId;


SELECT
    @QueryVector_MRL256 = embedding
FROM dbo.ArticlesEmbeddings_Matryoshka256_FP16
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
  2. MATRYOSHKA-256 — COLD
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'MATRYOSHKA-256 — INDEXED SEARCH — COLD';
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


/*==============================================================
  PREPARE BOTH REPRESENTATIONS FOR WARM RUNS

  The second cold run cleared the buffer pool again,
  so explicitly warm both representations before measurement.
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'WARMING FP32 + MATRYOSHKA-256';
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


/* Warm Matryoshka-256 */

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
  4. MATRYOSHKA-256 — WARM
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'MATRYOSHKA-256 — INDEXED SEARCH — WARM';
PRINT '============================================';

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