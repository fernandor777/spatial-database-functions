DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

CREATE OR REPLACE EDITIONABLE TYPE BODY &&INSTALL_SCHEMA..T_VERTEX 
AS
  Constructor Function T_Vertex(SELF IN OUT NOCOPY T_Vertex)
                Return Self As Result
  AS
  BEGIN
    self.x         := NULL;
    self.y         := NULL;
    self.z         := NULL;
    self.w         := NULL;
    self.id        := NULL;
    self.sdo_gtype := 2001;
    self.sdo_srid  := null;
    self.deleted   := 0;
    RETURN;
  END T_Vertex;

  Constructor Function T_Vertex(SELF     IN OUT NOCOPY T_Vertex,
                                p_vertex In &&INSTALL_SCHEMA..T_vertex)
                Return Self As Result
  AS
  BEGIN
    IF (p_vertex is NULL) THEN
      self.x         := NULL;
      self.y         := NULL;
      self.z         := NULL;
      self.w         := NULL;
      self.id        := NULL;
      self.sdo_gtype := 2001;
      self.sdo_srid  := null;
      self.deleted   := 0;
    ELSE
      self.x         := p_vertex.x;
      self.y         := p_vertex.y;
      self.z         := p_vertex.z;
      self.w         := p_vertex.w;
      self.id        := p_vertex.id;
      self.sdo_gtype := TRUNC(NVL(p_vertex.sdo_gtype,2001)/10)*10+1;
      self.sdo_srid  := p_vertex.sdo_srid;
      self.deleted   := p_vertex.deleted;
    END If;
    RETURN;
  END T_Vertex;

  Constructor Function T_Vertex(SELF    IN OUT NOCOPY T_Vertex,
                                p_point in mdsys.sdo_geometry)
                Return Self As Result
  AS
    v_vertex mdsys.vertex_type;
    v        number;
  BEGIN
    self.x         := NULL;
    self.y         := NULL;
    self.z         := NULL;
    self.w         := NULL;
    self.id        := NULL;
    self.sdo_gtype := 2001;
    self.sdo_srid  := null;
    self.deleted   := 0;
    IF (p_point is null) Then
      Return;
    ElsIf( p_point.sdo_Point is not null) Then
      self.x  := p_point.sdo_Point.x;
      self.y  := p_point.sdo_Point.y;
      self.z  := p_point.sdo_Point.z;
    Else
      v_vertex := mdsys.sdo_util.getVertices(p_point)(1);
      self.x  := v_vertex.x;
      self.y  := v_vertex.y;
      self.z  := v_vertex.z;
      self.w  := v_vertex.w;
    End If;
    self.sdo_gtype := TRUNC(NVL(p_point.sdo_gtype,2001)/10)*10+1;
    self.sdo_srid  := p_point.sdo_srid;
    Return;
  End T_Vertex;

  Constructor Function T_Vertex(SELF           IN OUT NOCOPY T_Vertex,
                                p_coord_string in varchar2,
                                p_id           in integer default 1,
                                p_sdo_srid     in integer default null)
       Return Self as result
  As
  Begin
    self.id        := NVL(p_id,1);
    self.sdo_srid  := p_sdo_srid;
    self.deleted   := 0;
    IF ( p_coord_string is null ) THEN
       RETURN;
    END IF;
    BEGIN
      SELECT CASE COUNT(*)
                  WHEN 2 THEN 2001
                  WHEN 3 THEN 3001
                  WHEN 4 THEN 4401
               END as sdo_gtype,
             SUM(DECODE(id,1,to_number(t.token),0)) as x,
             SUM(DECODE(id,2,to_number(t.token),0)) as y,
             CASE WHEN COUNT(*) > 2 THEN SUM(DECODE(id,3,to_number(t.token),0)) ELSE NULL END as z,
             CASE WHEN COUNT(*) = 4 THEN SUM(DECODE(id,4,to_number(t.token),0)) ELSE NULL END as m
        INTO self.sdo_gtype,
             self.x,
             self.y,
             self.z,
             self.w
        FROM TABLE(&&INSTALL_SCHEMA..TOOLS.Tokenizer(p_coord_string,', ')) t;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          dbms_output.put_line(SQLERRM);
          NULL;
    END;
    RETURN;
  End T_Vertex;

  Constructor Function T_Vertex(SELF        IN OUT NOCOPY T_Vertex,
                                p_id        In Integer,
                                p_sdo_gtype In integer default 2001,
                                p_sdo_srid  In integer default NULL)
                Return Self As Result
  As
  Begin
    self.x         := null;
    self.y         := null;
    self.z         := null;
    self.w         := null;
    self.id        := p_id;
    self.sdo_gtype := TRUNC(NVL(p_sdo_gtype,2001)/10)*10+1;
    self.sdo_srid  := p_sdo_srid;
    self.deleted   := 0;
    RETURN;
  End T_Vertex;

  Constructor Function T_Vertex( SELF        IN OUT NOCOPY T_Vertex,
                                 p_x         In number,
                                 p_y         In number)
       Return Self As Result
  As
  Begin
    self.x         := p_x;
    self.y         := p_y;
    self.z         := NULL;
    self.w         := NULL;
    self.id        := 1;
    self.sdo_gtype := 2001;
    self.sdo_srid  := NULL;
    self.deleted   := 0;
    RETURN;
  End T_Vertex;
  
  Constructor Function T_Vertex(SELF        IN OUT NOCOPY T_Vertex,
                                p_x         In number,
                                p_y         In number,
                                p_z         In number,
                                p_id        In integer,
                                p_sdo_gtype In integer,
                                p_sdo_srid  In integer)
                Return Self As Result
  As
  Begin
    self.x         := p_x;
    self.y         := p_y;
    self.z         := p_z;
    self.w         := NULL;
    self.id        := p_id;
    self.sdo_gtype := TRUNC(NVL(p_sdo_gtype,2001)/10)*10+1;
    self.sdo_srid  := p_sdo_srid;
    self.deleted   := 0;
    RETURN;
  End T_Vertex;

  Constructor Function T_Vertex(SELF        IN OUT NOCOPY T_Vertex,
                                p_x         In number,
                                p_y         In number,
                                p_z         In number,
                                p_w         In number,
                                p_id        In integer,
                                p_sdo_gtype In integer,
                                p_sdo_srid  In integer)
                Return Self As Result
  As
  Begin
    self.x         := p_x;
    self.y         := p_y;
    self.z         := p_z;
    self.w         := p_w;
    self.id        := p_id;
    self.sdo_gtype := TRUNC(NVL(p_sdo_gtype,2001)/10)*10+1;
    self.sdo_srid  := p_sdo_srid;
    self.deleted   := 0;
    RETURN;
  End T_Vertex;

  Constructor Function T_Vertex(SELF        IN OUT NOCOPY T_Vertex,
                                p_x         In number,
                                p_y         In number,
                                p_id        In integer,
                                p_sdo_gtype In integer,
                                p_sdo_srid  In integer)
                Return Self As Result
  AS
  BEGIN
    self.x         := p_x;
    self.y         := p_y;
    self.id        := p_id;
    self.sdo_gtype := TRUNC(NVL(p_sdo_gtype,2001)/10)*10+1;
    self.sdo_srid  := p_sdo_srid;
    self.deleted   := 0;
    RETURN;
  END T_Vertex;

  Constructor Function T_Vertex(SELF        IN OUT NOCOPY T_Vertex,
                                p_vertex    In mdsys.vertex_type,
                                p_sdo_gtype In integer default 2001,
                                p_sdo_srid  In integer default null)
                Return Self As Result
  AS
  BEGIN
    IF (p_vertex is NULL) THEN
      self.x       := NULL;
      self.y       := NULL;
      self.z       := NULL;
      self.w       := NULL;
      self.id      := NULL;
    ELSE
      self.x       := p_vertex.x;
      self.y       := p_vertex.y;
      self.z       := p_vertex.z;
      self.w       := p_vertex.w;
      self.id      := p_vertex.id;
    END IF;
    self.sdo_gtype := TRUNC(NVL(p_sdo_gtype,2001)/10)*10+1;
    self.sdo_srid  := p_sdo_srid;
    self.deleted   := 0;
    RETURN;
  END T_Vertex;

  Constructor Function T_Vertex(SELF        IN OUT NOCOPY T_Vertex,
                                p_vertex    In mdsys.vertex_type,
                                p_id        In integer,
                                p_sdo_gtype In integer default 2001,
                                p_sdo_srid  In integer default null)
                Return Self As Result
  AS
  BEGIN
    IF (p_vertex is NULL) THEN
      self.x       := NULL;
      self.y       := NULL;
      self.z       := NULL;
      self.w       := NULL;
    ELSE
      self.x       := p_vertex.x;
      self.y       := p_vertex.y;
      self.z       := p_vertex.z;
      self.w       := p_vertex.w;
    END IF;
    self.id        := p_id;
    self.sdo_gtype := TRUNC(NVL(p_sdo_gtype,2001)/10)*10+1;
    self.sdo_srid  := p_sdo_srid;
    self.deleted   := 0;
    RETURN;
  END T_Vertex;

  Constructor Function T_Vertex(SELF        IN OUT NOCOPY T_Vertex,
                                p_point     in mdsys.sdo_point_type,
                                p_sdo_gtype In integer default 2001,
                                p_sdo_srid  In integer default null)
                Return Self As Result
  AS
  BEGIN
    IF (p_point is NULL) THEN
      self.x       := NULL;
      self.y       := NULL;
      self.z       := NULL;
    ELSE
      self.x       := p_point.x;
      self.y       := p_point.y;
      self.z       := p_point.z;
    END IF;
    self.w         := NULL;
    self.sdo_gtype := TRUNC(NVL(p_sdo_gtype,2001)/10)*10+1;
    self.sdo_srid  := p_sdo_srid;
    self.deleted   := 0;
    Return;
  End T_Vertex;

  -- **************************************************************************************
  
  Member Function ST_X          Return Number  AS BEGIN RETURN SELF.x;         END ST_X;

  Member Function ST_Y          Return Number  AS BEGIN RETURN SELF.y;         END ST_Y;

  Member Function ST_Z          Return Number  AS BEGIN RETURN SELF.z;         END ST_Z;

  Member Function ST_W          Return Number  AS BEGIN RETURN SELF.w;         END ST_W;

  Member Function ST_M          Return Number  AS BEGIN RETURN SELF.w;         END ST_M;

  Member Function ST_ID         Return Integer AS BEGIN RETURN SELF.ID;        END ST_ID;

  Member Function ST_SRID       Return integer AS BEGIN RETURN SELF.SDO_SRID;  END ST_SRID;

  Member Function ST_SDO_GTYPE  Return integer AS BEGIN RETURN SELF.SDO_GTYPE; END ST_SDO_GTYPE;

  Member Function ST_isDeleted  Return integer AS BEGIN RETURN SELF.deleted;   END ST_isDeleted;

  Member Function ST_IsMeasured Return integer 
  AS
  Begin
    Return CASE WHEN MOD(TRUNC(SELF.sdo_gtype/100),10) = 0
                THEN 0
                ELSE 1
             END;
  End ST_IsMeasured;

  Member Function ST_Self
           Return &&INSTALL_SCHEMA..T_Vertex
  As
  Begin
    Return &&INSTALL_SCHEMA..T_Vertex(SELF);
  End ST_Self;

  Member Procedure ST_SetCoordinate(
           SELF  IN OUT NOCOPY T_Vertex,
           p_x   in number,
           p_y   in number,
           p_z   in number default null,
           p_w   in number default null
         )
  As
  Begin
    -- SGG: Leave sdo_gtype alone for now.
    SELF.x := p_x;
    SELF.y := p_y;
    SELF.Z := p_z;
    SELF.w := p_w;
  end ST_SetCoordinate;
  
  Member Procedure ST_SetDeleted(SELF      IN OUT NOCOPY T_Vertex,
                                 p_deleted IN INTEGER default 1)
  As
  Begin
    SELF.deleted := case when NVL(p_deleted,1) = 1 then 1 else 0 end;
  End ST_SetDeleted;
  
  Member Function ST_isEmpty
           Return integer Deterministic
  AS
  Begin
       return case when self.x is null or self.y is null
                   then 1 else 0 end;
  End ST_isEmpty;

  Member FUNCTION ST_Dims
  RETURN integer Deterministic
  AS
  BEGIN
    IF ( self.sdo_gtype IS NULL ) THEN
       RETURN CASE WHEN self.x IS NULL THEN 0 ELSE 2 END +
              CASE WHEN self.z IS NULL THEN 0 ELSE 1 END +
              CASE WHEN self.w IS NULL THEN 0 ELSE 1 END;
    ELSE
      RETURN CASE WHEN self.sdo_gtype < 2000
                  THEN self.sdo_gtype
                  ELSE self.sdo_gtype / 1000
              END;
    END IF;
  END ST_Dims;

  Member Function ST_HasM
  RETURN integer Deterministic
  AS
  BEGIN
    RETURN CASE WHEN SELF.sdo_gtype IS NULL
                THEN 0
                ELSE CASE WHEN MOD(TRUNC(SELF.sdo_gtype/100),10) = 0
                          THEN 0
                          ELSE 1
                      END
    END;
  END ST_HasM;

  Member Function ST_Lrs_Dim
           Return Integer Deterministic
  As
  Begin
     return case when SELF.sdo_gtype is null then 0 else trunc(mod(SELF.sdo_gtype,1000)/100) end;
  End ST_Lrs_Dim;

  Member Function ST_LRS_Set_Measure(p_measure in number)
           Return &&INSTALL_SCHEMA..T_Vertex
  As
    v_vertex &&INSTALL_SCHEMA..T_Vertex;
  Begin
    IF  ((SELF.ST_LRS_Dim()=0 AND SELF.ST_Dims()=2)
      or (SELF.ST_LRS_Dim()=3 AND SELF.ST_Dims()=3)
      or (SELF.ST_LRS_Dim()=3 AND SELF.ST_Dims()=4)) THEN
      v_vertex:= &&INSTALL_SCHEMA..t_vertex(
                   p_x=>self.x,
                   p_y=>self.y,
                   p_z=>p_measure,
                   p_w=>self.w,
                   p_id=>self.id,
                   p_sdo_gtype=>case when SELF.ST_Dims()=2 then 3301 else (SELF.ST_Dims()*1000)+(SELF.ST_LRS_DIM()*100)+1 end,
                   p_sdo_srid=>self.sdo_srid
                );
    ELSIF ( (SELF.ST_LRS_Dim()=0 AND SELF.ST_Dims()=3)
         OR (SELF.ST_LRS_Dim()=4 AND SELF.ST_Dims()=4) ) THEN
      v_vertex:= &&INSTALL_SCHEMA..t_vertex(
                   p_x=>self.x,
                   p_y=>self.y,
                   p_z=>SELF.z,
                   p_w=>p_measure,
                   p_id=>self.id,
                   p_sdo_gtype=>4401,
                   p_sdo_srid=>self.sdo_srid
                );
    ELSE
      v_vertex := &&INSTALL_SCHEMA..T_VERTEX(SELF);
    END IF;
    RETURN v_vertex;
  End ST_LRS_Set_Measure;
  
  Member Function ST_hasZ
  RETURN integer Deterministic
  As
  Begin
    return CASE WHEN ( ( SELF.ST_Dims() = 3
                          AND SELF.ST_hasM()=0  )
                      OR SELF.ST_Dims() = 4  )
                THEN 1
                ELSE 0
            END;
  End ST_hasZ;
  
  Member Function ST_SdoPointType
           Return mdsys.sdo_point_type Deterministic
  AS
    v_point mdsys.sdo_point_type := new mdsys.sdo_point_type(null,null,null);
  Begin
    v_point.x  := self.x;
    v_point.y  := self.y;
    v_point.z  := self.z;
    return v_point;
  End ST_SdoPointType;

  Member Function ST_VertexType
           Return mdsys.vertex_type Deterministic
  AS
    v_vertex mdsys.vertex_type;
  Begin
    v_vertex := mdsys.sdo_util.getVertices(mdsys.sdo_geometry(4001,null,null,mdsys.sdo_elem_info_array(1,1,1),mdsys.sdo_ordinate_array(NULL,NULL,NULL,NULL)))(1);
    v_vertex.x  := self.x;
    v_vertex.y  := self.y;
    v_vertex.z  := self.z;
    v_vertex.w  := self.w;
    v_vertex.id := self.id;
    return v_vertex;
  End ST_VertexType;
  
  Member Function ST_To2D
           Return &&INSTALL_SCHEMA..T_Vertex
  AS
  BEGIN
    RETURN CASE WHEN SELF.ST_DIMS()=2
                THEN &&INSTALL_SCHEMA..T_VERTEX(SELF)
                ELSE &&INSTALL_SCHEMA..T_VERTEX(
                       p_x         =>SELF.x,
                       p_y         =>SELF.y,
                       p_id        =>SELF.id,
                       p_sdo_gtype =>2001,
                       p_sdo_srid  =>SELF.sdo_srid)
            END;
  END ST_To2D;
  
  Member Function ST_To3D(p_keep_measure in integer,
                          p_default_z    in number)
           Return &&INSTALL_SCHEMA..T_Vertex
  As
  Begin
    RETURN case when SELF.ST_Dims() = 2
                then &&INSTALL_SCHEMA..T_VERTEX(
                       p_x         =>SELF.x,
                       p_y         =>SELF.y,
                       p_z         =>p_default_z,
                       p_w         =>NULL,
                       p_id        =>SELF.id,
                       p_sdo_gtype =>3001,
                       p_sdo_srid  =>SELF.sdo_srid
                     )
                when SELF.ST_Dims()=3 and SELF.ST_hasZ=1
                then &&INSTALL_SCHEMA..T_VERTEX(SELF)
                when SELF.ST_Dims()=3
                then &&INSTALL_SCHEMA..T_VERTEX(
                       p_x         =>SELF.x,
                       p_y         =>SELF.y,
                       p_z         =>CASE WHEN SELF.ST_hasM()=1 and p_keep_measure=1
                                          THEN CASE WHEN SELF.ST_LRS_Dim()=3 THEN SELF.z ELSE SELF.w END
                                          ELSE p_default_z
                                      END,
                       p_w         =>NULL,
                       p_id        =>SELF.id,
                       p_sdo_gtype =>3001,
                       p_sdo_srid  =>SELF.sdo_srid)
                when SELF.ST_Dims()=4
                then &&INSTALL_SCHEMA..T_VERTEX(
                       p_x         =>SELF.x,
                       p_y         =>SELF.y,
                       p_z         =>CASE WHEN SELF.ST_LRS_Dim()=0                      THEN SELF.z
                                          WHEN SELF.ST_LRS_Dim()=3 AND p_keep_measure=1 THEN SELF.z
                                          WHEN SELF.ST_LRS_Dim()=3 AND p_keep_measure=0 THEN SELF.w
                                          WHEN SELF.ST_LRS_Dim()=4 AND p_keep_measure=1 THEN SELF.w
                                          WHEN SELF.ST_LRS_Dim()=4 AND p_keep_measure=0 THEN SELF.z
                                          ELSE SELF.z
                                      END,
                       p_w         =>NULL,
                       p_id        =>SELF.id,
                       p_sdo_gtype =>3001,
                       p_sdo_srid  =>SELF.sdo_srid
                    )
            END;
  End ST_To3D;

  Member Function ST_Round(p_dec_places_x In integer Default 8,
                           p_dec_places_y In integer Default null,
                           p_dec_places_z In integer Default 3,
                           p_dec_places_m In integer Default 3)
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic
  As
  Begin
    Return new &&INSTALL_SCHEMA..T_Vertex(
                 p_x => case when self.x is not null then round(self.x,NVL(p_dec_places_x,8)) else self.x end,
                 p_y => case when self.y is not null then round(self.y,NVL(p_dec_places_y,NVL(p_dec_places_x,8))) else self.y end,
                 p_z => case when self.z is not null then round(self.z,NVL(p_dec_places_z,3)) else self.z end,
                 p_w => case when self.w is not null then round(self.w,NVL(p_dec_places_m,3)) else self.w end,
                p_id => self.id,
         p_sdo_gtype => self.sdo_gtype,
          p_sdo_srid => self.sdo_srid);
  End ST_Round;

  Member Function ST_Bearing(p_vertex    in &&INSTALL_SCHEMA..T_Vertex,
                             p_projected in integer default 1,
                             p_normalize in integer default 1)
           Return Number
  As
    geographic3D EXCEPTION;
    PRAGMA EXCEPTION_INIT(geographic3D,-13364);
    c_i_geographic3D Constant Integer       := -20101;
    c_s_geographic3D Constant VarChar2(200) := 'Layer dimensionality does not match geometry dimensions: Probably trying to compute using Geographic/Geographic3D data.';
    v_dBearing    Number;
    v_dTilt       Number;
    v_dEast       Number;
    v_dNorth      Number;
    v_start_point mdsys.sdo_geometry;
    v_end_point   mdsys.sdo_geometry;
    v_planar_srid pls_integer;
  Begin
    If ( SELF.ST_Dims() = 0 ) Then
      Return null;
    End If;
    If (p_vertex is null) Then
       Return null;
    End If;
    If (SELF.x     Is Null or SELF.y     Is Null Or
        p_vertex.x Is Null or p_vertex.x Is null ) THEN
       Return Null;
    End If;
    If ( (SELF.x = p_vertex.x) And (SELF.y = p_vertex.y) ) Then
       Return Null;
    End If;
    IF ( p_projected is null ) THEN
      IF ( SELF.sdo_srid is null ) THEN
        v_planar_srid := 1;
      ELSE
        v_planar_srid := case when &&INSTALL_SCHEMA..TOOLS.ST_GetSridType(SELF.sdo_srid) = 'PLANAR' then 1 else 0 end;
      END IF;
    ELSE
      v_planar_srid := case when p_projected <= 0 then 0 else 1 end;
    END IF;
    IF (v_planar_srid = 1) Then
      v_dEast  := p_vertex.x - SELF.x;
      v_dNorth := p_vertex.y - SELF.y;
      If ( v_dEast = 0 ) Then
        v_dBearing := case when ( v_dNorth < 0 ) then &&INSTALL_SCHEMA..COGO.PI() Else 0 End;
      Else
        v_dBearing := -aTan(v_dNorth / v_dEast) + &&INSTALL_SCHEMA..COGO.PI() / 2;
      End If;
      Return &&INSTALL_SCHEMA..COGO.ST_Degrees(
               p_radians  => case when v_dEast<0 Then v_dBearing + &&INSTALL_SCHEMA..COGO.PI() else v_dBearing end,
               p_normalize=>1
             );
    Else
      v_start_point := SELF.ST_SdoGeometry();
      v_end_point   := p_vertex.ST_SdoGeometry();
      BEGIN
        MDSYS.SDO_UTIL.BEARING_TILT_FOR_POINTS(
          v_start_point,
          v_end_point,
          0.05,
          v_dBearing,
          v_dTilt
        );
        EXCEPTION
          WHEN geographic3D THEN
          BEGIN
            -- SRID is not 3D
            v_start_point :=     SELF.ST_To2D().ST_SdoGeometry();
            v_end_point   := p_vertex.ST_To2D().ST_SdoGeometry();
            MDSYS.SDO_UTIL.BEARING_TILT_FOR_POINTS(
              v_start_point,
              v_end_point,
              0.05,
              v_dBearing,
              v_dTilt
            );
          END;
      END;
      Return &&INSTALL_SCHEMA..COGO.ST_Degrees(
               p_radians  => case when v_dEast<0 Then v_dBearing + &&INSTALL_SCHEMA..COGO.PI() else v_dBearing end,
               p_normalize=>1
             );
    End If;
  End ST_Bearing;

  Member Function ST_Distance(p_vertex    in &&INSTALL_SCHEMA..T_Vertex,
                              p_tolerance in number   default 0.05,
                              p_unit      in varchar2 default NULL)
           Return number
  As
    c_i_empty_geom Constant
                   Integer       := -20120;
    c_s_empty_geom Constant
                   VarChar2(100) := 'Object geometry must not be null or empty';
    v_tolerance    number        := NVL(p_tolerance,0.05);
    v_distance     number;
    v_isLocator    BOOLEAN       := false;
  Begin
    If ( SELF.ST_Dims() < 2 ) Then
      Return null;
    End If;
    If (p_vertex is null) Then
       Return null;
    End If;
    v_isLocator := case when &&INSTALL_SCHEMA..TOOLS.ST_isLocator() = 1 then true else false end;
    v_distance  := case when SELF.sdo_srid is not null and p_unit is not null
                        then mdsys.sdo_geom.sdo_distance(SELF.ST_SdoGeometry(),
                                                         p_vertex.ST_SdoGeometry(),
                                                         p_tolerance,
                                                         p_unit)
                        else mdsys.sdo_geom.sdo_distance(SELF.ST_SdoGeometry(),
                                                         p_vertex.ST_SdoGeometry(),
                                                         p_tolerance)
                    end;
     If ( SELF.ST_Dims() > 2 AND v_isLocator ) Then
        RETURN SQRT(POWER(v_distance,2) + POWER(p_vertex.z - SELF.z,2));
     Else
        RETURN v_distance;
     End If;
  End ST_Distance;

  Member Function ST_Add(p_vertex in &&INSTALL_SCHEMA..T_Vertex)
           Return &&INSTALL_SCHEMA..T_Vertex
  As
  Begin
    Return &&INSTALL_SCHEMA..T_Vertex(
             p_x        =>SELF.x + p_vertex.x,
             p_y        =>SELF.y + p_vertex.y,
             p_id       =>SELF.id,
             p_sdo_gtype=>2001,
             p_sdo_srid =>SELF.sdo_srid
           );
  End ST_Add;

  Member Function ST_Normal
           Return &&INSTALL_SCHEMA..T_Vertex
  As
    v_length Number;
  Begin
    v_length := SQRT(SELF.x*SELF.x + SELF.y*SELF.y);
    Return &&INSTALL_SCHEMA..T_Vertex(
             p_x        =>SELF.x / v_length,
             p_y        =>SELF.y / v_length,
             p_id       =>SELF.id,
             p_sdo_gtype=>2001,
             p_sdo_srid =>SELF.sdo_srid
           );
  End ST_Normal;

  Member Function ST_Subtract(p_vertex in &&INSTALL_SCHEMA..T_Vertex)
           Return &&INSTALL_SCHEMA..T_Vertex
  As
  Begin
    Return &&INSTALL_SCHEMA..T_Vertex(
             p_x        =>SELF.x - p_vertex.x,
             p_y        =>SELF.y - p_vertex.y,
             p_id       =>SELF.id,
             p_sdo_gtype=>2001,
             p_sdo_srid =>SELF.sdo_srid
           );
  End ST_Subtract;

  Member Function ST_Scale(p_scale in number default 1)
           Return &&INSTALL_SCHEMA..T_Vertex
  As
  Begin
    Return &&INSTALL_SCHEMA..T_Vertex(
             p_x        =>SELF.x * NVL(p_scale,1),
             p_y        =>SELF.y * NVL(p_scale,1),
             p_id       =>SELF.id,
             p_sdo_gtype=>2001,
             p_sdo_srid =>SELF.sdo_srid
           );
  End ST_Scale;
  
  Member Function ST_SubtendedAngle(p_start_vertex in &&INSTALL_SCHEMA..T_Vertex,
                                    p_end_vertex   in &&INSTALL_SCHEMA..T_Vertex,
                                    p_projected    in integer default 1)
           Return Number
  IS
    c_i_empty_geom  Constant Integer       := -20120;
    c_s_empty_geom  Constant VarChar2(100) := 'Object geometry must not be null or empty';
    v_DotProduct    Number;
    v_CrossProduct  Number;
    v_degrees       Number;
    v_planar_srid   pls_integer;
    Function CrossProductLength(dStartX in number,
                                dStartY in number,
                                dCentreX in number,
                                dCentreY in number,
                                dEndX in number,
                                dEndY in number)
      Return Number
    IS
        dCentreStartX Number;
        dCentreStartY Number;
        dCentreEndX Number;
        dCentreEndY Number;
    BEGIN
        dCentreStartX := dStartX - dCentreX;
        dCentreStartY := dStartY - dCentreY;
        dCentreEndX   := dEndX - dCentreX;
        dCentreEndY   := dEndY - dCentreY;
        Return dCentreStartX * dCentreEndY - dCentreStartY * dCentreEndX;
    END CrossProductLength;
    Function DotProduct(dStartX  in number,
                        dStartY  in number,
                        dCentreX in number,
                        dCentreY in number,
                        dEndX   in number,
                        dEndY   in number)
      Return Number
    IS
        dCentreStartX Number;
        dCentreStartY Number;
        dCentreEndX   Number;
        dCentreEndY   Number;
    BEGIN
        dCentreStartX := dStartX - dCentreX;
        dCentreStartY := dStartY - dCentreY;
        dCentreEndX   :=   dEndX - dCentreX;
        dCentreEndY   :=   dEndY - dCentreY;
        Return dCentreStartX * dCentreEndX + dCentreStartY * dCentreEndY;
    End DotProduct;
  BEGIN
    If ( SELF.ST_Dims() < 2 ) Then
      Return null;
    End If;
    If (p_start_vertex is null Or p_end_vertex is null) Then
       Return null;
    End If;
    IF ( p_projected is null ) THEN
      IF ( SELF.sdo_srid is null ) THEN
        v_planar_srid := 1;
      ELSE
        v_planar_srid := case when &&INSTALL_SCHEMA..TOOLS.ST_GetSridType(SELF.sdo_srid) = 'PLANAR' then 1 else 0 end;
      END IF;
    ELSE
      v_planar_srid := case when p_projected <= 0 then 0 else 1 end;
    END IF;
    IF ( v_planar_srid = 1 ) Then
      v_DotProduct   :=         DotProduct(p_start_vertex.X, p_start_vertex.Y, SELF.x, SELF.Y, p_End_Vertex.X, p_End_Vertex.Y);
      v_CrossProduct := CrossProductLength(p_start_vertex.X, p_start_vertex.Y, SELF.x, SELF.Y, p_End_Vertex.X, p_End_Vertex.Y);
      Return ATan2(v_CrossProduct,
                   v_DotProduct);
    ELSE
      v_degrees := SELF.ST_Bearing(
                           p_vertex    => p_end_vertex,
                           p_projected => 0,
                           p_normalize => 0
                   )
                   -
                   SELF.ST_Bearing(
                           p_vertex    => p_start_vertex,
                           p_projected => 0,
                           p_normalize => 0
                   );
      Return &&INSTALL_SCHEMA..COGO.ST_Radians(
               &&INSTALL_SCHEMA..COGO.ST_Normalize(v_degrees)
             );
    END IF;
  End ST_SubtendedAngle;
  
  Member Function ST_FromBearingAndDistance(p_Bearing   in number,
                                            p_Distance  in number,
                                            p_projected in integer default 1)
           Return &&INSTALL_SCHEMA..T_Vertex
  AS
    geographic3D EXCEPTION;
    PRAGMA EXCEPTION_INIT(geographic3D,-13364);
    c_i_geographic3D Constant Integer       := -20101;
    c_s_geographic3D Constant VarChar2(200) := 'Layer dimensionality does not match geometry dimensions: Probably trying to compute using Geographic/Geographic3D data.';
    dAngle1       NUMBER;
    dAngle1Rad    NUMBER;
    dDeltaN       NUMBER;
    dDeltaE       NUMBER;
    dEndE         Number;
    dEndN         Number;
    v_point       mdsys.sdo_geometry;
    v_Bearing     Number := case when NVL(p_Bearing,0.0) > 360 then mod(p_Bearing,360) else NVL(p_Bearing,0) end;
    v_planar_srid pls_integer;
  BEGIN
    If ( SELF.ST_Dims() = 0 ) Then
      Return null;
    End If;
    If (p_bearing is null or p_distance is null) Then
       Return null;
    End If;
    IF ( p_projected is null ) THEN
      IF ( SELF.sdo_srid is null ) THEN
        v_planar_srid := 1;
      ELSE
        v_planar_srid := case when &&INSTALL_SCHEMA..TOOLS.ST_GetSridType(SELF.sdo_srid) = 'PLANAR' then 1 else 0 end;
      END IF;
    ELSE
      v_planar_srid := case when p_projected <= 0 then 0 else 1 end;
    END IF;
    If (v_planar_srid = 1  ) Then
      If v_Bearing < 90 Then
          dAngle1 := 90 - v_Bearing;
          dAngle1Rad := dAngle1 * &&INSTALL_SCHEMA..COGO.PI() / 180;
          dDeltaE := Cos(dAngle1Rad) * p_distance;
          dDeltaN := Sin(dAngle1Rad) * p_distance;
      ElsIf v_Bearing < 180 Then
          dAngle1 := v_Bearing - 90;
          dAngle1Rad := dAngle1 * &&INSTALL_SCHEMA..COGO.PI() / 180;
          dDeltaE := Cos(dAngle1Rad) * p_distance;
          dDeltaN := Sin(dAngle1Rad) * p_distance * -1;
      ElsIf v_Bearing < 270 Then
          dAngle1 := 270 - v_Bearing;
          dAngle1Rad := dAngle1 * &&INSTALL_SCHEMA..COGO.PI() / 180;
          dDeltaE := Cos(dAngle1Rad) * p_distance * -1;
          dDeltaN := Sin(dAngle1Rad) * p_distance * -1;
      ElsIf v_Bearing <= 360 Then
          dAngle1 := v_Bearing - 270;
          dAngle1Rad := dAngle1 * &&INSTALL_SCHEMA..COGO.PI() / 180;
          dDeltaE := Cos(dAngle1Rad) * p_distance * -1;
          dDeltaN := Sin(dAngle1Rad) * p_distance;
      End If;
      dEndE := dDeltaE + SELF.x;
      dEndN := dDeltaN + SELF.y;
      RETURN case when SELF.ST_HasZ()=1
                  then &&INSTALL_SCHEMA..T_Vertex(
                         p_x         => dEndE,
                         p_y         => dEndN,
                         p_z         => SELF.z,
                         p_id        => 1,
                         p_sdo_gtype => 3001,
                         p_sdo_srid  => self.sdo_srid
                       )
                  else &&INSTALL_SCHEMA..T_Vertex(
                         p_x         => dEndE,
                         p_y         => dEndN,
                         p_id        => 1,
                         p_sdo_gtype => 2001,
                         p_sdo_srid  => self.sdo_srid
                       )
             end;
    Else
      BEGIN
        v_point := MDSYS.SDO_UTIL.POINT_AT_BEARING(
                         SELF.ST_SdoGeometry(),
                         &&INSTALL_SCHEMA..COGO.ST_Radians(v_bearing),
                         p_distance);
        EXCEPTION
          WHEN geographic3D THEN
            v_point := MDSYS.SDO_UTIL.POINT_AT_BEARING(
                             SELF.ST_To2D()
                                 .ST_SdoGeometry(),
                             &&INSTALL_SCHEMA..COGO.ST_Radians(v_bearing),
                             p_distance);
      END;
      Return &&INSTALL_SCHEMA..T_Vertex(v_point);
    End If;
  END ST_FromBearingAndDistance;

  Member Function ST_WithinTolerance(P_Vertex    In &&INSTALL_SCHEMA..T_Vertex,
                                     p_tolerance in number  default 0.005,
                                     p_projected in integer default 1)
           Return Integer
  Is
    v_distance number;
  Begin
    If (p_vertex is null) Then
       Return 0;
    End If;
    IF ( NVL(p_projected,0) = 1 ) Then
      v_distance := Sqrt(
                     POWER(P_Vertex.X-Self.X, 2) +
                     POWER(P_Vertex.Y-Self.Y, 2) +
                     POWER(NVL(P_Vertex.Z, 0)-NVL(Self.Z, 0), 2)
                    );
    Else
       v_distance := SELF.ST_Distance(p_vertex    => p_vertex,
                                      p_tolerance => p_tolerance,
                                      p_unit      => NULL);
    End If;
    Return Case When ( v_distance <= p_tolerance )
                Then 1
                Else 0
            End;
  End ST_WithinTolerance;

  Member Function ST_SdoGeometry(p_dims in integer default null)
           Return mdsys.sdo_geometry
  AS
    v_dims integer := NVL(p_dims,SELF.ST_Dims());
  Begin
    If ( SELF.sdo_gtype is null ) Then
      Return null;
    ElsIf ( SELF.sdo_gtype = 2001 or v_dims = 2) Then
      Return mdsys.sdo_geometry(SELF.sdo_gtype,SELF.sdo_SRID,mdsys.sdo_point_type(self.x,self.y,NULL),null,null);
    ElsIf ( v_dims = 3 ) Then
      Return mdsys.sdo_geometry(SELF.sdo_gtype,SELF.sdo_SRID,mdsys.sdo_point_type(self.x,self.y,self.z),null,null);
    ElsIf ( v_dims = 4 ) Then
      If ( SELF.ST_Dims() = 3 ) Then
        Return mdsys.sdo_geometry(SELF.sdo_gtype,SELF.sdo_SRID,mdsys.sdo_point_type(self.x,self.y,self.z),null,null);
      Else
        Return mdsys.sdo_geometry(SELF.sdo_gtype,SELF.sdo_SRID,NULL,mdsys.sdo_elem_info_array(1,1,1),mdsys.sdo_ordinate_array(self.x,self.y,self.z,self.w));
      End If;
    End If;
    RETURN NULL;
  End ST_SdoGeometry;

  Member Function ST_AsCoordString(p_separator    in varchar2 Default ' ',
                                   p_format_model in varchar2 default 'TM9')
           Return VarChar2
  AS
    v_format_model varchar2(38)  := NVL(p_format_model,'TM9');  -- FM999999999999990D09999999999
    v_separator    varchar2(100) := SUBSTR(NVL(p_separator,' '),1,100);
  Begin
    Return NVL(to_char(self.x,v_format_model),'NULL') ||
           v_separator ||
           NVL(to_char(self.y,v_format_model),'NULL') ||
           case when SELF.ST_Dims() > 2
                then v_separator ||
                     NVL(to_char(self.z,v_format_model),'NULL') ||
                     case when SELF.ST_Dims() = 4
                          then v_separator ||
                               NVL(to_char(self.w,v_format_model),'NULL')
                          else ''
                      end
                else ''
            end;
  End ST_AsCoordString;

  Member Function ST_AsText(p_format_model     in varchar2 default 'TM9',
                            p_coordinates_only in integer default 0)
           Return VarChar2
  AS
    v_format_model varchar2(38)  := NVL(p_format_model,'TM9');
  Begin
    Return case when NVL(p_coordinates_only,0)=0
                then 'T_Vertex('||
                        'p_x=>' || NVL(to_char(self.x,v_format_model), 'NULL') ||
                       ',p_y=>' || NVL(to_char(self.y,v_format_model), 'NULL') ||
                       ',p_z=>' || NVL(to_char(self.z,v_format_model), 'NULL') ||
                       ',p_w=>' || NVL(to_char(self.w,v_format_model), 'NULL') ||
                      ',p_id=>' || NVL(to_char(self.id),               'NULL') ||
                      ',p_sdo_gtype=>' || NVL(to_char(self.sdo_gtype), 'NULL') ||
                       ',p_sdo_srid=>' || NVL(to_char(self.sdo_srid),  'NULL') ||
                     ')'
                else'T_Vertex('||
                        'p_x=>' || NVL(to_char(self.x,v_format_model), 'NULL') ||
                       ',p_y=>' || NVL(to_char(self.y,v_format_model), 'NULL') ||
                       ',p_z=>' || NVL(to_char(self.z,v_format_model), 'NULL') ||
                       ',p_w=>' || NVL(to_char(self.w,v_format_model), 'NULL') ||
                     ')'
            end;
  End ST_AsText;

  Member Function ST_AsEWKT(p_format_model in varchar2 default 'TM9')
           Return VarChar2 
  AS
    v_format_model varchar2(38)  := NVL(p_format_model,'TM9');
  BEGIN
    RETURN case when SELF.ST_Srid() is not null 
                then 'SRID='||SELF.SDO_SRID||';' 
                else '' 
            end ||
           'POINT' || 
           case when SELF.ST_Dims()=4 then 'ZM'
                when SELF.ST_Dims()>2 and SELF.ST_Lrs_Dim()=0  then 'Z' 
                when SELF.ST_Dims()>2 and SELF.ST_Lrs_Dim()<>0 then 'M'
            end ||
           ' (' || SELF.ST_AsCoordString(p_separator=>' ',p_format_model=>p_format_model) || ')';
  End ST_AsEWkt;

  Member Function ST_Equals(p_vertex     in &&INSTALL_SCHEMA..T_Vertex,
                            p_dPrecision In integer default 3)
           Return Number
  Is
    c_Min       CONSTANT NUMBER := -1E38;
    v_precision integer := NVL(p_dPrecision,3);
  Begin
    If (p_vertex is null) Then
       Return 0;
    End If;
    If ( ROUND(NVL(SELF.x,c_Min),v_precision) = ROUND(NVL(p_vertex.x,c_Min),v_precision) AND
         ROUND(NVL(SELF.y,c_Min),v_precision) = ROUND(NVL(p_vertex.y,c_Min),v_precision) AND
         ROUND(NVL(SELF.z,c_Min),v_precision) = ROUND(NVL(p_vertex.z,c_Min),v_precision) AND
         ROUND(NVL(SELF.w,c_Min),v_precision) = ROUND(NVL(p_vertex.w,c_Min),v_precision) ) Then
       Return 1;
    Else
       Return 0;
    END IF;
  End ST_Equals;

  Order Member Function orderBy(p_vertex in &&INSTALL_SCHEMA..T_Vertex)
                 Return Number
  Is
    c_Min CONSTANT NUMBER := -1E38;
  Begin
    If (p_vertex is null)                                  Then return  1;
    ElsIf SELF.ST_Equals(p_vertex) = 1                     Then Return  0;
     ElsIf ( SELF.X < p_vertex.X )                         Then Return -2;
     ElsIf ( SELF.X = p_vertex.X AND SELF.Y < p_vertex.Y ) Then Return -1;
     ElsIf ( SELF.X > p_vertex.X )                         Then Return  1;
     ElsIf ( NVL(SELF.Z,c_Min) < NVL(p_vertex.Z,c_Min) )   Then Return -1;
     ElsIf ( NVL(SELF.Z,c_Min) > NVL(p_vertex.Z,c_Min) )   Then Return  1;
     ElsIf ( NVL(SELF.w,c_Min) < NVL(p_vertex.w,c_Min) )   Then Return -1;
     ElsIf ( NVL(SELF.w,c_Min) > NVL(p_vertex.w,c_Min) )   Then Return  1;
     Else                                                       Return 0;
     End If;
  End orderBy;
END;
/
show errors

