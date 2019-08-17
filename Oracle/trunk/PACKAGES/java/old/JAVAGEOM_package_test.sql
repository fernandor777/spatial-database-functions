set linesize 131 pagesize 1000 long 4000

select to_char(sdo_util.to_gmlgeometry(mdsys.sdo_geometry(2001,8307,sdo_point_type(147.234232,-43.452334,null),null,null))) as GML from dual;

select javageom.GML2Geometry(sdo_util.to_gmlgeometry(mdsys.sdo_geometry(2001,8307,sdo_point_type(147.234232,-43.452334,null),null,null))) as GEOM from dual;

select javageom.GML2Geometry('<gml:Point srsName="SDO:8307" xmlns:gml="http://www.opengis.net/gml">
  <gml:coordinates decimal="." cs="," ts=" ">147.234232,-43.452334 </gml:coordinates>
</gml:Point>') as GEOM from dual;

select javageom.gml2sdo('<gml:Point srsName="EPSG:4326" srsDimension="2"  xmlns:gml="http://www.opengis.net/gml">
  <gml:pos xmlns:gml="http://www.opengis.net/gml">4.852,52.31</gml:pos>
</gml:Point>') as GEOM from dual;
select javageom.gml2sdo('<gml:Point gml:id="p21" srsName="urn:ogc:def:crs:EPSG:6.6:4326" xmlns:gml="http://www.opengis.net/gml">
  <gml:pos dimension="2">45.67 88.56</gml:pos>
</gml:Point>') as GEOM from dual;
select javageom.GML2Geometry('<gml:LineString gml:id="p21" srsName="urn:ogc:def:crs:EPSG:6.6:4326" xmlns:gml="http://www.opengis.net/gml">
  <gml:coordinates xmlns:gml="http://www.opengis.net/gml" >45.67, 88.56 55.56,89.44</gml:coordinates>
</gml:LineString >') as GEOM from dual;
select javageom.GML2Geometry('<gml:LineString gml:id="p21" srsName="urn:ogc:def:crs:EPSG:6.6:4326" xmlns:gml="http://www.opengis.net/gml">
  <gml:coordinates>45.67, 88.56 55.56,89.44</gml:coordinates>
</gml:LineString >') as GEOM from dual;
select javageom.GML2Geometry('<gml:Polygon xmlns:gml="http://www.opengis.net/gml">
  <gml:outerBoundaryIs>
        <gml:LinearRing>
                <gml:coordinates>0,0 100,0 100,100 0,100 0,0</gml:coordinates>
        </gml:LinearRing>
  </gml:outerBoundaryIs>
</gml:Polygon>') as GEOM from dual;

quit;
