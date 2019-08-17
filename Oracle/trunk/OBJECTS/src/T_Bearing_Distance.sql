DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

CREATE OR REPLACE TYPE &&INSTALL_SCHEMA..T_BEARING_DISTANCE
AUTHID DEFINER
AS OBJECT (

/****t* OBJECT TYPE/T_BEARING_DISTANCE 
*  NAME
*    T_BEARING_DISTANCE - Object Type representing a single bearing and distance COGO instruction.
*  DESCRIPTION
*    An object type that represents a set of bearing/distance instructions for building the sides of a polygon, or the segments of a linestring.
*  NOTES
*    No methods are declared on this type.
*  AUTHOR
*    Simon Greener
*  HISTORY
*    Simon Greener - Jan 2017 - Original coding.
*  COPYRIGHT
*    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
******/

  /****v* T_BEARING_DISTANCE/ATTRIBUTES(T_BEARING_DISTANCE) 
  *  ATTRIBUTES
  *    sDegMinSec varchar2(255) -- Textual description of a bearing eg 180^10'5.2" (cf Google).
  *                                See also function COGO.DMS2DD.
  *    nBearing   number,       -- A numeric bearing eg 180.092784
  *    distance   number,       -- Length of line along line defined by bearing.
  *    Z          number,       -- Z ordinate of point at end of bearing/distance (line cogo function only)
  *  NOTES
  *    Normally only one or the other of the sDegMinSec or nBearing attributes are defined.
  *  SOURCE
  */
  Bearing  number,
  Distance number,
  Z        number,
  /*******/
  
 /****m* T_BEARING_DISTANCE/CONSTRUCTORS(T_BEARING_DISTANCE) 
  *  NAME
  *    A collection of T_BEARING_DISTANCE Constructors.
  *  INPUT
  *    p_sDegMinSec varchar2 -- Textual description of a bearing eg 180^10'5.2" (cf Google).
  *                             Converted to internal bearing attribute via call to COGO.DMS2DEG.
  *  SOURCE
  */
  Constructor Function T_BEARING_DISTANCE ( p_sDegMinSec in varchar2,
                                            p_distance   in number )
                Return Self As Result,
                
  Constructor Function T_BEARING_DISTANCE ( p_bearing  in number,
                                            p_distance in number )
                Return Self As Result,

  Constructor Function T_BEARING_DISTANCE ( p_sDegMinSec in varchar2,
                                            p_distance   in number,
                                            p_z          in number )
                Return Self As Result
  /*******/

);
/
SHOW ERRORS

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := FALSE;
   v_obj_name varchar2(30) := 'T_BEARING_DISTANCE';
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

grant execute on &&INSTALL_SCHEMA..T_BEARING_DISTANCE to public with grant option;

/****s* OBJECT TYPE ARRAY/T_BEARING_DISTANCES 
*  NAME
*    T_BEARING_DISTANCES - Array of T_BEARING_DISTANCE Objects.
*  DESCRIPTION
*    An array of T_BEARING_DISTANCE objects used to fully describe a single polygon ring or linestring object.
*  AUTHOR
*    Simon Greener
*  HISTORY
*    Simon Greener - Jan 2017 - Original coding.
*  COPYRIGHT
*    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
*  SOURCE
*/
CREATE OR REPLACE TYPE &&INSTALL_SCHEMA..T_BEARING_DISTANCES
           AS TABLE OF &&INSTALL_SCHEMA..T_BEARING_DISTANCE;
/*******/
/
SHOW ERRORS

EXIT SUCCESS;
