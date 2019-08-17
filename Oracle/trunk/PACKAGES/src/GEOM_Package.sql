DEFINE defaultSchema='&1'

SET VERIFY OFF;

SET SERVEROUTPUT ON
alter session set plsql_optimize_level=1;

create or replace package Geom
AUTHID CURRENT_USER
Is

  /** Common types
  */
  TYPE T_Integers    IS TABLE OF INTEGER;

  TYPE T_VertexSet   IS TABLE OF &&defaultSchema..T_Vertex;

  TYPE T_VectorSet   IS TABLE OF &&defaultSchema..T_Vector;

  TYPE T_GeometrySet IS TABLE OF &&defaultSchema..T_Geometry;

  /* For Function GetNumRings() */
  c_rings_all        Constant Pls_Integer   := 0;
  c_rings_outer      Constant Pls_Integer   := 1;
  c_rings_inner      Constant Pls_Integer   := 2;

  /** ----------------------------------------------------------------------------------------
  * @function   : Convert_Unit
  * @precis     : Function to convert a value from one unit of measure to another.
  * @version    : 1.0
  * @usage      : Function Convert_Unit ( p_from_unit IN varchar2,
  *                                       p_value     IN Number
  *                                       p_to_unit   IN VarChar2 )
  *                 Return Number Deterministic;
  *               eg dLinks := &&defaultSchema..geom.convert_unit('CHAIN',1,'LINK');
  * @param      : p_from_unit  : Number : The unit of measure describing p_value. Must exist in mdsys.sdo_dist_units
  * @param      : p_value      : Number : The actual distance expressed in SRID's units to be converted
  * @return     : p_to_unit    : Number : The unit of measure to convert p_value to. Must exist in mdsys.sdo_dist_units
  * @note       : Supplied p_from_unit must exist in mdsys.sdo_dist_units
  * @note       : Supplied p_to_unit should exist in mdsys.sdo_dist_units
  * @history    : Simon Greener - Feb 2008 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function Convert_Unit( p_from_unit in varchar2,
                         p_value     in number,
                         p_to_unit   in varchar2 )
           return number deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : Convert_Distance
  * @precis     : Function to convert a distance in a SRID's unit of measure to another unit of measure.
  * @version    : 1.0
  * @usage      : Function Convert_Distance ( p_srid  IN number,
  *                                           p_value IN Number
  *                                           p_unit  IN VarChar2 )
  *                 Return Number Deterministic;
  *               eg distanceInFeet := &&defaultSchema..geom.Convert_Distance(8311,1,'Feet');
  * @param      : p_srid  : Number : A valid srid (ie exists in mdsys.cs_srs)
  * @param      : p_value : Number : The actual distance expressed in SRID's units to be converted
  * @return     : p_unit  : Number : The unit of measure to convert p_value to. Must exist in mdsys.sdo_dist_units
  * @note       : Supplied p_srid must exist in mdsys.cs_srs
  * @note       : Supplied p_units should exist in mdsys.sdo_dist_units
  * @history    : Simon Greener - Feb 2008 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function Convert_Distance( p_srid  in number,
                             p_value in number,
                             p_unit  in varchar2 := 'Meter' )
           Return Number Deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : Generate_Series
  * @precis     : Function that generates a series of numbers mimicking PostGIS's function with
  *               the same name
  * @version    : 1.0
  * @usage      : Function generate_series(p_start pls_integer,
  *                                        p_end   pls_integer,
  *                                        p_step  pls_integer )
  *                 Return &&defaultSchema..geom.t_integers Pipelined;
  *               eg SELECT s.* FROM TABLE(generate_series(1,1000,10)) s;
  * @param      : p_start : Integer : Starting value
  * @param      : p_end   : Integer : Ending value.
  * @return     : p_step  : Integer : The step value of the increment between start and end
  * @history    : Simon Greener - June 2008 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function Generate_Series(p_start pls_integer,
                           p_end   pls_integer,
                           p_step  pls_integer )
       Return &&defaultSchema..geom.t_integers Pipelined;

  /** ----------------------------------------------------------------------------------------
  * @function   : Generate_DimInfo
  * @precis     : Function that generates a 2D/3D diminfo structure with default tolerances of
  *               Constants.c_MinVal/Constants.c_MaxVal
  * @version    : 1.0
  * @usage      : Function Generate_DimInfo(p_dims        in number,
  *                                         p_X_tolerance in number,
  *                                         p_Y_tolerance in number := NULL,
  *                                         p_Z_tolerance in number := NULL)
  *                 Return mdsys.sdo_dim_array deterministic;
  *               eg SELECT s.* FROM TABLE(generate_series(1,1000,10)) s;
  * @param      : p_dims        : Integer : Number of dimensions from 2 to 3 (will return NULL otherwise)
  * @param      : p_X_tolerance : Number : X ordinate tolerance
  * @return     : p_Y_tolerance : Number : Y ordinate tolerance
  * @return     : p_Z_tolerance : Number : Z ordinate tolerance
  * @history    : Simon Greener - June 2008 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function Generate_DimInfo(p_dims        in number,
                            p_X_tolerance in number,
                            p_Y_tolerance in number := NULL,
                            p_Z_tolerance in number := NULL)
    Return mdsys.sdo_dim_array deterministic;

  /**
  * @function   : ADD_ELEMENT
  * @precis     : A procedure that allows a user to add a new element to a supplied
  *               element info array.
  * @version    : 1.0
  * @history    : Simon Greener - Jul 2001 - Original coding.
  * @todo       : Integrate into GF
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  procedure ADD_Element (
    p_sdo_elem_info  in out nocopy mdsys.sdo_elem_info_array,
    p_offset         in number,
    p_etype          in number,
    p_interpretation in number );

  /** Additional Wrapper function
  **/
  Procedure ADD_Element( p_SDO_Elem_Info  in out nocopy mdsys.sdo_elem_info_array,
                         p_Elem_Info      in &&defaultSchema..T_ElemInfo );


  /** ----------------------------------------------------------------------------------------
  * @function   : isCompoundElement
  * @precis     : A function that tests whether an sdo_geometry element contains circular arcs
  * @version    : 1.0
  * @history    : Simon Greener - Aug 2009 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function isCompoundElement(p_elem_type in number)
    return boolean deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : hasCircularArcs
  * @precis     : A function that tests whether an sdo_geometry contains circular arcs
  * @version    : 1.0
  * @history    : Simon Greener - Dec 2008 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function hasCircularArcs(p_elem_info in mdsys.sdo_elem_info_array)
    return boolean deterministic;

  /** Wrappers
  */
  Function isCompound(p_elem_info in mdsys.sdo_elem_info_array)
    return integer deterministic;

  Function hasArc(p_elem_info in mdsys.sdo_elem_info_array)
    return integer deterministic;

  Function numCompoundElements(p_geometry in sdo_geometry)
    return integer deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : isRectangle
  * @precis     : A function that tests whether an sdo_geometry contains rectangles
  * @version    : 1.0
  * @history    : Simon Greener - Jun 2011 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function isRectangle(p_elem_info in mdsys.sdo_elem_info_array)
    return integer deterministic;

  Function hasRectangles(p_elem_info in mdsys.sdo_elem_info_array)
    return boolean deterministic;

  Function numOptimizedRectangles(p_geometry in sdo_geometry)
    return integer deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : Rectangle2Polygon
  * @precis     : A function that converts a single ringed geometry with a rectangle to its 5 vertex
  *               Polygon equivalent.
  * @version    : 1.0
  * @history    : Simon Greener - Jun 2016 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function Rectangle2Polygon(p_geometry in mdsys.sdo_geometry)
    return mdsys.sdo_geometry deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : Polygon2Rectangle
  * @precis     : A function that check and then converts a 5 vertex geometry to its optimized rectangle equivalent.
  * @version    : 1.0
  * @history    : Simon Greener - Jun 2011 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function Polygon2Rectangle( p_geometry  in mdsys.sdo_geometry,
                              p_tolerance in number default 0.005 )
    Return mdsys.sdo_geometry Deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Multi
  * @precis     : A function that converts a single part geometry to a multipart (with one element)
  * @version    : 1.0
  * @history    : Simon Greener - Dec 2016 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function st_multi(p_single_geometry in mdsys.sdo_geometry)
    Return mdsys.sdo_geometry deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : isMeasured
  * @precis     : A function that tests whether an sdo_geometry contains LRS measures
  * @version    : 1.0
  * @history    : Simon Greener - Dec 2008 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function isMeasured( p_gtype in number )
    return boolean deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : IsOrientedPoint
  * @precis     : A function that tests whether an sdo_geometry is an oriented (multi-)point
  * @version    : 1.0
  * @history    : Simon Greener - May 2010 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
    Function isOrientedPoint( p_elem_info in mdsys.sdo_elem_info_array)
    return integer Deterministic;

  Function orientation(p_oriented_point in mdsys.sdo_geometry)
    Return Number Deterministic;

  Function Point2oriented(P_Point      In Mdsys.Sdo_Geometry, 
                          P_Degrees    In Number,
                          P_Dec_Digits In Integer Default 5)
    Return mdsys.sdo_geometry deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ADD_COORDINATE
  * @precis     : A procedure that allows a user to add a new coordinate to a supplied ordinate info array.
  * @version    : 1.0
  * @history    : Simon Greener - Jul 2001 - Original coding.
  * @todo       : Integrate into GF
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  procedure ADD_Coordinate(
    p_ordinates  in out nocopy mdsys.sdo_ordinate_array,
    p_dim        in number,
    p_x_coord    in number,
    p_y_coord    in number,
    p_z_coord    in number,
    p_m_coord    in number,
    p_measured   in boolean := false);

  /**
  * Overloads of main ADD_COORDINATE procedure
  **/
  PROCEDURE ADD_Coordinate( p_ordinates  in out nocopy mdsys.sdo_ordinate_array,
                            p_dim        in number,
                            p_coord      in &&defaultSchema..ST_Point,
                            p_measured   in boolean := false);

  PROCEDURE ADD_Coordinate( p_ordinates  in out nocopy mdsys.sdo_ordinate_array,
                            p_dim        in number,
                            p_coord      in &&defaultSchema..T_Vertex,
                            p_measured   in boolean := false);

  PROCEDURE ADD_Coordinate( p_ordinates  in out nocopy mdsys.sdo_ordinate_array,
                            p_dim        in number,
                            p_coord      in mdsys.vertex_type,
                            p_measured   in boolean := false);

  PROCEDURE ADD_Coordinate( p_ordinates  in out nocopy mdsys.sdo_ordinate_array,
                            p_dim        in number,
                            p_coord      in mdsys.sdo_point_type,
                            p_measured   in boolean := false);

  /** ----------------------------------------------------------------------------------------
  * @function   : TOTALCOORDS
  * @precis     : Returns number of 2D/3D/4D coordinates (as against ordinates) in a shape.
  * @version    : 1.0
  * @usage      : Function totalCoords ( p_geometry IN MDSYS.SDO_GEOMETRY ) RETURN number DETERMINISTIC;
  *               eg tCoords := geom.totalCoords(shape);
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A shape.
  * @return     : totalCoords : Number : The vector.
  * @history    : Simon Greener - Jan 2002 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  function TotalCoords    (
    p_geometry in MDSYS.SDO_Geometry )
    return number deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : GetNumElem
  * @precis     : Returns total number of elements in a geometry.
  * @version    : 1.0
  * @usage      : Function GetNumElem ( p_geometry IN MDSYS.SDO_GEOMETRY )
  *                 Return number Deterministic;
  * @example    : SELECT GetNumElem(a.geom)
  *                 FROM ProjCompound2D a
  *                WHERE a.geom is not null;
  * @param      : p_geometry       : MDSYS.SDO_GEOMETRY : A shape.
  * @return     : NumberOfElements : T_ElemInfoSet : Set of Elements of type ElemInfoSet.
  * @history    : Simon Greener - Jan 2006 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  function GetNumElem(
    p_geometry in mdsys.sdo_geometry )
    return number deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : GetElemInfo
  * @precis     : Returns Element Info as a set of Elements.
  * @version    : 1.0
  * @usage      : Function GetElemInfo ( p_geometry IN MDSYS.SDO_GEOMETRY )
  *                 Return T_ElemInfoSet Deterministic;
  * @example    : SELECT DISTINCT
  *                      ei.etype,
  *                      ei.interpretation
  *                 FROM ProjCompound2D a,
  *                      TABLE( &&defaultSchema..geom.GetElemInfo( a.geom ) ) ei
  *                WHERE a.geom is not null;
  * @param      : p_geometry : MDSYS.SDO_GEOMETRY : A shape.
  * @return     : elements   : T_ElemInfoSet : Set of Elements of type ElemInfoSet.
  * @note       : Function is pipelined
  * @history    : Simon Greener - Jan 2006 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  function GetElemInfo(
    p_geometry in mdsys.sdo_geometry)
    Return &&defaultSchema..T_ElemInfoSet pipelined;

  Function GetElemInfoSet(p_geometry in mdsys.sdo_geometry)
    Return &&defaultSchema..T_ElemInfoSet deterministic;

  Function GetElemInfoAt(
    p_geometry in mdsys.sdo_geometry,
    p_element  in pls_integer)
    Return &&defaultSchema..T_ElemInfo deterministic;

  Function GetETypeAt(
    p_geometry  in mdsys.sdo_geometry,
    p_element   in pls_integer)
    Return pls_integer deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : GetNumRings
  * @precis     : Returns Number of Rings in a polygon/mutlipolygon.
  * @version    : 1.0
  * @usage      : Function GetNumRings ( p_geometry  IN MDSYS.SDO_GEOMETRY,
  *                                      p_ring_type IN INTEGER )
  *                 Return Number Deterministic;
  * @example    : SELECT GetNumRings( SDO_GEOMETRY(2007,  -- two-dimensional multi-part polygon with hole
  *                                                NULL,
  *                                                NULL,
  *                                                SDO_ELEM_INFO_ARRAY(1,1005,2, 1,2,1, 5,2,2,
  *                                                                   11,2005,2, 11,2,1, 15,2,2,
  *                                                                   21,1005,2, 21,2,1, 25,2,2),
  *                                                SDO_ORDINATE_ARRAY(  6,10, 10,1, 14,10, 10,14,  6,10,
  *                                                                    13,10, 10,2,  7,10, 10,13, 13,10,
  *                                                                   106,110, 110,101, 114,110, 110,114,106,110)
  *                                               )
  *                                   )
  *                      as RingCount
  *                 FROM DUAL;
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A shape.
  * @param      : p_ring_type : integer : All, inner or outer rings
  * @return     : numberRings : Number : Number of outer and inner rings.
  * @history    : Simon Greener - Dec 2008 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
 Function GetNumRings(p_geometry  in mdsys.sdo_geometry,
                      p_ring_type in integer /* 0 = ALL; 1 = OUTER; 2 = INNER */ )
   Return Number Deterministic;

  /* Overloads */
  Function GetNumRings( p_geometry in mdsys.sdo_geometry )
    Return Number Deterministic;

  Function GetNumOuterRings( p_geometry in mdsys.sdo_geometry )
    Return Number Deterministic;

  Function GetNumInnerRings( p_geometry in mdsys.sdo_geometry )
    Return Number Deterministic;

  /**
  * @function   : Convert_Geometry
  * @precis     : A function that converts any special elements - circulararcs, rectangles, \
  *               circles - in a geometry to vertex to vertex linestrings
  * @version    : 1.0
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A geographic shape.
  * @param      : p_arc2chord : number : The arc2chord distance used in converting circular arcs and circles.
  *                                      Expressed in dataset units eg decimal degrees if 8311. See Convert_Distance
  *                                      for method of converting distance in meters to dataset units.
  * @history    : Simon Greener - Feb 2008 - Original coding
  **/
  Function Convert_Geometry(
     p_geometry  In mdsys.SDO_Geometry,
     p_arc2chord In Number := 0.1 )
     Return mdsys.SDO_GEOMETRY Deterministic;

  /***
  * @function   : GetVector
  * @precis     : Places a geometry's coordinates into a pipelined vector data structure using ST_Point (ie > 2D).
  * @version    : 2.0
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A geographic shape.
  * @history    : Simon Greener - Jan 2007 - ST_Point support, integrated into this package.
  **/
  Function GetVector( p_geometry in mdsys.sdo_geometry )
    Return &&defaultSchema..GEOM.t_VectorSet pipelined ;

  /***
  * @function   : GetVector
  * @precis     : Places a geometry's coordinates into a pipelined vector data structure using ST_Point (ie > 2D).
  * @version    : 2.0
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A geographic shape.
  * @param      : p_arc2chord : number : The arc2chord distance used in converting circular arcs and circles.
  *                                      Expressed in dataset units eg decimal degrees if 8311. See Convert_Distance
  *                                      for method of converting distance in meters to dataset units.
  * @history    : Simon Greener - Jan 2007 - ST_Point support, integrated into this package.
  * @history    : Simon Greener - Apr 2008 - Rebuilt to be a wrapper over GetVector.
  **/
  function GetVector( p_geometry  in mdsys.sdo_geometry,
                      p_arc2chord in number )
    Return &&defaultSchema..GEOM.t_VectorSet pipelined;

  /** ----------------------------------------------------------------------------------------
  * @function   : GetVector2DArray
  * @precis     : Places a geometry's coordinates into a vector data structure.
  * @version    : 2.0
  * @description: Loads the coordinates of a linestring, polygon geometry into a
  *               simple vector data structure for easy manipulation by other functions
  * @usage      : Function GetVector2DArray ( p_geometry IN MDSYS.SDO_GEOMETRY, p_arc2chord in number := 0.1 )
  *                 Return T_Vector2DSet DETERMINISTIC
  *               eg aVector := geom.GetVector2DArray(shape);
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A shape.
  * @param      : p_dimarray  : MDSYS.SDO_DIM_ARRAY : The dimarray describing the shape.
  * @param      : p_arc2chord : number : The arc2chord distance used in converting circular arcs and circles.
  *                                      Expressed in dataset units eg decimal degrees if 8311. See Convert_Distance
  *                                      for method of converting distance in meters to dataset units.
  * @return     : geomVector  : T_Vector2DSet : The vector.
  * @requires   : Global data types coordRec, vectorRec and T_Vector2DSet
  * @requires   : GEOM package's GetVector() and Converte_Geometry() functions.
  * @history    : Simon Greener - Jun 2002 - Original coding.
  * @history    : Simon Greener - Jan 2006 - Point support, integrated into this package.
  * @history    : Simon Greener - Apr 2008 - Rebuilt to be a wrapper over GetVector.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  function GetVector2DArray ( p_geometry  in mdsys.sdo_geometry,
                              p_arc2chord in number := 0.1 )
    Return &&defaultSchema..T_Vector2DSet deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : GetVector2D
  * @precis     : Places a geometry's coordinates into a pipelined vector data structure.
  * @version    : 2.0
  * @description: Loads the coordinates of a linestring, polygon geometry into a
  *               pipelined vector data structure for easy manipulation by other functions
  * @usage      : Function GetVector2D( p_geometry IN MDSYS.SDO_GEOMETRY, p_arc2chord in number := 0.1 )
  *                 Return T_Vector2DSet PIPELINED
  *               eg select *
  *                    from myshapetable a,
  *                         table(geom.GetPipeVector2D(a.shape));
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A geographic shape.
  * @param      : p_dimarray  : MDSYS.SDO_DIM_ARRAY : The dimarray describing the geographic shape.
  * @param      : p_arc2chord : number : The arc2chord distance used in converting circular arcs and circles.
  *                                      Expressed in dataset units eg decimal degrees if 8311. See Convert_Distance
  *                                      for method of converting distance in meters to dataset units.
  * @return     : geomVector  : T_Vector2DSet : The vector pipelined.
  * @requires   : Global data types coordRec, vectorRec and T_Vector2DSet
  * @requires   : GF package.
  * @history    : Simon Greener - July 2006 - Original coding from GetVector2D
  * @history    : Simon Greener - Apr 2008 - Rebuilt to be a wrapper over GetVector.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  function GetVector2D( p_geometry  in mdsys.sdo_geometry,
                        p_arc2chord in number := 0.1 )
    Return &&defaultSchema..T_Vector2DSet pipelined;

  /***
  * @function   : GetArcs
  * @precis     : Like GetVector but this one only extracts 3 point arcs and circles from geometries.
  * @version    : 2.0
  * @history    : Simon Greener - Jan 2007 - Original coding.
  **/
  Function GetArcs( p_geometry in mdsys.sdo_geometry )
    return &&defaultSchema..T_ArcSet pipelined;

  /***
  * @function   : GetPointSet
  * @precis     : Places a geometry's coordinates into a pipelined  data structure using ST_Point (ie > 2D).
  * @version    : 1.0
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A geographic shape.
  * @param      : p_stroke    : number : If false (default), points in the geometry are returned as they are, otherwise they are stroked.
  * @param      : p_arc2chord : number : The arc2chord distance used in converting circular arcs and circles.
  *                                      Expressed in dataset units eg decimal degrees if 8311. See Convert_Distance
  *                                      for method of converting distance in meters to dataset units.
  * @history    : Simon Greener - Jan 2007 - ST_Point support, integrated into this package.
  * @history    : Simon Greener - Jan 2008 - Added support for the conversion of rectangles, circular arcs and circles.
  **/
  Function GetPointSet( p_geometry  In mdsys.Sdo_Geometry,
                        p_stroke    in number := 0,
                        p_arc2chord in number := 0.1)
           Return &&defaultSchema..ST_PointSet Pipelined;

  /**
  * OGC isSimple() function
  **/
  function isSimple (
    p_geometry in mdsys.sdo_geometry,
    p_dimarray in MDSYS.SDO_Dim_Array )
    return integer deterministic;

  /**
  * Overload of main isSimple function
  **/
  function isSimple (
    p_geometry  in mdsys.sdo_geometry,
    p_tolerance in number )
    return integer deterministic;

  /* ----------------------------------------------------------------------------------------
  * @function   : Densify
  * @precis     : Implements a basic geometry densification algorithm.
  * @version    : 1.0
  * @description: This function uses a binary-chop recursive algorithm to add vertices to
  *               an existing vertex-to-vertex described linestring or polygon sdo_geometry.
  *               New vertices are added in such a way as to ensure that no two vertices will
  *               ever fall with p_tolerance. Also, because of the binary-chop implementation
  *               there is no guarantee that the added vertices will be p_distance apart. The
  *               implementation prefers to balance the added vertices across a complete segment
  *               such that an even number are added. The final vertex separation will be
  *               BETWEEN p_distance AND p_distance * 2 .
  *
  *               The implementation honours 3D and 4D shapes and averages these dimension values
  *               for the new vertices.
  *
  *               The function does not support compound objects or objects with circles,
  *               optimised rectangles or described by arcs. An exception is raised if one of
  *               these is passed to the function.
  *
  *               Any point shape is simply returned as it is.
  *
  * @usage      : Function Densify ( p_geometry IN MDSYS.SDO_GEOMETRY,
  *                                  p_tolerance IN number,
  *                                  p_distance  IN number )
  *                                ) RETURN MDSYS.SDO_GEOMETRY
  *               eg new_detailed_geom := geom.Densify(geometry,1,10);
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A vector geometry described by vertex-to-vertex (Elem Interp 1).
  * @param      : p_tolerance : number : The sdo_tolerance for the geometry (see diminfo)
  * @param      : p_distance  : number : The desired optimal distance between added vertices. Must be > p_tolerance.
  * @return     : Geometry    : MDSYS.SDO_GEOMETRY : Densified geometry.
  * @requires   : &&defaultSchema..GF package.
  * @history    : Simon Greener - June 2006 - Original coding.
  * @history    : Simon Greener - July 2006 - Migrated to GF package.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  function Densify( p_geometry  in MDSYS.SDO_Geometry,
                    p_tolerance in number,
                    p_distance  in number )
           return MDSYS.SDO_Geometry deterministic;

   /*
   --  @function To_2D
   --  @precis   Converts a geometry to a 2D geometry
   --  @version  2.0
   --  @usage    v_2D_geom := geom.To_2D(MDSYS.SDO_Geometry(3001,....)
   --  @history  Albert Godfrind, July 2006, Original Coding
   --  @history  Bryan Hall,      July 2006, Modified to handle points
   --  @history  Simon Greener,   July 2006, Integrated into geom with GF.
   --  @history  Simon Greener,   Aug  2009, Removed GF; Modified Byan Hall's version to handle compound elements.
   */
   Function To_2D( p_geom IN MDSYS.SDO_Geometry )
     Return MDSYS.SDO_Geometry deterministic;

   /*
   --  @function To_3D
   --  @precis   Converts a 2D or 4D geometry to a 3D geometry
   --  @version  1.0
   --  @usage    v_3D_geom := geom.To_3D(MDSYS.SDO_Geometry(2001,....),50)
   --  @history  Simon Greener,   May 2007 Original coding
   --  @history  Simon Greener,   Aug 2009 Added support for interpolating Z values
   */
  Function To_3D( p_geom      IN MDSYS.SDO_Geometry,
                  p_start_z   IN NUMBER := NULL,
                  p_end_z     IN NUMBER := NULL,
                  p_tolerance IN NUMBER := 0.05)
     Return MDSYS.SDO_Geometry deterministic;

   /*
   --  @function DownTo_3D
   --  @precis   Converts a 4D geometry to a 3D geometry
   --  @version  1.0
   --  @usage    v_3D_geom := geom.DownTo_3D(MDSYS.SDO_Geometry(4001,....),50)
   --  @history  Simon Greener,   May 2010 Original coding
   */
  Function DownTo_3D( p_geom  IN MDSYS.SDO_Geometry,
                      p_z_ord IN INTEGER )
    Return MDSYS.SDO_GEOMETRY deterministic;

   /** @Function : FIX_3D_Z
   *  @Precis   : Checks the Z ordinate in the SDO_GEOMETRY and if NULL changes to p_default_z value
   *  @Note     : Needed as MapServer appears to not handle 3003/3007 polygons with NULL Z values in the sdo_ordinate_array
   *  @History  : Simon Greener  -  JUNE 4th 2007  - Original Coding
   **/
   Function Fix_3D_Z( p_3D_geom   IN MDSYS.SDO_Geometry,
                      p_default_z IN NUMBER := -9999 )
            Return MDSYS.SDO_Geometry Deterministic;

  /* ----------------------------------------------------------------------------------------
  * @function   : ExtractLine
  * @precis     : Function which extracts any lines in a COMPOUND 2004 object.
  * @version    : 1.0
  * @description: Result of an intersect can result in a COMPOUND shape with points, linestrings
  *               and polygons as the result.  This function iterates over all the parts of
  *               a multi-part (SDO_GTYPE == 2004) shape, extracts only the linestring elements
  *               and returns them in a new shape.
  * @usage      : Function ExtractLine ( p_geometry IN MDSYS.SDO_GEOMETRY )
  *                        RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;
  *               eg v_geometry := &&defaultSchema..geom.ExtractLine(p_geometry);
  * @param      : p_geometry : MDSYS.SDO_GEOMETRY : A shape.
  * @return     : newShape   : MDSYS.SDO_GEOMETRY : Shape with only linestring elements.
  * @requires   : Oracle 10g esp SDO_UTIL.CONCAT_LINES
  * @history    : Simon Greener - Feb 2006 - Original coding
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  function ExtractLine(
    p_geometry in MDSYS.SDO_Geometry )
    return MDSYS.SDO_Geometry deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ExtractPoint
  * @precis     : Function which extracts any points in a COMPOUND 2004 object.
  * @version    : 1.0
  * @description: Result of an intersect can result in a COMPOUND shape with points, linestrings
  *               and polygons as the result.  This function iterates over all the parts of
  *               a multi-part (SDO_GTYPE == 2004) shape, extracts only the point elements
  *               and returns them in a new shape.
  * @usage      : Function ExtractPoint ( p_geometry IN MDSYS.SDO_GEOMETRY )
  *                        RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;
  *               eg v_geometry := &&defaultSchema..geom.ExtractPoint(p_geometry);
  * @param      : p_geometry : MDSYS.SDO_GEOMETRY : A shape.
  * @return     : newShape   : MDSYS.SDO_GEOMETRY : Shape with only point elements.
  * @requires   : Oracle 10g esp SYS.SDO_UTIL.APPEND
  * @history    : Simon Greener - Feb 2006 - Original coding
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  function ExtractPoint (
    p_geometry in MDSYS.SDO_Geometry )
    return MDSYS.SDO_Geometry deterministic;

  /** Function just to change a single point coded in sdo_ordinates to sdo_point representation
  * @param p_geometry  A sdo_geometry object.
  **/
  Function ToSdoPoint ( p_geometry in MDSYS.SDO_Geometry )
    return MDSYS.SDO_Geometry Deterministic;

  /** Function which extracts a polygon from a COMPOUND 2004 object using 10g features.
  * @param p_geometry  A sdo_geometry object.
  **/
  function ExtractPolygon (
    p_geometry in MDSYS.SDO_Geometry )
    return MDSYS.SDO_Geometry deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ExtractPolygon9i
  * @precis     : Function which extracts any polygons in a COMPOUND 2004 object.
  * @version    : 1.0
  * @description: Result of an intersect can result in a COMPOUND shape with linestrings
  *               as well as polygons as the result.  This function iterates over all the parts of
  *               a multi-part (SDO_GTYPE == 2004) shape, extracts the polygon elements
  *               and returns them in a new shape.
  * @usage      : Function ExtractPolygon9i ( p_geometry IN MDSYS.SDO_GEOMETRY,
  *                                           p_dimarray IN MDSYS.SDO_DIM_ARRAY )
  *                        RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;
  *               eg p_geometry := &&defaultSchema..geom.ExtractPolygon(p_geometry);
  * @param      : p_geometry : MDSYS.SDO_GEOMETRY  : A shape.
  * @param      : p_dimarray : MDSYS.SDO_DIM_ARRAY : The dimarray describing the shape.
  * @requires   : &&defaultSchema..GEOMETRY package.
  * @return     : newShape : MDSYS.SDO_GEOMETRY : Shape with only polygon elements.
  * @history    : Simon Greener - Mar 2004 - Original coding.
  * @history    : Simon Greener - Oct 2005 - Changed to ExtractPolygon9i
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  function ExtractPolygon9i(
    p_geometry in MDSYS.SDO_Geometry,
    p_dimarray in MDSYS.SDO_Dim_Array )
    return MDSYS.SDO_Geometry deterministic;

  /** ExtractGeometry
  * Overload of main ExtractFunctions (except ExtractPolyon9i)
  * @param  p_geometryType Type of geometry object (POINT, LINE, POLYGON) to extract.
  * @param  p_geometry     An Sdo_geometry object.
  **/
  function ExtractGeometry(
    p_geometryType in varchar2,
    p_geometry     in MDSYS.SDO_Geometry )
    return MDSYS.SDO_Geometry deterministic;

  /**
  * ExtractElements returns each element identified in sdo_elem_info as a separate sdo_geometry
  * @param p_geometry    The main geometry object
  * @param p_subElements If set to 1 (true) subelements of a compound element will be extracted.
  **/
  function ExtractElements(
    p_geometry    in MDSYS.SDO_Geometry,
    p_subElements in number )
    return &&defaultSchema..T_GeometrySet deterministic;

  /**
  * ExtractElementsPiped returns each element identified in sdo_elem_info as a separate sdo_geometry but via a pipeline
  * @param p_geometry    The main geometry object
  * @param p_subElements If set to 1 (true) subelements of a compound element will be extracted.
  **/
  function ExtractElementsPiped(
    p_geometry    in MDSYS.SDO_Geometry,
    p_subElements in number )
    return &&defaultSchema..T_GeometrySet pipelined;

  /** ***************************************************************
  *  ExplodeGeometry
  *  ***************************************************************
  *  Created:     17/12/2004
  *  Author:      Simon Greener
  *  Description: Breaks a geometry into its fundamenal elements which
  *               includes the breaking down of compound LineStrings or
  *               Polygons down into their individual subElements: returns
  *               children of compound elements as themselves; and all other
  *               elements as themselves.
  *  Note:        This function is for 8i and 9iR1. For 9iR2 and above use ExtractElements
  *               with p_subElements = 1 to get an equivalent output.
  **/
  Function ExplodeGeometry(
    p_geometry in MDSYS.SDO_Geometry )
    Return &&defaultSchema..T_GeometrySet pipelined;

  /**
  * ST_Dump       Extracts valid, individual geometries, from a geometry's elements and sub-elements
  *  Created:     10/12/2008
  *  Author:      Simon Greener
  *  Description: Mimicks PostGIS ST_Dump function.
  *               Is a wrapper over ExtractElementsPiped
  **/
  Function ST_Dump( p_geometry in MDSYS.SDO_GEOMETRY)
    Return &&defaultSchema..T_GeometrySet pipelined;

  /** ----------------------------------------------------------------------------------------
  * @function   : Split
  * @precis     : A procedure that splits a line geometry at a known point
  * @version    : 1.0
  * @description: This procedure will split a linestring or multi-linestring sdo_geometry object
  *               at a supplied (known) point. Normally the point should lie on the linestring at
  *               a vertex or between two vertices but the algorithm used will split a line even if
  *               the point does not lie on the line. Where the point does not lie on the linestring
  *               the algorithm approproximates the nearest point on the linestring to the supplied point
  *               and splits it there: the algorithm is ratio based and will not be accurate for geodetic data.
  * @usage      : procedure Split( p_line      in mdsys.sdo_geometry,
  *                                p_point     in mdsys.sdo_geometry,
  *                                p_tolerance in number,
  *                                p_out_line1 out mdsys.sdo_geometry,
  *                                p_out_line2 out mdsys.sdo_geometry )
  * @param      : p_line      : MDSYS.SDO_GEOMETRY : A linestring(2002) or multi-linestring (2006) sdo_geometry object describing the line to be split.
  * @param      : p_point     : MDSYS.SDO_GEOMETRY : A point(2001) sdo_geometry object describing the point for splitting the linestring.
  * @param      : p_tolerance : NUMBER : Tolerance value used in MDSYS.SDO_GEOM.SDO_DISTANCE function.
  * @return     : p_out_line1 : MDSYS.SDO_GEOMETRY : First part of split linestring
  * @return     : p_out_line2 : MDSYS.SDO_GEOMETRY : Second part of split linestring
  * @history    : Simon Greener - Jan 2008 - Original coding.
  * @history    : Simon Greener - Dec 2009 - Fixed SRID handling bug for Geodetic data.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Procedure Split( p_line      in mdsys.sdo_geometry,
                   p_point     in mdsys.sdo_geometry,
                   p_tolerance in number,
                   p_out_line1 out nocopy mdsys.sdo_geometry,
                   p_out_line2 out nocopy mdsys.sdo_geometry );

  /**
  * Overload of the Split procedure
  */
  Function Split( p_line      in mdsys.sdo_geometry,
                  p_point     in mdsys.sdo_geometry,
                  p_tolerance in number )
    Return &&defaultSchema..T_GeometrySet pipelined;

  /** AsEWKT
  * @function   : AsEWKT
  * @precis     : Function that returns a fully described WKT which includes SRID, 3D and 4D
  *               data with all inner elements including the WKT descriptor.
  *               As "Extended" WKT based on AutoDesk's FDO AGFText
  * @version    : 1.0
  * @history    : Simon Greener - Apr 2007 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function AsEWKT(
    p_geometry In mdsys.sdo_geometry )
           Return CLOB deterministic;

  /** AsEWKT
  * @param p_GeomSet  A set of sdo_geometry objects.
  **/
  Function AsEWKT(
    p_GeomSet In &&defaultSchema..T_GeometrySet )
           Return CLOB deterministic;

  /** RemoveDuplicateCoordinates
  * Sequential vertices with same coordinate values are replaced by a single vertex.
  * @param p_geometry  An sdo_geometry objects.
  * @param p_diminfo   An user_sdo_geom_metadata.diminfo object from which the sdo_tolerance values are extracted.
  **/
  Function removeDuplicateCoordinates (
    p_geometry   in MDSYS.SDO_Geometry,
    p_diminfo in MDSYS.SDO_Dim_Array)
    return MDSYS.SDO_Geometry deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : TOLERANCE
  * @precis     : Function which updates all coordinates in a shape to precision of the
  *               tolerances referenced in the diminfo structure.
  * @version    : 1.0
  * @description: Nothing in the Oracle Spatial library ensures that a shape loaded into
  *               a column in a table has its ordinates set to the precision specified in
  *               the table's SDO_GEOM_METADATA DIMARRAY.
  *               This function ensures that all the ordinates of a shape are specified to the
  *               precision documented in its dimarray.
  * @usage      : Function tolerance ( p_geometry IN MDSYS.SDO_GEOMETRY, p_dimarray IN MDSYS.SDO_DIM_ARRAY )
  *                 Return MDSYS.SDO_GEOMETRY DETERMINISTIC;
  *               eg fixedShape := &&defaultSchema..geom.tolerance(shape,diminfo);
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A shape.
  * @param      : p_dimarray  : MDSYS.SDO_DIM_ARRAY : The dimarray describing the shape.
  * @requires   : &&defaultSchema..GF package.
  * @return     : newShape    : MDSYS.SDO_GEOMETRY : Shape whose coordinates are 'truncated'.
  * @history    : Simon Greener - Feb 2002 - Original coding.
  * @history    : Simon Greener - Jul 2006 - Migrated to GF package and made 3D aware.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  function Tolerance (
    p_geometry in MDSYS.SDO_Geometry,
    p_dimarray in MDSYS.SDO_Dim_Array )
    return MDSYS.SDO_Geometry deterministic;

  /** Overloads of above */
  Function Tolerance (
    p_geometry in MDSYS.SDO_Geometry,
    p_tolerance in Number )
    return MDSYS.SDO_Geometry deterministic;

  Function Tolerance( p_geometry  IN MDSYS.SDO_GEOMETRY,
                      p_X_tolerance IN NUMBER,
                      p_Y_tolerance IN NUMBER,
                      p_Z_tolerance IN NUMBER := NULL)
    RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;

  Function Roundordinates( P_Geometry        In Mdsys.Sdo_Geometry,
                           P_X_Round_Factor  In Number,
                           P_Y_Round_Factor  In Number := Null,
                           P_Z_Round_Factor  In Number := Null,
                           p_m_round_factor  In Number := null)
    Return Mdsys.Sdo_Geometry Deterministic;

  /** ToleranceUpdate
  *   Version of Tolerance that processes a whole table.
  *   @param p_tableName The table containing sdo_geometry objects.
  **/
  procedure ToleranceUpdate(
    p_tableName in varchar2 );

  /** ----------------------------------------------------------------------------------------
  * @function   : Parallel
  * @precis     : Function that moves the supplied linestring left/right a fixed amount.
  *               Bends in the linestring, when moved, can remain vertex-connected or be converted to curves.
  * @version    : 1.0
  * @usage      : FUNCTION Parallel(p_geometry   in mdsys.sdo_geometry,
  *                                 p_distance   in number,
  *                                 p_tolerance  in number,
  *                                 p_curved     in number := 0)
  *                 RETURN mdsys.sdo_geometry DETERMINISTIC;
  *               eg select Parallel(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,1,10)),10,0.05) from dual;
  * @param      : p_geometry  : mdsys.sdo_geometry : Original linestring/multilinestring
  * @param      : p_distance  : Number : Distance to move parallel -vs = left; +ve = right
  * @param      : p_tolerance : Number : Standard Oracle diminfo tolerance.
  * @param      : p_curved    : Integer (but really boolean) : Boolean flag indicating whether to stroke
  *                                                            bends in line (1=stroke;0=leave alone)
  * @return     : mdsys.sdo_geometry : input geometry moved parallel by p_distance units
  * @history    : Simon Greener - Devember 2008 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au
  **/
  FUNCTION Parallel(p_geometry   in mdsys.sdo_geometry,
                    p_distance   in number,
                    p_tolerance  in number,
                    p_curved     in number := 0)
    RETURN mdsys.sdo_geometry DETERMINISTIC;

  /** ----------------------------------------------------------------------------------------
  * @function   : SquareBuffer
  * @precis     : Function that creates a buffer with mitred rather than round ends.
  * @version    : 1.0
  * @usage      : FUNCTION SquareBuffer(p_geometry   in mdsys.sdo_geometry,
  *                                     p_distance   in number,
  *                                     p_tolerance  in number,
  *                                     p_curved     in number := 0)
  *                 RETURN mdsys.sdo_geometry DETERMINISTIC;
  *               eg select SquareBuffer(mdsys.sdo_geometry(2002,null,null,
  *                                            sdo_elem_info_array(1,2,1),
  *                                            sdo_ordinate_array(1,1,1,10)),
  *                                      10,0.05) from dual;
  * @param      : p_geometry  : mdsys.sdo_geometry : Original linestring/multilinestring
  * @param      : p_distance  : Number : Buffer Distance
  * @param      : p_tolerance : Number : Standard Oracle diminfo tolerance.
  * @param      : p_curved    : Integer (but really boolean) : Boolean flag indicating whether
  *               to stroke bends in line (1=stroke;0=leave alone)
  * @return     : mdsys.sdo_geometry : square buffer created over input geometry
  * @history    : Simon Greener - June 2011 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function SquareBuffer(p_geometry   in mdsys.sdo_geometry,
                        p_distance   in number,
                        p_tolerance  in number,
                        p_curved     in number := 0 )
    RETURN mdsys.sdo_geometry deterministic;

    /** ----------------------------------------------------------------------------------------
    * @function   : Reverse_Geometry
    * @precis     : Reverses ordinates in supplied sdo_geometry's sdo_ordinate_array.
    * @version    : 1.0
    * @description: The function reverses ordinates in supplied sdo_geometry's sdo_ordinate_array.
    * @usage      : select Reverse_Geometry(p_geometry) from dual;
    * @param      : p_geometry        : MDSYS.SDO_GEOMETRY : sdo_geometry whose ordinates will be reversed
    * @return     : modified geometry : MDSYS.SDO_GEOMETRY : SDO_Geometry with reversed ordinates
    * @history    : Simon Greener - Feb 2012 2010
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
    **/
   Function Reverse_Geometry(p_geometry in mdsys.sdo_geometry)
     Return mdsys.sdo_geometry Deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : Filter_Rings
  * @precis     : Function that allows a user to remove inner rings from a polygon/multipolygon
  *               based on an area value.
  * @version    : 1.0
  * @usage      : FUNCTION Filter_Rings(p_geometry   in mdsys.sdo_geometry,
  *                                     p_tolerance in number,
  *                                     p_area      in number,
  *                                     p_ring      in number := 0)
  *                 RETURN mdsys.sdo_geometry DETERMINISTIC;
  *               eg select Filter_Rings(mdsys.sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',null),
  *                                      10,
  *                                      0.05)
  *                    from dual;
  * @param      : p_geometry  : mdsys.sdo_geometry : Original polygon/multipolygon
  * @param      : p_area      : number : Area in square srid units below which an inner ring is removed.
  * @param      : p_tolerance : number : Standard Oracle diminfo tolerance.
  * @Param      : p_ring      : number : The number of the internal ring to be removed
  * @return     : mdsys.sdo_geometry : input geometry with any qualifying inner rings removed
  * @history    : Simon Greener - December 2008 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  FUNCTION Filter_Rings(p_geometry  in mdsys.sdo_geometry,
                        p_tolerance in number,
                        p_area      in number,
                        p_ring      in number := 0)
    RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;

  /** ----------------------------------------------------------------------------------------
  * @function   : SDO_AddPoint
  * @precis     : Adds a point to a MultiPoint, LineString or MultiLineString geometry before point <p_position> (1-based index: Set to -1/NULL for appending.
  * @version    : 1.0
  * @usage      : FUNCTION SDO_AddPoint(p_geometry   in mdsys.sdo_geometry,
  *                                     p_point      in mdsys.vertex_type,
  *                                     p_position   in number )
  *                 RETURN mdsys.sdo_geometry DETERMINISTIC;
  * @param      : p_geometry  : mdsys.sdo_geometry : Original geometry
  * @param      : p_point     : number : Actual point coordinates to be inserted
  * @param      : p_position  : number : Position before which point is inserted. If NULL or -1 the point is appended to whole geometry.
  * @return     : mdsys.sdo_geometry : input geometry with new point added.
  * @history    : Simon Greener - February 2009 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function SDO_AddPoint(p_geometry   IN MDSYS.SDO_Geometry,
                        p_point      IN MDSYS.Vertex_Type,
                        p_position   IN Number )
    Return MDSYS.SDO_Geometry Deterministic;

  Function SDO_AddPoint(p_geometry   IN MDSYS.SDO_Geometry,
                        p_point      IN &&defaultSchema..T_Vertex,
                        p_position   IN Number )
    Return MDSYS.SDO_Geometry Deterministic;

  -- Removes point (p_position) from a linestring. Offset is 1-based.
  Function SDO_RemovePoint(p_geometry  IN MDSYS.SDO_Geometry,
                           p_position  IN Number)
    Return MDSYS.SDO_Geometry Deterministic;

  -- OGC Style wrapper
  Function ST_RemovePoint(p_geometry  IN MDSYS.ST_Geometry,
                          p_position  IN Number)
    RETURN MDSYS.ST_Geometry DETERMINISTIC;

  /** ----------------------------------------------------------------------------------------
  * @function   : SDO_SetPoint
  * @precis     : Replace point (p_position) of linestring with given point (1-based index)
  * @version    : 1.0
  * @usage      : FUNCTION SDO_SetPoint(p_geometry   in mdsys.sdo_geometry,
  *                                     p_point      in mdsys.vertex_type,
  *                                     p_position   in number )
  *                 RETURN mdsys.sdo_geometry DETERMINISTIC;
  * @param      : p_geometry  : mdsys.sdo_geometry : Original geometry object
  * @param      : p_point     : mdsys.vertex_update : Actual point coordinates updating existing point
  * @param      : p_position  : Number : Position of point to be updated. If NULL the last point is updated otherwise, if a single sdo_point, that point is updated.
  * @return     : mdsys.sdo_geometry : input geometry with changed point.
  * @history    : Simon Greener - February 2009 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function SDO_SetPoint(p_geometry   IN MDSYS.SDO_Geometry,
                        p_point      IN MDSYS.Vertex_Type,
                        p_position   IN Number )
    Return MDSYS.SDO_Geometry Deterministic;
  Function SDO_SetPoint(p_geometry   IN MDSYS.SDO_Geometry,
                        p_point      IN &&defaultSchema..T_Vertex,
                        p_position   IN Number )
    Return MDSYS.SDO_Geometry Deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : SDO_VertexUpdate
  * @precis     : Replace all points of geometry with new point where they match (including Z and M)
  * @version    : 1.0
  * @usage      : FUNCTION SDO_VertexUpdate(p_geometry in mdsys.sdo_geometry,
  *                                         p_old_point in mdsys.vertex_type,
  *                                         p_new_point in mdsys.vertex_type )
  *                 RETURN mdsys.sdo_geometry DETERMINISTIC;
  * @param      : p_geometry  : mdsys.sdo_geometry : Original geometry object
  * @param      : p_old_point : mdsys.vertex_type : Actual point coordinates of an existing point
  * @param      : p_new_point : mdsys.vertex_type : Actual point coordinates of replacement point
  * @return     : mdsys.sdo_geometry : input geometry with changed point.
  * @history    : Simon Greener - February 2009 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function SDO_VertexUpdate(p_geometry  IN MDSYS.SDO_Geometry,
                            p_old_point IN MDSYS.Vertex_Type,
                            p_new_point IN MDSYS.Vertex_Type)
    Return MDSYS.SDO_Geometry Deterministic;
  Function SDO_VertexUpdate(p_geometry  IN MDSYS.SDO_Geometry,
                            p_old_point IN &&defaultSchema..T_Vertex,
                            p_new_point IN &&defaultSchema..T_Vertex)
    Return MDSYS.SDO_Geometry Deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : Fix_Ordinates
  * @precis     : Allows calculations expressed as formula to change the ordinates of an SDO_Geometry
  * @version    : 1.0
  * @usage      : FUNCTION Fix_Ordinates(p_geometry   in mdsys.sdo_geometry,
  *                                      p_x_formula in varchar2,
  *                                      p_y_formula in varchar2,
  *                                      p_z_formula in varchar2 := null,
  *                                      p_w_formula in varchar2 := null)
  *                 RETURN mdsys.sdo_geometry DETERMINISTIC;
  * @description: The formula may reference the ordinates of the geometry via the columns X, Y, Z and W
  *               (the T_Vertex fields produced by SDO_Util.GetVertices function) keywords. These
  *               keywords can be referred to multiple times in a formula (see
  *               'ROUND ( z / ( z * dbms_random.value(1,10) ), 3 )' in the example that processes a 3D linestring below).
  *               Since the formula are applied via SQL even Oracle intrinsic columns like ROWNUM
  *               can be used (see '(rownum * w)' below). One can also use any Oracle function,
  *               eg RANDOM: this includes functions in packages such as DBMS_RANDOM
  *               eg 'ROUND ( Y * dbms_random.value ( 1,1000) ,3 )') as well.
  * @param      : p_geometry  : mdsys.sdo_geometry : Original geometry object
  * @param      : p_x_formula : varchar2 : Mathematical formula to be applied to X ordinate
  * @param      : p_y_formula : varchar2 : Mathematical formula to be applied to Y ordinate
  * @param      : p_z_formula : varchar2 : Mathematical formula to be applied to Z ordinate
  * @param      : p_w_formula : varchar2 : Mathematical formula to be applied to W/M ordinate
  * @return     : mdsys.sdo_geometry : input geometry with modified ordiantes
  * @history    : Simon Greener - February 2009 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function fix_ordinates(p_geometry in mdsys.sdo_geometry,
                         p_x_formula in varchar2,
                         p_y_formula in varchar2,
                         p_z_formula in varchar2 := null,
                         p_w_formula in varchar2 := null)
    Return mdsys.SDO_GEOMETRY Deterministic;

  Function Append(p_geom_1 in mdsys.sdo_geometry,
	                p_geom_2 in mdsys.sdo_geometry )
    Return mdsys.sdo_geometry deterministic;

  Function Concat_Lines(p_geom_1 in mdsys.sdo_geometry,
	                      p_geom_2 in mdsys.sdo_geometry )
    Return mdsys.sdo_geometry deterministic;

 /** ----------------------------------------------------------------------------------------
  * @function    : Extend
  * @precis      : Shortens or increases length of single linestring by desired amount.
  * @description : To extend a linestring provide a positive number. The linestring
  *                will be extended by taking the bearing of the first/last vector in the linestring
  *                and extending it by the desired amount. Providing START for the p_end parameter
  *                will cause the linestring to be ended at its beginning only; END ensures the
  *                extension occurs from the end of the linestring; BOTH ensures extension occurs at
  *                both ends. Providing a negative extension value will cause the linestring to shrink
  *                from either START, END or BOTH ends. If vertices are met when shrink the linestring
  *                within the distance to be shrunk the vertices will be removed.
  * @version     : 1.0
  * @usage      : FUNCTION get_point( p_geom      in mdsys.sdo_geometry,
  *                                   p_extension in number,
  *                                   p_tolerance in number,
  *                                   p_end       in varchar2 default 'START' )
  *                 RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;
  * @param      : p_geom      : MDSY.SDO_GEOMETRY : Geometry
  * @param      : p_extension : number   : The value to extend or shrink (-ve) the linesting
  * @param      : p_tolerance : number   : Standard Oracle diminfo tolerance.
  * @param      : p_end       : VARCHAR2 : START, END or BOTH
  * @history    : Simon Greener - July 2009 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  function Extend( p_geom      in mdsys.sdo_geometry,
                   p_extension in number,
                   p_tolerance in number,
                   p_end       in varchar2 default 'START' )
    return mdsys.sdo_geometry deterministic;

 /** ----------------------------------------------------------------------------------------
  * @function    : SwapOrdinates
  * @precis      : Allows for swapping ordinate pairs in a geometry.
  * @description : Sometimes the ordinates of a geometry can be swapped such as latitude for X
  *                and Longitude for Y when it should be reversed. This function allows for the
  *                swapping of pairs of ordinates controlled by the p_pair parameter.
  * @version     : 1.0
  * @usage       : Function SwapOrdinates( p_geom in mdsys.sdo_geometry,
  *                                        p_pair in varchar default 'XY' )
  *                  RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;
  * @param      : p_geom : MDSYS.SDO_GEOMETRY : Geometry
  * @param      : p_pair : varchar2  : The ordinate pair to swap = XY, XZ, XM, YZ, YM or ZM
  * @return     : mdsys.sdo_geometry : changed geometry
  * @history    : Simon Greener - Aug 2009 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function SwapOrdinates( p_geom in mdsys.sdo_geometry,
                          p_pair in varchar2 default 'XY' /* Can be XY, XZ, XM, YZ, YM, ZM */ )
    return mdsys.sdo_geometry deterministic;

  /*********************************************************************************
  * @function    : TokenAggregator
  * @precis      : A string aggregator.
  * @description : Takes a set of strings an aggregates/appends them using supplied separator
  * @example     : SELECT TokenAggregator(CAST(COLLECT(to_char(l.lineid)) AS t_Tokens)) AS lineids
  *                  FROM test_lines_large_set l;
  * @param       : p_tokenSet  : The strings to be aggregated.
  * @param       : p_separator : The character that is placed between each token string.
  * @requires    : t_Tokens type to be declared.
  * @history     : Simon Greener - June 2011 - Original coding
  **/
  Function TokenAggregator(p_tokenSet  IN  &&defaultSchema..t_Tokens,
                           p_delimiter IN  VarChar2 DEFAULT ',')
    Return VarChar2 Deterministic;

  /*********************************************************************************
  * @function    : ConcatLines
  * @precis      : A geometry linestring aggregator.
  * @description : Takes a set of linestrings and aggregates them into a single geoemtry
  * @example     : SELECT concatLines(CAST(COLLECT(a.geom) AS t_geometrySet)) AS lines
  *                  FROM test_lines_large_set l;
  * @param       : p_lines  : t_geometrySet : The lines to be aggregated.
  * @requires    : t_GeometrySet type to be declared.
  * @history     : Simon Greener - June 2011 - Original coding
  **/
  Function concatLines(p_lines IN &&defaultSchema..GEOM.t_geometrySet)
    Return mdsys.sdo_geometry deterministic;

End geom;
/
show errors

Prompt --------------------------000000000000000000000-------------------------

CREATE OR REPLACE PACKAGE BODY Geom
AS

  c_module_name          CONSTANT varchar2(256) := 'Geom';

  Type t_ADFDimensions Is Varray(5) Of varchar2(12);
  v_ADFDimensions        t_ADFDimensions;   -- Instantiated in Begin/End section for package body itself

  Type t_ADFElementList Is Table Of varchar2(255) index by binary_integer;
  v_ADFSDOGeometries     t_ADFElementList;  -- Instantiated in Begin/End section for package body itself
  v_ADFElements          t_ADFElementList;  -- Instantiated in Begin/End section for package body itself

  Function InitializeVertexType
    return mdsys.vertex_type deterministic
  is
  begin
     return mdsys.sdo_util.getVertices(mdsys.sdo_geometry(4001,null,null,mdsys.sdo_elem_info_array(1,1,1),mdsys.sdo_ordinate_array(NULL,NULL,NULL,NULL)))(1);
  End InitializeVertexType;

  Function Generate_Series(p_start pls_integer,
                           p_end   pls_integer,
                           p_step  pls_integer )
       Return &&defaultSchema..GEOM.t_integers Pipelined
  As
    v_i PLS_INTEGER := p_start;
  Begin
     while ( v_i <= p_end) Loop
       PIPE ROW ( v_i );
       v_i := v_i + p_step;
     End Loop;
     Return;
  End Generate_Series;

 /**
 * SDO_Element_Array handlers
 **/
  Function GetElemInfo(p_geometry in mdsys.sdo_geometry)
    Return &&defaultSchema..T_ElemInfoSet pipelined
  Is
    v_elements  number;
  Begin
    If ( p_geometry is not null ) Then
      v_elements := ( ( p_geometry.sdo_elem_info.COUNT / 3 ) - 1 );
      <<element_extraction>>
      for v_i IN 0 .. v_elements LOOP
         PIPE ROW ( &&defaultSchema..T_ElemInfo(
                      p_geometry.sdo_elem_info(v_i * 3 + 1),
                      p_geometry.sdo_elem_info(v_i * 3 + 2),
                      p_geometry.sdo_elem_info(v_i * 3 + 3) ) );
        end loop element_extraction;
    End If;
    Return;
  End GetElemInfo;

  Function GetElemInfoSet(p_geometry in mdsys.sdo_geometry)
    Return &&defaultSchema..T_ElemInfoSet
  Is
    v_elements  number;
    v_elem_info &&defaultSchema..T_ElemInfoSet := new &&defaultSchema..T_ElemInfoSet();
  Begin
    If ( p_geometry is not null And p_geometry.sdo_elem_info is not null) Then
      v_elements := ( ( p_geometry.sdo_elem_info.COUNT / 3 ) - 1 );
      v_elem_info.EXTEND(v_elements);
      <<element_extraction>>
      for v_i IN 0 .. v_elements LOOP
         v_elem_info(v_i) := new &&defaultSchema..T_ElemInfo(
                                      p_geometry.sdo_elem_info(v_i * 3 + 1),
                                      p_geometry.sdo_elem_info(v_i * 3 + 2),
                                      p_geometry.sdo_elem_info(v_i * 3 + 3) );
        end loop element_extraction;
    End If;
    Return v_elem_info;
  End GetElemInfoSet;

  Function GetElemInfoAt(
    p_geometry in mdsys.sdo_geometry,
    p_element  in pls_integer)
    Return &&defaultSchema..T_ElemInfo
  Is
    v_elements  number;
  Begin
    If ( p_geometry is not null ) Then
      v_elements := ( ( p_geometry.sdo_elem_info.COUNT / 3 ) - 1 );
      <<element_extraction>>
      for v_i IN 0 .. v_elements LOOP
         if ( (v_i+1) = p_element ) then
             RETURN &&defaultSchema..T_ElemInfo(
                          p_geometry.sdo_elem_info(v_i * 3 + 1),
                          p_geometry.sdo_elem_info(v_i * 3 + 2),
                          p_geometry.sdo_elem_info(v_i * 3 + 3) );
        End If;
        end loop element_extraction;
    End If;
    Return NULL;
  End GetElemInfoAt;

  Function GetETypeAt(
    p_geometry  in mdsys.sdo_geometry,
    p_element   in pls_integer)
    Return pls_integer
  Is
    v_num_elems number;
  Begin
    If ( p_geometry is not null ) Then
      v_num_elems := MDSYS.SDO_UTIL.GETNUMELEM(p_geometry);
      <<element_extraction>>
      for v_i IN 0 .. v_num_elems LOOP
         if ( (v_i+1) = p_element ) then
            RETURN p_geometry.sdo_elem_info(v_i * 3 + 2);
        End If;
        end loop element_extraction;
    End If;
    Return NULL;
  End GetETypeAt;

  Function GetNumElem( p_geometry IN mdsys.sdo_geometry )
    return number
  Is
    TYPE t_elemCursor IS REF CURSOR;
    c_elems                t_elemCursor;
    v_num_elems            number := 0;
    v_rin                  number := 0;
    v_compound_element     boolean := FALSE;
    v_compound_element_end number := 0;
  Begin
    If ( p_geometry is not null ) Then
      If ( p_geometry.sdo_elem_info is not null ) Then
        If ( DBMS_DB_VERSION.VERSION < 10 ) Then
          -- Get count of all elements
          OPEN c_elems FOR
            'SELECT rownum as rin,
                    case when i.etype in (4,5,1005,2005) then i.interpretation + rownum else 0 end as celem
               FROM (SELECT rownum as id,
                            e.interpretation,
                            e.etype,
                            e.offset
                      FROM TABLE(&&defaultSchema..GEOM.GetElemInfo(:1)) e
                         ) i'
            USING p_geometry;
          LOOP
            FETCH c_elems INTO v_rin, v_compound_element_end;
            EXIT WHEN c_elems%NOTFOUND;
            If ( v_compound_element_end <> 0 ) Then
              v_compound_element := TRUE;
              v_num_elems := v_num_elems + 1;
            Else
              If ( v_compound_element ) Then
                 If ( v_compound_element_end = v_rin ) Then
                    v_compound_element := FALSE;
                 End If;
              Else
                 v_num_elems := v_num_elems + 1;
              End If;
            End If;
          END LOOP;
        Else
          EXECUTE IMMEDIATE 'SELECT mdsys.sdo_util.GetNumElem(:1) FROM DUAL' INTO v_num_elems USING p_geometry ;
        END IF;
      End If;
    End If;
    RETURN v_num_elems;
  End GetNumElem;

  Procedure ADD_Element( p_SDO_Elem_Info  in out nocopy mdsys.sdo_elem_info_array,
                         p_Offset         in number,
                         p_Etype          in number,
                         p_Interpretation in number )
    IS
  Begin
    p_SDO_Elem_Info.extend(3);
    p_SDO_Elem_Info(p_SDO_Elem_Info.count-2) := p_Offset;
    p_SDO_Elem_Info(p_SDO_Elem_Info.count-1) := p_Etype;
    p_SDO_Elem_Info(p_SDO_Elem_Info.count  ) := p_Interpretation;
  END ADD_Element;

  Procedure ADD_Element( p_SDO_Elem_Info  in out nocopy mdsys.sdo_elem_info_array,
                         p_Elem_Info      in &&defaultSchema..T_ElemInfo )
    IS
  Begin
    p_SDO_Elem_Info.extend(3);
    p_SDO_Elem_Info(p_SDO_Elem_Info.count-2) := p_Elem_Info.offset;
    p_SDO_Elem_Info(p_SDO_Elem_Info.count-1) := p_Elem_Info.etype;
    p_SDO_Elem_Info(p_SDO_Elem_Info.count  ) := p_Elem_Info.interpretation;
  END ADD_Element;

   /** Some useful utility functions
   **/
  Function isCompoundElement(p_elem_type in number)
    return boolean
  Is
  Begin
    Return ( p_elem_type in (4,5,1005,2005) );
  End isCompoundElement;

  Function numCompoundElements(p_geometry in sdo_geometry)
    return integer
  Is
    v_etype           pls_integer;
    v_elements        pls_integer := 0;
  Begin
    If ( p_geometry.get_gtype() in (1,2,5,6) ) Then
      return 0;
    End If;
    v_elements := ( ( p_geometry.sdo_elem_info.COUNT / 3 ) - 1 );
    <<element_extraction>>
    FOR v_i IN 0 .. v_elements LOOP
      v_etype          := p_geometry.sdo_elem_info(v_i * 3 + 2);
      If ( v_etype in (1005,2005) ) Then
         Return 1;
      End If;
    END LOOP element_extraction;
    Return 0;
  End numCompoundElements;

  Function hasCircularArcs(p_elem_info in mdsys.sdo_elem_info_array)
    return boolean
  Is
     v_elements  number;
  Begin
     v_elements := ( ( p_elem_info.COUNT / 3 ) - 1 );
     <<element_extraction>>
     for v_i IN 0 .. v_elements LOOP
        if ( ( /* etype */         p_elem_info(v_i * 3 + 2) = 2 AND
               /* interpretation*/ p_elem_info(v_i * 3 + 3) = 2 )
             OR
             ( /* etype */         p_elem_info(v_i * 3 + 2) in (1003,2003) AND
               /* interpretation*/ p_elem_info(v_i * 3 + 3) IN (2,4) ) ) then
               return true;
        end If;
     end loop element_extraction;
     return false;
  End hasCircularArcs;

  Function isCompound(p_elem_info in mdsys.sdo_elem_info_array)
    return integer
  IS
  Begin
    return case when &&defaultSchema..GEOM.hasCircularArcs(p_elem_info) then 1 else 0 end;
  End isCompound;

  Function hasArc(p_elem_info in mdsys.sdo_elem_info_array)
    return integer
  IS
  Begin
    return case when &&defaultSchema..GEOM.hasCircularArcs(p_elem_info) then 1 else 0 end;
  End hasArc;

  Function hasRectangles(p_elem_info in mdsys.sdo_elem_info_array)
    return boolean
  Is
    v_etype           pls_integer;
    v_interpretation  pls_integer;
    v_elements        pls_integer := 0;
    v_rectangle_count number := 0;
  Begin
    If ( p_elem_info is not null ) Then
      v_elements := ( ( p_elem_info.COUNT / 3 ) - 1 );
      <<element_extraction>>
      FOR v_i IN 0 .. v_elements LOOP
        v_etype          := p_elem_info(v_i * 3 + 2);
        v_interpretation := p_elem_info(v_i * 3 + 3);
        If ( ( v_etype in (1003,2003) AND
               v_interpretation = 3 ) ) Then
           v_rectangle_count := v_rectangle_count + 1;
        End If;
      END LOOP element_extraction;
    End If;
     Return case when v_rectangle_count > 0 then true else false end;
  End hasRectangles;

  Function numOptimizedRectangles(p_geometry in sdo_geometry)
    return integer
  Is
    v_etype           pls_integer;
    v_interpretation  pls_integer;
    v_elements        pls_integer := 0;
    v_rectangle_count number := 0;
  Begin
    If ( p_geometry.get_gtype() in (1,2,5,6) ) Then
      return 0;
    End If;
    v_elements := ( ( p_geometry.sdo_elem_info.COUNT / 3 ) - 1 );
    <<element_extraction>>
    FOR v_i IN 0 .. v_elements LOOP
      v_etype          := p_geometry.sdo_elem_info(v_i * 3 + 2);
      v_interpretation := p_geometry.sdo_elem_info(v_i * 3 + 3);
      If ( ( v_etype in (1003,2003) AND
             v_interpretation = 3 ) ) Then
         v_rectangle_count := v_rectangle_count + 1;
      End If;
    END LOOP element_extraction;
    Return v_rectangle_count;
  End numOptimizedRectangles;

  Function isRectangle( p_elem_info in mdsys.sdo_elem_info_array  )
    Return integer
  Is
  Begin
     return case when &&defaultSchema..GEOM.hasRectangles(p_elem_info) then 1 else 0 end;
  End isRectangle;

  Function Rectangle2Polygon(p_geometry in mdsys.sdo_geometry)
    return mdsys.sdo_geometry deterministic
  As
    v_dims             pls_integer;
    v_vertices         mdsys.vertex_set_type;
    v_ordinates        mdsys.sdo_ordinate_array  := new mdsys.sdo_ordinate_array(null);
    v_elem_info        mdsys.sdo_elem_info_array := new mdsys.sdo_elem_info_array(null);
    v_ord_count        pls_integer;
    v_num_elements     pls_integer;
    v_num_sub_elements pls_integer;
    v_element          sdo_geometry;

    Procedure processElement(p_geometry  in sdo_geometry,
                             p_ordinates in out nocopy mdsys.sdo_ordinate_array,
                             p_elem_info in out nocopy mdsys.sdo_elem_info_array)
    As
      v_vertices         mdsys.vertex_set_type;
      v_interpretation   pls_integer;
      v_etype            pls_integer;
      v_start_coord      mdsys.vertex_type;
      v_end_coord        mdsys.vertex_type;
      v_temp_coord       mdsys.vertex_type;
      v_num_sub_elements pls_integer;
      v_sub_element      sdo_geometry;
      v_dims             pls_integer;
    Begin
      -- Can only be called if p_geometry contains at least one optimized rectangle.
      -- Count sub elements
      v_dims := p_geometry.get_dims();
      v_num_sub_elements := (p_geometry.sdo_elem_info.COUNT / 3);
      for i in 1..v_num_sub_elements loop
        dbms_output.put_line('...... Processing Sub Element ' || i || ' of ' || v_num_sub_elements);
        v_sub_element    := sdo_util.extract(p_geometry,1,i);
        v_vertices       := sdo_util.getVertices(v_sub_element);
        v_interpretation := v_sub_element.sdo_elem_info(3);
        v_etype          := p_geometry.sdo_elem_info((i-1)*3+2);  /* Use Original etype 2003 for holes as extract turns holes into 1003 */
        -- Update elem_info_array
        p_elem_info.EXTEND(3);
        p_elem_info(p_elem_info.COUNT-2) := v_ordinates.COUNT + 1;
        -- If sub element not an optimized rectangle copy it through
        If ( v_interpretation <> 3 ) Then
          dbms_output.put_line('........ Skipping ' || i || ' sub element as is not optimized rectangle.');
          -- Copy through elem_info and ordinates
          p_elem_info(p_elem_info.COUNT-1) := v_sub_element.sdo_elem_info(2);
          p_elem_info(p_elem_info.COUNT)   := v_sub_element.sdo_elem_info(3);
          -- Now copy all ordinates
          For i in 1..v_vertices.COUNT Loop
            ADD_Coordinate( p_ordinates, v_dims, v_vertices(i).x, v_vertices(i).y, v_vertices(i).z, v_vertices(i).w );
          End Loop;
          Continue;
        End If;
        dbms_output.put_line('........ Converting Processing Found Optimized Rectangle.');
        -- Change to optimized rectangle in to a 5 vertex polygon
        p_elem_info(p_elem_info.COUNT-1) := case when i=1 then v_sub_element.sdo_elem_info(2) else 2003 end;
        p_elem_info(p_elem_info.COUNT)   := 1;
        v_start_coord := v_vertices(1);
        v_end_coord   := v_vertices(2);
        -- Check inverted only if first element
        if ( i = 1 ) Then
          v_temp_coord    := v_vertices(1);
          v_temp_coord.x  := least(v_start_coord.x,v_end_coord.x);
          v_temp_coord.y  := least(v_start_coord.y,v_end_coord.y);
          v_end_coord.x   := greatest(v_start_coord.x,v_end_coord.x);
          v_end_coord.y   := greatest(v_start_coord.y,v_end_coord.y);
          v_start_coord.x := v_temp_coord.x;
          v_start_coord.y := v_temp_coord.y;
        End If;
        -- First coordinate
        ADD_Coordinate( p_ordinates, v_dims, v_start_coord.x, v_start_coord.y, v_start_coord.z, v_start_coord.w );
        -- Second coordinate
        If ( v_etype = 1003 ) Then
          ADD_Coordinate(p_ordinates,v_dims,v_end_coord.x,v_start_coord.y,(v_start_coord.z + v_end_coord.z) /2, v_start_coord.w);
        Else
          ADD_Coordinate(p_ordinates,v_dims,
                       v_start_coord.x,
                       v_end_coord.y,
                       (v_start_coord.z + v_end_coord.z) /2,
                       (v_end_coord.w - v_start_coord.w) * ((v_end_coord.x - v_start_coord.x) /
                       ((v_end_coord.x - v_start_coord.x) + (v_end_coord.y - v_start_coord.y)) ));
        End If;
        -- 3rd or middle coordinate
        ADD_Coordinate(p_ordinates,v_dims,v_end_coord.x,v_end_coord.y,v_end_coord.z,v_end_coord.w);
        -- 4th coordinate
        If ( v_etype = 1003 ) Then
          ADD_Coordinate(p_ordinates,v_dims,v_start_coord.x,v_end_coord.y,(v_start_coord.z + v_end_coord.z) /2,v_start_coord.w);
        Else
          ADD_Coordinate(p_ordinates,v_dims,v_end_coord.x,v_start_coord.y,(v_start_coord.z + v_end_coord.z) /2,
              (v_end_coord.w - v_start_coord.w) * ((v_end_coord.x - v_start_coord.x) /
             ((v_end_coord.x - v_start_coord.x) + (v_end_coord.y - v_start_coord.y)) ));
        End If;
        -- Last coordinate
        ADD_Coordinate(p_ordinates,v_dims,v_start_coord.x,v_start_coord.y,v_start_coord.z,v_start_coord.w);
        dbms_output.put_line('........ Finishing Converting Optimized Rectangle.');
      End Loop;
    End processElement;

  Begin
      If ( p_geometry is null ) Then
        return p_geometry;
      End If;
      If ( p_geometry.get_gtype() not in (3,7) ) Then
        return p_geometry;
      End If;
      If ( numOptimizedRectangles(p_geometry) = 0 ) Then
        dbms_output.put_line('p_geometry does not have optimized rectangles.');
        return p_geometry;
      End If;
      If ( numCompoundElements(p_geometry) <> 0 ) Then
        dbms_output.put_line('p_geometry has compound elements.');
        return p_geometry;
      End If;
      v_ordinates.DELETE;
      v_elem_info.DELETE;
      v_dims         := p_geometry.get_dims();
      v_num_elements := mdsys.sdo_util.getNumElem(p_geometry);
      dbms_output.put_line('p_geometry has ' || v_num_elements || ' parts/elements.');
      FOR elem IN 1..v_num_elements loop
         v_element := mdsys.sdo_util.Extract(p_geometry,elem,0);
         dbms_output.put_line('... Extracted part/element ' || elem || ' has ' || numOptimizedRectangles(v_element) || ' optimized rectangles.');
         If ( numOptimizedRectangles(v_element) <> 0 ) Then
           processElement(v_element,v_ordinates,v_elem_info);
         Else
           -- Append
          dbms_output.put_line('........ Appending non-optimized rectangle geometry to output geometry ');
          v_num_sub_elements := (v_element.sdo_elem_info.COUNT / 3);
          v_ord_count := v_ordinates.count;
          for i in 1..v_num_sub_elements loop
            v_elem_info.EXTEND(3);
            v_elem_info(v_elem_info.COUNT-2) := case when i=1 then v_ord_count+1 else v_element.sdo_elem_info(i) + v_ord_count end;
            v_ord_count := v_elem_info(v_elem_info.COUNT-2);
            v_elem_info(v_elem_info.COUNT-1) := v_element.sdo_elem_info(i+1);
            v_elem_info(v_elem_info.COUNT  ) := v_element.sdo_elem_info(i+2);
          End Loop;
          v_vertices       := sdo_util.getVertices(v_element);
          -- Now copy all ordinates
          For i in 1..v_vertices.COUNT Loop
            ADD_Coordinate( v_ordinates, v_dims, v_vertices(i).x, v_vertices(i).y, v_vertices(i).z, v_vertices(i).w );
          End Loop;
         End If;
      END LOOP;
      return mdsys.sdo_geometry(p_geometry.sdo_gtype,p_geometry.sdo_srid,null,v_elem_info,v_ordinates);
  End Rectangle2Polygon;

  Function Polygon2Rectangle( p_geometry  in mdsys.sdo_geometry,
                              p_tolerance in number default 0.005 )
    Return mdsys.sdo_geometry
  AS
     v_vertices        mdsys.vertex_set_type;
     v_ords            mdsys.sdo_ordinate_array :=  new mdsys.sdo_ordinate_array(null);
     v_num_elems       pls_integer;
     v_actual_etype    pls_integer;
     v_ring_elem_count pls_integer := 0;
     v_ring            mdsys.sdo_geometry;
     v_num_rings       pls_integer;
     v_out_geom        mdsys.sdo_geometry;
  BEGIN
     IF ( p_geometry is null ) THEN
        RETURN p_geometry;
     END IF;
     -- Is polygon?
     IF ( p_geometry.get_gtype() not in (3,7) ) THEN
        RETURN p_geometry;
     END IF;

     v_num_elems := MDSYS.SDO_UTIL.GETNUMELEM(p_geometry);
     <<all_elements>>
     FOR v_elem_no IN 1..v_num_elems LOOP
         -- Need to process and check all inner rings
         --
         -- Process all rings in the extracted single - 2003 - polygon
         v_num_rings := GetNumRings(MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_elem_no),0);
         <<All_Rings>>
         FOR v_ring_no IN 1..v_num_rings LOOP
             v_ring := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_elem_no,v_ring_no);
             v_actual_etype := GetEtypeAt(p_geometry,(v_ring_elem_count+1));
             v_ring_elem_count := v_ring_elem_count + v_ring.sdo_elem_info.COUNT / 3;
             IF ( v_ring is not null ) THEN
               IF ( v_ring.sdo_elem_info(2) = 1003 AND
                    v_ring.sdo_elem_info(2) <> v_actual_etype ) THEN
                  -- Replace etype as Oracle extracts 2003 as 1003
                  v_ring.sdo_elem_info(2) := v_actual_etype;
               End If;
               v_vertices := mdsys.sdo_util.getVertices(v_ring);
               IF ( v_vertices.COUNT = 5 ) THEN
                 -- Do the five vertices form a rectangle?
                 -- inner product of two consequent vector must equals to zero
                 IF ( (v_vertices(1).x-v_vertices(2).x) * (v_vertices(2).x-v_vertices(3).x) +
                      (v_vertices(1).y-v_vertices(2).y) * (v_vertices(2).y-v_vertices(3).y) = 0 AND
                      (v_vertices(3).x-v_vertices(4).x) * (v_vertices(4).x-v_vertices(5).x) +
                      (v_vertices(3).y-v_vertices(4).y) * (v_vertices(4).y-v_vertices(5).y) = 0 ) THEN
                    v_ring.sdo_elem_info(1) := 1;
                    v_ring.sdo_elem_info(3) := 3;
                    v_ords.DELETE;
                    v_ords.EXTEND(4);
                    v_ords(1) := v_vertices(1).x;
                    v_ords(2) := v_vertices(1).y;
                    v_ords(3) := v_vertices(3).x;
                    v_ords(4) := v_vertices(3).y;
                    v_ring := mdsys.sdo_geometry(v_ring.sdo_gtype,
                                                 v_ring.sdo_srid,
                                                 v_ring.sdo_point,
                                                 v_ring.sdo_elem_info,
                                                 v_ords);
                 END IF;
               END IF;
               IF ( v_out_geom is null ) THEN
                 v_out_geom := v_ring;
               ELSE
                 v_out_geom := mdsys.sdo_util.APPEND(v_out_geom,v_ring);
               END IF;
             END IF;
         END LOOP All_Rings;
     END LOOP all_elements;
     RETURN mdsys.sdo_geometry(p_geometry.sdo_gtype,
                               p_geometry.sdo_srid,
                               p_geometry.sdo_point,
                               v_out_geom.sdo_elem_info,
                               v_out_geom.sdo_ordinates);
  END Polygon2Rectangle;

  Function st_multi(p_single_geometry in mdsys.sdo_geometry)
  return mdsys.sdo_geometry
  As
  Begin
    if ( p_single_geometry is null or p_single_geometry.get_gtype() in (4,5,6,7) ) Then
       return p_single_geometry;
    End If;
    return sdo_geometry(p_single_geometry.sdo_gtype+4,
                        p_single_geometry.sdo_srid,
                        null,
                        case when p_single_geometry.get_gtype()=1 and p_single_geometry.sdo_point is not null
                             then sdo_elem_info_array(1,1,1)
                             else p_single_geometry.sdo_elem_info
                         end,
                        case when p_single_geometry.get_gtype()=1 and p_single_geometry.sdo_point is not null
                             then case when p_single_geometry.get_dims()=2
                                       then sdo_ordinate_array(p_single_geometry.sdo_point.x,p_single_geometry.sdo_point.y)
                                       else sdo_ordinate_array(p_single_geometry.sdo_point.x,p_single_geometry.sdo_point.y,p_single_geometry.sdo_point.z)
                                  end
                             else p_single_geometry.sdo_ordinates
                         end);
  End ST_Multi;

  Function isMeasured( p_gtype in number )
    return boolean
  is
  Begin
    Return CASE WHEN MOD(trunc(p_gtype/100),10) = 0
                THEN False
                ELSE True
             END;
  End isMeasured;

  Function isOrientedPoint( p_elem_info in mdsys.sdo_elem_info_array)
    return integer
  is
  Begin
    /* Single Oriented Point
    // Sdo_Elem_Info = (1,1,1, 3,1,0), SDO_ORDINATE_ARRAY(12,14, 0.3,0.2)));
    // The Final 1,0 In 3,1,0 Indicates That This Is An Oriented Point.
    //
    // Multi Oriented Point
    // Sdo_Elem_Info_Array(1,1,1, 3,1,0, 5,1,1, 7,1,0), Sdo_Ordinate_Array(12,14, 0.3,0.2, 12,10, -1,-1)));
    */
    If ( P_Elem_Info Is Null ) Then
       Return 0;
    Elsif ( P_Elem_Info.Count >= 6 ) Then
       Return case when ( P_Elem_Info(2) = 1 ) /* Point */          And
                        ( P_Elem_Info(3) = 1 ) /* Single Point */   And
                        ( P_Elem_Info(5) = 1 ) /* Oriented Point */ And
                        ( P_Elem_Info(6) = 0 )
                   then 1
                   else 0
              end;
    Else
       Return 0;
    End If;
  End isOrientedPoint;

  Function Orientation(P_Oriented_Point In Mdsys.Sdo_Geometry)
    Return number
  as
    v_vertices mdsys.vertex_set_type;
    v_dims     number;
  begin
    If (p_oriented_point is null) then
      return null;
    end if;
    if ( &&defaultSchema..geom.isOrientedPoint(p_oriented_point.sdo_elem_info)=0) Then
      return null;
    End If;
    v_vertices := mdsys.sdo_util.getVertices(p_oriented_point);
    If (v_vertices is null or v_vertices.count != 2) then
      return null;
    End If;
    v_dims := p_oriented_point.get_dims();
    return &&defaultSchema..cogo.bearing(v_vertices(1).x,
                                v_vertices(1).y,
                                v_vertices(1).x + v_vertices(2).x,
                                V_Vertices(1).Y + V_Vertices(2).Y);
  end orientation;

  Function Point2oriented(P_Point      In Mdsys.Sdo_Geometry,
                          P_Degrees    In Number,
                          P_Dec_Digits In Integer Default 5)
    Return mdsys.sdo_geometry
  as
    V_Dx         Number;
    V_Dy         Number;
    V_Dec_Digits Integer := Nvl(P_Dec_Digits,5);
    v_vertices   mdsys.vertex_set_type;
  begin
    if (p_point is null or p_point.get_gtype() != 1) Then
       return p_point;
    End If;
    -- p_degrees is bearing clockwise from north.
    V_Dx := Round(Sin(Cogo.Radians(P_Degrees)),V_Dec_Digits);
    v_dy := Round(cos(cogo.radians(p_degrees)),v_dec_digits);
    v_vertices := mdsys.sdo_util.getVertices(p_point);
    return mdsys.sdo_geometry(p_point.sdo_gtype,
                              p_point.sdo_srid,
                              null,
                              mdsys.sdo_elem_info_array(1,1,1, p_point.get_dims()+1,1,0),
                              case p_point.get_dims()
                                   When 2 Then Mdsys.Sdo_Ordinate_Array(V_Vertices(1).X,V_Vertices(1).Y,V_Dx,V_Dy)
                                   When 3 Then Mdsys.Sdo_Ordinate_Array(V_Vertices(1).X,V_Vertices(1).Y,V_Vertices(1).Z,V_Dx,V_Dy,V_Vertices(1).Z)
                                   when 4 then mdsys.sdo_ordinate_array(v_vertices(1).x,v_vertices(1).Y,v_vertices(1).z,v_vertices(1).w,v_dx,v_dy,v_vertices(1).z,v_vertices(1).w)
                                   else mdsys.sdo_ordinate_array(v_vertices(1).x,v_vertices(1).Y,v_dx,v_dy)
                               end
                              );
  End Point2oriented;

  Function GetDimensions( p_gtype in number )
    return integer
  Is
  Begin
    return TRUNC(p_gtype/1000,0);
  End GetDimensions;

  Function GetShortGType( p_gtype in number )
    return integer
  Is
  Begin
    return MOD(p_gtype,10);
  End GetShortGType;

  /**
  * SDO_Ordinate_Array handlers
  **/

  PROCEDURE ADD_Coordinate( p_ordinates  in out nocopy mdsys.sdo_ordinate_array,
                            p_dim        in number,
                            p_x_coord    in number,
                            p_y_coord    in number,
                            p_z_coord    in number,
                            p_m_coord    in number,
                            p_measured   in boolean := false)
    IS
      Function Duplicate
        Return Boolean
      Is
      Begin
        /** DEBUG
	if not (p_ordinates is null or p_ordinates.count = 0 ) Then
          dbms_output.put( p_dim || ' -> ' || p_ordinates(p_ordinates.COUNT-1) || ' = ' ||  p_x_coord || ' AND ' || p_ordinates(p_ordinates.COUNT) || ' = ' || p_y_coord );
          dbms_output.put_line( case when (( p_ordinates(p_ordinates.COUNT) = p_y_coord
                                     AND
                                     p_ordinates(p_ordinates.COUNT-1) = p_x_coord ) ) then 'TRUE' Else 'False' end );
        end if;
        **/
        Return case when p_ordinates is null or p_ordinates.count = 0
                    then False
                    Else case p_dim
                              when 2
                              then ( p_ordinates(p_ordinates.COUNT)   = p_y_coord
                                     AND
                                     p_ordinates(p_ordinates.COUNT-1) = p_x_coord )
                              when 3
                              then ( p_ordinates(p_ordinates.COUNT)   =  case when p_measured then p_m_coord else p_z_coord end
                                     AND
                                     p_ordinates(p_ordinates.COUNT-1) = p_y_coord
                                     AND
                                     p_ordinates(p_ordinates.COUNT-2) = p_x_coord )
                              when 4
                              then ( p_ordinates(p_ordinates.COUNT)   = p_m_coord
                                     AND
                                     p_ordinates(p_ordinates.COUNT-1) = p_z_coord
                                     AND
                                     p_ordinates(p_ordinates.COUNT-2) = p_y_coord
                                     AND
                                     p_ordinates(p_ordinates.COUNT-3) = p_x_coord )
                          end
                  End;
      End Duplicate;

  Begin
    If Not Duplicate() Then
      IF ( p_dim >= 2 ) Then
        p_ordinates.extend(2);
        p_ordinates(p_ordinates.count-1) := p_x_coord;
        p_ordinates(p_ordinates.count  ) := p_y_coord;
      END IF;
      IF ( p_dim >= 3 ) Then
        p_ordinates.extend(1);
        p_ordinates(p_ordinates.count)   := case when p_dim = 3 And p_measured
                                                 then p_m_coord
                                                 else p_z_coord
                                            end;
      END IF;
      IF ( p_dim = 4 ) Then
        p_ordinates.extend(1);
        p_ordinates(p_ordinates.count)   := p_m_coord;
      END IF;
    End If;
  END ADD_Coordinate;

  PROCEDURE ADD_Coordinate( p_ordinates  in out nocopy mdsys.sdo_ordinate_array,
                            p_dim        in number,
                            p_coord      in &&defaultSchema..ST_Point,
                            p_measured   in boolean := false)
  Is
  Begin
    ADD_Coordinate( p_ordinates, p_dim, p_coord.x, p_coord.y, p_coord.z, p_coord.m, p_measured);
  END Add_Coordinate;

  PROCEDURE ADD_Coordinate( p_ordinates  in out nocopy mdsys.sdo_ordinate_array,
                            p_dim        in number,
                            p_coord      in &&defaultSchema..T_Vertex,
                            p_measured   in boolean := false)
  Is
  Begin
    ADD_Coordinate( p_ordinates, p_dim, p_coord.x, p_coord.y, p_coord.z, p_coord.w, p_measured);
  END Add_Coordinate;

  PROCEDURE ADD_Coordinate( p_ordinates  in out nocopy mdsys.sdo_ordinate_array,
                            p_dim        in number,
                            p_coord      in mdsys.vertex_type,
                            p_measured   in boolean := false)
  Is
  Begin
    ADD_Coordinate( p_ordinates, p_dim, p_coord.x, p_coord.y, p_coord.z, p_coord.w, p_measured);
  END Add_Coordinate;

  PROCEDURE ADD_Coordinate( p_ordinates  in out nocopy mdsys.sdo_ordinate_array,
                            p_dim        in number,
                            p_coord      in mdsys.sdo_point_type,
                            p_measured   in boolean := false)
  Is
  Begin
    ADD_Coordinate( p_ordinates, p_dim, p_coord.x, p_coord.y, p_coord.z, NULL, p_measured);
  END Add_Coordinate;

  Function Generate_DimInfo(p_dims        in number,
                            p_X_tolerance in number,
                            p_Y_tolerance in number := NULL,
                            p_Z_tolerance in number := NULL)
    Return mdsys.sdo_dim_array
  As
    v_Y_tolerance number := NVL(p_Y_tolerance,p_X_tolerance);
    v_Z_tolerance number := NVL(p_Z_tolerance,p_X_tolerance);
  Begin
    return case when p_dims = 2
                then MDSYS.SDO_DIM_ARRAY(MDSYS.SDO_DIM_ELEMENT('X', &&defaultSchema..Constants.c_MinVal, &&defaultSchema..Constants.c_MaxVal, p_X_tolerance),
                                         MDSYS.SDO_DIM_ELEMENT('Y', &&defaultSchema..Constants.c_MinVal, &&defaultSchema..Constants.c_MaxVal, v_Y_tolerance))
                when p_dims = 3
                then MDSYS.SDO_DIM_ARRAY(MDSYS.SDO_DIM_ELEMENT('X', &&defaultSchema..Constants.c_MinVal, &&defaultSchema..Constants.c_MaxVal, p_X_tolerance),
                                         MDSYS.SDO_DIM_ELEMENT('Y', &&defaultSchema..Constants.c_MinVal, &&defaultSchema..Constants.c_MaxVal, v_Y_tolerance),
                                         MDSYS.SDO_DIM_ELEMENT('Z', &&defaultSchema..Constants.c_MinVal, &&defaultSchema..Constants.c_MaxVal, v_Z_tolerance))
                else NULL
            end;
  End Generate_DimInfo;

  Function GetNumRings( p_geometry  in mdsys.sdo_geometry,
                        p_ring_type in integer /* 0 = ALL; 1 = OUTER; 2 = INNER */ )
    Return Number
  Is
    v_elements   pls_integer := 0;
    v_ring_count pls_integer := 0;
    v_etype      pls_integer;
    v_ring_type  pls_integer := case when ( p_ring_type is null OR
                                            p_ring_type not in (0,1,2) )
                                     Then 0
                                     Else p_ring_type
                                 End;
  Begin
    If ( p_geometry is not null ) Then
      v_elements := ( ( p_geometry.sdo_elem_info.COUNT / 3 ) - 1 );
      <<element_extraction>>
      FOR v_i IN 0 .. v_elements LOOP
        v_etype := p_geometry.sdo_elem_info(v_i * 3 + 2);
        If ( ( v_etype in (1003,1005,2003,2005) and 0 = v_ring_type )
          OR ( v_etype in (1003,1005)           and 1 = v_ring_type )
          OR ( v_etype in (2003,2005)           and 2 = v_ring_type ) ) Then
           v_ring_count := v_ring_count + 1;
        End If;
      END LOOP element_extraction;
    End If;
    Return v_ring_count;
  End GetNumRings;

  Function GetNumRings( p_geometry  in mdsys.sdo_geometry )
    Return Number
  Is
  Begin
    Return &&defaultSchema..geom.GetNumRings(p_geometry,0);
  End GetNumRings;

  Function GetNumOuterRings( p_geometry  in mdsys.sdo_geometry )
    Return Number
  Is
  Begin
    Return &&defaultSchema..geom.GetNumRings(p_geometry,1);
  End GetNumOuterRings;

  Function GetNumInnerRings( p_geometry  in mdsys.sdo_geometry )
    Return Number
  Is
  Begin
    Return &&defaultSchema..Geom.GetNumRings(p_geometry,2);
  End GetNumInnerRings;

  Function Append(p_geom_1 in mdsys.sdo_geometry,
	          p_geom_2 in mdsys.sdo_geometry )
    Return mdsys.sdo_geometry
  Is
    v_geom mdsys.sdo_geometry;

    function append9( p_geom_1 in mdsys.sdo_geometry,
                      p_geom_2 in mdsys.sdo_geometry )
      return mdsys.sdo_geometry DETERMINISTIC
    as
      v_geom     mdsys.sdo_geometry;
      v_gtype_1  Number;
      v_gtype_2  Number;
      v_dims_1   Number;
      v_dims_2   Number;
      v_offset   Number;
    begin
      If ( p_geom_1 is null and p_geom_2 is null ) Then
        Return Null;
      ElsIf ( p_geom_1 is null ) Then
        Return p_geom_2;
      ElsIf ( p_geom_2 is null ) then
        Return p_geom_1;
      End If;
      If ( NVL(p_geom_1.sdo_srid,0) <> NVL(p_geom_2.sdo_srid,0) ) Then
        Raise_Application_Error(-20001,'SRIDs are different',True);
      End If;
      v_dims_1  := p_geom_1.Get_Dims();
      v_dims_2  := p_geom_2.Get_Dims();
      If ( v_dims_1 <> v_dims_2 ) Then
        Raise_Application_Error(-20001,'Dimensions are different',True);
      End If;
      v_gtype_1 := p_geom_1.Get_GType();
      v_gtype_2 := p_geom_2.Get_GType();
      Case
      When v_gtype_1 = 1 Then  -- Point
      Begin
          v_geom := mdsys.sdo_geometry(p_geom_1.sdo_gtype,
                                     p_geom_1.sdo_srid,
                                     NULL,
                                     mdsys.sdo_elem_info_array(1,1,2),
                                     mdsys.sdo_ordinate_array());
        v_geom.sdo_ordinates.Extend(v_dims_1);
        -- Add first point's ordinates...
        If ( p_geom_1.sdo_point is not null ) Then
          v_geom.sdo_ordinates(1) := p_geom_1.sdo_point.x;
          v_geom.sdo_ordinates(2) := p_geom_1.sdo_point.y;
          If ( v_dims_1 > 2 ) Then
            v_geom.sdo_ordinates(3) := p_geom_1.sdo_point.z;
          End If;
        Else
          For i In 1..v_dims_1 Loop
            v_geom.sdo_ordinates(i) := p_geom_1.sdo_ordinates(i);
          End Loop;
        End If;

        Case
        When v_gtype_2 = 1 Then  -- Point and point
        Begin
          v_geom.sdo_ordinates.Extend(v_dims_1);
          -- Add Second point's ordinates...
          If ( p_geom_2.sdo_point is not null ) Then
            v_geom.sdo_ordinates(v_dims_1 + 1) := p_geom_2.sdo_point.x;
            v_geom.sdo_ordinates(v_dims_1 + 2) := p_geom_2.sdo_point.y;
            If ( v_dims_2 > 2 ) Then
              v_geom.sdo_ordinates(v_dims_1 + 3) := p_geom_2.sdo_point.z;
            End If;
          Else
            For i In 1..v_dims_2 Loop
              v_geom.sdo_ordinates(v_dims_1 + i) := p_geom_2.sdo_ordinates(i);
            End Loop;
          End If;
        End;

        When v_gtype_2 in (2,3,4) Then  -- Point and Line/Polygon
        Begin
          v_offset := v_geom.sdo_ordinates.COUNT;
          v_geom.sdo_ordinates.Extend(p_geom_2.sdo_ordinates.COUNT);
          For i in 1..p_geom_2.sdo_ordinates.COUNT Loop
              v_geom.sdo_ordinates(v_dims_1 + i) := p_geom_2.sdo_ordinates(i);
          End Loop;
          v_geom.sdo_gtype := ( v_dims_1 * 1000 ) + 4; -- Is a compound element
          v_geom.sdo_elem_info(v_geom.sdo_elem_info.COUNT) := 1;
          v_geom.sdo_elem_info.extend(p_geom_2.sdo_elem_info.COUNT);
          For i in 1..p_geom_2.sdo_elem_info.COUNT Loop
              v_geom.sdo_elem_info(3 + i) := p_geom_2.sdo_elem_info(i) + case when mod(i,3) = 1 then v_offset else 0 end;
          End Loop;
        End;

        Else
          Raise_Application_Error(-20001,'Unsupported SDO_GTYPE (' || v_gtype_1 || ').',True);
        End Case;
      End;

      When v_gtype_1 in (2,3,4) Then  -- Linestring, Polygon or Compound
      Begin
        v_geom := p_geom_1;
        v_offset := v_geom.sdo_ordinates.COUNT;

        Case
        When v_gtype_2 = 1 Then -- Point
        Begin
          -- Add Second point's ordinates...
          If ( p_geom_2.sdo_point is not null and v_geom.sdo_point is null ) Then
            v_geom.sdo_point := p_geom_2.sdo_point;
          ElsIf ( p_geom_2.sdo_point is not null ) Then
            v_geom.sdo_ordinates.Extend(v_dims_2);
            v_geom.sdo_ordinates(v_offset + 1) := p_geom_2.sdo_point.x;
            v_geom.sdo_ordinates(v_offset + 2) := p_geom_2.sdo_point.y;
            If ( v_dims_2 > 2 ) Then
              v_geom.sdo_ordinates(v_offset + 3) := p_geom_2.sdo_point.z;
            End If;
          Else
            v_geom.sdo_gtype := ( v_dims_1 * 1000 ) + 4; -- Is a compound element
            v_geom.sdo_ordinates.Extend(v_dims_2);
            For i In 1..v_dims_2 Loop
              v_geom.sdo_ordinates(v_offset + i) := p_geom_2.sdo_ordinates(i);
            End Loop;
          End If;
        End;

        When v_gtype_2 in (2,3,4) Then -- Linestring, Polygon and Compound
        Begin
          v_geom.sdo_ordinates.Extend(p_geom_2.sdo_ordinates.COUNT);
          For i in 1..p_geom_2.sdo_ordinates.COUNT Loop
              v_geom.sdo_ordinates(v_offset + i) := p_geom_2.sdo_ordinates(i);
          End Loop;
          v_geom.sdo_gtype := ( v_dims_1 * 1000 ) +
                              case when least(v_gtype_1,v_gtype_2) + 3 = greatest(v_gtype_1,v_gtype_2)
                                   then greatest(v_gtype_1,v_gtype_2)
                                   when ( v_gtype_1 = v_gtype_2 )
                                   then
                                     case when v_gtype_1 < 5 then v_gtype_1 + 4 else v_gtype_1 end
                                   else 4 -- Is a compound element
                               end;
          --v_geom.sdo_elem_info(v_geom.sdo_elem_info.COUNT) := 1;
          v_geom.sdo_elem_info.extend(p_geom_2.sdo_elem_info.COUNT);
          For i in 1..p_geom_2.sdo_elem_info.COUNT Loop
              v_geom.sdo_elem_info(3 + i) := p_geom_2.sdo_elem_info(i) + case when mod(i,3) = 1 then v_offset else 0 end;
          End Loop;
        End;
        End Case;
      End;

      Else
        Raise_Application_Error(-20001,'Unsupported SDO_GTYPE (' || v_gtype_1 || ').',True);
      End Case;
      return v_geom;
    end append9;
  Begin
    If ( DBMS_DB_VERSION.VERSION < 10 ) Then
       -- Illegal use of Spatial if Locator (for time being)
       v_geom := Append9(p_geom_1, p_geom_2);
    Else
       EXECUTE IMMEDIATE 'SELECT MDSYS.SDO_UTIL.APPEND(:1,:2) FROM DUAL'
                   INTO v_geom
                  USING p_geom_1, p_geom_2;
    End If;
    Return v_geom;
  End Append;

  Function Concat_Lines(p_geom_1 in mdsys.sdo_geometry,
	                      p_geom_2 in mdsys.sdo_geometry )
    Return mdsys.sdo_geometry
  Is
    v_geom mdsys.sdo_geometry;
  Begin
    If ( p_geom_1 is null and p_geom_2 is null ) Then
      Return Null;
    ElsIf ( p_geom_1 is null ) Then
      Return p_geom_2;
    ElsIf ( p_geom_2 is null ) then
      Return p_geom_1;
    End If;
    If ( NVL(p_geom_1.sdo_srid,0) <> NVL(p_geom_2.sdo_srid,0) ) Then
      Raise_Application_Error(-20001,'SRIDs are different',True);
    End If;
    If NOT ( p_geom_1.Get_GType() in (2,6) And p_geom_2.Get_GType() in (2,6) ) Then
      Raise_Application_Error(-20001,'Can only concatentate two linestrings or multilinestrings.',True);
    End If;
    If ( DBMS_DB_VERSION.VERSION < 10 ) Then
       -- Illegal use of Spatial if Locator (for time being)
       v_geom := Append(p_geom_1, p_geom_2);
    Else
       EXECUTE IMMEDIATE 'SELECT MDSYS.SDO_UTIL.CONCAT_LINES(:1,:2) FROM DUAL'
                   INTO v_geom
                  USING p_geom_1, p_geom_2;
    End If;
    Return v_geom;
  End Concat_Lines;

  Function Tolerance( p_geometry IN MDSYS.SDO_GEOMETRY,
                      p_dimarray IN MDSYS.SDO_DIM_ARRAY )
    RETURN MDSYS.SDO_GEOMETRY
    IS
     v_ordinates      mdsys.sdo_ordinate_array := new mdsys.sdo_ordinate_array();
     v_x_round_factor number;
     v_y_round_factor number;
     v_z_round_factor number;
     v_m_round_factor number;
  Begin
    If ( p_dimarray is null ) Then
     raise_application_error(&&defaultSchema..Constants.c_i_null_tolerance,&&defaultSchema..Constants.c_s_null_tolerance,true);
    End If;
    -- Compute rounding factors
    v_x_round_factor := round(log(10,(1/p_dimarray(1).sdo_tolerance)/2));
    v_y_round_factor := round(log(10,(1/p_dimarray(2).sdo_tolerance)/2));
    IF ( p_dimarray.count > 2 ) Then
      v_z_round_factor := floor(log(10,(1/p_dimarray(3).sdo_tolerance)/2));
      IF ( p_dimarray.count > 3 ) THEN
         v_m_round_factor := floor(log(10,(1/p_dimarray(4).sdo_tolerance)/2));
      END IF;
    END IF;
    RETURN RoundOrdinates(p_geometry,
                          v_x_round_factor,
                          v_y_round_factor,
                          v_z_round_factor,
                          v_m_round_factor
                          );
  END tolerance;

  Function RoundOrdinates ( P_Geometry        In Mdsys.Sdo_Geometry,
                            P_X_Round_Factor  In Number,
                            p_y_round_factor  In Number := null,
                            P_Z_Round_Factor  In Number := Null,
                            p_m_round_factor  In Number := null)
    RETURN MDSYS.SDO_GEOMETRY
    Is
       v_ismeasured       boolean;
       v_dim              pls_integer;
       v_gtype            pls_integer;
       v_measure_ord      pls_integer;
       v_ord              pls_integer;
       v_geometry         mdsys.sdo_geometry := new sdo_geometry(p_geometry.sdo_gtype,
                                                                 p_geometry.sdo_srid,
                                                                 p_geometry.sdo_point,
                                                                 p_geometry.sdo_elem_info,
                                                                 p_geometry.sdo_ordinates);
       V_Ordinates        mdsys.Sdo_Ordinate_Array;
       V_X_Round_Factor   Number := NVL(P_X_Round_Factor,3);
       V_Y_Round_Factor   Number := Nvl(P_Y_Round_Factor,v_X_Round_Factor);
       V_Z_Round_Factor   Number := Nvl(P_z_Round_Factor,v_X_Round_Factor);
       V_W_Round_Factor   Number := NVL(p_m_round_factor,v_x_round_factor);
    Begin
      If ( p_x_round_factor Is Null ) Then
         raise_application_error(&&defaultSchema..CONSTANTS.c_i_null_tolerance,
                                 &&defaultSchema..CONSTANTS.c_s_null_tolerance,TRUE);
       End If;
      If ( p_geometry is null ) Then
         raise_application_error(&&defaultSchema..CONSTANTS.c_i_null_geometry,
                                 &&defaultSchema..CONSTANTS.c_s_null_geometry,TRUE);
      End If;
      V_Ismeasured := Case When Mod(Trunc(p_geometry.Sdo_Gtype/100),10) = 0 Then False Else True End;
      v_gtype := Mod(p_geometry.sdo_gtype,10);
      v_dim   := p_geometry.get_dims(); -- IF 9i then .... TRUNC(p_geometry.sdo_gtype/1000,0);
      -- If point update differently to other shapes...
      --
      If ( V_Geometry.Sdo_Point Is Not Null ) Then
        v_geometry.sdo_point.X := round(v_geometry.sdo_point.x,v_x_round_factor);
        V_Geometry.Sdo_Point.Y := Round(V_Geometry.Sdo_Point.Y,V_Y_Round_Factor);
        If ( v_dim > 2 ) Then
          v_geometry.sdo_point.z := round(v_geometry.sdo_point.z,v_z_round_factor);
        End If;
      END IF;
      IF ( p_geometry.sdo_ordinates is not null ) THEN
        v_measure_ord := MOD(trunc(p_geometry.sdo_gtype/100),10);
        v_ordinates   := new mdsys.sdo_ordinate_array(1);
        v_ordinates.DELETE;
        v_ordinates.EXTEND(p_geometry.sdo_ordinates.count);
        -- Process all coordinates
        <<while_vertex_to_process>>
        FOR v_i IN 1..(v_ordinates.COUNT/v_dim) LOOP
           v_ord := (v_i-1)*v_dim + 1;
           v_ordinates(v_ord) := round(p_geometry.sdo_ordinates(v_ord),v_x_round_factor);
           v_ord := v_ord + 1;
           v_ordinates(v_ord) := round(p_geometry.sdo_ordinates(v_ord),v_y_round_factor);
           if ( v_dim >= 3 ) Then
              v_ord := v_ord + 1;
              V_Ordinates(v_ord) := Case When V_Ismeasured
                                         then round(p_geometry.sdo_ordinates(v_ord),v_w_round_factor)
                                         else round(p_geometry.sdo_ordinates(v_ord),v_z_round_factor)
                                      End;
              if ( v_dim > 3 ) Then
                 v_ord := v_ord + 1;
                 v_ordinates(v_ord) := round(p_geometry.sdo_ordinates(v_ord),v_w_round_factor);
              End If;
           End If;
        END LOOP while_vertex_to_process;
      END IF;
      RETURN mdsys.sdo_geometry(v_geometry.sdo_gtype,
                                v_geometry.sdo_srid,
                                v_geometry.sdo_point,
                                v_geometry.sdo_elem_info,
                                V_Ordinates);
    END RoundOrdinates;

  /** Overloaded functions */
  Function Tolerance( p_geometry  IN MDSYS.SDO_GEOMETRY,
                      p_tolerance IN NUMBER)
    RETURN MDSYS.SDO_GEOMETRY
  IS
    v_round_factor number;
  Begin
    If ( p_tolerance is null ) Then
     raise_application_error(&&defaultSchema..Constants.c_i_null_tolerance,&&defaultSchema..Constants.c_s_null_tolerance,true);
    End If;
    -- Compute rounding factors
    v_round_factor := round(log(10,(1/p_tolerance)/2));
    RETURN &&defaultSchema..GEOM.RoundOrdinates(p_geometry,v_round_factor);
  END Tolerance;

  Function Tolerance( p_geometry    IN MDSYS.SDO_GEOMETRY,
                      p_X_tolerance IN NUMBER,
                      p_Y_tolerance IN NUMBER,
                      p_Z_tolerance IN NUMBER := NULL)
    RETURN MDSYS.SDO_GEOMETRY
  IS
     V_X_Round_Factor Number;
     V_Y_Round_Factor Number;
     V_Z_Round_Factor Number;
  Begin
    If ( p_X_tolerance is null ) Then
     raise_application_error(&&defaultSchema..Constants.c_i_null_tolerance,&&defaultSchema..Constants.c_s_null_tolerance,true);
    End If;
    -- Compute rounding factors
    v_x_round_factor := round(log(10,(1/p_X_tolerance)/2));
    v_y_round_factor := round(log(10,(1/p_Y_tolerance)/2));
    IF ( p_Z_tolerance is not null ) Then
      v_z_round_factor := floor(log(10,(1/p_Z_tolerance)/2));
    END IF;
    RETURN &&defaultSchema..GEOM.RoundOrdinates(p_geometry,
                                       p_X_tolerance,
                                       p_Y_tolerance,
                                       p_Z_tolerance);
  END Tolerance;

  PROCEDURE toleranceUpdate( p_tableName IN VARCHAR2 )
   IS
     c_rowid           varchar2(18);
     v_count           number;
     v_diminfo         mdsys.sdo_dim_array;
     c_shape           mdsys.sdo_geometry;
     TYPE shapeCursorType IS REF CURSOR;
     shapeCursor shapeCursorType;
   Begin
    SELECT   diminfo
      INTO v_diminfo
      FROM USER_SDO_GEOM_METADATA
     WHERE table_name = p_tablename and column_name = 'SHAPE';
    v_count := 0;
    OPEN shapeCursor FOR 'SELECT ROWID, SHAPE FROM ' || p_tablename;
    LOOP
     FETCH shapeCursor INTO c_rowid, c_shape;
     EXIT WHEN shapeCursor%NOTFOUND;
     v_count := v_count + 1;
     EXECUTE IMMEDIATE 'UPDATE ' || p_tablename || ' A SET A.SHAPE = :1 WHERE rowid = :2 '
             USING tolerance(c_shape,v_diminfo), c_rowid;
     IF MOD(v_count,100) = 0 Then
       COMMIT;
     END IF;
    END LOOP;
    CLOSE shapeCursor;
    COMMIT;
    EXCEPTION
     WHEN NO_DATA_FOUND Then
       NULL;
  END toleranceUpdate;

  /* @history    : Simon Greener - Jul 2006 - Migrated to GF package and made 3D aware.
  */
  Function removeDuplicateCoordinates ( p_geometry   IN MDSYS.SDO_GEOMETRY,
                                        p_diminfo    IN MDSYS.SDO_DIM_ARRAY
                                       )
    Return MDSYS.SDO_GEOMETRY
  IS
     v_geometry       MDSYS.SDO_GEOMETRY;
     v_new_elem_info  MDSYS.SDO_ELEM_INFO_ARRAY;
     v_new_ordinates  MDSYS.SDO_ORDINATE_ARRAY;
     v_offset         number;
     v_vertex         number;
     v_Coord          &&defaultSchema..ST_Point;
     v_prev_Coord     &&defaultSchema..ST_Point;
     v_dim            number;
     v_elem_info      &&defaultSchema..T_ElemInfo := &&defaultSchema..T_ElemInfo(NULL,NULL,NULL);
     v_partToProcess  boolean;
     v_coordToProcess boolean;
  Begin
    v_Coord      := New &&defaultSchema..ST_Point(&&defaultSchema..Constants.c_MaxVal,&&defaultSchema..Constants.c_MaxVal);
    v_Prev_Coord := New &&defaultSchema..ST_Point(&&defaultSchema..Constants.c_MaxVal,&&defaultSchema..Constants.c_MaxVal);
     -- Only processes non-simple point geometries...
     IF ( p_geometry.sdo_ordinates is null ) Then
       Return p_geometry;
     END IF;
     v_geometry := tolerance(p_geometry,p_diminfo);

     v_new_elem_info := mdsys.sdo_elem_info_array();
     v_new_ordinates := mdsys.sdo_ordinate_array();

     &&defaultSchema..GF.New;
     &&defaultSchema..GF.SetGeometry( v_geometry );

     v_dim   := &&defaultSchema..GF.GetDimension();
     v_offset := 1;
     v_partToProcess := &&defaultSchema..GF.FirstElement();
     <<while_part_to_process>>
     While v_partToProcess Loop
       <<while_coord_to_process>>
       v_prev_coord.x := &&defaultSchema..Constants.c_MinVal;
       v_prev_coord.x := &&defaultSchema..Constants.c_MinVal;
       v_prev_coord.z := NULL;
       v_prev_coord.m := NULL;
       v_coordToProcess := &&defaultSchema..GF.FirstCoordinate();
       WHILE v_coordToProcess LOOP
         v_coord := &&defaultSchema..GF.GetCoordinate();
         IF ( ( v_coord.x <> v_prev_coord.x ) OR
              ( v_coord.y <> v_prev_coord.y ) OR
              ( v_coord.z <> v_prev_coord.z ) OR
              ( v_coord.m <> v_prev_coord.m ) ) Then
           ADD_Coordinate( v_new_ordinates, v_dim, v_coord );
           v_vertex := v_vertex + 1;
         END IF;
         v_prev_coord     := v_coord;
         v_coordToProcess := &&defaultSchema..GF.NextCoordinate();
       END LOOP while_coord_to_process;
       v_elem_info := &&defaultSchema..GF.GetElemInfo();
       ADD_Element( v_new_elem_info, v_offset, v_elem_info.etype, v_elem_info.interpretation );
       v_offset := v_offset + ( v_vertex * v_dim );
       v_partToProcess := &&defaultSchema..GF.NextElement();
     END LOOP while_part_to_process;
     RETURN MDSYS.SDO_GEOMETRY(p_geometry.sdo_gtype,
                               p_geometry.sdo_srid,
                               p_geometry.sdo_point,
                               v_new_elem_info,
                               v_new_ordinates);
  END removeDuplicateCoordinates;

  Function totalCoords( p_geometry in mdsys.sdo_geometry )
    RETURN number
    IS
  Begin
    RETURN to_char( p_geometry.sdo_ordinates.count / (to_number(substr(ltrim(to_char(p_geometry.sdo_gtype,'9999'),' '),1,1),'9')) );
  END totalCoords;

  Function MidVertex( p_first_vertex IN &&defaultSchema..ST_Point,
                      p_last_vertex  IN &&defaultSchema..ST_Point )
           Return &&defaultSchema..ST_Point DETERMINISTIC
  Is
  Begin
    return &&defaultSchema..ST_Point( p_first_vertex.x + ( p_last_vertex.x - p_first_vertex.x ) / 2,
                                      p_first_vertex.y + ( p_last_vertex.y - p_first_vertex.y ) / 2,
                                      p_first_vertex.z + ( p_last_vertex.z - p_first_vertex.z ) / 2,
                                      p_first_vertex.m + ( p_last_vertex.m - p_first_vertex.m ) / 2 );
  End MidVertex;

  Function Densify( p_geometry  IN MDSYS.SDO_GEOMETRY,
                    p_tolerance IN number,
                    p_distance  IN number )
           RETURN MDSYS.SDO_GEOMETRY
  Is
    v_geometry        MDSYS.SDO_Geometry;
    v_Coord           &&defaultSchema..ST_Point    := &&defaultSchema..ST_Point(&&defaultSchema..Constants.c_MaxVal,&&defaultSchema..Constants.c_MaxVal);
    v_frst_Coord      &&defaultSchema..ST_Point    := &&defaultSchema..ST_Point(&&defaultSchema..Constants.c_MaxVal,&&defaultSchema..Constants.c_MaxVal);
    v_last_Coord      &&defaultSchema..ST_Point    := &&defaultSchema..ST_Point(&&defaultSchema..Constants.c_MaxVal,&&defaultSchema..Constants.c_MaxVal);
    v_seg_coords      &&defaultSchema..ST_PointSet := &&defaultSchema..ST_PointSet();
    v_segment         number;
    v_vertex          number;
    v_dim             number;
    v_elem_info       &&defaultSchema..T_ElemInfo := &&defaultSchema..T_ElemInfo(NULL,NULL,NULL);
    v_offset          number := 0;  -- Element ordinate offset
    v_elem_info_array mdsys.sdo_elem_info_array;
    v_ordinates       mdsys.sdo_ordinate_array;
    v_partToProcess   boolean;
    v_coordToProcess  boolean;

    Procedure SaveSegment
    Is
      v_i      number;
    Begin
       FOR v_i IN v_seg_coords.FIRST .. v_seg_coords.LAST LOOP
         ADD_Coordinate(v_ordinates,v_dim,v_seg_coords(v_i));
       END LOOP;
    End;

    Procedure DensifySegment( p_vertices     IN OUT NOCOPY &&defaultSchema..ST_PointSet,
                              p_first_vertex IN &&defaultSchema..ST_Point,
                              p_last_vertex  IN &&defaultSchema..ST_Point
                            )
    Is
      v_dist           number;
      v_middle_vertex  &&defaultSchema..ST_Point := &&defaultSchema..ST_Point(&&defaultSchema..Constants.c_MaxVal,&&defaultSchema..Constants.c_MaxVal);
    Begin
      v_dist := &&defaultSchema..COGO.Distance(p_first_vertex,p_last_vertex,p_geometry.sdo_srid,p_tolerance);
      If ( v_dist > p_distance ) Then
        -- Create a new point in the middle of the current segment
        v_middle_vertex := MidVertex(p_first_vertex,p_last_vertex);
        -- Now call this function again to recurse the left part
        DensifySegment(p_vertices,p_first_vertex,v_middle_vertex);
        If ( &&defaultSchema..COGO.Distance(p_first_vertex,v_middle_vertex,p_geometry.sdo_srid,p_tolerance) > p_distance ) Then
          -- Save this coordinate
          p_vertices.EXTEND;
          p_vertices(p_vertices.LAST) := v_middle_vertex;
        -- DEBUG dbms_output.put_line('Middle('||v_middle_vertex.x||','||v_middle_vertex.y||')');
        End If;
        -- Then recurse the right part
        DensifySegment(p_vertices,v_middle_vertex,p_last_vertex);
     END IF;
    End DensifySegment;

  Begin
    v_seg_coords.Extend(1);
    v_seg_coords(1) := New &&defaultSchema..ST_Point(&&defaultSchema..Constants.c_MaxVal,&&defaultSchema..Constants.c_MaxVal);
    v_seg_coords(1).x := NULL;
    v_seg_coords(1).y := NULL;
    v_seg_coords(1).z := NULL;
    v_seg_coords(1).m := NULL;
    v_seg_coords.DELETE; -- all segment coords
    -- We do not densify such that we produce an invalid geometry!
    If ( p_distance < p_tolerance ) Then
      Return p_geometry;
    End If;
    -- We do not densify points
    --
    If ( MOD(p_geometry.sdo_gtype,10) = 1 ) Then
      Return p_geometry;
    End If;

    v_elem_info_array := mdsys.sdo_elem_info_array();
    v_ordinates       := mdsys.sdo_ordinate_array();

    &&defaultSchema..GF.New;
    &&defaultSchema..GF.SetGeometry( p_geometry );
    v_dim    := &&defaultSchema..GF.GetDimension();
    v_offset := 1;
    v_partToProcess := &&defaultSchema..GF.FirstElement();
    <<while_part_to_process>>
    While v_partToProcess Loop
      v_elem_info := &&defaultSchema..GF.GetElemInfo();
      -- We do not densify compound objects at the moment
      If ( v_elem_info.etype in (4,1005,2005) OR v_elem_info.interpretation <> 1 ) Then
        raise_application_error(&&defaultSchema..Constants.c_i_unsupported,
                                &&defaultSchema..Constants.c_s_unsupported,TRUE);
      End If;
      v_vertex         := 1;
      v_coordToProcess := &&defaultSchema..GF.FirstCoordinate();
      <<while_coord_to_process>>
      WHILE v_coordToProcess LOOP
        v_Coord     := &&defaultSchema..GF.GetCoordinate();
        IF v_vertex = 1 Then
          v_frst_coord := v_coord;
          -- Save first coordinate
          v_seg_coords.EXTEND;
          v_seg_coords(v_seg_coords.LAST) := v_frst_coord;
        ELSE
          v_last_coord := v_coord;
          -- Generate additional internal coordinates
          DensifySegment(v_seg_coords,v_frst_coord,v_last_coord);
          -- Save last coordinate
          v_seg_coords.EXTEND;
          v_seg_coords(v_seg_coords.LAST) := v_last_coord;
          SaveSegment;
          v_seg_coords.DELETE; -- all segment coords
          v_frst_coord := v_last_coord;
        END IF;
        v_vertex := v_vertex + 1;
        v_coordToProcess := &&defaultSchema..GF.NextCoordinate();
        END LOOP while_coord_to_process;
      -- Add the Element Info Array updated for the new offset information.
      ADD_Element( v_elem_info_array, v_offset, v_elem_info.etype, v_elem_info.interpretation );
      -- DEBUG dbms_output.put_line('v_offset = ' || v_offset);
      -- DEBUG dbms_output.put_line('v_ordinates.COUNT = ' || v_ordinates.COUNT);
      v_offset := v_ordinates.COUNT + 1;
      v_partToProcess := &&defaultSchema..GF.NextElement();
    END LOOP while_part_to_process;
    Return MDSYS.SDO_GEOMETRY(p_geometry.sdo_gtype,
                              p_geometry.sdo_srid,
                              p_geometry.sdo_point,
                              v_elem_info_array,
                              v_ordinates);
  End Densify;

  Function Convert_Geometry(p_geometry  In mdsys.SDO_Geometry,
                            p_arc2chord In Number := 0.1 )
     Return mdsys.SDO_GEOMETRY
  Is
    CURSOR c_coordinates( p_geometry  in mdsys.sdo_geometry,
                          p_start     in number,
                          p_end       in number) Is
    SELECT Coord
      FROM (SELECT &&defaultSchema..T_Vertex(
                         i.x,
                         i.y,
                         CASE WHEN MOD(trunc(p_geometry.sdo_gtype/100),10) <> 3
                              THEN i.z
                              ELSE NULL
                          END,
                         CASE WHEN MOD(trunc(p_geometry.sdo_gtype/100),10) = 3
                              THEN i.z
                              ELSE i.w
                          END,
                         rownum) as Coord
              FROM TABLE(mdsys.sdo_util.getvertices(p_geometry)) i
           ) c
     WHERE c.coord.id BETWEEN p_start AND p_end;

    -- Note, this is based on there not being any compound (arc'd) elements in the geometry
    CURSOR c_elements (p_geometry        in mdsys.sdo_geometry,
                       p_dims            in number) IS
      SELECT i.offset,
             i.etype,
             i.interpretation,
             (((i.offset-1)/p_dims)+1) as first_coord,
             ((case when (lead(i.offset,1) over (order by i.id)) is not null
                    then (lead(i.offset,1) over (order by i.id))
                    else (select count(*) + 1 from table(p_geometry.SDO_ORDINATES))
                end - 1) / p_dims) as last_coord
        FROM (SELECT e.id,
                     e.etype,
                     e.offset,
                     e.interpretation
                FROM (SELECT trunc((rownum - 1) / 3,0) as id,
                             sum(case when mod(rownum,3) = 1 then sei.column_value else null end) as offset,
                             sum(case when mod(rownum,3) = 2 then sei.column_value else null end) as etype,
                             sum(case when mod(rownum,3) = 0 then sei.column_value else null end) as interpretation
                        FROM TABLE(p_geometry.sdo_elem_info) sei
                       GROUP BY trunc((rownum - 1) / 3,0)
                      ) e
                     ) i
      ORDER BY i.id;

    Cursor c_arc_points(p_geometry in mdsys.sdo_geometry) Is
    Select i.x,i.y,
           CASE WHEN MOD(trunc(p_geometry.sdo_gtype/100),10) <> 3
                THEN i.z
                ELSE NULL
            END as z,
           CASE WHEN MOD(trunc(p_geometry.sdo_gtype/100),10) = 3
                THEN i.z
                ELSE i.w
            END as w
      From Table(sdo_util.GetVertices(p_geometry)) i;

    v_geometry          MdSys.Sdo_Geometry;
    v_ord_pos           number;
    v_start_coord       &&defaultSchema..T_Vertex;
    v_mid_coord         &&defaultSchema..T_Vertex;
    v_end_coord         &&defaultSchema..T_Vertex;
    v_CentreX           Number;
    v_CentreY           Number;
    v_radius            Number;
    v_dims              Number;
    v_elem_info         mdsys.sdo_elem_info_array := mdsys.sdo_elem_info_array();
    v_ordinates         mdsys.sdo_ordinate_array  := mdsys.sdo_ordinate_array();
    v_num_sub_elements  Number := 0;
    v_first_coord       Number;
    v_last_coord        Number;
    NULL_GEOMETRY       EXCEPTION;

    /* -------------------- ConvertGeometry Procedures and Functions -------------- */

    Function CircularArc2Line(dStart      in &&defaultSchema..T_Vertex,
                              dMid        in &&defaultSchema..T_Vertex,
                              dEnd        in &&defaultSchema..T_Vertex,
                              p_Arc2Chord in number  := 0.1 )
    Return MDSYS.Sdo_Geometry
    IS
        iDimension          Number;
        dTheta              Number;
        dTheta1             Number;
        dTheta2             Number;
        dDeltaTheta         Number;
        dThetaStart         Number;
        dBearingStart       Number;
        iSeg                Integer;
        dCentreX            Number;
        dCentreY            Number;
        dRadius             Number;
        iOptimalSegments    Integer;
        dMDelta             Number;
        iAbsSegments        Integer;
        vRotation           Integer;
        v_ordinates         mdsys.sdo_ordinate_array := mdsys.sdo_ordinate_array();
    BEGIN
        If Not &&defaultSchema..COGO.FindCircle(dStart.X,  dStart.Y,
                          dMid.X,    dMid.Y,
                          dEnd.X,    dEnd.Y,
                          dCentreX, dCentreY, dRadius) Then
          raise_application_error(&&defaultSchema..CONSTANTS.c_i_CircleProperties,
                                  &&defaultSchema..CONSTANTS.c_s_CircleProperties,False);
          Return Null;
        End If;
        iDimension := case when dStart.Z is null then 2 else case when dStart.W is null then 3 else 4 end end;

        dBearingStart    := &&defaultSchema..COGO.Bearing(dCentreX, dCentreY, dStart.X, dStart.Y);
        -- Compute number of segments for whole circle
        iOptimalSegments := &&defaultSchema..COGO.OptimalCircleSegments(dRadius, p_Arc2Chord);
        dTheta1 := &&defaultSchema..COGO.AngleBetween3Points(dStart.X, dStart.Y, dCentreX, dCentreY, dMid.X, dMid.Y);
        dTheta2 := &&defaultSchema..COGO.AngleBetween3Points(dMid.X,   dMid.Y,   dCentreX, dCentreY, dEnd.X, dEnd.Y);
        vRotation := case when dTheta1 < 0 or dTheta2 < 0 then -1 else 1 end;
        dTheta    := (ABS(dTheta1) + ABS(dTheta2)) * vRotation;

        -- Compute number of segments just for this arc
        iOptimalSegments := Round(iOptimalSegments * (dTheta / (2 * &&defaultSchema..CONSTANTS.c_PI)));
        If ( abs(iOptimalSegments) < 3 ) Then
           -- Return the original arc as a line
           RETURN( MDSYS.SDO_GEOMETRY(iDimension*1000 + 2,
                                      NULL,
                                      NULL,
                                      mdsys.sdo_elem_info_array(1, 2, 1 ),
                                      case iDimension
                                           when 2 then mdsys.sdo_ordinate_array( dStart.X, dStart.Y, dMid.X, dMid.Y, dEnd.X, dEnd.Y )
                                           when 3 then mdsys.sdo_ordinate_array( dStart.X, dStart.Y, dStart.Z, dMid.X, dMid.Y, dMid.Z, dEnd.X, dEnd.Y, dEnd.Z )
                                           when 4 then mdsys.sdo_ordinate_array( dStart.X, dStart.Y, dStart.Z, dStart.W, dMid.X, dMid.Y, dMid.Z, dMid.W, dEnd.X, dEnd.Y, dEnd.Z, dEnd.W )
                                           else mdsys.sdo_ordinate_array( dStart.X, dStart.Y, dMid.X, dMid.Y, dEnd.X, dEnd.Y )
                                           end
                                      )
                 );
        End If;

        If ( dTheta > 0 ) Then
            --angle is clockwise
            If ( iOptimalSegments < 0 ) Then
                --circularArc is anticlockwise so get the opposite angle (Should be +ve)
                dTheta := 2 * &&defaultSchema..CONSTANTS.c_PI + dTheta;
            End If;
            --dDeltaTheta should be -ve
            dThetaStart := dBearingStart - &&defaultSchema..CONSTANTS.c_PI / 2;
        Else
            --angle is anticlockwise
            If ( iOptimalSegments > 0 ) Then
                --circularArc is clockwise so get the opposite angle (Should be -ve)
                dTheta := dTheta - (2 * &&defaultSchema..CONSTANTS.c_PI);
            End If;
            --dDeltaTheta should be +ve
        End If;
        iAbsSegments := Abs(iOptimalSegments);
        dDeltaTheta := dTheta / iAbsSegments;

        --compensate for cartesian angles versus compass bearing
        If dBearingStart = 0 Then
            dThetaStart := &&defaultSchema..CONSTANTS.c_PI / 2;
        ElsIf (dBearingStart > 0) And (dBearingStart <= &&defaultSchema..CONSTANTS.c_PI / 2) Then
            dThetaStart := &&defaultSchema..CONSTANTS.c_PI / 2 - dBearingStart;
        ElsIf (dBearingStart > &&defaultSchema..CONSTANTS.c_PI / 2) Then
            dThetaStart := 2 * &&defaultSchema..CONSTANTS.c_PI - (dBearingStart - &&defaultSchema..CONSTANTS.c_PI / 2);
        End If;

        if ( iDimension = 4 ) Then
          dMDelta := ( 1 / iAbsSegments ) * ( dEnd.W - dStart.W);
        End If;
        -- Start with first point
        ADD_Coordinate( v_ordinates, iDimension, dStart );
        dTheta := dThetaStart;
        -- Create intermediate points
        FOR iSeg in 1..(iAbsSegments-1) LOOP
            dTheta := dTheta + dDeltaTheta;
            ADD_Coordinate( v_ordinates,
                            iDimension,
                           (dCentreX + dRadius * Cos(dTheta)),
                           (dCentreY + dRadius * Sin(dTheta)),
                           dStart.Z,
                           case when iDimension = 4 then dStart.W + ( iSeg * dMDelta ) else null end );
        END LOOP;
        -- Add end point
        ADD_Coordinate( v_ordinates, iDimension, dEnd );
        RETURN( MDSYS.SDO_GEOMETRY(iDimension*1000 + 2,NULL,NULL,mdsys.sdo_elem_info_array(1, 2, 1 ),v_ordinates) );
    End CircularArc2Line;

    Function Circle2Polygon( dCentreX in number,
                             dCentreY in number,
                             dRadius in number,
                             iSegments in integer)
    Return MDSYS.Sdo_Geometry
    IS
        dTheta       Number;
        dDeltaTheta  Number;
        iSeg         Integer;
        iAbsSegments Integer;
        v_ordinates  mdsys.sdo_ordinate_array;
    BEGIN
        v_ordinates := mdsys.sdo_ordinate_array();
        -- if iSegments is negative then the dDeltaTheta value will be negative and so the circle will be anticlockwise
        dDeltaTheta := 2 * &&defaultSchema..CONSTANTS.c_PI / iSegments;
        iAbsSegments := Abs(iSegments);
        ADD_Coordinate( v_ordinates, 2, (dCentreX + dRadius),dCentreY, NULL, NULL );
        dTheta := 0;
        FOR iSeg in 1..iAbsSegments LOOP
            dTheta := dTheta + dDeltaTheta;
            ADD_Coordinate( v_ordinates, 2, (dCentreX + dRadius * Cos(dTheta)), (dCentreY + dRadius * Sin(dTheta)), NULL, NULL );
        END LOOP;
        RETURN ( MDSYS.SDO_GEOMETRY(2003,NULL,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),v_ordinates) );
    End Circle2Polygon;

    Procedure Rectangle2Polygon(p_etype       In Number,
                                p_first_coord in number,
                                p_last_coord  in Number)
    As
    Begin
        v_elem_info(v_elem_info.COUNT) := 1;
        FOR crd IN c_coordinates(p_geometry,p_first_coord,p_last_coord) LOOP
          If c_coordinates%ROWCOUNT = 1 Then
            v_start_coord := crd.coord;
          Else
            v_end_coord := crd.coord;
          End If;
        END LOOP;
        -- First coordinate
        ADD_Coordinate( v_ordinates, v_dims, v_start_coord.x, v_start_coord.y, v_start_coord.z, v_start_coord.w );
        -- Second coordinate
        If ( p_etype = 1003 ) Then
          ADD_Coordinate(v_ordinates,v_dims,v_end_coord.x,v_start_coord.y,(v_start_coord.z + v_end_coord.z) /2, v_start_coord.w);
        Else
          ADD_Coordinate(v_ordinates,v_dims,v_start_coord.x,v_end_coord.y,(v_start_coord.z + v_end_coord.z) /2,
              (v_end_coord.w - v_start_coord.w) * ((v_end_coord.x - v_start_coord.x) /
             ((v_end_coord.x - v_start_coord.x) + (v_end_coord.y - v_start_coord.y)) ));
        End If;
        -- 3rd or middle coordinate
        ADD_Coordinate(v_ordinates,v_dims,v_end_coord.x,v_end_coord.y,v_end_coord.z,v_end_coord.w);
        -- 4th coordinate
        If ( p_etype = 1003 ) Then
          ADD_Coordinate(v_ordinates,v_dims,v_start_coord.x,v_end_coord.y,(v_start_coord.z + v_end_coord.z) /2,v_start_coord.w);
        Else
          Add_Coordinate(v_ordinates,v_dims,v_end_coord.x,v_start_coord.y,(v_start_coord.z + v_end_coord.z) /2,
              (v_end_coord.w - v_start_coord.w) * ((v_end_coord.x - v_start_coord.x) /
             ((v_end_coord.x - v_start_coord.x) + (v_end_coord.y - v_start_coord.y)) ));
        End If;
        -- Last coordinate
        ADD_Coordinate(v_ordinates,v_dims,v_start_coord.x,v_start_coord.y,v_start_coord.z,v_start_coord.w);
    End Rectangle2Polygon;

    Procedure StrokeArc( p_elem_first_coord in number,
                         p_elem_last_coord  in number )
    Is
      v_number_arcs       Number;
      v_number_coords     Number := ( p_elem_last_coord - p_elem_first_coord ) + 1;
      v_first_coord       Number;
      v_last_coord        Number;
    Begin
        v_number_arcs := 1 + ( v_number_coords - 3 ) / 2;
        <<all_arcs_loop>>
        For i In 1..v_number_arcs Loop
          if i = 1 Then
            v_first_coord := p_elem_first_coord;
            v_last_coord  := v_first_coord + 2;
          else
            v_first_coord := v_last_coord;
            v_last_coord := v_first_coord + 2;
          end if;
          -- Now retrieve 3 points making up this arc
          <<Original_3_Points_Loop>>
          FOR crd IN c_coordinates(p_geometry,v_first_coord,v_last_coord) LOOP
            If c_coordinates%ROWCOUNT = 1 Then
             v_start_coord := crd.coord;
            ElsIf c_coordinates%ROWCOUNT = 2 Then
              v_mid_coord := crd.coord;
            Else
              v_end_coord := crd.coord;
            End If;
          END LOOP Original_3_Points_Loop;
          -- Convert arc to equivalent vertex-connected
          -- Cogo Code
          v_geometry := CircularArc2Line(v_start_coord,v_mid_coord,v_end_coord,p_Arc2Chord);
          If v_geometry is null Then
            raise_application_error(&&defaultSchema..CONSTANTS.c_i_CircArc2Linestring,
                                    &&defaultSchema..CONSTANTS.c_s_CircArc2Linestring,False);
            RETURN;
          Else
            -- write to ordinate array
            <<converted_arc_points_loop>>
            FOR rec IN c_Arc_Points(v_geometry) LOOP
              Add_Coordinate(v_ordinates,v_dims,rec.x,rec.y,rec.z,rec.w);
            END LOOP converted_arc_points_loop;
          End If;
        End Loop all_arcs_loop;
    End StrokeArc;

    Procedure StrokeCircle(p_elem_first_coord in number,
                           p_elem_last_coord in number,
                           p_elem_etype      in number)
    Is
      iOptimalCircleSegments Number;
    Begin
        FOR crd IN c_coordinates(p_geometry,p_elem_first_coord,p_elem_last_coord) LOOP
            If c_coordinates%ROWCOUNT = 1 Then
              v_start_coord := crd.coord;
            ElsIf c_coordinates%ROWCOUNT = 2 Then
              v_mid_coord := crd.coord;
            Else
              v_end_coord := crd.coord;
            End If;
        END LOOP;
        If &&defaultSchema..COGO.FindCircle(v_start_coord.X, v_start_coord.Y,
                      v_mid_coord.X, v_mid_coord.Y,
                      v_end_coord.X, v_end_coord.Y,
                      v_CentreX, v_CentreY, v_Radius) Then
            iOptimalCircleSegments := &&defaultSchema..COGO.OptimalCircleSegments(v_Radius, p_Arc2Chord);
            -- Convert to polygon shape
            --
            If ( p_elem_etype = 2003  ) Then
                -- Ensure vertex orientation will be correct
                iOptimalCircleSegments := 0 - iOptimalCircleSegments;
            End If;
            -- If the Oracle Spatial database is 9.2 or above, the MDSYS.SDO_GEOM.ARC_DENSIFY()
            -- Function should be used in a view...
            -- Note 1: Oracle Spatial does not support CIRCULAR ARCS and CIRCLES in GEODETIC
            -- coordinate space (ie LAT/LONG) in 9.x and above
            --
            v_geometry := Circle2Polygon(v_CentreX, v_CentreY, v_Radius, iOptimalCircleSegments);
            If v_geometry is null then
              raise_application_error(&&defaultSchema..CONSTANTS.c_i_Circle2Polygon,
                                      &&defaultSchema..CONSTANTS.c_s_Circle2Polygon,False);
              RETURN ;
            Else
              -- write to ordinate array
              FOR rec IN c_Arc_Points(v_geometry) LOOP
                Add_Coordinate(v_ordinates,v_dims,rec.x,rec.y,rec.z,rec.w);
              END LOOP;
            End If;
        Else
          raise_application_error(&&defaultSchema..CONSTANTS.c_i_CircleProperties,
                                  &&defaultSchema..CONSTANTS.c_s_CircleProperties,False);
          RETURN;
        End If;
    End StrokeCircle;

  Begin


    -- DEBUG  dbms_output.put_line(p_geometry.sdo_gtype);
    If ( Mod(p_geometry.sdo_gtype,10) in (1,5) ) Then
      Return p_geometry;
    End If;

    v_dims := TRUNC(p_geometry.sdo_gtype/1000,0);
    <<Element_Loop>>
    For elem IN c_elements(p_geometry,v_dims) Loop
      Case
      When elem.etype = 2 Then  -- Linestring
          If (v_num_sub_elements = 0 ) Then
            -- Interpretation is 1 because we convert everything to vertex-connected segments
            ADD_Element(v_elem_info, v_ordinates.COUNT  + 1,elem.etype,1);
          End If;
          v_first_coord := elem.first_coord;
          v_last_coord  := elem.last_coord;
          if v_num_sub_elements > 0 Then
            -- The last point of a subelement is the first point of the next subelement (??except when end of element OR whole ordinate array??), and must not be repeated.
            v_last_coord := elem.last_coord + case when v_num_sub_elements = 1 then 0 else 1 end;
            v_num_sub_elements := v_num_sub_elements - 1;
          End If;
          Case
            When elem.Interpretation = 1 Then
              -- 2  1  Line string whose vertices are connected by straight line segments.
              FOR crd IN c_coordinates(p_geometry,v_first_coord,v_last_coord) LOOP
                  ADD_Coordinate(v_ordinates, v_dims, crd.coord);
              END LOOP;
            When elem.Interpretation = 2 Then
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
              StrokeArc(v_first_coord,v_last_coord);
          End Case;
      When elem.etype in (3,1003,2003) Then  -- Polygon with Hole
          ADD_Element(v_elem_info, v_ordinates.COUNT  + 1,elem.etype,1); -- Because we convert everything to vertex-connected segments
          Case
            When elem.Interpretation = 1 Then
              -- 3  1   Simple polygon whose vertices are connected by straight line segments.
              --        Note that you must specify a point for each vertex, and the last point
              --        specified must be identical to the first (to close the polygon).
              --        For example, for a 4-sided polygon, specify 5 points, with point 5
              --        the same as point 1.
              FOR crd IN c_coordinates(p_geometry,elem.first_coord,elem.last_coord) LOOP
                Add_Coordinate(v_ordinates,v_dims,crd.coord);
              END LOOP;
            When elem.Interpretation = 2 Then
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
              StrokeArc(elem.first_coord,elem.last_coord);
            When elem.Interpretation = 3 Then
              -- 3  3   Rectangle type.
              --        A bounding rectangle such that only two points, the lower-left and the upper-right,
              --        are required to describe it.
              Rectangle2Polygon(elem.etype,elem.first_coord,elem.last_coord);
            When elem.Interpretation = 4 Then
              -- 3  4   Circle type.
              --        Described by three points, all on the circumference of the circle.
              StrokeCircle(elem.first_coord,elem.last_coord+1, elem.etype);
          End Case;
        When elem.etype IN (4,5,1005,2005) Then
            -- 4  n > 1  Compound line string with some vertices connected by straight line segments and some by circular arcs.
            --            The value n in the Interpretation column specifies the number of contiguous subelements that make up the line string.
            --            The next n triplets in the SDO_ELEM_INFO array describe each of these subelements.
            --            The subelements can only be of SDO_ETYPE 2.
            --            The last point of a subelement is the first point of the next subelement, and must not be repeated.
            -- 5,1005,2005 n > 1
            --            Compound polygon with some vertices connected by straight line segments and
            --            some by circular arcs. The value, n, in the Interpretation column specifies the number of
            --            contiguous subelements that make up the polygon.
            --            The next n triplets in the SDO_ELEM_INFO array describe each of these subelements.
            --            The subelements can only be of SDO_ETYPE 2.
            --            The end point of a subelement is the start point of the next subelement, and it must not be repeated.
            --            The start and end points of the polygon must be exactly the same point (tolerance is ignored).
            ADD_Element(v_elem_info,
                        v_ordinates.COUNT  + 1,
                        elem.etype-2, /* 4->2, 5->3, 1005->1003,2005->2003*/
                        1); -- Because we convert everything to vertex-connected segments
            v_num_sub_elements  := elem.interpretation;
     End Case;
    END LOOP Element_Loop;

    RETURN mdsys.sdo_geometry(p_geometry.sdo_gtype,
                              p_geometry.sdo_srid,
                              p_geometry.sdo_point,
                              v_elem_info,
                              v_ordinates);

    EXCEPTION
      WHEN NULL_GEOMETRY Then
        raise_application_error(&&defaultSchema..CONSTANTS.c_i_null_geometry,
                                &&defaultSchema..CONSTANTS.c_s_null_geometry,TRUE);
        RETURN p_geometry;
  End Convert_Geometry;

  Function GetVector( p_geometry in mdsys.sdo_geometry )
    Return &&defaultSchema..GEOM.T_VectorSet pipelined
  Is
    v_element        mdsys.sdo_geometry;
    v_ring           mdsys.sdo_geometry;
    v_element_no     pls_integer;
    v_ring_no        pls_integer;
    v_num_elements   pls_integer;
    v_num_rings      pls_integer;
    v_dimensions     pls_integer;
    v_coordinates    mdsys.vertex_set_type;
    NULL_GEOMETRY    EXCEPTION;
    NOT_CIRCULAR_ARC EXCEPTION;

    Function Vertex2Vertex(p_vertex in mdsys.vertex_type,
                           p_id     in pls_integer)
      return &&defaultSchema..T_Vertex deterministic
    Is
    Begin
       if ( p_vertex is null ) then
          return null;
       end if;
       return new &&defaultSchema..T_Vertex(p_vertex.x,p_vertex.y,p_vertex.z,p_vertex.w,p_id);
    End Vertex2Vertex;

  Begin
    If ( p_geometry is NULL ) Then
       raise NULL_GEOMETRY;
    End If;

    -- No Points
    -- DEBUG  dbms_output.put_line(p_geometry.sdo_gtype);
    If ( Mod(p_geometry.sdo_gtype,10) in (1,5) ) Then
      Return;
    End If;

   If ( &&defaultSchema..GEOM.hasCircularArcs(p_geometry.sdo_elem_info) ) Then
       raise NOT_CIRCULAR_ARC;
   End If;

   v_num_elements := MDSYS.SDO_UTIL.GETNUMELEM(p_geometry);
   <<all_elements>>
   FOR v_element_no IN 1..v_num_elements LOOP
       if ( v_num_elements = 1 ) Then
          v_element := p_geometry;
       Else
          v_element := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_element_no,0);
       End If;

       If ( v_element is not null ) Then
           -- Polygons
           -- Need to check for inner rings
           --
           If ( v_element.get_gtype() = 3) Then
              -- Process all rings in this single polygon have?
              v_num_rings := GetNumRings(v_element,&&defaultSchema..GEOM.c_rings_all);
              <<All_Rings>>
              FOR v_ring_no IN 1..v_num_rings LOOP
                  v_ring := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_element_no,v_ring_no);
                  -- Now generate marks
                  If ( v_ring is not null ) Then
                      v_coordinates := mdsys.sdo_util.getVertices(v_ring);
                      If ( v_ring.sdo_elem_info(2) in (1003,2003) And v_coordinates.COUNT = 2 ) Then
                         PIPE ROW( &&defaultSchema..T_Vector(1, Vertex2Vertex(v_coordinates(1),1),
                                                   &&defaultSchema..T_Vertex(v_coordinates(2).x, v_coordinates(1).y,
                                                                v_coordinates(1).z, v_coordinates(1).w,
                                                                2) ) );
                         PIPE ROW( &&defaultSchema..T_Vector(2, &&defaultSchema..T_Vertex(v_coordinates(2).x, v_coordinates(1).y,
                                                                v_coordinates(1).z, v_coordinates(1).w,
                                                                2),
                                                   Vertex2Vertex(v_coordinates(2),3) ) );
                         PIPE ROW( &&defaultSchema..T_Vector(3, Vertex2Vertex(v_coordinates(2),3),
                                                   &&defaultSchema..T_Vertex(v_coordinates(1).x, v_coordinates(2).y,
                                                                v_coordinates(1).z, v_coordinates(1).w,
                                                                4) ) );
                         PIPE ROW( &&defaultSchema..T_Vector(4, &&defaultSchema..T_Vertex(v_coordinates(1).x, v_coordinates(2).y,
                                                                v_coordinates(1).z, v_coordinates(1).w,
                                                                4),
                                                   Vertex2Vertex(v_coordinates(1),5) ) );
                      Else
                         FOR v_coord_no IN 1..v_coordinates.COUNT-1 LOOP
                            PIPE ROW(&&defaultSchema..T_Vector(v_coord_no,&&defaultSchema..T_Vertex(v_coordinates(v_coord_no).x,
                                                                          v_coordinates(v_coord_no).y,
                                                                          v_coordinates(v_coord_no).z,
                                                                          v_coordinates(v_coord_no).w,
                                                                          v_coord_no),
                                                             &&defaultSchema..T_Vertex(v_coordinates(v_coord_no+1).x,
                                                                          v_coordinates(v_coord_no+1).y,
                                                                          v_coordinates(v_coord_no+1).z,
                                                                          v_coordinates(v_coord_no+1).w,
                                                                          v_coord_no + 1) ) );
                         END LOOP;
                      End If;
                  End If;
              END LOOP All_Rings;
           -- Linestrings
           --
           ElsIf ( v_element.get_gtype() = 2) Then
               v_coordinates := mdsys.sdo_util.getVertices(v_element);
               FOR v_coord_no IN 1..v_coordinates.COUNT-1 LOOP
                   PIPE ROW(&&defaultSchema..T_Vector(v_coord_no,&&defaultSchema..T_Vertex(v_coordinates(v_coord_no).x,
                                                                 v_coordinates(v_coord_no).y,
                                                                 v_coordinates(v_coord_no).z,
                                                                 v_coordinates(v_coord_no).w,
                                                                 v_coord_no),
                                                    &&defaultSchema..T_Vertex(v_coordinates(v_coord_no+1).x,
                                                                 v_coordinates(v_coord_no+1).y,
                                                                 v_coordinates(v_coord_no+1).z,
                                                                 v_coordinates(v_coord_no+1).w,
                                                                 v_coord_no + 1)) );
               END LOOP;
           End If;
       End If;
   END LOOP all_elements;
   RETURN;
   EXCEPTION
      WHEN NULL_GEOMETRY THEN
        raise_application_error(&&defaultSchema..CONSTANTS.c_i_null_geometry, &&defaultSchema..CONSTANTS.c_s_null_geometry,TRUE);
        RETURN;
      WHEN NOT_CIRCULAR_ARC THEN
        raise_application_error(&&defaultSchema..CONSTANTS.c_i_arcs_unsupported, &&defaultSchema..CONSTANTS.c_s_arcs_unsupported,TRUE);
        RETURN;
  End GetVector;

  Function GetVector(p_geometry  in mdsys.sdo_geometry,
                     p_arc2chord in number  )
    Return &&defaultSchema..GEOM.T_VectorSet pipelined
  is
    v_geometry       MDSYS.SDO_Geometry := p_geometry;
  Begin
    If ( p_geometry is NULL ) Then
      Return ;
    End If;
    If ( Mod(v_geometry.sdo_gtype,10) in (1,5) ) Then
      Return ;
    End If;
    If isCompound(p_geometry.sdo_elem_info) > 0 Then
       -- And compound header to top of element_info (1,4,n_elements)
       v_geometry := &&defaultSchema..GEOM.Convert_Geometry(p_geometry,p_arc2chord);
    End If;
    <<vector_access_loop>>
    For rec IN (select v.id           as coord_no,
                       v.startCoord.x as sx,
                       v.startCoord.y as sy,
                       v.startCoord.z as sz,
                       v.startCoord.w as sw,
                       v.endCoord.X   as ex,
                       v.endCoord.Y   as ey,
                       v.endCoord.Z   as ez,
                       v.endCoord.w   as ew
                  from table(&&defaultSchema..geom.getvector(v_geometry)) v ) LOOP
      PIPE ROW (&&defaultSchema..T_Vector(rec.coord_no,
                                 &&defaultSchema..T_Vertex(rec.sx,rec.sy,rec.sz,rec.sw,rec.coord_no),
                                 &&defaultSchema..T_Vertex(rec.ex,rec.ey,rec.ez,rec.ew,rec.coord_no + 1)) );
    END LOOP vector_access_loop;
    RETURN ;
  end GetVector;

  Function GetVector2DArray ( p_geometry  in mdsys.sdo_geometry,
                              p_arc2chord in number := 0.1 )
    return &&defaultSchema..T_Vector2DSet
  is
    v_geometry       MDSYS.SDO_Geometry := p_geometry;
    vectors          &&defaultSchema..T_Vector2DSet := T_Vector2DSet();
  Begin
    If ( p_geometry is NULL ) Then
      Return NULL;
    End If;
    If ( Mod(v_geometry.sdo_gtype,10) in (1,5) ) Then
      Return NULL;
    End If;
    If isCompound(p_geometry.sdo_elem_info) > 0 Then
       -- And compound header to top of element_info (1,4,n_elements)
       v_geometry := &&defaultSchema..GEOM.Convert_Geometry(p_geometry,p_arc2chord);
    End If;
    <<vector_access_loop>>
    For rec IN (select v.startCoord.x as sx,
                       v.startCoord.y as sy,
                       v.endCoord.X   as ex,
                       v.endCoord.y   as ey
                  from table(&&defaultSchema..geom.getvector(v_geometry)) v ) LOOP
      vectors.EXTEND;
      vectors(vectors.LAST) := &&defaultSchema..T_Vector2d(&&defaultSchema..T_Coord2D(rec.sx,rec.sy),
                                                           &&defaultSchema..T_Coord2D(rec.ex,rec.ey));
    END LOOP vector_access_loop;
    RETURN vectors;
  END GetVector2DArray;

  Function GetVector2D(
    p_geometry  in mdsys.sdo_geometry,
    p_arc2chord in number := 0.1 )
    return &&defaultSchema..T_Vector2DSet pipelined
  is
    v_geometry       MDSYS.SDO_Geometry := p_geometry;
  Begin
    If ( p_geometry is NULL ) Then
      Return ;
    End If;
    If ( Mod(v_geometry.sdo_gtype,10) in (1,5) ) Then
      Return ;
    End If;
    If isCompound(p_geometry.sdo_elem_info) > 0 Then
       -- And compound header to top of element_info (1,4,n_elements)
       v_geometry := &&defaultSchema..GEOM.Convert_Geometry(p_geometry,p_arc2chord);
    End If;
    <<vector_access_loop>>
    For rec IN (select v.startCoord.x as sx,
                       v.startCoord.y as sy,
                       v.endCoord.X   as ex,
                       v.endCoord.y   as ey
                  from table(&&defaultSchema..geom.getvector(v_geometry)) v ) LOOP
      PIPE ROW (&&defaultSchema..T_Vector2d(&&defaultSchema..T_Coord2D(rec.sx,rec.sy),
                                     &&defaultSchema..T_Coord2D(rec.ex,rec.ey)));
    END LOOP vector_access_loop;
    RETURN ;
  end GetVector2D;

  Function GetArcs(p_geometry in mdsys.sdo_geometry )
    return &&defaultSchema..T_ArcSet pipelined
  is
    v_geometry       MDSYS.SDO_Geometry     := p_geometry;
    v_arc            &&defaultSchema..T_Arc := &&defaultSchema..T_Arc(&&defaultSchema..T_Vertex(&&defaultSchema..Constants.c_MinVal, &&defaultSchema..Constants.c_MinVal,
                                                                                                &&defaultSchema..Constants.c_MinVal, &&defaultSchema..Constants.c_MinVal,1),
                                                                      &&defaultSchema..T_Vertex(&&defaultSchema..Constants.c_MinVal, &&defaultSchema..Constants.c_MinVal,
                                                                                                &&defaultSchema..Constants.c_MinVal, &&defaultSchema..Constants.c_MinVal,2),
                                                                      &&defaultSchema..T_Vertex(&&defaultSchema..Constants.c_MinVal, &&defaultSchema..Constants.c_MinVal,
                                                                                                &&defaultSchema..Constants.c_MinVal, &&defaultSchema..Constants.c_MinVal,3));
    v_point          &&defaultSchema..ST_Point := &&defaultSchema..ST_Point(&&defaultSchema..Constants.c_MinVal, &&defaultSchema..Constants.c_MinVal);
    v_vertex         number;
    v_elem_type      Integer;
    v_partToProcess  boolean;
    v_coordToProcess boolean;
  Begin
    If ( p_geometry is NULL ) Then
      RETURN;
    End If;
    -- DEBUG  dbms_output.put_line(p_geometry.sdo_gtype);
    If ( Mod(v_geometry.sdo_gtype,10) in (1,5) ) Then
      RETURN;
    End If;
    -- Loop though geometry and load the arcs...
    --
    &&defaultSchema..GF.New;
    &&defaultSchema..GF.SetGeometry(v_geometry);
    v_partToProcess := &&defaultSchema..GF.FirstElement();
    <<element_access_loop>>
    While v_partToProcess Loop
      v_elem_type := &&defaultSchema..GF.GetElementGeomType();
      If ( v_elem_type = &&defaultSchema..GF.uElemType_CircularArc        Or
           v_elem_type = &&defaultSchema..GF.uElemType_PolyCircularArc    Or
           v_elem_type = &&defaultSchema..GF.uElemType_PolyCircularArcExt Or
           v_elem_type = &&defaultSchema..GF.uElemType_PolyCircularArcInt Or
           v_elem_type = &&defaultSchema..GF.uElemType_CircleExterior     Or
           v_elem_type = &&defaultSchema..GF.uElemType_CircleInterior ) Then
        -- Note: A circulararc element can describe more than on arc
        v_coordToProcess := &&defaultSchema..GF.FirstCoordinate();
        For i In 1..&&defaultSchema..GF.GetNumberOfArcsInElement() Loop
            v_vertex := case when i = 1 then 1 else 2 end;
            <<coordinate_access_loop>>
            WHILE v_coordToProcess And v_vertex < 4 LOOP
                  v_point := &&defaultSchema..GF.GetCoordinate();
                  Case v_vertex
                    When 1 Then
                      v_arc.startCoord.x := v_point.x;
                      v_arc.startCoord.y := v_point.y;
                      v_arc.startCoord.z := v_point.z;
                      v_arc.startCoord.w := v_point.m;
                    When 2 Then
                      v_arc.MidCoord.x := v_point.x;
                      v_arc.MidCoord.y := v_point.y;
                      v_arc.MidCoord.z := v_point.z;
                      v_arc.MidCoord.w := v_point.m;
                    When 3 Then
                      v_arc.endCoord.x := v_point.x;
                      v_arc.endCoord.y := v_point.y;
                      v_arc.endCoord.z := v_point.z;
                      v_arc.endCoord.w := v_point.m;
                      PIPE ROW ( v_arc );
                      v_arc.startCoord.x := v_point.x;
                      v_arc.startCoord.y := v_point.y;
                      v_arc.startCoord.z := v_point.z;
                      v_arc.startCoord.w := v_point.m;
                  End Case;
                  v_vertex := v_vertex + 1;
                  v_coordToProcess := &&defaultSchema..GF.NextCoordinate();
            END LOOP coordinate_access_loop;
        End Loop;
      End If;
      v_partToProcess := &&defaultSchema..GF.NextElement();
    End Loop element_access_loop;
    RETURN ;
  end GetArcs;

  /* Note that GetPointSet strokes Arcs if it finds them */
  Function GetPointSet( p_geometry  In mdsys.Sdo_Geometry,
                        p_stroke    in number := 0,
                        p_arc2chord in number := 0.1)
           Return &&defaultSchema..ST_PointSet Pipelined
  Is
    v_elem_type      number;
    v_dims           number := trunc(p_geometry.sdo_gtype/1000);
    v_Coord          &&defaultSchema..ST_Point := &&defaultSchema..ST_Point(&&defaultSchema..Constants.c_MaxVal,&&defaultSchema..Constants.c_MaxVal);
    v_partToProcess  boolean;
    v_CoordToProcess boolean;
    v_stroke         boolean := case when p_stroke = 0 then false else true end;
    cursor c_points(p_arc2chord in number) Is
    Select &&defaultSchema..ST_Point(a.x,a.y,a.z,a.m) as point
      from table(&&defaultSchema..GF.ConvertSpecialElements(p_arc2chord)) a;
  Begin
    If ( p_geometry is NULL ) Then
      RETURN;
    End If;
    If p_geometry.sdo_point is not null Then
       v_Coord.X := p_geometry.sdo_point.x;
       v_Coord.y := p_geometry.sdo_point.y;
       v_Coord.z := p_geometry.sdo_point.z;
       v_Coord.m := NULL;
       PIPE ROW( v_Coord );
    Else
      If ( NOT v_stroke ) Then
        for rec in (select dim,
                           &&defaultSchema..ST_Point(sum(v.x),sum(v.y),sum(v.z),sum(v.m)) as point
                      from (select trunc((rownum-1) / v_dims ) as dim,
                                   case when mod(rownum,v_dims) = 1 then o.column_value else null
                                    end as x,
                                   case when (mod(rownum,v_dims) = 0 and v_dims = 2)
                                             OR
                                             (mod(rownum,v_dims) = 1 and v_dims = 3)
                                             OR
                                             (mod(rownum,v_dims) = 2 and v_dims = 4)
                                        then o.column_value else null
                                    end as y,
                                   case when ((mod(rownum,v_dims) = 0 and v_dims = 3)
                                               OR
                                              (mod(rownum,v_dims) = 3 and v_dims = 4))
                                              AND
                                              (mod(trunc(p_geometry.sdo_gtype / 100),10) <> 3)
                                        then o.column_value else null
                                    end as z,
                                   case when (mod(rownum,v_dims) = 0 and v_dims = 4 )
                                              OR
                                             (
                                              ((mod(rownum,v_dims) = 0 and v_dims = 3)
                                               OR
                                               (mod(rownum,v_dims) = 3 and v_dims = 4))
                                               AND
                                              (mod(trunc(p_geometry.sdo_gtype / 100),10) = 3)
                                              )
                                        then o.column_value else null
                                    end as m
                              FROM TABLE(p_geometry.sdo_ordinates) o
                            ) v
                    group by v.dim
                  order by 1 )
         loop
            PIPE ROW( rec.point );
         end loop;
      Else
        &&defaultSchema..GF.New;
        &&defaultSchema..GF.SetGeometry(p_geometry);
        v_partToProcess := &&defaultSchema..GF.FirstElement();
        <<element_access_loop>>
        While v_partToProcess Loop
          v_elem_type := &&defaultSchema..GF.GetElementGeomType();
          If ( v_elem_type = &&defaultSchema..GF.uElemType_Rectangle          Or
               v_elem_type = &&defaultSchema..GF.uElemType_RectangleExterior  Or
               v_elem_type = &&defaultSchema..GF.uElemType_RectangleInterior  Or
               v_elem_type = &&defaultSchema..GF.uElemType_CircularArc        Or
               v_elem_type = &&defaultSchema..GF.uElemType_PolyCircularArc    Or
               v_elem_type = &&defaultSchema..GF.uElemType_PolyCircularArcExt Or
               v_elem_type = &&defaultSchema..GF.uElemType_PolyCircularArcInt Or
               v_elem_type = &&defaultSchema..GF.uElemType_Circle             Or
               v_elem_type = &&defaultSchema..GF.uElemType_CircleExterior     Or
               v_elem_type = &&defaultSchema..GF.uElemType_CircleInterior     ) Then
             FOR rec IN c_points(p_arc2chord) LOOP
               v_Coord := rec.point;
               PIPE ROW( rec.point );
             END LOOP;
          ElsIf ( v_elem_type = &&defaultSchema..GF.uElemType_LineString      Or
                  v_elem_type = &&defaultSchema..GF.uElemType_Polygon         Or
                  v_elem_type = &&defaultSchema..GF.uElemType_PolygonExterior Or
                  v_elem_type = &&defaultSchema..GF.uElemType_PolygonInterior ) Then
            v_CoordToProcess := &&defaultSchema..GF.FirstCoordinate();
            <<coordinate_access_loop>>
            While v_CoordToProcess LooP
              v_Coord := &&defaultSchema..GF.GetCoordinate();
              PIPE ROW( v_Coord );
              v_CoordToProcess := &&defaultSchema..GF.NextCoordinate();
            End Loop coordinate_access_loop;
          End If;
          v_partToProcess := &&defaultSchema..GF.NextElement();
        End Loop element_access_loop;
      End If;
    End If;
    Return ;
  End GetPointSet;

  function isSimple (
    p_geometry  in MDSYS.SDO_Geometry,
    p_tolerance in number )
    return integer
  Is
    v_isSimple integer := 0;
    v_Ok       number;
    v_version  number;
  Begin
    v_version := DBMS_DB_VERSION.VERSION;
    If ( v_version < 10 ) Then
      <<process_via_gtype>>
      case
      when MOD(p_geometry.sdo_gtype,10) = 1 then
        v_isSimple := 0;
      when MOD(p_geometry.sdo_gtype,10) = 5 then
        select case count(*) when 0 then 1 else 0 end
          into v_isSimple
          from (select t.x, t.y, count(*)
                  from TABLE(&&defaultSchema..GEOM.GetPointSet(p_geometry)) t
                group by t.x, t.y
                having count(*) > 1);
      when MOD(p_geometry.sdo_gtype,10) in (2,6) then
        -- First check if first and last point are the same
        select case count(*) when 0 then 1 else 0 end
          into v_isSimple
          from (select t.x, t.y, count(*)
                  from TABLE(&&defaultSchema..GEOM.GetPointSet(p_geometry)) t
                group by t.x, t.y
                having count(*) > 1);
        Begin
          -- Can only use this if Enterprise Edition and SDO, or 12c and above
          SELECT 1
            INTO v_Ok
            FROM v$version
           WHERE v_version >= 12
             OR ( banner like '%Enterprise Edition%'
                   AND EXISTS (SELECT 1
                                 FROM all_objects ao
                                WHERE ao.owner       = 'MDSYS'
                                  AND ao.object_type = 'TYPE'
                                  AND ao.object_name = 'SDO_GEORASTER'
                               )
                );
          IF (v_OK = 1) THEN
            SELECT case count(*) when 0 then 1 else 0 end
              INTO v_isSimple
              FROM (SELECT t.x, t.y, count(*)
                      FROM (select MDSYS.SDO_GEOM.SDO_INTERSECTION(p_geometry,p_geometry,p_tolerance) as geometry from dual) k,
                           TABLE(&&defaultSchema..GEOM.GetPointSet(k.GEOMETRY)) t
                     GROUP BY t.x, t.y
                     HAVING count(*) > 1);
          ELSE
            raise_application_error(-20001,'Not licensed for use of sdo_difference/sdo_aggr_union',true);
          END IF;
          EXCEPTION
            WHEN OTHERS THEN
              raise_application_error(-20001,'Not licensed for use of sdo_difference/sdo_aggr_union',true);
              RETURN -1;
        End;
      when MOD(p_geometry.sdo_gtype,10) in (3,7) Then
        select case MDSYS.SDO_GEOM.VALIDATE_GEOMETRY(p_geometry,p_tolerance) when 'TRUE' then 1 else 0 end
          into v_isSimple
          from dual;
      else
        raise_application_error(&&defaultSchema..Constants.c_i_isSimple,
                                &&defaultSchema..Constants.c_s_isSimple,TRUE);
      end case process_via_gtype;
    Else
      -- We have to do it this way because won't compile on 9i databases.
      Execute Immediate 'select mdsys.st_geometry.from_sdo_geom(:1).ST_issimple() from dual'
                  Into v_isSimple
                 Using p_geometry;
    End If;
    return v_isSimple;
  End isSimple;

  function isSimple (
    p_geometry in MDSYS.SDO_geometry,
    p_dimarray in MDSYS.SDO_Dim_Array )
    return integer
  Is
    v_tolerance number;
  Begin
    v_tolerance := p_dimarray(1).sdo_tolerance;
    return isSimple(p_geometry,v_tolerance);
  End isSimple;

  Function To_2D( p_geom IN MDSYS.SDO_Geometry )
    Return MDSYS.SDO_Geometry
  Is
    v_gtype           INTEGER;     -- geometry type (single digit)
    v_dim             INTEGER;
    v_2D_geom         MDSYS.SDO_Geometry;
    v_npoints         INTEGER;
    v_i               PLS_INTEGER;
    v_j               PLS_INTEGER;
    v_offset          PLS_INTEGER;
  Begin
    -- If the input geometry is null, just return null
    IF p_geom IS NULL THEN
      RETURN (NULL);
    END IF;

    -- Get the number of dimensions and the gtype
    v_dim   := GetDimensions(p_geom.sdo_gtype);
    v_gtype := MOD(p_geom.sdo_gtype,10); -- Short gtype

    IF v_dim = 2 THEN
      -- Nothing to do, p_geom is already 2D
      RETURN (p_geom);
    END IF;

    -- Construct output object ...
    v_2D_geom           :=  MDSYS.SDO_GEOMETRY (2000 + v_gtype,
                             p_geom.sdo_srid,
                             p_geom.sdo_point,
                             p_geom.sdo_elem_info,
                             MDSYS.sdo_ordinate_array ()
                            );

    -- Does geometry have a valid sdo_point?
    If ( V_2d_Geom.Sdo_Point Is Not Null ) Then
      -- It's a point - possibly with sdo_ordinates.... fix this first...
      V_2d_Geom.Sdo_Point.Z := Null;
    End If;
    If ( V_Gtype = 1 And P_Geom.Sdo_Ordinates Is Not Null ) Then
      V_2d_Geom.Sdo_Ordinates := P_Geom.Sdo_Ordinates;
      v_2D_Geom.Sdo_Ordinates.Trim(1);
    ElsIF ( v_gtype != 1 AND v_2D_geom.sdo_ordinates is not null ) THEN
      -- Compute number of points
      v_npoints := p_geom.sdo_ordinates.COUNT / v_dim;

      -- It's not a single point ...
      -- Process the geometry's ordinate array
      v_2D_geom.sdo_ordinates.EXTEND ( v_npoints * 2 );
      -- Copy the ordinates array
      v_i := p_geom.sdo_ordinates.FIRST;      -- index into input ordinate array
      v_j := 1;                               -- index into output ordinate array
      FOR i IN 1 .. v_npoints LOOP
        v_2D_geom.sdo_ordinates (v_j)     := p_geom.sdo_ordinates (v_i);      -- copy X
        v_2D_geom.sdo_ordinates (v_j + 1) := p_geom.sdo_ordinates (v_i + 1);  -- copy Y
        v_i := v_i + v_dim;
        v_j := v_j + 2;
      END LOOP;

      -- Process the element info array
      -- by adjust the offsets
      v_i := v_2D_geom.sdo_elem_info.FIRST;
      WHILE v_i < v_2D_geom.sdo_elem_info.LAST LOOP
            If Not ( isCompoundElement(v_2D_geom.sdo_elem_info (v_i + 1) ) ) Then
              -- Adjust Elem Info offsets
              v_offset := v_2D_geom.sdo_elem_info (v_i);
              v_2D_geom.sdo_elem_info(v_i) := (v_offset - 1) / v_dim * 2 + 1;
            End If;
            v_i := v_i + 3;
      END LOOP;

    END IF;
    RETURN v_2D_geom;
  END To_2D;

  Function DownTo_3D( p_geom  IN MDSYS.SDO_Geometry,
                      p_z_ord IN INTEGER )
    Return MDSYS.SDO_GEOMETRY
  Is
    v_gtype            INTEGER;     -- geometry type (single digit)
    v_dim              INTEGER;
    V_Npoints          Integer;
    v_measure_ord      Integer;
    v_offset           PLS_INTEGER;
    v_count            PLS_Integer;
    v_coord            PLS_INTEGER;
    v_coords           MDSYS.VERTEX_SET_TYPE;
    v_3D_geom          MDSYS.SDO_Geometry := p_geom;
    INVALID_Z_ORDINATE EXCEPTION;
    /** Test...
select c.threed_geom, c.lrs_geom, geom.downto_3d(c.lrs_geom,3) as downtoGeom
  from (select MDSYS.SDO_LRS.CONVERT_TO_LRS_GEOM( threed_geom, 1, 10) as lrs_geom, threed_geom
          from (select geom.to_3d( a.original_geom, -1, -200, 0.05) as threed_geom
                 from ( select mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,5,5,10,10)) as original_geom
                         from dual
                      ) a
              ) b
      ) c;
      **/
  Begin
    Begin
        -- If the input geometry is null, just return null
        IF ( p_geom IS NULL ) THEN
          RETURN NULL;
        END IF;
        IF ( p_z_ord not in (3,4) ) THEN
           raise INVALID_Z_ORDINATE;
        END IF;

        -- Get the number of dimensions
        --
        v_dim := Trunc(p_geom.sdo_gtype/1000,0);

        IF ( v_dim <= 3 ) THEN
          -- Nothing to do, p_geom is already 3D
          Return (p_geom);
        END IF;

        -- If Single Point, nothing to do ...
        If ( p_geom.sdo_ordinates Is Null ) Then
          return p_geom;
        End If;

        -- Construct output object ...
        v_gtype   := MOD(p_geom.sdo_gtype,10); -- Short gtype
        v_measure_ord := Mod(Trunc(p_geom.Sdo_Gtype/100),10);
        if ( v_measure_ord = p_z_ord ) Then
           v_measure_ord := 3;
        else
           v_measure_ord := 0;
        End If;
        v_3D_geom.sdo_gtype := 3000 + (v_measure_ord*100) + v_gtype;
        v_3D_geom.sdo_ordinates := MDSYS.sdo_ordinate_array ();

        -- Compute number of points
        v_npoints := mdsys.sdo_util.GetNumVertices(p_geom);
        -- Create space in ordinate array for 3D coordinates
        v_3D_geom.sdo_ordinates.EXTEND ( v_npoints * 3 );

        v_coord := 1;
        V_Coords := Mdsys.Sdo_Util.GetVertices(P_Geom);
        For i in 1..v_coords.COUNT Loop
          V_3d_Geom.Sdo_Ordinates (v_coord)     := v_coords(i).X;
          v_3D_geom.sdo_ordinates (v_coord + 1) := v_coords(i).y;
          V_3d_Geom.Sdo_Ordinates (v_coord + 2) := case when p_z_ord = 3 then v_coords(i).z else v_coords(i).w end;
          v_coord := v_coord + 3;
        END LOOP;

        -- Process the element info array and adjust the offsets
        V_Count := 1;
        V_Offset := 0;
        For v_i in v_3D_geom.sdo_Elem_Info.First .. v_3D_geom.sdo_Elem_Info.Last Loop
              -- IsCompoundElement?
              If ( Mod(v_count,3) = 1 ) Then -- Ordinate count to adjust
                 -- Adjust Elem Info offsets
                 If Not ( v_3D_geom.sdo_Elem_Info (V_I + 1) In (4,5,1005,2005) ) Then
                    V_Offset := v_3D_geom.sdo_Elem_Info (V_I);
                    v_3D_geom.sdo_elem_info(v_i) := ( v_offset - 1 ) / v_dim * 3 + 1;
                 End If;
              End If;
              v_count := v_count + 1;
        End Loop;

        EXCEPTION
          WHEN INVALID_Z_ORDINATE THEN
            dbms_output.put_line('p_z_ord should be between (3,4)');
      End;
      RETURN v_3d_geom;
  End DownTo_3D;

   Function To_3D(p_geom      IN MDSYS.SDO_Geometry,
                  p_start_z   IN NUMBER := NULL,
                  p_end_z     IN NUMBER := NULL,
                  p_tolerance IN NUMBER := 0.05)
     Return MDSYS.SDO_Geometry
  Is
    v_gtype             INTEGER;     -- geometry type (single digit)
    v_dim               INTEGER;
    V_Npoints           Integer;
    v_count             PLS_Integer;
    v_coords            MDSYS.VERTEX_SET_TYPE;
    v_i                 PLS_INTEGER;
    v_j                 PLS_INTEGER;
    v_offset            PLS_INTEGER;
    v_length            NUMBER := 0;
    v_cumulative_length NUMBER := 0;
    v_round_factor      NUMBER := case when p_tolerance is null
                                       then null
                                       else round(log(10,(1/p_tolerance)/2))
                                   end;
    v_3D_geom           MDSYS.SDO_Geometry;

    /* **** Test Data
     *  select sdo_geom.validate_geometry(d.geom_3d,0.05)
     *    from (select geom.to_3d(c.lrs_geom,null,null,0.05) as geom_3d, c.threed_geom
     *            from (select MDSYS.SDO_LRS.CONVERT_TO_LRS_GEOM( threed_geom, 1, 10) as lrs_geom, threed_geom
     *                    from (select geom.to_3d( a.original_geom, -1, -200, 0.05) as threed_geom
     *                            from ( select mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,5,5,10,10)) as original_geom
     *                                     from dual
     *                                 ) a
     *                          ) b
     *                 ) c
     *          ) d;
     */

  Begin
    -- If the input geometry is null, just return null
    IF ( p_geom IS NULL ) THEN
      RETURN NULL;
    END IF;

    -- Get the number of dimensions and the gtype
    v_dim        := Trunc(p_geom.sdo_gtype/1000,0);
    v_gtype      := MOD(p_geom.sdo_gtype,10); -- Short gtype

    IF ( v_dim = 3 ) THEN
      -- Nothing to do, p_geom is already 3D
      Return (p_geom);
    ElsIf ( v_dim = 4 ) Then
      Return DownTo_3D(p_geom,3);
    END IF;

    If ( P_Start_Z Is Not Null And P_End_Z Is Not Null ) Then
       v_length := MDSYS.SDO_GEOM.SDO_LENGTH( p_geom, p_tolerance );
    END IF;

    -- Compute number of points
    v_npoints := mdsys.sdo_util.GetNumVertices(p_geom);

    -- Construct output object ...
    v_3D_geom           := MDSYS.SDO_GEOMETRY (3000 + v_gtype,
                             p_geom.sdo_srid,
                             p_geom.sdo_point,
                             p_geom.sdo_elem_info,
                             MDSYS.sdo_ordinate_array ()
                           );

    -- Does geometry have a valid sdo_point?
    IF ( v_3D_geom.sdo_point is not null ) Then
      -- It's a point, there's not much to it...
      v_3D_geom.sdo_point.Z := p_start_z;
    END IF;

    -- If Single Point, all done, else...
    If ( V_3d_Geom.Sdo_Elem_Info Is Null ) Then
      return v_3d_geom;
    End If;

    -- It's not a single point ...
    -- Process the geometry's ordinate array

    -- Create space in ordinate array for 3D coordinates
    v_3D_geom.sdo_ordinates.EXTEND ( v_npoints * 3 );

    -- Copy the ordinates array
    -- index into output ordinate array
    V_J := 1;
    V_Cumulative_Length := 0;
    V_Coords := Mdsys.Sdo_Util.GetVertices(P_Geom);
    For i in 1..v_coords.COUNT Loop
      V_3d_Geom.Sdo_Ordinates (V_J)        := v_coords(i).X;
      v_3D_geom.sdo_ordinates (v_j + 1)    := v_coords(i).y;
      -- Compute new Z
      If ( i = 1 ) Then
         V_3d_Geom.Sdo_Ordinates (V_J + 2) := P_Start_Z;
      Elsif ( I = V_Coords.Count ) Then
         V_3d_Geom.Sdo_Ordinates (V_J + 2) := P_End_Z;
      Else
          If ( v_length <> 0 ) Then
            v_cumulative_length := v_cumulative_length +
               round(sdo_geom.sdo_distance(mdsys.sdo_geometry(2001,P_Geom.Sdo_Srid,sdo_point_type(v_coords(i).x,v_coords(i).y,v_coords(i).z),null,null),
                                           mdsys.sdo_geometry(2001,P_Geom.Sdo_Srid,Sdo_Point_Type(V_Coords(i+1).X,V_Coords(i+1).Y,v_coords(i+1).z),null,null),
                                           p_tolerance),
                     v_round_factor);
          End If;
          v_3D_geom.sdo_ordinates (v_j + 2) := case when p_end_z is null then p_start_z
                                                    when v_length != 0   then p_start_z + round( ( ( p_end_z - p_start_z ) / v_length ) * v_cumulative_length,v_round_factor)
                                                    else p_start_z
                                                end;
      End If;
      v_j := v_j + 3;
    END LOOP;
    -- Process the element info array
    -- by adjust the offsets
    V_Count := 1;
    V_Offset := 0;
    For v_i in v_3D_geom.sdo_Elem_Info.First .. v_3D_geom.sdo_Elem_Info.Last Loop
          -- IsCompoundElement?
          If ( Mod(v_count,3) = 1 ) Then -- Ordinate count to adjust
             -- Adjust Elem Info offsets
             If Not ( v_3D_geom.sdo_Elem_Info (V_I + 1) In (4,5,1005,2005) ) Then
                V_Offset := v_3D_geom.sdo_Elem_Info (V_I);
                v_3D_geom.sdo_elem_info(v_i) := ( v_offset - 1 ) / v_dim * 3 + 1;
             End If;
          End If;
          v_count := v_count + 1;
    End Loop;

    Return V_3d_Geom;
  End To_3d;

  Function Fix_3D_Z( p_3D_geom   IN MDSYS.SDO_Geometry,
                     p_default_z IN NUMBER := -9999 )
           Return MDSYS.SDO_Geometry
  Is
    v_3D_geom     MDSYS.SDO_GEOMETRY := p_3D_geom;
    v_dim_count   integer; -- number of dimensions in layer
    v_gtype       integer; -- geometry type (single digit)
    v_n_points    integer; -- number of points in ordinates array
    i             integer;
  begin
    -- If the input geometry is null, just return null
    if v_3D_geom is null then
      return (null);
    end if;

    -- Get the number of dimensions from the v_gtype
    if ( length (v_3D_geom.sdo_gtype) = 4 ) then
      v_dim_count := substr (v_3D_geom.sdo_gtype, 1, 1);
      v_gtype     := substr (v_3D_geom.sdo_gtype, 4, 1);
    else
      -- Indicate failure
      RAISE_APPLICATION_ERROR ( &&defaultSchema..CONSTANTS.c_i_dimensionality,
                        REPLACE(&&defaultSchema..CONSTANTS.c_s_dimensionality,':1',to_char(v_3D_geom.sdo_gtype)));
    end if;

    if ( v_dim_count <> 3 ) then
      -- Nothing to do, geometry is not 3D
      return (v_3D_geom);
    end if;

    -- Process the point structure
    if ( v_3D_Geom.sdo_point is not null ) then
      if ( v_3D_Geom.sdo_point.z is null) then
        v_3D_Geom.SDO_Point.Z := p_default_z;
      end if;
    end if;

    v_n_points := v_3D_geom.sdo_ordinates.count / v_dim_count;
    -- Process object replacing NULL Z values with p_default_z
    for i in 1..v_n_points loop
      IF ( v_3D_Geom.sdo_ordinates ( i * v_dim_count ) is null ) THEN
        v_3D_geom.sdo_ordinates ( i * v_dim_count ) := p_default_z;
      END IF;
    end loop;

    return v_3D_Geom;
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('Error ('|| SQLCODE ||') of ' || SQLERRM(SQLCODE) );
        RETURN v_3D_Geom;
  END Fix_3D_Z;

  Function ToSdoPoint( p_geometry IN MDSYS.SDO_GEOMETRY )
    RETURN MDSYS.SDO_GEOMETRY
    IS
     v_element         number;
     v_elements        number;
     v_geometry        MDSYS.SDO_Geometry;
     v_SdoPoint        MDSYS.SDO_Point_Type := MDSYS.SDO_Point_Type(0,0,NULL);
     v_Ordinates       MDSYS.SDO_Ordinate_Array;
  Begin
    IF ( MOD(p_geometry.sdo_gtype,10) not in (1,5) ) Then
      v_geometry := NULL;
    ELSIF p_geometry.sdo_point is not null THEN
      v_geometry := mdsys.sdo_geometry(p_geometry.sdo_gtype,p_geometry.sdo_srid,p_geometry.sdo_point,NULL,NULL);
    ELSE
      v_ordinates  := p_geometry.sdo_ordinates;
      v_SdoPoint.X := v_ordinates(1);
      v_SdoPoint.Y := v_ordinates(2);
      IF ( FLOOR(p_geometry.sdo_gtype/1000) = 3 ) THEN
        v_SdoPoint.Z := v_ordinates(3);
      END IF;
      v_geometry := mdsys.sdo_geometry(p_geometry.sdo_gtype,p_geometry.sdo_srid,v_SdoPoint,NULL,NULL);
    END IF;
    RETURN v_geometry;
  END ToSdoPoint;

  Function ExtractPolygon9i( p_geometry IN MDSYS.SDO_GEOMETRY, p_dimarray IN MDSYS.SDO_DIM_ARRAY )
    RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC
    IS
     v_dim             number;
     v_offset          number;
     v_gtype           number;
     v_new_gtype       number;
     v_elem_info       &&defaultSchema..T_ElemInfo := &&defaultSchema..T_ElemInfo(NULL,NULL,NULL);
     v_Coord4D         &&defaultSchema..ST_Point   := &&defaultSchema..ST_Point(&&defaultSchema..Constants.c_MaxVal,&&defaultSchema..Constants.c_MaxVal);
     v_SdoPoint        MDSYS.SDO_Point_Type        := MDSYS.SDO_Point_Type(NULL,NULL,NULL);
     v_new_elem_info   mdsys.sdo_elem_info_array;
     v_new_shape       mdsys.sdo_geometry;
     v_new_ordinates   mdsys.sdo_ordinate_array;
     v_partToProcess   boolean;
     v_coordToProcess  boolean;
  Begin
    IF ( MOD(p_geometry.sdo_gtype,10) <> 4 ) Then
       RETURN p_geometry;
    END IF;
    v_new_elem_info := mdsys.sdo_elem_info_array();
    v_new_ordinates := mdsys.sdo_ordinate_array();
    &&defaultSchema..GF.New;
    &&defaultSchema..GF.SetGeometry( p_geometry );
    v_dim   := &&defaultSchema..GF.GetDimension();
    v_gtype := &&defaultSchema..GF.GetGType();
    v_new_gtype := 0;
    v_offset    := 1;
    v_partToProcess := &&defaultSchema..GF.FirstElement();
    <<while_part_to_process>>
    While v_partToProcess Loop
      v_elem_info := &&defaultSchema..GF.GetElemInfo();
      IF ( v_elem_info.etype in (1003,2003) and v_elem_info.interpretation = 1 ) Then
        IF ( v_elem_info.etype = 1003 AND v_new_gtype = (( v_dim * 1000 ) + 3) ) Then
          v_new_gtype := ( v_dim * 1000) + 7;
        ELSE
          v_new_gtype := ( v_dim * 1000) + 3;
        END IF;
        ADD_Element( v_new_elem_info, v_offset, v_elem_info.etype, v_elem_info.interpretation );
        v_coordToProcess := &&defaultSchema..GF.FirstCoordinate();
        <<while_coord_to_process>>
        WHILE v_coordToProcess LOOP
          v_Coord4D := &&defaultSchema..GF.GetCoordinate();
          v_offset  := v_offset + v_dim;
          ADD_Coordinate( v_new_ordinates, v_dim, v_Coord4D );
          v_coordToProcess := &&defaultSchema..GF.NextCoordinate();
        End Loop while_coord_to_process;
      End If;
      v_partToProcess := &&defaultSchema..GF.NextElement();
    End Loop while_part_to_process;
    If ( v_new_gtype = 0 ) Then
      Return( NULL );
    Else
      Return( MDSYS.SDO_Geometry(v_new_gtype,
                                 p_geometry.sdo_srid,
                                 p_geometry.sdo_point,
                                 v_new_elem_info,
                                 v_new_ordinates) );
    End If;
  End ExtractPolygon9i;

  Function ExtractPolygon( p_geometry IN MDSYS.SDO_GEOMETRY )
    RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC
    IS
     v_element         number;
     v_elements        number;
     v_geometry        mdsys.sdo_geometry;
     v_extract_shape   mdsys.sdo_geometry;
  Begin
    IF ( MOD(p_geometry.sdo_gtype,10) <> 4 ) Then
       RETURN p_geometry;
    END IF;
    v_elements := GetNumElem(p_geometry);
    FOR v_element IN 1..v_elements LOOP
      v_extract_shape := mdsys.sdo_util.Extract(p_geometry,v_element,0);   -- Extract element with all sub-elements
      IF ( v_extract_shape.Get_Gtype() = 3 ) Then
        IF ( v_geometry is null ) Then
           v_geometry := v_extract_shape;
        ELSE
           v_geometry := Append(v_geometry,v_extract_shape);
        END IF;
      END IF;
    END LOOP;
    RETURN( v_geometry );
  END ExtractPolygon;

  Function ExtractLine( p_geometry IN MDSYS.SDO_GEOMETRY )
    RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC
    IS
     v_element         number;
     v_elements        number;
     v_geometry        mdsys.sdo_geometry;
     v_extract_shape   mdsys.sdo_geometry;
  Begin
    IF ( MOD(p_geometry.sdo_gtype,10) <> 4 ) Then
       RETURN p_geometry;
    END IF;
    v_elements := GetNumElem(p_geometry);
    FOR v_element IN 1..v_elements LOOP
      v_extract_shape := mdsys.sdo_util.Extract(p_geometry,v_element,0);   -- Extract element with all sub-elements
      IF ( v_extract_shape.Get_Gtype() = 2 ) Then
        IF ( v_geometry is null ) Then
           v_geometry := v_extract_shape;
        ELSE
           If ( DBMS_DB_VERSION.VERSION < 10 ) Then
             v_geometry := Append(v_geometry,v_extract_shape);
           Else
             EXECUTE IMMEDIATE 'SELECT mdsys.SDO_UTIL.CONCAT_LINES(:1,:2) FROM DUAL'
                     INTO v_geometry
                     USING v_geometry,v_extract_shape;
           End If;
        END IF;
      END IF;
    END LOOP;
    RETURN( v_geometry );
  END ExtractLine;

  Function ExtractPoint( p_geometry IN MDSYS.SDO_GEOMETRY )
    RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC
    IS
     v_element         number;
     v_elements        number;
     v_geometry        MDSYS.SDO_Geometry;
     v_extract_shape   MDSYS.SDO_Geometry;
  Begin
    IF ( MOD(p_geometry.sdo_gtype,10) <> 4 ) Then
      v_geometry := p_geometry;
    ELSE
      v_elements := GetNumElem(p_geometry);
      FOR v_element IN 1..v_elements LOOP
        v_extract_shape := mdsys.sdo_util.Extract(p_geometry,v_element,0);   -- Extract element with all sub-elements
        IF ( v_extract_shape.Get_Gtype() = 1 ) Then
          IF ( v_geometry is null ) Then
             v_geometry := v_extract_shape;
          ELSE
             v_geometry := Append(v_geometry,v_extract_shape);
          END IF;
        END IF;
      END LOOP;
    END IF;
    RETURN v_geometry;
  END ExtractPoint;

  -- @function    : Extract
  -- @description : Public wrapper classes for private ExtractPoint, ExtractLine, ExtractPolygon functions
  --
  Function ExtractGeometry( p_GeometryType IN VARCHAR2,
                            p_geometry     IN MDSYS.SDO_GEOMETRY )
    RETURN MDSYS.SDO_GEOMETRY
  IS
    v_geometry  MDSYS.SDO_GEOMETRY;
  Begin
    IF ( UPPER(p_GeometryType) IN ('LINE','LINESTRING','MULTILINE','MULTILINESTRING') ) Then
      v_geometry := ExtractLine(p_geometry);
    ELSIF ( UPPER(p_GeometryType) IN ( 'POINT','MULTIPOINT' ) ) Then
      v_geometry := ExtractPoint(p_geometry);
    ELSIF ( UPPER(p_GeometryType) in ('POLY','POLYGON','MULTIPOLY','MULTIPOLYGON') ) Then
      v_geometry := ExtractPolygon(p_geometry);
    END IF;
    RETURN v_geometry;
  END ExtractGeometry;

  /* @history    : Simon Greener - Dec 2009 - Made completely dependent on ExtractElementsPiped
  */
  Function ExtractElements(
    p_geometry    IN MDSYS.SDO_GEOMETRY,
    p_subElements IN number )  -- p_SubElements should be BOOLEAN
    RETURN &&defaultSchema..T_GeometrySet
    IS
     v_geometries &&defaultSchema..T_GeometrySet := &&defaultSchema..T_GeometrySet();
  Begin
    -- Reuse algorithm in ExtractElementsPiped
    --
    SELECT &&defaultSchema..T_Geometry(geometry=>g.geometry)
      BULK COLLECT INTO v_geometries
      FROM TABLE(&&defaultSchema..GEOM.ExtractElementsPiped(p_geometry,p_subElements)) g;
    RETURN( v_geometries );
  END ExtractElements;

  /* @history    : Simon Greener - Dec 2009 - Made PointSet take parameter correcting bug with handling ordinates of extracted geometry
  *                                         - Corrected handling of last point in a 3 point arc, interpretation 2, when extracting sub elements.
  */
  Function ExtractElementsPiped(
    p_geometry    IN MDSYS.SDO_GEOMETRY,
    p_subElements IN number )  -- p_SubElements should be BOOLEAN
    RETURN &&defaultSchema..T_GeometrySet pipelined
    IS
     v_i               PLS_INTEGER;
     v_count           PLS_INTEGER;
     v_dim             PLS_INTEGER;
     v_gtype           PLS_INTEGER;
     v_element         PLS_INTEGER;
     v_elements        PLS_INTEGER;
     v_subelem_count   PLS_INTEGER;
     v_subelement_geom mdsys.sdo_geometry;
     v_extract_geom    mdsys.sdo_geometry;
     v_ord_count       PLS_INTEGER;
     v_ordinates       mdsys.sdo_ordinate_array;
     v_vertices        &&defaultSchema..ST_PointSet     := &&defaultSchema..ST_PointSet();
     v_geometries      &&defaultSchema..T_GeometrySet := &&defaultSchema..T_GeometrySet();
     v_subelements     Boolean := case when p_subelements = 0 then false else true end;

     Procedure PointSet(p_geometry in mdsys.sdo_geometry)
     Is
     Begin
       If ( DBMS_DB_VERSION.VERSION < 10 ) Then
          SELECT &&defaultSchema..ST_Point(a.x,a.y,a.z,a.m)
            Bulk Collect into v_vertices
            FROM TABLE(&&defaultSchema..GEOM.GetPointSet(p_geometry)) a;
       Else
          EXECUTE IMMEDIATE '
SELECT &&defaultSchema..ST_Point(
               v.x,
               v.y,
               CASE WHEN :1 <> 3 THEN v.z ELSE NULL END,
               CASE WHEN :2 =  3 THEN v.z ELSE v.w END )
  FROM TABLE(sdo_util.GetVertices(:3)) v'
            BULK COLLECT INTO v_vertices
                      USING MOD(trunc(p_geometry.sdo_gtype/100),10),
                            MOD(trunc(p_geometry.sdo_gtype/100),10),
                            p_geometry;
       End If;
     End;

  Begin
    v_dim      := TRUNC(p_geometry.SDO_GType/1000);
    v_gtype    := MOD(p_geometry.SDO_GType,10 );
    v_elements := GetNumElem(p_geometry);
    IF ( ( v_gtype = 1 ) AND ( v_elements = 0 ) ) THEN
       -- ie single point geometry
       PIPE ROW (&&defaultSchema..T_Geometry(geometry=>P_geometry));

    ELSIF ( v_gtype = 5 ) THEN
       -- ie multipoint
       PointSet(p_geometry);
       <<for_all_vertices>>
       FOR v_i IN v_vertices.FIRST..v_vertices.LAST LOOP
         PIPE ROW (&&defaultSchema..T_Geometry(geometry=>
                           mdsys.sdo_geometry(( v_dim * 1000 ) + 1,
                                              p_geometry.sdo_srid,
                                              mdsys.sdo_point_type(v_vertices(v_i).x,
                                                                   v_vertices(v_i).y,
                                                                   v_vertices(v_i).z),
                                              NULL,
                                              NULL)));
       END LOOP for_all_vertices;
    ELSE -- linestrings and polygons
       v_element := 0;
       <<while_all_elements>>
       WHILE ( v_element < v_elements ) LOOP
         v_element := v_element + 1;
         -- Extract element with all sub-elements
         v_extract_geom := mdsys.sdo_util.Extract(p_geometry,v_element,0);
         -- The rings of a polygon are subelements that Extract can handle.
         -- But if a ring is a compound object then Extract cannot handle it.
         -- We will leave the extraction of a ring as a whole polygon to ExtractPolygon
         -- Does user want to further break down geometry into its basic subElements?
         IF ( v_subelements ) THEN
            PointSet(v_extract_geom);
            -- Get count of all, irreduceable sub-elements
            SELECT COUNT(*)
              INTO v_count
              FROM TABLE(&&defaultSchema..GEOM.GetElemInfo(v_extract_geom)) e
             WHERE e.etype not in (4,1005,2005);
            IF ( v_count > 1 ) THEN
               v_ord_count := v_extract_geom.sdo_ordinates.COUNT;
               FOR rec IN (SELECT *
                             FROM (SELECT rownum as rin,
                                         i.etype,
                                         i.interpretation,
                                         (((i.offset-1)/2)+1) as first_coord,
                                         ((case when (lead(i.offset,1) over (order by i.id)) is not null
                                                then (lead(i.offset,1) over (order by i.id))
                                                else v_ord_count + 1
                                            end - 1) / v_dim) +
                                          (case when lag(i.etype,1) over (order by i.id) in (4,1005,2005)
                                                     or
                                                     i.interpretation = 2
                                                then 1
                                                else 0
                                            end) as last_coord
                                     FROM (SELECT rownum as id,
                                                  e.interpretation,
                                                  e.etype,
                                                  e.offset
                                             FROM TABLE(&&defaultSchema..GEOM.GetElemInfo(v_extract_geom)) e
                                           ) i
                                  ) o
                             WHERE o.etype not in (4,1005,2005)) LOOP
                    v_ordinates := mdsys.sdo_ordinate_array();
                    FOR v_i IN rec.first_coord..rec.last_coord LOOP
                        ADD_Coordinate(v_ordinates,v_dim,v_vertices(v_i));
                    END LOOP;
                    PIPE ROW (&&defaultSchema..T_Geometry(
                                geometry=>mdsys.sdo_geometry(2002,
                                                   p_geometry.sdo_srid,
                                                   null,
                                                   mdsys.sdo_elem_info_array(1,2,rec.interpretation),
                                                   v_ordinates)));
               END LOOP;
            ELSE
                -- Always write out a single element
                PIPE ROW (&&defaultSchema..T_Geometry( geometry=>v_extract_geom));
            END IF;
         ELSE
           IF ( v_gtype in (3,7) ) THEN
              SELECT COUNT(*)
                INTO v_count
                FROM TABLE(&&defaultSchema..GEOM.GetElemInfo(v_extract_geom)) e
               WHERE e.etype in (1003,2003,1005,2005);
              IF ( v_count > 1 ) THEN
                FOR v_subelem_count IN 1..v_count LOOP
                    v_subelement_geom := mdsys.sdo_util.extract(v_extract_geom,v_element,v_subelem_count);
                    PIPE ROW (&&defaultSchema..T_Geometry( geometry=>v_subelement_geom));
                END LOOP;
              ELSE
                -- Always write out a single element
                PIPE ROW (&&defaultSchema..T_Geometry( geometry=>v_extract_geom));
              END IF;
           ELSE
             -- Always write out the higher element
             PIPE ROW (&&defaultSchema..T_Geometry( geometry=>v_extract_geom));
           END IF;
         END IF;
       END LOOP while_all_elements;
    END IF;
    RETURN;
  END ExtractElementsPiped;

  /**
  * Dump          Extracts valid, individual geometries, from a geometry's elements and sub-elements
  *  Created:     10/12/2008
  *  Author:      Simon Greener
  *  Description: Mimicks PostGIS ST_Dump function.
  *               Is a wrapper over ExtractElementsPiped
  **/
  Function ST_Dump( p_geometry in MDSYS.SDO_GEOMETRY)
    Return &&defaultSchema..T_GeometrySet pipelined
  As
    TYPE t_geomCursor IS REF CURSOR;
    c_geoms   t_geomCursor;
    v_geom    mdsys.sdo_geometry;
  Begin
    OPEN c_geoms FOR 'SELECT e.geometry FROM TABLE(&&defaultSchema..GEOM.ExtractElementsPiped(:1,1)) e'
    USING p_geometry;
    LOOP
       FETCH c_geoms INTO v_geom;
       EXIT WHEN c_geoms%NOTFOUND;
       PIPE ROW (&&defaultSchema..T_Geometry(geometry=>v_geom));
    END LOOP;
    RETURN;
  End;

  Function AsEWKT( p_geometry in MDSYS.SDO_Geometry )
           Return CLOB
  Is
    v_NumFMT          varchar2(4000) := 'FM999999999999999999990.099999999999999999999';
    v_EWKT            CLOB;
    v_wkt             PLS_INTEGER;
    v_gtype           PLS_INTEGER;     -- geometry type (single digit)
    v_dim             PLS_INTEGER;
    v_elem_type       PLS_INTEGER;
    v_elem_info       &&defaultSchema..T_ElemInfo := &&defaultSchema..T_ElemInfo(NULL,NULL,NULL);
    v_Coord4D         &&defaultSchema..ST_Point   := &&defaultSchema..ST_Point(&&defaultSchema..Constants.c_MaxVal,&&defaultSchema..Constants.c_MaxVal);
    v_partToProcess   boolean;
    v_coordToProcess  boolean;
  Begin
    DBMS_LOB.CreateTemporary( v_EWKT, TRUE, DBMS_LOB.CALL );
    &&defaultSchema..GF.New;
    &&defaultSchema..GF.SetGeometry( p_geometry );
    -- Get the number of dimensions and the gtype
    v_dim   := &&defaultSchema..GF.GetDimension();
    v_gtype := &&defaultSchema..GF.GetGType();
    v_EWKT  := v_ADFSDOGeometries(v_gtype) || ' ' ||  v_ADFDimensions(v_dim) || ' (';
    If ( v_gtype = &&defaultSchema..GF.uGeomType_SinglePoint And
         p_geometry.sdo_point is not null ) Then
       v_EWKT := v_EWKT || To_Char( p_geometry.sdo_point.x, v_numFMT ) || ' ' ||
                           To_Char( p_geometry.sdo_point.y, v_numFMT )
                        || case when ( v_dim = 3 )
                                Then ' ' || To_Char( p_geometry.sdo_point.z, v_numFMT )
                                Else NULL
                            End
                        || ')' ;
    Else
      v_partToProcess := &&defaultSchema..GF.FirstElement();
      <<while_part_to_process>>
      While v_partToProcess Loop
        v_elem_type := &&defaultSchema..GF.GetElementGeomType();
        v_EWKT := v_EWKT || ' ' || v_ADFElements(v_elem_type) || '(';
        v_coordToProcess := &&defaultSchema..GF.FirstCoordinate();
        <<while_coord_to_process>>
        WHILE v_coordToProcess LOOP
          v_Coord4D := &&defaultSchema..GF.GetCoordinate();
          v_EWKT := v_EWKT || To_Char( v_Coord4D.x, v_numFMT ) || ' ' ||
                              To_Char( v_Coord4D.y, v_numFMT ) ||
                              case when ( v_Dim = 3 )
                                   then ' ' || case when v_Coord4D.z is null then 'NULL' else To_Char(v_Coord4D.z, v_numFMT) end
                                   else NULL
                               end ||
                              case when ( v_Dim = 4 )
                                   then ' ' || case when v_Coord4D.m is null then 'NULL' else To_Char(v_Coord4D.m, v_numFMT) end
                                   else null
                              end;
          v_coordToProcess := &&defaultSchema..GF.NextCoordinate();
          If ( v_CoordToProcess ) Then
            v_EWKT := v_EWKT || ', ';
          End If;
        End Loop while_coord_to_process;
        If Not ( &&defaultSchema..GF.isCompoundElement ) Then
          v_EWKT := v_EWKT || ')';
        End If;
        If ( &&defaultSchema..GF.IsCompoundElementChild     = True ) And
           ( &&defaultSchema..GF.IsLastCompoundElementChild = True ) Then
          v_EWKT := v_EWKT || ')';
        End If;
        v_partToProcess := &&defaultSchema..GF.NextElement();
      End Loop while_part_to_process;
      v_EWKT := v_EWKT || ' )';
    End If;
    Return v_EWKT;
  End AsEWKT;

  Function AsEWKT(
    p_GeomSet In &&defaultSchema..T_GeometrySet )
    Return CLOB
  IS
     v_MultiWKT CLOB;
     v_wkt      INTEGER;
  Begin
    SYS.DBMS_LOB.CreateTemporary( v_MultiWKT, TRUE, DBMS_LOB.CALL );
    FOR v_wkt IN p_GeomSet.FIRST..p_GeomSet.LAST LOOP
        SYS.DBMS_LOB.APPEND(v_MultiWKT,&&defaultSchema..GEOM.AsEWKT(p_GeomSet(v_wkt).geometry)||CHR(10));
    END LOOP;
    RETURN( v_MultiWKT );
  END AsEWKT;

  Function GetETypeAsGType( p_gtype in number, p_elem_gtype in number )
    Return Number
  Is
    v_gtype Number := Trunc(p_gtype / 10) * 10;
  Begin
      case p_elem_gtype
           when &&defaultSchema..CONSTANTS.uElemType_Point              then v_gtype := v_gtype + 1;
           when &&defaultSchema..CONSTANTS.uElemType_OrientationPoint   then v_gtype := v_gtype + 1;
           when &&defaultSchema..CONSTANTS.uElemType_LineString         Then v_gtype := v_gtype + 2;
           when &&defaultSchema..CONSTANTS.uElemType_CircularArc        then v_gtype := v_gtype + 2;
           when &&defaultSchema..CONSTANTS.uElemType_PolyCircularArc    then v_gtype := v_gtype + 2;
           when &&defaultSchema..CONSTANTS.uElemType_PolyCircularArcExt then v_gtype := v_gtype + 2;
           when &&defaultSchema..CONSTANTS.uElemType_PolyCircularArcInt then v_gtype := v_gtype + 2;
           when &&defaultSchema..CONSTANTS.uElemType_Rectangle          then v_gtype := v_gtype + 3;
           when &&defaultSchema..CONSTANTS.uElemType_RectangleExterior  then v_gtype := v_gtype + 3;
           when &&defaultSchema..CONSTANTS.uElemType_RectangleInterior  then v_gtype := v_gtype + 3;
           when &&defaultSchema..CONSTANTS.uElemType_Circle             then v_gtype := v_gtype + 3;
           when &&defaultSchema..CONSTANTS.uElemType_CircleExterior     then v_gtype := v_gtype + 3;
           when &&defaultSchema..CONSTANTS.uElemType_CircleInterior     Then v_gtype := v_gtype + 3;
           when &&defaultSchema..CONSTANTS.uElemType_Polygon            Then v_gtype := v_gtype + 3;
           when &&defaultSchema..CONSTANTS.uElemType_PolygonExterior    Then v_gtype := v_gtype + 3;
           when &&defaultSchema..CONSTANTS.uElemType_PolygonInterior    Then v_gtype := v_gtype + 3;
           when &&defaultSchema..CONSTANTS.uElemType_MultiPoint         then v_gtype := v_gtype + 5;
           else v_gtype := p_gtype;
      end case;
      Return v_gtype;
  End GetETypeAsGType;

  /** ***************************************************************
  *  ExplodeGeometry
  *  ***************************************************************
  *  Created:     17/12/2004
  *  Author:      Simon Greener
  *  Description: Breaks a geometry into its fundamenal elements which
  *               includes the breaking down of compound LineStrings or
  *               Polygons down into their individual subElements: returns
  *               children of compound elements as themselves; and all other
  *               elements as themselves.
  *  Note:        This function is for 8i and 9iR1. For 9iR2 and above use ExtractElements
  *               with p_subElements = 1 to get an equivalent output.
  **/
  Function ExplodeGeometry(p_geometry in MDSYS.SDO_Geometry)
    RETURN &&defaultSchema..T_GeometrySet pipelined
  Is
    sProcID            constant varchar2(256) := c_module_name || '.ExplodeGeometry';
    v_j                binary_integer;
    v_lCoordMax        binary_integer;
    v_bConverted       boolean;
    v_lStartOrdinate   binary_integer;
    v_lOrdinateLBound  binary_integer;
    v_lOrdinateUBound  binary_integer;
    v_lPartVertexCount binary_integer;
    v_partToProcess    boolean;
    v_ElemInfo         MDSYS.SDO_Elem_Info_Array;
    v_Ordinates        MDSYS.SDO_Ordinate_Array;
    v_gtype            Number;
  Begin
    &&defaultSchema..GF.New;
    &&defaultSchema..GF.SetGeometry(p_geometry);
    If (&&defaultSchema..GF.IsNullGeometry) Then
      Return;
    End If;
    v_gtype := &&defaultSchema..GF.GetFullGType();
    v_partToProcess := &&defaultSchema..GF.FirstElement();
    <<while_part_to_process>>
    While v_partToProcess Loop
      If Not ( &&defaultSchema..GF.isCompoundElement ) Then
        v_lCoordMax := &&defaultSchema..GF.GetElementCoordinateCount();
        If v_lCoordMax <> 0 Then
          v_lOrdinateLBound := &&defaultSchema..GF.GetStartOffset();
          v_lOrdinateUBound := &&defaultSchema..GF.GetEndOffset();
          v_Ordinates := &&defaultSchema..GF.GetElementOrdinates(v_lOrdinateLBound,v_lOrdinateUBound);
          v_ElemInfo  := &&defaultSchema..GF.GetElemInfoArray();
          v_ElemInfo(1) := 1;
          PIPE ROW (&&defaultSchema..T_Geometry(geometry=>
                    MDSYS.SDO_Geometry(GetETypeAsGType( v_gtype, &&defaultSchema..GF.GetElementGeomType() ),
                                       p_geometry.sdo_srid,
                                       NULL,
                                       v_ElemInfo,
                                       v_Ordinates))
                   );
        Else
          raise_application_error(&&defaultSchema..Constants.c_i_coordinate_read,sProcID ||
                           ' : '||&&defaultSchema..Constants.c_s_coordinate_read,TRUE);
        End If;
      End If;
      v_partToProcess := &&defaultSchema..GF.NextElement();
    End Loop while_part_to_process;
    -- Set GF.asPolyline := v_aPolyLine;
    return;
  End ExplodeGeometry;

  /* @history    : Simon Greener - Dec 2009 - Fixed SRID handling bug for Geodetic data.
  */
  procedure Split( p_line      in mdsys.sdo_geometry,
                   p_point     in mdsys.sdo_geometry,
                   p_tolerance in number,
                   p_out_line1 out nocopy mdsys.sdo_geometry,
                   p_out_line2 out nocopy mdsys.sdo_geometry )
  As
    cursor c_vectors(p_geometry in mdsys.sdo_geometry) Is
    select rownum as id,
           b.startcoord.x as x1,
           b.startcoord.y as y1,
           b.endcoord.x as x2,
           b.endcoord.y as y2
      from table(&&defaultSchema..GEOM.GetVector2D(p_geometry)) b;
    v_gtype          number;
    v_part           number;
    v_element        number;
    v_num_elements   number;
    v_vector_id      number;
    v_start_distance number;
    v_x1             number;
    v_y1             number;
    v_end_distance   number;
    v_x2             number;
    v_y2             number;
    v_line_distance  number;
    v_ratio          number;
    v_geometry       mdsys.sdo_geometry;
    v_extract_geom   mdsys.sdo_geometry;
    v_geom_part      mdsys.sdo_geometry;
    v_min_dist       number;
    v_dist           number;
    v_vector_1       &&defaultSchema..T_Vector2d := &&defaultSchema..T_Vector2d(
                                                      &&defaultSchema..T_Coord2D(&&defaultSchema..Constants.c_MinVal,&&defaultSchema..Constants.c_MinVal),
                                                      &&defaultSchema..T_Coord2D(&&defaultSchema..Constants.c_MinVal,&&defaultSchema..Constants.c_MinVal));
    v_vector_2       &&defaultSchema..T_Vector2d := &&defaultSchema..T_Vector2d(
                                                      &&defaultSchema..T_Coord2D(&&defaultSchema..Constants.c_MinVal,&&defaultSchema..Constants.c_MinVal),
                                                      &&defaultSchema..T_Coord2D(&&defaultSchema..Constants.c_MinVal,&&defaultSchema..Constants.c_MinVal));
    NULL_GEOMETRY    EXCEPTION;
    NOT_A_LINE       EXCEPTION;
    NOT_A_POINT      EXCEPTION;
    NULL_TOLERANCE   EXCEPTION;
  begin
    -- Check inputs
    If ( p_point is NULL or p_line is NULL ) Then
       raise NULL_GEOMETRY;
    End If;
    v_gtype := MOD(p_line.Sdo_GType,10);
    If ( v_gtype not in (2,6) ) Then
       RAISE NOT_A_LINE;
    End If;
    v_gtype := MOD(p_point.Sdo_GType,10);
    If ( MOD(p_point.Sdo_Gtype,10) <> 1 ) Then
       RAISE NOT_A_POINT;
    End If;
    if ( p_tolerance is null ) Then
       RAISE NULL_TOLERANCE;
    End If;

    -- Check number of elements in input line
    v_num_elements := GetNumElem(p_line);
    If ( v_num_elements = 1 ) Then
       v_geometry := p_line;
       v_part     := 1;
    Else
       v_min_dist := 999999999999.99999999;  -- All distances should be less than this
       <<for_all_vertices>>
       FOR v_element IN 1..v_num_elements LOOP
         v_extract_geom := mdsys.sdo_util.Extract(p_line,v_element);   -- Extract element with all sub-elements
         v_dist := MDSYS.SDO_GEOM.SDO_DISTANCE(v_extract_geom,p_point,p_tolerance);
         If ( v_dist < v_min_dist ) Then
            -- dbms_output.put_line('Assigning element || ' || v_element || ' to v_geometry');
            v_geometry := v_extract_geom;
            v_min_dist := v_dist;
            v_part     := v_element;
         End If;
       END LOOP for_all_elements;
    End If;

    -- We have the line geometry for splitting in v_geometry
    -- Find the vector in v_geometry that will be split
    --
    select id,startdist,x1,y1,enddist,x2,y2,linedist,startdist/(startdist+enddist) as ratio
      into v_vector_id,
           v_start_distance,
           v_x1,
           v_y1,
           v_end_distance,
           v_x2,
           v_y2,
           v_line_distance,
           v_ratio
      from (select rownum as id,
                   b.startcoord.x as x1,
                   b.startcoord.y as y1,
                   b.endcoord.x as x2,
                   b.endcoord.y as y2,
                   MDSYS.SDO_GEOM.SDO_DISTANCE(
                            mdsys.sdo_geometry(2001,p_point.sdo_srid,
                                  mdsys.sdo_point_type(b.startcoord.x,b.startcoord.y,NULL),NULL,NULL),
                                  p_point,p_tolerance) as startDist,
                   MDSYS.SDO_GEOM.SDO_DISTANCE(
                            mdsys.sdo_geometry(2001,p_point.sdo_srid,
                                  mdsys.sdo_point_type(b.endcoord.x,b.endcoord.y,NULL),NULL,NULL),
                                  p_point,p_tolerance) as endDist,
                   MDSYS.SDO_GEOM.SDO_DISTANCE(
                            mdsys.sdo_geometry(2002,p_line.sdo_srid,NULL,
                                  mdsys.sdo_elem_info_array(1,2,1),
                                  mdsys.sdo_ordinate_array(b.startcoord.x,b.startcoord.y,b.endcoord.x,b.endcoord.y)),
                                  p_point,p_tolerance) as linedist
             from table(&&defaultSchema..GEOM.GetVector2D(v_geometry)) b
             order by 8
           )
     where rownum < 2;
    -- dbms_output.put_line('Split vector is ' || v_vector_id);
    -- dbms_output.put_line('Start Distance is ' || v_start_distance);
    -- dbms_output.put_line('Line Distance is ' || v_line_distance);
    -- dbms_output.put_line('End Distance is ' || v_end_distance);
    -- Now do the splitting
    If ( v_line_distance = 0 ) Then
        -- provided point is on the line.
        if ( v_start_distance = 0 ) then
           -- point can only split line at the start of the vector
           v_vector_1 := NULL;
           v_vector_2 := &&defaultSchema..T_Vector2d(&&defaultSchema..T_Coord2D(v_x1,v_y1),
                                                       &&defaultSchema..T_Coord2D(v_x2,v_y2));
        elsif ( v_end_distance = 0 ) then
           -- point can only split line at the start of the vector
           v_vector_1 := &&defaultSchema..T_Vector2d(&&defaultSchema..T_Coord2D(v_x1,v_y1),
                                                       &&defaultSchema..T_Coord2D(v_x2,v_y2));
           v_vector_2 := NULL;
        else
           -- point is between start and end of vector
           v_vector_1 := &&defaultSchema..T_Vector2d(&&defaultSchema..T_Coord2D(v_x1,v_y1),
                                                       &&defaultSchema..T_Coord2D(p_point.sdo_point.x,p_point.sdo_point.y));
           v_vector_2 := &&defaultSchema..T_Vector2d(&&defaultSchema..T_Coord2D(p_point.sdo_point.x,p_point.sdo_point.y),
                                                       &&defaultSchema..T_Coord2D(v_x2,v_y2));
        end if;
    else
       If ( v_line_distance = v_start_distance ) then
          -- point can only split line at the start of the vector
           v_vector_1 := NULL;
           v_vector_2 := &&defaultSchema..T_Vector2d(&&defaultSchema..T_Coord2D(v_x1,v_y1),
                                                       &&defaultSchema..T_Coord2D(v_x2,v_y2));
       elsIf ( v_line_distance = v_end_distance ) then
          -- point can only split line at the end of the vector
           v_vector_1 := &&defaultSchema..T_Vector2d(&&defaultSchema..T_Coord2D(v_x1,v_y1),
                                                       &&defaultSchema..T_Coord2D(v_x2,v_y2));
           v_vector_2 := NULL;
       else
          -- point is between first and last vertex so split point is ratio of start/end distances
           v_vector_1 := &&defaultSchema..T_Vector2d(&&defaultSchema..T_Coord2D(v_x1,v_y1),
                                                       &&defaultSchema..T_Coord2D(v_x1+(v_x2-v_x1)*v_ratio,
                                                                                    v_y1+(v_y2-v_y1)*v_ratio));
           v_vector_2 := &&defaultSchema..T_Vector2d(&&defaultSchema..T_Coord2D(p_point.sdo_point.x,p_point.sdo_point.y),
                                                       &&defaultSchema..T_Coord2D(v_x2,v_y2));
        end if;
    End If;
    -- dbms_output.put_line('Vector1: ('||v_vector_1.startcoord.x||','||v_vector_1.startcoord.y||')('||v_vector_1.endcoord.x||','||v_vector_1.endcoord.y||')');
    -- dbms_output.put_line('Vector2: ('||v_vector_2.startcoord.x||','||v_vector_2.startcoord.y||')('||v_vector_2.endcoord.x||','||v_vector_2.endcoord.y||')');

    -- Construct the output geometries
    -- Add elements in multi-part geometry to first output line
    FOR v_element IN 1..(v_part-1) LOOP
      -- dbms_output.put_line('Adding element || ' || v_element || ' to out line 1');
      v_extract_geom := mdsys.sdo_util.Extract(p_line,v_element);   -- Extract element with all sub-elements
      p_out_line1    := Append(p_out_line1,v_extract_geom);
    END LOOP;

    -- Now add the vertexes of the split geometry (in v_geometry) to the output lines
    FOR rec IN c_vectors(v_geometry) LOOP
      -- dbms_output.put(rec.id || ': ');
      If ( rec.id < v_vector_id ) Then
        -- dbms_output.put_line('Add to first part');
        if ( rec.id = 1 ) Then
          -- dbms_output.put_line('Creating output line1 geometry');
          v_geom_part := mdsys.sdo_geometry(2002,p_line.sdo_srid,NULL,
                                            mdsys.sdo_elem_info_array(1,2,1),
                                            mdsys.sdo_ordinate_array(rec.x1,rec.y1,rec.x2,rec.y2));
        Else
          -- dbms_output.put_line('Append vector to output line1 geometry');
          v_geom_part := mdsys.sdo_util.Concat_Lines(v_geom_part,
                                                   mdsys.sdo_geometry(2002,p_line.sdo_srid,NULL,
                                                         mdsys.sdo_elem_info_array(1,2,1),
                                                         mdsys.sdo_ordinate_array(rec.x1,rec.y1,rec.x2,rec.y2)));
        End If;
      ElsIf ( rec.id = v_vector_id ) Then
        If ( v_vector_1 is not NULL ) Then
           if ( v_geom_part is null ) Then
              -- dbms_output.put_line('Creating output line1 geometry');
              v_geom_part := mdsys.sdo_geometry(2002,p_line.sdo_srid,NULL,
                                                mdsys.sdo_elem_info_array(1,2,1),
                                                mdsys.sdo_ordinate_array(v_vector_1.startcoord.x,v_vector_1.startcoord.y,
                                                                         v_vector_1.endcoord.x,  v_vector_1.endcoord.y));
           Else
              -- dbms_output.put_line('Appending v_vector_1 to first part');
              v_geom_part := mdsys.sdo_util.Concat_Lines(v_geom_part,
                                   mdsys.sdo_geometry(2002,p_line.sdo_srid,NULL,
                                         mdsys.sdo_elem_info_array(1,2,1),
                                         mdsys.sdo_ordinate_array(v_vector_1.startcoord.x,v_vector_1.startcoord.y,
                                                                  v_vector_1.endcoord.x,  v_vector_1.endcoord.y)));
           End If;
        End If;
        p_out_line1 := Append(p_out_line1,v_geom_part);
        p_out_line2 := NULL;
        If ( v_vector_2 is not NULL ) Then
           -- dbms_output.put_line(' Add v_vector_2 to p_out_line2 ready to collect up remaining vectors and elements into output line 2');
           p_out_line2 := mdsys.sdo_geometry(2002,p_line.sdo_srid,NULL,
                                mdsys.sdo_elem_info_array(1,2,1),
                                mdsys.sdo_ordinate_array(v_vector_2.startcoord.x,v_vector_2.startcoord.y,v_vector_2.endcoord.x,v_vector_2.endcoord.y));
        End If;
      Else
        -- dbms_output.put_line(' Add any remaining vectors to v_geom_part');
        if ( p_out_line2 is null ) Then
           p_out_line2 := mdsys.sdo_geometry(2002,p_line.sdo_srid,NULL,
                                             mdsys.sdo_elem_info_array(1,2,1),
                                             mdsys.sdo_ordinate_array(rec.x1,rec.y1,rec.x2,rec.y2));
        Else
           p_out_line2 := mdsys.sdo_util.Concat_Lines(p_out_line2,
                                                      mdsys.sdo_geometry(2002,p_line.sdo_srid,NULL,
                                                            mdsys.sdo_elem_info_array(1,2,1),
                                                            mdsys.sdo_ordinate_array(rec.x1,rec.y1,rec.x2,rec.y2)));
        End If;
      End If;
    END LOOP;

    -- Now append any remaining elements in p_line to p_out_line2
    FOR v_element IN (v_part+1)..v_num_elements LOOP
      -- dbms_output.put_line('Adding element || ' || v_element || ' to out line 2');
      v_extract_geom := mdsys.sdo_util.Extract(p_line,v_element);   -- Extract element with all sub-elements
      p_out_line2    := Append(p_out_line2,v_extract_geom);
    END LOOP;

    Exception
      When NULL_GEOMETRY Then
         raise_application_error(&&defaultSchema..Constants.c_i_null_geometry,
                                 &&defaultSchema..Constants.c_s_null_geometry,TRUE);
      When NOT_A_LINE Then
         raise_application_error(&&defaultSchema..Constants.c_i_not_line,
                                 &&defaultSchema..Constants.c_s_not_line || ' ' || v_gtype,TRUE);
      When NOT_A_POINT Then
         raise_application_error(&&defaultSchema..Constants.c_i_not_point,
                                 &&defaultSchema..Constants.c_s_not_point || ' ' || v_gtype,TRUE);
      When NULL_TOLERANCE Then
         raise_application_error(&&defaultSchema..Constants.c_i_null_tolerance,
                                 &&defaultSchema..Constants.c_s_null_tolerance,TRUE);
  end Split;

  Function Split( p_line      in mdsys.sdo_geometry,
                  p_point     in mdsys.sdo_geometry,
                  p_tolerance in number )
    Return &&defaultSchema..T_GeometrySet pipelined
  Is
    v_out_line1 mdsys.sdo_geometry;
    v_out_line2 mdsys.sdo_geometry;
  Begin
    Split( p_line,
           p_point,
           p_tolerance,
           v_out_line1,
           v_out_line2 );
    PIPE ROW (&&defaultSchema..T_Geometry(geometry=>v_out_line1));
    PIPE ROW (&&defaultSchema..T_Geometry(geometry=>v_out_line2));
    Return;
  End Split;

  Function Convert_Unit( p_from_unit in varchar2,
                         p_value     in number,
                         p_to_unit   in varchar2 )
           return number
  Is
    v_from_conversion_factor number;
    v_to_conversion_factor   number;
  Begin
    If ( p_value is null or p_from_unit is null or p_to_unit is null ) Then
        raise_application_error( &&defaultSchema..Constants.c_i_null_parameter,
                                 &&defaultSchema..Constants.c_s_null_parameter,False );
    End If;
    -- Check if p_from_unit exists by getting the necessary conversion factor to meters
    BEGIN
      -- Note that the conversion_factor is a conversion factor between v_from_unit and 1 metre.
      SELECT conversion_factor
        INTO v_from_conversion_factor
        FROM mdsys.sdo_dist_units
           WHERE sdo_unit = UPPER(p_from_unit)
             AND ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          raise_application_error( &&defaultSchema..Constants.c_i_invalid_unit,
                                   &&defaultSchema..Constants.c_s_invalid_unit || ' ' || p_from_unit);
    END;
    -- Check if p_to_unit exists by getting the necessary conversion factor to meters
    BEGIN
      -- Note that the conversion_factor is a conversion factor between v_to_unit and 1 metre.
      SELECT conversion_factor
        INTO v_to_conversion_factor
        FROM mdsys.sdo_dist_units
           WHERE sdo_unit = UPPER(p_to_unit)
             AND ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          raise_application_error( &&defaultSchema..Constants.c_i_invalid_unit,
                                   &&defaultSchema..Constants.c_s_invalid_unit || ' ' || p_to_unit);
    END;
    -- Do the computation
    RETURN ( p_value * v_from_conversion_factor ) / v_to_conversion_factor;
  End Convert_Unit;

  Function Convert_Distance( p_srid  in number,
                             p_value in number,
                             p_unit  in varchar2 := 'Meter' )
           Return number
  Is
    v_unit                   varchar2(1000) := UPPER(p_unit);
    v_unit_conversion_factor number;
    v_srid_conversion_factor number;
    v_radius_of_earth        number := 6378137;  -- Default
    v_length                 number;
    v_srid                   mdsys.cs_srs.SRID%TYPE;
    v_token_id               number;
    v_token                  varchar2(4000);
    v_geocs                  boolean;
    cursor c_cs_tokens(p_srid in number)
    Is
       select rownum as id,
              substr(trim(both ' ' from replace(b.token,'"')),1,40) as token
         from mdsys.cs_srs a,
              table(&&defaultSchema..Tokenizer(a.wktext,',[]')) b
         where srid = p_srid;
  Begin
    If ( p_srid is null ) Then
        -- Normally Oracle assumes a NULL srid is planar but
        -- this could be planar feet, or meters etc so throw an error
        raise_application_error( &&defaultSchema..Constants.c_i_null_srid,
                                 &&defaultSchema..Constants.c_s_null_srid,False );
    End If;
    If ( p_value is null ) Then
        raise_application_error( &&defaultSchema..Constants.c_i_null_parameter,
                                 &&defaultSchema..Constants.c_s_null_parameter,False );
    End If;
    -- Check if p_unit exists by getting the necessary conversion factor to meters
    BEGIN
      -- Note that the conversion_factor is a conversion factor between v_unit and 1 metre.
      SELECT conversion_factor
        INTO v_unit_conversion_factor
        FROM mdsys.sdo_dist_units
           WHERE sdo_unit = v_unit
             AND ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          raise_application_error( &&defaultSchema..Constants.c_i_invalid_unit,
                                   &&defaultSchema..Constants.c_s_invalid_unit || v_unit);
    END;
    -- Check if SRID exists
    BEGIN
      SELECT srid
        INTO v_srid
        FROM mdsys.cs_srs
       WHERE srid = p_srid;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          raise_application_error( &&defaultSchema..Constants.c_i_invalid_srid,
                                   &&defaultSchema..Constants.c_s_invalid_srid || p_srid);
    END;
    -- We need to get the conversion factor to meters and earth's radius for the supplied SRID.
    -- This can only be gotten by getting the WKTEXT in mdsys.cs_srs, breaking it into tokens,
    -- and finding the right ones:
    -- SPHEROID + 2 tokens = Radius
    -- Last UNIT + 1 = conversion unit
    -- Last UNIT + 2 = conversion unit value
    FOR rec IN c_cs_tokens(p_srid) LOOP
      If ( rec.id = 1 ) Then
        v_geocs :=  case rec.token when 'GEOGCS' then true else false end;
      ElsIf ( rec.token = 'SPHEROID' ) Then
        v_token    := rec.token;
        v_token_id := rec.id + 2;
      ElsIf ( rec.token = 'UNIT' ) Then
        v_token    := rec.token;
        v_token_id := rec.id + 2;
      End If;
      If ( rec.id = v_token_id ) Then
        If ( v_token = 'SPHEROID' ) Then
          v_radius_of_earth := to_number(rec.token);
        ElsIf ( v_token = 'UNIT' ) Then
          v_srid_conversion_factor := to_number(rec.token);
        End If;
      End If;
    END LOOP;
    If ( v_geocs ) Then
      v_srid_conversion_factor := v_srid_conversion_factor * v_radius_of_earth;
    End If;
    -- OK, now we have a conversion factor from p_unit to meters
    -- and a conversion factor for the units to meters
    -- The returned value is: p_value * v_srid_conversion_factor (to get value in meters) / v_unit_conversion_factor (to convert from meters to the unit)
    --
    return ( p_value * v_srid_conversion_factor ) / v_unit_conversion_factor;
  End Convert_Distance;

  FUNCTION Parallel(p_geometry   in mdsys.sdo_geometry,
                    p_distance   in number,
                    p_tolerance  in number,
                    p_curved     in number := 0)
    RETURN mdsys.sdo_geometry
  AS
    v_round_factor number := case when p_tolerance is null
                                  then null
                                  else round(log(10,(1/p_tolerance)/2))
                              end;
    v_result       mdsys.sdo_geometry;

    CURSOR c_parts Is
    SELECT a.geometry
      FROM TABLE(CAST(MULTISET(
                      SELECT mdsys.sdo_util.Extract(p_geometry,v.column_value,0) as geometry
                        FROM TABLE(&&defaultSchema..GEOM.generate_series(
                                     1,
                                     (SELECT COUNT(*)
                                        FROM (SELECT sum(case when mod(rownum,3) = 1 then sei.column_value else null end) as offset,
                                                     sum(case when mod(rownum,3) = 2 then sei.column_value else null end) as etype,
                                                     sum(case when mod(rownum,3) = 0 then sei.column_value else null end) as interpretation
                                                FROM TABLE(p_geometry.sdo_elem_info) sei
                                              GROUP BY trunc((rownum - 1) / 3,0)
                                              ORDER BY 1
                                              ) i
                                        WHERE i.etype in (1003,1005,2)),
                                      1)
                                   ) v
                             ) AS &&defaultSchema..T_GeometrySet)
                ) a;

    Procedure ADD_Compound_Beginning(p_elem_info in out nocopy mdsys.sdo_elem_info_array)
    Is
      v_elem_count number := p_elem_info.COUNT / 3;
      v_element    number;
    Begin
      p_elem_info.EXTEND(3);
      v_element := p_elem_info.COUNT;
      -- Shuffle
      while ( v_element > 3 ) loop
        p_elem_info(v_element) := p_elem_info(v_element-3);
        v_element := v_element - 1;
      end loop;
      p_elem_info(1) := 1;
      p_elem_info(2) := 4;
      p_elem_info(3) := v_elem_count;
    End ADD_Compound_Beginning;

    Function Process_LineString( p_linestring in mdsys.sdo_geometry )
      Return mdsys.sdo_geometry
    Is
      bAcute            Boolean := False;
      bCurved           Boolean := ( 1 = p_curved );
      v_dims            pls_integer;
      v_delta           mdsys.sdo_point_type := mdsys.sdo_point_type(null,null,null);
      v_prev_delta      mdsys.sdo_point_type := mdsys.sdo_point_type(null,null,null);

      v_adj_Coord       &&defaultSchema..T_Vertex;
      v_int_1           &&defaultSchema..T_Vertex := &&defaultSchema..T_Vertex(null,null,null,null,null);
      v_int_coord       &&defaultSchema..T_Vertex;
      v_int_2           &&defaultSchema..T_Vertex := &&defaultSchema..T_Vertex(null,null,null,null,null);
      v_endCoord        &&defaultSchema..T_Vertex;

      v_distance        number;
      v_ratio           number;
      v_az              number;
      v_dir             pls_integer;
      v_elem_info       mdsys.sdo_elem_info_array := new mdsys.sdo_elem_info_array();
      v_ordinates       mdsys.sdo_ordinate_array  := new mdsys.sdo_ordinate_array();

      CURSOR c_vector IS
      SELECT o.startCoord,
             o.EndCoord
        FROM TABLE(&&defaultSchema..GEOM.getVector(p_linestring)) o
       WHERE round(sdo_geom.sdo_distance(mdsys.sdo_geometry(2001,p_linestring.sdo_srid,sdo_point_type(o.startcoord.x,o.startcoord.y,null),null,null),
                                         mdsys.sdo_geometry(2001,p_linestring.sdo_srid,sdo_point_type(o.endcoord.x,o.endcoord.y,null),null,null),
                                         p_tolerance),
            v_round_factor) >= p_distance;

    Begin
      v_dims := TRUNC(p_linestring.sdo_gtype/1000,0);

      -- Process geometry one vector at a time
      FOR rec IN c_vector LOOP

        -- Compute base offset
        v_az := &&defaultSchema..Cogo.Bearing(rec.startCoord.X,rec.startCoord.Y,rec.endCoord.X,rec.endCoord.Y);
        v_dir  := CASE WHEN v_az < Constants.pi THEN -1 ELSE 1 END;
        v_delta.x := ABS(COS(v_az)) * p_distance * v_dir;
        v_delta.y := ABS(SIN(v_az)) * p_distance * v_dir;
        IF  Not ( v_az > Constants.pi/2 AND
                  v_az < Constants.pi OR
                  v_az > 3 * Constants.pi/2 ) THEN
          v_delta.x := -1 * v_delta.x;
        END IF;

        -- merge vectors at this point?
        IF (c_vector%ROWCOUNT > 1) THEN
           -- Get intersection of two lines parallel at distance p_distance from current ones
           v_int_coord := rec.startCoord;
           &&defaultSchema..cogo.FindLineIntersection(v_adj_coord.x,
                                             v_adj_coord.y,
                                             rec.startCoord.x + v_prev_delta.x,
                                             rec.startCoord.y + v_prev_delta.y,
                                             rec.endCoord.x   + v_delta.x,
                                             rec.endCoord.y   + v_delta.y,
                                             rec.startCoord.x + v_delta.x,
                                             rec.startCoord.y + v_delta.y,
                                             v_int_coord.x,
                                             v_int_coord.y,
                                             v_int_1.x,v_int_1.y,
                                             v_int_2.x,v_int_2.y);
           If ( v_int_coord.x = &&defaultSchema..constants.c_Max ) Then
             -- No intersection point as lines are parallel
             bAcute := True;
             -- int coord could be computed from start or end, doesn't matter.
             v_int_coord := &&defaultSchema..T_Vertex(Round(rec.startCoord.x + v_prev_delta.x,v_round_factor),
                                             Round(rec.startCoord.y + v_prev_delta.y,v_round_factor),
                                             rec.startCoord.z,
                                             rec.startCoord.w,
                                             1);
           Else
             bAcute := ( Round(v_int_coord.x,v_round_factor) = Round(v_int_1.x,v_round_factor) )
                   And ( Round(v_int_coord.x,v_round_factor) = Round(v_int_2.x,v_round_factor) )
                   And ( Round(v_int_coord.y,v_round_factor) = Round(v_int_1.y,v_round_factor) )
                   And ( Round(v_int_coord.y,v_round_factor) = Round(v_int_2.y,v_round_factor) );
           End If;
           If ( bCurved and Not bAcute) Then
             -- First point in "intersection" curve
             v_int_1 := &&defaultSchema..T_Vertex(Round(rec.startCoord.x + v_prev_delta.x,v_round_factor),
                                         Round(rec.startCoord.y + v_prev_delta.y,v_round_factor),
                                         rec.startCoord.z, /* Keep all three points at same z */
                                         rec.startCoord.w, /* Measure may actually change.. */
                                         1);
             -- Intersection point (top of circular arc)
             -- Need to compute coordinates at mid-angle of the circular arc formed by last and current vector
             v_distance := MDSYS.SDO_GEOM.SDO_DISTANCE(mdsys.sdo_geometry(2001,p_linestring.sdo_srid,mdsys.sdo_point_type(v_int_coord.x,v_int_coord.y,v_int_coord.z),null,null),
                                                       mdsys.sdo_geometry(2001,p_linestring.sdo_srid,mdsys.sdo_point_type(rec.startCoord.X,rec.startCoord.Y,rec.startCoord.Z),null,null),
                                                       p_tolerance);
             v_ratio := ( p_distance / v_distance ) * SIGN(p_distance);
             v_adj_coord   := rec.startCoord;
             v_adj_coord.x := Round(rec.startCoord.x + (( v_int_coord.x - rec.startCoord.x ) * v_ratio ),v_round_factor);
             v_adj_coord.y := Round(rec.startCoord.y + (( v_int_coord.y - rec.startCoord.y ) * v_ratio ),v_round_factor);
             -- Last point in "intersection" curve
             v_int_2 := &&defaultSchema..T_Vertex(Round(rec.startCoord.x + v_delta.x,v_round_factor),
                                         Round(rec.startCoord.y + v_delta.y,v_round_factor),
                                         rec.startCoord.z, /* Keep all three points at same z */
                                         rec.startCoord.w, /* Measure may actually change.. */
                                         1);
           Else
             -- Intersection point
             v_adj_coord   := v_int_coord;
             v_adj_coord.x := Round(v_int_coord.x,v_round_factor);
             v_adj_coord.y := Round(v_int_coord.y,v_round_factor);
           End If;
        ELSE  -- c_vector%ROWCOUNT = 1
          If (bCurved) Then
            &&defaultSchema..GEOM.ADD_Element(v_elem_info,1,2,1);
          Else
            -- Copy original through to new geometry as will not change
            v_elem_info := p_linestring.sdo_elem_info;
          End If;
          -- Translate start point with current vector
          v_adj_coord := &&defaultSchema..T_Vertex(Round(rec.startCoord.x + v_delta.x, v_round_factor),
                                          Round(rec.startCoord.y + v_delta.y, v_round_factor),
                                          rec.startCoord.z,
                                          rec.startCoord.w,
                                          1);
        END IF;

        -- Now add computed coordints to output ordinate_array
        If (Not bCurved) or bAcute or (c_vector%ROWCOUNT = 1 ) Then
          &&defaultSchema..GEOM.ADD_Coordinate(v_ordinates,v_dims,v_adj_coord,&&defaultSchema..GEOM.isMeasured(p_linestring.sdo_gtype));
        ElsIf (bCurved) Then
          -- With any generated circular curves we need to add the appropriate elem_info
          &&defaultSchema..GEOM.ADD_Element(v_elem_info,v_ordinates.COUNT+1,2,2);
          &&defaultSchema..GEOM.ADD_Coordinate(v_ordinates,v_dims,v_int_1,&&defaultSchema..GEOM.isMeasured(p_linestring.sdo_gtype));
          &&defaultSchema..GEOM.ADD_Coordinate(v_ordinates,v_dims,v_adj_coord,&&defaultSchema..GEOM.isMeasured(p_linestring.sdo_gtype));
          &&defaultSchema..GEOM.ADD_Element(v_elem_info,v_ordinates.COUNT+1,2,1);
          &&defaultSchema..GEOM.ADD_Coordinate(v_ordinates,v_dims,v_int_2,&&defaultSchema..GEOM.isMeasured(p_linestring.sdo_gtype));
        End If;
        v_prev_delta := v_delta;
        v_endCoord   := rec.endCoord;
      END LOOP;

      &&defaultSchema..GEOM.ADD_Coordinate(v_ordinates,
                     v_dims,
                     &&defaultSchema..T_Vertex(Round(v_endcoord.x + v_delta.x,v_round_factor),
                                      Round(v_endcoord.y + v_delta.y,v_round_factor),
                                      v_endcoord.z,
                                      v_endcoord.w,
                                      1),
                     &&defaultSchema..GEOM.isMeasured(p_linestring.sdo_gtype));

      If isCompound(v_elem_info) > 0 Then
         -- And compound header to top of element_info (1,4,n_elements)
         ADD_Compound_Beginning(v_elem_info);
      End If;

      -- Return moved geometry
      RETURN mdsys.sdo_geometry(p_linestring.sdo_gtype,
                                p_linestring.sdo_srid,
                                p_linestring.sdo_point,
                                v_elem_info,
                                v_ordinates);
    End Process_LineString;

  BEGIN
    -- Problem with this algorithm is that any existing circular curved elements will not be honoured unless bCurved is 0
    If ( p_tolerance is null ) Then
       raise_application_error(-20001,'p_tolerance may not be null',true);
    End If;
    If ( p_geometry is null
         or
         Mod(p_geometry.sdo_gtype,10) not in (2,6) ) Then
       raise_application_error(-20001,'p_linestring is null or is not a linestring',true);
    End If;
    If isCompound(p_geometry.sdo_elem_info) > 0 Then
       raise_application_error(-20001,'Compound linestrings are not supported.',true);
    End If;

    -- Process all parts of a, potentially, multi-part linestring geometry
    FOR part IN c_parts loop
      If ( c_parts%ROWCOUNT = 1 ) Then
        v_result := Process_LineString(part.geometry);
      Else
        v_result := Append(v_result,Process_LineString(part.geometry)); /* CONCAT_LINES destroys compound element descriptions */
      End If;
    End Loop;

    Return v_Result;
  END Parallel;

  Function SquareBuffer(p_geometry   in mdsys.sdo_geometry,
                        p_distance   in number,
                        p_tolerance  in number,
                        p_curved     in number := 0 )
    RETURN mdsys.sdo_geometry
  AS
    v_geoml    mdsys.sdo_geometry;
    v_geomr    mdsys.sdo_geometry;
    v_rgeom    mdsys.sdo_geometry;
    v_vertices mdsys.vertex_set_type;
  Begin
    If p_geometry is null Then
       return null;
    End If;
    v_geoml := &&defaultSchema..GEOM.Parallel(p_geometry,p_distance,p_tolerance,p_curved);
    v_geomr := mdsys.sdo_util.reverse_linestring(&&defaultSchema..GEOM.Parallel(p_geometry,0-p_distance,p_tolerance,p_curved));
    v_rgeom := mdsys.sdo_util.append(v_geoml,v_geomr);
    v_vertices := mdsys.sdo_util.getVertices(v_rgeom);
    v_rgeom := mdsys.sdo_util.append(v_rgeom,
                                     mdsys.sdo_geometry(p_geometry.get_dims()*1000+1,
                                                        p_geometry.sdo_srid,
                                                        mdsys.sdo_point_type(v_vertices(v_vertices.COUNT).x,
                                                                             v_vertices(v_vertices.COUNT).y,
                                                                             v_vertices(v_vertices.COUNT).z),
                                                        null,null));
    return mdsys.sdo_geometry(p_geometry.get_dims()*1000+3,
                              p_geometry.sdo_srid,
                              p_geometry.sdo_point,
                              mdsys.sdo_elem_info_array(1,1003,1),
                              v_rgeom.sdo_ordinates);
  End SquareBuffer;

  Function Reverse_Geometry(p_geometry in mdsys.sdo_geometry)
    return mdsys.sdo_geometry
  Is
    v_ordinates mdsys.sdo_ordinate_array;
    v_ord       pls_integer;
    v_dims      pls_integer;
    v_vertex    pls_integer;
    v_vertices  mdsys.vertex_set_type;
  Begin
    If ( p_geometry is null OR p_geometry.get_gtype() not in (2,3,5,6,7) OR p_geometry.sdo_ordinates is null ) Then
       return p_geometry;
    End If;
    v_dims      := p_geometry.get_dims();
    v_vertices  := sdo_util.getVertices(p_geometry);
    v_ordinates := new mdsys.sdo_ordinate_array(1);
    v_ordinates.DELETE;
    v_ordinates.EXTEND(p_geometry.sdo_ordinates.count);
    v_ord    := 1;
    v_vertex := v_vertices.LAST;
    WHILE (v_vertex >= 1 ) LOOP
        v_ordinates(v_ord) := v_vertices(v_vertex).x; v_ord := v_ord + 1;
        v_ordinates(v_ord) := v_vertices(v_vertex).y; v_ord := v_ord + 1;
        if ( v_dims >= 3 ) Then
           v_ordinates(v_ord) := v_vertices(v_vertex).z; v_ord := v_ord + 1;
        end if;
        if ( v_dims >= 4 ) Then
           v_ordinates(v_ord) := v_vertices(v_vertex).w; v_ord := v_ord + 1;
        end if;
        v_vertex := v_vertex - 1;
    END LOOP;
    RETURN mdsys.sdo_geometry(p_geometry.sdo_gtype,
                              p_geometry.sdo_srid,
                              p_geometry.sdo_point,
                              p_geometry.sdo_elem_info,
                              v_ordinates);
  End Reverse_Geometry;

  -- This is all about filtering INNER rings from polygons/multipolyons
  FUNCTION Filter_Rings(p_geometry  in mdsys.sdo_geometry,
                        p_tolerance in number,
                        p_area      in number,
                        p_ring      in number := 0)
    RETURN MDSYS.SDO_GEOMETRY
  IS
     v_num_dims        pls_integer;
     v_num_elems       pls_integer;
     v_actual_etype    pls_integer;
     v_ring_elem_count pls_integer := 1;
     v_ring            mdsys.sdo_geometry;
     v_num_rings       pls_integer;
     v_elemInfoSet     &&defaultSchema..T_ElemInfoSet;
     v_geom            mdsys.sdo_geometry;
     v_ok              number;
     v_version         number;
  BEGIN
    If ( p_geometry is null or Mod(p_geometry.sdo_gtype,10) not in (3,7) ) Then
       raise_application_error(-20001,'p_geometry is null or is not a polygon',true);
    End If;
    v_version := DBMS_DB_VERSION.VERSION;
    If ( v_version < 12 ) Then
      Begin
        -- Can only use this if Enterprise Edition and SDO
        SELECT 1
          INTO v_Ok
          FROM v$version
         WHERE banner like '%Enterprise Edition%'
           AND EXISTS (SELECT 1
                         FROM all_objects ao
                        WHERE ao.owner       = 'MDSYS'
                          AND ao.object_type = 'TYPE'
                          AND ao.object_name = 'SDO_GEORASTER'
                      );
        IF ( v_OK = 0 ) THEN
          raise_application_error(-20001,'Not licensed for use of SDO_AREA',true);
        END IF;
        EXCEPTION
          WHEN OTHERS THEN
            raise_application_error(-20001,'Not licensed for use of SDO_AREA',true);
            RETURN p_geometry;
      End;
    End If;
    /* The processing below assumes the structure of a polygon/multipolygon
       is correct and passes sdo_geom.validate_geometry */
    v_num_dims  := p_geometry.get_dims();
    v_num_elems := MDSYS.SDO_UTIL.GETNUMELEM(p_geometry);  -- Gets number of 1003 geometries
    <<all_elements>>
    FOR v_elem_no IN 1..v_num_elems LOOP
        -- Need to process and check all inner rings
        --
        -- Process all rings in the extracted single - 2003 - polygon
        v_num_rings   := &&defaultSchema..GEOM.GetNumRings(MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_elem_no),0);
        --v_elemInfoSet := &&defaultSchema..GEOM.GetElemInfoSet(MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_elem_no));
        <<All_Rings>>
        FOR v_ring_no IN 1..v_num_rings LOOP
            v_ring := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_elem_no,v_ring_no);
            IF ( v_ring is not null ) Then
               If ( v_ring_no = 1 ) Then -- outer ring
                 v_geom := case when ( v_geom is null ) then v_ring else mdsys.sdo_util.APPEND(v_geom,v_ring) end;
               Else -- Inner Ring
                  if ( MDSYS.SDO_GEOM.SDO_AREA(v_ring,p_tolerance) > p_area ) Then
                     If ( v_ring.sdo_ordinates.count <> v_num_dims * 2 ) then -- If optimized rectangle don't swap
                        if ( v_ring.sdo_elem_info(2) <> 1005 ) Then  -- Reverse_Geometry does not yet support compound object reversal
                           v_ring := GEOM.Reverse_Geometry(v_ring);
                        End If;
                     End If;
                     v_ring.sdo_elem_info(2) := v_ring.sdo_elem_info(2) + 1000;
                     v_geom := mdsys.sdo_util.APPEND(v_geom,v_ring);
                     -- Gtype must always be 2003 regardless as to what APPEND does as we are processing a single geometry's rings
                     v_geom.sdo_gtype := case when MOD(v_geom.sdo_gtype,1000)=7 then v_geom.sdo_gtype - 4 else v_geom.sdo_gtype end;
                  End If;
               End If;
            END IF;
        END LOOP All_Rings;
    END LOOP all_elements;
    RETURN v_geom;
  END Filter_Rings;

  -- Adds a point to a MultiPoint, LineString or MultiLinestring geometry before point <p_position> (1-based index: Set to -1/NULL for appending.
  Function SDO_AddPoint(p_geometry   IN MDSYS.SDO_Geometry,
                        p_point      IN MDSYS.Vertex_Type,
                        p_position   IN Number )
    Return MDSYS.SDO_Geometry
  Is
    v_elem_info               mdsys.sdo_elem_info_array;
    v_ordinates               MDSYS.SDO_Ordinate_Array;
    v_dims                    Number;
    NULL_GEOMETRY             EXCEPTION;
    NOT_LINESTRING_MULTIPOINT EXCEPTION;
    IS_COMPOUND               EXCEPTION;
    NULL_POINT                EXCEPTION;
  Begin
    If ( p_geometry is null ) Then
      Raise NULL_GEOMETRY;
    ElsIf ( Mod(p_geometry.sdo_gtype,10) not in (2,5,6) ) Then
       RAISE NOT_LINESTRING_MULTIPOINT;
    End If;
    If ( p_point is null ) Then
       RAISE NULL_POINT;
    End If;
    If isCompound(p_geometry.sdo_elem_info) > 0 Then
       RAISE IS_COMPOUND;
    End If;
    v_dims := TRUNC(p_geometry.sdo_gtype/1000,0);
    v_elem_info := p_geometry.sdo_elem_info;
    If ( p_position is NULL or p_position <= 0 ) Then
       v_ordinates := p_geometry.sdo_ordinates;
       ADD_Coordinate( v_ordinates, v_dims, p_point );
    Else
       -- First insert the point at the right point in the ordinate array
       SELECT column_value
         BULK COLLECT INTO v_ordinates
         FROM (SELECT case when Ceil(rownum/v_dims) = p_position then (p_position+0.5) else Ceil(rownum/v_dims) end as coord,
                      rownum - (Ceil(rownum/v_dims) - 1) * v_dims as ord,
                      a.column_value
                 FROM TABLE(p_geometry.sdo_ordinates) a
               UNION ALL
               SELECT p_position as coord,
                      rownum as ord,
                      v.column_value
                 FROM TABLE(mdsys.sdo_ordinate_array(p_point.x,p_point.y,p_point.z,p_point.w)) v
                WHERE rownum <= v_dims
             )
       ORDER BY coord,ord;
       -- Now, modify sdo_elem_info if needed
       If ( GetNumElem(p_geometry) > 1 ) Then
         SELECT case when e.elem = 1
                      and ( e.elem_value > 1 And e.elem_value > e.new_ord_position )
                     then e.elem_value + v_dims
                     when e.elem = 3
                     then /* If this is a multi-point geometry, add one to the point count in interpretation field*/
                          case when (LAG(e.elem_value,1) over (order by e.rin)) = 1
                               then e.elem_value + 1
                               else e.elem_value
                           end
                     else e.elem_value
                 end as new_elem_value
           BULK COLLECT INTO v_elem_info
           FROM (SELECT rownum                            as rin,
                        (( p_position - 1 ) * v_dims) + 1 as new_ord_position,
                        rownum - (Ceil(rownum/3) - 1) * 3 as elem,
                        a.column_value                    as elem_value
                   FROM TABLE(p_geometry.sdo_elem_info) a
                 ) e;
       End If;
    End If;
    Return MDSYS.SDO_Geometry(p_geometry.sdo_gtype,
                              p_geometry.sdo_srid,
                              p_geometry.sdo_point,
                              v_elem_info,
                              v_ordinates);
    EXCEPTION
      WHEN NULL_GEOMETRY Then
        raise_application_error(&&defaultSchema..CONSTANTS.c_i_null_geometry,
                                &&defaultSchema..CONSTANTS.c_s_null_geometry,TRUE);
        RETURN p_geometry;
      WHEN NOT_LINESTRING_MULTIPOINT THEN
        raise_application_error(&&defaultSchema..CONSTANTS.c_i_not_line,&&defaultSchema..CONSTANTS.c_s_not_line ||
                                                      ' / ' || &&defaultSchema..CONSTANTS.c_s_not_point,true);
       RETURN p_geometry;
      WHEN IS_COMPOUND THEN
       raise_application_error(&&defaultSchema..CONSTANTS.c_i_cmpnd_vector,&&defaultSchema..CONSTANTS.c_s_cmpnd_vector,true);
       RETURN p_geometry;
      WHEN NULL_POINT THEN
       raise_application_error(-20001,'p_point is null',true);
       RETURN p_geometry;
  End SDO_AddPoint;

  Function SDO_AddPoint(p_geometry IN MDSYS.SDO_Geometry,
                        p_point    IN &&defaultSchema..T_Vertex,
                        p_position IN Number)
    Return MDSYS.SDO_Geometry
  Is
    v_vertex mdsys.vertex_type := InitializeVertexType();
  Begin
    v_vertex.x  := p_point.x;
    v_vertex.y  := p_point.y;
    v_vertex.z  := p_point.z;
    v_vertex.w  := p_point.w;
    v_vertex.id := p_point.id;
    return SDO_AddPoint(p_geometry,v_vertex,p_position);
  End SDO_AddPoint;

  -- Removes point (p_position) from a linestring. Offset is 1-based.
  Function SDO_RemovePoint(p_geometry   IN MDSYS.SDO_Geometry,
                           p_position   IN Number)
    Return MDSYS.SDO_Geometry
  Is
    v_elem_info                MDSYS.SDO_Elem_Info_Array;
    v_ordinates                MDSYS.SDO_Ordinate_Array;
    v_dims                     PLS_INTEGER;
    v_gtype                    PLS_INTEGER;
    v_coords                   PLS_INTEGER; /* Coordinate count after deletion */
    v_position                 NUMBER        := p_position;
    v_end_position             PLS_INTEGER;
    NULL_GEOMETRY              EXCEPTION;
    NOT_LINESTRING_MULTIPOINT  EXCEPTION;
    IS_COMPOUND                EXCEPTION;
    INVALID_POSITION           EXCEPTION;
  Begin
    If ( p_geometry is null ) Then
      Raise NULL_GEOMETRY;
    ElsIf ( Mod(p_geometry.sdo_gtype,10) not in (2,5,6) ) Then
       RAISE NOT_LINESTRING_MULTIPOINT;
    End If;
    If isCompound(p_geometry.sdo_elem_info) > 0 Then
       RAISE IS_COMPOUND;
    End If;
    v_dims := TRUNC(p_geometry.sdo_gtype/1000,0);
    v_gtype := Mod(p_geometry.sdo_gtype,10);
    v_ordinates := p_geometry.sdo_ordinates;
    v_elem_info := p_geometry.sdo_elem_info;

    /* Compute correct positions */
    v_end_position := CASE WHEN v_ordinates is null
                           THEN 1
                           ELSE v_ordinates.COUNT / v_dims
                         END;
    If ( v_position is NULL or v_position <= 0 ) Then
      v_position := v_end_position;
    End If;
    -- Can't update a point that does not exist....
    If Not ( v_position BETWEEN 1 AND v_end_position ) Then
       RAISE INVALID_POSITION;
    End If;

    -- First remove coordinate from ordinate array
    SELECT i.ordinate
      BULK COLLECT INTO v_ordinates
      FROM (SELECT Ceil(rownum/v_dims) as coord,
                   rownum - (Ceil(rownum/v_dims) - 1) * v_dims as ord,
                   a.column_value as ordinate
              FROM TABLE(p_geometry.sdo_ordinates) a
           ) i
     WHERE i.coord <> v_position
    ORDER BY coord,ord /* Probably not needed, but just in case */;

    -- Need coordinate count for next checks
    v_coords := v_ordinates.COUNT / v_dims;

    -- If a single element of a linestring then check we have enough coords */
    If ( v_coords = 1 And v_gtype = 2) Then
      raise ZERO_DIVIDE;
    End If;

    -- Now, modify sdo_elem_info if needed for multi objects
    If ( v_gtype in (5,6) ) Then
      SELECT case when ( f.elem = 1 )  /* Check ordinate value of previous element, if exists, to compute its size */
                   and ( (( ( f.new_elem_value - lag(f.new_elem_value,3) over (order by f.id)  ) / v_dims ) - 1)  = 0 )
                  then 1/0 /* Not enough ordinates to create a proper line */
                  when ( f.elem = 1 /* Compute size of last element in whole geometry */
                   And (lead(f.new_elem_value,3) over (order by f.id)) is null )
                   And ( ( ( f.max_ords - f.new_elem_value + 1 ) / v_dims ) <= 1 )
                  then 1/0 /* Last element has only 1 coord */
                  else f.new_elem_value
              end as elem_Value
        BULK COLLECT INTO v_elem_info
        FROM (SELECT rownum as id,
                     e.elem,
                     e.max_ords,
                     case when e.elem = 1
                           and ( e.elem_value > 1 And e.elem_value > e.ord_position )
                          then e.elem_value - v_dims /* Calculate new start ord position for this element */
                          when e.elem = 3
                          then /* If this is a multi-point geometry, remove one from the point count in interpretation field*/
                               case when (LAG(e.elem_value,1) over (order by e.rin)) = 1
                                    then e.elem_value - 1
                                    else e.elem_value
                                end
                          else e.elem_value
                      end as new_elem_value
                FROM (SELECT rownum                            as rin,
                             (( v_position - 1 ) * v_dims) + 1 as ord_position,
                             ( v_coords * v_dims)              as max_ords,
                             rownum - (Ceil(rownum/3) - 1) * 3 as elem,
                             a.column_value                    as elem_value
                        FROM TABLE(p_geometry.sdo_elem_info) a
                     ) e
             ) f;
    End If;
    Return MDSYS.SDO_Geometry(p_geometry.sdo_gtype,
                              p_geometry.sdo_srid,
                              p_geometry.sdo_point,
                              v_elem_info,
                              v_ordinates);
    EXCEPTION
      WHEN NULL_GEOMETRY Then
        raise_application_error(&&defaultSchema..CONSTANTS.c_i_null_geometry,
                                &&defaultSchema..CONSTANTS.c_s_null_geometry,TRUE);
        RETURN p_geometry;
      WHEN NOT_LINESTRING_MULTIPOINT THEN
        raise_application_error(&&defaultSchema..CONSTANTS.c_i_not_line,&&defaultSchema..CONSTANTS.c_s_not_line ||
                                                      ' / ' || &&defaultSchema..CONSTANTS.c_s_not_point,true);
        RETURN p_geometry;
      WHEN IS_COMPOUND THEN
        raise_application_error(&&defaultSchema..CONSTANTS.c_i_cmpnd_vector,&&defaultSchema..CONSTANTS.c_s_cmpnd_vector,true);
        RETURN p_geometry;
      WHEN ZERO_DIVIDE THEN
        raise_application_error(-20001,'point deletion results in an invalid one vertex element.',true);
        return p_geometry;
      WHEN INVALID_POSITION THEN
        raise_application_error(-20001,'invalid p_position value',true);
        RETURN p_geometry;
  End SDO_RemovePoint;

  Function ST_RemovePoint(p_geometry  IN MDSYS.ST_Geometry,
                          p_position  IN Number)
    RETURN MDSYS.ST_Geometry
  Is
  Begin
    Return MDSYS.ST_Geometry.FROM_SDO_GEOM(
                    SDO_RemovePoint( p_geometry.GET_SDO_GEOM(),
                                     p_position ));
  End ST_RemovePoint;

  -- Replace point (p_position) of a geometry with given point. Index is 1-based.
  -- We will allow the user to update a point in any sdo_geometry type even if it is
  -- the first or last point in a polygon shell (call procedure twice to update start/end)
  --
  Function SDO_SetPoint(p_geometry IN MDSYS.SDO_Geometry,
                        p_point    IN MDSYS.Vertex_Type,
                        p_position IN Number)
    Return MDSYS.SDO_Geometry
  Is
    v_ordinates       MDSYS.SDO_Ordinate_Array;
    v_dims            PLS_Integer;
    v_gtype           PLS_Integer;
    v_position        PLS_Integer := p_position;
    v_end_position    PLS_Integer := p_position;
    v_sdo_point       Mdsys.SDO_Point_Type;
    NULL_GEOMETRY     EXCEPTION;
    NULL_POINT        EXCEPTION;
    INVALID_POSITION  EXCEPTION;
  Begin
    If ( p_geometry is NULL ) Then
      raise NULL_GEOMETRY;
    End If;
    If ( p_point is null ) Then
       RAISE NULL_POINT;
    End If;

    v_dims  := TRUNC(p_geometry.sdo_gtype/1000,0);
    v_gtype := Mod(p_geometry.sdo_gtype,10);
    v_sdo_point := p_geometry.sdo_point;
    v_ordinates := p_geometry.sdo_ordinates;
    v_end_position := CASE WHEN v_ordinates is null
                           THEN 1
                           ELSE v_ordinates.COUNT / v_dims
                         END;
    If ( v_position is NULL ) Then
      v_position := v_end_position;
    End If;
    -- Can't update a point that does not exist....
    If Not ( v_position BETWEEN 1 AND v_end_position ) Then
       RAISE INVALID_POSITION;
    End If;
    -- If sdo_geometry is a single point coded in sdo_point, then update it
    If ( v_gtype = 1
         And p_geometry.sdo_point is not null
         And p_geometry.sdo_ordinates is null
        ) Then
      If ( v_position = 1 ) Then
        v_sdo_point.X := p_point.X;
        v_sdo_point.Y := p_point.Y;
        v_sdo_point.Z := CASE WHEN v_Dims = 3 THEN p_point.Z ELSE NULL END;
      Else
        RAISE INVALID_POSITION;
      End If;
    ElsIf ( v_ordinates is not null ) Then
      -- Update the point in the ordinate array
      SELECT case when o.coord = v_position
                  then case o.ord
                            when 1 then p_point.x
                            when 2 then p_point.y
                            when 3 then
                              case when MOD(trunc(p_geometry.sdo_gtype/100),10) <> 3
                                   then p_point.z
                                   else null
                               end
                            when 4 then
                              case when MOD(trunc(p_geometry.sdo_gtype/100),10) = 3
                                   then p_point.z
                                   else p_point.w
                               end
                            else o.ordinate_value
                        end
                  else o.ordinate_value
              end as ordinate
       BULK COLLECT INTO v_ordinates
       FROM (SELECT rownum as id,
                    Ceil(rownum/v_dims)                         as coord,
                    rownum - (Ceil(rownum/v_dims) - 1) * v_dims as ord,
                    a.column_value as ordinate_value
               FROM TABLE(p_geometry.sdo_ordinates) a
             ) o
      ORDER BY id;
    End If;
    -- Return the updated geometry
    Return MDSYS.SDO_Geometry(p_geometry.sdo_gtype,
                              p_geometry.sdo_srid,
                              v_sdo_point,
                              p_geometry.sdo_elem_info,
                              v_ordinates);

    EXCEPTION
      WHEN NULL_GEOMETRY Then
        raise_application_error(&&defaultSchema..CONSTANTS.c_i_null_geometry,
                                &&defaultSchema..CONSTANTS.c_s_null_geometry,TRUE);
        RETURN p_geometry;
      WHEN NULL_POINT THEN
        raise_application_error(-20001,'p_point is null',true);
        RETURN p_geometry;
      WHEN INVALID_POSITION THEN
        raise_application_error(-20001,'invalid p_position value',true);
        RETURN p_geometry;
  End SDO_SetPoint;

  Function SDO_SetPoint(p_geometry IN MDSYS.SDO_Geometry,
                        p_point    IN &&defaultSchema..T_Vertex,
                        p_position IN Number)
    Return MDSYS.SDO_Geometry
  Is
    v_vertex mdsys.vertex_type := InitializeVertexType();
  Begin
    v_vertex.x  := p_point.x;
    v_vertex.y  := p_point.y;
    v_vertex.z  := p_point.z;
    v_vertex.w  := p_point.w;
    v_vertex.id := p_point.id;
    return SDO_SetPoint(p_geometry,v_vertex,p_position);
  End SDO_SetPoint;

  /* SDO_VertexUpdate changes the value of a vertex in a geometry.
  ** You must supply both the exact old value and the new value of the vertex to be altered.
  ** If the input geometry has Z values or measures, you must supply them as well.
  ** All vertices in the geometry which match the old value will be updated.
  */
  Function SDO_VertexUpdate(p_geometry  IN MDSYS.SDO_Geometry,
                            p_old_point IN MDSYS.Vertex_Type,
                            p_new_point IN MDSYS.Vertex_Type)
    Return MDSYS.SDO_Geometry
  Is
    v_ordinates       MDSYS.SDO_Ordinate_Array;
    v_dims            Number;
    v_gtype           PLS_Integer;
    v_sdo_point       Mdsys.SDO_Point_Type;
    v_measure_posn    Number;
    NULL_GEOMETRY     EXCEPTION;
    NULL_POINT        EXCEPTION;
    INVALID_POSITION  EXCEPTION;
  Begin
    If ( p_geometry is NULL ) Then
      raise NULL_GEOMETRY;
    End If;
    If ( p_old_point is null or
        p_new_point is null ) Then
       RAISE NULL_POINT;
    End If;

    v_dims  := TRUNC(p_geometry.sdo_gtype/1000,0);
    v_gtype := Mod(p_geometry.sdo_gtype,10);
    v_measure_posn := MOD(trunc(p_geometry.sdo_gtype/100),10);
    v_sdo_point := p_geometry.sdo_point;
    v_ordinates := p_geometry.sdo_ordinates;
    -- If sdo_geometry is a single point coded in sdo_point, then update it
    If ( p_geometry.sdo_point is not null ) Then
      If ( ( p_old_point.x = v_sdo_point.x
             or
             ( v_sdo_point.x is null And p_old_point.x is null )
            )
           and
           ( p_old_point.y = v_sdo_point.y
             or
             ( v_sdo_point.y is null And p_old_point.y is null )
            )           and
           ( v_Dims = 2
             or
             ( v_Dims = 3
               and
               ( p_old_point.z = v_sdo_point.z
                 or
                 ( v_sdo_point.z is null And p_old_point.z is null )
               )
             )
           )
         ) Then
        v_sdo_point.X := p_new_point.X;
        v_sdo_point.Y := p_new_point.Y;
        v_sdo_point.Z := p_new_point.Z;
      End If;
    End If;
    If ( v_ordinates is not null ) Then
      -- Update the point in the ordinate array
      SELECT CASE e.rin
                  WHEN 1 THEN e.x
                  WHEN 2 THEN e.y
                  WHEN 3 THEN CASE v_measure_posn
                                   WHEN 0 THEN e.z
                                   WHEN 3 THEN e.w
                               END
                  WHEN 4 THEN e.w
              END as ord
       BULK COLLECT INTO v_ordinates
      FROM (SELECT d.cin, a.rin, d.x, d.y, d.z, d.w
              FROM (SELECT LEVEL as rin
                      FROM DUAL
                    CONNECT BY LEVEL <= v_dims) a,
                   (SELECT cin,
                           case when xm = 1 and ym = 1
                                 and ( zexists = 0 or (zm = 1 and zexists = 1))
                                 and ( wexists = 0 or (wm = 1 and wexists = 1 ))
                                then p_new_point.x else c.x end as x,
                           case when xm = 1 and ym = 1
                                 and ( zexists = 0 or (zm = 1 and zexists = 1))
                                 and ( wexists = 0 or (wm = 1 and wexists = 1 ))
                                then p_new_point.y else c.y end as y,
                           case when xm = 1 and ym = 1
                                 and ( zexists = 0 or (zm = 1 and zexists = 1))
                                 and ( wexists = 0 or (wm = 1 and wexists = 1 ))
                                then p_new_point.z else c.z end as z,
                           case when xm = 1 and ym = 1
                                 and ( zexists = 0 or (zm = 1 and zexists = 1))
                                 and ( wexists = 0 or (wm = 1 and wexists = 1 ))
                                then p_new_point.w else c.w end as w
                      FROM (SELECT rownum as cin,
                                   b.x,b.y,b.z,b.w,
                                   DECODE(b.x,p_old_point.x,1,0) as xm,
                                   DECODE(b.y,p_old_point.y,1,0) as ym,
                                   DECODE(b.z,p_old_point.z,1,0) as zm,
                                   DECODE(b.w,p_old_point.w,1,0) as wm,
                                   CASE WHEN (( v_dims >= 3 And (v_measure_posn <> 3) )                 ) THEN 1 ELSE 0 END as zexists,
                                   CASE WHEN (( v_dims  = 3 And (v_measure_posn  = 3) ) Or (v_dims = 4) ) THEN 1 ELSE 0 END as wexists
                              FROM (SELECT v.x,
                                           v.y,
                                           CASE WHEN v_measure_posn <> 3 /* If measured geometry and measure position is not 3 then Z is coded in this position */
                                                THEN v.z
                                                ELSE NULL
                                            END as z,
                                           CASE WHEN v_measure_posn = 3 /* If measured geometry and measure position is 3 then Z has been coded with W so move it */
                                                THEN v.z
                                                ELSE v.w
                                            END as w
                                      FROM TABLE(mdsys.sdo_util.GetVertices(p_geometry)) v
                                   ) b
                            ) c
                    ) d
             ) e
          order by e.cin, e.rin;
    End If;
    -- Return the updated geometry
    Return MDSYS.SDO_Geometry(p_geometry.sdo_gtype,
                              p_geometry.sdo_srid,
                              v_sdo_point,
                              p_geometry.sdo_elem_info,
                              v_ordinates);

    EXCEPTION
      WHEN NULL_GEOMETRY Then
        raise_application_error(&&defaultSchema..CONSTANTS.c_i_null_geometry,
                                &&defaultSchema..CONSTANTS.c_s_null_geometry,TRUE);
        RETURN p_geometry;
      WHEN NULL_POINT THEN
        raise_application_error(-20001,'p_point is null',true);
        RETURN p_geometry;
      WHEN INVALID_POSITION THEN
        raise_application_error(-20001,'invalid p_position value',true);
        RETURN p_geometry;
  End SDO_VertexUpdate;

  Function SDO_VertexUpdate(p_geometry  IN MDSYS.SDO_Geometry,
                            p_old_point IN &&defaultSchema..T_Vertex,
                            p_new_point IN &&defaultSchema..T_Vertex)
    Return MDSYS.SDO_Geometry
  Is
    v_old_point mdsys.vertex_type := InitializeVertexType();
    v_new_point mdsys.vertex_type := InitializeVertexType();
  Begin
    v_old_point.x := p_old_point.x;
    v_old_point.y  := p_old_point.y;
    v_old_point.z  := p_old_point.z;
    v_old_point.w  := p_old_point.w;
    v_old_point.id := p_old_point.id;
    v_new_point.x  := p_new_point.x;
    v_new_point.y  := p_new_point.y;
    v_new_point.z  := p_new_point.z;
    v_new_point.w  := p_new_point.w;
    v_new_point.id := p_new_point.id;
    return SDO_VertexUpdate(p_geometry,v_old_point,v_new_point);
  End SDO_VertexUpdate;

  Function fix_ordinates(p_geometry  in mdsys.sdo_geometry,
                         p_x_formula in varchar2,
                         p_y_formula in varchar2,
                         p_z_formula in varchar2 := null,
                         p_w_formula in varchar2 := null)
    Return mdsys.SDO_GEOMETRY
  Is
     v_measure_posn PLS_INTEGER; /* Ordinate position of the Measure value in an LRS geometry */
     v_dims         PLS_INTEGER;
     v_gtype        PLS_INTEGER;
     v_sdo_point    mdsys.sdo_point_type;
     v_ordinates    MDSYS.SDO_Ordinate_Array := new MDSYS.SDO_Ordinate_Array();
     v_sql          varchar2(4000);
     NULL_GEOMETRY  EXCEPTION;
  Begin
    If ( p_geometry is NULL ) Then
      raise NULL_GEOMETRY;
    End If;
    v_dims  := TRUNC(p_geometry.sdo_gtype/1000,0);
    v_gtype := Mod(p_geometry.sdo_gtype,10);
    -- If sdo_geometry is a single point coded in sdo_point, then update it
    v_sdo_point := p_geometry.sdo_point;
    If ( v_gtype = 1 And p_geometry.sdo_point is not null ) Then
      v_sql := 'SELECT mdsys.sdo_point_type(' || p_x_formula || ',' ||
                                                 p_y_formula || ',' ||
                                                 case when p_z_formula is null
                                                      then 'NULL'
                                                      else p_z_formula
                                                  end || ')
                FROM (SELECT :X as X,:Y as Y,:Z as Z FROM DUAL )';
       EXECUTE IMMEDIATE v_sql
                    INTO v_sdo_point
                   USING v_sdo_point.x,
                         v_sdo_point.y,
                         v_sdo_point.z;
    End If;
    If ( p_geometry.sdo_ordinates is not null ) Then
      v_measure_posn := MOD(trunc(p_geometry.sdo_gtype/100),10);
      /* Need to UNPIVOT x,y,z,w records from "b" query into ordinate list to collect into v_ordinates */
      v_sql := '
SELECT CASE A.rin
            WHEN 1 THEN b.x
            WHEN 2 THEN b.y
            WHEN 3 THEN CASE ' || v_measure_posn || '
                             WHEN 0 THEN b.z
                             WHEN 3 THEN b.w
                         END
            WHEN 4 THEN b.w
        END as ord
  FROM (SELECT LEVEL as rin
          FROM DUAL
        CONNECT BY LEVEL <= ' || v_dims || ') a,
       (SELECT rownum as cin, ' ||
               case when p_x_formula is null
                    then 'x'
                    else p_x_formula
                end || ' as x,' ||
               case when p_y_formula is null
                    then 'y'
                    else p_y_formula
                end || ' as y,' ||
               case when p_z_formula is null
                    then 'z'
                    else p_z_formula
                end || ' as z,' ||
               case when p_w_formula is null
                    then 'w'
                    else p_w_formula
                end || ' as w
          FROM (SELECT v.x,
                       v.y, ' ||
                       CASE WHEN v_measure_posn <> 3 /* If measured geometry and measure position is not 3 then Z is coded in this position */
                            THEN 'v.z'
                            ELSE 'NULL'
                        END || ' as z, ' ||
                       CASE WHEN v_measure_posn = 3 /* If measured geometry and measure position is 3 then Z has been coded with W so move it */
                            THEN 'v.z'
                            ELSE 'v.w'
                        END || ' as w
                  FROM TABLE(mdsys.sdo_util.GetVertices(:1)) v
               )
        ) b
 ORDER BY B.cin,A.rin';
      EXECUTE IMMEDIATE v_sql
      BULK COLLECT INTO v_ordinates
                  USING p_geometry;
    End If;
    Return mdsys.sdo_geometry(p_geometry.sdo_gtype,
                              p_geometry.sdo_srid,
                              v_sdo_point,
                              p_geometry.sdo_elem_info,
                              v_ordinates);
    EXCEPTION
      WHEN NULL_GEOMETRY Then
        raise_application_error(&&defaultSchema..CONSTANTS.c_i_null_geometry,
                                &&defaultSchema..CONSTANTS.c_s_null_geometry,TRUE);
        RETURN p_geometry;
      WHEN OTHERS THEN
        dbms_output.put_line('Error ('|| SQLCODE ||') of ' || SQLERRM(SQLCODE) );
        RETURN p_geometry;
  End fix_ordinates;

  function Extend( p_geom      in mdsys.sdo_geometry,
                   p_extension in number,
                   p_tolerance in number,
                   p_end       in varchar2 default 'START' )
    return mdsys.sdo_geometry
  as
    v_geom           mdsys.sdo_geometry := p_geom;
    v_geom_length    number := 0;
    v_x_round_factor number;
    v_y_round_factor number;
    v_end            varchar2(5) := UPPER(SUBSTR(p_end,1,5));
    INVALID_END      EXCEPTION;
    BAD_EXTENSION    EXCEPTION;
    NULL_EXTENSION   EXCEPTION;
    NULL_TOLERANCE   EXCEPTION;
    NULL_GEOMETRY    EXCEPTION;
    NOT_LINEAR       EXCEPTION;

    /* Tests
    ** select &&defaultSchema..geom.extend(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,2,2,3,3,4,4)),1.414,0.05,'START') from dual;
    ** select &&defaultSchema..geom.extend(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,2,2,3,3,4,4)),1.414,0.05,'END') from dual;
    ** select &&defaultSchema..geom.extend(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,2,2,3,3,4,4)),1.414,0.05,'BOTH') from dual;
    ** select &&defaultSchema..geom.extend(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,2,2,3,3,4,4)),-1.414,0.05,'START') from dual;
    ** select &&defaultSchema..geom.extend(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,2,2,3,3,4,4)),-1.414,0.05,'END') from dual;
    ** select &&defaultSchema..geom.extend(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,2,2,3,3,4,4)),-1.414,0.05,'BOTH') from dual;
    */

    Procedure Extension( p_end_pt_id      in Number,
                         p_internal_pt_id in Number,
                         p_extension      in Number)
    Is
      v_extend         number := p_extension;
      v_end_pt         mdsys.sdo_geometry;
      v_internal_pt    mdsys.sdo_geometry;
      v_deltaX         number;
      v_deltaY         number;
      v_length         number;
      v_new_point      mdsys.Vertex_Type;
    Begin
       v_end_pt      := &&defaultSchema..LINEAR.ST_Get_Point(v_geom,p_end_pt_id );
       v_internal_pt := &&defaultSchema..LINEAR.ST_Get_Point(v_geom,p_internal_pt_id);
       v_deltaX      := v_end_pt.sdo_point.x - v_internal_pt.sdo_point.x;
       v_deltaY      := v_end_pt.sdo_point.y - v_internal_pt.sdo_point.y;
       v_length      := MDSYS.SDO_GEOM.SDO_DISTANCE( v_end_pt, v_internal_pt, p_tolerance );
       v_new_point   := InitializeVertexType();
       v_new_point.x := ROUND(v_internal_pt.sdo_point.x + v_deltaX * ( (v_Length + p_extension) / v_Length ), v_x_round_factor);
       v_new_point.y := ROUND(v_internal_pt.sdo_point.y + v_deltaY * ( (v_Length + p_extension) / v_Length ), v_y_round_factor);
       v_geom        := &&defaultSchema..GEOM.SDO_SetPoint(v_geom,
                                                  v_new_point,
                                                  CASE SIGN(p_end_pt_id) WHEN -1 THEN NULL ELSE 1 END  );
    End Extension;

    Procedure Reduction( p_end_pt_id      in Number,
                         p_internal_pt_id in Number,
                         p_extension      in Number)
    Is
      v_extend         number := p_extension;
      v_sign           number := SIGN(p_end_pt_id);
      v_pt_id          number := 0;
      v_end_pt         mdsys.sdo_geometry;
      v_internal_pt    mdsys.sdo_geometry;
      v_deltaX         number;
      v_deltaY         number;
      v_length         number;
      v_new_point      mdsys.Vertex_Type;

      FUNCTION EndPoint( p_geom in MDSYS.SDO_GEOMETRY )
        RETURN Number
      IS
      BEGIN
        RETURN (p_geom.SDO_ORDINATES.COUNT() / TO_NUMBER(SUBSTR(p_geom.SDO_GTYPE,1,1)) );
      END EndPoint;

    Begin
       LOOP
         v_pt_id       := v_pt_id + v_sign;
         v_end_pt      := &&defaultSchema..LINEAR.ST_Get_Point(v_geom,v_pt_id );
         v_internal_pt := &&defaultSchema..LINEAR.ST_Get_Point(v_geom,v_pt_id + v_sign);
         v_deltaX      := v_end_pt.sdo_point.x - v_internal_pt.sdo_point.x;
         v_deltaY      := v_end_pt.sdo_point.y - v_internal_pt.sdo_point.y;
         v_length      := MDSYS.SDO_GEOM.SDO_DISTANCE( v_end_pt, v_internal_pt, p_tolerance );
         IF ( ABS(ROUND(v_extend, v_x_round_factor + 1)) >= ROUND(v_length, v_x_round_factor + 1) ) THEN
           v_geom := &&defaultSchema..GEOM.SDO_RemovePoint(v_geom,v_pt_id);
           v_extend := v_length + v_extend;
           v_pt_id  := v_pt_id - v_sign;
         ELSE
           v_new_point   := InitializeVertexType;
           v_new_point.x := ROUND(v_internal_pt.sdo_point.x + v_deltaX * ( (v_Length + v_extend) / v_Length ), v_x_round_factor);
           v_new_point.y := ROUND(v_internal_pt.sdo_point.y + v_deltaY * ( (v_Length + v_extend) / v_Length ), v_y_round_factor);
           v_geom        := &&defaultSchema..GEOM.SDO_SetPoint(v_geom,
                                                      v_new_point,
                                                      case v_sign when -1 then EndPoint(v_geom) else v_pt_id end );
           EXIT;
         END IF;
       END LOOP;
    End Reduction;

  Begin
    Begin
      IF ( p_tolerance is null ) THEN
        RAISE NULL_TOLERANCE;
      END IF;
      v_x_round_factor := round(log(10,(1/p_tolerance)/2));
      v_y_round_factor := round(log(10,(1/p_tolerance)/2));
      IF ( v_geom is NULL ) THEN
        RAISE NULL_GEOMETRY;
      END IF;
      -- Only support simple linestrings
      IF ( MOD(v_geom.sdo_gtype,10) <> 2 ) THEN
        RAISE NOT_LINEAR;
      End If;
      IF ( NOT v_end IN ('START','BOTH','END') ) Then
        RAISE INVALID_END;
      END IF;
      IF ( p_extension is NULL OR p_extension = 0 ) THEN
        RAISE NULL_EXTENSION;
      END IF;
      IF ( SIGN(p_extension) = -1 ) THEN
        -- Is reduction distance (when BOTH) greater than actual length of string?
        v_geom_length := MDSYS.SDO_GEOM.SDO_LENGTH(v_geom,p_tolerance);
        IF ( ABS(p_extension) >= ( v_geom_length / CASE v_end WHEN 'BOTH' THEN 2.0 ELSE 1 END ) )  THEN
          RAISE BAD_EXTENSION;
        END IF;
      END IF;
      IF v_end IN ('START','BOTH') THEN
        If ( SIGN(p_extension) = 1 ) Then
          Extension(1,2,p_extension);
        Else
          Reduction(1,2,p_extension);
        End If;
      END IF;
      IF v_end IN ('BOTH','END') THEN
        If ( SIGN(p_extension) = 1 ) Then
          Extension(-1,-2,p_extension);
        Else
          Reduction(-1,-2, p_extension);
        End If;
       END IF;
      RETURN v_geom;
    EXCEPTION
      WHEN NULL_GEOMETRY THEN
        raise_application_error(-20001,'p_geom may not be NULL.');
      WHEN NULL_TOLERANCE THEN
        raise_application_error(-20001,'p_tolerance may not be NULL.');
      WHEN NULL_EXTENSION THEN
        raise_application_error(-20001,'p_extension value must not be 0 or NULL.');
      WHEN NOT_LINEAR THEN
        raise_application_error(-20001,'p_geom must be a single linestring.');
      WHEN INVALID_END THEN
        raise_application_error(-20001,'p_end value (' || v_end || ') must be START, BOTH or END');
      WHEN BAD_EXTENSION THEN
        Raise_Application_Error(-20001,'Reduction of geometry of length (' || V_Geom_Length || ') of each end by (' || Abs(P_Extension) || ') would result in zero length geometry.');
    END;
    Return V_Geom;
  end extend;

  Function SwapOrdinates( p_geom in mdsys.sdo_geometry,
                          p_pair in varchar2 default 'XY' /* Can be XY, XZ, XM, YZ, YM, ZM */ )
    return mdsys.sdo_geometry
  Is
    v_geom        mdsys.sdo_geometry := p_geom;
    v_pair        VARCHAR2(2)        := UPPER(SUBSTR(p_pair,1,2));
    v_dim         NUMBER;
    v_gtype       NUMBER;
    v_vertices    &&defaultSchema..ST_PointSet;
    v_i           PLS_INTEGER;
    v_j           PLS_INTEGER;
    v_isMeasured  Boolean;
    NULL_GEOMETRY EXCEPTION;
    INVALID_PAIR  EXCEPTION;
    INVALID_SWAP  EXCEPTION;
  Begin
    Begin
      IF ( v_pair is NULL
           Or
           v_pair not in ('XY', 'XZ', 'XM', 'YZ', 'YM', 'ZM' ) ) Then
          RAISE INVALID_PAIR;
      End If;

      IF ( v_geom is NULL ) THEN
        RAISE NULL_GEOMETRY;
      END IF;

      v_isMeasured := isMeasured(p_geom.sdo_gtype);
      v_dim := GetDimensions(p_geom.sdo_gtype);
      If ( ( v_dim = 2
             And
             v_pair in ('XZ', 'XM', 'YZ', 'YM', 'ZM' )
           )
           Or
           ( v_dim = 3
             And
             v_isMeasured
             And
             v_pair in ('XZ', 'YZ' )
           )
           Or
           ( v_dim = 3
             And
             Not v_isMeasured
             And
             v_pair in ('XM', 'YM', 'ZM' )
           )
        ) Then
        RAISE INVALID_SWAP;
      End If;

      -- Get basic geometry type (point, line, polygon)
      v_gtype := GetShortGType(p_geom.sdo_gtype);

      If ( v_geom.sdo_point is not null
           And
           v_pair in ('XY','XZ','YZ') ) Then
        v_geom.sdo_point.x := CASE v_pair WHEN 'XY' THEN p_geom.sdo_point.y WHEN 'XZ' THEN p_geom.sdo_point.z ELSE p_geom.sdo_point.x END;
        v_geom.sdo_point.y := CASE v_pair WHEN 'XY' THEN p_geom.sdo_point.x WHEN 'YZ' THEN p_geom.sdo_point.z ELSE p_geom.sdo_point.y END;
        v_geom.sdo_point.z := CASE v_pair WHEN 'XZ' THEN p_geom.sdo_point.x WHEN 'YZ' THEN p_geom.sdo_point.y ELSE p_geom.sdo_point.z END;
      End If;

      -- If Single Point, all done, else...
      IF ( v_gtype != 1
           And
           p_geom.sdo_ordinates is not null ) Then
        -- It's not a single point ...
        -- Process the geometry's ordinate array

        -- Copy the ordinates array
        If ( DBMS_DB_VERSION.VERSION < 10 ) Then
            SELECT &&defaultSchema..ST_Point(a.x,a.y,a.z,a.m)
              Bulk Collect into v_vertices
              FROM TABLE(&&defaultSchema..GEOM.GetPointSet(p_geom)) a;
        Else
            EXECUTE IMMEDIATE '
  SELECT &&defaultSchema..ST_Point(
                 v.x,
                 v.y,
                 CASE WHEN :1 <> 3 THEN v.z ELSE NULL END,
                 CASE WHEN :2 =  3 THEN v.z ELSE v.w END )
    FROM TABLE(sdo_util.GetVertices(:3)) v'
              BULK COLLECT INTO v_vertices
                        USING MOD(trunc(p_geom.sdo_gtype/100),10),
                              MOD(trunc(p_geom.sdo_gtype/100),10),
                              p_geom;
        End If;

        v_i := v_vertices.FIRST;           -- index into input coordinate array
        v_j := v_geom.sdo_ordinates.FIRST; -- index into output ordinate array
        FOR i IN 1 .. v_vertices.COUNT LOOP
          v_geom.sdo_ordinates (v_j)     := CASE WHEN ( v_pair = 'XY' )
                                                 THEN v_vertices(v_i).y
                                                 WHEN ( v_pair = 'XZ' ) And ( ( v_dim = 4 ) Or ( v_dim = 3 And Not v_isMeasured ) )
                                                 THEN v_vertices(v_i).z
                                                 WHEN ( v_pair = 'XM' ) And ( v_dim = 4 )
                                                 THEN v_vertices(v_i).m
                                                 WHEN ( v_pair = 'XM' ) And ( v_dim = 3 And v_isMeasured )
                                                 THEN v_vertices(v_i).z
                                                 ELSE v_vertices(v_i).x
                                             END;
          v_geom.sdo_ordinates (v_j + 1) := CASE WHEN ( v_pair = 'XY' )
                                                 THEN v_vertices(v_i).x
                                                 WHEN ( v_pair = 'YZ' ) And ( ( v_dim = 4 ) Or ( v_dim = 3 And Not v_isMeasured ) )
                                                 THEN v_vertices(v_i).z
                                                 WHEN ( v_pair = 'YM' ) And ( v_dim = 4 )
                                                 THEN v_vertices(v_i).m
                                                 WHEN ( v_pair = 'YM' ) And ( v_dim = 3 And v_isMeasured )
                                                 THEN v_vertices(v_i).z
                                                 ELSE v_vertices(v_i).y
                                             END;
          -- Do Z only if exists
          If ( ( v_dim = 4 ) OR ( ( v_dim = 3 ) And Not v_isMeasured ) And v_pair in ('XZ', 'YZ', 'ZM' ) ) Then
            v_geom.sdo_ordinates (v_j + 2) := CASE WHEN ( v_pair = 'XZ' )
                                                   THEN v_vertices(v_i).x
                                                   WHEN ( v_pair = 'YZ' ) And ( ( v_dim = 4 ) Or ( v_dim = 3 And Not v_isMeasured ) )
                                                   THEN v_vertices(v_i).y
                                                   WHEN ( v_pair = 'ZM' ) And ( v_dim = 4 )
                                                   THEN v_vertices(v_i).m
                                                   ELSE v_vertices(v_i).z
                                               END;
          End If;
          -- Do M only if exists
          If ( ( v_dim = 4 ) OR ( ( v_dim = 3 ) And v_isMeasured ) And v_pair in ('XM', 'YM', 'ZM' ) ) Then
            v_geom.sdo_ordinates (v_j + ( v_dim - 1)) := CASE WHEN ( v_pair = 'XM' )
                                                   THEN v_vertices(v_i).x
                                                   WHEN ( v_pair = 'YM' ) And ( ( v_dim = 4 ) Or ( v_dim = 3 And v_isMeasured ) )
                                                   THEN v_vertices(v_i).y
                                                   WHEN ( v_pair = 'ZM' ) And ( v_dim = 4 )
                                                   THEN v_vertices(v_i).z
                                                   ELSE v_vertices(v_i).m
                                               END;
          End If;
          v_i := v_i + 1;
          v_j := v_j + v_dim;
        END LOOP;

      End If;

      Return V_Geom;

    EXCEPTION
      WHEN NULL_GEOMETRY THEN
        raise_application_error(-20001,'p_geom may not be NULL.');
      WHEN INVALID_PAIR THEN
        raise_application_error(-20001,'p_pair (' || v_pair || ') must be one of  XY, XZ, XM, YZ, YM, ZM only.');
      WHEN INVALID_SWAP THEN
        Raise_Application_Error(-20001,'Requested swap (' || V_Dim || ',' || V_Pair ||')cannot occur as sdo_geometry dimensionality does not support it.' );
   End;

   Return V_Geom;

  End SwapOrdinates;

  Function TokenAggregator(p_tokenSet  IN  &&defaultSchema..T_Tokens,
                           p_delimiter IN  VARCHAR2 DEFAULT ',')
    Return VarChar2
  Is
    l_string     VARCHAR2(32767);
  Begin
    IF ( p_tokenSet is null ) THEN
        Return NULL;
    END IF;
    FOR i IN p_tokenSet.FIRST .. p_tokenSet.LAST LOOP
      IF i <> p_tokenSet.FIRST THEN
        l_string := l_string || p_delimiter;
      END IF;
      l_string := l_string || p_tokenSet(i).token;
    END LOOP;
    Return l_string;
  End TokenAggregator;

  Function concatLines(p_lines IN &&defaultSchema..GEOM.t_geometrySet)
    Return mdsys.sdo_geometry
  Is
    v_geometry mdsys.sdo_geometry;
  Begin
    IF ( p_lines is null ) THEN
        Return NULL;
    END IF;
    FOR i IN p_lines.FIRST .. p_lines.LAST LOOP
      IF ( i = p_lines.FIRST ) THEN
        v_geometry := p_lines(i).geometry;
      ELSE
        v_geometry := mdsys.sdo_util.concat_lines(v_geometry,p_lines(i).geometry);
      END IF;
    END LOOP;
    Return v_geometry;
  End concatLines;

Begin
  v_ADFDimensions := t_ADFDimensions(&&defaultSchema..CONSTANTS.c_1D_Prefix,
                                     &&defaultSchema..CONSTANTS.c_2D_Prefix,
                                     &&defaultSchema..CONSTANTS.c_3D_Prefix,
                                     &&defaultSchema..CONSTANTS.c_4D_Prefix,
                                     &&defaultSchema..CONSTANTS.c_5D_Prefix);

  v_ADFSDOGeometries(&&defaultSchema..CONSTANTS.uGeomType_Unknown)          := 'UNKNOWN';
  v_ADFSDOGeometries(&&defaultSchema..CONSTANTS.uGeomType_SinglePoint)      := &&defaultSchema..CONSTANTS.c_Point_WKT;
  v_ADFSDOGeometries(&&defaultSchema..CONSTANTS.uGeomType_SingleLineString) := &&defaultSchema..CONSTANTS.c_LineString_WKT;
  v_ADFSDOGeometries(&&defaultSchema..CONSTANTS.uGeomType_SinglePolygon)    := &&defaultSchema..CONSTANTS.c_Polygon_WKT;
  v_ADFSDOGeometries(&&defaultSchema..CONSTANTS.uGeomType_Collection)       := &&defaultSchema..CONSTANTS.c_Collection_WKT;
  v_ADFSDOGeometries(&&defaultSchema..CONSTANTS.uGeomType_MultiPoint)       := &&defaultSchema..CONSTANTS.c_Multi_Point_WKT;
  v_ADFSDOGeometries(&&defaultSchema..CONSTANTS.uGeomType_MultiLineString)  := &&defaultSchema..CONSTANTS.c_Multi_LineString_WKT;
  v_ADFSDOGeometries(&&defaultSchema..CONSTANTS.uGeomType_MultiPolygon)     := &&defaultSchema..CONSTANTS.c_Multi_Polygon_WKT;

  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_Unknown)               := '';
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_Point)                 := &&defaultSchema..CONSTANTS.c_Point_WKT;
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_OrientationPoint)      := 'ORIENTEDPOINT';
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_MultiPoint)            := &&defaultSchema..CONSTANTS.c_Multi_Point_WKT;
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_LineString)            := &&defaultSchema..CONSTANTS.c_LineString_WKT;
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_CircularArc)           := &&defaultSchema..CONSTANTS.c_CurveString_WKT;
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_Polygon)               := &&defaultSchema..CONSTANTS.c_Polygon_WKT;
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_PolyCircularArc)       := &&defaultSchema..CONSTANTS.c_CurvePolygon_WKT;
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_Rectangle)             := &&defaultSchema..CONSTANTS.c_Rectangle_WKT;
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_Circle)                := &&defaultSchema..CONSTANTS.c_CurvePolygon_WKT;
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_PolygonExterior)       := &&defaultSchema..CONSTANTS.c_Polygon_WKT;
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_PolygonInterior)       := &&defaultSchema..CONSTANTS.c_Polygon_WKT||'_INTERIOR';
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_PolyCircularArcExt)    := &&defaultSchema..CONSTANTS.c_CurveString_WKT;
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_PolyCircularArcInt)    := &&defaultSchema..CONSTANTS.c_CurveString_WKT||'_INTERIOR';
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_RectangleExterior)     := &&defaultSchema..CONSTANTS.c_Rectangle_WKT;
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_RectangleInterior)     := &&defaultSchema..CONSTANTS.c_Rectangle_WKT||'_INTERIOR';
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_CircleExterior)        := &&defaultSchema..CONSTANTS.c_CurvePolygon_WKT;
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_CircleInterior)        := &&defaultSchema..CONSTANTS.c_CurvePolygon_WKT||'_INTERIOR';
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_CompoundLineString)    := &&defaultSchema..CONSTANTS.c_Multi_CurveString_WKT;
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_CompoundPolygon)       := &&defaultSchema..CONSTANTS.c_Multi_CurvePolygon_WKT||'_INTERIOR';
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_CompoundPolyExt)       := &&defaultSchema..CONSTANTS.c_Multi_CurvePolygon_WKT;
  v_ADFElements(&&defaultSchema..CONSTANTS.uElemType_CompoundPolyInt)       := &&defaultSchema..CONSTANTS.c_Multi_CurvePolygon_WKT||'_INTERIOR';
END geom;
/
show errors

set serveroutput on size unlimited

Prompt Check package has compiled correctly ...
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'GEOM';
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

grant execute on geom to public;

QUIT;
