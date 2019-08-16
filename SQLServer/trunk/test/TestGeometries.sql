use gisdb
go

With Geoms As (
            select 1 as id, geometry::STGeomFromText('POINT(4 5)',0) as geom
  union all select 2 as id, geometry::STGeomFromText('MULTIPOINT((1 1 1))',0) as geom
  union all select 3 as id, geometry::STGeomFromText('MULTIPOINT((1 1 1),(2 2 2),(3 3 3))',0) as geom

  union all select 4 as id, geometry::STGeomFromText('LINESTRING(0 0, 10 0)',0) as geom
  union all select 5 as id, geometry::STGeomFromText('MULTILINESTRING((2 3, 3 4), (1 1, 2 2))',0) as geom
  union all select 6 as id, geometry::STGeomFromText('CIRCULARSTRING(0 -23.43778, 0 0, 0 23.43778)',0) as geom
  union all select 7 as id, geometry::STGeomFromText('COMPOUNDCURVE(
    CIRCULARSTRING(0 -23.43778, 0 0, 0 23.43778),
    CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778),
    CIRCULARSTRING(-90 23.43778, -90 0, -90 -23.43778),
    CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))',0) as geom
  union all select 8 as id, geometry::STGeomFromText('COMPOUNDCURVE(
    (0 -23.43778, 0 23.43778),
    CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778), 
    (-90 23.43778, -90 -23.43778),
    CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778))
  ',0) as geom
  union all select  9 as id, geometry::STGeomFromText('POLYGON((1 1, 1 6, 11 6, 11 1, 1 1))',0) as geom
  union all select 10 as id, geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0) as geom
  union all select 11 as id, geometry::STGeomFromText('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((30 30, 50 30, 50 50, 30 50, 30 30)), ((0 30, 20 30, 20 50, 0 50, 0 30)), ((30 0,31 0,31 1,30 1,30 0)))',0) as geom
  union all select 12 as id, geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5))',0) as geom
  union all select 13 as id, geometry::STGeomFromText('GEOMETRYCOLLECTION(POINT(2 3 4),LINESTRING(2 3 4,3 4 5),POLYGON((326000.0 5455000.0,327000.0 5455000.0,326500.0 5456000.0,326000.0 5455000.0)))',0) as geom
  union all select 14 as id, geometry::STGeomFromText('CURVEPOLYGON(CIRCULARSTRING(0 50, 50 100, 100 50, 50 0, 0 50))',0) as geom
  union all select 15 as id, GEOMETRY::STGeomFromText('
  CURVEPOLYGON(
    COMPOUNDCURVE(
      (0 -23.43778, 0 23.43778),
      CIRCULARSTRING(0 23.43778, -45 23.43778, -90 23.43778), 
      (-90 23.43778, -90 -23.43778),
      CIRCULARSTRING(-90 -23.43778, -45 -23.43778, 0 -23.43778)
    )
  )
',0).AsTextZM() as geom 
)
select *
 from (
select id, 
       GeometryType,
       isCoordString, 
       case when isCoordString = 'Y' 
	        then case when ISNULL(lag(token,1) over (order by id),'') = '' 
			          then case when GeometryType = 0 then 'LINESTRING' 
                                when GeometryType = 1 then 'POLYGON' 
					            when GeometryType = 2 then 'POINT' 
								else 'LINESTRING' end
			          else (lag(token,1) over (order by id)) 
				  end 
			else token
	    end as subObject,
	   token, separator
  from (select t.id,
               max(case when t.id = 1 and t.token = 'CURVEPOLYGON'    then 0
        	            when t.id = 1 and t.token like '%POLYGON%'    then 1 
			            when t.id = 1 and t.token like '%MULTIPOINT%' then 2
	                    else 0 
        			end) over (order by t.id) as GeometryType,
               case when PATINDEX('%[-0-9]%',t.token) > 0 then 'Y' else 'F' end as isCoordString,
               case when PATINDEX(', %',LTRIM(t.token)) = 1 then replace(ltrim(t.token),', ','') else ltrim(t.token) end token, 
        	   t.separator
          from geoms as a 
               cross apply 
        	   dbo.Tokenizer(a.geom.AsTextZM(),'()') as t
         where a.id = 14
       ) as f
	   ) as g 
 where isCoordString = 'Y' and subObject <> token
GO
 
 /*
 -- Main WKT Tokens
 POLYGON
 CURVEPOLYON
 MULTIPOLYGON
 COMPOUNDCURVE (when first token)

 -- Sub Tokens
 COMPOUNDCURVE (when under top token CURVEPOLYGON)
 CIRCULARSTRING

select geometry::STGeomFromText('MultiCurve((3 2, 4 3),CircularString(0 0, 1 1, 0 0))',0);

select geometry::STGeomFromText(
'MULTILINESTRING(
   COMPOUNDCURVE(
      CIRCULARSTRING(0 0, 1 1, 1 0),
	  (1 0, 0 1)
   ),
   (0 0, 5 5),
   CIRCULARSTRING(4 0, 4 4, 8 4),
   (10 10, 15 15)
   )',0) as geom
*/

select t.gid, t.sid, t.geom, t.geom.STGeometryType() as geom
  from [dbo].[STEXTRACT](geometry::STGeomFromText('CURVEPOLYGON(CIRCULARSTRING(0 50, 50 100, 100 50, 50 0, 0 50))',0),1) as t
GO

QUIT
