DEFINE defaultSchema = '&1'

WHENEVER SQLERROR EXIT FAILURE;
set linesize 200
set serveroutput on size unlimited

DECLARE
  v_SQL   varchar2(4000);
  V_ONAME varchar2(100);
  V_OTYPE varchar2(100);
BEGIN
  IF ( '&&defaultSchema.' <> sys_context('userenv','current_schema') ) THEN
    raise_application_error(-20001,'Script must be run in schema ''&&defaultSchema.'' and not ''' || sys_context('userenv','current_schema')||'''');
  END IF;
  FOR rec in (SELECT OBJECT_NAME, OBJECT_TYPE 
                FROM SYS.ALL_OBJECTS
               WHERE owner = UPPER('&&defaultSchema.') 
                 AND OBJECT_TYPE IN ('JAVA SOURCE','JAVA CLASS','JAVA RESOURCE')
                 AND OBJECT_NAME not like 'oracle%'
               ORDER BY CASE OBJECT_TYPE WHEN 'JAVA SOURCE' THEN 1 WHEN 'JAVA CLASS' THEN 2 ELSE 3 END
             ) 
  LOOP
   BEGIN
     V_ONAME := rec.object_name;
     V_OTYPE := rec.object_type;
     if V_OTYPE='JAVA CLASS' THEN
       v_SQL := 'DROP JAVA CLASS "' || V_ONAME || '"';
     ELSIF V_OTYPE='JAVA SOURCE' THEN
       v_SQL := 'DROP JAVA SOURCE "' || V_ONAME || '"';
     ELSE
       v_SQL := 'DROP JAVA RESOURCE "' || V_ONAME || '"';
     end if;
     execute immediate v_sql;
     dbms_output.put_line('Successfully executed: ' || v_sql);
     EXCEPTION
        WHEN OTHERS THEN
          dbms_output.put_line('Failed to execute: ' || v_sql);
          /*
          IF ( V_OTYPE = 'JAVA CLASS' AND V_ONAME IS NOT NULL ) THEN
            V_ONAME := DBMS_JAVA.derivedFrom(V_ONAME, UPPER('&&defaultSchema.'), 'CLASS');
            v_SQL := 'DROP JAVA SOURCE "' || V_ONAME || '"';
            execute immediate v_sql;
            dbms_output.put_line('Tried executing: ' || v_sql);
          end if; 
          */
   END;
  END LOOP;
END;
/
show errors

purge recyclebin;

quit;

/*
              SELECT OBJECT_NAME, OBJECT_TYPE 
                FROM SYS.ALL_OBJECTS
               WHERE owner = UPPER('&&defaultSchema.') 
                 AND OBJECT_TYPE IN ('JAVA SOURCE','JAVA CLASS','JAVA RESOURCE')
                 AND(    OBJECT_NAME not like 'oracle%' or ORACLE_MAINTAINED = 'N')
                 AND (   OBJECT_NAME like 'jxl%'
                      or OBJECT_NAME like 'org/locationtech%'
                      or OBJECT_NAME like 'com.vividsolutions%'
                      or OBJECT_NAME like 'org/xBaseJ%'
                      or OBJECT_NAME like 'org/GeoTools%'
                      or OBJECT_NAME like 'com.spdba%'
                      or OBJECT_NAME like 'com/spdba%'
                      or OBJECT_NAME like 'es/%' 
                      ) 
               ORDER BY CASE OBJECT_TYPE 
                        WHEN 'JAVA SOURCE'   THEN 1 
                        WHEN 'JAVA CLASS'    THEN 2 
                        WHEN 'JAVA RESOURCE' THEN 3
                        ELSE 4 
                        END,
                        OBJECT_NAME 
*/
