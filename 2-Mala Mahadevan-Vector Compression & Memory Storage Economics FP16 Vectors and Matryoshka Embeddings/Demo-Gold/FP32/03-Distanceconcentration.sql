USE HackerNews;
GO
SET NOCOUNT ON;
--Is this true for a sample of 1000000?
DECLARE @RunId          INT          = 3;
DECLARE @Representation VARCHAR(50)  = 'FP32-768';
DECLARE @K              INT          = 10;
DECLARE @ExampleQueries INT          = 5;


DROP TABLE IF EXISTS #QueryConcentration;

WITH PerQuery AS
(
    SELECT
        n.query_hn_id,

        MAX
        (
            CASE
                WHEN n.neighbor_rank = 1
                THEN CAST(n.distance AS FLOAT)
            END
        ) AS rank_1_distance,

        MAX
        (
            CASE
                WHEN n.neighbor_rank = @K
                THEN CAST(n.distance AS FLOAT)
            END
        ) AS rank_k_distance,

        AVG(CAST(n.distance AS FLOAT)) AS average_top_k_distance,

        STDEV(CAST(n.distance AS FLOAT)) AS top_k_distance_stddev,

        COUNT_BIG(*) AS neighbor_count
    FROM dbo.EmbeddingGeometryNeighbors AS n
    WHERE n.run_id = @RunId
      AND n.representation = @Representation
      AND n.neighbor_rank <= @K
      AND CAST(n.distance AS FLOAT) > 0
    GROUP BY
        n.query_hn_id
)
SELECT
    p.query_hn_id,
    p.rank_1_distance,
    p.rank_k_distance,

    p.rank_k_distance - p.rank_1_distance
        AS absolute_distance_spread,

    100.0 *
    (
        p.rank_k_distance - p.rank_1_distance
    )
    / NULLIF(p.rank_1_distance, 0)
        AS rank_k_percent_farther_than_rank_1,

    100.0 *
    p.rank_1_distance
    / NULLIF(p.rank_k_distance, 0)
        AS rank_1_as_percent_of_rank_k,

    p.average_top_k_distance,
    p.top_k_distance_stddev,
    p.neighbor_count
INTO #QueryConcentration
FROM PerQuery AS p
WHERE p.neighbor_count = @K
  AND p.rank_1_distance IS NOT NULL
  AND p.rank_k_distance IS NOT NULL;


/* Detailed concentration results by query */

SELECT
    c.query_hn_id,
    q.title AS query_title,

    CAST(c.rank_1_distance AS DECIMAL(12,8))
        AS rank_1_distance,

    CAST(c.rank_k_distance AS DECIMAL(12,8))
        AS rank_k_distance,

    CAST(c.absolute_distance_spread AS DECIMAL(12,8))
        AS absolute_distance_spread,

    CAST(c.rank_k_percent_farther_than_rank_1 AS DECIMAL(9,2))
        AS rank_k_percent_farther_than_rank_1,

    CAST(c.rank_1_as_percent_of_rank_k AS DECIMAL(9,2))
        AS rank_1_as_percent_of_rank_k,

    CAST(c.top_k_distance_stddev AS DECIMAL(12,8))
        AS top_k_distance_stddev
FROM #QueryConcentration AS c
LEFT JOIN dbo.HackerNewsStories AS q
    ON q.hn_id = c.query_hn_id
ORDER BY
    c.absolute_distance_spread ASC;

--Summary
SELECT
    @RunId          AS run_id,
    @Representation AS representation,
    @K              AS neighbors_per_query,

    COUNT_BIG(*) AS query_count,

    CAST
    (
        AVG(rank_1_distance)
        AS DECIMAL(12,8)
    ) AS average_rank_1_distance,

    CAST
    (
        AVG(rank_k_distance)
        AS DECIMAL(12,8)
    ) AS average_rank_k_distance,

    CAST
    (
        AVG(absolute_distance_spread)
        AS DECIMAL(12,8)
    ) AS average_absolute_spread,

    CAST
    (
        AVG(rank_k_percent_farther_than_rank_1)
        AS DECIMAL(9,2)
    ) AS average_rank_k_percent_farther,

    CAST
    (
        AVG(rank_1_as_percent_of_rank_k)
        AS DECIMAL(9,2)
    ) AS average_rank_1_as_percent_of_rank_k,

    CAST
    (
        AVG(top_k_distance_stddev)
        AS DECIMAL(12,8)
    ) AS average_top_k_standard_deviation
FROM #QueryConcentration;


