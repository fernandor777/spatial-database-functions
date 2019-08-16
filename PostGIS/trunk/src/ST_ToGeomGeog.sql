DROP FUNCTION IF EXISTS spdba.ST_ToGeography(geometry,int);

DROP FUNCTION IF EXISTS spdba.ST_ToGeometry(geography,int);

CREATE FUNCTION spdba.ST_ToGeography
(
  p_geom geometry,
  p_srid Int = null
)
Returns geography
As
$$
/****f* CONVERSION/STToGeography (2008)
 *  NAME
 *    STToGeography - Given a geometry object returns a geography object.
 *  SYNOPSIS
 *    Function STToGeography (
 *       p_geom geometry,
 *       p_srid Int = NULL
 *     )
 *     Returns geography
 *  EXAMPLE
 *
 *    SELECT [$(owner)].[STToGeography] (
 *             geometry::STGeomFromText('LINESTRING(147.234 -43.2345, 148.234 -43.2345)',0),
 *             4326
 *           ).STAsText() 
 *     as geog
 *    GO
 *    geog
 *    LINESTRING(147.234 -43.2345, 148.234 -43.2345)
 *
 *  DESCRIPTION
 *    Given valid geometry object this function converts it to a geography object, assigns p_srid value and returns. 
 *    The p_srid value should be a valid geography SRID.
 *    Mainly useful for converting 2008 geometry objects with geographic data to 2012+ geography objects.  *  INPUTS
 *    p_geom (geometry) - A valid geometry object.
 *    p_srid      (int) - Valid geographic SRID. If null, uses SRID associated with supplied geometry.
 *  RESULT
 *    geography (geography) - Geography object.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Aug 20012 - Initial SQL Server 20012 implementation
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Return ST_SetSrid(
            ST_GeogFromText(ST_AsText(p_geom)),
            case when p_srid is null then ST_Srid(p_geom::geometry) else p_srid end
         );
END $$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

CREATE FUNCTION spdba.ST_ToGeometry 
(
  p_geog geography,
  p_srid Int = null
)
Returns geometry
As
$$
/****f* CONVERSION/STToGeometry (2012)
 *  NAME
 *    STToGeometry - Given a geography object returns a geometry object.
 *  SYNOPSIS
 *    Function STToGeometry (
 *       p_geog geography,
 *       p_srid Int = NULL
 *     )
 *     Returns geometry
 *  EXAMPLE
 *
 *    SELECT [$(owner)].[STToGeometry] (
 *             geography::STGeomFromText('LINESTRING(147.234 -43.2345, 148.234 -43.2345)',4326),
 *             NULL
 *           ).STAsText() as geom;
 *    GO
 *    geom
 *    LINESTRING (147.234 -43.2345, 148.234 -43.2345)
 *
 *  DESCRIPTION
 *    Given valid geography object this function converts it to a geometry object, assigns p_srid value and returns. 
 *    The p_srid value should be a valid projected SRID.
 *    Mainly useful for converting 2012 geography objects to geometry equalivalent to be able to use functions only available for geometry. 
 *  INPUTS
 *    p_geog (geography) - A valid geographic object.
 *    p_srid       (int) - Valid projected SRID. If null, uses SRID associated with supplied geography
 *  RESULT
 *    geometry (geometry) - Geometry object.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Aug 20012 - Initial SQL Server 20012 implementation
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Return ST_GeomFromText(
          ST_AsText(p_geog),
          case when p_srid is null then ST_Srid(p_geog::geometry) else p_srid end
         );
END $$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

SELECT spdba.ST_ToGeography(
         spdba.ST_ToGeometry(
               ST_SetSrid(
                  ST_GeogFromText('LINESTRING(147.234 -43.2345, 148.234 -43.2345)'),
                  4326
               ),
           4326),
	     4326
       ) as geog;

