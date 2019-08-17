With testGeom as (
  select mdsys.sdo_geometry(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2.0,2.0,2.0,4.0,8.0,4.0,12.0,4.0,12.0,10.0,8.0,10.0,5.0,14.0)) as geom,
         SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2.0,2.0,0.0, 2.0,4.0,22.22, 8.0,4.0,37.04, 12.0,4.0,59.26, 12.0,10.0,74.07, 8.0,10.0,92.59, 5.0,14.0,100.0)) as geom3D,
         mdsys.sdo_geometry(2001,null,sdo_point_type(2.0,2.0,null),null,null) as rotatePoint
    from dual
)
SELECT 'RotatePoint', rotatePoint from testGeom union all
SELECT 'ST_Rotate(90)' as aFunction, Affine.ST_Rotate(p_geometry=>a.geom,p_angle_rad=>Affine.ST_Radians(90)) as geom from testGeom a union all
SELECT 'ST_Rotate(rPoint)' as aFunction, Affine.ST_Rotate(p_geometry=>a.geom,p_angle_rad=>Affine.ST_Radians(225),p_rotate_point=>rotatePoint) as geom from testGeom a union all
SELECT 'ST_Rotate(45/dir/rPoint)' as aFunction, Affine.ST_Rotate(p_geometry=>a.geom,p_angle_rad=>Affine.ST_Radians(45),p_dir=>-1,p_rotate_point=>rotatePoint, p_line1=>null ) as geom from testGeom a union all
SELECT 'ST_Rotate(135/2/2)' as aFunction, Affine.ST_Rotate(p_geometry=>a.geom,p_angle_rad=>Affine.ST_Radians(135),p_rotate_x=>2.0,p_rotate_y=>2.0) as geom from testGeom a union all
SELECT 'ST_Scale'                as aFunction, Affine.ST_Scale(p_geometry=>a.geom,p_sx=>2,p_sy=>2,p_sz=>0) as geom from testGeom a union all
SELECT 'ST_Scale'                as aFunction, Affine.ST_Scale(p_geometry=>a.geom,p_sx=>3,p_sy=>3) as geom from testGeom a union all
SELECT 'ST_Translate'            as aFunction, Affine.ST_Translate(a.geom,10,10) as geom from testGeom a union all
SELECT 'ST_Translate'            as aFunction, Affine.ST_Translate(a.geom,10,10,10) as geom from testGeom a union all
SELECT 'ST_RotateTranslateScale' as aFunction, Affine.ST_RotateTranslateScale(a.geom,Affine.ST_Radians(45),rotatePoint,2,2,0,10,10,0) as geom from testGeom a union all
SELECT 'PLSQL: Move'             as aFunction, Affine.Move(a.geom,10,10) as geom from testGeom a union all
SELECT 'PLSQL: Scale'            as aFunction, Affine.Scale(a.geom,2.0,2.0,NULL,3) as geom from testGeom a union all
SELECT 'PLSQL: Rotate'           as aFunction, Affine.Rotate(a.geom,a.rotatePoint.sdo_point.X,a.rotatePoint.sdo_point.Y,225,3) as geom from testGeom a;

-- Compare Oracle vs PLSQL 
--

With testGeom as (
  select mdsys.sdo_geometry(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2.0,2.0,2.0,4.0,8.0,4.0,12.0,4.0,12.0,10.0,8.0,10.0,5.0,14.0)) as geom,
         mdsys.sdo_geometry(2001,null,sdo_point_type(2.0,2.0,null),null,null) as rotatePoint
    from dual
)
select aFunction,CAST(sdo_geom.relate(pGeom,'DETERMINE',oGeom,0.0005) as varchar2(15)) as cGeom, pGeom, oGeom
  FROM (SELECT 'PLSQL: Rotate About Point(' || g.column_value || ')' as aFunction, 
               Affine.Rotate   (p_geometry=>a.geom,                                                     p_rX=>a.rotatePoint.sdo_point.X,      p_rY=>a.rotatePoint.sdo_point.Y,p_angle=>g.column_Value,p_decimal_digits=>3) as pGeom,
               Affine.ST_Rotate(p_geometry=>a.geom,p_angle_rad=>Affine.ST_Radians(g.column_value),p_rotate_x=>a.rotatePoint.sdo_point.X,p_rotate_y=>a.rotatePoint.sdo_point.Y) as oGeom
          from testGeom a,
               table(codetest.geom.generate_series(45,225,45))  g
        union all
        SELECT 'PLSQL: Rotate About First Vertex (' || g.column_value || ')' as aFunction, 
               Affine.Rotate   (p_geometry=>a.geom,                                               p_rX      =>LINEAR.ST_Start_Point(a.geom).sdo_point.X,      p_rY=>LINEAR.ST_Start_Point(a.geom).sdo_point.Y,p_angle=>g.column_Value,p_decimal_digits=>3) as pGeom,
               Affine.ST_Rotate(p_geometry=>a.geom,p_angle_rad=>Affine.ST_Radians(g.column_value),p_rotate_x=>LINEAR.ST_Start_Point(a.geom).sdo_point.X,p_rotate_y=>LINEAR.ST_Start_Point(a.geom).sdo_point.Y) as oGeom
          from testGeom a,
               table(codetest.geom.generate_series(45,225,45)) g
      ) h;

With rGeom As (
SELECT sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,2,3,1,4,3)) As the_geom,
       mdsys.sdo_geometry(2001,null,mdsys.sdo_point_type(0.0,0.0,null),NULL,NULL) as rPoint
  from dual
)
select AFFINE.Rotate   (the_geom,a.rPoint.sdo_point.x,a.rPoint.sdo_point.y,180,3) As sRotate,
       AFFINE.ST_Rotate(the_geom,CONSTANTS.pi(), rPoint)                          As oRotate,
       the_geom,
       rPoint
	FROM rGeom a;

With rGeom As (
SELECT sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,2,3,1,4,3)) As the_geom
  from dual
)
select AFFINE.Move        (the_geom,10.0,10.0,null,3) As sMove,
       AFFINE.ST_Translate(the_geom,10.0,10.0)        As oTranslate,
       the_geom
	FROM rGeom a;

With rGeom As (
SELECT sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,2,3,1,4,3)) As the_geom
  from dual
)
select AFFINE.Scale   (a.the_geom,2,2.0,NULL,3) As sScale,
       AFFINE.ST_Scale(a.the_geom,2,2,p_sz=>0)  as oScale,

       the_geom
	FROM rGeom a;

-- Documented test for PostGIS
--
With geom3d as (
SELECT sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,2,3,1,4,3)) 
          As the_geom 
  from dual
)
SELECT AFFINE.ST_Affine(p_geometry=>the_geom, 
                        p_a=>cos(CONSTANTS.pi()), 
                        p_b=>0-sin(CONSTANTS.pi()), 
                        p_c=>0,  
                        p_d=>sin(CONSTANTS.pi()), 
                        p_e=>cos(CONSTANTS.pi()), 
                        p_f=>0,  
                        p_g=>0, 
                        p_h=>0, 
                        p_i=>1, 
                        p_xoff=>0, 
                        p_yoff=>0, 
                        p_zoff=>0) As using_affine
	FROM geom3d a;

quit;
