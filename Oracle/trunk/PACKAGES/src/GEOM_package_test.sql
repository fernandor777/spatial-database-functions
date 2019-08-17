DEFINE defaultSchema='&1'

SET SERVEROUTPUT ON
SET TIMING ON
SET PAGESIZE 1000
SET LINESIZE 120
SET LONG 50000
SET VERIFY OFF

Prompt Rotate Point Tests ...
SELECT &defaultSchema..GEOM.rotate( a.geom, 
	MDSYS.SDO_DIM_ARRAY(
		MDSYS.SDO_DIM_ELEMENT('X', 190000, 640000, .005),
		MDSYS.SDO_DIM_ELEMENT('Y', 120000, 630000, .005)),
	0,0,90 ) 
FROM LocalPoint2D a; 
SELECT &defaultSchema..GEOM.rotate( a.geom, 
	MDSYS.SDO_DIM_ARRAY(
		MDSYS.SDO_DIM_ELEMENT('X', 190000, 640000, .005),
		MDSYS.SDO_DIM_ELEMENT('Y', 120000, 630000, .005)),
	5,5,90) 
FROM LocalPoint2D a;

Prompt Rotate Polygon Tests ...
SELECT PolyType, &defaultSchema..GEOM.rotate( a.geom, MDSYS.SDO_DIM_ARRAY(
		MDSYS.SDO_DIM_ELEMENT('X', 190000, 640000, .005),
		MDSYS.SDO_DIM_ELEMENT('Y', 120000, 630000, .005)),
	NULL,NULL,90) 
FROM ProjPoly2D a;

SELECT 'Rotate by MBR == centroid',    &&defaultSchema..GEOM.Rotate(mdsys.sdo_geometry('POLYGON((2 2, 2 7, 12 7, 12 2, 2 2))',NULL),0.05,45) FROM DUAL;
SELECT 'Rotate centroid -> same as 2', &&defaultSchema..GEOM.Rotate(b.the_geom,0.05,b.centroid.sdo_point.x,b.centroid.sdo_point.y, 45 )
from (select the_geom, centroid.sdo_centroid(p_geometry=>the_geom,p_start=>1,p_tolerance=>0.05) as centroid
	from (select mdsys.sdo_geometry('POLYGON((2 2, 2 7, 12 7, 12 2, 2 2))',NULL) as the_geom
		from dual) a
) b;
select 'Rotate about Origin', &&defaultSchema..GEOM.Rotate(b.the_geom,0.05,0,0, 45 )
from (select the_geom, centroid.sdo_centroid(p_geometry=>the_geom,p_start=>1,p_tolerance=>0.05) as centroid
	from (select mdsys.sdo_geometry('POLYGON((2 2, 2 7, 12 7, 12 2, 2 2))',NULL) as the_geom
		from dual) a
) b;

Prompt ===============================================
Prompt MOVE: Projected Point Tests ...
Prompt ===============================================
SELECT &defaultSchema..GEOM.MOVE(a.geom,112,183,NULL) 
FROM ProjPoint2D a 
WHERE ROWNUM < 20;

Prompt Move Projected Polygon Tests ...
SELECT &defaultSchema..GEOM.MOVE(a.geom,112,183,NULL) 
FROM ProjPoly2D a
WHERE ROWNUM < 10 ;

With userGeom as (
	Select MDSYS.SDO_GEOMETRY(2006,null,null,
		MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1,5,2,1,9,2,1,13,2,1,17,2,1,21,2,1),
		MDSYS.SDO_ORDINATE_ARRAY(351,0, 334,30, 334,30, 317,0, 317,0, 300,30, 300,30, 282,0, 282,0, 265,30, 265,30, 248,0))
	as InGeom,
	-351 as xDelta,
	0 as yDelta
	from dual
)
SELECT &&defaultSchema..GEOM.MOVE(
	p_geometry    => a.inGeom,
	p_tolerance   => 005,
	p_deltaX      => a.xDelta,
	p_deltaY      => a.yDelta,
	p_deltaZ      => NULL,
	p_mbr         => NULL,
	p_filter_geom => NULL,
	p_filter_mask => NULL)
as outGeom 
FROM userGeom a ;

Prompt ===============================================
Prompt Convert 3D CompoundLine to 2D
Prompt ===============================================
Prompt First: Validate ...
SELECT LineType, 
mdsys.sdo_geom.validate_geometry( a.geom, 0.5 ) 
FROM ProjLine3D a;
Prompt Second: Convert ...
SELECT LINEType, &&defaultSchema..GEOM.To_2D( a.geom ) FROM ProjLine3D a;
SELECT LINEType, a.geom, &&defaultSchema..GEOM.To_3D( a.geom,-100 ), sdo_geom.validate_geometry(geom.to_3d(a.geom,-1000),0.5) FROM ProjLine2D a;
SELECT &&defaultSchema..GEOM.TO_3D(
	SDO_GEOMETRY(
		4302,
		NULL,
		NULL,
		SDO_ELEM_INFO_ARRAY(1,2,1),
		SDO_ORDINATE_ARRAY(
			2,2,3,0,
			2,4,4,2,
			8,4,5,8, 
			12,4,6,12,
			12,10,7,13,
			8,10,8,22,
			5,14,9,27)
))
FROM DUAL;
SELECT &&defaultSchema..GEOM.TO_3D(
	SDO_GEOMETRY(
		4302,
		NULL,
		NULL,
		SDO_ELEM_INFO_ARRAY(1,2,1),
		SDO_ORDINATE_ARRAY(
			2,2,NULL,0,
			2,4,4,2,
			8,4,5,8, 
			12,4,6,12,
			12,10,NULL,13,
			8,10,8,22,
			5,14,9,27)
),999)
FROM DUAL;
SELECT &&defaultSchema.GEOM..TO_3D(&&defaultSchema.GEOM..TO_2D(&&defaultSchema..GEOM.TO_3D(
			SDO_GEOMETRY(
				4302,
				NULL,
				NULL,
				SDO_ELEM_INFO_ARRAY(1,2,1),
				SDO_ORDINATE_ARRAY(
					2,2,NULL,0,
					2,4,4,2,
					8,4,5,8, 
					12,4,6,12,
					12,10,NULL,13,
					8,10,8,22,
					5,14,9,27)
))))
FROM DUAL;
SELECT SDO_GEOM.VALIDATE_GEOMETRY(&&defaultSchema..GEOM.TO_2D(&&defaultSchema..GEOM.TO_3D(
			SDO_GEOMETRY(
				4302,
				NULL,
				NULL,
				SDO_ELEM_INFO_ARRAY(1,2,1),
				SDO_ORDINATE_ARRAY(
					2,2,NULL,0,
					2,4,4,2,
					8,4,5,8, 
					12,4,6,12,
					12,10,NULL,13,
					8,10,8,22,
					5,14,9,27)
),999)),0.5)
FROM DUAL;
select &&defaultSchema..GEOM.to_2d(mdsys.sdo_geometry(3001,null,mdsys.sdo_point_type(10,20,30),sdo_elem_info_array(1,1,1),sdo_ordinate_array(1,2,3))) 
from dual;
SELECT PolyType,
sdo_geom.validate_geometry(sdo_util.Extract(a.geom,1,0),1) 
FROM LocalPoly2D a
WHERE PolyType = 'VERTEXMULTI';

Prompt Count ProjCompound2D ordinates ...
SELECT count(*)
FROM TABLE ( SELECT a.GEOM.sdo_ordinates FROM ProjCompound2D a WHERE rownum < 2 );

Prompt Explode ProjCompound2D ...
SELECT b.*
FROM ProjCompound2D a,
TABLE ( &&defaultSchema..GEOM.ExplodeGeometry( a.geom ) ) b;
Prompt Explode ProjLine2D ...
SELECT b.*
FROM ProjLine2D a,
TABLE( &&defaultSchema..GEOM.ExplodeGeometry( a.geom ) ) b;
Prompt Explode ProjPoly2D ...
SELECT *
FROM ProjPoly2D a,
TABLE( &&defaultSchema..GEOM.ExplodeGeometry( a.geom ) ) b;
SELECT sdo_util.to_wktgeometry(b.geometry)
FROM ProjPoly2D a,
TABLE( &&defaultSchema..GEOM.ExplodeGeometry( a.geom ) ) b;
SELECT &&defaultSchema..GEOM.AsEWKT(b.geometry)
FROM ProjPoly2D a,
TABLE( &&defaultSchema..GEOM.ExplodeGeometry( a.geom ) ) b;

Prompt Explode Test using AsEWKT ...
SELECT &&defaultSchema..GEOM.AsEWKT(&&defaultSchema..GEOM.ExplodeGeometry( a.geom )) FROM ProjPoly2D a;

Prompt Self Intersection test ...
SELECT sdo_geom.sdo_intersection(a.geom,a.geom,0.0005) FROM ProjLine2D a;

Prompt isSimple test ...
SELECT &&defaultSchema..GEOM.isSimple( a.geom,0.0005 ) FROM ProjPoint2D a WHERE ROWNUM < 20 ;
SELECT &&defaultSchema..GEOM.isSimple( a.geom,0.0005 ) FROM ProjMultiPoint2D a WHERE ROWNUM < 20;
SELECT &&defaultSchema..GEOM.isSimple( a.geom,0.0005 ) FROM ProjLine2D a WHERE ROWNUM < 20;

Prompt GetNumELem test ...
SELECT &&defaultSchema..GEOM.GetNumElem( a.geom ) As NumElements FROM ProjCompound2D a;

Prompt Extract Polygon Test ...
SELECT &defaultSchema..GEOM.ExtractPolygon( a.geom ) FROM ProjCompound2D a;
Prompt Extract Line Test ...
SELECT &defaultSchema..GEOM.ExtractLine(    a.geom ) FROM ProjCompound2D a;
Prompt Extract Point Test ...
SELECT &defaultSchema..GEOM.ExtractPoint(   a.geom ) FROM ProjCompound2D a;

Prompt Convert SdoOrdinates Point to Sdo_Point Test ...
select &&defaultSchema..GEOM.ToSdoPoint(mdsys.sdo_geometry(2001,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,2))) 
from dual;

Prompt Test ElementInfoExtraction ...
SELECT DISTINCT
ei.etype, 
ei.interpretation 
FROM ProjCompound2D a,
TABLE( &&defaultSchema..GEOM.GetElemInfo( a.geom ) ) ei
WHERE a.geom is not null;

Prompt ================================================
Prompt WKT and EWKT tests....
Prompt ================================================

Prompt Test Oracle TO_WKTGEOMETRY on Extracted compound objects (Pipelined)...
SELECT MDSYS.SDO_UTIL.TO_WKTGEOMETRY(b.geometry)
FROM ProjCompound2D a,
TABLE(&&defaultSchema..GEOM.ExtractElements( a.GEOM,1 ) ) b;

Prompt AsEWKT With Extract for Compound Geometries
SELECT &&defaultSchema..GEOM.AsEWKT( 
	&&defaultSchema..GEOM.ExtractElements( a.GEOM,1 ) ) 
FROM ProjCompound2D a;

Prompt Oracle TO_WKTGEOMETRY for Projected Polygons ...
SELECT PolyType, MDSYS.SDO_UTIL.TO_WKTGEOMETRY( a.GEOM ) FROM ProjPoly2D a;
Prompt My AsEWKT Projected Polygons ...
SELECT PolyType, &&defaultSchema..GEOM.AsEWKT( GEOM ) FROM ProjPoly2D a;
Prompt Test Oracles TO_WKTGEOMETRY For Projected Lines...
SELECT LineType, MDSYS.SDO_UTIL.TO_WKTGEOMETRY( GEOM ) FROM ProjLine2D a;

Prompt Text EWKT For Projected Lines...
SELECT &&defaultSchema..GEOM.AsEWKT( A.GEOM ) FROM ProjLine2D a:
Prompt Oracle TO_WKTGEOMETRY for a Projected Polygon data
SELECT MDSYS.SDO_UTIL.TO_WKTGEOMETRY( A.GEOM ) FROM ProjPoly2D a;
Prompt My EWKT for a Projected Polygon data
SELECT &&defaultSchema..GEOM.AsEWKT( A.GEOM ) FROM ProjPoly2D a;

Prompt Test Extract ELements...
SELECT b.*
  FROM ProjMultiPoint2D a,
       TABLE( &&defaultSchema..GEOM.ExtractElements( a.geom,1 ) ) b;

Prompt Densify linestrings ...
SELECT LineType, 
       &&defaultSchema..GEOM.DENSIFY(a.geom,1,10)
  FROM LocalLine2D a;
Prompt Test Densification of polygons ...
SELECT PolyType, 
       MDSYS.SDO_UTIL.TO_WKTGEOMETRY( &&defaultSchema..GEOM.DENSIFY( a.GEOM,1,10 ) )
  FROM LocalPoly2D a;

Prompt Convert_Geometry - Rectangle
SELECT &&defaultSchema..GEOM.convert_geometry(sdo_geometry(2003,null,null,sdo_elem_info_array(1,1003,3),sdo_ordinate_array(0,0,100,100)),0.1) from dual;

Prompt COnvert_Geometry - Compound line string
SELECT &&defaultSchema..GEOM.convert_geometry(
 SDO_GEOMETRY(
     2002,
     NULL,
     NULL,
     SDO_ELEM_INFO_ARRAY(1,4,2, 1,2,1, 3,2,2), -- compound line string
     SDO_ORDINATE_ARRAY(252000,5526000,252700,5526700,252500,5526700,252500,5526500)
   ),0.1) from dual;
  
Prompt Convert_Geometry - Compound polygon 
SELECT &&defaultSchema..GEOM.convert_geometry(
 SDO_GEOMETRY(
    2003,  -- two-dimensional polygon
    NULL,
    NULL,
    SDO_ELEM_INFO_ARRAY(1,1005,2, 1,2,1, 5,2,2), -- compound polygon
    SDO_ORDINATE_ARRAY(6,10, 10,1, 14,10, 10,14, 6,10)
   ),0.5) from dual;

Prompt Convert_Geometry - Compound polygon 
select &&defaultSchema..GEOM.convert_geometry(
 sdo_geometry(2003, 82000, NULL,
 sdo_elem_info_array(
 1, 1005, 5,
 1, 2, 1,
 3, 2, 2,
 7, 2, 1,
 9, 2, 2,
 13, 2, 1
 ),
 sdo_ordinate_array(
 227118.588455087, 1299711.39449101,
 227230.423505445, 1299754.81294682,
 227219.353084497, 1299782.32662005,
 227207.606276162, 1299809.55838329,
 227097.503683946, 1299762.0281499,
 227099.099661904, 1299758.34384359,
 227100.707423966, 1299754.66466437,
 227109.88244048, 1299733.12648321,
 227118.588455087, 1299711.39449101)),0.1) from dual;

Prompt Convert_Geometry: two-dimensional polygon with hole
SELECT
&&defaultSchema..GEOM.Convert_Geometry(
   SDO_GEOMETRY(
     2003,  -- two-dimensional polygon with hole
     NULL,
     NULL,
     SDO_ELEM_INFO_ARRAY(1,1005,2, 1,2,1, 5,2,2,
                        11,2005,2, 11,2,1, 15,2,2),
     SDO_ORDINATE_ARRAY(  6,10, 10,1, 14,10, 10,14,  6,10,
                         13,10, 10,2,  7,10, 10,13, 13,10)
    )
    ,0.5)
from dual
/

Prompt Convert_Geometry: two-dimensional multi-part polygon with hole
SELECT
&&defaultSchema..GEOM.Convert_Geometry(
   SDO_GEOMETRY(
     2007,  -- two-dimensional multi-part polygon with hole 
     NULL,
     NULL,
     SDO_ELEM_INFO_ARRAY(1,1005,2, 1,2,1, 5,2,2,
                        11,2005,2, 11,2,1, 15,2,2,
                        21,1005,2, 21,2,1, 25,2,2),
     SDO_ORDINATE_ARRAY(  6,10, 10,1, 14,10, 10,14,  6,10,
                         13,10, 10,2,  7,10, 10,13, 13,10,
                       106,110, 110,101, 114,110, 110,114,106,110)
    )
    ,0.5)
from dual
/

select &&defaultSchema..GEOM.tolerance( &&defaultSchema..GEOM.convert_geometry( SDO_GEOMETRY(
     2002,
     NULL,
     NULL,
     SDO_ELEM_INFO_ARRAY(1,4,2, 1,2,1, 3,2,2), -- compound line string
     SDO_ORDINATE_ARRAY(252000,5526000,252700,5526700,252500,5526700,252500,5526500)
   ), 0.1),0.05) 
  from dual;

Prompt Test 2D Vectorisation (No pipelining)...
SELECT rownum,
       MDSYS.sdo_geometry(2002,NULL,NULL,
                     MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1),
                     MDSYS.SDO_ORDINATE_ARRAY(startx,startY,endX,endY))
  FROM ( SELECT DISTINCT c.StartCoord.X as startX, 
                         c.StartCoord.Y as startY, 
                         c.EndCoord.X as endX, 
                         c.EndCoord.X as endY
           FROM ( SELECT geom 
                    FROM ProjPoly2D 
                   WHERE PolyType = 'VERTEXNOHOLE' ) a, 
                TABLE(CAST(&&defaultSchema..GEOM.GetVector2D(a.geom) AS &&defaultSchema..T_Vector2DSet)) c
       )
 WHERE rownum < 20;

Prompt Test 2D Vectorisation (VERTEXNOHOLE Pipelined)...
SELECT rownum,
       MDSYS.sdo_geometry(2002,NULL,NULL,
                     MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1),
                     MDSYS.SDO_ORDINATE_ARRAY(startx,startY,endX,endY))
  FROM ( SELECT DISTINCT c.StartCoord.X as startX, 
                         c.StartCoord.Y as startY, 
                         c.EndCoord.X as endX, 
                         c.EndCoord.X as endY
           FROM ( SELECT geom 
                    FROM ProjPoly2D 
                   WHERE PolyType = 'VERTEXNOHOLE' ) a, 
                TABLE(CAST(&&defaultSchema..GEOM.GetVector2D(a.geom) AS &&defaultSchema..T_Vector2DSet)) c
       )
 WHERE rownum < 20;

Prompt Test ST_Point Vectorisation (VERTEXNOHOLE Pipelined)...
SELECT rownum,
       MDSYS.sdo_geometry(2002,NULL,NULL,
                     MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1),
                     MDSYS.SDO_ORDINATE_ARRAY(startx,startY,endX,endY))
  FROM ( SELECT DISTINCT c.StartCoord.X as startX, 
                         c.StartCoord.Y as startY, 
                         c.EndCoord.X as endX, 
                         c.EndCoord.X as endY
           FROM ( SELECT geom 
                    FROM ProjPoly2D 
                   WHERE PolyType = 'VERTEXNOHOLE' ) a, 
                TABLE(CAST(&&defaultSchema..GEOM.GetVector(a.geom) AS &&defaultSchema..T_VectorSet)) c
       )
 WHERE rownum < 20;

Prompt Test ST_Point 3D Vectorisation (Pipelined)...
SELECT rownum,
       MDSYS.sdo_geometry(3002,NULL,NULL,
                     MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1),
                     MDSYS.SDO_ORDINATE_ARRAY(startx,startY,startZ,endX,endY,endZ))
  FROM ( SELECT DISTINCT c.StartCoord.X as startX, 
                         c.StartCoord.Y as startY, 
                         c.StartCoord.Z as startZ, 
                         c.EndCoord.X as endX, 
                         c.EndCoord.X as endY,
                         c.EndCoord.Z as endZ
           FROM ( SELECT geom 
                    FROM ProjPoly3D ) a, 
                TABLE(CAST(&&defaultSchema..GEOM.GetVector(a.geom) AS &&defaultSchema..T_VectorSet)) c
       )
 WHERE rownum < 20;

SELECT c.StartCoord.X as startX,
       c.StartCoord.Y as startY,
       c.EndCoord.X   as endX,
       c.EndCoord.Y   as endY
  FROM TABLE(&&defaultSchema..GEOM.GetVector2D(
 SDO_GEOMETRY(
     2002,
     NULL,
     NULL,
     SDO_ELEM_INFO_ARRAY(1,4,2, 1,2,1, 3,2,2), -- compound line string
     SDO_ORDINATE_ARRAY(10,10, 10,14, 6,10, 14,10)
   )
 ,0.5)) c;

SELECT c.StartCoord.X as startX,
       c.StartCoord.Y as startY,
       c.EndCoord.X   as endX,
       c.EndCoord.Y   as endY
  FROM TABLE(&&defaultSchema..GEOM.GetVector2D(
 SDO_GEOMETRY(
     2002,
     NULL,
     NULL,
     SDO_ELEM_INFO_ARRAY(1,4,2, 1,2,1, 3,2,2), -- compound line string
     SDO_ORDINATE_ARRAY(252000,5526000,252700,5526700,252500,5526700,252500,5526500)
   )
 ,0.5)) c;

 select v.startcoord.x,v.startcoord.y,v.endcoord.x,v.endcoord.y
   from table(geom.GetVector2D(
 sdo_geometry(2003, 82000, NULL,
 sdo_elem_info_array(
 1, 1005, 5,
 1, 2, 1,
 3, 2, 2,
 7, 2, 1,
 9, 2, 2,
 13, 2, 1
 ),
 sdo_ordinate_array(
 227118.588455087, 1299711.39449101,
 227230.423505445, 1299754.81294682,
 227219.353084497, 1299782.32662005,
 227207.606276162, 1299809.55838329,
 227097.503683946, 1299762.0281499,
 227099.099661904, 1299758.34384359,
 227100.707423966, 1299754.66466437,
 227109.88244048, 1299733.12648321,
 227118.588455087, 1299711.39449101)),0.01)) v;

SELECT *
  FROM TABLE(&&defaultSchema..GEOM.GetVector(
  SDO_GEOMETRY(
    2003,  -- two-dimensional polygon
    NULL,
    NULL,
    SDO_ELEM_INFO_ARRAY(1,1005,2, 1,2,1, 5,2,2), -- compound polygon
    SDO_ORDINATE_ARRAY(6,10, 10,1, 14,10, 10,14, 6,10)
   ),0.5));

Prompt Test Arc Extraction (Pipelined)...
SELECT rownum,
       MDSYS.sdo_geometry(2002,NULL,NULL,
                     MDSYS.SDO_ELEM_INFO_ARRAY(1,2,2),
                     MDSYS.SDO_ORDINATE_ARRAY(startx,startY,midX,MidY,endX,endY))
  FROM ( SELECT DISTINCT c.StartCoord.X as startX, 
                         c.StartCoord.Y as startY, 
                         c.MidCoord.X as MidX, 
                         c.MidCoord.Y as MidY, 
                         c.EndCoord.X as endX, 
                         c.EndCoord.X as endY
           FROM ( SELECT geom 
                    FROM ProjPoly2D ) a, 
                TABLE(CAST(&&defaultSchema..GEOM.GetArcs(a.geom) AS &&defaultSchema..ArcSetType)) c
       )
 WHERE rownum < 20;

select v.startcoord.x,v.startcoord.y,v.endcoord.x,v.endcoord.y
   from table(geom.GetArcs(
 sdo_geometry(2003, 82000, NULL,
 sdo_elem_info_array(
 1, 1005, 5,
 1, 2, 1,
 3, 2, 2,
 7, 2, 1,
 9, 2, 2,
 13, 2, 1
 ),
 sdo_ordinate_array(
 227118.588455087, 1299711.39449101,
 227230.423505445, 1299754.81294682,
 227219.353084497, 1299782.32662005,
 227207.606276162, 1299809.55838329,
 227097.503683946, 1299762.0281499,
 227099.099661904, 1299758.34384359,
 227100.707423966, 1299754.66466437,
 227109.88244048, 1299733.12648321,
 227118.588455087, 1299711.39449101)))) v;

Prompt Test GetPointSet (Pipelined)...
SELECT rownum, c.x, c.y, c.z, c.m
  FROM ( SELECT geom 
           FROM ProjPoly2D 
          WHERE PolyType = 'VERTEXNOHOLE' ) a, 
       TABLE(&&defaultSchema..GEOM.GetPointSet(a.geom)) c
 WHERE ROWNUM < 20;

Prompt Test ToSdoPoint
SELECT &&defaultSchema..GEOM.ToSdoPoint( mdsys.sdo_geometry(2001,28355,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(300000,5200000))) as SdoPointGeom
  FROM DUAL;

Prompt Testing SDO_Area/SDO_Length ...
select uom_id,substr(unit_of_meas_name,1,50) as measure
from SDO_UNITS_OF_MEASURE
order by 2;

SELECT substr(PolyType,1,26) as polygon_Name,
       mdsys.sdo_geom.sdo_length(a.geom,b.diminfo) as sdo_length,
       &&defaultSchema..GEOM.sdo_length(a.geom,b.diminfo,'FOOT') as geom_length,
       a.geom
  FROM GeodPoly2D a,
       (select MDSYS.SDO_DIM_ARRAY( 
                      MDSYS.SDO_DIM_ELEMENT('X',190000, 640000, .005),
                      MDSYS.SDO_DIM_ELEMENT('Y',120000, 630000, .005)) 
                  as diminfo
          from dual) b;

SELECT substr(PolyType,1,26) as polygon_Name,
       mdsys.sdo_geom.sdo_length(a.geom,b.diminfo)        as sdo_length,
       &&defaultSchema..GEOM.sdo_length(a.geom,b.diminfo) as geom_length,
       mdsys.sdo_geom.sdo_area(a.geom,b.diminfo)          as sdo_area,
       &&defaultSchema..GEOM.sdo_area(a.geom,b.diminfo)   as geom_area
  FROM ProjPoly2D a,
       (select MDSYS.SDO_DIM_ARRAY( 
                      MDSYS.SDO_DIM_ELEMENT('X',190000, 640000, .005),
                      MDSYS.SDO_DIM_ELEMENT('Y',120000, 630000, .005)) 
                  as diminfo
          from dual) b;

Prompt Test Split Procedure
declare
  v_line   mdsys.sdo_geometry := mdsys.sdo_geometry(2002,NULL,NULL, mdsys.sdo_elem_info_array(1,2,1), mdsys.sdo_ordinate_array(0,0,10,10));
  v_point  mdsys.sdo_geometry := mdsys.sdo_geometry(2001,null,mdsys.sdo_point_type(5,5,NULL),NULL,NULL);
  v_oline1 mdsys.sdo_geometry;
  v_oline2 mdsys.sdo_geometry;
  cursor c_vectors(p_geometry in mdsys.sdo_geometry) Is
  select rownum as id,
         b.x, b.y
    from table(sdo_util.getvertices(p_geometry)) b;
begin
  &defaultSchema..GEOM.split(v_line, v_point,0.005,v_oline1,v_oline2);
  dbms_output.put_line('Line1');
  for rec in c_vectors(v_oline1) loop
    dbms_output.put_line(rec.id||','||rec.x||','||rec.y);
  end loop;
  dbms_output.put_line('Line2');
  for rec in c_vectors(v_oline2) loop
    dbms_output.put_line(rec.id||','||rec.x||','||rec.y);
  end loop;
end;
/
show errors

declare
  v_line   mdsys.sdo_geometry := mdsys.sdo_geometry(2006,NULL,NULL, mdsys.sdo_elem_info_array(1,2,1,5,2,1), mdsys.sdo_ordinate_array(0,0,5,5,5,5,10,10));
  v_point  mdsys.sdo_geometry := mdsys.sdo_geometry(2001,null,mdsys.sdo_point_type(2.5,2.5,NULL),NULL,NULL);
  v_oline1 mdsys.sdo_geometry;
  v_oline2 mdsys.sdo_geometry;

  cursor c_vectors(p_geometry in mdsys.sdo_geometry) Is
  select rownum as id,
         b.x, b.y
    from table(sdo_util.getvertices(p_geometry)) b;

  procedure printgeom(p_text in varchar2,p_geom in mdsys.sdo_geometry)
  Is
    v_geom   mdsys.sdo_geometry;
  Begin
    dbms_output.put_line(p_text || ': Number of Elements ' || sdo_util.GetNumElem(p_geom));
    for v_element in 1..sdo_util.GetNumElem(p_geom) loop
      v_geom := sdo_util.Extract(p_geom,v_element);   -- Extract element with all sub-elements
      dbms_output.put_line('Element ' || v_element || ' Vertices');
      for rec in c_vectors(v_geom) loop
        dbms_output.put_line(rec.id||','||rec.x||','||rec.y);
      end loop;
    end loop;
  End PrintGeom;

begin
  &defaultSchema..GEOM.split(v_line, v_point,0.005,v_oline1,v_oline2);
  PrintGeom('Outline1',v_oline1);
  PrintGeom('Outline2',v_oline2);
end;
/
show errors

select b.*
  from table( &defaultSchema..GEOM.split( mdsys.sdo_geometry(2006,NULL,NULL, mdsys.sdo_elem_info_array(1,2,1,5,2,1), mdsys.sdo_ordinate_array(0,0,5,5,5,5,10,10)),
                                          mdsys.sdo_geometry(2001,null,mdsys.sdo_point_type(2.5,2.5,NULL),NULL,NULL),
		                          0.005) ) b;

select s.*
 from table(&&defaultSchema..GEOM.split( SDO_GEOMETRY(2002, 8307, NULL, SDO_ELEM_INFO_ARRAY(1, 2, 1), SDO_ORDINATE_ARRAY(59.8833333, 25.8666667, 59.975, 26.1116667, 60.1333333, 26.55, 60.205, 27.3, 60.2166667, 27.4666667, 60.5494444, 27.8016667, 60.555, 27.8369444)),
                                         SDO_GEOMETRY(2001, 8307, SDO_POINT_TYPE(60.66,27.37527,NULL),NULL,NULL),
                                         0.05) ) s;


select     &&defaultSchema..GEOM.Convert_Distance(8311,1,'Meter') as meters_per_degree,
       1 / &&defaultSchema..GEOM.Convert_Distance(8311,1,'Meter') as degrees_per_metre
  from dual;
select     &&defaultSchema..GEOM.Convert_Distance(8311,1,'Foot') as feet_per_degree,
       1 / &&defaultSchema..GEOM.Convert_Distance(8311,1,'Foot') as degrees_per_foot
  from dual;
select     &&defaultSchema..GEOM.Convert_Distance(28355,1,'Foot') as feet_per_metre,
       1 / &&defaultSchema..GEOM.Convert_Distance(28355,1,'Foot') as metres_per_foot
  from dual;

select &&defaultSchema..GEOM.convert_unit('CHAIN',1,'LINK') from dual;

select &&defaultSchema..GEOM.Generate_Diminfo(2,0.05) from dual;

Prompt Points should not be handled.
select &&defaultSchema..GEOM.Parallel(mdsys.sdo_geometry(2001,null,null,sdo_elem_info_array(1,1,1),sdo_ordinate_array(1,1)),10,0.05) 
  from dual;

Prompt Neither should polygons
select &&defaultSchema..GEOM.Parallel(mdsys.sdo_geometry('POLYGON((2 2, 2 7, 12 7, 12 2, 2 2))',NULL),10,0.05)  as geom
  from dual; 

Prompt Ordinary test  
select 1, mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,1,10)) from dual
union all
select 2, &&defaultSchema..GEOM.Parallel(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,1,10)),10,0.05) from dual
union all
select 3, &&defaultSchema..GEOM.Parallel(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,1,10)),-10,0.05) from dual;


Prompt Test Acute Angle
select 1, mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,10,10,20,1)) from dual
union all
select 2, &&defaultSchema..GEOM.Parallel(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,10,10,20,1)),5,0.05,0) from dual;

Prompt Test Obtuse angle - Not curved
select 1, mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,10,10,20,1)) from dual
union all
select 2, &&defaultSchema..GEOM.Parallel(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,10,10,20,1)),-5,0.05,0) from dual;

Prompt Test Obtuse angle - Curved
select 1, mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,10,10,20,1)) from dual
union all
select 2, &&defaultSchema..GEOM.Parallel(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,10,10,20,1)),-5,0.05,1) from dual;

Prompt Compound Linestrings not supported
select 1, &&defaultSchema..GEOM.Parallel(MDSYS.SDO_GEOMETRY(2002,null,null,MDSYS.SDO_ELEM_INFO_ARRAY(1,4,3,1,2,1,3,2,2,7,2,1),MDSYS.SDO_ORDINATE_ARRAY(-2.5,4.5,6.5,13.5,9.9,15,13.3,13.7,23.3,4.7)),5,0.05,1) 
  from dual;

Prompt Check 3D linestring processing
select 1, &&defaultSchema..GEOM.Parallel(mdsys.sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,1,1,10,1)),10,0.05) as Geom 
  from dual;

Prompt Check lines that are parallel or continue from last line without deflection
select 1, mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,1,10,1,100)) from dual
union all
select 2, &&defaultSchema..GEOM.Parallel(mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,1,10,1,100)),10,0.05) from dual;

Prompt Check 3D lines that are parallel or continue from last line without deflection
select &&defaultSchema..GEOM.Parallel(mdsys.sdo_geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,9,1,10,9,1,100,9)),10,0.05) as geom
  from dual;

Prompt Check multilinestring with one linestring with an acute angle and the other an obtuse angle
select 1, mdsys.sdo_geometry(2006,null,null,sdo_elem_info_array(1,2,1,5,2,1),sdo_ordinate_array(1,1,10,10,20,1,50,50,100,0,150,50)) from dual
union all
select 2, &&defaultSchema..GEOM.Parallel(mdsys.sdo_geometry(2006,null,null,sdo_elem_info_array(1,2,1,5,2,1),sdo_ordinate_array(1,1,10,10,20,1,50,50,100,0,150,50)),10,0.05,1) from dual;

Prompt Check 2D line with LRS measures
select &&defaultSchema..GEOM.parallel(SDO_GEOMETRY(3302, NULL, NULL,
                     SDO_ELEM_INFO_ARRAY(1,2,1),
                     SDO_ORDINATE_ARRAY(5,10,0, 20,5,NULL, 35,10,NULL, 55,10,100)),1,0.05,1) 
         as geom
  from dual;

Prompt Check 3D line with LRS measures
select &&defaultSchema..GEOM.parallel(SDO_GEOMETRY(4402, NULL, NULL,
                     SDO_ELEM_INFO_ARRAY(1,2,1),
                     SDO_ORDINATE_ARRAY(5,10,500,0, 20,5,501,NULL, 35,10,502,NULL, 55,10,503,100)),1,0.05,1)
         as geom
  from dual;

Prompt Finish with left/right parallel of linestring with acute/obtuse bends with/without p_curve = 1
select 1, mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,45,45,90,0,135,45,180,0,180,-45,45,-45,0,0)) as geom 
  from dual
union all
select rin + 1, &&defaultSchema..GEOM.Parallel(b.geom,case when rin = 2 then -1 else 1 end * 10,0.005,1) as geom
  from (select level as rin, mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,45,45,90,0,135,45,180,0,180,-45,45,-45,0,0)) as geom 
         from dual
         where level between 1 and 2
         connect by level < 3) b;

Prompt Scale...
SELECT &&defaultSchema..GEOM.AsEWKT(&&defaultSchema..GEOM.Scale(SDO_GEOMETRY(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,2,3,1,1,1)), 0.005, 0.5, 0.75))
  FROM DUAL;
  
SELECT &&defaultSchema..GEOM.AsEWKT(&&defaultSchema..GEOM.Scale(SDO_GEOMETRY(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,2,3,1,1,1)), 0.005, 0.5, 0.75, 0.8))
  FROM DUAL;
  
SELECT &&defaultSchema..GEOM.Scale(SDO_GEOMETRY(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,2,3,1,1,1)), 0.005, 0.5, 0.75, 0.8)
  FROM DUAL;

Prompt Affine ...
SELECT &&defaultSchema..GEOM.AsEWKT(
       &&defaultSchema..GEOM.Tolerance(
       &&defaultSchema..GEOM.Affine(foo.the_geom, 
              cos(Constants.pi()), -sin(Constants.pi()), 0, 
              sin(Constants.pi()), cos(Constants.pi()), -sin(Constants.pi()), 
              0, sin(Constants.pi()), cos(Constants.pi()), 
              0, 0, 0),
       0.05)
       ) as AsEWKT
	FROM (SELECT MDSYS.SDO_GEOMETRY(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,2,3,1,4,3)) As the_geom 
                FROM DUAL) foo;
-- SET point testing
-- Test update of SDO_POINT structure with NULL ordinate values
select &&defaultSchema..GEOM.SDO_SetPoint(mdsys.SDO_Geometry(2001,null,sdo_point_type(null,null,null),null,null),
                               mdsys.vertex_type(4.555,4.666,null,null,1),
                               1) as point
  from dual;
-- Test update of SDO_POINT structure with valid ordinate values
select &&defaultSchema..GEOM.SDO_SetPoint(mdsys.SDO_Geometry(2001,null,sdo_point_type(1.12345,2.43534,3.43513),null,null),
                               mdsys.vertex_type(4.555,4.666,10,null,1),
                               1) as point
  from dual;
-- Test to see if NULL p_position is correctly resolved to 1
select &&defaultSchema..GEOM.SDO_SetPoint(mdsys.SDO_Geometry(3001,null,sdo_point_type(1.12345,2.43534,3.43513),null,null),
                               mdsys.vertex_type(4.555,4.666,10,null,1),
                               null) as point
  from dual;
-- Test if invalid p_position value is supplied
select &&defaultSchema..GEOM.SDO_SetPoint(mdsys.SDO_Geometry(3001,null,sdo_point_type(1.12345,2.43534,3.43513),null,null),
                               mdsys.vertex_type(4.555,4.666,10,null,1),
                               2) as point
  from dual;

-- *******************************************
-- Multipoint
-- Update last point 
select &&defaultSchema..GEOM.SDO_SetPoint(mdsys.SDO_Geometry(2001,null,null,sdo_elem_info_array(1,1,3),
                               sdo_ordinate_array(1.12345,1.3445,2.43534,2.03998398,3.43513,3.451245)),
                               mdsys.vertex_type(4.555,4.666,10,null,1),
                               null) as point
  from dual;
-- Update third point in 2D multipoint
select &&defaultSchema..GEOM.SDO_SetPoint(mdsys.SDO_Geometry(2001,null,null,sdo_elem_info_array(1,1,3),
                               sdo_ordinate_array(1.12345,1.3445,2.43534,2.03998398,3.43513,3.451245)),
                               mdsys.vertex_type(4.555,4.666,10,null,1),
                               3) as point
  from dual;
-- Update third point in 3D multipoint
select &&defaultSchema..GEOM.SDO_SetPoint(mdsys.SDO_Geometry(3001,null,null,sdo_elem_info_array(1,1,3),
                               sdo_ordinate_array(1.12345,1.3445,9,2.43534,2.03998398,9,3.43513,3.451245,9)),
                               mdsys.vertex_type(4.555,4.666,10,null,1),
                               3) as point
  from dual;
-- Update non-existant point 
select &&defaultSchema..GEOM.SDO_SetPoint(mdsys.SDO_Geometry(2001,null,null,sdo_elem_info_array(1,1,3),
                               sdo_ordinate_array(1.12345,1.3445,2.43534,2.03998398,3.43513,3.451245)),
                               mdsys.vertex_type(4.555,4.666,10,null,1),
                               10) as point
  from dual;

-- *****************************************
-- Linestrings
--Change third point in 3D single linestring
select &&defaultSchema..GEOM.SDO_SetPoint(SDO_Geometry(3002,null,null,sdo_elem_info_array(1,2,1),
                               sdo_ordinate_array(1.12345,1.3445,9,2.43534,2.03998398,9,3.43513,3.451245,9)),
                               mdsys.vertex_type(4.555,4.666,10,null,1),
                               3) as linestring3d
  from dual;

-- Change 3rd point in 3D multilinestring
select &&defaultSchema..GEOM.SDO_SetPoint(SDO_Geometry(3006,null,null,sdo_elem_info_array(1,2,1,10,2,1),
                               sdo_ordinate_array(1.12345,1.3445,9,2.43534,2.03998398,9,3.43513,3.451245,9,10,10,9,10,20,9)),
                               mdsys.vertex_type(4.555,4.666,10,null,1),
                               3) as mutlilinestring3
  from dual;

-- ********************************
-- Update the last point in a simple polygon (note result is incorrect)
select &&defaultSchema..GEOM.SDO_SetPoint(b.the_geom,
                         mdsys.vertex_type(1,1,null,null,1),
                         NULL) as setGeom
  from (select sdo_geometry('POLYGON((2 2, 2 7, 12 7, 12 2, 2 2))',NULL) as the_geom
         from dual
       ) b;

-- Now do it properly...
select &&defaultSchema..GEOM.SDO_SetPoint(Geom.SDO_SetPoint(b.the_geom,b.the_point,1),b.the_point,NULL) 
         as setGeom
  from (select sdo_geometry('POLYGON((2 2, 2 7, 12 7, 12 2, 2 2))',NULL) as the_geom,
               mdsys.vertex_type(1,1,null,null,1) as the_point
         from dual
       ) b;

-- How to set the first and last points in a single outer shelled compound polygon polygon
select &&defaultSchema..GEOM.SDO_SetPoint(
          &&defaultSchema..GEOM.SDO_SetPoint(
                 SDO_GEOMETRY(2003,null,null,
                             SDO_ELEM_INFO_ARRAY(1,1005,2,1,2,2,5,2,1),
                             SDO_ORDINATE_ARRAY(-0.175,9.998,-0.349,9.994,-0.523,9.986,0,0,-0.175,9.998)),
                 mdsys.vertex_type(1,1,null,null,1),
                 NULL),
          mdsys.vertex_type(1,1,null,null,1),
          1) as setGeom
  from dual;

-- MultiPolygon
select &&defaultSchema..GEOM.SDO_SetPoint(b.the_geom,
                         mdsys.vertex_type(2,7.5,null,null,1),
                         2).Get_WKT() as setGeom
  from (select sdo_geometry('MULTIPOLYGON(((2 2, 2 7, 12 7, 12 2, 2 2)), ((20 20, 20 70, 120 70, 120 20, 20 20)) )',NULL) as the_geom
         from dual
       ) b;

--- ADDPOINT TESTING
--------------------------
select &&defaultSchema..GEOM.SDO_AddPoint(mdsys.SDO_Geometry(3002,null,null,sdo_elem_info_array(1,2,1),
                               sdo_ordinate_array(1.12345,1.3445,9,2.43534,2.03998398,9,3.43513,3.451245,9)),
                               mdsys.vertex_type(4.555,4.666,10,null,null),
                               NULL) 
  from dual;

-- ADD point testing

select &&defaultSchema..GEOM.sdo_RemovePoint(mdsys.SDO_Geometry(3002,null,null,sdo_elem_info_array(1,2,1),
                               sdo_ordinate_array(1.12345,1.3445,9,2.43534,2.03998398,9,3.43513,3.451245,9)),
                               0) 
  from dual;

select &&defaultSchema..GEOM.sdo_AddPoint(mdsys.SDO_Geometry(3006,null,null,sdo_elem_info_array(1,2,1,7,2,1),
                               sdo_ordinate_array(1.1,1.3,9,2.43534,2.3,9,3.4,3.5,9,4.6,4.48,9)),
                               mdsys.vertex_type(5.5,5.6,9,null,null),
                               4) 
  from dual;
  
select &&defaultSchema..GEOM.sdo_AddPoint(mdsys.SDO_Geometry(3006,null,null,sdo_elem_info_array(1,2,1,7,2,1),
                               sdo_ordinate_array(1.12345,1.3445,9,2.43534,2.03998398,9,3.43513,3.451245,9,4.45645,4.4545,9)),
                               mdsys.vertex_type(5.555,5.666,9,null,null),
                               NULL) 
  from dual;

select &&defaultSchema..GEOM.SDO_RemovePoint(mdsys.SDO_Geometry(3006,null,null,sdo_elem_info_array(1,2,1,10,2,1),
                                          sdo_ordinate_array(0.23223,0.32432,9,1.12345,1.3445,9,2.43534,2.03998398,9,3.43513,3.451245,9,4.45645,4.4545,9,5.6745,5.34343,9)),
                            i.column_value) as new_geom
  from dual,
       table(&&defaultSchema..GEOM.generate_series(1,6,1)) i;

-- ********************************************************************************
-- SDO_VertexUpdate
-- *******************************************************************************
-- Update 2D null point
select &&defaultSchema..GEOM.SDO_VertexUpdate(
            mdsys.SDO_Geometry(2001,null,sdo_point_type(null,null,null),null,null),
                               mdsys.vertex_type(null,null,null,null,1),
                               mdsys.vertex_type(4.555,4.666,null,null,1)
                               ) as point
  from dual;
-- Update 3D null point
select &&defaultSchema..GEOM.SDO_VertexUpdate(
            mdsys.SDO_Geometry(2001,null,sdo_point_type(null,null,null),null,null),
                               mdsys.vertex_type(null,null,null,null,1),
                               mdsys.vertex_type(4.555,4.666,10,null,1)
                               ) as point
  from dual;
-- Update 4D null point
select &&defaultSchema..GEOM.SDO_VertexUpdate(
            mdsys.SDO_Geometry(4001,null,null,
                                mdsys.sdo_elem_info_array(1,1,1),
                                mdsys.sdo_ordinate_array(null,null,null,null)),
                               mdsys.vertex_type(null,null,null,null,1),
                               mdsys.vertex_type(4.555,4.666,5,6,1)
                               ) as point
  from dual;

-- LINESTRINGS
-- Update first point 
select &&defaultSchema..GEOM.SDO_VertexUpdate(
            mdsys.SDO_Geometry(2002,null,null,sdo_elem_info_array(1,2,1),
                               sdo_ordinate_array(1.12345,1.3445,2.43534,2.03998398,3.43513,3.451245)),
                               mdsys.vertex_type(1.12345,1.3445,null,null,1),
                               mdsys.vertex_type(29.8,29.9,99,null,1)) as point
  from dual;
-- Update any point 
select &&defaultSchema..GEOM.SDO_VertexUpdate(
            mdsys.SDO_Geometry(3002,null,null,sdo_elem_info_array(1,2,1),
                               sdo_ordinate_array(1.12345,1.3445,9,2.43534,2.03998398,9,3.43513,3.451245,9)),
                               mdsys.vertex_type(2.43534,2.03998398,9,null,1),
                               mdsys.vertex_type(29.8,29.9,99,null,1)) as point
  from dual;
-- Update last point 
select &&defaultSchema..GEOM.SDO_VertexUpdate(
            mdsys.SDO_Geometry(2002,null,null,sdo_elem_info_array(1,2,1),
                               sdo_ordinate_array(1.12345,1.3445,2.43534,2.03998398,3.43513,3.451245)),
                               mdsys.vertex_type(3.43513,3.451245,10,null,1),
                               mdsys.vertex_type(29.8,29.9,99,null,1)) as point
  from dual;
-- Update the last point in a simple polygon (note result is correct, as against SDO_SetPoint)
select &&defaultSchema..GEOM.SDO_VertexUpdate(
                         b.the_geom,
                         mdsys.vertex_type(2,2,null,null,1),
                         mdsys.vertex_type(29,29,null,null,1)) as setGeom
  from (select sdo_geometry('POLYGON((2 2, 2 7, 12 7, 12 2, 2 2))',NULL) as the_geom
         from dual
       ) b;
-- Update first point of complex polygon
select &&defaultSchema..GEOM.SDO_VertexUpdate(
                 SDO_GEOMETRY(2003,null,null,
                             SDO_ELEM_INFO_ARRAY(1,1005,2,1,2,2,5,2,1),
                             SDO_ORDINATE_ARRAY(-0.175,9.998,-0.349,9.994,-0.523,9.986,0,0,-0.175,9.998)),
                 mdsys.vertex_type(-0.175,9.998,null,null,1),
                 mdsys.vertex_type(1,1,null,null,1)) as UpdateGeom
  from dual;
-- MultiPolygon: Update first/last point in second geometry
select &&defaultSchema..GEOM.SDO_VertexUpdate(b.the_geom,
                         mdsys.vertex_type(20,20,null,null,1),
                         mdsys.vertex_type(21,21,null,null,1)).Get_WKT() as UpdateGeom
  from (select sdo_geometry('MULTIPOLYGON(((2 2, 2 7, 12 7, 12 2, 2 2)), ((20 20, 20 70, 120 70, 120 20, 20 20)) )',NULL) as the_geom
         from dual
       ) b;

-- ************************************
-- TOLERANCE
-- ************************************
SELECT &&defaultSchema..GEOM.Tolerance(a.geom,0.005) as geom
  FROM (SELECT mdsys.SDO_Geometry('LINESTRING(1.12345 1.3445,2.43534 2.03998398)') as geom 
          FROM dual) a;
  
SELECT &&defaultSchema..GEOM.Tolerance(a.geom,0.005,0.05).Get_WKT() as geom
  FROM (SELECT mdsys.SDO_Geometry('LINESTRING(1.12345 1.3445,2.43534 2.03998398)') as geom 
          FROM dual) a;

-- ************************************
-- Fix_Ordinates
-- ************************************
select &&defaultSchema..GEOM.fix_ordinates(mdsys.SDO_Geometry('POINT(1.25 2.44)'),
                          'ROUND(X * 3.141592653,3)',
                          'ROUND(Y * dbms_random.value(1,1000),3)',
                          NULL).Get_WKT() as point
  from dual;

select &&defaultSchema..GEOM.fix_ordinates(mdsys.SDO_Geometry(3001,null,sdo_point_type(1.25,2.44,3.09),null,null),
                          'ROUND(X * 3.141592653,3)',
                          'ROUND(Y * dbms_random.value(1,1000),3)',
                          'ROUND(Z / 1000,3)') as point
  from dual;

select &&defaultSchema..GEOM.fix_ordinates(mdsys.SDO_Geometry('LINESTRING(1.12345 1.3445,2.43534 2.03998398)'),
                          'ROUND(X * 3.141592653,3)',
                          'ROUND(Y * dbms_random.value(1,1000),3)').Get_WKT() as LINE2D
  from dual;

select &&defaultSchema..GEOM.fix_ordinates(SDO_Geometry(3006,null,null,sdo_elem_info_array(1,2,1,10,2,1),
                               sdo_ordinate_array(1.12345,1.3445,9,2.43534,2.03998398,9,3.43513,3.451245,9,10,10,9,10,20,9)),
                               NULL,
                               NULL,
                               'ROUND(z / (z * dbms_random.value(1,10)),3)',
                               NULL) as fixed_mutlilinestring3D
  from dual;
  
select &&defaultSchema..GEOM.fix_ordinates(SDO_GEOMETRY(
    3302,  -- line string, 3 dimensions: X,Y,M
    NULL,
    NULL,
    SDO_ELEM_INFO_ARRAY(1,2,1), -- one line string, straight segments
    SDO_ORDINATE_ARRAY(
      2,2,0,   -- Start point - Exit1; 0 is measure from start.
      2,4,2,   -- Exit2; 2 is measure from start. 
      8,4,8,   -- Exit3; 8 is measure from start. 
      12,4,12,  -- Exit4; 12 is measure from start. 
      12,10,NULL,  -- Not an exit; measure automatically calculated and filled.
      8,10,22,  -- Exit5; 22 is measure from start.  
      5,14,27)  -- End point (Exit6); 27 is measure from start.
  ),
  NULL,
  NULL,
  NULL,
  '(rownum * w)') as measured_geom
from dual;

set numformat 9999999.999
select 
&&defaultSchema..centroid.sdo_centroid(
sdo_geometry(2003, 82000, NULL ,
sdo_elem_info_array (1, 1005, 4, 1, 2, 1, 3, 2, 2, 7, 2, 1, 9, 2, 2 ),
sdo_ordinate_array(
227498.114022263, 1300538.63029401, 
227580.711071332, 1300625.68262124, 
227563.461558546, 1300641.86959784, 
227546.031319055, 1300657.86180389, 
227398.550732655, 1300660.62402885, 
227424.62785479,  1300613.46525468, 
227460.586197987, 1300573.32844073, 
227479.4618626,   1300556.1002334, 
227498.114022263, 1300538.63029401)),1,0.0005,0.1)
from dual;

select 
&&defaultSchema..GEOM.convert_geometry(
sdo_geometry(2003, 82000, NULL ,
sdo_elem_info_array (1, 1005, 4, 1, 2, 1, 3, 2, 2, 7, 2, 1, 9, 2, 2 ),
sdo_ordinate_array(
227498.114022263, 1300538.63029401, 
227580.711071332, 1300625.68262124, 
227563.461558546, 1300641.86959784, 
227546.031319055, 1300657.86180389, 
227398.550732655, 1300660.62402885, 
227424.62785479,  1300613.46525468, 
227460.586197987, 1300573.32844073, 
227479.4618626,   1300556.1002334, 
227498.114022263, 1300538.63029401)),0.1)
from dual;

select v.*
  from table(&&defaultSchema..GEOM.GetPointSet(sdo_geometry(2003, 82000, NULL ,
sdo_elem_info_array (1, 1005, 4, 1, 2, 1, 3, 2, 2, 7, 2, 1, 9, 2, 2 ),
sdo_ordinate_array(
227498.114022263, 1300538.63029401,
227580.711071332, 1300625.68262124,
227563.461558546, 1300641.86959784,
227546.031319055, 1300657.86180389,
227398.550732655, 1300660.62402885,
227424.62785479,  1300613.46525468,
227460.586197987, 1300573.32844073,
227479.4618626,   1300556.1002334,
227498.114022263, 1300538.63029401)),0.1)) v;

select 
&&defaultSchema..GEOM.To_3d(
sdo_geometry(2003, 82000, NULL ,
sdo_elem_info_array (1, 1005, 4, 1, 2, 1, 3, 2, 2, 7, 2, 1, 9, 2, 2 ),
sdo_ordinate_array(
227498.114022263, 1300538.63029401, 
227580.711071332, 1300625.68262124, 
227563.461558546, 1300641.86959784, 
227546.031319055, 1300657.86180389, 
227398.550732655, 1300660.62402885, 
227424.62785479,  1300613.46525468, 
227460.586197987, 1300573.32844073, 
227479.4618626,   1300556.1002334, 
227498.114022263, 1300538.63029401)),0.0005,0.1)
from dual;

select *
from table(&&defaultSchema..GEOM.getarcs(
&&defaultSchema..GEOM.To_3d(
sdo_geometry(2003, 82000, NULL ,
sdo_elem_info_array (1, 1005, 4, 1, 2, 1, 3, 2, 2, 7, 2, 1, 9, 2, 2 ),
sdo_ordinate_array(
227498.114022263, 1300538.63029401,
227580.711071332, 1300625.68262124,
227563.461558546, 1300641.86959784,
227546.031319055, 1300657.86180389,
227398.550732655, 1300660.62402885,
227424.62785479,  1300613.46525468,
227460.586197987, 1300573.32844073,
227479.4618626,   1300556.1002334,
227498.114022263, 1300538.63029401)),1000))) v
/

select *
from table(&&defaultSchema..GEOM.getpointset(
sdo_geometry(3003, 82000, NULL ,
sdo_elem_info_array (1, 1005, 4, 1, 2, 1, 4, 2, 2, 10, 2, 1, 13, 2, 2 ),
sdo_ordinate_array(
227498.114022263, 1300538.63029401,1,
227580.711071332, 1300625.68262124,2,
227563.461558546, 1300641.86959784,2,
227546.031319055, 1300657.86180389,2,
227398.550732655, 1300660.62402885,3,
227424.62785479,  1300613.46525468,3,
227460.586197987, 1300573.32844073,3,
227479.4618626,   1300556.1002334,3,
227498.114022263, 1300538.63029401,3)),0.1)) v
/

select *
from table(&&defaultSchema..GEOM.GetPointSet(&&defaultSchema..GEOM.convert_geometry(
sdo_geometry(4403, 82000, NULL ,
sdo_elem_info_array (
1, 1005, 4,
1, 2, 1,
5, 2, 2,
13, 2, 1,
17, 2, 2 ),
sdo_ordinate_array(
227498.114022263, 1300538.63029401,1,0,
227580.711071332, 1300625.68262124,2,10,
227563.461558546, 1300641.86959784,2,20,
227546.031319055, 1300657.86180389,2,30,
227398.550732655, 1300660.62402885,3,40,
227424.62785479,  1300613.46525468,3,50,
227460.586197987, 1300573.32844073,3,60,
227479.4618626,   1300556.1002334,3,70,
227498.114022263, 1300538.63029401,3,80)),0.1),0.1))
/

select *
from table(&&defaultSchema..GEOM.GetPointSet( sdo_geometry(2003, 82000, NULL ,
sdo_elem_info_array (
1, 1005, 4, 
1, 2, 1, 
3, 2, 2, 
7, 2, 1, 
9, 2, 2 ),
sdo_ordinate_array(
227498.114022263, 1300538.63029401,
227580.711071332, 1300625.68262124,
227563.461558546, 1300641.86959784,
227546.031319055, 1300657.86180389,
227398.550732655, 1300660.62402885,
227424.62785479,  1300613.46525468,
227460.586197987, 1300573.32844073,
227479.4618626,   1300556.1002334,
227498.114022263, 1300538.63029401)),0.1)) v
/

Prompt Now test APPEND and CONCAT_LINES...

select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(3001,null,mdsys.sdo_point_type(1,2,null),null,null),
              mdsys.sdo_geometry(3001,null,null,mdsys.sdo_elem_info_array(1,1,1),mdsys.sdo_ordinate_array(3,4,5))
             ) 
  from dual;
  
  
select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(3001,null,mdsys.sdo_point_type(1,2,null),null,null),
              mdsys.sdo_geometry(3001,4326,mdsys.sdo_point_type(3,4,5),null,null)
             ) 
  from dual;

select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(3001,null,mdsys.sdo_point_type(1,2,null),null,null),
              mdsys.sdo_geometry(2001,null,mdsys.sdo_point_type(3,4,5),null,null)
             ) 
  from dual;

select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(3001,null,mdsys.sdo_point_type(1,2,null),null,null),
              mdsys.sdo_geometry(3001,null,mdsys.sdo_point_type(3,4,5),null,null)
             ) 
  from dual;
  
select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(2001,null,mdsys.sdo_point_type(1,2,null),null,null),
              mdsys.sdo_geometry(2001,null,mdsys.sdo_point_type(3,4,null),null,null)
             ) 
  from dual;

select geom,sdo_geom.validate_geometry(geom,0.05)
  from ( select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(2001,null,mdsys.sdo_point_type(1,2,null),null,null),
                       mdsys.sdo_geometry(2005,null,null,mdsys.sdo_elem_info_array(1,1,2),mdsys.sdo_ordinate_array(3,4,5,6))
                      ) as geom
           from dual
        );
select geom,sdo_geom.validate_geometry(geom,0.05)
  from ( select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(2005,null,null,mdsys.sdo_elem_info_array(1,1,2),mdsys.sdo_ordinate_array(3,4,5,6)),
                       mdsys.sdo_geometry(2001,null,mdsys.sdo_point_type(1,2,null),null,null)
                      ) as geom
           from dual
        );
select geom,sdo_geom.validate_geometry(geom,0.05)
  from ( select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(2005,null,null,mdsys.sdo_elem_info_array(1,1,3),mdsys.sdo_ordinate_array(1,2,3,4,5,6)),
                       mdsys.sdo_geometry(2005,null,null,mdsys.sdo_elem_info_array(1,1,2),mdsys.sdo_ordinate_array(7,8,9,10))
                      ) as geom
           from dual
        );

select geom,sdo_geom.validate_geometry(geom,0.05)
  from ( select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(2001,null,mdsys.sdo_point_type(1,2,null),null,null),
                       mdsys.sdo_geometry(2002,null,null,mdsys.sdo_elem_info_array(1,2,1),mdsys.sdo_ordinate_array(3,4,5,6))
                      ) as geom
           from dual
        );

select SUBSTR(sdo_geom.validate_geometry(geom,0.05),1,10) as Valid, geom
  from ( select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(2001,null,mdsys.sdo_point_type(1,2,null),null,null),
                       MDSYS.SDO_GEOMETRY(2003,null,null,
                                          MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1,11,2003,1),
                                          MDSYS.SDO_ORDINATE_ARRAY(0,0,50,0,50,50,0,50,0,0,20,10,10,10,10,20,20,20,20,10))
                      ) as geom
           from dual
        );

select SUBSTR(sdo_geom.validate_geometry(geom,0.05),1,10) as Valid, geom
  from ( select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(2002,null,null,mdsys.sdo_elem_info_array(1,2,1),mdsys.sdo_ordinate_array(3,4,5,6)),
                       mdsys.sdo_geometry(2001,null,mdsys.sdo_point_type(1,2,null),null,null)
                      ) as geom
           from dual
        );

select SUBSTR(sdo_geom.validate_geometry(geom,0.05),1,10) as Valid, geom
  from ( select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(2002,null,mdsys.sdo_point_type(3,4,null),mdsys.sdo_elem_info_array(1,2,1),mdsys.sdo_ordinate_array(3,4,5,6)),
                       mdsys.sdo_geometry(2001,null,mdsys.sdo_point_type(1,2,null),null,null)
                      ) as geom
           from dual
        );

select SUBSTR(sdo_geom.validate_geometry(geom,0.05),1,10) as Valid, geom
  from ( select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(2002,null,mdsys.sdo_point_type(3,4,null),mdsys.sdo_elem_info_array(1,2,1),mdsys.sdo_ordinate_array(3,4,5,6)),
                       mdsys.sdo_geometry(2001,null,null,mdsys.sdo_elem_info_array(1,1,1),mdsys.sdo_ordinate_array(1,2))
                      ) as geom
           from dual
        );

select SUBSTR(sdo_geom.validate_geometry(geom,0.05),1,10) as Valid, geom
  from ( select sdo_util.concat_lines(mdsys.sdo_geometry(2002,null,null,mdsys.sdo_elem_info_array(1,2,1),mdsys.sdo_ordinate_array(1,2,3,4)),
                                      mdsys.sdo_geometry(2002,null,null,mdsys.sdo_elem_info_array(1,2,1),mdsys.sdo_ordinate_array(5,6,7,8))
                      ) as geom
           from dual
        )
UNION ALL
select SUBSTR(sdo_geom.validate_geometry(geom,0.05),1,10) as Valid, geom
  from ( select &&defaultSchema..GEOM.Concat_Lines(mdsys.sdo_geometry(2002,null,null,mdsys.sdo_elem_info_array(1,2,1),mdsys.sdo_ordinate_array(1,2,3,4)),
                                           mdsys.sdo_geometry(2002,null,null,mdsys.sdo_elem_info_array(1,2,1),mdsys.sdo_ordinate_array(5,6,7,8))
                      ) as geom
           from dual
        )
UNION ALL
select SUBSTR(sdo_geom.validate_geometry(geom,0.05),1,10) as Valid, geom
  from ( select &&defaultSchema..GEOM.Concat_Lines(mdsys.sdo_geometry(2002,null,null,mdsys.sdo_elem_info_array(1,2,1),mdsys.sdo_ordinate_array(1,2,3,4)),
                                           mdsys.sdo_geometry(2006,null,null,mdsys.sdo_elem_info_array(1,2,1,5,2,1),mdsys.sdo_ordinate_array(5,6,7,8,10,11,12,14))
                      ) as geom
           from dual
        )
UNION ALL
select SUBSTR(sdo_geom.validate_geometry(geom,0.05),1,10) as Valid, geom
  from ( select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(2002,null,null,mdsys.sdo_elem_info_array(1,2,1),mdsys.sdo_ordinate_array(1,2,3,4)),
                       mdsys.sdo_geometry(2002,null,null,mdsys.sdo_elem_info_array(1,2,1),mdsys.sdo_ordinate_array(5,6,7,8))
                      ) as geom
           from dual
        );
        
select SUBSTR(sdo_geom.validate_geometry(geom,0.05),1,10) as Valid, geom
  from ( select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(2002,null,null,mdsys.sdo_elem_info_array(1,2,1),mdsys.sdo_ordinate_array(1,2,3,4)),
                       MDSYS.SDO_GEOMETRY(2003,null,null,
                                          MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1,11,2003,1),
                                          MDSYS.SDO_ORDINATE_ARRAY(0,0,50,0,50,50,0,50,0,0,20,10,10,10,10,20,20,20,20,10))
                      ) as geom
           from dual
        );
        
select SUBSTR(sdo_geom.validate_geometry(geom,0.05),1,10) as Valid, geom
  from ( select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(2003,null,null,mdsys.sdo_elem_info_array(1,1003,3),mdsys.sdo_ordinate_array(-10,-10, -5, -5)),
                       MDSYS.SDO_GEOMETRY(2003,null,null,
                                          MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1,11,2003,1),
                                          MDSYS.SDO_ORDINATE_ARRAY(0,0,50,0,50,50,0,50,0,0,20,10,10,10,10,20,20,20,20,10))
                      ) as geom
           from dual
        );
select SUBSTR(sdo_geom.validate_geometry(geom,0.05),1,10) as Valid, geom
  from ( select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(2003,null,null,mdsys.sdo_elem_info_array(1,1003,3),mdsys.sdo_ordinate_array(-10,-10, -5, -5)),
                       MDSYS.SDO_GEOMETRY(2007,null,null,
                                          MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1,11,1003,1),
                                          MDSYS.SDO_ORDINATE_ARRAY(0,0,50,0,50,50,0,50,0,0,
                                                                   100,100,200,100,200,200,100,200,100,100))
                      ) as geom
           from dual
        );

select SUBSTR(sdo_geom.validate_geometry(geom,0.05),1,10) as Valid, geom
  from ( select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(2002,null,null,mdsys.sdo_elem_info_array(1,2,1),mdsys.sdo_ordinate_array(-10,-10,60,60)),
                       MDSYS.SDO_GEOMETRY(2004,null,null,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3,5,1003,1,15,2003,1),MDSYS.SDO_ORDINATE_ARRAY(-10,-10,60,60,0,0,50,0,50,50,0,50,0,0,20,10,10,10,10,20,20,20,20,10))
                      ) as geom
           from dual
        );

select SUBSTR(sdo_geom.validate_geometry(geom,0.05),1,10) as Valid, geom
  from ( select &&defaultSchema..GEOM.Append(mdsys.sdo_geometry(2002,null,null,mdsys.sdo_elem_info_array(1,2,1),mdsys.sdo_ordinate_array(-10,-10,60,60)),
                       MDSYS.SDO_GEOMETRY(2004,null,null,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3,5,1003,1,15,2003,1),MDSYS.SDO_ORDINATE_ARRAY(-10,-10,60,60,0,0,50,0,50,50,0,50,0,0,20,10,10,10,10,20,20,20,20,10))
                      ) as geom
           from dual
        );

Prompt Test SwapOrdinates

select &&defaultSchema..GEOM.SwapOrdinates(mdsys.sdo_geometry(3001,null,mdsys.sdo_point_type(1,20,30),null,null),'XY') as Geom
  from dual union all
select &&defaultSchema..GEOM.SwapOrdinates(mdsys.sdo_geometry(3001,null,mdsys.sdo_point_type(1,20,30),null,null),'XZ') as Geom
  from dual union all
select &&defaultSchema..GEOM.SwapOrdinates(mdsys.sdo_geometry(3001,null,mdsys.sdo_point_type(1,20,30),null,null),'YZ') as Geom
  from dual union all
select &&defaultSchema..GEOM.SwapOrdinates(mdsys.sdo_geometry('LINESTRING (-32 147, -33 180)'),'XY') as Geom
  from dual union all
select &&defaultSchema..GEOM.SwapOrdinates(mdsys.sdo_geometry('LINESTRING (0 50, 10 50, 10 55, 10 60, 20 50)'),'XY') as Geom
  from dual union all
select &&defaultSchema..GEOM.SwapOrdinates(mdsys.sdo_geometry(3002,null,null,
                     mdsys.sdo_elem_info_array(1,2,1),
                     mdsys.sdo_ordinate_array(0,50,105, 
                                              10,50,110, 
                                              10,55,115, 
                                              10,60,120, 
                                              20,50,125)),'XZ') as Geom
  from dual union all
select &&defaultSchema..GEOM.SwapOrdinates(mdsys.sdo_geometry(3002,null,
                     mdsys.sdo_point_type(1,20,30),
                     mdsys.sdo_elem_info_array(1,2,1),
                     mdsys.sdo_ordinate_array(0,50,105, 
                                              10,50,110, 
                                              10,55,115, 
                                              10,60,120, 
                                              20,50,125)),'YZ') as Geom
  from dual union all
select &&defaultSchema..GEOM.SwapOrdinates(MDSYS.SDO_GEOMETRY(3302, NULL, NULL,
                     MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1),
                     MDSYS.SDO_ORDINATE_ARRAY(5,10,0, 
                                              20,5,NULL, 
                                              35,10,NULL, 
                                              55,10,100)),'XM') as Geom
  from dual union all
select &&defaultSchema..GEOM.SwapOrdinates(MDSYS.SDO_GEOMETRY(4402, NULL, NULL,
                     MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1),
                     MDSYS.SDO_ORDINATE_ARRAY(5,10,500,0, 
                                              20,5,501,NULL, 
                                              35,10,502,NULL, 
                                              55,10,503,100)),'ZM') as Geom
  from dual;

select &&defaultSchema..GEOM.isCompound(MDSYS.SDO_ELEM_INFO_ARRAY(1,4,2,1,2,2,5,2,1,13,2,1,17,2,1,21,2,1)) as isCmpd
from dual;

select &&defaultSchema..GEOM.isCompound(MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1,5,2,1,9,2,1,17,4,2,17,2,1,23,2,2)) as isCmpd
from dual;

WITH testGeom As (
  SELECT sdo_geometry(     'POLYGON( (0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',null) as geom FROM DUAL UNION ALL
  SELECT SDO_GEOMETRY('MULTIPOLYGON(((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5)), ((40 40,50 40,50 50,40 50,40 40)))',null) as geom FROM DUAL UNION ALL
  SELECT SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1005,2, 1,2,1, 5,2,2),SDO_ORDINATE_ARRAY(6,10, 10,1, 14,10, 10,14, 6,10)) as geom FROM DUAL UNION ALL
  SELECT SDO_GEOMETRY(2007,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1005,2, 1,2,1, 5,2,2,11,2005,2, 11,2,1, 15,2,2,21,1005,2, 21,2,1, 25,2,2),SDO_ORDINATE_ARRAY(  6,10, 10,1, 14,10, 10,14,  6,10,13,10, 10,2,  7,10, 10,13, 13,10,106,110, 110,101, 114,110, 110,114,106,110)) as geom FROM DUAL UNION ALL
  SELECT SDO_GEOMETRY(2007,null,null,SDO_ELEM_INFO_ARRAY(1,1003,3,5,1003,1,15,2003,3),SDO_ORDINATE_ARRAY(-10,-10,60,60,0,0,50,0,50,50,0,50,0,0,10,10,12,12)) as geom FROM DUAL 
)
SELECT &&defaultSchema..GEOM.Filter_Rings(a.geom,0.005,2.0) as filtered_geom
  FROM testGeom a

QUIT;

