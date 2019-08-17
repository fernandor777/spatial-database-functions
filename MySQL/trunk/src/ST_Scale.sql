DELIMITER $$

USE `gisdb`$$

DROP function IF EXISTS `ST_Scale`$$

CREATE FUNCTION `ST_Scale` 
(
  p_geometry geometry,
  p_xFactor  double,
  p_yFactor  double,
  p_round_xy int 
)
RETURNS geometry
/****m* AFFINE/ST_Scale (1.0)
 *  NAME
 *    ST_Scale -- Function which scales a geometry using the required XY ordinate input factors.
 *  SYNOPSIS
 *    Function ST_Scale (
 *                p_geometry geometry,
 *                p_xFactor  double,
 *                p_yFactor  double,
 *                p_round_xy int 
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT ST_AsText(
 *              ST_Scale(
 *                 ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),
 *                 -5.0, 3.2, 3
 *              )
 *           ) as scaledGeom;
 *
 *    # scaledGeom
 *    'LINESTRING(-0.5 0.32,-7 4.48)'
 *  DESCRIPTION
 *    Function that scales the supplied geometry's ordinates using the supplied p_xFactor and p_yFactors .
 *    The computed ordinates of the new geometry are rounded to p_round_xy number of decimal digits of precision.
 *  INPUTS
 *    p_geometry  (geometry) - supplied geometry of any type.
 *    p_xFactor   (double)   - X ordinate scale factor.
 *    p_yFactor   (double)   - Y ordinate scale factor.
 *    p_round_xy  (int)      - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *  RESULT
 *    scaled geom (geometry) - Input geometry scaled by supplied X and Y ordinate factor values.
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
  Declare v_xFactor       double;
  Declare v_yFactor       double;
  Declare v_x             double;
  Declare v_y             double;

  If ( p_geometry is NULL ) THEN
    Return p_geometry;
  End If;

  SET v_xFactor = COALESCE(p_xFactor,0.0);
  SET v_yFactor = COALESCE(p_yFactor,0.0);

  If ( v_xFactor = 0.0 AND v_yFactor = 0.0 ) THEN
    Return p_geometry;
  END IF;

  SET v_round_xy = COALESCE(p_round_xy,3);

  -- Shortcircuit for simplest case
  IF ( ST_GeometryType(p_geometry) = 'POINT' ) THEN
    SET v_x   = ROUND(ST_X(p_geometry) * v_xFactor,v_round_xy);
    SET v_y   = ROUND(ST_Y(p_geometry) * v_yFactor,v_round_xy);           
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
      SET v_x      = CAST(SUBSTR(v_wkt_remainder,1,INSTR(v_wkt_remainder,' ')-1)       as decimal(38,10));
      SET v_y      = CAST(SUBSTR(v_wkt_remainder,INSTR(v_wkt_remainder,' ')+1,v_pos-1) as decimal(38,10));
      -- Compute moved ordinates
      SET v_x      = ROUND(v_x * v_xFactor,v_round_xy);
      SET v_y      = ROUND(v_y * v_yFactor,v_round_xy);
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

select ST_AsText(ST_Scale(ST_PointFromText('POINT(0 1)',0), 5.0, 3.1, 2)) as scaledGeom;
-- # scaledGeom
-- 'POINT(0 3.1)'
-- 
select ST_AsText(ST_Scale(ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),-5.0,3.2, 3)) as scaledGeom;
-- # scaledGeom
-- LINESTRING(-0.5 0.64,-7 144.64)

select ST_AsText(ST_Scale(ST_GeomFromText('POLYGON((0 0,10 0,10 10,0 10,0 0))',0),-5.0,30.1, 3)) as scaledGeom;
-- # scaledGeom
-- 'POLYGON((-0 0,-50 301,-50 301,-0 0,-0 0))'


