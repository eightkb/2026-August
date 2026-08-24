SELECT
    SCHEMA_NAME(t.schema_id)          AS schema_name,
    t.name                             AS table_name,
    i.name                             AS vector_index_name,
    it.internal_type_desc             AS component,
    SUM(ps.used_page_count)  * 8 / 1024.0     AS used_mb,
    SUM(ps.reserved_page_count) * 8 / 1024.0  AS reserved_mb,
    SUM(ps.row_count)                 AS row_count
FROM sys.indexes AS i
JOIN sys.tables  AS t
    ON t.object_id = i.object_id
JOIN sys.internal_tables AS it
    ON it.parent_object_id = i.object_id
   AND it.parent_minor_id  = i.index_id
JOIN sys.dm_db_partition_stats AS ps
    ON ps.object_id = it.object_id
WHERE i.type_desc = 'VECTOR'
GROUP BY t.schema_id, t.name , i.name , it.internal_type_desc
ORDER BY vector_index_name, component