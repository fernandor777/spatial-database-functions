select ST_AsText(ST_Scale(ST_PointFromText('POINT(0 1)',0), 5.0, 3.1, 2)) as scaledGeom;

select ST_AsText(ST_Scale(ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0),-5.0,3.2, 3)) as scaledGeom;
# scaledGeom
'LINESTRING(-0.5 0.32,-7 4.48)'

select ST_AsText(ST_Scale(ST_GeomFromText('POLYGON((0 0,10 0,10 10,0 10,0 0))',0),-5.0,30.1, 2)) as scaledGeom;

select ST_AsText(ST_StartPoint(                ST_GeomFromText('LINESTRING(0.1 0.2,1.4 45.2)',0))) as scaledGeom;
select ST_AsText(ST_PointPoint(ST_GeomFromText('POLYGON((0 0,10 0,10 10,0 10,0 0))',0))) as startPoint;
select ST_AsText(ST_PointN(ST_GeomFromText('POLYGON((0 0,10 0,10 10,0 10,0 0))',0),1)) as startPoint;
select ST_AsText(ST_StartPoint(ST_ExteriorRing(ST_GeomFromText('POLYGON((0 0,10 0,10 10,0 10,0 0))',0)))) as startPoint;

-- Curves not supported
select ST_GeomFromText('COMPOUNDCURVE(CIRCULARSTRING(9.962 -0.872,10.1 0,9.962 0.872),(9.962 0.872,0 0,9.962 -0.872))',0);

select ST_AsText(ST_Buffer(ST_GeomFromText('LINESTRING (570.365 1.65, 563.909 4.991, 651.002 129.214, 657.878 121.421, 666.129 131.964, 672.088 125.088, 712.426 170.927, 703.717 178.72, 711.968 186.054, 689.507 203.014, 692.716 207.598)',0),25.0));



