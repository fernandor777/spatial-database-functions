DROP FUNCTION IF EXISTS spdba.ST_OneSidedBuffer(geometry,float);

CREATE FUNCTION spdba.ST_OneSidedBuffer (
  p_line  geometry,
  p_width float
)
  RETURNS geometry IMMUTABLE 
AS
$$
DECLARE
  v_GeometryType varchar(1000);
  v_buffer       geometry;
  v_small_line   geometry;
  v_offset_line  geometry;
  v_split_buffer geometry;
Begin
  If ( p_line is NULL ) Then
    return p_line;
  End If;
  If ( p_width is NULL ) Then
    return p_line;
  End If;
  v_GeometryType := ST_GeometryType(p_line);
  IF  ( v_GeometryType <> ('ST_LineString' ) ) Then
    return p_line;
  END IF;
  -- Generate square buffer.
  v_buffer := ST_Buffer(p_line,p_width, 'endcap=flat join=mitre');
  -- Split buffer into two halves
  v_split_buffer := ST_Split(v_buffer,p_line);
  If ( v_split_buffer is null ) Then
    Return v_split_buffer;
  End If;
  IF ( ST_NumGeometries(v_split_buffer) < 2 ) THEN
    Return ST_GeometryN(v_split_buffer,1);
  END IF;
  -- Identify side
  v_small_line  := ST_MakeLine(ST_StartPoint(p_line),ST_EndPoint(p_line));
  v_offset_line := ST_OffsetCurve(v_small_line, (p_width / 2.0), 'quad_segs=4 join=round');
  IF ( ST_Crosses(ST_GeometryN(v_split_buffer,1), v_small_line) ) Then
    return ST_GeometryN(v_split_buffer,1);
  ELSE
    return ST_GeometryN(v_split_buffer,2);
  END IF;
  RETURN p_line; 
End;
$$ LANGUAGE 'plpgsql';

SELECT ST_AsEWKT(spdba.ST_OneSidedBuffer('LINESTRING(0 0, 10 10)'::geometry,5.0));
-- "POLYGON((10 10,13.5355339059327 6.46446609406726,3.53553390593274 -3.53553390593274,0 0,10 10))"
SELECT spdba.ST_OneSidedBuffer('LINESTRING(0 0, 10 10)'::geometry,-5.0);
