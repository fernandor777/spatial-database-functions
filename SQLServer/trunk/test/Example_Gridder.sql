USE $(usedbname)
GO

DECLARE @tname nvarchar(128);
SET @tname = 'dbo.MyGrid';  -- CHANGE THIS
DECLARE @minx float;
DECLARE @miny float;
DECLARE @maxx float;
DECLARE @maxy float;
DECLARE @xgrid float = (0.00225 / 5);
DECLARE @ygrid float = (0.00225 / 5);
DECLARE @srid Int;
DECLARE @geographyType Int = 1;
select TOP 1 @srid = a.geom.STSrid from dbo.QGC_AOI a;
SELECT @minx = c.minx,
       @miny = c.miny,
       @maxx = c.maxx,
       @maxy = c.maxy
  from (select min( a.geom.STEnvelope().STPointN(1).STX ) as minx,
               min( a.geom.STEnvelope().STPointN(1).STY ) as miny,
               max( a.geom.STEnvelope().STPointN(3).STX ) as maxx,
               max( a.geom.STEnvelope().STPointN(3).STY ) as maxy
          from (select dbo.toGeometry(s.geog,0) as geom from dbo.QGC_AOI) a
        ) c;
Print cast(@srid as varchar(10)) + ' ' + cast(@minx as varchar(10)) + ' ' + cast(@miny as varchar(10))  + ' ' + cast(@maxx as varchar(10))  + ' ' + cast(@maxy as varchar(10));
exec dbo.Gridder @minx, @miny, @maxx, @maxy, @xgrid, @ygrid, @srid, @tname, @geographyType;

use GISDB
go

drop table dbo.TasGrid2;
DECLARE @gridx Int = 250;
DECLARE @gridy Int = 250;
DECLARE @srid Int;
select TOP 1 @srid = a.geom.STSrid from dbo.Delaunay a;
DECLARE @box geometry;
SELECT @box = dbo.MBR2GEOMETRY(0,0,@gridx,@gridy,@srid);
With TasExtent As
(select Floor(min( a.geom.STEnvelope().STPointN(1).STX ) / @gridx) * @gridx as minx,
        Floor(min( a.geom.STEnvelope().STPointN(1).STY ) / @gridy) * @gridy as miny,
        Round(max( a.geom.STEnvelope().STPointN(3).STX ) / @gridx,0) * @gridx as maxx,
        Round(max( a.geom.STEnvelope().STPointN(3).STY ) / @gridy,0) * @gridy as maxy
  from (select s.geom from dbo.Delaunay s) a
)
SELECT dbo.ShiftGeometry(@box, x_series.IntValue, y_series.IntValue) as geom
  INTO TasGrid2
  FROM TasExtent a
       cross apply 
       dbo.generate_series( a.minx - 1, a.maxx + 1, @gridx) as x_series
       cross apply
       dbo.generate_series( a.miny - 1, a.maxy + 1, @gridy) as y_series;

-- 2952 x 10,000m grids in 6 seconds
-- 292,320 x 1,000m grids in 47 seconds
-- 2,335,497 x 250 grids in 6 minutes 27 seconds

drop table dbo.TasGrid;

DECLARE @tname nvarchar(128) = 'dbo.TasGrid'; 
DECLARE @minx float;
DECLARE @miny float;
DECLARE @maxx float;
DECLARE @maxy float;
DECLARE @xgrid float = 250;
DECLARE @ygrid float = 250;
DECLARE @srid Int;
DECLARE @geographyType Int = 0;
select TOP 1 @srid = a.geom.STSrid from dbo.Delaunay a;
SELECT @minx = c.minx,
       @miny = c.miny,
       @maxx = c.maxx,
       @maxy = c.maxy
  from (select min( a.geom.STEnvelope().STPointN(1).STX ) as minx,
               min( a.geom.STEnvelope().STPointN(1).STY ) as miny,
               max( a.geom.STEnvelope().STPointN(3).STX ) as maxx,
               max( a.geom.STEnvelope().STPointN(3).STY ) as maxy
           from dbo.Delaunay a
        ) c;
Print cast(@srid as varchar(10)) + ' ' + cast(@minx as varchar(20)) + ' ' + cast(@miny as varchar(20))  + ' ' + cast(@maxx as varchar(20))  + ' ' + cast(@maxy as varchar(20));
exec dbo.Gridder @minx, @miny, @maxx, @maxy, @xgrid, @ygrid, @srid, @tname, @geographyType;

-- Created 146,160 grids in: 36 seconds!
-- Created 2,334,058 grids in: 17 minutes 49 seconds!

select COUNT(*) from dbo.TasGrid;

Use GISDB
GO

--- QLD

drop table dbo.MyGrid;
DECLARE @gridx float = 0.00225; -- (0.00225 / 5);
DECLARE @gridy float = 0.00225; -- (0.00225 / 5);
DECLARE @srid  Int;
SELECT TOP 1 @srid = a.geog.STSrid from dbo.QGC_AOI a;
DECLARE @tile geometry; 
SELECT  @tile = dbo.MBR2GEOMETRY(0,0,@gridx,@gridy,0);
With QLDExtent As
(SELECT dbo.MBR2GEOMETRY(b.minx,b.miny,b.minx + @gridx,b.miny + @gridy,0) as First_Tile,
        ( ( Round(b.maxx / @gridx,0) * @gridx ) - 
          ( Floor(b.minx / @gridx)   * @gridx ) ) / @gridx as NumXGrids,
        ( ( Round(b.maxy / @gridy,0) * @gridy ) -
          ( Floor(b.miny / @gridy)   * @gridy ) ) / @gridy as NumYGrids
   FROM (SELECT min( a.geom.STEnvelope().STPointN(1).STX ) as minx,
                       min( a.geom.STEnvelope().STPointN(1).STY ) as miny,
                       max( a.geom.STEnvelope().STPointN(3).STX ) as maxx,
                       max( a.geom.STEnvelope().STPointN(3).STY ) as maxy
                 FROM (SELECT dbo.toGeometry(q.geog,0) as geom 
                         FROM dbo.QGC_AOI q) a
                ) b
)
SELECT dbo.ToGeography(dbo.ShiftGeometry(a.first_tile, x_series.IntValue * @gridx, y_series.IntValue * @gridy),@srid) as geom
  INTO dbo.MyGrid
/*
SELECT Top 1000 dbo.ShiftGeometry(a.first_tile, x_series.IntValue * @gridx, y_series.IntValue * @gridy).STAsText() as geom 
*/
  FROM QLDExtent a
       cross apply 
       dbo.generate_series( 0, a.NumXGrids, 1) as x_series
       cross apply
       dbo.generate_series( 0, a.NumYGrids, 1) as y_series;

-- 7,100,115 grids in 2hours 12 minutes 16 seconds
