DEFINE defaultSchema='&1'

CREATE OR REPLACE PACKAGE LINEAR
AUTHID CURRENT_USER
AS

   TYPE T_Integers   IS TABLE OF INTEGER;

   TYPE T_Vectors    IS TABLE OF &&defaultSchema..T_Vector;

   TYPE T_Geometries IS TABLE OF &&defaultSchema..T_Geometry;

   /* For Function GetNumRings() */
   c_rings_all        Constant Pls_Integer   := 0;
   c_rings_outer      Constant Pls_Integer   := 1;
   c_rings_inner      Constant Pls_Integer   := 2;

  /** =========================================== Linear Functions
  **/
  
  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Split
  * @precis     : A procedure that splits a line geometry at a known point
  * @version    : 1.0
  * @description: This procedure will split a linestring or multi-linestring sdo_geometry object
  *               at a supplied (known) point. Normally the point should lie on the linestring at
  *               a vertex or between two vertices but the algorithm used will split a line even if
  *               the point does not lie on the line. Where the point does not lie on the linestring
  *               the algorithm approximates the nearest point on the linestring to the supplied point
  *               and splits it there: the algorithm is ratio based and will not necessarily be accurate
  *               for geodetic data.
  *               The function can be used to return only the split point if p_snap > 0.
  * @usage      : procedure ST_Split( p_geometry  in mdsys.sdo_geometry,
  *                                p_point     in mdsys.sdo_geometry,
  *                                p_tolerance in number,
  *                                p_out_line1 out mdsys.sdo_geometry,
  *                                p_out_line2 out mdsys.sdo_geometry )
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A linestring(2002) or multi-linestring (2006)
  * @                           sdo_geometry object describing the line to be split.
  * @param      : p_point     : MDSYS.SDO_GEOMETRY : A point(2001) sdo_geometry object describing the
  * @                           point for splitting the linestring.
  * @param      : p_tolerance : NUMBER : Tolerance value used in mdsys.sdo_geom.sdo_distance function.
  * @return     : p_out_geom1 : MDSYS.SDO_GEOMETRY : First part of split linestring
  * @return     : p_out_geom2 : MDSYS.SDO_GEOMETRY : Second part of split linestring
  * @param      : p_snap      : PLS_INTEGER : Value 0 means line is split and two parts are returned.
  * @                           Positive value means split point is returned in p_out_geom1 rather than two halves of line
  * @param      : p_unit      : VarChar2 : Unit of measure for distance calculations when defining snap point
  * @param      : p_exception : PLS_INTEGER : If set to 1 then an exception will be thrown if any error is discovered,
  * @                           otherwise NULL values are returned. Useful when procesing large SQL statements.
  * @history    : Simon Greener - Jan 2008 - Original coding.
  * @history    : Simon Greener - Dec 2009 - Fixed SRID handling bug for Geodetic data.
  * @history    : Simon Greener - Jun 2010 - Added p_snap and p_exception handling
  * @copyright  : Simon Greener, 2008, 2009, 2010, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Procedure ST_Split( p_geometry  in mdsys.sdo_geometry,
                      p_point     in mdsys.sdo_geometry,
                      p_tolerance in number default 0.005,
                      p_out_geom1 out nocopy mdsys.sdo_geometry,
                      p_out_geom2 out nocopy mdsys.sdo_geometry,
                      p_snap      in pls_integer default 0,
                      p_unit      in varchar2 default null,
                      p_exception in pls_integer default 0);

  /**
  * Repackaging of the Split procedure
  * via overloaded functions
  */
  Function ST_Split( p_geometry  in mdsys.sdo_geometry,
                     p_point     in mdsys.sdo_geometry,
                     p_tolerance in number default 0.005,
                     p_unit      in varchar2 default null,
                     p_exception in pls_integer default 0)
    Return &&defaultSchema..LINEAR.t_Geometries pipelined;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Split_Geom_Segment
  * @precis     : A procedure that splits a line geometry into possibly two line geometries at a known point
  * @version    : 1.0
  * @description: This procedure will split a linestring or multi-linestring sdo_geometry object
  *               at a supplied (known) point. Normally the point should lie on the linestring at
  *               a vertex or between two vertices but the algorithm used will split a line even if
  *               the point does not lie on the line. Where the point does not lie on the linestring
  *               the algorithm approximates the nearest point on the linestring to the supplied point
  *               and splits it there: the algorithm is ratio based and will not necessarily be accurate
  *               for geodetic data.
  * @usage      : procedure ST_Split(p_geometry      in  mdsys.sdo_geometry,
  *                                  p_split_measure in  mdsys.sdo_geometry,
  *                                  p_segment_1     out mdsys.sdo_geometry,
  *                                  p_segment_2     out mdsys.sdo_geometry )
  * @param      : p_geometry      : MDSYS.SDO_GEOMETRY : A linestring(2002) or multi-linestring (2006)
  * @                               sdo_geometry object describing the line to be split.
  * @param      : p_split_measure : measure between start and end of linestring at which the segment should be split.
  * @return     : p_segment_1 : MDSYS.SDO_GEOMETRY : First part of split linestring
  * @return     : p_segment_2 : MDSYS.SDO_GEOMETRY : Second part of split linestring
  * @history    : Simon Greener - Jan 2012 - Implemented wrapper over ST_Split
  * @copyright  : Simon Greener, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Procedure ST_Split_Geom_Segment( p_geom_segment  IN SDO_GEOMETRY,
                                   p_split_measure IN NUMBER,
                                   p_segment_1     OUT NOCOPY SDO_GEOMETRY,
                                   p_segment_2     OUT NOCOPY SDO_GEOMETRY);

  Function ST_Split_Geom_Segment( p_geom_segment  IN SDO_GEOMETRY,
                                  p_split_measure IN NUMBER)
    Return &&defaultSchema..LINEAR.t_Geometries pipelined;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Clip
  * @precis     : A procedure that clips out a segment of a line geometry between two known points
  * @version    : 1.0
  * @description: This procedure will split a linestring or multi-linestring sdo_geometry object
  *               between two supplied (known) points. Normally the points should lie on the linestring at
  *               a vertex or between two vertices but the algorithm used will clip a line even if
  *               the points do not lie exactly on the line. Where a point does not lie on the linestring
  *               the algorithm approximates the nearest point on the linestring to the supplied point
  *               and splits it there: the algorithm is ratio based and will not be accurate for geodetic data.
  * @usage      : procedure ST_Clip( p_geometry  in mdsys.sdo_geometry,
  *                               p_point1    in mdsys.sdo_geometry,
  *                               p_point2    in mdsys.sdo_geometry,
  *                               p_tolerance in number default 0.005,
  *                               p_exception in pls_integer default 0)
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A linestring(2002) or multi-linestring (2006) sdo_geometry
  * @                           object describing the line to be split.
  * @param      : p_point1    : MDSYS.SDO_GEOMETRY : A point(2001) sdo_geometry object describing the first split point
  * @param      : p_point2    : MDSYS.SDO_GEOMETRY : A point(2001) sdo_geometry object describing the seconds split point.
  * @param      : p_tolerance : NUMBER : Tolerance value used in mdsys.sdo_geom.sdo_distance function.
  * @param      : p_unit      : VarChar2 : Unit of measure for distance calculations when defining snap point
  * @param      : p_exception : PLS_INTEGER : If set to 1 then an exception will be thrown if any error is discovered,
  * @                           otherwise NULL values are returned. Useful when procesing large SQL statements.
  * @return     : line_segment: MDSYS.SDO_GEOMETRY : First part of split linestring
  * @history    : Simon Greener - Jan 2011 - Original coding.
  * @copyright  : Simon Greener, 2011, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Clip(p_geometry  in mdsys.sdo_geometry,
                   p_point1    in mdsys.sdo_geometry,
                   p_point2    in mdsys.sdo_geometry,
                   p_tolerance in number      default 0.005,
                   p_unit      in varchar2    default null,
                   p_exception in pls_integer default 0)
    Return mdsys.sdo_geometry Deterministic;

  Function ST_Clip( p_geometry    IN mdsys.sdo_geometry,
                    p_start_value IN NUMBER,
                    p_end_value   IN NUMBER,
                    P_Value_Type  In Varchar2    DEFAULT 'L', -- or 'M'
                    p_tolerance   IN NUMBER      DEFAULT 0.005,
                    p_unit        in varchar2    DEFAULT null,
                    p_exception   IN PLS_INTEGER DEFAULT 0 )
    Return mdsys.sdo_geometry Deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Snap
  * @precis     : Snaps a point to Line
  * @version    : 1.0
  * @description: The function snaps a point to the supplied line.
  * @usage      : procedure ST_snap(p_geometry  in mdsys.sdo_geometry,
  *                              p_point     in mdsys.sdo_geometry,
  *                              p_tolerance in number      default 0.005,
  *                              p_exception in pls_integer default 0)
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A linestring(2002) or multi-linestring (2006)
  *                             sdo_geometry object describing the line to be split.
  * @param      : p_point     : MDSYS.SDO_GEOMETRY : A point(2001) sdo_geometry object describing the
  *                             point for splitting the linestring.
  * @param      : p_tolerance : NUMBER : Tolerance value used in mdsys.sdo_geom.sdo_distance function.
  * @param      : p_unit      : VarChar2 : Unit of measure for distance calculations when defining snap point
  * @param      : p_exception : PLS_INTEGER : If set to 1 then an exception will be thrown if any error
  *                             is discovered, otherwise NULL values are returned.
  *                             Useful when procesing large SQL statements.
  * @return     : snapped_point : MDSYS.SDO_GEOMETRY : Snapped point
  * @note       : Uses Split() with p_snap = 1
  * @history    : Simon Greener - Jun 2010
  * @copyright  : Simon Greener, 2010, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Snap( p_geometry  in mdsys.sdo_geometry,
                    p_point     in mdsys.sdo_geometry,
                    p_tolerance in number      default 0.005,
                    p_unit      in varchar2    default null,
                    p_exception in pls_integer default 0)
    Return mdsys.sdo_geometry Deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Locate_Point
  * @precis     : Returns the point (possibly offset) located at a specified measure from the start of a measured linestring.
  * @version    : 1.0
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A linestring(2002) or multi-linestring (2006)
  *                             sdo_geometry object describing the line to be split.
  * @param      : p_distance  : Number : Distance or Measure at which to locate the point.
  * @param      : p_offset    : NUMBER : Distance to measure perpendicularly from the points along geom_segment. 
  *                                      Positive offset values are to the left of p_geometry; 
  *                                      Negative offset values are to the right of p_geometry.
  * @param      : p_tolerance : NUMBER : Tolerance value used in mdsys.sdo_geom.sdo_distance function.
  * @param      : p_distance_type : VARCHAR2 : Interpret p_distance as Measure or a Length  
  * @param      : p_tolerance : NUMBER : Tolerance value used in mdsys.sdo_geom.sdo_distance function.
  * @param      : p_unit      : VarChar2 : Unit of measure for distance calculations when defining snap point
  * @param      : p_exception : PLS_INTEGER : If set to 1 then an exception will be thrown if any error
  *                             is discovered, otherwise NULL values are returned.
  *                             Useful when procesing large SQL statements.
  * @return     : point       : SDO_GEOMETRY : Located (and offset) point at distance or measure.
  * @history    : Simon Greener - Jun 2010
  * @copyright  : Simon Greener, 2010, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Locate_Point(p_geometry      IN mdsys.sdo_geometry,
                           p_distance      IN NUMBER      DEFAULT NULL,
                           p_offset        IN NUMBER      DEFAULT NULL,
                           p_distance_type IN VARCHAR2    DEFAULT 'L', -- or 'M'
                           p_tolerance     IN NUMBER      DEFAULT 0.005,
                           p_unit          IN VARCHAR2    DEFAULT NULL,
                           p_exception     IN PLS_INTEGER DEFAULT 0)
   Return mdsys.sdo_geometry Deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Find_Measure
  * @precis     : Given a point near a measured linestring, this function returns the measure 
  *               nearest to that point.
  * @version    : 1.0
  * @param      : p_geometry  : mdsys.sdo_geometry : A linestring(2002) or multi-linestring (2006)
  * @param      : p_point     : mdsys.sdo_geometry : Point(2001) for which a measure is needed.
  * @param      : p_tolerance : NUMBER      : Tolerance value used in various functions.
  * @param      : p_unit      : VarChar2    : Unit of measure for distance calculations when defining snap point
  * @param      : p_exception : PLS_INTEGER : If set to 1 then an exception will be thrown if any error
  *                             is discovered, otherwise NULL values are returned.
  *                             Useful when procesing large SQL statements.
  * @return     : measure     : NUMBER : Measure on line closest to point.
  * @history    : Simon Greener - Jun 2012
  * @copyright  : Simon Greener, 2010, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Find_Measure(p_geometry  IN mdsys.sdo_geometry,
                           p_point     IN mdsys.sdo_geometry,
                           p_tolerance IN NUMBER      DEFAULT 0.005,
                           p_unit      in varchar2    default null,
                           p_exception IN PLS_INTEGER DEFAULT 0)
    Return number deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Split_Points
  * @precis     : Returns all intersection points that the splitter geometry has with 
  *               the main geometry.
  * @version    : 1.0
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A linestring(2002) or multi-linestring (2006)
  *                             sdo_geometry object describing the line to be split.
  * @param      : p_splitter  :  MDSYS.SDO_GEOMETRY  : A Linestring that will be used to split the main geometry.
  * @param      : p_tolerance : NUMBER : Tolerance value used in mdsys.sdo_geom.sdo_distance function.
  * @param      : p_unit      : VarChar2 : Unit of measure for distance calculations when defining snap point
  * @param      : p_exception : PLS_INTEGER : If set to 1 then an exception will be thrown if any error
  *                             is discovered, otherwise NULL values are returned.
  *                             Useful when procesing large SQL statements.
  * @return     : Set of Points : T_Geometries : All intersection points betwen the main geometry and the splitter.
  * @history    : Simon Greener - Jun 2012
  * @copyright  : Simon Greener, 2010, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Split_Points(p_geometry  in mdsys.sdo_geometry,
                           p_splitter  in mdsys.sdo_geometry,
                           p_tolerance in number      default 0.005,
                           p_unit      In Varchar2    default null,
                           p_exception in pls_integer default 0)
    return &&defaultSchema..LINEAR.t_geometries pipelined;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Split_Line
  * @precis     : Splits main linear geometry with a splitter geometry returning
  *               all the linesegments formed from that splitting.
  * @version    : 1.0
  * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A linestring(2002) or multi-linestring (2006)
  *                             sdo_geometry object describing the line to be split.
  * @param      : p_splitter  :  MDSYS.SDO_GEOMETRY  : A Linestring that will be used to split the main geometry.
  * @param      : p_tolerance : NUMBER : Tolerance value used in mdsys.sdo_geom.sdo_distance function.
  * @param      : p_unit      : VarChar2 : Unit of measure for distance calculations when defining snap point
  * @param      : p_exception : PLS_INTEGER : If set to 1 then an exception will be thrown if any error
  *                             is discovered, otherwise NULL values are returned.
  *                             Useful when procesing large SQL statements.
  * @return     : Set of Linestrings : t_Geometries : All linestring segments formed from the splitting.
  * @history    : Simon Greener - Jun 2012
  * @copyright  : Simon Greener, 2010, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Split_Line(p_geometry  in mdsys.sdo_geometry,
                         p_splitter  in mdsys.sdo_geometry,
                         P_Tolerance In Number      Default 0.005,
                         p_unit      In Number      Default null,
                         p_exception in pls_integer default 0)
    Return &&defaultSchema..LINEAR.t_Geometries pipelined;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Concat_Lines
  * @precis     : A simple aggregator for linestrings where SDO_AGGR_CONCAT_LINES is not licensed.
  * @version    : 1.0
  * @param      : p_lines    : t_Geometries      : A set of linestring(2002) or multi-linestring (2006) to be aggregated.
  * @return     : linestring : mdsys.sdo_geometry : Resultant concatenated geometry.
  * @history    : Simon Greener - Jun 2012
  * @copyright  : Simon Greener, 2010, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Concat_Lines(p_lines IN &&defaultSchema..LINEAR.t_Geometries)
    Return mdsys.sdo_geometry deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Concatenate_Geom_Segments
  * @precis     : A method for concatenating two measured linestrings 
  * @version    : 1.0
  * @param      : p_geom_segment_1 : mdsys.sdo_geometry : A linestring(2002) or multi-linestring (2006)
  * @param      : p_geom_segment_2 : mdsys.sdo_geometry : A linestring(2002) or multi-linestring (2006)
  * @param      : p_tolerance      : NUMBER : Tolerance value used in various functions.
  * @return     : linestring       : mdsys.sdo_geometry : Resultant concatenated geometry.
  * @history    : Simon Greener - Jun 2012
  * @copyright  : Simon Greener, 2010, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Concatenate_Geom_Segments(p_geom_segment_1 IN SDO_GEOMETRY,
                                        p_geom_segment_2 IN SDO_GEOMETRY,
                                        p_tolerance      IN NUMBER DEFAULT 1.0e-8) 
    Return mdsys.sdo_geometry deterministic;
     
  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Is_Measure_Decreasing
  * @precis     : Checks if the measure values along an LRS segment are decreasing.
  * @version    : 1.0
  * @description: Checks whole linestring to make sure all adjacent measures are decreasing in 
  *               numerical order.
  *               Returns 'TRUE' if descreasing, 'FALSE' otherwise.
  * @usage      : Function ST_Is_Measure_Decreasing( p_geometry in mdsys.sdo_geometry)
  *                Returns varchar2;
  * @param      : p_geometry    : MDSYS.SDO_GEOMETRY : A linestring(2002) or multi-linestring (2006) sdo_geometry
  * @                           object describing the line to be split.
  * @return     : is_increasing : varchar2 : Returns 'TRUE' if decreasing, 'FALSE' otherwise.
  * @history    : Simon Greener - Jan 2012 - Original coding.
  * @copyright  : Simon Greener, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Is_Measure_Decreasing(p_geometry IN SDO_GEOMETRY) 
    RETURN VARCHAR2 Deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Is_Measure_Increasing
  * @precis     : Checks if the measure values along an LRS segment are increasing (that is, ascending in numerical value).
  * @version    : 1.0
  * @description: Checks whole linestring to make sure all adjacent measures are increasing. 
  *               Returns 'TRUE' if increasing, 'FALSE' otherwise.
  * @usage      : Function ST_Is_Measure_Increasing( p_geometry in mdsys.sdo_geometry)
  *                Returns varchar2;
  * @param      : p_geometry    : MDSYS.SDO_GEOMETRY : A linestring(2002) or multi-linestring (2006) sdo_geometry
  * @                           object describing the line to be split.
  * @return     : is_increasing : varchar2 : Returns 'TRUE' if increasing, 'FALSE' otherwise.
  * @history    : Simon Greener - Jan 2012 - Original coding.
  * @copyright  : Simon Greener, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Is_Measure_Increasing(p_geometry IN SDO_GEOMETRY) 
    RETURN VARCHAR2 Deterministic;
    
  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Reset_Measure
  * @precis     : Sets all measures of a measured linesting to null values.
  *               Wipes all existing assigned measures.
  * @version    : 1.0
  * @param      : p_geometry : sdo_geometry : measured geometry
  * @return     : sdo_geometry : reset measure 
  * @history    : Simon Greener - Dec 2012 - Original coding.
  * @copyright  : Simon Greener, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Reset_Measure(p_geometry in mdsys.sdo_geometry) 
    Return mdsys.sdo_geometry deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Measure_Range
  * @precis     : Returns the measure range of a measured linestring.
  *               Range is the difference between the first and last measure values.
  * @version    : 1.0
  * @param      : p_geometry : sdo_geometry : measured geometry
  * @return     : number : measured range
  * @history    : Simon Greener - Dec 2012 - Original coding.
  * @copyright  : Simon Greener, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Measure_Range(p_geometry IN SDO_GEOMETRY)
     Return Number deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Start_Measure
  * @precis     : Returns the measure of the first vertex in a measured linestring.
  * @version    : 1.0
  * @param      : p_geometry : sdo_geometry : measured geometry
  * @return     : number : measure value
  * @history    : Simon Greener - Dec 2012 - Original coding.
  * @copyright  : Simon Greener, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Start_Measure(p_geometry IN SDO_GEOMETRY)
     Return Number deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_End_Measure
  * @precis     : Returns the measure of the last vertex in a measured linestring.
  * @version    : 1.0
  * @param      : p_geometry : sdo_geometry : measured geometry
  * @return     : number : measure value
  * @history    : Simon Greener - Dec 2012 - Original coding.
  * @copyright  : Simon Greener, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_End_Measure(p_geometry IN SDO_GEOMETRY)
     Return Number deterministic;
     
  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Measure_To_Percentage
  * @precis     : Returns the percentage (0 to 100) of the measured within the measured range 
  *               of a measured linestring. 
  * @version    : 1.0
  * @param      : p_geometry : sdo_geometry : measured geometry
  * @return     : number     : measure expressed as a percentage of the measure range.
  * @history    : Simon Greener - Dec 2012 - Original coding.
  * @copyright  : Simon Greener, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Measure_To_Percentage(p_geometry IN SDO_GEOMETRY,
                                    p_measure  IN NUMBER)
     Return Number deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Percentage_To_Measure
  * @precis     : Returns the measure associated associated with a position within a measured
  *               linestring expressed as a percentage (0 to 100). 
  * @version    : 1.0
  * @param      : p_geometry : sdo_geometry : measured geometry
  * @return     : number : measure associated with the supplied percentage 
  * @history    : Simon Greener - Dec 2012 - Original coding.
  * @copyright  : Simon Greener, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Percentage_To_Measure(p_geometry   IN SDO_GEOMETRY,
                                    p_percentage IN NUMBER)
     Return Number deterministic;

   /**
   * ST_AddMeasure
   * Return a derived geometry with measure elements linearly interpolated between the start and end points.
   * If the geometry has no measure dimension, one is added. If the geometry has a measure dimension, it is
   * over-written with new values. Only LINESTRINGS and MULTILINESTRINGS are supported.
   *
   * geometry ST_AddMeasure(geometry geom_mline, float measure_start, float measure_end);
   */
  Function ST_AddMeasure(p_geometry      in mdsys.sdo_geometry,
                         p_start_measure in number,
                         p_end_measure   in number,
                         p_tolerance     in number Default 0.005,
                         p_unit          IN VARCHAR2 Default NULL)
     Return Mdsys.Sdo_Geometry Deterministic;

    /** ----------------------------------------------------------------------------------------
    * @function   : ST_Reverse_Measure
    * @precis     : Reverses the measure values of measured linestring
    * @version    : 1.0
    * @description: The function reverses the measure values in supplied sdo_geometry's sdo_ordinate_array.
    * @usage      : select ST_Reverse_Measure(p_geometry) from dual;
    * @param      : p_geometry        : MDSYS.SDO_GEOMETRY : sdo_geometry whose ordinates will be reversed
    * @return     : modified geometry : MDSYS.SDO_GEOMETRY : SDO_Geometry with reversed measure
    * @history    : Simon Greener - Feb 2012 2010
    * @copyright  : Simon Greener, 2010, 2012
    * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
    **/
   Function ST_Reverse_Measure(p_geometry in mdsys.sdo_geometry)
     Return mdsys.sdo_geometry Deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Scale_Geom_Segment
  * @precis     : Returns the geometry object resulting from a measure scaling operation on a geometric segment.
  * @version    : 1.0
  * @history    : Simon Greener - Jul 2012 - Original coding.
  * @copyright  : Simon Greener, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Scale_Geom_Segment( p_geometry IN mdsys.sdo_geometry,
                                  p_start_measure IN NUMBER,
                                  p_end_measure   IN NUMBER,
                                  p_shift_measure IN NUMBER DEFAULT 0.0 )
    Return mdsys.sdo_geometry Deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_isMeasured
  * @precis     : A function that tests whether an sdo_geometry contains LRS measures
  * @version    : 1.0
  * @param      : p_gtype : number : sdo_geometry sdo_gtype
  * @return     : pls_integer : 1 is true if geometry has an LRS measure
  * @history    : Simon Greener - Dec 2008 - Original coding.
  * @copyright  : Simon Greener, 2008, 2009, 2010, 2011, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_isMeasured( p_gtype in number )
    return pls_integer deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_getMeasureDimension
  * @precis     : A function returns the dimension holding the LRS measure
  * @version    : 1.0
  * @param      : p_gtype : number : sdo_geometry sdo_gtype
  * @return     : pls_integer : 0 if geometry has no measure otherwise the dimension holding the 
  *               measure (eg in 3302, the measure is 3)
  * @history    : Simon Greener - Jul 2102 - Original coding.
  * @copyright  : Simon Greener, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_getMeasureDimension( p_gtype in number )
   return pls_integer deterministic;
    
  /** ---------------------- Point Extractors ------------------------------ **/

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Set_Pt_Measure
  * @precis     : Sets measure of vertex nearest to the supplied point
  * @version    : 1.0
  * @param      : p_geometry    : sdo_geometry : The actual measured geometry 
  * @param      : p_point       : sdo_geometry : A point geometry coded in sdo_point_type
  * @param      : p_unit        : VarChar2 : Unit of measure for distance calculations when defining snap point
  * @return     : measure linestring : sdo_geometry
  * @history    : Simon Greener - Jul 2012 - Original coding.
  * @copyright  : Simon Greener, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Set_Pt_Measure(p_geometry  IN SDO_GEOMETRY,
                             p_point     IN SDO_GEOMETRY,
                             p_measure   IN Number,
                             p_tolerance IN number default 0.05,
                             p_unit      in varchar2 default null)
    Return sdo_geometry deterministic;
     
  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Get_Point
  * @precis     : Returns the vertex associated with the supplied point number
  * @version    : 1.0
  * @param      : p_geometry    : sdo_geometry : The actual geometry 
  * @param      : p_point_array : number       : 1 .. sdo_util.getNumVertices(), with -1 meaning last vertex
  * @return     : point geometry : sdo_geometry
  * @history    : Simon Greener - Jul 2010 - Original coding.
  * @copyright  : Simon Greener, 2010-2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Get_Point(p_geometry     IN MDSYS.SDO_GEOMETRY,
                        p_point_number IN NUMBER DEFAULT 1 )
    Return MDSYS.sdo_geometry deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Start_Point
  * @precis     : Returns the first vertex in the supplied geometry if exists
  * @version    : 1.0
  * @param      : p_geometry : sdo_geometry : The actual geometry 
  * @return     : point geometry : sdo_geometry
  * @history    : Simon Greener - Jul 2010 - Original coding.
  * @copyright  : Simon Greener, 2010-2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Start_Point( p_geometry IN mdsys.sdo_geometry )
    Return mdsys.sdo_geometry deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_End_Point
  * @precis     : Returns the last vertex in the supplied geometry if exists
  * @version    : 1.0
  * @param      : p_geometry : sdo_geometry : The actual geometry 
  * @return     : point geometry : sdo_geometry
  * @history    : Simon Greener - Jul 2010 - Original coding.
  * @copyright  : Simon Greener, 2010-2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_End_Point ( p_geometry IN mdsys.sdo_geometry )
    Return mdsys.sdo_geometry deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Point_Text
  * @precis     : Returns the vertex associated with the supplied point number as formatted text
  * @version    : 1.0
  * @param      : p_geometry    : sdo_geometry : The actual geometry 
  * @param      : p_point_array : number       : 1 .. sdo_util.getNumVertices(), with -1 meaning last vertex
  * @return     : formatted_string : varchar2
  * @history    : Simon Greener - Jul 2010 - Original coding.
  * @copyright  : Simon Greener, 2010-2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Point_Text( p_geometry     IN mdsys.sdo_geometry,
                          p_point_number IN number default 1 )
    Return varchar2 deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Start_point_text
  * @precis     : Returns the first vertex in the supplied geometry as formatted text
  * @version    : 1.0
  * @param      : p_geometry    : sdo_geometry : The actual geometry 
  * @param      : p_point_array : number       : 1 .. sdo_util.getNumVertices(), with -1 meaning last vertex
  * @return     : formatted_string : varchar2
  * @history    : Simon Greener - Jul 2010 - Original coding.
  * @copyright  : Simon Greener, 2010-2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_Start_point_text( p_geometry IN mdsys.sdo_geometry )
    Return varchar2 deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_End_point_text
  * @precis     : Returns the last vertex in the supplied geometry as formatted text
  * @version    : 1.0
  * @param      : p_geometry    : sdo_geometry : The actual geometry 
  * @param      : p_point_array : number       : 1 .. sdo_util.getNumVertices(), with -1 meaning last vertex
  * @return     : formatted_string : varchar2
  * @history    : Simon Greener - Jul 2010 - Original coding.
  * @copyright  : Simon Greener, 2010-2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_End_point_text( p_geometry IN mdsys.sdo_geometry )
    Return varchar2 deterministic;

  /** --------------------------------------------------------------------------------- **/
  /** ------------------- PostGIS/JASPA Linear Referencing wrappers ------------------- **/
  /** --------------------------------------------------------------------------------- **/

  /**
  * ST_Line_Locate_Point
  * double ST_Line_Locate_Point(bytea Line, bytea Point)
  * Computes the fraction of a Line from the closest point on the line to the given point.
  * The point does not necessarily have to lie precisely on the line.
  * Both geometries must have the same SRID and dimensions.
  * Wrapper (based on PostGIS) over
  *     Function Find_Measure(p_geometry  IN mdsys.sdo_geometry,
  *                           p_point     IN mdsys.sdo_geometry,
  *                           p_tolerance IN NUMBER      DEFAULT 0.005,
  *                           p_exception IN PLS_INTEGER DEFAULT 0)
  *       Return Number Deterministic;
  **/
  Function ST_Line_Locate_Point(p_geometry  In Mdsys.Sdo_Geometry,
                                P_Point     In Mdsys.Sdo_Geometry,
                                P_Tolerance In Number      Default 0.005,
                                p_unit      in varchar2    default null,
                                p_exception In Pls_Integer Default 0)
    Return Number Deterministic;

  /**
  * ST_Locate_ALong_Measure
  * Extracts Points from a Geometry object that have the specified m coordinate value.
  * Wrapper (based on PostGIS) over
    Function ST_Locate_Along_Measure(p_geometry  IN mdsys.sdo_geometry,
                                     p_m         IN NUMBER,
                                     p_tolerance IN NUMBER      DEFAULT 0.005,
                                     p_exception IN PLS_INTEGER DEFAULT 0)
      Return mdsys.sdo_geometry Deterministic;
  */
  Function ST_Locate_Along_Measure(P_Geometry  In Mdsys.Sdo_Geometry,
                                   p_m         In Number,
                                   P_Tolerance In Number      Default 0.005,
                                   p_exception In Pls_Integer Default 0 )
    Return Mdsys.Sdo_Geometry Deterministic;

  /**
  * ST_Locate_Between_Measures
  * geometry ST_Locate_Between_Measures(bytea Geometry, double start_M, double end_M)
  * Returns a derived geometry whose measures are in the specified M range.
  * Wrapper (based on PostGIS) over
  * Function Clip( p_geometry    IN mdsys.sdo_geometry,
  *                p_start_value IN NUMBER,
  *                p_end_value   IN NUMBER,
  *                p_tolerance   IN NUMBER      DEFAULT 0.005,
  *                p_exception   IN PLS_INTEGER DEFAULT 0 )
  *    Return Mdsys.Sdo_Geometry Deterministic;
  **/
  Function ST_Locate_Between_Measures(p_Geometry  In Mdsys.Sdo_Geometry,
                                      P_Start_M   In Number,
                                      p_End_M     In number,
                                      P_Tolerance In Number      Default 0.005,
                                      P_Exception In Pls_Integer Default 0 )
    Return Mdsys.Sdo_Geometry Deterministic;

  /**
  * ST_Line_SubString
  * Line ST_Line_Substring(Bytea Geometry, Double Startfraction, Double Endfraction)
  * Returns A Linestring Being A Portion Of The Input One. It Will Start And End At
  * The Given Fractions (Eg 0.2 / 20% To 0.8 / 80%) Of The Total 2D Length.
  **/
  Function ST_Line_Substring(P_Geometry      In Mdsys.Sdo_Geometry,
                             P_Startfraction In Number,
                             P_EndFraction   In Number,
                             P_Tolerance     In Number      Default 0.005,
                             p_unit          in varchar2    default null,
                             P_Exception     In Pls_Integer Default 0 )
  Return Mdsys.Sdo_Geometry Deterministic;

  /**
  * ST_Locate_Along_Elevation
  * geometry ST_Locate_Along_Elevation(bytea Geometry, double Z)
  * Extracts Points from a Geometry object that have the specified z coordinate value.
  * Wrapper over: Locate_Point() with p_distance_type = Z
  */
  Function ST_Locate_Along_Elevation(P_Geometry  In Mdsys.Sdo_Geometry,
                                     P_Z         In Number,
                                     P_Tolerance In Number      Default 0.005,
                                     p_exception In Pls_Integer Default 0)
    Return Mdsys.Sdo_Geometry Deterministic;

  /**
  * ST_Locate_Between_Elevations
  * Geometry ST_Locate_Between_Elevations(Bytea Geometry, Double Start_Z, Double End_Z)
  * Returns A Derived Geometry Whose Elevation Are In The Specified Z Range.
  */
  Function ST_Locate_Between_Elevations(P_Geometry    In Mdsys.Sdo_Geometry,
                                        p_start_value IN NUMBER,
                                        P_End_Value   In Number,
                                        p_tolerance   IN NUMBER      DEFAULT 0.005,
                                        p_exception   IN PLS_INTEGER DEFAULT 0 )
    Return Mdsys.Sdo_Geometry Deterministic;

  /**
  * point ST_Line_Interpolate_Point(bytea Geometry, double fraction);
  * Returns the Coordinates for the point on the line at the given fraction.
  * This fraction (ie percentage 0.9 = 80%), is applied to the line's total length.
  * Does not support measure. To do so use 
  * Wrapper (based on PostGIS) over:
    Function Locate_Point(p_geometry      IN mdsys.sdo_geometry,
                          v_distance      IN NUMBER      DEFAULT NULL,
                          v_distance_type IN VARCHAR2    DEFAULT 'L', -- or 'M'
                          p_tolerance     IN NUMBER      DEFAULT 0.005,
                          p_exception     IN PLS_INTEGER DEFAULT 0)
  **/  
  Function ST_Line_Interpolate_Point(P_Geometry  In Mdsys.Sdo_Geometry,
                                     p_Fraction  In Number,
                                     P_Tolerance In Number      Default 0.005,
                                     p_unit      in varchar2    default null,
                                     p_exception In Pls_Integer Default 0)
    Return Mdsys.Sdo_Geometry Deterministic;

   /**
   * ST_Project_Point
   * geometry ST_Project_Point(bytea Line, bytea Point)
   * Finds the closest point from a Line to a given point.
   * NOTE: ST_Project_Point (Line, Point) is a shortening of
   *       ST_Line_Interpolate_Point(line,ST_Line_Locate_Point(line,point)))
   * Wrapper over:
   * Function Snap( p_geometry  in mdsys.sdo_geometry,
   *                p_point     in mdsys.sdo_geometry,
   *                p_tolerance in number      default 0.005,
   *                p_unit      In varchar2    Default null,,
   *                p_exception in pls_integer default 0)
   *   Return mdsys.sdo_geometry Deterministic;
   **/
   Function ST_Project_Point(P_Line      In Mdsys.Sdo_Geometry,
                             P_Point     In Mdsys.Sdo_Geometry,
                             P_Tolerance In Number      Default 0.005,
                             p_unit      In varchar2    Default null,
                             p_exception In Pls_Integer Default 0)
   Return Mdsys.Sdo_Geometry Deterministic;

  /** --------------------------------------------------------------------------------- **/
  /** ---------------------------- Some SDO_LRS Wrappers ------------------------------ **/
  /** --------------------------------------------------------------------------------- **/

   /**
   * Project_PT
   * Wrapper for SDO_LRS.PROJECT_PT
   * Returns the projection point of a specified point. The projection point is on the geometric segment.
   * Wrapper over:
   * Function ST_Snap( p_geometry  in mdsys.sdo_geometry,
   *                   p_point     in mdsys.sdo_geometry,
   *                   p_tolerance in number      default 0.005,
   *                   p_unit      in varchar2    default null,
   *                   p_exception in pls_integer default 0)
   *   Return mdsys.sdo_geometry Deterministic;
   **/
   Function Project_PT(geom_segment IN SDO_GEOMETRY,
                       point        IN SDO_GEOMETRY,
                       tolerance    IN NUMBER DEFAULT 1.0e-8,
                       unit         IN VARCHAR2 DEFAULT NULL
                       /* NO OFFSET AS IS FUNCTION */ ) 
     Return mdsys.sdo_geometry deterministic;

   /* Wrapper */
   Function Define_Geom_Segment(geom_segment  IN SDO_GEOMETRY,
                                start_measure IN NUMBER,
                                end_measure   IN NUMBER,
                                p_tolerance   IN NUMBER   Default 0.005,
                                p_unit        IN VARCHAR2 default null)
    Return sdo_geometry Deterministic;
     
   /*
   *  @function Convert_To_Lrs_Geom
   *  @precis   Wrapper to look like SDO_LRS.CONVERT_TO_LRS_GEOM
   *  @precis   Converts a 2/3D geometry to measured geometry.
   *  @version  1.1
   *  @usage    v_m_geom := convert_to_lrs_geom(MDSYS.SDO_Geometry(2002,....),0,50)
   *  @history  Simon Greener, Jun 2011 Original Coding.
   *  @history  Simon Greener, Feb 2012 Re-wrote.
   */
   Function Convert_To_Lrs_Geom( p_geometry      IN mdsys.sdo_geometry,
                                 p_start_measure IN NUMBER Default NULL,
                                 p_end_measure   IN NUMBER Default NULL,
                                 p_tolerance     IN NUMBER Default 0.005,
                                 p_unit          IN VARCHAR2 Default NULL)
     Return mdsys.sdo_geometry deterministic;

   /** ----------------------------------------------------------------------------------------
   * @function   : Clip_Geom_Segment
   * @precis     : Wrapper to look like SDO_LRS.CLIP_GEOM_SEGMENT
   * @version    : 1.0
   * @history    : Simon Greener - Jun 2011 - Original coding.
   * @copyright  : Simon Greener, 2011, 2012
   * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
   *               http://creativecommons.org/licenses/by-sa/2.5/au/
   **/
   Function Clip_Geom_Segment(p_lrs_line      in mdsys.sdo_geometry,
                              p_current_start in number,
                              p_window_start  in number,
                              p_tolerance     IN NUMBER      DEFAULT 0.005,
                              p_unit          in varchar2    default null,
                              p_exception     IN PLS_INTEGER DEFAULT 0 )
     Return mdsys.sdo_geometry Deterministic;

    /** ----------------------------------------------------------------------------------------
    * @function   : Offset_Geom_Segment
    * @precis     : Returns a geometric segment at a specified measure range and offset.
    * @version    : 1.0
    * @description: The function clips a linestring based on the measure range then offsets the result.
    * @usage      : select ST_Offset_Geom_Segment(p_geometry) from dual;
    * @param      : p_geometry        : MDSYS.SDO_GEOMETRY : sdo_geometry whose ordinates will be reversed
    * @param      : p_start_measure   : NUMBER : Start measure of segment at which to start the offset operation.
    * @param      : p_end_measure     : NUMBER : End measure of geom_segment at which to start the offset operation.
    * @param      : p_offset          : NUMBER : Distance to measure perpendicularly from the points along geom_segment. 
    *                                            Positive offset values are to the left of geom_segment; 
    *                                            Negative offset values are to the right of geom_segment.
    * @param      : p_tolerance       : NUMBER : Tolerance value used in mdsys.sdo_geom.sdo_distance function.
    *                                            Default 0.00000001.
    * @param      : p_unit            : VARCHAR2 : Unit of measurement specification: a quoted string eg  'unit=km arc_tolerance=0.05'
    * @return     : modified geometry : MDSYS.SDO_GEOMETRY : Offset sdo geometry
    * @history    : Simon Greener - July 2012
    * @copyright  : Simon Greener, 2012
    * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
    **/
  Function Offset_Geom_Segment(p_geometry      IN SDO_GEOMETRY,
                               p_start_measure IN NUMBER,
                               p_end_measure   IN NUMBER,
                               p_offset        IN NUMBER,
                               p_tolerance     IN NUMBER DEFAULT 1.0e-8,
                               p_unit          IN VARCHAR2 DEFAULT NULL)
     Return SDO_Geometry Deterministic;

   /** ----------------------------------------------------------------------------------------
   * @function   : geom_segment_length
   * @precis     : Wrapper for sdo_length as is function in SDO_LRS.GEOM_SEGMENT_LENGTH
   * @version    : 1.0
   * @history    : Simon Greener - Jun 2011 - Original coding.
   * @copyright  : Simon Greener, 2011, 2012
   * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
   *               http://creativecommons.org/licenses/by-sa/2.5/au/
   **/
   Function geom_segment_length(p_geometry  in mdsys.sdo_geometry,
                                p_tolerance in number default 0.005,
                                p_unit      in varchar2 default null )
     Return Number Deterministic;
   
   /* ==================================================================== */
   /* ======================== Utility Functions ========================= */
   /* ==================================================================== */
   
   /*
   * @function ST_To2D
   * @precis   Converts a geometry to a 2D geometry
   * @version  2.0
   * @usage    v_2D_geom := LINEAR.ST_To2D(MDSYS.SDO_Geometry(3001,....)
   * @history  Albert Godfrind, July 2006, Original Coding
   * @history  Bryan Hall,      July 2006, Modified to handle points
   * @history  Simon Greener,   July 2006, Integrated into geom with GF.
   * @history  Simon Greener,   Aug  2009, Removed GF; Modified Byan Hall''s version to handle compound elements.
   * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
   *               http://creativecommons.org/licenses/by-sa/2.5/au/
   */
   Function ST_To2D(p_geom IN MDSYS.SDO_Geometry )
     Return MDSYS.SDO_Geometry deterministic;

   /*
   * @function ST_To3D
   * @precis   Converts a 2D or 4D geometry to a 3D geometry
   * @version  1.0
   * @usage    v_3D_geom := LINEAR.ST_To3D(MDSYS.SDO_Geometry(2001,....),50)
   * @history  Simon Greener,   May 2007 Original coding
   * @history  Simon Greener,   Aug 2009 Added support for interpolating Z values
   * @copyright Simon Greener, 2007 - 2012
   * @License   Creative Commons Attribution-Share Alike 2.5 Australia License.
   *            http://creativecommons.org/licenses/by-sa/2.5/au/
   */
  Function ST_To3D(p_geom      IN MDSYS.SDO_Geometry,
                   p_start_z   IN NUMBER   default NULL,
                   p_end_z     IN NUMBER   default NULL,
                   p_tolerance IN NUMBER   default 0.005, 
                   p_unit      in varchar2 default null)
     Return MDSYS.SDO_Geometry deterministic;

   /*
   * @function  ST_DownTo3D
   * @precis    Converts a 4D geometry to a 3D geometry
   * @version   1.0
   * @usage     v_3D_geom := LINEAR.ST_DownTo3D(MDSYS.SDO_Geometry(4001,....),50)
   * @history   Simon Greener,   May 2010 Original coding
   * @copyright Simon Greener, 2010 - 2012
   * @License   Creative Commons Attribution-Share Alike 2.5 Australia License.
   *            http://creativecommons.org/licenses/by-sa/2.5/au/
   */
  Function ST_DownTo3D(p_geom  IN MDSYS.SDO_Geometry,
                       p_z_ord IN INTEGER )
    Return MDSYS.SDO_GEOMETRY deterministic;

   /*
   * @Function  : ST_Fix3DZ
   * @Precis    : Checks the Z ordinate in the SDO_GEOMETRY and if NULL changes to p_default_z value
   * @Note      : Needed as MapServer/ArcSDE appear to not handle 3003/3007 polygons with NULL Z values
   *              in the sdo_ordinate_array
   * @History   : Simon Greener  -  JUNE 4th 2007  - Original Coding
   * @copyright : Simon Greener, 2007 - 2012
   * @License     Creative Commons Attribution-Share Alike 2.5 Australia License.
   *              http://creativecommons.org/licenses/by-sa/2.5/au/
   */
   Function ST_Fix3DZ( p_3D_geom   IN MDSYS.SDO_Geometry,
                       p_default_z IN NUMBER default -9999 )
     Return MDSYS.SDO_Geometry Deterministic;

    /** ----------------------------------------------------------------------------------------
    * @function   : ST_Reverse_Geometry
    * @precis     : Reverses ordinates in supplied sdo_geometry's sdo_ordinate_array.
    * @version    : 1.0
    * @description: The function reverses ordinates in supplied sdo_geometry's sdo_ordinate_array.
    * @usage      : select ST_Reverse_Geometry(p_geometry) from dual;
    * @param      : p_geometry        : MDSYS.SDO_GEOMETRY : sdo_geometry whose ordinates will be reversed
    * @return     : modified geometry : MDSYS.SDO_GEOMETRY : SDO_Geometry with reversed ordinates
    * @history    : Simon Greener - Feb 2012 2010
    * @copyright  : Simon Greener, 2010 - 2012
    * @License      Creative Commons Attribution-Share Alike 2.5 Australia License.
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
    **/
   Function ST_Reverse_Geometry(p_geometry in mdsys.sdo_geometry)
     Return mdsys.sdo_geometry Deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function  : ST_Parallel
  * @precis    : Function that moves the supplied linestring left/right a fixed amount.
  *              Bends in the linestring, when moved, can remain vertex-connected or be converted to curves.
  * @version   : 1.0
  * @usage     : FUNCTION ST_Parallel(p_geometry   in mdsys.sdo_geometry,
  *                                   p_distance   in number,
  *                                   p_tolerance  in number,
  *                                   p_curved     in number := 0)
  *                RETURN mdsys.sdo_geometry DETERMINISTIC;
  *              eg select ST_Parallel(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,1,10)),10,0.05) from dual;
  * @param     : p_geometry  : mdsys.sdo_geometry : Original linestring/multilinestring
  * @param     : p_distance  : Number : Distance to move parallel -vs = left; +ve = right
  * @param     : p_tolerance : Number : Standard Oracle diminfo tolerance.
  * @param     : p_unit      : VarChar2 : Unit of measure for distance calculations when defining snap point
  * @param     : p_curved    : Integer (but really boolean) : Boolean flag indicating whether to stroke
  *                                                           bends in line (1=stroke;0=leave alone)
  * @return    : mdsys.sdo_geometry : input geometry moved parallel by p_distance units
  * @history   : Simon Greener - Devember 2008 - Original coding.
  * @copyright : Simon Greener, 2008 - 2012
  * @License     Creative Commons Attribution-Share Alike 2.5 Australia License.
  *              http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  FUNCTION ST_Parallel(p_geometry   in mdsys.sdo_geometry,
                       p_distance   in number,
                       p_tolerance  in number,
                       p_curved     in number := 0,
                       p_unit       in varchar2 default null)
    RETURN mdsys.sdo_geometry DETERMINISTIC;

    /** ----------------------------------------------------------------------------------------
    * @function   : ST_RoundOrdinates
    * @precis     : Rounds ordinate values (sdo_ordinate_array) of an sdo_geometry
    * @version    : 1.0
    * @description: The function rounds ordinate values (sdo_ordinate_array) of an sdo_geometry
    * @usage      : select ST_RoundOrdinates(p_geometry) from dual
    * @param      : p_geometry        : MDSYS.SDO_GEOMETRY : sdo_geometry whose ordinates will be rounded
    * @param      : p_X_dec_places  : Number : X ordinate tolerance
    * @return     : p_y_dec_places  : Number : Y ordinate tolerance
    * @return     : p_z_dec_places  : Number : Z ordinate tolerance
    * @return     : p_m_dec_places  : Number : M ordinate tolerance
    * @return     : modified geometry : MDSYS.SDO_GEOMETRY : SDO_Geometry with rounded ordinates
    * @history    : Simon Greener - Jun 2010
    * @copyright  : Simon Greener, 2010 - 2012
    * @License      Creative Commons Attribution-Share Alike 2.5 Australia License.
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
    **/
  Function ST_RoundOrdinates(p_Geometry     In Mdsys.Sdo_Geometry,
                             p_X_dec_places In Number,
                             p_y_dec_places In Number Default null,
                             p_z_dec_places In Number Default Null,
                             p_m_dec_places In Number Default null)
    Return MDSYS.SDO_GEOMETRY DETERMINISTIC;

    /** ----------------------------------------------------------------------------------------
    * @function  : ST_hasElementCircularArcs
    * @precis    : A function that tests whether an sdo_geometry element contains circular arcs
    * @version   : 1.0
    * @history   : Simon Greener - Aug 2009 - Original coding.
    * @copyright : Simon Greener, 2009 - 2012
    * @License     Creative Commons Attribution-Share Alike 2.5 Australia License.
    *              http://creativecommons.org/licenses/by-sa/2.5/au/
    **/
    Function ST_hasElementCircularArcs(p_elem_type in number)
      return boolean deterministic;

   /** ----------------------------------------------------------------------------------------
   * @function  : ST_hasRectangles
   * @precis    : A function that tests whether an sdo_geometry contains rectangles
   * @version   : 1.0
   * @param     : p_elem_info : mdsys.sdo_elem_info_array : sdo_geometry's sdo_elem_info_array
   * @return    : pls_integer : 1 is true ie has optimized rectangle elements, 0 otherwise
   * @history   : Simon Greener - Jun 2011 - Original coding.
   * @copyright : Simon Greener, 2011 - 2012
   * @License     Creative Commons Attribution-Share Alike 2.5 Australia License.
   *              http://creativecommons.org/licenses/by-sa/2.5/au/
   **/
    Function ST_hasRectangles( p_elem_info in mdsys.sdo_elem_info_array  )
    Return Pls_Integer deterministic;
    
    /** ----------------------------------------------------------------------------------------
    * @function   : ST_Vectorize
    * @precis     : Places a geometry''s coordinates into a pipelined vector data structure.
    * @version    : 3.0
    * @description: Loads the coordinates of a linestring, polygon geometry into a
    *               pipelined vector data structure for easy manipulation by other functions
    *               such as geom.SDO_Centroid.
    * @usage      : Function ST_Vectorize( p_geometry IN MDSYS.SDO_GEOMETRY,
    *                                      p_dimarray IN MDSYS.SDO_DIM_ARRAY )
    *                 Return RETURN T_Vectors PIPELINED
    *               eg select *
    *                    from myshapetable a,
    *                         table(&&defaultSchema..linear.ST_Vectorize(a.shape));
    * @param      : p_geometry : MDSYS.SDO_GEOMETRY : A geographic shape.
    * @return     : geomVector : T_Vectors        : The vector pipelined.
    * @requires   : Global data types T_Vertex, T_Vector and t_Vectors
    * @requires   : GF package.
    * @history    : Simon Greener - July 2006 - Original coding from GetVector
    * @history    : Simon Greener - July 2008 - Re-write to be standalone of other packages eg GF
    * @history    : Simon Greener - October 2008 - Removed 2D limits
    * @copyright  : Simon Greener, 2006 - 2012
    * @License      Creative Commons Attribution-Share Alike 2.5 Australia License.
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
    **/
    Function ST_Vectorize(p_geometry  IN mdsys.sdo_geometry,
                          p_exception IN PLS_INTEGER DEFAULT 0)
      Return &&defaultSchema..LINEAR.T_Vectors pipelined;
      
  /***
  * @function  : ST_Vectorize
  * @precis    : Places a geometry's coordinates into a pipelined vector data structure using ST_Point (ie > 2D).
  * @version   : 2.0
  * @param     : p_geometry  : MDSYS.SDO_GEOMETRY : A geographic shape.
  * @param     : p_arc2chord : number : The arc2chord distance used in converting circular arcs and circles.
  *                                     Expressed in dataset units eg decimal degrees if 8311. See Convert_Distance
  *                                     for method of converting distance in meters to dataset units.
  * @param     : p_unit      : VarChar2 : Unit of measure for distance calculations when defining snap point
  * @history   : Simon Greener - Jan 2007 - ST_Point support, integrated into this package.
  * @history   : Simon Greener - Apr 2008 - Rebuilt to be a wrapper over GetVector.
  * @copyright : Simon Greener, 2007 - 2012
  * @License     Creative Commons Attribution-Share Alike 2.5 Australia License.
  *              http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  function ST_Vectorize(p_geometry  in mdsys.sdo_geometry,
                        p_arc2chord in number,
                        p_unit      in varchar2 default null,
                        p_exception IN PLS_INTEGER DEFAULT 0 )
    Return &&defaultSchema..LINEAR.t_Vectors pipelined;

    /** ----------------------------------------------------------------------------------------
    * @function   : ST_GetNumRings
    * @precis     : Returns Number of Rings in a polygon/mutlipolygon.
    * @version    : 1.0
    * @usage      : Function ST_GetNumRings ( p_geometry  IN MDSYS.SDO_GEOMETRY,
    *                                         p_ring_type IN INTEGER )
    *                 Return Number Deterministic;
    * @example    : SELECT ST_GetNumRings(SDO_GEOMETRY(2007,  -- two-dimensional multi-part polygon with hole
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
    * @param     : p_geometry : MDSYS.SDO_GEOMETRY : A shape.
    * @param     : p_ring_type : integer : Number of outer and inner rings.
    * @                           Values LINEAR.c_rings_all, LINEAR.c_rings_outer, LINEAR.c_rings_inner
    * @return    : numberRings : Number
    * @history   : Simon Greener - Dec 2008 - Original coding.
    * @copyright : Simon Greener, 2008 - 2012
    * @License     Creative Commons Attribution-Share Alike 2.5 Australia License.
    *              http://creativecommons.org/licenses/by-sa/2.5/au/
    **/
    Function ST_GetNumRings( p_geometry  in mdsys.sdo_geometry,
                             p_ring_type in integer default &&defaultSchema..LINEAR.c_rings_all  )
      Return Number Deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function  : ST_hasCircularArcs
  * @precis    : A function that tests whether an sdo_geometry contains circular arcs
  * @version   : 1.0
  * @history   : Simon Greener - Dec 2008 - Original coding.
  * @copyright : Simon Greener, 2008 - 2012
  * @License     Creative Commons Attribution-Share Alike 2.5 Australia License.
  *              http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function ST_hasCircularArcs(p_elem_info in mdsys.sdo_elem_info_array)
     return boolean deterministic;

  /** Wrappers
  */
  Function ST_isCompound(p_elem_info in mdsys.sdo_elem_info_array)
    return integer deterministic;

  Function ST_hasArc(p_elem_info in mdsys.sdo_elem_info_array)
    return integer deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_FindLineIntersection
  * @precis     : Find the point where two vectors intersect.
  * @version    : 1.0
  * @usage      : PROCEDURE ST_FindLineIntersection(x11 in number, y11 in number,
  *                                              x12 in Single, y12 in Single,
  *                                              x21 in Single, y21 in Single,
  *                                              x22 in Single, y22 in Single,
  *                                              inter_x  OUT Single, inter_y  OUT Single,
  *                                              inter_x1 OUT Single, inter_y1 OUT Single,
  *                                              inter_x2 OUT Single, inter_y2 OUT Single );
  * @param      : x11 : NUMBER : X Ordinate of the start point for the first vector
  * @param      : y11 : NUMBER : Y Ordinate of the start point for the first vector
  * @param      : x12 : NUMBER : X Ordinate of the end point for the first vector
  * @param      : y12 : NUMBER : Y Ordinate of the end point for the first vector
  * @param      : x21 : NUMBER : X Ordinate of the start point for the second vector
  * @param      : y21 : NUMBER : Y Ordinate of the start point for the second vector
  * @param      : x22 : NUMBER : X Ordinate of the end point for the second vector
  * @param      : y22 : NUMBER : Y Ordinate of the end point for the second vector
  * @description: (inter_x, inter_y) is the point where the lines
  *               defined by the segments intersect.
  *               (inter_x1, inter_y1) is the point on segment 1 that
  *               is closest to segment 2.
  *               (inter_x2, inter_y2) is the point on segment 2 that
  *               is closest to segment 1.

  * If the lines are parallel, all returned coordinates are 1E+38.
  * -------
  * Method:
  * Treat the lines as parametric where line 1 is:
  *   X = x11 + dx1 * t1
  *   Y = y11 + dy1 * t1
  * and line 2 is:
  *   X = x21 + dx2 * t2
  *   Y = y21 + dy2 * t2
  * Setting these equal gives:
  *   x11 + dx1 * t1 = x21 + dx2 * t2
  *   y11 + dy1 * t1 = y21 + dy2 * t2
  * Rearranging:
  *   x11 - x21 + dx1 * t1 = dx2 * t2
  *   y11 - y21 + dy1 * t1 = dy2 * t2
  *   (x11 - x21 + dx1 * t1) *   dy2  = dx2 * t2 *   dy2
  *   (y11 - y21 + dy1 * t1) * (-dx2) = dy2 * t2 * (-dx2)
  * Adding the equations gives:
  *   (x11 - x21) * dy2 + ( dx1 * dy2) * t1 +
  *   (y21 - y11) * dx2 + (-dy1 * dx2) * t1 = 0
  * Solving for t1 gives:
  *   t1 * (dy1 * dx2 - dx1 * dy2) =
  *   (x11 - x21) * dy2 + (y21 - y11) * dx2
  *   t1 = ((x11 - x21) * dy2 + (y21 - y11) * dx2) /
  *        (dy1 * dx2 - dx1 * dy2)
  * Now solve for t2.
  * ----------
  * @Note       : If 0 <= t1 <= 1, then the point lies on segment 1.
  *             : If 0 <= t2 <= 1, then the point lies on segment 1.
  *             : If dy1 * dx2 - dx1 * dy2 = 0 then the lines are parallel.
  *             : If the point of intersection is not on both
  *             : segments, then this is almost certainly not the
  *             : point where the two segments are closest.
  * @note       : Does not throw exceptions
  * @note       : Assumes planar projection eg UTM.
  * @history    : Simon Greener - Mar 2006 - Original coding.
  */
  Procedure ST_FindLineIntersection(
      x11       in number,        y11       in number,
      x12       in number,        y12       in number,
      x21       in number,        y21       in number,
      x22       in number,        y22       in number,
      inter_x  out nocopy number, inter_y  out nocopy number,
      inter_x1 out nocopy number, inter_y1 out nocopy number,
      inter_x2 out nocopy number, inter_y2 out nocopy number );

    /* ----------------------------------------------------------------------------------------
    * @function   : ST_AngleBetween3Points
    * @precis     : Return the angle in Radians. Returns a value between PI and -PI.
    * @version    : 1.0
    * @usage      : FUNCTION ST_AngleBetween3Points( dStartX in number,
    *                                                dStartY in number,
    *                                                dCentreX in number,
    *                                                dCentreY in number,
    *                                                dEndX in number,
    *                                                dEndY in number)
    *                        RETURN NUMBER DETERMINISTIC;
    *               eg :new.shape := COGO.ST_AngleBetween3Points(299900, 5200000, 300000, 5200000, 300000, 5200100);
    * @param      : dStartX  : NUMBER : X Ordinate of the start point for the first vector
    * @param      : dStartY  : NUMBER : Y Ordinate of the start point for the first vector
    * @param      : dCentreX : NUMBER : X Ordinate of the end point for the first vector and the start point for the second vector
    * @param      : dCentreY : NUMBER : Y Ordinate of the end point for the first vector and the start point for the second vector
    * @param      : dEndX    : NUMBER : X Ordinate of the end point for the second vector
    * @param      : dEndY    : NUMBER : Y Ordinate of the end point for the second vector
    * @return     : AngleBetween3Points : NUMBER : the angle in Radians between PI and -PI
    * @note       : Does not throw exceptions
    * @note       : Assumes planar projection eg UTM.
    * @history    : Steve Harwin - Feb 2005 - Original coding.
    */
    Function ST_AngleBetween3Points(dStartX in number,
                                    dStartY in number,
                                    dCentreX in number,
                                    dCentreY in number,
                                    dEndX in number,
                                    dEndY in number)
             Return Number Deterministic;

    /* Wrapper */
    Function ST_AngleBetween3Points(p_Start  in mdsys.vertex_type,
                                    p_Centre in mdsys.vertex_type,
                                    p_End    in mdsys.vertex_type)
             Return Number Deterministic;

    /* Wrapper */
    Function ST_AngleBetween3Points(p_Start  in T_Vertex,
                                    p_Centre in T_Vertex,
                                    p_End    in T_Vertex)
             Return Number Deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function  : Generate_Series
  * @precis    : Function that generates a series of numbers mimicking PostGIS's function with
  *              the same name
  * @version   : 1.0
  * @usage     : Function generate_series(p_start pls_integer,
  *                                       p_end   pls_integer,
  *                                       p_step  pls_integer )
  *                Return &&defaultSchema..geom.t_integers Pipelined;
  *              eg SELECT s.* FROM TABLE(generate_series(1,1000,10)) s;
  * @param     : p_start : Integer : Starting value
  * @param     : p_end   : Integer : Ending value.
  * @return    : p_step  : Integer : The step value of the increment between start and end
  * @history   : Simon Greener - June 2008 - Original coding.
  * @copyright : Simon Greener, 2007 - 2012
  * @License     Creative Commons Attribution-Share Alike 2.5 Australia License.
  *              http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function Generate_Series(p_start pls_integer,
                           p_end   pls_integer,
                           p_step  pls_integer )
       Return &&defaultSchema..LINEAR.t_integers Pipelined;

  /** ----------------------------------------------------------------------------------------
  * @function   : sdo_length
  * @precis     : SDO_GEOM.SDO_LENGTH is not licensed for LOCATOR users on certain databases.
  *               This function uses the licensed SDO_GEOM.SDO_DISTANCE function to compute length
  *               of lines, multilines, polygon and multipolygon boundaries.
  * @version    : 1.0
  * @description: This function is a SQL based function that uses sdo_distance which is a Locator function.
  * @usage      : Function SDO_Length ( p_geometry IN MDSYS.SDO_GEOMETRY,
  *                                     p_dimarray IN MDSYS.SDO_DIM_ARRAY
  *                                     p_unit     IN VarChar2 )
  *                 Return Number Deterministic;
  *               eg fixedShape := &&defaultSchema..LINEAR.sdo_length(shape,diminfo);
  * @param      : p_geometry   : MDSYS.SDO_GEOMETRY  : A valid sdo_geometry.
  * @param      : p_tolerance  : MDSYS.SDO_DIM_ARRAY : The dimarray describing the shape.
  * @param      : p_unit       : varchar2            : Unit of measure for geometries with SRIDs
  * @return     : length       : Number : Length of linestring or boundary of a polygon in required unit of measure
  * @note       : Supplied p_unit should exist in mdsys.SDO_UNITS_OF_MEASURE
  * @history    : Simon Greener - Jun 2011 - Original coding.
  * @copyright  : Simon Greener, 2011 - 2012
  * @License      Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function sdo_length(p_geometry  in mdsys.sdo_geometry,
                      p_tolerance in number   default 0.05,
                      p_unit      in varchar2 default 'Meter' )
    Return number deterministic;

  /** ----------------------------------------------------------------------------------------
  * @function  : SDO_LENGTH
  * @precis    : Overload of SDO_Length Function
  * @version   : 1.0
  * @usage     : Function SDO_Length ( p_geometry  IN MDSYS.SDO_GEOMETRY,
  *                                p_tolerance IN Number
  *                                p_units     IN VarChar2 )
  *                Return Number Deterministic;
  *              eg fixedShape := &&defaultSchema..LINEAR.sdo_length(shape,0.05);
  * @param     : p_geometry   : MDSYS.SDO_GEOMETRY : A valid sdo_geometry.
  * @param     : p_dimarray   : MDSYS.SDO_DIM_ARRAY : The dimarray describing the shape.
  * @param     : p_unit       : varchar2            : Unit of measure for geometries with SRIDs
  * @return    : length       : NUMBER : Length of linestring or boundary of a polygon in required unit of measure
  * @note      : Supplied p_unit should exist in mdsys.SDO_UNITS_OF_MEASURE
  * @history   : Simon Greener - Jun 2011 - Original coding.
  * @copyright : Simon Greener, 201 - 2012
  * @License     Creative Commons Attribution-Share Alike 2.5 Australia License.
  *              http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  Function sdo_length(p_geometry in mdsys.sdo_geometry,
                      p_diminfo  in mdsys.sdo_dim_array,
                      p_unit     in varchar2 default 'Meter' )
    Return number deterministic;

    /**----------------------------------------------------------------------------------------------------
    * @function    : Tokenizer
    * @precis      : Splits any string into its tokens.
    * @description : Supplied a string and a list of separators this function
    *                returns resultant tokens as a pipelined collection.
    * @example     : SELECT t.column_value
    *                      FROM TABLE(tokenizer('The rain in spain, stays mainly on the plain.!',' ,.!') ) t;
    * @param       : p_string. The string to be Tokenized.
    * @param       : p_separators. The characters that are used to split the string.
    * @requires    : T_Tokens type to be declared.
    * @history     : Pawel Barut, http://pbarut.blogspot.com/2007/03/yet-another-tokenizer-in-oracle.html
    * @history     : Simon Greener - July 2006 - Original coding (extended SQL sourced from a blog on the internet)
    * @copyright   : Simon Greener, 2006 - 2012
    * @License       Creative Commons Attribution-Share Alike 2.5 Australia License.
    *                http://creativecommons.org/licenses/by-sa/2.5/au/
    **/
    Function Tokenizer(p_string     In VarChar2,
                       p_separators In VarChar2 DEFAULT ' ')
      Return &&defaultSchema..T_Tokens Pipelined;

    /**----------------------------------------------------------------------------------------------------
    * @function    : TokenAggregator
    * @precis      : A string aggregator.
    * @description : Takes a set of strings an aggregates/appends them using supplied separator
    * @example     : SELECT TokenAggregator(CAST(COLLECT(to_char(l.lineid)) AS T_Tokens)) AS lineids
    *                      FROM test_lines_large_set l;
    * @param       : p_tokens    : The strings to be aggregated.
    * @param       : p_separator : The character that is placed between each token string.
    * @requires    : t_Tokens type to be declared.
    * @history     : Simon Greener - June 2011 - Original coding
    * @copyright   : Simon Greener, 2011 - 2012
    * @License       Creative Commons Attribution-Share Alike 2.5 Australia License.
    *                http://creativecommons.org/licenses/by-sa/2.5/au/
    **/
    Function TokenAggregator(p_tokens    IN &&defaultSchema..T_Tokens,
                             p_delimiter IN VarChar2 DEFAULT ',')
      Return VarChar2 Deterministic;

END LINEAR;
/
show errors

create or replace
PACKAGE BODY LINEAR AS

  c_module_name          CONSTANT varchar2(256) := 'Linear';

  -- Some useful constants
  --
  c_MaxVal               CONSTANT number        :=  999999999999.99999999;
  c_MinVal               CONSTANT number        := -999999999999.99999999;
  c_MaxLong              CONSTANT PLS_INTEGER   :=  2147483647;
  c_MinLong              CONSTANT PLS_INTEGER   := -2147483647;
  c_CoordMask            CONSTANT VARCHAR2(21)  := '999999999999.99999999';

  C_Pi                    Constant Number(16,14) := 3.14159265358979;
  c_MAX                   CONSTANT NUMBER        := 1E38;
  C_Min                   Constant Number        := -1E38;

  /* Exception constants
  */
  c_i_unsupported            CONSTANT INTEGER       := -20101;
  c_s_unsupported            CONSTANT VARCHAR2(100) := 'Compound objects, Circles, Arcs and Optimised Rectangles currently not supported.';
  c_i_dimensionality         CONSTANT INTEGER       := -20115;
  c_s_dimensionality         CONSTANT VARCHAR2(100) := 'Unable to determine dimensionality from geometry''s gtype (:1)';
  c_i_not_line               CONSTANT INTEGER       := -20116;
  c_s_not_line               CONSTANT VARCHAR2(100) := 'Input geometry is not a linestring';
  c_i_not_point              CONSTANT INTEGER       := -20117;
  c_s_not_point              CONSTANT VARCHAR2(100) := 'Input geometry is not a point';
  c_i_null_tolerance         CONSTANT INTEGER       := -20119;
  c_s_null_tolerance         CONSTANT VARCHAR2(100) := 'Input tolerance/dimarray must not be null';
  c_i_null_geometry          CONSTANT INTEGER       := -20120;
  c_s_null_geometry          CONSTANT VARCHAR2(100) := 'Input geometry must not be null';
  c_i_point_not_sdo_point    CONSTANT INTEGER       := -20130;
  c_s_point_not_sdo_point    CONSTANT VARCHAR2(100) := 'Input point must be sdo_point.';
  c_i_points_cannot_be_equal CONSTANT INTEGER       := -20131;
  c_s_points_cannot_be_equal CONSTANT VARCHAR2(100) := 'Input points must not be equal.';
  c_i_split_failed           CONSTANT INTEGER       := -20132;
  c_s_split_failed           CONSTANT VARCHAR2(100) := 'Split failed (check point1).';
  c_i_split_start_negative   CONSTANT INTEGER       := -20133;
  c_s_split_start_negative   CONSTANT VARCHAR2(100) := 'Start value may not be negative.';
  c_i_split_end_negative     CONSTANT INTEGER       := -20134;
  c_s_split_end_negative     CONSTANT VARCHAR2(100) := 'End value may not be negative.';
  c_i_split_start_not_online CONSTANT INTEGER       := -20135;
  c_s_split_start_not_online CONSTANT VARCHAR2(100) := 'Start value does not exist on line.';
  c_i_split_end_not_online   CONSTANT INTEGER       := -20136;
  c_s_split_end_not_online   CONSTANT VARCHAR2(100) := 'End value does not exist on line.';
  c_i_distance_not_negative  CONSTANT INTEGER       := -20137;
  c_s_distance_not_negative  CONSTANT VARCHAR2(100) := 'Distance may not be negative';
  c_i_distance_type_wrong    CONSTANT INTEGER       := -20138;
  c_s_distance_type_wrong    CONSTANT VARCHAR2(100) := 'Distance type must be L or M not ';
  c_i_not_measured           CONSTANT INTEGER       := -20139;
  c_s_not_measured           CONSTANT VARCHAR2(100) := 'Geometry is not measured.';
  c_i_must_be_linestring     CONSTANT INTEGER       := -20140;
  C_S_Must_Be_Linestring     Constant Varchar2(100) := 'Geometry must be a (multi-)linestring.';
  C_I_Null_Elem_Info         Constant Integer       := -20141;
  C_S_Null_Elem_Info         Constant Varchar2(100) := 'Geometry has null sdo_elem_info.';
  C_I_Arcs_Unsupported       Constant Integer       := -20142;
  C_S_Arcs_Unsupported       Constant Varchar2(100) := 'Geometries with Circular Arcs not supported.';
  c_i_value_type             CONSTANT INTEGER       := -20143;
  c_s_value_type             CONSTANT VARCHAR2(100) := 'Value Type can only be L or M';
  c_i_2d_only                CONSTANT INTEGER       := -20144;
  c_s_2d_only                CONSTANT VARCHAR2(100) := 'Only 2D geometries supported at this time';
  c_i_start_end_measure      Constant Integer       := -20145;
  c_s_start_end_measure      Constant Varchar2(100) := 'Start/End measures must be provided.';
  c_i_invalid_point          CONSTANT INTEGER       := -20146;
  c_s_invalid_point          CONSTANT VARCHAR2(100) := 'Input point has no sdo_point and no sdo_ordinate data.';
  c_i_srids_not_same         CONSTANT INTEGER       := -20147;
  c_s_srids_not_same         CONSTANT VARCHAR2(100) := 'Input sdo_geometry objects have different SRIDS.';

  Procedure logger(p_text in varchar2)
  As
  Begin
    dbms_output.put_line(p_text);
  End logger;

  -- *************************** Internal Utilities

  Function InitializeVertexType
    return mdsys.vertex_type deterministic
  is
  begin
     return mdsys.sdo_util.getVertices(mdsys.sdo_geometry(4001,null,null,mdsys.sdo_elem_info_array(1,1,1),mdsys.sdo_ordinate_array(NULL,NULL,NULL,NULL)))(1);
  End InitializeVertexType;

  Function T_Vertex2VertexType(p_coord in &&defaultSchema..T_Vertex)
    return mdsys.vertex_type deterministic
  is
  begin
     return mdsys.sdo_util.getVertices(mdsys.sdo_geometry(4001,null,null,mdsys.sdo_elem_info_array(1,1,1),
                                                          mdsys.sdo_ordinate_array(p_coord.x,p_coord.y,p_coord.z,p_coord.w)))(1);
  End T_Vertex2VertexType;

 /** ----------------------------------------------------------------------------------------
  * @function   : ADD_COORDINATE
  * @precis     : A procedure that allows a user to add a new coordinate to a supplied ordinate info array.
  * @version    : 1.0
  * @history    : Simon Greener - Jul 2001 - Original coding.
  * @todo       : Integrate into GF
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. (http://creativecommons.org/licenses/by-sa/2.5/au/)
  **/
  PROCEDURE ADD_Coordinate( p_ordinates   in out nocopy mdsys.sdo_ordinate_array,
                            p_dim         in number,
                            p_x_coord     in number,
                            p_y_coord     in number,
                            p_z_coord     in number,
                            p_m_coord     in number,
                            p_measure_dim in pls_integer := 0)
    IS
      v_measure_dim pls_integer := NVL(p_measure_dim,0);
      
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
                              then ( p_ordinates(p_ordinates.COUNT)   = p_z_coord 
                                     AND
                                     p_ordinates(p_ordinates.COUNT-1) = p_y_coord
                                     AND
                                     p_ordinates(p_ordinates.COUNT-2) = p_x_coord )
                              when 4
                              then ( p_ordinates(p_ordinates.COUNT)   = case when v_measure_dim=4 then p_m_coord else p_z_coord end
                                     AND
                                     p_ordinates(p_ordinates.COUNT-1) = case when v_measure_dim=3 then p_z_coord else p_m_coord end
                                     AND
                                     p_ordinates(p_ordinates.COUNT-2) = p_y_coord
                                     AND
                                     p_ordinates(p_ordinates.COUNT-3) = p_x_coord )
                          end
                  End;
      End Duplicate;

  Begin
    If ( p_ordinates is null ) Then
      p_ordinates := new mdsys.sdo_ordinate_array(10);
      p_ordinates.DELETE;
    End If;
    If Not Duplicate() Then
      IF ( p_dim >= 2 ) Then
        p_ordinates.extend(2);
        p_ordinates(p_ordinates.count-1) := p_x_coord;
        p_ordinates(p_ordinates.count  ) := p_y_coord;
      END IF;
      IF ( p_dim >= 3 ) Then
        p_ordinates.extend(1);
        p_ordinates(p_ordinates.count)   := p_z_coord;
      END IF;
      IF ( p_dim = 4 ) Then
        p_ordinates.extend(1);
        p_ordinates(p_ordinates.count)   := case when v_measure_dim=3 then p_z_coord else p_m_coord end;
      END IF;
    End If;
  END ADD_Coordinate;

  PROCEDURE ADD_Coordinate( p_ordinates   in out nocopy mdsys.sdo_ordinate_array,
                            p_dim         in number,
                            p_coord       in mdsys.vertex_type,
                            p_measure_dim in pls_integer := 0)
  Is
  Begin
    ADD_Coordinate( p_ordinates, p_dim, p_coord.x, p_coord.y, p_coord.z, p_coord.w, p_measure_dim);
  END Add_Coordinate;

  PROCEDURE ADD_Coordinate( p_ordinates   in out nocopy mdsys.sdo_ordinate_array,
                            p_dim         in number,
                            p_coord       in &&defaultSchema..T_Vertex,
                            p_measure_dim in pls_integer := 0)
  Is
  Begin
    ADD_Coordinate( p_ordinates, p_dim, p_coord.x, p_coord.y, p_coord.z, p_coord.w, p_measure_dim);
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

  Procedure ADD_Element( p_sdo_elem_info     in out nocopy mdsys.sdo_elem_info_array,
                         p_elem_info_array   in mdsys.sdo_elem_info_array,
                         p_current_ord_count in number)
  IS
    v_i                 pls_integer;
    v_end_sdo_elem      pls_integer;
    v_additional        pls_integer;
  Begin
    if (    p_sdo_elem_info   is null
         or p_elem_info_array is null ) Then
         return;
    End If;
    v_end_sdo_elem := p_sdo_elem_info.COUNT;
    v_additional   := p_elem_info_array.COUNT;
    p_sdo_elem_info.EXTEND(v_additional);
    FOR v_i IN 1..v_additional LOOP
        if ( v_end_sdo_elem = 0 ) then
           p_sdo_elem_info(v_i) := p_Elem_Info_array(v_i);
        ElsIf ( MOD(v_i,3) = 1 ) then
           p_sdo_elem_info(v_end_sdo_elem + v_i) := p_current_ord_count + p_Elem_Info_array(v_i);
        else
           p_sdo_elem_info(v_end_sdo_elem + v_i) := p_Elem_Info_array(v_i);
        End If;
    END LOOP;
  END ADD_Element;

  Function Rectangle2Polygon(p_geometry in mdsys.sdo_geometry)
    return mdsys.sdo_geometry
  As
    v_dims      pls_integer;
    v_ordinates mdsys.sdo_ordinate_array := new mdsys.sdo_ordinate_array(null);
    v_vertices  mdsys.vertex_set_type;
    v_etype     pls_integer;
    v_start_coord mdsys.vertex_type;
    v_end_coord   mdsys.vertex_type;
  Begin
      v_ordinates.DELETE;
      v_dims        := p_geometry.get_dims();
      v_etype       := p_geometry.sdo_elem_info(2);
      v_vertices    := sdo_util.getVertices(p_geometry);
      v_start_coord := v_vertices(1);
      v_end_coord   := v_vertices(2);
      -- First coordinate
      ADD_Coordinate( v_ordinates, v_dims, v_start_coord.x, v_start_coord.y, v_start_coord.z, v_start_coord.w );
      -- Second coordinate
      If ( v_etype = 1003 ) Then
        ADD_Coordinate(v_ordinates,v_dims,v_end_coord.x,v_start_coord.y,(v_start_coord.z + v_end_coord.z) /2, v_start_coord.w);
      Else
        ADD_Coordinate(v_ordinates,v_dims,v_start_coord.x,v_end_coord.y,(v_start_coord.z + v_end_coord.z) /2,
            (v_end_coord.w - v_start_coord.w) * ((v_end_coord.x - v_start_coord.x) /
           ((v_end_coord.x - v_start_coord.x) + (v_end_coord.y - v_start_coord.y)) ));
      End If;
      -- 3rd or middle coordinate
      ADD_Coordinate(v_ordinates,v_dims,v_end_coord.x,v_end_coord.y,v_end_coord.z,v_end_coord.w);
      -- 4th coordinate
      If ( v_etype = 1003 ) Then
        ADD_Coordinate(v_ordinates,v_dims,v_start_coord.x,v_end_coord.y,(v_start_coord.z + v_end_coord.z) /2,v_start_coord.w);
      Else
        Add_Coordinate(v_ordinates,v_dims,v_end_coord.x,v_start_coord.y,(v_start_coord.z + v_end_coord.z) /2,
            (v_end_coord.w - v_start_coord.w) * ((v_end_coord.x - v_start_coord.x) /
           ((v_end_coord.x - v_start_coord.x) + (v_end_coord.y - v_start_coord.y)) ));
      End If;
      -- Last coordinate
      ADD_Coordinate(v_ordinates,v_dims,v_start_coord.x,v_start_coord.y,v_start_coord.z,v_start_coord.w);
      return mdsys.sdo_geometry(p_geometry.sdo_gtype,p_geometry.sdo_srid,null,mdsys.sdo_elem_info_array(1,v_etype,1),v_ordinates);
  End Rectangle2Polygon;

  /* ====================================== COGO
  */
  
  Function degrees(p_radians in number)
  return number
  Is
  Begin
    return p_radians * (180.0 / c_PI);
  End degrees;

  /*
  *      radians     - returns radians converted from degrees
  */
  Function radians(p_degrees in number)
    Return number
  Is
  Begin
    Return p_degrees * (c_PI / 180.0);
  End radians;

  Function ArcTan2(dOpp in number,
                   dAdj in number)
  Return Number
  IS
      dAngleRad Number;
  BEGIN
      --Get the basic angle.
      If Abs(dAdj) < 0.0001 Then
          dAngleRad := c_PI / 2;
      Else
          dAngleRad := Abs(aTan(dOpp / dAdj));
      End If;

      --See if we are in quadrant 2 or 3.
      If dAdj < 0 Then
          --dAngle > c_PI/2 or angle < -c_PI/2.
          dAngleRad := c_PI - dAngleRad;
      End If;
      --See if we are in quadrant 3 or 4.
      If dOpp < 0 Then
          dAngleRad := -dAngleRad;
      End If;
      --Return the result.
      Return dAngleRad;
  END ArcTan2;

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
      If (dE1 Is Null or dN1 Is Null or dE2 Is Null or dE1 Is null ) THEN
         Return Null;
      End If;
      If ( (dE1 = dE2) And (dN1 = dN2) ) Then
         Return Null;
      End If;
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

    FUNCTION PointFromBearingAndDistance (
                               dStartE in number,
                               dStartN in number,
                               dBearing in number,
                               dDistance in number
                               )
    RETURN MDSYS.SDO_GEOMETRY
    IS
      dAngle1 NUMBER;
      dAngle1Rad NUMBER;
      dDeltaN NUMBER;
      dDeltaE NUMBER;
      dEndE Number;
      dEndN Number;
    BEGIN
      -- First calculate dDeltaE and dDeltaN
        If dBearing < 90 Then
            dAngle1 := 90 - dBearing;
            dAngle1Rad := dAngle1 * c_PI / 180;
            dDeltaE := Cos(dAngle1Rad) * dDistance;
            dDeltaN := Sin(dAngle1Rad) * dDistance;
        ElsIf dBearing < 180 Then
            dAngle1 := dBearing - 90;
            dAngle1Rad := dAngle1 * c_PI / 180;
            dDeltaE := Cos(dAngle1Rad) * dDistance;
            dDeltaN := Sin(dAngle1Rad) * dDistance * -1;
        ElsIf dBearing < 270 Then
            dAngle1 := 270 - dBearing;
            dAngle1Rad := dAngle1 * c_PI / 180;
            dDeltaE := Cos(dAngle1Rad) * dDistance * -1;
            dDeltaN := Sin(dAngle1Rad) * dDistance * -1;
        ElsIf dBearing <= 360 Then
            dAngle1 := dBearing - 270;
            dAngle1Rad := dAngle1 * c_PI / 180;
            dDeltaE := Cos(dAngle1Rad) * dDistance * -1;
            dDeltaN := Sin(dAngle1Rad) * dDistance;
        End If;
        -- Calculate the easting and northing of the end point
        dEndE := dDeltaE + dStartE;
        dEndN := dDeltaN + dStartN;
      RETURN MDSYS.SDO_GEOMETRY(2001,NULL,MDSYS.SDO_POINT_TYPE(dEndE,dEndN,NULL),NULL,NULL);
    END PointFromBearingAndDistance;
  
  /* ============================================== Utility functions */
  
  Function sdo_distance(p_geom1     in mdsys.sdo_geometry,
                        p_geom2     in mdsys.sdo_geometry,
                        p_tolerance in number default 0.05,
                        p_unit      in varchar2 default null)
  Return Number Deterministic
  As
  Begin
    If ( p_geom1 is null or p_geom2 is null ) Then
       return 0.0;
    End If;
    Return case when p_geom1.sdo_srid is not null
                then mdsys.sdo_geom.sdo_distance(p_geom1,p_geom2,p_tolerance,p_unit)
                else mdsys.sdo_geom.sdo_distance(p_geom1,p_geom2,p_tolerance)
            end;
  End sdo_distance;
  
  Function ST_hasRectangles( p_elem_info in mdsys.sdo_elem_info_array  )
    Return Pls_Integer
  Is
     v_rectangle_count number := 0;
     v_etype           pls_integer;
     v_interpretation  pls_integer;
     v_elements        pls_integer;
  Begin
     If ( p_elem_info is null ) Then
        return 0;
     End If;
     v_elements := ( ( p_elem_info.COUNT / 3 ) - 1 );
     <<element_extraction>>
     for v_i IN 0 .. v_elements LOOP
       v_etype := p_elem_info(v_i * 3 + 2);
       v_interpretation := p_elem_info(v_i * 3 + 3);
       If  ( v_etype in (1003,2003) AND v_interpretation = 3  ) Then
           v_rectangle_count := v_rectangle_count + 1;
       end If;
     end loop element_extraction;
     Return v_rectangle_Count;
  End ST_hasRectangles;

  Function ST_hasCircularArcs(p_elem_info in mdsys.sdo_elem_info_array)
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
   End ST_hasCircularArcs;

  Function ST_isCompound(p_elem_info in mdsys.sdo_elem_info_array)
    return integer
  IS
  Begin
    return case when &&defaultSchema..LINEAR.ST_hasCircularArcs(p_elem_info) then 1 else 0 end;
  End ST_isCompound;

  Function ST_hasArc(p_elem_info in mdsys.sdo_elem_info_array)
    return integer
  IS
  Begin
    return case when &&defaultSchema..LINEAR.ST_hasCircularArcs(p_elem_info) then 1 else 0 end;
  End ST_hasArc;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_isMeasured
  * @precis     : A function that tests whether an sdo_geometry contains LRS measures
  * @version    : 1.0
  * @history    : Simon Greener - Dec 2008 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. (http://creativecommons.org/licenses/by-sa/2.5/au/)
  **/
  Function ST_isMeasured( p_gtype in number )
   return pls_integer
   is
   Begin
    /* SDO_GTYPE value is 4 digits in the format DLTT
    * L identifies the linear referencing measure dimension for a three-dimensional linear referencing system (LRS) geometry, 
    * that is, which dimension (3 or 4) contains the measure value. For a non-LRS geometry, or to accept the Spatial default 
    * of the last dimension as the measure for an LRS geometry, specify 0. For information about the linear referencing system (LRS)
    */
     Return CASE WHEN MOD(trunc(p_gtype/100),10) != 0 /* OR TRUNC(p_gtype/1000,0) > 3 */
                 THEN 1
                 ELSE 0
              END;
   End ST_isMeasured;

  Function ST_getMeasureDimension( p_gtype in number )
   return pls_integer
   is
   Begin
    /* SDO_GTYPE value is 4 digits in the format DLTT
    * L identifies the linear referencing measure dimension for a three-dimensional linear referencing system (LRS) geometry, 
    * that is, which dimension (3 or 4) contains the measure value. For a non-LRS geometry, or to accept the Spatial default 
    * of the last dimension as the measure for an LRS geometry, specify 0. For information about the linear referencing system (LRS)
    */
     Return MOD(trunc(p_gtype/100),10);
   End ST_getMeasureDimension;

  Function ST_RoundOrdinates(p_Geometry     In Mdsys.Sdo_Geometry,
                             p_X_dec_places In Number,
                             p_y_dec_places In Number Default null,
                             p_Z_dec_places In Number Default Null,
                             p_m_dec_places In Number Default null)
  Return MDSYS.SDO_GEOMETRY
  Is
    v_dim              pls_integer;
    v_ord              pls_integer;
    v_measure_ord      pls_integer;
    -- Copy geometry so it can be edited
    v_geometry         mdsys.sdo_geometry := p_geometry;
    V_X_dec_places     Number := P_X_dec_places;
    V_Y_dec_places     Number := Nvl(P_Y_dec_places,
                                     P_X_dec_places);
    V_Z_dec_places     Number := Nvl(P_z_dec_places,
                                     P_X_dec_places);
    v_m_dec_places     Number := NVL(p_m_dec_places,
                                     p_x_dec_places);
  Begin
    If ( p_geometry is null ) Then
      raise_application_error(c_i_null_geometry,c_s_null_geometry,true);
    End If;
    If ( p_x_dec_places Is Null ) Then
      raise_application_error(c_i_null_tolerance,c_s_null_tolerance,true);
    End If;
    v_dim   := p_geometry.get_dims();
    -- If point update differently to other shapes
    If ( V_Geometry.Sdo_Point Is Not Null ) Then
      v_geometry.sdo_point.X := round(v_geometry.sdo_point.x,
                                      v_x_dec_places);
      V_Geometry.Sdo_Point.Y := Round(V_Geometry.Sdo_Point.Y,
                                      v_y_dec_places);
      If ( v_dim > 2 ) Then
        v_geometry.sdo_point.z := round(v_geometry.sdo_point.z,
                                        v_z_dec_places);
      End If;
    End If;
    -- Now let's round the ordinates
    If ( p_geometry.sdo_ordinates is not null ) Then
      v_measure_ord := p_geometry.Get_Lrs_Dim();
      v_ord := 0;
      <<while_vertex_to_process>>
      For v_i In 1..(v_geometry.sdo_ordinates.COUNT/v_dim) Loop
         v_ord := v_ord + 1;
         v_geometry.sdo_ordinates(v_ord) :=
                          round(p_geometry.sdo_ordinates(v_ord),
                                v_x_dec_places);
         v_ord := v_ord + 1;
         v_geometry.sdo_ordinates(v_ord) :=
                          round(p_geometry.sdo_ordinates(v_ord),
                                v_y_dec_places);
         If ( v_dim >= 3 ) Then
            v_ord := v_ord + 1;
            v_geometry.sdo_ordinates(v_ord) := 
                round(p_geometry.sdo_ordinates(v_ord),
                      Case When v_measure_ord in (0,4)
                           Then v_z_dec_places
                           When v_measure_ord = 3
                           Then v_m_dec_places
                       End);
            if ( v_dim > 3 ) Then
               v_ord := v_ord + 1;
               v_geometry.sdo_ordinates(v_ord) := 
                round(p_geometry.sdo_ordinates(v_ord), 
                      v_m_dec_places);
            End If;
         End If;
      End Loop while_vertex_to_process;
    End If;
    Return v_geometry;
  End ST_RoundOrdinates;

  /* ======================================== LINEAR FUNCTIONS ============= */
  
  /**
  * FindSplitVector
  * Not public.
  * Common splitting function
  **/
  Procedure FindSplitVector( p_geometry   in mdsys.sdo_geometry,
                             p_point      in mdsys.sdo_geometry,
                             p_vector_1   out nocopy &&defaultSchema..t_vector,
                             p_vector_2   out nocopy &&defaultSchema..t_vector,
                             p_vector_id  out nocopy pls_integer,
                             p_snap_point out nocopy mdsys.sdo_geometry,
                             p_snap       in pls_integer DEFAULT 0,
                             p_tolerance  in number      DEFAULT 0.005,
                             p_unit       in varchar2 default null,
                             p_exception  in pls_integer DEFAULT 0)
  Is
    v_gtype_p        pls_integer;
    v_gtype_l        pls_integer;
    v_dims           pls_integer;
    v_part           number;
    v_element        number;
    v_num_elements   number;
    v_start_distance number;
    v_x1             number;
    v_y1             number;
    v_z1             number;
    v_w1             number;
    v_end_distance   number;
    v_x2             number;
    v_y2             number;
    v_z2             number;
    v_w2             number;
    v_line_distance  number;
    v_ratio          number;
    V_Min_Dist       Number;
    v_dist           number;
    V_Vector_1       &&defaultSchema..T_Vector := &&defaultSchema..T_Vector(0,&&defaultSchema..T_Vertex(C_Minval,C_Minval,C_Minval,C_Minval,1),
                                                            &&defaultSchema..T_Vertex(C_Minval,C_Minval,C_Minval,C_Minval,1));
    V_Vector_2       &&defaultSchema..T_Vector := &&defaultSchema..T_Vector(0,&&defaultSchema..T_Vertex(C_Minval,C_Minval,C_Minval,C_Minval,2),
                                                            &&defaultSchema..T_Vertex(c_MinVal,c_MinVal,c_MinVal,c_MinVal,2));

    v_round_factor number;
    NULL_GEOMETRY      EXCEPTION;
  Begin
    If ( p_geometry is null ) Then
       If ( p_exception is null or p_exception = 1) then
           raise NULL_GEOMETRY;
       Else
           return;
       End If;
    End If;
    If ( p_point is null ) Then
       if ( p_exception is null or p_exception = 1) then
           raise NULL_GEOMETRY;
       Else
           return;
       End If;
    End If;
    -- Compute rounding factors
    v_round_factor := round(log(10,(1/p_tolerance)/2));
    -- Measure distance in 2D or 3D only
    v_dims  := p_geometry.Get_Dims();
    if ( v_dims > 3 ) Then
       v_dims := 3;
    End If;
    v_gtype_p := v_dims * 1000 + 1;
    v_gtype_l := v_dims * 1000 + 2;

    select id,startdist,x1,y1,z1,w1,enddist,x2,y2,z2,w2,linedist,startdist/(startdist+enddist) as ratio
      into p_vector_id,
           v_start_distance,
           v_x1,v_y1,v_z1,v_w1,
           v_end_distance,
           v_x2,v_y2,v_z2,v_w2,
           v_line_distance,
           v_ratio
      from (select rownum as id,
                   b.startcoord.x as x1,
                   b.startcoord.y as y1,
                   b.startcoord.z as z1,
                   b.startcoord.w as w1,
                   b.endcoord.x as x2,
                   b.endcoord.y as y2,
                   b.endcoord.z as z2,
                   b.endcoord.w as w2,             
                   case when p_geometry.sdo_srid is not null 
                        then mdsys.sdo_geom.sdo_distance(
                                      mdsys.sdo_geometry(v_gtype_p,p_geometry.sdo_srid,
                                          mdsys.sdo_point_type(b.startcoord.x,b.startcoord.y,b.startCoord.z),NULL,NULL),
                                    p_point,p_tolerance,p_unit)
                        else mdsys.sdo_geom.sdo_distance(
                                      mdsys.sdo_geometry(v_gtype_p,p_geometry.sdo_srid,
                                          mdsys.sdo_point_type(b.startcoord.x,b.startcoord.y,b.startCoord.z),NULL,NULL),
                                    p_point,p_tolerance)
                    end as startDist,
                    
                   case when p_geometry.sdo_srid is not null 
                        then mdsys.sdo_geom.sdo_distance(
                                      mdsys.sdo_geometry(v_gtype_p,p_geometry.sdo_srid,
                                            mdsys.sdo_point_type(b.endcoord.x,b.endcoord.y,b.endCoord.z),NULL,NULL),
                                            p_point,p_tolerance,p_unit) 
                        else mdsys.sdo_geom.sdo_distance(
                                      mdsys.sdo_geometry(v_gtype_p,p_geometry.sdo_srid,
                                            mdsys.sdo_point_type(b.endcoord.x,b.endcoord.y,b.endCoord.z),NULL,NULL),
                                            p_point,p_tolerance) 
                    end as endDist,
                   case when p_geometry.sdo_srid is not null 
                        then mdsys.sdo_geom.sdo_distance(
                                            mdsys.sdo_geometry(v_gtype_l,p_geometry.sdo_srid,NULL,
                                                               mdsys.sdo_elem_info_array(1,2,1),
                                                               decode(v_dims,3,mdsys.sdo_ordinate_array(b.startcoord.x,b.startcoord.y,b.startcoord.z,
                                                                                                        b.endcoord.x,b.endcoord.y,b.endcoord.z),
                                                                               mdsys.sdo_ordinate_array(b.startcoord.x,b.startcoord.y,
                                                                                                        b.endcoord.x,b.endcoord.y))),
                                            p_point,p_tolerance,p_unit) 
                        else mdsys.sdo_geom.sdo_distance(
                                            mdsys.sdo_geometry(v_gtype_l,p_geometry.sdo_srid,NULL,
                                                               mdsys.sdo_elem_info_array(1,2,1),
                                                               decode(v_dims,3,mdsys.sdo_ordinate_array(b.startcoord.x,b.startcoord.y,b.startcoord.z,
                                                                                                        b.endcoord.x,b.endcoord.y,b.endcoord.z),
                                                                               mdsys.sdo_ordinate_array(b.startcoord.x,b.startcoord.y,
                                                                                                        b.endcoord.x,b.endcoord.y))),
                                            p_point,p_tolerance) 
                    end as linedist
             from table(&&defaultSchema..LINEAR.ST_Vectorize(p_geometry)) b
             order by 12 /* linedist */
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
           -- point splits line at the start of the vector
           if ( p_snap = 1 ) Then
              p_snap_point := mdsys.sdo_geometry(v_gtype_p,p_point.sdo_srid,
                                mdsys.sdo_point_type(ROUND(v_x1,v_round_factor),
                                                     ROUND(v_y1,v_round_factor),
                                                     v_z1),null,null);
              return;
           End If;
           V_Vector_1 := Null;
           v_vector_2 := &&defaultSchema..T_Vector(0,&&defaultSchema..T_Vertex(ROUND(v_x1,v_round_factor),
                                                     Round(V_Y1,v_round_factor),V_Z1,V_W1,1),
                                        &&defaultSchema..T_Vertex(ROUND(v_x2,v_round_factor),
                                                     ROUND(v_y2,v_round_factor),v_z2,v_w2,1));
        elsif ( v_end_distance = 0 ) then
           -- point Splits line at the end of the vector
           if ( p_snap = 1 ) Then
              p_snap_point := mdsys.sdo_geometry(v_gtype_p,p_point.sdo_srid,
                                mdsys.sdo_point_type(ROUND(v_x2,v_round_factor),
                                                     ROUND(v_y2,v_round_factor),
                                                     ROUND(v_z2,v_round_factor)),null,null);
              return;
           End If;
           V_Vector_1 := &&defaultSchema..T_Vector(0,&&defaultSchema..T_Vertex(Round(V_X1,v_round_factor),
                                                     Round(V_Y1,v_round_factor),V_Z1,V_W1,1),
                                        &&defaultSchema..T_Vertex(Round(V_X2,v_round_factor),
                                                     ROUND(v_y2,v_round_factor),v_z2,v_w2,1));
           v_vector_2 := NULL;
        else
           -- point is on line between start and end of vector
           if ( p_snap = 1 ) Then
              p_snap_point := p_point;
              return;
           End If;
           v_vector_1 := &&defaultSchema..T_Vector(0,&&defaultSchema..T_Vertex(ROUND(v_x1,v_round_factor),
                                                     ROUND(v_y1,v_round_factor),v_z1,v_w1,1),
                                        &&defaultSchema..T_Vertex(p_point.sdo_point.x,p_point.sdo_point.y,p_point.sdo_point.z,null,1));
           v_vector_2 := &&defaultSchema..T_Vector(0,&&defaultSchema..T_Vertex(p_point.sdo_point.x,p_point.sdo_point.y,p_point.sdo_point.z,null,2),
                                        &&defaultSchema..T_Vertex(ROUND(v_x2,v_round_factor),
                                                     ROUND(v_y2,v_round_factor),v_z2,v_w2,2));
        end if;
    else
       If ( v_line_distance = v_start_distance ) then
           -- point can only split line at the start of the vector
           if ( p_snap = 1 ) Then
              p_snap_point := mdsys.sdo_geometry(v_gtype_p,p_point.sdo_srid,
                                   mdsys.sdo_point_type(ROUND(v_x1,v_round_factor),
                                                        ROUND(v_y1,v_round_factor),
                                                        v_z1),null,null);
              return;
           End If;
           v_vector_1 := NULL;
           v_vector_2 := &&defaultSchema..T_Vector(0,&&defaultSchema..T_Vertex(ROUND(v_x1,v_round_factor),
                                                     ROUND(v_y1,v_round_factor),v_z1,v_w1,2),
                                        &&defaultSchema..T_Vertex(ROUND(v_x2,v_round_factor),
                                                     ROUND(v_y2,v_round_factor),v_z2,v_w2,2));
       elsIf ( v_line_distance = v_end_distance ) then
           -- point can only split line at the end of the vector
           if ( p_snap = 1 ) Then
              p_snap_point := mdsys.sdo_geometry(v_gtype_p,p_point.sdo_srid,
                                mdsys.sdo_point_type(ROUND(v_x2,v_round_factor),
                                                     ROUND(v_y2,v_round_factor),
                                                     v_z2),null,null);
              return;
           End If;
           v_vector_1 := &&defaultSchema..T_Vector(0,&&defaultSchema..T_Vertex(ROUND(v_x1,v_round_factor),
                                                     ROUND(v_y1,v_round_factor),v_z1,v_w1,1),
                                        &&defaultSchema..T_Vertex(ROUND(v_x2,v_round_factor),
                                                     ROUND(v_y2,v_round_factor),v_z2,v_w2,1));
           v_vector_2 := NULL;
       else
           -- point is between first and last vertex so split point is ratio of start/end distances
           if ( p_snap = 1 ) Then
              p_snap_point := mdsys.sdo_geometry(v_gtype_p,p_point.sdo_srid,
                                     mdsys.sdo_point_type(ROUND(v_x1+(v_x2-v_x1)*v_ratio,v_round_factor),
                                                          ROUND(v_y1+(v_y2-v_y1)*v_ratio,v_round_factor),
                                                          ROUND(v_z1+(v_z2-v_z1)*v_ratio,v_round_factor)),null,null);
              Return;
           End If;
           V_Vector_1 := &&defaultSchema..T_Vector(0,&&defaultSchema..T_Vertex(Round(V_X1,v_round_factor),ROUND(v_y1,v_round_factor),v_z1,v_w1,1),
                                        &&defaultSchema..T_Vertex(ROUND(v_x1+(v_x2-v_x1)*v_ratio,v_round_factor),
                                                     ROUND(v_y1+(v_y2-v_y1)*v_ratio,v_round_factor),
                                                     v_z1,v_w1,2));
           v_vector_2 := &&defaultSchema..T_Vector(0,&&defaultSchema..T_Vertex(ROUND(v_vector_1.endCoord.x,v_round_factor),
                                                     ROUND(v_vector_1.endCoord.y,v_round_factor),
                                                     v_vector_1.endCoord.z,
                                                     v_vector_1.endCoord.w,
                                                     2),
                                        &&defaultSchema..T_Vertex(ROUND(v_x2,v_round_factor),
                                                     ROUND(v_y2,v_round_factor),v_z2,v_w2,2));
        end if;
    End If;
    -- dbms_output.put_line('Vector1: ('||v_vector_1.startcoord.x||','||v_vector_1.startcoord.y||')('||v_vector_1.endcoord.x||','||v_vector_1.endcoord.y||')');
    -- dbms_output.put_line('Vector2: ('||v_vector_2.startcoord.x||','||v_vector_2.startcoord.y||')('||v_vector_2.endcoord.x||','||v_vector_2.endcoord.y||')');
    p_vector_1 := v_vector_1;
    p_vector_2 := v_vector_2;
    return;
    Exception
      When NULL_GEOMETRY Then
         raise_application_error(c_i_null_geometry,c_s_null_geometry,TRUE);
  End FindSplitVector;

  /* @history    : Simon Greener - Dec 2009 - Fixed SRID handling bug for Geodetic data.
  */
  Procedure ST_Split( p_geometry  in mdsys.sdo_geometry,
                      p_point     in mdsys.sdo_geometry,
                      p_tolerance in number default 0.005,
                      p_out_geom1 out nocopy mdsys.sdo_geometry,
                      p_out_geom2 out nocopy mdsys.sdo_geometry,
                      p_snap      in pls_integer default 0,
                      p_unit      in varchar2 default null,
                      p_exception in pls_integer default 0)
  As
    v_gtype            pls_integer;
    V_Dims             Pls_Integer;
    V_Part             Number;
    V_Element          Number;
    V_Num_Elements     Number;
    V_Vector_Id        Number;
    V_Geometry         Mdsys.Sdo_Geometry;
    V_Extract_Geom     Mdsys.Sdo_Geometry;
    V_Geom_Part        Mdsys.Sdo_Geometry;
    V_Min_Dist         Number;
    V_Dist             Number;
    v_round_factor Number;
    V_Vector_1         &&defaultSchema..T_Vector := &&defaultSchema..T_Vector(0,&&defaultSchema..T_Vertex(C_Minval,C_Minval,C_Minval,C_Minval,1),
                                                      &&defaultSchema..T_Vertex(C_Minval,C_Minval,C_Minval,C_Minval,1));
    V_Vector_2         &&defaultSchema..T_Vector := &&defaultSchema..T_Vector(0,&&defaultSchema..T_Vertex(C_Minval,C_Minval,C_Minval,C_Minval,2),
                                                      &&defaultSchema..T_Vertex(C_Minval,C_Minval,C_Minval,C_Minval,2));

    Null_Geometry      Exception;
    Not_A_Line         Exception;
    Not_A_Point        Exception;
    NULL_TOLERANCE     EXCEPTION;

    CURSOR c_vectors(p_geometry in mdsys.sdo_geometry)
    IS
    SELECT rownum as id,
           b.startcoord.x as x1,
           b.startcoord.y as y1,
           b.startcoord.z as z1,
           b.startcoord.w as w1,
           b.endcoord.x as x2,
           b.endcoord.y as y2,
           b.endcoord.z as z2,
           b.endcoord.w as w2
      FROM TABLE(&&defaultSchema..LINEAR.ST_Vectorize(p_geometry)) b;

  BEGIN
    -- Check inputs
    If ( p_point is NULL or p_geometry is NULL ) Then
       if ( p_exception is null or p_exception = 1) then
          raise NULL_GEOMETRY;
       Else
          return;
       End If;
    End If;
    v_gtype := MOD(p_geometry.Sdo_GType,10);
    If ( v_gtype not in (2,6) ) Then
       if ( p_exception is null or p_exception = 1) then
          raise NOT_A_LINE;
       Else
          return;
       End If;
    End If;
    v_gtype := MOD(p_point.Sdo_GType,10);
    If ( MOD(p_point.Sdo_Gtype,10) <> 1 ) Then
       if ( p_exception is null or p_exception = 1) then
          raise NOT_A_POINT;
       Else
          return;
       End If;
    End If;
    if ( p_tolerance is null ) Then
       if ( p_exception is null or p_exception = 1) then
          raise NULL_TOLERANCE;
       Else
          return;
       End If;
    End If;

    -- Compute rounding factors
    v_round_factor := round(log(10,(1/p_tolerance)/2));

    -- Check number of elements in input line
    v_num_elements := mdsys.sdo_util.GetNumElem(p_geometry);
    If ( v_num_elements = 1 ) Then
       v_geometry := p_geometry;
       v_part     := 1;
    Else
       v_min_dist := 999999999999.99999999;  -- All distances should be less than this
       <<for_all_vertices>>
       FOR v_element IN 1..v_num_elements LOOP
         v_extract_geom := mdsys.sdo_util.Extract(p_geometry,v_element);   -- Extract element with all sub-elements
         v_dist := LINEAR.sdo_distance(v_extract_geom,p_point,p_tolerance,p_unit);
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
    FindSplitVector( v_geometry,
                     p_point,
                     v_vector_1,
                     v_vector_2,
                     v_vector_id,
                     v_extract_geom,
                     p_snap,
                     p_tolerance,
                     p_unit,
                     p_exception);
     If ( p_snap = 1 ) Then
        p_out_geom1 := v_extract_geom;
        return;
     End If;
     -- dbms_output.put_line(case when v_vector_1 is null then 'v_vector_1 is NULL' else 'v_vector_1 is not null' end );
     -- dbms_output.put_line(case when v_vector_2 is null then 'v_vector_2 is NULL' else 'v_vector_2 is not null' end );

    -- Construct the output geometries
    -- Add elements in multi-part geometry to first output line
    -- dbms_output.put_line('v_part = ' || v_part);
    FOR v_element IN 1..(v_part-1) LOOP
      -- dbms_output.put_line('Adding element || ' || v_element || ' to out line 1');
      v_extract_geom := mdsys.sdo_util.Extract(p_geometry,v_element);   -- Extract element with all sub-elements
      p_out_geom1    := mdsys.sdo_util.concat_lines(p_out_geom1,v_extract_geom);
    END LOOP;
    -- dbms_output.put_line(case when p_out_geom1 is null then 'p_out_geom1 is NULL' else 'p_out_geom1 is not null' end );

    -- Now add the vertexes of the split geometry (in v_geometry) to the output lines
    FOR rec IN c_vectors(v_geometry) LOOP
      -- dbms_output.put_line(rec.id || ' < ' || v_vector_id);
      If ( rec.id < v_vector_id ) Then
        -- dbms_output.put_line('Add to first part');
        if ( rec.id = 1 ) Then
          -- dbms_output.put_line('rec.id = 1 - Creating output line1 geometry');
          v_geom_part := mdsys.sdo_geometry(2002,p_geometry.sdo_srid,NULL,
                                            mdsys.sdo_elem_info_array(1,2,1),
                                            mdsys.sdo_ordinate_array(
                                                ROUND(rec.x1,v_round_factor),
                                                ROUND(rec.y1,v_round_factor),
                                                ROUND(rec.x2,v_round_factor),
                                                ROUND(rec.y2,v_round_factor)));
        Else
          -- dbms_output.put_line('mdsys.sdo_util.Append vector to output line1 geometry');
          v_geom_part := mdsys.sdo_util.concat_lines(v_geom_part,
                                                   mdsys.sdo_geometry(2002,p_geometry.sdo_srid,NULL,
                                                         mdsys.sdo_elem_info_array(1,2,1),
                                                         mdsys.sdo_ordinate_array(
                                                              ROUND(rec.x1,v_round_factor),
                                                              ROUND(rec.y1,v_round_factor),
                                                              ROUND(rec.x2,v_round_factor),
                                                              ROUND(rec.y2,v_round_factor))));
        End If;
      ElsIf ( rec.id = v_vector_id ) Then
        -- dbms_output.put_line('rec.id = v_vector_id');
        If ( v_vector_1 is not NULL ) Then
           -- dbms_output.put_line('v_vector_1 is not null');
           if ( v_geom_part is null ) Then
              -- dbms_output.put_line('v_geom_art is null - Creating');
              v_geom_part := mdsys.sdo_geometry(2002,p_geometry.sdo_srid,NULL,
                                                mdsys.sdo_elem_info_array(1,2,1),
                                                mdsys.sdo_ordinate_array(v_vector_1.startcoord.x,v_vector_1.startcoord.y,
                                                                         v_vector_1.endcoord.x,  v_vector_1.endcoord.y));
           Else
              v_geom_part := mdsys.sdo_util.concat_lines(v_geom_part,
                                   mdsys.sdo_geometry(2002,p_geometry.sdo_srid,NULL,
                                         mdsys.sdo_elem_info_array(1,2,1),
                                         mdsys.sdo_ordinate_array(v_vector_1.startcoord.x,v_vector_1.startcoord.y,
                                                                  v_vector_1.endcoord.x,  v_vector_1.endcoord.y)));
           End If;
        End If;
        -- dbms_output.put_line('Finished building v_geom_part: ' || case when v_geom_part is null then 'v_geom_part is NULL' else 'v_geom_part is not null' end );
        p_out_geom1 := case when p_out_geom1 is null then v_geom_part else mdsys.sdo_util.concat_lines(p_out_geom1,v_geom_part) end;
        -- dbms_output.put_line('Finished building p_out_geom1: ' || case when p_out_geom1 is null then 'p_out_geom1 is NULL' else 'p_out_geom1 is not null' end );

        p_out_geom2 := NULL;
        If ( v_vector_2 is not NULL ) Then
           -- dbms_output.put_line(' Add v_vector_2 to p_out_geom2 ready to collect up remaining vectors and elements into output line 2');
           p_out_geom2 := mdsys.sdo_geometry(2002,p_geometry.sdo_srid,NULL,
                                mdsys.sdo_elem_info_array(1,2,1),
                                mdsys.sdo_ordinate_array(v_vector_2.startcoord.x,v_vector_2.startcoord.y,
                                                         v_vector_2.endcoord.x,v_vector_2.endcoord.y));
        End If;
      Else
        -- dbms_output.put_line(' Add any remaining vectors to v_geom_part');
        if ( p_out_geom2 is null ) Then
           p_out_geom2 := mdsys.sdo_geometry(2002,p_geometry.sdo_srid,NULL,
                                             mdsys.sdo_elem_info_array(1,2,1),
                                             mdsys.sdo_ordinate_array(ROUND(rec.x1,v_round_factor),
                                                                      ROUND(rec.y1,v_round_factor),
                                                                      ROUND(rec.x2,v_round_factor),
                                                                      ROUND(rec.y2,v_round_factor)));
        Else
           p_out_geom2 := mdsys.sdo_util.concat_lines(p_out_geom2,
                                                      mdsys.sdo_geometry(2002,p_geometry.sdo_srid,NULL,
                                                            mdsys.sdo_elem_info_array(1,2,1),
                                                            mdsys.sdo_ordinate_array(ROUND(rec.x1,v_round_factor),
                                                                                     ROUND(rec.y1,v_round_factor),
                                                                                     ROUND(rec.x2,v_round_factor),
                                                                                     ROUND(rec.y2,v_round_factor))));
        End If;
      End If;
    END LOOP;

    -- Now mdsys.sdo_util.Append any remaining elements in p_geometry to p_out_geom2
    FOR v_element IN (v_part+1)..v_num_elements LOOP
      -- dbms_output.put_line('Adding element || ' || v_element || ' to out line 2');
      v_extract_geom := mdsys.sdo_util.Extract(p_geometry,v_element);   -- Extract element with all sub-elements
      p_out_geom2    := case when p_out_geom2 is null then v_extract_geom else mdsys.sdo_util.concat_lines(p_out_geom2,v_extract_geom) end;
    END LOOP;

    Exception
      When Null_Geometry Then
         raise_application_error(c_i_null_geometry,c_s_null_geometry,TRUE);
      When Not_A_Line Then
         raise_application_error(c_i_not_line,c_s_not_line || ' ' || v_gtype,TRUE);
      When NOT_A_POINT Then
         raise_application_error(c_i_not_point,c_s_not_point || ' ' || v_gtype,TRUE);
      When NULL_TOLERANCE Then
         raise_application_error(c_i_null_tolerance,c_s_null_tolerance,TRUE);
  end ST_Split;

  Function ST_Split(p_geometry  in mdsys.sdo_geometry,
                    p_point     in mdsys.sdo_geometry,
                    p_tolerance in number      default 0.005,
                    p_unit      in varchar2    default null,
                    p_exception in pls_integer default 0)
    Return &&defaultSchema..LINEAR.t_Geometries pipelined
  AS
    v_out_line1 mdsys.sdo_geometry;
    v_out_line2 mdsys.sdo_geometry;
  Begin
    &&defaultSchema..LINEAR.ST_Split( p_geometry,
                  p_point,
                  p_tolerance,
                  v_out_line1,
                  v_out_line2,
                  0 /* no point snapping */,
                  p_unit,
                  p_exception);
    PIPE ROW (&&defaultSchema..T_Geometry(v_out_line1));
    PIPE ROW (&&defaultSchema..T_Geometry(v_out_line2));
    Return;
  End ST_Split;

  /**
  * Snap Point to Line
  */
  Function ST_Snap( p_geometry  in mdsys.sdo_geometry,
                    p_point     in mdsys.sdo_geometry,
                    p_tolerance in number      default 0.005,
                    p_unit      in varchar2    default null,
                    p_exception in pls_integer default 0)
    Return mdsys.sdo_geometry
  As
    v_out_point mdsys.sdo_geometry;
    v_out_line  mdsys.sdo_geometry;
  Begin
    -- Split with snap option to snap point to line and return point
    &&defaultSchema..LINEAR.ST_Split(p_geometry,
                      p_point,
                      p_tolerance,
                      v_out_point,
                      v_out_line,
                      1, /* point snapping */
                      p_unit, 
                      p_exception);
    RETURN v_out_point;
  End ST_Snap;

  Function ST_Clip(p_geometry  in mdsys.sdo_geometry,
                   p_point1    in mdsys.sdo_geometry,
                   p_point2    in mdsys.sdo_geometry,
                   p_tolerance in number      default 0.005,
                   p_unit      in varchar2    default null,
                   p_exception in pls_integer default 0)
    Return MDSYS.SDO_GEOMETRY
  AS
    v_gtype          PLS_INTEGER;
    v_point1         mdsys.sdo_geometry := p_point1;
    v_point2         mdsys.sdo_geometry := p_point2;
    v_line1          mdsys.sdo_geometry;
    v_line2          mdsys.sdo_geometry;
    v_clip_geom      mdsys.sdo_geometry;
    NULL_GEOMETRY    EXCEPTION;
    NOT_A_LINE       EXCEPTION;
    NOT_A_POINT      EXCEPTION;
    NULL_TOLERANCE   EXCEPTION;
    POINTS_THE_SAME  EXCEPTION;
    NOT_SDO_POINT    EXCEPTION;
    CLIP_FAILED      EXCEPTION;
  BEGIN
    -- Check inputs
    If ( p_geometry is NULL
        OR
        p_point1 is NULL
        OR
        p_point2 is NULL) Then
       if ( p_exception is null or p_exception = 1) then
          raise NULL_GEOMETRY;
       Else
          return p_geometry;
       End If;
    End If;
    v_gtype := p_geometry.Get_GType();
    If ( v_gtype not in (2,6) ) Then
       if ( p_exception is null or p_exception = 1) then
          raise NOT_A_LINE;
       Else
          return p_geometry;
       End If;
    End If;
    v_gtype := p_point1.Get_GType();
    If ( v_gtype <> 1 ) Then
       if ( p_exception is null or p_exception = 1) then
          raise NOT_A_POINT;
       Else
          return p_geometry;
       End If;
    End If;
    v_gtype := p_point2.Get_GType();
    If ( v_gtype <> 1 ) Then
       if ( p_exception is null or p_exception = 1) then
          raise NOT_A_POINT;
       Else
          return p_geometry;
       End If;
    End If;
    if ( p_tolerance is null ) Then
       if ( p_exception is null or p_exception = 1) then
          raise NULL_TOLERANCE;
       Else
          return p_geometry;
       End If;
    End If;

    -- Points may not be the same
    --
    If ( mdsys.sdo_geom.relate(p_point1,'EQUAL',p_point2,p_tolerance) = 'TRUE' ) Then
       If ( p_exception is null or p_exception = 1) then
          raise POINTS_THE_SAME;
       Else
          return p_geometry;
       End If;
    End If;
    -- Points must be encoded in SDO_POINT_TYPE
    --
    If ( p_point1.sdo_point is null
         OR
         p_point2.sdo_point is null ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NOT_SDO_POINT;
       Else
          return p_geometry;
       End If;
    End If;
    -- Points must be on the line for later line/point testing
    --
    If ( mdsys.sdo_geom.relate(p_point1,'DETERMINE',p_point2,p_tolerance) = 'DISJOINT' ) Then
       v_point1 := &&defaultSchema..LINEAR.ST_Snap( p_geometry, p_point1, p_tolerance, p_unit );
    End If;
    If ( mdsys.sdo_geom.relate(p_point1,'DETERMINE',p_point2,p_tolerance) = 'DISJOINT' ) Then
       v_point2 := &&defaultSchema..LINEAR.ST_Snap( p_geometry, p_point2, p_tolerance, p_unit );
    End If;

    -- Do Split once
    &&defaultSchema..LINEAR.ST_Split( p_geometry, v_point1, p_tolerance, v_line1, v_line2, 0, p_unit );
    If ( v_line1 is null and v_line2 is null ) Then
       If ( p_exception is null or p_exception = 1) then
          raise CLIP_FAILED;
       Else
          return p_geometry;
       End If;
    End If;
    If ( v_line1 is not null ) Then
        -- Check to see if this is the line to be split again by v_point2
        --
        If ( mdsys.sdo_geom.relate(v_line1,'ANYINTERACT',v_point2,p_tolerance) = 'TRUE' ) Then
            v_clip_geom := v_line1;
        End If;
    End If;
    If ( v_clip_geom is null And v_line2 is not null ) Then
        -- Check to see if this is the line to be split again by v_point2
        --
        If ( mdsys.sdo_geom.relate(v_line2,'ANYINTERACT',v_point2,p_tolerance) = 'TRUE' ) Then
            v_clip_geom := v_line2;
        End If;
    End If;
    If ( v_clip_geom is null ) Then
       If ( p_exception is null or p_exception = 1) then
          raise CLIP_FAILED;
       Else
          return p_geometry;
       End If;
    End If;
    -- Split one last time
    &&defaultSchema..LINEAR.ST_Split( p_geometry  => v_clip_geom,
                             p_point     => v_point2,
                             p_tolerance => p_tolerance,
                             p_out_geom1 => v_line1,
                             p_out_geom2 => v_line2,
                             p_snap      => 0,
                             p_unit      => p_unit,
                             p_exception => 0);
    -- Chose line that has relationship with v_point2 and v_point1
    --
    If ( v_line1 is not null ) Then
        if ( mdsys.sdo_geom.relate(v_line1,'DETERMINE',v_point1,p_tolerance) <> 'DISJOINT'
             AND
             mdsys.sdo_geom.relate(v_line1,'DETERMINE',v_point2,p_tolerance) <> 'DISJOINT' ) Then
            return v_line1;
	End If;
    End If;
    If ( v_line2 is not null ) Then
        if ( mdsys.sdo_geom.relate(v_line2,'DETERMINE',v_point1,p_tolerance) <> 'DISJOINT'
             AND
             mdsys.sdo_geom.relate(v_line2,'DETERMINE',v_point2,p_tolerance) <> 'DISJOINT' ) Then
            return v_line2;
	End If;
    End If;
    RETURN NULL;
    Exception
      When NULL_GEOMETRY Then
         raise_application_error(c_i_null_geometry,c_s_null_geometry,TRUE);
      When NOT_A_LINE Then
         raise_application_error(c_i_not_line,c_s_not_line || ' ' || v_gtype,TRUE);
      When NOT_A_POINT Then
         raise_application_error(c_i_not_point,c_s_not_point || ' ' || v_gtype,TRUE);
      When NULL_TOLERANCE Then
         raise_application_error(c_i_null_tolerance,c_s_null_tolerance,TRUE);
      When POINTS_THE_SAME Then
         raise_application_error(c_i_points_cannot_be_equal,c_s_points_cannot_be_equal,TRUE);
      When NOT_SDO_POINT Then
         raise_application_error(c_i_point_not_sdo_point,c_s_point_not_sdo_point,TRUE);
      When CLIP_FAILED Then
         raise_application_error(c_i_split_failed,c_s_split_failed,TRUE);
  END ST_Clip;

  Function ST_Clip( p_geometry    IN mdsys.sdo_geometry,
                    p_start_value IN NUMBER,
                    P_End_Value   In Number,
                    p_value_Type  In Varchar2    Default 'L', -- or 'M'
                    p_tolerance   IN NUMBER      DEFAULT 0.005,
                    p_unit        in varchar2    default null,
                    p_exception   IN PLS_INTEGER DEFAULT 0 )
    Return mdsys.sdo_geometry
  As
    v_value_type        varchar2(1) := SUBSTR(UPPER(NVL(p_value_type,'L')),1,1);
    v_dims              pls_integer;
    v_gtype             pls_integer;
    v_measured          boolean;
    v_measure           number := 0.0;
    v_round_factor      pls_integer;
    v_start_value       number := p_start_value;
    v_end_value         number := p_end_value;
    v_return_line       mdsys.sdo_geometry;
    NULL_GEOMETRY       EXCEPTION;
    START_NEGATIVE      EXCEPTION;
    END_NEGATIVE        EXCEPTION;
    START_NOT_ONLINE    EXCEPTION;
    END_NOT_ONLINE      EXCEPTION;
    NOT_A_LINE          EXCEPTION;
    NULL_TOLERANCE      EXCEPTION;
    NO_MEASURE          EXCEPTION;
    VALUE_TYPE          EXCEPTION;
    
    Function Clip_distance(p_geometry     in mdsys.sdo_geometry,
                           p_round_factor in pls_integer,
                           p_start_value  in number,
                           p_end_value    in number)
    Return mdsys.sdo_geometry
    Is
        v_ratio             number;
        v_return_line       mdsys.sdo_geometry := NULL;
        v_vector_length     number := 0.0;
        v_cumulative_length number;
        v_vertices          mdsys.vertex_set_type;
        v_id                pls_integer;
        v_vertex            mdsys.vertex_type;
        v_element_no        pls_integer;
        v_num_elements      pls_integer;
        v_element           mdsys.sdo_geometry;
        v_skip              boolean;
    Begin
        v_cumulative_length := 0.0;
        v_num_elements      := mdsys.sdo_util.GetNumElem(p_geometry);
        <<for_all_elements>>
        FOR v_element_no IN 1..v_num_elements LOOP
           v_element  := mdsys.sdo_util.Extract(p_geometry,v_element_no,0);   -- Extract element with all sub-elements
           v_vertices := mdsys.sdo_util.getVertices(v_element);
           <<for_all_vectors>>
           FOR v_id in v_vertices.FIRST..(v_vertices.LAST-1) LOOP
               v_skip := false;
               -- Compute vector length
               v_vector_length := LINEAR.sdo_distance(
                                      mdsys.sdo_geometry(2001,p_geometry.sdo_srid,
                                                         mdsys.sdo_point_type(v_vertices(v_id).x,
                                                                              v_vertices(v_id).y,
                                                                              v_vertices(v_id).z),
                                                         NULL,NULL),
                                      mdsys.sdo_geometry(2001,p_geometry.sdo_srid,
                                                         mdsys.sdo_point_type(v_vertices(v_id+1).x,
                                                                              v_vertices(v_id+1).y,
                                                                              v_vertices(v_id+1).z),
                                                         NULL,NULL),
                                                p_tolerance,p_unit);
               -- Is start measure at start or end of this vector?
               If ( v_return_line is null ) Then
                  If ( round(p_start_value,p_round_factor) = round(v_cumulative_length,p_round_factor) ) Then
                     -- Add to returned line
                     v_return_line := mdsys.sdo_geometry(p_geometry.sdo_gtype,
                                                         p_geometry.sdo_srid,
                                                         null,
                                                         mdsys.sdo_elem_info_array(1,2,1),
                                                         case when v_dims = 4
                                                              then mdsys.sdo_ordinate_array(
                                                                          round(v_vertices(v_id).x,p_round_factor),
                                                                          round(v_vertices(v_id).y,p_round_factor),
                                                                          v_vertices(v_id).z,
                                                                          v_vertices(v_id).w)
                                                              when v_dims = 3
                                                              then mdsys.sdo_ordinate_array(
                                                                          round(v_vertices(v_id).x,p_round_factor),
                                                                          round(v_vertices(v_id).y,p_round_factor),
                                                                          v_vertices(v_id).z)
                                                              else mdsys.sdo_ordinate_array(
                                                                          round(v_vertices(v_id).x,p_round_factor),
                                                                          round(v_vertices(v_id).y,p_round_factor))
                                                           end);
                  ElsIf ( round(p_start_value,p_round_factor) = round(v_cumulative_length + v_vector_length,p_round_factor) ) Then
                     -- Add first point to returned line only if line doesn't exist
                     v_return_line := mdsys.sdo_geometry(p_geometry.sdo_gtype,
                                                         p_geometry.sdo_srid,
                                                         null,
                                                         mdsys.sdo_elem_info_array(1,2,1),
                                                         case when v_dims = 4
                                                              then mdsys.sdo_ordinate_array(
                                                                          round(v_vertices(v_id+1).x,p_round_factor),
                                                                          round(v_vertices(v_id+1).y,p_round_factor),
                                                                          v_vertices(v_id+1).z,
                                                                          v_vertices(v_id+1).w)
                                                              when v_dims = 3
                                                              then mdsys.sdo_ordinate_array(
                                                                          round(v_vertices(v_id+1).x,p_round_factor),
                                                                          round(v_vertices(v_id+1).y,p_round_factor),
                                                                          v_vertices(v_id+1).z)
                                                              else mdsys.sdo_ordinate_array(
                                                                          round(v_vertices(v_id+1).x,p_round_factor),
                                                                          round(v_vertices(v_id+1).y,p_round_factor))
                                                           end);
                     -- no need to continue processing this vector
                     v_skip := true;
                  -- Is in between?
                  ElsIf ( round(p_start_value,p_round_factor) BETWEEN round(v_cumulative_length,p_round_factor)
                                                                  AND round(v_cumulative_length + v_vector_length,p_round_factor) ) Then
                     -- calculate new position (measure - cumulative) / vector_length
                     v_ratio := (p_start_value - v_cumulative_length) / v_vector_length;
                     v_return_line := mdsys.sdo_geometry(p_geometry.sdo_gtype,
                                                         p_geometry.sdo_srid,
                                                         null,
                                                         mdsys.sdo_elem_info_array(1,2,1),
                                                         case when v_dims = 4
                                                              then mdsys.sdo_ordinate_array(
                                                                    round(v_vertices(v_id).x+(v_ratio*(v_vertices(v_id+1).x-v_vertices(v_id).x)),p_round_factor),
                                                                    round(v_vertices(v_id).y+(v_ratio*(v_vertices(v_id+1).y-v_vertices(v_id).y)),p_round_factor),
                                                                    (v_vertices(v_id).z+v_vertices(v_id+1).z)/2.0,
                                                                    (v_vertices(v_id).w+v_vertices(v_id+1).w)/2.0)
                                                              when v_dims = 3
                                                              then mdsys.sdo_ordinate_array(
                                                                    round(v_vertices(v_id).x+(v_ratio*(v_vertices(v_id+1).x-v_vertices(v_id).x)),p_round_factor),
                                                                    round(v_vertices(v_id).y+(v_ratio*(v_vertices(v_id+1).y-v_vertices(v_id).y)),p_round_factor),
                                                                    (v_vertices(v_id).z+v_vertices(v_id+1).z)/2.0)
                                                              else mdsys.sdo_ordinate_array(
                                                                    round(v_vertices(v_id).x+(v_ratio*(v_vertices(v_id+1).x-v_vertices(v_id).x)),p_round_factor),
                                                                    round(v_vertices(v_id).y+(v_ratio*(v_vertices(v_id+1).y-v_vertices(v_id).y)),p_round_factor))
                                                           end);
                  End If;
               End If;
    
               -- If start not in this vector skip it.
               If ( v_return_line is not null and not v_skip ) Then
                   -- Now process end measure
                   -- End measure can't be at the start of the vector or before the start measure stored in the line
                   -- If end value = end of this vector then return
                   --
                   -- DEBUG dbms_output.put_line('testing ' || p_end_value || ' between ' || round(v_cumulative_length,p_round_factor) || ' AND ' || round(v_cumulative_length + v_vector_length,p_round_factor));
                   if ( round(p_end_value,p_round_factor) BETWEEN round(v_cumulative_length,p_round_factor)
                                                              AND round(v_cumulative_length + v_vector_length,p_round_factor) ) then
                      -- DEBUG dbms_output.put_line(p_end_value || ' being added to output geometry');
                      -- calculate new position (measure - cumulative) / vector_length
                      v_ratio := (p_end_value - v_cumulative_length) / v_vector_length;
                      -- DEBUG dbms_output.put_line('Ratio is ' || v_ratio || ' Calculated point is ' || round(v_vertices(v_id).x+(v_ratio*(v_vertices(v_id+1).x-v_vertices(v_id).x)),p_round_factor) || ',' ||round(v_vertices(v_id).y+(v_ratio*(v_vertices(v_id+1).y-v_vertices(v_id).y)),p_round_factor));
                      ADD_Coordinate( v_return_line.sdo_ordinates,
                                      v_dims,
                                      round(v_vertices(v_id).x+(v_ratio*(v_vertices(v_id+1).x-v_vertices(v_id).x)),p_round_factor),
                                      round(v_vertices(v_id).y+(v_ratio*(v_vertices(v_id+1).y-v_vertices(v_id).y)),p_round_factor),
                                      case when v_vertices(v_id).z is not null then (v_vertices(v_id).z+v_vertices(v_id+1).z)/2.0 else null end,
                                      case when v_vertices(v_id).w is not null then (v_vertices(v_id).w+v_vertices(v_id+1).w)/2.0 else null end,
                                      ST_getMeasureDimension(p_geometry.sdo_gtype));
                      -- All finished
                      return v_return_line;
                   Else
                      -- DEBUG dbms_output.put_line('Adding vector end to ordinate array ' || round(v_vertices(v_id+1).x,p_round_factor) || ',' || round(v_vertices(v_id+1).y,p_round_factor));
                      -- Add in end vertex
                      ADD_Coordinate( v_return_line.sdo_ordinates,
                                      v_dims,
                                      round(v_vertices(v_id+1).x,p_round_factor),
                                      round(v_vertices(v_id+1).y,p_round_factor),
                                      v_vertices(v_id+1).z,
                                      v_vertices(v_id+1).w,
                                      ST_getMeasureDimension(p_geometry.sdo_gtype));
                   End If;
               End If;
               -- Update cumulative length to include this vector
               v_cumulative_length := v_cumulative_length + v_vector_length;
           END LOOP for_all_vectors;
        END LOOP for_all_elements;
        return v_return_line;
    End Clip_distance;

    Function Clip_Measure(p_geometry     in mdsys.sdo_geometry,
                          p_round_factor in pls_integer,
                          p_start_value  in number,
                          p_end_value    in number)
    Return mdsys.sdo_geometry
    Is
        v_ratio             number;
        v_return_line       mdsys.sdo_geometry := mdsys.sdo_geometry(p_geometry.sdo_gtype,
                                                                     p_geometry.sdo_srid,
                                                                     null,
                                                                     mdsys.sdo_elem_info_array(1,2,1),
                                                                     mdsys.sdo_ordinate_array(0));

        v_vertices          mdsys.vertex_set_type;
        v_id                pls_integer;
        v_vertex            mdsys.vertex_type;
        v_element_no        pls_integer;
        v_num_elements      pls_integer;
        v_element           mdsys.sdo_geometry;
        v_point_gtype       pls_integer;
        v_dims              pls_integer;
        v_measure_dim       pls_integer;
        v_measure_1         number;
        v_measure_2         number;
        v_ord               pls_integer := 0;

    Begin
        v_return_line.sdo_ordinates.DELETE;
        v_dims              := p_geometry.get_dims();
        v_point_gtype       := case when v_dims >= 3 then 3001 else 2001 end;
        v_measure_dim       := ST_getMeasureDimension(p_geometry.sdo_gtype);
        v_num_elements      := mdsys.sdo_util.GetNumElem(p_geometry);
        <<for_all_elements>>
        FOR v_element_no IN 1..v_num_elements LOOP
           v_element  := mdsys.sdo_util.Extract(p_geometry,v_element_no,0);   -- Extract element with all sub-elements
           v_vertices := mdsys.sdo_util.getVertices(v_element);
           <<for_all_vectors>>
           FOR v_id in v_vertices.FIRST..(v_vertices.LAST-1) LOOP
               v_measure_1 := case v_measure_dim
                                   when 3 then v_vertices(v_id).z
                                   when 4 then v_vertices(v_id).w
                                   else v_vertices(v_id).z
                               end;
               v_measure_2 := case v_measure_dim
                                   when 3 then v_vertices(v_id+1).z
                                   when 4 then v_vertices(v_id+1).w
                                   else v_vertices(v_id).z
                               end;
               -- Is start measure at start or end of this vector?
               --
               If ( v_return_line.sdo_ordinates.COUNT = 0 ) Then
                  -- If start....
                  --
                  If ( round(p_start_value,p_round_factor) = v_measure_1 ) Then
                     -- Simply add starting vertex to returned line
                     --
                     v_return_line.sdo_ordinates.EXTEND(v_dims);
                     v_ord := v_ord + 1;v_return_line.sdo_ordinates(v_ord) := round(v_vertices(v_id).x,p_round_factor);
                     v_ord := v_ord + 1;v_return_line.sdo_ordinates(v_ord) := round(v_vertices(v_id).y,p_round_factor);
                     IF ( v_dims = 3 ) THEN
                        v_ord := v_ord + 1;v_return_line.sdo_ordinates(v_ord) := v_vertices(v_id).z;
                     END IF;
                     IF ( v_dims = 4 ) THEN 
                        v_ord := v_ord + 1;v_return_line.sdo_ordinates(v_ord) := v_vertices(v_id).w;
                     END IF;
                  -- Start value equals end of current vector/segment
                  --
                  ElsIf ( round(p_start_value,p_round_factor) = v_measure_2 ) Then
                     -- Add Second point to returned line 
                     v_return_line.sdo_ordinates.EXTEND(v_dims);
                     v_ord := v_ord + 1; v_return_line.sdo_ordinates(v_ord) := round(v_vertices(v_id).x,p_round_factor);
                     v_ord := v_ord + 1; v_return_line.sdo_ordinates(v_ord) := round(v_vertices(v_id).y,p_round_factor);
                     IF ( v_dims = 3 ) THEN
                        v_ord := v_ord + 1; v_return_line.sdo_ordinates(v_ord) := v_vertices(v_id).z;
                     END IF;
                     IF ( v_dims = 4 ) THEN 
                        v_ord := v_ord + 1; v_return_line.sdo_ordinates(v_ord) := v_vertices(v_id).w;
                     END IF;
                  -- Is in between?
                  ElsIf ( round(p_start_value,p_round_factor) BETWEEN v_measure_1 AND v_measure_2 ) Then
                     -- calculate new position (measure - cumulative) / vector_length
                     v_ratio := (p_start_value - v_measure_1) / (v_measure_2 - v_measure_1);
                     v_return_line.sdo_ordinates.EXTEND(v_dims);
                     v_ord := v_ord + 1; v_return_line.sdo_ordinates(v_ord) := round(v_vertices(v_id).x+(v_ratio*(v_vertices(v_id+1).x-v_vertices(v_id).x)),p_round_factor);
                     v_ord := v_ord + 1; v_return_line.sdo_ordinates(v_ord) := round(v_vertices(v_id).y+(v_ratio*(v_vertices(v_id+1).y-v_vertices(v_id).y)),p_round_factor);
                     IF ( v_dims = 3 ) THEN
                        v_ord := v_ord + 1; v_return_line.sdo_ordinates(v_ord) := round(v_vertices(v_id).z+(v_ratio*(v_vertices(v_id+1).z-v_vertices(v_id).z)),p_round_factor);
                     END IF;
                     IF ( v_dims = 4 ) THEN 
                        v_ord := v_ord + 1; v_return_line.sdo_ordinates(v_ord) := round(v_vertices(v_id).w+(v_ratio*(v_vertices(v_id+1).w-v_vertices(v_id).w)),p_round_factor);
                     END IF;
                  End If;
               End If;
    
               -- Check end measure and this vector...
               -- End measure can't be at the start of the vector or before the start measure stored in the line
               -- If end value = end of this vector then return
               --
               If ( v_return_line.sdo_ordinates.COUNT > 0 ) Then
                  if ( round(p_end_value,p_round_factor) BETWEEN v_measure_1 AND v_measure_2 ) then
                      -- calculate new position (measure - cumulative) / vector_length
                      v_ratio := (p_end_value - v_measure_1) / (v_measure_2 - v_measure_1);
                     v_return_line.sdo_ordinates.EXTEND(v_dims);
                     v_ord := v_ord + 1; v_return_line.sdo_ordinates(v_ord) := round(v_vertices(v_id).x+(v_ratio*(v_vertices(v_id+1).x-v_vertices(v_id).x)),p_round_factor);
                     v_ord := v_ord + 1; v_return_line.sdo_ordinates(v_ord) := round(v_vertices(v_id).y+(v_ratio*(v_vertices(v_id+1).y-v_vertices(v_id).y)),p_round_factor);
                     IF ( v_dims = 3 ) THEN
                        v_ord := v_ord + 1; v_return_line.sdo_ordinates(v_ord) := v_vertices(v_id).z+(v_ratio*(v_vertices(v_id+1).z-v_vertices(v_id).z));
                     END IF;
                     IF ( v_dims = 4 ) THEN 
                        v_ord := v_ord + 1; v_return_line.sdo_ordinates(v_ord) := v_vertices(v_id).w+(v_ratio*(v_vertices(v_id+1).w-v_vertices(v_id).w));
                     END IF;
                      -- All finished
                      return v_return_line;
                   Else
                      -- Add in end vertex
                     v_return_line.sdo_ordinates.EXTEND(v_dims);
                     v_ord := v_ord + 1; v_return_line.sdo_ordinates(v_ord) := round(v_vertices(v_id+1).x,p_round_factor);
                     v_ord := v_ord + 1; v_return_line.sdo_ordinates(v_ord) := round(v_vertices(v_id+1).y,p_round_factor);
                     IF ( v_dims = 3 ) THEN
                        v_ord := v_ord + 1; v_return_line.sdo_ordinates(v_ord) := v_vertices(v_id+1).z;
                     END IF;
                     IF ( v_dims = 4 ) THEN 
                        v_ord := v_ord + 1; v_return_line.sdo_ordinates(v_ord) := v_vertices(v_id+1).w;
                     END IF;
                   End If;
               End If;
           END LOOP for_all_vectors;
        END LOOP for_all_elements;
        return v_return_line;
    End Clip_Measure;
    
  Begin
    If ( p_geometry is null ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NULL_GEOMETRY;
       Else
          return p_geometry;
       End If;
    End If;

    v_gtype := p_geometry.get_gtype();
    If ( v_gtype not in (2,6) ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NOT_A_LINE;
       Else
          return null;
       End If;
    End If;
    if ( v_value_Type not in ('L','M') ) Then
       RAISE VALUE_TYPE;
    End If;

    If ( v_start_value < 0) Then
       If ( p_exception is null or p_exception = 1) then
          raise START_NEGATIVE;
       Else
          return p_geometry;
       End If;
    End If;

    If ( v_end_value < 0) Then
       If ( p_exception is null or p_exception = 1) then
          raise END_NEGATIVE;
       Else
          return p_geometry;
       End If;
    End If;

    If ( v_start_value = v_end_value ) Then
       -- Return single point
       return &&defaultSchema..LINEAR.ST_Locate_Point(p_geometry,
                                             v_start_value,
                                             v_value_Type,
                                             p_tolerance,
                                             p_unit);
    End If;

    If ( v_start_value > v_end_value ) Then
       v_measure     := v_start_value;
       v_start_value := v_end_value;
       v_end_value   := v_measure;
       v_measure     := 0.0;
    End If;

    If ( p_tolerance is Null ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NULL_TOLERANCE;
       Else
          return null;
       End If;
    End If;

    v_dims     := p_geometry.Get_Dims();
    v_measured := case when ST_isMeasured(p_geometry.sdo_gtype)=0 then false else true end;

    if ( ( v_dims = 2 and v_value_type <> 'L' ) 
         OR
         ( ( NOT v_measured ) and v_value_type = 'M' ) ) Then
       RAISE NO_MEASURE;
    End If;

    v_round_factor      := round(log(10,(1/p_tolerance)/2));
    v_return_line       := null;
    If ( v_value_type = 'L' ) Then
      v_return_line := clip_distance(p_geometry,v_round_factor,v_start_value,v_end_value);
    Else
      v_return_line := clip_measure(p_geometry,v_round_factor,v_start_value,v_end_value);
    End If;
    return v_return_line;

    Exception
      When NULL_GEOMETRY THEN
         raise_application_error(c_i_null_geometry,c_s_null_geometry,TRUE);
      WHEN NOT_A_LINE THEN
         raise_application_error(c_i_not_line,c_s_not_line || ' ' || v_gtype,TRUE);
      WHEN NULL_TOLERANCE THEN
         raise_application_error(c_i_null_tolerance,c_s_null_tolerance,TRUE);
      WHEN START_NEGATIVE THEN
         raise_application_error(c_i_split_start_negative,c_s_split_start_negative,true);
      WHEN END_NEGATIVE THEN
         raise_application_error(c_i_split_end_negative,c_s_split_end_negative,true);
      WHEN START_NOT_ONLINE THEN
         raise_application_error(c_i_split_start_not_online,c_s_split_start_not_online,true);
      WHEN END_NOT_ONLINE THEN
         raise_application_error(c_i_split_end_not_online,c_s_split_end_not_online,true);
      WHEN NO_MEASURE THEN
         raise_application_error(c_i_not_measured,c_s_not_measured,true);
      WHEN VALUE_TYPE THEN
         raise_application_error(c_i_value_type,c_s_value_type,true);
  End ST_Clip;

  FUNCTION ST_Parallel(p_geometry   in mdsys.sdo_geometry,
                       p_distance   in number,
                       p_tolerance  in number,
                       p_curved     in number := 0,
                       p_unit       in varchar2 default null)
    RETURN mdsys.sdo_geometry
  AS
    v_part         mdsys.sdo_geometry;
    v_result       mdsys.sdo_geometry;
    v_round_factor number := case when p_tolerance is null
                                  then null
                                  else round(log(10,(1/p_tolerance)/2))
                              end;
    v_dims         pls_integer := case when NVL(p_geometry,NULL) is null then NULL
                                       else p_geometry.get_dims()
                                   end;

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

    Function Process_LineString(p_linestring in mdsys.sdo_geometry )
      Return mdsys.sdo_geometry
    Is
      bAcute               Boolean := False;
      bCurved              Boolean := ( 1 = p_curved );
      v_delta              T_vertex := T_vertex(null,null,null,null,NULL);
      v_prev_delta         T_vertex := T_vertex(null,null,null,null,NULL);
      v_adjusted_coord     T_vertex := T_vertex(null,null,null,null,NULL);
      v_int_1              T_vertex := T_vertex(null,null,null,null,NULL);
      v_int_coord T_vertex := T_vertex(null,null,null,null,NULL);
      v_int_2              T_vertex := T_vertex(null,null,null,null,NULL);
      v_prev_start         T_vertex := T_vertex(null,null,null,null,NULL);
      v_last_vertex        T_vertex := T_vertex(null,null,null,null,NULL);
      v_distance           number;
      v_angle              number;
      v_ratio              number;
      v_az                 number;
      v_dir                pls_integer;
      v_elem_info          mdsys.sdo_elem_info_array := new mdsys.sdo_elem_info_array();
      v_ordinates          mdsys.sdo_ordinate_array  := new mdsys.sdo_ordinate_array();

      Procedure appendElement(p_SDO_Elem_Info  in out nocopy mdsys.sdo_elem_info_array,
                              p_Offset         in number,
                              p_Etype          in number,
                              p_Interpretation in number )
        IS
      Begin
        p_SDO_Elem_Info.extend(3);
        p_SDO_Elem_Info(p_SDO_Elem_Info.count-2) := p_Offset;
        p_SDO_Elem_Info(p_SDO_Elem_Info.count-1) := p_Etype;
        p_SDO_Elem_Info(p_SDO_Elem_Info.count  ) := p_Interpretation;
      END appendElement;

      Procedure appendVertex(p_ordinates in out nocopy
                                            mdsys.sdo_ordinate_array,
                             p_vertex    in T_Vertex)
      Is
        v_ord pls_integer := 0;
      Begin
        If ( p_ordinates is null ) Then
          p_ordinates := new sdo_ordinate_array(0);
          p_ordinates.DELETE;
        End If;
        v_ord := p_ordinates.COUNT + 1;
        p_ordinates.EXTEND(v_dims);
        -- Insert first vertex 
        p_ordinates(v_ord)   := p_vertex.X;
        p_ordinates(v_ord+1) := p_vertex.Y;
        If (v_dims>=3) Then
           p_ordinates(v_ord+2) := p_vertex.z;
           if ( v_dims > 3 ) Then
               p_ordinates(v_ord+3) := p_vertex.w;
           End If;
        End If;
      End appendVertex;

    Begin
      <<process_each_vector>>
      FOR rec IN (SELECT o.startCoord, o.EndCoord, o.id as vector_id
                    FROM TABLE(&&defaultSchema..LINEAR.ST_Vectorize(p_linestring)) o ) 
      LOOP
        -- Compute base offset
        v_az   := Bearing(rec.startCoord.X,rec.startCoord.Y,rec.endCoord.X,rec.endCoord.Y);
        v_dir  := CASE WHEN v_az < c_PI THEN -1 ELSE 1 END;
        v_delta.x := ABS(COS(v_az)) * p_distance * v_dir;
        v_delta.y := ABS(SIN(v_az)) * p_distance * v_dir;
        IF  Not ( v_az > c_PI/2 AND
                  v_az < c_PI OR
                  v_az > 3 * c_PI/2 ) THEN
          v_delta.x := -1 * v_delta.x;
        END IF;
        -- merge vectors at this point?
        IF (rec.vector_id > 1) THEN
           v_int_coord := rec.startCoord;
           -- Get intersection of two lines parallel at distance p_distance from current ones
           ST_FindLineIntersection(v_adjusted_coord.x,v_adjusted_coord.y,
                                   rec.startCoord.x + v_prev_delta.x,
                                   rec.startCoord.y + v_prev_delta.y,
                                   rec.endCoord.x   + v_delta.x,
                                   rec.endCoord.y   + v_delta.y,
                                   rec.startCoord.x + v_delta.x,
                                   rec.startCoord.y + v_delta.y,
                                   v_int_coord.x,     v_int_coord.y,
                                   v_int_1.x,         v_int_1.y,
                                   v_int_2.x,         v_int_2.y);
           If ( v_int_coord.x = c_Max ) Then
             -- No intersection point as lines are parallel
             bAcute := True;
             -- int coord could be computed from start or end, doesn't matter.
             v_int_coord := &&defaultSchema..T_Vertex(rec.startCoord.x + v_prev_delta.x,
                                             rec.startCoord.y + v_prev_delta.y,
                                             rec.startCoord.z,
                                             rec.startCoord.w,
                                             1);
           Else
             v_angle := ST_AngleBetween3Points(v_prev_start,rec.startCoord,rec.endCoord); 
             bAcute := case when p_distance < 0 and v_angle < 0
                            then /* left */ True
                            when p_distance < 0 and v_angle > 0
                            then /* left */ False
                            when p_distance > 0 and v_angle < 0
                            then /* right */ False
                            when p_distance > 0 and v_angle > 0
                            then /* right */ True
                            else True
                        end;
           End If;
           If ( bCurved and Not bAcute) Then
             -- 1. First point in intersection circular arc
             v_int_1 := T_Vertex(rec.startCoord.x + v_prev_delta.x,
                                 rec.startCoord.y + v_prev_delta.y,
                                 rec.startCoord.z, /* Keep all three points at same z */
                                 rec.startCoord.w, /* Measure may actually change.. */
                                 1);
             -- Need to compute coordinate at mid-angle of the circular arc formed by last and current vector
             v_distance := LINEAR.sdo_distance(mdsys.sdo_geometry(2001,p_linestring.sdo_srid,mdsys.sdo_point_type(v_int_coord.x,v_int_coord.y,v_int_coord.z),null,null),
                                               mdsys.sdo_geometry(2001,p_linestring.sdo_srid,mdsys.sdo_point_type(rec.startCoord.X,rec.startCoord.Y,rec.startCoord.Z),null,null),
                                               p_tolerance,p_unit);
             v_ratio := ( p_distance / v_distance ) * SIGN(p_distance);
             -- 2. Top point of intersection circular arc
             v_adjusted_coord.x := rec.startCoord.x + (( v_int_coord.x - rec.startCoord.x ) * v_ratio );
             v_adjusted_coord.y := rec.startCoord.y + (( v_int_coord.y - rec.startCoord.y ) * v_ratio );
             v_adjusted_coord.z := rec.startCoord.z;
             v_adjusted_coord.w := rec.startCoord.w;
             -- 3. Last point in intersection circular arc
             v_int_2 := T_Vertex(rec.startCoord.x + v_delta.x,
                                 rec.startCoord.y + v_delta.y,
                                 rec.startCoord.z, /* Keep all three points at same z */
                                 rec.startCoord.w, /* Measure may actually change.. */
                                 1);
           Else
             -- Intersection point
             v_adjusted_coord   := v_int_coord;
             v_adjusted_coord.x := v_int_coord.x;
             v_adjusted_coord.y := v_int_coord.y;
           End If;
        ELSE  -- rec.vector_id = 1
          If (bCurved) Then
            appendElement(v_elem_info,1,2,1);
          Else
            -- Copy original through to new geometry as will not change
            v_elem_info := p_linestring.sdo_elem_info;
          End If;
          -- Translate start point with current vector
          v_adjusted_coord := T_Vertex(rec.startCoord.x + v_delta.x,
                                       rec.startCoord.y + v_delta.y,
                                       rec.startCoord.z,rec.startCoord.w,
                                       1);
        END IF;

        -- Now add computed coordints to output ordinate_array
        If (Not bCurved) or bAcute or (rec.vector_id=1) Then
          appendVertex(v_ordinates,v_adjusted_coord);
        ElsIf (bCurved) Then
          -- With any generated circular curves we need to add the appropriate elem_info
          appendElement(v_elem_info,v_ordinates.COUNT+1,2,2);
          appendVertex(v_ordinates,v_int_1);
          appendVertex(v_ordinates,v_adjusted_coord);
          appendElement(v_elem_info,v_ordinates.COUNT+1,2,1);
          appendVertex(v_ordinates,v_int_2);
        End If;
        v_prev_start := rec.startCoord;
        v_prev_delta := v_delta;
        v_last_vertex:= T_Vertex(rec.endCoord.x,rec.endCoord.y,
                                 rec.endCoord.z,rec.endCoord.w,1);
      END LOOP process_each_vector;
      
      appendVertex(v_ordinates,
                   T_Vertex(v_last_vertex.x + v_delta.x,
                            v_last_vertex.y + v_delta.y,
                            v_last_vertex.z,v_last_vertex.w,1));

      If ( ST_hasCircularArcs(v_elem_info) ) Then
         -- And compound header to top of element_info (1,4,n_elements)
         ADD_Compound_Beginning(v_elem_info);
      End If; 
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
    If ST_isCompound(p_geometry.sdo_elem_info) > 0 Then
       raise_application_error(-20001,'Compound linestrings are not supported.',true);
    End If;

    -- Process all parts of a, potentially, multi-part linestring geometry
    FOR elem IN 1..mdsys.sdo_util.getNumElem(p_geometry) loop
       v_part := mdsys.sdo_util.Extract(p_geometry,elem,0);
       If ( elem = 1 ) Then
         v_result := Process_LineString(v_part);
       Else
         /* CONCAT_LINES destroys compound element descriptions, so use APPEND */
         v_result :=  MDSYS.SDO_UTIL.APPEND(v_result,Process_LineString(v_part)); 
       End If;
     End Loop;

    Return v_Result;
  END ST_Parallel;

  /** ---------------------- Point Extractors ------------------------------ **/

  Function ST_Set_Pt_Measure(p_geometry  IN SDO_GEOMETRY,
                             p_point     IN SDO_GEOMETRY,
                             p_measure   IN Number,
                             p_tolerance IN number default 0.05,
                             p_unit      in varchar2 default null)
     Return SDO_Geometry 
  Is
    v_ordinates     mdsys.sdo_ordinate_array;
    v_ord           pls_integer;
    v_dims          pls_integer;
    v_measure_dim   pls_integer;
    v_vertex        pls_integer;
    v_vertex_count  pls_integer;
    v_distance      number;
    v_point_gtype   pls_integer ;
    v_min_distance  number      := c_MaxVal;
    NOT_MEASURED    EXCEPTION;
    NULL_GEOMETRY   EXCEPTION;
    NOT_A_LINE      EXCEPTION;
    NOT_A_POINT     EXCEPTION;
    INVALID_POINT   EXCEPTION;
    DIFFERENT_SRIDS EXCEPTION;
  Begin
    If ( p_geometry is null ) Then
       raise NULL_GEOMETRY;
    End If;
    If ( p_geometry.get_gtype() not in (2,6) ) Then
       raise NOT_A_LINE;
    End If;
    If ( p_point.get_gtype() <> 1 ) Then
       raise NOT_A_POINT;
    End If;
    If ( NVL(p_point.sdo_srid,0) <> NVL(p_geometry.sdo_srid,0) ) Then
       raise DIFFERENT_SRIDS;
    End If;
    v_measure_dim := ST_getMeasureDimension( p_geometry.sdo_gtype );
    If ( v_measure_dim not in (3,4) ) Then
       raise NOT_MEASURED;
    End If;
    If ( p_point.sdo_point is null AND p_point.sdo_ordinates is null OR p_point.sdo_ordinates.count < 2) Then
       raise INVALID_POINT;
    End If;
    v_min_distance := LINEAR.sdo_distance(p_geometry,p_point,p_tolerance,p_unit);
    v_dims         := p_geometry.get_dims();
    v_point_gtype  := case when v_dims = 3 then 2001 else 3001 end;
    v_vertex_count := sdo_util.getNumVertices(p_geometry);
    v_ordinates    := new mdsys.sdo_ordinate_array(1);
    v_ordinates.DELETE;
    v_ordinates.EXTEND(p_geometry.sdo_ordinates.count);
    v_ord    := 1;
    FOR i IN 1..v_vertex_count LOOP
        v_ordinates(v_ord) := p_geometry.sdo_ordinates(v_ord); v_ord := v_ord + 1;
        v_ordinates(v_ord) := p_geometry.sdo_ordinates(v_ord); v_ord := v_ord + 1;
        v_distance := LINEAR.sdo_distance(
                           mdsys.sdo_geometry(2001, /* v_point_gtype, */
                                              p_geometry.sdo_srid,
                                              mdsys.sdo_point_type(p_geometry.sdo_ordinates(v_ord-2),
                                                                   p_geometry.sdo_ordinates(v_ord-1),
                                                                   NULL),
                                              NULL,NULL),
                            p_point,p_tolerance,p_unit);
        if ( v_distance = v_min_distance ) Then
            if ( v_measure_dim = 3 ) Then
               v_ordinates(v_ord) := p_measure; v_ord := v_ord + 1;
               if ( v_dims > 3 ) Then
                  v_ordinates(v_ord) := p_geometry.sdo_ordinates(v_ord); v_ord := v_ord + 1;
               End If;
            ElsIf ( v_measure_dim = 4 ) Then
               v_ordinates(v_ord) := p_geometry.sdo_ordinates(v_ord); v_ord := v_ord + 1;
               v_ordinates(v_ord) := p_measure; v_ord := v_ord + 1;
            end if;
        Else
            v_ordinates(v_ord) := p_geometry.sdo_ordinates(v_ord); v_ord := v_ord + 1;
            if ( v_dims > 3 ) Then
               v_ordinates(v_ord) := p_geometry.sdo_ordinates(v_ord); v_ord := v_ord + 1;
            End If;
        End If;
    END LOOP;
    RETURN mdsys.sdo_geometry(p_geometry.sdo_gtype,
                              p_geometry.sdo_srid,
                              p_geometry.sdo_point,
                              p_geometry.sdo_elem_info,
                              v_ordinates);
    EXCEPTION
      WHEN NOT_MEASURED THEN
         raise_application_error(c_i_not_measured,c_s_not_measured,true);
      WHEN NULL_GEOMETRY THEN
       raise_application_error(c_i_null_geometry,c_s_null_geometry,true);
      When Not_A_Line Then
         raise_application_error(c_i_not_line,c_s_not_line || ' ' || p_geometry.get_gtype(),TRUE);
      When NOT_A_POINT THEN
         raise_application_error(c_i_not_point,c_s_not_point || ' ' || p_point.get_gtype(),TRUE);
      When INVALID_POINT THEN
         raise_application_error(c_i_invalid_point,c_s_invalid_point,TRUE);
      When DIFFERENT_SRIDS THEN
         raise_application_error(c_i_srids_not_same,c_s_srids_not_same,TRUE);
      
  End ST_Set_Pt_Measure;

   FUNCTION ST_Get_Point (p_geometry     IN MDSYS.SDO_GEOMETRY,
                          p_point_number IN NUMBER DEFAULT 1 )
   RETURN MDSYS.SDO_GEOMETRY
   IS
     v_dims  PLS_INTEGER;    -- Number of dimensions in geometry
     v_gtype NUMBER;         -- SDO_GTYPE of returned geometry
     v_p     NUMBER;         -- Index into ordinates array
     v_px    NUMBER;         -- X of extracted point
     v_py    NUMBER;         -- Y of extracted point
     v_pz    NUMBER;         -- Z of extracted point
     v_pm    NUMBER;         -- M of extracted point
   BEGIN
     -- Get the number of dimensions from the gtype
     v_dims := SUBSTR (p_geometry.SDO_GTYPE, 1, 1);
     -- Verify that the point exists
     -- and set index in ordinates array
     IF p_point_number = 0
        OR ABS(p_point_number) > p_geometry.SDO_ORDINATES.COUNT()/v_dims THEN
       RETURN NULL;
     ELSIF p_point_number <= -1 THEN
       v_p := ( (p_geometry.SDO_ORDINATES.COUNT() / v_dims) + p_point_number ) * v_dims + 1;
     ELSE
       v_p := (p_point_number - 1) * v_dims + 1;
     END IF;
     -- Extract the X and Y coordinates of the desired point
     v_gtype := (v_dims*1000) + 1;
     v_px := p_geometry.SDO_ORDINATES(v_p);
     v_py := p_geometry.SDO_ORDINATES(v_p+1);
     IF ( v_dims > 3 ) THEN
       v_pm := p_geometry.SDO_ORDINATES(v_p+3);
       v_pz := p_geometry.SDO_ORDINATES(v_p+2);
     ELSIF ( v_dims = 3 ) THEN
         IF ( ST_isMeasured(p_geometry.SDO_GTYPE)=1 ) THEN
           v_pm := p_geometry.SDO_ORDINATES(v_p+2);
         ELSE
           v_pz := p_geometry.SDO_ORDINATES(v_p+2);
         END IF;
     END IF;
     -- Construct and return the point
     RETURN CASE WHEN v_dims > 3
                 THEN MDSYS.SDO_GEOMETRY(v_gtype,
                                         p_geometry.SDO_SRID,
                                         NULL,
                                         MDSYS.SDO_ELEM_INFO_ARRAY(1,1,1),
                                         MDSYS.SDO_ORDINATE_ARRAY(v_px, v_py, v_pz, v_pm))
                 ELSE MDSYS.SDO_GEOMETRY(v_gtype,
                                         p_geometry.SDO_SRID,
                                         MDSYS.SDO_POINT_TYPE (v_px, v_py,
                                         CASE WHEN ST_isMeasured(p_geometry.sdo_gtype)=1 THEN v_pm ELSE v_pz END),
                                         NULL,
                                         NULL)
             END;
   END ST_Get_Point;

  /* Wrappers over Get_Point */
  -- Start
  Function ST_Start_Point ( p_geometry IN MDSYS.SDO_GEOMETRY )
    Return MDSYS.sdo_geometry
   Is
   Begin
       Return &&defaultSchema..LINEAR.ST_get_point(p_geometry,1);
   End ST_Start_Point;

  Function ST_End_Point ( p_geometry IN MDSYS.SDO_Geometry )
    Return mdsys.sdo_geometry
   Is
   Begin
       Return &&defaultSchema..LINEAR.ST_get_point(p_geometry,-1);
   End ST_End_Point;

   -- Text
   Function ST_Point_Text(p_geometry     IN MDSYS.SDO_GEOMETRY,
                          p_point_number IN NUMBER DEFAULT 1 )
    Return varchar2
  Is
    v_geom  mdsys.sdo_geometry;
    v_text  varchar2(1000);
  Begin
    v_geom := ST_get_point( p_geometry, p_point_number );
    v_text := v_geom.sdo_point.x || '@' ||
              v_geom.sdo_point.y;
    If ( v_geom.sdo_point.z is not null ) Then
      v_text := v_text || '@' || v_geom.sdo_point.z;
    End If;
    Return v_text;
  END ST_Point_Text;

  Function ST_Start_Point_Text ( p_geometry IN MDSYS.SDO_GEOMETRY )
    Return varchar2
  Is
  Begin
    Return ST_Point_Text( p_geometry, 1 );
  END ST_Start_Point_Text;

  Function ST_End_Point_Text ( p_geometry IN MDSYS.SDO_GEOMETRY )
    Return varchar2
  Is
  Begin
    Return ST_Point_Text( p_geometry, -1 );
  END ST_End_Point_Text;

  /** -------------------- END POINT EXTRACTORS --------------------- **/

  Function Compute_Offset(p_vertex_1 in mdsys.vertex_type,
                          p_vertex_2 in mdsys.vertex_type,
                          p_offset   in number)
    return &&defaultSchema..t_vertex
  As
      -- For Offset
      v_ratio           number := 0.0;
      v_offset          &&defaultSchema..T_Vertex := &&defaultSchema..T_Vertex(1,0,0,NULL,NULL);
      v_az              number;
      v_dir             pls_integer;
  Begin
     v_az := Bearing(p_vertex_1.x,p_vertex_1.y,
                     p_vertex_2.x,p_vertex_2.y);
     v_dir  := CASE WHEN v_az < C_PI THEN -1 ELSE 1 END;
     v_offset.x := ABS(COS(v_az)) * p_offset * v_dir;
     v_offset.y := ABS(SIN(v_az)) * p_offset * v_dir;
     IF  Not ( v_az > C_PI/2 AND
               v_az < C_PI OR
               v_az > 3 * C_PI/2 ) THEN
        v_offset.x := -1 * v_offset.x;
      END IF;
      RETURN v_offset;
  End compute_Offset;

  Function Compute_Offset_Point(p_vertex_prev  in mdsys.vertex_type,
                                p_vertex_mid   in mdsys.vertex_type,
                                p_vertex_next  in mdsys.vertex_type,
                                p_offset       in number,
                                p_round_factor in pls_integer)
    return &&defaultSchema..t_vertex
  As
     v_offset_distance number := p_offset;
     v_angle           number;
     v_bearing         number;
     v_geom            mdsys.sdo_geometry;
  Begin
     -- Left
     if ( p_offset < 0 ) then 
       v_angle := anglebetween3points(p_vertex_next.x,p_vertex_next.y,
                                      p_vertex_mid.x,p_vertex_mid.y,
                                      p_vertex_prev.x,p_vertex_prev.y);
       v_offset_distance := (p_offset / sin(v_angle/2.0));
       v_angle := round(degrees(v_angle),2);                        
       if (v_angle < 0 ) then
          v_angle := v_angle+360;
       End If;
       v_bearing := degrees(Bearing(p_vertex_mid.x,p_vertex_mid.y,
                                    p_vertex_next.x,p_vertex_next.y))
                    - (v_angle/2);
       if (v_bearing < 0 ) then
          v_bearing := v_bearing+360;
       elsIf (v_bearing>=360) Then
          v_bearing := v_bearing - 360;
       End If;
     ElsIf ( p_offset > 0 ) then
       v_angle := anglebetween3points(p_vertex_prev.x,p_vertex_prev.y,
                                      p_vertex_mid.x,p_vertex_mid.y,
                                      p_vertex_next.x,p_vertex_next.y);
       v_offset_distance := (p_offset / sin(v_angle/2.0));
       v_angle := round(degrees(v_angle),2);                        
       if (v_angle < 0 ) then
          v_angle := v_angle+360;
       End If;
       v_bearing := degrees(Bearing(p_vertex_mid.x,p_vertex_mid.y,
                                    p_vertex_next.x,p_vertex_next.y))
                    + (v_angle/2);
       if (v_bearing < 0) then
          v_bearing := v_bearing+360;
       elsIf (v_bearing>=360) Then
          v_bearing := v_bearing - 360;
       End If;
     ELse
       v_offset_distance := 0;
       return &&defaultSchema..T_Vertex(p_vertex_mid.x,p_vertex_mid.y,p_vertex_mid.z,p_vertex_mid.w,p_vertex_mid.id);
     End If;
     -- sdo_util.point_at_bearing only for geodetic
     --
     v_geom := PointFromBearingAndDistance(p_vertex_mid.x,p_vertex_mid.y,
                                           v_Bearing,
                                           ABS(v_offset_distance));
     return &&defaultSchema..T_Vertex(v_geom.sdo_point.x,v_geom.sdo_point.y,p_vertex_mid.z,p_vertex_mid.w,p_vertex_mid.id);
  End Compute_Offset_Point;

  Function Build_Point(p_dims         in pls_integer,
                       p_m_dim        in pls_integer,
                       p_srid         in pls_integer,
                       p_vertex       in &&defaultSchema..T_Vertex,
                       p_offset       in &&defaultSchema..T_Vertex,
                       p_round_factor in number)
    return mdsys.sdo_geometry
  As
      v_gtype   pls_integer := (NVL(p_dims,2)*1000) + (100 * NVL(p_m_dim,0)) + 1;
      v_vertex  &&defaultSchema..T_Vertex := case when p_vertex is null
                                         then &&defaultSchema..T_Vertex(0,0,0,0,0)
                                         else &&defaultSchema..T_Vertex(p_vertex.x,p_vertex.y,p_vertex.z,p_vertex.w,0)
                                     end; -- Values for when p_vertex is null
      v_offset  &&defaultSchema..T_Vertex := case when p_offset is null
                                         then &&defaultSchema..T_Vertex(0,0,0,0,0)
                                         else &&defaultSchema..T_Vertex(p_offset.x,p_offset.y,p_offset.z,p_offset.w,0)
                                     end; -- Values for when p_offset is null
  Begin
      If ( p_dims = 2 ) Then
          return mdsys.sdo_geometry(v_gtype,p_srid,
                                    mdsys.sdo_point_type(round(v_vertex.x + v_offset.x,p_round_factor),
                                                         round(v_vertex.y + v_offset.y,p_round_factor),
                                                         NULL),
                                    NULL,NULL);
      ElsIf (p_dims = 3) then
          return mdsys.sdo_geometry(v_gtype,p_srid,
                                    mdsys.sdo_point_type(round(v_vertex.x + v_offset.x,p_round_factor),
                                                         round(v_vertex.y + v_offset.y,p_round_factor),
                                                         v_vertex.z + v_offset.z),
                                    NULL,NULL);
      Else /* = 4 */
          return mdsys.sdo_geometry(v_gtype,
                                    p_srid,
                                    NULL,
                                    mdsys.sdo_elem_info_array(1,1,1),
                                    mdsys.sdo_ordinate_array(round(v_vertex.x + v_offset.x,p_round_factor),
                                                             round(v_vertex.y + v_offset.y,p_round_factor),
                                                             v_vertex.z + v_offset.z,
                                                             v_vertex.z + v_offset.w));
      End If;
  End Build_Point;

  Function ST_Locate_Point(p_geometry      IN mdsys.sdo_geometry,
                           p_distance      IN NUMBER      DEFAULT NULL,
                           p_offset        IN NUMBER      DEFAULT NULL,
                           p_distance_type IN VARCHAR2    DEFAULT 'L', -- or 'M'
                           p_tolerance     IN NUMBER      DEFAULT 0.005,
                           p_unit          in varchar2    default null,
                           p_exception     IN PLS_INTEGER DEFAULT 0)
   Return mdsys.sdo_geometry
  AS
    v_location            number := p_distance;
    v_geom_length         number := 0;
    v_measure             boolean := false;
    v_measure_dimension   pls_integer := 0;
    
    COMPOUND_UNSUPPORTED  EXCEPTION;
    NULL_GEOMETRY         EXCEPTION;
    DISTANCE_NOT_NEGATIVE EXCEPTION;
    DISTANCE_TYPE_WRONG   EXCEPTION;
    NOT_MEASURED          EXCEPTION;
    MUST_BE_LINESTRING    EXCEPTION;
    NULL_ELEM_INFO        EXCEPTION;
    TWOD_ONLY             EXCEPTION;

    Function locate_point_by_length(p_geometry  in mdsys.sdo_geometry,
                                    p_distance  in number,
                                    p_offset    in number,
                                    p_tolerance in number)
    return mdsys.sdo_geometry
    As
        v_dims              pls_integer := p_geometry.get_dims();
        v_point_gtype       pls_integer;
        v_ratio             number;
        v_element_geom      mdsys.sdo_geometry;
        v_num_elements      pls_integer := 0;
        v_offset            &&defaultSchema..T_Vertex := &&defaultSchema..T_Vertex(1,0,0,NULL,NULL);
        v_coord             &&defaultSchema..T_Vertex := &&defaultSchema..T_Vertex(1,null,null,null,null);
        v_vertices          mdsys.vertex_set_type;
        v_vector_length     number := 0.0;
        v_elem_length       number := 0.0;
        v_cumulative_length number := 0.0;
        v_round_factor      number;

    Begin
      -- Compute rounding factors
      v_round_factor := round(log(10,(1/NVL(p_tolerance,0.05))/2));
      v_point_gtype  := p_geometry.sdo_gtype - p_geometry.get_gtype() + 1;
      v_num_elements := mdsys.sdo_util.getNumElem(p_geometry);
      <<for_all_elements>>
      for v_element in 1..v_num_elements loop
          v_element_geom := mdsys.sdo_util.extract(p_geometry,v_element,0);
          v_elem_length  := mdsys.sdo_geom.sdo_length(v_element_geom,p_tolerance);
          If ( round(v_elem_length+v_cumulative_length,v_round_factor) < p_distance ) Then
             -- Skip this element
             v_cumulative_length := v_cumulative_length + v_elem_length;
          Else
            v_vertices := mdsys.sdo_util.getVertices(v_element_geom);
            <<for_all_vertices>>
            for v_vertex in 1..v_vertices.COUNT-1 loop
               v_vector_length := LINEAR.sdo_distance(
                                       mdsys.sdo_geometry(v_point_gtype,
                                                          p_geometry.sdo_srid,
                                                          mdsys.sdo_point_type(v_vertices(v_vertex).x,v_vertices(v_vertex).y,v_vertices(v_vertex).z),
                                                          NULL,NULL),
                                       mdsys.sdo_geometry(v_point_gtype,
                                                          p_geometry.sdo_srid,
                                                          mdsys.sdo_point_type(v_vertices(v_vertex+1).x,v_vertices(v_vertex+1).y,v_vertices(v_vertex+1).z),
                                                          NULL,NULL),
                                       p_tolerance,p_unit);
              -- Is equal to start point of current segment?
              --
              if ( p_distance = round(v_cumulative_length,v_round_factor) ) then

                  if ( p_offset is not null and p_offset <> 0 ) then
                     -- Point is on start vertex of a segment/vector
                     -- Offset by 90 degrees if not first vertex
                     --
                     if ( v_vertex = 1 ) Then
                        v_offset := compute_offset(v_vertices(v_vertex),v_vertices(v_vertex+1),p_offset);
                        return Build_Point(v_dims,0,p_geometry.sdo_srid,&&defaultSchema..T_Vertex(v_vertices(v_vertex).x,v_vertices(v_vertex).y,v_vertices(v_vertex).z,v_vertices(v_vertex).w,0),v_offset,v_round_factor);
                     Else
                        -- Is on vertex between two vectors so need to bisect to find offset point
                        --
                        v_coord := Compute_Offset_Point(v_vertices(v_vertex-1),v_vertices(v_vertex),v_vertices(v_vertex+1),p_offset,v_round_factor);
                        return Build_Point(v_dims,0,p_geometry.sdo_srid,v_coord,null,v_round_factor);
                     End If;
                  Else
                     return Build_Point(v_dims,0,p_geometry.sdo_srid,&&defaultSchema..T_Vertex(v_vertices(v_vertex).x,v_vertices(v_vertex).y,v_vertices(v_vertex).z,v_vertices(v_vertex).w,0),v_offset,v_round_factor);
                  End If;

              -- END POINT OF CURRENT VECTOR SEGMENT 
              --
              elsif ( p_distance = round(v_cumulative_length + v_vector_length,v_round_factor) ) then

                  If ( p_offset is not null and p_offset <> 0) Then

                     -- We are offsetting the point
                     --
                     If ( (v_vertex+1) = v_vertices.COUNT ) Then 
                        -- Falls on End Vertex of whole linestring
                        --
                        v_coord := compute_offset(v_vertices(v_vertex),v_vertices(v_vertex+1),p_offset);
                        return Build_Point(v_dims,
                                           0,
                                           p_geometry.sdo_srid,
                                           &&defaultSchema..T_Vertex(v_vertices(v_vertex+1).x,v_vertices(v_vertex+1).y,v_vertices(v_vertex+1).z,v_vertices(v_vertex+1).w,0),
                                           v_coord,
                                           v_round_factor);
                     -- Else end will be next start so leave to next loop
                     End If;
                  Else
                     return Build_Point(v_dims,0,p_geometry.sdo_srid,&&defaultSchema..T_Vertex(v_vertices(v_vertex+1).x,v_vertices(v_vertex+1).y,v_vertices(v_vertex+1).z,v_vertices(v_vertex+1).w,0),null,v_round_factor);
                  End If;

              elsIf ( p_distance BETWEEN round(v_cumulative_length,v_round_factor)
                                     AND round(v_cumulative_length + v_vector_length,v_round_factor) ) Then
                                     

                     -- Compute new point location along line
                     --
                     v_ratio := ( ( p_distance - v_cumulative_length ) / v_vector_length );
                     v_coord.x := v_vertices(v_vertex).x + ( v_ratio * (v_vertices(v_vertex+1).x-v_vertices(v_vertex).x ));
                     v_coord.y := v_vertices(v_vertex).y + ( v_ratio * (v_vertices(v_vertex+1).y-v_vertices(v_vertex).y ));
                     If ( v_dims = 3 ) Then
                        v_coord.z := v_vertices(v_vertex).z + ( v_ratio * (v_vertices(v_vertex+1).z-v_vertices(v_vertex).z ));
                     ElsIf ( v_dims = 4 ) Then
                        v_coord.w := v_vertices(v_vertex).w + ( v_ratio * (v_vertices(v_vertex+1).z-v_vertices(v_vertex).w ));
                     End If;

                     If ( p_offset is not null and p_offset <> 0) Then
                        -- Falls along the line, use v_coord
                        --
                        v_offset := Compute_Offset_Point(v_vertices(v_vertex),T_Vertex2VertexType(v_coord),v_vertices(v_vertex+1),p_offset,v_round_factor);
                        return Build_Point(v_dims,v_measure_dimension,p_geometry.sdo_srid,null,v_offset,v_round_factor);
                     Else
                        return Build_Point(v_dims,v_measure_dimension,p_geometry.sdo_srid,null,v_coord,v_round_factor);
                     End If;
                     
              end if;
              v_cumulative_length := v_cumulative_length + v_vector_length;
            end loop for_all_vertices;
          End If;
      end loop for_all_elements;
      return build_point(v_dims,0,p_geometry.sdo_srid,
                         &&defaultSchema..T_Vertex(v_vertices(v_vertices.count).x,v_vertices(v_vertices.count).y,v_vertices(v_vertices.count).z,v_vertices(v_vertices.count).w,0),
                         null,
                         v_round_factor);
    END locate_point_by_length;

    Function locate_point_by_measure(p_geometry  in mdsys.sdo_geometry,
                                     p_measure   in number,
                                     p_offset    in number,
                                     p_tolerance in number)
    Return mdsys.sdo_geometry
    As
        v_dims              pls_integer := p_geometry.get_dims();
        v_return_gtype      integer;
        v_element_geom      mdsys.sdo_geometry;
        v_num_elements      pls_integer := 0;
        v_offset            &&defaultSchema..T_Vertex := &&defaultSchema..T_Vertex(1,0,0,NULL,NULL);
        v_new_vertex        mdsys.vertex_type; 
        v_coord             &&defaultSchema..T_Vertex := &&defaultSchema..T_Vertex(1,null,null,null,null);
        v_vertices          mdsys.vertex_set_type;
        v_ratio_along_line  number;
        v_round_factor      number;
        v_measure           number;
        v_next_measure      number;

    Begin
        -- Create gtype of returned object based on this dimension
        v_return_gtype:= TRUNC(p_geometry.sdo_gtype/10)*10+1;
        -- Compute rounding factors
        v_round_factor := round(log(10,(1/p_tolerance)/2));
        v_num_elements := mdsys.sdo_util.getNumElem(p_geometry);
        <<for_all_elements>>
        for v_element in 1..v_num_elements loop
            v_element_geom := mdsys.sdo_util.extract(p_geometry,v_element,0);
            -- iterate over points
            v_vertices := mdsys.sdo_util.getVertices(v_element_geom);
            <<for_all_vertices>>
            for v_vertex in 1..(v_vertices.COUNT-1) loop
                if (  v_measure_dimension = 3 ) Then
                   v_measure      := v_vertices(v_vertex).z;
                   v_next_measure := v_vertices(v_vertex+1).z;
                Else
                   v_measure      := v_vertices(v_vertex).w;
                   v_next_measure := v_vertices(v_vertex+1).w;
                End If;
                -- calculate new position (measure - cumulative) / vector_length
                v_ratio_along_line := (p_measure - v_measure ) / (v_next_measure - v_measure);
                v_coord.x := v_vertices(v_vertex).x + v_ratio_along_line*(v_vertices(v_vertex+1).x-v_vertices(v_vertex).x);
                v_coord.y := v_vertices(v_vertex).y + v_ratio_along_line*(v_vertices(v_vertex+1).y-v_vertices(v_vertex).y);
                v_coord.z := p_measure;
                IF ( v_dims = 4 ) THEN
                   v_coord.w := v_vertices(v_vertex).w + v_ratio_along_line*(v_vertices(v_vertex+1).w-v_vertices(v_vertex).w);
                END IF;
                
                -- Is measure at start point?
                --
                If ( p_measure = ROUND(v_measure,  v_round_factor) ) Then
                
                    If ( p_offset is not null and p_offset <> 0) Then
                      If ( v_vertex = 1 ) Then
                        -- Falls on Start vertex of whole linestring
                        v_offset   := compute_offset(v_vertices(1),v_vertices(2),p_offset);
                        v_offset.x := v_vertices(v_vertex).x + v_offset.x;
                        v_offset.y := v_vertices(v_vertex).y + v_offset.y;
                      Else 
                        -- Falls on vertex between two vectors
                        v_offset := Compute_Offset_Point(v_vertices(v_vertex-1),v_vertices(v_vertex),v_vertices(v_vertex+1),p_offset,v_round_factor);
                      End If;
                      return Build_Point(v_dims,v_measure_dimension,p_geometry.sdo_srid,null,v_offset,v_round_factor);
                    Else -- no offset just return point
                        return Build_Point(v_dims,v_measure_dimension,p_geometry.sdo_srid,v_coord,null,v_round_factor);                        
                    End If;
                    
                -- Is measure at end point?
                --
                ElsIf ( p_measure = ROUND(v_next_measure,v_round_factor) ) Then
                
                     If ( p_offset is not null and p_offset <> 0) Then
                        If ( (v_vertex+1) = v_vertices.COUNT ) Then 
                            -- Falls on End Vertex of whole linestring
                            v_offset   := compute_offset(v_vertices(v_vertex),v_vertices(v_vertex+1),p_offset);
                            v_offset.x := v_vertices(v_vertex+1).x + v_offset.x;
                            v_offset.y := v_vertices(v_vertex+1).y + v_offset.y;
                            return Build_Point(v_dims,v_measure_dimension,p_geometry.sdo_srid,null,v_offset,v_round_factor);
                        End If;
                     Else 
                       -- no offset just return point
                       return Build_Point(v_dims,v_measure_dimension,p_geometry.sdo_srid,v_coord,null,v_round_factor);
                     End If;
                     
                ElsIf ( p_measure BETWEEN ROUND(v_measure,     v_round_factor)
                                      AND ROUND(v_next_measure,v_round_factor) ) Then

                    -- Now offset the found measure
                    --
                    If ( p_offset is not null and p_offset <> 0) Then
                       -- Falls in middle, use v_coord
                       --
                       v_offset := Compute_Offset_Point(v_vertices(v_vertex),T_Vertex2VertexType(v_coord),v_vertices(v_vertex+1),p_offset,v_round_factor);
                       if (  v_measure_dimension = 3 ) Then
                          v_offset.z := p_measure;
                       Else
                          v_offset.w := p_measure;
                       End If;
                       return Build_Point(v_dims,v_measure_dimension,p_geometry.sdo_srid,null,v_offset,v_round_factor);
                    Else
                       return Build_Point(v_dims,v_measure_dimension,p_geometry.sdo_srid,null,v_coord,v_round_factor);
                    End If;
                    
                End If;
            End Loop for_all_vertices;
        end loop for_all_elements;
    End locate_point_by_measure;
    
  Begin
    If ( p_geometry is null ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NULL_GEOMETRY;
       Else
          return p_geometry;
       End If;
    End If;
    If (  p_distance < 0) Then
       If ( p_exception is null or p_exception = 1) then
          raise DISTANCE_NOT_NEGATIVE;
       Else
          return p_geometry;
       End If;
    End If;
    If ( p_distance_type is null ) Then
       v_measure := false;
    ElsIf ( UPPER(p_distance_type) NOT IN ('L','M') ) THEN
       If ( p_exception is null or p_exception = 1) then
          raise DISTANCE_TYPE_WRONG;
       Else
          return p_geometry;
       End If;
    Else
       v_measure := CASE WHEN UPPER(p_distance_type) = 'M' THEN true ELSE false END;
    End If;
    v_measure_dimension := ST_GetMeasureDimension(p_geometry.sdo_gtype);
    if ( v_measure and v_measure_dimension = 0 ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NOT_MEASURED;
       Else
          return p_geometry;
       End If;
    End If;
    if ( p_geometry.get_gtype() not in (2,6) ) Then
       If ( p_exception is null or p_exception = 1) then
          raise MUST_BE_LINESTRING;
       Else
          return p_geometry;
       End If;
    End If;
    if ( p_geometry.sdo_elem_info is null ) then
       If ( p_exception is null or p_exception = 1) then
          raise NULL_ELEM_INFO;
       Else
          return p_geometry;
       End If;
    End if;
    if ( ST_hasCircularArcs(p_geometry.sdo_elem_info) ) then
       If ( p_exception is null or p_exception = 1) then
          raise COMPOUND_UNSUPPORTED;
       Else
          return p_geometry;
       End If;
    End if;

    if ( Not v_measure ) Then
        -- Only 2D for now
        --if (  p_geometry.get_dims()>2 ) Then
        --   RAISE TWOD_ONLY;
        --End If;
        return locate_point_by_length(p_geometry,  v_location, p_offset, p_tolerance);
    Else
        return locate_point_by_measure(p_geometry, v_location, p_offset, p_tolerance);
    End If;
    
    Exception
        WHEN NULL_GEOMETRY THEN
            Raise_Application_Error(C_I_Null_Geometry,C_S_Null_Geometry,True);
        WHEN COMPOUND_UNSUPPORTED THEN
            raise_application_error(c_i_unsupported,c_s_unsupported,true);
        WHEN DISTANCE_TYPE_WRONG THEN
            raise_application_error(c_i_distance_type_wrong,c_s_distance_type_wrong || UPPER(p_distance_type) ||'.',true);
        WHEN DISTANCE_NOT_NEGATIVE THEN
            raise_application_error(c_i_distance_not_negative,c_s_distance_not_negative,true);
        WHEN NOT_MEASURED THEN
            raise_application_error(c_i_not_measured,c_s_not_measured,true);
        WHEN MUST_BE_LINESTRING THEN
            raise_application_error(c_i_must_be_linestring,c_i_must_be_linestring,true);
        WHEN NULL_ELEM_INFO THEN
            raise_application_error(c_i_null_elem_info,c_s_null_elem_info,true);
        WHEN TWOD_ONLY THEN
             raise_application_error(c_i_2d_only,c_s_2d_only,true);
             
  END ST_Locate_Point;

  Function ST_Find_Measure(p_geometry  IN mdsys.sdo_geometry,
                           p_point     IN mdsys.sdo_geometry,
                           p_tolerance IN NUMBER      DEFAULT 0.005,
                           p_unit      in varchar2    default null,
                           p_exception IN PLS_INTEGER DEFAULT 0)
    Return number
  Is
    v_dims              pls_integer;
    v_gtype             pls_integer;
    v_measure           number := 0.0;
    v_start_distance    number := 0.0;
    v_end_distance      number := 0.0;
    v_distance_to_line  number := 0.0;
    v_vector_length     number := 0.0;
    v_min_dist_to_line  number := c_MaxVal;
    v_vertices          mdsys.vertex_set_type;
    v_id         pls_integer;
    v_vertex            mdsys.vertex_type;
    v_element_no        pls_integer;
    v_num_elements      pls_integer;
    v_element           mdsys.sdo_geometry;
    v_round_factor      number;
    v_cumulative_length number := 0.0;
    NULL_GEOMETRY       EXCEPTION;
    NOT_A_LINE          EXCEPTION;
    NOT_A_POINT         EXCEPTION;
    NULL_TOLERANCE      EXCEPTION;

  Begin
    If ( p_geometry is null ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NULL_GEOMETRY;
       Else
          return null;
       End If;
    End If;
    If ( p_point is null ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NULL_GEOMETRY;
       Else
          return null;
       End If;
    End If;
    v_gtype := p_geometry.Get_GType();
    If ( v_gtype not in (2,6) ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NOT_A_LINE;
       Else
          return null;
       End If;
    End If;
    v_gtype := p_point.Get_GType();
    If ( v_gtype <> 1 ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NOT_A_POINT;
       Else
          return null;
       End If;
    End If;
    If ( p_tolerance is Null ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NULL_TOLERANCE;
       Else
          return null;
       End If;
    End If;
    v_dims  := p_geometry.Get_Dims();
    if ( v_dims > 3 ) Then
       v_dims := 3;
    End If;
    v_round_factor      := round(log(10,(1/p_tolerance)/2));
    v_cumulative_length := 0.0;
    v_num_elements := mdsys.sdo_util.GetNumElem(p_geometry);
    <<for_all_elements>>
    FOR v_element_no IN 1..v_num_elements LOOP
       v_element  := mdsys.sdo_util.Extract(p_geometry,v_element_no,0);   -- Extract element with all sub-elements
       v_vertices := mdsys.sdo_util.getVertices(v_element);
       <<for_all_vectors>>
       FOR v_id in v_vertices.FIRST..(v_vertices.LAST-1) LOOP
           -- Is start point of vector equal to supplied point?
           v_start_distance := LINEAR.sdo_distance(
                                      mdsys.sdo_geometry(p_point.sdo_gtype,
                                                         p_point.sdo_srid,
                                                         mdsys.sdo_point_type(v_vertices(v_id).x,v_vertices(v_id).y,v_vertices(v_id).z),
                                                         NULL,NULL),
                                      p_point,p_tolerance,p_unit);
           if ( round(v_start_distance,v_round_factor) = 0.0 ) then
               return round(v_cumulative_length,v_round_factor);
           End If;
           -- Compute vector length
           v_vector_length := mdsys.sdo_geom.sdo_distance(
                                    mdsys.sdo_geometry(p_point.sdo_gtype,
                                                       p_point.sdo_srid,
                                                       mdsys.sdo_point_type(v_vertices(v_id).x,v_vertices(v_id).y,v_vertices(v_id).z),
                                                       NULL,NULL),
                                    mdsys.sdo_geometry(p_point.sdo_gtype,
                                                       p_point.sdo_srid,
                                                       mdsys.sdo_point_type(v_vertices(v_id+1).x,v_vertices(v_id+1).y,v_vertices(v_id+1).z),
                                                       NULL,NULL),
                                    p_tolerance,p_unit);
           -- Is end point of vector equal to supplied point?
           v_end_distance   := LINEAR.sdo_distance(
                                      mdsys.sdo_geometry(p_point.sdo_gtype,
                                                         p_point.sdo_srid,
                                                         mdsys.sdo_point_type(v_vertices(v_id+1).x,v_vertices(v_id+1).y,v_vertices(v_id+1).z),
                                                         NULL,NULL),
                                      p_point,
                                      p_tolerance,p_unit);
           if ( round(v_end_distance,v_round_factor) = 0.0 ) then
               return round(v_cumulative_length + v_vector_length,v_round_factor);
           End If;
           -- Compute point's distance to vector
           v_distance_to_line := LINEAR.sdo_distance(
                                   mdsys.sdo_geometry(p_geometry.sdo_gtype,
                                                      p_geometry.sdo_srid,NULL,
                                                      mdsys.sdo_elem_info_array(1,2,1),
                                                      case when v_dims = 3
                                                           then mdsys.sdo_ordinate_array(v_vertices(v_id  ).x,v_vertices(v_id  ).y,v_vertices(v_id  ).z,
                                                                                         v_vertices(v_id+1).x,v_vertices(v_id+1).y,v_vertices(v_id+1).z)
                                                           else mdsys.sdo_ordinate_array(v_vertices(v_id  ).x,v_vertices(v_id  ).y,
                                                                                         v_vertices(v_id+1).x,v_vertices(v_id+1).y)
                                                       end),
                                   p_point,p_tolerance,p_unit);
           -- Save it if it is the current minimum
           if ( v_distance_to_line < v_min_dist_to_line ) then
               v_min_dist_to_line := v_distance_to_line;
               -- Calculate measure point for this minimum
               -- measure along this line is cumulative length to start point +
               -- distance from start point to calculated measure by ratio
               v_measure := v_cumulative_length + ( v_vector_length * ( v_start_distance / (v_start_distance + v_end_distance) ) );
           End If;
           -- Update cumulative length to include this vector
           v_cumulative_length := v_cumulative_length + v_vector_length;
       END LOOP for_all_vectors;
    END LOOP for_all_elements;
    return round(v_measure,v_round_factor);
    Exception
      When NULL_GEOMETRY Then
         raise_application_error(c_i_null_geometry,c_s_null_geometry,TRUE);
      When NOT_A_LINE Then
         raise_application_error(c_i_not_line,c_s_not_line || ' ' || v_gtype,TRUE);
      When NOT_A_POINT Then
         raise_application_error(c_i_not_point,c_s_not_point || ' ' || v_gtype,TRUE);
      When NULL_TOLERANCE Then
         raise_application_error(c_i_null_tolerance,c_s_null_tolerance,TRUE);
  End ST_Find_Measure;

  /* ========================= UTILITIES ============================ */

  Function ST_GetNumRings( p_geometry  in mdsys.sdo_geometry,
                        p_ring_type in integer default &&defaultSchema..LINEAR.c_rings_all )
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
  End ST_GetNumRings;

/** ----------------------------------------------------------------------------------------
  * @function   : ST_hasElementCircularArcs
  * @precis     : A function that tests whether an sdo_geometry element contains circular arcs
  * @version    : 1.0
  * @history    : Simon Greener - Aug 2009 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. (http://creativecommons.org/licenses/by-sa/2.5/au/)
  **/
  Function ST_hasElementCircularArcs(p_elem_type in number)
    return boolean
  Is
  Begin
    Return ( p_elem_type in (4,5,1005,2005) );
  End ST_hasElementCircularArcs;

  Function ST_Vectorize(p_geometry  IN mdsys.sdo_geometry,
                        p_exception IN PLS_INTEGER DEFAULT 0)
    Return &&defaultSchema..LINEAR.T_Vectors pipelined
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
       If ( NVL(p_exception,1)=1 ) Then
          raise NULL_GEOMETRY;
       Else
          return;
       End If;
    End If;

    -- No Points
    -- DEBUG  dbms_output.put_line(p_geometry.sdo_gtype);
    If ( Mod(p_geometry.sdo_gtype,10) in (1,5) ) Then
      Return;
    End If;

   If ( &&defaultSchema..LINEAR.ST_hasCircularArcs(p_geometry.sdo_elem_info) ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NOT_CIRCULAR_ARC;
       Else
          return;
       End If;
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
              v_num_rings := ST_GetNumRings(v_element,&&defaultSchema..LINEAR.c_rings_all);
              <<All_Rings>>
              FOR v_ring_no IN 1..v_num_rings LOOP
                  v_ring := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_element_no,v_ring_no);
                  -- Now generate marks
                  If ( v_ring is not null ) Then
                      v_coordinates := mdsys.sdo_util.getVertices(v_ring);
                      If ( v_ring.sdo_elem_info(2) in (1003,2003) 
                       And v_ring.sdo_elem_info(3) = 3 
                       And v_coordinates.COUNT = 2 ) Then
                         PIPE ROW( &&defaultSchema..T_Vector(1, 
                                                    Vertex2Vertex(v_coordinates(1),1),
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
                            PIPE ROW(&&defaultSchema..T_Vector(v_coord_no,
                                                      &&defaultSchema..T_Vertex(v_coordinates(v_coord_no).x,
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
                   PIPE ROW(&&defaultSchema..T_Vector(v_coord_no,
                                             &&defaultSchema..T_Vertex(v_coordinates(v_coord_no).x,
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
        raise_application_error(c_i_null_geometry, c_s_null_geometry,TRUE);
        RETURN;
      WHEN NOT_CIRCULAR_ARC THEN
        raise_application_error(c_i_arcs_unsupported, c_s_arcs_unsupported,TRUE);
        RETURN;
  End ST_Vectorize;

  Function ST_Vectorize(p_geometry  in mdsys.sdo_geometry,
                        p_arc2chord in number,
                        p_unit      in varchar2 default null,
                        p_exception IN PLS_INTEGER DEFAULT 0  )
    Return &&defaultSchema..LINEAR.T_Vectors pipelined
  is
    v_geometry MDSYS.SDO_Geometry := p_geometry;
  Begin
    If ( p_geometry is NULL ) Then
      Return ;
    End If;
    If ( Mod(v_geometry.sdo_gtype,10) in (1,5) ) Then
      Return ;
    End If;
    If ST_isCompound(p_geometry.sdo_elem_info) > 0 Then
       -- And compound header to top of element_info (1,4,n_elements)
       -- v_geometry := &&defaultSchema..LINEAR.Convert_Geometry(p_geometry,p_arc2chord);
       v_geometry := case when p_geometry.sdo_srid is not null
                          then mdsys.sdo_geom.sdo_arc_densify(p_geometry,0.05,'arc_tolerance='||p_arc2chord||' '||p_unit)
                          else mdsys.sdo_geom.sdo_arc_densify(p_geometry,0.05,'arc_tolerance='||p_arc2chord)
                      end;
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
                  from table(&&defaultSchema..LINEAR.ST_Vectorize(v_geometry,p_exception)) v ) LOOP
      PIPE ROW (&&defaultSchema..T_Vector(rec.coord_no,
                                 &&defaultSchema..T_Vertex(rec.sx,rec.sy,rec.sz,rec.sw,rec.coord_no),
                                 &&defaultSchema..T_Vertex(rec.ex,rec.ey,rec.ez,rec.ew,rec.coord_no + 1)) );
    END LOOP vector_access_loop;
    RETURN ;
  end ST_Vectorize;

  Function ST_To2D( p_geom IN MDSYS.SDO_Geometry )
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
    v_dim   := p_geom.Get_Dims();
    v_gtype := MOD(p_geom.sdo_gtype,10); -- Short gtype

    IF v_dim = 2 THEN
      -- Nothing to do, p_geom is already 2D
      RETURN (p_geom);
    END IF;

    -- Compute number of points
    v_npoints := mdsys.sdo_util.GetNumVertices(p_geom);

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
            If Not ( ST_hasElementCircularArcs(v_2D_geom.sdo_elem_info (v_i + 1) ) ) Then
              -- Adjust Elem Info offsets
              v_offset := v_2D_geom.sdo_elem_info (v_i);
              v_2D_geom.sdo_elem_info(v_i) := (v_offset - 1) / v_dim * 2 + 1;
            End If;
            v_i := v_i + 3;
      END LOOP;

    END IF;
    RETURN v_2D_geom;
  END ST_To2D;

  Function ST_DownTo3D( p_geom  IN MDSYS.SDO_Geometry,
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
           raise INVALID_Z_ORDINATE;  -- write to output
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
              -- hasElementCircularArcs?
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
  End ST_DownTo3D;

   Function ST_To3D(p_geom      IN MDSYS.SDO_Geometry,
                    p_start_z   IN NUMBER default NULL,
                    p_end_z     IN NUMBER default NULL,
                    p_tolerance IN NUMBER default 0.005,
                    p_unit      in varchar2 default null)
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
    v_dim   := Trunc(p_geom.sdo_gtype/1000,0);
    v_gtype := MOD(p_geom.sdo_gtype,10); -- Short gtype

    IF ( v_dim = 3 ) THEN
      -- Nothing to do, p_geom is already 3D
      Return (p_geom);
    ElsIf ( v_dim = 4 ) Then
      Return ST_DownTo3D(p_geom,3);
    END IF;

    If ( P_Start_Z Is Not Null And P_End_Z Is Not Null ) Then
       -- This can only be done for Spatial and Not Locator.
       v_length := &&defaultSchema..LINEAR.sdo_length( p_geom, p_tolerance, p_unit );
    END IF;

    -- Compute number of points
    v_npoints := mdsys.sdo_util.GetNumVertices(p_geom);

    -- Construct output object ...
    v_3D_geom := MDSYS.SDO_GEOMETRY(3000 + v_gtype,
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
               round(LINEAR.sdo_distance(mdsys.sdo_geometry(2001,P_Geom.Sdo_Srid,sdo_point_type(v_coords(i).x,v_coords(i).y,v_coords(i).z),null,null),
                                         mdsys.sdo_geometry(2001,P_Geom.Sdo_Srid,Sdo_Point_Type(V_Coords(i+1).X,V_Coords(i+1).Y,v_coords(i+1).z),null,null),
                                         p_tolerance,p_unit),
                     v_round_factor);
          End If;
          v_3D_geom.sdo_ordinates (v_j + 2) := case when p_end_z is null
                                                    then p_start_z
                                                    when v_length != 0
                                                    then p_start_z + round( ( ( p_end_z - p_start_z ) / v_length ) * v_cumulative_length,v_round_factor)
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
          -- hasElementCircularArcs?
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
  End ST_To3d;

  Function ST_Fix3DZ( p_3D_geom   IN MDSYS.SDO_Geometry,
                      p_default_z IN NUMBER := -9999 )
           Return MDSYS.SDO_Geometry
  Is
    v_3D_geom       MDSYS.SDO_GEOMETRY := p_3D_geom;
    v_dim_count     integer; -- number of dimensions in layer
    v_gtype         integer; -- geometry type (single digit)
    v_n_points      integer; -- number of points in ordinates array
    i               integer;
    WRONG_DIMENSION EXCEPTION;
  begin
    -- If the input geometry is null, just return null
    if v_3D_geom is null then
      RETURN (null);
    end if;

    -- Get the number of dimensions from the v_gtype
    if ( length (v_3D_geom.sdo_gtype) = 4 ) then
      v_dim_count := substr (v_3D_geom.sdo_gtype, 1, 1);
      v_gtype     := substr (v_3D_geom.sdo_gtype, 4, 1);
    else
      -- Indicate failure
      raise WRONG_DIMENSION;
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
      WHEN WRONG_DIMENSION THEN
         raise_application_error ( c_i_dimensionality,REPLACE(c_s_dimensionality,':1',to_char(v_3D_geom.sdo_gtype)));
      WHEN OTHERS THEN
        dbms_output.put_line('Error ('|| SQLCODE ||') of ' || SQLERRM(SQLCODE) );
        RETURN v_3D_Geom;
  END ST_Fix3DZ;

  Function ST_Reverse_Geometry(p_geometry in mdsys.sdo_geometry)
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
  End ST_Reverse_Geometry;

  Procedure ST_FindLineIntersection(
    x11       in number,        y11       in number,
    x12       in number,        y12       in number,
    x21       in number,        y21       in number,
    x22       in number,        y22       in number,
    inter_x  out nocopy number, inter_y  out nocopy number,
    inter_x1 out nocopy number, inter_y1 out nocopy number,
    inter_x2 out nocopy number, inter_y2 out nocopy number )
  IS
      X1          NUMBER;
      Y1          NUMBER;
      dx2         NUMBER;
      dy2         NUMBER;
      t1          NUMBER;
      t2          NUMBER;
      denominator NUMBER;
  BEGIN
    -- Get the segments' parameters.
    X1 := x12 - x11;
    Y1 := y12 - y11;
    dx2 := x22 - x21;
    dy2 := y22 - y21;

    -- Solve for t1 and t2.
    denominator := (Y1 * dx2 - X1 * dy2);
    IF ( denominator = 0 ) Then
      -- The lines are parallel.
      inter_x  := c_Max;
      inter_y  := c_Max;
      inter_x1 := c_Max;
      inter_y1 := c_Max;
      inter_x2 := c_Max;
      inter_y2 := c_Max;
      RETURN;
    End If;
    t1 := ((x11 - x21) * dy2 + (y21 - y11) * dx2) / denominator;
    t2 := ((x21 - x11) * Y1  + (y11 - y21) * X1) / -denominator;

    -- Find the point of intersection.
    inter_x := x11 + X1 * t1;
    inter_y := y11 + Y1 * t1;

    -- Find the closest points on the segments.
    If t1 < 0 Then t1 := 0; ElsIf t1 > 1 Then t1 := 1; End If;
    If t2 < 0 Then t2 := 0; ElsIf t2 > 1 Then t2 := 1; End If;
    inter_x1 := x11 + X1 * t1;
    inter_y1 := y11 + Y1 * t1;
    inter_x2 := x21 + dx2 * t2;
    inter_y2 := y21 + dy2 * t2;
  END ST_FindLineIntersection;

    Function ST_AngleBetween3Points(dStartX in number,
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
    End ST_AngleBetween3Points;

    Function ST_AngleBetween3Points(p_Start  in mdsys.vertex_type,
                                    p_Centre in mdsys.vertex_type,
                                    p_End    in mdsys.vertex_type)
    Return Number
    IS
    BEGIN
        Return &&defaultSchema..LINEAR.ST_AngleBetween3Points(p_Start.x,p_start.y,
                                                     p_Centre.x,p_Centre.y,
                                                     p_End.x, p_End.y);
    End ST_AngleBetween3Points;

    Function ST_AngleBetween3Points(p_Start  in T_Vertex,
                                    p_Centre in T_Vertex,
                                    p_End    in T_Vertex)
    Return Number
    IS
    BEGIN
        Return &&defaultSchema..LINEAR.ST_AngleBetween3Points(p_Start.x,p_start.y,
                                                     p_Centre.x,p_Centre.y,
                                                     p_End.x, p_End.y);
    End ST_AngleBetween3Points;

  Function ST_Split_Points(p_geometry  in mdsys.sdo_geometry,
                           p_splitter  in mdsys.sdo_geometry,
                           p_tolerance in number      default 0.005,
                           p_unit      In Varchar2    default null,
                           p_exception in pls_integer default 0)
    return &&defaultSchema..LINEAR.t_Geometries pipelined
  Is
    v_targtVectors &&defaultSchema..LINEAR.t_Vectors;
    v_splitVectors &&defaultSchema..LINEAR.t_Vectors;
    v_inter_x      number; v_inter_y  number;
    v_inter_x1     number; v_inter_y1 number;
    v_inter_x2     number; v_inter_y2 number;
    v_round_factor number      := round(log(10,(1/p_tolerance)/2));
    v_lgtype       pls_integer := case when p_geometry is not null then p_geometry.get_dims()*1000+1 else 2001 end;
  Begin
    if ( mdsys.sdo_util.getNumVertices(p_geometry) > mdsys.sdo_util.getNumVertices(p_splitter) ) then
      select &&defaultSchema..t_Vector(v.id,v.startCoord,v.endCoord) bulk collect into v_targtVectors from table(&&defaultSchema..LINEAR.ST_Vectorize(p_geometry)) v;
      select &&defaultSchema..t_Vector(v.id,v.startCoord,v.endCoord) bulk collect into v_SplitVectors from table(&&defaultSchema..LINEAR.ST_Vectorize(p_splitter)) v;
    else
      select &&defaultSchema..t_Vector(v.id,v.startCoord,v.endCoord) bulk collect into v_targtVectors from table(&&defaultSchema..LINEAR.ST_Vectorize(p_splitter)) v;
      select &&defaultSchema..t_Vector(v.id,v.startCoord,v.endCoord) bulk collect into v_SplitVectors from table(&&defaultSchema..LINEAR.ST_Vectorize(p_geometry)) v;
    end if;
    for v_i in v_targtVectors.FIRST..v_targtVectors.LAST loop
      for v_j in v_splitVectors.FIRST..v_splitVectors.LAST loop
        ST_FindLineIntersection(v_targtVectors(v_i).startCoord.x, v_targtVectors(v_i).startCoord.y,
                             v_targtVectors(v_i).endCoord.x,   v_targtVectors(v_i).endCoord.y,
                             v_splitVectors(v_j).startCoord.x, v_splitVectors(v_j).startCoord.y,
                             v_splitVectors(v_j).endCoord.x,   v_splitVectors(v_j).endCoord.y,
                             v_inter_x, v_inter_y,
                             v_inter_x1,v_inter_y1,
                             v_inter_x2,v_inter_y2);
        v_inter_x  := round(v_inter_x,v_round_factor);
        v_inter_y  := round(v_inter_y,v_round_factor);
        v_inter_x1 := round(v_inter_x1,v_round_factor);
        v_inter_y1 := round(v_inter_y1,v_round_factor);
        v_inter_x2 := round(v_inter_x2,v_round_factor);
        v_inter_y2 := round(v_inter_y2,v_round_factor);
        -- When all three returned points are the same (and not c_Max) we have an actual intersection
        If ( v_inter_x <> c_Max
          and v_inter_x = v_inter_x1
          and v_inter_y = v_inter_y1
          and v_inter_x = v_inter_x2
          and v_inter_y = v_inter_y2 ) Then
          -- Return point
          PIPE ROW(&&defaultSchema..t_geometry(mdsys.sdo_geometry(v_lgtype,p_geometry.sdo_srid,mdsys.sdo_point_type(v_inter_x,v_inter_y,null),null,null)));
        End If;
      End loop;
    End loop;
    return;
  End ST_Split_Points;

  Function ST_Split_Line(p_geometry  in mdsys.sdo_geometry,
                         p_splitter  in mdsys.sdo_geometry,
                         P_Tolerance In Number      Default 0.005,
                         p_unit      In Number      Default null,
                         p_exception in pls_integer default 0)
    Return &&defaultSchema..LINEAR.t_Geometries pipelined
  AS
    v_targtVectors  &&defaultSchema..LINEAR.t_Vectors;
    v_SplitVectors  &&defaultSchema..LINEAR.t_Vectors;
    v_geometry      mdsys.sdo_geometry;
    v_inter_x       number; v_inter_y  number;
    v_inter_x1      number; v_inter_y1 number;
    v_inter_x2      number; v_inter_y2 number;
    v_lgtype        pls_integer            := case when p_geometry is not null then p_geometry.get_dims()*1000+1 else 2001 end;
    v_measures      &&defaultSchema..t_numbers := &&defaultSchema..t_numbers(null);
    v_measures_uniq &&defaultSchema..t_numbers := &&defaultSchema..t_numbers(null);
    v_round_factor  number                 := round(log(10,(1/p_tolerance)/2));

  Begin
    v_measures.DELETE;
    if ( mdsys.sdo_util.getNumVertices(p_geometry) > mdsys.sdo_util.getNumVertices(p_splitter) ) then
      select &&defaultSchema..t_Vector(v.id,v.startCoord,v.endCoord) bulk collect into v_targtVectors from table(&&defaultSchema..LINEAR.ST_Vectorize(p_geometry)) v;
      select &&defaultSchema..t_Vector(v.id,v.startCoord,v.endCoord) bulk collect into v_SplitVectors from table(&&defaultSchema..LINEAR.ST_Vectorize(p_splitter)) v;
    else
      select &&defaultSchema..t_Vector(v.id,v.startCoord,v.endCoord) bulk collect into v_targtVectors from table(&&defaultSchema..LINEAR.ST_Vectorize(p_splitter)) v;
      select &&defaultSchema..t_Vector(v.id,v.startCoord,v.endCoord) bulk collect into v_SplitVectors from table(&&defaultSchema..LINEAR.ST_Vectorize(p_geometry)) v;
    end if;
    -- Get start measure ...
    v_measures.EXTEND(1);
    v_measures(v_measures.COUNT) := case when p_geometry.get_lrs_dim()=0 then 0 else p_geometry.sdo_ordinates(p_geometry.get_lrs_dim()) end;
    for v_i in v_targtVectors.FIRST..v_targtVectors.LAST loop
      for v_j in v_splitVectors.FIRST..v_splitVectors.LAST loop
        -- Check if vectors cross by computing intersection point
        --
        ST_FindLineIntersection(v_targtVectors(v_i).startCoord.x, v_targtVectors(v_i).startCoord.y,
                             v_targtVectors(v_i).endCoord.x,   v_targtVectors(v_i).endCoord.y,
                             v_splitVectors(v_j).startCoord.x, v_splitVectors(v_j).startCoord.y,
                             v_splitVectors(v_j).endCoord.x,   v_splitVectors(v_j).endCoord.y,
                             v_inter_x, v_inter_y,
                             v_inter_x1,v_inter_y1,
                             v_inter_x2,v_inter_y2);
        v_inter_x  := round(v_inter_x,v_round_factor);
        v_inter_y  := round(v_inter_y,v_round_factor);
        v_inter_x1 := round(v_inter_x1,v_round_factor);
        v_inter_y1 := round(v_inter_y1,v_round_factor);
        v_inter_x2 := round(v_inter_x2,v_round_factor);
        v_inter_y2 := round(v_inter_y2,v_round_factor);
        -- When all three returned points are the same (and not c_Max) we have an actual intersection
        If ( v_inter_x <> c_Max
          and v_inter_x = v_inter_x1
          and v_inter_y = v_inter_y1
          and v_inter_x = v_inter_x2
          and v_inter_y = v_inter_y2 ) Then
          -- Get measure
          v_measures.EXTEND(1);
          v_measures(v_measures.COUNT) :=
             ST_Find_Measure(p_geometry,
                             mdsys.sdo_geometry(v_lgtype,p_geometry.sdo_srid,mdsys.sdo_point_type(v_inter_x,v_inter_y,null),null,null),
                             p_tolerance,
                             p_unit);
        End If;
      End loop;
    End loop;

    -- Add end measure ...
    v_measures.EXTEND(1);
    v_measures(v_measures.COUNT) := case when p_geometry.get_lrs_dim()=0 then mdsys.sdo_geom.sdo_length(p_geometry,p_tolerance) 
                                         else p_geometry.sdo_ordinates((p_geometry.sdo_ordinates.count-p_geometry.get_dims())+p_geometry.get_lrs_dim()) 
                                     end;

    -- sort, unique numbers
    --
    select distinct t.column_value
      bulk collect into v_measures_uniq
      from table( v_measures ) t
     order by t.column_value;

    -- Now Split and return lines
    --
    if ( v_measures_uniq is not null and v_measures_uniq.COUNT > 1 ) THen
      for v_i in v_measures_uniq.FIRST..(v_measures_uniq.COUNT-1) loop
          v_geometry := &&defaultSchema..LINEAR.ST_Clip(p_geometry,
                                        v_measures_uniq(v_i),  /* Start */
                                        v_measures_uniq(v_i+1),/* End */
                                        case when p_geometry.get_lrs_dim()=0 then 'L' else 'M' end,
                                        p_tolerance,
                                        p_unit,
                                        p_exception);

          If ( v_geometry is not null ) Then 
             PIPE ROW (&&defaultSchema..T_Geometry(v_geometry)); 
          End If;
      end loop;
    Else
      PIPE ROW (&&defaultSchema..T_Geometry(p_geometry));
    End If;

    Return;
  End ST_Split_Line;

  /**
  * point ST_Line_Interpolate_Point(bytea Geometry, double fraction);
  * Returns the Coordinates for the point on the line at the given fraction.
  * This fraction (ie percentage 0.9 = 80%), is applied to the line's total length.
  * Does not support measure. TO do so use 
  * Wrapper (based on PostGIS) over:
    Function Locate_Point(p_geometry      IN mdsys.sdo_geometry,
                          v_distance      IN NUMBER      DEFAULT NULL,
                          v_distance_type IN VARCHAR2    DEFAULT 'L', -- or 'M'
                          p_tolerance     IN NUMBER      DEFAULT 0.005,
                          p_exception     IN PLS_INTEGER DEFAULT 0)
  **/
  Function ST_Line_Interpolate_Point(P_Geometry  In Mdsys.Sdo_Geometry,
                                     P_Fraction  In Number,
                                     P_Tolerance In Number      Default 0.005,
                                     p_unit      in varchar2    default null,
                                     p_exception In Pls_Integer Default 0)
    Return Mdsys.Sdo_Geometry
  As
      v_length number;
  Begin
      v_length := &&defaultSchema..LINEAR.sdo_length(p_geometry,p_tolerance,p_unit);
      Return &&defaultSchema..Linear.ST_Locate_Point(P_Geometry,
                                     v_length * p_fraction,
                                     'L',
                                     P_Tolerance,
                                     p_unit,
                                     P_Exception);
  End ST_Line_Interpolate_Point;

  /**
  * ST_Line_Locate_Point
  * double ST_Line_Locate_Point(bytea Line, bytea Point)
  * Computes the fraction of a Line from the closest point on the line to the given point.
  * The point does not necessarily have to lie precisely on the line.
  * Both geometries must have the same SRID and dimensions.
  * Wrapper (based on PostGIS) over
    Function Find_Measure(p_geometry  IN mdsys.sdo_geometry,
                          p_point     IN mdsys.sdo_geometry,
                          p_tolerance IN NUMBER      DEFAULT 0.005,
                          p_exception IN PLS_INTEGER DEFAULT 0)
      Return Number Deterministic;
  **/
  Function ST_Line_Locate_Point(p_geometry  In Mdsys.Sdo_Geometry,
                                P_Point     In Mdsys.Sdo_Geometry,
                                P_Tolerance In Number      Default 0.005,
                                p_unit      In Varchar2    default null,
                                p_exception In Pls_Integer Default 0)
    Return Number
  As
  Begin
      return &&defaultSchema..LINEAR.ST_Find_Measure(p_geometry,p_point,p_tolerance,p_unit,p_exception);
  End ST_Line_Locate_Point;

  Function ST_Locate_Along_Measure(P_Geometry  In Mdsys.Sdo_Geometry,
                                   p_m         in Number,
                                   P_Tolerance In Number      Default 0.005,
                                   p_exception In Pls_Integer Default 0)
    Return Mdsys.Sdo_Geometry
  As
  Begin
      Return &&defaultSchema..Linear.ST_Locate_Point(P_Geometry,
                                     p_m,
                                     'M',
                                     P_Tolerance,
                                     NULL,
                                     p_exception);
  End ST_Locate_Along_Measure;

  Function ST_Locate_Between_Measures(p_Geometry  In Mdsys.Sdo_Geometry,
                                      P_Start_M   In Number,
                                      p_End_M     In number,
                                      P_Tolerance In Number      Default 0.005,
                                      P_Exception In Pls_Integer Default 0 )
    Return Mdsys.Sdo_Geometry
  As
  Begin
      return &&defaultSchema..LINEAR.ST_Clip(p_Geometry,
                             P_Start_M,
                             P_End_M,
                             'M',
                             P_Tolerance,
                             null,
                             p_exception);
  End ST_Locate_Between_Measures;

  Procedure ST_Split_Geom_Segment( p_geom_segment  IN SDO_GEOMETRY,
                                   p_split_measure IN NUMBER,
                                   p_segment_1     OUT NOCOPY SDO_GEOMETRY,
                                   p_segment_2     OUT NOCOPY SDO_GEOMETRY)
  As
    v_geom1     mdsys.sdo_geometry;
    v_geom2     mdsys.sdo_geometry;
    v_end_point mdsys.sdo_geometry;
  Begin
    p_segment_1 := &&defaultSchema..LINEAR.ST_Clip(p_geom_segment,
                                          0,
                                          p_split_measure,
                                          'M');
    v_end_point := &&defaultSchema..LINEAR.ST_End_Point(p_geom_segment);
    p_segment_2 := &&defaultSchema..LINEAR.ST_Clip(p_geom_segment,
                                          p_split_measure,
                                          v_end_point.sdo_ordinates(v_end_point.sdo_ordinates.COUNT),
                                          'M');
  End ST_Split_Geom_Segment;
  
  Function ST_Split_Geom_Segment( p_geom_segment  IN SDO_GEOMETRY,
                                  p_split_measure IN NUMBER)
    Return &&defaultSchema..LINEAR.t_Geometries pipelined
  As
    v_geom1  mdsys.sdo_geometry;
    v_geom2  mdsys.sdo_geometry;
    v_end_pt mdsys.sdo_geometry;
  Begin
    v_end_pt := &&defaultSchema..LINEAR.ST_End_Point(p_geom_segment);
    v_geom1  := &&defaultSchema..LINEAR.ST_Clip(p_geom_segment,
                                       0, 
                                       p_split_measure,
                                       'M');
    v_geom2  := &&defaultSchema..LINEAR.ST_Clip(p_geom_segment,
                                       p_split_measure,
                                       v_end_pt.sdo_point.z,
                                       'M');
    PIPE ROW ( &&defaultSchema..T_Geometry(v_geom1));
    PIPE ROW ( &&defaultSchema..T_Geometry(v_geom2));
    RETURN;
  End ST_Split_Geom_Segment;
    
  Function ST_Concatenate_Geom_Segments(p_geom_segment_1 IN SDO_GEOMETRY,
                                        p_geom_segment_2 IN SDO_GEOMETRY,
                                        p_tolerance      IN NUMBER DEFAULT 1.0e-8) 
    Return mdsys.sdo_geometry 
  As
    v_geom     mdsys.sdo_geometry;
    v_meas_1   pls_integer;
    v_meas_2   pls_integer;
    v_gtype_1  pls_integer;
    v_gtype_2  pls_integer;
    v_dims_1   pls_integer;
    v_dims_2   pls_integer;
    v_offset   pls_integer;
    v_eoffset  pls_integer;
    v_start    pls_integer;
    v_m_delta  number := 0.0;
  begin
    If ( p_geom_segment_1 is null and p_geom_segment_2 is null ) Then
      Return Null;
    ElsIf ( p_geom_segment_1 is null ) Then
      Return p_geom_segment_2;
    ElsIf ( p_geom_segment_2 is null ) then
      Return p_geom_segment_1;
    End If;
    If ( ST_IsMeasured(p_geom_segment_1.sdo_gtype) = 0 Or
         ST_IsMeasured(p_geom_segment_2.sdo_gtype) = 0 ) Then
      Raise_Application_Error(-20001,'Both linestrings must be measured',True);
    End If;
    v_meas_1 := trunc(mod((p_geom_segment_1.sdo_gtype/100),10));
    v_meas_2 := trunc(mod((p_geom_segment_2.sdo_gtype/100),10));
    If ( NVL(p_geom_segment_1.sdo_srid,0) <> NVL(p_geom_segment_2.sdo_srid,0) ) Then
      Raise_Application_Error(-20001,'SRIDs are different',True);
    End If;
    v_dims_1  := p_geom_segment_1.Get_Dims();
    v_dims_2  := p_geom_segment_2.Get_Dims();
    If ( v_dims_1 <> v_dims_2 ) Then
      Raise_Application_Error(-20001,'Dimensions are different',True);
    End If;
    v_gtype_1 := p_geom_segment_1.Get_GType();
    IF ( v_gtype_1 not in (2,6) ) Then
       Raise_Application_Error(-20001,'Unsupported SDO_GTYPE (' || v_gtype_1 || ').',True);
    End If;
    v_gtype_2 := p_geom_segment_2.Get_GType();
    IF ( v_gtype_2 not in (2,6) ) Then
       Raise_Application_Error(-20001,'Unsupported SDO_GTYPE (' || v_gtype_2 || ').',True);
    End If;
    v_geom := mdsys.sdo_geometry(p_geom_segment_1.sdo_gtype,
                                 p_geom_segment_1.sdo_srid,
                                 NULL,
                                 mdsys.sdo_elem_info_array(0),
                                 mdsys.sdo_ordinate_array(0));
    v_geom.sdo_elem_info.TRIM(1);
    v_geom.sdo_ordinates.TRIM(1);
    -- Append Elem Info from first geom
    v_geom.sdo_elem_info.Extend(p_geom_segment_1.sdo_elem_info.COUNT);
    For i in 1..p_geom_segment_1.sdo_elem_info.COUNT Loop
        v_geom.sdo_elem_info(i) := p_geom_segment_1.sdo_elem_info(i);
    End Loop;
    -- Append sdo_ordinates from first geom
    v_offset := p_geom_segment_1.sdo_ordinates.COUNT;
    v_geom.sdo_ordinates.Extend(v_offset);
    For i in 1..p_geom_segment_1.sdo_ordinates.COUNT Loop
        v_geom.sdo_ordinates(i) := p_geom_segment_1.sdo_ordinates(i);
    End Loop;
    -- Now, check if first coord of second geometry = last coord of first
    v_start := 1;
    if ( /*X*/ p_geom_segment_1.sdo_ordinates(v_offset-(v_dims_1-1)) = p_geom_segment_2.sdo_ordinates(1) AND
         /*Y*/ p_geom_segment_1.sdo_ordinates(v_offset-(v_dims_1-2)) = p_geom_segment_2.sdo_ordinates(2) ) Then
       v_m_delta := p_geom_segment_2.sdo_ordinates(v_meas_2)  - 
                    p_geom_segment_1.sdo_ordinates(v_offset-(v_dims_1-v_meas_1));
       v_geom.sdo_ordinates(v_offset-(v_dims_1-v_meas_1)) := v_geom.sdo_ordinates(v_offset-(v_dims_1-v_meas_1)) + v_m_delta;
       v_start := v_dims_2 + 1;
    End If;
    -- Append Elem Info from second geom
    if ( v_start = 1 ) then
      v_offset  := v_geom.sdo_ordinates.COUNT;
      v_eoffset := v_geom.sdo_elem_info.COUNT;
      v_geom.sdo_elem_info.Extend(p_geom_segment_2.sdo_elem_info.COUNT);
      For i in 1..p_geom_segment_2.sdo_elem_info.COUNT Loop
          if ( mod(i,3)=1 ) Then
             v_geom.sdo_elem_info(v_eoffset + i) := v_offset + i;
          Else
             v_geom.sdo_elem_info(v_eoffset + i) := p_geom_segment_2.sdo_elem_info(i);
          End If;
      End Loop;
      v_geom.sdo_ordinates.Extend(p_geom_segment_2.sdo_ordinates.COUNT);
      For i in 1..p_geom_segment_2.sdo_ordinates.COUNT Loop
          v_geom.sdo_ordinates(v_offset + i) := p_geom_segment_2.sdo_ordinates(i);
      End Loop;
    Else
      v_offset  := v_geom.sdo_ordinates.COUNT;
      v_eoffset := v_geom.sdo_elem_info.COUNT;
      v_geom.sdo_elem_info.Extend(p_geom_segment_2.sdo_elem_info.COUNT-3);
      For i in 4..p_geom_segment_2.sdo_elem_info.COUNT Loop
          if ( mod(i,3)=1 ) Then
             v_geom.sdo_elem_info(v_eoffset + (i-3)) := v_offset + i;
          Else
             v_geom.sdo_elem_info(v_eoffset + (i-3)) := p_geom_segment_2.sdo_elem_info(i);
          End If;
      End Loop;
      v_geom.sdo_ordinates.Extend(p_geom_segment_2.sdo_ordinates.COUNT-v_dims_2);
      For i in (v_dims_2+1)..p_geom_segment_2.sdo_ordinates.COUNT Loop
          v_offset := v_offset + 1;
          v_geom.sdo_ordinates(v_offset) := p_geom_segment_2.sdo_ordinates(i);
      End Loop;
    End If;
    return v_geom;
  End ST_Concatenate_Geom_Segments;

  Function ST_Line_Substring(P_Geometry      In Mdsys.Sdo_Geometry,
                             P_Startfraction In Number,
                             P_EndFraction   In Number,
                             P_Tolerance     In Number      Default 0.005,
                             p_unit          in varchar2    default null,
                             P_Exception     In Pls_Integer Default 0 )
    Return Mdsys.Sdo_Geometry
  As
      v_length number;
  Begin
      V_Length := &&defaultSchema..Linear.Sdo_Length(P_Geometry,P_Tolerance,p_unit);
      Return &&defaultSchema..LINEAR.ST_Clip(P_Geometry,
                             V_Length * P_Startfraction,
                             V_Length * P_Endfraction,
                             'M',
                             P_Tolerance,
                             p_unit,
                             p_exception);
  End ST_Line_Substring;

  /**
  * ST_Locate_Along_Elevation
  * geometry ST_Locate_Along_Elevation(bytea Geometry, double Z)
  * Extracts Points from a Geometry object that have the specified z coordinate value.
  * Wrapper over: Locate_Point() with v_distance_type = Z
  */
  Function ST_Locate_Along_Elevation(P_Geometry  In Mdsys.Sdo_Geometry,
                                     p_Z         in Number,
                                     P_Tolerance In Number      Default 0.005,
                                     p_exception In Pls_Integer Default 0)
    Return Mdsys.Sdo_Geometry
  As
    v_dims                 pls_integer;
    v_gtype                pls_integer;
    v_elevation_difference number := 0.0;
    v_vertex               mdsys.vertex_type;
    v_vertices             mdsys.vertex_set_type;
    v_id                   pls_integer;
    v_element_no           pls_integer;
    v_num_elements         pls_integer;
    v_element              mdsys.sdo_geometry;
    v_return_points        mdsys.sdo_geometry;
    v_ratio                number;
    v_round_factor         number;
    NULL_GEOMETRY          EXCEPTION;
    START_NEGATIVE         EXCEPTION;
    END_NEGATIVE           EXCEPTION;
    START_NOT_ONLINE       EXCEPTION;
    END_NOT_ONLINE         EXCEPTION;
    NOT_A_LINE             EXCEPTION;
    NULL_TOLERANCE         EXCEPTION;
  Begin
    If ( P_Geometry is null ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NULL_GEOMETRY;
       Else
          return P_Geometry;
       End If;
    End If;
    v_gtype := p_geometry.get_gtype();
    If ( v_gtype not in (2,6) ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NOT_A_LINE;
       Else
          return null;
       End If;
    End If;
    If ( p_tolerance is Null ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NULL_TOLERANCE;
       Else
          return null;
       End If;
    End If;
    v_dims  := P_Geometry.Get_Dims();
    if ( v_dims > 3 ) Then
       v_dims := 3;
    End If;
    v_return_points := mdsys.sdo_geometry(p_geometry.sdo_gtype,
                                          p_geometry.sdo_srid,
                                          p_geometry.sdo_point,
                                          new mdsys.sdo_elem_info_array(1),
                                          new mdsys.sdo_ordinate_array(1));
    v_return_points.sdo_elem_info.DELETE;
    v_return_points.sdo_ordinates.DELETE;

    v_round_factor  := round(log(10,(1/p_tolerance)/2));
    v_num_elements  := mdsys.sdo_util.GetNumElem(P_Geometry);
    <<for_all_elements>>
    FOR v_element_no IN 1..v_num_elements LOOP
       if ( v_num_elements = 1 ) then
          v_element := p_geometry;
       else
          v_element  := mdsys.sdo_util.Extract(P_Geometry,v_element_no,0);   -- Extract element with all sub-elements
       end if;
       v_vertices := mdsys.sdo_util.getVertices(v_element);
       <<for_all_vectors>>
       FOR v_id in v_vertices.FIRST..(v_vertices.LAST-1) LOOP
           -- DEBUG logger('v_vertices(' || v_id || ') = ' ||  round(v_vertices(v_id).x,v_round_factor) || ',' || round(v_vertices(v_id).y,v_round_factor) || ',' || round(v_vertices(v_id).z,v_round_factor) );
           -- DEBUG logger('v_vertices(' || to_char(v_id+1) || ') = ' ||  round(v_vertices(v_id+1).x,v_round_factor) || ',' || round(v_vertices(v_id+1).y,v_round_factor) || ',' || round(v_vertices(v_id+1).z,v_round_factor)  );
           v_elevation_difference := v_vertices(v_id+1).z - v_vertices(v_id).z;
           if (  p_z between    least(v_vertices(v_id).Z,v_vertices(v_id+1).z)
                         and greatest(v_vertices(v_id).Z,v_vertices(v_id+1).z) ) Then
              -- Compute height ratio
              --
              if ( p_z <= v_vertices(v_id).Z
                   or
                   v_elevation_difference = 0 ) then
                v_ratio := 0;
              else
                v_ratio := ABS(( p_z - v_vertices(v_id).Z ) / v_elevation_difference);
              End If;
              -- Calculate position of Z value
              --
              ADD_Coordinate(v_return_points.sdo_ordinates,
                             v_dims,
                             round(v_vertices(v_id).x+(v_ratio*(v_vertices(v_id+1).x-v_vertices(v_id).x)),v_round_factor),
                             round(v_vertices(v_id).y+(v_ratio*(v_vertices(v_id+1).y-v_vertices(v_id).y)),v_round_factor),
                             p_z,
                             case when v_vertices(v_id).w is not null then (v_vertices(v_id).w+v_vertices(v_id+1).w)/2.0 else null end,
                             ST_getMeasureDimension(p_geometry.sdo_gtype));
           End If;
       END LOOP for_all_vectors;
    END LOOP for_all_elements;
    If ( v_return_points.sdo_ordinates.COUNT = 0 ) Then
       v_return_points := null;
    else
       v_return_points.sdo_elem_info := new mdsys.sdo_elem_info_array(1,1,v_return_points.sdo_ordinates.COUNT/v_dims);
       if ( v_return_points.sdo_elem_info(3) = 1 ) then
          v_return_points.sdo_gtype := p_geometry.sdo_gtype - p_geometry.get_gtype() + 1;
       else
          v_return_points.sdo_gtype := p_geometry.sdo_gtype - p_geometry.get_gtype() + 5;
       End If;
    End If;
    return v_return_points;

    Exception
      When NULL_GEOMETRY THEN
         raise_application_error(c_i_null_geometry,c_s_null_geometry,TRUE);
      WHEN NOT_A_LINE THEN
         raise_application_error(c_i_not_line,c_s_not_line || ' ' || v_gtype,TRUE);
      WHEN NULL_TOLERANCE THEN
         raise_application_error(c_i_null_tolerance,c_s_null_tolerance,TRUE);
      WHEN START_NEGATIVE THEN
         raise_application_error(c_i_split_start_negative,c_s_split_start_negative,true);
      WHEN END_NEGATIVE THEN
         raise_application_error(c_i_split_end_negative,c_s_split_end_negative,true);
      WHEN START_NOT_ONLINE THEN
         raise_application_error(c_i_split_start_not_online,c_s_split_start_not_online,true);
      WHEN END_NOT_ONLINE THEN
         raise_application_error(c_i_split_end_not_online,c_s_split_end_not_online,true);
  End ST_Locate_Along_Elevation;

  /**
  * ST_Locate_Between_Elevations
  * Geometry ST_Locate_Between_Elevations(Bytea Geometry, Double Start_Z, Double End_Z)
  * Returns A Derived Geometry Whose Elevation Are In The Specified Z Range.
  * Wrapper over
    Function Locate_Point(p_geometry      IN mdsys.sdo_geometry,
                          v_distance      IN NUMBER      DEFAULT NULL,
                          v_distance_type IN VARCHAR2    DEFAULT 'L', -- or 'M'
                          p_tolerance     IN NUMBER      DEFAULT 0.005,
                          p_exception     IN PLS_INTEGER DEFAULT 0)
      Return mdsys.sdo_geometry Deterministic;
  */
  Function ST_Locate_Between_Elevations(P_Geometry    In Mdsys.Sdo_Geometry,
                                        p_start_value IN NUMBER,
                                        P_End_Value   In Number,
                                        p_tolerance   IN NUMBER      DEFAULT 0.005,
                                        p_exception   IN PLS_INTEGER DEFAULT 0 )
    Return Mdsys.Sdo_Geometry
  As
    v_dims                 pls_integer;
    v_gtype                pls_integer;
    v_elevation_difference number := 0.0;
    v_vertices             mdsys.vertex_set_type;
    v_id                   pls_integer;
    v_vertex               mdsys.vertex_type;
    v_element_no           pls_integer;
    v_num_elements         pls_integer;
    v_element              mdsys.sdo_geometry;
    v_new_segment          mdsys.sdo_geometry;
    v_return_line          mdsys.sdo_geometry;
    v_ratio                number;
    v_round_factor         number;
    v_count_before         pls_integer;
    v_start_value          number  := least(p_start_value,p_end_value);
    v_end_value            number  := greatest(p_start_value,p_end_value);
    v_linear_segment       boolean := false;
    v_is_compound          boolean := false;
    NULL_GEOMETRY          EXCEPTION;
    START_NEGATIVE         EXCEPTION;
    END_NEGATIVE           EXCEPTION;
    START_NOT_ONLINE       EXCEPTION;
    END_NOT_ONLINE         EXCEPTION;
    NOT_A_LINE             EXCEPTION;
    NULL_TOLERANCE         EXCEPTION;
  Begin
    If ( P_Geometry is null ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NULL_GEOMETRY;
       Else
          return P_Geometry;
       End If;
    End If;
    v_gtype := p_geometry.get_gtype();
    If ( v_gtype not in (2,6) ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NOT_A_LINE;
       Else
          return null;
       End If;
    End If;
    If ( p_tolerance is Null ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NULL_TOLERANCE;
       Else
          return null;
       End If;
    End If;
    v_dims  := P_Geometry.Get_Dims();
    if ( v_dims > 3 ) Then
       v_dims := 3;
    End If;

    v_return_line  := null;
    v_round_factor := round(log(10,(1/p_tolerance)/2));
    v_num_elements := mdsys.sdo_util.GetNumElem(P_Geometry);
    <<for_all_elements>>
    FOR v_element_no IN 1..v_num_elements LOOP
       if ( v_num_elements = 1 ) then
          v_element := p_geometry;
       else
          v_element  := mdsys.sdo_util.Extract(P_Geometry,v_element_no,0);   -- Extract element with all sub-elements
       end if;
       v_vertices := mdsys.sdo_util.getVertices(v_element);
       v_new_segment := mdsys.sdo_geometry(p_geometry.sdo_gtype,
                                           p_geometry.sdo_srid,
                                           p_geometry.sdo_point,
                                           new mdsys.sdo_elem_info_array(),
                                           new mdsys.sdo_ordinate_array());
       <<for_all_vectors>>
       FOR v_id in v_vertices.FIRST..(v_vertices.LAST-1) LOOP
           -- DEBUG logger('LOOP: ' || v_id);
           v_elevation_difference := v_vertices(v_id+1).z - v_vertices(v_id).z;
           -- DEBUG logger('elev diff=' || v_elevation_difference);
           -- DEBUG logger('v_start_value ' || v_start_value || ' between ' || least(v_vertices(v_id).Z,v_vertices(v_id+1).z) || ' AND ' || greatest(v_vertices(v_id).Z,v_vertices(v_id+1).z) );
           if (  v_start_value between    least(v_vertices(v_id).Z,v_vertices(v_id+1).z)
                                   and greatest(v_vertices(v_id).Z,v_vertices(v_id+1).z) ) Then
              -- Compute height ratio
              --
              if ( v_start_value <= v_vertices(v_id).Z
                   or
                   v_elevation_difference = 0 ) then
                v_ratio := 0;
              else
                v_ratio := ABS(( v_start_value - v_vertices(v_id).Z ) / v_elevation_difference);
              End If;
              -- Calculate start coord
              --
              -- DEBUG  logger('START: Add_coord('||round(v_vertices(v_id).x+(v_ratio*(v_vertices(v_id+1).x-v_vertices(v_id).x)),v_round_factor) || ',' ||
              -- DEBUG        round(v_vertices(v_id).y+(v_ratio*(v_vertices(v_id+1).y-v_vertices(v_id).y)),v_round_factor) || ',' ||
              -- DEBUG        case when v_start_value <= v_vertices(v_id).Z then v_vertices(v_id).Z else v_start_value end || ')');
              v_count_before := v_new_segment.sdo_ordinates.COUNT;
              ADD_Coordinate(v_new_segment.sdo_ordinates,
                             v_dims,
                             round(v_vertices(v_id).x+(v_ratio*(v_vertices(v_id+1).x-v_vertices(v_id).x)),v_round_factor),
                             round(v_vertices(v_id).y+(v_ratio*(v_vertices(v_id+1).y-v_vertices(v_id).y)),v_round_factor),
                             case when v_start_value <= v_vertices(v_id).Z then v_vertices(v_id).Z else v_start_value end,
                             case when v_vertices(v_id).w is not null then (v_vertices(v_id).w+v_vertices(v_id+1).w)/2.0 else null end,
                             ST_getMeasureDimension(p_geometry.sdo_gtype));
              if ( v_count_before = v_new_segment.sdo_ordinates.COUNT ) Then
                 -- no point was added as it was a duplicate of what was already there
                 -- So no change to sdo_elem_info required
                 null;
              else
                 -- Is segment below end value then this is a single point
                 --
                 -- DEBUG logger('v_start_value ' || v_start_value || ' = greatest ' || greatest (v_vertices(v_id).Z,v_vertices(v_id+1).z));
                 if ( v_start_value = greatest(v_vertices(v_id).Z,v_vertices(v_id+1).z) ) Then
                     -- Add single point element info
                     --
                     v_linear_segment := false; -- We do not have the start of a linear segment
                     v_is_compound := true;
                     -- DEBUG logger('START: SINGLE POINT ADDED');
                     ADD_Element(v_new_segment.sdo_elem_info,
                                 new mdsys.sdo_elem_info_array(1,1,1),
                                 v_count_before);
                 -- A point has been added to existing or new element that is not a point
                 --
                 Else
                     v_linear_segment := true; -- We have located the start of a linear segment
                     If ( v_new_segment.sdo_elem_info.COUNT = 0 ) Then
                         -- DEBUG logger('ADD FIRST ELEM_INFO');
                         -- New sdo_elem_info needed
                         v_new_segment.sdo_elem_info := new mdsys.sdo_elem_info_array(1,2,1);
                     Else
                         -- DEBUG logger('another ELEM_INFO');
                         ADD_Element(v_new_segment.sdo_elem_info,
                                     new mdsys.sdo_elem_info_array(1,2,1),
                                     v_count_before);
                     End If;
                  End If;
              End If;
           End If;

           -- Now check end
           --
           -- DEBUG logger('v_end_value ' || v_end_value || ' between ' || least(v_vertices(v_id).Z,v_vertices(v_id+1).z) || ' and ' || greatest(v_vertices(v_id).Z,v_vertices(v_id+1).z));
           If ( v_end_value between    least(v_vertices(v_id).Z,v_vertices(v_id+1).z)
                                and greatest(v_vertices(v_id).Z,v_vertices(v_id+1).z) ) Then
              v_ratio := ABS((v_end_value - v_vertices(v_id).Z ) / v_elevation_difference);
              -- DEBUG logger('end ratio='||v_ratio);
              -- Calculate and add end coord
              --
              v_count_before := v_new_segment.sdo_ordinates.COUNT;
              ADD_Coordinate( v_new_segment.sdo_ordinates,
                              v_dims,
                              round(v_vertices(v_id).x+(v_ratio*(v_vertices(v_id+1).x-v_vertices(v_id).x)),v_round_factor),
                              round(v_vertices(v_id).y+(v_ratio*(v_vertices(v_id+1).y-v_vertices(v_id).y)),v_round_factor),
                              v_end_value,
                              case when v_vertices(v_id).w is not null then (v_vertices(v_id).w+v_vertices(v_id+1).w)/2.0 else null end,
                              ST_getMeasureDimension(p_geometry.sdo_gtype));
              -- end of this segment
              v_linear_segment := false;
              if ( v_count_before = v_new_segment.sdo_ordinates.COUNT ) Then
                 -- no point was added as it was a duplicate of what was already there
                 -- So no change to sdo_elem_info required
                 null;
              else
                 -- DEBUG logger('v_end_value ' || v_end_value || ' = least ' || least (v_vertices(v_id).Z,v_vertices(v_id+1).z));
                 if ( v_end_value = least(v_vertices(v_id).Z,v_vertices(v_id+1).z) ) Then
                     -- Add single point element info
                     --
                     v_is_compound := true;
                     -- DEBUG logger('END: SINGLE POINT ADDED');
                     ADD_Element(v_new_segment.sdo_elem_info,
                                 new mdsys.sdo_elem_info_array(1,1,1),
                                 v_count_before);
                 End If;
              End If;
           End If;

           -- If whole segment between elevations, add both vertices
           --
           If ( v_linear_segment
                and ( v_vertices(v_id).Z   between v_end_value and v_end_value
                      or
                      v_vertices(v_id+1).z between v_end_value and v_end_value ) )
           Then
              -- DEBUG logger('both in between');
              -- Add
              ADD_Coordinate( v_new_segment.sdo_ordinates,
                              v_dims,
                              v_vertices(v_id),
                              ST_isMeasured(p_geometry.sdo_gtype));
              ADD_Coordinate( v_new_segment.sdo_ordinates,
                              v_dims,
                              v_vertices(v_id+1),
                              ST_isMeasured(p_geometry.sdo_gtype));
           End If;
       END LOOP for_all_vectors;
       if ( v_new_segment is not null ) then
          if( v_return_line is null ) then
              v_return_line := v_new_segment;
          else
              v_return_line := mdsys.sdo_util.append(v_return_line,v_new_segment);
          End If;
       End If;
    END LOOP for_all_elements;
    If ( v_return_line is not null
         and v_is_compound ) Then
       v_return_line.sdo_gtype := p_geometry.sdo_gtype - p_geometry.get_gtype() + 4;
    End If;
    return v_return_line;

    Exception
      When NULL_GEOMETRY THEN
         raise_application_error(c_i_null_geometry,c_s_null_geometry,TRUE);
      WHEN NOT_A_LINE THEN
         raise_application_error(c_i_not_line,c_s_not_line || ' ' || v_gtype,TRUE);
      WHEN NULL_TOLERANCE THEN
         raise_application_error(c_i_null_tolerance,c_s_null_tolerance,TRUE);
      WHEN START_NEGATIVE THEN
         raise_application_error(c_i_split_start_negative,c_s_split_start_negative,true);
      WHEN END_NEGATIVE THEN
         raise_application_error(c_i_split_end_negative,c_s_split_end_negative,true);
      WHEN START_NOT_ONLINE THEN
         raise_application_error(c_i_split_start_not_online,c_s_split_start_not_online,true);
      WHEN END_NOT_ONLINE THEN
         raise_application_error(c_i_split_end_not_online,c_s_split_end_not_online,true);
  End ST_Locate_Between_Elevations;

  Function ST_Is_Measure_Increasing(p_geometry IN SDO_GEOMETRY) 
    RETURN VARCHAR2 
  Is
    v_vertices    mdsys.vertex_set_type;
    v_prev        number := c_MinVal;
    v_dims        pls_integer;
    v_measure_dim pls_integer;
    v_measure     number;
    NOT_MEASURED  EXCEPTION;
    NULL_GEOMETRY EXCEPTION;
    NOT_A_LINE    EXCEPTION;
  Begin
    If ( p_geometry is null ) Then
       raise NULL_GEOMETRY;
    End If;
    If ( p_geometry.get_gtype() not in (2,6) ) Then
       raise NOT_A_LINE;
    End If;
    v_measure_dim := ST_getMeasureDimension( p_geometry.sdo_gtype );
    If ( v_measure_dim not in (3,4) ) Then
       raise NOT_MEASURED;
    End If;
    v_vertices := sdo_util.getVertices(p_geometry);
    FOR i IN v_vertices.FIRST..v_vertices.LAST LOOP
       if ( v_measure_dim = 3 ) then 
          v_measure := v_vertices(i).z;
       else 
          v_measure := v_vertices(i).w;
       end if;
       if ( v_measure < v_prev ) then
          return 'FALSE';
       end If;
    END LOOP;
    RETURN 'TRUE';
  End ST_Is_Measure_Increasing;

  Function ST_Is_Measure_Decreasing(p_geometry IN SDO_GEOMETRY) 
    RETURN VARCHAR2 
  Is
  Begin
    RETURN case when ST_Is_Measure_Increasing(p_geometry) = 'TRUE' 
                then 'FALSE' 
                else 'TRUE' 
            end;
  End ST_Is_Measure_Decreasing;

  Function ST_Reset_Measure(p_geometry in mdsys.sdo_geometry) 
    Return mdsys.sdo_geometry 
  As
    V_Ordinates   mdsys.Sdo_Ordinate_Array;
    v_dim         pls_integer;
    v_measure_dim pls_integer;
    v_ord         number;
    NULL_GEOMETRY EXCEPTION;
    NOT_MEASURED  EXCEPTION;
    NOT_LINE      EXCEPTION;
  Begin
    If ( p_geometry is null ) Then
       RAISE NULL_GEOMETRY;
    End If;
    v_measure_dim := ST_getMeasureDimension(p_geometry.sdo_gtype);
    If ( v_measure_dim = 0 ) Then
       RAISE NOT_MEASURED;
    End If;
    If ( p_geometry.get_gtype() not in (2,6) ) Then
       raise NOT_LINE;
    End If;
    v_dim   := p_geometry.get_dims(); -- IF 9i then .... TRUNC(p_geometry.sdo_gtype/1000,0);
    IF ( p_geometry.sdo_ordinates is not null ) THEN
      v_ordinates   := new mdsys.sdo_ordinate_array(1);
      v_ordinates.DELETE;
      v_ordinates.EXTEND(p_geometry.sdo_ordinates.count);
      -- Process all coordinates
      <<while_vertex_to_process>>
      FOR v_i IN 1..(v_ordinates.COUNT/v_dim) LOOP
         v_ord := (v_i-1)*v_dim + 1;
         v_ordinates(v_ord) := p_geometry.sdo_ordinates(v_ord);
         v_ord := v_ord + 1; v_ordinates(v_ord) := p_geometry.sdo_ordinates(v_ord);
         if ( v_dim >= 3 ) Then
            v_ord := v_ord + 1;
            V_Ordinates(v_ord) := Case when v_measure_dim = 3 
                                       then NULL
                                       else p_geometry.sdo_ordinates(v_ord)
                                    End;
            if ( v_dim > 3 ) Then
               v_ord := v_ord + 1;
               v_ordinates(v_ord) := Case when v_measure_dim = 4 
                                          then NULL
                                          else p_geometry.sdo_ordinates(v_ord)
                                      End; 
            End If;
         End If;
      END LOOP while_vertex_to_process;
    END IF;
    RETURN mdsys.sdo_geometry(p_geometry.sdo_gtype,
                              p_geometry.sdo_srid,
                              p_geometry.sdo_point,
                              p_geometry.sdo_elem_info,
                              V_Ordinates);
    EXCEPTION
      WHEN NULL_GEOMETRY THEN
         raise_application_error(c_i_null_geometry,c_s_null_geometry,true);
      WHEN NOT_MEASURED THEN
         raise_application_error(c_i_not_measured,c_s_not_measured,true);
      WHEN NOT_LINE THEN
         raise_application_error(c_i_not_line,c_s_not_line,true);
  End ST_Reset_Measure;

  Function ST_Measure_Range(p_geometry IN SDO_GEOMETRY)
     Return Number 
  As
    v_s_measure   number;
    v_e_measure   number;
    v_s_vertex    mdsys.vertex_type;
    v_e_vertex    mdsys.vertex_type;
    v_measure_dim pls_integer;
    NOT_MEASURED  EXCEPTION;
    NULL_GEOMETRY EXCEPTION;
    NOT_A_LINE    EXCEPTION;
  Begin
    If ( p_geometry is null ) Then
       raise NULL_GEOMETRY;
    End If;
    If ( p_geometry.get_gtype() not in (2,6) ) Then
       raise NOT_A_LINE;
    End If;
    v_measure_dim := ST_getMeasureDimension( p_geometry.sdo_gtype );
    If ( v_measure_dim not in (3,4) ) Then
       raise NOT_MEASURED;
    End If;
    v_s_vertex := mdsys.sdo_util.getVertices(ST_Start_Point(p_geometry))(1);
    v_e_vertex := mdsys.sdo_util.getVertices(ST_End_Point(p_geometry))(1);
    v_s_measure := case v_measure_dim 
                   when 3 then v_s_vertex.z 
                   when 4 then v_s_vertex.w
                   end;
    v_e_measure := case v_measure_dim 
                   when 3 then v_e_vertex.z 
                   when 4 then v_e_vertex.w
                   end;
    return ( v_e_measure - v_s_measure);
    EXCEPTION
      WHEN NOT_MEASURED THEN
         raise_application_error(c_i_not_measured,c_s_not_measured,true);
      WHEN NULL_GEOMETRY THEN
       raise_application_error(c_i_null_geometry,c_s_null_geometry,true);
      When Not_A_Line Then
         raise_application_error(c_i_not_line,c_s_not_line || ' ' || p_geometry.get_gtype(),TRUE);
  End ST_Measure_Range;

  Function ST_Start_Measure(p_geometry IN SDO_GEOMETRY)
     Return Number 
  As
    v_dims        pls_integer;
    v_measure     number;
    v_measure_dim pls_integer;
    NOT_MEASURED  EXCEPTION;
    NULL_GEOMETRY EXCEPTION;
    NOT_A_LINE    EXCEPTION;
  Begin
    If ( p_geometry is null ) Then
       raise NULL_GEOMETRY;
    End If;
    If ( p_geometry.get_gtype() not in (2,6) ) Then
       raise NOT_A_LINE;
    End If;
    v_measure_dim := ST_getMeasureDimension( p_geometry.sdo_gtype );
    If ( v_measure_dim not in (3,4) ) Then
       raise NOT_MEASURED;
    End If;
    v_dims    := p_geometry.get_dims();
    v_measure := p_geometry.sdo_ordinates(v_measure_dim) /* first measure */;
    return v_measure;
    EXCEPTION
      WHEN NOT_MEASURED THEN
         raise_application_error(c_i_not_measured,c_s_not_measured,true);
      WHEN NULL_GEOMETRY THEN
       raise_application_error(c_i_null_geometry,c_s_null_geometry,true);
      When Not_A_Line Then
         raise_application_error(c_i_not_line,c_s_not_line || ' ' || p_geometry.get_gtype(),TRUE);
  End ST_Start_Measure;

  Function ST_End_Measure(p_geometry IN SDO_GEOMETRY)
     Return Number 
  As
    v_dims        pls_integer;
    v_measure     number;
    v_measure_dim pls_integer;
    NOT_MEASURED  EXCEPTION;
    NULL_GEOMETRY EXCEPTION;
    NOT_A_LINE    EXCEPTION;
  Begin
    If ( p_geometry is null ) Then
       raise NULL_GEOMETRY;
    End If;
    If ( p_geometry.get_gtype() not in (2,6) ) Then
       raise NOT_A_LINE;
    End If;
    v_measure_dim := ST_getMeasureDimension( p_geometry.sdo_gtype );
    If ( v_measure_dim not in (3,4) ) Then
       raise NOT_MEASURED;
    End If;
    v_dims    := p_geometry.get_dims();
    v_measure := p_geometry.sdo_ordinates(p_geometry.sdo_ordinates.COUNT-(v_dims-v_measure_dim));
    return v_measure;
    EXCEPTION
      WHEN NOT_MEASURED THEN
         raise_application_error(c_i_not_measured,c_s_not_measured,true);
      WHEN NULL_GEOMETRY THEN
       raise_application_error(c_i_null_geometry,c_s_null_geometry,true);
      When Not_A_Line Then
         raise_application_error(c_i_not_line,c_s_not_line || ' ' || p_geometry.get_gtype(),TRUE);
  End ST_End_Measure;
  
  Function ST_Measure_To_Percentage(p_geometry IN SDO_GEOMETRY,
                                    p_measure  IN NUMBER)
   Return Number 
  As
    v_max_measure number;
    v_s_measure   number;
    v_e_measure   number;
    v_s_vertex    mdsys.vertex_type;
    v_e_vertex    mdsys.vertex_type;
    v_measure_dim pls_integer;
    NOT_MEASURED  EXCEPTION;
    NULL_GEOMETRY EXCEPTION;
    NOT_A_LINE    EXCEPTION;
  Begin
    If ( p_geometry is null ) Then
       raise NULL_GEOMETRY;
    End If;
    If ( p_geometry.get_gtype() not in (2,6) ) Then
       raise NOT_A_LINE;
    End If;
    v_measure_dim := ST_getMeasureDimension( p_geometry.sdo_gtype );
    If ( v_measure_dim not in (3,4) ) Then
       raise NOT_MEASURED;
    End If;
    v_s_vertex := mdsys.sdo_util.getVertices(ST_Start_Point(p_geometry))(1);
    v_e_vertex := mdsys.sdo_util.getVertices(ST_End_Point(p_geometry))(1);
    v_s_measure := case v_measure_dim 
                   when 3 then v_s_vertex.z 
                   when 4 then v_s_vertex.w
                   end;
    v_e_measure := case v_measure_dim 
                   when 3 then v_e_vertex.z 
                   when 4 then v_e_vertex.w
                   end;
    v_max_measure := case when v_e_measure > v_s_measure
                          then v_e_measure
                          else v_s_measure
                      end;
    return ( NVL(p_measure,0) / v_max_measure ) * 100;
    EXCEPTION
      WHEN NOT_MEASURED THEN
         raise_application_error(c_i_not_measured,c_s_not_measured,true);
      WHEN NULL_GEOMETRY THEN
       raise_application_error(c_i_null_geometry,c_s_null_geometry,true);
      When Not_A_Line Then
         raise_application_error(c_i_not_line,c_s_not_line || ' ' || p_geometry.get_gtype(),TRUE);
  End ST_Measure_To_Percentage;

  Function ST_Percentage_To_Measure(p_geometry   IN SDO_GEOMETRY,
                                    p_percentage IN NUMBER)
   Return Number 
  As
  Begin
    Return (p_percentage / 100.0 ) * ST_Measure_Range(p_geometry);
  End ST_Percentage_To_Measure;
       
  Function ST_AddMeasure(p_geometry      in mdsys.sdo_geometry,
                         p_start_measure in number,
                         p_end_measure   in number,
                         p_tolerance     in number Default 0.005,
                         p_unit          IN VARCHAR2 Default NULL)
    Return mdsys.sdo_geometry
  Is
  Begin
    Return &&defaultSchema..LINEAR.Convert_to_lrs_geom(p_geometry,p_start_measure,p_end_measure,p_tolerance,p_unit);
  End ST_AddMeasure;

  Function ST_Reverse_Measure(p_geometry in mdsys.sdo_geometry)
     Return mdsys.sdo_geometry 
  Is
    v_ordinates   mdsys.sdo_ordinate_array;
    v_ord         pls_integer;
    v_dims        pls_integer;
    v_measure_dim pls_integer;
    v_vertex      pls_integer;
    v_vertices    mdsys.vertex_set_type;
    NOT_MEASURED  EXCEPTION;
    NULL_GEOMETRY EXCEPTION;
    NOT_A_LINE    EXCEPTION;
  Begin
    If ( p_geometry is null ) Then
       raise NULL_GEOMETRY;
    End If;
    If ( p_geometry.get_gtype() not in (2,6) ) Then
       raise NOT_A_LINE;
    End If;
    v_measure_dim := ST_getMeasureDimension( p_geometry.sdo_gtype );
    If ( v_measure_dim not in (3,4) ) Then
       raise NOT_MEASURED;
    End If;
    v_dims        := p_geometry.get_dims();
    v_vertices    := sdo_util.getVertices(p_geometry);
    v_ordinates   := new mdsys.sdo_ordinate_array(1);
    v_ordinates.DELETE;
    v_ordinates.EXTEND(p_geometry.sdo_ordinates.count);
    v_ord    := 1;
    v_vertex := v_vertices.LAST;
    WHILE (v_vertex >= 1 ) LOOP
        v_ordinates(v_ord) := p_geometry.sdo_ordinates(v_ord); v_ord := v_ord + 1;
        v_ordinates(v_ord) := p_geometry.sdo_ordinates(v_ord); v_ord := v_ord + 1;
        if ( v_measure_dim = 3 ) Then
           v_ordinates(v_ord) := v_vertices(v_vertex).z;       v_ord := v_ord + 1;
           if ( v_dims > 3 ) Then
              v_ordinates(v_ord) := p_geometry.sdo_ordinates(v_ord); v_ord := v_ord + 1;
           End If;
        ElsIf ( v_measure_dim = 4 ) Then
           v_ordinates(v_ord) := p_geometry.sdo_ordinates(v_ord); v_ord := v_ord + 1;
           v_ordinates(v_ord) := v_vertices(v_vertex).w;          v_ord := v_ord + 1;
        end if;
        v_vertex := v_vertex - 1;
    END LOOP;
    RETURN mdsys.sdo_geometry(p_geometry.sdo_gtype,
                              p_geometry.sdo_srid,
                              p_geometry.sdo_point,
                              p_geometry.sdo_elem_info,
                              v_ordinates);
    EXCEPTION
      WHEN NOT_MEASURED THEN
         raise_application_error(c_i_not_measured,c_s_not_measured,true);
      WHEN NULL_GEOMETRY THEN
       raise_application_error(c_i_null_geometry,c_s_null_geometry,true);
      When Not_A_Line Then
         raise_application_error(c_i_not_line,c_s_not_line || ' ' || p_geometry.get_gtype(),TRUE);
  End ST_Reverse_Measure;

  Function ST_Scale_Geom_Segment( p_geometry      IN mdsys.sdo_geometry,
                                  p_start_measure IN NUMBER,
                                  p_end_measure   IN NUMBER,
                                  p_shift_measure IN NUMBER DEFAULT 0.0 )
    Return mdsys.sdo_geometry 
  Is
    v_ordinates         mdsys.sdo_ordinate_array;
    v_ord               pls_integer;
    v_dims              pls_integer;
    v_measure_dim       pls_integer;
    v_vertex            pls_integer;
    v_num_vertices      pls_integer;
    v_shift_measure     pls_integer := NVL(p_shift_measure,0.0);
    v_delta_measure     number;
    v_measure_range     number;
    v_new_measure_range number;
    v_sum_new_measure   number := 0.0;
    NOT_MEASURED        EXCEPTION;
    NULL_GEOMETRY       EXCEPTION;
    NOT_A_LINE          EXCEPTION;
    MEASURE_ERROR       EXCEPTION;
  Begin
    If ( p_geometry is null ) Then
       raise NULL_GEOMETRY;
    End If;
    If ( p_geometry.get_gtype() not in (2,6) ) Then
       raise NOT_A_LINE;
    End If;
    v_measure_dim := ST_getMeasureDimension( p_geometry.sdo_gtype );
    If ( v_measure_dim not in (3,4) ) Then
       raise NOT_MEASURED;
    End If;
    If ( p_start_measure is null OR p_end_measure is null ) Then
       raise MEASURE_ERROR;
    End If;
    
    v_dims              := p_geometry.get_dims();
    v_new_measure_range := p_end_measure - p_start_measure;
    v_num_vertices      := sdo_util.GetNumVertices(p_geometry);
    v_measure_range     := p_geometry.sdo_ordinates(p_geometry.sdo_ordinates.COUNT-(v_dims-v_measure_dim)) /* Last measure */
                           -
                           p_geometry.sdo_ordinates(v_measure_dim)  /* first measure */;

    v_ordinates         := new mdsys.sdo_ordinate_array(1);
    v_ordinates.DELETE;
    v_ordinates.EXTEND(p_geometry.sdo_ordinates.count);
    v_ordinates(1) := p_geometry.sdo_ordinates(1);
    v_ordinates(2) := p_geometry.sdo_ordinates(2);
    if ( v_measure_dim = 3 ) Then
       v_ordinates(3) := p_start_measure;
       if ( v_dims > 3 ) Then
          v_ordinates(4) := p_geometry.sdo_ordinates(4);
       End If;
    ElsIf ( v_measure_dim = 4 ) Then
       v_ordinates(3) := p_geometry.sdo_ordinates(3);
       v_ordinates(4) := p_start_measure;
    end if;
    v_ord := v_dims + 1;
    
    FOR i IN 2..v_num_vertices LOOP
        v_ordinates(v_ord) := p_geometry.sdo_ordinates(v_ord); v_ord := v_ord + 1;
        v_ordinates(v_ord) := p_geometry.sdo_ordinates(v_ord); v_ord := v_ord + 1;
        v_delta_measure    := p_geometry.sdo_ordinates((i-1)*v_dims + v_measure_dim) - 
                              p_geometry.sdo_ordinates((i-2)*v_dims + v_measure_dim);
        v_sum_new_measure  := v_sum_new_measure + ( v_delta_measure / v_measure_range ) * v_new_measure_range;
        if ( v_measure_dim = 3 ) Then
           v_ordinates(v_ord) := p_start_measure + v_shift_measure + v_sum_new_measure; v_ord := v_ord + 1;
           if ( v_dims > 3 ) Then
              v_ordinates(v_ord) := p_geometry.sdo_ordinates(v_ord); v_ord := v_ord + 1;
           End If;
        ElsIf ( v_measure_dim = 4 ) Then
           v_ordinates(v_ord) := p_geometry.sdo_ordinates(v_ord); v_ord := v_ord + 1;  -- 3
           v_ordinates(v_ord) := p_start_measure + v_shift_measure + v_sum_new_measure; v_ord := v_ord + 1;
        end if;
    END LOOP;
    RETURN mdsys.sdo_geometry(p_geometry.sdo_gtype,
                              p_geometry.sdo_srid,
                              p_geometry.sdo_point,
                              p_geometry.sdo_elem_info,
                              v_ordinates);
    EXCEPTION
      WHEN NOT_MEASURED THEN
         raise_application_error(c_i_not_measured,c_s_not_measured,true);
      WHEN NULL_GEOMETRY THEN
       raise_application_error(c_i_null_geometry,c_s_null_geometry,true);
      When Not_A_Line Then
         raise_application_error(c_i_not_line,c_s_not_line || ' ' || p_geometry.get_gtype(),TRUE);
      When MEASURE_ERROR Then
         raise_application_error(c_i_start_end_measure,c_s_start_end_measure,TRUE);
         
  End ST_Scale_Geom_Segment;

  Function ST_Concat_Lines(p_lines IN &&defaultSchema..LINEAR.t_Geometries)
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
  End ST_Concat_Lines;

  Function ST_Project_Point(P_Line      In Mdsys.Sdo_Geometry,
                            P_Point     In Mdsys.Sdo_Geometry,
                            P_Tolerance In Number      Default 0.005,
                            p_unit      In varchar2    Default null,
                            p_exception In Pls_Integer Default 0)
   Return Mdsys.Sdo_Geometry
  As
  Begin
      Return &&defaultSchema..LINEAR.ST_Snap(P_Line,
                                    P_Point,
                                    P_Tolerance,
                                    p_unit,
                                    p_exception);
  End ST_Project_Point;
  
  /* ===================== SDO_LRS Wrapper Function ================== */

  Function Project_PT(geom_segment IN SDO_GEOMETRY,
                      point        IN SDO_GEOMETRY,
                      tolerance    IN NUMBER DEFAULT 1.0e-8,
                      unit         IN VARCHAR2 DEFAULT NULL
                    /* NO OFFSET AS IS FUNCTION */ ) 
    Return Mdsys.Sdo_Geometry
  As
  Begin
      Return &&defaultSchema..Linear.ST_Snap(geom_segment,
                                    point,
                                    tolerance,
                                    unit,
                                    0);
  End Project_PT;

   Function Define_Geom_Segment (geom_segment  IN SDO_GEOMETRY,
                                 start_measure IN NUMBER,
                                 end_measure   IN NUMBER,
                                 p_tolerance   IN NUMBER   Default 0.005,
                                 p_unit        in varchar2 default null)
    Return sdo_geometry Deterministic
  As
  Begin
    Return &&defaultSchema..LINEAR.Convert_to_lrs_geom(geom_segment,start_measure,end_measure,p_tolerance,p_unit);
  End Define_Geom_Segment;

  Function convert_to_lrs_geom(p_geometry      IN mdsys.sdo_geometry,
                               p_start_measure IN NUMBER   Default NULL,
                               p_end_measure   IN NUMBER   Default NULL,
                               p_tolerance     IN NUMBER   Default 0.005,
                               p_unit          in varchar2 default null)
    return mdsys.sdo_geometry
  As
    v_extract_geom   mdsys.sdo_geometry;
    v_dims           pls_integer;
    v_dim_z          pls_integer;
    v_new_dims       pls_integer;
    v_gtype          pls_integer;
    v_new_gtype      pls_integer;
    v_num_elements   pls_integer;
    v_ordinates      mdsys.sdo_ordinate_array;
    v_ordinate       pls_integer;
    v_elem_info      mdsys.sdo_elem_info_array;
    v_vertices       mdsys.vertex_set_type;
    v_total_vertices pls_integer;
    v_start_coord    mdsys.vertex_type;
    v_end_coord      mdsys.vertex_type;
    v_measure_per_m  number;
    v_has_measure    boolean;
    v_has_z          boolean;
    v_length         number;
    v_measure        number;
    v_cum_length     number;
    v_prev_posn      pls_integer;
    v_start          number;
    v_end            number;
    v_round_factor   number := case when p_tolerance is null
                                    then null
                                    else round(log(10,(1/p_tolerance)/2))
                                end;
  Begin
    IF ( p_geometry is null ) Then
       return p_geometry;
    End If;

    If ( p_start_measure Is Null Or p_end_measure Is Null ) Then
       return p_geometry;
    END IF;

    v_dims        := p_geometry.get_dims();
    v_new_dims    := case v_dims when 2 then 3 when 3 then 4 else v_dims end;
    v_gtype       := p_geometry.get_gtype();
    IF ( v_gtype not in (2,6) ) Then
       return p_geometry;
    End If;
    v_has_measure := CASE WHEN MOD(trunc(v_gtype/100),10) = 0 THEN False ELSE True END;
    v_has_z       := CASE WHEN v_dims > 2 AND MOD(trunc(v_gtype/100),10) = 0 THEN TRUE ELSE False END;
    v_dim_z       := CASE WHEN v_dims > 2 AND v_has_z THEN 3001 ELSE 2001 END;
    v_new_gtype   := ( v_new_dims * 1000 ) +
                     ( CASE WHEN v_has_z AND v_has_measure THEN MOD(trunc(v_gtype/100),10)
                            WHEN v_has_z THEN ( v_dims + 1 )
                            ELSE 3
                        END * 100 ) +
                     v_gtype;

    v_total_vertices := mdsys.sdo_util.getNumVertices(p_geometry);
    v_length         := &&defaultSchema..LINEAR.sdo_length( p_geometry, p_tolerance, p_unit );
    if ( v_length = 0 ) then
       return p_geometry;
    End If;
    v_measure_per_m  := ( ( p_end_measure - p_start_measure ) / v_length );

    v_ordinates      := new mdsys.sdo_ordinate_array(null);
    v_ordinates.DELETE;
    v_ordinates.EXTEND(p_geometry.sdo_ordinates.COUNT + v_total_vertices  );

    v_ordinate     := 1;
    v_cum_length   := 0;
    v_start        := p_start_measure;
    v_measure      := 0;
    v_num_elements := mdsys.sdo_util.GetNumElem(p_geometry);
    <<for_all_elements>>
    FOR v_element IN 1..v_num_elements LOOP
        v_extract_geom  := mdsys.sdo_util.Extract(p_geometry,v_element);   -- Extract element with all sub-elements
        v_vertices      := mdsys.sdo_util.getVertices(v_extract_geom);
        v_end           := v_start + ROUND( v_measure_per_m * &&defaultSchema..LINEAR.sdo_length( v_extract_geom, p_tolerance, p_unit ),v_round_factor);
        <<for_all_vertices>>
        FOR i IN 1..v_vertices.COUNT LOOP
            v_ordinates(v_ordinate) := v_vertices(i).x; v_ordinate := v_ordinate + 1;
            v_ordinates(v_ordinate) := v_vertices(i).y; v_ordinate := v_ordinate + 1;
            if ( v_has_z ) then
                v_ordinates(v_ordinate) := v_vertices(i).z; v_ordinate := v_ordinate + 1;
            end if;
            -- Compute new Measure
            --
            If ( i = 1 ) Then
               v_measure := v_start;
            ElsIf ( i = v_vertices.COUNT ) Then
               v_measure := v_end;
            Else
              -- Proportion everything else
              --
dbms_output.put_line('i=' || i || ' totalVertices='||v_vertices.COUNT || ' SRID=' || NVL(P_Geometry.Sdo_Srid,-999) || ' v_dim_z='||v_dim_z);
              v_cum_length := v_cum_length +
                     round(LINEAR.sdo_distance(
                               mdsys.sdo_geometry(v_dim_z,
                                                  P_Geometry.Sdo_Srid,
                                                  sdo_point_type(v_vertices(i).x,v_vertices(i).y,case when v_dim_z = 2001 then null else v_vertices(i).z end),
                                                  null,null),
                               mdsys.sdo_geometry(v_dim_z,
                                                  P_Geometry.Sdo_Srid,
                                                  Sdo_Point_Type(v_vertices(i+1).X,v_vertices(i+1).Y,case when v_dim_z = 2001 then null else v_vertices(i+1).z end),
                                                  null,null),
                               p_tolerance,p_unit),
                          v_round_factor);
              v_measure := case when p_end_measure is null then p_start_measure
                                when v_length >= 0 then p_start_measure + round( v_measure_per_m * v_cum_length,v_round_factor)
                                else p_start_measure
                            end;
            End If;
            -- Assign measure
            v_ordinates(v_ordinate) := v_measure; v_ordinate := v_ordinate + 1;
        END LOOP for_all_vertices;
        v_start := v_measure;
    END LOOP for_all_elements;
    -- Fix elem_info_array
    --
    v_elem_info := new mdsys.sdo_elem_info_array(p_geometry.sdo_elem_info.count);
    v_elem_info.DELETE; v_elem_info.EXTEND(p_geometry.sdo_elem_info.COUNT);
    v_prev_posn := 1;
    FOR i IN 1..p_geometry.sdo_elem_info.COUNT LOOP
        v_elem_info(i) := p_geometry.sdo_elem_info(i);
        IF ( i > 1 AND MOD(i,3) = 1 ) THEN
           v_elem_info(i) := v_elem_info(i) + (( v_elem_info(i) - v_prev_posn ) / v_dims );
        END IF;
    NULL;
    END LOOP;
    return mdsys.sdo_geometry(v_new_gtype,p_geometry.sdo_srid,null,v_elem_info,v_ordinates);
  End Convert_to_lrs_geom;

  Function Clip_Geom_Segment(p_lrs_line      in mdsys.sdo_geometry,
                             p_current_start in number,
                             p_window_start  in number,
                             p_tolerance     IN NUMBER      DEFAULT 0.005,
                             p_unit          in varchar2    default null,
                             p_exception     in pls_integer DEFAULT 0)
    Return mdsys.sdo_geometry
  Is
  Begin
      return &&defaultSchema..LINEAR.ST_Clip(p_lrs_line,
                                      p_current_start,
                                      p_window_start,
                                      p_tolerance,
                                      p_unit);
  End Clip_Geom_Segment;

  Function Offset_Geom_Segment(p_geometry      IN SDO_GEOMETRY,
                               p_start_measure IN NUMBER,
                               p_end_measure   IN NUMBER,
                               p_offset        IN NUMBER,
                               p_tolerance     IN NUMBER DEFAULT 1.0e-8,
                               p_unit          IN VARCHAR2 DEFAULT NULL)
     Return SDO_Geometry 
  Is
     v_segment mdsys.sdo_geometry;
     v_offset  mdsys.sdo_geometry;
  Begin
    -- First cut out the segment
    --
    v_segment := &&defaultSchema..LINEAR.ST_Clip(p_geometry    => p_geometry,
                                        p_start_value => p_start_measure,
                                        P_End_Value   => p_end_measure,
                                        p_value_type  => 'M',
                                        P_Tolerance   => p_tolerance,
                                        p_unit        => p_unit,
                                        p_exception   => 0);
    if ( v_segment is not null ) then
      -- Now, offset the returned segment
      --
      v_offset := &&defaultSchema..LINEAR.ST_Parallel(p_geometry  => v_segment,
                                             p_distance  => 0-p_offset,
                                             p_tolerance => p_tolerance,
                                             p_curved    => 0,
                                             p_unit      => p_unit);
      return v_offset;
    Else
       return null;
    End If;
  End Offset_Geom_Segment;

  Function geom_segment_length(p_geometry  in mdsys.sdo_geometry,
                                  p_tolerance in number default 0.005,
                                  p_unit      in varchar2 default null)
    Return Number
  Is
  Begin
      return &&defaultSchema..LINEAR.sdo_length(p_geometry,p_tolerance,p_unit);
  End geom_segment_length;
  
  /* Additional Utility Functions */

  Function sdo_length(p_geometry  in mdsys.sdo_geometry,
                      p_tolerance in number   default 0.05,
                      p_unit      in varchar2 default 'Meter' )
    Return Number
  Is
    v_length       number;
    v_i            pls_integer;
    v_num_rings    pls_integer;
    v_num_elements pls_integer;
    v_element_no   pls_integer;
    v_element      mdsys.sdo_geometry;
    v_ring         mdsys.sdo_geometry;
    v_unit         varchar2(100) := case when ( p_geometry is null or p_geometry.sdo_srid is null )
                                         Then NULL
                                         Else case when SUBSTR(UPPER(p_unit),1,4) like 'UNIT%'
                                                   then p_unit
                                                   else case when p_unit is null
                                                             then null
                                                             else 'unit='||p_unit
                                                         end
                                               end
                                     end;

    Function ComputeLength (p_geometry  in mdsys.sdo_geometry,
                            p_tolerance in number default 0.005 )
      Return Number
    Is
      v_length   number := 0.0;
      v_vertex   mdsys.vertex_type;
      v_vertices mdsys.vertex_set_type;
    Begin
      v_vertices := mdsys.sdo_util.getVertices(p_geometry);
      if ( v_vertices is null ) Then
         v_length := 0.0;
      Else
         v_vertex := v_vertices(1);
         for v_i in 2..v_vertices.COUNT loop
             v_length := v_length +
                         LINEAR.sdo_distance(
                                mdsys.sdo_geometry(2001,p_geometry.sdo_srid,mdsys.sdo_point_type(v_vertex.x,v_vertex.y,null),null,null),
                                mdsys.sdo_geometry(2001,p_geometry.sdo_srid,mdsys.sdo_point_type(v_vertices(v_i).x,v_vertices(v_i).y,null),null,null),
                                p_tolerance,v_unit);
             v_vertex := v_vertices(v_i);
         end loop;
      End If;
      return v_length;
    End ComputeLength;

  Begin
    -- If the input geometry is null, just return null
    IF ( p_geometry IS NULL ) THEN
      RETURN NULL;
    END IF;

    -- Only process linestrings and polygons
    --
    If ( p_geometry.get_gtype() not in (2,6,3,7) ) Then
      RETURN NULL;
    End If;

    If ( ST_hasCircularArcs(p_geometry.sdo_elem_info) ) then
        return null;
    End If;

    v_num_elements := mdsys.sdo_util.GetNumElem(p_geometry);
    v_length := 0.0;
    <<for_all_elements>>
    FOR v_element_no IN 1..v_num_elements LOOP
       v_element := mdsys.sdo_util.Extract(p_geometry,v_element_no);   -- Extract element with all sub-elements
       If ( v_element.get_gtype() = 2 ) Then
          v_length := v_length + ComputeLength(v_element,p_tolerance);
       Else
          v_num_rings := ST_GetNumRings(v_element);
          <<for_all_rings>>
          FOR v_i in 1..v_num_rings Loop
               v_ring := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_element_no,v_i);  -- Extract ring from element .. must do it this way, can't correctly extract from v_element.
              If (ST_hasRectangles(v_ring.sdo_elem_info)>0 ) Then
                 v_length := v_length + ComputeLength(Rectangle2Polygon(v_ring),p_tolerance);
              else
                 v_length := v_length + ComputeLength(v_ring,p_tolerance);
              End If;
          End Loop for_all_rings;
       End If;
    END LOOP for_all_elements;
    return v_length;
    exception
       when others then
          return null;
  End sdo_length;

  Function sdo_length( p_geometry in mdsys.sdo_geometry,
                       p_diminfo  in mdsys.sdo_dim_array,
                       p_unit     in varchar2 := 'Meter' )
    Return number
  Is
    v_tolerance number;
  Begin
    if ( p_geometry is null or p_diminfo is null ) then
       return null;
    End If;
    if ( p_diminfo.COUNT = 0 ) Then
       v_tolerance := 0.05;
    else
       v_tolerance := p_diminfo(1).sdo_tolerance;
    end if;
    return &&defaultSchema..LINEAR.sdo_length(p_geometry,v_tolerance,p_unit);
  End sdo_length;

  Function Generate_Series(p_start pls_integer,
                           p_end   pls_integer,
                           p_step  pls_integer )
       Return &&defaultSchema..LINEAR.t_integers Pipelined
  As
    v_i PLS_INTEGER := p_start;
  Begin
     while ( v_i <= p_end) Loop
       PIPE ROW ( v_i );
       v_i := v_i + p_step;
     End Loop;
     Return;
  End Generate_Series;
  
  Function Tokenizer(p_string     In VarChar2,
                     p_separators In VarChar2 DEFAULT ' ')
    Return &&defaultSchema..T_Tokens Pipelined
  As
    v_tokens &&defaultSchema..T_Tokens;
  Begin
    if ( p_string is null 
         or
         p_separators is null ) then
       return;
    end if;
    With myCTE As (
       Select c.beg, c.sep, Row_Number() Over(Order By c.beg Asc) rid
         From (Select b.beg, c.sep
                 From (Select Level beg
                         From dual
                        Connect By Level <= length(p_string)
                      ) b,
                      (Select SubStr(p_separators,level,1) as sep
                        From dual
                        Connect By Level <= length(p_separators)
                      ) c
                Where instr(c.sep,substr(p_string,b.beg,1)) >0
               Union All Select 0, cast(null as varchar2(10)) From dual
             ) c
    )
    Select &&defaultSchema..T_Token(Row_Number() Over (Order By a.rid ASC), 
                           Case When Length(a.token) = 0 Then NULL Else a.token End, 
                           a.sep) as token
      Bulk Collect Into v_tokens
      From (Select d.rid,
                   SubStr(p_string, 
                          (d.beg + 1), 
                          (Lead(d.beg,1) Over (Order By d.rid Asc) - d.beg - 1) ) as token,
                   Lead(d.sep,1) Over (Order By d.rid asc) as sep
              From MyCTE d 
           ) a
     Where Length(a.token) <> 0 or Length(a.sep) <> 0;
    FOR v_i IN v_tokens.first..v_tokens.last loop  
       PIPE ROW(v_tokens(v_i));
    END LOOP;
    RETURN;
  End Tokenizer;

  Function TokenAggregator(p_tokens    IN  &&defaultSchema..T_Tokens,
                           p_delimiter IN  VARCHAR2 DEFAULT ',')
    Return VarChar2
  Is
    l_string     VARCHAR2(32767);
  Begin
    IF ( p_tokens is null ) THEN
        Return NULL;
    END IF;
    FOR i IN p_tokens.FIRST .. p_tokens.LAST LOOP
      IF i <> p_tokens.FIRST THEN
        l_string := l_string || p_delimiter;
      END IF;
      l_string := l_string || p_tokens(i).token;
    END LOOP;
    Return l_string;
  End TokenAggregator;

END LINEAR;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'LINEAR';
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

grant execute on LINEAR to public;

EXIT;
