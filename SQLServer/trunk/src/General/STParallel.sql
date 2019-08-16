USE [$(usedbname)]
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

Print '********************************************************************************';
PRINT 'Database Schema Variables are: $(lrsowner)Owner($(lrsowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STParallel]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STParallel];
  Print 'Dropped [$(owner)].[STParallel] ...';
END;
GO

Print 'Creating [$(owner)].[STParallel] ...';
GO

CREATE FUNCTION [$(owner)].[STParallel]
(
  @p_linestring geometry,
  @p_distance   Float, /* -ve is left and +ve is right */
  @p_round_xy   int = 3,
  @p_round_zm   int = 2
)
Returns geometry 
AS
/****f* GEOPROCESSING/STParallel (2012)
 *  NAME
 *    STParallel -- Creates a line at a fixed offset from the input line.
 *  SYNOPSIS
 *    Function STParallel (
 *               @p_linestring geometry,
 *               @p_distance   float, 
 *               @p_round_xy   int = 3,
 *               @p_round_zm   int = 2
 *             )
 *     Returns geometry
 *  DESCRIPTION
 *    This function creates a parallel line at a fixed offset to the supplied line.
 *    To create a line on the LEFT of the linestring (direction start to end) supply a negative @p_distance; 
 *    a +ve value will create a line on the right side of the linestring.
 *    Where the linestring either crosses itself or starts and ends at the same point, the result may not be as expected.
 *    The final geometry will have its XY ordinates rounded to @p_round_xy of precision.
 *    Support for Z and M ordinates is experimental: where supported the final geometry has its ZM ordinates rounded to @p_round_zm of precision.
 *  NOTES
 *    Supports simple linestrings, circular strings and compoundCurves (not multilinestrings).
 *  INPUTS
 *    @p_linestring (geometry) - Must be a linestring geometry.
 *    @p_distance   (float)    - if < 0 then linestring is created on left side of original; if > 0 then offset linestring it to right side of original.
 *    @p_round_xy   (int)      - Rounding factor for XY ordinates.
 *    @p_round_zm   (int)      - Rounding factor for ZM ordinates.
 *  RESULT
 *    linestring    (geometry) - On left or right side of supplied line at required distance.
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
    @v_GeometryType  varchar(100),
    @v_round_xy      int,
    @v_round_zm      int,
    @v_parallel_line geometry,
    @v_side_buffer   geometry,
    @v_modified_line geometry;
  Begin
    If ( @p_linestring is null )
      Return @p_linestring;

    If ( ISNULL(ABS(@p_distance),0.0) = 0.0 )
      Return @p_linestring;

    SET @v_GeometryType = @p_linestring.STGeometryType();
    -- MultiLineString Supported by alternate processing.
    IF ( @v_GeometryType NOT IN ('LineString','CompoundCurve','CircularString' ) )
      Return @p_linestring;

    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_zm = ISNULL(@p_round_zm,2);

    SET @v_side_buffer = [$(owner)].[STOneSidedBuffer] ( 
                            /* @p_linestring        */ @p_linestring, 
                            /* @p_buffer)distance   */ @p_distance, 
                            /* @p_square            */ 1, 
                            /* @p_round    */ @v_round_xy, 
                            /* @p_round_zm */ @v_round_zm 
                         );

    SET @v_parallel_line = @v_side_buffer.STExteriorRing().STDifference(@p_linestring);

    -- Remove start and end segments
    SET @v_parallel_line = [$(owner)].[STDelete] ( 
                              /* @p_geometry          */ @v_parallel_line,
                              /* @p_point_list        */ '1,-1',
                              /* @p_round    */ @v_round_xy, 
                              /* @p_round_zm */ @v_round_zm 
                           );

    Return @v_parallel_line;
  END;
END
GO

Print '****************************';
Print 'Testing ...';
GO

with data as (
select 'Ordinary 2 Point Linestring'  as test,  geometry::STGeomFromText('LINESTRING(0 0, 1 0)',0) as linestring
)
Select f.pGeom.AsTextZM()/*.STBuffer(0.01)*/ as pGeom from (
select d.linestring as pGeom from data as d
union all
select [$(owner)].[STParallel](d.linestring, 0.5,2,1) as pGeom from data as d
union all
select [$(owner)].[STParallel](d.linestring,-0.5,2,1) as pGeom from data as d
) as f;
GO

with data as (
select 'More complex Linestring'  as test,  geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5)',0) as linestring
)
Select f.pGeom.STBuffer(0.01) as pGeom from (
select d.linestring as pGeom from data as d
union all
select [$(owner)].[STParallel](d.linestring, 0.5,2,1) as pGeom from data as d
union all
select [$(owner)].[STParallel](d.linestring,-0.5,2,1) as pGeom from data as d
) as f;
GO

with data as (
select 'Nearly Closed Loop Linestring'  as test,  geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5, 0 -2, 0 -1)',0) as linestring
)
Select f.pGeom.STBuffer(0.01) as pGeom from (
select d.linestring as pGeom from data as d
union all
select [$(owner)].[STParallel](d.linestring, 0.5,2,1) as pGeom from data as d
union all
select [$(owner)].[STParallel](d.linestring,-0.5,2,1) as pGeom from data as d
) as f;
GO

with data as (
select 'Closed Loop Linestring +ve case fails' as test, geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5, 0 -2, 0 0)',0) as linestring
)
Select f.pGeom as pGeom from (
select d.linestring.STBuffer(0.01) as pGeom from data as d
union all
select d.linestring.STBuffer(0.5) as pGeom from data as d
union all
--select [$(owner)].[STParallel](d.linestring, 0.5,2,1) as pGeom from data as d
--union all
select [$(owner)].[STParallel](d.linestring,-0.5,2,1).STBuffer(0.01) as pGeom from data as d
) as f;
GO

QUIT
GO

select geometry::STGeomFromText('POLYGON ((0 0, 1 0, 1 0.5, 0 0.5, 0 0))',0).STExteriorRing().STDifference(geometry::STGeomFromText('LINESTRING (0 0.51, 0 0, 1 0, 1 0.51)',0)).STAsText() as parallelLine;

