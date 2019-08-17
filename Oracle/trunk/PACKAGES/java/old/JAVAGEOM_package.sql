create or replace
package javageom as

  Function GML2Geometry ( p_GML in varchar2 )
    Return MDSYS.SDO_Geometry
    Deterministic;

  Function GML2Geometry ( p_GML in CLOB )
    Return MDSYS.SDO_Geometry
    Deterministic;

  Function GML2SDO(p_GML in clob)
    Return MDSYS.SDO_Geometry
    Deterministic;
    
  Function GML2SDO(p_GML in varchar2)
    Return MDSYS.SDO_Geometry
   Deterministic;
  
  Function RunCommand( p_command in varchar2 )
    Return Number
           Deterministic;

end javageom;
/
show errors

create or replace
PACKAGE BODY JavaGeom AS

  c_module_name          CONSTANT varchar2(256) := 'JavaGeom';

  l_version              LONG;
  l_compatibility        LONG;
  v_version              number;
  v_compatibility        number;

  Function GML2Geometry ( p_GML in Varchar2 )
    Return mdsys.sdo_geometry 
        As language java name 
           'com.spatialdbadvisor.gis.oracle.utilities.gml2geometry(java.lang.String) return oracle.sql.STRUCT'; 

  Function GML2Geometry ( p_GML in CLOB )
    Return mdsys.sdo_geometry deterministic
        As language java name 
          'com.spatialdbadvisor.gis.oracle.utilities.gml2geometry(oracle.sql.CLOB) return oracle.sql.STRUCT'; 

  Function GML2SDO(p_GML in clob)
    Return MDSYS.SDO_Geometry
  Is
    v_gmltext clob;
  Begin
    v_gmltext := replace(p_gml,':posList',':coordinates');
    v_gmltext := replace(v_gmltext,':pos',':coordinates');
    v_gmltext := replace(v_gmltext,':exterior',':outerBoundaryIs');
    Return javageom.GML2Geometry(v_gmltext);
  End GML2SDO;
 
  Function GML2SDO(p_GML in varchar2)
    Return MDSYS.SDO_Geometry
  Is
    v_gmltext varchar2(32000);
  Begin
    v_gmltext := replace(p_gml,':posList',':coordinates');
    v_gmltext := replace(v_gmltext,':pos',':coordinates');
    v_gmltext := replace(v_gmltext,':exterior',':outerBoundaryIs');
    Return javageom.GML2Geometry(v_gmltext);
  End GML2SDO;

  Function RunCommand( p_command in varchar2 )
    Return Number
        As language java name 
           'com.spatialdbadvisor.gis.oracle.utilities.RunCommand(java.lang.String) return oracle.sql.string';

BEGIN
  dbms_utility.db_version(version => l_version, compatibility => l_compatibility);
  v_version := TO_number( substr(SUBSTR(l_version,1,17),1,instr(SUBSTR(l_version,1,17),'.',1,2)-1));
  v_compatibility := TO_number( substr(SUBSTR(l_compatibility,1,17),1,instr(SUBSTR(l_compatibility,1,17),'.',1,2)-1));
END JavaGeom;
/
show errors

QUIT;
