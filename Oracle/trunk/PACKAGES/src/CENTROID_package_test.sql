DEFINE defaultSchema='&1'

SET SERVEROUTPUT ON 
SET PAGESIZE 1000 LINESIZE 132

Set echo on
With data as (
select sdo_geometry(
         'POLYGON((2300 -700, 2800 -300, 2300 700, 2800 1100, 2300 1100, 
                   1800 1100, 2300 800, 2000 600, 2300 600, 2300 500, 2400 400, 
                   2300 400, 2300 300, 2300 200, 2500 150, 2100 100, 2500 100, 
                   2300 -200, 1800 -300, 2300 -500, 2200 -400, 2400 -400, 2300 -700), 
                  (2300 1000, 2400 900, 2200 900, 2300 1000), 
                  (2400 -400, 2450 -300, 2550 -400, 2400 -400),
                  (2300 1000, 2400 1050, 2400 1000, 2300 1000))',null)
         as geom 
  from dual 
)
select t.COLUMN_VALUE as method_id,
       case t.Column_Value 
       when  0 then 'Avg of Area''s X Ordinates as Centroid Seed'
       when 10 then 'Avg of Area''s Y Ordinates as Centroid Seed'
       when  1 then 'Centre X Ordinate of geom MBR as seed'
       when 11 then 'Centre Y Ordinate of geom MBR as seed'
       when  2 then 'User X ordinate'
       when 12 then 'User Y ordinate'
       when  3 then 'MDSYS.SDO_GEOM.SDO_CENTROID'
       when  4 then 'MDSYS.SDO_GEOM.SDO_PointOnSurface'
       end as Method_Text,
       CENTROID.Centroid_A(
         P_Geometry   => a.geom, 
         p_method     => t.Column_Value,
         P_Seed_Value => case t.Column_Value when 2 then /*X*/ 2035.4 when 12 then /*Y*/ 284.6 else NULL end,
         P_Dec_Places => 3,
         P_Tolerance  => 0.05,
         p_loops      => 5
       ) as centroid
  from data a,
       table(CENTROID.generate_series(0,12,1)) t
 where t.Column_Value in (0, 1, 2, 3, 4, 10, 11, 12)
 order by 2 asc;
 
With geoms as (
  select 2 as roundX, 
         2300 as seedX,
         sdo_geometry('POLYGON((2300 -700, 2800 -300, 2300 700, 2800 1100, 2300 1100, 
                                1800 1100, 2300 800, 2000 600, 2300 600, 2300 500, 2400 400, 2300 400, 2300 300, 2300 200, 2500 150, 2100 100, 2500 100, 2300 -200, 1800 -300, 2300 -500, 2200 -400, 2400 -400, 2300 -700), 
                                (2300 1000, 2400 900, 2200 900, 2300 1000), 
                                (2400 -400, 2450 -300, 2550 -400, 2400 -400),
                                (2300 1000, 2400 1050, 2400 1000, 2300 1000))',null)                      as geom from dual union all 
  select 2 as roundX,4           as seedX,sdo_geometry('POLYGON((0 0, 10 0, 12 0, 10 10, 0 10, 0 9, 4 9, 4 1, 0 1, 0 0))',null)            as geom from dual union all 
  select 3 as roundX,4           as seedX,sdo_geometry('POLYGON((0 0, 10 0, 10 1, 4 1, 4 9, 10 9, 10 10, 3 10, 3 12, 5 12, 5 13, 0 13, -8 0, 0 0))', null)  as geom from dual union all 
  select 2 as roundX,4           as seedX,sdo_geometry('POLYGON((0 0, 10 0, 10 1, 3 1, 3 2, 4 2, 4 8, 3 8, 3 9, 10 9, 10 10, 0 10, -4 0, 0 0))', null)      as geom from dual union all 
  select 2 as roundX,4           as seedX,sdo_geometry('POLYGON((0 0, 2 0, 4 1, 3 9, 10 9, 15 10, 0 10, 0 0), (4 1, 3 1, 3 2, 4 1))',null) as geom from dual union all
  select 2 as roundX,4           as seedX,sdo_geometry('POLYGON((0 0, 2 0, 4 1, 5 9, 10 9, 13 10, 0 10, 0 0), (4 1, 3 1, 3 2, 4 1))',null) as geom from dual union all
  select 2 as roundX,4           as seedX,sdo_geometry('POLYGON((0.0 0.0, 2.0 0.0, 4.0 1.0, 9.0 2.0, 10.0 9.0, 13.0 10.0, 0.0 10.0, 0.0 0.0), (4.0 1.0, 3.0 1.0, 3.0 2.0, 4.0 1.0))',null) as geom from dual union all
  select 6 as roundX,-120.162105 as seedX,sdo_geometry('POLYGON ((-120.162832 42.356006, -120.164074 42.356006, -120.164074 42.3558, -120.16449 42.3558, -120.16449 42.355592, -120.164696 42.355592, -120.164696 42.355178, -120.164904 42.355178, -120.164904 42.35497, -120.165318 42.35497, -120.165318 42.354762, -120.165526 42.354762, -120.165526 42.353104, -120.165318 42.353104, -120.165318 42.350824, -120.164904 42.350824, -120.164904 42.350616, -120.164696 42.350616, -120.164696 42.349372, -120.16449 42.349372, -120.16449 42.349166, -120.164074 42.349166, -120.164074 42.348544, -120.163868 42.348544, -120.163868 42.348128, -120.16366 42.348128, -120.16366 42.347506, -120.163246 42.347506, -120.163246 42.346884, -120.163038 42.346884, -120.163038 42.346264, -120.162832 42.346264, -120.162832 42.345848, -120.162416 42.345848, -120.162416 42.345226, -120.16221 42.345226, -120.16221 42.34502, -120.162002 42.34502, -120.162002 42.344604, -120.16138 42.344604, -120.16138 42.34502, -120.161172 42.34502, -120.161172 42.345226, -120.160758 42.345226, -120.160758 42.345848, -120.16055 42.345848, -120.16055 42.346264, -120.160344 42.346264, -120.160344 42.346884, -120.159928 42.346884, -120.159928 42.347092, -120.159722 42.347092, -120.159722 42.347506, -120.159514 42.347506, -120.159514 42.347714, -120.1591 42.347714, -120.1591 42.348128, -120.158892 42.348128, -120.158892 42.348336, -120.158684 42.348336, -120.158684 42.348544, -120.158892 42.348544, -120.158892 42.349166, -120.1591 42.349166, -120.1591 42.349372, -120.159514 42.349372, -120.159514 42.349994, -120.159722 42.349994, -120.159722 42.350202, -120.159928 42.350202, -120.159928 42.352276, -120.160344 42.352276, -120.160344 42.352482, -120.160758 42.352482, -120.160758 42.353104, -120.161172 42.353104, -120.161172 42.353312, -120.16138 42.353312, -120.16138 42.35414, -120.161588 42.35414, -120.161588 42.35497, -120.162002 42.35497, -120.162002 42.355178, -120.16221 42.355178, -120.16221 42.355592, -120.162416 42.355592, -120.162416 42.3558, -120.162832 42.3558, -120.162832 42.356006))',8307) as geom from dual union all
  select 6 as roundX,-121.58488  as seedX,sdo_geometry('POLYGON ((-121.58488 43.259452, -121.584968 43.25945, -121.584966 43.259384, -121.58488 43.259386, -121.58488 43.259374, -121.584792 43.259376, -121.584794 43.259442, -121.58488 43.25944, -121.58488 43.259452))',8307) as geom from dual
)
select seedX, 
       roundX,
       sdo_geom.relate(centroid, 'determine', geom, 0.005) sdo_relate, 
       b.centroid.get_wkt() centroid_wkt, 
       b.centroid,
       b.geom.get_wkt() geom_wkt ,
       b.geom
from (select a.seedX,
             a.roundX,
             &&defaultSchema..centroid.centroid_a(p_geometry   => a.geom,
                                                  p_method     => 2,
                                                  p_seed_value => a.seedx,
                                                  p_dec_places => 5,
                                                  p_tolerance  => 0.005,
                                                  p_loops      => 2) as centroid, 
             a.geom 
       from geoms a ) b;

Prompt ConvertGeometry - Compound linestring
SELECT &&defaultSchema..CENTROID.convertGeometry(
       SDO_GEOMETRY(
           2002,
           NULL,
           NULL,
           SDO_ELEM_INFO_ARRAY(1,4,2, 1,2,1, 3,2,2), -- compound line string
           SDO_ORDINATE_ARRAY(252000,5526000,252700,5526700,252500,5526700,252500,5526500)
         ),0.1) 
  from dual;

Prompt ConvertGeometry - Compound polygon 
SELECT &&defaultSchema..CENTROID.convertGeometry(
       SDO_GEOMETRY(
          2003,  -- two-dimensional polygon
          NULL,
          NULL,
          SDO_ELEM_INFO_ARRAY(1,1005,2, 1,2,1, 5,2,2), -- compound polygon
          SDO_ORDINATE_ARRAY(6,10, 10,1, 14,10, 10,14, 6,10)
         ),0.5) 
  from dual;

Prompt ConvertGeometry - Compound polygon 
With cPoly As (
SELECT &&defaultSchema..CENTROID.convertGeometry(
       SDO_GEOMETRY(
          2003,  -- two-dimensional polygon
          NULL,
          NULL,
          SDO_ELEM_INFO_ARRAY(1,1005,2, 1,2,1, 5,2,2), -- compound polygon
          SDO_ORDINATE_ARRAY(6,10, 10,1, 14,10, 10,14, 6,10)
         ),0.5) geom
  from dual
)
select case LEVEL when 1 then 'X' else 'Y' end as ord,
       &&defaultSchema..centroid.centroid_a(p_geometry   => a.geom,
                                            p_method     => case LEVEL when 1 then 0 else 10 end,
                                            p_seed_value => NULL,
                                            p_dec_places => 2,
                                            p_tolerance  => 0.005,
                                            p_loops      => 2) as centroid
  from cPoly a
  connect by level < 3;

With geom As (
  select mdsys.sdo_geometry(2003,null,null,sdo_elem_info_array(1,1003,3,5,2003,3),sdo_ordinate_array(0,0,100,100,40,40,60,60)) as geom 
    from dual
)
select &&defaultSchema..centroid.sdo_centroid(p_geometry=>a.geom,p_start=>1,p_tolerance=>0.05) as centroid 
  from geom a;

With geom As (
SELECT 
MDSYS.SDO_GEOMETRY(2003, 8265, NULL, 
MDSYS.SDO_ELEM_INFO_ARRAY(1, 1003, 1),
MDSYS.SDO_ORDINATE_ARRAY(
-79.230383, 35.836761, -79.230381, 35.836795, -79.230414, 35.83683, -79.230468, 35.836857, 
-79.230502, 35.836878, -79.23055, 35.836906, -79.23059, 35.836922,  -79.230617, 35.836945,
-79.230658, 35.836966, -79.230671, 35.837005, -79.230698, 35.837048, -79.230704, 35.837082, 
-79.230712, 35.83712, -79.230711, 35.837192, -79.230725, 35.83722, -79.230779, 35.837247, 
-79.230792, 35.837202, -79.230785, 35.837114, -79.23078, 35.837087, -79.230765, 35.837038,
-79.230718, 35.836972, -79.230671, 35.836917, -79.230637, 35.8369, -79.23061, 35.836873,
-79.230583, 35.83685, -79.230529, 35.836818, -79.230489, 35.83679, -79.230456, 35.836774, -79.230383, 35.836761)) as geom
from dual
)
SELECT mdsys.sdo_geom.sdo_centroid( a.geom, 0.005 ) as sdo_centroid,
       &&defaultSchema..centroid.sdo_centroid(p_geometry=>a.geom,p_start=>1,p_tolerance=>0.0000001) as centroidTol,
       &&defaultSchema..centroid.sdo_centroid(p_geometry=>a.geom,p_start=>1,p_largest=>1,p_round_x=>8,p_round_y=>8,p_round_z=>1) as centroidRound
  from geom a;

With t_poly as (
select MDSYS.SDO_GEOMETRY(2007,NULL,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1,11,1003,1),MDSYS.SDO_ORDINATE_ARRAY(0.0,0.0,100.0,0.0,100.0,100.0,0.0,100.0,0.0,0.0,1000.0,1000.0,1100.0,1000.0,1100.0,1100.0,1000.0,1100.0,1000.0,1000.0)) as geom
from dual
) 
SELECT &&defaultSchema..centroid.sdo_centroid(p_geometry=>sdo_util.Extract(a.geom,1,0),p_start=>1,p_tolerance=>0.05).get_wkt() as centroid,
       &&defaultSchema..centroid.sdo_multi_centroid(p_geometry=>a.geom,p_start=>1,p_round_x=>3,p_round_y=>3,p_round_z=>2).get_wkt() as mCentroid
  from t_poly a;

with c_manydigits_geom as (
select MDSYS.SDO_GEOMETRY(2003,41014,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(703004.4,1829970.1,703014.8,1829973.6,703018.3,1829983.9,703019.1,1830008.2,703013.9,1830033.2,703001.8,1830043.6,702994.9,1830037.5,702989.7,1830019.4,702990.5,1829991.7,702993.2,1829975.3,703004.4,1829970.1)) as geom
from dual
)
SELECT &&defaultSchema..centroid.sdo_centroid(a.geom, 1, MDSYS.SDO_DIM_ARRAY(
                                          MDSYS.SDO_DIM_ELEMENT('X', 0, 1200000, .01),
                                          MDSYS.SDO_DIM_ELEMENT('Y', 1600000, 2700000, .01))) as c1,
       &&defaultSchema..centroid.sdo_centroid(a.geom, 1, MDSYS.SDO_DIM_ARRAY(
                                          MDSYS.SDO_DIM_ELEMENT('X',0,5000000,0.005),
                                          MDSYS.SDO_DIM_ELEMENT('Y',0,5000000,0.005)) ) as c2
  from c_manydigits_geom a;

-- Example of how to use centroid in an anonymous pl/sql situation.
set serveroutput on size unlimited
declare
     v_centroid mdsys.sdo_geometry;
begin
    for rec in ( With t_geoms as (
                   select 1 as id, MDSYS.SDO_GEOMETRY(2007,NULL,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1,11,1003,1),MDSYS.SDO_ORDINATE_ARRAY(0.0,0.0,100.0,0.0,100.0,100.0,0.0,100.0,0.0,0.0,1000.0,1000.0,1100.0,1000.0,1100.0,1100.0,1000.0,1100.0,1000.0,1000.0)) as geom from dual union all
                   select 2 as id, MDSYS.SDO_GEOMETRY(2003,NULL,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1,77,2003,1),MDSYS.SDO_ORDINATE_ARRAY(524570.7,5202359.4,524267.6,5202035.7,524720,5201928.8,524725.1,5201939.5,524739.1,5201953.4,524752.6,5201964.8,524766,5201976.2,524783.1,5201991.4,524797.6,5202011.7,524804.6,5202025,524815,5202040.8,524815.6,5202042.1,524820.6,5202052.9,524825.9,5202063.1,524834.6,5202085.3,524843.6,5202099.9,524853.9,5202114.5,524864.6,5202124.6,524868.6,5202130,524876.1,5202139.8,524890.1,5202158.2,524903,5202177.8,524914.4,5202194.3,524925.9,5202214.7,524933.5,5202228,524945.6,5202245.1,524959,5202260.3,524968.6,5202276.2,524976.9,5202289.5,524984.5,5202299.6,524987.6,5202304.1,524995.4,5202314.8,525005.5,5202329.5,525016.4,5202343.4,525022.6,5202354.2,525023.2,5202355,524976.5,5202359.4,524570.7,5202359.4,524548.319747,5202136.448354,524548.319747,5202227.311646,524738.65443,5202227.311646,524738.65443,5202136.448354,524548.319747,5202136.448354)) as geom from dual
                 ) 
                 SELECT id, a.geom
                   from t_geoms a
                ) loop
       begin
          v_centroid := &&defaultSchema..CENTROID.sdo_centroid( p_geometry => rec.geom, 
                                                                p_start    => 1, 
                                                                p_largest  => 0,
                                                                p_round_X  => 2,
                                                                p_round_y  => 2,
                                                                p_round_z  => 1);
          dbms_output.put_line(rec.id || ' centroid(' || v_centroid.sdo_point.x || ',' || v_centroid.sdo_point.x || ')');
          exception
             when others then
                dbms_output.put_line('ERROR: ' || rec.id || ' ' || SQLERRM);
       end;
    end loop;
end;
/

With geoms as (
select sdo_geometry('POLYGON ((-121.58488 43.259452, -121.584968 43.25945, -121.584966 43.259384, -121.58488 43.259386, -121.58488 43.259374, -121.584792 43.259376, -121.584794 43.259442, -121.58488 43.25944, -121.58488 43.259452))',8307)
as geom from dual
)
select centroid.sdo_centroid(a.geom,1,0.0000005) as centroid from geoms a;

With geoms as (
select sdo_geometry('POLYGON ((-120.162832 42.356006, -120.164074 42.356006, -120.164074 42.3558, -120.16449 42.3558, -120.16449 42.355592, -120.164696 42.355592, -120.164696 42.355178, -120.164904 42.355178, -120.164904 42.35497, -120.165318 42.35497, -120.165318 42.354762, -120.165526 42.354762, -120.165526 42.353104, -120.165318 42.353104, -120.165318 42.350824, -120.164904 42.350824, -120.164904 42.350616, -120.164696 42.350616, -120.164696 42.349372, -120.16449 42.349372, -120.16449 42.349166, -120.164074 42.349166, -120.164074 42.348544, -120.163868 42.348544, -120.163868 42.348128, -120.16366 42.348128, -120.16366 42.347506, -120.163246 42.347506, -120.163246 42.346884, -120.163038 42.346884, -120.163038 42.346264, -120.162832 42.346264, -120.162832 42.345848, -120.162416 42.345848, -120.162416 42.345226, -120.16221 42.345226, -120.16221 42.34502, -120.162002 42.34502, -120.162002 42.344604, -120.16138 42.344604, -120.16138 42.34502, -120.161172 42.34502, -120.161172 42.345226, -120.160758 42.345226, -120.160758 42.345848, -120.16055 42.345848, -120.16055 42.346264, -120.160344 42.346264, -120.160344 42.346884, -120.159928 42.346884, -120.159928 42.347092, -120.159722 42.347092, -120.159722 42.347506, -120.159514 42.347506, -120.159514 42.347714, -120.1591 42.347714, -120.1591 42.348128, -120.158892 42.348128, -120.158892 42.348336, -120.158684 42.348336, -120.158684 42.348544, -120.158892 42.348544, -120.158892 42.349166, -120.1591 42.349166, -120.1591 42.349372, -120.159514 42.349372, -120.159514 42.349994, -120.159722 42.349994, -120.159722 42.350202, -120.159928 42.350202, -120.159928 42.352276, -120.160344 42.352276, -120.160344 42.352482, -120.160758 42.352482, -120.160758 42.353104, -120.161172 42.353104, -120.161172 42.353312, -120.16138 42.353312, -120.16138 42.35414, -120.161588 42.35414, -120.161588 42.35497, -120.162002 42.35497, -120.162002 42.355178, -120.16221 42.355178, -120.16221 42.355592, -120.162416 42.355592, -120.162416 42.3558, -120.162832 42.3558, -120.162832 42.356006))',8307) as geom
from dual
)
select centroid.sdo_centroid(a.geom,1,0.0000005) as centroid from geoms a;


QUIT;
