/*==============================================================
  FP32 vs FP16 — EXACT / TABLE SCAN VECTOR SEARCH DEMO

  Same query
  Same dimensions
  Same TOP 10
  Different precision

  Runs:
      1. FP32 COLD
      2. FP16 COLD
      3. Warm both
      4. FP32 WARM
      5. FP16 WARM

  NO VECTOR INDEX
  Uses VECTOR_DISTANCE / Exact Search
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
  1. FP32 — COLD EXACT SEARCH
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'FP32-768 — EXACT SEARCH — COLD';
PRINT 'NO VECTOR INDEX';
PRINT '============================================';

CHECKPOINT;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT TOP (10)
    e.hn_id,
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_FP32
    ) AS distance
FROM dbo.ArticlesEmbeddings_FP32 AS e
WHERE e.hn_id <> @QueryHnId
  AND e.embedding IS NOT NULL
ORDER BY
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_FP32
    );

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;


/*==============================================================
  2. FP16 — COLD EXACT SEARCH
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'FP16-768 — EXACT SEARCH — COLD';
PRINT 'NO VECTOR INDEX';
PRINT '============================================';

CHECKPOINT;
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT TOP (10)
    e.hn_id,
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_FP16
    ) AS distance
FROM dbo.ArticlesEmbeddings_FP16 AS e
WHERE e.hn_id <> @QueryHnId
  AND e.embedding IS NOT NULL
ORDER BY
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_FP16
    );

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;


/*==============================================================
  WARM BOTH REPRESENTATIONS

  The FP16 cold run cleared the buffer pool again,
  so explicitly warm both tables before measuring warm runs.
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'WARMING FP32 + FP16';
PRINT '============================================';


/* Warm FP32 */

SELECT TOP (10)
    e.hn_id,
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_FP32
    ) AS distance
FROM dbo.ArticlesEmbeddings_FP32 AS e
WHERE e.hn_id <> @QueryHnId
  AND e.embedding IS NOT NULL
ORDER BY
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_FP32
    );


/* Warm FP16 */

SELECT TOP (10)
    e.hn_id,
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_FP16
    ) AS distance
FROM dbo.ArticlesEmbeddings_FP16 AS e
WHERE e.hn_id <> @QueryHnId
  AND e.embedding IS NOT NULL
ORDER BY
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_FP16
    );


/*==============================================================
  3. FP32 — WARM EXACT SEARCH
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'FP32-768 — EXACT SEARCH — WARM';
PRINT 'NO VECTOR INDEX';
PRINT '============================================';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT TOP (10)
    e.hn_id,
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_FP32
    ) AS distance
FROM dbo.ArticlesEmbeddings_FP32 AS e
WHERE e.hn_id <> @QueryHnId
  AND e.embedding IS NOT NULL
ORDER BY
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_FP32
    );

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;


/*==============================================================
  4. FP16 — WARM EXACT SEARCH
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'FP16-768 — EXACT SEARCH — WARM';
PRINT 'NO VECTOR INDEX';
PRINT '============================================';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT TOP (10)
    e.hn_id,
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_FP16
    ) AS distance
FROM dbo.ArticlesEmbeddings_FP16 AS e
WHERE e.hn_id <> @QueryHnId
  AND e.embedding IS NOT NULL
ORDER BY
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_FP16
    );

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;