DECLARE @QueryHnId BIGINT = 18349232;

SELECT
    'FP32-768' AS representation,
    DATALENGTH(embedding) AS vector_bytes
FROM dbo.ArticlesEmbeddings_FP32
WHERE hn_id = @QueryHnId

