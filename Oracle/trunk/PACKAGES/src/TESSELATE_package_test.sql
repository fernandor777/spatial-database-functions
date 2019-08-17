DEFINE defaultSchema='&1'

SET PAGESIZE 1000
SET LINESIZE 150
SET TIMING OFF
SET HEADING OFF

Prompt Test Morton function
SELECT &&defaultSchema..TESSELATE.morton(100,300) as morton_key
  FROM dual;

Prompt Create table to be quadded
DROP SEQUENCE my_points_seq;
CREATE SEQUENCE my_points_seq;

DROP TABLE my_points;
Prompt Create a table to hold our point data maximising its use of database blocks so it uses as little space as possible
CREATE TABLE my_points ( 
  point_id     Integer primary key,
  window_id    Integer,
  sub_point_id Integer,
  geometry     mdsys.sdo_geometry
) NOLOGGING PCTUSED 99 ;

INSERT /*+APPEND*/ INTO my_points (point_id,window_id,sub_point_id,geometry)
With params As (
  select 100000  as minx,
         5000000 as miny,
         400000  as maxx,
         6000000 as maxy,
         5       as InternalWindows,
         5000    as PointsPerWindow,
         500     as minWidth,
         100000  as maxWidth,
         500     as minHeight,
         100000  as maxHeight,
         0.05    as sdoTolerance  
   from dual
)
SELECT rownum as point_id,
       w.Window_Id,
       s.COLUMN_VALUE as PointN, 
       mdsys.sdo_geometry(2001,NULL,
                   MDSYS.SDO_POINT_TYPE(
                         ROUND(dbms_random.value(w.x - ( w.WinWidth  / 2 ),  
                                                 w.x + ( w.WinWidth  / 2 )),ROUND(log(10,1/w.sdotolerance))+1),
                         ROUND(dbms_random.value(w.y - ( w.WinHeight / 2 ), 
                                                 w.y + ( w.WinHeight / 2 )),ROUND(log(10,1/w.sdotolerance))+1),
                         NULL),
                   NULL,NULL) as geometry
 FROM ( SELECT rownum As Window_ID, 
               p.PointCount, 
               p.X, 
               p.Y, 
               p.WinHeight, 
               p.WinWidth,
               p.sdoTolerance
          FROM ( SELECT p.sdotolerance,
                        ( p.minx + p.maxx ) / 2                         as X,
                        ( p.miny + p.maxy ) / 2                         as y,
                        ( p.maxy - p.miny )                             as WinHeight,
                        ( p.maxx - p.minx )                             as WinWidth,
                        trunc(dbms_random.value(1,p.PointsPerWindow),0) as PointCount
                   FROM params p
                 UNION ALL 
                 SELECT  p.sdotolerance,
                         dbms_random.value(p.minx,p.maxx)                as X,
                        dbms_random.value(p.miny,p.maxy)                as Y,
                        dbms_random.value(p.minHeight,p.maxHeight)      as WinHeight,
                        dbms_random.value(p.minWidth,p.maxWidth)        as WinWidth,
                        trunc(dbms_random.value(1,p.PointsPerWindow),0) as PointCount
                   FROM params p
                 CONNECT BY LEVEL <= p.InternalWindows
               ) p
      ) w,
      TABLE(CAST(MULTISET(select level from dual connect by level <= w.PointCount) as t_numbers)) s;
COMMIT;
ALTER TABLE my_points LOGGING;

Prompt Let us sample some of the created data... 
SELECT myp.geometry.sdo_point.x,
       myp.geometry.sdo_point.y,
       window_id
  FROM my_points sample (2) myp;

Prompt Let us summary what was inserted into the table...
SELECT 'For Window ' || window_id || ' ' || count(*) || ' points were stored' As Result
  FROM my_points
GROUP BY window_id;

Prompt Create Oracle Metadata Entry...
DELETE FROM user_sdo_geom_metadata WHERE table_name = 'MY_POINTS';
COMMIT;
INSERT INTO user_sdo_geom_metadata 
SELECT 'MY_POINTS','GEOMETRY', 
       MDSYS.SDO_DIM_ARRAY( 
             MDSYS.SDO_DIM_ELEMENT('X', minx, maxx, 0.05), 
             MDSYS.SDO_DIM_ELEMENT('Y', miny, maxy, 0.05)), NULL
  FROM ( SELECT TRUNC( MIN( a.geometry.sdo_point.x ) - 1,0) as minx,
                ROUND( MAX( a.geometry.sdo_point.x ) + 1,0) as maxx,
                TRUNC( MIN( a.geometry.sdo_point.y ) - 1,0) as miny,
                ROUND( MAX( a.geometry.sdo_point.y ) + 1,0) as maxy
           FROM my_points a);

Prompt Create RTree index on point data ...
DROP INDEX my_points_geometry;
CREATE INDEX my_points_geometry ON my_points(geometry) 
INDEXTYPE IS MDSYS.SPATIAL_INDEX 
PARAMETERS('sdo_indx_dims=2, layer_gtype=point');

-- *******************************************************************
Prompt Now quad the test data into a table called QUAD 

DROP TABLE QUAD;
DECLARE
  v_diminfo mdsys.SDO_DIM_ARRAY;
BEGIN
  SELECT diminfo
    INTO v_diminfo
    FROM user_sdo_geom_metadata u
   WHERE table_name  = 'MY_POINTS'
     AND column_name = 'GEOMETRY';
  Tesselate.QuadTree( p_MaxCount     => 200,
                      p_SearchTable  => 'MY_POINTS',
                      p_SearchColumn => 'GEOMETRY',
                      p_diminfo      => v_diminfo,
                      p_TargetTable  => 'QUAD',
                      p_TargetColumn => 'GEOM',
                      p_MaxQuadLevel => 16,
                      p_format       => 'SDO' );
  COMMIT;
END;
/
SHOW ERRORS

CREATE INDEX &&defaultSchema..QUAD_GEOM_SPIX
          ON &&defaultSchema..QUAD(GEOM)
   INDEXTYPE IS MDSYS.SPATIAL_INDEX
PARAMETERS('sdo_indx_dims=2, layer_gtype=POLYGON, tablespace=USERS');

-- ******************************************************

Select *
 From Table(&&defaultSchema..TESSELATE.RegularGrid( 
            MDSYS.SDO_POINT_TYPE(0,0,NULL),
            MDSYS.SDO_POINT_TYPE(100,60,NULL),
            MDSYS.SDO_POINT_TYPE(25,20,NULL),
            Null ) );
EXIT;

