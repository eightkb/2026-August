/*==============================================================
  FP32 vs MATRYOSHKA-512 — EXACT / TABLE SCAN VECTOR SEARCH DEMO

  Same query
  Same TOP 10
  Different representation

  Runs:
      1. FP32 COLD
      2. MRL-512 COLD
      3. Warm both
      4. FP32 WARM
      5. MRL-512 WARM

  NO VECTOR INDEX
  Uses VECTOR_DISTANCE / Exact Search
==============================================================*/

SET NOCOUNT ON;

DECLARE @QueryHnId BIGINT = 18349232;

DECLARE @QueryVector_FP32   VECTOR(768, FLOAT32);
DECLARE @QueryVector_MRL512 VECTOR(512, FLOAT16);


/*==============================================================
  LOAD BOTH QUERY VECTORS BEFORE MEASUREMENT
==============================================================*/

SELECT
    @QueryVector_FP32 = embedding
FROM dbo.ArticlesEmbeddings_FP32
WHERE hn_id = @QueryHnId;

SELECT
    @QueryVector_MRL512 = embedding
FROM dbo.ArticlesEmbeddings_Matryoshka512_FP16
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
  2. MATRYOSHKA-512 — COLD EXACT SEARCH
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'MATRYOSHKA-512 — EXACT SEARCH — COLD';
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
        @QueryVector_MRL512
    ) AS distance
FROM dbo.ArticlesEmbeddings_Matryoshka512_FP16 AS e
WHERE e.hn_id <> @QueryHnId
  AND e.embedding IS NOT NULL
ORDER BY
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_MRL512
    );

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;


/*==============================================================
  WARM BOTH REPRESENTATIONS

  The second cold run cleared the buffer pool again,
  so explicitly warm both tables before measuring warm runs.
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'WARMING FP32 + MATRYOSHKA-512';
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


/* Warm Matryoshka-512 */

SELECT TOP (10)
    e.hn_id,
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_MRL512
    ) AS distance
FROM dbo.ArticlesEmbeddings_Matryoshka512_FP16 AS e
WHERE e.hn_id <> @QueryHnId
  AND e.embedding IS NOT NULL
ORDER BY
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_MRL512
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
  4. MATRYOSHKA-512 — WARM EXACT SEARCH
==============================================================*/

PRINT '';
PRINT '============================================';
PRINT 'MATRYOSHKA-512 — EXACT SEARCH — WARM';
PRINT 'NO VECTOR INDEX';
PRINT '============================================';

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT TOP (10)
    e.hn_id,
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_MRL512
    ) AS distance
FROM dbo.ArticlesEmbeddings_Matryoshka512_FP16 AS e
WHERE e.hn_id <> @QueryHnId
  AND e.embedding IS NOT NULL
ORDER BY
    VECTOR_DISTANCE(
        'cosine',
        e.embedding,
        @QueryVector_MRL512
    );

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;