VARIABLE db_version NUMBER
set serveroutput on size unlimited
declare
  v_version       varchar2(4000);
  v_db_version    number;
  v_compatibility varchar2(4000);
begin
  dbms_utility.db_version(v_version,v_compatibility);
  v_db_version := to_number(replace(substr(v_version,1,INSTR(v_version,'.')+1),'.','0'));
  dbms_output.put_line('Database version is ' || v_version || ' or ' || v_db_version); 
  :db_version := v_db_version;
end;
/
SHOW ERRORS
WHENEVER SQLERROR EXIT :db_version
DECLARE
  v_number number;
BEGIN
  v_number := 1/0; 
END;
/
quit;
