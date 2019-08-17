DEFINE defaultSchema='&1'

SET SERVEROUTPUT ON
SET TIMING ON
SET PAGESIZE 1000
SET LINESIZE 120
SET LONG 50000
SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000
SET SHOWMODE OFF
SET TRIMOUT ON

DECLARE
  CURSOR c_kml IS
   SELECT 'VERTEX NO HOLE' as polytype,
          MDSYS.SDO_GEOMETRY(2003, NULL, NULL, 
MDSYS.SDO_ELEM_INFO_ARRAY(1, 1003, 1), 
MDSYS.SDO_ORDINATE_ARRAY(
524570.7, 5202359.4, 524267.6, 5202035.7, 524720, 5201928.8, 524725.1, 5201939.5, 
524739.1, 5201953.4, 524752.6, 5201964.8, 524766, 5201976.2, 524783.1, 5201991.4,
524797.6, 5202011.7, 524804.6, 5202025, 524815, 5202040.8, 524815.6, 5202042.1,
524820.6, 5202052.9, 524825.9, 5202063.1, 524834.6, 5202085.3, 524843.6, 5202099.9,
524853.9, 5202114.5, 524864.6, 5202124.6, 524868.6, 5202130, 524876.1, 5202139.8,
524890.1, 5202158.2, 524903, 5202177.8, 524914.4, 5202194.3, 524925.9, 5202214.7,
524933.5, 5202228, 524945.6, 5202245.1, 524959, 5202260.3, 524968.6, 5202276.2,
524976.9, 5202289.5, 524984.5, 5202299.6, 524987.6, 5202304.1, 524995.4, 5202314.8, 
525005.5, 5202329.5, 525016.4, 5202343.4, 525022.6, 5202354.2, 525023.2, 5202355,
524976.5, 5202359.4, 524570.7, 5202359.4)) as geom
     FROM DUAL;
BEGIN
  KML.Header('Projected Polygons');
  FOR rec IN c_KML LOOP
    KML.TO_KML(rec.geom,'Placemark for '||rec.polytype,'A test description' );
  END LOOP;
  KML.Footer;
  dbms_output.put_line(SUBSTR(KML.GetDocument,1,250));
END;
/
SHOW ERRORS

Prompt Test 2D GeoDetic points ...
set serveroutput on size unlimited format wrapped
DECLARE
  CURSOR c_kml IS
   SELECT rownum as ID,
          'Geodetic Point number ' || rownum as name,
          'Point '||rownum||' created to demonstrate what the KML package can do' as description,
          mdsys.sdo_geometry(2001,8311,
                 MDSYS.SDO_POINT_TYPE(ROUND(dbms_random.value(112,147),2),
                                      ROUND(dbms_random.value(-10,-44),2),
                                      NULL),
                 NULL,NULL) as geom
       FROM DUAL
     CONNECT BY LEVEL <= 10;
BEGIN
  KML.Header('Geodetic 2D points');
  FOR rec IN c_KML LOOP
    KML.TO_KML(rec.geom,'2D Point Placemark (' || rec.ID ||')','A test description' );
  END LOOP;
  KML.Footer;
  dbms_output.put_line(KML.GetDocument);
  --dbms_output.put_line(SUBSTR(KML.GetDocument,1,250));
END;
/
show errors

Prompt Test 3D points ...
DECLARE
  CURSOR c_kml IS
   SELECT rownum as ID,
          mdsys.sdo_geometry(3001,8311,
                   MDSYS.SDO_POINT_TYPE(
                         ROUND(dbms_random.value(112,147),2),
                         ROUND(dbms_random.value(-10,-44),2),
                         ROUND(dbms_random.value(0,10000),2)),
                   NULL,NULL) as geom
       FROM DUAL
     CONNECT BY LEVEL <= 10;
BEGIN
  KML.Header('Geodetic points');
  FOR rec IN c_KML LOOP
    KML.TO_KML(rec.geom,'Placemark '|| rec.ID,'A test description' );
  END LOOP;
  KML.Footer;
  dbms_output.put_line(SUBSTR(KML.GetDocument,1,250));
END;
/

Prompt Test Geodetic points ...
DECLARE
  CURSOR c_kml IS
   SELECT rownum as ID,
          'SIMPLE' as polytype, 
	  MDSYS.SDO_GEOMETRY(2003, 8265, NULL, 
           MDSYS.SDO_ELEM_INFO_ARRAY(1, 1003, 1),
           MDSYS.SDO_ORDINATE_ARRAY(
               -79.230383, 35.836761, -79.230381, 35.836795, -79.230414, 35.83683, -79.230468, 35.836857, 
               -79.230502, 35.836878, -79.23055, 35.836906, -79.23059, 35.836922,  -79.230617, 35.836945,
               -79.230658, 35.836966, -79.230671, 35.837005, -79.230698, 35.837048, -79.230704, 35.837082, 
               -79.230712, 35.83712, -79.230711, 35.837192, -79.230725, 35.83722, -79.230779, 35.837247, 
               -79.230792, 35.837202, -79.230785, 35.837114, -79.23078, 35.837087, -79.230765, 35.837038,
               -79.230718, 35.836972, -79.230671, 35.836917, -79.230637, 35.8369, -79.23061, 35.836873,
               -79.230583, 35.83685, -79.230529, 35.836818, -79.230489, 35.83679, -79.230456, 35.836774, 
               -79.230383, 35.836761)) as geom
     FROM DUAL a;
BEGIN
  KML.Header('Geodetic 2D Poly');
  FOR rec IN c_KML LOOP
    KML.TO_KML(rec.geom,'Polygon (' || rec.ID || ') of type ' || rec.polytype,'Test description' );
  END LOOP;
  KML.Footer;
  dbms_output.put_line(SUBSTR(KML.GetDocument,1,250));
END;
/

SELECT g.airspace_designator, 
       mdsys.sdo_util.to_gmlgeometry( G.GEOM ) as gml
  FROM (SELECT "MDSYS"."SDO_GEOMETRY"(2003,8307,NULL,
                       "MDSYS"."SDO_ELEM_INFO_ARRAY"(1,1003,1),
                       "MDSYS"."SDO_ORDINATE_ARRAY"(1.68333333333333,51.0527777777778,1.46666666666667,51,1.46638888888889,50.9047222222222,1.82027777777778,50.6486111111111,2.38916666666667,50.2283333333333,2.51333333333333,50.2283333333333,3.13138888888889,50.7280555555556,2.615,50.8433333333333,2.57138888888889,51.0155555555556,1.68333333333333,51.0527777777778)
                                     ) as geom,
               2852    as AIRSPACE_ID, 
               115     as MIN_FL, 
               999     as MAX_FL, 
               'EB'    as COUNTRY_ICAO, 
               'CBA'   as AIRSPACE_TYPE, 
               'CBA1A' as AIRSPACE_DESIGNATOR
	 FROM DUAL ) g;

select Kml.To_KML( G.GEOM,
                   G.COUNTRY_ICAO||G.AIRSPACE_TYPE||G.AIRSPACE_DESIGNATOR,
                   'COUNTRY='||G.COUNTRY_ICAO||CHR(10)||
                   'TYPE='||G.AIRSPACE_TYPE||CHR(10)||
                   'DESIGNATOR='||G.AIRSPACE_DESIGNATOR||CHR(10)
                 ) as kml
  FROM (SELECT "MDSYS"."SDO_GEOMETRY"(2003,8307,NULL,
                       "MDSYS"."SDO_ELEM_INFO_ARRAY"(1,1003,1),
                       "MDSYS"."SDO_ORDINATE_ARRAY"(1.68333333333333,51.0527777777778,1.46666666666667,51,1.46638888888889,50.9047222222222,1.82027777777778,50.6486111111111,2.38916666666667,50.2283333333333,2.51333333333333,50.2283333333333,3.13138888888889,50.7280555555556,2.615,50.8433333333333,2.57138888888889,51.0155555555556,1.68333333333333,51.0527777777778)
                                     ) as geom,
               2852    as AIRSPACE_ID, 
               115     as MIN_FL, 
               999     as MAX_FL, 
               'EB'    as COUNTRY_ICAO, 
               'CBA'   as AIRSPACE_TYPE, 
               'CBA1A' as AIRSPACE_DESIGNATOR
	 FROM DUAL ) g;

QUIT;
