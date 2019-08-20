DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

CREATE OR REPLACE TYPE BODY T_VERTEXLIST 
AS

  Constructor Function T_VERTEXLIST(SELF IN OUT NOCOPY T_VERTEXLIST)
                Return Self As Result
  AS
  BEGIN
    SELF.vertexList            := new &&INSTALL_SCHEMA..T_Vertices(&&INSTALL_SCHEMA..T_Vertex());
    SELF.vertexList.TRIM(1);
    SELF.minimimVertexDistance := 0.0001;
    SELF.dPrecision            := 4;
    RETURN;
  END T_VERTEXLIST;

  Constructor Function T_VERTEXLIST(SELF     IN OUT NOCOPY T_VERTEXLIST,
                                    p_vertex in &&INSTALL_SCHEMA..T_VERTEX)
                Return Self As Result
  AS
  BEGIN
    SELF.vertexList            := new &&INSTALL_SCHEMA..T_Vertices(&&INSTALL_SCHEMA..T_VERTEX());
    SELF.vertexList(1)         := p_vertex;
    SELF.minimimVertexDistance := 0.0001;
    SELF.dPrecision            := 4;
    RETURN;
  END T_VERTEXLIST;

  Constructor Function T_VERTEXLIST(SELF      IN OUT NOCOPY T_VERTEXLIST,
                                    p_segment in &&INSTALL_SCHEMA..T_SEGMENT)
                Return Self As Result
  AS
  BEGIN
    SELF.vertexList            := new &&INSTALL_SCHEMA..T_Vertices(&&INSTALL_SCHEMA..T_Vertex());
    SELF.vertexList(1)         := p_segment.startCoord;
    SELF.vertexList.EXTEND(1);
    SELF.vertexList(2)         := p_segment.endCoord;
    SELF.minimimVertexDistance := 0.0001;
    SELF.dPrecision            := 4;
    RETURN;
  END T_VERTEXLIST;

  Constructor Function T_VERTEXLIST(SELF   IN OUT NOCOPY T_VERTEXLIST,
                                    p_line in mdsys.sdo_geometry)
                Return Self As Result
  AS
    v_ord         pls_integer;
    v_dims        integer;
    v_coordinates integer;
    v_vertex      &&INSTALL_SCHEMA..T_VERTEX;
  BEGIN
    SELF.vertexList            := new &&INSTALL_SCHEMA..T_Vertices(&&INSTALL_SCHEMA..T_Vertex());
    SELF.vertexList.TRIM(1);
    SELF.minimimVertexDistance := 0.0001;
    SELF.dPrecision            := 4;
    IF ( p_line is null or p_line.sdo_ordinates.COUNT < 1 ) THEN
      RETURN;
    END IF;
    v_dims        := p_line.get_dims();
    v_coordinates := p_line.sdo_ordinates.count / v_dims;
    SELF.vertexList.EXTEND(v_coordinates);
    v_vertex      := new &&INSTALL_SCHEMA..T_VERTEX(
                           p_x         => NULL,
                           p_y         => NULL,
                           p_z         => NULL,
                           p_w         => NULL,
                           p_id        => 1,
                           p_sdo_gtype => v_dims * 1000  + 1,
                           p_sdo_srid  => p_line.sdo_srid
                     );
    for i in 1..v_coordinates loop
       v_ord := ((i - 1) * v_dims) + 1;
       v_vertex.x := p_line.sdo_ordinates(v_ord); 
       v_vertex.y := p_line.sdo_ordinates(v_ord+1); 
       if ( v_dims > 2 ) Then
         v_vertex.z := p_line.sdo_ordinates(v_ord+2); 
	 if ( v_dims = 4 ) Then
           v_vertex.w := p_line.sdo_ordinates(v_ord+3); 
         End If;
       End If;
       SELF.vertexList(i) := new T_VERTEX(v_vertex);
    end loop;
    RETURN;
  END T_VERTEXLIST;

  /* ******************* Member Methods ************************ */

  Member Function ST_Self
           Return &&INSTALL_SCHEMA..T_VERTEXLIST
  AS
  BEGIN
    Return SELF; -- &&INSTALL_SCHEMA..T_Ordinates(SELF);
  END ST_Self;

  Member Function isDeleted(p_index in integer)
           return integer 
  As
    v_index pls_integer := ABS(p_index);
  Begin
    if (SELF.vertexList.COUNT = 0 or v_index = 0 or SELF.vertexList.COUNT < v_index) then
      return 0;
    end if;
    return SELF.vertexList(v_index).deleted;
  End isDeleted;

  Member Procedure setDeleted(
                      SELF      IN OUT NOCOPY T_VERTEXLIST,
                      p_index   IN INTEGER,
                      p_deleted IN INTEGER DEFAULT 1)
  As
    v_index pls_integer := ABS(p_index);
  Begin
    if (SELF.vertexList.COUNT = 0 or v_index = 0 or SELF.vertexList.COUNT < v_index) then
      return;
    end if;
    SELF.vertexList(v_index).deleted := NVL(p_deleted,2);
  End setDeleted;

  Member Function getNumCoordinates
           return integer deterministic
  As
  Begin
    if (SELF.vertexList is null or SELF.vertexList.COUNT = 0 ) then
      return 0;
    end if;
    return SELF.vertexList.COUNT;
  End getNumCoordinates;

  Member Function getOrdinates
           Return mdsys.sdo_ordinate_array
  As
    v_dims       pls_integer := 2;
    v_coordCount pls_integer;
    v_ordCount   pls_integer;
    v_ord        pls_integer;
    v_ords       mdsys.sdo_ordinate_array;
  Begin
    if ( SELF.vertexList is null or SELF.vertexList.COUNT = 0 ) Then
      return NULL;
    end If;
    v_dims       := SELF.vertexList(1).ST_Dims();
    v_coordCount := SELF.vertexList.COUNT;
    v_ordCount   := v_coordCount * v_dims;
    -- if more ords than sdo_ordinate_array can hold the following will break
    v_ords.EXTEND(v_ordCount);
    v_ord := 1;
    for i in 1..v_coordCount loop
      v_ords(v_ord) := SELF.vertexList(i).x;
      v_ord := v_ord + 1;
      v_ords(v_ord) := SELF.vertexList(i).y;
      v_ord := v_ord + 1;
      if ( v_dims > 2 ) then
        v_ord := v_ord + 1;
        v_ords(v_ord) := SELF.vertexList(i).z;
        if ( v_dims > 3 ) then
          v_ord := v_ord + 1;
          v_ords(v_ord) := SELF.vertexList(i).w;
        end If;
      end if;
    end loop;
    return v_ords;
  End getOrdinates;

  Member Function getCoordinates
           Return &&INSTALL_SCHEMA..T_Vertices
  As
  Begin
    return SELF.vertexList;
  End getCoordinates;

  /**
   * Tests whether the given point is redundant
   * relative to the previous
   * point in the list (up to tolerance).
   * 
   * @param p_vertex
   * @return true if the point is redundant
   */
  Member Function isRedundant(p_vertex in &&INSTALL_SCHEMA..T_Vertex)
           Return boolean
  As
    vertexDist Number;
    lastVertex &&INSTALL_SCHEMA..T_Vertex;
  Begin
    if (SELF.vertexList.COUNT < 1) then
    	return false;
    end if;
    lastVertex := vertexList(vertexList.COUNT);
    VertexDist := p_vertex.ST_Distance(lastVertex);
    if (VertexDist < minimimVertexDistance) then
    	return true;
    end if;
    return false;
  end isRedundant;

  Member Procedure makePrecise(
         SELF    IN OUT NOCOPY T_VERTEXLIST,
         p_coord in out nocopy &&INSTALL_SCHEMA..T_Vertex)
  As
  Begin
    -- optimization for full precision
    p_coord.x := ROUND(p_coord.x,SELF.dPrecision);
    p_coord.y := ROUND(p_coord.y,SELF.dPrecision);
  End makePrecise;

  Member Procedure addVertex(
         SELF     IN OUT NOCOPY T_VERTEXLIST,
         p_vertex IN &&INSTALL_SCHEMA..T_Vertex)
  As
   bufVertex &&INSTALL_SCHEMA..T_Vertex;
  Begin
    if ( NVL(p_vertex.sdo_srid,-1) <> NVL(SELF.vertexList(1).sdo_srid,-1) ) Then
      raise_application_error(-20001,'SRIDs do not match',true);
    End If;  
    bufVertex := new T_Vertex(p_vertex);
    makePrecise(bufVertex);
    -- don't add duplicate (or near-duplicate) points
    if (SELF.isRedundant(bufVertex)) then
        return;
    end if;
    vertexList.EXTEND(1); vertexList(vertexList.COUNT) := bufVertex;
  End addVertex;

  Member Procedure addCoordinate( 
        SELF       IN OUT NOCOPY T_VERTEXLIST,
         p_dim     in number,
         p_x_coord in number,
         p_y_coord in number,
         p_z_coord in number,
         p_m_coord in number,
         p_lrs_dim in integer default 0)
  IS
    v_vertex  &&INSTALL_SCHEMA..t_vertex;
    v_dim     integer := NVL(p_dim,2);
    v_lrs_dim integer := NVL(p_lrs_dim,0);
  Begin
    v_vertex := &&INSTALL_SCHEMA..t_vertex(
                      p_x         => p_x_coord,
                      p_y         => p_y_coord,
                      p_id        => SELF.vertexList.count+1,
                      p_sdo_gtype => v_dim * 1000 + (v_lrs_dim*100) + 1,
                      p_sdo_srid  => NULL
                 );
    IF ( p_dim >= 3 ) Then
      v_vertex.z := p_z_coord;
    END IF;
    IF ( p_dim = 4 ) Then
      v_vertex.w := p_m_coord;
    END IF;
    SELF.addVertex(v_vertex);
    RETURN;
  END addCoordinate;

  Member Procedure addCoordinate( 
         SELF    IN OUT NOCOPY T_VERTEXLIST,
         p_dim   in number,
         p_coord in &&INSTALL_SCHEMA..T_Vertex )
  Is
  Begin
    SELF.addCoordinate( p_dim, p_coord.x, p_coord.y, p_coord.z, p_coord.w,  p_coord.ST_Lrs_Dim());
  END addCoordinate;

  Member Procedure addCoordinate( 
         SELF      IN OUT NOCOPY T_VERTEXLIST,
         p_dim     in number,
         p_coord   in mdsys.vertex_type,
         p_lrs_dim in integer default 0)
  Is
  Begin
    SELF.addCoordinate( p_dim, p_coord.x, p_coord.y, p_coord.z, p_coord.w, p_lrs_dim);
  END addCoordinate;

  Member Procedure addCoordinate( 
         SELF      IN OUT NOCOPY T_VERTEXLIST,
         p_dim     in number,
         p_coord   in mdsys.sdo_point_type,
         p_lrs_dim in integer default 0)
  Is
  Begin
    SELF.addCoordinate( p_dim, p_coord.x, p_coord.y, p_coord.z, NULL, p_lrs_dim);
  END addCoordinate;

  Member Procedure addOrdinates( 
         SELF        IN OUT NOCOPY T_VERTEXLIST,
         p_dim       in integer,
         p_lrs_dim   in integer,
         p_ordinates in mdsys.sdo_ordinate_array)
  Is
    v_srid           integer;
    v_dims           integer := NVL(p_dim,2);
    v_lrs_dim        integer := NVL(p_lrs_dim,0);
    v_sdo_gtype      integer;
    v_ord_position   pls_integer;
    v_numCoordinates pls_integer;
    v_vertexBase     pls_integer;
    v_vertex         &&INSTALL_SCHEMA..t_vertex;
  Begin
    if ( p_ordinates is null or p_ordinates.COUNT = 1 or v_dims not in (2,3,4) ) then
      return;
    End If;
    if ( v_dims <> SELF.vertexList(1).ST_Dims() ) Then
      raise_application_error(-20001,'Coordinate dimensions do not match',true);
    End If;
    v_sdo_gtype      := v_dims * 1000 + (v_lrs_dim*100) + 1;
    if ( v_sdo_gtype <> SELF.vertexList(1).ST_SDO_GTYPE() ) Then
      raise_application_error(-20001,'SDO_GTYPE values do not match',true);
    End If;
    v_numCoordinates := p_ordinates.COUNT / v_dims;
    v_srid           := SELF.vertexList(1).sdo_srid;
    v_vertexBase     := SELF.vertexList.COUNT;
    SELF.vertexList.EXTEND(v_numCoordinates);
    FOR i IN 1..v_numCoordinates LOOP
      v_ord_position := ((i-1) * v_dims) + 1;
      v_vertex := &&INSTALL_SCHEMA..t_vertex(
                      p_x         => p_ordinates(v_ord_position),
                      p_y         => p_ordinates(v_ord_position+1),
                      p_id        => SELF.vertexList.count + i,
                      p_sdo_gtype => v_sdo_gtype,
                      p_sdo_srid  => v_srid
                  );
       if ( v_dims > 2 ) then
         v_vertex.z := p_ordinates(v_ord_position+2);
         If ( v_dims > 3 ) then
           v_vertex.w := p_ordinates(v_ord_position+3);
         End If;
       End If;
       SELF.vertexList(v_vertexBase + i) := &&INSTALL_SCHEMA..t_vertex(v_vertex);
    END LOOP;
  END addOrdinates;

  Member Procedure addVertices(
         SELF        IN OUT NOCOPY T_VERTEXLIST,
         p_vertices  IN &&INSTALL_SCHEMA..T_Vertices, 
         p_isForward IN integer default 1)            
  As
    v_isForward integer := NVL(p_isForward,1);
  Begin
    if ( p_vertices is null ) then
      return;
    end if;
    if ( NVL(p_vertices(1).sdo_srid,-1) <> NVL(SELF.vertexList(1).sdo_srid,-1) ) Then
      raise_application_error(-20001,'SRIDs do not match',true);
    End If;
    if (v_isForward = 1) Then
      -- No MakePrecise
      SELF.vertexList := SELF.vertexList MULTISET UNION p_vertices;
    ElsIf ( v_isForward = 2 ) then
      -- This uses MakePrecise
      for i in 1..p_vertices.COUNT Loop
        addVertex(p_vertices(i));
      end loop;
    else 
      -- This uses MakePrecise
      for i in Reverse 1..p_vertices.COUNT loop
        addVertex(p_vertices(i));
      end loop;
    end if;
  end addVertices;

  Member Procedure addSegments(
         SELF        IN OUT NOCOPY T_VERTEXLIST,
         p_vertices  IN &&INSTALL_SCHEMA..T_Vertices, 
         p_isForward IN integer default 1)
  As
  Begin
    SELF.addVertices(p_vertices,p_isForward);
  End addSegments;

  Member Procedure addSegment(
         SELF     IN OUT NOCOPY T_VERTEXLIST,
         p_vertex IN &&INSTALL_SCHEMA..T_Segment) 
  As
  Begin
    if ( p_vertex is null ) then
      return;
    end if;
    addVertex(p_vertex.startCoord);
    -- if (p_vertex.midCoord is not null then addVertex(p_vertex.midCoord); End If;
    addVertex(p_vertex.endCoord  );
  End addSegment;

  -- Because JTS represents a segment as two vertices, it writes the first coordinate with this function....
  Member Procedure addFirstSegment(
         SELF     IN OUT NOCOPY T_VERTEXLIST,
         p_offset IN &&INSTALL_SCHEMA..T_Vertex)
  As
  Begin
    -- vertexList.addVertex(offset1.startCoord); --p0);
    SELF.addVertex(p_offset); 
  End addFirstSegment;

  -- and the other with this function.
  Member Procedure addLastSegment(
         SELF     IN OUT NOCOPY T_VERTEXLIST,
         p_offset IN &&INSTALL_SCHEMA..T_Vertex)
  As
  Begin
    -- vertexList.addVertex(offset1.endCoord); -- p1);
    SELF.addVertex(p_offset);
  End AddLastSegment;

  Member Procedure closeRing(SELF IN OUT NOCOPY T_VERTEXLIST)
  As
    startVertex &&INSTALL_SCHEMA..T_Vertex;
    lastVertex  &&INSTALL_SCHEMA..T_Vertex;
    last2Vertex &&INSTALL_SCHEMA..T_Vertex;
  Begin
    if (vertexList.COUNT < 1) then
      return;
    end if;
    startVertex := new &&INSTALL_SCHEMA..T_Vertex(vertexList(1));
    lastVertex  := vertexList(vertexList.COUNT);
    last2Vertex := null;
    if (vertexList.COUNT >= 2) then
      last2Vertex := vertexList(vertexList.COUNT - 1);
    End If;
    if (startVertex.ST_Equals(lastVertex)=1) Then 
      return;
    End If;
    SELF.addVertex(startVertex);
  End closeRing;

  Member Procedure setPrecision(
         SELF        IN OUT NOCOPY T_VERTEXLIST,
         p_precision in integer default 3)
  AS
  Begin
    SELF.dPrecision := NVL(p_precision,3);
  End setPrecision;

  Member Function getPrecision
           Return Integer
  AS
  Begin
    RETURN SELF.dPrecision;
  End getPrecision;

  Member Procedure setMinimumVertexDistance(
         SELF       IN OUT NOCOPY T_VERTEXLIST,
         p_distance in number)
  As
  Begin
    SELF.minimimVertexDistance := p_distance * &&INSTALL_SCHEMA..OffsetSegmentGenerator.CURVE_VERTEX_SNAP_DISTANCE;
  End setMinimumVertexDistance;

  Member Function getMinimumVertexDistance
          return number
  As
  Begin
    return SELF.minimimVertexDistance;
  End getMinimumVertexDistance;

END;
/
SHOW ERRORS

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'T_VERTEXLIST';
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
      ELSE
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is invalid.');
         v_ok := false;
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

