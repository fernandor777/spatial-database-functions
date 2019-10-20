USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: COGO=$(cogoowner) owner=$(owner)';
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STLineOffset]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STLineOffset];
  PRINT 'Dropped [$(owner)].[STLineOffset] ...';
END;
GO

PRINT 'Creating STLineOffset'
GO

CREATE FUNCTION [$(owner)].[STLineOffset]
(
  @p_linestring geometry,
  @p_distance   Float, /* -ve is left and +ve is right */
  @p_round_xy   int = 3,
  @p_round_zm   int = 2
)
Returns geometry 
AS
/****m* GEOPROCESSING/STLineOffset (2012)
 *  NAME
 *    STLineOffset -- Creates a line at a fixed offset from the input line.
 *  SYNOPSIS
 *    Function [$(owner)].[STLineOffset] (
 *               @p_linestring geometry,
 *               @p_distance   float, 
 *               @p_round_xy   int = 3,
 *               @p_round_zm   int = 2
 *             )
 *     Returns geometry
 *  DESCRIPTION
 *    This function creates a parallel line at a fixed offset to the supplied line.
 *    To create a line on the LEFT of the linestring (direction start to end) supply a negative p_distance; 
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
 *    Simon Greener - Oct 2019 - Large scale rewrite. Rename from STParallel to STLineOffset.
 *  COPYRIGHT
 *    (c) 2012-2017 by TheSpatialDBAdvisor/Simon Greener
 *  LICENSE
 *      Creative Commons Attribution-Share Alike 2.5 Australia License.
 *      http://creativecommons.org/licenses/by-sa/2.5/au/
******/
BEGIN
  DECLARE
    @v_GeometryType      varchar(100),
    @v_round_xy          int,
    @v_round_zm          int,
   @v_interior_rings    geometry,
   @v_exterior_rings    geometry,
   @v_linestring        geometry,
   @v_linestring_buffer geometry,
    @v_side_buffer       geometry,
   @v_result_geom       geometry;
  Begin
    If ( @p_linestring is null )
      Return @p_linestring;

    If ( ISNULL(ABS(@p_distance),0.0) = 0.0 )
      Return @p_linestring;

    SET @v_GeometryType = @p_linestring.STGeometryType();
    -- MultiLineString Supported by alternate processing.
    IF ( @v_GeometryType NOT IN ('LineString','CompoundCurve','CircularString' ) )
      Return @p_linestring;

    SET @v_round_xy   = ISNULL(@p_round_xy,3);
    SET @v_round_zm   = ISNULL(@p_round_zm,2);

    SET @v_linestring = [$(owner)].[STRemoveOffsetSegments] (
                           @p_linestring.CurveToLineWithTolerance ( 0.5, 1 ),
                     @p_distance,
                           @v_round_xy, 
                           @v_round_zm 
                        );

    IF ( @v_linestring.STNumPoints() = 2 ) 
      RETURN [$(owner)].[STLineOffsetSegment] ( 
               @v_linestring,
                @p_distance,
                @v_round_xy,
                @v_round_zm
             );

    SET @v_linestring = [$(owner)].[STRound] ( 
                           @v_linestring, 
                           @v_round_xy, 
                           @v_round_zm 
                        );

    -- STOneSidedBuffer rounds ordinates of its result
    SET @v_side_buffer = [$(owner)].[STOneSidedBuffer] ( 
                            /* @p_linestring      */ @v_linestring, 
                            /* @p_buffer)distance */ @p_distance, 
                            /* @p_square          */ 1, 
                            /* @p_round           */ @v_round_xy, 
                            /* @p_round_zm        */ @v_round_zm 
                         ).CurveToLineWithTolerance ( 0.5, 1 );

    -- Inner rings are always part of offset line. 
    SELECT @v_interior_rings = geometry::UnionAggregate(f.eGeom)
     FROM (SELECT v.geom.STExteriorRing() as eGeom
              FROM [$(owner)].[STExtract](@v_side_buffer,1) as v
              WHERE v.sid <> 1 /* Interior ring */
            ) as f;

    SELECT @v_exterior_rings = geometry::UnionAggregate(f.eGeom)
     FROM (SELECT v.geom.STExteriorRing() as eGeom
              FROM [$(owner)].[STExtract](@v_side_buffer,1) as v
              WHERE v.sid = 1 /* Exterior rings */
            ) as f;

     -- Remove original line and any artifaces created in STOneSidedBuffer
     SET @v_linestring_buffer = @v_linestring.STBuffer(ROUND(1.0/POWER(10,@v_round_xy-1),@v_round_xy+1));

     SELECT @v_result_geom =  [$(owner)].[STMakeLineFromMultiPoint] (
              geometry::STGeomFromText('MULTIPOINT (' + STRING_AGG(REPLACE(dbo.STMakePoint(g.x, g.y, g.z, g.m, 0).STAsText(),'POINT ',''),',' ) WITHIN GROUP (ORDER BY g.uid ASC) + ')',0)
            )
       FROM (SELECT d1.uid, d1.x, d1.y, d1.z, d1.m
               FROM dbo.STVertices(@v_exterior_rings) as d1
             EXCEPT
             SELECT d1.uid, d1.x, d1.y, d1.z, d1.m
               FROM dbo.STVertices(/* Exterior ring */ @v_exterior_rings) as d1
              WHERE d1.point.STIntersects(@v_linestring_buffer) = 1
           ) g;

    SET @v_result_geom = @v_result_geom.STUnion(@v_interior_rings);

     Return @v_result_geom;
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
select [$(owner)].[STLineOffset](d.linestring, 0.5,2,1) as pGeom from data as d
union all
select [$(owner)].[STLineOffset](d.linestring,-0.5,2,1) as pGeom from data as d
) as f;
GO

with data as (
select 'More complex Linestring'  as test,  geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5)',0) as linestring
)
Select f.pGeom.STBuffer(0.01) as pGeom from (
select d.linestring as pGeom from data as d
union all
select [$(owner)].[STLineOffset](d.linestring, 0.5,2,1) as pGeom from data as d
union all
select [$(owner)].[STLineOffset](d.linestring,-0.5,2,1) as pGeom from data as d
) as f;
GO

with data as (
select 'Nearly Closed Loop Linestring'  as test,  geometry::STGeomFromText('LINESTRING(0 0, 1 0, 1 1, 10 0, 10 -10, 5 -5, 0 -2, 0 -1)',0) as linestring
)
Select f.pGeom.STBuffer(0.01) as pGeom from (
select d.linestring as pGeom from data as d
union all
select [$(owner)].[STLineOffset](d.linestring, 0.5,2,1) as pGeom from data as d
union all
select [$(owner)].[STLineOffset](d.linestring,-0.5,2,1) as pGeom from data as d
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
--select [$(owner)].[STLineOffset](d.linestring, 0.5,2,1) as pGeom from data as d
--union all
select [$(owner)].[STLineOffset](d.linestring,-0.5,2,1).STBuffer(0.01) as pGeom from data as d
) as f;
GO

SELECT geometry::STGeomFromText('LINESTRING (63.29 914.361, 73.036 899.855, 80.023 897.179, 79.425 902.707, 91.228 903.305, 79.735 888.304, 98.4 883.584, 115.73 903.305, 102.284 923.026, 99.147 899.271, 110.8 902.707, 90.78 887.02, 96.607 926.911, 95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0)
         .STBuffer(0.2)
          as geom
UNION ALL
SELECT [$(owner)].[STLineOffset] (
         geometry::STGeomFromText('LINESTRING (63.29 914.361, 73.036 899.855, 80.023 897.179, 79.425 902.707, 91.228 903.305, 79.735 888.304, 98.4 883.584, 115.73 903.305, 102.284 923.026, 99.147 899.271, 110.8 902.707, 90.78 887.02, 96.607 926.911, 95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0),
         -2.0,
         3,
         1
       ).STAsText() as oGeom;
GO

QUIT
GO


