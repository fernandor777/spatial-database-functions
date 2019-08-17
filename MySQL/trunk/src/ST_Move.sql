DELIMITER $$

USE `gisdb`$$

DROP function IF EXISTS `ST_Move`$$

CREATE FUNCTION `ST_Move` 
(
  p_geometry geometry,
  p_dX       double,
  p_dY       double,
  p_round_xy int 
)
RETURNS geometry
/****m* AFFINE/ST_Move (1.0)
 *  NAME
 *    ST_Move -- Function which moves a geometry the supplied delta X and delta Y.
 *  SYNOPSIS
 *    Function ST_Move (
 *                p_geometry geometry,
 *                p_dX       double,
 *                p_dY       double,
 *                p_round_xy int 
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT ST_AsText(
 *              ST_Move(
 *                 ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),
 *                 -5.0, 30.1, 1
 *              )
 *           ) as movedGeom;
 *
 *    # movedGeom
 *    'LINESTRING(-4.9 30.2,-3.6 31.5)'
 *  DESCRIPTION
 *    Function that moves the supplied geometry's ordinates the supplied x and y deltas.
 *    The computed ordinates of the new geometry are rounded to p_round_xy number of decimal digits of precision.
 *  INPUTS
 *    p_geometry (geometry) - supplied geometry of any type.
 *    p_dX       (double)   - X ordinate delta shift.
 *    p_dy       (double)   - Y ordinate delta shift.
 *    p_round_xy (int)      - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *  RESULT
 *    moved geom (geometry) - Input geometry moved by supplied X and Y ordinate deltas.
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
  Declare v_dX            double;
  Declare v_dY            double;
  Declare v_x             double;
  Declare v_y             double;

  If ( p_geometry is NULL ) THEN
    Return p_geometry;
  End If;

  SET v_dX = COALESCE(p_dX,0.0);
  SET v_dY = COALESCE(p_dY,0.0);

  If ( v_dX = 0.0 AND v_dY = 0.0 ) THEN
    Return p_geometry;
  END IF;

  SET v_round_xy = COALESCE(p_round_xy,3);
  -- Shortcircuit for simplest case
  IF ( ST_GeometryType(p_geometry) = 'POINT' ) THEN
    SET v_x   = ROUND(ST_X(p_geometry) + v_dX,v_round_xy);
    SET v_y   = ROUND(ST_Y(p_geometry) + v_dY,v_round_xy);           
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
      SET v_x   = CAST(SUBSTR(v_wkt_remainder,1,INSTR(v_wkt_remainder,' ')-1)          as decimal(38,10));
      SET v_y      = CAST(SUBSTR(v_wkt_remainder,INSTR(v_wkt_remainder,' ')+1,v_pos-1) as decimal(38,10));
      -- Compute moved ordinates
      SET v_x   = ROUND(v_x + v_dX,v_round_xy);
      SET v_y   = ROUND(v_y + v_dY,v_round_xy);
      -- Add to WKT
      SET v_wkt = CONCAT(v_wkt,LTRIM(CAST(v_x as CHAR(50))),' ',LTRIM(CAST(v_y as CHAR(50))));
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
select ST_AsText(ST_Move(ST_PointFromText('POINT(0 0)',0), -5.0, 30.1, 1)) as movedGeom;
-- # movedGeom
-- 'POINT(-5 30.1)'
-- MultiPoint
SELECT ST_AsText(ST_Move(ST_GeomFromText('MULTIPOINT((100.12223 100.345456),(388.839 499.40400))',0),-100,-3000,2)) as rGeom; 
-- # rGeom
-- 'MULTIPOINT((0.12 -2899.65),(288.84 -2500.6))'
-- Linestring
select ST_AsText(ST_Move(ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),-5.0,30.1, 1)) as movedGeom;
-- # movedGeom
-- 'LINESTRING(-4.9 30.3,-3.6 75.3)'
select ST_AsText(ST_Move(ST_GeomFromText('POLYGON((0 0,10 0,10 10,0 10,0 0))',0),-5.0,30.1, 2)) as movedGeom;
-- # movedGeom
-- 'POLYGON((-5 30.1,5 30.1,5 40.1,-5 40.1,-5 30.1))'

select ST_AsText(
        ST_Move(
          ST_GeomFromText('MULTIPOLYGON (((160 400, 200.00000000000088 400.00000000000045, 200.00000000000088 480.00000000000017, 160 480, 160 400)), ((100 200, 180.00000000000119 300.0000000000008, 100 300, 100 200)))',0),
          -50,
          -100,
          1)) as movedGeom;
-- # movedGeom
-- 'MULTIPOLYGON(((110 300,150 300,150 380,110 380,110 300)),((50 100,130 200,50 200,50 100)))'

