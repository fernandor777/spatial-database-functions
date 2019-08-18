declare
  c_parcel_ov  codesys.javageom.refcur_t;
begin
  open c_parcel_ov for 'SELECT FID,geom,AREA,GID,LOT_NUMBER,SECTION,DP_NUMBER,ID_PARCEL_TYPE as ID_PRCLTYP,LSTATUS,ASSET,ADMIN_CODE,ID_ORIGIN,ID_ACCURACY as ID_ACC,NOTE,DRAIN_DIAG,SEWER_CODE,LOT_ID,METER_ID,IDENTIFIER,LOCATION,NAME,OWNER,STR_NO,ADD1,ADD2,WATER_CODE,METER_NUMBER as METER_NUM,DOCS_LINK,LAND_TYPE,LOCALNAME FROM SP_PARCEL_OWNERVIEW';
  codesys.javageom.WriteTabfile( c_parcel_ov,
                                'E:\GIS_Downloads\MCW_GIS',
                                'parcel_ov',
                                codesys.javageom.c_Polygon,
                                2,
                               'CoordSys Earth Projection 8, 33, ""m"", 153, 0, 0.9996, 500000, 10000000');
end;

create or replace
Procedure ExportShapefile
As

  Cursor c_shapefile_list Is
    SELECT u.view_name,
           (select distinct column_name 
	      from user_tab_columns
             where table_name = u.view_name
	       and data_type = 'SDO_GEOMETRY')
             as geom_column
      FROM user_views u
     WHERE u.view_name like 'WATERCAD%';

  v_upper_shape varchar2(4000) := 'select case gtype 
            when 7 then ''multipolygon''
            when 6 then ''multilinestring''
            when 5 then ''multipoint''
            when 3 then ''polygon''
            when 2 then ''linestring''
            when 1 then ''point''
            else NULL
        end as shapetype
  from (select distinct mod(a.geometry.sdo_gtype,10) as gtype from ';
  v_lower_shape varchar2(4000) := ' a order by 1 desc) where rownum = 1';
  v_shape_type  varchar2(4000);

  Procedure DoExport(p_sql            in varchar2,
                     p_shape_filename in varchar2,
                     p_shape_type     in varchar2)
  As
    c_refcur codesys.javageom.refcur_t;
  Begin
    open c_refcur for p_sql;
    codesys.javageom.WriteTabfile( c_refcur,

create or replace
Procedure ExportShapefile
As

  v_posn number;
  v_upper_shape varchar2(4000) := 'select case gtype 
            when 7 then ''multipolygon''
            when 6 then ''multilinestring''
            when 5 then ''multipoint''
            when 3 then ''polygon''
            when 2 then ''linestring''
            when 1 then ''point''
            else NULL
        end as shapetype
  from (select distinct mod(a.geometry.sdo_gtype,10) as gtype from ';
  v_lower_shape varchar2(4000) := ' a order by 1 desc) where rownum = 1';
  v_shape_type  varchar2(4000);
  
  Cursor c_shapefile_list Is
    SELECT u.view_name,
           (select distinct column_name 
	      from user_tab_columns
             where table_name = u.view_name
	       and data_type = 'SDO_GEOMETRY')
             as geom_column
      FROM user_views u
     WHERE u.view_name like 'WATERCAD%';

  Procedure DoExport(p_sql            in varchar2,
                     p_shape_filename in varchar2,
                     p_shape_type     in varchar2)
  As
    c_refcur codesys.javageom.refcur_t;
  Begin
    open c_refcur for p_sql;
    codesys.javageom.WriteTabfile( c_refcur,
                                  'E:\GIS_Downloads\MCW_GIS',
                                  p_shape_filename,
                                  p_shape_type,
                                  NULL,
                                 'CoordSys Earth Projection 8, 33, ""m"", 153, 0, 0.9996, 500000, 10000000');
    EXCEPTION
       WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE(p_shape_filename || ' ' || SQLERRM);
  End DoExport;
  
begin
  for rec in c_shapefile_list loop
    execute immediate v_upper_shape || rec.view_name || v_lower_shape into v_shape_type;  
    select selposn
     into v_posn
     from (select rownum as selposn,column_name,data_type
             from (select column_name,data_type
                     from user_tab_columns
                    where table_name = rec.view_name
                   order by column_name
                  )
            )
   where data_type = 'SDO_GEOMETRY'
     and rownum = 1;
    DoExport('SELECT * FROM ' || rec.view_name,rec.view_name,v_shape_type);
  end loop;
end;

