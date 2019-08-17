DEFINE defaultSchema='&1'

SET SERVEROUTPUT ON
SET TIMING ON
SET PAGESIZE 1000
SET LINESIZE 120
SET LONG 50000
SET VERIFY OFF

Prompt Scale...
SELECT ST_GEOM.ST_Scale(MDSYS.ST_GEOMETRY.FROM_WKT('LINESTRING(1 2, 1 1)'), 0.005, 0.5, 0.75).Get_WKT()
  FROM dual;

SELECT GEOM.AsEWKT(
       GEOM.Tolerance(
       ST_GEOM.ST_Affine(foo.the_geom, 
              cos(Constants.pi()), -sin(Constants.pi()), 0, 
              sin(Constants.pi()), cos(Constants.pi()), -sin(Constants.pi()), 
              0, sin(Constants.pi()), cos(Constants.pi()), 
              0, 0, 0).Get_Sdo_Geom(),
       0.05)
       ) as ST_AsEWKT
	FROM (SELECT MDSYS.ST_GEOMETRY.FROM_SDO_GEOM(SDO_GEOMETRY(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,2,3,1,4,3))) As the_geom 
                FROM dual) foo;

--Change first point in a 2D single linestring from -1 3 to -1 1
SELECT ST_GEOM.ST_SetPoint(a.linestring,a.point,1).Get_WKT() as st_geom
  FROM (SELECT mdsys.OGC_LineStringFromText('LINESTRING(-1 2,-1 3)') as linestring,
               mdsys.OGC_PointFromText('POINT(-1 -1)') as point
          FROM dual) a;

/* Note: PostGIS Equivalent 
SELECT ST_AsText(ST_SetPoint('LINESTRING(-1 2,-1 3)', 0, 'POINT(-1 1)'));
	   st_astext
-----------------------
 LINESTRING(-1 1,-1 3)
*/

--Change first point in a 2D single linestring from -1 3 to -1 1
SELECT ST_GEOM.ST_SetPoint(a.multilinestring,a.point,1).Get_WKT() as st_geom
  FROM (SELECT mdsys.OGC_MultiLineStringFromText('MULTILINESTRING ((1.12345 1.3445, 2.43534 2.03998398, 3.43513 3.451245), (10.0 10.0, 10.0 20.0))') as multilinestring,
               mdsys.OGC_PointFromText('POINT(-1 -1)') as point
          FROM dual) a;

-- ADD point testing
SELECT ST_GEOM.ST_ADDPoint(a.linestring,a.point,null).Get_WKT() as st_geom
  FROM (SELECT mdsys.OGC_LineStringFromText('LINESTRING(1.12345 1.3445,2.43534 2.03998398,3.43513 3.451245)') as linestring,
               mdsys.OGC_PointFromText('POINT(4.555 4.666)') as point
          FROM dual) a;
          
SELECT ST_GEOM.ST_RemovePoint(a.linestring,1).Get_WKT() as st_geom
  FROM (SELECT mdsys.OGC_LineStringFromText('LINESTRING(1.12345 1.3445,2.43534 2.03998398,3.43513 3.451245)') as linestring
          FROM dual) a;

--Change first point in a OGC 2D single linestring from -1 -2 to -1 -1 (ahowa problem with "exactness"
SELECT ST_GEOM.ST_VertexUpdate(a.linestring,a.old_point,a.new_point).Get_WKT() as st_geom
  FROM (SELECT mdsys.OGC_LineStringFromText('LINESTRING(1.12345 1.3445,2.43534 2.03998398,3.43513 3.451245)') as linestring,
               mdsys.OGC_PointFromText('POINT(3.43513 3.451245)') as old_point,
               mdsys.OGC_PointFromText('POINT(29.8 29.9)') as new_point
          FROM dual) a;

-- ************************************
-- ST_SnapToGrid
-- ************************************
SELECT ST_GEOM.ST_SnapToGrid(a.geom,0.005) as st_geom
  FROM (SELECT mdsys.OGC_LineStringFromText('LINESTRING(1.12345 1.3445,2.43534 2.03998398)') as geom 
          FROM dual) a;

SELECT ST_GEOM.ST_SnapToGrid(a.geom,0.005,0.05).Get_WKT() as st_geom
  FROM (SELECT mdsys.OGC_LineStringFromText('LINESTRING(1.12345 1.3445,2.43534 2.03998398)') as geom 
          FROM dual) a;

QUIT;
