SET schema 'public';
SET search_path TO public;
SHOW search_path;

DROP FUNCTION IF EXISTS ST_AddMeasure(geography,float8,float8);
DROP FUNCTION IF EXISTS ST_AddPoint(geography,geography);
DROP FUNCTION IF EXISTS ST_AddPoint(geography,geography,integer);
DROP FUNCTION IF EXISTS ST_CoordDim(geography);
DROP FUNCTION IF EXISTS ST_Dimension(geography);
DROP FUNCTION IF EXISTS ST_EndPoint(geography);
DROP FUNCTION IF EXISTS ST_ExteriorRing(geography);
DROP FUNCTION IF EXISTS ST_FlipCoordinates(geography);
DROP FUNCTION IF EXISTS ST_GeometryN(geography,integer);
DROP FUNCTION IF EXISTS ST_GeometryType(geography);
DROP FUNCTION IF EXISTS ST_InteriorRingN(geography,integer);
DROP FUNCTION IF EXISTS ST_IsClosed(geography);
DROP FUNCTION IF EXISTS ST_IsEmpty(geography);
DROP FUNCTION IF EXISTS ST_IsValid(geography);
DROP FUNCTION IF EXISTS ST_IsValid(geography,integer);
DROP FUNCTION IF EXISTS ST_IsValidDetail(geography);
DROP FUNCTION IF EXISTS ST_IsValidDetail(geography,integer);
DROP FUNCTION IF EXISTS ST_IsValidReason(geography);
DROP FUNCTION IF EXISTS ST_IsValidReason(geography,integer);
DROP FUNCTION IF EXISTS ST_M(geography);
DROP FUNCTION IF EXISTS ST_NPoints(geography);
DROP FUNCTION IF EXISTS ST_NumGeometries(geography);
DROP FUNCTION IF EXISTS ST_NumInteriorRings(geography);
DROP FUNCTION IF EXISTS ST_NumPoints(geography);
DROP FUNCTION IF EXISTS ST_PointN(geography,integer);
DROP FUNCTION IF EXISTS ST_Points(geography);
DROP FUNCTION IF EXISTS ST_RemovePoint(geography,integer);
DROP FUNCTION IF EXISTS ST_SetPoint(geography,integer,geography);
DROP FUNCTION IF EXISTS ST_StartPoint(geography);
DROP FUNCTION IF EXISTS ST_X(geography);
DROP FUNCTION IF EXISTS ST_Y(geography);
DROP FUNCTION IF EXISTS ST_Z(geography);
