DEFINE DEFAULTSCHEMA='GIS'

Prompt Should only be run as SYS by DBA

SET VERIFY OFF

set serveroutput on size unlimited 
-- Delete all permissions
declare
begin
  for rec in (select grantee, 
                     row_number() over (partition by grantee order by seq) as rin,
                     type_name, name, action, seq
                from dba_java_policy p
               where grantee like '&&DEFAULTSCHEMA..'
             ) 
  loop
      begin
         DBMS_JAVA.DISABLE_PERMISSION(rec.seq);
         dbms_java.revoke_permission( rec.grantee, rec.type_name, rec.name, rec.action );
         dbms_java.delete_permission(rec.seq); 
         commit;
         dbms_output.put_line('Permission ' || rec.type_name || ' with action ' || rec.action || ' on ' || rec.name || ' was disabled, revoked and deleted for ' || rec.grantee);
         if ( rec.rin = 1 ) then
             execute immediate 'REVOKE JAVAUSERPRIV FROM ' || rec.grantee;
             dbms_output.put_line('REVOKE JAVAUSERPRIV FROM ' || rec.grantee);         
         end if;
         exception 
            when others then
                dbms_output.put_line('Priv failed to be revoked from ' || rec.grantee || ' (' || SQLERRM || ')');
      end;
  End Loop;
End;
/
SHOW ERRORS

-- Should return no rows
select grantee, type_name, name, action, seq
  from dba_java_policy p
 where grantee = '&&DEFAULTSCHEMA..';

-- Grant permission
set serveroutput on size unlimited 
declare
begin
  for rec in (select username, 
                     'SYS:java.io.FilePermission' as fileperm, 
                     'SYS:java.lang.RuntimePermission' as runtimeperm,
                     'C:/TEMP/-' as exportDir
                from dba_users u
               where u.username = '&&DEFAULTSCHEMA..'
              ) 
  loop
      begin
         dbms_java.grant_permission(rec.username, rec.fileperm, rec.exportDir, 'read ,write, execute, delete');
         dbms_output.put_line(rec.fileperm || ' on ' || rec.exportDir || ' granted to ' || rec.username);
         dbms_java.grant_permission(rec.username, rec.fileperm, '<<ALL FILES>>', 'read ,write, execute, delete');
         dbms_output.put_line(rec.fileperm || ' granted to ' || rec.username);
         dbms_java.grant_permission(rec.username, rec.runtimeperm, 'readFileDescriptor, writeFileDescriptor', '');
         dbms_output.put_line(rec.runtimeperm || ' granted to ' || rec.username);
         execute immediate 'GRANT JAVAUSERPRIV TO ' || rec.username;
         dbms_output.put_line('JAVAUSERPRIV granted to ' || rec.username);         
         exception 
            when others then
                dbms_output.put_line('Priv failed to be granted to ' || rec.username || ' (' || SQLERRM || ')');
      end;
  End Loop;
End;
/
show errors

execute dbms_java.grant_permission( '&&DEFAULTSCHEMA.', 'SYS:java.lang.reflect.ReflectPermission', 'suppressAccessChecks', '' );

EXIT;
