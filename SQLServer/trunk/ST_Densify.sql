Create or Replace
  Function ST_Densify(p_geometry GEOMETRY,
                      p_distance numeric )
RETURNS GEOMETRY
As
$BODY$
Declare
    v_line        geometry;
    v_prev_point  geometry;
    v_point       geometry;
    v_dense_point geometry;
    v_dim         numeric;
    v_vect_len    numeric;
    v_seg_len     numeric;
    v_diff_x      numeric;
    v_diff_y      numeric;
    v_num_segs    int;
    v_ratio       numeric;
  Begin
    -- We do not densify points
    --
    If ( ST_GeometryType(p_geometry) <> 'ST_LineString' ) Then
      Return p_geometry;
    End If;
    v_dim         := ST_CoordDim(p_geometry);
    v_prev_point  := ST_PointN(p_geometry,1);
--RAISE NOTICE 'ST_NPoints %', ST_NPoints(p_geometry);
    For i In 2..ST_NPoints(p_geometry) Loop
--RAISE NOTICE 'i=%', i;
       v_point    := ST_PointN(p_geometry,i);
       v_vect_len := ST_Distance(v_prev_point,v_point);
--RAISE NOTICE 'v_vect_len % p_distance=%', v_vect_len,p_distance;
       -- Is a point required to be inserted ?
       v_num_segs := (v_vect_len / p_distance)::int;
--RAISE NOTICE 'v_num_segs=%',v_num_segs;
       if ( v_num_segs > 0 and (p_distance < v_vect_len)) Then
         v_seg_len  := (v_vect_len / v_num_segs) / v_vect_len;
--RAISE NOTICE 'v_seg_len=%',v_seg_len;
         v_diff_x   := (ST_X(v_point)-ST_X(v_prev_point));
         v_diff_y   := (ST_Y(v_point)-ST_Y(v_prev_point));
--RAISE NOTICE 'diffx % , diffy %', v_diff_x, v_diff_y;
--RAISE NOTICE '% to %', ST_AsText(v_prev_point),St_AsText(v_point);
         FOR j IN 1..v_num_segs LOOP
            v_dense_point := ST_SetSrid(
                                  ST_MakePoint(ST_X(v_prev_point) + (v_diff_x * (v_seg_len * j)),
                                               ST_Y(v_prev_point) + (v_diff_y * (v_seg_len * j))),
                                  ST_Srid(p_geometry));
--RAISE NOTICE 'Adding % %', j,ST_AsText(v_dense_point);
            if ( v_line is null ) Then
               v_line := ST_SetSrid(ST_MakeLine(v_prev_point,v_dense_point),ST_Srid(p_geometry));
            Else
               v_line := ST_AddPoint(v_line,v_dense_point);
            End If;
         END LOOP;
       End If;
       v_prev_point := v_point;
    END LOOP;
    Return v_line;
  End;
$BODY$
  LANGUAGE plpgsql VOLATILE STRICT;

--select ST_AsText(ST_Densify(St_MakeLine(ST_MakePoint(0,0),St_mAKEpOINT(10,0)),2));
select ST_AsText(ST_Densify(    ST_AddPoint(St_MakeLine(ST_MakePoint(0,0),ST_MakePoint(5,5)),ST_MakePoint(10,10)),2.1));
