Prompt Check if have necessary permissions 

WHENEVER SQLERROR EXIT FAILURE;

Prompt Make sure this is not an XE database that does not support Java...
set serveroutput on size unlimited
declare
  v_xe v$option.value%TYPE;
begin
  SELECT value 
    INTO v_xe
    FROM v$option 
   WHERE parameter = 'Java';
  If ( v_xe = 'FALSE' ) Then
     RAISE_APPLICATION_ERROR(-20000, 'XE does not have a JVM and so is not supported.');
  End If;
  dbms_output.put_line('Database has required JVM capabilities.');
  EXCEPTION 
    WHEN NO_DATA_FOUND THEN
         RAISE_APPLICATION_ERROR(-20000, 'Either JVM is not installed or ' || USER ||' does not have SELECT permissions on v$option - "GRANT SELECT ON v_$option TO ' || USER || ';".');
end;
/
show errors

set serveroutput on size unlimited
DECLARE
   TYPE    t_privs IS TABLE OF VARCHAR2(30);
   v_privs t_privs := t_privs('CREATE PROCEDURE','CREATE TYPE','JAVAUSERPRIV','JAVASYSPRIV');
   v_priv  user_sys_privs.privilege%type;
   v_OK    boolean := TRUE;
BEGIN
   FOR i IN v_privs.FIRST..v_privs.LAST LOOP
   BEGIN
     SELECT privilege
       INTO  v_priv
       FROM (SELECT GRANTED_ROLE as privilege
               FROM USER_ROLE_PRIVS
              WHERE GRANTED_ROLE = v_privs(i)
	           UNION
             SELECT privilege
               FROM user_sys_privs
              WHERE privilege = v_privs(i)
	           UNION
             SELECT privilege
               FROM role_sys_privs
              WHERE privilege = v_privs(i)
            ) f;
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
