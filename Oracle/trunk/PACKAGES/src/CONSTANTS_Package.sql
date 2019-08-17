DEFINE defaultSchema = '&1'

SET VERIFY OFF;

SET SERVEROUTPUT On
ALTER SESSION SET plsql_optimize_level=1;

CREATE OR REPLACE PACKAGE CONSTANTS
AUTHID CURRENT_USER
AS
  -- Some useful constants
  --
  c_CoordMask            CONSTANT VARCHAR2(21)  := '999999999999.99999999';
  c_MaxVal               CONSTANT number        :=  999999999999.99999999;
  c_MinVal               CONSTANT number        := -999999999999.99999999;
  c_MaxLong              CONSTANT PLS_INTEGER   :=  2147483647;
  c_MinLong              CONSTANT PLS_INTEGER   := -2147483647;
  c_MAX                  CONSTANT NUMBER        := 1E38;
  c_Min                  CONSTANT NUMBER        := -1E38;

  c_PI                   CONSTANT NUMBER(16,14) := 3.14159265358979;

  /** Inspector function to return value of constants
  */
  FUNCTION PI
    RETURN NUMBER;
  FUNCTION MaxNumber
    RETURN NUMBER;
  FUNCTION MinNumber
    RETURN NUMBER;
  FUNCTION MaxLong
    RETURN NUMBER;
  FUNCTION MinLong
    RETURN NUMBER;

  -- ###########################################################################
  -- Public Enumerations describing SDO_GEOMETRY structure
  -- ###########################################################################
  
  -- n000 of SDO_GTYPE
  --
  uDimensions_None           Integer := -1;
  uDimensions_Two            Integer := 2;
  uDimensions_Three          Integer := 3;
  uDimensions_Four           Integer := 4;
  uDimensions_Unsupported    Integer := 5;

  -- 000n of SDO_GTYPE 
  --
  uGeomType_Unknown          Integer := 0;    -- Spatial ignores this geometry.
  uGeomType_SinglePoint      Integer := 1;    -- Geometry contains one point.
  uGeomType_SingleLineString Integer := 2;    -- Geometry contains one line string.
  uGeomType_SinglePolygon    Integer := 3;    -- Geometry contains one polygon with or without holes.
  uGeomType_Collection       Integer := 4;    -- Geometry is a heterogeneous collection of elements.
  uGeomType_MultiPoint       Integer := 5;    -- Geometry has multiple points.
  uGeomType_MultiLineString  Integer := 6;    -- Geometry has multiple line strings.
  uGeomType_MultiPolygon     Integer := 7;    -- Geometry has multiple, disjoint polygons (>1 exterior boundary).

  -- ###########################################################################
  -- Meanings of SDO_ETYPE and SDO_INTERPRETATION of SDO_ELEM_INFO structure
  -- ###########################################################################
  
  --  SDO_ETYPE SDO_INTERP..  MEANING
  --  0         0             Unsupported element type. Ignored by the Spatial functions and procedures.
  uElemType_Unknown                    CONSTANT BINARY_Integer := 0;
  --  Simple Element Types
  --  SDO_ETYPE values 1, 2, and 3 are considered simple elements.
  --  They are defined by a single triplet entry in the SDO_ELEM_INFO array.
  --  1         1             Point type.
  uElemType_Point                      CONSTANT BINARY_Integer := 1;     --  ie 1 x 1
  --  1         0             Point with orientation vector.
  uElemType_OrientationPoint           CONSTANT BINARY_Integer := 10;
  --  1         n > 1         Point cluster with n points.
  uElemType_MultiPoint                 CONSTANT BINARY_Integer := 100;   --  Who knows what N is! so just make this 100
  --  Linear types
  --  2         1             Line string whose vertices are connected by straight line segments.
  uElemType_LineString                 CONSTANT BINARY_Integer := 2;     --  ie 2 x 1
  --  2         2             Line string made up of a connected sequence of circular arcs.
  uElemType_CircularArc                CONSTANT BINARY_Integer := 4;     --  ie 2 x 2
  --  ======================================================================
  --  Simple Polygon Types
  --  --------------------
  --  3         1             Simple polygon whose vertices are connected by straight line segments.
  uElemType_Polygon                    CONSTANT BINARY_Integer := 3;     --  ie 3 x 1
  --  3         2             Polygon made up of a connected sequence of circular arcs.
  uElemType_PolyCircularArc            CONSTANT BINARY_Integer := 6;
  --  3         3             Optimised Rectangle type.
  uElemType_Rectangle                  CONSTANT BINARY_Integer := 9;
  --  3         4             Circle type. Described by three points, all on the circumference of the circle.
  uElemType_Circle                     CONSTANT BINARY_Integer := 12;
  --  Polygons with holes (ie Outer and Inner Shells)
  --  -----------------------------------------------
  --  1003: exterior polygon ring (must be specified in counterclockwise order)
  --  2003: interior polygon ring (must be specified in clockwise order)
  uElemType_PolygonExterior            CONSTANT BINARY_Integer := 1003;  --  ie 1003 x 1
  uElemType_PolygonInterior            CONSTANT BINARY_Integer := 2003;  --  ie 2003 x 1
  uElemType_PolyCircularArcExt         CONSTANT BINARY_Integer := 2006;  --  1003 x 2
  uElemType_PolyCircularArcInt         CONSTANT BINARY_Integer := 4006;  --  2003 x 2
  uElemType_RectangleExterior          CONSTANT BINARY_Integer := 3009;  --  ie 1003 x 3
  uElemType_RectangleInterior          CONSTANT BINARY_Integer := 6009;  --  ie 2003 x 3
  uElemType_CircleExterior             CONSTANT BINARY_Integer := 4012;  --  ie 1003 x 4
  uElemType_CircleInterior             CONSTANT BINARY_Integer := 8012;  --  ie 2003 x 4
  --  ===========================================================================
  --  SDO_ETYPE values 4 and 5 are considered compound elements.
  --  They contain at least one header triplet with a series of triplet values that belong to the compound element.
  --  4         n > 1               Line string with some vertices connected by straight line segments and some
  --                                by circular arcs. The value, n, in the Interpretation column specifies the
  --                                number of contiguous subelements that make up the line string.
  --                                The next n triplets in the SDO_ELEM_INFO array describe each of these subelements.
  --                                The subelements can only be of SDO_ETYPE 2.
  --                                The last point of a subelement is the first point of the next subelement, and
  --                                must not be repeated.
  uElemType_CompoundLineString         CONSTANT BINARY_Integer := 400;
  --  5         n > 1               Compound polygon with some vertices connected by straight line segments and some by circular arcs. The value, n, in the Interpretation column specifies the number of contiguous subelements that make up the polygon.
  --                                The next n triplets in the SDO_ELEM_INFO array describe each of these subelements.
  --                                The subelements can only be of SDO_ETYPE 2.
  --                                The end point of a subelement is the start point of the next subelement, and it must
  --                                not be repeated. The start and end points of the polygon must be the same.
  uElemType_CompoundPolygon            CONSTANT BINARY_Integer := 500;
  --  The following are considered variants of type 5, with the first digit
  --  indicating exterior (1) or interior (2):
  --  1005: exterior polygon ring (must be specified in counterclockwise order)
  --  2005: interior polygon ring (must be specified in clockwise order)
  uElemType_CompoundPolyExt            CONSTANT BINARY_Integer := 1005;
  uElemType_CompoundPolyInt            CONSTANT BINARY_Integer := 2005;
  -- ###########################################################################

  /**
  * Some strings for use in a custom WKT coverter based on AutoDesk's AGF Text
  * AGF Text is the textual analogue to the binary AGF format.
  * It is a superset of the OGC WKT format.
  * (see FDO Developers Guide)
  **/
  /**
  * The grammar definition for AGF Text is the following:
  *
  * <AGF Text> ::= POINT <Dimensionality> <PointEntity>        -- d001
  * | LINESTRING         <Dimensionality> <LineString>         -- d002
  * | POLYGON            <Dimensionality> <Polygon>            -- d002
  * | CURVESTRING        <Dimensionality> <CurveString>        -- d002 all interpretation elements must be Curves
  * | CURVEPOLYGON       <Dimensionality> <CurvePolygon>       -- d003 all interpretation elements must be Curves
  * | MULTIPOINT         <Dimensionality> <MultiPoint>         -- d005
  * | MULTILINESTRING    <Dimensionality> <MultiLineString>    -- d006
  * | MULTIPOLYGON       <Dimensionality> <MultiPolygon>       -- d007
  * | MULTICURVESTRING   <Dimensionality> <MultiCurveString>   -- d006 all interpretation elements must be Curves
  * | MULTICURVEPOLYGON  <Dimensionality> <MultiCurvePolygon>  -- d006 all interpretation elements must be Curves
  * | GEOMETRYCOLLECTION <GeometryCollection>                  -- d004
  *
  * <PointEntity> ::= '(' <Point> ')'
  * <LineString> ::= '(' <PointCollection> ')'
  * <Polygon> ::= '(' <LineStringCollection> ')'
  * <MultiPoint> ::= '(' <PointCollection> ')'
  * <MultiLineString> ::= '(' <LineStringCollection> ')'
  * <MultiPolygon> ::= '(' <PolygonCollection> ')'
  * <GeometryCollection : '(' <AGF Collection Text> ')'
  * <CurveString> ::= '(' <Point> '(' <CurveSegmentCollection> ')' ')'
  * <CurvePolygon> ::= '(' <CurveStringCollection> ')'
  * <MultiCurveString> ::= '(' <CurveStringCollection> ')'
  * <MultiCurvePolygon> ::= '(' <CurvePolygonCollection> ')'
  * <Dimensionality> ::= // default to XY
  * | XY
  * | XYZ
  * | XYM
  * | XYZM
  * <Point> ::= DOUBLE DOUBLE
  * | DOUBLE DOUBLE DOUBLE
  * | DOUBLE DOUBLE DOUBLE DOUBLE
  * <PointCollection> ::= <Point>
  * | <PointCollection ',' <Point>
  * <LineStringCollection> ::= <LineString>
  * | <LineStringCollection> ',' <LineString>
  * <PolygonCollection> ::= <Polygon>
  * | <PolygonCollection> ',' <Polygon>
  * <AGF Collection Text> ::= <AGF Text>
  * | <AGF Collection Text> ',' <AGF Text>
  * <CurveSegment> ::= CIRCULARARCSEGMENT '(' <Point> ',' <Point> ')'
  * | LINESTRINGSEGMENT '(' <PointCollection> ')'
  * <CurveSegmentCollection> ::= <CurveSegment>
  * | <CurveSegmentCollection> ',' <CurveSegment>
  * <CurveStringCollection> ::= <CurveString>
  * | <CurveStringCollection> ',' <CurveString>
  * <CurvePolygonCollection> ::= <CurvePolygon>
  * | <CurvePolygonCollection> ',' <CurvePolygon>
  **/
  c_1D_Prefix              CONSTANT varchar2(4)  := 'NONE';
  c_2D_Prefix              CONSTANT varchar2(2)  := 'XY';
  c_3D_Prefix              CONSTANT varchar2(3)  := 'XYZ';
  c_4D_Prefix              CONSTANT varchar2(4)  := 'XYZM';
  c_5D_Prefix              CONSTANT varchar2(11) := 'UNSUPPORTED';

  -- Point (a single point object),
  c_Point_WKT              CONSTANT varchar2(20) := 'POINT';
  -- LineString (one or more connected line segments, defined by positions at the vertices),
  c_LineString_WKT         CONSTANT varchar2(20) := 'LINESTRING';
  -- CurveString (a collection of connected circular arc segments and linear segments),
  c_CurveString_WKT        CONSTANT varchar2(20) := 'CURVESTRING';
  -- Polygon (a surface bound by one outer ring and zero or more interior rings;
  --          the rings are closed, connected line segments, defined by positions at the vertices),
  c_Polygon_WKT            CONSTANT varchar2(20) := 'POLYGON';
  -- CurvePolygon (a surface bound by one outer ring and zero or more interior rings;
  --               the rings are closed, connected curve segments),
  c_CurvePolygon_WKT       CONSTANT varchar2(20) := 'CURVEPOLYGON';
  -- MultiPoint (multiple points, which may be disjoint),
  c_Multi_Point_WKT        CONSTANT varchar2(20) := 'MULTIPOINT';
  -- MultiLineString (multiple LineStrings, which may be disjoint),
  c_Multi_LineString_WKT   CONSTANT varchar2(20) := 'MULTILINESTRING';
  -- MultiCurveString (multiple CurveStrings, which may be disjoint),
  c_Multi_CurveString_WKT  CONSTANT varchar2(20) := 'MULTICURVESTRING';
  -- MultiPolygon (multiple Polygons, which may be disjoint),
  c_Multi_Polygon_WKT      CONSTANT varchar2(20) := 'MULTIPOLYGON';
  -- MultiCurvePolygon (multiple CurvePolygons, which may be disjoint), and
  c_Multi_CurvePolygon_WKT CONSTANT varchar2(20) := 'MULTICURVEPOLYGON';
  -- MultiGeometry (a heterogenous collection of geometries, which may be disjoint).
  c_Collection_WKT         CONSTANT varchar2(20) := 'GEOMETRYCOLLECTION';
  -- Most geometry types are defined using either curve segments or a series of
  -- connected line segments. Curve segments are used where non-linear curves
  -- may appears. The following curve segment types are supported:
  --
  -- CircularArcSegment (circular arc defined by three positions on the arc),
  c_CircularArcSegment_WKT CONSTANT varchar2(20) := 'CIRCULARARCSEGMENT';
  -- LineStringSegment ( a series of connected line segments, defined by positions are the vertices).
  c_LineStringSegment_WKT  CONSTANT varchar2(20) := 'LINESTRINGSEGMENT';

  -- *********** EXAMPLES
  -- POINT XY (10 11) // equivalent to POINT (10 11)
  -- POINT XYZ (10 11 12)
  -- POINT XYM (10 11 1.2)
  -- POINT XYZM (10 11 12 1.2)
  -- GEOMETRYCOLLECTION (POINT xyz (10 11 12),POINT XYM (30 20 1.8),
  -- LINESTRING XYZM(1 2 3 4, 3 5 15, 3 20 20))
  -- CURVESTRING (0 0 (LINESTRINGSEGMENT (10 10, 20 20, 30 40))))
  -- CURVESTRING (0 0 (CIRCULARARCSEGMENT (11 11, 12 12), LINESTRINGSEGMENT (10 10, 20 20, 30 40)))
  -- CURVESTRING (0 0 (ARC (11 11, 12 12), LINESTRINGSEGMENT (10 10, 20 20, 30 40)))
  -- CURVESTRING XYZ (0 0 0 (LINESTRINGSEGMENT (10 10 1, 20 20 1, 30 40 1)))
  -- MULTICURVESTRING ((0 0 (LINESTRINGSEGMENT (10 10, 20 20, 30 40))),(0 0 (ARC (11 11, 12 12), LINESTRINGSEGMENT (10 10, 20 20, 30 40))))
  -- CURVEPOLYGON ((0 0 (LINESTRINGSEGMENT (10 10, 10 20, 20 20), ARC (20 15, 10 10))), (0 0 (ARC (11 11, 12 12), LINESTRINGSEGMENT (10 10, 20 20, 40 40, 90 90))))
  -- MULTICURVEPOLYGON (((0 0 (LINESTRINGSEGMENT (10 10, 10 20, 20 20), ARC (20 15, 10 10))), (0 0 (ARC (11 11, 12 12), LINESTRINGSEGMENT (10 10, 20 20, 40 40, 90 90)))),((0 0 (LINESTRINGSEGMENT (10 10, 10 20, 20 20), ARC (20 15, 10 10))), (0 0 (ARC (11 11, 12 12), LINESTRINGSEGMENT (10 10, 20 20, 40 40, 90 90)))))

  -- Additional Ones
  c_Rectangle_WKT      CONSTANT varchar2(4) := 'MBR';

  -- ===========================================================================================

  -- Error messages used by other packages
  --
  c_i_unsupported        CONSTANT INTEGER       := -20101;
  c_s_unsupported        CONSTANT VARCHAR2(100) := 'Compound objects, Circles, Arcs and Optimised Rectangles currently not supported.';
  c_i_point_vector       CONSTANT INTEGER       := -20102;
  c_s_point_vector       CONSTANT VARCHAR2(100) := 'Can''t create a vector from a point or multi-point sdo_geometry.';
  c_i_cmpnd_vector       CONSTANT INTEGER       := -20103;
  c_s_cmpnd_vector       CONSTANT VARCHAR2(100) := 'Compound sdo_geometry objects not supported.';
  c_i_centroid           CONSTANT INTEGER       := -20104;
  c_s_centroid           CONSTANT VARCHAR2(150) := 'sdo_centroid only supported on Polygon (xxx3) and Multi-Polygon (xxx7) geometries.';
  c_i_paracentroid       CONSTANT INTEGER       := -20105;
  c_s_paracentroid       CONSTANT VARCHAR2(150) := 'sdo_centroid calculation failed, couldn''t find two crossing points up from centre bottom edge of bounding box';
  c_i_multipolygon       CONSTANT INTEGER       := -20106;
  c_s_multipolygon       CONSTANT VARCHAR2(100) := 'Multi-Centroid only supported on multi-geometries.';
  c_i_isSimple           CONSTANT INTEGER       := -20107;
  c_s_isSimple           CONSTANT VARCHAR2(100) := 'isSimple not supported on compound (xxx4) geometries.';
  c_i_coordinate_read    CONSTANT INTEGER       := -20108;
  c_s_coordinate_read    CONSTANT VARCHAR2(100) := 'Could not read coordinates of geometry.';
  c_i_first_element      CONSTANT INTEGER       := -20109;
  c_s_first_element      CONSTANT VARCHAR2(100) := 'Could not read first element of geometry.';
  c_i_projected          CONSTANT INTEGER       := -20110;
  c_s_projected          CONSTANT VARCHAR2(100) := 'Projected data not supported.';
  c_i_geodetic           CONSTANT INTEGER       := -20111;
  c_s_geodetic           CONSTANT VARCHAR2(100) := 'Geodetic data not supported.';
  c_i_table_geometry     CONSTANT INTEGER       := -20112;
  c_s_table_geometry     CONSTANT VARCHAR2(100) := 'No table exists with supplied sdo_geometry column name.';
  c_i_no_diminfo         CONSTANT INTEGER       := -20113;
  c_s_no_diminfo         CONSTANT VARCHAR2(100) := 'No DIMINFO record exists in xxx_SDO_GEOM_METADATA.';
  c_i_not_geographic     CONSTANT INTEGER       := -20114;
  c_s_not_geographic     CONSTANT VARCHAR2(100) := 'Geodetic data not supported.';
  c_i_dimensionality     CONSTANT INTEGER       := -20115;
  c_s_dimensionality     CONSTANT VARCHAR2(100) := 'Unable to determine dimensionality from geometry''s gtype (:1)';
  c_i_not_line           CONSTANT INTEGER       := -20116;
  c_s_not_line           CONSTANT VARCHAR2(100) := 'Input geometry is not a linestring';
  c_i_not_point          CONSTANT INTEGER       := -20117;
  c_s_not_point          CONSTANT VARCHAR2(100) := 'Input geometry is not a point';
  c_i_not_polygon        CONSTANT INTEGER       := -20118;
  c_s_not_polygon        CONSTANT VARCHAR2(100) := 'Input geometry is not a polygon (xxx3) or multi-polygon (xxx7)';
  c_i_null_tolerance     CONSTANT INTEGER       := -20119;
  c_s_null_tolerance     CONSTANT VARCHAR2(100) := 'Input tolerance must not be null';
  c_i_null_geometry      CONSTANT INTEGER       := -20120;
  c_s_null_geometry      CONSTANT VARCHAR2(100) := 'Input geometry must not be null';
  c_i_CircArc2LineString CONSTANT NUMBER        := -20121;
  c_s_CircArc2LineString CONSTANT VARCHAR2(100) := 'Problem converting circular arc to a linestring';
  c_i_CircleProperties   CONSTANT NUMBER        := -20122;
  c_s_CircleProperties   CONSTANT VARCHAR2(100) := 'Circle properties cannot be computed when converting circular arc to a linestring';
  c_i_Circle2Polygon     CONSTANT NUMBER        := -20123;
  c_s_Circle2Polygon     CONSTANT VARCHAR2(100) := 'Problem converting Circle to Polygon.';
  c_i_ShapeNoElements    CONSTANT NUMBER        := -20124;
  c_s_ShapeNoElements    CONSTANT VARCHAR2(100) := 'Shape did not have any elements.';
  c_i_NoDimension        CONSTANT NUMBER        := -20125;
  c_s_NoDimension        CONSTANT VARCHAR2(100) := 'Geometry does not have a dimension set: use SetGType.';
  c_i_null_srid          CONSTANT INTEGER       := -20126;
  c_s_null_srid          CONSTANT VARCHAR2(100) := 'Input srid must not be null';
  c_i_null_parameter     CONSTANT INTEGER       := -20127;
  c_s_null_parameter     CONSTANT VARCHAR2(100) := 'Input parameters must not be null';
  c_i_invalid_unit       CONSTANT INTEGER       := -20127;
  c_s_invalid_unit       CONSTANT VARCHAR2(100) := 'Input unit of measure - must exist in mdsys.sdo_dist_units';
  c_i_invalid_srid       CONSTANT INTEGER       := -20128;
  c_s_invalid_srid       CONSTANT VARCHAR2(100) := 'Input srid - must exist in mdsys.cs_srs';
  c_i_arcs_unsupported   CONSTANT INTEGER       := -20129;
  c_s_arcs_unsupported   CONSTANT VARCHAR2(100) := 'Geometries with Circular Arcs not supported.';
  c_i_null_diminfo       CONSTANT INTEGER       := -20130;
  c_s_null_diminfo       CONSTANT VARCHAR2(100) := 'Input dimarray must not be null';

END Constants;
/
show errors

create or replace
package body Constants AS

  Function PI
           Return number
  Is
  Begin
     Return &&defaultSchema..constants.c_PI;
  End PI;

  Function MaxNumber
           Return number
  Is
  Begin
     Return &&defaultSchema..constants.c_Max;
  End MaxNumber;

  FUNCTION MinNumber
           Return number
  Is
  Begin
     Return &&defaultSchema..constants.c_Min;
  End MinNumber;

  Function MaxLong
           Return number
  Is
  Begin
     Return &&defaultSchema..constants.c_MaxLong;
  End MaxLong;

  FUNCTION MinLong
           Return number
  Is
  Begin
     Return &&defaultSchema..constants.c_MinLong;
  End MinLong;

end constants;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'CONSTANTS';
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

grant execute on constants to public;

QUIT;
