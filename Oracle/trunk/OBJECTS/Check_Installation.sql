set serveroutput on size unlimited format wrapped

WHENEVER SQLERROR EXIT FAILURE;

DECLARE
   v_OK       boolean       := TRUE;
   v_obj_list varchar2(500) := 'T_INTVALUE,T_TOKEN,T_ELEMINFO,T_GRID,T_VERTEX,T_SEGMENT,T_GEOMETRY_ROW,T_VECTOR3D,T_GEOMETRY,T_ELEMINFOSET,T_INTVALUES,T_TOKENS,T_VERTICES,T_SEGMENTS,T_GEOMETRIES,T_GRIDS,TOOLS,COGO,DEBUG,ST_LRS';
BEGIN
   FOR rec IN (select a.object_name as required_object,uo.object_name, uo.object_type,uo.status 
                 from (select regexp_substr(v_obj_list,'[^(,)]+', 1, level) as object_name
                         from dual
                              connect by level <= regexp_count(v_obj_list,'[^(,)]+',1)
                      ) a
                      left outer join user_objects uo on (uo.object_name = a.object_name)
               order by uo.status desc, NVL(a.object_name,uo.object_name), uo.object_type asc
   )
   LOOP
     IF ( rec.required_object is not null and rec.object_name is not null and rec.status = 'VALID' ) Then
       dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.required_object || ' is valid.');
     ELSIF ( rec.required_object is not null ) Then
       dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.required_object || ' does not exist.');
       v_ok := FALSE;
     ELSE
       dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.required_object || ' is invalid.');
       v_ok := FALSE;
     END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
     RAISE_APPLICATION_ERROR(-20000,'Installation Failed: Check Log file.');
   END IF;
END;
/
SHOW ERRORS

EXIT SUCCESS;

