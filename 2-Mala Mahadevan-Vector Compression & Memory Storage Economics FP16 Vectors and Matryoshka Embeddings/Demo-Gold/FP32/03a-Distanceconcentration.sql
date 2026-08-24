SET NOCOUNT ON;

DECLARE @QueryHnId         BIGINT = 18346257;
DECLARE @NumberOfNeighbors INT    = 10;

DECLARE @QueryVector VECTOR(768);
DECLARE @QueryTitle  NVARCHAR(1000);

DROP TABLE IF EXISTS #Neighbors;

------------------------------------------------------------
-- Load query vector
------------------------------------------------------------

SELECT
    @QueryVector = e.embedding,
    @QueryTitle  = s.title
FROM dbo.ArticlesEmbeddings_FP32 e
JOIN dbo.HackerNewsStories s
    ON s.hn_id = e.hn_id
WHERE e.hn_id = @QueryHnId;

------------------------------------------------------------
-- Top-K neighbors (excluding self)
------------------------------------------------------------

;WITH Ranked AS
(
    SELECT TOP (@NumberOfNeighbors)

        e.hn_id,
        s.title,

        VECTOR_DISTANCE
        (
            'cosine',
            @QueryVector,
            e.embedding
        ) AS cosine_distance

    FROM dbo.ArticlesEmbeddings_FP32 e
    JOIN dbo.HackerNewsStories s
        ON s.hn_id = e.hn_id

    WHERE e.hn_id <> @QueryHnId

    ORDER BY
        VECTOR_DISTANCE
        (
            'cosine',
            @QueryVector,
            e.embedding
        ),
        e.hn_id
)
SELECT

    ROW_NUMBER() OVER
    (
        ORDER BY cosine_distance, hn_id
    ) AS neighbor_rank,

    hn_id,
    title,

    CAST(cosine_distance AS decimal(18,10))
        AS cosine_distance

INTO #Neighbors
FROM Ranked;

------------------------------------------------------------
-- Show Top-K neighbors
------------------------------------------------------------

SELECT
    @QueryTitle AS query_title,
    *
FROM #Neighbors
ORDER BY neighbor_rank;

------------------------------------------------------------
-- Neighborhood summary
------------------------------------------------------------

;WITH Stats AS
(
    SELECT

        MAX(CASE WHEN neighbor_rank=1
                 THEN cosine_distance END) AS rank_1_distance,

        MAX(CASE WHEN neighbor_rank=@NumberOfNeighbors
                 THEN cosine_distance END) AS rank_k_distance,

        AVG(CAST(cosine_distance AS float))
            AS average_distance,

        STDEV(CAST(cosine_distance AS float))
            AS top_k_standard_deviation

    FROM #Neighbors
)

SELECT

    @QueryHnId AS query_hn_id,
    @QueryTitle AS query_title,

    @NumberOfNeighbors AS top_k,

    CAST(rank_1_distance AS decimal(12,10))
        AS rank_1_distance,

    CAST(rank_k_distance AS decimal(12,10))
        AS rank_k_distance,

    CAST(rank_k_distance-rank_1_distance AS decimal(12,10))
        AS absolute_spread,

    CAST(rank_k_distance/rank_1_distance AS decimal(10,2))
        AS rank_k_to_rank_1_ratio,

    CAST(100.0*rank_1_distance/rank_k_distance
         AS decimal(10,2))
        AS rank_1_as_percent_of_rank_k,

    CAST(
        100.0*
        (rank_k_distance-rank_1_distance)
        /rank_k_distance
        AS decimal(10,2)
    ) AS spread_as_percent_of_rank_k,

    CAST(average_distance AS decimal(12,10))
        AS average_top_k_distance,

    CAST(top_k_standard_deviation AS decimal(12,10))
        AS top_k_standard_deviation

FROM Stats;

DROP TABLE #Neighbors;
/*
> "Let's look at a single real query to understand what a healthy semantic neighborhood looks like."

> "For this article, the closest matching neighbor has a cosine distance of **0.012**, which tells us it's extremely similar to the query."

> "As we move outward through the neighborhood, the distance increases steadily. By the tenth nearest neighbor, the cosine distance is **0.215**."

> "That gives us an **absolute spread of 0.203**, showing there's meaningful separation between the closest and farthest neighbors rather than everything clustering together."

> "Another way to look at it is through the ratio. The tenth neighbor is approximately **17.7 times farther away** than the closest neighbor."

> "Conversely, the closest neighbor is only **5.6%** of the distance to the tenth neighbor, meaning the search engine clearly distinguishes the strongest semantic match from the outer edge of the neighborhood."

> "Finally, notice the **94.4% spread** across the Top-10 neighborhood. Almost the entire distance range is utilized, which is exactly what we want. The neighbors aren't compressed into nearly identical distances—they're well distributed."

> "The average cosine distance across the Top-10 is **0.184**, with a standard deviation of about **0.061**. That tells us the neighborhood has a healthy amount of variation instead of collapsing into a narrow band of nearly equal distances."

### Closing transition

> **"This FP32 result becomes our baseline. The question we'll answer next is whether FP16 and Matryoshka preserve this same neighborhood structure—or whether compression starts to collapse these distances and change the geometry of the embedding space."**

"This neighborhood exhibits 94% separation between its closest and farthest neighbors."**

*/