
SET NOCOUNT ON;

DECLARE @RunId INT = 3;
DECLARE @Representation VARCHAR(30) = 'FP32-768';
DECLARE @TopK INT = 10;
DECLARE @HubThreshold INT = 3;

DROP TABLE IF EXISTS #NeighborSelections;
DROP TABLE IF EXISTS #KOccurrences;


SELECT
    query_hn_id,
    neighbor_hn_id,
    neighbor_rank,
    CAST(distance AS FLOAT) AS cosine_distance
INTO #NeighborSelections
FROM dbo.EmbeddingGeometryNeighbors
WHERE run_id = @RunId
  AND representation = @Representation
  AND neighbor_rank BETWEEN 1 AND @TopK;


SELECT
    @Representation AS representation,
    COUNT(DISTINCT query_hn_id) AS queries_tested,
    COUNT(*) AS total_neighbor_selections,
    CAST
    (
        1.0 * COUNT(*)
        / NULLIF(COUNT(DISTINCT query_hn_id), 0)
        AS DECIMAL(10,2)
    ) AS average_neighbors_per_query
FROM #NeighborSelections;


SELECT
    e.hn_id AS neighbor_hn_id,

    COUNT(DISTINCT n.query_hn_id) AS neighborhood_appearances,

    COUNT(n.neighbor_hn_id) AS total_appearances,

    AVG(n.cosine_distance) AS average_distance_when_selected,

    MIN(n.cosine_distance) AS minimum_distance_when_selected,

    MAX(n.cosine_distance) AS maximum_distance_when_selected
INTO #KOccurrences
FROM dbo.ArticlesEmbeddings_FP32 AS e
LEFT JOIN #NeighborSelections AS n
    ON n.neighbor_hn_id = e.hn_id
GROUP BY
    e.hn_id;



SELECT
    @Representation AS representation,

    COUNT(*) AS total_vectors,

    SUM
    (
        CASE
            WHEN neighborhood_appearances > 0 THEN 1
            ELSE 0
        END
    ) AS vectors_selected_at_least_once,

    SUM
    (
        CASE
            WHEN neighborhood_appearances = 0 THEN 1
            ELSE 0
        END
    ) AS vectors_never_selected,

    MAX(neighborhood_appearances) AS maximum_hub_appearances,

    SUM
    (
        CASE
            WHEN neighborhood_appearances >= @HubThreshold THEN 1
            ELSE 0
        END
    ) AS vectors_classified_as_hubs,

    CAST
    (
        100.0 *
        SUM
        (
            CASE
                WHEN neighborhood_appearances >= @HubThreshold THEN 1
                ELSE 0
            END
        )
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,4)
    ) AS percent_of_vectors_classified_as_hubs
FROM #KOccurrences;