DEFINE defaultSchema='&1'

SET VERIFY OFF;

SET LINESIZE 132 PAGESIZE 1000
set serveroutput on size unlimited
declare
    v_inter_x   number; v_inter_y  number;
    v_inter_x1  number; v_inter_y1 number;
    v_inter_x2  number; v_inter_y2 number;
begin
    &&defaultSchema..LINEAR.ST_FindLineIntersection(0,0,10,10, 
                                0,10,0,1,
                             v_inter_x,v_inter_y,
                             v_inter_x1,v_inter_y1,
                             v_inter_x2,v_inter_y2);
    dbms_output.put_line(v_inter_x|| ',' || v_inter_y);
    dbms_output.put_line(v_inter_x1|| ',' || v_inter_y1);
    dbms_output.put_line(v_inter_x2|| ',' || v_inter_y2);

    dbms_output.put_line('');

    &&defaultSchema..LINEAR.ST_FindLineIntersection(0,0,10,10, 
                                5,0,5,10,
                                v_inter_x,v_inter_y,
                                v_inter_x1,v_inter_y1,
                                v_inter_x2,v_inter_y2);
    dbms_output.put_line(v_inter_x|| ',' || v_inter_y);
    dbms_output.put_line(v_inter_x1|| ',' || v_inter_y1);
    dbms_output.put_line(v_inter_x2|| ',' || v_inter_y2);

    dbms_output.put_line('');

    &&defaultSchema..LINEAR.ST_FindLineIntersection(0,0,10,10, 
                                1,1,11,11,
                                v_inter_x, v_inter_y,
                                v_inter_x1,v_inter_y1,
                                v_inter_x2,v_inter_y2);
    dbms_output.put_line(v_inter_x|| ',' || v_inter_y);
    dbms_output.put_line(v_inter_x1|| ',' || v_inter_y1);
    dbms_output.put_line(v_inter_x2|| ',' || v_inter_y2);

    dbms_output.put_line('');

    &&defaultSchema..LINEAR.ST_FindLineIntersection(0,2,10,11, 
                                0,0,10,10,
                                v_inter_x, v_inter_y,
                                v_inter_x1,v_inter_y1,
                                v_inter_x2,v_inter_y2);
    dbms_output.put_line(v_inter_x|| ',' || v_inter_y);
    dbms_output.put_line(v_inter_x1|| ',' || v_inter_y1);
    dbms_output.put_line(v_inter_x2|| ',' || v_inter_y2);

    dbms_output.put_line('');

    dbms_output.put_line(&&defaultSchema..constants.c_Max);
    
    &&defaultSchema..LINEAR.ST_FindLineIntersection(0,5,11,5,1,10,1,1,
                             v_inter_x,v_inter_y,
                             v_inter_x1,v_inter_y1,
                             v_inter_x2,v_inter_y2);
    dbms_output.put_line(v_inter_x|| ',' || v_inter_y);
    dbms_output.put_line(v_inter_x1|| ',' || v_inter_y1);
    dbms_output.put_line(v_inter_x2|| ',' || v_inter_y2);

end;
/
show errors

select  mdsys.sdo_lrs.convert_to_lrs_geom(sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,5, 10,5)),100,200) from dual;
select &&defaultSchema..LINEAR.convert_to_lrs_geom(sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,5, 10,5)),100,200,0.005) from dual;
select  mdsys.sdo_lrs.convert_to_lrs_geom(sdo_geometry(2006,null,null,sdo_elem_info_array(1,2,1,5,2,1),sdo_ordinate_array(0,0,10,0,30,0,60,0)),100,200) from dual;
select &&defaultSchema..LINEAR.convert_to_lrs_geom(sdo_geometry(2006,null,null,sdo_elem_info_array(1,2,1,5,2,1),sdo_ordinate_array(0,0,10,0,30,0,60,0)),100,200) from dual;
select  mdsys.sdo_lrs.convert_to_lrs_geom(sdo_geometry(3006,null,null,sdo_elem_info_array(1,2,1,7,2,1),sdo_ordinate_array(0,0,-1,10,0,-2,30,0,-3,60,0,-4)),100,200) from dual;
select &&defaultSchema..LINEAR.convert_to_lrs_geom(sdo_geometry(3006,null,null,sdo_elem_info_array(1,2,1,7,2,1),sdo_ordinate_array(0,0,-1,10,0,-2,30,0,-3,60,0,-4)),100,200,0.005) from dual;
select  mdsys.sdo_lrs.convert_to_lrs_geom(LINEAR.ST_to3d(sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,5, 10,5)),-99,-90),100,200) from dual;
select &&defaultSchema..LINEAR.convert_to_lrs_geom(LINEAR.ST_to3d(sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,5, 10,5)),-99,-90),100,200) from dual;

set serveroutput on size unlimited
With lrs_routes As (
  SELECT SDO_GEOMETRY(3302,NULL,NULL, SDO_ELEM_INFO_ARRAY(1,2,1), SDO_ORDINATE_ARRAY(
          2.0,2.0,0.0,
          2.0,4.0,3.218,
          8.0,4.0,12.872,
          12.0,4.0,19.308,
          12.0,10.0,28.962,
          8.0,10.0,35.398,
          5.0,14.0,43.443)) as geometry
  FROM DUAL
)
SELECT 'LINEAR.ST_LOCATE_POINT at ' || f.measure || ' ' || f.mType || ' units ' || f.offset || ' offset' as text, 
       f.measure,
       f.offset,
       f.mType,
       LINEAR.ST_Locate_Point(f.geometry,
                              f.measure,
                              f.offset,
                              f.mType,
                              0.0005) as located_point
 from (select case when lm.column_value = 0 then a.geometry else linear.ST_To2d(a.geometry) end as geometry,
              round(case when lm.column_value = 0 then m.z else dbms_random.value(0,sdo_geom.sdo_length(a.geometry,0.005)) end,3) as measure,
              o.column_value as offset,
              case when lm.column_value = 0 then 'M' else 'L' end mType
         From lrs_routes a,
              table(linear.generate_series(0,1,1)) lm,
              table(linear.generate_series(-1,1,1)) o,
              table(sdo_util.getVertices(a.geometry)) m
      ) f
order by f.mType, f.offset, f.measure;
  
set serveroutput on size unlimited
With lrs_routes As (
  SELECT SDO_GEOMETRY(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1), SDO_ORDINATE_ARRAY(
          2.0,2.0,0.0,
          2.0,4.0,3.218,
          8.0,4.0,12.872,
          12.0,4.0,19.308,
          12.0,10.0,28.962,
          8.0,10.0,35.398,
          5.0,14.0,43.443)) as geometry
  FROM DUAL
)
SELECT 'Original Measured geometry'                           as text, a.geometry as geom FROM lrs_routes a union all 
SELECT 'LINEAR.ST_isMeasured(' || a.geometry.sdo_gtype || ')=' || LINEAR.ST_isMeasured(a.geometry.sdo_gtype)                   as text, NULL as geom from lrs_routes a union all
SELECT 'LINEAR.ST_getMeasureDimension(' || a.geometry.sdo_gtype || ')=' || LINEAR.ST_getMeasureDimension(a.geometry.sdo_gtype) as text, NULL as geom from lrs_routes a union all
SELECT 'LINEAR.ST_Measure_Range = '                            || round(LINEAR.ST_Measure_Range(a.geometry),3)                 as text, NULL as geom from lrs_routes a union all
SELECT 'LINEAR.ST_Start_Measure = '                            || round(LINEAR.ST_Start_Measure(a.geometry),3)                 as text, NULL as geom from lrs_routes a union all
SELECT 'LINEAR.ST_End_Measure = '                              || round(LINEAR.ST_End_Measure(a.geometry),3)                   as text, NULL as geom from lrs_routes a union all
SELECT 'LINEAR.ST_Is_Measure_Increasing = '                    || LINEAR.ST_Is_Measure_Increasing(a.geometry)                  as text, NULL as geom from lrs_routes a union all
SELECT 'LINEAR.ST_Is_Measure_Decreasing = '                    || LINEAR.ST_Is_Measure_Decreasing(a.geometry)                  as text, NULL as geom from lrs_routes a union all
SELECT 'LINEAR.ST_Measure_To_Percentage 18/43.443 = '          || round(LINEAR.ST_Measure_To_Percentage(a.geometry,18),2)      as text, a.geometry as geom from lrs_routes a union all
SELECT 'LINEAR.ST_Percentage_To_Measure 41.43% = '             || round(LINEAR.ST_Percentage_To_Measure(a.geometry,41.43),3)   as text, NULL as geom from lrs_routes a union all
SELECT 'LINEAR.ST_Reverse_Measure'                            as text, LINEAR.ST_Reverse_Measure(a.geometry) as geom FROM lrs_routes a union all 
SELECT 'LINEAR.ST_Set_Pt_Measure (Set 8,10 m from 22 to 20'   as text, LINEAR.ST_Set_Pt_Measure(a.geometry, SDO_GEOMETRY(3301,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,10,22)),20) as geom FROM lrs_routes a union all 
SELECT 'LINEAR.ST_Clip by distance'                           as text, LINEAR.ST_Clip(a.geometry, 5, 10, 'L', 0.0005, 0) as Geom FROM lrs_routes a union all
SELECT 'LINEAR.ST_Clip by measure'                            as text, LINEAR.ST_Clip(a.geometry, 5, 10, 'M', 0.0005, 0) as Geom FROM lrs_routes a union all
SELECT 'SDO_LRS.CLIP_GEOM_SEGMENT by measure'                 as text, LINEAR.ST_RoundOrdinates(SDO_LRS.CLIP_GEOM_SEGMENT (a.geometry, 5, 10, 0.0005),3) as geom FROM lrs_routes a union all
SELECT 'LINEAR.ST_Offset_Geom_Segment 5-10'                   as text, LINEAR.OFFSET_GEOM_SEGMENT(a.geometry, 5, 10, 2, 0.0005) as geom FROM lrs_routes a union all
SELECT 'SDO_LRS.OFFSET_GEOM_SEGMENT measured segment 5-10'    as text, LINEAR.ST_RoundOrdinates(SDO_LRS.OFFSET_GEOM_SEGMENT  (a.geometry, 5, 10, 2, 0.0005),3) as geom FROM lrs_routes a union all
SELECT 'LINEAR.ST_Offset_Geom_Segment measured segment 5-20'  as text, LINEAR.OFFSET_GEOM_SEGMENT(a.geometry, 5, 20, 2, 0.0005) as geom FROM lrs_routes a union all
SELECT 'SDO_LRS.OFFSET_GEOM_SEGMENT measured segment 5-20'    as text, LINEAR.ST_RoundOrdinates(SDO_LRS.OFFSET_GEOM_SEGMENT(a.geometry, 5, 20, 2, 0.0005),3) as geom FROM lrs_routes a union all
SELECT 'LINEAR.ST_Reset_Measure'                              as text, LINEAR.ST_Reset_Measure(a.geometry)                         as geom from lrs_routes a union all
SELECT 'LINEAR.convert_to_lrs_geom'                           as text, LINEAR.convert_to_lrs_geom(a.geometry,0,27,0.005) as geom from lrs_routes a union all
SELECT 'LINEAR.Define_Geom_Segment (SDO_LRS Wrapper)'         as text, LINEAR.Define_Geom_Segment(a.geometry,0,27) as geom from lrs_routes a union all
SELECT 'SDO_LRS.SCALE_GEOM_SEGMENT'                           as text, SDO_LRS.SCALE_GEOM_SEGMENT(a.geometry, 100, 200, 10) as geom from lrs_routes a union all
SELECT 'LINEAR.ST_Scale_Geom_Segment'                         as text, LINEAR.ST_Scale_Geom_Segment(a.geometry, 100, 200, 10) as geom from lrs_routes a union all
SELECT 'LINEAR.ST_Split_Geom_Segment (cf SDO_LRS.SPLIT_GEOM_SEGMENT)' || rownum as text, s.geometry as geom 
  FROM lrs_routes a,
       TABLE(LINEAR.ST_SPLIT_GEOM_SEGMENT(a.geometry,5)) s union all
SELECT 'LINEAR.ST_Concatenate_Geom_Segments'                  as text, 
       LINEAR.ST_CONCATENATE_GEOM_SEGMENTS(f1.geom1,f2.geom2,0.005) as geom
  FROM (SELECT rownum as rin,
               s.geometry as geom1
          FROM lrs_routes a,
               TABLE(LINEAR.ST_SPLIT_GEOM_SEGMENT(a.geometry,5)) s
       ) f1,
       (SELECT rownum as rin,
               s.geometry as geom2
          FROM lrs_routes a,
               TABLE(LINEAR.ST_SPLIT_GEOM_SEGMENT(a.geometry,5)) s
       ) f2
 WHERE f1.rin = 1 and f2.rin = 2;

With Geoms As (
select mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,45,45,90,0,135,45,180,0,180,-45,90.84,-44.855, 91.181,-90.221, 123.586,-107.277, 98.685,-74.872, 160.766,-111.37, 159.06,-62.933))
        as geom
  from dual
)
select LINEAR.ST_Parallel(a.geom,5,0.05,1) as RightGeom from geoms a union all
select LINEAR.ST_Parallel(a.geom,-5,0.05,1) as LeftGeom from geoms a;

select LINEAR.ST_Parallel(SDO_GEOMETRY(2006,2872,NULL,SDO_ELEM_INFO_ARRAY(1,2,1,5,2,1),SDO_ORDINATE_ARRAY(6012251.772,2099305.196, 6011750.876,2098627.567,6012897.282,2099637.281, 6012338.911,2099378.038))
                          ,-5,0.05,1,'unit=U.S. FOOT') as LeftGeom 
from dual;

exit;
