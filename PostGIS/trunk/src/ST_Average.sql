DROP FUNCTION IF EXISTS spdba.ST_Average(geometry, geometry);

CREATE FUNCTION spdba.ST_Average (
  p_first_point  in geometry,
  p_second_point in geometry
)
RETURNS geometry
AS
$BODY$
  /****f* GEOPROCESSING/ST_Average
  *  NAME
  *    ST_Average -- Averages ordinates of 2 Points 
  *  SYNOPSIS
  *    CREATE OR REPLACE FUNCTION spdba.ST_Average(
  *        p_first_point  in geometry,
  *        p_second_point in geometry
  *    )
  *    RETURNS boolean 
  *  ARGUMENTS
  *    p_first_point  (geometry) -- point 
  *    p_second_point (geometry) -- point
  *  RESULT
  *    point (geometry - Average of two points
  *  DESCRIPTION
  *    This function takes two points and averages the ordinates.
  *    If points have different ordinate dimensions, 2D point is returned.
  *  EXAMPLE
  *     select ST_AsText(spdba.ST_Average('POINT(-1 -1)'::geometry,'POINT(1 1)'::geometry)) as aPoint;
  *     aPoint
  *     POINT(0 0)
  *     select ST_AsText(spdba.ST_Average('POINTZ(-1 -1 1)'::geometry,'POINTZ(1 1 2)'::geometry)) as aPoint;
  *     aPoint
  *     POINT(0 0 1.5)
  *     select ST_AsText(spdba.ST_Average('POINTM(-1 -1 1)'::geometry,'POINTM(1 1 2)'::geometry)) as aPoint;
  *     aPoint
  *     POINT(0 0 1.5)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - April 2019, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
DECLARE
  v_avg_point       geometry;
  v_first_dim_flag  smallint ;
  v_second_dim_flag smallint ;
Begin
  If ( p_first_point is NULL or p_second_point is null) Then
    Return case when p_first_point is NULL then p_second_point else p_first_point end;
  End If;
  IF ( ST_GeometryType(p_first_point)  != 'ST_Point' 
    OR ST_GeometryType(p_second_point) != 'ST_Point' ) THEN
    Return case when ST_GeometryType(p_first_point)  = 'ST_Point' then p_first_point 
                when ST_GeometryType(p_second_point) = 'ST_Point' then p_second_point 
                else NULL
           end;
  END IF;
  -- Values are: 0=2d, 1=3dm, 2=3dz, 3=4d.
  v_first_dim_flag  := ST_Zmflag(p_first_point);
  v_second_dim_flag := ST_Zmflag(p_second_point);
  IF (v_first_dim_flag = v_second_dim_flag) THEN
    IF ( v_first_dim_flag = 0 ) THEN
      v_avg_point := ST_MakePoint(
                        (ST_X(p_first_point) + ST_X(p_second_point))/2.0, 
                        (ST_Y(p_first_point) + ST_Y(p_second_point))/2.0); 
    ELSIF ( v_first_dim_flag = 1 ) THEN
      v_avg_point := ST_MakePointM(
                        (ST_X(p_first_point) + ST_X(p_second_point))/2.0, 
                        (ST_Y(p_first_point) + ST_Y(p_second_point))/2.0,
                        (ST_M(p_first_point) + ST_M(p_second_point))/2.0 ); 
    ELSIF ( v_first_dim_flag = 2 ) THEN
      v_avg_point := ST_MakePoint(
                        (ST_X(p_first_point) + ST_X(p_second_point))/2.0, 
                        (ST_Y(p_first_point) + ST_Y(p_second_point))/2.0,
                        (ST_Z(p_first_point) + ST_Z(p_second_point))/2.0); 
    ELSIF ( v_first_dim_flag = 3 ) THEN
      v_avg_point := ST_MakePoint(
                        (ST_X(p_first_point) + ST_X(p_second_point))/2.0, 
                        (ST_Y(p_first_point) + ST_Y(p_second_point))/2.0,
                        (ST_Z(p_first_point) + ST_Z(p_second_point))/2.0,
                        (ST_M(p_first_point) + ST_M(p_second_point))/2.0 ); 
    END IF;	
  ELSE
    v_avg_point := ST_MakePoint(
                      (ST_X(p_first_point) + ST_X(p_second_point))/2.0, 
                      (ST_Y(p_first_point) + ST_Y(p_second_point))/2.0); 
  END IF;

  Return ST_SetSRID(v_avg_point,ST_Srid(p_first_point));

end;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

select ST_AsText(spdba.ST_Average('POINT(-1 -1)'::geometry,'POINT(1 1)'::geometry)) as aPoint;

select ST_AsText(spdba.ST_Average('POINTZ(-1 -1 1)'::geometry,'POINTZ(1 1 2)'::geometry)) as aPoint;

select ST_AsText(spdba.ST_Average('POINTM(-1 -1 1)'::geometry,'POINTM(1 1 2)'::geometry)) as aPoint;

