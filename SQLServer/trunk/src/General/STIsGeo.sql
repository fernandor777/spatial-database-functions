USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS ( SELECT * 
              FROM sysobjects 
             WHERE id = object_id (N'[$(owner)].[STIsGeo]') AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION  [$(owner)].[STIsGeo];
  PRINT 'Dropped [$(owner)].[STIsGeo] ...';
END;
GO

PRINT 'Creating [$(owner)].[STIsGeo] ...';
GO

CREATE FUNCTION [$(owner)].[STIsGeo] 
(
  @schema_name nvarchar(128), 
  @object_name nvarchar(128), 
  @column_name nvarchar(128)
)
Returns integer
WITH EXECUTE AS CALLER, 
     RETURNS NULL ON NULL INPUT
AS
/****f* EDITOR/STIsGeo (2012)
 *  NAME
 *    STIsGeo -- Tests if referenced schema/table/column is of type geography (1) or geometry (0).
 *  SYNOPSIS
 *    Function STIsGeo (
 *               @schema_name nvarchar(128), 
 *               @object_name nvarchar(128), 
 *               @column_name nvarchar(128)
 *             )
 *     Returns integer
 *  USAGE
 *    SELECT [$(owner)].[STIsGeo]('dbo','Table','Column') as isGeo;
 *    GO
 *    isGeo 
 *    geography
 *  DESCRIPTION
 *    Function that checks the SQL Server metadata and returns whether the referenced column contains geographic or geometry objects.
 *  NOTES
 *    While will run in SQL Server 2008 (always geometry), is aimed at 2012 onwards.
 *  INPUTS
 *    @schema_name nvarchar(128) - Schema name
 *    @object_name nvarchar(128) - Table/View name
 *    @column_name nvarchar(128) - Column name
 *  RESULT
 *    result (integer)           - no geography/geometry (-1), geography (1), geometry (0)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2012 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2017 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE @v_result varchar(15);
    SELECT @v_result=a.column_type
      FROM (SELECT sc.name as schema_name,
                   ta.name as object_name,
                   co.name as column_name,
                   ty.name as column_type,
                   'TABLE' as object_type
              FROM sys.tables ta
                   JOIN sys.schemas sc ON sc.schema_id = ta.schema_id 
                   JOIN sys.columns co ON ta.object_id = co.object_id
                   JOIN sys.types ty   ON co.user_type_id = ty.user_type_id
             WHERE ty.name IN ('geography','geometry')
             UNION ALL
            SELECT sc.name as schema_name,
                   va.name as object_name,
                   co.name as column_name,
                   ty.name as column_type,
                   'VIEW' as object_type
              FROM sys.views va 
                   JOIN sys.schemas sc ON sc.schema_id = va.schema_id
                   JOIN sys.columns co ON va.object_id = co.object_id
                   JOIN sys.types ty   ON co.user_type_id = ty.user_type_id
             WHERE ty.name IN ('geography','geometry')
            ) a
        WHERE a.schema_name = @schema_name
          AND a.object_name = @object_name
          AND a.column_name = @column_name ;
    Return case when @v_result is null       then -1 
                when @v_result = 'geography' then  1
                else 0 
           end;
END;
GO

PRINT 'Testing [$(owner)].[STIsGeo] ...';
GO

create table dbo.foo (foo_id integer, geog geography, geom geometry);
select dbo.STIsGeo('dbo',NULL,'geog') as isGeo;
select dbo.STIsGeo('dbo','foo','geog') as isGeo;
select dbo.STIsGeo('dbo','foo','geom') as isGeo;
GO
create view dbo.vw_foo as select foo_id, geog from dbo.foo;
select dbo.STIsGeo('dbo','foo','geom') as isGeo;
select dbo.STIsGeo('dbo','foo','geog') as isGeo;
drop view  dbo.vw_foo;
drop table dbo.foo;
GO

QUIT
GO

