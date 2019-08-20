DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

-- Always aim for a clean compile
ALTER SESSION SET PLSQL_WARNINGS='ERROR:ALL';
-- Enable optimizations
-- ALTER SESSION SET plsql_optimize_level=2;

CREATE OR REPLACE TYPE BODY &&INSTALL_SCHEMA..T_VECTOR3D 
AS

  Constructor Function T_VECTOR3D( SELF      IN OUT NOCOPY T_VECTOR3D,
	                           p_SEGMENT IN &&INSTALL_SCHEMA..T_SEGMENT)
                Return Self As Result 
  as
  Begin
    SELF.x := p_SEGMENT.endCoord.x - p_SEGMENT.startCoord.x;
    SELF.y := p_SEGMENT.endCoord.y - p_SEGMENT.startCoord.y;
    SELF.z := p_SEGMENT.endCoord.z - p_SEGMENT.startCoord.z;
    Return;
  End T_VECTOR3D;

  Constructor Function T_VECTOR3D( SELF           IN OUT NOCOPY T_VECTOR3D,
	                           p_start_vertex IN &&INSTALL_SCHEMA..T_Vertex,
                                   p_end_vertex   IN &&INSTALL_SCHEMA..T_Vertex)
                Return Self As Result 
  as
  begin
    SELF.x := p_end_Vertex.x - p_start_Vertex.x;
    SELF.y := p_end_Vertex.y - p_start_Vertex.y;
    SELF.z := p_end_Vertex.z - p_start_Vertex.z;
    Return;
  end T_VECTOR3D;

  Constructor Function T_VECTOR3D( SELF     IN OUT NOCOPY T_VECTOR3D,
	                           p_vertex IN &&INSTALL_SCHEMA..T_Vertex)
                Return Self As Result 
  as
  begin
    SELF.x := p_vertex.x;
    SELF.y := p_vertex.y;
    SELF.z := p_vertex.z;
    return;
  end T_VECTOR3D;

  Constructor Function T_VECTOR3D( SELF      IN OUT NOCOPY T_VECTOR3D,
                                   p_SEGMENT iN &&INSTALL_SCHEMA..T_VECTOR3D)
                Return Self As Result as
  begin
    SELF.x := p_SEGMENT.x;
    SELF.y := p_SEGMENT.y;
    SELF.z := p_SEGMENT.z;
    return;
  end T_VECTOR3D;

  Member Function cross(v1 in &&INSTALL_SCHEMA..T_VECTOR3D)
           Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic
  as
    x number;
    y number;
  begin
    x := SELF.y*v1.z - SELF.z*v1.y;
    y := v1.x*SELF.z - v1.z*SELF.x;
    return &&INSTALL_SCHEMA..T_VECTOR3D(x,y,SELF.x*v1.y - SELF.y*v1.x);
  end cross;

  Member Function dot(v1 in &&INSTALL_SCHEMA..T_VECTOR3D)
           Return Number Deterministic
  as
  begin
    return (SELF.x*v1.x + SELF.y*v1.y + NVL(SELF.z*v1.z,0));
  end dot;

  Member Function normalize(v1 in &&INSTALL_SCHEMA..T_VECTOR3D )
           Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic
  as
    norm number;
  Begin
    norm := 1.0/SQRT(v1.x*v1.x + v1.y*v1.y + NVL(v1.z*v1.z,0));
    return &&INSTALL_SCHEMA..T_VECTOR3D(v1.x*norm,
                    v1.y*norm,
                    v1.z*norm);
  end normalize;

  Member Function normalize
           Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic
  as
    norm number;
  begin
    norm := 1.0/SQRT(SELF.x*SELF.x + SELF.y*SELF.y + NVL(SELF.z*SELF.z,0));
    RETURN &&INSTALL_SCHEMA..T_VECTOR3D(SELF.x * norm,
                    SELF.y * norm,
                    SELF.z * norm);
  end normalize;

  Member Function MagnitudeSquared
           Return Number Deterministic
  as
  begin
    return (SELF.x*SELF.x + SELF.y*SELF.y + NVL(SELF.z*SELF.z,0));
  end MagnitudeSquared;

  Member Function Magnitude
           Return Number Deterministic
  as
  begin
    return SQRT(SELF.x*SELF.x + SELF.y*SELF.y + NVL(SELF.z*SELF.z,0));
  end Magnitude;

  Member Function angle(v1 in &&INSTALL_SCHEMA..T_VECTOR3D)
           Return Number Deterministic
  as
     vDot Number;
  Begin
     vDot := SELF.dot(v1) / ( SELF.Magnitude()*v1.Magnitude() );
      if ( vDot < -1.0) then vDot := -1.0; End If;
      if ( vDot >  1.0) then vDot :=  1.0; End If;
      return ACOS( vDot );
  end angle;

  Member Function Subtract(v1 in &&INSTALL_SCHEMA..T_VECTOR3D)
           Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic
  as
  Begin
    Return New &&INSTALL_SCHEMA..T_VECTOR3D(
                 SELF.x - v1.x,
                 SELF.y - v1.y,
                 SELF.z - v1.z);
  End subtract;

  Member Function Multiply(p_scalar in Number)
           Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic
  As
  Begin
     return new &&INSTALL_SCHEMA..T_VECTOR3D(
                  SELF.X * p_scalar,
                  SELF.Y * p_scalar,
                  SELF.Z * p_scalar);
  End Multiply;

  Member Function Divide(p_scalar in Number)
           Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic
  As
    s Number := 1 / p_scalar;
  Begin
     return new &&INSTALL_SCHEMA..T_VECTOR3D(
                  SELF.X * s,
                  SELF.Y * s,
                  SELF.Z * s);
  End Divide;

  Member Function addv(v1 in &&INSTALL_SCHEMA..T_VECTOR3D)
           Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic
  As
    i pls_integer;
  Begin
    Return new &&INSTALL_SCHEMA..T_VECTOR3D(SELF.x + v1.x,
                        SELF.y + v1.y,
                        SELF.z + v1.z);
  End addv;

  Member Function Distance(p_point in &&INSTALL_SCHEMA..T_VECTOR3D)
           Return Number Deterministic
  As
  Begin
    return SELF.subtract(p_point).Magnitude();
  End Distance;

  Member Function Distance(p_point in &&INSTALL_SCHEMA..T_Vertex )
           Return Number Deterministic
  As
  Begin
     Return SELF.Distance(T_VECTOR3D(p_point));
  End Distance;

  Member Function DistanceSquared(p_point in &&INSTALL_SCHEMA..T_VECTOR3D)
           Return Number Deterministic
  As
  Begin
    Return SELF.subtract(p_point).MagnitudeSquared();
  End DistanceSquared;

  Member Function DistanceSquared(p_point in &&INSTALL_SCHEMA..T_Vertex)
           Return Number Deterministic
  As
  Begin
    Return SELF.subtract(T_VECTOR3D(p_point)).MagnitudeSquared();
  End DistanceSquared;

  Member Function ProjectOnLine(pointOnLine1 in &&INSTALL_SCHEMA..T_VECTOR3D,
                                pointOnLine2 in &&INSTALL_SCHEMA..T_VECTOR3D)
           Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic
  As
    t &&INSTALL_SCHEMA..T_VECTOR3D;
    u &&INSTALL_SCHEMA..T_VECTOR3D;
    n Number;
  Begin
    t := pointOnLine2.subtract(pointOnLine1);
    u := SELF.subtract(pointOnLine1);
    n := u.dot(t) / t.MagnitudeSquared();
    return pointOnLine1.addv(t.multiply(n));
  End ProjectOnLine;

  Member Function ProjectOnLine(p_line in &&INSTALL_SCHEMA..T_SEGMENT)
           Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic
  As
    pointOnLine1 &&INSTALL_SCHEMA..T_VECTOR3D := &&INSTALL_SCHEMA..T_VECTOR3D(p_line.startCoord);
    pointOnLine2 &&INSTALL_SCHEMA..T_VECTOR3D := &&INSTALL_SCHEMA..T_VECTOR3D(p_line.endCoord);
    t            &&INSTALL_SCHEMA..T_VECTOR3D;
    u            &&INSTALL_SCHEMA..T_VECTOR3D;
    n            Number;
  Begin
    t := pointOnLine2.subtract(pointOnLine1);
    u := SELF.subtract(pointOnLine1);
    n := u.dot(t) / t.MagnitudeSquared();
    return pointOnLine1.addv(t.multiply(n));
  End ProjectOnLine;

  Member Function Negate
           Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic
  As
  Begin
    return new &&INSTALL_SCHEMA..T_VECTOR3D(-SELF.X,-SELF.Y,-SELF.Z);
  End Negate;

  Member Function zero
           Return &&INSTALL_SCHEMA..T_VECTOR3D Deterministic
  As
  Begin
    Return &&INSTALL_SCHEMA..T_VECTOR3D(0.0,0.0,0.0);
  End zero;

  Member Function AsText(p_round IN integer DEFAULT 9)
           Return Varchar2 Deterministic
  As
    v_precision pls_integer := NVL(p_round,9);
  Begin
    Return 'T_VECTOR3D(x='||NVL(TO_CHAR(ROUND(SELF.x,v_precision)),'NULL')||
                     ',y='||NVL(TO_CHAR(ROUND(SELF.y,v_precision)),'NULL')||
                     ',z='||NVL(TO_CHAR(ROUND(SELF.z,v_precision)),'NULL')||')';
  End AsText;

  Member Function AsSdoGeometry(p_srid in integer default null)
           Return mdsys.sdo_geometry Deterministic
  As
  Begin
    Return mdsys.sdo_geometry(3001,p_srid,mdsys.sdo_point_type(SELF.X,SELF.Y,SELF.Z),NULL,NULL);
  End AsSdoGeometry;

  Member Function Equals(p_vector3D in &&INSTALL_SCHEMA..T_Vector3D)
           Return Integer Deterministic
  Is
    v_vector3D &&INSTALL_SCHEMA..T_Vector3D;
  Begin
    If (p_vector3D is null) Then
       Return 0; /* False */
    End If;
    -- Two vectors are equal if length (magnitude) and direction are equal
    v_vector3D := SELF.Subtract(p_vector3D);
    IF ( (  v_vector3D.X = 0 and v_vector3D.Y = 0 and NVL(v_vector3D.Z,0) = 0 )
       AND /* Magnitude */
           SELF.Magnitude() = p_vector3d.Magnitude() ) Then
       Return 1; /* True */
    Else
       Return 0; /* False */
    END IF;
  End Equals;
  
end;
/
SHOW ERRORS

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := FALSE;
   v_obj_name varchar2(30) := 'T_VECTOR3D';
BEGIN
   FOR rec IN (select object_name,object_Type, status 
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'TYPE BODY'
               order by object_type
              ) 
   LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is valid.');
         v_ok := TRUE;
      ELSE
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is invalid.');
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

WHENEVER SQLERROR CONTINUE;

EXIT SUCCESS;

