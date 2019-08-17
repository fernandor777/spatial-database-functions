DELIMITER $$

USE `gisdb`$$

DROP function IF EXISTS `ST_SwapOrdinates`$$

CREATE FUNCTION `ST_SwapOrdinates`
(
  p_geometry geometry,
  p_swap     varchar(2)
)
Returns geometry
/****m* EDITOR/ST_SwapOrdinates (1.0)
 *  NAME
 *    ST_SwapOrdinates -- Allows for swapping ordinate pairs in a geometry.
 *  SYNOPSIS
 *    Function ST_SwapOrdinates (
 *               p_geometry geometry,
 *               p_swap     varchar(2) = 'XY'
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT [$(owner)].[ST_SwapOrdinates] (
 *             ST_PointFromText('POINT(143.282374 20.293874)',4326),
 *             'XY'
 *           ).AsTextZM() as correctedOrdinates;
 *    correctedOrdinates
 *    POINT (20.293874 143.282374)
 *  DESCRIPTION
 *    Sometimes the ordinates of a geometry can be swapped such as latitude for X
 *    and Longitude for Y when it should be reversed. This function allows for the
 *    swapping of pairs of ordinates controlled by the p_swap parameter.
 *    Will support Z and M ordinate values when MySQL provides such support.
 *  INPUTS
 *    p_geometry (geometry)  - Supplied geometry object.
 *    p_swap     (varchar 2) - The ordinate pair to swap: XY (only one supported), XZ, XM, YZ, YM or ZM
 *  RESULT
 *    altered geom (geometry) - Changed Geometry;
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2018 - Original Port to MYSQL
 *  COPYRIGHT
 *    (c) 2008-2017 by TheSpatialDBAdvisor/Simon Greener
******/
BEGIN
  Declare v_wkt           TEXT;
  Declare v_wkt_remainder TEXT;
  Declare v_pos           int;
  Declare v_x             double;
  Declare v_y             double;

  If ( p_geometry is NULL ) THEN
    Return p_geometry;
  End If;

  -- Shortcircuit for simplest case
  IF ( ST_GeometryType(p_geometry) = 'POINT' ) THEN
    SET v_x   = ST_X(p_geometry);
    SET v_y   = ST_Y(p_geometry);
    SET v_wkt = CONCAT_WS('','POINT(',LTRIM( CAST( v_y as CHAR(50))),' ',LTRIM( CAST( v_x as CHAR(50))),')');
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
      -- Add to WKT
      SET v_wkt    = CONCAT(v_wkt,LTRIM(CAST(v_y as CHAR(50))),' ',LTRIM(CAST(v_x as CHAR(50))));
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
SELECT ST_AsText(ST_SwapOrdinates(ST_GeomFromText('POINT(100.12223 100.345456)',0),'XY')) as rGeom; 
-- # rGeom
-- POINT(100.345456 100.12223)
SELECT ST_AsText(ST_SwapOrdinates(ST_PointFromText('POINT(20.293874 143.282374)',4326),'XY')) as sGeom;
-- # sGeom
-- POINT(143.282374 20.293874)
-- MultiPoint
SELECT ST_AsText(ST_SwapOrdinates(ST_GeomFromText('MULTIPOINT((100.12223 100.345456),(38832.839 4949.40400))',0),'XY')) as sGeom; 
-- # sGeom
-- MULTIPOINT((100.345456 100.12223),(4949.404 38832.839))
-- Linestring
select ST_AsText(ST_SwapOrdinates(ST_GeomFromText('LINESTRING(0.1342 0.2322,1.2324 45.122)',0),'XY')) as SGeom;
-- # SGeom
-- LINESTRING(0.2322 0.1342,45.122 1.2324)
-- Polygon
select ST_AsText(
        ST_SwapOrdinates(
          ST_GeomFromText('POLYGON((160 400, 200.00000000000088 400.00000000000045, 200.00000000000088 480.00000000000017, 160 480, 160 400))',0),
          'XY')) as sGeom;
-- # sGeom
-- POLYGON((400 160,400 200,480 200,480 160,400 160))
-- MultiPolygon
select ST_AsText(
        ST_SwapOrdinates(
          ST_GeomFromText('MULTIPOLYGON (((160 400, 200.00000000000088 400.00000000000045, 200.00000000000088 480.00000000000017, 160 480, 160 400)), ((100 200, 180.00000000000119 300.0000000000008, 100 300, 100 200)))',0),
          'XY')) as sGeom;
-- # sGeom
-- MULTIPOLYGON(((400 160,400 200,480 200,480 160,400 160)),((200 100,300 180,300 100,200 100)))


