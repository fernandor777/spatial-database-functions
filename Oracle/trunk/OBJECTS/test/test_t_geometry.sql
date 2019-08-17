create or replace package test_t_geometry
AUTHID DEFINER
as

  --%suite(T_Geometry Object Test Suite)

  --%test(Test ST_LRS_Dim)
  procedure test_dim;
  --%test(Test ST_LRS_IsMeasured)
  procedure test_is_measured;
  --%test(Test Measure Range)
  procedure test_measure_range;  
  --%test(Test Start Measure)
  Procedure test_start_measure;
  --%test(Test End Measure)
  Procedure test_end_measure;
  --%test(Test Is Measure Increasing)
  Procedure test_is_measure_increasing;
  --%test(Test Is Measure Decreasing)
  Procedure test_is_measure_decreasing;
  --%test(Test Measure_to_Percentage and Percentage_To_Measure)
  Procedure test_measure_percentage;
  --%test(Test Is Shape PT Measure)
  Procedure test_is_shape_pt_measure;
  --%test(Test Reset Measure)
  Procedure test_reset_measure;
  --%test(Test LRS Set Pt Measure)
  Procedure test_set_pt_measure;
  --%test(Test Convert To LRS Geom)
  Procedure test_convert_to_lrs_geom;
  --%test(Test Convert To Standard Geom)
  Procedure test_convert_to_std_geom;
  --%test(Test Revese Measure)
  Procedure test_reverse_measure;
  --%test(Test Reverse Geometry)
  Procedure test_reverse_geometry;
  --%test(Test Scale Segment)
  Procedure test_scale_geom_segment;
  --%test(Find Offset)
  Procedure test_find_offset;
  --%test(Find Measure)
  Procedure test_find_measure;
  --%test(Test Locate Pt)
  Procedure test_Locate_Pt;
  --%test(Test Clip geom Segment)
  Procedure test_clip_geom_segment;
  --%test(Test Dynamic Segment)
  Procedure test_dynamic_segment;
  --%test(Test Offset Geom Segment)
  Procedure test_offset_geom_segment;
  --%test(Test Project Point)
  Procedure test_Project_Pt; 
  --%test(Test Translate Segment)
  Procedure test_translate_segment;
  --%test(Test Split)
  Procedure test_split;
  --%test(Test Concatenate Line and Point)
  Procedure test_concatenate_pt_arg;
  --%test(Test Concatenate)
  Procedure test_concatenate;
  
  /**** IMPORT EXPORT *****/
  --%test(Test ST_AsEWKT)
  procedure test_asewkt;

end;
/
SHOW ERRORS

create or replace package body test_t_geometry as

  g_t_circular2D SPDBA.t_geometry := 
                 SPDBA.T_Geometry(
                   sdo_geometry(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(252230.478,5526918.373, 252400.08,5526918.373,252230.478,5527000.0)),
                   0.005,2,1
                 );
  g_t_geometry SPDBA.t_geometry := 
               SPDBA.T_Geometry(
                 SDO_GEOMETRY(3302,NULL,NULL,
                              SDO_ELEM_INFO_ARRAY(1,2,1), 
                              SDO_ORDINATE_ARRAY(
                                  2.0,2.0,0.0,
                                  2.0,4.0,3.218,
                                  8.0,4.0,12.872,
                                  12.0,4.0,19.308,
                                  12.0,10.0,28.962,
                                  8.0,10.0,35.398,
                                  5.0,14.0,43.443)),
                 0.005,2,1);
   g_t_geom2D SPDBA.t_geometry :=
            SPDBA.t_geometry(SDO_GEOMETRY(2002,NULL,NULL,
                         SDO_ELEM_INFO_ARRAY(1,2,1), 
                         SDO_ORDINATE_ARRAY(
                            2.0,2.0,
                            2.0,4.0,
                            8.0,4.0,
                            12.0,4.0,
                            12.0,10.0,
                            8.0,10.0,
                            5.0,14.0)),
                       0.005,2,1);
   g_sdo_point     mdsys.sdo_geometry := SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(10.719,8.644,NULL),NULL,NULL);
   g_sdo_point_3D  mdsys.sdo_geometry := SDO_GEOMETRY(3301,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,10,35.398));

  procedure test_dim
  As
    v_ST_LRS  pls_integer;
    v_SDO_LRS pls_integer;
  Begin
    v_ST_LRS  := g_t_geometry.ST_LRS_Dim(); 
    v_SDO_LRS := g_t_geometry.geom.get_lrs_dim();
    ut.expect( v_ST_LRS, 
               'Failed to compare g_t_geometry.ST_LRS_Dim() to g_t_geometry.geom.get_lrs_dim()' 
             ).to_equal(v_SDO_LRS);
  End;

  procedure test_is_measured
  As
    v_ST_LRS  pls_integer;
    v_SDO_LRS pls_integer;
  Begin
    v_ST_LRS := g_t_geometry.ST_LRS_isMeasured(); 
    v_SDO_LRS:= case when g_t_geometry.geom.get_lrs_dim()=0 then 0 else 1 end;
    ut.expect( v_ST_LRS, 
               'failed to compare g_t_geometry.ST_LRS_isMeasured() to case when g_t_geometry.geom.get_lrs_dim()=0 then 0 else 1 end' 
             ).to_equal(v_SDO_LRS);
  End test_is_measured;

  procedure test_measure_range
  As
    v_ST_LRS  number;
    v_SDO_LRS number;
  Begin
    v_ST_LRS := ST_LRS.MEASURE_RANGE(g_t_geometry.geom);
    v_SDO_LRS:= MDSYS.SDO_LRS.MEASURE_RANGE(g_t_geometry.geom);
    ut.expect( v_ST_LRS, 
               'ST_LRS.MEASURE_RANGE(g_t_geometry.geom) did not produce same output as MDSYS.SDO_LRS.MEASURE_RANGE(g_t_geometry.geom)'
              ).to_equal(v_SDO_LRS);
  End;

  Procedure test_start_measure
  As
    v_ST_LRS  number;
    v_SDO_LRS number;
  Begin
    v_ST_LRS := ST_LRS.GEOM_SEGMENT_START_MEASURE(g_t_geometry.geom);
    v_SDO_LRS:= MDSYS.SDO_LRS.GEOM_SEGMENT_START_MEASURE(g_t_geometry.geom);
    ut.expect( v_ST_LRS, 
               'ST_LRS.GEOM_SEGMENT_START_MEASURE(g_t_geometry.geom) did not produce same output as MDSYS.SDO_LRS.GEOM_SEGMENT_START_MEASURE(g_t_geometry.geom)'
              ).to_equal(v_SDO_LRS);
  End;

  Procedure test_end_measure
  As
    v_ST_LRS  number;
    v_SDO_LRS number;
  Begin
    v_ST_LRS := ST_LRS.GEOM_SEGMENT_END_MEASURE(g_t_geometry.geom);
    v_SDO_LRS:= MDSYS.SDO_LRS.GEOM_SEGMENT_END_MEASURE(g_t_geometry.geom);
    ut.expect( v_ST_LRS, 
               'ST_LRS.GEOM_SEGMENT_END_MEASURE(g_t_geometry.geom) did not produce same output as MDSYS.SDO_LRS.GEOM_SEGMENT_END_MEASURE(g_t_geometry.geom)'
              ).to_equal(v_SDO_LRS);
  End;

  Procedure test_is_measure_increasing
  As
    v_ST_LRS  varchar(100);
    v_SDO_LRS varchar(100);
  Begin
    v_ST_LRS := ST_LRS.IS_MEASURE_INCREASING(g_t_geometry.geom);
    v_SDO_LRS:= MDSYS.SDO_LRS.IS_MEASURE_INCREASING(g_t_geometry.geom);
    ut.expect( v_ST_LRS, 
               'ST_LRS.IS_MEASURE_INCREASING(g_t_geometry.geom) did not produce same output as MDSYS.SDO_LRS.IS_MEASURE_INCREASING(g_t_geometry.geom)'
              ).to_equal(v_SDO_LRS);
  End;

  Procedure test_is_measure_decreasing
  As
    v_ST_LRS  varchar(100);
    v_SDO_LRS varchar(100);
  Begin
    v_ST_LRS := ST_LRS.IS_MEASURE_DECREASING(g_t_geometry.geom);
    v_SDO_LRS:= MDSYS.SDO_LRS.IS_MEASURE_DECREASING(g_t_geometry.geom);
    ut.expect( v_ST_LRS, 
               'ST_LRS.IS_MEASURE_DECREASING(g_t_geometry.geom) did not produce same output as MDSYS.SDO_LRS.IS_MEASURE_DECREASING(g_t_geometry.geom)'
              ).to_equal(v_SDO_LRS);
  End;

  Procedure test_measure_percentage
  As
    v_ST_LRS  number;
    v_SDO_LRS number;
  Begin
    v_ST_LRS := ROUND(ST_LRS.MEASURE_TO_PERCENTAGE(g_t_geometry.geom,18),4);
    v_SDO_LRS:= ROUND(MDSYS.SDO_LRS.MEASURE_TO_PERCENTAGE(g_t_geometry.geom,18),4);
    dbms_output.put_line('     Test 1: Measure of 18 to Percentage SPDBA(' || v_st_lrs || ') SDO(' || v_sdo_lrs||')');
    ut.expect( v_ST_LRS, 
               'ST_LRS.MEASURE_TO_PERCENTAGE(g_t_geometry.geom,18) did not produce same output as MDSYS.SDO_LRS.MEASURE_TO_PERCENTAGE(g_t_geometry.geom,18)'
              ).to_equal(v_SDO_LRS);
    v_ST_LRS := ROUND(ST_LRS.PERCENTAGE_TO_MEASURE(g_t_geometry.geom,41.43),4);
    v_SDO_LRS:= ROUND(MDSYS.SDO_LRS.PERCENTAGE_TO_MEASURE(g_t_geometry.geom,41.43),4);
    dbms_output.put_line('     Test 2: Percentage of 41.43 to Measure SPDBA(' || v_st_lrs || ') SDO(' || v_sdo_lrs||')');
    ut.expect( v_ST_LRS, 
               'ST_LRS.PERCENTAGE_TO_MEASURE(g_t_geometry.geom,41.43) did not produce same output as MDSYS.SDO_LRS.PERCENTAGE_TO_MEASURE(g_t_geometry.geom,41.43)'
              ).to_equal(v_SDO_LRS);
  End;

  Procedure test_is_shape_pt_measure
  As
    v_ST_LRS  varchar(100);
    v_SDO_LRS varchar(100);
  Begin
    dbms_output.put_line('     Test 1: Measure of 28.962 SPDBA('||v_ST_LRS||') SDO('||v_SDO_LRS||')');
    v_ST_LRS := ST_LRS.IS_SHAPE_PT_MEASURE(g_t_geometry.geom,28.962);
    v_SDO_LRS:= MDSYS.SDO_LRS.IS_SHAPE_PT_MEASURE(g_t_geometry.geom,28.962);
    ut.expect( v_ST_LRS, 
               'ST_LRS.IS_SHAPE_PT_MEASURE(g_t_geometry.geom,28.962) did not produce same output as MDSYS.SDO_LRS.IS_SHAPE_PT_MEASURE(g_t_geometry.geom,28.962)'
              ).to_equal(v_SDO_LRS);

    dbms_output.put_line('     Test 2: Measure of 25 SPDBA('||v_ST_LRS||') SDO('||v_SDO_LRS||')');
    v_ST_LRS := ST_LRS.IS_SHAPE_PT_MEASURE(g_t_geometry.geom,25);
    v_SDO_LRS:= MDSYS.SDO_LRS.IS_SHAPE_PT_MEASURE(g_t_geometry.geom,25);
    ut.expect( v_ST_LRS, 
               'ST_LRS.IS_SHAPE_PT_MEASURE(g_t_geometry.geom,25) did not produce same output as MDSYS.SDO_LRS.IS_SHAPE_PT_MEASURE(g_t_geometry.geom,25)'
              ).to_equal(v_SDO_LRS);
  End;

  Procedure test_reset_measure
  As
    v_ST_LRS   SPDBA.t_geometry;
    v_SDO_LRS  SPDBA.t_geometry;
    v_sdo_geom sdo_geometry;
  Begin
    v_ST_LRS   := SPDBA.t_geometry(ST_LRS.RESET_MEASURE(g_t_geometry.geom),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    v_sdo_geom := g_t_geometry.geom;
    MDSYS.SDO_LRS.RESET_MEASURE(v_sdo_geom);
    v_SDO_LRS := SPDBA.t_geometry(v_sdo_geom,g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.RESET_MEASURE(g_t_geometry.geom) did not produce same output as MDSYS.SDO_LRS.RESET_MEASURE(g_t_geometry.geom)'
              ).to_equal('EQUAL');
    dbms_output.put_line('       ST=' ||  v_ST_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
    dbms_output.put_line('      SDO=' || v_SDO_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
  End;

  Procedure test_convert_to_lrs_geom
  As
    v_ST_LRS  SPDBA.t_geometry;
    v_SDO_LRS SPDBA.t_geometry;
  Begin
    -- Same as ST_LRS_ADD_MEASURE
    dbms_output.put_line('     Test 1: 2D Linestring');
    v_ST_LRS  := SPDBA.t_geometry(       ST_LRS.CONVERT_TO_LRS_GEOM(g_t_geom2D.geom,0,27),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    v_SDO_LRS := SPDBA.t_geometry(MDSYS.SDO_LRS.CONVERT_TO_LRS_GEOM(g_t_geom2D.geom,0,27),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.CONVERT_TO_LRS_GEOM(g_t_geom2D.geom) did not produce same output as MDSYS.SDO_LRS.CONVERT_TO_LRS_GEOM(g_t_geom2D.geom)'
              ).to_equal('EQUAL');

    dbms_output.put_line('     Test 2: 2D CircularString');          
    v_ST_LRS  := SPDBA.t_geometry(       ST_LRS.CONVERT_TO_LRS_GEOM(g_t_circular2D.geom,0,27),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    v_SDO_LRS := SPDBA.t_geometry(MDSYS.SDO_LRS.CONVERT_TO_LRS_GEOM(g_t_circular2D.geom,0,27),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.CONVERT_TO_LRS_GEOM(g_t_circular2D) did not produce same output as MDSYS.SDO_LRS.CONVERT_TO_LRS_GEOM(g_t_circular2D)'
              ).to_equal('EQUAL');
    dbms_output.put_line('       ST=' ||  v_ST_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
    dbms_output.put_line('      SDO=' || v_SDO_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
  End;

  Procedure test_convert_to_std_geom
  As
    v_ST_LRS  SPDBA.t_geometry;
    v_SDO_LRS SPDBA.t_geometry;
  Begin
    v_ST_LRS  := SPDBA.t_geometry(ST_LRS.CONVERT_TO_STD_GEOM(g_t_geometry.geom),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected)
                      .ST_Round(3,3,2,3);
    v_SDO_LRS := SPDBA.t_geometry(MDSYS.SDO_LRS.CONVERT_TO_STD_GEOM(g_t_geometry.geom),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected)
                      .ST_Round(3,3,2,3);
    ut.expect( v_ST_LRS.ST_Equals(v_SDO_LRS.geom),
               'ST_LRS.CONVERT_TO_STD_GEOM(g_t_geometry.geom) did not produce same output as MDSYS.SDO_LRS.CONVERT_TO_STD_GEOM(g_t_geometry.geom)'
              ).to_equal('EQUAL');
    dbms_output.put_line('       ST=' ||  v_ST_LRS.ST_AsEWKT());
    dbms_output.put_line('      SDO=' || v_SDO_LRS.ST_AsEWKT());
  End test_convert_to_std_geom;

  Procedure test_scale_geom_segment
  As
    v_ST_LRS  SPDBA.t_geometry;
    v_SDO_LRS SPDBA.t_geometry;
  Begin
    v_ST_LRS  := SPDBA.t_geometry(
                   ST_LRS.Scale_Geom_Segment(
                     lrs_segment  => g_t_geometry.geom,
                     start_measure=>100,
                     end_measure  =>200,
                     shift_measure=>10,
                     tolerance    =>g_t_geometry.tolerance),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    v_SDO_LRS := SPDBA.t_geometry(
                   MDSYS.SDO_LRS.SCALE_GEOM_SEGMENT(
                     geom_segment=>g_t_geometry.geom,
                     start_measure=>100,
                     end_measure=>200,
                     shift_measure=>10,
                     tolerance=>g_t_geometry.tolerance),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
           'ST_LRS.SCALE_GEOM_SEGMENT(g_t_geometry.geom) did not produce same output as MDSYS.SDO_LRS.SCALE_GEOM_SEGMENT(g_t_geometry.geom)'
              ).to_equal('EQUAL');
    dbms_output.put_line('       ST=' ||  v_ST_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
    dbms_output.put_line('      SDO=' || v_SDO_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
  End;

  Procedure test_set_pt_measure
  As
    v_ST_LRS   SPDBA.t_geometry;
    v_SDO_LRS  SPDBA.t_geometry;
    v_sdo_geom sdo_geometry;
    v_return   varchar2(4000);
  Begin
    -- set the measure value of the closest point (using snap_to_pt) in the given geometry
    v_ST_LRS  := SPDBA.t_geometry(       
                   ST_LRS.Set_Pt_Measure(
                     lrs_segment => g_t_geometry.geom,
                     point       => g_sdo_point_3D,
                     measure     => 35,
                     tolerance   => g_t_geometry.tolerance),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    v_sdo_geom := g_t_geometry.geom;
    v_return   := MDSYS.SDO_LRS.set_pt_measure (
                   geom_segment => v_sdo_geom,
                   point        => g_sdo_point_3D,
                   measure      => 35 
                 );
    v_SDO_LRS := SPDBA.t_geometry(v_sdo_geom,g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    dbms_output.put_line('     MDSYS.SDO_LRS.SET_PT_MEASURE returned ' || v_return);
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.Set_Pt_Measure() did not produce same output as MDSYS.SDO_LRS.Set_Pt_Measure()'
              ).to_equal('EQUAL');
    dbms_output.put_line('       ST=' ||  v_ST_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
    dbms_output.put_line('      SDO=' || v_SDO_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
  End;

  Procedure test_find_offset
  As
    v_st_offset  number;
    v_sdo_offset number;
  Begin
    v_st_offset  := ST_LRS.FIND_OFFSET (
                      GEOM_SEGMENT => g_t_geometry.geom,
                      POINT        => g_sdo_point,
                      TOLERANCE    => g_t_geometry.tolerance,
                      UNIT         => NULL
                    );
    v_sdo_offset := ST_LRS.FIND_OFFSET (
                      GEOM_SEGMENT => g_t_geometry.geom,
                      POINT        => g_sdo_point,
                      TOLERANCE    => g_t_geometry.tolerance,
                      UNIT         => NULL
                    );
    ut.expect( v_st_offset,
               'ST_LRS.FIND_OFFSET did not produce same output as MDSYS.SDO_LRS.FIND_OFFSET'
              ).to_equal(v_sdo_offset);
    dbms_output.put_line('       ST(' ||  v_st_offset ||') = SDO(' || v_sdo_offset||')');
  End test_find_offset;

  Procedure test_find_measure
  As
    v_st_measure  number;
    v_sdo_measure number;
  Begin
    v_st_measure := ST_LRS.FIND_MEASURE (
                      LRS_SEGMENT => g_t_geometry.geom,
                      POINT       => g_sdo_point,
                      TOLERANCE   => g_t_geometry.tolerance,
                      UNIT        => NULL);
    v_sdo_measure := ST_LRS.FIND_MEASURE (
                      LRS_SEGMENT => g_t_geometry.geom,
                      POINT       => g_sdo_point,
                      TOLERANCE   => g_t_geometry.tolerance,
                      UNIT        => NULL);
    ut.expect( v_st_measure,
               'ST_LRS.FIND_MEASURE did not produce same output as MDSYS.SDO_LRS.FIND_MEASURE'
              ).to_equal(v_sdo_measure);
    dbms_output.put_line('       ST(' ||  v_st_measure ||') = SDO(' || v_sdo_measure||')');
  End test_find_measure;

  Procedure test_Locate_Pt
  As
    v_ST_LRS  SPDBA.t_geometry;
    v_SDO_LRS SPDBA.t_geometry;
  Begin
    -- Same as SELF.ST_LRS_Locate_Point
    v_ST_LRS  := SPDBA.t_geometry(
                   ST_LRS.LOCATE_PT(
                     geom_segment => g_t_geometry.geom,
                     measure      => 5,
                     offset       => 0,
                     tolerance    => g_t_geometry.tolerance,
                     unit         => NULL),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    v_SDO_LRS := SPDBA.t_geometry(
                   MDSYS.SDO_LRS.LOCATE_PT(
                     geom_segment=>g_t_geometry.geom,
                     measure     =>5,
                     offset      =>0,
                     tolerance   =>g_t_geometry.tolerance),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.LOCATE_PT(g_t_geometry.geom) did not produce same output as MDSYS.SDO_LRS.LOCATE_PT(g_t_geometry.geom)'
              ).to_equal('EQUAL');
    dbms_output.put_line('       ST=' ||  v_ST_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
    dbms_output.put_line('      SDO=' || v_SDO_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
  End;

  Procedure test_reverse_measure
  As
    v_ST_LRS  SPDBA.t_geometry;
    v_SDO_LRS SPDBA.t_geometry;
  Begin                              
    -- Same as SELF.ST_LRS_Reverse_Measure
    v_ST_LRS  := SPDBA.t_geometry(       ST_LRS.REVERSE_MEASURE(g_t_geometry.geom),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    v_SDO_LRS := SPDBA.t_geometry(MDSYS.SDO_LRS.REVERSE_MEASURE(g_t_geometry.geom),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.REVERSE_MEASURE() did not produce same output as MDSYS.SDO_LRS.REVERSE_MEASURE()'
              ).to_equal('EQUAL');
    dbms_output.put_line('       ST=' ||  v_ST_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
    dbms_output.put_line('      SDO=' || v_SDO_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
  End test_reverse_measure;

  Procedure test_reverse_geometry
  As
    v_ST_LRS  SPDBA.t_geometry;
    v_SDO_LRS SPDBA.t_geometry;
  Begin                              
    -- Same as SELF.ST_LRS_Reverse_Measure
    v_ST_LRS  := SPDBA.t_geometry(       ST_LRS.REVERSE_GEOMETRY(g_t_geometry.geom),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected)
                      .ST_Round(3,3,2,3);
    v_SDO_LRS := SPDBA.t_geometry(MDSYS.SDO_LRS.REVERSE_GEOMETRY(g_t_geometry.geom),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected)
                       .ST_Round(3,3,2,3);
    ut.expect( v_ST_LRS.ST_Equals(v_SDO_LRS.geom),
               'ST_LRS.REVERSE_GEOMETRY() did not produce same output as MDSYS.SDO_LRS.REVERSE_GEOMETRY()'
              ).to_equal('EQUAL');
    dbms_output.put_line('       ST=' ||  v_ST_LRS.ST_AsEWKT());
    dbms_output.put_line('      SDO=' || v_SDO_LRS.ST_AsEWKT());
  End test_reverse_geometry;

  Procedure test_clip_geom_segment
  As
    v_ST_LRS  SPDBA.t_geometry;
    v_SDO_LRS SPDBA.t_geometry;
  Begin                              
    -- Otherwise SPDBA.t_geometry.ST_LRS_Locate_Measures()
    v_ST_LRS  := SPDBA.t_geometry(
                   ST_LRS.CLIP_GEOM_SEGMENT(
                     geom_segment => g_t_geometry.geom,
                     start_measure=> 5,
                     end_measure  => 10,
                     tolerance    => g_t_geometry.tolerance),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    v_SDO_LRS := SPDBA.t_geometry(
                   MDSYS.SDO_LRS.CLIP_GEOM_SEGMENT(
                     geom_segment => g_t_geometry.geom,
                     start_measure=> 5,
                     end_measure  => 10,
                     tolerance    => g_t_geometry.tolerance),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.CLIP_GEOM_SEGMENT(g_t_geometry.geom) did not produce same output as MDSYS.SDO_LRS.CLIP_GEOM_SEGMENT(g_t_geometry.geom)'
              ).to_equal('EQUAL');
    dbms_output.put_line('       ST=' ||  v_ST_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
    dbms_output.put_line('      SDO=' || v_SDO_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
  End test_clip_geom_segment;

  Procedure test_dynamic_segment
  As
    v_ST_LRS  SPDBA.t_geometry;
    v_SDO_LRS SPDBA.t_geometry;
  Begin                              
    -- Same as SELF.ST_LRS_Locate_Measures(with offset)
    dbms_output.put_line('     Test 1: 5-10');
    v_ST_LRS  := SPDBA.t_geometry(
                   ST_LRS.DYNAMIC_SEGMENT(
                     geom_segment => g_t_geometry.geom,
                     start_measure=> 5,
                     end_measure  => 10,
                     tolerance    => g_t_geometry.tolerance,
                     unit         => NULL),
                   g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected)
                   .ST_Round(3,3,2,3);
    v_SDO_LRS := SPDBA.t_geometry(
                   MDSYS.SDO_LRS.DYNAMIC_SEGMENT(
                    geom_segment => g_t_geometry.geom,
                    start_measure=> 5,
                    end_measure  => 10,
                    tolerance    => g_t_geometry.tolerance),
                   g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected)
                   .ST_Round(3,3,2,3);
    ut.expect( v_ST_LRS.ST_Equals(v_SDO_LRS.geom),
               'ST_LRS.DYNAMIC_SEGMENT(5,10,2) did not produce same output as MDSYS.SDO_LRS.DYNAMIC_SEGMENT(5,10,2)'
              ).to_equal('EQUAL');
    dbms_output.put_line('       ST=' ||  v_ST_LRS.ST_AsEWKT());
    dbms_output.put_line('      SDO=' || v_SDO_LRS.ST_AsEWKT());
  End test_dynamic_segment;

  Procedure test_offset_geom_segment
  As
    v_ST_LRS  SPDBA.t_geometry;
    v_SDO_LRS SPDBA.t_geometry;
  Begin                              
    -- Same as SELF.ST_LRS_Locate_Measures(with offset)
    dbms_output.put_line('     Test 1: 5-10 with 2.0 offset');
    v_ST_LRS  := SPDBA.t_geometry(
                   ST_LRS.OFFSET_GEOM_SEGMENT(
                     geom_segment => g_t_geometry.geom,
                     start_measure=> 5,
                     end_measure  => 10,
                     offset       => 2.0,
                     tolerance    => g_t_geometry.tolerance,
                     unit         => NULL),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    v_SDO_LRS := SPDBA.t_geometry(
                   MDSYS.SDO_LRS.OFFSET_GEOM_SEGMENT(
                    geom_segment => g_t_geometry.geom,
                    start_measure=> 5,
                    end_measure  => 10,
                    offset       => 2.0,
                    tolerance    => g_t_geometry.tolerance),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.OFFSET_GEOM_SEGMENT(5,10,2) did not produce same output as MDSYS.SDO_LRS.OFFSET_GEOM_SEGMENT(5,10,2)'
              ).to_equal('EQUAL');
    dbms_output.put_line('       ST=' ||  v_ST_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
    dbms_output.put_line('      SDO=' || v_SDO_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
              
    dbms_output.put_line('     Test 2: 5-20 with 2.0 offset');
    v_ST_LRS  := SPDBA.t_geometry(
                   ST_LRS.OFFSET_GEOM_SEGMENT(
                     geom_segment => g_t_geometry.geom,
                     start_measure=> 5,
                     end_measure  => 20,
                     offset       => 2.0,
                     tolerance    => g_t_geometry.tolerance,
                     unit         => NULL),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    v_SDO_LRS := SPDBA.t_geometry(
                   MDSYS.SDO_LRS.OFFSET_GEOM_SEGMENT(
                     geom_segment => g_t_geometry.geom,
                     start_measure=> 5,
                     end_measure  => 20,
                     offset       => 2.0,
                     tolerance    => g_t_geometry.tolerance),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.OFFSET_GEOM_SEGMENT(5,10,2) did not produce same output as MDSYS.SDO_LRS.OFFSET_GEOM_SEGMENT(5,10,2)'
              ).to_equal('EQUAL');
    dbms_output.put_line('       ST=' ||  v_ST_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
    dbms_output.put_line('      SDO=' || v_SDO_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
    
  End;

  Procedure test_Project_Pt
  As
    v_ST_LRS  SPDBA.t_geometry;
    v_SDO_LRS SPDBA.t_geometry;
  Begin                              
    -- Same as SELF.ST_LRS_Project_Point
    v_ST_LRS  := SPDBA.t_geometry(
                   ST_LRS.PROJECT_PT(
                      geom_segment => g_t_geometry.geom,
                      point        => g_sdo_point,
                      tolerance    => g_t_geometry.tolerance,
                      unit         => NULL
                   ),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected)
                  .ST_SdoPoint2Ord();
    v_SDO_LRS := SPDBA.t_geometry(
                   MDSYS.SDO_LRS.PROJECT_PT(
                     geom_segment => g_t_geometry.geom,
                     point        => g_sdo_point,
                     tolerance    => g_t_geometry.tolerance),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.PROJECT_PT() did not produce same output as MDSYS.SDO_LRS.PROJECT_PT()'
              ).to_equal('EQUAL');
    dbms_output.put_line('       ST=' ||  v_ST_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
    dbms_output.put_line('      SDO=' || v_SDO_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
  End;

  Procedure test_translate_segment
  As
    v_ST_LRS  SPDBA.t_geometry;
    v_SDO_LRS SPDBA.t_geometry;
  Begin
    v_ST_LRS  := SPDBA.t_geometry(
                   ST_LRS.TRANSLATE_MEASURE(
                     geom_segment => g_t_geometry.geom,
                     translate_m  => 10),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    v_SDO_LRS := SPDBA.t_geometry(
                   MDSYS.SDO_LRS.TRANSLATE_MEASURE(
                     geom_segment => g_t_geometry.geom,
                     translate_m  => 10),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.TRANSLATE_MEASURE() did not produce same output as MDSYS.SDO_LRS.TRANSLATE_MEASURE()'
              ).to_equal('EQUAL');
    dbms_output.put_line('       ST=' ||  v_ST_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
    dbms_output.put_line('      SDO=' || v_SDO_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
  End;

  Procedure test_split
  As
    v_ST_LRS_1  sdo_geometry;
    v_ST_LRS_2  sdo_geometry;
    v_SDO_LRS_1 sdo_geometry;
    v_SDO_LRS_2 sdo_geometry;
    v_ST_LRS    SPDBA.t_geometry;
    v_SDO_LRS   SPDBA.t_geometry;
  Begin
    ST_LRS.SPLIT_GEOM_SEGMENT(
       geom_segment => g_t_geometry.geom,
       split_measure=> 5,
       segment_1    => v_ST_LRS_1,
       segment_2    => v_ST_LRS_2,
       tolerance    => g_t_geometry.tolerance);
    MDSYS.SDO_LRS.split_geom_segment(
       geom_segment => g_t_geometry.geom,
       split_measure=> 5,
       segment_1    => v_SDO_LRS_1,
       segment_2    => v_SDO_LRS_2,
       tolerance    => g_t_geometry.tolerance);
    v_ST_LRS  := SPDBA.t_geometry( v_ST_LRS_1,g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    v_SDO_LRS := SPDBA.t_geometry(v_SDO_LRS_1,g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.SPLIT_GEOM_SEGMENT(segment_1) did not produce same output as MDSYS.SDO_LRS.SPLIT_GEOM_SEGMENT(segment_1)'
              ).to_equal('EQUAL');

    v_ST_LRS  := SPDBA.t_geometry( v_ST_LRS_2,g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    v_SDO_LRS := SPDBA.t_geometry(v_SDO_LRS_2,g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.SPLIT_GEOM_SEGMENT(segment_2) did not produce same output as MDSYS.SDO_LRS.SPLIT_GEOM_SEGMENT(segment_2)'
              ).to_equal('EQUAL');
  End;

  Procedure test_concatenate_pt_arg
  As
    c_i_point_not_line CONSTANT pls_integer := -20121;
    point_not_line     EXCEPTION;
    PRAGMA             EXCEPTION_INIT(point_not_line,-20121);
    v_geom             T_Geometry;
  Begin
    BEGIN
      v_geom := SPDBA.t_geometry( 
                  ST_LRS.CONCATENATE_GEOM_SEGMENTS(g_t_geometry.geom,g_sdo_point,g_t_geometry.Tolerance),
                  g_t_geometry.tolerance,
                  g_t_geometry.dPrecision,
                  g_t_geometry.projected
                );
      dbms_output.put_line('      v_geom=' || v_geom.ST_AsEWKT());
      EXCEPTION
         WHEN point_not_line THEN
           dbms_output.put_line('      SQLERRM=' || SUBSTR(SQLERRM,12,100));
           ut.expect(SQLCODE,SQLERRM).to_equal(c_i_point_not_line);
    END;
  End test_concatenate_pt_arg;
  
  Procedure test_concatenate
  As
    v_ST_LRS_1  sdo_geometry;
    v_ST_LRS_2  sdo_geometry;
    v_SDO_LRS_1 sdo_geometry;
    v_SDO_LRS_2 sdo_geometry;

    v_ST_LRS    SPDBA.t_geometry;
    v_SDO_LRS   SPDBA.t_geometry;
  Begin
    -- Retrieve segments for concatenation.
    ST_LRS.SPLIT_GEOM_SEGMENT(
       geom_segment => g_t_geometry.geom,
       split_measure=> 5,
       segment_1    => v_ST_LRS_1,
       segment_2    => v_ST_LRS_2,
       tolerance    => g_t_geometry.tolerance
    );
    dbms_output.put_line(DEBUG.PRINTGEOM(v_st_lrs_1,1,0,'v_st_lrs_1=',0));
    dbms_output.put_line(DEBUG.PRINTGEOM(v_st_lrs_2,1,0,'v_st_lrs_2=',0));    
    MDSYS.SDO_LRS.SPLIT_GEOM_SEGMENT(
       geom_segment => g_t_geometry.geom,
       split_measure=> 5,
       segment_1    => v_SDO_LRS_1,
       segment_2    => v_SDO_LRS_2,
       tolerance    => g_t_geometry.tolerance
    );
    dbms_output.put_line(DEBUG.PRINTGEOM(v_sdo_lrs_1,1,0,'v_sdo_lrs_1=',0));
    dbms_output.put_line(DEBUG.PRINTGEOM(v_sdo_lrs_2,1,0,'v_sdo_lrs_2=',0));    
    -- Now concatenate
    v_ST_LRS  := SPDBA.t_geometry(
                   ST_LRS.CONCATENATE_GEOM_SEGMENTS(
                     geom_segment_1 => v_ST_LRS_1,
                     geom_segment_2 => v_ST_LRS_2,
                     tolerance      => g_t_geometry.tolerance,
                     unit           => NULL),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    v_SDO_LRS := SPDBA.t_geometry(
                   MDSYS.SDO_LRS.CONCATENATE_GEOM_SEGMENTS(
                     geom_segment_1 => v_SDO_LRS_1,
                     geom_segment_2 => v_SDO_LRS_2,
                     tolerance      => g_t_geometry.tolerance),g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.CONCATENATE_GEOM_SEGMENTS() did not produce same output as MDSYS.SDO_LRS.CONCATENATE_GEOM_SEGMENTS()'
              ).to_equal('EQUAL');
    dbms_output.put_line('       ST=' ||  v_ST_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
    dbms_output.put_line('      SDO=' || v_SDO_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
  End;

  Procedure test_intersection
  As
  Begin
    NULL;
  End;

  procedure test_asewkt
  As
    v_ST_GEOM   VARCHAR(32000);
    v_ewkt_geom SPDBA.t_geometry;
  Begin
    v_ST_GEOM  := dbms_lob.substr( g_t_geometry.ST_Round(3,3,2,3).ST_AsEWKT(), 500, 1);
    ut.expect( v_st_geom,
               'v_ewkt OK'
              ).to_equal(V_ST_GEOM);
    dbms_output.put_line('       ST_AsEWKT=' || v_ST_GEOM);
  End test_asewkt;
  
  Procedure test_from_ewkt
  As
  Begin
  End;
  
end test_t_geometry;
/
SHOW ERRORS

set serveroutput on size unlimited
set long 800
set linesize 800
begin ut.run('test_t_geometry'); end;

Test:

1. Constructors.
2. ST_Release
ST_SetProjection
ST_SetSdoGtype
ST_SetSrid
ST_SetPrecision
ST_SetTolerance
Nothing till...
ST_AsEWKT
ST_isEmpty
ST_isClosed
ST_NumSegments
ST_Dimension
ST_hasDimension


'<gml:Polygon srsName="SDO:" xmlns:gml="http://www.opengis.net/gml"><gml:exterior><gml:LinearRing><gml:posList srsDimension="2">5.0 1.0 8.0 1.0 8.0 6.0 5.0 7.0 5.0 1.0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>'
'<gml:Polygon srsName="SDO:" xmlns:gml="http://www.opengis.net/gml"><gml:outerBoundaryIs><gml:LinearRing><gml:coordinates decimal="." cs="," ts=" ">5.0,1.0 8.0,1.0 8.0,6.0 5.0,7.0 5.0,1.0</gml:coordinates></gml:LinearRing></gml:outerBoundaryIs></gml:Polygon>'

'POINTZ (-123.08963356 49.27575579 70)'
select spdba.t_geometry(TO_CLOB('POINTZ (-123.08963356 49.27575579 70)')).geom from dual;
'SRID=28355;POINTZ (-123.08963356 49.27575579 70)'
select spdba.t_geometry(TO_CLOB('SRID=28355;POINTZ (-123.08963356 49.27575579 70)')).geom from dual;

'LINESTRING (1 1,2 1,3 1)'
'LINESTRING M (1 1 20,2 1 30,3 1 40)'
'LINESTRING Z (1 1 20,2 1 30,3 1 40)'
'LINESTRING ZM (1 1 20 0,2 1 30 10,3 1 40 20)'
'POLYGON Z ((0 0 10,0 1 20,1 1 30,1 0 40,0 0 10))'
'SRID=8307;LINESTRING Z ((0 0 10,0 1 20,1 1 30,1 0 40))'
'SRID=8307;POLYGON Z ((0 0 10,0 1 20,1 1 30,1 0 40,0 0 10))'
SDO_GEOMETRY(2001,28355,sdo_point_type(1,1,NULL),NULL,NULL)
SDO_GEOMETRY(2001, 8307,sdo_point_type(147.5,-32.7,NULL),NULL,NULL)
SDO_GEOMETRY(2001, NULL,sdo_point_type(147.5,-32.7,NULL),NULL,NULL)
SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1,1,2,1,3,1))
SDO_GEOMETRY(3001,28355,sdo_point_type(1,1,1),NULL,NULL)
SDO_GEOMETRY(3001, NULL,sdo_point_type(1,1,1),NULL,NULL)
SDO_GEOMETRY(3003, 8307,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,10,1,0,40,1,1,30,0,1,20,0,0,10))

