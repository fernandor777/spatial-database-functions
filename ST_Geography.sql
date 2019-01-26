DROP FUNCTION IF EXISTS spdba.ST_GeometryType(geography);

CREATE FUNCTION spdba.ST_GeometryType(p_geography geography) 
RETURNS varchar(20) 
AS
$BODY$
Begin
  Return ST_GeometryType(p_geography::geometry);
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION spdba.ST_GeometryType(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_GeometryType(IN geography) IS 'Geography Aware Function';

select spdba.ST_GeometryType('POINT(147.1 -32.1)'::geography);

-- ****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_NumGeometries(geography);

CREATE FUNCTION spdba.ST_NumGeometries(p_geography geography) 
RETURNS integer 
AS
$BODY$
Begin
  Return ST_NumGeometries(p_geography::geometry);
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION spdba.ST_NumGeometries(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_NumGeometries(IN geography) IS 'Geography Aware Function';

select spdba.ST_NumGeometries('POINT(147.1 -32.1)'::geography);

-- ****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_GeometryN(geography,integer);

CREATE FUNCTION spdba.ST_GeometryN(
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

ALTER FUNCTION spdba.ST_GeometryN(IN geography,IN integer) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_GeometryN(IN geography, IN integer) IS 'Geography Aware Function';

select ST_AsText(spdba.ST_GeometryN('MULTIPOINT((147.1 -32.1),(-6 45.4))'::geography,2));

-- ****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_ExteriorRing(geography);

CREATE FUNCTION spdba.ST_ExteriorRing(
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

ALTER FUNCTION spdba.ST_ExteriorRing(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_ExteriorRing(IN geography) IS 'Geography Aware Function';

select ST_AsText(spdba.ST_ExteriorRing('MULTIPOINT((147.1 -32.1),(-6 45.4))'::geography));
select ST_AsEWKT(spdba.ST_ExteriorRing('POLYGON((0 0,1 0,1 1,0 1,0 0))'::geography));

-- ****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_NumInteriorRings(geography);

CREATE FUNCTION spdba.ST_NumInteriorRings(p_geography geography) 
RETURNS integer 
AS
$BODY$
Begin
  Return ST_NumInteriorRings(p_geography::geometry);
End;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

ALTER FUNCTION spdba.ST_NumInteriorRings(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_NumInteriorRings(IN geography) IS 'Geography Aware Function';

select spdba.ST_NumInteriorRings('POLYGON((0 0,1 0,1 1,0 1,0 0))'::geography);
select spdba.ST_NumInteriorRings('POLYGON((0 0,1 0,1 1,0 1,0 0),(2 2,3 2,3 3,2 3,2 2))'::geography);

-- ****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_InteriorRingN(geography,integer);

CREATE FUNCTION spdba.ST_InteriorRingN(
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

ALTER FUNCTION spdba.ST_InteriorRingN(IN geography,IN integer) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_InteriorRingN(IN geography, IN integer) IS 'Geography Aware Function';

select ST_AsText(spdba.ST_InteriorRingN('MULTIPOINT((147.1 -32.1),(-6 45.4))'::geography,2));
select ST_AsText(spdba.ST_InteriorRingN('POLYGON((0 0,1 0,1 1,0 1,0 0))'::geography,1));
select ST_AsText(spdba.ST_InteriorRingN('POLYGON((0 0,1 0,1 1,0 1,0 0),(2 2,3 2,3 3,2 3,2 2))'::geography,1));

-- ****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_PointN(geography,integer);

CREATE FUNCTION spdba.ST_PointN(
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

ALTER FUNCTION spdba.ST_PointN(IN geography,IN integer) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_PointN(IN geography,IN integer) IS 'Geography Aware Function';

select ST_AsText(spdba.ST_PointN('MULTIPOINT((147.1 -32.1),(-6 45.4))'::geography,1));
select ST_AsText(spdba.ST_PointN('LINESTRING(147.1 -32.1,147.3 -32.2)'::geography,1));
select ST_AsEWKT(spdba.ST_PointN(spdba.ST_ExteriorRing('POLYGON((0 0,1 0,1 1,0 1,0 0))'::geography),1));

-- ****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_NumPoints(geography);

CREATE FUNCTION spdba.ST_NumPoints(
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

ALTER FUNCTION spdba.ST_NumPoints(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_NumPoints(IN geography) IS 'Geography Aware Function';

select spdba.ST_NumPoints('MULTIPOINT((147.1 -32.1),(-6 45.4))'::geography);
select spdba.ST_NumPoints('LINESTRING(147.1 -32.1,147.3 -32.2)'::geography);
select spdba.ST_NumPoints(spdba.ST_ExteriorRing('POLYGON((0 0,1 0,1 1,0 1,0 0))'::geography));

-- ********************************************************************

DROP FUNCTION IF EXISTS spdba.ST_NPoints(geography);

CREATE FUNCTION spdba.ST_NPoints(
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

ALTER FUNCTION spdba.ST_NPoints(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_NPoints(IN geography) IS 'Geography Aware Function';

select spdba.ST_NPoints('MULTIPOINT((147.1 -32.1),(-6 45.4))'::geography);
select spdba.ST_NPoints('LINESTRING(147.1 -32.1,147.3 -32.2)'::geography);
select spdba.ST_NPoints(spdba.ST_ExteriorRing('POLYGON((0 0,1 0,1 1,0 1,0 0))'::geography));

-- ****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_Points(geography);

CREATE FUNCTION spdba.ST_Points(
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

ALTER FUNCTION spdba.ST_Points(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_Points(IN geography) IS 'Geography Aware Function';

select ST_AsText(spdba.ST_Points('MULTIPOINT((147.1 -32.1),(-6 45.4))'::geography));
select ST_AsText(spdba.ST_Points('LINESTRING(147.1 -32.1,147.3 -32.2)'::geography));
select ST_AsText(spdba.ST_Points('POLYGON((0 0,1 0,1 1,0 1,0 0))'::geography));

-- ****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_X(geography);

CREATE FUNCTION spdba.ST_X(
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

ALTER FUNCTION spdba.ST_X(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_X(IN geography) IS 'Geography Aware Function';

select spdba.ST_X('MULTIPOINT((147.1 -32.1),(-6 45.4))'::geography);
select spdba.ST_X('POINT(147.1 -32.1)'::geography);

-- ****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_Y(geography);

CREATE FUNCTION spdba.ST_Y(
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

ALTER FUNCTION spdba.ST_Y(IN geography)
  OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_Y(IN geography) IS 'Geography Aware Function';

select spdba.ST_Y('MULTIPOINT((147.1 -32.1),(-6 45.4))'::geography);
select spdba.ST_Y('POINT(147.1 -32.1)'::geography);

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_Z(geography);

CREATE FUNCTION spdba.ST_Z(
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

ALTER FUNCTION spdba.ST_Z(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_Z(IN geography) IS 'Geography Aware Function';

select spdba.ST_Z('POINT Z(147.1 -32.1 1.34)'::geography);

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_M(geography);

CREATE FUNCTION spdba.ST_M(
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

ALTER FUNCTION spdba.ST_M(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_M(IN geography) IS 'Geography Aware Function';

select spdba.ST_M('POINT ZM(147.1 -32.1 1.23 23.45)'::geography);

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_AddMeasure(geography,geography);

CREATE FUNCTION spdba.ST_AddMeasure(
  p_geography      in geography, 
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

ALTER FUNCTION spdba.ST_AddMeasure(IN geography, IN float8, IN float8) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_AddMeasure(IN geography, IN float8, IN float8 ) IS 'Geography Aware Function';

select ST_Astext(spdba.ST_AddMeasure('LINESTRING(147.1 -32.1, 147.15 -32.1, 147.2 -32.1)'::geography,0,12098.0));
-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_CoordDim(geography,geography);

CREATE FUNCTION spdba.ST_CoordDim(
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

ALTER FUNCTION spdba.ST_CoordDIm(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_CoordDIm(IN geography) IS 'Geography Aware Function';

select spdba.ST_CoordDim('POINT ZM(147.1 -32.1 1.23 23.45)'::geography);
select spdba.ST_CoordDim('LINESTRING(147.1 -32.1, 147.2 -32.1)'::geography);
select spdba.ST_CoordDim('POLYGON Z((147.1 -32.1 1, 147.2 -32.1 2, 147.2 -32.0 3,147.1 -32.0 2,147.1 -32.1 1))'::geography);

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_Dimension(geography);

CREATE FUNCTION spdba.ST_Dimension(
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

ALTER FUNCTION spdba.ST_Dimension(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_Dimension(IN geography) IS 'Geography Aware Function';

select spdba.ST_Dimension('POINT ZM(147.1 -32.1 1.23 23.45)'::geography);
select spdba.ST_Dimension('LINESTRING M(147.1 -32.1 0, 147.2 -32.1 1238.3)'::geography);
select spdba.ST_Dimension('POLYGON((147.1 -32.1, 147.2 -32.1, 147.2 -32.0,147.1 -32.0,147.1 -32.1))'::geography);

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_IsClosed(geography);

CREATE FUNCTION spdba.ST_IsClosed(
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

ALTER FUNCTION spdba.ST_IsClosed(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_IsClosed(IN geography) IS 'Geography Aware Function';

select spdba.ST_IsClosed('LINESTRING(147.1 -32.1, 147.2 -32.1)'::geography);
select spdba.ST_IsClosed('LINESTRING(147.1 -32.1, 147.2 -32.1, 147.2 -31.0,147.1 -32.1)'::geography);

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_IsEmpty(geography);

CREATE FUNCTION spdba.ST_IsEmpty(
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

ALTER FUNCTION spdba.ST_IsEmpty(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_IsEmpty(IN geography) IS 'Geography Aware Function';

select spdba.ST_IsEmpty('LINESTRING(147.1 -32.1, 147.2 -32.1)'::geography);
select spdba.ST_IsEmpty('LINESTRING EMPTY'::geography);

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_IsValid(geography);

CREATE FUNCTION spdba.ST_IsValid(
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

ALTER FUNCTION spdba.ST_IsValid(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_IsValid(IN geography) IS 'Geography Aware Function';

select spdba.ST_IsValid('LINESTRING(147.1 -32.1, 147.2 -32.1)'::geography);
select spdba.ST_IsClosed('LINESTRING(147.1 -32.1, 147.2 -32.1, 147.2 -31.0,147.15 -32.5)'::geography);

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_IsValid(geography,integer);

CREATE FUNCTION spdba.ST_IsValid(
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

ALTER FUNCTION spdba.ST_IsValid(IN geography,IN integer) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_IsValid(IN geography,IN integer) IS 'Geography Aware Function';

select spdba.ST_IsValid('LINESTRING(147.1 -32.1, 147.2 -32.1)'::geography,0);
select spdba.ST_IsValid('LINESTRING(147.1 -32.1, 147.2 -32.1, 147.2 -31.0,147.15 -32.5)'::geography,0);
select spdba.ST_IsValid('POLYGON((0 0,10 0,10 10,9 9,8 10,10 10,5 11,0 10,0 0))'::geography,0);
select spdba.ST_IsValid('POLYGON((0 0,10 0,10 10,9 9,8 10,10 10,5 11,0 10,0 0))'::geography,1);

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_IsValidDetail(geography);

CREATE FUNCTION spdba.ST_IsValidDetail(
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

ALTER FUNCTION spdba.ST_IsValidDetail(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_IsValidDetail(IN geography) IS 'Geography Aware Function';

select spdba.ST_IsValidDetail('LINESTRING(147.1 -32.1, 147.2 -32.1)'::geography);
select spdba.ST_IsValidDetail('LINESTRING(147.1 -32.1, 147.2 -32.1, 147.2 -31.0,147.15 -32.5)'::geography);
select spdba.ST_IsValidDetail('POLYGON((0 0,10 0,10 10,9 9,8 10,10 10,5 11,0 10,0 0))'::geography);

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_IsValidDetail(geography,integer);

CREATE FUNCTION spdba.ST_IsValidDetail(
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

ALTER FUNCTION spdba.ST_IsValidDetail(IN geography,IN integer) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_IsValidDetail(IN geography,IN integer) IS 'Geography Aware Function';

select spdba.ST_IsValidDetail('LINESTRING(147.1 -32.1, 147.2 -32.1)'::geography,0);
select spdba.ST_IsValidDetail('LINESTRING(147.1 -32.1, 147.2 -32.1, 147.2 -31.0,147.15 -32.5)'::geography,0);
select spdba.ST_IsValidDetail('POLYGON((0 0,10 0,10 10,9 9,8 10,10 10,5 11,0 10,0 0))'::geography,0);
select spdba.ST_IsValidDetail('POLYGON((0 0,10 0,10 10,9 9,8 10,10 10,5 11,0 10,0 0))'::geography,1);

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_IsValidReason(geography);

CREATE FUNCTION spdba.ST_IsValidReason(
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

ALTER FUNCTION spdba.ST_IsValidReason(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_IsValidReason(IN geography) IS 'Geography Aware Function';

select spdba.ST_IsValidReason('LINESTRING(147.1 -32.1, 147.2 -32.1)'::geography);
select spdba.ST_IsValidReason('LINESTRING(147.1 -32.1, 147.2 -32.1, 147.2 -31.0,147.15 -32.5)'::geography);
select spdba.ST_IsValidReason('POLYGON((0 0,10 0,10 10,9 9,8 10,10 10,5 11,0 10,0 0))'::geography);

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_IsValidReason(geography,integer);

CREATE FUNCTION spdba.ST_IsValidReason(
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

ALTER FUNCTION spdba.ST_IsValidReason(IN geography,IN integer) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_IsValidReason(IN geography,IN integer) IS 'Geography Aware Function';

select spdba.ST_IsValidReason('LINESTRING(147.1 -32.1, 147.2 -32.1)'::geography,0);
select spdba.ST_IsValidReason('LINESTRING(147.1 -32.1, 147.2 -32.1, 147.2 -31.0,147.15 -32.5)'::geography,0);
select spdba.ST_IsValidReason('POLYGON((0 0,10 0,10 10,9 9,8 10,10 10,5 11,0 10,0 0))'::geography,0);
select spdba.ST_IsValidReason('POLYGON((0 0,10 0,10 10,9 9,8 10,10 10,5 11,0 10,0 0))'::geography,1);

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_AddPoint(geography,geography,integer);
									 
CREATE FUNCTION spdba.ST_AddPoint(
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

ALTER FUNCTION spdba.ST_AddPoint(IN geography,IN geography,IN integer) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_AddPoint(IN geography,IN geography,IN integer) IS 'Geography Aware Function';

select ST_AsText(spdba.ST_AddPoint('LINESTRING(147.1 -32.1, 147.2 -32.1)'::geography,'POINT(147.3 -32.1)'::geography,-1));

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_StartPoint(geography);
									 
CREATE FUNCTION spdba.ST_StartPoint(
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

ALTER FUNCTION spdba.ST_StartPoint(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_StartPoint(IN geography) IS 'Geography Aware Function';

select ST_AsText(spdba.ST_StartPoint('LINESTRING(147.1 -32.1, 147.2 -32.1)'::geography));

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_EndPoint(geography);
									 
CREATE FUNCTION spdba.ST_EndPoint(
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

ALTER FUNCTION spdba.ST_EndPoint(IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_EndPoint(IN geography) IS 'Geography Aware Function';

select ST_AsText(spdba.ST_EndPoint('LINESTRING(147.1 -32.1, 147.2 -32.1)'::geography));

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_AddPoint(geography,geography);
									 
CREATE FUNCTION spdba.ST_AddPoint(
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

ALTER FUNCTION spdba.ST_AddPoint(IN geography,IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_AddPoint(IN geography,IN geography) IS 'Geography Aware Function';

select ST_AsText(spdba.ST_AddPoint('LINESTRING(147.1 -32.1, 147.2 -32.1)'::geography,'POINT(147.0 -32.1)'::geography));

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_RemovePoint(geography,integer);
									 
CREATE FUNCTION spdba.ST_RemovePoint(
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

ALTER FUNCTION spdba.ST_RemovePoint(IN geography,IN integer) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_RemovePoint(IN geography,IN integer) IS 'Geography Aware Function';

select ST_AsText(spdba.ST_RemovePoint('LINESTRING(147.1 -32.1, 147.2 -32.1,147.3 -32.1)'::geography,2));

-- *****************************************************************

DROP FUNCTION IF EXISTS spdba.ST_SetPoint(geography,integer,geography);
									 
CREATE FUNCTION spdba.ST_SetPoint(
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

ALTER FUNCTION spdba.ST_SetPoint(IN geography,IN integer,IN geography) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_SetPoint(IN geography,IN integer,IN geography) IS 'Geography Aware Function';

select ST_AsText(spdba.ST_SetPoint('LINESTRING(147.1 -32.1, 147.2 -32.1,147.3 -32.1)'::geography,
								   1,
								   'POINT(147.15 -32.1)'::geography));

-- ****************************************************************************

DROP FUNCTION IF EXISTS spdba.ST_FlipCoordinates(geography);

CREATE FUNCTION spdba.ST_FlipCoordinates(
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

ALTER FUNCTION spdba.ST_FlipCoordinates(IN geography,IN integer) OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_FlipCoordinates(IN geography,IN integer) IS 'Geography Aware Function';

select ST_AsText(spdba.ST_FlipCoordinates('MULTIPOINT((-31.2 147.1),(45.4 -6))'::geography));
select ST_AsText(spdba.ST_FlipCoordinates('LINESTRING(-32.1 147.1,-32.2 147.3)'::geography));
