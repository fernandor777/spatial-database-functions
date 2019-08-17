DEFINE OWNER='&1'

GRANT  DEBUG CONNECT SESSION TO &&OWNER.;

GRANT DEBUG ANY PROCEDURE TO &&OWNER.;

grant execute on DBMS_DEBUG_JDWP to &&OWNER.;

begin
   dbms_network_acl_admin
       .append_host_ace(host=>'10.0.0.33', -- '127.0.0.1',
                        ace=> sys.xs$ace_type(privilege_list=>sys.XS$NAME_LIST('JDWP'),
                                              principal_name=>'&&OWNER.',
                                              principal_type=>sys.XS_ACL.PTYPE_DB
                              ) 
        );
end;
/
