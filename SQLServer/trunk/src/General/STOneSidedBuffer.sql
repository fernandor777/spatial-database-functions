USE [$(usedbname)]
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STOneSidedBuffer]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STOneSidedBuffer];
  Print 'Dropped [$(owner)].[STOneSidedBuffer] ...';
END;
GO

Print 'Creating [$(owner)].[STOneSidedBuffer] ...';
GO

CREATE FUNCTION [$(owner)].[STOneSidedBuffer]
(
  @p_linestring      geometry,
  @p_buffer_distance Float,   /* -ve is left and +ve is right */
  @p_square          int = 1, /* 1 means square ends, 0 means round ends */
  @p_round_xy        int = 3,
  @p_round_zm        int  = 2
)
Returns geometry 
AS
/****f* GEOPROCESSING/STOneSidedBuffer (2012)
 *  NAME
 *    STOneSidedBuffer -- Creates a square buffer to left or right of a linestring.
 *  SYNOPSIS
 *    Function STOneSidedBuffer (
 *                @p_linestring      geometry,
 *                @p_buffer_distance Float, 
 *                @p_square          int = 1, 
 *                @p_round_xy        int = 3,
 *                @p_round_zm        int = 2
 *             )
 *     Returns geometry
 *  DESCRIPTION
 *    This function creates a square buffer to left or right of a linestring.
 *    To create a buffer to the LEFT of the linestring (direction start to end) supply a negative @p_buffer_distance; 
 *    a +ve value will create a buffer on the right side of the linestring.
 *    Square ends can be created by supplying a positive value to @p_square parameter. 
 *    A value of 0 will create a rounded end at the start or end point.
 *    Where the linestring either crosses itself or starts and ends at the same point, the result may not be as expected.
 *    The final geometry will have its XY ordinates rounded to @p_round_xy of precision.
 *    Support for Z and M ordinates is experimental: where supported the final geometry has its ZM ordinates rounded to @p_round_zm of precision.
 *  NOTES
 *    Supports circular strings and compoundCurves.
 *  INPUTS
 *    @p_linestring (geometry) - Must be a linestring geometry.
 *    @p_distance   (float)    - if < 0 then left side buffer; if > 0 then right sided buffer.
 *    @p_square     (int)      - 0 = no (round mitre); 1 = yes (square mitre)
 *    @p_round_xy   (int)      - Rounding factor for XY ordinates.
 *    @p_round_zm   (int)      - Rounding factor for ZM ordinates.
 *  RESULT
 *    polygon       (geometry) - Result of one sided buffering of a linestring.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Jan 2013 - Original coding (Oracle).
 *    Simon Greener - Nov 2017 - Original coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_wkt               varchar(max),
    @v_GeometryType      varchar(100),
    @v_dimensions        varchar(4),
    @v_square            int = case when ISNULL(@p_square,1) >= 1 then 1 else 0 end,
    @v_round_xy          int,
    @v_round_zm           int,
    @v_buffer_distance   float = ABS(@p_buffer_distance),
    @v_buffer_increment  float,
    @v_sign              int, /* -1 left/+1 right */
    @v_GeomN             int,
    @v_bearing           float,
    @v_linestring        geometry,
    @v_start_linestring  geometry,
    @v_end_linestring    geometry,
    @v_circular_string   geometry,
    @v_point             geometry,
    @v_circle            geometry,
    @v_split_geom        geometry,
    @v_side_geom         geometry,
    @v_buffer            geometry;
  Begin
    If ( @p_linestring is null )
      Return @p_linestring;

    If ( ISNULL(ABS(@p_buffer_distance),0.0) = 0.0 )
      Return @p_linestring;

    SET @v_GeometryType = @p_linestring.STGeometryType();
    -- MultiLineString Supported by alternate processing.
    IF ( @v_GeometryType NOT IN ('LineString','CompoundCurve','CircularString' ) )
      Return @p_linestring;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);

    -- Set flag for STPointFromText
    SET @v_dimensions = 'XY' 
                       + case when @p_linestring.HasZ=1 then 'Z' else '' end 
                       + case when @p_linestring.HasM=1 then 'M' else '' end;

    -- Create buffer around linestring.
    SET @v_sign             = SIGN(@p_buffer_distance);
    SET @v_buffer_distance  = ROUND(ABS(@p_buffer_distance),@v_round_xy+1);
    SET @v_buffer_increment = ROUND(1.0/POWER(10,@v_round_xy+1)*5.0,@v_round_xy+1);

    -- If @p_linestring is a closed ring, use polygon outer ring processing
    -- STEquals with precision
    --
    IF ( @p_linestring.STStartPoint().STEquals(@p_linestring.STEndPoint())=1
      OR [$(owner)].[STEquals] ( 
             @p_linestring.STStartPoint(),
             @p_linestring.STEndPoint(),
             @v_round_xy,
             @v_round_zm,
             @v_round_zm ) = 1 )
    BEGIN
      -- Try and convert to polygon with single outer ring
      IF      @v_GeometryType = 'LineString' 
        SET @v_wkt    = REPLACE(@p_linestring.AsTextZM(),'LINESTRING (','POLYGON ((') + ')'
      ELSE IF @v_geometryType = 'CompoundCurve'
        SET @v_wkt    = REPLACE(@p_linestring.AsTextZM(),'COMPOUNDCURVE (','CURVEPOLYGON ((') + ')'
      ELSE IF @v_geometryType = 'CircularString' 
        SET @v_wkt    = REPLACE(@p_linestring.AsTextZM(),'CIRCULARSTRING (','CURVEPOLYGON ((') + ')';
      -- +ve Buffer outside, -ve buffer inside, so reverse
      SET @v_split_geom = geometry::STGeomFromText(@v_wkt,@p_linestring.STSrid).MakeValid();
      SET @v_buffer = @v_split_geom.STBuffer(-1.0 * @p_buffer_distance).STSymDifference(@v_split_geom);
      Return @v_buffer;
    END;

    SET @v_linestring       = @p_linestring;
    IF ( @v_GeometryType    = 'CompoundCurve' )
    BEGIN
      SET @v_start_linestring = @p_linestring.STCurveN(1);
      SET @v_end_linestring   = @p_linestring.STCurveN(@p_linestring.STNumCurves());
    END
    ELSE
    BEGIN
      SET @v_start_linestring = @p_linestring;
      SET @v_end_linestring   = @p_linestring;
    END;

    -- Create splitting lines at either end at 90 degrees to line direction if square else straght extension..
    -- 

    -- ******************** START OF LINE PROCESSING *************************

    IF ( @v_start_linestring.STGeometryType() = 'LineString' ) 
    BEGIN
      -- Extend original line at start on right or left side of line segment 
      -- depending on sign of offset at 90 degrees to direction of segment
      -- 
      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] ( 
                         [$(cogoowner)].[STBearingBetweenPoints] (
                            @v_start_linestring.STStartPoint(),
                            @v_start_linestring.STPointN(2)
                         )
                         + 
                         case when @v_square = 1 then (@v_sign * 90.0) else 180.0 end
                       );
      SET @v_linestring = [$(cogoowner)].[STAddSegmentByCOGO] (
                             @v_linestring,
                             @v_bearing,
                             @v_buffer_distance + @v_buffer_increment,
                             'START', /* POINT */
                             /* @p_round    */ @v_round_xy+1,
                             /* @p_round_zm */ @v_round_zm 
                           );
    END;

    IF ( @v_start_linestring.STGeometryType() = 'CircularString') 
    BEGIN
      -- Compute curve center
      SET @v_circle = [$(cogoowner)].[STFindCircleFromArc] ( @v_start_linestring );
      -- Is collinear?
      IF ( @v_circle.STStartPoint().STX = -1 and @v_circle.STStartPoint().STY = -1 and @v_circle.STStartPoint().Z = -1 )
        RETURN @v_buffer;
      -- Line from centre to v_start_point is at a tangent (90 degrees) to arc "direction" 
      -- Compute bearing
      -- 
      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] ( 
                         [$(cogoowner)].[STBearingBetweenPoints] (
                            @v_circular_string.STStartPoint(),
                            @v_circle
                         )
                         +
                         case when @v_square = 1 then 0.0 else (@v_sign * 90.0) end
                       );
      -- Create and Add new segment to existing linestring...
      SET @v_linestring = [$(cogoowner)].[STAddSegmentByCOGO] ( 
                             @v_linestring,
                             @v_bearing,
                             (@v_circle.Z /*Radius*/ + @p_buffer_distance + (@v_sign * @v_buffer_increment)),
                             'START', 
                             @v_round_xy+1,
                             @v_round_zm
                          );
    END;

    -- ******************** END OF LINE PROCESSING *************************

    IF ( @v_end_linestring.STGeometryType() = 'LineString')  
    BEGIN
      -- Now Extend at end
      -- 
      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] ( 
                         [$(cogoowner)].[STBearingBetweenPoints] (
                            @v_end_linestring.STPointN(@p_linestring.STNumPoints()-1),
                            @v_end_linestring.STEndPoint()
                         )
                         + 
                         case when @v_square = 1 then (@v_sign * 90.0) else 0.0 end
                       );
      SET @v_linestring = [$(cogoowner)].[STAddSegmentByCOGO] (
                             @v_linestring,
                             @v_bearing,
                             @v_buffer_distance + @v_buffer_increment,
                             'END',  /* POINT */
                             @v_round_xy+1,
                             @v_round_zm
                           );
    END;

    IF ( @v_end_linestring.STGeometryType() = 'CircularString' ) 
    BEGIN
      -- Compute curve center
      SET @v_circle = [$(cogoowner)].[STFindCircleFromArc] ( @v_end_linestring );
      -- Is collinear?
      IF ( @v_circle.STStartPoint().STX = -1 and @v_circle.STStartPoint().STY = -1 and @v_circle.STStartPoint().Z = -1 )
        RETURN @v_buffer;
      -- Line from centre to v_start_point is at a tangent (90 degrees) to arc "direction" 
      -- Compute bearing
      -- 
      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] ( 
                         [$(cogoowner)].[STBearingBetweenPoints] (
                            @v_circular_string.STStartPoint(),
                            @v_circle
                         )
                         +
                         case when @v_square = 1 then 0.0 else (@v_sign * 90.0) end
                       );
      -- Create and Add new segment to existing linestring...
      SET @v_linestring = [$(cogoowner)].[STAddSegmentByCOGO] ( 
                             @p_linestring,
                             @v_bearing,
                             (@v_circle.Z /*Radius*/ + @p_buffer_distance + (@v_sign * @v_buffer_increment)),
                             'END', 
                             @v_round_xy+1,
                             @v_round_zm
                          );
    END;

    -- #########################################################################################
    -- Now, split buffer with modified linestring (using buffer trick) to generate two polygons
    --

    SET @v_buffer     = @p_linestring.STBuffer(@v_buffer_distance);
    SET @v_split_geom = @v_buffer.STDifference(@v_linestring.STBuffer(@v_buffer_increment/10.0));

    -- Find out which polygon is the one we want.
    SET @v_GeomN = 1;
    WHILE ( @v_GeomN <= @v_split_geom.STNumGeometries() )
    BEGIN
      -- Create point on correct side of line at 1/2 buffer distance.
      SET @v_bearing = [$(cogoowner)].[STNormalizeBearing] ( 
                         [$(cogoowner)].[STBearingBetweenPoints] (
                            @p_linestring.STStartPoint(),
                            @p_linestring.STPointN(2)
                         ) 
                         + 
                         (@v_sign * 45.0)
                       );
      SET @v_point   = [$(cogoowner)].[STPointFromCOGO] ( 
                          @p_linestring.STStartPoint(),
                          @v_bearing,
                          @v_buffer_distance / 2.0,
                          @v_round_xy
                       );
      IF ( @v_split_geom.STGeometryN(@v_GeomN).STContains(@v_point) = 1 )
      BEGIN
        SET @v_side_geom = @v_split_geom.STGeometryN(@v_GeomN);
        BREAK;
      END;
      SET @v_GeomN = @v_GeomN + 1;
    END;
    -- #########################################################################################
    -- STRound removes 0.00001 sliver trick that would otherwise be left behind in the data.
    SET @v_side_geom = [$(owner)].[STRound] ( 
                           case when @v_side_geom is null then @v_split_geom else @v_side_geom end,
                           @v_round_xy,
                           @v_round_zm
                       );
    Return case when @v_side_geom.STIsValid()=0 
                then @v_side_geom.MakeValid() 
                else @v_side_geom 
            end;
  End;
End
GO

Print '****************************';
Print 'Test STOneSidedBuffer ...';
GO

with data as (
select 'Ordinary 2 Point Linestring' as test, geometry::STGeomFromText('LINESTRING(0 0, 1 0)',0) as linestring
union all
select 'Self Joining Linestring'     as test, geometry::STGeomFromText('LINESTRING(0 0,1 0,2 3,4 5,2 10,-1 5,0 0)',0) as linestring
union all
select 'Ends within buffer distance' as test, geometry::STGeomFromText('LINESTRING(0 0,1 0,2 3,4 5,2 10,-1 5,0 0.3)',0) as linestring
)
select d.linestring.STAsText() as sqBuff from data as d
union all
select [$(owner)].[STOneSidedBuffer](d.linestring,/*BuffDist*/0.5,/*@p_square*/1,2,1).STAsText() as sqBuff from data as d;
GO

select geometry::STGeomFromText('LINESTRING(0 0, 10 0, 10 10, 0 10,0 0)',0) as geom
union all
select [$(owner)].[STOneSidedBuffer](geometry::STGeomFromText('LINESTRING (0 0, 10 0, 10 10, 0 10,0 0)',0),-1.0,3,2)
union all
select [$(owner)].[STOneSidedBuffer](geometry::STGeomFromText('LINESTRING (0 0, 10 0, 10 10, 0 10,0 0)',0),1.0,3,2);

QUIT
GO

