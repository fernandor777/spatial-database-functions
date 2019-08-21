DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;
SET SERVEROUTPUT ON

-- Always aim for a clean compile
ALTER SESSION SET PLSQL_WARNINGS='ERROR:ALL';
-- Enable optimizations
-- ALTER SESSION SET plsql_optimize_level=2;

CREATE OR REPLACE PACKAGE BODY &&INSTALL_SCHEMA..COGO
AS
  Function PI
  Return Number
  As
  Begin
    Return acos(-1);
  End Pi;
  Function ST_Degrees(p_radians   in number,
                      p_normalize in integer default 1)
  Return number
  Is
    v_degrees number;
  Begin
    If (p_radians is null) Then
      Return p_radians;
    End If;
    v_degrees := p_radians * (180.0 / &&INSTALL_SCHEMA..COGO.PI());

    IF ( NVL(p_normalize,1)=1 ) Then
      v_degrees :=
           case when v_degrees  <   0.0
                then v_degrees  + 360.0
                when v_degrees >= 360.0
                then v_degrees  - 360.0
                else v_degrees
            end;
    End If;
    Return v_degrees;
  End ST_Degrees;
  Function ArcTan2(dOpp in number,
                   dAdj in number)
    Return Number
  IS
    dAngleRad Number;
  BEGIN
    --Get the basic angle.
    If Abs(dAdj) < 0.0001 Then
      dAngleRad := codesys.CONSTANTS.c_PI / 2;
    Else
      dAngleRad := Abs(aTan(dOpp / dAdj));
    End If;
    --See if we are in quadrant 2 or 3.
    If dAdj < 0 Then
      --dAngle > codesys.CONSTANTS.c_PI/2 or angle < -codesys.CONSTANTS.c_PI/2.
      dAngleRad := codesys.CONSTANTS.c_PI - dAngleRad;
    End If;
    --See if we are in quadrant 3 or 4.
    If dOpp < 0 Then
      dAngleRad := -dAngleRad;
    End If;
    --Return the result.
    Return dAngleRad;
  END ArcTan2;
  Function ST_Normalize(p_degrees in number)
    Return Number
  As
  Begin
    If (p_degrees is null) Then
      Return p_degrees;
    End If;
    Return
           case when p_degrees  <   0.0
                then p_degrees  + 360.0
                when p_degrees >= 360.0
                then p_degrees  - 360.0
                else p_degrees
            end;
  End ST_Normalize;
  Function ST_Radians(p_degrees in number)
    Return number
  Is
  Begin
    Return p_degrees * (&&INSTALL_SCHEMA..COGO.PI() / 180.0);
  End ST_Radians;
  Function DMS2DD(strDegMinSec in varchar2)
    Return Number
  IS
     TYPE StringArray IS TABLE OF VarChar2(2048);
     arrDegMinSec    stringarray;
     i               Number;
     intDmsLen       Number;
     strCardinalDirection Char(1);
     strNorm         varchar2(16);
     strDegMinSecB   varchar2(100);
     blnGotSeparator integer;
     dDeg            Number := 0;
     dMin            Number := 0;
     dSec            Number := 0;
     strChr          Char(1);
     Function strtok(p_str   in varchar2,
                     p_delim in varchar2)
       Return StringArray
     IS
       v_numtok      number;
       v_length      number;
       v_outside     number;
       v_char        char(1);
       v_strtok_vals StringArray := new StringArray(' ');
     BEGIN
       v_numtok  := 0;
       v_length  := length(p_str);
       v_outside := 1;
       FOR i in 1..v_length loop
        v_char := SUBSTR(p_str,i,1);
        IF instr(p_delim, v_char) <> 0 then
          v_outside := 1;
          v_strtok_vals.EXTEND;
          v_strtok_vals(v_strtok_vals.LAST) := '';
        else
          if (v_outside = 1) then
            v_numtok := v_numtok + 1;
          end if;
          v_strtok_vals(v_strtok_vals.LAST) := v_strtok_vals(v_strtok_vals.LAST) || v_char;
          v_outside := 0;
        end if;
      END LOOP;
      Return v_strtok_vals;
    END strtok;
  BEGIN
    strDegMinSecB := REPLACE(strDegMinSec,' ',NULL);
    intDmsLen := Length(strDegMinSecB);
    blnGotSeparator := 0;
    FOR i in 1..intDmsLen LOOP
      strChr := SubStr(strDegMinSecB, i, 1);
      If InStr('0123456789,.', strChr) > 0 Then
         If (strChr <> ',') Then
            strNorm := strNorm || strChr;
         Else
            strNorm := strNorm || '.';
         End If;
         blnGotSeparator := 0;
      ElsIf InStr('neswNESW',strChr) > 0 Then
        strCardinalDirection := strChr;
      Else
         If blnGotSeparator = 0 Then
            strNorm := strNorm || ' ';
            blnGotSeparator := 0;
         End If;
      End If;
    End Loop;
    arrDegMinSec := strtok(strNorm, ' ');
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
    return (CASE WHEN UPPER(strCardinalDirection) IN ('S','W')
                 THEN -1
                 ELSE 1
             END
            *
            (dDeg + dMin / 60 + dSec / 3600));
  End DMS2DD;
  Function DD2DMS(dDecDeg in Number,
                  pDegree in NChar default '°',
                  pMinute in NChar default '''',
                  pSecond in NChar default '"' )
    Return varchar2 deterministic
  IS
    sDegreeSymbol NCHAR(1) := NVL(pDegree,'°');
    sMinuteSymbol NCHAR(1) := NVL(pMinute,'''');
    sSecondSymbol NCHAR(1) := NVL(pSecond,'"');
    iDeg          Integer;
    iMin          Integer;
    dSec          Number;
    iSign         pls_integer;
  BEGIN
    iSign := SIGN(dDecDeg);
    iDeg := Trunc(ABS(dDecDeg));
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
      iDeg := 0;
    End If;
    Return TO_CHAR(iSign*iDeg)      || sDegreeSymbol ||
           TO_CHAR(iMin,'FM00')     || sMinuteSymbol ||
           TO_CHAR(dSec,'FM00.000') || sSecondSymbol;
  End DD2DMS;
  Function DD2TIME(p_dDecDeg in Number,
                   p_24_hour in integer default 0)
    Return VarChar2
  Is
    v_dDecDeg Number := Round((p_dDecDeg/360)*12,2);
    v_iDeg    Integer;
    v_iMin    Integer;
  Begin
    v_iDeg := TRUNC(v_dDecDeg);
    v_iMin := (v_dDecDeg - v_iDeg) * 60;
    Return TO_CHAR(case when NVL(p_24_hour,0)=0 then v_iDeg else 12+v_iDeg end)||'hr '||TO_CHAR(v_iMin)||'min';
  End DD2TIME;
  Function CardinalDirection(p_bearing      in number,
                             p_abbreviation in integer default 1)
    Return varchar2
  As
    v_bearing number;
  Begin
    If ( p_bearing is null ) then
      Return null;
    End If;
    v_bearing := round(abs(p_bearing),2);
    Return case when NVL(p_abbreviation,1) <> 0
                then case when v_bearing between   0.00 AND  11.25 then 'North'
                          when v_bearing between  11.25 AND  33.75 then 'North-NorthEast'
                          when v_bearing between  33.75 AND  56.25 then 'NorthEast'
                          when v_bearing between  56.25 AND  78.75 then 'East-NorthEast'
                          when v_bearing between  78.75 AND 101.25 then 'East'
                          when v_bearing between 101.25 AND 123.75 then 'East-SouthEast'
                          when v_bearing between 123.75 AND 146.25 then 'SouthEast'
                          when v_bearing between 146.25 AND 168.75 then 'South-SouthEast'
                          when v_bearing between 168.75 AND 191.25 then 'South'
                          when v_bearing between 191.25 AND 213.75 then 'South-SouthWest'
                          when v_bearing between 213.75 AND 236.25 then 'SouthWest'
                          when v_bearing between 236.25 AND 258.75 then 'West-SouthWest'
                          when v_bearing between 258.75 AND 281.25 then 'West'
                          when v_bearing between 281.25 AND 303.75 then 'West-NorthWest'
                          when v_bearing between 303.75 AND 326.25 then 'NorthWest'
                          when v_bearing between 326.25 AND 348.75 then 'North-NorthWest'
                          when v_bearing between 348.75 AND 360.00 then 'North'
                          else null
                      end
                else case when v_bearing between   0.00 AND  11.25 then 'N'
                          when v_bearing between  11.25 AND  33.75 then 'NNE'
                          when v_bearing between  33.75 AND  56.25 then 'NE'
                          when v_bearing between  56.25 AND  78.75 then 'ENE'
                          when v_bearing between  78.75 AND 101.25 then 'E'
                          when v_bearing between 101.25 AND 123.75 then 'ESE'
                          when v_bearing between 123.75 AND 146.25 then 'SE'
                          when v_bearing between 146.25 AND 168.75 then 'SSE'
                          when v_bearing between 168.75 AND 191.25 then 'S'
                          when v_bearing between 191.25 AND 213.75 then 'SSW'
                          when v_bearing between 213.75 AND 236.25 then 'SW'
                          when v_bearing between 236.25 AND 258.75 then 'WSW'
                          when v_bearing between 258.75 AND 281.25 then 'W'
                          when v_bearing between 281.25 AND 303.75 then 'WNW'
                          when v_bearing between 303.75 AND 326.25 then 'NW'
                          when v_bearing between 326.25 AND 348.75 then 'NNW'
                          when v_bearing between 348.75 AND 360.00 then 'N'
                          else null
                      end
           end;
  End CardinalDirection;
  Function QuadrantBearing(p_bearing in number,
                           p_Degree  in NChar default '°')
    Return varchar2
  IS
    sDegreeSymbol NCHAR(1) := NVL(p_Degree,'°');
    v_bearing     number;
  Begin
    If ( p_bearing is null ) then
      Return null;
    End If;
    v_bearing := ROUND(ABS(p_bearing),3);
    Return case when v_bearing = 0.0 or v_bearing = 360.0 then 'N'
                when v_bearing = 180.0                    then 'S'
                when v_bearing = 90.0                     then 'E'
                when v_bearing = 270.0                    then 'W'
                when v_bearing between   0.00 AND  90.0 then 'N'||TO_CHAR(v_Bearing)      ||sDegreeSymbol||'E'
                when v_bearing between 270.00 AND 360.0 then 'N'||TO_CHAR(v_Bearing-270.0)||sDegreeSymbol||'W'
                when v_bearing between   90.0 AND 180.0 then 'S'||TO_CHAR(180.0-v_Bearing)||sDegreeSymbol||'E'
                when v_bearing between  180.0 AND 270.0 then 'S'||TO_CHAR(v_Bearing-180.0)||sDegreeSymbol||'W'
                else null
            end;
  End QuadrantBearing;
  function GreatCircleBearing( p_lon1 in number,
                               p_lat1 in number,
                               p_lon2 in number,
                               p_lat2 in number)
   return number
  Is
     v_lon1      number;
     v_lat1      number;
     v_lon2      number;
     v_lat2      number;
     v_dLong     number;
     v_cosC      number;
     v_cosD      number;
     v_C         number;
     v_D         number;
  Begin
     v_lon1  := &&INSTALL_SCHEMA..COGO.ST_Radians(p_lon1);
     v_lat1  := &&INSTALL_SCHEMA..COGO.ST_Radians(p_lat1);
     v_lon2  := &&INSTALL_SCHEMA..COGO.ST_Radians(p_lon2);
     v_lat2  := &&INSTALL_SCHEMA..COGO.ST_Radians(p_lat2);
     v_dLong := v_lon2 - v_lon1;
     v_cosD  := ( sin(v_lat1) * sin(v_lat2) ) +
                ( cos(v_lat1) * cos(v_lat2) * cos(v_dLong) );
     v_D     := acos(v_cosD);
     if ( v_D = 0.0 ) then
       v_D := 0.00000001;
     end if;
     v_cosC  := ( sin(v_lat2) - v_cosD * sin(v_lat1) ) /
                ( sin(v_D) * cos(v_lat1) );
     if ( v_cosC > 1.0 ) then
         v_cosC := 1.0;
     end if;
     if ( v_cosC < -1.0 ) then
         v_cosC := -1.0;
     end if;
     v_C  := 180.0 * acos( v_cosC ) / &&INSTALL_SCHEMA..COGO.PI();
     if ( sin(v_dLong) < 0.0 ) then
         v_C := 360.0 - v_C;
     end if;
     return (round( 100 * v_C ) / 100.0);
  END GreatCircleBearing;
  
  Function ComputeArcLength(p_Radius in number,
                            p_Angle  in number)
  Return Number
  IS
  BEGIN
    Return p_Radius * p_Angle * acos(-1) / 180.0;
  END ComputeArcLength;

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
                  and object_type = 'PACKAGE BODY'
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

