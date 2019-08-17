DEFINE defaultSchema='&1'

SET VERIFY OFF;

SET SERVEROUTPUT ON

create or replace package FRONTAGE 
AUTHID CURRENT_USER
AS

  Function DD2TIME(dDecDeg in Number)
    Return VARCHAR2 Deterministic;

  Function CompassPoint(p_bearing      in number,
                        p_abbreviation in integer default 1)
    Return varchar2 deterministic;

  Function ST_GetNumRings(p_geometry  in mdsys.sdo_geometry,
                          p_ring_type in integer /* 0 = ALL; 1 = OUTER; 2 = INNER */ )
    Return Number Deterministic;
 
  Function ST_HasCircularArcs(p_elem_info in mdsys.sdo_elem_info_array)
    return integer Deterministic;
  
  Function ST_BearingPlanar(p_x1 in number,
                            p_y1 in number,
                            p_x2 in number,
                            p_y2 in number)
    Return Number Deterministic;

  Function ST_Bearing(p_line in mdsys.sdo_geometry)
    Return Number Deterministic;

  Function ST_BearingGeodetic(p_Start_Point in MDSYS.SDO_GEOMETRY,
                              p_End_Point   in MDSYS.SDO_GEOMETRY)
  Return Number Deterministic;
  
  Function ST_BearingGreatCircle(p_lon1 in number,
                                 p_lat1 in number,
                                 p_lon2 in number,
                                 p_lat2  in number)
   Return number Deterministic;

  Function ST_BearingGreatCircle(p_geom in MDSYS.SDO_GEOMETRY )
    Return Number Deterministic;

  Function ST_RoundOrdinates(p_geom       In MDSYS.SDO_GEOMETRY,
                             p_dec_places In Number Default 3)
    Return MDSYS.SDO_GEOMETRY Deterministic;

  Function ST_Centroid_L(P_Geometry          In Mdsys.Sdo_Geometry,
                         P_Option            In Varchar2 := 'LARGEST',
                         P_Round_X           In Pls_Integer := 3,
                         P_Round_Y           In Pls_Integer := 3,
                         p_round_z           IN pls_integer := 2,
                         P_Unit              In Varchar2 Default Null)
    Return MDSYS.SDO_GEOMETRY Deterministic;

  Function ST_RemoveInnerRings(p_geometry  in mdsys.sdo_geometry)
    Return MDSYS.SDO_GEOMETRY Deterministic;


  /* ***********************************************************************
   * ******************** Main Function ************************************
   * ***********************************************************************
   **/
  Function Clockface(P_CAD_GID     In integer,
                     P_STREET_NAME in varchar2,
                     P_STREET_OBJ  In MDSYS.SDO_GEOMETRY,
                     p_dec_places  In Integer  default 8,
                     p_tolerance   In Number   default 0.005,
                     p_unit        In Varchar2 default null)
    Return &&defaultSchema..t_clockfaces Deterministic;

  /* *******************************************
   * ************* Overloads *******************
   * *******************************************
   **/
  Function Clockface(P_CAD_GID        In integer,
                     P_STREET_NAME    In varchar2,
                     P_STREET_OBJ_X   In Number,
                     P_STREET_OBJ_Y   In Number,
                     P_SRID           IN NUMBER   default 8307,
                     p_dec_places     In Integer  default 8,
                     p_tolerance      In Number   default 0.005,
                     p_unit           In Varchar2 default null)
    Return &&defaultSchema..t_clockfaces Deterministic;

  Function Clockface(P_CAD_GID        In integer,
                     P_STREET_LINE_ID in varchar2,
                     P_STREET_OBJ     In mdsys.sdo_geometry,
                     p_dec_places     In Integer  default 8,
                     p_tolerance      In Number   default 0.005,
                     p_unit        In Varchar2    default null)
    Return &&defaultSchema..t_clockfaces Deterministic;

  
  /* Alternate Clockface function 
   * main cad_id coded as negative in &&defaultSchema..TGEOMROW in &&defaultSchema..TGEOMETRIES
   */
  Function Clockface(P_STREET_OBJ     In mdsys.sdo_geometry,
                     P_CAD_NEIGHBOURS In &&defaultSchema..T_GEOMETRIES,
                     p_dec_places     In Integer  default 8,
                     p_tolerance      In Number   default 0.005,
                     p_unit           in varchar2 default NULL)
    Return &&defaultSchema..t_clockfaces Deterministic;

  Function Clockface(P_CAD_OBJ         In mdsys.sdo_geometry,
                     P_STREET_LINE_OBJ In mdsys.sdo_geometry,
                     P_STREET_OBJ      In mdsys.sdo_geometry,
                     p_dec_places      In Integer  default 8,
                     p_tolerance       In Number   default 0.005,
                     p_unit            in varchar2 default NULL)
    Return &&defaultSchema..T_Clockfaces deterministic;
    
END Frontage;
/
show errors

