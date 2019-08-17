DEFINE defaultSchema='&1'

SET VERIFY OFF;

ALTER SESSION SET plsql_optimize_level=1;

CREATE OR REPLACE PACKAGE KML
authid current_user
As

  Procedure Header( p_document_name  In Varchar2,
                    p_visibility     In Integer := 1,
                    p_open           In Integer := 1,
                    p_object_list    In VarChar2 := 'POINT,LINE,POLYGON',
                    p_colour         In VarChar2 := 'ff00ff00',
                    p_normal_mode    In Integer := 1,
                    p_point_scale    In Number  := 1.1,
                    p_line_width     In Integer := 4,
                    p_polygon_fill   In Integer := 0 );

  /**
  * @function   : TO_KML
  * @precis     : Procedure takes a geodetic shape, converts it to a KML representation which
  *               could be used within Google Earth and adds it to an internal document.
  * @version    : 1.0
  * @description: As per precis. If you need to handle projected data then I suggest you call the function
  *               with the relevant Oracle projection call eg SDO_CS.TRANSFORM(geom,to_srid);
  * @usage      : Procedure To_KML(p_geometry       In MdSys.Sdo_Geometry,
  *                                p_placemark_name In Varchar2,
  *                                p_description    In Varchar2,
  *                                p_elevation      In Number  := 0.0
  *                                );
  *               eg KML := &&defaultSchema..geom.To_KML(shape,'My House','My house converted from oracle');
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : An geodetic Sdo_Geometry object of any type.
  * @history    : Simon Greener - Feb 2007 - Original coding.
  * @copyright  : Free for public use
  **/
  Procedure To_KML( p_geometry       In MdSys.Sdo_Geometry,
                    p_placemark_name In Varchar2,
                    p_description    In Varchar2,
                    p_elevation      In Number  := 0.0
                  );

  Function  To_KML( p_geometry       In MdSys.Sdo_Geometry,
                    p_placemark_name In Varchar2,
                    p_description    In Varchar2,
                    p_elevation      In Number  := 0.0
                  )
    Return CLOB Deterministic;

  Procedure Footer;

  Function GetDocument
    Return CLOB Deterministic;

End KML;
/

create or replace 
package body KML
AS

  C_MODULE_NAME   CONSTANT VARCHAR2(256) := 'KML';

  c_i_UNSUPPORTED CONSTANT INTEGER       := -20101;
  C_S_UNSUPPORTED CONSTANT VARCHAR2(100) := 'Compound objects, Circles, Arcs and Optimised Rectangles currently not supported.';
  c_i_PROJECTED   CONSTANT INTEGER       := -20102;
  C_S_PROJECTED   CONSTANT VARCHAR2(100) := 'Projected data not supported.';
  C_I_NULL_SRID   CONSTANT INTEGER       := -20103;
  C_S_NULL_SRID   CONSTANT VARCHAR2(100) := 'Geometry objects with NULL sdo_srid are considered to be projected data and are not supported.';

  -- We create one global temporary variable so we can build up a single document from many calls to the package's functions
  --
  v_KML           CLOB;

  Procedure Header( p_document_name  In Varchar2,
                    p_visibility     In Integer := 1,
                    p_open           In Integer := 1,
                    p_object_list    In VarChar2 := 'POINT,LINE,POLYGON',
                    p_colour         In VarChar2 := 'ff00ff00',
                    p_normal_mode    In Integer := 1,
                    p_point_scale    In Number  := 1.1,
                    P_LINE_WIDTH     IN INTEGER := 4,
                    P_POLYGON_FILL   IN INTEGER := 0 )
  Is
     v_open         Integer := p_open;
     v_visibility   Integer := p_visibility;
     v_normal_mode  Integer := p_normal_mode;
     v_polygon_fill Integer := p_polygon_fill;
     v_line_width   Integer := p_line_width;
     v_point_scale  Number  := p_point_scale;
     V_COLOUR_MODE  VARCHAR2(20) := 'normal';
     v_temp         Integer;
     ISUNSUPPORTED  EXCEPTION;
  Begin
     If ( v_normal_mode  not in (0,1) ) Then v_normal_mode  := 1; End If;
     If ( v_visibility   not in (0,1) ) Then v_visibility   := 1; End If;
     If ( v_open         not in (0,1) ) Then v_open         := 1; End If;
     If ( v_polygon_fill not in (0,1) ) Then v_polygon_fill := 1; End If;
     If ( v_line_width   <= 0 )         Then v_line_width   := 4; End If;
     If ( v_point_scale  <= 0 )         Then v_point_scale  := 4; End If;
     If ( v_normal_mode = 0 ) THEN
       v_colour_mode := 'random';
     End If;

     -- Create New Document..
     SYS.DBMS_LOB.CreateTemporary( v_KML, TRUE, SYS.DBMS_LOB.CALL );
     SYS.DBMS_LOB.APPEND(v_KML,'<?xml version="1.0" encoding="UTF-8"?>'||CHR(10));
     SYS.DBMS_LOB.APPEND(v_KML,'<kml xmlns="http://earth.google.com/kml/2.1">'||CHR(10));
     SYS.DBMS_LOB.APPEND(v_KML,'<Document>'||CHR(10));
     SYS.DBMS_LOB.APPEND(v_KML,'  <name><![CDATA['||p_document_name||']]>' || '</name>'||CHR(10));
     SYS.DBMS_LOB.APPEND(v_KML,'  <visibility>'||v_visibility||'</visibility>'||CHR(10));
     SYS.DBMS_LOB.APPEND(v_KML,'  <open>'||v_open||'</open>'||CHR(10));
     If ( INSTR(UPPER(p_object_list),'POINT') > 0 ) Then
        SYS.DBMS_LOB.APPEND(v_KML,'  <Style id="PointStyle">'||CHR(10));
        SYS.DBMS_LOB.APPEND(v_KML,'    <IconStyle>'||CHR(10));
     ElsIf ( INSTR(UPPER(p_object_list),'LINE') > 0 ) Then
        SYS.DBMS_LOB.APPEND(v_KML,'  <Style id="LineStyle">'||CHR(10));
        SYS.DBMS_LOB.APPEND(v_KML,'    <LineStyle>'||CHR(10));
     ElsIf ( INSTR(UPPER(p_object_list),'POLYGON') > 0 ) Then
        SYS.DBMS_LOB.APPEND(v_KML,'  <Style id="PolygonStyle">'||CHR(10));
        SYS.DBMS_LOB.APPEND(v_KML,'    <PolyStyle>'||CHR(10));
     Else
        RAISE ISUNSUPPORTED;
     End If;
     SYS.DBMS_LOB.APPEND(v_KML,'      <color>' || p_colour || '</color>'||CHR(10));
     SYS.DBMS_LOB.APPEND(v_KML,'      <colorMode>'||v_Colour_Mode||'</colorMode>'||CHR(10));
     If ( INSTR(UPPER(p_object_list),'POINT') > 0 ) Then
        SYS.DBMS_LOB.APPEND(v_KML,'      <scale>'||v_point_scale||'</scale>'||CHR(10));
        SYS.DBMS_LOB.APPEND(v_KML,'      <Icon>'||CHR(10));
        SYS.DBMS_LOB.APPEND(v_KML,'        <href>http://maps.google.com/mapfiles/kml/pal3/icon21.png</href>'||CHR(10));
        SYS.DBMS_LOB.APPEND(v_KML,'      </Icon>'||CHR(10));
        SYS.DBMS_LOB.APPEND(v_KML,'    </IconStyle>'||CHR(10));
     ElsIf ( INSTR(UPPER(p_object_list),'LINE') > 0 ) Then
        SYS.DBMS_LOB.APPEND(v_KML,'      <width>'||v_line_width||'</width>'||CHR(10));
        SYS.DBMS_LOB.APPEND(v_KML,'    </LineStyle>'||CHR(10));
     ElsIf ( INSTR(UPPER(p_object_list),'POLYGON') > 0 ) Then
        SYS.DBMS_LOB.APPEND(v_KML,'      <fill>'||v_polygon_fill||'</fill>'||CHR(10));
        SYS.DBMS_LOB.APPEND(v_KML,'      <outline>1</outline>'||CHR(10));
        SYS.DBMS_LOB.APPEND(v_KML,'    </PolyStyle>'||CHR(10));
     End If;
     SYS.DBMS_LOB.APPEND(v_KML,'  </Style>'||CHR(10));
     Exception
      When ISUNSUPPORTED Then
         raise_application_error(c_i_unsupported,c_s_unsupported,TRUE);
         RETURN ;
  END Header;

  --           I have chosen icon representations of points and not text with balloons. The icon is fixed but
  --           could be altered.
  --           I am aware that this should be done via XSLT
  --                 cf http://members.home.nl/cybarber/geomatters/GML2KML.xslt)
  --           rather than REGEXP_REPLACE hacks but, like you, I am time pressured.
  --           If you fix any of these concerns, please let me have a copy...
  --
  Procedure To_KML( p_geometry       In MdSys.Sdo_Geometry,
                    p_placemark_name In Varchar2,
                    p_description    In Varchar2,
                    p_elevation      In Number  := 0.0
                  )
  Is
     v_gtype        Number;
     v_dims         Number;
     c_geographic   VarChar2(20) := 'GEOGRAPHIC';
     v_coord_ref    VarChar2(20);
     ISPROJECTED    EXCEPTION;
     ISNULLSRID     EXCEPTION;
  Begin
     -- Will only work with geodetic data.
     IF ( P_GEOMETRY.SDO_SRID IS NULL ) THEN
         RAISE ISNULLSRID;
     ELSE
         SELECT SUBSTR(DECODE(CRS.COORD_REF_SYS_KIND,
                        'COMPOUND',    'PLANAR',
                        'ENGINEERING', 'PLANAR',
                        'GEOCENTRIC',  'GEOGRAPHIC',
                        'GEOGENTRIC',  'GEOGRAPHIC',
                        'GEOGRAPHIC2D','GEOGRAPHIC',
                        'GEOGRAPHIC3D','GEOGRAPHIC',
                        'PROJECTED',   'PLANAR',
                        'VERTICAL',    'GEOGRAPHIC',
                        'PLANAR'),1,20) as unit_of_measure
          INTO V_COORD_REF
          FROM MDSYS.SDO_COORD_REF_SYSTEM CRS 
         WHERE CRS.SRID = P_GEOMETRY.SDO_SRID;
         IF ( V_COORD_REF <> 'GEOGRAPHIC' ) THEN
              RAISE ISPROJECTED;
         END IF;
     END IF;
     v_gtype := p_geometry.get_gtype();
     SYS.DBMS_LOB.APPEND(V_KML,'  <Placemark>'||CHR(10));
     SYS.DBMS_LOB.APPEND(V_KML,'    <name><![CDATA['||P_PLACEMARK_NAME||']]>' || '</name>'||CHR(10));
     SYS.DBMS_LOB.APPEND(v_KML,'    <description><![CDATA['||p_description||']]>' || '</description>'||CHR(10));
     Case
      When v_gtype in (1,5) Then
       SYS.DBMS_LOB.APPEND(V_KML,'    <styleUrl>#PointStyle</styleUrl>'||CHR(10));
      When v_gtype in (2,6) Then
       SYS.DBMS_LOB.APPEND(v_KML,'    <styleUrl>#LineStyle</styleUrl>'||CHR(10));
      WHEN V_GTYPE IN (3,7) THEN
       SYS.DBMS_LOB.APPEND(V_KML,'    <styleUrl>#PolygonStyle</styleUrl>'||CHR(10));
     END CASE;
     SYS.DBMS_LOB.APPEND(v_KML,'    ');
     SYS.DBMS_LOB.APPEND(V_KML,MDSYS.SDO_UTIL.TO_KMLGEOMETRY(P_GEOMETRY));
     SYS.DBMS_LOB.APPEND(v_KML,'  </Placemark>'||CHR(10));
     Exception
      WHEN ISPROJECTED THEN
         raise_application_error(c_i_projected,c_s_projected,TRUE);
         RETURN;
      WHEN ISNULLSRID THEN
         raise_application_error(c_i_null_srid,c_s_null_srid,TRUE);
         RETURN;
  End To_KML;

  Function To_KML( p_geometry       In MdSys.Sdo_Geometry,
                   p_placemark_name In Varchar2,
                   p_description    In Varchar2,
                   p_elevation      In Number  := 0.0
                 )
    Return CLOB
  Is
     v_gtype        Number;
     v_dims         Number;
     c_geographic   VarChar2(20) := 'GEOGRAPHIC';
     v_coord_ref    VarChar2(20);
     v_KML          CLOB;
     ISPROJECTED    EXCEPTION;
  Begin
     -- Will only work with geodetic data.
     IF ( p_geometry.SDO_SRID IS NOT NULL ) THEN
        BEGIN
        SELECT c_geographic
          INTO v_coord_ref
          FROM MDSYS.GEODETIC_SRIDS
         WHERE SRID = p_geometry.sdo_srid;
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
              RAISE ISPROJECTED;
        END;
     END IF;
     SYS.DBMS_LOB.CreateTemporary( v_KML, TRUE, SYS.DBMS_LOB.CALL );
     v_gtype := p_geometry.get_gtype();
     SYS.DBMS_LOB.APPEND(v_KML,'<Placemark>'||CHR(10));
     SYS.DBMS_LOB.APPEND(v_KML,'  <name><![CDATA['||p_placemark_name||']]>' || '</name>'||CHR(10));
     SYS.DBMS_LOB.APPEND(v_KML,'  <description><![CDATA['||p_description||']]>' || '</description>'||CHR(10));
     Case
      When v_gtype in (1,5) Then
       SYS.DBMS_LOB.APPEND(v_KML,'  <styleUrl>#PointStyle</styleUrl>'||CHR(10));
      When v_gtype in (2,6) Then
       SYS.DBMS_LOB.APPEND(v_KML,'  <styleUrl>#LineStyle</styleUrl>'||CHR(10));
      When v_gtype in (3,7) Then
       SYS.DBMS_LOB.APPEND(v_KML,'  <styleUrl>#PolygonStyle</styleUrl>'||CHR(10));
     END CASE;
     SYS.DBMS_LOB.APPEND(v_KML,'  ');
     V_DIMS := P_GEOMETRY.GET_DIMS();
     SYS.DBMS_LOB.APPEND(V_KML,MDSYS.SDO_UTIL.TO_KMLGEOMETRY(P_GEOMETRY));
     SYS.DBMS_LOB.APPEND(v_KML,'</Placemark>'||CHR(10));
     Return v_KML;
     Exception
      When ISPROJECTED Then
         raise_application_error(c_i_projected,c_s_projected,TRUE);
         Return v_kml;
  End To_KML;

  Procedure Footer
  Is
  Begin
    SYS.DBMS_LOB.APPEND(v_KML,'</Document>'||CHR(10));
    SYS.DBMS_LOB.APPEND(v_KML,'</kml>'||CHR(10));
  End;

  Function GetDocument
    Return CLOB
  Is
  Begin
    RETURN v_KML;
  End;

END KML;
/

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'KML';
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

grant execute on kml to public;

quit;

