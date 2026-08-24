USE HackerNews;
go
-- Semantic search without using the vector index (full scan + VECTOR_DISTANCE)
DECLARE @qv VECTOR(768, float32), @id int, @title nvarchar(max)

SELECT TOP (1) @qv = i.Embedding, @title = h.title, @id = i.hn_id
FROM [dbo].[HackerNewsStories] h
INNER JOIN [dbo].[ArticlesEmbeddings_FP32] i
ON h.hn_id = i.hn_id
WHERE h.title = 'Leadership as a Type B Introvert'--'How writers scientifically increase productivity'--
  AND i.Embedding IS NOT NULL

SELECT 'REFERENCE:' As Reference, @id as ArticleID, @title As 'Reference article on Leadership';


SELECT
    e.hn_id,
    h.title,
    r.distance
FROM VECTOR_SEARCH
(
    TABLE      = dbo.ArticlesEmbeddings_FP32 AS e,
    COLUMN     = embedding,
    SIMILAR_TO = @Qv,
    METRIC     = 'cosine',
    TOP_N      = 11
) AS r
INNER JOIN [dbo].[HackerNewsStories] h 
ON e.hn_id = h.hn_id
WHERE e.hn_id <> @id
ORDER BY
    r.distance;

go
SELECT TOP (1)
    DATALENGTH(embedding) AS embedding_bytes
FROM dbo.ArticlesEmbeddings_FP32;