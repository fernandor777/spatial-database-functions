DROP FUNCTION IF EXISTS spdba.ST_Densify(geometry,numeric,int,int);

CREATE FUNCTION spdba.ST_Densify(
  p_geom      IN GEOMETRY,
  p_distance  IN numeric,
  p_mode      IN int,
  p_round_xy  in int
)
RETURNS GEOMETRY
LANGUAGE 'plpgsql'
COST 100
IMMUTABLE 
AS 
$BODY$
DECLARE
   v_wkt            TEXT;
   v_wkt_remainder  TEXT;
   v_mode           int;
   v_pos            int;
   v_coord          int;
   v_round_xy       int;
   v_num_points     int;
   v_num_segments   int;
   v_space_pos      int;
   v_x              numeric;
   v_y              numeric;
   v_prev_x         numeric;
   v_prev_y         numeric;
   v_delta_x        numeric;
   v_delta_y        numeric;
   v_dense_x        numeric;
   v_dense_y        numeric;
   v_length         numeric;
   v_seg_length     numeric;
   v_distance       numeric;
   v_segment        geometry;
BEGIN
  If ( p_geom is NULL ) THEN
    Return p_geom;
  End If;

  -- Currently only supports simple LineStrings
  IF ( ST_GeometryType(p_geom) NOT IN ('ST_LineString','ST_MultiLineString') ) THEN
    Return p_geom;
  END IF;
  -- raise notice 'geoemtry type %',ST_GeometryType(p_geom);

  If ( p_distance is NULL or p_distance > ST_Length(p_geom) ) Then
    Return p_geom; 
  End If;
  
  -- 2D Only
  IF ( ST_CoordDim(p_geom) <> 2 ) THEN
    Return p_geom; 
  END IF;

  v_round_xy := COALESCE(p_round_xy,3);
  v_mode     := COALESCE(p_mode,   1);
  v_length   := ST_Length(p_geom);

  -- Set up WKT variables. Remove geometrytype tag in one hit
  v_wkt_remainder = ST_AsText(p_geom);
  v_wkt           = SUBSTR(v_wkt_remainder,1,POSITION('(' in v_wkt_remainder));
  v_wkt_remainder = SUBSTR(v_wkt_remainder,  
                           POSITION('(' in v_wkt_remainder)+1,
                           LENGTH(v_wkt_remainder));
  v_coord := 0;
  WHILE ( LENGTH(v_wkt_remainder) > 0 ) LOOP
    --raise notice 'Start Loop: %  <----> v_coord=%', v_wkt, v_coord;
    -- Is the start of v_wkt_remainder a coordinate?
	IF ( (regexp_matches(v_wkt_remainder,'^[-0-9]'))[1] is not null ) THEN
      v_coord := v_coord + 1;
      -- We have a coord
      -- Generate replacement coord from geometry point (better than unnecessary string manipulation)
      -- Now get position of end of coordinate 
      v_pos := case when POSITION(',' in v_wkt_remainder) = 0
                    then POSITION(')' in v_wkt_remainder)
                    when POSITION(',' in v_wkt_remainder) <> 0 and POSITION(',' in v_wkt_remainder) < POSITION(')' in v_wkt_remainder)
                    then POSITION(',' in v_wkt_remainder)
                    else POSITION(')' in v_wkt_remainder)
                end;
      -- Extract X and Y Ordinates from WKT
      v_space_pos := POSITION(' ' in v_wkt_remainder);
      v_x         := TO_NUMBER(SUBSTR(v_wkt_remainder,1,v_space_pos-1)::text,'FM999999999999990D0999999999999999'::text);
      v_y         := TO_NUMBER(SUBSTR(v_wkt_remainder,v_space_pos+1,v_pos-v_space_pos-1)::text,'FM999999999999990D0999999999999999'::text);
      -- Remove the old coord from v_wkt_remainder
      v_wkt_remainder := SUBSTR(v_wkt_remainder,v_pos,LENGTH(v_wkt_remainder));
      --raise notice 'v_wkt_remainder should start with )=%', v_wkt_remainder;
      IF ( v_coord = 1 ) THEN
          v_wkt := CONCAT(v_wkt,
                          LTRIM(TO_CHAR(round(v_x::numeric,v_round_xy),'FM999999999999990D0999999999999999')),
                          ' ',
                          LTRIM(TO_CHAR(round(v_y::numeric,v_round_xy),'FM999999999999990D0999999999999999'))
                   );
        v_prev_x := v_x;
        v_prev_y := v_y;
      ELSE
        v_segment := ST_SetSrid(
                        ST_MakeLine(
                           ST_Point(v_prev_x,v_prev_y),
                           ST_Point(v_x,v_y)
                        ),
                        ST_Srid(p_geom)
                      );
        v_seg_length := round(ST_Length(v_segment)::numeric,v_round_xy::int);
        -- Add previous point to WKT
        --Raise Notice 'Add Previous: v_seg_length=% p_distance=% wkt=%', v_seg_length, p_distance, v_wkt;
        -- Can we densify this segment?
        If ( v_seg_length <= p_distance ) Then
          v_wkt := CONCAT(v_wkt,
                          LTRIM(TO_CHAR(round(v_prev_x::numeric,v_round_xy),'FM999999999999990D0999999999999999')),
                          ' ',
                          LTRIM(TO_CHAR(round(v_prev_y::numeric,v_round_xy),'FM999999999999990D0999999999999999'))
                   );
	    Else
          -- Densify this segment
          -- Compute required segment distance
          If ( v_mode = 0 ) Then
            -- p_mode = 0 fit as many segments of length p_length as possible with last segment length < p_distance allowed
            v_distance   := p_distance;
            v_num_points := FLOOR(v_seg_length / v_distance);
          ElsIf ( v_mode = 1 ) Then
            -- p_mode = 1 is ensure no segment < p_distance; means last segment have segment > distance
            v_distance   := p_distance;
            v_num_points := FLOOR(v_seg_length / v_distance);
          ElsIf ( v_mode = 2 ) Then
            -- p_mode = 2 fits segments via binary chop with all segments being same length
            v_num_segments := CEIL(v_seg_length / p_distance);
            --raise notice 'mode=% v_num_segments=%', v_mode, v_num_points;						  
            v_distance   := v_seg_length / v_num_segments;
            v_num_points := v_num_segments - 1;
          End If;
          -- Now create points
          -- 
          -- raise notice 'mode=% v_distance=% v_num_points=%', v_mode, v_distance, v_num_points;
          v_delta_x := (v_x - v_prev_x) / v_seg_length * v_distance;
          v_delta_y := (v_y - v_prev_y) / v_seg_length * v_distance;
          FOR i IN 1..v_num_points LOOP
            v_dense_x := v_prev_x + (v_delta_x * i::numeric);
            v_dense_y := v_prev_y + (v_delta_y * i::numeric);
            If ( v_mode = 1 ) Then
			  if ( i = v_num_points ) Then
                -- Previous segment's start x/y has been written, only write end if lengths > p_length
                continue;
			  End If;
            End If;
            -- Add to WKT
            v_wkt := CONCAT(v_wkt,
							case when SUBSTR(v_wkt,LENGTH(v_wkt),1)=',' then '' else ',' end,
                            LTRIM(TO_CHAR(round(v_dense_x::numeric,v_round_xy),'FM999999999999990D0999999999999999')),
                            ' ',
                            LTRIM(TO_CHAR(round(v_dense_y::numeric,v_round_xy),'FM999999999999990D0999999999999999'))
                           );
            -- raise notice 'added coord to wkt=%', v_wkt;
          END LOOP;
          v_wkt := CONCAT(v_wkt,
                          case when SUBSTR(v_wkt,LENGTH(v_wkt),1)=',' then '' else ',' end,
                          LTRIM(TO_CHAR(round(v_x::numeric,v_round_xy),'FM999999999999990D0999999999999999')),
                          ' ',
                          LTRIM(TO_CHAR(round(v_y::numeric,v_round_xy),'FM999999999999990D0999999999999999'))
                         );
          -- raise notice 'added v_x/v_y coord to wkt=%', v_wkt;
        End If; -- seg_length <= p_distance
						  
      END IF; -- Coord = 0 
      v_prev_x := v_x;
      v_prev_y := v_y;
    ELSE
      -- Move to next character
      v_wkt := CONCAT(v_wkt,SUBSTR(v_wkt_remainder,1,1));
      If ( SUBSTR(v_wkt_remainder,1,3) = '),(') Then
        v_coord := 0;
      End If;
      -- raise notice 'v_wkt=%', v_wkt;
      v_wkt_remainder := SUBSTR(v_wkt_remainder,2,LENGTH(v_wkt_remainder));
      continue;
    END IF;
  END LOOP; 
  -- raise notice 'Return: %', v_wkt;
  RETURN ST_GeomFromText(v_wkt,ST_SRID(p_geom));
End;
$BODY$;

-- LineString
select 0 as mode,ST_AsText(spdba.ST_Densify(ST_GeomFromText('LINESTRING(0 0,95 0)')::geometry,10.0::numeric,0::int,3)) as geom
union all
select 1 as mode,ST_AsText(spdba.ST_Densify(ST_GeomFromText('LINESTRING(0 0,95 0)')::geometry,10.0::numeric,1::int,3::int)) as geom
union all
select 2 as mode,ST_AsText(spdba.ST_Densify(ST_GeomFromText('LINESTRING(0 0,95 0)')::geometry,10.0::numeric,2::int,3::int)) as geom;

select g.id, round(ST_Length(g.geom)::numeric,3) as segLength, g.geom
  from (select (f.geom).id, 
               (f.geom).segment as geom
          from (select spdba.ST_VectorAsSegment(
                          spdba.ST_Densify(ST_GeomFromText('LINESTRING(0 0,101 101)')::geometry,20.0::numeric,0::int,3) 
		               ) as geom
			   ) as f
		) as g;
												  
-- LineString
select 0 as mode,ST_AsText(spdba.ST_Densify(ST_GeomFromText('LINESTRING(0 0,101 101)')::geometry,20.0::numeric,0::int,3)) as geom
union all
select 1 as mode,ST_AsText(spdba.ST_Densify(ST_GeomFromText('LINESTRING(0 0,101 101)')::geometry,20.0::numeric,1::int,3::int)) as geom
union all
select 2 as mode,ST_AsText(spdba.ST_Densify(ST_GeomFromText('LINESTRING(0 0,101 101)')::geometry,20.0::numeric,2::int,3::int)) as geom;

select 0 as mode,ST_AsText(spdba.ST_Densify(ST_GeomFromText('LINESTRING(0 0,101 101,105 50)')::geometry,20.0::numeric,0::int,3)) as geom
union all
select 1 as mode,ST_AsText(spdba.ST_Densify(ST_GeomFromText('LINESTRING(0 0,101 101,105 50)')::geometry,20.0::numeric,1::int,3::int)) as geom
union all
select 2 as mode,ST_AsText(spdba.ST_Densify(ST_GeomFromText('LINESTRING(0 0,101 101,105 50)')::geometry,20.0::numeric,2::int,3::int)) as geom;

-- MultiLineString									  
select 1 as mode,spdba.ST_Densify(ST_GeomFromText('MULTILINESTRING((0 0,101 101),(200 205,250 265))')::geometry,20.0::numeric,1::int,3::int) as geom
