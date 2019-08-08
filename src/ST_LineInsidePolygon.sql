DROP FUNCTION IF EXISTS spdba.ST_LineInsidePolygon(geometry, numeric, geometry, numeric);

CREATE FUNCTION spdba.ST_LineInsidePolygon(
    p_point     geometry,
    p_bearing   numeric,
    p_polygon   geometry,
    p_tolerance numeric default 0.01
)
RETURNS geometry
LANGUAGE 'plpgsql'

COST 100
IMMUTABLE 
AS $BODY$
/****f* GEOPROCESSING/ST_LineInsidePolygon
  *  NAME
  *    ST_LineInsidePolygon -- Generates line and clips to polygon returning part p_point is within
  *  SYNOPSIS
  *    CREATE OR REPLACE FUNCTION spdba.ST_LineInsidePolygon(
  *        p_point   in geometry,
  *        p_bearing in numeric,
  *        p_length  in numeric,
  *        p_polygon in geometry
  *    )
  *    RETURNS geometry 
  *  ARGUMENTS
  *    p_point   (geometry) -- Starting point which must fall inside p_polygon
  *    p_bearing  (numeric) -- Whole circle bearing in degrees defining direction of line from p_point to the start of the line
  *    p_length   (numeric) -- Line length.
  *    p_polygon (geometry) -- Polygon for which the inside line must be fitted.
  *  RESULT
  *    line       (geometry) -- Line at desired bearing which is clipped to correct polygon part and touches p_polygon.
  *  DESCRIPTION
  *    This function creates a line that lies inside p_polygon but whose start and end points touch p_polygon's boundary.
  *    Line is generated from a starting point and bearings
  *    The algorithm creates line from supplied point the length of the diagonal of the ST_BoundingRectangle of the polygon. 
  *    It then intersects the created line with the polygon to create a set of intersecting lines. 
  *    Each line is processsed to find the one that contains the starting point; this line is returned.
  *  EXAMPLE
  *    select ST_AsText(
  *              spdba.ST_LineInsidePolygon(
  *                ST_SetSrid(ST_Point(82,60),28355),
  *                0.0::numeric,
  *                5.0,
  *                ST_GeomFromText('POLYGON((8.003 66.926, 11.164 70.086, 13.692 70.929, 19.171 70.929, 23.385 70.508, 26.546 70.297, 33.078 71.983, 36.871 74.301, 43.824 75.776, 51.199 75.986, 59.206 74.511, 62.788 71.772, 64.685 70.719, 73.535 71.351, 78.592 69.244, 83.649 64.187, 84.913 62.501, 86.178 57.022, 85.756 53.019, 85.124 49.226, 86.81 45.433, 87.863 40.376, 89.338 37.215, 89.338 32.58, 87.653 27.522, 83.438 18.462, 81.12 15.933, 74.799 17.619, 77.538 25.205, 80.067 30.472, 80.488 37.215, 78.381 41.219, 75.22 53.229, 72.06 60.394, 62.999 63.133, 52.463 65.451, 46.353 66.926, 37.714 63.344, 29.496 62.501, 20.646 61.447, 14.114 62.922, 9.899 61.447, 3.157 63.765, 3.367 64.187, 8.003 66.926))',28355)
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
  *    Simon Greener - February 2019, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
DECLARE
   v_GeometryType varchar(100);
   v_LineN        integer;
   v_nLines       integer;
   v_bearing      numeric;
   v_length       numeric;
   v_tolerance    numeric;
   v_line         geometry;
   v_lGeom        geometry;
   v_intersection geometry;
Begin
    If ( p_point is NULL ) Then
      return p_point;
    End If;
    If ( p_bearing is NULL ) Then
      Return p_point;
    End If;
    If ( p_polygon is NULL ) Then
      return p_polygon;
    End If;
    v_GeometryType := ST_GeometryType(p_point);
    IF ( v_GeometryType != 'ST_Point' ) THEN
      return p_point;
    END IF;
    v_GeometryType := ST_GeometryType(p_polygon);
    IF ( v_GeometryType not in ('ST_Polygon','ST_MultiPolygon') ) THEN
      return p_point;
    END IF;
    v_tolerance := case when p_tolerance is null then 0.01 else p_tolerance end;
    -- raise notice 'ST_LineInsidePolygon tolerance %',v_tolerance;
    -- raise notice '  p_point %',ST_AsText(p_point);
    -- Generate line
    v_bearing := spdba.ST_NormalizeBearing(p_bearing + 180.0);
    v_length  := ST_Length(ST_BoundingDiagonal(p_polygon,false));
    -- raise notice '  v_bearing/p_bearing %/% v_distance=%',v_bearing,p_bearing,v_length;
    v_line := ST_SetSrid(
                    ST_MakeLine(spdba.ST_PointFromCogo(p_point,                          v_bearing::double precision, v_length::double precision),
                                spdba.ST_PointFromCogo(p_point,spdba.ST_NormalizeBearing(p_bearing)::double precision,v_length::double precision)
                    ),
                    ST_Srid(p_point)
                 );
    -- raise notice '  v_line is %',ST_AsText(v_line);
    -- Get intersection elements 
    v_intersection := ST_Intersection(v_line,p_polygon);
    IF ( v_intersection is null  ) THEN
      RAISE NOTICE '  ST_LineInsidePolygon NULL intersection for v_bearing=% v_distance=%', v_bearing, v_distance;
      Return null;
    End If;
    IF ( ST_GeometryType(v_intersection) = 'ST_Point' ) THEN
      Return NULL;
    End If;
    IF ( ST_GeometryType(v_intersection) = 'ST_LineString' ) THEN
      -- RAISE NOTICE '  ST_LineString returned: %',ST_AsText(v_intersection);
      Return v_intersection;
    End If;
    -- Process linestring parts of multilinestring
    -- Comparison at tolerance
    --raise notice '  v_point %',ST_AsText(v_point);
    v_LineN  := 1;
    v_nLines := ST_NumGeometries(v_intersection);
    WHILE (v_lineN <= v_nLines) LOOP
      v_lGeom := ST_SnapToGrid(
                    ST_GeometryN(v_intersection,v_lineN),
                    v_tolerance);
      -- Test if original point and intersected line have a relationship
      -- raise notice '  Testing % of % is disjoint: %',v_lineN,v_nLines,ST_AsText(v_lgeom);
      IF ( ST_Distance(p_point,v_lGeom) <= v_tolerance ) THEN
        -- raise notice '    Not Disjoint';
        -- Is on line
        Return v_lGeom;
      -- ELSE
        -- raise notice '    Disjoint';
      END IF;
      v_lineN := v_lineN + 1;
    END LOOP;
    -- raise notice '  Return NULL';
    -- raise notice 'End';
    Return NULL;
end;
$BODY$;

ALTER FUNCTION spdba.st_lineinsidepolygon(geometry, numeric, geometry, numeric)
    OWNER TO postgres;


