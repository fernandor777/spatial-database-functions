DEFINE defaultSchema='&1'
SET SERVEROUTPUT ON SIZE 10000
ALTER SESSION SET plsql_optimize_level=1;

Prompt Dependencies ...
select name,
       type,
       referenced_owner
   from dba_dependencies
 where owner = '&&defaultSchema.'
   and referenced_owner not in ('PUBLIC','MDSYS')
   and referenced_name = 'ST_POINT'
group by name,
       type,
       referenced_owner,
       referenced_name,
       REFERENCED_TYPE
 order by 1;

WHENEVER SQLERROR CONTINUE;
CREATE TYPE &&defaultSchema..ST_ExplicitPoint_Type IS VARRAY(4) Of NUMBER;
/
show errors

GRANT EXECUTE ON &&defaultSchema..ST_ExplicitPoint_Type TO PUBLIC;

WHENEVER SQLERROR EXIT FAILURE;
CREATE TYPE &&defaultSchema..ST_Point AS OBJECT (

  x       NUMBER,
  y       NUMBER,
  z       NUMBER,
  m       NUMBER,

  Constructor Function ST_Point ( p_x    In NUMBER,
                                  p_y    In NUMBER )
                Return Self As Result,

  Constructor Function ST_Point ( p_x    In NUMBER,
                                  p_y    In NUMBER,
                                  p_z    In NUMBER )
                Return Self As Result,

  /** Note: ORacle provides a default constructor for the 4 attributes of the Object
  Constructor Function ST_Point ( p_x    In NUMBER,
                                  p_y    In NUMBER,
                                  p_z    In NUMBER := NULL,
                                  p_m    In NUMBER := NULL)
                Return Self As Result,
  **/

  Constructor Function ST_Point ( p_WKT in varchar2 )
                Return Self As Result,

  -- Some ISO/MM Methods
  --
  Member Function ST_X 
           Return Number Deterministic,

  Member Function ST_Y 
           Return Number Deterministic,

  Member Function ST_Z 
           Return Number Deterministic,

  Member Function ST_M 
           Return Number Deterministic,

  Member Function ST_Dimension 
           Return PLS_Integer Deterministic,

  Member Function ST_CoordDim 
           Return PLS_Integer Deterministic,

  Member Function ST_IsEmpty 
           Return Boolean Deterministic,

  Member Function ST_is3D
           Return PLS_Integer Deterministic,

  Member Function ST_isMeasured
           Return PLS_Integer Deterministic,

  Member Function ST_ExplicitPoint
           Return &&defaultSchema..ST_ExplicitPoint_Type deterministic,

  Member Function AsGML
           Return VarChar2 Deterministic,

  Member Function ST_AsText
           Return VarChar2 Deterministic,

  Member Function AsSVG
           Return VarChar2 Deterministic,

  -- Some Non ISO/MM Methods
  --
  Member Function ST_Equals( p_Point In &&defaultSchema..ST_Point )
           Return Boolean Deterministic,

  Member Function Average( p_Point IN &&defaultSchema..ST_Point )
           Return &&DefaultSchema..ST_Point Deterministic,

  Member Function MidPoint( p_Point IN &&defaultSchema..ST_Point )
           Return &&DefaultSchema..ST_Point Deterministic,

  Member Function Distance( p_Point In &&defaultSchema..ST_Point,
	                    p_SRID  In NUMBER := NULL )
           Return Number Deterministic,

  -- Order function for sorting point data
  --
  Order Member Function compare( p_Point In &&defaultSchema..ST_Point )
                 Return Number Deterministic

 );
/
show errors

CREATE OR REPLACE TYPE BODY &&defaultSchema..ST_Point As

  Constructor Function ST_Point( p_x   In NUMBER,
                                 p_y   In NUMBER )
                Return Self As Result
  Is
  Begin
   Self.X := p_x;
   Self.Y := p_Y;
   Self.Z := NULL;
   Self.M := NULL;
   Return;
  End ST_Point;

  Constructor Function ST_Point( p_x    In NUMBER,
                                 p_y    In NUMBER,
                                 p_z    In NUMBER )
                Return Self As Result
  Is
  Begin
   Self.X := p_x;
   Self.Y := p_Y;
   Self.Z := p_Z;
   Self.M := NULL;
   Return;
  End ST_Point;

  /** Not needed
  Constructor Function ST_Point( p_x    In NUMBER,
                                 p_y    In NUMBER,
                                 p_z    In NUMBER := NULL,
                                 p_m    In NUMBER := NULL )
                Return Self As Result
  Is
  Begin
   Self.X := p_x;
   Self.Y := p_Y;
   Self.Z := p_Z;
   Self.M := p_m;
   Return;
  End ST_Point;
  **/

  Constructor Function ST_Point ( p_WKT in varchar2 )
                Return Self As Result
  Is
    v_crds  varchar2(256);
    v_token varchar2(256);
  Begin
    v_crds  := TRIM( BOTH ' ' FROM REPLACE(REPLACE(SUBSTR(p_wkt,INSTR(p_wkt,'(')),'('),')') );
    v_token := SUBSTR(v_crds,1,INSTR(v_crds,' ')-1);
    Self.X  := to_number(v_token);
    v_crds  := SUBSTR(v_crds,  INSTR(v_crds,' ')+1);
    v_token := SUBSTR(v_crds,1,INSTR(v_crds,' ')-1);
    Self.Y  := to_number(v_token);
    If Self.Y is NULL Then
      Self.Y  := to_number(v_crds);
    End If;
    If INSTR(UPPER(p_wkt),'POINTZ') > 0 Then
      v_crds  := SUBSTR(v_crds,  INSTR(v_crds,' ')+1);
      v_token := SUBSTR(v_crds,1,INSTR(v_crds,' ')-1);
      Self.Z  := to_number(v_token);
      If Self.Z is NULL Then
        Self.Z  := to_number(v_crds);
      End If;
    End If;
    If INSTR(UPPER(p_wkt),'POINTZM') > 0 Then
      v_token  := SUBSTR(v_crds,  INSTR(v_crds,' ')+1);
      Self.M  := to_number(v_token);
    End If;
    Return;
  End ST_Point;

  Member Function ST_X 
           Return Number Deterministic
  Is
  Begin
    Return SELF.X;
  End ST_X;

  Member Function ST_Y 
           Return Number Deterministic
  Is
  Begin
    Return SELF.Y;
  End ST_Y;

  Member Function ST_Z 
           Return Number Deterministic
  Is
  Begin
    Return SELF.Z;
  End ST_Z;

  Member Function ST_M 
           Return Number Deterministic
  Is
  Begin
    Return SELF.M;
  End ST_M;

  Member Function ST_Dimension
           Return Pls_Integer Deterministic
  Is
  Begin
    Return 0;  -- Always 0
  End ST_Dimension;

  Member Function ST_CoordDim
           Return PLS_Integer Deterministic
  Is
    v_CoordDim PLS_Integer := -1;
  Begin
    Case
      When ( Self.Z IS NOT NULL AND Self.M IS NOT NULL) THEN
        v_CoordDim := 4;
      When ((Self.Z IS NOT NULL AND Self.M IS NULL) OR
            (Self.Z IS NULL     AND Self.M IS NOT NULL)) THEN
        v_CoordDim := 3;
      When ( Self.X is not null And Self.y is not null ) Then
        v_CoordDim := 2;
      Else
        v_CoordDim := 0;  -- ISO Standard does not indicate what to do. Won't raise exception.
    End Case;
    Return v_CoordDim;
  End ST_CoordDim;

  Member Function ST_is3D
           Return Pls_Integer Deterministic
  Is
  Begin
    Case
      When Self.Z IS NOT NULL Then -- if z coordinate is not the null
         Return 1;                 -- value, then is 3D
      Else                         -- otherwise,
         Return 0;                 -- is not 3D
    End Case;
  End ST_is3D;

  Member Function ST_isMeasured
         Return Pls_Integer Deterministic
  Is
  Begin
    Case
      When Self.m IS NOT NULL Then  -- if m coordinate value is not the null value, then
        Return 1;                   -- is measured
      Else                          -- otherwise,
        Return 0;                   -- is not measured
    End Case;
  End ST_isMeasured;

  Member Function ST_isEmpty
         Return Boolean Deterministic
  Is
  Begin
    return ( Self.x is null And Self.y is null And Self.z is Null and Self.m is null );
  End ST_isEmpty;

  Member Function ST_ExplicitPoint
           Return &&defaultSchema..ST_ExplicitPoint_Type  Deterministic
  Is
    v_varray  &&defaultSchema..ST_ExplicitPoint_Type;
  Begin
    CASE
    WHEN SELF.ST_IsEmpty() THEN
       NULL;
    WHEN (SELF.Z IS NOT NULL AND
          SELF.M IS NOT NULL) THEN
       v_varray := &&defaultSchema..ST_ExplicitPoint_Type(SELF.X, SELF.Y, SELF.Z, SELF.M);
    WHEN (SELF.Z IS NOT NULL AND
          SELF.M IS NULL) THEN
        v_varray := &&defaultSchema..ST_ExplicitPoint_Type(SELF.X, SELF.Y, SELF.Z);
    WHEN (SELF.Z IS NULL AND
          SELF.M IS NOT NULL) THEN
        v_varray := &&defaultSchema..ST_ExplicitPoint_Type(SELF.X, SELF.Y, SELF.M);
    ELSE
        v_varray := &&defaultSchema..ST_ExplicitPoint_Type(SELF.X, SELF.Y);
    END CASE;
    Return v_varray;
  End ST_ExplicitPoint;

  Member Function Average( p_Point IN &&defaultSchema..ST_Point )
         Return &&defaultSchema..ST_Point Deterministic
  Is
  Begin
    return &&defaultSchema..ST_Point( ( p_Point.x + Self.x ) / 2.0,
                                      ( p_Point.y + Self.y ) / 2.0,
                                      ( p_Point.z + Self.z ) / 2.0,
                                      ( p_Point.m + Self.m ) / 2.0 );
  End Average;

  Member Function MidPoint( p_Point IN &&defaultSchema..ST_Point )
         Return &&defaultSchema..ST_Point Deterministic
  Is
  Begin
    return &&defaultSchema..ST_Point( Self.x + ( p_Point.x - Self.x ) / 2.0,
                                      Self.y + ( p_Point.y - Self.y ) / 2.0,
                                      Self.z + ( p_Point.z - Self.z ) / 2.0,
                                      Self.m + ( p_Point.m - Self.m ) / 2.0 );
  End MidPoint;

  Member Function Distance( p_Point In &&defaultSchema..ST_Point,
	                    p_SRID  In NUMBER := NULL )
         Return Number Deterministic
  As
    dX         Number;
    dY         Number;
    dZ         Number;
    v_distance Number;
    v_geodetic Number;

    /*
     * Calculate geodesic distance (in m) between two points specified by latitude/longitude
     * using Vincenty inverse formula for ellipsoids

     * The most accurate and widely used globally-applicable model for the earth ellipsoid is WGS-84. 
     * Other ellipsoids offering a better fit to the local geoid include Airy (1830) in the UK, 
     * International 1924 in much of Europe, Clarke (1880) in Africa, and GRS-67 in South America. 
     * America (NAD83) and Australia (GDA) use GRS-80, functionally equivalent to the WGS-84 ellipsoid.
     * WGS-84        a = 6 378 137 m (±2 m) b = 6 356 752.3142 m   f = 1 / 298.257223563
     * GRS-80        a = 6 378 137 m        b = 6 356 752.3141 m   f = 1 / 298.257222101
     * Airy (1830)   a = 6 377 563.396 m    b = 6 356 256.909 m    f = 1 / 299.3249646
     * Int’l 1924    a = 6 378 388 m        b = 6 356 911.946 m    f = 1 / 297
     * Clarke (1880) a = 6 378 249.145 m    b = 6 356 514.86955 m  f = 1 / 293.465
     * GRS-67        a = 6 378 160 m        b = 6 356 774.719 m    f = 1 / 298.25
     *
     * Note that to locate latitude/longitude points on these ellipses, they are associated with 
     * specific datums: for instance, OSGB36 for Airy in the UK, ED50 for Int’l 1924 in Europe; 
     * WGS-84 defines a datum as well as an ellipse. 
     *
     * Some of the terms involved are explained in Ed Williams’ notes on Spheroid Geometry.
     * Test case (from Geoscience Australia), using WGS-84:
     *  Flinders Peak  37°57'03.72030?S, 144°25'29.52440?E
     *  Buninyong      37°39'10.15610?S, 143°55'35.38390?E
     *  s              54 972.271 m
     *  a1             306°52'05.37?
     *  a2             127°10'25.07? (= 307°10'25.07? p1?p2)

     */
    Function Vincenty(p_p1 In &&defaultSchema..ST_Point, p_p2 in &&defaultSchema..ST_Point ) 
             Return Number Deterministic
    Is
      c_PI       CONSTANT NUMBER(16,14) := 3.14159265358979;
      major_axis Number := 6378137; 
      minor_axis Number := 6356752.3142;  
      f          Number;
      deltaL     Number;
      U1         Number;
      U2         Number;
      SinU1      Number;
      SinU2      Number;
      CosU1      Number;
      CosU2      Number;
      Lambda     Number;
      LambdaP    Number;
      SinLambda  Number;
      CosLambda  Number;
      SinSigma   Number;
      CosSigma   Number;
      Sigma      Number;
      SinAlpha   Number;
      CosSqAlpha Number;
      Cos2SigmaM Number;
      A          Number;
      B          Number;
      C          Number;
      S          Number;
      v_p1       &&defaultSchema..ST_Point := p_p1;
      v_p2       &&defaultSchema..ST_Point := p_p2;
      IterLimit  NUMBER;
      uSq        Number;
      deltaSigma Number;
      v_ignore   NUMBER;
    Begin 
      -- Convert to radians
      v_p1.X := v_p1.X * c_PI / 180.0;
      v_p2.X := v_p2.X * c_PI / 180.0;
      v_p1.Y := v_p1.Y * c_PI / 180.0;
      v_p2.Y := v_p2.Y * c_PI / 180.0;
      f     := 1/298.257223563;
      deltaL:= v_p2.X - v_p1.X;
      U1    := atan((1-f) * tan(v_p1.Y));
      U2    := atan((1-f) * tan(v_p2.Y));
      sinU1 := sin(U1);
      cosU1 := cos(U1);
      sinU2 := sin(U2);
      cosU2 := cos(U2);
    
      lambda  := deltaL;
      lambdaP := 2.0 * c_PI;
  
      iterLimit := 20;
      <<iteration_loop>>
      while ( abs(lambda-lambdaP) > 1E-12 ) AND ( iterLimit > 0 ) Loop
        sinLambda := sin(lambda); 
        cosLambda := cos(lambda);
        sinSigma  := sqrt((cosU2*sinLambda) * (cosU2*sinLambda) + (cosU1*sinU2-sinU1*cosU2*cosLambda) * (cosU1*sinU2-sinU1*cosU2*cosLambda));
        If ( sinSigma = 0.0 ) Then
          return 0;  -- co-incident points
        End If;
        cosSigma   := sinU1*sinU2 + cosU1*cosU2*cosLambda;
        sigma      := atan2(sinSigma, cosSigma);
        sinAlpha   := cosU1 * cosU2 * sinLambda / sinSigma;
        cosSqAlpha := 1.0 - sinAlpha * sinAlpha;
        begin
          v_ignore := ( cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha );
          cos2SigmaM := cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;
          EXCEPTION
            WHEN ZERO_DIVIDE THEN  -- (Was using IS NAN feature of 10g)
              cos2SigmaM := 0;
            WHEN VALUE_ERROR THEN
              cos2SigmaM := 0;
        End; -- equatorial line: cosSqAlpha=0 (§6)
        C := f/16 * cosSqAlpha * (4 + f * (4-3 * cosSqAlpha) );
        lambdaP := lambda;
        lambda  := deltaL + (1-C) * f * sinAlpha * (sigma + C*sinSigma * (cos2SigmaM + C*cosSigma*(-1+2 * cos2SigmaM*cos2SigmaM)));
        iterLimit := iterLimit - 1;
      End Loop iteration_loop;
      if (iterLimit=0) Then
        raise_application_error(-20001,'Vincenty formula failed to converge',TRUE);
      End If;
      uSq := cosSqAlpha * (major_axis*major_axis - minor_axis*minor_axis) / (minor_axis*minor_axis);
      A   := 1 + uSq/16384.0 * (4096.0 + uSq * (-768.0 + uSq * (320.0-175.0 * uSq)));
      B   := uSq/1024.0 * ( 256.0 + uSq * (-128 + uSq * (74.0 - 47.0 * uSq)));
      deltaSigma := B * sinSigma * ( cos2SigmaM + B/4.0 * (cosSigma * (-1.0 + 2.0*cos2SigmaM*cos2SigmaM ) -
                    B/6.0 * cos2SigmaM * (-3.0+4.0*sinSigma*sinSigma)*(-3.0 + 4.0*cos2SigmaM*cos2SigmaM )));
      s := minor_axis * A * (sigma-deltaSigma);
      s := Round(s,3); -- round to 1mm precision
      return s;
    End Vincenty;

  Begin
    v_geodetic := 0;
    If ( p_SRID is not NULL ) Then
      select count(*) 
        into v_geodetic
        from mdsys.cs_srs
       where srid = p_SRID
         and cs_name Like 'Longitude%';
    End If;
    If v_geodetic = 0 Then
      dX := Self.X - p_Point.X;
      dY := Self.Y - p_Point.Y;
      If ( Self.Z is not NULL And p_Point.Z is not NULL ) Then
        dZ := Self.Z - p_Point.Z;
      Else
        dZ := 0.0;
      End If;
      v_distance := Sqrt(dX * dX + dY * dY + dZ * dZ);
    Else
      -- Planar or geodetic ?
      v_distance := Vincenty( Self, p_Point );
    End If;
    Return v_distance;
  End distance;

  Member Function ST_equals( p_Point In &&defaultSchema..ST_Point )
         Return Boolean Deterministic
  As
  Begin
    Return ( Self.X = p_Point.X ) And ( Self.Y = p_Point.Y ) And ( Self.Z = p_Point.Z ) And ( Self.m = p_Point.M ) ;
  End ST_equals;

  Order Member Function compare( p_Point In &&defaultSchema..ST_Point )
        Return number Deterministic
  As
    v_value number;
  Begin
    If self.ST_equals( p_Point ) Then
      v_value := 0;
    ElsIf ( Self.X * Self.Y * Self.Z * Self.m ) < ( p_Point.X * p_Point.Y * p_Point.Z * p_Point.m ) Then
      v_value := -1;
    Else
      v_value := 1;
    End If;
    Return v_value;
  End compare;

  -- @function  : AsGML
  -- @version   : 1.0
  -- @precis    : Returns coordinate as GML
  -- @return    : OGC GML
  -- @returntype: VarChar2
  -- @history   : SGG August 2006 - Original Coding
  --
  Member Function AsGML
    Return VarChar2 Deterministic
  Is
    v_gml   varchar2(4000);
  Begin
    v_gml := '<gml:Point gml:id="" srsName=""><gml:pos dimension="' || Self.ST_CoordDim || '">';
    Case Self.ST_CoordDim 
      When 2 Then
        v_gml := v_gml || To_Char(Self.X) || ' ' || To_Char(Self.Y);
      When 3 Then
        v_gml := v_gml || ' ' || To_Char(Self.Z);
      When 4 Then
        v_gml := v_gml || ' ' || To_Char(Self.M);
      Else
        NULL;
    End Case;
    v_gml := v_gml || '</gml:pos></gml:Point>';
  End AsGML;

  -- @function  : AsText
  -- @version   : 1.0
  -- @precis    : Returns coordinate as WKT
  -- @return    : OGC WKT
  -- @returntype: VarChar2
  -- @history   : SGG August 2006 - Original Coding
  --
  Member Function ST_AsText
    Return VarChar2 Deterministic
  Is
  Begin
    Case Self.ST_CoordDim 
      When 2 Then
        Return 'POINT(('   || To_Char(Self.X) || ' ' || To_Char(Self.Y) || '))';
      When 3 Then
        Return 'POINTZ(('  || To_Char(Self.X) || ' ' || To_Char(Self.Y) || ' ' || To_Char(Self.Z) || '))';
      When 4 Then
        Return 'POINTZM((' || To_Char(Self.X) || ' ' || To_Char(Self.Y) || ' ' || To_Char(Self.Z) ||  ' ' || To_Char(Self.M) || '))';
      Else
        Return NULL;
    End Case;
  End ST_AsText;

  -- @function  : AsSVG
  -- @version   : 1.0
  -- @precis    : Returns coordinate as SVG <point> xml
  -- @return    : SVG <point> XML
  -- @returntype: VarChar2
  -- @history   : SGG August 2006 - Original Coding
  --
  Member Function AsSVG
    Return VarChar2 Deterministic
  Is
  Begin
    RETURN '<point x=''' || To_Char(Self.X) || ''' y=''' || To_Char(Self.Y) || ''' />';
  End AsSVG;

END;
/
Show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'ST_POINT';
BEGIN
   FOR rec IN (select object_name || '.' || object_Type as package_name, status 
                 from user_objects
                where object_name = v_obj_name) LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line('Type ' || USER || '.' || rec.package_name || ' is valid.');
      ELSE
         dbms_output.put_line('Type ' || USER || '.' || rec.package_name || ' is invalid.');
         v_ok := false;
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

GRANT EXECUTE ON &&defaultSchema..ST_Point TO PUBLIC WITH GRANT OPTION;

CREATE TYPE &defaultSchema..ST_PointSet IS TABLE OF &defaultSchema..ST_Point
/
show errors

--alter type &defaultSchema..ST_PointSet
--  add map member function m  
--      return number invalidate
--/

GRANT EXECUTE ON &defaultSchema..ST_PointSet TO PUBLIC WITH GRANT OPTION;

purge recyclebin;

quit;

