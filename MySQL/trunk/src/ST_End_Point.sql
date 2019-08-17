DELIMITER $$

USE `gisdb`$$

DROP function IF EXISTS `ST_End_Point`$$

CREATE FUNCTION `ST_End_Point` 
(
  p_geometry geometry
)
RETURNS geometry
/****m* INSPECT/ST_End_Point (1.0)
 *  NAME
 *    ST_End_Point -- Function which returns the last point in supplied geometry inclusive of all parts.
 *  SYNOPSIS
 *    Function ST_End_Point (
 *                p_geometry geometry
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT ST_AsText(
 *              ST_End_Point(
 *                 ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),
 *                 -5.0, 3.2, 3
 *              )
 *           ) as startPoint;
 *
 *    # startPoint
 *    'POINT(1.4 45.2)'
 *  DESCRIPTION
 *    Function that returns last point in supplied geometry.
 *    Standard MySQL ST_EndPoint does not work Multi(Geometry) objects.
 *  INPUTS
 *    p_geometry (geometry) - supplied geometry of any type.
 *  RESULT
 *    point      (geometry) - Last point in Geometry inclusive of all parts.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding for MySQL.
 *  COPYRIGHT
 *    (c) 2012-2017 by TheSpatialDBAdvisor/Simon Greener
 ******/
BEGIN
  DECLARE v_GeometryType Text;
  DECLARE v_Geometry     geometry;
  DECLARE v_recurse      int;
  If ( p_geometry is NULL ) THEN
    Return p_geometry;
  End If;
  SET v_GeometryType = ST_GeometryType(p_geometry);
  SET v_Geometry = p_Geometry;
  SET v_recurse  = 1;
  WHILE (v_recurse = 1) DO
    IF (     v_GeometryType = 'POINT' ) THEN
      Return v_geometry;
    ELSEIF ( v_GeometryType = 'LINESTRING' ) THEN  
      Return ST_EndPoint(v_geometry);
    ELSEIF ( v_GeometryType = 'POLYGON' ) THEN  
      Return ST_EndPoint(ST_ExteriorRing(v_geometry));
    ELSEIF ( v_GeometryType = 'MULTIPOINT') THEN
      Return ST_GeometryN(v_geometry,ST_NumGeometries(v_geometry));
    ELSEIF ( v_GeometryType = 'MULTILINESTRING') THEN
      Return ST_EndPoint(ST_GeometryN(v_geometry,ST_NumGeometries(v_geometry)));
    ELSEIF ( v_GeometryType = 'MULTIPOLYGON' ) THEN  
      Return ST_StartPoint(ST_ExteriorRing(ST_GeometryN(v_geometry,ST_NumGeometries(v_geometry))));
    ELSEIF ( v_GeometryType = 'GEOMETRYCOLLECTION' ) THEN  
      SET v_geometry     = ST_GeometryN(p_geometry,ST_NumGeometries(p_geometry));
      SET v_GeometryType = ST_GeometryType(v_geometry);
    ELSE
      Return v_geometry;
    END IF;
  END WHILE;
END;$$

DELIMITER ;

select ST_AsText(ST_End_Point(ST_PointFromText('POINT(0 1)',0))) as startPoint;
-- # scaledGeom
-- 'POINT(0 3.1)'
-- 
select ST_AsText(ST_End_Point(ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0))) as startPoint;
-- # scaledGeom
-- 'LINESTRING(-0.5 0.32,-7 4.48)'

select ST_AsText(ST_End_Point(ST_GeomFromText('POLYGON((0 0,10 0,10 10,0 10,0 0))',0))) as startPoint;
-- # scaledGeom
-- 'POLYGON((-0 0,-50 301,-50 301,-0 0,-0 0))'

SELECT ST_AsText(ST_End_Point(ST_GeomFromText('MULTIPOINT((100.12223 100.345456),(388.839 499.40400))',0))) as startPoint;

select ST_AsText(ST_End_Point(ST_GeomFromText('MULTILINESTRING((1 1,2 2),(3 3,4 4))',0))) as STARTPOINT;

select ST_AsText(ST_End_Point(ST_GeomFromText('MULTIPOLYGON (((160 400, 200 400, 200 480, 160 480, 160 400)), ((100 200, 180 300, 100 300, 100 200)))',0))) as StartPoint;

select ST_AsText(ST_End_Point(ST_GeomFromText('GEOMETRYCOLLECTION(POINT(199 555),LINESTRING(200 400, 200 480, 160 480, 160 400))',0))) as StartPoint;
select ST_AsText(ST_End_Point(ST_GeomFromText('GEOMETRYCOLLECTION(LINESTRING(200 400, 200 480, 160 480, 160 400),POINT(199 555))',0))) as StartPoint;


