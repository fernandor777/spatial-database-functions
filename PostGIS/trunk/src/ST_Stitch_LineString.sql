DROP FUNCTION IF EXISTS spdba.ST_Line_Offset(geometry, float);

CREATE FUNCTION spdba.ST_Line_Offset(
  p_geometry geometry, 
  p_offset float
)
Returns geometry
        LANGUAGE 'plpgsql'
        COST 100
        IMMUTABLE 
As
$$
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
$$

select spdba.ST_Line_Offset('MULTILINESTRING(
(505936.114999501 6964843.32490447,505946.744001857 6964843.26935537),
(505764.14839403 6964863.33092499,505765.646 6964862.946,505828.462181607 6964846.28827654,505831.139 6964845.996,505831.148999585 6964845.99499587),
(505893.916002321 6964843.54544413,505924.215949511 6964843.38709108),
(505831.148999585 6964845.99499587,505853.436 6964843.757,505893.916002321 6964843.54544413))'::geometry,5) as geom
union all
select 'MULTILINESTRING(
(505936.114999501 6964843.32490447,505946.744001857 6964843.26935537),
(505764.14839403 6964863.33092499,505765.646 6964862.946,505828.462181607 6964846.28827654,505831.139 6964845.996,505831.148999585 6964845.99499587),
(505893.916002321 6964843.54544413,505924.215949511 6964843.38709108),
(505831.148999585 6964845.99499587,505853.436 6964843.757,505893.916002321 6964843.54544413))'::geometry as geom;

-- *****************************************************************************
drop function spdba.ST_Stitch_LineString(geometry);

create function spdba.ST_Stitch_LineString(p_geometry geometry)
returns geometry
     LANGUAGE 'plpgsql'
     COST 100
     IMMUTABLE 
As
$$
Declare
  v_line geometry;
Begin
  IF ( p_geometry is null ) THEN
    RETURN NULL;
  END IF;
  IF ( ST_GeometryType(p_geometry) = 'ST_LineString' ) THEN
    RETURN p_geometry;
  END IF;
  IF ( ST_GeometryType(p_geometry) not in ('ST_MultiLineString','ST_GeometryCollection') ) THEN
    RETURN null;
  END IF;
  IF ( ST_NumGeometries(p_geometry) = 1 ) THEN
    RETURN ST_GeometryN(p_geometry,1);
  END IF;
  WITH RECURSIVE walk_network(id,geom) AS (
    SELECT id,
           n.geom 
      FROM network as n
     WHERE id = 1
     UNION ALL
    SELECT n.id,
           ST_MakeLine(n.geom,w.geom) as geom
      FROM walk_network as w,
           network      as n
    WHERE ST_DWithin(ST_EndPoint  (n.geom),ST_StartPoint(w.geom),0.25)
       OR ST_DWithin(ST_StartPoint(n.geom),ST_EndPoint  (w.geom),0.25)
  ), network as (
    select row_number() over (order by gs.*) as id, 
           ST_GeometryN(p_geometry,gs.*) as geom
      FROM generate_series(1,ST_NumGeometries(p_geometry),1) as gs
  )
  select geom
    into v_line
    from (select id,
                 max(a.id) over (partition by ST_Length(geom)) as MId,
                 ST_Length(geom) as gLength,
                 max(ST_Length(geom)) over () as mLength,
                 geom
              from walk_network as a
         ) as f
   where f.gLength = f.MLength
     and f.id      = f.mId;
   RETURN v_line;
End;
$$

select ST_NPoints(line), ST_AsText(line), line
  from (select spdba.ST_Stitch_LineString(geom) as line
          from (select ST_AsText(ST_Union(line)) as geom, ST_AsText(ST_LineMerge(line)) as lm_geom
                  from (select *
                          from (select 1 as id,'LINESTRING(0 0,1 0,1 1)'::geometry as line union all
                                select 2 as id,'LINESTRING(1 1,2 1,2 2)'::geometry as line union all
                                select 3 as id,'LINESTRING(2 2,3 2,3 3)'::geometry as line union all
                                select 4 as id,'LINESTRING(4 4,5 5)'::geometry as line 
                               ) as a
                         order by a.line
                       ) as g
                 ) as f
       ) as g;


