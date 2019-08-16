EXEC sp_dropextendedproperty @name = N'SPDBA', @level0type = N'Schema', @level0name = 'dbo', @level1type = N'Function', @level1name = 'STMove';  
GO 
EXEC sp_addextendedproperty  @name = N'SPDBA', @level0type = N'Schema', @level0name = 'dbo', @level1type = N'Function', @level1name = 'STMove', @value = 'Function which moves a shape using the supplied delta X, Y, Z amd M.';
GO  

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [major_id],[name],[value]
  FROM [GISDB].[sys].[extended_properties]
 WHERE name = 'SPDBA';
GO

quit
go

