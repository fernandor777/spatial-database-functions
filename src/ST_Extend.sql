DROP FUNCTION IF EXISTS spdba.ST_Extend(geometry,float,varchar,int,int,int);
DROP FUNCTION IF EXISTS spdba.ST_ExtendLine(geometry,geometry);

/* *************************** FUNCTIONS ************************************* */

CREATE FUNCTION spdba.ST_Extend
(
  p_linestring    geometry,
  p_extend_length float,
  p_end           varchar(5) = 'START', /* START means extend line at the start; END means extend at the end and BOTH means extend at both START and END of line */
  p_keep          int        = 0,       /* Keep first/last point adding new (1) or move start/end point */
  p_round_xy      int        = 3,
  p_round_zm      int        = 2
)
returns geometry
as
$$
/****f* EDITOR/ST_Extend (2008)
 *  NAME
 *    ST_Extend -- Function which extends the supplied linestring required distance at its start/end or both.
 *  SYNOPSIS
 *    Function spdba.ST_Extend (
 *               p_linestring    geometry,
 *               p_extend_length float,
 *               p_end           int,
 *               p_keep          int,
 *               p_round_xy      int = 3,
 *               p_round_zm      int = 2
 *             )
 *     Returns geometry
 *  USAGE
 *    SELECT ST_Extend(geometry::ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),5.0,'START',1,2,1).AsTextZM() as extendedGeom;
 *
 *    extendedGeom
 *    LINESTRING(-4.9 30.2,-3.6 31.5)
 *  DESCRIPTION
 *    Function that extends the supplied linestring at either its start or end (p_end), in the direction of a line formed by the
 *    first and second vertices (if START) or last and second last vertices (if END). p_end value of BOTH means line is extended at both ends.
 *    If p_keep is set to 1, the start or end vertex is kept and a new vertex added at the extended length from the start/end.
 *    If p_keep is 0, the actual first or last vertex is moved.
 *    The computed ordinates of the new geometry are rounded to p_round_xy/p_round_zm number of decimal digits of precision.
 *  NOTES
 *    MultiLinestrings and CircularString linestrings are not supported.
 *    Assumes planar projection eg UTM.
 *  INPUTS
 *    p_linestring    (geometry) - Supplied geometry of type LINESTRING only.
 *    p_extend_length (float)    - Length to extend linestring in SRID units.
 *    p_end           (varchar5) - START means extend line at the start; END means extend at the end and BOTH means extend at both START and END of line.
 *    p_keep          (int)      - Keep existing first/last vertex and add new (1) vertices, or move (0) existing start/end vertex.
 *    p_round_xy      (int)      - Round XY ordinates to supplied decimal digits of precision.
 *    p_round_zm      (int)      - Round ZM ordinates to supplied decimal digits of precision.
 *  RESULT
 *    linestring       (geometry) - Input geometry extended as instructed.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
Begin
  Declare
    v_GeometryType   varchar(50);
    v_extend_length  float = ABS(p_extend_length);
    v_round_xy       int;
    v_round_zm       int;
    v_isGeography    int;
    v_end            varchar(5) = UPPER(SUBSTRING(case when p_end is null then 'START' else p_end end,1,5));
    v_keep           int        = case when p_keep is null then 0 when p_keep <= 0 then 0 else 1 end;
    v_pt_id          int        = 0;
    v_sign           int;
    v_deltaX         float;
    v_deltaY         float;
    v_segment_length float;
    v_geom_length    float = 0;
    v_end_pt         geometry;
    v_internal_pt    geometry;
    v_new_point      geometry;
    v_linestring     geometry;
  Begin
    IF ( p_linestring is NULL ) THEN
      Return Null;
    END IF;

    -- Only support simple linestrings
    v_GeometryType := ST_GeometryType(p_linestring);
    IF ( v_GeometryType <> 'ST_LineString' ) THEN
      Return p_linestring;
    END IF;

    IF ( v_end NOT IN ('START','BOTH','END') ) THEN
      Return p_linestring;
    END IF;

    IF ( p_extend_length is NULL OR p_extend_length = 0 ) THEN
      Return p_linestring;
    END IF;

    v_isGeography := spdba.ST_IsGeographicSrid(ST_Srid(p_linestring));
    v_round_xy    := case when p_round_xy is null then 3 else p_round_xy end;
    v_round_zm    := case when p_round_zm is null then 2 else p_round_zm end;

    -- Set local geometry so that we can update it.
    --
    v_linestring := p_linestring;

    IF ( v_end IN ('START','BOTH') ) THEN
      -- Extend
      v_end_pt         := ST_StartPoint(v_linestring);
      v_internal_pt    := ST_PointN(v_linestring,2);
      v_deltaX         := ST_X(v_end_pt) - ST_X(v_internal_pt);
      v_deltaY         := ST_Y(v_end_pt) - ST_Y(v_internal_pt);
      v_segment_length := ROUND(case when v_isGeography = 1
                                     then ST_Distance(
                                             spdba.ST_ToGeography (v_end_pt,     ST_Srid(p_linestring)),
                                             spdba.ST_ToGeography (v_internal_pt,ST_Srid(p_linestring)) 
                                          )
                                     else ST_Distance(v_end_pt,v_internal_pt)
                                 End::numeric,
                                v_round_xy);
      -- To Do: Handle Z and M
      v_new_point      := ST_MakePoint(ROUND((ST_X(v_internal_pt) + v_deltaX * ((v_segment_length + p_extend_length) / v_segment_length))::numeric, v_round_xy),
                                       ROUND((ST_Y(v_internal_pt) + v_deltaY * ((v_segment_length + p_extend_length) / v_segment_length))::numeric, v_round_xy),
                                       ST_Srid(p_linestring));
      v_linestring     := CASE WHEN v_keep = 0  
                               THEN ST_SetPoint(v_linestring, 0, v_new_point)
                               ELSE ST_AddPoint(v_linestring, v_new_point, 0)
                           END;
    END IF;   -- IF ( v_end IN ('START','BOTH') )

    IF ( v_end IN ('BOTH','END') ) THEN
      -- Extend ...
      v_end_pt         := ST_EndPoint(v_linestring);
      v_internal_pt    := ST_PointN(v_linestring,ST_NumPoints(v_linestring)-1);
      v_deltaX         := ST_X(v_end_pt) - ST_X(v_internal_pt);
      v_deltaY         := ST_Y(v_end_pt) - ST_Y(v_internal_pt);
      v_segment_length := ROUND(case when v_isGeography = 1
                                     then ST_Distance(
                                            spdba.ST_ToGeography (v_end_pt,     ST_Srid(p_linestring)),
                                            spdba.ST_ToGeography (v_internal_pt,ST_Srid(p_linestring)) 
                                          )
                                     else ST_Distance(v_end_pt,v_internal_pt)
                                 End::numeric,
                                v_round_xy);
      -- To Do: Handle Z and M
      v_new_point      := ST_MakePoint(ROUND((ST_X(v_internal_pt) + v_deltaX * ((v_segment_length + p_extend_length) / v_segment_length))::numeric, v_round_xy),
                                       ROUND((ST_Y(v_internal_pt) + v_deltaY * ((v_segment_length + p_extend_length) / v_segment_length))::numeric, v_round_xy),
                                       ST_Srid(p_linestring));
      v_linestring     := CASE WHEN v_keep = 0 
                               THEN ST_SetPoint (v_linestring, -1, v_new_point)
                               ELSE ST_AddPoint (v_linestring,v_new_point,ST_NumPoints(v_linestring)-1)
                           END;
    END IF;   -- IF ( v_end IN ('BOTH','END') )
    Return v_linestring;
  END;
END $$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;

with data as (
  select ST_MakeLine(ST_MakePoint(0,0),ST_MakePoint(10,10)) as line
)
select CAST('ORIGINAL' as varchar(8)) as direction, ST_Buffer(line,2.0) from data
union all
select 'START' as direction, ST_BUFFER(spdba.ST_Extend(a.line,5.0,'START',1,3,2),0.25) from data as a
union all
select 'END' as direction, ST_BUFFER(spdba.ST_Extend(a.line,5.0,'END',0,3,2),0.5) from data as a
union all
select 'BOTH' as direction, ST_BUFFER(spdba.ST_Extend(a.line,5.0,'BOTH',1,3,2),0.75) from data as a;

-- ***************************************************************

CREATE FUNCTION spdba.ST_ExtendLine(
  eje_   geometry, 
  bound_ geometry
)
RETURNS geometry 
AS $$
-- version: alfa , by Julio A. Galindo, April 17, 2007: [hidden email]
DECLARE
     b_ geometry = boundary(bound_);
     dist float;
     max_dist float = 0;
     n_points int;
     pto_1 geometry;
     pto_2 geometry;
     first_pto geometry;
     last_pto geometry; 
     u_1 float;
     u_2 float;
     norm float;
     result text = 'LINESTRING(';
BEGIN
  IF GeometryType(eje_) NOT LIKE 'LINESTRING'
  OR GeometryType(bound_) NOT LIKE 'POLYGON' THEN RETURN NULL; END IF; 

  -- First Search how far is the boundary: (worst case)
  pto_1 := StartPoint(eje_);
  pto_2 := EndPoint(eje_);
  FOR i IN 1..NumPoints(b_)-1 LOOP
    dist := distance(PointN(b_,i),pto_1);
    IF dist > max_dist THEN max_dist := dist; END IF; 
    dist := distance(PointN(b_,i),pto_2);
    IF dist > max_dist THEN max_dist := dist; END IF;
  END LOOP;

  -- Now extent the linestring:
  pto_2 := PointN(eje_,2);
  u_1 := X(pto_2)-X(pto_1); 
  u_2 := Y(pto_2)-Y(pto_1);
  norm := sqrt(u_1^2 + u_2^2);
  first_pto := MakePoint(X(pto_1)-u_1/norm*dist,Y(pto_1)-u_2/norm*dist);
  n_points := nPoints(eje_);
  IF n_points > 2 THEN
    pto_1 := PointN(eje_,n_points-1);
    pto_2 := PointN(eje_,n_points);
    u_1 := X(pto_2)-X(pto_1);
    u_2 := Y(pto_2)-Y(pto_1);
    norm := sqrt(u_1^2 + u_2^2);
  END IF;

  last_pto := MakePoint(X(pto_2)+u_1/norm*dist,Y(pto_2)+u_2/norm*dist); 
  result := result || X(first_pto) || ' ' || Y(first_pto) || ',';
  FOR i IN 1..NumPoints(eje_) LOOP
    result := result || X(PointN(eje_,i)) || ' ' || Y(PointN(eje_,i)) || ','; 
  END LOOP;
  result := result || X(last_pto) || ' ' || Y(last_pto) || ')';
  -- Find the final Linestring:
  b_ := intersection(GeomFromText(result,SRID(eje_)),bound_);
  RETURN b_; 
END $$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;


