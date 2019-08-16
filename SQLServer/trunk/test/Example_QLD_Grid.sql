use gisdb
go

select row_number() over (order by rand()) as rid,
       geography::STPolyFromText(geoWKT,4326) as geog
  from dbo.australian_States s
	   cross apply
	   (select min( a.geom.STEnvelope().STPointN(1).STX ) as minx,
	           min( a.geom.STEnvelope().STPointN(1).STY ) as miny,
	           max( a.geom.STEnvelope().STPointN(3).STX ) as maxx,
	           max( a.geom.STEnvelope().STPointN(3).STY ) as maxy
          from (select dbo.toGeometry(s.geog) as geom) a
        ) b 
	   cross apply
       dbo.REGULARGRID(b.minx, b.miny, b.maxx, b.maxy,0.5/* approx 250m*/,0.5/* approx 250m*/) c
 where s.[GMI_ADMIN] = 'AUS-QNS'
   and s.geog.STIntersects(geography::STPolyFromText(c.geoWKT,4326)) = 1;

