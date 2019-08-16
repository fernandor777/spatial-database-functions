-- create schema spdba;

DROP FUNCTION IF EXISTS spdba.ST_Vectorize(geometry);
DROP TYPE     IF EXISTS spdba.vectortype;
DROP TYPE     IF EXISTS spdba.coordtype;

CREATE TYPE spdba.coordtype AS (
  x double precision,
  y double precision,
  z double precision,
  m double precision
);

CREATE TYPE spdba.vectortype AS (
  id         int,
  startcoord spdba.coordtype,
  endcoord   spdba.coordtype
);

CREATE TYPE spdba.segments AS (
  id      int,
  segment geometry
);

CREATE FUNCTION spdba.ST_Vectorize(
  p_geometry geometry
)
RETURNS SETOF spdba.VectorType IMMUTABLE  
AS $$
DECLARE
    v_GeometryType   varchar(1000);
    v_rec            RECORD;
    v_vector_id      int;
    v_vector         spdba.VectorType;
    v_start          spdba.CoordType;
    v_end            spdba.CoordType;
    c_points CURSOR ( p_geom geometry ) 
    IS
      SELECT ST_X(sp) as sx,ST_Y(sp) as sy,ST_Z(sp) as sz,ST_M(sp) as sm,
             ST_X(ep) as ex,ST_Y(ep) as ey,ST_Z(ep) as ez,ST_M(ep) as em
        FROM (SELECT ST_PointN(p_geom, generate_series(1, ST_NPoints(p_geom)-1)) as sp,
                     ST_PointN(p_geom, generate_series(2, ST_NPoints(p_geom)  )) as ep
               WHERE ST_GeometryType(p_geom) = 'ST_LineString'
              UNION ALL
              SELECT ST_PointN(b.geom, generate_series(1, ST_NPoints(b.geom)-1)) as sp,
                     ST_PointN(b.geom, generate_series(2, ST_NPoints(b.geom)  )) as ep
                FROM (SELECT ST_GeometryN(p_geom,generate_series(1,ST_NumGeometries(p_geom))) as geom
                       WHERE ST_GeometryType(p_geom) = 'ST_MultiLineString' 
                     ) as b
              UNION ALL
              SELECT ST_PointN(a.geom, generate_series(1, ST_NPoints(a.geom)-1)) as sp,
                     ST_PointN(a.geom, generate_series(2, ST_NPoints(a.geom)  )) as ep
                FROM ( SELECT ST_ExteriorRing(p_geom) as geom
                       UNION ALL
                       SELECT ST_InteriorRingN(p_geom,generate_series(1,ST_NumInteriorRings(p_geom))) as geom
                     ) a
               WHERE ST_GeometryType(p_geom) = 'ST_Polygon'
              UNION ALL
              SELECT ST_PointN(a.geom, generate_series(1, ST_NPoints(a.geom)-1)) as sp,
                     ST_PointN(a.geom, generate_series(2, ST_NPoints(a.geom)  )) as ep
                FROM ( SELECT ST_ExteriorRing(b.geom) as geom
                         FROM (SELECT ST_GeometryN(p_geom,generate_series(1,ST_NumGeometries(p_geom))) as geom) as b
                       UNION ALL
                       SELECT ST_InteriorRingN(c.geom,generate_series(1,ST_NumInteriorRings(c.geom))) as geom
                         FROM (SELECT ST_GeometryN(p_geom,generate_series(1,ST_NumGeometries(p_geom))) as geom) as c    
                     ) a
               WHERE ST_GeometryType(p_geom) = 'ST_MultiPolygon'
             ) as f;
Begin
    If ( p_geometry is NULL ) Then
      return;
    End If;
    v_GeometryType := ST_GeometryType(p_geometry);
    --  RAISE NOTICE 'ST_GeometryType %', v_GeometryType;
    IF  ( v_GeometryType in ('ST_Point','ST_MultiPoint','ST_Geometry') ) Then
      return;
    END IF;
    IF ( v_GeometryType IN ('ST_GeometryCollection') ) THEN
       FOR v_geom IN 1..ST_NumGeometries(p_geometry) LOOP
          FOR v_rec IN SELECT * FROM spdba.ST_Vectorize(ST_GeometryN(p_geometry,v_geom)) LOOP
             RETURN NEXT v_rec;
          END LOOP;
       END LOOP;
    ELSE 
      v_vector_id = 0;
      OPEN c_points(p_geometry);
      LOOP
        v_vector_id = v_vector_id + 1;
        FETCH c_points INTO 
              v_start.x, v_start.y, v_start.z, v_start.m,
              v_end.x,   v_end.y,   v_end.z,   v_end.m;
        v_vector.id         := v_vector_id;
        v_vector.startcoord := v_start;
        v_vector.endcoord   := v_end;
        EXIT WHEN NOT FOUND;
        RETURN NEXT v_vector;
      END LOOP;
      CLOSE c_points;
    END IF;
end;
$$ LANGUAGE 'plpgsql';

select * from spdba.ST_Vectorize('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5),POLYGON((326454.7 5455793.7 1,326621.3 5455813.7 2,326455.4 5455796.6 3,326454.7 5455793.7 4)))'::geometry);
select * from spdba.ST_Vectorize('LINESTRING(0 0, 1 1, 2 2, 3 3)'::geometry) as v;
select * from spdba.ST_Vectorize('MULTILINESTRING((0 0,1 1,1 2),(2 3,3 2,5 4))'::geometry) As GV;
select * from spdba.ST_Vectorize(ST_GeomFromText('POLYGON((326454.7 5455793.7,326621.3 5455813.7,326455.4 5455796.6,326454.7 5455793.7))',28356));
select * from spdba.ST_Vectorize('MULTIPOLYGON(((326454.7 5455793.7,326621.3 5455813.7,326455.4 5455796.6,326454.7 5455793.7)),((326771.6 5455831.6,326924.1 5455849.9,326901.9 5455874.2,326900.7 5455875.8,326888.9 5455867.3,326866 5455853.1,326862 5455851.2,326847.4 5455845.8,326827.7 5455841.2,326771.6 5455831.6)))'::geometry);

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

