DEFINE newuser = '&1'

drop user &&newuser. cascade;
CREATE USER &&newuser. 
    IDENTIFIED BY &&newuser.
    DEFAULT TABLESPACE users
    QUOTA UNLIMITED ON users
    TEMPORARY TABLESPACE temp;
grant connect                  to &&newuser.;
grant resource                 to &&newuser.;
grant create table             to &&newuser.;
grant create view              to &&newuser.;
grant create type              to &&newuser.;
grant create procedure         to &&newuser.;
grant create sequence          to &&newuser.;
grant create trigger           to &&newuser.;
grant create synonym           to &&newuser.;
grant create public synonym    to &&newuser.;
grant create materialized view to &&newuser.;
grant javauserpriv             to &&newuser.;
purge recyclebin;

exit;


