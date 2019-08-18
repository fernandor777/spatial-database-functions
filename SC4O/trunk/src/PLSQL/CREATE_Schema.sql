DEFINE CODEOWNER='&1'
DEFINE PSWD='&2'
drop   user &CODEOWNER. cascade;
create user &CODEOWNER 
       identified by &PSWD. 
       default tablespace users 
       temporary tablespace temp;
grant connect to &CODEOWNER;
grant resource to &CODEOWNER;
grant create table to &CODEOWNER;
grant create view to &CODEOWNER;
grant create procedure to &CODEOWNER;
grant create sequence to &CODEOWNER;
grant create trigger to &CODEOWNER;
grant create synonym to &CODEOWNER;
grant create public synonym to &CODEOWNER;
grant query rewrite to &CODEOWNER;
grant SELECT_CATALOG_ROLE to &CODEOWNER;
grant debug connect session to &CODEOWNER.;
grant debug any procedure to &CODEOWNER.;
grant imp_full_database to &CODEOWNER.;
grant exp_full_database to &CODEOWNER.;
grant execute on sys.utl_smtp to &CODEOWNER.;
grant execute on mdsys.sdo_3gl to &CODEOWNER.;
quit;
