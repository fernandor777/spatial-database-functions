USE [GISDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

BEGIN TRY
  drop   table dbo.GridExample;
END TRY
BEGIN CATCH
END CATCH

select distinct geometry::STPolyFromText(geoWKT,28355).STIsValid() as geog
  from dbo.STREGULARGRID(0,0,1000,1000,100,100)
GO

select row_number() over (order by rand()) as rid,
       geometry::STPolyFromText(geoWKT,28355) as geog
  into dbo.GridExample
  from dbo.STREGULARGRID(0,0,1000,1000,100,100)
GO

With QExtent As
(select min( a.geom.STEnvelope().STPointN(1).STX ) as minx,
	    min( a.geom.STEnvelope().STPointN(1).STY ) as miny,
	    max( a.geom.STEnvelope().STPointN(3).STX ) as maxx,
	    max( a.geom.STEnvelope().STPointN(3).STY ) as maxy
  from (select dbo.toGeometry(s.geog) as geom  
 		  from dbo.australian_States s
		 where [GMI_ADMIN] = 'AUS-QNS' 
	    ) a
)
select row_number() over (order by rand()) as rid,
       geography::STPolyFromText(geoWKT,4326) as geog
  from QExtent b cross apply
       dbo.STREGULARGRID(b.minx, b.miny, b.maxx, b.maxy,0.5,0.5);

select hiCol - loCol as numCols,
       hiRow - loRow as numRows,
       (hiCol - loCol ) * ( hiRow - loRow ) as numCells 
  from (
SELECT FLOOR( minx / 0.00225 ) as loCol, 
     CEILING( maxx / 0.00225 ) - 1 as hiCol, 
       FLOOR( miny / 0.00225 ) as loRow,
     CEILING( maxy / 0.00225 ) - 1 as hiRow
  from ( select min( a.geom.STEnvelope().STPointN(1).STX ) as minx,
				min( a.geom.STEnvelope().STPointN(1).STY ) as miny,
				max( a.geom.STEnvelope().STPointN(3).STX ) as maxx,
				max( a.geom.STEnvelope().STPointN(3).STY ) as maxy
		  from (select dbo.toGeometry(s.geog) as geom  
 				  from dbo.australian_States s
				 where [GMI_ADMIN] = 'AUS-QNS' 
				) a
	  ) b
) c;

select MAX(a.[IntValue]) - MIN(a.[IntValue])
from dbo.generate_series(-12965,-4468,1) a;

BEGIN TRY
  drop   table dbo.GridExampleLL;
END TRY
BEGIN CATCH
END CATCH

With QExtent As
(select min( a.geom.STEnvelope().STPointN(1).STX ) as minx,
	    min( a.geom.STEnvelope().STPointN(1).STY ) as miny,
	    max( a.geom.STEnvelope().STPointN(3).STX ) as maxx,
	    max( a.geom.STEnvelope().STPointN(3).STY ) as maxy
  from (select dbo.toGeometry(s.geog) as geom  
 		  from dbo.australian_States s
		 where [GMI_ADMIN] = 'AUS-QNS' 
	    ) a
)
select row_number() over (order by rand()) as rid,
       geography::STPolyFromText(geoWKT,s.geog.STSrid) as geog
  into dbo.GridExampleLL
  from (select s.geog 
 		  from dbo.australian_States s
		 where [GMI_ADMIN] = 'AUS-QNS') a
	   cross join
	   QExtent b cross apply
       dbo.STREGULARGRID(b.minx, b.miny, b.maxx, b.maxy,0.5/* approx 250m*/,0.5/* approx 250m*/)
 where a.geog.STIntersects(geography::STPolyFromText(geoWKT,s.geog.STSrid)) = 1;

/* Or ..... without CTE 
 */
select row_number() over (order by rand()) as gid,
       geography::STPolyFromText(geoWKT,s.geog.STSrid) as geog
  into GridExampleLL
  from dbo.AOI s
	   cross apply
	   (select min( a.geom.STEnvelope().STPointN(1).STX ) as minx,
	           min( a.geom.STEnvelope().STPointN(1).STY ) as miny,
	           max( a.geom.STEnvelope().STPointN(3).STX ) as maxx,
	           max( a.geom.STEnvelope().STPointN(3).STY ) as maxy
          from (select dbo.toGeometry(s.geog) as geom) a
        ) b 
	   cross apply
       dbo.STREGULARGRID(b.minx, b.miny, b.maxx, b.maxy,0.00225/* approx 250m*/,0.00225/* approx 250m*/) c
 where s.geog.STIntersects(geography::STPolyFromText(c.geoWKT,s.geog.STSrid)) = 1;

select * from GridExampleLL;

/* Alternate Method using Spatial Tools ShiftGeometry function and my port of the PostgreSQL generate_series function 
 */
use GISDB
go

DECLARE @gridx Int = 250;
DECLARE @box geometry; -- = 'POLYGON((0 0,10000 0,10000 10000,0 10000,0 0))';
SELECT @box = dbo.MBR2GEOMETRY(0,0,10000,10000,28355);
With TasExtent As
(select min( a.geom.STEnvelope().STPointN(1).STX ) as minx,
        min( a.geom.STEnvelope().STPointN(1).STY ) as miny,
        max( a.geom.STEnvelope().STPointN(3).STX ) as maxx,
        max( a.geom.STEnvelope().STPointN(3).STY ) as maxy
  from (select s.geom from dbo.Delaunay s) a
)
SELECT dbo.ShiftGeometry(one_grid.geom, x_series.IntValue, y_series.IntValue) as geom
  INTO TasGrid
  FROM TasExtent a
       cross apply 
       dbo.generate_series( a.minx - 1, a.maxx + 1, @gridx) as x_series
       cross apply
       dbo.generate_series( a.miny - 1, a.maxy + 1, @gridx) as y_series,
       (SELECT @box as geom
	    UNION ALL
        SELECT dbo.ShiftGeometry(@box, @gridx, @gridx) as geom
       ) as one_grid;

--      2952 x 10,000m grids in  6 seconds
--   292,320 x  1,000m grids in 47 seconds
-- 4,664,872 x    250m grids in 16 minutes 28 seconds

use GISDB
go

drop table dbo.tas_grids;
create table dbo.tas_grids (
  gid int identity(1,1) not null,
  geog geography
);

insert into dbo.tas_grids(geog)
select dbo.ToGeography(g.grid_cell,c.GEOG.STSrid)
  from Tas_LGA c
       Cross Apply
       dbo.REGULARGRIDGEOM( dbo.ToGeometry(c.geog,0), c.geog.STSrid, 0.0450, 0.0450 ) as g;

alter table dbo.tas_grids add constraint pk_tas_grids_gid primary key (gid);

CREATE SPATIAL INDEX [SPIDX_tas_grids_geog] ON [$(owner)].[TAS_GRIDS] ( [GEOG] )
 USING  GEOGRAPHY_GRID 
  WITH ( GRIDS =(LEVEL_1 = LOW, LEVEL_2 = LOW,LEVEL_3 = LOW,LEVEL_4 = LOW), 
         CELLS_PER_OBJECT = 16 ) 
    ON [PRIMARY]
GO

select * from tas_grids;

drop table dbo.tas_lga_grids;
create table dbo.tas_lga_grids (
  gid     int identity(1,1) not null primary key,
  lga_pid char(15),
  geog    geography 
);

insert into dbo.tas_lga_grids (lga_pid,geog)  
select d.LGA_PID, d.clip_grid
  from (select c.LGA_PID, 
               c.GEOG.STIntersection(dbo.ToGeography(g.grid_cell,c.GEOG.STSrid)) as clip_grid
          from Tas_LGA c
               Cross Apply
               dbo.REGULARGRIDGEOM( dbo.ToGeometry(c.geog,0), c.geog.STSrid, 0.0450, 0.0450 ) as g
        ) d
 Where CHARINDEX('POLYGON',d.clip_grid.STAsText()) <> 0; 

alter table dbo.tas_lga_grids add constraint FK_tas_lga_pid foreign key (lga_pid) references dbo.tas_lga(lga_pid);

select COUNT(*)
  from dbo.tas_lga_grids;

-- alter table dbo.tas_lga_grids add gid int identity(1,1) not null primary key;

select COUNT(*) 
  from (select distinct a.LGA_PID, a.tas_gid
  from (select l.gid as lga_gid, 
               c.gid as tas_gid, 
               l.lga_pid,
               c.geog.STIntersection(l.clip_grid) as igeog
          from dbo.tas_lga_grids l,
               dbo.Tas_Grids c
               with (index (SPIDX_tas_grids_geog))
         where c.geog.STIntersects(l.clip_grid) = 1
        ) as a
 where CHARINDEX('POLYGON',a.iGEOG.STAsText()) <> 0 ) as b;

-- 55 minutes for 26,818 grids
-- 42 minutes 49 seconds for 26,818 grids
-- 32 minutes 31 seconds for 26,818 grids
-- 45 minutes 24 seconds for 26,818 grids
-- 46 minutes  9 seconds for 26,818 grids
-- 44 minutes 37 seconds for 8727 (distinct)

select COUNT(*) /*d.gid, d.LGA_PID, d.geog */
  from (select l.fulltext_id as lga_gid,
               c.gid         as tas_gid,
               l.lga_pid,
               c.GEOG.STIntersection(l.GEOG) as iGeog
          from dbo.tas_lga l,
               dbo.Tas_Grids c
               with (index (SPIDX_tas_grids_geog))
         where c.geog.STIntersects(l.GEOG) = 1             
        ) d
 Where CHARINDEX('POLYGON',d.iGeog.STAsText()) <> 0;  
 
 -- 1 hour 17 minutes 55 seconds 8727

