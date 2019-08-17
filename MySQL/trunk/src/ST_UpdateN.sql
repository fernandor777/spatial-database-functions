DELIMITER $$

USE `gisdb`$$

DROP function IF EXISTS `ST_UpdateN`$$

CREATE FUNCTION `ST_UpdateN` 
(
  p_geometry      geometry,
  p_replace_point geometry,
  p_position      int,
  p_round_xy      int 
)
Returns geometry
/****m* EDITOR/ST_UpdateN (1.0)
 *  NAME
 *    ST_UpdateN -- Function which updates the coordinate at position p_position in the supplied geometry.
 *  SYNOPSIS
 *    Function ST_UpdateN (
 *                p_geometry      geometry,
 *                p_replace_point double,
 *                p_position      int,
 *                p_round_xy      int 
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT ST_AsText(
 *              ST_UpdateN(
 *                 ST_GeomFromText ('LINESTRING(0 0,2 2)',0),
 *                 ST_PointFromText('POINT(1 1)',0),
 *                 2,
 *                 1 
 *              ) 
 *           ) as newGeom;
 * 
 *    # updatedGeom
 *    'LINESTRING(0 0,1 1)'
 *  DESCRIPTION
 *    Function that updates coordinate identified by p_position with the new point (p_replace_point) in the supplied geometry.
 *    p_position Values:
 *      1. null -> defaults to 1;
 *      2. -1   -> maximum number of points ie ST_NumPoints(p_geometry) 
 *      3. Greater than ST_NumPoints(p_geometry) -> maximum number of points ie ST_NumPoints(p_geometry)
 *    The updated coordinate's ordinates are rounded to p_round_xy number of decimal digits of precision.
 *  INPUTS
 *    p_geometry      (geometry) - supplied geometry of any type.
 *    p_replace_point (geoemtry) - Replacement coordinate
 *    p_position      (int)      - Coordinate position in p_geometry: between 1 and STNumPoints.
 *    p_round_xy      (int)      - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *  RESULT
 *    updated geom    (geometry)-- Input geometry with coordinate replaced.
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
  Declare v_coord         int;
  Declare v_position      int;
  Declare v_round_xy      int;
  Declare v_x             double;
  Declare v_y             double;

  If ( p_geometry is NULL OR p_replace_point is NULL ) THEN
    Return p_geometry;
  End If;
  
  SET v_position = case when COALESCE(p_position,1) < 0 or COALESCE(p_position,1) > ST_NumPoints(p_geometry)
                        then ST_NumPoints(p_geometry)
                        else COALESCE(p_position,1)
                    end;
  SET v_round_xy = COALESCE(p_round_xy,3);
  SET v_coord    = 0;
  
  -- Shortcircuit for simplest case
  IF ( ST_GeometryType(p_geometry) = 'POINT' and v_position = 1 ) THEN
    SET v_x   = ROUND(ST_X(p_replace_point),v_round_xy);
    SET v_y   = ROUND(ST_Y(p_replace_point),v_round_xy);           
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
      -- Now get position of end of coordinate 
      SET v_pos = case when INSTR(v_wkt_remainder,',') = 0
                       then INSTR(v_wkt_remainder,')')
                       when INSTR(v_wkt_remainder,',') <> 0 and INSTR(v_wkt_remainder,',') < INSTR(v_wkt_remainder,')')
                       then INSTR(v_wkt_remainder,',')
                       else INSTR(v_wkt_remainder,')')
                   end;
      -- Check if this is the coordinate to update....
      SET v_coord  = v_coord + 1;
      IF ( v_coord = v_position ) THEN
        -- Add Replace Point to WKT
        SET v_wkt = CONCAT(v_wkt,
                           LTRIM(CAST(ST_X(p_replace_point) as CHAR(50))),
                           ' ',
                           LTRIM(CAST(ST_Y(p_replace_point) as CHAR(50))));
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
select ST_AsText(ST_UpdateN(ST_PointFromText('POINT(0 0)',0),
                            ST_PointFromText('POINT(1 1)',0),1,1)) as updatedGeom;
-- # updatedGeom
-- 'POINT(1 1)'
-- MultiPoint
SELECT ST_AsText(ST_UpdateN(ST_GeomFromText('MULTIPOINT((100.12223 100.345456),(388.839 499.40400))',0),
                            ST_PointFromText('POINT(1 1)',0),
                            1,
                            2)) as updatedGeom; 
-- # updatedGeom
-- 'MULTIPOINT((1 1),(388.839 499.404))'
-- Linestring
SELECT ST_AsText(ST_UpdateN(ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),
                            ST_PointFromText('POINT(0 0)',0),
                            1,
                            2)) as updatedGeom; 
-- # updatedGeom
-- 'LINESTRING(0 0,1.4 45.2)'
-- Polygon
select ST_AsText(ST_UpdateN(ST_GeomFromText('POLYGON((0 0,10 0,10 10,0 10,0 0))',0),
                            ST_PointFromText('POINT(10 1)',0),
                            2,
                            2)) as updatedGeom; 

-- # updatedGeom
-- 'POLYGON((0 0,10 1,10 10,0 10,0 0))'
-- MultiPolygon (Double Update)
select ST_AsText(
         ST_UpdateN(
            ST_UpdateN(
               ST_GeomFromText('MULTIPOLYGON (((160 400, 200.00000000000088 400.00000000000045, 200.00000000000088 480.00000000000017, 160 480, 160 400)), ((100 200, 180.00000000000119 300.0000000000008, 100 300, 100 200)))',0),
               ST_PointFromText('POINT(201 481)',0),
               3,
               2),
            ST_PointFromText('POINT(201 401)',0),
            2,
            2) 
       ) as updatedGeom; 
-- # updatedGeom
-- 'MULTIPOLYGON(((160 400,201 401,201 481,160 480,160 400)),((100 200,180.0000000000012 300.0000000000008,100 300,100 200)))'
