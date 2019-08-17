DELIMITER $$

USE `gisdb`$$

DROP function IF EXISTS `ST_DeletePoints`$$

CREATE FUNCTION `ST_DeletePoints` 
(
  p_geometry   geometry,
  p_point_list text
)
Returns geometry
/****m* EDITOR/ST_DeletePoints (1.0)
 *  NAME
 *    ST_DeletePoints -- Function which deletes one or more coordinates from the supplied geometry.
 *  SYNOPSIS
 *    Function ST_DeletePoints (
 *                p_geometry   geometry,
 *                p_point_list text 
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT ST_AsText(
 *              ST_DeletePoints(
 *                 ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2,120 394.23)',0),
 *                 '2'
 *              )
 *           ) as deleteGeom; 
 *
 *    # deleteGeom
 *    'LINESTRING(0.1 0.2,120 394.23)'
 *  DESCRIPTION
 *    Function that removes one or more coordinates from the supplied geometry.
 *    The function does not process POINT or GEOMETRYCOLLECTION geometries.
 *    The list of points to be deleted is supplied as a comma separated string of point numbers.
 *    The point numbers are from 1 to the total number of points in a WKT representation of the object.
 *    Point numbers do not refer to specific points within a specific sub-geometry eg point number 1 in the 2nd interiorRing in a polygon object.
 *  INPUTS
 *    p_geometry   (geometry) - supplied geometry of any type.
 *    p_point_line (text)     - Comma separated list of point numbers from 1 to the total number in a geometry's WKT representation.
 *  RESULT
 *    smaller geom (geometry) - Input geometry with referenced points deleted. 
 *  NOTE
 *    May throw "Error Code: 3037. Invalid GIS data provided to function st_geometryfromtext." if point deletion invalidates the geometry.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding for MySQL.
 *  COPYRIGHT
 *    (c) 2012-2017 by TheSpatialDBAdvisor/Simon Greener
 *  LICENSE
 *    Creative Commons Attribution-Share Alike 2.5 Australia License.
 *    http://creativecommons.org/licenses/by-sa/2.5/au/
******/
BEGIN
  Declare v_GeometryType      varchar(100);
  Declare v_wkt               TEXT;
  Declare v_point_list        text;
  Declare v_points_to_delete  int;
  Declare v_pointn            int;
  Declare v_RingN             int;
  Declare v_part_pointn       int;
  Declare v_geomn             int;
  Declare v_ring_geom         geometry;
  Declare v_geometry_part     geometry;
  Declare v_geometry          geometry;

  IF ( p_geometry is NULL ) THEN
    Return NULL;
  END IF;
  
  IF ( p_point_list is null ) THEN
    Return p_geometry;
  END IF;
  
  SET v_point_list = REPLACE(CONCAT(',',COALESCE(p_point_list,'1'),','),',,',',');
 
  SET v_GeometryType = SUBSTR(ST_GeometryType(p_geometry),1,100);
  IF ( v_GeometryType IN ('GEOMETRYCOLLECTION','POINT')) THEN
    RETURN p_geometry;
  END IF;

  -- Count points that need deleting...  
  SET v_points_to_delete = ROUND( (CHAR_LENGTH(v_point_list)-1) - 
                                   CHAR_LENGTH(REPLACE(v_point_list,',',''))
                                 / CHAR_LENGTH(','),
                            0);

  IF (  ( v_GeometryType = 'MULTIPOINT' and ST_NumPoints(p_geometry) = 1) 
     or ( v_GeometryType = 'LINESTRING' and ABS(v_points_to_delete - ST_NumPoints(p_geometry)) < 2 )
     or ( v_GeometryType = 'POLYGON'    and  v_points_to_delete   <= ST_NumPoints(ST_ExteriorRing(p_geometry)) ) and ST_NumPoints(p_geometry) = 5) THEN
    Return p_geometry;
  END IF;

  -- Check and replace -1 end marker with STNumPoints()
  SET v_point_list = case when INSTR(v_point_list,'-1') <> 0 
                          then REPLACE(v_point_list,',-1,',CONCAT(',',CAST(ST_NumPoints(p_geometry) as CHAR(10)),','))
                          else v_point_list
                      end;

  IF ( v_GeometryType = 'MULTIPOINT' ) THEN
      SET v_geomn = 1;
      SET v_WKT   = 'MULTIPOINT (';
      WHILE ( v_geomn <= ST_NumGeometries(p_geometry) ) DO
          -- Add if not a deleted point
          IF ( INSTR(v_point_list,CONCAT(',',CAST(v_geomn as CHAR(10)),',')) = 0 ) THEN
             IF ( RIGHT(v_wkt,1) = ')' ) THEN
               SET v_wkt = CONCAT(v_wkt,',');
             END IF;
             SET v_WKT = CONCAT(v_wkt,
                                '(',
                                CAST(ST_X(ST_GeometryN(p_geometry,v_geomn)) as char(50)),
                                ' ',
                                CAST(ST_Y(ST_GeometryN(p_geometry,v_geomn)) as char(50)),
                                ')');
          END IF;
          SET v_geomn = v_geomn + 1;
      END WHILE; 
      RETURN ST_GeomFromText(CONCAT(v_wkt,')'),ST_Srid(p_geometry));
    END IF;

    IF ( v_GeometryType = 'LINESTRING' ) THEN
      SET v_pointn = 1;
      SET v_WKT    = 'LINESTRING (';
      WHILE ( v_pointn <= ST_NumPoints(p_geometry) ) DO
        -- Add if not a deleted point
        IF ( INSTR(v_point_list,CONCAT(',',CAST(v_pointn as CHAR(10)),',')) = 0 ) THEN
          IF ( RIGHT(v_wkt,1) != '(' ) THEN
            SET v_WKT = CONCAT(v_wkt,',');
          END IF;
          SET v_WKT = CONCAT(v_wkt,
                             CAST(ST_X(ST_PointN(p_geometry,v_pointn)) as char(50)),
							 ' ',
                             CAST(ST_Y(ST_PointN(p_geometry,v_pointn)) as char(50)));
        END IF;
        SET v_pointn = v_pointn + 1;
      END WHILE; 
      RETURN ST_GeomFromText(CONCAT(v_wkt,')'),ST_Srid(p_geometry));
    END IF;

    IF ( v_GeometryType = 'MULTILINESTRING' ) THEN
      SET v_WKT    = 'MULTILINESTRING (';
      SET v_geomn  = 1;
      SET v_pointn = 1;
      WHILE ( v_geomn <= ST_NumGeometries(p_geometry) ) DO
        IF ( v_GeomN > 1 ) THEN
          SET v_wkt = CONCAT(v_wkt,',(');
        ELSE
          SET v_WKT = CONCAT(v_wkt,'(');
 		END IF;
        SET v_geometry_part = ST_GeometryN(p_geometry,v_geomn);
        SET v_part_pointn = 1;
        WHILE ( v_part_pointn <= ST_NumPoints(v_geometry_part) ) DO
          -- Add if not a deleted point
          IF ( INSTR(v_point_list,CONCAT(',',CAST(v_pointn as CHAR(10)),',')) = 0 ) THEN
            IF ( RIGHT(v_wkt,1) != '(' ) THEN
              SET v_WKT = CONCAT(v_WKT,',');
            END IF;
            SET v_WKT = CONCAT(v_wkt,
                               CAST(ST_X(ST_PointN(v_geometry_part,v_part_pointn)) as char(50)),
                               ' ',
                               CAST(ST_Y(ST_PointN(v_geometry_part,v_part_pointn)) as char(50)));
          END IF;
          SET v_pointn      = v_pointn + 1;
          SET v_part_pointn = v_part_pointn + 1;
        END WHILE; 
        -- Terminate this part
        SET v_wkt = CONCAT(v_wkt,')');
        -- Process next
        SET v_geomn = v_geomn + 1;
      END WHILE;  -- All geometries...
      -- Terminate whole geometry and return.
      RETURN ST_GeomFromText(CONCAT(v_wkt,')'),ST_Srid(p_geometry));
    END IF;

    IF ( v_GeometryType = 'POLYGON' ) THEN
      -- If Delete Point is start or end vertex of a ring the WKT will fail to convert to a POLYGON.
      SET v_WKT    = 'POLYGON (';
      SET v_PointN = 1;
      SET v_RingN  = 0;
      WHILE ( v_RingN < ( 1 /* One ExteriorRing */ + ST_NumInteriorRing(p_geometry) ) ) DO
        IF ( v_RingN = 0 ) THEN
          SET v_ring_geom = ST_ExteriorRing(p_geometry);
        ELSE
          SET v_ring_geom = ST_InteriorRingN(p_geometry,v_RingN);
		END IF;
        IF ( v_RingN > 0 ) THEN
          SET v_wkt = CONCAT(v_wkt,','); 
		END IF;
        SET v_wkt = CONCAT(v_wkt,'(');
        SET v_part_pointn = 1;
        WHILE ( v_part_pointn <= ST_NumPoints(v_ring_geom) ) DO
          -- Add if not a deleted point
          IF ( INSTR(v_point_list,CONCAT(',',CAST(v_pointn as CHAR(10)),',')) = 0 ) THEN
            IF ( RIGHT(v_wkt,1) != '(' ) THEN
              SET v_wkt = CONCAT(v_wkt,',');
            END IF;
            SET v_WKT = CONCAT(v_wkt,
                               CAST(ST_X(ST_PointN(v_ring_geom,v_part_pointn)) as char(50)),
                               ' ',
                               CAST(ST_Y(ST_PointN(v_ring_geom,v_part_pointn)) as char(50)));
          END IF;
          SET v_pointn      = v_pointn + 1;
          SET v_part_pointn = v_part_pointn + 1;
        END WHILE;
        -- Terminate this part
        SET v_wkt = CONCAT(v_wkt,')');
        -- Process next ring
        SET v_RingN = v_RingN + 1;
      END WHILE;  -- All Rings...
      -- Terminate whole geometry and return.
      RETURN ST_GeomFromText(CONCAT(v_wkt,')'),ST_Srid(p_geometry));
    END IF;  -- IF POLYGON

    IF ( v_GeometryType = 'MULTIPOLYGON' ) THEN
      -- If Delete Point is start or end vertex of any ring the WKT will fail to convert to a POLYGON.
      SET v_WKT    = 'MULTIPOLYGON ((';
      SET v_PointN = 1;
      SET v_GeomN  = 1;
      WHILE ( v_GeomN <= ST_NumGeometries(p_geometry) ) DO
        IF ( v_GeomN > 1 ) THEN
          SET v_wkt = CONCAT(v_wkt,',(');
		END IF;
        SET v_geometry_part = ST_GeometryN(p_geometry,v_GeomN);
        SET v_RingN         = 0;
        WHILE ( v_RingN < ( 1 /* ExteriorRing */ + ST_NumInteriorRing(v_geometry_part) ) ) DO
          IF ( v_RingN = 0 ) THEN
            SET v_ring_geom = ST_ExteriorRing(v_geometry_part);
          ELSE
            SET v_ring_geom = ST_InteriorRingN(v_geometry_part,v_RingN);
            SET v_wkt       = CONCAT(v_wkt,',');
          END IF;
          SET v_wkt         = CONCAT(v_wkt,'(');
          SET v_part_pointn = 1;
          WHILE ( v_part_pointn <= ST_NumPoints(v_ring_geom) ) DO
            -- Add if not a deleted point
            IF ( INSTR(v_point_list,CONCAT(',',CAST(v_pointn as CHAR(10)),',')) = 0 ) THEN
              IF ( RIGHT(v_wkt,1) != '(' ) THEN
                SET v_wkt = CONCAT(v_wkt,',');
              END IF;
            SET v_WKT = CONCAT(v_wkt,
                               CAST(ST_X(ST_PointN(v_ring_geom,v_part_pointn)) as char(50)),
                               ' ',
                               CAST(ST_Y(ST_PointN(v_ring_geom,v_part_pointn)) as char(50)));
            END IF;
            SET v_pointn      = v_pointn + 1;
            SET v_part_pointn = v_part_pointn + 1;
          END WHILE;
          -- Terminate this part
          SET v_wkt = CONCAT(v_wkt,')');
          -- Process next ring
          SET v_RingN = v_RingN + 1;
        END WHILE;  -- All Rings...
        SET v_wkt   = CONCAT(v_wkt,')');
        SET v_GeomN = v_GeomN + 1;
      END WHILE; -- Terminate this part of the multi geometry
      -- Terminate whole geometry and return.
      SET v_wkt = CONCAT(v_wkt,')');
      RETURN ST_GeomFromText(v_wkt,ST_Srid(p_geometry));
    END IF;  -- IF MultiPOLYGON
    RETURN p_geometry;
END;$$

DROP function IF EXISTS `ST_DeleteN`$$

CREATE FUNCTION `ST_DeleteN`
(
  p_geometry geometry,
  p_position int
)
Returns geometry
/****m* EDITOR/ST_DeleteN (1.0)
 *  NAME
 *    STDeletePointN -- Function which deletes referenced coordinate from the supplied geometry.
 *  SYNOPSIS
 *    Function STDeletePointN (
 *               p_geometry geometry,
 *               p_position int 
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT ST_AsText(
 *              ST_DeletePointN(
 *                 ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2,120 394.23)',0),
 *                 2
 *              )
 *           ) as deleteGeom; 
 *
 *    # deleteGeom
 *    'LINESTRING(0.1 0.2,120 394.23)'
 *  DESCRIPTION
 *    Function that removes a single, nominated, coordinates from the supplied geometry.
 *    The function does not process POINT or GEOMETRYCOLLECTION geometries.
 *    The point to be deleted is supplied as a single integer.
 *    The point number can be supplied as -1 (last number), or 1 to the total number of points in a WKT representation of the object.
 *    A point number does not refer to a specific point within a specific sub-geometry eg point number 1 in the 2nd interiorRing in a polygon object.
 *  INPUTS
 *    p_geometry   (geometry) - supplied geometry of any type.
 *    p_position        (int) - Valid point number in geometry.
 *  RESULT
 *    smaller geom (geometry) - Input geometry with required point deleted. 
 *  NOTES
 *    May throw error message ST_GeomFromText error if point deletion invalidates the geometry.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding for MySQL.
 *  COPYRIGHT
 *    (c) 2012-2017 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Return ST_DeletePoints(p_geometry,CAST(COALESCE(p_position,1) as char(10)));
END;$$

DELIMITER ;

-- TO BE DONE: Delete Part from MultiGeometry

-- Point
select ST_AsText(ST_DeletePoints(ST_PointFromText('POINT(0 0)',0),'1')) as deleteGeom;
-- same

-- MULTIPOINT
SELECT ST_AsText(ST_DeletePoints(ST_GeomFromText('MULTIPOINT((100.12223 100.345456),(388.839 499.40400))',0),'2')) as deleteGeom; 
-- # deleteGeom
-- 'MULTIPOINT((100.12223 100.345456))'

-- LINESTRING
SELECT ST_AsText(ST_DeletePoints(ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),'1')) as deleteGeom; 
-- Nothing to do.
-- # deleteGeom
-- 'LINESTRING(0.1 0.2,1.4 45.2)'

-- LINESTRING
SELECT ST_AsText(ST_DeletePoints(ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2,120 394.23)',0),'2')) as deleteGeom; 
-- # deleteGeom
-- 'LINESTRING(0.1 0.2,120 394.23)'

-- MULTILINESTRING
SELECT ST_AsText(ST_DeletePoints(ST_GeomFromText('MULTILINESTRING((0.1 0.2,1.4 45.2,120 394.23),(0 0,1 1,2 2))',0),'2')) as deleteGeom; 
-- # deleteGeom
-- 'MULTILINESTRING((0.1 0.2,120 394.23),(0 0,1 1,2 2))'

-- POLYGON (nothing will be done as number of points would fall below 5)
select ST_AsText(ST_DeletePoints(ST_GeomFromText('POLYGON((0 0,10 0,10 10,0 10,0 0))',0),'2')) as deleteGeom; 

select ST_AsText(ST_DeletePoints(ST_GeomFromText('POLYGON((0 0,10 0,10 2,10 4,10 6,10 8,10 10,0 10,0 0))',0),'3,4,5,6')) as deleteGeom; 
-- # deleteGeom
-- 'POLYGON((0 0,10 0,10 10,0 10,0 0))'

-- # deleteGeom
-- 'POLYGON((0 0,10 1,10 10,0 10,0 0))'
-- MultiPOLYGON (Double Update)
select ST_AsText(
          ST_DeletePoints(
             ST_GeomFromText('MULTIPOLYGON (((160 400, 201 399, 200.00000000000088 400.00000000000045, 200.00000000000088 480.00000000000017, 160 480, 160 400)), ((100 200, 180.00000000000119 300.0000000000008, 100 300, 100 200)))',0),
             '2') 
       ) as deleteGeom; 
-- # deleteGeom
-- 'MULTIPOLYGON(((160 400,200.00000000000088 400.00000000000045,200.00000000000088 480.00000000000017,160 480,160 400)),((100 200,180.0000000000012 300.0000000000008,100 300,100 200)))'

SELECT ST_AsText(ST_DeleteN(ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2,120 394.23)',0),2)) as deleteGeom; 

