use GISDB
go

with data as (
select geometry::STGeomFromText('CIRCULARSTRING (10 0 NULL 15.657, 10 5 NULL 20.657, 20 10 NULL 38.162)',0) as cString
)
select dbo.STComputeLengthToMidPoint(d.cString), d.cString.STLength()
  from data as d;

with data as (
select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0) as linestring
)
select g.intValue as length,
       o.IntValue as offset,
       [lrs].[STFindPointByLength](linestring,g.IntValue,o.IntValue,3,2).STBuffer(0.2) as fPoint
  from data as a
       cross apply
       [dbo].[generate_series](0,a.lineString.STLength(),1) as g
       cross apply
       [dbo].[generate_series](-1,1,1) as o
union all
select null as length, 
       null as offset,
       linestring.STBuffer(0.1)
  from data as a;
GO

with data as (
select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as linestring
)
select g.intValue as measure,
       o.IntValue as offset,
       [lrs].[STFindPointByMeasure](linestring,g.IntValue,o.IntValue,3,2).STBuffer(0.2) as fPoint
  from data as a
       cross apply
       [dbo].[generate_series](a.lineString.STPointN(1).M,
                                    round(a.lineString.STPointN(a.linestring.STNumPoints()).M,0,1),
                                    1) as g
       cross apply
       [dbo].[generate_series](-1, 1, 1) as o
union all
select a.linestring.STPointN(a.linestring.STNumPoints()).M as measure, 
       null as offset,
       linestring.STBuffer(0.1)
  from data as a;
GO


-- SHow arc points ...
with data as (
select geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 20 0)',0) as cString
union all
select geometry::STGeomFromText('CIRCULARSTRING(25 30, 30 12, 25 10)',0) as cString
union all
select geometry::STGeomFromText('CIRCULARSTRING(20 0, 15 5, 10 0)',0) as cString
union all
select geometry::STGeomFromText('CIRCULARSTRING(30 0, 35 5, 35 -5)',0) as cString
union all
select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as cString
union all
select geometry::STGeomFromText('CIRCULARSTRING (-3 6.325 NULL 0, 0 7 NULL 3.08, 3 6.325 NULL 6.15)',0) as cString
union all
select geometry::STGeomFromText('CIRCULARSTRING (-3 6.325 NULL 0, 0 7 NULL 3.08, 3 9.325 NULL 6.15)',0) as cString
)
select a.cString.STBuffer(0.1)  from data as a union all
select d.cString.STCurveN(1).STPointN(p.IntValue).STBuffer(p.IntValue * 0.2) from data as d cross apply dbo.GENERATE_SERIES ( 1, d.cString.STNumPoints(), 1) as p;

-- Arc Mid Point Calcs
with data as (
select geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 20 0)',0) as cString
union all
select geometry::STGeomFromText('CIRCULARSTRING(25 30, 30 12, 25 10)',0) as cString
union all
select geometry::STGeomFromText('CIRCULARSTRING(20 0, 15 5, 10 0)',0) as cString
union all
select geometry::STGeomFromText('CIRCULARSTRING(30 0, 35 5, 35 -5)',0) as cString
union all
select geometry::STGeomFromText('CIRCULARSTRING (3 6.325 NULL 0, 0 7 NULL 3.08, -3 6.325 NULL 6.15)',0) as cString
union all
select geometry::STGeomFromText('CIRCULARSTRING (-3 6.325 NULL 0, 0 7 NULL 3.08, 3 6.325 NULL 6.15)',0) as cString
union all
select geometry::STGeomFromText('CIRCULARSTRING (-3 6.325 NULL 0, 0 7 NULL 3.08, 3 9.325 NULL 6.15)',0) as cString
)
Select cString, round(midArc,2) as midArcLength, round(allArc,2) as allArcLength, round(midArc/allArc,5) as MidAllRatio
  from (select d.cString, [dbo].[STComputeLengthToMidPoint](d.[cString]) as midArc, d.[cString].STLength() as allArc
          from data as d
		) as f
union all
select d.cString.STCurveN(1).STPointN(p.IntValue).STBuffer(p.IntValue * 0.2) as Point, null, null, null from data as d cross apply dbo.GENERATE_SERIES ( 1, d.cString.STNumPoints(), 1) as p;

-- *********************
-- Add Measure work....

with data as (
--select geometry::STGeomFromText('MULTILINESTRING((0 0,5 5,10 10,11 11,12 12),(100 100,200 200))',0) as linestring
--select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246, 0 7, -3 6.3246),(-3 6.3246, 0 0, 3 6.3246))',0) as linestring
select geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(0 0, 1 2.1082, 3 6.3246, 0 7, -3 6.3246, -1 2.1082, 0 0))',0) as linestring 
--select geometry::STGeomFromText('COMPOUNDCURVE (CIRCULARSTRING (0 0, 1 2.1082, 3 6.3246), CIRCULARSTRING(3 6.3246, 0 7, -3 6.3246), CIRCULARSTRING(-3 6.3246, -1 2.1082, 0 0))',0) as linestring
--select geometry::STGeomFromText('COMPOUNDCURVE((0 -23.43778, 0 23.43778),CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),(-90 23.43778, -90 -23.43778),CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))',0) as linestring
)
select t.id, t.token, t.separator,
       (case when t.token is null then CAST(null as geometry)
	        when t.token like '%[-0-9]%' then geometry::STPointFromText('POINT(' + LTRIM (t.token) + 
			       case when d.linestring.HasM=0 then case when d.linestring.HasZ=0 then ' null' end + ' 0' end + ')',0) 
			else null
			end).AsTextZM() as coord
  from data as d
      cross apply [dbo].[TOKENIZER](d.linestring.AsTextZM(),',()') as t;

with data as (
select geometry::STGeomFromText('MULTILINESTRING((0 0,5 5,10 10,11 11,12 12),(100 100,200 200))',0) as linestring
)
select stuff(
        (select ISNULL(case when t.token not like '%[-0-9]%' then t.token else t.token + ' 0' end,'') + t.separator as [text()]
           from data as d
                cross apply [dbo].[TOKENIZER](d.linestring.AsTextZM(),',()') as t
        for xml path('')), 1, 0, '');

with data as (
select geometry::STGeomFromText('COMPOUNDCURVE (CIRCULARSTRING (3 6.3 1.1 0, 0 7 1.1 3.1, -3 6.3 1.1 9.3), (-3 6.3 1.1 9.3, 0 0 1.4 16.3, 3 6.3 1.6 20.2))',0) as geom
)
select [lrs].[STScaleMeasure]( d.geom, 100.0, 125.1, 5.0, 3, 2).AsTextZM() as sGeom 
  from data as d;
GO

-- FilterByLength

-- MULTILINESTRING

with data as (
select geometry::STGeomFromText('MULTILINESTRING((-4 -4 0  1, 0  0 0  5.6),(10 0 0 15.61, 10 5 0 20.61,10 10 0 25.4),(11 11 0 26.8, 12 12 0 28.30))',28355) as linestring
)
select 1 as id, 'Start = First Point Second Segment' as locateType, 
       s.* from data as d cross apply [lrs].[STFilterLineSegmentByLength](linestring,15.61,null) as s
union all
select 2 as id, 'SM = First Point Second Element / EM = Second Point Second Element' as locateType,
       s.* from data as d cross apply [lrs].[STFilterLineSegmentByLength](linestring,15.61,25.4) as s
union all
select 3 as id, 'Cross first and second segments of first element',
       s.* from data as d cross apply [lrs].[STFilterLineSegmentByLength](linestring,2,6) as s
union all
select 4 as id, 'Cross first and second segments',
       s.* from data as d cross apply [lrs].[STFilterLineSegmentByLength](linestring,2,25) as s
union all
select 4 as id, 'Cross all segments',
       s.* from data as d cross apply [lrs].[STFilterLineSegmentByLength](linestring,2,26) as s;
go

-- COMPOUNDCURVE

with data as (
select geometry::STGeomFromText(
'COMPOUNDCURVE (
(-4 -4 NULL 0, 0 0 NULL 5.657, 10 0 NULL 15.657), 
CIRCULARSTRING (10 0 NULL 15.657, 10 5 NULL 20.657, 20 10 NULL 33.162), 
(20 10 NULL 33.162, 21 11 NULL 34.577, 22 12 NULL 35.991))',0) as linestring
-- Length at segment Start: 0
-- Length at segment Start: 5.657
-- Length at segment Start: 15.657
-- Length at segment Start: 33.162
-- Length at segment Start: 34.577
-- Total 35.991
)
select 'SP = FP First Segment; EP < EP First Segment' as locateType, 
       s.* from data as d cross apply [lrs].[STFilterLineSegmentByLength](linestring,0,5.0,3) as s
union all
select 'SP = FP First Segment; EP = EP First Segment' as locateType, 
       s.* from data as d cross apply [lrs].[STFilterLineSegmentByLength](linestring,0,5.65685424949238,3) as s
union all
select 'SP > FP First Segment; EP < EP First Segment' as locateType, 
       s.* from data as d cross apply [lrs].[STFilterLineSegmentByLength](linestring,0.1,5.0,3) as s
union all
select 'SM BETWEEN FP AND EP First Element / EM > FP Second Element' as locateType, 
       s.* from data as d cross apply [lrs].[STFilterLineSegmentByLength](linestring,5.0,15.0,3) as s
union all
select 'SM BETWEEN FP AND EP First Element / EM = EP Second Element' as locateType, 
       s.* from data as d cross apply [lrs].[STFilterLineSegmentByLength](linestring,5.0,15.657,3) as s
union all
select 'SM BETWEEN FP AND EP First Element / EM > SP Third Element' as locateType, 
       s.* from data as d cross apply [lrs].[STFilterLineSegmentByLength](linestring,5.0,16.0,3) as s
union all
select 'SM BETWEEN FP AND EP First Element / EM > SP Fourth Element' as locateType, 
       s.* from data as d cross apply [lrs].[STFilterLineSegmentByLength](linestring,5.0,24.1,3) as s
union all
select 'SM BETWEEN FP AND EP First Element / EM = EP Last CircularString Element' as locateType, 
       s.* from data as d cross apply [lrs].[STFilterLineSegmentByLength](linestring,5.0,33.162,3) as s
union all
select 'All segments' as locateType, 
       s.* from data as d cross apply [lrs].[STFilterLineSegmentByLength](linestring,null,null,3) as s;
go

use gisdb
go

-- LineString

With data as (
  select geometry::STGeomFromText('LINESTRING (3 6.3,0 7)',0) as segment
)
select test, pSegment.STBuffer(0.1) as geom from (
select 'StartPoint' as test, d.segment.STStartPoint() as pSegment from data as d
union all
select 'Before' as test, d.segment as pSegment from data as d
union all
select 'Right' as test, [$(owner)].[STParallelSegment](d.segment,  1.0, 3, 1) as pSegment from data as d
union all
select 'Left'  as test, [$(owner)].[STParallelSegment](d.segment, -1.0, 3, 1) as pSegment from data as d
) as g;

With data as (
  select geometry::STGeomFromText('LINESTRING (0 7,3 6.3)',0) as segment
)
select test, pSegment.STBuffer(0.1) as geom from (
select 'StartPoint' as test, d.segment.STStartPoint() as pSegment from data as d
union all
select 'Before' as test, d.segment as pSegment from data as d
union all
select 'Right' as test, [$(owner)].[STParallelSegment](d.segment,  1.0, 3, 1) as pSegment from data as d
union all
select 'Left'  as test, [$(owner)].[STParallelSegment](d.segment, -1.0, 3, 1) as pSegment from data as d
) as g;

-- Circular String
With data as (
  select geometry::STGeomFromText('CIRCULARSTRING (3 6.3,0 7,-3 6.3)',0) as segment
)
select test, 
       pSegment.STBuffer(0.1) as geom, 
	   pSegment.STAsText() as tGeom, 
       [cogo].[STFindCircleFromArc](pSegment).AsTextZM() as circle
  from (
select 'StartPoint' as test, d.segment.STStartPoint() as pSegment from data as d
union all
select 'Before' as test, d.segment as pSegment from data as d
union all
select 'Right' as test, [$(owner)].[STParallelSegment](d.segment,  1.0, 3, 1) as pSegment from data as d
union all
select 'Left'  as test, [$(owner)].[STParallelSegment](d.segment, -1.0, 3, 1) as pSegment from data as d
) as g;

With data as (
  select geometry::STGeomFromText('CIRCULARSTRING (-3 6.3,0 7,3 6.3)',0) as segment
)
select test, 
       pSegment.STBuffer(0.1) as geom, 
	   pSegment.STAsText() as tGeom, 
       [cogo].[STFindCircleFromArc(pSegment).AsTextZM() as circle 
  from (
select 'StartPoint' as test, d.segment.STStartPoint() as pSegment from data as d
union all
select 'Before' as test, d.segment as pSegment from data as d
union all
select 'Right' as test, [$(owner)].[STParallelSegment](d.segment, 1.0, 3, 1) as pSegment from data as d
union all
select 'Left'  as test, [$(owner)].[STParallelSegment](d.segment, -1.0, 3, 1) as pSegment from data as d
) as g;

-- *******************************************

With data as (
  select geometry::STGeomFromText('CIRCULARSTRING (3 6.3,0 5.6,-3 6.3)',0) as segment
)
select test, pSegment.STBuffer(0.1) as geom from (
select 'Before' as test, d.segment as pSegment from data as d
union all
select 'Right' as test, [$(owner)].[STParallelSegment](d.segment,  1.0, 3, 1) as pSegment from data as d
union all
select 'Left'  as test, [$(owner)].[STParallelSegment](d.segment, -1.0, 3, 1) as pSegment from data as d
) as g;

With data as (
  select geometry::STGeomFromText('CIRCULARSTRING (-3 6.3,0 5.6,3 6.3)',0) as segment
)
select test, 
       pSegment.STBuffer(0.1) as geom, 
	   pSegment.AsTextZM() as tgeom, 
       [cogo].[STFindCircleFromArc](pSegment).AsTextZM() as circle 
  from (
select CONCAT('N:',g.IntValue) as test, d.segment.STPointN(g.IntValue).STBuffer(0.1) as pSegment from data as d cross apply dbo.generate_series(1,3,1) as g 
union all
select 'Before' as test, cogo.[STFindCircleFromArc](d.segment).STBuffer(0.1) as pSegment from data as d
union all
select 'Before' as test, d.segment as pSegment from data as d
union all
select 'Right' as test, [$(owner)].[STParallelSegment](d.segment,  1.0, 3, 1) as pSegment from data as d
union all
select 'Left'  as test, [$(owner)].[STParallelSegment](d.segment, -1.0, 3, 1) as pSegment from data as d
) as g;

-- Point difference calculations....
With data as (
  select geometry::STGeomFromText('CIRCULARSTRING (-3 6.3,0 5.6,3 6.3)',0) as segment
)
select 'Right' as test, 
       [$(owner)].[STParallelSegment](d.segment, 1.0, 3, 1).STStartPoint().STDistance(d.segment.STStartPoint()) as startPointDist,
       [$(owner)].[STParallelSegment](d.segment, 1.0, 3, 1).STPointN(2).STDistance(d.segment.STPointN(2)) as midPointDist,
       [$(owner)].[STParallelSegment](d.segment, 1.0, 3, 1).STEndPoint().STDistance(d.segment.STEndPoint()) as endPointDist
from data as d
union all
select 'Left'  as test, 
       [$(owner)].[STParallelSegment](d.segment,-1.0, 3, 1).STStartPoint().STDistance(d.segment.STStartPoint()) as startPointDist,
       [$(owner)].[STParallelSegment](d.segment,-1.0, 3, 1).STPointN(2).STDistance(d.segment.STPointN(2)) as midPointDist,
       [$(owner)].[STParallelSegment](d.segment,-1.0, 3, 1).STEndPoint().STDistance(d.segment.STEndPoint()) as endPointDist
from data as d;
go

select 'Right' as test, [$(owner)].[STParallelSegment](geometry::STGeomFromText('CIRCULARSTRING (-3 6.3,0 5.6,3 6.3)',0), -1.0, 3, 1).AsTextZM() as pSegment
go

select dbo.STPointFromCogo(geometry::STGeomFromText('POINT (0 16.5047619)',0),196.382302553,9.63659558,3).STAsText();

select geometry::STGeomFromText('POINT (0 16.5047619 10.63659558)',0).STDistance(geometry::STGeomFromText('POINT (-3 6.3)',0))

select 'O' as test,
       geometry::STGeomFromText('CIRCULARSTRING (0 0,10 0,10 -10)',0).STBuffer(0.1) as circle1,
       [cogo].[STFindCircleFromArc](geometry::STGeomFromText('CIRCULARSTRING (0 0,10 0,10 -10)',0)).STBuffer(0.1) as circleOne,
	   [cogo].[STFindCircleFromArc](geometry::STGeomFromText('CIRCULARSTRING (0 0,10 0,10 -10)',0)).STBuffer(0.1) as circle11
union all
select 'N' as test,
       geometry::STGeomFromText('CIRCULARSTRING (1 0,9 0,9 -9)',0).STBuffer(0.2) circle2,
       [cogo].[STFindCircleFromArc](geometry::STGeomFromText('CIRCULARSTRING (1 0,9 0,9 -9)',0)).STBuffer(0.2) as circleTwo,
	   [cogo].[STFindCircleFromArc](geometry::STGeomFromText('CIRCULARSTRING (1 0,9 0,9 -9)',0)).STBuffer(0.1) as circle22;

select 'O' as test, [cogo].[STFindCircleFromArc](geometry::STGeomFromText('CIRCULARSTRING (0 0,10 0,10 -10)',0)).AsTextZM() as circle 
union all
select 'N' as test, [cogo].[STFindCircleFromArc](geometry::STGeomFromText('CIRCULARSTRING (1 0, 9 0, 9  -9)',0)).AsTextZM() as circle;


QUIT
GO
