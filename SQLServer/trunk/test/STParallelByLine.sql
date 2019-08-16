Use GISDB
GO

with data as (
select geometry::STGeomFromText(
'LINESTRING (63.29 914.361, 73.036 899.855, 80.023 897.179, 79.425 902.707, 91.228 903.305, 79.735 888.304, 98.4 883.584, 115.73 903.305, 102.284 923.026, 99.147 899.271, 110.8 902.707, 90.78 887.02, 96.607 926.911, 95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring 
),
vectors as (
select t.id, 
       lrs.STParallelSegment(t.geom,                               -1.5,3,2) as pGeom,
       lrs.STParallelSegment((lead(t.geom,1) over (order by t.id)),-1.5,3,2) as pNextGeom
  from data as d cross apply dbo.STVectorize(linestring) as t
)
select -1 as id, d.linestring.STStartPoint().STBuffer(0.03) as finalGeom from data as d
union all
select 0 as id, d.linestring.STBuffer(0.01) as finalGeom from data as d
union all
select v.id, v.pGeom.STBuffer(0.02) from vectors as v
union all
select v.id, v.pNextGeom.STBuffer(0.04) from vectors as v
union all
select g.id*10, case when g.shortGeom is null then null else g.shortGeom.STBuffer(0.05) end as shortGeom
  from (select v.id, v.pGeom, v.pNextGeom, v.pGeom.ShortestLineTo(v.pNextGeom) as shortGeom
          from vectors as v
	    ) as g
union all
select 0-g.id, case when g.shortGeom is null then null else g.shortGeom.STBuffer(0.06) end as shortGeom
  from (select v.id, v.pGeom, v.pNextGeom, s.iPoint as shortGeom
          from vectors as v
		       cross apply
			   [cogo].[STFindSegmentIntersection](v.pGeom,v.pNextGeom) as s
	    ) as g;


