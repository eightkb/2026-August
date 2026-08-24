USE HackerNews;
GO
DECLARE @RunId INT = 3;
DECLARE @K INT = 10;
DECLARE @TopHubs INT = 25;

WITH NeighborAppearances AS
(
    SELECT
        neighbor_hn_id,
        COUNT_BIG(*) AS appearance_count
    FROM dbo.EmbeddingGeometryNeighbors
    WHERE run_id = @RunId
      AND representation = 'FP32-768'
      AND neighbor_rank <= @K
    GROUP BY
        neighbor_hn_id
)
SELECT TOP (@TopHubs)
    ROW_NUMBER() OVER
    (
        ORDER BY
            a.appearance_count DESC,
            a.neighbor_hn_id
    ) AS hub_rank,

    a.neighbor_hn_id,
    s.title,

    a.appearance_count
    FROM NeighborAppearances AS a
INNER JOIN dbo.HackerNewsStories AS s
    ON s.hn_id = a.neighbor_hn_id
ORDER BY
    a.appearance_count DESC,
    a.neighbor_hn_id;
