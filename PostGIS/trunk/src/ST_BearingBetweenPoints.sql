DROP   FUNCTION IF EXISTS spdba.ST_BearingBetweenPoints(numeric,numeric,numeric,numeric);
DROP   FUNCTION IF EXISTS spdba.ST_BearingBetweenPoints(geometry,geometry);

CREATE FUNCTION spdba.ST_BearingBetweenPoints (
  p_dE1 numeric,
  p_dN1 numeric,
  p_dE2 numeric,
  p_dN2 numeric
)
Returns numeric
AS
$$
/****f* COGO/ST_BearingBetweenPoints (2008)
 *  NAME
 *    ST_BearingBetweenPoints -- Returns a (Normalized) bearing in Degrees between two non-geodetic (XY) coordinates
 *  SYNOPSIS
 *    Function ST_BearingBetweenPoints (
 *               p_dE1 numeric,
 *               p_dN1 numeric,
 *               p_dE2 numeric,
 *               p_dN2 numeric
 *             )
 *     Returns numeric 
 *  USAGE
 *    SELECT spdba.ST_Bearing(0,0,45,45) as Bearing;
 *    Bearing
 *    45
 *  DESCRIPTION
 *    Function that computes the bearing from the supplied start point (p_dx1) to the supplied end point (p_dx2).
 *    The result is expressed as a whole circle bearing in decimal degrees.
 *  INPUTS
 *    p_dE1 (numeric) - X ordinate of start point.
 *    p_dN1 (numeric) - Y ordinate of start point.
 *    p_dE2 (numeric) - Z ordinate of start point.
 *    p_dN2 (numeric) - M ordinate of start point.
 *  RESULT
 *    decimal degrees (numeric) - Bearing between point 1 and 2 from 0-360.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    dBearing numeric;
    dEast    numeric;
    dNorth   numeric;
  Begin
    If (p_dE1 IS NULL OR
        p_dN1 IS NULL OR
        p_dE2 IS NULL OR
        p_dE1 IS NULL ) THEN
      Return NULL;
    END IF;

    If ( (p_dE1 = p_dE2) AND 
         (p_dN1 = p_dN2) ) THEN
      Return NULL;
    END IF;

    dEast  := p_dE2 - p_dE1;
    dNorth := p_dN2 - p_dN1;
    If ( dEast = 0.0 ) THEN
      If ( dNorth < 0.0 ) THEN
        dBearing := PI();
      Else
        dBearing := 0.0;
      End IF;
    Else
      dBearing := -aTan(dNorth / dEast) + PI() / CAST(2.0 as float);
    End IF;
          
    IF ( dEast < 0.0 ) THEN
      dBearing := dBearing + PI();
    END IF;

    -- Turn radians into degrees
    dBearing := dBearing * CAST(180.0 as float) / PI();

    -- Normalize bearing ...
    Return case when dBearing < 0.0
                then dBearing + CAST(360.0 as float)
                when dBearing >= 360.0
                then dBearing - CAST(360.0 as float)
                else dBearing
            end;
    End;
End;
$$
LANGUAGE plpgsql IMMUTABLE
COST 100;

select spdba.ST_BearingBetweenPoints(0.0,0.0,1.0,1.0);

-- **************************************************************

CREATE FUNCTION spdba.ST_BearingBetweenPoints (
  p_point1 geometry,
  p_point2 geometry
)
Returns numeric
AS
$$
Begin
  Return case when ST_GeometryType(p_point1) = 'ST_Point'
               and ST_GeometryType(p_point2) = 'ST_Point'
			  then spdba.ST_BearingBetweenPoints (
                      CAST(ST_X(p_point1) as numeric),
                      CAST(ST_Y(p_point1) as numeric),
                      CAST(ST_X(p_point2) as numeric),
                      CAST(ST_Y(p_point2) as numeric)
				   )
			  else spdba.ST_BearingBetweenPoints (
	                  CAST(ST_X(ST_PointN(p_point1,1)) as numeric),
	                  CAST(ST_Y(ST_PointN(p_point1,1)) as numeric),
	                  CAST(ST_X(ST_PointN(p_point2,1)) as numeric),
	                  CAST(ST_Y(ST_PointN(p_point2,1)) as numeric)
		  	       )
		   end;
End;
$$
LANGUAGE plpgsql IMMUTABLE
COST 100;

select spdba.ST_BearingBetweenPoints('POINT(0 0)'::geometry,'POINT(1 1)'::geometry);

