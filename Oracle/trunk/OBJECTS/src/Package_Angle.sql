DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

CREATE OR REPLACE EDITIONABLE PACKAGE "&&INSTALL_SCHEMA."."ANGLE" 
AUTHID CURRENT_USER
AS

  Function angle(p in T_Vertex) return number deterministic;
  Function angle(p0 in T_Vertex, p1 in T_Vertex)  return number deterministic;
  Function angleBetween(tip1 in T_Vertex, tail in T_Vertex, tip2 in T_Vertex)  return number deterministic;
  Function angleBetweenOriented(tip1 in T_Vertex, tail in T_Vertex, tip2 in T_Vertex)  return number deterministic;
  Function diff(ang1 in number, ang2 in number)  return number deterministic;
  Function toRadians(angleDegrees in number) return number deterministic;
  Function getTurn(p_ang1 in number, p_ang2 in number)  return integer deterministic;
  Function interiorAngle(p0 in T_Vertex, p1 in T_Vertex, p2 in T_Vertex) return number deterministic;
  Function isAcute(p0 in T_Vertex, p1 in T_Vertex, p2 in T_Vertex) return boolean deterministic;
  Function isObtuse(p0 in T_Vertex, p1 in T_Vertex, p2 in T_Vertex) return boolean deterministic;
  Function normalize(p_angle in number) return number deterministic;
  Function normalizePositive(p_angle in number) return number deterministic;
  Function toDegrees(radians in number) return number deterministic;

End Angle;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean      := FALSE;
   v_obj_name varchar2(30) := 'ANGLE';
BEGIN
   FOR rec IN (select object_name,object_Type, status 
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'PACKAGE'
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
   EXECUTE IMMEDIATE 'GRANT EXECUTE ON &&INSTALL_SCHEMA..' || v_obj_name || ' TO public WITH GRANT OPTION';
END;
/
SHOW ERRORS

EXIT SUCCESS;

