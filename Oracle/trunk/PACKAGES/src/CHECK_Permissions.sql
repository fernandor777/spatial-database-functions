DEFINE defaultSchema='&1'

Prompt Check if have necessary permissions 

set serveroutput on size unlimited

WHENEVER SQLERROR EXIT FAILURE;

DECLARE
   TYPE    t_privs IS TABLE OF VARCHAR2(30);
   v_privs t_privs := t_privs('CREATE PROCEDURE','CREATE TABLE','CREATE TRIGGER','CREATE TYPE','CREATE VIEW');
   v_priv  user_sys_privs.privilege%type;
   v_OK    boolean := TRUE;
BEGIN
   FOR i IN v_privs.FIRST..v_privs.LAST LOOP
   BEGIN
      SELECT privilege
        INTO v_priv
        FROM user_sys_privs
       WHERE privilege = v_privs(i)
	   UNION
      SELECT privilege
        FROM role_sys_privs
       WHERE privilege = v_privs(i);
      dbms_output.put_line(USER || ' has required "' || v_privs(i) || '" privilege.');
      EXCEPTION 
         WHEN NO_DATA_FOUND THEN
              dbms_output.put_line(USER || ' does NOT have required "' || v_privs(i) || '" privilege.');
              v_OK := FALSE;
   END;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000, USER || ' does not have all required privileges - check LOG.');
   END IF;
END;
/
SHOW ERRORS

exit;
