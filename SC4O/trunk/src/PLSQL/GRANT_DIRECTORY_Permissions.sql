/*
A Java method is called from SQL or PL/SQL through a corresponding wrapper. Java wrappers are special PL/SQL entities, which expose Java methods to SQL and PL/SQL as PL/SQL stored procedures or functions. Such a wrapper might change the current effective user. The wrappers that change the current effective user to the owner of the wrapper are called definer's rights wrappers. By default, Java wrappers are definer's rights wrappers. If you want to override this, then create the wrapper using the AUTHID CURRENT_USER option. You can load a Java class to the database with the loadjava -definer option. Any method of a class having the definer attribute marked, becomes a definer's rights method.

However, you cannot override the loadjava option -definer by specifying CURRENT_USER.

Note: Prior to Oracle Database 11g release 1 (11.1), granting execute right to a stored procedure would mean granting execute right to both the stored procedure and the Java class referred by the stored procedure. In Oracle Database 11g release, if you want to grant execute right on the underlying Java class as well, then you must grant execute right on the class explicitly. This is implemented for better security.

*/
execute dbms_java.grant_permission( 'CODESYS', 'SYS:java.io.FilePermission', 'c:\\temp\\-', 'read,write' );
execute dbms_java.grant_permission( 'CODESYS', 'SYS:java.io.FilePermission', 'c:\temp\-', 'write' );
execute dbms_java.grant_permission( 'CODESYS', 'SYS:java.io.FilePermission', 'c:\temp\*', 'read' );
execute dbms_java.grant_permission( 'CODESYS', 'SYS:java.io.FilePermission', 'c:\temp\*', 'write' );

declare
  TYPE      varray_type is VARRAY(7) OF VARCHAR(10);
  v_folders varray_type := varray_type('CODESYS','YOURSCHEMA');
  v_i       pls_integer;
  v_user    varchar2(32);
begin
  dbms_output.put_line('v_folders.COUNT = ' || v_folders.COUNT );
  for v_i in 1..v_folders.COUNT loop
      v_user := v_folders(v_i);
      dbms_output.put_line('User = ' || v_user );
      dbms_java.grant_permission( v_user, 'java.io.FilePermission', 'C:/Temp/*', 'read,write' );
  end loop;
end;

exit;

