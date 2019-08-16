USE $(usedbname)
GO

-- If schema does not exist, create it
IF NOT EXISTS ( 
  SELECT * 
    FROM sys.schemas 
   WHERE schema_id = schema_id(N'$(owner)') )
BEGIN
  EXEC sp_executesql N'CREATE SCHEMA $(owner) AUTHORIZATION dbo';
  PRINT 'Schema $(owner) created.';
END
ELSE
BEGIN
  PRINT 'Schema $(owner) already exists.';
END
GO

QUIT
GO

