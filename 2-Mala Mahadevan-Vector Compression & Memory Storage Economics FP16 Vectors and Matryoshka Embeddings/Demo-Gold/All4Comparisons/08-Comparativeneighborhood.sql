DECLARE @RunId INT = 3;
DECLARE @K     INT = 10;

WITH BaseNeighbors AS
(
    SELECT
        representation,
        query_hn_id,
        neighbor_hn_id,
        neighbor_rank,
        CAST(distance AS FLOAT) AS distance
    FROM dbo.EmbeddingGeometryNeighbors
    WHERE run_id = @RunId
      AND neighbor_rank <= @K
),
QuerySummary AS
(
    SELECT
        representation,
        COUNT(DISTINCT query_hn_id) AS query_count,
        COUNT_BIG(*)                AS total_neighbor_selections
    FROM BaseNeighbors
    GROUP BY
        representation
),
DistanceSummary AS
(
    SELECT
        representation,

        AVG
        (
            CASE
                WHEN neighbor_rank = 1
                THEN distance
            END
        ) AS average_rank_1_distance,

        AVG
        (
            CASE
                WHEN neighbor_rank = @K
                THEN distance
            END
        ) AS average_rank_k_distance
    FROM BaseNeighbors
    GROUP BY
        representation
),
NeighborAppearances AS
(
    SELECT
        representation,
        neighbor_hn_id,
        COUNT_BIG(*) AS appearance_count
    FROM BaseNeighbors
    GROUP BY
        representation,
        neighbor_hn_id
),
HubSummary AS
(
    SELECT
        representation,
        COUNT_BIG(*)          AS unique_selected_neighbors,
        MAX(appearance_count) AS maximum_hub_appearances
    FROM NeighborAppearances
    GROUP BY
        representation
)
SELECT
    q.representation,

    q.query_count,

    @K AS neighbors_per_query,

    q.total_neighbor_selections,

    CAST
    (
        d.average_rank_1_distance
        AS DECIMAL(12,8)
    ) AS average_rank_1_distance,

    CAST
    (
        d.average_rank_k_distance
        AS DECIMAL(12,8)
    ) AS average_rank_10_distance,

    CAST
    (
        100.0
        * d.average_rank_1_distance
        / NULLIF(d.average_rank_k_distance, 0)
        AS DECIMAL(9,2)
    ) AS rank_1_as_percent_of_rank_10,

    h.unique_selected_neighbors,

    h.maximum_hub_appearances
FROM QuerySummary AS q
JOIN DistanceSummary AS d
    ON d.representation = q.representation
JOIN HubSummary AS h
    ON h.representation = q.representation
ORDER BY
    CASE q.representation
        WHEN N'FP32-768'                    THEN 1
        WHEN N'FP16-768'                    THEN 2
        WHEN N'Matryoshka512-FP16'          THEN 3
        WHEN N'Matryoshka256-FP16'          THEN 4
        ELSE 99
    END,
    q.representation;