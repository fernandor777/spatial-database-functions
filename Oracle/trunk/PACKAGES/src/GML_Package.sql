create or replace
package gml
authid current_user
as
  Function toGeometry ( p_GML in varchar2 )
    Return MDSYS.SDO_Geometry
           Deterministic;

  Function toGeometry ( p_GML in CLOB )
    Return MDSYS.SDO_Geometry
           Deterministic;
           
  /** ----------------------------------------------------------------------------------------
  * @function   : gml2sdo
  * @precis     : Function for handling some GML 3 geometries that the GML 2 java converter doesn't handle.
  * @version    : 1.0
  * @usage      : gml2sdo ( p_gml IN CLOB )
  *                 Return MDSYS.SDO_Geometry Deterministic;
  *               eg select GML.GML2SDO('<gml:Point srsName="SDO:8307" xmlns:gml="http://www.opengis.net/gml">
  *                                      <gml:coordinates decimal="." cs="," ts=" ">147.234232,-43.452334 </gml:coordinates>
  *                                      </gml:Point>') as GEOM 
  *                    from dual;
  * @param      : p_GML  : GML 2.x snippet 
  * @paramtype  : p_DML  : CLOB
  * @return     : geom   : geometry or null
  * @rtnType    : sdo_geometry 
  * @note       : Supplied GML must be valid GML2. Might support some GML 3 constructs.
  * @history    : Simon Greener - Nov 2009 - Original idea.
  * @history    : Noud van Beek - Dec 2009 - Original coding.
  * @history    : Simon Greener - Dec 2009 - Integration into package
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. (http://creativecommons.org/licenses/by-sa/2.5/au/)
  **/  
  Function gml2sdo(p_GML in clob)
    return MDSYS.SDO_Geometry 
           Deterministic;
           
  /** ----------------------------------------------------------------------------------------
  * @function   : gml2sdo
  * @precis     : Function for handling some GML 3 geometries that the GML 2 java converter doesn't handle.
  * @version    : 1.0
  * @usage      : gml2sdo ( p_gml IN varchar2 )
  *                 Return MDSYS.SDO_Geometry Deterministic;
  *               eg select GML.GML2SDO('<gml:Point srsName="SDO:8307" xmlns:gml="http://www.opengis.net/gml">
  *                                      <gml:coordinates decimal="." cs="," ts=" ">147.234232,-43.452334 </gml:coordinates>
  *                                      </gml:Point>') as GEOM 
  *                    from dual;
  * @param      : p_GML  : GML 2.x snippet 
  * @paramtype  : p_DML  : varchar2
  * @return     : geom   : geometry or null
  * @rtnType    : sdo_geometry 
  * @note       : Supplied GML must be valid GML2. Might support some GML 3 constructs.
  * @history    : Simon Greener - Nov 2009 - Original idea.
  * @history    : Noud van Beek - Dec 2009 - Original coding.
  * @history    : Simon Greener - Dec 2009 - Integration into package
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. (http://creativecommons.org/licenses/by-sa/2.5/au/)
  **/  
  Function gml2sdo(p_GML in varchar2)
    return MDSYS.SDO_Geometry
           Deterministic;
    
end GML;
/
show errors

create or replace
PACKAGE BODY GML
AS

  Function toGeometry ( p_GML in Varchar2 )
    Return mdsys.sdo_geometry
        As language java name
           'com.spatialdbadvisor.gis.oracle.gml.toGeometry(java.lang.String) return oracle.sql.STRUCT';

  Function toGeometry ( p_GML in CLOB )
    Return mdsys.sdo_geometry deterministic
        As language java name
          'com.spatialdbadvisor.gis.oracle.gml.toGeometry(oracle.sql.CLOB) return oracle.sql.STRUCT';

  Function gml2sdo(p_GML in clob)
    return MDSYS.SDO_Geometry
  is
    v_gmltext clob;
  begin
    v_gmltext := replace(p_gml,':posList',':coordinates');
    v_gmltext := replace(v_gmltext,':pos',':coordinates');
    v_gmltext := replace(v_gmltext,':exterior',':outerBoundaryIs');
    return gml.togeometry(v_gmltext);
  end;
 
  Function gml2sdo(p_GML in varchar2)
    return MDSYS.SDO_Geometry
  is
    v_gmltext varchar2(32000);
  begin
    v_gmltext := replace(p_gml,':posList',':coordinates');
    v_gmltext := replace(v_gmltext,':pos',':coordinates');
    v_gmltext := replace(v_gmltext,':exterior',':outerBoundaryIs');
    Return gml.togeometry(v_gmltext);
  end;
  
END GML;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'GML';
BEGIN
   FOR rec IN (select object_name || '.' || object_Type as package_name, status 
                 from user_objects
                where object_name = v_obj_name) LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line('Package ' || USER || '.' || rec.package_name || ' is valid.');
      ELSE
         dbms_output.put_line('Package ' || USER || '.' || rec.package_name || ' is invalid.');
         v_ok := false;
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

grant execute on gml to public;


