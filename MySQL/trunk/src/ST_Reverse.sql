DELIMITER $$

USE `gisdb`$$

DROP function IF EXISTS `ST_Reverse`$$

CREATE FUNCTION ST_Reverse
(
  p_geometry geometry
)
Returns geometry
/****m* EDITOR/ST_Reverse (1.0)
 *  NAME
 *    ST_Reverse -- Function which reverses the vertices of a linestring and parts/vertices of multilinestring.
 *  SYNOPSIS
 *    Function ST_Reverse (
 *                p_geometry geometry 
 *             )
 *     Returns geometry 
 *  SYNOPSIS
 *    select id, action, geom 
 *      from (select 'Before' as action, id, ST_AsText(geom) as geom
 *              from (select 1 as id, ST_GeomFromText('LINESTRING(0 0, 10 0)',0) as geom
 *                    union all
 *                    select 2 as id, ST_GeomFromText('MULTILINESTRING((1 1,2 2), (3 3, 4 4))',0) as geom
 *                    union all
 *                    select 3 as id, ST_GeomFromText('MULTIPOINT((1 1),(2 2),(3 3),(4 4))',0) as geom
 *                    ) as data
 *           union all
 *           select 'After' as action, id, ST_AsText(ST_Reverse(geom)) as geom
 *             from (select 1 as id, ST_GeomFromText('LINESTRING(0 0, 10 0)',0) as geom
 *                   union all
 *                   select 2 as id, ST_GeomFromText('MULTILINESTRING((1 1,2 2), (3 3, 4 4))',0) as geom
 *                   union all
 *                   select 3 as id, ST_GeomFromText('MULTIPOINT((1 1),(2 2),(3 3),(4 4))',0) as geom
 *                  ) as data
 *           ) as f
 *    order by id, action desc;
 *
 *   id,  action,   geom
 *   '1', 'Before', 'LINESTRING(0 0,10 0)'
 *   '1', 'After',  'LINESTRING(10 0,0 0)'
 *   '2', 'Before', 'MULTILINESTRING((1 1,2 2),(3 3,4 4))'
 *   '2', 'After',  'MULTILINESTRING((4 4,3 3),(2 2,1 1))'
 *   '3', 'Before', 'MULTIPOINT((1 1),(2 2),(3 3),(4 4))'
 *   '3', 'After',  'MULTIPOINT((4 4),(3 3),(2 2),(1 1))'
 * 
 *  DESCRIPTION
 *    Function that reverses the coordinates of the supplied linestring.
 *    If the geometry is a multilinestring, the parts, and then their vertices are reversed.
 *    Supports reversal of MULTIPOINT geometries;
 *    The function does not process POINT, (MULTI)POLYGON or GEOMETRYCOLLECTION geometries.
 *  INPUTS
 *    p_geometry    (geometry) - Supplied geometry of supported type.
 *  RESULT
 *    reversed geom (geometry) -- Input geometry with parts and vertices reversed.
 *  NOTES
 *    May throw "Error Code: 3037. Invalid GIS data provided to function st_geometryfromtext." if reversal invalidates the geometry.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding for MySQL.
 *  COPYRIGHT
 *    (c) 2012-2017 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare v_geometryType varchar(100);
  Declare v_wkt          text;
  Declare v_pointN       int;
  Declare v_geomN        int;
  Declare v_point        geometry;
  Declare v_geom         geometry;
     
  If ( p_geometry is null ) Then
    Return p_geometry;
  End If;

    -- Only process linear geometries.
  SET v_GeometryType = ST_GeometryType(p_geometry);
  IF ( v_GeometryType NOT IN ('LINESTRING','MULTILINESTRING','MULTIPOINT') ) Then
    Return p_geometry;
  End If;

  IF ( v_GeometryType = 'MULTIPOINT' ) THEN
    SET v_geomn = ST_NumGeometries(p_geometry);
    SET v_WKT   = 'MULTIPOINT (';
    WHILE ( v_geomn > 0 ) DO
      SET v_point = ST_GeometryN(p_geometry,v_geomn);
      SET v_WKT   = CONCAT(v_wkt,
                           '(',
                           CAST(ST_X(v_point) as char(50)),
                           ' ',
                           CAST(ST_Y(v_point) as char(50)),
                           ')');
      SET v_geomn = v_geomn - 1;
      IF ( v_GeomN > 0 ) THEN
        SET v_wkt = CONCAT(v_wkt,',');
      END IF;
    END WHILE;  -- All geometries...
    -- Terminate whole geometry
    SET v_wkt = CONCAT(v_wkt,')');
    RETURN ST_GeomFromText(v_wkt,ST_Srid(p_geometry));
  END IF;

  IF ( v_GeometryType = 'LINESTRING' ) THEN
    SET v_pointn = ST_NumPoints(p_geometry);
    SET v_WKT    = 'LINESTRING (';
    WHILE ( v_pointn > 0 ) DO
      SET v_point = ST_PointN(p_geometry,v_pointn);
      SET v_WKT = CONCAT(v_wkt,
                         CAST(ST_X(v_point) as char(50)),
                         ' ',
                         CAST(ST_Y(v_point) as char(50)));
      SET v_pointn = v_pointn - 1;
      IF ( v_pointN > 0 ) THEN
        SET v_WKT = CONCAT(v_WKT,',');
      END IF;
    END WHILE; 
    RETURN ST_GeomFromText(CONCAT(v_wkt,')'),ST_Srid(p_geometry));
  END IF;

  IF ( v_GeometryType = 'MULTILINESTRING' ) THEN
    SET v_WKT    = 'MULTILINESTRING (';
    SET v_geomn  = ST_NumGeometries(p_geometry);
    WHILE ( v_geomn > 0 ) DO
      IF ( v_GeomN = ST_NumGeometries(p_geometry) ) THEN
        SET v_WKT = CONCAT(v_wkt,'(');
      ELSE
        SET v_wkt = CONCAT(v_wkt,',(');
      END IF;
      SET v_geom   = ST_GeometryN(p_geometry,v_geomn);
      SET v_pointn = ST_NumPoints(v_geom);
      WHILE ( v_pointN > 0 ) DO
        SET v_point = ST_PointN(v_geom,v_pointn);
        SET v_WKT = CONCAT(v_wkt,
                           CAST(ST_X(v_point) as char(50)),
                           ' ',
                           CAST(ST_Y(v_point) as char(50)));
        SET v_pointn = v_pointn - 1;
        IF ( v_pointN > 0 ) THEN
          SET v_WKT = CONCAT(v_WKT,',');
        END IF;
      END WHILE; 
      -- Terminate this part
      SET v_wkt = CONCAT(v_wkt,')');
      -- Process next
      SET v_geomn = v_geomn - 1;
    END WHILE;  -- All geometries...
    -- Terminate whole geometry and return.
    RETURN ST_GeomFromText(CONCAT(v_wkt,')'),ST_Srid(p_geometry));
  END IF;
  Return p_geometry;
End$$

DELIMITER ;

/* ***************************** TESTING *************************/

select id, action, geom 
  from (select 'Before' as action, id, ST_AsText(geom) as geom
          from (select 1 as id, ST_GeomFromText('LINESTRING(0 0, 10 0)',0) as geom
                union all
                select 2 as id, ST_GeomFromText('MULTILINESTRING((1 1,2 2), (3 3, 4 4))',0) as geom
                union all
                select 3 as id, ST_GeomFromText('MULTIPOINT((1 1),(2 2),(3 3),(4 4))',0) as geom
                ) as data
       union all
       select 'After' as action, id, ST_AsText(ST_Reverse(geom)) as geom
         from (select 1 as id, ST_GeomFromText('LINESTRING(0 0, 10 0)',0) as geom
               union all
               select 2 as id, ST_GeomFromText('MULTILINESTRING((1 1,2 2), (3 3, 4 4))',0) as geom
               union all
               select 3 as id, ST_GeomFromText('MULTIPOINT((1 1),(2 2),(3 3),(4 4))',0) as geom
              ) as data
       ) as f
order by id, action desc;


