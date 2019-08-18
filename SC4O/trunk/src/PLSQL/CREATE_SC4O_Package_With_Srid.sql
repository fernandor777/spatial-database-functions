define defaultSchema='&1'

SET VERIFY OFF;

WHENEVER SQLERROR EXIT FAILURE;

create or replace
package SC4O
AUTHID CURRENT_USER
AS

  /****h* PACKAGE/SC4O
  *  NAME
  *    SC4O - Spatial Companion For Oracle is a package that publishes JTS based Java code.
  *  DESCRIPTION
  *    A package that publishes some common JTS-based Java functions.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
******/

  /****v* SC4O/ATTRIBUTES
  *  ATTRIBUTES
  *    TYPE refcur_t             IS REF CURSOR; -- REFCURSOR for use in building geometry objects from a set.
  *    CAP_ROUND         CONSTANT integer := 1; -- Linestring buffer is round at distance from end point
  *    CAP_BUTT          CONSTANT integer := 2; -- Linestring buffer is square and flush to end points
  *    CAP_SQUARE        CONSTANT integer := 3; -- Linestring buffer is square at end distance from end point
  *    JOIN_ROUND        CONSTANT integer := 1; -- For obtuse deflection angles, offset line segments are joined by circular curve.
  *    JOIN_MITRE        CONSTANT integer := 2; -- For obtuse deflection angles, offset line segments are joined by straight lines extensions
  *    JOIN_BEVEL        CONSTANT integer := 3; -- For obtuse deflection angles, offset line segments are joined by flat straight line between start/end points.
  *    QUADRANT_SEGMENTS CONSTANT integer := 8; -- Where circular arc is to be added, it is created as a stroked linestring with this number of segments per quadrant (cf arc to chord separation)
  *  SOURCE
  */
  TYPE refcur_t             IS REF CURSOR;
  CAP_ROUND         CONSTANT integer := 1;
  CAP_BUTT          CONSTANT integer := 2;
  CAP_SQUARE        CONSTANT integer := 3;
  JOIN_ROUND        CONSTANT integer := 1;
  JOIN_MITRE        CONSTANT integer := 2;
  JOIN_BEVEL        CONSTANT integer := 3;
  QUADRANT_SEGMENTS CONSTANT integer := 8;
  /*******/

  /** ============================ PROPERTIES ==================================== **/

  /****f* SC4O/ST_Area
  *  NAME
  *    ST_Area -- Returns area of supplied polygon sdo_geometry
  *  SYNOPSIS
  *    Function ST_Area(p_geom      in mdsys.sdo_geometry,
  *                     p_precision in number)
  *             Return Number Deterministic
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- Geometry subject to area calculation
  *    p_precision (integer) -- Number of decimal places of precision for resulting area.
  *  DESCRIPTION
  *    This function computes the area of the sdo_geometry polygon parameter.
  *    Result is rounded to p_precision.
  *  RESULT
  *    area (Number) -- Area in SRID unit of measure or in units of supplied p_SRID, rounded to SELF.Precision
  *  EXAMPLE
  *    With data as (
  *      Select sdo_geometry(3003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,1, 10,0,2, 10,5,3, 10,10,4, 5,10,5, 5,5,6, 0,0,1)) as geom From Dual union all
  *      select sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10))',28356) as geom From Dual
  *    )
  *    select SC4O.ST_Area(a.geom,3) as area_sq_m
  *      from data a;
  *
  *     AREA_SQ_M
  *    ----------
  *          62.5
  *           399
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2011, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_Area(p_geom      in mdsys.sdo_geometry,
                   p_precision in number)
    Return number Deterministic;

  /****f* SC4O/ST_Area(srid)
  *  NAME
  *    ST_Area -- Computes area of supplied polygon sdo_geometry but in projected SRID.
  *  SYNOPSIS
  *    Function ST_Area(p_geom      in mdsys.sdo_geometry,
  *                     p_precision in number,
  *                     p_srid      in number)
  *             Return Number Deterministic
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- Geometry subject to area calculation
  *    p_precision (integer) -- Number of decimal places of precision for resulting area.
  *    p_srid      (integer) -- SRID of projected space in which actual area calculation occurs before being projected back to p_geom.sdo_srid.
  *  DESCRIPTION
  *    This function computes the area of the sdo_geometry polygon, with computations occuring in projected space described by the p_srid parameter.
  *    JTS does not support geographic or geodetic data. Any such data must therefore be transformed in to a suitable projection before calculations can occur.
  *    This function uses sdo_cs.transform before calling SC4O..ST_Area.
  *    Result is rounded to p_precision.
  *  RESULT
  *    length (Number) -- Length in SRID units of measure.
  *  EXAMPLE
  *    With data as (
  *      Select sdo_geometry(3003,28356,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,1, 10,0,2, 10,5,3, 10,10,4, 5,10,5, 5,5,6, 0,0,1)) as geom From Dual union all
  *      select sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10))',28356) as geom From Dual
  *    )
  *    select SC4O.ST_Area(a.geom,3) as area_sq_m
  *      from data a;
  *
  *     AREA_SQ_M
  *    ----------
  *          62.5
  *           399
  *  NOTES
  *    Calls SDO_CS.TRANSFORM before calling main ST_Area.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2011, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_Area(p_geom      in mdsys.sdo_geometry,
                   p_precision in number,
                   p_srid      in number)
    Return Number Deterministic;

  /****f* SC4O/ST_Length
  *  NAME
  *    ST_Length -- Computes length of supplied linear sdo_geometry
  *  SYNOPSIS
  *    Function ST_Length(p_geom      in mdsys.sdo_geometry,
  *                       p_precision in number)
  *             Return Number Deterministic
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- Geometry subject to length calculation
  *    p_precision (integer) -- Number of decimal places of precision for resulting length.
  *  DESCRIPTION
  *    This function computes the length of the (linear) sdo_geometry parameter.
  *    Result is rounded to p_precision.
  *  RESULT
  *    length (Number) -- Length in SRID unit of measure or in supplied units (p_unit) possibly rounded to SELF.Precision
  *  EXAMPLE
  *    With data as (
  *      Select sdo_geometry(3003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,1, 10,0,2, 10,5,3, 10,10,4, 5,10,5, 5,5,6, 0,0,1)) as geom From Dual union all
  *      select sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10))',28356) as geom From Dual
  *    )
  *    select SC4O.ST_Length(a.geom,3) as length_m
  *      from data a;
  *
  *     AREA_SQ_M
  *    ----------
  *          62.5
  *           399
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2011, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_Length(p_geom      in mdsys.sdo_geometry,
                     p_precision in number)
    Return number Deterministic;

  /****f* SC4O/ST_Length(srid)
  *  NAME
  *    ST_Length -- Computes length of supplied sdo_geometry but in projected SRID.
  *  SYNOPSIS
  *    Function ST_Length(p_geom      in mdsys.sdo_geometry,
  *                       p_precision in number,
  *                       p_srid      in number)
  *             Return Number Deterministic
  *  DESCRIPTION
  *    This function computes the length of the sdo_geometry object, with computations occuring in projected space described by the p_srid parameter.
  *    JTS does not support geographic or geodetic data. Any such data must therefore be transformed in to a suitable projection before calculations can occur.
  *    This function uses sdo_cs.transform before calling SC4O..ST_Length.
  *    Result is rounded to p_precision.
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- Geometry subject to length calculation
  *    p_precision (integer) -- Number of decimal places of precision for resulting lenth.
  *    p_srid      (integer) -- SRID of projected space in which actual overlay occurs before being projected back to p_geom.sdo_srid.
  *  RESULT
  *    length (Number) -- Length in SRID units of measure.
  *  EXAMPLE
  *    With data as (
  *      Select sdo_geometry(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1, 10,0,2, 10,5,3, 10,10,4, 5,10,5, 5,5,6, 0,0,1)) as geom From Dual union all
  *      select sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10))',28356) as geom From Dual
  *    )
  *    select SC4O.ST_Length(a.geom,3) as length_m
  *      from data a;
  *
  *     AREA_SQ_M
  *    ----------
  *          62.5
  *           399
  *  NOTES
  *    Calls SDO_CS.TRANSFORM before calling main ST_Length function.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2011, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_Length(p_geom      in mdsys.sdo_geometry,
                     p_precision in number,
                     p_srid      in number)
    Return Number Deterministic;

  /****f* SC4O/ST_isValid
  *  NAME
  *    ST_isValid -- Computes whether p_geom is valid (by OGC definition)
  *  SYNOPSIS
  *    Function ST_isValid(p_geom in mdsys.sdo_geometry )
  *      Return varchar2 Deterministic,
  *  DESCRIPTION
  *    See also ST_isValidReason
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- Geometry subject to area calculation
  *  RESULT
  *    BOOLEAN (varchar2) -- If mdsys.sdo_geometry is valid returns TRUE else FALSE.
  *  EXAMPLE
  *  NOTES
  *    Is an implementation of OGC ST_isValid method.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_IsValid(p_geom in mdsys.sdo_geometry )
    Return varchar2 Deterministic;

  /****f* SC4O/ST_isValidReason
  *  NAME
  *    ST_isValidReason -- Returns reason why passed in geometry is invalid.
  *  SYNOPSIS
  *    Function ST_isValidReason(p_geom      in mdsys.sdo_geometry,
  *                              p_precision in number)
  *             Return varchar2 Deterministic,
  *  DESCRIPTION
  *    If p_geom is invalid, a descriptive reason for it being invalid is returned.
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- Geometry subject to area calculation
  *    p_precision (integer) -- Number of decimal places of precision for resulting area.
  *  RESULT
  *    result (varchar2) -- Returns reason for invalidity.
  *  EXAMPLE
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_isValidReason(p_geom      in mdsys.sdo_geometry,
                            p_precision in number)
    Return VarChar2 Deterministic;


  /****f* SC4O/ST_isSimple
  *  NAME
  *    ST_isSimple -- Checks if underlying geometry object is simple as per the OGC.
  *  SYNOPSIS
  *    Function ST_isSimple(p_geom in mdsys.sdo_geometry )
  *      Return integer Deterministic,
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- Geometry subject to area calculation
  *  NOTES
  *    Is an implementation of OGC ST_isSimple method.
  *  DESCRIPTION
  *    This function checks to see if the underlying object is simple.
  *    A simple linestring is one for which none of its segments cross each other.
  *    This is not the same as a closed linestring whose start/end points are the same as in a polygon ring.
  *  RESULT
  *    boolean (varchar2) -- TRUE if Simple, FALSE if not..
  *
  *    With data as (
  *      select 'Simple 2 point line' as test,
  *             sdo_geometry('LINESTRING(0 0,1 1)',null) as Geom
  *        from dual union all
  *      select 'Line with 4 Points with two segments crossing' as test,
  *             sdo_geometry('LINESTRING(0 0,1 1,1 0,0 1)',null) as Geom
  *        from dual union all
  *      select 'Line whose start/end points are the same (closed)' as test,
  *             sdo_geometry('LINESTRING(0 0,1 0,1 1,0 1,0 0)',null) as Geom
  *        from dual
  *    )
  *    Select a.test, ST_isSimple(a.Geom) as isSimple
  *      from data a;
  *
  *    TEST                                              ISSIMPLE
  *    ------------------------------------------------- --------
  *    Simple 2 point line                                      1
  *    Line with 4 Points with two segments crossing            0
  *    Line whose start/end points are the same (closed)        1
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_IsSimple(p_geom in mdsys.sdo_geometry )
    Return varchar2 Deterministic;

  /****f* SC4O/ST_Dimension
  *  NAME
  *    ST_Dimension -- Returns spatial dimension of p_geom parameter.
  *  SYNOPSIS
  *    Function ST_Dimension(p_geom in mdsys.sdo_geometry)
  *      Return Integer Deterministic,
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- Geometry subject to area calculation
  *    p_precision (integer) -- Number of decimal places of precision for resulting area.
  *  NOTES
  *    Is an implementation of OGC ST_Dimension method.
  *  EXAMPLE
  *    With data as (
  *      Select sdo_geometry('POINT(0 0)',null) as geom From Dual UNION ALL
  *      Select sdo_geometry('LINESTRING(0 0,10 0,10 5,10 10,5 10,5 5)',null) as geom From Dual UNION ALL
  *      Select sdo_geometry('MULTILINESTRING((-1 -1, 0 -1),(0 0,10 0,10 5,10 10,5 10,5 5))',null) as geom From Dual union all
  *      select sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10))',null) as geom From Dual UNION ALL
  *      Select sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0)),((100 100,200 100,200 200,100 200,100 100)))',null) as geom From Dual union all
  *      Select sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)),((100 100,200 100,200 200,100 200,100 100)))',null) as geom From Dual
  *    )
  *    select ST_GType(a.geom)        as sdo_gtype,
  *           ST_GeometryType(a.geom) as geomType,
  *           ST_Dimension(a.geom)    as geomDim
  *      from data a;
  *
  *    SDO_GTYPE GEOMTYPE             GEOMDIM
  *    --------- -------------------- -------
  *            1 ST_POINT                   0
  *            2 ST_LINESTRING              1
  *            6 ST_MULTILINESTRING         1
  *            3 ST_POLYGON                 2
  *            7 ST_MULTIPOLYGON            2
  *            7 ST_MULTIPOLYGON            2
  *
  *    6 rows selected
  *  DESCRIPTION
  *    Is OGC method that returns the geometric dimension of the underlying geometry.
  *    The dimensions returned are:
  *    GeometryType Dimension
  *    ------------ ---------
  *           Point         0
  *      LineString         1
  *         Polygon         2
  *    OGC Dimension is not to be confused with coordinate dimension ie number of ordinates. See ST_CoordDimension.
  *  RESULT
  *    Dimension (Integer) -- 0 if (Multi)Point; 1 if (Multi)LineString/M=(Multi)LinearRing; 2 (Multi)Polygon etc.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_Dimension(p_geom in mdsys.sdo_geometry)
    Return varchar2 Deterministic;

  /****f* SC4O/ST_CoordDimension
  *  NAME
  *    ST_CoordDimension -- Returns Coordinate Dimension of mdsys.sdo_geometry object.
  *  SYNOPSIS
  *    Function ST_CoordDimension(p_geom in mdsys.sdo_geometry)
  *      Return Integer Deterministic,
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- Geometry subject to area calculation
  *  EXAMPLE
  *    With data as (
  *      Select sdo_geometry('POINT(0 0)',null) as geom From Dual UNION ALL
  *      Select sdo_geometry(3001,NULL,SDO_POINT_TYPE(0,0,0),null,null) as geom From Dual UNION ALL
  *      Select sdo_geometry('LINESTRING(0 0,10 0,10 5,10 10,5 10,5 5)',null) as geom From Dual UNION ALL
  *      Select sdo_geometry(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)) as geom From Dual UNION ALL
  *      Select sdo_geometry('MULTILINESTRING((-1 -1, 0 -1),(0 0,10 0,10 5,10 10,5 10,5 5))',null) as geom From Dual union all
  *      select sdo_geometry('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10))',null) as geom From Dual UNION ALL
  *      Select sdo_geometry('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)),((100 100,200 100,200 200,100 200,100 100)))',null) as geom From Dual
  *    )
  *    select ST_GeometryType(a.geom)   as geomType,
  *           ST_GType(a.geom)          as sdo_gtype,
  *           ST_CoordDimension(a.geom) as coordDim,
  *           ST_Dimension(a.geom)      as geomDim
  *      from data a;
  *
  *    GEOMTYPE             SDO_GTYPE   COORDDIM    GEOMDIM
  *    ------------------- ---------- ---------- ----------
  *    ST_POINT                     1          2          0
  *    ST_POINT                     1          3          0
  *    ST_LINESTRING                2          2          1
  *    ST_LINESTRING                2          3          1
  *    ST_MULTILINESTRING           6          2          1
  *    ST_POLYGON                   3          2          2
  *    ST_MULTIPOLYGON              7          2          2
  *
  *     7 rows selected
  *  DESCRIPTION
  *    Returns number of ordinates that describe a single coordinate within the supplied geometry.
  *    If XY->2;XYZ->3;XYM->3;XYZM->4
  *  RESULT
  *    Coordinate Dimension (SMALLINT) -- If XY->2; iXYZ->3; iXYM->3; iXYZM->4
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_CoordDim(p_geom in mdsys.sdo_geometry)
    Return varchar2 Deterministic;

  /** ============================= EDITORS =====================================*/

/****f* SC4O/ST_DeletePoint(index)
 *  NAME
 *    ST_DeletePoint -- Function which deletes the coordinate at position p_pointIndex from the supplied geometry.
 *  SYNOPSIS
 *    Function ST_DeletePoint(p_geom       in sdo_geometry,
 *                            p_pointIndex in number)
 *      Return mdsys.sdo_geometry deterministic;
 *  DESCRIPTION
 *    Function that deletes the coordinate at position p_pointIndex in the supplied geometry.
 *    p_pointIndex Values:
 *      1. null -> defaults to 0;
 *      2. -1   -> maximum number of points ie ST_NumPoints()
 *      3. Greater than ST_NumPoints() -> maximum number of points ie ST_NumPoints(p_geometry)
 *  ARGUMENTS
 *    p_geom  (sdo_geometry) - Geometry to be modified
 *    p_pointIndex (integer) - Coordinate to be deleted.
 *  RESULT
 *    updated geom (geometry) - Geometry with coordinate deleted.
 *  EXAMPLE
 *    select ST_DeletePoint(
 *             sdo_geometry('LINESTRING(0 0,1 1,2 2)',NULL),
 *             -1
 *           ) as updatedGeom
 *      from dual;
 *
 *    UPDATEDGEOM
 *    -------------------
 *    LINESTRING(0 0,1 1)
 *  ERRORS
 *    Can throw one or other of the following exceptions:
 *    SQLException("Supplied Sdo_Geometry is NULL.");
 *    SQLException("The index (" + _vertexIndex+ ") must be -1 (last coord) or greater or equal than 1" );
 *    SQLException("Deleting vertex from an input point sdo_geometry is not supported." );
 *    SQLException("SDO_Geometry conversion to JTS geometry returned NULL.");
 *    SQLException("Point index (" + _vertexIndex + ") out of range (1.." + numPoints + ")");
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2018 - Original Coding.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Function ST_DeletePoint(p_geom       in sdo_geometry,
                          p_pointIndex in number)
    Return mdsys.sdo_geometry deterministic;

/****f* SC4O/ST_UpdatePoint(point,index)
 *  NAME
 *    ST_UpdatePoint -- Function which updates the coordinate at position v_pointIndex of the underlying geometry with ordinates in v_vertex.x etc.
 *  SYNOPSIS
 *    Function ST_UpdatePoint(p_geom       in sdo_geometry,
 *                            p_point      in sdo_geometry,
 *                            p_pointIndex in number)
 *      Return mdsys.sdo_geometry deterministic;
 *  ARGUMENTS
 *    p_geom        : sdo_geometry : Geometry to be modified
 *    p_point       : sdo_geometry : The point geometry holding the new XYZM values
 *    p_pointIndex  : integer      : Position in input geometry where new point is to be updated (1..NumPoints with -1 being "add to end of existing points")
 *  RESULT
 *    updated geom (geometry) - Geometry with coordinate replaced.
 *  DESCRIPTION
 *    Function that updates coordinate in the underlying geometry identified by p_pointIndex with the ordinate values in p_point.
 *    p_pointIndex Values:
 *      1. null -> defaults to 0 which is at start of geometry;
 *      2. -1   -> maximum number of points ie ST_NumPoints(p_geometry)
 *      3. Greater than ST_NumPoints(p_geometry) -> maximum number of points ie ST_NumPoints(p_geometry)
 *  EXAMPLE
 *    select ST_UpdatePoint(
 *              sdo_geometry('LINESTRING(0 0,2 2)',NULL),
 *              sdo_geometry('POINT(1 1)',null),
 *              2
 *           )
 *      from dual;
 *
 *    UPDATEDGEOM
 *    -------------------
 *    LINESTRING(0 0,1 1)
 *  ERRORS
 *    Can throw one or other of the following exceptions:
 *      SQLException("The index (" + _vertexIndex+ ") must be -1 (last coord) or greater or equal than 1" );
 *      SQLException("SDO_Geometries have different SRIDs.");
 *      SQLException("SDO_Geometries have different coordinate dimensions.");
 *      SQLException("SDO_Geometry conversion to JTS geometry returned NULL.");
 *      SQLException("SDO_Geometry Point conversion to JTS geometry returned NULL.");
 *      SQLException("Provided point is not a Point");
 *      SQLException("Point index (" + _vertexIndex + ") out of range (1.." + numPoints + ")");
 *      SQLException("LinearRings must be closed linestring");
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2011 - Original Coding for GEOM package.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Function ST_UpdatePoint(p_geom       in sdo_geometry,
                          p_point      in sdo_geometry,
                          p_pointIndex in number)
    Return mdsys.sdo_geometry deterministic;

/****f* SC4O/ST_UpdatePoint(fromPoint,toPoint)
 *  NAME
 *    ST_UpdatePoint -- Function that updates (replaces) all geometry points that are equal to the supplied point with the replacement point.
 *  SYNOPSIS
 *    Function ST_UpdatePoint(p_geom      in mdsys.sdo_geometry,
 *                            p_fromPoint in mdsys.sdo_geometry,
 *                            p_toPoint   in mdsys.sdo_geometry)
 *      Return mdsys.sdo_geometry deterministic;
 *  DESCRIPTION
 *    Function that updates all coordinates that equal p_fromPoint with the supplied p_toPoint.
 *  NOTES
 *    This version of ST_UpdatePoint allows for the update of the first and last vertex in a polygon thereby not invalidating it.
 *  ARGUMENTS
 *    p_geom      (sdo_geometry) - Geometry to be modified
 *    p_fromPoint (sdo_geometry) - Original coordinate to be replaced.
 *    p_toPoint   (sdo_geometry) - Replacement coordinate
 *  RESULT
 *    geometry (geometry) - Underlying geometry with one or more coordinates replaced.
 *  EXAMPLE
 *    select ST_UpdatePoint(
 *              sdo_geometry('POLYGON((0 0,10 0,10 10,0 10,0 0))',NULL),
 *              sdo_geometry('POINT(0 0)',null),
 *              sdo_geometry('POINT(1 1)',null)
 *           ) as updatedGeom
 *      from dual;
 *
 *    UPDATEDGEOM
 *    ---------------------------------------
 *    POLYGON ((1 1, 10 0, 10 10, 0 10, 1 1))
 *  ERRORS
 *    SQLException("SDO_Geometries have different SRIDs.");
 *    SQLException("SDO_Geometries have different coordinate dimensions.");
 *    SQLException("SDO_Geometry conversion to JTS geometry returned NULL.");
 *    SQLException("SDO_Geometry fromVertex conversion to JTS geometry returned NULL.");
 *    SQLException("Provided fromVertex is not a Point");
 *    SQLException("SDO_Geometry toVertex conversion to JTS geometry returned NULL.");
 *    SQLException("Provided toVertex is not a Point");
 *    SQLException("Geometry must have at least one point");
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - October 2018 - Original Coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
  Function ST_UpdatePoint(p_geom      in mdsys.sdo_geometry,
                          p_fromPoint in mdsys.sdo_geometry,
                          p_toPoint   in mdsys.sdo_geometry)
    Return mdsys.sdo_geometry deterministic;

/****f* SC4O/ST_InsertPoint(point,pointIndex)
 *  NAME
 *    ST_InsertPoint -- Function which inserts new coordinate (p_point) at position p_pointIndex into the supplied geometry.
 *  SYNOPSIS
 *    Function ST_InsertPoint(p_geom       in sdo_geometry,
 *                            p_point      in sdo_geometry,
 *                            p_pointIndex in number)
 *             )
 *     Returns mdsys.sdo_geometry determinisitic
 *  DESCRIPTION
 *    Function that inserts p_point into into supplied geometry as position p_pointIndex
 *    All existing vertices are shuffled down ie Insert is "add before" except at end.
 *    Supplied p_point must have Z and M coded correctly if p_geom has Z and M ordinates.
 *    p_pointIndex values:
 *      1. null -> defaults to 1;
 *      2. -1   -> maximum number of points ie _NumPoints()
 *      3. Greater than ST_NumPoints() -> maximum number of points ie ST_NumPoints()
 *  ARGUMENTS
 *    p_geom        : sdo_geometry : Geometry to be modified
 *    p_point       : sdo_geometry : The point geometry holding the new XYZM values
 *    p_pointIndex  : integer      : Position in input geometry where new point is to be inserted (1..NumPoints with -1 being "add to end of existing points")
 *  RESULT
 *    geometry -- Geometry with coordinate inserted.
 *  EXAMPLE
 *    -- Insert 2D Point into 2D linestring
 *    select ST_InsertPoint(
 *              sdo_geometry('LINESTRING(0 0,2 2)',null),
 *              sdo_geometry('POINT(1,1)',null),
 *              2
 *           ) as UpdatedGeom
 *      from dual;
 *
 *    NEWGEOM
 *    --------------------------
 *    LINESTRING (0 0, 1 1, 2 2)
 *
 *    -- Update 3D point....
 *    select ST_InsertPoint(
 *              sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,1, 2,2,2)),0.005,2,1)
 *              sdo_geometry(3001,NULL,sdo_point_type(1.5,1.5,1.5),null,null),
 *              2
 *           ) as UpdatedGeom
 *      from dual;
 *
 *    UPDATEDGEOM
 *    ---------------------------------------------------------------------------------------------
 *    SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,1.5,1.5,1.5))
 *
 *    -- Insert 3D point into 3D linestring.
 *    select ST_InsertPoint(
 *              sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,1,2,2,2)),
 *              sdo_geometry(3001,null,null,sdo_elem_info_array(1,1,1),sdo_ordinate_array(1,1,1,5)),
 *              2
 *           ).geom as newGeom
 *      from dual;
 *
 *    NEWGEOM
 *    -----------------------------------------------------------------------------------------------
 *    SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,1,1,1.5,2,2,2))
 *  ERRORS
 *    Can throw one or other of the following exceptions:
 *      SQLException("The index (" + _vertexIndex+ ") must be -1 (last coord) or greater or equal than 1" );
 *      SQLException("SDO_Geometries have different SRIDs.");
 *      SQLException("SDO_Geometries have different coordinate dimensions.");
 *      SQLException("SDO_Geometry conversion to JTS geometry returned NULL.");
 *      SQLException("SDO_Geometry Point conversion to JTS geometry returned NULL.");
 *      SQLException("Provided point is not a Point");
 *      SQLException("Point index (" + _vertexIndex + ") out of range (1.." + numPoints + ")");
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - January 2011 - Original coding.
 *  COPYRIGHT
 *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Function ST_InsertPoint(p_geom       in sdo_geometry,
                          p_point      in sdo_geometry,
                          p_pointIndex in number)
    Return mdsys.sdo_geometry deterministic;

  /****f* SC4O/ST_Envelope
  *  NAME
  *    ST_Envelope - Method for getting MBR or envelope of a geometry object
  *  SYNOPSIS
  *    Function ST_Envelope(p_geom      in mdsys.sdo_geometry,
  *                         p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    ST_OffsetLine is implemented using JTS buffering and point removal functions.
  *  ARGUMENTS
  *    p_geom (sdo_geometry) : Any non-null geometry
  *    p_precision (integer) : Number of decimal places of precision
  *  EXAMPLE
  *
  *  RESULT
  *    MBR as Polygon (sdo_geometry) : MBR as 5 point polygon.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2012, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *     http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_Envelope(p_geom      in mdsys.sdo_geometry,
                       p_precision in number)
    Return mdsys.sdo_geometry
   deterministic;

  /** ========================== Utility ======================== **/

  /****f* SC4O/ST_MakeEnvelope
  *  NAME
  *    ST_MakeEnvelope - Method for turning the two corners of an MBR or envelope into a geometry object.
  *  SYNOPSIS
  *    Function ST_MakeEnvelope(p_minx      in number,
  *                             p_miny      in number,
  *                             p_maxx      in number,
  *                             p_maxy      in number,
  *                             p_srid      in number,
  *                             p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    ST_MakeEnvelope - Method for turning the two corners of an MBR or envelope into a geometry object.
  *  ARGUMENTS
  *    p_minx      (number)  -- minimum x ordinate of MBR
  *    p_miny      (number)  -- minimum y ordinate of MBR
  *    p_maxx      (number)  -- maximum x ordinate of MBR
  *    p_maxx      (number)  -- maximum y ordinate of MBR
  *    p_srid      (integer) -- srid of returned geometry
  *    p_precision (integer) -- number of decimal places of precision when comparing ordinates.
  *  EXAMPLE
  *
  *  RESULT
  *    Polygon (sdo_geometry) : MBR as 5 point polygon.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2012, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *     http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_MakeEnvelope(p_minx      in number,
                           p_miny      in number,
                           p_maxx      in number,
                           p_maxy      in number,
                           p_srid      in number,
                           p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

  /** ========================== Collection ======================== **/

/****f* SC4O/ST_Collect
  *  NAME
  *    ST_Collect - Turns array of sdo_geometry objects into single multipart geometry.
  *  SYNOPSIS
  *    Function ST_Collect(p_geomList    in mdsys.sdo_geometry_array,
  *                        p_returnMulti in number default 0)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    ST_Collect takes the supplied sdo_geometry_array and returns a single sdo_geometry object.
  *    The returned sdo_geometry object is a GeometryCollection if p_returnMulti is false, or a Multi-geometry if true.
  *  ARGUMENTS
  *    p_geomList (sdo_geometry_array) : An array of (normally homogeneous) sdo_geometry objects.
  *    p_returnMulti         (integer) : If false (0) a GeometryCollection is returned otherwise a Multi Point/Line/Polygon object.
  *  EXAMPLE
  *
  *  RESULT
  *    Multi or collection object (sdo_geometry)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2012, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *     http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
 Function ST_Collect(p_geomList    in mdsys.sdo_geometry_array,
                     p_returnMulti in number default 0)
    Return mdsys.sdo_geometry Deterministic;

  /** ========================== OVERLAY ======================== **/

 /****f* SC4O/ST_Union
  *  NAME
  *    ST_Union -- Unions two geometries together.
  *  SYNOPSIS
  *    Function ST_Union(p_geom1     in mdsys.sdo_geometry,
  *                      p_geom2     in mdsys.sdo_geometry,
  *                      p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    This function determines the unoin of two linestrings, polygons or a mix of either.
  *    Computes union between two geometries using suppied p_precision to compare coordinates.
  *  ARGUMENTS
  *    p_geom1 (sdo_geometry) -- First geometry subject to overlay action
  *    p_geom2 (sdo_geometry) -- Second geometry subject to overlay action
  *    p_precision  (integer) -- Number of decimal places of precision when comparing ordinates.
  *  RESULT
  *    geometry (sdo_geometry) -- Result of unioning the geometries.
  *  ERRORS
  *    Will throw on of the following exceptions:
  *       SQLException("ST_Union: One or other of supplied Sdo_Geometries is NULL.");
  *       SQLException("ST_Union: SDO_Geometry SRIDs not equal");
  *       SQLException("ST_Union: Converted first geometry is NULL.");
  *       SQLException("ST_Union: Converted first geometry is invalid.");
  *       SQLException("ST_Union: Converted second geometry is NULL.");
  *       SQLException("ST_Union: Converted second geometry is invalid.");
  *    Plus any processing error thrown by JTS when executing intersection.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *  LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *             http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_Union(p_geom1     in mdsys.sdo_geometry,
                    p_geom2     in mdsys.sdo_geometry,
                    p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

 /****f* SC4O/ST_Union(srid)
  *  NAME
  *    ST_Union -- Unions two geometries together in projected space of p_srid.
  *  SYNOPSIS
  *    Function ST_Union(p_geom1     in mdsys.sdo_geometry,
  *                      p_geom2     in mdsys.sdo_geometry,
  *                      p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    This function determines the unoin of two linestrings, polygons or a mix of either.
  *    Computes union between two geometries using suppied p_precision to compare coordinates.
  *    Wrapper function over ST_Union that computes geometry union in projected space described by p_srid parameter.
  *  ARGUMENTS
  *    p_geom1 (sdo_geometry) -- First geometry subject to overlay action
  *    p_geom2 (sdo_geometry) -- Second geometry subject to overlay action
  *    p_precision  (integer) -- Number of decimal places of precision when comparing ordinates.
  *    p_srid       (integer) -- SRID of projected space in which actual overlay occurs before being projected back to p_srid.
  *  RESULT
  *    geometry (sdo_geometry) -- Result of unioning the geometries.
  *  ERRORS
  *    Will throw on of the following exceptions:
  *       SQLException("ST_Union: One or other of supplied Sdo_Geometries is NULL.");
  *       SQLException("ST_Union: SDO_Geometry SRIDs not equal");
  *       SQLException("ST_Union: Converted first geometry is NULL.");
  *       SQLException("ST_Union: Converted first geometry is invalid.");
  *       SQLException("ST_Union: Converted second geometry is NULL.");
  *       SQLException("ST_Union: Converted second geometry is invalid.");
  *       Plus any processing error thrown by JTS when executing intersection.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_Union(p_geom1             in mdsys.sdo_geometry,
                    p_geom2             in mdsys.sdo_geometry,
                    p_precision         in number,
                    p_srid              in number)
    Return mdsys.sdo_geometry Deterministic;

 /****f* SC4O/ST_Difference
  *  NAME
  *    ST_Difference -- Computes the spatial difference between two sdo_geometry objects.
  *  SYNOPSIS
  *    Function ST_Difference(p_geom1     in mdsys.sdo_geometry,
  *                           p_geom2     in mdsys.sdo_geometry,
  *                           p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    This function determines the difference between two linestrings, polygons or a mix of either.
  *    Computes difference between two geometries using suppied p_precision to compare coordinates.
  *  ARGUMENTS
  *    p_geom1 (sdo_geometry) -- First geometry subject to overlay action
  *    p_geom2 (sdo_geometry) -- Second geometry subject to overlay action
  *    p_precision  (integer) -- Number of decimal places of precision when comparing ordinates.
  *  RESULT
  *    geometry (sdo_geometry) -- Result of differencing the geometries.
  *  ERRORS
  *    Will throw on of the following exceptions:
  *       SQLException("ST_Difference: One or other of supplied Sdo_Geometries is NULL.");
  *       SQLException("ST_Difference: SDO_Geometry SRIDs not equal");
  *       SQLException("ST_Difference: Converted first geometry is NULL.");
  *       SQLException("ST_Difference: Converted first geometry is invalid.");
  *       SQLException("ST_Difference: Converted second geometry is NULL.");
  *       SQLException("ST_Difference: Converted second geometry is invalid.");
  *       Plus any processing error thrown by JTS when executing intersection.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_Difference(p_geom1     in mdsys.sdo_geometry,
                         p_geom2     in mdsys.sdo_geometry,
                         p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

 /****f* SC4O/ST_Difference(srid)
  *  NAME
  *    ST_Difference -- Computes the spatial difference between two sdo_geometry objects.
  *  SYNOPSIS
  *    Function ST_Difference(p_geom1     in mdsys.sdo_geometry,
  *                           p_geom2     in mdsys.sdo_geometry,
  *                           p_precision in number,
  *                           p_srid      in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    This function determines the difference between two linestrings, polygons or a mix of either.
  *    Computes difference between two geometries using suppied p_precision to compare coordinates.
  *    Wrapper function over ST_Union that computes geometry difference in projected space describe by p_srid parameter.
  *  ARGUMENTS
  *    p_geom1 (sdo_geometry) -- First geometry subject to overlay action
  *    p_geom2 (sdo_geometry) -- Second geometry subject to overlay action
  *    p_precision  (integer) -- Number of decimal places of precision when comparing ordinates.
  *    p_srid       (integer) -- SRID of projected space in which actual overlay occurs before being projected back to p_srid.
  *  RESULT
  *    geometry (sdo_geometry) -- Result of differencing the geometries.
  *  ERRORS
  *    Will throw on of the following exceptions:
  *       SQLException("ST_Difference: One or other of supplied Sdo_Geometries is NULL.");
  *       SQLException("ST_Difference: SDO_Geometry SRIDs not equal");
  *       SQLException("ST_Difference: Converted first geometry is NULL.");
  *       SQLException("ST_Difference: Converted first geometry is invalid.");
  *       SQLException("ST_Difference: Converted second geometry is NULL.");
  *       SQLException("ST_Difference: Converted second geometry is invalid.");
  *       Plus any processing error thrown by JTS when executing intersection.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_Difference(p_geom1     in mdsys.sdo_geometry,
                         p_geom2     in mdsys.sdo_geometry,
                         p_precision in number,
                         p_srid      in number)
    Return mdsys.sdo_geometry Deterministic;

 /****f* SC4O/ST_Intersection
  *  NAME
  *    ST_Intersection -- Returns the spatial intersection of two sdo_geometry objects.
  *  SYNOPSIS
  *    Function ST_Intersection(p_geom1     in mdsys.sdo_geometry,
  *                             p_geom2     in mdsys.sdo_geometry,
  *                             p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    This function intersects two linestrings, polygons or a mix of either.
  *    Computes intersection between two geometries using suppied p_precision to compare coordinates.
  *    Intersection could result in a Point, Line, Polygon or GeometryCollection.
  *  ARGUMENTS
  *    p_geom1 (sdo_geometry) -- First geometry subject to overlay action
  *    p_geom2 (sdo_geometry) -- Second geometry subject to overlay action
  *    p_precision  (integer) -- Number of decimal places of precision when comparing ordinates.
  *  RESULT
  *    geometry (T_GEOMETRY) -- Result of intersecting the geometries.
  *  ERRORS
  *    Will throw on of the following exceptions:
  *       SQLException("ST_Intersection: One or other of supplied Sdo_Geometries is NULL.");
  *       SQLException("ST_Intersection: SDO_Geometry SRIDs not equal");
  *       SQLException("ST_Intersection: Converted first geometry is NULL.");
  *       SQLException("ST_Intersection: Converted first geometry is invalid.");
  *       SQLException("ST_Intersection: Converted second geometry is NULL.");
  *       SQLException("ST_Intersection: Converted second geometry is invalid.");
  *       Plus any processing error thrown by JTS when executing intersection.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_Intersection(p_geom1     in mdsys.sdo_geometry,
                           p_geom2     in mdsys.sdo_geometry,
                           p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

 /****f* SC4O/ST_Intersection(srid)
  *  NAME
  *    ST_Intersection -- Returns the spatial intersection of two sdo_geometry objects.
  *  SYNOPSIS
  *    Function ST_Intersection(p_geom1     in mdsys.sdo_geometry,
  *                             p_geom2     in mdsys.sdo_geometry,
  *                             p_precision in number,
  *                             p_srid      in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Wrapper Function that enables computation of geometry intersection for geodetic (long/lat)
  *    geometries.  Computations occur in projected space described by p_srid parameter.
  *    This function intersects two linestrings, polygons or a mix of either.
  *    Computes intersection between two geometries using suppied p_precision to compare coordinates.
  *    Intersection could result in a Point, Line, Polygon or GeometryCollection.
  *  ARGUMENTS
  *    p_geom1 (sdo_geometry) -- First geometry subject to overlay action
  *    p_geom2 (sdo_geometry) -- Second geometry subject to overlay action
  *    p_precision  (integer) -- Number of decimal places of precision when comparing ordinates.
  *    p_srid       (integer) -- SRID of projected space in which actual overlay occurs before being projected back to p_srid.
  *  RESULT
  *    geometry (T_GEOMETRY) -- Result of intersecting the geometries.
  *  ERRORS
  *    Will throw on of the following exceptions:
  *       SQLException("ST_Intersection: One or other of supplied Sdo_Geometries is NULL.");
  *       SQLException("ST_Intersection: SDO_Geometry SRIDs not equal");
  *       SQLException("ST_Intersection: Converted first geometry is NULL.");
  *       SQLException("ST_Intersection: Converted first geometry is invalid.");
  *       SQLException("ST_Intersection: Converted second geometry is NULL.");
  *       SQLException("ST_Intersection: Converted second geometry is invalid.");
  *       Plus any processing error thrown by JTS when executing intersection.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_Intersection(p_geom1     in mdsys.sdo_geometry,
                           p_geom2     in mdsys.sdo_geometry,
                           p_precision in number,
                           p_srid      in number )
    Return mdsys.sdo_geometry Deterministic;

 /****f* SC4O/ST_XOR
  *  NAME
  *    ST_XOR -- Returns the spatial Symmetric Difference of two sdo_geometry objects.
  *  SYNOPSIS
  *    Function ST_XOR(p_geom1     in mdsys.sdo_geometry,
  *                    p_geom2     in mdsys.sdo_geometry,
  *                    p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    This function exeuctes the symmetric difference between two linestrings, polygons or a mix of either.
  *    Computes intersection between two geometries using suppied p_precision to compare coordinates.
  *  ARGUMENTS
  *    p_geom1 (sdo_geometry) -- First geometry subject to overlay action
  *    p_geom2 (sdo_geometry) -- Second geometry subject to overlay action
  *    p_precision  (integer) -- Number of decimal places of precision when comparing ordinates.
  *  RESULT
  *    geometry (T_GEOMETRY) -- Symmetric difference of the geometries.
  *  ERRORS
  *    Will throw on of the following exceptions:
  *       SQLException("ST_XOR: One or other of supplied Sdo_Geometries is NULL.");
  *       SQLException("ST_XOR: SDO_Geometry SRIDs not equal");
  *       SQLException("ST_XOR: Converted first geometry is NULL.");
  *       SQLException("ST_XOR: Converted first geometry is invalid.");
  *       SQLException("ST_XOR: Converted second geometry is NULL.");
  *       SQLException("ST_XOR: Converted second geometry is invalid.");
  *       Plus any processing error thrown by JTS when executing symmetric difference.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_Xor(p_geom1     in mdsys.sdo_geometry,
                  p_geom2     in mdsys.sdo_geometry,
                  p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

 /****f* SC4O/ST_XOR(srid)
  *  NAME
  *    ST_XOR -- Returns the spatial Symmetric Difference of two sdo_geometry objects.
  *  SYNOPSIS
  *    Function ST_XOR(p_geom1     in mdsys.sdo_geometry,
  *                    p_geom2     in mdsys.sdo_geometry,
  *                    p_precision in number,
  *                    p_srid      in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    This function exeuctes the symmetric difference between two linestrings, polygons or a mix of either.
  *    Computes intersection between two geometries using suppied p_precision to compare coordinates.
  *    Is a wrapper function for ST_XOR as it enables computation of geometry xor for geodetic (long/lat)
  *    geometries.  Computations occur in projected space described by p_srid parameter.
  *  ARGUMENTS
  *    p_geom1 (sdo_geometry) -- First geometry subject to overlay action
  *    p_geom2 (sdo_geometry) -- Second geometry subject to overlay action
  *    p_precision  (integer) -- Number of decimal places of precision when comparing ordinates.
  *    p_srid       (integer) -- SRID of projected space in which actual overlay occurs before being projected back to p_srid.
  *  RESULT
  *    geometry (T_GEOMETRY) -- Symmetric difference of the geometries.
  *  ERRORS
  *    Will throw on of the following exceptions:
  *       SQLException("ST_XOR: One or other of supplied Sdo_Geometries is NULL.");
  *       SQLException("ST_XOR: SDO_Geometry SRIDs not equal");
  *       SQLException("ST_XOR: Converted first geometry is NULL.");
  *       SQLException("ST_XOR: Converted first geometry is invalid.");
  *       SQLException("ST_XOR: Converted second geometry is NULL.");
  *       SQLException("ST_XOR: Converted second geometry is invalid.");
  *       Plus any processing error thrown by JTS when executing symmetric difference.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_Xor(p_geom1     in mdsys.sdo_geometry,
                  p_geom2     in mdsys.sdo_geometry,
                  p_precision in number,
                  p_srid      in number)
    Return mdsys.sdo_geometry
   Deterministic;

 /****f* SC4O/ST_SymDifference
  *  NAME
  *    ST_SymDifference -- Returns the spatial symmetric difference (XOR) of two sdo_geometry objects.
  *  SYNOPSIS
  *    Function ST_SymDifference(p_geom1     in mdsys.sdo_geometry,
  *                              p_geom2     in mdsys.sdo_geometry,
  *                              p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    This function exeuctes the symmetric difference between two linestrings, polygons or a mix of either.
  *    Computes intersection between two geometries using suppied p_precision to compare coordinates.
  *    This function is an alias of ST_XOR
  *  ARGUMENTS
  *    p_geom1 (sdo_geometry) -- First geometry subject to overlay action
  *    p_geom2 (sdo_geometry) -- Second geometry subject to overlay action
  *    p_precision  (integer) -- Number of decimal places of precision when comparing ordinates.
  *  RESULT
  *    geometry (T_GEOMETRY) -- Symmetric difference of the geometries.
  *  ERRORS
  *    Will throw on of the following exceptions:
  *       SQLException("ST_SymDifference: One or other of supplied Sdo_Geometries is NULL.");
  *       SQLException("ST_SymDifference: SDO_Geometry SRIDs not equal");
  *       SQLException("ST_SymDifference: Converted first geometry is NULL.");
  *       SQLException("ST_SymDifference: Converted first geometry is invalid.");
  *       SQLException("ST_SymDifference: Converted second geometry is NULL.");
  *       SQLException("ST_SymDifference: Converted second geometry is invalid.");
  *       Plus any processing error thrown by JTS when executing symmetric difference.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_SymDifference(p_geom1     in mdsys.sdo_geometry,
                            p_geom2     in mdsys.sdo_geometry,
                            p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

 /****f* SC4O/ST_SymDifference(srid)
  *  NAME
  *    ST_SymDifference -- Returns the spatial Symmetric Difference (XOR) of two sdo_geometry objects.
  *  SYNOPSIS
  *    Function ST_SymDifference(p_geom1     in mdsys.sdo_geometry,
  *                              p_geom2     in mdsys.sdo_geometry,
  *                              p_precision in number,
  *                              p_srid      in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    This function exeuctes the symmetric difference between two linestrings, polygons or a mix of either.
  *    Computes intersection between two geometries using suppied p_precision to compare coordinates.
  *    Is a wrapper function for ST_XOR as it enables computation of geometry xor for geodetic (long/lat)
  *    geometries.  Computations occur in projected space described by p_srid parameter.
  *  ARGUMENTS
  *    p_geom1 (sdo_geometry) -- First geometry subject to overlay action
  *    p_geom2 (sdo_geometry) -- Second geometry subject to overlay action
  *    p_precision  (integer) -- Number of decimal places of precision when comparing ordinates.
  *    p_srid       (integer) -- SRID of projected space in which actual overlay occurs before being projected back to p_srid.
  *  RESULT
  *    geometry (T_GEOMETRY) -- Symmetric difference of the geometries.
  *  ERRORS
  *    Will throw on of the following exceptions:
  *       SQLException("ST_SymDifference: One or other of supplied Sdo_Geometries is NULL.");
  *       SQLException("ST_SymDifference: SDO_Geometry SRIDs not equal");
  *       SQLException("ST_SymDifference: Converted first geometry is NULL.");
  *       SQLException("ST_SymDifference: Converted first geometry is invalid.");
  *       SQLException("ST_SymDifference: Converted second geometry is NULL.");
  *       SQLException("ST_SymDifference: Converted second geometry is invalid.");
  *       Plus any processing error thrown by JTS when executing symmetric difference.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_SymDifference(p_geom1     in mdsys.sdo_geometry,
                            p_geom2     in mdsys.sdo_geometry,
                            p_precision in number,
                            p_srid      in number )
    Return mdsys.sdo_geometry Deterministic;

  /** ================ Comparisons ================= */

 /****f* SC4O/ST_HausdorffSimilarityMeasure
  *  NAME
  *    ST_HausdorffSimilarityMeasure - Measures the degree of similarity between two sdo_geometrys using JTS's Hausdorff distance metric.
  *  SYNOPSIS
  *    Function ST_HausdorffSimilarityMeasure(p_poly1     in mdsys.sdo_geometry,
  *                                           p_poly2     in mdsys.sdo_geometry,
  *                                           p_precision in number )
  *      Return number deterministic;
  *  DESCRIPTION
  *    Measures the degree of similarity between two sdo_geometrys using JTS's Hausdorff distance metric.
  *    The measure is normalized to lie in the range [0, 1].
  *    Higher measures indicate a great degree of similarity.
  *    The measure is computed by computing the Hausdorff distance between the input geometries,
  *    and then normalizing this by dividing it by the diagonal distance across the envelope of the combined geometries.
  *  ARGUMENTS
  *    p_geom1 (sdo_geometry) -- First geometry subject to comparison
  *    p_geom2 (sdo_geometry) -- Second geometry subject to comparison
  *    p_precision  (integer) -- Number of decimal places of precision
  *  RETURNS
  *    Comparison value (number) -- Result of comparison
  *  NOTES
  *    Currently experimental and incomplete.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_HausdorffSimilarityMeasure(p_geom1     in mdsys.sdo_geometry,
                                         p_geom2     in mdsys.sdo_geometry,
                                         p_precision in number)
    Return number deterministic;

 /****f* SC4O/ST_HausdorffSimilarityMeasure(srid)
  *  NAME
  *    ST_HausdorffSimilarityMeasure - Measures the degree of similarity between two sdo_geometrys using JTS's Hausdorff distance metric.
  *  SYNOPSIS
  *    Function ST_HausdorffSimilarityMeasure(p_poly1     in mdsys.sdo_geometry,
  *                                           p_poly2     in mdsys.sdo_geometry,
  *                                           p_precision in number,
  *                                           p_srid      in number )
  *      Return number deterministic;
  *  DESCRIPTION
  *    Measures the degree of similarity between two sdo_geometrys using JTS's Hausdorff distance metric.
  *    The measure is normalized to lie in the range [0, 1].
  *    Higher measures indicate a great degree of similarity.
  *    The measure is computed by computing the Hausdorff distance between the input geometries,
  *    and then normalizing this by dividing it by the diagonal distance across the envelope of the combined geometries.
  *  ARGUMENTS
  *    p_geom1 (sdo_geometry) -- First geometry subject to comparison
  *    p_geom2 (sdo_geometry) -- Second geometry subject to comparison
  *    p_precision  (integer) -- Number of decimal places of precision
  *    p_srid       (integer) -- SRID of projected space in which actual overlay occurs before being projected back to p_geom1.sdo_srid.
  *  RETURNS
  *    Comparison value (number) -- Result of comparison
  *  NOTES
  *    Both geometries are projected to p_srid before the ST_HausdorffSimilarityMeasure JTS function is called.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_HausdorffSimilarityMeasure(p_geom1     in mdsys.sdo_geometry,
                                         p_geom2     in mdsys.sdo_geometry,
                                         p_precision in number,
                                         p_srid      in number )
    Return number deterministic;

 /****f* SC4O/ST_AreaSimilarityMeasure
  *  NAME
  *    ST_AreaSimilarityMeasure - Measures the degree of similarity between the two Geometries
  *  SYNOPSIS
  *    Function ST_AreaSimilarityMeasure(p_poly1     in mdsys.sdo_geometry,
  *                                      p_poly2     in mdsys.sdo_geometry,
  *                                      p_precision in number )
  *      Return number deterministic;
  *  DESCRIPTION
  *    Measures the degree of similarity between the supplied Geometries using the area of intersection between the geometries.
  *    The measure is normalized to lie in the range [0, 1]. Higher measures indicate a great degree of similarity.
  *  ARGUMENTS
  *    p_geom1 (sdo_geometry) -- First geometry subject to comparison
  *    p_geom2 (sdo_geometry) -- Second geometry subject to comparison
  *    p_precision  (integer) -- Number of decimal places of precision
  *  RETURNS
  *    Comparison value (number) -- Result of comparison
  *  NOTES
  *    Currently experimental and incomplete.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_AreaSimilarityMeasure(p_poly1     in mdsys.sdo_geometry,
                                    p_poly2     in mdsys.sdo_geometry,
                                    p_precision in number)
    Return number deterministic;

 /****f* SC4O/ST_AreaSimilarityMeasure(srid)
  *  NAME
  *    ST_AreaSimilarityMeasure - Measures the degree of similarity between the two Geometries
  *  SYNOPSIS
  *    Function ST_AreaSimilarityMeasure(p_poly1     in mdsys.sdo_geometry,
  *                                      p_poly2     in mdsys.sdo_geometry,
  *                                      p_precision in number,
  *                                      p_srid      in number )
  *      Return number deterministic;
  *  DESCRIPTION
  *    Measures the degree of similarity between the supplied Geometries using the area of intersection between the geometries.
  *    The measure is normalized to lie in the range [0, 1]. Higher measures indicate a great degree of similarity.
  *  ARGUMENTS
  *    p_geom1 (sdo_geometry) -- First geometry subject to comparison
  *    p_geom2 (sdo_geometry) -- Second geometry subject to comparison
  *    p_precision  (integer) -- Number of decimal places of precision
  *    p_srid       (integer) -- SRID of projected space in which actual overlay occurs before being projected back to p_geom1.sdo_srid.
  *  RETURNS
  *     Comparison value (number) -- Result of comparison
  * NOTES
  *   Currently experimental and incomplete.
  *    Both geometries are projected to p_srid before the ST_HausdorffSimilarityMeasure JTS function is called.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_AreaSimilarityMeasure(p_poly1     in mdsys.sdo_geometry,
                                    p_poly2     in mdsys.sdo_geometry,
                                    p_precision in number,
                                    p_srid      in number )
    Return number deterministic;

 /****f* SC4O/ST_Relate
  *  NAME
  *    ST_Relate - Determines spatial relations between two geometry instances.
  *  SYNOPSIS
  *    Function ST_Relate(p_geom1     in mdsys.sdo_geometry,
  *                       p_mask      in varchar2,
  *                       p_geom2     in mdsys.sdo_geometry,
  *                       p_precision in number)
  *      Return varchar2 Deterministic;
  *  DESCRIPTION
  *    Compares the first geometry against the second to discover if the two geometry objects have the required relationship.
  *    If the ANYINTERACT keyword is passed in mask, the function returns TRUE if two geometries not DISJOINT.
  *    If one does not know what relationships might exist, set the parameter p_mask to the value DETERMINE to discover what relationships exist.
  *    If a DE-9IM Matrix string is supplied for p_mask the function will return TRUE if the mask correctly describes the geometry relationships
  *    or FALSE otherwise.
  *    The returned relationship names are not the same as SDO_GEOM.RELATE:
  *  ARGUMENTS
  *    p_geom1 (sdo_geometry) -- Geometry which will be compared to second
  *    p_mask      (varchar2) -- Mask containing DETERMINE or a list of comma separated topological relationships
  *    p_geom2 (sdo_geometry) -- geometry which will be compared to first.
  *    p_precision  (integer) -- Number of decimal places of precision of a geometry
  *  RESULT
  *    Relationships (varchar) - Comma separated list of topological relationships.
  *  ERRORS
  *    Any exceptions thrown internally are passed back as the function result as follows:
  *      ERROR: One or other of supplied Sdo_Geometries is NULL.
  *      ERROR: First geometry has circular arcs that JTS does not support.
  *      ERROR: Second geometry has circular arcs that JTS does not support.
  *      ERROR: Converted first geometry is NULL.
  *      ERROR: Converted first geometry is invalid.
  *      ERROR: Converted second geometry is NULL.
  *      ERROR: Converted second geometry is invalid.
  *  EXAMPLE
  *    Select SC4O.ST_Relate(
  *             sdo_geometry('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',NULL),
  *             'DETERMINE',
  *             sdo_geometry('POLYGON ((-175.0 0.0, 100.0 0.0, 0.0 75.0, 100.0 75.0, 100.0 200.0, 200.0 325.0, 200.0 525.0, -175.0 525.0, -175.0 0.0))',NULL),
  *             2
  *           ) as relations
  *      from dual;
  *
  *    RELATIONS
  *    ------------------
  *    INTERSECTS,OVERLAP   -> Oracle: OVERLAPBDYINTERSECT
  *
  *    Select SC4O.ST_Relate(
  *             sdo_geometry('LINESTRING (100.0 0.0, 400.0 0.0)',NULL),
  *             'DETERMINE',
  *             sdo_geometry('LINESTRING (90.0 0.0, 100.0 0.0)',NULL),
  *             2
  *           ) as relations
  *      from dual;
  *
  *    RELATIONS
  *    ----------------
  *    INTERSECTS,TOUCH --> Oracle: TOUCH
  *
  *    Select SC4O.ST_Relate(
  *             sdo_geometry('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',NULL),
  *             'DETERMINE',
  *             sdo_geometry('POINT (250 150)',NULL),
  *             2
  *           ) as relations
  *      from dual;
  *
  *    RELATIONS
  *    --------------------------
  *    CONTAINS,COVERS,INTERSECTS --> Oracle: CONTAINS
  *
  *    -- Example using different precision values and a specific "question": Are they equal?
  *
  *    Select t.intValue as precision,
  *           SC4O.ST_Relate(
  *             sdo_geometry('POINT (250.001 150.0)'    ,NULL),
  *             'EQUAL',
  *             sdo_geometry('POINT (250.0   150.002)',NULL),
  *             t.intvalue
  *           ) as relations
  *      from table(SPDBA.tools.GENERATE_SERIES(0,3,1)) t
  *
  *    PRECISION RELATIONS
  *    --------- ---------
  *            0 EQUAL
  *            1 EQUAL
  *            2 EQUAL
  *            3 FALSE
  *
  *    Example using 9DIM mask to check for equality
  *    Select SC4O.ST_Relate(
  *             sdo_geometry('POINT (250.001 150.0)'    ,NULL),
  *             '0FFFFFFF2',
  *             sdo_geometry('POINT (250.0   150.002)',NULL),
  *             t.intvalue
  *           ) as relations
  *      from dual;
  *
  *    RELATIONS
  *    ---------
  *    TRUE
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - November 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_Relate(p_geom1     in mdsys.sdo_geometry,
                     p_mask      in varchar2,
                     p_geom2     in mdsys.sdo_geometry,
                     p_precision in number)
    Return varchar2 Deterministic;

  /**  ======================== PROCESSING ================== **/

 /****f* SC4O/ST_MinimumBoundingCircle
  *  NAME
  *    ST_MinimumBoundingCircle - Computes the Minimum Bounding Circle (MBC) for the points in a Geometry.
  *  SYNOPSIS
  *    Function ST_MinimumBoundingCircle(p_geom      in mdsys.sdo_geometry,
  *                                      p_precision in number )
  *      Return mdsys.sdo_geometry deterministic;
  *  DESCRIPTION
  *    Computes the Minimum Bounding Circle (MBC) for the points in a Geometry.
  *    The MBC is the smallest circle which contains all the input points (this is sometimes known as the Smallest Enclosing Circle).
  *    This is equivalent to computing the Maximum Diameter of the input point set.
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- First geometry subject to comparison
  *    p_precision (integer) -- Number of decimal places of precision
  *  RETURNS
  *    circle (sdo_geometry) -- Result of MBC calculation
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_MinimumBoundingCircle(p_geom      in mdsys.sdo_geometry,
                                    p_precision in number)
    Return mdsys.sdo_geometry deterministic;

 /****f* SC4O/ST_MinimumBoundingCircle(srid)
  *  NAME
  *    ST_MinimumBoundingCircle - Computes the Minimum Bounding Circle (MBC) for the points in a Geometry.
  *  SYNOPSIS
  *    Function ST_MinimumBoundingCircle(p_geom      in mdsys.sdo_geometry,
  *                                      p_precision in number,
  *                                      p_srid      in number )
  *      Return mdsys.sdo_geometry deterministic;
  *  DESCRIPTION
  *    Computes the Minimum Bounding Circle (MBC) for the points in a Geometry.
  *    The MBC is the smallest circle which contains all the input points (this is sometimes known as the Smallest Enclosing Circle).
  *    This is equivalent to computing the Maximum Diameter of the input point set.
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- First geometry subject to comparison
  *    p_precision (integer) -- Number of decimal places of precision
  *    p_srid      (integer) -- SRID of projected space in which actual overlay occurs before being projected back to p_geom1.sdo_srid.
  *  RETURNS
  *    circle (sdo_geometry) -- Result of MBC calculation
  *  NOTES
  *    Both geometries are projected to p_srid before the ST_MinimumBoundingCircle function is called.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_MinimumBoundingCircle(p_geom      in mdsys.sdo_geometry,
                                    p_precision in number,
                                    p_srid      in number )
    Return mdsys.sdo_geometry deterministic;

  /****f* SC4O/ST_Buffer
  *  NAME
  *    ST_Buffer - Buffers a geometry by the required value with optional styling.
  *  SYNOPSIS
  *    Function ST_Buffer(p_geom             in mdsys.sdo_geometry,
  *                       p_distance         in number,
  *                       p_precision        in number,
  *                       p_endCapStyle      in number,
  *                       p_joinStyle        in number,
  *                       p_quadrantSegments in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    ST_Buffer is implemented using JTS buffering and point removal functions.
  *    Will buffer any geometry object using variety of parameters.
  *    See ST_OneSidedBuffer for buffering on one side of a linestring.
  *  ARGUMENTS
  *    p_geom        (sdo_geometry) -- Geometry to be buffered
  *    p_distance         (integer) -- Buffer distance -ve/+ve (points +ve only)
  *    p_precision        (integer) -- Number of decimal places of precision
  *    p_endCapStyle      (integer) -- One of BufferParameters.CAP_ROUND,BufferParameters.CAP_BUTT, BufferParameters.CAP_SQUARE
  *    p_joinStyle        (integer) -- One of BufferParameters.JOIN_ROUND, BufferParameters.JOIN_MITRE, or BufferParameters.JOIN_BEVEL
  *    p_quadrantSegments (integer) -- Stroking of curves
  *  EXAMPLE
  *    select SC4O.ST_Buffer(
  *                mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(20,1,50,50,100,0,150,50)),15.0,2,
  *                1,    --CAP_ROUND
  *                1,    --JOIN_ROUND
  *                8     --QUADRANT_SEGMENTS
  *             ) as buf
  *      from dual;
  *
  *    BUF
  *    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(37.21,57.83,7.21,8.83,5.93,6.19,5.18,3.34,5.01,0.41,5.42,-2.51,6.38,-5.29,7.87,-7.82,9.82,-10.02,12.17,-11.79,14.81,-13.07,17.66,-13.82,20.59,-13.99,23.51,-13.58,26.29,-12.62,28.82,-11.13,31.02,-9.18,32.79,-6.83,52.85,25.93,89.39,-10.61,91.67,-12.47,94.26,-13.86,97.07,-14.71,100,-15,102.93,-14.71,105.74,-13.86,108.33,-12.47,110.61,-10.61,160.61,39.39,162.47,41.67,163.86,44.26,164.71,47.07,165,50,164.71,52.93,163.86,55.74,162.47,58.33,160.61,60.61,158.33,62.47,155.74,63.86,152.93,64.71,150,65,147.07,64.71,144.26,63.86,141.67,62.47,139.39,60.61,100,21.21,60.61,60.61,58.28,62.51,55.62,63.91,52.73,64.75,49.74,65,46.75,64.64,43.9,63.7,41.29,62.21,39.03,60.23,37.21,57.83))
  *
  *    select SC4O.ST_Buffer(
  *                   mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(20,1,50,50,100,0,150,50)),15.0,2,
  *                   3,        --CAP_SQUARE
  *                   1,        --JOIN_ROUND
  *                   8         --QUADRANT_SEGMENTS
  *            )  as buf --FULL BUFFER
  *      from dual;
  *
  *    BUF
  *    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(37.21,57.83,-0.63,-3.96,24.96,-19.63,32.79,-6.83,52.85,25.93,89.39,-10.61,91.67,-12.47,94.26,-13.86,97.07,-14.71,100,-15,102.93,-14.71,105.74,-13.86,108.33,-12.47,110.61,-10.61,171.21,50,150,71.21,139.39,60.61,100,21.21,60.61,60.61,58.28,62.51,55.62,63.91,52.73,64.75,49.74,65,46.75,64.64,43.9,63.7,41.29,62.21,39.03,60.23,37.21,57.83))
  *
  *    select SC4O.ST_Buffer(
  *                   mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(20,1,50,50,100,0,150,50)),15.0,2,
  *                   2,        --CAP_BUTT
  *                   1,        --JOIN_ROUND
  *                   8        --QUADRANT_SEGMENTS
  *             )  as buf 
  *      from dual;
  *
  *    BUF
  *    --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(37.21,57.83,7.21,8.83,32.79,-6.83,52.85,25.93,89.39,-10.61,91.67,-12.47,94.26,-13.86,97.07,-14.71,100,-15,102.93,-14.71,105.74,-13.86,108.33,-12.47,110.61,-10.61,160.61,39.39,139.39,60.61,100,21.21,60.61,60.61,58.28,62.51,55.62,63.91,52.73,64.75,49.74,65,46.75,64.64,43.9,63.7,41.29,62.21,39.03,60.23,37.21,57.83))
  *
  *    select SC4O.ST_Buffer(
  *                   mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(20,1,50,50,100,0,150,50)),15.0,2,
  *                   2,        --CAP_BUTT
  *                   2,        --JOIN_MITRE
  *                   8        --QUADRANT_SEGMENTS
  *           ) as buf 
  *      from dual;
  *
  *    BUF
  *    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(47.15,74.07,7.21,8.83,32.79,-6.83,52.85,25.93,100,-21.21,160.61,39.39,139.39,60.61,100,21.21,47.15,74.07))
  *
  *    select SC4O.ST_Buffer(
  *                   mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(20,1,50,50,100,0,150,50)),15.0,2,
  *                   2,        --CAP_BUTT
  *                   3,        --JOIN_BEVEL
  *                   8        --QUADRANT_SEGMENTS
  *           ) as buf 
  *      from dual;
  *
  *    BUF
  *    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(37.21,57.83,7.21,8.83,32.79,-6.83,52.85,25.93,89.39,-10.61,110.61,-10.61,160.61,39.39,139.39,60.61,100,21.21,60.61,60.61,37.21,57.83))
  *  RESULT
  *    OffsetLine (sdo_geometry) : Line offset on left or right.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - October 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *     http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_Buffer(p_geom             in mdsys.sdo_geometry,
                     p_distance         in number,
                     p_precision        in number,
                     p_endCapStyle      in number,
                     p_joinStyle        in number,
                     p_quadrantSegments in number )
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_Buffer(srid)
  *  NAME
  *    ST_Buffer - Buffers a geometry by the required value with optional styling.
  *  SYNOPSIS
  *    Function ST_Buffer(p_geom             in mdsys.sdo_geometry,
  *                       p_distance         in number,
  *                       p_precision        in number,
  *                       p_endCapStyle      in number,
  *                       p_joinStyle        in number,
  *                       p_quadrantSegments in number,
  *                       p_srid             in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    ST_Buffer is implemented using JTS buffering and point removal functions.
  *    Will buffer any geometry object using variety of parameters.
  *    See ST_OneSidedBuffer for buffering one side of a linestring.
  *  ARGUMENTS
  *    p_geom        (sdo_geometry) -- Geometry to be buffered
  *    p_distance         (integer) -- Buffer distance -ve/+ve (points +ve only)
  *    p_precision        (integer) -- Number of decimal places of precision
  *    p_endCapStyle      (integer) -- One of BufferParameters.CAP_ROUND,BufferParameters.CAP_BUTT, BufferParameters.CAP_SQUARE
  *    p_joinStyle        (integer) -- One of BufferParameters.JOIN_ROUND, BufferParameters.JOIN_MITRE, or BufferParameters.JOIN_BEVEL
  *    p_quadrantSegments (integer) -- Stroking of curves
  *    p_srid             (integer) -- SRID of projected space in which actual overlay occurs before being projected back to p_geom1.sdo_srid.
  * NOTES
  *    Geometry is projected to p_srid before the ST_Buffer function is called.
  *  EXAMPLE
  *
  *  RESULT
  *    OffsetLine (sdo_geometry) : Line offset on left or right.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *    Simon Greener - July   2019 - Changed underlying implementation which saw removal of p_onesided parameter (see new ST_OneSidedBuffer)
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_Buffer(p_geom             in mdsys.sdo_geometry,
                     p_distance         in number,
                     p_precision        in number,
                     p_endCapStyle      in number,
                     p_joinStyle        in number,
                     p_quadrantSegments in number,
                     p_srid             in number)
    Return mdsys.sdo_geometry Deterministic;

  -- *********************************************************************************
 
  /****f* SC4O/ST_OneSidedBuffer
  *  NAME
  *    ST_OneSidedBuffer - Creates a buffer polygon on one side of the supplied line with optional styling.
  *  SYNOPSIS
  *    Function ST_OneSidedBuffer(p_geom             in mdsys.sdo_geometry,
  *                               p_offset           in number,
  *                               p_precision        in number,
  *                               p_endCapStyle      in number,
  *                               p_joinStyle        in number,
  *                               p_quadrantSegments in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    ST_OneSidedBuffer creates a buffer on the left or right of the supplied linestring.
  *    Buffer polygon is created using a variety of parameters.
  *  NOTES
  *    JTS does not support linestrings with circularString elements.
  *  ARGUMENTS
  *    p_geom        (sdo_geometry) -- Geometry to be buffered
  *    p_distance         (integer) -- Buffer distance -ve/+ve (points +ve only)
  *    p_precision        (integer) -- Number of decimal places of precision
  *    p_endCapStyle      (integer) -- One of SC4O.CAP_ROUND,SC4O.CAP_BUTT, SC4O.CAP_SQUARE
  *    p_joinStyle        (integer) -- One of SC4O.JOIN_ROUND, SC4O.JOIN_MITRE, or SC4O.JOIN_BEVEL
  *    p_quadrantSegments (integer) -- Stroking of curves
  *  RESULT
  *    Buffer        (sdo_geometry) : Buffer of size offset on left or right of supplied line.
  *  EXAMPLE
  *    select SC4O.ST_OneSidedBuffer(line,b.left_right_distance,2,c.cap_join,c.cap_join,8) as buf
  *      from (select mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(20,1,50,50,100,0,150,50)) as line
  *              from dual
  *           ) a,
  *           (select case when level = 1 then -15.0 else 15.0 end as left_right_distance from dual connect by level < 3) b,
  *           (select LEVEL as cap_Join from dual connect by level <=3) c;
  *
  *    BUF
  *    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(20,1,32.79,-6.83,52.85,25.93,89.39,-10.61,91.67,-12.47,94.26,-13.86,97.07,-14.71,100,-15,102.93,-14.71,105.74,-13.86,108.33,-12.47,110.61,-10.61,160.61,39.39,150,50,100,0,50,50,20,1))
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(20,1,32.79,-6.83,52.85,25.93,100,-21.21,160.61,39.39,150,50,100,0,50,50,20,1))
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(20,1,32.79,-6.83,52.85,25.93,89.39,-10.61,110.61,-10.61,160.61,39.39,150,50,100,0,50,50,20,1))
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(150,50,139.39,60.61,100,21.21,60.61,60.61,58.28,62.51,55.62,63.91,52.73,64.75,49.74,65,46.75,64.64,43.9,63.7,41.29,62.21,39.03,60.23,37.21,57.83,7.21,8.83,20,1,50,50,100,0,150,50))
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(150,50,139.39,60.61,100,21.21,47.15,74.07,7.21,8.83,20,1,50,50,100,0,150,50))
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(150,50,139.39,60.61,100,21.21,60.61,60.61,37.21,57.83,7.21,8.83,20,1,50,50,100,0,150,50))
  *
  *     6 rows selected
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_OneSidedBuffer(p_geom             in mdsys.sdo_geometry,
                             p_offset           in number,
                             p_precision        in number,
                             p_endCapStyle      in number,
                             p_joinStyle        in number,
                             p_quadrantSegments in number)
    Return mdsys.sdo_geometry
   Deterministic;
 
  /****f* SC4O/ST_OneSidedBuffer
  *  NAME
  *    ST_OneSidedBuffer - Creates a buffer polygon on one side of the supplied line with optional styling.
  *  SYNOPSIS
  *    Function ST_OneSidedBuffer(p_geom             in mdsys.sdo_geometry,
  *                               p_offset           in number,
  *                               p_precision        in number,
  *                               p_endCapStyle      in number,
  *                               p_joinStyle        in number,
  *                               p_quadrantSegments in number,
  *                               p_srid             in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    ST_OneSidedBuffer creates a buffer on the left or right of the supplied linestring.
  *    Buffer polygon is created using a variety of parameters.
  *    Because JTS does not support geodetic computations so where the SRID is geographic/geodetic a planar SRID can be provided in which the buffering occurs.
  *  NOTES
  *    JTS does not support linestrings with circularString elements.
  *  ARGUMENTS
  *    p_geom        (sdo_geometry) -- Geometry to be buffered
  *    p_distance         (integer) -- Buffer distance -ve/+ve (points +ve only)
  *    p_precision        (integer) -- Number of decimal places of precision
  *    p_endCapStyle      (integer) -- One of SC4O.CAP_ROUND,SC4O.CAP_BUTT, SC4O.CAP_SQUARE
  *    p_joinStyle        (integer) -- One of SC4O.JOIN_ROUND, SC4O.JOIN_MITRE, or SC4O.JOIN_BEVEL
  *    p_quadrantSegments (integer) -- Stroking of curves
  *    p_srid             (integer) -- SRID of projected space in which actual overlay occurs before being projected back to p_geom1.sdo_srid.
  *  RESULT
  *    Buffer        (sdo_geometry) : Buffer of size offset on left or right of supplied line.
  *  EXAMPLE
  *    select SC4O.ST_OneSidedBuffer(line,b.left_right_distance,2,c.cap_join,c.cap_join,8) as buf
  *      from (select mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(20,1,50,50,100,0,150,50)) as line
  *              from dual
  *           ) a,
  *           (select case when level = 1 then -15.0 else 15.0 end as left_right_distance from dual connect by level < 3) b,
  *           (select LEVEL as cap_Join from dual connect by level <=3) c;
  *
  *    BUF
  *    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(20,1,32.79,-6.83,52.85,25.93,89.39,-10.61,91.67,-12.47,94.26,-13.86,97.07,-14.71,100,-15,102.93,-14.71,105.74,-13.86,108.33,-12.47,110.61,-10.61,160.61,39.39,150,50,100,0,50,50,20,1))
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(20,1,32.79,-6.83,52.85,25.93,100,-21.21,160.61,39.39,150,50,100,0,50,50,20,1))
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(20,1,32.79,-6.83,52.85,25.93,89.39,-10.61,110.61,-10.61,160.61,39.39,150,50,100,0,50,50,20,1))
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(150,50,139.39,60.61,100,21.21,60.61,60.61,58.28,62.51,55.62,63.91,52.73,64.75,49.74,65,46.75,64.64,43.9,63.7,41.29,62.21,39.03,60.23,37.21,57.83,7.21,8.83,20,1,50,50,100,0,150,50))
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(150,50,139.39,60.61,100,21.21,47.15,74.07,7.21,8.83,20,1,50,50,100,0,150,50))
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(150,50,139.39,60.61,100,21.21,60.61,60.61,37.21,57.83,7.21,8.83,20,1,50,50,100,0,150,50))
  *
  *     6 rows selected
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_OneSidedBuffer(p_geom             in mdsys.sdo_geometry,
                             p_offset           in number,
                             p_precision        in number,
                             p_endCapStyle      in number,
                             p_joinStyle        in number,
                             p_quadrantSegments in number,
                             p_srid             in number)
    Return mdsys.sdo_geometry
   Deterministic;

  /****f* SC4O/ST_OffsetLine
  *  NAME
  *    ST_OffsetLine - Offsets a linestring by the required value with optional styling.
  *  SYNOPSIS
  *    Function ST_OffsetLine(p_geom             in mdsys.sdo_geometry,
  *                           p_offset           in number,
  *                           p_precision        in number,
  *                           p_endCapStyle      in number,
  *                           p_joinStyle        in number,
  *                           p_quadrantSegments in number )
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    ST_OffsetLine offsets a linestring on either its left or right side.
  *    Various styings can be applied at segment intersections.
  *    JTS does not support geodetic computations so where the SRID is geographic/geodetic a planar SRID can be provided in which the offsetting occurs.
  *  NOTES
  *    JTS does not support linestrings with circularString elements.
  *  ARGUMENTS
  *    p_geom        (sdo_geometry) : Linestring to be offset
  *    p_offset           (integer) : Offset distance: -ve right; +ve left
  *    p_precision        (integer) : number of decimal places of precision
  *    p_endCapStyle      (integer) : One of SC4O.CAP_ROUND(1),  SC4O.CAP_FLAT(2),   or SC4O.CAP_SQUARE(3)
  *    p_joinStyle        (integer) : One of SC4O.JOIN_ROUND(1), SC4O.JOIN_MITRE(2), or SC4O.JOIN_BEVEL(3)
  *    p_quadrantSegments (integer) : Stroking of curves
  *  RESULT
  *    OffsetLine (sdo_geometry) : Line offset on left or right required distance.
  *  EXAMPLE
  *    select SC4O.ST_AsText(
  *              SC4O.ST_OffsetLine(
  *                  sdo_geometry('LINESTRING (548845.366 3956342.941, 548866.753 3956341.844, 548766.398 3956415.329)',32639),
  *                  -5.0,
  *                  3,
  *                  1,   --SC4O.CAP_ROUND,
  *                  1,   --SC4O.JOIN_ROUND,
  *                  8   --SC4O.QUADRANT_SEGMENTS
  *              )
  *           ) as geom
  *      from dual;
  *
  *    GEOM
  *    ------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    LINESTRING (548845.366 3956342.941, 548845.11 3956337.948, 548866.497 3956336.851, 548867.479 3956336.897, 548868.433 3956337.135, 548869.322 3956337.555, 548870.112 3956338.141, 548870.772 3956338.87, 548871.276 3956339.714, 548871.606 3956340.64, 548871.748 3956341.613, 548871.696 3956342.595, 548871.454 3956343.548, 548871.029 3956344.435, 548870.439 3956345.222, 548869.707 3956345.878, 548769.352 3956419.363, 548766.398 3956415.329, 548866.753 3956341.844, 548845.366 3956342.941)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_OffsetLine(p_geom             in mdsys.sdo_geometry,
                         p_offset           in number,
                         p_precision        in number,
                         p_endCapStyle      in number,
                         p_joinStyle        in number,
                         p_quadrantSegments in number)
    Return mdsys.sdo_geometry
   Deterministic;

  /****f* SC4O/ST_OffsetLine
  *  NAME
  *    ST_OffsetLine - Offsets a linestring by the required value with optional styling.
  *  SYNOPSIS
  *    Function ST_OffsetLine(p_geom             in mdsys.sdo_geometry,
  *                           p_offset           in number,
  *                           p_precision        in number,
  *                           p_endCapStyle      in number,
  *                           p_joinStyle        in number,
  *                           p_quadrantSegments in number,
  *                           p_srid             in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    ST_OffsetLine offsets a linestring on either its left or right side.
  *    Various styings can be applied at segment intersections.
  *    JTS does not support geodetic computations so where the SRID is geographic/geodetic a planar SRID can be provided in which the offsetting occurs.
  *  NOTES
  *    JTS does not support linestrings with circularString elements.
  *  ARGUMENTS
  *    p_geom        (sdo_geometry) : Linestring to be offset
  *    p_offset           (integer) : Offset distance: -ve right; +ve left
  *    p_precision        (integer) : number of decimal places of precision
  *    p_endCapStyle      (integer) : One of SC4O.CAP_ROUND(1),  SC4O.CAP_FLAT(2),   or SC4O.CAP_SQUARE(3)
  *    p_joinStyle        (integer) : One of SC4O.JOIN_ROUND(1), SC4O.JOIN_MITRE(2), or SC4O.JOIN_BEVEL(3)
  *    p_quadrantSegments (integer) : Stroking of curves
  *    p_srid             (integer) : SRID of projected space in which actual overlay occurs before being projected back to p_geom1.sdo_srid.
  *  RESULT
  *    OffsetLine (sdo_geometry) : Line offset on left or right required distance.
  *  EXAMPLE
  *    select SC4O.ST_AsText(
  *              SC4O.ST_OffsetLine(
  *                  sdo_geometry('LINESTRING (548845.366 3956342.941, 548866.753 3956341.844, 548766.398 3956415.329)',32639),
  *                  -5.0,
  *                  3,
  *                  1,   --SC4O.CAP_ROUND,
  *                  1,   --SC4O.JOIN_ROUND,
  *                  8,   --SC4O.QUADRANT_SEGMENTS
  *                  null --p_srid
  *               )
  *            ) as geom
  *      from dual;
  *
  *    GEOM
  *    ------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    LINESTRING (548845.366 3956342.941, 548845.11 3956337.948, 548866.497 3956336.851, 548867.479 3956336.897, 548868.433 3956337.135, 548869.322 3956337.555, 548870.112 3956338.141, 548870.772 3956338.87, 548871.276 3956339.714, 548871.606 3956340.64, 548871.748 3956341.613, 548871.696 3956342.595, 548871.454 3956343.548, 548871.029 3956344.435, 548870.439 3956345.222, 548869.707 3956345.878, 548769.352 3956419.363, 548766.398 3956415.329, 548866.753 3956341.844, 548845.366 3956342.941)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_OffsetLine(p_geom             in mdsys.sdo_geometry,
                         p_offset           in number,
                         p_precision        in number,
                         p_endCapStyle      in number,
                         p_joinStyle        in number,
                         p_quadrantSegments in number,
                         p_srid             in number)
    Return mdsys.sdo_geometry
   Deterministic;

  /****f* SC4O/ST_LineDissolver
  *  NAME
  *    ST_LineDissolver - Removes linear elements in _line from _geom.
  *  SYNOPSIS
  *    Function ST_LineDissolver(p_geom               in mdsys.sdo_geometry,
  *                              p_line               in mdsys.sdo_geometry,
  *                              p_precision          in number,
  *                              p_keepBoundaryPoints in number )
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Line two's vertices are removed from p_line1. If p_keepBoundaryPoints is 0 (false) the end points of
  *    p_line2 are also removed from p_line1; otherwise only interior line points are removed.
  *  ARGUMENTS
  *    p_geom               (sdo_geometry) : Linestring from which points will be removed.
  *    p_line               (sdo_geometry) : Linestring or MultiPoint containing points for removal
  *    p_precision          (integer)      : Number of decimal places of precision (should be coasest of the two linstrings.
  *    P_keepBoundaryPoints (integer)      : If 0 (false) end points of line linestring are also removed from line1; otherwise only interior line points are removed.
  *  EXAMPLE
  *    select SC4O.ST_AsText(
  *              SC4O.ST_OffsetLine(
  *                  sdo_geometry('LINESTRING (548845.366 3956342.941, 548866.753 3956341.844, 548766.398 3956415.329)',32639),
  *                  -5.0,
  *                  3,
  *                  1,   --SC4O.CAP_ROUND,
  *                  1,   --SC4O.JOIN_ROUND,
  *                  8   --SC4O.QUADRANT_SEGMENTS
  *              )
  *           ) as geom
  *      from data a;
  *
  *    GEOM
  *    ------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    LINESTRING (548845.366 3956342.941, 548845.11 3956337.948, 548866.497 3956336.851, 548867.479 3956336.897, 548868.433 3956337.135, 548869.322 3956337.555, 548870.112 3956338.141, 548870.772 3956338.87, 548871.276 3956339.714, 548871.606 3956340.64, 548871.748 3956341.613, 548871.696 3956342.595, 548871.454 3956343.548, 548871.029 3956344.435, 548870.439 3956345.222, 548869.707 3956345.878, 548769.352 3956419.363, 548766.398 3956415.329, 548866.753 3956341.844, 548845.366 3956342.941)
  *  RESULT
  *    Reduced line1 (sdo_geometry) : p_line1 with p_line2 removed and optionally its end points.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - October 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_LineDissolver(p_line1              in mdsys.sdo_geometry,
                            p_line2              in mdsys.sdo_geometry,
                            p_precision          in number,
                            p_keepBoundaryPoints in number )
    Return mdsys.sdo_geometry
   Deterministic;

  /****f* SC4O/ST_Centroid
  *  NAME
  *    ST_Centroid - Generates centroid for provided geometry.
  *  SYNOPSIS
  *    Function ST_Centroid(p_geom      in mdsys.sdo_geometry,
  *                         p_precision in number,
  *                         p_interior  in number default 1)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    An interior point is guaranteed to lie in the interior of the geometry,
  *    if it possible to calculate such a point exactly.
  *    Otherwise, the point may lie on the boundary of the geometry.
  *  ARGUMENTS
  *    p_geom (sdo_geometry) - Geometry for which a centroid is to be calculated by JTS.
  *    p_precision (integer) - Number of decimal places of precision.
  *    p_interior  (integer) - If +ve the centroid will be guaranteed to be an interior point of this Geometry.
  *  EXAMPLE
  *
  *  RESULT
  *    Point (sdo_geometry) - Centroid of geometry.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - November 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_Centroid(p_geom      in mdsys.sdo_geometry,
                       p_precision in number,
                       p_interior  in number default 1)
    Return mdsys.sdo_geometry deterministic;

  /* ********************************************************************************************** */

  /****f* SC4O/ST_ConvexHull
  *  NAME
  *    ST_ConvexHull - Generates convex hull using provided geometry's points.
  *  SYNOPSIS
  *    Function ST_ConvexHull(p_geom      in mdsys.sdo_geometry,
  *                           p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Computes centroid of provided geometry.
  *  ARGUMENTS
  *    p_geom (sdo_geometry) - Geometry for which a ConvexHull is to be calculated by JTS.
  *    p_precision (integer) - Number of decimal places of precision.
  *  EXAMPLE
  *
  *  RESULT
  *    Point (sdo_geometry) - Centroid of geometry.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_ConvexHull: SDO_Geometry conversion to JTS geometry returned NULL.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - November 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_ConvexHull(p_geom      in mdsys.sdo_geometry,
                         p_precision in number)
    Return mdsys.sdo_geometry deterministic;

  /** ============================ EDIT ==================================== **/

  /****f* SC4O/ST_Densify
  *  NAME
  *    ST_Densify - Densifies a geometry using provided distance tolerance.
  *  SYNOPSIS
  *    Function ST_Densify(p_geom              in mdsys.sdo_geometry,
  *                        p_precision         in number,
  *                        p_distanceTolerance in Number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Densifies a geometry using a given distance tolerance, and respecting the input geometry's precision.
  *    Supports only non-point geometries.
  *  ARGUMENTS
  *    p_geom        (sdo_geometry) - Polygon/Linear geometry to be densified.
  *    p_precision        (integer) - Number of decimal places of precision.
  *    p_distanceTolerance (number) - The distance between points when densifying the geometry.
  *  EXAMPLE
  *
  *  RESULT
  *    Point (sdo_geometry) - Centroid of geometry.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_Densify : SDO_Geometry conversion to JTS geometry returned NULL.
  *      ST_Densify: Converted geometry is invalid.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_Densify(p_geom              in mdsys.sdo_geometry,
                      p_precision         in number,
                      p_distanceTolerance in Number)
    Return mdsys.sdo_geometry deterministic;

  /****f* SC4O/ST_Densify(srid)
  *  NAME
  *    ST_Densify - Densifies a geometry using provided distance tolerance.
  *  SYNOPSIS
  *    Function ST_Densify(p_geom              in mdsys.sdo_geometry,
  *                        p_precision         in number,
  *                        p_distanceTolerance in Number,
  *                        p_srid              in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Densifies a geometry using a given distance tolerance, and respecting the input geometry's precision.
  *    Supports only non-point geometries.
  *    Wrapper function over ST_Densify that densifies geometry in projected space described by p_srid parameter.
  *  ARGUMENTS
  *    p_geom        (sdo_geometry) - Polygon/Linear geometry to be densified.
  *    p_precision        (integer) - Number of decimal places of precision.
  *    p_distanceTolerance (number) - The distance between points when densifying the geometry.
  *    p_srid      (integer) -- SRID of projected space in which actual overlay occurs before being projected back to p_geom.sdo_srid.
  *  EXAMPLE
  *
  *  RESULT
  *    Point (sdo_geometry) - Centroid of geometry.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_Densify : SDO_Geometry conversion to JTS geometry returned NULL.
  *      ST_Densify: Converted geometry is invalid.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_Densify(p_geom              in mdsys.sdo_geometry,
                      p_precision         in number,
                      p_distanceTolerance in Number,
                      p_srid              in number)
    Return mdsys.sdo_geometry deterministic;

  /* ********************************************************************************************** */

  /****f* SC4O/ST_LineMerger(resultSet)
  *  NAME
  *    ST_LineMerger - Constructs maximal length linestrings from provided result set.
  *  SYNOPSIS
  *    Function ST_LineMerger(p_resultSet in SC4O.RefCur_T,
  *                           p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Takes set of linestring geometries and constructs a collection of linear components
  *    that form maximal-length linestrings. The linear components are returned as a MultiLineString.
  *  ARGUMENTS
  *    p_resultSet (RefCur_T) - Ref Cursor of Linestring Geometries
  *    p_precision  (integer) - Number of decimal places of precision.
  *  EXAMPLE
  *
  *  RESULT
  *    Linestrings (sdo_geometry) - Collection of linear sdo_geometries as MultiLineString.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_LineMerger: No ResultSet passed to ST_LineMerger.
  *      ConvertResultSet (private): No SDO_GEOMETRY column can be found in resultset.
  *      ST_LineMerger: merged line strings are null or empty.
  *      ST_LineMerger: Failed with <Reason>
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_LineMerger(p_resultSet in &&defaultSchema..SC4O.refcur_t,
                         p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_LineMerger(geomset)
  *  NAME
  *    ST_LineMerger - Constructs maximal length linestrings from provided array.
  *  SYNOPSIS
  *    Function ST_LineMerger(p_geomset   in mdsys.sdo_geometry_array,
  *                           p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Takes set of linestring geometries and constructs a collection of linear components
  *    that form maximal-length linestrings. The linear components are returned as a MultiLineString.
  *  ARGUMENTS
  *    p_geomset (mdsys.sdo_geometry_array) - Array of Linestring Geometries
  *    p_precision                (integer) - Number of decimal places of precision.
  *  EXAMPLE
  *
  *  RESULT
  *    Linestrings (sdo_geometry) - Collection of linear sdo_geometries as MultiLineString.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_LineMerger: No ResultSet passed to ST_LineMerger.
  *      ConvertResultSet (private): No SDO_GEOMETRY column can be found in resultset.
  *      ST_LineMerger: merged line strings are null or empty.
  *      ST_LineMerger: Failed with <Reason>
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_LineMerger(p_geomset   in mdsys.sdo_geometry_array,
                         p_precision in number)
    Return mdsys.sdo_geometry
   Deterministic;

  /* ********************************************************************************************** */

  /****f* SC4O/ST_NodeLineStrings(resultSet)
  *  NAME
  *    ST_NodeLineStrings - Creates nodes at all topological intersections of linestrings.
  *  SYNOPSIS
  *    Function ST_NodeLineStrings(p_resultSet in SC4O.RefCur_T,
  *                                p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Takes a set of linestring geometries and ensures nodes are created at all topological intersections
  *    The linear components are returned as a MultiLineString.
  *  ARGUMENTS
  *    p_resultSet (RefCur_T) - Ref Cursor of Linestring Geometries
  *    p_precision  (integer) - Number of decimal places of precision.
  *  EXAMPLE
  *
  *  RESULT
  *    Linestrings (sdo_geometry) - Collection of linear sdo_geometries as MultiLineString.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_NodeLineStrings: Supplied ResultSet is null.
  *      ConvertResultSet (private): No SDO_GEOMETRY column can be found in resultset.
  *      ST_NodeLineStrings (private): LineString/MultiLineString or GeometryCollection expected, <GeometryType> found and skipped.
 ST_NodeLineStrings (private): Failed with <Message>
  *      ST_NodeLineStrings: Failed with <Message>.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - February 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_NodeLineStrings(p_resultSet in &&defaultSchema..SC4O.refcur_t,
                              p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_NodeLineStrings(sdo_geometry_array)
  *  NAME
  *    ST_NodeLineStrings - Creates nodes at all topological intersections of linestrings within geometry array.
  *  SYNOPSIS
  *    Function ST_NodeLineStrings(p_geomset   in mdsys.sdo_geometry_array,
  *                                p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Takes an array containing linestring geometries and ensures nodes are created at all topological intersections.
  *    The linear components are returned as a MultiLineString.
  *  ARGUMENTS
  *    p_geomset (sdo_geometry_array) - Array of linestring geometries.
  *    p_precision          (integer) - Number of decimal places of precision.
  *  EXAMPLE
  *
  *  RESULT
  *    Linestrings (sdo_geometry) - Noded linear sdo_geometries as MultiLineString.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_NodeLineStrings: Supplied geometry array is NULL or empty.
  *      ST_NodeLineStrings: SDO_Geometry conversion to JTS geometry returned NULL.
  *      ST_NodeLineStrings: SDO_Geometry is not a MultiLineString object or a GeometryCollection.
  *      ST_NodeLineStrings: LineString expected, <GeometryType> found and skipped.
  *      ST_NodeLineStrings: Failed with <Message>.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - February 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_NodeLineStrings(p_geomset   in mdsys.sdo_geometry_array,
                              p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_NodeLineStrings(GeometryCollection)
  *  NAME
  *    ST_NodeLineStrings - Creates nodes at all topological intersections of linestrings within collection.
  *  SYNOPSIS
  *    Function ST_NodeLineStrings(p_geometry  in mdsys.sdo_geometry,
  *                                p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Takes a GeometryCollection of linestring geometries and ensures nodes are created at all
  *    topological intersections.
  *    The linear components are returned as a MultiLineString.
  *  ARGUMENTS
  *    p_geometry (sdo_geometry) - Geometry collection (x004) or MultiLineStrings (x006)
  *    p_precision     (integer) - Number of decimal places of precision.
  *  EXAMPLE
  *
  *  RESULT
  *    Linestrings (sdo_geometry) - Collection of linear sdo_geometries as MultiLineString.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_NodeLineStrings: Supplied SDO_Geometry is NULL.
  *      ST_NodeLineStrings: SDO_Geometry conversion to JTS geometry returned NULL.
  *      ST_NodeLineStrings: SDO_Geometry is not a MultiLineString object or a GeometryCollection.
  *      ST_NodeLineStrings: LineString expected, <GeometryType> found and skipped.
  *      ST_NodeLineStrings: Failed with <Message>.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - February 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_NodeLineStrings(p_geometry  in mdsys.sdo_geometry,
                              p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

  /* ********************************************************************************************** */

  /****f* SC4O/ST_PolygonBuilder(RefCur)
  *  NAME
  *    ST_PolygonBuilder - Builds a polygon from a cursor resultset of noded linestrings
  *  SYNOPSIS
  *    Function ST_PolygonBuilder(p_resultSet in SC4O.RefCur_T,
  *                               p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Takes a set of noded (see ST_NodeLineStrings) linestring geometries and builds polygons from them.
  *    The polygons components are returned as a MultiPolygon or Polygon.
  *  ARGUMENTS
  *    p_resultSet (RefCur_T) - Ref Cursor of Linestring Geometries from which polygons will be built.
  *    p_precision  (integer) - Number of decimal places of precision.
  *  EXAMPLE
  *
  *  RESULT
  *    Polygons (sdo_geometry) - MultiPolygon or NULL geometry depending on success of processing.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_PolygonBuilder: Supplied ResultSet is NULL.
  *      ConvertResultSet (private): No SDO_GEOMETRY column can be found in resultset.
  *      ST_PolygonBuilder (private): LineString/MultiLineString or GeometryCollection expected, <GeometryType> found and skipped.
 ST_PolygonBuilder (private): Failed with <Message>
  *      ST_PolygonBuilder: Failed with <Message>.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_PolygonBuilder(p_resultSet in &&defaultSchema..SC4O.refcur_t,
                             p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_PolygonBuilder(sdo_geometry_array)
  *  NAME
  *    ST_PolygonBuilder - Builds a polygon from an array of linestrings
  *  SYNOPSIS
  *    Function ST_PolygonBuilder(p_geomset in mdsys.sdo_geometry_array,
  *                               p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Takes a set of noded (see ST_NodeLineStrings) linestring geometries and builds polygons from them.
  *    The polygons components are returned as a MultiPolygon or Polygon.
  *  ARGUMENTS
  *    p_geomset (sdo_geometry_array) - Array of Linestring Geometries
  *    p_precision          (integer) - Number of decimal places of precision.
  *  EXAMPLE
  *
  *  RESULT
  *    Polygons (sdo_geometry) - MultiPolygon or NULL geometry depending on success of processing.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_PolygonBuilder: Supplied geometry array is NULL or empty.
  *      ST_PolygonBuilder: LineString/MultiLineString or GeometryCollection expected, <GeometryType> found and skipped.
  *      ST_PolygonBuilder: Failed with <Message>.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - February 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_PolygonBuilder(p_geomset   in mdsys.sdo_geometry_array,
                             p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_PolygonBuilder(GeometryCollection)
  *  NAME
  *    ST_PolygonBuilder - Builds a polygon from a GeometryCollection containing linestrings
  *  SYNOPSIS
  *    Function ST_PolygonBuilder(p_geometry  in mdsys.sdo_geometry,
  *                               p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Takes a set of noded (see ST_NodeLineStrings) linestring geometries and builds polygons from them.
  *    The polygons components are returned as a MultiPolygon or Polygon.
  *  ARGUMENTS
  *    p_geometry (sdo_geometry) - GeometryCollection containing noded Linestring Geometries from which polygons will be built.
  *    p_precision     (integer) - Number of decimal places of precision.
  *  EXAMPLE
  *
  *  RESULT
  *    Polygons (sdo_geometry) - MultiPolygon or NULL geometry depending on success of processing.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_PolygonBuilder: Supplied Sdo_Geometry is NULL.
  *      ST_PolygonBuilder: SDO_Geometry conversion to JTS geometry returned NULL.
  *      ST_PolygonBuilder: LineString expected, <GeometryType> found and skipped.
  *      ST_PolygonBuilder: Failed with <Message>.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_PolygonBuilder(p_geometry  in mdsys.sdo_geometry,
                             p_precision in number)
    return mdsys.sdo_geometry Deterministic;

  /* **************************************************************************************************** */

  /****f* SC4O/ST_DelaunayTriangles(RefCur)
  *  NAME
  *    ST_DelaunayTriangles - Creates a delaunay triangulation from a geometry input (eg multipoints)
  *  SYNOPSIS
  *    Function ST_DelaunayTriangles(p_resultSet in SC4O.RefCur_T,
  *                                  p_tolerance in number,
  *                                  p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    This function creates a Delaunay triangulation from the geometries in the input result set.
  *    Extracts vertices from the geometries in the input SQL Cursor result set.
  *    The trianguation is returned as a GeometryCollection containing polygons.
  *  ARGUMENTS
  *    p_resultSet (RefCur_T) - Selection of sdo_geometry objects from whose vertices the Delaunay Triangles will be built
  *    p_tolerance   (number) - Snapping tolerance used to improved the robustness of the triangulation computation.
  *    p_precision  (integer) - Number of decimal places of precision.
  *  EXAMPLE
  *
  *  RESULT
  *    Polygons (sdo_geometry) - GeometryCollection of polygon geometries.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_DelaunayTriangles: Supplied ResultSet is NULL.
  *      ST_DelaunayTriangles: failed with (_convertResultSet) no SDO_GEOMETRY column can be found in resultset.
  *      ST_DelaunayTriangles: failed with (_createTriangles) <Message>
  *      ST_DelaunayTriangles: Failed with <Message>.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - February 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_DelaunayTriangles(p_resultSet in &&defaultSchema..SC4O.refcur_t,
                                p_tolerance in number,
                                p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_DelaunayTriangles(sdo_geometry_array)
  *  NAME
  *    ST_DelaunayTriangles - Creates a delaunay triangulation from array of geometry points.
  *  SYNOPSIS
  *    Function ST_DelaunayTriangles(p_geomSet   in mdsys.sdo_geometry_array,
  *                                  p_tolerance in number,
  *                                  p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    This function creates a Delaunay triangulation from the geometries in the input result set.
  *    Extracts vertices from the geometries in the input SQL Cursor result set.
  *    The trianguation is returned as a GeometryCollection containing polygons.
  *  ARGUMENTS
  *    p_geomset (sdo_geometry_array) - Array of sdo_geometry objects from whose vertices the Delaunay Triangles will be built
  *    p_tolerance   (number) - Snapping tolerance used to improved the robustness of the triangulation computation.
  *    p_precision  (integer) - Number of decimal places of precision.
  *  EXAMPLE
  *
  *  RESULT
  *    Polygons (sdo_geometry) - GeometryCollection of polygon geometries.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_DelaunayTriangles: Supplied array is NULL.
  *      ST_DelaunayTriangles: No SDO_GEOMETRY column can be found in resultset.
  *      ST_DelaunayTriangles: failed with (_convertArray) <Message>
  *      ST_DelaunayTriangles: failed with (_createTriangles) <Message>
  *      ST_DelaunayTriangles: failed with <Message>.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - February 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_DelaunayTriangles(p_geomset   in mdsys.sdo_geometry_array,
                                p_tolerance in number,
                                p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_DelaunayTriangles(Geometry)
  *  NAME
  *    ST_DelaunayTriangles - Creates a Delaunay triangulation from the coordinates in the input geometry.
  *  SYNOPSIS
  *    Function ST_DelaunayTriangles(p_geometry  in mdsys.sdo_geometry,
  *                                  p_tolerance in number,
  *                                  p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    This function creates a Delaunay triangulation from the coordinates in the input geometry eg GeometryCollection, MultiPoint etc.
  *    The trianguation is returned as a GeometryCollection containing polygons.
  *  ARGUMENTS
  *    p_geometry (sdo_geometry) - sdo_geometry object whose coordinates will be used to create Delaunay Triangles.
  *    p_tolerance      (number) - Snapping tolerance used to improved the robustness of the triangulation computation.
  *    p_precision     (integer) - Number of decimal places of precision.
  *  EXAMPLE
  *
  *  RESULT
  *    Polygons (sdo_geometry) - GeometryCollection of polygon geometries.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_DelaunayTriangles: Supplied SDO_Geometry is NULL.
  *      ST_DelaunayTriangles: Cannot build a Delaunay Triangulation from a single point geometry.
  *      ST_DelaunayTriangles: SDO_Geometry conversion to JTS geometry returned NULL.
  *      ST_DelaunayTriangles: <Message>.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - February 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_DelaunayTriangles(p_geometry  in mdsys.sdo_geometry,
                                p_tolerance in number,
                                p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

  /* **************************************************************************************************** */

  /****f* SC4O/ST_Voronoi(RefCur)
  *  NAME
  *    ST_Voronoi - Creates a Voronoi diagram from a selection of geometry objects.
  *  SYNOPSIS
  *    Function ST_Voronoi(p_resultSet in SC4O.RefCur_T,
  *                        p_envelope  in mdsys.sdo_geometry,
  *                        p_tolerance in number,
  *                        p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    This function creates a Voronoi diagram from the coordinates of the geometries in the input result set.
  *    Extracts vertices from the geometries in the input SQL Cursor result set.
  *    The diagram is returned as a GeometryCollection containing polygons.
  *    The voronoi diagram is constrained to be built within the input p_envvelope geometry.
  *  ARGUMENTS
  *    p_resultSet    (RefCur_T) - Selection of sdo_geometry objects from whose vertices the Delaunay Triangles will be built
  *    p_envelope (sdo_geometry) - Single geometry containing limiting envelope for triangulation
  *    p_tolerance      (number) - Snapping tolerance used to improved the robustness of the triangulation computation.
  *    p_precision     (integer) - Number of decimal places of precision.
  *  EXAMPLE
  *
  *  RESULT
  *    Polygons (sdo_geometry) - GeometryCollection of polygon geometries.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_Voronoi: Supplied ResultSet is NULL.
  *      ST_Voronoi: failed with (_convertResultSet) no SDO_GEOMETRY column can be found in resultset.
  *      ST_Voronoi: Envelope (clip) sdo_geometry conversion to JTS geometry returned NULL.
  *      ST_Voronoi: failed with (_createTriangles) <Message>
  *      ST_Voronoi: failed with <Message>.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - March 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_Voronoi(p_resultSet in &&defaultSchema..SC4O.refcur_t,
                      p_envelope  in mdsys.sdo_geometry,
                      p_tolerance in number,
                      p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_Voronoi(sdo_geometry_array)
  *  NAME
  *    ST_Voronoi - Creates a Voronoi diagram from coordinates of an array of geometry objects.
  *  SYNOPSIS
  *    Function ST_Voronoi(p_geomset   in mdsys.sdo_geometry_array,
  *                        p_envelope  in mdsys.sdo_geometry,
  *                        p_tolerance in number,
  *                        p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    This function creates a Voronoi diagram from the coordinates of the geometries in the input array.
  *    Extracts vertices from the geometries in the input SQL Cursor result set.
  *    The diagram is returned as a GeometryCollection containing polygons.
  *    The voronoi diagram is constrained to be built within the input p_envvelope geometry.
  *  ARGUMENTS
  *    p_geomset (sdo_geometry_array) - Array of sdo_geometry objects from whose coordinates the Delaunay Triangles will be built
  *    p_envelope      (sdo_geometry) - Single geometry containing limiting envelope for triangulation
  *    p_tolerance           (number) - Snapping tolerance used to improved the robustness of the triangulation computation. Must be expressed in ordinate units eg m or decimal degrees
  *    p_precision          (integer) - Number of decimal places of precision.
  *  EXAMPLE
  *
  *  RESULT
  *    Polygons (sdo_geometry) - GeometryCollection of polygon geometries.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_Voronoi: Supplied ResultSet is NULL.
  *      ST_Voronoi: failed with (_convertResultSet) no SDO_GEOMETRY column can be found in resultset.
  *      ST_Voronoi: Envelope (clip) sdo_geometry conversion to JTS geometry returned NULL.
  *      ST_Voronoi: failed with (_createTriangles) <Message>
  *      ST_Voronoi: failed with <Message>.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - March 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_Voronoi(p_geomset   in mdsys.sdo_geometry_array,
                      p_envelope  in mdsys.sdo_geometry,
                      p_tolerance in number,
                      p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_Voronoi(sdo_geometry)
  *  NAME
  *    ST_Voronoi - Creates a Voronoi diagram from coordinates of the supplied geometry object.
  *  SYNOPSIS
  *    Function ST_Voronoi(p_geometry  in mdsys.sdo_geometry,
  *                        p_envelope  in mdsys.sdo_geometry,
  *                        p_tolerance in number,
  *                        p_precision in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    This function creates a Voronoi diagram from the coordinates of the geometries in the input array.
  *    Extracts vertices from the geometries in the input SQL Cursor result set.
  *    The diagram is returned as a GeometryCollection containing polygons.
  *    The voronoi diagram is constrained to be built within the input p_envvelope geometry.
  *  ARGUMENTS
  *    p_geomset  (sdo_geometry) - Single geometry containing source coordinates from which the voronoi will be built.
  *    p_envelope (sdo_geometry) - Single geometry containing limiting envelope for triangulation
  *    p_tolerance      (number) - Snapping tolerance used to improved the robustness of the triangulation computation. Must be expressed in ordinate units eg m or decimal degrees
  *    p_precision     (integer) - Number of decimal places of precision.
  *  EXAMPLE
  *
  *  RESULT
  *    Polygons (sdo_geometry) - GeometryCollection of polygon geometries.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_Voronoi: Supplied SDO_Geometry is NULL.
  *      ST_Voronoi: Envelope (clip) sdo_geometry conversion to JTS geometry returned NULL.
  *      ST_Voronoi: failed with (_createTriangles) <Message>
  *      ST_Voronoi: failed with <Message>.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - March 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
  Function ST_Voronoi(p_geometry  in mdsys.sdo_geometry,
                      p_envelope  in mdsys.sdo_geometry,
                      p_tolerance in number,
                      p_precision in number)
    Return mdsys.sdo_geometry Deterministic;

  /* *************************************************************************************************** */

  /****f* SC4O/ST_InterpolateZ
  *  NAME
  *    ST_InterpolateZ - Takes a 2D point and a 3D triangle (facet) and interpolates a Z ordinate value.
  *  SYNOPSIS
  *    Function ST_InterpolateZ(p_point in mdsys.sdo_geometry,
  *                             p_geom1 in mdsys.sdo_geometry,
  *                             p_geom2 in mdsys.sdo_geometry,
  *                             p_geom3 in mdsys.sdo_geometry)
  *     Return Number Deterministic;
  *  DESCRIPTION
  *    This function takes a 2D point and a 3D triangle (facet in a triangulated mesh) and returns interpolated Z ordinate value.
  *  ARGUMENTS
  *    p_point (sdo_geometry) - Point for which Z ordinate's value is to be computed
  *    p_geom1 (sdo_geometry) - First corner geometry 3D point
  *    p_geom2 (sdo_geometry) - Second corner geometry 3D point
  *    p_geom3 (sdo_geometry) - Third corner geometry 3D point
  *  EXAMPLE
  *
  *  RESULT
  *    Z value (Number) - Result of Interpolation
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_InterpolateZ: One or other of supplied Sdo_Geometries is NULL.
  *      ST_InterpolateZ: SRIDs of Sdo_Geometries must be equal.
  *      ST_InterpolateZ: Converted point geometry is NULL.
  *      ST_InterpolateZ: Converted point geometry is invalid.
  *      ST_InterpolateZ: Converted first geometry is NULL.
  *      ST_InterpolateZ: Converted first geometry is invalid.
  *      ST_InterpolateZ: Converted second geometry is NULL.
  *      ST_InterpolateZ: Converted second geometry is invalid.
  *      ST_InterpolateZ: Converted third geometry is NULL.
  *      ST_InterpolateZ: Converted third geometry is invalid.
  *      ST_InterpolateZ: The three facet geometries must have a Z value.
  *      ST_InterpolateZ: All three facet geometries should be points.
  *      ST_InterpolateZ: <Message>.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - March 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
   Function ST_InterpolateZ(p_point in mdsys.sdo_geometry,
                            p_geom1 in mdsys.sdo_geometry,
                            p_geom2 in mdsys.sdo_geometry,
                            p_geom3 in mdsys.sdo_geometry)
    Return Number Deterministic;

  /****f* SC4O/ST_InterpolateZ(facet)
  *  NAME
  *    ST_InterpolateZ - Takes a 2D point and a 3D triangle (facet) and interpolates a Z ordinate value.
  *  SYNOPSIS
  *    Function ST_InterpolateZ(p_point in mdsys.sdo_geometry,
  *                             p_facet in mdsys.sdo_geometry)
  *     Return Number Deterministic;
  *  DESCRIPTION
  *    This function takes a 2D point and a 3D triangle (facet in a triangulated mesh) and returns interpolated Z ordinate value.
  *    Facet is a 4 point polygon with a single exterior ring.
  *  ARGUMENTS
  *    p_point (sdo_geometry) - Point for which Z ordinate's value is to be computed
  *    p_facet (sdo_geometry) - 3 point triangular polygon
  *  EXAMPLE
  *
  *  RESULT
  *    Z value (Number) - Result of Interpolation
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_InterpolateZ: One or other of supplied Sdo_Geometries is NULL.
  *      ST_InterpolateZ: Failed with SRIDs of Sdo_Geometries must be equal.
  *      ST_InterpolateZ: Converted point geometry is NULL.
  *      ST_InterpolateZ: Converted point geometry is invalid.
  *      ST_InterpolateZ: Supplied point geometry (<GeometryType>) can ony be Point or MultiPoint.
  *      ST_InterpolateZ: Converted facet polygon is NULL.
  *      ST_InterpolateZ: Converted facet polygon is invalid.
  *      ST_InterpolateZ: Facet geometry should be a polygon.
  *      ST_InterpolateZ: Facet polygon must have 3 corner points (<NumPoints>).
  *      ST_InterpolateZ: The three facet corners must have a Z value.
  *      ST_InterpolateZ: <Message>
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - March 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  *  NOTES
  *    LICENSE is Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  ******/
   Function ST_InterpolateZ(p_point in mdsys.sdo_geometry,
                            p_facet in mdsys.sdo_geometry)
    Return mdsys.sdo_geometry Deterministic;

/* *************************************************************************************************** */

  /****f* SC4O/ST_Snap
  *  NAME
  *    ST_Snap -- Snaps geometries to each other with both being able to move.
  *  SYNOPSIS
  *    Function ST_Snap(p_geom1         in mdsys.sdo_geometry,
  *                     p_geom2         in mdsys.sdo_geometry,
  *                     p_snapTolerance in number,
  *                     p_precision     in number)
  *      Return mdsys.sdo_geometry deterministic;
  *  DESCRIPTION
  *    Snaps geometries to each other with both being able to move.
  *    p_snapTolerance controls distance within which coordinates are compared/snapped.
  *    p_precision controls number of decimal digits of precision for result coordinates.
  *    Returns compound sdo_geometry ie x004
  *  ARGUMENTS
  *    p_geom1   (sdo_geometry) - first snapping geometry.
  *    p_geom2   (sdo_geometry) - Second snapping geometry.
  *    p_snapTolerance (double) - Distance tolerance is used to control where snapping is performed.
  *                               SnapTolerance must be expressed in ordinate units eg m or decimal degrees.
  *    p_precision     (number) - Precision of geometries in decimal digits of precision.
  *  RESULT
  *    snapped geometry (sdo_geometry) - Result of snap which is always a compound geometry x004
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_Snap : One or other of supplied Sdo_Geometries is null.
  *      ST_Snap : SDO_Geometry SRIDs must be equal.
  *      ST_Snap : Converted first geometry is NULL.
  *      ST_Snap : Converted first geometry is invalid.
  *      ST_Snap : Converted second geometry is NULL.
  *      ST_Snap : Converted second geometry is invalid.
  *      ST_Snap : <Error Message>
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
   Function ST_Snap(p_geom1         in mdsys.sdo_geometry,
                    p_geom2         in mdsys.sdo_geometry,
                    p_snapTolerance in number,
                    p_precision     in number)
     Return mdsys.sdo_geometry deterministic;

  /****f* SC4O/ST_Snap(srid)
  *  NAME
  *    ST_Snap -- Snaps geometries to each other with both being able to move.
  *  SYNOPSIS
  *    Function ST_Snap(p_geom1         in mdsys.sdo_geometry,
  *                     p_geom2         in mdsys.sdo_geometry,
  *                     p_snapTolerance in number,
  *                     p_precision     in number,
  *                     p_srid          in number)
  *      Return mdsys.sdo_geometry deterministic;
  *  DESCRIPTION
  *    Snaps geometries to each other with both being able to move.
  *    p_snapTolerance controls distance within which coordinates are compared/snapped.
  *    p_precision controls number of decimal digits of precision for result coordinates.
  *    Computations occur in projected space described by p_srid parameter.
  *    Result is projected back to p_geom1 srid.
  *    Returns compound sdo_geometry ie x004
  *  ARGUMENTS
  *    p_geom1   (sdo_geometry) - first snapping geometry.
  *    p_geom2   (sdo_geometry) - Second snapping geometry.
  *    p_snapTolerance (double) - Distance tolerance is used to control where snapping is performed.
  *                               SnapTolerance must be expressed in ordinate units eg m or decimal degrees.
  *    p_precision     (number) - Precision of geometries in decimal digits of precision.
  *    p_srid         (integer) - SRID of projected space in which actual processing occurs. Result is projected back to p_geom1 srid.
  *  RESULT
  *    snapped geometry (sdo_geometry) - Result of snap which is always a compound geometry x004
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_Snap : One or other of supplied Sdo_Geometries is null.
  *      ST_Snap : SDO_Geometry SRIDs must be equal.
  *      ST_Snap : Converted first geometry is NULL.
  *      ST_Snap : Converted first geometry is invalid.
  *      ST_Snap : Converted second geometry is NULL.
  *      ST_Snap : Converted second geometry is invalid.
  *      ST_Snap : <Error Message>
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
   Function ST_Snap(p_geom1         in mdsys.sdo_geometry,
                    p_geom2         in mdsys.sdo_geometry,
                    p_snapTolerance in number,
                    p_precision     in number,
                    p_srid          in number)
     Return mdsys.sdo_geometry deterministic;

  /****f* SC4O/ST_SnapTo
  *  NAME
  *    ST_SnapTo -- Snaps the vertices in the component LineStrings of the source geometry to the vertices of the given snap geometry.
  *  SYNOPSIS
  *    Function ST_SnapTo(p_geom1         in mdsys.sdo_geometry,
  *                       p_geom2         in mdsys.sdo_geometry,
  *                       p_snapTolerance in number,
  *                       p_precision     in number)
  *      Return mdsys.sdo_geometry deterministic;
  *  DESCRIPTION
  *    Snap first geometry to second.
  *    p_snapTolerance controls distance within which coordinates are compared/snapped.
  *    p_precision controls number of decimal digits of precision for result coordinates.
  *    Returns compound sdo_geometry ie x004
  *  ARGUMENTS
  *    p_geom1   (sdo_geometry) - Geometry which will be snapped to the second geometry
  *    p_geom2   (sdo_geometry) - The snapTo geometry
  *    p_snapTolerance (double) - Distance tolerance is used to control where snapping is performed.
  *                               SnapTolerance must be expressed in ordinate units eg m or decimal degrees.
  *    p_precision     (number) - Precision of geometries in decimal digits of precision.
  *  RESULT
  *    snapped geometry (sdo_geometry) - Result of snapTo which is modified first geometry.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_SnapTo : One or other of supplied Sdo_Geometries is null.
  *      ST_SnapTo : SDO_Geometry SRIDs must be equal.
  *      ST_SnapTo : Converted first geometry is NULL.
  *      ST_SnapTo : Converted first geometry is invalid.
  *      ST_SnapTo : Converted second geometry is NULL.
  *      ST_SnapTo : Converted second geometry is invalid.
  *      ST_SnapTo : <Error Message>
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_SnapTo(p_geom1         in mdsys.sdo_geometry,
                     p_snapGeom      in mdsys.sdo_geometry,
                     p_snapTolerance in number,
                     p_precision     in number)
    Return mdsys.sdo_geometry deterministic;

  /****f* SC4O/ST_SnapTo(srid)
  *  NAME
  *    ST_SnapTo -- Snaps the vertices in the component LineStrings of the source geometry to the vertices of the given snap geometry.
  *  SYNOPSIS
  *    Function ST_SnapTo(p_geom1         in mdsys.sdo_geometry,
  *                       p_geom2         in mdsys.sdo_geometry,
  *                       p_snapTolerance in number,
  *                       p_precision     in number,
  *                       p_srid          in number)
  *      Return mdsys.sdo_geometry deterministic;
  *  DESCRIPTION
  *    Snap first geomtery to second.
  *    p_snapTolerance controls distance within which coordinates are compared/snapped.
  *    p_precision controls number of decimal digits of precision for result coordinates.
  *    Returns compound sdo_geometry ie x004
  *    Computations occur in projected space described by p_srid parameter with result returned in p_srid.
  *  ARGUMENTS
  *    p_geom1   (sdo_geometry) - Geometry which will be snapped to the second geometry
  *    p_geom2   (sdo_geometry) - The snapTo geometry
  *    p_snapTolerance (double) - Distance tolerance is used to control where snapping is performed.
  *                               SnapTolerance must be expressed in ordinate units eg m or decimal degrees.
  *    p_precision     (number) - Precision of geometries in decimal digits of precision.
  *    p_srid         (integer) - SRID of projected space in which actual processing occurs with result projected back to p_geom1 srid.
  *  RESULT
  *    snapped geometry (sdo_geometry) - Result of snapTo which is modified first geometry.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_SnapTo : One or other of supplied Sdo_Geometries is null.
  *      ST_SnapTo : SDO_Geometry SRIDs must be equal.
  *      ST_SnapTo : Converted first geometry is NULL.
  *      ST_SnapTo : Converted first geometry is invalid.
  *      ST_SnapTo : Converted second geometry is NULL.
  *      ST_SnapTo : Converted second geometry is invalid.
  *      ST_SnapTo : <Error Message>
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_SnapTo(p_geom1         in mdsys.sdo_geometry,
                     p_snapGeom      in mdsys.sdo_geometry,
                     p_snapTolerance in number,
                     p_precision     in number,
                     p_srid          in number)
    Return mdsys.sdo_geometry deterministic;

  /****f* SC4O/ST_SnapToSelf
  *  NAME
  *    ST_SnapToSelf -- Snaps the vertices in the component LineStrings of the source geometry to itself.
  *  SYNOPSIS
  *    Function ST_SnapToSelf(p_geom         in mdsys.sdo_geometry,
  *                           p_snapTolerance in number,
  *                           p_precision     in number)
  *      Return mdsys.sdo_geometry deterministic;
  *  DESCRIPTION
  *    Snaps supplied geometry to itself.
  *    Returns snapped p_geom1.
  *    p_snapTolerance controls distance within which coordinates are compared/snapped.
  *    p_precision controls number of decimal digits of precision for result coordinates.
  *  ARGUMENTS
  *    p_geom    (sdo_geometry) - Geometry to be snapped to itself.
  *    p_snapTolerance (double) - Distance tolerance is used to control where snapping is performed.
  *                               SnapTolerance must be expressed in ordinate units eg m or decimal degrees.
  *    p_precision     (number) - Precision of geometry in decimal digits of precision.
  *  RESULT
  *    snapped geometry (sdo_geometry) - Result of snap should be modified p_geom1.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_SnapToSelf : Supplied Sdo_Geometry must not be null.
  *      ST_SnapToSelf : Converted first geometry is NULL.
  *      ST_SnapToSelf : Converted first geometry is invalid.
  *      ST_SnapToSelf : <Error Message>
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_SnapToSelf(p_geom          in mdsys.sdo_geometry,
                         p_snapTolerance in number,
                         p_precision     in number)
    Return mdsys.sdo_geometry deterministic;

  /****f* SC4O/ST_SnapToSelf(srid)
  *  NAME
  *    ST_SnapToSelf -- Snaps the vertices in the component LineStrings of the source geometry to itself.
  *  SYNOPSIS
  *    Function ST_SnapToSelf(p_geom         in mdsys.sdo_geometry,
  *                           p_snapTolerance in number,
  *                           p_precision     in number,
  *                           p_srid          in number)
  *      Return mdsys.sdo_geometry deterministic;
  *  DESCRIPTION
  *    Snaps supplied geometry to itself.
  *    Returns snapped p_geom1.
  *    p_snapTolerance controls distance within which coordinates are compared/snapped.
  *    p_precision controls number of decimal digits of precision for result coordinates.
  *    Computations occur in projected space described by p_srid parameter with result returned in p_srid.
  *  ARGUMENTS
  *    p_geom    (sdo_geometry) - Geometry to be snapped to itself.
  *    p_snapTolerance (double) - Distance tolerance is used to control where snapping is performed.
  *                               SnapTolerance must be expressed in ordinate units eg m or decimal degrees.
  *    p_precision     (number) - Precision of geometry in decimal digits of precision.
  *    p_srid         (integer) - SRID of projected space in which actual processing occurs with result projected back to p_geom1 srid.
  *  RESULT
  *    snapped geometry (sdo_geometry) - Result of snap should be modified p_geom1 with SRID of p_geom1 SRID.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_SnapToSelf : Supplied Sdo_Geometry must not be null.
  *      ST_SnapToSelf : Converted first geometry is NULL.
  *      ST_SnapToSelf : Converted first geometry is invalid.
  *      ST_SnapToSelf : <Error Message>
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_SnapToSelf(p_geom          in mdsys.sdo_geometry,
                         p_snapTolerance in number,
                         p_precision     in number,
                         p_srid          in number)
    Return mdsys.sdo_geometry deterministic;

  /* ************************************************************************************************** */

  /****f* SC4O/ST_Round
  *  NAME
  *    ST_Round -- Method for rounding the coordinates of a geometry to a particular precision.
  *  SYNOPSIS
  *    Function ST_Round(p_geom      in mdsys.sdo_geometry,
  *                      p_precision in number)
  *      Return mdsys.sdo_geometry deterministic;
  *  DESCRIPTION
  *    All ordinates of p_geom are rounded to required decimal digits of precision.
  *    Only XY are all rounded using same p_precision.
  *  ARGUMENTS
  *    p_geom    (sdo_geometry) - Geometry whose coordinate ordinates are to be rounded.
  *    p_precision     (number) - Precision of an ordinate expresses in decimal digits of precision eg 0.001m = 3.
  *  RESULT
  *    Rounded geometry (sdo_geometry) - Input p_geom with all ordinates rounded to p_precision.
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_Round : Supplied Sdo_Geometry must not be null.
  *      ST_Round : SDO_Geometry conversion to JTS geometry returned NULL.
  *      ST_Round : <Error Message>
  *  NOTES
  *    Uses JTS GeometryPrecisionReducer.reduce()
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_Round(p_geom      in mdsys.sdo_geometry,
                    p_precision in number)
    Return mdsys.sdo_geometry deterministic;

  /** =========================== Simplification ======================== **/

  /****f* SC4O/ST_DouglasPeuckerSimplify
  *  NAME
  *    ST_DouglasPeuckerSimplify -- Simplifies a linear geometry using the Douglas Peucker algorithm.
  *  SYNOPSIS
  *    Function ST_DouglasPeuckerSimplify(p_geom              in mdsys.sdo_geometry,
  *                                       p_distanceTolerance in Number,
  *                                       p_precision         in number)
  *      Return mdsys.sdo_geometry deterministic;
  *  DESCRIPTION
  *    Simplifies a Geometry using the standard Douglas-Peucker algorithm.
  *    Ensures that any polygonal geometries returned are valid.
  *    In general D-P does not preserve topology e.g. polygons can be split, collapse to lines or disappear
  *    holes can be created or disappear, and lines can cross. However, this implementation attempts always
  *    to preserve topology. Switch to not preserve topology is not exposed to PL/SQL.
  *  ARGUMENTS
  *    p_geom        (sdo_geometry) -- Geometry for which the JTS Douglas Peucker simplification is to be applied.
  *    p_distanceTolerance (Number) -- The maximum distance difference.
  *    p_precision        (integer) -- Precision of an ordinate expresses in decimal digits of precision eg 0.001m = 3.
  *  RESULT
  *    Simplified geometry (sdo_geometry) - Simplified geometry
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *      ST_DouglasPeuckerSimplify: Supplied Sdo_Geometry must not be null.
  *      ST_DouglasPeuckerSimplify: SDO_Geometry conversion to JTS geometry returned NULL.
  *      ST_DouglasPeuckerSimplify: <Error Message>
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_DouglasPeuckerSimplify(p_geom              in mdsys.sdo_geometry,
                                     p_distanceTolerance in Number,
                                     p_precision         in number)
    Return mdsys.sdo_geometry deterministic;

  /****f* SC4O/ST_TopologyPreservingSimplify
  *  NAME
  *    ST_TopologyPreservingSimplify -- Simplifies a geometry preserving topological correctness.
  *  SYNOPSIS
  *    Function ST_TopologyPreservingSimplify(p_geom              in mdsys.sdo_geometry,
  *                                          p_distanceTolerance in Number,
  *                                          p_precision         in number)
  *      Return mdsys.sdo_geometry deterministic;
  *  DESCRIPTION
  *    Simplifies a Geometry using a maximum distance difference algorithm similar to the one used in the Douglas-Peucker algorithm.
  *    In particular, if the input is an polygon geometry the result has the same number of shells and holes
  *    (rings) as the input, in the same order. The result rings touch at no more than the number of touching
  *    point in the input (although they may touch at fewer points).
  *    (The key implication of this constraint is that the output will be topologically valid if the input was.)
  *  ARGUMENTS
  *    p_geom        (sdo_geometry) -- Geometry for which simplification is required.
  *    p_distanceTolerance (Number) -- The maximum distance difference (similar to the one used in the Douglas-Peucker algorithm)
  *    p_precision        (integer) -- Precision of an ordinate expresses in decimal digits of precision eg 0.001m = 3.
  *  RESULT
  *    Simplified geometry (sdo_geometry) - Simplified geometry
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_TopologyPreservingSimplify(p_geom              in mdsys.sdo_geometry,
                                         p_distanceTolerance in Number,
                                         p_precision         in number)
    Return mdsys.sdo_geometry deterministic;

  /****f* SC4O/ST_VisvalingamWhyattSimplify
  *  NAME
  *    ST_VisvalingamWhyattSimplify -- Simplifies a geometry using the Visvalingam Whyatt approach.
  *  SYNOPSIS
  *    Function ST_VisvalingamWhyattSimplify(p_geom              in mdsys.sdo_geometry,
  *                                          p_distanceTolerance in Number,
  *                                          p_precision         in number)
  *      Return mdsys.sdo_geometry deterministic;
  *  DESCRIPTION
  *    Simplifies an SDO_GEOMETRY using the Visvalingam-Whyatt algorithm.
  *    The Visvalingam-Whyatt algorithm simplifies geometry by removing vertices while trying to minimize the area changed.
  *    Ensures that any polygonal geometries returned are valid.
  *    Simple lines are not guaranteed to remain simple after simplification.
  *    All geometry types are handled.
  *    Empty and point geometries are returned unchanged.
  *    Empty geometry components are deleted.
  *    The simplification tolerance is specified as a distance.
  *    This is converted to an area tolerance by squaring it.
  *  NOTES
  *    In general this algorithm does not preserve topology - e.g. polygons can be split,
  *    collapse to lines or disappear holes can be created or disappear, and lines can cross.
  *  ARGUMENTS
  *    p_geom        (sdo_geometry) -- Geometry for which simplification is required.
  *    p_distanceTolerance (Number) -- The maximum distance difference.
  *    p_precision        (integer) -- Precision of an ordinate expresses in decimal digits of precision eg 0.001m = 3.
  *  RESULT
  *    Simplified geometry (sdo_geometry) - Simplified geometry
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - November 2016 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_VisvalingamWhyattSimplify(p_geom              in mdsys.sdo_geometry,
                                        p_distanceTolerance in Number,
                                        p_precision         in number)
    Return mdsys.sdo_geometry deterministic;

  /** ============================= Input / Output =====================================*/

  -- Input

  /****f* SC4O/ST_GeomFromEWKT(clob)
  *  NAME
  *    ST_GeomFromEWKT -- Create SDO_GEOMETRY object from Extended Well Known Text formatted CLOB.
  *  SYNOPSIS
  *    Function ST_GeomFromEWKT(p_ewkt in CLOB)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Creates SDO_GEOMETRY object from Extended Well Known Text formatted string. Supports empty EWKT such as
  *    "POINT EMPTY" which will result in SDO_GEOMETRY(NULL,NULL,NULL,NULL,NULL).
  *    If EWKT has no SRID, sdo_srid is set to NULL, otherwise returned sdo_srid will be set to srid_value in prefixed SRID=<srid_value>.
  *  ARGUMENTS
  *    p_ewkt           (clob) -- Extended (PostGIS) Well Known Text string.
  *  RESULT
  *    geometry (sdo_geometry) - Sdo_Geometry object.
  *  EXAMPLE
  *    select sc4o.ST_GeomFromEWKT(TO_CLOB('SRID=28355;POINTZ (-123.08963356 49.27575579 70)')) as geom from dual
  *    union all
  *    select sc4o.ST_GeomFromEWKT(TO_CLOB('LINESTRING Z (1 1 20,2 1 30,3 1 40)')) as geom from dual
  *    union all
  *    select sc4o.ST_GeomFromEWKT(TO_CLOB('LINESTRING M (1 1 20,2 1 30,3 1 40)')) as geom from dual
  *    union all
  *    select SC4O.ST_GeomFromEWKT(TO_CLOB('SRID=8307;POLYGON Z ((0 0 10,0 1 20,1 1 30,1 0 40,0 0 10))')) from dual;
  *
  *    GEOM
  *    -----------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3001,28355,SDO_POINT_TYPE(-123.08963356,49.27575579,70),NULL,NULL)
  *    SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1,1,20,2,1,30,3,1,40))
  *    SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1,1,20,2,1,30,3,1,40))
  *    SDO_GEOMETRY(3003,8307,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,10,1,0,40,1,1,30,0,1,20,0,0,10))
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *  NOTES
  *   This software is based on other open source projects. I am very grateful to:
  *     - Java Topology Suite (JTS). http://sourceforge.net/projects/jts-topo-suite/
  *     - JAva SPAtial for SQL (JASPA) is free software redistributed under terms of the
  *       GNU General Public License Version 2+. http://forge.osor.eu/projects/jaspa/
  *     - GeoTools. http://www.geotools.org/
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_GeomFromEWKT(p_ewkt in CLOB)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_GeomFromEWKT(clob,srid)
  *  NAME
  *    ST_GeomFromEWKT -- Create SDO_GEOMETRY object from Extended Well Known Text formatted CLOB and srid.
  *  SYNOPSIS
  *    Function ST_GeomFromEWKT(p_ewkt in CLOB,
  *                             p_srid in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Creates SDO_GEOMETRY object from Extended Well Known Text formatted CLOB.
  *    Supports empty EWKT such as "POINT EMPTY" which will result in SDO_GEOMETRY(NULL,NULL,NULL,NULL,NULL).
  *    We keep EWKT SRID=<value> only if <value> is 0, otherwise p_srid overwrites EWKT SRID (SRID=28355;LINESTRING....).
  *    p_srid => -1 means NULL.
  *  ARGUMENTS
  *    p_ewkt           (clob) -- Extended (PostGIS) Well Known Text string.
  *    p_srid        (integer) -- SRID for when no SRID is supplied with the EWKT.
  *  RESULT
  *    geometry (sdo_geometry) -- Sdo_Geometry object.
  *  EXAMPLE
  *    select sc4o.ST_GeomFromEWKT(TO_CLOB('POINT Z (-123.08963356 49.27575579 70)'),4283) as geom from dual
  *    union all
  *    select sc4o.ST_GeomFromEWKT(TO_CLOB('SRID=28355;POINTZ (-123.08963356 49.27575579 70)'),4283) as geom from dual
  *    union all
  *    select sc4o.ST_GeomFromEWKT(TO_CLOB('LINESTRING (1 1,2 1,3 1)'),28355) as geom from dual
  *    union all
  *    select SC4O.ST_GeomFromEWKT(TO_CLOB('SRID=8307;POLYGON Z ((0 0 10,0 1 20,1 1 30,1 0 40,0 0 10))'),28355) from dual
  *    union all
  *    select SC4O.ST_GeomFromEWKT(SC4O.ST_AsEWKT(sdo_geometry(3001,28355,sdo_point_type(1,1,1),null,null)),28355) from dual;
  *
  *    GEOM
  *    -----------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3001,4283,SDO_POINT_TYPE(-123.08963356,49.27575579,70),NULL,NULL)
  *    SDO_GEOMETRY(3001,28355,SDO_POINT_TYPE(-123.08963356,49.27575579,70),NULL,NULL)
  *    SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1,1,2,1,3,1))
  *    SDO_GEOMETRY(3003,8307,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,10,1,0,40,1,1,30,0,1,20,0,0,10))
  *    SDO_GEOMETRY(3001,28355,SDO_POINT_TYPE(1,1,1),NULL,NULL)
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  * NOTES
  *   This software is based on other open source projects. I am very grateful to:
  *     - Java Topology Suite (JTS). http://sourceforge.net/projects/jts-topo-suite/
  *     - JAva SPAtial for SQL (JASPA) is free software redistributed under terms of the
  *       GNU General Public License Version 2+. http://forge.osor.eu/projects/jaspa/
  *     - GeoTools. http://www.geotools.org/
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_GeomFromEWKT(p_ewkt in CLOB,
                           p_srid in number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_GeomFromEWKT(varchar2)
  *  NAME
  *    ST_GeomFromEWKT -- Create SDO_GEOMETRY object from Extended Well Known Text formatted varchar2 string.
  *  SYNOPSIS
  *    Function ST_GeomFromEWKT(p_ewkt in varchar2)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Creates SDO_GEOMETRY object from Extended Well Known Text formatted varchar2 string.
  *    Supports empty EWKT such as "POINT EMPTY" which will result in SDO_GEOMETRY(NULL,NULL,NULL,NULL,NULL).
  *    If EWKT has no SRID and p_srid is not null, the returned sdo_geometry will have its sdo_srid set to p_srid.
  *  ARGUMENTS
  *    p_ewkt       (varchar2) -- Extended (PostGIS) Well Known Text string.
  *  RESULT
  *    geometry (sdo_geometry) -- Sdo_Geometry object.
  *  EXAMPLE
  *    select sc4o.ST_GeomFromEWKT('SRID=28355;POINTZ (-123.08963356 49.27575579 70)') as geom from dual
  *    union all
  *    select sc4o.ST_GeomFromEWKT('LINESTRING Z (1 1 20,2 1 30,3 1 40)') as geom from dual
  *    union all
  *    select sc4o.ST_GeomFromEWKT('LINESTRING M (1 1 20,2 1 30,3 1 40)') as geom from dual
  *    union all
  *    select SC4O.ST_GeomFromEWKT('SRID=8307;POLYGON Z ((0 0 10,0 1 20,1 1 30,1 0 40,0 0 10))') from dual;
  *
  *    GEOM
  *    -----------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3001,28355,SDO_POINT_TYPE(-123.08963356,49.27575579,70),NULL,NULL)
  *    SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1,1,20,2,1,30,3,1,40))
  *    SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1,1,20,2,1,30,3,1,40))
  *    SDO_GEOMETRY(3003,8307,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,10,1,0,40,1,1,30,0,1,20,0,0,10))
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *  NOTES
  *   This software is based on other open source projects. I am very grateful to:
  *     - Java Topology Suite (JTS). http://sourceforge.net/projects/jts-topo-suite/
  *     - JAva SPAtial for SQL (JASPA) is free software redistributed under terms of the
  *       GNU General Public License Version 2+. http://forge.osor.eu/projects/jaspa/
  *     - GeoTools. http://www.geotools.org/
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_GeomFromEWKT(p_ewkt in varchar2)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_GeomFromEWKT(varchar2,srid)
  *  NAME
  *    ST_GeomFromEWKT -- Create SDO_GEOMETRY object from Extended Well Known Text formatted varchar2 string.
  *  SYNOPSIS
  *    Function ST_GeomFromEWKT(p_ewkt in varchar2,
  *                             p_srid in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Creates SDO_GEOMETRY object from Extended Well Known Text formatted varchar2 string.
  *    Supports empty EWKT such as "POINT EMPTY" which will result in SDO_GEOMETRY(NULL,NULL,NULL,NULL,NULL).
  *    We keep EWKT SRID=<value> only if <value> is 0, otherwise p_srid overwrites EWKT SRID (SRID=28355;LINESTRING....)
  *    p_srid => -1 means NULL.
  *  ARGUMENTS
  *    p_ewkt           (clob) -- Extended (PostGIS) Well Known Text string.
  *    p_srid        (integer) -- SRID for when no SRID is supplied with the EWKT.
  *  RESULT
  *    geometry (sdo_geometry) -- Sdo_Geometry object.
  *  EXAMPLE
  *    select sc4o.ST_GeomFromEWKT('POINT Z (-123.08963356 49.27575579 70)',4283) as geom from dual
  *    union all
  *    select sc4o.ST_GeomFromEWKT('SRID=28355;POINTZ (-123.08963356 49.27575579 70)',4283) as geom from dual
  *    union all
  *    select sc4o.ST_GeomFromEWKT('LINESTRING (1 1,2 1,3 1)',28355) as geom from dual
  *    union all
  *    select SC4O.ST_GeomFromEWKT('SRID=8307;POLYGON Z ((0 0 10,0 1 20,1 1 30,1 0 40,0 0 10))',28355) from dual;
  *
  *    GEOM
  *    -----------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3001,4283,SDO_POINT_TYPE(-123.08963356,49.27575579,70),NULL,NULL)
  *    SDO_GEOMETRY(3001,28355,SDO_POINT_TYPE(-123.08963356,49.27575579,70),NULL,NULL)
  *    SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1,1,2,1,3,1))
  *    SDO_GEOMETRY(3003,8307,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,10,1,0,40,1,1,30,0,1,20,0,0,10))
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  * NOTES
  *   This software is based on other open source projects. I am very grateful to:
  *     - Java Topology Suite (JTS). http://sourceforge.net/projects/jts-topo-suite/
  *     - JAva SPAtial for SQL (JASPA) is free software redistributed under terms of the
  *       GNU General Public License Version 2+. http://forge.osor.eu/projects/jaspa/
  *     - GeoTools. http://www.geotools.org/
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_GeomFromEWKT(p_ewkt in varchar2,
                           p_srid in number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_GeomFromText(clob)
  *  NAME
  *    ST_GeomFromText -- Create SDO_GEOMETRY object from Well Known Text (WKT) formatted string as CLOB.
  *  SYNOPSIS
  *    Function ST_GeomFromText(p_wkt in CLOB)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Creates SDO_GEOMETRY object from Extended Well Known Text formatted string.
  *    Supports empty EWKT such as "POINT EMPTY" which will result in SDO_GEOMETRY(NULL,NULL,NULL,NULL,NULL).
  *    If EWKT has no SRID and p_srid is not null, the returned sdo_geometry will have its sdo_srid set to p_srid.
  *  ARGUMENTS
  *    p_ewkt           (clob) -- Extended (PostGIS) Well Known Text string.
  *  RESULT
  *    geometry (sdo_geometry) - Sdo_Geometry object.
  *  EXAMPLE
  *    select sc4o.ST_GeomFromText(TO_CLOB('SRID=28355;POINTZ (-123.08963356 49.27575579 70)')) as geom from dual
  *    union all
  *    select sc4o.ST_GeomFromText(TO_CLOB('LINESTRING Z (1 1 20,2 1 30,3 1 40)')) as geom from dual
  *    union all
  *    select sc4o.ST_GeomFromText(TO_CLOB('LINESTRING M (1 1 20,2 1 30,3 1 40)')) as geom from dual
  *    union all
  *    select SC4O.ST_GeomFromText(TO_CLOB('SRID=8307;POLYGON Z ((0 0 10,0 1 20,1 1 30,1 0 40,0 0 10))')) from dual;
  *
  *    GEOM
  *    -----------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3001,28355,SDO_POINT_TYPE(-123.08963356,49.27575579,70),NULL,NULL)
  *    SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1,1,20,2,1,30,3,1,40))
  *    SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1,1,20,2,1,30,3,1,40))
  *    SDO_GEOMETRY(3003,8307,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,10,1,0,40,1,1,30,0,1,20,0,0,10))
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *  NOTES
  *   This software is based on other open source projects. I am very grateful to:
  *     - Java Topology Suite (JTS). http://sourceforge.net/projects/jts-topo-suite/
  *     - JAva SPAtial for SQL (JASPA) is free software redistributed under terms of the
  *       GNU General Public License Version 2+. http://forge.osor.eu/projects/jaspa/
  *     - GeoTools. http://www.geotools.org/
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_GeomFromText(p_wkt in CLOB)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_GeomFromText(clob,srid)
  *  NAME
  *    ST_GeomFromText -- Create SDO_GEOMETRY object from Extended Well Known Text formatted string as CLOB and srid.
  *  SYNOPSIS
  *    Function ST_GeomFromText(p_wkt  in CLOB,
  *                             p_srid in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Creates SDO_GEOMETRY object from Extended Well Known Text formatted CLOB.
  *    Supports empty EWKT such as "POINT EMPTY" which will result in SDO_GEOMETRY(NULL,NULL,NULL,NULL,NULL).
  *    We keep EWKT SRID=<value> only if <value> is 0, otherwise p_srid overwrites EWKT SRID (SRID=28355;LINESTRING....).
  *    p_srid => -1 means NULL.
  *  ARGUMENTS
  *    p_wkt            (clob) -- Extended (PostGIS) Well Known Text string.
  *    p_srid        (integer) -- SRID for when no SRID is supplied with the EWKT.
  *  RESULT
  *    geometry (sdo_geometry) -- Sdo_Geometry object.
  *  EXAMPLE
  *    select sc4o.ST_GeomFromText(TO_CLOB('POINT Z (-123.08963356 49.27575579 70)'),4283) as geom from dual
  *    union all
  *    select sc4o.ST_GeomFromText(TO_CLOB('SRID=28355;POINTZ (-123.08963356 49.27575579 70)'),4283) as geom from dual
  *    union all
  *    select sc4o.ST_GeomFromText(TO_CLOB('LINESTRING (1 1,2 1,3 1)'),28355) as geom from dual
  *    union all
  *    select SC4O.ST_GeomFromText(TO_CLOB('SRID=8307;POLYGON Z ((0 0 10,0 1 20,1 1 30,1 0 40,0 0 10))'),28355) from dual
  *    union all
  *    select SC4O.ST_GeomFromText(SC4O.ST_AsEWKT(sdo_geometry(3001,28355,sdo_point_type(1,1,1),null,null)),28355) from dual;
  *
  *    GEOM
  *    -----------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3001,4283,SDO_POINT_TYPE(-123.08963356,49.27575579,70),NULL,NULL)
  *    SDO_GEOMETRY(3001,28355,SDO_POINT_TYPE(-123.08963356,49.27575579,70),NULL,NULL)
  *    SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1,1,2,1,3,1))
  *    SDO_GEOMETRY(3003,8307,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,10,1,0,40,1,1,30,0,1,20,0,0,10))
  *    SDO_GEOMETRY(3001,28355,SDO_POINT_TYPE(1,1,1),NULL,NULL)
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  * NOTES
  *   This software is based on other open source projects. I am very grateful to:
  *     - Java Topology Suite (JTS). http://sourceforge.net/projects/jts-topo-suite/
  *     - JAva SPAtial for SQL (JASPA) is free software redistributed under terms of the
  *       GNU General Public License Version 2+. http://forge.osor.eu/projects/jaspa/
  *     - GeoTools. http://www.geotools.org/
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_GeomFromText(p_wkt  in CLOB,
                           p_srid in number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_GeomFromText(varchar2)
  *  NAME
  *    ST_GeomFromText -- Create SDO_GEOMETRY object from Well Known Text formatted string.
  *  SYNOPSIS
  *    Function ST_GeomFromText(p_wkt in varchar2)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Creates SDO_GEOMETRY object from Well Known Text formatted string (varchar2).
  *    Supports empty EWKT such as "POINT EMPTY" which will result in SDO_GEOMETRY(NULL,NULL,NULL,NULL,NULL).
  *    We keep EWKT SRID=<value> only if <value> is 0, otherwise p_srid overwrites EWKT SRID (SRID=28355;LINESTRING....).
  *    p_srid => -1 means NULL.
  *  ARGUMENTS
  *    p_wkt        (varchar2) -- Well Known Text (WKT) string as varchar2.
  *  RESULT
  *    geometry (sdo_geometry) -- Sdo_Geometry object.
  *  EXAMPLE
  *    select sc4o.ST_GeomFromText('SRID=28355;POINTZ (-123.08963356 49.27575579 70)') as geom from dual
  *    union all
  *    select sc4o.ST_GeomFromText('LINESTRING Z (1 1 20,2 1 30,3 1 40)') as geom from dual
  *    union all
  *    select sc4o.ST_GeomFromText('LINESTRING M (1 1 20,2 1 30,3 1 40)') as geom from dual
  *    union all
  *    select SC4O.ST_GeomFromText('SRID=8307;POLYGON Z ((0 0 10,0 1 20,1 1 30,1 0 40,0 0 10))') from dual;
  *
  *    GEOM
  *    -----------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3001,28355,SDO_POINT_TYPE(-123.08963356,49.27575579,70),NULL,NULL)
  *    SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1,1,20,2,1,30,3,1,40))
  *    SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1,1,20,2,1,30,3,1,40))
  *    SDO_GEOMETRY(3003,8307,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,10,1,0,40,1,1,30,0,1,20,0,0,10))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_GeomFromText(p_wkt in varchar2)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_GeomFromText(varchar2,srid)
  *  NAME
  *    ST_GeomFromText -- Create SDO_GEOMETRY object from Extended Well Known Text formatted string.
  *  SYNOPSIS
  *    Function ST_GeomFromText(p_wkt  in varchar2,
  *                             p_srid in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Creates SDO_GEOMETRY object from Known Text formatted varchar2.
  *    Supports empty EWKT such as "POINT EMPTY" which will result in SDO_GEOMETRY(NULL,NULL,NULL,NULL,NULL).
  *    We keep EWKT SRID=<value> only if <value> is 0, otherwise p_srid overwrites EWKT SRID (SRID=28355;LINESTRING....).
  *    p_srid => -1 means NULL.
  *  ARGUMENTS
  *    p_wkt            (clob) -- Extended (PostGIS) Well Known Text string.
  *    p_srid        (integer) -- SRID for when no SRID is supplied with the EWKT.
  *  RESULT
  *    geometry (sdo_geometry) -- Sdo_Geometry object.
  *  EXAMPLE
  *    select sc4o.ST_GeomFromText(POINT Z (-123.08963356 49.27575579 70)',4283) as geom from dual
  *    union all
  *    select sc4o.ST_GeomFromText(SRID=28355;POINTZ (-123.08963356 49.27575579 70)',4283) as geom from dual
  *    union all
  *    select sc4o.ST_GeomFromText(LINESTRING (1 1,2 1,3 1)',28355) as geom from dual
  *    union all
  *    select SC4O.ST_GeomFromText(SRID=8307;POLYGON Z ((0 0 10,0 1 20,1 1 30,1 0 40,0 0 10))',28355) from dual;
  *
  *    GEOM
  *    -----------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3001,4283,SDO_POINT_TYPE(-123.08963356,49.27575579,70),NULL,NULL)
  *    SDO_GEOMETRY(3001,28355,SDO_POINT_TYPE(-123.08963356,49.27575579,70),NULL,NULL)
  *    SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1,1,2,1,3,1))
  *    SDO_GEOMETRY(3003,8307,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,10,1,0,40,1,1,30,0,1,20,0,0,10))
  *    SDO_GEOMETRY(3001,28355,SDO_POINT_TYPE(1,1,1),NULL,NULL)
  *  ERRORS
  *    Can throw one or other of the following exceptions:
  *  NOTES
  *   This software is based on other open source projects. I am very grateful to:
  *     - Java Topology Suite (JTS). http://sourceforge.net/projects/jts-topo-suite/
  *     - JAva SPAtial for SQL (JASPA) is free software redistributed under terms of the
  *       GNU General Public License Version 2+. http://forge.osor.eu/projects/jaspa/
  *     - GeoTools. http://www.geotools.org/
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_GeomFromText(p_wkt  in varchar2,
                           p_srid in number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_GeomFromGML
  *  NAME
  *    ST_GeomFromGML -- Create SDO_GEOMETRY object from Geography Markup Language formatted string.
  *  SYNOPSIS
  *    Function ST_GeomFromGML(p_gml in varchar2)
  *      Return mdsys.sdo_geometry Deterministic;
  *  DESCRIPTION
  *    Creates SDO_GEOMETRY object from from Geography Markup Language 2 formatted string.
  *  ARGUMENTS
  *    p_wkt        (varchar2) -- GML string (.
  *    p_srid        (integer) -- SRID for when no SRID is supplied with the EWKT.
  *  RESULT
  *    geometry (sdo_geometry) -- Sdo_Geometry object.
  *  EXAMPLE
  *    SELECT SC4O.ST_GeomFromGML('<gml:Polygon srsName="SDO:" xmlns:gml="http://www.opengis.net/gml"><gml:outerBoundaryIs><gml:LinearRing><gml:coordinates decimal="." cs="," ts=" ">5.0,1.0 8.0,1.0 8.0,6.0 5.0,7.0 5.0,1.0</gml:coordinates></gml:LinearRing></gml:outerBoundaryIs></gml:Polygon>') as gmlGeom
  *      FROM DUAL;
  *
  *    GMLGEOM
  *    --------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(5,1,8,1,8,6,5,7,5,1))
  *  NOTES
  *    Supports GML2 only.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_GeomFromGML(p_gml in varchar2)
    Return mdsys.sdo_geometry Deterministic;

  -- Output

  /****f* SC4O/ST_AsText
  *  NAME
  *    ST_AsText -- Creates Well Known Text (WKT) from SDO_GEOMETRY Object
  *  SYNOPSIS
  *    Function ST_AsText(p_geom in sdo_geometry)
  *      Return CLOB deterministic;
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- Non null sdo_geometry
  *  RESULT
  *    wkt            (clob) -- WKT object.
  *  EXAMPLE
  *    select SC4O.ST_AsEWKT(sdo_geometry(2001,28355,sdo_point_type(1,1,null),null,null)) as wkt from dual union all
  *    select SC4O.ST_AsEWKT(sdo_geometry(3001,null,sdo_point_type(1,1,1),null,null)) from dual union all
  *    select SC4O.ST_AsEWKT(sdo_geometry(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1,1,2,1,3,1))) from dual union all
  *    select SC4O.ST_AsEWKT(sdo_geometry(3003,8307,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,10,1,0,40,1,1,30,0,1,20,0,0,10))) from dual;
  *
  *    WKT
  *    ---------------------------------------------------
  *    POINT (1 1)
  *    POINTZ (1 1 1)
  *    LINESTRING (1 1, 2 1, 3 1)
  *    POLYGONZ ((0 0 10, 1 0 40, 1 1 30, 0 1 20, 0 0 10))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_AsText(p_geom in sdo_geometry)
    Return CLOB deterministic;

  /****f* SC4O/ST_AsEWKT
  *  NAME
  *    ST_AsEWKT -- Creates Extended Well Known Text (EWKT) from SDO_GEOMETRY Object
  *  SYNOPSIS
  *    Function ST_AsEWKT(p_geom in sdo_geometry)
  *      Return CLOB deterministic;
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- Non null sdo_geometry
  *  RESULT
  *    ewkt           (clob) -- EWKT object.
  *  EXAMPLE
  *    select SC4O.ST_AsEWKT(sdo_geometry(2001,28355,sdo_point_type(1,1,null),null,null)) as wkt from dual union all
  *    select SC4O.ST_AsEWKT(sdo_geometry(3001,null,sdo_point_type(1,1,1),null,null)) from dual union all
  *    select SC4O.ST_AsEWKT(sdo_geometry(2002,28355,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,2,1,3,1))) from dual union all
  *    select SC4O.ST_AsEWKT(sdo_geometry(3003,8307,NULL,sdo_elem_info_array(1,1003,1),sdo_ordinate_array(0,0,10,1,0,40,1,1,30,0,1,20,0,0,10))) from dual;
  *
  *    WKT
  *    -------------------------------------------------------------
  *    SRID=28355;POINT (1 1)
  *    SRID=NULL;POINTZ (1 1 1)
  *    SRID=28355;LINESTRING (1 1, 2 1, 3 1)
  *    SRID=8307;POLYGONZ ((0 0 10, 1 0 40, 1 1 30, 0 1 20, 0 0 10))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_AsEWKT(p_geom in sdo_geometry)
    Return CLOB deterministic;

  /****f* SC4O/ST_AsGML
  *  NAME
  *    ST_AsGML -- Creates GML from SDO_GEOMETRY Object
  *  SYNOPSIS
  *    Function ST_AsGML(p_geom in sdo_geometry)
  *      Return CLOB deterministic;
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- Non null sdo_geometry
  *  RESULT
  *    GML            (clob) -- EWKT object.
  *  DESCRIPTION
  * 
  *  EXAMPLE
  *    select SC4O.ST_AsGml(sdo_geometry(2001,28355,sdo_point_type(1,1,null),null,null)) as wkt from dual union all
  *    select SC4O.ST_AsGml(sdo_geometry(3001,null,sdo_point_type(1,1,1),null,null)) from dual union all
  *    select SC4O.ST_AsGml(sdo_geometry(2002,28355,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,2,1,3,1))) from dual union all
  *    select SC4O.ST_AsGml(sdo_geometry(3003,8307,NULL,sdo_elem_info_array(1,1003,1),sdo_ordinate_array(0,0,10,1,0,40,1,1,30,0,1,20,0,0,10))) from dual;
  *    WKT
  *    ------------------------------------------------------------------------------
  *    <gml:Point srsName='EPSG:28355'>
  *      <gml:coordinates>
  *        1.0,1.0
  *      </gml:coordinates>
  *    </gml:Point>
  *    
  *    
  *    <gml:Point>
  *      <gml:coordinates>
  *        1.0,1.0,1.0
  *      </gml:coordinates>
  *    </gml:Point>
  *    
  *    
  *    <gml:LineString srsName='EPSG:28355'>
  *      <gml:coordinates>
  *        1.0,1.0 2.0,1.0 3.0,1.0
  *      </gml:coordinates>
  *    </gml:LineString>
  *    
  *    
  *    <gml:Polygon srsName='EPSG:8307'>
  *      <gml:outerBoundaryIs>
  *        <gml:LinearRing>
  *          <gml:coordinates>
  *            0.0,0.0,10.0 1.0,0.0,40.0 1.0,1.0,30.0 0.0,1.0,20.0 0.0,0.0,10.0
  *          </gml:coordinates>
  *        </gml:LinearRing>
  *      </gml:outerBoundaryIs>
  *    </gml:Polygon>
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_AsGML(p_geom in sdo_geometry)
    Return CLOB deterministic;

  /****f* SC4O/ST_AsBinary
  *  NAME
  *    ST_AsBinary -- Creates Well Known Binary (WKB) from SDO_GEOMETRY Object
  *  SYNOPSIS
  *    Function ST_AsBinary(p_geom in sdo_geometry)
  *      Return BLOB deterministic;
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- Non null sdo_geometry
  *  RESULT
  *    WKB            (blob) -- Result of creation
  *  EXAMPLE
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_AsBinary(p_geom in sdo_geometry)
    Return BLOB deterministic;

  /****f* SC4O/ST_AsBinary(geometry,endian)
  *  NAME
  *    ST_AsBinary -- Creates a standard Well Known Binary (WKB) from SDO_GEOMETRY Object
  *  SYNOPSIS
  *    Function ST_AsBinary(p_geom   in sdo_geometry,
  *                         p_endian in varchar2 )
  *      Return BLOB deterministic;
  *  DESCRIPTION
  *    This function creates a standard well known binary object with required byte order.
  *    The byte order (p_endian) must be NDR (little-endian) or XDR (big-endian).
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- Non null sdo_geometry
  *    p_endian   (varchar2) -- String "NDR" (little-endian) or "XDR" (big-endian).
  *  RESULT
  *    EWKB           (blob) -- EWKB as blob with suitable endian encoding.
  *  EXAMPLE
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_AsBinary(p_geom   in sdo_geometry,
                       p_endian in varchar2 )
    Return BLOB deterministic;

  /****f* SC4O/ST_AsEWKB(geometry)
  *  NAME
  *    ST_AsEWKB -- Creates Extended Well Known Binary (WKB) from SDO_GEOMETRY Object
  *  SYNOPSIS
  *    Function ST_AsEWKB(p_geom in sdo_geometry)
  *      Return BLOB deterministic;
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- Non null sdo_geometry
  *  RESULT
  *    EWKB           (blob) -- EWKB as blob
  *  EXAMPLE
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_AsEWKB(p_geom in sdo_geometry)
    Return BLOB deterministic;

  /****f* SC4O/ST_AsEWKB(geometry,endian)
  *  NAME
  *    ST_AsEWKB -- Creates Extended Well Known Binary (WKB) from SDO_GEOMETRY Object
  *  SYNOPSIS
  *    Function ST_AsEWKB(p_geom   in sdo_geometry,
  *                       p_endian in varchar2)
  *      Return BLOB deterministic;
  *  DESCRIPTION
  *    This function creates an extended well known binary object with required byte order.
  *    The byte order (p_endian) must be NDR (little-endian) or XDR (big-endian).
  *  ARGUMENTS
  *    p_geom (sdo_geometry) -- Non null sdo_geometry
  *    p_endian   (varchar2) -- String "NDR" (little-endian) or "XDR" (big-endian).
  *  RESULT
  *    EWKB           (blob) -- EWKB as blob with suitable endian encoding.
  *  EXAMPLE
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2012 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_AsEWKB(p_geom   in sdo_geometry,
                     p_endian in varchar2)
    Return BLOB deterministic;

  /****f* SC4O/ST_GeomFromBinary
  *  NAME
  *    ST_GeomFromBinary -- Create SDO_GEOMETRY object from Extended Well Known Binary object.
  *  SYNOPSIS
  *    Function ST_GeomFromBinary(p_ewkb in BLOB)
  *      Return mdsys.sdo_geometry Deterministic;
  *  ARGUMENTS
  *    p_ewkb           (blob) -- An extended well known binary object.
  *  RESULT
  *    geometry (sdo_geometry) -- Result of converting blob to sdo_geometry.
  *  EXAMPLE
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2014 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_GeomFromBinary(p_ewkb in BLOB)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_GeomFromBinary(blob,srid)
  *  NAME
  *    ST_GeomFromBinary -- Create SDO_GEOMETRY object from Extended Well Known Binary object.
  *  SYNOPSIS
  *    Function ST_GeomFromBinary(p_ewkb in BLOB,
  *                               p_srid in number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  ARGUMENTS
  *    p_ewkb           (blob) -- An extended well known binary object.
  *    p_srid        (integer) -- Srid that over-writes any srid that may be encoded in the EWKT.
  *                               set p_srid to -1 to set NULL sdo_srid in sdo_geometry.
  *  RESULT
  *    geometry (sdo_geometry) -- Result of converting blob to sdo_geometry.
  *  EXAMPLE
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2014 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_GeomFromBinary(p_ewkb in BLOB,
                             p_srid in number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_GeomFromEWKB(blob)
  *  NAME
  *    ST_GeomFromEWKB -- Create SDO_GEOMETRY object from Extended Well Known Binary object.
  *  SYNOPSIS
  *    Function ST_GeomFromEWKB(p_ewkb in BLOB)
  *      Return mdsys.sdo_geometry Deterministic;
  *  ARGUMENTS
  *    p_ewkb           (blob) -- An extended well known binary object.
  *  RESULT
  *    geometry (sdo_geometry) -- Result of converting blob to sdo_geometry.
  *  EXAMPLE
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2014 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_GeomFromEWKB(p_ewkb in BLOB)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_GeomFromEWKB(blob,srid)
  *  NAME
  *    ST_GeomFromEWKB -- Create SDO_GEOMETRY object from Extended Well Known Binary object.
  *  SYNOPSIS
  *    Function ST_GeomFromEWKB(p_ewkb in BLOB,
  *                             p_srid in number)
  *      Return mdsys.sdo_geometry Deterministic;\
  *  ARGUMENTS
  *    p_ewkb           (blob) -- An extended well known binary object.
  *    p_srid        (integer) -- Srid that over-writes any srid that may be encoded in the EWKT.
  *                               set p_srid to -1 to set NULL sdo_srid in sdo_geometry.
  *  RESULT
  *    geometry (sdo_geometry) -- Result of converting blob to sdo_geometry.
  *  EXAMPLE
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2014 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_GeomFromEWKB(p_ewkb in BLOB,
                           p_srid in number)
    Return mdsys.sdo_geometry Deterministic;

  /** =========================================================== */
  /** ========================== Aggregate ====================== */
  /** =========================================================== */

  /****f* SC4O/ST_AggrUnionPolygons(geomSet)
  *  NAME
  *    ST_AggrUnionPolygons -- Unions a set of sdo_geometry polygons.
  *  SYNOPSIS
  *    Function ST_AggrUnionPolygons(p_geomset           in mdsys.sdo_geometry_array,
  *                                  p_precision         in number,
  *                                  p_distanceTolerance in Number)
  *      Return mdsys.sdo_geometry Deterministic;
  *
  *  ARGUMENTS
  *    p_geomset           (sdo_geometry_array) - Collection of SDO_GEOMETRY polygon objects.
  *    p_precision         (integer)            - Number of decimal places of precision when comparing ordinates.
  *    p_distanceTolerance (Number)             - Optional maximum distance difference (see ST_TopologyPreservingSimplify) for use with simplifying the resultant geometry. Enter 0.0 for no simplification.
  *  RETURNS
  *    union geometry      (sdo_geometry) - Result of Union (single or multipolygon)
  *  NOTES
  *    The underlying JTS code uses planar arithmetic. For long/lat data it is highly recommended that
  *    the geometries in p_geomset are projected into a suitable SRID before calling and then tranformed back
  *    to the original SRID after processing. See example:
  *  EXAMPLE
  *    select sdo_cs.transform(
  *                    sc4o.ST_AggrUnionPolygons(
  *                            CAST(COLLECT(sdo_cs.transform(a.geom,32630)) as mdsys.sdo_geometry_array),
  *                            2,
  *                            0.5),
  *                    8307) as uGeom
  *     from provinces a;
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_AggrUnionPolygons(p_geomset           in mdsys.sdo_geometry_array,
                                p_precision         in number,
                                p_distanceTolerance in Number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_AggrUnionMixed(geomSet)
  *  NAME
  *    ST_AggrUnionMixed -- Unions a set of sdo_geometry objects (can be mix of polygons, lines etc).
  *  SYNOPSIS
  *    Function ST_AggrUnionMixed(p_geomset           in mdsys.sdo_geometry_array,
  *                               p_precision         in number,
  *                               p_distanceTolerance in Number)
  *      Return mdsys.sdo_geometry Deterministic;
  *
  *  ARGUMENTS
  *    p_geomset           (sdo_geometry_array) - Collection of SDO_GEOMETRY objects.
  *    p_precision         (integer)            - number of decimal places of precision when comparing ordinates.
  *    p_distanceTolerance (Number)             - Optional maximum distance difference (see ST_TopologyPreservingSimplify)
  *                                               for use with simplifying the resultant geometry. Enter 0.0 for no simplification.
  *  RETURNS
  *    Union Geometry (sdo_geometry) 
  *  NOTES
  *    The underlying JTS code uses planar arithmetic. For long/lat data it is highly recommended that
  *    the geometries in p_geomset are projected into a suitable SRID before calling and then tranformed back
  *    to the original SRID after processing. See example:
  *  EXAMPLE
  *    select sdo_cs.transform(
  *                    sc4o.ST_AggrUnionMixed(
  *                            CAST(COLLECT(sdo_cs.transform(a.geom,32630)) as mdsys.sdo_geometry_array),
  *                            2,
  *                            0.5),
  *                    8307) as uGeom
  *     from provinces a;
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_AggrUnionMixed(p_geomset           in mdsys.sdo_geometry_array,
                             p_precision         in number,
                             p_distanceTolerance in Number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_AggrUnionPolygons(refCur)
  *  NAME
  *    ST_AggrUnionPolygons -- Unions a result set of sdo_geometry polygons.
  *  SYNOPSIS
  *    Function ST_AggrUnionPolygons(p_resultSet         in &&defaultSchema..SC4O.refcur_t,
  *                                  p_precision         in number,
  *                                  p_distanceTolerance in Number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  ARGUMENTS
  *    p_resultSet         (SC4O.refcur_t) - SQL statement defining a ref cursor collection of SDO_GEOMETRY polygon objects.
  *    p_precision         (integer)       - Number of decimal places of precision when comparing ordinates.
  *    p_distanceTolerance (Number)        - Optional maximum distance difference (see ST_TopologyPreservingSimplify)
  *                                          for use with simplifying the resultant geometry. Enter 0.0 for no simplification.
  *  RETURNS 
  *    Union Geometry (sdo_geometry) -  Single or multipolygon
  *  NOTES 
  *    The underlying JTS code uses planar arithmetic. For long/lat data it is highly recommended that
  *    the geometries in p_geomset are projected into a suitable SRID before calling and then tranformed back
  *    to the original SRID after processing. See example:
  *  EXAMPLE
  *    select sdo_cs.transform(
  *                   sc4o.ST_AggrUnionPolygons(
  *                           CURSOR(SELECT sdo_cs.transform(b.geom,32630) FROM provinces b),
  *                           2,
  *                           0.5),
  *                   8307) as uGeom
  *     from provinces a;
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_AggrUnionPolygons(p_resultSet         in &&defaultSchema..SC4O.refcur_t,
                                p_precision         in number,
                                p_distanceTolerance in Number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_AggrUnionPolygons(table)
  *  NAME
  *    ST_AggrUnionPolygons -- Unions all sdo_geometry polygon objects in a column of a database objects eg view/table etc.
  *  SYNOPSIS
  *    Function ST_AggrUnionPolygons(p_tableName         in varchar2,
  *                                  p_columnName        in varchar2,
  *                                  p_precision         in number,
  *                                  p_distanceTolerance in Number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  ARGUMENTS
  *    p_tableName         (varchar2) - name of existing table/view etc whose contents will be unioned.
  *    p_columnName        (varchar2) - Name of sdo_geometry column in p_tableName holding polygons for unioning.
  *    p_precision         (integer)  - number of decimal places of precision when comparing ordinates.
  *    p_distanceTolerance (Number)   - Optional maximum distance difference (see ST_TopologyPreservingSimplify)
  *                                     for use with simplifying the resultant geometry. Enter 0.0 for no simplification.
  *  RETURNS
  *    Union Geometry (sdo_geometry) -  Single or multipolygon
  *  NOTES
  *    The underlying JTS code uses planar arithmetic. For long/lat data it is highly recommended that
  *    the geometries in p_geomset are projected into a suitable SRID before calling and then tranformed back
  *    to the original SRID after processing. See example:
  *  EXAMPLE
  *    select sdo_cs.transform(sc4o.ST_AggrUnionPolygons('PROVS32630','GEOM',2,0.5),8307) as uGeom
  *      from dual a;
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_AggrUnionPolygons(p_tableName         in varchar2,
                                p_columnName        in varchar2,
                                p_precision         in number,
                                p_distanceTolerance in Number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_AggrUnionMixed(refcur)
  *  NAME
  *    ST_AggrUnionMixed -- Unions a result set of sdo_geometry objects (can be mix of polygons, lines etc).
  *  SYNOPSIS
  *    Function ST_AggrUnionMixed(p_resultSet         in &&defaultSchema..SC4O.refcur_t,
  *                               p_precision         in number,
  *                               p_distanceTolerance in Number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  ARGUMENTS
  *    p_resultSet       (refcur_t) - SQL statement defining a ref cursor collection of SDO_GEOMETRY objects.
  *    p_precision        (integer) - Number of decimal places of precision when comparing ordinates.
  *    p_distanceTolerance (Number) - Optional maximum distance difference (see ST_TopologyPreservingSimplify)
  *                                   for use with simplifying the resultant geometry. Enter 0.0 for no simplification.
  *  RETURNS
  *    Result of Union (sdo_geometry)
  *  NOTES
  *    The underlying JTS code uses planar arithmetic. For long/lat data it is highly recommended that
  *    the geometries in p_geomset are projected into a suitable SRID before calling and then tranformed back
  *    to the original SRID after processing. See example:
  *  EXAMPLE
  *    select sdo_cs.transform(
  *                    sc4o.ST_AggrUnionPolygons(CURSOR(SELECT sdo_cs.transform(b.geom,32630) 
  *                                                       FROM provinces b),
  *                                              2,
  *                                              0.5),
  *                    8307) as uGeom
  *     from provinces a;
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_AggrUnionMixed(p_resultSet         in &&defaultSchema..SC4O.refcur_t,
                             p_precision         in number,
                             p_distanceTolerance in Number)
    Return mdsys.sdo_geometry Deterministic;

  /****f* SC4O/ST_AggrUnionMixed(table)
  *  NAME
  *    ST_AggrUnionMixed -- Unions all sdo_geometry objects (can be mix of polygons, lines etc) in a column of a database object eg view/table etc.
  *  SYNOPSIS
  *    Function ST_AggrUnionMixed(p_tableName         in varchar2,
  *                               p_columnName        in varchar2,
  *                               p_precision         in number,
  *                               p_distanceTolerance in Number)
  *      Return mdsys.sdo_geometry Deterministic;
  *  ARGUMENTS
  *    p_tableName         (varchar2) - Name of existing table/view etc whose contents will be unioned.
  *    p_columnName        (varchar2) - Name of sdo_geometry column in p_tableName holding polygons for unioning.
  *    p_precision          (integer) - Number of decimal places of precision when comparing ordinates.
  *    p_distanceTolerance   (Number) - Optional maximum distance difference (see ST_TopologyPreservingSimplify)
  *                                     for use with simplifying the resultant geometry. Enter 0.0 for no simplification.
  *  RETURNS
  *    Union Geometry (sdo_geometry) - Single or multipolygon
  *  NOTES
  *    The underlying JTS code uses planar arithmetic. For long/lat data it is highly recommended that
  *    the geometries in p_geomset are projected into a suitable SRID before calling and then tranformed back
  *    to the original SRID after processing. See example:
  *  EXAMPLE
  *    select sdo_cs.transform(sc4o.ST_AggrUnionMixed('PROVS32630','GEOM',2,0.5),8307) as uGeom
  *      from dual a;
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_AggrUnionMixed(p_tableName         in varchar2,
                             p_columnName        in varchar2,
                             p_precision         in number,
                             p_distanceTolerance in Number)
    Return mdsys.sdo_geometry Deterministic;

End SC4O;
/
SHOW ERRORS

create or replace
PACKAGE BODY SC4O AS

  c_module_name  CONSTANT varchar2(256) := 'SC4O';

  /** ============================ PROPERTIES ==================================== **/

  Function ST_Area(p_geom      in mdsys.sdo_geometry,
                   p_precision in number)
    Return number
        As language java name
           'com.spdba.dbutils.JTS.ST_Area(oracle.sql.STRUCT,int) return double';

  Function ST_Area(p_geom      in mdsys.sdo_geometry,
                   p_precision in number,
                   p_srid      in number)
    Return Number
  As
  Begin
    if ( p_geom is null ) Then
       return null;
    End If;
    if ( p_srid is null OR p_srid = p_geom.sdo_srid ) then
        return &&defaultSchema..SC4O.ST_Area(p_geom,p_precision);
    else
        return &&defaultSchema..SC4O.ST_Area(sdo_cs.transform(p_geom,p_srid),p_precision);
    end if;
  end ST_Area;

  Function ST_Length(p_geom      in mdsys.sdo_geometry,
                     p_precision in number)
    Return number
        As language java name
           'com.spdba.dbutils.JTS.ST_Length(oracle.sql.STRUCT,int) return double';

  Function ST_Length(p_geom      in mdsys.sdo_geometry,
                     p_precision in number,
                     p_srid      in number)
    Return Number
  As
  Begin
    if ( p_geom is null ) Then
       return null;
    End If;
    if ( p_srid is null OR p_srid = p_geom.sdo_srid ) then
        return &&defaultSchema..SC4O.ST_Length(p_geom,p_precision);
    else
        return &&defaultSchema..SC4O.ST_Length(sdo_cs.transform(p_geom,p_srid),p_precision);
    end if;
  end ST_Length;

  Function ST_IsValid(p_geom in mdsys.sdo_geometry )
    Return varchar2
        As language java name
           'com.spdba.dbutils.JTS.ST_IsValid(oracle.sql.STRUCT) return int';

  Function ST_IsSimple(p_geom in mdsys.sdo_geometry )
    Return varchar2
        As language java name
           'com.spdba.dbutils.JTS.ST_IsSimple(oracle.sql.STRUCT) return int';

  Function ST_Dimension(p_geom in mdsys.sdo_geometry )
    Return varchar2
        As language java name
           'com.spdba.dbutils.JTS.ST_Dimension(oracle.sql.STRUCT) return int';

  Function ST_CoordDim(p_geom in mdsys.sdo_geometry )
    Return varchar2
        As language java name
           'com.spdba.dbutils.JTS.ST_CoordDim(oracle.sql.STRUCT) return int';

  Function ST_isValidReason(p_geom      in mdsys.sdo_geometry,
                            p_precision in number)
    Return VarChar2
        As language java name
           'com.spdba.dbutils.JTS.ST_IsValidReason(oracle.sql.STRUCT,int) return java.lang.String';

  /** ============================= EDITORS =====================================*/

  Function ST_DeletePoint(p_geom       in sdo_geometry,
                          p_pointIndex in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_DeletePoint(oracle.sql.STRUCT,int) return oracle.sql.STRUCT';

  Function ST_UpdatePoint(p_geom       in sdo_geometry,
                          p_point      in sdo_geometry,
                          p_pointIndex in number )
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_UpdatePoint(oracle.sql.STRUCT,oracle.sql.STRUCT,int) return oracle.sql.STRUCT';

  Function ST_UpdatePoint(p_geom      in mdsys.sdo_geometry,
                          p_fromPoint in mdsys.sdo_geometry,
                          p_toPoint   in mdsys.sdo_geometry)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_UpdatePoint(oracle.sql.STRUCT,oracle.sql.STRUCT,oracle.sql.STRUCT) return oracle.sql.STRUCT';

  Function ST_InsertPoint(p_geom       in sdo_geometry,
                          p_point      in sdo_geometry,
                          p_pointIndex in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_InsertPoint(oracle.sql.STRUCT,oracle.sql.STRUCT,int) return oracle.sql.STRUCT';

  /** ============================ Utility ==================================== **/

  Function ST_Envelope(p_geom      in mdsys.sdo_geometry,
                       p_precision in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_Envelope(oracle.sql.STRUCT,int) return oracle.sql.STRUCT';

  Function ST_MakeEnvelope(p_minx      in number,
                           p_miny      in number,
                           p_maxx      in number,
                           p_maxy      in number,
                           p_srid      in number,
                           p_precision in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_MakeEnvelope(double,double,double,double,int,int) return oracle.sql.STRUCT';

  /** ============================ COLLECTION ==================================== **/

  Function ST_Collect(p_geomList    in mdsys.sdo_geometry_array,
                      p_returnMulti in boolean)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_Collect(oracle.sql.ARRAY,boolean) return oracle.sql.STRUCT';

  Function ST_Collect(p_geomList    in mdsys.sdo_geometry_array,
                      p_returnMulti in number default 0)
    Return mdsys.sdo_geometry
  As
  Begin
    return ST_Collect(p_geomList,p_returnMulti=1);
  End ST_Collect;

  /** ============================ OVERLAY ==================================== **/

  Function ST_Union(p_geom1     in mdsys.sdo_geometry,
                    p_geom2     in mdsys.sdo_geometry,
                    p_precision in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_Union(oracle.sql.STRUCT,oracle.sql.STRUCT,int) return oracle.sql.STRUCT';

  Function ST_Union(p_geom1     in mdsys.sdo_geometry,
                    p_geom2     in mdsys.sdo_geometry,
                    p_precision in number,
                    p_srid      in number)
    Return mdsys.sdo_geometry
  As
  Begin
    if ( p_geom1 is null or p_geom2 is null ) Then
       return null;
    End If;
    if ( p_srid is null OR p_srid = p_geom1.sdo_srid ) then
        return &&defaultSchema..SC4O.ST_Union(p_geom1,p_geom2,p_precision);
    else
        return sdo_cs.transform(
                      &&defaultSchema..SC4O.ST_Union(sdo_cs.transform(p_geom1,p_srid),
                                                    sdo_cs.transform(p_geom2,p_srid),
                                                    p_precision),
                      p_geom1.sdo_srid);
    end if;
  end ST_Union;

  Function ST_AggrUnionPolygons(p_geomset           in mdsys.sdo_geometry_array,
                                p_precision         in number,
                                p_distanceTolerance in Number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.aggr.Aggregate.aggrUnionPolygons(oracle.sql.ARRAY,int,double) return oracle.sql.STRUCT';

  Function ST_AggrUnionMixed(p_geomset           in mdsys.sdo_geometry_array,
                             p_precision         in number,
                             p_distanceTolerance in Number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.aggr.Aggregate.aggrUnionMixed(oracle.sql.ARRAY,int,double) return oracle.sql.STRUCT';

  Function ST_AggrUnionPolygons(p_resultSet         in &&defaultSchema..SC4O.refcur_t,
                                p_precision         in number,
                                p_distanceTolerance in Number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.aggr.Aggregate.aggrUnionPolygons(java.sql.ResultSet,int,double) return oracle.sql.STRUCT';

  Function ST_AggrUnionMixed(p_resultSet         in &&defaultSchema..SC4O.refcur_t,
                             p_precision         in number,
                             p_distanceTolerance in Number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.aggr.Aggregate.aggrUnionMixed(java.sql.ResultSet,int,double) return oracle.sql.STRUCT';

  Function ST_AggrUnionPolygons(p_tableName         in varchar2,
                                p_columnName        in varchar2,
                                p_precision         in number,
                                p_distanceTolerance in Number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.aggr.Aggregate.aggrUnionPolygons(java.lang.String,java.lang.String,int,double) return oracle.sql.STRUCT';

  Function ST_AggrUnionMixed(p_tableName         in varchar2,
                             p_columnName        in varchar2,
                             p_precision         in number,
                             p_distanceTolerance in Number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.aggr.Aggregate.aggrUnionMixed(java.lang.String,java.lang.String,int,double) return oracle.sql.STRUCT';

  Function ST_Difference(p_geom1     in mdsys.sdo_geometry,
                         p_geom2     in mdsys.sdo_geometry,
                         p_precision in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_Difference(oracle.sql.STRUCT,oracle.sql.STRUCT,int) return oracle.sql.STRUCT';

  Function ST_Difference(p_geom1     in mdsys.sdo_geometry,
                         p_geom2     in mdsys.sdo_geometry,
                         p_precision in number,
                         p_srid      in number )
    Return mdsys.sdo_geometry
  As
  Begin
    if ( p_geom1 is null or p_geom2 is null ) Then
       return null;
    End If;
    if ( p_srid is null OR p_srid = p_geom1.sdo_srid ) then
        return &&defaultSchema..SC4O.ST_Difference(p_geom1,p_geom2,p_precision);
    else
        return sdo_cs.transform(
                      &&defaultSchema..SC4O.ST_Difference(sdo_cs.transform(p_geom1,p_srid),
                                                                sdo_cs.transform(p_geom2,p_srid),
                                                                p_precision),
                      p_geom1.sdo_srid);
    end if;
  end ST_Difference;

  Function ST_Intersection(p_geom1     in mdsys.sdo_geometry,
                           p_geom2     in mdsys.sdo_geometry,
                           p_precision in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_Intersection(oracle.sql.STRUCT,oracle.sql.STRUCT,int) return oracle.sql.STRUCT';

  Function ST_Intersection(p_geom1     in mdsys.sdo_geometry,
                           p_geom2     in mdsys.sdo_geometry,
                           p_precision in number,
                           p_srid      in number )
    Return mdsys.sdo_geometry
  As
  Begin
    if ( p_geom1 is null or p_geom2 is null ) Then
       return null;
    End If;
    if ( p_srid is null OR p_srid = p_geom1.sdo_srid ) then
        return &&defaultSchema..SC4O.ST_intersection(p_geom1,p_geom2,p_precision);
    else
        return sdo_cs.transform(
                      &&defaultSchema..SC4O.ST_intersection(sdo_cs.transform(p_geom1,p_srid),
                                                                  sdo_cs.transform(p_geom2,p_srid),
                                                                  p_precision),
                      p_geom1.sdo_srid);
    end if;
  end ST_Intersection;

  Function ST_Xor(p_geom1     in mdsys.sdo_geometry,
                  p_geom2     in mdsys.sdo_geometry,
                  p_precision in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_Xor(oracle.sql.STRUCT,oracle.sql.STRUCT,int) return oracle.sql.STRUCT';

  Function ST_Xor(p_geom1     in mdsys.sdo_geometry,
                  p_geom2     in mdsys.sdo_geometry,
                  p_precision in number,
                  p_srid      in number )
    Return mdsys.sdo_geometry
  As
  Begin
    if ( p_geom1 is null or p_geom2 is null ) Then
       return null;
    End If;
    if ( p_srid is null OR p_srid = p_geom1.sdo_srid ) then
        return &&defaultSchema..SC4O.ST_Xor(p_geom1,p_geom2,p_precision);
    else
        return sdo_cs.transform(
                      &&defaultSchema..SC4O.ST_Xor(sdo_cs.transform(p_geom1,p_srid),
                                                         sdo_cs.transform(p_geom2,p_srid),
                                                         p_precision),
                      p_geom1.sdo_srid);
    end if;
  end ST_Xor;

  /** Wrapper over XOR
  **/
  Function ST_SymDifference(p_geom1     in mdsys.sdo_geometry,
                            p_geom2     in mdsys.sdo_geometry,
                            p_precision in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_Xor(oracle.sql.STRUCT,oracle.sql.STRUCT,int) return oracle.sql.STRUCT';

  Function ST_SymDifference(p_geom1     in mdsys.sdo_geometry,
                            p_geom2     in mdsys.sdo_geometry,
                            p_precision in number,
                            p_srid      in number )
    Return mdsys.sdo_geometry
  As
  Begin
    if ( p_geom1 is null or p_geom2 is null ) Then
       return null;
    End If;
    if ( p_srid is null OR p_srid = p_geom1.sdo_srid ) then
        return &&defaultSchema..SC4O.ST_SymDifference(p_geom1,p_geom2,p_precision);
    else
        return sdo_cs.transform(
                      &&defaultSchema..SC4O.ST_SymDifference(sdo_cs.transform(p_geom1,p_srid),
                                                                   sdo_cs.transform(p_geom2,p_srid),
                                                                   p_precision),
                      p_geom1.sdo_srid);
    end if;
  end ST_SymDifference;

  /** ================ Comparisons ================= */

  Function ST_HausdorffSimilarityMeasure(p_geom1     in mdsys.sdo_geometry,
                                         p_geom2     in mdsys.sdo_geometry,
                                         p_precision in number)
    Return number
        As language java name
           'com.spdba.dbutils.Comparitor.ST_HausdorffSimilarityMeasure(oracle.sql.STRUCT,oracle.sql.STRUCT,int) return double';

  Function ST_HausdorffSimilarityMeasure(p_geom1     in mdsys.sdo_geometry,
                                         p_geom2     in mdsys.sdo_geometry,
                                         p_precision in number,
                                         p_srid      in number )
    Return number
  As
  Begin
    if ( p_geom1 is null or p_geom2 is null ) Then
       return null;
    End If;
    if ( p_srid is null OR ( p_srid = p_geom1.sdo_srid AND p_srid = p_geom2.sdo_srid) ) then
        return &&defaultSchema..SC4O.ST_HausdorffSimilarityMeasure(p_geom1,p_geom2,p_precision);
    else
        return &&defaultSchema..SC4O.ST_HausdorffSimilarityMeasure(sdo_cs.transform(p_geom1,p_srid),
                                                                         sdo_cs.transform(p_geom2,p_srid),
                                                                         p_precision);
    end if;
  end ST_HausdorffSimilarityMeasure;

  Function ST_AreaSimilarityMeasure(p_poly1     in mdsys.sdo_geometry,
                                    p_poly2     in mdsys.sdo_geometry,
                                    p_precision in number)
    Return number
        As language java name
           'com.spdba.dbutils.Comparitor.ST_AreaSimilarityMeasure(oracle.sql.STRUCT,oracle.sql.STRUCT,int) return double';

  Function ST_AreaSimilarityMeasure(p_poly1     in mdsys.sdo_geometry,
                                    p_poly2     in mdsys.sdo_geometry,
                                    p_precision in number,
                                    p_srid      in number )
    Return number
  As
  Begin
    if ( p_poly1 is null or p_poly2 is null ) Then
       return null;
    End If;
    if ( p_srid is null OR ( p_srid = p_poly1.sdo_srid AND p_srid = p_poly2.sdo_srid) ) then
        return &&defaultSchema..SC4O.ST_AreaSimilarityMeasure(p_poly1,p_poly2,p_precision);
    else
        return &&defaultSchema..SC4O.ST_AreaSimilarityMeasure(sdo_cs.transform(p_poly1,p_srid),
                                                                    sdo_cs.transform(p_poly2,p_srid),
                                                                    p_precision);
    end if;
  end ST_AreaSimilarityMeasure;

  Function ST_Relate(p_geom1     in mdsys.sdo_geometry,
                     p_mask      in varchar2,
                     p_geom2     in mdsys.sdo_geometry,
                     p_precision in number)
    Return varchar2
        As language java name
           'com.spdba.dbutils.Comparitor.ST_Relate(oracle.sql.STRUCT,java.lang.String,oracle.sql.STRUCT,int) return java.lang.String';

  /** ============================== PROCESSING ================================= */

  Function ST_Buffer(p_geom             in mdsys.sdo_geometry,
                     p_distance         in number,
                     p_precision        in number,
                     p_endCapStyle      in number,
                     p_joinStyle        in number,
                     p_quadrantSegments in number ) /* If p_distance is Positive then LEFT else RIGHT */
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_Buffer(oracle.sql.STRUCT,double,int,int,int,int) return oracle.sql.STRUCT';

  Function ST_Buffer(p_geom             in mdsys.sdo_geometry,
                     p_distance         in number,
                     p_precision        in number,
                     p_endCapStyle      in number,
                     p_joinStyle        in number,
                     p_quadrantSegments in number,
                     p_srid             in number)
    Return mdsys.sdo_geometry
  As
  Begin
    if ( p_geom is null ) Then
       return null;
    End If;
    if ( p_srid is null OR p_srid = p_geom.sdo_srid ) then
        Return &&defaultSchema..SC4O.ST_Buffer(
                   p_geom             => p_geom,
                   p_distance         => p_distance,
                   p_precision        => p_precision,
                   p_endCapStyle      => p_endCapStyle,
                   p_joinStyle        => p_joinStyle,
                   p_quadrantSegments => p_quadrantSegments
                );
    else
        Return sdo_cs.Transform(
                 &&defaultSchema..SC4O.ST_Buffer(
                   p_geom             => sdo_cs.transform(p_geom,p_srid),
                   p_distance         => p_distance,
                   p_precision        => p_precision,
                   p_endCapStyle      => p_endCapStyle,
                   p_joinStyle        => p_joinStyle,
                   p_quadrantSegments => p_quadrantSegments
                 ),
                 p_geom.sdo_srid);
    end if;
  End ST_Buffer;

  Function ST_OneSidedBuffer(p_geom             in mdsys.sdo_geometry,
                             p_offset           in number,
                             p_precision        in number,
                             p_endCapStyle      in number,
                             p_joinStyle        in number,
                             p_quadrantSegments in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_OneSidedBuffer(oracle.sql.STRUCT,double,int,int,int,int) return oracle.sql.STRUCT';

  Function ST_OneSidedBuffer(p_geom             in mdsys.sdo_geometry,
                             p_offset           in number,
                             p_precision        in number,
                             p_endCapStyle      in number,
                             p_joinStyle        in number,
                             p_quadrantSegments in number,
                             p_srid             in number)
    Return mdsys.sdo_geometry
  As
  Begin
    if ( p_geom is null ) Then
       return null;
    End If;
    if ( p_srid is null OR p_srid = p_geom.sdo_srid ) then
        Return &&defaultSchema..SC4O.ST_OneSidedBuffer(
                   p_geom             => p_geom,
                   p_offset           => p_offset,
                   p_precision        => p_precision,
                   p_endCapStyle      => p_endCapStyle,
                   p_joinStyle        => p_joinStyle,
                   p_quadrantSegments => p_quadrantSegments
                );
    else
        Return sdo_cs.Transform(
                 &&defaultSchema..SC4O.ST_OneSidedBuffer(
                   p_geom             => sdo_cs.transform(p_geom,p_srid),
                   p_offset           => p_offset,
                   p_precision        => p_precision,
                   p_endCapStyle      => p_endCapStyle,
                   p_joinStyle        => p_joinStyle,
                   p_quadrantSegments => p_quadrantSegments
                 ),
                 p_geom.sdo_srid);
    end if;
  End ST_OneSidedBuffer;

  Function ST_OffsetLine(p_geom             in mdsys.sdo_geometry,
                         p_offset           in number,
                         p_precision        in number,
                         p_endCapStyle      in number,
                         p_joinStyle        in number,
                         p_quadrantSegments in number )
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_OffsetLine(oracle.sql.STRUCT,double,int,int,int,int) return oracle.sql.STRUCT';

  Function ST_OffsetLine(p_geom             in mdsys.sdo_geometry,
                         p_offset           in number,
                         p_precision        in number,
                         p_endCapStyle      in number,
                         p_joinStyle        in number,
                         p_quadrantSegments in number,
                         p_srid             in number)
    Return mdsys.sdo_geometry
   As
   Begin
    if ( p_geom is null ) Then
       return null;
    End If;
    if ( p_srid is null OR p_srid = p_geom.sdo_srid ) then
        Return &&defaultSchema..SC4O.ST_OffsetLine(
                   p_geom             => p_geom,
                   p_offset           => p_offset,
                   p_precision        => p_precision,
                   p_endCapStyle      => p_endCapStyle,
                   p_joinStyle        => p_joinStyle,
                   p_quadrantSegments => p_quadrantSegments
                );
    else
        Return sdo_cs.Transform(
                 &&defaultSchema..SC4O.ST_OffsetLine(
                   p_geom             => sdo_cs.transform(p_geom,p_srid),
                   p_offset           => p_offset,
                   p_precision        => p_precision,
                   p_endCapStyle      => p_endCapStyle,
                   p_joinStyle        => p_joinStyle,
                   p_quadrantSegments => p_quadrantSegments
                 ),
                 p_geom.sdo_srid);
    end if;
  End ST_OffsetLine;

  Function ST_LineDissolver(p_line1              in mdsys.sdo_geometry,
                            p_line2              in mdsys.sdo_geometry,
                            p_precision          in number,
                            p_keepBoundaryPoints in number )
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_LineDissolver(oracle.sql.STRUCT,oracle.sql.STRUCT,int,int) return oracle.sql.STRUCT';

  /**
  * ST_CreateCircle
  * Internal function
  **/
  Function ST_CreateCircle(dCentreX in Number,
                           dCentreY in Number,
                           dRadius  in Number,
                           iSrid    in pls_integer)
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
    RETURN MDSYS.SDO_GEOMETRY(2003,iSrid,MDSYS.SDO_POINT_TYPE(dCentreX, dCentreY, dRadius),MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,4),MDSYS.SDO_ORDINATE_ARRAY(dPnt1X, dPnt1Y, dPnt2X, dPnt2Y, dPnt3X, dPnt3Y));
  End ST_CreateCircle;

  Function doMinimumBoundingCircle(p_geom      in mdsys.sdo_geometry,
                                   p_precision in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_MinimumBoundingCircle(oracle.sql.STRUCT,int) return oracle.sql.STRUCT';

  Function ST_MinimumBoundingCircle(p_geom      in mdsys.sdo_geometry,
                                    p_precision in number)
    Return mdsys.sdo_geometry
  As
    v_circle mdsys.sdo_geometry;
  Begin
    v_circle := doMinimumBoundingCircle(p_geom,p_precision);
    if ( v_circle is not null And v_circle.sdo_point is not null And v_circle.sdo_point.z is not null ) then
        v_circle := ST_CreateCircle(v_circle.sdo_point.x,v_circle.sdo_point.y,v_circle.sdo_point.z,v_circle.sdo_srid);
    End If;
    return v_circle;
  End ST_MinimumBoundingCircle;

  Function ST_MinimumBoundingCircle(p_geom      in mdsys.sdo_geometry,
                                    p_precision in number,
                                    p_srid      in number )
    Return mdsys.sdo_geometry
  As
  Begin
    if ( p_geom is null ) Then
       return null;
    End If;
    if ( p_srid is null OR p_srid = p_geom.sdo_srid ) then
        return &&defaultSchema..SC4O.ST_MinimumBoundingCircle(p_geom,p_precision);
    else
        return sdo_cs.transform(
                      &&defaultSchema..SC4O.ST_MinimumBoundingCircle(sdo_cs.transform(p_geom,p_srid),
                                                                           p_precision),
                      p_geom.sdo_srid);
    end if;
  End ST_MinimumBoundingCircle;

  Function ST_Densify(p_geom              in mdsys.sdo_geometry,
                      p_precision         in number,
                      p_distanceTolerance in Number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_Densify(oracle.sql.STRUCT,int,double) return oracle.sql.STRUCT';

  Function ST_Densify(p_geom              in mdsys.sdo_geometry,
                      p_precision         in number,
                      p_distanceTolerance in Number,
                      p_srid              in number)
    Return mdsys.sdo_geometry
  As
  Begin
    if ( p_geom is null ) Then
       return null;
    End If;
    if ( p_srid is null OR p_srid = p_geom.sdo_srid ) then
        return &&defaultSchema..SC4O.ST_Densify(p_geom,p_precision,p_distanceTolerance);
    else
        return sdo_cs.transform(
                      &&defaultSchema..SC4O.ST_Densify(sdo_cs.transform(p_geom,p_srid),
                                                             p_precision,
                                                             p_distanceTolerance),
                      p_geom.sdo_srid);
    end if;
  End ST_Densify;

  /** ============================ EDIT ==================================== **/

  Function ST_LineMerger(p_resultSet in &&defaultSchema..SC4O.refcur_t,
                         p_precision in number)
    Return mdsys.sdo_geometry
           As language java name
           'com.spdba.dbutils.JTS.ST_LineMerger(java.sql.ResultSet,int) return oracle.sql.STRUCT';

  Function ST_LineMerger(p_geomset   in mdsys.sdo_geometry_array,
                         p_precision in number)
    Return mdsys.sdo_geometry
           As language java name
           'com.spdba.dbutils.JTS.ST_LineMerger(oracle.sql.ARRAY,int) return oracle.sql.STRUCT';

  Function ST_NodeLineStrings(p_geometry  in mdsys.sdo_geometry,
                              p_precision in number)
    Return mdsys.sdo_geometry
           As language java name
           'com.spdba.dbutils.JTS.ST_NodeLineStrings(oracle.sql.STRUCT,int) return oracle.sql.STRUCT';

  Function ST_NodeLineStrings(p_resultSet in &&defaultSchema..SC4O.refcur_t,
                              p_precision in number)
    Return mdsys.sdo_geometry
           As language java name
           'com.spdba.dbutils.JTS.ST_NodeLineStrings(java.sql.ResultSet,int) return oracle.sql.STRUCT';

  Function ST_NodeLineStrings(p_geomset   in mdsys.sdo_geometry_array,
                              p_precision in number)
    Return mdsys.sdo_geometry
           As language java name
           'com.spdba.dbutils.JTS.ST_NodeLineStrings(oracle.sql.ARRAY,int) return oracle.sql.STRUCT';

  /**
  * Method for building a polygon from a set of linestrings
  **/
  Function ST_PolygonBuilder(p_resultSet &&defaultSchema..SC4O.refcur_t,
                             p_precision in number)
    return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_PolygonBuilder(java.sql.ResultSet,int) return oracle.sql.STRUCT';

  Function ST_PolygonBuilder(p_geomset   in mdsys.sdo_geometry_array,
                             p_precision in number)
    return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_PolygonBuilder(oracle.sql.ARRAY,int) return oracle.sql.STRUCT';

  Function ST_PolygonBuilder(p_geometry  in mdsys.sdo_geometry,
                             p_precision in number)
    return mdsys.sdo_geometry
  As
  Begin
      Return ST_PolygonBuilder(mdsys.sdo_geometry_array(p_geometry),
                               p_precision);
  End ST_PolygonBuilder;

   /** ==== Delaunay ==
   */
  Function ST_DelaunayTriangles(p_geometry  in mdsys.sdo_geometry,
                                p_tolerance in number,
                                p_precision in number)
    return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_DelaunayTriangles(oracle.sql.STRUCT,double,int) return oracle.sql.STRUCT';

  Function ST_DelaunayTriangles(p_resultSet in &&defaultSchema..SC4O.refcur_t,
                                p_tolerance in number,
                                p_precision in number)
    return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_DelaunayTriangles(java.sql.ResultSet,double,int) return oracle.sql.STRUCT';

  Function ST_DelaunayTriangles(p_geomset   in mdsys.sdo_geometry_array,
                                p_tolerance in number,
                                p_precision in number)
    return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_DelaunayTriangles(oracle.sql.ARRAY,double,int) return oracle.sql.STRUCT';

   /** ==== Voronoi ==
   */
  Function ST_Voronoi(p_geometry  in mdsys.sdo_geometry,
                      p_envelope  in mdsys.sdo_geometry,
                      p_tolerance in number,
                      p_precision in number)
    return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_Voronoi(oracle.sql.STRUCT,oracle.sql.STRUCT,double,int) return oracle.sql.STRUCT';

  Function ST_Voronoi(p_resultSet in &&defaultSchema..SC4O.refcur_t,
                      p_envelope  in mdsys.sdo_geometry,
                      p_tolerance in number,
                      p_precision in number)
    return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_Voronoi(java.sql.ResultSet,oracle.sql.STRUCT,double,int) return oracle.sql.STRUCT';

  Function ST_Voronoi(p_geomset   in mdsys.sdo_geometry_array,
                      p_envelope  in mdsys.sdo_geometry,
                      p_tolerance in number,
                      p_precision in number)
    return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_Voronoi(oracle.sql.ARRAY,oracle.sql.STRUCT,double,int) return oracle.sql.STRUCT';

  Function ST_InterpolateZ(p_point in mdsys.sdo_geometry,
                           p_geom1 in mdsys.sdo_geometry,
                           p_geom2 in mdsys.sdo_geometry,
                           p_geom3 in mdsys.sdo_geometry)
   Return Number
        As language java name
           'com.spdba.dbutils.JTS.ST_InterpolateZ(oracle.sql.STRUCT,oracle.sql.STRUCT,oracle.sql.STRUCT,oracle.sql.STRUCT) return double';

  Function ST_InterpolateZ(p_point in mdsys.sdo_geometry,
                           p_facet in mdsys.sdo_geometry)
   Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_InterpolateZ(oracle.sql.STRUCT,oracle.sql.STRUCT) return oracle.sql.STRUCT';

  /** ============================ EDIT - Snapping ==================================== **/

  Function ST_Snap(p_geom1         in mdsys.sdo_geometry,
                   p_geom2         in mdsys.sdo_geometry,
                   p_snapTolerance in number,
                   p_precision     in number)
    Return mdsys.sdo_geometry
        As language java name
          'com.spdba.dbutils.JTS.ST_Snap(oracle.sql.STRUCT,oracle.sql.STRUCT,double,int) return oracle.sql.STRUCT';

  Function ST_Snap(p_geom1         in mdsys.sdo_geometry,
                   p_geom2         in mdsys.sdo_geometry,
                   p_snapTolerance in number,
                   p_precision     in number,
                   p_srid          in number)
    Return mdsys.sdo_geometry
  As
  Begin
    if ( p_geom1 is null or p_geom2 is not null ) Then
       return case when p_geom1 is null then p_geom2 else p_geom1 end;
    End If;
    if ( p_srid is null OR ( p_srid = p_geom1.sdo_srid AND p_srid = p_geom2.sdo_srid) ) then
        return &&defaultSchema..SC4O.ST_Snap(p_geom1,p_geom2,p_snapTolerance,p_precision);
    else
        return sdo_cs.transform(
                   &&defaultSchema..SC4O.ST_Snap(sdo_cs.transform(p_geom1,p_srid),
                                                       sdo_cs.transform(p_geom2,p_srid),
                                                       p_snapTolerance,
                                                       p_precision),
                   p_geom1.sdo_srid);
    end if;
  End ST_Snap;

  Function ST_SnapTo(p_geom1         in mdsys.sdo_geometry,
                     p_snapGeom      in mdsys.sdo_geometry,
                     p_snapTolerance in number,
                     p_precision     in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_SnapTo(oracle.sql.STRUCT,oracle.sql.STRUCT,double,int) return oracle.sql.STRUCT';

  Function ST_SnapTo(p_geom1         in mdsys.sdo_geometry,
                     p_snapGeom      in mdsys.sdo_geometry,
                     p_snapTolerance in number,
                     p_precision     in number,
                     p_srid          in number)
    Return mdsys.sdo_geometry
  As
  Begin
    if ( p_geom1 is null or p_snapGeom is not null ) Then
       return case when p_geom1 is null then p_snapGeom else p_geom1 end;
    End If;
    if ( p_srid is null OR ( p_srid = p_geom1.sdo_srid AND p_srid = p_snapGeom.sdo_srid) ) then
        return &&defaultSchema..SC4O.ST_SnapTo(p_geom1,p_snapGeom,p_snapTolerance,p_precision);
    else
        return sdo_cs.transform(
                   &&defaultSchema..SC4O.ST_SnapTo(sdo_cs.transform(p_geom1,p_srid),
                                                      sdo_cs.transform(p_snapGeom,p_srid),
                                                      p_snapTolerance,
                                                      p_precision),
                   p_geom1.sdo_srid);
    end if;
  End ST_SnapTo;

  Function ST_SnapToSelf(p_geom          in mdsys.sdo_geometry,
                         p_snapTolerance in number,
                         p_precision     in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_SnapToSelf(oracle.sql.STRUCT,double,int) return oracle.sql.STRUCT';

  Function ST_SnapToSelf(p_geom          in mdsys.sdo_geometry,
                         p_snapTolerance in number,
                         p_precision     in number,
                         p_srid          in number)
    Return mdsys.sdo_geometry
  As
  Begin
    if ( p_geom is null ) Then
       return null;
    End If;
    if ( p_srid is null OR p_srid = p_geom.sdo_srid ) then
        return &&defaultSchema..SC4O.ST_SnapToSelf(p_geom,p_precision,p_snapTolerance);
    else
        return sdo_cs.transform(
                       &&defaultSchema..SC4O.ST_SnapToSelf(sdo_cs.transform(p_geom,p_srid),
                                                                 p_snapTolerance,
                                                                 p_precision),
                       p_geom.sdo_srid);
    end if;
  End ST_SnapToSelf;

  Function ST_Round(p_geom      in mdsys.sdo_geometry,
                    p_precision in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_Round(oracle.sql.STRUCT,int) return oracle.sql.STRUCT';

  /** =========================== Centroid Functions ======================== **/

  Function doCentroid(p_geom      in mdsys.sdo_geometry,
                      p_precision in number,
                      p_interior  in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_Centroid(oracle.sql.STRUCT,int,int) return oracle.sql.STRUCT';

  Function ST_Centroid(p_geom      in mdsys.sdo_geometry,
                       p_precision in number,
                       p_interior  in number default 1)
    Return mdsys.sdo_geometry
  As
  Begin
    return doCentroid(p_geom,p_precision,p_interior);
  End ST_Centroid;

  Function ST_ConvexHull(p_geom      in mdsys.sdo_geometry,
                         p_precision in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_ConvexHull(oracle.sql.STRUCT,int) return oracle.sql.STRUCT';

  /** =========================== Simplification Functions ======================== **/

  Function ST_DouglasPeuckerSimplify(p_geom              in mdsys.sdo_geometry,
                                     p_distanceTolerance in Number,
                                     p_precision         in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_DouglasPeuckerSimplifier(oracle.sql.STRUCT,double,int) return oracle.sql.STRUCT';

  Function ST_TopologyPreservingSimplify(p_geom              in mdsys.sdo_geometry,
                                         p_distanceTolerance in Number,
                                         p_precision         in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_TopologyPreservingSimplifier(oracle.sql.STRUCT,double,int) return oracle.sql.STRUCT';

  Function ST_VisvalingamWhyattSimplify(p_geom              in mdsys.sdo_geometry,
                                        p_distanceTolerance in Number,
                                        p_precision         in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_VisvalingamWhyattSimplifier(oracle.sql.STRUCT,double,int) return oracle.sql.STRUCT';

  /** ============================= Import / Export =====================================*/

  -- Import Text

  Function ST_GeomFromGML(p_gml in varchar2)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.JTS.ST_GeomFromGML(java.lang.String) return oracle.sql.STRUCT';

  Function ST_GeomFromEWKT(p_ewkt in CLOB)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.io.imp.wkt.EWKTImporter.ST_GeomFromEWKT(oracle.sql.CLOB) return oracle.sql.STRUCT';

  Function ST_GeomFromEWKT(p_ewkt in CLOB,
                           p_srid in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.io.imp.wkt.EWKTImporter.ST_GeomFromEWKT(oracle.sql.CLOB,int) return oracle.sql.STRUCT';

  Function ST_GeomFromEWKT(p_ewkt in varchar2)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.io.imp.wkt.EWKTImporter.ST_GeomFromEWKT(java.lang.String) return oracle.sql.STRUCT';

  Function ST_GeomFromEWKT(p_ewkt in varchar2,
                           p_srid in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.io.imp.wkt.EWKTImporter.ST_GeomFromEWKT(java.lang.String,int) return oracle.sql.STRUCT';

  Function ST_GeomFromText(p_wkt in CLOB)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.io.imp.wkt.EWKTImporter.ST_GeomFromText(oracle.sql.CLOB) return oracle.sql.STRUCT';

  Function ST_GeomFromText(p_wkt  in CLOB,
                           p_srid in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.io.imp.wkt.EWKTImporter.ST_GeomFromText(oracle.sql.CLOB,int) return oracle.sql.STRUCT';

  Function ST_GeomFromText(p_wkt in varchar2)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.io.imp.wkt.EWKTImporter.ST_GeomFromText(java.lang.String) return oracle.sql.STRUCT';

  Function ST_GeomFromText(p_wkt  in varchar2,
                           p_srid in number)
    Return mdsys.sdo_geometry
        As language java name
           'com.spdba.dbutils.io.imp.wkt.EWKTImporter.ST_GeomFromText(java.lang.String,int) return oracle.sql.STRUCT';

  -- Import Binary

  Function ST_GeomFromEWKB(p_ewkb in BLOB)
    Return mdsys.sdo_geometry
    As language java name
           'com.spdba.dbutils.io.imp.wkb.EWKBImporter.ST_GeomFromEWKB(oracle.sql.BLOB) return oracle.sql.STRUCT';

  Function ST_GeomFromEWKB(p_ewkb in BLOB,
                           p_srid in number)
    Return mdsys.sdo_geometry
    As language java name
           'com.spdba.dbutils.io.imp.wkb.EWKBImporter.ST_GeomFromEWKB(oracle.sql.BLOB, int) return oracle.sql.STRUCT';

  Function ST_GeomFromBinary(p_ewkb in BLOB)
    Return mdsys.sdo_geometry
    As language java name
           'com.spdba.dbutils.io.imp.wkb.EWKBImporter.ST_GeomFromEWKB(oracle.sql.BLOB) return oracle.sql.STRUCT';

  Function ST_GeomFromBinary(p_ewkb in BLOB,
                             p_srid in number)
    Return mdsys.sdo_geometry
    As language java name
           'com.spdba.dbutils.io.imp.wkb.EWKBImporter.ST_GeomFromEWKB(oracle.sql.BLOB, int) return oracle.sql.STRUCT';

  -- Output Text

  Function ST_AsGML(p_geom in sdo_geometry)
    Return CLOB
    As language java name
           'com.spdba.dbutils.JTS.ST_AsGML(oracle.sql.STRUCT) return oracle.sql.CLOB';

  Function ST_AsText(p_geom in sdo_geometry)
    Return CLOB
    As language java name
           'com.spdba.dbutils.io.exp.wkt.EWKTExporter.ST_AsText(oracle.sql.STRUCT) return oracle.sql.CLOB';

  Function ST_AsEWKT(p_geom in sdo_geometry)
    Return CLOB
    As language java name
           'com.spdba.dbutils.io.exp.wkt.EWKTExporter.ST_AsEWKT(oracle.sql.STRUCT) return oracle.sql.CLOB';

  -- Output Binary

  Function ST_AsBinary(p_geom in sdo_geometry)
    Return BLOB
    As language java name
           'com.spdba.dbutils.io.exp.wkb.EWKBExporter.ST_AsBinary(oracle.sql.STRUCT) return oracle.sql.BLOB';

  Function ST_AsBinary(p_geom in sdo_geometry, p_endian in varchar2)
    Return BLOB
    As language java name
           'com.spdba.dbutils.io.exp.wkb.EWKBExporter.ST_AsBinary(oracle.sql.STRUCT, java.lang.String) return oracle.sql.BLOB';

  Function ST_AsEWKB(p_geom in sdo_geometry)
    Return BLOB
    As language java name
           'com.spdba.dbutils.io.exp.wkb.EWKBExporter.ST_AsEWKB(oracle.sql.STRUCT) return oracle.sql.BLOB';

  Function ST_AsEWKB(p_geom in sdo_geometry, p_endian in varchar2)
    Return BLOB
    As language java name
           'com.spdba.dbutils.io.exp.wkb.EWKBExporter.ST_AsEWKB(oracle.sql.STRUCT, java.lang.String) return oracle.sql.BLOB';

END SC4O;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean      := true;
   v_obj_name varchar2(30) := 'SC4O';
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

grant execute on SC4O to public;

quit;


