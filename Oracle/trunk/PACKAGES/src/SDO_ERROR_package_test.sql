set pagesize 1000
set linesize 131

select t.id,
       t.startCoord.x, t.startCoord.y, 
       t.endCoord.x, t.endCoord.y 
from table(SDO_ERROR.FINDSPIKES(
              MDSYS.SDO_GEOMETRY(2002, NULL, NULL,
                    MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1), 
                    MDSYS.SDO_ORDINATE_ARRAY(377735.193, 5167466.085, 377738.192, 5167467.466, 
                                             377739.835, 5167465.897, 377739.859, 5167465.783,
                                             377739.876, 5167465.897, 377741.477, 5167466.510))
              ,0.05)) t;

select sdo_geom.validate_geometry_with_context(b.geom,0.005) as error
 from (select mdsys.sdo_util.extract(
                MDSYS.SDO_GEOMETRY(2003, NULL, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1,17,2003,1), 
                      MDSYS.SDO_ORDINATE_ARRAY(
                            523960.5, 5201847.7, 525174.7, 5202361.9, 525171.4, 5202328.8, 524843.0, 5202839.7,
                            524889.4, 5202833.0, 523748.1, 5202484.7, 523781.3, 5202554.4, 523960.5, 5201847.7,
                            524141.2, 5202192.9, 524223.1, 5202550.3, 524197.1, 5202520.5, 524502.3, 5202546.6,
                            524584.2, 5202293.4, 524614.0, 5202345.6, 524171.0, 5202189.2, 524141.2, 5202192.9)
                ),1,a.elem_no) as geom
         from (select level as elem_no from dual connect by level < 3) a
      ) b;

SELECT rownum as id, mdsys.sdo_geometry(2002,null,null,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1), MDSYS.SDO_ORDINATE_ARRAY(t.startCoord.x,t.startCoord.y,t.endCoord.x,t.endCoord.y)) as vector
  from table(sdo_error.getvector(MDSYS.SDO_GEOMETRY(2003, NULL, NULL, 
                                       MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1), 
                                       MDSYS.SDO_ORDINATE_ARRAY(
                                             378732.8, 145076.2, 492250.6, 145076.2, 476593.0, 129418.5, 
                                             472678.6, 256636.8, 494207.8, 242936.4, 366989.5, 240979.2, 
                                             388518.8, 256636.8, 390476.0, 115718.1, 378732.8, 145076.2)))) t;

With geom as (
SELECT MDSYS.SDO_GEOMETRY(2003, NULL, NULL, 
             MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1), 
             MDSYS.SDO_ORDINATE_ARRAY(378732.8, 145076.2, 492250.6, 145076.2, 476593.0, 129418.5, 
                                      472678.6, 256636.8, 494207.8, 242936.4, 366989.5, 240979.2, 
                                      388518.8, 256636.8, 390476.0, 115718.1, 378732.8, 145076.2)) as geom
  from dual
)
select t.*
  FROM geom a,
       TABLE(SDO_ERROR.getValidateErrors(a.geom,0.005,NULL,null,0,1,null)) t;

select *
 from table(sdo_error.getErrors(MDSYS.SDO_GEOMETRY(2003, NULL, NULL, 
                                      MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1), 
                                      MDSYS.SDO_ORDINATE_ARRAY(
                                            -371529.1, 5413628.1, 35054.5, 5409851.8, 11137.8, 5398522.8, 
                                               6102.7, 5669159.0, 36313.3, 5640207.2, -396704.6, 5636430.9, 
                                            -363976.5, 5676711.6, -351388.8, 5385935.1,-371529.1, 5408593.0, 
                                            -371529.1, 5413628.1)),0.005,2,1)) b;

select b.*
  from TABLE(sdo_error.getMarks(
  MDSYS.SDO_GEOMETRY(2003, NULL, NULL, 
        MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1,77,2003,1), 
        MDSYS.SDO_ORDINATE_ARRAY(
              524570.7, 5202359.4, 524267.6, 5202035.7, 524720.0, 5201928.8, 524725.1, 5201939.5,
              524739.1, 5201953.4, 524752.6, 5201964.8, 524766.0, 5201976.2, 524783.1, 5201991.4, 
              524797.6, 5202011.7, 524804.6, 5202025.0, 524815.0, 5202040.8, 524815.6, 5202042.1, 
              524820.6, 5202052.9, 524825.9, 5202063.1, 524834.6, 5202085.3, 524843.6, 5202099.9, 
              524853.9, 5202114.5, 524864.6, 5202124.6, 524868.6, 5202130.0, 524876.1, 5202139.8, 
              524890.1, 5202158.2, 524903.0, 5202177.8, 524914.4, 5202194.3, 524925.9, 5202214.7, 
              524933.5, 5202228.0, 524945.6, 5202245.1, 524959.0, 5202260.3, 524968.6, 5202276.2, 
              524976.9, 5202289.5, 524984.5, 5202299.6, 524987.6, 5202304.1, 524995.4, 5202314.8, 
              525005.5, 5202329.5, 525016.4, 5202343.4, 525022.6, 5202354.2, 525023.2, 5202355.0, 
              524976.5, 5202359.4, 524570.7, 5202359.4, 524548.3, 5202136.4, 524629.5, 5202207.1, 
              524548.3, 5202227.3, 524738.7, 5202227.3, 524738.7, 5202136.4, 524642.0, 5202103.2, 
              524548.3, 5202136.4)),
       0.05,
       1) ) b;

EXIT;
