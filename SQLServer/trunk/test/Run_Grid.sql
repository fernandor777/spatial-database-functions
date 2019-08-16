truncate table grid_count;
insert into grid_count (processed, total) values (0,0);

select CAST(row_number() over (order by b.minx, b.miny) as Int) as gid,
       geography::STPolyFromText(geoWKT,s.geog.STSrid) as geog
  into dbo.QGC_QGRID
  from dbo.Australian_States s
	   cross apply
	   (select min( a.geom.STEnvelope().STPointN(1).STX ) as minx,
	           min( a.geom.STEnvelope().STPointN(1).STY ) as miny,
	           max( a.geom.STEnvelope().STPointN(3).STX ) as maxx,
	           max( a.geom.STEnvelope().STPointN(3).STY ) as maxy
          from (select dbo.toGeometry(s.geog) as geom) a
        ) b 
 	   cross apply
       dbo.REGULARGRID(b.minx, b.miny, b.maxx, b.maxy,0.00225/* approx 250m*/,0.00225/* approx 250m*/) c
 where s.[GMI_ADMIN] = 'AUS-QNS'
   and s.geog.STIntersects(geography::STPolyFromText(c.geoWKT,s.geog.STSrid)) = 1;

exec dbo.Gridder 138, -29.1705551147461, 153.543304443359, -10.0513896942139, 0.00225/* approx 250m*/,0.00225/* approx 250m*/, 4283;
