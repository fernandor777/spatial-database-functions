DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

-- Always aim for a clean compile
ALTER SESSION SET PLSQL_WARNINGS='ERROR:ALL';
-- Enable optimizations
ALTER SESSION SET plsql_optimize_level=2;

CREATE OR REPLACE PACKAGE BODY &&INSTALL_SCHEMA..DEBUG
AS

  Procedure PrintPoint( p_point  in mdsys.sdo_point_type,
                        p_round  in number default 3,
                        p_prefix in varchar2 default null,
                        p_linefeed in boolean default false )
  As
  Begin
    dbms_output.put(p_prefix || '(x,y,z) = (' ||
                               ROUND(p_point.x,p_round) || ',' ||
                               ROUND(p_point.y,p_round) || ',' ||
                               CASE WHEN p_point.z IS NULL THEN 'NULL' ELSE TO_CHAR(ROUND(p_point.z,p_round)) END || ')');
    IF ( p_linefeed ) THEN
      dbms_output.put_line('');
    END IF;
  End PrintPoint;

  Procedure PrintPoint( p_point  in mdsys.vertex_type,
                        p_round  in number default 3,
                        p_prefix in varchar2 default null,
                        p_linefeed in boolean default false )
  As
  Begin
    dbms_output.put(p_prefix || '(id,x,y,z,w) = (' ||
                               CASE WHEN p_point.id IS NULL THEN 'NULL' ELSE TO_CHAR(p_point.id) END || ',' ||
                               ROUND(p_point.x,p_round) || ',' ||
                               ROUND(p_point.y,p_round) || ',' ||
                               CASE WHEN p_point.z IS NULL THEN 'NULL' ELSE TO_CHAR(ROUND(p_point.z,p_round)) END || ',' ||
                               CASE WHEN p_point.w IS NULL THEN 'NULL' ELSE TO_CHAR(ROUND(p_point.w,p_round)) END || ')');
    IF ( p_linefeed ) THEN
      dbms_output.put_line('');
    END IF;
  End PrintPoint;

  Procedure PrintPoint( p_point  in &&INSTALL_SCHEMA..T_Vertex,
                        p_round  in number default 3,
                        p_prefix in varchar2 default null,
                        p_linefeed in boolean default false)
  As
  Begin
    dbms_output.put(p_prefix || '(id,x,y,z,w) = (' ||
                               CASE WHEN p_point.id IS NULL THEN 'NULL' ELSE TO_CHAR(p_point.id) END || ',' ||
                               ROUND(p_point.x,p_round) || ',' ||
                               ROUND(p_point.y,p_round) || ',' ||
                               CASE WHEN p_point.z IS NULL THEN 'NULL' ELSE TO_CHAR(ROUND(p_point.z,p_round)) END || ',' ||
                               CASE WHEN p_point.w IS NULL THEN 'NULL' ELSE TO_CHAR(ROUND(p_point.w,p_round)) END || ')');
    IF ( p_linefeed ) THEN
      dbms_output.put_line('');
    END IF;
  End PrintPoint;

  Procedure PrintGeom( p_geom        in mdsys.sdo_geometry,
                       p_round       in number default 3,
                       p_linefeed    in Boolean default false,
                       p_suffix_text in varchar2 default null)
  As
    v_coordDim integer := 2;
  begin
    if ( p_suffix_text is not null ) then
      dbms_output.put(p_suffix_text);
    End If;
    if ( p_geom is null ) then
      Dbms_Output.Put_Line('NULL');
      RETURN;
    End If;
    v_coordDim := TRUNC(p_geom.sdo_gtype / 1000);
    Dbms_Output.Put('MDSYS.SDO_GEOMETRY('); If (P_Linefeed ) Then Dbms_Output.Put_Line(''); End If;
    Dbms_Output.Put(Case When P_Geom.Sdo_Gtype Is Null Then 'NULL' Else To_Char(P_Geom.Sdo_Gtype,'FM9999') End || ',');
    dbms_output.put(CASE WHEN p_geom.SDO_SRID  IS NULL THEN 'NULL' ELSE TO_CHAR(p_geom.SDO_SRID)           END || ',');
    dbms_output.put(CASE WHEN p_geom.SDO_POINT IS NULL THEN 'NULL,'
                              ELSE 'MDSYS.SDO_POINT_TYPE(' ||
                                   CASE WHEN p_geom.sdo_point.x IS NULL THEN 'NULL' ELSE TO_CHAR(ROUND(p_geom.sdo_point.x,p_round)) END || ',' ||
                                   CASE WHEN p_geom.sdo_point.y IS NULL THEN 'NULL' ELSE TO_CHAR(ROUND(p_geom.sdo_point.y,p_round)) END || ',' ||
                                   CASE WHEN p_geom.sdo_point.z IS NULL THEN 'NULL' ELSE TO_CHAR(ROUND(p_geom.sdo_point.z,p_round)) END || '),'
                          END );

    IF ( p_geom.sdo_elem_info IS NULL ) THEN
      dbms_output.put('NULL,');
    elsif ( p_geom.sdo_elem_info.count = 0 ) then
      dbms_output.put('MDSYS.SDO_ELEM_INFO_ARRAY()');
      If ( p_linefeed ) Then dbms_output.put_line(','); Else dbms_output.put(','); End If;
    ELSE
      dbms_output.put('MDSYS.SDO_ELEM_INFO_ARRAY(');
      FOR i IN p_geom.sdo_elem_info.FIRST..p_geom.sdo_elem_info.LAST LOOP
          dbms_output.put(p_geom.sdo_elem_info(i));
          If ( i <> p_geom.sdo_elem_info.LAST ) THEN
            If ( p_linefeed And ( 0 = MOD(i,3) )) Then dbms_output.put_line(','); Else dbms_output.put(','); End If;
          END IF;
      END LOOP;
      If ( p_linefeed ) Then dbms_output.put_line('),'); Else dbms_output.put('),'); End If;
    END IF;

    IF ( p_geom.sdo_ordinates IS NULL ) THEN
      dbms_output.put_line('NULL)');
    elsif ( p_geom.sdo_ordinates.count = 0 ) then
      dbms_output.put_line('MDSYS.SDO_ORDINATE_ARRAY())');
    ELSE
      dbms_output.put('MDSYS.SDO_ORDINATE_ARRAY(');
      FOR i IN p_geom.sdo_ordinates.FIRST..p_geom.sdo_ordinates.LAST LOOP
          dbms_output.put(case when p_geom.sdo_ordinates(i) is null
                               then 'NULL'
                               else to_char(round(p_geom.sdo_ordinates(i),NVL(p_round,3)))
                          end);
          If ( i <> p_geom.sdo_ordinates.LAST ) THEN
             If ( p_linefeed And ( 0 = MOD(i,v_coordDim) )) Then
                dbms_output.put_line(',');
             Else
                dbms_output.put(',');
             End If;
          END IF;
      END LOOP;
      dbms_output.put_line('))');
    END IF;
  End PrintGeom;

  Procedure PrintGeom( p_geom        in &&INSTALL_SCHEMA..T_Geometry,
                       p_round       in number default 3,
                       p_linefeed    in boolean default false,
                       p_suffix_text in varchar2 default null)
  As
  begin
    if ( p_suffix_text is not null ) then
      dbms_output.put(p_suffix_text);
    End If;
    if ( p_geom is null ) then
      dbms_output.put_Line('NULL');
      return;
    end if;
    dbms_output.put('&&INSTALL_SCHEMA..T_GEOMETRY('); if (p_linefeed ) then dbms_output.put_line(''); end if;
    &&INSTALL_SCHEMA..DEBUG.printgeom(case when p_geom is not null then p_geom.geom else null end,p_round,p_linefeed);
    dbms_output.put_line(')');
  end printgeom;

  Function PrintGeom( p_geom     in mdsys.sdo_geometry,
                      p_round    in number default 3,
                      p_linefeed in integer default 0,
                      p_prefix   in varchar2 default null,
                      p_relative in integer default 0)
    Return clob 
  As
    v_coordDim integer := 2;
    v_linefeed boolean := case when NVL(p_linefeed,0)=0 then false else true end;
    v_x        number;
    v_y        number;
    v_z        number;
    v_w        number;
    v_geom     CLOB;
  begin
    if ( p_geom is null ) then
      Return NULL;
    End If;
    v_coordDim := TRUNC(p_geom.sdo_gtype / 1000);    
    SYS.DBMS_LOB.CreateTemporary( v_geom, TRUE, SYS.DBMS_LOB.CALL );
    if ( p_prefix is not null ) then
      SYS.DBMS_LOB.APPEND(v_geom,p_prefix);
    End If;
    SYS.DBMS_LOB.APPEND(v_geom,'MDSYS.SDO_GEOMETRY('); If (v_linefeed) Then SYS.DBMS_LOB.APPEND(v_geom,''); End If;
    SYS.DBMS_LOB.APPEND(v_geom,Case When P_Geom.Sdo_Gtype Is Null Then 'NULL' Else To_Char(P_Geom.Sdo_Gtype,'FM9999') End || ',');
    SYS.DBMS_LOB.APPEND(v_geom,CASE WHEN p_geom.SDO_SRID  IS NULL THEN 'NULL' ELSE TO_CHAR(p_geom.SDO_SRID)           END || ',');
    SYS.DBMS_LOB.APPEND(v_geom,CASE WHEN p_geom.SDO_POINT IS NULL THEN 'NULL,'
                                     ELSE 'MDSYS.SDO_POINT_TYPE(' ||
                                          CASE WHEN p_geom.sdo_point.x IS NULL THEN 'NULL' ELSE TO_CHAR(ROUND(p_geom.sdo_point.x,p_round)) END || ',' ||
                                          CASE WHEN p_geom.sdo_point.y IS NULL THEN 'NULL' ELSE TO_CHAR(ROUND(p_geom.sdo_point.y,p_round)) END || ',' ||
                                          CASE WHEN p_geom.sdo_point.z IS NULL THEN 'NULL' ELSE TO_CHAR(ROUND(p_geom.sdo_point.z,p_round)) END || '),'
                                 END);

    IF ( p_geom.sdo_elem_info IS NULL ) THEN
      SYS.DBMS_LOB.APPEND(v_geom,'NULL,');
    elsif ( p_geom.sdo_elem_info.count = 0 ) then
      SYS.DBMS_LOB.APPEND(v_geom,'MDSYS.SDO_ELEM_INFO_ARRAY()');
      If ( v_linefeed ) Then SYS.DBMS_LOB.APPEND(v_geom,','); Else SYS.DBMS_LOB.APPEND(v_geom,','); End If;
    ELSE
      SYS.DBMS_LOB.APPEND(v_geom,'MDSYS.SDO_ELEM_INFO_ARRAY(');
      FOR i IN p_geom.sdo_elem_info.FIRST..p_geom.sdo_elem_info.LAST LOOP
          SYS.DBMS_LOB.APPEND(v_geom,to_char(p_geom.sdo_elem_info(i)));
          If ( i <> p_geom.sdo_elem_info.LAST ) THEN
            If ( v_linefeed And ( 0 = MOD(i,3) )) Then SYS.DBMS_LOB.APPEND(v_geom,','); Else SYS.DBMS_LOB.APPEND(v_geom,','); End If;
          END IF;
      END LOOP;
      If ( v_linefeed ) Then SYS.DBMS_LOB.APPEND(v_geom,'),'); Else SYS.DBMS_LOB.APPEND(v_geom,'),'); End If;
    END IF;

    IF ( p_geom.sdo_ordinates IS NULL ) THEN
      SYS.DBMS_LOB.APPEND(v_geom,'NULL)');
    elsif ( p_geom.sdo_ordinates.count = 0 ) then
      SYS.DBMS_LOB.APPEND(v_geom,'MDSYS.SDO_ORDINATE_ARRAY())');
    ELSE
      SYS.DBMS_LOB.APPEND(v_geom,'MDSYS.SDO_ORDINATE_ARRAY(');
      FOR i IN p_geom.sdo_ordinates.FIRST..p_geom.sdo_ordinates.LAST LOOP
          SYS.DBMS_LOB.APPEND(v_geom,case when p_geom.sdo_ordinates(i) is null
                                           then 'NULL'
                                           else to_char(round(p_geom.sdo_ordinates(i),NVL(p_round,3)))
                                      end);
          If ( i <> p_geom.sdo_ordinates.LAST ) THEN
             If ( v_linefeed And ( 0 = MOD(i,v_coordDim) )) Then
                SYS.DBMS_LOB.APPEND(v_geom,',');
             Else
                SYS.DBMS_LOB.APPEND(v_geom,',');
             End If;
          END IF;
      END LOOP;
      SYS.DBMS_LOB.APPEND(v_geom,'))');
    END IF;
    Return v_geom;
  End PrintGeom;

  Procedure PrintElemInfo( p_elem_info in mdsys.sdo_elem_info_array,
                           p_linefeed  in Boolean default false)
  As
  Begin
      IF ( p_elem_info IS NULL ) THEN
      dbms_output.put('NULL,');
    ELSE
      dbms_output.put('MDSYS.SDO_ELEM_INFO_ARRAY(');
      FOR i IN p_elem_info.FIRST..p_elem_info.LAST LOOP
          dbms_output.put(p_elem_info(i));
          If ( i <> p_elem_info.LAST ) THEN
            If ( p_linefeed And ( 0 = MOD(i,3) )) Then dbms_output.put_line(','); Else dbms_output.put(','); End If;
          END IF;
      END LOOP;
      dbms_output.put_line(')');
    END IF;
  End PrintElemInfo;

  Procedure PrintOrdinates(p_ordinates in mdsys.sdo_ordinate_array,
                           p_coordDim  in pls_integer default 2,
                           p_round     in pls_integer default 3,
                           p_linefeed  in Boolean default false)
  As
  Begin
    IF ( p_ordinates IS NULL ) THEN
      dbms_output.put_line('NULL)');
    ELSE
      dbms_output.put('MDSYS.SDO_ORDINATE_ARRAY(');
      FOR i IN p_ordinates.FIRST..p_ordinates.LAST LOOP
          dbms_output.put(case when p_ordinates(i) is null then 'NULL' else to_char(round(p_ordinates(i),p_round)) end);
          If ( i <> p_ordinates.LAST ) THEN
             If ( p_linefeed And ( 0 = MOD(i,p_coordDim) )) Then dbms_output.put_line(','); Else dbms_output.put(','); End If;
          END IF;
      END LOOP;
      dbms_output.put_line('))');
    END IF;
  End PrintOrdinates;

end DEBUG;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean      := FALSE;
   v_obj_name varchar2(30) := 'DEBUG';
BEGIN
   FOR rec IN (select object_name,object_Type, status 
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'PACKAGE BODY'
                order by object_type) LOOP
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

