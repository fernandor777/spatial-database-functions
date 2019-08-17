set serveroutput on size unlimited format wrapped
declare
    v_point_on_point  mdsys.sdo_geometry;
    v_point_on_line   mdsys.sdo_geometry;
    v_distance        number;
  begin
    -- Compute closest point
    -- DEBUG dbms_output.put_line('T_VECTOR.ST_DISTANCE: SDO_CLOSEST_POINTS');
    -- SDO_CLOSEST_POINTS:
    -- A. if Geodetic must be 3D SRID otherwise get rubbish.
    -- B. If Locator then both geom1/geom2 must be 2D
    -- C. If Spatial then don't mix dimensions eg 3001/4402
    --
    -- POINTS and LINESTRINGS (Spatial)
    dbms_output.put_line('2D test, point near line');
    --select SDO_GEOMETRY(2001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,2))as geom from dual union all
    --select SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2, 2,4, 8,4, 12,4, 12,10, 8,10, 5,14.0)) as geom from dual;    
    mdsys.sdo_geom.SDO_CLOSEST_POINTS(
         geom1     => SDO_GEOMETRY(2001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,2)),
         geom2     => SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2, 2,4, 8,4, 12,4, 12,10, 8,10, 5,14.0)),
         tolerance => 0.005,
         unit      => NULL,
         dist      => v_distance,
         geoma     => v_point_on_point,
         geomb     => v_point_on_line
    );
    debug.printGeom(v_point_on_point,3,false,'2001 point_on_point    : ');
    debug.printGeom(v_point_on_line, 3,false,'     point_on_line 2002: ');

    dbms_output.put_line(CHR(10)||'2D test, with Point outside linestring end');
    --select SDO_GEOMETRY(2001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(0,0)) as geom from dual union all
    --select SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2, 2,4, 8,4, 12,4, 12,10, 8,10, 5,14.0)) as geom from dual;
    mdsys.sdo_geom.SDO_CLOSEST_POINTS(
         geom1     => SDO_GEOMETRY(2001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(0,0)),
         geom2     => SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2, 2,4, 8,4, 12,4, 12,10, 8,10, 5,14.0)),
         tolerance => 0.005,
         unit      => NULL,
         dist      => v_distance,
         geoma     => v_point_on_point,
         geomb     => v_point_on_line
    );
    debug.printGeom(v_point_on_point,3,false,'2001 point_on_point    : ');
    debug.printGeom(v_point_on_line, 3,false,'     point_on_line 2002: ');

    dbms_output.put_line(CHR(10)||'2D test for CircularArc with Point outside CircularStringend');
--select SDO_GEOMETRY(2001,NULL,MDSYS.SDO_POINT_TYPE(10,0,NULL),NULL,NULL) as geom from dual union all
--select SDO_GEOMETRY(2001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(5,-5)) as geom from dual union all
--select SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(0,0,5,5,10,0)) as geom from dual;
    mdsys.sdo_geom.SDO_CLOSEST_POINTS(
         geom1     => SDO_GEOMETRY(2001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(5,1)),
         geom2     => SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(0,0,5,5,10,0)),
         tolerance => 0.005,
         unit      => NULL,
         dist      => v_distance,
         geoma     => v_point_on_point,
         geomb     => v_point_on_line
    );
    debug.printGeom(v_point_on_point,3,false,'2001 point_on_point    : ');
    debug.printGeom(v_point_on_line, 3,false,'     point_on_line 2002: ');
 
    dbms_output.put_line(CHR(10)||'2D/3D(Z) test => 2D point as result');
    mdsys.sdo_geom.SDO_CLOSEST_POINTS(
         geom1     => SDO_GEOMETRY(2001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,2)),
         geom2     => SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,0, 2,4,3.218, 8,4,12.872, 12,4,19.308, 12,10,28.962, 8,10,35.398, 5,14,43.443)),
         tolerance => 0.005,
         unit      => NULL,
         dist      => v_distance,
         geoma     => v_point_on_point,
         geomb     => v_point_on_line
    );
    debug.printGeom(v_point_on_point,3,false,'2001 point_on_point    : ');
    debug.printGeom(v_point_on_line, 3,false,'     point_on_line 3002: ');

    dbms_output.put_line(CHR(10)||'2D/3D(M) test => 2D point as result');
    mdsys.sdo_geom.SDO_CLOSEST_POINTS(
         geom1     => SDO_GEOMETRY(2001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,2)),
         geom2     => SDO_GEOMETRY(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,0, 2,4,3.218, 8,4,12.872, 12,4,19.308, 12,10,28.962, 8,10,35.398, 5,14,43.443)),
         tolerance => 0.005,
         unit      => NULL,
         dist      => v_distance,
         geoma     => v_point_on_point,
         geomb     => v_point_on_line
    );
    debug.printGeom(v_point_on_point,3,false,'2001 point_on_point    : ');
    debug.printGeom(v_point_on_line, 3,false,'     point_on_line 3302: ');

    dbms_output.put_line(CHR(10)||'3D(Z)/4D(MZ) test => 2D point result');
    mdsys.sdo_geom.SDO_CLOSEST_POINTS(
         geom1     => SDO_GEOMETRY(2001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,2)),
         geom2     => SDO_GEOMETRY(4302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,0,1.1, 2,4,3.218,1.2, 8,4,12.872,1.1, 12,4,19.308,1, 12,10,28.962,1.3, 8,10,35.398,1.4, 5,14,43.443,1.2)),
         tolerance => 0.005,
         unit      => NULL,
         dist      => v_distance,
         geoma     => v_point_on_point,
         geomb     => v_point_on_line
    );
    debug.printGeom(v_point_on_point,3,false,'2001 point_on_point    : ');
    debug.printGeom(v_point_on_line, 3,false,'     point_on_line 4302: ');

    dbms_output.put_line(CHR(10)||'4D(ZM) Point /4D(MZ) test => 2D point result');
    mdsys.sdo_geom.SDO_CLOSEST_POINTS(
         geom1     => SDO_GEOMETRY(2001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,2)),
         geom2     => SDO_GEOMETRY(4402,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,1.1,0, 2,4,1.2,3.218, 8,4,1.1,12.872, 12,4,1,19.308, 12,10,1.3,28.962, 8,10,1.4,35.398, 5,14,1.2,43.443)),
         tolerance => 0.005,
         unit      => NULL,
         dist      => v_distance,
         geoma     => v_point_on_point,
         geomb     => v_point_on_line
    );
    debug.printGeom(v_point_on_point,3,false,'2001 point_on_point    : ');
    debug.printGeom(v_point_on_line, 3,false,'     point_on_line 4402: ');

    dbms_output.put_line(CHR(10)||'-- *********************************************************');

    dbms_output.put_line(CHR(10)||'3D(Z)/2D test -> 2D point returned');
    mdsys.sdo_geom.SDO_CLOSEST_POINTS(
         geom1     => SDO_GEOMETRY(3001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,2,9.0)),
         geom2     => SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2, 2,4, 8,4, 12,4, 12,10, 8,10, 5,14)),
         tolerance => 0.005,
         unit      => NULL,
         dist      => v_distance,
         geoma     => v_point_on_point,
         geomb     => v_point_on_line
    );
    debug.printGeom(v_point_on_point,3,false,'3001 point_on_point    : ');
    debug.printGeom(v_point_on_line, 3,false,'     point_on_line 2002: ' );

    dbms_output.put_line(CHR(10)||'3D(Z)/3D(Z) test -> 3D point returned');
    mdsys.sdo_geom.SDO_CLOSEST_POINTS(
         geom1     => SDO_GEOMETRY(3001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,2,9.0)),
         geom2     => SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,0, 2,4,3.218, 8,4,12.872, 12,4,19.308, 12,10,28.962, 8,10,35.398, 5,14,43.443)),
         tolerance => 0.005,
         unit      => NULL,
         dist      => v_distance,
         geoma     => v_point_on_point,
         geomb     => v_point_on_line
    );
    debug.printGeom(v_point_on_point,3,false,'3001 point_on_point    : ');
    debug.printGeom(v_point_on_line, 3,false,'     point_on_line 3002: ' );

    dbms_output.put_line(CHR(10)||'3D/3D(M) test -> result 3DM point with measure');
    -- select SDO_GEOMETRY(3001,NULL,SDO_POINT_TYPE(7.161,4,11.522),NULL,NULL) as geom from dual;
    mdsys.sdo_geom.SDO_CLOSEST_POINTS(
         geom1     => SDO_GEOMETRY(3001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,2,11)),
         geom2     => SDO_GEOMETRY(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,0, 2,4,3.218, 8,4,12.872, 12,4,19.308, 12,10,28.962, 8,10,35.398, 5,14,43.443)),
         tolerance => 0.005,
         unit      => NULL,
         dist      => v_distance,
         geoma     => v_point_on_point,
         geomb     => v_point_on_line
    );
    debug.printGeom(v_point_on_point,3,false,'3001 point_on_point    : ');
    debug.printGeom(v_point_on_line, 3,false,'     point_on_line 3302: ');

    dbms_output.put_line(CHR(10)||'3D(M)/3D(M) test: result is 3D point with no measure sdo_gtype but has M ordinate');
    mdsys.sdo_geom.SDO_CLOSEST_POINTS(
         geom1     => SDO_GEOMETRY(3301,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,2,11)),
         geom2     => SDO_GEOMETRY(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,0, 2,4,3.218, 8,4,12.872, 12,4,19.308, 12,10,28.962, 8,10,35.398, 5,14,43.443)),
         tolerance => 0.005,
         unit      => NULL,
         dist      => v_distance,
         geoma     => v_point_on_point,
         geomb     => v_point_on_line
    );
    debug.printGeom(v_point_on_point,3,false,'3301 point_on_point    : ');
    debug.printGeom(v_point_on_line, 3,false,'     point_on_line 3302: ');

    dbms_output.put_line(CHR(10)||'3D(Z)/4D(MZ) test => 2D point result');
    mdsys.sdo_geom.SDO_CLOSEST_POINTS(
         geom1     => SDO_GEOMETRY(3001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,2,11)),
         geom2     => SDO_GEOMETRY(4302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,0,1.1, 2,4,3.218,1.2, 8,4,12.872,1.1, 12,4,19.308,1, 12,10,28.962,1.3, 8,10,35.398,1.4, 5,14,43.443,1.2)),
         tolerance => 0.005,
         unit      => NULL,
         dist      => v_distance,
         geoma     => v_point_on_point,
         geomb     => v_point_on_line
    );
    debug.printGeom(v_point_on_point,3,false,'3001 point_on_point    : ');
    debug.printGeom(v_point_on_line, 3,false,'     point_on_line 4302: ');

    dbms_output.put_line(CHR(10)||'3D(M)/4D(MZ) test => 2D point result');
    mdsys.sdo_geom.SDO_CLOSEST_POINTS(
         geom1     => SDO_GEOMETRY(3301,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,2,11)),
         geom2     => SDO_GEOMETRY(4302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,0,1.1, 2,4,3.218,1.2, 8,4,12.872,1.1, 12,4,19.308,1, 12,10,28.962,1.3, 8,10,35.398,1.4, 5,14,43.443,1.2)),
         tolerance => 0.005,
         unit      => NULL,
         dist      => v_distance,
         geoma     => v_point_on_point,
         geomb     => v_point_on_line
    );
    debug.printGeom(v_point_on_point,3,false,'3301 point_on_point    : ');
    debug.printGeom(v_point_on_line, 3,false,'     point_on_line 4302: ');

    dbms_output.put_line(CHR(10)||'3D(M)/4D(ZM) test. Result is 2D point');
    mdsys.sdo_geom.SDO_CLOSEST_POINTS(
         geom1     => SDO_GEOMETRY(3301,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,2,1.1)),
         geom2     => SDO_GEOMETRY(4402,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,1.1,0, 2,4,1.2,3.218, 8,4,1.1,12.872, 12,4,1,19.308, 12,10,1.3,28.962, 8,10,1.4,35.398, 5,14,1.2,43.443)),
         tolerance => 0.005,
         unit      => NULL,
         dist      => v_distance,
         geoma     => v_point_on_point,
         geomb     => v_point_on_line
    );
    debug.printGeom(v_point_on_point,3,false,'3301 point_on_point    : ');
    debug.printGeom(v_point_on_line, 3,false,'     point_on_line 4402: ');

    dbms_output.put_line(CHR(10)||'3D(Z)/4D test. Result is 2D point');
    mdsys.sdo_geom.SDO_CLOSEST_POINTS(
         geom1     => SDO_GEOMETRY(3001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,2,1.1)),
         geom2     => SDO_GEOMETRY(4002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,1.1,0, 2,4,1.2,3.218, 8,4,1.1,12.872, 12,4,1,19.308, 12,10,1.3,28.962, 8,10,1.4,35.398, 5,14,1.2,43.443)),
         tolerance => 0.005,
         unit      => NULL,
         dist      => v_distance,
         geoma     => v_point_on_point,
         geomb     => v_point_on_line
    );
    debug.printGeom(v_point_on_point,3,false,'3001 point_on_point    : ');
    debug.printGeom(v_point_on_line, 3,false,'     point_on_line 4002: ');

    dbms_output.put_line(CHR(10)||'-- *********************************************************');
    
    dbms_output.put_line(CHR(10)||'4D(ZM) Point /4D(MZ) test => 2D point result');
    mdsys.sdo_geom.SDO_CLOSEST_POINTS(
         geom1     => SDO_GEOMETRY(4301,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(8,2,11.1,1.1)),
         geom2     => SDO_GEOMETRY(4302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(2,2,0,1.1, 2,4,3.218,1.2, 8,4,12.872,1.1, 12,4,19.308,1, 12,10,28.962,1.3, 8,10,35.398,1.4, 5,14,43.443,1.2)),
         tolerance => 0.005,
         unit      => NULL,
         dist      => v_distance,
         geoma     => v_point_on_point,
         geomb     => v_point_on_line
    );
    debug.printGeom(v_point_on_point,3,false,'4301 point_on_point    : ');
    debug.printGeom(v_point_on_line, 3,false,'     point_on_line 4302: ');

END;
/

/*
** RULES
** 2D point returns 2D point for 2D, 3D or 4D linestring.
** 3D (with/without measure) or 4D point returns 2D point for any 4D linestring.
** Points off the end return the end point of nearest linestring.
** 3D(Z) Point close to 3D(Z) linestrnig returns nearest 3D(Z) point.
** 3D(Z) Point close to 3D(M) linestring returns 3D(Z) point where Z is computed from actual M linestring ordinate.
**       Change sdo_gtype from 3001 to 3301.
** 3D(M) Point close to 3D(M) linestring returns 3D(Z) point where Z is computed from actual M linestring ordinate.
**       Change sdo_gtype from 3001 to 3301.
*/
