-- create schema spdba;

DROP FUNCTION IF EXISTS spdba.ST_VectorAsSegment(geometry);
DROP TYPE     IF EXISTS spdba.segments;

CREATE TYPE spdba.segments AS (
  id      int,
  segment geometry
);

CREATE FUNCTION spdba.ST_VectorAsSegment(
  p_geometry geometry
)
RETURNS SETOF spdba.segments IMMUTABLE 
AS
$$
  SELECT (v.id),
         ST_SetSrid(ST_MakeLine(ST_MakePoint((v.startcoord).x,(v.startcoord).y),
                                ST_MakePoint(  (v.endcoord).x,  (v.endcoord).y)),ST_Srid(p_geometry)) 
    FROM spdba.ST_Vectorize($1) as v;
$$
LANGUAGE 'sql';

select * from spdba.ST_VectorAsSegment('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5),POLYGON((326454.7 5455793.7 1,326621.3 5455813.7 2,326455.4 5455796.6 3,326454.7 5455793.7 4)))'::geometry);
select * from spdba.ST_VectorAsSegment('LINESTRING(0 0, 1 1, 2 2, 3 3)'::geometry) as v;
select * from spdba.ST_VectorAsSegment('MULTILINESTRING((0 0,1 1,1 2),(2 3,3 2,5 4))'::geometry) As GV;
select * from spdba.ST_VectorAsSegment(ST_GeomFromText('POLYGON((326454.7 5455793.7,326621.3 5455813.7,326455.4 5455796.6,326454.7 5455793.7))',28356));
select * from spdba.ST_VectorAsSegment('MULTIPOLYGON(((326454.7 5455793.7,326621.3 5455813.7,326455.4 5455796.6,326454.7 5455793.7)),((326771.6 5455831.6,326924.1 5455849.9,326901.9 5455874.2,326900.7 5455875.8,326888.9 5455867.3,326866 5455853.1,326862 5455851.2,326847.4 5455845.8,326827.7 5455841.2,326771.6 5455831.6)))'::geometry);

