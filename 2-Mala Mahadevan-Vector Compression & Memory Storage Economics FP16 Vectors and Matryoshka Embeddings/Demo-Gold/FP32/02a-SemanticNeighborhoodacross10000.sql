DECLARE @RunId INT = 3;

SELECT
    representation,

    COUNT(DISTINCT query_hn_id) AS queries_tested,
    COUNT(*) AS total_neighbor_selections,

    CAST(AVG(distance) AS decimal(10,6))
        AS average_cosine_distance,

    CAST(
        AVG(CASE WHEN neighbor_rank = 1 THEN distance END)
        AS decimal(10,6)
    ) AS average_closest_distance,

    CAST(
        AVG(CASE WHEN neighbor_rank = 10 THEN distance END)
        AS decimal(10,6)
    ) AS average_farthest_distance
FROM dbo.EmbeddingGeometryNeighbors
WHERE run_id = @RunId
AND representation = 'FP32-768'
GROUP BY representation
ORDER BY representation;