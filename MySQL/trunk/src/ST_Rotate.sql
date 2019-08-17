DELIMITER $$

USE `gisdb`$$

DROP function IF EXISTS `ST_Rotate`$$

CREATE FUNCTION `ST_Rotate` 
(
  p_geometry geometry,
  p_rX       double,
  p_rY       double,
  p_angle    double,
  p_round_xy int 
)
RETURNS geometry
/****m* AFFINE/ST_Rotate (1.0)
 *  NAME
 *    ST_Rotate -- Function which rotates a shape a supplied rotation point a provided number of degrees.
 *  SYNOPSIS
 *    Function ST_Rotate ( 
 *                p_geometry geometry,
 *                p_rX       double,
 *                p_rY       double,
 *                p_angle    double
 *                p_round_xy int 
 *             )
 *     Returns geometry
 *  USAGE
 *    SELECT ST_AsText(
 *              ST_Rotate(
 *                 ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),
 *                 0.0, 0.0, 125, 2
 *              )
 *           ) as rotatedGeom;
 *
 *    # rotatedGeom
 *    'LINESTRING(-0.14 -0.17,-1.95 -2.4)'
 *  DESCRIPTION
 *    Function that rotates the supplied geometry around a supplied point.
 *    The rotation angle, p_angle, is in degrees between -360 and 360 degrees.
 *    The computed ordinates of the new geometry are rounded to p_round_xy number of decimal digits of precision.
 *  INPUTS
 *    p_geometry   (geometry) - supplied geometry of any type.
 *    p_rX         (double)   - X ordinate of rotation point.
 *    p_rY         (double)   - Y ordinate of rotation point.
 *    p_angle      (double)   - Rotation angle specified in range degrees -360 to 360 degrees.
 *    p_round_xy   (int)      - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *  RESULT
 *    rotated geom (geometry) - Input geometry rotated p_angle degrees around supplied rotation point.
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
  Declare v_cos_angle     double;
  Declare v_sin_angle     double;
  Declare v_x             double;
  Declare v_y             double;
  Declare v_geometry      geometry;

  If ( p_geometry is NULL ) THEN
    Return p_geometry;
  End If;

  If ( p_rX IS NULL OR p_rY IS NULL ) Then
    Return p_geometry; -- cast('Rotation X and Y must both not be NULL.' as varchar(max)); -- geometry);
  End If;

  If ( ( p_angle is NULL ) Or ( p_angle NOT BETWEEN -360 AND 360 ) ) Then
    Return p_geometry; -- cast('Rotation value must be supplied and must be between 0 and 360.' as varchar(max)); -- geometry);
  End If;
  
  SET v_round_xy  = COALESCE(p_round_xy,3);
  SET v_cos_angle = COS(p_angle * PI()/180);
  SET v_sin_angle = SIN(p_angle * PI()/180);

  -- Shortcircuit for simplest case
  IF ( ST_GeometryType(p_geometry) = 'POINT' ) THEN
    SET v_x = ROUND(p_rX + (
                            ( (ST_X(p_geometry) - p_rX) * v_cos_angle) -
                            ( (ST_Y(p_geometry) - p_rY) * v_sin_angle) 
                           ),v_round_xy);
    SET v_y = ROUND( p_rY + (
                             ( (ST_X(p_geometry) - p_rX) * v_sin_angle ) +
                             ( (ST_Y(p_geometry) - p_rY) * v_cos_angle ) 
                            ),v_round_xy);
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
      -- Extract X and Y Ordinates from WKT
      SET v_x   = CAST(SUBSTR(v_wkt_remainder,1,INSTR(v_wkt_remainder,' ')-1)       as decimal(38,10));
      SET v_y   = CAST(SUBSTR(v_wkt_remainder,INSTR(v_wkt_remainder,' ')+1,v_pos-1) as decimal(38,10));
      -- Apply rotation 
      SET v_x   = ROUND(((v_x - p_rX) * v_cos_angle - (v_y - p_rY) * v_sin_angle) + p_rX,v_round_xy);
      SET v_y   = ROUND(((v_x - p_rX) * v_sin_angle + (v_y - p_rY) * v_cos_angle) + p_rY,v_round_xy);
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

-- Point
select ST_AsText(ST_Rotate(ST_PointFromText('POINT(10 10)',0), 0.0, 0.0, 90, 1)) as rotatedGeom;
-- # rotatedGeom
-- POINT(-10 10)
-- Linestring
select ST_AsText(ST_Rotate(ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),0.0,0.0,125,2)) as rotatedGeom;
-- # rotatedGeom
-- LINESTRING(-0.22 -0.29,-37.83 -56.91)
-- Polygon
select ST_AsText(ST_Rotate(ST_GeomFromText('POLYGON((0 0,10 0,10 10,0 10,0 0))',0),0.0,0.0,300,2)) as rotatedGeom;
-- # rotatedGeom
-- POLYGON((0 0,5 -4.33,13.66 -6.83,8.66 -2.5,0 0))
-- MultiPolygon
select ST_AsText(
        ST_Rotate(
          ST_GeomFromText('MULTIPOLYGON (((160 400, 200.00000000000088 400.00000000000045, 200.00000000000088 480.00000000000017, 160 480, 160 400)), ((100 200, 180.00000000000119 300.0000000000008, 100 300, 100 200)))',0),
          0,
          0,
          110,
          1)) as rotatedGeom;
-- # rotatedGeom
-- 'MULTIPOLYGON(((-430.6 -541.4,-444.3 -554.3,-519.5 -652.3,-505.8 -639.5,-430.6 -541.4)),((-222.1 -277.1,-343.5 -425.4,-316.1 -399.6,-222.1 -277.1)))'
