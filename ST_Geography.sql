SET schema 'public';
SET search_path TO public;
SHOW search_path;

-- ****************************************************************

DROP FUNCTION IF EXISTS ST_GeometryType(geography);

CREATE FUNCTION ST_GeometryType(p_geography geography) 
RETURNS varchar(20) 
AS
$BODY$
Begin
  Return ST_GeometryType(p_geography::geometry);
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_GeometryType(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_GeometryType(IN geography) IS 'Geography Aware Function';

-- ****************************************************************

DROP FUNCTION IF EXISTS ST_NumGeometries(geography);

CREATE FUNCTION ST_NumGeometries(p_geography geography) 
RETURNS integer 
AS
$BODY$
Begin
  Return ST_NumGeometries(p_geography::geometry);
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_NumGeometries(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_NumGeometries(IN geography) IS 'Geography Aware Function';

-- ****************************************************************

DROP FUNCTION IF EXISTS ST_GeometryN(geography,integer);

CREATE FUNCTION ST_GeometryN(
  p_geography geography,
  p_index integer
) 
RETURNS geography
AS
$BODY$
Begin
  Return ST_SetSrid(ST_GeometryN(p_geography::geometry,p_index),
                    ST_Srid(p_geography::geometry)
         )::geography;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_GeometryN(IN geography,IN integer) OWNER TO postgres;

COMMENT ON FUNCTION ST_GeometryN(IN geography, IN integer) IS 'Geography Aware Function';

-- *************************************************************

DROP FUNCTION IF EXISTS ST_ExteriorRing(geography);

CREATE FUNCTION ST_ExteriorRing(
  p_geography geography
) 
RETURNS geography
AS
$BODY$
Begin
  Return ST_SetSrid(ST_ExteriorRing(p_geography::geometry),
                    ST_Srid(p_geography::geometry)
         )::geography;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_ExteriorRing(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_ExteriorRing(IN geography) IS 'Geography Aware Function';


-- ****************************************************************

DROP FUNCTION IF EXISTS ST_NumInteriorRings(geography);

CREATE FUNCTION ST_NumInteriorRings(p_geography geography) 
RETURNS integer 
AS
$BODY$
Begin
  Return ST_NumInteriorRings(p_geography::geometry);
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_NumInteriorRings(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_NumInteriorRings(IN geography) IS 'Geography Aware Function';


-- ****************************************************************

DROP FUNCTION IF EXISTS ST_InteriorRingN(geography,integer);

CREATE FUNCTION ST_InteriorRingN(
  p_geography geography,
  p_index integer
) 
RETURNS geography
AS
$BODY$
Begin
  Return ST_SetSrid(ST_InteriorRingN(p_geography::geometry,p_index),
                    ST_Srid(p_geography::geometry)
         )::geography;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_InteriorRingN(IN geography,IN integer) OWNER TO postgres;

COMMENT ON FUNCTION ST_InteriorRingN(IN geography, IN integer) IS 'Geography Aware Function';

-- ****************************************************************

DROP FUNCTION IF EXISTS ST_PointN(geography,integer);

CREATE FUNCTION ST_PointN(
  p_geography geography,
  p_index     integer
) 
RETURNS geography
AS
$BODY$
Begin
  Return ST_SetSrid(ST_PointN(p_geography::geometry,
                              p_index),
                    ST_Srid(p_geography::geometry)
         )::geography;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_PointN(IN geography,IN integer) OWNER TO postgres;

COMMENT ON FUNCTION ST_PointN(IN geography,IN integer) IS 'Geography Aware Function';

-- ****************************************************************

DROP FUNCTION IF EXISTS ST_NumPoints(geography);

CREATE FUNCTION ST_NumPoints(
  p_geography geography
) 
RETURNS integer
AS
$BODY$
Begin
  Return ST_NumPoints(p_geography::geometry);
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_NumPoints(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_NumPoints(IN geography) IS 'Geography Aware Function';

-- ********************************************************************

DROP FUNCTION IF EXISTS ST_NPoints(geography);

CREATE FUNCTION ST_NPoints(
  p_geography geography
) 
RETURNS integer
AS
$BODY$
Begin
  Return ST_NPoints(p_geography::geometry);
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_NPoints(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_NPoints(IN geography) IS 'Geography Aware Function';

-- ****************************************************************

DROP FUNCTION IF EXISTS ST_Points(geography);

CREATE FUNCTION ST_Points(
  p_geography geography
) 
RETURNS geography
AS
$BODY$
Begin
  Return ST_Points(p_geography::geometry)::geography;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_Points(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_Points(IN geography) IS 'Geography Aware Function';

-- ****************************************************************

DROP FUNCTION IF EXISTS ST_X(geography);

CREATE FUNCTION ST_X(
  p_point geography
) 
RETURNS float
AS
$BODY$
Begin
  Return ST_X(p_point::geometry)::float;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_X(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_X(IN geography) IS 'Geography Aware Function';


-- ****************************************************************

DROP FUNCTION IF EXISTS ST_Y(geography);

CREATE FUNCTION ST_Y(
  p_point geography
) 
RETURNS float
AS
$BODY$
Begin
  Return ST_Y(p_point::geometry)::float;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_Y(IN geography)
  OWNER TO postgres;

COMMENT ON FUNCTION ST_Y(IN geography) IS 'Geography Aware Function';


-- *****************************************************************

DROP FUNCTION IF EXISTS ST_Z(geography);

CREATE FUNCTION ST_Z(
  p_point geography
) 
RETURNS float
AS
$BODY$
Begin
  Return ST_Z(p_point::geometry)::float;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_Z(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_Z(IN geography) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_M(geography);

CREATE FUNCTION ST_M(
  p_point geography
) 
RETURNS float
AS
$BODY$
Begin
  Return ST_M(p_point::geometry)::float;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_M(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_M(IN geography) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_AddMeasure(geography,float8,float8);

CREATE FUNCTION ST_AddMeasure(
  p_geography     in geography, 
  p_measure_start in float8,
  p_measure_end   in float8 
) 
RETURNS geography
AS
$BODY$
Begin
  /* Or write own implementation */
  Return ST_SetSrid(
            ST_AddMeasure(p_geography::geometry,
               p_measure_start,
               p_measure_end
            ),
            ST_Srid(p_geography::geometry)
         )::geography;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_AddMeasure(IN geography, IN float8, IN float8) OWNER TO postgres;

COMMENT ON FUNCTION ST_AddMeasure(IN geography, IN float8, IN float8 ) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_CoordDim(geography,geography);

CREATE FUNCTION ST_CoordDim(
  p_geography geography
) 
RETURNS integer
AS
$BODY$
Begin
  Return ST_CoordDim(p_geography::geometry)::integer;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_CoordDIm(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_CoordDIm(IN geography) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_Dimension(geography);

CREATE FUNCTION ST_Dimension(
  p_geography geography
) 
RETURNS integer
AS
$BODY$
Begin
  Return ST_Dimension(p_geography::geometry)::integer;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_Dimension(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_Dimension(IN geography) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_IsClosed(geography);

CREATE FUNCTION ST_IsClosed(
  p_geography geography
) 
RETURNS boolean
AS
$BODY$
Begin
  Return ST_IsClosed(p_geography::geometry)::boolean;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_IsClosed(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_IsClosed(IN geography) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_IsEmpty(geography);

CREATE FUNCTION ST_IsEmpty(
  p_geography geography
) 
RETURNS boolean
AS
$BODY$
Begin
  Return ST_IsEmpty(p_geography::geometry)::boolean;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_IsEmpty(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_IsEmpty(IN geography) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_IsValid(geography);

CREATE FUNCTION ST_IsValid(
  p_geography geography
) 
RETURNS boolean
AS
$BODY$
Begin
  Return ST_IsValid(p_geography::geometry)::boolean;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_IsValid(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_IsValid(IN geography) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_IsValid(geography,integer);

CREATE FUNCTION ST_IsValid(
  p_geography geography,
  p_flags     integer
) 
RETURNS boolean
AS
$BODY$
Begin
  Return ST_IsValid(p_geography::geometry,p_flags)::boolean;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_IsValid(IN geography,IN integer) OWNER TO postgres;

COMMENT ON FUNCTION ST_IsValid(IN geography,IN integer) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_IsValidDetail(geography);

CREATE FUNCTION ST_IsValidDetail(
  p_geography geography
) 
RETURNS text
AS
$BODY$
Begin
  Return ST_IsValidDetail(p_geography::geometry)::text;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_IsValidDetail(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_IsValidDetail(IN geography) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_IsValidDetail(geography,integer);

CREATE FUNCTION ST_IsValidDetail(
  p_geography geography,
  p_flags     integer
) 
RETURNS text
AS
$BODY$
Begin
  Return ST_IsValidDetail(p_geography::geometry,p_flags)::text;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_IsValidDetail(IN geography,IN integer) OWNER TO postgres;

COMMENT ON FUNCTION ST_IsValidDetail(IN geography,IN integer) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_IsValidReason(geography);

CREATE FUNCTION ST_IsValidReason(
  p_geography geography
) 
RETURNS text
AS
$BODY$
Begin
  Return ST_IsValidReason(p_geography::geometry)::text;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_IsValidReason(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_IsValidReason(IN geography) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_IsValidReason(geography,integer);

CREATE FUNCTION ST_IsValidReason(
  p_geography geography,
  p_flags     integer
) 
RETURNS text
AS
$BODY$
Begin
  Return ST_IsValidReason(p_geography::geometry,p_flags)::text;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_IsValidReason(IN geography,IN integer) OWNER TO postgres;

COMMENT ON FUNCTION ST_IsValidReason(IN geography,IN integer) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_AddPoint(geography,geography,integer);
									 
CREATE FUNCTION ST_AddPoint(
  p_geography geography,
  p_point     geography,
  p_position  integer
) 
RETURNS geography
AS
$BODY$
Begin
  Return ST_AddPoint(p_geography::geometry,p_point::geometry,p_position)::geography;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_AddPoint(IN geography,IN geography,IN integer) OWNER TO postgres;

COMMENT ON FUNCTION ST_AddPoint(IN geography,IN geography,IN integer) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_StartPoint(geography);
									 
CREATE FUNCTION ST_StartPoint(
  p_geography geography
) 
RETURNS geography
AS
$BODY$
Begin
  Return ST_StartPoint(p_geography::geometry)::geography;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_StartPoint(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_StartPoint(IN geography) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_EndPoint(geography);
									 
CREATE FUNCTION ST_EndPoint(
  p_geography geography
) 
RETURNS geography
AS
$BODY$
Begin
  Return ST_EndPoint(p_geography::geometry)::geography;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_EndPoint(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_EndPoint(IN geography) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_AddPoint(geography,geography);
									 
CREATE FUNCTION ST_AddPoint(
  p_geography geography,
  p_point     geography
) 
RETURNS geography
AS
$BODY$
Begin
  Return ST_AddPoint(p_geography::geometry,p_point::geometry)::geography;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_AddPoint(IN geography,IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_AddPoint(IN geography,IN geography) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_RemovePoint(geography,integer);
									 
CREATE FUNCTION ST_RemovePoint(
  p_geography geography,
  p_offset    integer
) 
RETURNS geography
AS
$BODY$
Begin
  Return ST_RemovePoint(p_geography::geometry,p_offset)::geography;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_RemovePoint(IN geography,IN integer) OWNER TO postgres;

COMMENT ON FUNCTION ST_RemovePoint(IN geography,IN integer) IS 'Geography Aware Function';

-- *****************************************************************

DROP FUNCTION IF EXISTS ST_SetPoint(geography,integer,geography);
									 
CREATE FUNCTION ST_SetPoint(
  p_geography         geography,
  p_zerobasedposition integer,
  p_point             geography
) 
RETURNS geography
AS
$BODY$
Begin
  Return ST_SetPoint(p_geography::geometry,p_zerobasedposition,p_point::geometry)::geography;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_SetPoint(IN geography,IN integer,IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_SetPoint(IN geography,IN integer,IN geography) IS 'Geography Aware Function';

-- ****************************************************************************

DROP FUNCTION IF EXISTS ST_FlipCoordinates(geography);

CREATE FUNCTION ST_FlipCoordinates(
  p_geography geography
) 
RETURNS geography
AS
$BODY$
Begin
  Return ST_SetSrid(ST_FlipCoordinates(p_geography::geometry),
                    ST_Srid(p_geography::geometry)
         )::geography;
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION ST_FlipCoordinates(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION ST_FlipCoordinates(IN geography) IS 'Geography Aware Function';

