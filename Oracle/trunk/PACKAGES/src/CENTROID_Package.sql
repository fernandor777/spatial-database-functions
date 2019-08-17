DEFINE defaultSchema = '&1'

SET VERIFY OFF;

ALTER SESSION SET plsql_optimize_level=1;

CREATE OR REPLACE PACKAGE CENTROID
AUTHID CURRENT_USER
As
   TYPE T_Numbers     IS TABLE OF Number;

   TYPE T_Vectors     IS TABLE OF &&defaultSchema..T_Vector;

  /** @NOTE : These packages assume a minimum of 9iR2 as the SDO_MBR function uses SDO_AGGR_MBR for
  *           Locator users. If you are on 9iR1 then modify the SDO_MBR function to uncomment out
  *           the SQL that doesn't use SDO_AGGR_MBR and comment out the SDO_AGGR_MBR SQL.
  *   @NOTE : This package uses &&defaultSchema..T_VERTEX_TYPE which Oracle changed the definition of at 10g
  *           by adding an ID field. If you want to compile the package on 9i, manually change the
  *           code in ConvertGeometry so that it does not reference the last, ID, field.
  *   @NOTE : If sdo_geometry linestrings or polygons contain circular arcs they must be "stroked" before
  *           Calling the sdo_centroid function. If you have SPATIAL you can use sdo_geom.sdo_arc_densify().
  *           If not use this package's ConvertGeometry() function.
  *           SDO_GEOM.SDO_ARC_DENSIFY() function before calling sdo_centroid.
  *   @NOTE : SDO_Area does not work for non-2D geometries.
  **/

  /** ----------------------------------------------------------------------------------------
  * @function   : Generate_Series
  * @precis     : Function that generates a series of numbers mimicking PostGIS's function with
  *               the same name
  * @version    : 1.0
  * @usage      : Function generate_series(p_start pls_integer,
  *                                        p_end   pls_integer,
  *                                        p_step  pls_integer := 1)
  *                 Return CENTROID.t_integers Pipelined;
  *               eg SELECT s.* FROM TABLE(generate_series(1,1000,10)) s;
  * @param      : p_start   : Starting value
  * @paramtype  : p_start   : Integer
  * @param      : p_end     : Ending value.
  * @paramtype  : p_end     : Integer
  * @return     : p_step    : The step value of the increment between start and end
  * @rtnType    : p_step    : Integer
  * @history    : Simon Greener - June 2008 - Original coding.
  * @copyright  : Free for public use
  **/
  Function generate_series(p_start in pls_integer,
                           p_end   in pls_integer,
                           p_step  in pls_integer := 1 )
       Return &&defaultSchema..CENTROID.t_numbers Pipelined;

  /** ----------------------------------------------------------------------------------------
  * @function   : SDO_MBR
  * @precis     : Returns Minimum Bounding Rectangle of a given geometry.
  * @version    : 1.0
  * @usage      : Function SDO_MBR ( p_geometry IN MDSYS.SDO_GEOMETRY )
  *                 Return MDSYS.SDO_GEOMETRY Deterministic;
  * @example    : SELECT sdo_mbr(a.geom,0.01)
  *                 FROM ProjCompound2D a,
  *                      TABLE( &&defaultSchema..geom.GetElemInfo( a.geom ) ) ei
  *                WHERE a.geom is not null;
  * @param      : p_geometry  : A shape.
  * @paramtype  : p_geomery   : MDSYS.SDO_GEOMETRY
  * @param      : p_tolerance : Dimarray sdo_tolerance value
  * @paramtype  : p_tolerance : number
  * @return     : geometry    : A 2003 vertex described polygon
  * @rtnType    : sdo_geometry : MDSYS.SDO_GEOMETRY
  * @note       : Function is pipelined
  * @history    : Simon Greener - Jul 2008 - Original coding.
  * @copyright  : Free for public use
  **/
  Function SDO_MBR( p_geometry  IN MDSYS.SDO_GEOMETRY )
           Return MDSYS.SDO_GEOMETRY Deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : SDO_Length
  * @precis     : Function which computes length of linestrings or boundaries of polygons.
  * @version    : 1.0
  * @description: These are wrapper functions over SDO_3GL.LENGTH_AREA procedures that are
  *               not mentioned in Oracle's licensing as being functions limited to Spatial (EE)
  * @usage      : Function SDO_Length ( p_geometry IN MDSYS.SDO_GEOMETRY,
  *                                     p_tolerance IN Number
  *                                     p_units    IN VarChar2 )
  *                 Return Number Deterministic;
  *               eg fixedShape := &&defaultSchema..geom.length(shape,diminfo);
  * @param      : p_geometry   : A valid sdo_geometry.
  * @paramtype  : p_geomery    : MDSYS.SDO_GEOMETRY
  * @param      : p_tolerance  : The dimarray describing the shape.
  * @paramtype  : p_tolerance  : MDSYS.SDO_DIM_ARRAY
  * @param      : p_units      : The units in which the length is to be calculated eg meters, miles etc
  * @paramtype  : p_units      : varchar2
  * @return     : length       : Length of linestring or boundary of a polygon in required unit of measure
  * @rtnType    : length       : Number
  * @note       : Supplied p_units should exist in mdsys.SDO_UNITS_OF_MEASURE
  * @history    : Simon Greener - Oct 2007 - Original coding.
  * @copyright  : Free for public use
  **/
  Function SDO_Length( p_geometry  in mdsys.sdo_geometry,
                       p_tolerance in number,
                       p_units     in varchar2 default NULL )
    Return number deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : SDO_AREA
  * @precis     : Function which computes area of a polygon.
  * @version    : 1.0
  * @description: These are wrapper functions over SDO_3GL.LENGTH_AREA procedures that are
  *               not mentioned in Oracle's licensing as being functions limited to Spatial (EE)
  * @usage      : Function SDO_Area ( p_geometry IN MDSYS.SDO_GEOMETRY,
  *                                   p_dimarray IN MDSYS.SDO_DIM_ARRAY
  *                                   p_units    IN VarChar2 )
  *                 Return Number Deterministic;
  *               eg fixedShape := sdo_area(shape,tolerance);
  * @param      : p_geometry   : A valid sdo_geometry.
  * @paramtype  : p_geomery    : MDSYS.SDO_GEOMETRY
  * @param      : p_tolerance  : The vertex tolerance .
  * @paramtype  : p_tolerance  : NUMBER
  * @return     : area         : Area of a polygon in required unit of measure
  * @rtnType    : area         : Number
  * @note       : Supplied p_units should exist in mdsys.SDO_UNITS_OF_MEASURE
  * @history    : Simon Greener - Oct 2007 - Original coding.
  * @copyright  : Free for public use
  **/
  Function SDO_Area( p_geometry   in mdsys.sdo_geometry,
                     p_tolerance  in number,
                     p_units      in varchar2 default NULL)
    Return Number Deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ConvertGeometry
  * @precis     : Function which converts optimized rectangle components in a polygon to their
  *               stroked equivalent.
  * @version    : 1.0
  * @description: The centroid algorithm works with vector representations of the sides
  *               of a polygon generated by GetVector. Optimized rectangle are not directly
  *               supported in either the GetVector or sdo_centroid functions. If these exist
  *               the sdo_geometry should be put through this function before calling sdo_centroid.
  * @usage      : Function Converte_Geometry ( p_geometry IN MDSYS.SDO_GEOMETRY )
  *                 Return MdSys.Sdo_Geometry Deterministic;
  *               eg centroid := CENTROID.sdo_centroid(CENTROID.ConvertGeometry(shape),tolerance);
  * @param      : p_geometry   : A valid sdo_geometry.
  * @paramtype  : p_geomery    : MDSYS.SDO_GEOMETRY
  * @param      : p_Arc2Chord  : ArcToChord separation expressed in dataset units for converting arcs to stroked lines.
  * @paramtype  : p_Arc2Chord  : Number
  * @return     : geometry     : Converted, valid, geometry
  * @rtnType    : sdo_geometry : MDSYS.SDO_GEOMETRY
  * @note       : Oracle changed the definition of T_VERTEX_TYPE at 10g by adding and ID field. If you
  *               compiling on 9i manually change the code in ConvertGeometry so that it does not
  *               reference the ID field.
  * @history    : Simon Greener - July 2008 - Original coding.
  * @copyright  : Free for public use
  **/
  Function ConvertGeometry(p_geometry  In mdsys.sdo_geometry,
                           p_Arc2Chord In Number := 0.1)
    Return mdsys.sdo_geometry Deterministic;

  Function SDO_ARC_DENSIFY(p_geometry  In mdsys.sdo_geometry,
                           p_Arc2Chord In Number := 0.1)
    Return mdsys.sdo_geometry Deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : GetVector
  * @precis     : Places a geometry's coordinates into a pipelined vector data structure.
  * @version    : 3.0
  * @description: Loads the coordinates of a linestring, polygon geometry into a
  *               pipelined vector data structure for easy manipulation by other functions
  *               such as geom.SDO_Centroid.
  * @usage      : select *
  *                 from myshapetable a,
  *                      table(CENTROID.GetVector(a.shape));
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A geographic shape.
  * @return     : geomVector  : VectorSetType : The vector pipelined.
  * @requires   : Global data types coordRec, vectorRec and VectorSetType
  * @history    : Simon Greener - July 2006 - Original coding from GetVector
  * @history    : Simon Greener - July 2008 - Re-write to be standalone of other packages eg GF
  * @history    : Simon Greener - October 2008 - Removed 2D limits
  * @copyright  : Free for public use
  **/
  Function Vectorize(P_Geometry           In Mdsys.Sdo_Geometry,
                     p_filter_ordinate    in number   default null,
                     p_ordinate_dimension in varchar2 default 'X')
    Return &&defaultSchema..CENTROID.t_Vectors pipelined;

  /** =================== CENTROID Functions ====================== **/

  /* ----------------------------------------------------------------------------------------
  * @function   : centroid_p
  * @precis     : Generates centroid for a point (itself) or multipoint.
  * @version    : 1.3
  * @description: This function creates centroid of multipoint via averaging of ordinates.
  * @param      : p_geometry     : MDSYS.SDO_GEOMETRY : The geometry object.
  * @param      : p_round_x      : pls_integer : Ordinate rounding precision for X ordinates.
  * @param      : p_round_y      : pls_integer : Ordinate rounding precision for Y ordinates.
  * @param      : p_round_z      : pls_integer : Ordinate rounding precision for Z ordinates.
  * @return     : centroid       : MDSYS.SDO_GEOMETRY : The centroid.
  * @requires   : GetVector()
  * @history    : Simon Greener - Jul 2008 - Original coding of centroid_p as internal function
  * @history    : Simon Greener - Jan 2012 - Exposed internal function.
  * @copyright  : Free for public use
  **/
  FUNCTION centroid_p(p_geometry in mdsys.sdo_geometry,
                      p_round_x  IN pls_integer := 3,
                      p_round_y  IN pls_integer := 3,
                      p_round_z  IN pls_integer := 2)
    RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;

  /* ----------------------------------------------------------------------------------------
  * @function   : centroid_a
  * @precis     : Generates centroid for a polygon.
  * @version    : 1.3
  * @description: The standard mdsys.sdo_geom.sdO_centroid function does not guarantee
  *               that the centroid it generates falls inside the polygon.
  *               This function ensures that the centroid of any arbitrary polygon falls within the polygon.
  * @param      : p_geometry   : MDSYS.SDO_GEOMETRY : The geometry object.
  * @param      : P_Method     : pls_integer 
  /** @param    : p_method     : number : 0 = use average of all Area's X Ordinates for starting centroid Calculation
  *                                      10 = use average of all Area's Y Ordinates for starting centroid Calculation
  *                                       1 = Use centre X Ordinate of geometry MBR
  *                                      11 = Use centre Y Ordinate of geometry MBR
  *                                       2 = User supplied starting seed X ordinate value
  *                                      12 = User supplied starting seed Y ordinate value
  *                                       3 = Use Standard Oracle centroid function
  *                                       4 = Use Oracle implementation of PointOnSurface 
  ** @param     : p_Seed_Value : Number : Starting ordinate X/Y for which a Y/X that is inside the polygon is returned.
  * @param      : P_Dec_Places : pls_integer : Ordinate rounding precision for X, Y ordinates.
  * @param      : P_Tolerance  : number      : Tolerance for Oracle functions.
  * @param      : p_loops      : pls_integer : Number of attempts to find centroid based on small changes to seed
  * @return     : centroid     : MDSYS.SDO_GEOMETRY : The centroid.
  * @requires   : GetVector()
  * @history    : Simon Greener - Jul 2008 - Original coding of centroid_a as internal function
  * @history    : Simon Greener - Jan 2012 - Exposed internal function. Added p_seed_x support.
  * @copyright  : Free for public use
  **/
  function Centroid_A(P_Geometry   In Mdsys.Sdo_Geometry,
                      P_method     In Pls_Integer Default 1,
                      P_Seed_Value In Number      Default Null,
                      P_Dec_Places In Pls_Integer Default 3,
                      P_Tolerance  In NUMBER      Default 0.05,
                      p_loops      IN pls_integer DEFAULT 10)
    RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;

  /* ----------------------------------------------------------------------------------------
  * @function   : centroid_l
  * @precis     : Generates centroid for a linestring.
  * @version    : 1.3
  * @description: The standard mdsys.sdo_geom.sdo_centroid function does not guarantee
  *               that the centroid it generates falls inside the polygon.
  *               This function ensures that the centroid of any arbitrary polygon falls within the polygon.
  * @param      : p_geometry           : MDSYS.SDO_GEOMETRY : The geometry object.
  * @param      : p_position_as_ratio  : Number : Position along multi-line/line where "centroid" created.
  * @param      : p_round_x            : pls_integer : Ordinate rounding precision for X ordinates.
  * @param      : p_round_y            : pls_integer : Ordinate rounding precision for Y ordinates.
  * @param      : p_round_z            : pls_integer : Ordinate rounding precision for Z ordinates.
  * @return     : centroid             : MDSYS.SDO_GEOMETRY : The centroid.
  * @requires   : GetVector()
  * @history    : Simon Greener - Jul 2008 - Original coding of centroid_l as internal function
  * @history    : Simon Greener - Jan 2012 - Exposed internal function.
  * @copyright  : Free for public use
  **/
  FUNCTION centroid_l(p_geometry          in mdsys.sdo_geometry,
                      p_position_as_ratio in number := 0.5,
                      p_round_x           IN pls_integer := 3,
                      p_round_y           IN pls_integer := 3,
                      p_round_z           IN pls_integer := 2)
    RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;

  /* ----------------------------------------------------------------------------------------
  * @function   : sdo_centroid
  * @precis     : Generates centroid for a polygon.
  * @version    : 1.5
  * @description: The standard mdsys.sdo_geom.sdo_centroid function does not guarantee
  *               that the centroid it generates falls inside the polygon.   Nor does it
  *               generate a centroid for a multi-part polygon shape.
  *               This function ensures that the centroid of any arbitrary polygon
  *               falls within the polygon. Also provides centroid functions for multipoints and linestrings.
  * @param      : p_geometry     : MDSYS.SDO_GEOMETRY : The geometry object.
  * @param      : p_start        : pls_integer : 0 = Use average of all Area's vertices for starting X centroid calculation
  *                                              1 = Use centre X of MBR
  * @param      : p_largest      : pls_integer : 0 = Use smallest of any multipart geometry.
  *                                              1 = Use largest of any multipart geometry.
  * @param      : p_round_x      : pls_integer : Ordinate rounding precision for X ordinates.
  * @param      : p_round_y      : pls_integer : Ordinate rounding precision for Y ordinates.
  * @param      : p_round_z      : pls_integer : Ordinate rounding precision for Z ordinates.
  * @return     : centroid       : MDSYS.SDO_GEOMETRY : The centroid.
  * @requires   : GetVector()
  * @history    : Simon Greener - Mar 2008 - Total re-write of algorithm following on from cases the original algorithm didn't handle.
  *                                          The new algorithm does everything in a single SQL statement which can be run outside of this function if needed.
  *                                          The algorithm is based on a known method for filling a polygon which counts the type and number of crossings of a
  *                                          "ray" (in this case a vertical line) across a polygon boundary. The new algorithm also has improved handling of
  *                                          multi-part geometries and also generates a starting X ordinate for the vertical "ray" using vertex averaging
  *                                          rather than the mid point of a part's MBR. This is to try and "weight" the centroid more towards where detail exists.
  *               Simon Greener - Jul 2008 - Standalone version with no dependencies other than the need for external object types.
  * @copyright  : Free for public use
  **/
    Function sdo_centroid(
    p_geometry     IN MDSYS.SDO_GEOMETRY,
    p_start        IN pls_integer := 1,
    p_largest      IN pls_integer := 1,
    p_round_x      IN pls_integer := 3,
    p_round_y      IN pls_integer := 3,
    p_round_z      IN pls_integer := 2)
    RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;

  /**
  * Overload of main sdo_centroid function
  * @param      : p_tolerance    : Number : Single tolerance for use with all ordinates.
  *                                         Expressed in dataset units eg decimal degrees if 8311.
  *                                         See Convert_Distance for method of converting distance in meters to dataset units.
  **/
  function sdo_centroid (
    p_geometry     IN MDSYS.SDO_Geometry,
    p_start        IN pls_integer := 1,
    p_tolerance    IN NUMBER := 0.005)
    return MDSYS.SDO_Geometry deterministic;

  /**
  * Overload of main sdo_centroid function
  * @param      : p_dimarray  : Number : Supplies all tolerances when processing vertices.
  *                                      Note that the function requires the sdo_tolerances inside the diminfo to be expressed in dataset
  *                                      units eg decimal degrees if 8311. But for Oracle this is in meters for long/lat and dataset units otherwise.
  *                                      Thus use of this wrapper for geodetic data IS NOT RECOMMENDED.
  *                                      See Convert_Distance for method of converting distance in meters to dataset units.
  **/
  Function sdo_centroid(
    p_geometry     IN MDSYS.SDO_GEOMETRY,
    p_start        IN pls_integer := 1,
    p_dimarray     IN MDSYS.SDO_DIM_ARRAY)
    return MDSYS.SDO_Geometry deterministic;

  /* ----------------------------------------------------------------------------------------
  * @function   : Sdo_Multi_Centroid
  * @precis     : Generates centroids for a all parts of a multi-polygon.
  * @version    : 1.0
  * @description: The standard MDSYS.SDO_GEOM.SDO_GEOMETRY function does not guarantee
  *               that the centroid it generates falls inside the polygon.   Nor does it
  *               generate a centroid for a multi-part polygon shape.
  *               This function generates a point for every part of a 2007 multi-part polygon..
  * @param      : p_geometry : MDSYS.SDO_GEOMETRY : The polygon shape.
  * @param      : p_start    : Number : 0 = Use average of all Area's vertices for starting X centroid calculation
  *                                     1 = Use centre X of MBR
  * @param      : p_round_x  : Number : Ordinate rounding precision for X ordinates.
  * @param      : p_round_y  : Number : Ordinate rounding precision for Y ordinates.
  * @param      : p_round_z  : Number : Ordinate rounding precision for Z ordinates.
  * @return     : centroid   : MDSYS.SDO_GEOMETRY : The centroids of the parts as a multi-part shape.
  * @history    : Simon Greener - Jun 2006 - Original coding.
  * @copyright  : Free for public use
  **/
  function sdo_multi_centroid(
    p_geometry  IN MDSYS.SDO_Geometry,
    p_start     IN pls_integer := 1,
    p_round_x   IN pls_integer := 3,
    p_round_y   IN pls_integer := 3,
    p_round_z   IN pls_integer := 2)
   return MDSYS.SDO_Geometry deterministic;

  /**
  * Overload of main sdo_multi_centroid function
  * @param      : p_geometry  : MdSys.Sdo_Geometry : The sdo_geometry object.
  * @param      : p_start     : pls_integer : 0 = Use average of all Area's vertices for starting X centroid calculation
  *                                      1 = Use centre X of MBR
  * @param      : p_tolerance : Number : Tolerance used when processing vertices.
  * @return     : centroid    : MDSYS.SDO_GEOMETRY : The centroids of the parts as a multi-part shape.
  * @history    : Simon Greener - Jun 2006 - Original coding.
  * @copyright  : Free for public use
  **/
  function sdo_multi_centroid(
    p_geometry  IN MDSYS.SDO_Geometry,
    p_start     IN pls_integer := 1,
    p_tolerance IN NUMBER)
    return MDSYS.SDO_Geometry deterministic;

  /**
  * Overload of main sdo_multi_centroid function
  * @param      : p_geometry  : MdSys.Sdo_Geometry : The sdo_geometry object.
  * @param      : p_start     : pls_integer : 0 = Use average of all Area's vertices for starting X centroid calculation
  *                                      1 = Use centre X of MBR
  * @param      : p_dimarray  : Number : Supplies all tolerances when processing vertices.
  *                                      Note that the function requires the sdo_tolerances inside the diminfo to be expressed in dataset
  *                                      units eg decimal degrees if 8311. But for Oracle this is in meters for long/lat and dataset units otherwise.
  *                                      Thus use of this wrapper for geodetic data IS NOT RECOMMENDED.
  *                                      See Convert_Distance for method of converting distance in meters to dataset units.
  * @return     : Centroid    : MDSYS.SDO_GEOMETRY : The centroids of the parts as a multi-part shape.
  * @history    : Simon Greener - Jun 2006 - Original coding.
  * @copyright  : Free for public use
  **/
  function sdo_multi_centroid(
    p_geometry  IN MDSYS.SDO_Geometry,
    p_start     IN pls_integer := 1,
    p_dimarray  IN MDSYS.SDO_Dim_Array)
    return MDSYS.SDO_Geometry deterministic;

End Centroid;
/
show errors

CREATE OR REPLACE PACKAGE BODY CENTROID
AS
  c_module_name          CONSTANT varchar2(256) := 'CENTROID';

  c_PI                   CONSTANT NUMBER(16,14) := 3.14159265358979;
  c_MaxVal               CONSTANT number        :=  999999999999.99999999;
  c_MinVal               CONSTANT number        := -999999999999.99999999;

  c_i_circle_error       CONSTANT NUMBER        := -20101;
  c_s_circle_error       CONSTANT VARCHAR2(100) := 'Three points are collinear and no finite-radius circle through them exists';
  c_i_centroid           CONSTANT INTEGER       := -20102;
  c_s_centroid           CONSTANT VARCHAR2(250) := 'sdo_centroid only supported on LineString (xxx2), Polygon (xxx3), Multi-LineString (xxx5) and Multi-Polygon (xxx7) geometries.';
  c_i_paracentroid       CONSTANT INTEGER       := -20103;
  c_s_paracentroid       CONSTANT VARCHAR2(250) := 'sdo_centroid calculation failed: perhaps supplied tolerance is not in projection units eg 0.000001 decimal degrees?';
  c_i_multi              CONSTANT INTEGER       := -20104;
  c_s_multi              CONSTANT VARCHAR2(250) := 'Multi-Centroid only supported on multi-LineString and multi-Polygon shapes.';
  c_i_CircArc2LineString CONSTANT NUMBER        := -20105;
  c_s_CircArc2LineString CONSTANT VARCHAR2(100) := 'Problem converting circular arc to a linestring';
  c_i_CircleProperties   CONSTANT NUMBER        := -20106;
  c_s_CircleProperties   CONSTANT VARCHAR2(100) := 'Circle properties cannot be computed when converting circular arc to a linestring';
  c_i_Circle2Polygon     CONSTANT NUMBER        := -20107;
  c_s_Circle2Polygon     CONSTANT VARCHAR2(100) := 'Problem converting Circle to Polygon.';
  c_i_linecentroid       CONSTANT INTEGER       := -20108;
  c_s_linecentroid       CONSTANT VARCHAR2(250) := 'sdo_centroid calculation failed: couldn''t find segment containing centroid.';
  c_i_arcs_unsupported   CONSTANT INTEGER       := -20109;
  C_S_Arcs_Unsupported   Constant Varchar2(100) := 'Geometries with Circular Arcs not supported.';
  c_i_null_tolerance     CONSTANT INTEGER       := -20110;
  c_s_null_tolerance     CONSTANT VARCHAR2(100) := 'Input tolerance must not be null';
  c_i_null_geometry      CONSTANT INTEGER       := -20111;
  c_s_null_geometry      CONSTANT VARCHAR2(100) := 'Input geometry must not be null';
  c_i_null_diminfo       CONSTANT INTEGER       := -20112;
  c_s_null_diminfo       CONSTANT VARCHAR2(100) := 'Input dimarray must not be null';
  c_i_null_round_factor  CONSTANT INTEGER       := -20113;
  c_s_null_round_factor  CONSTANT VARCHAR2(100) := 'Input round factor x must not be null';
  c_i_wrong_ordinate_dim CONSTANT INTEGER       := -20114;
  c_s_wrong_ordinate_dim CONSTANT VARCHAR2(100) := 'Input Ordinate Dimension Must be X or Y';

  g_spatial              Number := 0; /* 0 means Locator, > 0 means Spatial */
  g_db_version           Number;

  Procedure setOraVersion
  As
    v_version       varchar2(4000);
    v_db_version    number;
    v_compatibility varchar2(4000);
  begin
    -- DBMS_DB_VERSION.VERSION not guaranteed for 9i
    dbms_utility.db_version(v_version,v_compatibility);
    v_db_version := to_number(replace(substr(v_version,1,INSTR(v_version,'.')+1),'.','0'));
    --dbms_output.put_line('Database version is ' || v_version || ' or ' || v_db_version); 
    g_db_version := v_db_version;
  end setOraVersion;

  Function generate_series(p_start in pls_integer,
                           p_end   in pls_integer,
                           p_step  in pls_integer := 1 )
       Return &&defaultSchema..CENTROID.t_numbers Pipelined
  As
    v_i    PLS_INTEGER := CASE WHEN p_start IS NULL THEN 1 ELSE p_start END;
    v_step PLS_INTEGER := CASE WHEN p_step IS NULL OR p_step = 0 THEN 1 ELSE p_step END;
    v_terminating_value PLS_INTEGER :=  p_start + TRUNC(ABS(p_start-p_end) / abs(v_step) ) * v_step;
  Begin
     -- Check for impossible combinations
     If ( p_start > p_end AND SIGN(p_step) = 1 )
        Or
        ( p_start < p_end AND SIGN(p_step) = -1 ) Then
       Return;
     End If;
     -- Generate integers
     LOOP
       PIPE ROW ( v_i );
       EXIT WHEN ( v_i = v_terminating_value );
       v_i := v_i + v_step;
     End Loop;
     Return;
  End generate_series;

  Function SDO_MBR( p_geometry IN MDSYS.SDO_GEOMETRY )
           Return MDSYS.SDO_GEOMETRY
  AS
    v_Minx     Number;
    v_Maxx     Number;
    v_miny     Number;
    v_maxy     Number;
  BEGIN
    IF ( g_spatial = 0 ) THEN
        SELECT min(v.x),max(v.x),min(v.y),max(v.y)
          INTO v_Minx, v_Maxx, v_miny, v_maxy
          FROM TABLE(mdsys.sdo_util.GetVertices(p_geometry)) v;
    ELSE
        SELECT min(v.x),max(v.x),min(v.y),max(v.y)
          INTO v_Minx, v_Maxx, v_miny, v_maxy
          FROM TABLE(mdsys.sdo_util.GetVertices(mdsys.sdo_geom.sdo_mbr(p_geometry))) v;
    END IF;
    Return mdsys.sdo_geometry(2003,
                              p_geometry.sdo_srid,
                              NULL,
                              mdsys.sdo_elem_info_array(1,1003,3),
                              mdsys.sdo_ordinate_array(v_minx,v_miny,
                                                       v_maxx,v_maxy));
  END SDO_MBR;

  Function SDO_Length( p_geometry  in mdsys.sdo_geometry,
                       p_tolerance in number,
                       p_units     in varchar2)
    Return number
  Is
    v_length number;
    v_area   number;
    v_units  varchar2(20) := p_units;
  Begin
    IF ( p_geometry is null ) then
       return null;
    End If;
    /* If  you are using Locator AND are on using Oracle database up to and including
    *  10gR2 you are not licensed for sdo_geom.sdo_length even though you can execute it.
    *  Uncomment out the following ensuring you have execute permissions on mdsys.sdo_3gl
    *
    If ( p_geometry.sdo_srid is null ) Then
      v_units := NULL;
    End If;
    mdsys.sdo_3gl.length_area(Generate_DimInfo(case when p_geometry.sdo_gtype < 3000 then 2 else 3 end, p_tolerance),
        p_geometry,
        1, -- 2 is area; 1 is length, v_units, Seems to be flakey
        v_length,
        v_area);
    */
    -- Comment out the following if  you are not licensed for use of sdo_length
    v_length := case when p_units is null
                     then mdsys.sdo_geom.sdo_length(p_geometry,p_tolerance)
                     else mdsys.sdo_geom.sdo_length(p_geometry,p_tolerance,p_units)
                 end;
    return v_length;
  End SDO_Length;

  Function SDO_Area( p_geometry  in mdsys.sdo_geometry,
                     p_tolerance in number,
                     p_units     in varchar2 )
    Return number
  Is
    v_length number;
    v_area   number;
    v_units  varchar2(20) := p_units;
  Begin
    IF ( p_geometry is null ) then
       return null;
    End If;
    /* If  you are using Locator AND are on using Oracle database up to and including
    *  10gR2 you are not licensed for sdo_geom.sdo_length even though you can execute it.
    *  Uncomment out the following ensuring you have execute permissions on mdsys.sdo_3gl
    *
    If ( p_geometry.sdo_srid is null ) Then
      v_units := NULL;
    End If;
    mdsys.sdo_3gl.length_area(Generate_DimInfo(case when p_geometry.sdo_gtype < 3000 then 2 else 3 end, p_tolerance),
        p_geometry,
        2, -- 2 is area; 1 is length
        -- v_units, Seems to be flakey returning "ORA-13205: internal error while parsing spatial parameters"
        -- if provided with SQ_M, SQ_KM, Square Meter etc
        v_length,
        v_area);
    */
    -- Comment out the following if  you are not licensed for use of sdo_length
    v_area := case when p_units is null
                   then mdsys.sdo_geom.sdo_area(p_geometry,p_tolerance)
                   else mdsys.sdo_geom.sdo_area(p_geometry,p_tolerance,p_units)
               end;
    return v_area;
  End SDO_Area;

  /** ---------------------------------------------------------------------------------
   ** Functions and Procedures for ConvertGeometry
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
                            p_coord      in  &&defaultSchema..T_Vertex )
  Is
  Begin
    ADD_Coordinate( p_ordinates, p_dim, p_coord.x, p_coord.y, p_coord.z, p_coord.w);
  END Add_Coordinate;

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

  /* =================== COGO FUNCTIONS ===================================== */

  function FindCircle(p_X1     in number, p_Y1 in number,
                      p_X2     in number, p_Y2 in number,
                      p_X3     in number, p_Y3 in number,
                      p_CX     in out nocopy NUMBER,
                      p_CY     in out nocopy NUMBER,
                      p_Radius in out nocopy NUMBER)
          return boolean
  Is
    bFindCircle Boolean;
    dA          NUMBER;
    dB          NUMBER;
    dC          NUMBER;
    dD          NUMBER;
    dE          NUMBER;
    dF          NUMBER;
    dG          NUMBER;
  BEGIN
    bFindCircle := True;
    dA := p_X2 - p_X1;
    dB := p_Y2 - p_Y1;
    dC := p_X3 - p_X1;
    dD := p_Y3 - p_Y1;
    dE := dA * (p_X1 + p_X2) + dB * (p_Y1 + p_Y2);
    dF := dC * (p_X1 + p_X3) + dD * (p_Y1 + p_Y3);
    dG := 2.0 * (dA * (p_Y3 - p_Y2) - dB * (p_X3 - p_X2));
    -- If dG is zero then the three points are collinear and no finite-radius
    -- circle through them exists.
    If ( dG = 0 ) Then
      bFindCircle := False;
    Else
      p_CX := (dD * dE - dB * dF) / dG;
      p_CY := (dA * dF - dC * dE) / dG;
      p_Radius := sqrt(power(p_X1 - p_CX,2) + power(p_Y1 - p_CY,2) );
    End If;
    return bFindCircle;
  end FindCircle;

  Function Bearing(dE1 in number,
                   dN1 in number,
                   dE2 in number,
                   dN2 in number)
  Return Number
  IS
      dBearing Number;
      dEast Number;
      dNorth Number;
  BEGIN
      dEast := dE2 - dE1;
      dNorth := dN2 - dN1;
      If ( dEast = 0 ) Then
          If ( dNorth < 0 ) Then
              dBearing := c_PI;
          Else
              dBearing := 0;
          End If;
      Else
          dBearing := -aTan(dNorth / dEast) + c_PI / 2;
      End If;
      If ( dEast < 0 ) Then
          dBearing := dBearing + c_PI;
      End If;
      Return dBearing;
  End Bearing;

  Function OptimalCircleSegments( dRadius in number,
                                  dArcToChordSeparation in number)
  Return Integer
  Is
    dAngleRad Number;
    dCentreToChordMidPoint Number;
  BEGIN
     dCentreToChordMidPoint := dRadius - dArcToChordSeparation;
     dAngleRad := 2 * aCos(dCentreToChordMidPoint/dRadius);
    Return CEIL( (2 * c_PI) / dAngleRad );
  END OptimalCircleSegments;

  Function CrossProductLength(dStartX in number,
                              dStartY in number,
                              dCentreX in number,
                              dCentreY in number,
                              dEndX in number,
                              dEndY in number)
  Return Number
  IS
      dCentreStartX Number;
      dCentreStartY Number;
      dCentreEndX Number;
      dCentreEndY Number;
  BEGIN
      --Get the vectors' coordinates.
      dCentreStartX := dStartX - dCentreX;
      dCentreStartY := dStartY - dCentreY;
      dCentreEndX   := dEndX - dCentreX;
      dCentreEndY   := dEndY - dCentreY;
      --Calculate the Z coordinate of the cross product.
      Return dCentreStartX * dCentreEndY - dCentreStartY * dCentreEndX;
  END CrossProductLength;

  Function DotProduct(dStartX in number,
                      dStartY in number,
                      dCentreX in number,
                      dCentreY in number,
                      dEndX in number,
                      dEndY in number)
  Return Number
  IS
      dCentreStartX Number;
      dCentreStartY Number;
      dCentreEndX   Number;
      dCentreEndY   Number;
  BEGIN
      --Get the vectors' coordinates.
      dCentreStartX := dStartX - dCentreX;
      dCentreStartY := dStartY - dCentreY;
      dCentreEndX   :=   dEndX - dCentreX;
      dCentreEndY   :=   dEndY - dCentreY;
      --Calculate the dot product.
      Return dCentreStartX * dCentreEndX + dCentreStartY * dCentreEndY;
  End DotProduct;

  Function AngleBetween3Points(dStartX in number,
                               dStartY in number,
                               dCentreX in number,
                               dCentreY in number,
                               dEndX in number,
                               dEndY in number)
  Return Number
  IS
      dDotProduct   Number;
      dCrossProduct Number;
  BEGIN
      --Get the dot product and cross product.
      dDotProduct   := DotProduct(dStartX, dStartY, dCentreX, dCentreY, dEndX, dEndY);
      dCrossProduct := CrossProductLength(dStartX, dStartY, dCentreX, dCentreY, dEndX, dEndY);
      --Calculate the angle in Radians.
      Return ATan2(dCrossProduct, dDotProduct);
  End AngleBetween3Points;

  /* ----------------------------------- ConvertGeometry Function itself -------- */

  Function ConvertGeometry(p_geometry  in mdsys.sdo_geometry,
                           p_Arc2Chord in Number := 0.1 )
    Return mdsys.sdo_geometry
  Is
    CURSOR c_coordinates( p_geometry  in mdsys.sdo_geometry,
                          p_start     in number,
                          p_end       in number) Is
    SELECT coord
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
            ) b
     WHERE b.coord.id BETWEEN p_start AND p_end;

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
        If Not FindCircle(dStart.X,  dStart.Y,
                          dMid.X,    dMid.Y,
                          dEnd.X,    dEnd.Y,
                          dCentreX, dCentreY, dRadius) Then
          raise_application_error(c_i_CircleProperties,
                                  c_s_CircleProperties,False);
          Return Null;
        End If;
        iDimension := case when dStart.Z is null then 2 else case when dStart.W is null then 3 else 4 end end;

        dBearingStart    := Bearing(dCentreX, dCentreY, dStart.X, dStart.Y);
        -- Compute number of segments for whole circle
        iOptimalSegments := OptimalCircleSegments(dRadius, p_Arc2Chord);
        dTheta1 := AngleBetween3Points(dStart.X, dStart.Y, dCentreX, dCentreY, dMid.X, dMid.Y);
        dTheta2 := AngleBetween3Points(dMid.X,   dMid.Y,   dCentreX, dCentreY, dEnd.X, dEnd.Y);
        vRotation := case when dTheta1 < 0 or dTheta2 < 0 then -1 else 1 end;
        dTheta    := (ABS(dTheta1) + ABS(dTheta2)) * vRotation;

        -- Compute number of segments just for this arc
        iOptimalSegments := Round(iOptimalSegments * (dTheta / (2 * c_PI)));
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
                dTheta := 2 * c_PI + dTheta;
            End If;
            --dDeltaTheta should be -ve
            dThetaStart := dBearingStart - c_PI / 2;
        Else
            --angle is anticlockwise
            If ( iOptimalSegments > 0 ) Then
                --circularArc is clockwise so get the opposite angle (Should be -ve)
                dTheta := dTheta - (2 * c_PI);
            End If;
            --dDeltaTheta should be +ve
        End If;
        iAbsSegments := Abs(iOptimalSegments);
        dDeltaTheta := dTheta / iAbsSegments;

        --compensate for cartesian angles versus compass bearing
        If dBearingStart = 0 Then
            dThetaStart := c_PI / 2;
        ElsIf (dBearingStart > 0) And (dBearingStart <= c_PI / 2) Then
            dThetaStart := c_PI / 2 - dBearingStart;
        ElsIf (dBearingStart > c_PI / 2) Then
            dThetaStart := 2 * c_PI - (dBearingStart - c_PI / 2);
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
        dDeltaTheta := 2 * c_PI / iSegments;
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
            raise_application_error(c_i_CircArc2Linestring,
                                    c_s_CircArc2Linestring,False);
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
        If FindCircle(v_start_coord.X, v_start_coord.Y,
                      v_mid_coord.X, v_mid_coord.Y,
                      v_end_coord.X, v_end_coord.Y,
                      v_CentreX, v_CentreY, v_Radius) Then
            iOptimalCircleSegments := OptimalCircleSegments(v_Radius, p_Arc2Chord);
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
              raise_application_error(c_i_Circle2Polygon,
                                      c_s_Circle2Polygon,False);
              RETURN ;
            Else
              -- write to ordinate array
              FOR rec IN c_Arc_Points(v_geometry) LOOP
                Add_Coordinate(v_ordinates,v_dims,rec.x,rec.y,rec.z,rec.w);
              END LOOP;
            End If;
        Else
          raise_application_error(c_i_CircleProperties,
                                  c_s_CircleProperties,False);
          RETURN;
        End If;
    End StrokeCircle;

  Begin
    If ( p_geometry is NULL ) Then
      raise NULL_GEOMETRY;
    End If;

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
        raise_application_error(c_i_null_geometry, c_s_null_geometry,TRUE);
        RETURN p_geometry;
  End ConvertGeometry;

  Function SDO_ARC_DENSIFY(p_geometry  in mdsys.sdo_geometry,
                           p_Arc2Chord in Number := 0.1 )
    Return mdsys.sdo_geometry
  Is
  BEGIN
     RETURN &&defaultSchema..CENTROID.ConvertGeometry(p_geometry,p_Arc2Chord);
  END SDO_ARC_DENSIFY;

  /** -------------------------- End of Functions and Procedures for ConvertGeometry
   **/

  /** ----------------------------------------------------------------------------------------
  * @function   : isCompound
  * @precis     : A function that tests whether an sdo_geometry contains circular arcs
  * @version    : 1.0
  * @history    : Simon Greener - Dec 2008 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. (http://creativecommons.org/licenses/by-sa/2.5/au/)
  **/
  Function isCompound(p_elem_info in mdsys.sdo_elem_info_array)
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
   End IsCompound;

  Function GetNumRings( p_geometry  in mdsys.sdo_geometry,
                        p_ring_type in integer default 0 /* 0 = ALL; 1 = OUTER; 2 = INNER */ )
    Return Number
  Is
     v_ring_count number := 0;
     v_ring_type  number := p_ring_type;
     v_elements   number;
     v_etype      pls_integer;
  Begin
     If ( p_geometry is null ) Then
        return 0;
     End If;
     If ( v_ring_type not in (0,1,2) ) Then
        v_ring_type := 0;
     End If;
     v_elements := ( ( p_geometry.sdo_elem_info.COUNT / 3 ) - 1 );
     <<element_extraction>>
     for v_i IN 0 .. v_elements LOOP
       v_etype := p_geometry.sdo_elem_info(v_i * 3 + 2);
       If  ( v_etype in (1003,1005,2003,2005) and 0 = v_ring_type )
        OR ( v_etype in (1003,1005)           and 1 = v_ring_type )
        OR ( v_etype in (2003,2005)           and 2 = v_ring_type ) Then
           v_ring_count := v_ring_count + 1;
       end If;
     end loop element_extraction;
     Return v_ring_count;
  End GetNumRings;

  Function Vectorize(P_Geometry           In Mdsys.Sdo_Geometry,
                     p_filter_ordinate    in number   default null,
                     p_ordinate_dimension in varchar2 default 'X')
    Return &&defaultSchema..Centroid.T_Vectors Pipelined
  Is
    v_ordinate_dimension varchar2(1) := SUBSTR(UPPER(NVL(p_ordinate_dimension,'X')),1,1);
    v_element            mdsys.sdo_geometry;
    v_ring               mdsys.sdo_geometry;
    v_element_no         pls_integer;
    v_ring_no            pls_integer;
    v_num_elements       pls_integer;
    v_num_rings          pls_integer;
    v_dimensions         pls_integer;
    v_coordinates        mdsys.vertex_set_type;
    NULL_GEOMETRY        EXCEPTION;
    NOT_CIRCULAR_ARC     EXCEPTION;
    WRONG_ORDINATE_DIMENSION EXCEPTION;

    Function Vertex2Vertex(p_vertex in mdsys.vertex_type,
                           P_Id     In Pls_Integer)
      Return &&defaultSchema..T_Vertex deterministic
    Is
    Begin
       if ( p_vertex is null ) then
          return null;
       end if;
       return new &&defaultSchema..T_Vertex(p_vertex.x,
                                   p_vertex.y,
                                   p_vertex.z,
                                   p_vertex.w,
                                   p_id);
    End Vertex2Vertex;

  Begin
    If ( P_Geometry Is Null ) Then
       raise NULL_GEOMETRY;
    End If;

    -- No Points
    -- DEBUG  dbms_output.put_line(p_geometry.sdo_gtype);
    If ( Mod(p_geometry.sdo_gtype,10) in (1,5) ) Then
      Return;
    End If;

    If ( isCompound(p_geometry.sdo_elem_info) ) Then
      raise NOT_CIRCULAR_ARC;
    End If;

    If ( p_filter_ordinate is not null
     and v_ordinate_dimension not in ('X','Y') 
     and p_filter_ordinate is not null ) Then
      raise WRONG_ORDINATE_DIMENSION;
    End If;
    
    v_num_elements := MDSYS.SDO_UTIL.GETNUMELEM(p_geometry);
    <<all_elements>>
    FOR v_element_no IN 1..v_num_elements LOOP
       v_element := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_element_no,0);
       If ( v_element is not null ) Then
           -- Polygons
           -- Need to check for inner rings
           --
           If ( v_element.get_gtype() = 3) Then
              -- Process all rings in this single polygon have?
              v_num_rings := GetNumRings(v_element,0);
              <<All_Rings>>
              FOR v_ring_no IN 1..v_num_rings LOOP
                  v_ring := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_element_no,v_ring_no);
                  -- Now generate marks
                  If ( v_ring is not null ) Then
                      v_coordinates := mdsys.sdo_util.getVertices(v_ring);
                      If ( v_ring.sdo_elem_info(2) in (1003,2003) And v_coordinates.COUNT = 2 ) Then
                         Pipe Row( &&defaultSchema..T_Vector(1, v_element_no, v_ring_no,
                                                    Vertex2vertex(V_Coordinates(1),1),
                                                    &&defaultSchema..T_Vertex(v_coordinates(2).x, v_coordinates(1).y,V_Coordinates(1).Z, V_Coordinates(1).W,2) ) );
                         PIPE ROW( &&defaultSchema..t_vector(2, v_element_no, v_ring_no,
                                                    &&defaultSchema..T_Vertex(v_coordinates(2).x, v_coordinates(1).y,v_coordinates(1).z, v_coordinates(1).w,2),
                                                    Vertex2Vertex(v_coordinates(2),3) ) );
                         Pipe Row( T_Vector(3,v_element_no, v_ring_no,
                                            Vertex2vertex(V_Coordinates(2),3),
                                                          &&defaultSchema..T_Vertex(v_coordinates(1).x, v_coordinates(2).y,v_coordinates(1).z, v_coordinates(1).w,4) ) );
                         PIPE ROW( &&defaultSchema..t_vector(4, v_element_no, v_ring_no,
                                                    &&defaultSchema..T_Vertex(v_coordinates(1).x, v_coordinates(2).y,v_coordinates(1).z, v_coordinates(1).w,4),
                                                    Vertex2Vertex(v_coordinates(1),5) ) );
                      Else
                         For V_Coord_No In 1..V_Coordinates.Count-1 Loop
                            If ( p_filter_ordinate is not null ) then
                               If ( ( v_ordinate_dimension = 'X' 
                                      and 
                                      ( p_filter_ordinate BETWEEN   v_coordinates(v_coord_no).x AND v_coordinates(v_coord_no+1).x
                                        OR 
                                        p_filter_ordinate BETWEEN v_coordinates(v_coord_no+1).x AND   v_coordinates(v_coord_no).x 
                                      )
                                    ) 
                                    OR
                                    ( v_ordinate_dimension = 'Y' 
                                      and 
                                      ( p_filter_ordinate BETWEEN   v_coordinates(v_coord_no).y AND v_coordinates(v_coord_no+1).y
                                        OR 
                                        p_filter_ordinate BETWEEN v_coordinates(v_coord_no+1).y AND   v_coordinates(v_coord_no).y 
                                      )
                                    )
                                  ) Then
                                Pipe Row( &&defaultSchema..t_vector(V_Coord_No,v_element_no,v_ring_no,
                                                           &&defaultSchema..T_Vertex(
                                                                    v_coordinates(v_coord_no).x,
                                                                    v_coordinates(v_coord_no).y,
                                                                    v_coordinates(v_coord_no).z,
                                                                    v_coordinates(v_coord_no).w,
                                                                    v_coord_no),
                                                           &&defaultSchema..T_Vertex(
                                                                    v_coordinates(v_coord_no+1).x,
                                                                    v_coordinates(v_coord_no+1).y,
                                                                    v_coordinates(v_coord_no+1).z,
                                                                    v_coordinates(v_coord_no+1).w,
                                                                    v_coord_no + 1) ) );
                               End If;
                            Else
                              Pipe Row( &&defaultSchema..t_vector(V_Coord_No,v_element_no,v_ring_no,
                                                         &&defaultSchema..T_Vertex(
                                                                  v_coordinates(v_coord_no).x,
                                                                  v_coordinates(v_coord_no).y,
                                                                  v_coordinates(v_coord_no).z,
                                                                  v_coordinates(v_coord_no).w,
                                                                  v_coord_no),
                                                         &&defaultSchema..T_Vertex(
                                                                  v_coordinates(v_coord_no+1).x,
                                                                  v_coordinates(v_coord_no+1).y,
                                                                  v_coordinates(v_coord_no+1).z,
                                                                  v_coordinates(v_coord_no+1).w,
                                                                  v_coord_no + 1) ) );
                            End If;
                         END LOOP;
                      End If;
                  End If;
              END LOOP All_Rings;
           -- Linestrings
           --
           ElsIf ( v_element.get_gtype() = 2) Then
               v_coordinates := mdsys.sdo_util.getVertices(v_element);
               For V_Coord_No In 1..V_Coordinates.Count-1 Loop
                  If ( p_filter_ordinate is not null ) then
                   If ( ( v_ordinate_dimension = 'X' 
                          and 
                          ( p_filter_ordinate BETWEEN   v_coordinates(v_coord_no).x AND v_coordinates(v_coord_no+1).x
                            OR 
                            p_filter_ordinate BETWEEN v_coordinates(v_coord_no+1).x AND   v_coordinates(v_coord_no).x 
                          )
                        ) 
                        OR
                        ( v_ordinate_dimension = 'Y' 
                          and 
                          ( p_filter_ordinate BETWEEN   v_coordinates(v_coord_no).y AND v_coordinates(v_coord_no+1).y
                            OR 
                            p_filter_ordinate BETWEEN v_coordinates(v_coord_no+1).y AND   v_coordinates(v_coord_no).y 
                          )
                        )
                      ) Then
                      Pipe Row( &&defaultSchema..t_vector(V_Coord_No,v_element_no,v_ring_no,
                                                 &&defaultSchema..T_Vertex(
                                                          v_coordinates(v_coord_no).x,
                                                          v_coordinates(v_coord_no).y,
                                                          v_coordinates(v_coord_no).z,
                                                          v_coordinates(v_coord_no).w,
                                                          v_coord_no),
                                                 &&defaultSchema..T_Vertex(
                                                          v_coordinates(v_coord_no+1).x,
                                                          v_coordinates(v_coord_no+1).y,
                                                          v_coordinates(v_coord_no+1).z,
                                                          v_coordinates(v_coord_no+1).w,
                                                          v_coord_no + 1) ) );
                     End If;
                  Else
                    Pipe Row( &&defaultSchema..t_vector(V_Coord_No,v_element_no,v_ring_no,
                                               &&defaultSchema..T_Vertex(
                                                        v_coordinates(v_coord_no).x,
                                                        v_coordinates(v_coord_no).y,
                                                        v_coordinates(v_coord_no).z,
                                                        v_coordinates(v_coord_no).w,
                                                        v_coord_no),
                                               &&defaultSchema..T_Vertex(
                                                        v_coordinates(v_coord_no+1).x,
                                                        v_coordinates(v_coord_no+1).y,
                                                        v_coordinates(v_coord_no+1).z,
                                                        v_coordinates(v_coord_no+1).w,
                                                        v_coord_no + 1) ) );
                  End If;
               END LOOP;
           End If;
       End If;
   END LOOP all_elements;
   RETURN;
   EXCEPTION
      WHEN NULL_GEOMETRY THEN
        raise_application_error(c_i_null_geometry, c_s_null_geometry,TRUE);
        RETURN;
      WHEN NOT_CIRCULAR_ARC THEN
        raise_application_error(c_i_arcs_unsupported, c_s_arcs_unsupported,TRUE);
        RETURN;
      WHEN WRONG_ORDINATE_DIMENSION THEN
        raise_application_error(c_i_wrong_ordinate_dim, c_s_wrong_ordinate_dim, TRUE);
        RETURN;      
  End Vectorize;

  /** ======================= CENTROID FUNCTIONS =================================
  **/
  FUNCTION centroid_p(p_geometry in mdsys.sdo_geometry,
                      p_round_x  IN pls_integer := 3,
                      p_round_y  IN pls_integer := 3,
                      p_round_z  IN pls_integer := 2)
    RETURN MDSYS.SDO_GEOMETRY
  AS
    v_centroid MDSYS.SDO_GEOMETRY;
    v_point    MDSYS.SDO_GEOMETRY := p_geometry;
  BEGIN
    If ( p_geometry.sdo_point is not null ) Then
      return p_geometry;
    ElsIf ( Mod(p_geometry.Sdo_Gtype,10) = 1
            AND
            p_Geometry.Sdo_Elem_Info Is Null ) Then
      return mdsys.sdo_geometry(p_geometry.sdo_gtype,
                                p_geometry.sdo_srid,
                                mdsys.sdo_point_type(round(p_geometry.Sdo_Ordinates(1),p_round_x),
                                                     round(p_geometry.Sdo_Ordinates(2),p_round_y),
                                                     case when p_geometry.sdo_ordinates.count = 3
                                                          then round(p_geometry.Sdo_Ordinates(3),p_round_z)
                                                        else NULL
                                                    end),
                              null,null);
    END IF;
    -- rough as guts SQL average will do!
    SELECT mdsys.sdo_geometry(v_point.sdo_gtype,
                              v_point.sdo_srid,
                              mdsys.sdo_point_type(round(avg(v.x),p_round_x),
                                                   round(avg(v.y),p_round_y),
                                                   round(avg(v.z),p_round_z)),
                              null,
                              null) as centroid
      Into V_Centroid
      From Table(Mdsys.Sdo_Util.Getvertices(V_Point)) V;
    RETURN v_centroid;
    EXCEPTION
       WHEN OTHERS THEN
           raise_application_error(-20001,SQLERRM,TRUE);
           RETURN NULL;
  END centroid_p;

  function Centroid_A(P_Geometry   In Mdsys.Sdo_Geometry,
                      P_method     In Pls_Integer Default 1,
                      P_Seed_Value In Number      Default Null,
                      P_Dec_Places In Pls_Integer Default 3,
                      P_Tolerance  In NUmber      Default 0.05,
                      p_loops      IN pls_integer DEFAULT 10)
    RETURN MDSYS.SDO_GEOMETRY
  AS
    /** @param : p_method : number : 0 = use average of all Area's X Ordinates for starting centroid Calculation
    *                               10 = use average of all Area's Y Ordinates for starting centroid Calculation
    *                                1 = Use centre X Ordinate of geometry MBR
    *                               11 = Use centre Y Ordinate of geometry MBR
    *                                2 = User supplied starting seed X ordinate value
    *                               12 = User supplied starting seed Y ordinate value
    *                                3 = Use Standard Oracle centroid function
    *                                4 = Use Oracle implementation of PointOnSurface 
    * @param  : p_Seed_Value : Number : Starting ordinate X/Y for which a Y/X that is inside the polygon is returned.
    **/
    -- Some of these exceptions are global in the body of their package but are included to be consistent with the T_GEOMETRY object version.
    c_i_method        Constant Integer       := -20001;
    c_s_method        Constant VarChar2(100) := 'Method parameter must be one of (0, 1, 2, 3, 4, 10, 11, 12).';
    STARTING_POSITION EXCEPTION; PRAGMA EXCEPTION_INIT(STARTING_POSITION,-20001);
    c_i_seed          Constant Integer       := -20002;
    c_s_seed          Constant VarChar2(100) := 'Seed value not provided.';
    SEED_MBR          EXCEPTION; PRAGMA EXCEPTION_INIT(SEED_MBR,-20002);
    c_i_x_seed        Constant Integer       := -20003;
    c_s_x_seed        Constant VarChar2(100) := 'Seed value for p_method 2 (X) not between provided geometry''s MBR''s X ordinate range.';
    NO_X_SEED_VALUE   EXCEPTION; PRAGMA EXCEPTION_INIT(NO_X_SEED_VALUE,-20003);
    c_i_y_seed        Constant Integer       := -20004;
    c_s_y_seed        Constant VarChar2(100) := 'Seed value for p_method 12 (Y) not between provided geometry''s MBR''s Y ordinate range.';
    NO_Y_SEED_VALUE   EXCEPTION; PRAGMA EXCEPTION_INIT(NO_Y_SEED_VALUE,-20004);
    c_i_fail          CONSTANT INTEGER       := -20005;
    c_s_fail          CONSTANT VARCHAR2(250) := 'Calculation of Centroid for Area failed: perhaps supplied tolerance is not in projection units eg 0.000001 decimal degrees?';
    CENTROID_FAIL     EXCEPTION; PRAGMA EXCEPTION_INIT(CENTROID_FAIL,-20005);
    c_i_polygon       CONSTANT INTEGER       := -20006;
    c_s_polygon       CONSTANT VARCHAR2(250) := 'Method only operates on a single polygon. If MultiPolygon, use ST_Multi_Centroid.';
    NOT_POLYGON       EXCEPTION; PRAGMA EXCEPTION_INIT(NOT_POLYGON,-20006);
    c_i_null_geometry CONSTANT INTEGER       := -20007;
    c_s_null_geometry CONSTANT VARCHAR2(100) := 'Input geometry must not be null';
    NULL_GEOMETRY     EXCEPTION; PRAGMA EXCEPTION_INIT(NULL_GEOMETRY,-20007);

    v_method          pls_integer := NVL(P_method,1);
    v_dec_places      PLS_INTEGER := NVL(P_Dec_Places,3);
    v_tolerance       number      := NVL(p_tolerance,0.05);
    v_loop            pls_integer := NVL(p_loops,10);
    v_seed_value      NUMBER      := p_seed_value;
    v_mbr             MDSYS.SDO_GEOMETRY;
    v_centroid        MDSYS.SDO_GEOMETRY;
    v_not_inside      boolean     := true;
  Begin
    If ( p_geometry is NULL ) Then
       raise NULL_GEOMETRY;
    End If;
    IF ( p_geometry.Get_Gtype() <> 3 ) THEN
      raise NOT_POLYGON;
    END IF;

    -- Get MBR of polygon
    IF ( v_method NOT IN (0, 1, 2, 3, 4, 10, 11, 12) ) THEN
       raise STARTING_POSITION;
    END IF;

    -- Handle Oracle calls first
    IF ( v_method in (3,4) ) Then
      RETURN CASE v_method
                  WHEN 3 THEN mdsys.sdo_geom.sdo_centroid(      p_geometry,v_tolerance)
                  WHEN 4 THEN Mdsys.Sdo_Geom.Sdo_PointOnsurface(p_geometry,v_tolerance)
              END;
    END IF;

    -- Get X or Y ordinate from non user supplied values
    -- Need MBR for value checking.
    v_mbr := &&defaultSchema..CENTROID.sdo_mbr(p_geometry);

    -- Create starting seed point geometry from average of ordinates
    --
    IF ( v_method = 0 /* X as avg all ordinates */ ) THEN
      SELECT round(avg(p.x), v_dec_places) as x INTO v_seed_value FROM TABLE(mdsys.sdo_util.GetVertices(p_geometry)) p;
    ELSIF ( v_method = 10 /* Y as avg all ordinates */ ) THEN
      SELECT round(avg(p.x), v_dec_places) as x INTO v_seed_value FROM TABLE(mdsys.sdo_util.GetVertices(p_geometry)) p;
      SELECT round(avg(p.Y), v_dec_places) as Y INTO v_seed_value FROM TABLE(mdsys.sdo_util.GetVertices(p_geometry)) p;
    ELSIF ( v_method = 1 /* Centre X of MBR */ ) THEN
      v_seed_value := (v_mbr.sdo_ordinates(1 + p_geometry.Get_Dims()) + v_mbr.sdo_ordinates(1)) / 2.0;
    ELSIF ( v_method = 11 /* Centre Y of MBR */ ) THEN
      v_seed_value := (v_mbr.sdo_ordinates(2 + p_geometry.Get_Dims()) + v_mbr.sdo_ordinates(2)) / 2.0;
    ELSIF ( v_method = 2 ) THEN
       -- Check user seed between MBR X ordinate range of object
       IF ( v_Seed_Value <= v_mbr.sdo_ordinates(1)
         OR v_Seed_Value >= v_mbr.sdo_ordinates(1+p_geometry.Get_Dims()) ) THEN
         RAISE NO_X_SEED_VALUE;
       END IF;
    ELSIF ( v_method = 12 ) THEN
       -- Check user seed between MBR Y ordinate range of object
       IF ( v_Seed_Value <= v_mbr.sdo_ordinates(2)
         OR v_Seed_Value >= v_mbr.sdo_ordinates(2+p_geometry.Get_Dims()) ) THEN
         RAISE NO_Y_SEED_VALUE;
       END IF;
    END IF;

    -- Now find Centroid
    -- Centroid X is based on average x ordinate
    -- Centroid Y is computed using a variation on flood filling area geometries in graphics libraries
    -- (In following, the use of sdo_geom.sdo_mbr is posited on its use being licensed. If not, use the CENTROID.sdo_mbr() function in this package)
    --
    WHILE (v_not_inside and v_loop > 0) LOOP
      BEGIN
      v_seed_value := ROUND(v_seed_value,v_dec_places + 1);
      -- DEBUG dbms_output.put_line('v_seed_value(' || v_loop || '): '||v_seed_value);
      IF ( v_method in (0,1,2) ) Then
        SELECT MDSYS.SDO_GEOMETRY(2001,
                                  p_geometry.SDO_SRID,
                                  mdsys.sdo_point_type(f.CX,f.CY,NULL),
                                  NULL,NULL)
          INTO v_centroid
          FROM (SELECT z.x                 as cx,
                       z.y + ( ydiff / 2 ) as cy
                  FROM (SELECT w.id,
                               w.x,
                               w.y,
                               case when w.ydiff is null then 0 else w.ydiff end as ydiff,
                               case when w.id = 1
                                    then case when w.inout = 1
                                              then 'INSIDE'
                                              else 'OUTSIDE'
                                          end
                                    when w.inout = 99
                                    then 'OUTSIDE'
                                    when MOD(SUM(w.inout) OVER (ORDER BY w.id),2) = 1
                                         /* Need to look at previous result as inside/outside is a binary switch */
                                    then 'INSIDE'
                                    else 'OUTSIDE'
                                end as inout
                          FROM (SELECT rownum as id,
                                       u.x,
                                       u.y,
                                       case when u.touchCross in (-1,0,1) /* Cross */ then 1
                                            when u.touchCross in (-2,2)   /* Touch */ then 0
                                            when u.touchCross >= 99                   then 99
                                            else 0
                                        end as inout,
                                       ABS(LEAD(u.y,1) OVER(ORDER BY u.y) - u.y) As YDiff
                                  FROM (SELECT s.x,
                                               s.y,
                                               /* In cases where polygons have boundaries/holes that touch at a point we need to count them more than once */
                                               case when count(*) > 2 then 1 else sum(s.touchcross) end as touchcross
                                          FROM (SELECT t.element_id, t.subelement_id,
                                                       t.x,
                                                       t.y,
                                                       t.touchCross
                                                  FROM (SELECT r.element_id, r.subelement_id,
                                                               r.x,
                                                               case when (r.endx = r.startx)
                                                                    then (r.starty + r.endy ) / 2
                                                                    else round(r.starty + ( (r.endy-r.starty)/(r.endx-r.startx) ) * (r.x-r.startx),v_dec_places)
                                                                end as y,
                                                                case when ( r.x = r.startx and r.x = r.endx )
                                                                     then 99 /* Line is Vertical ie two touches */
                                                                     when ( ( r.x = r.startx and r.x > r.endx )
                                                                              or
                                                                            ( r.x = r.endX   and r.x > r.startX )
                                                                          )
                                                                     then -1 /* Left Touch */
                                                                     when ( ( r.x = r.endX   and r.x < r.startX  )
                                                                              or
                                                                            ( r.x = r.startX and r.x < r.endX )
                                                                          )
                                                                      then 1 /* Right Touch */
                                                                      else 0 /* cross */
                                                                  end as TouchCross
                                                            FROM (SELECT v.element_id    as element_id,
                                                                         v.subelement_id as subelement_id,
                                                                         v_seed_value         as x,
                                                                         round(v.startCoord.x,v_dec_places) as startX,
                                                                         round(v.startCoord.y,v_dec_places) as startY,
                                                                         round(  v.endCoord.x,v_dec_places) as endX,
                                                                         round(  v.endCoord.y,v_dec_places) as endY
                                                                       FROM TABLE(CENTROID.Vectorize(P_Geometry           => p_geometry,
                                                                                                     p_ordinate_dimension => 'X',
                                                                                                     p_filter_ordinate    => v_Seed_Value)) v
                                                                 ) r
                                                        ) t
                                                  ORDER BY t.y
                                               ) s
                                        /*WHERE s.touchCross <> 99*/
                                        GROUP BY s.element_id, s.subelement_id, s.x, s.y
                                        ORDER BY s.y
                                       ) u
                               ) w
                       ) z
                 WHERE z.inout = 'INSIDE'
                ORDER BY z.ydiff DESC
               ) f
         WHERE ROWNUM < 2;
      ELSIF ( v_method in (10,11,12) ) THEN
        SELECT MDSYS.SDO_GEOMETRY(2001,p_geometry.sdo_srid,mdsys.sdo_point_type(f.CX,f.CY,NULL),NULL,NULL)
          INTO v_centroid
          FROM (SELECT z.x + ( xdiff / 2 ) as cx,
                       z.y                 as cy
                  FROM (SELECT w.id,
                               w.x,
                               w.y,
                               case when w.xdiff is null then 0 else w.xdiff end as xdiff,
                               case when w.id = 1
                                    then case when w.inout = 1
                                              then 'INSIDE'
                                              else 'OUTSIDE'
                                          end
                                    when w.inout = 99
                                    then 'OUTSIDE'
                                    when MOD(SUM(w.inout) OVER (ORDER BY w.id),2) = 1
                                         /* Need to look at previous result as inside/outside is a binary switch */
                                    then 'INSIDE'
                                    else 'OUTSIDE'
                                end as inout
                          FROM (SELECT rownum as id,
                                       u.x,
                                       u.y,
                                       case when u.touchCross in (-1,0,1) /* Cross */ then 1
                                            when u.touchCross in (-2,2)   /* Touch */ then 0
                                            when u.touchCross >= 99                   then 99
                                            else 0
                                        end as inout,
                                       ABS(LEAD(u.x,1) OVER(ORDER BY u.x) - u.x) As xDiff
                                  FROM (SELECT s.x,
                                               s.y,
                                               /* In cases where polygons have boundaries/holes that touch at a point we need to count them more than once */
                                               case when count(*) > 2 then 1 else sum(s.touchcross) end as touchcross
                                          FROM (SELECT t.element_id,
                                                       t.subelement_id,
                                                       t.x,
                                                       t.y,
                                                       t.touchCross
                                                  FROM (SELECT r.element_id,
                                                               r.subelement_id,
                                                               r.y,
                                                               case when (r.endy = r.starty)
                                                                    then (r.startx + r.endx ) / 2
                                                                    else round(r.startx + ( (r.endx-r.startx)/(r.endy-r.starty) ) * (r.y-r.starty),v_dec_places)
                                                                end as x,
                                                                case when ( r.y = r.starty and r.y = r.endy )
                                                                     then 99 /* Line is Vertical ie two touches */
                                                                     when ( ( r.y = r.starty and r.y > r.endy )
                                                                              or
                                                                            ( r.y = r.endy   and r.y > r.starty )
                                                                          )
                                                                     then -1 /* Left Touch */
                                                                     when ( ( r.y = r.endy   and r.y < r.starty  )
                                                                              or
                                                                            ( r.y = r.starty and r.y < r.endy )
                                                                          )
                                                                      then 1 /* Right Touch */
                                                                      else 0 /* cross */
                                                                  end as TouchCross
                                                            FROM (SELECT v.element_id    as element_id,
                                                                         v.subelement_id as subelement_id,
                                                                         v_seed_value    as y,
                                                                         round(v.startCoord.x,v_dec_places) as startX,
                                                                         round(v.startCoord.y,v_dec_places) as startY,
                                                                         round(  v.endCoord.x,v_dec_places) as endX,
                                                                         round(  v.endCoord.y,v_dec_places) as endY
                                                                       FROM TABLE(CENTROID.Vectorize(P_Geometry           => p_geometry,
                                                                                                     p_ordinate_dimension => 'Y',
                                                                                                     p_filter_ordinate    => v_Seed_Value)) v
                                                                 ) r
                                                        ) t
                                                  ORDER BY t.x
                                               ) s
                                        /*WHERE s.touchCross <> 99*/
                                        GROUP BY s.element_id, s.subelement_id, s.x, s.y
                                        ORDER BY s.x
                                       ) u
                               ) w
                       ) z
                 WHERE z.inout = 'INSIDE'
                ORDER BY z.xdiff DESC
               ) f
         WHERE ROWNUM < 2;
      End If;
      EXCEPTION
        WHEN NO_DATA_FOUND Then
          -- No Data Found means v_centroid will be null so try again
          v_centroid := NULL;
      END;
      IF ( v_centroid is null
           OR
           sdo_geom.relate(v_centroid,'INSIDE',p_geometry,0.005)='FALSE' ) Then
          -- Get a new v_seed_value from v_MBR
          v_seed_value:= case when v_method < 10
                              then sys.dbms_random.value(v_mbr.sdo_ordinates(1),v_mbr.sdo_ordinates(1+p_geometry.Get_Dims()))
                              else sys.dbms_random.value(v_mbr.sdo_ordinates(2),v_mbr.sdo_ordinates(2+p_geometry.Get_Dims()))
                          end;
          v_loop := v_loop - 1;
       else
          v_not_inside := false;
       End If;
    END LOOP;
    IF ( v_centroid is null ) Then
      RAISE CENTROID_FAIL;
    End If;
    RETURN v_centroid;
    EXCEPTION
      WHEN NO_DATA_FOUND Then
           raise_application_error(c_i_fail, c_s_fail,TRUE);
           RETURN NULL;
      WHEN NULL_GEOMETRY Then
           raise_application_error(c_i_null_geometry, c_s_null_geometry,TRUE);
           RETURN NULL;
      WHEN STARTING_POSITION THEN
           raise_application_error(c_i_method,c_s_method,TRUE);
           RETURN NULL;
      WHEN NO_X_SEED_VALUE THEN
           raise_application_error(c_i_x_seed,c_s_x_seed,TRUE);
           RETURN NULL;
      WHEN NO_Y_SEED_VALUE THEN
           raise_application_error(c_i_y_seed,c_s_y_seed,TRUE);
           RETURN NULL;
      WHEN SEED_MBR THEN
          raise_application_error(-20001,'Seed value not between provided geometry''s MBR.',TRUE);
          RETURN NULL;
      WHEN CENTROID_FAIL THEN
          raise_application_error(c_i_fail, c_s_fail,TRUE);
          RETURN NULL;
  End centroid_a;

  FUNCTION centroid_l(p_geometry          in mdsys.sdo_geometry,
                      p_position_as_ratio in number := 0.5,
                      p_round_x           IN pls_integer := 3,
                      p_round_y           IN pls_integer := 3,
                      p_round_z           IN pls_integer := 2)
    RETURN MDSYS.SDO_GEOMETRY
  As
    v_centroid     MDSYS.SDO_GEOMETRY;
    v_tolerance    number := 1/power(10,p_round_x);
    NULL_GEOMETRY  EXCEPTION;
  Begin
    If ( p_geometry is NULL ) Then
       raise NULL_GEOMETRY;
    End If;
    SELECT mdsys.sdo_geometry(CASE WHEN i3.z2 IS NOT NULL
                                   THEN 3001
                                   ELSE 2001
                               END,
                              i3.srid,
                              mdsys.sdo_point_type(
                                    round(i3.x2-((i3.x2-i3.x1)*i3.vectorPositionRatio),p_round_x), /* what about geographic data? */
                                    round(i3.y2-((i3.y2-i3.y1)*i3.vectorPositionRatio),p_round_y),
                                    CASE WHEN i3.z2 IS NOT NULL
                                         THEN round(i3.z2-((i3.z2-i3.z1)*vectorPositionRatio),p_round_z)
                                         ELSE NULL
                                     END),
                              null,
                              null) as centroid
      INTO v_centroid
      FROM (SELECT /* select vector/segment "containing" centroid Or mid-point of linestring */
                   i2.SRID,
                   i2.X1,i2.Y1,i2.Z1,
                   i2.X2,i2.Y2,i2.Z2,
                   (i2.cumLength-i2.pointDistance)/i2.vectorLength as vectorPositionRatio,
                   CASE WHEN pointDistance between
                             case when lag(cumLength,1) over (order by rid) is null
                                  then 0
                                  else lag(cumLength,1) over (order by rid)
                              end
                              and vectorLength +
                              case when lag(cumLength,1) over (order by rid) is null
                                  then 0
                                  else lag(cumLength,1) over (order by rid)
                              end
                        THEN 1
                        ELSE 0
                    END as RightSegment
              FROM (SELECT i1.RID,
                           i1.SRID,
                           i1.X1,i1.Y1,i1.Z1,
                           i1.X2,i1.Y2,i1.Z2,
                           i1.vectorLength,
                           i1.pointDistance,
                           /* generate cumulative length */
                          SUM(vectorLength) OVER (ORDER BY rid ROWS UNBOUNDED PRECEDING) as cumLength
                      FROM (SELECT rownum as rid,
                                   a.srid,
                                   a.pointDistance,
                                   v.startCoord.x as X1,
                                   v.startCoord.y as Y1,
                                   v.startCoord.z as Z1,
                                     v.endCoord.x as X2,
                                     v.endCoord.y as Y2,
                                     v.endCoord.z as Z2,
                                   mdsys.sdo_geom.sdo_distance(
                                         mdsys.sdo_geometry(2001,a.srid,mdsys.sdo_point_type(v.startCoord.X,v.startCoord.y,v.startCoord.z),NULL,NULL),
                                         mdsys.sdo_geometry(2001,a.srid,mdsys.sdo_point_type(v.endCoord.X,v.endCoord.y,v.endCoord.z),NULL,NULL),
                                         v_tolerance,
                                         CASE when a.srid IS NULL THEN NULL ELSE 'unit=m' END
                                   ) as vectorLength
                              FROM (SELECT p_geometry.sdo_srid as srid,
                                           CASE WHEN g_db_version < 11
                                                THEN &&defaultSchema..CENTROID.sdo_length(p_geometry,v_tolerance,CASE WHEN p_geometry.sdo_srid IS NULL THEN NULL ELSE 'METER' END)
                                                ELSE mdsys.sdo_geom.sdo_length(p_geometry,v_tolerance,CASE WHEN p_geometry.sdo_srid IS NULL THEN NULL ELSE 'unit=m' END)
                                            END * p_position_as_ratio as pointDistance
                                      FROM DUAL) a,
                                   TABLE(&&defaultSchema..CENTROID.Vectorize(p_geometry)) v
                           ) i1
                   ORDER BY rid
                 ) i2
                )  i3
          WHERE i3.rightSegment = 1
            AND rownum < 2;
    RETURN v_centroid;
    EXCEPTION
      WHEN NULL_GEOMETRY Then
           raise_application_error(c_i_null_geometry, c_s_null_geometry,TRUE);
           RETURN NULL;
       WHEN NO_DATA_FOUND THEN
           raise_application_error(c_i_linecentroid, c_s_linecentroid,TRUE);
           RETURN NULL;
       WHEN OTHERS THEN
           raise_application_error(-20001,DBMS_UTILITY.format_error_backtrace,TRUE);
           RETURN NULL;
  End centroid_l;

  Function sdo_Centroid(
    p_geometry     IN MDSYS.SDO_GEOMETRY,
    p_start        IN pls_integer := 1,
    p_largest      IN pls_integer := 1,
    p_round_x      IN pls_integer := 3,
    p_round_y      IN pls_integer := 3,
    p_round_z      IN pls_integer := 2)
    RETURN MDSYS.SDO_GEOMETRY
  IS
    v_gtype       number;
    v_geometry    MDSYS.SDO_GEOMETRY;
    v_tolerance   number     := 1/power(10,NVL(p_round_x,0.005));
    NOT_SUPPORTED EXCEPTION;
    NULL_GEOMETRY EXCEPTION;
  Begin
    If ( p_geometry is NULL ) Then
       raise NULL_GEOMETRY;
    End If;
    v_gtype := MOD(p_geometry.Sdo_GType,10);
    If ( v_gtype not in (1,2,3,5,6,7) ) Then
       raise NOT_SUPPORTED;
    End If;

    -- DEBUG dbms_output.put_line(v_gtype);
    -- Handle MultiLine and MultiPolygon Geometries
    IF ( v_gtype IN (6,7) ) Then
      -- Get smallest/largest part of multi-part geometry
     SELECT geometry
       INTO v_geometry
       FROM (SELECT a.geometry
               FROM TABLE(CAST(MULTISET(
                          SELECT &&defaultSchema..T_Geometry(mdsys.sdo_util.Extract(p_geometry,v.column_value,0)) as geometry
                            FROM TABLE(&&defaultSchema..CENTROID.generate_series(
                                          1,
                                          (SELECT COUNT(*)
                                             FROM (SELECT sum(case when mod(rownum,3) = 1 then sei.column_value else null end) as offset,
                                                          sum(case when mod(rownum,3) = 2 then sei.column_value else null end) as etype,
                                                          sum(case when mod(rownum,3) = 0 then sei.column_value else null end) as interpretation
                                                     FROM TABLE(p_geometry.sdo_elem_info) sei
                                                    GROUP BY trunc((rownum - 1) / 3,0)
                                                    ORDER BY 1) i
                                            WHERE i.etype in (1003,1005,2)),
                                          1)
                                      ) v
                              ) AS &&defaultSchema..T_GeometrySet)
                    ) a
              ORDER BY 99999999999999999 +
                       case when p_largest = 1 then -1 else 1 end *
                       CASE WHEN v_gtype = 6 /* linestring */
                            THEN CASE WHEN g_db_version < 11
                                      THEN &&defaultSchema..CENTROID.sdo_length(a.geometry,v_tolerance)
                                      ELSE mdsys.sdo_geom.sdo_length(a.geometry,v_tolerance)
                                  END/* g_spatial */
                            ELSE /* v_gtype = 7 POLYGON */
                                 CASE WHEN g_db_version < 11 
                                      THEN CASE WHEN p_start = 1
                                                THEN &&defaultSchema..CENTROID.sdo_area(a.geometry,v_tolerance)
                                                ELSE &&defaultSchema..CENTROID.sdo_area(&&defaultSchema..CENTROID.sdo_mbr(a.geometry),v_tolerance)
                                            END /* p_area */
                                      ELSE CASE WHEN p_start = 1
                                                THEN mdsys.sdo_geom.sdo_area(a.geometry,v_tolerance)
                                                ELSE mdsys.sdo_geom.sdo_area(&&defaultSchema..CENTROID.sdo_mbr(a.geometry),v_tolerance)
                                            END /* p_area */
                                  END /* g_db_version */
                        END /* v_gtype = 6 */
            )
      WHERE rownum < 2;
    ELSE
      v_geometry := p_geometry;
    END IF;

    v_geometry := CASE WHEN v_gtype IN (1,5)
                       THEN &&defaultSchema..CENTROID.centroid_p(v_geometry,p_round_x,p_round_y,p_round_z)
                       WHEN v_gtype in (2,6)
                       THEN &&defaultSchema..CENTROID.centroid_l(v_geometry,0.5,p_round_x,p_round_y,p_round_z)
                       WHEN v_gtype in (3,7)
                       THEN &&defaultSchema..CENTROID.Centroid_A(P_Geometry  => v_Geometry,
                                                        P_method    => p_start,
                                                        P_Seed_Value=> Null,
                                                        P_Dec_Places=> NVL(p_round_x,3),
                                                        P_Tolerance => v_tolerance,
                                                        p_loops     => 10)
                       ELSE NULL
                   END;

    RETURN v_geometry;

    EXCEPTION
      WHEN NULL_GEOMETRY Then
       raise_application_error(c_i_null_geometry, c_s_null_geometry,TRUE);
        RETURN NULL;
      WHEN NOT_SUPPORTED Then
       raise_application_error(c_i_centroid, c_s_centroid,TRUE);
        RETURN NULL;
      WHEN OTHERS THEN
        raise_application_error(-20001,DBMS_UTILITY.format_error_backtrace,TRUE);
        RETURN NULL;
  END sdo_Centroid;

  -- @function : Sdo_Centroid
  -- @description : Public wrapper classes for private Do_Centroid
  --
  Function sdo_centroid(
    p_geometry     IN MDSYS.SDO_GEOMETRY,
    p_start        IN pls_integer := 1,
    p_dimarray     IN MDSYS.SDO_DIM_ARRAY)
    RETURN MDSYS.SDO_GEOMETRY
  IS
     v_x_round_factor number;
     v_y_round_factor number;
     v_z_round_factor number;
  Begin
    If ( p_dimarray is null ) Then
     raise_application_error(c_i_null_diminfo,c_s_null_diminfo,true);
    End If;
    -- Compute rounding factors
    v_x_round_factor := round(log(10,(1/p_dimarray(1).sdo_tolerance)/2));
    v_y_round_factor := round(log(10,(1/p_dimarray(2).sdo_tolerance)/2));
    IF ( p_dimarray.count > 2 ) Then
      v_z_round_factor := floor(log(10,(1/p_dimarray(3).sdo_tolerance)/2));
    END IF;
    RETURN &&defaultSchema..CENTROID.sdo_Centroid(p_geometry,
                                         p_start,1,
                                         v_x_round_factor,
                                         v_y_round_factor,
                                         case when p_dimarray.COUNT=3 then v_z_round_factor else null end);
  END Sdo_Centroid;

  Function Sdo_Centroid(
    p_geometry     IN MDSYS.SDO_GEOMETRY,
    p_start        IN pls_integer := 1,
    p_tolerance    IN NUMBER := 0.005)
    RETURN MDSYS.SDO_GEOMETRY
  IS
     v_x_round_factor number;
  Begin
    If ( p_tolerance is null ) Then
     raise_application_error(c_i_null_tolerance,c_s_null_tolerance,true);
    End If;
    -- Compute rounding factors
    v_x_round_factor := round(log(10,(1/p_tolerance)/2));
    RETURN &&defaultSchema..CENTROID.sdo_Centroid(p_geometry,
                        p_start,
                        1,
                        v_x_round_factor,
                        v_x_round_factor,
                        case when p_geometry.get_dims() > 2 then v_x_round_factor else null end);
  END Sdo_Centroid;

  /* MULTI-CENTROID */

  Function SDO_Multi_Centroid(
    p_geometry  IN MDSYS.SDO_Geometry,
    p_start     IN pls_integer := 1,
    p_round_x   IN pls_integer := 3,
    p_round_y   IN pls_integer := 3,
    p_round_z   IN pls_integer := 2)
   return MDSYS.SDO_Geometry
  Is
    v_elements      number;
    v_dims          number;
    v_extract_shape MDSYS.SDO_Geometry;
    v_geometry      MDSYS.SDO_Geometry;
    v_ordinates     MDSYS.SDO_Ordinate_Array;
    CURSOR c_geoms (p_geometry in MDSYS.SDO_GEOMETRY) Is
    SELECT mdsys.sdo_util.Extract(p_geometry,v.column_value,0) as geometry
      FROM TABLE(generate_series(1,
                                 (SELECT count(*)
                                    FROM TABLE(p_geometry.sdo_elem_info) e
                                   WHERE e.column_value IN (1003,1005,2)),
                                 1)) v;
  Begin
    IF ( p_geometry.sdo_gtype NOT IN (2006,2007,3006,3007) ) Then
      raise_application_error(c_i_multi, c_s_multi,TRUE);
    END IF;
    v_ordinates := mdsys.sdo_ordinate_array();

    v_dims := TRUNC(p_geometry.sdo_gtype/1000,0) +
              CASE WHEN MOD(trunc(p_geometry.sdo_gtype/100),10) = 0
                   THEN 0
                   ELSE 1
               END;

    FOR geoms IN c_geoms(p_geometry) LOOP
      v_geometry := sdo_Centroid(geoms.geometry,
                                 p_start,
                                 1,
                                 p_round_x,
                                 p_round_y,
                                 p_round_z);
      v_ordinates.EXTEND(v_dims);
      v_ordinates(v_ordinates.LAST-(v_dims-1)) := v_geometry.sdo_point.x;
      v_ordinates(v_ordinates.LAST-(v_dims-2)) := v_geometry.sdo_point.y;
      IF v_geometry.sdo_point.z IS NOT NULL THEN
        v_ordinates(v_ordinates.LAST) := v_geometry.sdo_point.z;
      END IF;
    END LOOP;
    RETURN( mdsys.sdo_geometry(2005,
                               v_geometry.sdo_srid,
                               NULL,
                               MdSys.Sdo_Elem_Info_Array(1,1,v_ordinates.COUNT / 2),
                               v_Ordinates) );
  END Sdo_Multi_Centroid;

  Function Sdo_Multi_Centroid(
    p_geometry   IN MDSYS.SDO_GEOMETRY,
    p_start      IN pls_integer := 1,
    p_dimarray   IN MDSYS.SDO_DIM_ARRAY)
    RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC
  IS
     v_x_round_factor number;
     v_y_round_factor number;
     v_z_round_factor number;
  Begin
    If ( p_dimarray is null ) Then
     raise_application_error(c_i_null_diminfo,c_s_null_diminfo,true);
    End If;
    -- Compute rounding factors
    v_x_round_factor := round(log(10,(1/NVL(p_dimarray(1).sdo_tolerance,0.005))/2));
    v_y_round_factor := round(log(10,(1/NVL(p_dimarray(2).sdo_tolerance,0.005))/2));
    IF ( p_dimarray.count > 2 ) Then
      v_z_round_factor := floor(log(10,(1/NVL(p_dimarray(3).sdo_tolerance,0.005))/2));
    END IF;
    RETURN &&defaultSchema..CENTROID.sdo_Multi_Centroid(p_geometry,
                              p_start,
                              v_x_round_factor,
                              v_y_round_factor,
                              case when p_dimarray.COUNT=3 then v_z_round_factor else null end);
  END Sdo_Multi_Centroid;

  Function Sdo_Multi_Centroid(
    p_geometry  IN MDSYS.SDO_GEOMETRY,
    p_start     IN pls_integer := 1,
    p_tolerance IN number)
    RETURN MDSYS.SDO_GEOMETRY
  IS
    v_x_round_factor number := round(log(10,(1/NVL(p_tolerance,0.005))/2));
  Begin
    If ( p_tolerance is null ) Then
     raise_application_error(c_i_null_tolerance,c_s_null_tolerance,true);
    End If;
    RETURN &&defaultSchema..CENTROID.sdo_Multi_Centroid(p_geometry,
                              p_start,
                              v_x_round_factor,
                              v_x_round_factor,
                              case when p_geometry.get_dims() > 2 then v_x_round_factor else null end);
  END Sdo_Multi_Centroid;

BEGIN
  -- Query to determine if Locator or Spatial
  SELECT count(*)
    INTO g_spatial
    FROM all_objects
   WHERE owner = 'MDSYS'
     AND object_type = 'TYPE'
     AND object_name = 'SDO_GEORASTER';
 -- Set global g_db_version so can decide if can use functions in sdo_geom.
 setOraVersion();
END Centroid;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'CENTROID';
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

grant execute on CENTROID to public;

quit;
