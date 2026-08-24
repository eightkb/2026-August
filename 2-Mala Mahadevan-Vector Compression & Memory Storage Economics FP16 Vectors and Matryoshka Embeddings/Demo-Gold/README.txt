HackerNews.bak can be downloaded https://1drv.ms/u/c/dc7582c1f40d2719/IQBOzUFVf6sERKh0tVq47LpTARbRkQNbfRa8ZrgZFnFUz4c?e=R5LbcR

It is 70 GB approx. 

Python scripts that generated embeddings are in the folder /EmbeddingGenerationScripts.

Table dbo.HackerNews contains the data that was used for embeddings (column 'title').
Table dbo.ArticlesEmbeddings_FP32 contains 32 bit embeddings(768 dimensions).
Table dbo.ArticlesEmbeddings_FP32 contains 16 bit embeddings(768 dimensions).
Table dbo.ArticlesEmbeddings_Matryoshka512_FP16 contains 32 bit embeddings(512 dimensions, 16 bit).
Table dbo.ArticlesEmbeddings_Matryoshka256_FP16 contains 32 bit embeddings(512 dimensions, 16 bit).
Tables dbo.EmbeddingGeometry*.* contain embedding geometry finds across embeddings for a sample of 10K rows.

Stored Procedure dbo.BuildMatryoshkaPrefix from FP16  - normalizes the Matryoshka 512 embeddings.
Stored Procedure dbo.GenerateMatryoshka256FromFP16 creates Matryoshka 256 embeddings from 512 (just truncation and normalization)
Stored Procedure dbo.PopulateEmbeddingGeometryDemo creates embedding geometry metrics for specified sample and stores it in dbo.EmbeddingGeometry*.* tables .

ALL THESE PROCEDURES CAN TAKE CONSIDERABLE TIME TO RUN.

 