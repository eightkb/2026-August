DECLARE @RunId INT = 3;
DECLARE @K INT = 10;

WITH Distances AS
(
    SELECT
        representation,
        query_hn_id,
        neighbor_rank,
        distance
    FROM dbo.EmbeddingGeometryNeighbors
    WHERE run_id = @RunId
      AND representation IN ('FP32-768','MRL-FP16-256')
      AND neighbor_rank <= @K
),
PerQuery AS
(
    SELECT
        representation,
        query_hn_id,

        MIN(CASE WHEN neighbor_rank = 1 THEN distance END) AS rank1_distance,
        MAX(CASE WHEN neighbor_rank = @K THEN distance END) AS rankk_distance,

        AVG(distance)  AS avg_distance,
        STDEV(distance) AS stdev_distance
    FROM Distances
    GROUP BY
        representation,
        query_hn_id
)

SELECT
    representation,

    COUNT(*) AS queries,

    CAST(AVG(rank1_distance) AS DECIMAL(8,2)) AS avg_rank1_distance,

    CAST(AVG(rankk_distance) AS DECIMAL(8,2)) AS avg_rankk_distance,

    CAST(AVG(rankk_distance - rank1_distance) AS DECIMAL(8,2))
        AS avg_absolute_spread,

    CAST
    (
        100.0 * AVG
        (
            rank1_distance /
            NULLIF(rankk_distance,0)
        )
        AS DECIMAL(6,2)
    ) AS rank1_as_percent_of_rankk,

    CAST(AVG(avg_distance) AS DECIMAL(8,2))
        AS avg_topk_distance,

    CAST(AVG(stdev_distance) AS DECIMAL(8,2))
        AS avg_standard_deviation

FROM PerQuery
GROUP BY representation
ORDER BY representation;
GO

DECLARE @RunId INT = 3;
DECLARE @K INT = 10;

WITH HubCounts AS
(
    SELECT
        representation,
        neighbor_hn_id,
        COUNT(DISTINCT query_hn_id) AS hub_occurrences
    FROM dbo.EmbeddingGeometryNeighbors
    WHERE run_id = @RunId
      AND representation IN ('FP32-768','MRL-FP16-256')
      AND neighbor_rank <= @K
    GROUP BY
        representation,
        neighbor_hn_id
)

SELECT
    representation,

    COUNT(*) AS unique_neighbors,

    CAST
    (
        AVG(CAST(hub_occurrences AS FLOAT))
        AS DECIMAL(10,2)
    ) AS average_occurrences,

    CAST
    (
        STDEV(CAST(hub_occurrences AS FLOAT))
        AS DECIMAL(10,2)
    ) AS stdev_occurrences,

    MAX(hub_occurrences) AS max_occurrences

FROM HubCounts
GROUP BY
    representation
ORDER BY
    representation;