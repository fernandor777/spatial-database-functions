-- ****************************************************************************************************
-- Drop functions and type.

DROP     TYPE IF EXISTS spdba.T_Grid cascade;
DROP FUNCTION IF EXISTS spdba.ST_RegularGridXYSQL(numeric,numeric,numeric,numeric,numeric,numeric,int4);
DROP FUNCTION IF EXISTS spdba.ST_RegularGridSQL(geometry,numeric,numeric);
DROP FUNCTION IF EXISTS spdba.ST_RegularGrid(geometry,numeric,numeric);
DROP FUNCTION IF EXISTS spdba.ST_RegularGridXY(numeric,numeric,numeric,numeric,numeric,numeric,int4);

-- ****************************************************************************************************
-- Create types

CREATE TYPE T_Grid AS (
 gcol  int4,
 grow  int4,
 geom  geometry
);

-- ****************************************************************************************************
-- Create functions

CREATE FUNCTION spdba.ST_RegularGrid(
  p_geometry   geometry,
  p_TileSizeX  numeric,
  p_TileSizeY  numeric
)
Returns SETOF T_Grid IMMUTABLE
As $$
DECLARE
   v_loCol int4;
   v_hiCol int4;
   v_loRow int4;
   v_hiRow int4;
   v_geom  geometry;
   v_grid  t_grid;
Begin
   v_loCol := trunc( (ST_XMIN(p_geometry) / p_TileSizeX)::numeric );
   v_hiCol := ceil(  (ST_XMAX(p_geometry) / p_TileSizeX)::numeric ) - 1;
   v_loRow := trunc( (ST_YMIN(p_geometry) / p_TileSizeY)::numeric );
   v_hiRow := ceil(  (ST_YMAX(p_geometry) / p_TileSizeY)::numeric ) - 1;
   For v_col in v_loCol..v_hiCol Loop
     For v_row in v_loRow..v_hiRow Loop
         v_geom := ST_SetSRID(ST_MakeBox2D(ST_Point(( v_col * p_TileSizeX),               (v_row * p_TileSizeY)),
                                           ST_Point(((v_col * p_TileSizeX)+p_TileSizeX), ((v_row * p_TileSizeY)+p_TileSizeY))),
                                           ST_Srid(p_geometry));
         SELECT v_col,v_row,v_geom INTO v_grid;
         -- SELECT v_col,v_row,ST_GeomFromText('POINT(' || v_col || ' ' || v_row ||')',0) INTO v_gridType;
         RETURN NEXT v_grid;
     End Loop;
   End Loop;
END;
$$ LANGUAGE 'plpgsql';

CREATE FUNCTION spdba.ST_RegularGridSQL(
  p_geometry  geometry,
  p_TileSizeX numeric,
  p_TileSizeY numeric
)
  RETURNS SETOF T_Grid IMMUTABLE 
AS
$$
  SELECT * FROM spdba.ST_RegularGrid($1,$2,$3);
$$
LANGUAGE 'sql';
  
CREATE FUNCTION spdba.ST_RegularGridXY(
  p_xmin       numeric,
  p_ymin       numeric,
  p_xmax       numeric,
  p_ymax       numeric,
  p_TileSizeX  numeric,
  p_TileSizeY  numeric,
  p_srid       int4
)
Returns SETOF T_Grid IMMUTABLE
As $$
DECLARE
   v_loCol int4;
   v_hiCol int4;
   v_loRow int4;
   v_hiRow int4;
   v_geom  geometry;
   v_grid  t_grid;
Begin
   v_loCol := trunc((p_XMIN / p_TileSizeX)::numeric );
   v_hiCol := ceil( (p_XMAX / p_TileSizeX)::numeric ) - 1;
   v_loRow := trunc((p_YMIN / p_TileSizeY)::numeric );
   v_hiRow := ceil( (p_YMAX / p_TileSizeY)::numeric ) - 1;
   For v_col in v_loCol..v_hiCol Loop
     For v_row in v_loRow..v_hiRow Loop
         v_geom := ST_SetSRID(ST_MakeBox2D(ST_Point(( v_col * p_TileSizeX),               (v_row * p_TileSizeY)),
                                           ST_Point(((v_col * p_TileSizeX)+p_TileSizeX), ((v_row * p_TileSizeY)+p_TileSizeY))),
                                           p_srid);
         SELECT v_col,v_row,v_geom INTO v_grid;
         -- SELECT v_col,v_row,ST_GeomFromText('POINT(' || v_col || ' ' || v_row ||')',0) INTO v_grid;
         RETURN NEXT v_grid;
     End Loop;
   End Loop;
END;
$$ LANGUAGE 'plpgsql';


CREATE FUNCTION spdba.ST_RegularGridXYSQL(
  p_xmin       numeric,
  p_ymin       numeric,
  p_xmax       numeric,
  p_ymax       numeric,
  p_TileSizeX  numeric,
  p_TileSizeY  numeric,
  p_srid       int4
)
  RETURNS SETOF T_Grid IMMUTABLE 
AS
$$
  SELECT * FROM spdba.ST_RegularGridXY($1,$2,$3,$4,$5,$6,$7);
$$
LANGUAGE 'sql';

-- *************************************************************************************************************
-- Testing....

drop table multiPoint;

CREATE TABLE multiPoint as
WITH geomQuery AS (
SELECT ST_XMIN(g.geom)::numeric as xmin, round(ST_XMAX(g.geom)::numeric,2)::numeric as xmax, 
       ST_YMIN(g.geom)::numeric as ymin, round(ST_YMAX(g.geom)::numeric,2)::numeric as ymax,
       g.geom, 0.050::numeric as gridX, 0.050::numeric as gridY, 0::int4 as loCol, 0::int4 as loRow
  FROM (SELECT ST_SymDifference(ST_Buffer(a.geom,1.000::numeric),ST_Buffer(a.geom,0.50::numeric)) as geom 
          FROM (SELECT ST_GeomFromText('MULTIPOINT((09.25 10.00),(10.75 10.00),(10.00 10.75),(10.00 9.25))',0) as geom ) as a
       ) as g 
)
SELECT row_number() over (order by f.gcol, f.grow) as tid,
       ST_Morton((f.gcol-f.loCol),(f.grow-f.loRow)) as mkey,
       f.gcol,
       f.grow,
       count(*) as UnionedTileCount,
       ST_Union(f.geom) as geom
  FROM (SELECT case when ST_GeometryType(b.geom) in ('ST_Polygon','ST_MultiPolygon')
                    then ST_Intersection(b.ageom,b.geom) 
                    else b.geom
                end as geom, 
               b.gcol, b.grow, b.loCol, b.loRow
          FROM (SELECT a.geom as ageom, a.loCol, a.loRow,
                       (spdba.ST_RegularGridXYSQL(a.xmin,a.ymin,a.xmax,a.ymax,a.gridX,a.gridY,ST_Srid(a.geom))).*
                  FROM geomQuery as a 
                ) as b
         WHERE ST_Intersects(b.ageom,b.geom) 
        ) as f 
 WHERE position('POLY' in UPPER(ST_AsText(f.geom))) > 0
 GROUP BY f.gcol, f.grow, f.loCol, f.loRow
 ORDER BY  2;

drop   table multiPoint2;

CREATE TABLE multiPoint2 as
WITH geomQuery AS (
SELECT g.rid,
       (min(ST_XMIN(g.geom))                   over (partition by g.pid))::numeric  as xmin, 
       (max(round(ST_XMAX(g.geom)::numeric,2)) over (partition by g.pid))::numeric as xmax, 
       (min(ST_YMIN(g.geom))                   over (partition by g.pid))::numeric as ymin, 
       (max(round(ST_YMAX(g.geom)::numeric,2)) over (partition by g.pid))::numeric as ymax,
       g.geom, 0.050::numeric as gridX, 0.050::numeric as gridY, 0::int4 as loCol, 0::int4 as loRow
  FROM (SELECT 1::int4 as pid, a.rid, ST_SymDifference(ST_Buffer(a.geom,1.000::numeric),ST_Buffer(a.geom,0.750::numeric)) as geom 
          FROM (SELECT 1::int4 as rid, ST_GeomFromText('POINT(09.50 10.00)',0) as geom
      UNION ALL SELECT 2::int4 as rid, ST_GeomFromText('POINT(10.50 10.00)',0) as geom
      UNION ALL SELECT 3::int4 as rid, ST_GeomFromText('POINT(10.00 10.50)',0) as geom
      UNION ALL SELECT 4::int4 as rid, ST_GeomFromText('POINT(10.00 09.50)',0) as geom ) a
       ) g                         
)
SELECT row_number() over (order by f.gcol, f.grow) as tid,
       ST_Morton((f.gcol-f.loCol),(f.grow-f.loRow)) as mkey,
       f.gcol,
       f.grow,
       count(*) as UnionedTileCount,
       ST_Union(f.geom) as geom
  FROM (SELECT case when ST_GeometryType(b.geom) in ('ST_Polygon','ST_MultiPolygon')
                    then ST_Intersection(b.ageom,b.geom) 
                    else b.geom
                end as geom, 
               b.gcol, b.grow, b.loCol, b.loRow
          FROM (SELECT a.geom as ageom, a.loCol, a.loRow,
                       (spdba.ST_RegularGridXYSQL(a.xmin,a.ymin,a.xmax,a.ymax,a.gridX,a.gridY,ST_Srid(a.geom))).*
                  FROM geomQuery a 
                ) b
         WHERE ST_Intersects(b.ageom,b.geom) 
        ) f 
 WHERE position('POLY' in UPPER(ST_AsText(f.geom))) > 0
 GROUP BY f.gcol, f.grow, f.loCol, f.loRow
 ORDER BY  2;
 -- 2136 

SELECT (spdba.ST_RegularGridXYSQL(0.0,0.0,300.0,300.0,30.0,30.0,82469)).*;


