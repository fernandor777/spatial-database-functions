DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

-- Always aim for a clean compile
ALTER SESSION SET PLSQL_WARNINGS='ERROR:ALL';
-- Enable optimizations
ALTER SESSION SET plsql_optimize_level=2;

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

CREATE OR REPLACE PACKAGE BODY ST_LRS 
As

   FUNCTION Find_Lrs_Dim_Pos(lrs_geometry IN mdsys.sdo_geometry,
                             tolerance    in number default 0.005) 
     RETURN INTEGER 
   As
   BEGIN
     Return &&INSTALL_SCHEMA..T_GEOMETRY(lrs_geometry,nvl(tolerance,0.005))
                .ST_Lrs_Dim();
   END Find_Lrs_Dim_Pos;
   
   FUNCTION Find_Lrs_Dim_Pos(table_name  IN VARCHAR2,
                             column_name IN VARCHAR2) 
     RETURN INTEGER 
   As
     v_schema     varchar2(30) := case when INSTR(table_name,'.')=0 then sys_context('USERENV','SESSION_USER') else SUBSTR(table_name,1,INSTR(table_name,'.')-1) end;
     v_table_name varchar2(30) := case when v_schema is null        then table_name                            else SUBSTR(table_name,INSTR(table_name,'.')+1,30) end;
     v_dim_array  mdsys.sdo_dim_array;
   Begin
     -- dbms_output.put_line(NVL(v_schema,'NULL')||','||NVL(v_table_name,'NULL')||','||NVL(column_name,'NULL'));
     IF ( ( v_schema is null and v_table_name is null ) or (column_name is null) ) Then
       RETURN NULL;
     END IF;
     SELECT m.diminfo 
       INTO v_dim_array 
       FROM all_sdo_geom_metadata m
      WHERE m.owner       = v_schema
        AND m.table_name  = v_table_name
        AND m.column_name = column_name;
     IF (v_dim_array is not null) Then
       FOR i IN 1..v_dim_array.COUNT LOOP
         IF ( UPPER(v_dim_array(i).sdo_dimname) = 'M' ) THEN
           RETURN i;
         END IF;
       END LOOP;
     END IF;
     RETURN NULL;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
         RETURN null;
   End Find_Lrs_Dim_Pos;

   FUNCTION CONCATENATE_GEOM_SEGMENTS(geom_segment_1 IN mdsys.sdo_geometry,
                                      geom_segment_2 IN mdsys.sdo_geometry,
                                      tolerance      IN NUMBER DEFAULT 0.005,
                                      unit           IN varchar2 default null) 
     RETURN mdsys.sdo_geometry 
   As
   BEGIN
     Return &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment_1,nvl(tolerance,0.005))
                .ST_LRS_Concatenate(geom_segment_2,unit)
                .geom;
   END CONCATENATE_GEOM_SEGMENTS;

   FUNCTION SPLIT_GEOM_SEGMENT(geom_segment  IN mdsys.sdo_geometry,
                               split_measure IN NUMBER,
                               tolerance     IN NUMBER DEFAULT 0.005) 
     RETURN mdsys.sdo_geometry_array pipelined
   As
     v_geom_array &&INSTALL_SCHEMA..T_GEOMETRIES;
   Begin
     IF ( split_measure is null ) Then
       PIPE ROW (geom_segment);
     End If;
     v_geom_array := &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment,NVL(tolerance,0.05))
                         .ST_SPLIT(p_measure=>split_measure);
     IF ( v_geom_array is not null) THEN
       IF ( v_geom_array.COUNT >= 1 ) THEN
         PIPE ROW (v_geom_array(1).geometry);
         IF ( v_geom_array.COUNT > 1 ) THEN
           PIPE ROW (v_geom_array(2).geometry);
         END IF;
       END IF;
     END IF;
     RETURN;
   End SPLIT_GEOM_SEGMENT;
     
   PROCEDURE SPLIT_GEOM_SEGMENT(geom_segment  IN mdsys.sdo_geometry,
                                split_measure IN NUMBER,
                                segment_1     IN OUT NOCOPY mdsys.sdo_geometry,
                                segment_2     IN OUT NOCOPY mdsys.sdo_geometry,
                                tolerance     IN NUMBER DEFAULT 0.005)
   As
     v_geom_array &&INSTALL_SCHEMA..T_GEOMETRIES;
   Begin
     IF ( split_measure is null ) Then
       RETURN ;
     End If;
     v_geom_array := &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment,NVL(tolerance,0.05))
                         .ST_SPLIT(p_measure=>split_measure);
     IF ( v_geom_array is not null) THEN
       IF ( v_geom_array.COUNT >= 1 ) THEN
         segment_1 := v_geom_array(1).geometry;
         IF ( v_geom_array.COUNT > 1 ) THEN
           segment_2 := v_geom_array(2).geometry;
         END IF;
       END IF;
     END IF;
     RETURN;
   END SPLIT_GEOM_SEGMENT;
                                
   FUNCTION CLIP_GEOM_SEGMENT(GEOM_SEGMENT  IN mdsys.sdo_geometry,
                              START_MEASURE IN NUMBER,
                              END_MEASURE   IN NUMBER,
                              TOLERANCE     IN NUMBER   DEFAULT 0.005,
                              UNIT          IN VARCHAR2 DEFAULT NULL)
     RETURN mdsys.sdo_geometry
   As
   BEGIN
     Return &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment,nvl(tolerance,0.005))
                .ST_LRS_Locate_Measures(
                  p_start_measure => START_MEASURE,
                  p_end_measure   => END_MEASURE,
                  p_offset        => 0,
                  p_unit          => UNIT)
                .geom;
   END CLIP_GEOM_SEGMENT;

   FUNCTION DYNAMIC_SEGMENT(GEOM_SEGMENT  IN mdsys.sdo_geometry,
                            START_MEASURE IN NUMBER,
                            END_MEASURE   IN NUMBER,
                            TOLERANCE     IN NUMBER   DEFAULT 0.005,
                            UNIT          IN VARCHAR2 DEFAULT NULL)
     RETURN mdsys.sdo_geometry
   As
   BEGIN
     Return &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment,nvl(tolerance,0.005))
                .ST_LRS_Locate_Measures(
                  p_start_measure => START_MEASURE,
                  p_end_measure   => END_MEASURE,
                  p_offset        => 0,
                  p_unit          => UNIT)
                .geom;
   END DYNAMIC_SEGMENT;

   FUNCTION LOCATE_PT (GEOM_SEGMENT IN mdsys.sdo_geometry,
                       MEASURE      IN NUMBER,
                       OFFSET       IN NUMBER,
                       TOLERANCE    IN NUMBER   DEFAULT 0.005,
                       UNIT         IN VARCHAR2 DEFAULT NULL)
     RETURN mdsys.sdo_geometry
   As
     v_point mdsys.sdo_geometry;
   BEGIN
     v_point := &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment,nvl(tolerance,0.005))
                    .ST_LRS_Locate_Measure(
                        p_measure => MEASURE,
                        p_offset  => (0-NVL(offset,0)), /* Reverse Sign because Oracle has Left as + while I have left as - */
                        p_unit    => UNIT)
                    .ST_SdoPoint2Ord()
                    .geom;
    RETURN v_point;
   END Locate_Pt;
   
   FUNCTION FIND_OFFSET (GEOM_SEGMENT IN mdsys.sdo_geometry,
                         POINT        IN mdsys.sdo_geometry,
                         TOLERANCE    IN NUMBER   DEFAULT 0.005,
                         UNIT         IN VARCHAR2 DEFAULT NULL)
    RETURN NUMBER
   As
    v_offset NUMBER;
   BEGIN
     /* Reverse Sign because Oracle has Left as + while I have left as - */
     v_offset := &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment,nvl(tolerance,0.005))
                     .St_Lrs_Find_Offset(p_point=>point,
                                         p_unit=>unit);
     IF (sign(v_offset) = -1) THEN
       v_offset := abs(v_offset);
     ELSIF (sign(v_offset) = 1) THEN
       v_offset := 0 - v_offset;
     END IF;
     RETURN v_offset;
   END FIND_OFFSET;
   
   FUNCTION FIND_MEASURE(lrs_segment  IN mdsys.sdo_geometry,
                         POINT        IN mdsys.sdo_geometry,
                         TOLERANCE    IN NUMBER   DEFAULT 0.005,
                         UNIT         IN VARCHAR2 DEFAULT NULL)
    RETURN NUMBER 
   As
   BEGIN
      RETURN &&INSTALL_SCHEMA..T_GEOMETRY(lrs_segment,nvl(tolerance,0.005))
                 .ST_LRS_Find_MeasureN(p_geom     => POINT,
                                       p_measureN => 1,
                                       p_unit     => UNIT);
   END FIND_MEASURE;

   Function SET_PT_MEASURE(lrs_segment in mdsys.sdo_geometry,
                           point       IN mdsys.sdo_geometry,
                           measure     IN NUMBER,
                           tolerance   in number default 0.005)
     RETURN mdsys.sdo_geometry
   As
     v_old_vertex &&INSTALL_SCHEMA..T_Vertex;
     v_new_vertex &&INSTALL_SCHEMA..T_Vertex;
   Begin
     v_old_vertex := &&INSTALL_SCHEMA..T_Vertex(point);
     v_new_vertex := &&INSTALL_SCHEMA..T_Vertex(point).ST_LRS_Set_Measure(measure);
     RETURN &&INSTALL_SCHEMA..T_GEOMETRY(
                lrs_segment,
                NVL(tolerance,0.005)
            )
            .ST_UpdateVertex(p_old_vertex => v_old_vertex,
                             p_new_vertex => v_new_vertex)
            .geom;
   End SET_PT_MEASURE;

   FUNCTION GET_MEASURE(point IN mdsys.sdo_geometry)
    RETURN NUMBER 
   As
   BEGIN
      RETURN &&INSTALL_SCHEMA..T_GEOMETRY(point).ST_LRS_Get_Measure();
   END GET_MEASURE;
    
   FUNCTION PROJECT_PT (GEOM_SEGMENT IN mdsys.sdo_geometry,
                        POINT        IN mdsys.sdo_geometry,
                        TOLERANCE    IN NUMBER   DEFAULT 0.005,
                        UNIT         IN VARCHAR2 DEFAULT NULL)
    RETURN mdsys.sdo_geometry
   AS
      v_measure number;
   BEGIN
      Return &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment,nvl(tolerance,0.005))
                 .ST_LRS_Project_Point (p_point => POINT,
                                        p_unit  => UNIT)
                 .geom;
   END Project_Pt;

   FUNCTION LRS_INTERSECTION(geom_1    in mdsys.sdo_geometry,
                             geom_2    in mdsys.sdo_geometry,
                             tolerance in number default 0.005)
    RETURN mdsys.sdo_geometry 
  As
    v_tgeom &&INSTALL_SCHEMA..T_Geometry;
  BEGIN
    v_tgeom := &&INSTALL_SCHEMA..T_GEOMETRY(GEOM_1,TOLERANCE)
                   .ST_LRS_Intersection(p_geom=>geom_2);
    IF ( v_tgeom is not null and v_tGeom.ST_Dimension()=0 ) Then
      RETURN v_tgeom.ST_SdoPoint2Ord().geom;
    END IF;
    RETURN v_tgeom.geom;
  END LRS_INTERSECTION;

   FUNCTION Convert_To_Lrs_Geom(standard_geom IN mdsys.sdo_geometry,
                                start_measure IN NUMBER DEFAULT NULL,
                                end_measure   IN NUMBER DEFAULT NULL)
     RETURN mdsys.sdo_geometry 
   As
   Begin
     Return &&INSTALL_SCHEMA..T_GEOMETRY(standard_geom)
              .ST_LRS_Add_Measure(p_start_measure => start_measure,
                                  p_end_measure   => end_measure,
                                  p_unit          => NULL)
              .geom;
   END Convert_To_Lrs_Geom;

   FUNCTION Reverse_Measure(lrs_segment IN mdsys.sdo_geometry) 
     RETURN mdsys.sdo_geometry 
   As
   Begin
     Return &&INSTALL_SCHEMA..T_GEOMETRY(lrs_segment)
              .ST_LRS_Reverse_Measure()
              .geom;
   END Reverse_Measure;

   FUNCTION Reverse_Geometry (geom_segment IN mdsys.sdo_geometry) 
     RETURN mdsys.sdo_geometry 
   As
   Begin
     Return &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment)
              .ST_Reverse_Linestring()
              .geom;
   END Reverse_Geometry;

   FUNCTION Reset_Measure(lrs_segment IN mdsys.sdo_geometry)
     RETURN mdsys.sdo_geometry 
   As
   Begin
     Return &&INSTALL_SCHEMA..T_GEOMETRY(lrs_segment)
              .ST_LRS_Reset_Measure()
              .geom;
   End Reset_Measure;

   PROCEDURE Reset_Measure(lrs_segment IN OUT NOCOPY mdsys.sdo_geometry)
   As
   Begin
     lrs_segment := &&INSTALL_SCHEMA..T_GEOMETRY(lrs_segment)
                           .ST_LRS_Reset_Measure()
                           .geom;
   End Reset_Measure;

   FUNCTION TRANSLATE_MEASURE(geom_segment IN mdsys.sdo_geometry,
                              translate_m  IN NUMBER) 
     RETURN mdsys.sdo_geometry 
  As
    v_line &&INSTALL_SCHEMA..T_GEOMETRY := &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment);
  Begin
     Return v_line
             .ST_LRS_Scale_Measures(p_start_measure=>v_line.ST_LRS_Start_Measure(),
                                    p_end_measure  =>v_line.ST_LRS_End_Measure(),
                                    p_shift_measure=>translate_m)
             .geom;
  End Translate_measure;

   Function REDEFINE_GEOM_SEGMENT(geom_segment  IN mdsys.sdo_geometry,
                                  start_measure IN NUMBER,
                                  end_measure   IN NUMBER)
     RETURN mdsys.sdo_geometry 
   As
   Begin
     RETURN &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment)
                .ST_LRS_Update_Measures(p_start_measure=>start_measure,
                                        p_end_measure  =>end_measure,
                                        p_unit         =>null)
                .geom;
   End REDEFINE_GEOM_SEGMENT;

   Procedure REDEFINE_GEOM_SEGMENT(geom_segment  IN OUT NOCOPY mdsys.sdo_geometry,
                                   start_measure IN NUMBER,
                                   end_measure   IN NUMBER)
   As
   Begin     
     geom_segment := &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment)
                         .ST_LRS_Update_Measures(p_start_measure=>start_measure,
                                                 p_end_measure  =>end_measure,
                                                 p_unit         =>null)
                         .geom;
   End REDEFINE_GEOM_SEGMENT;
   
    FUNCTION Is_Measure_Increasing(lrs_segment IN mdsys.sdo_geometry)
    RETURN VARCHAR2
   As
   Begin
     Return &&INSTALL_SCHEMA..T_GEOMETRY(lrs_segment)
                .ST_LRS_Is_Measure_Increasing();
   END Is_Measure_Increasing;

   FUNCTION Is_Measure_Decreasing (lrs_segment IN mdsys.sdo_geometry)
    RETURN VARCHAR2
   As
   Begin
     Return &&INSTALL_SCHEMA..T_GEOMETRY(lrs_segment)
                .ST_LRS_Is_Measure_Decreasing();
   END Is_Measure_Decreasing;

   FUNCTION Measure_To_Percentage(lrs_segment IN mdsys.sdo_geometry,
                                  measure     IN NUMBER)
    RETURN NUMBER
   As
   Begin
     Return &&INSTALL_SCHEMA..T_GEOMETRY(lrs_segment)
                .ST_LRS_Measure_To_Percentage(p_measure => Measure,
                                              p_unit    => NULL);
   END Measure_To_Percentage;

   FUNCTION Percentage_To_Measure(lrs_segment IN mdsys.sdo_geometry,
                                  Percentage  IN NUMBER)
    RETURN NUMBER 
   As
   Begin
     Return &&INSTALL_SCHEMA..T_GEOMETRY(lrs_segment)
                .ST_LRS_Percentage_To_Measure(p_percentage => Percentage,
                                              p_unit       => NULL);
   END Percentage_To_Measure;

  /**
   * Description
   *  Returns the measure range of a geometric segment, that is, the difference between the start measure and end measure.
   **/
   FUNCTION Measure_Range(lrs_segment IN mdsys.sdo_geometry,
                          dim_array   IN mdsys.sdo_dim_ARRAY default null)
     RETURN NUMBER 
   As
     v_tolerance number := 0.005;
   Begin
     IF (dim_array is not null and dim_array.COUNT > 0 ) Then
       v_tolerance := dim_array(1).sdo_tolerance;
     End If;
     Return &&INSTALL_SCHEMA..T_GEOMETRY(lrs_segment, v_tolerance)
                .ST_LRS_Measure_Range(p_unit => NULL);
   END Measure_Range;

   /** 
    * The start and end measures of geom_segment must be defined (cannot be null), 
    * and any measures assigned must be in an ascending or descending order along the segment direction.
   **/
   FUNCTION Is_Geom_Segment_Defined(geom_segment IN mdsys.sdo_geometry,
                                    dim_array    IN mdsys.sdo_dim_ARRAY DEFAULT NULL) 
     RETURN VARCHAR2 
   As
   Begin
     Return CASE WHEN &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment)
                          .ST_LRS_isMeasured() = 1 
                 THEN 'TRUE' 
                 ELSE 'FALSE' 
            END;
   End Is_Geom_Segment_Defined;

   FUNCTION Convert_To_Std_Geom(lrs_segment IN mdsys.sdo_geometry) 
     RETURN mdsys.sdo_geometry 
   As
   Begin
     Return &&INSTALL_SCHEMA..T_GEOMETRY(lrs_segment)
                .ST_To2D()
                .geom;
   ENd Convert_To_Std_Geom;

   FUNCTION Scale_Geom_Segment(lrs_segment   IN mdsys.sdo_geometry,
                               start_measure IN NUMBER,
                               end_measure   IN NUMBER,
                               shift_measure IN NUMBER,
                               tolerance     IN NUMBER DEFAULT 0.005) 
     RETURN mdsys.sdo_geometry 
   As
   BEGIN
     Return &&INSTALL_SCHEMA..T_GEOMETRY(lrs_segment,nvl(tolerance,0.005))
                .ST_LRS_Scale_Measures(p_start_measure => start_measure,
                                       p_end_measure   => end_measure,
                                       p_shift_measure => shift_measure)
                .geom;
   END Scale_Geom_Segment;

   FUNCTION Geom_Segment_Start_Measure(lrs_segment IN mdsys.sdo_geometry) 
     RETURN NUMBER 
   As
   BEGIN
     Return &&INSTALL_SCHEMA..T_GEOMETRY(lrs_segment)
                .ST_LRS_Start_Measure();
   END Geom_Segment_Start_Measure;

   FUNCTION Geom_Segment_End_Measure(lrs_segment IN mdsys.sdo_geometry) 
     RETURN NUMBER 
   As
   BEGIN
     Return &&INSTALL_SCHEMA..T_GEOMETRY(lrs_segment)
                .ST_LRS_End_Measure();
   END Geom_Segment_End_Measure;

   FUNCTION Geom_Segment_Start_Pt(geom_segment IN mdsys.sdo_geometry) 
     RETURN mdsys.sdo_geometry 
   As
   BEGIN
     Return &&INSTALL_SCHEMA..T_GEOMETRY(
              p_vertex    => &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment)
                              .ST_StartVertex()
                              .ST_VertexType(),
              p_srid      => geom_segment.sdo_srid,
              p_tolerance => 0.005
            )
            .ST_SdoPoint2Ord()
            .geom;
   END Geom_Segment_Start_Pt;

   FUNCTION Geom_Segment_End_Pt(geom_segment IN mdsys.sdo_geometry) 
     RETURN mdsys.sdo_geometry 
   As
   BEGIN
     Return &&INSTALL_SCHEMA..T_GEOMETRY(
              p_vertex    => &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment)
                            .ST_EndVertex()
			    .ST_VertexType(),
              p_srid      => geom_segment.sdo_srid,
              p_tolerance => 0.005
            )
            .ST_SdoPoint2Ord()
            .geom;
   END Geom_Segment_End_Pt;

   Function IS_SHAPE_PT_MEASURE(geom_segment in mdsys.sdo_geometry,
                                measure      IN NUMBER)
     RETURN VARCHAR2
   As
   Begin
     IF ( geom_segment is null ) THEN
       RETURN 'FALSE';
     END IF;
     Return &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment,0.005).ST_LRS_Is_Shape_Pt_Measure(p_measure => measure);
   End IS_SHAPE_PT_MEASURE;

   Function Geom_Segment_Length(geom_segment IN mdsys.sdo_geometry,
                                unit         in varchar2 default null)
     RETURN NUMBER 
   As
   BEGIN
     Return &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment)
                .ST_Length(p_unit => unit);
   END Geom_Segment_Length;

   Function Offset_Geom_Segment(geom_segment  IN mdsys.sdo_geometry,
                                start_measure IN NUMBER,
                                end_measure   IN NUMBER,
                                offset        IN NUMBER   DEFAULT 0,
                                tolerance     IN NUMBER   DEFAULT 0.005,
                                unit          IN VARCHAR2 DEFAULT NULL)
     RETURN mdsys.sdo_geometry 
   As
   BEGIN
     Return &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment,nvl(tolerance,0.005))
                .ST_LRS_Locate_Measures(
                   p_start_measure => START_MEASURE,
                   p_end_measure   => END_MEASURE,
                   p_offset        => (0-NVL(offset,0)),
                   p_unit          => UNIT)
               .geom;
   END Offset_Geom_Segment;

   Function VALID_LRS_PT(point     IN mdsys.sdo_geometry,
                         dim_array IN mdsys.sdo_dim_ARRAY DEFAULT NULL) 
     RETURN VARCHAR2 
   AS
   BEGIN
     Return &&INSTALL_SCHEMA..T_GEOMETRY(point)
                .ST_LRS_Valid_Point(p_diminfo=>dim_array);
   END VALID_LRS_PT;
     
   Function VALID_MEASURE(geom_segment IN mdsys.sdo_geometry,
                          measure      IN NUMBER) 
     RETURN VARCHAR2 
   AS
   BEGIN
     Return &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment)
                .ST_LRS_Valid_Measure(p_measure => measure);
   END VALID_MEASURE;
  
   Function VALID_GEOM_SEGMENT(geom_segment IN mdsys.sdo_geometry, 
                               dim_array    IN mdsys.sdo_dim_ARRAY default null) 
     RETURN VARCHAR2 
   AS
   BEGIN
     Return &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment)
                .ST_LRS_Valid_Segment(p_diminfo=>dim_array);
   END VALID_GEOM_SEGMENT;

   Function VALIDATE_LRS_GEOMETRY(geom_segment IN mdsys.sdo_geometry,
                                  dim_array    IN mdsys.sdo_dim_ARRAY DEFAULT NULL)
     RETURN VARCHAR2 
   AS
     v_result varchar2(20);
   BEGIN
     v_result := substr(&&INSTALL_SCHEMA..T_GEOMETRY(geom_segment)
                        .ST_LRS_Valid_Geometry(p_diminfo => dim_array),1,20);
     IF ( v_result = 'TRUE' ) THEN 
       Return v_result;
     ELSIF ( substr(v_result,1,2) = '13' ) THEN
       raise_application_error(0-to_number(v_result),
                               case v_result 
                                    when '13331' then 'Invalid LRS segment'
                                    when '13335' then 'Measure information not defined'
                                    else 'Unknown error'
                                end 
                              );
     END IF;
     RETURN v_result;
   END VALIDATE_LRS_GEOMETRY;

   Function ROUND_COORDINATES(geom_segment   in mdsys.sdo_geometry,
                              p_dec_places_x in integer default null,
                              p_dec_places_y in integer default null,
                              p_dec_places_z in integer default null,
                              p_dec_places_m in integer default null)
	 RETURN MDSYS.SDO_GEOMETRY
   AS
   BEGIN
     RETURN &&INSTALL_SCHEMA..T_GEOMETRY(geom_segment)
	          .ST_Round(p_dec_places_x => p_dec_places_x,
                      p_dec_places_y => p_dec_places_y,
                      p_dec_places_z => p_dec_places_z,
                      p_dec_places_m => p_dec_places_m)
	          .geom;
   END ROUND_COORDINATES;

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
