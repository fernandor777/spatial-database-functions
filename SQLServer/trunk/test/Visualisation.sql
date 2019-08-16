use spatialdb
GO

SELECT [lrs].[STAddMeasure] (
geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0),
1.0, geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0).STLength()+0.999, 
3,2 ).AsTextZM();
GO
-- LINESTRING (63.29 914.361 NULL 1, 73.036 899.855 NULL 18.48, 80.023 897.179 NULL 25.96, 79.425 902.707 NULL 31.52, 91.228 903.305 NULL 43.34, 79.735 888.304 NULL 62.23, 98.4 883.584 NULL 81.49, 115.73 903.305 NULL 107.74, 102.284 923.026 NULL 131.61, 99.147 899.271 NULL 155.57, 110.8 902.707 NULL 167.72, 90.78 887.02 NULL 193.15, 96.607 926.911 NULL 233.47, 95.71 926.313 NULL 234.55, 95.412 928.554 NULL 236.81, 101.238 929.002 NULL 242.65, 119.017 922.279 NULL 261.66)
WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength() +0.999, 3,2 ) as mLinestring
    FROM data as d
)
select 0 as m, linestring from data as d union all
SELECT v.sm, v.geom.STStartPoint().STBuffer(1) as sp
  FROM data as d
       cross apply
	   [dbo].[STSegmentLine] ( [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength() +0.999, 3,2 )) as v 
union all
SELECT 50, [lrs].[STFindPointByMeasure](e.mLinestring, 50.0, 0.0, 3, 2).STBuffer(2) as Measure2Point10Offset FROM mLine as e
GO

WITH data as (
  SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring
), mLine as (
  SELECT [lrs].[STAddMeasure] (d.linestring, 1.0, d.linestring.STLength() +0.999, 3,2 ) as mLinestring
    FROM data as d
)
select 0 as sm, 0 as em, linestring from data as d 
union all
select m.mlinestring.STPointN(g.IntValue).M as sm, null as em, m.mlinestring.STPointN(g.IntValue).STBuffer(2) as point from mLine as m cross apply dbo.generate_series(1,m.mLinestring.STNumPoints(),1) as g
union all
--SELECT 29, 49, [lrs].[STFindSegmentByLengthRange](e.mLinestring, 29, 49, 0.0, 3, 2).STBuffer(0.2) as Lengths2SegmentNoOffset FROM mLine as e
--union all
SELECT 30, 50, [lrs].[STFindSegmentByMeasureRange](e.mLinestring, 30, 50, 0.0, 3, 2) as Measures2SegmentNoOffset FROM mLine as e
GO

SELECT 30, 50, [lrs].[STFindSegmentByMeasureRange](
geometry::STGeomFromText('LINESTRING (63.29 914.361 NULL 1, 73.036 899.855 NULL 18.48, 80.023 897.179 NULL 25.96, 79.425 902.707 NULL 31.52, 91.228 903.305 NULL 43.34, 79.735 888.304 NULL 62.23, 98.4 883.584 NULL 81.49, 115.73 903.305 NULL 107.74, 102.284 923.026 NULL 131.61, 99.147 899.271 NULL 155.57, 110.8 902.707 NULL 167.72, 90.78 887.02 NULL 193.15, 96.607 926.911 NULL 233.47, 95.71 926.313 NULL 234.55, 95.412 928.554 NULL 236.81, 101.238 929.002 NULL 242.65, 119.017 922.279 NULL 261.66)',0),
30, 50, 0.0, 3, 2) as Measures2SegmentNoOffset



DECLARE @g geometry;  
SET @g = geometry::STGeomFromText('LINESTRING(0 0,0 0)', 0);  
SELECT @g.STIsValid();  


with data as (
select geometry::STGeomFromText('MULTILINESTRING((-4 -4 0  1, 0  0 0  5.6), (10  0 0 15.61, 10 10 0 25.4),(11 11 0 25.4, 12 12 0 26.818))',28355) as linestring
)
/* Measures */
select round(start_measure,3) as start_measure, 
       round(end_measure,  3) as end_measure, 
       offset, 
       case when f.fSegment is not null then f.fSegment.AsTextZM() else null end as fSegment 
  from (
select g.intValue   as start_measure,
       g.intValue+1 as end_measure,
       0.0          as offset
       ,[$(lrsowner)].[STFindSegmentByMeasureRange](
               linestring,
               g.IntValue,
               g.IntValue+1,
               0.0,3,2) as fsegment
  from data as a
       cross apply
       generate_series(a.lineString.STPointN(1).M,
                       round(a.lineString.STPointN(a.linestring.STNumPoints()-1).M,0,1),
                       1 ) as g
       -- cross apply [$(owner)].[GENERATE_SERIES](-1,1,1) as o
union all
/* Point Measures from Points */
select cast(linestring.STPointN(g.IntValue  ).M as numeric(8,3)) as start_measure,
       cast(linestring.STPointN(g.IntValue+1).M as numeric(8,3)) as end_measure,
       0.0          as offset,
       [$(lrsowner)].[STFindSegmentByMeasureRange] (
               linestring,
               cast(linestring.STPointN(g.IntValue  ).M as numeric(8,3)),
               cast(linestring.STPointN(g.IntValue+1).M as numeric(8,3)),
               0.0,3,2) as fSegment
  from data as a
       cross apply
       generate_series(1,
                       a.lineString.STNumPoints()-1,
                       1 ) as g
       --cross apply [$(owner)].[GENERATE_SERIES](-1,1,1) as o
--union all
--select null as start_measure, null as end_measure, null as offset,linestring as fSegment
--  from data as a
 ) as f;
GO

use spatialdb
go


SELECT [lrs].[STFindSegmentByLengthRange](
geometry::STGeomFromText('LINESTRING (63.29 914.361 NULL 1, 73.036 899.855 NULL 18.48, 
80.023 897.179 NULL 25.96, 
79.425 902.707 NULL 31.52, 
91.228 903.305 NULL 43.34, 
79.735 888.304 NULL 62.23, 
98.4 883.584 NULL 81.49, 115.73 903.305 NULL 107.74, 102.284 923.026 NULL 131.61, 99.147 899.271 NULL 155.57, 110.8 902.707 NULL 167.72, 90.78 887.02 NULL 193.15, 96.607 926.911 NULL 233.47, 95.71 926.313 NULL 234.55, 95.412 928.554 NULL 236.81, 101.238 929.002 NULL 242.65, 119.017 922.279 NULL 261.66)',0), 
30.0, 49.0, 0.0, -- 29.0, 49.0,
3, 2).AsTextZM() as Lengths2SegmentNoOffset;

-- LINESTRING (
-- 79.481 902.192 NULL 31, 
-- 79.425 902.707 NULL 31.52, 
-- 91.228 903.305 NULL 43.34, 
-- 87.175 898.015 NULL 50)

SELECT [lrs].[STFindSegmentByMeasureRange](
geometry::STGeomFromText(
'LINESTRING (63.29 914.361 NULL 1, 73.036 899.855 NULL 18.48, 
80.023 897.179 NULL 25.96, 
79.425 902.707 NULL 31.52, 
91.228 903.305 NULL 43.34, 
79.735 888.304 NULL 62.23, 
98.4 883.584 NULL 81.49, 115.73 903.305 NULL 107.74, 102.284 923.026 NULL 131.61, 99.147 899.271 NULL 155.57, 110.8 902.707 NULL 167.72, 90.78 887.02 NULL 193.15, 96.607 926.911 NULL 233.47, 95.71 926.313 NULL 234.55, 95.412 928.554 NULL 236.81, 101.238 929.002 NULL 242.65, 119.017 922.279 NULL 261.66)',0), 
29.0, 49.0, 0.0, 3, 2).AsTextZM() as Measure2SegmentNoOffset;
-- LINESTRING (
-- 76.904 926.011 NULL 29, 
-- 79.425 902.707 NULL 31.52, 
-- 91.228 903.305 NULL 43.34, 
-- 61.428 864.409 NULL 49)

SELECT CAST([lrs].[STSplitCircularStringByMeasure] (geometry::STGeomFromText('CIRCULARSTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32, 20 0 NULL 33.1)',0), 0, 32.0, 0.0,3,2 ).AsTextZM() as varchar(500)) as subString 
go
-- CIRCULARSTRING (0.036 0.985 NULL 1, 10.123 10.123 NULL 15.32, 20.001 0.099 NULL 32)

select geometry::STGeomFromText('CIRCULARSTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32, 20 0 NULL 33.1)',0);

USE SPATIALDB
GO

-- sqlcmd -S BIGGER-SPDBA\GISDB -v usedbname=SPATIALDB owner=dbo lrsowner=lrs cogoowner=cogo -i STTiling.sql

select [cogo].[STFindCircleFromArc](geometry::STGeomFromText('CIRCULARSTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32, 20 0 NULL 33.1)',0)).AsTextZM();
Select [cogo].[STBearing](10,0.123,20,0);
Select [cogo].[STPointFromBearingAndDistance](10,0.123,90.7047025512949/*[cogo].[STBearing](10,0.123,20,0)*/,10.0007564214,10,0).AsTextZM();

select geometry::STGeomFromText('CIRCULARSTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32, 20 0 NULL 33.1)',0).STLength() as len,
       geometry::STGeomFromText('CIRCULARSTRING (0 0 NULL 1, 10.123 10.123 NULL 15.32, 20 0 NULL 33.1)',0)
union all
select null, geometry::STGeomFromText('POINT (0 0 NULL 1)',0).STBuffer(0.3)
union all
select null, geometry::STGeomFromText('POINT (10.123 10.123 NULL 15.32)',0).STBuffer(0.3)
union all
select null, geometry::STGeomFromText('POINT (20 0 NULL 33.1)',0).STBuffer(0.3)
union all
select 14, geometry::STGeomFromText('POINT(8.178 9.956 NULL 15.19)',0).STBuffer(0.3)
union all
select 18, geometry::STGeomFromText('POINT (19.38 3.591 NULL 29.39)',0).STBuffer(0.3)
union all
select 0, geometry::STGeomFromText('POINT (10 0.123 10.00075642)',0).STBuffer(0.3);

SELECT [lrs].[STFindSegmentByLengthRange](geometry::STGeomFromText('LINESTRING (63.29 914.361 NULL 1, 73.036 899.855 NULL 18.48, 80.023 897.179 NULL 25.96, 79.425 902.707 NULL 31.52, 91.228 903.305 NULL 43.34, 79.735 888.304 NULL 62.23, 98.4 883.584 NULL 81.49, 115.73 903.305 NULL 107.74, 102.284 923.026 NULL 131.61, 99.147 899.271 NULL 155.57, 110.8 902.707 NULL 167.72, 90.78 887.02 NULL 193.15, 96.607 926.911 NULL 233.47, 95.71 926.313 NULL 234.55, 95.412 928.554 NULL 236.81, 101.238 929.002 NULL 242.65, 119.017 922.279 NULL 261.66)',0),
 29.0, 49.0, 0.0, 3, 2).AsTextZM() as Lengths2SegmentNoOffset;
go

with mLine as (
  SELECT geometry::STGeomFromText('LINESTRING (63.29 914.361 NULL 1, 73.036 899.855 NULL 18.48, 80.023 897.179 NULL 25.96, 79.425 902.707 NULL 31.52, 91.228 903.305 NULL 43.34, 79.735 888.304 NULL 62.23, 98.4 883.584 NULL 81.49, 115.73 903.305 NULL 107.74, 102.284 923.026 NULL 131.61, 99.147 899.271 NULL 155.57, 110.8 902.707 NULL 167.72, 90.78 887.02 NULL 193.15, 96.607 926.911 NULL 233.47, 95.71 926.313 NULL 234.55, 95.412 928.554 NULL 236.81, 101.238 929.002 NULL 242.65, 119.017 922.279 NULL 261.66)',0) as mLinestring
)
select 'ORGNL' as tSource, e.mLineString from mLine as e
union all
SELECT 'SGMNT', [lrs].[STFindSegmentByLengthRange](e.mLinestring, 29.0, 49.0, 0.0, 3, 2).STBuffer(0.3) as Lengths2Segment FROM mLine as e
union all
SELECT 'RIGHT', [lrs].[STFindSegmentByLengthRange](e.mLinestring, 29.0, 49.0, 1.0, 3, 2).STBuffer(0.3) as Lengths2Segment FROM mLine as e
union all
SELECT 'LEFT',  [lrs].[STFindSegmentByLengthRange](e.mLinestring, 29.0, 49.0,-1.0, 3, 2).STBuffer(0.3) as Lengths2Segment FROM mLine as e
GO

select a.IntValue as InsertPosn,
       [dbo].[STInsertN](geometry::STGeomFromText('LINESTRING (63.29 914.361 NULL 1, 73.036 899.855 NULL 18.48, 80.023 897.179 NULL 25.96, 79.425 902.707 NULL 31.52, 91.228 903.305 NULL 43.34, 79.735 888.304 NULL 62.23, 98.4 883.584 NULL 81.49, 115.73 903.305 NULL 107.74, 102.284 923.026 NULL 131.61, 99.147 899.271 NULL 155.57, 110.8 902.707 NULL 167.72, 90.78 887.02 NULL 193.15, 96.607 926.911 NULL 233.47, 95.71 926.313 NULL 234.55, 95.412 928.554 NULL 236.81, 101.238 929.002 NULL 242.65, 119.017 922.279 NULL 261.66)',0),
                         geometry::STGeomFromText('POINT (80.5823 901.3054 NULL 30)',0),
                         a.IntValue,
                         1,
                         2).AsTextZM() as geom
  from [dbo].[GENERATE_SERIES](-1,4,1) a
GO

select 'From/To/Right',
       sAngle,
       actualDegrees,
	   [cogo].[STDegrees](sAngle) as computedDegrees 
  from (select  45 as actualDegrees,[cogo].[STSubtendedAngle] (0,-1,0,0,1,-1) as sAngle
		union all
		select  90, [cogo].[STSubtendedAngle] (0,-1,0,0,1,0) 
		union all
		select 135, [cogo].[STSubtendedAngle] (0,-1,0,0,1,1) 
		union all
		select 180, [cogo].[STSubtendedAngle] (0,-1,0,0,0,1) 
		union all
		select 225, [cogo].[STSubtendedAngle] (0,-1,0,0,-1,1)
		union all
		select 270, [cogo].[STSubtendedAngle] (0,-1,0,0,-1,0)
		union all
		select 315, [cogo].[STSubtendedAngle] (0,-1,0,0,-1,-1)
       ) as a
union all
select 'To/From/Left',
       sAngle,
       actualDegrees,
       [cogo].[STDegrees](sAngle) as computedDegrees 
  from (select  45 as actualDegrees, [cogo].[STSubtendedAngle] (1,-1,0,0,0,-1) as sAngle 
		union all
		select  90, [cogo].[STSubtendedAngle] (1,0,0,0,0,-1) 
		union all
		select 135, [cogo].[STSubtendedAngle] (1,1,0,0,0,-1) 
		union all
		select 180, [cogo].[STSubtendedAngle] (0,1,0,0,0,-1) 
		union all
		select 225, [cogo].[STSubtendedAngle] (-1,1,0,0,0,-1)
		union all
		select 270, [cogo].[STSubtendedAngle] (-1,0,0,0,0,-1)
		union all
		select 315, [cogo].[STSubtendedAngle] (-1,-1,0,0,0,-1) 
       ) as b;
GO

select offset,
       left_right, 
       sAngle         as subtendedAngle,
       aAngle         as adjustedAngle, 
	   [cogo].[STDegrees](sAngle) as aDeg,
       angleAsDegrees,
	   case when sign(offset) = -1 then 360 - actualDegrees else actualDegrees end as actualDegrees,
	   [cogo].[STisAcute](sAngle,offset) as isAcute,
	   [cogo].[STFindPointBisector](first_segment,second_segment,offset,8,8) as bisectorPoint,
       [cogo].[STFindPointBisector](first_segment,second_segment,offset,8,8).STBuffer(0.1).STUnion(first_segment.STUnion(second_segment).STBuffer(0.05)) as segments
  from (select g.IntValue as offset,
               aDegrees,
			   actualDegrees,
               case when g.IntValue = 1 
                    then 'From/To/Right (' + CAST(g.IntValue as varchar(10)) + 've offset)'
                    else 'From/To/Left  (' + CAST(g.IntValue as varchar(10)) + 've offset)'
                 end as left_right,
               sAngle,
               case when g.IntValue = 1
                    then case when Sign(sAngle) = 1
                              then sAngle
                              else 2*PI() - ABS(sAngle)
                          end
                    else case when Sign(sAngle) = 1
                              then 2*PI() - sAngle
                              else ABS(sAngle)
                          end
                end as aAngle,
               case when g.IntValue = 1
                    then case when Sign(sAngle) = 1
                              then [cogo].[STDegrees](sAngle)
                              else [cogo].[STDegrees](2*PI() - ABS(sAngle))
                          end
                    else case when Sign(sAngle) = 1
                              then [cogo].[STDegrees](2*PI() - ABS(sAngle))
                              ELSE [cogo].[STDegrees](ABS(sAngle))
                          end
                end as angleAsDegrees,
                first_segment,
                second_segment
          from (select [cogo].[STSubtendedAngle]        (sx,sy,mx,my,ex,ey) as sAngle,
                       [cogo].[STSubtendedAngleDegrees] (sx,sy,mx,my,ex,ey) as aDegrees,
					   actualDegrees,
                       [dbo].[STMakeLine](geometry::Point(sx,sy,0), geometry::Point(mx,my,0),8,8) as first_segment,
                       [dbo].[STMakeLine](geometry::Point(mx,my,0), geometry::Point(ex,ey,0),8,8) as second_segment
                  from (select 45 as actualDegrees, 0 as sx,-1 as sy, 0 as mX,0 as mY, 1 as eX,-1 as ey
                        union all
                        select 90 as actualDegrees,0,-1, 0,0, 1,0
                        union all
                        select 135 as actualDegrees,0,-1, 0,0, 1,1 
                        union all
                        select 180 as actualDegrees,0,-1, 0,0, 0,1 
                        union all
                        select 225 as actualDegrees,0,-1, 0,0, -1,1
                        union all
                        select 270 as actualDegrees,0,-1, 0,0, -1,0
                        union all
                        select 315 as actualDegrees,0,-1, 0,0, -1,-1
                        ) as a
              ) as b
              cross apply
              [dbo].[Generate_Series] ( -1, 1, 2 ) as g
       ) as f
go

SELECT charindex('3456','23232,23232,3456,23423');

with objectids as (
select 1 as gid, '23232' as objectid 
         union all 
		select 1 as gid, '3456' as objectid 
         union all 
		select 1 as gid, '23423' as objectid 
)
select STUFF((SELECT ',' + b.objectid 
                FROM objectids b 
               ORDER BY b.objectid 
               FOR XML PATH(''), TYPE, ROOT).value('root[1]','varchar(max)'),1,1,'') AS oids ;



SELECT SUBSTRING(a.gtype,5,LEN(a.gtype)) + ''''''
  FROM (SELECT (STUFF((SELECT DISTINCT ''''',''''' + a.gtype
                         FROM ( select distinct t.token as gtype
                                  from [dbo].[TOKENIZER]('LineString:MultiLineString:MultiPoint:MultiPolygon:Point:Point:LineString:Polygon:Polygon',':') as t
                              ) a
                        ORDER BY ''''',''''' + a.gtype
                       FOR XML PATH(''), TYPE, ROOT).value('root[1]','nvarchar(max)'),1,1,'''')
                ) AS gtype
        ) as a
GO
