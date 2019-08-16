use GISDB
go

with data as (
--  select 'Ordinary 2 Point Linestring' as test, 
--         geometry::STGeomFromText('LINESTRING(0 0 0 1, 10 0 0 2)',0) as linestring
--union all
select 'CircularArc (anticlockwise)' as test, geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 20 0)',28355) as linestring
--union all
--select 'Ordinary 2 Point Linestring (after circularArc)'   as test,  geometry::STGeomFromText('LINESTRING(20 0 0 15.6, 20 -4 34.5)',28355) as linestring
--union all
--select 'Proper CircularArc (clockwise)'               as test,  geometry::STGeomFromText('CIRCULARSTRING(20 0, 15 5, 10 0)',28355) as linestring
)
select d.test, 0.0 as bufferDistance, d.linestring.STBuffer(0.1) as sqBuff 
  from data as d
--       cross apply
--       [dbo].[generate_series](-15,15,5) as g
--where g.intValue <> 0
union all
select d.test, 
       g.intValue as bufferDistance, 
       [dbo].[STSquareBuffer](d.linestring,CAST(g.intValue as float),3,2) as sqBuff
  from data as d
       cross apply
       [dbo].[generate_series](5,5,0) as g
 where g.intValue <> 0
GO



with data as (
select 'Ordinary 2 Point Linestring' as test, 
       geometry::STGeomFromText('LINESTRING(0 0 0 1, 1 0 0 2)',0) as linestring
--union all
--select 'CircularArc (anticlockwise)'                       as test,  geometry::STGeomFromText('CIRCULARSTRING(10 0, 15 5, 20 0)',28355) as linestring
--union all
--select 'Ordinary 2 Point Linestring (after circularArc)'   as test,  geometry::STGeomFromText('LINESTRING(20 0 0 15.6, 20 -4 34.5)',28355) as linestring
--union all
--select 'Proper CircularArc (clockwise)'               as test,  geometry::STGeomFromText('CIRCULARSTRING(20 0, 15 5, 10 0)',28355) as linestring
)
select d.test, 0.0 as bufferDistance, d.linestring.STBuffer(0.1) as sqBuff from data as d
union all
select d.test, 
       CAST(g.intValue/3.0 as float) as bufferDistance, 
       [dbo].[STSquareBuffer](d.linestring,CAST(g.intValue/3.0 as float),3,2) as sqBuff
  from data as d
       cross apply
       GENERATE_SERIES(-15,30,5) as g;
GO

QUIT
GO

with data as (
select 'Ordinary 2 Point Linestring' as test, geometry::STGeomFromText('LINESTRING(0 0, 1 0)',0) as linestring
union all
select 'Self Joining Linestring'     as test, geometry::STGeomFromText('LINESTRING(0 0,1 0,2 3,4 5,2 10,-1 5,0 0)',0) as linestring
union all
select 'Ends within buffer distance' as test, geometry::STGeomFromText('LINESTRING(0 0,1 0,2 3,4 5,2 10,-1 5,0 0.3)',0) as linestring
)
select d.linestring as sqBuff from data as d
union all
select [dbo].[STOneSidedBuffer](d.linestring,0.5,/*@p_square*/0,2,1) as sqBuff from data as d;
GO

