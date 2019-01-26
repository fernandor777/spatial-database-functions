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

ALTER FUNCTION spdba.ST_GeometryType(IN geography)
  OWNER TO postgres;

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

ALTER FUNCTION spdba.ST_NumGeometries(IN geography)
  OWNER TO postgres;

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

ALTER FUNCTION spdba.ST_GeometryN(IN geography,IN integer)
  OWNER TO postgres;

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

ALTER FUNCTION spdba.ST_ExteriorRing(IN geography)
  OWNER TO postgres;

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

ALTER FUNCTION spdba.ST_NumInteriorRings(IN geography)
  OWNER TO postgres;

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

ALTER FUNCTION spdba.ST_InteriorRingN(IN geography,IN integer)
  OWNER TO postgres;

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

ALTER FUNCTION spdba.ST_PointN(IN geography,IN integer)
  OWNER TO postgres;

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

ALTER FUNCTION spdba.ST_NumPoints(IN geography)
  OWNER TO postgres;

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

ALTER FUNCTION spdba.ST_NPoints(IN geography)
  OWNER TO postgres;

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

ALTER FUNCTION spdba.ST_Points(IN geography)
  OWNER TO postgres;

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

ALTER FUNCTION spdba.ST_X(IN geography)
  OWNER TO postgres;

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

ALTER FUNCTION spdba.ST_Z(IN geography)
  OWNER TO postgres;

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

ALTER FUNCTION spdba.ST_M(IN geography)
  OWNER TO postgres;

COMMENT ON FUNCTION spdba.ST_M(IN geography) IS 'Geography Aware Function';

select spdba.ST_M('POINT ZM(147.1 -32.1 1.23 23.45)'::geography);

