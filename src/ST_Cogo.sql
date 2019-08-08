DROP FUNCTION IF EXISTS spdba.DD2DMS(numeric,nchar,nchar,nchar);
DROP FUNCTION IF EXISTS spdba.DMS2DD(Integer,Integer,Float);
DROP FUNCTION IF EXISTS spdba.DMSS2DD (varchar);
DROP FUNCTION IF EXISTS spdba.ST_NormalizeBearing(float);

CREATE FUNCTION spdba.DD2DMS(
  dDecDeg in Numeric,
  pDegree in NChar default CHR(176),
  pMinute in NChar default '''',
  pSecond in NChar default '"' 
)
Returns varchar
As
  /****f* COGO/DD2DMS 
  *  NAME
  *    DD2DMS -- Returns string equivalent of decimal degree numeric value.
  *  SYNOPSIS
  *    Function DD2DMS(
  *                dDecDeg in Number,
  *                pDegree in NChar default CHR(176),
  *                pMinute in NChar default '''',
  *                pSecond in NChar default '"' 
  *             )
  *      Return varchar2 Deterministic;
  *  INPUTS
  *    dDecDeg (Number) - Decimal degrees.
  *    pDegree (NChar)  - Superscript degree value identifier eg ^
  *    pMinute (NChar)  - Superscript minute value identifier eg '
  *    pSecond (NChar)  - Superscript second value identifier eg " 
  *  RESULT
  *    Decimal Degrees (NUMBER) - eg 22.16972222.
  *  DESCRIPTION
  *    This function converts a numeric decimal degree value into its textual whole-circle bearing equivalent.
  *  EXAMPLE
  *    select spdba.DD2DMS(15.8515065952945,'^','''','"') as dms;
  *
  *    DMS
  *    15^51'5.424"
  *
  *    select spdba.DD2DMS(415.67845) as dms;
  *
  *    dms
  *    55°40'42.420"
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
$$
Declare
  sDegreeSymbol NCHAR(1) := case when pDegree is null then CHR(176) else pDegree end;
  sMinuteSymbol NCHAR(1) := case when pMinute is null then ''''     else pMinute end;
  sSecondSymbol NCHAR(1) := case when pSecond is null then '"'      else pSecond end;
  iDeg          Integer;
  iMin          Integer;
  dSec          Numeric;
BEGIN
  If (dDecDeg is null) Then
    Return null;
  End If;
  iDeg := Trunc(dDecDeg);
  iMin := Trunc((Abs(dDecDeg)   - Abs(iDeg)) * 60.0);
  dSec := Round((((Abs(dDecDeg) - Abs(iDeg)) * 60.0) - iMin) * 60.0, 3);
  IF (Round(dSec,3) >= 60.0 ) Then
    dSec := 0.0;
    iMin := iMin + 1;
  End If;
  IF ( iMin >= 60 ) Then
    iMin := 0;
    iDeg := iDeg + 1;
  End If;
  IF ( iDeg >= 360 ) Then
    iDeg := iDeg - 360;
  End If;
  Return CAST(iDeg as varchar(3)) || sDegreeSymbol || 
         TO_CHAR(iMin,'FM00')     || sMinuteSymbol || 
         TO_CHAR(dSec,'FM00.000') || sSecondSymbol;
End;
$$
LANGUAGE plpgsql IMMUTABLE
COST 100;

select spdba.DD2DMS(15.8515065952945,'^','''','"') as dms;
select spdba.DD2DMS(45.67845);
select spdba.DD2DMS(415.67845);

-- ***********************************************

CREATE FUNCTION spdba.DMS2DD
(
  p_dDeg in Integer,
  p_dMin in Integer,
  p_dSec in Float
)
Returns Float
AS
/****f* COGO/DMS2DD (2008)
 *  NAME
 *    DMS2DD -- Function computes a decimal degree floating point number from individual degrees, minutes and seconds values.
 *  SYNOPSIS
 *    Function DMS2DD(
 *               p_dDeg in Integer,
 *               p_dMin in Integer,
 *               p_dSec in Float 
 *             )
 *     Returns Float
 *  USAGE
 *    SELECT spdba.DMS2DD(45,30,30) as DD;
 *
 *    DD
 *    45.5083333333333
 *  DESCRIPTION
 *    Function that computes the decimal equivalent to the supplied degrees, minutes and seconds values.
 *    No checking of the values of each of the inputs is conducted: one can supply 456 minutes if one wants to!
 *  NOTES
 *    Normalization of the returned value to ensure values are between 0 and 360 degrees can be conducted via the ST_NormalizeBearing function.
 *  INPUTS
 *    p_dDeg (integer) : Non-NULL degree value (0-360)
 *    p_dMin (integer) : Non-NULL minutes value (0-60)
 *    p_dSec   (float) : Non-NULL seconds value (0-60)
 *  RESULT
 *    DecimalDegrees (float) : Decimal degrees equivalent value.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
$$
Declare
   dDD Float;
Begin
   IF ( p_dDeg IS NULL OR
        p_dMin IS NULL OR
        p_dSec IS NULL ) THEN
     Return NULL;   
   END IF;
   dDD := ABS(p_dDeg) + p_dMin / 60.0 + p_dSec / 3600.0;
   Return SIGN(p_dDeg) * dDD;
End;
$$
LANGUAGE plpgsql IMMUTABLE
COST 100;

SELECT spdba.DMS2DD(45,30,30)  as dd
union all
select spdba.DMS2DD(-44,10,50) as dd
union all
select spdba.DMS2DD(-32,10,45) as dd
union all
select spdba.DMS2DD(147,10,0)  as dd;

-- ***********************************************

CREATE FUNCTION spdba.DMSS2DD 
(
  p_strDegMinSec varchar
)
Returns Float
As 
/****f* COGO/DMSS2DD (2008)
 *  NAME
 *    DMSS2DD -- Function computes a decimal degree floating point number from individual degrees, minutes and seconds values encoded in supplied string.
 *  SYNOPSIS
 *    Function DMSS2DD(
 *               p_strDegMinSec varchar
 *             )
 *     Returns Float
 *  USAGE
 *    SELECT spdba.DMSS2DD('43° 0'' 50.00"S') as DD;
 *
 *    DD
 *    -43.0138888888889
 *  DESCRIPTION
 *    The function parses the provided string (eg extracted from Google Earth) that contains DD MM SS.SS values, extracts and creates a single floating point decimal degrees value.
 *    No checking of the values of each of the inputs is conducted: one can supply 456 minutes if one wants to!
 *    The function honours N, S, E and W cardinal references.
 *  NOTES
 *    Normalization of the returned value to ensure values are between 0 and 360 degrees can be conducted via the STNormalizeBearing function.
 *  INPUTS
 *    p_strDegMinSec (varchar) : DD MM SS.SS description eg 43° 0'' 50.00"S
 *  RESULT
 *    DecimalDegrees (float) : Decimal degrees equivalent value.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 *  LICENSE
 *      Creative Commons Attribution-Share Alike 2.5 Australia License.
 *      http://creativecommons.org/licenses/by-sa/2.5/au/
 ******/
$$
DECLARE
   i               Integer := 0;
   intDmsLen       Integer := -1;      --Length of original string
   strCompassPoint VarChar(1);
   strNorm         varchar(100) := ''; --Will contain normalized string
   strDegMinSecB   varchar(100);
   token           varchar(100);
   strChr          VarChar(1);
   blnGotSeparator integer = -1;       -- Keeps track of separator sequences
   dDeg            Float   = 0;
   dMin            Float   = 0;
   dSec            Float   = 0;
   dReturnDecimal  Float   = 0.0;
   rec             Record;
BEGIN
   -- Remove leading and trailing spaces
   strDegMinSecB   := REPLACE(p_strDegMinSec,' ','');
   -- assume no leading and trailing spaces?
   intDmsLen       := LENGTH(strDegMinSecB);
   blnGotSeparator := 0; -- Not in separator sequence right now
   -- Loop over string, replacing anything that is not a digit or a
   -- decimal separator with
   -- a single blank
   i := 0;
   WHILE ( i <= intDmsLen)
   LOOP
      i := i + 1;
      -- Get current character
      strChr := SUBSTRING(strDegMinSecB from i for 1);
      -- either add character to normalized string or replace
      -- separator sequence with single blank
      IF (strChr in ('0','1','2','3','4','5','6','7','8','9',',','.') ) THEN
         -- add character but replace comma with point
         IF ( strChr <> ',' ) THEN
            strNorm := CONCAT(strNorm,strChr);
         Else
            strNorm := CONCAT(strNorm,'.');
         END IF;
         blnGotSeparator := 0;
      ELSE
        IF (strChr IN ('n','e','s','w','N','E','S','W') ) THEN -- Extract Compass Point IF (present
          strCompassPoint := UPPER(strChr);
        ELSE
           -- ensure only one separator is replaced with a marker -
           -- suppress the rest
           IF (blnGotSeparator = 0) THEN
              strNorm         := CONCAT(strNorm,'@');
              blnGotSeparator := 0;
           END IF;
         END IF;
      END IF;
   END LOOP;
   -- Split normalized string into array of max 3 components
   i := 0;
   FOR rec IN 
       SELECT f.token 
         FROM (SELECT CAST(a.* as float) as token
                 FROM unnest(regexp_split_to_array(strNorm, '[@]')) as a
                WHERE length(a.*) > 0
                  AND upper(a.*) not in ('N','S','E','W')
               ) as f
   LOOP
     i := i + 1;
     --convert specified components to double
     IF ( i = 1 ) THEN dDeg := rec.token; END IF;
     IF ( i = 2 ) THEN dMin := rec.token; END IF;
     IF ( i = 3 ) THEN dSec := rec.token; END IF;
   END LOOP;
   -- convert components to value
   dReturnDecimal := CASE WHEN UPPER(strCompassPoint) IN ('S','W') 
                          THEN -1 
                          ELSE 1 
                      END 
                    *
                    (dDeg + (dMin / 60.0) + (dSec / 3600.0));
   Return dReturnDecimal;
End;
$$
LANGUAGE plpgsql IMMUTABLE
COST 100;

SELECT a.id, a.DD
  FROM (SELECT 1 as id, spdba.DMSS2DD('43° 0''   50.00"S') as DD
  UNION SELECT 2 as id, spdba.DMSS2DD('43° 30''  45.50"N') as DD
  UNION SELECT 3 as id, spdba.DMSS2DD('147° 50'' 30.60"E') as DD
  UNION SELECT 4 as id, spdba.DMSS2DD('65° 10''  12.60"W') as DD
  UNION SELECT 5 as id, spdba.DMSS2DD('225° 10''W') as DD
  UNION SELECT 6 as id, spdba.DMSS2DD('12°N') as DD
 ) a
ORDER BY a.id;

-- ***********************************************

CREATE FUNCTION spdba.ST_NormalizeBearing
(
  p_bearing float
)
Returns float
As
/****f* COGO/ST_NormalizeBearing
 *  NAME
 *    ST_NormalizeBearing -- Function ensures supplied bearing is between 0 and 360. 
 *  SYNOPSIS
 *    Function spdba.ST_NormalizeBearing(
 *                p_bearing float
 *             )
 *     Returns Float
 *  USAGE
 *    SELECT spdba.ST_NormalizeBearing(450.39494) as bearing;
 *
 *    bearing
 *    90.39494
 *  DESCRIPTION
 *    Function that ensures supplied bearing is between 0 and 360 degrees (360 = 0).
 *  INPUTS
 *    p_bearing (float) : Non-NULL decimal bearing.
 *  RESULT
 *    bearing (float) : Bearing between 0 and 360 degrees.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2011 - Original pl/pgSQL Coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
 ******/
$$
Begin
  if ( p_bearing is null ) Then
    return p_bearing;
  End If;
  return case when p_bearing < 0.0
              then p_bearing + 360.0
              when p_bearing >= 360.0
              then p_bearing - 360.0
              else p_bearing
          end;
End
$$
LANGUAGE plpgsql IMMUTABLE
COST 100;

COMMENT ON FUNCTION spdba.ST_NormalizeBearing(IN numeric) IS 'Function that ensures bearing is between 0 and 360';

SELECT spdba.ST_NormalizeBearing(450.39494) as bearing;
select spdba.ST_NormalizeBearing(-27.4039973589964);
select spdba.ST_NormalizeBearing(360);

