DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;
SET SERVEROUTPUT ON

-- Always aim for a clean compile
ALTER SESSION SET PLSQL_WARNINGS='ERROR:ALL';
-- Enable optimizations
-- ALTER SESSION SET plsql_optimize_level=2;

CREATE OR REPLACE PACKAGE &&INSTALL_SCHEMA..COGO
AUTHID CURRENT_USER
As

/****h* PACKAGE/COGO 
*  NAME
*    COGO - A package that publishes some common COGO functions used by other object types.
*  DESCRIPTION
*    A package that publishes some common COGO functions used by other object types.
*  AUTHOR
*    Simon Greener
*  HISTORY
*    Simon Greener - Jan 2017 - Original coding.
*  COPYRIGHT
*    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
******/

  /****f* COGO/PI 
  *  NAME
  *    PI -- Returns constant PI value.
  *  SYNOPSIS
  *    Function PI
  *      Return Number Deterministic
  *  DESCRIPTION
  *    This function exposes static constant PI.
  *  EXAMPLE
  *    SELECT COGO.PI()
  *      FROM DUAL;
  *
  *                                  COGO.PI()
  *    ---------------------------------------
  *    3.1415926535897932384626433832795028842
  *  RESULT
  *    PI (NUMBER) - 3.1415926535897932384626433832795028842
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function PI Return Number deterministic; 

  /****f* COGO/ST_Degrees 
  *  NAME
  *    ST_Degrees -- Converts input radians to whole circle bearing (0 North).
  *  SYNOPSIS
  *    Function ST_Degrees(p_radians   in number, 
  *                        p_normalize in integer default 1) 
  *      Return Number deterministic
  *  DESCRIPTION
  *    This function converts supplied radians value to whole circle bearing clockwise from 0 as North.
  *    Also normalises bearing to 0..360 if requested.
  *  INPUTS
  *    p_radians    (Number) - Angle in radians (clockwise from north)
  *    p_normalize (Integer) - Normalises bearing to range 0..360 (defaul)
  *  RESULT
  *    degrees (NUMBER) - 0 to 360 degrees
  *  EXAMPLE
  *    SELECT Round(COGO.ST_Degrees(0.789491),4) as degrees
  *      FROM dual;
  *
  *       DEGREES
  *    ----------
  *       45.2345
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_Degrees(p_radians   in number, 
                      p_normalize in integer default 1) 
    Return number Deterministic;

  /****f* COGO/ArcTan2 
  *  NAME
  *    ArcTan2 -- Returns the angle in Radians with tangent opp/hyp. The returned value is between PI and -PI
  *  SYNOPSIS
  *    Function ArcTan2( dOpp in number,
  *                      dAdj in number)
  *      Return Number deterministic
  *  DESCRIPTION
  *    Returns the angle in Radians with tangent opp/hyp. The returned value is between PI and -PI.
  *  INPUTS
  *    dOpp : NUMBER : Length of the vector perpendicular to two vectors (cross product)
  *    dAdj : NUMBER : Length of the calculated from the dot product of two vectors
  *  RESULT
  *    number : The angle in Radians with tangent opp/hyp
  *  NOTES 
  *    Assumes planar projection eg UTM.
  *  EXAMPLE
  *    SELECT COGO.ArcTan2(14,15) as atan2
  *      FROM dual;
  *
  *    ATAN2
  *    ------------
  *    0.7509290624
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ArcTan2( dOpp in number,
                    dAdj in number)
    Return Number deterministic;

  /****f* COGO/ST_Normalize 
  *  NAME
  *    ST_Normalize -- Converts input degree value to whole circle bearing between 0..360.
  *  SYNOPSIS
  *    Function ST_Normalize(p_degrees in number)
  *      Return Number deterministic
  *  DESCRIPTION
  *    This function converts supplied degree value to whole circle bearing clockwise between 0..360.
  *  INPUTS
  *    p_degrees (Number) - Angle in degrees.
  *  RESULT
  *    degrees (Number) - 0 to 360 degrees
  *  EXAMPLE
  *    SELECT COGO.ST_Normalize(400) as degrees
  *      FROM dual;
  *
  *    DEGREES
  *    -------
  *         40
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_Normalize(p_degrees in number)
    Return Number Deterministic;

  /****f* COGO/ST_Radians 
  *  NAME
  *    ST_Radians -- Converts input whole circle bearing (0 North) to radians.
  *  SYNOPSIS
  *    Function ST_Radians(p_radians in number)
  *      Return Number deterministic
  *  INPUTS
  *    p_degrees (NUMBER) - Angle in degrees,  clockwise from North.
  *  DESCRIPTION
  *    This function converts supplied decimal degree value to radians.
  *  EXAMPLE
  *    SELECT Round(COGO.ST_Radians(45.2345),6) as radians
  *      FROM dual;
  *
  *       RADIANS
  *    ----------
  *       .789491
  *  RESULT
  *    radians (NUMBER) - 0 to 2 x PI radians.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function ST_Radians(p_degrees in number) Return number Deterministic;

  /****f* COGO/DMS2DD 
  *  NAME
  *    DMS2DD -- Returns decimal degree value from string input.
  *  SYNOPSIS
  *    Function DMS2DD(strDegMinSec varchar2) 
  *      Return Number Deterministic;
  *  INPUTS
  *    strDegMinSec (varchar2) - Angle in DMS format (quandrantal, whole circle or Cardinal bearing), with/without separators
  *  RESULT
  *    Decimal Degrees (NUMBER) - eg 22.16972222.
  *  DESCRIPTION
  *    This function converts a textual representation of a degree value to its decimal equivalent.
  *  EXAMPLE
  *    select COGO.DMS2DD('15°51''5.424"') as dd 
  *      from DUAL;
  *
  *    DD
  *    -----------------------------------------
  *    15.85150666666666666666666666666666666667
  *
  *    select COGO.DMS2DD('22^10''11"') as dd
  *      from DUAL;
  *
  *    DD
  *    -----------
  *    22.16972222 
  * 
  *    select COGO.DMS2DD('N22.1697E') as dd
  *     from DUAL;
  * 
  *    DD
  *    -----------
  *    22.16972222 
  *
  *    select COGO.DMS2DD('S52E') as dd 
  *      from dual;
  *
  *    DD
  *    --
  *    52
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function DMS2DD(strDegMinSec varchar2) 
    Return Number Deterministic;

  /****f* COGO/DD2DMS 
  *  NAME
  *    DD2DMS -- Returns string equivalent of decimal degree numeric value.
  *  SYNOPSIS
  *    Function DD2DMS(
  *                dDecDeg in Number,
  *                pDegree in NChar default '°',
  *                pMinute in NChar default '''',
  *                pSecond in NChar default '"' 
  *             )
  *      Return varchar2 Deterministic;
  *  INPUTS
  *    dDecDeg (Number) - Decimal degrees.
  *    pDegree (NChar)  - Superscript degree value identifier eg °
  *    pMinute (NChar)  - Superscript minute value identifier eg '
  *    pSecond (NChar)  - Superscript second value identifier eg " 
  *  RESULT
  *    Decimal Degrees (NUMBER) - eg 22.16972222.
  *  DESCRIPTION
  *    This function converts a numeric decimal degree value into its textual whole-circle bearing equivalent.
  *  EXAMPLE
  *    select COGO.DD2DMS(15.8515065952945,'^','''','"') as dms 
  *      from dual;
  *
  *    DMS
  *    ------------
  *    15^51'5.424"
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function DD2DMS(dDecDeg in Number,
                  pDegree in NChar default '°',
                  pMinute in NChar default '''',
                  pSecond in NChar default '"' )
    Return varchar2 Deterministic;

  /****f* COGO/DD2TIME 
  *  NAME
  *    DD2TIME -- Supplied with a whole-circle bearing, this function returns its equivalent ClockFace Direction eg 45 => 1hr 30min.
  *  SYNOPSIS
  *    Function DD2TIME(p_dDecDeg in Number,
  *                     p_24_hour in integer default 0)
  *      Return varchar2 Deterministic;
  *  ARGUMENTS
  *    p_dDecDeg (Number) -- Decimal degrees.
  *    p_24_hour (integer) -- 12 hour (0) readout or 24 (1)
  *  RESULT
  *    Time as string (varchar2) -- ClockFace time as direction 45 degrees is same as 1Hr 30min
  *  DESCRIPTION
  *    This function converts a whole circular bearing in decimal degrees to its equivalent ClockFace Direction eg 45 => 1hr 30min.
  *    Can return clockface directions as 12-14 hour references or 0-12 references.
  *  EXAMPLE
  *    select COGO.DD2TIME(t.IntValue,t12.IntValue) as clockface 
  *      from table(TOOLS.generate_series(0,360,45)) t,
  *           table(TOOLS.generate_series(0,1,1)) t12
  *     order by t12.IntValue, t.intValue;
  *    
  *    CLOCKFACE
  *    ----------
  *    0Hr 0min
  *    1Hr 30min
  *    3Hr 0min
  *    4Hr 30min
  *    6Hr 0min
  *    7Hr 30min
  *    9Hr 0min
  *    10Hr 30min
  *    12Hr 0min
  *    12Hr 0min
  *    13Hr 30min
  *    15Hr 0min
  *    16Hr 30min
  *    18Hr 0min
  *    19Hr 30min
  *    21Hr 0min
  *    22Hr 30min
  *    24Hr 0min
  *    
  *    18 rows selected 
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function DD2TIME(p_dDecDeg in Number,
                   p_24_hour in integer default 0)
    Return varchar2 Deterministic;

  /****f* COGO/CardinalDirection 
  *  NAME
  *    CardinalDirection -- Returns Compass point string equivalent of decimal degree numeric value.
  *  SYNOPSIS
  *    Function CardinalDirection(p_bearing      in number,
  *                               p_abbreviation in integer default 1)
  *      Return varchar2 Deterministic;
  *  INPUTS
  *    p_bearing       (Number) -- Decimal degrees.
  *    p_abbreviation (integer) -- Whether to return full text North (0) or abbreviation N (1), South West(0) or SW(1).
  *  RESULT
  *    Compass Point (varchar2) -- Compass point string for supplied bearing.
  *  DESCRIPTION
  *    This function converts a numeric decimal degree value into its textual Compass Point equivalent.
  *  EXAMPLE
  *    select COGO.CardinalDirection(15.8515065952945,t.IntValue) as CardinalDirection 
  *      from table(tools.generate_series(0,1,1)) t;
  *
  *    CARDINALDIRECTION
  *    -----------------
  *    NNE
  *    North-NorthEast
  *
  *    -- All Compass Points
  *    select COGO.DD2DMS(avg(t.IntValue))         as bearing,
  *           COGO.CardinalDirection(t.IntValue,0) as CardinalDirection,
  *           COGO.CardinalDirection(t.IntValue,1) as CardinalDirectionFull
  *      from table(tools.generate_series(1,360,1)) t
  *    group by COGO.CardinalDirection(t.IntValue,0),
  *             COGO.CardinalDirection(t.IntValue,1);
  *
  *    BEARING        CARDINALDIRECTION CARDINALDIRECTIONFULL
  *    -------------- ----------------- ----------------
  *    135°0'0"       SE                SouthEast
  *    187°49'33.913" N                 North
  *    90°0'0"        E                 East
  *    112°30'0"      ESE               East-SouthEast
  *    180°0'0"       S                 South
  *    315°0'0"       NW                NorthWest
  *    67°30'0"       ENE               East-NorthEast
  *    337°30'0"      NNW               North-NorthWest
  *    270°0'0"       W                 West
  *    157°30'0"      SSE               South-SouthEast
  *    202°30'0"      SSW               South-SouthWest
  *    292°30'0"      WNW               West-NorthWest
  *    225°0'0"       SW                SouthWest
  *    247°30'0"      WSW               West-SouthWest
  *    22°30'0"       NNE               North-NorthEast
  *    45°0'0"        NE                NorthEast
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function CardinalDirection(p_bearing      in number,
                             p_abbreviation in integer default 1)
    Return varchar2 Deterministic;

  /****f* COGO/QuadrantBearing 
  *  NAME
  *    QuadrantBearing -- Returns Quadrant Bearing string equivalent of decimal degree numeric value eg N34.5°E
  *  SYNOPSIS
  *    Function QuadrantBearing(p_bearing in number,
  *                             p_Degree  in NChar default '°')
  *      Return varchar2 Deterministic;
  *  INPUTS
  *    p_bearing (Number) -- Decimal degrees.
  *    p_degree  (NChar)  -- Degree Symbol Superscript.
  *  RESULT
  *    Quadrant Bearing (varchar2) -- Quadrant bearing eg N34.5°E
  *  DESCRIPTION
  *    This function converts a numeric decimal degree value into its textual Quadrant bearing equivalent.
  *  EXAMPLE
  *    select COGO.QuadrantBearing(15.8515065952945,'^') as quadrantBearing 
  *      from dual;
  *
  *    QUADRANTBEARING
  *    ---------------
  *          N15.852^E
  *    
  *    select COGO.DD2DMS(t.IntValue)          as bearing,
  *           COGO.QuadrantBearing(t.IntValue) as QuadrantBearing
  *      from table(tools.generate_series(0,315,45)) t
  *     order by t.IntValue asc;
  *    
  *    BEARING    QUADRANTBEARING
  *    ---------- ---------------
  *    0°0'0"     N
  *    45°0'0"    N45°E
  *    90°0'0"    E
  *    135°0'0"   S45°E
  *    180°0'0"   S
  *    225°0'0"   S45°W
  *    270°0'0"   W
  *    315°0'0"   N45°W 
  *    
  *     8 rows selected 
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function QuadrantBearing(p_bearing in number,
                           p_Degree  in NChar default '°')
    Return varchar2 Deterministic;

  Function ComputeArcLength(p_Radius in number,
                            p_Angle  in number)
    Return Number deterministic;

  Function GreatCircleBearing( p_lon1 in number,
                               p_lat1 in number,
                               p_lon2 in number,
                               p_lat2 in number)
    Return Number Deterministic;

END COGO;
/
show errors

Prompt Check Package has compiled correctly ...
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean      := FALSE;
   v_obj_name varchar2(30) := 'COGO';
BEGIN
   FOR rec IN (select object_name || '.' || object_Type as package_name, status 
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'PACKAGE'
              ) LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line(USER || '.' || rec.package_name || ' is valid.');
         v_ok := TRUE;
      ELSE
         dbms_output.put_line(USER || '.' || rec.package_name || ' is invalid.');
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
   EXECUTE IMMEDIATE 'GRANT EXECUTE ON &&INSTALL_SCHEMA..' || v_obj_name || ' TO public WITH GRANT OPTION';
END;
/
SHOW ERRORS

EXIT SUCCESS;

