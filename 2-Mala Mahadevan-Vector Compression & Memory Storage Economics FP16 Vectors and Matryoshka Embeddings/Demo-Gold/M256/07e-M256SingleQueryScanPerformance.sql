/*==============================================================
  FP32 vs MATRYOSHKA-256 — EXACT / TABLE SCAN VECTOR SEARCH DEMO

  Same query
  Same TOP 10
  Different representation

  Runs:
      1. FP32 COLD
      2. MRL-256 COLD
      3. Warm both
      4. FP32 WARM
      5. MRL-256 WARM

  NO VECTOR INDEX
  Uses VECTOR_DISTANCE / Exact Search
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
  2. MATRYOSHKA-256 — COLD EXACT SEARCH
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'MATRYOSHKA-256 — EXACT SEARCH — COLD';
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
        @QueryVector_MRL256
    ) AS distance
FROM dbo.ArticlesEmbeddings_Matryoshka256_FP16 AS e
WHERE e.hn_id <> @QueryHnId
  AND e.embedding IS NOT NULL
ORDER BY
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_MRL256
    );

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;


/*==============================================================
  WARM BOTH REPRESENTATIONS

  The MRL-256 cold run cleared the buffer pool again,
  so explicitly warm both tables before measuring warm runs.
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'WARMING FP32 + MATRYOSHKA-256';
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


/* Warm Matryoshka-256 */

SELECT TOP (10)
    e.hn_id,
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_MRL256
    ) AS distance
FROM dbo.ArticlesEmbeddings_Matryoshka256_FP16 AS e
WHERE e.hn_id <> @QueryHnId
  AND e.embedding IS NOT NULL
ORDER BY
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_MRL256
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
  4. MATRYOSHKA-256 — WARM EXACT SEARCH
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'MATRYOSHKA-256 — EXACT SEARCH — WARM';
PRINT 'NO VECTOR INDEX';
PRINT '============================================';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT TOP (10)
    e.hn_id,
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_MRL256
    ) AS distance
FROM dbo.ArticlesEmbeddings_Matryoshka256_FP16 AS e
WHERE e.hn_id <> @QueryHnId
  AND e.embedding IS NOT NULL
ORDER BY
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_MRL256
    );

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;