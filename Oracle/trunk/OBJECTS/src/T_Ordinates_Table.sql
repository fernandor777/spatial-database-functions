create or replace TYPE SPDBA.T_ORDINATES
AUTHID DEFINER
AS OBJECT (

  ordinates mdsys.sdo_numtab,
  
  Constructor Function T_ORDINATES(SELF IN OUT NOCOPY SPDBA.T_ORDINATES)
                Return Self As Result,

  Constructor Function T_ORDINATES(SELF        IN OUT NOCOPY SPDBA.T_ORDINATES,
                                   p_ordinates in mdsys.sdo_numtab)
                Return Self As Result,

  Constructor Function T_ORDINATES(SELF        IN OUT NOCOPY SPDBA.T_ORDINATES,
                                   p_ordinates in mdsys.sdo_ordinate_array)
                Return Self As Result,

  -- ***************************************************************
  
  Member Function ST_Self
           Return SPDBA.T_ORDINATES Deterministic,

  Member Procedure ADD_Coordinate( 
            p_dim        in number,
            p_x_coord    in number,
            p_y_coord    in number,
            p_z_coord    in number,
            p_m_coord    in number,
            p_measured   in boolean := false
          ),

  Member Procedure ADD_Coordinate(
            p_dim        in number,
            p_coord      in SPDBA.T_Vertex
         ),

  Member Procedure ADD_Coordinate( 
            p_dim        in number,
            p_coord      in mdsys.vertex_type,
            p_measured   in boolean := false
         ),

  Member Procedure ADD_Coordinate( 
            p_dim        in number,
            p_coord      in mdsys.sdo_point_type,
            p_measured   in boolean := false 
         ),

  Member Procedure ADD_ARRAY( p_ordinates in mdsys.sdo_numtab ),

  Member Procedure ADD_ARRAY( p_ordinates in mdsys.sdo_ordinate_array ),

  Member Function ST_AsOrdinateArray
           Return mdsys.sdo_ordinate_array

)
INSTANTIABLE NOT FINAL;
/
show errors

create or replace 
type body       t_ordinates
As

  Constructor Function T_ORDINATES(SELF IN OUT NOCOPY SPDBA.T_ORDINATES)
       Return Self AS Result
  AS
  BEGIN
    SELF.ordinates := NULL;
    Return;
  END T_Ordinates;

  Constructor Function T_ORDINATES(SELF IN OUT NOCOPY SPDBA.T_ORDINATES,
                                   p_ordinates in mdsys.sdo_numtab )
       Return Self AS Result
  AS
  BEGIN
    SELF.ordinates := p_ordinates;
    Return;
  END T_Ordinates;

  Constructor Function T_ORDINATES(SELF IN OUT NOCOPY SPDBA.T_ORDINATES,
                                   p_ordinates in mdsys.sdo_ordinate_array )
       Return Self AS Result
  AS
  BEGIN
    IF ( p_ordinates is null or p_ordinates.COUNT < 1 ) THEN
      Return;
    END IF;
    SELF.ordinates := mdsys.sdo_numTab(0);
    SELF.ordinates.TRIM();
    FOR i IN 1..p_ordinates.COUNT LOOP
       SELF.ordinates(i) := p_ordinates(i);
    END LOOP;
    Return;
  END T_Ordinates;

  -- **************************************************************
  
  Member Function ST_Self
           Return SPDBA.T_ORDINATES
  AS
  BEGIN
    Return SELF; -- SPDBA.T_Ordinates(SELF);
  END ST_Self;

  Member Procedure ADD_Coordinate( 
         p_dim        in number,
         p_x_coord    in number,
         p_y_coord    in number,
         p_z_coord    in number,
         p_m_coord    in number,
         p_measured   in boolean := false)
  IS
  Begin
    IF ( p_dim >= 2 ) THEN
      SELF.ordinates.extend(2);
      SELF.ordinates(SELF.ordinates.count-1) := p_x_coord;
      SELF.ordinates(SELF.ordinates.count  ) := p_y_coord;
    END IF;
    IF ( p_dim >= 3 ) Then
      SELF.ordinates.extend(1);
      SELF.ordinates(SELF.ordinates.count)   := case when p_dim = 3 And p_measured
                                                     then p_m_coord
                                                     else p_z_coord
                                                end;
    END IF;
    IF ( p_dim = 4 ) Then
      SELF.ordinates.extend(1);
      SELF.ordinates(SELF.ordinates.count)   := p_m_coord;
    END IF;
    RETURN;
  END ADD_Coordinate;

  Member Procedure  ADD_Coordinate( 
           p_dim   in number,
           p_coord in spdba.T_Vertex
         )
  Is
  Begin
    SELF.ADD_Coordinate( p_dim, p_coord.x, p_coord.y, p_coord.z, p_coord.w, 
                         case when p_coord.ST_IsMeasured() = 1 then TRUE else FALSE end);
  END Add_Coordinate;

  Member Procedure ADD_Coordinate( 
           p_dim      in number,
           p_coord    in mdsys.vertex_type,
           p_measured in boolean := false
         )
  Is
  Begin
    SELF.ADD_Coordinate( p_dim, p_coord.x, p_coord.y, p_coord.z, p_coord.w, p_measured);
  END Add_Coordinate;

  Member Procedure ADD_Coordinate( 
           p_dim      in number,
           p_coord    in mdsys.sdo_point_type,
            p_measured in boolean := false
         )
  Is
  Begin
    SELF.ADD_Coordinate( p_dim, p_coord.x, p_coord.y, p_coord.z, NULL, p_measured);
  END Add_Coordinate;

  Member Procedure ADD_ARRAY( p_ordinates in mdsys.sdo_numtab )
  Is
  Begin
    SELF.ordinates := SELF.Ordinates MULTISET UNION p_ordinates;
  End Add_Array;

  Member Procedure ADD_ARRAY( p_ordinates in mdsys.sdo_ordinate_array )
  Is
    v_base pls_integer;
  Begin
    if ( p_ordinates is null or p_ordinates.COUNT = 1 ) then
      return;
    End If;
    if ( SELF.ordinates is null ) then
      SELF.ordinates := mdsys.sdo_numTab(0);
      SELF.ordinates.TRIM();
    end If;
    v_base := SELF.ordinates.COUNT;
    SELF.ordinates.EXTEND(p_ordinates.COUNT);
    FOR i IN 1..p_ordinates.COUNT LOOP
       SELF.ordinates(v_base + i) := p_ordinates(i);
    END LOOP;
  END;

  Member Function ST_AsOrdinateArray
  Return mdsys.sdo_ordinate_array
  As
    v_ordinates mdsys.sdo_ordinate_array;
  Begin
    IF (SELF.ordinates is null or SELF.ordinates.COUNT < 1 ) THEN
      RETURN NULL;
    END IF;
    SELECT t.COLUMN_VALUE
      BULK COLLECT INTO v_ordinates
      FROM TABLE(SELF.ordinates) t;
    RETURN v_ordinates;
  End ST_AsOrdinateArray;

END;
/
show errors

/*
set serveroutput on size unlimited
declare
  TYPE t_ords    IS table of number;
  v_ords1     t_ords := t_ords(0,0,1,1,2,2);
  v_ords2     t_ords := t_ords(3,3,4,4,5,5);
  v_ords3     t_ords;
  ordinates   mdsys.sdo_ordinate_array := mdsys.sdo_ordinate_array(0,0,1,1,2,2);
  result      mdsys.sdo_ordinate_array;
begin
  result := ordinates;
  for i in 1..result.COUNT loop
    dbms_output.put_line(result(i));
  end loop;
  for i in 1..v_ords1.COUNT loop
    dbms_output.put_line(v_ords1(i));
  end loop;
  if ( v_ords1 = v_ords1 ) Then
    dbms_output.put_line('v_ords1=v_ords1');
  end if;
  if ( v_ords1 <> v_ords2 ) Then
    dbms_output.put_line('v_ords2<>v_ords2');
  end if;
  v_ords3 := v_ords1 multiset union v_ords2;
  for i in 1..v_ords3.COUNT loop
    dbms_output.put_line('v_ords3='||v_ords3(i));
  end loop;
end;
/
show errors
*/
