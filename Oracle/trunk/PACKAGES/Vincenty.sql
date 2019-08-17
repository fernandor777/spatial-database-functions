/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
/* Vincenty Inverse Solution of Geodesics on the Ellipsoid (c) Chris Veness 2002-2012             */
/*                                                                                                */
/* from: Vincenty inverse formula - T Vincenty, "Direct and Inverse Solutions of Geodesics on the */
/*       Ellipsoid with application of nested equations", Survey Review, vol XXII no 176, 1975    */
/*       http://www.ngs.noaa.gov/PUBS_LIB/inverse.pdf                                             */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

/**
 * Calculates geodetic distance between two points specified by latitude/longitude using 
 * Vincenty inverse formula for ellipsoids
 *
 * @param   {Number} lat1, lon1: first point in decimal degrees
 * @param   {Number} lat2, lon2: second point in decimal degrees
 * @returns (Number} distance in metres between points
 */
create or replace
function distVincenty(lat1 in number, lon1 in number, lat2 in number, lon2 in number) 
return number deterministic
Is
  a         number := 6378137;
  b         number := 6356752.314245;
  f         number := 1/298.257223563;  -- WGS-84 ellipsoid params
  L         number;
  U1        number;
  U2        number;
  sinU1     number;
  sinU2     number;
  cosU1     number;
  cosU2     number;
  lambda    number;
  lambdaP   number;
  iterLimit number := 100;
  
  sinLambda number;
  cosLambda number;
  sinSigma  number;

  cosSigma   number;
  sigma      number;
  sinAlpha   number;
  cosSqAlpha number;
  cos2SigmaM number;
  C          number;
  uSq        number;
  Aa         number;
  Bb         number;
  deltaSigma number; 
  s          number;

Begin
  L      := COGO.Radians(lon2-lon1);
  U1     := atan((1-f) * tan(COGO.Radians(lat1)));
  U2     := atan((1-f) * tan(COGO.Radians(lat2)));
  sinU1  := sin(U1);
  cosU1  := cos(U1);
  sinU2  := sin(U2);
  cosU2  := cos(U2);
  lambda := L;
  LOOP
    sinLambda := sin(lambda);
    cosLambda := cos(lambda);
    sinSigma  := sqrt((cosU2*sinLambda) * (cosU2*sinLambda) + 
                (cosU1*sinU2-sinU1*cosU2*cosLambda) * (cosU1*sinU2-sinU1*cosU2*cosLambda));
    if (sinSigma=0) then
      return 0;  -- co-incident points
    end if;
    cosSigma := sinU1*sinU2 + cosU1*cosU2*cosLambda;
    sigma    := atan2(sinSigma, cosSigma);
    sinAlpha := cosU1 * cosU2 * sinLambda / sinSigma;
    cosSqAlpha := 1 - sinAlpha*sinAlpha;
    cos2SigmaM := cosSigma - 2*sinU1*sinU2/cosSqAlpha;
    if (NANVL(cos2SigmaM, NULL) is null ) Then 
        cos2SigmaM := 0;  -- equatorial line: cosSqAlpha=0 (§6)
    End If;
    C  := f/16*cosSqAlpha*(4+f*(4-3*cosSqAlpha));
    lambdaP   := lambda;
    lambda    := L + (1-C) * f * sinAlpha * (sigma + C*sinSigma*(cos2SigmaM+C*cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)));
    iterLimit := iterLimit - 1;
    EXIT WHEN (abs(lambda-lambdaP) > 1e-12 and iterLimit>0);
  END LOOP;
  if (iterLimit=0) then
     return 1E-27; -- formula failed to converge
  End If;
  uSq := cosSqAlpha * (a*a - b*b) / (b*b);
  Aa  := 1 + uSq/16384*(4096+uSq*(-768+uSq*(320-175*uSq)));
  Bb  := uSq/1024 * (256+uSq*(-128+uSq*(74-47*uSq)));
  deltaSigma := Bb*sinSigma*(cos2SigmaM+Bb/4*(cosSigma*(-1+2*cos2SigmaM*cos2SigmaM)-
                Bb/6*cos2SigmaM*(-3+4*sinSigma*sinSigma)*(-3+4*cos2SigmaM*cos2SigmaM)));
  s := b*Aa*(sigma-deltaSigma);
  s := Round(s,3); -- round to 1mm precision
  return s;
End distVincenty;
/
show errors

select distVincenty(cogo.dms2dd('50° 03'' 58.76″N'),
cogo.dms2dd('5° 42'' 53.10″W'),
cogo.dms2dd('58° 38'' 38.48″N'),
cogo.dms2dd('3° 04'' 12.34″W')) from dual;

969920.212
should be
969954.114

select 'sdo_geometry(2001,8307,sdo_point_type('||cogo.dms2dd('50° 03'' 58.76″N')||','||cogo.dms2dd('5° 42'' 53.10″W')||'null),null,null)',
        'sdo_geometry(2001,8307,sdo_point_type('||cogo.dms2dd('58° 38'' 38.48″N')||','||cogo.dms2dd('3° 04'' 12.34″W')||'null),null,null)'
        from dual;

select sdo_geom.sdo_distance(sdo_geometry(2001,8307,sdo_point_type(cogo.dms2dd('5° 42'' 53.10″W'),cogo.dms2dd('50° 03'' 58.76″N'),NULL),NULL,NULL),
                             sdo_geometry(2001,8307,sdo_point_type(cogo.dms2dd('3° 04'' 12.34″W'),cogo.dms2dd('58° 38'' 38.48″N'),NULL),NULL,NULL),
                             0.05)
  from dual;

select sdo_geom.sdo_distance(
          sdo_geometry(2001,8307,sdo_point_type(-5.71475,      50.0663222222,null),null,null),
          sdo_geometry(2001,8307,sdo_point_type(-3.07009444444,58.6440222222,null),null,null),
          0.05) as dist
  from dual


-- 969954.113110525
