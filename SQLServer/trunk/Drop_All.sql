use [$(usedbname)]
go
SELECT CONCAT('Connected to ',QUOTENAME(DB_NAME())) as db_name;
Declare @sql NVARCHAR(MAX) = N'';
SELECT @sql = @sql + N' DROP FUNCTION ' 
                   + QUOTENAME(SCHEMA_NAME(schema_id)) 
                   + N'.' + QUOTENAME(name)
FROM sys.objects
WHERE type_desc LIKE '%FUNCTION%';
Exec sp_executesql @sql
SET @sql = '';
SELECT @sql = @sql + N' DROP PROCEDURE ' 
                   + QUOTENAME(SCHEMA_NAME(schema_id)) 
                   + N'.' + QUOTENAME(name)
FROM sys.objects
WHERE type_desc LIKE '%PROCEDURE%';
Exec sp_executesql @sql
GO

QUIT
GO
