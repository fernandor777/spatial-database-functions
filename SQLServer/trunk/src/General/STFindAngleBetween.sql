USE [$(usedbname)]
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(owner)) Cogo($(cogoowner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STFindAngleBetween]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STFindAngleBetween];
  PRINT 'Dropped [$(cogoowner)].[STFindAngleBetween] ...';
END;
GO

IF EXISTS (SELECT * 
             FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[$(cogoowner)].[STFindDeflectionAngle]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(cogoowner)].[STFindDeflectionAngle];
  PRINT 'Dropped [$(cogoowner)].[STFindDeflectionAngle] ...';
END;
GO

PRINT 'Creating [$(cogoowner)].[STFindAngleBetween]...';
GO

CREATE FUNCTION [$(cogoowner)].[STFindAngleBetween]
(
  @p_line      geometry /* LineString/CircularString */,
  @p_next_line geometry /* LineString/CircularString */,
  @p_side      int = -1 /* Left -1; Right +1 */
)
Returns Float
AS
/****f* COGO/STFindAngleBetween (2012)
 *  NAME
 *   STFindAngleBetween - Computes left or right angle between first and second linestrings in the direction from @p_line to @p_next_line
 *  SYNOPSIS
 *    Function STFindAngleBetween
 *               @p_line      geometry 
 *               @p_next_line geometry,
 *               @p_side      int = -1 /* Left -1; Right +1 */
 *             )
 *      Return Float
 *  DESCRIPTION
 *    Supplied with a second linestring (@p_next_line) whose first point is the same as 
 *    the last point of @p_line, this function computes the angle between the two linestrings 
 *    on either the left (-1) or right (+1) side in the direction of the two segments.
 *  NOTES
 *    Only supports CircularStrings from SQL Server Spatial 2012 onwards, otherwise supports LineStrings from 2008 onwards.
 *    @p_line must be first segment whose STEndPoint() is the same as @p_next_line STStartPoint(). No other combinations are supported.
 *  INPUTS
 *    @p_line      (geometry) - A vector that touches the next vector at one end point.
 *    @p_next_line (geometry) - A vector that touches the previous vector at one end point.
 *    @p_side           (int) - The side whose angle is required; 
 *                              A negative value instructs the function to compute the left angle; 
 *                              and a positive value the right angle.
 *  RESULT
 *    angle           (float) - Left or right side angle
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - April 2018 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_side          Float,
    @v_angle_between Float,
    @v_angle         Float,
    @v_prev_point    geometry,
    @v_mid_point     geometry,
    @v_next_point    geometry;
  BEGIN
    IF ( @p_line is null or @p_next_line is null ) 
      Return NULL;

    IF (      @p_line.STGeometryType() NOT IN ('LineString','CircularString') 
      OR @p_next_line.STGeometryType() NOT IN ('LineString','CircularString') 
       )
      Return NULL;

    -- Because we support circularStrings, we support only single segments ....
    IF ( (      @p_line.STGeometryType() = 'LineString'     and      @p_line.STNumPoints() > 2 ) 
      OR ( @p_next_line.STGeometryType() = 'LineString'     and @p_next_line.STNumPoints() > 2 ) 
      OR (      @p_line.STGeometryType() = 'CircularString' and      @p_line.STNumPoints() > 3 )
      OR ( @p_next_line.STGeometryType() = 'CircularString' and @p_next_line.STNumPoints() > 3 ) )
      Return null;

    SET @v_side = ISNULL(@p_side,-1);

    -- Get intersection(mid) point
    SET @v_mid_point = @p_line.STEndPoint();

    -- Intersection point must be shared.
    IF ( @v_mid_point.STEquals(@p_next_line.STStartPoint())=0 )
      return NULL;

    -- Get previous and next points of 3 point angle.
    IF ( @p_line.STGeometryType()='CircularString' ) 
    BEGIN
      SET @v_prev_point = [$(cogoowner)].[STComputeTangentPoint](@p_line,     'END',  8);
      SET @v_next_point = [$(cogoowner)].[STComputeTangentPoint](@p_next_line,'START',8);
    END
    ELSE
    BEGIN
      SET @v_prev_point = @p_line.STStartPoint(); 
      SET @v_next_point = @p_next_line.STEndPoint();
    END;

    SET @v_angle         = [$(cogoowner)].[STDegrees] ( 
                             [$(cogoowner)].[STSubtendedAngleByPoint](
                               /* @p_start  */ @v_prev_point,
                               /* @p_centre */ @v_mid_point,
                               /* @p_end    */ @v_next_point
                             ) 
                           );

    SET @v_angle_between = case when @v_angle < 0 and @v_side < 0 /*left */ then (           ABS( @v_angle ) )
                                when @v_angle < 0 and @v_side > 0 /*right*/ then ( 360.0 +        @v_angle ) 
                                when @v_angle > 0 and @v_side < 0 /*left */ then ( 360.0 + ( -1 * @v_angle ) )
                                when @v_angle > 0 and @v_side > 0 /*right*/ then (           ABS( @v_angle ) )
                                when @v_side = 0                  /*None */ then 0.0
                                else 0.0
                            end;

    Return @v_angle_between;
  END;
END
Go

-- ************************************************************************

PRINT 'Creating [$(cogoowner)].[STFindDeflectionAngle]...';
GO

CREATE FUNCTION [$(cogoowner)].[STFindDeflectionAngle]
(
  @p_from_line geometry /* LineString/CircularString */,
  @p_to_line   geometry /* LineString/CircularString */
)
Returns Float
AS
/****f* COGO/STFindDeflectionAngle (2012)
 *  NAME
 *   STFindDeflectionAngle - Computes deflection angle between from line and to line.
 *  SYNOPSIS
 *    Function STFindDeflectionAngle
 *               @p_from_line geometry 
 *               @p_to_line   geometry
 *             )
 *      Return Float
 *  DESCRIPTION
 *    Supplied with a second linestring (@p_next_line) whose first point is the same as 
 *    the last point of @p_line, this function computes the deflection angle from the first line to the second
 *    in the direction of the first line.
 *  NOTES
 *    Only supports CircularStrings from SQL Server Spatial 2012 onwards, otherwise supports LineStrings from 2008 onwards.
 *    @p_line must be first segment whose STEndPoint() is the same as @p_next_line STStartPoint(). No other combinations are supported.
 *  INPUTS
 *    @p_from_line (geometry) - A linestring segment
 *    @p_to_line   (geometry) - A second linestring segment whose direction is computed from the start linestring direction + deflection angle.
 *  RESULT
 *    angle           (float) - Deflection angle in degrees.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - April 2018 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  DECLARE
    @v_from_bearing     Float,
    @v_to_bearing       Float,
    @v_deflection_angle Float,
    @v_prev_point       geometry,
    @v_mid_point        geometry,
    @v_next_point       geometry;
  BEGIN
    IF ( @p_from_line is null or @p_to_line is null ) 
      Return NULL;

    IF ( @p_from_line.STGeometryType() NOT IN ('LineString','CircularString') 
      OR   @p_to_line.STGeometryType() NOT IN ('LineString','CircularString') 
       )
      Return NULL;

    -- Because we support circularStrings, we support only single segments ....
    IF ( ( @p_from_line.STGeometryType() = 'LineString'     and @p_from_line.STNumPoints() > 2 ) 
      OR (   @p_to_line.STGeometryType() = 'LineString'     and   @p_to_line.STNumPoints() > 2 ) 
      OR ( @p_from_line.STGeometryType() = 'CircularString' and @p_from_line.STNumPoints() > 3 )
      OR (   @p_to_line.STGeometryType() = 'CircularString' and   @p_to_line.STNumPoints() > 3 ) )
      Return null;

    -- Get intersection(mid) point
    SET @v_mid_point = @p_from_line.STEndPoint();

    -- Intersection point must be shared.
    IF ( @v_mid_point.STEquals(@p_to_line.STStartPoint())=0 )
      return NULL;

    -- Get previous and next points of 3 point angle.
    IF ( @p_from_line.STGeometryType()='CircularString' ) 
    BEGIN
      SET @v_prev_point = [$(cogoowner)].[STComputeTangentPoint](@p_from_line,'END',8);
      SET @v_next_point = [$(cogoowner)].[STComputeTangentPoint](@p_to_line,'START',8);
    END
    ELSE
    BEGIN
      SET @v_prev_point = @p_from_line.STStartPoint(); 
      SET @v_next_point = @p_to_line.STEndPoint();
    END;

    SET @v_from_bearing = [$(cogoowner)].[STBearingBetweenPoints] ( 
                               /* @p_start  */ @v_prev_point,
                               /* @p_centre */ @v_mid_point
                           );

    SET @v_to_bearing   = [$(cogoowner)].[STBearingBetweenPoints] ( 
                               /* @p_centre */ @v_mid_point,
                               /* @p_start  */ @v_next_point
                           );

    IF ( @v_from_bearing = @v_to_bearing ) 
      Return 0.0;

    SET @v_deflection_angle = @v_to_bearing - @v_from_bearing;
    SET @v_deflection_angle = case when @v_deflection_angle > 180.0 
                                   then @v_deflection_angle - 360.0
                                   when @v_deflection_angle < -180.0
                                   then @v_deflection_angle + 360.0
                                   else @v_deflection_angle
                               end;
    Return @v_deflection_angle;
  END;
END
Go

PRINT 'Testing ....';
PRINT '************';
GO

With data as (
  select geometry::STGeomFromText('LINESTRING( 0  0, 10 10)',0) as line,
         geometry::STGeomFromText('LINESTRING(10 10, 20 0)',0) as next_line
)
select g.IntValue as side,
       [$(cogoowner)].[STFindAngleBetween] ( a.line, a.next_line, g.Intvalue )
  from data as a
       cross apply
       [$(owner)].[Generate_Series](-1,1,1) as g
 where g.IntValue <> 0
go

With data as (
  select geometry::STGeomFromText('LINESTRING(-5 0, 0 0)',0) as line,
         geometry::STGeomFromText('LINESTRING( 0 0, 5 0)',0) as next_line
)
select offset, rAngle, round(sAngle,1) as sAngle, 
       line.STUnion(rLine).STBuffer(0.3) as line, 
       Round([$(cogoowner)].[STFindAngleBetween] (line,rLine,offset),1) 
/*       round(
          case when sAngle < 0 and offset < 0 /*left */ then (          ABS( sAngle ) )
               when sAngle < 0 and offset > 0 /*right*/ then ( 360.0 +       sAngle ) 
               when sAngle > 0 and offset < 0 /*left */ then ( 360.0 + (-1 * sAngle ) )
               when sAngle > 0 and offset > 0 /*right*/ then (          ABS( sAngle ) )
               when offset = 0                          then 0.0
               else 0.0
           end,1) */
          as angleBetween
  from (select CAST(g.IntValue as float) as offset, rAngle, 
               [$(cogoowner)].[STDegrees] ( [$(cogoowner)].[STSubtendedAngleByPoint] ( f.line.STStartPoint(), f.line.STEndPoint(), f.rline.STEndPoint() ) ) as sAngle,
               line, rLine
          from (select cast(e.IntValue as float) as rAngle,
                       a.line,
                       [$(owner)].[STRotate] (a.next_line,
                                 a.next_line.STStartPoint().STX,
                                 a.next_line.STStartPoint().STY,
                                 CAST(e.IntValue as float),
                                 3,2) as rLine
                  from data as a
                       cross apply
                       [$(owner)].[Generate_Series](0,350,30) as e
              ) as f
              cross apply
              [$(owner)].[Generate_Series](0,1,1) as g
        where g.IntValue <> 0
        ) as g
go

With data as (
  select geometry::STGeomFromText('LINESTRING(-5 0, 0 0)',0) as line,
         geometry::STGeomFromText('LINESTRING( 0 0, 5 0)',0) as next_line
)
select round([$(cogoowner)].[STBearingBetweenPoints](Line.STStartPoint(),Line.STEndPoint()),1) as fromBearing,
       rotationAngle, 
       round([$(cogoowner)].[STBearingBetweenPoints](rLine.STStartPoint(),rLine.STEndPoint()),1) as toBearing,
       Round([$(cogoowner)].[STFindDeflectionAngle] (line,rLine),1)  as deflectionAngle,
       line.STUnion(rLine).STBuffer(0.3) as line
  from (select cast(e.IntValue as float) as rotationAngle,
               a.line,
               [$(owner)].[STRotate] (a.next_line,
                                 a.next_line.STStartPoint().STX,
                                 a.next_line.STStartPoint().STY,
                                 CAST(e.IntValue as float),
                                 3,2) as rLine
                  from data as a
                       cross apply
                       [$(owner)].[Generate_Series](0,350,30) as e
       ) as f;
GO

QUIT
GO

