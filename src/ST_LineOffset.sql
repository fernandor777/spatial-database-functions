-- FUNCTION: spdba.st_line_offset(geometry, double precision)

DROP FUNCTION IF EXISTS spdba.st_line_offset(geometry, double precision);

CREATE FUNCTION spdba.st_line_offset(
  p_geometry      geometry,
  p_offset double precision
)
RETURNS geometry
LANGUAGE 'plpgsql'
COST 100
IMMUTABLE 
AS $BODY$
Declare
  v_geom  geometry;
  v_geomn geometry;
  v_geomo geometry;
  v_id    integer; 
Begin
  IF ( p_geometry is null or p_offset is null) THEN
    RETURN p_geometry;
  END IF;
  IF ( ST_GeometryType(p_geometry) NOT IN ('ST_LineString','ST_MultiLineString','ST_GeometryCollection') ) THEN
    RETURN null;
  END IF;
  v_geom := NULL;
  FOR v_id in 1..ST_NumGeometries(p_geometry) LOOP
    BEGIN
      v_geomn := ST_GeometryN(p_geometry,v_id);
      IF ( ST_GeometryType(v_geomn) <> 'ST_LineString' ) THEN
        CONTINUE;
      END IF;
      v_geomo := ST_OffsetCurve(v_geomn,p_offset);
      IF ( v_geom is null ) THEN
        v_geom := v_geomo;
      ELSE
        v_geom := ST_Union(v_geom,v_geomo);
      END IF;
      EXCEPTION 
        WHEN OTHERS THEN
          RAISE NOTICE 'ST_OffsetCurve failed with %',SQLSTATE ;
    END;
  END LOOP;
  RETURN v_geom;
End;
$BODY$;

ALTER FUNCTION spdba.st_line_offset(geometry, double precision)
    OWNER TO postgres;

