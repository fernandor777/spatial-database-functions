DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

CREATE OR REPLACE TYPE &&INSTALL_SCHEMA..T_SEGMENT
AUTHID DEFINER
AS OBJECT (

  /****t* OBJECT TYPE/T_SEGMENT
  *  NAME
  *    T_SEGMENT -- Object type representing a single 2-point linestring or single 3 point circular arc.
  *  DESCRIPTION
  *    An object type that represents a single segment of a linestring.
  *    A segment is composed of a minimum of two T_VERTEX objects with Implied director (SEGMENT) from start to end.
  *    When a segment/segment contains a mid coordinate, that segment defines a circular arc.
  *    Includes Methods on that type.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/

  /****v* T_SEGMENT/ATTRIBUTES
  *  ATTRIBUTES
  *    element_id    -- Top level part identifier of multi-part geometry
  *                     eg multi-linestring composed of two lines generates element_ids 1 and 2.
  *    subelement_id -- Part id of any sub-elements of a single geometry part
  *                     eg inner ring of a single polygon; circular curve of single linestring.
  *    segment_id    -- Id of segments in sequential order appears in original geometry
  *    startCoord    -- Ordinates of start point
  *    midCoord      -- Ordinates of mid point of circular arc
  *    endCoord      -- Ordinates of end point
  *    sdo_gtype     -- Geometry Type of segment
  *    sdo_srid      -- Spatial Reference ID of segment
  *    projected      -- If planar then 1 else 0 
  *    precisionModel -- Holds precision information for object
  *  SOURCE
  */
  element_id     integer,
  subelement_id  integer,
  segment_Id     Integer,
  startCoord     &&INSTALL_SCHEMA..T_Vertex,
  midCoord       &&INSTALL_SCHEMA..T_Vertex, /* If circular arc */
  endCoord       &&INSTALL_SCHEMA..T_Vertex,
  sdo_gtype      integer,
  sdo_srid       integer,
  projected      integer,
  PrecisionModel &&INSTALL_SCHEMA..T_PrecisionModel,  /* Holds XYZM ordinate scale/precision values */
  /*******/

  /****m* T_SEGMENT/CONSTRUCTORS(T_SEGMENT)
  *  NAME
  *    A collection of T_SEGMENT Constructors.
  *  SOURCE
  */
  -- Useful as an "Empty" constructor.
  Constructor Function T_SEGMENT(SELF IN OUT NOCOPY T_SEGMENT)
                Return Self As Result,

  Constructor Function T_SEGMENT(SELF     IN OUT NOCOPY T_SEGMENT,
                                 p_segment in &&INSTALL_SCHEMA..T_SEGMENT)
                Return Self As Result,

  Constructor Function T_SEGMENT(SELF         IN OUT NOCOPY T_SEGMENT,
                                 p_line       in mdsys.sdo_geometry,
                                 p_segment_id in integer default 0,
                                 p_precision  in integer default 3,
                                 p_tolerance  in number default 0.005
                       )
                Return Self As Result,

  Constructor Function T_SEGMENT(SELF        IN OUT NOCOPY T_SEGMENT,
                                 p_sdo_gtype In Integer,
                                 p_sdo_srid  In Integer,
                                 p_projected in integer default 1,
                                 p_precision in integer default 3,
                                 p_tolerance in number  default 0.005)
                Return Self As Result,

  -- T_VERTEX Constructors
  Constructor Function T_SEGMENT(SELF         IN OUT NOCOPY T_SEGMENT,
                                 p_segment_id In Integer,
                                 p_startCoord In &&INSTALL_SCHEMA..T_Vertex,
                                 p_endCoord   In &&INSTALL_SCHEMA..T_Vertex,
                                 p_sdo_gtype  In Integer default null,
                                 p_sdo_srid   In Integer default null,
                                 p_projected  in integer default 1,
                                 p_precision  in integer default 3,
                                 p_tolerance  in number  default 0.005)
                Return Self As Result,

  Constructor Function T_SEGMENT(SELF         IN OUT NOCOPY T_SEGMENT,
                                 p_segment_id In Integer,
                                 p_startCoord In &&INSTALL_SCHEMA..T_Vertex,
                                 p_midCoord   In &&INSTALL_SCHEMA..T_Vertex,
                                 p_endCoord   In &&INSTALL_SCHEMA..T_Vertex,
                                 p_sdo_gtype  In Integer default null,
                                 p_sdo_srid   In Integer default null,
                                 p_projected  in integer default 1,
                                 p_precision  in integer default 3,
                                 p_tolerance  in number  default 0.005 )
                Return Self As Result,

  Constructor Function T_SEGMENT(SELF            IN OUT NOCOPY T_SEGMENT,
                                 p_element_id    In Integer,
                                 p_subelement_id In Integer,
                                 p_segment_id    In Integer,
                                 p_startCoord    In &&INSTALL_SCHEMA..T_Vertex,
                                 p_endCoord      In &&INSTALL_SCHEMA..T_Vertex,
                                 p_sdo_gtype     In Integer default null,
                                 p_sdo_srid      In Integer default null,
                                 p_projected     in integer default 1,
                                 p_precision     in integer default 3,
                                 p_tolerance     in number default 0.005)
                Return Self As Result,

  Constructor Function T_SEGMENT(SELF            IN OUT NOCOPY T_SEGMENT,
                                 p_element_id    In Integer,
                                 p_subelement_id In Integer,
                                 p_segment_id    In Integer,
                                 p_startCoord    In &&INSTALL_SCHEMA..T_Vertex,
                                 p_midCoord      In &&INSTALL_SCHEMA..T_Vertex,
                                 p_endCoord      In &&INSTALL_SCHEMA..T_Vertex,
                                 p_sdo_gtype     In Integer default null,
                                 p_sdo_srid      In Integer default null,
                                 p_projected     in integer default 1,
                                 p_precision     in integer default 3,
                                 p_tolerance     in number default 0.005)
                Return Self As Result,

  -- MDSYS.VERTEX_TYPE Constructors
  Constructor Function T_SEGMENT(SELF         IN OUT NOCOPY T_SEGMENT,
                                 p_segment_id In Integer,
                                 p_startCoord In mdsys.vertex_type,
                                 p_endCoord   In mdsys.vertex_type,
                                 p_sdo_gtype  In Integer default null,
                                 p_sdo_srid   In Integer default null,
                                 p_projected  in integer default 1,
                                 p_precision  in integer default 3,
                                 p_tolerance  in number default 0.005
                        )
                Return Self As Result,

  Constructor Function T_SEGMENT(SELF         IN OUT NOCOPY T_SEGMENT,
                                 p_segment_id In Integer,
                                 p_startCoord In mdsys.vertex_type,
                                 p_midCoord   In mdsys.vertex_type,
                                 p_endCoord   In mdsys.vertex_type,
                                 p_sdo_gtype  In Integer default null,
                                 p_sdo_srid   In Integer default null,
                                 p_projected  in integer default 1,
                                 p_precision  in integer default 3,
                                 p_tolerance  in number  default 0.005)
                Return Self As Result,
  /*******/

  /* ******************* Member Methods ************************ */

  /****m* T_SEGMENT/ST_GetProjected
  *  NAME
  *    ST_getProjected -- Rerturns whether underlying segment is planar/projected (1) or geographic/geodetic (0).
  *  SYNOPSIS
  *    Static Function ST_GetProjection
  *             Return integer deterministic,
  *  DESCRIPTION
  *    This function can be used to discover whether the underlying SRID is projeccted/planar or not.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Static Function ST_GetProjected(p_srid in integer default null)
          Return integer deterministic,

  /****m* T_SEGMENT/ST_SetPrecisionModel
  *  NAME
  *    ST_SetPrecisionModel -- Allows user to set object's t_precision object.
  *  SYNOPSIS
  *    Member Procedure ST_SetPrecisionModel(SELF IN OUT NOCOPY T_SEGMENT,
  *                                          p_precision &&INSTALL_SCHEMA..T_PrecisionModel),
  *  DESCRIPTION
  *    This procedure allows a user to set the object's precision values in its t_precision object.
  *    If a NULL value is provided for a precision object element, the existing value is maintained.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2019 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Procedure ST_SetPrecisionModel(SELF IN OUT NOCOPY T_SEGMENT,
                                        p_PrecisionModel in &&INSTALL_SCHEMA..T_PrecisionModel),

 /****m* T_SEGMENT/ST_MBR
  *  NAME
  *    ST_MBR - Returns optimized rectangle sdo_geometry representnig the underlying segment's minimum bounding rectangle (MBR).
  *  SYNOPSIS
  *    Member Function ST_MBR
  *             Return SDO_GEOMETRY Determinsitic
  *  EXAMPLE
  *    select T_Segment(sdo_geometry('LINESTRING(0 0,0.8 0.8)',NULL)).ST_MBR() as mbrGeom
  *      from dual;
  *
  *    MBRGEOM
  *    --------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3),SDO_ORDINATE_ARRAY(0,0,0.8,0.8))
  *  DESCRIPTION
  *    Supplied with a non-NULL segment, this function returns the envelope or minimum bounding rectangle as a polygon geometry with one optimized rectangle exterior ring.
  *  RESULT
  *    MBR Geometry (sdo_geometry) -- Single Polygon with Optimized Rectangle Exterior Ring.
  *  SEE ALSO
  *    T_MBR object.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2011 - Converted to T_GEOMETRY from GEOM package.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_MBR  return mdsys.sdo_geometry deterministic,

 /****m* T_SEGMENT/ST_MinX
  *  NAME
  *    ST_MinX - Returns the smallest X ordinate value from the underlying segments minimum bounding rectangle (MBR).
  *  SYNOPSIS
  *    Member Function ST_MinX
  *             Return SDO_GEOMETRY Determinsitic
  *  DESCRIPTION
  *    Supplied with a non-NULL segment, this function returns the smallest X ordinate value held by the startCoord,midCoord or endCoord vertices.
  *  RESULT
  *    ordinate (number) -- Smallest
  *  EXAMPLE
  *    select T_Segment(sdo_geometry('LINESTRING(0 0,0.8 0.8)',NULL)).ST_MinX() as minX
  *      from dual;
  *
  *    MINX
  *    ----
  *       0
  *  SEE ALSO
  *    T_MBR object.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2011 - Original coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_MinX return Number deterministic,

 /****m* T_SEGMENT/ST_MaxX
  *  NAME
  *    ST_MaxX - Returns the largest X ordinate value from the underlying segments minimum bounding rectangle (MBR).
  *  SYNOPSIS
  *    Member Function ST_MaxX
  *             Return SDO_GEOMETRY Determinsitic
  *  DESCRIPTION
  *    Supplied with a non-NULL segment, this function returns the largest X ordinate value held by the startCoord,midCoord or endCoord vertices.
  *  RESULT
  *    ordinate (number) -- Largest x ordinate value
  *  EXAMPLE
  *    select T_Segment(sdo_geometry('LINESTRING(0 0,0.8 0.8)',NULL)).ST_MaxX() as maxX
  *      from dual;
  *
  *    MAXX
  *    ----
  *     0.8
  *  SEE ALSO
  *    T_MBR object.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2011 - Original coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_MaxX return Number deterministic,

 /****m* T_SEGMENT/ST_MinY
  *  NAME
  *    ST_MinY - Returns the smallest Y ordinate value from the underlying segments minimum bounding rectangle (MBR).
  *  SYNOPSIS
  *    Member Function ST_MinY
  *             Return SDO_GEOMETRY Determinsitic
  *  DESCRIPTION
  *    Supplied with a non-NULL segment, this function returns the smallest Y ordinate value held by the startCoord,midCoord or endCoord vertices.
  *  RESULT
  *    ordinate (number) -- Smallest
  *  EXAMPLE
  *    select T_Segment(sdo_geometry('LINESTRING(0 0,0.8 0.8)',NULL)).ST_MinY() as minX
  *      from dual;
  *
  *    MINY
  *    ----
  *       0
  *  SEE ALSO
  *    T_MBR object.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2011 - Original coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_MinY return Number deterministic,

 /****m* T_SEGMENT/ST_MaxY
  *  NAME
  *    ST_MaxY - Returns the largest Y ordinate value from the underlying segments minimum bounding rectangle (MBR).
  *  SYNOPSIS
  *    Member Function ST_MaxY
  *             Return SDO_GEOMETRY Determinsitic
  *  DESCRIPTION
  *    Supplied with a non-NULL segment, this function returns the largest Y ordinate value held by the startCoord,midCoord or endCoord vertices.
  *  RESULT
  *    ordinate (number) -- Largest x ordinate value
  *  EXAMPLE
  *    select T_Segment(sdo_geometry('LINESTRING(0 0,0.8 0.8)',NULL)).ST_MaxY() as maxX
  *      from dual;
  *
  *    MAXX
  *    ----
  *     0.8
  *  SEE ALSO
  *    T_MBR object.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2011 - Original coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_MaxY return Number deterministic,

 /****m* T_SEGMENT/ST_isHorizontal
  *  NAME
  *    ST_isHorizontal - Returns true if the segment is horizonal or parallel to X axis.
  *  SYNOPSIS
  *    Member Function ST_isHorizontal
  *             Return integer Determinsitic
  *  DESCRIPTION
  *    Supplied with a non-NULL segment, this function checks if segment is horizontal or parallel to X axis
  *  RESULT
  *    true/false (integer) -- 1 is horizontal 0 otherwise
  *  EXAMPLE
  *    select T_Segment(sdo_geometry('LINESTRING(0 0,10 0)',NULL)).ST_isHorizontal() as isHorizontal
  *      from dual;
  *
  *    ISHORIZONTAL
  *    ------------
  *               1
  *    
  *    select T_Segment(sdo_geometry('LINESTRING(0 0,10 10)',NULL)).ST_isHorizontal() as isHorizontal
  *      from dual;
  *      
  *    ISHORIZONTAL
  *    ------------
  *               0
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 - Original coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_isHorizontal
           return integer deterministic,
           
 /****m* T_SEGMENT/ST_isVertical
  *  NAME
  *    ST_isVertical - Returns true if the segment is Vertical or parallel to Y axis.
  *  SYNOPSIS
  *    Member Function ST_isVertical
  *             Return integer Determinsitic
  *  DESCRIPTION
  *    Supplied with a non-NULL segment, this function checks if segment is vertical or parallel to Y axis
  *  RESULT
  *    true/false (integer) -- 1 is Vertical 0 otherwise
  *  EXAMPLE
  *    select T_Segment(sdo_geometry('LINESTRING(0 0,0 10)',NULL)).ST_isVertical() as isVertical
  *      from dual;
  *
  *    ISVERTICAL
  *    ----------
  *             1
  *    
  *    select T_Segment(sdo_geometry('LINESTRING(0 0,10 10)',NULL)).ST_isVertical() as isVertical
  *      from dual;
  *      
  *    ISVERTICAL
  *    ----------
  *             0
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 - Original coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_isVertical
           return integer deterministic,

 /****m* T_SEGMENT/ST_MidPoint
  *  NAME
  *    ST_MidPoint - Computes, and returns, the midpoint of the segment
  *  SYNOPSIS
  *    Member Function ST_MidPoint
  *             Return t_vertex Determinsitic
  *  DESCRIPTION
  *    Supplied with a non-NULL segment, this function computes and returns its mid Point.
  *    If CircularArc, mid point is point at mid length distance from start.
  *  RESULT
  *    point (t_vertex) -- The midpoint of the segment
  *  EXAMPLE
  *    select &&INSTALL_SCHEMA..T_Segment(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,1,1)))
  *                .ST_midPoint() 
  *                .ST_SdoGeometry() as mPoint
  *      from dual;
  *               
  *    
  *    MPOINT
  *    --------------------------------------------------------------------
  *    SDO_GEOMETRY(2001, NULL, SDO_POINT_TYPE(0.5, 0.5, NULL), NULL, NULL)
  *    
  *    
  *    select &&INSTALL_SCHEMA..T_Segment(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,2),sdo_ordinate_array(0,0,10,10,20,0)))
  *                .ST_midPoint()
  *                .ST_SdoGeometry() as mPoint
  *      from dual;
  *    
  *    MPOINT
  *    ------------------------------------------------------------------
  *    SDO_GEOMETRY(2001, NULL, SDO_POINT_TYPE(10, 10, NULL), NULL, NULL)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 - Original coding
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_MidPoint
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

  /****m* T_SEGMENT/ST_SetCoordinates(vertex vertex vertex)
  *  NAME
  *    ST_SetCoordinates -- Allows user to set a segment's start/mid/end coordinates
  *  SYNOPSIS
  *    Member Procedure ST_SetCoordinates(SELF IN OUT NOCOPY T_SEGMENT,
  *                         p_startCoord in &&INSTALL_SCHEMA..T_VERTEX,
  *                         p_midCoord   in &&INSTALL_SCHEMA..T_VERTEX,
  *                         p_endCoord   in &&INSTALL_SCHEMA..T_VERTEX),
  *  DESCRIPTION
  *    This procedure allows a user to set a segment's coordinates without creating a new segment.
  *    If a NULL value is provided for the midCoord parameter its associated coordinate will be set to NULL.
  *    If a NULL value is provided for the startCoord or endCoord it is ignored as it would otherwise invalidate the object.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2019 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Procedure ST_SetCoordinates(SELF         IN OUT NOCOPY T_SEGMENT,
                                     p_startCoord in &&INSTALL_SCHEMA..T_VERTEX,
                                     p_midCoord   in &&INSTALL_SCHEMA..T_VERTEX,
                                     p_endCoord   in &&INSTALL_SCHEMA..T_VERTEX),

  /****m* T_SEGMENT/ST_SetCoordinates(vertex vertex)
  *  NAME
  *    ST_SetCoordinates -- Allows user to set object's start or end coordinates.
  *  SYNOPSIS
  *    Member Procedure ST_SetCoordinates(SELF IN OUT NOCOPY T_SEGMENT,
  *                         p_startCoord in &&INSTALL_SCHEMA..T_VERTEX,
  *                         p_endCoord   in &&INSTALL_SCHEMA..T_VERTEX),
  *  DESCRIPTION
  *    This procedure allows a user to set a segment's coordinates without creating a new segment.
  *    If a NULL value is provided for a parameter it is ignored as it would otherwise invalidate the object.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2019 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Procedure ST_SetCoordinates(SELF         IN OUT NOCOPY T_SEGMENT,
                                     p_startCoord in &&INSTALL_SCHEMA..T_VERTEX,
                                     p_endCoord   in &&INSTALL_SCHEMA..T_VERTEX),

  /****m* T_SEGMENT/ST_Self
  *  NAME
  *    ST_Self -- Handy method for use with TABLE(T_Segments) to return element as T_Segment object.
  *  SYNOPSIS
  *    Member Function ST_Self
  *             Return T_Segment Deterministic,
  *  DESCRIPTION
  *    When segmentizing linear geometries into T_Segment objects via a TABLE function call to T_GEOMETRY.T_SEGMENTIZE()
  *    it is handy to have a method which allows access to the result as a single object.
  *    In a sense this method allows access similar to t.COLUMN_VALUE for atmoic datatype access from TABLE functions.
  *  RESULT
  *    segment (T_SEGMENT) -- A single T_Segment object.
  *  EXAMPLE
  *    set serveroutput on
  *    BEGIN
  *      FOR rec IN (select seg.segment_id, seg.ST_Self() as line
  *                    from table(t_geometry(
  *                                 SDO_GEOMETRY(2002,28355,NULL,
  *                                     SDO_ELEM_INFO_ARRAY(1,2,1),
  *                                     SDO_ORDINATE_ARRAY(252282.861,5526962.496,252282.861,5526882.82, 252315.91,5526905.639, 252287.189,5526942.228)) )
  *                               .ST_Segmentize('ALL')) seg
  *                  )
  *      LOOP
  *        dbms_output.put_line(rec.line.ST_AsText());
  *      END LOOP;
  *    END;
  *    /
  *    anonymous block completed
  *    SEGMENT(1,1,1,Start(1,252282.861,5526962.496,NULL,NULL,2001,28355),End(2,252282.861,5526882.82,NULL,NULL,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *    SEGMENT(1,1,2,Start(2,252282.861,5526882.82,NULL,NULL,2001,28355),End(3,252315.91,5526905.639,NULL,NULL,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *    SEGMENT(1,1,3,Start(3,252315.91,5526905.639,NULL,NULL,2001,28355),End(4,252287.189,5526942.228,NULL,NULL,2001,28355),SDO_GTYPE=2002,SDO_SRID=28355)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Self
           Return &&INSTALL_SCHEMA..T_SEGMENT Deterministic,

  /****m* T_SEGMENT/ST_isEmpty
  *  NAME
  *    ST_isEmpty -- Checks if segment has any valid data.
  *  SYNOPSIS
  *    Member Function ST_isEmpty
  *             Return INTEGER Deterministic,
  *  DESCRIPTION
  *    If segment object data values are NULL returns 1 (TRUE) ie is Empty; else 0 (False)
  *    cf "LINESTRING EMPTY" EKT.
  *  RESULT
  *    BOOLEAN (INTEGER) -- 1 if segment has no non null values; 0 if has values
  *  EXAMPLE
  *    select T_Segment().ST_AsText()  as TSegment,
  *           T_Segment().ST_isEmpty() as isEmpty
  *      from dual;
  *
  *    TSEGMENT
  *    -------------------------------------------------------------------------------------------------------------------------------------- --------
  *    SEGMENT(NULL,NULL,NULL,Start(NULL,NULL,NULL,NULL,NULL,2001,NULL),End(NULL,NULL,NULL,NULL,NULL,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)        0
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_isEmpty
           Return integer Deterministic,

  /****m* T_SEGMENT/ST_CheckZ
  *  NAME
  *    ST_CheckZ -- Checks Z values on linString or CircularArc
  *  SYNOPSIS
  *    Member Function ST_CheckZ
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    The circularArc mathematics are considered to be 2D; 
  *    If a circularArc coordinate contains a Z ordinate, then its value has to be the same for all coordinates to remain in the same plane;
  *    If the segment is a lineString, its Z values don't need checking;.
  *  RESULT
  *    BOOLEAN (INTEGER) -- 1 if segment's Z ordinates pass checking.
  *  NOTES
  *    See also t_segment constructors that take a valid midCoord t_vertex parameter value.
  *    Where ST_CheckZ fails for a t_segment constructor, the error message is the same as for SQL Server Spatial.
  *  EXAMPLE
  *    -- Check ST_CheckZ for valid planar circularArc segment
  *    select T_Segment(
  *             SDO_GEOMETRY(3002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(252230.478,5526918.373,1.0, 252400.08,5526918.373,1.0, 252230.478,5527000.0,1.0))
  *           ).ST_CheckZ() as tsegment 
  *      from dual;
  *
  *      TSEGMENT
  *    ----------
  *             1
  *
  *    -- Test ST_CheckZ built in to circularArc segment constructors 
  *    select T_Segment(
  *             SDO_GEOMETRY(3002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(252230.478,5526918.373,2.0, 252400.08,5526918.373,2.5, 252230.478,5527000.0,3.0))
  *           ) as tsegment 
  *      from dual;
  *
  *    Error starting at line 129 in command:
  *    select T_Segment(SDO_GEOMETRY(3002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(252230.478,5526918.373,2.0, 252400.08,5526918.373,2.5, 252230.478,5527000.0,3.0)))
  *             as geom from dual
  *    Error report:
  *    SQL Error: ORA-20214: Circular arc segments with Z values must have equal Z value for all 3 points.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_CheckZ
           return integer deterministic,

  /****m* T_SEGMENT/ST_isCircularArc
  *  NAME
  *    ST_isCircularArc -- Checks if segment is a CircularArc
  *  SYNOPSIS
  *    Member Function ST_isCircularArc
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    If segment start/mid/end coordinates are all not null then is CircularString.
  *  RESULT
  *    BOOLEAN (INTEGER) -- 1 if segment is CircularArc.
  *  EXAMPLE
  *    with data as (
  *      select T_Segment(
  *               SDO_GEOMETRY('CIRCULARSTRING(252230.478 5526918.373, 252400.08 5526918.373, 252230.478 5527000.0)',null)
  *             ) as circular_segment
  *        from dual
  *    )
  *    select a.circular_segment.ST_isCircularArc() as isCString
  *      from data a;
  *
  *    ISCSTRING
  *    ---------
  *            1
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_isCircularArc
           Return integer Deterministic,

  /****m* T_SEGMENT/ST_Dims
  *  NAME
  *    ST_Dims -- Returns number of ordinate dimensions
  *  SYNOPSIS
  *    Member Function ST_Dims
  *             Return INTEGER Deterministic,
  *  DESCRIPTION
  *    Examines SDO_GTYPE (2XXX etc) and extracts coordinate dimensions.
  *    If SDO_GTYPE is null, examines ordinates eg XY not null, Z null -> 2.
  *  RESULT
  *    BOOLEAN (INTEGER) -- 2 if data 2D; 3 if 3D; 4 if 4D
  *  EXAMPLE
  *    with data as (
  *      select T_Segment(
  *               SDO_GEOMETRY('CIRCULARSTRING(252230.478 5526918.373, 252400.08 5526918.373, 252230.478 5527000.0)',28355)
  *             ) as circular_segment
  *        from dual
  *    )
  *    select a.circular_segment.ST_Dims() as Dims
  *      from data a;
  *
  *    DIMS
  *    ----
  *       2
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Dims
           Return integer Deterministic,

  /****m* T_SEGMENT/ST_SRID
  *  NAME
  *    ST_SRID -- Returns the object's SDO_SRID attribute value.
  *  SYNOPSIS
  *    Member Function ST_SRID
  *             Return INTEGER Deterministic,
  *  DESCRIPTION
  *    Returns sdo_srid object attribute.
  *  RESULT
  *    spatial reference id (INTEGER) -- eg 8311 etc.
  *  EXAMPLE
  *    with data as (
  *      select T_Segment(
  *               SDO_GEOMETRY('CIRCULARSTRING(252230.478 5526918.373, 252400.08 5526918.373, 252230.478 5527000.0)',28355)
  *             ) as circular_segment
  *        from dual
  *    )
  *    select a.circular_segment.ST_Srid() as Srid
  *      from data a;
  *
  *     SRID
  *    -----
  *    28355
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_SRID
           Return integer Deterministic,

  /****m* T_SEGMENT/ST_hasZ
  *  NAME
  *    ST_hasZ -- Tests segment to see if coordinates include a Z ordinate.
  *  SYNOPSIS
  *    Member Function ST_hasZ
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    Examines SDO_GTYPE (DLNN etc). If D position is 2 then segment does not have a Z ordinate.
  *    If D position is 3 and measure ordinate position (L) is 0 then segment has Z ordinate.
  *    If D position is 3 and measure ordinate position (L) is not equal to 0 then segment does not have a Z ordinate.
  *    If D position is 4 and measure ordinate position (L) is equal to 0 or equal to D (4) then segment has a Z ordinate.
  *    If D position is 4 and measure ordinate position (L) is equal to 3 then segment does not have a Z ordinate.
  *    If SDO_GTYPE is null, examines Z and W ordinates of the segment's coordinates to determine if segment has Z ordinate.
  *  RESULT
  *    BOOLEAN (INTEGER) -- 1 means segment has Z ordinate, 0 otherwise.
  *  EXAMPLE
  *    select T_Segment(sdo_geometry(3002,4283,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(147.5, -42.5,10.0, 147.6, -42.5, 10.0))).ST_hasZ() as hasZ
  *      from dual;
  *
  *    HASZ
  *    ----
  *       1
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_hasZ
           Return integer Deterministic,

  /****m* T_SEGMENT/ST_hasM
  *  NAME
  *    ST_hasM -- Tests segment to see if coordinates include a measure.
  *  SYNOPSIS
  *    Member Function ST_hasM
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    Examines SDO_GTYPE (DLNN etc) to see if sdo_gtype has measure ordinate eg 3302 not 3002.
  *    If SDO_GTYPE is null, examines coordinates to see if W ordinate is not null.
  *  RESULT
  *    BOOLEAN (INTEGER) -- 1 means segment has measure ordinate, 0 otherwise.
  *  EXAMPLE
  *    select T_Segment(sdo_geometry(3302,4283,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(147.5, -42.5,0.0, 147.6, -42.5, 10923.0))).ST_hasM() as hasM
  *      from dual;
  *
  *    HASM
  *    ----
  *       1
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_hasM
           Return integer Deterministic,

  /****m* T_SEGMENT/ST_Angle
  *  NAME
  *    ST_Angle -- Computes the angle that the vector defined by this segment makes with the X-axis.
  *  SYNOPSIS
  *      Member Function ST_Angle
  *               Return number Deterministic,
  *  DESCRIPTION
  *    Computes the angle that the vector defined by this segment makes with the X-axis.
  *    The angle will be in the range [ -PI, PI ] radians.
  *  RESULT
  *    angle (Number) -- The angle this segment makes with the X-axis (in radians)
  *  EXAMPLE
  *    -- Simple angle 
  *    select round(
  *            T_Segment(
  *              sdo_geometry('LINESTRING(0 0,10 10)',null)
  *            ).ST_Angle(),
  *            3
  *           ) as angle
  *      from dual;
  *
  *         ANGLE
  *    ----------
  *          .785
  *  SEE ALSO
  *    T_SEGMENT.ST_Bearing
  *    COGO.ST_Degrees
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Angle
           return number Deterministic,

  /****m* T_SEGMENT/ST_Bearing
  *  NAME
  *    ST_Bearing -- Returns Bearing, in degrees, from start to end (possibly normalized to 0..360 degree range.
  *  SYNOPSIS
  *    Member Function ST_Bearing(p_normalize in integer default 1)
  *             Return Number Deterministic
  *  DESCRIPTION
  *    This function computes a bearing from the current object point's startCoord to its EndCoord.
  *    ST_Bearing returns a whole circle bearing in range 0..360 is normalize flag is set.
  *  ARGUMENTS
  *    p_normalize (integer) -- 1 is normalise bearing to 0..360 degree range, 0 leave as calculated
  *  RESULT
  *    bearing (Number) -- Bearing in Degrees.
  *  EXAMPLE
  *    -- Simple bearing for projected data
  *    select round(
  *             T_Segment(
  *                sdo_geometry('LINESTRING(0 0,10 10)',null)
  *              ).ST_Bearing(
  *              ),3) as bearing
  *      from dual;
  *
  *    BEARING
  *    -------
  *         45
  *
  *    -- Simple geodetic bearing (2D)
  *    select COGO.DD2DMS(
  *             T_Segment(
  *               sdo_geometry(2002,4283,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(147.5,-42.5, 147.6,-42.5))
  *              ).ST_Bearing(
  *              )) as bearing
  *      from dual;
  *
  *    BEARING
  *    -----------
  *    90°2'1.606"
  *  SEE ALSO
  *    T_VERTEX.ST_Bearing
  *    COGO.ST_Degrees
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Bearing(p_normalize in integer default 1)
           Return Number Deterministic,

  /****m* T_SEGMENT/ST_Length
  *  NAME
  *    ST_Length -- Returns Length of the segment
  *  SYNOPSIS
  *    Member Function ST_Length(p_unit      in varchar2 DEFAULT NULL)
  *             Return Number Deterministic
  *  DESCRIPTION
  *    This function computes a length from the underlying T_SEGMENT.
  *    Result is in the distance units of the SDO_SRID, or in p_units where supplied.
  *  ARGUMENTS
  *    p_unit      (VARCHAR2) - Oracle Unit of Measure eg unit=M.
  *  RESULT
  *    distance (Number) -- Distance in SRID unit of measure or in supplied units (p_unit)
  *  EXAMPLE
  *    TO DO
  *    -- Simple length for mixed planar and geodetic data
  *    with data as (
  *      select 'Planar LineString' as test, sdo_geometry('LINESTRING(0 0,10 10)',null) as geom
  *        from dual
  *        union all
  *      select 'Geo LineString' as test, sdo_geometry('LINESTRING(147.50 -43.132,147.41 -43.387)',4326) as geom
  *        from dual
  *       union all
  *       select 'Planar CircularString' as test,
  *             SDO_GEOMETRY(2002,28355,NULL,
  *                          SDO_ELEM_INFO_ARRAY(1,2,2), -- Circular Arc line string
  *                          SDO_ORDINATE_ARRAY(252230.478,5526918.373, 252400.08,5526918.373,252230.478,5527000.0)) as geom
  *        from dual
  *    )
  *    select a.test,
  *           T_Segment(a.geom).ST_Length(p_unit=>NULL)      as l_in_meters,
  *           T_Segment(a.geom).ST_Length(p_unit=>'unit=KM') as l_in_km
  *      from data a;
  *
  *    TEST                  L_IN_METERS    L_IN_KM
  *    --------------------- ----------- ----------
  *    Planar LineString     14.14213562 14.14213562
  *    Geo LineString        29257.27111 29.25727111
  *    Planar CircularString 506.8892138 0.5068892138
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Length(p_unit      in varchar2 default NULL)
           Return number Deterministic,

  /****m* T_SEGMENT/ST_LRS_Dim
  *  NAME
  *    ST_LRS_Dim -- Tests segment to see if coordinates include a measure ordinate and returns measure ordinate's position.
  *  SYNOPSIS
  *    Member Function ST_LRS_Dim
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    Examines SDO_GTYPE (DLNN etc) measure ordinate position (L) and returns it.
  *    If SDO_GTYPE is null, examines coordinates to see if W ordinate is not null.
  *  RESULT
  *    dimension (integer) -- L from DLNN.
  *  EXAMPLE
  *    select T_Segment(sdo_geometry(3302,4283,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(147.5, -42.5,0.0, 147.6, -42.5, 10923.0))).ST_LRS_Dim() as lrs_dim
  *      from dual;
  *
  *    LRS_DIM
  *    -------
  *          3
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Dim
           Return Integer Deterministic,

  /****m* T_SEGMENT/ST_LRS_isMeasured
  *  NAME
  *    ST_LRS_isMeasured -- Tests to see if segment is measured.
  *  SYNOPSIS
  *    Member Function ST_LRS_isMeasured
  *             Return Integer Deterministic,
  *    With data as (
  *      Select T_GEOMETRY(sdo_geometry('LINESTRING(0 0,10 0,10 5,10 10,5 10,5 5)',null),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,3,1) as tgeom From Dual UNION ALL
  *      Select T_GEOMETRY(sdo_geometry(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,1,10,0,2,10,5,3,10,10,4,5,10,5,5,5,6)),0.005,3,1) as tgeom From Dual
  *    )
  *    select a.tgeom.ST_GType()          as sdo_gtype,
  *           a.tgeom.ST_LRS_isMeasured() as isMeasured
  *      from data a;
  *
  *    SDO_GTYPE GEOMTYPE       COORDDIM isMeasured
  *    --------- -------------- -------- ----------
  *            2 ST_LINESTRING         2          0
  *            2 ST_LINESTRING         3          0
  *            2 ST_LINESTRING         3          1
  *  DESCRIPTION
  *    Examines SDO_GTYPE (ST_LRS_Dim) to see if sdo_gtype has measure ordinate eg 3302 not 3002.
  *  RESULT
  *    BOOLEAN (Integer) -- 1 is measure ordinate exists, 0 otherwise.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_isMeasured
           Return Integer Deterministic,

  /****m* T_SEGMENT/ST_LRS_Measure_Length
  *  NAME
  *    ST_LRS_Measure_Length -- Returns difference between end measure and start measure of segment.
  *  SYNOPSIS
  *    Member Function ST_LRS_Measure_Length( p_unit IN VARCHAR2 Default NULL )
  *             Return Number Deterministic
  *  DESCRIPTION
  *    This function computes length by subtracting end and start measure ordinates.
  *    If segment is without measures length is returned.
  *  RESULT
  *    distance (Number) -- Difference between end and start measure ordinates (delta) or segment length.
  *  EXAMPLE
  *    with data as (
  *      select 'Planar LineString' as test,
  *             sdo_geometry(3302,NULL,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,1.1,6,6,5.95)) as geom
  *        from dual
  *        union all
  *       select 'Geo LineString' as test,
  *             sdo_geometry(3302,4326,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(147.50,-43.132,100.0,147.41,-43.387,30000.0)) as geom
  *        from dual
  *    )
  *    select a.test,
  *           T_Segment(a.geom)
  *             .ST_LRS_Measure_Length() as measureLength
  *      from data a;
  *
  *    TEST              MEASURELENGTH
  *    ----------------- -------------
  *    Planar LineString          4.85
  *    Geo LineString            29900
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Measure_Length( p_unit IN VARCHAR2 Default NULL )
           Return number Deterministic,

  /****m* T_SEGMENT/ST_LRS_Add_Measure
  *  NAME
  *    ST_LRS_Add_Measure -- Adds measures to 2D segment linestring/circularString
  *  SYNOPSIS
  *    Member Function ST_LRS_Add_Measure(p_start_measure IN Number Default NULL,
  *                                       p_end_measure   IN Number Default NULL,
  *                                       p_unit          IN VarChar2 Default NULL)
  *             Return &&INSTALL_SCHEMA..T_Segment deterministic,
  *  DESCRIPTION
  *    Takes a 2D geometry and assigns supplied measures to the start/end vertices
  *    and adds proportioned measure values to all vertices in between.
  *    If p_start_measure/p_end_measure are null, length is used to add measures.
  *  ARGUMENTS
  *    p_start_measure (Number)   - Measure defining start point for segment .
  *    p_end_measure   (Number)   - Measure defining end point for segment.
  *    p_unit          (VarChar2) - Unit of measure for distance calculations.
  *  RESULT
  *    segment (T_segment) -- Measured segment
  *  EXAMPLE
  *    select t_geometry(SDO_GEOMETRY(2002,28355,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,2,1),
  *                 SDO_ORDINATE_ARRAY(
  *                    571303.231,321126.963, 571551.298,321231.412, 572765.519,321322.805, 572739.407,321845.051,
  *                    572752.463,322641.476, 573209.428,323398.732, 573796.954,323555.406, 574436.705,323790.416,
  *                    574945.895,324051.539, 575128.681,324652.122, 575128.681,325161.311, 575898.993,325213.536,
  *                    576238.453,324521.56, 576251.509,321048.626, 575259.242,322615.364, 574306.144,321296.693)),
  *                    0.0005,3,1)
  *             .ST_LRS_ADD_Measure(110.0)
  *             .ST_Round(3,3,1,2)
  *             .geom as mGeom
  *      from dual;
  *
  *    MGEOM
  *    ---------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3302,28355,NULL,
  *                 SDO_ELEM_INFO_ARRAY(1,2,1),
  *                 SDO_ORDINATE_ARRAY(
  *                     571303.231,321126.963,110.0,   571551.298,321231.412,377.21,   572765.519,321322.805,1586.05,  572739.407,321845.051,2105.16,
  *                     572752.463,322641.476,2895.92, 573209.428,323398.732,3773.96,  573796.954,323555.406,4377.62,  574436.705,323790.416,5054.23,
  *                     574945.895,324051.539,5622.33, 575128.681,324652.122,6245.56,  575128.681,325161.311,6751.06,  575898.993,325213.536,7517.55,
  *                     576238.453,324521.56,8282.72,  576251.509,321048.626,11730.53, 575259.242,322615.364,13571.62, 574306.144,321296.693,15186.88))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 - Original Coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Add_Measure(p_start_measure IN NUMBER Default NULL,
                                     p_end_measure   IN NUMBER Default NULL,
                                     p_unit          IN VARCHAR2 Default NULL)
           Return &&INSTALL_SCHEMA..t_segment deterministic,

  /****m* T_SEGMENT/ST_LRS_Compute_Measure
  *  NAME
  *    ST_LRS_Compute_Measure -- Computes measure for supplied p_vertex against underlying LRS measured T_SEGMENT.
  *  SYNOPSIS
  *    Member Function ST_LRS_Compute_Measure(p_vertex    In &&INSTALL_SCHEMA..T_Vertex,
  *                                           p_unit      IN varchar2 Default null)
  *             Return Number Deterministic
  *  DESCRIPTION
  *    This function computes a measure value for the supplied point (must be a point
  *    on the underlying segment). All calculations are done on 2D versions of segment
  *    and point.
  *  ARGUMENTS
  *    p_vertex  (T_VERTEX) - Finds p_vertex on LRS Segment and computes M ordinate
  *    p_unit    (VARCHAR2) - Oracle Unit of Measure eg unit=M.
  *  RESULT
  *    -- Compute measure of point
  *    with data as (
  *      select 'Planar LineString' as test,
  *             sdo_geometry(3302,NULL,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,1.1,6,6,5.95)) as geom,
  *             sdo_geometry('POINT(5 4.9)',null) as dGeom
  *        from dual
  *        union all
  *       select 'Geo LineString' as test,
  *             sdo_geometry(3302,4326,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(147.50,-43.132,100.0,147.41,-43.387,30000.0)) as geom,
  *             sdo_geometry('POINT(147.3 -43.2)',4326) as dGeom
  *        from dual
  *    )
  *    select a.test,
  *           T_Segment(a.geom).ST_LRS_Compute_Measure(p_vertex=>T_VERTEX(a.dGeom),p_unit=>NULL) as measure
  *      from data a;
  *
  *    TEST              MEASURE
  *    ----------------- ----------
  *    Planar LineString 4.93180695
  *    Geo LineString     18427.043
  *  TODO
  *    Support CircularString (Circular Arcs).
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Compute_Measure(p_vertex    In &&INSTALL_SCHEMA..T_Vertex,
                                         p_unit      IN varchar2 Default null)
           Return number Deterministic,

  /****m* T_SEGMENT/ST_Reverse
  *  NAME
  *    ST_Reverse -- Reverses underlying segment's start and end coordinates.
  *  SYNOPSIS
  *    Member Function ST_Reverse
  *             Return &&INSTALL_SCHEMA..T_SEGMENT Deterministic,
  *  DESCRIPTION
  *    Constructs new segment by swapping start and end coordinates of underlying segment.
  *    If underlying segment has a middle coordinate it is left in place.
  *  RESULT
  *    segment (T_SEGMENT) -- segment that has reverse direction to the original segment.
  *  EXAMPLE
  *    select T_Segment(
  *             sdo_geometry(2002,NULL,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,10,10))
  *           ).ST_Reverse()
  *            .ST_SdoGeometry() as rSegment
  *      from dual;
  *
  *    RSEGMENT
  *    -------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(10,10,0,0))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Reverse
           Return &&INSTALL_SCHEMA..T_SEGMENT Deterministic,

  /****m* T_SEGMENT/ST_isReversed
  *  NAME
  *    ST_isReversed -- Returns 1 (true) if the underlying segment has its start/end coordinates reversed to supplied segment.
  *  SYNOPSIS
  *    Member Function ST_isReversed(p_other     IN &&INSTALL_SCHEMA..T_SEGMENT)
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    Compares underlying T_SEGMENT's start and end coordinates against those of the supplied segment parameter.
  *    If self.start = p_other.end and self.end = p_other.start, the function returns 1 (True) otherwise 0 (False).
  *    If SDO_GTYPE is null, examines coordinates to see if W ordinate is not null.
  *  ARGUMENTS
  *    p_other   (T_Segment) -- Compared to SELF with return of 1 if reversed start/end coordinates
  *  RESULT
  *    True/False  (Integer) -- 1 if two segments have opposite direction.
  *    select T_Segment(
  *             sdo_geometry('LINESTRING(0 0,10 10)',null)
  *           ).ST_isReversed(
  *                p_other    =>T_Segment(sdo_geometry('LINESTRING(10 10,0 0)',null))
  *            ) as isReversed
  *      from dual;
  *
  *    ISREVERSED
  *    ----------
  *             1
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_isReversed(p_other In &&INSTALL_SCHEMA..T_Segment)
           Return integer Deterministic,

  /****m* T_SEGMENT/ST_To2D
  *  NAME
  *    ST_To2D -- Constructs a 2D segment from the underlying segment which can have any dimension.
  *  SYNOPSIS
  *    Member Function ST_To2D
  *             Return &&INSTALL_SCHEMA..T_SEGMENT Deterministic,
  *  DESCRIPTION
  *    Constructs new segment by discarding any z and w ordinates.
  *    SDO_GTYPE returned will be 2001.
  *    If segment already 2D it is returned unchanged.
  *  RESULT
  *    segment (T_SEGMENT) -- 2d segment.
  *  EXAMPLE
  *    select T_Segment(sdo_geometry(3002,4283,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(147.5, -42.5,10.0, 147.6, -42.5, 10.0)))
  *             .ST_To2D()
  *             .ST_SdoGeometry(2) as geom2D
  *      from dual;
  *
  *    GEOM2D
  *    ---------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2002,4283,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(147.5,-42.5,147.6,-42.5))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_To2D
           Return &&INSTALL_SCHEMA..T_SEGMENT Deterministic,

  /****m* T_SEGMENT/ST_To3D
  *  NAME
  *    ST_To3D -- Constructs a 3D segment from the underlying segment which can have any dimension.
  *  SYNOPSIS
  *    Member Function ST_To3D(p_keep_measure in integer default 0,
  *                            p_default_z    in number  default null)
  *             Return &&INSTALL_SCHEMA..T_SEGMENT Deterministic,
  *  DESCRIPTION
  *    Constructs new 3D segment.
  *    If segment 2D is has any p_default_z values added to the new segment's z ordinates.
  *    If segment is 3D with no measure it is returned without change.
  *    If segment is 3D with Measure it is returned as an unmeasured 3D segment with the Z ordinates
  *    being the original measure values if p_keep_measure = 1, otherwise, the Z values are set to p_default_z.
  *    If segment is 4D with Measure it is returned as an unmeasured 3D segment with the Z ordinates
  *    being the original measure values if p_keep_measure = 1, otherwise, the Z values are set to p_default_z.
  *  RESULT
  *    segment (T_SEGMENT) -- 3D segment.
  *  EXAMPLE
  *    -- Convert 2D segment to 3D with constant Z value of 10.0
  *    select T_Segment(sdo_geometry(2002,4283,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(147.5, -42.5, 147.6,-42.5)))
  *             .ST_To3D(p_keep_measure => 0,
  *                      p_default_z    => 10.0)
  *             .ST_SdoGeometry(3) as geom3D
  *      from dual;
  *
  *    GEOM3D
  *    ---------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3002,4283,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1),MDSYS.SDO_ORDINATE_ARRAY(147.5,-42.5,10,147.6,-42.5,10))
  *
  *    -- Convert measured segment (no Z) to 3D with Z
  *    select T_Segment(sdo_geometry(3302,4283,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(147.5, -42.5,0.0, 147.6, -42.5, 10923.0)))
  *             .ST_To3D(p_keep_measure => 1)
  *             .ST_SdoGeometry(3) as geom3D
  *      from dual;
  *
  *    GEOM3D
  *    -----------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3002,4283,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1),MDSYS.SDO_ORDINATE_ARRAY(147.5,-42.5,0,147.6,-42.5,10923))
  *
  *    -- Convert measured segment with Z to 3D with Z (throw M away)
  *    select T_Segment(sdo_geometry(4402,4283,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(147.5,-42.5,849.9,2000.0, 147.6,-42.5,1923.0,4000.0)))
  *             .ST_To3D(p_keep_measure => 0)
  *             .ST_SdoGeometry(3) as geom3D
  *      from dual;
  *
  *    GEOM3D
  *    --------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3002,4283,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(147.5,-42.5,849.9,147.6,-42.5,1923))
  *
  *    -- Convert measured segment with Z to 3D with M becoming Z (throw Z away)
  *    select T_Segment(sdo_geometry(4402,4283,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(147.5,-42.5,849.9,2000.0, 147.6,-42.5,1923.0,4000.0)))
  *             .ST_To3D(p_keep_measure => 1)
  *             .ST_SdoGeometry(3) as geom3D
  *      from dual;
  *
  *    GEOM3D
  *    -------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3002,4283,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(147.5,-42.5,2000,147.6,-42.5,4000))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_To3D(p_keep_measure in integer default 0,
                          p_default_z    in number  default null)
           Return &&INSTALL_SCHEMA..T_SEGMENT Deterministic,

  /****m* T_SEGMENT/ST_isCollinear
  *  NAME
  *    ST_isCollinear -- Checks if two segments' coordinates are collinar.
  *  SYNOPSIS
  *    Member Function ST_isCollinear(p_segment in &&INSTALL_SCHEMA..T_SEGMENT)
  *             Return Integer Deterministic
  *  DESCRIPTION
  *    This function determines if the two segments (underlying and supplied) have coordinates that fall in a line (collinear)
  *    The segments should touch with a end/start relationship.
  *    Supplied segments cannot be CircularArcs.
  *  ARGUMENTS
  *    p_segment  (T_Segment) -- Other, possibly connected, segment (LineString not CircularString)
  *  RESULT
  *    boolean      (integer) -- 1 is true (collinear) 0 if false.
  *  NOTES
  *    Ignores any measure ordinates.
  *    Calculations are always planar.
  *  EXAMPLE
  *    -- 0. Uses T_Vector3D to compute whether segments can be merged by sharing vertex and having same normalized vectors.
  *    with data as (
  *    select sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(  0,  0, 100,100)) as line1,
  *           sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(100,100, 200,200)) as line2
  *      from dual
  *     UNION ALL
  *    select sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(  0,  0, 0, 100,100,10)) as line1,
  *           sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(100,100,10, 200,200,20)) as line2
  *      from dual
  *    )
  *    select T_Segment(a.line1)
  *             .ST_IsCollinear(p_segment=>T_Segment(a.line2)) as isCollinear
  *      from data a;
  *
  *    MS2
  *    ----------------
  *    0
  *    1
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 -- Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_isCollinear(p_segment in &&INSTALL_SCHEMA..T_SEGMENT)
           Return integer Deterministic,

  /****m* T_SEGMENT/ST_Merge
  *  NAME
  *    ST_Merge -- Merge two straight line segments - does not support circular arc segments
  *  SYNOPSIS
  *    Member Function ST_Merge(p_segment in &&INSTALL_SCHEMA..T_SEGMENT)
  *             Return t_segment Deterministic
  *  DESCRIPTION
  *    This function determines if the two segments (underlying and supplied) for a straight line (no bend)
  *    and touch as a start/end coordinate pair.
  *    New segment is created from start/end coordinates.
  *  ARGUMENTS
  *    p_segment  (T_Segment) -- Other, possibly connected, segment
  *  RESULT
  *    segment   (T_Segment) -- New segment.
  *  NOTES
  *    Ignores any measure ordinates.
  *    Calculations are always planar.
  *  EXAMPLE
  *    -- 0. Uses T_Vector3D to compute whether segments can be merged by sharing vertex and having same normalized vectors.
  *    with data as (
  *    select sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(  0,  0, 100,100)) as line1,
  *           sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(100,100, 200,200)) as line2
  *      from dual
  *     UNION ALL
  *    select sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(  0,  0, 0, 100,100,10)) as line1,
  *           sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(100,100,10, 200,200,20)) as line2
  *      from dual
  *    )
  *    select a.line1.get_Dims() as dims,
  *           t_vector3d(T_Segment(a.line1))
  *             .Normalize()
  *             .Subtract(
  *                t_vector3d(
  *                  T_Segment(a.line2))
  *                  .Normalize())
  *                  .AsText()as ms2
  *      from data a;
  *
  *    DIMS MS2
  *    ---- ----------------
  *       2 T_VECTOR3D(x=0,y=0,z=NULL}
  *       3 T_VECTOR3D(x=0,y=0,z=0}
  *
  *    -- 1. ST_Merge End/Start collinear in 2D and 3D
  *    with data as (
  *    select sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array( 0, 0, 0, 10,10,10)) as first_line,
  *           sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(10,10,10, 20,20,20)) as second_line
  *      from dual
  *    )
  *    select 2 as dims,
  *           T_Segment( a.first_line,  1 ).ST_To2D()
  *           .ST_Merge( T_Segment( a.second_line, 2 ).ST_To2D() ).ST_AsText() as mergedSegment
  *      from data a
  *     union all
  *    select 3 as dims,
  *           T_Segment( a.first_line, 1 ).ST_Merge( T_Segment( a.second_line, 2 ) ).ST_AsText() as mergedSegment
  *      from data a;
  *
  *    DIMS MERGEDSEGMENT
  *    ---- -------------------------------------------------------------------------------------------------------------------
  *       2 SEGMENT(NULL,NULL,1,Start(1,0,0,NULL,NULL,2001,NULL),End(2,20,20,NULL,NULL,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *       3 SEGMENT(NULL,NULL,1,Start(1,0,0,0,NULL,3001,NULL),End(2,20,20,20,NULL,3001,NULL),SDO_GTYPE=3002,SDO_SRID=NULL)
  *
  *    -- 2. ST_Merge End/Start collinear in 2D but not 3D
  *    with data as (
  *    select sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array( 0, 0, 0, 10,10,10)) as first_line,
  *           sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(10,10,10, 20,20,21)) as second_line
  *      from dual
  *    )
  *    select 2 as dims,
  *                      T_Segment( a.first_line, 1 ).ST_To2D()
  *           .ST_Merge( T_Segment( a.second_line, 2 ).ST_To2D() ).ST_AsText() as mergedSegment
  *      from data a
  *     union all
  *    select 3 as dims,
  *           T_Segment( a.first_line ).ST_Merge( T_Segment( a.second_line, 2 ) ).ST_AsText() as mergedSegment
  *      from data a;
  *
  *    DIMS MERGEDSEGMENT
  *    ---- ---------------------------------------------------------------------------------------------------------------------------------------------
  *       2 SEGMENT(NULL,NULL,1,Start(1,0,0,NULL,NULL,2001,NULL),End(2,20,20,NULL,NULL,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *       3 SEGMENT(NULL,NULL,0,Start(1,0,0,0,NULL,3001,NULL),Mid(2,10,10,10,NULL,3001,NULL),End(2,20,20,21,NULL,3001,NULL),SDO_GTYPE=3002,SDO_SRID=NULL)
  *
  *    -- 3. ST_Merge where relationship is end/end collinear
  *    with data as (
  *    select sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array( 0, 0, 0, 10,10,10)) as first_line,
  *           sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(20,20,20, 10,10,10)) as second_line
  *      from dual
  *    )
  *    select 2 as dims,
  *                      T_Segment( a.first_line,  1 ).ST_To2D()
  *           .ST_Merge( T_Segment( a.second_line, 2 ).ST_To2D() ).ST_AsText() as mergedSegment
  *      from data a
  *     union all
  *    select 3 as dims,
  *           T_Segment( a.first_line, 1 ).ST_Merge( T_Segment( a.second_line, 2 ) ).ST_AsText() as mergedSegment
  *      from data a;
  *
  *    DIMS MERGEDSEGMENT
  *    ---- -------------------------------------------------------------------------------------------------------------------
  *       2 SEGMENT(NULL,NULL,1,Start(1,0,0,NULL,NULL,2001,NULL),End(1,20,20,NULL,NULL,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *       3 SEGMENT(NULL,NULL,1,Start(1,0,0,0,NULL,3001,NULL),End(1,20,20,20,NULL,3001,NULL),SDO_GTYPE=3002,SDO_SRID=NULL)
  *
  *    -- 4. ST_Merge where relationship is start/start collinear
  *    with data as (
  *    select sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(10,10,10,  0, 0, 0)) as first_line,
  *           sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(20,20,20, 10,10,10)) as second_line
  *      from dual
  *    )
  *    select 2 as dims,
  *                      T_Segment( a.first_line, 1 ).ST_To2D()
  *           .ST_Merge( T_Segment( a.second_line, 2 ).ST_To2D() ).ST_AsText() as mergedSegment
  *      from data a
  *     union all
  *    select 3 as dims,
  *           T_Segment( a.first_line, 1 ).ST_Merge( T_Segment( a.second_line, 2 ) ).ST_AsText() as mergedSegment
  *      from data a;
  *
  *    DIMS MERGEDSEGMENT
  *    ---- --------------------------------------------------------------------------------------------------------------------------------------
  *       2 SEGMENT(NULL,NULL,NULL,Start(NULL,NULL,NULL,NULL,NULL,NULL,NULL),End(NULL,NULL,NULL,NULL,NULL,NULL,NULL),SDO_GTYPE=NULL,SDO_SRID=NULL)
  *       3 SEGMENT(NULL,NULL,NULL,Start(NULL,NULL,NULL,NULL,NULL,NULL,NULL),End(NULL,NULL,NULL,NULL,NULL,NULL,NULL),SDO_GTYPE=NULL,SDO_SRID=NULL)
  *
  *    -- 5. ST_Merge where identical (returns first_line)
  *    with data as (
  *    select sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,0, 10,10,10)) as first_line,
  *           sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,0, 10,10,10)) as second_line
  *      from dual
  *    )
  *    select 2 as dims,
  *                      T_Segment( a.first_line,  1 ).ST_To2D()
  *           .ST_Merge( T_Segment( a.second_line, 2 ).ST_To2D() ).ST_AsText() as mergedSegment
  *      from data a
  *     union all
  *    select 3 as dims,
  *           T_Segment( a.first_line, 1 ).ST_Merge( T_Segment( a.second_line, 2 ) ).ST_AsText() as mergedSegment
  *      from data a;
  *
  *    DIMS MERGEDSEGMENT
  *    ---- -------------------------------------------------------------------------------------------------------------------
  *       2 SEGMENT(NULL,NULL,1,Start(1,0,0,NULL,NULL,2001,NULL),End(2,10,10,NULL,NULL,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *       3 SEGMENT(NULL,NULL,1,Start(1,0,0,0,NULL,3001,NULL),End(2,10,10,10,NULL,3001,NULL),SDO_GTYPE=3002,SDO_SRID=NULL)
  *
  *    -- 6. ST_Merge where no spatial relationship (Returns Empty Segment)
  *    with data as (
  *    select sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,0,    10,10,10)) as first_line,
  *           sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(11,11,11, 20,20,21)) as second_line
  *      from dual
  *    )
  *    select 2 as dims,
  *                      T_Segment( a.first_line,  1 ).ST_To2D()
  *           .ST_Merge( T_Segment( a.second_line, 2 ).ST_To2D() ).ST_AsText() as mergedSegment
  *      from data a
  *     union all
  *    select 3 as dims,
  *           T_Segment( a.first_line, 1 ).ST_Merge( T_Segment( a.second_line, 2 ) ).ST_AsText() as mergedSegment
  *      from data a;
  *
  *    DIMS MERGEDSEGMENT
  *    ---- --------------------------------------------------------------------------------------------------------------------------------------
  *       2 SEGMENT(NULL,NULL,NULL,Start(NULL,NULL,NULL,NULL,NULL,NULL,NULL),End(NULL,NULL,NULL,NULL,NULL,NULL,NULL),SDO_GTYPE=NULL,SDO_SRID=NULL)
  *       3 SEGMENT(NULL,NULL,NULL,Start(NULL,NULL,NULL,NULL,NULL,NULL,NULL),End(NULL,NULL,NULL,NULL,NULL,NULL,NULL),SDO_GTYPE=NULL,SDO_SRID=NULL)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2013 -- Original coding.
  *    Simon Greener - August 2018  -- Ensure all cases correct esp for 3D (XYZ)
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Merge(p_segment    in &&INSTALL_SCHEMA..T_SEGMENT)
           Return &&INSTALL_SCHEMA..T_SEGMENT Deterministic,

  /****m* T_SEGMENT/ST_Densify
  *  NAME
  *    ST_Densify -- Implements a basic geometry densification algorithm.
  *  SYNOPSIS
  *    Member Function ST_Densify(p_distance in number)
  *                               p_unit      IN varchar2 default NULL)
  *             Return mdsys.sdo_Geometry Deterministic
  *  DESCRIPTION
  *    This function add vertices to an existing vertex-to-vertex described geometry segment.
  *    New vertices are added in such a way as to ensure that no two vertices will
  *    ever fall with SELF.PrecisionModel.XY.
  *    Also, because of the nature of the implementation there is no guarantee that the
  *    added vertices will be p_distance apart.
  *    The implementation prefers to balance the added vertices across a complete segment
  *    such that an even number are added. The final vertex separation will be
  *    BETWEEN p_distance AND p_distance * 2 .
  *
  *    The implementation honours 3D and 4D shapes and averages these dimension values
  *    for the new vertices.
  *  ARGUMENTS
  *    p_distance     (Number) -- The desired optimal distance between added vertices. Must be > SELF.tolerance.
  *  RESULT
  *    geometry (sdo_geometry) -- Densified geometry.
  *  EXAMPLE
  *  NOTES
  *    Does not support CircularArc segments.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2013 -- Original coding.
  *    Simon Greener - August 2018  -- Ensure all cases correct esp for 3D (XYZ)
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Densify(p_distance  in number,
                             p_unit      IN varchar2 default NULL)
           Return mdsys.sdo_geometry Deterministic,

  /****m* T_SEGMENT/ST_AddCurveBetweenSegments
  *  NAME
  *    ST_AddCurveBetweenSegments -- Adds Circular Curve between two segments
  *  SYNOPSIS
  *    Member Function ST_AddCurveBetweenSegments(
  *                         p_segment   In &&INSTALL_SCHEMA..T_Segment,
  *                         p_iVertex   in &&INSTALL_SCHEMA..T_Verex default NULL,
  *                         p_radius    In number        default null,
  *                         p_unit      In varchar2      default NULL)
  *               Return mdsys.sdo_Geometry Deterministic,
  *  DESCRIPTION
  *    Adds Circular Curve between two segments. 
  *    The segments can be 2 point linestrings or 3 point circular curves.
  *    How the circular cuve is added depends on the parameters.
  *    1. If SELF and p_segment do not meet, and the intersectoin point between 
  *       SELF.endCoord and p_segment.startCoord is not provided, the intersection point
  *       is computed using ST_IntersectDetail.
  *    2. If p_radius is provided a circular curve is fitted between end/mid/start of radius p_radius.
  *    3. If p_iVertex, p_radius are not provided, the best circular arc is fittd.
  *    The implementation honours 3D and 4D shapes and averages these dimension values
  *    for the new vertices.
  *  ARGUMENTS
  *    p_segment (T_Segment) -- Other, unconnected, segment
  *    p_iVertex  (T_Vertex) -- The intersectoin point between the two segments.
  *    p_radius     (number) -- Optional Radius.
  *    p_unit     (Varchar2) -- If NULL, the calculations are done using the underlying projection default units.
  *                             If an Oracle Unit of Measure is supplied (eg unit=M) that is value for the SRID,
  *                             this value is used when calculating the p_offset distance.
  *  RESULT
  *    geometry (sdo_geometry) -- sdo_geometry with self and p_segment joined by circular arc.
  *  EXAMPLE
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2013 -- Original coding.
  *    Simon Greener - August 2018  -- Ensure all cases correct esp for 3D (XYZ)
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_AddCurveBetweenSegments(
                     p_segment   In &&INSTALL_SCHEMA..T_SEGMENT,
                     p_iVertex   in &&INSTALL_SCHEMA..T_Vertex default NULL,
                     p_radius    In number         default null,
                     p_unit      In varchar2       default NULL)
           Return mdsys.sdo_Geometry Deterministic,

 /****m* T_SEGMENT/ST_Parallel
  *  NAME
  *    ST_Parallel -- Moves segment parallel the provided p_offset distance.
  *  SYNOPSIS
  *    Member Function ST_Parallel(p_offset in Number)
  *             Return &&INSTALL_SCHEMA..T_SEGMENT Deterministic,
  *  DESCRIPTION
  *    Computes parallel offset, left or right of underlying geometry.
  *    Circular arcs are not yet correctly handled.
  *  ARGUMENTS
  *    p_offset     (Number) -- Value +/- numeric value.
  *  RESULT
  *    New segment (T_SEGMENT) -- Input segment moved parallel by p_offset units
  *  TODO
  *    Check Circular Arc Calculations
  *  EXAMPLE
  *    with data as (
  *      select 'Planar LineString' as test,
  *             sdo_geometry(3302,NULL,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,1.1,6,6,5.95)) as geom,
  *             5.0 as offset
  *        from dual
  *       union all
  *       select 'Planar CircularString' as test,
  *             SDO_GEOMETRY(2002,28355,NULL,
  *                          SDO_ELEM_INFO_ARRAY(1,2,2), -- Circular Arc line string
  *                          SDO_ORDINATE_ARRAY(252230.478,5526918.373, 252400.08,5526918.373,252230.478,5527000.0)) as geom,
  *             -5.0 as offset
  *        from dual
  *    )
  *    select a.test,
  *           T_Segment(a.geom)
  *             .ST_Parallel(p_offset=>a.offset)
  *             .ST_Round(3,3,2,1)
  *             .ST_SdoGeometry() as pGeom
  *      from data a;
  *
  *    TEST                  PGEOM
  *    --------------------- -------------------------------------------------------------------------------------------------------------------------------------------------
  *    Planar LineString     SDO_GEOMETRY(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(4.536,-2.536,1.1,9.536,2.464,5.95))
  *    Planar CircularString SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(252321.904,5527048.051,252318.419,5527048.243,252323.295,5527047.937))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - December 2008 - Original coding in GEOM package.
  *    Simon Greener - January 2013  - Port/Rewrite to T_GEOMETRY object function member.
  *    Simon Greener - January 2014  - Port/Rewrite to T_SEGMENT object function member.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Parallel(p_offset in Number)
           Return &&INSTALL_SCHEMA..T_SEGMENT Deterministic,

    /**
   * Computes the distance from a line segment AB to a line segment CD
   * 
   * Note: NON-ROBUST!
   * 
   * @param A - a point of one line
   * @param B - the second point of (must be different to A)
   * @param C - one point of the line
   * @param D - another point of the line (must be different to A)
   */
  Member Function ST_SegmentToSegmentDistance(
                     p_segment    in &&INSTALL_SCHEMA..T_Segment,
                     p_unit       in varchar2 default null
                  )
           Return Number deterministic,

 /****m* T_SEGMENT/ST_Closest(p_geometry p_unit)
  *  NAME
  *    ST_Closest -- Finds nearest point on line where supplied geometry comes closest (snap to).
  *  SYNOPSIS
  *    Member Function ST_Closest(p_geometry  in mdys.sdo_geometry,
  *                               p_unit      In varchar2 DEFAULT NULL
  *                              )
  *             Return &&INSTALL_SCHEMA..T_Vertex Deterministic
  *  DESCRIPTION
  *    Finds nearest point on segment where supplied geometry comes closest (snap).
  *    Computations respect SRID and unit as uses SDO_GEOM.SDO_CLOSEST_POINTS.
  *    If SDO_GEOM.SDO_CLOSEST_POINTS fails, a result is calculated using planar arithmetic.
  *    This function handles fact that SDO_GEOM function does not support measured segments.
  *  ARGUMENTS
  *    p_geometry (sdo_geometry) - Any sdo_geometry object.
  *    p_unit    (Varchar2) - Oracle Unit of Measure eg unit=M.
  *  RESULT
  *    vertex    (T_Vertex) -- Nearest point on line supplied vertex is nearest to.
  *  EXAMPLE
  *    -- Planar
  *    -- Planar 3D
  *    With tGeom as (
  *     select sdo_geometry(3001,90000006,Sdo_point_type(562038.848,1013262.454,0.0),NULL,NULL) as geometry,
  *            t_geometry(SDO_GEOMETRY(3002,90000006,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),
  *                                    SDO_ORDINATE_ARRAY(
  *                                       562046.642,1013077.602,0, 562032.193,1013252.074,0.035,
  *                                       562028.848,1013292.454,0.043, 562018.682,1013424.977,0.07,
  *                                       562007.163,1013575.247,0.099, 561981.686,1013900.825,0.16,
  *                                       561971.702,1014043.346,0.187, 561968.808,1014089.436,0.196,
  *                                       561966.077,1014146.249,0.207, 561957.494,1014376.425,0.25,
  *                                       561941.333,1014879.5,0.345,   561934.844,1015013.849,0.37,
  *                                       561930.843,1015108.115,0.388, 561926.975,1015245.592,0.414,
  *                                       561922.233,1015468.243,0.456, 561918.631,1015586.912,0.478,
  *                                       561912.301,1015756.343,0.51,  561910.44,1015825.101,0.523,
  *                                       561909.946,1015874.059,0.532, 561910.027,1015909.594,0.539,
  *                                       561910.765,1015948.408,0.547, 561913.6,1016019.49,0.561,
  *                                       561917.047,1016069.767,0.57,  561919.944,1016103.33,0.577,
  *                                       561927.81,1016171.894,0.59,   561934.889,1016220.292,0.599,
  *                                       561939.73,1016249.091,0.605,  561949.697,1016302.867,0.615,
  *                                       561965.347,1016374.268,0.629, 561972.535,1016402.687,0.634
  *                                       )),
  *                        0.0005,3,1)
  *                as lrs_tgeom
  *       from dual
  *    )
  *    select t.segment
  *            .ST_Closest(
  *               p_geometry  => a.geometry,
  *               p_unit      => 'unit=M'
  *            )
  *            .ST_Round(3)
  *            .ST_AsText() as closestPoint
  *      from tGeom a,
  *            table(a.lrs_tgeom.ST_Segmentize(p_filter=>'DISTANCE',
  *                                            p_vertex=>SELF.T_Vertex(a.geometry)) t;
  *
  *    CLOSESTPOINT
  *    ----------------------------------------------------------
  *    T_Vertex(562031.384,1013261.836,.037,NULL,NULL,3001,90000006)
  *
  *    -- Geodetic
  *    With data as (
  *     select SDO_GEOMETRY(2001,4326,SDO_POINT_TYPE(147.439,-43.195,NULL),NULL,NULL) as point,
  *            sdo_geometry(3002,4326,NULL,sdo_elem_info_array(1,2,1),
  *                         sdo_ordinate_array(147.50,-43.132,100.0, 147.41,-43.387,30000.0)) as line
  *       from dual
  *    )
  *    select T_Segment(a.line)
  *            .ST_Closest(
  *               p_vertex    => T_Vertex(a.point),
  *               p_unit      => 'unit=M'
  *            )
  *           .ST_Round(8)
  *           .ST_AsText() as closestPoint
  *      from data a;
  *
  *    CLOSESTPOINT
  *    ------------------------------------------------------------
  *    T_Vertex(147.47543293,-43.20182579,NULL,NULL,NULL,2001,4326)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Closest (p_geometry  in mdsys.sdo_geometry,
                              p_unit      In varchar2 DEFAULT NULL
                             )
           Return &&INSTALL_SCHEMA..T_Vertex deterministic,

 /****m* T_SEGMENT/ST_isPointOnSegment
 *  NAME
 *    ST_isPointOnSegment -- Checks if supplied point falls on the underlying segment.
 *  SYNOPSIS
 *    ST_isPointOnSegment(p_vertex in &&INSTALL_SCHEMA..T_Vertex,
 *                        p_unit   in varchar2)
 *     Return integer deterministic
 *  DESCRIPTION
 *    This function checks if the supplied point falls on the underlying segment.
 *    
 *    Computes for LineString or CircularString.
 *  NOTES
 *    Geodetic/geographic CircularArc segments treated as planar
 *  INPUTS
 *    p_vertex (t_vertex) - Point on to linestring or CircularString.
 *    p_unit   (varchar2) - Unit of measure for SRID.
 *  RESULT
 *    booelan (integer) -- 1 if point on segment; 0 otherwise
 *  EXAMPLE
 *    select T_Segment(MDSYS.SDO_GEOMETRY(3302,8307,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1),MDSYS.SDO_ORDINATE_ARRAY(147.41,-43.132,100, 147.5,-43.387,30000)))
 *             .ST_isPointOnSegment (
 *                t_vertex(SDO_GEOMETRY(3301,8307,SDO_POINT_TYPE(147.44551945,-43.23290209,11930.116),NULL,NULL))
 *           ) as is_on 
 *      from dual union all
 *    select T_Segment(MDSYS.SDO_GEOMETRY(3302,8307,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1),MDSYS.SDO_ORDINATE_ARRAY(147.41,-43.132,100, 147.5,-43.387,30000)))
 *             .ST_isPointOnSegment (
 *                t_vertex(SDO_GEOMETRY(3301,8307,SDO_POINT_TYPE(147.445,-43.232,11930.116),NULL,NULL))
 *           ) as is_on 
 *      from dual;
 *
 *          IS_ON
 *    ----------
 *             1
 *             0
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - August 2019 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Member Function ST_isPointOnSegment(p_vertex    in &&INSTALL_SCHEMA..T_Vertex,
                                      p_unit      in varchar2 default null)
      Return integer deterministic,

 /****m* T_SEGMENT/STPointToCircularArc
 *  NAME
 *    ST_PointToCircularArc -- Return a measured point by snapping provided point to the provided circularstring
 *  SYNOPSIS
 *    ST_PointToCircularArc(p_vertex in &&INSTALL_SCHEMA..T_Vertex,
 *                          p_unit   in varchar2 default null)
 *     Return &&INSTALL_SCHEMA..T_Vertex deterministic
 *  DESCRIPTION
 *    This function snaps supplied point to underlying circularString, returning the snapped point.
 *
 *    Computes Z and M values if exist on underlying CircularString.
 *
 *    If input circularString is 2D, length from start of circularString to point is returned in M ordinate of snapped point.
 *
 *  NOTES
 *    Supports CircularString geometries only.
 *  INPUTS
 *    p_vertex (t_vertex) - Point near to linestring.
 *    p_unit   (varchar2) - Unit of measure (depends on SRID)
 *  RESULT
 *    snapped point (t_vetex) -- First point found on circularString.
 *  EXAMPLE
 *    select 'Point is on centre of the XYZ circular arc (returns start point)' as test,
 *           t_segment(SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(3,6.3246,-1, 0,7,-1, -3,6.3246,-1)))
 *             .ST_PointToCircularArc (
 *                t_vertex(SDO_GEOMETRY('POINT(0 0)',NULL)),
 *                null
 *           ).ST_Round(3,3,3,3).ST_AsEWKT() as project_point
 *    from dual union all
 *    select 'Point does not have relationship with XYM CircularSring' as test,
 *           t_segment(SDO_GEOMETRY(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(3,6.325,0, 0,7,3.08, -3,6.325,6.15)))
 *             .ST_PointToCircularArc (
 *                t_vertex(SDO_GEOMETRY('POINT(8 8)',NULL))
 *           ).ST_AsEWKT() as project_point
 *    from dual union all
 *    select 'Point projects on to point half way along XY circular arc (returns measure as length)' as test,
 *           t_segment(SDO_GEOMETRY('CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246)',NULL))
 *             .ST_PointToCircularArc (
 *              t_vertex(SDO_GEOMETRY('POINT(0 3.5)',NULL)),
 *              null
 *           ).ST_Round(3,3,3,3).ST_AsEWKT() as project_point
 *      from dual union all
 *    select 'Point has relationship with XYM CircularSring' as test,
 *           t_segment(SDO_GEOMETRY(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(3,6.325,0, 0,7,3.08, -3,6.325,6.15)))
 *             .ST_PointToCircularArc (
 *                t_vertex(SDO_GEOMETRY('POINT(2 8)',NULL))
 *           ).ST_Round(3,3,3,3).ST_AsEWKT() as project_point
 *    from dual union all
 *    select 'Point has relationship with XYZM circular arc' as test,
 *           t_segment(SDO_GEOMETRY(4402,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(3,6.325,-2.1,0, 0,7,-2.1,3.08, -3,6.325,-2.1,6.15)))
 *             .ST_PointToCircularArc (
 *                t_vertex(SDO_GEOMETRY('POINT(2 8)',NULL)),
 *                null
 *           ).ST_Round(3).ST_AsEWKT() as project_point
 *    from dual ;
 *    
 *    TEST                                                                                  PROJECT_POINT
 *    ------------------------------------------------------------------------------------- -----------------------------
 *    Point is on centre of the XYZ circular arc (returns start point)                      POINTZ (3 6.325 -1)
 *    Point does not have relationship with XYM CircularSring                               NULL
 *    Point projects on to point half way along XY circular arc (returns measure as length) POINTM (0 7 3.1)
 *    Point has relationship with XYM CircularSring                                         POINTM (1.698 6.791 1.374)
 *    Point has relationship with XYZM circular arc                                         POINTZM (1.698 6.791 -2.1 1.374)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - August 2019 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Member Function ST_PointToCircularArc(p_vertex in &&INSTALL_SCHEMA..T_Vertex,
                                        p_unit   in varchar2 default null)
      Return &&INSTALL_SCHEMA..T_Vertex deterministic,

 /****m* T_SEGMENT/STPointToLineString
 *  NAME
 *    ST_PointToLineString -- Return a measured point by snapping provided point to the underlying LineString
 *  SYNOPSIS
 *    ST_PointToLineString(p_vertex in &&INSTALL_SCHEMA..T_Vertex)
 *     Return &&INSTALL_SCHEMA..T_Vertex deterministic
 *  DESCRIPTION
 *    This function snaps supplied point to underlying LineString, returning the snapped point.
 *    
 *    Computes Z and M values if exist on underlying LineString.
 *    
 *    If input circularString is 2D, length from start of LineString to point is returned in M ordinate of snapped point.
 *    
 *  NOTES
 *    Supports LineString geometries only.
 *  INPUTS
 *    p_vertex (t_vertex) - Point near to linestring.
 *  RESULT
 *    snapped point (t_vetex) -- First point found on LineString.
 *  EXAMPLE
 *    select 'Point is on centre of the XYZ circular arc (returns start point)' as test,
 *           t_segment(SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(3,6.3246,-1, 0,7,-1, -3,6.3246,-1)))
 *             .ST_PointToLineString (
 *                t_vertex(SDO_GEOMETRY('POINT(0 0)',NULL)),
 *                null
 *           ).ST_Round(3,3,3,3).ST_AsEWKT() as project_point
 *    from dual union all
 *    select 'Point does not have relationship with XYM LineString' as test,
 *           t_segment(SDO_GEOMETRY(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(3,6.325,0, 0,7,3.08, -3,6.325,6.15)))
 *             .ST_PointToLineString (
 *                t_vertex(SDO_GEOMETRY('POINT(8 8)',NULL))
 *           ).ST_AsEWKT() as project_point
 *    from dual union all
 *    select 'Point projects on to point half way along XY circular arc (returns measure as length)' as test,
 *           t_segment(SDO_GEOMETRY('CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246)',NULL))
 *             .ST_PointToLineString (
 *              t_vertex(SDO_GEOMETRY('POINT(0 3.5)',NULL)),
 *              null
 *           ).ST_Round(3,3,3,3).ST_AsEWKT() as project_point
 *      from dual union all
 *    select 'Point has relationship with XYM LineString' as test,
 *           t_segment(SDO_GEOMETRY(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(3,6.325,0, 0,7,3.08, -3,6.325,6.15)))
 *             .ST_PointToLineString (
 *                t_vertex(SDO_GEOMETRY('POINT(2 8)',NULL))
 *           ).ST_Round(3,3,3,3).ST_AsEWKT() as project_point
 *    from dual union all
 *    select 'Point has relationship with XYZM circular arc' as test,
 *           t_segment(SDO_GEOMETRY(4402,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(3,6.325,-2.1,0, 0,7,-2.1,3.08, -3,6.325,-2.1,6.15)))
 *             .ST_PointToLineString (
 *                t_vertex(SDO_GEOMETRY('POINT(2 8)',NULL)),
 *                null
 *           ).ST_Round(3).ST_AsEWKT() as project_point
 *    from dual ;
 *    
 *    TEST                                                                                  PROJECT_POINT
 *    ------------------------------------------------------------------------------------- -----------------------------
 *    Point is on centre of the XYZ circular arc (returns start point)                      POINTZ (3 6.325 -1)
 *    Point does not have relationship with XYM CircularSring                               NULL
 *    Point projects on to point half way along XY circular arc (returns measure as length) POINTM (0 7 3.1)
 *    Point has relationship with XYM CircularSring                                         POINTM (1.698 6.791 1.374)
 *    Point has relationship with XYZM circular arc                                         POINTZM (1.698 6.791 -2.1 1.374)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - August 2019 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Member Function ST_PointToLineString(p_vertex in &&INSTALL_SCHEMA..t_vertex)
      Return &&INSTALL_SCHEMA..T_Vertex deterministic,

 /****m* T_SEGMENT/ST_ProjectPoint
 *  NAME
 *    ST_ProjectPoint -- Return a measured point by snapping provided point to the underlying LineString or circularString
 *  SYNOPSIS
 *    ST_ProjectPoint(p_vertex in &&INSTALL_SCHEMA..T_Vertex,
 *                    p_unit   in varchar2)
 *     Return &&INSTALL_SCHEMA..T_Vertex deterministic
 *  DESCRIPTION
 *    This function snaps supplied point to underlying LineString or CircularString, returning the snapped point.
 *    
 *    Computes Z and M values if exist on underlying LineString or CircularString.
 *    
 *    If input circularString is 2D, length from start of LineString or CircularString to point is returned in M ordinate of snapped point.
 *  NOTES
 *    Supports geodetic/geographic data.
 *  INPUTS
 *    p_vertex (t_vertex) - Point near to linestring or CircularString.
 *  RESULT
 *    snapped point (t_vetex) -- First point found on LineString.
 *  EXAMPLE
 *    select 'Point is on centre of the XYZ circular arc (returns start point)' as test,
 *           t_segment(SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(3,6.3246,-1, 0,7,-1, -3,6.3246,-1)))
 *             .ST_ProjectPoint (
 *                t_vertex(SDO_GEOMETRY('POINT(0 0)',NULL)),
 *                null
 *           ).ST_Round(3,3,3,3).ST_AsEWKT() as project_point
 *    from dual union all
 *    select 'Point does not have relationship with XYM LineString' as test,
 *           t_segment(SDO_GEOMETRY(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(3,6.325,0, 0,7,3.08, -3,6.325,6.15)))
 *             .ST_ProjectPoint (
 *                t_vertex(SDO_GEOMETRY('POINT(8 8)',NULL))
 *           ).ST_AsEWKT() as project_point
 *    from dual union all
 *    select 'Point projects on to point half way along XY circular arc (returns measure as length)' as test,
 *           t_segment(SDO_GEOMETRY('CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246)',NULL))
 *             .ST_ProjectPoint (
 *              t_vertex(SDO_GEOMETRY('POINT(0 3.5)',NULL)),
 *              null
 *           ).ST_Round(3,3,3,3).ST_AsEWKT() as project_point
 *      from dual union all
 *    select 'Point has relationship with XYM LineString' as test,
 *           t_segment(SDO_GEOMETRY(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(3,6.325,0, 0,7,3.08, -3,6.325,6.15)))
 *             .ST_ProjectPoint (
 *                t_vertex(SDO_GEOMETRY('POINT(2 8)',NULL))
 *           ).ST_Round(3,3,3,3).ST_AsEWKT() as project_point
 *    from dual union all
 *    select 'Point has relationship with XYZM circular arc' as test,
 *           t_segment(SDO_GEOMETRY(4402,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(3,6.325,-2.1,0, 0,7,-2.1,3.08, -3,6.325,-2.1,6.15)))
 *             .ST_ProjectPoint (
 *                t_vertex(SDO_GEOMETRY('POINT(2 8)',NULL)),
 *                null
 *           ).ST_Round(3).ST_AsEWKT() as project_point
 *    from dual union all
 *    select 'Geodetic Point has relationship with XYZM Geodetic LineString' as test,
 *           T_Segment(MDSYS.SDO_GEOMETRY(3302,4326,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1),MDSYS.SDO_ORDINATE_ARRAY(147.5,-43.132,100,147.41,-43.387,30000)))
 *             .ST_ProjectPoint (
 *                 t_vertex(SDO_GEOMETRY(2001,8307,SDO_POINT_TYPE(147.509,-43.221,NULL),NULL,NULL))
 *           ).ST_Round(3).ST_AsEWKT() as project_point
 *    from dual ;
 *    
 *    TEST                                                                                  PROJECT_POINT
 *    ------------------------------------------------------------------------------------- ---------------------------------
 *    Point is on centre of the XYZ circular arc (returns start point)                      POINTZ (3 6.325 -1)
 *    Point does not have relationship with XYM CircularSring                               NULL
 *    Point projects on to point half way along XY circular arc (returns measure as length) POINTM (0 7 3.1)
 *    Point has relationship with XYM CircularSring                                         POINTM (1.698 6.791 1.374)
 *    Point has relationship with XYZM circular arc                                         POINTZM (1.698 6.791 -2.1 1.374)
 *    Geodetic Point has relationship with XYZM Geodetic LineString                         SRID=8307;POINTM (147.44551945 -43.23290209 11930.116)
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - August 2019 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Member Function ST_ProjectPoint(p_vertex in &&INSTALL_SCHEMA..T_Vertex,
                              p_unit      In varchar2 Default NULL)
           Return &&INSTALL_SCHEMA..T_Vertex deterministic,

  -- ************************************************************************
  Member Function ST_Distance(p_geometry   in mdsys.sdo_geometry,
                              p_unit       in varchar2 Default null)
  Return Number deterministic,

  /****m* T_SEGMENT/ST_Distance(p_vertex p_unit)
  *  NAME
  *    ST_Distance -- Returns Distance from segment supplied T_Vertex (Wrapper)
  *  SYNOPSIS
  *    Member Function ST_Distance(p_vertex     in &&INSTALL_SCHEMA..T_Vertex,
  *                                p_unit       in varchar2 DEFAULT NULL)
  *             Return Number Deterministic
  *  DESCRIPTION
  *    (Wrapper over sdo_geometry ST_Distance method).
  *    This function computes a distance from the input T_Vertex object to the underlying T_SEGMENT.
  *    Result is in the distance units of the SDO_SRID, or in p_units where supplied.
  *  ARGUMENTS
  *    p_geom      (T_VERTEX) - A single vertex from which a bearing to the segment is calculated.
  *    p_unit      (VARCHAR2) - Oracle Unit of Measure eg unit=M.
  *  RESULT
  *    distance (Number) -- Distance in SRID unit of measure or in supplied units (p_unit)
  *  EXAMPLE
  *    -- Examples of ST_Distance to T_Vertex single poins
  *    with data as (
  *      select 'Planar LineString to Point' as test,
  *             sdo_geometry('LINESTRING(0 0,10 10)',null) as geom,
  *             sdo_geometry('POINT(5 0)',null) as dGeom
  *        from dual
  *        union all
  *      select 'Geo LineString to Point' as test,
  *             sdo_geometry('LINESTRING(147.50 -43.132,147.41 -43.387)',4326) as geom,
  *             sdo_geometry('POINT(147.3 -43.2)',4326) as dGeom
  *        from dual
  *       union all
  *       select 'Planar CircularString to Point' as test,
  *             SDO_GEOMETRY(2002,28355,NULL,
  *                          SDO_ELEM_INFO_ARRAY(1,2,2), -- Circular Arc line string
  *                          SDO_ORDINATE_ARRAY(252230.478,5526918.373, 252400.08,5526918.373,252230.478,5527000.0)) as geom,
  *             SDO_GEOMETRY('POINT(252429.706 5527034.024)',28355) as dGeom
  *        from dual
  *    )
  *    select a.test,
  *           T_Segment(a.geom).ST_Distance(p_vertex=>T_Vertex(a.dGeom),p_unit=>NULL) as d_in_meters,
  *           T_Segment(a.geom).ST_Distance(p_vertex=>T_Vertex(a.dGeom),p_unit=>'unit=KM') as l_in_km
  *      from data a;
  *
  *    TEST                           D_IN_METERS    L_IN_KM
  *    ------------------------------ ----------- ----------
  *    Planar LineString to Point        3.535534   3.535534
  *    Geo LineString to Point        13820.16185  13.820162
  *    Planar CircularString to Point    42.61532   0.042615
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Distance(p_vertex     in &&INSTALL_SCHEMA..T_Vertex,
                              p_unit       in varchar2 default null)
           Return Number Deterministic,

  /****m* T_SEGMENT/ST_Distance(p_segment p_unit)
  *  NAME
  *    ST_Distance -- Returns Distance from segment to the supplied segment (T_Segment)
  *  SYNOPSIS
  *    Member Function ST_Distance(p_segment    in &&INSTALL_SCHEMA..T_Segment,
  *                                p_unit       in varchar2 DEFAULT NULL)
  *             Return Number Deterministic
  *  DESCRIPTION
  *    (Wrapper over sdo_geometry ST_Distance method).
  *    This function computes a distance from the input T_Segment object to the underlying T_SEGMENT.
  *    Result is in the distance units of the SDO_SRID, or in p_units where supplied.
  *  ARGUMENTS
  *    p_segment  (T_SEGMENT) - A single T_Segment from which a distance to the segment is calculated.
  *    p_unit      (VARCHAR2) - Oracle Unit of Measure eg unit=M.
  *  RESULT
  *    distance (Number) -- Distance in SRID unit of measure or in supplied units (p_unit)
  *  EXAMPLE
  *    -- Examples of ST_Distance to T_Vertex single poins
  *    with data as (
  *      select 'Planar LineString to Point' as test,
  *             sdo_geometry('LINESTRING(0 0,10 10)',null) as geom,
  *             sdo_geometry('POINT(5 0)',null) as dGeom
  *        from dual
  *        union all
  *      select 'Geo LineString to Point' as test,
  *             sdo_geometry('LINESTRING(147.50 -43.132,147.41 -43.387)',4326) as geom,
  *             sdo_geometry('POINT(147.3 -43.2)',4326) as dGeom
  *        from dual
  *       union all
  *       select 'Planar CircularString to Point' as test,
  *             SDO_GEOMETRY(2002,28355,NULL,
  *                          SDO_ELEM_INFO_ARRAY(1,2,2), -- Circular Arc line string
  *                          SDO_ORDINATE_ARRAY(252230.478,5526918.373, 252400.08,5526918.373,252230.478,5527000.0)) as geom,
  *             SDO_GEOMETRY('POINT(252429.706 5527034.024)',28355) as dGeom
  *        from dual
  *    )
  *    select a.test,
  *           T_Segment(a.geom).ST_Distance(p_vertex=>T_Vertex(a.dGeom),p_unit=>NULL) as d_in_meters,
  *           T_Segment(a.geom).ST_Distance(p_vertex=>T_Vertex(a.dGeom),p_unit=>'unit=KM') as l_in_km
  *      from data a;
  *
  *    TEST                           D_IN_METERS    L_IN_KM
  *    ------------------------------ ----------- ----------
  *    Planar LineString to Point        3.535534   3.535534
  *    Geo LineString to Point        13820.16185  13.820162
  *    Planar CircularString to Point    42.61532   0.042615
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Distance(p_segment    in &&INSTALL_SCHEMA..T_Segment,
                              p_unit       in varchar2 default null)
           Return Number Deterministic,

 /****m* T_SEGMENT/ST_FindCircle
  *  NAME
  *    ST_FindCircle -- Finds a centre X and Y and Radius from three points of underlying circular arc.
  *  SYNOPSIS
  *    Member Function ST_FindCircle (
                Return &&INSTALL_SCHEMA..T_Vertex Deterministic,
  *  DESCRIPTION
  *    If the underlying object is a circular arc segment, then this function computes the centre and radius defining it.
  *    If segment is not a circular arc, null is returned.
  *  NOTES
  *    Assumes planar projection eg UTM.
  *    Works only on 2D circular segments
  *  RESULT
  *    Circle Properties (T_Vertex) : X ordinate of centre of circle.
  *                                   Y ordinate of centre of circle.
  *                                   Z ordinate contains radius of circle.
  *                                   SRID as underlying T_SEGMENT.
  *  EXAMPLE
  *    -- Compute measure of point
  *    with data as (
  *      select 'LineString' as test,
  *             sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,2),sdo_ordinate_array(0,0,5,5,10,0)) as geom
  *        from dual
  *       union all
  *      select 'CircularString' as test,
  *              SDO_GEOMETRY(2002,28355,NULL,
  *                          SDO_ELEM_INFO_ARRAY(1,2,2), -- Circular Arc line string
  *                          SDO_ORDINATE_ARRAY(252230.478,5526918.373, 252400.08,5526918.373,252230.478,5527000.0)) as geom
  *        from dual
  *    )
  *    select a.test,
  *           T_Segment(a.geom)
  *             .ST_FindCircle()
  *             .ST_AsText() as circle_params
  *      from data a;
  *
  *    TEST           CIRCLE_PARAMS
  *    -------------- ----------------------------------------------------------
  *    LineString     T_Vertex(5,0,5,NULL,0,2001,NULL)
  *    CircularString T_Vertex(252315.279,5526959.1865,94.111,NULL,0,2001,28355)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_FindCircle
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

 /****m* T_SEGMENT/ST_OffsetPoint
  *  NAME
  *    ST_OffsetPoint -- Creates a point described by a ratio along the
  *                      segment and with a perpendicular offset.
  *  SYNOPSIS
  *    Member Function ST_OffsetPoint(p_ratio     in Number,
  *                                   p_offset    in Number,
  *                                   p_unit      In Integer Default NULL)
  *             Return &&INSTALL_SCHEMA..T_Vertex Deterministic
  *  DESCRIPTION
  *    Supplied with a ratio value (0.0 -> 1.0), this function uses that value to find the
  *    point along its segment where it lies. If an offset value of 0.0 is supplied, the
  *    discovered point is returned. If the p_offset value is <> 0, the function computes a new
  *    position for the point at a distance of p_offset on the left (-ve) or right (+ve) side
  *    of the segment.
  *    The returned vertex's ordinate values are rounded using the supplied tolerance.
  *  ARGUMENTS
  *    p_ratio     (number) - A value between 0 and 1, from the start vertex of the segment,
  *                           which describes the position of the point to be offset.
  *    p_offset    (number) - The perpendicular distance to offset the point generated using p_ratio.
  *                           A negative value instructs the function to offet the point to the left (start-end),
  *                           and a positive value to the right.
  *    p_unit    (VARCHAR2) - If NULL, the calculations are done using the underlying projection default units.
  *                           If an Oracle Unit of Measure is supplied (eg unit=M) that is value for the SRID,
  *                           this value is used when calculating the p_offset distance.
  *  RESULT
  *    vertex     (T_VERTEX)   - New point on line with optional perpendicular offset.
  *  EXAMPLE
  *    With data as (
  *     select sdo_geometry(3302,4326,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(147.50,-43.132,100.0,147.41,-43.387,30000.0)) as geom
  *       from dual
  *       UNION ALL
  *     select sdo_geometry(2002,4326,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(147.50,-43.132,147.41,-43.387)) as geom
  *       from dual
  *    )
  *    select a.geom.get_dims() as dims,
  *           t.IntValue        as offset,
  *           T_Segment(a.geom)
  *             .ST_OffsetPoint(p_ratio     => 0.25,
  *                             p_offset    => t.IntValue,
  *                             p_unit      => 'unit=M')
  *           .ST_Round(8)
  *           .ST_SdoGeometry() as offsetPoint
  *      from data a,
  *          table(tools.generate_series(-5,5,5)) t;
  *
  *    DIMS OFFSET OFFSETPOINT
  *    ---- ------ --------------------------------------------------------------------------------
  *       3     -5 SDO_GEOMETRY(3301,4326,SDO_POINT_TYPE(152.19245167,-44.85985059,7575),NULL,NULL)
  *       3      0 SDO_GEOMETRY(3301,4326,SDO_POINT_TYPE(147.4775,-43.19575,7575),NULL,NULL)
  *       3      5 SDO_GEOMETRY(3301,4326,SDO_POINT_TYPE(142.76254833,-41.53164941,7575),NULL,NULL)
  *       2     -5 SDO_GEOMETRY(2001,4326,SDO_POINT_TYPE(152.19245167,-44.85985059,NULL),NULL,NULL)
  *       2      0 SDO_GEOMETRY(2001,4326,SDO_POINT_TYPE(147.4775,-43.19575,NULL),NULL,NULL)
  *       2      5 SDO_GEOMETRY(2001,4326,SDO_POINT_TYPE(142.76254833,-41.53164941,NULL),NULL,NULL)
  *
  *     6 rows selected
  *    With data as (
  *     select SDO_GEOMETRY(3302,90000006,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),
  *                         SDO_ORDINATE_ARRAY(562046.642,1013077.602,0, 562032.193,1013252.074,0.035)) as geom
  *      from dual
  *    )
  *    select t.IntValue as offset,
  *           T_Segment(a.geom)
  *             .ST_OffsetPoint(p_ratio     => 0.25,
  *                             p_offset    => t.IntValue,
  *                             p_unit      => 'unit=M')
  *           .ST_Round(3)
  *           .ST_SdoGeometry() as offsetPoint
  *      from data a,
  *          table(tools.generate_series(-5,5,5)) t;
  *
  *        OFFSET OFFSETPOINT
  *    ---------- ----------------------------------------------------------------------------------
  *            -5 SDO_GEOMETRY(3301,90000006,SDO_POINT_TYPE(562038.047,1013120.807,0.009),NULL,NULL)
  *             0 SDO_GEOMETRY(3301,90000006,SDO_POINT_TYPE(562043.03,1013121.22,0.009),NULL,NULL)
  *             5 SDO_GEOMETRY(3301,90000006,SDO_POINT_TYPE(562048.013,1013121.633,0.009),NULL,NULL)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_OffsetPoint(p_ratio     IN Number,
                                 p_offset    IN Number,
                                 p_unit      IN Varchar2 Default NULL)
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

 /****m* T_SEGMENT/ST_OffsetBetween
  *  NAME
  *    ST_OffsetBetween - Computes offset point on the bisector between two vertices.
  *  SYNOPSIS
  *    Member Function ST_OffsetBetween(p_segment   in number,
  *                                     p_offset    in number,
  *                                     p_unit      In Integer Default NULL)
  *             Return &&INSTALL_SCHEMA..T_Vertex Deterministic
  *  DESCRIPTION
  *    Supplied with a second segment (p_segment), this function computes the bisector
  *    between the two segments and then creates a new vertex at a distance of p_offset
  *    from the intersection point.  If an offset value of 0.0 is supplied, the
  *    intersection point is returned. If the p_offset value is <> 0, the function computes a new
  *    position for the point at a distance of p_offset on the left (-ve) or right (+ve) side
  *    of the segment.
  *    The returned vertex's ordinate values are rounded using the supplied tolerance.
  *  ARGUMENTS
  *    p_segment (number) - A segment that touches the current segment at one end point.
  *    p_offset       (number) - The perpendicular distance to offset the point generated using p_ratio.
  *                              A negative value instructs the function to offet the point to the left (start-end),
  *                              and a positive value to the right.
  *    p_unit       (varchar2) - If NULL, the calculations are done using the underlying projection default units.
  *                              If an Oracle Unit of Measure is supplied (eg unit=M) that is value for the SRID,
  *                            - this value is used when calculating the p_offset distance.
  *  RESULT
  *    point        (T_Vertex) - New point on bisection point or along bisector line with optional perpendicular offset.
  *  EXAMPLE
  *    -- Planar
  *    With data as (
  *     select SDO_GEOMETRY(3302,90000006,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(561981.279,1013120.171,0.00, 562044.981,1013076.691,77.1))  as sGeom,
  *            SDO_GEOMETRY(3302,90000006,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(562044.981,1013076.691,77.1, 562024.253,1013138.371,142.2)) as nGeom
  *      from dual
  *    )
  *    select 3                  as dims,
  *           CAST('Start Segment'
  *                as
  *                varchar2(30)) as description,
  *           a.sGeom            as offsetBetween
  *      from data a
  *      Union All
  *    select 3                  as dims,
  *           CAST('Next Segment'
  *                as
  *                varchar2(30)) as description,
  *           a.nGeom            as offsetBetween
  *      from data a
  *      Union All
  *    select a.sGeom.get_dims() as dims,
  *           CAST('Offset Point @' || t.IntValue
  *                as
  *                varchar2(30)) as description,
  *           T_Segment(a.sGeom)
  *             .ST_OffsetBetween(
  *                 p_segment => T_Segment(a.nGeom),
  *                 p_offset       => t.IntValue,
  *                 p_unit         => 'unit=M')
  *           .ST_Round(3)
  *           .ST_SdoGeometry() as OffsetBetween
  *      from data a,
  *          table(tools.generate_series(-5,5,5)) t;
  *
  *    DIMS DESCRIPTION       OFFSETBETWEEN
  *    ---- ----------------- ----------------------------------------------------------------------------------------------------------------------------------------
  *       3 Start Segment     SDO_GEOMETRY(3302,90000006,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(561981.279,1013120.171,0,562044.981,1013076.691,77.1))
  *       3 Next Segment      SDO_GEOMETRY(3302,90000006,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(562044.981,1013076.691,77.1,562024.253,1013138.371,142.2))
  *       3 Offset Point @-5  SDO_GEOMETRY(3301,90000006,SDO_POINT_TYPE(562041.963,1013080.677,77.1),NULL,NULL)
  *       3 Offset Point @0   SDO_GEOMETRY(3301,90000006,SDO_POINT_TYPE(562044.981,1013076.691,77.1),NULL,NULL)
  *       3 Offset Point @5   SDO_GEOMETRY(3301,90000006,SDO_POINT_TYPE(562047.999,1013072.705,77.1),NULL,NULL)
  *
  *    -- Geodetic
  *    With data as (
  *     select SDO_GEOMETRY(3302,4326,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(147.7868589596,-45.0326616056,0.0, 147.7876729555,-45.0330473956,77.1)) as sGeom,
  *            SDO_GEOMETRY(3302,4326,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(147.7876729555,-45.0330473956,77.1, 147.787402221,-45.032494027,142.2)) as nGeom
  *      from dual
  *    )
  *    select 3                  as dims,
  *           CAST('Start Segment'
  *                as
  *                varchar2(20)) as description,
  *           a.sGeom            as offsetBetween
  *      from data a
  *      Union All
  *    select 3                  as dims,
  *           CAST('Next Segment'
  *                as
  *                varchar2(20)) as description,
  *           a.nGeom            as offsetBetween
  *      from data a
  *      Union All
  *    select a.sGeom.get_dims() as dims,
  *           CAST('Offset Point @' || t.IntValue
  *                as
  *                varchar2(20)) as description,
  *           T_Segment(a.sGeom)
  *             .ST_OffsetBetween(
  *                 p_segment => T_Segment(a.nGeom),
  *                 p_offset       => t.IntValue,
  *                 p_unit         => 'unit=M') -- if 3D geodetic, compute as planar otherwise Oracle error
  *           .ST_Round(8)
  *           .ST_SdoGeometry() as OffsetBetween
  *      from data a,
  *          table(tools.generate_series(-5,5,5)) t;
  *
  *    DIMS DESCRIPTION      OFFSETBETWEEN
  *    ---- ---------------- ------------------------------------------------------------------------------------------------------------------------------------------------
  *       3 Start Segment    SDO_GEOMETRY(3302,4326,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(147.7868589596,-45.0326616056,0,147.7876729555,-45.0330473956,77.1))
  *       3 Next Segment     SDO_GEOMETRY(3302,4326,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(147.7876729555,-45.0330473956,77.1,147.787402221,-45.032494027,142.2))
  *       3 Offset Point @-5 SDO_GEOMETRY(2001,4326,SDO_POINT_TYPE(147.78763353,-45.03301215,NULL),NULL,NULL)
  *       3 Offset Point @0  SDO_GEOMETRY(3301,4326,SDO_POINT_TYPE(147.78767296,-45.0330474,77.1),NULL,NULL)
  *       3 Offset Point @5  SDO_GEOMETRY(2001,4326,SDO_POINT_TYPE(147.78771238,-45.03308265,NULL),NULL,NULL)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_OffsetBetween(p_segment   In &&INSTALL_SCHEMA..T_SEGMENT,
                                   p_offset    In NUMBER,
                                   p_unit       In Varchar2 Default NULL)
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

 /****m* T_SEGMENT/ST_PointAlong
  *  NAME
  *    ST_PointAlong -- Computes the vertex that lies a given fraction along the line defined by this segment.
  *  SYNOPSIS
  *    Member Function ST_pointAlong(segmentLengthFraction in Number)
  *             Return &&INSTALL_SCHEMA..T_Vertex deterministic
  *  DESCRIPTION
  *    A fraction of <code>0.0</code> returns the start point of the segment;
  *    a fraction of <code>1.0</code> returns the end point of the segment.
  *    If the fraction is null; 0.0 or null; 1.0 the point returned
  *    will lie before the start or beyond the end of the segment. 
  *  INPUTS
  *    p_segmentLengthFraction (number) -- The fraction of the segment length along the line
  *  RESULT
  *    Returns the vertex at that distance along the segment
  *  EXAMPLE
  *    select &&INSTALL_SCHEMA..T_Segment(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,1,1)))
  *                .ST_PointAlong(p_segmentLengthFraction=>0.5)
  *                .ST_SdoGeometry() as mPoint
  *      from dual;
  *               
  *    MPOINT
  *    --------------------------------------------------------------------
  *    SDO_GEOMETRY(2001, NULL, SDO_POINT_TYPE(0.5, 0.5, NULL), NULL, NULL)
  *    
  *    select &&INSTALL_SCHEMA..T_Segment(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,1,1)))
  *                .ST_PointAlong(p_segmentLengthFraction=>0.9)
  *                .ST_SdoGeometry() as mPoint
  *      from dual;
  *               
  *    MPOINT
  *    --------------------------------------------------------------------
  *    SDO_GEOMETRY(2001, NULL, SDO_POINT_TYPE(0.9, 0.9, NULL), NULL, NULL)
  *    
  *    select &&INSTALL_SCHEMA..T_Segment(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,2),sdo_ordinate_array(0,0,10,10,20,0)))
  *                .ST_PointAlong(p_segmentLengthFraction=>0.5)
  *                .ST_SdoGeometry() as mPoint
  *      from dual;
  *    
  *    MPOINT
  *    ------------------------------------------------------------------
  *    SDO_GEOMETRY(2001, NULL, SDO_POINT_TYPE(10, 10, NULL), NULL, NULL)
  *  NOTES
  *    From JTS LineSegment.java
  *    2D only; no circular arcs.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_pointAlong(p_segmentLengthFraction in Number)
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

 /****m* T_SEGMENT/ST_PointAlongOffset
  *  NAME
  *    ST_PointAlongOffset -- Computes the vertex that lies a given fraction along the line defined by this segment and offset from the segment by a given distance.
  *  SYNOPSIS
  *    Member Function ST_pointAlongOffset(
  *                       p_segmentLengthFraction in Number, 
  *                       p_offsetDistance in Number
  *                    )
  *             Return &&INSTALL_SCHEMA..T_Vertex deterministic
  *  DESCRIPTION
  *    A fraction of 0.0 offsets from the start point of the segment;
  *    a fraction of 1.0 offsets from the end point of the segment.
  *    The computed point is offset to the left of the line if the offset distance is
  *    positive, to the right if negative.
  *  INPUTS
  *    p_segmentLengthFraction (number) -- The fraction of the segment length along the line
  *    p_offsetDistance        (number) -- The distance the point is offset from the segment (positive is to the left, negative is to the right)
  *  RESULT
  *    Returns the vertex at that distance and offset along the segment
  *  NOTES
  *    From JTS LineSegment.java
  *    2D only; no circular arcs.
  *    Throws Exception if the segment has zero length
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_PointAlongOffset(
                     p_segmentLengthFraction in Number, 
                     p_offsetDistance in Number
                  )
          Return &&INSTALL_SCHEMA..T_Vertex deterministic,

/****f* T_SEGMENT/ST_ComputeDeflectionAngle
 *  NAME
 *   ST_ComputeDeflectionAngle - Computes deflection angle between two segments.
 *  SYNOPSIS
 *    Member Function ST_ComputeDeflectionAngle
 *             p_segment   t_segment default null,
 *           )
 *      Return Number
 *  DESCRIPTION
 *    This function computes the deflection angle between two segments: SELF.start->(bearing)->SELF.end deflect p_segment.start->(bearing)->p_segment.end
 *    The deflection angle from the projection of the first line to the direction(bearing) of the first line.
 *    If the underlying segment is a circular arc, p_segment is ignored and a deflection angle is computed between the circular arc's three vertices.
 *    If p_segment is supplied its first coordinate is assumed to be the same as the last point of SELF; if not a "virtual" deflection is computed.
 *    If SELF.projected = 0 deflection angle is computed using geodetic math (see MDSYS.SDO_UTIL.BEARING_TILT_FOR_POINTS)
 *  INPUTS
 *    p_segment (t_segment) - A linestring segment
 *  RESULT
 *    angle        (number) - Deflection angle in degrees.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - April 2019 - Original coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
  Member Function ST_ComputeDeflectionAngle(p_segment in &&INSTALL_SCHEMA..t_segment default null)
          return number deterministic,

 /****m* T_SEGMENT/ST_ComputeTangentPoint
  *  NAME
  *    ST_ComputeTangentPoint -- Computes point that would define a tandential line at the start, mid or end point of a circular arc
  *  SYNOPSIS
  *    Member Function ST_ComputeTangentPoint(p_position  In VarChar2,
  *                                           p_fraction  In Number   default 0.0,
  *                                           p_unit      IN varchar2 default NULL)
  *             Return T_Vertex Deterministic,
  *  DESCRIPTION
  *    There is a need to be able to compute an angle between a linestring and a circularstring.
  *    To do this, one needs to compute a tangential line at the start, mid, end or user fraction of a circularstring.
  *    This function computes point that would define a tangential line at the start, mid or end of a circular arc.
  *  INPUTS
  *    p_position (varchar2) -- Requests tangent point for 'START', 'MID', 'END' point, or 'FRACTION' of circular arc.
  *    p_fraction   (number) -- Fractional value between 0.0 and 1.0 (length)
  *    p_unit     (varchar2) -- If NULL, the calculations are done using the underlying projection default units.
  *                             If an Oracle Unit of Measure is supplied (eg unit=M) that is value for the SRID.
  *  RESULT
  *    point      (T_Vertex) -- A tangent point that combined with the start, mid or end of the circularstring creates a tangential line.
  *  EXAMPLE
  *    select T_Segment(
  *             p_Segment_id => 0,
  *             p_startCoord => T_Vertex(
  *                               p_id        =>  1,
  *                               p_x         => 10,
  *                               p_y         =>  0,
  *                               p_sdo_gtype => 2001,
  *                               p_sdo_srid  => NULL
  *                             ),
  *             p_midCoord   => T_Vertex(
  *                               p_id        =>  2,
  *                               p_x         => 15,
  *                               p_y         =>  5,
  *                               p_sdo_gtype => 2001,
  *                               p_sdo_srid  => NULL
  *                             ),
  *             p_endCoord   => T_Vertex(
  *                               p_id        =>  3,
  *                               p_x         => 20,
  *                               p_y         =>  0,
  *                               p_sdo_gtype => 2001,
  *                               p_sdo_srid  => NULL
  *                             ),
  *             p_sdo_gtype  => 2002,
  *             p_sdo_srid   => NULL
  *           )
  *           .ST_ComputeTangentPoint(p_position =>'START')
  *           .ST_AsText() as tangentPoint
  *      from dual;
  *
  *    TANGENTPOINT
  *    ------------------------------------
  *    T_Vertex(10,5,NULL,NULL,1,2001,NULL)
  *
  *    -- Circular String all points tangent
  *    with data as (
  *      select T_Segment(
  *               SDO_GEOMETRY('CIRCULARSTRING(252230.478 5526918.373, 252400.08 5526918.373, 252230.478 5527000.0)',null)
  *             ) as circular_string
  *        from dual
  *    )
  *    select a.circular_string.ST_SdoGeometry() as geom
  *      from data a
  *     union all
  *    select b.circular_string
  *            .ST_ComputeTangentPoint(
  *                 p_position=>cast(case t.IntValue
  *                                  when 1 then 'START'
  *                                  when 2 then 'MID'
  *                                  when 3 then 'END'
  *                                  end as varchar(5))
  *            ).ST_SdoGeometry() as geom
  *      from data b,
  *           table(tools.generate_series(1,3,1)) t;
  *
  *    GEOM
  *    -------------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(252230.478,5526918.373,252400.08,5526918.373,252230.478,5527000))
  *    SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(252189.6645,5527003.174,NULL),NULL,NULL)
  *    SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(252440.8935,5527003.174,NULL),NULL,NULL)
  *    SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(252189.6645,5526915.199,NULL),NULL,NULL)
  *
  *    -- Fraction
  *    select CAST(t.IntValue as number) / 10.0 as fraction,
  *           T_Segment(
  *             p_Segment_id => 0,
  *             p_startCoord => T_Vertex(
  *                               p_id        =>  1,
  *                               p_x         => 10,
  *                               p_y         =>  0,
  *                               p_sdo_gtype => 2001,
  *                               p_sdo_srid  => NULL
  *                             ),
  *             p_midCoord   => T_Vertex(
  *                               p_id        =>  2,
  *                               p_x         => 15,
  *                               p_y         =>  5,
  *                               p_sdo_gtype => 2001,
  *                               p_sdo_srid  => NULL
  *                             ),
  *             p_endCoord   => T_Vertex(
  *                               p_id        =>  3,
  *                               p_x         => 20,
  *                               p_y         =>  0,
  *                               p_sdo_gtype => 2001,
  *                               p_sdo_srid  => NULL
  *                             ),
  *             p_sdo_gtype  => 2002,
  *             p_sdo_srid   => NULL
  *           )
  *           .ST_ComputeTangentPoint(p_position  =>'FRACTION',
  *                                   p_fraction  => CAST(t.IntValue as number) / 10.0)
  *           .ST_Round(3)
  *           .ST_SdoGeometry() as tangentPoint
  *      from table(tools.generate_series(0,10,1)) t;
  *
  *      FRACTION TANGENTPOINT
  *    ---------- -------------------------------------------------------------------
  *             0 SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(10,-2.5,NULL),NULL,NULL)
  *           0.1 SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(9.472,-0.833,NULL),NULL,NULL)
  *           0.2 SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(9.485,0.916,NULL),NULL,NULL)
  *           0.3 SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(10.039,2.576,NULL),NULL,NULL)
  *           0.4 SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(11.077,3.983,NULL),NULL,NULL)
  *           0.5 SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(12.5,5,NULL),NULL,NULL)
  *           0.6 SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(18.923,3.983,NULL),NULL,NULL)
  *           0.7 SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(19.961,2.576,NULL),NULL,NULL)
  *           0.8 SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(20.515,0.916,NULL),NULL,NULL)
  *           0.9 SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(20.528,-0.833,NULL),NULL,NULL)
  *             1 SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(20,-2.5,NULL),NULL,NULL)
  *
  *     11 rows selected
  *  NOTES
  *    If SELF.projected is 1 then calculations are PLANAR or PROJECTED, otherwise GEODETIC/GEOGRAPHIC.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *   Simon Greener - June 2011 - Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_ComputeTangentPoint(p_position  In VarChar2,
                                         p_fraction  In Number   default 0.0,
                                         p_unit      IN varchar2 default NULL)
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

 /****m* T_SEGMENT/ST_ComputeTangentLine
  *  NAME
  *    ST_ComputeTangentLine -- Computes point that would define a tangential line at the nominated position on the circular arc
  *  SYNOPSIS
  *    Member Function ST_ComputeTangentLine(p_position  in VarChar2,
  *                                          p_fraction  In Number   default 0.0,
  *                                          p_unit      IN varchar2 default NULL)
  *             Return T_Segment Deterministic,
  *  DESCRIPTION
  *    There is a need to be able to create a tangent line at any point on a circular arc.
  *    This function computes a tangential line at the start/mid or end coord.
  *  INPUTS
  *    p_position (varchar2) -- Requests tangent point for 'START', 'MID', 'END' point, or 'FRACTION' of circular arc.
  *    p_fraction   (number) -- Fractional value between 0.0 and 1.0 (length)
  *    p_unit     (varchar2) -- If NULL, the calculations are done using the underlying projection default units.
  *                             If an Oracle Unit of Measure is supplied (eg unit=M) that is value for the SRID.
  *  RESULT
  *    line      (T_Segment) -- A tangent line.
  *  EXAMPLE
  *    with data as (
  *      select T_Segment(
  *               SDO_GEOMETRY('CIRCULARSTRING(252230.478 5526918.373, 252400.08 5526918.373, 252230.478 5527000.0)',null)
  *             ) as circular_string
  *        from dual
  *    )
  *    select a.circular_string.ST_SdoGeometry() as geom
  *      from data a
  *     union all
  *    select b.circular_string
  *            .ST_ComputeTangentLine(
  *                p_position=>case t.IntValue
  *                            when 1 then 'START'
  *                            when 2 then 'MID'
  *                            when 3 then 'END'
  *                            end
  *            ).ST_SdoGeometry() as geom
  *      from data b,
  *           table(tools.generate_series(1,3,1)) t;
  *
  *    GEOM
  *    ----------------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(252230.478,5526918.373, 252400.08,5526918.373, 252230.478,5527000.0))
  *    SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(252230.478,5526918.373, 252250.88475,5526875.9725))
  *    SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(252400.08,5526918.373, 252420.48675,5526960.7735))
  *    SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(252230.478,5527000.0, 252250.88475,5527042.4005))
  *
  *    -- Fraction.
  *    with data as (
  *      select T_Segment(
  *               SDO_GEOMETRY('CIRCULARSTRING(252230.478 5526918.373, 252400.08 5526918.373, 252230.478 5527000.0)',28355)
  *             ) as circular_string
  *        from dual
  *    )
  *    select CAST(NULL AS Number) as fraction,
  *           a.circular_string.ST_SdoGeometry() as geom
  *      from data a
  *     union all
  *    select CAST(t.IntValue as number) / 10.0 as fraction,
  *           b.circular_string
  *            .ST_ComputeTangentLine(
  *                p_position  =>'FRACTION',
  *                p_fraction  => CAST(t.IntValue as number) / 10.0,
  *                p_unit      => 'unit=M' )
  *           .ST_Round(3)
  *           .ST_SdoGeometry() as tangentLine
  *      from data b,
  *           table(tools.generate_series(0,10,1)) t;
  *
  *      FRACTION GEOM
  *    ---------- --------------------------------------------------------------------------------------------------------------------------------------------
  *          NULL SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(252230.478,5526918.373,252400.08,5526918.373,252230.478,5527000))
  *             0 SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(252230.478,5526918.373,252250.885,5526875.973))
  *           0.1 SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(252221.549,5526967.649,252217.318,5526920.784))
  *           0.2 SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(252239.159,5527014.529,252211.488,5526976.469))
  *           0.3 SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(252278.323,5527045.738,252235.047,5527027.261))
  *           0.4 SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(252327.951,5527052.441,252281.324,5527058.777))
  *           0.5 SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(252373.991,5527032.738,252337.215,5527062.094))
  *           0.6 SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(252403.406,5526992.209,252419.918,5526948.146))
  *           0.7 SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(252407.868,5526942.33,252399.44,5526896.035))
  *           0.8 SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(252386.114,5526897.224,252355.132,5526861.806))
  *           0.9 SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(252344.302,5526869.662,252299.54,5526855.151))
  *             1 SDO_GEOMETRY(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(252294.273,5526867.449,252248.404,5526877.953))
  *
  *     12 rows selected
  *  NOTES
  *    If SELF.projected is 1 then calculations are PLANAR or PROJECTED, otherwise GEODETIC/GEOGRAPHIC.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *   Simon Greener - June 2011 - Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
  Member Function ST_ComputeTangentLine(p_position  in VarChar2,
                                        p_fraction  In Number   default 0.0,
                                        p_unit      IN varchar2 default NULL)
           Return &&INSTALL_SCHEMA..T_Segment Deterministic,

  /****m* T_SEGMENT/ST_Intersect2CircularArcs
  *  NAME
  *    ST_Intersect2CircularArcs -- Computes intersecton point between two 2D CircularArc segments.
  *  SYNOPSIS
  *    Member Function ST_Intersect2CircularArcs(
  *                       p_segment   in &&INSTALL_SCHEMA..T_Segment,
  *                       p_unit      in varchar2 default NULL)
  *             Return &&INSTALL_SCHEMA..T_Segment Deterministic(
  *  DESCRIPTION
  *    This function computes the intersection point between the underlying circularArc segment and the provided circularArc segment.
  *    If one of the segments is a LineString, ST_Intersect is called.
  *  ARGUMENTS
  *    p_segment  (T_Segment) -- CircularArc Segment that is to be intersected with the current CircularArc object (SELF).
  *    p_unit      (varchar2) -- Oracle Unit of Measure for functions such as SDO_DISTANCE.
  *  RESULT
  *    intersection (T_Vertex) -- The intersection point.
  *  EXAMPLE
  *    select &&INSTALL_SCHEMA..t_segment(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,2),sdo_ordinate_array(0,0,10,10,20,0)))
  *                .ST_Intersect2CircularArcs(
  *                    p_segment => &&INSTALL_SCHEMA..t_segment(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,2),SDO_ORDINATE_ARRAY(9.959,-0.004, 14.719,5.245, 8.133,13.623))),
  *                    p_unit    => null)
  *                .ST_Round(3) as intersection
  *      from dual;
  *
  *    INTERSECTION
  *    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    &&INSTALL_SCHEMA..T_SEGMENT(NULL,NULL,1,&&INSTALL_SCHEMA..T_VERTEX(14.477,8.942,NULL,NULL,1,2001,NULL,0),NULL,&&INSTALL_SCHEMA..T_VERTEX(1.189,4.729,NULL,NULL,3,2001,NULL,0),2002,NULL,1,&&INSTALL_SCHEMA..T_PRECISIONMODEL(3,3,3,0.005))
  *  NOTES
  *    Two intersections are returned for the two possible points where two circles defined by CircularArcs intersect.
  *    Calculations are always planar.
  *  TODO
  *    Enable calculation of intersection between geodetic/geographic segments.
  *    Return only the actual intersections.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *   Simon Greener - 2011 - Original Coding nuary 2018\
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Intersect2CircularArcs(p_segment   in &&INSTALL_SCHEMA..T_Segment,
                                            p_unit      in varchar2 default NULL)
           Return &&INSTALL_SCHEMA..T_Segment Deterministic,

  /****m* T_SEGMENT/ST_IntersectCircularArc
  *  NAME
  *    ST_IntersectCircularArc -- Computes intersecton point between a CircularArc and a LineString segment.
  *  SYNOPSIS
  *    Member Function ST_IntersectCircularArc(
  *                       p_segment   in &&INSTALL_SCHEMA..T_Segment,
  *                       p_unit      in varchar2 default NULL)
  *             Return &&INSTALL_SCHEMA..T_Segment Deterministic(
  *  DESCRIPTION
  *    This function computes the intersection point between a CircularArc and a LineString.
  *    If both of the segments is a LineString, ST_Intersect is called.
  *  ARGUMENTS
  *    p_segment  (T_Segment) -- CircularArc Segment that is to be intersected with the current CircularArc object (SELF).
  *    p_unit      (varchar2) -- Oracle Unit of Measure for functions such as SDO_DISTANCE.
  *  RESULT
  *    intersection (T_Vertex) -- The intersection point.
  *  EXAMPLE
  *    select &&INSTALL_SCHEMA..t_segment(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,2),sdo_ordinate_array(0,0,10,10,20,0)))
  *                .ST_IntersectCircularArc(
  *                    p_segment => &&INSTALL_SCHEMA..t_segment(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),SDO_ORDINATE_ARRAY(10,0,10,12))),
  *                    p_unit    => null)
  *                .ST_Round(3)
  *                .ST_SdoGeometry() as intersection
  *      from dual;
  *    
  *    INTERSECTION
  *    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  *    MDSYS.SDO_GEOMETRY(2002,NULL,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1),MDSYS.SDO_ORDINATE_ARRAY(10,-10,0,0))
  *  NOTES
  *    Two intersections are returned for the two possible points where two circles defined by CircularArcs intersect.
  *    Calculations are always planar.
  *  TODO
  *    Fix as result is incorrect.
  *    Enable calculation of intersection between geodetic/geographic segments.
  *    Return only the actual intersections.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *   Simon Greener - 2011 - Original Coding nuary 2018\
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_IntersectCircularArc(p_segment   in &&INSTALL_SCHEMA..T_Segment,
                                          p_unit      in varchar2 default NULL)
           Return &&INSTALL_SCHEMA..T_Segment Deterministic,

  /****m* T_SEGMENT/ST_Intersect
  *  NAME
  *    ST_Intersect -- Computes intersection point between two 2D or 3D segments, returning a single intersection vertex.
  *  SYNOPSIS
  *    Member Function ST_Intersect(p_segment   IN T_SEGMENT,
  *                                 p_unit      IN varchar2 default NULL)
  *             Return T_Vertex Deterministic,
  *  DESCRIPTION
  *    This function computes the intersection point between the underlying 2D/3D segment and the provided 2D/3D segment.
  *    The intersection point computed is always physical ie a physical intersection or an empty vertex is returned if no intersection is computed.
  *    If segments are parallel an empty T_VERTEX is returned with T_VERTEX.id set to -9.
  *    Intersection between a linestring segment and circular arc segment is supported.
  *    However, the intersection between two circular arc segments is not yet supported.
  *  INPUTS
  *    p_segment (T_Segment) -- Second segment for which an intersection with current is computed.
  *    p_unit     (varchar2) -- Oracle Unit of Measure eg unit=M.
  *  RESULT
  *    Intersection (T_Vertex) -- The intersection point or empty point with id = -9 for parallel segments.
  *  EXAMPLE
  *    select T_Segment(
  *             p_Segment_id => 0,
  *             p_startCoord => T_Vertex(
  *                               p_id        =>  1,
  *                               p_x         => 10,
  *                               p_y         =>  0,
  *                               p_sdo_gtype => 2001,
  *                               p_sdo_srid  => NULL
  *                             ),
  *             p_endCoord   => T_Vertex(
  *                               p_id        =>  3,
  *                               p_x         => 20,
  *                               p_y         =>  0,
  *                               p_sdo_gtype => 2001,
  *                               p_sdo_srid  => NULL
  *                             ),
  *             p_sdo_gtype  => 2002,
  *             p_sdo_srid   => NULL
  *           )
  *           .ST_Intersect(p_segment =>
  *           .ST_AsText() as Intersection3D
  *      from dual;
 *
  *    INTERSECTION3D
  *    ------------------------------------
  *    T_Vertex(10,5,NULL,NULL,1,2001,NULL)
 *
  *    -- ST_Intersect of line segment and circular arc segment
  *    With data As (
  *    SELECT SDO_GEOMETRY('CIRCULARSTRING(252230.478 5526918.373, 252400.08 5526918.373, 252230.478 5527000.0)',null) as cString,
  *           SDO_GEOMETRY('LINESTRING(252257.745 5526951.808, 252438.138 5526963.252)',null) as lString
  *      FROM Dual
  *    )
  *    select t_geometry(SDO_GEOM.SDO_Intersection(cString,lString,0.005),0.005,3,1)
  *             .ST_Round(3,3,1)
  *             .geom as iGeom,
  *           T_Segment(lString)
  *             .ST_Intersect(T_Segment(cString),3)
  *             .ST_Round(3)
  *             .ST_SdoGeometry() as iPoint
  *      from data a;
 *
  *    IGEOM
  *    IPOINT
  *    -------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(252409.364,5526961.427))
  *    SDO_GEOMETRY(2001,NULL,                                    SDO_POINT_TYPE(252409.364,5526961.427,NULL),NULL,NULL)
 *
  *     -- ST_Intersect two 3D segments: No intersection in Z
  *     with data as (
  *     select sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(  0,0, 500, 100,100,1000)) as line1,
  *            sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(100,0,1000,   0,100, 501)) as line2
  *       from dual
  *     )
  *     select f.intersection.ST_IsNull() as intersectAlwaysNull,
  *            f.intersection.id          as intersectMarker,
  *            f.intersection.ST_AsText() as IntersectCoordValues
  *       from (select T_Segment(line1)
  *                      .ST_Intersect(
  *                          T_Segment(line2)
  *                      ) as intersection
  *               from data a
  *            ) f;
 *
  *     INTERSECTALWAYSNULL INTERSECTMARKER INTERSECTCOORDVALUES
  *     ------------------- --------------- ----------------------------------------
  *                       1             -99 T_Vertex(NULL,NULL,NULL,NULL,-99,1,NULL)
 *
  *     -- ST_Intersect 3D has intersection in Z
  *     -- Compare to SDO_GEOM.SDO_Intersection
  *     with data as (
  *     select sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,  0, 0, 100,100,10)) as line1,
  *            sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,100,10, 100,  0, 0)) as line2
  *       from dual
  *     )
  *     select sdo_geom.sdo_intersection(line1,line2,0.005) as geom from data
  *     union all
  *     select T_Segment(line1)
  *            .ST_Intersect(
  *                T_Segment(line2)
  *            )
  *            .ST_Round(3,3)
  *            .ST_SdoGeometry(3) as int3D
  *       from data a;
 *
  *     GEOM
  *     ---------------------------------------------------------------------------------------------
  *     SDO_GEOMETRY(3001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(50,50,0))
  *     SDO_GEOMETRY(3001,NULL,                                    SDO_POINT_TYPE(50,50,5),NULL,NULL)
  *  NOTES
  *    Calculations are always planar.
  *    3D computations use T_Vector3D object methods.
  *  TODO
  *    Enable calculation of intersection between geodetic/geographic segments.
  *    Support intersections including circular arcs
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *   Simon Greener - June 2011 - Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Intersect(p_segment   IN &&INSTALL_SCHEMA..T_SEGMENT,
                               p_unit      IN varchar2 default NULL)
           Return &&INSTALL_SCHEMA..T_Segment Deterministic,

  /****m* T_SEGMENT/ST_IntersectDetail
  *  NAME
  *    ST_IntersectDetail -- Computes intersecton point between two 2D segments.
  *  SYNOPSIS
  *    Member Function ST_IntersectDetail(p_segment   in T_SEGMENT,
  *                                       p_unit      in varchar2 default NULL)
  *             Return T_Vertex Deterministic,
  *  DESCRIPTION
  *    This function computes the intersection point between the underlying segment and the provided segment.
  *    If segments are parallel an empty T_VERTEX is returned with T_VERTEX.id set to -9.
  *    The intersection point is always returned in startCoord of returned T_Segment.
  *    This version of ST_Intersect returns details about the nature of the Intersection.
  *    These details include the coding of the returned midCoord and endCoords as follows:
  *    1.  If intersection is physical both are set to startCoord (cf ST_Intersect).
  *    2.  If intersection is physical in SELF but virtual in p_segment, midCoord is set to physical intersection point, and endCoord is set to projected (virtual) point from p_segment.
  *    3.  If intersection is physical in p_segment but virtual in SELF, midCoord is set to projected (virtual) point from SELF, and endCoord is set to physical intersection point in p_segment.
  *    4.  If intersection is virtual in p_segment and SELF, midCoord and endCoord are both set to virtual point (same as startCoord).
  *  ARGUMENTS
  *    p_segment  (T_Segment) -- Segment that is to be intersections with current object (SELF).
  *    p_unit      (varchar2) -- Oracle Unit of Measure for functions such as SDO_DISTANCE.
  *  RESULT
  *    intersection (T_Vertex) -- The intersection point or empty point with id = -9 for parallel segments.
  *  EXAMPLE
  *    select T_Segment(
  *             p_Segment_id => 0,
  *             p_startCoord => T_Vertex(
  *                               p_id        =>  1,
  *                               p_x         => 10,
  *                               p_y         =>  0,
  *                               p_sdo_gtype => 2001,
  *                               p_sdo_srid  => NULL
  *                             ),
  *             p_endCoord   => T_Vertex(
  *                               p_id        =>  3,
  *                               p_x         => 20,
  *                               p_y         =>  0,
  *                               p_sdo_gtype => 2001,
  *                               p_sdo_srid  => NULL
  *                             ),
  *             p_sdo_gtype  => 2002,
  *             p_sdo_srid   => NULL
  *           )
  *           .ST_IntersectDetail(p_segment =>
  *           .ST_AsText() as Intersection
  *      from dual;
 *
  *    INTERSECTION
  *    ------------------------------------
  *    T_Vertex(10,5,NULL,NULL,1,2001,NULL)
 *
  *    select T_Segment(
  *             sdo_geometry('LINESTRING(0 0,10 10)',null)
  *           ).ST_IntersectDetail(
  *                T_Segment(
  *                  sdo_geometry('LINESTRING(0 10,10 0)',null)
  *                )
  *            ).ST_AsText() as iPoint
  *      from dual;
 *
  *    IPOINT
  *    -----------------------------------------
  *    SEGMENT(NULL,NULL,1,
  *            Start(5,5,NULL,NULL,0,2001,NULL),
  *            Mid(5,5,NULL,NULL,-1,2001,NULL),
  *            End(5,5,NULL,NULL,-2,2001,NULL),
  *            SDO_GTYPE=2002,SDO_SRID=NULL)
 *
  *    -- Physical 1, virtual 2
  *    select T_Segment(
  *             sdo_geometry('LINESTRING(0 0,10 0)',null)
  *           ).ST_IntersectDetail(
  *                T_Segment(
  *                  sdo_geometry('LINESTRING(-5 10,-2 7)',null)
  *                )
  *            ).ST_AsText() as iPoint
  *      from dual;
 *
  *    IPOINT
  *    -----------------------------------------
  *    SEGMENT(NULL,NULL,1,
  *            Start(5,0,NULL,NULL,0,2001,NULL),
  *            Mid(5,0,NULL,NULL,-1,2001,NULL),
  *            End(-2,7,NULL,NULL,-2,2001,NULL),
  *            SDO_GTYPE=2002,SDO_SRID=NULL)
 *
  *     -- Virtual 1, Virtual 2
  *    select T_Segment(
  *             sdo_geometry('LINESTRING(10 10,5 5)',null)
  *           ).ST_IntersectDetail(
  *                T_Segment(
  *                  sdo_geometry('LINESTRING(-10 10,-5 5)',null)
  *                )
  *            ).ST_AsText() as iPoint
  *      from dual;
 *
  *    IPOINT
  *    -----------------------------------------
  *    SEGMENT(NULL,NULL,1,
  *            Start(0,0,NULL,NULL,0,2001,NULL),
  *            Mid(5,5,NULL,NULL,-1,2001,NULL),
  *            End(-5,5,NULL,NULL,-2,2001,NULL),
  *            SDO_GTYPE=2002,SDO_SRID=NULL)
 *
  *    -- Parallel
  *    select T_Segment(
  *             sdo_geometry('LINESTRING(10 10,0 10)',null)
  *           ).ST_IntersectDetail(
  *                T_Segment(
  *                  sdo_geometry('LINESTRING(-10 5,-5 5)',null)
  *                )
  *            ).ST_AsText() as iPoint
  *      from dual;
 *
  *    IPOINT
  *    -----------------------------------------
  *    SEGMENT(NULL,NULL,1,
  *            Start(,,NULL,NULL,-9,2001,NULL),
  *            Mid(,,NULL,NULL,NULL,2001,NULL),
  *            End(,,NULL,NULL,NULL,2001,NULL),
  *            SDO_GTYPE=2002,SDO_SRID=NULL)
  *  NOTES
  *    Calculations are always planar.
  *  TODO
  *    Enable calculation of intersection between geodetic/geographic segments.
  *    Support intersections including circular arcs
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *   Simon Greener - June 2011 - Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_IntersectDetail(p_segment   IN &&INSTALL_SCHEMA..T_SEGMENT,
                                     p_unit      IN VarChar2 default NULL)
           Return &&INSTALL_SCHEMA..T_Segment deterministic,

  /****m* T_SEGMENT/ST_IntersectDescription
  *  NAME
  *    ST_IntersectDescription -- Interprets intersection that results from a call to STIntersectionDetail with same parameter values.
  *  SYNOPSIS
  *    Member Function ST_IntersectDescription(p_segment    in T_SEGMENT,
  *                                            p_unit       in varchar2 default NULL)
  *             Return T_Vertex Deterministic,
  *  DESCRIPTION
  *    Describes intersection point between two lines.
  *    Internal code is same as STIntersectionDetail with same parameters so see its documentation.
  *    Determines intersections as per STIntersectionDetail but determines nature of intersection ie whether physical, virtual, nearest point on segment etc.
  *    Returned interpretation is one of:
  *      Intersection at End 1 End 2
  *      Intersection at End 1 Start 2
  *      Intersection at Start 1 End 2
  *      Intersection at Start 1 Start 2
  *      Intersection within both segments
  *      Parallel
  *      Unknown
  *      Virtual Intersection Near End 1 and End 2
  *      Virtual Intersection Near End 1 and Start 2
  *      Virtual Intersection Near Start 1 and End 2
  *      Virtual Intersection Near Start 1 and Start 2
  *      Virtual Intersection Within 1 and Near End 2
  *      Virtual Intersection Within 1 and Near Start 2
  *      Virtual Intersection Within 2 and Near End 1
  *      Virtual Intersection Within 2 and Near Start 1
  *  ARGUMENTS
  *    p_segment  (T_Segment) -- Segment that is to be intersections with current object (SELF).
  *    p_unit      (varchar2) -- Oracle Unit of Measure for functions such as SDO_DISTANCE.
  *  RESULT
  *    intersection (varchar2) -- Intersection description as in DESCRIPTION above.
  *  EXAMPLE
  *    select T_Segment(
  *             p_Segment_id => 0,
  *             p_startCoord => T_Vertex(
  *                               p_id        =>  1,
  *                               p_x         => 10,
  *                               p_y         =>  0,
  *                               p_sdo_gtype => 2001,
  *                               p_sdo_srid  => NULL
  *                             ),
  *             p_endCoord   => T_Vertex(
  *                               p_id        =>  3,
  *                               p_x         => 20,
  *                               p_y         =>  0,
  *                               p_sdo_gtype => 2001,
  *                               p_sdo_srid  => NULL
  *                             ),
  *             p_sdo_gtype  => 2002,
  *             p_sdo_srid   => NULL
  *           )
  *           .ST_IntersectDescription(p_segment =>
  *           .ST_AsText() as Intersection
  *      from dual;
 *
  *    INTERSECTION
  *    ------------------------------------
  *    T_Vertex(10,5,NULL,NULL,1,2001,NULL)
 *
  *    select T_Segment(
  *             sdo_geometry('LINESTRING(0 0,10 10)',null)
  *           ).ST_IntersectDescription(
  *                T_Segment(
  *                  sdo_geometry('LINESTRING(0 10,10 0)',null)
  *                )
  *            ).ST_AsText() as iPoint
  *      from dual;
 *
  *    IPOINT
  *    -----------------------------------------
  *    SEGMENT(NULL,NULL,1,
  *            Start(5,5,NULL,NULL,0,2001,NULL),
  *            Mid(5,5,NULL,NULL,-1,2001,NULL),
  *            End(5,5,NULL,NULL,-2,2001,NULL),
  *            SDO_GTYPE=2002,SDO_SRID=NULL)
 *
  *    -- Physical 1, virtual 2
  *    select T_Segment(
  *             sdo_geometry('LINESTRING(0 0,10 0)',null)
  *           ).ST_IntersectDescription(
  *                T_Segment(
  *                  sdo_geometry('LINESTRING(-5 10,-2 7)',null)
  *                )
  *            ).ST_AsText() as iPoint
  *      from dual;
 *
  *    IPOINT
  *    -----------------------------------------
  *    SEGMENT(NULL,NULL,1,
  *            Start(5,0,NULL,NULL,0,2001,NULL),
  *            Mid(5,0,NULL,NULL,-1,2001,NULL),
  *            End(-2,7,NULL,NULL,-2,2001,NULL),
  *            SDO_GTYPE=2002,SDO_SRID=NULL)
 *
  *     -- Virtual 1, Virtual 2
  *    select T_Segment(
  *             sdo_geometry('LINESTRING(10 10,5 5)',null)
  *           ).ST_IntersectDescription(
  *                T_Segment(
  *                  sdo_geometry('LINESTRING(-10 10,-5 5)',null)
  *                )
  *            ).ST_AsText() as iPoint
  *      from dual;
 *
  *    IPOINT
  *    -----------------------------------------
  *    SEGMENT(NULL,NULL,1,
  *            Start(0,0,NULL,NULL,0,2001,NULL),
  *            Mid(5,5,NULL,NULL,-1,2001,NULL),
  *            End(-5,5,NULL,NULL,-2,2001,NULL),
  *            SDO_GTYPE=2002,SDO_SRID=NULL)
 *
  *    -- Parallel
  *    select T_Segment(
  *             sdo_geometry('LINESTRING(10 10,0 10)',null)
  *           ).ST_IntersectDescription(
  *                T_Segment(
  *                  sdo_geometry('LINESTRING(-10 5,-5 5)',null)
  *                )
  *            ).ST_AsText() as iPoint
  *      from dual;
 *
  *    IPOINT
  *    -----------------------------------------
  *    SEGMENT(NULL,NULL,1,
  *            Start(,,NULL,NULL,-9,2001,NULL),
  *            Mid(,,NULL,NULL,NULL,2001,NULL),
  *            End(,,NULL,NULL,NULL,2001,NULL),
  *            SDO_GTYPE=2002,SDO_SRID=NULL)
  *  NOTES
  *    Calculations are always planar.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - March 2018 - Original TSQL Coding for SQL Server.
  *    Simon Greener - June 2011 - Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_IntersectDescription(p_segment    IN &&INSTALL_SCHEMA..T_SEGMENT,
                                          p_unit       IN VarChar2 Default NULL)
           Return varchar2 deterministic,



 /****m* T_SEGMENT/ST_LineSubstring
  *  NAME
  *    ST_LineSubstring -- Creates a new segment by cutting out the line defined by p_start_fraction and p_end_fraction.
  *  SYNOPSIS
  *    Member Function ST_LineSubstring(p_start_fraction In Number   Default 0.0,
  *                                     p_end_fraction   In Number   Default 1.0,
  *                                     p_unit           In Varchar2 Default NULL)
  *             Return &&INSTALL_SCHEMA..T_Segment Deterministic
  *  DESCRIPTION
  *    Supplied with two ratio values between (0.0 -> 1.0), this function uses those values to find the
  *    points along its segment where they lie. If offset values of 0.0 and 1.0 are supplied, the underlying
  *    segment is returned. Otherwise, the function finds the position of the point defined by p_start_fraction
  *    and the point defined by p_end_fraction and creates a new segment based on those points.
  *    For circular arcs a new midCoord is created at position p_start_fraction + (p_end_fraction-p_start_Fraction)/2.0.
  *    If p_start_fraction == p_end_fraction a single point is returned in the T_Segment's startCoord with the others being NULL.
  *    The substring operation uses length and not LRS measure.
  *    Any Z and M ordinates are calculated by ratio.
  *  ARGUMENTS
  *    p_start_fraction (Number) -- A value between 0 and 1, from the start vertex of the segment,
  *                                 which describes the position of the first point in the substring.
  *    p_end_fraction   (Number) -- A value > p_start_fraction, from the start vertex of the segment,
  *                                 which describes the position of the last point in the substring.
  *    p_unit         (Varchar2) -- If NULL, the calculations are done using the underlying projection default units.
  *                                 If an Oracle Unit of Measure is supplied (eg unit=M) that is value for the SRID,
  *                                 this value is used when calculating the p_offset distance.
  *  RESULT
  *    segment  (T_Segment)  - - New segment between the start and end measures.
  *  EXAMPLE
  *    -- Substring of XYZ LineString.
  *    With data as (
  *     select SDO_GEOMETRY(3002,90000006,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),
  *                         SDO_ORDINATE_ARRAY(562046.642,1013077.602,0, 562032.193,1013252.074,0.035)) as geom
  *      from dual
  *    )
  *    select T_Segment(a.geom)
  *             .ST_LineSubstring(p_start_fraction => 0.25,
  *                               p_end_fraction   => 0.75,
  *                               p_unit           => 'unit=M'
  *              )
  *             .ST_Round(3)
  *             .ST_SdoGeometry() as substring
  *      from data a;
  *
  *    SUBSTRING
  *    ---------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3302,90000006,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(562043.03,1013121.22,0.009,562035.805,1013208.456,0.026))
  *
  *    -- Fractions equal...
  *    With data as (
  *     select SDO_GEOMETRY(3302,90000006,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),
  *                         SDO_ORDINATE_ARRAY(562046.642,1013077.602,0, 562032.193,1013252.074,0.035)) as geom
  *      from dual
  *    )
  *    select T_Segment(a.geom)
  *             .ST_LineSubstring(p_start_fraction => 0.5,
  *                               p_end_fraction   => 0.5,
  *                               p_unit           => 'unit=M'
  *              )
  *             .ST_Round(3)
  *             .ST_SdoGeometry() as substring
  *      from data a;
  *
  *    SUBSTRING
  *    ----------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3301,90000006,SDO_POINT_TYPE(562039.418,1013164.838,0.018),NULL,NULL)
  *
  *    -- Geodetic.
  *    With data as (
  *     select sdo_geometry(2002,4326,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(147.50,-43.132,147.41,-43.387)) as geom
  *       from dual
  *       union all
  *     select sdo_geometry(3302,4326,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(147.50,-43.132,100.0,147.41,-43.387,30000.0)) as geom
  *       from dual
  *       union all
  *      select sdo_geometry(3002,4326,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(147.50,-43.132,100.0, 147.41,-43.387,30000.0)) as geom
  *        from dual
  *    )
  *    select T_Segment(a.geom)
  *             .ST_LineSubstring(p_start_fraction => 0.5,
  *                               p_end_fraction   => 0.9,
  *                               p_unit           => 'unit=M'
  *              )
  *             .ST_Round(8)
  *             .ST_SdoGeometry() as substring
  *      from data a;
  *
  *    SUBSTRING
  *    -------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2002,4326,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(147.455,-43.2595,147.419,-43.3615))
  *    SDO_GEOMETRY(3302,4326,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(147.455,-43.2595,15050,147.419,-43.3615,27010))
  *    SDO_GEOMETRY(3002,4326,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(147.455,-43.2595,15050,147.419,-43.3615,27010))
  *
  *    -- Circular Arc line string
  *    With data as (
  *      select sdo_geometry(2002,NULL,NULL,
  *                          sdo_elem_info_array(1,2,2),
  *                          sdo_ordinate_array(252230.478,5526918.373, 252400.08,5526918.373,252230.478,5527000.0)) as geom
  *        from dual
  *    )
  *    select T_Segment(a.geom)
  *             .ST_LineSubstring(p_start_fraction => 0.25,
  *                               p_end_fraction   => 0.75,
  *                               p_unit           => 'unit=M'
  *              )
  *             .ST_Round(3)
  *             .ST_SdoGeometry() as substring
  *      from data a;
  *
  *    SUBSTRING
  *    ------------------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(252256.627,5527032.786,252373.991,5527032.738,252400.046,5526918.303))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LineSubstring(p_start_fraction In Number   Default 0.0,
                                   p_end_fraction   In Number   Default 1.0,
                                   p_unit           In Varchar2 Default NULL)
           Return &&INSTALL_SCHEMA..T_Segment Deterministic,

  /****m* T_SEGMENT/ST_UpdateCoordinate(p_vertex)
  *  NAME
  *    ST_UpdateCoordinate -- Function which updates the start, mid or end coordinate depending on p_which.
  *  SYNOPSIS
  *    Member Function ST_UpdateCoordinate(p_coordinate in &&INSTALL_SCHEMA..T_Vertex,
  *                                        p_which      in varchar2 default 'S' )
  *             Return &&INSTALL_SCHEMA..T_SEGMENT Deterministic,
  *  DESCRIPTION
  *    Function that updates start, mid or end coordinate the underlying T_Segment which value in p_coordinate depending on position identified by p_which.
  *    p_which can have one of 6 values. See Arguments.
  *  ARGUMENTS
  *    p_coordinate (T_Vertex) -- Replacement coordinate which must not be null otherwise T_Segment is unchanged.
  *    p_which      (varchar2) -- Can be one of the following values:
  *                               - NULL : defaults to 'S'
  *                               - 'S' or '1' : StartCoord
  *                               - 'M' or '2' :   midCoord
  *                               - 'E' or '3' :   endCoord
  *  RESULT
  *    updated segment (T_Segment) - Geometry with coordinate replaced.
  *  EXAMPLE
  *    select T_Segment(
  *             p_Segment_id => 0,
  *             p_startCoord => T_Vertex(
  *                               p_id        =>  1,
  *                               p_x         => 10,
  *                               p_y         =>  0,
  *                               p_sdo_gtype => 2001,
  *                               p_sdo_srid  => NULL
  *                             ),
  *             p_endCoord   => T_Vertex(
  *                               p_id        =>  3,
  *                               p_x         => 20,
  *                               p_y         =>  0,
  *                               p_sdo_gtype => 2001,
  *                               p_sdo_srid  => NULL
  *                             ),
  *             p_sdo_gtype  => 2002,
  *             p_sdo_srid   => NULL
  *           )
  *           .ST_UpdateCoordinate(
  *                p_coordinate => T_Vertex(
  *                  p_x         => 99.0,
  *                  p_y         => 100.0,
  *                  p_id        => 1,
  *                  p_sdo_gtype => 2001,
  *                  p_sdo_srid  => NULL),
  *                p_which => 1
  *           )
  *           .startCoord
  *           .ST_AsText() as updatedSegment
  *       from dual;
 *
  *    UPDATEDSEGMENT
  *    --------------------------------------
  *    T_Vertex(99,100,NULL,NULL,1,2001,NULL)
 *
  *    -- Create midCoord where doesn't exist.
  *    select T_Segment(
  *             p_Segment_id => 0,
  *             p_startCoord => T_Vertex(
  *                               p_id        =>  1,
  *                               p_x         => 10,
  *                               p_y         =>  0,
  *                               p_sdo_gtype => 2001,
  *                               p_sdo_srid  => NULL
  *                             ),
  *             p_endCoord   => T_Vertex(
  *                               p_id        =>  3,
  *                               p_x         => 20,
  *                               p_y         =>  0,
  *                               p_sdo_gtype => 2001,
  *                               p_sdo_srid  => NULL
  *                             ),
  *             p_sdo_gtype  => 2002,
  *             p_sdo_srid   => NULL
  *           )
  *           .ST_UpdateCoordinate(
  *                p_coordinate => T_Vertex(
  *                  p_x         => 99.0,
  *                  p_y         => 100.0,
  *                  p_id        => 2,
  *                  p_sdo_gtype => 2001,
  *                  p_sdo_srid  => NULL),
  *                p_which => '2'
  *           )
  *           .ST_AsText() as updatedSegment
  *       from dual;
 *
  *    UPDATEDSEGMENT
  *    ------------------------------------------
  *    SEGMENT(NULL,NULL,0,
  *            Start(10,0,NULL,NULL,1,2001,NULL),
  *            Mid(99,100,NULL,NULL,2,2001,NULL),
  *            End(20,0,NULL,NULL,3,2001,NULL),
  *            SDO_GTYPE=2002,SDO_SRID=NULL)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - December 2006 - Original Coding for GEOM package.
  *    Simon Greener - July 2011     - Port to T_GEOMETRY.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_UpdateCoordinate(p_coordinate in &&INSTALL_SCHEMA..T_Vertex,
                                      p_which      in varchar2 default 'S' /*M,E*/)
           Return &&INSTALL_SCHEMA..T_SEGMENT Deterministic,

  /****m* T_SEGMENT/ST_SdoGeometry
  *  NAME
  *    ST_SdoGeometry -- Returns segment as a suitably encoded MDSYS.SDO_GEOMETRY object.
  *  SYNOPSIS
  *    Member Function ST_SdoGeometry(p_dims in integer default null)
  *             Return MDSYS.sdo_geometry Deterministic,
  *  DESCRIPTION
  *    Geometry depends on how the segment is described (vertex-connected or circular arc).
  *    Also, p_dims can force 3D linestring to be returned as a 2D linestring.
  *  ARGUMENTS
  *    p_dims in integer default null - A dimension value that will override SELF.ST_Dims() eg to return 2D from a 3D segment.
  *  RESULT
  *    linestring (MDSYS.SDO_GEOMETRY) -- Two (or three) point linestring.
  *  EXAMPLE
  *    select T_Segment(
  *             p_segment_id => 0,
  *             p_startCoord => t_Vertex(
  *                               p_id=>1,
  *                               p_x=>0.0023763,
  *                               p_y=>0.18349,
  *                               p_z=>1.346,
  *                               p_w=>0.001,
  *                               p_sdo_gtype=>4401,
  *                               p_sdo_srid=>NULL
  *                             ),
  *             p_EndCoord   => T_Vertex(
  *                               p_id=>2,
  *                               p_x=>10.87365,
  *                               p_y=>11.983645,
  *                               p_z=>1.984,
  *                               p_w=>14.386,
  *                               p_sdo_gtype=>4401,
  *                               p_sdo_srid=>NULL
  *                             ),
  *             p_sdo_gtype=>4402,
  *             p_sdo_srid=>NULL
  *          ).ST_SdoGeometry() as geom
  *     from dual;
  *
  *    GEOM
  *    -----------------------------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(4402,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0.0023763,0.18349,1.346,0.001,10.87365,11.983645,1.984,14.386))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_SdoGeometry(p_dims in integer default null)
           Return mdsys.sdo_geometry Deterministic,

  /****m* T_SEGMENT/ST_Round(x y z m)
  *  NAME
  *    ST_Round -- Rounds X,Y,Z and m(w) ordinates of segment's coordinates to passed in precision.
  *  SYNOPSIS
  *    Member Function ST_Round(p_dec_places_x in integer,
  *                             p_dec_places_y in integer default NULL,
  *                             p_dec_places_z in integer default 3,
  *                             p_dec_places_m in integer default 3)
  *             Return &&INSTALL_SCHEMA..T_SEGMENT Deterministic,
  *  DESCRIPTION
  *    Applies relevant decimal digits of precision value to ordinate.
  *    For example:
  *      SELF.x := ROUND(SELF.x,p_dec_places_x);
  *  ARGUMENTS
  *    p_dec_places_x (integer) - value applied to x Ordinate.
  *    p_dec_places_y (integer) - value applied to y Ordinate.
  *    p_dec_places_z (integer) - value applied to z Ordinate.
  *    p_dec_places_m (integer) - value applied to m Ordinate.
  *  RESULT
  *    segment (T_SEGMENT)
  *  EXAMPLE
  *    with data as (
  *      select sdo_geometry(4402,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0.0023763,0.18349,1.3456,0.0005, 10.87365,11.983645,1.98434,14.38573)) as geom
  *        From Dual
  *       Union all
  *      select sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0.0023763,0.18349,1.3456,10.87365,11.983645,1.98434)) as geom
  *        From Dual
  *       Union all
  *      select sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0.0023763,0.18349,       10.87365,11.983645        )) as geom
  *        from dual
  *    )
  *    select T_Segment(a.geom)
  *             .ST_Round(p_dec_places_x=>3,
  *                       p_dec_places_y=>3,
  *                       p_dec_places_z=>1,
  *                       p_dec_places_m=>2
  *              ).ST_SdoGeometry() as rGeom
  *     from data a;
  *
  *    RGEOM
  *    -------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(4402,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0.002,0.183,1.3,0,10.874,11.984,2,14.39))
  *    SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0.002,0.183,1.3,10.874,11.984,2))
  *    SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0.002,0.183,10.874,11.984))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Round(p_dec_places_x In integer,
                           p_dec_places_y In integer Default null,
                           p_dec_places_z In integer Default 3,
                           p_dec_places_m In integer Default 3)
           Return &&INSTALL_SCHEMA..T_SEGMENT Deterministic,

  /****m* T_SEGMENT/ST_Round
  *  NAME
  *    ST_Round -- Rounds X,Y,Z and m(w) ordinates of segment's coordinates usoing object's PrecisionModel.
  *  SYNOPSIS
  *    Member Function ST_Round
  *             Return &&INSTALL_SCHEMA..T_SEGMENT Deterministic,
  *  DESCRIPTION
  *    Applies internal object's precisionModel decimal digits of precision value to ordinates of object.
  *    If internal PrecisionModel is null, the object is returned unchanged.
  *    If an internal PrecisionModel element is null the default values for the called ST_Round are applied.
  *  RESULT
  *    segment (T_SEGMENT) -- T_Segment with rounded ordinates using SELF.PrecisionModel values.
  *  NOTES
  *    Is wrapper over ST_Round( y, y, z, m );
  *  EXAMPLE
  *    with data as (
  *      select sdo_geometry(4402,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0.0023763,0.18349,1.3456,0.0005, 10.87365,11.983645,1.98434,14.38573)) as geom
  *        From Dual
  *       Union all
  *      select sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0.0023763,0.18349,1.3456,10.87365,11.983645,1.98434)) as geom
  *        From Dual
  *       Union all
  *      select sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0.0023763,0.18349,       10.87365,11.983645        )) as geom
  *        from dual
  *    )
  *    select T_Segment(a.geom)
  *             .ST_Round().ST_SdoGeometry() as rGeom
  *     from data a;
  *
  *    RGEOM
  *    -------------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(4402,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0.002,0.183,1.3,0,10.874,11.984,2,14.39))
  *    SDO_GEOMETRY(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0.002,0.183,1.3,10.874,11.984,2))
  *    SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0.002,0.183,10.874,11.984))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Round
           Return &&INSTALL_SCHEMA..T_Segment Deterministic,

  /****m* T_SEGMENT/ST_AsText
  *  NAME
  *    ST_AsText -- Returns text Description of underlying segment
  *  SYNOPSIS
  *    Member Function ST_AsText
  *             Return Varchar2 Deterministic,
  *  DESCRIPTION
  *    Returns textual description of segment.
  *  RESULT
  *    String - T_SEGMENT in text format.
  *  EXAMPLE
  *    with data as (
  *      select sdo_geometry(4402,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0.0023763,0.18349,1.3456,0.0005, 10.87365,11.983645,1.98434,14.38573)) as geom
  *        From Dual
  *       Union all
  *      select sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0.0023763,0.18349,1.3456,10.87365,11.983645,1.98434)) as geom
  *        From Dual
  *       Union all
  *      select sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0.0023763,0.18349,       10.87365,11.983645        )) as geom
  *        from dual
  *    )
  *    select T_Segment(a.geom).ST_AsText() as geomText
  *     from data a;
  *
  *    GEOMTEXT
  *    ------------------------------------------------------------------------------------------------------------------------------------------------
  *    SEGMENT(NULL,NULL,0,Start(1,.0023763,.18349,1.346,.001,4401,NULL),End(2,10.87365,11.983645,1.984,14.386,4401,NULL),SDO_GTYPE=4402,SDO_SRID=NULL)
  *    SEGMENT(NULL,NULL,0,Start(1,.0023763,.18349,1.346,NULL,3001,NULL),End(2,10.87365,11.983645,1.984,NULL,3001,NULL),SDO_GTYPE=3002,SDO_SRID=NULL)
  *    SEGMENT(NULL,NULL,0,Start(1,.0023763,.18349,NULL,NULL,2001,NULL),End(2,10.87365,11.983645,NULL,NULL,2001,NULL),SDO_GTYPE=2002,SDO_SRID=NULL)
  *  TODO
  *    Create Function, ST_FromText(), to create T_Segment from ST_AsText representation.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_AsText
           Return VarChar2 Deterministic,

  /****m* T_SEGMENT/ST_AsWKT
  *  NAME
  *    ST_AsWKT -- Exports T_SEGMENT object to its Extended Well Known Text (EWKT).
  *  SYNOPSIS
  *    Member Function ST_AsWKT
  *             Return varchar2 Deterministic,
  *  DESCRIPTION
  *    Returns Extended Well Known Text representation of underlying T_GEOEMTRY.
  *    Supports 2D/3D/4D t_segments.
  *    Formatting of ordinates supported by supplied p_format_model eg TM9 or FM999999999999990D0
  *  RESULT
  *    WKT (CLOB) -- eg Well Known Text encoding of mdsys.sdo_geometry object.
  *  EXAMPLE
  *    With data as (
  *     select t_segment(sdo_geometry(2002,28355,NULL,
  *                                  sdo_elem_info_array(1,2,2),
  *                                  sdo_ordinate_array(252230.4743434348,5526918.37343433, 252400.034348,5526918.33434333473,252230.4434343378,5527000.433445660))) as segment
  *     from dual union all
  *     select t_segment(SDO_GEOMETRY(3002,28355,NULL,
  *                                  sdo_elem_info_array(1,2,2),
  *                                  sdo_ordinate_array(252230.478,5526918.373,1.5, 252400.08,5526918.373,1.5, 252230.478,5527000.0,1.5))) as segment
  *     from dual union all
  *     select t_segment(SDO_GEOMETRY(3302,28355,NULL,
  *                                  sdo_elem_info_array(1,2,2),
  *                                  sdo_ordinate_array(252230.478,5526918.373,0.0, 252400.08,5526918.373,417.4, 252230.478,5527000.0,506.88))) as segment
  *     from dual union all
  *     select t_segment(SDO_GEOMETRY(4402,28355,NULL,
  *                                  sdo_elem_info_array(1,2,2),
  *                                  sdo_ordinate_array(252230.478,5526918.373,1.5,0.0, 252400.08,5526918.373,1.5,417.4, 252230.478,5527000.0,1.5,506.88))) as segment
  *     from dual union all
  *     select t_segment(sdo_geometry(2002,NULL,NULL,
  *                                   sdo_elem_info_array(1,2,1),
  *                                   sdo_ordinate_array(100,100,900,900.0))) as segment
  *     from dual union all
  *     select t_segment(sdo_geometry(3002,NULL,NULL,
  *                                   sdo_elem_info_array(1,2,1),
  *                                   sdo_ordinate_array(0,0,1, 10,0,2))) as segment
  *     from dual union all
  *     select t_segment(sdo_geometry(3302,NULL,NULL,
  *                                   sdo_elem_info_array(1,2,1),
  *                                   sdo_ordinate_array(0,0,1.5, 10,0,1.5, 10,5,1.5 ))) as segment
  *     from dual union all
  *     select t_segment(sdo_geometry(4402,4283,null,
  *                                   sdo_elem_info_array(1,2,1),
  *                                   sdo_ordinate_array(147.5,-42.5,849.9,102.0, 147.6,-42.5,1923.0,2100.0))) as segment
  *     From Dual
  *    )
  *    select a.segment.sdo_gtype as gtype,
  *         a.segment
  *          .ST_Round(3)
  *          .ST_AsEWKT('TM9') as ewkt
  *    from data a;
  *    
  *    GTYPE EWKT
  *    ----- ------------------------------------------------------------------------------------------------------------------------
  *     2002 SRID=28355;CIRCULARSTRING (252230.474 5526918.373,252400.034 5526918.334,252230.443 5527000.433)
  *     3002 SRID=28355;CIRCULARSTRINGZ (252230.478 5526918.373 1.5,252400.08 5526918.373 1.5,252230.478 5527000 1.5)
  *     3302 SRID=28355;CIRCULARSTRINGM (252230.478 5526918.373 0,252400.08 5526918.373 417.4,252230.478 5527000 506.88)
  *     4402 SRID=28355;CIRCULARSTRINGZM (252230.478 5526918.373 1.5 0,252400.08 5526918.373 1.5 417.4,252230.478 5527000 1.5 506.88)
  *     2002 LINESTRING (100 100,900 900)
  *     3002 LINESTRINGZ (0 0 1,10 0 2)
  *     3302 LINESTRINGM (0 0 1.5,10 0 1.5)
  *     4402 SRID=4283;LINESTRINGZM (147.5 -42.5 849.9 102,147.6 -42.5 1923 2100)
  *    
  *     8 rows selected
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_AsEWKT (p_format_model varchar2 default 'TM9')
           Return VarChar2 Deterministic,

  /****m* T_SEGMENT/ST_Equals
  *  NAME
  *    ST_Equals -- Compares current object (SELF) with supplied segment.
  *  SYNOPSIS
  *    Member Function ST_Equals(p_segment    in &&INSTALL_SCHEMA..T_SEGMENT,
  *                              p_coords     In Integer default 1)
  *             Return Integer deterministic
  *  DESCRIPTION
  *    This function compares current segment object (SELF) to supplied segment (p_vertex).
  *    If all ordinates (to supplied precision) are equal, returns True (1) else False (0).
  *    SDO_GTYPE, SDO_SRID and ID are not compared uinless p_coords = 0
  *  NOTES
  *    To compare all 4 ordinates, use ST_Round on both segments before calling ST_Equals
  *  ARGUMENTS
  *    p_segment  (T_Segment) -- Segment that is to be compared to current object (SELF).
  *    p_coords     (Integer) -- Boolean. If 1, only coordinates are compared; if 0, then all elements including segment_id etc are compared.
  *  RESULT
  *    BOOLEAN (INTEGER) - 1 is True (Equal); 0 is False.
  *  EXAMPLE
  *    set serveroutput on size unlimited
  *    Declare
  *      v_segment1 T_Segment;
  *      v_segment2 T_Segment;
  *    Begin
  *      v_segment1 :=
  *          T_Segment(
  *             p_segment_id => 0,
  *             p_startCoord => t_Vertex(
  *                               p_id=>1,
  *                               p_x=>0.0023763,
  *                               p_y=>0.18349,
  *                               p_z=>1.346,
  *                               p_w=>0.001,
  *                               p_sdo_gtype=>4401,
  *                               p_sdo_srid=>NULL
  *                             ),
  *             p_EndCoord   => T_Vertex(
  *                               p_id=>2,
  *                               p_x=>10.87365,
  *                               p_y=>11.983645,
  *                               p_z=>1.984,
  *                               p_w=>14.386,
  *                               p_sdo_gtype=>4401,
  *                               p_sdo_srid=>NULL
  *                             ),
  *             p_sdo_gtype=>4402,
  *             p_sdo_srid =>NULL
  *          );
  *      v_segment2 := T_Segment(v_segment1);
  *      v_segment2.segment_id := 2;
  *      dbms_output.put_line('Equals(With Metadata): ' ||
  *                             v_segment1.ST_Equals(p_segment    =>v_segment2,
  *                                                  p_coords     => 0 ));
  *      dbms_output.put_line('Equals(Only Coords): ' ||
  *                             v_segment1.ST_Equals(p_segment    =>v_segment2,
  *                                                  p_coords     => 1 ));
  *    END;
  *
  *    anonymous block completed
  *    Equals(With Metadata): 0
  *    Equals(Only Coords): 1
  *  TODO
  *    Consider extending to support precision for xy, z and W.
  *    Need to do so in all other objects (T_Geometry currently only supports SELF.precision not SELF.precision XY/Z/W).
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Equals(p_segment    in &&INSTALL_SCHEMA..T_SEGMENT,
                            p_coords     In Integer default 1)
           Return Number Deterministic,

  /****m* T_SEGMENT/OrderBy
  *  NAME
  *    OrderBy -- Implements ordering function that can be used to sort a collection of T_Vertex objects.
  *  SYNOPSIS
  *    Order Function OrderBy(p_segment in &&INSTALL_SCHEMA..T_SEGMENT)
  *            Return Number deterministic
  *  ARGUMENTS
  *    p_segment (T_SEGMENT) - Order pair
  *  DESCRIPTION
  *    This order by function allows a collection of T_Vertex objects to be sorted.
  *    For example in the ORDER BY clause of a SELECT statement.
  *    Comparison only uses ordinates: X, Y, Z and W.
  *    If precision is an issue, the two segments have to be rounded before this method can be used.
  *  EXAMPLE
  *    With segments as (
  *      select T_SEGMENT(p_segment_id=> LEVEL,
  *                       p_startCoord=>T_Vertex(p_x=>dbms_random.value(0,level),
  *                                              p_y=>dbms_random.value(0,level),
  *                                              p_id=>1,
  *                                              p_sdo_gtype=>2001,
  *                                              p_sdo_srid=>null),
  *                         p_endCoord=>T_Vertex(p_x=>dbms_random.value(0,level),
  *                                              p_y=>dbms_random.value(0,level),
  *                                              p_id=>2,
  *                                              p_sdo_gtype=>2001,
  *                                              p_sdo_srid=>null),
  *                         p_sdo_gtype=>3002,
  *                          p_sdo_srid=>null
  *             ) as segment
  *        from dual
  *        connect by level < 5
  *    )
  *    select a.segment.st_astext(2) as segment
  *      from segments a
  *     order by a.segment;
  *
  *    SEGMENT
  *    ---------------------------------------------------------------------------------------------------------------------------
  *    SEGMENT(NULL,NULL,1,Start(.51,.86,NULL,NULL,1,2001,NULL),End(.2,.43,NULL,NULL,2,2001,NULL),SDO_GTYPE=3002,SDO_SRID=NULL)
  *    SEGMENT(NULL,NULL,2,Start(1.3,1.31,NULL,NULL,1,2001,NULL),End(.96,1.56,NULL,NULL,2,2001,NULL),SDO_GTYPE=3002,SDO_SRID=NULL)
  *    SEGMENT(NULL,NULL,3,Start(.84,2.03,NULL,NULL,1,2001,NULL),End(.55,.23,NULL,NULL,2,2001,NULL),SDO_GTYPE=3002,SDO_SRID=NULL)
  *    SEGMENT(NULL,NULL,4,Start(2.69,1.34,NULL,NULL,1,2001,NULL),End(2.65,1.37,NULL,NULL,2,2001,NULL),SDO_GTYPE=3002,SDO_SRID=NULL)
  *
  *  4 rows selected
  *  RESULT
  *    order value (NUMBER) - -1 less than; 0 equal; 1 greater than
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Order Member Function OrderBy(p_segment in &&INSTALL_SCHEMA..T_SEGMENT)
                 Return Number Deterministic

)
INSTANTIABLE NOT FINAL;
/
SHOW ERRORS

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'T_SEGMENT';
BEGIN
   FOR rec IN (select object_name,object_Type, status
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'TYPE'
               order by object_type
              ) 
   LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is valid.');
      ELSE
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is invalid.');
         v_ok := false;
      END IF;
   END LOOP;
   execute immediate 'GRANT EXECUTE ON &&INSTALL_SCHEMA..' || v_obj_name || ' TO public WITH GRANT OPTION';
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

  /****s* OBJECT TYPE ARRAY/T_SEGMENTS
  *  NAME
  *    T_SEGMENTS -- An array (collection/table) of T_SEGMENT type.
  *  DESCRIPTION
  *    An array of T_SEGMENT that a PIPELINED function can use to return T_SEGMENT objects.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  *  SOURCE
  */
CREATE OR REPLACE TYPE &&INSTALL_SCHEMA..T_SEGMENTS
           AS TABLE OF &&INSTALL_SCHEMA..T_SEGMENT
  /*******/
/
show errors

grant execute on &&INSTALL_SCHEMA..T_Segments to public with grant option;

EXIT SUCCESS;

