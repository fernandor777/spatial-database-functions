USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STRound]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STRound];
  PRINT 'Dropped [$(owner)].[STRound] ...';
END;
GO

PRINT 'Creating [$(owner)].[STRound] ...';
GO

CREATE FUNCTION [$(owner)].[STRound]
(
  @p_geometry geometry,
  @p_round_xy int = 3,
  @p_round_zm int = 2
)
Returns geometry
/****f* EDITOR/STRound (2008)
 *  NAME
 *    STRound -- Function which rounds the ordinates of the supplied geometry.
 *  SYNOPSIS
 *    Function [$(owner)].[STRound] (
 *               @p_geometry geometry,
 *               @p_round_xy int = 3,
 *               @p_round_zm int = 2
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *    The result of many geoprocessing operations in any spatial type can be geometries 
 *    with ordinates (X, Y etc) that have far more decimal digits of precision than the initial geometry.
 *
 *    Additionally, some input GIS formats, such as shapefiles (which has no associated precision model), 
 *    when loaded, can show far more decimal digits of precision in the created ordinates misrepresenting 
 *    the actual accuracy of the data.
 *
 *    STRound takes a geometry object and some specifications of the precision of any X, Y, Z or M ordinates, 
 *    applies those specifications to the geometry and returns the corrected geometry.
 * 
 *    The @p_round_xy/@p_round_zm values are decimal digits of precision, which are used in TSQL's ROUND function 
 *    to round each ordinate value.
 *  PARAMETERS
 *    @p_geometry (geometry) - supplied geometry of any type.
 *    @p_round_xy (int)      - Decimal degrees of precision to which calculated ordinates are rounded.
 *    @p_round_zm (int)      - Decimal degrees of precision to which calculated ordinates are rounded.
 *  RESULT
 *    geometry -- Input geometry moved by supplied X and Y ordinate deltas.
 *  EXAMPLE
 *    -- Geometry
 *    -- Point
 *    SELECT [dbo].[STRound](geometry::STPointFromText('POINT(0.345 0.282)',0),1,1).STAsText() as RoundGeom
 *    UNION ALL 
 *    -- MultiPoint
 *    SELECT [dbo].[STRound](geometry::STGeomFromText('MULTIPOINT((100.12223 100.345456),(388.839 499.40400))',0),3,1).STAsText() as RoundGeom 
 *    UNION ALL 
 *    -- Linestring
 *    SELECT [dbo].[STRound](geometry::STGeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),2,1).STAsText() as RoundGeom
 *    UNION ALL 
 *    -- LinestringZ
 *    SELECT [dbo].[STRound](geometry::STGeomFromText('LINESTRING(0.1 0.2 0.312,1.4 45.2 1.5738)',0),2,1).AsTextZM() as RoundGeom
 *    UNION ALL 
 *    -- Polygon
 *    SELECT [dbo].[STRound](geometry::STGeomFromText('POLYGON((0 0,10 0,10 10,0 10,0 0))',0),2,1).STAsText() as RoundGeom
 *    UNION ALL 
 *    -- MultiPolygon
 *    SELECT [dbo].[STRound](
 *             geometry::STGeomFromText('MULTIPOLYGON (((160 400, 200.00000000000088 400.00000000000045, 200.00000000000088 480.00000000000017, 160 480, 160 400)), ((100 200, 180.00000000000119 300.0000000000008, 100 300, 100 200)))',0),
 *              2,1).STAsText() as RoundGeom
 *    
 *    RoundGeom
 *    POINT (0.3 0.3)
 *    MULTIPOINT ((100.122 100.345), (388.839 499.404))
 *    LINESTRING (0.1 0.2, 1.4 45.2)
 *    LINESTRING (0.1 0.2 0.3, 1.4 45.2 1.6)
 *    POLYGON ((0 0, 10 0, 10 10, 0 10, 0 0))
 *    MULTIPOLYGON (((160 400, 200 400, 200 480, 160 480, 160 400)), ((100 200, 180 300, 100 300, 100 200)))
 *
 *    -- Geography
 *    -- Can't overload existing STRound so have to use conversion functions.
 *    SELECT [dbo].STToGeography(
 *             [dbo].[STRound](
 *               [dbo].STToGeometry(
 *                     geography::STGeomFromText('LINESTRING(141.29384764892390 -43.93834736282 234.82756,
 *                                                           141.93488793487934 -44.02323872332 235.26384)',
 *                                               4326),
 *                     4326
 *               ),
 *               7,
 *               3
 *             ),
 *             4326
 *           ).AsTextZM() as rGeom;
 *    
 *    rGeom
 *    LINESTRING (141.2938476 -43.9383474 234.828, 141.9348879 -44.0232387 235.264)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding for MySQL.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
Begin
  Declare
     @v_wkt           varchar(max) = '',
     @v_wkt_remainder varchar(max),
     @v_dimensions    varchar(4),
     @v_round_xy      int = 3,
     @v_round_zm      int = 2,
     @v_pos           int = 0,
     @v_x             Float = 0.0,
     @v_y             Float = 0.0,
     @v_z             Float = NULL,
     @v_m             Float = NULL,
     @v_point         geometry;
  Begin
    If ( @p_geometry is NULL ) 
      Return @p_geometry;

    SET @v_dimensions = 'XY' 
                        + case when @p_geometry.HasZ=1 then 'Z' else '' end +
                        + case when @p_geometry.HasM=1 then 'M' else '' end;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);

    -- Shortcircuit for simplest case
    IF ( @p_geometry.STGeometryType() = 'Point' ) 
    BEGIN
      SET @v_wkt = 'POINT(' 
                   +
                   [$(owner)].[STPointAsText] (
                          /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                          /* @p_X          */ ROUND(@p_geometry.STX,@v_round_xy),
                          /* @p_Y          */ ROUND(@p_geometry.STY,@v_round_xy),
                          /* @p_Z          */ ROUND(@p_geometry.Z,@v_round_zm),
                          /* @p_M          */ ROUND(@p_geometry.M,@v_round_zm),
                          /* @p_round_x    */ @v_round_xy,
                          /* @p_round_y    */ @v_round_xy,
                          /* @p_round_z    */ @v_round_zm,
                          /* @p_round_m    */ @v_round_zm
                   )
                   + 
                   ')';
      Return geometry::STPointFromText(@v_wkt,@p_geometry.STSrid);
    END;

    SET @v_wkt_remainder = @p_geometry.AsTextZM();
    SET @v_wkt           = SUBSTRING(@v_wkt_remainder,1,CHARINDEX('(',@v_wkt_remainder));
    SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,  CHARINDEX('(',@v_wkt_remainder)+1,LEN(@v_wkt_remainder));

    WHILE ( LEN(@v_wkt_remainder) > 0 )
    BEGIN
       -- Is the start of v_wkt_remainder a coordinate?
       IF ( @v_wkt_remainder like '[-0-9]%' ) 
        BEGIN
         -- We have a coord
         -- Now get position of end of coordinate string
         SET @v_pos = case when CHARINDEX(',',@v_wkt_remainder) = 0
                           then CHARINDEX(')',@v_wkt_remainder)
                           when CHARINDEX(',',@v_wkt_remainder) <> 0 and CHARINDEX(',',@v_wkt_remainder) < CHARINDEX(')',@v_wkt_remainder)
                           then CHARINDEX(',',@v_wkt_remainder)
                           else CHARINDEX(')',@v_wkt_remainder)
                       end;
         -- Create a geometry point from WKT coordinate string
         SET @v_point = geometry::STPointFromText(
                          'POINT(' 
                          + 
                          SUBSTRING(@v_wkt_remainder,1,@v_pos-1)
                          + 
                          ')',
                          @p_geometry.STSrid);
         -- Apply the delta to the ordinates
         SET @v_x     = ROUND(@v_point.STX,@v_round_xy);
         SET @v_y     = ROUND(@v_point.STY,@v_round_xy);
         SET @v_z     = ROUND(@v_point.Z,  @v_round_zm);
         SET @v_m     = ROUND(@v_point.M,  @v_round_zm);
         -- Add to WKT
         SET @v_wkt   = @v_wkt 
                        + 
                        [$(owner)].[STPointAsText] (
                                /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                                /* @p_X          */ @v_x,
                                /* @p_Y          */ @v_y,
                                /* @p_Z          */ @v_z,
                                /* @p_M          */ @v_m,
                                /* @p_round_x    */ @p_round_xy,
                                /* @p_round_y    */ @p_round_xy,
                                /* @p_round_z    */ @v_round_zm,
                                /* @p_round_m    */ @v_round_zm
                        );
         -- Now remove the old coord from v_wkt_remainder
         SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,@v_pos,LEN(@v_wkt_remainder));
       END
       ELSE
       BEGIN
         -- Move to next character
         SET @v_wkt           = @v_wkt + SUBSTRING(@v_wkt_remainder,1,1);
         SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,2,LEN(@v_wkt_remainder));
       END;
    END; -- Loop
    Return geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
  End;
End
GO

PRINT 'Testing [$(owner)].[STRound] ...';
GO

-- Point
select [$(owner)].[STRound](geometry::STPointFromText('POINT(0.345 0.282)',0),1,1).STAsText() as RoundGeom;
GO

-- MultiPoint
SELECT [$(owner)].[STRound](geometry::STGeomFromText('MULTIPOINT((100.12223 100.345456),(388.839 499.40400))',0),3,1).STAsText() as RoundGeom; 
GO

-- Linestring
select [$(owner)].[STRound](geometry::STGeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),2,1).STAsText() as RoundGeom;
GO

-- LinestringZ
select [$(owner)].[STRound](geometry::STGeomFromText('LINESTRING(0.1 0.2 0.312,1.4 45.2 1.5738)',0),2,1).AsTextZM() as RoundGeom;
GO

-- Polygon
select [$(owner)].[STRound](geometry::STGeomFromText('POLYGON((0 0,10 0,10 10,0 10,0 0))',0),2,1).STAsText() as RoundGeom;
GO

-- MultiPolygon
select [$(owner)].[STRound](
         geometry::STGeomFromText('MULTIPOLYGON (((160 400, 200.00000000000088 400.00000000000045, 200.00000000000088 480.00000000000017, 160 480, 160 400)), ((100 200, 180.00000000000119 300.0000000000008, 100 300, 100 200)))',0),
          2,1).STAsText() as RoundGeom;
GO

-- Geography
-- Can't overload existing STRound so have to use conversion functions.
SELECT [dbo].STToGeography(
         [dbo].[STRound](
           [dbo].STToGeometry(
                 geography::STGeomFromText('LINESTRING(141.29384764892390 -43.93834736282 234.82756,
                                                       141.93488793487934 -44.02323872332 235.26384)',
                                           4326),
                 4326
           ),
           7,
           3
         ),
         4326
       ).AsTextZM() as rGeom;
GO

QUIT
GO
