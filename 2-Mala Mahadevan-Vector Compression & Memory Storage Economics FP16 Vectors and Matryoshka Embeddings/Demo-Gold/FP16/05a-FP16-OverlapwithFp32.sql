
DECLARE @QueryHnId BIGINT = 18349232;
DECLARE @TopK INT = 10;

DECLARE @FP32Query VECTOR(768, FLOAT32);
DECLARE @FP16Query VECTOR(768, FLOAT16);

SELECT @FP32Query = embedding
FROM dbo.ArticlesEmbeddings_FP32
WHERE hn_id = @QueryHnId;

SELECT @FP16Query = embedding
FROM dbo.ArticlesEmbeddings_FP16
WHERE hn_id = @QueryHnId;

IF @FP32Query IS NULL OR @FP16Query IS NULL
    THROW 50001, 'Query embedding is missing from FP32 or FP16.', 1;

DROP TABLE IF EXISTS #FP32Results;
DROP TABLE IF EXISTS #FP16Results;


/* FP32 Top 10 */

SELECT TOP (@TopK)
    ROW_NUMBER() OVER
    (
        ORDER BY
            VECTOR_DISTANCE('cosine', @FP32Query, e.embedding),
            e.hn_id
    ) AS neighbor_rank,

    e.hn_id,
    s.title,

    CAST
    (
        VECTOR_DISTANCE('cosine', @FP32Query, e.embedding)
        AS DECIMAL(9,6)
    ) AS cosine_distance
INTO #FP32Results
FROM dbo.ArticlesEmbeddings_FP32 AS e
JOIN dbo.HackerNewsStories AS s
    ON s.hn_id = e.hn_id
WHERE e.hn_id <> @QueryHnId
ORDER BY
    VECTOR_DISTANCE('cosine', @FP32Query, e.embedding),
    e.hn_id;


/* FP16 Top 10 */

SELECT TOP (@TopK)
    ROW_NUMBER() OVER
    (
        ORDER BY
            VECTOR_DISTANCE('cosine', @FP16Query, e.embedding),
            e.hn_id
    ) AS neighbor_rank,

    e.hn_id,
    s.title,

    CAST
    (
        VECTOR_DISTANCE('cosine', @FP16Query, e.embedding)
        AS DECIMAL(9,6)
    ) AS cosine_distance
INTO #FP16Results
FROM dbo.ArticlesEmbeddings_FP16 AS e
JOIN dbo.HackerNewsStories AS s
    ON s.hn_id = e.hn_id
WHERE e.hn_id <> @QueryHnId
ORDER BY
    VECTOR_DISTANCE('cosine', @FP16Query, e.embedding),
    e.hn_id;


/* Display matching ranks side by side */

SELECT
    COALESCE(f32.neighbor_rank, f16.neighbor_rank) AS rank_position,

    f32.title AS fp32_neighbor,
    f32.cosine_distance AS fp32_distance,

    f16.title AS fp16_neighbor,
    f16.cosine_distance AS fp16_distance,

    CASE
        WHEN f32.hn_id = f16.hn_id
        THEN 'Same'
        ELSE 'Different'
    END AS same_result_at_rank
FROM #FP32Results AS f32
FULL JOIN #FP16Results AS f16
    ON f16.neighbor_rank = f32.neighbor_rank
ORDER BY
    rank_position;

--Overlap check
SELECT
    COUNT(*) AS shared_neighbors,
    @TopK AS neighbors_requested,

    CAST
    (
        100.0 * COUNT(*) / @TopK
        AS DECIMAL(6,2)
    ) AS top_k_overlap_percent
FROM #FP32Results AS f32
JOIN #FP16Results AS f16
    ON f16.hn_id = f32.hn_id;