DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

-- Always aim for a clean compile
ALTER SESSION SET PLSQL_WARNINGS='ERROR:ALL';
-- Enable optimizations
-- ALTER SESSION SET plsql_optimize_level=2;

CREATE OR REPLACE PACKAGE &&INSTALL_SCHEMA..ST_LRS 
AUTHID CURRENT_USER
AS

/****h* PACKAGE/ST_LRS
*  NAME
*    ST_LRS - A package that publishes an SDO_LRS view of the T_GEOMETRY object's ST_LRS* functions.
*  DESCRIPTION
*    A package that publishes an SDO_LRS view of the T_GEOMETRY object's ST_LRS* functions.
*    This is an example of what could be done to help Locator users use my LRS code and be in a position
*    to migrate with minimal effort to Oracle Spatial's Enterprise SDO_LRS code.
*    If this package is extended, please supply the changed package to me via simon@spatialdbadvisor.com
*  TODO
*    CONNECTED_GEOM_SEGMENTS
*    GET_NEXT_SHAPE_PT
*    GET_NEXT_SHAPE_PT_MEASURE
*    GET_PREV_SHAPE_PT
*    GET_PREV_SHAPE_PT_MEASURE
*  AUTHOR
*    Simon Greener
*  HISTORY
*    Simon Greener - Jan 2017 - Original coding.
*  COPYRIGHT
*    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
*  SOURCE
*/
   FUNCTION FIND_LRS_DIM_POS(lrs_geometry IN mdsys.sdo_geometry,
                             tolerance    in number default 0.005)
     RETURN INTEGER DETERMINISTIC;

   FUNCTION FIND_LRS_DIM_POS(table_name  IN VARCHAR2,
                             column_name IN VARCHAR2)
     RETURN INTEGER DETERMINISTIC;

   FUNCTION GEOM_SEGMENT_END_MEASURE(lrs_segment IN mdsys.sdo_geometry)
     RETURN NUMBER DETERMINISTIC;

   FUNCTION GEOM_SEGMENT_START_MEASURE(lrs_segment IN mdsys.sdo_geometry)
     RETURN NUMBER DETERMINISTIC;

  /**
   * Description
   *  Returns the measure range of a geometric segment, that is, the difference between the start measure and end measure.
   **/
   FUNCTION MEASURE_RANGE(lrs_segment IN mdsys.sdo_geometry,
                          dim_array   IN mdsys.sdo_dim_ARRAY DEFAULT NULL)
     RETURN NUMBER DETERMINISTIC;

   FUNCTION GEOM_SEGMENT_START_PT(geom_segment IN mdsys.sdo_geometry)
     RETURN mdsys.sdo_geometry Deterministic;

   FUNCTION GEOM_SEGMENT_END_PT(geom_segment IN mdsys.sdo_geometry)
     RETURN mdsys.sdo_geometry Deterministic;

   Function IS_SHAPE_PT_MEASURE(geom_segment in mdsys.sdo_geometry,
                                measure      in number)
     RETURN VARCHAR2 Deterministic;

   Function SET_PT_MEASURE(lrs_segment in mdsys.sdo_geometry,
                           point       IN mdsys.sdo_geometry,
                           measure     IN NUMBER,
                           tolerance   in number default 0.005)
     RETURN mdsys.sdo_geometry Deterministic;

   FUNCTION GET_MEASURE(point IN mdsys.sdo_geometry)
    RETURN NUMBER DETERMINISTIC;

   FUNCTION IS_MEASURE_INCREASING (lrs_segment IN mdsys.sdo_geometry)
    RETURN VARCHAR2 DETERMINISTIC;

   FUNCTION IS_MEASURE_DECREASING (lrs_segment IN mdsys.sdo_geometry)
    RETURN VARCHAR2 DETERMINISTIC;

   /**
    * The start and end measures of geom_segment must be defined (cannot be null),
    * and any measures assigned must be in an ascending or descending order along the segment direction.
   **/
   FUNCTION IS_GEOM_SEGMENT_DEFINED(geom_segment IN mdsys.sdo_geometry,
                                    dim_array    IN mdsys.sdo_dim_ARRAY DEFAULT NULL)
     RETURN VARCHAR2 DETERMINISTIC;

   FUNCTION MEASURE_TO_PERCENTAGE(lrs_segment IN mdsys.sdo_geometry,
                                  measure     IN NUMBER)
    RETURN NUMBER DETERMINISTIC;

   FUNCTION PERCENTAGE_TO_MEASURE(lrs_segment IN mdsys.sdo_geometry,
                                  percentage  IN NUMBER)
    RETURN NUMBER DETERMINISTIC;

   Function GEOM_SEGMENT_LENGTH(geom_segment in mdsys.sdo_geometry,
                                unit         in varchar2 default null)
     RETURN NUMBER Deterministic;

   FUNCTION SPLIT_GEOM_SEGMENT(geom_segment  IN mdsys.sdo_geometry,
                               split_measure IN NUMBER,
                               tolerance     IN NUMBER DEFAULT 0.005)
     RETURN mdsys.sdo_geometry_array pipelined;

   PROCEDURE SPLIT_GEOM_SEGMENT(geom_segment   IN mdsys.sdo_geometry,
                                split_measure  IN NUMBER,
                                segment_1      IN OUT NOCOPY mdsys.sdo_geometry,
                                segment_2      IN OUT NOCOPY mdsys.sdo_geometry,
                                tolerance      IN NUMBER DEFAULT 0.005);

   FUNCTION CONCATENATE_GEOM_SEGMENTS(geom_segment_1 IN mdsys.sdo_geometry,
                                      geom_segment_2 IN mdsys.sdo_geometry,
                                      tolerance      IN NUMBER DEFAULT 0.005,
                                      unit           IN varchar2 default null)
     RETURN mdsys.sdo_geometry DETERMINISTIC;

   FUNCTION CLIP_GEOM_SEGMENT(GEOM_SEGMENT  IN mdsys.sdo_geometry,
                              START_MEASURE IN NUMBER,
                              END_MEASURE   IN NUMBER,
                              TOLERANCE     IN NUMBER   DEFAULT 0.005,
                              UNIT          IN VARCHAR2 DEFAULT NULL)
     RETURN mdsys.sdo_geometry DETERMINISTIC;

   FUNCTION LOCATE_PT(GEOM_SEGMENT IN mdsys.sdo_geometry,
                      MEASURE      IN NUMBER,
                      OFFSET       IN NUMBER,
                      TOLERANCE    IN NUMBER   DEFAULT 0.005,
                      UNIT         IN VARCHAR2 DEFAULT NULL)
     RETURN mdsys.sdo_geometry DETERMINISTIC;

   FUNCTION FIND_OFFSET (GEOM_SEGMENT IN mdsys.sdo_geometry,
                         POINT        IN mdsys.sdo_geometry,
                         TOLERANCE    IN NUMBER   DEFAULT 0.005,
                         UNIT         IN VARCHAR2 DEFAULT NULL)
    RETURN NUMBER DETERMINISTIC;

   FUNCTION FIND_MEASURE(lrs_segment IN mdsys.sdo_geometry,
                         POINT       IN mdsys.sdo_geometry,
                         TOLERANCE   IN NUMBER   DEFAULT 0.005,
                         UNIT        IN VARCHAR2 DEFAULT NULL)
    RETURN NUMBER DETERMINISTIC;

   FUNCTION PROJECT_PT (GEOM_SEGMENT IN mdsys.sdo_geometry,
                        POINT        IN mdsys.sdo_geometry,
                        TOLERANCE    IN NUMBER DEFAULT 0.005,
                        UNIT         IN VARCHAR2 DEFAULT NULL)
    RETURN mdsys.sdo_geometry DETERMINISTIC;

   FUNCTION LRS_INTERSECTION(GEOM_1    IN mdsys.sdo_geometry,
                             GEOM_2    IN mdsys.sdo_geometry,
                             TOLERANCE IN NUMBER DEFAULT 0.005)
    RETURN mdsys.sdo_geometry DETERMINISTIC;

   FUNCTION REVERSE_MEASURE (lrs_segment IN mdsys.sdo_geometry)
     RETURN mdsys.sdo_geometry DETERMINISTIC;

   FUNCTION REVERSE_GEOMETRY (geom_segment IN mdsys.sdo_geometry)
     RETURN mdsys.sdo_geometry DETERMINISTIC;

   /* Populates the measures of all shape points based on the start and end measures of a geometric segment, overriding any previously assigned measures between the start point and end point.*/
   Function REDEFINE_GEOM_SEGMENT(geom_segment  IN mdsys.sdo_geometry,
                                  start_measure IN NUMBER,
                                  end_measure   IN NUMBER)
     RETURN mdsys.sdo_geometry DETERMINISTIC;

   Procedure REDEFINE_GEOM_SEGMENT(geom_segment  IN OUT NOCOPY mdsys.sdo_geometry,
                                   start_measure IN NUMBER,
                                   end_measure   IN NUMBER);

   PROCEDURE RESET_MEASURE(lrs_segment in OUT NOCOPY mdsys.sdo_geometry);

   FUNCTION RESET_MEASURE(lrs_segment IN mdsys.sdo_geometry)
     RETURN mdsys.sdo_geometry DETERMINISTIC;

   FUNCTION TRANSLATE_MEASURE(geom_segment IN mdsys.sdo_geometry,
                              translate_m  IN NUMBER)
     RETURN mdsys.sdo_geometry DETERMINISTIC;

   FUNCTION CONVERT_TO_STD_GEOM(lrs_segment IN mdsys.sdo_geometry)
     RETURN mdsys.sdo_geometry DETERMINISTIC;

   FUNCTION CONVERT_TO_LRS_GEOM(standard_geom IN mdsys.sdo_geometry,
                                start_measure IN NUMBER DEFAULT NULL,
                                end_measure   IN NUMBER DEFAULT NULL)
     RETURN mdsys.sdo_geometry DETERMINISTIC;

   FUNCTION SCALE_GEOM_SEGMENT(lrs_segment   IN mdsys.sdo_geometry,
                               start_measure IN NUMBER,
                               end_measure   IN NUMBER,
                               shift_measure IN NUMBER,
                               tolerance     IN NUMBER DEFAULT 0.005 )
     RETURN mdsys.sdo_geometry DETERMINISTIC;

   FUNCTION DYNAMIC_SEGMENT(GEOM_SEGMENT  IN mdsys.sdo_geometry,
                            START_MEASURE IN NUMBER,
                            END_MEASURE   IN NUMBER,
                            TOLERANCE     IN NUMBER   DEFAULT 0.005,
                            UNIT          IN VARCHAR2 DEFAULT NULL)
     RETURN mdsys.sdo_geometry DETERMINISTIC;

   Function OFFSET_GEOM_SEGMENT(geom_segment  IN mdsys.sdo_geometry,
                                start_measure IN NUMBER,
                                end_measure   IN NUMBER,
                                offset        IN NUMBER DEFAULT 0,
                                tolerance     IN NUMBER DEFAULT 0.005,
                                unit          IN VARCHAR2 default null)
     RETURN mdsys.sdo_geometry Deterministic;

   Function VALID_GEOM_SEGMENT(geom_segment IN mdsys.sdo_geometry,
                               dim_array    IN mdsys.sdo_dim_ARRAY default null)
     RETURN VARCHAR2 Deterministic;

   Function VALID_LRS_PT(point     IN mdsys.sdo_geometry,
                         dim_array IN mdsys.sdo_dim_ARRAY DEFAULT NULL)
     RETURN VARCHAR2 Deterministic;

   Function VALID_MEASURE(geom_segment in mdsys.sdo_geometry,
                          measure      in number)
     RETURN VARCHAR2 Deterministic;

   Function VALIDATE_LRS_GEOMETRY(geom_segment in mdsys.sdo_geometry,
                                  dim_array    in mdsys.sdo_dim_ARRAY default null)
     RETURN VARCHAR2 Deterministic;

   Function ROUND_COORDINATES(geom_segment   in mdsys.sdo_geometry,
                              p_dec_places_x in integer default null,
                              p_dec_places_y in integer default null,
                              p_dec_places_z in integer default null,
                              p_dec_places_m in integer default null)
     RETURN mdsys.sdo_geometry Deterministic;

/*******/

END ST_LRS;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'ST_LRS';
BEGIN
   FOR rec IN (select object_name,object_Type, status 
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'PACKAGE'
               order by object_type) LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is valid.');
      ELSE
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is invalid.');
         v_ok := false;
      END IF;
   END LOOP;
   execute immediate 'GRANT EXECUTE ON &&INSTALL_SCHEMA..' || v_obj_name || ' TO public WITH GRANT OPTION';
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

EXIT SUCCESS;
