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
),
RepresentationPairs AS
(
    SELECT
        a.representation AS representation_a,
        b.representation AS representation_b
    FROM Representations AS a
    CROSS JOIN Representations AS b
    WHERE a.representation < b.representation
),
CommonQueries AS
(
    SELECT
        p.representation_a,
        p.representation_b,
        a.query_hn_id
    FROM RepresentationPairs AS p
    JOIN
    (
        SELECT DISTINCT
            representation,
            query_hn_id
        FROM TopK
    ) AS a
        ON a.representation = p.representation_a
    JOIN
    (
        SELECT DISTINCT
            representation,
            query_hn_id
        FROM TopK
    ) AS b
        ON b.representation = p.representation_b
       AND b.query_hn_id = a.query_hn_id
),
PerQueryOverlap AS
(
    SELECT
        cq.representation_a,
        cq.representation_b,
        cq.query_hn_id,

        COUNT(DISTINCT overlap_rows.neighbor_hn_id)
            AS overlap_count
    FROM CommonQueries AS cq

    LEFT JOIN TopK AS a
        ON a.representation = cq.representation_a
       AND a.query_hn_id = cq.query_hn_id

    LEFT JOIN TopK AS overlap_rows
        ON overlap_rows.representation = cq.representation_b
       AND overlap_rows.query_hn_id = cq.query_hn_id
       AND overlap_rows.neighbor_hn_id = a.neighbor_hn_id

    GROUP BY
        cq.representation_a,
        cq.representation_b,
        cq.query_hn_id
)
SELECT
    representation_a,
    representation_b,

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
    representation_a,
    representation_b
ORDER BY
    representation_a,
    representation_b;