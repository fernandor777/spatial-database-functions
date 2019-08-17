DELIMITER $$

USE `gisdb`$$

DROP function IF EXISTS `ST_Round`$$

CREATE FUNCTION `ST_Round`
(
  p_geometry geometry,
  p_round_xy int
)
Returns geometry
/****m* TOOLS/ST_Round (1.0)
 *  NAME
 *    ST_Round -- Function which rounds the XY ordinates of a geometry to the supplied number of decimal digits.
 *  SYNOPSIS
 *    Function ST_Round ( 
 *                p_geometry geometry,
 *                p_round_xy int 
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT ST_AsText(ST_Round(ST_GeomFromText('POINT(100.12223 100.345456)',0),2)) as rGeom; 
 *              ST_Round(
 *                 ST_GeomFromText('POINT(100.12223 100.345456)',0),
 *                 2)
 *           ) as rGeom; 
 *
 *    # rGeom
 *    'POINT(100.12 100.35)'
 *  DESCRIPTION
 *    The ordinates of the supplied geometry are rounded to p_round_xy number of decimal digits of precision.
 *  INPUTS
 *    p_geometry (geometry) - supplied geometry of any type.
 *    p_round_xy (int)      - Decimal degrees of precision to which the geometry's XY ordinates are rounded.
 *  RESULT
 *    geometry   (geometry) - Input geometry rounded to the supplied number of decimal digits of precision.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding for MySQL.
 *  COPYRIGHT
 *    (c) 2012-2017 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  Declare v_wkt           TEXT;
  Declare v_wkt_remainder TEXT;
  Declare v_round_xy      int;
  Declare v_pos           int;
  Declare v_x             double;
  Declare v_y             double;

  If ( p_geometry is NULL ) THEN
    Return p_geometry;
  End If;

  SET v_round_xy = COALESCE(p_round_xy,3);
  
  -- Shortcircuit for simplest case
  IF ( ST_GeometryType(p_geometry) = 'POINT' ) THEN
    SET v_x   = ROUND(ST_X(p_geometry),v_round_xy);
    SET v_y   = ROUND(ST_Y(p_geometry),v_round_xy);           
    SET v_wkt = CONCAT_WS('','POINT(',LTRIM( CAST( v_x as CHAR(50))),' ',LTRIM( CAST( v_y as CHAR(50))),')');
    Return ST_PointFromText(v_wkt,ST_SRID(p_geometry));
  END IF;

  -- Set up WKT variables. Remove geometrytype tag in one hit
  SET v_wkt_remainder = ST_AsText(p_geometry);
  SET v_wkt           = SUBSTR(v_wkt_remainder,1,INSTR(v_wkt_remainder,'('));
  SET v_wkt_remainder = SUBSTR(v_wkt_remainder,INSTR(v_wkt_remainder,'(')+1,LENGTH(v_wkt_remainder));
  WHILE ( LENGTH(v_wkt_remainder) > 0 ) DO
    -- Is the start of v_wkt_remainder a coordinate?
    IF ( v_wkt_remainder REGEXP '^[-0-9]' ) THEN
      -- We have a coord
      -- Generate replacement coord from geometry point (better than unnecessary string manipulation)
      -- Now get position of end of coordinate 
      SET v_pos = case when INSTR(v_wkt_remainder,',') = 0
                       then INSTR(v_wkt_remainder,')')
                       when INSTR(v_wkt_remainder,',') <> 0 and INSTR(v_wkt_remainder,',') < INSTR(v_wkt_remainder,')')
                       then INSTR(v_wkt_remainder,',')
                       else INSTR(v_wkt_remainder,')')
                   end;
      -- Get ordinates as numbers
      SET v_x      = CAST(SUBSTR(v_wkt_remainder,1,INSTR(v_wkt_remainder,' ')-1) as decimal(38,10));
      SET v_y      = CAST(SUBSTR(v_wkt_remainder,INSTR(v_wkt_remainder,' ')+1,v_pos-1) as decimal(38,10));
      -- Compute moved ordinates
      SET v_x      = ROUND(v_x,v_round_xy);
      SET v_y      = ROUND(v_y,v_round_xy);
      -- Add to WKT
      SET v_wkt    = CONCAT(v_wkt,LTRIM(CAST(v_x as CHAR(50))),' ',LTRIM(CAST(v_y as CHAR(50))));
      -- Remove the old coord from v_wkt_remainder
      SET v_wkt_remainder = SUBSTR(v_wkt_remainder,v_pos,LENGTH(v_wkt_remainder));
    ELSE
      -- Move to next character
      SET v_wkt           = CONCAT(v_wkt,SUBSTR(v_wkt_remainder,1,1));
      SET v_wkt_remainder = SUBSTR(v_wkt_remainder,2,LENGTH(v_wkt_remainder));
    END IF;
  END WHILE; 
  RETURN ST_GeomFromText(v_wkt,ST_SRID(p_geometry));
END;$$

DELIMITER ;

/* ************************ TESTING *****************************/

-- Point
SELECT ST_AsText(ST_Round(ST_GeomFromText('POINT(100.12223 100.345456)',0),2)) as rGeom; 
-- # rGeom
-- 'POINT(100.12 100.35)'
-- Point
SELECT ST_AsText(ST_Round(ST_GeomFromText('POINT(200.00000000000088 400.00000000000045)',0),2)) as rGeom; 
-- # rGeom
-- 'POINT(200 400)'
-- MultiPoint
SELECT ST_AsText(ST_Round(ST_GeomFromText('MULTIPOINT((100.12223 100.345456),(38832.839 4949.40400))',0),2)) as rGeom; 
-- # rGeom
-- 'MULTIPOINT((100.12 100.12),(38832.84 38832.84))'
-- Linestring
select ST_AsText(ST_Round(ST_GeomFromText('LINESTRING(0.1342 0.2322,1.2324 45.122)',0),2)) as rGeom;
-- # rGeom
-- 'LINESTRING(0.13 0.13,1.23 1.23)'
-- Polygon
select ST_AsText(
        ST_Round(
          ST_GeomFromText('POLYGON((160 400, 200.00000000000088 400.00000000000045, 200.00000000000088 480.00000000000017, 160 480, 160 400))',0),
          1)) as rGeom;
-- # rGeom
-- 'POLYGON((160 160,200 200,200 200,160 160,160 160))'
-- MultiPolygon
select ST_AsText(
        ST_Round(
          ST_GeomFromText('MULTIPOLYGON (((160 400, 200.00000000000088 400.00000000000045, 200.00000000000088 480.00000000000017, 160 480, 160 400)), ((100 200, 180.00000000000119 300.0000000000008, 100 300, 100 200)))',0),
          1)) as rGeom;
-- # rGeom
-- 'MULTIPOLYGON(((160 160,200 200,200 200,160 160,160 160)),((100 100,180 180,100 100,100 100)))'

