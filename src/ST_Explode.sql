DROP FUNCTION IF EXISTS spdba.ST_Explode(geometry);

CREATE FUNCTION spdba.ST_Explode(
  p_geometry geometry
)
RETURNS SETOF geometry IMMUTABLE  
AS $$
DECLARE
    v_GeometryType varchar(1000);
    v_rec          RECORD;
Begin
    If ( p_geometry is NULL ) Then
      return;
    End If;
    v_GeometryType := ST_GeometryType(p_geometry);
    --  RAISE NOTICE 'ST_GeometryType %', v_GeometryType;
    IF ( v_GeometryType IN ('ST_GeometryCollection','ST_MultiLineString','ST_MultiPolygon') ) THEN
       FOR v_geomN IN 1..ST_NumGeometries(p_geometry) LOOP
         RETURN NEXT ST_GeometryN(p_geometry,v_geomN);
       END LOOP;
    ELSE
      Return Next p_geometry;
    END IF;
end;
$$ LANGUAGE 'plpgsql';

select * from spdba.ST_Explode('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5),POLYGON((326454.7 5455793.7 1,326621.3 5455813.7 2,326455.4 5455796.6 3,326454.7 5455793.7 4)))'::geometry);
select * from spdba.ST_Explode('LINESTRING(0 0, 1 1, 2 2, 3 3)'::geometry) as v;
select * from spdba.ST_Explode('MULTILINESTRING((0 0,1 1,1 2),(2 3,3 2,5 4))'::geometry) As GV;
select * from spdba.ST_Explode(ST_GeomFromText('POLYGON((326454.7 5455793.7,326621.3 5455813.7,326455.4 5455796.6,326454.7 5455793.7))',28356));
select * from spdba.ST_Explode('MULTIPOLYGON(((326454.7 5455793.7,326621.3 5455813.7,326455.4 5455796.6,326454.7 5455793.7)),((326771.6 5455831.6,326924.1 5455849.9,326901.9 5455874.2,326900.7 5455875.8,326888.9 5455867.3,326866 5455853.1,326862 5455851.2,326847.4 5455845.8,326827.7 5455841.2,326771.6 5455831.6)))'::geometry);

With geoms as (
  select 'LINESTRING(0 0, 1 1, 2 2, 3 3)'::geometry as p_geom
)
SELECT vector_id,
     ST_X(sp) as sx,ST_Y(sp) as sy,ST_Z(sp) as sz,ST_M(sp) as sm,
     ST_X(ep) as ex,ST_Y(ep) as ey,ST_Z(ep) as ez,ST_M(ep) as em
FROM ( SELECT b.pn as vector_id,
	     ST_pointn(b.p_geom, pn-1) as sp,
	     ST_pointn(b.p_geom, pn  ) as ep
	FROM (SELECT generate_series(1, ST_NPoints(p_geom),1) as pn, a.p_geom 
		FROM geoms a
	     ) as b
    ) AS linestring;


