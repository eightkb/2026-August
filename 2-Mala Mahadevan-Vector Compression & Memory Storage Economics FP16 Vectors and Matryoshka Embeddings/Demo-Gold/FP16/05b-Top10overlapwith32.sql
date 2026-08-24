DECLARE @RunId INT = 3;
DECLARE @K     INT = 10;

WITH TopK AS
(
    SELECT
        representation,
        query_hn_id,
        neighbor_hn_id
    FROM dbo.EmbeddingGeometryNeighbors
    WHERE run_id = @RunId
      AND neighbor_rank <= @K
),
Representations AS
(
    SELECT DISTINCT
        representation
    FROM TopK
    WHERE representation not in ('FP32-768','MRL-FP16-256','MRL-FP16-512')
),
Queries AS
(
    SELECT DISTINCT
        query_hn_id
    FROM TopK
    WHERE representation = N'FP32-768'
),
PerQueryOverlap AS
(
    SELECT
        r.representation,
        q.query_hn_id,

        COUNT(DISTINCT fp32.neighbor_hn_id)
            AS fp32_neighbor_count,

        COUNT(DISTINCT candidate.neighbor_hn_id)
            AS candidate_neighbor_count,

        COUNT(DISTINCT overlap_rows.neighbor_hn_id)
            AS overlap_count
    FROM Representations AS r
    CROSS JOIN Queries AS q

    LEFT JOIN TopK AS fp32
        ON fp32.representation = N'FP32-768'
       AND fp32.query_hn_id = q.query_hn_id

    LEFT JOIN TopK AS candidate
        ON candidate.representation = r.representation
       AND candidate.query_hn_id = q.query_hn_id

    LEFT JOIN TopK AS overlap_rows
        ON overlap_rows.representation = r.representation
       AND overlap_rows.query_hn_id = q.query_hn_id
       AND overlap_rows.neighbor_hn_id = fp32.neighbor_hn_id

    GROUP BY
        r.representation,
        q.query_hn_id
)
SELECT
    N'FP32-768' AS baseline_representation,
    representation AS comparison_representation,

    COUNT_BIG(*) AS query_count,

    CAST
    (
        AVG(CAST(overlap_count AS FLOAT))
        AS DECIMAL(10,4)
    ) AS average_overlap_count,

    CAST
    (
        100.0 * AVG(CAST(overlap_count AS FLOAT)) / @K
        AS DECIMAL(9,2)
    ) AS average_top_k_overlap_percent,

    MIN(overlap_count) AS minimum_overlap_count,
    MAX(overlap_count) AS maximum_overlap_count,

    SUM
    (
        CASE
            WHEN overlap_count = @K THEN 1
            ELSE 0
        END
    ) AS exact_match_query_count,

    CAST
    (
        100.0 *
        SUM
        (
            CASE
                WHEN overlap_count = @K THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT_BIG(*), 0)
        AS DECIMAL(9,2)
    ) AS exact_match_query_percent
FROM PerQueryOverlap
GROUP BY
    representation
ORDER BY
    CASE representation
        WHEN N'FP16-768'           THEN 1
        WHEN N'MRL512-FP16'        THEN 2
        WHEN N'MRL256-FP16'        THEN 3
        ELSE 99
    END;