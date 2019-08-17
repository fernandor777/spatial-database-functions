DELIMITER $$

USE `gisdb`$$

DROP function IF EXISTS `ST_Update`$$

CREATE FUNCTION `ST_Update` 
(
  p_geometry      geometry,
  p_point         geometry,
  p_replace_point geometry,
  p_round_xy      int 
)
RETURNS geometry
/****m* EDITOR/ST_Update (1.0)
 *  NAME
 *    ST_Update -- Function that updates (replaces) all geometry points that are equal to the supplied point with the replacement point.
 *  SYNOPSIS
 *    Function ST_Update (
 *                p_geometry      geometry,
 *                p_point         geometry,
 *                p_replace_point geometry,
 *                p_round_xy      int
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT ST_AsText(
 *              ST_Update(
 *                 ST_GeomFromText ('POLYGON(0 0,10 0,10 10,0 10,0 0)',0),
 *                 ST_PointFromText('POINT(0 0)',0),
 *                 ST_PointFromText('POINT(1 1)',0),
 *                 1 
 *              ) 
 *           ) as newGeom;
 *
 *    # updatedGeom
 *    'POLYGON(1 1,10 0,10 10,0 10,1 1)'
 *  DESCRIPTION
 *    Function that updates all coordinates that equal p_point with the supplied p_replace_point.
 *    The p_round_xy value is used when comparing geometry point's XY ordinates to p_point's.
 *    The updated coordinate's ordinates are rounded to p_round_xy number of decimal digits of precision.
 *  INPUTS
 *    p_geometry      (geometry) - supplied geometry of any type.
 *    p_point         (geometry) - Original coordinate to be replaced.
 *    p_replace_point (geometry) - Replacement coordinate
 *    p_round_xy      (int)      - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *  RESULT
 *    updated geom    (geometry) - Input geometry with one or more coordinate replaced.
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
  Declare v_pos           int;
  Declare v_round_xy      int;
  Declare v_point         geometry;

  If ( p_geometry      IS NULL 
    OR p_replace_point IS NULL 
    OR p_point         IS NULL) THEN
    Return p_geometry;
  End If;
  
  SET v_round_xy = COALESCE(p_round_xy,3);
  
  -- Shortcircuit for simplest case
  IF (  ST_GeometryType(p_geometry) = 'POINT' 
    AND ROUND(ST_X(p_geometry),v_round_xy) = ROUND(ST_X(p_point),v_round_xy)
    AND ROUND(ST_Y(p_geometry),v_round_xy) = ROUND(ST_Y(p_point),v_round_xy) ) THEN
    Return p_replace_point;
  END IF;

  -- Set up WKT variables. Remove geometrytype tag in one hit
  SET v_wkt_remainder = ST_AsText(p_geometry);
  SET v_wkt           = SUBSTR(v_wkt_remainder,1,INSTR(v_wkt_remainder,'('));
  SET v_wkt_remainder = SUBSTR(v_wkt_remainder,INSTR(v_wkt_remainder,'(')+1,LENGTH(v_wkt_remainder));
  WHILE ( LENGTH(v_wkt_remainder) > 0 ) DO
    -- Is the start of v_wkt_remainder a coordinate?
    IF ( v_wkt_remainder REGEXP '^[-0-9]' ) THEN
      -- We have a coord
      -- Now get position of end of coordinate 
      SET v_pos = case when INSTR(v_wkt_remainder,',') = 0
                       then INSTR(v_wkt_remainder,')')
                       when INSTR(v_wkt_remainder,',') <> 0 and INSTR(v_wkt_remainder,',') < INSTR(v_wkt_remainder,')')
                       then INSTR(v_wkt_remainder,',')
                       else INSTR(v_wkt_remainder,')')
                   end;
      -- Convert current point WKT to a geometry point 
      SET v_point = ST_PointFromText(CONCAT('POINT(',SUBSTR(v_wkt_remainder,1,v_pos-1),')'),ST_Srid(p_geometry));
      -- Check if this is the coordinate to update....
      IF ( ROUND(ST_X(v_point),v_round_xy) = ROUND(ST_X(p_point),v_round_xy)
       AND ROUND(ST_Y(v_point),v_round_xy) = ROUND(ST_Y(p_point),v_round_xy) ) THEN
        -- Add Replace Point to WKT
        SET v_wkt = CONCAT(v_wkt,
                           LTRIM(CAST(ROUND(ST_X(p_replace_point),v_round_xy) as CHAR(50))),
                           ' ',
                           LTRIM(CAST(ROUND(ST_Y(p_replace_point),v_round_xy) as CHAR(50))));
      ELSE
        SET v_wkt = CONCAT(v_wkt,
                           SUBSTR(v_wkt_remainder,1,v_pos-1)
                           );
      END IF;
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

-- Point
select ST_AsText(ST_Update(ST_PointFromText('POINT(0 0)',0),
                            ST_PointFromText('POINT(0 0)',0),
                            ST_PointFromText('POINT(1 1)',0),
                            1)) as updatedGeom;
-- # updatedGeom
-- 'POINT(1 1)'
--
-- MultiPoint
SELECT ST_AsText(ST_Update(ST_GeomFromText('MULTIPOINT((100.12223 100.345456),(388.839 499.40400))',0),
                            ST_PointFromText('POINT(100.12223 100.345456)',0),
                            ST_PointFromText('POINT(1 1)',0),
                            2)) as updatedGeom; 
-- # updatedGeom
-- 'MULTIPOINT((1 1),(388.839 499.404))'
--
-- Linestring
SELECT ST_AsText(ST_Update(ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),
                            ST_PointFromText('POINT(1.4 45.2)',0),
                            ST_PointFromText('POINT(2 45)',0),
                            2)) as updatedGeom; 
-- # updatedGeom
-- 'LINESTRING(0.1 0.2,2 45)'
--
-- Polygon
select ST_AsText(
          ST_Update(
             ST_GeomFromText('POLYGON((0 0,10 0,10 10,0 10,0 0))',0),
             ST_PointFromText('POINT(0 0)',0),
             ST_PointFromText('POINT(1 1)',0),
             2
          )
       ) as updatedGeom; 
-- # updatedGeom
-- 'POLYGON((1 1,10 0,10 10,0 10,1 1))'
--
-- MultiPolygon (Double Update)
select ST_AsText(
            ST_Update(
               ST_GeomFromText('MULTIPOLYGON (((160 400, 200.00000000000088 400.00000000000045, 200.00000000000088 480.00000000000017, 160 480, 160 400)), ((100 200, 180.00000000000119 300.0000000000008, 100 300, 100 200)))',0),
               ST_PointFromText('POINT(200.00000000000088 400.00000000000045)',0),
               ST_PointFromText('POINT(201 401)',0),
            2) 
       ) as updatedGeom; 
-- # updatedGeom
-- 'MULTIPOLYGON(((160 400,201 401,200.00000000000088 480.00000000000017,160 480,160 400)),((100 200,180.0000000000012 300.0000000000008,100 300,100 200)))'

