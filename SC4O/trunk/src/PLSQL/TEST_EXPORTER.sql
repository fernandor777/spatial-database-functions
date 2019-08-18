Prompt Exporting Spreadsheet
declare
  mycur EXPORTER.refcur_t;
begin
  open mycur 
    for 
 'SELECT CAST(rownum as integer) as id,
         sdo_geometry(2001,4283,SDO_POINT_TYPE(ROUND(dbms_random.value(100,160),8),0-ROUND(dbms_random.value(0,50),8),NULL),NULL,NULL) as geom,
         CAST(case when round(dbms_random.value(0,1),0) = 0 then ''M'' else ''F'' end as char(1)) as sex,
         CAST(case when round(dbms_random.value(0,1),0) = 0 then ''M'' else ''I'' end as char(1)) as maturity,
         CAST(round(dbms_random.value(1,10),0)        as number(2))   as species,
         CAST(round(dbms_random.value(1,100),0)       as number(3))   as station_number,
         CAST(round(dbms_random.value(100,500),0)     as number(3))   as length,
         CAST(round(dbms_random.value(100.0,300.0),1) as Number(5,1)) as weight,
         TO_DATE(TO_CHAR(TO_DATE(TRUNC(DBMS_RANDOM.VALUE(2452641,2452641+364)),''J''),''YYYY-MM-DD'')||'' ''||TRUNC(DBMS_RANDOM.VALUE(0,23))||'':''||TRUNC(DBMS_RANDOM.VALUE(0,59))||'':''||TRUNC(DBMS_RANDOM.VALUE(0,59)),''YYYY-MM-DD HH24:MI:SS'') as obsn_date
    FROM DUAL
 CONNECT BY LEVEL <= 1000';
  EXPORTER.writeSpreadsheet(
    p_RefCursor        => myCur,
     p_outputDirectory => 'C:\temp\',
     p_fileName        => 'fishes',
     p_sheetName       => 'FishData',
     p_stratification  => EXPORTER.c_NO_STRATIFICATION,
     p_geomFormat      => EXPORTER.c_WKT,
     p_DateFormat      => EXPORTER.c_DATEFORMAT,
     p_TimeFormat      => EXPORTER.c_TIMEFORMAT,
     p_digits_of_precision => 7);
End;
/
SHOW ERRORS

-- ***********************************************************************************************
Prompt Exporting CSV File
declare
  mycur EXPORTER.refcur_t;
begin
  open mycur 
    for 
 'SELECT CAST(rownum as integer) as id,
         sdo_geometry(2001,4283,SDO_POINT_TYPE(ROUND(dbms_random.value(100,160),8),0-ROUND(dbms_random.value(0,50),8),NULL),NULL,NULL) as geom,
         CAST(case when round(dbms_random.value(0,1),0) = 0 then ''M'' else ''F'' end as char(1)) as sex,
         CAST(case when round(dbms_random.value(0,1),0) = 0 then ''M'' else ''I'' end as char(1)) as maturity,
         CAST(round(dbms_random.value(1,10),0)        as number(2))   as species,
         CAST(round(dbms_random.value(1,100),0)       as number(3))   as station_number,
         CAST(round(dbms_random.value(100,500),0)     as number(3))   as length,
         CAST(round(dbms_random.value(100.0,300.0),1) as Number(5,1)) as weight,
         TO_DATE(TO_CHAR(TO_DATE(TRUNC(DBMS_RANDOM.VALUE(2452641,2452641+364)),''J''),''YYYY-MM-DD'')||'' ''||TRUNC(DBMS_RANDOM.VALUE(0,23))||'':''||TRUNC(DBMS_RANDOM.VALUE(0,59))||'':''||TRUNC(DBMS_RANDOM.VALUE(0,59)),''YYYY-MM-DD HH24:MI:SS'') as obsn_date
    FROM DUAL
 CONNECT BY LEVEL <= 1000';
  EXPORTER.writeSpreadsheet(
     p_RefCursor       => myCur,
     p_outputDirectory => 'C:\temp\',
     p_fileName        => 'fishes',
     p_sheetName       => 'FishData',
     p_stratification  => EXPORTER.c_NO_STRATIFICATION,
     p_geomFormat      => EXPORTER.c_WKT,
     p_DateFormat      => EXPORTER.c_DATEFORMAT,
     p_TimeFormat      => EXPORTER.c_TIMEFORMAT,
     p_digits_of_precision => 7);
End;
/
SHOW ERRORS

-- *************************************************************************************
Prompt Exporting Delimited text file
Declare
  c_refcursor EXPORTER.refcur_t;
Begin
  OPEN c_refcursor 
   FOR 
    'SELECT rownum as id,
         CAST(round(dbms_random.value(1,10),0) as number(1)) as species,
         sdo_geometry(2001,4283,SDO_POINT_TYPE(ROUND(dbms_random.value(100,160),8),0-ROUND(dbms_random.value(0,50),8),NULL),NULL,NULL) as geom,
         CAST(round(dbms_random.value(1,100),0)       as number(3))     as station_number,
         CAST(round(dbms_random.value(100,500),0)     as number(3))  as length,
         CAST(round(dbms_random.value(100.0,300.0),1) as Number(5,1)) as weight,
         CAST(case when round(dbms_random.value(0,1),0) = 0 then ''M'' else ''F'' end as char(1)) as sex,
         CAST(case when round(dbms_random.value(0,1),0) = 0 then ''M'' else ''I'' end as char(1)) as maturity,
         TO_DATE(TO_CHAR(TO_DATE(TRUNC(DBMS_RANDOM.VALUE(2452641,2452641+364)),''J''),''YYYY-MM-DD'')||'' ''||TRUNC(DBMS_RANDOM.VALUE(0,23))||'':''||TRUNC(DBMS_RANDOM.VALUE(0,59))||'':''||TRUNC(DBMS_RANDOM.VALUE(0,59)),''YYYY-MM-DD HH24:MI:SS'') as obsn_date
    FROM DUAL
 CONNECT BY LEVEL <= 1000';
  EXPORTER.WriteTextFile(
     p_RefCursor           => c_refCursor,
     p_output_dir          => 'C:\temp\',
     p_file_name           => 'gutdata.csv',
     p_field_separator     => ',',
     p_Text_Delimiter      => '"',
     p_date_format         => 'yyyy/MM/dd hh:mm:ss a',
     p_geometry_format     => EXPORTER.c_WKT,
     p_digits_of_precision => 8
  );
End;
/
SHOW ERRORS
                          
-- ************************************************************************************************
Prompt Exporting KML file
Declare
  c_refcursor EXPORTER.refcur_t;
Begin
  OPEN c_refcursor 
   FOR 
    'SELECT rownum as id,
         CAST(round(dbms_random.value(1,10),0) as number(1)) as species,
         sdo_geometry(2001,4283,SDO_POINT_TYPE(ROUND(dbms_random.value(100,160),8),0-ROUND(dbms_random.value(0,50),8),NULL),NULL,NULL) as geom,
         CAST(round(dbms_random.value(1,100),0)       as number(3))  as station_number,
         CAST(round(dbms_random.value(100,500),0)     as number(3))  as length,
         CAST(round(dbms_random.value(100.0,300.0),1) as Number(5,1)) as weight,
         CAST(case when round(dbms_random.value(0,1),0) = 0 then ''M'' else ''F'' end as char(1)) as sex,
         CAST(case when round(dbms_random.value(0,1),0) = 0 then ''M'' else ''I'' end as char(1)) as maturity,
         TO_DATE(TO_CHAR(TO_DATE(TRUNC(DBMS_RANDOM.VALUE(2452641,2452641+364)),''J''),''YYYY-MM-DD'')||'' ''||TRUNC(DBMS_RANDOM.VALUE(0,23))||'':''||TRUNC(DBMS_RANDOM.VALUE(0,59))||'':''||TRUNC(DBMS_RANDOM.VALUE(0,59)),''YYYY-MM-DD HH24:MI:SS'') as obsn_date
    FROM DUAL
 CONNECT BY LEVEL <= 1000';
  EXPORTER.WriteKMLFile(  
     p_RefCursor           => c_refCursor,
     p_output_dir          => 'C:\temp\',
     p_file_name           => 'fishes.kml',
     p_geometry_name       => 'GEOM',
     p_date_format         => 'yyyy/MM/dd hh:mm:ss a',
     p_geometry_format     => EXPORTER.c_WKT,
     p_digits_of_precision => 8,
     p_commit              => 100
    );
End;
/
show errors

-- ************************************************************************************************
Prompt Exporting KML file
Declare
  c_refcursor EXPORTER.refcur_t;
Begin
  OPEN c_refcursor 
   FOR 
    'SELECT rownum as id,
         CAST(round(dbms_random.value(1,10),0) as number(1)) as species,
         sdo_geometry(2001,4283,SDO_POINT_TYPE(ROUND(dbms_random.value(100,160),8),0-ROUND(dbms_random.value(0,50),8),NULL),NULL,NULL) as geom,
         CAST(round(dbms_random.value(1,100),0)       as number(3))  as station_number,
         CAST(round(dbms_random.value(100,500),0)     as number(3))  as length,
         CAST(round(dbms_random.value(100.0,300.0),1) as Number(5,1)) as weight,
         CAST(case when round(dbms_random.value(0,1),0) = 0 then ''M'' else ''F'' end as char(1)) as sex,
         CAST(case when round(dbms_random.value(0,1),0) = 0 then ''M'' else ''I'' end as char(1)) as maturity,
         TO_DATE(TO_CHAR(TO_DATE(TRUNC(DBMS_RANDOM.VALUE(2452641,2452641+364)),''J''),''YYYY-MM-DD'')||'' ''||TRUNC(DBMS_RANDOM.VALUE(0,23))||'':''||TRUNC(DBMS_RANDOM.VALUE(0,59))||'':''||TRUNC(DBMS_RANDOM.VALUE(0,59)),''YYYY-MM-DD HH24:MI:SS'') as obsn_date
    FROM DUAL
 CONNECT BY LEVEL <= 1000';                           
  EXPORTER.WriteGMLFile(  
     p_RefCursor           => c_refCursor,
     p_output_dir          => 'C:\temp\',
     p_file_name           => 'fishes.gml',
     p_geometry_name       => 'GEOM',
     p_ring_orientation    => EXPORTER.c_Ring_Inverse,
     p_GML_version         => EXPORTER.c_GML3,
     p_geometry_format     => EXPORTER.c_WKT,
     p_digits_of_precision => 8,
     p_commit              => 100
    );
End;
/
show errors

-- ************************************************************************************************
-- Create, write shapefile all in one simple direct call
-- Note that one grants write permissions to the directory with \* on the end eg 'C:\Temp\*' 
-- but one writes to p_output_dir without the * eg 'C:\Temp\'.  
--
BEGIN
  EXPORTER.writeshapefile(
               p_sql                 => 'SELECT mdsys.sdo_geometry(3001,null,mdsys.sdo_point_type(1,2,3),null,null) as point, 232.32 as num FROM DUAL',
               p_output_dir          => 'C:\temp',
               p_file_name           => 'dual.shp',
               p_shape_type          => EXPORTER.c_Point_Z,
               p_geometry_name       => 'POINT',
               p_ring_orientation    => EXPORTER.c_Ring_Inverse,  -- Ignored if not polygon
               p_dbase_type          => EXPORTER.c_DBASEIII,
               p_geometry_format     => EXPORTER.c_WKT,
               p_prj_string          => NULL,
               p_digits_of_precision => 1,
               p_commit              => 10
        );
END;
/
SHOW ERRORS

declare
  mycur EXPORTER.refcur_t;
begin
  open mycur for 'SELECT rownum, 
                         mdsys.sdo_geometry(2001,4326,MDSYS.SDO_POINT_TYPE(ROUND(dbms_random.value(112,147),2),ROUND(dbms_random.value(-10,-44),2),NULL),NULL,NULL) as geom
                    FROM DUAL 
                 CONNECT BY LEVEL <= 500';
   EXPORTER.WriteShapefile(p_RefCursor           => myCur,
                           p_output_dir          => 'C:\temp',
                           p_file_name           => 'geopnt2d',
                           p_shape_type          => EXPORTER.c_Point,
                           p_geometry_name       => 'GEOM',
                           p_ring_orientation    => EXPORTER.c_Ring_Inverse,
                           p_dbase_type          => EXPORTER.c_DBASEIII,
                           p_geometry_format     => EXPORTER.c_WKT,
                           p_prj_string          => 'GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]]',
                           p_digits_of_precision => 6,
                           p_commit              => 100
   );
   -- WriteShapefile Function closes the refCursor after use.
end;
/
show errors

declare
  mycur EXPORTER.refcur_t;
begin
  open myCur for 'SELECT rownum as id,
             mdsys.sdo_geometry(2002,4326,NULL,
                   MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1),
                   MDSYS.SDO_ORDINATE_ARRAY(
                         ROUND(lon,6),
                         ROUND(lat,6),
                         ROUND(lon+dbms_random.value(0.1,1.0),6),
                         ROUND(lat+dbms_random.value(0.1,1.0),6)
                         )) as geom
       FROM (SELECT dbms_random.value(147,149) as lon,
                    dbms_random.value(-44,-42) as lat
               FROM DUAL)
     CONNECT BY LEVEL <= 500';
   EXPORTER.WriteShapefile(p_RefCursor           => myCur,
                           p_output_dir          => 'C:\temp',
                           p_file_name           => 'lines',
                           p_shape_type          => EXPORTER.c_LineString,
                           p_geometry_name       => 'GEOM',
                           p_ring_orientation    => EXPORTER.c_Ring_Inverse,
                           p_dbase_type          => EXPORTER.c_DBASEIII,
                           p_geometry_format     => EXPORTER.c_WKT,
                           p_prj_string          => 'GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]]',
                           p_digits_of_precision => 6,
                           p_commit              => 100
   );
   -- WriteShapefile Function closes the refCursor after use.
end;
/
show errors

declare
  mycur EXPORTER.refcur_t;
begin
  open mycur for 'SELECT rownum as id,
             mdsys.sdo_geometry(2003,4326,NULL,
                   MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3),
                   MDSYS.SDO_ORDINATE_ARRAY(
                         ROUND(lon,6),
                         ROUND(lat,6),
                         ROUND(lon+dbms_random.value(0.1,1.0),6),
                         ROUND(lat+dbms_random.value(0.1,1.0),6)
                         )) as geom
       FROM (SELECT dbms_random.value(147,149) as lon,
                    dbms_random.value(-44,-42) as lat
               FROM DUAL)
     CONNECT BY LEVEL <= 5000';
   EXPORTER.WriteShapefile(p_RefCursor           => myCur,
                           p_output_dir          => 'C:\temp',
                           p_file_name           => 'rectangles',
                           p_shape_type          => EXPORTER.c_Polygon,
                           p_geometry_name       => 'GEOM',
                           p_ring_orientation    => EXPORTER.c_Ring_Inverse,
                           p_dbase_type          => EXPORTER.c_DBASEIII,
                           p_geometry_format     => EXPORTER.c_WKT,
                           p_prj_string          => 'GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]]',
                           p_digits_of_precision => 6,
                           p_commit              => 100
   );
   -- WriteShapefile Function closes the refCursor after use.
end;
/
show errors

-- ************************************************************************************************
Prompt TAB File
declare
  mycur  EXPORTER.refcur_t;
begin
  open mycur for '
SELECT a.mi_prinx,
       ROUND(sdo_geom.sdo_area(a.geom,0.05,''unit=SQ_KM''),4) as area,
       a.geom
  FROM (SELECT rownum as mi_prinx,
               mdsys.sdo_geometry(2003,4326,NULL,
                     MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3),
                     MDSYS.SDO_ORDINATE_ARRAY(
                           ROUND(lon,6),
                           ROUND(lat,6),
                           ROUND(lon+dbms_random.value(0.1,1.0),6),
                           ROUND(lat+dbms_random.value(0.1,1.0),6)
                           )) as geom
         FROM (SELECT dbms_random.value(147,149) as lon,
                      dbms_random.value(-44,-42) as lat
                 FROM DUAL)
       CONNECT BY LEVEL <= 500
      ) a';      
   EXPORTER.WriteTabfile(p_RefCursor           => myCur,
                         p_output_dir          => 'C:\temp',
                         p_file_name           => 'rect',
                         p_shape_type          => EXPORTER.c_Polygon,
                         p_geometry_name       => 'GEOM',
                         p_ring_orientation    => EXPORTER.c_Ring_Inverse,
                         p_dbase_type          => EXPORTER.c_DBASEIII,
                         p_geometry_format     => EXPORTER.c_WKT,
                         p_coordsys            => 'CoordSys Earth Projection 1, 104',
                         p_symbolisation       => NULL,
                         p_digits_of_precision => 6,
                         p_commit              => 100
   );
   -- WriteTabfile Function closes the refCursor after use.
end;
/
show errors

-- ************************************************************************************************
-- Multi Table Export Test...
--
DROP   TABLE Point2D PURGE;
CREATE TABLE Point2D ( geom MDSYS.SDO_GEOMETRY );
INSERT INTO  Point2D VALUES( MDSYS.SDO_GEOMETRY(2001, NULL, MDSYS.SDO_POINT_TYPE(10,20,NULL),NULL,NULL));
COMMIT;

DROP   TABLE Line2D PURGE;
CREATE TABLE Line2D ( linetype varchar2(40), geom mdsys.sdo_geometry );
INSERT INTO  Line2D 
VALUES( 'VERTEX', mdsys.sdo_geometry(2002,NULL,NULL,
                        mdsys.sdo_elem_info_array(1,2,1,5,2,1),
                        mdsys.sdo_ordinate_array(0,0,21,0,21,0,21,21)));
INSERT INTO  Line2D 
VALUES( 'ARC', mdsys.sdo_geometry(2002,NULL,NULL,
                     mdsys.sdo_elem_info_array(1,2,2),
                     mdsys.sdo_ordinate_array(0,0,21,0,0,21)));
COMMIT;

DROP   TABLE Poly2D PURGE;
CREATE TABLE Poly2D ( polytype varchar2(40), geom mdsys.sdo_geometry );
INSERT INTO  Poly2D 
 VALUES ('VERTEXWITHHOLE',mdsys.sdo_geometry(2003,NULL,NULL,
                           mdsys.sdo_elem_info_array(1,1003,1,11,2003,1),
                           mdsys.sdo_ordinate_array(0,0,50,0,50,50,0,50,0,0,20,10,20,20,10,20,10,10,20,10)));
INSERT INTO  Poly2D 
 VALUES ('VERTEXMULTI', mdsys.sdo_geometry(2007,NULL,NULL,
                              MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1,11,1003,1),
                              mdsys.sdo_ordinate_array(0,0,100,0,100,100,0,100,0,0,
                                                       1000,1000,1100,1000,1100,1100,1000,1100,1000,1000)));
COMMIT;

PROMPT Export as TABFiles
BEGIN
  EXPORTER.EXPORTTABLES(
              p_tables       => EXPORTER.tablist_t('LINE2D','POLY2D','POINT2D'),
              p_output_dir   => 'C:\temp',
              p_mi_coordsys  => 'CoordSys NonEarth Units ""m""',
              p_mi_style     => NULL,
              p_prj_string   => NULL
  );
end;
/
show errors

DROP TABLE LINE2D  PURGE;
DROP TABLE POLY2D  PURGE;
DROP TABLE POINT2D PURGE;

exit;


