DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

CREATE OR REPLACE EDITIONABLE TYPE BODY "&&INSTALL_SCHEMA."."T_SEGMENT" 
AS

  Constructor Function T_Segment(SELF IN OUT NOCOPY T_Segment)
                Return Self AS Result
  AS
  BEGIN
    SELF.element_id     := NULL;
    SELF.subelement_id  := NULL;
    SELF.segment_id     := NULL;
    SELF.startCoord     := NULL;
    SELF.midCoord       := NULL;
    SELF.endCoord       := NULL;
    SELF.SDO_GTYPE      := NULL;
    SELF.SDO_SRID       := NULL;
    SELF.projected      := NULL;
    SELF.PrecisionModel := NULL;
    Return;
  END T_Segment;

  Constructor Function T_Segment(SELF      IN OUT NOCOPY T_Segment,
                                 p_segment IN &&INSTALL_SCHEMA..T_Segment)
                Return Self AS Result
  AS
  BEGIN
    IF ( p_segment        IS NULL ) THEN
      SELF.element_id     := NULL;
      SELF.subelement_id  := NULL;
      SELF.segment_id     := NULL;
      SELF.startCoord     := &&INSTALL_SCHEMA..T_Vertex();
      SELF.midCoord       := NULL;
      SELF.ENDCOORD       := &&INSTALL_SCHEMA..T_Vertex();
      SELF.sdo_gtype      := 2002;
      SELF.sdo_srid       := NULL;
      SELF.projected      := 1;
      SELF.PrecisionModel := &&INSTALL_SCHEMA..T_PrecisionModel(8,3,3,0.005);
    ELSE
      SELF.element_id     := p_segment.element_id;
      SELF.subelement_id  := p_segment.subelement_id;
      SELF.segment_id     := p_segment.segment_id;
      SELF.startCoord     := &&INSTALL_SCHEMA..T_Vertex(p_segment.startCoord);
      SELF.midCoord       := CASE WHEN p_segment.midCoord IS NOT NULL THEN &&INSTALL_SCHEMA..T_Vertex(p_segment.midCoord) ELSE NULL END;
      SELF.endCoord       := &&INSTALL_SCHEMA..T_Vertex(p_segment.endCoord);
      SELF.sdo_gtype      := TRUNC(NVL(p_segment.sdo_gtype,2002)/10)*10+2; -- Cannot be other than a line.
      SELF.sdo_srid       := p_segment.sdo_srid;
      SELF.projected      := NVL(p_segment.projected,1);
      SELF.PrecisionModel := case when p_segment.PrecisionModel is null then &&INSTALL_SCHEMA..T_PrecisionModel(8,3,3,0.005) else p_segment.PrecisionModel end;
    END IF;
    IF ( SELF.ST_isCircularArc()=1 and SELF.ST_hasZ()=1 ) Then
      if ( SELF.ST_CheckZ = 0 ) then
        raise_application_error(-20214,'Circular arc segments with Z values must have equal Z value for all 3 points.');
      end If;
    end If;
    Return;
  END;

  Constructor Function T_Segment(SELF         IN OUT NOCOPY T_Segment,
                                 p_line       in mdsys.sdo_geometry,
                                 p_segment_id in integer default 0,
                                 p_precision  in integer default 3,
                                 p_tolerance  in number  default 0.005)
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
    SELF.startCoord := &&INSTALL_SCHEMA..T_Vertex(
                         p_vertex    => v_vertices(1),
                         p_sdo_gtype => TRUNC(NVL(p_line.sdo_gtype,2002)/10)*10+1,
                         p_sdo_srid  => p_line.sdo_srid
                       );
    v_isCircularArc := case when p_line.sdo_elem_info.COUNT = 3 then p_line.sdo_elem_info(3) = 2 else false end;
    if ( v_isCircularArc ) Then
      SELF.midCoord := &&INSTALL_SCHEMA..T_Vertex(
                         p_vertex    => v_vertices(2),
                         p_sdo_gtype => TRUNC(NVL(p_line.sdo_gtype,2002)/10)*10+1,
                         p_sdo_srid  => p_line.sdo_srid);
    End If;
    If (v_vertices.COUNT > 1) Then
      SELF.endCoord := &&INSTALL_SCHEMA..T_Vertex(
                         p_vertex    => v_vertices(case when v_isCircularArc then 3 else 2 end),
                         p_sdo_gtype => TRUNC(NVL(p_line.sdo_gtype,2002)/10)*10+1,
                         p_sdo_srid  => p_line.sdo_srid
                       );
    End If;
    SELF.sdo_gtype      := TRUNC(NVL(p_line.sdo_gtype,2002)/10)*10+2; -- Cannot be other than a line.
    SELF.sdo_srid       := p_line.sdo_srid;
    SELF.projected      := case when SELF.sdo_srid is null then 1 else &&INSTALL_SCHEMA..t_segment.ST_GetProjected(SELF.sdo_srid) end;
    SELF.PrecisionModel := &&INSTALL_SCHEMA..T_PrecisionModel(NVL(p_precision,8),3,3,NVL(p_tolerance,0.005));
    IF ( SELF.ST_isCircularArc()=1 and SELF.ST_hasZ()=1 ) Then
      if ( SELF.ST_CheckZ = 0 ) then
        raise_application_error(-20214,'Circular arc segments with Z values must have equal Z value for all 3 points.');
      end If;
    end If;
    Return;
  End;

  Constructor Function T_SEGMENT(SELF        IN OUT NOCOPY T_SEGMENT,
                                 p_sdo_gtype In Integer,
                                 p_sdo_srid  In Integer,
                                 p_projected in integer default 1,
                                 p_precision in integer default 3,
                                 p_tolerance in number  default 0.005)
                Return Self As Result
  As
  Begin
    SELF.element_id     := NULL;
    SELF.subelement_id  := NULL;
    SELF.segment_id     := NULL;
    SELF.startCoord     := NULL;
    SELF.midCoord       := NULL;
    SELF.endCoord       := NULL;
    SELF.sdo_gtype      := p_sdo_gtype;
    SELF.sdo_srid       := p_sdo_srid;
    SELF.projected      := case when NVL(p_projected,-1) = -1 
                                then case when SELF.sdo_srid is null 
                                          then 1 
                                          else t_segment.ST_GetProjected(SELF.sdo_srid) 
                                      end
                                else p_projected
                            end;
    SELF.PrecisionModel := &&INSTALL_SCHEMA..T_PrecisionModel(NVL(p_precision,8),3,3,NVL(p_tolerance,0.005));
    Return;
  End;

  Constructor Function T_Segment(SELF          IN OUT NOCOPY T_Segment,
                                 p_segment_id  In Integer,
                                 p_startCoord  IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_endCoord    IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_sdo_gtype   In Integer Default NULL,
                                 p_sdo_srid    In Integer Default NULL,
                                 p_projected   in integer default 1,
                                 p_precision   in integer default 3,
                                 p_tolerance   in number  default 0.005)
  Return Self AS Result
  AS
  BEGIN
    SELF.segment_id     := p_segment_id;
    SELF.startCoord     := p_startCoord;
    SELF.midCoord       := NULL;
    SELF.endCoord       := p_endCoord;
    SELF.sdo_gtype      := TRUNC(NVL(p_sdo_gtype,2002)/10)*10+2; -- Cannot be other than a line.
    SELF.sdo_srid       := p_sdo_srid;
    SELF.projected      := case when NVL(p_projected,-1) = -1 
                                then case when SELF.sdo_srid is null 
                                          then 1 
                                          else t_segment.ST_GetProjected(SELF.sdo_srid) 
                                      end
                                else p_projected
                            end;
    SELF.PrecisionModel := &&INSTALL_SCHEMA..T_PrecisionModel(NVL(p_precision,8),3,3,NVL(p_tolerance,0.005));
    Return;
  END T_Segment;

  Constructor Function T_Segment(SELF    IN OUT NOCOPY T_Segment,
                                 p_segment_id In Integer,
                                 p_startCoord IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_midCoord   IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_endCoord   IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_sdo_gtype  In Integer Default NULL,
                                 p_sdo_srid   In Integer Default NULL,
                                 p_projected  in integer default 1,
                                 p_precision  in integer default 3,
                                 p_tolerance  in number  default 0.005)
  Return Self AS Result
  AS
  BEGIN
    SELF.segment_id     := p_segment_id;
    SELF.startCoord     := p_startCoord;
    SELF.midCoord       := p_midCoord;
    SELF.endCoord       := p_endCoord;
    SELF.sdo_gtype      := TRUNC(NVL(p_sdo_gtype,2002)/10)*10+2; -- Cannot be other than a line.
    SELF.sdo_srid       := p_sdo_srid;
    SELF.projected      := case when NVL(p_projected,-1) = -1 
                                then case when SELF.sdo_srid is null 
                                          then 1 
                                          else t_segment.ST_GetProjected(SELF.sdo_srid) 
                                      end
                                else p_projected
                            end;
    SELF.PrecisionModel := &&INSTALL_SCHEMA..T_PrecisionModel(NVL(p_precision,8),3,3,NVL(p_tolerance,0.005));
    IF ( SELF.ST_isCircularArc()=1 and SELF.ST_hasZ()=1 ) Then
      if ( SELF.ST_CheckZ = 0 ) then
        raise_application_error(-20214,'Circular arc segments with Z values must have equal Z value for all 3 points.');
      end If;
    end If;
    Return;
  END T_Segment;

  Constructor Function T_Segment(SELF         IN OUT NOCOPY T_Segment,
                                 p_segment_id In Integer,
                                 p_startCoord IN mdsys.vertex_type,
                                 p_endCoord   IN mdsys.vertex_type,
                                 p_sdo_gtype  In Integer Default NULL,
                                 p_sdo_srid   In Integer Default NULL,
                                 p_projected  in integer default 1,
                                 p_precision  in integer default 3,
                                 p_tolerance  in number  default 0.005)
  Return Self AS Result
  AS
  BEGIN
    SELF.segment_id := p_segment_id;
    SELF.startCoord := &&INSTALL_SCHEMA..T_Vertex(
                         p_vertex    => p_startCoord,
                         p_sdo_gtype => TRUNC(NVL(p_sdo_gtype,2002)/10)*10+1,
                         p_sdo_srid  => p_sdo_srid);
    SELF.midCoord   := NULL;
    SELF.endCoord   := &&INSTALL_SCHEMA..T_Vertex(
                         p_vertex    => p_endCoord,
                         p_sdo_gtype => TRUNC(NVL(p_sdo_gtype,2002)/10)*10+1,
                         p_sdo_srid  => p_sdo_srid);
    SELF.sdo_gtype      := TRUNC(NVL(p_sdo_gtype,2002)/10)*10+2; -- Cannot be other than a line.
    SELF.sdo_srid       := p_sdo_srid;
    SELF.projected      := case when NVL(p_projected,-1) = -1 
                                then case when SELF.sdo_srid is null 
                                          then 1 
                                          else t_segment.ST_GetProjected(SELF.sdo_srid) 
                                      end
                                else p_projected
                            end;
    SELF.PrecisionModel := &&INSTALL_SCHEMA..T_PrecisionModel(NVL(p_precision,8),3,3,NVL(p_tolerance,0.005));
    Return;
  END T_Segment;

  Constructor Function T_Segment(SELF         IN OUT NOCOPY T_Segment,
                                 p_segment_id In Integer,
                                 p_startCoord IN mdsys.vertex_type,
                                 p_midCoord   IN mdsys.vertex_type,
                                 p_endCoord   IN mdsys.vertex_type,
                                 p_sdo_gtype  In Integer Default NULL,
                                 p_sdo_srid   In Integer Default NULL,
                                 p_projected  in integer default 1,
                                 p_precision  in integer default 3,
                                 p_tolerance  in number  default 0.005)
  Return Self AS Result
  AS
  BEGIN
    SELF.segment_id := p_segment_id;
    SELF.startCoord := &&INSTALL_SCHEMA..T_Vertex(
                         p_vertex    => p_startCoord,
                         p_sdo_gtype => TRUNC(NVL(p_sdo_gtype,2002)/10)*10+1,
                         p_sdo_srid  => p_sdo_srid);
    SELF.midCoord   := &&INSTALL_SCHEMA..T_Vertex(
                         p_vertex    => p_midCoord,
                         p_sdo_gtype => TRUNC(NVL(p_sdo_gtype,2002)/10)*10+1,
                         p_sdo_srid  => p_sdo_srid);
    SELF.endCoord   := &&INSTALL_SCHEMA..T_Vertex(
                         p_vertex    => p_endCoord,
                         p_sdo_gtype => TRUNC(NVL(p_sdo_gtype,2002)/10)*10+1,
                         p_sdo_srid  => p_sdo_srid);
    SELF.sdo_gtype      := TRUNC(NVL(p_sdo_gtype,2002)/10)*10+2; -- Cannot be other than a line.
    SELF.sdo_srid       := p_sdo_srid;
    SELF.projected      := case when NVL(p_projected,-1) = -1 
                                then case when SELF.sdo_srid is null 
                                          then 1 
                                          else t_segment.ST_GetProjected(SELF.sdo_srid) 
                                      end
                                else p_projected
                            end;
    SELF.PrecisionModel := &&INSTALL_SCHEMA..T_PrecisionModel(NVL(p_precision,8),3,3,NVL(p_tolerance,0.005));
    IF ( SELF.ST_isCircularArc()=1 and SELF.ST_hasZ()=1 ) Then
      if ( SELF.ST_CheckZ = 0 ) then
        raise_application_error(-20214,'Circular arc segments with Z values must have equal Z value for all 3 points.');
      end If;
    end If;
    Return;
  END T_Segment;

  Constructor Function T_Segment(SELF            In OUT NOCOPY T_Segment,
                                 p_element_id    In Integer,
                                 p_subelement_id In Integer,
                                 p_segment_id    In Integer,
                                 p_startCoord    IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_endCoord      IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_sdo_gtype     In Integer Default NULL,
                                 p_sdo_srid   In Integer Default NULL,
                                 p_projected  in integer default 1,
                                 p_precision  in integer default 3,
                                 p_tolerance  in number  default 0.005)
  Return Self AS Result
  AS
  BEGIN
    SELF.element_id     := p_element_id;
    SELF.subelement_id  := p_subelement_id;
    SELF.segment_id     := p_segment_id;
    SELF.startCoord     := p_startCoord;
    SELF.midCoord       := NULL;
    SELF.endCoord       := p_endCoord;
    SELF.sdo_gtype      := TRUNC(NVL(p_sdo_gtype,2002)/10)*10+2; -- Cannot be other than a line.
    SELF.sdo_srid       := p_sdo_srid;
    SELF.projected      := case when NVL(p_projected,-1) = -1 
                                then case when SELF.sdo_srid is null 
                                          then 1 
                                          else t_segment.ST_GetProjected(SELF.sdo_srid) 
                                      end
                                else p_projected
                            end;
    SELF.PrecisionModel := &&INSTALL_SCHEMA..T_PrecisionModel(NVL(p_precision,8),3,3,NVL(p_tolerance,0.005));
    Return;
  END T_Segment;

  Constructor Function T_Segment(SELF            In OUT NOCOPY T_Segment,
                                 p_element_id    In Integer,
                                 p_subelement_id In Integer,
                                 p_segment_id    In Integer,
                                 p_startCoord    IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_midCoord      IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_endCoord      IN &&INSTALL_SCHEMA..T_Vertex,
                                 p_sdo_gtype     In Integer Default NULL,
                                 p_sdo_srid   In Integer Default NULL,
                                 p_projected  in integer default 1,
                                 p_precision  in integer default 3,
                                 p_tolerance  in number  default 0.005)
  Return Self AS Result
  AS
  BEGIN
    SELF.element_id     := p_element_id;
    SELF.subelement_id  := p_subelement_id;
    SELF.segment_id     := p_segment_id;
    SELF.startCoord     := p_startCoord;
    SELF.midCoord       := p_midCoord;
    SELF.endCoord       := p_endCoord;
    SELF.sdo_gtype      := TRUNC(NVL(p_sdo_gtype,2002)/10)*10+2; -- Cannot be other than a line.
    SELF.sdo_srid       := p_sdo_srid;
    SELF.projected      := case when NVL(p_projected,-1) = -1 
                                then case when SELF.sdo_srid is null 
                                          then 1 
                                          else t_segment.ST_GetProjected(SELF.sdo_srid) 
                                      end
                                else p_projected
                            end;
    SELF.PrecisionModel := &&INSTALL_SCHEMA..T_PrecisionModel(NVL(p_precision,8),3,3,NVL(p_tolerance,0.005));
    IF ( SELF.ST_isCircularArc()=1 and SELF.ST_hasZ()=1 ) Then
      if ( SELF.ST_CheckZ = 0 ) then
        raise_application_error(-20214,'Circular arc segments with Z values must have equal Z value for all 3 points.');
      end If;
    end If;
    Return;
  END T_Segment;

  /* ================= Methods ================= */

  Static Function ST_GetProjected(p_srid in integer default null)
           Return integer
  As
    c_i_invalid_srid CONSTANT INTEGER       := -20120;
    c_s_invalid_srid CONSTANT VARCHAR2(100) := 'p_srid (*SRID*) must exist in mdsys.cs_srs';
    v_srid_type      varchar2(25);
  BEGIN
     IF (p_SRID is null) Then
        RETURN 1;
     End If;
     BEGIN
        SELECT SUBSTR(DECODE(crs.coord_ref_sys_kind,
                            'COMPOUND',    'PLANAR',
                            'ENGINEERING', 'PLANAR',
                            'PROJECTED',   'PLANAR',
                            'GEOCENTRIC',  'GEOGRAPHIC',
                            'GEOGENTRIC',  'GEOGRAPHIC',
                            'GEOGRAPHIC2D','GEOGRAPHIC',
                            'GEOGRAPHIC3D','GEOGRAPHIC',
                            'VERTICAL',    'GEOGRAPHIC',
                            'PLANAR'),1,20) as unit_of_measure
           into v_srid_type
          from mdsys.sdo_coord_ref_system crs
         where crs.srid = p_SRID;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          raise_application_error(c_i_invalid_srid,
                                  REPLACE(c_s_invalid_srid,'*SRID*',p_SRID));
     END;
     RETURN case when v_srid_type = 'PLANAR' then 1 else 0 end;
  END ST_GetProjected;

  Member Procedure ST_SetPrecisionModel(SELF IN OUT NOCOPY T_SEGMENT,
                                        p_PrecisionModel in &&INSTALL_SCHEMA..T_PrecisionModel)
  As
  Begin
    if (p_PrecisionModel is null) Then
      return;
    end if;    
    if (SELF.PrecisionModel is null) Then
      SELF.PrecisionModel := &&INSTALL_SCHEMA..T_PrecisionModel(
                          xy         => p_PrecisionModel.xy,
                           z         => p_PrecisionModel.z,
                           w         => p_PrecisionModel.w,
                           tolerance => 0.005
                        );
    else
      SELF.PrecisionModel := &&INSTALL_SCHEMA..T_PrecisionModel(
                                 xy => case when p_PrecisionModel.xy        is null then SELF.PrecisionModel.xy         else p_PrecisionModel.xy        end,
                                  z => case when p_PrecisionModel.z         is null then SELF.PrecisionModel.z          else p_PrecisionModel.z         end,
                                  w => case when p_PrecisionModel.w         is null then SELF.PrecisionModel.w          else p_PrecisionModel.w         end,
                          tolerance => case when p_PrecisionModel.tolerance is null then SELF.PrecisionModel.tolerance  else p_PrecisionModel.tolerance end
                        );
    end if;
  End ST_SetPrecisionModel;

  Member Function ST_CheckZ
           return integer 
  As
  Begin
    -- Is Circular Arc?
    IF ( SELF.ST_isCircularArc()=0 ) Then
      return 1;
    End If;
    -- Check Z is the same on all three coordinates
    IF ( (SELF.ST_Dims()=3 and ST_Lrs_Dim()=0)
      or (SELF.ST_Dims()=4 and ST_Lrs_Dim()=4) ) Then
      -- Check Z 
      Return case when SELF.startCoord.z = SELF.midCoord.Z and SELF.startCoord.z = SELF.endCoord.Z then 1 else 0 end;
    End If;
    Return 1;
  End ST_CheckZ;

  Member Function ST_MBR
           return mdsys.sdo_geometry 
  As
  Begin
    return mdsys.sdo_geometry(
                     2003,
                     SELF.sdo_srid,
                     NULL,
                     mdsys.sdo_elem_info_array(1,1003,3),
                     mdsys.sdo_ordinate_array(
                            SELF.ST_MinX,SELF.ST_MinY,
                            SELF.ST_MaxX,SELF.ST_MaxY
                     )
           );
  End ST_MBR;

  Member Function ST_MinX
           return Number 
  As
  Begin
    return case when SELF.midCoord is not null 
                then LEAST(SELF.startCoord.x, SELF.midCoord.x, SELF.endCoord.x)
                else LEAST(SELF.startCoord.x,                  SELF.endCoord.x)
            end;
  End ST_MinX;

  Member Function ST_MaxX
           return Number 
  As
  Begin
    return case when SELF.midCoord is not null 
                then GREATEST(SELF.startCoord.x, SELF.midCoord.x, SELF.endCoord.x)
                else GREATEST(SELF.startCoord.x,                  SELF.endCoord.x)
            end;

  End ST_MaxX;

  Member Function ST_MinY 
           return Number 
  As
  Begin
    return case when SELF.midCoord is not null 
                then LEAST(SELF.startCoord.y, SELF.midCoord.y, SELF.endCoord.y)
                else LEAST(SELF.startCoord.y,                  SELF.endCoord.y)
            end;
  End ST_MinY;

  Member Function ST_MaxY 
           return Number 
  As
  Begin
    return case when SELF.midCoord is not null 
                then GREATEST(SELF.startCoord.y, SELF.midCoord.y, SELF.endCoord.y)
                else GREATEST(SELF.startCoord.y,                  SELF.endCoord.y)
            end;
  End ST_MaxY;

  Member Function ST_isHorizontal
           return integer 
  As
  Begin
    return case when SELF.startCoord.y = SELF.endCoord.y then 1 else 0 end;
  End ST_isHorizontal;

  Member Function ST_isVertical
           return integer 
  As
  Begin
    return case when SELF.startCoord.x = SELF.endCoord.x then 1 else 0 end;
  End ST_isVertical;

  Member Function ST_MidPoint
           Return &&INSTALL_SCHEMA..T_Vertex 
  As
  Begin
    return new &&INSTALL_SCHEMA..T_Vertex( p_x => (SELF.startCoord.x + SELF.endCoord.x) / 2.0,
                               p_y => (SELF.startCoord.y + SELF.endCoord.y) / 2.0,
                               p_z => (SELF.startCoord.z + SELF.endCoord.z) / 2.0,
                               p_w => (SELF.startCoord.w + SELF.endCoord.w) / 2.0,
                               p_id => 1,
                               p_sdo_gtype => SELF.startCoord.sdo_gtype,
                               p_sdo_srid  => SELF.startCoord.sdo_srid);
  End ST_MidPoint;

  Member Procedure ST_SetCoordinates(SELF         IN OUT NOCOPY T_Segment,
                                     p_startCoord in &&INSTALL_SCHEMA..T_Vertex,
                                     p_midCoord   in &&INSTALL_SCHEMA..T_Vertex,
                                     p_endCoord   in &&INSTALL_SCHEMA..T_Vertex
                                     )
  As
  BEGIN
     SELF.startCoord := p_startCoord;
     SELF.midCoord   := p_midCoord;
     SELF.endCoord   := p_endCoord;
  END ST_SetCoordinates;

  Member Procedure ST_SetCoordinates(SELF         IN OUT NOCOPY T_Segment,
                                     p_startCoord in &&INSTALL_SCHEMA..T_Vertex,
                                     p_endCoord   in &&INSTALL_SCHEMA..T_Vertex
                                     )
  As
  BEGIN
     SELF.startCoord := p_startCoord;
     SELF.endCoord   := p_endCoord;
  END ST_SetCoordinates;

  Member Function ST_UpdateCoordinate(p_coordinate in &&INSTALL_SCHEMA..T_Vertex,
                                      p_which      in varchar2 Default 'S' )
  Return &&INSTALL_SCHEMA..T_Segment
  As
    v_which varchar2(1) := SUBSTR(UPPER(p_which),1,1);
    v_copy  &&INSTALL_SCHEMA..T_Segment;
  Begin
    IF (  v_which not in ('S','M','E','1','2','3')
       OR p_coordinate is null or p_coordinate.ST_isEmpty()=1 ) Then
      Return SELF;
    End If;
    If (p_coordinate is null) Then
      Return SELF;
    ElsIf ( v_which IN ('S','1') ) Then
      v_copy            := &&INSTALL_SCHEMA..T_Segment(SELF);
      v_copy.startCoord := &&INSTALL_SCHEMA..T_Vertex(p_coordinate);
      Return v_copy;
    ElsIf ( v_which IN ('M','2') ) Then
      v_copy          := &&INSTALL_SCHEMA..T_Segment(SELF);
      v_copy.midCoord := &&INSTALL_SCHEMA..T_Vertex(p_coordinate);

      Return v_copy;
    ElsIf ( v_which IN ('E','3') ) Then
      v_copy          := &&INSTALL_SCHEMA..T_Segment(SELF);
      v_copy.endCoord := &&INSTALL_SCHEMA..T_Vertex(p_coordinate);
      Return v_copy;
    Else
      Return SELF;
    End If;
  End ST_UpdateCoordinate;

  Member Function ST_Self
           Return &&INSTALL_SCHEMA..T_Segment
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
    Return integer 
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

  Member Function ST_hasZ
  Return integer
  As
  Begin
    Return CASE WHEN ( ( SELF.ST_Dims() = 3 AND SELF.ST_LRS_Dim()=0 /* is XYZ object */ )
                      OR SELF.ST_Dims() = 4 AND SELF.ST_LRS_Dim()=4 /* is XYZM */ )
                THEN 1
                ELSE 0
            END;
  end ST_hasZ;

  Member Function ST_To2D
  Return &&INSTALL_SCHEMA..T_Segment
  AS
  BEGIN
    RETURN CASE WHEN SELF.ST_DIMS()=2
                THEN &&INSTALL_SCHEMA..T_Segment(SELF)
                ELSE &&INSTALL_SCHEMA..T_Segment(p_element_id  => SELF.element_id,
                                   p_subelement_id => SELF.element_id,
                                   p_segment_id    => SELF.segment_id,
                                   p_startCoord    => SELF.startCoord.ST_To2D(),
                                   p_midCoord      => NULL,
                                   p_endCoord      => SELF.EndCoord.ST_To2D(),
                                   p_sdo_gtype     => 2001,
                                   p_sdo_srid      => SELF.sdo_srid)
            END;

  END ST_To2D;

  Member Function ST_To3D(p_keep_measure in integer default 0,
                          p_default_z    in number  default null)
  Return &&INSTALL_SCHEMA..T_Segment
  As
  Begin
    RETURN case when SELF.ST_Dims() = 2   /* Upscale to 3D */
                then &&INSTALL_SCHEMA..T_Segment(
                       element_id    => SELF.element_id,
                       subelement_id => SELF.element_id,
                       segment_id    => SELF.segment_id,
                       startCoord    => SELF.StartCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z),
                       midCoord      => CASE WHEN SELF.midCoord is not NULL THEN SELF.midCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z) else null end,
                       endCoord      => SELF.endCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z),
                       sdo_gtype     => 3001,
                       sdo_srid      => SELF.sdo_srid,
                       projected     => SELF.projected,
                       precisionModel=> SELF.PrecisionModel
                     )
                when SELF.ST_Dims()=3 and SELF.ST_hasZ()=1  /* Nothing to do */
                then T_Segment(SELF)
                when SELF.ST_Dims()=3
                then &&INSTALL_SCHEMA..T_Segment(
                       element_id    => SELF.element_id,
                       subelement_id => SELF.element_id,
                       segment_id    => SELF.segment_id,
                       startCoord    => SELF.StartCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z),
                       midCoord      => CASE WHEN SELF.midCoord is not NULL THEN SELF.midCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z) else null end,
                       endCoord      => SELF.endCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z),
                       sdo_gtype     => 3002,
                       sdo_srid      => SELF.sdo_srid,
                       projected     => SELF.projected,
                       precisionModel=> SELF.PrecisionModel
                     )
                when SELF.ST_Dims()=4
                then &&INSTALL_SCHEMA..T_Segment(
                       element_id    => SELF.element_id,
                       subelement_id => SELF.element_id,
                       segment_id    => SELF.segment_id,
                       startCoord    => SELF.startCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z),
                       midCoord      => CASE WHEN SELF.midCoord is not NULL THEN SELF.midCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z) else null end,
                       endCoord      => SELF.endCoord.ST_To3D(p_keep_measure=>p_keep_measure,p_default_z=>p_default_z),
                       sdo_gtype     => 3002,
                       sdo_srid      => SELF.sdo_srid,
                       projected     => SELF.projected,
                       precisionModel=> SELF.PrecisionModel
                     )
            END;
  End ST_To3D;

  Member Function ST_isCollinear(p_segment in &&INSTALL_SCHEMA..T_Segment)
           Return integer
  As
    v_vector3D &&INSTALL_SCHEMA..T_Vector3D;
  Begin
    If ( p_segment is null ) Then
      return 1;
    End If;
    if ( SELF.ST_isCircularArc()=1 or p_segment.ST_IsCircularArc()=1 ) Then
      return 0;
    end if;    
    v_vector3D := &&INSTALL_SCHEMA..t_vector3d(SELF.ST_Self())
                       .Normalize()
                       .Subtract(&&INSTALL_SCHEMA..t_vector3d(p_segment)
                       .Normalize());
    return case when (  ROUND(v_vector3D.X,SELF.PrecisionModel.XY) = 0
                    and ROUND(v_vector3D.Y,SELF.PrecisionModel.XY) = 0
                    and ROUND(NVL(v_vector3D.Z,0),SELF.PrecisionModel.XY) = 0 ) 
                then 1
                else 0
           end;
  End ST_isCollinear;
  
  Member Function ST_Merge(p_segment in &&INSTALL_SCHEMA..T_Segment)
           Return &&INSTALL_SCHEMA..T_Segment
  AS
    v_self     &&INSTALL_SCHEMA..T_Segment;
    v_segment  &&INSTALL_SCHEMA..T_Segment;
  BEGIN
    -- DEBUG dbms_output.put_line('<ST_Merge>');
    IF ( p_segment IS NULL ) THEN
      Return SELF;
    END IF;
    -- Check if equals
    IF ( SELF.ST_Equals(p_segment => p_segment,
                        p_coords  => 1)=1) Then
      Return SELF;
    END IF;

    -- Can't merge if one is circular arc
    if ( SELF.ST_isCircularArc()=1 or p_segment.ST_isCircularArc()=1 ) then
       -- Could merge and return an sdo_geometry linestring - see t_geometry
       Return SELF;
    End If;

    -- Ensure all segments are correctly ordered
    --
    v_self := SELF.ST_Self();
    IF (    SELF.endCoord.ST_Equals(p_segment.endCoord)=1 ) Then
      v_segment := &&INSTALL_SCHEMA..T_Segment(p_segment.ST_Reverse());
    ELSIF ( SELF.endCoord.ST_Equals(p_segment.startCoord)=1 ) Then
      v_segment := &&INSTALL_SCHEMA..T_Segment(p_segment);
    ELSIF ( SELF.startCoord.ST_Equals(p_segment.startCoord)=1 ) Then
      v_self    := p_segment.ST_Reverse();
      v_segment := &&INSTALL_SCHEMA..T_Segment(SELF);
    ELSE
      -- They don't touch, so return original segment
      RETURN SELF;
    END IF;

    /* dbms_output.put_line('            v_self: ' || v_self.ST_AsText());
       dbms_output.put_line('         v_segment: ' || v_segment.ST_AsText());
    */

    -- We now have correct end/start relationship
    -- Check if join point is collinear using vector arithmetic.
    -- 
    If ( v_self.ST_isCollinear(p_segment=>v_segment)=1 ) Then
      -- DEBUG dbms_output.put_line('  Two segments have shared end/start point And Are Collinear.');
      -- DEBUG dbms_output.put_line('</ST_Merge>');
-- SGG
      Return new &&INSTALL_SCHEMA..T_Segment(
                   p_segment_id    => 1,   /*SELF.segment_id*/
                   p_element_id    => SELF.element_id,
                   p_subelement_id => SELF.subelement_id,
                   p_startCoord    => v_self.startCoord,
                   p_endCoord      => v_segment.endCoord,
                   p_sdo_gtype     => SELF.sdo_gtype,
                   p_sdo_srid      => SELF.sdo_srid
                 );
    ELSE
      -- DEBUG dbms_output.put_line('  Two segments have shared end/start point but Not Collinear.');
      -- DEBUG dbms_output.put_line('</ST_Merge>');
      -- Return merged segment with shared point as midCoord.
      Return new &&INSTALL_SCHEMA..T_Segment(
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
    v_length := SELF.ST_Length (p_unit=>p_unit);
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
  Return &&INSTALL_SCHEMA..T_Segment
  AS

  BEGIN
    Return &&INSTALL_SCHEMA..T_Segment(
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

  Member Function ST_Parallel(p_offset in Number)
  Return &&INSTALL_SCHEMA..T_Segment Deterministic
  As
    v_deflection_angle Number;
    v_bearing          Number;
    v_offset           Number;
    v_sign             Number;
    v_delta_x          Number;
    v_delta_y          Number;
    v_circle           &&INSTALL_SCHEMA..T_Vertex;
    v_start_point      &&INSTALL_SCHEMA..T_Vertex;
    v_mid_point        &&INSTALL_SCHEMA..T_Vertex;
    v_end_point        &&INSTALL_SCHEMA..T_Vertex;
  Begin
    v_offset := NVL(p_offset,0.0);
    If ( v_offset = 0.0 ) Then
      Return SELF;
    END IF;

    v_sign := SIGN(v_offset);

    -- Process two point linestring first...
    IF ( SELF.ST_isCircularArc() = 0 /* LineString */ ) THEN

      -- Compute offset bearing from segment bearing (degrees)...

      v_bearing := SELF.ST_Bearing(p_normalize => 0)
                   +
                   (v_sign * 90.0); -- If left, then -90 else 90
      v_bearing := COGO.ST_Normalize( p_degrees => v_bearing );
      -- Compute first offset point
      v_start_point := SELF.startCoord
                           .ST_FromBearingAndDistance(
                               p_bearing   => v_bearing,
                               p_distance  => ABS(v_offset),
                               p_projected => SELF.projected
                            );

      -- Create deltas to apply to End Ordinate...
      v_delta_x := v_start_point.X - SELF.StartCoord.X;
      v_delta_y := v_start_point.Y - SELF.StartCoord.Y;

      -- Now return parallel segment
-- SGG PrecisionModel
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
           .ST_Parallel(p_offset    => p_offset);
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
                       p_projected => SELF.projected,
                       p_normalize => 1);
    v_start_point := v_circle
                       .ST_FromBearingAndDistance(
                           p_bearing   => v_bearing,
                           p_distance  => ABS(v_offset),
                           p_projected => 1
                        );

    -- Mid Point
    --
    v_bearing     := v_circle.ST_Bearing(
                       p_vertex    => SELF.MidCoord,
                       p_projected => SELF.projected,
                       p_normalize => 1);
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
                       p_projected => SELF.projected,
                       p_normalize => 1);
    v_end_point   := v_circle
                       .ST_FromBearingAndDistance(
                           p_bearing   => v_bearing,
                           p_distance  => ABS(v_offset),
                           p_projected => SELF.projected
                        );

    -- Now return circular arc
    RETURN &&INSTALL_SCHEMA..T_Segment(
               element_id    => SELF.element_id,
               subelement_id => SELF.subelement_id,
               segment_id    => SELF.segment_id,
               startCoord    => &&INSTALL_SCHEMA..T_Vertex (
                  p_id        => SELF.startCoord.ID,
                  p_X         => v_start_point.X,
                  p_Y         => v_start_point.Y,
                  p_Z         => SELF.startCoord.Z,
                  p_W         => SELF.startCoord.W,
                  p_sdo_gtype => SELF.startCoord.sdo_gtype,
                  p_sdo_srid  => SELF.sdo_Srid
               ),
               midCoord => &&INSTALL_SCHEMA..T_Vertex (
                  p_id        => SELF.midCoord.ID,
                  p_X         => v_mid_point.X,
                  p_Y         => v_mid_point.Y,
                  p_Z         => SELF.midCoord.Z,
                  p_W         => SELF.midCoord.W,
                  p_sdo_gtype => SELF.startCoord.sdo_gtype,
                  p_sdo_srid  => SELF.sdo_Srid
               ),
               endCoord => &&INSTALL_SCHEMA..T_Vertex (
                  p_id        => SELF.endCoord.ID,
                  p_X         => v_end_point.X,
                  p_Y         => v_end_point.Y,
                  p_Z         => SELF.EndCoord.Z,
                  p_W         => SELF.EndCoord.W,
                  p_sdo_gtype => SELF.startCoord.sdo_gtype,
                  p_sdo_srid  => SELF.sdo_Srid
               ),
               sdo_gtype => SELF.sdo_gtype,
               sdo_srid  => SELF.sdo_Srid,
               projected => SELF.projected,
               PrecisionModel => SELF.precisionModel
           );
  End ST_Parallel;

  Member Function ST_AddCurveBetweenSegments(
                     p_segment   In &&INSTALL_SCHEMA..T_Segment,
                     p_iVertex   in &&INSTALL_SCHEMA..T_Vertex default NULL,
                     p_radius    In number         default null,
                     p_unit      In varchar2       default NULL)
           Return mdsys.sdo_Geometry 
  As
    v_cVertex         &&INSTALL_SCHEMA..T_Vertex;
    v_iVertex         &&INSTALL_SCHEMA..T_Vertex;
    v_iExisted        boolean;
    v_iPoints         &&INSTALL_SCHEMA..T_Segment;
    v_perpendicular_2 &&INSTALL_SCHEMA..T_Segment;
  Begin
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
                            p_segment    => p_segment,
                            p_offset     => p_radius,
                            p_unit       => p_unit
                    );
       -- DEBUG dbms_output.put_line(v_cVertex.ST_AsText());
       Return v_cVertex.ST_SdoGeometry();
    END IF;
    Return SELF.ST_SdoGeometry();
  End ST_AddCurveBetweenSegments;

  Member Function ST_Length(p_unit IN VARCHAR2 Default NULL)
  Return NUMBER
  AS
    v_length    NUMBER;
    v_seg_len   NUMBER;
    v_test_len  NUMBER;
    v_dims      INTEGER;
    v_z_posn    INTEGER;
    v_has_z     BOOLEAN := SELF.ST_hasZ() = 1;
    v_geom      mdsys.sdo_geometry;
    v_isLocator BOOLEAN := false;
  BEGIN
    v_isLocator := case when &&INSTALL_SCHEMA..TOOLS.ST_isLocator() = 1 then true else false end;
    v_geom      := SELF.ST_SdoGeometry(SELF.ST_Dims());
    v_dims      := v_geom.get_Dims();
    v_z_posn    := case when SELF.ST_Lrs_Dim() = 0 and v_dims = 2      then 0
                        when SELF.ST_Lrs_Dim() = 0 and v_dims in (3,4) then 3
                        when SELF.ST_Lrs_Dim() = 3 and v_dims = 3 then 0
                        when SELF.ST_Lrs_Dim() = 3 and v_dims = 4 then 4  -->> SGG
                        when SELF.ST_Lrs_Dim() = 4 and v_dims = 4 then 3
                    end;
    
    -- DEBUG dbms_output.put_line(' sdo_gtype='|| v_geom.sdo_gtype ||' v_dims='||v_dims||' v_z_posn='||v_z_posn|| ' SRID=' || NVL(SELF.SDO_SRID,-1)||' tolerance='||p_tolerance);
    -- Compute length
    --
    IF (  (v_geom.Get_Dims() = 2 /*2002*/ )
       OR (v_geom.Get_Dims() = 3 AND v_geom.Get_Lrs_Dim() != 0 /*3302*/) ) Then
       -- DEBUG dbms_output.put_line('T_Segment.ST_LENGTH: 200x or 330x');
       v_length := CASE WHEN p_unit IS NOT NULL AND SELF.SDO_Srid IS NOT NULL
                        THEN MDSYS.SDO_Geom.SDO_Length(v_geom,SELF.precisionModel.tolerance,P_UNIT)
                        ELSE MDSYS.SDO_Geom.SDO_Length(v_geom,SELF.precisionModel.tolerance)
                    END;
    ELSIF (Not v_isLocator ) Then -- v_geom.GET_DIMS() = 3 /*3002*/ And Not v_isLocator) Then
       -- DEBUG dbms_output.put_line('T_Segment.ST_LENGTH: Spatial sdo_geom.sdo_length; p_unit=' || NVL(p_unit,'null'));
       v_length := CASE WHEN p_unit IS NOT NULL AND SELF.SDO_Srid IS NOT NULL
                        THEN MDSYS.SDO_Geom.SDO_Length(v_geom,SELF.precisionModel.tolerance,P_UNIT)
                        ELSE MDSYS.SDO_Geom.SDO_Length(v_geom,SELF.precisionModel.tolerance)
                    END;
    ELSE -- isLocator
       -- Because srid may be lat/long, compute horizontal distance first
       v_geom.sdo_ordinates := mdsys.sdo_ordinate_array(1,2,3,4);
       v_geom.sdo_ordinates(1) := SELF.startCoord.x;
       v_geom.sdo_ordinates(2) := SELF.startCoord.y;
       v_geom.sdo_ordinates(3) := SELF.endCoord.x;
       v_geom.sdo_ordinates(4) := SELF.endCoord.y;
       v_seg_len := CASE WHEN p_unit IS NOT NULL AND SELF.SDO_Srid IS NOT NULL
                         THEN MDSYS.SDO_Geom.SDO_Length(v_geom,SELF.precisionModel.tolerance,P_UNIT)
                         ELSE MDSYS.SDO_Geom.SDO_Length(v_geom,SELF.precisionModel.tolerance)
                     END;
       -- DEBUG dbms_output.put_line('T_Segment.ST_LENGTH v_seg_len= ' || v_seg_len);
       -- Now compute Z component
       v_length := SQRT(POWER(v_seg_len,2) +
                        POWER(case when v_z_posn = 3 then SELF.endCoord.z  else SELF.endCoord.w end
                              -
                              case when v_z_posn = 3 then SELF.StartCoord.z else SELF.StartCoord.w end,2) );
    END IF;
    -- DEBUG dbms_output.put_line('T_Segment.ST_LENGTH Return = ' || v_length);
    Return v_length;
  END ST_Length;

  Member Function ST_Angle
           Return Number
  As
  Begin
    return &&INSTALL_SCHEMA..COGO.ArcTan2(SELF.endCoord.y - SELF.startCoord.y, 
                              SELF.endCoord.x - SELF.startCoord.x);
  End ST_Angle;

  Member Function ST_Bearing(p_normalize in Integer Default 1)
  Return Number Deterministic
  As
    v_bearing number;
  Begin
    v_bearing := SELF.StartCoord
                     .ST_Bearing(
                         p_vertex    => SELF.EndCoord,
                         p_projected => SELF.projected,
                         p_normalize => p_normalize
                     );
    Return v_bearing;
  End ST_Bearing;

  Member Function ST_Distance(p_geometry   in mdsys.sdo_geometry,
                              p_unit       in varchar2 Default null)
  Return Number
  As
    v_tgeometry       &&INSTALL_SCHEMA..t_geometry;
    v_segment_geom    mdsys.sdo_geometry;
    v_point           mdsys.sdo_geometry;
    v_distance        number;
    v_length          number;
    v_vertex_b        &&INSTALL_SCHEMA..T_Vertex;
    v_vertex          &&INSTALL_SCHEMA..T_Vertex;
    v_segment         &&INSTALL_SCHEMA..T_Segment;
    v_has_z           BOOLEAN;
    v_test_len        NUMBER;
    v_isLocator       BOOLEAN;
  Begin
    -- BEGIN dbms_output.put_line('T_Segment.ST_DISTANCE: START');
    If (p_geometry is null) Then
       Return -1; /* False */
    End If;
    
    IF ( NVL(SELF.ST_SRID(),0) <> NVL(p_geometry.sdo_srid,0) ) THEN
       Return -1;
    END IF;
    
    v_isLocator := case when &&INSTALL_SCHEMA..TOOLS.ST_isLocator() = 1 then true else false end;
    v_tgeometry := &&INSTALL_SCHEMA..T_Geometry(p_geometry,SELF.PrecisionModel.tolerance,SELF.PrecisionModel.XY,SELF.projected);
    -- if start = end, then just compute distance to one of the endpoints
    if ( SELF.startCoord.ST_Equals(SELF.endCoord,SELF.PrecisionModel.XY) = 1 ) then
      Return v_tGeometry.ST_Distance(SELF.startCoord.ST_SdoGeometry(),
                                     p_unit,
                                     SELF.PrecisionModel.XY);
    end if;
    
    -- Normalise geometries for use in sdo_geom.sdo_distance
    -- DEBUG dbms_output.put_line('v_vertex.ST_Dims() ' || v_vertex.ST_Dims() || ' = SELF.ST_Dims() '||SELF.ST_Dims());
    -- DEBUG dbms_output.put_line('v_vertex.ST_Lrs_Dim() ' || v_vertex.ST_Lrs_Dim() || ' = SELF.ST_Lrs_Dim() '||SELF.ST_Lrs_Dim());
    v_segment := &&INSTALL_SCHEMA..T_Segment(SELF);
    IF ( v_tgeometry.ST_Dims() = 2 and SELF.ST_Dims() = 2 ) THEN
      NULL;  -- ie Do Nothing...
    ELSIF ( v_tgeometry.ST_Dims() = 2 and SELF.ST_Dims() = 3 ) THEN
      v_segment := SELF.ST_To2D();
    ELSIF ( v_tgeometry.ST_Dims() = 3 and SELF.ST_Dims() = 2 ) THEN
      v_tgeometry := v_tgeometry.ST_To2D();
    ELSIF ( v_tgeometry.ST_Dims() = 3 AND v_tgeometry.ST_Lrs_Dim()=3 ) THEN
      v_segment   :=        SELF.ST_To2D();
      v_tgeometry := v_tgeometry.ST_To2D();
    ELSE
      v_segment   :=        SELF.ST_To3D(p_keep_measure=>0,p_default_z=>NULL);
      v_tgeometry := v_tgeometry.ST_To3D(p_zordtokeep=>3);
    End If;
    -- DEBUG dbms_output.put_line('  v_segment: ' || v_segment.ST_AsText() || ' v_tgeometry: ' || v_tgeometry.ST_AsEWKT());
    -- Get normalised segment as geometry
    v_segment_geom := v_segment.ST_SdoGeometry();
    -- DEBUG &&INSTALL_SCHEMA._DEBUG.PrintGeom(v_segment_geom,3,false,'v_segment_geom: ');
    -- DEBUG dbms_output.put_line('T_Segment.ST_DISTANCE: case when p_unit is not null and SELF.ST_Srid() is not null => '||case when p_unit is not null and SELF.ST_Srid() is not null then 'p_unit' else 'no p_unit' end);
    v_distance := case when p_unit is not null and SELF.ST_Srid() is not null
                       then mdsys.sdo_geom.sdo_distance(v_tgeometry.geom,v_segment_geom,SELF.precisionModel.XY,p_unit)
                       else mdsys.sdo_geom.sdo_distance(v_tgeometry.geom,v_segment_geom,SELF.precisionModel.XY)
                   end;
    -- DEBUG dbms_output.put_line('T_Segment.ST_DISTANCE: v_distance='||v_distance);
    v_has_z     := (SELF.ST_hasZ()=1 AND LEAST(v_tgeometry.ST_Dims(),SELF.ST_Dims()) > 2);

    -- DEBUG dbms_output.put_line('T_Segment.ST_DISTANCE: v_has_z='||case when v_has_z then 'T' else 'F' end || ' v_isLocator=' || case when v_isLocator then 'T' else 'F' end);
    if ( v_isLocator and v_has_z ) Then
       /* TOBEDONE: Add in Z height which hopefully is in p_units */
       -- DEBUG dbms_output.put('BEFORE ST_CLOSEST=>' || v_distance);
       v_vertex_b := SELF.ST_Closest(
                             p_geometry =>v_tgeometry.geom,
                             p_unit     =>p_unit
                     );
       v_distance := ROUND(SQRT(POWER(v_distance,2) +
                                POWER(NVL(v_vertex_b.z,NVL(v_vertex.z,  0))
                                    - NVL(v_vertex.z,  NVL(v_vertex_b.z,0)),2)
                               ),SELF.PrecisionModel.XY);
       -- DEBUG dbms_output.put_line(' AFTER=>' || v_distance);
    End If;
    -- DEBUG dbms_output.put_line('T_Segment.ST_DISTANCE: result is ' || NVL(round(v_distance,v_precision),-9999));
    Return ROUND(v_distance,SELF.PrecisionModel.XY);
  End ST_Distance;

  Member Function ST_Distance(p_vertex     in &&INSTALL_SCHEMA..T_Vertex,
                              p_unit       in varchar2 default null)
           Return Number
  As
    v_vertex &&INSTALL_SCHEMA..T_Vertex;
  Begin
    return SELF.ST_Distance(
             p_geometry => p_vertex.ST_SdoGeometry(),
             p_unit     => p_unit
           );
  End ST_Distance;

  Member Function ST_Distance(p_segment    in &&INSTALL_SCHEMA..T_Segment,
                              p_unit       in varchar2 default null)
           Return Number
  As
    v_vertex &&INSTALL_SCHEMA..T_Vertex;
  Begin
    return SELF.ST_Distance(
             p_geometry => p_segment.ST_SdoGeometry(),
             p_unit     => p_unit
           );
  End ST_Distance;

  Member Function ST_SegmentToSegmentDistance(
                     p_segment in &&INSTALL_SCHEMA..T_Segment,
                     p_unit    in varchar2 default null
                  )
           Return Number
  As
    denominator    number;
    numerator      number;
    noIntersection boolean;
    A              &&INSTALL_SCHEMA..t_vertex;
    B              &&INSTALL_SCHEMA..t_vertex;
    C              &&INSTALL_SCHEMA..t_vertex;
    D              &&INSTALL_SCHEMA..t_vertex;
    r_num          number;
    s_num          number;
    s              number;
    r              number;
  Begin
    -- DEBUG dbms_output.put_line('<ST_SegmentToSegmentDistance>');
    if ( p_segment is null ) then
      return null;
    End If;
    -- Assign same names as comp.graphics.algo below
    A := &&INSTALL_SCHEMA..t_vertex(self.startCoord);
    B := &&INSTALL_SCHEMA..t_vertex(self.endCoord);
    C := &&INSTALL_SCHEMA..t_vertex(p_segment.startCoord);
    D := &&INSTALL_SCHEMA..t_vertex(p_segment.endCoord);
    
    -- check for zero-length segments
    if (A.ST_Equals(B)=1 ) then
      -- return distancePointLine(A, C, D);
      -- DEBUG dbms_output.put_line('  1. A=B -> ST_ProjectPoint');
      return p_segment.ST_ProjectPoint (
               p_vertex => SELF.startCoord,
               p_unit   => p_unit
             ).ST_Distance(
                  p_vertex => SELF.startCoord,
                  p_unit   => p_unit
             );
    end if;
    
    if (C.ST_Equals(D)=1) then
      -- DEBUG dbms_output.put_line('  1. C=D -> ST_ProjectPoint');
      --return distancePointLine(D, A, B);
      return SELF.ST_ProjectPoint(
               p_vertex => p_segment.endCoord,
               p_unit   => p_unit
             ).ST_Distance(
                  p_vertex => SELF.endCoord,
                  p_unit   => p_unit
             );
    End If;

    /*
     * from comp.graphics.algo
     * 
     * Solving the above for r and s yields 
     * 
     *     (Ay-Cy)(Dx-Cx)-(Ax-Cx)(Dy-Cy) 
     * r = ----------------------------- (eqn 1) 
     *     (Bx-Ax)(Dy-Cy)-(By-Ay)(Dx-Cx)
     * 
     *     (Ay-Cy)(Bx-Ax)-(Ax-Cx)(By-Ay) 
     * s = ----------------------------- (eqn 2)
     *     (Bx-Ax)(Dy-Cy)-(By-Ay)(Dx-Cx) 
     *     
     * Let P be the position vector of the intersection point, then 
     *   P=A+r(B-A) or 
     *   Px=Ax+r(Bx-Ax) 
     *   Py=Ay+r(By-Ay) 
     * By examining the values of r & s, you can also determine some other limiting conditions: 
     *   If 0<=r<=1 & 0<=s<=1, intersection exists 
     *      r<0 or r>1 or s<0 or s>1 line segments do not intersect 
     *   If the denominator in eqn 1 is zero, AB & CD are parallel 
     *   If the numerator   in eqn 1 is also zero, AB & CD are collinear.
     */
    -- DEBUG dbms_output.put_line('  Compute Intersection');
    noIntersection := false;
    if ( Not &&INSTALL_SCHEMA..T_MBR.Intersects(A, B, C, D) ) Then
      -- DEBUG dbms_output.put_line('  MBR does not intersect');
      noIntersection := true;
    else
      denominator := (B.x - A.x) * (D.y - C.y) - (B.y - A.y) * (D.x - C.x);
      -- DEBUG dbms_output.put_line('  denominator is ' || denominator);
      numerator   := (A.y - C.y) * (D.x - C.x) - (A.x - C.x) * (D.y - C.y);
      -- DEBUG dbms_output.put_line('  numerator is ' || numerator);
      if (denominator = 0) then
        return -9; /* Parallel */
      else 
        r_num := numerator;
        s_num := (A.y - C.y) * (B.x - A.x) - (A.x - C.x) * (B.y - A.y);
        s     := s_num / denominator;
        r     := r_num / denominator;
        -- DEBUG dbms_output.put_line('  s= '||s||'; r= '||r);
        if ((r < 0) OR (r > 1) OR (s < 0) OR (s > 1)) then
        -- DEBUG dbms_output.put_line('  No intersection');
          noIntersection := true;
        End If;
      End If;
    End If;
    -- DEBUG dbms_output.put_line('  No intersection? ' || case when noIntersection then 'TRUE' else 'FALSE' end);
    if (noIntersection) Then
      return Least(
               p_segment.ST_Distance(A,p_unit),
               p_segment.ST_Distance(B,p_unit),
                    SELF.ST_Distance(C,p_unit),
                    SELF.ST_Distance(D,p_unit)
            );
    End If;
    -- segments intersect
    -- DEBUG dbms_output.put_line('</ST_SegmentToSegmentDistance>');
    return 0.0; 
  End ST_SegmentToSegmentDistance;

  Member Function ST_PointToCircularArc(p_vertex in &&INSTALL_SCHEMA..T_Vertex,
                                        p_unit   in varchar2 default null)
      Return &&INSTALL_SCHEMA..T_Vertex
  As
    vX                     Number;
    vY                     Number;
    magV                   Number;
    v_vertex               &&INSTALL_SCHEMA..T_vertex;
    v_centre               &&INSTALL_SCHEMA..T_vertex;
    v_intersection_point   &&INSTALL_SCHEMA..t_vertex;
    v_segment              &&INSTALL_SCHEMA..t_segment;
    v_radius               number;
    v_intersection_angle   Number;
    v_circular_arc_angle   Number;
    v_bearing              number;
    v_length               number;
    v_ratio                number;
    v_projected            pls_integer;
  Begin
    -- DEBUG dbms_output.put_line('<ST_PointToCircularArc>');
    IF ( p_vertex is null ) Then
      Return null;
    End If;
    v_projected := case when SELF.sdo_srid is null then 1 else &&INSTALL_SCHEMA..t_segment.ST_GetProjected(SELF.sdo_srid) end;
    If ( SELF.ST_isCircularArc()=0 ) Then
      RETURN SELF.ST_ProjectPoint(p_vertex => p_vertex,
                                  p_unit   => p_unit
                                 );
    Else /* is Circular Arc */
      IF ( v_projected = 0 ) THEN
        RETURN SELF.ST_Closest(
                       p_geometry => p_vertex.ST_SdoGeometry(),
                       p_unit   => p_unit
                    );
      End If;
    End If;

    -- ST_isCircularArc()=1 and v_projected=1
    --
    -- Find centre of circle
    v_centre := SELF.ST_FindCircle(); -- z holds radius
    -- DEBUG dbms_output.put_line('  v_centre is '||v_centre.ST_AsText());
    If ( v_centre.z = -9 ) Then
      return null;
    End If;
    v_radius := v_centre.z;

    -- SGG: Align input/self
    v_vertex             := &&INSTALL_SCHEMA..t_vertex(p_vertex);
    if ( v_vertex.ST_Dims()=2 and SELF.ST_Dims()=3 ) Then
      v_vertex.z         := SELF.startCoord.z;
      v_vertex.sdo_gtype := case when SELF.ST_Lrs_Dim()=3 then 3301 else 3001 end;
    elsif ( v_vertex.ST_Dims()=3 and SELF.ST_Dims()=3 ) Then
      -- If Z are not the same they can't intersect
      if ( v_vertex.Z <> SELF.startCoord.Z ) Then
        return null;
      End If;
    elsif ( v_vertex.ST_Dims()=3 and SELF.ST_Dims()=2 ) Then
      v_vertex.z         := null;
      v_vertex.sdo_gtype := 2001;
    End If;
    -- DEBUG dbms_output.put_line('v_Vertex: ' || v_vertex.ST_AsEWKT());
    
    -- SGG: Apply SELF Z to centre
    v_centre.z         := SELF.startCoord.z;
    v_centre.sdo_gtype := v_vertex.sdo_gtype;

    -- Short circuit if centre = v_vertex
    -- SGG: Precision Model
    IF ( v_centre.ST_Equals(v_vertex)=1 ) Then
      Return SELF.startCoord;
    End If;

    -- Now compute intersection point with circular arc using math 
    vX   := v_vertex.X - v_centre.X;
    vY   := v_vertex.Y - v_centre.Y;
    magV := SQRT(vX*vX + vY*vY);
    v_intersection_point := &&INSTALL_SCHEMA..T_Vertex(
                              p_x         => v_centre.X + vX / magV * v_radius,
                              p_y         => v_centre.Y + vY / magV * v_radius,
                              p_id        => 1,
                              p_sdo_gtype => 2001,
                              p_sdo_srid  => SELF.ST_Srid
                            );
    -- Check to see if computed point is actually on circular arc and not virtual circle perimiter
    -- DEBUG dbms_output.put_line('  v_intersection_point: ' || v_intersection_point.ST_AsEWKT());
    If ( v_intersection_point is null ) then
      -- Compute length from centre to v_vertex
      v_length := v_centre.ST_Distance(
                    p_vertex    => v_vertex,
                    p_unit      => p_unit 
                  );
      if ( v_length < v_radius ) Then
        -- Bearing and distance from centre to circular arc 
        v_bearing := v_centre.ST_Bearing(
                             p_vertex    => v_vertex,
                             p_normalize => 1
                     );
        -- DEBUG dbms_output.put_line('Bearing: ' || v_bearing);
        v_intersection_point := v_centre.ST_FromBearingAndDistance(
                                            p_bearing   => v_bearing,
                                            p_distance  => v_radius
                                          );
      ELSE
        -- Create line from centre to p_vertex.
        v_segment := &&INSTALL_SCHEMA..T_Segment(
                             p_segment_id => 1,
                             p_startCoord => v_centre,
                             p_endCoord   => v_vertex,
                             p_sdo_gtype  => SELF.sdo_gtype,
                             p_sdo_srid   => SELF.sdo_srid
                     );
        v_segment.PrecisionModel := SELF.PrecisionModel;
        v_segment.projected      := SELF.projected;
        -- DEBUG dbms_output.put_line(v_segment.ST_AsEWKT());
        -- Compute intersection using alternate segment method
        v_intersection_point := SELF.ST_IntersectCircularArc(v_segment).startCoord;
        -- SGG What does this return?
        -- DEBUG dbms_output.put_line('ST_IntersectCircularArc: ' || v_intersection_point.ST_AsEWKT());
      End If;
    End If;

    -- *********************************************************
    -- Determine if intersection point falls on Circular Arc or not.
    --
    
    -- Circular arc angle
    v_circular_arc_angle := SELF.startCoord.ST_SubtendedAngle(self.midCoord,self.endCoord);
    -- DEBUG dbms_output.put_line('  angle subtended by whole arc =' || v_circular_arc_angle );
    
    -- Now compute again with midCoord replaced by computed point
    v_intersection_angle := SELF.startCoord.ST_SubtendedAngle(v_intersection_point,SELF.endCoord);
    -- DEBUG dbms_output.put_line('  angle subtended by arc containing intersection point=' || v_intersection_angle );

    -- DEBUG dbms_output.put_line('   Arc Angle Signs (main,intersection): '||SIGN(v_circular_arc_angle) || ' -- ' || SIGN(v_intersection_angle));
    -- DEBUG dbms_output.put_line('</ST_PointToCircularArc>');
    If ( SIGN(v_circular_arc_angle) != SIGN(v_intersection_angle) ) then
      Return NULL;
    End If;

    -- Construct point to be returned
	--

	-- 1. Compute subtended angle at centre
	--

	-- 1.1 Circular arc angle
    v_circular_arc_angle := v_centre.ST_SubtendedAngle(
                                        SELF.startCoord,
                                        SELF.endCoord
								);

    -- 1.2 Compute start/centre/intersection 
    v_intersection_angle := v_centre.ST_SubtendedAngle(
                                        SELF.startCoord,
                                        v_intersection_point
								);

    -- v_intersection_point is 2D
    --   Compute other ordinates
	--     Z is as for any point on circular arc if circular arc has Z (not measure)
	--     M is computed as a ratio from start coord (is measure if circular arc measured, else length
    --
    v_length := SELF.ST_Length(p_unit => p_unit);
    v_ratio  := v_intersection_angle / v_circular_arc_angle;
    If ( SELF.ST_Lrs_Dim()=0 ) Then
      IF ( SELF.ST_Dims() in (3,4) ) Then
        v_intersection_point.Z := SELF.startCoord.Z;
        v_intersection_point.W := v_length * v_ratio;
        v_intersection_point.sdo_gtype := 4401;
      Else 

        v_intersection_point.Z := v_length * v_ratio;
        v_intersection_point.sdo_gtype := 3301;
      End If;
    Else
      -- Now calculate Measure
      if ( SELF.ST_Lrs_Dim() = 3 ) Then
        v_intersection_point.z := SELF.startCoord.z + (SELF.endCoord.z - SELF.startCoord.z) * v_ratio; 
        v_intersection_point.sdo_gtype := 3301;
      elsif ( SELF.ST_Lrs_Dim() = 4 ) Then
        v_intersection_point.Z := SELF.startCoord.Z;
        v_intersection_point.w := SELF.startCoord.w + (SELF.endCoord.w - SELF.startCoord.w) * v_ratio; 
        v_intersection_point.sdo_gtype := 4401;
      End If;      
    End If;
    
    -- DEBUG DEBUG.PrintGeom(v_intersection_point.ST_SdoGeometry(),3,false,'  v_intersection_point: ');
    Return v_intersection_point;
  End ST_PointToCircularArc;
  
  Member Function ST_PointToLineString(p_vertex in &&INSTALL_SCHEMA..T_Vertex)
      Return &&INSTALL_SCHEMA..T_Vertex
  As
    sqrP_LB  number;
    sqrP_LE  number;
    sqrLB_LE number;
    LB_LE    number;
    I_LB     number;
    u        number;
    v_vertex &&INSTALL_SCHEMA..t_vertex;

    Function sqrDistPP3D(p_v1 in &&INSTALL_SCHEMA..T_Vertex,
                         p_v2 in &&INSTALL_SCHEMA..T_Vertex)
    Return Number
    As
    Begin
      Return (p_v1.x - p_v2.x)    *     (p_v1.x - p_v2.x) +
             (p_v1.y - p_v2.y)    *     (p_v1.y - p_v2.y) +
         NVL((p_v1.z - p_v2.z),0) * NVL((p_v1.z - p_v2.z),0);  -- SGG Is this correct if z is measure?
    End sqrDistPP3D;

  Begin
    -- DEBUG dbms_output.put_line('<ST_PointToLineString>');
    if ( p_vertex is null ) Then
      Return null;
    End If;
    
    IF ( SELF.ST_isCircularArc()=1 ) THEN
       RETURN SELF.ST_PointToCircularArc(p_vertex => p_vertex,
                                         p_unit   => NULL);
    END IF;
    
    sqrP_LB  := sqrDistPP3D(p_vertex,        SELF.startCoord);
    sqrP_LE  := sqrDistPP3D(p_vertex,        SELF.endCoord);
    sqrLB_LE := sqrDistPP3D(SELF.startCoord, SELF.endCoord);

    LB_LE    := SQRT(sqrLB_LE);
    I_LB     := (sqrP_LB + sqrLB_LE - sqrP_LE)/(2.0*LB_LE);

    if (I_LB < 0 ) then 
      -- DEBUG dbms_output.put_line('  intersection point is before beginning line segment');
      return SELF.startCoord;
    end If;
    if (I_LB > LB_LE ) then
      -- DEBUG dbms_output.put_line('  intersection point is behind end line segment');
      return SELF.endCoord;
    End If;

    -- Compute closest point
    u        := I_LB/LB_LE;
    v_vertex := new &&INSTALL_SCHEMA..T_Vertex(
                  p_x         => SELF.startCoord.x + u *(SELF.endCoord.x-SELF.startCoord.x),
                  p_y         => SELF.startCoord.y + u *(SELF.endCoord.y-SELF.startCoord.y),
                  p_z         => case when SELF.ST_Dims()>2 then SELF.startCoord.z + u *(SELF.endCoord.z-SELF.startCoord.z) else null end,
                  /* SGG Is measure calculation correct by assuming 3D */
                  p_w         => case when SELF.ST_Dims()>2 then SELF.startCoord.w + u *(SELF.endCoord.w-SELF.startCoord.w) else null end,
                  p_id        => 0,
                  p_sdo_gtype => SELF.sdo_gtype-1,
                  p_sdo_srid  => p_vertex.sdo_srid
              );
    -- DEBUG dbms_output.put_line('  v_vertex='||v_vertex.ST_round(8).ST_AsText());

    -- DEBUG dbms_output.put_line('<ST_PointToLineString>');

    Return v_vertex;
  END ST_PointToLineString;

  Member Function ST_isPointOnSegment(p_vertex    in &&INSTALL_SCHEMA..T_Vertex,
                                      p_unit      in varchar2 default null)
      Return integer 
  As
    v_centre                   &&INSTALL_SCHEMA..t_vertex;
    v_radius                   NUMBER;
    v_segment_length           NUMBER;
    v_start_to_point_distance  NUMBER;
    v_point_to_end_distance    NUMBER;
    v_point_to_centre_distance NUMBER;
  Begin
    -- DEBUG dbms_output.put_line('<ST_isPointOnSegment>');
    If (p_vertex is null) Then
      return null;
    End If;
    v_segment_length := SELF.ST_Length(p_unit);
    IF (SELF.ST_isCircularArc()=0) Then
      v_start_to_point_distance := SELF.startCoord.ST_Distance(
                                          p_vertex    => p_vertex,
                                          p_tolerance => SELF.PrecisionModel.tolerance,
                                          p_unit      => p_unit
                                   );
      v_point_to_end_distance   := p_vertex.ST_Distance(
                                          p_vertex    => SELF.endCoord,
                                          p_tolerance => SELF.PrecisionModel.tolerance,
                                          p_unit      => p_unit);
      if ( ROUND(v_segment_length,                                    SELF.precisionModel.xy)
         = ROUND( v_start_to_point_distance + v_point_to_end_distance,SELF.precisionModel.xy) ) then
        return 1;
      else
        return 0;
      End If;
    End If;
    
    -- DEBUG dbms_output.put_line('  CircularArc');
    -- Centre math is planar
    -- Try conversion to PLANAR coordinate system beforehand
    -- Assume CircularArcs are very small so treating lat/long as planar is acceptable.
    -- SGG: Could compute using circularArc lengths.
    v_centre := SELF.ST_FindCircle();
    if ( v_centre.id = -9 ) Then
      return 0;
    end If;
    v_radius                   := v_centre.z;
    -- DEBUG dbms_output.put_line('  v_radius=' ||v_radius);

    v_centre.z                 := null;
    v_centre.sdo_gtype         := 2001;
    v_point_to_centre_distance := p_vertex.ST_Distance(
                                    p_vertex    => v_centre,
                                    p_tolerance => SELF.PrecisionModel.xy,
                                    p_unit      => p_unit
                                  );
    -- DEBUG dbms_output.put_line('  ROUND(v_point_to_centre_distance,SELF.precisionModel.xy) (' ||ROUND(v_point_to_centre_distance,SELF.precisionModel.xy) || ') = ROUND(v_radius,SELF.precisionModel.xy) (' ||ROUND(v_radius,SELF.precisionModel.xy) || ')');

    if ( ROUND(v_point_to_centre_distance,SELF.precisionModel.xy)
       = ROUND(v_radius,                  SELF.precisionModel.xy) ) Then
       return 1;
    End If;
    -- DEBUG dbms_output.put_line('</ST_isPointOnSegment>');
    return 0;
  End ST_isPointOnSegment;

  Member Function ST_Closest (p_geometry  in mdsys.sdo_geometry,
                              p_unit      In varchar2 DEFAULT NULL
                             )
           Return &&INSTALL_SCHEMA..T_Vertex
  AS
    geographic3D EXCEPTION;
    PRAGMA       EXCEPTION_INIT(
                    geographic3D,-13364
                 );
    v_tgeometry        &&INSTALL_SCHEMA..T_Geometry;
    v_segment_geom     mdsys.sdo_geometry;
    v_point_on_geom    mdsys.sdo_geometry;
    v_point_on_segment mdsys.sdo_geometry;
    v_segment_length   number;
    v_ratio            number;
    v_distance         number;
    v_segment          &&INSTALL_SCHEMA..T_Segment;
    v_vertex           &&INSTALL_SCHEMA..T_Vertex;
  Begin
    -- DEBUG dbms_output.put_line('<ST_Closest p_geometry>');
    If (p_geometry is null) Then
      -- DEBUG dbms_output.put_line('  p_geometry is NULL'); 
       Return NULL;
    End If;

    IF ( p_geometry.get_gtype()=1 ) Then
      v_vertex := SELF.ST_ProjectPoint(p_vertex=>&&INSTALL_SCHEMA..T_Vertex(p_geometry));
      Return v_vertex;
    End If;
    
    -- SDO_CLOSEST_POINTS
    -- A. Cannot use to compute measure value even if we try and trick the code
    --    into doing so by pretending a 3302 segment is 3302.
    -- B. if Geodetic must be 3D SRID otherwise get rubbish.
    -- C. If Locator then both geom1/geom2 must be 2D
    -- D. If Spatial then don't mix dimensions eg 3001/4402
    --    So, convert both to Same Dimension and then add measure back in via alternate method

    -- DEBUG dbms_output.put_line(' SELF ' || SELF.ST_AsText());
    -- DEBUG dbms_output.put_line(' p_geometry ' || p_geometry.ST_AsText());
    v_tgeometry := &&INSTALL_SCHEMA..T_Geometry(p_geometry,SELF.PrecisionModel.tolerance,SELF.PrecisionModel.XY,SELF.projected); -- SGG IsGeographic
    v_segment   := &&INSTALL_SCHEMA..T_Segment(SELF);
    
    -- DEBUG dbms_output.put_line('  v_tgeometry.ST_Dims()/v_segment.ST_Dims()='||v_tgeometry.ST_Dims() || '/' || v_segment.ST_Dims());
    -- DEBUG dbms_output.put_line('  v_tgeometry.ST_Lrs_Dims()/v_segment.ST_Lrs_Dims()='||v_tgeometry.ST_Lrs_Dim() || '/' || v_segment.ST_Lrs_Dim());

    -- Turn geometries into something SDO_CLOSEST_POINTS can handle.
    IF (    v_tgeometry.ST_Dims() = 2 and SELF.ST_Dims() = 2 ) THEN
      -- ie both geometries are OK for sdo_closest_points
      NULL;  
    ELSIF ( v_tgeometry.ST_Dims() = 2 and SELF.ST_Dims() = 3 ) THEN
      -- ie Reduce 3D segment to 2D as can't calculate 2D point position correctly without Z dimension.
      v_segment := SELF.ST_To2D();
    ELSIF ( v_tgeometry.ST_Dims() = 3 and SELF.ST_Dims() = 2 ) THEN
      -- ie Reduce input geometry to 2D as can only calculate a 2D position against a 2D segment    
      v_tgeometry  := v_tgeometry.ST_To2D();
    ELSIF ( v_tgeometry.ST_Dims() = 3 AND SELF.ST_Dims() = 3 ) Then
      if ( v_tgeometry.ST_Lrs_Dim()=0 ) THEN
        NULL; -- Leave alone
      Else -- Reduce
        -- Lrs_Dim = 3
        v_segment   :=        SELF.ST_To2D();
        v_tgeometry := v_tgeometry.ST_To2D();
      End If;
    ELSIF ( v_tgeometry.ST_Dims() = 4 AND SELF.ST_Dims() = 4 ) Then
      If ( v_tgeometry.ST_Lrs_Dim()=0 ) THEN
        v_segment   :=        SELF.ST_To3D(p_keep_measure=> 0,p_default_z=>NULL); -- SGG 4D
        v_tgeometry := v_tgeometry.ST_To3D(p_zordtokeep  => 3);
      ELSE
        v_segment   :=        SELF.ST_To3D(p_keep_measure=>0,p_default_z=>NULL); -- SGG 4D
        v_tgeometry := v_tgeometry.ST_To3D(p_zordtokeep=>case when v_tgeometry.ST_LRS_Dim()=3 then 4 else 3 end);
      END IF;
    End If;
    v_segment_geom := v_segment.ST_SdoGeometry();

    -- DEBUG dbms_output.put_line('  Compute closest point');
    BEGIN
      /* Trap possible
             ORA-01403: no data found: ORA-06512: at "MDSYS.SDO_VERSION", line 5 ORA-06512: at  "MDSYS.SDO_3GL"
      */
      MDSYS.SDO_GEOM.SDO_CLOSEST_POINTS(
           geom1     => v_tgeometry.geom,
           geom2     => v_segment_geom,
           tolerance => SELF.PrecisionModel.tolerance,
           unit      => p_unit,
           dist      => v_distance,
           geoma     => v_point_on_geom,
           geomb     => v_point_on_segment
      );
      -- DEBUG DEBUG.PrintGeom(v_point_on_segment,3,false,'  v_point_on_segment (SDO_CLOSEST_POINTS): ');
      EXCEPTION
        --WHEN NO_DATA_FOUND THEN
        --   Return NULL;
        WHEN geographic3D THEN
          -- Force 2D answer
          v_tgeometry    := v_tgeometry.ST_To2D();
          v_segment_geom :=   v_segment.ST_To2D().ST_SdoGeometry();
          MDSYS.SDO_GEOM.SDO_CLOSEST_POINTS(
            geom1     => v_tgeometry.geom,
            geom2     => v_segment_geom,
            tolerance => SELF.PrecisionModel.tolerance,
            unit      => p_unit,
            dist      => v_distance,
            geoma     => v_point_on_geom,
            geomb     => v_point_on_segment
         );
    END;
    -- DEBUG 
dbms_output.put_line('  Result of SDO_GEOM.SDO_CLOSEST_POINT, v_point_on_segment=' || case when v_point_on_segment is null then 'NULL' else DEBUG.PrintGeom(v_point_on_segment,3,0,null,0) end);

    -- Check if CLOSEST_POINTS worked
    --
    IF ( v_point_on_segment is null or v_point_on_segment.sdo_gtype is null ) THEN
      -- dbms_output.put_line('  Situation where SDO_GEOM.SDO_CLOSEST_POINTS could not resolve (eg point off the end of line)');
      -- Call Older version which is only OK for projected data.
      v_vertex := SELF.ST_PointToLineString(p_vertex=>&&INSTALL_SCHEMA..T_Vertex(p_geometry));
    ELSE
      v_vertex := &&INSTALL_SCHEMA..T_Vertex(v_point_on_segment);
      -- Circular Arc centre check -> closest will be centre
      if ( SELF.ST_isCircularArc()=1 ) then
         -- DEBUG dbms_output.put_line(' v_vertex: ' || v_vertex.ST_AsText());
         if ( v_vertex.x=0.0 and v_vertex.y = 0.0 ) then
           -- p_geometry must be centre of circular arc so all points are equidistant.
           -- Choose startPoint
           v_vertex := SELF.startCoord;
         end if;
      end if;
    End If;
   
    v_segment_length := case when SELF.ST_isCircularArc()=0 
                             then SELF.ST_Length(p_unit => p_unit)
                             else -- ROUGH until Function written
                                  SELF.startCoord.ST_Distance(v_vertex) + v_vertex.ST_Distance(SELF.endCoord,p_unit)
                          end;
    v_ratio          := case when SELF.ST_isCircularArc()=0 
                             then SELF.startCoord.ST_Distance(v_vertex,p_unit) / v_segment_length
                             else -- SGG SELF.ST_Compute_Ratio(v_vertex)
                                  SELF.startCoord.ST_Distance(v_vertex,p_unit) / v_segment_length
                         end;
dbms_output.put_line(' Ratio='||v_ratio || '  Length=' || v_segment_length);
    IF ( SELF.ST_isCircularArc() = 0 ) Then
        If ( SELF.ST_Lrs_Dim()=0 ) Then
          IF ( SELF.ST_Dims() in (3,4) ) Then
            v_vertex.Z := SELF.startCoord.z;
            v_vertex.W := v_segment_length * v_ratio;
            v_vertex.sdo_gtype := 4401;
          Else 
            v_vertex.Z := v_segment_length * v_ratio;
            v_vertex.sdo_gtype := 3301;
          End If;
        Else
          -- Now calculate Measure
          if ( SELF.ST_Lrs_Dim() = 3 ) Then
            v_vertex.z := SELF.startCoord.z + (SELF.endCoord.z - SELF.startCoord.z) * v_ratio; 
            v_vertex.sdo_gtype := 3301;
          elsif ( SELF.ST_Lrs_Dim() = 4 ) Then
            v_vertex.Z := SELF.startCoord.Z;
            v_vertex.w := SELF.startCoord.w + (SELF.endCoord.w - SELF.startCoord.w) * v_ratio; 
            v_vertex.sdo_gtype := 4401;
          End If;      
        End If;
    Else
dbms_output.put_line('Set Z if CircularArc and > 2D (See ST_PointToCircularArc)');
      -- Set Z if CircularArc and > 2D (See ST_PointToCircularArc)
      v_vertex.sdo_gtype := SELF.sdo_gtype - 1;
      v_vertex.z := case when SELF.ST_Lrs_Dim() = 0 and SELF.ST_Dims() = 2      then v_segment_length * v_ratio
                         when SELF.ST_Lrs_Dim() = 0 and SELF.ST_Dims() in (3,4) then SELF.startCoord.z
                         when SELF.ST_Lrs_Dim() = 3 and SELF.ST_Dims() = 3      then SELF.startCoord.z + (SELF.endCoord.z - SELF.startCoord.z) * v_ratio -- SGG Compute Measure
                         when SELF.ST_Lrs_Dim() = 3 and SELF.ST_Dims() = 4      then SELF.startCoord.w + (SELF.endCoord.w - SELF.startCoord.w) * v_ratio
                         when SELF.ST_Lrs_Dim() = 4 and SELF.ST_Dims() = 4      then SELF.startCoord.w + (SELF.endCoord.w - SELF.startCoord.w) * v_ratio
                     end;
    End If;

    -- DEBUG 
dbms_output.put_line('</ST_Closest> = ' || v_vertex.ST_AsText());
    RETURN v_Vertex;
  END ST_Closest;


  Member Function ST_ProjectPoint(p_vertex in &&INSTALL_SCHEMA..T_Vertex,
                                  p_unit   In varchar2 Default NULL)
           Return &&INSTALL_SCHEMA..T_Vertex 
  As
    geographic3D EXCEPTION;
    PRAGMA       EXCEPTION_INIT(
                    geographic3D,-13364
                 );
    v_vertex           &&INSTALL_SCHEMA..T_Vertex;
    v_segment          &&INSTALL_SCHEMA..T_Segment;
    v_point_on_point   mdsys.sdo_geometry;
    v_point_on_segment mdsys.sdo_geometry;
    v_distance         number;
    v_dim              PLS_INTEGER;

  Begin
    -- DEBUG dbms_output.put_line('<ST_ProjectPoint>');
    if ( p_vertex is null ) Then
      return null;
    end if;
    
    If ( NVL(p_vertex.ST_SRID(),-1) <> NVL(SELF.ST_SRID(),-1) ) Then 
      -- SGG: Throw exception?
      return p_vertex;
    End If;
    
    IF ( NVL(SELF.projected,1)=1 ) Then
      If ( SELF.ST_isCircularArc()=0 ) Then
        v_vertex := SELF.ST_PointToLineString(p_vertex=>p_vertex);
      Else
        v_vertex := SELF.ST_PointToCircularArc(p_vertex=>p_Vertex,
                                               p_unit  => p_unit);
      End If;
      Return v_vertex;
    End If;

    -- DEBUG dbms_output.put_line('  Projected=' || SELF.projected);

    -- DEBUG dbms_output.put_line('  Compute closest point with geometries as they are');
    BEGIN
      /* Trap possible
             ORA-01403: no data found: ORA-06512: at "MDSYS.SDO_VERSION", line 5 ORA-06512: at  "MDSYS.SDO_3GL"
      */
      MDSYS.SDO_GEOM.SDO_CLOSEST_POINTS(
           geom1     => p_vertex.ST_SdoGeometry(),
           geom2     => SELF.ST_SdoGeometry(),
           tolerance => SELF.PrecisionModel.tolerance,
           unit      => p_unit,
           dist      => v_distance,
           geoma     => v_point_on_point,
           geomb     => v_point_on_segment
      );
      EXCEPTION
        --WHEN NO_DATA_FOUND THEN
        --  RETURN NULL; Ensure error is visible
        WHEN geographic3D THEN
          -- Force 2D answer
          v_vertex  := v_vertex.ST_To2D();
          v_segment := SELF.ST_To2D();
          -- DEBUG dbms_output.put_line('  Geographic3D exception caught');
          MDSYS.SDO_GEOM.SDO_CLOSEST_POINTS(
            geom1     => v_vertex.ST_SdoGeometry(),
            geom2     => v_segment.ST_SdoGeometry,
            tolerance => SELF.PrecisionModel.tolerance,
            unit      => p_unit,
            dist      => v_distance,
            geoma     => v_point_on_point,
            geomb     => v_point_on_segment
         );
    END;
    -- DEBUG dbms_output.put_line('  After SDO_CLOSEST_POINTS');
    -- DEBUG debug.printGeom(v_point_on_point,   SELF.precisionModel.xy,false,p_vertex.Sdo_Gtype||' point_on_point    : ');
    -- DEBUG 
debug.printGeom(v_point_on_segment, SELF.precisionModel.xy,false,'     point_on_line ' || SELF.sdo_gtype||': ' );

    If ( p_vertex.ST_Dims() = 2 ) Then
      If ( SELF.ST_Dims() = 2 ) Then
        v_vertex := &&INSTALL_SCHEMA..t_vertex(v_point_on_segment);
      ElsIf ( SELF.ST_Dims() > 2 ) Then
        If ( SELF.ST_Lrs_Dim() = 0 ) Then
          v_vertex := &&INSTALL_SCHEMA..t_vertex(v_point_on_segment);
        else
          v_vertex           := &&INSTALL_SCHEMA..t_vertex(v_point_on_segment);
          v_vertex.z         := SELF.ST_LRS_Compute_Measure(p_vertex => &&INSTALL_SCHEMA..t_vertex(v_point_on_segment));
          v_vertex.sdo_gtype := 3301;
        End If;
      End If;
    ElsIf ( p_vertex.ST_Dims()=3 ) Then
      If ( SELF.ST_Dims()=2 ) Then
        v_vertex := &&INSTALL_SCHEMA..t_vertex(v_point_on_segment);
      Else        
        If ( SELF.ST_Lrs_Dim() = 0 ) Then
          v_vertex := &&INSTALL_SCHEMA..t_vertex(v_point_on_segment);
        else
          v_vertex           := &&INSTALL_SCHEMA..t_vertex(v_point_on_segment);
          v_vertex.z         := SELF.ST_LRS_Compute_Measure(p_vertex => &&INSTALL_SCHEMA..t_vertex(v_point_on_segment));
          v_vertex.sdo_gtype := 3301;
        End If;
      End If;
    ElsIf ( p_vertex.ST_Dims()=4 ) Then
      If ( SELF.ST_Dims() = 2 ) Then
          v_vertex := &&INSTALL_SCHEMA..t_vertex(v_point_on_segment);
      Else
        If ( SELF.ST_Lrs_Dim() = 0 ) Then
          v_vertex := &&INSTALL_SCHEMA..t_vertex(v_point_on_segment);
        else
          v_vertex   := &&INSTALL_SCHEMA..t_vertex(v_point_on_segment);
          v_vertex.z := SELF.ST_LRS_Compute_Measure(p_vertex => &&INSTALL_SCHEMA..t_vertex(v_point_on_segment));
          v_vertex.sdo_gtype := 3301;
        End If;
      End If;      
    End If;
    -- DEBUG dbms_output.put_line('  Returned vertex ' || v_vertex.ST_AsText());
    -- DEBUG dbms_output.put_line('</ST_ProjectPoint>');
    return v_vertex;
  End ST_ProjectPoint;

  Member Function ST_FindCircle
    Return &&INSTALL_SCHEMA..T_Vertex
  AS
    v_centre &&INSTALL_SCHEMA..T_Vertex;
    dA       NUMBER;
    dB       NUMBER;
    dC       NUMBER;
    dD       NUMBER;
    dE       NUMBER;
    dF       NUMBER;
    dG       NUMBER;
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
        -- Return empty T_Vertex with marker id of -9 to indicate no centre can be calculated.
        Return &&INSTALL_SCHEMA..T_Vertex(
                  p_id        => -9,
                  p_sdo_gtype => NULL,
                  p_sdo_srid  => NULL);
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

  Member Function ST_ComputeDeflectionAngle(p_segment in &&INSTALL_SCHEMA..T_Segment default null)
           return number 
  As
    v_bearing1         number;
    v_bearing2         number;
    v_deflection_angle number;
    v_vertex1          &&INSTALL_SCHEMA..T_Vertex;
    v_vertex2          &&INSTALL_SCHEMA..T_Vertex;
    v_vertex3          &&INSTALL_SCHEMA..T_Vertex;
  Begin
     if ( p_segment is null ) then
       if (SELF.ST_isCircularArc()=1) Then
          v_bearing1 := SELF.startCoord.ST_Bearing(
                           p_vertex    => SELF.midCoord,
                           p_projected => SELF.projected,
                           p_normalize => 0
                        );
          v_bearing2 := SELF.midCoord.ST_Bearing(
                           p_vertex    => SELF.endCoord,
                           p_projected => SELF.projected,
                           p_normalize => 0
                        ); 
       else
         return 0;
       end if;
    else
      v_bearing1 := SELF.startCoord.ST_Bearing(
                           p_vertex    => SELF.endCoord,
                           p_projected => SELF.projected,
                           p_normalize => 0
                    );
      v_bearing2 := p_segment.startCoord.ST_Bearing(
                           p_vertex    => p_segment.endCoord,
                           p_projected => SELF.projected,
                           p_normalize => 0
                    ); 
    End If;
    v_deflection_angle := v_bearing2 - v_bearing1;
    v_deflection_angle := case when v_deflection_angle > 180.0 
                               then v_deflection_angle - 360.0
                               when v_deflection_angle < -180.0
                               then v_deflection_angle + 360.0
                               else v_deflection_angle
                           end;
    return v_deflection_angle;
  End ST_ComputeDeflectionAngle;
    
  Member Function ST_ComputeTangentPoint(p_position  In VarChar2,
                                         p_fraction  In Number   default 0.0,
                                         p_unit      IN varchar2 default NULL)
  Return &&INSTALL_SCHEMA..T_Vertex
  AS
    c_i_invalid_position Constant Integer       := -20120;
    c_s_invalid_position Constant VarChar2(100) := 'p_position (*POSN*) must be one of START, MID, END, or FRACTION only.';
    c_i_invalid_fraction Constant Integer       := -20121;
    c_s_invalid_fraction Constant VarChar2(100) := 'When p_position = FRACTION, p_fraction must be between 0.0 and 1.0.';

    v_position         VarChar2(10) := UPPER(SUBSTR(NVL(p_position,'START'),1,10));
    v_angle            NUMBER;
    v_bearing          NUMBER;
    v_distance         NUMBER;
    v_deflection_angle NUMBER;
    v_arc_rotation     pls_integer;

    v_fraction         Number := NVL(p_fraction,0.0);
    v_centre           &&INSTALL_SCHEMA..T_Vertex;
    v_vertex           &&INSTALL_SCHEMA..T_Vertex;
    v_result           &&INSTALL_SCHEMA..T_Vertex;
  BEGIN
    -- DEBUG dbms_output.put_line('<ST_ComputeTangentPoint>('||v_position||','||p_fraction||')');
    IF ( v_position NOT IN ('START','MID','END','FRACTION')  ) THEN
      raise_application_error(c_i_invalid_position,
                      REPLACE(c_s_invalid_position,'*POSN*',v_position),true );
    END IF;

    IF ( v_position = 'FRACTION' and v_fraction not between 0.0 and 1.0 ) THEN
      raise_application_error(c_i_invalid_fraction,c_s_invalid_fraction,true );
    END IF;

    -- DEBUG dbms_output.put_line('  ST_isCircularArc()=' || SELF.ST_isCircularArc());
    IF (SELF.ST_isCircularArc()=0) THEN
      -- Return point on the segment instead
      Return case when v_position = 'START' or (v_position = 'FRACTION' and v_fraction = 0.0) then SELF.startCoord
                  when v_position = 'MID'   or (v_position = 'FRACTION' and v_fraction = 0.5) then SELF.ST_midPoint()
                  when v_position = 'END'   or (v_position = 'FRACTION' and v_fraction = 1.0) then SELF.endCoord
                  else SELF.ST_OffsetPoint(
                               p_ratio     => v_fraction,
                               p_offset    => 0.0,
                               p_unit      => p_unit
                       )
              end;
    END IF;

    --- Compute vertex on circular arc
    IF ( v_position = 'FRACTION' and v_fraction <> 0.0 and v_fraction <> 1.0 ) THEN
      v_vertex := SELF.ST_OffsetPoint(
                          p_ratio     => v_fraction,
                          p_offset    => 0.0,
                          p_unit      => p_unit
                  );
    ELSE
      v_vertex := case when v_position = 'START' or (v_position = 'FRACTION' and v_fraction = 0.0) then SELF.startCoord
                       when v_position = 'MID'                                                     then SELF.midCoord
                       when v_position = 'END'   or (v_position = 'FRACTION' and v_fraction = 1.0) then SELF.endCoord
                       ELSE                                                                        SELF.endCoord
                   END;
    END IF;
    -- DEBUG dbms_output.put_line('  vertex on boundary ' || v_vertex.ST_AsEWKT());

    -- ** <Compute tangent coordinate> **
    v_centre := SELF.ST_FindCircle(); -- z holds radius
    -- DEBUG dbms_output.put_line('  v_centre is '||v_centre.ST_AsText());
    v_distance := v_centre.z / 2.0;
    -- SGG: Honour Z
    v_centre.z := SELF.startCoord.z;
    v_centre.sdo_gtype := v_vertex.sdo_gtype;
    -- DEBUG dbms_output.put_line('  Modified v_centre is '||v_centre.ST_AsEWKT());
    -- ** </Compute tangent coordinate> **

    -- Compute bearing from point on circular arc to centre of circular arc
    v_bearing := v_vertex
                   .ST_Bearing(
                       p_vertex    => v_centre,
                       p_projected => SELF.projected,
                       p_normalize => 1
                   );

    -- Which direction is circular arc progressing?
    
    v_deflection_angle := SELF.ST_ComputeDeflectionAngle(NULL);
    v_arc_rotation     := SIGN(v_deflection_angle) * case when v_position = 'END' or v_fraction > 0.5 then 1 else -1 end;
    -- DEBUG dbms_output.put_line('  deflection angle '|| v_deflection_angle || ' arc rotation '|| v_arc_rotation );

    -- DEBUG dbms_output.put_line('  bearing to centre='|| Round(v_bearing,8)|| ' Modified Angle='|| (v_arc_rotation * 90.0) );

    -- Compute tangent point by where on arc our point resides.
    v_bearing := &&INSTALL_SCHEMA..COGO.ST_Normalize(v_bearing + (v_arc_rotation * 90.0));

    -- DEBUG dbms_output.put_line('  bearing from vertex to tangent point='||v_bearing);

    -- Create tangent point 1/2 radius distance from point on circular arc.
    v_result := v_vertex.ST_FromBearingAndDistance(v_bearing,v_distance,SELF.projected);
    -- DEBUG dbms_output.put_line('  result ' || v_result.ST_AsEWKT());
    
    -- DEBUG dbms_output.put_line('</ST_ComputeTangentPoint>');
    Return v_result;
  END ST_ComputeTangentPoint;

  Member Function ST_ComputeTangentLine(p_position  in VarChar2,
                                        p_fraction  In Number   default 0.0,
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
    v_starT_Vertex       &&INSTALL_SCHEMA..T_Vertex;
  Begin
    -- DEBUG dbms_output.put_line('<ST_ComputeTangentLine>('||v_position||','||p_fraction||')');
    IF (SELF.ST_isCircularArc()=0) THEN
      Return NULL;
    END IF;
    IF ( v_position NOT IN ('START','MID','END','FRACTION')  ) THEN
      raise_application_error(c_i_invalid_position,
                      REPLACE(c_s_invalid_position,'*POSN*',v_position),true );
    END IF;
    IF ( v_position = 'FRACTION' and v_fraction not between 0.0 and 1.0 ) THEN
      raise_application_error(c_i_invalid_fraction,c_s_invalid_fraction,true );
    END IF;
    -- FInd the point on the circularArc which is the tangent point

    IF ( v_position = 'FRACTION' ) THEN
      -- DEBUG dbms_output.put_line('  Computing start vertex by fraction');
      v_starT_Vertex := SELF.ST_OffsetPoint(
                     p_ratio     => v_fraction,
                     p_offset    => 0.0,
                     p_unit      => p_unit
                   );
    ELSE
      -- DEBUG dbms_output.put_line('  Computing start vertex by position');
      v_starT_Vertex := CASE v_position
                        WHEN 'START' THEN SELF.startCoord
                        WHEN 'MID'   THEN SELF.midCoord
                        WHEN 'END'   THEN SELF.endCoord
                        ELSE              SELF.endCoord
                        END;
      v_fraction := CASE v_position
                    WHEN 'START' THEN 0.0
                    WHEN 'MID'   THEN 0.5 --<< SGG Nope
                    WHEN 'END'   THEN 1.0
                    ELSE              1.0
                    END;
    END IF;
    -- DEBUG dbms_output.put_line('  Start vertex is ' || v_starT_Vertex.ST_AsText());

    -- Now compute tangent point 
    v_tangent_point := SELF.ST_ComputeTangentPoint(
                          p_position  => 'FRACTION',
                          p_fraction  => v_fraction,
                          p_unit      => p_unit
                       );
    -- DEBUG dbms_output.put_line('  Tangent Point is '||v_tangent_point.ST_AsEWKT());
    -- DEBUG dbms_output.put_line('</ST_ComputeTangentLine>');
    -- Now compute and return the tangent line.
    Return &&INSTALL_SCHEMA..T_Segment(

             p_segment_id => 1,
             p_startCoord => v_starT_Vertex,
             p_endCoord   => v_tangent_point,
             p_sdo_gtype  => SELF.sdo_gtype,
             p_sdo_srid   => SELF.sdo_srid
           );
  End ST_ComputeTangentLine;

  Member Function ST_OffsetPoint(p_ratio     IN NUMBER,
                                 p_offset    IN NUMBER,
                                 p_unit      IN VARCHAR2 Default NULL)

  Return &&INSTALL_SCHEMA..T_Vertex
  AS
    v_az               NUMBER;
    v_angle            NUMBER;
    v_vertex           &&INSTALL_SCHEMA..T_Vertex;
    v_centre           &&INSTALL_SCHEMA..T_Vertex;
    v_bearing          NUMBER;
    v_distance         NUMBER;
    v_measure_ratio    NUMBER;
    v_dir              Integer;
    v_linePt           &&INSTALL_SCHEMA..T_Vertex;
    v_delta            &&INSTALL_SCHEMA..T_Vertex;

    v_point            mdsys.sdo_geometry;
    v_deflection_angle Number;
    v_arc_rotation     pls_integer;

  BEGIN
    -- DEBUG dbms_output.put_line('<ST_OffsetPoint>('||p_ratio||','||p_offset||')');
    IF (SELF.ST_isEmpty()=1) THEN
      Return NULL;
    END IF;

    IF (p_ratio NOT BETWEEN 0 AND 1) THEN
      Return NULL;
    END IF;

    -- DEBUG dbms_output.put_line('  p_ratio ' || p_ratio || ' p_offset='||p_offset || ' SELF.ST_AsText()=' || SELF.ST_AsText(3));
    IF ( SELF.ST_IsCircularArc()=1 ) THEN
      -- DEBUG dbms_output.put_line('  ST_isCircularArc = 1');

      -- *** Short circuit if start/end coord.
      v_vertex := case when p_ratio = 0.0
                       Then SELF.startCoord
                       when p_ratio = 1.0
                       then SELF.endCoord
                       else NULL
                   end;
      -- DEBUG dbms_output.put_line('  short circuit vertex ' || case when v_vertex is null then 'NULL' else v_Vertex.ST_AsEWKT() end);
      if ( p_offset = 0.0 and v_vertex is not null ) then
        -- DEBUG dbms_output.put_line('</ST_OffsetPoint>');
        return v_vertex;
      end if;
      -- *** End Short Circuit 

      -- Compute common centre and radius
      --
      v_centre := SELF.ST_FindCircle();
      -- DEBUG dbms_output.put_line('  centre (' || case when v_centre is null then 'NULL' else v_centre.ST_AsEWKT() end||') Radius (' || v_centre.z||')');

      -- Get subtended angle ie angle of circular arc
      IF ( v_centre.id = -9 ) THEN
        RETURN NULL;
      END IF;
      -- Knock out Z as radius after creating offset adjusted distance
      v_distance         := v_centre.z+(p_offset*-1);
      v_centre.z         := SELF.startCoord.Z;
      v_centre.sdo_gtype := case when SELF.startCoord.sdo_gtype > 3300 then 3300 else SELF.startCoord.sdo_gtype end;
      -- DEBUG dbms_output.put_line('  centre ' || v_centre.ST_AsText());
      -- DEBUG dbms_output.put_line('  angleBetweenOriented ' || Angle.toDegrees(Angle.angleBetweenOriented(self.endCoord,v_centre,self.startCoord)));      

      -- ** Short Circuit
      If ( p_offset != 0.0 and v_vertex is not null ) then
        v_bearing := v_centre.ST_Bearing(
                       p_vertex    => v_vertex,
                       p_projected => SELF.projected,
                       p_normalize => 0
                     );
        -- DEBUG dbms_output.put_line('   SS: bearing is ' || v_bearing);
      Else 
        v_angle := &&INSTALL_SCHEMA..COGO.ST_Degrees(
                     v_centre.ST_SubtendedAngle(
                       SELF.startCoord,
                       SELF.EndCoord
                     )
                   );
        v_deflection_angle := SELF.ST_ComputeDeflectionAngle(NULL);
        v_arc_rotation     := SIGN(v_deflection_angle);
        -- DEBUG dbms_output.put_line('  rotation sign ' || v_arc_rotation);

        -- DEBUG dbms_output.put_line('  Subtended angle of whole circular arc at centre in degrees is  ' || v_angle);
        v_measure_ratio := (v_angle * p_ratio) / v_angle;
        -- DEBUG dbms_output.put_line('  measure_ratio= ' || v_measure_ratio);

        -- now get angle subtended by this measure ratio

        v_angle := p_ratio * v_angle;
        -- DEBUG dbms_output.put_line('  Subtended angle based on ratio of circular arc ' || v_angle);
        -- Turn subtended angle of ratio into a bearing
        v_bearing := v_centre.ST_Bearing(
                       p_vertex    => SELF.startCoord,
                       p_projected => SELF.projected,
                       p_normalize => 0
                     );
        -- DEBUG dbms_output.put_line('   bearing from centre to start is ' || v_bearing);
        v_bearing := &&INSTALL_SCHEMA..COGO.ST_Normalize(p_degrees => v_bearing + (v_arc_rotation*v_angle));
        -- DEBUG dbms_output.put_line('   Compute (Normalized) bearing from centre to tangent point is ' || v_bearing );
      End If;

      -- Offset point is bearing+@v_radius from centre
      -- Can't use sdo_util.point_at_bearing as "The point geometry must be based on a geodetic coordinate system."
      -- DEBUG dbms_output.put_line('   create vertex on circular arc using bearing/distance is ' || v_bearing || '/' || v_distance);
      v_vertex := v_centre.ST_FromBearingAndDistance(
                    v_bearing,
                    v_distance,
                    SELF.projected
                  );
      IF ( SELF.ST_Dims() > 2 ) THEN

        -- upscale v_vertex to pretend Measure
        v_vertex.sdo_srid  := SELF.ST_SRID();
        v_vertex.sdo_gtype := SELF.startCoord.ST_Sdo_GType();
        -- DEBUG dbms_output.put_line('Compute M for 2D circular arc point');
        v_vertex.z := case when SELF.ST_Dims()>=3
                           then SELF.startCoord.z + v_measure_ratio * (SELF.endCoord.z - SELF.startCoord.z) 
                           else NULL
                       end;
        v_vertex.w := case when SELF.ST_Dims()>3 AND SELF.ST_Lrs_Dim()=4
                           then SELF.startCoord.w + v_measure_ratio * (SELF.endCoord.w - SELF.startCoord.w) 
                           else NULL
                       end;
      End If;

      -- DEBUG dbms_output.put_line('  vertex on segment ' || v_Vertex.ST_AsEWKT());
    ELSE
      -- DEBUG dbms_output.put_line('  LineString: Compute base offset');
      v_az    := &&INSTALL_SCHEMA..COGO.ST_Radians(
                   p_degrees =>
                     SELF.StartCoord
                         .ST_Bearing(
                             p_vertex    => SELF.endCoord,
                             p_projected => SELF.projected,
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
      v_linePt := &&INSTALL_SCHEMA..T_Vertex(
                    p_x         => SELF.startCoord.x + p_ratio*(SELF.endCoord.x-SELF.startCoord.x),
                    p_y         => SELF.startCoord.y + p_ratio*(SELF.endCoord.y-SELF.startCoord.y),
                    p_z         => case when SELF.ST_Dims() >= 3 then SELF.startCoord.z + (p_ratio*(SELF.endCoord.z-SELF.startCoord.z)) else null end,
                    p_w         => case when SELF.ST_Dims()  = 4 then SELF.startCoord.w + (p_ratio*(SELF.endCoord.w-SELF.startCoord.w)) else null end,
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
      -- DEBUG dbms_output.put_line('ST_OffsetPoint ELSE: v_vertex ' || v_Vertex.ST_AsText());
    END IF;
    -- DEBUG dbms_output.put_line('Returned vertex is ' || v_Vertex.ST_AsEWKT());
    -- DEBUG dbms_output.put_line('</ST_OffsetPoint>');

    Return v_vertex;
  END ST_OffsetPoint;

  /* ST_OffsetBetween
  *  Computes offset point (left/-ve; right/+ve) at bi-sector of angle formed by SELF and p_segment
  */
  Member Function ST_OffsetBetween(p_segment    IN &&INSTALL_SCHEMA..T_Segment,
                                   p_offset     IN NUMBER,
                                   p_unit       IN VARCHAR2 Default NULL)
  Return &&INSTALL_SCHEMA..T_Vertex
  AS
    v_angle         NUMBER;
    v_bearing       NUMBER;
    v_offset        NUMBER := NVL(p_offset,0);
    v_centre        &&INSTALL_SCHEMA..T_Vertex;
    v_vertex        &&INSTALL_SCHEMA..T_Vertex;
    v_shared_vertex &&INSTALL_SCHEMA..T_Vertex;
    v_nexT_Vertex   &&INSTALL_SCHEMA..T_Vertex;
    v_mid_vertex    &&INSTALL_SCHEMA..T_Vertex;
    v_prev_vertex   &&INSTALL_SCHEMA..T_Vertex;
    v_segment       &&INSTALL_SCHEMA..T_Segment;
    v_geom          mdsys.sdo_geometry;
  BEGIN
    -- DEBUG dbms_output.put_line('<ST_OffsetBetween>');

    -- DEBUG dbms_output.put_line('      v_offset='||v_offset);
    -- DEBUG dbms_output.put_line('      SELF=' || SELF.ST_AsText() || ' p_segment=' || p_segment.ST_AsText());

    -- Find common point (normally p_segment's startCoord is SELF's endCoord)
    IF (    SELF.endCoord.ST_Equals(p_segment.startCoord, SELF.PrecisionModel.XY)=1 ) Then
      v_prev_vertex := &&INSTALL_SCHEMA..T_Vertex(SELF.startCoord);
      v_mid_vertex  := SELF.endCoord;
      v_nexT_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_segment.endCoord);
    ELSIF ( SELF.endCoord.ST_Equals(p_segment.endCoord,   SELF.PrecisionModel.XY)=1 ) Then
      v_prev_vertex := &&INSTALL_SCHEMA..T_Vertex(SELF.startCoord);
      v_mid_vertex  := SELF.endCoord;
      v_nexT_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_segment.StartCoord);
    ELSIF ( SELF.startCoord.ST_Equals(p_segment.startCoord,SELF.PrecisionModel.XY)=1 ) Then

      v_prev_vertex := &&INSTALL_SCHEMA..T_Vertex(SELF.endCoord);
      v_mid_vertex  := SELF.startCoord;
      v_nexT_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_segment.endCoord);
    ELSE
      -- They don't touch, return no intersection point
      RETURN NULL;
    END IF;

    IF ( v_offset = 0 ) THEN
      -- OffsetBetween is simply the shared point 
      Return &&INSTALL_SCHEMA..T_Vertex(v_mid_vertex);
    END IF;

    IF ( SELF.ST_isCircularArc()=1 ) THEN -- Is CircularArc
      v_prev_vertex := SELF.ST_ComputeTangentPoint('END');
      v_next_Vertex := p_segment.ST_ComputeTangentPoint('START');
    END IF;

    -- DEBUG dbms_output.put_line('      v_prev_vertex='||v_prev_vertex.ST_AsText() || '  v_mid_vertex=' ||v_mid_vertex.ST_AsText()  || ' v_nexT_Vertex='||v_nexT_Vertex.ST_AsText());
    -- DEBUG dbms_output.put_line('      v_mid_vertex.ST_Dims()='||v_mid_vertex.ST_Dims() || ' v_prev_vertex.ST_Dims()=' ||v_mid_vertex.ST_Dims()  || ' v_nexT_Vertex.ST_Dims()='||v_nexT_Vertex.ST_Dims());
    v_angle   := v_mid_vertex.ST_SubtendedAngle(v_prev_vertex,v_next_Vertex);
    -- DEBUG dbms_output.put('      ST_SubtendedAngle(degrees)='||&&INSTALL_SCHEMA..COGO.ST_Degrees(v_angle));
    -- v_distance := ABS(v_offset / sin(v_angle/2.0));
    v_angle   := &&INSTALL_SCHEMA..COGO.ST_Degrees(
                   p_radians  => v_angle/2.0,
                   p_normalize=> 0
                 );
    -- DEBUG dbms_output.put(' v_angle/2.0(degrees)='||v_angle);
    v_bearing := &&INSTALL_SCHEMA..COGO.ST_Normalize(
                   v_mid_vertex.ST_Bearing(
                     p_vertex    => v_nexT_Vertex,
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
    v_vertex := v_mid_vertex.ST_FromBearingAndDistance(v_Bearing,ABS(v_offset),SELF.projected);
    -- DEBUG dbms_output.put(' SELF.ST_Dims()='||SELF.ST_Dims());
    if ( SELF.ST_Dims() > 2 ) then
      v_vertex.z         := v_mid_vertex.z;
      v_vertex.sdo_gtype := SELF.sdo_gtype - 1;
      If ( SELF.ST_Dims() > 3 ) then
        v_vertex.w  := v_mid_vertex.w;
      End If;
    End If;
    v_vertex.id := SELF.endCoord.id;
    -- DEBUG dbms_output.put(' v_vertex='||v_vertex.ST_AsText());
    -- DEBUG dbms_output.put_line('</ST_OffsetBetween>');
    Return v_vertex;
  END ST_OffsetBetween;

  Member Function ST_PointAlong(p_segmentLengthFraction in Number)
  Return &&INSTALL_SCHEMA..T_Vertex
  As
    v_Fraction Number := NVL(p_segmentLengthFraction,0.0);
  Begin
    If ( SELF.ST_isCircularArc()=1 ) Then
      RETURN SELF.ST_ComputeTangentPoint(
                      p_position  => 'FRACTION',
                      p_fraction  => v_Fraction,
                      p_unit      => NULL
             );
    End If;

    -- DEBUG dbms_output.put_line('<ST_PointAlong>('||p_segmentLengthFraction||',' || SELF.ST_Dims()||','||SELF.ST_LRS_DIM()||')');
    return &&INSTALL_SCHEMA..T_Vertex( 
                   p_x         => SELF.startCoord.x + v_Fraction * (SELF.endCoord.x - SELF.startCoord.x),

                   p_y         => SELF.startCoord.y + v_Fraction * (SELF.endCoord.y - SELF.startCoord.y),
                   p_z         => case when SELF.ST_Dims()>=3
                                       then SELF.startCoord.z + v_Fraction * (SELF.endCoord.z - SELF.startCoord.z) 
                                       else NULL
                                   end,
                   p_w         => case when SELF.ST_Dims()>3 AND SELF.ST_Lrs_Dim()=4
                                       then SELF.startCoord.w + v_Fraction * (SELF.endCoord.w - SELF.startCoord.w) 
                                       else NULL
                                   end,
                   p_id        => 1,
                   p_sdo_gtype => SELF.startCoord.sdo_gtype,
                   p_sdo_srid  => SELF.SDO_SRID
          );
  End ST_PointAlong;

  Member Function ST_PointAlongOffset(
                     p_segmentLengthFraction in Number, 
                     p_offsetDistance        in Number
                  )
           Return &&INSTALL_SCHEMA..T_Vertex
  As
    dx       number;
    dy       number;
    len      number;
    ux       number;
    uy       number;
    offsetx  number;
    offsety  number;
    v_vertex &&INSTALL_SCHEMA..T_Vertex;
    v_Fraction Number := NVL(p_segmentLengthFraction,0.0);
  Begin
    -- DEBUG dbms_output.put_line('<ST_PointAlongOffset>('||p_segmentLengthFraction||','||','||p_offsetDistance||','|| SELF.ST_Dims()||','||SELF.ST_LRS_DIM()||')');
    If ( SELF.ST_isCircularArc()=1 ) Then
      -- Support Offset
      RETURN SELF.ST_ComputeTangentPoint(
                      p_position  => 'FRACTION',
                      p_fraction  => v_Fraction,
                      p_unit      => NULL
             );
    End If;

  	-- the point on the segment line 
    v_vertex := SELF.ST_PointAlong(p_segmentLengthFraction);
    -- DEBUG dbms_output.put_line('  v_vertex='||v_vertex.ST_AsText());

    dx       := SELF.endCoord.x - SELF.startCoord.x;
    dy       := SELF.endCoord.y - SELF.startCoord.y;
    len      := SQRT(dx * dx + dy * dy);
    ux       := 0.0;
    uy       := 0.0;
    if (p_offsetDistance != 0.0) then
      if (len <= 0.0) then
        return v_vertex;
        -- raise_application_error(-20001,'Cannot compute offset from zero-length line segment');
      end if;
      -- u is the vector that is the length of the offset, in the direction of the segment
      ux := p_offsetDistance * dx / len;
      uy := p_offsetDistance * dy / len;
    end if;
    -- the offset point is the seg point plus the offset vector rotated 90 degrees CCW
    offsetx := v_vertex.x - uy;

    offsety := v_vertex.y + ux;
    v_vertex.ST_SetCoordinate(p_x=>offsetx,p_y=>offsety,p_z=>v_vertex.z,p_w=>v_vertex.w);
    -- DEBUG dbms_output.put_line('</ST_PointAlongOffset>()='||v_vertex.ST_AsText());
    return v_vertex;
  End ST_PointAlongOffset;

  Member Function ST_Intersect2CircularArcs(p_segment   in &&INSTALL_SCHEMA..T_Segment,
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
      Return SELF.ST_Intersect(p_segment,p_unit);
    END IF;
    v_circle_1 :=      SELF.ST_FindCircle();

    v_circle_2 := p_segment.ST_FindCircle();
    IF ( v_circle_1.id = -9 or v_circle_2.id = -9 ) THEN
      Return SELF.ST_Intersect(p_segment,p_unit);
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
    v_d  := v_P0.ST_Distance(
                    p_vertex    => v_P1,
                    p_tolerance => SELF.PrecisionModel.tolerance,
                    p_unit      => p_unit
            );
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

    -- DEBUG dbms_output.put_line('<ST_IntersectCircle>');
    v_circular_arc := CASE WHEN SELF.ST_IsCircularArc()=1 THEN SELF ELSE p_segment END;
    v_line_segment := CASE WHEN SELF.ST_IsCircularArc()=0 THEN SELF ELSE p_segment END;
    v_arc_length   := v_circular_arc.ST_Length(p_unit);
    v_line_length  := v_line_segment.ST_Length(p_unit);
    v_centre       := v_circular_arc.ST_FindCircle(); -- We have already checked if p_circular_arc is indeed a circular arc.
    IF ( v_centre.id = -9 ) Then
    -- DEBUG dbms_output.put_line('</ST_IntersectCircle>');
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

    -- DEBUG dbms_output.put_line('    v_p1: '||v_p1.ST_AsText());
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
    -- DEBUG dbms_output.put_line('    v_p2: '||v_p2.ST_AsText());

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
    v_arc_length_2 := v_circular_arc_2.ST_Length(p_unit);
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
      -- DEBUGdbms_output.put_line('   1. Intersection point is within circular arc segment: Assign it as nearest point on curve.');
      IF ( SELF.ST_isCircularArc()=1 ) THEN
        -- SELF is circular arc
        v_iPoints.midCoord := new T_Vertex(v_p1);
      ELSE 
        -- p_segment is Circular Arc
        v_iPoints.endCoord := new T_Vertex(v_p1);
        -- DEBUG dbms_output.put_line('</ST_IntersectCircle>');
      END IF;
    END IF;

    -- DEBUG dbms_output.put_line('   2. Now find the intersection with the linestring.');
    -- DEBUG dbms_output.put_line('   3. Find the closest point on the linear segment'); 
    v_dist_int_pt2lineStart := v_iPoints.startCoord.ST_Distance(v_line_segment.startCoord,SELF.PrecisionModel.tolerance,p_unit);
    v_dist_int_pt2lineEnd   := v_iPoints.startCoord.ST_Distance(v_line_segment.endCoord,  SELF.PrecisionModel.tolerance,p_unit);

    -- DEBUG dbms_output.put_line('   v_dist_int_pt2lineStart start(' || v_dist_int_pt2lineStart||') + v_dist_int_pt2lineEnd('||v_dist_int_pt2lineEnd||')= '||(ROUND(v_dist_int_pt2LineStart,6) + ROUND(v_dist_int_pt2LineEnd,6)) );
    IF ( ROUND(v_line_length,6) = ROUND(v_dist_int_pt2LineStart,6) + ROUND(v_dist_int_pt2LineEnd,6) ) THEN
      -- DEBUG dbms_output.put_line('   3.1 intersection point is within line segment: Assign it as nearest point on line.');
      IF ( SELF.ST_isCircularArc()=1 ) THEN
        -- SELF is circular arc
        v_iPoints.endCoord := new T_Vertex(v_iPoints.startCoord);
      ELSE 
        -- p_segment is Circular Arc
        v_iPoints.midCoord := new T_Vertex(v_iPoints.startCoord);
      END IF;
      IF ( v_within_arc ) THEN
        -- DEBUG dbms_output.put_line('   3.2 Intersection point is within both segments, return it.');
        -- DEBUG dbms_output.put_line('       Intersection Points are ' || v_iPoints.ST_AsText());
        -- DEBUG dbms_output.put_line('</ST_IntersectCircle>');
        Return v_iPoints;
      END IF;
    ELSE
      -- DEBUG dbms_output.put_line('   3.1 Intersection point is Near Line.');
      IF ( v_dist_int_pt2LineStart = LEAST(v_dist_int_pt2LineStart,v_dist_int_pt2LineEnd) ) THEN
        -- DEBUG dbms_output.put_line('       3.2 Is Near Start');
        v_iPoints.midCoord := new T_Vertex(SELF.startCoord);
      ELSE
       -- DEBUG dbms_output.put_line('       3.2 Is Near End');
       v_iPoints.midCoord := new T_Vertex(SELF.endCoord);
      END IF;

    END IF;

    IF ( v_within_arc ) THEN
      -- We are finished
      -- DEBUG dbms_output.put_line('      Intersection Points are ' || v_iPoints.ST_AsText());
      -- DEBUG dbms_output.put_line('</ST_IntersectCircle>');
      Return v_iPoints;
    END IF;

    -- DEBUG dbms_output.put_line('   4. Compute Closest Circular Arc Point.');
    -- DEBUG dbms_output.put_line('      TODO: MidCoord Closest?');
    --v_pt1_line               := v_line_segment.ST_Distance(p_vertex=>v_p1,p_tolerance=>p_tolerance,p_unit=>p_unit);
    --v_pt1_arc                := v_circular_arc.ST_Distance(p_vertex=>v_p1,p_tolerance=>p_tolerance,p_unit=>p_unit);

    v_dist_int_pt2CurveStart := v_iPoints.startCoord.ST_Distance(v_circular_arc.startCoord,SELF.PrecisionModel.XY,p_unit);
    v_dist_int_pt2CurveEnd   := v_iPoints.startCoord.ST_Distance(v_circular_arc.endCoord,  SELF.PrecisionModel.XY,p_unit);

    -- DEBUG dbms_output.put_line('     v_dist_int_pt2CurveStart=' || v_dist_int_pt2CurveStart);  
    -- DEBUG dbms_output.put_line('       v_dist_int_pt2CurveEnd=' || v_dist_int_pt2CurveEnd);
    v_vertex := case when v_dist_int_pt2CurveStart = LEAST(v_dist_int_pt2CurveStart,v_dist_int_pt2CurveEnd) 
                     then v_circular_arc.startCoord
                     else v_circular_arc.endCoord
                end;
    -- DEBUG dbms_output.put_line('      4.1 Point is ' || v_vertex.ST_AsText());
     -- Assign start/end coord to midCoord
    IF ( SELF.ST_isCircularArc()=1 ) THEN
      v_iPoints.midCoord := v_vertex;
    ELSE
      v_iPoints.endCoord := v_vertex;
    END IF;      
    -- DEBUG dbms_output.put_line('      Intersection Points are ' || v_iPoints.ST_AsText());
    -- DEBUG dbms_output.put_line('</ST_IntersectCircle>');
    Return v_iPoints; 
  END ST_IntersectCircularArc;

  Member Function ST_Intersect(p_segment   IN &&INSTALL_SCHEMA..T_Segment,
                               p_unit      IN varchar2 Default NULL)
           Return &&INSTALL_SCHEMA..T_Segment
  As
    v_a            number;
    v_p1           &&INSTALL_SCHEMA..T_Vertex;
    v_p2           &&INSTALL_SCHEMA..T_Vertex;
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
    -- DEBUG dbms_output.put_line('<ST_Intersect>');
    -- DEBUG dbms_output.put_line(SELF.ST_AsText()||'.ST_Intersect(' || p_segment.ST_Astext()||')');

    If ( p_segment is null       OR
        p_segment.ST_isEmpty()=1 OR 
             SELF.ST_isEmpty()=1 ) Then
        -- DEBUG dbms_output.put_line('</ST_Intersect>');
       Return null;
    End If;

    IF (    SELF.ST_isCircularArc() = 1 AND p_segment.ST_isCircularArc() = 1 ) THEN
      -- DEBUG dbms_output.put_line('   Two CircularArcs: Call ST_Intersect2CircularArcs');
      v_iWD := SELF.ST_Intersect2CircularArcs(
                       p_segment,
                       p_unit);
    ELSIF ( NOT ( SELF.ST_isCircularArc() = 0 AND p_segment.ST_isCircularArc() = 0 ) ) THEN
      -- DEBUG dbms_output.put_line('   One is a CircularArc: Call ST_IntersectCircularArc');
      v_iWD := SELF.ST_IntersectCircularArc(
                       p_segment,
                       p_unit);
    END IF;
    IF ( SELF.ST_isCircularArc() = 1 OR p_segment.ST_isCircularArc() = 1 ) THEN
      -- DEBUG dbms_output.put_line('</ST_Intersect>');
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
      -- DEBUG dbms_output.put_line('</ST_Intersect>');
      Return new &&INSTALL_SCHEMA..T_Segment(v_iWD);
    Else
      -- No intersection
      v_iPoints := new &&INSTALL_SCHEMA..T_Segment();
      v_iPoints.segment_id := -99;
      -- DEBUG dbms_output.put_line('</ST_Intersect>');
      Return new &&INSTALL_SCHEMA..T_Segment(v_iWD);
    END If;

  End ST_Intersect;

  Member Function ST_IntersectDetail(p_segment   in &&INSTALL_SCHEMA..T_Segment,
                                     p_unit      in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_Segment
  AS
    v_dx1          NUMBER;
    v_dY1          NUMBER;
    v_dx2          NUMBER;
    v_dy2          NUMBER;
    v_t1           NUMBER;
    v_t2           NUMBER;

    v_denominator  NUMBER;
    v_iPoints      &&INSTALL_SCHEMA..T_Segment;
    v_tesT_Segment &&INSTALL_SCHEMA..T_Segment;
    v_intersection &&INSTALL_SCHEMA..T_Segment
            := new &&INSTALL_SCHEMA..T_Segment (
                     p_segment_id => 1,
                     p_startCoord => new T_Vertex(p_id=>1,p_sdo_gtype=>SELF.sdo_gtype,p_sdo_srid=>SELF.sdo_srid),
                     p_midCoord   => new T_Vertex(p_id=>2,p_sdo_gtype=>SELF.sdo_gtype,p_sdo_srid=>SELF.sdo_srid),
                     p_endCoord   => new T_Vertex(p_id=>3,p_sdo_gtype=>SELF.sdo_gtype,p_sdo_srid=>SELF.sdo_srid),
                     p_sdo_gtype  => SELF.Sdo_Gtype,
                     p_sdo_srid   => SELF.sdo_srid
               );


  BEGIN
    -- DEBUG dbms_output.put_line('<ST_IntersectDetail>');
    -- TODO: Support circular arcs.
    IF ( SELF.ST_isCircularArc() = 1 OR p_segment.ST_isCircularArc() = 1 ) THEN
      -- DEBUG dbms_output.put_line('<ST_IntersectWithCircularArc>');
      v_iPoints := SELF.ST_Intersect(p_segment   => p_segment,
                                     p_unit      => p_unit);
    -- DEBUG dbms_output.put_line('  v_intersection='||v_iPoints.ST_AsText());
    -- DEBUG dbms_output.put_line('</ST_IntersectWithCircularArc>');
    -- DEBUG dbms_output.put_line('</ST_IntersectDetail>');
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

    -- DEBUG dbms_output.put_line('  intersection point= ' || v_intersection.startCoord.ST_Round(6).ST_AsText());

    -- Compute by ratio any z value
    If ( SELF.ST_Dims() = 3 and p_segment.ST_Dims() = 3 ) Then
       -- Note: we do the ratio via 2D length of segments not 3D.

       v_tesT_Segment := &&INSTALL_SCHEMA..T_Segment(
                          p_segment_id => 0,
                          p_startCoord => SELF.startCoord.ST_To2D(),
                          p_endCoord   => v_intersection.startCoord.ST_To2D(),
                          p_sdo_gtype  => 2002,
                          p_sdo_srid   => SELF.sdo_srid
                        );
       v_intersection.startCoord.z := SELF.startCoord.z + ( ( v_tesT_Segment.ST_Length(p_unit) / SELF.ST_To2D().ST_Length(p_unit) ) * (SELF.endCoord.z-SELF.startCoord.z) );
       v_tesT_Segment.startCoord   := p_segment.startCoord.ST_To2D();
       v_tesT_Segment.endCoord     := v_intersection.startCoord.ST_To2D();
       v_intersection.endCoord.z   := p_segment.startCoord.z + ( ( v_tesT_Segment.ST_Length(p_unit) / p_segment.ST_To2D().ST_Length(p_unit) ) * (p_segment.endCoord.z-p_segment.startCoord.z) );
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
    -- DEBUG dbms_output.put_line('</ST_IntersectDetail>');    
    Return v_intersection;
  END ST_IntersectDetail;

  Member Function ST_IntersectDescription(p_segment    in &&INSTALL_SCHEMA..T_Segment,
                                          p_unit       in varchar2 default null)
           Return varchar2
  AS
    v_dPrecision             PLS_Integer := NVL(SELF.PrecisionModel.XY,6);

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
    -- DEBUG dbms_output.put_line('<ST_IntersectDescription>');
    IF (p_segment is null) THEN
      Return 'NULL';
    END IF;

    -- Short Circuit: Check for common point at either end
    --
    IF ( SELF.StartCoord.ST_Equals(p_vertex => p_segment.startCoord, p_dPrecision=>SELF.PrecisionModel.XY) = 1 ) THEN
      RETURN 'Intersection at Start Point 1 and Start Point 2';
    END IF;

    IF ( SELF.startCoord.ST_Equals(p_vertex => p_segment.EndCoord, p_dPrecision=>SELF.PrecisionModel.XY) = 1 ) THEN
      RETURN 'Intersection at Start Point 1 and End Point 2';
    END IF;
    IF ( SELF.EndCoord.ST_Equals(p_vertex => p_segment.startCoord, p_dPrecision=>SELF.PrecisionModel.XY) = 1 ) THEN
      RETURN 'Intersection at End Point 1 and Start Point 2';
    END IF;
    IF ( SELF.EndCoord.ST_Equals(p_vertex => p_segment.EndCoord, p_dPrecision=>SELF.PrecisionModel.XY) = 1 ) THEN
      RETURN 'Intersection at End Point 1 and End Point 2';
    END IF;

    -- Intersection not at one of ends.
    -- Compute intersection.
    --

    v_intersection_points := SELF.ST_IntersectDetail(p_segment);
    -- Debug dbms_output.put_line('  intersection point= ' || v_intersection_points.startCoord.ST_AsText());

    -- Easy case: parallel
    --
    IF ( v_intersection_points.startCoord.x = -9 ) THEN
      -- The lines are parallel.
      RETURN 'Parallel';
    END IF;

    v_intersection_point   := v_intersection_points.startCoord;
    v_intersection_point_1 := v_intersection_points.midCoord;
    v_intersection_point_2 := v_intersection_points.endCoord;


    -- DEBUG dbms_output.put_line('  Segment 1 Start Point: ' || SELF.startCoord.ST_AsText());
    -- DEBUG dbms_output.put_line('              End Point: ' || SELF.endCoord.ST_AsText());
    -- DEBUG dbms_output.put_line('  Segment 2 Start Point: ' || p_segment.startCoord.ST_AsText());
    -- DEBUG dbms_output.put_line('              End Point: ' || p_segment.endCoord.ST_AsText());
    -- DEBUG dbms_output.put_line('     Intersection Point: ' || v_intersection_point.ST_AsText());
    -- DEBUG dbms_output.put_line('             Point on 1: ' || v_intersection_point_1.ST_AsText());
    -- DEBUG dbms_output.put_line('             Point on 2: ' || v_intersection_point_2.ST_AsText());

    -- Set up test short hand variables
    INT_POINT_EQ_INT_POINT_1 := v_intersection_point.ST_Equals(p_vertex=>v_intersection_point_1,p_dPrecision=>SELF.PrecisionModel.XY);
    INT_POINT_EQ_INT_POINT_2 := v_intersection_point.ST_Equals(p_vertex=>v_intersection_point_2,p_dPrecision=>SELF.PrecisionModel.XY);
    -- DEBUG dbms_output.put_line('      INT_POINT_EQ_INT_POINT_1 = '||INT_POINT_EQ_INT_POINT_1 || '; INT_POINT_EQ_INT_POINT_2   = '||INT_POINT_EQ_INT_POINT_2);


    INT_POINT_1_EQ_START_POINT_1 := v_intersection_point_1.ST_Equals(p_vertex=>SELF.startCoord,p_dPrecision=>SELF.PrecisionModel.XY);
    INT_POINT_1_EQ_END_POINT_1   := v_intersection_point_1.ST_Equals(p_vertex=>SELF.endCoord,  p_dPrecision=>SELF.PrecisionModel.XY);
    -- DEBUG dbms_output.put_line('  INT_POINT_1_EQ_START_POINT_1 = '||INT_POINT_1_EQ_START_POINT_1 || '; INT_POINT_1_EQ_END_POINT_1 = '||INT_POINT_1_EQ_END_POINT_1);

    INT_POINT_2_EQ_START_POINT_2 := v_intersection_point_2.ST_Equals(p_vertex=>p_segment.startCoord,p_dPrecision=>SELF.PrecisionModel.XY);
    INT_POINT_2_EQ_END_POINT_2   := v_intersection_point_2.ST_Equals(p_vertex=>p_segment.endCoord,  p_dPrecision=>SELF.PrecisionModel.XY);
    -- DEBUG dbms_output.put_line('  INT_POINT_2_EQ_START_POINT_2 = '||INT_POINT_2_EQ_START_POINT_2 || '; INT_POINT_2_EQ_END_POINT_2 = '||INT_POINT_2_EQ_END_POINT_2);

    v_segment_1_description :=
              CASE WHEN v_intersection_point.ST_Equals(p_vertex=>SELF.startCoord,p_dPrecision=>SELF.PrecisionModel.XY) = 1
                   THEN 'at Start Point 1'
                   WHEN v_intersection_point.ST_Equals(p_vertex=>SELF.endCoord,p_dPrecision=>SELF.PrecisionModel.XY) = 1
                   THEN 'at End Point 1'
                   WHEN INT_POINT_EQ_INT_POINT_1=1
                   THEN 'Within 1'
                   ELSE ''
                END;

    v_segment_2_description :=
              CASE WHEN v_intersection_point.ST_Equals(p_vertex=>p_segment.startCoord,p_dPrecision=>SELF.PrecisionModel.XY) = 1
                   THEN 'at Start Point 2'
                   WHEN v_intersection_point.ST_Equals(p_vertex=>p_segment.endCoord,p_dPrecision=>SELF.PrecisionModel.XY) = 1
                   THEN 'at End Point 2'
                   WHEN INT_POINT_EQ_INT_POINT_2=1
                   THEN 'Within 2'
                   ELSE ''
                END;

    -- DEBUG dbms_output.put_line('  v_segment_1_description='||v_segment_1_description || '; v_segment_2_description='||v_segment_2_description);

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
    -- DEBUG dbms_output.put_line('  v_description='||v_description);
    -- DEBUG dbms_output.put_line('</ST_IntersectDescription>');
    Return v_description;
  END ST_IntersectDescription;

  Member Function ST_isReversed(p_other in &&INSTALL_SCHEMA..T_Segment)
           Return integer
  As
    v_self_bearing  number;
    v_other_bearing number;
  Begin
    -- Check reversal of direction as indication that a segment should be ignored.
    --
    v_self_bearing  := ROUND(SELF.ST_Bearing   (p_normalize=>1),0);  ---- << WHY IS THIS ROUND(..,0) and NOT ROUND(...,8)? or no ROUND?
    v_other_bearing := ROUND(p_other.ST_Bearing(p_normalize=>1),0);
    -- DEBUG dbms_output.put_line('Bearing (Self): ' || v_self_Bearing || ' (Other): ' || v_other_bearing || ' (Difference): ' || ABS(v_other_bearing - v_self_bearing));
    Return case when (ABS(v_other_bearing - v_self_bearing) = 180) then 1 else 0 end;
  End ST_isReversed;

  Member Function ST_LineSubstring(p_start_fraction In Number   Default 0.0,
                                   p_end_fraction   In Number   Default 1.0,
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
                                    p_unit      => p_unit
                            );
    IF ( v_start_fraction = v_end_fraction ) Then
      v_segment.endCoord := &&INSTALL_SCHEMA..T_Vertex(v_segment.startCoord);
      RETURN v_segment;
    End If;
    v_segment.endCoord := SELF.ST_OffsetPoint(
                           p_ratio     => v_end_fraction,
                           p_offset    => 0.0,
                           p_unit      => p_unit
                          );
    IF ( SELF.ST_IsCircularArc() = 1 ) THEN
      -- DEBUG dbms_output.put_line('midCoord: ' || TO_CHAR(v_start_fraction + ((v_end_fraction - v_start_fraction) / 2.0)));
      v_segment.midCoord := SELF.ST_OffsetPoint(
                              p_ratio     => v_start_fraction + ((v_end_fraction - v_start_fraction) / 2.0),
                              p_offset    => 0.0
                            );
    END IF;
    Return v_segment;
  End ST_LineSubstring;

  Member Function ST_Lrs_Dim
  Return Integer Deterministic
  As
  Begin
     Return case when SELF.sdo_gtype is null then 0 else trunc(mod(SELF.sdo_gtype,1000)/100) end;
  End ST_Lrs_Dim;

  Member Function ST_LRS_isMeasured
           Return Integer
  Is
  Begin
     return CASE WHEN SELF.ST_LRS_Dim() <> 0
                 THEN 1
                 ELSE 0
             END;
  End ST_LRS_isMeasured;
  
  Member Function ST_LRS_Measure_Length( p_unit      IN VARCHAR2 Default NULL )
  Return Number
  AS
  BEGIN
    Return CASE WHEN SELF.ST_Lrs_Dim() = 0 THEN SELF.ST_Length(p_unit => p_unit)
                WHEN SELF.ST_Lrs_Dim() = 3 THEN (SELF.endCoord.z - SELF.startCoord.z)
                WHEN SELF.ST_Lrs_Dim() = 4 THEN (SELF.endCoord.w - SELF.startCoord.w)
                ELSE 0.0
            END;
  END ST_LRS_Measure_Length;

  Member Function ST_LRS_Add_Measure(p_start_measure IN NUMBER   Default NULL,
                                     p_end_measure   IN NUMBER   Default NULL,
                                     p_unit          IN VARCHAR2 Default NULL)
           Return &&INSTALL_SCHEMA..T_Segment 
  As
    v_measure_ord      pls_integer := 0;
    v_start_measure    number;
    v_end_measure      number;
    v_range_measure    NUMBER := 0;
    v_segment          &&INSTALL_SCHEMA..T_Segment;
    v_centre           &&INSTALL_SCHEMA..T_Vertex;
    v_radius           NUMBER;
    v_length           NUMBER := 0;
    v_arc_Angle2Mid    NUMBER := 0;
    v_arc_Length2Mid   NUMBER := 0;
    v_return_dims      pls_integer := 3;
    v_return_segment   &&INSTALL_SCHEMA..T_Segment;
    v_geom             mdsys.sdo_geometry;
  Begin
    IF ( SELF.ST_LRS_isMeasured()=1 ) Then
       RETURN SELF;
    End If;
    -- DEBUG dbms_output.put_line('<ST_LRS_Add_Measure>');
    v_measure_ord   := SELF.ST_Dims() + 1;
    v_start_measure := NVL(p_start_measure,0);
    v_length        := SELF.ST_Length(p_unit=>p_unit);
    v_end_measure   := NVL(p_end_measure,v_length);
    v_range_measure := v_end_measure-v_start_measure;
    v_return_dims   := SELF.ST_Dims()+1;
    -- DEBUG dbms_output.put_line('  MeasureOrd= ' || v_measure_ord || CHR(10) ||'  Start/End/Range Measures= ' || v_start_measure||'/'||v_end_measure||'/'||v_range_measure || CHR(10) ||'  Return Dims= ' || v_return_dims);

    v_segment := SELF.ST_Self();
    if ( v_measure_ord = 3 ) Then
       v_segment.startCoord.z := v_start_measure;
    ElsIf ( v_measure_ord = 4 ) Then
       v_segment.startCoord.w := v_start_measure;
    End If;
    v_segment.startCoord.sdo_gtype := (v_return_dims*1000)+(v_measure_ord*100)+1;
    -- DEBUG dbms_output.put_line('  v_segment.startCoord after start measure assigned= ' || v_segment.startCoord.ST_AsText());

    if ( v_segment.ST_isCircularArc()=1 ) Then
      -- DEBUG dbms_output.put_line('  IS Circular Arc');
      v_centre           := v_segment.ST_FindCircle();
      v_radius           := v_centre.z;
      v_centre.z         := v_segment.startCoord.z;
      v_centre.sdo_gtype := v_segment.startCoord.sdo_gtype;
      v_arc_Angle2Mid    := Angle.toDegrees(ANGLE.angleBetween(v_segment.startCoord,v_centre,v_segment.midCoord));
      v_arc_Length2Mid := &&INSTALL_SCHEMA..COGO.ComputeArcLength(v_radius,v_arc_Angle2Mid);
      -- DEBUG dbms_output.put_line('  v_arc_Angle2Mid='||v_arc_Angle2Mid || CHR(10) || '  v_arc_Length2Mid='||v_arc_Length2Mid);

      -- DEBUG dbms_output.put_line('  Assigning Z/W to midCoord');
      if ( v_measure_ord = 3 ) Then
        v_segment.midCoord.z := v_segment.startCoord.z + (v_range_measure * (v_arc_length2mid/v_length));
        v_segment.endCoord.z := v_length;
      ElsIf ( v_measure_ord = 4 ) Then
        v_segment.midCoord.w := v_segment.startCoord.w + (v_range_measure * (v_arc_length2mid/v_length));
        v_segment.endCoord.w := v_length;
      End If;
      v_segment.midCoord.sdo_gtype := (v_return_dims*1000)+(v_measure_ord*100)+1;
      -- DEBUG dbms_output.put_line('    v_segment.midCoord after midCoord measure assigned= ' || v_segment.startCoord.ST_AsText());
    End If;
    -- DEBUG dbms_output.put_line('  Assigning Z/W to endCoord');
    If ( v_measure_ord = 3 ) Then
      v_segment.endCoord.z := v_segment.startCoord.z + (v_length * (v_range_measure/v_length));
    ElsIf ( v_measure_ord = 4 ) Then
      v_segment.endCoord.w := v_segment.startCoord.w + (v_length * (v_range_measure/v_length));
    End If;
    v_segment.endCoord.sdo_gtype := (v_return_dims*1000)+(v_measure_ord*100)+1;
    -- DEBUG dbms_output.put_line('  v_segment.endCoord after measures assigned= ' || v_segment.endCoord.ST_AsText());

    v_segment.sdo_gtype := (v_return_dims*1000)+(v_measure_ord*100)+2;

    -- DEBUG dbms_output.put_line('  '||v_segment.ST_AsEWKT());
    -- DEBUG dbms_output.put_line('</ST_LRS_Add_Measure>');
    return v_segment;
  End ST_LRS_Add_Measure;

  Member Function ST_LRS_Compute_Measure(p_vertex    In &&INSTALL_SCHEMA..T_Vertex,
                                         p_unit      IN varchar2 Default null)
  Return number
  As
    v_vertex                  &&INSTALL_SCHEMA..T_Vertex;
    v_start_to_point_Segment  &&INSTALL_SCHEMA..T_Segment;
    v_self                    &&INSTALL_SCHEMA..T_Segment;
    v_segment_length          number;
    v_start_to_point_distance number;
    v_measure                 number;
    v_measure_Length          number;
    v_projected               pls_integer   := 1;
    v_unit                    varchar2(100) := p_unit;
  Begin
    -- DEBUG dbms_output.put_line('<ST_LRS_Compute_Measure>');

    IF ( p_vertex is null ) THEN
      RETURN NULL;
    END IF;

    -- If not measured compute using length
    v_self := case when SELF.ST_HasM() = 0 
                   then SELF.ST_LRS_Add_Measure(
                           p_start_measure => NULL,
                           p_end_measure   => NULL,
                           p_unit          => p_unit
                        )
                    else SELF.ST_Self()
                End;

    v_projected := v_self.projected;
    IF ( v_projected=1 ) Then
      v_vertex := case when v_self.ST_isCircularArc()=0 
                       then v_self.ST_PointToLineString(&&INSTALL_SCHEMA..T_Vertex(p_vertex))
                       else v_self.ST_PointToCircularArc(&&INSTALL_SCHEMA..T_Vertex(p_vertex))
                   end;
      -- DEBUG dbms_output.put_line('   Projected: After Call to ST_PointToCircularArc/LineString returned v_vertex='||v_vertex.ST_AsText());
      v_measure := case v_vertex.ST_LRS_Dim()
                   when 0 then null 
                   when 3 then v_vertex.z
                   when 4 then v_vertex.w
                   end;
      -- DEBUG dbms_output.put_line('   v_measure= '||v_measure);
      -- DEBUG dbms_output.put_line('</ST_LRS_Compute_Measure>');
      Return v_measure;
    End If;
    
    -- *************
    -- Projected = 0 ie geodetic/geographic/geographic3d
    -- *************
    
    -- Is supplied point on line?
    --
    if (v_self.ST_isPointOnSegment(p_vertex,p_unit)=1) Then
      -- vertex is already on circularArc or LineString.
      v_vertex := p_vertex;
      -- DEBUG dbms_output.put_line('  p_vertex is already on segment');
      -- If snapped vertex already has Measure, return it    
      If ( v_vertex.ST_Lrs_Dim()<>0 ) /* SGG AND v_vertex.z/w is not null */ Then
        return case v_vertex.ST_Lrs_Dim() when 3 then v_vertex.z when 4 then v_vertex.w end;
      End If;
    Else
      -- ST_Closest does not compute Z or M
      -- ST_Closest returns vertex snapped to segment.
      v_vertex := v_self.ST_Closest(
                           p_geometry => p_vertex.ST_SdoGeometry(),
                           p_unit     => v_unit
                         );
      -- DEBUG 
      dbms_output.put_line('  AFTER CLOSEST: v_vertex='||v_vertex.ST_AsText());
    End If;

    -- DEBUG dbms_output.put_line('  measure='||case v_vertex.ST_Lrs_Dim() when 0 then v_vertex.z when 3 then v_vertex.z when 4 then v_vertex.w end);
    
    v_segment_length := v_self.ST_Length(p_unit => p_unit);
    v_start_to_point_Segment := &&INSTALL_SCHEMA..T_Segment(
                                  p_segment_id => 1,
                                  p_startCoord => v_self.startCoord,
                                  p_endCoord   => v_vertex,
                                  p_sdo_gtype  => v_self.Sdo_Gtype,
                                  p_sdo_srid   => v_self.sdo_srid
                                );

    v_start_to_point_distance := v_self.ST_Length(p_unit=>p_unit);
    v_measure_Length          := v_self.ST_LRS_Measure_Length();
    v_measure := CASE WHEN v_self.ST_LRS_Dim() = 3 
                      THEN v_self.StartCoord.z 
                      ELSE v_self.StartCoord.w 
                 END +
                 ( (v_start_to_point_distance / v_segment_length) * v_measure_length );

    -- DEBUG dbms_output.put_line('</ST_LRS_Compute_Measure>='||v_measure);    
    RETURN v_measure;
  END ST_LRS_Compute_Measure;

  Member Function ST_Round(p_dec_places_x In integer,
                           p_dec_places_y In integer Default null,
                           p_dec_places_z In integer Default 3,
                           p_dec_places_m In integer Default 3)
  Return &&INSTALL_SCHEMA..T_Segment Deterministic
  As
  Begin
    Return new &&INSTALL_SCHEMA..T_Segment(
                 element_id     => SELF.element_id,
                 subelement_id  => SELF.subelement_id,
                 segment_id     => SELF.segment_id,
                 startCoord     => case when SELF.startCoord is null
                                        then null
                                        else SELF.startCoord.ST_Round(p_dec_places_x,p_dec_places_y,p_dec_places_z,p_dec_places_m)
                                    end,
                 midCoord       => case when SELF.midCoord is null
                                        then null
                                        else SELF.midCoord.ST_Round(p_dec_places_x,p_dec_places_y,p_dec_places_z,p_dec_places_m)
                                    end,
                 endCoord       => case when SELF.endCoord is null
                                        then NULL
                                        else SELF.endCoord.ST_Round(p_dec_places_x,p_dec_places_y,p_dec_places_z,p_dec_places_m)
                                    end,
                 sdo_gtype      => SELF.SDO_GTYPE,
                 sdo_srid       => SELF.SDO_SRID,
                 projected      => SELF.projected,
                 PrecisionModel => SELF.PrecisionModel
           );
  End ST_Round;

  Member Function ST_Round
  Return &&INSTALL_SCHEMA..T_Segment Deterministic
  As
  Begin
    if ( SELF.precisionModel is null ) Then
      return SELF.ST_Self();
    else
      Return SELF.ST_Round( 
                     p_dec_places_x => SELF.PrecisionModel.xy,
                     p_dec_places_y => SELF.PrecisionModel.xy,
                     p_dec_places_z => SELF.PrecisionModel.z,
                     p_dec_places_m => SELF.PrecisionModel.w
             );
    end If;
  End ST_Round;

  Member Function ST_AsText
  Return VARCHAR2
  AS
  BEGIN
    Return 'T_Segment(' ||
              'p_element_id=>'    || NVL(TO_CHAR(SELF.element_id),    'NULL') || ',' ||
              'p_subelement_id=>' || NVL(TO_CHAR(SELF.subelement_id), 'NULL') || ',' ||
              'p_segment_id=>'    || NVL(TO_CHAR(SELF.segment_id),    'NULL') || ',' ||
              'p_startCoord=>'    || CASE WHEN SELF.startCoord IS NULL THEN 'NULL' ELSE SELF.startCoord.ST_AsText() END || ',' || 
              'p_midCoord=>'      || CASE WHEN SELF.midCoord   IS NULL THEN 'NULL' ELSE SELF.midCoord.ST_AsText()   END || ',' || 
              'p_endCoord=>'      || CASE WHEN SELF.endCoord   IS NULL THEN 'NULL' ELSE SELF.endCoord.ST_AsText()   END || ',' || 
              'p_sdo_gtype=>'     || NVL(TO_CHAR(SELF.SDO_GTYPE),     'NULL') || ','||
              'p_sdo_srid=>'      || NVL(TO_CHAR(SELF.SDO_SRID),      'NULL') || ')';
  END ST_AsText;

  Member Function ST_AsEWKT (p_format_model varchar2 default 'TM9')
           Return VARCHAR2
  AS
    v_ewkt varchar2(32000);
  BEGIN
    IF ( SELF.ST_isEmpty() = 1 ) THEN
      v_ewkt := case when SELF.sdo_srid is not null 
                     then 'SRID='||SELF.sdo_srid||';' 
                     else '' 
                 end ||
                 'LINESTRING EMPTY';
      Return v_ewkt;
    END IF;
    v_ewkt := case when SELF.sdo_srid is not null 
                     then 'SRID='||SELF.sdo_srid||';' 
                     else '' 
                 end ||
              case when SELF.ST_isCircularArc()=1 
                   then 'CIRCULARSTRING' 
                   else 'LINESTRING' 
               end ||
              case when SELF.ST_Dims()=4 then 'ZM'
                   when SELF.ST_Dims()=3 
                   then case when SELF.ST_Lrs_Dim()=0  then 'Z' 
                             when SELF.ST_Lrs_Dim()<>0 then 'M'
                         end
               end ||
               ' (' || 
               SELF.startCoord.ST_AsCoordString(p_separator=>' ',p_format_model=>p_format_model) ||
               ',' || 
               case when SELF.ST_isCircularArc()=1 
                    then SELF.midCoord.ST_AsCoordString(p_separator=>' ',p_format_model=>p_format_model) || ','
                    else ''
                end ||
               SELF.endCoord.ST_AsCoordString(p_separator=>' ',p_format_model=>p_format_model) ||
               ')';
    Return v_ewkt;
  END ST_AsEWKT;
  
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

  Member Function ST_Equals(p_segment In &&INSTALL_SCHEMA..T_Segment,
                            p_coords  In Integer default 1)
  Return NUMBER
  IS
    c_Min CONSTANT NUMBER := -1E38;
  BEGIN
    IF (p_segment IS NULL) THEN
      Return 0; /* False */
    END IF;
    IF ( NVL(p_coords,1)=1 ) THEN
      IF ( SELF.startCoord.ST_Equals(p_segment.startCoord,SELF.PrecisionModel.XY) = 1
       AND SELF.endCoord.ST_Equals  (p_segment.endCoord,  SELF.PrecisionModel.XY) = 1
       AND ( ( SELF.midCoord IS NOT NULL
           AND p_segment.midCoord IS NOT NULL
           AND SELF.midCoord.ST_Equals(p_segment.midCoord,SELF.PrecisionModel.XY) = 1 )
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
           SELF.startCoord.ST_Equals(p_segment.startCoord,SELF.PrecisionModel.XY) = 1    AND
           SELF.endCoord.ST_Equals(p_segment.endCoord,SELF.PrecisionModel.XY)     = 1    AND
           ( ( SELF.midCoord IS NOT NULL
               AND p_segment.midCoord IS NOT NULL
               AND SELF.midCoord.ST_Equals(p_segment.midCoord,SELF.PrecisionModel.XY) = 1
              ) OR
              ( SELF.midCoord IS NULL AND p_segment.midCoord IS NULL ) ) ) THEN
        Return 1; /* True */
      ELSE
        Return 0; /* False */
      END IF;

    END IF;
  END ST_Equals;

  Order Member Function orderBy(p_segment IN &&INSTALL_SCHEMA..T_Segment)
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
show errors

