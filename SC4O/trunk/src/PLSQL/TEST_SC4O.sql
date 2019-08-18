define defaultSchema='&1'

SET PAGESIZE  5000;
SET LINESIZE 30000;
SET LONG     30000;
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TERMOUT ON;
SET TRIMSPOOL OFF;
SET VERIFY OFF;
SET SQLNUMBER OFF;
SET SHOWMODE OFF;
SET ECHO ON;

-- ***********************************************************************************
-- ST_DelaunayTriangles
-- ***********************************************************************************
-- Method 1: From MultiPoint
--
With data as (
  select &&DefaultSchema..SC4O.ST_GeomFromEWKT('SRID=32615;MULTIPOINT ((755441.542258283 3678850.38541675 9.14999999944121), (755438.136705691 3679051.52458636 9.86999999918044), (755642.681431119 3678853.79096725 10.0000000018626), (755639.275877972 3679054.93014137 10), (755635.870328471 3679256.06930606 8.62999999988824), (755843.82060051 3678857.19651868 10), (755840.415056435 3679058.33568674 9.99999999906868), (755837.009506021 3679259.47485623 10), (755959.586342714 3679438.15319976 5.94999999925494), (756044.959776444 3678860.6020602 9.95000000018626), (756041.554231838 3679061.74123334 10.0000000009313), (756038.148680523 3679262.88040789 9.26999999862164))')
             as points
    from dual
)
select &&DefaultSchema..SC4O.ST_AsEWKT(
        &&DefaultSchema..SC4O.ST_Round(
          &&DefaultSchema..SC4O.ST_DelaunayTriangles(
            a.points,
            0.05,
            10
          ),
          3
        )
       ) as triangles
  from data a;

-- Method 2: COLLECT from set of points
--
With data as (
  select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755959.58634214,3679438.15320103,5.95),NULL,NULL) as point from dual union all
  select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(756038.14867762,3679262.88040938,9.27),NULL,NULL) as point from dual union all
  select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755837.009504873,3679259.47485944,10),NULL,NULL) as point from dual union all
  select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755635.870332123,3679256.0693095,8.63),NULL,NULL) as point from dual union all
  select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755438.136709314,3679051.52458769,9.87),NULL,NULL) as point from dual union all
  select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755639.275882053,3679054.93013763,10),NULL,NULL) as point from dual union all
  select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755840.415054801,3679058.33568758,10),NULL,NULL) as point from dual union all
  select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(756041.554227549,3679061.74123752,10),NULL,NULL) as point from dual union all
  select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(756044.959777476,3678860.60206565,9.95),NULL,NULL) as point from dual union all
  select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755843.820604722,3678857.19651571,10),NULL,NULL) as point from dual union all
  select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755642.681431989,3678853.79096576,10),NULL,NULL) as point from dual union all
  select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755441.54225925,3678850.38541582,9.15),NULL,NULL) as point from dual
)
select &&DefaultSchema..SC4O.ST_AsEWKT(
        &&DefaultSchema..SC4O.ST_Round(
         &&DefaultSchema..SC4O.ST_DelaunayTriangles(
           cast(collect(a.point) as sdo_geometry_array),
           0.05,10
         ),
         3
        )
       ) as triangles
  from data a;

-- Method 3: Cursor
--
select &&DefaultSchema..SC4O.ST_AsEWKT(
        &&DefaultSchema..SC4O.ST_Round(
         &&DefaultSchema..SC4O.ST_DelaunayTriangles(
          CURSOR(
           select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755959.58634214,3679438.15320103,5.95),NULL,NULL) as point from dual union all
           select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(756038.14867762,3679262.88040938,9.27),NULL,NULL) as point from dual union all
           select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755837.009504873,3679259.47485944,10),NULL,NULL) as point from dual union all
           select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755635.870332123,3679256.0693095,8.63),NULL,NULL) as point from dual union all
           select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755438.136709314,3679051.52458769,9.87),NULL,NULL) as point from dual union all
           select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755639.275882053,3679054.93013763,10),NULL,NULL) as point from dual union all
           select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755840.415054801,3679058.33568758,10),NULL,NULL) as point from dual union all
           select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(756041.554227549,3679061.74123752,10),NULL,NULL) as point from dual union all
           select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(756044.959777476,3678860.60206565,9.95),NULL,NULL) as point from dual union all
           select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755843.820604722,3678857.19651571,10),NULL,NULL) as point from dual union all
           select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755642.681431989,3678853.79096576,10),NULL,NULL) as point from dual union all
           select SDO_GEOMETRY(3001,32615,SDO_POINT_TYPE(755441.54225925,3678850.38541582,9.15),NULL,NULL) as point from dual 
         ),0.05,10
        ),
        2
       )
      ) as triangles
 from dual;

set serveroutput on size unlimited
declare
  mycur  &&DefaultSchema..SC4O.refcur_t;
  v_geom mdsys.sdo_geometry;
begin
  open mycur for 
    With data as (
      select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755959.58634214,3679438.15320103,5.95),NULL,NULL) as point from dual union all
      select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(756038.14867762,3679262.88040938,9.27),NULL,NULL) as point from dual union all
      select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755837.009504873,3679259.47485944,10),NULL,NULL) as point from dual union all
      select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755635.870332123,3679256.0693095,8.63),NULL,NULL) as point from dual union all
      select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755438.136709314,3679051.52458769,9.87),NULL,NULL) as point from dual union all
      select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755639.275882053,3679054.93013763,10),NULL,NULL) as point from dual union all
      select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755840.415054801,3679058.33568758,10),NULL,NULL) as point from dual union all
      select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(756041.554227549,3679061.74123752,10),NULL,NULL) as point from dual union all
      select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(756044.959777476,3678860.60206565,9.95),NULL,NULL) as point from dual union all
      select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755843.820604722,3678857.19651571,10),NULL,NULL) as point from dual union all
      select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755642.681431989,3678853.79096576,10),NULL,NULL) as point from dual union all
      select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755441.54225925,3678850.38541582,9.15),NULL,NULL) as point from dual 
    )
    select point from data a;
  v_geom := &&DefaultSchema..SC4O.ST_DelaunayTriangles(mycur,0.05,10);
  dbms_output.put_line('Delaunay: ' || &&DefaultSchema..SC4O.ST_AsEWKT(v_geom));
  Close myCur;
END;
/

-- ***********************************************************************************
-- ST_Voronoi
-- ***********************************************************************************
-- Method 1: From MultiPoint
--
With data as (
  select &&DefaultSchema..SC4O.ST_GeomFromEWKT('SRID=32615;MULTIPOINT ((755441.542258283 3678850.38541675 9.14999999944121), (755438.136705691 3679051.52458636 9.86999999918044), (755642.681431119 3678853.79096725 10.0000000018626), (755639.275877972 3679054.93014137 10), (755635.870328471 3679256.06930606 8.62999999988824), (755843.82060051 3678857.19651868 10), (755840.415056435 3679058.33568674 9.99999999906868), (755837.009506021 3679259.47485623 10), (755959.586342714 3679438.15319976 5.94999999925494), (756044.959776444 3678860.6020602 9.95000000018626), (756041.554231838 3679061.74123334 10.0000000009313), (756038.148680523 3679262.88040789 9.26999999862164))')
            as points
    from dual 
)
select &&defaultSchema..SC4O.ST_AsEWKT(
         &&DefaultSchema..SC4O.ST_Round(
           &&DefaultSchema..SC4O.ST_Voronoi(a.points,NULL,0.05,10),
          3)
       ) as triangles
  from data a;

-- Method 2: COLLECT from single points
--
With data as (
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755959.58634214,3679438.15320103,5.95),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(756038.14867762,3679262.88040938,9.27),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755837.009504873,3679259.47485944,10),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755635.870332123,3679256.0693095,8.63),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755438.136709314,3679051.52458769,9.87),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755639.275882053,3679054.93013763,10),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755840.415054801,3679058.33568758,10),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(756041.554227549,3679061.74123752,10),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(756044.959777476,3678860.60206565,9.95),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755843.820604722,3678857.19651571,10),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755642.681431989,3678853.79096576,10),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755441.54225925,3678850.38541582,9.15),NULL,NULL) as point from dual 
)
select &&defaultSchema..SC4O.ST_AsEWKT(
         &&DefaultSchema..SC4O.ST_Round(
           &&DefaultSchema..SC4O.ST_Voronoi(cast(collect(a.point) as mdsys.sdo_geometry_array),NULL,0.05,10),
          3)
       ) as triangles
  from data a;

-- Method 3: From Refcursor containing individual points
--
set serveroutput on size unlimited
declare
  mycur  &&DefaultSchema..SC4O.refcur_t;
  v_geom mdsys.sdo_geometry;
begin
  open mycur for 
WITH DATA AS (
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755959.58634214,3679438.15320103,5.95),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(756038.14867762,3679262.88040938,9.27),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755837.009504873,3679259.47485944,10),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755635.870332123,3679256.0693095,8.63),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755438.136709314,3679051.52458769,9.87),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755639.275882053,3679054.93013763,10),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755840.415054801,3679058.33568758,10),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(756041.554227549,3679061.74123752,10),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(756044.959777476,3678860.60206565,9.95),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755843.820604722,3678857.19651571,10),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755642.681431989,3678853.79096576,10),NULL,NULL) as point from dual union all
  select MDSYS.SDO_GEOMETRY(3001,32615,MDSYS.SDO_POINT_TYPE(755441.54225925,3678850.38541582,9.15),NULL,NULL) as point from dual 
)
select point
  from data a;
  v_geom := &&DefaultSchema..SC4O.ST_Voronoi(mycur,NULL,0.05,10);
  v_geom := &&DefaultSchema..SC4O.ST_Round(v_geom,3);
  dbms_output.put_line(REGEXP_REPLACE(&&DefaultSchema..SC4O.ST_AsEWKT(v_geom),'POLYGON',CHR(10)||'POLYGON'));
  Close myCur;
END;
/

-- ST_InterpolateZ
select &&DefaultSchema..SC4O.ST_InterpolateZ(
         &&DefaultSchema..SC4O.ST_GeomFromEWKT('POINT(755027.456 3679331.845)',28355),
         &&DefaultSchema..SC4O.ST_GeomFromEWKT('POINT(754831.314 3678940.652 1.0)',28355),
         &&DefaultSchema..SC4O.ST_GeomFromEWKT('POINT(755540.409 3678952.658 2.6)',28355),
         &&DefaultSchema..SC4O.ST_GeomFromEWKT('POINT(754831.314 3679835.988 6.2)',28355) 
       ) AS Z
  from DUAL;

select &&DefaultSchema..SC4O.ST_InterpolateZ(
          p_point => SDO_GEOMETRY('POINT(755027.456 3679331.845)',28355),
          p_facet => &&DefaultSchema..SC4O.ST_GeomFromEWKT('POLYGON ((754831.314 3678940.652 1.0, 755540.409 3678952.658 2.6, 754831.314 3679835.988 6.2, 754831.314 3678940.652 1.0))',28355) 
       ) AS PointZ
  from DUAL;

-- ***********************************************************************************
-- ST_Densify, ST_DouglasPeuckerSimplify and ST_TopologyPreservingSimplify
-- ***********************************************************************************
--
select &&DefaultSchema..SC4O.ST_AsText(
         &&DefaultSchema..SC4O.ST_Densify(sdo_geometry('LINESTRING(0 0, 10 10, 10 0, 20 10)',0),2,3)
       ) as dGeom 
  from dual;

select &&DefaultSchema..SC4O.ST_Densify(sdo_geometry(2003,null,null,sdo_elem_info_array(1,1003,3),sdo_ordinate_array(1,1,10,10)),2,3) as dGeom 
  from dual;
  
With data As ( 
  select SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1), 
                      SDO_ORDINATE_ARRAY(191060.535,576339.562,186987.358,581000.620,184257.910,575373.757,181570.453,577305.367,180562.657,571300.581,175901.599,580958.628,174263.930,574575.919,171282.533,575037.825,170694.652,572266.385)) 
            as geom
    from dual
)
select &&defaultSchema..SC4O.ST_DouglasPeuckerSimplify(a.geom,5000,3) as geom from data a;

With data As ( 
  select sdo_geometry('POLYGON ((120 120, 121 121, 122 122, 220 120, 180 199, 160 200, 140 199, 120 120))',null) as geom
    from dual
)
select &&defaultSchema..SC4O.ST_DouglasPeuckerSimplify(a.geom,10.0,3) as geom from data a;

With data As ( 
  select sdo_geometry('POLYGON ((3312459.605 6646878.353, 3312460.524 6646875.969, 3312459.427 6646878.421, 3312460.014 6646886.391, 3312465.889 6646887.398, 3312470.827 6646884.839, 3312475.4 6646878.027, 3312477.289 6646871.694, 3312472.748 6646869.547, 3312468.253 6646874.01, 3312463.52 6646875.779, 3312459.605 6646878.353))',28355) as geom
    from dual
   union all 
  select sdo_geometry('POLYGON ((80 200, 240 200, 240 60, 80 60, 80 200), (120 120, 220 120, 180 199, 160 200, 140 199, 120 120))',null) as geom
    from dual
)
select &&defaultSchema..SC4O.ST_TopologyPreservingSimplify(a.geom,5000,3) as geom from data a;

With data As (
  select 5000.0 as distance_tolerance,
         SDO_GEOMETRY(2002,NULL,NULL,
                      SDO_ELEM_INFO_ARRAY(1,2,1),
                      SDO_ORDINATE_ARRAY(170795.473,572319.395, 171380.236,575041.567, 174263.723,574638.282, 175897.026,580889.197,
                                         180554.966,571311.183, 181583.342,577320.126, 178921.662,578771.952, 182652.047,580667.39,
                                         181684.163,577320.126, 184245.022,575344.031, 187007.523,580969.854, 190939.55,576392.571))
          as geom
    from dual
   union all
  select 10.0 as distance_tolerance,
         sdo_geometry('POLYGON ((1721270 693090, 1721400 693090, 1721400 692960, 1721270 692960, 1721270 693090), (1721355.3 693015.146, 1721318.687 693046.251, 1721306.747 693063.038, 1721367.025 692978.29, 1721355.3 693015.146))',28355) as geom
    from dual
)
select GIS.SC4O.ST_VisvalingamWhyattSimplify(a.geom,a.distance_tolerance,3) as geom from data a;

GEOM
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(170795.473,572319.395,175897.026,580889.197,180554.966,571311.183,187007.523,580969.854,190939.55,576392.571))
SDO_GEOMETRY(2003,28355,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1,11,2003,1),SDO_ORDINATE_ARRAY(1721270,693090,1721270,692960,1721400,692960,1721400,693090,1721270,693090,1721355.3,693015.146,1721367.025,692978.29,1721318.687,693046.251,1721355.3,693015.146))


-- ***********************************************************************************
-- ST_InsertVertex
-- ***********************************************************************************
-- ST_InsertVertex testing
-- Test update of SDO_POINT structure with valid ordinate values
select &&DefaultSchema..SC4O.ST_InsertVertex(
           mdsys.SDO_Geometry(3001,null,sdo_point_type(1.12345,2.43534,3.43513),null,null),
           mdsys.SDO_Geometry(3001,null,sdo_point_type(4.555,4.666,10),null,null),
           1
        ) as atStart,
       &&DefaultSchema..SC4O.ST_InsertVertex(
           mdsys.SDO_Geometry(3001,null,sdo_point_type(1.12345,2.43534,3.43513),null,null),
           mdsys.SDO_Geometry(3001,null,sdo_point_type(4.555,4.666,10),null,null),
           -1
       ) as atEnd
  from dual;

-- Add point at every position in MultiPoint
with data as (
   select mdsys.SDO_Geometry(2005,null,null,sdo_elem_info_array(1,1,3),sdo_ordinate_array(1.1,1.3,2.4,2.03,3.4,3.5)) as mPoint
     from dual
)
select case when b.posn =  SDO_UTIL.GETNUMVERTICES((select mPoint from data)) + 2 then -1 else b.posn end as posn,
       &&DefaultSchema..SC4O.ST_InsertVertex(
           a.mPoint,
           mdsys.SDO_Geometry(2001,null,sdo_point_type(4.5,4.6,null),null,null),
           case when b.posn =  SDO_UTIL.GETNUMVERTICES((select mPoint from data)) + 2 then -1 else b.posn end /* Means append to end of coordinates */
       ) as point
  from data a,
       (select level as posn 
          from dual 
          connect by level <= ( SDO_UTIL.GETNUMVERTICES((select mPoint from data)) + 2) ) b;

-- Test a linestring (should throw exception)
With data as (
  SELECT mdsys.sdo_geometry('LINESTRING(1.12345 1.3445,2.43534 2.03998398,3.43513 3.451245)') as linestring,
         mdsys.sdo_geometry('POINT(4.555 4.666)') as point
    FROM dual
)
SELECT &&DefaultSchema..SC4O.ST_InsertVertex(a.linestring,a.point,null/*Will throw exception as null interpreted as 0*/).Get_WKT() as geom
  FROM data a;
       
With data as (
  SELECT mdsys.sdo_geometry('LINESTRING(1.12345 1.3445,2.43534 2.03998398,3.43513 3.451245)',null) as linestring,
         mdsys.sdo_geometry('POINT(4.555 4.666)',null) as point
    FROM dual
)
SELECT &&DefaultSchema..SC4O.ST_InsertVertex(a.linestring,a.point,1/*Insert at beginning of linestring*/).Get_WKT() as geom
  FROM data a;

-- Multilinestring
With data as (
  SELECT mdsys.sdo_geometry('MULTILINESTRING ((1.1 1.1, 2.2 2.2, 3.3 3.3), (10.0 10.0, 10.0 20.0))') as multilinestring,
         mdsys.sdo_geometry('POINT(-1 -1)') as point
    FROM dual
)
SELECT &&DefaultSchema..SC4O.ST_InsertVertex(a.multilinestring,a.point,1).Get_WKT() as st_geom
  FROM data a;

With Data as (
  SELECT mdsys.sdo_geometry('MULTILINESTRING ((1.1 1.1, 2.2 2.2, 3.3 3.3), (10.0 10.0, 10.0 20.0))') as multilinestring,
         mdsys.sdo_geometry('POINT(4.4 4.4)') as point
    FROM dual
)
SELECT &&DefaultSchema..SC4O.ST_InsertVertex(a.multilinestring,a.point,4).Get_WKT() as geom
  FROM data a;

With data as (
  SELECT mdsys.sdo_geometry('MULTILINESTRING ((1.1 1.1, 2.2 2.2, 3.3 3.3), (10.0 10.0, 10.0 20.0))') as multilinestring,
         mdsys.sdo_geometry('POINT(30 30)') as point
    FROM dual
)
SELECT &&DefaultSchema..SC4O.ST_InsertVertex(a.multilinestring,a.point,-1).Get_WKT() as st_geom
  FROM data a;

-- ***********************************************************************************
-- ST_UpdateVertex
-- ***********************************************************************************
-- ST_UpdatePoint all indexes 
with data as (
   select mdsys.SDO_Geometry(2005,null,null,sdo_elem_info_array(1,1,3),sdo_ordinate_array(1.1,1.3,2.4,2.03,3.4,3.5)) as mPoint
     from dual
)
select case when b.posn =  SDO_UTIL.GETNUMVERTICES((select mPoint from data)) + 1 then -1 else b.posn end as posn,
       &&DefaultSchema..SC4O.ST_UpdateVertex(a.mPoint,
                                mdsys.SDO_Geometry(2001,null,sdo_point_type(4.5,4.6,null),null,null),
                                case when b.posn =  SDO_UTIL.GETNUMVERTICES((select mPoint from data)) + 1 then -1 else b.posn end /* Means append to end of coordinates */
                        ) 
            as point
  from data a,
       (select level as posn from dual connect by level <= ( SDO_UTIL.GETNUMVERTICES((select mPoint from data)) + 1) ) b;

-- ST_UpdateVertex from/to 
With data as (
select mdsys.SDO_Geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1.12345,1.3445,2.43534,2.03998398,3.43513,3.451245)) as geom, 
       mdsys.SDO_Geometry(2001,null,sdo_point_type(3.43513,3.451245,null),null,null) as fromPoint,
       mdsys.SDO_Geometry(2001,null,sdo_point_type(4.555,4.666,null),null,null) as toPoint
  from dual
)
select &&DefaultSchema..SC4O.ST_UpdateVertex(a.geom,a.fromPoint,a.toPoint) as updated_geom
  from data a;
            
-- LinearRing single point update returns LINESTRING...
With data as (
  select mdsys.sdo_geometry('LINESTRING(2 2, 2 7, 12 7, 12 2, 2 2)',NULL) as the_line,
         mdsys.SDO_Geometry(2001,null,sdo_point_type(1,1,null),null,null) as the_point
    from dual
)
select &&DefaultSchema..SC4O.ST_UpdateVertex(b.the_line,b.the_point,1) as setPointOfPoly
  from data b;

-- If point first or last in existing polygon it will fail .... 
With data as (
  select mdsys.sdo_geometry('POLYGON((2 2, 2 7, 12 7, 12 2, 2 2))',NULL)        as the_poly,
         mdsys.SDO_Geometry(2001,null,sdo_point_type(1,1,null),null,null) as the_point
    from dual
)
select &&DefaultSchema..SC4O.ST_UpdateVertex(b.the_poly,b.the_point,1) as setPointOfPoly
  from data b;

-- .... So up overloaded ST_UpdateVertex...
With data as (
  select mdsys.sdo_geometry('POLYGON((2 2, 2 7, 12 7, 12 2, 2 2))',NULL)  as the_poly,
         mdsys.SDO_Geometry(2001,null,sdo_point_type(2,2,null),null,null) as from_Point,
         mdsys.SDO_Geometry(2001,null,sdo_point_type(1,1,null),null,null) as to_Point
    from dual
)
select &&DefaultSchema..SC4O.ST_UpdateVertex(b.the_poly,b.from_point,b.to_point) as setPointOfPoly
  from data b;

-- ***********************************************************************************
-- ST_DeleteVertex
-- ***********************************************************************************

-- Test single point in two forms
select &&DefaultSchema..SC4O.ST_DeleteVertex(
           mdsys.SDO_Geometry(3001,null,null,sdo_elem_info_array(1,1,1),sdo_ordinate_array(1.1,2.4,3.5)),
           1
       ) as point
  from dual;

select &&DefaultSchema..SC4O.ST_DeleteVertex(
           mdsys.SDO_Geometry(3001,null,sdo_point_type(1.1,2.4,3.5),null,null),
           1
       ) as point
  from dual;

-- Remove first coordinate in standard LineString
define DefaultSchema='GIS'
With data as (
  SELECT mdsys.sdo_geometry('LINESTRING(1.1 1.1,2.2 2.2,3.3 3.3)',null) as linestring
    FROM dual
)
SELECT &&DefaultSchema..SC4O.ST_DeleteVertex(a.linestring,1) as st_geom
  FROM data a;

-- Remove points 1-4 in a 3D LineString, note 0 and NULL denote is the last coord
With data as (
  select sdo_util.getNumVertices(b.geom)+1 as numVertices,
        b.geom
   from (select mdsys.SDO_Geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1.1,1.1,9, 2.2,2.2,9, 3.3,3.3,9)) as geom 
           from dual
        ) b
)
select CAST('Deleting ' || (case when LEVEL < 4 then LEVEL else -1 END) || ' out of ' || (a.numVertices-1) as varchar2(50)) as pointN,
       &&DefaultSchema..SC4O.ST_DeleteVertex(a.geom,case when LEVEL < a.numVertices then LEVEL else -1 END 
       ) as RemovedPoint
  from data a
 connect by level <= a.numVertices;

-- Test single polygon
select null as removedVertex, mdsys.sdo_geometry('POLYGON((2 2, 12 2, 12 7, 2 7, 2 2))',NULL) as geom from dual
union all select 2 as removedVertex, &&DefaultSchema..SC4O.ST_DeleteVertex(sdo_geometry('POLYGON((2 2, 12 2, 12 7, 2 7, 2 2))',NULL),2) as geom from dual
union all select 3 as removedVertex, &&DefaultSchema..SC4O.ST_DeleteVertex(sdo_geometry('POLYGON((2 2, 12 2, 12 7, 2 7, 2 2))',NULL),3) as geom from dual;
 
-- Exceptions.....  
-- Try to remove a point from 2 point linestring (should get error)
SELECT &&DefaultSchema..SC4O.ST_DeleteVertex(mdsys.sdo_geometry('LINESTRING(1.1 1.1,2.2 2.2)',null),1).Get_WKT() as st_geom
  FROM dual;

-- Try to remove 2 points from three point linestring (should get error)
SELECT &&DefaultSchema..SC4O.ST_DeleteVertex(
           &&DefaultSchema..SC4O.ST_DeleteVertex(mdsys.sdo_geometry('LINESTRING(1.1 1.1,2.2 2.2,3.3 3.3)',null),
                                                 1),
           1).Get_WKT() as st_geom
  FROM dual;
  
-- Remove vertices from multipoint
-- Test single point
define DefaultSchema='GIS'
set serveroutput on size unlimited
declare
  v_geom        mdsys.sdo_geometry;
  v_mpoint      mdsys.sdo_geometry := mdsys.SDO_Geometry(2005,null,null,sdo_elem_info_array(1,1,3),sdo_ordinate_array(1.1,1.1,2.2,2.2,3.2,3.2));
  v_numVertices pls_integer;
  v_pointN      pls_integer;
begin
  v_numVertices := sdo_util.getNumVertices(v_mpoint);
  for i in 1..(v_numVertices+1) loop
    v_pointN := i;
    if ( i = (v_numVertices+1) ) then
      v_pointN := -1;
    End If;
    dbms_output.put_line('Deleting ' || v_pointN || ' of ' || v_numVertices);
    v_geom := &&DefaultSchema..SC4O.ST_DeleteVertex(v_mPoint,v_pointN);
  End Loop;
End;
/
show errors

-- ***********************************************************************************
-- ST_LineMerger
-- ***********************************************************************************
--
select &&DefaultSchema..SC4O.st_linemerger(
         cast(
           multiset(
             select sdo_geometry('LINESTRING (160 310, 160 280, 160 250, 170 230)',NULL) as geom from dual union all
             select sdo_geometry('LINESTRING (170 230, 180 210, 200 180, 220 160)',NULL) as geom from dual union all
             select sdo_geometry('LINESTRING (160 310, 200 330, 220 340, 240 360)',NULL) as geom from dual union all
             select sdo_geometry('LINESTRING (240 360, 260 390, 260 410, 250 430)',NULL) as geom from dual 
           ) as mdsys.sdo_geometry_array
         ),
         2
       )as mLines
  from dual;

select SC4O.ST_LineMerger(
         CURSOR(
           select sdo_geometry('LINESTRING (160 310, 160 280, 160 250, 170 230)',NULL) as geom from dual union all
           select sdo_geometry('LINESTRING (170 230, 180 210, 200 180, 220 160)',NULL) as geom from dual union all
           select sdo_geometry('LINESTRING (160 310, 200 330, 220 340, 240 360)',NULL) as geom from dual union all
           select sdo_geometry('LINESTRING (240 360, 260 390, 260 410, 250 430)',NULL) as geom from dual 
        ),3) as geom
  from dual;
  
-- ***********************************************************************************
-- St_HausdorffSimilarityMeasure, St_AreaSimilarityMeasure
-- ***********************************************************************************
--
-- Two similar lines
With data As (
  select MDSYS.SDO_GEOMETRY(2002, NULL, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1), MDSYS.SDO_ORDINATE_ARRAY(0,0, 10,10, 20,0, 30,30)) as line1,
         MDSYS.SDO_GEOMETRY(2002, NULL, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1), MDSYS.SDO_ORDINATE_ARRAY(0,0, 10.01,10, 20,0.1, 30,30.07)) as line2
    from dual
)
select &&DefaultSchema..SC4O.St_HausdorffSimilarityMeasure(line1,line2,3) as HSM,
       &&DefaultSchema..SC4O.St_AreaSimilarityMeasure(line1,line1,3)      as ASM
  from data;

-- Identical
With data As (
  select MDSYS.SDO_GEOMETRY(2003,NULL,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3),MDSYS.SDO_ORDINATE_ARRAY(100.0, 100.0, 500.0, 500.0)) as area1,
         MDSYS.SDO_GEOMETRY(2003,NULL,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(100,100,500,100,500,500,100,500,100,100)) as area2
    from dual
)
select &&DefaultSchema..SC4O.St_HausdorffSimilarityMeasure(area1,area2,3) as HSM,
       &&DefaultSchema..SC4O.St_AreaSimilarityMeasure(area1,area2,3)      as ASM
  from data;

-- Two nearly identical rectangles
With data As (
  select MDSYS.SDO_GEOMETRY(2003,NULL,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(100,100,500.00,100,500.00,500.00,100,500.00,100,100)) as area1,
         MDSYS.SDO_GEOMETRY(2003,NULL,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(100,100,500.01,100,500.01,500.01,100,500.01,100,100)) as area2
    from dual
)
select &&DefaultSchema..SC4O.St_HausdorffSimilarityMeasure(area1,area2,3) as HSM,
       &&DefaultSchema..SC4O.St_AreaSimilarityMeasure(area1,area2,3)      as ASM
  from data;

-- Rectangle and polygon near boundary
With data As (
  select SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(100,100,500.00,100,500.00,500.00,100,500.00,100,100)) as area1,
         SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(103.846,91.346, 509.615,91.346, 509.615,494.231, 103.846,494.231, 103.846,91.346)) as area2
    from dual
)
select &&DefaultSchema..SC4O.St_HausdorffSimilarityMeasure(area1,area2,3) as HSM,
       &&DefaultSchema..SC4O.St_AreaSimilarityMeasure(area1,area2,3)      as ASM
  from data;

-- Rectangle with small inner irregular shaped polygon
With data As (
  select SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(100,100,500.00,100,500.00,500.00,100,500.00,100,100)) as area1,
         SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(153.846,327.885, 156.731,279.808, 198.077,297.115, 236.538,233.654,264.423,188.462, 233.654,164.423, 285.577,136.538, 338.462,170.192,332.692,227.885, 374.038,263.462, 357.692,302.885, 281.731,351.923,254.808,326.923, 215.385,374.038, 180.769,363.462, 153.846,327.885)) as area2
    from dual
)
select &&DefaultSchema..SC4O.St_HausdorffSimilarityMeasure(area1,area2,3) as HSM,
       &&DefaultSchema..SC4O.St_AreaSimilarityMeasure(area1,area2,3)      as ASM,
       SC4O.ST_Area(area2,8)/SC4O.ST_Area(area1,8)                        as customMeasure
  from data;


-- ***********************************************************************************
-- ST_Area, ST_Length, ST_IsValid, ST_IsSimple, ST_Dimension, ST_CoordDim, ST_GeomFromText
-- ***********************************************************************************
--
With data As (
    select &&DefaultSchema..SC4O.ST_GeomFromText('POINT (10 5)',null) as geom from dual union all
    select &&DefaultSchema..SC4O.ST_GeomFromText('POINT (900 900 10)',null) as geom from dual union all
    select mdsys.sdo_geometry('LINESTRING (10 10, 20 10)',null) as geom from dual union all
    select mdsys.sdo_geometry('LINESTRING (100 100, 900 900)',null) as geom from dual union all
    select &&DefaultSchema..SC4O.ST_GeomFromText('LINESTRING (10 10 1, 20 10 2)',null) as geom from dual union all
    select &&DefaultSchema..SC4O.ST_GeomFromText('LINESTRING (10 25, 20 30, 25 25, 30 30)',null) as geom from dual union all
    select mdsys.sdo_geometry('LINESTRING (10 55, 15 55, 20 60, 10 60, 10 55)',null) as geom from dual union all
    select &&DefaultSchema..SC4O.ST_GeomFromText('LINESTRING (10 85, 20 90, 20 85, 10 90, 10 85)',null) as geom from dual union all
    select mdsys.sdo_geometry('POLYGON ((10 105, 15 105, 20 110, 10 110, 10 105))',null) as geom from dual union all
    select mdsys.sdo_geometry('POLYGON ((100 100, 500 100, 500 500, 100 500, 100 100))',null) as geom from dual union all
    select mdsys.sdo_geometry('POLYGON ((500 500, 1500 500, 1500 1500, 500 1500, 500 500), (600 750, 900 750, 900 1050, 600 1050, 600 750))',null) as geom from dual union all
    select &&DefaultSchema..SC4O.ST_GeomFromText('POLYGON ((50 135, 60 135, 60 140, 50 140, 50 135), (51 136, 59 136, 59 139, 51 139, 51 136))',null) as geom from dual union all
    select mdsys.sdo_geometry('POLYGON ((10 135, 20 135, 20 140, 10 140, 10 135))',null) as geom from dual union all
    select &&DefaultSchema..SC4O.ST_GeomFromText('MULTIPOINT ((50 5), (55 7), (60 5))',null) as geom from dual union all
    select mdsys.sdo_geometry('MULTIPOINT ((65 5))',null) as geom from dual union all
    select mdsys.sdo_geometry('MULTIPOINT ((100 100), (900 900))',null) as geom from dual union all
    select mdsys.sdo_geometry('MULTILINESTRING ((50 15, 55 15), (60 15, 65 15))',null) as geom from dual union all
    select &&DefaultSchema..SC4O.ST_GeomFromText('MULTILINESTRING ((50 22, 60 22), (55 20, 55 25))',null) as geom from dual union all
    select mdsys.sdo_geometry('MULTILINESTRING ((50 55, 50 60, 55 58, 50 55), (56 58, 60 55, 60 60, 56 58))',null) as geom from dual union all
    select mdsys.sdo_geometry('MULTIPOLYGON (((50 105, 55 105, 60 110, 50 110, 50 105)), ((62 108, 65 108, 65 112, 62 112, 62 108)))',null) as geom from dual union all
    select &&DefaultSchema..SC4O.ST_GeomFromText('MULTIPOLYGON (((50 115, 55 115, 55 120, 50 120, 50 115)), ((55 120, 58 120, 58 122, 55 122, 55 120)))',null) as geom from dual union all
    select mdsys.sdo_geometry('MULTIPOLYGON (((50 95, 55 95, 53 96, 55 97, 53 98, 55 99, 50 99, 50 95)), ((55 100, 55 95, 60 95, 60 100, 55 100)))',null) as geom from dual union all
    select mdsys.sdo_geometry('MULTIPOLYGON (((50 168, 50 160, 55 160, 55 168, 50 168), (51 167, 54 167, 54 161, 51 161, 51 162, 52 163, 51 164, 51 165, 51 166, 51 167)), ((52 166, 52 162, 53 162, 53 166, 52 166)))',null) as geom from dual union all
    select mdsys.sdo_geometry('MULTIPOLYGON (((1500 100, 1900 100, 1900 500, 1500 500, 1500 100)), ((1900 500, 2300 500, 2300 900, 1900 900, 1900 500)))',null) as geom from dual 
)
select distinct 
       case when a.geom.get_gtype() in (1) then 'Point' 
            when a.geom.get_gtype() in (5) then 'MultiPoint' 
            when a.geom.get_gtype() in (2) then 'Line' 
            when a.geom.get_gtype() in (6) then 'MultiLine' 
            when a.geom.get_gtype() in (3) then 'Area' 
            when a.geom.get_gtype() in (7) then 'MultiArea' 
            else 'Not Supported'
        end geometryType,
       round(&&DefaultSchema..SC4O.ST_area(a.geom,3),3) as area, 
       round(sdo_geom.sdo_area(a.geom,0.0005),3) as areaSDO, 
       round(&&DefaultSchema..SC4O.ST_length(a.geom,3),3) as len, 
       round(sdo_geom.sdo_length(a.geom,0.0005),3) as lenSDO, 
       &&DefaultSchema..SC4O.ST_IsValid(a.geom) as isValid,
       &&DefaultSchema..SC4O.ST_IsSimple(a.geom) as isSimple,
       &&DefaultSchema..SC4O.ST_Dimension(a.geom) as Dimension,
       &&DefaultSchema..SC4O.ST_CoordDim(a.geom) as coordDim
  from data a
order by 1,2,4;

-- ***********************************************************************************
-- ST_Buffer
-- ***********************************************************************************
--
-- No Geometry
--
select &&DefaultSchema..SC4O.ST_Buffer(NULL,100.0,1) as polygon
  from dual;
  
-- 1. 15m Buffer with _Round_ End Cap and Join Style*
select &&DefaultSchema..SC4O.ST_Buffer(
                   mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(20,1,50,50,100,0,150,50)),15.0,2,
                   1 /*CAP_ROUND*/,
                   1 /*JOIN_ROUND*/,
                   8 /*QUADRANT_SEGMENTS*/
       ) as buf 
  from dual;
  
-- 2. 15m Buffer with _SQUARE_ End Cap and ROUND Join Style*
select &&DefaultSchema..SC4O.ST_Buffer(
                   mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(20,1,50,50,100,0,150,50)),15.0,2,
                   3 /*CAP_SQUARE*/,
                   1 /*JOIN_ROUND*/,
                   8 /*QUADRANT_SEGMENTS*/
       ) as buf 
  from dual;

-- 3. 15m Buffer with _BUTT_ End Cap and _ROUND_ Join Style*
select &&DefaultSchema..SC4O.ST_Buffer(
                   mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(20,1,50,50,100,0,150,50)),15.0,2,
                   2 /*CAP_BUTT*/,
                   1 /*JOIN_ROUND*/,
                   8 /*QUADRANT_SEGMENTS*/
       ) as buf 
  from dual;

-- 4. 15m Buffer with _BUTT_ End Cap and _MITRE_ Join Style*
select &&DefaultSchema..SC4O.ST_Buffer(
                   mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(20,1,50,50,100,0,150,50)),15.0,2,
                   2 /*CAP_BUTT*/,
                   2 /*JOIN_MITRE*/,
                   8 /*QUADRANT_SEGMENTS*/
       ) as buf 
  from dual;

-- 5. 15m Buffer with _BUTT_ End Cap and _BEVEL_ Join Style*
select &&DefaultSchema..SC4O.ST_Buffer(
                   mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(20,1,50,50,100,0,150,50)),15.0,2,
                   2 /*CAP_BUTT*/,
                   3 /*JOIN_BEVEL*/,
                   8 /*QUADRANT_SEGMENTS*/
       ) as buf 
  from dual;

-- 6. Simple Bent Line Buffered Left and Right Side by 15m.
select &&DefaultSchema..SC4O.ST_Buffer(
                   line,
                   b.left_right_distance,
                   2,
                   1,
                   c.join_type,
                   8
       ) as buf 
  from (select mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(20,1,50,50,100,0,150,50)) as line 
          from dual
       ) a,
       (select case when level = 1 then -15.0 else 15.0 end as left_right_distance from dual connect by level < 3) b,
       (select level as join_type from dual connect by level < 4) c;

-- **********************
-- ST_OneSidedBuffer

select SC4O.ST_OneSidedBuffer(line,b.left_right_distance,2,c.cap_join,c.cap_join,8) as buf
  from (select mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(20,1,50,50,100,0,150,50)) as line
          from dual
       ) a,
       (select case when level = 1 then -15.0 else 15.0 end as left_right_distance from dual connect by level < 3) b,
       (select LEVEL as cap_Join from dual connect by level <=3) c;

-- ***********************************************************************************
-- ST_Union, ST_Intersection, ST_XOR, ST_Difference, ST_Round
-- ***********************************************************************************

-- Union of two points
With data as (
  select MDSYS.SDO_GEOMETRY(2001, 32639, MDSYS.SDO_POINT_TYPE(548810.44489, 3956383.07564,NULL),NULL,NULL) g1,
         MDSYS.SDO_GEOMETRY(2001, 32639, MDSYS.SDO_POINT_TYPE(548766.398, 3956415.329,NULL), NULL, NULL) g2 
    from dual
)
select CAST('JTS' as varchar2(3)) as codebase, &&DefaultSchema..SC4O.ST_Round(&&DefaultSchema..SC4O.ST_Union(g1,g2,1),1) as GeoProcess from data union all
select      'SDO'                 as codebase, &&DefaultSchema..SC4O.ST_Round(sdo_geom.sdo_union(g1,g2,0.05),1)  from data;

-- Two linestrings
With data as (
  select SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(5,10, 5,5, 10,5)) g1,
         SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(10,5, 10,10, 5,10)) g2 
    from dual
)
select CAST('JTS' as varchar2(3)) as codebase, &DefaultSchema..SC4O.ST_Union(g1,g2,1) as GeoProcess from data union all
select      'SDO'                 as codebase, sdo_geom.sdo_union(g1,g2,0.05)  from data;


-- Polygon tests
--
with data As (
  select mdsys.sdo_geometry(2003,82469,NULL,sdo_elem_info_array(1,1003,3),sdo_ordinate_array(1,1,10,10)) as geom1,
         mdsys.sdo_geometry(2003,82469,NULL,sdo_elem_info_array(1,1003,3),sdo_ordinate_array(5,5,15,15)) as geom2 
  from dual
)
select 'UNION' as gtype,        &&DefaultSchema..SC4O.ST_Union(a.geom1,a.geom2,1)         as rGeom from data a union all
select 'INTERSECTION' as gtype, &&DefaultSchema..SC4O.ST_intersection(a.geom1,a.geom2,1)  as iGeom from data a union all
select 'XOR' as gtype,          &&DefaultSchema..SC4O.ST_XOr(a.geom1,a.geom2,1)           as xGeom from data a union all
select 'SYMDIFFERENCE' as gtype,&&DefaultSchema..SC4O.ST_SymDifference(a.geom1,a.geom2,1) as xGeom from data a union all
select 'DIFFERENCE' as gtype,   &&DefaultSchema..SC4O.ST_Difference(a.geom1,a.geom2,1)    as dGeom from data a;

-- ************************************************************************************************
-- Coordinate rounding ...
With data as (
  select MDSYS.SDO_GEOMETRY(2001, 32639, MDSYS.SDO_POINT_TYPE(548810.44489, 3956383.07564,NULL),NULL,NULL) g1,
         MDSYS.SDO_GEOMETRY(2001, 32639, MDSYS.SDO_POINT_TYPE(548766.398, 3956415.329,NULL), NULL, NULL) g2 
    from dual
)
select sdo_geom.relate(&&DefaultSchema..SC4O.ST_Round(&&DefaultSchema..SC4O.ST_Union(g1,g2,1),1),
                       'DETERMINE',
                       &&DefaultSchema..SC4O.ST_Round(sdo_geom.sdo_union(g1,g2,0.05),1),
                       0.05) as compare
  from data;

-- Intersection of mixed objects ...
-- 1. A point and a line
With data as (
  select MDSYS.SDO_GEOMETRY(2002, 32639, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1), MDSYS.SDO_ORDINATE_ARRAY(548766.398, 3956415.329, 548866.753, 3956341.844, 548845.366, 3956342.941)) g1,
         MDSYS.SDO_GEOMETRY(2001, 32639, MDSYS.SDO_POINT_TYPE(548766.398, 3956415.329,NULL), NULL, NULL) g2
    from dual
)
select &&DefaultSchema..SC4O.ST_Round(&&DefaultSchema..SC4O.ST_Intersection(g1,g2,1),1) as GeoProcess,
       &&DefaultSchema..SC4O.ST_Round(sdo_geom.sdo_intersection(g1,g2,0.05),1) as Oracle
  from data;

-- 2. Two crossing lines
With data as (
  select MDSYS.SDO_GEOMETRY(2002, 32639, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1), MDSYS.SDO_ORDINATE_ARRAY(548938.421,3956363.864,548823.852,3956379.758,548818.010,3956381.297,548812.139,3956382.844,548683.715,3956400.404)) g1,
         MDSYS.SDO_GEOMETRY(2002, 32639, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1), MDSYS.SDO_ORDINATE_ARRAY(548766.398,3956415.329,548866.753,3956341.844,548845.366,3956342.941)) g2
    from dual
)
select &&DefaultSchema..SC4O.ST_Round(&&DefaultSchema..SC4O.ST_Intersection(g1,g2,1),1) as GeoProcess, 
       &&DefaultSchema..SC4O.ST_Round(sdo_geom.sdo_intersection(g1,g2,0.05),1) as Oracle
  from data;
          
-- 3. A line and a polygon
With data as (
  select MDSYS.SDO_GEOMETRY(2003, 32639, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1), MDSYS.SDO_ORDINATE_ARRAY(548862.366, 3956401.619, 548793.269, 3956409.845, 548785.043, 3956369.812, 548850.302, 3956361.587, 548862.366, 3956401.619)) g1,
         MDSYS.SDO_GEOMETRY(2002, 32639, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1), MDSYS.SDO_ORDINATE_ARRAY(548766.398, 3956415.329, 548866.753, 3956341.844, 548845.366, 3956342.941)) g2
    from dual
)
select &&DefaultSchema..SC4O.ST_Round(&&DefaultSchema..SC4O.ST_Intersection(g1,g2,1),1) as GeoProcess, 
       &&DefaultSchema..SC4O.ST_Round(sdo_geom.sdo_intersection(g1,g2,0.05),1) as Oracle
  from data;
          
-- 4. A Point and polygon
With data as (
  select mdsys.sdo_geometry (2001, NULL, NULL, SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY (13,106)) g1,
         mdsys.sdo_geometry (2003, NULL, NULL, SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY (10,105, 15,105, 20,110, 10,110, 10,105)) g2
    from dual
)
select &&DefaultSchema..SC4O.ST_Round(&&DefaultSchema..SC4O.ST_Intersection(g1,g2,1),1) as GeoProcess, 
       &&DefaultSchema..SC4O.ST_Round(sdo_geom.sdo_intersection(g1,g2,0.05),1) as Oracle
  from data;

-- ***********************************************************************************
-- ST_RELATE
-- ***********************************************************************************

With data as (
  select CAST('No Interaction' as varchar2(25)) as testType, 
         SDO_GEOMETRY(2001,32639,SDO_POINT_TYPE(548810.44489, 3956383.07564,NULL),NULL,NULL) g1,
         SDO_GEOMETRY(2001,32639,SDO_POINT_TYPE(548766.398, 3956415.329,NULL), NULL, NULL) g2 
    from dual union all
  select 'Two crossing lines' as testType,
         SDO_GEOMETRY(2002,32639,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(548938.421,3956363.864,548823.852,3956379.758,548818.010,3956381.297,548812.139,3956382.844,548683.715,3956400.404)) g1,
         SDO_GEOMETRY(2002,32639,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(548766.398,3956415.329,548866.753,3956341.844,548845.366,3956342.941)) g2
    from dual union all
  select 'A line and a polygon' as testType, 
         SDO_GEOMETRY(2003,32639,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(548862.366, 3956401.619, 548793.269, 3956409.845, 548785.043, 3956369.812, 548850.302, 3956361.587, 548862.366, 3956401.619)) g1,
         SDO_GEOMETRY(2002,32639,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(548766.398, 3956415.329, 548866.753, 3956341.844, 548845.366, 3956342.941)) g2
    from dual
)
select testType,
       sdo_geom.relate(g1,'DETERMINE',g2,0.05) as sdoRelate, 
       SC4O.ST_Relate(g1,'DETERMINE',g2,1)     as jtsRelate
  from data;


-- ***********************************************************************************
-- ST_MinimumBoundingCircle
-- ***********************************************************************************
select '1. Point is returned as is'    as msg, &&DefaultSchema..SC4O.ST_MinimumBoundingCircle(sdo_geometry(2001,null,sdo_point_type(1,1,null),null,null),2) as mbc from dual union all
select '2. Two point straight line'    as msg, &&DefaultSchema..SC4O.ST_MinimumBoundingCircle(sdo_geometry('MULTIPOINT ((10 10), (20 20))',0),2) as mbc  from dual union all
select '3. Three Points In Line'       as msg, &&DefaultSchema..SC4O.ST_MinimumBoundingCircle(sdo_geometry('MULTIPOINT ((10 10), (20 20), (30 30))',0),2) as mbc  from dual union all
select '4. Three points'               as msg, &&DefaultSchema..SC4O.ST_MinimumBoundingCircle(sdo_geometry('MULTIPOINT ((10 10), (20 20), (10 20))',0),2) as mbc  from dual union all
select '5. Triangle With Middle Point' as msg, &&DefaultSchema..SC4O.ST_MinimumBoundingCircle(sdo_geometry('MULTIPOINT ((10 10), (20 20), (10 20), (15 19))',0),2) as mbc from dual union all
select '6. Linestring'                 as msg, &&DefaultSchema..SC4O.ST_MinimumBoundingCircle(mdsys.sdo_geometry('LINESTRING(0 0, 10 10, 10 0, 20 10)',0),2) as dGeom from dual union all
select '7. Optimized Rectangle'        as msg, &&DefaultSchema..SC4O.ST_MinimumBoundingCircle(mdsys.sdo_geometry(2003,null,null,sdo_elem_info_array(1,1003,3),sdo_ordinate_array(1,1,10,10)),2) as dGeom from dual;

-- ***********************************************************************************
-- ST_PolygonBuilder
-- ***********************************************************************************
--
-- 1. No result set
select &&DefaultSchema..SC4O.ST_Polygonbuilder(CAST(NULL as mdsys.sdo_geometry_array),1) as polygon
  from dual;

-- 2. Result set with no mdsys.sdo_geometry
select &&DefaultSchema..SC4O.ST_Polygonbuilder(CURSOR(SELECT * FROM DUAL),1) as polygon
  from dual;

-- 3. Empty result set
select &&DefaultSchema..SC4O.ST_Polygonbuilder(CURSOR(select mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,10,10)) as geom from dual where rownum < 1),1) as polygon
  from dual;
  
-- 4. Result set with one linestring
select &&DefaultSchema..SC4O.ST_Polygonbuilder(CURSOR(select mdsys.sdo_geometry(2002,82469,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,10,10)) as geom from dual),1) as polygon
  from dual;
  
-- 5. From a resultSet containing lines
set serveroutput on size unlimited
declare
  v_lines    SC4O.refcur_t;
  v_geometry mdsys.sdo_geometry;
begin
   open v_lines for select mdsys.sdo_geometry('LINESTRING (1.0 1.0, 10.0 1.0)') as line from dual union all
                    select mdsys.sdo_geometry('LINESTRING (10.0 1.0, 10.0 10.0)') as line from dual union all
                    select mdsys.sdo_geometry('LINESTRING (10.0 10.0, 1.0 10.0)') as line from dual union all
                    select mdsys.sdo_geometry('LINESTRING (1.0 10.0, 1.0 1.0)') as line from dual;
   v_geometry := SC4O.ST_PolygonBuilder(v_lines,1);
   dbms_output.put_line('Geometry:' || 
                        case when v_geometry is null then 'NULL' 
                             else ' Type: ' || to_char(v_geometry.sdo_gtype) || 
                                  ' numPoints: ' || mdsys.sdo_util.GETNUMVERTICES(v_geometry) ||
                                  ' WKT: ' || v_geometry.get_wkt()
                         end);
end;
/

-- From geometryCollection
select &&DefaultSchema..SC4O.ST_PolygonBuilder(SDO_GEOMETRY(2004,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1, 5,2,1, 9,2,1, 13,2,1),SDO_ORDINATE_ARRAY(1.0,1.0, 10.0,1.0, 10.0,1.0, 10.0,10.0, 10.0,10.0, 1.0,10.0, 1.0,10.0, 1.0,1.0)),1) as geom
  from dual;

-- 6. Create polygon from COLLECTion of lines 
With data As (
  select cast(
             multiset(
               select mdsys.sdo_geometry('LINESTRING (1.0 1.0, 10.0 1.0)')   as line from dual union all
               select mdsys.sdo_geometry('LINESTRING (10.0 1.0, 10.0 10.0)') as line from dual union all
               select mdsys.sdo_geometry('LINESTRING (10.0 10.0, 1.0 10.0)') as line from dual union all
               select mdsys.sdo_geometry('LINESTRING (1.0 10.0, 1.0 1.0)')   as line from dual
             ) as mdsys.sdo_geometry_array
           ) as mLines
  from dual
)
select f.geom.get_wkt() as geomWKT,
       sdo_util.getNumElem(f.geom)     as numElems, 
       sdo_util.getNumVertices(f.geom) as numVertices 
  from (select rownum as Id, 
               &&DefaultSchema..SC4O.ST_PolygonBuilder(s.mlines,1) as geom
          from data s
        ) f;

-- 7. Create polygon from CURSOR containing lines 
select &&DefaultSchema..SC4O.ST_Polygonbuilder(CURSOR(
                    select sdo_geometry('LINESTRING (1.0 1.0, 10.0 1.0)')   as line from dual union all
                    select sdo_geometry('LINESTRING (10.0 1.0, 10.0 10.0)') as line from dual union all
                    select sdo_geometry('LINESTRING (10.0 10.0, 1.0 10.0)') as line from dual union all
                    select sdo_geometry('LINESTRING (1.0 10.0, 1.0 1.0)')   as line from dual
                  ),1) as polygon
  from dual;

-- ST_NodeLineStrings (cursor)
select SC4O.ST_NodeLineStrings(
         CURSOR(select sdo_geometry('LINESTRING ( 0.0  0.0,  11.0  0.0)') as line from dual union all
                select sdo_geometry('LINESTRING ( 1.0 -1.0,   1.0 11.0)') as line from dual union all
                select sdo_geometry('LINESTRING ( 0.0 10.0,  11.0 10.0)') as line from dual union all
                select sdo_geometry('LINESTRING (10.0 -1.0,  10.0 11.0)') as line from dual
               ),
         2
       ) as nLines
  from dual;


-- ST_NodeLinestrings (sdo_geometry_array)
select SC4O.ST_NodeLineStrings(
         cast(
             multiset(
               select sdo_geometry('LINESTRING ( 0.0  0.0,  11.0  0.0)') as line from dual union all
               select sdo_geometry('LINESTRING ( 1.0 -1.0,   1.0 11.0)') as line from dual union all
               select sdo_geometry('LINESTRING ( 0.0 10.0,  11.0 10.0)') as line from dual union all
               select sdo_geometry('LINESTRING (10.0 -1.0,  10.0 11.0)') as line from dual
             ) as sdo_geometry_array
           ),
           2
       ) as nLines
  from dual;

-- ST_NodeLineStrings (GeoemtryCollection)
select SC4O.ST_NodeLineStrings(SDO_GEOMETRY(2004,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1,5,2,1,9,2,1,13,2,1),SDO_ORDINATE_ARRAY(0,0,11,0,1,-1,1,11,0,10,11,10,10,-1,10,11)),2) as nLines
  from dual;


-- ***********************************************************************************
-- ST_Snap
-- ***********************************************************************************
--
-- 1. Snap line to line ...
with data as (
   select SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0.2,0.4,9.8,10.5,19.7,-0.2,30.2,9.6)) as geom1,
          SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,10,10,20,0,30,10)) as snapGeom
     from dual
)
select &&DefaultSchema..SC4O.ST_Snap(
          p_geom1        =>geom1,
          p_geom2        =>snapgeom,
          p_snapTolerance=>1.0,
          p_precision    =>3) as SnappedLines
  from data;

-- 2. Snap first line to second
with data as (
   select SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0.2,0.4,9.8,10.5,19.7,-0.2,30.2,9.6)) as line1,
          SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,10,10,20,0,30,10)) as snapGeom
     from dual
)
select &&DefaultSchema..SC4O.ST_SnapTo(
          p_geom1        =>line1,
          p_snapGeom     =>snapgeom,
          p_snapTolerance=>1.0,
          p_precision    =>3) as SnappedLine
  from data;

-- 3. Snap point to area
with data as (
select SDO_GEOMETRY(2001,NULL,SDO_POINT_TYPE(-7.091,1.347,NULL),NULL,NULL) as point,
       SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(-8.369,14.803,-8.191,8.673,-8.072,0.400,5.737,0.400,5.142,14.922,-8.369,14.803)) as snapGeom 
  from dual
)
select &&DefaultSchema..SC4O.ST_SnapTo(
          p_geom1        =>point,
          p_snapGeom     =>snapgeom,
          p_snapTolerance=>2.0,
          p_precision    =>3) as SnappedPoint
  from data;

-- 4. Snap a line to an area
with data as (
select SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(-8.339,-1.553,-8.682,8.496,-8.476,16.728)) as line,
       SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(-8.369,14.803,-8.191,8.673,-8.072,0.400,5.737,0.400,5.142,14.922,-8.369,14.803)) as snapGeom 
  from dual
)
select &&DefaultSchema..SC4O.ST_SnapTo(
          p_geom1        =>line,
          p_snapGeom     =>snapgeom,
          p_snapTolerance=>0.75,
          p_precision    =>3) as SnappedLine
  from data;

-- 5. Snap one area to another 
with data as (
select SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(-24.089,0.348,-8.339,0.553,-8.682,8.496,-8.476,14.728,-24.020,14.522,-24.089,0.348)) as poly,
       SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(-8.369,14.803,-8.191,8.673,-8.072,0.400,5.737,0.400,5.142,14.922,-8.369,14.803)) as snapPoly 
  from dual
)
select &&DefaultSchema..SC4O.ST_SnapTo(
          p_geom1        =>poly,
          p_snapGeom     =>snapPoly,
          p_snapTolerance=>0.75,
          p_precision    =>3) as snappedPoly
  from data;

-- 6. Snap line to itself
with data as (
   select SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),
                       SDO_ORDINATE_ARRAY(0.261,0.436,9.689,10.589,19.696,0.216,30.139,9.719,22.307,11.822,19.720,0.246,17.303,14.65,9.702,10.542,-3.292,12.547)
          ) as line
     from dual
)
select &&DefaultSchema..SC4O.ST_SnapToSelf(
          p_geom         =>line,
          p_snapTolerance=>1.0,
          p_precision    =>1) as SnappedLine
  from data;

-- ST_Round
select SC4O.ST_Round(
            SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),
                         SDO_ORDINATE_ARRAY(0.261,0.436,9.689,10.589,19.696,0.216,30.139,9.719,22.307,11.822,19.720,0.246,17.303,14.65,9.702,10.542,-3.292,12.547)
            ),
            2
          ) as line
     from dual;
  
-- ***********************************************************************************
-- ST_Centroid, ST_ConvexHull, ST_Envelope
-- ***********************************************************************************
--
select 'ORIGINAL' as method, &&DefaultSchema..SC4O.ST_AsText(mdsys.sdo_geometry('POLYGON ((-0.93 -0.17, -0.75 -0.22, -0.14 0.22, -0.34 -0.17, 0.33 0.05, 0.87 -0.34, 0.97 0.3, -0.15 0.97, -0.93 -0.17))')) as geom 
  from dual union all
select 'JCENTROID' as method, &&DefaultSchema..SC4O.ST_AsText(&&DefaultSchema..SC4O.ST_Centroid(sdo_geometry('POLYGON ((-0.93 -0.17, -0.75 -0.22, -0.14 0.22, -0.34 -0.17, 0.33 0.05, 0.87 -0.34, 0.97 0.3, -0.15 0.97, -0.93 -0.17))'),3,1)) as geom 
  from dual union all
select 'OCENTROID' as method, &&DefaultSchema..SC4O.ST_AsText(sdo_geom.sdo_centroid(sdo_geometry('POLYGON ((-0.93 -0.17, -0.75 -0.22, -0.14 0.22, -0.34 -0.17, 0.33 0.05, 0.87 -0.34, 0.97 0.3, -0.15 0.97, -0.93 -0.17))'),0.005)) as geom 
  from dual union all
select 'JCONVEXH'  as method, &&DefaultSchema..SC4O.ST_AsText(&&DefaultSchema..SC4O.ST_ConvexHull(sdo_geometry('POLYGON ((-0.93 -0.17, -0.75 -0.22, -0.14 0.22, -0.34 -0.17, 0.33 0.05, 0.87 -0.34, 0.97 0.3, -0.15 0.97, -0.93 -0.17))'),3)) as geom 
  from dual union all
select 'JENVELOP'  as method, &&DefaultSchema..SC4O.ST_AsText(&&DefaultSchema..SC4O.ST_Envelope(sdo_geometry('POLYGON ((-0.93 -0.17, -0.75 -0.22, -0.14 0.22, -0.34 -0.17, 0.33 0.05, 0.87 -0.34, 0.97 0.3, -0.15 0.97, -0.93 -0.17))'),3))   as geom 
  from dual;
--select 'PCENTROID' as method, &&DefaultSchema..centroid.sdo_centroid(sdo_geometry('POLYGON ((-0.93 -0.17, -0.75 -0.22, -0.14 0.22, -0.34 -0.17, 0.33 0.05, 0.87 -0.34, 0.97 0.3, -0.15 0.97, -0.93 -0.17))'),1,1,3,3,2) as geom from dual union all

-- ***********************************************************************************
-- ST_GeomFromText, ST_GeomFromEWKT, ST_AsEWKT, ST_AsText
-- ***********************************************************************************
--
-- 1. FROM POINT EMPTY 
select &&DefaultSchema..SC4O.ST_GeomFromText('POINT EMPTY') as point
  from dual;

-- 2. FROM BBOX 
select &&DefaultSchema..SC4O.ST_GeomFromEWKT('BOX(-32 147, -33 148)',8307) as optRect
  from dual;

-- 3. Rectangle Polgon as EWKT 
select &&DefaultSchema..SC4O.ST_AsEWKT(sdo_geometry(2003,8307,null,sdo_elem_info_array(1,1003,3),sdo_ordinate_array(-32,147,-33,148))) as Box
  from dual;

-- 4. Rectangular Polgon from BOX EWKT 
select &&DefaultSchema..SC4O.ST_GeomFromText('BOX(-32 147, -33 148)') as optRect
  from dual;

-- 5. Geodetic Rectangular Polgon to WKT 
select &&DefaultSchema..SC4O.ST_AsText(sdo_geometry(2003,8307,null,sdo_elem_info_array(1,1003,3),sdo_ordinate_array(-32,147,-33,148))) as Box
  from dual;

-- 6. Polgon from EWKT with SRID encoded in EWKT.
select &&DefaultSchema..SC4O.ST_GeomFromEWKT('SRID=8307;POLYGON((-76.57418668270113 38.91891450597657 0, -76.57484114170074 38.91758725401061 0, -76.57661139965057 38.91881851059802 0, -76.57418668270113 38.91891450597657 0))') as geom
  from dual;

-- 7. Polygon Polgon from EWKT no SRID
select &&DefaultSchema..SC4O.ST_GeomFromEWKT('POLYGON((-76.57418668270113 38.91891450597657 0, -76.57484114170074 38.91758725401061 0, -76.57661139965057 38.91881851059802 0, -76.57418668270113 38.91891450597657 0))',8307) as geom
  from dual;

-- 8. Polygon Polgon from BOX EWKT with SRID parameters
With data as (
  select &&DefaultSchema..SC4O.ST_GeomFromEWKT('BOX(-32 147,-33 148)',8307) as Box
    from dual
)
select &&DefaultSchema..SC4O.ST_AsText(a.box) as text
  from data a;

select &&DefaultSchema..SC4O.ST_AsText(
            sdo_geometry(3003,null,null,sdo_elem_info_array(1,1003,1),
                         sdo_ordinate_array(-76.57418668270113,38.91891450597657,0, -76.57484114170074,38.91758725401061,0, -76.57661139965057,38.91881851059802,0, -76.57418668270113,38.91891450597657,0))) as wkt
from dual;

-- 8. Round Polygon and convert to EWKT 
select &&DefaultSchema..SC4O.ST_AsEWKT(
         &&DefaultSchema..SC4O.ST_Round(
         mdsys.sdo_geometry(3003,8307,NULL,sdo_elem_info_array(1,1003,1),
                            sdo_ordinate_array(-76.5741866827011,38.9189145059766,0,-76.5766113996506,38.918818510598,0,-76.5748411417007,38.9175872540106,0,-76.5741866827011,38.9189145059766,0)),
       8)
       ) as text
from dual;

-- 8. Polygon to GML 
COLUMN GML FORMAT A300
With data As (
  select mdsys.sdo_geometry(2003,81989,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(600000.0,300000.0, 601000.0,300000.0, 601000.0,301000.0, 600000.0,301000.0, 600000.0,300000.0)) as geometry
    from dual 
)
select CAST('SC4OGML'   as varchar2(10)) as fn, &&defaultSchema..SC4O.ST_AsGML(geometry)   as GML from data union all
select CAST('SDOGML'    as varchar2(10)) as fn, mdsys.sdo_util.to_gmlgeometry(geometry)    as GML from data union all
select CAST('SDOGML311' as varchar2(10)) as fn, mdsys.sdo_util.to_gml311geometry(geometry) as GML from data a;

-- 9. Polygon from GML
With data As (
  select mdsys.sdo_geometry(2003,81989,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(600000.0,300000.0, 601000.0,300000.0, 601000.0,301000.0, 600000.0,301000.0, 600000.0,300000.0)) as geometry
    from dual 
)
select &&defaultSchema..SC4O.ST_GeomFromGML(
         &&defaultSchema..SC4O.ST_AsGML(geometry)
       ) as geom 
  from data ;

-- ************************************
-- Test ST_OffsetLine

select &&DefaultSchema..SC4O.ST_AsText(
          &&DefaultSchema..SC4O.ST_OffsetLine(
              sdo_geometry('LINESTRING (548845.366 3956342.941, 548866.753 3956341.844, 548766.398 3956415.329)',32639),
              -5.0,
              3,
              1, --SC4O.JOIN_ROUND,
              8  --SC4O.QUADRANT_SEGMENTS
           )
        ) as geom
  from data a;

-- *********************************************************
-- Test ST_LineDissolver
With data as (
  select sdo_geometry('LINESTRING (548845.37 3956342.94, 548840.24 3956243.07, 548861.63 3956241.98, 548881.28 3956242.9, 548900.36 3956247.66, 548918.14 3956256.06, 548933.94 3956267.77, 548947.13 3956282.36, 548957.22 3956299.24, 548963.81 3956317.77, 548966.65 3956337.23, 548965.62 3956356.87, 548960.77 3956375.93, 548952.28 3956393.67, 548940.48 3956409.4, 548925.83 3956422.53, 548825.48 3956496.01, 548766.4 3956415.33, 548866.75 3956341.84, 548845.37 3956342.94)',32639) as line1,
         sdo_geometry('LINESTRING (548845.366 3956342.941, 548866.753 3956341.844, 548766.398 3956415.329)',32639) as line2
    from dual
)
select &&DefaultSchema..SC4O.ST_AsText(
         &&DefaultSchema..SC4O.ST_LineDissolver(
             a.line1,
             a.line2,
             3,
             1
          )
       ) as geom
  from data a;

quit;


with data as (
  select mdsys.sdo_geometry (2001, NULL, sdo_point_type(50,5,null),null,null) as point from dual union all
  select mdsys.sdo_geometry (2001, NULL, sdo_point_type(55,7,null),null,null) as point from dual union all
  select mdsys.sdo_geometry (2001, NULL, sdo_point_type(60,5,null),null,null) as point from dual
)
select SC4O.ST_Collect(CAST(COLLECT(a.point) as mdsys.sdo_geometry_array),0) as geom
  from data a;

-- GEOM
-- -------------------------------------------------------------------------------------------------------
-- SDO_GEOMETRY(2004,28355,NULL,SDO_ELEM_INFO_ARRAY(1,1,1,3,1,1,5,1,1),SDO_ORDINATE_ARRAY(50,5,55,7,60,5))

with data as (
  select mdsys.sdo_geometry (2001, 28355, sdo_point_type(50,5,null),null,null) as point from dual union all
  select mdsys.sdo_geometry (2001, 28355, sdo_point_type(55,7,null),null,null) as point from dual union all
  select mdsys.sdo_geometry (2001, 28355, sdo_point_type(60,5,null),null,null) as point from dual
)
select SC4O.ST_Collect(CAST(COLLECT(a.point) as mdsys.sdo_geometry_array),1) as geom
  from data a

