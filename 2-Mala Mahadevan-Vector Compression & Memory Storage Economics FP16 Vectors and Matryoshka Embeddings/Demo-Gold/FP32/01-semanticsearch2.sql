--Semantic neighborhood - good neighbors are in the same neighborhood
    

DECLARE @QueryHnId BIGINT = 18346257;
DECLARE @NumberOfNeighbors INT = 10;

DECLARE @QueryVector VECTOR(768);
DECLARE @QueryTitle NVARCHAR(1000);


SELECT
    @QueryVector = e.embedding,
    @QueryTitle = s.title
FROM dbo.ArticlesEmbeddings_FP32 AS e
INNER JOIN dbo.HackerNewsStories AS s
    ON s.hn_id = e.hn_id
WHERE e.hn_id = @QueryHnId;


SELECT TOP (@NumberOfNeighbors)
    @QueryTitle AS query_title,
    ROW_NUMBER() OVER
    (
        ORDER BY
            VECTOR_DISTANCE
            (
                'cosine',
                @QueryVector,
                e.embedding
            ),
            s.hn_id
    ) AS neighbor_rank,
    s.title AS neighbor_title,
    CAST
    (
        VECTOR_DISTANCE
        (
            'cosine',
            @QueryVector,
            e.embedding
        )
        AS DECIMAL(9,6)
    ) AS cosine_distance
FROM dbo.ArticlesEmbeddings_FP32 AS e
INNER JOIN dbo.HackerNewsStories AS s
    ON s.hn_id = e.hn_id
ORDER BY
    neighbor_rank;
GO

