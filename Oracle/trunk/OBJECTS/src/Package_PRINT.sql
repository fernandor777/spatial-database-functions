DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

-- Always aim for a clean compile
ALTER SESSION SET PLSQL_WARNINGS='ERROR:ALL';

CREATE OR REPLACE PACKAGE &&INSTALL_SCHEMA..PRINT
AUTHID CURRENT_USER
As
/****h* PACKAGE/PRINT
*  NAME
*    PRINT - Functions that can be used to create string versions of complex types for output during debugging eg dbms_output.
*  DESCRIPTION
*    A package that publishes some functions that can be used to create string versions of complex types for output during debugging eg dbms_output.
*  AUTHOR
*    Simon Greener
*  HISTORY
*    Simon Greener - August 2019 - Original coding.
*  COPYRIGHT
*    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
*  SOURCE
*/
  Function sdo_point_type( p_point in mdsys.sdo_point_type,
                           p_round in number default 3)
    Return varchar2 deterministic;

  Function Vertex_Type(p_point in mdsys.vertex_type,
                       p_round in number default 3)
    Return varchar2 deterministic;

  Function sdo_elem_info( p_elem_info in mdsys.sdo_elem_info_array )
    return varchar2 deterministic;

  Function sdo_ordinates(p_ordinates in mdsys.sdo_ordinate_array,
                         p_coordDim  in pls_integer default 2,
                         p_round     in pls_integer default 3)
    Return clob deterministic;

  Function sdo_geometry(p_geom  in mdsys.sdo_geometry,
                        p_round in number default 3)
    Return clob deterministic;
/*******/

end PRINT;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := FALSE;
   v_obj_name varchar2(30) := 'PRINT';
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
END;
/
SHOW ERRORS

EXIT SUCCESS;

