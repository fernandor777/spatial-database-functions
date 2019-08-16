create table hex_grid (gid int identity not null primary key, geom geometry not null);

INSERT INTO hex_grid (geom)
SELECT dbo.ShiftGeometry(one_hex.geom, x_series.IntValue, y_series.IntValue)
  FROM dbo.generate_series( (select min(geom.STX) from dbo.my_points) - 12800, 
	                        (select max(geom.STX) from dbo.my_points) + 12800, 12800) as x_series,
       dbo.generate_series( (select min(geom.STY) from dbo.my_points) - 12800,
	                        (select max(geom.STY) from dbo.my_points) + 12800, 25600) as y_series,
       (SELECT geometry::STGeomFromText('POLYGON((0 0,6400 6400,6400 12800,0 19200,-6400 12800,-6400 6400,0 0))',0) as geom
	    UNION ALL
        SELECT dbo.ShiftGeometry(geometry::STGeomFromText('POLYGON((0 0,6400 6400,6400 12800,0 19200,-6400 12800,-6400 6400,0 0))',0), 6400, 12800) as geom
       ) as one_hex;

With QExtent As
(select min( a.geom.STEnvelope().STPointN(1).STX ) as minx,
        min( a.geom.STEnvelope().STPointN(1).STY ) as miny,
        max( a.geom.STEnvelope().STPointN(3).STX ) as maxx,
        max( a.geom.STEnvelope().STPointN(3).STY ) as maxy
  from (select s.geom
          from dbo.Delaunay s
       ) a
)
SELECT dbo.ShiftGeometry(one_hex.geom, x_series.IntValue, y_series.IntValue)
  FROM QExtent a
       cross apply 
       dbo.generate_series( a.minx - 12800, a.maxx + 12800, 12800) as x_series
       cross apply
       dbo.generate_series( a.miny - 12800, a.maxy + 12800, 25600) as y_series,
       (SELECT geometry::STGeomFromText('POLYGON((0 0,6400 6400,6400 12800,0 19200,-6400 12800,-6400 6400,0 0))',0) as geom
	    UNION ALL
        SELECT dbo.ShiftGeometry(geometry::STGeomFromText('POLYGON((0 0,6400 6400,6400 12800,0 19200,-6400 12800,-6400 6400,0 0))',0), 6400, 12800) as geom
       ) as one_hex;

