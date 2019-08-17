DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

create or replace type &&INSTALL_SCHEMA..T_CLOCKFACES As Table of &&INSTALL_SCHEMA..T_CLOCKFACE;
/

create or replace type &&INSTALL_SCHEMA..t_integers as table of Integer;
/
GRANT EXECUTE on T_INTEGERS TO PUBLIC;

create or replace type &&INSTALL_SCHEMA..t_elem_info_array as table of Integer;
/

create or replace type &&INSTALL_SCHEMA..t_ordinate_array as table of Number;
/

EXIT SUCCESS;
