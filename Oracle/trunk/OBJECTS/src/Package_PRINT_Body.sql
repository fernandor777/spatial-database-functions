DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

-- Always aim for a clean compile
ALTER SESSION SET PLSQL_WARNINGS='ERROR:ALL';

CREATE OR REPLACE PACKAGE BODY &&INSTALL_SCHEMA..PRINT
AS
  Function sdo_point_type( p_point in mdsys.sdo_point_type,
                           p_round in number default 3 )
    return varchar2
  As
  Begin
    return 'MDSYS.SDO_POINT_TYPE(' ||
                  CASE WHEN p_point.x IS NULL THEN 'NULL' ELSE TO_CHAR(ROUND(p_point.x,p_round)) END || ',' ||
                  CASE WHEN p_point.y IS NULL THEN 'NULL' ELSE TO_CHAR(ROUND(p_point.y,p_round)) END || ',' ||
                  CASE WHEN p_point.z IS NULL THEN 'NULL' ELSE TO_CHAR(ROUND(p_point.z,p_round)) END || ')';
  End sdo_point_type;

  Function vertex_type( p_point in mdsys.vertex_type,
                        p_round in number default 3)
    return varchar2
  As
  Begin
    return 'MDSYS.VERTEX_TYPE(' ||
                  CASE WHEN p_point.x  is null THEN 'NULL' ELSE ROUND(p_point.x,p_round)          END || ',' ||
                  CASE WHEN p_point.x  is null THEN 'NULL' ELSE ROUND(p_point.y,p_round)          END || ',' ||
                  CASE WHEN p_point.z  IS NULL THEN 'NULL' ELSE TO_CHAR(ROUND(p_point.z,p_round)) END || ',' ||
                  CASE WHEN p_point.w  IS NULL THEN 'NULL' ELSE TO_CHAR(ROUND(p_point.w,p_round)) END || ')';
  End vertex_type;

  Function sdo_elem_info( p_elem_info in mdsys.sdo_elem_info_array )
    return varchar2
  As
    v_text varchar2(32000);
  Begin
      IF ( p_elem_info IS NULL ) THEN
      v_text := v_text || 'NULL,';
    ELSE
      v_text := v_text || 'MDSYS.SDO_ELEM_INFO_ARRAY(';
      FOR i IN p_elem_info.FIRST..p_elem_info.LAST LOOP
          v_text := v_text || p_elem_info(i);
          If ( i <> p_elem_info.LAST ) THEN
            v_text := v_text || ',';
          END IF;
      END LOOP;
      v_text := v_text || ')';
    END IF;
    return v_text;
  End sdo_elem_info;

  Function Sdo_Ordinates(p_ordinates in mdsys.sdo_ordinate_array,
                         p_coordDim  in pls_integer default 2,
                         p_round     in pls_integer default 3)
    return CLOB
  As
    v_ordinates clob;
  Begin
    IF ( p_ordinates IS NULL ) THEN
      RETURN 'NULL)';
    END IF;

    SYS.DBMS_LOB.CreateTemporary( v_ordinates, TRUE, SYS.DBMS_LOB.CALL );    
    SYS.DBMS_LOB.APPEND(v_ordinates,'MDSYS.SDO_ORDINATE_ARRAY(');
    FOR i IN p_ordinates.FIRST..p_ordinates.LAST LOOP
        SYS.DBMS_LOB.APPEND(v_ordinates,
                            case when p_ordinates(i) is null 
                                 then 'NULL' 
                                 else to_char(round(p_ordinates(i),p_round)) 
                             end);
        If ( i <> p_ordinates.LAST ) THEN
          SYS.DBMS_LOB.APPEND(v_ordinates,','); 
        END IF;
    END LOOP;
    SYS.DBMS_LOB.APPEND(v_ordinates,')');
    Return v_ordinates;
  End Sdo_Ordinates;

  Function sdo_geometry( p_geom  in mdsys.sdo_geometry,
                         p_round in number default 3)
    Return clob
  As
    v_coordDim integer := 2;
    v_geom     CLOB;
  begin
    if ( p_geom is null ) then
      Return 'NULL';
    End If;
    v_coordDim := TRUNC(p_geom.sdo_gtype / 1000);
    SYS.DBMS_LOB.CreateTemporary( v_geom, TRUE, SYS.DBMS_LOB.CALL );
    SYS.DBMS_LOB.APPEND(v_geom,'MDSYS.SDO_GEOMETRY('); 
    SYS.DBMS_LOB.APPEND(v_geom,Case When P_Geom.Sdo_Gtype Is Null Then 'NULL' Else To_Char(P_Geom.Sdo_Gtype,'FM9999') End || ',');
    SYS.DBMS_LOB.APPEND(v_geom,CASE WHEN p_geom.SDO_SRID  IS NULL THEN 'NULL' ELSE TO_CHAR(p_geom.SDO_SRID)           END || ',');
    SYS.DBMS_LOB.APPEND(v_geom,CASE WHEN p_geom.SDO_POINT IS NULL THEN 'NULL,'
                                     ELSE &&INSTALL_SCHEMA..PRINT.sdo_point_type(
                                                          p_point => p_geom.sdo_point,
                                                          p_round => p_round) || ','
                                 END);
    IF ( p_geom.sdo_elem_info IS NULL ) THEN
      SYS.DBMS_LOB.APPEND(v_geom,'NULL,');
    elsif ( p_geom.sdo_elem_info.count = 0 ) then
      SYS.DBMS_LOB.APPEND(v_geom,'MDSYS.SDO_ELEM_INFO_ARRAY()');
    ELSE
      SYS.DBMS_LOB.APPEND(v_geom,&&INSTALL_SCHEMA..PRINT.sdo_elem_info(p_geom.sdo_elem_info));
      SYS.DBMS_LOB.APPEND(v_geom,','); 
    END IF;
    IF ( p_geom.sdo_ordinates IS NULL ) THEN
      SYS.DBMS_LOB.APPEND(v_geom,'NULL)');
    elsif ( p_geom.sdo_ordinates.count = 0 ) then
      SYS.DBMS_LOB.APPEND(v_geom,'MDSYS.SDO_ORDINATE_ARRAY())');
    ELSE
      SYS.DBMS_LOB.APPEND(v_geom,
                          &&INSTALL_SCHEMA..PRINT.sdo_ordinates(
                             p_ordinates => p_geom.sdo_ordinates,
                             p_coordDim  => v_coordDim,
                             p_round     => p_round
                          )
                          );
      SYS.DBMS_LOB.APPEND(v_geom,')');
    END IF;
    Return v_geom;
  End sdo_geometry;

end PRINT;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := FALSE;
   v_obj_name varchar2(30) := 'PRINT';
BEGIN
   FOR rec IN (select object_name,object_Type, status
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'PACKAGE BODY'
               order by object_type
              ) 
   LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is valid.');
         v_ok := TRUE;
      ELSE
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is invalid.');
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

EXIT SUCCESS;

