USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '***********************************************************************';
PRINT 'Database Schema Variables are: COGO Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STTileGeom]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION  [$(owner)].[STTileGeom];
  PRINT 'Dropped [$(owner)].[STTileGeom] ...';
END;
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STTileXY]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION  [$(owner)].[STTileXY];
  PRINT 'Dropped [$(owner)].[STTileXY] ...';
END;
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STTiler]') 
    AND xtype IN (N'P')
)
BEGIN
  DROP PROCEDURE [$(owner)].[STTiler];
  PRINT 'Dropped [$(owner)].[STTiler] ...';
END;
GO

PRINT 'Creating [$(owner)].[STTileGeom] ...';
GO

CREATE FUNCTION [$(owner)].[STTileGeom]
(
  @p_geometry geometry,
  @p_TileX    float,
  @p_TileY    float
)
returns @table table
(
  col  Int,
  row  Int,
  geom geometry
)
AS
/****f* COGO/STTileGeom (2008)
 *  NAME
 *    STTileGeom -- Covers envelope of supplied goemetry with a mesh of tiles of size TileX and TileY.
 *  SYNOPSIS
 *    Function STTileGeom (
 *               @p_geometry geometry,
 *               @p_TileX float,
 *               @p_TileY float,
 *             )
 *     Returns @table table
 *    (
 *      col  Int,
 *      row  Int,
 *      geom geometry
 *    )
 *  USAGE
 *    SELECT t.col, t.row, t.geom.STAsText() as geom
 *      FROM [$(owner)].[STTileGeom] (
 *             geometry::STGeomFromText('POLYGON((100 100, 900 100, 900 900, 100 900, 100 100))',0),
 *             400,200) as t;
 *    GO
 *
 *    col row geom
 *    --- --- ------------------------------------------------------------
 *    0   0   POLYGON ((0 0, 400 0, 400 200, 0 200, 0 0))
 *    0   1   POLYGON ((0 200, 400 200, 400 400, 0 400, 0 200))
 *    0   2   POLYGON ((0 400, 400 400, 400 600, 0 600, 0 400))
 *    0   3   POLYGON ((0 600, 400 600, 400 800, 0 800, 0 600))
 *    0   4   POLYGON ((0 800, 400 800, 400 1000, 0 1000, 0 800))
 *    1   0   POLYGON ((400 0, 800 0, 800 200, 400 200, 400 0))
 *    1   1   POLYGON ((400 200, 800 200, 800 400, 400 400, 400 200))
 *    1   2   POLYGON ((400 400, 800 400, 800 600, 400 600, 400 400))
 *    1   3   POLYGON ((400 600, 800 600, 800 800, 400 800, 400 600))
 *    1   4   POLYGON ((400 800, 800 800, 800 1000, 400 1000, 400 800))
 *    2   0   POLYGON ((800 0, 1200 0, 1200 200, 800 200, 800 0))
 *    2   1   POLYGON ((800 200, 1200 200, 1200 400, 800 400, 800 200))
 *    2   2   POLYGON ((800 400, 1200 400, 1200 600, 800 600, 800 400))
 *    2   3   POLYGON ((800 600, 1200 600, 1200 800, 800 800, 800 600))
 *    2   4   POLYGON ((800 800, 1200 800, 1200 1000, 800 1000, 800 800))
 *    
 *  DESCRIPTION
 *    Function that takes a non-point geometry type, determines its spatial extent (LL/UR),
 *    computes the number of tiles given the tile size @p_TileX/@p_TileY (real world units),
 *    creates each tile as a polygon, and outputs it in the table array with its col/row reference.
 *    The lower left and upper right coordinates are calculated as follows:
 *      LL.X = @p_geometry.STEnvelope().STPointN(1).STX;
 *      LL.Y = @p_geometry.STEnvelope().STPointN(1).STY;
 *      UR.X = @p_geometry.STEnvelope().STPointN(3).STX;
 *      UR.Y = @p_geometry.STEnvelope().STPointN(3).STY;
 *    The number of columns and rows that cover this area is calculated.
 *    All rows and columns are visited, with polygons being created that represent each tile.
 *  INPUTS
 *    @p_geometry (geometry) -- Column reference 
 *    @p_TileX       (float) -- Size of a Tile's X dimension in real world units.
 *    @p_TileY       (float) -- Size of a Tile's Y dimension in real world units.
 *  RESULT
 *    A Table of the following is returned
 *    (
 *      col  Int      -- The column reference for a tile
 *      row  Int      -- The row reference for a tile
 *      geom geometry -- The polygon geometry covering the area of the Tile.
 *    )
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
begin
   DECLARE
     @v_srid  Int,
     @v_ll_x  float,
     @v_ll_y  float,
     @v_ur_x  float,
     @v_ur_y  float,
     @v_loCol int,
     @v_hiCol int,
     @v_loRow int,
     @v_hiRow int,
     @v_col   int,
     @v_row   int,
     @v_wkt   nvarchar(max);
   Begin
     If ( @p_geometry is null )
       Return;
     If ( @p_geometry.STGeometryType() = 'Point' )
       Return;
     SET @v_srid = @p_geometry.STSrid;
     SET @v_ll_x = @p_geometry.STEnvelope().STPointN(1).STX;
     SET @v_ll_y = @p_geometry.STEnvelope().STPointN(1).STY;
     SET @v_ur_x = @p_geometry.STEnvelope().STPointN(3).STX;
     SET @v_ur_y = @p_geometry.STEnvelope().STPointN(3).STY;

     SET @v_loCol = FLOOR(   @v_LL_X / @p_TileX );
     SET @v_hiCol = CEILING( @v_UR_X / @p_TileX ) - 1;
     SET @v_loRow = FLOOR(   @v_LL_Y / @p_TileY );
     SET @v_hiRow = CEILING( @v_UR_Y / @p_TileY ) - 1;
     SET @v_col = @v_loCol;
     WHILE ( @v_col <= @v_hiCol )
     BEGIN
       SET @v_row = @v_loRow;
       WHILE ( @v_row <= @v_hiRow )
       BEGIN
         SET @v_wkt = 'POLYGON((' + 
                 CONVERT(varchar(30),CAST(  @v_col * @p_TileX              as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(  @v_row * @p_TileY              as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST(((@v_col * @p_TileX) + @p_TileX) as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(  @v_row * @p_TileY              as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST(((@v_col * @p_TileX) + @p_TileX) as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(((@v_row * @p_TileY) + @p_TileY) as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST(  @v_col * @p_TileX              as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(((@v_row * @p_TileY) + @p_TileY) as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST(  @v_col * @p_TileX              as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(  @v_row * @p_TileY              as DECIMAL(24,12))) + '))';
         INSERT INTO @table VALUES(@v_col,@v_row,geometry::STGeomFromText(@v_WKT,@v_srid));
         SET @v_row = @v_row + 1;
       END;
       SET @v_col = @v_col + 1;
     END;
     RETURN;
   END;
End
GO

PRINT 'Creating [$(owner)].[STTileXY]  ...';
GO

CREATE FUNCTION [$(owner)].[STTileXY]
(
  @p_ll_x  float,
  @p_ll_y  float,
  @p_ur_x  float,
  @p_ur_y  float,
  @p_TileX float,
  @p_TileY float,
  @p_srid  int = 0
)
returns @table table
(
  col  Int,
  row  Int,
  geom geometry 
)
as
/****f* COGO/STTileXY (2008)
 *  NAME
 *    STTileXY -- Covers supplied envelope (LL/UR) with a mesh of tiles of size TileX and TileY.
 *  SYNOPSIS
 *    Function STTileXY (
 *               @p_ll_x  float,
 *               @p_ll_y  float,
 *               @p_ur_x  float,
 *               @p_ur_y  float,
 *               @p_TileX float,
 *               @p_TileY float,
 *               @p_srid  int = 0
 *             )
 *     Returns @table table
 *    (
 *      col  Int,
 *      row  Int,
 *      geom geometry
 *    )
 *  USAGE
 *    SELECT row_number() over (order by t.col, t.row) as rid, 
 *           t.col, t.row, t.geom.STAsText() as geom
 *      FROM [$(owner)].[STTileXY](0,0,1000,1000,250,250,0) as t;
 *    GO
 *
 *    rid col row geom
 *    --- --- --- -----------------------------------------------------------
 *     1  0   0   POLYGON ((0 0, 250 0, 250 250, 0 250, 0 0))
 *     2  0   1   POLYGON ((0 250, 250 250, 250 500, 0 500, 0 250))
 *     3  0   2   POLYGON ((0 500, 250 500, 250 750, 0 750, 0 500))
 *     4  0   3   POLYGON ((0 750, 250 750, 250 1000, 0 1000, 0 750))
 *     5  1   0   POLYGON ((250 0, 500 0, 500 250, 250 250, 250 0))
 *     6  1   1   POLYGON ((250 250, 500 250, 500 500, 250 500, 250 250))
 *     7  1   2   POLYGON ((250 500, 500 500, 500 750, 250 750, 250 500))
 *     8  1   3   POLYGON ((250 750, 500 750, 500 1000, 250 1000, 250 750))
 *     9  2   0   POLYGON ((500 0, 750 0, 750 250, 500 250, 500 0))
 *    10  2   1   POLYGON ((500 250, 750 250, 750 500, 500 500, 500 250))
 *    11  2   2   POLYGON ((500 500, 750 500, 750 750, 500 750, 500 500))
 *    12  2   3   POLYGON ((500 750, 750 750, 750 1000, 500 1000, 500 750))
 *    13  3   0   POLYGON ((750 0, 1000 0, 1000 250, 750 250, 750 0))
 *    14  3   1   POLYGON ((750 250, 1000 250, 1000 500, 750 500, 750 250))
 *    15  3   2   POLYGON ((750 500, 1000 500, 1000 750, 750 750, 750 500))
 *    16  3   3   POLYGON ((750 750, 1000 750, 1000 1000, 750 1000, 750 750))
 * 
 *  DESCRIPTION
 *    Function that takes a spatial extent (LL/UR), computes the number of tiles that cover it and
 *    the table array with its col/row reference.
 *    The number of columns and rows that cover this area is calculated using @p_TileX/@p_TileY which
 *    are in @p_SRID units.
 *    All rows and columns are visited, with polygons being created that represent each tile.
 *  INPUTS
 *    @p_ll_x  (float) -- Spatial Extent's lower left X ordinate.
 *    @p_ll_y  (float) -- Spatial Extent's lower left Y ordinate.
 *    @p_ur_x  (float) -- Spatial Extent's uppre righ X ordinate.
 *    @p_ur_y  (float) -- Spatial Extent's uppre righ Y ordinate.
 *    @p_TileX (float) -- Size of a Tile's X dimension in real world units.
 *    @p_TileY (float) -- Size of a Tile's Y dimension in real world units.
 *    @p_srid    (int) -- Geometric SRID.
 *  RESULT
 *    A Table of the following is returned
 *    (
 *      col  Int      -- The column reference for a tile
 *      row  Int      -- The row reference for a tile
 *      geom geometry -- The polygon geometry covering the area of the Tile.
 *    )
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
begin
   DECLARE
     @v_loCol int,
     @v_hiCol int,
     @v_loRow int,
     @v_hiRow int,
     @v_col   int,
     @v_row   int,
     @v_srid  int = ISNULL(@p_srid,0),
     @v_wkt   nvarchar(max);
   Begin
     SET @v_loCol = FLOOR(   @p_LL_X / @p_TileX );
     SET @v_hiCol = CEILING( @p_UR_X / @p_TileX ) - 1;
     SET @v_loRow = FLOOR(   @p_LL_Y / @p_TileY );
     SET @v_hiRow = CEILING( @p_UR_Y / @p_TileY ) - 1;
     SET @v_col = @v_loCol;
     WHILE ( @v_col <= @v_hiCol )
     BEGIN
       SET @v_row = @v_loRow;
       WHILE ( @v_row <= @v_hiRow )
       BEGIN
         SET @v_wkt = 'POLYGON((' + 
                 CONVERT(varchar(100), ROUND(@v_col * @p_TileX,6))                + ' ' + 
                 CONVERT(varchar(100), ROUND(@v_row * @p_TileY,6))                + ',' +
                 CONVERT(varchar(100), ROUND(((@v_col * @p_TileX) + @p_TileX),6)) + ' ' + 
                 CONVERT(varchar(100), ROUND(@v_row * @p_TileY,6))                + ',' +
                 CONVERT(varchar(100), ROUND(((@v_col * @p_TileX) + @p_TileX),6)) + ' ' + 
                 CONVERT(varchar(100), ROUND(((@v_row * @p_TileY) + @p_TileY),6)) + ',' +
                 CONVERT(varchar(100), ROUND(@v_col * @p_TileX,6))                + ' ' + 
                 CONVERT(varchar(100), ROUND(((@v_row * @p_TileY) + @p_TileY),6)) + ',' +
                 CONVERT(varchar(100), ROUND(@v_col * @p_TileX,6))                + ' ' + 
                 CONVERT(varchar(100), ROUND(@v_row * @p_TileY,6))                + '))';
         INSERT INTO @table (   col,   row,geom)
                     VALUES (@v_col,@v_row,geometry::STGeomFromText(@v_WKT,@p_srid));
         SET @v_row = @v_row + 1;
       END;
       SET @v_col = @v_col + 1;
     END;
     RETURN;
   END;
End
Go

PRINT 'Creating [$(owner)].[STTiler] ...';
GO

CREATE PROCEDURE [$(owner)].[STTiler]
(
  @p_ll_x      float,
  @p_ll_y      float,
  @p_ur_x      float,
  @p_ur_y      float,
  @p_TileX     float,
  @p_TileY     float,
  @p_Srid      Int,
  @p_out_table nvarchar(128),
  @p_geography Int = 1
)
AS
/****f* COGO/STTiler (2012)
 *  NAME
 *    STTiler -- Covers supplied envelope (LL/UR) with a mesh of tiles of size TileX and TileY,
 *               and writes them to a new table created with the supplied name.
 *  SYNOPSIS
 *    Procedure STTiler (
 *               @p_ll_x      float,
 *               @p_ll_y      float,
 *               @p_ur_x      float,
 *               @p_ur_y      float,
 *               @p_TileX     float,
 *               @p_TileY     float,
 *               @p_srid      int,
 *               @p_out_table nvarchar(128),
 *               @p_geography Int = 1
 *             )
 *  USAGE
 *    EXEC [$(owner)].[STTiler] 0, 0, 1000, 1000, 250, 250, 0, '[$(owner)].GridLL', 0;
 *    GO
 *    SELECT COUNT(*) as tableCount FROM [$(owner)].[GridLL];
 *    GO
 *
 *    tableCount
 *    ----------
 *    16
 *    
 *  DESCRIPTION
 *    Procedure that takes a spatial extent (LL/UR), computes the number of tiles that cover it and
 *    The number of columns and rows that cover this area is calculated using @p_TileX/@p_TileY which
 *    are in @p_SRID units.
 *    All rows and columns are visited, with polygons being created that represent each tile.
 *  INPUTS
 *    @p_ll_x         (float) -- Spatial Extent's lower left X/Longitude ordinate.
 *    @p_ll_y         (float) -- Spatial Extent's lower left Y/Latitude  ordinate.
 *    @p_ur_x         (float) -- Spatial Extent's upper right X/Longitude ordinate.
 *    @p_ur_y         (float) -- Spatial Extent's upper right Y/Latitude  ordinate.
 *    @p_TileX        (float) -- Size of a Tile's X dimension in decimal degrees.
 *    @p_TileY        (float) -- Size of a Tile's Y dimension in decimal degrees.
 *    @p_srid           (int) -- Geographic SRID (default is 4326)
 *    @p_out_table (nvarchar) -- Name of table to hold tiles. Can be expressed as DB.OWNER.OBJECT.
 *    @p_geography      (int) -- If 1 (True) column in table will be geography; if 0, geometry.
 *  RESULT
 *    A Table with the name @p_out_table is created with this structure:
 *    Create Table + @p_out_table + 
 *    ( 
 *      gid  Int Identity(1,1) not null, 
 *      geom geometry   -- If @p_geography = 0
 *      geog geography  -- If @p_geography = 1
 *    );
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
begin
   DECLARE
     @v_srid       Int,
     @v_obj_type   varchar(20),
     @v_sql        nvarchar(MAX),
     @v_db         nvarchar(128),
     @v_owner      nvarchar(128),
     @v_object     nvarchar(128),
     @v_geo        nvarchar(128),
     @v_geo_type   nvarchar(128),
     @v_start_time datetime,
     @v_count      BigInt = 0,
     @v_loCol      int,
     @v_hiCol      int,
     @v_loRow      int,
     @v_hiRow      int,
     @v_col        int,
     @v_row        int,
     @v_wkt        nvarchar(max);
   Begin
     SET @v_srid     = ISNULL(@p_srid,4326);
     SET @v_geo      = 'geom';
     SET @v_geo_type = 'geometry';
     If ( ISNULL(@p_geography,1) = 1 )
     BEGIN
       SET @v_geo_type = 'geography';
       SET @v_geo      = 'geog';
     END;
    
     -- If @p_out_table name is fully qualified... we need to split it
     --
     SET @v_object = PARSENAME(@p_out_table,1);
     SET @v_owner  = CASE WHEN PARSENAME(@p_out_table,2) IS NULL THEN 'dbo'     ELSE PARSENAME(@p_out_table,2) END;
     SET @v_db     = CASE WHEN PARSENAME(@p_out_table,3) IS NULL THEN DB_NAME() ELSE PARSENAME(@p_out_table,3) END;
    
     -- Check if object exists with a geography/geometry
     -- NOTE: If table_catalog of table is different from current DB_NAME we need to query
     -- The [INFORMATION_SCHEMA] of that database via dynamic SQL
     --
     SET @v_sql = N'SELECT @object_type = a.[TABLE_TYPE]
                      FROM ' + @v_db + N'.[INFORMATION_SCHEMA].[TABLES] a
                     WHERE a.[TABLE_CATALOG] = @db_in
                       AND a.[TABLE_SCHEMA]  = @owner_in
                       AND a.[TABLE_NAME]    = @object_in';
     BEGIN TRY
       EXEC sp_executesql @query = @v_sql, 
                          @params = N'@object_type nvarchar(128) OUTPUT, @db_in nvarchar(128), @owner_in nvarchar(128), @object_in nvarchar(128)', 
                          @object_type = @v_obj_type OUTPUT, 
                          @db_in       = @v_db, 
                          @owner_in    = @v_owner, 
                          @object_in   = @v_object;
     END TRY
     BEGIN CATCH
       Print 'Could not verify that @p_out_table does not exist. Reason = ' + ERROR_MESSAGE();
       Return;
     END CATCH

     If ( @v_obj_type is not null )
     Begin
       Print 'Table/View with name ' + @p_out_table + ' must not exist.';
       Return;
     End;
    
     -- Create Table
     --
     SET @v_sql = N'Create Table ' + @p_out_table + 
                  N' ( gid Int Identity(1,1) not null, ' +
                  N' ' + @v_geo +N' ' + @v_geo_type +
                  N' )';
     BEGIN TRY
       EXEC sp_executesql @query = @v_sql;
     END TRY
     BEGIN CATCH
       Print 'Could not create output grid table ' + @p_out_table + '. Reason = ' + ERROR_MESSAGE();
       Return;
     END CATCH
    
     SET @v_start_time = getdate();
     SET @v_loCol = FLOOR(   @p_LL_X / @p_TileX );
     SET @v_hiCol = CEILING( @p_UR_X / @p_TileX ) - 1;
     SET @v_loRow = FLOOR(   @p_LL_Y / @p_TileY );
     SET @v_hiRow = CEILING( @p_UR_Y / @p_TileY ) - 1;
     SET @v_col = @v_loCol;
     WHILE ( @v_col <= @v_hiCol )
     BEGIN
       BEGIN TRANSACTION thisColumn;
       SET @v_row = @v_loRow;
       WHILE ( @v_row <= @v_hiRow )
       BEGIN
         SET @v_count = @v_count + 1;
         SET @v_wkt = 'POLYGON((' + 
                 CONVERT(varchar(30),CAST(  @v_col * @p_TileX              as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(  @v_row * @p_TileY              as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST(((@v_col * @p_TileX) + @p_TileX) as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(  @v_row * @p_TileY              as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST(((@v_col * @p_TileX) + @p_TileX) as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(((@v_row * @p_TileY) + @p_TileY) as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST(  @v_col * @p_TileX              as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(((@v_row * @p_TileY) + @p_TileY) as DECIMAL(24,12))) + ',' +
                 CONVERT(varchar(30),CAST(  @v_col * @p_TileX              as DECIMAL(24,12))) + ' ' + 
                 CONVERT(varchar(30),CAST(  @v_row * @p_TileY              as DECIMAL(24,12))) + '))';
         SET @v_sql = N'INSERT INTO ' + @p_out_table + N' (' + @v_geo + N') ' +
                      N'VALUES(' + @v_geo_type + N'::STPolyFromText(@IN_WKT,@IN_Srid))';
         BEGIN TRY
           EXEC sp_executesql @query   = @v_sql, 
                              @params  = N'@in_WKT nvarchar(max), @IN_SRID Int', 
                              @IN_WKT  = @v_WKT, 
                              @IN_SRID = @v_SRID;
         END TRY
         BEGIN CATCH
           Print 'Could not insert grid record into ' + @p_out_table + '. Reason = ' + ERROR_MESSAGE();
           Return;
         END CATCH
         SET @v_row = @v_row + 1;
       END;
       COMMIT TRANSACTION thisColumn;
       SET @v_col = @v_col + 1;
     END;
     PRINT 'Created ' + CAST(@v_count as varchar(10)) + ' grids in: ' + RTRIM(CAST(DATEDIFF(ss,@v_start_time,GETDATE()) as char(10))) + ' seconds!';
     RETURN;
   END;
End
Go

Print 'Testing [$(owner)].[STTileGeom] ...';
GO

SELECT t.col, t.row, t.geom.STAsText() as geom
  FROM [$(owner)].[STTileGeom] (
         geometry::STGeomFromText('POLYGON((100 100, 900 100, 900 900, 100 900, 100 100))',0),
         400,200) as t;
GO
/*
col row geom
--- --- ------------------------------------------------------------
0   0   POLYGON ((0 0, 400 0, 400 200, 0 200, 0 0))
0   1   POLYGON ((0 200, 400 200, 400 400, 0 400, 0 200))
0   2   POLYGON ((0 400, 400 400, 400 600, 0 600, 0 400))
0   3   POLYGON ((0 600, 400 600, 400 800, 0 800, 0 600))
0   4   POLYGON ((0 800, 400 800, 400 1000, 0 1000, 0 800))
1   0   POLYGON ((400 0, 800 0, 800 200, 400 200, 400 0))
1   1   POLYGON ((400 200, 800 200, 800 400, 400 400, 400 200))
1   2   POLYGON ((400 400, 800 400, 800 600, 400 600, 400 400))
1   3   POLYGON ((400 600, 800 600, 800 800, 400 800, 400 600))
1   4   POLYGON ((400 800, 800 800, 800 1000, 400 1000, 400 800))
2   0   POLYGON ((800 0, 1200 0, 1200 200, 800 200, 800 0))
2   1   POLYGON ((800 200, 1200 200, 1200 400, 800 400, 800 200))
2   2   POLYGON ((800 400, 1200 400, 1200 600, 800 600, 800 400))
2   3   POLYGON ((800 600, 1200 600, 1200 800, 800 800, 800 600))
2   4   POLYGON ((800 800, 1200 800, 1200 1000, 800 1000, 800 800))
*/

SELECT row_number() over (order by t.col, t.row) as rid, 
       t.col, t.row, t.geom.STAsText() as geom
  FROM [$(owner)].[STTileXY](0,0,1000,1000,250,250,0) as t;
GO
/*
rid col row geom
--- --- --- -----------------------------------------------------------
 1  0   0   POLYGON ((0 0, 250 0, 250 250, 0 250, 0 0))
 2  0   1   POLYGON ((0 250, 250 250, 250 500, 0 500, 0 250))
 3  0   2   POLYGON ((0 500, 250 500, 250 750, 0 750, 0 500))
 4  0   3   POLYGON ((0 750, 250 750, 250 1000, 0 1000, 0 750))
 5  1   0   POLYGON ((250 0, 500 0, 500 250, 250 250, 250 0))
 6  1   1   POLYGON ((250 250, 500 250, 500 500, 250 500, 250 250))
 7  1   2   POLYGON ((250 500, 500 500, 500 750, 250 750, 250 500))
 8  1   3   POLYGON ((250 750, 500 750, 500 1000, 250 1000, 250 750))
 9  2   0   POLYGON ((500 0, 750 0, 750 250, 500 250, 500 0))
10  2   1   POLYGON ((500 250, 750 250, 750 500, 500 500, 500 250))
11  2   2   POLYGON ((500 500, 750 500, 750 750, 500 750, 500 500))
12  2   3   POLYGON ((500 750, 750 750, 750 1000, 500 1000, 500 750))
13  3   0   POLYGON ((750 0, 1000 0, 1000 250, 750 250, 750 0))
14  3   1   POLYGON ((750 250, 1000 250, 1000 500, 750 500, 750 250))
15  3   2   POLYGON ((750 500, 1000 500, 1000 750, 750 750, 750 500))
16  3   3   POLYGON ((750 750, 1000 750, 1000 1000, 750 1000, 750 750))
*/

BEGIN TRY
  DROP TABLE [$(owner)].[GridLL];
END TRY
BEGIN CATCH
END CATCH
GO
exec [$(owner)].[STTiler] 0, 0, 1000, 1000, 250, 250, 0, '[$(owner)].GridLL', 0;
GO
SELECT COUNT(*) as tableCount FROM [$(owner)].[GridLL];
tableCount
16

QUIT
GO

