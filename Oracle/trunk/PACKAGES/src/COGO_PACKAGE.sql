DEFINE Default_Schema='&1'

SET VERIFY OFF;

SET SERVEROUTPUT ON
ALTER SESSION SET plsql_optimize_level=1;

CREATE OR REPLACE PACKAGE COGO
AUTHID CURRENT_USER
As

    /** Declare Public constants
    * @constant cPI The value of PI - is in Constants package
    * @constant cMAX Maximum number storable in NUMBER
    */
    c_ELLIPSOID_ID   CONSTANT VARCHAR2(100) := 'ELLIPSOID_ID';
    c_ELLIPSOID_NAME CONSTANT VARCHAR2(100) := 'ELLIPSOID_NAME';
    c_SRID           CONSTANT VARCHAR2(100) := 'SRID';

    /** Inspector function to return constant values in SQL SElect statements
    */
    FUNCTION ELLIPSOID_ID
      RETURN VARCHAR2;
    FUNCTION ELLIPSOID_NAME
      RETURN VARCHAR2;
    FUNCTION SRID
      RETURN VARCHAR2;

    /** Allows controlling program to set Degree Symbol for use in DD2DMS
    * @param p_Symbol A single character added as suffix to degrees value in DD2DMS
    */
    Procedure SetDegreeSymbol( p_Symbol In NVarChar2 );

    /** Allows controlling program to set Minutes Symbol for use in DD2DMS
    * @param p_Symbol A single character added as suffix to minutes value in DD2DMS
    */
    Procedure SetMinuteSymbol( p_Symbol In NVarChar2 );

    /** Allows controlling program to set Seconds Symbol for use in DD2DMS
    * @param p_Symbol A single character added as suffix to seconds value in DD2DMS
    */
    Procedure SetSecondSymbol( p_Symbol In NVarChar2 );

    /* ----------------------------------------------------------------------------------------
    * @function   : PointFromBearingAndDistance
    * @precis     : Returns point shape from starting E,N and bearing and distance.
    * @version    : 1.0
    * @usage      : FUNCTION PointFromBearindAndDistance (
    *                                        dStartE in number,
    *                                        dStartN in number,
    *                                        dBearing in number,
    *                                        dDistance in number )
    *                        RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;
    *               eg :new.shape := &&Default_Schema..COGO.PointFromBearingAndDistance(300000,5245000,225,45.56);
    * @param      : dStartE     : Reference point's easting
    * @paramtype  : dStartE     : NUMBER
    * @param      : dStartN     : Reference point's northing
    * @paramtype  : dStartN     : NUMBER
    * @param      : dBearing    : Whole circle bearing from start point to new point
    * @paramtype  : dBearing    : NUMBER
    * @param      : dDistance   : Distance from N,E to new point
    * @paramtype  : dDistance   : NUMBER
    * @return     : EndPoint    : The new point from the start.
    * @rtnType    : EndPoint    : MDSYS.SDO_GEOMETRY
    * @note       : Does not throw exceptions for dBearing not between 0 - 360
    * @note       : Assumes dBearing is a whole-cirle bearing.
    * @note       : Assumes planar projection eg UTM.
    * @history    : Simon Greener - Feb 2005 - Original coding.
    */
    FUNCTION PointFromBearingAndDistance ( dStartE in number,
                                           dStartN in number,
                                           dBearing in number,
                                           dDistance in number )
             RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;

    /* ----------------------------------------------------------------------------------------
    * @function   : RelativeLine
    * @precis     : Returns simple 2 vertex line whose first vertex is defined as a bearing and
    *               distance from a known point and whose second vertex is via a bearing and
    *               distance from the first point.
    * @version    : 1.0
    * @usage      : FUNCTION RelativeLine ( dStartE        in number,
    *                                       dStartN        in number,
    *                                       dBearingStart  in number,
    *                                       dDistanceStart in number,
    *                                       dBearingEnd    in number,
    *                                       dDistanceEnd   in number )
    *                        RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;
    *               eg :new.shape := &&Default_Schema..COGO.RelativeLine(300000,5245000,225,45.56,45,100);
    * @param      : dStartE        : Reference point's easting
    * @paramtype  : dStartE        : NUMBER
    * @param      : dStartN        : Reference point's northing
    * @paramtype  : dStartN        : NUMBER
    * @param      : dBearingStart  : Whole circle bearing from start point to first vertex
    * @paramtype  : dBearingStart  : NUMBER
    * @param      : dDistanceStart : Distance from start point to first vertex
    * @paramtype  : dDistanceStart : NUMBER
    * @param      : dBearingEnd    : Whole circle bearing from first to the second vertex.
    * @paramtype  : dBearingEnd    : NUMBER
    * @param      : dDistanceEnd   : Distance from first vertex to the second vertex.
    * @paramtype  : dDistanceEnd   : NUMBER
    * @return     : Linestring     : The actual line as a linestring.
    * @rtnType    : Linestring     : MDSYS.SDO_GEOMETRY
    * @note       : Does not throw exceptions for bearings not between 0 - 360
    * @note       : Assumes Bearings are whole-cirle bearing.
    * @note       : Assumes planar projection eg UTM.
    * @uses       : GIS.COGO.POINTFROMBEARINGANDDISTANCE()
    * @history    : Simon Greener - Feb 2005 - Original coding.
    */
    Function RelativeLine( dStartX        In Number,
                           dStartY        In Number,
                           dBearingStart  In Number,
                           dDistanceStart In Number,
                           dBearingEnd    In Number,
                           dDistanceEnd   In Number)
             Return MDSYS.SDO_GEOMETRY Deterministic;

    /* ----------------------------------------------------------------------------------------
    * @function   : CreateCircle
    * @precis     : Returns 2003 Circle sdo_geometry from Centre XY and Radius
    * @version    : 1.0
    * @usage      : FUNCTION CreateCircle ( dCentreX in number,
    *                                         dCentreY in number,
    *                                         dRadius in number )
    *                        RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;
    *               eg :new.shape := &&Default_Schema..COGO.CreateCircle(300000,52450000,100);
    * @param      : dCentreX    : X Ordinate of centre of Circle
    * @paramtype  : dCentreX    : NUMBER
    * @param      : dCentreY    : Y Ordinate of centre of Circle
    * @paramtype  : dCentreY    : NUMBER
    * @param      : dRadius     : Radius of Circle
    * @paramtype  : dRadius     : NUMBER
    * @return     : CircleShape : Circle as 2003 object with interpretation 4
    * @rtnType    : CircleShape : MDSYS.SDO_GEOMETRY
    * @note       : Does not throw exceptions
    * @note       : Assumes planar projection eg UTM.
    * @history    : Simon Greener - Mar 2005 - Original coding.
    */
    Function CreateCircle(dCentreX in Number,
                          dCentreY in Number,
                          dRadius in Number)
             Return MDSYS.SDO_GEOMETRY Deterministic;

    /* ----------------------------------------------------------------------------------------
    * @function   : FindCircle
    * @precis     : Finds Circle's centre X and Y and Radius from three points
    * @version    : 1.1
    * @usage      : procedure FindCircle
    *                         (
    *                             p_X1     in number, p_Y1 in number,
    *                             p_X2     in number, p_Y2 in number,
    *                             p_X3     in number, p_Y3 in number,
    *                             p_CX     out number,
    *                             p_CY     out number,
    *                             p_Radius out number
    *                         );
    *               eg &&Default_Schema..COGO.FindCircle(299900,5245000,
    *                                          300000,5245100,
    *                                          300100,5245000,
    *                                          centreX,centreY,Radius);
    * @param      : p_X1     : X ordinate of first point on circle
    * @paramtype  : p_X1     : NUMBER
    * @param      : p_Y1     : Y ordinate of first point on circle
    * @paramtype  : p_Y1     : NUMBER
    * @param      : p_X2     : X ordinate of second point on circle
    * @paramtype  : p_X2     : NUMBER
    * @param      : p_Y2     : Y ordinate of second point on circle
    * @paramtype  : p_Y2     : NUMBER
    * @param      : p_X3     : X ordinate of third point on circle
    * @paramtype  : p_X3     : NUMBER
    * @param      : p_Y3     : Y ordinate of third point on circle
    * @paramtype  : p_Y3     : NUMBER
    * @return     : p_CX     : X ordinate of centre of circle
    * @rtnType    : p_CX     : NUMBER
    * @return     : p_CY     : Y ordinate of centre of circle
    * @rtnType    : p_CY     : NUMBER
    * @return     : p_Radius : Radius of circle
    * @rtnType    : p_Radius : NUMBER
    * @note       : Throw exception if three points don't define circle.
    * @note       : Assumes planar projection eg UTM.
    * @history    : Simon Greener - Feb 2005 - Original coding.
    */
    procedure FindCircle ( p_X1     in number, p_Y1 in number,
                           p_X2     in number, p_Y2 in number,
                           p_X3     in number, p_Y3 in number,
                           p_CX     out number,
                           p_CY     out number,
                           p_Radius out number);

    /* ----------------------------------------------------------------------------------------
    * @function   : FindCircle
    * @precis     : Finds Circle's centre X and Y and Radius from three points returning True
    *               if circle could be computed, False otherwise.
    * @note       : See procedure FindCircle documentation for data types etc of parameters.
    * @note       : Does not throw an exception.
    * @history    : Simon Greener - Jul 2006 - Original coding.
    */
    function FindCircle(   p_X1     in number, p_Y1 in number,
                           p_X2     in number, p_Y2 in number,
                           p_X3     in number, p_Y3 in number,
                           p_CX     in out nocopy number,
                           p_CY     in out nocopy number,
                           p_Radius in out nocopy number)
             Return Boolean Deterministic;

    procedure FindCircle ( pot_Pt1    in &&Default_Schema..T_Vertex,
                           pot_Pt2    in &&Default_Schema..T_Vertex,
                           pot_Pt3    in &&Default_Schema..T_Vertex,
                           pot_Centre out nocopy &&Default_Schema..T_Vertex,
                           p_Radius   out nocopy number);

    Function FindCircle ( pot_Pt1    in  &&Default_Schema..T_Vertex,
                          pot_Pt2    in  &&Default_Schema..T_Vertex,
                          pot_Pt3    in  &&Default_Schema..T_Vertex,
                          pot_Centre out nocopy &&Default_Schema..T_Vertex,
                          p_Radius   out nocopy number)
             Return Boolean Deterministic;

    function FindCircle (pot_Pt1    in  mdsys.VERTEX_TYPE,
                         pot_Pt2    in  mdsys.VERTEX_TYPE,
                         pot_Pt3    in  mdsys.VERTEX_TYPE)
      return mdsys.sdo_point_type deterministic;

    function FindCircle (p_polygon in mdsys.sdo_geometry)
      return mdsys.sdo_point_type deterministic;

    /**
    * @function   : Circle2Polygon
    * @precis     : Returns 2003 Polygon shape from Circle Centre XY and Radius
    * @version    : 1.0
    * @usage      : FUNCTION Circle2Polygon ( dCentreX in number,
    *                                         dCentreY in number,
    *                                         dRadius in number,
    *                                         iSegments in INTEGER )
    *                        RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;
    *               eg :new.shape := &&Default_Schema..COGO.Circle2Polygon(300000,52450000,100,360);
    * @param      : dCentreX    : X Ordinate of centre of Circle
    * @paramtype  : dCentreX    : NUMBER
    * @param      : dCentreY    : Y Ordinate of centre of Circle
    * @paramtype  : dCentreY    : NUMBER
    * @param      : dRadius     : Radius of Circle
    * @paramtype  : dRadius     : NUMBER
    * @param      : iSegments   : Number of arc (chord) segments in circle (+ve clockwise, -ve anti-clockwise)
    * @paramtype  : iSegments   : INTEGER
    * @return     : PolyShape   : Circle as 2003 polyon
    * @rtnType    : PolyShape   : MDSYS.SDO_GEOMETRY
    * @note       : Does not throw exceptions
    * @note       : Assumes planar projection eg UTM.
    * @history    : Simon Greener  - Feb 2005 - Original coding.
    */
    Function Circle2Polygon( dCentreX in number,
                             dCentreY in number,
                             dRadius in number,
                             iSegments in integer)
             Return MDSYS.SDO_GEOMETRY DETERMINISTIC;

    /** ----------------------------------------------------------------------------------------
    * @function   : CircularArc2Line
    * @precis     : Returns Polyline shape from Circular Arc with Start XY, End XY and Centre XY and Radius
    * @version    : 1.0
    * @usage      : FUNCTION CircularArc2Line( dStart   in &&Default_Schema..ST_Point,
    *                                          dMid     in &&Default_Schema..ST_Point,
    *                                          dEnd     in &&Default_Schema..ST_Point,
    *                                          p_Arc2Chord in number := 0.1 )
    *                        RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;
    *               eg :new.shape := &&Default_Schema..COGO.CircularArc2Line(ST_Point(10,14), ST_Point(6,10), ST_Point(14,10), 0.5);
    * @param      : dStart     : Start point for the Circular Arc
    * @paramtype  : dStart     : &&Default_Schema..ST_Point
    * @param      : dMid       : Middle point for the Circular Arc
    * @paramtype  : dMid       : &&Default_Schema..ST_Point
    * @param      : dEnd       : Coordinate of the end point for the Circular Arc
    * @paramtype  : dEnd       : &&Default_Schema..ST_Point
    * @param      : p_Arc2Chord : Arc to chord separation distance for calculating vertices
    * @paramtype  : p_Arc2Chord : NUMBER
    * @return     : PolyShape   : Circular Arc as polyline
    * @rtnType    : PolyShape   : MDSYS.SDO_GEOMETRY
    * @note       : Does not throw exceptions
    * @note       : Assumes planar projection eg UTM.
    * @history    : Simon Greener - Feb 2005 - Original coding.
    * @history    : Simon Greener - Jan 2008 - Made function more standalone by incorporating code from GF package.
    *                                           Made attempt to fix rotation issues (still work in progress).
    * @history    : Simon Greener - Feb 2008 - Support for Z and measures added.
    */
    Function CircularArc2Line(dStart   in &&Default_Schema..ST_Point,
                              dMid     in &&Default_Schema..ST_Point,
                              dEnd     in &&Default_Schema..ST_Point,
                              p_Arc2Chord in number  := 0.1 )
             Return MDSYS.SDO_GEOMETRY DETERMINISTIC;

    /** Alternate Bindings
    */
    Function CircularArc2Line(dStart   in &&Default_Schema..T_Vertex,
                              dMid     in &&Default_Schema..T_Vertex,
                              dEnd     in &&Default_Schema..T_Vertex,
                              p_Arc2Chord in number  := 0.1 )
             Return MDSYS.SDO_GEOMETRY DETERMINISTIC;

    /**
    * @usage      : FUNCTION CircularArc2Line( dStartX   in number,
    *                                          dStartY   in number,
    *                                          dMidX     in number,
    *                                          dMidY     in number,
    *                                          dEndX     in number,
    *                                          dEndY     in number,
    *                                          p_Arc2Chord in number := 0.1 )
    *                        RETURN MDSYS.SDO_GEOMETRY DETERMINISTIC;
    *               eg :new.shape := &&Default_Schema..COGO.CircularArc2Line(10,14, 6,10, 14,10, 0.5);
    * @param      : dStartX     : X Ordinate of the start point for the Circular Arc
    * @paramtype  : dStartX     : NUMBER
    * @param      : dStartY     : Y Ordinate of the start point for the Circular Arc
    * @paramtype  : dStartY     : NUMBER
    * @param      : dMidX       : X Ordinate of the middle point for the Circular Arc
    * @paramtype  : dMidX       : NUMBER
    * @param      : dMidY       : Y Ordinate of the middle point for the Circular Arc
    * @paramtype  : dMidY       : NUMBER
    * @param      : dEndX       : X Ordinate of the end point for the Circular Arc
    * @paramtype  : dEndX       : NUMBER
    * @param      : dEndY       : Y Ordinate of the end point for the Circular Arc
    * @paramtype  : dEndY       : NUMBER
    */
    Function CircularArc2Line(dStartX     in number,
                              dStartY     in number,
                              dMidX       in number,
                              dMidY       in number,
                              dEndX       in number,
                              dEndY       in number,
                              p_Arc2Chord in number  := 0.1 )
             Return MDSYS.SDO_GEOMETRY DETERMINISTIC;

    /* ----------------------------------------------------------------------------------------
    * @function   : ComputeChordLength
    * @precis     : Returns the length of the chord for an angle given the radius
    * @version    : 1.0
    * @usage      : FUNCTION ComputeChordLength( dRadius in number,
    *                                            dAngle in number)
    *                        RETURN NUMBER DETERMINISTIC;
    *               eg :new.chordlength := &&Default_Schema..COGO.ComputeChordLength(100, 110);
    * @param      : dRadius     : Radius of Circle
    * @paramtype  : dRadius     : NUMBER
    * @param      : dAngle      : Angle inside
    * @paramtype  : dAngle      : NUMBER
    * @return     : ChordLength : the length of the chord in metres
    * @rtnType    : ChordLength : NUMBER
    * @note       : Does not throw exceptions
    * @note       : Assumes planar projection eg UTM.
    * @history    : Simon Greener - Feb 2005 - Original coding.
    */
    Function ComputeChordLength( dRadius in number,
                                 dAngle in number)
             Return Number Deterministic;

    /* ----------------------------------------------------------------------------------------
    * @function   : ComputeArcLength
    * @precis     : Returns the length of the Arc for an angle given the radius
    * @version    : 1.0
    * @usage      : FUNCTION ComputeArcLength( dRadius in number,
    *                                          dAngle in number)
    *                        RETURN NUMBER DETERMINISTIC;
    *               eg :new.arclength := &&Default_Schema..COGO.ComputeArcLength(100, 110);
    * @param      : dRadius     : Radius of Circle
    * @paramtype  : dRadius     : NUMBER
    * @param      : dAngle      : Angle inside
    * @paramtype  : dAngle      : NUMBER
    * @return     : ArcLength   : the length of the chord in metres
    * @rtnType    : ArcLength   : NUMBER
    * @note       : Does not throw exceptions
    * @note       : Assumes planar projection eg UTM.
    * @history    : Simon Greener  - Feb 2005 - Original coding.
    */
    Function ComputeArcLength( dRadius in number,
                               dAngle in number)
             Return Number Deterministic;

    /* ----------------------------------------------------------------------------------------
    * @function   : ArcToChordSeparation
    * @precis     : Returns the distance between the midpoint of the Arc and the Chord for an angle given the radius
    * @version    : 1.0
    * @usage      : FUNCTION ArcToChordSeparation( dRadius in number,
    *                                              dAngle in number)
    *                        RETURN NUMBER DETERMINISTIC;
    *               eg :new.sepearation := &&Default_Schema..COGO.ArcToChordSeparation(100, 110);
    * @param      : dRadius                : NUMBER : Radius of Circle
    * @param      : dAngle                 : NUMBER : Angle inside
    * @return     : ArcToChordSeparation   : NUMBER : the distance between the midpoint of the Arc and the Chord in metres
    * @note       : Does not throw exceptions
    * @note       : Assumes planar projection eg UTM.
    * @history    : Simon Greener  - Feb 2005 - Original coding.
    */
    Function ArcToChordSeparation( dRadius in number,
                                   dAngle in number )
             Return Number Deterministic;

    /* ----------------------------------------------------------------------------------------
    * @function   : OptimalCircleSegments
    * @precis     : Returns the optimal integer number of circle segments for an arc-to-chord
    *               separation given the radius
    * @version    : 1.0
    * @usage      : FUNCTION OptimalCircleSegments( dRadius in number,
    *                                               dArcToChordSeparation in number)
    *                        RETURN INTEGER DETERMINISTIC;
    *               eg :new.shape := &&Default_Schema..COGO.OptimalCircleSegments(100, 0.003);
    * @param      : dRadius               : NUMBER : Radius of Circle
    * @param      : dArcToChordSeparation : NUMBER : Distance between the midpoint of the Arc and the Chord in metres
    * @return     : OptimalCircleSegments : INTEGER : the optimal number of segments
    * @note       : Does not throw exceptions
    * @note       : Assumes planar projection eg UTM.
    * @history    : Simon Greener - Feb 2005 - Original coding.
    */
    Function OptimalCircleSegments( dRadius in number,
                                    dArcToChordSeparation in number)
    Return Integer Deterministic;

    /* ----------------------------------------------------------------------------------------
    * @function   : ArcTan2
    * @precis     : Returns the angle in Radians with tangent opp/hyp. The returned value is between PI and -PI
    * @version    : 1.0
    * @usage      : FUNCTION ArcTan2( dOpp in number,
    *                               dAdj in number)
    *                        RETURN NUMBER DETERMINISTIC;
    *               eg :new.shape := &&Default_Schema..COGO.ArcTan2(14 ,15);
    * @param      : dOpp    : NUMBER : Length of the vector perpendicular to two vectors (cross product)
    * @param      : dAdj    : NUMBER : Length of the calculated from the dot product of two vectors
    * @return     : ArcTan2 : NUMBER : the angle in Radians with tangent opp/hyp
    * @note       : Does not throw exceptions
    * @note       : Assumes planar projection eg UTM.
    * @history    : Steve Harwin - Feb 2005 - Original coding.
    */
    Function ArcTan2( dOpp in number,
                    dAdj in number)
             Return Number Deterministic;

    /* ----------------------------------------------------------------------------------------
    * @function   : CrossProductLength
    * @precis     : Return the cross product AB x BC, where a is Start, B is Centre and C is End.
    *               The cross product is a vector perpendicular to AB and BC having length |AB| * |BC| * Sin(theta)
    *               and with direction given by the right-hand rule.
    *               For two vectors in the X-Y plane, the result is a vector with X and Y components 0 so the Z
    *               component gives the vector's length and direction.
    * @version    : 1.0
    * @usage      : FUNCTION CrossProductLength( dStartX in number,
    *                                            dStartY in number,
    *                                            dCentreX in number,
    *                                            dCentreY in number,
    *                                            dEndX in number,
    *                                            dEndY in number)
    *                        RETURN NUMBER DETERMINISTIC;
    *               eg :new.shape := &&Default_Schema..COGO.CrossProductLength(299900, 5200000, 300000, 5200000, 300000, 5200100);
    * @param      : dStartX     : NUMBER : X Ordinate of the start point for the first vector
    * @param      : dStartY     : NUMBER : Y Ordinate of the start point for the first vector
    * @param      : dCentreX    : NUMBER : X Ordinate of the end point for the first vector and the start point for the second vector
    * @param      : dCentreY    : NUMBER : Y Ordinate of the end point for the first vector and the start point for the second vector
    * @param      : dEndX       : NUMBER : X Ordinate of the end point for the second vector
    * @param      : dEndY       : NUMBER : Y Ordinate of the end point for the second vector
    * @return     : CrossProductLength : NUMBER : the length of the vector perpendicular to the first and second vector
    * @note       : Does not throw exceptions
    * @note       : Assumes planar projection eg UTM.
    * @history    : Steve Harwin - Feb 2005 - Original coding.
    */
    Function CrossProductLength(dStartX in number,
                                dStartY in number,
                                dCentreX in number,
                                dCentreY in number,
                                dEndX in number,
                                dEndY in number)
             Return Number Deterministic;

    /* ----------------------------------------------------------------------------------------
    * @function   : DotProduct
    * @precis     : Return the dot product AB . BC, where a is Start, B is Centre and C is End..
    *               Note that AB . BC = |AB| * |BC| * Cos(theta).
    * @version    : 1.0
    * @usage      : FUNCTION DotProduct( dStartX in number,
    *                                    dStartY in number,
    *                                    dCentreX in number,
    *                                    dCentreY in number,
    *                                    dEndX in number,
    *                                    dEndY in number)
    *                        RETURN NUMBER DETERMINISTIC;
    *               eg :new.shape := &&Default_Schema..COGO.DotProduct(299900, 5200000, 300000, 5200000, 300000, 5200100);
    * @param      : dStartX    : NUMBER : X Ordinate of the start point for the first vector
    * @param      : dStartY    : NUMBER : Y Ordinate of the start point for the first vector
    * @param      : dCentreX   : NUMBER : X Ordinate of the end point for the first vector and the start point for the second vector
    * @param      : dCentreY   : NUMBER : Y Ordinate of the end point for the first vector and the start point for the second vector
    * @param      : dEndX      : NUMBER : X Ordinate of the end point for the second vector
    * @param      : dEndY      : NUMBER : Y Ordinate of the end point for the second vector
    * @return     : DotProduct : NUMBER : the dot product AB . BC
    * @note       : Does not throw exceptions
    * @note       : Assumes planar projection eg UTM.
    * @history    : Steve Harwin - Feb 2005 - Original coding.
    */
    Function DotProduct(dStartX in number,
                        dStartY in number,
                        dCentreX in number,
                        dCentreY in number,
                        dEndX in number,
                        dEndY in number)
             Return Number Deterministic;

    Function isGeographic( p_SRID in number )
             Return Boolean Deterministic;

    /* ----------------------------------------------------------------------------------------
    * @function   : AngleBetween3Points
    * @precis     : Return the angle in Radians. Returns a value between PI and -PI.
    * @version    : 1.0
    * @usage      : FUNCTION AngleBetween3Points( dStartX in number,
    *                                             dStartY in number,
    *                                             dCentreX in number,
    *                                             dCentreY in number,
    *                                             dEndX in number,
    *                                             dEndY in number)
    *                        RETURN NUMBER DETERMINISTIC;
    *               eg :new.shape := &&Default_Schema..COGO.AngleBetween3Points(299900, 5200000, 300000, 5200000, 300000, 5200100);
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
    Function AngleBetween3Points( dStartX in number,
                                  dStartY in number,
                                  dCentreX in number,
                                  dCentreY in number,
                                  dEndX in number,
                                  dEndY in number)
             Return Number Deterministic;

    /* ----------------------------------------------------------------------------------------
    * @function   : Bearing
    * @precis     : Returns a value between 0 and 2*PI representing the bearing
    *               North = 0, East = PI/2, South = PI, West = 3*PI/4
    *               To convert to degrees multiply by (180/PI).
    * @version    : 1.0
    * @usage      : FUNCTION Bearing( dE1 in number,
    *                                 dN1 in number,
    *                                 dE2 in number,
    *                                 dN2 in number)
    *                        RETURN NUMBER DETERMINISTIC;
    *               eg :new.shape := &&Default_Schema..COGO.Bearing(299900, 5200000, 300000, 5200100);
    * @param      : dE1     : NUMBER : X Ordinate of the start point for the vector
    * @param      : dN1     : NUMBER : Y Ordinate of the start point for the vector
    * @param      : dE2     : NUMBER : X Ordinate of the end point for the vector
    * @param      : dN2     : NUMBER : Y Ordinate of the end point for the vector
    * @return     : Bearing : NUMBER : the angle in radians between 0 and 2*PI representing the bearing
    * @note       : Does not throw exceptions
    * @note       : Assumes planar projection eg UTM.
    * @history    : Simon Greener - Feb 2005 - Original coding.
    */
    Function Bearing( dE1 in number,
                      dN1 in number,
                      dE2 in number,
                      dN2 in number)
             Return Number Deterministic;

    /** Alternate binding: 1
    */
    Function Bearing( startCoord in mdsys.sdo_point_type,
                        endCoord in mdsys.sdo_point_type)
             Return Number Deterministic;

    /** Alternate binding: 2
    */
    Function Bearing( p_startCoord in mdsys.sdo_point_type,
                        p_endCoord in mdsys.sdo_point_type,
                     p_planar_srid in number,
                 p_geographic_srid in number := 8311
	                  )
     Return Number Deterministic;

    /* Alternate binding for SQL/MM
    */
    Function ST_Azimuth( p_startCoord in &&Default_Schema..ST_Point,
                         p_endCoord   in &&Default_Schema..ST_Point)
      Return Number Deterministic;

    Function GreatCircleBearing ( p_lon1 in number,
                                  p_lat1 in number,
                                  p_lon2 in number,
                                  p_lat2  in number)
             Return number deterministic;

    /* ----------------------------------------------------------------------------------------
    * @function   : Distance
    * @precis     : Returns the distance between (dE1,dN1) and (dE2,dN2).
    * @version    : 1.0
    * @usage      : FUNCTION Distance( dE1 in number,
    *                                  dN1 in number,
    *                                  dE2 in number,
    *                                  dN2 in number)
    *                        RETURN NUMBER DETERMINISTIC;
    *               eg :new.shape := &&Default_Schema..COGO.Distance(299900, 5200000, 300000, 5200100);
    * @param      : dE1      : NUMBER : X Ordinate of the start point for the vector
    * @param      : dN1      : NUMBER : Y Ordinate of the start point for the vector
    * @param      : dE2      : NUMBER : X Ordinate of the end point for the vector
    * @param      : dN2      : NUMBER : Y Ordinate of the end point for the vector
    * @return     : Distance : NUMBER : the length in metres of the vector between (dE1,dN1) and (dE2,dN2)
    * @note       : Does not throw exceptions
    * @note       : Assumes planar projection eg UTM.
    * @history    : Simon Greener - Feb 2005 - Original coding.
    */
    Function Distance( dE1 in number,
                       dN1 in number,
                       dE2 in number,
                       dN2 in number)
             Return Number Deterministic;

    /** @note       : Overload of Distance()
    */
    Function Distance( p_startCoord in mdsys.sdo_point_type,
                         p_endCoord in mdsys.sdo_point_type)
             Return Number Deterministic;

    Function Distance( p_frst_vertex IN &&Default_Schema..ST_Point,
                       p_last_vertex IN &&Default_Schema..ST_Point,
                       p_srid        IN number,
                       p_tolerance   IN number)
             Return Number Deterministic;

    /** @note  : Projects any geographic data to planar projection before calling Distance.
    */
    Function Distance(    p_startCoord in mdsys.sdo_point_type,
                            p_endCoord in mdsys.sdo_point_type,
	             p_geographic_srid in number := 8311,
	                   p_tolerance in number := 0.05 )
             Return Number Deterministic;

    /** @note : A version that does not require use of sdo_geom.sdo_distance()
    */
  function GreatCircleDistance( p_lon1              in number,
                                p_lat1              in number,
                                p_lon2              in number,
                                p_lat2              in number,
                                p_equatorial_radius in number default null,
                                p_flattening        in number default null)
      	     Return number deterministic;

    /** @note : Overload of GreatCircleDistance.
    */
  function GreatCircleDistance( p_lon1           in number,
                                p_lat1           in number,
                                p_lon2           in number,
                                p_lat2           in number,
                                p_ref_type       in varchar2,
                                p_ref_id         in number,
                                p_ellipsoid_name in varchar2 default null)
             Return number deterministic;

    Function DD2DMS( dDecDeg in number)
             Return varchar2 Deterministic;

    Function DMS2DD( dDeg in number,
                     dMin in number,
                     dSec in number)
             Return Number Deterministic;

    Function DD2DMS( dDecDeg in Number,
                     pDegree in NVarChar2,
                     pMinute in NVarChar2,
                     pSecond in NVarChar2 )
             Return varchar2 Deterministic;

    Function DMS2DD(strDegMinSec in varchar2)
             Return Number deterministic;

  Function Latitude( p_deg in pls_integer,
                     p_min in pls_integer,
                     p_sec in pls_integer,
                     p_sgn in pls_integer)
           Return number Deterministic;

  Function Longitude( p_deg in pls_integer,
                      p_min in pls_integer,
                      p_sec in pls_integer,
                      p_sgn in pls_integer)
    Return Number Deterministic;

    /* ----------------------------------------------------------------------------------------
    * @function   : FindLineIntersection
    * @precis     : Find the point where two vectors intersect.
    * @version    : 1.0
    * @usage      : PROCEDURE FindLineIntersection(x11 in number, y11 in number,
    *                                              x12 in Single, y12 in Single,
    *                                              x21 in Single, y21 in Single,
    *                                              x22 in Single, y22 in Single,
    *                                              inter_x  OUT Single, inter_y  OUT Single,
    *                                              inter_x1 OUT Single, inter_y1 OUT Single,
    *                                              inter_x2 OUT Single, inter_y2 OUT Single );
    * @param      : x11     : NUMBER : X Ordinate of the start point for the first vector
    * @param      : y11     : NUMBER : Y Ordinate of the start point for the first vector
    * @param      : x12     : NUMBER : X Ordinate of the end point for the first vector
    * @param      : y12     : NUMBER : Y Ordinate of the end point for the first vector
    * @param      : x21     : NUMBER : X Ordinate of the start point for the second vector
    * @param      : y21     : NUMBER : Y Ordinate of the start point for the second vector
    * @param      : x22     : NUMBER : X Ordinate of the end point for the second vector
    * @param      : y22     : NUMBER : Y Ordinate of the end point for the second vector
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
    Procedure FindLineIntersection(
      x11       in number,        y11       in number,
      x12       in number,        y12       in number,
      x21       in number,        y21       in number,
      x22       in number,        y22       in number,
      inter_x  out nocopy number, inter_y  out nocopy number,
      inter_x1 out nocopy number, inter_y1 out nocopy number,
      inter_x2 out nocopy number, inter_y2 out nocopy number );

  /*
  *      degrees   - returns radians converted to degrees
  */
  Function degrees(p_radians in number)
    return number deterministic;

  /*
  *      radians     - returns radians converted from degrees
  */
  Function radians(p_degrees in number)
    Return number deterministic;


  Function createPolygonFromCogo(p_start_point            in sdo_geometry,
                                 p_bearings_and_distances in tbl_bearing_distances,
                                 p_round_xy               in integer default 3 )
    Return sdo_geometry deterministic;

  Function CreateLineFromCogo(p_start_point            in sdo_geometry,
                              p_bearings_and_distances in tbl_bearing_distances,
                              p_round_xy               in integer default 3,
                              p_round_z                in integer default 2
                             )
    Return sdo_geometry deterministic;

END COGO;
/
show errors

CREATE OR REPLACE PACKAGE BODY COGO 
AS

    -- Private constants
    --
    c_i_circle_error CONSTANT NUMBER        := -20101;
    c_s_circle_error CONSTANT VARCHAR2(100) := 'Three points are collinear and no finite-radius circle through them exists';
    c_i_not_radians  CONSTANT NUMBER        := -20102;
    c_s_not_radians  CONSTANT VarChar2(100) := 'Supplied longitude/latitude not in radians.';
    c_i_null_srid    CONSTANT NUMBER        := -20103;
    c_s_null_srid    CONSTANT VARCHAR2(100) := 'Supplied srid or ellipsoid id is null';
    c_i_srid_not_geo CONSTANT NUMBER        := -20104;
    c_s_srid_not_geo CONSTANT VARCHAR2(100) := 'SRID reference is not geographic';
    sDegreeSymbol    NCHAR(1) := '^';
    sMinuteSymbol    NCHAR(1) := '''';
    sSecondSymbol    NCHAR(1) := '"';

    -- Private Types
    --
    TYPE STRINGARRAY is table of varchar2(2048) ;

    -- ----------------------------------------------------------------------------------------
    -- @function   : StrTok
    -- @precis     : Simple string tokeniser.
    -- @version    : 1.0
    -- @usage      : function StrTok(
    --                                p_str in varchar2,
    --                                p_delim in varchar2
    --                              )
    --                        return stringarray deterministic;
    --               eg tokens := StrTok('299900, 5200000, 300000, 5200100',' ,');
    -- @param      : p_Str   : String containing tokens for extraction.
    -- @paramtype  : p_Str   : string.
    -- @param      : p_delim : String containg one or more token separators.
    -- @paramtype  : p_Delim : String
    -- @return     : Tokens  : A list of tokens (string).
    -- @rtnType    : Tokens  : Table of tokens (like a varray).
    -- @note       : Does not throw exceptions
    -- @history    : Simon Greener, Feb 2005 - Original coding.
    --
    FUNCTION strtok(p_str in varchar2, p_delim in varchar2)
       RETURN STRINGARRAY
       DETERMINISTIC
      IS
        v_numtok  number;
        v_length  number;
        v_outside number;
        v_char    char(1);
        v_strtok_vals STRINGARRAY;
      BEGIN
        -- initialise strtok_vals array
        v_strtok_vals := STRINGARRAY('');
        v_numtok := 0;
        v_length := length(p_str);
        v_outside := 1;
        FOR i in 1..v_length loop
         v_char := SUBSTR(p_str,i,1);
         IF instr(p_delim, v_char) <> 0 then
           -- outside
           v_outside := 1;
           v_strtok_vals.EXTEND;
           v_strtok_vals(v_strtok_vals.LAST) := '';
         else
           -- inside
           if (v_outside = 1) then
             v_numtok := v_numtok + 1;
           end if;
           v_strtok_vals(v_strtok_vals.LAST) := v_strtok_vals(v_strtok_vals.LAST) || v_char;
           v_outside := 0;
         end if;
       END LOOP;
       -- Return value
       RETURN v_strtok_vals;
    END strtok;

    -- Properties
    FUNCTION ELLIPSOID_NAME
      RETURN VARCHAR2
    IS
    BEGIN
       RETURN &&Default_Schema..COGO.c_ELLIPSOID_NAME;
    END ELLIPSOID_NAME;

    FUNCTION ELLIPSOID_ID
      RETURN VARCHAR2
    IS
    BEGIN
       RETURN &&Default_Schema..COGO.c_ELLIPSOID_ID;
    END ELLIPSOID_ID;

    FUNCTION SRID
      RETURN VARCHAR2
    IS
    BEGIN
       RETURN &&Default_Schema..COGO.c_SRID;
    END SRID;

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
            dAngle1Rad := dAngle1 * &&Default_Schema..CONSTANTS.c_PI / 180;
            dDeltaE := Cos(dAngle1Rad) * dDistance;
            dDeltaN := Sin(dAngle1Rad) * dDistance;
        ElsIf dBearing < 180 Then
            dAngle1 := dBearing - 90;
            dAngle1Rad := dAngle1 * &&Default_Schema..CONSTANTS.c_PI / 180;
            dDeltaE := Cos(dAngle1Rad) * dDistance;
            dDeltaN := Sin(dAngle1Rad) * dDistance * -1;
        ElsIf dBearing < 270 Then
            dAngle1 := 270 - dBearing;
            dAngle1Rad := dAngle1 * &&Default_Schema..CONSTANTS.c_PI / 180;
            dDeltaE := Cos(dAngle1Rad) * dDistance * -1;
            dDeltaN := Sin(dAngle1Rad) * dDistance * -1;
        ElsIf dBearing <= 360 Then
            dAngle1 := dBearing - 270;
            dAngle1Rad := dAngle1 * &&Default_Schema..CONSTANTS.c_PI / 180;
            dDeltaE := Cos(dAngle1Rad) * dDistance * -1;
            dDeltaN := Sin(dAngle1Rad) * dDistance;
        End If;
        -- Calculate the easting and northing of the end point
        dEndE := dDeltaE + dStartE;
        dEndN := dDeltaN + dStartN;
      RETURN MDSYS.SDO_GEOMETRY(2001,NULL,MDSYS.SDO_POINT_TYPE(dEndE,dEndN,NULL),NULL,NULL);
    END PointFromBearingAndDistance;

    function CreateCircle(dCentreX in Number,
                          dCentreY in Number,
                          dRadius in Number)
    return mDSYS.sdo_geometry
    IS
      dPnt1X NUMBER;
      dPnt1Y NUMBER;
      dPnt2X NUMBER;
      dPnt2Y NUMBER;
      dPnt3X NUMBER;
      dPnt3Y NUMBER;
    BEGIN
      -- Compute three points on the circle's circumference
      dPnt1X := dCentreX - dRadius;
      dPnt1Y := dCentreY;
      dPnt2X := dCentreX + dRadius;
      dPnt2Y := dCentreY;
      dPnt3X := dCentreX;
      dPnt3Y := dCentreY + dRadius;
      RETURN MDSYS.SDO_GEOMETRY(2003,NULL,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,4),MDSYS.SDO_ORDINATE_ARRAY(dPnt1X, dPnt1Y, dPnt2X, dPnt2Y, dPnt3X, dPnt3Y));
    End;

    -- More robust function version.
    --
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

    procedure FindCircle
        (
            p_X1     in number, p_Y1 in number,
            p_X2     in number, p_Y2 in number,
            p_X3     in number, p_Y3 in number,
            p_CX     out number,
            p_CY     out number,
            p_Radius out number
        )
    is
      bFindCircle  BOOLEAN;
    begin
      bFindCircle := FindCircle(p_X1,p_Y1,
	                        p_X2,p_Y2,
				p_X3,p_Y3,
				p_CX,p_CY,p_Radius );
      If (bFindCircle = False) Then
         raise_application_error(c_i_circle_error,c_s_circle_error,False);
      End If;
    end FindCircle;

    procedure FindCircle
        (
            pot_Pt1    in &&Default_Schema..T_Vertex,
            pot_Pt2    in &&Default_Schema..T_Vertex,
            pot_Pt3    in &&Default_Schema..T_Vertex,
            pot_Centre out nocopy &&Default_Schema..T_Vertex,
            p_Radius   out nocopy number
        )
    Is
      bFindCircle Boolean;
    begin
      bFindCircle := FindCircle(pot_Pt1.x,pot_Pt1.y,
	                        pot_Pt2.X,pot_Pt2.y,
				pot_Pt3.X,pot_Pt3.y,
                                pot_Centre.x,pot_Centre.Y,p_Radius );
      If (bFindCircle = False) Then
         raise_application_error(c_i_circle_error,c_s_circle_error,False);
      End If;
    end FindCircle;

    -- Function version of above
    --
    function FindCircle
           (
            pot_Pt1    in  &&Default_Schema..T_Vertex,
            pot_Pt2    in  &&Default_Schema..T_Vertex,
            pot_Pt3    in  &&Default_Schema..T_Vertex,
            pot_Centre out nocopy &&Default_Schema..T_Vertex,
            p_Radius   out nocopy number
            )
            return boolean
    Is
    begin
      Return FindCircle(pot_Pt1.x,pot_Pt1.y,
	                pot_Pt2.X,pot_Pt2.y,
			pot_Pt3.X,pot_Pt3.y,
                        pot_Centre.x,pot_Centre.Y,p_Radius );
    end FindCircle;

    function FindCircle (pot_Pt1    in  mdsys.VERTEX_TYPE,
                         pot_Pt2    in  mdsys.VERTEX_TYPE,
                         pot_Pt3    in  mdsys.VERTEX_TYPE)
      return mdsys.sdo_point_type
    Is
      v_pot_Centre mdsys.sdo_point_type := new mdsys.sdo_point_type(null,null,null);
      b_ok         boolean;
    begin
      b_ok := FindCircle(pot_Pt1.x,pot_Pt1.y,
                         pot_Pt2.X,pot_Pt2.y,
                         pot_Pt3.X,pot_Pt3.y,
                         v_pot_Centre.x,v_pot_Centre.Y,v_pot_Centre.Z );
      return case when b_ok then v_pot_centre else null end;
    end FindCircle;

    function FindCircle (p_polygon in mdsys.sdo_geometry)
      return mdsys.sdo_point_type deterministic
    Is
      b_ok     boolean;
      v_centre mdsys.sdo_point_type := new mdsys.sdo_point_type(null,null,null);
      v_pt1    mdsys.vertex_type;
      v_pt2    mdsys.vertex_type;
      v_pt3    mdsys.vertex_type;
    begin
      if (p_polygon is null) then
         return null;
      end if;
      If (p_polygon.get_gtype() not in (3,7) ) Then
         return null;
      end if;
      -- Grab first three vertices for checking
      --
      v_pt1 := mdsys.sdo_util.getVertices(p_polygon)(1);
      v_pt2 := mdsys.sdo_util.getVertices(p_polygon)(2);
      v_pt3 := mdsys.sdo_util.getVertices(p_polygon)(3);

      b_ok := FindCircle(v_pt1.x,v_pt1.y,
                         v_pt2.X,v_pt2.y,
                         v_pt3.X,v_pt3.y,
                         v_Centre.x,v_Centre.Y,v_Centre.Z );
      return case when b_ok then v_centre else null end;
    End FindCircle;

      -- ----------------------------------------------------------------------------------------
      -- @function   : ADD_COORDINATE
      -- @precis     : A procedure that allows a user to add a new coordinate to a supplied ordinate info array.
      -- @version    : 1.0
      -- @history    : Simon Greener - Jul 2001 - Original coding.
      --
      PROCEDURE ADD_Coordinate( p_ordinates  in out nocopy mdsys.sdo_ordinate_array,
                                p_dim        in number,
                                p_x_coord    in number,
                                p_y_coord    in number,
                                p_z_coord    in number,
                                p_m_coord    in number )
        IS
      BEGIN
        IF p_dim >= 2 THEN
          p_ordinates.extend(2);
          p_ordinates(p_ordinates.count-1) := p_x_coord;
          p_ordinates(p_ordinates.count  ) := p_y_coord;
        END IF;
        IF p_dim >= 3 THEN
          p_ordinates.extend(1);
          p_ordinates(p_ordinates.count)   := p_z_coord;
        END IF;
        IF p_dim = 4 THEN
          p_ordinates.extend(1);
          p_ordinates(p_ordinates.count)   := p_m_coord;
        END IF;
      END ADD_Coordinate;

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
        -- if iSegments is negative then the dDeltaTheta value will be negative and so the cirlce will be anticlockwise
        dDeltaTheta := 2 * &&Default_Schema..CONSTANTS.c_PI / iSegments;
        iAbsSegments := Abs(iSegments);
        ADD_Coordinate( v_ordinates, 2, (dCentreX + dRadius),dCentreY, NULL, NULL );
        dTheta := 0;
        FOR iSeg in 1..iAbsSegments LOOP
            dTheta := dTheta + dDeltaTheta;
            ADD_Coordinate( v_ordinates, 2, (dCentreX + dRadius * Cos(dTheta)), (dCentreY + dRadius * Sin(dTheta)), NULL, NULL );
        END LOOP;
        RETURN ( MDSYS.SDO_GEOMETRY(2003,NULL,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),v_ordinates) );
    End Circle2Polygon;

    Function CircularArc2Line(dStart   in &&Default_Schema..ST_Point,
                              dMid     in &&Default_Schema..ST_Point,
                              dEnd     in &&Default_Schema..ST_Point,
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
        If Not &&Default_Schema..COGO.FindCircle(dStart.X,  dStart.Y,
                                       dMid.X,    dMid.Y,
                                       dEnd.X,    dEnd.Y,
                                       dCentreX, dCentreY, dRadius) Then
          raise_application_error(&&Default_Schema..CONSTANTS.c_i_CircleProperties,
                                  &&Default_Schema..CONSTANTS.c_s_CircleProperties,False);
          Return Null;
        End If;
        iDimension := case when dStart.Z is null then 2 else case when dStart.M is null then 3 else 4 end end;

        dBearingStart    := &&Default_Schema..COGO.Bearing(dCentreX, dCentreY, dStart.X, dStart.Y);
	-- Compute number of segments for whole circle
        iOptimalSegments := &&Default_Schema..COGO.OptimalCircleSegments(dRadius, p_Arc2Chord);
        dTheta1 := &&Default_Schema..COGO.AngleBetween3Points(dStart.X, dStart.Y, dCentreX, dCentreY, dMid.X, dMid.Y);
        dTheta2 := &&Default_Schema..COGO.AngleBetween3Points(dMid.X,   dMid.Y,   dCentreX, dCentreY, dEnd.X, dEnd.Y);
        vRotation := case when dTheta1 < 0 or dTheta2 < 0 then -1 else 1 end;
        dTheta    := (ABS(dTheta1) + ABS(dTheta2)) * vRotation;

	-- Compute number of segments just for this arc
        iOptimalSegments := Round(iOptimalSegments * (dTheta / (2 * &&Default_Schema..CONSTANTS.c_PI)));
        If ( abs(iOptimalSegments) < 3 ) Then
           -- Return the original arc as a line
           RETURN( MDSYS.SDO_GEOMETRY(iDimension*1000 + 2,
                                      NULL,
                                      NULL,
                                      mdsys.sdo_elem_info_array(1, 2, 1 ),
                                      case iDimension
                                           when 2 then mdsys.sdo_ordinate_array( dStart.X, dStart.Y, dMid.X, dMid.Y, dEnd.X, dEnd.Y )
                                           when 3 then mdsys.sdo_ordinate_array( dStart.X, dStart.Y, dStart.Z, dMid.X, dMid.Y, dMid.Z, dEnd.X, dEnd.Y, dEnd.Z )
                                           when 4 then mdsys.sdo_ordinate_array( dStart.X, dStart.Y, dStart.Z, dStart.M, dMid.X, dMid.Y, dMid.Z, dMid.M, dEnd.X, dEnd.Y, dEnd.Z, dEnd.M )
                                           else mdsys.sdo_ordinate_array( dStart.X, dStart.Y, dMid.X, dMid.Y, dEnd.X, dEnd.Y )
                                           end
                                      )
                 );
        End If;

        If ( dTheta > 0 ) Then
            --angle is clockwise
            If ( iOptimalSegments < 0 ) Then
                --circularArc is anticlockwise so get the opposite angle (Should be +ve)
                dTheta := 2 * &&Default_Schema..CONSTANTS.c_PI + dTheta;
            End If;
            --dDeltaTheta should be -ve
            dThetaStart := dBearingStart - &&Default_Schema..CONSTANTS.c_PI / 2;
        Else
            --angle is anticlockwise
            If ( iOptimalSegments > 0 ) Then
                --circularArc is clockwise so get the opposite angle (Should be -ve)
                dTheta := dTheta - (2 * &&Default_Schema..CONSTANTS.c_PI);
            End If;
            --dDeltaTheta should be +ve
        End If;
        iAbsSegments := Abs(iOptimalSegments);
        dDeltaTheta := dTheta / iAbsSegments;

        --compensate for cartesian angles versus compass bearing
        If dBearingStart = 0 Then
            dThetaStart := &&Default_Schema..CONSTANTS.c_PI / 2;
        ElsIf (dBearingStart > 0) And (dBearingStart <= &&Default_Schema..CONSTANTS.c_PI / 2) Then
            dThetaStart := &&Default_Schema..CONSTANTS.c_PI / 2 - dBearingStart;
        ElsIf (dBearingStart > &&Default_Schema..CONSTANTS.c_PI / 2) Then
            dThetaStart := 2 * &&Default_Schema..CONSTANTS.c_PI - (dBearingStart - &&Default_Schema..CONSTANTS.c_PI / 2);
        End If;

        if ( iDimension = 4 ) Then
          dMDelta := ( 1 / iAbsSegments ) * ( dEnd.M - dStart.M);
        End If;
        ADD_Coordinate( v_ordinates,
                        iDimension,
                        dStart.X,
                        dStart.Y,
                        dStart.Z,
                        dStart.m );
        dTheta := dThetaStart;
        -- Create intermediate points
        FOR iSeg in 1..(iAbsSegments-1) LOOP
            dTheta := dTheta + dDeltaTheta;
            ADD_Coordinate( v_ordinates,
                            iDimension,
                           (dCentreX + dRadius * Cos(dTheta)),
                           (dCentreY + dRadius * Sin(dTheta)),
                           dStart.Z,
                           case when iDimension = 4 then dStart.m + ( iSeg * dMDelta ) else null end );
        END LOOP;
        -- Add end point
        ADD_Coordinate( v_ordinates,
                        iDimension,
                        dEnd.X,
                        dEnd.Y,
                        dEnd.Z,
                        dEnd.m );
        RETURN( MDSYS.SDO_GEOMETRY(iDimension*1000 + 2,NULL,NULL,mdsys.sdo_elem_info_array(1, 2, 1 ),v_ordinates) );
    End CircularArc2Line;

    Function CircularArc2Line(dStart   in &&Default_Schema..T_Vertex,
                              dMid     in &&Default_Schema..T_Vertex,
                              dEnd     in &&Default_Schema..T_Vertex,
                              p_Arc2Chord in number  := 0.1 )
             Return MDSYS.Sdo_Geometry
    Is
    Begin
      Return &&Default_Schema..COGO.CircularArc2Line(&&Default_Schema..ST_Point(dStart.X,dStart.Y),
                                                    &&Default_Schema..ST_Point(  dMid.X,  dMid.Y),
                                                    &&Default_Schema..ST_Point(  dEnd.X,  dEnd.Y),
                                                    p_Arc2Chord);
    End CircularArc2Line;

    Function CircularArc2Line(dStartX     in number,
                              dStartY     in number,
                              dMidX       in number,
                              dMidY       in number,
                              dEndX       in number,
                              dEndY       in number,
                              p_Arc2Chord in number  := 0.1 )
             Return MDSYS.Sdo_Geometry
    Is
    Begin
      Return &&Default_Schema..COGO.CircularArc2Line(&&Default_Schema..ST_Point(dStartX,dStartY),
                                                    &&Default_Schema..ST_Point(  dMidX,  dMidY),
                                                    &&Default_Schema..ST_Point(  dEndX,  dEndY),
                                                    p_Arc2Chord);
    End CircularArc2Line;

    Function ComputeArcLength( dRadius in number,
                               dAngle in number)
    Return Number
    IS
      dArc Number;
      dAngleRad Number;
    BEGIN
      dAngleRad := dAngle * &&Default_Schema..CONSTANTS.c_PI / 180;
      dArc := dRadius * dAngleRad;
      Return dArc;
    END ComputeArcLength;

    Function ComputeChordLength( dRadius in number,
                                 dAngle in number)
    Return Number
    IS
      dChord Number;
      dAngleRad Number;
    BEGIN
      dAngleRad := dAngle * &&Default_Schema..CONSTANTS.c_PI / 180;
      dChord := 2 * dRadius * Sin(dAngleRad / 2);
      Return dChord;
    END ComputeChordLength;

    Function ArcToChordSeparation(dRadius in number,
                                  dAngle in number )
    Return Number
    Is
      dAngleRad Number;
      dCentreToChordMidPoint Number;
      dArcChordSeparation Number;
    BEGIN
      dAngleRad := dAngle * &&Default_Schema..CONSTANTS.c_PI / 180;
      dCentreToChordMidPoint := dRadius * cos(dAngleRad/2);
      dArcChordSeparation := dRadius - dCentreToChordMidPoint;
      Return dArcChordSeparation;
    End ArcToChordSeparation;

    Function OptimalCircleSegments( dRadius in number,
                                    dArcToChordSeparation in number)
    Return Integer
    Is
      dAngleRad Number;
      dCentreToChordMidPoint Number;
    BEGIN
       dCentreToChordMidPoint := dRadius - dArcToChordSeparation;
       dAngleRad := 2 * aCos(dCentreToChordMidPoint/dRadius);
      Return CEIL( (2 * &&Default_Schema..CONSTANTS.c_PI) / dAngleRad );
    END OptimalCircleSegments;

    Function ArcTan2(dOpp in number,
                     dAdj in number)
    Return Number
    IS
        dAngleRad Number;
    BEGIN
        --Get the basic angle.
        If Abs(dAdj) < 0.0001 Then
            dAngleRad := &&Default_Schema..CONSTANTS.c_PI / 2;
        Else
            dAngleRad := Abs(aTan(dOpp / dAdj));
        End If;

        --See if we are in quadrant 2 or 3.
        If dAdj < 0 Then
            --dAngle > &&Default_Schema..CONSTANTS.c_PI/2 or angle < -&&Default_Schema..CONSTANTS.c_PI/2.
            dAngleRad := &&Default_Schema..CONSTANTS.c_PI - dAngleRad;
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
        dDotProduct   := &&Default_Schema..COGO.DotProduct(dStartX, dStartY, dCentreX, dCentreY, dEndX, dEndY);
        dCrossProduct := &&Default_Schema..COGO.CrossProductLength(dStartX, dStartY, dCentreX, dCentreY, dEndX, dEndY);
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
        If (dE1 Is Null
            or
            dN1 Is Null
            or
            dE2 Is Null
            or
            dE1 Is null
           ) THEN
           Return Null;
        End If;
        If ( (dE1 = dE2) And (dN1 = dN2) ) Then
           Return Null;
        End If;
        dEast := dE2 - dE1;
        dNorth := dN2 - dN1;
        If ( dEast = 0 ) Then
            If ( dNorth < 0 ) Then
                dBearing := &&Default_Schema..CONSTANTS.c_PI;
            Else
                dBearing := 0;
            End If;
        Else
            dBearing := -aTan(dNorth / dEast) + &&Default_Schema..CONSTANTS.c_PI / 2;
        End If;
        If ( dEast < 0 ) Then
            dBearing := dBearing + &&Default_Schema..CONSTANTS.c_PI;
        End If;
        Return dBearing;
    End Bearing;

    Function Bearing(startCoord in mdsys.sdo_point_type,
                       endCoord in mdsys.sdo_point_type)
    Return Number
    IS
    Begin
      Return Bearing( startCoord.X, startCoord.Y, endCoord.X, endCoord.Y );
    End Bearing;

    Function Bearing(startCoord in mdsys.vertex_type,
                       endCoord in mdsys.vertex_type)
    Return Number
    IS
    Begin
      Return Bearing( startCoord.X, startCoord.Y, endCoord.X, endCoord.Y );
    End Bearing;

    Function isGeographic( p_SRID in number )
      Return Boolean
    Is
      -- Some constants
      v_geodetic_srid  MDSYS.GEODETIC_SRIDS.SRID%TYPE := NULL;
    Begin
      IF ( p_SRID IS NOT NULL ) THEN
      BEGIN
         SELECT SRID
           INTO v_geodetic_srid
           FROM MDSYS.GEODETIC_SRIDS
          WHERE SRID = p_SRID;
         EXCEPTION
           WHEN NO_DATA_FOUND THEN
              v_geodetic_srid := NULL;
      END;
      END IF;
      RETURN ( v_geodetic_srid IS NOT NULL );
    End isGeographic;

    Function Bearing( p_startCoord in mdsys.sdo_point_type,
                        p_endCoord in mdsys.sdo_point_type,
                     p_planar_srid in number,
                 p_geographic_srid in number := 8311
	                  )
    Return Number
    IS
      v_bearing     Number;
      v_startCoord  mdsys.sdo_point_type;
      v_endCoord    mdsys.sdo_point_type;
      NOTGEOGRAPHIC EXCEPTION;
    Begin
      If ( p_startCoord.X NOT BETWEEN -180 AND 180 ) OR
         ( p_startCoord.Y NOT BETWEEN  -90 AND  90 ) OR
         (   p_endCoord.X NOT BETWEEN -180 AND 180 ) OR
         (   p_endCoord.Y NOT BETWEEN  -90 AND  90 ) THEN
         RAISE NOTGEOGRAPHIC;
      End If;
      If ( isGeographic( p_geographic_srid ) ) Then
         -- Convert to required planar SRID
         v_startCoord := MDSYS.SDO_CS.TRANSFORM(MDSYS.SDO_GEOMETRY(2001,p_geographic_srid,p_startCoord,NULL,NULL),p_planar_srid).SDO_POINT;
         v_endCoord   := MDSYS.SDO_CS.TRANSFORM(MDSYS.SDO_GEOMETRY(2001,p_geographic_srid,p_endCoord,  NULL,NULL),p_planar_srid).SDO_POINT;
      Else
         v_bearing := Bearing( p_startCoord.X, p_startCoord.Y, p_endCoord.X, p_endCoord.Y );
      End If;
      Return v_bearing;
      Exception
        When NOTGEOGRAPHIC Then
         raise_application_error(&&Default_Schema..Constants.c_i_not_geographic,
                                 &&Default_Schema..Constants.c_s_not_geographic,TRUE);
         Return 0;
    End Bearing;

    Function ST_Azimuth( p_startCoord in &&Default_Schema..ST_Point,
                         p_endCoord   in &&Default_Schema..ST_Point)
      Return Number
    IS
    Begin
      Return Bearing( p_startCoord.ST_X(), p_startCoord.ST_Y(), p_endCoord.ST_X(), p_endCoord.ST_Y() );
    End ST_Azimuth;

    Function Distance(dE1 in number,
                      dN1 in number,
                      dE2 in number,
                      dN2 in number)
    Return Number
    IS
        dEast Number;
        dNorth Number;
    Begin
        dEast := dE2 - dE1;
        dNorth := dN2 - dN1;
        Return Sqrt(dEast * dEast + dNorth * dNorth);
    End Distance;

    Function Distance(p_startCoord in mdsys.sdo_point_type,
                        p_endCoord in mdsys.sdo_point_type)
    Return Number
    IS
    Begin
      Return Distance( p_startCoord.X, p_startCoord.Y, p_endCoord.X, p_endCoord.Y );
    End Distance;

    Function Distance(    p_startCoord in mdsys.sdo_point_type,
                            p_endCoord in mdsys.sdo_point_type,
	             p_geographic_srid in number := 8311,
	                   p_tolerance in number := 0.05 )
    Return Number
    Is
      v_startCoord  mdsys.sdo_point_type;
      v_endCoord    mdsys.sdo_point_type;
      v_distance    number;
      NOTGEOGRAPHIC EXCEPTION;
    Begin
      If ( p_startCoord.X NOT BETWEEN -180 AND 180 ) OR
         ( p_startCoord.Y NOT BETWEEN  -90 AND  90 ) OR
         (   p_endCoord.X NOT BETWEEN -180 AND 180 ) OR
         (   p_endCoord.Y NOT BETWEEN  -90 AND  90 ) THEN
         RAISE NOTGEOGRAPHIC;
      End If;
      If ( isGeographic( p_geographic_srid ) ) Then
         v_distance := MDSYS.SDO_GEOM.SDO_DISTANCE(MDSYS.SDO_GEOMETRY(2001,p_geographic_srid,p_startCoord,NULL,NULL),
                                                   MDSYS.SDO_GEOMETRY(2001,p_geographic_srid,p_endCoord,  NULL,NULL),
					           p_tolerance);
      Else
         v_distance := Bearing( p_startCoord.X, p_startCoord.Y, p_endCoord.X, p_endCoord.Y );
      End If;
      Return v_distance;
      Exception
        When NOTGEOGRAPHIC Then
         raise_application_error(&&Default_Schema..Constants.c_i_not_geographic,
                                 &&Default_Schema..Constants.c_s_not_geographic,TRUE);
         Return 0;
    End Distance;

    Function Distance( p_frst_vertex IN &&Default_Schema..ST_Point,
                       p_last_vertex IN &&Default_Schema..ST_Point,
                       p_srid        IN number,
                       p_tolerance   IN number)
             RETURN number
    Is
      v_frst_pt      MDSYS.SDO_GEOMETRY;
      v_last_pt      MDSYS.SDO_GEOMETRY;
    Begin
        v_frst_pt := MDSYS.SDO_GEOMETRY(
                      2001,
                      p_srid,
                      MDSYS.SDO_POINT_TYPE(
                            p_frst_vertex.x,
                            p_frst_vertex.y,
                            p_frst_vertex.z),NULL,NULL);
        v_last_pt := MDSYS.SDO_GEOMETRY(
                      2001,
                      p_srid,
                      MDSYS.SDO_POINT_TYPE(
                            p_last_vertex.x,
                            p_last_vertex.y,
                            p_last_vertex.z),NULL,NULL);
        RETURN MDSYS.SDO_GEOM.SDO_DISTANCE(v_frst_pt,v_last_pt,p_tolerance);
    End Distance;

    Procedure SetDegreeSymbol( p_Symbol In NVarChar2 )
    Is
    Begin
      sDegreeSymbol := SUBSTR(p_Symbol,1,1);
    End;

    Procedure SetMinuteSymbol( p_Symbol In NVarChar2 )
    Is
    Begin
      sMinuteSymbol := SUBSTR(p_Symbol,1,1);
    End;

    Procedure SetSecondSymbol( p_Symbol In NVarChar2 )
    Is
    Begin
      sSecondSymbol := SUBSTR(p_Symbol,1,1);
    End;

    Function DD2DMS( dDecDeg in Number )
    Return varchar2
    IS
        iDeg Integer;
        iMin Integer;
        dSec Number;
    BEGIN
        iDeg := Trunc(dDecDeg);
        iMin := Trunc((Abs(dDecDeg) - Abs(iDeg)) * 60);
        dSec := Round((((Abs(dDecDeg) - Abs(iDeg)) * 60) - iMin) * 60, 3);
        Return TO_CHAR(iDeg) || sDegreeSymbol || TO_CHAR(iMin) || sMinuteSymbol || TO_CHAR(dSec) || sSecondSymbol;
    End DD2DMS;

    Function DD2DMS( dDecDeg in Number,
                     pDegree in NVarChar2,
                     pMinute in NVarChar2,
                     pSecond in NVarChar2 )
    Return varchar2
    IS
    BEGIN
        SetDegreeSymbol(pDegree);
        SetMinuteSymbol(pMinute);
        SetSecondSymbol(pSecond);
        Return DD2DMS( dDecDeg );
    End DD2DMS;

    Function DMS2DD( dDeg in number,
                     dMin in number,
                     dSec in number)
    Return Number
    IS
       dDD Number;
    BEGIN
       dDD := ABS(dDeg) + dMin / 60 + dSec / 3600;
       Return SIGN(dDeg) * dDD;
    End DMS2DD;

    Function DMS2DD(strDegMinSec in varchar2)
    Return Number
    IS
       i               Number;
       intDmsLen       Number; --Length of original string
       strCompassPoint Char(1);
       strNorm         varchar2(16); --Will contain normalized string
       strDegMinSecB   varchar2(100);
       blnGotSeparator integer;      -- Keeps track of separator sequences
       arrDegMinSec    stringarray;
       dDeg            Number := 0;
       dMin            Number := 0;
       dSec            Number := 0;
       strChr          Char(1);
    BEGIN
       -- Remove leading and trailing spaces
       strDegMinSecB := REPLACE(strDegMinSec,' ',NULL);
       -- assume no leading and trailing spaces?
       intDmsLen := Length(strDegMinSecB);

       blnGotSeparator := 0; -- Not in separator sequence right now

       -- Loop over string, replacing anything that is not a digit or a
       -- decimal separator with
       -- a single blank
       FOR i in 1..intDmsLen LOOP
          -- Get current character
          strChr := SubStr(strDegMinSecB, i, 1);
          -- either add character to normalized string or replace
          -- separator sequence with single blank
          If InStr('0123456789,.', strChr) > 0 Then
             -- add character but replace comma with point
             If (strChr <> ',') Then
                strNorm := strNorm || strChr;
             Else
                strNorm := strNorm || '.';
             End If;
             blnGotSeparator := 0;
          ElsIf InStr('neswNESW',strChr) > 0 Then -- Extract Compass Point if present
            strCompassPoint := strChr;
          Else
             -- ensure only one separator is replaced with a blank -
             -- suppress the rest
             If blnGotSeparator = 0 Then
                strNorm := strNorm || ' ';
                blnGotSeparator := 0;
             End If;
          End If;
       End Loop;

       -- Split normalized string into array of max 3 components
       arrDegMinSec := strtok(strNorm, ' ');

       -- If too many components, return error
       --If UBound(arrDegMinSec) > 2 Then Exit Function

       --convert specified components to double
       i := arrDegMinSec.Count;
       If i >= 1 Then
          dDeg := TO_NUMBER(arrDegMinSec(1));
       End If;
       If i >= 2 Then
          dMin := TO_NUMBER(arrDegMinSec(2));
       End If;
       If i >= 3 Then
          dSec := TO_NUMBER(arrDegMinSec(3));
       End If;

       -- convert components to value
       return (CASE WHEN UPPER(strCompassPoint) IN ('S','W')
                    THEN -1
                    ELSE 1
                END
               *
               (dDeg + dMin / 60 + dSec / 3600));
    End DMS2DD;

    Function RelativeLine( dStartX        In Number,
                           dStartY        In Number,
                           dBearingStart  In Number,
                           dDistanceStart In Number,
                           dBearingEnd    In Number,
                           dDistanceEnd   In Number)
    Return MDSYS.SDO_GEOMETRY
    IS
        dStartPntX Number;
        dStartPntY Number;
        dEndPntX Number;
        dEndPntY Number;
        shpTemp MDSYS.SDO_GEOMETRY;
    BEGIN
      shpTemp := &&Default_Schema..COGO.PointFromBearingAndDistance(dStartX, dStartY, dBearingStart, dDistanceStart);
      dStartPntX := shpTemp.sdo_point.x;
      dStartPntY := shpTemp.sdo_point.y;
      shpTemp := &&Default_Schema..COGO.POINTFROMBEARINGANDDISTANCE(dStartPntX, dStartPntY, dBearingEnd, dDistanceEnd);
      dEndPntX := shpTemp.sdo_point.x;
      dEndPntY := shpTemp.sdo_point.y;
      RETURN( MDSYS.SDO_GEOMETRY(2002,NULL,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1),MDSYS.SDO_ORDINATE_ARRAY(dStartPntX, dStartPntY, dEndPntX, dEndPntY)));
    END RelativeLine;

    Procedure FindLineIntersection(
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
        inter_x  := &&Default_Schema..CONSTANTS.c_Max;
        inter_y  := &&Default_Schema..CONSTANTS.c_Max;
        inter_x1 := &&Default_Schema..CONSTANTS.c_Max;
        inter_y1 := &&Default_Schema..CONSTANTS.c_Max;
        inter_x2 := &&Default_Schema..CONSTANTS.c_Max;
        inter_y2 := &&Default_Schema..CONSTANTS.c_Max;
        RETURN;
      End If;
      t1 := ((x11 - x21) * dy2 + (y21 - y11) * dx2) / denominator;
      t2 := ((x21 - x11) * Y1  + (y11 - y21) * X1) / -denominator;

      -- Find the point of intersection.
      inter_x := x11 + X1 * t1;
      inter_y := y11 + Y1 * t1;

      -- Find the closest points on the segments.
      If t1 < 0 Then
        t1 := 0;
      ElsIf t1 > 1 Then
        t1 := 1;
      End If;

      If t2 < 0 Then
        t2 := 0;
      ElsIf t2 > 1 Then
        t2 := 1;
      End If;
      inter_x1 := x11 + X1 * t1;
      inter_y1 := y11 + Y1 * t1;
      inter_x2 := x21 + dx2 * t2;
      inter_y2 := y21 + dy2 * t2;
    END FindLineIntersection;

  /**
  ** SQL> desc sdo_datums
  **  Name                                      Null?    Type
  **  ----------------------------------------- -------- --------------
  **
  **  DATUM_ID                                  NOT NULL NUMBER(10)
  **  DATUM_NAME                                NOT NULL VARCHAR2(80)
  **  DATUM_TYPE                                         VARCHAR2(24)
  **  ELLIPSOID_ID                                       NUMBER(10)
  **  PRIME_MERIDIAN_ID                                  NUMBER(10)
  **  INFORMATION_SOURCE                                 VARCHAR2(254)
  **  DATA_SOURCE                                        VARCHAR2(40)
  **  SHIFT_X                                            NUMBER
  **  SHIFT_Y                                            NUMBER
  **  SHIFT_Z                                            NUMBER
  **  ROTATE_X                                           NUMBER
  **  ROTATE_Y                                           NUMBER
  **  ROTATE_Z                                           NUMBER
  **  SCALE_ADJUST                                       NUMBER
  **  IS_LEGACY                                 NOT NULL VARCHAR2(5)
  **  LEGACY_CODE                                        NUMBER(10)
  **
  ** SQL> desc sdo_ellipsoids (10g)
  **  Name                                      Null?    Type
  **  ----------------------------------------- -------- --------------
  **
  **  ELLIPSOID_ID                              NOT NULL NUMBER
  **  ELLIPSOID_NAME                            NOT NULL VARCHAR2(80)
  **  SEMI_MAJOR_AXIS                                    NUMBER
  **  UOM_ID                                             NUMBER
  **  INV_FLATTENING                                     NUMBER
  **  SEMI_MINOR_AXIS                                    NUMBER
  **  INFORMATION_SOURCE                                 VARCHAR2(254)
  **  DATA_SOURCE                                        VARCHAR2(40)
  **  IS_LEGACY                                 NOT NULL VARCHAR2(5)
  **  LEGACY_CODE                                        NUMBER
  **
  ** SQL desc mdsys.sdo_ellipsoids (9i)
  **  Name                           Null     Type
  **  ------------------------------ -------- -------------
  **  NAME                                    VARCHAR2(64)
  **  SEMI_MAJOR_AXIS                         NUMBER
  **  INVERSE_FLATTENING                      NUMBER
  **
 /** Ellipsoid_Id can be gotten (10g) from:
  **  select ellipsoid_id,
  **         substr(ellipsoid_name,1,20) as ellipsoid_name,,
  **         semi_major_axis,
  **         semi_minor_axis,
  **         inv_flattening
  **    from sdo_ellipsoids
  **/

  /** Note: p_lon1 etc should be in radians. Best to call as follows:
  **        select COGO.GreatCircleDistance(COGO.longitude(90,0,0,1),0,
  **                                        COGO.longitude(100,0,0,1),0,
  **                                        null,null)
  **                    As GC_Distance_90_0_to_100_0
  **          from dual;
  **/
  function GreatCircleDistance( p_lon1              in number,
                                p_lat1              in number,
                                p_lon2              in number,
                                p_lat2              in number,
                                p_equatorial_radius in number default null,
                                p_flattening        in number default null)
      	   return number
  Is
    v_equatorial_radius  number := NVL(p_equatorial_radius,6378.137);     -- Default is WGS-84
    v_flattening         number := 1.0 / NVL(p_flattening,298.257223563); -- Default is WGS-84 ellipsoid flattening factor
    v_C           number;
    v_D           number;
    v_F           number;
    v_G           number;
    v_H1          number;
    v_H2          number;
    v_L           number;
    v_R           number;
    v_S           number;
    v_W           number;
    v_sinG2       number;
    v_cosG2       number;
    v_sinF2       number;
    v_cosF2       number;
    v_sinL2       number;
    v_cosL2       number;
    v_distance    number;
    NOT_RADIANS   EXCEPTION;
  BEGIN
      IF ( ABS(p_lon1) >  &&Default_Schema..CONSTANTS.c_PI ) OR
         ( ABS(p_lat1) >  &&Default_Schema..CONSTANTS.c_PI ) OR
         ( ABS(p_lon2) >  &&Default_Schema..CONSTANTS.c_PI ) OR
         ( ABS(p_lat2) >  &&Default_Schema..CONSTANTS.c_PI ) THEN
         RAISE NOT_RADIANS;
      END IF;

      v_F := ( p_lat1 + p_lat2 ) / 2.0;
      v_G := ( p_lat1 - p_lat2 ) / 2.0;
      v_L := ( p_lon1 - p_lon2 ) / 2.0;

      v_sinG2 := power( sin( v_G ), 2 );
      v_cosG2 := power( cos( v_G ), 2 );
      v_sinF2 := power( sin( v_F ), 2 );
      v_cosF2 := power( cos( v_F ), 2 );
      v_sinL2 := power( sin( v_L ), 2 );
      v_cosL2 := power( cos( v_L ), 2 );

      v_S  := v_sinG2 * v_cosL2 + v_cosF2 * v_sinL2;
      v_C  := v_cosG2 * v_cosL2 + v_sinF2 * v_sinL2;

      v_W  := atan( sqrt( v_S / v_C ) );
      v_R  := sqrt( v_S * v_C ) / v_w;

      v_D  := 2.0 * v_w * v_equatorial_radius;
      v_H1 := ( 3.0 * v_R - 1)/( 2.0 * v_C);
      v_H2 := ( 3.0 * v_R + 1)/( 2.0 * v_S);

      v_distance := v_D * ( ( 1.0 + v_flattening * v_H1 * v_sinF2 * v_cosG2 ) -
                                  ( v_flattening * v_H2 * v_cosF2 * v_sinG2 ) );

      return round( 100.0 * v_distance ) / 100.0;
      EXCEPTION
        WHEN NOT_RADIANS THEN
          raise_application_error(c_i_not_radians, c_s_not_radians );
          return 0;
  END GreatCircleDistance;

  function GreatCircleDistance( p_lon1           in number,
                                p_lat1           in number,
                                p_lon2           in number,
                                p_lat2           in number,
                                p_ref_type       in varchar2,
                                p_ref_id         in number,
                                p_ellipsoid_name in varchar2 default NULL)
    return number
  is
    v_ref_type           varchar2(100) := UPPER(NVL(p_ref_type,&&Default_Schema..COGO.c_SRID ));
    v_equatorial_radius  number;
    v_flattening         number;
    v_distance           number;
    NOT_RADIANS          EXCEPTION;
  begin
      IF ( ABS(p_lon1) >  &&Default_Schema..CONSTANTS.c_PI ) OR
         ( ABS(p_lat1) >  &&Default_Schema..CONSTANTS.c_PI ) OR
         ( ABS(p_lon2) >  &&Default_Schema..CONSTANTS.c_PI ) OR
         ( ABS(p_lat2) >  &&Default_Schema..CONSTANTS.c_PI ) THEN
         RAISE NOT_RADIANS;
      END IF;
      If ( p_ref_id is null
           And
           v_ref_type IN (&&Default_Schema..COGO.c_ELLIPSOID_ID,&&Default_Schema..COGO.c_SRID)
           ) then
         raise_application_error(c_i_null_srid,c_s_null_srid);
      End If;
      If ( v_ref_type IN (&&Default_Schema..COGO.c_ELLIPSOID_ID,&&Default_Schema..COGO.c_ELLIPSOID_NAME) ) Then
        -- Retrieve equatorial radius and flattening from sdo_ellipsoids table.
        EXECUTE IMMEDIATE '
        SELECT INV_FLATTENING, ( SEMI_MAJOR_AXIS / 1000 )
          FROM mdsys.sdo_ellipsoids
         WHERE ' || CASE WHEN v_ref_type = &&Default_Schema..COGO.c_ELLIPSOID_ID and DBMS_DB_VERSION.VERSION >= 10
                         THEN 'ellipsoid_id = ' || p_ref_id
                         ELSE 'ellipsoid_name = '''       || p_ellipsoid_name || ''''
                     END
      	  INTO v_flattening,   v_equatorial_radius;
      ElsIf ( v_ref_type = &&Default_Schema..COGO.c_SRID ) Then
        If ( isGeographic(p_ref_id) ) Then
          /* Retrieve equatorial radius and flattening from cs_srs table.
          */
          With sel_string
            as (select substr(cs.wktext,instr(cs.wktext,' SPHEROID')+9,1000) as spheroid_str
                  from mdsys.cs_srs cs
                 where srid = p_ref_id)
            select ( max(to_number(t.token)) / 1000 ) as equatorial_distance,
                   ( 1.0 / min(to_number(t.token)) ) as inv_flattening
              into v_equatorial_radius, v_flattening
              from mdsys.cs_srs m,
                   table(&&Default_Schema..Tokenizer(
                            substr((select spheroid_str from sel_string),1,
                            instr((select spheroid_str from sel_string),'PRIMEM')-1),
                           ',[]/()')) t
             where srid = p_ref_id
               and trim(BOTH ' ' from t.token) is not null
               and instr(t.token,'"') = 0;
       Else
         raise_application_error(c_i_srid_not_geo, c_s_srid_not_geo);
       End If;
    Else
         raise_application_error(-20000, 'Unknown reference type: must be ' ||
                                          &&Default_Schema..COGO.c_SRID || ' or ' ||
                                          &&Default_Schema..COGO.c_ELLIPSOID_ID || ' or ' ||
                                          &&Default_Schema..COGO.c_ELLIPSOID_NAME );

    End If;
    return &&Default_Schema..COGO.GreatCircleDistance( p_lon1, p_lat1, p_lon2, p_lat2, v_equatorial_radius, v_flattening);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         raise_application_error(-20000, 'Could not determine flattening etc for ellipsoid associated with supplied ' ||
                                          v_ref_type || '( ' || p_ref_id || ')');
         return 0;
      WHEN NOT_RADIANS THEN
         raise_application_error(c_i_not_radians,c_s_not_radians );
         return 0;
  END GreatCircleDistance;

  -- does not work if one latitude is polar!!!
  function GreatCircleBearing( p_lon1 in number,
                               p_lat1 in number,
                               p_lon2 in number,
                               p_lat2  in number)
   return number
  Is
     v_dLong     number;
     v_cosC      number;
     v_cosD      number;
     v_C         number;
     v_D         number;
     NOT_RADIANS EXCEPTION;
  Begin
     IF ( ABS(p_lon1) >  &&Default_Schema..CONSTANTS.c_PI ) OR
        ( ABS(p_lat1) >  &&Default_Schema..CONSTANTS.c_PI ) OR
        ( ABS(p_lon2) >  &&Default_Schema..CONSTANTS.c_PI ) OR
        ( ABS(p_lat2) >  &&Default_Schema..CONSTANTS.c_PI ) THEN
        RAISE NOT_RADIANS;
     END IF;
     v_dLong := p_lon2 - p_lon1;
     v_cosD  := ( sin(p_lat1) * sin(p_lat2) ) +
                ( cos(p_lat1) * cos(p_lat2) * cos(v_dLong) );
     v_D     := acos(v_cosD);
     if ( v_D = 0.0 ) then
       v_D := 0.00000001; -- roughly 1mm
     end if;
     v_cosC  := ( sin(p_lat2) - v_cosD * sin(p_lat1) ) /
                ( sin(v_D) * cos(p_lat1) );
     -- numerical error can result in |cosC| slightly > 1.0
     if ( v_cosC > 1.0 ) then
         v_cosC := 1.0;
     end if;
     if ( v_cosC < -1.0 ) then
         v_cosC := -1.0;
     end if;
     v_C  := 180.0 * acos( v_cosC ) / &&Default_Schema..CONSTANTS.c_PI;
     if ( sin(v_dLong) < 0.0 ) then
         v_C := 360.0 - v_C;
     end if;
     return (round( 100 * v_C ) / 100.0);
     EXCEPTION
       WHEN NOT_RADIANS THEN
         raise_application_error(c_i_not_radians, c_s_not_radians );
         return 0;
  END GreatCircleBearing;

  FUNCTION latitude( p_deg in pls_integer,
                     p_min in pls_integer,
                     p_sec in pls_integer,
                     p_sgn in pls_integer)
           Return number
  IS
    v_latitude NUMBER := 0.0;
  BEGIN
      if ( 0.0 <= p_sec AND p_sec < 60.0 ) Then
          v_latitude := v_latitude + ( p_sec / 3600.0 );
      else
          raise_application_error(-20000, 'check latitude seconds!' );
      end if;

      if ( 0.0 <= p_min AND p_min < 60.0 ) Then
          v_latitude := v_latitude + ( p_min / 60.0 );
      else
          raise_application_error(-20000, 'check latitude minutes!' );
      end if;

      if ( 0.0 <= p_deg AND p_deg <= 90.0 ) Then
          v_latitude := v_latitude + ( p_deg );
      else
          raise_application_error(-20000, 'check latitude degrees!' );
      end if;

      if ( 0.0 <= v_latitude AND v_latitude <= 90.0 ) Then
          v_latitude := &&Default_Schema..CONSTANTS.c_PI * v_latitude / 180.0;
      else
          raise_application_error(-20000, 'latitude range error!' );
      end if;

      if ( p_sgn = -1 ) Then
          v_latitude := ( 0 - v_latitude );
      end if;

      return v_latitude;
  END latitude;

  FUNCTION longitude( p_deg in pls_integer,
                      p_min in pls_integer,
                      p_sec in pls_integer,
                      p_sgn in pls_integer)
           Return Number
  Is
    v_longitude number := 0.0;
  BEGIN
      if ( 0.0 <= p_sec AND p_sec < 60.0 ) then
          v_longitude := v_longitude  + ( p_sec / 3600.0 );
      else
          raise_application_error(-20000, 'check longitude seconds!' );
      end if;

      if ( 0.0 <= p_min AND p_min < 60.0 ) then
          v_longitude := v_longitude  + ( p_min / 60.0 );
      else
          raise_application_error(-20000, 'check longitude minutes!' );
      end if;

      if ( 0.0 <= p_deg AND p_deg <= 180.0 ) then
          v_longitude := v_longitude  + ( p_deg );
      else
          raise_application_error(-20000, 'check longitude degrees!' );
      end if;

      if ( 0.0 <= v_longitude AND v_longitude <= 180.0 ) then
          v_longitude := &&Default_Schema..CONSTANTS.c_PI * v_longitude / 180.0;
      else
          raise_application_error(-20000, 'longitude range error!' );
      end if;

      if ( p_sgn = -1 ) then
          v_longitude := ( 0 - v_longitude);
      end if;

      return v_longitude;
  END longitude;

  Function degrees(p_radians in number)
    return number
  Is
  Begin
    return p_radians * (180.0 / &&Default_Schema..CONSTANTS.c_PI);
  End degrees;

  /*
  *      radians     - returns radians converted from degrees
  */
  Function radians(p_degrees in number)
    Return number
  Is
  Begin
    Return p_degrees * (&&Default_Schema..CONSTANTS.c_PI / 180.0);
  End radians;


  Function createPolygonFromCogo(p_start_point            in sdo_geometry,
                                 p_bearings_and_distances in tbl_bearing_distances,
                                 p_round_xy               in integer default 3 )
    return sdo_geometry
  as
    v_geometry   sdo_geometry;
    v_point      sdo_point_type;
    v_next_point sdo_point_type;
  begin
    IF ( p_start_point is null or p_start_point.sdo_gtype not in (2001,3001) ) THEN
      return null;
    END IF;
    IF (p_bearings_and_distances is null or p_bearings_and_distances.COUNT = 0 ) THEN
      return null;
    END IF;
    v_point    := p_start_point.sdo_point;
    v_geometry := sdo_geometry(2003,p_start_point.sdo_srid,null,sdo_elem_info_array(1,1003,1),sdo_ordinate_array(v_point.x,v_point.y));
    For rec in (select case when t.sDegMinSec is null or length(sDegMinSec)=0 
                            then nBearing 
                            else COGO.DMS2DD(strDegMinSec=>sDegMinSec) 
                        end as bearing,distance
                  from table(p_bearings_and_distances)  t
                )
    loop
       v_next_point := cogo.pointfrombearinganddistance(v_point.x, v_point.y, rec.bearing, rec.distance).sdo_point;
       v_geometry.sdo_ordinates.extend(2);
       v_geometry.sdo_ordinates(v_geometry.sdo_ordinates.count-1) := round(v_next_point.x,NVL(p_round_xy,3));
       v_geometry.sdo_ordinates(v_geometry.sdo_ordinates.count  ) := round(v_next_point.y,NVL(p_round_xy,3));
       v_point := v_next_point;
    end loop;
    -- Close polygon
    v_geometry.sdo_ordinates.extend(2);
    v_geometry.sdo_ordinates(v_geometry.sdo_ordinates.count-1) := round(p_start_point.sdo_point.x,NVL(p_round_xy,3));
    v_geometry.sdo_ordinates(v_geometry.sdo_ordinates.count  ) := round(p_start_point.sdo_point.y,NVL(p_round_xy,3));
    return v_geometry;
  end createpolygonfromcogo;

  Function CreateLineFromCogo(p_start_point            in sdo_geometry,
                              p_bearings_and_distances in tbl_bearing_distances,
                              p_round_xy               in integer default 3,
                              p_round_z                in integer default 2
                             )
      return sdo_geometry
  as
    v_line       sdo_geometry;
    v_point      sdo_point_type;
    v_next_point sdo_point_type;
    v_dims       pls_integer;
  begin
    IF ( p_start_point is null or p_start_point.sdo_gtype not in (2001,3001) ) THEN
      return null;
    END IF;
    IF (p_bearings_and_distances is null or p_bearings_and_distances.COUNT = 0 ) THEN
      return null;
    END IF;
    v_point    := p_start_point.sdo_point;
    v_dims     := p_start_point.get_dims();
    IF ( v_dims not in (2,3) ) THEN
      return null;
    END IF;
    -- Create basic line
    v_line := sdo_geometry((v_dims*1000)+2,
                           p_start_point.sdo_srid,
                           null,
                           sdo_elem_info_array(1,2,1),
                           case v_dims
                           when 2 then sdo_ordinate_array(v_point.x,v_point.y)
                           when 3 then sdo_ordinate_array(v_point.x,v_point.y,v_point.z)
                            end
                          );
    For rec in (select case when sDegMinSec is null or length(sDegMinSec)=0 then nBearing else COGO.DMS2DD(strDegMinSec=>sDegMinSec) end as bearing,distance,Z
                  from table(p_bearings_and_distances) )
    loop
      v_next_point := COGO.PointFromBearingAndDistance(v_point.x, v_point.y, rec.bearing, rec.distance).sdo_point;
      v_line.sdo_ordinates.extend(v_dims);
      v_line.sdo_ordinates(v_line.sdo_ordinates.count-(v_dims-1)) := round(v_next_point.x,NVL(p_round_xy,3));
      v_line.sdo_ordinates(v_line.sdo_ordinates.count-(v_dims-2)) := round(v_next_point.y,NVL(p_round_xy,3));
      IF ( v_dims = 3 ) Then
        v_line.sdo_ordinates(v_line.sdo_ordinates.count) := round(rec.z,NVL(p_round_z,2));
      End If;
      v_point := v_next_point;
    end loop;
    return v_line;
  end CreateLineFromCOGO;

END COGO;
/
show errors

Prompt Check package has compiled correctly ...
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'COGO';
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

grant execute on COGO to public;

QUIT;

