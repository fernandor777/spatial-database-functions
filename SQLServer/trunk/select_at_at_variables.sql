use gisdb
go


SELECT @@VERSION;

SELECT CAST(SubString(@@VERSION,1,CHARINDEX('-',@@VERSION,1)-1) as varchar(30)) as DatabaseVersion;

SELECT SUBSTRING(REPLACE(@@VERSION,'Microsoft SQL Server ',''),1,4) as DatabaseVersion;

SELECT SUBSTRING(f.ver,PATINDEX('%[0-9]%',f.ver),4) FROM (SELECT @@VERSION as ver) as f;

SELECT @@VERSION as DatabaseVersion;

select @@MAX_PRECISION;

select @@MICROSOFTVERSION;

select @@DBTS;

select @@SERVICENAME;

select @@SERVERNAME;

select @@SPID;

select @@OPTIONS;

select serverproperty('ProductMajorVersion') as major, 
       serverproperty('ProductMinorVersion') as minor, 
	   SERVERPROPERTY('ProductVersion') as pv, 
	   SERVERPROPERTY('Edition') as edn,
	   SERVERPROPERTY('InstanceName') as instance,
	   SERVERPROPERTY('ProductBuild') as prodbuild2014,
	   SERVERPROPERTY('ProductLevel') as prodLevel;

SELECT name FROM sys.schemas where principal_id = 1 order by 1;
go

WITH data As (
SELECT geometry::STGeomFromText('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',0) as geoma,
       geometry::STGeomFromText('POLYGON ((-175.0 0.0, 100.0 0.0, 0.0 75.0, 100.0 75.0, 100.0 200.0, 200.0 325.0, 200.0 525.0, -175.0 525.0, -175.0 0.0))',0) as geomb
)
SELECT CAST('POLY A' as varchar(12)) as source, d.geoma.AsTextZM() as geoma from data as d
union all
SELECT 'POLY B' as source, d.geomb.AsTextZM() as geomb from data as d
union all
SELECT 'Intersection' as source, [dbo].[STRound](d.geoma.STIntersection(d.geomb),2,1).AsTextZM() as geom FROM data as d
union all
SELECT 'RESULT' as source, [dbo].[STRound]([dbo].[STExtractPolygon](d.geoma.STIntersection(d.geomb)),2,1).AsTextZM() as geom FROM data as d;
GO

select e.gid, sid, geom.AsTextZM() as egeom
  FROM [dbo].[STExtract] (geometry::STGeomFromText('GEOMETRYCOLLECTION (POLYGON ((100 200, 180 300, 100 300, 100 200)), LINESTRING (100 200, 100 75), POINT (100 0))',0),0) as e;

select e.gid, sid, geom.AsTextZM() as egeom
  FROM [dbo].[STExtract] (geometry::STGeomFromText('MULTILINESTRING((0 0,5 5,10 10,11 11,12 12),(100 100,200 200))',0),1) as e;


  select f.iPoint.STAsText() as iPoint,
       f.iPoint1.STAsText() as iPoint1,
       f.iPoint2.STAsText() as iPoint2
  FROM [cogo].[STFindSegmentIntersection] (
                 geometry::STLineFromText('LINESTRING(0 0,10 10)',0),
                 geometry::STLineFromText('LINESTRING(0 10,10 0)',0)
       ) as f;
GO

SELECT i.inter_x, i.inter_y, i.inter_x1, i.inter_y1, i.inter_x2, i.inter_y2 FROM [cogo].[STFindLineIntersection](0,0,10,10,0,10,10,0) as i;

With data as (
  select geometry::Parse('POINT(100.123 100.456 NULL 4.567)') as pointzm
)
SELECT d.pointzm.STGeometryType() as gt, 
       d.pointzm.HasZ as z, 
       d.pointzm.HasM as m, 
       [dbo].[STSetZ](d.pointzm,99.123,3,1).AsTextZM() as rGeom
  FROM data as d; 
GO

use SPATIALDB
GO
select [dbo].[STUpdate](geometry::STGeomFromText('POINT(0 0 1 1)',0),
                             geometry::STGeomFromText('POINT(0 0 1 1)',0),
                             geometry::STGeomFromText('POINT(1 1 1 1)',0),2,1).AsTextZM() as WKT
GO
select [dbo].[STUpdate](geometry::STGeomFromText('MULTIPOINT((1 1 1 1),(2 2 2 2),(3 3 3 3))',0),
                             geometry::STGeomFromText('POINT(2 2 2 2)',0),
                             geometry::STGeomFromText('POINT(2.1 2.1 2 2)',0),2,1).AsTextZM() as wkt
GO
Select [dbo].[STUpdate](geometry::STGeomFromText('LINESTRING(1 1, 2 2, 3 3, 4 4)',0),
                             geometry::STGeomFromText('POINT(3 3)',0), 
                             geometry::STGeomFromText('POINT(2.1 2.5)',0),2,1).AsTextZM() as WKT
GO
select [dbo].[STUpdate](geometry::STGeomFromText('MULTILINESTRING((1 1,2 2,3 3),(4 4,5 5,6 6))',0),
                             geometry::STGeomFromText('POINT(3 3)',0),
                             geometry::STGeomFromText('POINT(3.1 3.3)',0),2,1).AsTextZM() as WKT
GO

select [dbo].[STUpdate](geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(9.962 -0.872,10.1 0,9.962 0.872),(9.962 0.872,0 0,9.962 -0.872))',0),
                              geometry::STGeomFromText('POINT(9.962 0.872)',0),
                              geometry::STGeomFromText('POINT(9.9 0.9)',0),2,1).AsTextZM() as WKT
GO

-- 'Polygon - First and lat point of ring update.
select [dbo].[STUpdate](geometry::STGeomFromText('POLYGON((1 1,10 1,10 10,1 10,1 1),(2 2,9 2,9 9,2 9,2 2))',0),
                             geometry::STGeomFromText('POINT(1 1)',0),
                             geometry::STGeomFromText('POINT(1.1 1.1)',0),2,1).AsTextZM() as WKT
GO
select [dbo].[STUpdate](geometry::STGeomFromText('POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0))',28355),
                             geometry::STGeomFromText('POINT(326000.0 5455000.0)',28355),
                             geometry::STGeomFromText('POINT(326100.0 5455100.0)',28355),2,1).AsTextZM() as WKT
GO
select [dbo].[STUpdate](geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5),POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0)))',0),
                             geometry::STGeomFromText('POINT(3 4 5)',0),
                             geometry::STGeomFromText('POINT(3.1 4.1 5.1)',0),2,1).AsTextZM() as WKT
GO

With data as (
  select geometry::Parse('POINT(100.123 100.456 NULL 4.567)') as pointzm
)
SELECT CAST(d.pointzm.STGeometryType() as varchar(20)) as GeomType, 
       d.pointzm.HasZ as z, 
       d.pointzm.HasM as m, 
       CAST([dbo].[STSetZ](d.pointzm,99.123,3,1).AsTextZM() as varchar(50)) as rGeom
  FROM data as d; 
GO

select e.[sid], e.[rid], e.[pid], e.[x], e.[y], e.[z], e.[m]
  from [dbo].[STDumpPoints](geometry::STGeomFromText(
'GEOMETRYCOLLECTION(
POLYGON((0 0, 100 0, 100 100, 0 100, 0 0)),
POINT(2 3 4),
MULTIPOINT((1 1),(2 2),(3 3)),
LINESTRING(2 3 4,3 4 5),
MULTILINESTRING((2 3 4,3 4 5),(1 1,2 2)),
POINT(4 5),
MULTIPOINT((1 1),(2 2)),
POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0)),
MULTIPOLYGON(((200 200, 400 200, 400 400, 200 400, 200 200)), ((0 0, 100 0, 100 100, 0 100, 0 0), (40 40,60 40,60 60,40 60,40 40))))',0)) as e
GO

USE SPATIALDB
GO


select [lrs].[STProjectPoint] (
          geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
          geometry::Point(8,8,28355),
          3,2).AsTextZM();
GO

Print '  [lrs].[STFindMeasureByPoint] ...';
GO
select [lrs].[STFindMeasureByPoint](
          geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
          geometry::Point(8,8,28355),
          3,2);
GO

Print '  [lrs].[STInterpolatePoint] ...';
GO
select [lrs].[STInterpolatePoint] (
         geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
         geometry::Point(8,8,28355),
         3,2);
GO

Print '  [lrs].[STFindMeasure] ...';
GO
select [lrs].[STFindMeasure](
         geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
         geometry::Point(8,8,28355),
         3,2);
GO

Print '  [lrs].[STFindOffset] ...';
GO
select [lrs].[STFindOffset](
          geometry::STGeomFromText('LINESTRING(-4 -4 0 1, 0 0 0 5.6, 10 0 0 15.61, 10 10 0 25.4)',28355),
         geometry::Point(8,8,28355),
         3,2);
GO

SELECT [lrs].[STAddMeasure] (
         [dbo].[STAddZ] (
           geometry::STGeomFromText('LINESTRING(0 0,0.5 0.5,1 1)',0),
           1.232,
           1.523,
          3, 2 
         ),
		 0.0,
		 1.414,
		 3,2).AsTextZM() as LineWithZM;
GO

SELECT geometry::STGeomFromText('LINESTRING(63.29 914.361, 73.036 899.855, 80.023 897.179,79.425 902.707, 91.228 903.305,79.735 888.304, 98.4 883.584,   115.73  903.305, 102.284 923.026,99.147 899.271, 110.8 902.707,  90.78 887.02, 96.607 926.911,95.71 926.313, 95.412 928.554, 101.238 929.002, 119.017 922.279)',0) as linestring;
GO

