/*
test_st_lrs_package tests the ST_LRS package which also tests the underlying T_GEOMETRY ST_LRS_* methods
*/

create or replace package test_st_lrs_package
AUTHID DEFINER
as

   --%suite(ST_LRS Package Test Suite)

   --%test(Test ST_LRS.Dim)
   PROCEDURE st_lrs_dim;
   --%test(ST_LRS.IsMeasured)
   PROCEDURE st_lrs_ismeasured;   
   --%test(Test ST_LRS.Get_Measure)
   PROCEDURE st_lrs_get_measure;
   --%test(Test ST_LRS.Start_Measure)
   PROCEDURE st_lrs_start_measure;
   --%test(Test ST_LRS.End_Measure)
   PROCEDURE st_lrs_end_measure;
   --%test(Test ST_LRS.Measure_Range)
   PROCEDURE st_lrs_measure_range;
   --%test(Test ST_LRS.Is_Measure_Decreasing)
   PROCEDURE st_lrs_is_measure_decreasing;
   --%test(Test ST_LRS.Is_Measure_Increasing)
   PROCEDURE st_lrs_is_measure_increasing;
   --%test(Test ST_LRS.Measure_To_Percentage)
   PROCEDURE st_lrs_measure_to_percentage;
   --%test(Test ST_LRS.Percentage_To_Measure)
   PROCEDURE st_lrs_percentage_to_measure;
   --%Test(Test ST_LRS.set_pt_measure)
   PROCEDURE st_lrs_set_pt_measure;
   --%test(Test ST_LRS.is_Shape_PT_Measure)
   PROCEDURE st_lrs_is_shape_pt_measure;
   --%Test(Test ST_LRS.convert_to_lrs_geom)
   PROCEDURE st_lrs_convert_to_lrs_geom;
   --%Test(Test ST_LRS.convert_to_std_geom)
   PROCEDURE st_lrs_convert_to_std_geom;
   --%Test(Test ST_LRS.reset_measure)
   PROCEDURE st_lrs_reset_measure;
   --%Test(Test ST_LRS.reverse_measure)
   PROCEDURE st_lrs_reverse_measure;
   --%Test(Test ST_LRS.reverse_geometry)
   PROCEDURE st_lrs_reverse_geometry;
   --%Test(Test ST_LRS.scale_geom_segment)
    PROCEDURE st_lrs_scale_geom_segment;
   --%test(Test ST_LRS.find_offset)
   PROCEDURE st_lrs_find_offset;
   --%test(Test ST_LRS.find_measure)
   PROCEDURE st_lrs_find_measure;
   --%Test(Test ST_LRS.Locate_Pt)
   PROCEDURE st_lrs_Locate_Pt;
   --%Test(Test ST_LRS.clip_geom_segment)
   PROCEDURE st_lrs_clip_geom_segment;
   --%Test(Test ST_LRS.dynamic_segment)
   PROCEDURE st_lrs_dynamic_segment;
   --%Test(Test ST_LRS.offset_geom_segment)
   PROCEDURE st_lrs_offset_geom_segment;
   --%Test(Test ST_LRS.Project_Pt)
   PROCEDURE st_lrs_Project_Pt; 
   --%Test(Test ST_LRS.translate_segment)
   PROCEDURE st_lrs_translate_segment;
   --%Test(Test ST_LRS.concatenate_pt_arg)
   PROCEDURE st_lrs_concatenate_pt_arg;
   --%Test(Test ST_LRS.concatenate)
   PROCEDURE st_lrs_concatenate;
   --%Test(Test ST_LRS.split)
   PROCEDURE st_lrs_split;

end test_st_lrs_package;
/
SHOW ERRORS

create or replace package body test_st_lrs_package
as

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

  g_t_append_geom SPDBA.t_geometry := 
               SPDBA.T_Geometry(
                 SDO_GEOMETRY(3302,NULL,NULL,
                              SDO_ELEM_INFO_ARRAY(1,2,1), 
                              SDO_ORDINATE_ARRAY(
                                  5.0,14.0,43.443,
                                  5.0,15.0,54.3)),
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

  PROCEDURE st_lrs_dim
  As
    v_ST_LRS  pls_integer;
    v_SDO_LRS pls_integer;
  Begin
    v_ST_LRS  := g_t_geometry.ST_LRS_Dim(); 
    v_SDO_LRS := g_t_geometry.geom.get_lrs_dim();
    ut.expect( v_ST_LRS, 
               'Failed to compare g_t_geometry.ST_LRS_Dim() to g_t_geometry.geom.get_lrs_dim()' 
             ).to_equal(v_SDO_LRS);
  End st_lrs_dim;

  PROCEDURE ST_LRS_IsMeasured
  As
    v_ST_LRS  pls_integer;
    v_SDO_LRS pls_integer;
  Begin
    v_ST_LRS := g_t_geometry.ST_LRS_isMeasured(); 
    v_SDO_LRS:= case when g_t_geometry.geom.get_lrs_dim()=0 then 0 else 1 end;
    ut.expect( v_ST_LRS, 
               'failed to compare g_t_geometry.ST_LRS_isMeasured() to case when g_t_geometry.geom.get_lrs_dim()=0 then 0 else 1 end' 
             ).to_equal(v_SDO_LRS);
  End ST_LRS_IsMeasured;

   PROCEDURE st_lrs_get_measure
   As
   Begin
     NULL;
   End st_lrs_get_measure;

   PROCEDURE st_lrs_start_measure
   As
     v_ST_LRS  number;
     v_SDO_LRS number;
   Begin
     v_ST_LRS := ST_LRS.GEOM_SEGMENT_START_MEASURE(g_t_geometry.geom);
     v_SDO_LRS:= MDSYS.SDO_LRS.GEOM_SEGMENT_START_MEASURE(g_t_geometry.geom);
     ut.expect( v_ST_LRS, 
                'ST_LRS.GEOM_SEGMENT_START_MEASURE(g_t_geometry.geom) did not produce same output as MDSYS.SDO_LRS.GEOM_SEGMENT_START_MEASURE(g_t_geometry.geom)'
               ).to_equal(v_SDO_LRS);
   End ST_LRS_start_measure;

   Procedure st_lrs_end_measure
   As
     v_ST_LRS  number;
     v_SDO_LRS number;
   Begin
     v_ST_LRS := ST_LRS.GEOM_SEGMENT_END_MEASURE(g_t_geometry.geom);
     v_SDO_LRS:= MDSYS.SDO_LRS.GEOM_SEGMENT_END_MEASURE(g_t_geometry.geom);
     ut.expect( v_ST_LRS, 
                'ST_LRS.GEOM_SEGMENT_END_MEASURE(g_t_geometry.geom) did not produce same output as MDSYS.SDO_LRS.GEOM_SEGMENT_END_MEASURE(g_t_geometry.geom)'
                ).to_equal(v_SDO_LRS);
   End st_lrs_end_measure;

   PROCEDURE st_lrs_measure_range
   As
     v_ST_LRS  number;
     v_SDO_LRS number;
   Begin
     v_ST_LRS := ST_LRS.MEASURE_RANGE(g_t_geometry.geom);
     v_SDO_LRS:= MDSYS.SDO_LRS.MEASURE_RANGE(g_t_geometry.geom);
     ut.expect( v_ST_LRS, 
                'ST_LRS.MEASURE_RANGE(g_t_geometry.geom) did not produce same output as MDSYS.SDO_LRS.MEASURE_RANGE(g_t_geometry.geom)'
               ).to_equal(v_SDO_LRS);
   End st_lrs_measure_range;

  Procedure st_lrs_is_measure_increasing
  As
    v_ST_LRS  varchar(100);
    v_SDO_LRS varchar(100);
  Begin
    v_ST_LRS := ST_LRS.IS_MEASURE_INCREASING(g_t_geometry.geom);
    v_SDO_LRS:= MDSYS.SDO_LRS.IS_MEASURE_INCREASING(g_t_geometry.geom);
    ut.expect( v_ST_LRS, 
               'ST_LRS.IS_MEASURE_INCREASING(g_t_geometry.geom) did not produce same output as MDSYS.SDO_LRS.IS_MEASURE_INCREASING(g_t_geometry.geom)'
              ).to_equal(v_SDO_LRS);
  End st_lrs_is_measure_increasing;

  Procedure st_lrs_is_measure_decreasing
  As
    v_ST_LRS  varchar(100);
    v_SDO_LRS varchar(100);
  Begin
    v_ST_LRS := ST_LRS.IS_MEASURE_DECREASING(g_t_geometry.geom);
    v_SDO_LRS:= MDSYS.SDO_LRS.IS_MEASURE_DECREASING(g_t_geometry.geom);
    ut.expect( v_ST_LRS, 
               'ST_LRS.IS_MEASURE_DECREASING(g_t_geometry.geom) did not produce same output as MDSYS.SDO_LRS.IS_MEASURE_DECREASING(g_t_geometry.geom)'
              ).to_equal(v_SDO_LRS);
  End st_lrs_is_measure_decreasing;

  Procedure st_lrs_measure_to_percentage
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
  End st_lrs_measure_to_percentage;

  Procedure st_lrs_percentage_to_measure
  As
    v_ST_LRS  number;
    v_SDO_LRS number;
  Begin
    v_ST_LRS := ROUND(ST_LRS.PERCENTAGE_TO_MEASURE(g_t_geometry.geom,41.43),4);
    v_SDO_LRS:= ROUND(MDSYS.SDO_LRS.PERCENTAGE_TO_MEASURE(g_t_geometry.geom,41.43),4);
    dbms_output.put_line('     Test 2: Percentage of 41.43 to Measure SPDBA(' || v_st_lrs || ') SDO(' || v_sdo_lrs||')');
    ut.expect( v_ST_LRS, 
               'ST_LRS.PERCENTAGE_TO_MEASURE(g_t_geometry.geom,41.43) did not produce same output as MDSYS.SDO_LRS.PERCENTAGE_TO_MEASURE(g_t_geometry.geom,41.43)'
              ).to_equal(v_SDO_LRS);
  End st_lrs_percentage_to_measure;

  Procedure st_lrs_is_shape_pt_measure
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
  End st_lrs_is_shape_pt_measure;

  PROCEDURE st_lrs_convert_to_lrs_geom
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
  End st_lrs_convert_to_lrs_geom;

  PROCEDURE st_lrs_convert_to_std_geom
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
  End st_lrs_convert_to_std_geom;

  Procedure st_lrs_reset_measure
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
  End st_lrs_reset_measure;

  PROCEDURE st_lrs_scale_geom_segment
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

  PROCEDURE st_lrs_set_pt_measure
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
  End st_lrs_set_pt_measure;

  PROCEDURE st_lrs_find_offset
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
  End st_lrs_find_offset;

  PROCEDURE st_lrs_find_measure
  As
    v_st_measure  number;
    v_sdo_measure number;
  Begin
    v_st_measure := ROUND(ST_LRS.FIND_MEASURE (
                             LRS_SEGMENT => g_t_geometry.geom,
                             POINT       => g_sdo_point,
                             TOLERANCE   => g_t_geometry.tolerance,
                             UNIT        => NULL),
                         3);
    v_sdo_measure := ROUND(ST_LRS.FIND_MEASURE (
                              LRS_SEGMENT => g_t_geometry.geom,
                              POINT       => g_sdo_point,
                              TOLERANCE   => g_t_geometry.tolerance,
                              UNIT        => NULL),
                           3);
    ut.expect( v_st_measure,
               'ST_LRS.FIND_MEASURE did not produce same output as MDSYS.SDO_LRS.FIND_MEASURE'
              ).to_equal(v_sdo_measure);
    dbms_output.put_line('       ST(' ||  v_st_measure ||') = SDO(' || v_sdo_measure||')');
  End st_lrs_find_measure;

  PROCEDURE st_lrs_Locate_Pt
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
  End st_lrs_Locate_Pt;

  PROCEDURE st_lrs_reverse_measure
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
  End st_lrs_reverse_measure;

  PROCEDURE st_lrs_reverse_geometry
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
  End st_lrs_reverse_geometry;

  PROCEDURE st_lrs_clip_geom_segment
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
  End st_lrs_clip_geom_segment;

  PROCEDURE st_lrs_dynamic_segment
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
  End st_lrs_dynamic_segment;

  PROCEDURE st_lrs_offset_geom_segment
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
                     unit         => NULL),
                   g_t_geometry.tolerance,
                   g_t_geometry.dPrecision,
                   g_t_geometry.projected);
    v_SDO_LRS := SPDBA.t_geometry(
                   MDSYS.SDO_LRS.OFFSET_GEOM_SEGMENT(
                    geom_segment => g_t_geometry.geom,
                    start_measure=> 5,
                    end_measure  => 10,
                    offset       => 2.0,
                    tolerance    => g_t_geometry.tolerance),
                   g_t_geometry.tolerance,
                   g_t_geometry.dPrecision,
                   g_t_geometry.projected);
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

  End st_lrs_offset_geom_segment;

  PROCEDURE st_lrs_Project_Pt
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
                     tolerance    => g_t_geometry.tolerance),
                     g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected);
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.PROJECT_PT() did not produce same output as MDSYS.SDO_LRS.PROJECT_PT()'
              ).to_equal('EQUAL');
    dbms_output.put_line('       ST(3302)=' ||  v_ST_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
    dbms_output.put_line('      SDO(2001)=' || v_SDO_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
    
    -- 2D Same as SELF.ST_LRS_Project_Point
    v_ST_LRS  := SPDBA.t_geometry(
                   ST_LRS.PROJECT_PT(
                      geom_segment => ST_LRS.CONVERT_TO_LRS_GEOM(g_t_geom2D.geom,0,g_t_geometry.ST_Length()),
                      point        => g_sdo_point,
                      tolerance    => g_t_geometry.tolerance,
                      unit         => NULL
                   ),g_t_geom2D.tolerance,g_t_geom2D.dPrecision,g_t_geom2D.projected)
                  .ST_SdoPoint2Ord();
    v_SDO_LRS := SPDBA.t_geometry(
                   MDSYS.SDO_LRS.PROJECT_PT(
                     geom_segment => MDSYS.SDO_LRS.CONVERT_TO_LRS_GEOM(g_t_geom2D.geom,0,g_t_geometry.ST_Length()),
                     point        => g_sdo_point,
                     tolerance    => g_t_geom2D.tolerance),g_t_geom2D.tolerance,g_t_geom2D.dPrecision,g_t_geom2D.projected);
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.PROJECT_PT() did not produce same output as MDSYS.SDO_LRS.PROJECT_PT()'
              ).to_equal('EQUAL');
    dbms_output.put_line('       ST(2D)=' ||  v_ST_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
    dbms_output.put_line('      SDO(2D)=' || v_SDO_LRS.ST_Round(3,3,2,3).ST_AsEWKT());    
  End st_lrs_Project_Pt;

  PROCEDURE st_lrs_translate_segment
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
  End st_lrs_translate_segment;

  PROCEDURE st_lrs_concatenate_pt_arg
  As
    c_i_point_not_line CONSTANT pls_integer := -20121;
    point_not_line     EXCEPTION;
    PRAGMA             EXCEPTION_INIT(point_not_line,-20121);
    v_ST_LRS           T_Geometry;
    v_SDO_LRS          T_Geometry;
  Begin
    BEGIN
     -- Should throw error as second argument should not be a point
      v_ST_LRS := SPDBA.t_geometry( 
                  ST_LRS.CONCATENATE_GEOM_SEGMENTS(g_t_geometry.geom,g_sdo_point,g_t_geometry.Tolerance),
                  g_t_geometry.tolerance,
                  g_t_geometry.dPrecision,
                  g_t_geometry.projected
                );
      EXCEPTION
         WHEN point_not_line THEN
           dbms_output.put_line('      SQLERRM=' || SUBSTR(SQLERRM,12,100));
           ut.expect(SQLCODE,SQLERRM).to_equal(c_i_point_not_line);
    END;
  End st_lrs_concatenate_pt_arg;

  PROCEDURE st_lrs_concatenate
  As
    v_SDO_LRS_1 sdo_geometry;
    v_SDO_LRS_2 sdo_geometry;
    v_ST_LRS    SPDBA.t_geometry;
    v_SDO_LRS   SPDBA.t_geometry;
  Begin
    MDSYS.SDO_LRS.SPLIT_GEOM_SEGMENT(
       geom_segment => g_t_geometry.geom,
       split_measure=> 5,
       segment_1    => v_SDO_LRS_1,
       segment_2    => v_SDO_LRS_2,
       tolerance    => g_t_geometry.tolerance
    );
    -- DEBUG dbms_output.put_line(DEBUG.PRINTGEOM(v_sdo_lrs_1,1,0,'v_sdo_lrs_1=',0));
    -- DEBUG dbms_output.put_line(DEBUG.PRINTGEOM(v_sdo_lrs_2,1,0,'v_sdo_lrs_2=',0));    
    
    -- Now concatenate
    v_ST_LRS  := SPDBA.t_geometry(
                   ST_LRS.CONCATENATE_GEOM_SEGMENTS(
                     geom_segment_1 => v_sdo_lrs_1,
                     geom_segment_2 => v_sdo_lrs_2,
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
    -- DEBUG dbms_output.put_line('       ST=' ||  v_ST_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
    -- DEBUG dbms_output.put_line('      SDO=' || v_SDO_LRS.ST_Round(3,3,2,3).ST_AsEWKT());
  End st_lrs_concatenate;

  PROCEDURE st_lrs_intersection
  As
  Begin
    NULL;
  End st_lrs_intersection;

  PROCEDURE st_lrs_split
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
       
    v_ST_LRS  := SPDBA.t_geometry( v_ST_LRS_1,g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected).ST_Round(3,3,2,3);
    v_SDO_LRS := SPDBA.t_geometry(v_SDO_LRS_1,g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected).ST_Round(3,3,2,3);
    dbms_output.put_line('       ST(1)=' ||  v_ST_LRS.ST_AsEWKT());
    dbms_output.put_line('      SDO(1)=' || v_SDO_LRS.ST_AsEWKT());

    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.SPLIT_GEOM_SEGMENT(segment_1) did not produce same output as MDSYS.SDO_LRS.SPLIT_GEOM_SEGMENT(segment_1)'
              ).to_equal('EQUAL');

    v_ST_LRS  := SPDBA.t_geometry( v_ST_LRS_2,g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected).ST_Round(3,3,2,3);
    v_SDO_LRS := SPDBA.t_geometry(v_SDO_LRS_2,g_t_geometry.tolerance,g_t_geometry.dPrecision,g_t_geometry.projected).ST_Round(3,3,2,3);
    dbms_output.put_line(CHR(10) || CHR(10) || 
                         '       ST(2)=' ||  v_ST_LRS.ST_AsEWKT());
    dbms_output.put_line('      SDO(2)=' || v_SDO_LRS.ST_AsEWKT());
    ut.expect( v_ST_LRS.ST_Round(3,3,2,3).ST_Equals(v_SDO_LRS.ST_Round(3,3,2,3).geom),
               'ST_LRS.SPLIT_GEOM_SEGMENT(segment_2) did not produce same output as MDSYS.SDO_LRS.SPLIT_GEOM_SEGMENT(segment_2)'
              ).to_equal('EQUAL');
  End st_lrs_split;

End test_st_lrs_package;
/
SHOW ERRORS

set serveroutput on size unlimited
set long 800
set linesize 800
begin ut.run('test_st_lrs_package'); end;

