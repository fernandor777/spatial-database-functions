DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

CREATE OR REPLACE TYPE BODY &&INSTALL_SCHEMA..t_bearing_distance 
AS

  Constructor Function T_BEARING_DISTANCE ( p_sDegMinSec in varchar2,
                                            p_distance   in number )
                Return Self As Result
  As
  Begin
    SELF.bearing  := &&INSTALL_SCHEMA..COGO.DMS2DD( p_sDegMinSec );
    SELF.distance := p_distance;
    SELF.z        := NULL;
    RETURN;
  end T_BEARING_DISTANCE;

  Constructor Function T_BEARING_DISTANCE ( p_bearing  in number,
                                            p_distance in number )
                Return Self As Result as
  begin
    SELF.bearing  := p_bearing;
    SELF.distance := p_distance;
    SELF.z        := NULL;
    RETURN;
  end T_BEARING_DISTANCE;

  Constructor Function T_BEARING_DISTANCE ( p_sDegMinSec in varchar2,
                                            p_distance   in number,
                                            p_z          in number )
                Return Self As Result 
  as
  Begin
    SELF.bearing  := &&INSTALL_SCHEMA..COGO.DMS2DD( p_sDegMinSec );
    SELF.distance := p_distance;
    SELF.z        := p_z;
    RETURN;
  end T_BEARING_DISTANCE;

end;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := FALSE;
   v_obj_name varchar2(30) := 'T_BEARING_DISTANCE';
BEGIN
   FOR rec IN (select object_name,object_Type, status
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'TYPE BODY'
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
