USE HackerNews;
go
/*==============================================================
  FP32-768 — EXACT / TABLE SCAN VECTOR SEARCH DEMO

  Same query vector
  Same TOP 10 result
  NO VECTOR INDEX

  Runs:
      1. FP32 COLD
      2. FP32 WARM

  Uses VECTOR_DISTANCE / Exact Search
==============================================================*/

SET NOCOUNT ON;

DECLARE @QueryHnId BIGINT = 18349232;
DECLARE @QueryVector_FP32 VECTOR(768, FLOAT32);


/*==============================================================
  LOAD QUERY VECTOR BEFORE MEASUREMENT
==============================================================*/

SELECT
    @QueryVector_FP32 = embedding
FROM dbo.ArticlesEmbeddings_FP32
WHERE hn_id = @QueryHnId;


/*==============================================================
  1. FP32 — COLD TABLE SCAN
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
  2. FP32 — WARM TABLE SCAN

  Do NOT clear the buffer pool.
  Same exact query immediately repeated.
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