PROMPT Permissions needed to write to an external directory....
-- Note that the directory to be written to is always specified with \* on the end
--
DEFINE defaultSchema='&1'
EXEC DBMS_JAVA.grant_permission('&&defaultSchema.','SYS:java.io.FilePermission', 'C:\Temp\*', 'read,write,execute,delete');
EXEC DBMS_JAVA.grant_permission('&&defaultSchema.','SYS:java.lang.RuntimePermission','writeFileDescriptor', '');
EXEC DBMS_JAVA.grant_permission('&&defaultSchema.','SYS:java.lang.RuntimePermission','readFileDescriptor', '');
EXEC DBMS_JAVA.GRANT_PERMISSION('&&defaultSchema.','SYS:java.lang.RuntimePermission','getClassLoader','');

REM commit the changes to the PolicyTable
commit;

PROMPT Grant general Java user permission to our schema...
Grant JAVASYSPRIV To &&defaultSchema.;

PROMPT Grant general Java user permission to our schema...
Grant JAVAUSERPRIV To &&defaultSchema.;

exit;
