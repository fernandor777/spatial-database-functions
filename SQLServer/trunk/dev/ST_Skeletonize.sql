Create or Replace Function ST_Skeletonize(polygon geometry, sampling_density NUMERIC, threshold NUMERIC)
returns geometry
AS 
$$
Declare
  v_geom geometry;
Begin
  select ST_Transform(ST_LineMerge(ST_Union(g.line)),ST_Srid($1)) as geom
    into v_geom
    from (select ST_SetSRID(
                    ST_MakeLine(ST_MakePoint(round((f.vect).startcoord.x::numeric,2),round((f.vect).startcoord.y::numeric,2)),
	                        ST_MakePoint(round((f.vect).  endcoord.x::numeric,2),round((f.vect).  endcoord.y::numeric,2))),
	  		        geo2mga($1)) as line
	     from (SELECT ST_Vectorize((c.vGeom).polygon) as vect
		     FROM (SELECT ST_Voronoi(ST_AsText(ST_Segmentize(ST_Transform($1, geo2mga($1)),$2))) as vGeom) as c 
		  ) as f
	  ) as g
    where ST_Length(g.line) < $3
      and ST_Within(g.line,ST_Transform($1,geo2mga($1)));
  return v_geom;
  EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
end;
$$
LANGUAGE plpgsql
IMMUTABLE
RETURNS NULL ON NULL INPUT;

drop   table foo;
create table foo as
SELECT 1 as gid, ST_Skeletonize(ST_GeomFromEWKT('SRID=4283;MULTIPOLYGON(((149.475230302661 -26.2259834430728,149.475255702485 -26.22595917213,149.475309323825 -26.2259079339601,149.475338980558 -26.2258782772271,149.475417166491 -26.2257839148944,149.475527705224 -26.2256733761617,149.475592410823 -26.2255924941622,149.47565172429 -26.2255304846293,149.475700253489 -26.22543342623,149.475759566955 -26.2252608779644,149.475781135489 -26.2252231330314,149.475834620021 -26.2250576759061,149.475866971424 -26.2249390540958,149.475885843076 -26.2247961687333,149.475893930926 -26.2246829388235,149.475907410677 -26.224607452217,149.475928978279 -26.2245373575109,149.475947849931 -26.2244780466057,149.476009856786 -26.224367512646,149.476109606945 -26.2242084515822,149.476230924706 -26.2240251269662,149.47628214776 -26.2239253768075,149.476301414183 -26.2238931493368,149.476359405338 -26.2238990414863,149.476298323461 -26.2240035593644,149.476217444955 -26.2241410528263,149.476133870497 -26.2242569786865,149.476066471741 -26.2243594247954,149.476007160836 -26.2244510871034,149.475974809433 -26.2245427494113,149.475955937782 -26.2246451955202,149.47594515398 -26.2247395537785,149.475920890428 -26.2249228783945,149.475902018777 -26.2250334123542,149.475869667374 -26.2251385544132,149.475829664689 -26.2252366133646,149.475802704022 -26.2253282796305,149.475767655156 -26.2254145537634,149.475729910223 -26.2254927396963,149.475689469223 -26.2255601413625,149.47561937149 -26.225641023362,149.47554657769 -26.2257299935613,149.475457607491 -26.2258270519606,149.475379421558 -26.2259187182268,149.475363245158 -26.2259483749599,149.475258098559 -26.2260589136926,149.475212265426 -26.2260912664923,149.475150255893 -26.2261532760252,149.475028932894 -26.2263042557574,149.474888737428 -26.2264741079565,149.474708100963 -26.2267140578882,149.474641088757 -26.2268008691544,149.47458947403 -26.2268677336872,149.474554425164 -26.226916262887,149.474284818499 -26.227299104351,149.473891798969 -26.2278924493693,149.473809866183 -26.2279041540529,149.474182367966 -26.227353025684,149.474511288097 -26.2268650376205,149.474587011596 -26.2267628565142,149.474735061629 -26.2265630781559,149.474918394161 -26.2263258242907,149.475042413227 -26.2261667563586,149.475107118826 -26.226093962559,149.475188000826 -26.2260238648262,149.475230302661 -26.2259834430728)))'), 2, 8) as geom
  FROM river a 
 WHERE a.rid = 22;
SELECT gid, st_astext(geom)
  FROM foo f;

drop table river_s;
create table river_s
as 
SELECT a.rid, ST_SkeletonizeE(a.geom, 2, 8) as geom
  FROM river a
 WHERE geom is not null 
   and st_isValid(geom);
/*
Create or Replace Function ST_Skeletonize(polygon geometry, sampling_density NUMERIC, threshold NUMERIC)
returns geometry
AS $$
With lGeoms as (
select ST_LineMerge(ST_Union(g.line)) as geom
  from (select ST_SetSRID(ST_MakeLine(ST_MakePoint(round((f.vect).startcoord.x::numeric,2),round((f.vect).startcoord.y::numeric,2)),
				      ST_MakePoint(round((f.vect).  endcoord.x::numeric,2),round((f.vect).  endcoord.y::numeric,2))),
				      28356) as line
	  from (SELECT ST_Vectorize((c.vGeom).polygon) as vect
		  FROM (SELECT ST_Voronoi(ST_AsText(a.geoms)) as vGeom
			  FROM (SELECT ST_Union((d.dp).geom) as geoms
				  FROM (SELECT ST_DumpPoints(ST_MakeValid(ST_Segmentize(ST_ExteriorRing(ST_GeometryN(ST_Transform($1,28356),1)),$2))) as dp
					) as d
				) as a 
			) as c 
		) as f
	) as g
  where ST_Length(g.line) < $3
    and ST_Within(g.line,ST_Transform($1,28356))
)
SELECT ST_Transform(
          ST_SetSrid(
             ST_LineFromMultiPoint(
                ST_Collect(ST_MakePoint((ST_X(ST_PointN(g.geom,pointN))+ST_X(ST_PointN(g.geom,pointN+1)))/2,
                                        (ST_Y(ST_PointN(g.geom,pointN))+ST_Y(ST_PointN(g.geom,pointN+1)))/2)
                          )        
                                   ),
             28356)
          ,4326) as geom
  from (select generate_series(1,ST_NumPoints(v.geom),1) as pointn, v.geom
          from lGeoms as v
        ) as g
$$
LANGUAGE SQL
VOLATILE
RETURNS NULL ON NULL INPUT;
*/


