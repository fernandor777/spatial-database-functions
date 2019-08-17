DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

CREATE OR REPLACE TYPE &&INSTALL_SCHEMA..T_ElemInfo 
AUTHID DEFINER
AS OBJECT (

/****t* OBJECT TYPE/T_ELEMINFO 
*  NAME
*    T_ELEMINFO -- Object type representing single mdsys.sdo_elem_info triplet.
*  DESCRIPTION
*    An object type that represents an sdo_elem_info_array "triplet" as a single object.
*  NOTES
*    No methods are declared on this type.
*  TODO
*    Methods on an T_ELEMINFO may be added in future.
*  AUTHOR
*    Simon Greener
*  HISTORY
*    Simon Greener - Jan 2013 - Original coding.
*  COPYRIGHT
*    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
******/

  /****v* T_ELEMINFO/ATTRIBUTES(T_ELEMINFO) 
  *  ATTRIBUTES
  *    offset         -- Offset value from Element_Info triplet
  *    etype          -- eType value from Element_Info triplet, describes geometry element.
  *    interpretation -- Interpretation value from Element_Info triplet eg 1 is vertex-connected; 3 is optimized rectangle; etc.
  *  SOURCE
  */
   offset           NUMBER,
   etype            NUMBER,
   interpretation   NUMBER
  /*******/
);
/

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'T_ELEMINFO';
BEGIN
   FOR rec IN (select object_name,object_Type, status 
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'TYPE'
               order by object_type) LOOP
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

/****s* OBJECT TYPE ARRAY/T_ELEMINFOSET 
*  NAME
*    T_ELEMINFOSET -- A type representing an array (collection) of T_ELEMINFO objects.
*  DESCRIPTION
*    An array of T_ELEMINFO objects that represent an ordered set of sdo_elem_info triplets.
*  AUTHOR
*    Simon Greener
*  HISTORY
*    Simon Greener - Jan 2005 - Original coding.
*  COPYRIGHT
*    (c) 2012-2018 by TheSpatialDBAdvisor/Simon Greener
*  SOURCE
*/
CREATE OR REPLACE TYPE &&INSTALL_SCHEMA..T_ElemInfoSet 
           IS TABLE OF &&INSTALL_SCHEMA..T_ElemInfo;
/*******/
/
show errors

grant execute on &&INSTALL_SCHEMA..T_ElemInfoSet to public with grant option;

EXIT SUCCESS;

