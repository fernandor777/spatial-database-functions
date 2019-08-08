DROP FUNCTION IF EXISTS spdba.ST_PointFromBearingAndDistance (Float,Float,Float,Float,integer);
DROP FUNCTION IF EXISTS spdba.ST_PointFromCOGO (geometry,Float,Float);

CREATE FUNCTION spdba.ST_PointFromBearingAndDistance (
  p_dStartE   in Float,
  p_dStartN   in Float,
  p_dBearing  in Float,
  p_dDistance in Float,
  p_iSrid     in integer
)
Returns geometry
As
/****f* COGO/ST_PointFromBearingAndDistance (2008)
 *  NAME
 *    ST_PointFromBearingAndDistance -- Returns a projected point given starting point, a bearing in Degrees, and a distance (geometry SRID units).
 *  SYNOPSIS
 *    Function spdba.ST_PointFromBearingAndDistance (
 *               p_dStartE   in float,
 *               p_dStartN   in float,
 *               p_dBearing  in float,
 *               p_dDistance in float,
 *               p_iSrid     in integer
 *             )
 *     Returns float 
 *  USAGE
 *    SELECT ST_AsEWKT(spdba.ST_PointFromBearingAndDistance (0,0,45,100,0)) as endPoint;
 *
 *    endPoint
 *    POINT (70.711 70.711)
 *  DESCRIPTION
 *    Function that computes a new point given a starting coordinate, a whole circle bearing, and a distance (SRID Units).
 *
 *    p_Srid is the SRID of the supplied start point.
 *
 *  NOTES
 *    Supports planar data only.
 *  INPUTS
 *    p_dStartE   (float) - Easting of starting point.
 *    p_dStartN   (float) - Northing of starting point.
 *    p_dBearing  (float) - Whole circle bearing between 0 and 360 degrees.
 *    p_dDistance (float) - Distance in SRID units from starting point to required point.
 *    p_iSrid       (int) - SRID associated with p_dStartE/p_dStartN.
 *  RESULT
 *    point    (geometry) - Point
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original pl/pgSQL Coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
$BODY$
DECLARE
  dAngle1    Float;
  dAngle1Rad Float;
  dDeltaN    Float;
  dDeltaE    Float;
  dEndE      Float;
  dEndN      Float;
BEGIN
  -- First calculate dDeltaE and dDeltaN
  If p_dBearing < 90.0 Then
    dAngle1    := 90.0 - p_dBearing;
    dAngle1Rad := dAngle1 * PI() / 180.0;
    dDeltaE    := Cos(dAngle1Rad) * p_dDistance;
    dDeltaN    := Sin(dAngle1Rad) * p_dDistance;
  ElsIf p_dBearing < 180.0 Then
    dAngle1    := p_dBearing - 90.0;
    dAngle1Rad := dAngle1 * PI() / 180.0;
    dDeltaE    := Cos(dAngle1Rad) * p_dDistance;
    dDeltaN    := Sin(dAngle1Rad) * p_dDistance * -1;
  ElsIf p_dBearing < 270.0 Then
    dAngle1    := 270.0 - p_dBearing;
    dAngle1Rad := dAngle1 * PI() / 180.0;
    dDeltaE    := Cos(dAngle1Rad) * p_dDistance * -1.0;
    dDeltaN    := Sin(dAngle1Rad) * p_dDistance * -1.0;
  ElsIf p_dBearing <= 360.0 Then
    dAngle1    := p_dBearing - 270.0;
    dAngle1Rad := dAngle1 * PI() / 180.0;
    dDeltaE    := Cos(dAngle1Rad) * p_dDistance * -1.0;
    dDeltaN    := Sin(dAngle1Rad) * p_dDistance;
  End If;
  -- Calculate the easting and northing of the end point
  dEndE := dDeltaE + p_dStartE;
  dEndN := dDeltaN + p_dStartN;
  RETURN case when p_iSRID is not null 
              then ST_SetSrid(ST_MakePoint(dEndE,dEndN),p_iSrid) 
              else ST_MakePoint(dEndE,dEndN)
          end;
END;
$BODY$
LANGUAGE 'plpgsql' IMMUTABLE STRICT
COST 100;

-- ***************************************************************

CREATE FUNCTION spdba.ST_PointFromCOGO (
  p_gStartPoint in geometry,
  p_dBearing    in Float,
  p_dDistance   in Float
)
Returns geometry
As
/****f* COGO/ST_PointFromCOGO 
 *  NAME
 *    ST_PointFromCOGO -- Returns a projected point given starting point, a bearing in Degrees, and a distance (geometry SRID units).
 *  SYNOPSIS
 *    Function ST_PointFromCOGO (
 *               @p_gStartPoint geometry,
 *               @p_dBearing    float,
 *               @p_dDistance   float
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT ST_AsEWKT( 
 *              ST_PointFromCOGO( 
 *                 ST_GeomFromEWKT('SRID=28355; POINT(0,0)'),
 *                 45.0,
 *                 100.0
 *              )
 *           ) as endPoint;
 *
 *    endPoint
 *    POINT (70.711 70.711)
 *  DESCRIPTION
 *    Is a wrapper function over STPointFromBearingAndDistance.
 *
 *    Function that computes a new point given a starting coordinate, a whole circle bearing and a distance (SRID Units).
 *
 *    SRID of the returned geometry is the SRID supplied start point.
 *  INPUTS
 *    @p_StartPoint (geometry) - Starting point.
 *    @p_dBearing      (float) - Whole circle bearing between 0 and 360 degrees.
 *    @p_dDistance     (float) - Distance in SRID units from starting point to required point.
 *  RESULT
 *    point          (geometry) - Point
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original pl/pgSQL coding.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
$BODY$
BEGIN
  RETURN spdba.ST_PointFromBearingAndDistance(
            ST_X(p_gStartPoint),
            ST_Y(p_gStartPoint),
            p_dBearing,
            p_dDistance,
            ST_Srid(p_gStartPoint)
	 );
END;
$BODY$
LANGUAGE 'plpgsql' IMMUTABLE STRICT
COST 100;

select ST_AsEWKT(spdba.ST_PointFromBearingAndDistance(0,0,90,10,0))             as newPoint;
select ST_AsEWKT(spdba.ST_PointFromBearingAndDistance(0,0,90,10,28355))         as newPoint;
select ST_AsEWKT(spdba.ST_PointFromCOGO(ST_SetSrid(ST_Point(0,0),28355),90,10)) as newPoint;

