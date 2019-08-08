DROP FUNCTION IF EXISTS spdba.ST_InsideLine(geometry,numeric,numeric,geometry,numeric);

CREATE FUNCTION spdba.ST_InsideLine(
    p_point           in geometry,
    p_direction_start in numeric,
    p_direction_end   in numeric,
    p_polygon         in geometry,
    p_dIncrement      in numeric default 5.0
)
RETURNS geometry 
LANGUAGE 'plpgsql'
COST 100
IMMUTABLE 
AS $BODY$
  /****f* GEOPROCESSING/ST_InsideLine
  *  NAME
  *    ST_InsideLine -- Generates a line that is fitted inside a polygon.
  *  SYNOPSIS
  *    CREATE OR REPLACE FUNCTION spdba.ST_insideLine(
  *        p_point           in geometry,
  *        p_direction_start in numeric,
  *        p_direction_end   in numeric default null,
  *        p_polygon         in geometry,
  *        p_dIncrement      in numeric default 5.0
  *    )
  *    RETURNS geometry 
  *  ARGUMENTS
  *    p_point          (geometry) -- Starting point which must fall inside p_polygon
  *    p_direction_start (numeric) -- Whole circle bearing in degrees defining direction of line from p_point to the start of the line
  *    p_direction_end   (numeric) -- Whole circle bearing in degrees defining direction of line from p_point to the end of the line
  *    p_polygon        (geometry) -- Polygon for which the inside line must be fitted.
  *    p_dIncrement      (numeric) -- Line increment (distance) for incrementally extending a line, and testing line to find its boundary intersection point.
  *  RESULT
  *    line        (geometry) -- Line at desired bearing which touches p_polygon at line start and end.
  *  DESCRIPTION
  *    This function creates a line that lies inside p_polygon but whose start and end points touch p_polygon's boundary.
  *    Line is generated from a starting point and two bearings
  *    Algorithm generates a line from supplied point to the line's start point by extending and testing the line by p_dIncrement until it finds a p_polygon boundary.
  *    After finding point for first half of line, the second line is generated using p_direction_end. 
  *    If p_direction_end is null or the same as p_direction_start, a default direction of p_direction_start - 180.0 is used
  *    The algorithm uses a stepping approach: it first creates a line at p_direction_start for p_dIncrement distance.
  *    If the line does not touch a p_polygon boundary point it increases the line length by p_dIncrement and tests again. 
  *    The stepping process continues until the line touches or crosses the boundary.
  *    Once the two halves are created, they are unioned together and the resulting line returned.
  *  EXAMPLE
  *    select ST_AsText(
  *              spdba.ST_insideLine(
  *                ST_SetSrid(ST_Point(82,60),28355),
  *                0.0::numeric,
  *                0.0::numeric,
  *                ST_GeomFromText('POLYGON((8.003 66.926, 11.164 70.086, 13.692 70.929, 19.171 70.929, 23.385 70.508, 26.546 70.297, 33.078 71.983, 36.871 74.301, 43.824 75.776, 51.199 75.986, 59.206 74.511, 62.788 71.772, 64.685 70.719, 73.535 71.351, 78.592 69.244, 83.649 64.187, 84.913 62.501, 86.178 57.022, 85.756 53.019, 85.124 49.226, 86.81 45.433, 87.863 40.376, 89.338 37.215, 89.338 32.58, 87.653 27.522, 83.438 18.462, 81.12 15.933, 74.799 17.619, 77.538 25.205, 80.067 30.472, 80.488 37.215, 78.381 41.219, 75.22 53.229, 72.06 60.394, 62.999 63.133, 52.463 65.451, 46.353 66.926, 37.714 63.344, 29.496 62.501, 20.646 61.447, 14.114 62.922, 9.899 61.447, 3.157 63.765, 3.367 64.187, 8.003 66.926))',28355),
  *                5.0)
  *        ) as geom ;
  *    
  *    geom
  *    text
  *    LINESTRING(82 16.8931035375324,82 60,82 65.836)
  *  NOTES
  *    This is a simplistic approach that is likely to perform slowly.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - November 2018, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
DECLARE
   v_GeometryType varchar(1000);
   v_first        geometry;
   v_second       geometry;
   v_result       geometry;
   v_continue     boolean;
   v_dIncrement   numeric;
   v_bearing      numeric;
   v_distance     numeric;
Begin
    If ( p_point is NULL ) Then
      return p_point;
    End If;
    If ( p_direction_start is NULL ) Then
      Return p_point;
    End If;
    If ( p_polygon is NULL ) Then
      return p_line;
    End If;
    v_GeometryType := ST_GeometryType(p_point);
    IF ( v_GeometryType != 'ST_Point' ) THEN
      return p_point;
    END IF;
    v_GeometryType := ST_GeometryType(p_polygon);
    IF ( v_GeometryType not in ('ST_Polygon','ST_MultiPolygon') ) THEN
      return p_point;
    END IF;
    -- Loop around extending at starting end until first hit polygon
    v_continue := true;
    v_distance := p_dIncrement;
    v_bearing  := p_direction_start;
    -- raise notice 'first v_bearing=%', v_bearing;
    WHILE (v_continue) LOOP
      -- raise notice 'v_distance=%', v_distance;
      v_first := ST_SetSrid(
                    ST_MakeLine(p_point,
                                spdba.ST_PointFromCogo(p_point,v_bearing,v_distance)
                    ),
                    ST_Srid(p_point)
                 );
      -- Test if has hit polygon boundary
      v_continue := ST_Within(v_first,p_polygon);
      -- raise notice 'First ST_Within: %', v_continue;
      v_distance := v_distance + p_dIncrement;
    END LOOP;
    -- Intersect v_first
    v_first := ST_Intersection(v_first,p_polygon);
    -- raise notice 'v_first=%', ST_AsText(v_first);
    -- Second half
    v_continue := true;
    v_distance := p_dIncrement;
    v_bearing  := COALESCE(p_direction_end,p_direction_start);
    -- raise notice 'v_bearing(end)=%', v_bearing;
    v_bearing  := case when v_bearing = p_direction_start then p_direction_start + 180.0 else v_bearing end;
    v_bearing  := case when v_bearing >= 360.0 then v_bearing - 360.0 
                       when v_bearing < 0.0    then v_bearing + 360.0
                       else v_bearing
                   end;
    -- raise notice 'second v_bearing=%', v_bearing;
    WHILE (v_continue) LOOP
      -- raise notice 'v_distance=%', v_distance;
      v_second := ST_SetSrid(
                    ST_MakeLine(p_point,
                                spdba.ST_PointFromCogo(p_point,v_bearing,v_distance)
                    ),
                    ST_Srid(p_point)
                 );
      -- Test if has hit polygon boundary
      v_continue := ST_Within(v_second,p_polygon);
      -- raise notice 'Second ST_Within: %', v_continue;
      v_distance := v_distance + p_dIncrement;
    END LOOP;
    -- Clip v_second by polygon.
    v_second := ST_Intersection(v_second,p_polygon);
    -- raise notice 'v_second=%', ST_AsText(v_second);
    -- Stitch together
    v_result := ST_LineMerge(ST_Union(v_first,ST_Reverse(v_second)));
    Return v_result;
end;
$BODY$;

ALTER FUNCTION spdba.ST_InsideLine(geometry,numeric,numeric,geometry,numeric)
    OWNER TO postgres;

-- Tests
With data as (
  select ST_GeomFromText('POLYGON((8.003 66.926, 11.164 70.086, 13.692 70.929, 19.171 70.929, 23.385 70.508, 26.546 70.297, 33.078 71.983, 36.871 74.301, 43.824 75.776, 51.199 75.986, 59.206 74.511, 62.788 71.772, 64.685 70.719, 73.535 71.351, 78.592 69.244, 83.649 64.187, 84.913 62.501, 86.178 57.022, 85.756 53.019, 85.124 49.226, 86.81 45.433, 87.863 40.376, 89.338 37.215, 89.338 32.58, 87.653 27.522, 83.438 18.462, 81.12 15.933, 74.799 17.619, 77.538 25.205, 80.067 30.472, 80.488 37.215, 78.381 41.219, 75.22 53.229, 72.06 60.394, 62.999 63.133, 52.463 65.451, 46.353 66.926, 37.714 63.344, 29.496 62.501, 20.646 61.447, 14.114 62.922, 9.899 61.447, 3.157 63.765, 3.367 64.187, 8.003 66.926))',28355) as poly
)
--select ST_AsText(ST_PointOnSurface(a.poly)) as poly from data as a;
select spdba.ST_InsideLine(
            ST_SetSrid(ST_Point(82,47),28355),
            generate_series(0,90,20)::numeric,
            null, 
            a.poly,
            5.0)
        as geom 
  from data as a
union all
select poly from data as a;
                        
