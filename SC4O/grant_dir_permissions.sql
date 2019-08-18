EXEC DBMS_JAVA.grant_permission('CODESYS', 'java.io.FilePermission', 'c:\temp\*', 'read ,write, execute, delete');
EXEC DBMS_JAVA.grant_permission('CODESYS', 'SYS:java.lang.RuntimePermission', 'writeFileDescriptor', '');
EXEC DBMS_JAVA.grant_permission('CODESYS', 'SYS:java.lang.RuntimePermission', 'readFileDescriptor', '');
GRANT JAVAUSERPRIV TO codesys;

declare
  TYPE varray_type is VARRAY(5) OF VARCHAR(10);
  v_folders varray_type := varray_type('MCW_GIS','MCW_LAND','MCW_STORM','MCW_WATER','MCW_WASTE');
  v_i pls_integer;
begin
  for v_i in 1..v_folders.COUNT loop
      dbms_java.grant_permission( 'CODESYS', 'SYS:java.io.FilePermission', 'E:\GIS_Downloads\' || v_folders(v_i) || '\*', 'read' );
      dbms_java.grant_permission( 'CODESYS', 'SYS:java.io.FilePermission', 'E:\GIS_Downloads\' || v_folders(v_i) || '\*', 'write' );
      dbms_output.put_line('Processed read,write for E:\GIS_Downloads\' ||  v_folders(v_i) || '\*' );
  end loop;
end;

