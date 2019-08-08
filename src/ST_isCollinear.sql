DROP FUNCTION IF EXISTS spdba.ST_isCollinear(geometry, geometry,geometry);

CREATE FUNCTION spdba.ST_isCollinear (
  p_start_point in geometry,
  p_mid_point   in geometry,
  p_end_point   in geometry
)
RETURNS boolean 
AS
$BODY$
  /****f* GEOPROCESSING/ST_isCollinear
  *  NAME
  *    ST_isCollinear -- Checks three points are collinear
  *  SYNOPSIS
  *    CREATE OR REPLACE FUNCTION spdba.ST_insideLine(
  *        p_start_point in geometry,
  *        p_mid_point   in geometry,
  *        p_end_point   in geometry
  *    )
  *    RETURNS boolean 
  *  ARGUMENTS
  *    p_start_point (geometry) -- Starting point 
  *    p_mid_point   (geometry) -- Mid point 
  *    p_end_point   (geometry) -- End point
  *  RESULT
  *    true or false (boolean) -- Checks if three points are collinear.
  *  DESCRIPTION
  *    This function takes three points and determines if any combination of them forms a straight line (ie are collinear).
  *  EXAMPLE
  *     select spdba.ST_IsCollinear('POINT(0 0)'::geometry,  'POINT(-1 -1)'::geometry,'POINT(1 1)'::geometry);
  *     st_iscollinear
  *     true
  *     select spdba.ST_IsCollinear('POINT(-1 -1)'::geometry,'POINT(0 0)'::geometry,'POINT(1 1)'::geometry);
  *     st_iscollinear
  *     true
  *     select spdba.ST_IsCollinear('POINT(-1 -1)'::geometry,'POINT(0 0)'::geometry,'POINT(1 2)'::geometry);
  *     st_iscollinear
  *     false
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - February 2019, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
DECLARE
  v_azimuth_diff numeric;
Begin
  If ( p_start_point is NULL or p_mid_point is null or p_end_point is null) Then
    Return false;
  End If;
  IF ( ST_GeometryType(p_start_point) != 'ST_Point' 
    OR ST_GeometryType(p_mid_point)   != 'ST_Point'
    OR ST_GeometryType(p_end_point)   != 'ST_Point' ) THEN
    Return false;
  END IF;
  v_azimuth_diff := ST_Azimuth(p_start_point,p_mid_point) 
                  - ST_Azimuth(p_mid_point,p_end_point);
  /*raise notice '% - % = % (%)',ST_Azimuth(p_start_point,p_mid_point),
                               ST_Azimuth(p_mid_point,p_end_point),
                               v_azimuth_diff,
						       PI(); */
  Return v_azimuth_diff = 0.0 or ROUND(ABS(v_azimuth_diff)::numeric,10) = ROUND(PI()::numeric,10);
end;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

select spdba.ST_IsCollinear('POINT(0 0)'::geometry,  'POINT(-1 -1)'::geometry,'POINT(1 1)'::geometry);
select spdba.ST_IsCollinear('POINT(-1 -1)'::geometry,'POINT(0 0)'::geometry,'POINT(1 1)'::geometry);
select spdba.ST_IsCollinear('POINT(-1 -1)'::geometry,'POINT(0 0)'::geometry,'POINT(1 2)'::geometry);

