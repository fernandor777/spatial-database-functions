DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

-- Always aim for a clean compile
ALTER SESSION SET PLSQL_WARNINGS='ERROR:ALL';
-- Enable optimizations
ALTER SESSION SET plsql_optimize_level=2;

CREATE OR REPLACE TYPE BODY &&INSTALL_SCHEMA..T_SEGMENT
AS

  Constructor Function T_SEGMENT(SELF IN OUT NOCOPY T_SEGMENT)
                Return Self AS Result
  AS
  BEGIN
    SELF.element_id    := NULL;
    SELF.subelement_id := NULL;
    SELF.segment_id    := NULL;
    SELF.startCoord    := NULL;
    SELF.midCoord      := NULL;
    SELF.endCoord      := NULL;
    SELF.SDO_GTYPE     := NULL;
    SELF.SDO_SRID      := NULL;
    Return;
  END T_SEGMENT;

  Constructor Function T_SEGMENT(SELF      IN OUT NOCOPY T_SEGMENT,
                                 p_segment IN &&INSTALL_SCHEMA..T_SEGMENT)
                Return Self AS Result
  AS
  BEGIN
    IF ( p_segment        IS NULL ) THEN
      SELF.element_id    := NULL;
      SELF.subelement_id := NULL;
      SELF.segment_id    := NULL;
      SELF.startCoord    := &&INSTALL_SCHEMA..T_Vertex();
      SELF.midCoord      := NULL;
      SELF.ENDCOORD      := &&INSTALL_SCHEMA..T_VERTEX();
      SELF.sdo_gtype     := 2002;
      SELF.sdo_srid      := NULL;
    ELSE
      SELF.element_id    := p_segment.element_id;
      SELF.subelement_id := p_segment.subelement_id;
      SELF.segment_id    := p_segment.segment_id;
      SELF.startCoord    := &&INSTALL_SCHEMA..T_Vertex(p_segment.startCoord);
      SELF.midCoord      :=
      CASE
      WHEN p_segment.midCoord IS NOT NULL THEN
        &&INSTALL_SCHEMA..T_Vertex(p_segment.midCoord)
      ELSE
        NULL
      END;
      SELF.endCoord  := &&INSTALL_SCHEMA..T_Vertex(p_segment.endCoord);
      SELF.sdo_gtype := TRUNC(NVL(p_segment.sdo_gtype,2002)/10)*10+2; -- Cannot be other than a line.
      SELF.sdo_srid  := p_segment.sdo_srid;
    END IF;
    Return;
  END;

  Constructor Function T_SEGMENT(SELF    IN OUT NOCOPY T_SEGMENT,
                                 p_line       in mdsys.sdo_geometry,
                                 p_segment_id in integer default 0)
  Return Self As Result
  As
    v_vertices      mdsys.vertex_set_type;
    v_isCircularArc boolean;
  Begin
    If (p_line is null) Then
       Return;
    End If;
    SELF.segment_id := NVL(p_segment_id,0);
    v_vertices := mdsys.sdo_util.getVertices(p_line);
    If (v_vertices is null or v_vertices.COUNT = 0) Then
       Return;
    End If;
    SELF.startCoord := &&INSTALL_SCHEMA..t_vertex(
                         p_vertex    => v_vertices(1),
                         p_sdo_gtype => TRUNC(NVL(p_line.sdo_gtype,2002)/10)*10+1,
                         p_sdo_srid  => p_line.sdo_srid);
    v_isCircularArc := p_line.sdo_elem_info(3) = 2;
    if ( v_isCircularArc ) Then
      SELF.midCoord := &&INSTALL_SCHEMA..t_vertex(
                         p_vertex    => v_vertices(2),
                         p_sdo_gtype => TRUNC(NVL(p_line.sdo_gtype,2002)/10)*10+1,
                         p_sdo_srid  => p_line.sdo_srid);
    End If;
    If (v_vertices.COUNT > 1) Then
      SELF.endCoord := &&INSTALL_SCHEMA..t_vertex(
                         p_vertex    => v_vertices(case when v_isCircularArc then 3 else 2 end),
                         p_sdo_gtype => TRUNC(NVL(p_line.sdo_gtype,2002)/10)*10+1,
                         p_sdo_srid  => p_line.sdo_srid);
    End If;
    SELF.sdo_gtype  := TRUNC(NVL(p_line.sdo_gtype,2002)/10)*10+2; -- Cannot be other than a line.
    SELF.sdo_srid   := p_line.sdo_srid;
    Return;
  End;

  Constructor Function T_SEGMENT(SELF    IN OUT NOCOPY T_SEGMENT,
                                 p_sdo_gtype In Integer,
                                 p_sdo_srid  In Integer)
  Return Self As Result
  As
  Begin
    SELF.element_id    := NULL;
    SELF.subelement_id := NULL;
    SELF.segment_id    := NULL;
    SELF.startCoord    := NULL;
    SELF.midCoord      := NULL;
    SELF.ENDCOORD      := NULL;
    SELF.sdo_gtype     := p_sdo_gtype;
    SELF.sdo_srid      := p_sdo_srid;
    Return;
  End;

  Constructor Function T_SEGMENT(SELF    IN OUT NOCOPY T_SEGMENT,
                                 p_segment_id  In Integer,
                                 p_startCoord IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_endCoord   IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_sdo_gtype  In Integer Default NULL,
                                 p_sdo_srid   In Integer Default NULL)
  Return Self AS Result
  AS
  BEGIN
    SELF.segment_id := p_segment_id;
    SELF.startCoord := p_startCoord;
    SELF.midCoord   := NULL;
    SELF.endCoord   := p_endCoord;
    SELF.sdo_gtype  := TRUNC(NVL(p_sdo_gtype,2002)/10)*10+2; -- Cannot be other than a line.
    SELF.sdo_srid   := p_sdo_srid;
    Return;
  END T_SEGMENT;

  Constructor Function T_SEGMENT(SELF    IN OUT NOCOPY T_SEGMENT,
                                 p_segment_id In Integer,
                                 p_startCoord IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_midCoord   IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_endCoord   IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_sdo_gtype  In Integer Default NULL,
                                 p_sdo_srid   In Integer Default NULL)
  Return Self AS Result
  AS
  BEGIN
    SELF.segment_id := p_segment_id;
    SELF.startCoord := p_startCoord;
    SELF.midCoord   := p_midCoord;
    SELF.endCoord   := p_endCoord;
    SELF.sdo_gtype  := TRUNC(NVL(p_sdo_gtype,2002)/10)*10+2; -- Cannot be other than a line.
    SELF.sdo_srid   := p_sdo_srid;
    Return;
  END T_SEGMENT;

  Constructor Function T_SEGMENT(SELF    IN OUT NOCOPY T_SEGMENT,
                                 p_segment_id In Integer,
                                 p_startCoord IN mdsys.vertex_type,
                                 p_endCoord   IN mdsys.vertex_type,
                                 p_sdo_gtype  In Integer Default NULL,
                                 p_sdo_srid   In Integer Default NULL)
  Return Self AS Result
  AS
  BEGIN
    SELF.segment_id := p_segment_id;
    SELF.startCoord := &&INSTALL_SCHEMA..t_vertex(
                         p_vertex    => p_startCoord,
                         p_sdo_gtype => TRUNC(NVL(p_sdo_gtype,2002)/10)*10+1,
                         p_sdo_srid  => p_sdo_srid);
    SELF.midCoord   := NULL;
    SELF.endCoord   := &&INSTALL_SCHEMA..T_Vertex(
                         p_vertex    => p_endCoord,
                         p_sdo_gtype => TRUNC(NVL(p_sdo_gtype,2002)/10)*10+1,
                         p_sdo_srid  => p_sdo_srid);
    SELF.sdo_gtype  := TRUNC(NVL(p_sdo_gtype,2002)/10)*10+2; -- Cannot be other than a line.
    SELF.sdo_srid   := p_sdo_srid;
    Return;
  END T_SEGMENT;

  Constructor Function T_SEGMENT(SELF    IN OUT NOCOPY T_SEGMENT,
                                 p_segment_id In Integer,
                                 p_startCoord IN mdsys.vertex_type,
                                 p_midCoord   IN mdsys.vertex_type,
                                 p_endCoord   IN mdsys.vertex_type,
                                 p_sdo_gtype  In Integer Default NULL,
                                 p_sdo_srid   In Integer Default NULL)
  Return Self AS Result
  AS
  BEGIN
    SELF.segment_id := p_segment_id;
    SELF.startCoord := &&INSTALL_SCHEMA..t_vertex(
                         p_vertex    => p_startCoord,
                         p_sdo_gtype => TRUNC(NVL(p_sdo_gtype,2002)/10)*10+1,
                         p_sdo_srid  => p_sdo_srid);
    SELF.midCoord   := &&INSTALL_SCHEMA..t_vertex(
                         p_vertex    => p_midCoord,
                         p_sdo_gtype => TRUNC(NVL(p_sdo_gtype,2002)/10)*10+1,
                         p_sdo_srid  => p_sdo_srid);
    SELF.endCoord   := &&INSTALL_SCHEMA..t_vertex(
                         p_vertex    => p_endCoord,
                         p_sdo_gtype => TRUNC(NVL(p_sdo_gtype,2002)/10)*10+1,
                         p_sdo_srid  => p_sdo_srid);
    SELF.sdo_gtype  := TRUNC(NVL(p_sdo_gtype,2002)/10)*10+2; -- Cannot be other than a line.
    SELF.sdo_srid   := p_sdo_srid;
    Return;
  END T_SEGMENT;

  Constructor Function T_SEGMENT(SELF    IN OUT NOCOPY T_SEGMENT,
                                 p_element_id    In Integer,
                                 p_subelement_id In Integer,
                                 p_segment_id    In Integer,
                                 p_startCoord    IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_endCoord      IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_sdo_gtype     In Integer Default NULL,
                                 p_sdo_srid      In Integer Default NULL)
  Return Self AS Result
  AS
  BEGIN
    SELF.element_id    := p_element_id;
    SELF.subelement_id := p_subelement_id;
    SELF.segment_id    := p_segment_id;
    SELF.startCoord    := p_startCoord;
    SELF.midCoord      := NULL;
    SELF.endCoord      := p_endCoord;
    SELF.sdo_gtype     := TRUNC(NVL(p_sdo_gtype,2002)/10)*10+2; -- Cannot be other than a line.
    SELF.sdo_srid      := p_sdo_srid;
    Return;
  END T_SEGMENT;

  Constructor Function T_SEGMENT(SELF    IN OUT NOCOPY T_SEGMENT,
                                 p_element_id    In Integer,
                                 p_subelement_id In Integer,
                                 p_segment_id    In Integer,
                                 p_startCoord    IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_midCoord      IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_endCoord      IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_sdo_gtype     In Integer Default NULL,
                                 p_sdo_srid      In Integer Default NULL)
  Return Self AS Result
  AS
  BEGIN
    SELF.element_id    := p_element_id;
    SELF.subelement_id := p_subelement_id;
    SELF.segment_id    := p_segment_id;
    SELF.startCoord    := p_startCoord;
    SELF.midCoord      := p_midCoord;
    SELF.endCoord      := p_endCoord;
    SELF.sdo_gtype     := TRUNC(NVL(p_sdo_gtype,2002)/10)*10+2; -- Cannot be other than a line.
    SELF.sdo_srid      := p_sdo_srid;
    Return;
  END T_SEGMENT;

  /* ================= Methods ================= */

  Member Procedure ST_SetCoordinates(SELF         IN OUT NOCOPY T_SEGMENT,
                                     p_startCoord in &&INSTALL_SCHEMA..T_VERTEX,
                                     p_midCoord   in &&INSTALL_SCHEMA..T_VERTEX,
                                     p_endCoord   in &&INSTALL_SCHEMA..T_VERTEX
                                     )
  As
  BEGIN
     SELF.startCoord := p_startCoord;
     SELF.midCoord   := p_endCoord;
     SELF.endCoord   := p_startCoord;
  END ST_SetCoordinates;

  Member Procedure ST_SetCoordinates(SELF         IN OUT NOCOPY T_SEGMENT,
                                     p_startCoord in &&INSTALL_SCHEMA..T_VERTEX,
                                     p_endCoord   in &&INSTALL_SCHEMA..T_VERTEX
                                     )
  As
  BEGIN
     SELF.startCoord := p_startCoord;
     SELF.endCoord   := p_startCoord;
  END ST_SetCoordinates;

  Member Function ST_Self
           Return &&INSTALL_SCHEMA..T_SEGMENT
  As
  Begin
    Return &&INSTALL_SCHEMA..T_Segment(SELF);
  End ST_Self;

  Member Function ST_isEmpty
    Return integer Deterministic
  AS
  BEGIN
    IF ( SELF.startCoord IS NULL OR SELF.endCoord IS NULL ) THEN
      Return 1;
    ELSE
      Return 0;
    END IF;
  END ST_isEmpty;

  Member Function ST_isCircularArc
           Return integer
  AS
    v_circle &&INSTALL_SCHEMA..T_Vertex;
  BEGIN
    IF ( SELF.ST_isEmpty() =1 ) THEN
      RETURN 0;
    END IF;
    IF ( SELF.startCoord IS NOT NULL
     AND SELF.midCoord   IS NOT NULL
     AND SELF.endCoord   IS NOT NULL ) THEN
      -- Check points not all in line.
      v_circle := SELF.ST_FindCircle();
      IF ( v_circle.ID = -9 ) THEN
        RETURN 0;
      ELSE
        RETURN 1;
      END IF;
    ELSE
      Return 0;
    END IF;
  END ST_isCircularArc;

  Member Function ST_Dims
    Return integer Deterministic
  AS
  BEGIN
    IF ( SELF.sdo_gtype   IS NULL ) THEN
      IF (SELF.startCoord IS NULL OR SELF.endCoord IS NULL ) THEN
        Return 0;
      ELSE
        Return CASE WHEN SELF.startCoord.x IS NULL THEN 0 ELSE 2 END +
               CASE WHEN SELF.startCoord.z IS NULL THEN 0 ELSE 1 END +
               CASE WHEN SELF.startCoord.w IS NULL THEN 0 ELSE 1 END;
      END IF;
    ELSE
      Return CASE WHEN SELF.sdo_gtype < 2000
                  THEN SELF.sdo_gtype
                  ELSE SELF.sdo_gtype / 1000
              END;
    END IF;
  END ST_Dims;

  Member Function ST_SRID
    Return integer Deterministic
  AS
  BEGIN
    Return SELF.sdo_srid;
  END ST_SRID;

  Member Function ST_hasM
  Return integer Deterministic
  AS
  BEGIN
    Return CASE WHEN SELF.sdo_gtype IS NULL
                THEN 0
                ELSE CASE WHEN MOD(TRUNC(SELF.sdo_gtype/100),10) = 0
                          THEN 0
                          ELSE 1
                      END
    END;
  END ST_hasM;

  Member Function ST_Lrs_Dim
  Return Integer Deterministic
  As
  Begin
     Return case when SELF.sdo_gtype is null then 0 else trunc(mod(SELF.sdo_gtype,1000)/100) end;
  End ST_Lrs_Dim;

  Member Function ST_hasZ
  Return integer
  As
  Begin
    -- DEBUG dbms_output.put_line('SEGMENT.ST_Length: v_has_z: ' || case when v_has_z then 'true' else 'false' end);
    Return CASE WHEN ( ( SELF.ST_Dims() = 3
                          AND SELF.ST_hasM()=0 /* is XYZ object */ )
                      OR SELF.ST_Dims() = 4 /* is XYZM */ )
                THEN 1
                ELSE 0
            END;
  end ST_hasZ;

  Member Function ST_To2D
  Return &&INSTALL_SCHEMA..T_SEGMENT
  AS
  BEGIN
    RETURN CASE WHEN SELF.ST_DIMS()=2
                THEN &&INSTALL_SCHEMA..T_SEGMENT(SELF)
                ELSE &&INSTALL_SCHEMA..T_SEGMENT(p_element_id    => SELF.element_id,
                                   p_subelement_id => SELF.element_id,
                                   p_segment_id     => SELF.segment_id,
                                   p_startCoord    => SELF.startCoord.ST_To2D(),
                                   p_midCoord      => NULL,
                                   p_endCoord      => SELF.EndCoord.ST_To2D(),
                                   p_sdo_gtype     => 2001,
                                   p_sdo_srid      => SELF.sdo_srid)
            END;
  END ST_To2D;

  Member Function ST_To3D(p_keep_measure in integer default 0,
                          p_default_z    in number  default null)
  Return &&INSTALL_SCHEMA..T_SEGMENT
  As
  Begin
    RETURN case when SELF.ST_Dims() = 2   /* Upscale to 3D */
                then &&INSTALL_SCHEMA..T_SEGMENT(
                       p_element_id    => SELF.element_id,
                       p_subelement_id => SELF.element_id,
                       p_segment_id     => SELF.segment_id,
                       p_startCoord    => SELF.StartCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z),
                       p_midCoord      => CASE WHEN SELF.midCoord is not NULL THEN SELF.midCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z) else null end,
                       p_endCoord      => SELF.endCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z),
                       p_sdo_gtype     => 2001,
                       p_sdo_srid      => SELF.sdo_srid
                     )
                when SELF.ST_Dims()=3 and SELF.ST_hasZ=1  /* Nothing to do */
                then T_SEGMENT(SELF)
                when SELF.ST_Dims()=3
                then &&INSTALL_SCHEMA..T_SEGMENT(
                       p_element_id    => SELF.element_id,
                       p_subelement_id => SELF.element_id,
                       p_segment_id     => SELF.segment_id,
                       p_startCoord    => SELF.StartCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z),
                       p_midCoord      => CASE WHEN SELF.midCoord is not NULL THEN SELF.midCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z) else null end,
                       p_endCoord      => SELF.endCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z),
                       p_sdo_gtype     => 3002,
                       p_sdo_srid      => SELF.sdo_srid
                     )
                when SELF.ST_Dims()=4
                then &&INSTALL_SCHEMA..T_SEGMENT(
                       p_element_id    => SELF.element_id,
                       p_subelement_id => SELF.element_id,
                       p_segment_id    => SELF.segment_id,
                       p_startCoord    => SELF.startCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z),
                       p_midCoord      => CASE WHEN SELF.midCoord is not NULL THEN SELF.midCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z) else null end,
                       p_endCoord      => SELF.endCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z),
                       p_sdo_gtype     => 3002,
                       p_sdo_srid      => SELF.sdo_srid
                     )
            END;
  End ST_To3D;

  Member Function ST_Merge(p_segment    in &&INSTALL_SCHEMA..T_SEGMENT,
                           p_dPrecision in integer default 6)
           Return &&INSTALL_SCHEMA..T_SEGMENT
  AS
    v_self     &&INSTALL_SCHEMA..T_Segment;
    v_segment  &&INSTALL_SCHEMA..T_Segment;
    v_vector3D &&INSTALL_SCHEMA..T_Vector3D;
  BEGIN
    IF ( p_segment IS NULL ) THEN
      Return SELF;
    END IF;
    -- Check if equals
    IF ( SELF.ST_Equals(p_segment    => p_segment,
                        p_dPrecision => NVL(p_dPrecision,6),
                        p_coords     => 1)=1) Then
      Return SELF;
    END IF;
    -- Ensure all segments are correctly ordered
    --
    v_self := &&INSTALL_SCHEMA..T_Segment(SELF);
    IF (    SELF.endCoord.ST_Equals(p_segment.endCoord,    p_dPrecision)=1 ) Then
      v_segment := &&INSTALL_SCHEMA..T_Segment(p_segment.ST_Reverse());
    ELSIF ( SELF.endCoord.ST_Equals(p_segment.startCoord,  p_dPrecision)=1 ) Then
      v_segment := &&INSTALL_SCHEMA..T_Segment(p_segment);
    ELSIF ( SELF.startCoord.ST_Equals(p_segment.startCoord,p_dPrecision)=1 ) Then
      v_self    := p_segment.ST_Reverse();
      v_segment := &&INSTALL_SCHEMA..T_Segment(SELF);
    ELSE
      -- They don't touch, so return Empty
      RETURN &&INSTALL_SCHEMA..T_Segment();
    END IF;

    -- We now have correct end/start relationship
    -- Check if join point is collinear using vector arithmetic.
    -- Equal is shared vertex and same direction (Subtract + Normalized => 0)
    v_vector3D := &&INSTALL_SCHEMA..t_vector3d(v_self)
                          .Normalize()
                          .Subtract(&&INSTALL_SCHEMA..t_vector3d(v_segment)
                                            .Normalize());
    /* DEBUG
       dbms_output.put_line('ST_Merge');
       dbms_output.put_line('v_self: ' || v_self.ST_AsText());
       dbms_output.put_line('v_self: ' || v_segment.ST_AsText());
       dbms_output.put_line('v_self.vector3D: '    || &&INSTALL_SCHEMA..t_vector3d(v_self).Normalize().AsText());
       dbms_output.put_line('v_segment.vector3D: ' || &&INSTALL_SCHEMA..t_vector3d(v_segment).Normalize().AsText());
       dbms_output.put_line('v_vector3D: ' || v_vector3D.AsText(p_dPrecision));
    */
    IF (  ROUND(v_vector3D.X,p_dPrecision) = 0
      and ROUND(v_vector3D.Y,p_dPrecision) = 0
      and ROUND(NVL(v_vector3D.Z,0),p_dPrecision) = 0 ) THEN
      Return new &&INSTALL_SCHEMA..T_SEGMENT(
                   p_segment_id    => 1,   /*SELF.segment_id*/
                   p_element_id    => SELF.element_id,
                   p_subelement_id => SELF.subelement_id,
                   p_startCoord    => v_self.startCoord,
                   p_endCoord      => v_segment.endCoord,
                   p_sdo_gtype     => SELF.sdo_gtype,
                   p_sdo_srid      => SELF.sdo_srid
                 );
    ELSE
      -- Two segments have shared end/start point but not collinar.
      -- Return merged segment with shared point as midCoord.
      Return new &&INSTALL_SCHEMA..T_SEGMENT(
                   p_segment_id    => 0,   /*SELF.segment_id*/
                   p_element_id    => SELF.element_id,
                   p_subelement_id => SELF.subelement_id,
                   p_startCoord    => v_self.startCoord,
                   p_midCoord      => v_self.endCoord,
                   p_endCoord      => v_segment.endCoord,
                   p_sdo_gtype     => SELF.sdo_gtype,
                   p_sdo_srid      => SELF.sdo_srid
                 );
    END IF;
  END ST_Merge;

  Member Function ST_Densify(p_distance  in number,
                             p_tolerance In number   default 0.005,
                             p_projected In Integer  default 1,
                             p_unit      In varchar2 default NULL)
           Return mdsys.sdo_geometry
  AS
    v_cum_length     number;
    v_ratio          number;
    v_length         number;
    v_section_length number;
    v_num_sections   pls_integer;
    v_num_vertices   pls_integer;
    v_ord            pls_integer := 1;
    v_dims           pls_integer := 2;
    v_vertex         &&INSTALL_SCHEMA..T_Vertex;
    v_ordinates      mdsys.sdo_ordinate_array;
  BEGIN
    -- DEBUG dbms_output.put_line('<ST_Densify>');
    IF ( p_distance is null ) THEN
      Return SELF.ST_SdoGeometry();
    END IF;
    -- Get Segment Length.
    v_length := SELF.ST_Length (p_tolerance=>p_tolerance,p_unit=>p_unit);
    -- DEBUG dbms_output.put_line('v_length: ' || v_length ); 
    If ( v_length <= p_distance ) Then
      Return SELF.ST_SdoGeometry();
    END IF;
    v_dims         := SELF.ST_Dims();
    v_ordinates    := mdsys.sdo_ordinate_array();
    -- Compute vertices to add to segment
    v_num_sections := CEIL(v_length / p_distance);
    v_num_vertices := v_num_sections - 1;
    -- DEBUG dbms_output.put_line('v_length: ' || v_length || ' p_distance: ' || p_distance || ' v_num_vertices: ' ||v_num_vertices); 
    -- Compute section length
    v_section_length := v_length / v_num_sections;
    -- DEBUG dbms_output.put_line('Num Sections:  ' || v_num_sections || ' v_section_length: ' ||v_section_length || ' v_vertices: ' || v_num_vertices);
    v_cum_length     := 0.0;
    FOR i IN 0..(v_num_vertices+1) LOOP
      IF ( i = 0 ) THEN -- Add start vertex
        v_vertex := &&INSTALL_SCHEMA..T_Vertex(SELF.startCoord);
      ELSIF ( i = (v_num_vertices+1) ) THEN -- Don't compute existing end vertex.
        v_vertex := &&INSTALL_SCHEMA..T_Vertex(SELF.endCoord);
      ELSE
        -- compute new vertex.
        v_cum_length := v_cum_length + v_section_length;
        v_ratio      := v_cum_length / v_length;
        -- DEBUG dbms_output.put_line('v_cum_length: ' || v_cum_length || ' v_ratio: ' ||v_ratio);
        v_vertex     := SELF.ST_OffsetPoint(
                            p_ratio     => v_ratio,
                            p_offset    => 0,
                            p_tolerance => p_tolerance,
                            p_projected => p_projected,
                            p_unit      => p_unit
                          );
      END IF;
      -- Add vertex to sdo_ordinate_array
      -- DEBUG dbms_output.put_line('  v_vertex to add: ' || v_vertex.ST_AsText());
      v_ordinates.EXTEND(v_Dims);
      v_ordinates(v_ord)   := v_vertex.x;
      v_ordinates(v_ord+1) := v_vertex.y;
      IF ( v_Dims >= 3 ) THEN
        v_ordinates(v_ord+2) := v_vertex.z;
        IF ( v_Dims > 3 ) THEN
          v_ordinates(v_ord+3) := v_vertex.w;
        END IF;
      END IF;
      v_ord := v_ord + v_Dims;
    END LOOP;
    -- DEBUG dbms_output.put_line('</ST_Densify>');
    Return mdsys.sdo_geometry(
             SELF.sdo_gtype,
             self.sdo_srid,
             NULL,
             mdsys.sdo_elem_info_array(1,2,1),
             v_ordinates
	   );
  END ST_Densify;

  Member Function ST_Reverse
  Return &&INSTALL_SCHEMA..T_SEGMENT
  AS
  BEGIN
    Return &&INSTALL_SCHEMA..T_SEGMENT(
             p_element_id    => SELF.ELEMENT_ID,
             p_subelement_id => SELF.SUBELEMENT_ID,
             p_segment_id    => SELF.segment_ID,
             p_startCoord    => SELF.ENDCOORD,
             p_midCoord      => SELF.MIDCOORD,
             p_endCoord      => SELF.STARTCOORD,
             p_sdo_gtype     => SELF.SDO_GTYPE,
             p_sdo_srid      => SELF.SDO_SRID
           );
  END ST_Reverse;

  Member Function ST_Bearing(p_projected in Integer Default 1,
                             p_normalize in Integer Default 1)
  Return Number Deterministic
  As
    v_bearing number;
  Begin
    v_bearing := SELF.StartCoord
                   .ST_Bearing(
                       p_vertex    => SELF.EndCoord,
                       p_projected => p_projected,
                       p_normalize => p_normalize
                   );
    Return v_bearing;
  End ST_Bearing;

  Member Function ST_Parallel(p_offset    in Number,
                              p_projected in Integer default 1)
  Return &&INSTALL_SCHEMA..T_SEGMENT Deterministic
  As
    v_deflection_angle Number;
    v_bearing           Number;
    v_offset            Number;
    v_sign              Number;
    v_delta_x           Number;
    v_delta_y           Number;
    v_circle            &&INSTALL_SCHEMA..T_Vertex;
    v_start_point       &&INSTALL_SCHEMA..T_Vertex;
    v_mid_point         &&INSTALL_SCHEMA..T_Vertex;
    v_end_point         &&INSTALL_SCHEMA..T_Vertex;
  Begin
    v_offset := NVL(p_offset,0.0);
    If ( v_offset = 0.0 ) Then
      Return SELF;
    END IF;

    v_sign := SIGN(v_offset);

    -- Process two point linestring first...
    IF ( SELF.ST_isCircularArc() = 0 /* LineString */ ) THEN

      -- Compute offset bearing from segment bearing (degrees)...
      v_bearing := SELF.ST_Bearing(p_projected => p_projected,
                                   p_normalize => 0)
                   +
                   (v_sign * 90.0); -- If left, then -90 else 90
      v_bearing := COGO.ST_Normalize( p_degrees => v_bearing );
      -- Compute first offset point
      v_start_point := SELF.startCoord
                           .ST_FromBearingAndDistance(
                               p_bearing => v_bearing,
                               p_distance => ABS(v_offset),
                               p_projected => 1
                            );

      -- Create deltas to apply to End Ordinate...
      v_delta_x := v_start_point.X - SELF.StartCoord.X;
      v_delta_y := v_start_point.Y - SELF.StartCoord.Y;

      -- Now return parallel segment
      RETURN &&INSTALL_SCHEMA..T_Segment(
               p_element_id    => SELF.element_id,
               p_subelement_id => SELF.subelement_id,
               p_segment_id    => SELF.segment_id,
               p_startCoord => &&INSTALL_SCHEMA..T_Vertex (
                    p_id        => SELF.startCoord.ID,
                    p_X         => v_start_point.X,
                    p_Y         => v_start_point.Y,
                    p_Z         => SELF.startCoord.Z,
                    p_W         => SELF.startCoord.W,
                    p_sdo_gtype => SELF.startCoord.sdo_gtype,
                    p_sdo_srid  => SELF.sdo_Srid
                ),
               p_endCoord => &&INSTALL_SCHEMA..T_Vertex (
                    p_id        => SELF.EndCoord.ID,
                    p_X         => SELF.EndCoord.X + v_delta_X,
                    p_Y         => SELF.EndCoord.Y + v_delta_Y,
                    p_Z         => SELF.EndCoord.Z,
                    p_W         => SELF.EndCoord.W,
                    p_sdo_gtype => SELF.startCoord.sdo_gtype,
                    p_sdo_srid  => SELF.sdo_Srid
               ),
              p_sdo_gtype => SELF.sdo_gtype,
              p_sdo_srid  => SELF.sdo_Srid
           );
    END IF;

    -- ###################################################
    -- Now we are processing a CircularCurve
    --

    -- Compute curve center
    --
    v_circle := SELF.ST_FindCircle();

    -- Is collinear?
    -- DEBUG dbms_output.put_line('ST_Parallel circle.ID='||v_circle.ID);
    IF ( v_circle.ID = -9 ) THEN
      -- Call this function again with no midCoord
      RETURN &&INSTALL_SCHEMA..T_Segment(
               p_element_id    => SELF.element_id,
               p_subelement_id => SELF.subelement_id,
               p_segment_id    => SELF.segment_id,
               p_startCoord => &&INSTALL_SCHEMA..T_Vertex (
                    p_id        => SELF.startCoord.ID,
                    p_X         => v_start_point.X,
                    p_Y         => v_start_point.Y,
                    p_Z         => SELF.startCoord.Z,
                    p_W         => SELF.startCoord.W,
                    p_sdo_gtype => SELF.startCoord.sdo_gtype,
                    p_sdo_srid  => SELF.sdo_Srid
                ),
               p_endCoord => &&INSTALL_SCHEMA..T_Vertex (
                    p_id        => SELF.EndCoord.ID,
                    p_X         => SELF.EndCoord.X + v_delta_X,
                    p_Y         => SELF.EndCoord.Y + v_delta_Y,
                    p_Z         => SELF.EndCoord.Z,
                    p_W         => SELF.EndCoord.W,
                    p_sdo_gtype => SELF.startCoord.sdo_gtype,
                    p_sdo_srid  => SELF.sdo_Srid
               ),
              p_sdo_gtype => SELF.sdo_gtype,
              p_sdo_srid  => SELF.sdo_Srid
           )
           .ST_Parallel(p_offset    => p_offset,
                        p_projected => p_projected);
    END IF;

    -- Compute which side the centre of the circular arc resides
    --
    v_deflection_angle := SELF
                           .midCoord
                           .ST_SubtendedAngle(
                               SELF.StartCoord,
                               SELF.EndCoord
                         );
    -- DEBUG dbms_output.put_line('  v_deflection_angle= '||Round(COGO.ST_Degrees(v_deflection_angle,0),6) || ' -> Centre on ' || case when v_deflection_angle < 0 then 'Left' else 'Right' end || ', Offset is to the ' || case when v_sign < 0 then 'Left' else 'Right' end );
    v_offset := ROUND(
                  case when v_deflection_angle < 0  /* Left Centre */
                       then case when v_sign < 0     /* Left Offset */
                                 then v_circle.Z - 
                                      ABS(v_offset)  /* Subtract ABS(v_offset) from Radius */
                                 else v_circle.Z + 
                                      ABS(v_offset)  /* Right Offset: Add offset to centre */
                             end
                       else case when v_sign < 0     /* Left Offset */
                                 then v_circle.Z + 
                                      ABS(v_offset)  /* Add offset to radius */
                                 else v_circle.Z - 
                                      ABS(v_offset)  /* Subtract offset from radius */
                             end
                   end,
                   6
                );

    -- Check if curve would degenerate into a single point
    IF ( v_offset <= 0.0 ) THEN
      v_circle.id := -1; -- Degenerated to nothing
      RETURN &&INSTALL_SCHEMA..T_Segment(
               p_element_id    => -1,
               p_subelement_id => -1,
               p_segment_id    => -1,
               p_startCoord    => &&INSTALL_SCHEMA..T_Vertex (v_circle),
               p_endCoord      => NULL,
               p_sdo_gtype     => SELF.sdo_gtype,
               p_sdo_srid      => SELF.sdo_Srid
           );
    END IF;

    -- Now compute new circularString points
    --
    -- Start Point
    --
    v_bearing     := v_circle.ST_Bearing(
                       p_vertex    => SELF.StartCoord,
                       p_projected => p_projected,
                       p_normalize => 1);
    v_start_point := v_circle
                       .ST_FromBearingAndDistance(
                           p_bearing   => v_bearing,
                           p_distance  => ABS(v_offset),
                           p_projected => 1
                        );

    -- Mid Point
    --
    v_bearing     := v_circle.ST_Bearing(p_vertex   =>SELF.MidCoord,
                                         p_projected=>p_projected,
                                         p_normalize=>1);
    v_mid_point   := v_circle
                       .ST_FromBearingAndDistance(
                           p_bearing   => v_bearing,
                           p_distance  => ABS(v_offset),
                           p_projected => 1
                        );
    -- End Point
    --
    v_bearing     := v_circle.ST_Bearing(
                       p_vertex    => SELF.EndCoord,
                       p_projected => p_projected,
                       p_normalize => 1);
    v_end_point   := v_circle
                       .ST_FromBearingAndDistance(
                           p_bearing   => v_bearing,
                           p_distance  => ABS(v_offset),
                           p_projected => 1
                        );

    -- Now return circular arc
    RETURN &&INSTALL_SCHEMA..T_Segment(
               p_element_id    => SELF.element_id,
               p_subelement_id => SELF.subelement_id,
               p_segment_id    => SELF.segment_id,
               p_startCoord    => &&INSTALL_SCHEMA..T_Vertex (
                    p_id        => SELF.startCoord.ID,
                    p_X         => v_start_point.X,
                    p_Y         => v_start_point.Y,
                    p_Z         => SELF.startCoord.Z,
                    p_W         => SELF.startCoord.W,
                    p_sdo_gtype => SELF.startCoord.sdo_gtype,
                    p_sdo_srid  => SELF.sdo_Srid
                ),
               p_midCoord => &&INSTALL_SCHEMA..T_Vertex (
                    p_id        => SELF.midCoord.ID,
                    p_X         => v_mid_point.X,
                    p_Y         => v_mid_point.Y,
                    p_Z         => SELF.midCoord.Z,
                    p_W         => SELF.midCoord.W,
                    p_sdo_gtype => SELF.startCoord.sdo_gtype,
                    p_sdo_srid  => SELF.sdo_Srid
                ),
               p_endCoord => &&INSTALL_SCHEMA..T_Vertex (
                    p_id        => SELF.endCoord.ID,
                    p_X         => v_end_point.X,
                    p_Y         => v_end_point.Y,
                    p_Z         => SELF.EndCoord.Z,
                    p_W         => SELF.EndCoord.W,
                    p_sdo_gtype => SELF.startCoord.sdo_gtype,
                    p_sdo_srid  => SELF.sdo_Srid
               ),
              p_sdo_gtype => SELF.sdo_gtype,
              p_sdo_srid  => SELF.sdo_Srid
           );
  End ST_Parallel;

  Member Function ST_AddCurveBetweenSegments(
                     p_segment   In &&INSTALL_SCHEMA..T_SEGMENT,
                     p_iVertex   in &&INSTALL_SCHEMA..T_Vertex default NULL,
                     p_radius    In number         default null,
                     p_tolerance In number         default 0.005,
                     p_projected In Integer        default 1,
                     p_unit      In varchar2       default NULL)
           Return mdsys.sdo_Geometry 
  As
    v_cVertex         &&INSTALL_SCHEMA..T_Vertex;
    v_iVertex         &&INSTALL_SCHEMA..T_Vertex;
    v_iExisted        boolean;
    v_iPoints         &&INSTALL_SCHEMA..T_Segment;
    v_perpendicular_2 &&INSTALL_SCHEMA..T_Segment;
  Begin
    -- DEBUG dbms_output.put_line('T_SEGMENT.ST_Closest: p_point is ' || case when p_point is null then 'NULL' else 'NOT NULL' end );
    If (p_segment is null) Then
       Return SELF.ST_SdoGeometry();
    End If;
    v_iExisted := false;
    If ( SELF.endCoord.ST_Equals(p_segment.startCoord)=1 ) Then
      v_iVertex  := &&INSTALL_SCHEMA..T_Vertex(SELF.endCoord);
      v_iExisted := true;
    Else
      IF ( p_iVertex is not null ) THEN
        v_iVertex  := p_iVertex;
      ELSE
        -- Calcular if both not cicular arc
        IF ( SELF.ST_isCircularArc()=0 AND p_segment.ST_isCircularArc()=0 ) THEN
          v_iPoints := SELF.ST_IntersectDetail(
                               p_segment   => p_segment,
                               p_tolerance => p_tolerance,
                               p_unit      => p_unit );
          IF ( v_iPoints is not null ) THEN
            v_iVertex := v_iPoints.startCoord;
            -- Check intersection is at correct end.
            IF ( NOT 
                (     v_iPoints.midCoord.ST_Equals(SELF.endCoord)=1 
                  and v_iPoints.endCoord.ST_Equals(p_segment.startCoord)=1 ) ) Then
              Return NULL; -- TODO: Raise exception?
            END IF;
          END IF;
        END IF;
      END IF;
    End If;
    -- We have endCoord, iVertex and startCoord
    -- Fit curve between them.
    IF ( p_radius is not null ) THEN
       -- Compute centre of circular arc
       v_cVertex := SELF.ST_OffsetBetween (
                            p_segment   => p_segment,
                            p_offset    => p_radius,
                            p_tolerance => p_tolerance,
                            p_unit      => p_unit,
                            p_projected => p_projected
                    );
       -- DEBUG dbms_output.put_line(v_cVertex.ST_AsText());
       Return v_cVertex.ST_SdoGeometry();
    END IF;
    Return SELF.ST_SdoGeometry();
  End ST_AddCurveBetweenSegments;

  Member Function ST_Length(p_tolerance IN NUMBER Default 0.005,
                            p_unit      IN VARCHAR2 Default NULL)
  Return NUMBER
  AS
    v_length    NUMBER;
    v_seg_len   NUMBER;
    v_test_len  NUMBER;
    v_dims      INTEGER;
    v_z_posn    INTEGER;
    v_has_z     BOOLEAN := SELF.ST_hasZ() = 1;
    v_geom      mdsys.sdo_geometry;
    v_tolerance NUMBER  := NVL(p_tolerance,0.005);
    v_isLocator BOOLEAN := false;
  BEGIN
    v_isLocator := case when &&INSTALL_SCHEMA..TOOLS.ST_isLocator() = 1 then true else false end;
    v_geom      := SELF.ST_SdoGeometry(SELF.ST_Dims());
    v_dims      := v_geom.get_Dims();
    v_z_posn    := (case v_geom.get_lrs_dim()
                         when 0 then v_dims
                         when 3 then v_dims
                         when 4 then 3
                      end ) - 1;
    -- DEBUG dbms_output.put_line('v_dims='||v_dims||' v_z_posn='||v_z_posn||' sdo_gtype='|| v_geom.sdo_gtype);
    -- Compute length
    --
    IF (  (v_geom.Get_Dims() = 2 /*2002*/ )
       OR (v_geom.Get_Dims() = 3 AND v_geom.Get_Lrs_Dim() != 0 /*3302*/) ) Then
       -- DEBUG dbms_output.put_line('T_SEGMENT.ST_LENGTH: 200x or 330x');
       v_length := CASE WHEN p_unit IS NOT NULL AND SELF.SDO_Srid IS NOT NULL
                        THEN MDSYS.SDO_Geom.SDO_Length(v_geom,v_tolerance,P_UNIT)
                        ELSE MDSYS.SDO_Geom.SDO_Length(v_geom,v_tolerance)
                    END;
    ELSIF (Not v_isLocator ) Then -- v_geom.GET_DIMS() = 3 /*3002*/ And Not v_isLocator) Then
       -- DEBUG dbms_output.put_line('T_SEGMENT.ST_LENGTH: Spatial sdo_geom.sdo_length; p_unit=' || NVL(p_unit,'null'));
       v_length := CASE WHEN p_unit IS NOT NULL AND SELF.SDO_Srid IS NOT NULL
                        THEN MDSYS.SDO_Geom.SDO_Length(v_geom,v_tolerance,P_UNIT)
                        ELSE MDSYS.SDO_Geom.SDO_Length(v_geom,v_tolerance)
                    END;
    ELSE -- isLocator
       -- Because srid may be lat/long, compute horizontal distance first
       v_geom.sdo_ordinates := mdsys.sdo_ordinate_array(1,2,3,4);
       v_geom.sdo_ordinates(1) := SELF.startCoord.x;
       v_geom.sdo_ordinates(2) := SELF.startCoord.y;
       v_geom.sdo_ordinates(3) := SELF.endCoord.x;
       v_geom.sdo_ordinates(4) := SELF.endCoord.y;
       v_seg_len := CASE WHEN p_unit IS NOT NULL AND SELF.SDO_Srid IS NOT NULL
                         THEN MDSYS.SDO_Geom.SDO_Length(v_geom,v_tolerance,P_UNIT)
                         ELSE MDSYS.SDO_Geom.SDO_Length(v_geom,v_tolerance)
                     END;
       -- DEBUG dbms_output.put_line('T_SEGMENT.ST_LENGTH v_seg_len= ' || v_seg_len);
       -- Now compute Z component
       v_length := SQRT(POWER(v_seg_len,2) +
                        POWER(case when v_z_posn = 3 then SELF.endCoord.z  else SELF.endCoord.w end
                              -
                              case when v_z_posn = 3 then SELF.StartCoord.z else SELF.StartCoord.w end,2) );
    END IF;
    -- DEBUG dbms_output.put_line('T_SEGMENT.ST_LENGTH Return = ' || v_length);
    Return v_length;
  END ST_Length;

  Member Function ST_LRS_Measure_Length
  Return NUMBER
  AS
  BEGIN
    Return CASE WHEN SELF.ST_Lrs_Dim() = 3 THEN (SELF.endCoord.z - SELF.startCoord.z)
                WHEN SELF.ST_Lrs_Dim() = 4 THEN (SELF.endCoord.w - SELF.startCoord.w)
                ELSE 0.0
            END;
  END ST_LRS_Measure_Length;

  Member Function ST_LRS_Compute_Measure(p_vertex    In &&INSTALL_SCHEMA..t_vertex,
                                         p_tolerance IN NUMBER   Default 0.005,
                                         p_unit      IN varchar2 Default null)
  Return number
  As
    v_vertex_no_lrs           &&INSTALL_SCHEMA..t_vertex;
    v_segment_no_lrs          &&INSTALL_SCHEMA..t_SEGMENT;
    v_start_to_point_SEGMENT  &&INSTALL_SCHEMA..t_SEGMENT;
    v_segment_length          number;
    v_start_to_point_distance number;
    v_measure                 number;
    v_measure_Length          number;
  Begin
    IF ( SELF.ST_hasM()=0 OR p_vertex is null ) THEN
      RETURN NULL;
    END IF;
    -- Assumes point is snapped to segment.
    -- If 3D or above, reduce to 3D and ensure has no measures
    v_vertex_no_lrs      := CASE WHEN p_vertex.ST_Dims() = 2
                                 THEN &&INSTALL_SCHEMA..T_vertex(p_vertex)
                                 WHEN p_vertex.ST_Dims() > 2
                                 THEN p_vertex.ST_To3D(p_keep_measure=>0,p_default_z=>NULL)
                             END;
    v_segment_no_lrs     := CASE WHEN SELF.ST_Dims() = 2
                                 THEN &&INSTALL_SCHEMA..t_SEGMENT(SELF)
                                 WHEN SELF.ST_Dims() > 2
                                 THEN SELF.ST_To3D(p_keep_measure=>0,p_default_z=>NULL)
                             END;
    IF ( v_vertex_no_lrs.ST_Dims() != v_segment_no_lrs.ST_Dims() ) THEN
      IF ( v_vertex_no_lrs.ST_Dims() = 2 ) THEN
         v_segment_no_lrs := v_segment_no_lrs.ST_To2D();
      ELSIF ( v_vertex_no_lrs.ST_Dims() = 3 ) THEN
         v_vertex_no_lrs := v_vertex_no_lrs.ST_To2D();
      END IF;
    END IF;
    v_segment_length := v_segment_no_lrs.ST_Length(p_tolerance=> p_tolerance,
                                                   p_unit     => p_unit);
    v_start_to_point_SEGMENT := &&INSTALL_SCHEMA..T_SEGMENT(
                                  p_segment_id  => 1,
                                  p_startCoord => v_segment_no_lrs.startCoord,
                                  p_endCoord   => v_vertex_no_lrs,
                                  p_sdo_gtype  => v_segment_no_lrs.Sdo_Gtype,
                                  p_sdo_srid   => SELF.sdo_srid);
    v_start_to_point_distance := v_start_to_point_SEGMENT.ST_Length(p_tolerance=>p_tolerance,
                                                                   p_unit     =>p_unit);
    v_measure_Length := SELF.ST_LRS_Measure_Length();
    v_measure := CASE WHEN SELF.ST_LRS_Dim() = 3 THEN SELF.StartCoord.z ELSE SELF.StartCoord.w END +
                 ( (v_start_to_point_distance / v_segment_length) * v_measure_length );
    -- DEBUG dbms_output.put_line('ST_LRS_Find_Measure(SEGMENT)='||v_measure);
    RETURN v_measure;
  END ST_LRS_Compute_Measure;

  -- Distance from external vertex to segment
  --
  Member Function ST_Distance(p_vertex     in &&INSTALL_SCHEMA..T_Vertex,
                              p_tolerance  in number   Default 0.005,
                              p_dPrecision In Integer  Default 2,
                              p_unit       in varchar2 Default null)
  Return Number
  As
    v_segment_geom    mdsys.sdo_geometry;
    v_point           mdsys.sdo_geometry;
    v_distance        number;
    v_length          number;
    v_vertex_b        &&INSTALL_SCHEMA..T_Vertex := 
                      &&INSTALL_SCHEMA..T_Vertex(
                        p_id => 0,
                        p_sdo_gtype => SELF.sdo_gtype,
                        p_sdo_srid  => SELF.sdo_srid
                      );
    v_vertex          &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_vertex);
    v_segment         &&INSTALL_SCHEMA..T_SEGMENT;
    v_has_z           BOOLEAN;
    v_tolerance       NUMBER  := NVL(p_tolerance,0.005);
    v_precision       NUMBER  := NVL(p_dPrecision,2);
    v_test_len        NUMBER;
    v_isLocator       BOOLEAN;
  Begin
    -- BEGIN dbms_output.put_line('T_SEGMENT.ST_DISTANCE: START');
    If (p_vertex is null) Then
       Return -1; /* False */
    End If;
    v_isLocator := case when &&INSTALL_SCHEMA..TOOLS.ST_isLocator() = 1 then true else false end;
    -- if start = end, then just compute distance to one of the endpoints
    if ( SELF.startCoord.ST_Equals(SELF.endCoord,p_dPrecision) = 1 ) then
      Return p_vertex.ST_Distance(SELF.startCoord);
    end if;
    -- Normalise geometries for use in sdo_geom.sdo_distance
    -- DEBUG dbms_output.put_line('v_vertex.ST_Dims() ' || v_vertex.ST_Dims() || ' = SELF.ST_Dims() '||SELF.ST_Dims());
    -- DEBUG dbms_output.put_line('v_vertex.ST_Lrs_Dim() ' || v_vertex.ST_Lrs_Dim() || ' = SELF.ST_Lrs_Dim() '||SELF.ST_Lrs_Dim());
    -- DEBUG dbms_output.put_line('v_vertex BEFORE ' || v_vertex.ST_AsTExt());
    v_vertex  := &&INSTALL_SCHEMA..T_Vertex(p_vertex);
    v_segment := &&INSTALL_SCHEMA..T_SEGMENT(SELF);
    IF ( v_vertex.ST_Dims() = 2 and SELF.ST_Dims() = 2 ) THEN
      NULL;  -- ie Do Nothing...
    ELSIF ( v_vertex.ST_Dims() = 2 and SELF.ST_Dims() = 3 ) THEN
      v_segment := SELF.ST_To2D();
    ELSIF ( v_vertex.ST_Dims() = 3 and SELF.ST_Dims() = 2 ) THEN
      v_vertex := v_vertex.ST_To2D();
    ELSIF ( v_vertex.ST_Dims() = 3 AND v_vertex.ST_Lrs_Dim()=3 ) THEN
      v_segment :=     SELF.ST_To2D();
      v_vertex := v_vertex.ST_To2D();
    ELSE
      v_segment :=     SELF.ST_To3D(p_keep_measure=>0,p_default_z=>NULL);
      v_vertex := v_vertex.ST_To3D(p_keep_measure=>0,p_default_z=>NULL );
    End If;
    -- DEBUG dbms_output.put_line(' v_segment: ' || v_segment.ST_AsText() || ' v_vertex: ' || v_vertex.ST_AsText());
    -- Get normalised geometries
    v_point   := v_vertex.ST_SdoGeometry();
    -- DEBUG SPDBA_DEBUG.PrintGeom(v_point,3,false,'v_point: ');
    v_segment_geom := v_segment.ST_SdoGeometry();
    -- DEBUG SPDBA_DEBUG.PrintGeom(v_segment_geom,3,false,'v_segment_geom: ');
    -- DEBUG dbms_output.put_line('T_SEGMENT.ST_DISTANCE: case when p_unit is not null and SELF.ST_Srid() is not null => '||case when p_unit is not null and SELF.ST_Srid() is not null then 'p_unit' else 'no p_unit' end);
    v_distance := case when p_unit is not null and SELF.ST_Srid() is not null
                       then mdsys.sdo_geom.sdo_distance(v_point,v_segment_geom,p_tolerance,p_unit)
                       else mdsys.sdo_geom.sdo_distance(v_point,v_segment_geom,p_tolerance)
                   end;
    v_has_z     := (SELF.ST_hasZ()=1 AND LEAST(v_vertex.ST_Dims(),SELF.ST_Dims()) > 2);
    -- DEBUG dbms_output.put_line('T_SEGMENT.ST_DISTANCE: v_has_z='||case when v_has_z then 'TRUE' else 'FALSE' end);
    if ( v_isLocator and v_has_z ) Then
       /* TOBEDONE: Add in Z height which hopefully is in p_units */
       -- DEBUG dbms_output.put('v_isLocator and v_has_z BEFORE=>' || v_distance);
       v_vertex_b := SELF.ST_Closest(p_vertex   =>v_vertex,
                                     p_tolerance=>p_tolerance,
                                     p_unit     =>p_unit);
       v_distance := ROUND(SQRT(POWER(v_distance,2) +
                                POWER(NVL(v_vertex_b.z,NVL(v_vertex.z,  0))
                                    - NVL(v_vertex.z,  NVL(v_vertex_b.z,0)),2)
                               ),v_precision);
       -- DEBUG dbms_output.put_line(' AFTER=>' || v_distance);
    End If;
    -- DEBUG dbms_output.put_line('T_SEGMENT.ST_DISTANCE: result is ' || NVL(round(v_distance,v_precision),-9999));
    Return round(v_distance,v_precision);
  End ST_Distance;

  Member Function ST_Closest (p_vertex    in &&INSTALL_SCHEMA..t_vertex,
                              p_tolerance in number  DEFAULT 0.05,
                              p_unit      In varchar2 DEFAULT NULL)
           Return &&INSTALL_SCHEMA..T_Vertex
  as
    geographic3D EXCEPTION;
    PRAGMA       EXCEPTION_INIT(
                    geographic3D,-13364
                 );

    v_segment_geom   mdsys.sdo_geometry;
    v_point          mdsys.sdo_geometry;
    v_point_on_point mdsys.sdo_geometry;
    v_point_on_line  mdsys.sdo_geometry;
    v_guess_measure  number;
    v_distance       number;
    v_length         number;
    v_segment        &&INSTALL_SCHEMA..T_SEGMENT;
    v_vertex         &&INSTALL_SCHEMA..T_Vertex := 
                     &&INSTALL_SCHEMA..T_Vertex(
                       p_id        => 0,
                       p_sdo_gtype => SELF.sdo_gtype,
                       p_sdo_srid  => SELF.sdo_srid
                     );
    v_has_z          BOOLEAN;
    v_dim            PLS_INTEGER;

    Function ST_Closest_Planar(p_vertex in &&INSTALL_SCHEMA..t_vertex)
      Return &&INSTALL_SCHEMA..T_Vertex
    as
       sqrP_LB  number;
       sqrP_LE  number;
       sqrLB_LE number;
       LB_LE    number;
       I_LB     number;
       u        number;

       Function sqrDistPP3D(p_v1 in &&INSTALL_SCHEMA..t_vertex,
                            p_v2 in &&INSTALL_SCHEMA..t_vertex)
       Return Number
       As
       Begin
         Return (p_v1.x - p_v2.x) * (p_v1.x - p_v2.x) +
                (p_v1.y - p_v2.y) * (p_v1.y - p_v2.y) +
                NVL((p_v1.z - p_v2.z),0) * NVL((p_v1.z - p_v2.z),0);
       End sqrDistPP3D;

    Begin
      sqrP_LB  := sqrDistPP3D(p_vertex, SELF.startCoord);
      sqrP_LE  := sqrDistPP3D(p_vertex, SELF.endCoord);
      sqrLB_LE := sqrDistPP3D(SELF.startCoord, SELF.endCoord);
      LB_LE    := SQRT(sqrLB_LE);
      I_LB     := (sqrP_LB + sqrLB_LE - sqrP_LE)/(2*LB_LE);
      -- Compute closest point
      u := I_LB/LB_LE;
      Return new &&INSTALL_SCHEMA..T_vertex(
                  p_x         => SELF.startCoord.x+ u*(SELF.endCoord.x-SELF.startCoord.x),
                  p_y         => SELF.startCoord.y+ u*(SELF.endCoord.y-SELF.startCoord.y),
                  p_z         => SELF.startCoord.z+ u*(SELF.endCoord.z-SELF.startCoord.z),
                  p_w         => NULL,
                  p_id        => 0,
                  p_sdo_gtype => p_vertex.sdo_gtype,
                  p_sdo_srid  => p_vertex.sdo_srid);
    END ST_Closest_Planar;

  Begin
    -- DEBUG dbms_output.put_line('T_SEGMENT.ST_Closest: p_point is ' || case when p_point is null then 'NULL' else 'NOT NULL' end );
    If (p_vertex is null) Then
       Return NULL;
    End If;

    -- SDO_CLOSEST_POINTS
    -- A. Cannot use to compute measure value even if we try and trick the code
    --    into doing so by pretending a 3302 segment is 3302.
    -- B. if Geodetic must be 3D SRID otherwise get rubbish.
    -- C. If Locator then both geom1/geom2 must be 2D
    -- D. If Spatial then don't mix dimensions eg 3001/4402
    --    So, convert both to Same Dimension and then add measure back in via alternate method
    -- DEBUG dbms_output.put_line(' SELF ' || SELF.ST_AsText());
    -- DEBUG dbms_output.put_line(' p_point ' || p_point.ST_AsText());
    v_vertex  := &&INSTALL_SCHEMA..T_Vertex(p_vertex);
    v_segment := &&INSTALL_SCHEMA..T_Segment(SELF);
    IF ( v_vertex.ST_Dims() = 2 and SELF.ST_Dims() = 2 ) THEN
      NULL;  -- ie Do Nothing...
    ELSIF ( v_vertex.ST_Dims() = 2 and SELF.ST_Dims() = 3 ) THEN
      v_segment := SELF.ST_To2D();
    ELSIF ( v_vertex.ST_Dims() = 3 and SELF.ST_Dims() = 2 ) THEN
      v_vertex  := v_vertex.ST_To2D();
    ELSIF ( v_vertex.ST_Dims() = 3 AND v_vertex.ST_Lrs_Dim()=3 ) THEN
      v_segment :=     SELF.ST_To2D();
      v_vertex  := v_vertex.ST_To2D();
    ELSE
      v_segment :=     SELF.ST_To3D(p_keep_measure=>0,p_default_z=>NULL);
      v_vertex  := v_vertex.ST_To3D(p_keep_measure=>0,p_default_z=>NULL );
    End If;
    -- DEBUG dbms_output.put_line(' v_segment: ' || v_segment.ST_AsText() || ' v_vertex: ' || v_vertex.ST_AsText());

    -- Compute closest point
    -- Get sdo_geometry point with same dimensionality as normalised vertex
    v_point        := v_vertex.ST_SdoGeometry();
    v_segment_geom := v_segment.ST_SdoGeometry();

    BEGIN
      /* Trap possible
             ORA-01403: no data found: ORA-06512: at "MDSYS.SDO_VERSION", line 5 ORA-06512: at  "MDSYS.SDO_3GL"
      */
      MDSYS.SDO_GEOM.SDO_CLOSEST_POINTS(
           geom1     => v_point,
           geom2     => v_segment_geom,
           tolerance => p_tolerance,
           unit      => p_unit,
           dist      => v_distance,
           geoma     => v_point_on_point,
           geomb     => v_point_on_line
      );
      -- DEBUG SPDBA_DEBUG.PrintGeom(v_point_on_line,3,false,'  v_point_on_line (SDO_CLOSEST_POINTS): ');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
           v_point_on_line := NULL;
        WHEN geographic3D THEN
          -- Force 2D answer
          v_point        := v_vertex.ST_To2D().ST_SdoGeometry();
          v_segment_geom := v_segment.ST_To2D().ST_SdoGeometry();
          MDSYS.SDO_GEOM.SDO_CLOSEST_POINTS(
            geom1     => v_point,
            geom2     => v_segment_geom,
            tolerance => p_tolerance,
            unit      => p_unit,
            dist      => v_distance,
            geoma     => v_point_on_point,
            geomb     => v_point_on_line
         );
    END;
    -- DEBUG dbms_output.put_line('  T_SEGMENT.ST_Closest: After SDO_CLOSEST_POINTS');
    -- Check if CLOSEST_POINTS worked
    --
    IF ( v_point_on_line is null or v_point_on_line.sdo_gtype is null ) THEN
      -- Situation where SDO_GEOM.SDO_CLOSEST_POINTS could not resolve (eg point of end of line)
      -- Call Older version which is only OK for projected data.
      RETURN ST_Closest_Planar(p_vertex=>p_vertex);
    ELSE
      RETURN &&INSTALL_SCHEMA..T_Vertex(v_point_on_line);
    End If;
  END ST_Closest;

  Member Function ST_FindCircle
    Return &&INSTALL_SCHEMA..T_Vertex
  AS
    v_centre &&INSTALL_SCHEMA..T_Vertex 
          := &&INSTALL_SCHEMA..T_Vertex(
                     p_coord_string => NULL,
                     p_id           => -9, -- Collinear
                     p_sdo_srid     => SELF.sdo_srid
                  );
    dA NUMBER;
    dB NUMBER;
    dC NUMBER;
    dD NUMBER;
    dE NUMBER;
    dF NUMBER;
    dG NUMBER;
    v_x      Number;
    v_y      Number;
    v_radius Number;
  BEGIN
    IF (SELF.ST_isEmpty()=1) THEN
      Return NULL;
    END IF;
    -- DEBUG dbms_output.put_line('SELF is ' || SELF.ST_AsText());
    IF ( SELF.midCoord IS NOT NULL AND SELF.midCoord.x IS NOT NULL ) THEN
      dA := SELF.midCoord.x - SELF.startCoord.x;
      dB := SELF.midCoord.y - SELF.startCoord.y;
      dC := SELF.endCoord.x - SELF.startCoord.x;
      dD := SELF.endCoord.y - SELF.startCoord.y;
      dE := dA              * (SELF.startCoord.x + SELF.midCoord.x) + dB * (SELF.startCoord.y + SELF.midCoord.y);
      dF := dC              * (SELF.startCoord.x + SELF.endCoord.x) + dD * (SELF.startCoord.y + SELF.endCoord.y);
      dG := 2.0             * (dA * (SELF.endCoord.y - SELF.midCoord.y) - dB * (SELF.endCoord.x - SELF.midCoord.x));
      -- If dG is zero then
      IF ( dG = 0 ) THEN
        -- DEBUG dbms_output.put_line('The three points are collinear and no finite-radius circle through them exists.');
        Return v_centre;
      ELSE
        v_x := (dD * dE - dB * dF) / dG;
        v_y := (dA * dF - dC * dE) / dG;
        v_radius := SQRT(POWER(SELF.startCoord.x - v_x,2)
                       + POWER(SELF.startCoord.y - v_y,2));
        v_centre := new &&INSTALL_SCHEMA..T_Vertex(
                           p_x         => v_x,
                           p_y         => v_y,
                           p_z         => v_radius,
                           p_w         => NULL,
                           p_id        => 0,
                           p_sdo_gtype => 3001,
                           p_sdo_srid  => SELF.sdo_srid);
        
        Return v_centre;
      END IF;
    ELSE
      Return NULL;
    END IF;
  END ST_FindCircle;

  Member Function ST_ComputeTangentPoint(p_position  In VarChar2,
                                         p_fraction  In Number   default 0.0,
                                         p_tolerance IN number   default 0.005,
                                         p_projected In Integer  default 1,
                                         p_unit      IN varchar2 default NULL)
  Return &&INSTALL_SCHEMA..T_Vertex
  AS
    c_i_invalid_position Constant Integer       := -20120;
    c_s_invalid_position Constant VarChar2(100) := 'p_position (*POSN*) must be one of START, MID, END, or FRACTION only.';
    c_i_invalid_fraction Constant Integer       := -20121;
    c_s_invalid_fraction Constant VarChar2(100) := 'When p_position = FRACTION, p_fraction must be between 0.0 and 1.0.';

    v_position  VarChar2(10) := UPPER(SUBSTR(NVL(p_position,'START'),1,10));
    v_angle     NUMBER;
    v_bearing   NUMBER;
    v_distance  NUMBER;
    v_fraction  Number := NVL(p_fraction,0.0);
    v_centre    &&INSTALL_SCHEMA..T_Vertex := 
                &&INSTALL_SCHEMA..T_Vertex(
                  p_id        => 0,
                  p_sdo_gtype => SELF.sdo_gtype,
                  p_sdo_srid  => SELF.sdo_srid
                );
    v_vertex    &&INSTALL_SCHEMA..T_Vertex := 
                &&INSTALL_SCHEMA..T_Vertex(
                  p_id        => 0,
                  p_sdo_gtype => SELF.sdo_gtype,
                  p_sdo_srid  => SELF.sdo_srid
                );
  BEGIN
    IF (SELF.ST_isCircularArc()=0) THEN
      Return NULL;
    END IF;
    IF ( v_position NOT IN ('START','MID','END','FRACTION')  ) THEN
      raise_application_error(c_i_invalid_position,
                      REPLACE(c_s_invalid_position,'*POSN*',v_position),true );
    END IF;
    IF ( v_position = 'FRACTION'
     and v_fraction not between 0.0 and 1.0 ) THEN
      raise_application_error(c_i_invalid_fraction,c_s_invalid_fraction,true );
    END IF;

    IF ( v_position = 'FRACTION' ) THEN
      v_vertex := SELF.ST_OffsetPoint(
                     p_ratio     => v_fraction,
                     p_offset    => 0.0,
                     p_tolerance => p_tolerance,
                     p_unit      => p_unit,
                     p_projected => p_projected);
    ELSE
      v_vertex := CASE v_position
                       WHEN 'START' THEN SELF.startCoord
                       WHEN 'MID'   THEN SELF.midCoord
                       WHEN 'END'   THEN SELF.endCoord
                       ELSE              SELF.endCoord
                   END;
      v_fraction := CASE v_position
                         WHEN 'START' THEN 0.0
                         WHEN 'MID'   THEN 0.5  -- SGG: Fix
                         WHEN 'END'   THEN 1.0
                         ELSE              1.0
                     END;
    END IF;
    -- Compute tangent coordinate
    v_centre := SELF.ST_FindCircle(); -- z holds radius
    -- DEBUG dbms_output.put_line('ST_ComputeTangentPoint: v_centre='||v_centre.ST_AsText());

    -- Turn this into a bearing
    v_bearing := v_vertex
                   .ST_Bearing(
                       p_vertex    => v_centre,
                       p_projected => p_projected,
                       p_normalize => 1
                   );
    -- DEBUG dbms_output.put_line('ST_ComputeTangentPoint: v_bearing='|| Round(v_bearing,8)|| ' Angle='||case when v_fraction <= 0.5 then 90.0 else -90.0 end || ' v_fraction:'||v_fraction);

    -- Compute tangent point by where on arc our point resides.
    v_bearing := &&INSTALL_SCHEMA..COGO.ST_Normalize(v_bearing + case when v_fraction <= 0.5 then 90.0 else -90.0 end);
    -- DEBUG dbms_output.put_line('next: v_bearing='||v_bearing);

    -- Create tangent point 1/2 radius distance from point on circular arc.
    v_distance := v_centre.z / 2.0;
    -- DEBUG dbms_output.put_line('ST_ComputeTangentPoint: v_centre(' || v_vertex.ST_AsText() || ').ST_FromBearingAndDistance(' || v_bearing || ',' || v_distance||')');

    Return v_vertex.ST_FromBearingAndDistance(v_bearing,v_distance,p_projected);
  END ST_ComputeTangentPoint;

  Member Function ST_ComputeTangentLine(p_position  in VarChar2,
                                        p_fraction  In Number   default 0.0,
                                        p_tolerance IN number   default 0.005,
                                        p_projected In Integer  default 1,
                                        p_unit      IN varchar2 default NULL)
           Return &&INSTALL_SCHEMA..T_Segment
  AS
    c_i_invalid_position Constant Integer       := -20120;
    c_s_invalid_position Constant VarChar2(100) := 'p_position (*POSN*) must be one of START, MID, END, or FRACTION only.';
    c_i_invalid_fraction Constant Integer       := -20121;
    c_s_invalid_fraction Constant VarChar2(100) := 'When p_position = FRACTION, p_fraction must be between 0.0 and 1.0.';
    v_position           VarChar2(10) := UPPER(SUBSTR(NVL(p_position,'START'),1,10));
    v_tangent_point      &&INSTALL_SCHEMA..T_Vertex;
    v_fraction           Number := NVL(p_fraction,0.0);
    v_vertex             &&INSTALL_SCHEMA..T_Vertex;
  Begin
    IF (SELF.ST_isCircularArc()=0) THEN
      Return NULL;
    END IF;
    IF ( v_position NOT IN ('START','MID','END','FRACTION')  ) THEN
      raise_application_error(c_i_invalid_position,
                      REPLACE(c_s_invalid_position,'*POSN*',v_position),true );
    END IF;
    IF ( v_position = 'FRACTION'
     and v_fraction not between 0.0 and 1.0 ) THEN
      raise_application_error(c_i_invalid_fraction,c_s_invalid_fraction,true );
    END IF;

    IF ( v_position = 'FRACTION' ) THEN
      v_vertex := SELF.ST_OffsetPoint(
                     p_ratio     => v_fraction,
                     p_offset    => 0.0,
                     p_tolerance => p_tolerance,
                     p_unit      => p_unit,
                     p_projected => p_projected);
    ELSE
      v_vertex := CASE v_position
                       WHEN 'START' THEN SELF.startCoord
                       WHEN 'MID'   THEN SELF.midCoord
                       WHEN 'END'   THEN SELF.endCoord
                       ELSE              SELF.endCoord
                   END;
      v_fraction := CASE v_position
                         WHEN 'START' THEN 0.0
                         WHEN 'MID'   THEN 0.5  -- SGG: Fix
                         WHEN 'END'   THEN 1.0
                         ELSE              1.0
                     END;
    END IF;

    v_tangent_point := SELF.ST_ComputeTangentPoint(p_position  => v_position,
                                                   p_fraction  => p_fraction,
                                                   p_tolerance => p_tolerance,
                                                   p_projected => p_projected,
                                                   p_unit      => p_unit );
    -- Now compute and return the tangent line.
    Return &&INSTALL_SCHEMA..T_Segment(
             p_segment_id => 1,
             p_startCoord => v_vertex,
             p_endCoord   => v_tangent_point,
             p_sdo_gtype  => 2002,
             p_sdo_srid   => SELF.sdo_srid
           );
  End ST_ComputeTangentLine;

  Member Function ST_OffsetPoint(p_ratio     IN NUMBER,
                                 p_offset    IN NUMBER,
                                 p_tolerance IN NUMBER   Default 0.005,
                                 p_unit      IN VARCHAR2 Default NULL,
                                 p_projected IN INTEGER)
  Return &&INSTALL_SCHEMA..T_Vertex
  AS
    v_az      NUMBER;
    v_length  NUMBER;
    v_angle   NUMBER;
    v_centre  &&INSTALL_SCHEMA..T_Vertex := 
              &&INSTALL_SCHEMA..T_Vertex(
                p_id        => 0,
                p_sdo_gtype => SELF.sdo_gtype,
                p_sdo_srid  => SELF.sdo_srid
              );
    v_vertex  &&INSTALL_SCHEMA..T_Vertex := 
              &&INSTALL_SCHEMA..T_Vertex(
                p_id        => 0,
                p_sdo_gtype => SELF.sdo_gtype,
                p_sdo_srid  => SELF.sdo_srid
              );
    v_bearing NUMBER;
    v_dir     Integer;
    v_dims    pls_integer;
    v_linePt  &&INSTALL_SCHEMA..T_Vertex := 
              &&INSTALL_SCHEMA..T_Vertex(
                p_id        => 0,
                p_sdo_gtype => SELF.sdo_gtype,
                p_sdo_srid  => SELF.sdo_srid);
    v_delta   &&INSTALL_SCHEMA..T_Vertex := 
              &&INSTALL_SCHEMA..T_Vertex(
                p_id        => 0,
                p_sdo_gtype => SELF.sdo_gtype,
                p_sdo_srid  => SELF.sdo_srid
              );
    v_point   mdsys.sdo_geometry;
  BEGIN
    -- DEBUG dbms_output.put_line('<ST_OffsetPoint>');
    IF (SELF.ST_isEmpty()=1) THEN
      Return NULL;
    END IF;
    IF (p_ratio NOT BETWEEN 0 AND 1) THEN
      Return NULL;
    END IF;
    v_dims := SELF.ST_Dims();
    -- DEBUG dbms_output.put_line('  p_ratio ' || p_ratio || ' p_offset='||p_offset || ' SELF.ST_AsText()=' || SELF.ST_AsText(3));
    IF ( SELF.midCoord IS NOT NULL AND SELF.midCoord.x IS NOT NULL ) THEN
      -- DEBUG dbms_output.put_line('midCoord is not null');
      -- Compute common centre and radius
      -- All calculations assume that the circular arc segment/segment is no larger than a semi-circle.
      --
      v_centre := SELF.ST_FindCircle();
      -- DEBUG dbms_output.put_line('centre is (id holds radius)=' || case when v_centre is null then 'NULL' else v_centre.ST_AsText() end);
      -- Get subtended angle ie angle of circular arc
      IF ( v_centre.id = -9 ) THEN
        RETURN NULL;
      END IF;
      v_angle := &&INSTALL_SCHEMA..COGO.ST_Degrees(
                   v_centre.ST_SubtendedAngle(
                     SELF.startCoord,
                     SELF.EndCoord
                   )
                 );
      -- DEBUG dbms_output.put_line('Subtended angle of circular arc at centre in degrees is  ' || v_angle);
      -- now get angle subtended by this measure ratio
      v_angle := p_ratio * v_angle;
      -- DEBUG dbms_output.put_line('Subtended angle based on ratio of circular arc ' || v_angle);
      -- Turn subtended angle of ratio into a bearing
      v_bearing := &&INSTALL_SCHEMA..COGO.ST_Normalize(
                     p_degrees => v_centre.ST_Bearing(
                                    p_vertex    => SELF.startCoord,
                                    p_projected => p_projected,
                                    p_normalize => 0
                                  )
                                  +
                                  v_angle
                   );
      -- DEBUG dbms_output.put_line('bearing is ' || v_bearing);
      -- Offset point is bearing+(radius+p_offset) from centre
      -- Can't use sdo_util.point_at_bearing as "The point geometry must be based on a geodetic coordinate system."
      v_vertex := v_centre.ST_FromBearingAndDistance(
                    v_bearing,
                    (v_centre.z+(p_offset*-1)),
                    p_projected
                  );
      -- DEBUG dbms_output.put_line('ST_FromBearingAndDistance: v_vertex ' || v_Vertex.ST_AsText());
    ELSE
      -- DEBUG dbms_output.put_line('  Compute base offset');
      v_az    := &&INSTALL_SCHEMA..COGO.ST_Radians(
                   p_degrees =>
                     SELF.StartCoord
                         .ST_Bearing(
                             p_vertex    => SELF.endCoord,
                             p_projected => p_projected,
                             p_normalize => 0
                     )
                 );
      v_dir   := CASE WHEN v_az < &&INSTALL_SCHEMA..COGO.PI() THEN -1 ELSE 1 END;
      v_delta := &&INSTALL_SCHEMA..T_Vertex(
                   p_x         => ABS(COS(v_az)) * NVL(p_offset,0) * v_dir,
                   p_y         => ABS(SIN(v_az)) * NVL(p_offset,0) * v_dir,
                   p_id        => 0,
                   p_sdo_gtype => SELF.startCoord.sdo_gtype,
                   p_sdo_srid  => SELF.sdo_srid
                 );
      IF NOT ( v_az > &&INSTALL_SCHEMA..COGO.PI()/2
           AND v_az < &&INSTALL_SCHEMA..COGO.PI()
            OR v_az > 3 * &&INSTALL_SCHEMA..COGO.PI()/2 ) THEN
        v_delta.x  := -1 * v_delta.x;
      END IF;
      -- v_delta holds offset delta line
      -- Need to compute point for that offset
      v_length := SELF.ST_Length(p_tolerance,p_unit);
      v_linePt := &&INSTALL_SCHEMA..T_Vertex(
                    p_x         => SELF.startCoord.x + p_ratio*(SELF.endCoord.x-SELF.startCoord.x),
                    p_y         => SELF.startCoord.y + p_ratio*(SELF.endCoord.y-SELF.startCoord.y),
                    p_z         => case when v_dims >= 3 then SELF.startCoord.z + (p_ratio*(SELF.endCoord.z-SELF.startCoord.z)) else null end,
                    p_w         => case when v_dims  = 4 then SELF.startCoord.w + (p_ratio*(SELF.endCoord.w-SELF.startCoord.w)) else null end,
                    p_id        => 0,
                    p_sdo_gtype => SELF.startCoord.sdo_gtype,
                    p_sdo_srid  => SELF.sdo_srid
                  );
      v_vertex := &&INSTALL_SCHEMA..T_Vertex(
                    p_x         => v_delta.x + v_linePt.x,
                    p_y         => v_delta.y + v_linePt.y,
                    p_Z         => case when v_linept.z is not null then v_linePt.z else null end,
                    p_w         => case when v_linept.w is not null then v_linePt.w else null end,
                    p_id        => 0,
                    p_sdo_gtype => SELF.startCoord.sdo_gtype,
                    p_sdo_srid  => SELF.sdo_srid
                  );
    END IF;
    -- DEBUG dbms_output.put_line('Returned vertex is ' || v_Vertex.ST_AsText());
    -- DEBUG dbms_output.put_line('</ST_OffsetPoint>');
    Return v_vertex;
  END ST_OffsetPoint;

  /* ST_OffsetBetween
  *  Computes offset point (left/-ve; right/+ve) at bi-sector of angle formed by SELF and p_segment
  */
  Member Function ST_OffsetBetween(p_segment   IN &&INSTALL_SCHEMA..T_SEGMENT,
                                   p_offset    IN NUMBER,
                                   p_tolerance IN NUMBER   Default 0.005,
                                   p_unit      IN VARCHAR2 Default NULL,
                                   p_projected IN INTEGER)
  Return &&INSTALL_SCHEMA..T_Vertex
  AS
    v_angle       NUMBER;
    v_bearing     NUMBER;
    v_offset      NUMBER := NVL(p_offset,0);
    v_centre      &&INSTALL_SCHEMA..T_Vertex := 
                  &&INSTALL_SCHEMA..T_Vertex(
                    p_id        => 0,
                    p_sdo_gtype => SELF.sdo_gtype,
                    p_sdo_srid  => SELF.sdo_srid
                  );
    v_vertex      &&INSTALL_SCHEMA..T_Vertex := 
                  &&INSTALL_SCHEMA..T_Vertex(
                    p_id        => 0,
                    p_sdo_gtype => SELF.sdo_gtype,
                    p_sdo_srid  => SELF.sdo_srid
                  );
    v_next_vertex &&INSTALL_SCHEMA..T_Vertex := 
                  &&INSTALL_SCHEMA..T_Vertex(
                    p_id        => 0,
                    p_sdo_gtype => SELF.sdo_gtype,
                    p_sdo_srid  => SELF.sdo_srid
                  );
    v_mid_vertex  &&INSTALL_SCHEMA..T_Vertex := 
                  &&INSTALL_SCHEMA..T_Vertex(
                    p_id        => 0,
                    p_sdo_gtype => SELF.sdo_gtype,
                    p_sdo_srid  => SELF.sdo_srid
                  );
    v_prev_vertex &&INSTALL_SCHEMA..T_Vertex := 
                  &&INSTALL_SCHEMA..T_Vertex(
                    p_id        => 0,
                    p_sdo_gtype => SELF.sdo_gtype,
                    p_sdo_srid  => SELF.sdo_srid
                  );
    v_geom        mdsys.sdo_geometry;
  BEGIN
    IF ( v_offset = 0 ) THEN
      -- Is the inflexion point
      Return &&INSTALL_SCHEMA..T_Vertex(SELF.endCoord);
    END IF;
    -- DEBUG 
    dbms_output.put_line('<ST_OffsetBetween>');
    -- DEBUG 
    dbms_output.put_line('      v_offset='||v_offset);
    -- DEBUG 
    dbms_output.put_line('      SELF=' || SELF.ST_AsText() || ' p_segment=' || p_segment.ST_AsText());
    v_mid_vertex    := &&INSTALL_SCHEMA..T_Vertex(SELF.endCoord); -- should be same as p_segment.startCoord.
    IF ( SELF.midCoord IS NOT NULL AND SELF.midCoord.x IS NOT NULL ) THEN
      v_prev_vertex := SELF.ST_ComputeTangentPoint('END',p_projected);
    ELSE
      v_prev_vertex := &&INSTALL_SCHEMA..T_Vertex(SELF.startCoord);
    END IF;
    IF ( p_segment.midCoord IS NOT NULL AND p_segment.midCoord.x IS NOT NULL) THEN
      v_next_vertex := p_segment.ST_ComputeTangentPoint('START',p_projected);
    ELSE
      v_next_vertex := &&INSTALL_SCHEMA..T_Vertex(p_segment.endCoord);
    END IF;
    -- DEBUG 
    dbms_output.put_line('      v_prev_vertex='||v_prev_vertex.ST_AsText() || '  v_mid_vertex=' ||v_mid_vertex.ST_AsText()  || ' v_next_vertex='||v_next_vertex.ST_AsText());
    v_angle   := v_mid_vertex.ST_SubtendedAngle(v_prev_vertex,v_next_vertex);
    -- DEBUG 
    dbms_output.put('      ST_SubtendedAngle(degrees)='||&&INSTALL_SCHEMA..COGO.ST_Degrees(v_angle));
    -- v_distance := ABS(v_offset / sin(v_angle/2.0));
    v_angle   := &&INSTALL_SCHEMA..COGO.ST_Degrees(
                   p_radians  => v_angle/2.0,
                   p_normalize=> 0
                 );
    -- DEBUG 
    dbms_output.put(' v_angle/2.0(degrees)='||v_angle);
    v_bearing := &&INSTALL_SCHEMA..COGO.ST_Normalize(
                   v_mid_vertex.ST_Bearing(
                     p_vertex => v_next_vertex,
                     p_projected => p_projected,
                     p_normalize => 0
                   )
                   +
                   CASE WHEN v_angle > 0 AND v_offset < 0 THEN 180
                        WHEN v_angle < 0 AND v_offset > 0 THEN 180
                        ELSE 0
                    END
                   +
                   v_angle
                 );
    -- DEBUG dbms_output.put(' v_bearing(half)='||round(v_bearing,6));
    -- DEBUG dbms_output.put_line(' v_offset='||round(v_offset,6));
    -- DEBUG dbms_output.put_line('      v_mid_vertex('||v_mid_vertex.x || ',' || v_mid_vertex.y || ').ST_FromBearingAndDistance(' || v_Bearing || ',' || v_offset||')');
    -- sdo_util.point_at_bearing only for geodetic
    v_vertex    := v_mid_vertex.ST_FromBearingAndDistance(v_Bearing,ABS(v_offset),p_projected);
    v_vertex.z  := SELF.endCoord.z;
    v_vertex.w  := SELF.endCoord.w;
    v_vertex.id := SELF.endCoord.id;
    -- DEBUG dbms_output.put_line('</ST_OffsetBetween>');
    Return v_vertex;
  END ST_OffsetBetween;

  Member Function ST_Intersect2CircularArcs(p_segment   in &&INSTALL_SCHEMA..T_Segment,
                                            p_tolerance in number   default 0.005,
                                            p_unit      in varchar2 default NULL)
           Return &&INSTALL_SCHEMA..T_Segment 
  As
    v_iPoints  &&INSTALL_SCHEMA..T_Segment;
    v_circle_1 &&INSTALL_SCHEMA..T_Vertex;
    v_circle_2 &&INSTALL_SCHEMA..T_Vertex;
    v_P0       &&INSTALL_SCHEMA..T_Vertex;
    v_P1       &&INSTALL_SCHEMA..T_Vertex;
    v_P2       &&INSTALL_SCHEMA..T_Vertex;
    v_d        Number;
    v_a        Number;
    v_h        NUMBER;
  Begin
    IF (      SELF.ST_IsCircularArc()=0 OR
         p_segment.ST_IsCircularArc()=0 ) THEN              
      Return SELF.ST_Intersect(p_segment,p_tolerance,p_unit);
    END IF;
    v_circle_1 :=      SELF.ST_FindCircle();
    v_circle_2 := p_segment.ST_FindCircle();
    IF ( v_circle_1.id = -9 or v_circle_2.id = -9 ) THEN
      Return SELF.ST_Intersect(p_segment,p_tolerance,p_unit);
    END IF;
    v_circle_1.w /*left*/ := v_circle_1.x - v_circle_1.z; 
    v_circle_2.w /*left*/ := v_circle_2.x - v_circle_2.z; 
    v_P0         := &&INSTALL_SCHEMA..T_Vertex(
                      p_x=>v_circle_1.x,
                      p_y=>v_circle_1.y,
                      p_id=>0,
                      p_sdo_gtype=>2001,
                      p_sdo_srid=>SELF.sdo_srid
                    );
    v_P1         := &&INSTALL_SCHEMA..T_Vertex(
                      p_x=>v_circle_2.x,
                      p_y=>v_circle_2.y,
                      p_id=>1,
                      p_sdo_gtype=>2001,
                      p_sdo_srid=>SELF.sdo_srid
                    );
    v_d  := v_P0.ST_Distance(v_P1,p_tolerance,p_unit);
    v_a  := ( v_circle_1.z*v_circle_1.z - v_circle_2.z*v_circle_2.z + v_d*v_d)/(2.0*v_d);
    v_h  := SQRT(v_circle_1.z*v_circle_1.z - v_a*v_a);
    v_P2 := v_P1.ST_Subtract(v_P0)
                .ST_Scale(v_a/v_d)
                .ST_Add(v_P0);
    v_iPoints := &&INSTALL_SCHEMA..T_Segment(
                   p_segment_id => 1,
                   p_startCoord => &&INSTALL_SCHEMA..T_Vertex(
                                     p_x         => v_P2.x + v_h * (v_P1.y - v_P0.y) / v_d,
                                     p_y         => v_P2.y - v_h * (v_P1.x - v_P0.x) / v_d,
                                     p_id        => 1,
                                     p_sdo_gtype => 2001,
                                     p_sdo_srid  => SELF.sdo_srid
                                   ),
                   p_endCoord   => &&INSTALL_SCHEMA..T_Vertex(
                                     p_x         => v_P2.x - v_h * (v_P1.y - v_P0.y) / v_d,
                                     p_y         => v_P2.y + v_h * (v_P1.x - v_P0.x) / v_d,
                                     p_id        => 3,
                                     p_sdo_gtype => 2001,
                                     p_sdo_srid  => SELF.sdo_srid
                                   ),
                   p_sdo_gtype  => SELF.sdo_gtype,
                   p_sdo_srid   => SELF.ST_Srid()
                 );
    Return v_iPoints;
  END ST_Intersect2CircularArcs;
  
  Member Function ST_IntersectCircularArc(p_segment   in &&INSTALL_SCHEMA..T_Segment,
                                          p_tolerance in number   default 0.005,
                                          p_unit      in varchar2 default NULL)
           Return &&INSTALL_SCHEMA..T_Segment
  Is
    c_dPrecision       integer := 8;
    v_centre           &&INSTALL_SCHEMA..T_Vertex;
    v_p1               &&INSTALL_SCHEMA..T_Vertex;
    v_p2               &&INSTALL_SCHEMA..T_Vertex;
    v_a                NUMBER;
    v_abScalingFactor1 Number;
    v_abScalingFactor2 Number;
    v_bBy2             Number;
    v_baX              Number;
    v_baY              Number;
    v_c                Number;
    v_caX              Number;
    v_caY              Number;
    v_disc             Number;
    v_pBy2             Number;
    v_q                Number;
    v_tmpSqrt          Number;

    -- Compute nearest point on SELF and p_segment
    v_dist_int_pt2lineStart  NUMBER;
    v_dist_int_pt2lineEnd    NUMBER; 
    v_dist_int_pt2CurveStart NUMBER;
    v_dist_int_pt2CurveEnd   NUMBER;
    v_dist_int_pt2CurveMid   NUMBER;

    v_within_arc             BOOLEAN;
    v_pt1_line               Number;
    v_pt1_arc                Number;
    v_arc_length             Number;
    v_arc_length_2           Number;
    v_line_length            Number;
    v_line_segment           &&INSTALL_SCHEMA..T_Segment;
    v_circular_arc           &&INSTALL_SCHEMA..T_Segment;
    v_circular_arc_2         &&INSTALL_SCHEMA..T_Segment;
    v_iPoints                &&INSTALL_SCHEMA..T_Segment;
    v_vertex                 &&INSTALL_SCHEMA..T_Vertex;
    
  Begin
dbms_output.put_line('<ST_IntersectCircle>');
    v_circular_arc := CASE WHEN SELF.ST_IsCircularArc()=1 THEN SELF ELSE p_segment END;
    v_line_segment := CASE WHEN SELF.ST_IsCircularArc()=0 THEN SELF ELSE p_segment END;
    v_arc_length   := v_circular_arc.ST_Length(p_tolerance,p_unit);
    v_line_length  := v_line_segment.ST_Length(p_tolerance,p_unit);
    v_centre       := v_circular_arc.ST_FindCircle(); -- We have already checked if p_circular_arc is indeed a circular arc.
    IF ( v_centre.id = -9 ) Then
dbms_output.put_line('</ST_IntersectCircle>');
      Return NULL;
    End If;

    v_baX  := v_line_segment.endCoord.x - v_line_segment.startCoord.x;
    v_baY  := v_line_segment.endCoord.y - v_line_segment.startCoord.y;
    v_caX  := v_centre.x      - v_line_segment.startCoord.x;
    v_caY  := v_centre.y      - v_line_segment.startCoord.y;
    v_a    := POWER(v_baX,2) + POWER(v_baY,2);
    v_bBy2 := v_baX * v_caX  + v_baY * v_caY;
    v_c    := POWER(v_caX,2) + POWER(v_caY,2) - POWER(v_centre.Z,2);
    v_pBy2 := v_bBy2 / v_a;
    v_q    := v_c    / v_a;
    v_disc := v_pBy2 * v_pBy2 - v_q;
    
    IF (v_disc < 0) THEN
      Return new &&INSTALL_SCHEMA..T_Segment();
    END IF;

    -- if v_disc == 0 .. dealt with later
    v_tmpSqrt          := SQRT(v_disc);
    v_abScalingFactor1 := -v_pBy2 + v_tmpSqrt;
    v_abScalingFactor2 := -v_pBy2 - v_tmpSqrt;
    v_p1               := new &&INSTALL_SCHEMA..T_Vertex(
                              p_x         => v_line_segment.startCoord.x - v_baX * v_abScalingFactor1,
                              p_y         => v_line_segment.startCoord.y - v_baY * v_abScalingFactor1,
                              p_id        => 1,
                              p_sdo_gtype => 2001,
                              p_sdo_srid  => v_line_segment.sdo_Srid
                            );
                            
    -- DEBUG 
    dbms_output.put_line('    v_p1: '||v_p1.ST_AsText());
    
    v_iPoints := &&INSTALL_SCHEMA..T_Segment(
                   p_segment_id => 1,
                   p_startCoord => &&INSTALL_SCHEMA..T_Vertex(
                                     p_id        => 1,
                                     p_sdo_gtype => 2001,
                                     p_sdo_srid  => SELF.sdo_srid
                                   ),
                   p_midCoord   => &&INSTALL_SCHEMA..T_Vertex(
                                     p_id        => 2,
                                     p_sdo_gtype => 2001,
                                     p_sdo_srid  => SELF.sdo_srid
                                   ),
                   p_endCoord   => &&INSTALL_SCHEMA..T_Vertex(
                                     p_id        => 3,
                                     p_sdo_gtype => 2001,
                                     p_sdo_srid  => SELF.sdo_srid
                                   ),
                   p_sdo_gtype  => SELF.sdo_gtype,
                   p_sdo_srid   => SELF.ST_Srid()
                 );

    IF (v_disc = 0) THEN
      -- TODO: Why return?
      -- abScalingFactor1 == abScalingFactor2
      v_iPoints.startCoord := &&INSTALL_SCHEMA..T_Vertex(v_p1);
      Return new &&INSTALL_SCHEMA..T_Segment(v_iPoints);
    END IF;
    v_p2 := new &&INSTALL_SCHEMA..T_Vertex(
                p_x         => v_line_segment.startCoord.x - v_baX * v_abScalingFactor2,
                p_y         => v_line_segment.startCoord.y - v_baY * v_abScalingFactor2,
                p_id        => 2,
                p_sdo_srid  => v_line_segment.sdo_srid,
                p_sdo_gtype => 2001
              );
    -- DEBUG 
    dbms_output.put_line('    v_p2: '||v_p2.ST_AsText());
    
    -- Computations are based on a circle.
    -- Which point is within the actual circular segment?
    -- Will be one nearest end/start points           
    v_circular_arc_2 := &&INSTALL_SCHEMA..T_Segment(
                          p_segment_id => 0,
                          p_startCoord => v_circular_arc.startCoord,
                          p_midCoord   => v_p2,
                          p_endCoord   => v_circular_arc.endCoord,
                          p_sdo_gtype  => v_circular_arc.sdo_gtype,
                          p_sdo_srid   => v_circular_arc.sdo_srid
                        );
    v_arc_length_2 := v_circular_arc_2.ST_Length(p_tolerance,p_unit);
    -- DEBUG dbms_output.put_line('   v_arc_length = ' || v_arc_length ||' v_arc_length_2= ' || v_arc_length_2);
    -- DEBUG dbms_output.put_line('   v_arc_length_2 = v_arc_length then circular arc length unchanged then this must be a point on the arc.');
    v_iPoints.startCoord := &&INSTALL_SCHEMA..T_Vertex(
                              p_x         => CASE WHEN ROUND(v_arc_length,NVL(c_dPrecision,6)) = ROUND(v_arc_length_2,NVL(c_dPrecision,6)) THEN v_p1.x ELSE v_p2.x END,
                              p_y         => CASE WHEN ROUND(v_arc_length,NVL(c_dPrecision,6)) = ROUND(v_arc_length_2,NVL(c_dPrecision,6)) THEN v_p1.y ELSE v_p2.y END,
                              p_id        => 1,
                              p_sdo_gtype => 2001,
                              p_sdo_srid  => SELF.sdo_srid
                              );

    v_within_arc := FALSE;
    IF ( ROUND(v_arc_length,6) = ROUND(v_arc_length_2,6) ) THEN
      v_within_arc := TRUE;
      -- DEBUG
dbms_output.put_line('   1. Intersection point is within circular arc segment: Assign it as nearest point on curve.');
      IF ( SELF.ST_isCircularArc()=1 ) THEN
        -- SELF is circular arc
        v_iPoints.midCoord := new T_Vertex(v_p1);
      ELSE 
        -- p_segment is Circular Arc
        v_iPoints.endCoord := new T_Vertex(v_p1);
dbms_output.put_line('</ST_IntersectCircle>');
      END IF;
    END IF;

    -- DEBUG
dbms_output.put_line('   2. Now find the intersection with the linestring.');
  
    -- DEBUG
dbms_output.put_line('   3. Find the closest point on the linear segment'); 
    v_dist_int_pt2lineStart := v_iPoints.startCoord.ST_Distance(v_line_segment.startCoord,NVL(p_tolerance,0.05),p_unit);
    v_dist_int_pt2lineEnd   := v_iPoints.startCoord.ST_Distance(v_line_segment.endCoord,  NVL(p_tolerance,0.05),p_unit);

dbms_output.put_line('   v_dist_int_pt2lineStart start(' || v_dist_int_pt2lineStart||') + v_dist_int_pt2lineEnd('||v_dist_int_pt2lineEnd||')= '||(ROUND(v_dist_int_pt2LineStart,6) + ROUND(v_dist_int_pt2LineEnd,6)) );
    IF ( ROUND(v_line_length,6) = ROUND(v_dist_int_pt2LineStart,6) + ROUND(v_dist_int_pt2LineEnd,6) ) THEN
      -- DEBUG
dbms_output.put_line('   3.1 intersection point is within line segment: Assign it as nearest point on line.');
      IF ( SELF.ST_isCircularArc()=1 ) THEN
        -- SELF is circular arc
        v_iPoints.endCoord := new T_Vertex(v_iPoints.startCoord);
      ELSE 
        -- p_segment is Circular Arc
        v_iPoints.midCoord := new T_Vertex(v_iPoints.startCoord);
      END IF;
      IF ( v_within_arc ) THEN
        -- DEBUG
dbms_output.put_line('   3.2 Intersection point is within both segments, return it.');
dbms_output.put_line('       Intersection Points are ' || v_iPoints.ST_AsText());
dbms_output.put_line('</ST_IntersectCircle>');
        Return v_iPoints;
      END IF;
    ELSE
      -- DEBUG
dbms_output.put_line('   3.1 Intersection point is Near Line.');
      IF ( v_dist_int_pt2LineStart = LEAST(v_dist_int_pt2LineStart,v_dist_int_pt2LineEnd) ) THEN
dbms_output.put_line('       3.2 Is Near Start');
        v_iPoints.midCoord := new T_Vertex(SELF.startCoord);
      ELSE
dbms_output.put_line('       3.2 Is Near End');
       v_iPoints.midCoord := new T_Vertex(SELF.endCoord);
      END IF;
    END IF;
    
    IF ( v_within_arc ) THEN
      -- We are finished
dbms_output.put_line('      Intersection Points are ' || v_iPoints.ST_AsText());
dbms_output.put_line('</ST_IntersectCircle>');
      Return v_iPoints;
    END IF;
    
    -- DEBUG
dbms_output.put_line('   4. Compute Closest Circular Arc Point.');
dbms_output.put_line('      TODO: MidCoord Closest?');
    --v_pt1_line               := v_line_segment.ST_Distance(p_vertex=>v_p1,p_tolerance=>p_tolerance,p_dPrecision=>6,p_unit=>p_unit);
    --v_pt1_arc                := v_circular_arc.ST_Distance(p_vertex=>v_p1,p_tolerance=>p_tolerance,p_dPrecision=>6,p_unit=>p_unit);
    v_dist_int_pt2CurveStart := v_iPoints.startCoord.ST_Distance(v_circular_arc.startCoord,NVL(p_tolerance,0.05),p_unit);
    v_dist_int_pt2CurveEnd   := v_iPoints.startCoord.ST_Distance(v_circular_arc.endCoord,  NVL(p_tolerance,0.05),p_unit);

dbms_output.put_line('     v_dist_int_pt2CurveStart=' || v_dist_int_pt2CurveStart);  
dbms_output.put_line('       v_dist_int_pt2CurveEnd=' || v_dist_int_pt2CurveEnd);
    v_vertex := case when v_dist_int_pt2CurveStart = LEAST(v_dist_int_pt2CurveStart,v_dist_int_pt2CurveEnd) 
                     then v_circular_arc.startCoord
                     else v_circular_arc.endCoord
                end;
dbms_output.put_line('      4.1 Point is ' || v_vertex.ST_AsText());
     -- Assign start/end coord to midCoord
    IF ( SELF.ST_isCircularArc()=1 ) THEN
      v_iPoints.midCoord := v_vertex;
    ELSE
      v_iPoints.endCoord := v_vertex;
    END IF;      
dbms_output.put_line('      Intersection Points are ' || v_iPoints.ST_AsText());
dbms_output.put_line('</ST_IntersectCircle>');
    Return v_iPoints; 
  END ST_IntersectCircularArc;

  Member Function ST_Intersect(p_segment   IN &&INSTALL_SCHEMA..T_SEGMENT,
                               p_tolerance IN number   Default 0.005,
                               p_projected in integer  Default 1,
                               p_unit      IN varchar2 Default NULL)
           Return &&INSTALL_SCHEMA..T_Segment
  As
    c_i_two_circular_arcs    Constant pls_integer   := -20101;
    c_s_two_circular_arcs    Constant VarChar2(100) := 'Intersection of 2 circular arcs not yet supported.';

    v_a            number;
    v_p1           &&INSTALL_SCHEMA..T_Vertex;
    v_p2           &&INSTALL_SCHEMA..T_Vertex;

    v_V1           &&INSTALL_SCHEMA..T_VECTOR3D;
    v_V2           &&INSTALL_SCHEMA..T_VECTOR3D;
    v_V1xV2        &&INSTALL_SCHEMA..T_VECTOR3D;
    v_p21xV2       &&INSTALL_SCHEMA..T_VECTOR3D;
    v_pV           &&INSTALL_SCHEMA..T_VECTOR3D;

    v_iWD          &&INSTALL_SCHEMA..T_Segment;
    v_segment      &&INSTALL_SCHEMA..T_Segment;
    v_circular_arc &&INSTALL_SCHEMA..T_Segment;
    v_intersection &&INSTALL_SCHEMA..T_Vertex;
    v_distance_from_start number;
    v_ratio               number;
    v_iPoints      &&INSTALL_SCHEMA..T_Segment;

    -- ************************************
    -- Circular arc and intersection

    -- ************************************
    
  Begin
dbms_output.put_line('<ST_Intersect>');
    -- DBEUG 
dbms_output.put_line(SELF.ST_AsText()||'.ST_Intersect(' || p_segment.ST_Astext()||')');
    If ( p_segment is null       OR
        p_segment.ST_isEmpty()=1 OR 
        SELF.ST_isEmpty()=1 ) Then
dbms_output.put_line('</ST_Intersect>');
       Return null;
    End If;

    IF (       SELF.ST_isCircularArc() = 1 AND 
         p_segment.ST_isCircularArc() = 1 ) THEN
      v_iWD := SELF.ST_Intersect2CircularArcs(p_segment,p_tolerance,p_unit);
    END IF; 
    
    IF ( SELF.ST_isCircularArc() = 1 OR p_segment.ST_isCircularArc() = 1 ) THEN
dbms_output.put_line('   Calling ST_IntersectCircularArc');
      v_iWD := SELF.ST_IntersectCircularArc(p_segment,
                                            p_tolerance,
                                            p_unit);
      -- TODO: Change return type of main function to T_Segment
dbms_output.put_line('</ST_Intersect>');
      RETURN case when v_iWD is null
                  then NULL
                  else new &&INSTALL_SCHEMA..T_Segment(v_iWD)
              end;
    END IF;

    -- v_segment and p_segment are both linestring segments
    -- Create 2D intersection point first
    v_iWD := SELF.ST_IntersectDetail(p_segment => p_segment);
    -- DEBUG dbms_output.put_line('v_iWD: ' || v_iWD.ST_Astext());

    IF ( v_iWD.startCoord.ST_Equals(v_iWD.endCoord,8)=1 ) Then
dbms_output.put_line('</ST_Intersect>');
      Return new &&INSTALL_SCHEMA..T_Segment(v_iWD);
    Else
      -- No intersection
      v_iPoints := new &&INSTALL_SCHEMA..T_Segment();
      v_iPoints.segment_id := -99;
dbms_output.put_line('</ST_Intersect>');
      Return new &&INSTALL_SCHEMA..T_Segment(v_iWD);
    END If;
  End ST_Intersect;

  Member Function ST_IntersectDetail(p_segment   in &&INSTALL_SCHEMA..T_SEGMENT,
                                     p_tolerance in number default 0.005,
                                     p_unit      in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_SEGMENT
  AS
    v_dx1          NUMBER;
    v_dY1          NUMBER;
    v_dx2          NUMBER;
    v_dy2          NUMBER;
    v_t1           NUMBER;
    v_t2           NUMBER;
    v_denominator  NUMBER;
    v_iPoints      &&INSTALL_SCHEMA..T_Segment;
    v_test_segment &&INSTALL_SCHEMA..T_Segment;
    v_intersection &&INSTALL_SCHEMA..T_Segment
            := new &&INSTALL_SCHEMA..T_Segment (
                     p_segment_id => 1,
                     p_startCoord => new T_Vertex(SELF.sdo_gtype,SELF.sdo_srid),
                     p_midCoord   => new T_Vertex(SELF.sdo_gtype,SELF.sdo_srid),
                     p_endCoord   => new T_Vertex(SELF.sdo_gtype,SELF.sdo_srid),
                     p_sdo_gtype  => SELF.Sdo_Gtype,
                     p_sdo_srid   => SELF.sdo_srid
               );
               
  BEGIN
dbms_output.put_line('<ST_IntersectDetail>');
    -- TODO: Support circular arcs.
    IF ( SELF.ST_isCircularArc() = 1 OR p_segment.ST_isCircularArc() = 1 ) THEN
      dbms_output.put_line('<ST_IntersectWithCircularArc>');
      v_iPoints := SELF.ST_Intersect(p_segment   => p_segment,
                                     p_tolerance => p_tolerance,
                                     p_projected => 1,
                                     p_unit      => p_unit);
dbms_output.put_line('  v_intersection='||v_iPoints.ST_AsText());
dbms_output.put_line('</ST_IntersectWithCircularArc>');
dbms_output.put_line('</ST_IntersectDetail>');
      Return &&INSTALL_SCHEMA..T_Segment(v_iPoints);
    END IF;
    -- Get the segments' parameters.
    v_dx1  := SELF.endCoord.x    - SELF.startCoord.x;
    v_dY1  := SELF.endCoord.y    - SELF.startCoord.y;
    -- DEBUG dbms_output.put_line('v_dx1='||v_dx1||' v_dY1='||v_dY1);
    v_dx2 := p_segment.endCoord.x - p_segment.startCoord.x;
    v_dy2 := p_segment.endCoord.y - p_segment.startCoord.y;
    -- DEBUG dbms_output.put_line('v_dx2='||v_dx2||' v_dy2='||v_dy2);
    -- Solve for t1 and t2.
    v_denominator     := (v_dY1 * v_dx2 - v_dx1 * v_dy2);
    -- DEBUG dbms_output.put_line('v_denominator='||v_denominator);
    IF ( v_denominator = 0 ) THEN
      v_intersection.StartCoord.id := -3;
      -- DEBUG dbms_output.put_line('The lines are parallel or straight and connected');
      If ( (SELF.startCoord.x=p_segment.startCoord.x and SELF.startCoord.y=p_segment.startCoord.y)
        OR (SELF.startCoord.x=p_segment.endCoord.x   and SELF.startCoord.y=p_segment.endCoord.y) ) Then
        v_intersection.startCoord.x := SELF.startCoord.x;
        v_intersection.midCoord.x   := SELF.startCoord.x;
        v_intersection.endCoord.x   := SELF.startCoord.x;
        v_intersection.startCoord.y := SELF.startCoord.y;
        v_intersection.midCoord.y   := SELF.startCoord.y;
        v_intersection.endCoord.y   := SELF.startCoord.y;
      ElsIf ((SELF.endCoord.x=p_segment.endCoord.x   and SELF.endCoord.y=p_segment.endCoord.y)
        OR   (SELF.endCoord.x=p_segment.startCoord.x and SELF.endCoord.y=p_segment.startCoord.y) ) Then
        v_intersection.StartCoord.x := SELF.endCoord.x;
        v_intersection.midCoord.x   := SELF.endCoord.x;
        v_intersection.endCoord.x   := SELF.endCoord.x;
        v_intersection.StartCoord.y := SELF.endCoord.y;
        v_intersection.midCoord.y   := SELF.endCoord.y;
        v_intersection.endCoord.y   := SELF.endCoord.y;
      Else
        v_intersection.StartCoord.id := -9;    -- Parallel
        v_intersection.startCoord.x  := NULL;
        v_intersection.startCoord.y  := NULL;
        v_intersection.midCoord.x    := NULL;
        v_intersection.midCoord.z    := NULL;
        v_intersection.endCoord.x    := NULL;
        v_intersection.endCoord.z    := NULL;
      End If;
      Return v_intersection;
    END IF;

    v_t1 := (     (SELF.startCoord.x - p_segment.startCoord.x) * v_dy2 + 
             (p_segment.startCoord.y -      SELF.startCoord.y) * v_dx2
            ) 
            / v_denominator;
             
    v_t2 := ( (p_segment.startCoord.x -       SELF.startCoord.x) * v_dY1 + 
                    (SELF.startCoord.y - p_segment.startCoord.y) * v_dx1
            ) / -v_denominator;

    -- Find the point of intersection.
    v_intersection.StartCoord.id := case when v_t1 < 0 and v_t2 < 0 then  0
                                         when v_t1 < 0              then -1
                                         when v_t2 < 0              then -2
                                         else 0
                                     end;  -- Mark if coord not on line
    v_intersection.startCoord.x  := SELF.startCoord.x + v_dx1 * v_t1;
    v_intersection.startCoord.y  := SELF.startCoord.y + v_dY1 * v_t1;

    -- DEBUG 
dbms_output.put_line('  intersection point= ' || v_intersection.startCoord.ST_Round(6).ST_AsText());

    -- Compute by ratio any z value
    If ( SELF.ST_Dims() = 3 and p_segment.ST_Dims() = 3 ) Then
       -- Note: we do the ratio via 2D length of segments not 3D.
       v_test_segment := &&INSTALL_SCHEMA..T_SEGMENT(
                          p_segment_id => 0,
                          p_startCoord => SELF.startCoord.ST_To2D(),
                          p_endCoord   => v_intersection.startCoord.ST_To2D(),
                          p_sdo_gtype  => 2002,
                          p_sdo_srid   => SELF.sdo_srid
                        );
       v_intersection.startCoord.z := SELF.startCoord.z + ( ( v_test_segment.ST_Length(p_tolerance,p_unit) / SELF.ST_To2D().ST_Length(p_tolerance,p_unit) ) * (SELF.endCoord.z-SELF.startCoord.z) );
       v_test_segment.startCoord   := p_segment.startCoord.ST_To2D();
       v_test_segment.endCoord     := v_intersection.startCoord.ST_To2D();
       v_intersection.endCoord.z   := p_segment.startCoord.z + ( ( v_test_segment.ST_Length(p_tolerance,p_unit) / p_segment.ST_To2D().ST_Length(p_tolerance,p_unit) ) * (p_segment.endCoord.z-p_segment.startCoord.z) );
      v_intersection.midCoord.z    := v_intersection.startCoord.z;
      IF ( round(v_intersection.endCoord.z,8) <> round(v_intersection.startCoord.z,8) ) Then
        v_intersection.startCoord.z := NULL;
      END IF;
    Else
      v_intersection.startCoord.z := SELF.startCoord.z;
      v_intersection.midCoord.z   := SELF.midCoord.z;
      v_intersection.endCoord.z   := p_segment.endCoord.z;
    End If;
    v_t1 := CASE WHEN v_t1 < 0 THEN 0 WHEN v_t1 > 1 THEN 1 ELSE v_t1 END;
    v_t2 := CASE WHEN v_t2 < 0 THEN 0 WHEN v_t2 > 1 THEN 1 ELSE v_t2 END;
    v_intersection.midCoord.id := -1;
    v_intersection.midCoord.x := SELF.startCoord.x     + v_dx1  * v_t1;
    v_intersection.midCoord.y := SELF.startCoord.y     + v_dY1  * v_t1;
    v_intersection.endCoord.id := -2;
    v_intersection.endCoord.x := p_segment.startCoord.x + v_dx2 * v_t2;
    v_intersection.endCoord.y := p_segment.startCoord.y + v_dy2 * v_t2;
dbms_output.put_line('</ST_IntersectDetail>');    
    Return v_intersection;
  END ST_IntersectDetail;

  Member Function ST_IntersectDescription(p_segment    in &&INSTALL_SCHEMA..T_SEGMENT,
                                          p_tolerance  in number   default 0.005,
                                          p_dPrecision in integer  default 6,
                                          p_unit       in varchar2 default null)
           Return varchar2
  AS
    v_dPrecision             PLS_Integer := NVL(p_dPrecision,6);
    v_intersection_point     &&INSTALL_SCHEMA..T_Vertex;
    v_intersection_point_1   &&INSTALL_SCHEMA..T_Vertex;
    v_intersection_point_2   &&INSTALL_SCHEMA..T_Vertex;
    v_intersection_points    &&INSTALL_SCHEMA..T_Segment;
    v_description            varchar2(10000);
    v_segment_1_description  varchar2(500);
    v_segment_2_description  varchar2(500);
    
    -- Point test short names
    INT_POINT_EQ_INT_POINT_1     pls_integer;
    INT_POINT_EQ_INT_POINT_2     pls_integer;
    INT_POINT_1_EQ_END_POINT_1   pls_integer;
    INT_POINT_1_EQ_START_POINT_1 pls_integer;
    INT_POINT_2_EQ_END_POINT_2   pls_integer;
    INT_POINT_2_EQ_START_POINT_2 pls_integer;
  BEGIN
dbms_output.put_line('<ST_IntersectDescription>');
    IF (p_segment is null) THEN
      Return 'NULL';
    END IF;

    -- Short Circuit: Check for common point at either end
    --
    IF ( SELF.StartCoord.ST_Equals(p_vertex => p_segment.startCoord, p_dPrecision=>v_dPrecision) = 1 ) THEN
      RETURN 'Intersection at Start Point 1 and Start Point 2';
    END IF;
    IF ( SELF.startCoord.ST_Equals(p_vertex => p_segment.EndCoord, p_dPrecision=>v_dPrecision) = 1 ) THEN
      RETURN 'Intersection at Start Point 1 and End Point 2';
    END IF;
    IF ( SELF.EndCoord.ST_Equals(p_vertex => p_segment.startCoord, p_dPrecision=>v_dPrecision) = 1 ) THEN
      RETURN 'Intersection at End Point 1 and Start Point 2';
    END IF;
    IF ( SELF.EndCoord.ST_Equals(p_vertex => p_segment.EndCoord, p_dPrecision=>v_dPrecision) = 1 ) THEN
      RETURN 'Intersection at End Point 1 and End Point 2';
    END IF;

    -- Intersection not at one of ends.
    -- Compute intersection.
    --
    v_intersection_points := SELF.ST_IntersectDetail(p_segment);
    -- Debug
dbms_output.put_line('  intersection point= ' || v_intersection_points.startCoord.ST_AsText());

    -- Easy case: parallel
    --
    IF ( v_intersection_points.startCoord.x = -9 ) THEN
      -- The lines are parallel.
      RETURN 'Parallel';
    END IF;

    v_intersection_point   := v_intersection_points.startCoord;
    v_intersection_point_1 := v_intersection_points.midCoord;
    v_intersection_point_2 := v_intersection_points.endCoord;

dbms_output.put_line('  Segment 1 Start Point: ' || SELF.startCoord.ST_AsText());
dbms_output.put_line('              End Point: ' || SELF.endCoord.ST_AsText());
dbms_output.put_line('  Segment 2 Start Point: ' || p_segment.startCoord.ST_AsText());
dbms_output.put_line('              End Point: ' || p_segment.endCoord.ST_AsText());
dbms_output.put_line('     Intersection Point: ' || v_intersection_point.ST_AsText());
dbms_output.put_line('             Point on 1: ' || v_intersection_point_1.ST_AsText());
dbms_output.put_line('             Point on 2: ' || v_intersection_point_2.ST_AsText());

    -- Set up test short hand variables
    INT_POINT_EQ_INT_POINT_1 := v_intersection_point.ST_Equals(p_vertex=>v_intersection_point_1,p_dPrecision=>p_dPrecision);
    INT_POINT_EQ_INT_POINT_2 := v_intersection_point.ST_Equals(p_vertex=>v_intersection_point_2,p_dPrecision=>p_dPrecision);
dbms_output.put_line('      INT_POINT_EQ_INT_POINT_1 = '||INT_POINT_EQ_INT_POINT_1 || '; INT_POINT_EQ_INT_POINT_2   = '||INT_POINT_EQ_INT_POINT_2);

    INT_POINT_1_EQ_START_POINT_1 := v_intersection_point_1.ST_Equals(p_vertex=>SELF.startCoord,p_dPrecision=>p_dPrecision);
    INT_POINT_1_EQ_END_POINT_1   := v_intersection_point_1.ST_Equals(p_vertex=>SELF.endCoord,  p_dPrecision=>p_dPrecision);
dbms_output.put_line('  INT_POINT_1_EQ_START_POINT_1 = '||INT_POINT_1_EQ_START_POINT_1 || '; INT_POINT_1_EQ_END_POINT_1 = '||INT_POINT_1_EQ_END_POINT_1);

    INT_POINT_2_EQ_START_POINT_2 := v_intersection_point_2.ST_Equals(p_vertex=>p_segment.startCoord,p_dPrecision=>p_dPrecision);
    INT_POINT_2_EQ_END_POINT_2   := v_intersection_point_2.ST_Equals(p_vertex=>p_segment.endCoord,  p_dPrecision=>p_dPrecision);
dbms_output.put_line('  INT_POINT_2_EQ_START_POINT_2 = '||INT_POINT_2_EQ_START_POINT_2 || '; INT_POINT_2_EQ_END_POINT_2 = '||INT_POINT_2_EQ_END_POINT_2);

    v_segment_1_description :=
              CASE WHEN v_intersection_point.ST_Equals(p_vertex=>SELF.startCoord,p_dPrecision=>p_dPrecision) = 1
                   THEN 'at Start Point 1'
                   WHEN v_intersection_point.ST_Equals(p_vertex=>SELF.endCoord,p_dPrecision=>p_dPrecision) = 1
                   THEN 'at End Point 1'
                   WHEN INT_POINT_EQ_INT_POINT_1=1
                   THEN 'Within 1'
                   ELSE ''
                END;

    v_segment_2_description :=
              CASE WHEN v_intersection_point.ST_Equals(p_vertex=>p_segment.startCoord,p_dPrecision=>p_dPrecision) = 1
                   THEN 'at Start Point 2'
                   WHEN v_intersection_point.ST_Equals(p_vertex=>p_segment.endCoord,p_dPrecision=>p_dPrecision) = 1
                   THEN 'at End Point 2'
                   WHEN INT_POINT_EQ_INT_POINT_2=1
                   THEN 'Within 2'
                   ELSE ''
                END;

dbms_output.put_line('  v_segment_1_description='||v_segment_1_description || '; v_segment_2_description='||v_segment_2_description);

    v_description :=
            CASE WHEN INT_POINT_EQ_INT_POINT_1 = 1 AND INT_POINT_EQ_INT_POINT_2 = 1
                      /* All three intersection points are the same */
                 THEN 'Intersection Within 1 and Within 2'

                 WHEN INT_POINT_EQ_INT_POINT_1 = 1 and INT_POINT_EQ_INT_POINT_2 = 0
                      /* Intersection point is within first segment but not second */
                 THEN 'Intersection '
                      ||
                      v_segment_1_description
                      ||
                      ' and Virtual Intersection '
                      ||
                      CASE WHEN INT_POINT_2_EQ_START_POINT_2 = 1
                           THEN 'Near Start Point 2'
                           WHEN INT_POINT_2_EQ_END_POINT_2 = 1
                           THEN 'Near End Point 2'
                           ELSE 'Outside 2'
                        END

                 WHEN INT_POINT_EQ_INT_POINT_1 = 0 AND INT_POINT_EQ_INT_POINT_2 = 1 
                      /* Intersection point is near second segment but not first */
                 THEN 'Virtual Intersection Near '
                      ||
                      CASE WHEN INT_POINT_1_EQ_START_POINT_1 = 1
                           THEN 'Start Point 1'
                           WHEN INT_POINT_1_EQ_END_POINT_1 = 1
                           THEN 'End Point 1'
                           ELSE 'Unknown'
                       END
                      ||
                      ' and '
                      ||
                      v_segment_2_description

                 WHEN INT_POINT_EQ_INT_POINT_1 = 0 AND INT_POINT_EQ_INT_POINT_2 = 0 
                 THEN 'Virtual Intersection Near '
                      ||
                      CASE WHEN INT_POINT_1_EQ_START_POINT_1 = 1 AND INT_POINT_2_EQ_START_POINT_2 = 1
                           THEN 'Start 1 and Near Start 2'
                           WHEN INT_POINT_1_EQ_END_POINT_1   = 1 AND INT_POINT_2_EQ_END_POINT_2   = 1
                           THEN 'End 1 and Near End 2'
                           WHEN INT_POINT_1_EQ_START_POINT_1 = 1 AND INT_POINT_2_EQ_END_POINT_2   = 1
                           THEN 'Start 1 and Near End 2'
                           WHEN INT_POINT_1_EQ_END_POINT_1   = 1 AND INT_POINT_2_EQ_START_POINT_2 = 1
                           THEN 'End 1 and Near Start 2'
                           ELSE 'Unknown'
                       END
                 ELSE 'Unknown'
             END;
dbms_output.put_line('  v_description='||v_description);
dbms_output.put_line('</ST_IntersectDescription>');
    Return v_description;
  END ST_IntersectDescription;

  Member Function ST_isReversed(p_other     in &&INSTALL_SCHEMA..T_Segment,
                                p_projected IN INTEGER)
           Return integer
  As
    v_self_bearing  number;
    v_other_bearing number;
  Begin
    -- Check reversal of direction as indication that a segment should be ignored.
    --
    v_self_bearing  := ROUND(SELF.ST_Bearing   (p_projected=>p_projected,p_normalize=>1),0);  ---- << WHY IS THIS ROUND(..,0) and NOT ROUND(...,8)? or no ROUND?
    v_other_bearing := ROUND(p_other.ST_Bearing(p_projected=>p_projected,p_normalize=>1),0);
    -- DEBUG dbms_output.put_line('Bearing (Self): ' || v_self_Bearing || ' (Other): ' || v_other_bearing || ' (Difference): ' || ABS(v_other_bearing - v_self_bearing));
    Return case when (ABS(v_other_bearing - v_self_bearing) = 180) then 1 else 0 end;
  End ST_isReversed;

  Member Function ST_LineSubstring(p_start_fraction In Number   Default 0.0,
                                   p_end_fraction   In Number   Default 1.0,
                                   p_tolerance      IN Number   Default 0.005,
                                   p_projected      In Integer  Default 1,
                                   p_unit           In Varchar2 Default NULL)
           Return &&INSTALL_SCHEMA..T_Segment
  As
    v_start_fraction Number := NVL(p_start_fraction,0.0);
    v_end_fraction   Number := NVL(p_end_fraction,1.0);
    v_temp_fraction  Number;
    v_length         Number;
    v_segment        &&INSTALL_SCHEMA..T_Segment;
  Begin
    IF ( v_start_fraction not between 0 and 1
      or v_end_fraction   not between 0 and 1 ) Then
      Return SELF;
    END IF;
    -- Ensure start <= end.
    v_temp_fraction := LEAST(   v_start_fraction,v_end_fraction);
    v_end_fraction  := GREATEST(v_start_fraction,v_end_fraction);
    v_start_fraction := v_temp_fraction;
    v_segment := new &&INSTALL_SCHEMA..T_Segment(
                       p_element_id    => 1,
                       p_subelement_id => 0,
                       p_segment_id    => 1,
                       p_startCoord    => NULL,
                       p_midCoord      => NULL,
                       p_endCoord      => NULL,
                       p_sdo_gtype     => SELF.sdo_gtype,
                       p_sdo_srid      => SELF.sdo_srid
                 );
    v_segment.startCoord := SELF.ST_OffsetPoint(
                     p_ratio     => v_start_fraction,
                     p_offset    => 0.0,
                     p_tolerance => p_tolerance,
                     p_unit      => p_unit,
                     p_projected => p_projected);
    IF ( v_start_fraction = v_end_fraction ) Then
      RETURN v_segment;
    End If;
    v_segment.endCoord := SELF.ST_OffsetPoint(
                           p_ratio     => v_end_fraction,
                           p_offset    => 0.0,
                           p_tolerance => p_tolerance,
                           p_unit      => p_unit,
                           p_projected => p_projected
                          );
    IF ( SELF.ST_IsCircularArc() = 1 ) THEN
      -- DEBUG dbms_output.put_line('midCoord: ' || TO_CHAR(v_start_fraction + ((v_end_fraction - v_start_fraction) / 2.0)));
      v_segment.midCoord := SELF.ST_OffsetPoint(
                              p_ratio     => v_start_fraction + ((v_end_fraction - v_start_fraction) / 2.0),
                              p_offset    => 0.0,
                              p_tolerance => p_tolerance,
                              p_unit      => p_unit,
                              p_projected => p_projected
                            );
    END IF;
    Return v_segment;
  End ST_LineSubstring;

  Member Function ST_UpdateCoordinate(p_coordinate in &&INSTALL_SCHEMA..T_Vertex,
                                      p_which      in varchar2 Default 'S' )
  Return &&INSTALL_SCHEMA..T_SEGMENT
  As
    v_which varchar2(1) := SUBSTR(UPPER(p_which),1,1);
    v_copy  &&INSTALL_SCHEMA..t_SEGMENT;
  Begin
    IF (  v_which not in ('S','M','E','1','2','3')
       OR p_coordinate is null or p_coordinate.ST_isEmpty()=1 ) Then
      Return SELF;
    End If;
    If (p_coordinate is null) Then
      Return SELF;
    ElsIf ( v_which IN ('S','1') ) Then
      v_copy            := &&INSTALL_SCHEMA..T_SEGMENT(SELF);
      v_copy.startCoord := &&INSTALL_SCHEMA..T_Vertex(p_coordinate);
      Return v_copy;
    ElsIf ( v_which IN ('M','2') ) Then
      v_copy          := &&INSTALL_SCHEMA..T_SEGMENT(SELF);
      v_copy.midCoord := &&INSTALL_SCHEMA..T_Vertex(p_coordinate);
      Return v_copy;
    ElsIf ( v_which IN ('E','3') ) Then
      v_copy          := &&INSTALL_SCHEMA..T_SEGMENT(SELF);
      v_copy.endCoord := &&INSTALL_SCHEMA..T_Vertex(p_coordinate);
      Return v_copy;
    Else
      Return SELF;
    End If;
  End ST_UpdateCoordinate;

  Member Function ST_Round(p_dec_places_x In integer Default 8,
                           p_dec_places_y In integer Default null,
                           p_dec_places_z In integer Default 3,
                           p_dec_places_m In integer Default 3)
  Return &&INSTALL_SCHEMA..T_SEGMENT Deterministic
  As
  Begin
    Return new &&INSTALL_SCHEMA..T_SEGMENT(
                 element_id    => SELF.element_id,
                 subelement_id => SELF.subelement_id,
                 segment_id    => SELF.segment_id,
                 startCoord    => case when SELF.startCoord is null
                                       then null
                                       else SELF.startCoord.ST_Round(p_dec_places_x,p_dec_places_y,p_dec_places_z,p_dec_places_m)
                                   end,
                 midCoord      => case when SELF.midCoord is null
                                       then null
                                       else SELF.midCoord.ST_Round(p_dec_places_x,p_dec_places_y,p_dec_places_z,p_dec_places_m)
                                   end,
                 endCoord      => case when SELF.endCoord is null
                                       then NULL
                                       else SELF.endCoord.ST_Round(p_dec_places_x,p_dec_places_y,p_dec_places_z,p_dec_places_m)
                                   end,
                 sdo_gtype     => SELF.SDO_GTYPE,
                 sdo_srid      => SELF.SDO_SRID
           );
  End ST_Round;

  Member Function ST_AsText(p_dec_places_x In integer Default 8,
                            p_dec_places_y In integer Default null,
                            p_dec_places_z In integer Default 3,
                            p_dec_places_m In integer Default 3)
  Return VARCHAR2
  AS
    v_segment &&INSTALL_SCHEMA..T_Segment;
  BEGIN
    v_segment := SELF.ST_Round(
                   p_dec_places_x => p_dec_places_x,
                   p_dec_places_y => p_dec_places_y,
                   p_dec_places_z => p_dec_places_z,
                   p_dec_places_m => p_dec_places_m
                 );
    Return 'T_SEGMENT(' ||
              'p_element_id=>'    || NVL(TO_CHAR(SELF.element_id),    'NULL') || ',' ||
              'p_subelement_id=>' || NVL(TO_CHAR(SELF.subelement_id), 'NULL') || ',' ||
              'p_segment_id=>'    || NVL(TO_CHAR(SELF.segment_id),    'NULL') || ',' ||
              'p_startCoord=>'    || CASE WHEN v_segment.startCoord IS NULL THEN 'NULL' ELSE v_segment.startCoord.ST_AsText() END || ',' || 
              'p_midCoord=>'      || CASE WHEN v_segment.midCoord   IS NULL THEN 'NULL' ELSE v_segment.midCoord.ST_AsText()   END || ',' || 
              'p_endCoord=>'      || CASE WHEN v_segment.endCoord   IS NULL THEN 'NULL' ELSE v_segment.endCoord.ST_AsText()   END || ',' || 
              'p_sdo_gtype=>'     || NVL(TO_CHAR(SELF.SDO_GTYPE),     'NULL') || ','||
              'p_sdo_srid=>'      || NVL(TO_CHAR(SELF.SDO_SRID),      'NULL') || ')';
  END ST_AsText;

  /* NOTE: p_dims can also be a full sdo_gtype */
  Member Function ST_SdoGeometry(p_dims in integer Default null)
  Return mdsys.sdo_geometry
  AS
    v_ordinates  mdsys.sdo_ordinate_array;
    v_ord        pls_integer;
    v_dims       pls_integer := case when p_dims is null then SELF.ST_Dims() else p_dims end;
  BEGIN
    v_ordinates := mdsys.sdo_ordinate_array();
    IF ( SELF.startCoord IS NOT NULL ) THEN
      IF ( SELF.startCoord.ST_isEmpty() = 0 ) THEN
        v_ord := v_ordinates.COUNT+1;
        v_ordinates.EXTEND(v_dims);
        v_ordinates(v_ord  ) := SELF.startCoord.X;
        v_ordinates(v_ord+1) := SELF.startCoord.Y;
        IF (v_dims>2) THEN
          v_ordinates(v_ord+2) := SELF.startCoord.Z;
          IF ( v_dims>3 ) THEN
            v_ordinates(v_ord+2) := SELF.startCoord.W;
          END IF;
        END IF;
      END IF;
    END IF;
    IF ( SELF.midCoord IS NOT NULL ) THEN
      IF ( SELF.midCoord.ST_isEmpty() = 0 ) THEN
        v_ord := v_ordinates.COUNT+1;
        v_ordinates.EXTEND(v_dims);
        v_ordinates(v_ord  ) := SELF.midCoord.X;
        v_ordinates(v_ord+1) := SELF.midCoord.Y;
        IF (v_dims>2) THEN
          v_ordinates(v_ord+2) := SELF.midCoord.Z;
          IF ( v_dims>3 ) THEN
            v_ordinates(v_ord+2) := SELF.midCoord.W;
          END IF;
        END IF;
      END IF;
    END IF;
    IF ( SELF.endCoord IS NOT NULL ) THEN
      IF ( SELF.endCoord.ST_isEmpty() = 0 ) THEN
        v_ord := v_ordinates.COUNT+1;
        v_ordinates.EXTEND(v_dims);
        v_ordinates(v_ord  ) := SELF.endCoord.X;
        v_ordinates(v_ord+1) := SELF.endCoord.Y;
        IF (v_dims>2) THEN
          v_ordinates(v_ord+2) := SELF.endCoord.Z;
          IF ( v_dims>3 ) THEN
            v_ordinates(v_ord+2) := SELF.endCoord.W;
          END IF;
        END IF;
      END IF;
    END IF;
    Return mdsys.sdo_geometry(
             v_dims * 1000 + 
             case when v_ordinates.COUNT = v_dims then 1 else 2 end +
             CASE WHEN v_dims = 2 THEN 0
                  WHEN v_dims = 3 AND SELF.ST_lrs_dim()in(0,3) THEN SELF.ST_Lrs_Dim()
                  WHEN v_dims = 4 THEN SELF.ST_Lrs_Dim()
                  ELSE 0
              END * 100,
             SELF.SDO_SRID,
             NULL,
             CASE WHEN v_ordinates.COUNT / v_dims = 2 
                  THEN mdsys.sdo_elem_info_array(1,2,1)
                  ELSE mdsys.sdo_elem_info_array(1,2,2)
              END,
             v_ordinates
           );
  END ST_SdoGeometry;

  Member Function ST_Equals(p_segment    In &&INSTALL_SCHEMA..T_Segment,
                            p_dPrecision In Integer default 8,
                            p_coords     In Integer default 1)
  Return NUMBER
  IS
    c_Min CONSTANT NUMBER      := -1E38;
    v_precision    pls_integer := NVL(p_dPrecision,8);
  BEGIN
    IF (p_segment IS NULL) THEN
      Return 0; /* False */
    END IF;
    IF ( NVL(p_coords,1)=1 ) THEN
      IF ( SELF.startCoord.ST_Equals(p_segment.startCoord,v_precision) = 1
       AND SELF.endCoord.ST_Equals  (p_segment.endCoord,  v_precision) = 1
       AND ( ( SELF.midCoord IS NOT NULL
           AND p_segment.midCoord IS NOT NULL
           AND SELF.midCoord.ST_Equals(p_segment.midCoord,v_precision) = 1 )
          OR ( SELF.midCoord IS NULL
           AND p_segment.midCoord IS NULL ) ) ) THEN
        Return 1; /* True */
      ELSE
        Return 0; /* False */
      END IF;
    ELSE
      IF ( NVL(SELF.element_id,   c_Min) = NVL(p_segment.element_id,   c_Min) AND
           NVL(SELF.subelement_id,c_Min) = NVL(p_segment.subelement_id,c_Min) AND
           NVL(SELF.segment_id,   c_Min) = NVL(p_segment.segment_id,   c_Min) AND
           SELF.startCoord.ST_Equals(p_segment.startCoord,v_precision) = 1    AND
           SELF.endCoord.ST_Equals(p_segment.endCoord,v_precision)     = 1    AND
           ( ( SELF.midCoord IS NOT NULL
               AND p_segment.midCoord IS NOT NULL
               AND SELF.midCoord.ST_Equals(p_segment.midCoord,v_precision) = 1
              ) OR
              ( SELF.midCoord IS NULL AND p_segment.midCoord IS NULL ) ) ) THEN
        Return 1; /* True */
      ELSE
        Return 0; /* False */
      END IF;
    END IF;
  END ST_Equals;

  Order Member Function orderBy(p_segment IN &&INSTALL_SCHEMA..T_SEGMENT)
    Return NUMBER
  IS
    c_Min CONSTANT NUMBER := -1E38;
  BEGIN
    IF (SELF.segment_id IS NULL) THEN
      Return -1;
    ElsIf (p_segment IS NULL) THEN
      Return 1;
    END IF;
    IF    NVL(SELF.element_id,   c_Min) < NVL(p_segment.element_id,   c_Min) THEN Return -1;
    ElsIf NVL(SELF.element_id,   c_Min) > NVL(p_segment.element_id,   c_Min) THEN Return  1;
    ElsIf NVL(SELF.subelement_id,c_Min) < NVL(p_segment.subelement_id,c_Min) THEN Return -1;
    ElsIf NVL(SELF.subelement_id,c_Min) > NVL(p_segment.subelement_id,c_Min) THEN Return  1;
    ElsIf NVL(SELF.segment_Id,   c_Min) < NVL(p_segment.segment_Id,   c_Min) THEN Return -1;
    ElsIf NVL(SELF.segment_Id,   c_Min) > NVL(p_segment.segment_Id,   c_Min) THEN Return  1;
    ELSE Return 0;
    END IF;
  END orderBy;

END;
/
SHOW ERRORS

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := FALSE;
   v_obj_name varchar2(30) := 'T_SEGMENT';
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

