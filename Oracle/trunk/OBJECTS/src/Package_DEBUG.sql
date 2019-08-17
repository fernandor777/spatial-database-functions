DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

CREATE OR REPLACE PACKAGE &&INSTALL_SCHEMA..DEBUG
AUTHID CURRENT_USER
As
/****h* PACKAGE/DEBUG 
*  NAME
*    DEBUG - Functions that can be used to create string versions of complex types for output during debugging eg dbms_output.
*  DESCRIPTION
*    A package that publishes some functions that can be used to create string versions of complext types for output during debugging eg dbms_output.
*  AUTHOR
*    Simon Greener
*  HISTORY
*    Simon Greener - Jan 2017 - Original coding.
*  COPYRIGHT
*    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
*  SOURCE
*/
  Procedure PrintPoint( p_point    in mdsys.sdo_point_type,
                        p_round    in number default 3,
                        p_prefix   in varchar2 default null,
                        p_linefeed in boolean default false);

  Procedure PrintPoint( p_point    in mdsys.vertex_type,
                        p_round    in number default 3,
                        p_prefix   in varchar2 default null,
                        p_linefeed in boolean default false);

  Procedure PrintPoint( p_point    in &&INSTALL_SCHEMA..T_Vertex,
                        p_round    in number default 3,
                        p_prefix   in varchar2 default null,
                        p_linefeed in boolean default false);

  Procedure PrintGeom(  p_geom        in mdsys.sdo_geometry,
                        p_round       in number default 3,
                        p_linefeed    in boolean default false,
                        p_suffix_text in varchar2 default null);

  Procedure PrintGeom(  p_geom        in &&INSTALL_SCHEMA..T_Geometry,
                        p_round       in number default 3,
                        p_linefeed    in boolean default false,
                        p_suffix_text in varchar2 default null);

  Function PrintGeom(   p_geom     in mdsys.sdo_geometry,
                        p_round    in number default 3,
                        p_linefeed in integer default 0,
                        p_prefix   in varchar2 default null,
                        p_relative in integer default 0)
    Return clob deterministic;

  Procedure PrintElemInfo( p_elem_info in mdsys.sdo_elem_info_array,
                           p_linefeed  in Boolean default false);

  Procedure PrintOrdinates(p_ordinates in mdsys.sdo_ordinate_array,
                           p_coordDim  in pls_integer default 2,
                           p_round     in pls_integer default 3,
                           p_linefeed  in Boolean default false);
/*******/
end DEBUG;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean      := FALSE;
   v_obj_name varchar2(30) := 'DEBUG';
BEGIN
   FOR rec IN (select object_name,object_Type, status 
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'PACKAGE'
                order by object_type
              ) 
   LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is valid.');
         v_ok := TRUE;
      ELSE
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is invalid.');
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
   EXECUTE IMMEDIATE 'GRANT EXECUTE ON &&INSTALL_SCHEMA..' || v_obj_name || ' TO public WITH GRANT OPTION';
END;
/
SHOW ERRORS

EXIT SUCCESS;

