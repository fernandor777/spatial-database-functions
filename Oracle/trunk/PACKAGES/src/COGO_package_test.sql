DEFINE DefaultSchema='&1'
set serveroutput on size unlimited

DECLARE
  dCX     NUMBER;
  dCY     NUMBER;
  dRadius NUMBER;
BEGIN
  cogo.FindCircle(525000, 5202000, 525500, 5202000, 525500, 5202500, dCX, dCY, dRadius);
  dbms_output.put_line('FindCircle (X,Y,R)=('||dCX||','||dCY||','||dRadius||')');
  cogo.FindCircle(525000, 5202000, 525500, 5202000, 525900, 5202000, dCX, dCY, dRadius);
  dbms_output.put_line('FindCircle (X,Y,R)=('||dCX||','||dCY||','||dRadius||')');
END;
/
show errors
Select cogo.CreateCircle(525000, 5202400, 100) from dual;
select cogo.PointFromBearingAndDistance ( 525000, 5202400, 90, 100) from dual;
Select cogo.Circle2Polygon(525000, 5202400,100, 16) from dual;
SELECT cogo.circulararc2line(10,14, 6,10, 14,10, 0.05) from dual;

Prompt Geodetic data ...
Prompt Oracle...
SELECT SDO_UTIL.CIRCLE_POLYGON(-71.34937, 42.46101, 100, 5) from dual;
Prompt COGO...
Prompt 100 meters is approx 0.00898  decimal degrees
Prompt   5 meters is approx 0.000045 decimal degrees
select cogo.CIRCLE2POLYGON(-71.34937, 42.46101, 0.000898, cogo.optimalcirclesegments(0.000898,0.000045)) from dual

Prompt Test Bearing
select cogo.Bearing(525000, 5202400,525000, 5202500) from dual;

Prompt Test GreatCircleBearing function
Prompt A. Test degrees vs radians
select cogo.GreatCircleBearing(90,0,100,0) 
            As GreatCircleBearing 
  from dual;

Prompt B. Directional Rose
select cogo.GreatCircleBearing(cogo.longitude( 90,0,0,1),0,
                               cogo.longitude(100,0,0,1),0 )
            As GreatCircleBearing from dual
union
select cogo.GreatCircleBearing(cogo.longitude( 90,0,0,1),0,
                               cogo.longitude(100,0,0,1),cogo.latitude(10,0,0,-1))
            As GreatCircleBearing from dual
union
select cogo.GreatCircleBearing(cogo.longitude( 90,0,0,1),0,
                               cogo.longitude( 90,0,0,1),cogo.latitude(10,0,0,-1))
            As GreatCircleBearing from dual
union
select cogo.GreatCircleBearing(cogo.longitude( 90,0,0,1),0,
                               cogo.longitude( 80,0,0,1),cogo.latitude(10,0,0,-1))
            As GreatCircleBearing from dual
union
select cogo.GreatCircleBearing(cogo.longitude( 90,0,0,1),0,
                               cogo.longitude( 80,0,0,1),0)
            As GreatCircleBearing from dual
union
select cogo.GreatCircleBearing(cogo.longitude( 90,0,0,1),0,
                               cogo.longitude( 80,0,0,1),cogo.latitude(10,0,0,1))
            As GreatCircleBearing from dual
union
select cogo.GreatCircleBearing(cogo.longitude( 90,0,0,1),0,
                               cogo.longitude( 90,0,0,1),cogo.latitude(10,0,0,1))
            As GreatCircleBearing from dual
union
select cogo.GreatCircleBearing(cogo.longitude( 90,0,0,1),0,
                               cogo.longitude(100,0,0,1),cogo.latitude(10,0,0,1))
            As GreatCircleBearing from dual;

select cogo.Distance(525000, 5202400,525000, 5202500) from dual;
declare
  v_ok boolean;
begin
  v_ok := &&defaultSchema..cogo.IsGeographic(8307);
  If ( v_ok ) Then
     dbms_output.put_line('isGeographic');
  else
     dbms_output.put_line('NOT isGeographic');
  end if;
end;
/
select mdsys.sdo_geom.sdo_distance(
       mdsys.sdo_geometry(2001,8307,mdsys.sdo_point_type(90,0,NULL),NULL,NULL),
       mdsys.sdo_geometry(2001,8307,mdsys.sdo_point_type(100,0,NULL),NULL,NULL),
		     0.05) 
             As Distance_90_0_to_100_0
	from dual;

select cogo.Distance(mdsys.sdo_point_type(90,0,NULL),
                     mdsys.sdo_point_type(100,0,NULL),
		     8307,
	             0.05) 
           as PointDistance_90_0_to_100_0
  from dual;

Prompt Test GreatCircleDistance functions (should return around 1113.xx km)...
Prompt A. Test degrees vs radians
select cogo.GreatCircleDistance(90,0,
                                100,0,
                                6378.137, 298.257223563 )
            As GC_Distance_90_0_to_100_0
  from dual;
Prompt 1. Hardcoded flattening for WGS84 ...
select cogo.GreatCircleDistance(cogo.longitude(90,0,0,1),0,
                                cogo.longitude(100,0,0,1),0,
                                6378.137, 298.257223563 )
            As GC_Distance_90_0_to_100_0
  from dual;
Prompt 2. Extract flattening etc for WGS84 from MDSYS metadata ...
select cogo.GreatCircleDistance(cogo.longitude(90,0,0,1),0,
                                cogo.longitude(100,0,0,1),0,
                                cogo.SRID,
                                8307,
                                NULL)
            As GC_Distance_90_0_to_100_0
  from dual;
Prompt 3. Extract flattening etc for GDA94 from MDSYS metadata ...
select cogo.GreatCircleDistance(cogo.longitude(90,0,0,1),0,
                                cogo.longitude(100,0,0,1),0,
   	                        cogo.SRID,8311,NULL)
            As GC_Distance_90_0_to_100_0
  from dual;
Prompt 4. AGD66 Tasmania
select cogo.GreatCircleDistance(cogo.longitude(90,0,0,1),0,
                                cogo.longitude(100,0,0,1),0,
   	                        cogo.SRID,8313)
            As GC_Distance_90_0_to_100_0
  from dual;
Prompt 5. Test for Ellipsoids
select Cogo.GreatCircleDistance(cogo.longitude(90,0,0,1),0,
                                cogo.longitude(100,0,0,1),0,
                                COGO.ELLIPSOID_ID,
                                ellipsoid_id) as distance_id,
       Cogo.GreatCircleDistance(cogo.longitude(90,0,0,1),0,
                                cogo.longitude(100,0,0,1),0,
                                COGO.ELLIPSOID_NAME,
                                NULL,
                                ellipsoid_name) as distance_name
  from (select ellipsoid_id,
               ellipsoid_name
         from mdsys.sdo_ellipsoids
        where ellipsoid_name = 'Australian National Spheroid'
          and rownum < 2);

DECLARE
      x11      NUMBER; 
      y11      NUMBER;
      x12      NUMBER; 
      y12      NUMBER;
      x21      NUMBER; 
      y21      NUMBER;
      x22      NUMBER; 
      y22      NUMBER;
      inter_x  NUMBER; 
      inter_y  NUMBER;
      inter_x1 NUMBER; 
      inter_y1 NUMBER;
      inter_x2 NUMBER; 
      inter_y2 NUMBER;
BEGIN
   x11 := 300000;
   y11 := 5200000;
   x12 := 300000;
   y12 := 5200100;
   x21 := 300100;
   y21 := 5200050;
   x22 := 300050;
   y22 := 5200050;
   Cogo.FindLineIntersection(x11,y11,x12,y12,x21,y21,x22,y22,inter_x,inter_y,inter_x1,inter_y1,inter_x2,inter_y2);
   dbms_output.put_line('inter_x = ' || inter_x);
   dbms_output.put_line('inter_y = ' || inter_y);
   dbms_output.put_line('inter_x1 = ' || inter_x1);
   dbms_output.put_line('inter_y1 = ' || inter_y1);
   dbms_output.put_line('inter_x2 = ' || inter_x2);
   dbms_output.put_line('inter_y2 = ' || inter_y2);
END;
/

DECLARE
      x11      NUMBER; 
      y11      NUMBER;
      x12      NUMBER; 
      y12      NUMBER;
      x21      NUMBER; 
      y21      NUMBER;
      x22      NUMBER; 
      y22      NUMBER;
      inter_x  NUMBER; 
      inter_y  NUMBER;
      inter_x1 NUMBER; 
      inter_y1 NUMBER;
      inter_x2 NUMBER; 
      inter_y2 NUMBER;
BEGIN
   x11 := 300000;
   y11 := 5200000;
   x12 := 300100;
   y12 := 5200100;
   x21 := 300500;
   y21 := 5200000;
   x22 := 300400;
   y22 := 5200100;
   Cogo.FindLineIntersection(x11,y11,x12,y12,x21,y21,x22,y22,inter_x,inter_y,inter_x1,inter_y1,inter_x2,inter_y2);
   dbms_output.put_line('inter_x = ' || inter_x);
   dbms_output.put_line('inter_y = ' || inter_y);
   dbms_output.put_line('inter_x1 = ' || inter_x1);
   dbms_output.put_line('inter_y1 = ' || inter_y1);
   dbms_output.put_line('inter_x2 = ' || inter_x2);
   dbms_output.put_line('inter_y2 = ' || inter_y2);
END;
/

Prompt CircularArc Conversion tests for rotation...
-- Top right sector with clockwise rotation...
SELECT c.startcoord.x,c.startcoord.y,c.endCoord.x,c.endCoord.y
from table(&&defaultSchema..geom.GetVector2D(
   SDO_GEOMETRY(
      2002,
      NULL,
      NULL,
      SDO_ELEM_INFO_ARRAY(1,2,2), -- compound line string
      SDO_ORDINATE_ARRAY(10,14,12.82843,12.82843,14,10)
    ),
  0.1)) c;

-- Top left sector with anti-clockwise rotation...
SELECT c.startcoord.x,c.startcoord.y,c.endCoord.x,c.endCoord.y
from table(&&defaultSchema..geom.GetVector2D(
   SDO_GEOMETRY(
      2002,
      NULL,
      NULL,
      SDO_ELEM_INFO_ARRAY(1,2,2), -- compound line string
      SDO_ORDINATE_ARRAY(10,14,7.17157,12.82843, 6,10)
    ),
  0.1)) c;

-- 3/4 of a circle starting at top and moving anti-clockwise
SELECT c.startcoord.x,c.startcoord.y,c.endCoord.x,c.endCoord.y
from table(&&defaultSchema..geom.GetVector2D(
   SDO_GEOMETRY(
      2002,
      NULL,
      NULL,
      SDO_ELEM_INFO_ARRAY(1,2,2), -- compound line string
      SDO_ORDINATE_ARRAY(10,14, 6,10, 14,10)
    ),
  0.5)) c;

-- 3/4 of a circle starting at top and moving clockwise
SELECT c.startcoord.x,c.startcoord.y,c.endCoord.x,c.endCoord.y
from table(&&defaultSchema..geom.GetVector2D(
   SDO_GEOMETRY(
      2002,
      NULL,
      NULL,
      SDO_ELEM_INFO_ARRAY(1,2,2), -- compound line string
      SDO_ORDINATE_ARRAY(10,14, 14,10, 6,10)
    ),
  0.5)) c;

-- Half-circle clockwise
SELECT c.startcoord.x,c.startcoord.y,c.endCoord.x,c.endCoord.y
from table(&&defaultSchema..geom.GetVector2D(
   SDO_GEOMETRY(
      2002,
      NULL,
      NULL,
      SDO_ELEM_INFO_ARRAY(1,2,2), -- compound line string
      SDO_ORDINATE_ARRAY(10,14, 14,10, 10,6)
    ),
  0.5)) c;

-- Half-circle anti-clockwise
SELECT c.startcoord.x,c.startcoord.y,c.endCoord.x,c.endCoord.y
from table(&&defaultSchema..geom.GetVector2D(
   SDO_GEOMETRY(
      2002,
      NULL,
      NULL,
      SDO_ELEM_INFO_ARRAY(1,2,2), -- compound line string
      SDO_ORDINATE_ARRAY(10,14, 6,10, 10,6)
    ),
  0.5)) c;

select &&defaultSchema..cogo.AngleBetween3Points(dStartX, dStartY, dCentreX, dCentreY, dMidX, dMidY),
       &&defaultSchema..cogo.AngleBetween3Points(dMidX,   dMidY,   dCentreX, dCentreY, dEndX, dEndY)
from (select 10 as dStartX,  14 as dStartY, 
             14 as dMidX,    10 as dMidY, 
              6 as dEndX,    10 as dEndY, 
             10 as dCentreX, 10 as dCentreY 
        from dual);

select &&defaultSchema..cogo.AngleBetween3Points(dStartX, dStartY, dCentreX, dCentreY, dMidX, dMidY),
       &&defaultSchema..cogo.AngleBetween3Points(dMidX,   dMidY,   dCentreX, dCentreY, dEndX, dEndY)
from (select 10 as dStartX,  14 as dStartY, 
              6 as dMidX,    10 as dMidY, 
             14 as dEndX,    10 as dEndY, 
             10 as dCentreX, 10 as dCentreY 
        from dual);

select cogo.radians(45), 
       cogo.radians(90) as one_quarter,
       cogo.radians(135), 
       cogo.radians(180) AS half_circle,
       cogo.radians(270) AS three_quarter,
       cogo.radians(315),
       cogo.radians(360) AS full_circle
  from dual;

select cogo.CircularArc2Line(
&&defaultSchema..st_point(227460.586197987, 1300573.32844073,3),
&&defaultSchema..st_point(227479.4618626,   1300556.1002334,3),
&&defaultSchema..st_point(227498.114022263, 1300538.63029401,3),0.001)
from dual
/

select cogo.CircularArc2Line(
&&defaultSchema..st_point(227460.586197987, 1300573.32844073,3,0),
&&defaultSchema..st_point(227479.4618626,   1300556.1002334,3,1),
&&defaultSchema..st_point(227498.114022263, 1300538.63029401,3,2),0.001)
from dual
/

Prompt Test Distance Method for 2D LatLong between 
Select 'Flinders Peak' || CHR(10) || ' 144°25''29.52440?E, 37°57''03.72030?S ' || CHR(10) || 
          to_char(cogo.dms2dd(144,25,29.52440),'999.99999999999') || ', ' || to_char(0-cogo.dms2dd(37,57,3.72030),'999.9999999999') || CHR(10) || 
       'Buninyong'|| CHR(10) || ' 143°55''35.38390?E, 37°39''10.15610?S' || CHR(10) || 
          to_char(cogo.dms2dd(143,55,35.38390),'999.99999999999') || ', '  || to_char(0-cogo.dms2dd(37,39,10.15610),'999.9999999999')
  from dual;
select 'Correct Distance  = 54972.271 m' || CHR(10) || 
        'Computed Distance = ' || a.mypoint.Distance(ST_Point(cogo.dms2dd(143,55,35.38390),0-cogo.dms2dd(37,39,10.15610)),8307) 
  from ( select ST_Point(cogo.dms2dd(144,25,29.52440),0-cogo.dms2dd(37,57,3.72030)) as mypoint 
           from dual) a;

select cogo.DMS2DD(-44,10,50) from dual;
select cogo.DD2DMS(cogo.DMS2DD(-44,10,50),'d','s','"') from dual;

execute cogo.SetDegreeSymbol( 'd' );
execute cogo.SetMinuteSymbol( 'm' );
execute cogo.SetSecondSymbol( '"' );
select cogo.DMS2DD('S44d10m50"') from dual;

exit;
