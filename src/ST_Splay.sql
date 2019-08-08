DROP FUNCTION IF EXISTS spdba.ST_Splay(geometry,integer,integer,numeric);

CREATE FUNCTION spdba.ST_Splay(
  p_geometry            geometry,
  p_position            integer,
  p_number_of_locations integer,
  p_splay_distance      numeric default 1.0
)
RETURNS geometry
AS
$$
DECLARE
  v_tx                  numeric;
  v_ty                  numeric;
  v_position            integer;
  v_number_of_locations integer;
  v_origin_point        geometry;
  v_splay_point         geometry;
  v_splay_geometry      geometry;
BEGIN
  IF ( p_geometry is null ) THEN
    RETURN p_geometry;
  END IF;
  v_position := case when ABS(p_position) = 0 then 1 else ABS(p_position) end;
  IF ( v_position = 1 ) THEN
    RETURN p_geometry;
  END IF;
  v_number_of_locations := ABS(p_number_of_locations);
  IF ( v_position is null or v_number_of_locations is null ) THEN
    RETURN p_geometry;
  END IF;
  v_origin_point := case when ST_GeometryType(p_geometry) = 'ST_Point' then p_geometry else ST_Centroid(p_geometry) end;
  v_splay_point  := ST_SetSrid(
                       spdba.ST_PointFromCogo(v_origin_point,
                                             (v_position-2) * (360.0/(v_number_of_locations-1)),
                                             COALESCE(p_splay_distance,1.0)
                       ),
                       ST_Srid(p_geometry)
                    );
  -- Move supplied object to splay position
  v_tx       := ST_X(v_splay_point)-ST_X(v_origin_point);
  v_ty       := ST_Y(v_splay_point)-ST_Y(v_origin_point);
  If ( NOT (v_tx = 0 and v_ty = 0 ) ) Then
    v_splay_geometry := ST_Translate(p_geometry,v_tx,v_ty);
  else
    v_splay_geometry := p_geometry;
  End If;
  RETURN v_splay_geometry;
END;
$$ 
LANGUAGE plpgsql;

select spdba.ST_Splay(ST_GeomFromText('POINT(10 10)',28356),gs.*,4) as s_geom from generate_series(1,4,1) gs;
select spdba.ST_Splay(ST_GeomFromText('POINT(10 10)',28356),gs.*,5) as s_geom from generate_series(1,5,1) gs;
select spdba.ST_Splay(ST_GeomFromText('POINT(10 10)',28356),gs.*,9) as s_geom from generate_series(1,9,1) gs;

-- *****************************************************************************

DROP FUNCTION IF EXISTS spdba.ST_Splay(geometry,bigint,bigint,numeric);

CREATE FUNCTION spdba.ST_Splay(
  p_geometry            geometry,
  p_position            bigint,
  p_number_of_locations bigint,
  p_splay_distance      numeric default 1.0
)
RETURNS geometry
AS
BEGIN
  Return spdba.ST_Splay(
           p_geometry,
           p_position::integer,
           p_number_of_locations::integer,
           p_splay_distance 
         );
END;
$$
LANGUAGE plpgsql;


