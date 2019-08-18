WHENEVER SQLERROR EXIT FAILURE;
set serveroutput on size unlimited
declare
   l_version       long;
   l_compatibility long;
   v_version       varchar2(20);
begin
   dbms_utility.db_version(version => l_version, compatibility => l_compatibility);
   v_version := SUBSTR(l_version,1,2);
   if ( NOT ( v_version > '10' ) ) then
     RAISE_APPLICATION_ERROR(-20000,'Can only compile java classes in Oracle 11g and later.');
   end if;
end;
/
show errors

set linesize 200
set serveroutput on size unlimited
declare
   v_compile       number;
begin
   for rec in (select name from user_java_classes) loop
   begin
      v_compile := DBMS_JAVA.compile_class(rec.name);
      dbms_output.put_line('Compiling class ' || rec.name || ' resulted in ' || v_compile || ' methods being compiled.');
      EXCEPTION 
         WHEN OTHERS THEN
              dbms_output.put_line('Compile of Java class ' || rec.name || ' failed with ' || SQLCODE ); 
   end;
   end loop;
end;
/
show errors

exit;


