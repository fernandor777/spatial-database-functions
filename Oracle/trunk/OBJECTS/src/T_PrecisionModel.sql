DEFINE INSTALL_SCHEMA='&&INSTALL_SCHEMA.'

SET VERIFY OFF;

CREATE OR REPLACE EDITIONABLE TYPE &&INSTALL_SCHEMA..T_PrecisionModel
AUTHID DEFINER
AS OBJECT (

  /****t* OBJECT TYPE/T_PrecisionModel
  *  NAME
  *    T_PrecisionModel -- Object type holding ordinate precision and tolerance values
  *  DESCRIPTION
  *    JTS has a PrecisionModel class. With the use of NUMBER data type most of the JTS PrecisionModel types (eg FIXED, FLOATING_SINGLE etc)
  *    are not neded. What is needed is a single place one can record XY, Z and M ordinate precision (scale) values.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/

  /****v* T_SEGMENT/ATTRIBUTES(T_SEGMENT)
  *  ATTRIBUTES
  *           XY -- Single scale/precision value for X and Y ordinates.
  *            Z -- Scale/precision value for the Z ordinate.
  *            W -- Scale/precision value for the W ordinate.
  *    tolerance -- Standard Oracle Spatial tolerance value eg 0.005.
  *  SOURCE
  */
  xy        integer,
  z         integer,
  w         integer,
  tolerance number
  /*******/

);
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'T_SEGMENT';
BEGIN
   FOR rec IN (select object_name,object_Type, status
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'TYPE'
               order by object_type
              ) 
   LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is valid.');
      ELSE
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is invalid.');
         v_ok := false;
      END IF;
   END LOOP;
   execute immediate 'GRANT EXECUTE ON &&INSTALL_SCHEMA..' || v_obj_name || ' TO public WITH GRANT OPTION';
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

EXIT SUCCESS;
