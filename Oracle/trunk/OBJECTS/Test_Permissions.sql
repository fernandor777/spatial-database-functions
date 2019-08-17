Prompt Check if have necessary permissions 
set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   TYPE    t_privs IS TABLE OF VARCHAR2(30);
   v_privs t_privs := t_privs('CREATE PROCEDURE','CREATE TYPE');
   v_priv  user_sys_privs.privilege%type;
BEGIN
   FOR i IN v_privs.FIRST..v_privs.LAST LOOP
   BEGIN
      SELECT privilege
        INTO v_priv
        FROM user_sys_privs
       WHERE privilege = v_privs(i);
      dbms_output.put_line(USER || ' has required "' || v_privs(i) || '" privilege.');
      EXCEPTION 
         WHEN NO_DATA_FOUND THEN
              RAISE_APPLICATION_ERROR(-20000, USER || ' does not have "' || v_privs(i) || '" privilege.');
   END;
   END LOOP;
END;
/
SHOW ERRORS

EXIT SUCCESS;
