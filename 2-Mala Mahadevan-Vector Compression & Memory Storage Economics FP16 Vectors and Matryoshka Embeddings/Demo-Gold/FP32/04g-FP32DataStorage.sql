WITH VectorTables AS
(
    SELECT DISTINCT
        t.object_id,
        t.schema_id,
        t.name AS table_name
    FROM sys.tables AS t
    JOIN sys.indexes AS i
        ON i.object_id = t.object_id
    WHERE i.type_desc = N'VECTOR'
    AND t.name IN ('ArticlesEmbeddings_FP32')
),
TableSize AS
(
    /* Base table: heap or clustered index */
    SELECT
        vt.object_id,
        SUM(ps.row_count) AS table_row_count,
        SUM(ps.used_page_count) * 8.0 / 1024.0 AS table_used_mb,
        SUM(ps.reserved_page_count) * 8.0 / 1024.0
            AS table_reserved_mb
    FROM VectorTables AS vt
    JOIN sys.dm_db_partition_stats AS ps
        ON ps.object_id = vt.object_id
       AND ps.index_id IN (0, 1)
    GROUP BY
        vt.object_id
),
VectorIndexSize AS
(
    /* Internal graph-edge tables used by vector indexes */
    SELECT
        i.object_id,
        SUM(ps.row_count) AS vector_index_row_count,
        SUM(ps.used_page_count) * 8.0 / 1024.0
            AS vector_index_used_mb,
        SUM(ps.reserved_page_count) * 8.0 / 1024.0
            AS vector_index_reserved_mb
    FROM sys.indexes AS i
    JOIN sys.internal_tables AS it
        ON it.parent_object_id = i.object_id
       AND it.parent_minor_id = i.index_id
    JOIN sys.dm_db_partition_stats AS ps
        ON ps.object_id = it.object_id
    WHERE i.type_desc = N'VECTOR'
      AND it.internal_type_desc =
          N'VECTOR_INDEX_GRAPH_EDGE_TABLE'
    GROUP BY
        i.object_id
)
SELECT
    SCHEMA_NAME(vt.schema_id) AS schema_name,
    vt.table_name,

    ts.table_row_count,

    CAST(
        ts.table_used_mb / 1024.0
        AS DECIMAL(18,2)
    ) AS table_used_gb,

    
    CAST(
        ts.table_reserved_mb / 1024.0
        AS DECIMAL(18,2)
    ) AS table_reserved_gb,

    ISNULL(vis.vector_index_row_count, 0)
        AS vector_index_row_count,

        CAST(
        ISNULL(vis.vector_index_used_mb, 0) / 1024.0
        AS DECIMAL(18,2)
    ) AS vector_index_used_gb,

    CAST(
        ISNULL(vis.vector_index_reserved_mb, 0)
        AS DECIMAL(18,2)
    ) AS vector_index_reserved_mb,

    CAST(
        ISNULL(vis.vector_index_reserved_mb, 0) / 1024.0
        AS DECIMAL(18,2)
    ) AS vector_index_reserved_gb,

    
    CAST(
        (
            ts.table_used_mb
            + ISNULL(vis.vector_index_used_mb, 0)
        ) / 1024.0
        AS DECIMAL(18,2)
    ) AS total_used_gb,

    CAST(
        ts.table_reserved_mb
        + ISNULL(vis.vector_index_reserved_mb, 0)
        AS DECIMAL(18,2)
    ) AS total_reserved_mb,

    CAST(
        (
            ts.table_reserved_mb
            + ISNULL(vis.vector_index_reserved_mb, 0)
        ) / 1024.0
        AS DECIMAL(18,2)
    ) AS total_reserved_gb
FROM VectorTables AS vt
INNER JOIN TableSize AS ts
    ON ts.object_id = vt.object_id
LEFT OUTER JOIN VectorIndexSize AS vis
    ON vis.object_id = vt.object_id
ORDER BY
    CAST(
        (
            ts.table_used_mb
            + ISNULL(vis.vector_index_used_mb, 0)
        ) / 1024.0
        AS DECIMAL(18,2)
    ) DESC;