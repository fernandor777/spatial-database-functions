-- *************************************
-- Create a table for routes (highways).
DROP   TABLE lrs_routes ;
CREATE TABLE lrs_routes (
  route_id        NUMBER PRIMARY KEY,
  route_name      VARCHAR2(32),
  route_geometry  SDO_GEOMETRY
);

-- Populate table with just one route for this example.
INSERT INTO lrs_routes VALUES(
  1,
  'Route1',
  SDO_GEOMETRY(
    3302,  -- line string, 3 dimensions: X,Y,M
    NULL,
    NULL,
    SDO_ELEM_INFO_ARRAY(1,2,1), -- one line string, straight segments
    SDO_ORDINATE_ARRAY(
      2,2,0,   -- Start point - Exit1; 0 is measure from start.
      2,4,2,   -- Exit2; 2 is measure from start. 
      8,4,8,   -- Exit3; 8 is measure from start. 
      12,4,12,  -- Exit4; 12 is measure from start. 
      12,10,NULL,  -- Not an exit; measure automatically calculated and filled.
      8,10,22,  -- Exit5; 22 is measure from start.  
      5,14,27)  -- End point (Exit6); 27 is measure from start.
  )
);

-- Update the Spatial metadata.
DELETE FROM user_sdo_geom_metadata where table_name = 'LRS_ROUTES' and column_name = 'ROUTE_GEOMETRY';
commit;
INSERT INTO user_sdo_geom_metadata
    (TABLE_NAME,
     COLUMN_NAME,
     DIMINFO,
     SRID)
  VALUES (
  'lrs_routes',
  'route_geometry',
  SDO_DIM_ARRAY(   -- 20X20 grid
    SDO_DIM_ELEMENT('X', 0, 20, 0.005),
    SDO_DIM_ELEMENT('Y', 0, 20, 0.005),
    SDO_DIM_ELEMENT('M', 0, 20, 0.005) -- Measure dimension
     ),
  NULL   -- SRID
);

-- Create the spatial index.
CREATE INDEX lrs_routes_idx 
          ON lrs_routes(route_geometry)
  INDEXTYPE IS MDSYS.SPATIAL_INDEX;

-- Test Oracle's SDO_LRS procedures.
DECLARE
  geom_segment SDO_GEOMETRY;
  line_string SDO_GEOMETRY;
  dim_array SDO_DIM_ARRAY;
  result_geom_1 SDO_GEOMETRY;
  result_geom_2 SDO_GEOMETRY;
  result_geom_3 SDO_GEOMETRY;
BEGIN
  SELECT a.route_geometry into geom_segment FROM lrs_routes a
    WHERE a.route_name = 'Route1';
  SELECT m.diminfo into dim_array from 
    user_sdo_geom_metadata m
    WHERE m.table_name = 'LRS_ROUTES' AND m.column_name = 'ROUTE_GEOMETRY';

  -- Define the LRS segment for Route1. This will populate any null measures.
  -- No need to specify start and end measures, because they are already defined 
  -- in the geometry.
  SDO_LRS.DEFINE_GEOM_SEGMENT (geom_segment, dim_array);

  SELECT a.route_geometry INTO line_string FROM lrs_routes a 
    WHERE a.route_name = 'Route1';

  -- Split Route1 into two segments.
  SDO_LRS.SPLIT_GEOM_SEGMENT(line_string,dim_array,5,result_geom_1,result_geom_2);

  -- Concatenate the segments that were just split.
  result_geom_3 := SDO_LRS.CONCATENATE_GEOM_SEGMENTS(result_geom_1, dim_array, result_geom_2, dim_array);

  -- Update and insert geometries into table, to display later.
  UPDATE lrs_routes a SET a.route_geometry = geom_segment
     WHERE a.route_id = 1;

  INSERT INTO lrs_routes VALUES( 11, 'result_geom_1', result_geom_1 );
  INSERT INTO lrs_routes VALUES( 12, 'result_geom_2', result_geom_2 );
  INSERT INTO lrs_routes VALUES( 13, 'result_geom_3', result_geom_3 );
END;
/
COMMIT;

-- First, display the data in the LRS table.
SELECT route_id, route_name, route_geometry 
  FROM lrs_routes;

-- Are result_geom_1 and result_geom2 connected? 
SELECT SDO_LRS.CONNECTED_GEOM_SEGMENTS(a.route_geometry,b.route_geometry, 0.005)
  FROM lrs_routes a, lrs_routes b
 WHERE a.route_id = 11 AND b.route_id = 12;

-- Is the Route1 segment valid?
SELECT  SDO_LRS.VALID_GEOM_SEGMENT(route_geometry)
  FROM lrs_routes WHERE route_id = 1;

-- Is 50 a valid measure on Route1? (Should return FALSE; highest Route1 measure is 27.)
SELECT  SDO_LRS.VALID_MEASURE(route_geometry, 50)
  FROM lrs_routes WHERE route_id = 1;

-- Is the Route1 segment defined?
SELECT  SDO_LRS.IS_GEOM_SEGMENT_DEFINED(route_geometry)
  FROM lrs_routes WHERE route_id = 1;

-- How long is Route1?
SELECT  SDO_LRS.GEOM_SEGMENT_LENGTH(route_geometry)
  FROM lrs_routes WHERE route_id = 1;

-- What is the start measure of Route1?
SELECT  SDO_LRS.GEOM_SEGMENT_START_MEASURE(route_geometry)
  FROM lrs_routes WHERE route_id = 1;

-- What is the end measure of Route1?
SELECT  SDO_LRS.GEOM_SEGMENT_END_MEASURE(route_geometry)
  FROM lrs_routes WHERE route_id = 1;

-- What is the start point of Route1?
SELECT  SDO_LRS.GEOM_SEGMENT_START_PT(route_geometry)
  FROM lrs_routes WHERE route_id = 1;

-- What is the end point of Route1?
SELECT  SDO_LRS.GEOM_SEGMENT_END_PT(route_geometry)
  FROM lrs_routes WHERE route_id = 1;

-- Translate (shift measure values) (+10).
-- First, display the original segment; then, translate.
SELECT a.route_geometry FROM lrs_routes a WHERE a.route_id = 1;
SELECT SDO_LRS.TRANSLATE_MEASURE(a.route_geometry, m.diminfo, 10)
  FROM lrs_routes a, user_sdo_geom_metadata m
  WHERE m.table_name = 'LRS_ROUTES' AND m.column_name = 'ROUTE_GEOMETRY'
    AND a.route_id = 1;
 
-- Redefine geometric segment to "convert" miles to kilometers
DECLARE
  geom_segment SDO_GEOMETRY;
  dim_array SDO_DIM_ARRAY;
BEGIN
  SELECT a.route_geometry 
    into geom_segment 
    FROM lrs_routes a
   WHERE a.route_name = 'Route1';
  SELECT m.diminfo 
    into dim_array 
    from user_sdo_geom_metadata m
   WHERE m.table_name = 'LRS_ROUTES' AND m.column_name = 'ROUTE_GEOMETRY';
 
  -- "Convert" mile measures to kilometers (27 * 1.609 = 43.443).
  SDO_LRS.REDEFINE_GEOM_SEGMENT (geom_segment, dim_array,
    0, -- Zero starting measure: LRS segment starts at start of route.
    43.443); -- End of LRS segment. 27 miles = 43.443 kilometers.
 
  -- Update and insert geometries into table, to display later.
  UPDATE lrs_routes a SET a.route_geometry = geom_segment
     WHERE a.route_id = 1;
END;
/
COMMIT;

-- Display the redefined segment, with all measures "converted."
SELECT a.route_geometry 
  FROM lrs_routes a 
 WHERE a.route_id = 1;

-- Clip a piece of Route1.
SELECT  SDO_LRS.CLIP_GEOM_SEGMENT(route_geometry, 5, 10)
  FROM lrs_routes 
 WHERE route_id = 1;

-- Point (9,3,NULL) is off the road; should return (9,4,9).
SELECT SDO_LRS.PROJECT_PT(route_geometry, SDO_GEOMETRY(3301, NULL, NULL, SDO_ELEM_INFO_ARRAY(1, 1, 1), SDO_ORDINATE_ARRAY(9, 3, NULL)) )
  FROM lrs_routes 
 WHERE route_id = 1;

-- Return the measure of the projected point.
SELECT SDO_LRS.GET_MEASURE( 
          SDO_LRS.PROJECT_PT(a.route_geometry, 
                             m.diminfo,
                             SDO_GEOMETRY(3301, NULL, NULL, SDO_ELEM_INFO_ARRAY(1, 1, 1), SDO_ORDINATE_ARRAY(9, 3, NULL)) 
                             ),
          m.diminfo )
 FROM lrs_routes a, 
      user_sdo_geom_metadata m
WHERE m.table_name  = 'LRS_ROUTES' 
  AND m.column_name = 'ROUTE_GEOMETRY'
  AND a.route_id = 1;

-- Is point (9,3,NULL) a valid LRS point? (Should return TRUE.)
SELECT SDO_LRS.VALID_LRS_PT( SDO_GEOMETRY(3301, NULL, NULL, SDO_ELEM_INFO_ARRAY(1, 1, 1), SDO_ORDINATE_ARRAY(9, 3, NULL)), m.diminfo)
  FROM lrs_routes a, 
       user_sdo_geom_metadata m
 WHERE m.table_name = 'LRS_ROUTES' 
   AND m.column_name = 'ROUTE_GEOMETRY'
   AND a.route_id = 1;

-- Locate the point on Route1 at measure 9, offset 0.
SELECT  SDO_LRS.LOCATE_PT(route_geometry, 9, 0)
  FROM lrs_routes 
  WHERE route_id = 1;

quit;

