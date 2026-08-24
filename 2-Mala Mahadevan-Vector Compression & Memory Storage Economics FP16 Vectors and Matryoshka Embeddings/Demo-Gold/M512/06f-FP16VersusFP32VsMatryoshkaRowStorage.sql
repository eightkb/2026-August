DECLARE @QueryHnId BIGINT = 18349232;

SELECT 1 AS CTR,
    'FP32-768' AS representation,
    DATALENGTH(embedding) AS vector_bytes
FROM dbo.ArticlesEmbeddings_FP32
WHERE hn_id = @QueryHnId

UNION 

SELECT 2 AS CTR,
    'FP16-768',
    DATALENGTH(embedding)
FROM dbo.ArticlesEmbeddings_FP16
WHERE hn_id = @QueryHnId

UNION 

SELECT
    3 AS CTR,
    'MRL512-FP16',
    DATALENGTH(embedding)
FROM dbo.ArticlesEmbeddings_Matryoshka512_FP16
WHERE hn_id = @QueryHnId

