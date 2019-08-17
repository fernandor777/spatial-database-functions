DEFINE defaultSchema='&1'

alter session set plsql_optimize_level=1;

create or replace Package GF
AUTHID CURRENT_USER
As

-- ----------------------------------------------------------------------------------------
  -- @application: GF
  -- @precis     : Provides a simple interface for accessing the complexities of an Oracle Spatial MDSYS.SDO_GEOMETRY.
  -- @version    : 1.3
  -- @description: An Oracle Spatial SDO_GEOMETRY is made up of multiple parts all represented via SQL3
  --               objects like Arrays. While the vertices in an SDO_GEOMETRY are stored according to
  --               the OGIS Simple Features Specification, accessing and interpreting this data can
  --               be quite complicated.
  --               This code attempts to provide programmers with a simple interface for accessing
  --               all the elements of an SDO_Geometry.
  -- @note       : No provision is provided to create an Sdo_Geometry.
  -- @usage      : See associated CLayerOracleSpatial class.
  -- @requires   : Oracle Objects for Ole - OO4O. (tested with 10g client and SQLnet).
  -- @return     : Nothing.
  -- @tobedone   : Support for GeoRasters; SDO_Topo; SDO_Geometry creation.
  -- @licensing  : Open Source (whatever model you like) - just acknowledge the work and if you fix any
  --               bugs or enhance it, give us a copy in return!
  -- @history    : Simon Greener - 2004,2005 - Original Coding - used actual Sdo_Geometry Object
  -- @history    : Simon Greener - May 2005 - Added in missing ETypes for CircularArcPolygons
  -- @history    : Simon Greener - May 2005 - Version 1.1 - Performance tuning
  --                                        - Dumped SdoPoint support;
  --                                        - Dumped dereferencing of Elements of Sdo_Geometry Object (too slow)
  --                                        - optimised for Sdo_Element_Info and Sdo_Ordinates
  --                                        - Commented out SRID support due to speed in access in OO4O
  -- @history    : Simon Greener - Mar 2006 - Version 1.2
  --                                        - Investigated OraCollection Iterator use - no benefits
  --                                        - Dumped internal eiaShape, oaShape as object dereferncing in OO4O is just
  --                                          too slow instead I pass everything by reference from Dynaset Object
  -- @history    : Simon Greener - Apr 2006 - Pulled into CLayerOracleSpatial as "inline" code
  -- @history    : Simon Greener - Jun 2006 - Ported to Oracle PL/SQL to try and standardise on one code base.
  -- @history    : Simon Greener - Jan 2007 - Modified ConvertSpecialElements to be a Pipelined funciton
  -- @history    : Simon Greener - Feb 2007 - Added isFirstCompoundElementChild and renamed isLastCompoundElement to isLastCompoundElementChild
  --
  -- Documentation - OO4O types and the Oracle Spatial UDT
  --
  -- MDSYS.SDO_GEOMETRY is an OraObject
  --
  -- SQL> describe mdsys.sdo_geometry
  -- Name                                      Null?    Type
  -- ----------------------------------------- -------- ----------------------------
  -- SDO_GTYPE                                          Number
  -- SDO_SRID                                           Number
  -- sdo_point                                          SDO_POINT_TYPE
  -- SDO_ELEM_INFO                                      sdo_elem_info_array
  -- SDO_ORDINATES                                      sdo_ordinate_array
  --
  -- MDSYS.SDO_POINT is an OraObject
  --
  -- SQL> describe mdsys.sdo_point_type
  -- Name                                      Null?    Type
  -- ----------------------------------------- -------- ----------------------------
  -- X                                                  Number
  -- Y                                                  Number
  -- Z                                                  Number
  --
  -- MDSYS.SDO_ELEM_INFO is an OraCollection
  --
  -- SQL> describe mdsys.sdo_elem_info_array
  -- mdsys.sdo_elem_info_array VARRAY(1048576) OF NUMBER
  --
  -- MDSYS.SDO_ORDINATES is an OraCollection
  --
  -- SQL> describe mdsys.sdo_ordinate_array
  -- mdsys.sdo_ordinate_array VARRAY(1048576) OF NUMBER

  -- ###########################################################################
  -- Public Enumerations
  -- ###########################################################################
  uDimensions_None           Integer := -1;
  uDimensions_Two            Integer := 2;
  uDimensions_Three          Integer := 3;
  uDimensions_Four           Integer := 4;
  uDimensions_Unsupported    Integer := 5;

  -- Based on SDO_GTYPE of each SDO_GEOMETRY
  uGeomType_Unknown          Integer := 0;    -- Spatial ignores this geometry.
  uGeomType_SinglePoint      Integer := 1;    -- Geometry contains one point.
  uGeomType_SingleLineString Integer := 2;    -- Geometry contains one line string.
  uGeomType_SinglePolygon    Integer := 3;    -- Geometry contains one polygon with or without holes.
  uGeomType_Collection       Integer := 4;    -- Geometry is a heterogeneous collection of elements.
  uGeomType_MultiPoint       Integer := 5;    -- Geometry has multiple points.
  uGeomType_MultiLineString  Integer := 6;    -- Geometry has multiple line strings.
  uGeomType_MultiPolygon     Integer := 7;    -- Geometry has multiple, disjoint polygons (>1 exterior boundary).

  -- ###########################################################################
  -- Public Enumerations
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

  Procedure Initialise;

  -- Setters
  --
  Procedure SetArcToChord( p_arc2chord   in number );
  Procedure SetGeometry( p_geometry IN MDSYS.SDO_Geometry );
  Procedure New;
  Procedure SetFullGType ( p_FullGType in integer );
  Procedure SetSRID  ( p_SRID in integer );
  Procedure InitElementInfoArray;
  Procedure NewElementInfoArray( p_elem_info in &&defaultSchema..T_ElemInfo );
  Procedure SetSdo_point( p_point in MDSYS.SDO_Point_Type );
  Procedure SetSdo_point( p_x in number,
                          p_y in integer,
                          p_z in integer);
  Procedure InitOrdinateArray;
  Procedure SetCoordinate( p_Coord4D     in &&defaultSchema..ST_Point );
  Procedure SetCoordinate( p_coord_index in integer,
                           p_Coord4D     in &&defaultSchema..ST_Point );
  Procedure SetCoordinate( p_x in number,
                           p_y in number,
                           p_z in number,
                           p_m in number);

  -- Interators
  --
  Function  FirstElement
            Return Boolean Deterministic;
  Function  NextElement
            Return Boolean Deterministic ;
  Function  FirstCoordinate
            Return Boolean Deterministic;
  Function  NextCoordinate
            Return Boolean Deterministic ;

  -- Inspectors
  --
  Function  GetGeometry
            Return MDSYS.SDO_Geometry Deterministic;
  Function  GetSRID
            return integer deterministic;
  Function  IsNullGeometry
            Return Boolean Deterministic ;
  Function  GetDimension
            Return Integer Deterministic ;
  Function  GetNumParts
            Return Integer Deterministic ;
  Function  GetStartOffset
            Return Integer Deterministic ;
  Function  GetEndOffset
            Return Integer Deterministic ;
  Function  GetElementType
            Return Integer Deterministic ;
  Function  GetElementGeomType
            Return Integer Deterministic ;
  Function  GetInterpretation
            Return Integer Deterministic ;
  Function  GetParentElementGeomType
            Return Integer Deterministic ;
  Function  isCompoundElement
            Return Boolean Deterministic;
  Function  isFirstCompoundElementChild
            Return Boolean Deterministic;
  Function  isLastCompoundElementChild
            Return Boolean Deterministic;
  Function  isCompoundElementChild
            Return Boolean Deterministic;
  Function  GetNumCoordinates
            Return Integer Deterministic;
  Function  GetSubElementCount
            Return Integer Deterministic;
  Function  GetSdo_point
            Return MDSYS.SDO_Point_Type Deterministic ;
  Function  GetElementCoordinateCount
            Return Integer Deterministic ;
  Function  GetNumberOfArcsInElement
            Return Integer Deterministic;
  Function  GetArcToChord return number deterministic;
  Function  GetElemInfo( p_Element in integer )
            Return &&defaultSchema..T_ElemInfo deterministic;
  Function  GetElemInfo
            Return &&defaultSchema..T_ElemInfo deterministic;
  Function  GetElemInfoArray( p_Element in integer )
            Return MDSYS.SDO_Elem_Info_Array deterministic;
  Function  GetElemInfoArray
            Return MDSYS.SDO_Elem_Info_Array deterministic;
  Function  GetCoordinate
            Return &&defaultSchema..ST_Point deterministic;
  Function  GetCoordinate( p_lCoordinate in integer )
            Return &&defaultSchema..ST_Point deterministic;
  Function  GetElementOrdinates( p_lBound in integer,
                                 p_uBound in integer )
            Return MDSYS.SDO_Ordinate_Array deterministic;
  Function  GetGType
     return integer deterministic;
  Function  GetFullGType
            return integer deterministic;

  -- Special
  --
  Function  ConvertSpecialElements( p_arc2chord in number := 0.1 )
            return &&defaultSchema..ST_PointSet Pipelined;
END;
/
show errors

create or replace Package Body GF
As
  c_module_name              CONSTANT varchar2(128) := 'GeometryFactory';

  -- Private Types
  Type GeomElementType IS RECORD (
    -- For COMPOUND elements 4 and 5
    uParentGeomType    INTEGER,   -- Actually uElemType see above
    lFirstSubElement   INTEGER,
    lLastSubElement    INTEGER,
    -- Common items
    uGeomType          INTEGER,   -- Actually uElemType
    lEType             INTEGER,
    lInterpretation    INTEGER,
    lStartOrdinate     INTEGER,
    lEndOrdinate       INTEGER,
    lOrdinateCount     INTEGER,   -- Total number of ordinates in the Element
    lCoordCount        INTEGER,   -- Total number of coordinates in the Element
    lCoordIndex        INTEGER    -- Current coordinate in the element being processed
  );

  Type uGeomUDT_FieldType IS Record (
    mobjGeometry       MDSYS.SDO_Geometry,
    lFullGType         INTEGER,                     -- As in d00x
    uGeomType          INTEGER,                     -- Actually uGeomType_*    Enum in package header
    lDimension         INTEGER,                     -- Actually uSpatialDims_* Enum in package header
    lSRID              INTEGER,                     -- Actually uGeomType_*    Enum in package header
    Point              MDSYS.SDO_Point_Type,        -- Externally declared
    vaElementInfo      MDSYS.SDO_ELEM_Info_Array,
    lNumElements       PLS_INTEGER,
    uCurrentElement    GeomElementType,             -- Keep information for this as well
    lCurrentElement    PLS_INTEGER,                 -- As we iterate over elements and the coordinates.. keep reference
    -- Ordinate Parts
    vaOrdinates        MDSYS.SDO_Ordinate_Array,
    lNumOrdinates      PLS_INTEGER,                 -- Could .COUNT on vaCoordinates but ....
    lNumCoordinates    PLS_INTEGER,                 -- Saves a / lDimension
    lCurrentCoordinate PLS_INTEGER                  -- As we iterate over elements and the coordinates.. keep count
  );

  -- ===============================================================
  -- Factory Global Variables
  --
  mutGeomUDTFields    uGeomUDT_FieldType;
  mdArcToChord        NUMBER;

  -- #################################################################################
  -- Procedures and Functions
  --

  Procedure InitElementInfoArray
  Is
    sProcID CONSTANT varchar2(256) := C_MODULE_NAME || '.InitElementInfoArray';
  Begin
    -- Element is defined as (ETYPE,Interpretation,Offset) triplet
    -- Set element in the SDO_elem_info array being processed to before the first
    mutGeomUDTFields.lCurrentElement                 := 0;
    -- And initialise the ParentGeomElement pointer
    mutGeomUDTFields.uCurrentElement.uParentGeomType := uElemType_Unknown;
    -- Get the actual number of elements in the sdo_elem_info array
    mutGeomUDTFields.lNumElements                    := (mutGeomUDTFields.vaElementInfo.COUNT / 3);
    If ( mutGeomUDTFields.lNumElements = 0 ) Then
       raise_application_error(&&defaultSchema..CONSTANTS.c_i_ShapeNoElements,&&defaultSchema..CONSTANTS.c_s_ShapeNoElements,False);
    End If;
  End InitElementInfoArray;

  Procedure InitOrdinateArray
  Is
    sProcID CONSTANT varchar2(256) := C_MODULE_NAME || '.InitOrdinateArray';
  Begin
    mutGeomUDTFields.lCurrentCoordinate                 := 0;
    mutGeomUDTFields.lNumOrdinates                      := mutGeomUDTFields.vaOrdinates.COUNT;
    mutGeomUDTFields.lNumCoordinates                    := mutGeomUDTFields.lNumOrdinates / mutGeomUDTFields.lDimension;
    mutGeomUDTFields.uCurrentElement.lOrdinateCount     := -1;
    mutGeomUDTFields.uCurrentElement.lCoordIndex := -1;
  End InitOrdinateArray;

  Procedure Initialise
  Is
    sProcID CONSTANT varchar2(256) := C_MODULE_NAME || '.Initialise';
  Begin
    mutGeomUDTFields.lNumOrdinates                    := -1;
    mutGeomUDTFields.lNumElements                     := -1;
    mutGeomUDTFields.lDimension        := uDimensions_None;
    mutGeomUDTFields.lCurrentElement                  := 0;
    mutGeomUDTFields.uCurrentElement.lStartOrdinate   := -1;
    mutGeomUDTFields.uCurrentElement.lEndOrdinate     := -1;
    mutGeomUDTFields.uCurrentElement.lOrdinateCount   := -1;
    mutGeomUDTFields.uCurrentElement.lEType           := -1;
    mutGeomUDTFields.uCurrentElement.lInterpretation  := -1;
    mutGeomUDTFields.uCurrentElement.uGeomType        := uElemType_Unknown;
    mutGeomUDTFields.uCurrentElement.uParentGeomType  := uElemType_Unknown;
    mutGeomUDTFields.uCurrentElement.lFirstSubElement := 0;
    mutGeomUDTFields.uCurrentElement.lLastSubElement  := -1;
    mdArcToChord := 0.003;
  End Initialise;

  Procedure SetArcToChord( p_arc2chord in number )
  Is
    sProcID CONSTANT varchar2(256) := C_MODULE_NAME || '.SetArcToChord';
  Begin
    mdArcToChord := p_arc2chord;
  End SetArcToChord;

  Function GetArcToChord
           return number
  Is
    sProcID CONSTANT varchar2(256) := C_MODULE_NAME || '.GetArcToChord';
  Begin
    Return mdArcToChord;
  End GetArcToChord;

  -- Return actual simple geometry type...
  --
  Function GetGType
           return integer
  Is
    sProcID CONSTANT varchar2(256) := C_MODULE_NAME || '.GetGType';
  Begin
    Return mutGeomUDTFields.uGeomType;
  End GetGType;

  -- Get Full d00x type of geometry
  --
  Function GetFullGType
           return integer
  Is
  Begin
     Return mutGeomUDTFields.lFullGType;
  End GetFullGType;

  -- Set Full d00x type of geometry
  --
  Procedure SetFullGType ( p_FullGType in integer )
  Is
    sProcID CONSTANT varchar2(256) := C_MODULE_NAME || '.SetFullGType';
  Begin
     mutGeomUDTFields.lFullGType := p_FullGType;
     mutGeomUDTFields.uGeomType  := MOD(mutGeomUDTFields.lFullGType,10);
     mutGeomUDTFields.lDimension := mutGeomUDTFields.lFullGType / 1000;
  End SetFullGType;

  Function  GetDimension
            return integer
  Is
    sProcID CONSTANT varchar2(256) := C_MODULE_NAME || '.GetDimension';
  Begin
    Return mutGeomUDTFields.lDimension;
  End;

  Function GetSRID
           return integer
  Is
    sProcID CONSTANT varchar2(256) := C_MODULE_NAME || '.GetSRID';
  Begin
    Return mutGeomUDTFields.lSRID;
  End GetSRID;

  Procedure SetSRID ( p_SRID in integer )
  Is
    sProcID CONSTANT varchar2(256) := C_MODULE_NAME || '.SetSRID';
  Begin
     mutGeomUDTFields.lSRID  := p_SRID;
  End SetSRID;

  Procedure SetGeometry( p_geometry IN MDSYS.SDO_GEOMETRY )
  Is
    sProcID CONSTANT varchar2(256) := C_MODULE_NAME || '.SetGeometry';
  Begin
     mutGeomUDTFields.mobjGeometry := p_geometry;
     mutGeomUDTFields.lFullGType   := mutGeomUDTFields.mobjGeometry.Sdo_Gtype;
     mutGeomUDTFields.uGeomType    := MOD(mutGeomUDTFields.lFullGType,10);
     If mutGeomUDTFields.lFullGType < 1000 Then
       mutGeomUDTFields.lFullGType := 2000 + mutGeomUDTFields.lFullGType;
     End If;
     mutGeomUDTFields.lDimension := mutGeomUDTFields.lFullGType / 1000;
     If mutGeomUDTFields.mobjGeometry.Sdo_Srid IS NOT NULL Then
        mutGeomUDTFields.lSRID     := mutGeomUDTFields.mobjGeometry.Sdo_Srid;
     End If;
     mutGeomUDTFields.Point := NULL;
     If ( p_geometry.sdo_point IS NOT NULL) Then
       mutGeomUDTFields.Point := p_geometry.Sdo_Point;
     End If;
     If ( p_geometry.sdo_elem_info IS NOT NULL) Then
       mutGeomUDTFields.vaElementInfo := p_geometry.sdo_elem_info;
       InitElementInfoArray();
       mutGeomUDTFields.vaOrdinates   := p_geometry.Sdo_Ordinates;
       InitOrdinateArray();
     End If;
  End SetGeometry;

  Procedure New
  Is
    sProcID CONSTANT varchar2(256) := C_MODULE_NAME || '.New';
  Begin
     mutGeomUDTFields.mobjGeometry  := NULL; -- MDSYS.SDO_GEOMETRY(&&defaultSchema..CONSTANTS.c_MaxVal,&&defaultSchema..CONSTANTS.c_MaxVal);
     mutGeomUDTFields.lFullGType    := NULL;
     mutGeomUDTFields.uGeomType     := NULL;
     mutGeomUDTFields.lDimension    := uDimensions_None;
     mutGeomUDTFields.lSRID         := NULL;
     mutGeomUDTFields.Point         := NULL;
     mutGeomUDTFields.vaElementInfo := NULL;
     mutGeomUDTFields.vaOrdinates   := NULL;
     Initialise();
  End New;

  Function GetGeometry
           return MDSYS.SDO_Geometry
  Is
    sProcID CONSTANT varchar2(256) := C_MODULE_NAME || '.GetGeometry';
  Begin
    return mdsys.sdo_geometry(mutGeomUDTFields.lFullGType,
                              mutGeomUDTFields.lSRID,
                              mutGeomUDTFields.Point,
                              mutGeomUDTFields.vaElementInfo,
                              mutGeomUDTFields.vaOrdinates);
  End GetGeometry;

  Procedure SetSdo_point( p_point in MDSYS.SDO_Point_Type )
  Is
  Begin
     mutGeomUDTFields.Point := p_point;
  End SetSdo_Point;

  Procedure SetSdo_Point( p_x in number,
                          p_y in integer,
                          p_z in integer)
  Is
    sProcID CONSTANT varchar2(256) := C_MODULE_NAME || '.SetSdo_Point';
  Begin
     SetSdo_Point( MDSYS.SDO_Point_Type( p_x, p_y, p_z ) );
  End SetSdo_Point;

  Procedure NewElementInfoArray( p_elem_info in &&defaultSchema..T_ElemInfo )
  Is
    sProcID CONSTANT varchar2(256) := C_MODULE_NAME || '.NewElementInfoArray';
    v_count number;
  Begin
    If mutGeomUDTFields.vaElementInfo IS NULL Then
      mutGeomUDTFields.vaElementInfo := mdsys.sdo_elem_info_array();
    End If;
    mutGeomUDTFields.vaElementInfo.extend(3);
    v_Count :=  mutGeomUDTFields.vaElementInfo.count;
    mutGeomUDTFields.vaElementInfo(v_count-2) := p_Elem_Info.offset;
    mutGeomUDTFields.vaElementInfo(v_count-1) := p_Elem_Info.etype;
    mutGeomUDTFields.vaElementInfo(v_count  ) := p_Elem_Info.Interpretation;
    InitElementInfoArray();
  END NewElementInfoArray;

  --******************************************************************************
  --** Routine:     IsNullGeometry
  --** Description: Returns True if the geometry object is NULL.
  --******************************************************************************
  Function IsNullGeometry
           return boolean
  Is
    v_isNullGeometry BOOLEAN;
  Begin
    If (mutGeomUDTFields.uGeomType = uGeomType_SinglePoint) Then
      v_IsNullGeometry := (mutGeomUDTFields.Point IS NULL);
    Else
      v_IsNullGeometry := (mutGeomUDTFields.vaElementInfo IS NULL) Or
                        (mutGeomUDTFields.vaOrdinates IS NULL);
    End If;
    RETURN (mutGeomUDTFields.mobjGeometry IS NULL
            AND
            v_IsNullGeometry);
  End IsNullGeometry;

  Function GetNumParts
           return integer
  Is
  Begin
    RETURN mutGeomUDTFields.lNumElements;
  End GetNumParts;

  Function GetNumCoordinates
           return integer
  Is
  Begin
    Return mutGeomUDTFields.lNumCoordinates;
  End GetNumCoordinates;

  -- =================================================================
  -- *******  SDO_ELEM_INFO Interators and Property Functions  *******
  -- *******  Properties                                       *******

  --Description: Get Element Information at nominated position in the array.
  --
  Function  GetElemInfo( p_Element in integer )
            Return &&defaultSchema..T_ElemInfo
  Is
    v_Element integer;
  Begin
    v_Element := p_Element - 1;
    Return &&defaultSchema..T_ElemInfo(
                      mutGeomUDTFields.vaElementInfo(v_Element * 3 + 1),
                      mutGeomUDTFields.vaElementInfo(v_Element * 3 + 2),
                      mutGeomUDTFields.vaElementInfo(v_Element * 3 + 3));
  End GetElemInfo;

  --Description: Get Element Information at current position in the array.
  Function  GetElemInfo
            Return &&defaultSchema..T_ElemInfo
  Is
    v_Element integer;
  Begin
    If mutGeomUDTFields.lCurrentElement = 0 Then
      Return NULL;
    Else
      v_Element := mutGeomUDTFields.lCurrentElement - 1;
      Return &&defaultSchema..T_ElemInfo(
                      mutGeomUDTFields.vaElementInfo(v_Element * 3 + 1),
                      mutGeomUDTFields.vaElementInfo(v_Element * 3 + 2),
                      mutGeomUDTFields.vaElementInfo(v_Element * 3 + 3));
    End If;
  End GetElemInfo;

  --Description: Get current Element at nominated position as an array.
  Function  GetElemInfoArray( p_Element in integer )
            Return MDSYS.SDO_Elem_Info_Array
  Is
    v_Element integer;
  Begin
    v_Element := p_Element - 1;
    Return MDSYS.SDO_Elem_Info_Array(
                      mutGeomUDTFields.vaElementInfo(v_Element * 3 + 1),
                      mutGeomUDTFields.vaElementInfo(v_Element * 3 + 2),
                      mutGeomUDTFields.vaElementInfo(v_Element * 3 + 3));
  End GetElemInfoArray;

  --Description: Get current Element at current position as an array.
  Function  GetElemInfoArray
            Return MDSYS.SDO_Elem_Info_Array
  Is
    v_Element integer;
  Begin
    v_Element := mutGeomUDTFields.lCurrentElement - 1;
    return MDSYS.SDO_Elem_Info_Array(
                      mutGeomUDTFields.vaElementInfo(v_Element * 3 + 1),
                      mutGeomUDTFields.vaElementInfo(v_Element * 3 + 2),
                      mutGeomUDTFields.vaElementInfo(v_Element * 3 + 3));
  End GetElemInfoArray;

  --******************************************************************************
  --** Routine:     GetStartOffset
  --** Description: Returns the starting ordinate array offset of the current element.
  --******************************************************************************
  Function GetStartOffset
           return integer
  Is
  Begin
    RETURN mutGeomUDTFields.uCurrentElement.lStartOrdinate;
  End GetStartOffset;

  --******************************************************************************
  --** Routine:     GetEndOffset
  --** Description: Returns the ending ordinate array offset of the current element.
  --******************************************************************************
  Function GetEndOffset
           return integer
  Is
  Begin
    RETURN mutGeomUDTFields.uCurrentElement.lEndOrdinate;
  End GetEndOffset;

  --******************************************************************************
  --** Routine:     GetElementType
  --** Description: Gets the ElementType of current element.
  --******************************************************************************
  Function GetElementType
           return integer
  Is
  Begin
    RETURN mutGeomUDTFields.uCurrentElement.lEType;
  End GetElementType;

  --******************************************************************************
  --** Routine:     GetElementGeomType
  --** Description: Returns the actual shape type of the current element.
  --**              This is different from the just returning the basic SDO_ETYPE
  --**              via ElementType() as is includes INTERPRETATION.
  --******************************************************************************
  Function GetElementGeomType
           return integer
  Is
  Begin
    RETURN mutGeomUDTFields.uCurrentElement.uGeomType;
  End;

  --******************************************************************************
  --** Routine:     GetInterpretation
  --** Description: Returns the interpretation field for current element.
  --******************************************************************************
  Function GetInterpretation
           return integer
  Is
  Begin
    RETURN mutGeomUDTFields.uCurrentElement.lInterpretation;
  End;

  --******************************************************************************
  --** Routine:     GetParentElementGeomType
  --** Description: Returns the actual shape type of the parent element in
  --**              cases where the shape is of type 4/5 ie COMPOUND.
  --******************************************************************************
  Function GetParentElementGeomType
           return integer
  Is
  BEGIN
    RETURN mutGeomUDTFields.uCurrentElement.uParentGeomType;
  End GetParentElementGeomType;

  Function GetSubElementCount
           return integer
  Is
  BEGIN
    RETURN mutGeomUDTFields.uCurrentElement.lLastSubElement - mutGeomUDTFields.uCurrentElement.lFirstSubElement ;
  End GetSubElementCount;

  -- Private method
  --
  Function ComputeElementGeomType(etype IN INTEGER, Interpretation IN INTEGER)
    Return INTEGER
  Is
    lElementGeomType INTEGER;
  Begin
    Case
      When etype = 0 Then
          -- 0  0   Unsupported element type.
          lElementGeomType := uElemType_Unknown;
      When etype = 1 Then
          -- 1         1       Point type.
          Case
            When Interpretation = 0 Then
              lElementGeomType := uElemType_OrientationPoint;
            When Interpretation = 1 Then
              lElementGeomType := uElemType_Point;
            Else
              -- 1         n > 1   Point cluster with n points.
              lElementGeomType := uElemType_MultiPoint;
          End Case;
      When etype = 2 Then
          Case
            When Interpretation = 1 Then
              -- 2  1  Line string whose vertices are connected by straight line segments.
              lElementGeomType := uElemType_LineString;
              -- ie CVar(etype * interpretation)
            When Interpretation = 2 Then
              -- 2  2  Line string made up of a connected sequence of circular arcs.
              --       Each circular arc is described using three coordinates:
              --           a. The arc's starting point,
              --           b. Any point on the arc, and
              --           c. The arc's end point.
              --       The coordinates for a point designating the end of one arc and the start of
              --       the next arc are not repeated. For example, five coordinates are used to
              --       describe a line string made up of two connected circular arcs.
              --       Points 1, 2, and 3 define the first arc, and points 3, 4, and 5 define the second arc,
              --       where point 3 is only stored once.
              lElementGeomType := uElemType_CircularArc;
            Else
              lElementGeomType := uElemType_Unknown;
          End Case;
      When etype in (3,1003,2003) Then
          Case
            When Interpretation = 1 Then
              -- 3  1   Simple polygon whose vertices are connected by straight line segments.
              --        Note that you must specify a point for each vertex, and the last point
              --        specified must be identical to the first (to close the polygon).
              --        For example, for a 4-sided polygon, specify 5 points, with point 5
              --        the same as point 1.
            lElementGeomType := etype * Interpretation;
            When Interpretation = 2 Then
              -- 3  2   Polygon made up of a connected sequence of circular arcs that closes
              --        on itself. The end point of the last arc is the same as the start point
              --        of the first arc.
              --        Each circular arc is described using three coordinates:
              --             the arc's start point,
              --             any point on the arc,
              --             and the arc's end point.
              --        The coordinates for a point designating the end of one arc and
              --        the start of the next arc are not repeated. For example, five
              --        coordinates are used to describe a polygon made up of two
              --        connected circular arcs. Points 1, 2, and 3 define the first
              --        arc, and points 3, 4, and 5 define the second arc.
              --        The coordinates for points 1 and 5 must be the same, and
              --        point 3 is not repeated.
              lElementGeomType := etype * Interpretation;
            When Interpretation = 3 Then
              -- 3  3   Rectangle type.
              --        A bounding rectangle such that only two points,
              --            the lower-left and the upper-right,
              --        are required to describe it.
              lElementGeomType := etype * Interpretation;
            When Interpretation = 4 Then
              -- 3  4   Circle type.
              --        Described by three points, all on the circumference of the circle.
              lElementGeomType := etype * Interpretation;
            Else
              lElementGeomType := uElemType_Unknown;
          End Case;
        When etype = 4 Then
            -- 4  n > 1  Line string with some vertices connected by straight line segments
            --           and some by circular arcs.
            --           The value, n, in the Interpretation column specifies the number of
            --           contiguous subelements that make up the line string.
            --           The next n triplets in the SDO_ELEM_INFO array describe each of these subelements.
            --           The subelements can only be of SDO_ETYPE 2.
            --           The last point of a subelement is the first point of the next subelement, and must not be repeated.
            lElementGeomType := uElemType_CompoundLineString;
        When etype = 5 Then
            -- 5  n > 1  Compound polygon with some vertices connected by straight line segments and
            --           some by circular arcs. The value, n, in the Interpretation column specifies the number of
            --           contiguous subelements that make up the polygon.
            --           The next n triplets in the SDO_ELEM_INFO array describe each of these subelements.
            --           The subelements can only be of SDO_ETYPE 2.
            --           The end point of a subelement is the start point of the next subelement,
            --           and it must not be repeated.
            --           The start and end points of the polygon must be the same.
            lElementGeomType := uElemType_CompoundPolygon;
        When etype = 1005 Then
            lElementGeomType := uElemType_CompoundPolyExt;
        When etype = 2005 Then
            lElementGeomType := uElemType_CompoundPolyInt;
        Else
            lElementGeomType := uElemType_Unknown;
     End Case;
     RETURN lElementGeomType;
  End ComputeElementGeomType;

  Function  isCompoundElement
            Return Boolean
  Is
  Begin
    Return ( mutGeomUDTFields.uCurrentElement.uGeomType = uElemType_CompoundLineString Or
             mutGeomUDTFields.uCurrentElement.uGeomType = uElemType_CompoundPolygon    Or
             mutGeomUDTFields.uCurrentElement.uGeomType = uElemType_CompoundPolyExt    Or
             mutGeomUDTFields.uCurrentElement.uGeomType = uElemType_CompoundPolyInt );
  End isCompoundElement;

  Function  isCompoundElementChild
            Return Boolean
  Is
  Begin
    Return ( mutGeomUDTFields.uCurrentElement.uParentGeomType <> uElemType_Unknown And
             mutGeomUDTFields.uCurrentElement.lCoordCount <> 0 );
  End isCompoundElementChild;

  Function  isFirstCompoundElementChild
            Return Boolean
  Is
  Begin
    Return ( mutGeomUDTFields.uCurrentElement.uParentGeomType <> uElemType_Unknown And
             mutGeomUDTFields.uCurrentElement.lFirstSubElement = mutGeomUDTFields.lCurrentElement );
  End isFirstCompoundElementChild;

  Function  isLastCompoundElementChild
            Return Boolean
  Is
  Begin
    Return ( mutGeomUDTFields.uCurrentElement.uParentGeomType <> uElemType_Unknown And
             mutGeomUDTFields.uCurrentElement.lLastSubElement = mutGeomUDTFields.lCurrentElement );
  End isLastCompoundElementChild;

  Function isLastElement
           Return Boolean
  Is
  Begin
    RETURN (mutGeomUDTFields.lCurrentElement = mutGeomUDTFields.lNumElements);
  End isLastElement;

  --******************************************************************************
  --** Routine:     ComputeEndOffset
  --** Description: Returns the ending offset of current element. Is adjusted
  --**              if parent element type is compound (ie type 4 or 5).
  --**              Called only by SetCurrentElement
  --**              Not called by any public method
  --******************************************************************************
  Function ComputeEndOffset
           return integer
  Is
    lEndOrdinate PLS_INTEGER;
    lArrayIndex  PLS_INTEGER;
  Begin
    If mutGeomUDTFields.lCurrentElement = mutGeomUDTFields.lNumElements Then
      lEndOrdinate := mutGeomUDTFields.lNumOrdinates;
    Else
      -- Compute next element array index from current element
      lArrayIndex := (mutGeomUDTFields.lCurrentElement * 3) + 1;
      -- The last ordinate of a element IS the ordinate BEFORE the first ordinate
      -- of the next element.
      lEndOrdinate := mutGeomUDTFields.vaElementInfo(lArrayIndex) - 1;
      If (mutGeomUDTFields.uCurrentElement.uParentGeomType <> uElemType_Unknown) Then
        If (mutGeomUDTFields.lCurrentElement > mutGeomUDTFields.uCurrentElement.lLastSubElement) Then
          mutGeomUDTFields.uCurrentElement.uParentGeomType  := uElemType_Unknown;
          mutGeomUDTFields.uCurrentElement.lFirstSubElement := 0;
          mutGeomUDTFields.uCurrentElement.lLastSubElement  := -1;
        Else
          /* dbms_output.put_line('The last point of a subelement in a compound element IS the first point of the next subelement. The point is not repeated -- Unless Next is itself a new compound Element'); */
          lEndOrdinate := lEndOrdinate + case when ( isLastCompoundElementChild()
                                                     And Not isLastElement() )
                                              then 0
                                              else mutGeomUDTFields.lDimension
                                          end;
        End If;
      End If;
    End If;
/* DEBUG
dbms_output.put_line('ComputeEndOffset: (CurrentElem,NumElems,EndOffset) ' ||
mutGeomUDTFields.lCurrentElement || ',' ||
mutGeomUDTFields.lNumElements || ',' ||
lEndOrdinate || ')');
*/
    RETURN lEndOrdinate;
  End ComputeEndOffset;

  --******************************************************************************
  --** Routine:     SetCurrentElement
  --** Description: Sets internally typed variable's values to reflect a particular
  --**              Element.
  --**              Shared by FirstElement, NextElement
  --**              Not called by any public method
  --******************************************************************************
  Procedure SetCurrentElement
  Is
    lIndex      INTEGER;
  Begin
    lIndex := ((mutGeomUDTFields.lCurrentElement - 1) * 3) + 1;
    mutGeomUDTFields.uCurrentElement.lStartOrdinate  := mutGeomUDTFields.vaElementInfo(lIndex);
    lIndex := lIndex + 1;
    mutGeomUDTFields.uCurrentElement.lEType          := mutGeomUDTFields.vaElementInfo(lIndex);
    lIndex := lIndex + 1;
    mutGeomUDTFields.uCurrentElement.lInterpretation := mutGeomUDTFields.vaElementInfo(lIndex);
    mutGeomUDTFields.uCurrentElement.lCoordIndex     := 1;
    mutGeomUDTFields.uCurrentElement.uGeomType       := ComputeElementGeomType(mutGeomUDTFields.uCurrentElement.lEType,
	                                                                       mutGeomUDTFields.uCurrentElement.lInterpretation);
    /* DEBUG
    dbms_output.put_line('GeomType = ' ||
                         mutGeomUDTFields.uCurrentElement.uGeomType ||
                         ' isCompoundElement = ' ||
                         case when isCompoundElement() then 'TRUE' else 'FALSE' end );
    */
    If isCompoundElement Then
      mutGeomUDTFields.uCurrentElement.uParentGeomType  := mutGeomUDTFields.uCurrentElement.uGeomType;
      mutGeomUDTFields.uCurrentElement.lFirstSubElement := mutGeomUDTFields.lCurrentElement + 1;
      mutGeomUDTFields.uCurrentElement.lLastSubElement  := mutGeomUDTFields.lCurrentElement +
                                                           mutGeomUDTFields.uCurrentElement.lInterpretation;
      mutGeomUDTFields.uCurrentElement.lOrdinateCount   := 0;
      mutGeomUDTFields.uCurrentElement.lCoordCount      := 0;
   Else
      mutGeomUDTFields.uCurrentElement.lEndOrdinate     := ComputeEndOffset();
      mutGeomUDTFields.uCurrentElement.lOrdinateCount   := (mutGeomUDTFields.uCurrentElement.lEndOrdinate -
                                                            mutGeomUDTFields.uCurrentElement.lStartOrdinate) + 1;
      mutGeomUDTFields.uCurrentElement.lCoordCount      := mutGeomUDTFields.uCurrentElement.lOrdinateCount /
                                                           mutGeomUDTFields.lDimension;
   End If;
  End SetCurrentElement;

  --******************************************************************************
  -- ----- Iterators
  --******************************************************************************
  --
  -- ----------------------------------------------------------------------------------------
  -- @function   : FirstElement
  -- @precis     : Sets iterator to first element in the ELEM_INFO_ARRAY
  -- @version    : 1.0
  -- @return     : Boolean
  --               - True if there is a first element.
  --               - False if is no first element.
  -- @history    : Simon Greener - Jul 2001 - Original coding.
  -- @copyright  : Free for public use
  --

  Function FirstElement
           return boolean
  Is
  Begin
    mutGeomUDTFields.lCurrentElement := 1; -- (ie first (ETYPE,INTER,OFFSET) triplet
    If ( mutGeomUDTFields.lCurrentElement <= mutGeomUDTFields.lNumElements ) Then
      mutGeomUDTFields.uCurrentElement.lFirstSubElement := 0;
      mutGeomUDTFields.uCurrentElement.lLastSubElement  := -1;
      mutGeomUDTFields.uCurrentElement.uParentGeomType := uElemType_Unknown;
      SetCurrentElement();
    End If;
    RETURN (mutGeomUDTFields.lCurrentElement <= mutGeomUDTFields.lNumElements);
  End FirstElement;

  -- ----------------------------------------------------------------------------------------
  -- @function   : NextElement
  -- @precis     : Sets iterator to next element in the ELEM_INFO_ARRAY
  -- @version    : 1.0
  -- @return     : Boolean
  --               - True if there there is another element and it has been successfully set.
  --               - False if there are no more elements for this geometry.
  -- @history    : Simon Greener - Jul 2001 - Original coding.
  -- @copyright  : Free for public use
  --
  Function NextElement
           return boolean
  Is
    lNextIndex   INTEGER;
    bNextElement BOOLEAN;
  Begin
    lNextIndex := mutGeomUDTFields.lCurrentElement + 1;
    bNextElement := False;
    If (lNextIndex <= mutGeomUDTFields.lNumElements) Then
      mutGeomUDTFields.lCurrentElement := lNextIndex;
      SetCurrentElement();
      bNextElement := True;
    End If;
    RETURN bNextElement;
  End NextElement;

  -- ----------------------------------------------------------------------------------------
  -- @function   : FirstCoordinate
  -- @precis     : Sets iterator to first coordinate in the current element.
  -- @version    : 1.0
  -- @return     : Boolean
  --               - True if there is a first coordinate for the element.
  --               - False if there are no coordinates for this element.
  -- @history    : Simon Greener - Jul 2001 - Original coding.
  -- @copyright  : Free for public use
  --
  Function FirstCoordinate
           return boolean
  Is
  Begin
    -- Coordinate within current element
    mutGeomUDTFields.uCurrentElement.lCoordIndex := 1;
    -- Coordinate position within whole object
    mutGeomUDTFields.lCurrentCoordinate := ( ( mutGeomUDTFields.uCurrentElement.lStartOrdinate - 1 ) / mutGeomUDTFields.lDimension ) + 1;
    Return ( mutGeomUDTFields.uCurrentElement.lCoordIndex <= mutGeomUDTFields.uCurrentElement.lCoordCount );
  End FirstCoordinate;

  -- ----------------------------------------------------------------------------------------
  -- @function   : NextCoordinate
  -- @precis     : Gets next coordinate for an element.
  -- @version    : 1.0
  -- @return     : Boolean
  --               - True if there there is another coordinate for the element.
  --               - False if there are no more coordinates for this element.
  -- @history    : Simon Greener - Jul 2001 - Original coding.
  -- @copyright  : Free for public use
  --
  Function NextCoordinate
           return boolean
  Is
  Begin
    mutGeomUDTFields.uCurrentElement.lCoordIndex := mutGeomUDTFields.uCurrentElement.lCoordIndex + 1;
    mutGeomUDTFields.lCurrentCoordinate          := mutGeomUDTFields.lCurrentCoordinate + 1;
    RETURN (mutGeomUDTFields.uCurrentElement.lCoordIndex <= mutGeomUDTFields.uCurrentElement.lCoordCount);
  End NextCoordinate;

  -- =================================================================
  -- *******  SDO_ORDINATES Interators and Property Functions  *******
  -- *******  Inspectors                                       *******
  -- =================================================================

  --******************************************************************************
  --** Routine:     GetSdo_point
  --** Description: Gets the SDO_POINT field IFF set.
  --**              Routine checks for NULL sdo_point field and
  --**              NULL x, y and z fields.
  --******************************************************************************
  Function GetSdo_point
    RETURN MDSYS.SDO_POINT_TYPE
  Is
  BEGIN
    RETURN mutGeomUDTFields.Point;
  End GetSdo_point;

  Function GetElementCoordinateCount
           return integer
  Is
  BEGIN
    RETURN (mutGeomUDTFields.uCurrentElement.lOrdinateCount) / mutGeomUDTFields.lDimension;
  End GetElementCoordinateCount;

  Function GetNumberOfArcsInElement
           return integer
  Is
    v_number Integer := -1;
  Begin
    If GetElementGeomType() in (uElemType_CircularArc,
                                uElemType_PolyCircularArc,
                                uElemType_PolyCircularArcExt,
                                uElemType_PolyCircularArcInt) Then
      v_number := 1 + ( GetElementCoordinateCount() - 3 ) / 2;
    End If;
    Return v_number;
  End GetNumberOfArcsInElement;

  -- ----------------------------------------------------------------------------------------
  -- @function   : GetCoordinate
  -- @precis     : Gets coordinate at a specific index.
  -- @version    : 1.0
  -- @history    : Simon Greener - Jul 2001 - Original coding.
  -- @copyright  : Free for public use
  --
  --
  Function  GetCoordinate( p_lCoordinate in integer )
            Return &&defaultSchema..ST_Point
  Is
    v_Coord4D  &&defaultSchema..ST_Point;
    v_Ordinate integer;
  Begin
    v_Coord4D  := New &&defaultSchema..ST_Point(&&defaultSchema..CONSTANTS.c_MaxVal,&&defaultSchema..CONSTANTS.c_MaxVal);
    v_Ordinate := ( p_lCoordinate - 1 ) * mutGeomUDTFields.lDimension + 1;
    v_Coord4D.X := mutGeomUDTFields.vaOrdinates(v_Ordinate);
    v_Coord4D.Y := mutGeomUDTFields.vaOrdinates(v_Ordinate + 1);
    If ( mutGeomUDTFields.lDimension IN ( uDimensions_Three, uDimensions_Four ) ) Then
      v_Coord4D.Z := mutGeomUDTFields.vaOrdinates(v_Ordinate + 2);
      if ( mutGeomUDTFields.lDimension = uDimensions_Four ) Then
         v_Coord4D.M := mutGeomUDTFields.vaOrdinates(v_Ordinate + 3);
      end If;
    End If;
    Return v_Coord4D;
  End GetCoordinate;

  -- ----------------------------------------------------------------------------------------
  -- @function   : GetCoordinate
  -- @precis     : Gets coordinate at current position as defined by mutGeomUDTFields.lCurrentCoordinate global
  -- @version    : 1.0
  -- @history    : Simon Greener - Jul 2001 - Original coding.
  -- @copyright  : Free for public use
  --
  --
  Function  GetCoordinate
            Return &&defaultSchema..ST_Point
  Is
    v_Coord4D  &&defaultSchema..ST_Point;
    v_Ordinate integer;
  Begin
    v_Coord4D  := New &&defaultSchema..ST_Point(&&defaultSchema..CONSTANTS.c_MaxVal,&&defaultSchema..CONSTANTS.c_MaxVal);
    v_Ordinate := ( mutGeomUDTFields.lCurrentCoordinate - 1 ) * mutGeomUDTFields.lDimension + 1 ;
    v_Coord4D.X := mutGeomUDTFields.vaOrdinates( v_Ordinate );
    v_Coord4D.Y := mutGeomUDTFields.vaOrdinates( v_Ordinate + 1 );
    If ( mutGeomUDTFields.lDimension IN ( uDimensions_Three, uDimensions_Four ) ) Then
      v_Coord4D.Z := mutGeomUDTFields.vaOrdinates( v_Ordinate + 2 );
      If ( mutGeomUDTFields.lDimension = uDimensions_Four ) Then
         v_Coord4D.M := mutGeomUDTFields.vaOrdinates( v_Ordinate + 3 );
      End IF;
    End IF;
    Return v_Coord4D;
  End GetCoordinate;

  -- ----------------------------------------------------------------------------------------
  -- @function   : AddCoordinate
  -- @precis     : Adds a coordinate to the end of the current ordinate array.
  -- @version    : 1.0
  -- @history    : Simon Greener - Jul 2001 - Original coding.
  -- @copyright  : Free for public use
  --
  Procedure AddCoordinate( p_x_coord    in number,
                           p_y_coord    in number,
                           p_z_coord    in number,
                           p_m_coord    in number )
  Is
    v_ordinate_count  number;
    NODIMENSION       EXCEPTION;
  Begin
    If mutGeomUDTFields.vaOrdinates is NULL Then
      mutGeomUDTFields.vaOrdinates := MDSYS.SDO_Ordinate_Array();
    End If;
    If mutGeomUDTFields.lDimension is NULL or
       mutGeomUDTFields.lDimension = uDimensions_None Then
      RAISE NODIMENSION;
    End If;
    mutGeomUDTFields.vaOrdinates.extend(mutGeomUDTFields.lDimension);
   -- Update global counter
    mutGeomUDTFields.lNumOrdinates    := mutGeomUDTFields.vaOrdinates.count;
    v_ordinate_count := mutGeomUDTFields.lNumOrdinates - (mutGeomUDTFields.lDimension + 1);
    mutGeomUDTFields.vaOrdinates( v_ordinate_count )     := p_x_coord;
    mutGeomUDTFields.vaOrdinates( v_ordinate_count + 2 ) := p_y_coord;
    If ( mutGeomUDTFields.lDimension IN (uDimensions_Three,uDimensions_Four) ) Then
      mutGeomUDTFields.vaOrdinates( v_ordinate_count + 3 ) := p_z_coord;
      If ( mutGeomUDTFields.lDimension = uDimensions_Four ) Then
        mutGeomUDTFields.vaOrdinates( v_ordinate_count + 3 ) := p_m_coord;
      End If;
    End If;
    Exception
      When NODIMENSION Then
         raise_application_error(&&defaultSchema..CONSTANTS.c_i_nodimension,
                                 &&defaultSchema..CONSTANTS.c_s_nodimension,TRUE);
         RETURN;
  END ADDCoordinate;

  Procedure AddCoordinate( p_coord in &&defaultSchema..ST_Point )
  Is
  BegiN
    AddCoordinate( p_coord.x, p_coord.y, p_coord.z, p_coord.m);
  End AddCoordinate;

  -- ----------------------------------------------------------------------------------------
  -- @function   : SetCoordinate
  -- @precis     : Replaces coordinate at a specific index into the sdo_ordinates array.
  -- @version    : 1.0
  -- @history    : Simon Greener - Jul 2001 - Original coding.
  -- @copyright  : Free for public use
  --
  --
  Procedure SetCoordinate( p_coord_index in integer,
                           p_Coord4D     in &&defaultSchema..ST_Point )
  Is
    v_Ordinate integer;
  Begin
    v_Ordinate := ( p_coord_index - 1 ) * mutGeomUDTFields.lDimension + 1;
    mutGeomUDTFields.vaOrdinates( v_Ordinate     ) := p_Coord4D.X;
    mutGeomUDTFields.vaOrdinates( v_Ordinate + 1 ) := p_Coord4D.Y;
    If  ( mutGeomUDTFields.lDimension IN ( uDimensions_Three , uDimensions_Four ) ) Then
      mutGeomUDTFields.vaOrdinates( v_Ordinate + 1 ) := p_Coord4D.Z;
      If ( mutGeomUDTFields.lDimension = uDimensions_Four ) Then
        mutGeomUDTFields.vaOrdinates( v_Ordinate + 1 ) := p_Coord4D.M;
      End If;
    End If;
  End SetCoordinate;

  -- ----------------------------------------------------------------------------------------
  -- @function   : SetCoordinate
  -- @precis     : Replaces current coordinate with passed in value
  -- @version    : 1.0
  -- @history    : Simon Greener - Jul 2001 - Original coding.
  -- @copyright  : Free for public use
  --
  Procedure SetCoordinate( p_Coord4D in &&defaultSchema..ST_Point )
  Is
    v_Ordinate   integer;
  Begin
    v_Ordinate := ( mutGeomUDTFields.uCurrentElement.lCoordIndex - 1 ) * mutGeomUDTFields.lDimension + 1;
    mutGeomUDTFields.vaOrdinates( v_Ordinate     ) := p_Coord4D.X;
    mutGeomUDTFields.vaOrdinates( v_Ordinate + 1 ) := p_Coord4D.Y;
    If (  mutGeomUDTFields.lDimension IN ( uDimensions_Three, uDimensions_Four ) ) Then
      mutGeomUDTFields.vaOrdinates( v_Ordinate + 1 ) := p_Coord4D.Z;
      If ( mutGeomUDTFields.lDimension = uDimensions_Four ) Then
         mutGeomUDTFields.vaOrdinates( v_Ordinate + 1 ) := p_Coord4D.M;
      End If;
    End If;
  End SetCoordinate;

  -- ----------------------------------------------------------------------------------------
  -- @function   : SetCoordinate
  -- @precis     : Replace current coordinate - alternate binding
  -- @version    : 1.0
  -- @history    : Simon Greener - Jul 2001 - Original coding.
  -- @copyright  : Free for public use
  --
  Procedure SetCoordinate( p_x in number,
                           p_y in number,
                           p_z in number,
                           p_m in number)
  Is
    v_Coord4D  &&defaultSchema..ST_Point;
  Begin
    v_Coord4D := New &&defaultSchema..ST_Point(&&defaultSchema..CONSTANTS.c_MaxVal,&&defaultSchema..CONSTANTS.c_MaxVal);
    v_Coord4D.x := p_x;
    v_Coord4D.y := p_y;
    v_Coord4D.z := p_z;
    v_Coord4D.m := p_m;
    SetCoordinate(v_Coord4D);
  End SetCoordinate;

  Function  GetElementOrdinates( p_lBound in integer,
                                 p_uBound in integer )
            Return MDSYS.SDO_Ordinate_Array
  Is
    v_Ordinates  MDSYS.SDO_Ordinate_Array := MDSYS.SDO_Ordinate_Array();
    v_offset     integer;
  Begin
    v_offset := p_LBound - 1;
    v_Ordinates.EXTEND( p_UBound - p_LBound + 1 );
    for v_i in p_LBound..p_UBound loop
      v_Ordinates(v_i - v_offset) := mutGeomUDTFields.vaOrdinates(v_i);
    end loop;
    return v_Ordinates;
  End GetElementOrdinates;

  -- =========================================================================================
  -- Special Element Conversion Code
  -- =========================================================================================
  --Created:     17/12/2004
  --Author:      Simon Greener
  --Description: Aligns Oracle Spatial Ordinates with appropriate arrays of dimensioned coordinates.
  --             includes conversion of "non traditional GIS types" such as circular arcs to vector equivalent
  --Modified:     4/4/2006 SGG             Modified to use actual Varrays directly.
  --Modified:    30/1/2008 SGG             Modified to become a pipelined function and expose p_arc2chord more directly
  --
  Function ConvertSpecialElements( p_arc2chord in number := 0.1 )
           return &&defaultSchema..ST_PointSet Pipelined
  Is
    sProcID          CONSTANT VARCHAR2(256) := C_MODULE_NAME || '.ConvertSpecialElements';
    -- Some variables for conversion use for Circles and CircularArcs
    --
    iOptimalCircleSegments INTEGER;
    dCentreX         NUMBER;
    dCentreY         NUMBER;
    dRadius          NUMBER;
    Type dCircleCoord_T IS VARRAY(3) OF &&defaultSchema..ST_Point;
    dCircleCoord     dCircleCoord_T := dCircleCoord_T(&&defaultSchema..ST_Point(&&defaultSchema..CONSTANTS.c_MaxVal,&&defaultSchema..CONSTANTS.c_MaxVal),
                                                      &&defaultSchema..ST_Point(&&defaultSchema..CONSTANTS.c_MaxVal,&&defaultSchema..CONSTANTS.c_MaxVal),
                                                      &&defaultSchema..ST_Point(&&defaultSchema..CONSTANTS.c_MaxVal,&&defaultSchema..CONSTANTS.c_MaxVal));
    dLLCoord         &&defaultSchema..ST_Point := &&defaultSchema..ST_Point(&&defaultSchema..CONSTANTS.c_MaxVal,&&defaultSchema..CONSTANTS.c_MaxVal);
    dURCoord         &&defaultSchema..ST_Point := &&defaultSchema..ST_Point(&&defaultSchema..CONSTANTS.c_MaxVal,&&defaultSchema..CONSTANTS.c_MaxVal);
    dAngle           NUMBER;
    dAngle2          NUMBER;
    v_geometry       mdsys.sdo_geometry;
    v_coordToProcess Boolean;
    Cursor c_points(p_geometry in mdsys.sdo_geometry) Is
    Select &&defaultSchema..ST_Point(a.x,a.y,a.z,a.w) as point
      From Table(mdsys.sdo_util.GetVertices(p_geometry)) a;
  BEGIN
    -- Execute any required conversions
    -- Get First Coordinate in current compound object
    v_coordToProcess := &&defaultSchema..GF.FirstCoordinate();
    If Not v_coordToProcess Then
        raise_application_error(&&defaultSchema..constants.c_i_coordinate_read,
                                &&defaultSchema..constants.c_s_coordinate_read,False);
    End If;
    CASE
    When GetElementGeomType in (uElemType_Rectangle, uElemType_RectangleExterior, uElemType_RectangleInterior) Then
      -- Make polygon from LL and UR coordinates in vaOrdinates
      -- Exterior shell has anti-clockwise rotation
      dLLCoord := &&defaultSchema..GF.GetCoordinate();
      If Not &&defaultSchema..GF.NextCoordinate() Then
        raise_application_error(&&defaultSchema..constants.c_i_coordinate_read,
                                &&defaultSchema..constants.c_s_coordinate_read,False);
      End If;
      dURCoord := &&defaultSchema..GF.GetCoordinate();
      Case
      When mutGeomUDTFields.lDimension = uDimensions_Two Then
        -- Save vaOrdinates coords...
        PIPE ROW(&&defaultSchema..ST_Point(dLLCoord.X,dLLCoord.Y));
        PIPE ROW(&&defaultSchema..ST_Point(dURCoord.X,dLLCoord.Y));
        PIPE ROW(&&defaultSchema..ST_Point(dURCoord.X,dURCoord.Y));
        PIPE ROW(&&defaultSchema..ST_Point(dLLCoord.X,dURCoord.Y));
        PIPE ROW(&&defaultSchema..ST_Point(dLLCoord.X,dLLCoord.Y));
      When mutGeomUDTFields.lDimension = uDimensions_Three Then
        PIPE ROW(&&defaultSchema..ST_Point(dLLCoord.X,dLLCoord.Y,dLLCoord.Z));
        PIPE ROW(&&defaultSchema..ST_Point(dURCoord.X,dLLCoord.Y,dLLCoord.Z)); -- This is a nonsense
        PIPE ROW(&&defaultSchema..ST_Point(dURCoord.X,dURCoord.Y,dURCoord.Z));
        PIPE ROW(&&defaultSchema..ST_Point(dLLCoord.X,dURCoord.Y,dURCoord.Z)); -- This is a nonsense
        PIPE ROW(&&defaultSchema..ST_Point(dLLCoord.X,dLLCoord.Y,dLLCoord.Z));
      When mutGeomUDTFields.lDimension = uDimensions_Four Then
        PIPE ROW(&&defaultSchema..ST_Point(dLLCoord.X,dLLCoord.Y,dLLCoord.Z,dLLCoord.M));
        PIPE ROW(&&defaultSchema..ST_Point(dURCoord.X,dLLCoord.Y,dLLCoord.Z,dLLCoord.M)); -- This is nonsense
        PIPE ROW(&&defaultSchema..ST_Point(dURCoord.X,dURCoord.Y,dURCoord.Z,dURCoord.M));
        PIPE ROW(&&defaultSchema..ST_Point(dLLCoord.X,dURCoord.Y,dURCoord.Z,dURCoord.M)); -- This is nonsense
        PIPE ROW(&&defaultSchema..ST_Point(dLLCoord.X,dLLCoord.Y,dLLCoord.Z,dLLCoord.M));
      Else
        NULL;
      End CASE;
    When GetElementGeomType in (uElemType_CircularArc, uElemType_PolyCircularArc, uElemType_PolyCircularArcExt, uElemType_PolyCircularArcInt) Then
      For i In 1..GetNumberOfArcsInElement() Loop
        -- Convert to ordinary polyline string
        --
        -- Save three points
        --
        dCircleCoord(1) := &&defaultSchema..GF.GetCoordinate();
        If Not &&defaultSchema..GF.NextCoordinate() Then
          raise_application_error(&&defaultSchema..constants.c_i_coordinate_read,
                                  &&defaultSchema..constants.c_s_coordinate_read,False);
        End If;
        dCircleCoord(2) := &&defaultSchema..GF.GetCoordinate();
        If Not &&defaultSchema..GF.NextCoordinate() Then
          raise_application_error(&&defaultSchema..constants.c_i_coordinate_read,
                                  &&defaultSchema..constants.c_s_coordinate_read,False);
        End If;
        dCircleCoord(3) := &&defaultSchema..GF.GetCoordinate();
/* DEBUG
dbms_output.put_line('Arc is (' || to_char(dCircleCoord(1).x,'9999999.999') || ',' || to_char(dCircleCoord(1).y,'9999999.999') || ') (' ||
                                   to_char(dCircleCoord(2).x,'9999999.999') || ',' || to_char(dCircleCoord(2).y,'9999999.999') || ') (' ||
                                   to_char(dCircleCoord(3).x,'9999999.999') || ',' || to_char(dCircleCoord(3).y,'9999999.999') || ')');
*/
        v_geometry := &&defaultSchema..COGO.CircularArc2Line(
                         dCircleCoord(1),
                         dCircleCoord(2),
                         dCircleCoord(3),
                         p_Arc2Chord );
        If v_geometry is null Then
           raise_application_error(&&defaultSchema..CONSTANTS.c_i_CircArc2Linestring,
                                   &&defaultSchema..CONSTANTS.c_s_CircArc2Linestring,False);
           RETURN;
        Else
           -- write to pipe
           FOR rec IN c_Points(v_geometry) LOOP
              If Not ( i > 1 and c_Points%ROWCOUNT = 1 ) Then
                PIPE ROW(rec.point);
              End If;
           END LOOP;
        End If;
      End Loop;
    When GetElementGeomType in (uElemType_Circle, uElemType_CircleExterior, uElemType_CircleInterior) Then

      -- Get Coordinates of circle
      dCircleCoord(1) := &&defaultSchema..GF.GetCoordinate();
      If Not &&defaultSchema..GF.NextCoordinate() Then
        raise_application_error(&&defaultSchema..constants.c_i_coordinate_read,
                                &&defaultSchema..constants.c_s_coordinate_read,False);
      End If;
      dCircleCoord(2) := &&defaultSchema..GF.GetCoordinate();
      If Not &&defaultSchema..GF.NextCoordinate() Then
        raise_application_error(&&defaultSchema..constants.c_i_coordinate_read,
                                &&defaultSchema..constants.c_s_coordinate_read,False);
      End If;
      dCircleCoord(3) := &&defaultSchema..GF.GetCoordinate();
      If &&defaultSchema..COGO.FindCircle(dCircleCoord(1).X, dCircleCoord(1).Y,
                                          dCircleCoord(2).X, dCircleCoord(2).Y,
                                          dCircleCoord(3).X, dCircleCoord(3).Y,
                                          dCentreX, dCentreY, dRadius) Then
          iOptimalCircleSegments := &&defaultSchema..COGO.OptimalCircleSegments(dRadius, p_Arc2Chord);
          -- Convert to polygon shape
          --
          If ( GetElementGeomType = uElemType_CircleInterior ) Then
              -- Ensure vertex orientation will be correct
              iOptimalCircleSegments := 0 - iOptimalCircleSegments;
          End If;
          -- If the Oracle Spatial database is 9.2 or above, the MDSYS.SDO_GEOM.ARC_DENSIFY()
          -- Function should be used in a view...
          -- Note 1: Oracle Spatial does not support CIRCULAR ARCS and CIRCLES in GEODETIC
          -- coordinate space (ie LAT/LONG) in 9.x and above
          --
          v_geometry := &&defaultSchema..COGO.Circle2Polygon(dCentreX, dCentreY, dRadius, iOptimalCircleSegments);
          If v_geometry is null then
            raise_application_error(&&defaultSchema..CONSTANTS.c_i_Circle2Polygon,
                                    &&defaultSchema..CONSTANTS.c_s_Circle2Polygon,False);
            RETURN;
	  Else
            -- write to pipe
            FOR rec IN c_Points(v_geometry) LOOP
               PIPE ROW(rec.point);
            END LOOP;
          End If;
      Else
        raise_application_error(&&defaultSchema..CONSTANTS.c_i_CircleProperties,
                                &&defaultSchema..CONSTANTS.c_s_CircleProperties,False);
        RETURN;
      End If;
    When GetElementGeomType = uElemType_CompoundLineString Then
      -- This function should never be called for this EType as the coordinate data is
      -- really only in the sub-elements

      -- Convert to ordinary polyline
      -- If the Oracle Spatial database is 9.2 or above, the MDSYS.SDO_GEOM.ARC_DENSIFY()
      -- function should be used to convert circular arc parts to linestrings.
      -- Note 1: Oracle Spatial does not support CIRCULAR ARCS and CIRCLES in GEODETIC coordinate space (ie LAT/LONG) in 9.x and above
      -- Note 2: Need an arc_tolerance (or arc-to-chord) separation value (see Let Arc2Chord property)
      --
      NULL;
    When GetElementGeomType in (uElemType_CompoundPolygon, uElemType_CompoundPolyExt, uElemType_CompoundPolyInt) Then
      -- This function should never be called for this EType as the coordinate data is
      -- really only in the sub-elements

      -- Convert to multi-polygon
      -- If the Oracle Spatial database is 9.2 or above, the MDSYS.SDO_GEOM.ARC_DENSIFY()
      -- function should be used to convert circular arc parts to linestrings.
      -- Note 1: Oracle Spatial does not support CIRCULAR ARCS and CIRCLES in GEODETIC coordinate space (ie LAT/LONG) in 9.x and above
      -- Note 2: Need an arc_tolerance (or arc-to-chord) separation value (see Let Arc2Chord property)
      --
      NULL;
    Else
      -- Might be greater than the dPoints buffer (see SetSaElements below)
      -- but we don--t fill it any more for straight point and vertex-to-vertex described linear/polygonal data
      NULL;
    End Case;
    Return;
  End ConvertSpecialElements;

BEGIN
  Initialise();
END GF;  -- Factory Package
/
SHOW ERRORS

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'GF';
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

grant execute on GF to public;

QUIT;
