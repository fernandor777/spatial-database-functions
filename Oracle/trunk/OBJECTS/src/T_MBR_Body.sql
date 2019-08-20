DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

-- Always aim for a clean compile
ALTER SESSION SET PLSQL_WARNINGS='ERROR:ALL';
-- Enable optimizations
ALTER SESSION SET plsql_optimize_level=2;

CREATE OR REPLACE TYPE BODY &&INSTALL_SCHEMA..T_MBR 
AS

  Constructor Function T_MBR(SELF IN OUT NOCOPY T_MBR)
                Return SELF As Result
  As
  Begin
    SELF.SetEmpty();
    Return;
  End T_MBR;

  Constructor Function T_MBR(SELF  IN OUT NOCOPY T_MBR,
                             p_mbr IN &&INSTALL_SCHEMA..T_MBR)
                Return SELF As Result
  As
  Begin
    SELF.SetEmpty();
    IF ( p_mbr is not null ) THEN
      SELF.MinX := p_mbr.MinX;
      SELF.MinY := p_mbr.MinY;
      SELF.MaxX := p_mbr.MaxX;
      SELF.MaxY := p_mbr.MaxY;
    END IF;
    Return;
  End T_MBR;

  Constructor Function T_MBR(SELF        IN OUT NOCOPY T_MBR,
                             p_geometry  IN MDSYS.SDO_GEOMETRY,
                             p_tolerance IN NUMBER DEFAULT 0.005)
                Return SELF As Result
  AS
    c_MaxVal   Constant Number :=  999999999999.99999999;
    c_MinVal   Constant Number := -999999999999.99999999;
    v_vertices mdsys.vertex_set_type;
    v_dimarray mdsys.sdo_dim_array := MDSYS.SDO_DIM_ARRAY(
                        MDSYS.SDO_DIM_ELEMENT('X',c_MinVal,c_MaxVal,p_tolerance),
                        MDSYS.SDO_DIM_ELEMENT('Y',c_minval,c_maxval,p_tolerance));
  begin
    if (p_geometry is null) then
      return;
    end if;
    /* If not licensed for SDO_MBR do this.
    SELECT min(v.x),max(v.x),min(v.y),max(v.y)
      INTO SELF.MinX, SELF.MaxX, SELF.MinY, SELF.MaxY
      FROM TABLE(mdsys.sdo_util.GetVertices(p_geometry)) v;
    */
    v_vertices := MDSYS.SDO_UTIL.GetVertices(MDSYS.SDO_GEOM.SDO_MBR(p_geometry,v_dimarray));
    if (v_vertices is null or v_vertices.count < 2) then
       return;
    end if;
    SELF.minx := v_vertices(1).x;
    SELF.maxx := v_vertices(1).y;
    SELF.miny := v_vertices(2).x;
    SELF.maxy := v_vertices(2).y;
    Return;
  end T_MBR;

  Constructor Function T_MBR(SELF       IN OUT NOCOPY T_MBR,
                             p_geometry IN MDSYS.SDO_GEOMETRY,
                             p_dimarray IN MDSYS.SDO_DIM_ARRAY )
                Return SELF As Result
  as
    v_vertices mdsys.vertex_set_type;
  begin
    if (p_geometry is null) then
      return;
    end if;
    v_vertices := mdsys.sdo_util.getVertices(mdsys.sdo_geom.sdo_mbr(p_geometry,p_dimarray));
    if (v_vertices is null or v_vertices.count < 2) then
       return;
    end if;
    SELF.minx := v_vertices(1).x;
    SELF.maxx := v_vertices(1).y;
    SELF.miny := v_vertices(2).x;
    SELF.maxy := v_vertices(2).y;
    Return;
  END T_MBR;

  Constructor Function T_MBR(SELF      IN OUT NOCOPY T_MBR,
                             p_dX      In NUMBER,
                             p_dY      In Number,
                             p_dExtent In Number )
                Return SELF As Result
  As
  Begin
    SELF.MinX := p_dX - (p_dExtent / 2);
    SELF.MinY := p_dY - (p_dExtent / 2);
    SELF.MaxX := p_dX + (p_dExtent / 2);
    SELF.MaxY := p_dY + (p_dExtent / 2);
    Return;
  End T_MBR;

  Constructor Function T_MBR(SELF      IN OUT NOCOPY T_MBR,
                             p_Vertex  In &&INSTALL_SCHEMA..T_Vertex,
                             p_dExtent In Number )
                Return SELF As Result
  As
  Begin
    SELF.MinX := p_Vertex.X - (p_dExtent / 2);
    SELF.MinY := p_Vertex.Y - (p_dExtent / 2);
    SELF.MaxX := p_Vertex.X + (p_dExtent / 2);
    SELF.MaxY := p_Vertex.Y + (p_dExtent / 2);
    Return;
  End T_MBR;

  -- ==============================================================
  -- ================ Modifiers ===================================
  -- ==============================================================

  Member Procedure SetEmpty(SELF IN OUT NOCOPY T_MBR)
  As
    c_MaxVal Constant Number :=  999999999999.99999999;
    c_MinVal Constant Number := -999999999999.99999999;
  Begin
    -- Set extents
    SELF.MinX := c_MaxVal;
    SELF.MinY := c_MaxVal;
    SELF.MaxX := c_MinVal;
    SELF.MaxY := c_MinVal;
    Return;
  End SetEmpty;

  Member Function SetToPart(p_geometry in mdsys.sdo_geometry, 
                            p_which    in integer /* 0 smallest, 1 largest */ )
           Return &&INSTALL_SCHEMA..T_MBR Deterministic
  Is
    v_self      &&INSTALL_SCHEMA..T_MBR;
    v_elem_mbr  &&INSTALL_SCHEMA..T_MBR;
    v_which     pls_integer := NVL(p_which,1);
    v_element   mdsys.sdo_geometry;
    v_num_elems pls_integer;
  BEGIN
    v_self := &&INSTALL_SCHEMA..T_MBR(SELF);
    if ( p_geometry is null ) then
        return v_self;
    end if;
    if ( p_geometry.get_gtype() in (6,7) ) Then
        v_num_elems := MDSYS.SDO_UTIL.GETNUMELEM(p_geometry);
        <<all_elements>>
        FOR v_elem_no IN 1..v_num_elems LOOP
             -- Get part 
             v_element := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_elem_no);
             v_elem_MBR := New &&INSTALL_SCHEMA..T_MBR(p_geometry=>v_element);
             If ( v_elem_no = 1 ) Then
                v_SELF := v_elem_MBR;
             ElsIf ( (   ( v_SELF.maxx     - v_SELF.Minx ) * (     v_SELF.maxy -     v_SELF.miny      ) ) <
                   ( ( v_elem_MBR.maxx - v_elem_MBR.Minx ) * ( v_elem_MBR.maxy - v_elem_MBR.miny ) ) ) Then
                If ( p_which = 1 ) then
                   v_SELF := v_elem_MBR;
                End If;
             Else
                If ( p_which = 0 ) then
                   v_SELF := v_elem_MBR;
                End If;
             End If;
        END LOOP all_elements;
    End If;
    Return &&INSTALL_SCHEMA..T_MBR(v_elem_MBR);
  End SetToPart;
  
  Member Function SetSmallestPart(p_geometry IN MDSYS.SDO_GEOMETRY )
           Return &&INSTALL_SCHEMA..T_MBR Deterministic
  Is
  BEGIN
    Return SELF.SetToPart(p_geometry,0);
  END SetSmallestPart;
  
  Member Function SetLargestPart(p_geometry IN MDSYS.SDO_GEOMETRY )
           Return &&INSTALL_SCHEMA..T_MBR Deterministic
  IS
  BEGIN
    Return SELF.SetToPart(p_geometry,1);
  END SetLargestPart;

  Member Function Normalize(p_dRatio In Number)
           Return &&INSTALL_SCHEMA..T_MBR Deterministic
  As
    v_dWidth  number;
    v_dHeight number;
    v_dX      number;
    v_dY      number;
    v_dRatio  number := NVL(p_dRatio,0);
    v_self    &&INSTALL_SCHEMA..T_MBR;
  Begin
    v_self := &&INSTALL_SCHEMA..T_MBR(SELF);
    IF ( v_dRatio = 0 ) Then
      Return &&INSTALL_SCHEMA..T_MBR(SELF);
    ElsIf ( v_dRatio > 0 ) Then
      -- Compute new width
      v_dWidth  := SELF.Height() * p_dRatio;
      -- Compute new minx and maxx based on centre
      v_dX      := SELF.X();
      v_SELF.MinX := v_dX - (v_dWidth / 2.0);
      v_SELF.MaxX := v_dX + (v_dWidth / 2.0);
    ElsIf ( v_dRatio < 0 ) Then
      v_dRatio  := ABS(p_dRatio);
      -- Compute new height
      v_dHeight := SELF.Width() * v_dRatio;
      -- Compute new minx and maxx based on centre
      v_dY      := SELF.Y();
      v_SELF.MinY := v_dY - (v_dHeight / 2.0);
      v_SELF.MaxY := v_dY + (v_dHeight / 2.0);
    Else
      NULL; -- no change
    End If;
    Return v_self;
  End Normalize;

  Member Function Expand(p_dX IN NUMBER,
                         p_dY IN NUMBER)
           Return &&INSTALL_SCHEMA..T_MBR 

  Is
    v_self    &&INSTALL_SCHEMA..T_MBR;
  Begin
    v_self := &&INSTALL_SCHEMA..T_MBR(SELF);
    If (p_dX Is Null Or p_dY Is Null) Then
       Return &&INSTALL_SCHEMA..T_MBR(SELF);
     ElsIf ( SELF.IsEmpty() ) Then
       v_SELF.MinX := p_dX;
       v_SELF.MaxX := p_dX;
       v_SELF.MinY := p_dY;
       v_SELF.MaxY := p_dY;
     Else
       If (p_dX < SELF.MinX) Then
         v_SELF.MinX := p_dX;
       End If;
       If (p_dX > SELF.MaxX) Then
         v_SELF.MaxX := p_dX;
       End If;
       If (p_dY < SELF.MinY) Then
         v_SELF.MinY := p_dY;
       End If;
       If (p_dY > SELF.MaxY) Then
         v_SELF.MaxY := p_dY;
       End If;
     End If;
     Return v_self;
  End Expand;

  Member Function Expand(p_Vertex IN &&INSTALL_SCHEMA..T_Vertex)
           Return &&INSTALL_SCHEMA..T_MBR 
  Is
  Begin
    Return SELF.Expand(p_dX=>p_Vertex.X, p_dY=>p_Vertex.Y);
  End Expand;

  Member Function Expand(p_other IN &&INSTALL_SCHEMA..T_MBR)
           Return &&INSTALL_SCHEMA..T_MBR Deterministic
  Is
    v_self &&INSTALL_SCHEMA..T_MBR;
  Begin
    v_self := &&INSTALL_SCHEMA..T_MBR(SELF);
    If (p_other is NULL) Then
      Return v_self;
    End If;
    If ( SELF.isEmpty() ) Then
      v_SELF.MinX := p_other.MinX;
      v_SELF.MaxX := p_other.MaxX;
      v_SELF.MinY := p_other.MinY;
      v_SELF.MaxY := p_other.MaxY;
    Else
      If (p_other.MinX < SELF.MinX) Then
        v_SELF.MinX := p_other.MinX;
      End If;
      If (p_other.MaxX > SELF.MaxX) Then
        v_SELF.MaxX := p_other.MaxX;
      End If;
      If (p_other.MinY < SELF.MinY) Then
        v_SELF.MinY := p_other.MinY;
      End If;
      If (p_other.MaxY > SELF.MaxY) Then
        v_SELF.MaxY := p_other.MaxY;
      End If;
    End If;
    Return v_SELF;
  End Expand;

  Member Function isEmpty
           Return Boolean
  Is
  Begin
    Return (SELF.MinX > SELF.MaxX);
  End isEmpty;

  Member Function Contains( p_other In &&INSTALL_SCHEMA..T_MBR )
           Return Boolean
  Is
  Begin
    Return (p_other.MinX >= SELF.MinX And
            p_other.MaxX <= SELF.MaxX And
            p_other.MinY >= SELF.MinY And
            p_other.MaxY <= SELF.MaxY);
  End Contains;

  Member Function Contains( p_dX In Number,
                            p_dY In Number )
           Return Boolean
  Is
  Begin
    Return (p_dX >= SELF.MinX And
            p_dX <= SELF.MaxX And
            p_dY >= SELF.MinY And
            p_dY <= SELF.MaxY);
  End Contains;

  Member Function Contains( p_vertex In mdsys.vertex_type )
           Return Boolean
  Is
  Begin
    Return SELF.Contains(p_dX=>p_vertex.X,p_dY=>p_vertex.Y);
  End Contains;

  Member Function Contains( p_vertex In &&INSTALL_SCHEMA..T_Vertex )
           Return Boolean
  Is
  Begin
    Return SELF.Contains(p_dX=>p_vertex.X,p_dY=>p_vertex.Y);
  End Contains;

  Member Function Equals(p_other In &&INSTALL_SCHEMA..T_MBR)
           Return Boolean
  Is
  Begin
    If (p_Other Is Null) Then
      Return False;
    End If;
    Return (SELF.MaxX = p_other.MaxX And
            SELF.MaxY = p_other.MaxY And
            SELF.MinX = p_other.MinX And
            SELF.MaxX = p_other.MaxX);
  End Equals;

  Member Function Intersection(p_other In &&INSTALL_SCHEMA..T_MBR)
           Return &&INSTALL_SCHEMA..T_MBR Deterministic
  Is
    c_MaxVal Constant Number :=  999999999999.99999999;
    c_MinVal Constant Number := -999999999999.99999999;
    v_LL     &&INSTALL_SCHEMA..T_Vertex;
    v_UR     &&INSTALL_SCHEMA..T_Vertex;
    v_self   &&INSTALL_SCHEMA..T_MBR;

    Function MiddleValue(p_dValue In Number,
                         p_dMin   In Number,
                         p_dMax   In Number)
      Return Number
    Is
    Begin
      If (p_dValue < p_dMin) Then
        Return p_dMin;
      ElsIf (p_dValue > p_dMax) Then
        Return p_dMax;
      Else
        Return p_dValue;
      End If;
    End;

  Begin
    v_self   := &&INSTALL_SCHEMA..T_MBR(SELF);
    v_LL     := New &&INSTALL_SCHEMA..T_Vertex(p_x=>c_MaxVal,p_y=>c_MaxVal);
    v_UR     := New &&INSTALL_SCHEMA..T_Vertex(p_x=>c_MaxVal,p_y=>c_MaxVal);
    -- Find minx
    v_LL.X   := MiddleValue(p_other.MinX, SELF.MinX, SELF.MaxX);
    v_LL.Y   := MiddleValue(p_other.MinY, SELF.MinY, SELF.MaxY);
    v_UR.X   := MiddleValue(p_other.MaxX, SELF.MinX, SELF.MaxX);
    v_UR.Y   := MiddleValue(p_other.MaxY, SELF.MinY, SELF.MaxY);
    v_SELF.MinX := v_LL.X;
    v_SELF.MinY := v_LL.Y;
    v_SELF.MaxX := v_UR.X;
    v_SELF.MaxY := v_UR.Y;
    Return v_self;
  End Intersection;

  Member Function Compare(p_other In &&INSTALL_SCHEMA..T_MBR)
           Return Integer
  Is
    mTmpMBR &&INSTALL_SCHEMA..T_MBR;
  Begin
    If SELF.equals(p_other) Then
      Return 100;
    ElsIf SELF.contains(p_other) Then
      Return (p_other.Height * p_other.Width) / ( SELF.Height() * SELF.Width() );
    ElsIf SELF.overlap(p_other) Then
      mTmpMBR := SELF.Intersection(p_other);
      Return (mTmpMBR.Height() * mTmpMBR.Width()) / ( SELF.Height() * SELF.Width() );
    Else
      Return 0; -- They don't overlap
    End If;
  End Compare;

  Member Function Overlap(p_other in &&INSTALL_SCHEMA..T_MBR)
           Return Boolean
  Is
  Begin
    Return Not (p_other.MinX > SELF.MaxX Or
                p_other.MaxX < SELF.MinX Or
                p_other.MinY > SELF.MaxY Or
                p_other.MaxY < SELF.MinY);
  End Overlap;

  Static Function Intersects(p1 in &&INSTALL_SCHEMA..T_Vertex, 
                             p2 in &&INSTALL_SCHEMA..T_Vertex, 
                             q  in &&INSTALL_SCHEMA..T_Vertex)
           Return boolean
  As
  Begin
    -- direct Comparison. 
    if (( (q.x >= (case when p1.x < p2.x then p1.x else p2.x end)) AND (q.x <= (case when p1.x > p2.x then p1.x else p2.x end)) ) AND
	( (q.y >= (case when p1.y < p2.y then p1.y else p2.y end)) AND (q.y <= (case when p1.y > p2.y then p1.y else p2.y end)) )) then
      return true;
    End If;
    return false;
  end Intersects;

  Static Function Intersects (
                      p1 in &&INSTALL_SCHEMA..t_vertex, p2 in &&INSTALL_SCHEMA..T_Vertex, 
                      q1 in &&INSTALL_SCHEMA..t_vertex, q2 in &&INSTALL_SCHEMA..t_vertex)
           return boolean 
  As
    minq Number;
    maxq Number;
    minp Number;
    maxp Number;
  Begin  
    minq := LEAST(q1.x, q2.x);
    maxq := GREATEST(q1.x, q2.x);
    minp := LEAST(p1.x, p2.x);
    maxp := GREATEST(p1.x, p2.x);

    if( minp > maxq ) then
        return false;
    end if;
    if( maxp < minq ) then
        return false;
    end if;

    minq := LEAST(q1.y, q2.y);
    maxq := GREATEST(q1.y, q2.y);
    minp := LEAST(p1.y, p2.y);
    maxp := GREATEST(p1.y, p2.y);

    if( minp > maxq ) then
        return false;
    end If;
    if( maxp < minq ) then
        return false;
    end if;
    return true;
  End Intersects;
  
  Member Function X
           Return Number
  Is
  Begin
    Return (SELF.MaxX + SELF.MinX) / 2.0;
  End X;

  Member Function Y
           Return Number
  Is
  Begin
    Return (SELF.MaxY + SELF.MinY) / 2.0;
  End Y;

  Member Function Width
    Return Number
  Is
  Begin
     Return Abs(SELF.MaxX - SELF.MinX);
  End Width;

  Member Function Height
    Return Number
  Is
  Begin
     Return Abs(SELF.MaxY - SELF.MinY);
  End Height;

  Member Function Area
         Return Number
  Is
  Begin
    Return ( SELF.Width() * SELF.Height() );
  End Area;

  Member Function Centre
           Return &&INSTALL_SCHEMA..T_Vertex
  Is
  Begin
      Return &&INSTALL_SCHEMA..T_Vertex(p_x=>SELF.X() ,p_y=>SELF.Y() );
  End Centre;

  Member Function Center
           Return &&INSTALL_SCHEMA..T_Vertex
  Is
  Begin
      Return &&INSTALL_SCHEMA..T_Vertex(p_x=>SELF.X() ,p_y=>SELF.Y() );
  End Center;

  Member Function AsDimArray
           Return MDSYS.SDO_DIM_ARRAY
  Is
  Begin
    Return ( MDSYS.SDO_DIM_ARRAY(
                   MDSYS.SDO_DIM_ELEMENT('X', SELF.minx, SELF.maxx, .0),
                   MDSYS.SDO_DIM_ELEMENT('Y', SELF.miny, SELF.maxy, .0)));
  End AsDimArray;

  Member Function AsString
           Return VarChar2
  Is
  Begin
    RETURN '<mbr minx=''' || To_Char(SELF.MinX) || ''' miny=''' || To_Char(SELF.MinY) || ''' maxx=''' || To_Char(SELF.MaxX) || ''' maxy=''' || To_Char(SELF.MaxY) || ''' />';
  End AsString;

  Member Function AsCSV
           Return VarChar2
  Is
  Begin
    RETURN To_Char(SELF.MinX) || ',' || To_Char(SELF.MinY) || ',' || To_Char(SELF.MaxX) || ',' || To_Char(SELF.MaxY);
  End AsCSV;

  Member Function AsWKT
           Return VARCHAR2
  IS
  BEGIN
    RETURN 'POLYGON((' ||
      TO_CHAR(SELF.minx) || ' ' || TO_CHAR(SELF.miny) ||','||
      TO_CHAR(SELF.maxx) || ' ' || TO_CHAR(SELF.miny) ||','||
      TO_CHAR(SELF.maxx) || ' ' || TO_CHAR(SELF.maxy) ||','||
      TO_CHAR(SELF.minx) || ' ' || TO_CHAR(SELF.maxy) ||','||
      TO_CHAR(SELF.minx) || ' ' || TO_CHAR(SELF.miny) ||'))';
  END AsWKT;

  Member Function AsSVG
           Return VarChar2
  Is
  BEGIN
    RETURN '<rect x=''' || To_Char(SELF.MinX) || ''' y=''' || To_Char(SELF.MinY) || ''' width=''' || To_Char(SELF.Width) || ''' height=''' || To_Char(SELF.Height) || ''' />';
  End AsSVG;

  Member Function getCentreAsSVG
           Return VarChar2
  Is
  Begin
    RETURN '<point x=''' || To_Char(SELF.X() ) || ''' y=''' || To_Char(SELF.Y() ) || ''' />';
  End GetCentreAsSVG;

  Order Member Function Evaluate(p_other In &&INSTALL_SCHEMA..T_MBR)
                 Return Integer
  Is
  Begin
    If (MinX < p_other.MinX) Then
      If (MinY <= p_other.MinY) Then
         Return -1;
      ElsIf (MinY = p_other.MinY) Then
         Return -1;
      End If;
    ElsIf (MinX = p_other.MinX) Then
      If (MinY < p_other.MinY) Then
         Return -1;
      ElsIf (MinY = p_other.MinY) Then
         Return 0;
      End If;
    Else
      Return 1;
    End If;
    Return 0;
  End Evaluate;
  
END;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := FALSE;
   v_obj_name varchar2(30) := 'T_MBR';
BEGIN
   FOR rec IN (select object_name || '.' || object_Type as package_name, 
                      status 
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'TYPE BODY'
              ) 
   LOOP
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
END;
/
SHOW ERRORS

EXIT SUCCESS;


