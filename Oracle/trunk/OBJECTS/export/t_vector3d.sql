DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

CREATE OR REPLACE EDITIONABLE TYPE "&&INSTALL_SCHEMA."."T_VECTOR3D" 
AUTHID DEFINER
AS OBJECT (

/****t* OBJECT TYPE/T_VECTOR3D [1.0]
*  NAME
*    T_VECTOR3D -- Object type representing a mathematical segment
*  DESCRIPTION
*    An object type that represents a single mathematical segment.
*    Includes methods on segments.
*  AUTHOR
*    Simon Greener
*  HISTORY
*    Simon Greener - Jan 2015 - Original coding.
*  COPYRIGHT
*    (c) 2012-2018 by TheSpatialDBAdvisor/Simon Greener
******/

  /****v* T_VECTOR3D/ATTRIBUTES(T_VECTOR3D) [1.0]
  *  ATTRIBUTES
  *   x -- X Ordinate
  *   y -- Y Ordinate
  *   z -- Z Ordinate
  *  SOURCE
  */
   x number,
   y number,
   z number,
  /*******/

  /****m* T_VECTOR3D/CONSTRUCTORS(T_VECTOR3D) [1.0]
  *  NAME
  *    A collection of T_VECTOR3D Constructors.
  *  SOURCE
  */
  Constructor Function T_VECTOR3D( SELF      IN OUT NOCOPY T_VECTOR3D,
                                   p_SEGMENT IN &&INSTALL_SCHEMA..T_SEGMENT)
                Return Self As Result,

  Constructor Function T_VECTOR3D( SELF      IN OUT NOCOPY T_VECTOR3D,
                                   p_SEGMENT IN &&INSTALL_SCHEMA..T_VECTOR3D)
                Return Self As Result,

  Constructor Function T_VECTOR3D( SELF     IN OUT NOCOPY T_VECTOR3D,
                                   p_vertex IN &&INSTALL_SCHEMA..T_Vertex)
                Return Self As Result,

  Constructor Function T_VECTOR3D( SELF           IN OUT NOCOPY T_VECTOR3D,
                                   p_start_vertex IN &&INSTALL_SCHEMA..T_Vertex,
                                   p_end_vertex   IN &&INSTALL_SCHEMA..T_Vertex)
                Return Self As Result,
  /*******/

  /****m* T_VECTOR3D/Cross
  *  NAME
  *    Cross -- Creates a new segment that is the segment cross product of segments SELF and v1.
  *  SYNOPSIS
  *    Member Function Cross(v1 in &&INSTALL_SCHEMA..T_VECTOR3D)
  *             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,
  *  PARAMETERS
  *    v1 (T_Vector3D) - Second segment
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function Cross(v1 in &&INSTALL_SCHEMA..T_VECTOR3D)
             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,

  /****m* T_VECTOR3D/Normalize(t_vector3d)
  *  NAME
  *    Normalize -- Creates a new segment that is the value of this segment to the normalization of segment v1.
  *  SYNOPSIS
  *    Member Function Normalize(v1 in &&INSTALL_SCHEMA..T_VECTOR3D )
  *             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,
  *  PARAMETERS
  *    v1 (T_Vector3D) - param v1 the un-normalized segment
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function Normalize(v1 in &&INSTALL_SCHEMA..T_VECTOR3D )
             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,

  /****m* T_VECTOR3D/Normalize
  *  NAME
  *    Normalize -- Normalizes the current segment returning a new one.
  *  SYNOPSIS
  *    Member Function Normalize
  *             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function Normalize
    Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,

  /****m* T_VECTOR3D/Dot
  *  NAME
  *    Dot -- Returns the dot product of the current segment and the provided parameter.
  *  SYNOPSIS
  *    Member Function Dot(v1 in &&INSTALL_SCHEMA..T_VECTOR3D)
  *             Return Number Deterministic,
  *  PARAMETERS
  *    v1 (T_Vector3D) - Another segment
  *  RETURNS
  *    The dot product of this and v1
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function Dot(v1 in &&INSTALL_SCHEMA..T_VECTOR3D)
             Return Number Deterministic,

  /****m* T_VECTOR3D/MagnitudeSquared
  *  NAME
  *    MagnitudeSquared -- Returns the squared Magnitude of this segment.
  *  SYNOPSIS
  *    Member Function MagnitudeSquared
  *             Return Number Deterministic,
  *  RETURNS
  *    The squared Magnitude of this segment
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function MagnitudeSquared
             Return Number Deterministic,

  /****m* T_VECTOR3D/Magnitude
  *  NAME
  *    Magnitude -- Returns the Magnitude of this segment.
  *  SYNOPSIS
  * Member Function Magnitude
  *          Return Number Deterministic,
  *  RETURNS
  *    The Magnitude of this segment
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function Magnitude
             Return Number Deterministic,

  /****m* T_VECTOR3D/Distance(t_vector3d)
  *  NAME
  *    Distance -- Returns the distance between this T_VECTOR3D the specified point.
  *  SYNOPSIS
  *    Member Function Distance(p_point in &&INSTALL_SCHEMA..T_VECTOR3D)
  *             Return Number Deterministic,
  *  PARAMETERS
  *    p_point (T_Vector3D) - The point.
  *  RETURNS
  *    The distance between the segment and p_point.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function Distance(p_point in &&INSTALL_SCHEMA..T_VECTOR3D)
             Return Number Deterministic,

  /****m* T_VECTOR3D/Distance(t_vertex)
  *  NAME
  *    Distance -- Returns the distance between this T_VECTOR3D the specified point.
  *  SYNOPSIS
  *    Member Function Distance(p_point in &&INSTALL_SCHEMA..T_Vertex )
  *             Return Number Deterministic,
  *  PARAMETERS
  *    v1 (T_Vector3D) - Second segment
  *  RETURNS
  *    The distance between the segment and p_point.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function Distance(p_point in &&INSTALL_SCHEMA..T_Vertex )
             Return Number Deterministic,

  /****m* T_VECTOR3D/DistanceSquared(T_Vector3D)
  *  NAME
  *    DistanceSquared -- Returns the square of the distance between the specified points.
  *  SYNOPSIS
  *    Member Function DistanceSquared(p_point in &&INSTALL_SCHEMA..T_VECTOR3D)
  *             Return Number Deterministic,
  *  PARAMETERS
  *    p_point (T_Vector3D) - Point.
  *  RETURNS
  *    The square of the distance between the segment and point1.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function DistanceSquared(p_point in &&INSTALL_SCHEMA..T_VECTOR3D)
             Return Number Deterministic,

  /****m* T_VECTOR3D/DistanceSquared(t_vertex)
  *  NAME
  *    DistanceSquared -- Returns the square of the distance between the specified points.
  *  SYNOPSIS
  *    Member Function DistanceSquared(p_point in &&INSTALL_SCHEMA..T_Vertex)
  *             Return Number Deterministic,
  *  PARAMETERS
       p_point (T_Vertext) - The point.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function DistanceSquared(p_point in &&INSTALL_SCHEMA..T_Vertex)
             Return Number Deterministic,

  /****m* T_VECTOR3D/Angle
  *  NAME
  *    Angle -- Returns the angle in radians between this segment and the segment parameter; the return value is constrained to the range [0-PI].
  *  SYNOPSIS
  *    Member Function Angle(v1 in &&INSTALL_SCHEMA..T_VECTOR3D)
  *             Return Number Deterministic,
  *  PARAMETERS
  *    v1 (T_Vector3D) - Second segment
  *  RETURNS
  *    The angle in radians in the range [0-PI]
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function Angle(v1 in &&INSTALL_SCHEMA..T_VECTOR3D)
             Return Number Deterministic,

  /****m* T_VECTOR3D/Subtract
  *  NAME
  *    Subtract -- Sets the value of this segment to the segment difference of itself and segment (this = this - segment).
  *  SYNOPSIS
  *    Member Function Subtract(v1 in &&INSTALL_SCHEMA..T_VECTOR3D)
  *             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,
  *  PARAMETERS
  *    v1 (T_Vector3D) - Second segment
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function Subtract(v1 in &&INSTALL_SCHEMA..T_VECTOR3D)
             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,

  /****m* T_VECTOR3D/Multiply
  *  NAME
  *    Multiply -- Returns the components of the specified segment multiplied by the specified scalar.
  *  SYNOPSIS
  *    Member Function Multiply(p_scalar in Number)
  *             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,
  *  PARAMETERS
  *    p_scalar (number) - The scalar value.
  *  RETURNS
  *    The components of the value1 multiplied by the p_scalar
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function Multiply(p_scalar in Number)
             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,

  /****m* T_VECTOR3D/Divide
  *  NAME
  *    Divide -- Returns the components of the current segment divided by the specified scalar.
  *  SYNOPSIS
  *    Member Function Divide(p_scalar in Number)
  *             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,
  *  PARAMETERS
  *    p_scalar (number) - The scalar value.
  *  RETURNS
  *    The components of value1 divided by the p_scalar.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function Divide(p_scalar in Number)
             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,

  /****m* T_VECTOR3D/Negate
  *  NAME
  *    Negate -- Computes a segment with the same magnitude as SELF but pointing to the opposite direction.
  *  SYNOPSIS
  *    Member Function Negate
  *             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,
  *  RETURNS
  *    A segment with the same magnitude as SELF but pointing to the opposite
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function Negate
             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,

  /****m* T_VECTOR3D/AddV
  *  NAME
  *    AddV -- Constructs segment as segment sum of SELF and v1 parameter.
  *  SYNOPSIS
  *   Member Function AddV(v1 in &&INSTALL_SCHEMA..T_VECTOR3D)
  *            Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,
  *  PARAMETERS
       v1 (T_Vector3D) - Second segment
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
   Member Function AddV(v1 in &&INSTALL_SCHEMA..T_VECTOR3D)
            Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,

  /****m* T_VECTOR3D/ProjectOnLine(t_vector t_vector)
  *  NAME
  *    ProjectOnLine -- Computes the current segment projected on the specified line.
  *  SYNOPSIS
  *    Member Function ProjectOnLine(pointOnLine1 in &&INSTALL_SCHEMA..T_VECTOR3D,
  *                                  pointOnLine2 in &&INSTALL_SCHEMA..T_VECTOR3D)
  *             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,
  *  PARAMETERS
  *    Second segment
  *    pointOnLine1 (T_Vector3D) - A point on the line.
  *    pointOnLine2 (T_Vector3D) - A point on the line.
  *  RETURNS
  *    Value projected on the line defined by pointOnLine1 pointOnLine2.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function ProjectOnLine(pointOnLine1 in &&INSTALL_SCHEMA..T_VECTOR3D,
                                  pointOnLine2 in &&INSTALL_SCHEMA..T_VECTOR3D)
             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,

  /****m* T_VECTOR3D/ProjectOnLine(t_segment)
  *  NAME
  *    ProjectOnLine -- Computes the current segment projected on p_line.
  *  SYNOPSIS
  *    Member Function ProjectOnLine(p_line in &&INSTALL_SCHEMA..T_SEGMENT)
  *             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,
  *  PARAMETERS
  *    p_line (T_Segment) - Second segment
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
    Member Function ProjectOnLine(p_line in &&INSTALL_SCHEMA..T_SEGMENT)
             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,

  /****m* T_VECTOR3D/Zero
  *  NAME
  *    Zero -- Sets all the values in this segment to zero.
  *  SYNOPSIS
  *    Member Function zero
  *             Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
   Member Function Zero
            Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic,

  /****m* T_VECTOR3D/AsText
  *  NAME
  *    AsText -- Creates an textual representation of a T_VECTOR3D object.
  *  SYNOPSIS
  *    Member Function AsText(p_round IN integer DEFAULT 9)
  *             Return Varchar2 Deterministic,
  *  PARAMETERS
  *    p_round (integer) -- Value for use in ROUND to compare XYZ values.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function AsText(p_round IN integer DEFAULT 9)
           Return Varchar2 Deterministic,

  /****m* T_VECTOR3D/AsSdoGeometry
  *  NAME
  *    AsSdoGeometry -- Creates an SDO_GEOMETRY equivalent of T_VECTOR3D.
  *  SYNOPSIS
  *    Member Function AsSdoGeometry(p_srid in integer default null)
  *             Return mdsys.sdo_geometry Deterministic
  *  PARAMETERS
  *    p_srid (integer) - Value for sdo_geometry.sdo_srid.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2011 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
   Member Function AsSdoGeometry(p_srid in integer default null)
            Return mdsys.sdo_geometry Deterministic,

  /****m* T_VECTOR3D/Equals
  *  NAME
  *    Equals -- Compares two vectors for equality (in magnitude and direction)
  *  SYNOPSIS
  *    Member Function Equals(p_vector3D IN T_Vector3D)
  *             Return Integer Deterministic,
  *  PARAMETERS
  *    p_vector3D (t_vector3D) - Second vector for comparison with SELF (underlying)
  *  RETURNS
  *    True(1)/False(0) -- 1 if True, 0 if False.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function Equals(p_vector3D in &&INSTALL_SCHEMA..T_Vector3D)
           Return Integer Deterministic

)
INSTANTIABLE NOT FINAL;
/
show errors


