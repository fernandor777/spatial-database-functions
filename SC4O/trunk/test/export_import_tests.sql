select sc4o.ST_GeomFromEWKT(TO_CLOB('SRID=28355;POINTZ (-123.08963356 49.27575579 70)')) as geom from dual 
union all 
select sc4o.ST_GeomFromEWKT(TO_CLOB('LINESTRING Z (1 1 20,2 1 30,3 1 40)')) as geom from dual 
union all 
select sc4o.ST_GeomFromEWKT(TO_CLOB('LINESTRING M (1 1 20,2 1 30,3 1 40)')) as geom from dual 
union all 
select SC4O.ST_GeomFromEWKT(TO_CLOB('SRID=8307;POLYGON Z ((0 0 10,0 1 20,1 1 30,1 0 40,0 0 10))')) from dual;

select sc4o.ST_GeomFromEWKT(TO_CLOB('POINT Z (-123.08963356 49.27575579 70)'),4283) as geom from dual 
union all 
select sc4o.ST_GeomFromEWKT(TO_CLOB('SRID=28355;POINTZ (-123.08963356 49.27575579 70)'),4283) as geom from dual
union all
select sc4o.ST_GeomFromEWKT(TO_CLOB('LINESTRING (1 1,2 1,3 1)'),28355) as geom from dual 
union all 
select SC4O.ST_GeomFromEWKT(TO_CLOB('SRID=8307;POLYGON Z ((0 0 10,0 1 20,1 1 30,1 0 40,0 0 10))'),28355) from dual
union all
select SC4O.ST_GeomFromEWKT(SC4O.ST_AsEWKT(sdo_geometry(3001,28355,sdo_point_type(1,1,1),null,null)),28355) from dual;

select sc4o.ST_GeomFromText(TO_CLOB('SRID=28355;POINTZ (-123.08963356 49.27575579 70)')) as geom from dual 
union all 
select sc4o.ST_GeomFromText(TO_CLOB('LINESTRING Z (1 1 20,2 1 30,3 1 40)')) as geom from dual 
union all 
select sc4o.ST_GeomFromText(TO_CLOB('LINESTRING M (1 1 20,2 1 30,3 1 40)')) as geom from dual 
union all 
select SC4O.ST_GeomFromText(TO_CLOB('SRID=8307;POLYGON Z ((0 0 10,0 1 20,1 1 30,1 0 40,0 0 10))')) from dual;

-- GML2
select sc4o.st_geomfromgml('<gml:Polygon srsName="SDO:" xmlns:gml="http://www.opengis.net/gml"><gml:outerBoundaryIs><gml:LinearRing><gml:coordinates decimal="." cs="," ts=" ">5.0,1.0 8.0,1.0 8.0,6.0 5.0,7.0 5.0,1.0</gml:coordinates></gml:LinearRing></gml:outerBoundaryIs></gml:Polygon>') as gmlgeom from DUAL;
-- GML3
select SC4O.ST_GeomFromGML('<gml:Polygon srsName="SDO:" xmlns:gml="http://www.opengis.net/gml"><gml:exterior><gml:LinearRing><gml:posList srsDimension="2">5.0 1.0 8.0 1.0 8.0 6.0 5.0 7.0 5.0 1.0</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>') from dual;

select SC4O.ST_AsEWKT(sdo_geometry(2001,28355,sdo_point_type(1,1,null),null,null)) as wkt from dual union all
select SC4O.ST_AsEWKT(sdo_geometry(3001,null,sdo_point_type(1,1,1),null,null)) from dual union all
select SC4O.ST_AsEWKT(sdo_geometry(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1,1,2,1,3,1))) from dual union all
select SC4O.ST_AsEWKT(sdo_geometry(3003,8307,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,10,1,0,40,1,1,30,0,1,20,0,0,10))) from dual;

select SC4O.ST_AsText(sdo_geometry(2001,28355,sdo_point_type(1,1,null),null,null)) as wkt from dual union all
select SC4O.ST_AsText(sdo_geometry(3001,null,sdo_point_type(1,1,1),null,null)) from dual union all
select SC4O.ST_AsText(sdo_geometry(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1,1,2,1,3,1))) from dual union all
select SC4O.ST_AsText(sdo_geometry(3003,8307,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,10,1,0,40,1,1,30,0,1,20,0,0,10))) from dual;

set long 5000
select SC4O.ST_AsGml(sdo_geometry(2001,28355,sdo_point_type(1,1,null),null,null)) as wkt from dual union all
select SC4O.ST_AsGml(sdo_geometry(3001,null,sdo_point_type(1,1,1),null,null)) from dual union all
select SC4O.ST_AsGml(sdo_geometry(2002,28355,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(1,1,2,1,3,1))) from dual union all
select SC4O.ST_AsGml(sdo_geometry(3003,8307,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,10,1,0,40,1,1,30,0,1,20,0,0,10))) from dual;

select sc4o.ST_GeomFromEWKT('POINT Z (-123.08963356 49.27575579 70)') as geom from dual union all select sc4o.st_geomfromewkt('LINESTRING Z (1 1 20,2 1 30,3 1 40)') as geom from dual union all select sc4o.st_geomfromewkt('LINESTRING M (1 1 20,2 1 30,3 1 40)') as geom from dual union all select SC4O.ST_GeomFromEWKT('POLYGON Z ((0 0 10,0 1 20,1 1 30,1 0 40,0 0 10))') from dual;
select sc4o.ST_GeomFromEWKT('POINT Z (-123.08963356 49.27575579 70)') as geom from dual union all select sc4o.st_geomfromewkt('LINESTRING Z (1 1 20,2 1 30,3 1 40)') as geom from dual union all select sc4o.st_geomfromewkt('LINESTRING M (1 1 20,2 1 30,3 1 40)') as geom from dual union all select SC4O.ST_GeomFromEWKT('SRID=8307;POLYGON Z ((0 0 10,0 1 20,1 1 30,1 0 40,0 0 10))') from dual;

-- Binary

select SC4O.ST_AsBinary(sdo_geometry(2001,8307,sdo_point_type(147.5,-32.7,null),null,null)) from dual;
select SC4O.ST_AsEWKB(sdo_geometry(2001,8307,sdo_point_type(147.5,-32.7,null),null,null)) from dual;
select SC4O.ST_GeomFromEWKB(SC4O.ST_AsEWKB(sdo_geometry(2001,8307,sdo_point_type(147.5,-32.7,null),null,null))) from dual;
select SC4O.ST_GeomFromEWKB(SC4O.ST_AsEWKB(sdo_geometry(2001,null,sdo_point_type(147.5,-32.7,null),null,null)),8307) from dual;
