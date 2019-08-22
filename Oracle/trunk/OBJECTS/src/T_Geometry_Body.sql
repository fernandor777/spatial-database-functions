DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

-- Always aim for a clean compile
ALTER SESSION SET PLSQL_WARNINGS='ERROR:ALL';
-- Enable optimizations
-- ALTER SESSION SET plsql_optimize_level=2;

CREATE OR REPLACE TYPE BODY &&INSTALL_SCHEMA..T_GEOMETRY
CREATE OR REPLACE TYPE BODY &&INSTALL_SCHEMA..T_GEOMETRY
AS

  Constructor Function T_GEOMETRY(SELF IN OUT NOCOPY T_GEOMETRY)
                Return Self As Result
  As
  Begin
    SELF.tolerance  := NULL;
    SELF.geom       := NULL;
    SELF.dPrecision := NULL;
    SELF.projected  := NULL;
    RETURN;
  End T_GEOMETRY;

  Constructor Function T_GEOMETRY(SELF   IN OUT NOCOPY T_GEOMETRY,
                                  p_geom IN mdsys.sdo_geometry)
                Return Self As Result
  As
  Begin
    SELF.tolerance := 0.005;
    SELF.geom      := p_geom;
    SELF.dPrecision := 3;
    SELF.projected := 1; -- 'PLANAR';
    RETURN;
  End T_GEOMETRY;

  Constructor Function T_GEOMETRY(SELF        IN OUT NOCOPY T_GEOMETRY,
                                  p_geom      in mdsys.sdo_geometry,
                                  p_tolerance in number)
                Return Self As Result
  As
  Begin
    SELF.tolerance := CASE WHEN NVL(p_tolerance,0.005) = 0 THEN 0.005 ELSE NVL(p_tolerance,0.005) END;
    SELF.geom      := p_geom; -- isValid needs tolerance
    SELF.dPrecision := ROUND(log(10,(1/SELF.tolerance)/2)) + 1;
    IF ( p_geom.sdo_srid is null ) THEN
      SELF.projected := 1; -- 'PLANAR';
    ELSE
      SELF.projected := case when &&INSTALL_SCHEMA..TOOLS.ST_GetSridType(p_srid=>p_geom.sdo_srid) = 'PLANAR' then 1 else 0 end;
    END IF;
    RETURN;
  End T_GEOMETRY;

  Constructor Function T_GEOMETRY(SELF        IN OUT NOCOPY T_GEOMETRY,
                                  p_geom      in mdsys.sdo_geometry,
                                  p_tolerance in number,
                                  p_dPrecision in integer)
                Return Self As Result
  As
  Begin
    SELF.tolerance := CASE WHEN NVL(p_tolerance,0.005) = 0 THEN 0.005 ELSE NVL(p_tolerance,0.005) END;
    SELF.geom      := p_geom; -- isValid needs tolerance
    SELF.dPrecision := NVL(p_dPrecision,(ROUND(log(10,(1/SELF.tolerance)/2)) + 1));
    IF ( p_geom.sdo_srid is null ) THEN
      SELF.projected := 1; -- 'PLANAR';
    ELSE
       SELF.projected := case when &&INSTALL_SCHEMA..TOOLS.ST_GetSridType(p_srid=>p_geom.sdo_srid) = 'PLANAR' then 1 else 0 end;
    END IF;
    RETURN;
  End T_GEOMETRY;

  Constructor Function T_GEOMETRY(SELF        IN OUT NOCOPY T_GEOMETRY,
                                  p_geom      in mdsys.sdo_geometry,
                                  p_tolerance in number,
                                  p_dPrecision in integer,
                                  p_projected in varchar2)
                Return Self As Result
  As
    c_i_projected    Constant Integer       := -20121;
    c_s_projected    Constant VarChar2(100) := 'project parameter can only be NULL, GEOGRAPHIC, PROJECTED or PLANAR).';
  Begin
    SELF.tolerance := CASE WHEN NVL(p_tolerance,0.005) = 0 THEN 0.005 ELSE NVL(p_tolerance,0.005) END;
    SELF.geom      := p_geom; -- isValid needs tolerance
    If ( NVL(p_projected,'PLANAR') not in ('GEOGRAPHIC','PROJECTED','PLANAR') ) Then
       raise_application_error(c_i_projected,c_s_projected,true);
    End If;
    SELF.dPrecision := NVL(p_dPrecision,
                          case when p_projected = 'GEOGRAPHIC'
                               then 9
                               else (ROUND(log(10,(1/SELF.tolerance)/2)) + 1)
                           end);
    SELF.projected := case when p_projected is null        then null
                           when p_projected = 'GEOGRAPHIC' then 0
                           when SELF.geom.sdo_srid is null 
                             or p_projected IN ('PROJECTED',
                                                'PLANAR')  then 1
                      end;
    RETURN;
  End T_GEOMETRY;

  Constructor Function T_GEOMETRY(SELF        IN OUT NOCOPY T_GEOMETRY,
                                  p_vertex    in mdsys.vertex_type,
                                  p_srid      in integer,
                                  p_tolerance in number default 0.005)
                Return Self As Result
  As
    /* Creates, at best, a 3D single point */
    c_i_empty_vertex  Constant Integer       := -20120;
    c_s_empty_vertex  Constant VarChar2(100) := 'Input vertex must not be null or empty';
  Begin
    SELF.tolerance := CASE WHEN NVL(p_tolerance,0.005) = 0 THEN 0.005 ELSE NVL(p_tolerance,0.005) END;
    SELF.dPrecision := ROUND(log(10,(1/SELF.tolerance)/2)) + 1;
    If ( p_vertex.x is null OR p_vertex.y is null ) THEN
       raise_application_error(c_i_empty_vertex,c_s_empty_vertex,true);
    End If;
    SELF.geom := mdsys.sdo_geometry(case when p_vertex.z is null then 2001 else 3001 end,
                                    p_srid,
                                    mdsys.sdo_point_type(p_vertex.x,p_vertex.y,p_vertex.z),
                                    NULL,NULL);
    IF ( SELF.geom.sdo_srid is null ) THEN
      SELF.projected := 1; -- 'PLANAR';
    ELSE
      SELF.projected := case when &&INSTALL_SCHEMA..TOOLS.ST_GetSridType(p_srid=>SELF.geom.sdo_srid) = 'PLANAR' then 1 else 0 end;
    END IF;
    RETURN;
  End T_GEOMETRY;

  Constructor Function T_GEOMETRY(SELF         IN OUT NOCOPY T_GEOMETRY,
                                  p_Segment in &&INSTALL_SCHEMA..T_Segment)
                Return Self As Result
  As
    /* Creates, at best, a 3D single point */
    c_i_empty_Segment Constant Integer       := -20120;
    c_s_empty_Segment Constant VarChar2(100) := 'Input segment must not be null or empty';
  Begin
    If ( p_Segment is null OR
         p_Segment.startCoord is null ) THEN
       raise_application_error(c_i_empty_Segment,c_s_empty_Segment,true);
    End If;
    SELF.geom       := p_segment.ST_SdoGeometry(p_dims=>p_segment.ST_Dims());
    SELF.tolerance  := CASE WHEN p_segment.PrecisionModel.tolerance is null THEN 0.005 
                            ELSE p_segment.PrecisionModel.tolerance
                        END;
    SELF.projected  := NVL(p_segment.projected,1);
    SELF.dPrecision := NVL(p_segment.PrecisionModel.XY,
                           case when p_segment.projected = 0 then 9
                                else (ROUND(log(10,(1/SELF.tolerance)/2)) + 1)
                            end);
    RETURN;
  End T_GEOMETRY;

  Constructor Function T_GEOMETRY(SELF    IN OUT NOCOPY T_GEOMETRY,
                                  p_geoms IN mdsys.sdo_geometry_array)
                Return Self As Result
  As
    c_i_dim_error  CONSTANT pls_integer    := -20101;
    c_s_dim_error  CONSTANT VARCHAR2(1000) := 'Coordinate Dimensions have to be the same for all sdo_geometry objects in p_geoms.';
    c_i_srid_error CONSTANT pls_integer    := -20102;
    c_s_srid_error CONSTANT VARCHAR2(1000) := 'All sdo_geometry objects in p_geoms have to have the same SRID.';
    c_i_lrs_error  CONSTANT pls_integer    := -20103;
    c_s_lrs_error  CONSTANT VARCHAR2(1000) := 'All sdo_geometry objects in p_geoms have to have the same LRS Dimension.';

    v_dims        pls_integer;
    v_lrs_dim     pls_integer;
    v_srid        pls_integer;

    v_elemNum     pls_integer;
    v_ordNum      pls_integer;
    v_base_offset pls_integer;

    v_geom        mdsys.Sdo_Geometry;
    v_nGeom       mdsys.Sdo_Geometry;
  Begin
    SELF.tolerance  := 0.005;
    SELF.dPrecision := 3;
    SELF.projected  := 1;
    IF ( p_geoms is not null AND p_geoms.COUNT > 0 ) THEN
      -- Dims, Srid and Lrs_Dim have to be the same
      v_dims    := p_geoms(1).Get_Dims();
      v_srid    := p_geoms(1).sdo_srid;
      v_lrs_dim := p_geoms(1).Get_LRS_Dim();
      <<ExtractMinimumDimensionality>>
      FOR i IN 2..p_geoms.COUNT LOOP
        IF ( p_geoms(i).get_dims() <> v_dims ) THEN
          raise_application_error(c_i_dim_error,c_s_dim_error,TRUE);
        END IF;
        IF ( p_geoms(i).sdo_srid <> v_srid) THEN
          raise_application_error(c_i_srid_error,c_s_srid_error,TRUE);
        END IF;
        IF ( p_geoms(i).Get_LRS_Dim() <> v_lrs_dim) THEN
          raise_application_error(c_i_lrs_error,c_s_lrs_error,TRUE);
        END IF;
      END LOOP ExtractMinimumDimensionality;
      -- Measures?
      v_geom := mdsys.sdo_geometry(v_dims * 1000 + 4,
                                   p_geoms(1).sdo_srid,
                                   null,
                                   mdsys.sdo_elem_info_array(),
                                   mdsys.sdo_ordinate_array()
                );
      <<IterateOverAllGeometries>>
      v_base_offset := 0;
      FOR geomN IN 1..p_geoms.COUNT LOOP
        v_nGeom := p_geoms(geomN);
        IF ( v_nGeom.sdo_ordinates is not null ) THEN

          -- DEBUG dbms_output.put_line('Sdo Element Info Array');
          v_elemNum := v_geom.sdo_elem_info.COUNT;
          v_geom.sdo_elem_info.EXTEND(v_nGeom.sdo_elem_info.COUNT);
          <<SdoElementInfoArray>>
          For i in 1..v_nGeom.sdo_elem_info.COUNT Loop
            v_elemNum := v_elemNum + 1;
            IF ( MOD(i,3)=1 ) THEN
              v_geom.sdo_elem_info(v_elemNum) := v_base_offset + v_nGeom.sdo_elem_info(i);
            ELSE
              v_geom.sdo_elem_info(v_elemNum) := v_nGeom.sdo_elem_info(i);
            END IF;
          End Loop SdoElementInfoArray;

          -- Ordinates
          -- DEBUG dbms_output.put_line('Sdo Ordinate Array');
          v_ordNum := v_geom.sdo_ordinates.COUNT;
          v_geom.sdo_ordinates.EXTEND(v_nGeom.sdo_ordinates.COUNT);
          <<ForAllOrdinatesToAppend>>
          For i In 1..v_nGeom.sdo_ordinates.COUNT Loop
            v_ordNum := v_ordNum + 1;
            v_geom.sdo_ordinates(v_ordNum) := v_nGeom.sdo_ordinates(i);
          End Loop ForAllOrdinatesToAppend;
          v_base_offset := v_geom.sdo_ordinates.COUNT;

        ELSIF ( v_nGeom.sdo_point is not null ) THEN
          -- DEBUG dbms_output.put('Sdo Point Geometry.sdo_elem_info(');

          v_geom.sdo_elem_info.EXTEND(3);
          v_geom.sdo_elem_info(v_geom.sdo_elem_info.COUNT-2) := v_base_offset + 1;
          v_geom.sdo_elem_info(v_geom.sdo_elem_info.COUNT-1) := 1;
          v_geom.sdo_elem_info(v_geom.sdo_elem_info.COUNT  ) := 1;

          -- Ordinates
          v_geom.sdo_ordinates.EXTEND(v_dims);
          v_geom.sdo_ordinates(v_geom.sdo_ordinates.COUNT-(v_dims-1)) := v_nGeom.sdo_point.x;
          v_geom.sdo_ordinates(v_geom.sdo_ordinates.COUNT-(v_dims-2)) := v_nGeom.sdo_point.y;
          IF ( v_dims > 2 ) Then
            v_geom.sdo_ordinates(v_geom.sdo_ordinates.COUNT)          := v_nGeom.sdo_point.z;
          End If;
          v_base_offset := v_geom.sdo_ordinates.COUNT;
        ELSE
          continue;
        END IF;
        -- DEBUG dbms_output.put(&&INSTALL_SCHEMA..PRINT.sdo_elem_info(v_geom.sdo_elem_info));
        -- DEBUG dbms_output.put(&&INSTALL_SCHEMA..PRINT.sdo_ordinates(v_geom.sdo_ordinates,v_dims,SELF.dPrecision));
      END LOOP IterateOverAllGeometries;
    END IF;
    SELF.geom := v_geom;
    RETURN;
  End T_GEOMETRY;

  Constructor Function T_GEOMETRY(SELF   IN OUT NOCOPY T_GEOMETRY,
                                  p_ewkt IN CLOB )
                Return Self As Result
  As
    v_ewkt          clob;
    v_num_ords      pls_integer := 0;
    v_srid_i        pls_integer;
    v_srid_s        varchar2(100);
    v_coord_string  varchar2(30000);
    v_geometry_type varchar2(30000);
    v_sdo_geom      mdsys.sdo_geometry;
    v_t_geom        &&INSTALL_SCHEMA..T_Geometry;
    v_2d_t_geom     &&INSTALL_SCHEMA..T_Geometry;
  Begin
    SELF.tolerance  := 0.005;
    SELF.dPrecision := 3;
    SELF.projected  := 1; -- 'PLANAR';
    IF ( p_ewkt is null ) THEN
      SELF.geom := SDO_GEOMETRY(NULL,NULL,NULL,NULL,NULL);
      RETURN;
    END IF;

    -- Find SRID if at start
    v_srid_i := NULL;
    v_srid_s := DBMS_LOB.SUBSTR(p_ewkt,REGEXP_INSTR(p_ewkt,';')-1,1);
    If ( v_srid_s is not null ) Then
      v_srid_s := REGEXP_SUBSTR(p_ewkt,'[0-9][0-9]*');
      If (v_srid_s is not null) Then
        v_srid_i := TO_NUMBER(v_srid_s);
      END IF;
      -- Remove SRID={VALUE};
      v_ewkt := DBMS_LOB.SUBSTR(p_ewkt,DBMS_LOB.GetLength(p_ewkt),REGEXP_INSTR(p_ewkt,';')+1);
    ELSE
      v_ewkt := p_ewkt;
    END IF;

    IF ( v_ewkt = 'POINT EMPTY' ) THEN
      SELF.geom := SDO_GEOMETRY(2001,v_srid_i,NULL,NULL,NULL);
      RETURN;
    ELSIF ( v_ewkt = 'MULTIPOINT EMPTY' ) THEN
      SELF.geom := SDO_GEOMETRY(2005,v_srid_i,NULL,NULL,NULL);
      RETURN;
    ELSIF ( v_ewkt = 'LINESTRING EMPTY' ) THEN
      SELF.geom := SDO_GEOMETRY(2002,v_srid_i,NULL,NULL,NULL);
      RETURN;
    ELSIF ( v_ewkt = 'MULTILINESTRING EMPTY' ) THEN
      SELF.geom := SDO_GEOMETRY(2006,v_srid_i,NULL,NULL,NULL);
      RETURN;
    ELSIF ( v_ewkt = 'POLYGON EMPTY' ) THEN
      SELF.geom := SDO_GEOMETRY(2003,v_srid_i,NULL,NULL,NULL);
      RETURN;
    ELSIF ( v_ewkt = 'MULTIPOLYGON EMPTY' ) THEN
      SELF.geom := SDO_GEOMETRY(2007,v_srid_i,NULL,NULL,NULL);
      RETURN;
    ELSIF ( v_ewkt = 'GEOMETRYCOLLECTION EMPTY' ) THEN
      SELF.geom := SDO_GEOMETRY(2004,v_srid_i,NULL,NULL,NULL);
      RETURN;
    END IF;

    v_coord_string  := DBMS_LOB.SUBSTR(v_ewkt,REGEXP_INSTR(v_ewkt,'[,)]',1,1)-1,1);
    v_coord_string  := REGEXP_SUBSTR(v_coord_string,'[0-9][0-9\. ]*',1);
    v_num_ords      := REGEXP_COUNT(v_coord_string, '[0-9][0-9\.]*',1);
    v_geometry_type := TRIM(DBMS_LOB.SUBSTR(v_ewkt,REGEXP_INSTR(v_ewkt,'\(')-1,1));
    -- If WKT is single Point then use T_VERTEX Constructor to parse the coordinate string.
    IF ( v_geometry_type LIKE 'POINT%' ) THEN
      SELF.geom := &&INSTALL_SCHEMA..T_VERTEX(
                     p_coord_string => v_coord_string,
                     p_id           => 1,
                     p_sdo_srid     => v_srid_i
                   )
                   .ST_SdoGeometry();
      RETURN;
    END IF;

    -- Now create a 2D geometry object from 2D part of EWKT.
    With tokens2D As (
      select a.id,
             case when REGEXP_LIKE(a.token,'^[A-Z]')
                  then REGEXP_REPLACE(a.token,'[ZM][ZM]*[ ]?$')
                  when a.coord_id <> 0
                  then REGEXP_SUBSTR(a.token,'[0-9][0-9\.]* [0-9][0-9\.]*',1)
                  else a.token
              end as token,
             a.separator
        from (select t.id,
                     t.token,
                     case when t.token is  null
                          then 0
                          when regexp_like(TRIM(t.token),'^[0-9]')
                          then 1
                          else 0
                      end as coord_id,
                     separator
                from TABLE(&&INSTALL_SCHEMA..TOOLS.Tokenizer(p_ewkt,';(,)')) t
             ) a
       order by a.id
    )
    SELECT &&INSTALL_SCHEMA..TOOLS.TokenAggregator(f.tokens,',') AS ewkt
      INTO v_ewkt
      FROM (SELECT CAST(COLLECT(&&INSTALL_SCHEMA..T_Token(l.id,l.token,l.separator))
                             AS &&INSTALL_SCHEMA..T_Tokens) as tokens
              FROM tokens2D l
            ORDER BY l.id
           ) f;

    v_2d_t_geom := &&INSTALL_SCHEMA..T_Geometry.ST_FromText(v_ewkt,v_srid_i);

    -- If WKT is 2D then nothing more to do
    IF ( NVL(v_num_ords,0) = 2 ) Then
      SELF.geom := v_2D_t_geom.geom;
    END IF;

    -- 3/4D so, reshape sdo_geometry to have additional coordinate dimensions.
    v_t_geom    := case when v_num_ords = 3
                        then v_2d_t_geom.ST_To3D(p_zOrdToKeep=>3)
                        when v_num_ords = 4
                        then v_2d_t_geom.ST_To3D(p_zOrdToKeep=>3).ST_LRS_Add_Measure()
                   end;

    -- Now make sure sdo_gtype is correct for ZM geometries
    v_t_geom.geom.sdo_gtype := case when v_num_ords = 3 and v_geometry_type like '%M'
                                    then 3300 + v_t_geom.ST_GType()
                                    when v_num_ords = 3 and v_geometry_type like '%Z'
                                    then 3000 + v_t_geom.ST_GType()
                                    else v_t_geom.geom.sdo_gtype
                                end;

    -- Now update ZM ordinates to have values from input p_ewkt.
    With replacementcoords As (
    select r.coord_id,
           r.coords.x as ordinates_x,
           r.coords.y as ordinates_y,
           r.coords.z as ordinates_z,
           r.coords.w as ordinates_w
      from (select coord_id,
                   &&INSTALL_SCHEMA..T_Vertex(
                      p_coord_string => coords,
                      p_id           => coord_id,
                      p_sdo_srid     => NULL
                   ) as coords
              from (select Sum(a.coord_id) over (partition by a.coord_id order by id) as coord_id,
                           TRIM(a.token)  as coords
                      from (select t.id,
                                   t.token,
                                   case when t.token is null
                                        then 0
                                        when regexp_like(TRIM(t.token),'^[0-9]')
                                        then 1
                                        else 0
                                    end as coord_id,
                                   separator
                              from TABLE(tools.tokenizer(p_ewkt,';(,)')) t
                           ) a
                  ) b
                  where b.coord_id > 0
              order by b.coord_id
           ) r
     order by r.coord_id
    )
    SELECT CAST(COLLECT(ord) AS mdsys.sdo_ordinate_array) as sdo_ordinates
      INTO v_t_geom.geom.sdo_ordinates
      FROM replacementCoords a
           UNPIVOT (
             ord
             FOR ordinate
              IN (ordinates_x AS 'X',
                  ordinates_y AS 'Y',
                  ordinates_z AS 'Z',
                  ordinates_w AS 'W'))
    order by coord_id,
             DECODE(ordinate,'X',1,'Y',2,'Z',3,'W',4,5);
    Return;
  End T_GEOMETRY;

  /********************* End Of Constructors ***************************/

  -- ************ STATIC FUNCTIONS ********************

  Static Function ST_Release
           Return varchar2
  IS
  BEGIN
    RETURN '5.0.0 Database(11.2,12.1,12,2) Documentation(RoboDoc 1.6.0)';
  END ST_Release;

  -- ************ MEMBER FUNCTIONS ********************

  Member Function ST_AsGeometryRow(p_gid in integer default 1)
           Return &&INSTALL_SCHEMA..T_Geometry_Row
  As
  Begin
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY_ROW(NVL(p_gid,1),SELF.geom,SELF.tolerance,SELF.dPrecision,SELF.projected);
  End ST_AsGeometryRow;

  Member Procedure ST_SetProjection(SELF IN OUT NOCOPY T_GEOMETRY)
  As
    c_i_invalid_srid CONSTANT INTEGER       := -20120;
    c_s_invalid_srid CONSTANT VARCHAR2(100) := 'p_srid (*SRID*) must exist in mdsys.cs_srs';
    v_srid_type      varchar2(25);
  BEGIN
     IF (SELF.ST_SRID() is null) Then
        SELF.projected := 1; -- PROJECTED
        RETURN;
     End If;
     BEGIN
        SELECT SUBSTR(DECODE(crs.coord_ref_sys_kind,
                            'COMPOUND','PLANAR',
                            'ENGINEERING','PLANAR',
                            'GEOCENTRIC','GEOGRAPHIC',
                            'GEOGENTRIC','GEOGRAPHIC',
                            'GEOGRAPHIC2D','GEOGRAPHIC',
                            'GEOGRAPHIC3D','GEOGRAPHIC',
                            'PROJECTED' ,'PLANAR',
                            'VERTICAL','GEOGRAPHIC',
                            'PLANAR'),1,20) as unit_of_measure
           into v_srid_type
          from mdsys.sdo_coord_ref_system crs
         where crs.srid = SELF.ST_SRID();
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          raise_application_error(c_i_invalid_srid,
                                  REPLACE(c_s_invalid_srid,'*SRID*',SELF.ST_SRID()));
     END;
     SELF.projected := case when v_srid_type = 'PLANAR' then 1 else 0 end;
     SELF.tolerance  := NVL(SELF.tolerance, case when SELF.projected = 'GEOGRAPHIC' then 0.05 else 0.0005 end);
     SELF.dPrecision := NVL(SELF.dPrecision,case when SELF.projected = 'GEOGRAPHIC' then 8    else (ROUND(log(10,(1/SELF.tolerance)/2))+1) end);
  END ST_SetProjection;

  Member Function ST_SetSdoGtype (p_sdo_gtype in integer)
           Return &&INSTALL_SCHEMA..T_Geometry
  As
  Begin
     Return &&INSTALL_SCHEMA..T_Geometry(
              mdsys.sdo_geometry(NVL(p_sdo_gtype,SELF.geom.sdo_gtype),
                                 SELF.geom.SDO_SRID,
                                 SELF.geom.SDO_POINT,
                                 SELF.geom.sdo_elem_info,
                                 SELF.geom.sdo_ordinates),
              SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_SetSdoGtype;

  Member Function ST_SetSRID(p_srid in integer)
           Return &&INSTALL_SCHEMA..T_Geometry
  As
  Begin
     return &&INSTALL_SCHEMA..T_Geometry(mdsys.sdo_geometry(SELF.geom.sdo_gtype,
                                               p_srid,
                                               SELF.geom.SDO_POINT,
                                               SELF.geom.sdo_elem_info,
                                               SELF.geom.sdo_ordinates),
                            SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_SetSRID;

  Member Function ST_SetPrecision(p_dPrecision in integer default 3)
           Return &&INSTALL_SCHEMA..T_Geometry
  As
  Begin
     return &&INSTALL_SCHEMA..T_Geometry(SELF.geom,SELF.tolerance,NVL(p_dPrecision,3),SELF.projected);
  End ST_SetPrecision;

  Member Function ST_SetTolerance(p_tolerance in number default 0.005)
           Return &&INSTALL_SCHEMA..T_Geometry
  As
  Begin
     return &&INSTALL_SCHEMA..T_Geometry(SELF.geom,NVL(p_tolerance,0.005),SELF.dPrecision,SELF.projected);
  End ST_SetTolerance;

  Member Function ST_Gtype
           Return Integer
  As
  Begin
     return case when SELF.geom is not null then SELF.GEOM.Get_Gtype() else null end;
  End ST_Gtype;

  Member Function ST_Dims
           Return Integer
  As
  Begin
     return case when SELF.geom is not null then SELF.GEOM.Get_Dims() else null end;
  End ST_Dims;

  Member Function ST_SDO_GType
           Return Integer
  As
  Begin
     return case when SELF.geom is not null then SELF.geom.sdo_gtype else null end;
  End ST_SDO_GType;

  Member Function ST_Srid
           Return Integer
  As
  Begin
     return case when SELF.geom is not null then SELF.GEOM.sdo_srid Else null end;
  End ST_Srid;

  Member Function ST_AsWkb
           Return Blob
  As
  Begin
     return case when SELF.geom is not null then SELF.GEOM.Get_Wkb() else null end;
  End ST_AsWkb ;

  Member Function ST_AsWKT
           Return CLOB
  As
  Begin
     return case when SELF.geom is not null then SELF.GEOM.Get_Wkt() else null end;
  End ST_AsWkt;

  Member Function ST_AsText
           Return CLOB
  As
  Begin
     return case when SELF.geom is not null then SELF.GEOM.Get_Wkt() else null end;
  End ST_AsText;

  Static Function ST_FromText(p_wkt  in clob,
                              p_srid in integer default NULL)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
  Begin
    Return &&INSTALL_SCHEMA..T_GEOMETRY (sdo_geometry(p_wkt,p_srid));
  End ST_FromText;

  Member Function ST_AsEWKT (p_format_model varchar2 default 'TM9')
           Return Clob
  As
    v_ewkt    CLOB;
    v_empty_s varchar2(100);
  Begin
    IF ( SELF.ST_isEmpty() = 1 ) THEN
      v_empty_s := case when SELF.geom.sdo_srid is not null 
                        then 'SRID='||SELF.geom.sdo_srid||';' 
                        else '' 
                    end ||
                   Case SELF.ST_GType()
                        When 1 Then 'POINT EMPTY'
                        When 2 Then 'LINESTRING EMPTY'
                        When 3 Then 'POLYGON EMPTY'
                        When 4 Then 'GEOMETRYCOLLECTION EMPTY'
                        When 5 Then 'MULTIPOINT EMPTY'
                        When 6 Then 'MULTILINESTRING EMPTY'
                        When 7 Then 'MULTIPOLYGON EMPTY'
                        When 8 Then 'SOLID EMPTY'
                        When 9 Then 'MULTISOLID EMPTY'
                    END;
      v_ewkt := TO_CLOB( v_empty_s );
      Return v_ewkt;
    END IF;
    -- Build EWKT String...
    With data as (
      select a.id,
             case when a.id = 1
                  then case when SELF.ST_Srid() is not null then 'SRID='||SELF.GEOM.SDO_SRID||';' else '' end ||
                       TRIM(a.token) ||
                       case when SELF.ST_HasZ()=1 AND SELF.ST_HasM()=1 then 'ZM' else '' end ||
                       case when SELF.ST_HasZ()=1 then 'Z' else '' end ||
                       case when SELF.ST_HasM()=1 then 'M' else '' end ||
                       ' '
                  when a.coord_id <> 0
                  then &&INSTALL_SCHEMA..T_Vertex (
                          p_x        => c.x,
                          p_y        => c.y,
                          p_z        => c.z,
                          p_w        => c.w,
                          p_id       => c.id,
                          p_sdo_gtype=> SELF.GEOM.SDO_GTYPE,
                          p_sdo_srid => SELF.GEOM.SDO_SRID
                       ).ST_AsCoordString(p_format_model => NVL(p_format_model,'TM9'))
                  else a.token
              end as token,
             a.separator
        from (select f.id,
                     f.token,
                     f.separator,
                     Sum(f.coord_id) over (partition by coord_id order by id) as coord_id
                from (select t.id,
                             t.token as token,
                             case when t.token is  null
                                  then 0
                                  when regexp_like(TRIM(t.token),'^[0-9]')
                                  then 1
                                  else 0
                              end as coord_id,
                             separator
                        from TABLE(&&INSTALL_SCHEMA..TOOLS.Tokenizer(SELF.ST_To2D().ST_AsText(),'(,)')) t
                     ) f
               order by f.id
             ) a
             LEFT OUTER JOIN
             TABLE(mdsys.sdo_util.getVertices(SELF.geom)) c
            ON (c.id = a.coord_id)
    )
    SELECT &&INSTALL_SCHEMA..TOOLS.TokenAggregator(tokens,',') AS ewkt
      INTO v_ewkt
      FROM (SELECT CAST(COLLECT(&&INSTALL_SCHEMA..T_Token(l.id,l.token,l.separator)) AS &&INSTALL_SCHEMA..T_Tokens) as tokens
              FROM data l
              ORDER BY l.id
           ) f;
    Return v_ewkt;
  End ST_AsEWKT;

  Static Function ST_FromEWKT(p_ewkt in clob)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
  Begin
    Return &&INSTALL_SCHEMA..T_GEOMETRY(p_ewkt);
  End ST_FromEWKT;

  Member Function ST_CoordDimension
           Return Smallint
  As
  Begin
     return case when SELF.geom is not null then SELF.GEOM.ST_CoordDim() else null end;
  End ST_CoordDimension;

  Member Function ST_isValid
           Return Integer
  As
  Begin
     return case when SELF.geom is null
                 then 0
                 else SELF.GEOM.ST_isValid()
             end;
  End ST_isValid;

  Member Function ST_Validate(p_context in integer default 0)
           Return varchar2
  As
  Begin
     Return case when NVL(p_context,0) = 0
                 then mdsys.sdo_geom.validate_geometry(SELF.geom,SELF.tolerance)
                 else mdsys.sdo_geom.validate_geometry_with_context(SELF.geom,SELF.tolerance)
            end;
  End ST_Validate;

  Member Function ST_isValidContext
           Return varchar2
  As
  Begin
     Return mdsys.sdo_geom.validate_geometry_with_context(SELF.geom,SELF.tolerance);
  End ST_isValidContext;

  Member Function ST_isEmpty
           Return integer
  Is
  Begin
    If (SELF.geom is null) Then /* NULL isEmpty by definition */
      return 1;
    End If;
    -- The Constructor T_GEOMETRY(p_ewkt) could have set sdo_gtype and sdo_srid
    -- So only test the actual geometry attributes for emptiness.
    If (  SELF.geom.sdo_point     is null
      and SELF.geom.sdo_elem_info is null
      and SELF.geom.sdo_ordinates is null ) Then
      Return 1;
    End If;
    Return 0;
  End ST_isEmpty;

  Member Function ST_isClosed
           Return integer
  As
    v_startVertex &&INSTALL_SCHEMA..T_Vertex;
    v_endVertex   &&INSTALL_SCHEMA..T_Vertex;
  Begin
    If ( SELF.ST_GType() <> 2 ) THEN
      Return -1;
    END IF;
    v_startVertex := SELF.ST_VertexN(1);
    v_endVertex   := SELF.ST_VertexN(-1);
    Return v_startVertex.ST_Equals(v_endVertex);
  END ST_isClosed;

  Member Function ST_isSimple
         Return integer
  Is
  Begin
    Return mdsys.ST_Geometry(SELF.GEOM).ST_isSimple();
  End ST_isSimple;

  Member Function ST_GeometryType
           Return VarChar2
  Is
    uninitialized_collection EXCEPTION;
    PRAGMA EXCEPTION_INIT(uninitialized_collection,-6531);
  Begin
     return case when SELF.geom is not null
                 then mdsys.ST_GEOMETRY(SELF.geom).ST_GeometryType()
                 else null
             end;
     Exception
        WHEN uninitialized_collection THEN
          RETURN NULL;
  End ST_GeometryType;

  Member Function ST_NumVertices
           Return Integer
  Is
    uninitialized_collection EXCEPTION;
    PRAGMA EXCEPTION_INIT(uninitialized_collection,-6531);
  Begin
     return case when SELF.geom is not null
                 then mdsys.sdo_util.getNumVertices(SELF.geom)
                 else null
             end;
     Exception
        WHEN uninitialized_collection THEN
          RETURN NULL;
  End ST_NumVertices;

  Member Function ST_NumPoints
           Return Integer
  Is
    uninitialized_collection EXCEPTION;
    PRAGMA EXCEPTION_INIT(uninitialized_collection,-6531);
  Begin
     return case when SELF.geom is not null
                 then mdsys.sdo_util.getNumVertices(SELF.geom)
                 else null
             end;
     Exception
        WHEN uninitialized_collection THEN
          RETURN NULL;
  End ST_NumPoints;

  Member Function ST_NumGeometries
           Return Integer
  Is
    uninitialized_collection EXCEPTION;
    PRAGMA EXCEPTION_INIT(uninitialized_collection,-6531);
  Begin
     Return case when SELF.geom is not null
                 then mdsys.sdo_util.getNumElem(SELF.geom)
                 else null
             end;
     Exception
        WHEN uninitialized_collection THEN
          RETURN NULL;
  End ST_NumGeometries;

  Member Function ST_NumElements
           Return Integer
  Is
    uninitialized_collection EXCEPTION;
    PRAGMA EXCEPTION_INIT(uninitialized_collection,-6531);
  Begin
     Return case when SELF.geom is not null
                 then mdsys.sdo_util.getNumElem(SELF.geom)
                 else null
             end;
     Exception
        WHEN uninitialized_collection THEN
          RETURN NULL;
  End ST_NumElements;

  Member Function ST_NumElementInfo
           Return Integer
  Is
    uninitialized_collection EXCEPTION;
    PRAGMA EXCEPTION_INIT(uninitialized_collection,-6531);
  Begin
     Return case when SELF.geom is not null
                 then (SELF.geom.sdo_elem_info.COUNT / 3) - 1
                 else null
             end;
     Exception
        WHEN uninitialized_collection THEN
          RETURN NULL;
  End ST_NumElementInfo;

  Member Function ST_NumSegments
           Return Integer
  Is
  Begin
    return case SELF.ST_Dimension()
                when 1
                then SELF.ST_NumVertices() - SELF.ST_NumElements()
                when 2
                then SELF.ST_NumVertices() - ( SELF.ST_NumElements() + SELF.ST_NumInteriorRing() )
                else 0
            end;
  End ST_NumSegments;

  Member Function ST_Dimension
           Return Integer
  Is
     v_gtype pls_integer;
  Begin
     If ( SELF.geom is null ) Then
        Return NULL;
     End If;
     v_gtype := SELF.ST_gtype();
    /* Returns 0 for POINT, 1 for LINESTRING, 2 for POLYGON, 3 for SOLID
      * and the largest dimension of the components of a GEOMETRYCOLLECTION.
     **/
     Return CASE WHEN v_gtype in (1,5) THEN 0
                 WHEN v_gtype in (2,6) THEN 1
                 WHEN v_gtype in (3,7) THEN 2
                 WHEN v_gtype =   4    THEN -1 /* Layer */
                 WHEN v_gtype in (8,9) THEN 3
                 ELSE -1
              END;
  End ST_Dimension;

  Member Function ST_hasDimension(p_dim in integer default 2)
           Return Integer
  As
     v_etype pls_integer := 0;
     v_gtype pls_integer := -1;
  Begin
     If ( SELF.geom is null or SELF.geom.get_gtype() is null ) Then
        Return 0;
     End If;
     v_gtype := MOD(SELF.geom.sdo_gtype,100);  -- DLTT
     If (  ( v_gtype in (1,5) and p_dim = 0 )
        or ( v_gtype in (2,6) and p_dim = 1 )
        or ( v_gtype in (3,7) and p_dim = 2 )
        or ( v_gtype in (8,9) and p_dim = 3 ) ) Then
           Return 1;
     End If;
     If ( v_gtype = 4 ) Then
       <<element_extraction>>
       FOR v_i IN 0 .. ( ( SELF.geom.sdo_elem_info.COUNT / 3 ) - 1 ) LOOP
          v_etype := SELF.geom.sdo_elem_info(v_i * 3 + 2);
          -- Loop, checking etype value, until find required dimension p_dim
          If ( ( v_etype = 1                      and p_dim = 0 )
            or ( v_etype in (2,4)                 and p_dim = 1 )
            or ( v_etype in (1003,2003,1005,2005) and p_dim = 2 )
            or ( v_etype in (1007,1006,2006)      and p_dim = 3 ) ) Then
             Return 1;
          End If;
        END LOOP element_extraction;
        Return 0;
     Else
        return 0;
     End If;
  End ST_hasDimension;

  Member Function ST_hasZ
           Return Integer
  Is
  Begin
     return case when SELF.geom is not null
            then CASE WHEN (SELF.ST_Dims() = 3 and SELF.Geom.Get_LRS_Dim() = 0)
                        OR (SELF.ST_Dims() = 4)
                      THEN 1
                      ELSE 0
                  END
            else 0
        end;
  End ST_hasZ;

  Member Function ST_hasM
           Return Integer
  Is
  Begin
     return case when SELF.geom is not null
            then CASE WHEN SELF.Geom.Get_LRS_Dim() <> 0
                        OR SELF.ST_Dims()=4
                      THEN 1
                      ELSE 0
                  END
            else 0
        end;
  End ST_hasM;

  Member Function ST_Length (p_unit  in varchar2 default null,
                             p_round in integer default 0 )
           Return Number
  is
    v_geom      mdsys.sdo_geometry;
    v_test_len  number;
    v_length    number;
    v_tolerance number  := nvl(SELF.tolerance,0.005);
    v_isLocator boolean := false;

    Function sdo_length3D(p_geom in mdsys.sdo_geometry)
    Return Number
    IS
      v_geom         mdsys.sdo_geometry;
      v_length       number;
      v_num_elements pls_integer;
      v_element      mdsys.sdo_geometry;
      v_num_rings    pls_integer;
      v_ring         mdsys.sdo_geometry;

      Function ComputeLength3D (P_Geom In Mdsys.Sdo_Geometry)
      Return Number
      Is
        v_first_ord  pls_integer  := 0;
        v_second_ord pls_integer  := 0;
        v_z_posn     pls_integer  := 0;
        v_length     number       := 0.0;
        v_seg_len    number       := 0.0;
        v_dims       pls_integer  := 2;
        v_geom       mdsys.sdo_geometry :=
                     mdsys.sdo_geometry(2002,
                                        p_geom.sdo_srid,
                                        null,
                                        mdsys.sdo_elem_info_array(1,2,1),
                                        mdsys.sdo_ordinate_array(0,0,0,0));
      Begin
         IF ( p_geom.sdo_ordinates IS NOT NULL AND p_geom.sdo_ordinates.COUNT > 0) THEN
            v_dims := p_geom.get_Dims();
            v_z_posn := (case p_geom.get_lrs_dim()
                              when 0 then v_dims
                              when 3 then v_dims
                              when 4 then 3
                          end ) - 1;
            <<while_vertex_to_process>>
            For v_coord In 1..(p_geom.sdo_ordinates.COUNT/v_dims)-1 Loop
                v_first_ord  := ((v_coord-1) * v_dims) + 1;
                v_second_ord :=  (v_coord    * v_dims) + 1;
                -- DEBUG dbms_output.put_line('v_first_ord: ' || v_first_ord || ' v_second_ord: ' || v_second_ord || ' v_z_posn: ' || v_z_posn);
                v_geom.sdo_ordinates(1) := p_geom.sdo_ordinates(v_first_ord);
                v_geom.sdo_ordinates(2) := p_geom.sdo_ordinates(v_first_ord+1);
                v_geom.sdo_ordinates(3) := p_geom.sdo_ordinates(v_second_ord);
                v_geom.sdo_ordinates(4) := p_geom.sdo_ordinates(v_second_ord+1);
                -- Because srid may be lat/long, compute horizontal distance first
                v_seg_len := CASE WHEN P_UNIT IS NOT NULL AND p_geom.sdo_SRID IS NOT NULL
                                  THEN MDSYS.SDO_GEOM.sdo_length(v_geom,v_tolerance,P_UNIT)
                                  ELSE MDSYS.SDO_GEOM.sdo_length(v_geom,v_tolerance)
                              END;
                -- DEBUG dbms_output.put_line('Z ords: ' || p_geom.sdo_ordinates(v_first_ord +v_z_posn) || ' - ' || p_geom.sdo_ordinates(v_second_ord+v_z_posn));
                -- Now compute Z component
                  v_length := v_length +
                            SQRT(POWER(v_seg_len,2) +
                                 POWER(p_geom.sdo_ordinates(v_first_ord +v_z_posn) -
                                       p_geom.sdo_ordinates(v_second_ord+v_z_posn),2));
            End Loop while_vertex_to_process;
          End If;
          Return v_length;
      End ComputeLength3D;

    BEGIN
        v_num_elements := SELF.ST_NumElements();
        v_length := 0.0;
        <<for_all_elements>>
        for v_element_no in 1..v_num_elements loop
           v_element := MDSYS.SDO_UTIL.EXTRACT(p_geom,v_element_no);   -- Extract element with all sub-elements
           IF ( V_ELEMENT.GET_GTYPE() = 2 ) THEN
              v_length := V_LENGTH + ComputeLength3D(v_element);
           else
              V_Num_Rings := &&INSTALL_SCHEMA..T_GEOMETRY(V_Element).St_NumRings();
              <<for_all_rings>>
              FOR v_ring_no in 1..v_num_rings Loop
                 -- Extract ring from element .. must do it this way, can't correctly extract from v_element.
                 v_ring := mdsys.sdo_util.extract(p_geom,v_element_no,v_ring_no);
                 v_length := v_length + ComputeLength3D(v_ring);
              End Loop for_all_rings;
           End If;
        END LOOP for_all_elements;
        Return v_length;
    END SDO_LENGTH3D;

  Begin
    -- DEBUG dbms_output.put_line('Test to see if we are running in Enterprise Edition Spatial or Locator');
    v_isLocator := case when &&INSTALL_SCHEMA..TOOLS.ST_isLocator() = 1 then true else false end;
    -- DEBUG dbms_output.put_line('v_isLocator='||case when v_isLocator is null then 'TRUE' else 'FALSE' end);
    v_length := 0.0;
    If (SELF.geom is null) Then
        return 0.0;
    End If;
    IF (SELF.ST_Dimension() not in (1/*LINESTRING*/,2/*POLYGON*/) ) Then
       Return 0.0;
    END IF;

    IF ( (SELF.ST_Dims() = 2) OR (SELF.ST_Dims() = 3 AND SELF.ST_Lrs_Dim() != 0)) Then

      -- If p_unit is null it is the same as not having it in the function call
      v_length := Case When P_UNIT IS NOT NULL AND SELF.ST_Srid() IS NOT NULL
                       Then MDSYS.SDO_GEOM.sdo_length(SELF.geom,v_tolerance,p_unit)
                       Else MDSYS.SDO_GEOM.sdo_length(SELF.geom,v_tolerance)
                   End;
      -- DEBUG dbms_output.put_line('2D or measured: ' || NVL(v_length,-1) || ' Tolerance(' ||v_tolerance||'), unit(' || NVL(p_unit,'NULL')||'), srid('||NVL(SELF.ST_Srid(),-1)||')');

    ELSIF (SELF.ST_Dims() = 3 ) THEN

      IF ( Not v_isLocator ) Then
         -- Spatial computes 3D length ....
         v_length := Case When P_UNIT IS NOT NULL
                          Then MDSYS.SDO_GEOM.sdo_length(SELF.geom,v_tolerance,P_UNIT)
                          Else MDSYS.SDO_GEOM.sdo_length(SELF.geom,v_tolerance)
                      End;
         -- DEBUG dbms_output.put_line('spatial sdo_geom.sdo_length; p_unit=' || NVL(p_unit,'null'));

      ELSE -- is not Locator
        If ( SELF.ST_hasCircularArcs() = 1 ) then
          v_geom := MDSYS.SDO_GEOM.sdo_arc_densify(
                              SELF.geom,
                              v_tolerance,
                              'arc_tolerance=' || (v_tolerance*10) || p_unit
                    );
        Else
          v_geom := SELF.geom;
        End If;
        -- To get 3D Length with circular arc we densify it first
        v_length := sdo_length3d(v_geom);
      end if;
    end if;
    return case when nvl(p_round,0) = 0 then v_length else round(v_length,nvl(self.dprecision,8)) end;
  end st_length;

  member function st_area (p_unit  in varchar2 default null,
                           p_round in integer  default 0 )
           return number
  is
    v_area number;
  begin
    v_area := 0.0;
    if (self.st_dimension() in (2/*polygon*/,3/*solid*/) ) then
       -- if p_unit is null it is the same as not having it in the function call
       v_area := case when p_unit is not null and self.st_srid() is not null
                      then mdsys.sdo_geom.sdo_area(self.geom,self.tolerance,p_unit)
                      else mdsys.sdo_geom.sdo_area(self.geom,self.tolerance)
                  end;
    end if;
    return case when nvl(p_round,0) = 0 then v_area else round(v_area,nvl(self.dprecision,8)) end;
  end st_area;

  -- to be done: locator vs spatial slope length calculation.
  member function st_distance(p_geom  in mdsys.sdo_geometry,
                              p_unit  in varchar2 default null,
                              p_round in integer  default 0 )
           return number
  is
    v_geom     &&INSTALL_SCHEMA..t_geometry;
    v_distance number;
  Begin
    -- Check parameter is OK: T_GEOMETRY construct validates as well
    v_geom     := &&INSTALL_SCHEMA..T_GEOMETRY(p_geom,SELF.tolerance,SELF.dPrecision,SELF.projected);
    v_distance := 0.0;
    -- DEBUG dbms_output.put_line('ST_Distance from ' || SELF.ST_AsEWKT() || ' to ' || v_geom.ST_AsEWKT());
    v_distance := case when p_unit is not null and SELF.ST_Srid() is not null
                       then MDSYS.SDO_GEOM.sdo_distance(SELF.geom,p_geom,SELF.tolerance,p_unit)
                       else MDSYS.SDO_GEOM.sdo_distance(SELF.geom,p_geom,SELF.tolerance)
                   end;
    Return case when NVL(p_round,0) = 0 then v_distance else round(v_distance,NVL(SELF.dPrecision,8)) end;
  End ST_Distance;

  Member Function ST_Relate(p_geom      in mdsys.sdo_geometry,
                            p_determine in varchar2 default 'DETERMINE')
  Return varchar2
  As
    c_i_dims    CONSTANT pls_integer   := -20101;
    c_s_dims    CONSTANT VARCHAR2(100) := 'Coordinate Dimensions are not equal';
    c_i_spatial CONSTANT pls_integer   := -20102;
    c_s_spatial CONSTANT VARCHAR2(100) := 'MDSYS.SDO_GEOM.RELATE only supported for Locator users from 12C onwards.';
  Begin
    IF ( SELF.ST_Dims() <> SELF.ST_Dims() ) THEN
      raise_application_error(c_i_dims,c_s_dims,true);
    End If;
    IF ( SELF.ST_Dims() > 2 and NVL(p_determine,'DETERMINE')='EQUAL' ) THEN
      Return SELF.ST_Equals(p_geometry    => p_geom,
                            p_z_precision => SELF.dPrecision,
                            p_m_precision => SELF.dPrecision);
    END IF;
    IF (  &&INSTALL_SCHEMA..TOOLS.ST_DB_Version() >= 12.0
       OR &&INSTALL_SCHEMA..TOOLS.ST_isLocator()   = 0 ) THEN
      Return MDSYS.SDO_GEOM.RELATE(SELF.geom,NVL(p_determine,'DETERMINE'),p_geom,SELF.tolerance);
    ELSE
      raise_application_error(c_i_spatial,c_s_spatial,true);
    END IF;
    RETURN 'FALSE';
  End ST_Relate;

  Member Function ST_SetPoint(p_point in mdsys.sdo_point_type)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
  Begin
     Return &&INSTALL_SCHEMA..T_GEOMETRY(sdo_geometry(SELF.geom.sdo_gtype,
                                    SELF.ST_SRID(),
                                    p_point,
                                    SELF.geom.sdo_elem_info,
                                    SELF.geom.sdo_ordinates),
                                    SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_SetPoint;

  Member Function ST_SwapOrdinates(p_pair in varchar2 default 'XY' /* Can be XY, XZ, XM, YZ, YM, ZM */ )
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    c_i_invalid_pair Constant Integer       := -20120;
    c_s_invalid_pair Constant VarChar2(100) := 'p_pair (*PAIR*) must be one of  XY, XZ, XM, YZ, YM, ZM only.';
    c_i_invalid_swap Constant Integer       := -20120;
    c_s_invalid_swap Constant VarChar2(100) := 'Requested swap (SWAP*) cannot occur as geometry dimensionality does not support it.';

    Type T_Positions IS Record (x pls_integer, y pls_integer,
                                z pls_integer, m pls_integer);
    v_pair        VARCHAR2(2) := UPPER(SUBSTR(p_pair,1,2));
    v_geom        mdsys.sdo_geometry;
    v_isMeasured  Boolean;
    v_measure_dim PLS_INTEGER;
    v_i           PLS_INTEGER;
    v_source      T_Positions;
    v_target      T_Positions;
  Begin
      IF (    v_pair is NULL
           Or v_pair not in ('XY', 'XZ', 'XM', 'YZ', 'YM', 'ZM' ) ) Then
        raise_application_error(c_i_invalid_pair,
                        REPLACE(c_s_invalid_pair,'*PAIR*',v_pair),true );
      End If;
      -- Get geometry properties needed for processing
      v_geom        := SELF.geom;
      v_isMeasured  := SELF.ST_LRS_isMeasured() = 1;
      v_measure_dim := SELF.ST_Lrs_Dim();
      -- Check provided swap mapping can be supported
      If (  ( SELF.ST_Dims() = 2 And v_pair in ('XZ', 'XM', 'YZ', 'YM', 'ZM' ) )
         Or ( SELF.ST_Dims() = 3 And     v_isMeasured And v_pair in ('XZ', 'YZ' ) )
         Or ( SELF.ST_Dims() = 3 And Not v_isMeasured And v_pair in ('XM', 'YM', 'ZM' ) )
         ) Then
        Raise_Application_Error(c_i_invalid_swap,
                        Replace(c_s_invalid_swap,'*SWAP*',SELF.ST_Dims()||','||V_Pair),
                        true);
      End If;
      -- SDO_POINT Handled separately to SDO_Ordinates
      If (     v_geom.sdo_point is not null
           And v_pair in ('XY','XZ','YZ') ) Then
        v_geom.sdo_point.x := CASE v_pair WHEN 'XY' THEN SELF.geom.sdo_point.y
                                          WHEN 'XZ' THEN SELF.geom.sdo_point.z
                                          ELSE SELF.geom.sdo_point.x END;
        v_geom.sdo_point.y := CASE v_pair WHEN 'XY' THEN SELF.geom.sdo_point.x
                                          WHEN 'YZ' THEN SELF.geom.sdo_point.z
                                          ELSE SELF.geom.sdo_point.y END;
        v_geom.sdo_point.z := CASE v_pair WHEN 'XZ' THEN SELF.geom.sdo_point.x
                                          WHEN 'YZ' THEN SELF.geom.sdo_point.y
                                          ELSE SELF.geom.sdo_point.z END;
        End If;
      -- Process the geometry's ordinate array
      IF ( SELF.geom.sdo_ordinates is not null ) Then
        -- First: Set up the ordinate mapping
        v_source.x := 1;
        v_source.y := 2;
        v_source.z := case when SELF.ST_Dims() in (3,4) and v_measure_dim = 0 then 3
                           when SELF.ST_Dims() = 3      and v_measure_dim = 3 then 0
                           when SELF.ST_Dims() = 4      and v_measure_dim = 4 then 3
                           when SELF.ST_Dims() = 4      and v_measure_dim = 3 then 4
                           else 0
                       end;
        v_source.m := v_measure_dim;
        v_target.x := CASE v_pair WHEN 'XY' THEN 2
                                  WHEN 'XZ' THEN v_source.z
                                  WHEN 'XM' THEN v_source.m ELSE 1 END;
        v_target.y := CASE v_pair WHEN 'XY' THEN 1 WHEN 'YZ' THEN v_source.z
                                  WHEN 'YM' THEN v_source.m ELSE 2 END;
        v_target.z := CASE v_pair WHEN 'XZ' THEN 1 WHEN 'YZ' THEN 2
                                  WHEN 'ZM' THEN v_source.m ELSE v_source.z END;
        v_target.m := CASE v_pair WHEN 'XM' THEN 1 WHEN 'YM' THEN 2
                                  WHEN 'ZM' THEN v_source.z ELSE v_source.m END;
        -- Now process sdo_ordinates
        v_i := 0; -- index into output/input coordinate array
        FOR i IN 1 .. (v_geom.sdo_ordinates.COUNT/SELF.ST_Dims()) LOOP
          v_geom.sdo_ordinates(v_i + v_target.x) :=
             SELF.geom.sdo_ordinates(v_i + v_source.x);
          v_geom.sdo_ordinates(v_i + v_target.y) :=
             SELF.geom.sdo_ordinates(v_i + v_source.y);
          -- Do Z only if exists
          If ( v_source.z <> 0 ) Then
            v_geom.sdo_ordinates(v_i + v_target.z) :=
               SELF.geom.sdo_ordinates(v_i + v_source.z);
          End If;
          -- Do M only if exists
          If ( v_source.m <> 0 ) Then
            v_geom.sdo_ordinates(v_i + v_target.m) :=
               SELF.geom.sdo_ordinates(v_i + v_source.m);
          End If;
          v_i := v_i + SELF.ST_Dims();
        END LOOP;
      End If;
      Return &&INSTALL_SCHEMA..T_GEOMETRY(v_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_SwapOrdinates;

  Member Function ST_hasCircularArcs
           Return Integer
  Is
    v_etype          pls_integer;
    v_interpretation pls_integer;
    v_elements       pls_integer;
    v_elem_info      mdsys.sdo_elem_info_array;
  Begin
    If ( SELF.ST_gtype() in (1,5) ) Then
      return 0;
    End If;
    v_elements  := ( ( SELF.geom.sdo_elem_info.COUNT / 3 ) - 1 );
    v_elem_info := SELF.geom.sdo_elem_info;
    <<element_extraction>>
    for v_i IN 0 .. v_elements LOOP
      v_etype          := v_i * 3 + 2;
      v_interpretation := v_etype + 1;
      if (    ( v_elem_info(v_etype) = 2 AND
                v_elem_info(v_interpretation) = 2 )
           OR ( v_elem_info(v_etype) in (4,1005,2005) )
           OR ( v_elem_info(v_etype) in (1003,2003) AND
                v_elem_info(v_interpretation) IN (2,4) ) ) then
         return 1;
      end If;
    end loop element_extraction;
    return 0;
  End ST_hasCircularArcs;

  Member Function ST_NumRectangles
           Return integer
  Is
    v_etype           pls_integer;
    v_interpretation  pls_integer;
    v_elements        pls_integer := 0;
    v_rectangle_count number := 0;
  Begin
    If ( SELF.ST_Gtype() in (1,2,5,6) ) Then
      return 0;
    End If;
    v_elements := ( ( SELF.geom.sdo_elem_info.COUNT / 3 ) - 1 );
    <<element_extraction>>
    FOR v_i IN 0 .. v_elements LOOP
      v_etype          := SELF.geom.sdo_elem_info(v_i * 3 + 2);
      v_interpretation := SELF.geom.sdo_elem_info(v_i * 3 + 3);
      If ( ( v_etype in (1003,2003) AND
             v_interpretation = 3 ) ) Then
         v_rectangle_count := v_rectangle_count + 1;
      End If;
    END LOOP element_extraction;
    Return v_rectangle_count;
  End ST_NumRectangles;

  Member Function ST_HasRectangles
           Return integer
  Is
  Begin
   Return case when SELF.ST_numRectangles() > 0 then 1 else 0 end;
  End ST_HasRectangles;

  Member Function ST_isOrientedPoint
           Return integer
  is
    v_element      mdsys.sdo_geometry;
    v_num_elements pls_integer;
  Begin
    If ( SELF.ST_Gtype() NOT IN (1,5) ) Then
      return 0;
    End If;

    /* Single Oriented Point
    // Sdo_Elem_Info_Array (1,1,1, 3,1,0),
    // Sdo_Ordinate_Array  (12,14, 0.3,0.2)
    // The Final 1,0 In 3,1,0 Indicates That This Is An Oriented Point.
    //
    // Multi Oriented Point
    // Sdo_Elem_Info_Array(1,1,1, 3,1,0,
    //                     5,1,1, 7,1,0),
    //  Sdo_Ordinate_Array(12,14, 0.3,0.2,
    //                     12,10, -1,-1)
    */
    IF ( SELF.geom.sdo_Elem_Info.Count >= 6 ) Then
       If ( SELF.geom.sdo_Elem_Info(2) = 1 ) /* Point */          And
          ( SELF.geom.sdo_Elem_Info(3) = 1 ) /* Single  Point */  And
          ( SELF.geom.sdo_Elem_Info(5) = 1 ) /* Oriented Point */ And
          ( SELF.geom.sdo_Elem_Info(6) = 0 ) Then
          Return 1;
       else
         Return 0;
       End If;
    End If;

    v_num_elements := SELF.ST_NumElements();
    <<for_all_elements>>
    for v_element_no in 1..v_num_elements loop
        v_element := MDSYS.SDO_UTIL.EXTRACT(SELF.geom,v_element_no);
        -- Now test element infor arrary
       IF ( v_element.sdo_Elem_Info.Count < 6 ) Then
         Continue;
       End If;
       If ( v_element.sdo_Elem_Info(2) = 1 ) /* Point */          And
          ( v_element.sdo_Elem_Info(3) = 1 ) /* Single  Point */  And
          ( v_element.sdo_Elem_Info(5) = 1 ) /* Oriented Point */ And
          ( v_element.sdo_Elem_Info(6) = 0 ) Then
          Return 1;
       else
         Return 0;
       End If;
    End Loop;
    Return 0;
  End ST_isOrientedPoint;

  Member Function ST_ElementTypeAt (p_element in integer)
           Return integer
  Is
    v_element   pls_integer;
    v_num_elems pls_integer;
  Begin
    IF ( SELF.geom is null or SELF.geom.sdo_elem_info is null) Then
      Return NULL;
    End If;
    v_element   := NVL(p_element,1);
    v_num_elems := SELF.geom.sdo_elem_info.COUNT / 3;
    If ( v_element < 0 or v_element > v_num_elems ) Then
      Return Null;
    End If;
    <<element_extraction>>
    for v_i IN 1 .. v_num_elems LOOP
       if ( v_i = v_element ) then
         RETURN SELF.geom.sdo_elem_info((v_i-1) * 3 + 2);
       End If;
    end loop element_extraction;
    Return NULL;
  End ST_ElementTypeAt;

  Member Function ST_Round(p_dec_places_x In integer Default 8,
                           p_dec_places_y In integer Default null,
                           p_dec_places_z In integer Default 3,
                           p_dec_places_m In integer Default 3)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    v_ord          pls_integer;
    v_geom         mdsys.sdo_geometry; -- Copy geometry so it can be edited
    V_X_dec_places Integer := NVL(p_dec_places_x,SELF.dPrecision);
    V_Y_dec_places Integer := Nvl(p_dec_places_y,v_X_dec_places);
    V_Z_dec_places Integer := Nvl(p_dec_places_z,v_X_dec_places);
    v_m_dec_places Integer := NVL(p_dec_places_m,v_x_dec_places);
  Begin
    v_geom := SELF.geom;
    -- If point update differently to other shapes
    If ( SELF.geom.Sdo_Point Is Not Null ) Then
      v_geom.sdo_point.X := round( SELF.geom.sdo_point.x,v_x_dec_places);
      v_geom.Sdo_Point.Y := Round( SELF.geom.Sdo_Point.Y,v_y_dec_places);
      If ( SELF.ST_Dims() > 2 ) Then
        v_geom.sdo_point.z := round( SELF.geom.sdo_point.z,v_z_dec_places);
      End If;
    End If;
    -- Now let's round the ordinates
    If ( SELF.geom.sdo_ordinates is not null ) Then
      v_ord         := 0;
      <<while_vertex_to_process>>
      For v_i In 1..(SELF.geom.sdo_ordinates.COUNT/SELF.ST_Dims()) Loop
         v_ord := v_ord + 1;
         v_geom.sdo_ordinates(v_ord) := round(SELF.geom.sdo_ordinates(v_ord), v_x_dec_places);
         v_ord := v_ord + 1;
         v_geom.sdo_ordinates(v_ord) := round(SELF.geom.sdo_ordinates(v_ord), v_y_dec_places);
         If ( SELF.ST_Dims() >= 3 ) Then
            v_ord := v_ord + 1;
            v_geom.sdo_ordinates(v_ord) :=
                round(SELF.geom.sdo_ordinates(v_ord),
                      Case When SELF.ST_Lrs_Dim() in (0,4)
                           Then v_z_dec_places
                           When SELF.ST_Lrs_Dim() = 3
                           Then v_m_dec_places
                       End);
            if ( SELF.ST_Dims() > 3 ) Then
               v_ord := v_ord + 1;
               v_geom.sdo_ordinates(v_ord) :=
                round(SELF.geom.sdo_ordinates(v_ord),
                      v_m_dec_places);
            End If;
         End If;
      End Loop while_vertex_to_process;
    End If;
    Return &&INSTALL_SCHEMA..T_GEOMETRY(v_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_Round;

  Member Function ST_NumRings(p_ring_type in integer default 0
                               /* 0 = ALL; 1 = OUTER; 2 = INNER */ )
           Return Integer
  Is
    c_i_ring_type Constant pls_integer   := -20120;
    c_s_ring_type Constant VarChar2(100) := 'p_ring_type must be one of 0(ALL),1(OUTER),2(INNER) only.';
    v_elements    pls_integer := 0;
    v_ring_count  pls_integer := 0;
    v_etype       pls_integer;
  Begin
    If ( p_ring_type is null OR p_ring_type not in (0,1,2) ) Then
      raise_application_error(c_i_ring_type,c_s_ring_type);
    End If;
    If ( SELF.ST_hasDimension() = 2 /*Poly/Compound*/ ) Then
      return 0;
    End If;
    v_elements := ( ( SELF.geom.sdo_elem_info.COUNT / 3 ) - 1 );
    <<element_extraction>>
    FOR v_i IN 0 .. v_elements LOOP
        v_etype := SELF.geom.sdo_elem_info(v_i * 3 + 2);
        If ( ( v_etype in (1003,1005,2003,2005) and 0 = p_ring_type )
          OR ( v_etype in (1003,1005)           and 1 = p_ring_type )
          OR ( v_etype in (2003,2005)           and 2 = p_ring_type ) ) Then
           v_ring_count := v_ring_count + 1;
        End If;
    END LOOP element_extraction;
    Return v_ring_count;
  End ST_NumRings;

  Member Function ST_ElemInfo
           Return &&INSTALL_SCHEMA..T_ElemInfoSet pipelined
  Is
    v_elements pls_integer;
  Begin
    v_elements := ( ( SELF.geom.sdo_elem_info.COUNT / 3 ) - 1 );
    <<element_extraction>>
    For v_i IN 0 .. v_elements Loop
       PIPE ROW (&&INSTALL_SCHEMA..T_ElemInfo(SELF.geom.sdo_elem_info(v_i * 3 + 1),
                                 SELF.geom.sdo_elem_info(v_i * 3 + 2),
                                 SELF.geom.sdo_elem_info(v_i * 3 + 3))
                );
    End Loop element_extraction;
    Return;
  End ST_ElemInfo;

  Member Function ST_NumSubElements(p_subArcs in integer default 0)
           Return Integer
  Is
    c_i_sub_arcs     pls_integer   := -20121;
    c_s_sub_arcs     Constant VarChar2(100) := 'p_subArcs must be 0 (No) or 1 (Yes).';
    v_elements       pls_integer := 0;
    v_sub_elem_count pls_integer := 0;
    v_offset         pls_integer := 0;
    v_nCoords        pls_integer := 0;
    -- sdo_elem_info triplet
    v_etype          pls_integer := 0;
    v_interpretation pls_integer := 0;
    v_compound_count pls_integer := 0;
  Begin
    If ( SELF.ST_Dimension() = 0 ) Then
       return 0;
    End If;
    if ( p_subArcs is null or p_subArcs not in (0,1) ) Then
      raise_application_error(c_i_sub_arcs,c_s_sub_arcs,true);
    End If;
    v_elements := ( ( SELF.geom.sdo_elem_info.COUNT / 3 ) - 1 );
    v_compound_count := 0;
    <<element_extraction>>
    FOR v_i IN 0 .. v_elements LOOP
        v_offset         := SELF.geom.sdo_elem_info(v_i * 3 + 1);
        v_etype          := SELF.geom.sdo_elem_info(v_i * 3 + 2);
        v_interpretation := SELF.geom.sdo_elem_info(v_i * 3 + 3);
        If ( v_etype in (4,1005,2005) ) Then
           -- Compound elements with sub-elements follow
           v_sub_elem_count := v_sub_elem_count + v_interpretation;
           v_compound_count := v_interpretation;
        ElsIf ( v_interpretation = 2 ) Then
           If (p_subArcs = 0) Then
              -- Only count if compound sub-element
              if ( v_compound_count > 0 ) Then
                 v_sub_elem_count := v_sub_elem_count + 1;
                 v_compound_count := v_compound_count - 1;
              End If;
           Else
             -- Always count up the number arcs whether compound or not
             if ( v_i = v_elements /* last triplet */ ) then
                v_nCoords := (SELF.geom.sdo_ordinates.count - v_offset ) / SELF.ST_Dims();
             else
                v_nCoords := (SELF.geom.sdo_elem_info((v_i+1) * 3 + 1) - v_offset ) / SELF.ST_Dims() ;
             end if;
             v_sub_elem_count := v_sub_elem_count + ((v_nCoords-1) / 2);
             -- For sub-element of compound we have already counted one
             if ( v_compound_count > 0 ) Then
                 v_sub_elem_count := v_sub_elem_count - 1;
             End If;
          End If;
        End If;
    END LOOP element_extraction;
    Return v_sub_elem_count;
  End ST_NumSubElements;

  Member Function ST_NumInteriorRing
         Return Integer
  Is

  Begin
    Return SELF.ST_NumRings(p_ring_type => 2);
  End ST_NumInteriorRing;

  Member Function ST_Dump( p_subElements IN integer default 0 )
           Return &&INSTALL_SCHEMA..T_Geometries Pipelined
  IS
     v_i               PLS_INTEGER := 0;
     v_count           PLS_INTEGER := 0;
     v_element         PLS_INTEGER := 0;
     v_Num_Elements    PLS_INTEGER := 0;
     v_subelement_geom mdsys.sdo_geometry;
     v_extract_geom    mdsys.sdo_geometry;
     v_ord_count       PLS_INTEGER := 0;
     v_ordinates       mdsys.sdo_ordinate_array;
     v_vertices        mdsys.vertex_set_type;
     v_subelements     Boolean := case when p_subelements = 0 then false else true end;

     --PRAGMA INLINE (copyOrdinates, 'YES');
     Function copyOrdinates(p_ords  in mdsys.sdo_ordinate_array,
                            p_first in integer,
                            p_last  in integer)
     Return mdsys.sdo_ordinate_array
     As
       v_ords mdsys.sdo_ordinate_array := new mdsys.sdo_ordinate_array();
     Begin
       v_ords.extend((p_last-p_first)+1);
       for i in p_first .. p_last loop
         v_ords(i-p_first+1) := p_ords(i);
       end loop;
       return v_ords;
     End copyOrdinates;

  Begin
    IF ( ( SELF.ST_GType() = 1 ) AND ( SELF.ST_NumElements() = 0 ) ) THEN
       -- ie single point geometry
       PIPE ROW(&&INSTALL_SCHEMA..T_GEOMETRY_ROW(1,SELF.geom,SELF.tolerance,SELF.dPrecision,SELF.projected));
    ELSIF ( SELF.ST_GType() = 5 ) THEN
       -- ie multipoint
       v_vertices := mdsys.sdo_util.getVertices(SELF.geom);
       <<for_all_vertices>>
       FOR v_i IN v_vertices.FIRST..v_vertices.LAST LOOP
         PIPE ROW(&&INSTALL_SCHEMA..T_GEOMETRY_ROW(
                     v_i,
                     mdsys.sdo_geometry(( SELF.ST_Dims() * 1000 ) + 1,
                                        SELF.ST_SRID(),
                                        mdsys.sdo_point_type(v_vertices(v_i).x,
                                                             v_vertices(v_i).y,
                                                             v_vertices(v_i).z),
                                        NULL,NULL),
                     SELF.tolerance,
                     SELF.dPrecision,
                     SELF.projected
                     ));
       END LOOP for_all_vertices;
    ELSE -- linestrings and polygons
       v_element := 0;
       v_Num_Elements := case when SELF.ST_GType() in (2,3) then 1 else SELF.ST_NumElements() end;
       <<while_all_elements>>
       WHILE ( v_element < v_Num_Elements ) LOOP
         v_element := v_element + 1;
         -- DEBUG dbms_output.put_line('Extracting element ' || v_element || ' of ' || v_Num_Elements);
         -- Extract element with all sub-elements
         v_extract_geom := case when v_Num_Elements = 1
                                then SELF.GEOM
                                else mdsys.sdo_util.Extract(SELF.geom,v_element,0)
                            end;
         -- The rings of a polygon are subelements that Extract can handle.
         -- But if a ring is a compound object then Extract cannot handle it.
         -- We will leave the extraction of a ring as a whole polygon to ExtractPolygon
         -- Does user want to further break down geometry into its basic subElements?
         IF ( v_subelements ) THEN
             -- DEBUG dbms_output.put_line('ST_Dump(1)');
             v_ord_count := v_extract_geom.sdo_ordinates.COUNT;
             FOR rec IN (select rownum as id, f.interpretation,
                                case when f.arccount = 0 then first_ord else first_ord + (t.IntValue-1)*2*SELF.ST_Dims()      end as start_ord,
                                case when f.arccount = 0 then end_ord   else first_ord + (t.IntValue*2   *SELF.ST_Dims()) + 2 end as end_ord,
                                t.IntValue as arcCounter
                           from (SELECT first_ord, end_ord, interpretation,
                                        (end_ord - first_ord)                as ordCount,
                                        (end_ord - first_ord)/SELF.ST_Dims() as coordCount,
                                        case when interpretation = 2
                                             then ((end_ord-first_ord)/SELF.ST_Dims()-1)/2
                                             else 0
                                         end as arcCount
                                   from (SELECT e.offset as first_ord, e.etype, e.interpretation,
                                                (case when (lead(e.offset,1) over (order by e.offset)) is not null
                                                      then (lead(e.offset,1) over (order by e.offset)) + SELF.ST_Dims()
                                                      else v_ord_count + 1
                                                  end) as end_ord
                                           FROM TABLE( &&INSTALL_SCHEMA..T_GEOMETRY(v_extract_geom).ST_ElemInfo()) e
                                          WHERE e.etype not in (4,1005,2005)
                                         ) b
                                  ) f,
                                  TABLE( &&INSTALL_SCHEMA..TOOLS.generate_series(1,(case when f.arcCount=0 then 1 else f.arcCount end),1)) t
                        ) LOOP
                 v_ordinates := mdsys.sdo_ordinate_array();
                 -- DEBUG dbms_output.put_line('rec.id=' || rec.id ||' rec.start_ord=' || rec.start_ord || ' rec.end_ord-1=' || (rec.end_ord-1) || 'TotalOrds=' || (rec.end_ord-rec.start_ord));
                 v_ordinates := copyOrdinates(v_extract_geom.sdo_ordinates,rec.start_ord,rec.end_ord-1);
                 -- DEBUG dbms_output.put_line(' writing ' || case when rec.interpretation=2 then 'CircularArc' else 'VertexConnected' end);
                 PIPE ROW(&&INSTALL_SCHEMA..T_GEOMETRY_ROW(
                                rec.id,
                                mdsys.sdo_geometry(v_extract_geom.sdo_gtype,
                                                   SELF.geom.sdo_srid,
                                                   null,
                                                   mdsys.sdo_elem_info_array(1,2,rec.interpretation),
                                                   v_ordinates),
                                SELF.tolerance,
                                SELF.dPrecision,
                                SELF.projected));
                 v_ordinates := new mdsys.sdo_ordinate_array();
             END LOOP;
         ELSE
           -- DEBUG dbms_output.put_line('ST_Dump(0)');
           IF ( SELF.ST_GType() in (3,7) ) THEN
              SELECT COUNT(*)
                INTO v_count
                FROM TABLE( &&INSTALL_SCHEMA..T_GEOMETRY(v_extract_geom).ST_ElemInfo()) e
               WHERE e.etype in (1003,2003,1005,2005);
              IF ( v_count > 1 ) THEN
                FOR v_subelem_count IN 1..v_count LOOP
                    v_subelement_geom := mdsys.sdo_util.extract(v_extract_geom,v_element,v_subelem_count);
                    PIPE ROW(&&INSTALL_SCHEMA..T_GEOMETRY_ROW(v_subelem_count,v_subelement_geom,SELF.Tolerance,SELF.dPrecision,SELF.projected));
                END LOOP;
              ELSE
                -- Always write out a single element
                PIPE ROW(&&INSTALL_SCHEMA..T_GEOMETRY_ROW(v_element,v_extract_geom,SELF.Tolerance,SELF.dPrecision,SELF.projected));
              END IF;
           ELSE
             -- Always write out the higher element
             PIPE ROW(&&INSTALL_SCHEMA..T_GEOMETRY_ROW(v_element,v_extract_geom,SELF.Tolerance,SELF.dPrecision,SELF.projected));
           END IF;
         END IF;
       END LOOP while_all_elements;
    END IF;
    RETURN;
  END ST_Dump;

  Member Function ST_Extract(p_geomType IN VARCHAR2)
           Return &&INSTALL_SCHEMA..T_Geometry
  IS
    c_i_geom_extract_type Constant pls_integer   := -20120;
    c_s_geom_extract_type Constant VarChar2(100) := 'p_geomType must be one of: POINT,ST_POINT,LINE,LINESTRING,ST_LINESTRING,POLY,POLYGON,ST_POLYGON';
    v_element             number;
    v_elements            number;
    v_geom_type           varchar2(20);
    v_geom                mdsys.sdo_geometry;
    v_extract_shape       mdsys.sdo_geometry;
  Begin
    IF ( SELF.ST_Gtype() <> 4 ) Then
       RETURN SELF;
    END IF;
    IF ( UPPER(NVL(p_geomType,'NULL')) NOT IN ('POINT','ST_POINT','LINE','LINESTRING','ST_LINESTRING','POLY','POLYGON','ST_POLYGON') ) Then
      raise_application_error(c_i_geom_extract_type,
                              c_s_geom_extract_type,true);
    END IF;
    v_geom_type := CASE WHEN UPPER(p_geomType) IN ('POINT','ST_POINT')                  THEN 'POINT'
                        WHEN UPPER(p_geomType) IN ('LINE','LINESTRING','ST_LINESTRING') THEN 'LINE'
                        WHEN UPPER(p_geomType) IN ('POLY','POLYGON','ST_POLYGON')       THEN 'POLY'
                    END;
    v_elements  := SELF.ST_NumElements();
    FOR v_element IN 1..v_elements LOOP
      -- Extract element with all sub-elements
      v_extract_shape := mdsys.sdo_util.Extract(SELF.geom,v_element,0);
      IF ( ( v_geom_Type = 'LINE'  AND v_extract_shape.get_gtype() = 2 )
           OR
           ( v_geom_Type = 'POINT' AND v_extract_shape.get_gtype() = 1 )
           OR
           ( v_geom_Type = 'POLY'  AND v_extract_shape.get_gtype() = 3 ) ) Then
        IF ( v_geom is null ) Then
           v_geom := v_extract_shape;
        ELSE
           v_geom := case
                     when v_extract_shape.get_gtype() = 2
                     then MDSYS.SDO_UTIL.CONCAT_LINES(v_geom, v_extract_shape)
                     else MDSYS.SDO_UTIL.APPEND(v_geom,v_extract_shape)  -- Probably should use ST_Append where DIms <> 2
                     end;
        END IF;
      END IF;
    END LOOP;
    Return &&INSTALL_SCHEMA..T_GEOMETRY(v_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  END ST_Extract;

  /**
  * ST_Extract
  * Extract geometries in a Collection/MPoly/MLine
  **/
  Member Function ST_Extract
           Return &&INSTALL_SCHEMA..T_Geometries Pipelined
  IS
     v_geom mdsys.sdo_geometry;
  BEGIN
    If ( SELF.ST_gType() not in (4,5,6,7) ) Then
      PIPE ROW (&&INSTALL_SCHEMA..T_GEOMETRY_ROW(1,SELF.geom,SELF.tolerance,SELF.dPrecision,SELF.projected));
    Else
      <<process_all_elements>>
      FOR v_elem_no IN 1..MDSYS.SDO_UTIL.GETNUMELEM(SELF.geom) LOOP
        PIPE ROW (&&INSTALL_SCHEMA..T_GEOMETRY_ROW(v_elem_no,MDSYS.SDO_UTIL.EXTRACT(SELF.geom,v_elem_no,0),SELF.tolerance,SELF.dPrecision,SELF.projected));
      END LOOP process_all_elements;
    End If;
    RETURN;
  END ST_Extract;

  Member Function ST_FilterRings(p_area in number,
                                 p_unit in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  IS
     v_area         number;
     v_num_elems    pls_integer;
     v_num_rings    pls_integer;
     v_ring         &&INSTALL_SCHEMA..T_GEOMETRY;
     v_return_tgeom &&INSTALL_SCHEMA..T_GEOMETRY;

    --PRAGMA INLINE (AddToGeometry, 'YES');
    Procedure AddToGeometry
    As
      v_num_elements pls_integer;
      v_offset       pls_integer;
      v_base_index   pls_integer;
    Begin
      -- DEBUG dbms_output.put_line('<ST_FilterRings: AddToGeometry> v_return_tgeom is null ' || case when v_return_tgeom is null then 'YES' else 'NO' end);
      IF  ( v_return_tgeom is null ) THEN
        v_return_tgeom := &&INSTALL_SCHEMA..T_Geometry(
                            v_ring.geom,
                            SELF.Tolerance, SELF.dPrecision, SELF.Projected
                          );
      ELSE
        -- DEBUG dbms_output.put_line('Append elem info of ring being processed to result geom..');
        v_num_elements := (v_ring.geom.sdo_elem_info.COUNT / 3) - 1;
        v_base_index   := v_return_tgeom.geom.sdo_elem_info.COUNT;
        <<for_all_elements>>
        for v_i IN 0 .. v_num_elements LOOP
          v_offset := ( v_i * 3 ) + 1;
          v_return_tgeom.geom.sdo_elem_info.EXTEND(3);
          v_return_tgeom.geom.sdo_elem_info(v_base_index + v_offset)   := v_return_tgeom.geom.sdo_ordinates.COUNT + v_ring.geom.sdo_elem_info(v_offset);
          v_return_tgeom.geom.sdo_elem_info(v_base_index + v_offset+1) := v_ring.geom.sdo_elem_info(v_offset+1);
          v_return_tgeom.geom.sdo_elem_info(v_base_index + v_offset+2) := v_ring.geom.sdo_elem_info(v_offset+2);
        end loop for_all_elements;
        -- DEBUG dbms_output.put_line('Append sdo_ordinates of ring being processed to result geom.');
        v_base_index := v_return_tgeom.geom.sdo_ordinates.COUNT;
        v_return_tgeom.geom.sdo_ordinates.EXTEND(v_ring.geom.sdo_ordinates.COUNT);
        <<for_all_ords>>
        for v_ord IN 1 .. v_ring.geom.sdo_ordinates.COUNT LOOP
          v_return_tgeom.geom.sdo_ordinates(v_base_index + v_ord) := v_ring.geom.sdo_ordinates(v_ord);
        end loop for_all_ords;
      End If;
      -- DEBUG dbms_output.put_line('</AddToGeometry> v_return_tgeom: ' || &&INSTALL_SCHEMA..PRINT.sdo_geometry(v_return_tgeom.geom,SELF.dPrecision));
    END AddToGeometry;

  BEGIN
    If ( SELF.ST_gType() not in (3,7) or p_area is null ) Then
       Return SELF;
    End If;
    v_num_elems := SELF.ST_NumElements();  -- Count 1003 geometries
    <<process_all_elements>>
    FOR v_elem_no IN 1..v_num_elems LOOP
        v_num_rings := &&INSTALL_SCHEMA..T_GEOMETRY(MDSYS.SDO_UTIL.EXTRACT(SELF.geom,v_elem_no,0)).ST_NumRings();
        <<process_all_rings>>
        FOR v_ring_no IN 1..v_num_rings LOOP
            v_ring := &&INSTALL_SCHEMA..T_GEOMETRY(
                        MDSYS.SDO_UTIL.EXTRACT(SELF.geom,v_elem_no,v_ring_no),
                        SELF.Tolerance,SELF.dPrecision,SELF.Projected);
            IF ( v_ring is not null and v_ring.geom is not null) Then
               -- If p_unit is null it is the same as not having it in the function call
               v_area := v_ring.ST_Area(p_unit=>p_unit);
               If ( v_area > p_area ) Then
                  IF ( v_ring_no > 1 ) THEN -- inner ring. EXTRACT reverses 2003 to make it 1003 we want it back as 2003
                    v_ring := v_ring.ST_Reverse_Geometry();
                    -- DEBUG dbms_output.put_line('v_ring (Reversed): ' || &&INSTALL_SCHEMA..PRINT.sdo_geometry(v_ring.geom,SELF.dPrecision));
                  End If;
                  -- Add Ring no matter what it is to v_return_geom.
                  AddToGeometry();
               End If;
            End If;
        END LOOP process_all_rings;
    END LOOP process_all_elements;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(v_return_tgeom.geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  END ST_FilterRings;

  Member Function ST_RemoveInnerRings
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
     v_vertices        mdsys.vertex_set_type;
     v_ords            mdsys.sdo_ordinate_array :=  new mdsys.sdo_ordinate_array(null);
     v_num_dims        pls_integer;
     v_num_geoms       pls_integer;
     v_actual_etype    pls_integer;
     v_ring_elem_count pls_integer := 1;
     v_exterior_ring   mdsys.sdo_geometry;
     v_num_rings       pls_integer;
     v_geom            sdo_geometry;
     v_ok              number;
  Begin
    If ( SELF.ST_Gtype not in (3,7) ) Then
       RETURN SELF;
    End If;
    IF ( SELF.ST_NumInteriorRing() = 0 ) THEN
       Return SELF;
    END IF;
    /* The processing below assumes the structure of a polygon/multipolygon
       is correct and passes sdo_geom.validate_geometry */
    v_num_dims  := SELF.ST_Dims();
    v_num_geoms := SELF.ST_NumGeometries();  -- Gets number of 1003 geometries
    <<all_elements>>
    FOR v_geom_no IN 1..v_num_geoms LOOP
        -- Process all rings in the extracted single - 2003 - polygon
        v_exterior_ring := MDSYS.SDO_UTIL.EXTRACT(SELF.geom,v_geom_no,1);
        IF ( v_exterior_ring is not null ) Then
          v_geom := case when ( v_geom is null ) then v_exterior_ring else mdsys.sdo_util.APPEND(v_geom,v_exterior_ring) end;
        END IF;
    END LOOP all_elements;
    Return &&INSTALL_SCHEMA..T_GEOMETRY(v_geom,SELF.tolerance,SELF.dPrecision,SELF.projected);
  End ST_RemoveInnerRings;

  Member Function ST_ExtractRings
          Return &&INSTALL_SCHEMA..T_GEOMETRIES PIPELINED
  IS
     v_num_rings pls_integer;
     v_ring      mdsys.sdo_geometry;
  BEGIN
    If ( SELF.ST_gType() not in (3,7) ) Then
       return;
    End If;
    <<process_all_elements>>
    FOR v_elem_no IN 1..MDSYS.SDO_UTIL.GETNUMELEM(SELF.geom) LOOP
        v_num_rings := &&INSTALL_SCHEMA..t_geometry(MDSYS.SDO_UTIL.EXTRACT(SELF.geom,v_elem_no,0)).ST_NumRings(0);
        If ( v_num_rings = 1 ) Then
          PIPE ROW (&&INSTALL_SCHEMA..T_GEOMETRY_ROW(1,MDSYS.SDO_UTIL.EXTRACT(SELF.geom,v_elem_no,1),SELF.tolerance,SELF.dPrecision,SELF.projected));
        Else
          <<process_all_rings>>
          FOR v_ring_no IN 1..v_num_rings LOOP
              v_ring := MDSYS.SDO_UTIL.EXTRACT(SELF.geom,v_elem_no,v_ring_no);
              IF ( v_ring is not null ) Then
                 PIPE ROW(&&INSTALL_SCHEMA..T_GEOMETRY_ROW(v_ring_no,v_ring,SELF.tolerance,SELF.dPrecision,SELF.projected));
              End If;
          END LOOP process_all_rings;
        End If;
    END LOOP process_all_elements;
    RETURN;
  END ST_ExtractRings;

  Member Function ST_ExteriorRing
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  IS
   v_numExteriorRing pls_integer;
   v_eRing           mdsys.sdo_geometry;
   v_geom            mdsys.sdo_geometry;
  BEGIN
    If ( SELF.ST_gType() not in (3,7) ) Then
       return null;
    End If;
    v_numExteriorRing := MDSYS.SDO_UTIL.GETNUMELEM(SELF.geom);
    IF ( v_numExteriorRing = 0 ) Then
      Return null;
    End If;
    v_eRing := MDSYS.SDO_UTIL.EXTRACT(SELF.geom,1,1);
    IF ( v_numExteriorRing > 0 ) Then
      FOR v_elem_no IN 2..v_numExteriorRing LOOP
        v_geom  := MDSYS.SDO_UTIL.EXTRACT(SELF.geom,v_elem_no,1);
        v_eRing := MDSYS.SDO_UTIL.APPEND(v_eRing,v_geom);
      END LOOP;
    End If;
    -- Extract only first ring even if multipolygon
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(v_eRing,SELF.tolerance,SELF.dPrecision,SELF.projected);
  END ST_ExteriorRing;

  Member Function ST_Boundary
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  IS
   -- sdo_geometry('MULTIPOLYGON(((0 0,10 0,10 10,0 10,0 0)),((20 20, 40 20, 40 40, 20 40,20 20)))',null);
   -- MULTILINESTRING ((20 20, 40 20, 40 40, 20 40, 20 20), (0 0, 10 0, 10 10, 0 10, 0 0))
   v_eRing &&INSTALL_SCHEMA..t_geometry;
   v_geom  mdsys.sdo_geometry;
  BEGIN
    v_eRing := SELF.ST_ExteriorRing();
    IF ( v_eRing is null ) Then
      Return NULL;
    End If;
    -- Convert to LineString....
    v_geom := mdsys.sdo_util.PolygonToLine(v_eRing.GEOM);
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(v_geom,SELF.tolerance,SELF.dPrecision,SELF.projected);
  END ST_Boundary;

  Member Function ST_Vertices
           Return &&INSTALL_SCHEMA..T_Vertices Pipelined
  Is
    v_vertices  mdsys.vertex_set_type;
  Begin
    v_vertices := mdsys.sdo_util.getVertices(SELF.geom);
    <<extract_all_vertices>>
    FOR v_id IN 1..v_vertices.COUNT LOOP
       PIPE ROW(&&INSTALL_SCHEMA..T_Vertex(
                     p_vertex    => v_vertices(v_id),
                     p_id        => v_id,
                     p_sdo_gtype => SELF.ST_Sdo_Gtype(),
                     p_sdo_srid  => SELF.ST_SRID()
                ) );
    END LOOP extract_all_vertices;
    RETURN;
  End ST_Vertices;

  Member Function ST_Segmentize(p_filter       in varchar2  default 'ALL',
                                p_id           in integer   default null,
                                p_vertex       in &&INSTALL_SCHEMA..T_Vertex default null,
                                p_filter_value in number    default null,
                                p_start_value  in number    default null,
                                p_end_value    in number    default null,
                                p_unit         in varchar2  default null)
           Return &&INSTALL_SCHEMA..T_Segments
  Is
    c_i_filter_value   Constant pls_integer   := -20101;
    c_s_filter_value   Constant VarChar2(100) := 'p_option value (*VALUE*) must be ALL, DISTANCE, ID, RANGE or MEASURE.';
    c_i_distance_value Constant pls_integer   := -20102;
    c_s_distance_value Constant VarChar2(100) := 'If p_option is DISTANCE, then p_vertex must not be NULL.';
    c_i_id_value       Constant pls_integer   := -20102;
    c_s_id_value       Constant VarChar2(100) := 'If p_option is ID, then p_id must not be NULL.';

    v_filter       varchar2(20)   := NVL(UPPER(p_filter),'NULL');
    v_dump         pls_integer    := 0;
    v_mDimension   pls_integer    := SELF.ST_LRS_Dim();
    v_num_elements pls_integer    := 0;
    v_num_rings    pls_integer    := 0;
    v_segment_id   pls_integer    := 0;
    v_id           pls_integer    := 0;
    v_total_length number         := 0.0;
    v_min_distance number         := 9999999999999999999999999;
    v_element      mdsys.sdo_geometry;
    v_ring         &&INSTALL_SCHEMA..T_GEOMETRY;
    v_geometries   &&INSTALL_SCHEMA..T_Geometries;
    v_min_Segment  &&INSTALL_SCHEMA..T_Segment;
    v_segments     &&INSTALL_SCHEMA..T_Segments := NEW &&INSTALL_SCHEMA..T_Segments(&&INSTALL_SCHEMA..T_Segment());

    Function segmentizeElement(p_segment_id     in out nocopy pls_integer,
                               p_element_no     in integer,
                               p_sub_element_no in integer,
                               p_geometry       in mdsys.sdo_geometry,
                               p_dims           in integer default 2)
    Return &&INSTALL_SCHEMA..T_Segments
    As
        v_compound       boolean := false;
        v_ll             &&INSTALL_SCHEMA..t_vertex;
        v_ur             &&INSTALL_SCHEMA..t_vertex;
        v_segment        &&INSTALL_SCHEMA..T_Segment;
        v_sub_elements   pls_integer := 0;
        v_nArcs          pls_integer := 0;
        v_element_no     pls_integer := 1;
        v_segment_no     pls_integer := 1;
        v_coord_no       pls_integer := 1;
        v_ord            pls_integer := 0;
        v_offset         pls_integer := 0;
        v_nOffset        pls_integer := 0;
        v_nCoords        pls_integer := 0;
        -- sdo_elem_info triplet
        v_etype          pls_integer := 0;
        v_interpretation pls_integer := 0;
        v_compound_count pls_integer := 0;
        v_dims           pls_integer := NVL(p_dims,2);
        v_point_gtype    pls_integer := TRUNC(NVL(p_geometry.sdo_gtype,2001)/10)*10+1;

        Procedure AddSegmentToOutput(p_segment_id   in pls_integer,
                                     p_Segments     in out nocopy &&INSTALL_SCHEMA..T_Segments,
                                     p_total_length in out nocopy number,
                                     p_min_distance in out nocopy number,
                                     p_min_Segment  in out nocopy &&INSTALL_SCHEMA..T_Segment,
                                     p_Segment      in            &&INSTALL_SCHEMA..T_Segment )
        As
           v_distance number;
        Begin
          -- Check if this segment is needed
          IF ( v_filter = 'ID' And p_segment_id = v_id ) THEN
              p_Segments.EXTEND(1);
              p_Segments(v_segments.COUNT) := new &&INSTALL_SCHEMA..T_Segment(p_Segment);
          ELSIF ( v_filter = 'ALL' ) THEN
              p_Segments.EXTEND(1);
              p_Segments(v_segments.COUNT) := new &&INSTALL_SCHEMA..T_Segment(p_Segment);
          ELSIF ( v_Filter = 'DISTANCE' ) THEN
            -- Snap to closest segment
            v_distance := p_Segment.ST_Distance(p_vertex    => p_vertex,
                                                p_unit      => p_unit);
            If ( v_distance = 0 ) THEN
              -- Can't get any more min distance than 0!
              -- DEBUG dbms_output.put_line('ST_Segmentize.v_distance=0');
              p_Segments.EXTEND(1);
              p_Segments(v_segments.COUNT) := new &&INSTALL_SCHEMA..T_Segment(p_Segment);
            END IF;
            IF (v_distance <  v_min_distance) Then
              p_min_distance := v_distance;
              p_min_Segment  := new &&INSTALL_SCHEMA..T_Segment(p_Segment);
              -- DEBUG dbms_output.put_line('ST_Segmentize.p_min_Segment='||case when p_min_Segment is null then 'NULL' else p_min_Segment.ST_AsText() end);
            END IF;
          ELSIF ( v_filter = 'MEASURE' ) THEN
            IF ( p_filter_value between case v_mDimension
                                             when 3 then p_Segment.startCoord.z
                                             when 4 then p_Segment.startCoord.w
                                             else p_total_length
                                         end
                                    and case v_mDimension
                                             when 3 then p_Segment.endCoord.z
                                             when 4 then p_Segment.endCoord.w
                                             else p_total_length + p_segment.ST_Length(p_unit=>p_unit)
                                         end) THEN
              p_Segments.EXTEND(1);
              p_Segments(p_Segments.COUNT) := new &&INSTALL_SCHEMA..T_Segment(p_Segment);
            END IF;
          ELSIF ( v_filter = 'RANGE' ) THEN
            IF ( Greatest(case v_mDimension
                               when 3 then p_Segment.startCoord.z
                               when 4 then p_Segment.startCoord.w
                               else p_total_length
                            end,p_start_value)
                  < Least(case v_mDimension
                               when 3 then p_Segment.endCoord.z
                               when 4 then p_Segment.endCoord.w
                               else p_total_length + p_segment.ST_Length(p_unit=>p_unit)
                           end,p_end_value) ) THEN
              -- Now save if Measure range overlaps user input range...
              -- DEBUG dbms_output.put_line('Greatest('||Greatest(case v_mDimension when 3 then v_segment.startCoord.z when 4 then v_segment.startCoord.w else -99999999 end,v_user_start_measure)||
              --                           ') < Least('||   Least(case v_mDimension when 3 then v_segment.endCoord.z   when 4 then v_segment.endCoord.w   else 9999999999 end,v_user_end_measure)||')');
              p_Segments.EXTEND(1);
              p_Segments(v_segments.COUNT) := new &&INSTALL_SCHEMA..T_Segment(p_Segment);
              -- DEBUG dbms_output.put_line('v_segment('||segId||').ST_AsText(4)='||v_segments(v_segments.COUNT).ST_AsText(4));
            END IF;
          ELSIF ( v_filter = 'X' ) THEN
            IF ( p_filter_value
                 between Least   (p_Segment.startCoord.X,
                                  p_Segment.endCoord.X,
                                  case when p_segment.midCoord is null then 99999999999999 else p_segment.midCoord.x end)
                     and Greatest(p_Segment.startCoord.x,
                                  p_Segment.endCoord.X,
                                  case when p_segment.midCoord is null then -99999999999999 else p_segment.midCoord.x end)
              ) THEN
              p_Segments.EXTEND(1);
              p_Segments(p_Segments.COUNT) := new &&INSTALL_SCHEMA..T_Segment(p_Segment);
            END IF;
          ELSIF ( v_filter = 'Y' ) THEN
            IF ( p_filter_value
                 between Least   (p_Segment.startCoord.Y,
                                  p_Segment.endCoord.Y,
                                  case when p_segment.midCoord is null then 99999999999999 else p_segment.midCoord.Y end)
                     and Greatest(p_Segment.startCoord.Y,
                                  p_Segment.endCoord.Y,
                                  case when p_segment.midCoord is null then -99999999999999 else p_segment.midCoord.Y end)
              ) THEN
              p_Segments.EXTEND(1);
              p_Segments(p_Segments.COUNT) := new &&INSTALL_SCHEMA..T_Segment(p_Segment);
            END IF;
          END IF;
          p_total_length := p_total_length + p_segment.ST_Length(p_unit=>p_unit);
        End addSegmentToOutput;

    Begin
        -- DEBUG dbms_output.put_line('SegmentizeElement('||p_element_no ||','||p_sub_element_no||','||p_dims||',GTYPE:'|| p_geometry.sdo_gtype||')');
        -- If compound ring or linestring the whole element will be so
        If ( p_geometry.sdo_elem_info(2) in (4,1005,2005) ) Then
           v_compound := true;
           v_sub_elements := p_geometry.sdo_elem_info(3);
        Else
           v_compound := false;
           v_sub_elements := (( p_geometry.sdo_elem_info.COUNT / 3 ) - 1);
        End If;
        <<element_extraction>>
        FOR v_sub_element IN 0 .. v_sub_elements LOOP
           v_offset := p_geometry.sdo_elem_info(v_sub_element * 3 + 1);
           v_etype  := p_geometry.sdo_elem_info(v_sub_element * 3 + 2);
           if (v_etype not in (4,1005,2005) ) Then
             v_interpretation := p_geometry.sdo_elem_info(v_sub_element * 3 + 3);
             If ( v_sub_element = v_sub_elements /* last triplet */ ) then
                v_nOffset := p_geometry.sdo_ordinates.count + 1;
             else
                v_nOffset := p_geometry.sdo_elem_info((v_sub_element+1) * 3 + 1);
             end if;
             -- If compound element and v_sub_element count > 1
             -- ""The last point of a subelement is the first point of the next subelement, and must not be repeated.""
             If ( v_compound and v_sub_element < v_sub_elements ) Then
                -- If so, shift offset to next coord
                v_nOffset := v_nOffset + v_dims;
             End If;
             v_nCoords := (v_nOffset - v_offset) / v_dims;
             -- Ignore compound elements as they don't reference physical elements
             If ( v_interpretation = 1 ) Then  -- Stroked Linestring
                <<All_Ords>>
                For v_coord In 1..(v_nCoords-1) loop
                   v_ord          := v_offset + (v_coord-1)*v_dims;
                   p_segment_id   := p_segment_id + 1;
                   v_segment      := &&INSTALL_SCHEMA..T_Segment (
                       element_id    => p_element_no,
                       subelement_id => p_sub_element_no,
                       Segment_id    => case when v_filter = 'ID' And p_segment_id = v_id then p_segment_id else v_segment_no end,
                       startCoord    => NEW
                         &&INSTALL_SCHEMA..T_Vertex(
                           p_x         => p_geometry.sdo_ordinates(v_ord),
                           p_y         => p_geometry.sdo_ordinates(v_ord+1),
                           p_z         => case when v_dims>2 then p_geometry.sdo_ordinates(v_ord+2) else null end,
                           p_w         => case when v_dims>3 then p_geometry.sdo_ordinates(v_ord+3) else null end,
                           p_id        => v_coord_no,
                           p_sdo_gtype => v_point_gtype,
                           p_sdo_srid  => p_geometry.sdo_srid
                         ) ,
                       midCoord      => NULL,
                       endCoord      => NEW
                         &&INSTALL_SCHEMA..T_Vertex(
                           p_x         => p_geometry.sdo_ordinates(v_ord+v_dims),
                           p_y         => p_geometry.sdo_ordinates(v_ord+v_dims+1),
                           p_z         => case when v_dims>2 then p_geometry.sdo_ordinates(v_ord+v_dims+2) else null end,
                           p_w         => case when v_dims>3 then p_geometry.sdo_ordinates(v_ord+v_dims+3) else null end,
                           p_id        => V_COORD_NO + 1,
                           p_sdo_gtype => v_point_gtype,
                           p_sdo_srid  => p_geometry.sdo_srid
                         ),
                       sdo_gtype     => p_geometry.sdo_gtype,
                       sdo_srid      => p_geometry.sdo_srid,
                       projected     => SELF.projected,
                       PrecisionModel=> &&INSTALL_SCHEMA..T_PrecisionModel(XY=>SELF.dPrecision,Z=>SELF.dPrecision,W=>SELF.dPrecision,tolerance=>SELF.tolerance)
                   );
                   AddSegmentToOutput(p_segment_id   => p_segment_id,
                                      p_Segments     => v_segments,
                                      p_total_length => v_total_length,
                                      p_min_distance => v_min_distance,
                                      p_min_Segment  => v_min_Segment,
                                      p_Segment      => v_segment
                                   );
                   IF ( v_filter = 'ID' And p_segment_id = v_id ) THEN
                     RETURN v_segments;
                   END If;
                   v_segment_no := v_segment_no + 1;
                   v_coord_no   := v_coord_no + 1;
                End loop All_Ords;
              ElsIf ( v_interpretation = 2 ) Then
                v_nArcs := ((v_nCoords-1) / 2);  -- 3 for first, then 2, 2, 2 etc.
                <<all_arcs>>
                for v_e in 1..v_nArcs loop
                  p_segment_id   := p_segment_id + 1;
                  v_segment      := &&INSTALL_SCHEMA..T_Segment (
                      element_id    => p_element_no,
                      subelement_id => p_sub_element_no,
                      Segment_id    => case when v_filter = 'ID' And p_segment_id = v_id then p_segment_id else v_segment_no end,
                      startCoord    => new
                        &&INSTALL_SCHEMA..T_Vertex(
                          p_x         => p_geometry.sdo_ordinates(v_offset),
                          p_y         => p_geometry.sdo_ordinates(v_offset+1),
                          p_z         => case when v_dims>2 then p_geometry.sdo_ordinates(v_offset+2) else null end,
                          p_w         => case when v_dims>3 then p_geometry.sdo_ordinates(v_offset+3) else null end,
                          p_id        => v_coord_no,
                          p_sdo_gtype => v_point_gtype,
                          p_sdo_srid  => p_geometry.sdo_srid
                        ),
                      midCoord      => new
                        &&INSTALL_SCHEMA..T_Vertex(
                          p_x         => p_geometry.sdo_ordinates(v_offset+v_dims),
                          p_y         => p_geometry.sdo_ordinates(v_offset+v_dims+1),
                          p_z         => case when v_dims>2 then p_geometry.sdo_ordinates(v_offset+v_dims+2) else null end,
                          p_w         => case when v_dims>3 then p_geometry.sdo_ordinates(v_offset+v_dims+3) else null end,
                          p_id        => v_coord_no + 1,
                          p_sdo_gtype => v_point_gtype,
                          p_sdo_srid  => p_geometry.sdo_srid
                        ),
                      endCoord      => new
                        &&INSTALL_SCHEMA..T_Vertex(
                          p_x         => p_geometry.sdo_ordinates(v_offset+(v_dims*2)),
                          p_y         => p_geometry.sdo_ordinates(v_offset+(v_dims*2)+1),
                          p_z         => case when v_dims>2 then p_geometry.sdo_ordinates(v_offset+(v_dims*2)+2) else null end,
                          p_w         => case when v_dims>3 then p_geometry.sdo_ordinates(v_offset+(v_dims*2)+3) else null end,
                          p_id        => v_coord_no + 2,
                          p_sdo_gtype => v_point_gtype,
                          p_sdo_srid  => p_geometry.sdo_srid
                        ),
                      sdo_gtype     => p_geometry.sdo_gtype,
                      sdo_srid      => p_geometry.sdo_srid,
                      projected     => SELF.projected,
                      PrecisionModel=> &&INSTALL_SCHEMA..T_PrecisionModel(XY=>SELF.dPrecision,Z=>SELF.dPrecision,W=>SELF.dPrecision,tolerance=>SELF.tolerance)
                  );
                  AddSegmentToOutput(
                      p_segment_id   => p_segment_id,
                      p_Segments     => v_segments,
                      p_total_length => v_total_length,
                      p_min_distance => v_min_distance,
                      p_min_Segment  => v_min_Segment,
                      p_Segment      => v_segment
                  )   /* AddSegmentToOutput */;
                  v_offset := v_offset + (v_dims*2);
                  IF ( v_filter = 'ID' And p_segment_id = v_id ) THEN
                    RETURN v_segments;
                  END If;
                  v_segment_no := v_segment_no + 1;
                  v_coord_no   := v_coord_no   + 2;
                END LOOP all_arcs;
              ElsIf ( v_interpretation = 3 ) Then
                v_ll := &&INSTALL_SCHEMA..t_vertex(
                          p_x         => p_geometry.sdo_ordinates(v_offset),
                          p_y         => p_geometry.sdo_ordinates(v_offset+1),
                          p_z         => case when v_dims>2 then p_geometry.sdo_ordinates(v_offset+2) else null end,
                          p_w         => case when v_dims>3 then p_geometry.sdo_ordinates(v_offset+3) else null end,
                          p_id        => 1,
                          p_sdo_gtype => v_point_gtype,
                          p_sdo_srid  => p_geometry.sdo_srid
                        ) ;
                v_ur := &&INSTALL_SCHEMA..t_vertex(
                          p_x         => p_geometry.sdo_ordinates(v_offset+v_dims),
                          p_y         => p_geometry.sdo_ordinates(v_offset+v_dims+1),
                          p_z         => case when v_dims>2 then p_geometry.sdo_ordinates(v_offset+v_dims+2) else null end,
                          p_w         => case when v_dims>3 then p_geometry.sdo_ordinates(v_offset+v_dims+3) else null end,
                          p_id        => 2,
                          p_sdo_gtype => v_point_gtype,
                          p_sdo_srid  => p_geometry.sdo_srid
                        ) ;
                <<all_rectangles>>
                for v_j in 1..4 loop
                  p_segment_id := p_segment_id + 1;
                  v_segment    := &&INSTALL_SCHEMA..T_Segment(
                      element_id    => p_element_no,
                      subelement_id => p_sub_element_no,
                      Segment_id    => case when v_filter = 'ID' And p_segment_id = v_id then p_segment_id else v_segment_no end,
                      startCoord    => new
                        &&INSTALL_SCHEMA..T_Vertex(
                          p_x => case v_j
                                      when 1 then v_ll.x
                                      when 2 then case when v_etype=1003 then v_ur.x else v_ll.x end
                                      when 3 then v_ur.x
                                      when 4 then case when v_etype=1003 then v_ll.x else v_ur.x end
                                  end,
                          p_y => case v_j
                                      when 1 then v_ll.y
                                      when 2 then case when v_etype=1003 then v_ll.y else v_ur.y end
                                      when 3 then v_ur.y
                                      when 4 then case when v_etype=1003 then v_ur.y else v_ll.y end
                                  end,
                          p_z => case v_j
                                      when 1 then v_ll.z
                                      when 2 then (v_ll.z + v_ur.z) /2
                                      when 3 then v_ur.z
                                      when 4 then v_ll.z
                                  end,
                          p_w => case v_j
                                      when 1 then v_ll.w
                                      when 2 then case when v_etype = 1003
                                                       then v_ll.w
                                                       else (v_ur.w-v_ll.w)*((v_ur.x-v_ll.x)/((v_ur.x-v_ll.x)+(v_ur.y-v_ll.y)))
                                                   End
                                      when 3 then v_ur.w
                                      when 4 then case when v_etype = 1003
                                                       then v_ll.w
                                                       else (v_ur.w-v_ll.w)*((v_ur.x-v_ll.x)/((v_ur.x-v_ll.x)+(v_ur.y-v_ll.y)))
                                                   End
                                  end,
                          p_id        => v_coord_no,
                          p_sdo_gtype => v_point_gtype,
                          p_sdo_srid  => p_geometry.sdo_srid
                        ) ,
                      midCoord => null,
                      endCoord => new
                        &&INSTALL_SCHEMA..T_Vertex(
                          p_x => case v_j
                                      when 1 then case when v_etype=1003 then v_ur.x else v_ll.x end
                                      when 2 then v_ur.x
                                      when 3 then case when v_etype=1003 then v_ll.x else v_ur.x end
                                      when 4 then v_ll.x
                                  end,
                          p_y => case v_j
                                      when 1 then case when v_etype=1003 then v_ll.y else v_ur.y end
                                      when 2 then v_ur.y
                                      when 3 then case when v_etype=1003 then v_ur.y else v_ll.y end
                                      when 4 then v_ll.y
                                  end,
                          p_z => case v_j
                                      when 1 then (v_ll.z + v_ur.z) /2
                                      when 2 then v_ur.z
                                      when 3 then (v_ll.z + v_ur.z) /2
                                      when 4 then v_ll.z
                                  end,
                          p_w => case v_j
                                      when 1 then case when v_etype = 1003
                                                       then v_ll.w
                                                       else (v_ur.w-v_ll.w)*((v_ur.x-v_ll.x)/((v_ur.x-v_ll.x)+(v_ur.y-v_ll.y)))
                                                   End
                                      when 2 then v_ur.w
                                      when 3 then case when v_etype=1003
                                                       then v_ll.w
                                                       else (v_ur.w-v_ll.w)*((v_ur.x-v_ll.x)/((v_ur.x-v_ll.x)+(v_ur.y-v_ll.y)))
                                                     End
                                      when 4 then v_ll.w
                                  end,
                          p_id        => v_coord_no + 1,
                          p_sdo_gtype => v_point_gtype,
                          p_sdo_srid  => p_geometry.sdo_srid
                        ),
                      sdo_gtype     => p_geometry.sdo_gtype,
                      sdo_srid      => p_geometry.sdo_srid,
                      projected     => SELF.projected,
                      PrecisionModel=> &&INSTALL_SCHEMA..T_PrecisionModel(XY=>SELF.dPrecision,Z=>SELF.dPrecision,W=>SELF.dPrecision,tolerance=>SELF.tolerance)
                  );
                  AddSegmentToOutput (
                      p_segment_id   => p_segment_id,
                      p_Segments     => v_segments,
                      p_total_length => v_total_length,
                      p_min_Segment  => v_min_Segment,
                      p_min_distance => v_min_distance,
                      p_Segment      => v_segment
                  ) /* AddSegmentToOutput */;
                  IF ( v_filter = 'ID' And p_segment_id = v_id ) THEN
                    RETURN v_segments;
                  END If;
                  v_segment_no := v_segment_no + 1;
                  v_coord_no   := v_coord_no + 1;
                END LOOP all_rectangles;

              ElsIf ( v_interpretation = 4 ) Then
                -- Segmentize circle as a single circular arc.
                p_segment_id := p_segment_id + 1;
                v_segment    := &&INSTALL_SCHEMA..T_Segment (
                      element_id    => p_element_no,
                      subelement_id => p_sub_element_no,
                      Segment_id    => case when v_filter = 'ID' And p_segment_id = v_id then p_segment_id else v_segment_no end,
                      startCoord    => new
                        &&INSTALL_SCHEMA..T_Vertex(
                          p_x         => p_geometry.sdo_ordinates(v_offset),
                          p_y         => p_geometry.sdo_ordinates(v_offset+1),
                          p_z         => case when v_dims>2 then p_geometry.sdo_ordinates(v_offset+2) else null end,
                          p_w         => case when v_dims>3 then p_geometry.sdo_ordinates(v_offset+3) else null end,
                          p_id        => 1,
                          p_sdo_gtype => v_point_gtype,
                          p_sdo_srid  => p_geometry.sdo_srid
                        ) ,
                      midCoord      => new
                        &&INSTALL_SCHEMA..T_Vertex(
                          p_x         => p_geometry.sdo_ordinates(v_offset+v_dims),
                          p_y         => p_geometry.sdo_ordinates(v_offset+v_dims+1),
                          p_z         => case when v_dims>2 then p_geometry.sdo_ordinates(v_offset+v_dims+2) else null end,
                          p_w         => case when v_dims>3 then p_geometry.sdo_ordinates(v_offset+v_dims+3) else null end,
                          p_id        => 2,
                          p_sdo_gtype => v_point_gtype,
                          p_sdo_srid  => p_geometry.sdo_srid
                        ) ,
                      endCoord      => new
                        &&INSTALL_SCHEMA..T_Vertex(
                          p_x         => p_geometry.sdo_ordinates(v_offset+(v_dims*2)),
                          p_y         => p_geometry.sdo_ordinates(v_offset+(v_dims*2)+1),
                          p_z         => case when v_dims>2 then p_geometry.sdo_ordinates(v_offset+(v_dims*2)+2) else null end,
                          p_w         => case when v_dims>3 then p_geometry.sdo_ordinates(v_offset+(v_dims*2)+3) else null end,
                          p_id        => 3,
                          p_sdo_gtype => v_point_gtype,
                          p_sdo_srid  => p_geometry.sdo_srid
                        ),
                      sdo_gtype     => p_geometry.sdo_gtype,
                      sdo_srid      => p_geometry.sdo_srid,
                      projected     => SELF.projected,
                      PrecisionModel=> &&INSTALL_SCHEMA..T_PrecisionModel(XY=>SELF.dPrecision,Z=>SELF.dPrecision,W=>SELF.dPrecision,tolerance=>SELF.tolerance)
                 );
                 AddSegmentToOutput(p_segment_id   => p_segment_id,
                                    p_Segments     => v_segments,
                                    p_total_length => v_total_length,
                                    p_min_distance => v_min_distance,
                                    p_min_Segment  => v_min_Segment,
                                    p_Segment      => v_segment
                                   );
                  IF ( v_filter = 'ID' And p_segment_id = v_id ) THEN
                    RETURN v_segments;
                  END If;
              End If;
           End If;
        END LOOP element_extraction;
        RETURN v_segments;
    End segmentizeElement;

  Begin
    IF ( v_filter not in ('ALL','DISTANCE','ID','RANGE','MEASURE','X','Y') ) Then
      raise_application_error(c_i_filter_value,
                              REPLACE(c_s_filter_value,'*VALUE*',v_filter),
                              true);
    END IF;

    IF ( v_filter = 'DISTANCE' and p_vertex is null ) THEN
      raise_application_error(c_i_distance_value,
                              c_s_distance_value,
                              true);
    END IF;

    IF ( v_filter = 'ID' and p_id is null ) THEN
      raise_application_error(c_i_id_value,
                              c_s_id_value,
                              true);
    END IF;

    If ( SELF.ST_Gtype() NOT IN (2,3,4,6,7) ) Then
       RETURN NULL;
    End If;

    -- Set min distance variable at start of processing of all element and ring segments
    v_min_distance := 9999999999999999999999999;
    -- How many elements?
    v_num_elements  := SELF.ST_NumElements();
    -- DEBUG dbms_output.PUT_LINE('ST_Segmentize v_num_elements:' || v_num_elements);
    v_id            := NVL(p_id,SELF.ST_NumSegments());

    -- Complete initialisation
    v_segments.DELETE;
    -- Generate id for every individual segment regardless as to element/sub_element
    v_segment_id := 0;
    <<for_all_elements>>
    For v_element_no in 1..v_num_elements loop
      -- DEBUG dbms_output.PUT_LINE('ST_Segmentize Processing element:' || v_element_no);
      v_element := MDSYS.SDO_UTIL.EXTRACT(SELF.geom,v_element_no);   -- Extract element (sub-elements handled by code)
       If ( v_element is not null ) Then
         If ( v_element.get_gtype() = 3) Then -- Polygons
           -- DEBUG dbms_output.put_line('v_element('||v_element_no||'): ' || &&INSTALL_SCHEMA..PRINT.sdo_geometry(v_element,SELF.dPrecision));
           v_num_rings := &&INSTALL_SCHEMA..T_GEOMETRY(v_element,SELF.tolerance,SELF.dPrecision,SELF.projected).ST_NumRings(0 /*0=ALL*/);
           -- DEBUG dbms_output.PUT_LINE('ST_Segmentize Polygon numRings:' || v_num_rings);
           <<Extract_All_Rings>>
           FOR v_ring_no IN 1..v_num_rings LOOP
             -- DEBUG dbms_output.PUT_LINE('ST_Segmentize extracting v_element_no/v_ring_no ('||v_element_no||'/'||v_ring_no||')');
             v_ring := &&INSTALL_SCHEMA..T_GEOMETRY(MDSYS.SDO_UTIL.EXTRACT(SELF.geom,v_element_no,v_ring_no),
                                                    SELF.tolerance,SELF.dPrecision,SELF.projected);
             -- Extract reverses inner rings (indicated by v_ring_no > 1)
             If ( v_ring is not null ) Then
               -- DEBUG dbms_output.put_line('v_ring: ' || &&INSTALL_SCHEMA..PRINT.sdo_geometry(v_ring.geom,SELF.dPrecision));
               IF ( v_ring_no > 1 ) THEN
                 v_ring := v_ring.ST_Reverse_Geometry();
                 -- DEBUG dbms_output.put_line('v_ring (Reversed): ' || &&INSTALL_SCHEMA..PRINT.sdo_geometry(v_ring.geom,SELF.dPrecision));
               End If;
               -- segmentize the ring
               v_segments := segmentizeElement(v_segment_id,
                                               v_element_no,
                                               v_ring_no,
                                               v_ring.geom,
                                               SELF.ST_Dims());
               IF ( v_filter = 'ID' And v_segment_id = v_id ) THEN
                 RETURN v_segments;
               END If;
             End If;
           END LOOP Extract_All_Rings;
         ElsIf ( v_element.get_gtype() = 2) Then  -- Linestrings
           -- segmentize the linestring
           v_segments := segmentizeElement(v_segment_id,
                                           v_element_no,
                                           1,
                                           v_element,
                                           SELF.ST_Dims());
           IF ( v_filter = 'ID' And v_segment_id = v_id ) THEN
             RETURN v_segments;
           END If;
         End If;
       End If;
    END LOOP extract_all_elements;
    -- IF Distance filter.
    -- If v_segments.count > 0 then already have had added segment(s) where distance=0 (could be more than one)
    -- If v_segments.count = 0 then we save the egment with the minimum distance (v_min_segment)
    IF ( v_filter = 'DISTANCE' AND v_min_Segment is not null AND v_segments.COUNT = 0 ) THEN
      -- DEBUG dbms_output.put_line(' Returning by extending v_segment which currently has ' || v_segments.COUNT||' element: ' || v_segments(1).ST_AsText());
      v_segments.EXTEND(1);
      v_segments(v_segments.COUNT) := new &&INSTALL_SCHEMA..T_Segment(v_min_Segment);
    End If;
    Return v_segments;
  END ST_Segmentize;

  Member Function ST_Flip_Segments(p_keep in integer default -1)
           Return &&INSTALL_SCHEMA..T_Segments Pipelined
  As
    v_keep integer := NVL(p_keep,-1);
  Begin
    IF (SELF.ST_Dimension() not in (1,2)) THEN
      Return;
    END IF;
    -- Reorder The Vectors of the input line collection (can be multiPolygon/Polygon/LineString/MultiLineString
    <<all_segments>>
    FOR rec IN (select &&INSTALL_SCHEMA..T_Segment(
                          p_Segment_id => 0,
                          p_startCoord => &&INSTALL_SCHEMA..T_Vertex(
                                    p_x        => E.Start_X,
                                    p_y        => E.Start_Y,
                                    p_id       => 1,
                                    p_sdo_gtype=> 2001,
                                    p_sdo_srid => SELF.geom.sdo_srid
                                  ),
                          p_endCoord => &&INSTALL_SCHEMA..T_Vertex(
                              p_x        => E.End_X,
                              p_y        => E.End_Y,
                              p_id       => 2,
                              p_sdo_gtype=> 2001,
                              p_sdo_srid => SELF.geom.sdo_srid
                            ),
                          p_sdo_gtype  => SELF.geom.SDO_Gtype,
                          p_sdo_srid   => SELF.geom.sdo_SRID,
                          p_projected  => SELF.projected,
                          p_precision  => SELF.dPrecision,
                          p_tolerance  => SELF.tolerance
                        ) as segmnt
                  from (select d.Start_X,d.Start_Y,d.End_X,d.End_Y,
                               count(*) over (partition by d.Start_X,d.Start_Y,d.End_X,d.End_Y order by d.Start_X,d.Start_Y,d.End_X,d.End_Y) as duplicate_count
                          from (select Case When C.startCoord.X <= C.EndCoord.X Then C.startCoord.X Else C.EndCoord.X   End As Start_X,
                                       Case When C.startCoord.X <= C.EndCoord.X Then C.EndCoord.X   Else C.startCoord.X End As End_X,
                                       Case When C.startCoord.X <  C.EndCoord.X Then C.startCoord.Y
                                            Else Case When C.startCoord.X = C.EndCoord.X
                                                      Then case when C.EndCoord.Y < C.startCoord.Y then C.EndCoord.Y Else C.startCoord.Y end
                                                      Else C.EndCoord.Y
                                                  End
                                        End As Start_Y,
                                       Case When C.startCoord.X < C.EndCoord.X then C.EndCoord.Y
                                            Else Case When C.startCoord.X = C.EndCoord.X
                                                      Then case when C.EndCoord.Y < C.startCoord.Y then C.startCoord.Y Else C.EndCoord.Y end
                                                      Else c.StartCoord.Y
                                                  End
                                        End As End_Y
                                  from TABLE(SELF.ST_Segmentize('ALL')) c
                                ) d
                        ) e
                    where v_keep = -1
                       OR (v_keep = 1 and duplicate_count = 1)
                       OR (v_keep = 2 and duplicate_count = 2 )
                       OR (v_keep = 3 and duplicate_count = 3 )
                       OR (v_keep = 4 and duplicate_count = 4 )
                       OR (v_keep = duplicate_count)
                )
    LOOP
      PIPE ROW(rec.segmnt);
    END LOOP all_segments;
    RETURN;
  End ST_Flip_Segments;

  Member Function ST_VertexN(p_vertex in integer)
           Return &&INSTALL_SCHEMA..T_Vertex
  Is
     c_i_invalid_vertex Constant pls_integer   := -20123;
     c_s_invalid_vertex Constant VarChar2(100) := 'Vertex position (*POSN*) is invalid.';

     v_ord              pls_integer;   -- index into ordinate array
     v_vertex           pls_integer := NVL(p_vertex,-1); -- Index into ordinates array
  Begin
    -- Check vertex request is correct
    IF ( v_vertex = 0
        OR ABS(v_vertex) > SELF.ST_NumVertices() ) THEN
       raise_application_error(c_i_invalid_vertex,
                               c_s_invalid_vertex,true);
     ELSIF ( v_vertex <= -1 ) THEN -- Request counting down from end
       v_ord := ( (SELF.geom.SDO_ORDINATES.COUNT()/SELF.ST_Dims())
                  + v_vertex ) * SELF.ST_Dims() + 1;
     ELSE
       v_ord := (v_vertex - 1) * SELF.ST_Dims()  + 1;
     END IF;
    -- Case 1: Point combinations
    If ( v_vertex = 1 AND SELF.ST_Dimension() = 0 ) Then
      If (SELF.geom.sdo_point is not null) Then
        Return &&INSTALL_SCHEMA..T_Vertex(
                   p_x         => SELF.geom.sdo_point.X,
                   p_y         => SELF.geom.sdo_point.Y,
                   p_z         => SELF.geom.sdo_point.Z,
                   p_w         => NULL,
                   p_id        => case when v_vertex = -1 then SELF.ST_NumVertices() else v_vertex end,
                   p_sdo_gtype => SELF.ST_sdo_gtype(),
                   p_sdo_srid  => SELF.ST_SRID()
               );
      ElsIf ( SELF.geom.sdo_ordinates is not null ) Then
        return &&INSTALL_SCHEMA..T_Vertex(
                   p_x         => SELF.geom.sdo_ordinates(1),
                   p_y         => SELF.geom.sdo_ordinates(2),
                   p_z         => case when (SELF.ST_Dims()>2) then SELF.geom.sdo_ordinates(3) else null end,
                   p_w         => case when (SELF.ST_Dims()>3) then SELF.geom.sdo_ordinates(4) else null end,
                   p_id        => case when v_vertex = -1 then SELF.ST_NumVertices() else v_vertex end,
                   p_sdo_gtype => SELF.ST_sdo_gtype(),
                   p_sdo_srid  => SELF.ST_SRID()
               );
      End If;
    End if;
    -- Case 2: Not point....
    -- DEBUG dbms_output.put_line('ST_VertexN(' || v_vertex || ')');
    return &&INSTALL_SCHEMA..T_Vertex(
             p_x         => SELF.geom.sdo_ordinates(v_ord),
             p_y         => SELF.geom.sdo_ordinates(v_ord+1),
             p_z         => case when (SELF.ST_Dims()>2) then SELF.geom.SDO_ORDINATES(v_ord+2) else NULL End,
             p_w         => case when (SELF.ST_Dims()>3) then SELF.geom.SDO_ORDINATES(v_ord+3) else NULL End,
             p_id        => case when v_vertex = -1 then SELF.ST_NumVertices() else v_vertex end,
             p_sdo_gtype => SELF.ST_sdo_gtype(),
             p_sdo_srid  => SELF.ST_SRID()
           );
  End ST_VertexN;

  Member Function ST_StartVertex
           Return &&INSTALL_SCHEMA..T_Vertex
  Is
  Begin
    Return SELF.ST_VertexN(1);
  End ST_StartVertex;

  Member Function ST_EndVertex
           Return &&INSTALL_SCHEMA..T_Vertex
  Is
  Begin
    Return SELF.ST_VertexN(-1);
  End ST_EndVertex;

  Member Function ST_PointN(p_point in integer)
           Return &&INSTALL_SCHEMA..T_Geometry
  Is
    v_vertex &&INSTALL_SCHEMA..T_Vertex;
  Begin
    v_vertex := SELF.ST_VertexN(p_point);
    IF ( v_vertex is not null ) THEN
      Return &&INSTALL_SCHEMA..T_GEOMETRY(v_vertex.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);
    END IF;
    Return NULL;
  End ST_PointN;

  Member Function ST_StartPoint
           Return &&INSTALL_SCHEMA..T_Geometry
  Is
    v_vertex &&INSTALL_SCHEMA..T_Vertex;
  Begin
    v_vertex := SELF.ST_VertexN(1);
    Return &&INSTALL_SCHEMA..T_Geometry(v_vertex.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);
  End ST_StartPoint;

  Member Function ST_EndPoint
           Return &&INSTALL_SCHEMA..T_Geometry
  Is
    v_vertex &&INSTALL_SCHEMA..T_Vertex;
  Begin
    v_vertex := SELF.ST_VertexN(-1);
    return &&INSTALL_SCHEMA..T_Geometry(v_vertex.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);
  End ST_EndPoint;

  Member Function ST_SegmentN(p_segment in integer)
           Return &&INSTALL_SCHEMA..t_Segment
  Is
     c_i_notlinear       CONSTANT pls_integer   := -20121;
     c_s_notlinear       CONSTANT VARCHAR2(100) := 'Input geometry not linestring or polygon';
     c_i_invalid_segment Constant pls_integer   := -20122;
     c_s_invalid_segment Constant VarChar2(100) := 'Segment number (*POSN*) is invalid.';
     v_segment_id        pls_integer := NVL(p_segment,-1);
     v_segments          &&INSTALL_SCHEMA..T_Segments;
  Begin
    IF (SELF.ST_Dimension() = 0 ) Then
      raise_application_error(c_i_notlinear,c_s_notlinear,true);
    End If;
    -- Check vertex id request is correct
    IF ( v_segment_id = 0
        OR v_segment_id < -1
        OR ABS(v_segment_id) > SELF.ST_NumSegments() ) THEN
       raise_application_error(c_i_invalid_segment,
                               c_s_invalid_segment,true);
    END IF;
    IF (v_segment_id = -1) Then
      v_segment_id := SELF.ST_NumSegments();
    End If;
    -- Get actual segment for v_segment_id
    v_segments := SELF.ST_Segmentize(p_filter => 'ID',
                                     p_id     => v_segment_id);
    If ( v_segments is null or v_segments.COUNT = 0 ) Then
      Return null;
    End If;
    Return v_segments(1);
  End ST_SegmentN;

  Member Function ST_StartSegment
           Return &&INSTALL_SCHEMA..t_Segment
  Is
  Begin
    return SELF.ST_SegmentN(1);
  End ST_startSegment;

  Member Function ST_EndSegment
           Return &&INSTALL_SCHEMA..t_Segment
  Is
  Begin
    return SELF.ST_SegmentN(-1);
  End ST_endSegment;

  Member Function ST_Which_Side(p_point in mdsys.sdo_geometry,
                                p_unit  in varchar2 default null)
           Return VarChar2
  As
    v_offset number;
  Begin
    v_offset := SELF.ST_LRS_Find_Offset(p_point,p_unit);
    Return case when v_offset = 0.0 then 'O' when SIGN(v_offset) = -1 then 'L' else 'R' end;
  End ST_Which_Side;

  Member Function ST_inCircularArc(p_point_number in integer)
           Return Integer
  Is
    v_arc_start_point pls_integer;
    v_etype           pls_integer;
    v_offset          pls_integer;
    v_interpretation  pls_integer;
    v_elements         pls_integer;
    v_elem_info       mdsys.sdo_elem_info_array;
  Begin
    If ( SELF.ST_Gtype() in (1,5) ) Then
      return 0;
    End If;
    v_elements  := ( ( SELF.geom.sdo_elem_info.COUNT / 3 ) - 1 );
    v_elem_info := SELF.geom.sdo_elem_info;
    <<element_extraction>>
    for v_i IN 0 .. v_elements LOOP
      v_offset         := (v_i * 3) + 1;
      v_etype          := v_offset + 1;
      v_interpretation := v_etype  + 1;
      if (    ( v_elem_info(v_etype) = 2 AND
                v_elem_info(v_interpretation) = 2 )
           OR ( v_elem_info(v_etype) in (1003,2003) AND
                v_elem_info(v_interpretation) = 4 ) ) then
         v_arc_start_point := ((v_elem_info(v_offset) - 1) / SELF.ST_dims()) + 1;
         if ( p_point_number  between v_arc_start_point and v_arc_start_point + 2 ) Then
             return (p_point_number - v_arc_start_point) + 1;
         End If;
      end If;
    end loop element_extraction;
    return 0;
  End ST_inCircularArc;

  Member Function ST_Polygon2Rectangle
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    v_vertices        mdsys.vertex_set_type;
    v_ords            mdsys.sdo_ordinate_array :=  new mdsys.sdo_ordinate_array(null);
    v_num_elems       pls_integer;
    v_actual_etype    pls_integer;
    v_ring_elem_count pls_integer := 0;
    v_ring            mdsys.sdo_geometry;
    v_num_rings       pls_integer;
    v_out_geom        mdsys.sdo_geometry;

    --PRAGMA INLINE (GetEtypeAt, 'YES');
    Function GetETypeAt(
      p_geometry  in mdsys.sdo_geometry,
      p_element   in integer)
      Return pls_integer
    Is
      v_num_elems number;
    Begin
      If ( p_geometry is not null ) Then
        v_num_elems := ( ( p_geometry.sdo_elem_info.COUNT / 3 ) - 1 );
        <<element_extraction>>
        for v_i IN 0 .. v_num_elems LOOP
           if ( (v_i+1) = p_element ) then
              RETURN p_geometry.sdo_elem_info(v_i * 3 + 2);
          End If;
          end loop element_extraction;
      End If;
      Return NULL;
    End GetETypeAt;

  Begin
    -- Only support polygons
    IF ( SELF.ST_gtype() not in (3,7) ) THEN
       RETURN SELF;
    END IF;

   v_num_elems := SELF.ST_NumElements();
   <<all_elements>>
   FOR v_elem_no IN 1..v_num_elems LOOP
       -- Need to process and check all inner rings
       --
       -- Process all rings in the extracted single - 2003 - polygon
       v_num_rings := &&INSTALL_SCHEMA..T_GEOMETRY(MDSYS.SDO_UTIL.EXTRACT(SELF.geom,v_elem_no,0),
                                      SELF.Tolerance,
                                      SELF.dPrecision,
                                      SELF.Projected).ST_NumRings();
       <<All_Rings>>
       FOR v_ring_no IN 1..v_num_rings LOOP
           v_ring            := MDSYS.SDO_UTIL.EXTRACT(SELF.geom,v_elem_no,v_ring_no);
           v_actual_etype    := GetEtypeAt(SELF.geom,(v_ring_elem_count+1));
           v_ring_elem_count := v_ring_elem_count + v_ring.sdo_elem_info.COUNT / 3;
           IF ( v_ring is not null ) THEN
             IF ( v_ring.sdo_elem_info(2) = 1003 AND
                  v_ring.sdo_elem_info(2) <> v_actual_etype ) THEN
                -- Replace etype as Oracle extracts 2003 as 1003
                v_ring.sdo_elem_info(2) := v_actual_etype;
             End If;
             v_vertices := mdsys.sdo_util.getVertices(v_ring);
             IF ( v_vertices.COUNT = 5 ) THEN
               -- Do the five vertices form a rectangle?
               -- inner product of two consequent segment must equals to zero
               IF ( (v_vertices(1).x-v_vertices(2).x) * (v_vertices(2).x-v_vertices(3).x) +
                    (v_vertices(1).y-v_vertices(2).y) * (v_vertices(2).y-v_vertices(3).y) = 0 AND
                    (v_vertices(3).x-v_vertices(4).x) * (v_vertices(4).x-v_vertices(5).x) +
                    (v_vertices(3).y-v_vertices(4).y) * (v_vertices(4).y-v_vertices(5).y) = 0 ) THEN
                  v_ring.sdo_elem_info(1) := 1;
                  v_ring.sdo_elem_info(3) := 3;
                  v_ords.DELETE;
                  v_ords.EXTEND(4);
                  v_ords(1) := LEAST(   v_vertices(1).x,v_vertices(3).x);
                  v_ords(2) := LEAST(   v_vertices(1).y,v_vertices(3).y);
                  v_ords(3) := GREATEST(v_vertices(1).x,v_vertices(3).x);
                  v_ords(4) := GREATEST(v_vertices(1).y,v_vertices(3).y);
                  v_ring := mdsys.sdo_geometry(v_ring.sdo_gtype,
                                               v_ring.sdo_srid,
                                               v_ring.sdo_point,
                                               v_ring.sdo_elem_info,
                                               v_ords);
               END IF;
             END IF;
             IF ( v_out_geom is null ) THEN
               v_out_geom := v_ring;
             ELSE
               v_out_geom := mdsys.sdo_util.APPEND(v_out_geom,v_ring);
             END IF;
           END IF;
       END LOOP All_Rings;
   END LOOP all_elements;
   RETURN &&INSTALL_SCHEMA..T_GEOMETRY(mdsys.sdo_geometry(SELF.geom.sdo_gtype,
                                             SELF.ST_SRID(),
                                             SELF.geom.SDO_POINT,
                                             v_out_geom.sdo_elem_info,
                                             v_out_geom.sdo_ordinates),
                                  SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_Polygon2Rectangle;

  Member Function ST_Rectangle2Polygon
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    v_egeom        &&INSTALL_SCHEMA..T_GEOMETRY;
    v_ring         &&INSTALL_SCHEMA..T_GEOMETRY;
    v_return_tGeom &&INSTALL_SCHEMA..T_GEOMETRY;
    v_num_rings    pls_integer;
    v_num_elements pls_integer;
    v_offset       pls_integer;
    v_base_index   pls_integer;
    v_min_x        number;
    v_min_y        number;
    v_max_x        number;
    v_max_y        number;

    -- The problem with Rectangles with Z and M ordinates is while one might know the value for the start and end,
    -- one cannot every know for certain what the values are for the other two points in the rectangle.
    -- So, if the LL is 0,0,0 and the UR is 10,10,10 what is the second and fourth Z value? one might say (start) 0 + (10+0)/2 = 5,
    -- But why can't it be -2.4 and 8.3 ie Z: 0,-2.4,10,8.3,0?

  Begin
    IF ( SELF.ST_Dimension() <> 2 ) THEN
      Return SELF;
    END IF;
    -- We only support 2D Optimized Rectangles.
    IF ( SELF.ST_Dims() <> 2 OR SELF.ST_HasRectangles() = 0 ) THEN
      Return SELF;
    END IF;

    <<for_all_polygons>>
    FOR v_elem_no IN 1..SELF.ST_NumElements() LOOP
      v_egeom := &&INSTALL_SCHEMA..T_GEOMETRY(
                   mdsys.sdo_util.Extract(SELF.geom,v_elem_no),
                   SELF.tolerance,
                   SELF.dPrecision,
                   SELF.projected);
      v_num_rings := v_egeom.ST_NumRings();
      <<for_all_rings>>
      FOR v_ring_no in 1..v_num_rings Loop
        -- Extract ring from element .. must do it this way, can't correctly extract from v_element.
        v_ring := &&INSTALL_SCHEMA..T_Geometry(
                    mdsys.sdo_util.Extract(SELF.geom,v_elem_no,v_ring_no),
                    SELF.tolerance,
                    SELF.dPrecision,
                    SELF.projected
                  );
        If ( v_ring is null ) Then
          CONTINUE;
        END  IF;
        -- Extract reverses inner rings (indicated by v_ring_no > 1)
        -- DEBUG dbms_output.put_line('v_ring ('|| v_ring_no || '): ' || &&INSTALL_SCHEMA..PRINT.sdo_geometry(v_ring.geom,SELF.dPrecision));
        IF ( v_ring_no > 1 ) THEN
          IF ( v_ring.geom.sdo_elem_info(3) <> 3 ) THEN
            v_ring := v_ring.ST_Reverse_Geometry();
          END IF;
          -- Replace etype as Oracle extracts 2003 as 1003
          v_ring.geom.sdo_elem_info(2) := 2003;
          -- DEBUG dbms_output.put_line('v_ring rev('|| v_ring_no || '): ' || &&INSTALL_SCHEMA..PRINT.sdo_geometry(v_ring.geom,SELF.dPrecision));
        END IF;
        IF ( v_ring.geom.sdo_elem_info(3) = 3 ) THEN
          Begin
            v_min_x := LEAST(   v_ring.geom.sdo_ordinates(1),v_ring.geom.sdo_ordinates(SELF.ST_Dims()+1));
            v_min_y := LEAST(   v_ring.geom.sdo_ordinates(2),v_ring.geom.sdo_ordinates(SELF.ST_Dims()+2));
            v_max_x := GREATEST(v_ring.geom.sdo_ordinates(1),v_ring.geom.sdo_ordinates(SELF.ST_Dims()+1));
            v_max_y := GREATEST(v_ring.geom.sdo_ordinates(2),v_ring.geom.sdo_ordinates(SELF.ST_Dims()+2));
            If ( v_ring.geom.sdo_elem_info(2) = 1003 ) Then
              v_ring.geom.sdo_ordinates :=
                new mdsys.sdo_ordinate_array(
                              v_min_x, v_min_y,
                              v_max_x, v_min_y,
                              v_max_x, v_max_y,
                              v_min_x, v_max_y,
                              v_min_x, v_min_y
                    );
            ElsIf ( v_ring.geom.sdo_elem_info(2) = 2003 ) Then
              v_ring.geom.sdo_ordinates :=
                new mdsys.sdo_ordinate_array(
                              v_max_x, v_min_y,
                              v_min_x, v_min_y,
                              v_min_x, v_max_y,
                              v_max_x, v_max_y,
                              v_max_x, v_min_y
                   );
            End If;
          End;
          v_ring.geom.sdo_elem_info(3) := 1;
        END IF;
        -- DEBUG dbms_output.put_line('v_ring: ' || &&INSTALL_SCHEMA..PRINT.sdo_geometry(v_ring.geom,SELF.dPrecision));
        IF  ( v_return_tgeom is null ) THEN
          v_return_tgeom := &&INSTALL_SCHEMA..T_GEOMETRY(v_ring.geom,SELF.tolerance,SELF.dPrecision,SELF.projected);
        ELSE
          -- Append elem info of ring being processed to result geom
          v_num_elements := ( ( v_ring.geom.sdo_elem_info.COUNT / 3 ) - 1 );
          v_base_index   := v_return_tgeom.geom.sdo_elem_info.COUNT;
          <<for_all_elements>>
          for v_i IN 0 .. v_num_elements LOOP
            v_offset := ( v_i * 3 ) + 1;
            v_return_tgeom.geom.sdo_elem_info.EXTEND(3);
            v_return_tgeom.geom.sdo_elem_info(v_base_index + v_offset)   := v_return_tgeom.geom.sdo_ordinates.COUNT + v_ring.geom.sdo_elem_info(v_offset);
            v_return_tgeom.geom.sdo_elem_info(v_base_index + v_offset+1) := v_ring.geom.sdo_elem_info(v_offset+1);
            v_return_tgeom.geom.sdo_elem_info(v_base_index + v_offset+2) := v_ring.geom.sdo_elem_info(v_offset+2);
          end loop for_all_elements;
          -- Append sdo_ordinates of ring being processed to result geom
          v_base_index := v_return_tGeom.geom.sdo_ordinates.COUNT;
          v_return_tgeom.geom.sdo_ordinates.EXTEND(v_ring.geom.sdo_ordinates.COUNT);
          <<for_all_ords>>
          for v_ord IN 1 .. v_ring.geom.sdo_ordinates.COUNT LOOP
            v_return_tgeom.geom.sdo_ordinates(v_base_index + v_ord) := v_ring.geom.sdo_ordinates(v_ord);
          end loop for_all_ords;
        End If;
        -- DEBUG dbms_output.put_line('v_return_tgeom: ' || &&INSTALL_SCHEMA..PRINT.sdo_geometry(v_return_tgeom.geom,v_return_tgeom.dPrecision));
      End Loop for_all_rings;
    END LOOP for_all_polygons;
    v_return_tgeom.geom.sdo_gtype := SELF.geom.sdo_gtype;
    Return v_return_tgeom;
  End ST_Rectangle2Polygon;

  Member Function ST_Geometry2Diminfo
           Return Mdsys.Sdo_Dim_Array
  As
    V_Dims      Pls_Integer;
    v_tolerance number      := NVL(SELF.tolerance,0.005);
    v_x_dimname varchar2(5) := case when UPPER(NVL(SELF.Projected,1)) = 1 then 'X' ELSE 'LONG' end;
    v_y_dimname varchar2(5) := case when UPPER(NVL(SELF.Projected,1)) = 1 then 'Y' ELSE 'LAT' end;
    v_t_mbr     &&INSTALL_SCHEMA..T_GEOMETRY;
    v_mbr       mdsys.sdo_geometry;
  Begin
    v_t_mbr  := SELF.ST_MBR();
    If (v_t_mbr is null) Then
       Return NULL;
    End If;
    v_mbr := v_t_mbr.geom;
    V_Dims := SELF.ST_Dims();
    Return
    Case When V_Dims = 2
         Then Mdsys.Sdo_Dim_Array(
                Mdsys.Sdo_Dim_Element(V_X_Dimname, v_mbr.Sdo_Ordinates(1), v_mbr.Sdo_Ordinates(v_dims+1), v_tolerance),
                Mdsys.Sdo_Dim_Element(V_Y_Dimname, v_mbr.Sdo_Ordinates(2), v_mbr.Sdo_Ordinates(v_dims+2), v_tolerance))
         When V_Dims = 3
         Then Mdsys.Sdo_Dim_Array(
                Mdsys.Sdo_Dim_Element(V_X_Dimname, v_mbr.Sdo_Ordinates(1), v_mbr.Sdo_Ordinates(v_dims+1), v_tolerance),
                Mdsys.Sdo_Dim_Element(V_Y_Dimname, v_mbr.Sdo_Ordinates(2), v_mbr.Sdo_Ordinates(v_dims+2), v_tolerance),
                Mdsys.Sdo_Dim_Element(Case When v_mbr.Get_LRS_Dim() In (0,4) Then 'Z' Else 'M' End,
                                      v_mbr.Sdo_Ordinates(3), v_mbr.Sdo_Ordinates(v_dims+3), v_tolerance))
         When V_Dims = 4
         Then Mdsys.Sdo_Dim_Array(
                Mdsys.Sdo_Dim_Element(V_X_Dimname, v_mbr.Sdo_Ordinates(1), v_mbr.Sdo_Ordinates(v_dims+1), v_tolerance),
                Mdsys.Sdo_Dim_Element(V_Y_Dimname, v_mbr.Sdo_Ordinates(2), v_mbr.Sdo_Ordinates(v_dims+2), v_tolerance),
                Mdsys.Sdo_Dim_Element(Case When v_mbr.Get_LRS_Dim() In (0,4) Then 'Z' Else 'M' End,
                                      v_mbr.Sdo_Ordinates(3), v_mbr.Sdo_Ordinates(v_dims+3), v_tolerance),
                Mdsys.Sdo_Dim_Element(Case When v_mbr.Get_LRS_Dim() = 4 Then 'M' Else 'Z' End,
                                      v_mbr.Sdo_Ordinates(4), v_mbr.Sdo_Ordinates(v_dims+4), v_tolerance))
         Else Null
     End;
  End ST_Geometry2Diminfo;

  Static Function ST_Diminfo2Rectangle(p_dim_array in mdsys.sdo_dim_array,
                                       p_srid      in integer default NULL)
  Return &&INSTALL_SCHEMA..T_Geometry
  AS
     v_ords mdsys.sdo_ordinate_array := new mdsys.sdo_ordinate_array(null);
     v_ord  pls_integer;
     v_dims pls_integer;
  BEGIN
    IF ( p_dim_array is null ) THEN
       RETURN NULL;
    END IF;
    -- Has p_dim_array sufficient elements
    IF ( p_dim_array.COUNT < 2 ) THEN
       RETURN NULL;
    END IF;
    -- Convert
    -- Assume first two sdo_dim_elements are X and Y (or Long/Lat
    -- ie don't bother checking dim name
    --
    v_dims := case when p_dim_array.COUNT > 4 then 4 else p_dim_array.COUNT end;
    v_ords.DELETE;
    v_ords.EXTEND(v_dims * 2);
    v_ords(1) := p_dim_array(1).sdo_lb; -- X
    v_ords(2) := p_dim_array(2).sdo_lb; -- Y
    v_ord := 3;
    if ( p_dim_array.COUNT > 2 ) Then
      v_ords(v_ord) := p_dim_array(3).sdo_lb;
      v_ord := v_ord + 1;
      if ( p_dim_array.COUNT > 3 ) Then
        v_ords(v_ord) := p_dim_array(4).sdo_lb;
        v_ord := v_ord + 1;
      End If;
    End If;
    v_ords(v_ord) := p_dim_array(1).sdo_ub; -- X
    v_ord := v_ord + 1;
    v_ords(v_ord) := p_dim_array(1).sdo_ub; -- Y
    v_ord := v_ord + 1;
    if ( p_dim_array.COUNT > 2 ) Then
      v_ords(v_ord) := p_dim_array(3).sdo_ub;
      v_ord := v_ord + 1;
      if ( p_dim_array.COUNT > 3 ) Then
        v_ords(v_ord) := p_dim_array(4).sdo_ub;
      End If;
    End If;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(mdsys.sdo_geometry(v_dims * 1000 + 3,
                                                           p_srid,
                                                           NULL,
                                                           mdsys.sdo_elem_info_array(1,1003,3),
                                                           v_ords));
  END ST_Diminfo2Rectangle;

  Member Function ST_Multi
           Return &&INSTALL_SCHEMA..t_geometry
  As
  Begin
    if ( SELF.ST_GType() in (4,5,6,7) ) Then
       return SELF;
    End If;
    Return &&INSTALL_SCHEMA..T_GEOMETRY(
             mdsys.sdo_geometry(SELF.geom.sdo_gtype+4,
                          SELF.geom.sdo_srid,
                          null,
                          case when SELF.geom.get_gtype()=1 and SELF.geom.sdo_point is not null
                               then sdo_elem_info_array(1,1,1)
                               else SELF.geom.sdo_elem_info
                           end,
                          case when SELF.geom.get_gtype()=1 and SELF.geom.sdo_point is not null
                               then case when SELF.geom.get_dims()=2
                                         then sdo_ordinate_array(SELF.geom.sdo_point.x,SELF.geom.sdo_point.y)
                                         else sdo_ordinate_array(SELF.geom.sdo_point.x,SELF.geom.sdo_point.y,SELF.geom.sdo_point.z)
                                    end
                               else SELF.geom.sdo_ordinates
                           end),
            SELF.tolerance,
            SELF.dPrecision,
            SELF.projected);
  End ST_Multi;

  Member Function ST_Polygon2Line
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    c_i_not_polygon Constant pls_integer   := -20121;
    c_s_not_polygon Constant VarChar2(100) := 'Geometry must be a polygon.';
  Begin
    -- Only support polygons and linestrings
    IF ( SELF.ST_gtype() not in (3,7) ) THEN
      raise_application_error(c_i_not_polygon,
                              c_s_not_polygon,true);
    End If;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(MDSYS.SDO_UTIL.PolygonToLine(SELF.geom),SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_Polygon2Line;

  Member Function ST_MBR
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
  Begin
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(MDSYS.SDO_GEOM.sdo_mbr(SELF.geom));
  End ST_MBR;

  Member Function ST_Envelope
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
  Begin
    RETURN SELF.ST_MBR();
  End ST_Envelope;

  Member Function ST_Append(p_geom        in mdsys.sdo_geometry,
                            p_concatenate in integer default 0)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    v_concatenate  boolean := case when NVL(p_concatenate,0) = 1 then TRUE else FALSE end;
    v_return_geom  mdsys.sdo_geometry;
    v_geom         mdsys.sdo_geometry;
    v_x_offset     pls_integer;
    v_first_vertex &&INSTALL_SCHEMA..t_vertex;
    v_last_vertex  &&INSTALL_SCHEMA..t_vertex;
    v_vertex       &&INSTALL_SCHEMA..t_vertex;
    v_offset       Number;
    v_elem         Number;
    v_num_Ords     pls_integer;
    v_base_gtype   pls_integer;
    v_start        pls_integer;

    -- A common utility function that allows for a single vertex
    -- to be added to the end of an sdo_ordinate_array
    -- All inserts are before existing vertex in same position
    --
    --PRAGMA INLINE (appendVertex, 'YES');
    Procedure appendVertex(p_ordinates   in out nocopy mdsys.sdo_ordinate_array,
                           p_vertex      &&INSTALL_SCHEMA..t_vertex,
                           p_concatenate boolean default false)
    Is
      v_ord         pls_integer := 0;
      v_x_offset    pls_integer;
      v_last_vertex &&INSTALL_SCHEMA..t_vertex;
    Begin
      If ( p_ordinates is null ) Then
        p_ordinates := new sdo_ordinate_array(0);
        p_ordinates.DELETE;
      End If;
      If ( p_concatenate ) THEN
        v_x_offset    := SELF.ST_Dims()-1;
        v_last_vertex := &&INSTALL_SCHEMA..T_Vertex(
                           p_id=>1,
                           p_x =>p_ordinates(p_ordinates.COUNT-v_x_offset),
                           p_y =>p_ordinates(p_ordinates.COUNT-(v_x_offset+1)),
                           p_z =>case when self.ST_Dims() = 3 then p_ordinates(p_ordinates.COUNT-(v_x_offset+2)) else null end,
                           p_w =>case when self.ST_Dims() = 4 then p_ordinates(p_ordinates.COUNT-(v_x_offset+3)) else null end,
                           p_sdo_gtype=>SELF.ST_Sdo_GType(),
                           p_sdo_srid =>SELF.ST_Srid()
                         );
       IF ( v_vertex.ST_Equals(p_vertex) = 1 ) Then
          Return;
        End If;
      End If;
      v_ord := p_ordinates.COUNT + 1;
      p_ordinates.EXTEND(SELF.ST_Dims());
      -- Insert first vertex
      p_ordinates(v_ord)   := p_vertex.X;
      p_ordinates(v_ord+1) := p_vertex.Y;
      If (SELF.ST_Dims()>=3) Then
         p_ordinates(v_ord+2) := p_vertex.z;
         if ( SELF.ST_Dims() > 3 ) Then
             p_ordinates(v_ord+3) := p_vertex.w;
         End If;
      End If;
    End appendVertex;

  begin
    If ( p_geom is null ) Then
      Return SELF;
    End If;
    If ( NVL(SELF.ST_Srid(),0) <> NVL(p_geom.sdo_srid,0) ) Then
      Raise_Application_Error(-20001,'SRIDs are different',True);
    End If;
    If ( SELF.ST_Dims() <> p_geom.Get_Dims() ) Then
      Raise_Application_Error(-20002,'Dimensions are different',True);
    End If;
    If ( SELF.ST_Lrs_Dim() <> p_geom.get_Lrs_Dim() ) Then
      Raise_Application_Error(-20003,'LRS dimensions are different',True);
    End If;

    -- Create output geometry from self
    --
    v_return_geom := mdsys.sdo_geometry(SELF.ST_Sdo_gtype(),
                                   SELF.ST_srid(),
                                   NULL,
                                   new mdsys.sdo_elem_info_array(0),
                                   new mdsys.sdo_ordinate_array(0));
    v_return_geom.sdo_elem_info.DELETE;
    v_return_geom.sdo_ordinates.DELETE;

    If ( SELF.geom.sdo_elem_info is not null ) Then
       v_return_geom.sdo_elem_info.Extend(SELF.geom.sdo_elem_info.COUNT);
       For i in 1..v_return_geom.sdo_elem_info.COUNT Loop
           v_return_geom.sdo_elem_info(i) := SELF.geom.sdo_elem_info(i);
       End Loop;
    End If;

    If ( SELF.geom.sdo_ordinates is not null ) Then
       v_return_geom.sdo_ordinates.Extend(SELF.geom.sdo_ordinates.COUNT);
       For i In 1..SELF.geom.sdo_ordinates.COUNT Loop
         v_return_geom.sdo_ordinates(i) := SELF.geom.sdo_ordinates(i);
       End Loop;
    ElsIf ( SELF.geom.sdo_point is not null ) Then
      -- Add SELF point's ordinates...
      appendVertex(v_return_geom.sdo_ordinates,&&INSTALL_SCHEMA..t_vertex(SELF.geom.sdo_point));
      v_return_geom.sdo_elem_info := new mdsys.sdo_elem_info_array(1,1,1);
    End If;

    -- Normalise any point point geometry parameters to sdo_ordinate_array storage.
    v_geom := p_geom;
    IF ( p_geom.Get_GType() = 1 and p_geom.sdo_point is not null ) Then
      v_geom := &&INSTALL_SCHEMA..T_GEOMETRY(p_geom,SELF.tolerance,SELF.dPrecision,SELF.projected).ST_SdoPoint2Ord().geom;
    END IF;

    -- Now append supplied geometry
    --
    v_base_gtype := ((SELF.ST_Dims()*10+SELF.ST_Lrs_Dim()) * 100 );
    If ( p_geom.Get_GType() = 1 ) Then
        v_vertex   := &&INSTALL_SCHEMA..t_vertex(v_geom);
        v_num_ords := v_return_geom.sdo_ordinates.COUNT;
        appendVertex(v_return_geom.sdo_ordinates,v_vertex,v_concatenate);
      IF ( v_num_ords = v_return_geom.sdo_ordinates.COUNT ) THEN
        -- No change to underlying geometry
        Return &&INSTALL_SCHEMA..T_Geometry(SELF.GEOM,SELF.tolerance,SELF.dPrecision,SELF.projected);
      ELSE
        v_return_geom.sdo_gtype := v_base_gtype +
                              case when SELF.ST_GType() IN (1,5)
                                   then 5
                                   else 4
                               end;
        if ( SELF.ST_Gtype() in (1,5) ) Then
          v_return_geom.sdo_elem_info := new mdsys.sdo_elem_info_array(1,1,v_return_geom.sdo_ordinates.COUNT/SELF.ST_Dims());
        Else
          v_elem := v_return_geom.sdo_elem_info.COUNT;
          v_return_geom.sdo_elem_info.EXTEND(p_geom.sdo_elem_info.COUNT);
          For i IN 1..p_geom.sdo_elem_info.COUNT Loop
            v_return_geom.sdo_elem_info(v_elem + i) := p_geom.sdo_elem_info(i);
          End Loop;
        End If;
      END IF;

    ElsIf ( p_geom.Get_GType() = 5 ) Then  -- MultiPoint
        v_offset := v_return_geom.sdo_ordinates.COUNT;
        v_return_geom.sdo_ordinates.Extend(p_geom.sdo_ordinates.COUNT);
        -- Add parameter point's ordinates
        For i In 1..p_geom.sdo_ordinates.COUNT Loop
          v_return_geom.sdo_ordinates(v_offset + i) := p_geom.sdo_ordinates(i);
        End Loop;
        v_return_geom.sdo_gtype := v_base_gtype +
                                case when SELF.ST_gtype() in (1,5) then 5
                                     else 4
                                 end;
         if ( SELF.ST_Gtype() in (1,5) ) Then
            v_return_geom.sdo_elem_info := new mdsys.sdo_elem_info_array(1,1,v_return_geom.sdo_ordinates.COUNT/SELF.ST_Dims());
         Else
            v_elem := v_return_geom.sdo_elem_info.COUNT;
            v_return_geom.sdo_elem_info.EXTEND(p_geom.sdo_elem_info.COUNT);
            For i IN 1..p_geom.sdo_elem_info.COUNT Loop
                v_return_geom.sdo_elem_info(v_elem + i) := p_geom.sdo_elem_info(i);
            End Loop;
         End If;

    ElsIf ( p_geom.Get_GType() in (2,6) ) Then  -- Linestring

        v_start := v_return_geom.sdo_ordinates.COUNT;
        -- DEBUG dbms_output.put_line('v_start = ' || v_start);

        -- Check if duplicate coordinate for two linear objects
        --
        v_offset := 1;

        if ( SELF.ST_GType() in (2,6) ) Then
          -- DEBUG dbms_output.put_line('Procesing depends on whether last coordinate <> first');
          v_x_offset     := SELF.ST_Dims()-1;
          v_last_vertex  := SELF.ST_EndVertex();
          v_first_vertex := &&INSTALL_SCHEMA..T_Vertex(
                              p_id=> 1,
                              p_x => p_geom.sdo_ordinates(1),
                              p_y => p_geom.sdo_ordinates(2),
                              p_z => case when p_geom.get_dims() > 2 then p_geom.sdo_ordinates(3) else null end,
                              p_w => case when p_geom.get_dims() > 3 then p_geom.sdo_ordinates(4) else null end,
                              p_sdo_gtype => p_geom.sdo_gtype,
                              p_sdo_srid  => p_geom.sdo_srid
                            );
          -- DEBUG dbms_output.put_line('SELF.v_last_vertex='||v_last_vertex.ST_AsText());
          -- DEBUG dbms_output.put_line('p_geom.first_vertex='||v_first_vertex.ST_AsText());
          v_offset := case when v_concatenate and
                                v_last_vertex.ST_Equals(v_first_vertex) = 1
                           then SELF.ST_Dims()
                           else 0
                        end +
                       1;
           -- DEBUG dbms_output.put_line('  v_offset is ' || v_offset);
           if ( v_offset = 1 ) Then
              v_elem := v_return_geom.sdo_elem_info.COUNT;
              v_return_geom.sdo_elem_info.extend(p_geom.sdo_elem_info.COUNT);
              For i in 1..p_geom.sdo_elem_info.COUNT Loop
                  v_return_geom.sdo_elem_info(v_elem + i) := p_geom.sdo_elem_info(i) + case when mod(i,3) = 1 then v_start else 0 end;
              End Loop;
              v_return_geom.sdo_gtype := v_base_gtype + 6;
           Else
              -- v_offset!=1 which means the ""connection point"" is considered to be the same point, we will eventually discard one point (since they are considered the same).
              -- Copy the first point of the second geometry to the end of the ordinate array.
              -- This is because according to Oracle, the second point should be the one to keep when discarding one point.
              For I In 0..(SELF.ST_Dims()-1) Loop -- Loop over the ""last coordinate"" in the oordinate array
                v_return_geom.sdo_ordinates(v_return_geom.sdo_ordinates.Count-I) := p_geom.sdo_ordinates(SELF.ST_Dims()-I);
              End Loop;
              v_return_geom.sdo_gtype := v_base_gtype + greatest(v_return_geom.Get_GType(),2);
           End If;
        Else
           v_return_geom.sdo_gtype := v_base_gtype + 4; -- Is a compound element
           -- v_elem)info already has normalised single points into elem_info_array/ordinate_array
           v_elem := v_return_geom.sdo_elem_info.COUNT;
           v_return_geom.sdo_elem_info.extend(p_geom.sdo_elem_info.COUNT);
           For i in 1..p_geom.sdo_elem_info.COUNT Loop
               v_return_geom.sdo_elem_info(v_elem + i) := p_geom.sdo_elem_info(i);
           End Loop;
        End If;
        v_return_geom.sdo_ordinates.Extend((p_geom.sdo_ordinates.COUNT - v_offset) + 1);
        -- DEBUG dbms_output.put_line('Extend= ' || (p_geom.sdo_ordinates.COUNT - v_offset + 1));
        -- DEBUG dbms_output.put_line('v_return_geom.sdo_ordinates.COUNT=' || v_return_geom.sdo_ordinates.COUNT);
        For i in v_offset..p_geom.sdo_ordinates.COUNT Loop
            -- DEBUG dbms_output.put_line('v_return_geom.sdo_ordinates(' || (v_start + (i-v_offset+1))||')='||p_geom.sdo_ordinates(i));
            v_return_geom.sdo_ordinates(v_start + (i-v_offset+1)) := p_geom.sdo_ordinates(i);
        End Loop;

      ElsIf ( p_geom.Get_GType() in (3,4,7) ) Then -- Linestring, Polygon

        v_start := v_return_geom.sdo_ordinates.COUNT;
        v_return_geom.sdo_ordinates.Extend(p_geom.sdo_ordinates.COUNT);
        For i in 1..p_geom.sdo_ordinates.COUNT Loop
            v_return_geom.sdo_ordinates(v_start + i) := p_geom.sdo_ordinates(i);
        End Loop;
        -- Dims are always equal.
        --
        v_return_geom.sdo_gtype := v_base_gtype +
                            case when SELF.ST_Dimension() = &&INSTALL_SCHEMA..t_geometry(p_geom).ST_Dimension()
                                 then case when SELF.ST_Gtype() = 3 then 7
                                           else greatest(SELF.ST_Gtype(),p_geom.Get_GType())
                                       end
                                 else 4 -- Is a compound element
                             end;
        -- DEBUG dbms_output.put_line('v_return_geom.sdo_gtype='||v_return_geom.sdo_gtype);
        --v_geom.sdo_elem_info(v_geom.sdo_elem_info.COUNT) := 1;
        v_elem := v_return_geom.sdo_elem_info.COUNT;
        v_return_geom.sdo_elem_info.extend(p_geom.sdo_elem_info.COUNT);
        For i in 1..p_geom.sdo_elem_info.COUNT Loop
            v_return_geom.sdo_elem_info( v_elem + i) := p_geom.sdo_elem_info(i) + case when mod(i,3) = 1 then v_start else 0 end;
        End Loop;

    Else
      Raise_Application_Error(-20001,'Unsupported SDO_GTYPE (' || SELF.ST_Gtype() || ').',True);
    End If;

    -- Now add the new segment
    Return &&INSTALL_SCHEMA..T_Geometry(v_return_geom,SELF.tolerance,SELF.dPrecision,SELF.projected);
  End ST_Append;

  Member Function ST_Concat_Line(p_line in mdsys.sdo_geometry)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
     c_i_notlinestring     CONSTANT INTEGER       := -20121;
     c_s_notlinestring     CONSTANT VARCHAR2(100) := 'Input geometry is not a linestring';
     c_s_selfnotlinestring CONSTANT VARCHAR2(100) := 'Main geometry is not a linestring';
     v_line                &&INSTALL_SCHEMA..T_GEOMETRY;
     v_rline               &&INSTALL_SCHEMA..T_GEOMETRY;
  Begin
     If ( SELF.ST_Dimension() <> 1 ) Then
         raise_application_error(c_i_notlinestring,c_s_selfnotlinestring,true);
     End If;
     v_line := &&INSTALL_SCHEMA..T_GEOMETRY(p_line,SELF.tolerance,SELF.dPrecision,SELF.projected);
     If ( v_line.ST_Dimension() <> 1 ) Then
         raise_application_error(c_i_notlinestring,c_s_notlinestring,true);
     End If;
     -- Do Oracle Magic.
     -- Check start / end
     -- Note: T_Vertex constructor modifies line sdo_gtype to point one.

     -- SELF.End   -> v_line.Start
     If ( SELF.ST_EndVertex()
              .St_WithinTolerance(
                  v_line.ST_StartVertex(),
                  SELF.tolerance
              ) = 1 ) Then
        -- DEBUG dbms_output.put_line('End/Start');
        Return SELF.ST_Append(v_line.geom,1);
     End If;

     -- SELF.End   -> v_line.End
     If ( SELF.ST_EndVertex()
              .ST_WithinTolerance(
                  v_line.ST_EndVertex(),
                  SELF.tolerance
               ) = 1 ) Then
        -- DEBUG dbms_output.put_line('END/END');
        v_rline := v_line.ST_Reverse_Linestring();
        Return SELF.ST_Append(v_rline.geom,1);
     End If;

     -- v_line.End   -> SELF.Start
     If ( SELF.ST_StartVertex()
              .ST_WithinTolerance(
                  v_line.ST_EndVertex(),
                  SELF.tolerance
              ) = 1 ) Then
        -- DEBUG dbms_output.put_line('START/END');
        Return v_line.ST_Append(SELF.geom,1);
     End If;

     -- v_line.Start   -> SELF.Start
     If ( SELF.ST_StartVertex()
              .ST_WithinTolerance(
                  v_line.ST_StartVertex(),
                  SELF.tolerance
              ) = 1 ) Then
        v_rline := v_line.ST_Reverse_Linestring();
        Return v_rline.ST_Append(SELF.geom,1);
     End If;
     -- DEBUG dbms_output.put_line('Not connected');
    Return SELF.ST_Append(v_line.geom,0);
  End ST_Concat_Line;

  Member Function ST_RemoveDuplicateVertices
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    c_i_not_polyline Constant pls_integer   := -20121;
    c_s_not_polyline Constant VarChar2(100) := 'Geometry must be a linestring or polygon.';
  Begin
    -- Only support polygons and linestrings
    IF ( SELF.ST_gtype() not in (2,3,6,7) ) THEN
      raise_application_error(c_i_not_polyline,
                              c_s_not_polyline,true);
    End If;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(
               MDSYS.SDO_UTIL.REMOVE_DUPLICATE_VERTICES(SELF.geom,NVL(SELF.Tolerance,0.005)),
               SELF.Tolerance,
               SELF.dPrecision,
               SELF.Projected
           );
  End ST_RemoveDuplicateVertices;

  Member Function ST_InsertVertex(p_vertex in &&INSTALL_SCHEMA..T_Vertex)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    c_i_empty_vertex    Constant pls_integer   := -20121;
    c_s_empty_vertex    Constant VarChar2(100) := 'Replacement vertex must not be null or empty';
    c_i_in_circular_arc Constant pls_integer   := -20122;
    c_s_in_circular_arc Constant VarChar2(100) := 'Insertion into existing circular arc not allowed.';
    c_i_invalid_vertex  Constant pls_integer   := -20123;
    c_s_invalid_vertex  Constant VarChar2(100) := 'Vertex insert position is invalid.';
    c_i_invalid_geom    Constant pls_integer   := -20124;
    c_s_invalid_geom    Constant VarChar2(100) := 'Vertex insert invalidated geometry. Reason: ORA-';
    -- Make a copy of the current geometry
    v_geom      mdsys.sdo_geometry :=
                 new mdsys.sdo_geometry(SELF.geom.sdo_gtype,
                                        SELF.geom.sdo_srid,
                                        SELF.geom.sdo_point,
                                        SELF.geom.sdo_elem_info,
                                        SELF.geom.sdo_ordinates);
    v_ins_posn  PLS_Integer := case when p_vertex is null then -1 else p_vertex.id end;
    v_ins_ord   pls_integer;
    v_src_ord   pls_integer;
    v_valid     varchar2(4000);
    v_vertex    &&INSTALL_SCHEMA..T_Vertex
                   := &&INSTALL_SCHEMA..T_Vertex(
                         p_id        => 0,
                         p_sdo_gtype => SELF.ST_sdo_gtype(),
                         p_sdo_srid  => SELF.ST_SRID()
                      );

    -- A common utility function that allows for a single vertex
    -- to be added to the end of an sdo_ordinate_array
    -- All inserts are before existing vertex in same position
    --
    --PRAGMA INLINE (appendVertex, 'YES');
    Procedure appendVertex(p_ordinates in out nocopy mdsys.sdo_ordinate_array,
                           p_vertex    in &&INSTALL_SCHEMA..T_Vertex)
    Is
      v_ord pls_integer := 0;
    Begin
      If ( p_ordinates is null ) Then
        p_ordinates := new sdo_ordinate_array(0);
        p_ordinates.DELETE;
      End If;
      v_ord := p_ordinates.COUNT + 1;
      p_ordinates.EXTEND(SELF.ST_Dims());
      -- Insert first vertex
      p_ordinates(v_ord)   := p_vertex.X;
      p_ordinates(v_ord+1) := p_vertex.Y;
      If (SELF.ST_Dims()>=3) Then
         p_ordinates(v_ord+2) := p_vertex.z;
         if ( SELF.ST_Dims() > 3 ) Then
             p_ordinates(v_ord+3) := p_vertex.w;
         End If;
      End If;
    End appendVertex;

  Begin
    If ( p_vertex is null ) Then
        raise_application_error(c_i_empty_vertex,
                                c_s_empty_vertex,true);
    End If;

    -- Case 1: mdsys.sdo_geometry is single point
    If ( SELF.ST_gtype() = 1 ) Then
      If (SELF.geom.sdo_point is not null) Then
        v_vertex := &&INSTALL_SCHEMA..T_Vertex(
                         p_x         => SELF.geom.sdo_point.X,
                         p_y         => SELF.geom.sdo_point.Y,
                         p_z         => SELF.geom.sdo_point.Z,
                         p_w         => NULL,
                         p_id        => 1,
                         p_sdo_gtype => SELF.ST_sdo_gtype(),
                         p_sdo_srid  => SELF.ST_SRID());
      ElsIf ( SELF.geom.sdo_ordinates is not null ) Then
        v_vertex := &&INSTALL_SCHEMA..T_Vertex(
                         p_x         => SELF.geom.sdo_ordinates(1),
                         p_y         => SELF.geom.sdo_ordinates(2),
                         p_z         => case when (SELF.ST_Dims()>2) then SELF.geom.sdo_ordinates(3) else null end,
                         p_w         => case when (SELF.ST_Dims()>3) then SELF.geom.sdo_ordinates(4) else null end,
                         p_id        => 1,
                         p_sdo_gtype => SELF.ST_sdo_gtype(),
                         p_sdo_srid  => SELF.ST_SRID());
      End If;
      v_geom.sdo_gtype     := v_geom.sdo_gtype + 4;
      v_geom.sdo_point     := null;
      v_geom.sdo_elem_info := new mdsys.sdo_elem_info_array(1,1,2);
      v_geom.sdo_ordinates := NULL;
      If (v_ins_posn is NULL OR v_ins_posn = -1) Then
        appendVertex(v_geom.sdo_ordinates,v_vertex);
        appendVertex(v_geom.sdo_ordinates,p_vertex);
        return &&INSTALL_SCHEMA..T_GEOMETRY(v_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
      ElsIf ( v_ins_posn = 1 ) Then
        appendVertex(v_geom.sdo_ordinates,p_vertex);
        appendVertex(v_geom.sdo_ordinates,v_vertex);
        return &&INSTALL_SCHEMA..T_GEOMETRY(v_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
      Else
        raise_application_error(c_i_invalid_vertex,
                                c_s_invalid_vertex,true);
      End If;
    End If;

    -- Case 2: Geometry vertices coded in sdo_ordinates.
    -- 2.1 Check if insertion is at the end
    If ( v_ins_posn is NULL OR v_ins_posn <= -1 ) Then
       v_ins_posn := SELF.ST_NumVertices() + 1;
    End If;
    -- 2.2 Can't insert a vertex beyond bounds of ordinaates ..
    If Not ( v_ins_posn BETWEEN 1 AND (SELF.ST_NumVertices()+1) ) Then
       raise_application_error(c_i_invalid_vertex,
                               c_s_invalid_vertex,true);
    End If;
    -- 2.3 Check if inserted vertex will affect circular arc
    -- Insert before start point of arc does not affect arc
    If ( SELF.ST_inCircularArc(v_ins_posn) > 1 ) Then
       raise_application_error(c_i_in_circular_arc,
                               c_s_in_circular_arc,true);
    End If;
    -- 2.4 Insert vertex in the ordinate array
    If ( v_ins_posn = (SELF.ST_NumVertices()+1) ) Then
       -- 2.4.1. First append to existing array
       appendVertex(v_geom.sdo_ordinates,p_vertex);
    Else
      -- 2.4.2. Insert anywhere else by shuffling array down
      --        until hit insertion point.
      v_geom.sdo_ordinates.EXTEND(SELF.ST_Dims());
      <<for_all_vertices>>
      FOR v_vertex_id IN REVERSE 1..(SELF.ST_NumVertices()+1) LOOP
         v_ins_ord := ((v_vertex_id-1) * SELF.ST_Dims()) + 1;
         IF (v_vertex_id > v_ins_posn) Then
            -- Shuffle vertices
            v_src_ord := v_ins_ord - SELF.ST_Dims();
            v_geom.sdo_ordinates(v_ins_ord)   := v_geom.sdo_ordinates(v_src_ord);
            v_geom.sdo_ordinates(v_ins_ord+1) := v_geom.sdo_ordinates(v_src_ord+1);
            If ( SELF.ST_dims() >= 3 ) Then
               v_geom.sdo_ordinates(v_ins_ord + 2)    := v_geom.sdo_ordinates(v_src_ord+2);
               if ( SELF.ST_Dims() > 3 ) Then
                  v_geom.sdo_ordinates(v_ins_ord + 3) := v_geom.sdo_ordinates(v_src_ord+3);
               End If;
            End If;
         ElsIf (v_vertex_id = v_ins_posn) Then
            -- Set vertex into hole
            v_geom.sdo_ordinates(v_ins_ord)          := p_vertex.X;
            v_geom.sdo_ordinates(v_ins_ord + 1)      := p_vertex.Y;
            If ( SELF.ST_dims() >= 3 ) Then
              v_geom.sdo_ordinates(v_ins_ord + 2)    := p_vertex.z;
              if ( SELF.ST_Dims() > 3 ) Then
                 v_geom.sdo_ordinates(v_ins_ord + 3) := p_vertex.w;
              End If;
            End If;
            EXIT;  -- We have made the insertion, so exit.
         End If;
      End Loop for_all_vertices;
    End If;
    -- 2.5 Fix sdo_elem_info array
    If (SELF.ST_GType()=5) Then
      -- 2.5.1 Multipoint: increase sdo_interpretation by 1
      v_geom.sdo_elem_info(3) := v_geom.sdo_elem_info(3) + 1;
    ElsIf (SELF.ST_NumElements()>1 OR SELF.ST_NumSubElements(1)>1) Then
       -- 2.5.2 If have more than one element
       -- SQL, while slower, is a very declarative way of implementing the change.
       SELECT case when e.elem = 1
                    and ( e.elem_value > 1 And e.elem_value >= e.new_ord_posn )
                   then e.elem_value + SELF.ST_Dims()
                   when e.elem = 3
                   then /*If m-point geom, add 1 to interpretation*/
                        case when (LAG(e.elem_value,1)
                                   over (order by e.rin)) = 1
                             then e.elem_value + 1
                             else e.elem_value
                         end
                   else e.elem_value
               end as new_elem_value
         BULK COLLECT INTO v_geom.sdo_elem_info
         FROM (SELECT rownum                      as rin,
                      ((v_ins_posn-1)*
                        SELF.ST_Dims())+1     as new_ord_posn,
                      rownum-(Ceil(rownum/3)-1)*3 as elem,
                      a.column_value              as elem_value
                 FROM TABLE(SELF.geom.sdo_elem_info) a
               ) e;
    End If;
    -- Check update hasn't invalidated geometry
    v_valid := sdo_geom.validate_geometry(v_geom,SELF.tolerance);
    if ( v_valid <> 'TRUE' ) Then
       raise_application_error(c_i_invalid_geom,
                               c_s_invalid_geom||v_valid,true);
    End If;
    -- Return the updated geometry
    Return &&INSTALL_SCHEMA..T_GEOMETRY(v_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_InsertVertex;

  Member Function ST_UpdateVertex (p_vertex in &&INSTALL_SCHEMA..T_Vertex)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    c_i_empty_vertex   Constant pls_integer   := -20121;
    c_s_empty_vertex   Constant VarChar2(100) := 'Replacement vertex must not be null or empty';
    c_i_invalid_vertex Constant pls_integer   := -20122;
    c_s_invalid_vertex Constant VarChar2(100) := 'Invalid vertex id value of ';
    c_i_invalid_geom   Constant pls_integer   := -20124;
    c_s_invalid_geom   Constant VarChar2(100) := 'Vertex update invalidated geometry. Reason: ORA-';
    -- Make a copy of the current geometry
    v_geom             mdsys.sdo_geometry :=
                        new mdsys.sdo_geometry(SELF.geom.sdo_gtype,
                                               SELF.geom.sdo_srid,
                                               SELF.geom.sdo_point,
                                               SELF.geom.sdo_elem_info,
                                               SELF.geom.sdo_ordinates);
    v_update_id        PLS_Integer;
    v_update_ord       pls_integer;
    v_valid            varchar2(20);
  Begin
    If ( p_vertex is null ) Then
        raise_application_error(c_i_empty_vertex,
                                c_s_empty_vertex,true);
    End If;
    -- Case 1: mdsys.sdo_geometry as single point coded in sdo_point
    If ( SELF.ST_gtype() = 1
         And v_geom.sdo_point is not null
         And v_geom.sdo_ordinates is null ) Then
      If ( NVL(p_vertex.id,-1) IN (-1,1) ) Then
        v_geom.sdo_point.X := p_vertex.X;
        v_geom.sdo_point.Y := p_vertex.Y;
        v_geom.sdo_point.Z := CASE WHEN SELF.ST_Dims() = 3 THEN p_vertex.Z ELSE NULL END;
        return &&INSTALL_SCHEMA..T_GEOMETRY(v_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
      Else
        raise_application_error(c_i_invalid_vertex,
                                c_s_invalid_vertex || to_char(NVL(p_vertex.id,-1)),
                                true);
      End If;
    End If;

    v_update_id := case when NVL(p_vertex.id,-1) = -1
                        then SELF.ST_NumVertices()
                        else p_vertex.id
                    end;

    -- Can't update a vertex that does not exist....
    If Not ( v_update_id BETWEEN 1 AND SELF.ST_NumVertices() ) Then
       raise_application_error(c_i_invalid_vertex,
                               c_s_invalid_vertex || to_char(v_update_id),
                               true);
    End If;

    -- DEBUG dbms_output.put_line('ST_UpdateVertex: ' || v_update_id);
    -- Case 2: Geometry vertices coded in sdo_ordinates.
    -- Update the vertex in the ordinate array
    -- Supplied p_vertex must have Z and W coded correctly
    --
    <<for_all_vertices>>
    FOR v_vertex_id IN 1..SELF.ST_NumVertices() LOOP
       IF (v_vertex_id = v_update_id) Then
          v_update_ord := ((v_vertex_id-1) * SELF.ST_Dims()) + 1;
          v_geom.sdo_ordinates(v_update_ord)          := p_vertex.X;
          v_geom.sdo_ordinates(v_update_ord + 1)      := p_vertex.Y;
          If ( SELF.ST_dims() >= 3 ) Then
            v_geom.sdo_ordinates(v_update_ord + 2)    := p_vertex.z;
            if ( SELF.ST_Dims() > 3 ) Then
               v_geom.sdo_ordinates(v_update_ord + 3) := p_vertex.w;
            End If;
          End If;
          EXIT;  -- We have made the update, so exit.
       End If;
    End Loop for_all_vertices;
    -- Check update hasn't invalidated geometry
    v_valid := sdo_geom.validate_geometry(v_geom,SELF.tolerance);
    if ( v_valid <> 'TRUE' ) Then
       raise_application_error(c_i_invalid_geom,
                               c_s_invalid_geom||v_valid,true);
    End If;
    -- Return the updated geometry
    Return &&INSTALL_SCHEMA..T_GEOMETRY(v_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_UpdateVertex;

  /* SDO_VertexUpdate changes the value of a vertex in a geometry.
  ** You must supply both the exact old value and the new value of the vertex to be altered.
  ** If the input geometry has Z values or measures, you must supply them as well.
  ** All vertices in the geometry which match the old value will be updated.
  ** The p_old_vertex.id field is ignored as is the p_new_vertex.id field.
  */
  Member Function ST_UpdateVertex(p_old_vertex IN &&INSTALL_SCHEMA..T_Vertex,
                                  p_new_vertex IN &&INSTALL_SCHEMA..T_Vertex)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    c_i_empty_vertex   Constant pls_integer   := -20121;
    c_s_empty_vertex   Constant VarChar2(100) := 'Old and New vertexes must not be null or empty';
    c_i_invalid_geom   Constant pls_integer   := -20124;
    c_s_invalid_geom   Constant VarChar2(100) := 'Vertex update invalidated geometry. Reason: ORA-';
    -- Make a copy of the current geometry
    v_geom             mdsys.sdo_geometry :=
                        new mdsys.sdo_geometry(SELF.geom.sdo_gtype,
                                               SELF.geom.sdo_srid,
                                               SELF.geom.sdo_point,
                                               SELF.geom.sdo_elem_info,
                                               NULL);
    v_vertex           &&INSTALL_SCHEMA..T_Vertex :=
                       &&INSTALL_SCHEMA..T_Vertex(
                         p_id        => 0,
                         p_sdo_gtype => SELF.ST_sdo_gtype(),
                         p_sdo_srid  => SELF.ST_SRID()
                       );
    v_old_vertex       &&INSTALL_SCHEMA..T_Vertex :=
                       &&INSTALL_SCHEMA..T_Vertex(
                         p_id        => 0,
                         p_sdo_gtype => SELF.ST_sdo_gtype(),
                         p_sdo_srid  => SELF.ST_SRID()
                       );
    v_new_vertex       &&INSTALL_SCHEMA..T_Vertex :=
                       &&INSTALL_SCHEMA..T_Vertex(
                         p_id        => 0,
                         p_sdo_gtype => SELF.ST_sdo_gtype(),
                         p_sdo_srid  => SELF.ST_SRID()
                       );
    v_vertices         mdsys.vertex_set_type;
    v_sdo_point        Mdsys.SDO_Point_Type;
    v_valid            varchar2(4000);

    --PRAGMA INLINE (appendVertex, 'YES');
    Procedure appendVertex(p_ordinates in out nocopy mdsys.sdo_ordinate_array,
                           p_vertex    in &&INSTALL_SCHEMA..T_Vertex)
    Is
      v_ord pls_integer := 0;
    Begin
      If ( p_ordinates is null ) Then
        p_ordinates := new sdo_ordinate_array(0);
        p_ordinates.DELETE;
      End If;
      v_ord := p_ordinates.COUNT + 1;
      p_ordinates.EXTEND(SELF.ST_Dims());
      -- Insert first vertex
      p_ordinates(v_ord)   := p_vertex.X;
      p_ordinates(v_ord+1) := p_vertex.Y;
      If (SELF.ST_Dims()>=3) Then
         p_ordinates(v_ord+2) := p_vertex.z;
         if ( SELF.ST_Dims()>3 ) Then
             p_ordinates(v_ord+3) := p_vertex.w;
         End If;
      End If;
    End appendVertex;

  Begin
    If ( p_old_vertex is null or p_new_vertex is null ) Then
        raise_application_error(c_i_empty_vertex,
                                c_s_empty_vertex,true);
    End If;
    v_old_vertex := &&INSTALL_SCHEMA..T_Vertex(
                    x         => p_old_vertex.x,
                    y         => p_old_vertex.y,
                    z         => p_old_vertex.z,
                    w         => p_old_vertex.w,
                    id        => p_old_vertex.id,
                    sdo_gtype => SELF.ST_Sdo_GType(),
                    sdo_srid  => SELF.ST_SRID(),
                    deleted   => p_old_vertex.deleted
                    );
    v_new_vertex := &&INSTALL_SCHEMA..T_Vertex(
                    x         => p_new_vertex.x,
                    y         => p_new_vertex.y,
                    z         => p_new_vertex.z,
                    w         => p_new_vertex.w,
                    id        => p_new_vertex.id,
                    sdo_gtype => SELF.ST_SDO_GType(),
                    sdo_srid  => SELF.ST_SRID(),
                    deleted   => p_new_vertex.deleted
                    );
    -- If mdsys.sdo_geometry is a single point coded in sdo_point, then update it
    If ( v_geom.sdo_point is not null ) Then
      v_vertex := &&INSTALL_SCHEMA..T_Vertex(
                      p_point     => v_geom.sdo_point,
                      p_sdo_gtype => SELF.ST_SDO_GType(),
                      p_sdo_srid  => SELF.ST_SRID()
                  );
      IF ( v_vertex.ST_Equals(v_old_vertex,SELF.dPrecision)=1 ) Then
        v_geom.sdo_point.X := p_new_vertex.X;
        v_geom.sdo_point.Y := p_new_vertex.Y;
        IF ( SELF.ST_Dims() > 2 ) Then
           v_geom.sdo_point.Z := p_new_vertex.Z;
        END IF;
      End If;
    End If;
    If ( SELF.geom.sdo_ordinates is not null ) Then
      -- Update the point in the ordinate array
      v_vertices := mdsys.sdo_util.getVertices(SELF.geom);
      <<process_all_vertices>>
      FOR i IN 1..v_vertices.COUNT LOOP
        v_vertex := &&INSTALL_SCHEMA..T_Vertex(
                       p_vertex    => v_vertices(i),
                       p_sdo_gtype => SELF.ST_SDO_GType(),
                       p_sdo_srid  => SELF.ST_SRID());
        IF ( v_vertex.ST_Equals(v_old_vertex,SELF.dPrecision) = 1 ) then
          appendVertex(v_geom.sdo_ordinates,v_new_vertex);
        ELSE
          appendVertex(v_geom.sdo_ordinates,v_vertex);
        END IF;
      END LOOP process_all_vertices;
    End If;
    -- Check update hasn't invalidated geometry
    v_valid := sdo_geom.validate_geometry(v_geom,SELF.tolerance);
    if ( v_valid <> 'TRUE' ) Then
       raise_application_error(c_i_invalid_geom,
                               c_s_invalid_geom||v_valid,true);
    End If;
    -- Return the updated geometry
    Return &&INSTALL_SCHEMA..T_GEOMETRY(v_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_UpdateVertex;

  -- Delete nominated vertex
  --
  Member Function ST_DeleteVertex(p_vertex_id in integer)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    c_i_in_circular_arc Constant pls_integer   := -20122;
    c_s_in_circular_arc Constant VarChar2(100) := 'Deletion of vertex within an existing circular arc not allowed.';
    c_i_invalid_vertex  Constant pls_integer   := -20123;
    c_s_invalid_vertex  Constant VarChar2(100) := 'Deletion vertex position is invalid.';
    c_i_invalid_geom    Constant pls_integer   := -20124;
    c_s_invalid_geom    Constant VarChar2(100) := 'Vertex delete invalidated geometry with reason: ';
    -- Make a copy of the current geometry
    v_geom              mdsys.sdo_geometry :=
                         new mdsys.sdo_geometry(
                               SELF.geom.sdo_gtype,
                               SELF.geom.sdo_srid,
                               SELF.geom.sdo_point,
                               SELF.geom.sdo_elem_info,
                               SELF.geom.sdo_ordinates
                       );
    v_offset           pls_integer;
    v_vertex           PLS_Integer := NVL(p_vertex_id,-1);
    v_delete_start_ord pls_integer; -- Start ord for deletion
    v_valid            varchar2(4000);

  Begin
    -- Case 1: single point or multi-point with only one point
    If ( SELF.ST_gtype()=1 OR
        (SELF.ST_Gtype()=5 AND SELF.ST_NumVertices()=1)) Then
       RETURN NULL;
    End If;
    -- Case 2: Geometry vertices coded in sdo_ordinates.
    --
    -- 2.1 Check if insertion is at the end
    If ( v_vertex is NULL OR v_vertex <= -1 ) Then
       v_vertex := SELF.ST_NumVertices();
    End If;
    -- 2.2 Can't delete a vertex beyond bounds of ordinaates ..
    If Not ( v_vertex BETWEEN 1
                          AND SELF.ST_NumVertices() ) Then
       raise_application_error(c_i_invalid_vertex,
                               c_s_invalid_vertex,true);
    End If;
    -- 2.3 Check if deleted vertex will affect any circular arc
    -- Can't delete any vertex an the arc.
    If ( SELF.ST_inCircularArc(v_vertex) > 0 ) Then
       raise_application_error(c_i_in_circular_arc,
                               c_s_in_circular_arc,true);
    End If;
    -- 2.4 Delete vertex from ordinate array
    If ( v_vertex = SELF.ST_NumVertices() ) Then
       -- 2.4.1. First delete by shortening if at end
       v_geom.sdo_ordinates.TRIM(SELF.ST_Dims());
    Else
      -- 2.4.2. Second delete anywhere else by shuffling array down
      --        until hit insertion point.
      v_delete_start_ord := ((v_vertex-1) * SELF.ST_Dims()) + 1;
      v_geom.sdo_ordinates.DELETE;  -- get rid of all ordinates
      <<for_all_ords>>
      FOR v_ord IN 1..SELF.geom.sdo_ordinates.COUNT LOOP
         IF NOT (v_ord between v_delete_start_ord and (v_delete_start_ord + SELF.ST_Dims() - 1)) Then
            v_geom.sdo_ordinates.EXTEND(1);
            v_geom.sdo_ordinates(v_geom.sdo_ordinates.COUNT) := SELF.geom.sdo_ordinates(v_ord);
         End If;
      End Loop for_all_vertices;
    End If;
    -- 2.5 Fix sdo_elem_info array sdo_offets if > 1 element.
    If (SELF.ST_GType()=5) Then
      -- 2.5.1 Multipoint: decrement sdo_interpretation by 1
      v_geom.sdo_elem_info(3) := v_geom.sdo_elem_info(3) - 1;
    ElsIf (SELF.ST_NumElements()>1 OR SELF.ST_NumSubElements(1)>1) Then
      -- 2.5.2 All others, sdo_offset must be correctly decremented
      -- Note: Pure PL/SQL approach (not SQL)
      v_delete_start_ord := ((v_vertex-1) * SELF.ST_Dims()) + 1;
      <<offset_processing>>
      for v_i IN 0 .. ((SELF.geom.sdo_elem_info.COUNT/3)-1) LOOP
        v_offset := v_geom.sdo_elem_info((v_i * 3) + 1);
        if ( v_offset > v_delete_start_ord ) then
           v_geom.sdo_elem_info((v_i * 3) + 1) := v_offset - SELF.ST_Dims();
        end If;
      end loop offset_processing;
    End If;
    -- 2.6 Check update hasn't invalidated geometry
    v_valid := SUBSTR(sdo_geom.validate_geometry_with_context(v_geom,SELF.tolerance),1,4000);
    if ( v_valid <> 'TRUE' ) Then
       raise_application_error(c_i_invalid_geom,
                               c_s_invalid_geom||v_valid,true);
    End If;
    -- Return the updated geometry
    Return &&INSTALL_SCHEMA..T_GEOMETRY(v_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_DeleteVertex;

  Member Function ST_Extend(p_length    in number,
                            p_start_end in varchar2 default 'START',
                            p_unit      in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    c_i_not_linestring Constant pls_integer   := -20121;
    c_s_not_linestring Constant VarChar2(100) := 'Geometry must be a linestring.';
    c_i_end_value      Constant pls_integer   := -20122;
    c_s_end_value      Constant VarChar2(100) := 'Start/End parameter value (*VALUE*) must be START, BOTH or END';
    c_i_extension_dist Constant pls_integer   := -20123;
    c_s_extension_dist Constant VarChar2(100) := 'p_length value must not be 0 or NULL.';
    v_geom_length      number := 0;
    v_start_end        varchar2(100) := UPPER(SUBSTR(NVL(p_start_end,'START'),1,100));
    v_geom             &&INSTALL_SCHEMA..T_GEOMETRY;

    --PRAGMA INLINE (Extend, 'YES');
    Procedure Extend( p_geom           in out nocopy &&INSTALL_SCHEMA..T_GEOMETRY,
                      p_end_pt_id      in Number,
                      p_internal_pt_id in Number)
    Is
      v_end_pt      &&INSTALL_SCHEMA..T_Vertex;
      v_internal_pt &&INSTALL_SCHEMA..T_Vertex;
      v_segment     &&INSTALL_SCHEMA..T_Segment;
      v_deltaX      number;
      v_deltaY      number;
      v_length      number;
    Begin
       v_end_pt      := p_geom.ST_VertexN(p_end_pt_id);
       v_internal_pt := p_geom.ST_VertexN(p_internal_pt_id);
       v_deltaX      := v_end_pt.x - v_internal_pt.x;
       v_deltaY      := v_end_pt.y - v_internal_pt.y;
       -- DEBUG dbms_output.put_line('Extend old v_length=' || v_length);
       v_segment     := &&INSTALL_SCHEMA..T_Segment(
                          p_Segment_id  => 0,
                          p_startCoord => v_end_pt,
                          p_endCoord   => v_internal_pt,
                          p_sdo_gtype  => SELF.ST_sdo_gtype,
                          p_sdo_srid   => SELF.ST_SRID(),
                          p_projected  => SELF.projected,
                          p_precision  => SELF.dPrecision,
                          p_tolerance  => SELF.tolerance
                        );
      v_length := v_segment.ST_Length(p_unit);
       -- DEBUG dbms_output.put_line('Extend T_Segment v_length=' || v_length);
      IF (v_length<>0.0) Then -- probably should get previous vertex but...
         -- Assign to global T_GEOMETRY in case BOTH extension type
         p_geom := p_geom.ST_UpdateVertex(
                     &&INSTALL_SCHEMA..T_Vertex(
                       p_x         => v_internal_pt.x+v_deltaX*((v_Length+p_length)/v_Length),
                       p_y         => v_internal_pt.y+v_deltaY*((v_Length+p_length)/v_Length),
                       p_id        => CASE SIGN(p_end_pt_id) WHEN -1 THEN NULL ELSE 1 END,
                       p_sdo_gtype => SELF.ST_sdo_gtype(),
                       p_sdo_srid  => SELF.ST_SRID()
                     )
                   );
       End If;
    End Extend;

  Begin
    -- Only support simple linestrings
    If ( SELF.ST_Dimension() <> 1 ) Then
      raise_application_error(c_i_not_linestring,
                              c_s_not_linestring,true);
    End If;
    IF ( NVL(p_length,0) = 0 ) THEN
      raise_application_error(c_i_extension_dist,
                              c_s_extension_dist,true);
    END IF;
    IF ( NOT v_start_end IN ('START','BOTH','END') ) Then
      raise_application_error(c_i_end_value,
                      REPLACE(c_s_end_value,'*VALUE*',v_start_end),true);
    END IF;

    IF ( p_length < 0 ) THEN
      RETURN SELF.ST_Reduce(p_length    => p_length,
                            p_start_end => p_start_end,
                            p_unit      => p_unit );
    END IF;

    v_geom := &&INSTALL_SCHEMA..T_GEOMETRY(SELF.geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
    IF v_start_end IN ('START','BOTH') THEN
      Extend(v_geom,1,2);
    END IF;
    IF v_start_end IN ('BOTH','END') THEN
      Extend(v_geom,-1,-2);
    END IF;
    RETURN v_geom;
  end ST_Extend;

  Member Function ST_Reduce(p_length    in number,
                            p_start_end in varchar2 default 'START',
                            p_unit      in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    c_i_not_linestring Constant pls_integer   := -20121;
    c_s_not_linestring Constant VarChar2(100) := 'Geometry must be a linestring.';
    c_i_end_value      Constant pls_integer   := -20122;
    c_s_end_value      Constant VarChar2(100) := 'Start/End parameter value (*VALUE*) must be START, BOTH or END';
    c_i_extension_dist Constant pls_integer   := -20123;
    c_s_extension_dist Constant VarChar2(100) := 'p_length value must not be 0 or NULL.';
    c_i_dist_error     Constant pls_integer   := -20124;
    c_s_dist_error     Constant VarChar2(200) := 'Reducing geometry of length (*GLEN*) by (*DIST*) at *STARTEND* would result in a zero length geometry.';
    v_geom_length      number := 0;
    v_start_end        varchar2(100) := UPPER(SUBSTR(NVL(p_start_end,'START'),1,100));
    v_geom             &&INSTALL_SCHEMA..T_GEOMETRY;
    v_geom_row         &&INSTALL_SCHEMA..T_GEOMETRY_ROW;
    v_reverse_geom     &&INSTALL_SCHEMA..T_GEOMETRY;
    v_geometries       &&INSTALL_SCHEMA..T_GEOMETRIES;
  Begin
    -- Only support simple linestrings
    If ( SELF.ST_Dimension() <> 1 ) Then
      raise_application_error(c_i_not_linestring,
                              c_s_not_linestring,true);
    End If;

    IF ( NVL(p_length,0) = 0 ) THEN
      raise_application_error(c_i_extension_dist,
                              c_s_extension_dist,true);
    END IF;

    IF ( NOT v_start_end IN ('START','BOTH','END') ) Then
      raise_application_error(c_i_end_value,
                      REPLACE(c_s_end_value,'*VALUE*',v_start_end),true);
    END IF;

    IF ( p_length > 0 ) THEN
      RETURN SELF.ST_Extend(p_length    => p_length,
                            p_start_end => p_start_end,
                            p_unit      => p_unit );
    END IF;

    -- Is Reduction distance (when BOTH) greater than actual length of string?
    IF ( ( SELF.ST_Length(p_unit) - (ABS(p_length) * CASE v_start_end WHEN 'BOTH' THEN 2.0 ELSE 1 END) ) <= 0.0 )  THEN
      Raise_Application_Error(c_i_dist_error,
              Replace(
                Replace(
                   Replace(c_s_dist_error,
                           '*GLEN*',
                           SELF.ST_Length(p_unit)
                          ),
                   '*DIST*',
                   p_length
                ),
                '*STARTEND*',
                CASE v_start_end
                     WHEN 'BOTH'  THEN 'both ends'
                     WHEN 'START' THEN 'start end'
                     WHEN 'END'   THEN 'end'
                 END
              ),true
      );
    END IF;

    -- Execute Processing.
    v_geom := &&INSTALL_SCHEMA..T_GEOMETRY(SELF.geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
    IF v_start_end IN ('START','BOTH') THEN
      -- Second element returned by ST_Split is remainder after START reduced.
      v_geometries := v_geom.ST_Split(ABS(p_length));
      v_geom_row   := v_geometries(2);
      IF ( v_start_end = 'START' ) THEN
        -- Create geometry to be returned
        v_geom := &&INSTALL_SCHEMA..T_Geometry (
                    v_geom_row.geometry,
                    SELF.tolerance,
                    SELF.dPrecision,
                    SELF.projected
                  );
      END IF;
    END IF;

    IF v_start_end IN ('BOTH','END') THEN
      IF (v_start_end = 'END' ) THEN
        -- Approach for single end is:
        -- 1. Reverse
        -- 2. Split from start
        v_geometries := v_geom
                          .ST_Reverse_Linestring()
                          .ST_Split(ABS(p_length));
        -- 3. Select second geometry
        IF ( v_geometries.COUNT > 0 and v_geometries.COUNT < 2 ) THEN
          -- This should never happen
          v_geom_row := v_geometries(1);
        ELSE
          v_geom_row := v_geometries(2);
        END IF;
        --   4. Reverse
        v_geom := &&INSTALL_SCHEMA..T_Geometry (
                    v_geom_row.geometry,
                    SELF.tolerance,
                    SELF.dPrecision,
                    SELF.projected
                  )
                  .ST_Reverse_Linestring();
        -- Reduce(v_geom,1,p_length);
      ELSE
        -- To apply END part of BOTH we:
        -- 1. Reverse linestring,
        v_reverse_geom := &&INSTALL_SCHEMA..T_GEOMETRY(
                            v_geom_row.geometry,
                            SELF.tolerance,
                            SELF.dPrecision,
                            SELF.projected
                          )
                          .ST_Reverse_Linestring();
        -- 2. Split from start
        v_geometries := v_reverse_geom
                        .ST_Split(ABS(p_length));
        -- 3. Keep second geometry
        IF ( v_geometries.COUNT > 0 and v_geometries.COUNT < 2 ) THEN
          -- This should never happen
          v_geom_row := v_geometries(1);
        ELSE
          v_geom_row := v_geometries(2);
        END IF;
        -- 4. Reverse again.
        v_geom := &&INSTALL_SCHEMA..T_Geometry (
                    v_geom_row.geometry,
                    SELF.tolerance,
                    SELF.dPrecision,
                    SELF.projected
                  )
                  .ST_Reverse_Linestring();
      END If;
    END IF;
    RETURN v_geom;
  End ST_Reduce;

  Member Function ST_Cogo2Line(p_bearings_and_distances in &&INSTALL_SCHEMA..T_BEARING_DISTANCES)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  as
    v_line        mdsys.sdo_geometry;
    v_vertex      &&INSTALL_SCHEMA..T_Vertex;
    v_next_vertex &&INSTALL_SCHEMA..T_Vertex;
    v_dims        pls_integer;
  begin
    -- Base geometry must be a vertex.
    IF ( SELF.ST_Dimension() <> 0 ) THEN
      return null;
    END IF;
    IF (p_bearings_and_distances is null or p_bearings_and_distances.COUNT = 0 ) THEN
      return null;
    END IF;
    v_dims  := SELF.ST_Dims();
    IF ( v_dims not in (2,3) ) THEN
      return null;
    END IF;
    v_vertex := &&INSTALL_SCHEMA..T_Vertex(SELF.geom);
    -- Create basic line
    v_line := sdo_geometry((v_dims*1000)+2,
                           SELF.geom.sdo_srid,
                           null,
                           sdo_elem_info_array(1,2,1),
                           case v_dims
                           when 2 then sdo_ordinate_array(v_vertex.x,v_vertex.y)
                           when 3 then sdo_ordinate_array(v_vertex.x,v_vertex.y,v_vertex.z)
                            end
                          );
    For i in p_bearings_and_distances.FIRST..p_bearings_and_distances.LAST
    loop
      v_next_vertex := v_vertex.ST_FromBearingAndDistance(p_bearings_and_Distances(i).bearing,
                                                          p_bearings_and_Distances(i).distance,
                                                          SELF.projected);
      -- DEBUG dbms_output.put_line(COGO.ST_Degrees(v_vertex.ST_Bearing(v_next_vertex,SELF.projected)));
      -- DEBUG dbms_output.put_line(v_vertex.ST_Distance(v_next_vertex));
      v_line.sdo_ordinates.extend(v_dims);
      v_line.sdo_ordinates(v_line.sdo_ordinates.count-(v_dims-1)) := v_next_vertex.x;
      v_line.sdo_ordinates(v_line.sdo_ordinates.count-(v_dims-2)) := v_next_vertex.y;
      IF ( v_dims = 3 ) Then
        v_line.sdo_ordinates(v_line.sdo_ordinates.count)          := p_bearings_and_Distances(i).z;
      End If;
      v_vertex := v_next_vertex;
    End Loop;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(v_line,SELF.tolerance,SELF.dPrecision,SELF.projected);
  end ST_Cogo2Line;

  Member Function ST_Line2Cogo (p_unit in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_BEARING_DISTANCES Pipelined
  As
    v_cogo         &&INSTALL_SCHEMA..T_Bearing_Distance := NEW &&INSTALL_SCHEMA..T_Bearing_Distance( 0.0, 0.0, null );
    v_start_vertex &&INSTALL_SCHEMA..T_Vertex;
    v_dims         pls_integer;
  Begin
    -- Base geometry must be a simple linestring.
    IF (   SELF.ST_Dimension() <> 1
       and SELF.ST_NumGeometries() = 1 ) THEN
      Return;
    END IF;
    v_dims  := SELF.ST_Dims();
    -- 2D and 3D only
    IF ( v_dims not in (2,3) ) THEN
      Return;
    END IF;
    v_start_vertex := &&INSTALL_SCHEMA..T_Vertex(
                         p_id       => 0,
                         p_x        => 0.0,
                         p_y        => 0.0,
                         p_z        => CASE WHEN v_dims = 2 THEN NULL ELSE 0.0  END,
                         p_sdo_gtype=> CASE WHEN v_dims = 2 THEN 2001 ELSE 3001 END,
                         p_sdo_srid => SELF.ST_Srid()
                      );
    For rec in (select v.ST_Self() as vertex
                  from TABLE(CAST(SELF.ST_Vertices() as &&INSTALL_SCHEMA..T_Vertices)) v
             )
    loop
      v_cogo.bearing  := v_start_vertex.ST_Bearing (p_vertex=>rec.vertex,p_projected=>SELF.projected,p_normalize=>1);
      v_cogo.distance := v_start_vertex.ST_Distance(p_vertex=>rec.vertex,p_tolerance=>SELF.tolerance,p_unit=>p_unit);
      v_cogo.Z        := rec.vertex.Z;
      PIPE ROW ( v_cogo );
      v_start_vertex  := rec.vertex;
    End Loop;
    Return;
  end ST_Line2Cogo;

  Member Function ST_Cogo2Polygon(p_bearings_and_distances in &&INSTALL_SCHEMA..T_BEARING_DISTANCES)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    v_polygon      mdsys.sdo_geometry;
    v_tLine        &&INSTALL_SCHEMA..T_Geometry;
    v_start_vertex &&INSTALL_SCHEMA..T_Vertex;
    v_last_vertex  &&INSTALL_SCHEMA..T_Vertex;
    v_dims         pls_integer;
  Begin
    -- Base geometry must be a point.
    IF ( SELF.ST_Dimension() <> 0 ) THEN
      return null;
    END IF;
    IF (p_bearings_and_distances is null or p_bearings_and_distances.COUNT = 0 ) THEN
      return null;
    END IF;
    v_dims         := SELF.ST_Dims();
    v_start_vertex := &&INSTALL_SCHEMA..T_Vertex(SELF.geom);
    -- Use ST_Cogo2Line to general exterior ring.
    v_tLine        := SELF.ST_Cogo2Line(p_bearings_and_distances);
    -- Now convert linestring to polygon
    IF (v_tLine is not null ) THEN
      v_polygon := sdo_geometry(v_tLine.ST_Sdo_GType()+1,
                                SELF.geom.sdo_srid,
                                null,
                                sdo_elem_info_array(1,1003,1),
                                v_tLine.geom.sdo_ordinates
                               );
      v_last_vertex := &&INSTALL_SCHEMA..T_Vertex(v_tLine.ST_EndVertex());
      -- Close polygon (if needed)
      if ( v_start_vertex.ST_Equals(v_last_vertex,SELF.dPrecision) = 0 )  Then
        v_polygon.sdo_ordinates.extend(v_dims);
        v_polygon.sdo_ordinates(v_polygon.sdo_ordinates.count-(v_dims-1)) := ROUND(v_start_vertex.x,NVL(SELF.dPrecision,3));
        v_polygon.sdo_ordinates(v_polygon.sdo_ordinates.count-(v_dims-2)) := ROUND(v_start_vertex.y,NVL(SELF.dPrecision,3));
        IF ( v_dims = 3 ) Then
          v_polygon.sdo_ordinates(v_polygon.sdo_ordinates.count)          := v_start_vertex.z;
        End If;
      End If;
      Return &&INSTALL_SCHEMA..T_GEOMETRY(v_polygon,SELF.tolerance,SELF.dPrecision,SELF.projected);
    End If;
    Return SELF;
  End ST_Cogo2Polygon;

  Member Function ST_TravellingSalesman(p_start_gid   in integer,
                                        p_start_point in mdsys.sdo_point_type default NULL,
                                        p_geo_fence   in mdsys.sdo_geometry   default NULL,
                                        p_unit        in varchar2             default NULL )
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  as
    v_dims               pls_integer;
    v_point_gtype        pls_integer;
    v_points_lrs_dim     pls_integer;
    v_geo_fence_class    pls_integer;
    v_num_points         pls_integer;
    v_start_id           pls_integer;
    v_next_id            pls_integer;
    v_point_id           pls_integer;
    v_point_set          mdsys.vertex_set_type;
    v_current_point      &&INSTALL_SCHEMA..T_Vertex;
    v_current_point_geom mdsys.sdo_geometry;
    v_line_geom          mdsys.sdo_geometry;
    v_temp_line_geom     mdsys.sdo_geometry;
    v_geo_fence          &&INSTALL_SCHEMA..T_Geometry;
    v_geo_fence_segs     &&INSTALL_SCHEMA..T_Geometries;
    v_relate             varchar2(100);
    v_ignore_fence       Integer := 0;
    v_distance           number;
    v_unit               varchar2(100) := case when SELF.ST_SRID() is null
                                               Then NULL
                                               Else case when SUBSTR(UPPER(p_unit),1,4) like 'UNIT%'
                                                         then p_unit
                                                         else case when p_unit is null
                                                                   then null
                                                                   else 'unit='||p_unit
                                                               end
                                                     end
                                           end;

  Begin
    -- DEBUG dbms_output.put_line('<ST_TravellingSalesman>');
    If ( SELF.geom.sdo_ordinates is null ) Then
      Return null;
    End If;

    If ( SELF.ST_GType() NOT IN (4,5) ) Then
      -- DEBUG dbms_output.put_line('ST_TravellingSalesman can only be run against a GeometryCollection of Points or a MultiPoint geometry');
      Return null;
    End If;

    If ( p_start_gid is null and p_start_point is null ) Then
      Return null;
    End If;

    v_geo_fence       := NULL;
    v_geo_fence_class := 0;
    IF ( p_geo_fence IS NOT NULL ) THEN
      v_geo_fence := &&INSTALL_SCHEMA..T_GEOMETRY(p_geo_fence,SELF.tolerance,SELF.dPrecision,SELF.projected);
      -- Since we iterate over the fences many times, create collection once
      SELECT &&INSTALL_SCHEMA..T_GEOMETRY_ROW(t.gid,t.geometry,t.tolerance,t.dPrecision,t.projected) as geom
        BULK COLLECT
        INTO v_geo_fence_segs
        FROM TABLE(&&INSTALL_SCHEMA..T_Geometry(p_geo_fence,SELF.tolerance,SELF.dPrecision,SELF.projected)
                        .ST_Extract()
                  ) t;
      v_geo_fence_class := NVL(v_geo_fence.ST_VertexN(1).Z,-9);
      -- DEBUG dbms_output.put_line('... v_geo_fence_class='||v_geo_fence_class);
    END IF;

    v_dims           := SELF.ST_Dims();
    v_points_lrs_dim := SELF.geom.get_lrs_dim();
    v_point_gtype    := (v_dims * 1000) + (SELF.geom.get_lrs_dim()*100) + 1;
    v_start_id       :=  1;
    v_next_id        := -1;
    v_point_set      := mdsys.sdo_util.getVertices(SELF.geom);
    v_num_points     := v_point_set.COUNT;
    -- DEBUG dbms_output.put_line('. v_dims('||v_dims||') v_num_points('||v_num_points||')');
    v_current_point := NEW &&INSTALL_SCHEMA..T_Vertex(
                         p_x         => v_point_set(1).x,
                         p_y         => v_point_set(1).y,
                         p_z         => v_point_set(1).z,
                         p_w         => v_point_set(1).w,
                         p_id        => v_point_set(1).z,
                         p_sdo_gtype => v_point_gtype,
                         p_sdo_srid  => SELF.ST_Srid()
                      );
    If ( p_start_gid is not null ) Then
      <<FindStartingPointLoop>>
      For i in 1..v_num_points loop
        -- DEBUG dbms_output.put_line('Comparing ('||v_point_set(i).Z||') to ('||p_start_gid||')');
        IF ( v_point_set(i).Z = p_start_gid ) THEN
          v_start_id := i;
          v_current_point := NEW &&INSTALL_SCHEMA..T_Vertex(
            p_x         => v_point_set(v_start_id).x,
            p_y         => v_point_set(v_start_id).y,
            p_z         => v_point_set(v_start_id).z,
            p_w         => v_point_set(v_start_id).w,
            p_id        => v_start_id,
            p_sdo_gtype => v_point_gtype,
            p_sdo_srid  => SELF.ST_Srid()
          );
          v_point_set.DELETE(v_start_id);
          v_num_points := v_num_points - 1;
          exit; -- loop
        END IF;
      End Loop FindStartingPointLoop;
      v_num_points    := v_point_set.COUNT;
      v_next_id       := v_start_id;
      -- DEBUG dbms_output.put_line('... Found starting point using GID('||p_start_gid||') at position '||v_start_id||' with ' || v_num_points || ' points to process');
    ElsIf ( p_start_point is not null and p_start_point.x is not null ) Then
      v_current_point := NEW &&INSTALL_SCHEMA..T_Vertex(
            p_x         => p_start_point.x,
            p_y         => p_start_point.y,
            p_z         => p_start_point.z,
            p_w         => NULL,
            p_id        => 0,
            p_sdo_gtype => v_point_gtype,
            p_sdo_srid  => SELF.ST_Srid()
      );
      v_next_id := -999;
    End If;

    -- Return is a linestring whose vertices are ordered by distance
    v_line_geom := mdsys.sdo_geometry((v_dims * 1000) + (SELF.geom.get_lrs_dim()*100) + 2,
                                      SELF.geom.sdo_srid,
                                      NULL,
                                      mdsys.sdo_elem_info_array(1,2,1),
                                      case when v_dims=2 then mdsys.sdo_ordinate_array(v_current_point.x,v_current_point.y)
                                           when v_dims=3 then mdsys.sdo_ordinate_array(v_current_point.x,v_current_point.y,v_current_point.z)
                                           when v_dims=4 then mdsys.sdo_ordinate_array(v_current_point.x,v_current_point.y,v_current_point.z,v_current_point.w)
                                       end
                                     );

    <<ProcessAllNavigablePoints>>
    v_point_id := 1;
    While ( v_point_id <= v_num_points ) Loop
    BEGIN
      -- DEBUG dbms_output.put_line('.. Processing point ' || v_point_id || ' of ' || v_num_points ||' with ' || case when v_ignore_fence=1 then 'IGNORE' else 'HONOUR' end || '('||v_ignore_fence||') Fence Mode');
      -- DEBUG dbms_output.put_line('... Current Point is ' || v_current_point.ST_AsText());
      -- DEBUG dbms_output.put('... Closest Node Found To ' || case when v_next_id=-999 then 'user supplied point ' else to_char(v_next_id) end);

      -- Find nearest in-memory point
      v_current_point_geom := v_current_point.ST_SdoGeometry();

      select f.next_id,
             f.relate,
             f.distance,
             &&INSTALL_SCHEMA..T_Vertex(
               p_x         => f.x,
               p_y         => f.y,
               p_z         => f.z,
               p_w         => f.w,
               p_id        => f.next_gid,
               p_sdo_gtype => v_point_gtype,
               p_sdo_srid  => f.srid
             ) as current_vertex
        into v_next_id,
             v_relate,
             v_distance,
             v_current_point
        from (select e.next_gid,
                     e.next_id,
                     e.x,e.y,e.w,
                     case when v_ignore_fence = 1 then -1 * e.z else e.z end as z,
                     e.relate,
                     e.distance,
                     e.geo_fence_z,
                     min(e.distance) over (partition by e.relate order by e.distance) as min_distance,
                     e.srid
                from (SELECT t.id as next_id,
                             case SELF.geom.get_lrs_dim() when 0 then t.id when 3 then t.z else t.w end as next_gid,
                             t.x,t.y,t.z,t.w,
                             v_geo_fence_class                 as geo_fence_z,
                             CAST('DISJOINT' as varchar2(100)) as relate,
                             /* Compute distance between current and table point */
                             case when v_unit is null
                                  then MDSYS.SDO_GEOM.SDO_Distance(
                                         mdsys.sdo_geometry(2001,SELF.geom.sdo_srid,null,mdsys.sdo_elem_info_array(1,1,1),mdsys.sdo_ordinate_array(t.x,t.y)),
                                         v_current_point_geom,
                                         SELF.tolerance)
                                  Else MDSYS.SDO_GEOM.SDO_Distance(
                                         mdsys.sdo_geometry(2001,SELF.geom.sdo_srid,null,mdsys.sdo_elem_info_array(1,1,1),mdsys.sdo_ordinate_array(t.x,t.y)),
                                         v_current_point_geom,
                                         SELF.tolerance,
                                         v_unit)
                              end as distance,
                             SELF.geom.sdo_srid as srid
                        FROM TABLE(v_point_set) t
                       WHERE v_geo_fence is null
                      UNION ALL
                      SELECT t.id as next_id,
                             case SELF.geom.get_lrs_dim() when 0 then t.id when 3 then t.z else t.w end as next_gid,
                             t.x,t.y,t.z,t.w,
                             v_geo_fence_class as geo_fence_z,
                             MDSYS.SDO_GEOM.RELATE(
                                 mdsys.sdo_geometry(2002,SELF.geom.sdo_srid,NULL,mdsys.sdo_elem_info_array(1,2,1),mdsys.sdo_ordinate_array(t.x,t.y,v_current_point.x,v_current_point.y)),
                                 'DISJOINT',
                                 &&INSTALL_SCHEMA..T_GEOMETRY(g.geometry,SELF.tolerance,SELF.dPrecision,SELF.projected)
                                      .ST_To2D()
                                      .geom,
                                 SELF.tolerance
                             ) as relate,
                             /* Compute distance between current and table point */
                             case when v_unit is null
                                  then MDSYS.SDO_GEOM.SDO_Distance(
                                         mdsys.sdo_geometry(2001,SELF.geom.sdo_srid,null,mdsys.sdo_elem_info_array(1,1,1),mdsys.sdo_ordinate_array(t.x,t.y)),
                                         v_current_point_geom,
                                         SELF.tolerance
                                       )
                                  Else MDSYS.SDO_GEOM.SDO_Distance(
                                         mdsys.sdo_geometry(2001,SELF.geom.sdo_srid,null,mdsys.sdo_elem_info_array(1,1,1),mdsys.sdo_ordinate_array(t.x,t.y)),
                                         v_current_point_geom,
                                         SELF.tolerance
                                       )
                              end as distance,
                             SELF.geom.sdo_srid as srid
                        FROM TABLE(v_point_set)      t
                             ,TABLE(v_geo_fence_segs) g
                      WHERE v_geo_fence is not null
                     ) e
                ORDER BY e.distance, e.geo_fence_z asc
             ) f
       WHERE (   ( f.relate <> 'DISJOINT' and f.distance = f.min_distance and (f.geo_fence_z <> -9 or v_ignore_fence = 1))
              OR ( f.relate  = 'DISJOINT' and f.distance = f.min_distance )
             )
         AND rownum < 2;

      -- DEBUG dbms_output.put_line(' @'||v_distance||'m is ' || v_next_id || ' (table) with gid ('||v_current_point.id||') ' || v_current_point.ST_AsText() || ' Relate ('||v_relate||')');

      -- Add nearest point to output line
      v_line_geom.sdo_ordinates.EXTEND(v_dims);
      v_line_geom.sdo_ordinates(v_line_geom.sdo_ordinates.COUNT-(v_dims-1))   := v_current_point.x;
      v_line_geom.sdo_ordinates(v_line_geom.sdo_ordinates.COUNT-(v_dims-2))   := v_current_point.y;
      IF ( v_dims >= 3 ) THEN
        v_line_geom.sdo_ordinates(v_line_geom.sdo_ordinates.COUNT-(v_dims-3)) := v_current_point.z;
        IF ( v_dims > 3 ) THEN
          v_line_geom.sdo_ordinates(v_line_geom.sdo_ordinates.COUNT)          := v_current_point.w;
        END IF;
      END IF;

      -- DEBUG dbms_output.put_line('...... Added point ' || v_next_id || ' to v_line_geom.sdo_ordinates(count)=' || v_line_geom.sdo_ordinates.COUNT );

      -- Delete this point from point set for next iteration
      v_point_set.DELETE(v_next_id);
      v_ignore_fence   := 0;
      v_point_id       := v_point_id + 1;
      -- DEBUG dbms_output.put_line('... Removed point ' || v_next_id || ' from point set with ' || v_point_set.COUNT || ' left to process');

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
           -- DEBUG dbms_output.put_line('.... Skipping an isolated point because crosses immoveable fence.');
           v_ignore_fence := 1;
        WHEN OTHERS THEN
           -- dbms_output.put_line('.... Others exception.');
           raise_application_error(-20101,'OTHERS: ' || SQLERRM);
    END;
    End Loop ProcessAllNavigablePoints;
    -- DEBUG dbms_output.put_line('... Finished: ' || to_char(v_point_set.COUNT) || ' vertices left to process.');
    -- DEBUG dbms_output.put_line('</ST_TravellingSalesman>');
    Return &&INSTALL_SCHEMA..T_GEOMETRY(v_line_geom,SELF.tolerance,SELF.dPrecision,SELF.projected);
  End ST_TravellingSalesman;

 /* ************************************************************ */
 /*                      TRANSFORMATIONS                         */
 /* ************************************************************ */

   Member Function ST_Rotate(p_angle        in number,
                             p_dir          in integer,
                             p_rotate_point in mdsys.sdo_geometry,
                             p_line1        in mdsys.sdo_geometry)
            Return &&INSTALL_SCHEMA..T_GEOMETRY
   As
     v_angle_radians number;
   Begin
     -- dir - Rotation parameter for x(0), y(1), or z(2)-axis roll.
     --       You cannot set p_dir => 0, 1 or 2.
     --       Only -1, -2, -3. They don't see to affect the result.
     -- For two-dimensional geometries, rotation uses the p1 and angle values.
     If ( SELF.ST_Dims() = 2 ) Then
       If ( p_angle is null and p_rotate_point is null ) Then
          raise_application_error(-20001,'For 2D geometry rotation, p_angle and p_rotate_point must not be null',true);
       End If;
     Else
         -- For three-dimensional geometries, rotation uses either:
         --     1. the angle and dir values or
         --     2. the angle and line1 values.
         If ( p_angle is null ) Then
            raise_application_error(-20001,'For 3D geometry rotation, p_angle must not be null',true);
         End If;
         If ( p_dir is null and p_line1 is null ) Then
            raise_application_error(-20001,'For 3D geometry rotation, both p_dir and p_line1 cannot be null',true);
         End If;
     End If;
     v_angle_radians := &&INSTALL_SCHEMA..COGO.ST_Radians(p_degrees=>p_angle);
     Return &&INSTALL_SCHEMA..T_GEOMETRY(
     mdsys.SDO_UTIL.AffineTransforms (
           geometry => SELF.geom,
           rotation => 'TRUE',
                 p1 => p_rotate_point,
              angle => v_angle_radians,
                dir => p_dir,
              line1 => p_line1,
        translation => 'FALSE',    tx => 0.0,     ty => 0.0,    tz => 0.0,
            scaling => 'FALSE',  psc1 => NULL,    sx => 0.0,    sy => 0.0,   sz => 0.0,
           shearing => 'FALSE',  shxy => 0.0,   shyx => 0.0,  shxz => 0.0, shzx => 0.0, shyz => 0.0, shzy => 0.0,
         reflection  => 'FALSE', pref => NULL, lineR => NULL, dirR => -1,
             planeR => 'FALSE',     n => null,  bigD => null
    ),SELF.Tolerance,SELF.dPrecision,SELF.Projected);
   End ST_Rotate;

   Member Function ST_Rotate(p_angle in number,
                             p_rx    in number,
                             p_ry    in number)
   Return &&INSTALL_SCHEMA..T_GEOMETRY
   As
     c_i_parameters CONSTANT INTEGER       := -20121;
     c_s_parameters CONSTANT VARCHAR2(100) := 'p_angle must not be null.';
     c_i_2d_support CONSTANT INTEGER       := -20122;
     c_s_2d_support CONSTANT VARCHAR2(100) := 'This version of ST_Rotate only supports 2D geometry rotation.';
     v_mbr                   &&INSTALL_SCHEMA..T_GEOMETRY;
     v_rx                    NUMBER;
     v_ry                    NUMBER;
   Begin
     -- dir - Rotation parameter for x(0), y(1), or z(2)-axis roll.
     -- For two-dimensional geometries, rotation uses the p1 and angle values.
     If ( SELF.ST_Dims() = 2 ) Then
       If ( p_angle is null ) Then
          raise_application_error(c_i_parameters,c_s_parameters,true);
       End If;
     Else
       raise_application_error(c_i_2d_support,c_s_2d_support,true);
     End If;
     -- Check rotation point
     IF ( p_rx is null or p_ry is null ) Then
       IF ( SELF.ST_Dimension() = 0 ) THEN
         -- Rotate point around itself is itself.
         Return SELF;
       END IF;
       v_mbr := SELF.ST_MBR();
       IF ( v_mbr is null ) THEN
      Return NULL;
       End If;
       -- With have an optimized rectangle MBR
       -- Extract RX/RY from centre of MBR.
       -- Note, only support 2D at the moment
       v_rx := (v_mbr.geom.sdo_ordinates(3)+v_mbr.geom.sdo_ordinates(1)) / 2.0;
       v_ry := (v_mbr.geom.sdo_ordinates(4)+v_mbr.geom.sdo_ordinates(2)) / 2.0;
     Else
       v_rx := p_rx;
       v_ry := p_ry;
     End If;
     Return SELF.ST_Rotate(p_angle        => p_angle,
                           p_dir          => -1,
                           p_rotate_point => mdsys.sdo_geometry(2001,SELF.ST_Srid(),mdsys.sdo_point_type(v_rx,v_ry,NULL),NULL,NULL),
                           p_line1        => NULL);
   End ST_Rotate;

   Member Function ST_Rotate(p_angle        in number,
                             p_rotate_point in mdsys.sdo_geometry)
            Return &&INSTALL_SCHEMA..T_GEOMETRY
   As
     v_mbr    &&INSTALL_SCHEMA..T_GEOMETRY;
     v_vertex &&INSTALL_SCHEMA..T_VERTEX;
     v_rx     NUMBER;
     v_ry     NUMBER;
   Begin
     -- dir - Rotation parameter for x(0), y(1), or z(2)-axis roll.
     -- For two-dimensional geometries, rotation uses the p1 and angle values.
     If ( SELF.ST_Dims() = 2 ) Then
        If ( p_angle is null ) Then
          raise_application_error(-20001,'p_angle must not be null.',true);
        End If;
     Else
        raise_application_error(-20001,'This version of ST_Rotate only supports 2D geometry rotation.',true);
     End If;
     IF ( p_rotate_point is null ) Then
       IF ( SELF.ST_Dimension() = 0 ) THEN
         -- Rotate point around itself is itself.
         Return SELF;
       END IF;
       v_mbr := SELF.ST_MBR();
       IF ( v_mbr is null ) THEN
         Return NULL;
       End If;
       -- With have an optimized rectangle MBR
       -- Extract RX/RY from centre of MBR.
       -- Note, only support 2D at the moment
       v_rx := (v_mbr.geom.sdo_ordinates(3)+v_mbr.geom.sdo_ordinates(1)) / 2.0;
       v_ry := (v_mbr.geom.sdo_ordinates(4)+v_mbr.geom.sdo_ordinates(2)) / 2.0;
     Else
       v_vertex := &&INSTALL_SCHEMA..T_VERTEX(p_rotate_point);
       v_rx := v_vertex.x;
       v_ry := v_vertex.y;
     End If;
     Return SELF.ST_Rotate(p_angle        => p_angle,
                           p_dir          => -1,
                           p_rotate_point => mdsys.sdo_geometry(2001,SELF.ST_Srid(),mdsys.sdo_point_type(v_rx,v_ry,NULL),NULL,NULL),
                           p_line1        => NULL);
   End ST_Rotate;

   Member Function ST_Rotate(p_angle in number)
            Return &&INSTALL_SCHEMA..T_GEOMETRY
   As
     v_mbr &&INSTALL_SCHEMA..T_GEOMETRY;
     v_rx  NUMBER;
     v_ry  NUMBER;
   Begin
      -- dir - Rotation parameter for x(0), y(1), or z(2)-axis roll.
      -- For two-dimensional geometries, rotation uses the p1 and angle values.
      If ( SELF.ST_Dims() = 2 ) Then
        If ( p_angle is null ) Then
          raise_application_error(-20001,'p_angle must not be null.',true);
        End If;
      Else
        raise_application_error(-20001,'This version of ST_Rotate only supports 2D geometry rotation.',true);
      End If;
      IF ( SELF.ST_Dimension() = 0 ) THEN
         -- Rotate point around itself is itself.
        Return SELF;
      END IF;
      v_mbr := SELF.ST_MBR();
      IF ( v_mbr is null ) THEN
        Return NULL;
      End If;
      -- With have an optimized rectangle MBR
      -- Extract RX/RY from centre of MBR.
      -- Note, only support 2D at the moment
      v_rx := (v_mbr.geom.sdo_ordinates(3)+v_mbr.geom.sdo_ordinates(1)) / 2.0;
      v_ry := (v_mbr.geom.sdo_ordinates(4)+v_mbr.geom.sdo_ordinates(2)) / 2.0;
      Return SELF.ST_Rotate(p_angle        => p_angle,
                            p_dir          => -1,
                            p_rotate_point => mdsys.sdo_geometry(2001,SELF.ST_SRID(),mdsys.sdo_point_type(v_rx,v_ry,NULL),null,null),
                            p_line1        => NULL);
   End ST_Rotate;

   /** =================================================================== **/

   /**  Scales the geometry to a new size by multiplying the ordinates with the parameters:
   *    ST_Scale(Xfactor, Yfactor, Zfactor, scale Point).
   *    ST_Scale(Xfactor, Yfactor, Zfactor).
   *    ST_Scale(Xfactor, Yfactor).
   **/
   Member Function ST_Scale(p_sx       in number,
                            p_sy       in number,
                            p_sz       in number default null,
                            p_scale_point in mdsys.sdo_geometry default null)
            Return &&INSTALL_SCHEMA..T_GEOMETRY
   As
     -- psc1 is Point on the input geometry about which to perform the scaling
     v_gtype  pls_integer;
     v_vertex mdsys.vertex_type;
     v_psc1   mdsys.sdo_geometry;
   Begin
      -- Point on the input geometry about which to perform the scaling.
      -- This geometry should be either a zero point (with 0,0 or 0,0,0
      -- ordinates for scaling about the origin) or a nonzero point (with ordinates
      -- for scaling about a point other than the origin).
      v_gtype := TRUNC(NVL(SELF.ST_sdo_gtype(),
                           SELF.ST_Dims()*1000+1)/10)*10+1;
      if ( p_scale_point is null ) then
        v_psc1     := mdsys.sdo_geometry(v_gtype,SELF.ST_SRID(),mdsys.sdo_point_type(0.0,0.0,case when v_gtype=3001 then 0.0 else null end),null,null);
      else
        IF ( p_scale_point.sdo_point is not null ) THEN
          v_psc1   := mdsys.sdo_geometry(v_gtype,SELF.ST_SRID(),p_scale_point.sdo_point,null,null);
        ELSE
          v_vertex := mdsys.sdo_util.getVertices(p_scale_point)(1);
          v_psc1   := mdsys.sdo_geometry(v_gtype,SELF.ST_SRID(),mdsys.sdo_point_type(v_vertex.x,v_vertex.y,v_vertex.z),null,null);
        End If;
      End If;
      Return &&INSTALL_SCHEMA..T_GEOMETRY(
      mdsys.SDO_UTIL.AffineTransforms (
           geometry => SELF.geom,
            scaling => 'TRUE',
               psc1 => v_psc1,
                 sx => case when p_sx is null then 0.0 else p_sx end,
                 sy => case when p_sy is null then 0.0 else p_sy end,
                 sz => case when p_sz is null then 0.0 else p_sz end,
           rotation => 'FALSE',   p1 => NULL, angle => 0.0,   dir => -1, line1 => NULL,
        translation => 'FALSE',   tx => 0.0,     ty => 0.0,    tz => 0.0,
           shearing => 'FALSE', shxy => 0.0,   shyx => 0.0,  shxz => 0.0, shzx => 0.0, shyz => 0.0, shzy => 0.0,
         reflection => 'FALSE', pref => NULL, lineR => NULL, dirR => -1,
        planeR      => 'FALSE',    n => null,  bigD => null
     ),SELF.Tolerance,SELF.dPrecision,SELF.Projected);
   End ST_Scale;

   /** =================================================================== **/

   /** Translates the geometry to a new location using the numeric parameters as offsets.
   *   ST_Translate(geom, X, Y) or
   *   ST_Translate(geom, X, Y, Z)
   **/
   Member Function ST_Translate(p_tx in number,
                                p_ty in number,
                                p_tz in number default null)
            Return &&INSTALL_SCHEMA..T_GEOMETRY
   As
   Begin
    Return &&INSTALL_SCHEMA..T_GEOMETRY(
    mdsys.SDO_UTIL.AffineTransforms (
        geometry    => SELF.geom,
        translation => 'TRUE',
          tx => case when p_tx is null then 0.0 else p_tx end,
          ty => case when p_ty is null then 0.0 else p_ty end,
          tz => case when (p_tz is null or SELF.ST_Dims()=2) then 0.0 else p_tz end,
        scaling    => 'FALSE', psc1 => NULL,    sx => 0.0,    sy => 0.0,   sz => 0.0,
        rotation   => 'FALSE', p1   => NULL, angle => 0.0,   dir => -1, line1 => NULL,
        shearing   => 'FALSE', shxy => 0.0,   shyx => 0.0,  shxz => 0.0, shzx => 0.0, shyz => 0.0, shzy => 0.0,
        reflection => 'FALSE', pref => NULL, lineR => NULL, dirR => -1,
        planeR     => 'FALSE',    n => null,  bigD => null
    ),SELF.Tolerance,SELF.dPrecision,SELF.Projected);
   End ST_Translate;

   Member Function ST_Reflect(p_reflect_geom  in mdsys.sdo_geometry,
                              p_reflect_plane in number default -1)
            Return &&INSTALL_SCHEMA..T_GEOMETRY
   As
     c_i_reflect_geom  CONSTANT INTEGER       := -20121;
     c_s_reflect_geom  CONSTANT VARCHAR2(100) := 'p_reflect_geom must be point (self-reflection) or single linestring (reflection about an axis).';
     c_i_reflect_dir   CONSTANT INTEGER       := -20122;
     c_s_reflect_dir   CONSTANT VARCHAR2(100) := 'p_reflect_plane must be -1 for 2D or 0 (yz plane), 1 (xz plane), or 2 (xy plane) for 3D .';
     c_i_reflect_param CONSTANT INTEGER       := -20122;
     c_s_reflect_param CONSTANT VARCHAR2(100) := '*X*D p_reflect_geom cannot have p_reflect_plane value of *DIRD*.';
   Begin
     If ( p_reflect_geom is null OR p_reflect_geom.get_gtype() not in (1,2) ) Then
       raise_application_error(c_i_reflect_geom,
                               c_s_reflect_geom,true);
     End If;
     if ( NVL(p_reflect_plane,-1) not in (-1,0,1,2) ) Then
       raise_application_error(c_i_reflect_dir,
                               c_s_reflect_dir,true);
     End If;
     -- If the dirR parameter is not used (2D) a value of -1 must be specified
     if ( ( p_reflect_geom.get_dims() = 2 and NVL(p_reflect_plane,-1) = -1 )
          AND
          ( p_reflect_geom.get_dims() = 3 and NVL(p_reflect_plane,-1) <> -1 ) ) Then
       raise_application_error(c_i_reflect_param,
                               REPLACE(
                                 REPLACE(c_s_reflect_param,
                                         '*DIRD*',NVL(p_reflect_plane,-1)),
                                 '*X*',p_reflect_geom.get_dims()),true);

     End If;
     Return &&INSTALL_SCHEMA..T_GEOMETRY(
     mdsys.SDO_UTIL.AffineTransforms (
          geometry    => SELF.geom,
          reflection  => 'TRUE',
                pref  => case when p_reflect_geom.get_gtype()=1 then p_reflect_geom else NULL end,
                dirR  => NVL(p_reflect_plane,-1),
                lineR => case when p_reflect_geom.get_gtype()=2 then p_reflect_geom else NULL end,
          translation => 'FALSE',tx => 0.0, ty => 0.0, tz => 0.0,
          scaling     => 'FALSE', psc1 => NULL, sx => 0.0, sy => 0.0, sz => 0.0,
          rotation    => 'FALSE', p1 => NULL, line1 => NULL,angle => 0.0, dir => 0,
          shearing    => 'FALSE', shxy => 0.0, shyx => 0.0, shxz => 0.0, shzx => 0.0, shyz => 0.0, shzy => 0.0,
          planeR      => 'FALSE', n => NULL,   bigD => NULL
       ),SELF.Tolerance,SELF.dPrecision,SELF.Projected);
     End ST_Reflect;

   Member Function ST_RotTransScale(p_angle    in number,
                                    p_rs_point in mdsys.sdo_geometry,
                                    p_sx       in number,
                                    p_sy       in number,
                                    p_sz       in number,
                                    p_tx       in number,
                                    p_ty       in number,
                                    p_tz       in number)
            Return &&INSTALL_SCHEMA..T_GEOMETRY
   As
     v_gtype         pls_integer;
     v_psc1          mdsys.sdo_geometry;
     v_vertex        mdsys.vertex_type;
     v_angle_radians NUMBER;
   Begin
     -- dir - Rotation parameter for x(0), y(1), or z(2)-axis roll.
     --       You cannot set p_dir => 0, 1 or 2. Only -1, -2, -3. They don't see to affect the result.
     -- For two-dimensional geometries, rotation uses the p1 and angle values.
     If ( SELF.ST_Dims() = 2 ) Then
       If ( p_angle is null and p_rs_point is null ) Then
          raise_application_error(-20001,'For 2D geometry rotation, p_angle and p_rs_point must not be null.',true);
       End If;
     Else
       raise_application_error(-20001,'This function does not support 3D geometry rotation - Use other functions.',true);
     End If;
     v_gtype := (SELF.ST_Dims()*1000) + 1;
     if ( p_rs_point is null ) then
        v_psc1 := mdsys.sdo_geometry(v_gtype,SELF.ST_SRID(),mdsys.sdo_point_type(0.0,0.0,case when v_gtype=3001 then 0.0 else null end),null,null);
     else
        v_vertex := mdsys.sdo_util.getVertices(p_rs_point)(1);
        v_psc1   := mdsys.sdo_geometry(v_gtype,SELF.ST_SRID(),mdsys.sdo_point_type(v_vertex.x,v_vertex.y,case when v_gtype=3001 then v_vertex.z else null end),null,null);
     end if;
     v_angle_radians := &&INSTALL_SCHEMA..COGO.ST_Radians(p_degrees=>p_angle);
     Return &&INSTALL_SCHEMA..T_GEOMETRY(
     mdsys.SDO_UTIL.AffineTransforms (
        geometry    => SELF.geom,
           rotation => 'TRUE',
                 p1 => p_rs_point,
              angle => v_angle_radians,
                dir => -1,
              line1 => NULL,
        translation => 'TRUE',
                 tx => case when p_tx is null then 0.0 else p_tx end,
                 ty => case when p_ty is null then 0.0 else p_ty end,
                 tz => case when (p_tz is null or SELF.ST_Dims()=2) then 0.0 else p_tz end,
            scaling => 'TRUE',
               psc1 => v_psc1,
                 sx => case when p_sx is null then 0.0 else p_sx end,
                 sy => case when p_sy is null then 0.0 else p_sy end,
                 sz => case when p_sz is null then 0.0 else p_sz end,
        shearing    => 'FALSE', shxy => 0.0,   shyx => 0.0,  shxz => 0.0, shzx => 0.0, shyz => 0.0, shzy => 0.0,
        reflection  => 'FALSE', pref => NULL, lineR => NULL, dirR => -1,
        planeR      => 'FALSE',    n => null,  bigD => null
    ),SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_RotTransScale;

  /* ----------------------------------------------------------------------------------------
  * @function   : Affine
  * @precis     : Applies a 3d affine transformation to the geometry to do things like translate, rotate, scale in one step.
  * @version    : 1.0
  * @description: Applies a 3d affine transformation to the geometry to do things like translate, rotate, scale in one step.
  *               To apply a 2D affine transformation only supply a, b, d, e, xoff, yoff
  * @usage      : Function Affine ( p_geom IN MDSYS.SDO_GEOMETRY,
  * @param      : p_geom  : MDSYS.SDO_GEOMETRY : The shape to rotate.
  * @param      : a, b, c, d, e, f, g, h, i, xoff, yoff, zoff :
  *               Represent the transformation matrix
  *                 / a  b  c  xoff \
  *                 | d  e  f  yoff |
  *                 | g  h  i  zoff |
  *                 \ 0  0  0     1 /
  *               and the vertices are transformed as follows:
  *                 x' = a*x + b*y + c*z + xoff
  *                 y' = d*x + e*y + f*z + yoff
  *                 z' = g*x + h*y + i*z + zoff
  * @requires   : SYS.UTL_NLA Package
  *               SYS.UTL_NLA_ARRAY_DBL Type
  *               SYS.UTL_NLA_ARRAY_INT Type
  * @return     : geom  : &&INSTALL_SCHEMA..T_GEOMETRY : Transformed input geometry.
  * @note       : Cartesian arithmetic only
  *             : Not for Oracle XE. Only 10g and above.
  * @history    : Simon Greener, SpatialDB Advisor - Feb 2009 - Original coding.
  * @copyright  : Simon Greener, 2011, 2012
  * @license    : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               Any bugs or improvements to be supplied back to Simon Greener
  **/
  Member Function ST_Affine(p_a    in number,
                            p_b    in number,
                            p_c    in number,
                            p_d    in number,
                            p_e    in number,
                            p_f    in number,
                            p_g    in number,
                            p_h    in number,
                            p_i    in number,
                            p_xoff in number,
                            p_yoff in number,
                            p_zoff in number)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
     c_i_null_parameter CONSTANT INTEGER       := -20127;
     c_s_null_parameter CONSTANT VARCHAR2(100) := 'Input parameters must not be null';
      -- Transformation matrix is represented by:
      -- / a  b  c  xoff \
      -- | d  e  f  yoff |
      -- | g  h  i  zoff |
      -- \ 0  0  0     1 /
      --
      -- For 2D only need to supply: a, b, d, e, xoff, yoff
      v_A          SYS.UTL_NLA_ARRAY_DBL :=
                   SYS.UTL_NLA_ARRAY_DBL(
                       p_a,            p_d,    NVL(p_g,0),    0,
                       p_b,            p_e,    NVL(p_h,0),    0,
                       NVL(p_c,0), NVL(p_f,0), NVL(p_i,1),    0,
                       p_xoff,         p_yoff, NVL(p_zoff,0), 1 );
      v_C           SYS.UTL_NLA_ARRAY_DBL;  -- Coordinates to be transformed
      v_ipiv        SYS.utl_nla_array_int := SYS.utl_nla_array_int(0,0,0,0);
      -- Geometry variables
      v_measure_dim PLS_Integer;
      v_ord         PLS_Integer;
      v_sdo_point   mdsys.sdo_point_type := NULL;
      v_trans_point mdsys.sdo_point_type;
      v_ordinates   mdsys.sdo_ordinate_array := NULL;

      --PRAGMA INLINE (TransformPoint, 'YES');
      Function TransformPoint(p_x in number,
                              p_y in number,
                              p_z in number)
        Return mdsys.sdo_point_type
      Is
        v_info  Integer;
        v_point mdsys.sdo_point_type := mdsys.sdo_point_type(p_x,p_y,p_z);
      Begin
        v_C := SYS.UTL_NLA_ARRAY_DBL(p_x,
                                     p_y,
                                     case when p_z is null then 0 else p_z end,  -- Supply 0 instead of NULL as this will crash LAPACK_GESV
                                     0);
       --  Vertices are transformed as follows:
       --  x' = a*x + b*y + c*z + xoff
       --  y' = d*x + e*y + f*z + yoff
       --  z' = g*x + h*y + i*z + zoff
       --
       SYS.UTL_NLA.LAPACK_GESV (
          n      => 4,      -- The number of linear equations
          nrhs   => 1,      -- B number of columns
          a      => v_A,    -- matrix A
          lda    => 4,      -- max(1, n)
          ipiv   => v_ipiv, -- pivot indices (set to zeros)
          b      => v_C,    -- matrix Result
          ldb    => 4,      -- ldb >= max(1,n)
          info   => v_info, -- operation status (0=sucess)
          pack   => 'C'     -- how the matrices are stored
                            -- (C=column-wise)
        );
        IF (v_info = 0) THEN
          v_point.x := v_C(1);
          v_point.y := v_C(2);
          v_point.z := case when p_z is null then null else v_C(3) end;  -- Return correct value only if one supplied.
        ELSE
          raise_application_error( -20001,
                                   'Matrix transformation by LAPACK_GESV failed with error ' || v_info,
                                   False );
        END IF;
        RETURN v_point;
      End TransformPoint;

   Begin
      If ( p_a is null OR
           p_b is null OR
           p_d is null OR
           p_e is null OR
           p_xoff is null OR
           p_yoff is null ) Then
        raise_application_error( c_i_null_parameter,c_s_null_parameter,true );
     End If;
     v_measure_dim := SELF.ST_Lrs_Dim();

    -- Transform any point in the geometry object
    If ( SELF.geom.sdo_point is not null ) Then
      v_sdo_point := TransformPoint(SELF.geom.sdo_point.x,
                                    SELF.geom.sdo_point.y,
                                    SELF.geom.sdo_point.z);
    End If;

    If ( SELF.geom.sdo_ordinates is not null ) Then
      v_ordinates := new mdsys.sdo_ordinate_array(1);
      v_ordinates.DELETE;
      v_ordinates.EXTEND(SELF.geom.sdo_ordinates.count);
      v_ord    := 1;
      -- Loop around coordinates and apply matrix to them.
      <<for_all_coords>>
      FOR coord in (SELECT v.*
                      FROM TABLE(mdsys.sdo_util.GetVertices(SELF.geom)) v)
      LOOP
        v_trans_point := TransformPoint(coord.x,
                                        coord.y,
                                        case when v_measure_dim=3 then null else coord.z end);
        v_ordinates(v_ord) := v_trans_point.x; v_ord := v_ord + 1;
        v_ordinates(v_ord) := v_trans_point.y; v_ord := v_ord + 1;
        if ( SELF.ST_Dims() >= 3 ) Then
           v_ordinates(v_ord) := v_trans_point.z; v_ord := v_ord + 1;
        end if;
        if ( SELF.ST_Dims() >= 4 ) Then
           v_ordinates(v_ord) := coord.w; v_ord := v_ord + 1;
        end if;
      END LOOP for_all_coords;
    End If;
    Return &&INSTALL_SCHEMA..T_GEOMETRY(
         mdsys.sdo_geometry(SELF.geom.sdo_gtype,
                      SELF.ST_Srid(),
                      v_sdo_point,
                      SELF.geom.sdo_elem_info,
                      v_ordinates
    ),SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_Affine;

  Member Function ST_Compress (p_delta_factor in number default 1,
                               p_origin       in &&INSTALL_SCHEMA..T_Vertex default null )
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  AS
    v_geometry     mdsys.sdo_geometry;
    v_delta_factor number := NVL(p_delta_factor,1);
  Begin
    v_geometry := sdo_geometry(SELF.geom.sdo_gtype,
                               SELF.geom.sdo_srid,
                               SELF.geom.sdo_point,
                               SELF.geom.sdo_elem_info,
                               new mdsys.sdo_ordinate_array());
    V_Geometry.Sdo_Ordinates.EXTEND(SELF.geom.Sdo_Ordinates.COUNT);
    FOR rec IN (Select v.id,
                       v.x, lag(v.x,1) over (order by v.id) as prevX,
                       v.y, lag(v.y,1) over (order by v.id) as prevY,
                       v.z, lag(v.z,1) over (order by v.id) as prevZ,
                       v.w, lag(v.w,1) over (order by v.id) as prevW
                  From Table(CAST(SELF.ST_Vertices() as &&INSTALL_SCHEMA..T_Vertices)) v
               )
    LOOP
      IF ( rec.id = 1 ) THEN
        IF ( p_origin is not null ) THEN
          v_geometry.sdo_ordinates(1) := rec.x - p_origin.x;
          v_geometry.sdo_ordinates(2) := rec.y - p_origin.y;
        ELSE
          v_geometry.sdo_ordinates(1) := rec.x;
          v_geometry.sdo_ordinates(2) := rec.y;
        END IF;
        Continue;
      END IF;
      v_geometry.sdo_ordinates(rec.id*2-1) := v_delta_factor * (rec.X-rec.prevX);
      v_geometry.sdo_ordinates(rec.id*2)   := v_delta_factor * (rec.y-rec.prevY);
    END LOOP;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(v_geometry,SELF.tolerance,SELF.dPrecision,SELF.projected);
  End ST_Compress;

  Member Function ST_Decompress(p_delta_factor in number default 1,
                                p_origin       in &&INSTALL_SCHEMA..T_Vertex default null )
           Return &&INSTALL_SCHEMA..T_Geometry
  AS
    v_geometry     mdsys.sdo_geometry;
    v_delta_factor number := NVL(p_delta_factor,1);
  Begin
    v_geometry := sdo_geometry(SELF.geom.sdo_gtype,
                               SELF.geom.sdo_srid,
                               SELF.geom.sdo_point,
                               SELF.geom.sdo_elem_info,
                               new mdsys.sdo_ordinate_array());
    V_Geometry.Sdo_Ordinates.EXTEND(SELF.geom.Sdo_Ordinates.COUNT);
    FOR rec IN (Select v.id, v.x, v.y, v.z, v.w
                  From Table(CAST(SELF.ST_Vertices() as &&INSTALL_SCHEMA..T_Vertices)) v
               )
    LOOP
      IF ( rec.id = 1 ) THEN
        IF ( p_origin is not null ) THEN
          v_geometry.sdo_ordinates(1) := rec.x + p_origin.x;
          v_geometry.sdo_ordinates(2) := rec.y + p_origin.y;
        ELSE
          v_geometry.sdo_ordinates(1) := rec.x;
          v_geometry.sdo_ordinates(2) := rec.y;
        END IF;
        Continue;
      END IF;
      v_geometry.sdo_ordinates(rec.id*2-1) := v_geometry.sdo_ordinates((rec.id-1)*2-1) + (rec.x/v_delta_factor);
      v_geometry.sdo_ordinates(rec.id*2)   := v_geometry.sdo_ordinates((rec.id-1)*2  ) + (rec.y/v_delta_factor);
    END LOOP;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(v_geometry,SELF.tolerance,SELF.dPrecision,SELF.projected);
  End ST_Decompress;

  Member Function ST_Centroid_P
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    c_i_unsupported Constant Integer       := -20121;
    c_s_unsupported Constant VarChar2(100) := 'Unsupported geometry type (*GTYPE*)';
    v_vertices      mdsys.vertex_set_type;
    v_centroid      mdsys.sdo_point_type;
    v_numVertices   Number;
  BEGIN
    If ( SELF.ST_Dimension() <> 0 ) Then
       raise_application_error(c_i_unsupported,
                               REPLACE(c_s_unsupported,
                                       '*GTYPE*',SELF.ST_GeometryType()),true);
    END IF;

    -- If Single Point return
    If ( SELF.ST_GType() = 1 ) Then
      Return SELF;
    END IF;

    -- Rough as guts SQL average will do!
    v_vertices    := mdsys.sdo_util.getVertices(SELF.geom);
    v_numVertices := v_vertices.COUNT;
    v_centroid    := new mdsys.sdo_point_type(0.0,0.0,CASE WHEN SELF.ST_Dims()=2 then NULL else 0.0 end);
    <<for_all_vertices>>
    FOR v_i IN v_vertices.FIRST..v_vertices.LAST LOOP
      v_centroid.x := v_centroid.x + v_vertices(v_i).x;
      v_centroid.y := v_centroid.y + v_vertices(v_i).y;
      v_centroid.z := v_centroid.z + v_vertices(v_i).z;
    END LOOP for_all_Vertices;

    RETURN &&INSTALL_SCHEMA..T_GEOMETRY (
             mdsys.sdo_geometry(SELF.ST_Dims() * 1000 + 1,
                                SELF.ST_Srid(),
                                mdsys.sdo_point_type(round((v_centroid.x / v_numVertices),NVL(SELF.dPrecision,8)),
                                                     round((v_centroid.y / v_numVertices),NVL(SELF.dPrecision,8)),
                                                     (v_centroid.z / v_numVertices)
                                ),
                                null,
                                null),
              SELF.tolerance,
              SELF.dPrecision,
              SELF.projected);
  End ST_Centroid_P;

  Member Function ST_Centroid_L(p_option in varchar2 := 'LARGEST',
                                p_unit   in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    c_i_unsupported     Constant Integer       := -20121;
    c_s_unsupported     Constant VarChar2(100) := 'Unsupported geometry type (*GTYPE*)';
    c_i_option_value    Constant pls_integer   := -20122;
    c_s_option_value    Constant VarChar2(100) := 'p_option value (*VALUE*) must be SMALLEST, LARGEST, MULTI.';

    v_option_value      varchar2(10) := SUBSTR(TRIM(BOTH ' ' FROM NVL(p_option,'LARGEST')),1,10);
    v_current_meas      pls_integer :=0;
    v_centroid_len_meas pls_integer :=0;
    v_egeom             &&INSTALL_SCHEMA..t_geometry;
    v_centroid          mdsys.sdo_geometry;
  Begin
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_unsupported,
                               REPLACE(c_s_unsupported,
                                       '*GTYPE*',SELF.ST_GeometryType()),true);
    END IF;
    IF ( NOT v_option_value IN ('SMALLEST','LARGEST','MULTI') ) Then
      raise_application_error(c_i_option_value,
                              REPLACE(c_s_option_value,'*VALUE*',v_option_value),true);
    END IF;
    <<for_all_linestrings_in_multi>>
    FOR v_elem IN 1..SELF.ST_NumElements() LOOP
      v_egeom        := &&INSTALL_SCHEMA..T_GEOMETRY(mdsys.sdo_util.Extract(SELF.geom,v_elem),
                                        SELF.tolerance,SELF.dPrecision,SELF.projected);  -- Extract linestring
      v_current_meas := v_egeom.ST_LRS_Measure_Range(p_unit); -- Detects measure/length
      if ( SELF.ST_NumElements() = 1 ) Then
         Return v_egeom.ST_LRS_Locate_Measure(
                           p_measure => v_current_meas / 2,
                           p_offset  => 0,
                           p_unit    => p_unit
                );
      End If;
      if ( v_elem = 1 ) Then
          if ( v_option_value = 'LARGEST' ) Then
              v_centroid_len_meas := -1;
          ElsIf ( v_option_value = 'SMALLEST' ) Then
              v_centroid_len_meas := SELF.ST_LRS_Measure_Range(p_unit) + 1;
          End If;
      End If;
      If ( v_option_value = 'MULTI' ) Then
          if ( v_centroid is null ) then
             v_centroid := v_egeom.ST_LRS_Locate_Measure(
                                      p_measure => v_egeom.ST_LRS_Start_Measure()+(v_current_meas/2),
                                      p_offset  => 0,
                                      p_unit    => p_unit).geom;
          Else
             v_centroid := mdsys.sdo_util
                                .append(v_centroid,
                                        v_egeom.ST_LRS_Locate_Measure(
                                                   p_measure => v_egeom.ST_LRS_Start_Measure()+(v_current_meas/2),
                                                   p_offset  => 0,
                                                   p_unit    => p_unit).geom
                                 );
          End If;
      Else -- Smallest or Largest
          -- SGG These are the same but should be different?
          if ( v_option_value = 'LARGEST' and v_current_meas > v_centroid_len_meas ) Then
             v_centroid := v_egeom.ST_LRS_Locate_Measure(
                                      p_measure => v_egeom.ST_LRS_Start_Measure()+(v_current_meas/2),
                                      p_offset  => 0,
                                      p_unit    => p_unit
                                  ).geom;
             v_centroid_len_meas := v_current_meas;
          ElsIf ( v_option_value = 'SMALLEST' and v_current_meas < v_centroid_len_meas ) Then
             v_centroid := v_egeom.ST_LRS_Locate_Measure(
                                      p_measure => v_egeom.ST_LRS_Start_Measure()+(v_current_meas/2),
                                      p_offset  => 0,
                                      p_unit    => p_unit
                                  ).geom;
             v_centroid_len_meas := v_current_meas;
          End If;
      End If;
    END LOOP for_all_linestrings_in_multi;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(v_centroid,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_Centroid_L;

  Member Function ST_Centroid_A(
                     P_method     In Integer Default 1,
                     P_Seed_Value In Number  Default Null,
                     p_loops      in integer Default 10)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  AS
    c_i_method   Constant Integer       := -20001;
    c_s_method   Constant VarChar2(100) := 'Method parameter must be one of (0, 1, 2, 3, 4, 10, 11, 12).';
    c_i_seed     Constant Integer       := -20002;
    c_s_seed     Constant VarChar2(100) := 'Seed value not provided.';
    c_i_x_seed   Constant Integer       := -20003;
    c_s_x_seed   Constant VarChar2(100) := 'Seed value for p_method 2 (X) not between provided geometry''s MBR''s X ordinate range.';
    c_i_y_seed   Constant Integer       := -20004;
    c_s_y_seed   Constant VarChar2(100) := 'Seed value for p_method 12 (Y) not between provided geometry''s MBR''s Y ordinate range.';
    c_i_fail     CONSTANT INTEGER       := -20005;
    c_s_fail     CONSTANT VARCHAR2(250) := 'Calculation of Centroid for Area failed: perhaps supplied tolerance is not in projection units eg 0.000001 decimal degrees?';
    c_i_polygon  CONSTANT INTEGER       := -20006;
    c_s_polygon  CONSTANT VARCHAR2(250) := 'Method only operates on a single polygon. If MultiPolygon, use ST_Multi_Centroid.';

    v_method     pls_integer := NVL(p_method,1);
    v_mbr        MDSYS.SDO_GEOMETRY;
    v_seed_value NUMBER      := p_seed_value;
    v_centroid   MDSYS.SDO_GEOMETRY;
    v_loop       pls_integer := NVL(p_loops,10);
    v_not_inside boolean     := true;
  Begin
    -- Single Polygons only
    IF ( SELF.ST_GeometryType() <> 'ST_POLYGON' ) THEN
      raise_application_error(c_i_polygon,c_s_polygon,TRUE);
      Return SELF;
    END IF;
    /*    p_method     (integer) --  0 = Use average of all Area's X Ordinates for starting centroid Calculation
     *                              10 = Use average of all Area's Y Ordinates for starting centroid Calculation
     *                               1 = Use centre X Ordinate of geometry MBR
     *                              11 = Use centre Y Ordinate of geometry MBR
     *                               2 = User supplied starting seed X ordinate value
     *                              12 = User supplied starting seed Y ordinate value
     *                               3 = Use MDSYS.SDO_GEOM.SDO_CENTROID function
     *                               4 = Use Oracle implementation of PointOnSurface
    */
    IF ( v_method NOT IN (0, 1, 2, 3, 4, 10, 11, 12) ) THEN
      raise_application_error(c_i_method,c_s_method,TRUE);
    END IF;

    If ( v_method IN (2,12) AND p_Seed_Value IS NULL ) THEN
       raise_application_error(c_i_seed,c_s_seed,TRUE);
    END IF;

    -- Handle Oracle calls first
    IF ( v_method in (3,4) ) Then
      RETURN &&INSTALL_SCHEMA..T_GEOMETRY(
               CASE v_method
                    WHEN  3 THEN MDSYS.SDO_GEOM.sdo_centroid      (SELF.geom,SELF.tolerance)
                    WHEN  4 THEN MDSYS.SDO_GEOM.sdo_PointOnsurface(SELF.geom,SELF.tolerance)
                END,
               SELF.tolerance,
               SELF.dPrecision,
               SELF.projected);
    END IF;

    -- Get X or Y ordinate from non user supplied values
    -- Need MBR for value checking.
    v_mbr := SELF.ST_MBR().geom;

    -- Create starting seed point geometry from average of ordinates
    --
    IF ( v_method = 0 /* X as avg all ordinates */ ) THEN
      SELECT round(avg(p.x), SELF.dPrecision) as x
        INTO v_seed_value
        FROM TABLE(SELF.ST_Vertices()) p;
    ELSIF ( v_method = 10 /* Y as avg all ordinates */ ) THEN
      SELECT round(avg(p.Y), SELF.dPrecision) as Y
        INTO v_seed_value
        FROM TABLE(SELF.ST_Vertices()) p;
    ELSIF ( v_method = 1 /* Centre X of MBR */ ) THEN
      v_seed_value := (v_mbr.sdo_ordinates(1 + SELF.ST_Dims()) + v_mbr.sdo_ordinates(1)) / 2.0;
    ELSIF ( v_method = 11 /* Centre Y of MBR */ ) THEN
      v_seed_value := (v_mbr.sdo_ordinates(2 + SELF.ST_Dims()) + v_mbr.sdo_ordinates(2)) / 2.0;
    ELSIF ( v_method = 2 ) THEN
       -- Check user seed between MBR X ordinate range of object
       IF ( v_Seed_Value <= v_mbr.sdo_ordinates(1)
         OR v_Seed_Value >= v_mbr.sdo_ordinates(1+SELF.ST_Dims()) ) THEN
         raise_application_error(c_i_x_seed,c_s_x_seed,TRUE);
       END IF;
    ELSIF ( v_method = 12 ) THEN
       -- Check user seed between MBR Y ordinate range of object
       IF ( v_Seed_Value <= v_mbr.sdo_ordinates(2)
         OR v_Seed_Value >= v_mbr.sdo_ordinates(2+SELF.ST_Dims()) ) THEN
         raise_application_error(c_i_y_seed,c_s_y_seed,TRUE);
       END IF;
    END IF;

    -- Now find Centroid
    -- Centroid X is based on average x ordinate
    -- Centroid Y is computed using a variation on flood filling area geometries in graphics libraries
    -- (In following, the use of MDSYS.SDO_GEOM.sdo_mbr is posited on its use being licensed. If not, use the CENTROID.sdo_mbr() function in this package)
    --
    WHILE (v_not_inside and v_loop > 0) LOOP
      BEGIN
      v_seed_value := ROUND(v_seed_value,SELF.dPrecision + 1);
      -- DEBUG dbms_output.put_line('v_seed_value(' || v_loop || '): '||v_seed_value);
      IF ( v_method in (0,1,2) ) Then
        SELECT MDSYS.SDO_GEOMETRY(2001,
                                  SELF.geom.SDO_SRID,
                                  mdsys.sdo_point_type(f.CX,f.CY,NULL),
                                  NULL,NULL)
          INTO v_centroid
          FROM (SELECT z.x                 as cx,
                       z.y + ( ydiff / 2 ) as cy
                  FROM (SELECT w.id,
                               w.x,
                               w.y,
                               case when w.ydiff is null then 0 else w.ydiff end as ydiff,
                               case when w.id = 1
                                    then case when w.inout = 1
                                              then 'INSIDE'
                                              else 'OUTSIDE'
                                          end
                                    when w.inout = 99
                                    then 'OUTSIDE'
                                    when MOD(SUM(w.inout) OVER (ORDER BY w.id),2) = 1
                                         /* Need to look at previous result as inside/outside is a binary switch */
                                    then 'INSIDE'
                                    else 'OUTSIDE'
                                end as inout
                          FROM (SELECT rownum as id,
                                       u.x,
                                       u.y,
                                       case when u.touchCross in (-1,0,1) /* Cross */ then 1
                                            when u.touchCross in (-2,2)   /* Touch */ then 0
                                            when u.touchCross >= 99                   then 99
                                            else 0
                                        end as inout,
                                       ABS(LEAD(u.y,1) OVER(ORDER BY u.y) - u.y) As YDiff
                                  FROM (SELECT s.x,
                                               s.y,
                                               /* In cases where polygons have boundaries/holes that touch at a point we need to count them more than once */
                                               case when count(*) > 2 then 1 else sum(s.touchcross) end as touchcross
                                          FROM (SELECT t.element_id, t.subelement_id,
                                                       t.x,
                                                       t.y,
                                                       t.touchCross
                                                  FROM (SELECT r.element_id, r.subelement_id,
                                                               r.x,
                                                               case when (r.endx = r.startx)
                                                                    then (r.starty + r.endy ) / 2
                                                                    else round(r.starty + ( (r.endy-r.starty)/(r.endx-r.startx) ) * (r.x-r.startx),SELF.dPrecision)
                                                                end as y,
                                                                case when ( r.x = r.startx and r.x = r.endx )
                                                                     then 99 /* Line is Vertical ie two touches */
                                                                     when ( ( r.x = r.startx and r.x > r.endx )
                                                                              or
                                                                            ( r.x = r.endX   and r.x > r.startX )
                                                                          )
                                                                     then -1 /* Left Touch */
                                                                     when ( ( r.x = r.endX   and r.x < r.startX  )
                                                                              or
                                                                            ( r.x = r.startX and r.x < r.endX )
                                                                          )
                                                                      then 1 /* Right Touch */
                                                                      else 0 /* cross */
                                                                  end as TouchCross
                                                            FROM (SELECT seg.element_id    as element_id,
                                                                         seg.subelement_id as subelement_id,
                                                                         v_seed_value      as x,
                                                                         round(seg.startCoord.x,SELF.dPrecision) as startX,
                                                                         round(seg.startCoord.y,SELF.dPrecision) as startY,
                                                                         round(  seg.endCoord.x,SELF.dPrecision) as endX,
                                                                         round(  seg.endCoord.y,SELF.dPrecision) as endY
                                                                     FROM TABLE(SELF.ST_Segmentize(p_filter      =>'X',
                                                                                                   p_filter_value=>v_Seed_Value)) seg
                                                                 ) r
                                                        ) t
                                                  ORDER BY t.y
                                               ) s
                                        /*WHERE s.touchCross <> 99*/
                                        GROUP BY s.element_id, s.subelement_id, s.x, s.y
                                        ORDER BY s.y
                                       ) u
                               ) w
                       ) z
                 WHERE z.inout = 'INSIDE'
                ORDER BY z.ydiff DESC
               ) f
         WHERE ROWNUM < 2;
      ELSIF ( v_method in (10,11,12) ) THEN
        SELECT MDSYS.SDO_GEOMETRY(2001,SELF.geom.sdo_srid,mdsys.sdo_point_type(f.CX,f.CY,NULL),NULL,NULL)
          INTO v_centroid
          FROM (SELECT z.x + ( xdiff / 2 ) as cx,
                       z.y                 as cy
                  FROM (SELECT w.id,
                               w.x,
                               w.y,
                               case when w.xdiff is null then 0 else w.xdiff end as xdiff,
                               case when w.id = 1
                                    then case when w.inout = 1
                                              then 'INSIDE'
                                              else 'OUTSIDE'
                                          end
                                    when w.inout = 99
                                    then 'OUTSIDE'
                                    when MOD(SUM(w.inout) OVER (ORDER BY w.id),2) = 1
                                         /* Need to look at previous result as inside/outside is a binary switch */
                                    then 'INSIDE'
                                    else 'OUTSIDE'
                                end as inout
                          FROM (SELECT rownum as id,
                                       u.x,
                                       u.y,
                                       case when u.touchCross in (-1,0,1) /* Cross */ then 1
                                            when u.touchCross in (-2,2)   /* Touch */ then 0
                                            when u.touchCross >= 99                   then 99
                                            else 0
                                        end as inout,
                                       ABS(LEAD(u.x,1) OVER(ORDER BY u.x) - u.x) As xDiff
                                  FROM (SELECT s.x,
                                               s.y,
                                               /* In cases where polygons have boundaries/holes that touch at a point we need to count them more than once */
                                               case when count(*) > 2 then 1 else sum(s.touchcross) end as touchcross
                                          FROM (SELECT t.element_id,
                                                       t.subelement_id,
                                                       t.x,
                                                       t.y,
                                                       t.touchCross
                                                  FROM (SELECT r.element_id,
                                                               r.subelement_id,
                                                               r.y,
                                                               case when (r.endy = r.starty)
                                                                    then (r.startx + r.endx ) / 2
                                                                    else round(r.startx + ( (r.endx-r.startx)/(r.endy-r.starty) ) * (r.y-r.starty),SELF.dPrecision)
                                                                end as x,
                                                                case when ( r.y = r.starty and r.y = r.endy )
                                                                     then 99 /* Line is Vertical ie two touches */
                                                                     when ( ( r.y = r.starty and r.y > r.endy )
                                                                              or
                                                                            ( r.y = r.endy   and r.y > r.starty )
                                                                          )
                                                                     then -1 /* Left Touch */
                                                                     when ( ( r.y = r.endy   and r.y < r.starty  )
                                                                              or
                                                                            ( r.y = r.starty and r.y < r.endy )
                                                                          )
                                                                      then 1 /* Right Touch */
                                                                      else 0 /* cross */
                                                                  end as TouchCross
                                                            FROM (SELECT seg.element_id    as element_id,
                                                                         seg.subelement_id as subelement_id,
                                                                         v_seed_value      as Y,
                                                                         round(seg.startCoord.x,SELF.dPrecision) as startX,
                                                                         round(seg.startCoord.y,SELF.dPrecision) as startY,
                                                                         round(  seg.endCoord.x,SELF.dPrecision) as endX,
                                                                         round(  seg.endCoord.y,SELF.dPrecision) as endY
                                                                     FROM TABLE(SELF.ST_Segmentize(p_filter      =>'Y',
                                                                                                   p_filter_value=>v_Seed_Value)) seg
                                                                 ) r
                                                        ) t
                                                  ORDER BY t.x
                                               ) s
                                        /*WHERE s.touchCross <> 99*/
                                        GROUP BY s.element_id, s.subelement_id, s.x, s.y
                                        ORDER BY s.x
                                       ) u
                               ) w
                       ) z
                 WHERE z.inout = 'INSIDE'
                ORDER BY z.xdiff DESC
               ) f
         WHERE ROWNUM < 2;
      End If;
      EXCEPTION
        WHEN NO_DATA_FOUND Then
          -- No Data Found means v_centroid will be null so try again
          v_centroid := NULL;
      END;
      IF ( v_centroid is null
           OR
           sdo_geom.relate(v_centroid,'INSIDE',SELF.geom,0.005)='FALSE' ) Then
          if ( v_mbr is null ) Then
             v_mbr := SELF.ST_MBR().geom;
          End If;
          -- Modify to get a new v_seed_value

          v_seed_value:= case when v_method < 10
                              then sys.dbms_random.value(v_mbr.sdo_ordinates(1),v_mbr.sdo_ordinates(1+SELF.ST_Dims()))
                              else sys.dbms_random.value(v_mbr.sdo_ordinates(2),v_mbr.sdo_ordinates(2+SELF.ST_Dims()))
                          end;
          v_loop := v_loop - 1;
       else
          v_not_inside := false;
       End If;
    END LOOP;
    IF ( v_centroid is null ) Then
      raise_application_error(c_i_fail, c_s_fail,TRUE);
    End If;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(v_centroid,
                           SELF.tolerance,
                           SELF.dPrecision,
                           SELF.projected);
  End ST_Centroid_A;

  Member Function ST_Multi_Centroid(
                    p_method IN integer  := 1,
                    p_unit   IN varchar2 := NULL
                  )
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    c_i_method     Constant Integer       := -20001;
    c_s_method     Constant VarChar2(100) := 'Method parameter must be one of (0, 1, 3, 4, 10, 11).';
    c_i_multi      Constant Integer       := -20002;
    c_s_multi      Constant VarChar2(250) := 'ST_Multi_Centroid only supports Multi-LineString and multi-Polygon geometries.';
    v_method       pls_integer := NVL(p_method,1);
    v_dims         pls_integer;
    v_extract_geom &&INSTALL_SCHEMA..T_GEOMETRY;
    v_centroid     mdsys.sdo_geometry;
    v_ordinates    MDSYS.SDO_Ordinate_Array;
  Begin
    IF ( SELF.ST_GType() NOT IN (6,7) ) Then
      raise_application_error(c_i_multi,c_s_multi,TRUE);
    END IF;

    IF ( SELF.ST_GType() = 6 ) THEN
      Return SELF.ST_Centroid_L(p_option => 'MULTI',
                                p_unit   => p_unit);
    END IF;

    /*    v_method     (integer) --  0 = Use average of all Area's X Ordinates for starting centroid Calculation
     *                              10 = Use average of all Area's Y Ordinates for starting centroid Calculation
     *                               1 = Use centre X Ordinate of geometry MBR
     *                              11 = Use centre Y Ordinate of geometry MBR
     * NOT SUPPORTED ->              2 = User supplied starting seed X ordinate value
     * NOT SUPPORTED ->             12 = User supplied starting seed Y ordinate value
     *                               3 = Use MDSYS.SDO_GEOM.SDO_CENTROID function
     *                               4 = Use Oracle implementation of PointOnSurface
    */
    IF ( v_method NOT IN (0, 1, 3, 4, 10, 11) ) THEN
      raise_application_error(c_i_method,c_s_method,TRUE);
    END IF;

    v_ordinates := mdsys.sdo_ordinate_array();
    v_dims      := SELF.ST_Dims();
    <<for_all_parts_in_multipolygon>>
    FOR v_elem_no IN 1..SELF.ST_NumElements() LOOP
      v_extract_geom := &&INSTALL_SCHEMA..T_GEOMETRY (
                          mdsys.sdo_util.Extract(SELF.geom,v_elem_no),
                          SELF.tolerance,
                          SELF.dPrecision,
                          SELF.projected
                        );
      v_centroid := v_extract_Geom.ST_Centroid_A(p_method => v_method).geom;
      v_ordinates.EXTEND(v_dims);
      v_ordinates(v_ordinates.LAST-(v_dims-1)) := v_centroid.sdo_point.x;
      v_ordinates(v_ordinates.LAST-(v_dims-2)) := v_centroid.sdo_point.y;
      IF v_centroid.sdo_point.z IS NOT NULL THEN
        v_ordinates(v_ordinates.LAST) := v_centroid.sdo_point.z;
      END IF;
    END LOOP;
    RETURN &&INSTALL_SCHEMA..T_Geometry(
                mdsys.sdo_geometry((SELF.ST_Dims() * 1000) + 5,
                                   SELF.ST_Srid(),
                                   NULL,
                                   MdSys.Sdo_Elem_Info_Array(1,1,v_ordinates.COUNT / v_dims),
                                   v_Ordinates
                                  ),
                    self.tolerance,
                    SELF.dPrecision,
                    self.projected);
  END ST_Multi_Centroid;

  Member Function ST_FixOrdinates   (p_x_formula in varchar2,
                                     p_y_formula in varchar2,
                                     p_z_formula in varchar2 := null,
                                     p_w_formula in varchar2 := null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
     c_i_null_geometry Constant Integer       := -20124;
     c_s_null_geometry Constant VarChar2(100) := 'Geometry must not be null.';
     v_isMeasured  BOOLEAN;
     v_measure_dim PLS_INTEGER; /* Ordinate position of the Measure value in an LRS geometry */
     v_dims        PLS_INTEGER;
     v_gtype       PLS_INTEGER;
     v_sdo_point   mdsys.sdo_point_type;
     v_ordinates   MDSYS.SDO_Ordinate_Array := new MDSYS.SDO_Ordinate_Array();
     v_sql         varchar2(4000);
  Begin
    v_dims  := SELF.ST_Dims();
    v_gtype := SELF.ST_GType;
    -- If mdsys.sdo_geometry is a single point coded in sdo_point, then update it
    v_sdo_point := SELF.geom.sdo_point;
    If ( v_gtype = 1 And SELF.geom.sdo_point is not null ) Then
      v_sql := 'SELECT mdsys.sdo_point_type(' || p_x_formula || ',' ||
                                                 p_y_formula || ',' ||
                                                 case when p_z_formula is null
                                                      then 'NULL'
                                                      else p_z_formula
                                                  end || ')
                FROM (SELECT :X as X,:Y as Y,:Z as Z FROM DUAL )';
       EXECUTE IMMEDIATE v_sql
                    INTO v_sdo_point
                   USING v_sdo_point.x,
                         v_sdo_point.y,
                         v_sdo_point.z;
    End If;
    If ( SELF.geom.sdo_ordinates is not null ) Then
      v_isMeasured  := SELF.ST_LRS_isMeasured() = 1;
      v_measure_dim := SELF.ST_Lrs_Dim();
      /* Need to UNPIVOT x,y,z,w records from ""b"" query into ordinate list to collect into v_ordinates */
      v_sql := '
SELECT CASE A.rin
            WHEN 1 THEN b.x
            WHEN 2 THEN b.y
            WHEN 3 THEN CASE ' || v_measure_dim || ' WHEN 0 THEN b.z WHEN 3 THEN b.w END
            WHEN 4 THEN b.w
        END as ord
  FROM (SELECT LEVEL as rin
          FROM DUAL
        CONNECT BY LEVEL <= ' || v_dims || ') a,
       (SELECT rownum as cin, ' ||
               case when p_x_formula is null then 'x' else p_x_formula end || ' as x,' ||
               case when p_y_formula is null then 'y' else p_y_formula end || ' as y,' ||
               case when p_z_formula is null then 'z' else p_z_formula end || ' as z,' ||
               case when p_w_formula is null then 'w' else p_w_formula end || ' as w
          FROM (SELECT v.x,
                       v.y, ' ||
                       CASE WHEN v_measure_dim <> 3 /* If measured geometry and measure position is not 3 then Z is coded in this position */
                            THEN 'v.z'
                            ELSE 'NULL'
                        END || ' as z, ' ||
                       CASE WHEN v_measure_dim = 3 /* If measured geometry and measure position is 3 then Z has been coded with W so move it */
                            THEN 'v.z'
                            ELSE 'v.w'
                        END || ' as w
                  FROM TABLE(mdsys.sdo_util.GetVertices(:1)) v
               )
        ) b
 ORDER BY B.cin,A.rin';
      EXECUTE IMMEDIATE v_sql
      BULK COLLECT INTO v_ordinates
                  USING SELF.geom;
    End If;
    Return &&INSTALL_SCHEMA..T_GEOMETRY(
             mdsys.sdo_geometry(SELF.geom.sdo_gtype,
                                SELF.geom.sdo_srid,
                                v_sdo_point,
                                SELF.geom.sdo_elem_info,
                                v_ordinates),
             SELF.Tolerance,
             SELF.dPrecision,
             SELF.Projected);
  End ST_FixOrdinates;

  Member Function ST_Densify(p_distance In Number,
                             p_unit     In Varchar2 Default NULL)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    v_dims            pls_integer;
    v_tolerance       number := NVL(SELF.tolerance,0.005);
    v_num_rings       pls_integer;
    v_geometry        MDSYS.SDO_Geometry;
    v_segment         pls_integer;
    v_vertex          pls_integer;
    v_num_geometries  pls_integer;
    v_extract_tgeom   &&INSTALL_SCHEMA..T_Geometry;
    v_densified_tgeom &&INSTALL_SCHEMA..T_Geometry;
    v_return_tgeom    &&INSTALL_SCHEMA..T_Geometry;
    v_partToProcess   boolean;
    v_coordToProcess  boolean;

    -- For Pragma efficiency:
    -- 1.  INPUT: v_extract_tgeom must contain geometry to be densified
    -- 2. OUTPUT: v_densified_tgeom is returned densified geometry.

    --PRAGMA INLINE (Densify_Segment, 'YES');
    Procedure Densify_Segment
    As
      v_ord        pls_integer;
      v_vertices   mdsys.vertex_set_type;
      v_segments   &&INSTALL_SCHEMA..T_Segments;
      v_geometry   mdsys.sdo_geometry;
      v_dense_geom mdsys.sdo_geometry;
    Begin
      -- DEBUG dbms_output.put_line('<Densify_Segment>');
      v_geometry :=  mdsys.sdo_geometry(
                        SELF.ST_Sdo_Gtype(),
                        SELF.ST_Srid(),
                        SELF.GEOM.SDO_POINT,
                        v_extract_tgeom.geom.sdo_elem_info,
                        mdsys.sdo_ordinate_array(0)
                     );
      v_geometry.sdo_ordinates.DELETE;
      v_segments  := v_extract_tgeom.ST_Segmentize(p_filter=>'ALL');
      -- DEBUG dbms_output.put_line('v_segments is ' ||v_segments.COUNT);
      v_ord       := 1;
      FOR i IN 1..v_segments.COUNT LOOP
        -- Densify this segment
        v_dense_geom  := v_segments(i)
                           .ST_Densify(
                               p_distance  => p_distance,
                               p_unit      => p_unit
                            );
        -- DEBUG dbms_output.put_line('v_dense_geom=' || &&INSTALL_SCHEMA..PRINT.sdo_geometry(v_dense_geom,SELF.dPrecision));
        -- Add all vertices in v_dense_geom to sdo_ordinate_array except last
        v_vertices := mdsys.sdo_util.GetVertices(v_dense_geom);  -- TODO: Performance improve by removal
        FOR i IN 1..(v_vertices.COUNT-1) LOOP
          v_geometry.sdo_ordinates.EXTEND(v_dims);
          v_geometry.sdo_ordinates(v_ord  )     := v_vertices(i).X;
          v_geometry.sdo_ordinates(v_ord+1)     := v_vertices(i).Y;
          IF ( v_dims >= 3 ) THEN
            v_geometry.sdo_ordinates(v_ord+2)   := v_vertices(i).Z;
            IF ( v_dims = 4 ) THEN
              v_geometry.sdo_ordinates(v_ord+3) := v_vertices(i).W;
            End If;
          End If;
          v_ord := v_ord + SELF.ST_Dims();
        END LOOP;
      END LOOP;
      -- Add last endCoord to geometry
      v_geometry.sdo_ordinates.EXTEND(v_dims);
      v_geometry.sdo_ordinates(v_ord  )     := v_vertices(v_vertices.COUNT).X;
      v_geometry.sdo_ordinates(v_ord+1)     := v_vertices(v_vertices.COUNT).Y;
      IF ( v_dims >= 3 ) THEN
        v_geometry.sdo_ordinates(v_ord+2)   := v_vertices(v_vertices.COUNT).Z;
        IF ( v_dims = 4 ) THEN
          v_geometry.sdo_ordinates(v_ord+3) := v_vertices(v_vertices.COUNT).w;
        End If;
      End If;
      v_densified_tgeom := &&INSTALL_SCHEMA..T_Geometry(
                             v_geometry,
                             SELF.tolerance, SELF.dPrecision, SELF.projected
                           );
      -- DEBUG dbms_output.put_line('v_processed_tGeom.geom:'||&&INSTALL_SCHEMA..PRINT.sdo_geometry(v_densified_tgeom.geom,SELF.dPrecision)); dbms_output.put_line('</Densify_Segment>');
    End Densify_Segment;

    -- For Pragma efficiency:
    -- 1.  INPUT: v_densified_tgeom must contain geometry to be appended
    -- 2. OUTPUT: v_return_tgeom is current contents of geomtrry to be returned after appending.

    --PRAGMA INLINE (AddToGeometry, 'YES');
    Procedure AddToGeometry
    As
      v_num_elements pls_integer;
      v_offset       pls_integer;
      v_base_index   pls_integer;
    Begin
      -- DEBUG dbms_output.put_line('<AddToGeometry> v_return_tgeom is null ' || case when v_return_tgeom is null then 'YES' else 'NO' end);
      IF  ( v_return_tgeom is null ) THEN
        v_return_tgeom := &&INSTALL_SCHEMA..T_Geometry(
                            v_densified_tgeom.geom,
                            SELF.Tolerance, SELF.dPrecision, SELF.Projected
                          );
      ELSE
        -- DEBUG dbms_output.put_line('Append elem info of ring being processed to result geom..');
        v_num_elements := (v_densified_tgeom.geom.sdo_elem_info.COUNT / 3) - 1;
        v_base_index   := v_return_tgeom.geom.sdo_elem_info.COUNT;
        <<for_all_elements>>
        for v_i IN 0 .. v_num_elements LOOP
          v_offset := ( v_i * 3 ) + 1;
          v_return_tgeom.geom.sdo_elem_info.EXTEND(3);
          v_return_tgeom.geom.sdo_elem_info(v_base_index + v_offset)   := v_return_tgeom.geom.sdo_ordinates.COUNT + v_densified_tgeom.geom.sdo_elem_info(v_offset);
          v_return_tgeom.geom.sdo_elem_info(v_base_index + v_offset+1) := v_densified_tgeom.geom.sdo_elem_info(v_offset+1);
          v_return_tgeom.geom.sdo_elem_info(v_base_index + v_offset+2) := v_densified_tgeom.geom.sdo_elem_info(v_offset+2);
        end loop for_all_elements;
        -- DEBUG dbms_output.put_line('Append sdo_ordinates of ring being processed to result geom.');
        v_base_index := v_return_tgeom.geom.sdo_ordinates.COUNT;
        v_return_tgeom.geom.sdo_ordinates.EXTEND(v_densified_tgeom.geom.sdo_ordinates.COUNT);
        <<for_all_ords>>
        for v_ord IN 1 .. v_densified_tgeom.geom.sdo_ordinates.COUNT LOOP
          v_return_tgeom.geom.sdo_ordinates(v_base_index + v_ord) := v_densified_tgeom.geom.sdo_ordinates(v_ord);
        end loop for_all_ords;
      End If;
      -- DEBUG dbms_output.put_line('</AddToGeometry> v_return_tgeom: '||&&INSTALL_SCHEMA..PRINT.sdo_geometry(v_return_tgeom.geom,v_return_tgeom.dPrecision));
    END AddToGeometry;

  Begin
    -- We do not densify such that we produce an invalid geometry!
    If ( p_distance < v_tolerance ) Then
      Return SELF;
    End If;

    -- We only densify lines, polygons and multi thereof
    --
    If ( SELF.ST_GType() NOT IN (2,6,3,7) ) Then
      Return SELF;
    End If;

    -- We do not densify anything with CircularArcs, Circles, Rectangles
    --
    If ( SELF.ST_hasRectangles()  = 1
      or SELF.ST_hasCircularArcs() = 1) Then
      Return SELF;
    End If;

    v_dims           := SELF.ST_Dims();
    v_num_geometries := SELF.ST_NumGeometries();
    FOR v_GeomN IN 1..v_num_geometries LOOP
      IF ( SELF.ST_GType() IN (2,6) ) THEN
        -- Extract geometry from (multi)LineString
        v_extract_tgeom := &&INSTALL_SCHEMA..T_Geometry(
                             MdSys.Sdo_Util.Extract(SELF.geom,v_GeomN),
                             SELF.tolerance,SELF.dPrecision,SELF.projected);
        -- ***************************
        -- Densify v_extract_tgeom returning v_densified_tgeom
        Densify_Segment();
        -- Adding v_densified_tgeom to v_return_tgeom
        AddToGeometry();
        -- ***************************
     ELSE
        v_num_rings := &&INSTALL_SCHEMA..T_GEOMETRY(MDSYS.SDO_UTIL.EXTRACT(SELF.geom,v_GeomN,0)).ST_NumRings();
        <<process_all_rings>>
        FOR v_ring_no IN 1..v_num_rings LOOP
          v_extract_tgeom := &&INSTALL_SCHEMA..T_Geometry(
                              MDSYS.SDO_UTIL.EXTRACT(SELF.geom,v_GeomN,v_ring_no),
                              SELF.tolerance,SELF.dPrecision,SELF.projected);
          -- ***************************
          -- Densify v_extract_tgeom returning v_densified_tgeom
          Densify_Segment();
          -- Adding v_densified_tgeom to v_return_tgeom
          AddToGeometry();
        END LOOP process_all_rings;
        -- ***************************
      END IF;
    END LOOP;
    Return &&INSTALL_SCHEMA..T_GEOMETRY(
             v_return_tgeom.geom,
             SELF.Tolerance,
             SELF.dPrecision,
             SELF.Projected);

  End ST_Densify;

  Member Function ST_LineShift(p_distance in number )
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  AS
     c_i_notlinestring CONSTANT INTEGER       := -20121;
     c_s_notlinestring CONSTANT VARCHAR2(100) := 'Input geometry is not a linestring';
     v_spt             &&INSTALL_SCHEMA..T_Vertex :=
                       &&INSTALL_SCHEMA..T_Vertex(
                         p_id        => 1,
                         p_sdo_gtype => SELF.ST_sdo_gtype(),
                         p_sdo_srid  => SELF.ST_SRID()
                       );
     v_ept             &&INSTALL_SCHEMA..T_Vertex :=
                       &&INSTALL_SCHEMA..T_Vertex(
                         p_id        => 2,
                         p_sdo_gtype => SELF.ST_sdo_gtype(),
                         p_sdo_srid  => SELF.ST_SRID()
                       );
     v_delx            number;
     v_dely            number;
     v_az              number;
     v_dir             integer;
   Begin
      If ( SELF.ST_Dimension() <> 1 ) Then
         raise_application_error(c_i_notlinestring,c_s_notlinestring,true);
     End If;
     v_spt  := SELF.ST_StartVertex();
     v_ept  := SELF.ST_EndVertex();
     v_az   := v_spt.ST_Bearing(v_ept,SELF.projected);
     v_dir  := CASE WHEN v_az < &&INSTALL_SCHEMA..COGO.PI() THEN -1 ELSE 1 END;
     v_delx := ABS(COS(v_az)) * p_distance * v_dir;
     v_dely := ABS(SIN(v_az)) * p_distance * v_dir;
     IF ( v_az > &&INSTALL_SCHEMA..COGO.PI()/2 AND v_az < &&INSTALL_SCHEMA..COGO.PI() OR v_az > 3 * &&INSTALL_SCHEMA..COGO.PI()/2 ) THEN
       RETURN SELF.ST_Translate(v_delx, v_dely);
     ELSE
       RETURN SELF.ST_Translate(-v_delx, v_dely);
     END IF;
  END ST_LineShift;

  Member Function ST_Parallel(p_offset in number,
                              p_curved in number   default 0,
                              p_unit   in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  AS
    c_i_notlinestring CONSTANT INTEGER       := -20121;
    c_s_notlinestring CONSTANT VARCHAR2(100) := 'Input geometry is not a linestring';
    c_i_tolerance     CONSTANT INTEGER       := -20122;
    c_s_tolerance     CONSTANT VARCHAR2(100) := 'tolerance may not be null';
    v_part            mdsys.sdo_geometry;
    v_return_geom     mdsys.sdo_geometry;
    v_elem_count      number;
    v_element         number;

    Function Process_LineString(p_linestring in &&INSTALL_SCHEMA..T_geometry )
      Return mdsys.sdo_geometry
    Is
      bAcute           Boolean := False;
      bDeformed        Boolean := False;
      bCurved          Boolean := ( 1 = p_curved );
      v_delta          &&INSTALL_SCHEMA..T_vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
      v_prev_delta     &&INSTALL_SCHEMA..T_vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
      v_adjusted_coord &&INSTALL_SCHEMA..T_vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
      v_int_1          &&INSTALL_SCHEMA..T_vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
      v_int_coord      &&INSTALL_SCHEMA..T_vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
      v_int_2          &&INSTALL_SCHEMA..T_vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
      v_prev_start     &&INSTALL_SCHEMA..T_vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
      v_last_vertex    &&INSTALL_SCHEMA..T_vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
      v_segment        &&INSTALL_SCHEMA..T_Segment;
      v_intersection   &&INSTALL_SCHEMA..T_Segment;
      v_distance       number;
      v_angle          number;
      v_ratio          number;
      v_az             number;
      v_dir            pls_integer;
      v_return_geom    mdsys.sdo_geometry;
      v_elem_info      mdsys.sdo_elem_info_array;
      v_ordinates      mdsys.sdo_ordinate_array;

      --PRAGMA INLINE (appendElement, 'YES');
      Procedure appendElement(p_SDO_Elem_Info  in out nocopy mdsys.sdo_elem_info_array,
                              p_Offset         in number,
                              p_Etype          in number,
                              p_Interpretation in number )
        IS
      Begin
        p_SDO_Elem_Info.extend(3);
        p_SDO_Elem_Info(p_SDO_Elem_Info.count-2) := p_Offset;
        p_SDO_Elem_Info(p_SDO_Elem_Info.count-1) := p_Etype;
        p_SDO_Elem_Info(p_SDO_Elem_Info.count  ) := p_Interpretation;
      END appendElement;

      --PRAGMA INLINE (appendVertex, 'YES');
      Procedure appendVertex(p_ordinates in out nocopy mdsys.sdo_ordinate_array,
                             p_vertex    in &&INSTALL_SCHEMA..T_Vertex)
      Is
        v_ord pls_integer;
      Begin
        -- DEBUG dbms_output.put_line('appendVertex: ' ||p_vertex.ST_AsText(3));
        v_ord := p_ordinates.COUNT + 1;
        p_ordinates.EXTEND(SELF.ST_Dims());
        -- Insert first vertex
        p_ordinates(v_ord)   := p_vertex.X;
        p_ordinates(v_ord+1) := p_vertex.Y;
        If (SELF.ST_Dims()>=3) Then
           p_ordinates(v_ord+2) := p_vertex.z;
           if ( SELF.ST_Dims() > 3 ) Then
               p_ordinates(v_ord+3) := p_vertex.w;
           End If;
        End If;
      End appendVertex;

    Begin
      If ( v_elem_info is null ) Then
        v_elem_info := new sdo_elem_info_array(0);
        v_elem_info.DELETE;
      End If;
      If ( v_ordinates is null ) Then
        v_ordinates := new sdo_ordinate_array(0);
        v_ordinates.DELETE;
      End If;

      -- DEBUG dbms_output.put_line('Process_LineString p_linestring = ' || p_linestring.ST_AsText(3));
      <<process_each_Segment>>
      FOR rec IN (SELECT f.segment_id,
                         f.number_of_Segments,
                         f.original_Segment,
                         f.parallel_Segment
                    FROM (SELECT o.segment_id                as segment_id,
                                 count(*) over (order by 1)  as number_of_Segments,
                                 o.ST_Self()                 as original_Segment,
                                 o.ST_Parallel(p_offset => p_offset) as parallel_Segment
                            FROM TABLE(p_linestring.ST_Segmentize(p_filter=>'ALL')) o
                         ) f
                  ORDER BY f.segment_id
                 )
      LOOP
        -- DEBUG dbms_output.put_line('LOOP START rec.segment=' || rec.original_Segment.ST_AsText(3));
        bDeformed := false;

        -- Compute base offset
        v_az      := rec.original_Segment.ST_Bearing();
        v_dir  := CASE WHEN v_az < &&INSTALL_SCHEMA..COGO.PI() THEN -1 ELSE 1 END;
        v_delta.x := ABS(COS(v_az)) * p_offset * v_dir;
        v_delta.y := ABS(SIN(v_az)) * p_offset * v_dir;
        IF  Not ( v_az > &&INSTALL_SCHEMA..COGO.PI()/2 AND
                  v_az < &&INSTALL_SCHEMA..COGO.PI() OR
                  v_az > 3 * &&INSTALL_SCHEMA..COGO.PI()/2 ) THEN
          v_delta.x := -1 * v_delta.x;
        END IF;

        -- DEBUG dbms_output.put_line('Segment_id('||rec.segment_id||') v_delta = ' || v_delta.ST_AsText(3)||' rec.line.ST_Bearing('||ROUND(rec.original_Segment.ST_Bearing(),10)||')');

        -- Check if only one segment in element
        IF (rec.segment_id = 1 AND rec.number_of_Segments = 1) Then
          -- Copy original sdo_elem_info_array through to new geometry as will not change
          v_elem_info := p_linestring.geom.sdo_elem_info;
          -- Add parallel segment to geometry
          appendVertex(v_ordinates,rec.parallel_Segment.startCoord);
          -- DEBUG dbms_output.put_line('.. does it have a midCoord?');
          if ( rec.parallel_Segment.midCoord is not null and
            rec.parallel_Segment.midCoord.x is not null ) Then
            -- DEBUG dbms_output.put_line('.... YES');
            appendVertex(v_ordinates,rec.parallel_Segment.midCoord);
          End If;
          appendVertex(v_ordinates,rec.parallel_Segment.endCoord);
          v_return_geom := mdsys.sdo_geometry(p_linestring.geom.sdo_gtype,
                                         p_linestring.geom.sdo_srid,
                                         p_linestring.geom.sdo_point,
                                         v_elem_info,
                                         v_ordinates);
          Return v_return_geom;
        End If;

        -- merge segments at this point?
        IF (rec.segment_id > 1) THEN
           v_int_coord := rec.original_Segment.startCoord;
           -- DEBUG dbms_output.put_line('Segment_id>1: v_int_coord= ' || v_int_coord.ST_AsText(3));
           -- Get intersection of two lines parallel at distance p_offset from current ones
           v_segment := &&INSTALL_SCHEMA..T_Segment(
                           p_segment_id => 1,
                           p_startCoord => &&INSTALL_SCHEMA..T_Vertex(
                             p_x         => round(v_adjusted_coord.x,SELF.dPrecision),
                             p_y         => round(v_adjusted_coord.y,SELF.dPrecision),
                             p_id        => 1,
                             p_sdo_gtype => SELF.ST_Sdo_GType(),
                             p_sdo_srid  => SELF.ST_SRID()
                           ),
                           p_endCoord => &&INSTALL_SCHEMA..T_Vertex(
                             p_x         => round(rec.original_Segment.startCoord.x + v_prev_delta.x,SELF.dPrecision),
                             p_y         => round(rec.original_Segment.startCoord.y + v_prev_delta.y,SELF.dPrecision),
                             p_id        => 2,
                             p_sdo_gtype => SELF.ST_Sdo_GType(),
                             p_sdo_srid  => SELF.ST_SRID()
                           ),
                           p_sdo_gtype   => rec.original_Segment.sdo_gtype,
                           p_sdo_srid    => rec.original_Segment.sdo_srid,
                           p_projected   => SELF.projected,
                           p_precision   => SELF.dPrecision,
                           p_tolerance   => SELF.tolerance
                          );
           v_segment.PrecisionModel := rec.original_Segment.PrecisionModel;
           v_intersection := v_segment.ST_IntersectDetail(
                               p_segment =>
                                 &&INSTALL_SCHEMA..T_Segment(
                                   p_segment_id => 1,
                                   p_startCoord => &&INSTALL_SCHEMA..T_Vertex(
                                     p_x         => round(rec.original_Segment.endCoord.x   + v_delta.x,SELF.dPrecision),
                                     p_y         => round(rec.original_Segment.endCoord.y   + v_delta.y,SELF.dPrecision),
                                     p_id        => 1,
                                     p_sdo_gtype => SELF.ST_Sdo_GType(), /* sdo_gtype created by constructor from segment gtype */
                                     p_sdo_srid  => SELF.ST_SRID()),
                                   p_endCoord => &&INSTALL_SCHEMA..T_Vertex(
                                     p_x         => Round(rec.original_Segment.startCoord.x + v_delta.x,SELF.dPrecision),
                                     p_y         => Round(rec.original_Segment.startCoord.y + v_delta.y,SELF.dPrecision),
                                     p_id        => 2,
                                     p_sdo_gtype => SELF.ST_Sdo_GType(),
                                     p_sdo_srid  => SELF.ST_SRID()
                                   ),
                                   p_sdo_gtype   => rec.original_Segment.sdo_gtype,
                                   p_sdo_srid    => rec.original_Segment.sdo_srid,
                                   p_projected   => SELF.projected,
                                   p_precision   => SELF.dPrecision,
                                   p_tolerance   => SELF.tolerance
                               )
                               /* SGG p_tolerance=> SELF.tolerance,
                               p_unit     => p_unit */
                             );
           v_int_coord := v_intersection.startCoord;
           v_int_1     := v_intersection.midCoord;
           v_int_2     := v_intersection.endCoord;
           /* DEBUG
           dbms_output.put_line('p_offset= '      || p_offset               || CHR(13) ||
                                ' v_delta= '        || v_delta.ST_AsText(3)     || CHR(13) ||
                                ' rec.line.vid= ' || rec.original_Segment.segment_Id     || CHR(13) ||
                                ' v_int_coord= '    || v_int_coord.ST_AsText(3) || CHR(13) ||
                                ' v_int_1= '        || v_int_1.ST_AsText(3)     || CHR(13) ||
                                ' v_int_2= '        || v_int_2.ST_AsText(3));
           dbms_output.put_line('v_int_coord.id= ' || v_int_coord.id || CHR(13) ||
                     ' v_int_coord.x= ' || v_int_coord.x  || CHR(13) ||
                     ' v_int_coord.ST_Equals(v_int_1,SELF.dPrecision)=' || v_int_coord.ST_Equals(v_int_1,SELF.dPrecision) ||  CHR(13) ||
                     ' v_int_coord.ST_Equals(v_int_2,SELF.dPrecision)=' || v_int_coord.ST_Equals(v_int_2,SELF.dPrecision));
           */
           If ( v_int_coord.id = -9 ) Then
             -- No intersection point as lines are parallel
             bAcute := True;
             -- int coord could be computed from start or end, doesn't matter.
             v_int_coord := &&INSTALL_SCHEMA..T_Vertex(
                              p_x         => Round(rec.original_Segment.startCoord.x + v_prev_delta.x,SELF.dPrecision),
                              p_y         => Round(rec.original_Segment.startCoord.y + v_prev_delta.y,SELF.dPrecision),
                              p_z         => rec.original_Segment.startCoord.z,
                              p_w         => rec.original_Segment.startCoord.w,
                              p_id        => 1,
                              p_sdo_gtype => SELF.ST_Sdo_GType(),
                              p_sdo_srid  => SELF.ST_SRID());
           ElsIf (v_int_coord.id < 0) Then
              -- DEBUG dbms_output.put_line('Bend has degraded to a single to point only: int_coord=' ||  v_int_coord.ST_AsText(3) || ' int_1=' || v_int_1.ST_AsText(3) || ' int_2=' || v_int_2.ST_AsText(3) );
              v_angle := 0;
              bAcute  := True; -- Skip next section
              v_int_1 := v_int_coord;
              v_int_2 := v_int_coord;
              v_delta.x := 0;
              v_delta.y := 0;
              v_delta.z := 0;
              v_delta.w := 0;
           Else
             v_angle := rec.original_Segment.startCoord.ST_SubtendedAngle(v_prev_start,rec.original_Segment.endCoord);
             bAcute := case when p_offset < 0 and v_angle < 0
                            then /* left */ True
                            when p_offset < 0 and v_angle > 0
                            then /* left */ False
                            when p_offset > 0 and v_angle < 0
                            then /* right */ False
                            when p_offset > 0 and v_angle > 0
                            then /* right */ True
                            else True
                        end;
           End If;
           -- DEBUG dbms_output.put_line('bCurved='||case when bCurved then 'TRUE' else 'FALSE' end || ' bAcute='||case when bAcute  then 'TRUE' else 'FALSE' end);
           If ( bCurved and Not bAcute) Then
             -- 1. First point in intersection circular arc
             v_int_1 := &&INSTALL_SCHEMA..T_Vertex(
                                 p_x         => Round(rec.original_Segment.startCoord.x + v_prev_delta.x,SELF.dPrecision),
                                 p_y         => Round(rec.original_Segment.startCoord.y + v_prev_delta.y,SELF.dPrecision),
                                 p_z         => rec.original_Segment.startCoord.z, /* Keep all three points at same z */
                                 p_w         => rec.original_Segment.startCoord.w, /* Measure may actually change.. */
                                 p_id        => 1,
                                 p_sdo_gtype => SELF.ST_Sdo_GType(),
                                 p_sdo_srid  => SELF.ST_SRID());
             -- Need to compute coordinate at mid-angle of the circular arc formed by last and current segment
             v_distance := &&INSTALL_SCHEMA..t_Segment(
                                    p_Segment_id => 0,
                                    p_startCoord => v_int_coord,
                                    p_endCoord   => rec.original_Segment.startCoord,
                                    p_sdo_gtype  => p_linestring.ST_Sdo_gtype(),
                                    p_sdo_srid   => p_linestring.ST_Srid(),
                                    p_projected  => SELF.projected,
                                    p_precision  => SELF.dPrecision,
                                    p_tolerance  => SELF.tolerance
                           ).ST_Length(p_unit); /* SGG */
             v_ratio := ( p_offset / v_distance ) * SIGN(p_offset);
             -- 2. Top point of intersection circular arc
             v_adjusted_coord.x := Round(rec.original_Segment.startCoord.x + (( v_int_coord.x - rec.original_Segment.startCoord.x ) * v_ratio ),SELF.dPrecision);
             v_adjusted_coord.y := Round(rec.original_Segment.startCoord.y + (( v_int_coord.y - rec.original_Segment.startCoord.y ) * v_ratio ),SELF.dPrecision);
             v_adjusted_coord.z := rec.original_Segment.startCoord.z;
             v_adjusted_coord.w := rec.original_Segment.startCoord.w;
             -- 3. Last point in intersection circular arc
             v_int_2 := &&INSTALL_SCHEMA..T_Vertex(
                                 p_x         => Round(rec.original_Segment.startCoord.x + v_delta.x,SELF.dPrecision),
                                 p_y         => Round(rec.original_Segment.startCoord.y + v_delta.y,SELF.dPrecision),
                                 p_z         => rec.original_Segment.startCoord.z, /* Keep all three points at same z */
                                 p_w         => rec.original_Segment.startCoord.w, /* Measure may actually change.. */
                                 p_id        => 1,
                                 p_sdo_gtype => SELF.ST_Sdo_GType(),
                                 p_sdo_srid  => SELF.ST_SRID());
           Else
             -- DEBUG dbms_output.put_line('Assign Intersection coord to adjusted coord');
             v_adjusted_coord   := v_int_coord;
             -- DEBUG dbms_output.put_line('Adjusted coord assigned intersection coord: ' || v_adjusted_coord.ST_AsText(3));
           End If;
        ELSE  -- rec.segment_id = 1
          If (bCurved) Then
            appendElement(v_elem_info,1,2,1);
          Else
            -- Copy original through to new geometry as will not change
            v_elem_info := p_linestring.geom.sdo_elem_info;
          End If;
          -- Translate start point with current segment
          v_adjusted_coord := &&INSTALL_SCHEMA..T_Vertex(
                                    p_x         => Round(rec.original_Segment.startCoord.x + v_delta.x,SELF.dPrecision),
                                    p_y         => Round(rec.original_Segment.startCoord.y + v_delta.y,SELF.dPrecision),
                                    p_z         => rec.original_Segment.startCoord.z,
                                    p_w         => rec.original_Segment.startCoord.w,
                                    p_id        => 1,
                                    p_sdo_gtype => SELF.ST_Sdo_GType(),
                                    p_sdo_srid  => SELF.ST_SRID());
        END IF;

        -- Now add computed coordinates to output ordinate_array
        If (Not bCurved) or bAcute or (rec.segment_id=1) Then
          appendVertex(v_ordinates,v_adjusted_coord);
        ElsIf (bCurved) Then
          -- With any generated circular curves we need to add the appropriate elem_info
          appendElement(v_elem_info,v_ordinates.COUNT+1,2,2);
          appendVertex(v_ordinates,v_int_1);
          appendVertex(v_ordinates,v_adjusted_coord);
          appendElement(v_elem_info,v_ordinates.COUNT+1,2,1);
          appendVertex(v_ordinates,v_int_2);
        End If;
        v_prev_start := rec.original_Segment.startCoord;
        v_prev_delta := v_delta;
        v_last_vertex:= &&INSTALL_SCHEMA..T_Vertex(
                              p_x         => Round(rec.original_Segment.endCoord.x,SELF.dPrecision),
                              p_y         => Round(rec.original_Segment.endCoord.y,SELF.dPrecision),
                              p_z         => rec.original_Segment.endCoord.z,
                              p_w         => rec.original_Segment.endCoord.w,
                              p_id        => 1,
                              p_sdo_gtype => SELF.ST_Sdo_GType(),
                              p_sdo_srid  => SELF.ST_SRID());
      END LOOP process_each_Segment;

      if (v_adjusted_coord.id >= 0) Then
        appendVertex(v_ordinates,
                     &&INSTALL_SCHEMA..T_Vertex(
                          p_x         => Round(v_last_vertex.x + v_delta.x,SELF.dPrecision),
                          p_y         => Round(v_last_vertex.y + v_delta.y,SELF.dPrecision),
                          p_z         => v_last_vertex.z,
                          p_w         => v_last_vertex.w,
                          p_id        => 1,
                          p_sdo_gtype => SELF.ST_Sdo_GType(),
                          p_sdo_srid  => SELF.ST_SRID()));
      End If;
      v_return_geom := mdsys.sdo_geometry(p_linestring.geom.sdo_gtype,
                                     p_linestring.geom.sdo_srid,
                                     p_linestring.geom.sdo_point,
                                     v_elem_info,
                                     v_ordinates);

      If ( &&INSTALL_SCHEMA..T_GEOMETRY(v_return_geom).ST_hasCircularArcs() > 0 ) Then
        -- And compound header to top of element_info (1,4,n_elements)
        Begin
          v_return_geom.sdo_elem_info.EXTEND(3);
          v_element    := v_return_geom.sdo_elem_info.COUNT;
          v_elem_count := v_return_geom.sdo_elem_info.COUNT / 3;
          -- Shuffle
          while ( v_element > 3 ) loop
            v_return_geom.sdo_elem_info(v_element) := v_return_geom.sdo_elem_info(v_element-3);
            v_element := v_element - 1;
          end loop;
          v_return_geom.sdo_elem_info(1) := 1;
          v_return_geom.sdo_elem_info(2) := 4;
          v_return_geom.sdo_elem_info(3) := v_elem_count;
        End;
      End If;
      RETURN v_return_geom;
    End Process_LineString;

  BEGIN
     If ( SELF.ST_Dimension() <> 1 ) Then
         raise_application_error(c_i_notlinestring,c_s_notlinestring,true);
     End If;
     If ( SELF.tolerance is null ) Then
        raise_application_error(c_i_tolerance,c_s_tolerance,true);
     End If;

     -- Problem with this algorithm is that any existing circular curved elements will not be honoured unless bCurved is 0
     If SELF.ST_hasCircularArcs() > 0 Then
        return SELF.ST_LRS_Locate_Measures(null,null,p_offset,null);
      -- raise_application_error(c_i_compound,c_s_compound,true);
     End If;

     -- DEBUG dbms_output.put_line('ST_Parallel processing geom = ' || SELF.ST_AsEWKT());

     -- Process all parts of a, potentially, multi-part linestring geometry
     FOR elem IN 1..SELF.ST_NumElements() loop
       v_part := mdsys.sdo_util.Extract(SELF.geom,elem,0);
       If ( elem = 1 ) Then
         -- DEBUG dbms_output.put_line('.... ProcessLineString(1) = ' || T_GEOMETRY(v_part,SELF.tolerance,SELF.dPrecision,SELF.projected).ST_AsText(3));
         v_return_geom := Process_LineString(&&INSTALL_SCHEMA..T_GEOMETRY(v_part,SELF.tolerance,SELF.dPrecision,SELF.projected));
       Else
         -- DEBUG dbms_output.put_line('.... ProcessLineString(' || elem || ') = ' || T_GEOMETRY(v_part,SELF.tolerance,SELF.dPrecision,SELF.projected).ST_AsText(3));
         /* CONCAT_LINES destroys compound element descriptions, so use APPEND */
         v_return_geom :=  MDSYS.SDO_UTIL.APPEND(v_return_geom,
                                            Process_LineString(&&INSTALL_SCHEMA..T_GEOMETRY(v_part,SELF.tolerance,SELF.dPrecision,SELF.projected)));
       End If;
       -- DEBUG dbms_output.put_line('.... result(' || elem || ')  = ' || T_GEOMETRY(v_return_geom,SELF.tolerance,SELF.dPrecision,SELF.projected).ST_AsText(3));
     End Loop;
     Return &&INSTALL_SCHEMA..T_GEOMETRY(v_return_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected).ST_Round(p_dec_places_x=>SELF.dPrecision);
  END ST_Parallel;

  Member Function ST_Rectangle(p_length in number,
                               p_width  in number)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  AS
    v_rgeom        mdsys.sdo_geometry;
    v_tgeom        mdsys.sdo_geometry;
    v_vertex       mdsys.vertex_type;
    v_vertices     mdsys.vertex_set_type;
  Begin
    -- DEBUG dbms_output.put_line('<ST_Rectangle>: ' || sdo_geom.validate_geometry(SELF.geom,self.tolerance));
    IF ( NVL(NVL(p_length,p_width),0.0) <= 0.0 ) Then
       return SELF;
    End If;
    If ( SELF.ST_Gtype() NOT IN (1,5) ) Then
       return SELF;
    End If;
    v_vertices := mdsys.sdo_util.getVertices(SELF.geom);
    if ( v_vertices is null or v_vertices.COUNT = 0 ) Then
      return SELF;
    End If;
    v_rgeom := null;
    FOR v IN 1..v_vertices.COUNT LOOP
      v_tgeom := mdsys.sdo_geometry(
                            (SELF.ST_Dims()*1000) + (SELF.ST_Gtype()+2),
                             SELF.ST_SRID(),
                             mdsys.sdo_point_type(v_vertices(v).x,
                                                  v_vertices(v).y,
                                                  v_vertices(v).z),
                             mdsys.sdo_elem_info_array(1,1003,3),
                             case SELF.ST_Dims()
                                  WHEN 3
                                  THEN mdsys.sdo_ordinate_array(v_vertices(v).x - (p_width/2.0),
                                                                v_vertices(v).y - (p_length/2.0),
                                                                v_vertices(v).z,
                                                                v_vertices(v).x + (p_width/2.0),
                                                                v_vertices(v).y + (p_length/2.0),
                                                                v_vertices(v).z)
                                  WHEN 4
                                  THEN mdsys.sdo_ordinate_array(v_vertices(v).x - (p_width/2.0),
                                                                v_vertices(v).y - (p_length/2.0),
                                                                v_vertices(v).z,v_vertices(v).w,
                                                                v_vertices(v).x + (p_width/2.0),
                                                                v_vertices(v).y + (p_length/2.0),
                                                                v_vertices(v).z,v_vertices(v).w)
                                  ELSE mdsys.sdo_ordinate_array(v_vertices(v).x - (p_width/2.0),
                                                                v_vertices(v).y - (p_length/2.0),
                                                                v_vertices(v).x + (p_width/2.0),
                                                                v_vertices(v).y + (p_length/2.0))
                            end);
      If ( SELF.ST_GType() = 1 OR v_rGeom is null) Then
         v_rgeom := v_tgeom;
      Else
         v_rgeom := mdsys.sdo_util.APPEND(v_rgeom, v_tgeom);
      End If;
    END LOOP;
    Return &&INSTALL_SCHEMA..T_GEOMETRY(v_rgeom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_Rectangle;

  /** ST_Tile
   ** Funtion that returns tile polygons covering the geometry
   ** p_Tile_X    : number   : Tile size in X dimension
   ** p_Tile_Y    : number   : Tile size in Y dimension
   ** p_grid_type : varchar2 : Returned geometry is either 'TILE','POINT' or 'BOTH'
   ** @param p_option : varchar2 : MBR       -- Tiles for all geometry's MBR
   **                              TOUCH     -- Only tiles that touch geometry
   **                              CLIP      -- Return tiles for geometry only but clip using geometry boundary
   **                              HALFCLIP  -- Return clipped tiles that touch boundary where area is > 1/2 tile
   **                              HALFTOUCH -- Return tiles that touch boundary where area is > 1/2 tile
   ** Exceptions :
   ** -20120 'Geometry must not be null or empty (*ERR*)'
   ** -20121 'Unsupported geometry type (*GTYPE*)'
   ** -20122 'p_grid_type parameter value (*VALUE*) must be TILE, POINT or BOTH'
   ** -20123 'p_option value (*VALUE*) must be MBR, TOUCH, CLIP, HALFCLIP or HALFTOUCH.'
   ** Returns set of T_Grid records.
  ***/
  Member Function ST_Tile(p_Tile_X    In number,
                          p_Tile_Y    In Number,
                          p_grid_type in varchar2 Default 'TILE',
                          p_option    in varchar2 default 'TOUCH',
                          p_unit      in varchar2 default null)
          Return &&INSTALL_SCHEMA..T_Grids Pipelined
  Is
    c_i_unsupported  Constant Integer       := -20121;
    c_s_unsupported  Constant VarChar2(100) := 'Unsupported geometry type (*GTYPE*)';
    c_i_point_value  Constant pls_integer   := -20122;
    C_S_POINT_VALUE  CONSTANT VARCHAR2(100) := 'p_grid_type parameter value (*VALUE*) must be TILE, POINT or BOTH';
    C_I_OPTION_VALUE CONSTANT PLS_INTEGER   := -20123;
    c_s_option_value Constant VarChar2(100) := 'p_option value (*VALUE*) must be MBR, TOUCH, CLIP, HALFCLIP or HALFTOUCH.';
    v_grid_type      varchar2(10) := SUBSTR(UPPER(NVL(p_grid_type,'TILE')),1,10);
    v_option_value   varchar2(10) := SUBSTR(UPPER(NVL(p_option,'TOUCH')),1,10);
    v_half_x         number := p_Tile_x / 2.0;
    v_half_y         number := p_Tile_y / 2.0;
    v_loCol          PLS_Integer;
    v_hiCol          PLS_Integer;
    v_loRow          PLS_Integer;
    v_hiRow          PLS_Integer;
    v_vertices       mdsys.vertex_set_type;
    v_mbr            mdsys.sdo_geometry;
    v_geometry       mdsys.sdo_geometry;
    v_clip_tgeom     &&INSTALL_SCHEMA..T_GEOMETRY;
   Begin
    If ( SELF.ST_GType() NOT IN (1,2,3,5,6,7) ) THEN
       raise_application_error(c_i_unsupported,
                               REPLACE(c_s_unsupported,
                                       'GTYPE',SELF.ST_GType()),true);
    END IF;
    IF ( NOT v_option_value IN ('MBR','TOUCH','CLIP','HALFCLIP','HALFTOUCH') ) Then
      raise_application_error(c_i_option_value,
                              REPLACE(c_s_option_value,'*VALUE*',v_option_value),true);
    END IF;
    IF ( NOT v_grid_type IN ('TILE','POINT','BOTH') ) Then
      raise_application_error(c_i_point_value,
                      REPLACE(c_s_point_value,'*VALUE*',v_grid_type),true);
    END IF;
    If (SELF.ST_GType() IN (1,5) ) Then
       v_vertices := mdsys.sdo_util.getVertices(SELF.geom);
       FOR i IN 1..v_vertices.COUNT LOOP
          v_loCol := TRUNC(v_vertices(i).x / p_Tile_X );
          v_loRow := TRUNC(v_vertices(i).y / p_Tile_Y );
          PIPE ROW (
               &&INSTALL_SCHEMA..T_GRID(v_loCol,
                      v_loRow,
                      MDSYS.SDO_Geometry(case when v_grid_type IN ('POINT') then 2001 Else 2003 end,
                                         SELF.ST_Srid(),
                                         case when v_grid_type IN ('POINT','BOTH')
                                              then MDSYS.SDO_Point_Type((v_loCol * p_Tile_X) + v_half_x,
                                                                        (v_loRow * p_Tile_Y) + V_Half_Y,
                                                                        NULL)
                                              else NULL
                                          end,
                                         case when v_grid_type IN ('TILE','BOTH')
                                              then MDSYS.SDO_Elem_Info_Array(1,1003,3)
                                              else NULL
                                          end,
                                         case when v_grid_type IN ('TILE','BOTH')
                                              then MDSYS.SDO_Ordinate_Array(v_loCol * p_Tile_X,
                                                                            v_loRow * p_Tile_Y,
                                                                           (v_loCol * p_Tile_X) + p_Tile_X,
                                                                           (v_loRow * p_Tile_Y) + p_Tile_Y)
                                              else null
                                         end )));
       END LOOP;
       RETURN;
    End If;
    v_mbr := SELF.ST_MBR().geom;
    -- Check for horizontal/vertical
    if (v_mbr.sdo_ordinates(1+SELF.ST_Dims()) - v_mbr.sdo_ordinates(1) < p_Tile_X ) Then
        v_mbr.sdo_ordinates(1)                := v_mbr.sdo_ordinates(1) - v_half_x;
        v_mbr.sdo_ordinates(1+SELF.ST_Dims()) := v_mbr.sdo_ordinates(1+SELF.ST_Dims()) + v_half_x;
    End If;
    if (v_mbr.sdo_ordinates(2+SELF.ST_Dims()) - v_mbr.sdo_ordinates(2) < p_Tile_Y ) Then
        v_mbr.sdo_ordinates(2)                := v_mbr.sdo_ordinates(2) - v_half_Y;
        v_mbr.sdo_ordinates(2+SELF.ST_Dims()) := v_mbr.sdo_ordinates(2+SELF.ST_Dims()) + v_half_Y;
    End If;
    v_loCol := TRUNC(v_mbr.sdo_ordinates(1) / p_Tile_X );
    v_loRow := TRUNC(v_mbr.sdo_ordinates(2) / p_Tile_Y );
    v_hiCol :=  CEIL(v_mbr.sdo_ordinates(1+SELF.ST_Dims())/p_Tile_X)-1;
    v_hiRow :=  CEIL(v_mbr.sdo_ordinates(2+SELF.ST_Dims())/p_Tile_Y)-1;
    <<column_interator>>
    For v_col in v_loCol..v_hiCol Loop
       <<row_iterator>>
       For v_row in v_loRow..v_hiRow Loop
           v_geometry := MDSYS.SDO_Geometry(case when v_grid_type IN ('POINT') then 2001 Else 2003 end,
                                            SELF.ST_Srid(),
                                            case when v_grid_type IN ('POINT','BOTH')
                                                 then MDSYS.SDO_Point_Type((v_col * p_Tile_X) + v_half_x,
                                                                           (v_row * p_Tile_Y) + V_Half_Y,
                                                                           NULL)
                                                 else NULL
                                             end,
                                            case when v_grid_type IN ('TILE','BOTH')
                                                 then MDSYS.SDO_Elem_Info_Array(1,1003,3)
                                                 else NULL
                                             end,
                                            case when v_grid_type IN ('TILE','BOTH')
                                                 then MDSYS.SDO_Ordinate_Array(v_col * p_Tile_X,
                                                                               v_row * p_Tile_Y,
                                                                              (v_col * p_Tile_X) + p_Tile_X,
                                                                              (v_row * p_Tile_Y) + p_Tile_Y)
                                                 else null
                                            end );
           v_clip_tgeom := &&INSTALL_SCHEMA..T_GEOMETRY(v_geometry,SELF.tolerance,SELF.dPrecision,SELF.projected);
           IF ( v_option_value = 'MBR' ) THEN
             PIPE ROW (&&INSTALL_SCHEMA..T_Grid(v_col,v_row,v_clip_tGeom.geom));
           ELSE
             -- TODO: Replace call to mdsys.sdo_geom.relate
             If ( mdsys.sdo_geom.relate(v_clip_tgeom.geom,'DETERMINE',SELF.geom,SELF.tolerance)<>'DISJOINT' ) Then
               If ( v_option_value IN ('CLIP','HALFCLIP','HALFTOUCH') AND SELF.ST_Gtype() in (3,7) ) Then
                  v_clip_tgeom := SELF.ST_Intersection(v_geometry,'FIRST');
               END IF;
               IF ( v_option_value IN ('HALFCLIP','HALFTOUCH') AND v_clip_tgeom is not null ) Then
                   IF ( v_clip_tgeom.ST_Area(p_unit) <
                       (&&INSTALL_SCHEMA..T_GEOMETRY(v_geometry,SELF.tolerance,SELF.dPrecision,SELF.projected).ST_Area(p_unit)/2.0) ) Then
                      v_clip_tgeom := NULL;
                   ELSIF ( V_OPTION_VALUE = 'HALFTOUCH' ) THEN
                      v_clip_tgeom.geom := v_geometry;
                   END IF;
                End If;
                IF ( v_clip_tgeom is not null ) THEN
                  PIPE ROW (&&INSTALL_SCHEMA..t_Grid(v_col,v_row,v_clip_tgeom.geom));
                END IF;
             END IF;
           END IF;
       End Loop row_iterator;
     End Loop col_iterator;
   End ST_Tile;

  Member Function ST_SmoothTile
           Return &&INSTALL_SCHEMA..T_GEOMETRY Deterministic
  As
    c_i_compound       CONSTANT INTEGER       := -20121;
    c_s_compound       CONSTANT VARCHAR2(100) := 'Compound geometries are not supported.';

    v_ordinate_array  mdsys.sdo_ordinate_array;
    v_elem_info_array mdsys.sdo_elem_info_array;
    v_ordinates       mdsys.sdo_ordinate_array;
    v_i               pls_integer := 0;
    v_ord_count       pls_integer := 0;
    v_element         pls_integer := 0;
    v_num_rings       pls_integer := 0;
    v_ring            pls_integer := 0;
    v_ring_geom       mdsys.sdo_geometry;
    v_prev_ord_count  pls_integer := 1;
  Begin
    if ( SELF.ST_gtype() not in (3,7) ) Then
       return SELF;
    End If;
    if ( SELF.ST_hasCircularArcs() > 0 ) then
       raise_application_error(c_s_compound,c_s_compound,true);
    End If;
    for v_element in 1..SELF.ST_NumElements() loop
      v_num_rings := &&INSTALL_SCHEMA..T_GEOMETRY(mdsys.sdo_util.extract(SELF.geom,v_element)).ST_NumRings();
      for v_ring in 1..v_num_rings loop
          v_ring_geom := mdsys.sdo_util.extract(SELF.geom,v_element,v_ring);
          -- smooth the ordinates
          select case when a.lid = 1 then mx else my end
            bulk collect into v_ordinates
            from (SELECT LEVEL as lid FROM DUAL CONNECT BY LEVEL < 3) a,
                 (select rid, slope, next_slope, mx, my
                   from (select rid,
                                slope,
                                lag(slope,1)  over (order by rid) as prev_Slope,
                                lead(slope,1) over (order by rid) as next_Slope,
                                mx,my
                           from (select rid,
                                        CASE WHEN (mx - lag(mx,1) over (order by rid)) = 0
                                             THEN 10
                                             ELSE (mY - lag(my,1) over (order by rid)) / (mx - lag(mx,1) over (order by rid))
                                         END as slope,
                                        lag(mx,1) over (order by rid) as lagX,
                                        lag(my,1) over (order by rid) as lagY,
                                        mx, my
                                   from ( select rownum as rid,
                                                 (seg.startCoord.x + seg.endCoord.x) / 2.0 as mX,
                                                 (seg.startCoord.y + seg.endCoord.y) / 2.0 as mY
                                            from Table(&&INSTALL_SCHEMA..T_GEOMETRY(
                                                          v_ring_geom,
                                                          SELF.tolerance,
                                                          SELF.dPrecision,
                                                          SELF.projected
                                                        ).ST_Segmentize(p_filter=>'ALL')
                                                      ) seg
                                        )
                                ) v
                        )
                 ) b
           where b.slope is null
              or b.slope <> b.next_slope
              or b.next_slope is null
           order by rid,lid;
           if ( v_ordinates is not null ) then
              v_ordinates.EXTEND(2);
              v_ordinates(v_ordinates.COUNT-1) := v_ordinates(1);
              v_ordinates(v_ordinates.COUNT  ) := v_ordinates(2);
              v_i := v_i + 1;
              if ( v_i = 1 ) then
                  v_elem_info_array := v_ring_geom.sdo_elem_info;
                  v_ordinate_array  := v_ordinates;
              else
                  v_elem_info_array.EXTEND(3);
                  v_elem_info_array(v_elem_info_array.COUNT)   := v_ring_geom.sdo_elem_info(1); /* interpretation */
                  IF ( v_ring <> 1 and v_ring_geom.sdo_elem_info(2) in (1003,1005) ) THEN
                      v_elem_info_array(v_elem_info_array.COUNT-1) := 1000 + v_ring_geom.sdo_elem_info(2); /* etype */
                      v_ord_count := v_ordinate_array.COUNT;
                      v_ordinate_array.EXTEND(v_ordinates.COUNT);
                      v_i := 1;
                      FOR i IN REVERSE 1..(v_ordinates.COUNT / 2) LOOP
                         v_ordinate_array(v_ord_count+v_i) := v_ordinates(i*2-1);
                         v_i := v_i + 1;
                         v_ordinate_array(v_ord_count+v_i) := v_ordinates(i*2);
                         v_i := v_i + 1;
                      END LOOP;
                  ELSE
                      v_elem_info_array(v_elem_info_array.COUNT-1) := v_ring_geom.sdo_elem_info(2); /* etype */
                      v_ord_count := v_ordinate_array.COUNT;
                      v_ordinate_array.EXTEND(v_ordinates.COUNT);
                      FOR i IN v_ordinates.FIRST..v_ordinates.LAST LOOP
                          v_ordinate_array(v_ord_count+i) := v_ordinates(i);
                      END LOOP;
                  end if;
                  v_elem_info_array(v_elem_info_array.COUNT-2) := v_prev_ord_count;
              end if;
              v_prev_ord_count := v_ordinates.COUNT + v_prev_ord_count;
           end if;
        end loop;
    end loop;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(
             mdsys.sdo_geometry(SELF.geom.sdo_gtype,
                                SELF.geom.sdo_srid,
                                SELF.geom.sdo_point,
                                v_elem_info_array,
                                v_ordinate_array),
                    SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_SmoothTile;

  Member Function ST_RemoveCollinearPoints
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    v_dims            pls_integer;
    v_numGeometries   pls_integer;
    v_extract_tgeom   &&INSTALL_SCHEMA..T_Geometry;
    v_processed_tGeom &&INSTALL_SCHEMA..T_Geometry;
    v_return_tgeom    &&INSTALL_SCHEMA..T_Geometry;

    --PRAGMA INLINE (RemoveCollinearPoints, 'YES');
    Function RemoveCollinearPoints(p_extract_tgeom in &&INSTALL_SCHEMA..t_geometry)
      Return &&INSTALL_SCHEMA..T_Geometry
    As
      v_ord            pls_integer;
      v_segments       &&INSTALL_SCHEMA..t_segments;
      v_geometry       mdsys.sdo_geometry :=
                         mdsys.sdo_geometry(SELF.ST_Sdo_Gtype(),
                                            SELF.ST_Srid(),
                                            SELF.GEOM.SDO_POINT,
                                            p_extract_tgeom.geom.sdo_elem_info,
                                            mdsys.sdo_ordinate_array(0)
                                           );
      v_last_segment   &&INSTALL_SCHEMA..t_segment;
      v_merged_segment &&INSTALL_SCHEMA..t_segment;
    Begin
      -- p_extract_geom is always linestring with no circular arcs
      v_geometry.sdo_ordinates.DELETE;
      v_ord       := 1;
      v_segments  := p_extract_tgeom.ST_Segmentize(p_filter=>'ALL');
      FOR i IN 1..v_segments.COUNT LOOP
        IF ( i = 1 ) THEN
          -- Add startCoord to geometry
          v_geometry.sdo_ordinates.EXTEND(v_dims);
          v_geometry.sdo_ordinates(v_ord  ) := v_segments(i).startCoord.X;
          v_geometry.sdo_ordinates(v_ord+1) := v_segments(i).startCoord.Y;
          IF ( SELF.ST_Dims() >= 3 ) THEN
            v_geometry.sdo_ordinates(v_ord+2) := v_segments(i).startCoord.Z;
          End If;
          v_ord := v_ord + v_dims;
          -- Save
          v_last_segment := v_segments(i);
          CONTINUE;
        END IF;
        v_merged_segment := v_last_segment.ST_Merge(v_segments(i));
        -- DEBUG dbms_output.put_line('v_merged_segment='||v_merged_segment.ST_AsText());
        IF ( v_merged_segment.ST_isEmpty()=1
          OR v_merged_segment.midCoord is not null
          OR v_merged_segment.ST_Equals(v_last_segment)=1 ) THEN
          -- DEBUG dbms_output.put_line('ST_RemoveCollinearPoints: Not Collinear. Add v_last_segment.endCoord');
          -- Add startCoord to geometry
          v_geometry.sdo_ordinates.EXTEND(v_dims);
          v_geometry.sdo_ordinates(v_ord  ) := v_last_segment.endCoord.X;
          v_geometry.sdo_ordinates(v_ord+1) := v_last_segment.endCoord.Y;
          IF ( SELF.ST_Dims() >= 3 ) THEN
            v_geometry.sdo_ordinates(v_ord+2) := v_last_segment.endCoord.Z;
          End If;
          v_ord := v_ord + v_dims;
          v_last_segment := v_segments(i);
        ELSIF ( v_merged_segment.midCoord is null
            AND v_merged_segment.startCoord.ST_Equals(v_last_segment.startCoord)=1
            AND v_merged_segment.endCoord.ST_Equals(v_segments(i).endCoord)=1 ) THEN
          -- DEBUG dbms_output.put_line('ST_RemoveCollinearPoints: Is Collinear and Merged, so do nothing ');
          -- First is added.
          -- Set merged segment as v_last_segment
          v_last_segment := v_merged_segment;
        END IF;
      END LOOP;
      -- Add last endCoord to geometry
      v_geometry.sdo_ordinates.EXTEND(v_dims);
      v_geometry.sdo_ordinates(v_ord  ) := v_last_segment.endCoord.X;
      v_geometry.sdo_ordinates(v_ord+1) := v_last_segment.endCoord.Y;
      IF ( SELF.ST_Dims() >= 3 ) THEN
        v_geometry.sdo_ordinates(v_ord+2) := v_last_segment.endCoord.Z;
      End If;
      Return &&INSTALL_SCHEMA..T_Geometry(
                v_geometry,
                SELF.tolerance,
                SELF.dPrecision,
                SELF.projected
             );
    End RemoveCollinearPoints;

  Begin
    -- At the moment, stroked linestrings without measures only
    --
    IF ( SELF.ST_Dimension() <> 1 and SELF.ST_hasCircularArcs()=1 and SELF.ST_HasM() = 0 ) THEN
      Return SELF;
    END IF;
    v_dims          := SELF.ST_Dims();
    v_numGeometries := SELF.ST_NumGeometries();
    FOR v_GeomN IN 1..v_numGeometries LOOP
      -- Extract linestring from multiLineString
      -- DEBUG dbms_output.put_line('ST_RemoveCollinearPoints( ' || v_GeomN || ' of ' || v_numGeometries || ')');
      v_extract_tgeom := &&INSTALL_SCHEMA..T_Geometry(
                           case when v_numGeometries = 1
                                then SELF.geom
                                else mdsys.sdo_util.Extract(SELF.geom,v_GeomN)
                            end,
                           SELF.tolerance,SELF.dPrecision,SELF.projected);
      -- ***************************
      -- Now remove collinear points
      v_processed_tGeom := RemoveCollinearPoints(v_extract_tgeom);
      -- DEBUG dbms_output.put_line('v_processed_tGeom.geom:' || &&INSTALL_SCHEMA..PRINT.sdo_geometry(v_processed_tGeom.geom,SELF.dPrecision));
      -- ***************************
      IF ( v_return_tgeom is null ) Then
         v_return_tgeom := &&INSTALL_SCHEMA..T_Geometry(v_processed_tgeom.geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
      ELSE
         v_return_tgeom := v_return_tgeom.ST_Append(v_processed_tgeom.geom);
      END IF;
      -- DEBUG dbms_output.put_line('v_return_tgeom.geom:'||&&INSTALL_SCHEMA..PRINT.sdo_geometry(v_return_tgeom.geom,SELF.dPrecision));
    END LOOP;
    Return &&INSTALL_SCHEMA..T_GEOMETRY(v_return_tgeom.geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_RemoveCollinearPoints;

  /** START DEPRECATED MEMBER ST_Split_Segments FUNCTIONS **/

  Member Function ST_Split_Segments(p_vertex in &&INSTALL_SCHEMA..T_Vertex,
                                    p_unit   in varchar2    DEFAULT null,
                                    p_pairs  in integer DEFAULT 0)
           Return &&INSTALL_SCHEMA..T_Segments
  Is
    c_tenth_second     Constant pls_integer   := 5; /* abs(round(log(10,(1/(36000))/2))) */

    c_i_not_geom       CONSTANT INTEGER       := -20121;
    c_s_not_geom       CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance CONSTANT INTEGER       := -20122;
    c_s_null_tolerance CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';
    c_i_pairs          CONSTANT INTEGER       := -20123;
    c_s_pairs          CONSTANT VARCHAR2(100) := 'p_pairs can only be 0 or 1';
    c_i_null_geom      Constant Integer       := -20124;
    c_s_null_geom      Constant VarChar2(100) := 'Geometry must not be null.';

    v_ratio            number;
    v_extend           pls_integer;
    v_bearing          number;
    v_arcAngle2SnapPt  number;
    v_arcLength2SnapPt number;
    v_arcAngle2Mid     number;
    v_arcLength2Mid    number;
    v_arcAngle2End     number;
    v_arcSnapPoint     &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
    v_vertex           &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_vertex => p_vertex);
    v_centre           &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
    v_segments         &&INSTALL_SCHEMA..T_Segments := &&INSTALL_SCHEMA..t_Segments(&&INSTALL_SCHEMA..t_Segment());
    BEGIN
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','Linestring'),TRUE);
    End If;
    If ( p_vertex is null ) Then
       raise_application_error(c_i_null_geom,'Supplied Point ' || c_s_null_geom,true);
    End If;

    -- Check inputs
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;
    If ( NVL(p_pairs,0) not in (0,1) ) Then
       raise_application_error(c_i_pairs,c_s_pairs,TRUE);
    End If;

    -- Delete all in initialised segments
    v_segments.DELETE;

    -- DEBUG dbms_output.put_line('<ST_Split_Segments>'); dbms_output.put_line('  p_vertex= '||p_vertex.ST_AsText(3));

    -- Find and process nearest segments
    --
    <<process_nearest_Segments>>
    FOR v_rec IN (SELECT i.line, i.adjoiningSegment, i.startDist, i.midDist, i.endDist, i.lineDist
                    FROM (SELECT case when h.line = (lag(h.adjoiningSegment,1) over (order by h.line.element_id,h.line.subelement_id,h.line.segment_id))
                                 and (h.startDist = (lag(h.endDist,1)          over (order by h.line.element_id,h.line.subelement_id,h.line.segment_id)) and h.startDist = h.lineDist)
                                      then 1 else 0 end isFollowing,
                                 h.line,h.startDist, h.midDist, h.endDist, h.lineDist, h.adjoiningSegment
                            FROM (SELECT g.line,
                                         g.startDist, g.midDist, g.endDist, g.lineDist,
                                         case when g.startDist = g.lineDist and g.line.segment_id > 1
                                              then g.preSegment
                                              when g.endDist   = g.lineDist and g.line.segment_id < g.maxSegmentId
                                              then g.nextSegment
                                              else null
                                          end as adjoiningSegment
                                    FROM (SELECT f.line, f.startDist, f.midDist, f.endDist, f.lineDist,
                                                 min(f.lineDist)        over (order by 1) as minDist,
                                                 max(f.line.segment_id) over (order by 1) as maxSegmentId,
                                                 lag(f.line, 1) over (order by f.line.element_id,f.line.subelement_id,f.line.segment_id) as preSegment,
                                                 lead(f.line,1) over (order by f.line.element_id,f.line.subelement_id,f.line.segment_id) as nextSegment
                                            FROM (SELECT seg.ST_Self() as line,
                                                         &&INSTALL_SCHEMA..T_Segment(
                                                           p_Segment_id => 0,
                                                           p_startCoord => seg.startCoord,
                                                           p_endCoord   => p_vertex,
                                                           p_sdo_gtype  => SELF.ST_sdo_gtype(),
                                                           p_sdo_srid   => SELF.ST_Srid(),
                                                           p_projected  => SELF.projected,
                                                           p_precision  => SELF.dPrecision,
                                                           p_tolerance  => SELF.tolerance
                                                         ).ST_Length(p_unit) as startDist, /* SGG */
                                                         case when seg.midCoord.x is not null
                                                              then &&INSTALL_SCHEMA..T_Segment(
                                                                     p_Segment_id => 0,
                                                                     p_startCoord => seg.midCoord,
                                                                     p_endCoord   => p_vertex,
                                                                     p_sdo_gtype  => SELF.st_sdo_gtype(),
                                                                     p_sdo_srid   => SELF.ST_Srid(),
                                                                     p_projected  => SELF.projected,
                                                                     p_precision  => SELF.dPrecision,
                                                                     p_tolerance  => SELF.tolerance
                                                                   ).ST_Length(p_unit)
                                                              else CAST(NULL as number)
                                                          end as midDist,
                                                         &&INSTALL_SCHEMA..T_Segment(
                                                           p_Segment_id => 0,
                                                           p_startCoord => seg.endCoord,
                                                           p_endCoord   => p_vertex,
                                                           p_sdo_gtype  => SELF.st_sdo_gtype(),
                                                           p_sdo_srid   => SELF.ST_Srid(),
                                                           p_projected  => SELF.projected,
                                                           p_precision  => SELF.dPrecision,
                                                           p_tolerance  => SELF.tolerance
                                                         ).ST_Length(p_unit) as endDist,  /* SGG */
                                                         seg.ST_Distance(p_vertex    => p_vertex,
                                                                         p_unit   => p_unit) as linedist
                                                   FROM TABLE(SELF.ST_Segmentize(p_filter=>'ALL')) seg
                                                  ORDER BY 5 /* linedist */
                                                 ) f
                                         ) g
                                   WHERE g.linedist = g.minDist
                                 ) h
                         ) i
                   WHERE i.isFollowing = 0 ) -- Get rid of duplicates
      LOOP
        -- DEBUG dbms_output.put_line('    Split segment is ' || v_rec.line.ST_AsText(3));
        -- DEBUG dbms_output.put_line('Adjoining segment is ' || case when v_rec.adjoiningSegment is not null then v_rec.adjoiningSegment.ST_AsText(3) else null end);
        -- DEBUG dbms_output.put_line('  Start Distance is ' || v_rec.startDist);
        -- DEBUG dbms_output.put_line('    End Distance is ' || v_rec.endDist);
        -- DEBUG dbms_output.put_line('    Mid Distance is ' || case when v_rec.midDist is not null then v_rec.midDist else cast(null as number) end);
        -- DEBUG dbms_output.put_line('   Line Distance is ' || v_rec.lineDist);

        -- v_extend := case when NVL(p_pairs,0) = 0 then 1 else 2 end;
        v_extend := case when NVL(p_pairs,0) = 0 AND ( v_rec.adjoiningSegment is null )
                         then 1
                         else 2
                      end;

        -- Now do the splitting/snapping
        --
        If ( v_rec.line.midCoord is not null ) Then
           -- DEBUG dbms_output.put_line('Compute common centre and radius for circular arc: ' || v_rec.line.ST_AsText(3) );
           -- DEBUG dbms_output.put_line('v_rec.line.midCoord = ' || v_rec.line.midCoord.ST_asText(3));
           -- All calculations assume that the circular arc segment/segment is no larger than a semi-circle.
           --
           v_centre := v_rec.line.ST_FindCircle(); -- ID holds flag indicating whether centre found.
           If ( v_centre.id = -9 ) Then -- Points are collinear and no finite-radius circle through them exists.
               -- DEBUG dbms_output.put_line('v_centre=(' || v_centre.x|| ',' || v_centre.y||','||v_centre.z||')');
               -- get bearing from centre to p_vertex
               -- DEBUG dbms_output.put_line('p_vertex=(' || p_vertex.x|| ',' || p_vertex.y||','||p_vertex.z||')');
               v_bearing   := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_Bearing(p_vertex=>p_vertex,p_projected=>SELF.projected));  -- radians
               -- DEBUG dbms_output.put_line('v_bearing=' || v_bearing);
               -- Snap point is bearing+radius from centre
               -- Can't use sdo_util.point_at_bearing as """"The point geometry must be based on a geodetic coordinate system.""""
               v_arcSnapPoint := v_centre.ST_FromBearingAndDistance(v_bearing,v_centre.z,SELF.projected);
               -- DEBUG dbms_output.put_line('v_arcSnapPoint=sdo_geometry('||v_arcSnapPoint.ST_AsText(3)||')');
           End If;
        End If;

        -- Need to actually to split the returned segment...
        --
        if ( ( ROUND(v_rec.startDist,SELF.dPrecision) = 0 ) OR
             ( ROUND(v_rec.startDist,SELF.dPrecision) = ROUND(v_rec.lineDist,SELF.dPrecision) ) ) then
           -- DEBUG dbms_output.put_line('Point splits line at the start of the segment');
           -- Point splits line at the start of the segment
           v_segments.EXTEND(v_extend);
           v_segments(v_segments.COUNT-(v_extend-1)) := &&INSTALL_SCHEMA..T_Segment(p_segment => v_rec.line);
           if ( v_extend = 2 ) Then
               v_segments(v_segments.COUNT) := &&INSTALL_SCHEMA..T_Segment(p_segment => v_rec.adjoiningSegment);
           end if;
        elsif ( ROUND(v_rec.midDist,SELF.dPrecision) = 0 ) OR
              ( ROUND(v_rec.midDist,SELF.dPrecision) = ROUND(v_rec.lineDist,SELF.dPrecision) ) Then
           -- DEBUG dbms_output.put_line('point Splits line at the mid point of the segment');
           -- point Splits line at the mid point of the segment
           v_segments.EXTEND(2);
           v_segments(v_segments.COUNT-1) :=
               &&INSTALL_SCHEMA..T_Segment(
                 p_element_id    => v_rec.line.element_id,
                 p_subelement_id => v_rec.line.subelement_id,
                 p_Segment_id    => v_rec.line.segment_id,
                 p_startCoord    => v_rec.line.startCoord,
                 p_midCoord      => v_centre.ST_FromBearingAndDistance(v_bearing - ABS(v_arcAngle2SnapPt / 2.0),v_centre.z,SELF.projected),
                 p_endCoord      => v_arcSnapPoint,
                 p_sdo_gtype     => SELF.geom.sdo_gtype,
                 p_sdo_srid      => SELF.ST_Srid(),
                 p_projected     => SELF.projected,
                 p_precision     => SELF.dPrecision,
                 p_tolerance     => SELF.tolerance
               );
           -- segment two is the circular arc from the mid to the end
           v_arcAngle2End := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_arcSnapPoint,v_rec.line.EndCoord));
           v_segments(v_segments.COUNT  ) :=
               &&INSTALL_SCHEMA..T_Segment(
                 p_element_id    => v_rec.line.element_id,
                 p_subelement_id => v_rec.line.subelement_id,
                 p_Segment_id    => v_rec.line.segment_id,
                 p_startCoord    => v_arcSnapPoint,
                 p_midCoord      => v_centre.ST_FromBearingAndDistance(v_bearing + ABS(v_arcAngle2End / 2.0),v_centre.z,SELF.projected),
                 p_endCoord      => v_rec.line.endCoord,
                 p_sdo_gtype     => SELF.geom.sdo_gtype,
                 p_sdo_srid      => SELF.ST_Srid(),
                 p_projected     => SELF.projected,
                 p_precision     => SELF.dPrecision,
                 p_tolerance     => SELF.tolerance
               );
        elsif ( ROUND(v_rec.endDist,SELF.dPrecision) = 0 ) OR
              ( ROUND(v_rec.endDist,SELF.dPrecision) = ROUND(v_rec.lineDist,SELF.dPrecision) ) then
           -- DEBUG dbms_output.put_line('point Splits line at the end of the segment EXTEND by ' || v_extend);
           -- point Splits line at the end of the segment
           v_segments.EXTEND(v_extend);
           -- DEBUG dbms_output.put_line('Adding ' || v_rec.line.ST_AsText(3) || ' to v_segments at position ' || (v_segments.COUNT-(v_extend-1)));
           v_segments(v_segments.COUNT-(v_extend-1)) := &&INSTALL_SCHEMA..T_Segment(v_rec.line);
           if ( v_extend = 2 ) Then
              -- DEBUG dbms_output.put_line('Adding &&INSTALL_SCHEMA..T_Segment(v_rec.adjoiningSegment) to v_segments at position ' || (v_segments.COUNT));
               v_segments(v_segments.COUNT) := &&INSTALL_SCHEMA..T_Segment(v_rec.adjoiningSegment);
           end if;
        elsif ( ROUND(v_rec.lineDist,SELF.dPrecision) = 0 ) Then
           -- DEBUG dbms_output.put_line('point is on line/circular arc between start and end of segment');
           if ( v_rec.line.midCoord is not null ) Then
             -- DEBUG dbms_output.put_line('Circular Arc: Point is ON circular arc between start and end of segment');
             -- is length to point < length to midpoint?
             v_arcAngle2SnapPt  := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_rec.line.startCoord,v_arcSnapPoint));
             v_arcLength2SnapPt := ROUND(&&INSTALL_SCHEMA..COGO.ComputeArcLength(v_centre.z ,v_arcAngle2SnapPt),SELF.dPrecision);
             v_arcAngle2Mid     := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_rec.line.startCoord,v_rec.line.midCoord));
             v_arcLength2Mid    := ROUND(&&INSTALL_SCHEMA..COGO.ComputeArcLength(v_centre.z ,v_arcAngle2Mid),SELF.dPrecision);
             -- DEBUG dbms_output.put_line('&&INSTALL_SCHEMA..COGO.ST_Degrees(v_arcAngle2SnapPt)=' || v_arcAngle2SnapPt || ' v_arcLength2SnapPt= ' || v_arcLength2SnapPt);
             -- DEBUG dbms_output.put_line('&&INSTALL_SCHEMA..COGO.ST_Degrees(v_arcAngle2Mid)   =' || v_arcAngle2Mid    || ' v_arcLength2Mid   = ' || v_arcLength2Mid );
              if (ABS(v_arcLength2SnapPt) < ABS(v_arcLength2Mid) ) Then
                -- DEBUG dbms_output.put_line('Circular Arc: length to point IS < length to midpoint?');
                -- Vertices that define:
                -- First circular arc are Start/New/Mid
                -- Second circular arc are Snap/Mid/End
                v_segments.EXTEND(2);
                -- Need to calculate a point on the curve between start point and snap point
                v_segments(v_segments.COUNT-1) :=
                   &&INSTALL_SCHEMA..T_Segment(
                     element_id    => v_rec.line.element_id,
                     subelement_id => v_rec.line.subelement_id,
                     Segment_id    => v_rec.line.segment_id,
                     startCoord    => v_rec.line.startCoord,
                     midCoord      => v_centre.ST_FromBearingAndDistance(v_bearing - ABS(v_arcAngle2SnapPt / 2.0),v_centre.z,SELF.projected),
                     endCoord      => v_rec.line.midCoord,
                     sdo_gtype     => SELF.geom.sdo_gtype,
                     sdo_srid      => SELF.ST_Srid(),
                     projected     => SELF.projected,
                     precisionModel  => &&INSTALL_SCHEMA..T_PrecisionModel(
                                                 xy        => SELF.dPrecision,
                                                 z         => NULL,
                                                 w         => NULL,
                                                 tolerance => SELF.tolerance )
                   );
                v_segments(v_segments.COUNT  ) :=
                    &&INSTALL_SCHEMA..T_Segment(
                      element_id    => v_rec.line.element_id,
                      subelement_id => v_rec.line.subelement_id,
                      Segment_id    => v_rec.line.segment_id,
                      startCoord    => v_arcSnapPoint,
                      midCoord      => v_rec.line.midCoord,
                      endCoord      => v_rec.line.endCoord,
                      sdo_gtype     => SELF.geom.sdo_gtype,
                      sdo_srid      => SELF.ST_Srid(),
                      projected     => SELF.projected,
                      precisionModel  => &&INSTALL_SCHEMA..T_PrecisionModel(
                                                 xy        => SELF.dPrecision,
                                                 z         => NULL,
                                                 w         => NULL,
                                                 tolerance => SELF.tolerance )
                    );
              ElsIf ( ROUND(v_arcLength2SnapPt,SELF.dPrecision) = ROUND(v_arcLength2Mid,SELF.dPrecision)) Then
                -- DEBUG dbms_output.put_line('Circular arc: length to point IS = length to midpoint?');
                -- Vertices that define:
                -- First circular arc are Start/New/Mid
                -- Second circular arc are Mid/New/End
                v_segments.EXTEND(2);
                -- Need to calculate a point on the curve between start point and snap point
                v_segments(v_segments.COUNT-1) :=
                    &&INSTALL_SCHEMA..T_Segment(
                      element_id    => v_rec.line.element_id,
                      subelement_id => v_rec.line.subelement_id,
                      Segment_id    => v_rec.line.segment_id,
                      startCoord    => v_rec.line.startCoord,
                      midCoord      => v_centre.ST_FromBearingAndDistance(v_bearing - ABS(v_arcAngle2SnapPt / 2.0),v_centre.z,SELF.projected),
                      endCoord      => v_rec.line.midCoord,
                      sdo_gtype     => SELF.ST_sdo_gtype(),
                      sdo_srid      => SELF.ST_Srid(),
                      projected     => SELF.projected,
                      precisionModel=> &&INSTALL_SCHEMA..T_PrecisionModel(
                                                 xy        => SELF.dPrecision,
                                                 z         => NULL,
                                                 w         => NULL,
                                                 tolerance => SELF.tolerance )
                    );
                v_segments(v_segments.COUNT  ) :=
                    &&INSTALL_SCHEMA..T_Segment(
                      element_id    => v_rec.line.element_id,
                      subelement_id => v_rec.line.subelement_id,
                      Segment_id    => v_rec.line.segment_id,
                      startCoord    => v_rec.line.midCoord,
                      midCoord      => v_centre.ST_FromBearingAndDistance(v_bearing + ABS(v_arcAngle2SnapPt / 2.0),v_centre.z,SELF.projected),
                      endCoord      => v_rec.line.endCoord,
                      sdo_gtype     => SELF.ST_sdo_gtype(),
                      sdo_srid      => SELF.ST_Srid(),
                      projected     => SELF.projected,
                      precisionModel=> &&INSTALL_SCHEMA..T_PrecisionModel(
                                                 xy        => SELF.dPrecision,
                                                 z         => NULL,
                                                 w         => NULL,
                                                 tolerance => SELF.tolerance )
                   );
              Else
                -- DEBUG dbms_output.put_line('Circular arc: length to point IS > length to midpoint?');
                -- Vertices that define
                -- First circular arc are Start/Mid/Snap
                -- Second circular arc are SnapPoint/NewPoint/EndPoint
                v_segments.EXTEND(2);
                -- need point on curve between snap point and end point
                v_segments(v_segments.COUNT-1) :=
                   &&INSTALL_SCHEMA..T_Segment(
                     element_id    => v_rec.line.element_id,
                     subelement_id => v_rec.line.subelement_id,
                     Segment_id    => v_rec.line.segment_id,
                     startCoord    => v_rec.line.startCoord,
                     midCoord      => v_rec.line.midCoord,
                     endCoord      => v_arcSnapPoint,
                     sdo_gtype     => SELF.ST_sdo_gtype(),
                     sdo_srid      => SELF.ST_Srid(),
                     projected     => SELF.projected,
                     precisionModel=> &&INSTALL_SCHEMA..T_PrecisionModel(
                                                 xy        => SELF.dPrecision,
                                                 z         => NULL,
                                                 w         => NULL,
                                                 tolerance => SELF.tolerance )

                  );
                v_arcAngle2End := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_arcSnapPoint,v_rec.line.EndCoord));
                v_segments(v_segments.COUNT) :=
                  &&INSTALL_SCHEMA..T_Segment(
                    element_id    => v_rec.line.element_id,
                    subelement_id => v_rec.line.subelement_id,
                    Segment_id    => v_rec.line.segment_id,
                    startCoord    => v_arcSnapPoint,
                    midCoord      => v_centre.ST_FromBearingAndDistance(v_bearing + ABS(v_arcAngle2End / 2.0),v_centre.z,SELF.projected),
                    endCoord      => v_rec.line.endCoord,
                    sdo_gtype     => SELF.ST_sdo_gtype(),
                    sdo_srid      => SELF.ST_Srid(),
                    projected     => SELF.projected,
                    precisionModel=> &&INSTALL_SCHEMA..T_PrecisionModel(
                                                 xy        => SELF.dPrecision,
                                                 z         => NULL,
                                                 w         => NULL,
                                                 tolerance => SELF.tolerance )
                );
              End If;
           Else
               -- DEBUG dbms_output.put_line('Ordinary linestring: Point is ON segment between start and end point');
               -- Even if p_vertex has measure z/w it can't be assumed to be same as linestring so we recompute base on distances
               v_ratio := v_rec.startDist / (v_rec.startDist+v_rec.endDist);
               -- DEBUG dbms_output.put_line('V_Ratio is: ' || v_ratio); dbms_output.put_line('    v_rec.line: ' || v_rec.line.ST_AsText(SELF.dPrecision));
               v_vertex.x := ROUND(v_rec.line.startCoord.x+((v_rec.line.endCoord.x-v_rec.line.startCoord.x)*v_ratio),SELF.dPrecision);
               -- DEBUG dbms_output.put_line('New X Point is: ' || v_vertex.x);
               v_vertex.y := ROUND(v_rec.line.startCoord.y+((v_rec.line.endCoord.y-v_rec.line.startCoord.y)*v_ratio),SELF.dPrecision);
               If (v_rec.line.startCoord.z is not null ) then -- SELF.ST_Lrs_Dim()=3) Then
                 v_vertex.z := v_rec.line.startCoord.z+(v_rec.line.endCoord.z-v_rec.line.startCoord.z)*v_ratio;
               ElsIf (v_rec.line.startCoord.w is not null ) then -- SELF.ST_Lrs_Dim()=3) Then
                  v_vertex.w := v_rec.line.startCoord.w+(v_rec.line.endCoord.w-v_rec.line.startCoord.w)*v_ratio;
               End If;
               -- DEBUG dbms_output.put_line('   Intersecting Vertex: ' || v_vertex.ST_AsText(SELF.dPrecision));
               v_segments.EXTEND(2);
               v_segments(v_segments.COUNT-1) :=
                 &&INSTALL_SCHEMA..T_Segment(
                    element_id    => v_rec.line.element_id,
                    subelement_id => v_rec.line.subelement_id,
                    Segment_id    => v_rec.line.segment_id,
                    startCoord    => v_rec.line.startCoord,
                    midCoord      => NULL,
                    endCoord      => v_vertex,
                    sdo_gtype     => SELF.ST_sdo_gtype(),
                    sdo_srid      => SELF.ST_Srid(),
                    projected     => SELF.projected,
                    precisionModel=> &&INSTALL_SCHEMA..T_PrecisionModel(
                                                 xy        => SELF.dPrecision,
                                                 z         => NULL,
                                                 w         => NULL,
                                                 tolerance => SELF.tolerance )
                );
               -- DEBUG dbms_output.put_line('    First segment: ' || v_segments(v_segments.COUNT-1).ST_AsText(SELF.dPrecision));
               v_segments(v_segments.COUNT  ) :=
                 &&INSTALL_SCHEMA..T_Segment(
                    element_id    => v_rec.line.element_id,
                    subelement_id => v_rec.line.subelement_id,
                    Segment_id    => v_rec.line.segment_id,
                    startCoord    => v_vertex,
                    midCoord      => NULL,
                    endCoord      => v_rec.line.endCoord,
                    sdo_gtype     => SELF.ST_sdo_gtype(),
                    sdo_srid      => SELF.ST_Srid(),
                    projected     => SELF.projected,
                    precisionModel=> &&INSTALL_SCHEMA..T_PrecisionModel(
                                                 xy        => SELF.dPrecision,
                                                 z         => NULL,
                                                 w         => NULL,
                                                 tolerance => SELF.tolerance )
                );
               -- DEBUG dbms_output.put_line('   Second segment: ' || v_segments(v_segments.COUNT).ST_AsText(SELF.dPrecision));
           End If;
        Else
           If ( v_rec.line.midCoord is not null ) Then
             -- DEBUG dbms_output.put_line('Circular arc: Point is off of a circular arc line');
             v_arcAngle2SnapPt  := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_rec.line.startCoord,v_arcSnapPoint));
             v_arcLength2SnapPt := ROUND(&&INSTALL_SCHEMA..COGO.ComputeArcLength(v_centre.z ,v_arcAngle2SnapPt),SELF.dPrecision);
             v_arcAngle2Mid     := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_rec.line.startCoord,v_rec.line.midCoord));
             v_arcLength2Mid    := ROUND(&&INSTALL_SCHEMA..COGO.ComputeArcLength(v_centre.z ,v_arcAngle2Mid),SELF.dPrecision);
             -- DEBUG dbms_output.put_line('&&INSTALL_SCHEMA..COGO.ST_Degrees(v_arcAngle2SnapPt)=' || v_arcAngle2SnapPt || ' v_arcLength2SnapPt= ' || v_arcLength2SnapPt );
             -- DEBUG dbms_output.put_line('&&INSTALL_SCHEMA..COGO.ST_Degrees(v_arcAngle2Mid)   =' || v_arcAngle2Mid    || ' v_arcLength2Mid   = ' || v_arcLength2Mid );
             if (ABS(ROUND(v_arcLength2SnapPt,SELF.dPrecision)) < ABS(ROUND(v_arcLength2Mid,SELF.dPrecision)) ) Then
                -- DEBUG dbms_output.put_line('Circular arc: length to snap point IS < length to midpoint');
                -- Vertices that define First  circular arc are Start/New/Snap
                -- Vertices that define Second circular arc are Snap/Mid/End
                v_segments.EXTEND(2);
                -- Need to calculate a point on the curve between start point and snap point
                v_segments(v_segments.COUNT-1) :=
                  &&INSTALL_SCHEMA..T_Segment(
                    element_id    => v_rec.line.element_id,
                    subelement_id => v_rec.line.subelement_id,
                    Segment_id    => v_rec.line.segment_id,
                    startCoord    => v_rec.line.startCoord,
                    midCoord      => v_centre.ST_FromBearingAndDistance(v_bearing - ABS(v_arcAngle2SnapPt / 2.0),v_centre.z,SELF.projected),
                    endCoord      => v_arcSnapPoint,
                    sdo_gtype     => SELF.ST_sdo_gtype(),
                    sdo_srid      => SELF.ST_Srid(),
                    projected     => SELF.projected,
                    precisionModel=> &&INSTALL_SCHEMA..T_PrecisionModel(
                                                 xy        => SELF.dPrecision,
                                                 z         => NULL,
                                                 w         => NULL,
                                                 tolerance => SELF.tolerance )
                  );
                v_segments(v_segments.COUNT  ) :=
                  &&INSTALL_SCHEMA..T_Segment(
                    element_id    => v_rec.line.element_id,
                    subelement_id => v_rec.line.subelement_id,
                    Segment_id    => v_rec.line.segment_id,
                    startCoord    => v_arcSnapPoint,
                    midCoord      => v_rec.line.midCoord,
                    endCoord      => v_rec.line.endCoord,
                    sdo_gtype     => SELF.ST_sdo_gtype(),
                    sdo_srid      => SELF.ST_Srid(),
                    projected     => SELF.projected,
                    precisionModel=> &&INSTALL_SCHEMA..T_PrecisionModel(
                                                 xy        => SELF.dPrecision,
                                                 z         => NULL,
                                                 w         => NULL,
                                                 tolerance => SELF.tolerance )
                  );
              Else
                -- DEBUG dbms_output.put_line('circular arc: length to snap point IS > length to midpoint');
                -- Vertices that define
                -- First circular arc are Start/Mid/Snap
                -- Second circular arc are SnapPoint/NewPoint/EndPoint
                v_segments.EXTEND(2);
                -- need point on curve between snap point and end point
                v_arcAngle2End := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_arcSnapPoint,v_rec.line.EndCoord));
                v_segments(v_segments.COUNT-1) :=
                  &&INSTALL_SCHEMA..T_Segment(
                    element_id    => v_rec.line.element_id,
                    subelement_id => v_rec.line.subelement_id,
                    Segment_id     => v_rec.line.segment_id,
                    startCoord    => v_rec.line.startCoord,
                    midCoord      => v_rec.line.midCoord,
                    endCoord      => v_arcSnapPoint,
                    sdo_gtype     => SELF.st_sdo_gtype(),
                    sdo_srid      => SELF.ST_Srid(),
                    projected     => SELF.projected,
                    precisionModel=> &&INSTALL_SCHEMA..T_PrecisionModel(
                                                 xy        => SELF.dPrecision,
                                                 z         => NULL,
                                                 w         => NULL,
                                                 tolerance => SELF.tolerance )
                  );
                v_segments(v_segments.COUNT) :=
                  &&INSTALL_SCHEMA..T_Segment(
                    element_id    => v_rec.line.element_id,
                    subelement_id => v_rec.line.subelement_id,
                    Segment_id    => v_rec.line.segment_id,
                    startCoord    => v_arcSnapPoint,
                    midCoord      => v_centre.ST_FromBearingAndDistance(v_bearing + ABS(v_arcAngle2End / 2.0),v_centre.z,SELF.projected),
                    endCoord      => v_rec.line.endCoord,
                    sdo_gtype     => SELF.st_sdo_gtype(),
                    sdo_srid      => SELF.ST_Srid(),
                    projected     => SELF.projected,
                    precisionModel=> &&INSTALL_SCHEMA..T_PrecisionModel(
                                                 xy        => SELF.dPrecision,
                                                 z         => NULL,
                                                 w         => NULL,
                                                 tolerance => SELF.tolerance )
                  );
              End If;
           Else
             -- DEBUG dbms_output.put_line('Ordinary linestring: point is off a straight line but between first and last vertex so split point is ratio of start/end distances');
             v_ratio := /* distance start to drop point / total length of segment */
                      SQRT(POWER(v_rec.startDist,2) -
                           POWER(v_rec.lineDist,2)) /
                      v_rec.line.ST_Length(p_unit=>p_unit);
             -- DEBUG dbms_output.put_line('distance start to drop point: ' || SQRT(POWER(v_rec.startDist,2)-POWER(v_rec.lineDist,2)));
             -- DEBUG dbms_output.put_line('total length of segment: ' || v_rec.line.ST_Length(SELF.tolerance,p_unit));
             -- DEBUG dbms_output.put_line('V_Ratio is: ' || v_ratio);
             v_vertex.x := ROUND(v_rec.line.startCoord.x+((v_rec.line.endCoord.x-v_rec.line.startCoord.x)*v_ratio),SELF.dPrecision);
             -- DEBUG dbms_output.put_line('New X Point is: ' || v_vertex.x);
             v_vertex.y := ROUND(v_rec.line.startCoord.y+((v_rec.line.endCoord.y-v_rec.line.startCoord.y)*v_ratio),SELF.dPrecision);
             if (SELF.ST_Lrs_Dim()<>0) Then
                -- Even if p_vertex has measure z/w it can't be assumed to be same as linestring so we recompute base on distances
                v_ratio := v_rec.startDist / (v_rec.startDist+v_rec.endDist);
                If (SELF.ST_Lrs_Dim()=3) Then
                   v_vertex.z := v_rec.line.startCoord.z+(v_rec.line.endCoord.z-v_rec.line.startCoord.z)*v_ratio;
                Else
                   v_vertex.w := v_rec.line.startCoord.w+(v_rec.line.endCoord.w-v_rec.line.startCoord.w)*v_ratio;
                End If;
             End If;
             v_vertex.id := 2;
             -- DEBUG dbms_output.put_line('writing out segments split by computed v_vertex = ' || v_vertex.ST_AsText(3));
             v_segments.EXTEND(2);
             v_segments(v_segments.COUNT-1) :=
               &&INSTALL_SCHEMA..T_Segment(
                 p_element_id    => v_rec.line.element_id,
                 p_subelement_id => v_rec.line.subelement_id,
                 p_Segment_id    => v_rec.line.segment_id,
                 p_startCoord    => v_rec.line.startCoord,
                 p_endCoord      => v_vertex,
                 p_sdo_gtype     => SELF.st_sdo_gtype(),
                 p_sdo_srid      => SELF.ST_Srid(),
                 p_projected     => SELF.projected,
                 p_precision     => SELF.dPrecision,
                 p_tolerance     => SELF.tolerance 
              );

             -- DEBUG dbms_output.put_line('Segment(' || (v_segments.COUNT-1) || ')=' || v_segments(v_segments.COUNT-1).ST_AsText(3));
             v_segments(v_segments.COUNT  ) :=
               &&INSTALL_SCHEMA..T_Segment(
                 p_element_id    => v_rec.line.element_id,
                 p_subelement_id => v_rec.line.subelement_id,
                 p_Segment_id    => v_rec.line.segment_id,
                 p_startCoord    => v_vertex,
                 p_endCoord      => v_rec.line.endCoord,
                 p_sdo_gtype     => SELF.st_sdo_gtype(),
                 p_sdo_srid      => SELF.ST_Srid(),
                 p_projected     => SELF.projected,
                 p_precision     => SELF.dPrecision,
                 p_tolerance     => SELF.tolerance 
              );
             -- DEBUG dbms_output.put_line('Segment(' || (v_segments.COUNT) || ')=' || v_segments(v_segments.COUNT).ST_AsText(3));
           End If;
        End If;
    END LOOP process_nearest_Segments;
    -- DEBUG dbms_output.put_line('</ST_Split_Segments>');
    return v_segments;
  End ST_Split_Segments;

  Member Function ST_Split_Segments(p_point in mdsys.sdo_geometry,
                                    p_unit  in varchar2 DEFAULT null,
                                    p_pairs in integer  DEFAULT 0)
           Return &&INSTALL_SCHEMA..T_Segments
  As
    c_i_not_geom       CONSTANT INTEGER       := -20121;
    c_s_not_geom       CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance CONSTANT INTEGER       := -20122;
    c_s_null_tolerance CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';
    v_vertex           &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype=>SELF.ST_sdo_gtype(),p_sdo_srid=>SELF.ST_SRID());
    v_point            &&INSTALL_SCHEMA..T_GEOMETRY;
    v_vertices         mdsys.vertex_set_type;
  Begin
    -- &&INSTALL_SCHEMA..T_GEOMETRY will validate p_point
    v_point := &&INSTALL_SCHEMA..T_GEOMETRY(p_point,SELF.tolerance,SELF.dPrecision,SELF.projected);
    -- Get point as vertex
    v_vertices := mdsys.sdo_util.getVertices(p_point);
    if ( v_vertices is null or v_vertices.COUNT = 0 ) Then
       RETURN null;
    End If;
    v_vertex := &&INSTALL_SCHEMA..T_Vertex(
                      p_vertex    => v_vertices(1),
                      p_id        => 0,
                      p_sdo_gtype => p_point.sdo_gtype,
                      p_sdo_srid  => p_point.sdo_srid);
    Return SELF.ST_Split_Segments(p_vertex => v_vertex,
                                  p_unit   => p_unit,
                                  p_pairs  => p_pairs);
  End ST_Split_Segments;

 /** END DEPRECATED MEMBER ST_Split_Segments FUNCTIONS **/

  Member Function ST_Split(p_vertex in &&INSTALL_SCHEMA..T_Vertex,
                           p_unit   in varchar2 DEFAULT null)
           Return &&INSTALL_SCHEMA..T_Geometries
  Is
    c_tenth_second     Constant pls_integer   := 5; /* abs(round(log(10,(1/(36000))/2))) */

    c_i_not_geom       CONSTANT INTEGER       := -20121;
    c_s_not_geom       CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance CONSTANT INTEGER       := -20122;
    c_s_null_tolerance CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';
    c_i_null_geom      Constant Integer       := -20124;
    c_s_null_geom      Constant VarChar2(100) := 'Geometry must not be null.';

    v_ratio            number;
    v_bearing          number;
    v_arcAngle2SnapPt  number;
    v_arcLength2SnapPt number;
    v_arcAngle2Mid     number;
    v_arcLength2Mid    number;
    v_arcAngle2End     number;
    v_arcSnapPoint     &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype=>SELF.ST_sdo_gtype(),p_sdo_srid=>SELF.ST_SRID());
    v_vertex           &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_vertex   =>p_vertex);
    v_centre           &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype=>SELF.ST_sdo_gtype(),p_sdo_srid=>SELF.ST_SRID());
    v_segment          &&INSTALL_SCHEMA..T_Segment;
    v_element          mdsys.sdo_geometry;
    v_return_geom      &&INSTALL_SCHEMA..T_Geometry;
    v_geometries       &&INSTALL_SCHEMA..T_Geometries := &&INSTALL_SCHEMA..t_geometries(&&INSTALL_SCHEMA..T_GEOMETRY_ROW(0,NULL,SELF.tolerance,SELF.dPrecision,SELF.projected));

    -- PRAGMA INLINE (addToGeomList, 'YES');
    Procedure addToGeomList(p_geometries  in out nocopy &&INSTALL_SCHEMA..t_geometries,
                            p_return_geom in out nocopy &&INSTALL_SCHEMA..t_geometry,
                            p_Segment      in &&INSTALL_SCHEMA..t_Segment)
    As
    Begin
        -- DEBUG dbms_output.put_line('<addToGeomList>');
        -- DEBUG dbms_output.put(' Adding');
        If ( p_return_geom is null) Then
           -- DEBUG dbms_output.put(' to start of new line: ');
           p_return_geom := &&INSTALL_SCHEMA..T_Geometry(p_Segment.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);
        Else
           -- DEBUG dbms_output.put(' to existing geometry: ');
           p_return_geom := p_return_geom.ST_Add_Segment(p_Segment);
        End If;
        -- DEBUG dbms_output.put_line(p_Segment.ST_AsText(3));
        -- DEBUG dbms_output.put_line(' Write Out Geometry');
        p_geometries.EXTEND(1);
        p_geometries(p_geometries.COUNT) := &&INSTALL_SCHEMA..T_GEOMETRY_ROW(p_geometries.COUNT,p_return_geom.geom,SELF.tolerance,SELF.dPrecision,SELF.projected);
        -- DEBUG dbms_output.put_line('p_return_geom:'||&&INSTALL_SCHEMA..PRINT.sdo_geometry(p_return_geom.geom,p_return_geom.dPrecision));
        p_return_geom := NULL;
        -- DEBUG dbms_output.put_line('</addToGeomList>');
        Return;
    End addToGeomList;

  Begin
    -- Only makes sense to split a linestring with a point
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','Linestring'),TRUE);
    End If;
    If ( p_vertex is null ) Then
       raise_application_error(c_i_null_geom,'Supplied Point ' || c_s_null_geom,true);
    End If;

    -- Check inputs
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;

    -- Delete all in initialised segments
    v_geometries.DELETE;

    -- DEBUG dbms_output.put_line('<ST_Split>'); dbms_output.put_line('  p_vertex= '||p_vertex.ST_AsText(3));

    -- Find and process nearest segments
    -- Note: MultiLinestrings are handled by code, no need to extract each and process separately
    --
    <<process_nearest_Segments>>
    FOR v_rec IN (SELECT i.line, 
                         i.startDist2Vertex, i.midDist2Vertex, i.endDist2Vertex, 
                         case when i.line.ST_isCircularArc() = 1 
                              then -1 /* Compute in code */
                              else i.startDist2Vertex + i.endDist2Vertex  
                              end as computedLength, /* If same as i.segmentLength then the segment is the intersecting segment */
                         i.lineDist2Vertex, i.segmentLength,
                         min(i.lineDist2Vertex) over (order by 1) as MinimumDist,
                         case when i.line.element_id <>
                                   lag(i.line.element_id,1) over (order by i.line.element_id, i.line.segment_id)
                              then 1 
                              else 0 
                          end as lastSegment
                    FROM (SELECT seg.ST_Self() as line,
                                 &&INSTALL_SCHEMA..T_Segment(
                                   p_Segment_id => 0,
                                   p_startCoord => seg.startCoord,
                                   p_endCoord   => p_vertex,
                                   p_sdo_gtype  => SELF.ST_sdo_gtype(),
                                   p_sdo_srid   => SELF.ST_Srid(),
                                   p_projected  => seg.projected,
                                   p_precision  => seg.PrecisionModel.xy,
                                   p_tolerance  => seg.PrecisionModel.tolerance
                                 ).ST_Length(p_unit) as startDist2Vertex,
                                 case when seg.midCoord.x is not null
                                      then &&INSTALL_SCHEMA..T_Segment(
                                             p_Segment_id => 0,
                                             p_startCoord => seg.midCoord,
                                             p_endCoord   => p_vertex,
                                             p_sdo_gtype  => SELF.st_sdo_gtype(),
                                             p_sdo_srid   => SELF.ST_Srid(),
                                             p_projected  => seg.projected,
                                             p_precision  => seg.PrecisionModel.xy,
                                             p_tolerance  => seg.PrecisionModel.tolerance
                                            ).ST_Length(p_unit)
                                       else CAST(NULL as number)
                                   end as midDist2Vertex,
                                  &&INSTALL_SCHEMA..T_Segment(
                                      p_Segment_id => 0,
                                      p_startCoord => seg.endCoord,
                                      p_endCoord   => p_vertex,
                                      p_sdo_gtype  => SELF.st_sdo_gtype(),
                                      p_sdo_srid   => SELF.ST_Srid(),
                                      p_projected  => seg.projected,
                                      p_precision  => seg.PrecisionModel.xy,
                                      p_tolerance  => seg.PrecisionModel.tolerance
                                  ).ST_Length(p_unit) as endDist2Vertex,
                                  seg.ST_Distance(p_vertex    => p_vertex,
                                                  p_unit      => p_unit)
                                      as linedist2Vertex,
                                  seg.ST_Length(p_unit=>p_unit) as segmentLength
                            FROM TABLE(SELF.ST_Segmentize(p_filter=>'ALL')) seg
                         ) i
            )
      LOOP
        -- DEBUG dbms_output.put_line(' Split segment is ' || v_rec.line.ST_AsText(3));
        -- DEBUG dbms_output.put_line(' Distances (Start,Mid,End) are (' || v_rec.startDist || ',' ||  case when v_rec.midDist is not null then to_char(v_rec.midDist,'FM9999999.9999') else 'NULL' end || ',' ||v_rec.endDist || ')');
        -- DEBUG dbms_output.put_line(' Distances (Line,Minimum) are (' || v_rec.lineDist || ',' || v_rec.MinimumDist || ')');
        -- DEBUG dbms_output.put_line(' Line Length is ' || v_rec.lineLen);
        -- DEBUG dbms_output.put_line(' Last segment is ' || v_rec.lastSegment);

        -- DEBUG dbms_output.put_line(CHR(10)||'START: Check if this segment is a candidate?');
        if ( v_rec.minimumDist <> v_rec.lineDist2Vertex ) Then
          -- DEBUG dbms_output.put_line(' This segment is NOT to be split just added to return geom');
          If ( v_return_geom is null) Then -- Return current return_geom....
            v_return_geom := &&INSTALL_SCHEMA..T_Geometry(v_rec.line.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);
          Else
            -- Add first segment to existing
            v_return_geom := v_return_geom.ST_Add_Segment(v_rec.line);
          End If;
          continue;
        End If;

        -- Now do the splitting/snapping
        --
        If ( v_rec.line.midCoord is not null ) Then
           -- DEBUG dbms_output.put_line('Compute common centre and radius for circular arc: ' || v_rec.line.ST_AsText(3) );
           -- DEBUG dbms_output.put_line('v_rec.line.midCoord = ' || v_rec.line.midCoord.ST_asText(3));
           -- All calculations assume that the circular arc segment/segment is no larger than a semi-circle.
           --
           v_centre := v_rec.line.ST_FindCircle(); -- Z holds radius
           If ( v_centre.z = -9 ) Then -- Points are collinear and no finite-radius circle through them exists.
               -- DEBUG dbms_output.put_line('v_centre=(' || v_centre.x|| ',' || v_centre.y||','||v_centre.z||')');
               -- get bearing from centre to p_vertex
               -- DEBUG dbms_output.put_line('p_vertex=(' || p_vertex.x|| ',' || p_vertex.y||','||p_vertex.z||')');
               v_bearing   := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_Bearing(p_vertex=>p_vertex,p_projected=>SELF.projected));  -- radians
               -- DEBUG dbms_output.put_line('v_bearing=' || v_bearing);
               -- Snap point is bearing+radius from centre
               -- Can't use sdo_util.point_at_bearing as """"The point geometry must be based on a geodetic coordinate system.""""
               v_arcSnapPoint := v_centre.ST_FromBearingAndDistance(p_bearing=>v_bearing,p_distance=>v_centre.z,p_projected=>SELF.projected);
               -- DEBUG dbms_output.put_line('v_arcSnapPoint=sdo_geometry('||v_arcSnapPoint.ST_AsText(3)||')');
           End If;
        End If;

        -- Need to actually to split the returned segment...
        --
        if ( ( ROUND(v_rec.startDist2Vertex,SELF.dPrecision) = 0 ) OR
             ( ROUND(v_rec.startDist2Vertex,SELF.dPrecision) = ROUND(v_rec.lineDist2Vertex,SELF.dPrecision) ) ) then
           -- DEBUG dbms_output.put_line('Point splits line at the start of the segment');
           If ( v_return_geom is not null) Then -- Return current return_geom....
              v_geometries.EXTEND(1);
              v_geometries(v_geometries.COUNT) := &&INSTALL_SCHEMA..T_GEOMETRY_ROW(v_geometries.COUNT,v_return_geom.geom,SELF.tolerance,SELF.dPrecision,SELF.projected);
           End If;
           -- Create new return geom based on current segment as is start of a new line
           v_return_geom := &&INSTALL_SCHEMA..T_Geometry(v_rec.line.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);
        elsif ( ROUND(v_rec.midDist2Vertex,SELF.dPrecision) = 0 ) OR
              ( ROUND(v_rec.midDist2Vertex,SELF.dPrecision) = ROUND(v_rec.lineDist2Vertex,SELF.dPrecision) ) Then
           -- DEBUG dbms_output.put_line('Point Splits line at the mid point of the circular arc.');
           -- DEBUG dbms_output.put_line('Create circular arc to hold from start to split point (mid)');
           v_segment := &&INSTALL_SCHEMA..T_Segment(
                             p_element_id    => v_rec.line.element_id,
                             p_subelement_id => v_rec.line.subelement_id,
                             p_Segment_id    => v_rec.line.segment_id,
                             p_startCoord    => v_rec.line.startCoord,
                             p_midCoord      => v_centre.ST_FromBearingAndDistance(v_bearing - ABS(v_arcAngle2SnapPt / 2.0),v_centre.z,p_projected=>SELF.projected),
                             p_endCoord      => v_arcSnapPoint,
                             p_sdo_gtype     => SELF.geom.sdo_gtype,
                             p_sdo_srid      => SELF.ST_Srid());

           -- Add first half to return geometry
           If ( v_return_geom is null) Then -- Start of new line
              v_return_geom := &&INSTALL_SCHEMA..T_Geometry(v_segment.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);
           Else
              -- Add first segment to existing
              v_return_geom := v_return_geom.ST_Add_Segment(v_segment);
           End If;
           -- Then write out
           v_geometries.EXTEND(1);
           v_geometries(v_geometries.COUNT) := &&INSTALL_SCHEMA..T_GEOMETRY_ROW(v_geometries.COUNT,v_return_geom.geom,SELF.tolerance,SELF.dPrecision,SELF.projected);
           v_return_geom := NULL;

           -- segment two is the circular arc from the mid to the end
           -- Create new return geom based on this circular arc
           v_arcAngle2End := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_arcSnapPoint,v_rec.line.EndCoord));
           v_segment := &&INSTALL_SCHEMA..T_Segment(
                             p_element_id    => v_rec.line.element_id,
                             p_subelement_id => v_rec.line.subelement_id,
                             p_Segment_id    => v_rec.line.segment_id,
                             p_startCoord    => v_arcSnapPoint,
                             p_midCoord      => v_centre.ST_FromBearingAndDistance(v_bearing + ABS(v_arcAngle2End / 2.0),v_centre.z,p_projected=>SELF.projected),
                             p_endCoord      => v_rec.line.endCoord,
                             p_sdo_gtype     => SELF.geom.sdo_gtype,
                             p_sdo_srid      => SELF.ST_Srid());
           v_return_geom := &&INSTALL_SCHEMA..T_Geometry(v_segment.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);
        elsif ( ROUND(v_rec.endDist2Vertex,SELF.dPrecision) = 0 ) OR
              ( ROUND(v_rec.endDist2Vertex,SELF.dPrecision) = ROUND(v_rec.lineDist2Vertex,SELF.dPrecision) ) then
           -- DEBUG dbms_output.put_line('Point splits line at the end of the segment');

           If ( v_return_geom is null) Then -- Start of new line
              v_return_geom := &&INSTALL_SCHEMA..T_Geometry(v_rec.line.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);
           Else
              -- DEBUG dbms_output.put_line('Add segment to existing line');
              -- Add first segment to existing
              v_return_geom := v_return_geom.ST_Add_Segment(v_rec.line);
           End If;
           -- Now write out geometry
           v_geometries.EXTEND(1);
           v_geometries(v_geometries.COUNT) := &&INSTALL_SCHEMA..T_GEOMETRY_ROW(v_geometries.COUNT,v_return_geom.geom,SELF.tolerance,SELF.dPrecision,SELF.projected);
           -- We have no segment to add on to any new geometry so null it out
           v_return_geom := null;
        elsif ( ROUND(v_rec.lineDist2Vertex,SELF.dPrecision) = 0 ) Then
           -- DEBUG dbms_output.put_line('Point is on line or circular arc between start and end of segment');

           if ( v_rec.line.midCoord is not null ) Then
             -- DEBUG dbms_output.put_line('Circular Arc: Point is ON circular arc between start and end of segment');
             -- is length to point < length to midpoint?
             v_arcAngle2SnapPt  := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_rec.line.startCoord,v_arcSnapPoint));
             v_arcLength2SnapPt := ROUND(&&INSTALL_SCHEMA..COGO.ComputeArcLength(v_centre.z ,v_arcAngle2SnapPt),SELF.dPrecision);
             v_arcAngle2Mid     := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_rec.line.startCoord,v_rec.line.midCoord));
             v_arcLength2Mid    := ROUND(&&INSTALL_SCHEMA..COGO.ComputeArcLength(v_centre.z ,v_arcAngle2Mid),SELF.dPrecision);
             -- DEBUG dbms_output.put_line('&&INSTALL_SCHEMA..COGO.ST_Degrees(v_arcAngle2SnapPt)=' || v_arcAngle2SnapPt || ' v_arcLength2SnapPt= ' || v_arcLength2SnapPt);
             -- DEBUG dbms_output.put_line('&&INSTALL_SCHEMA..COGO.ST_Degrees(v_arcAngle2Mid)   =' || v_arcAngle2Mid    || ' v_arcLength2Mid   = ' || v_arcLength2Mid );
              if (ABS(v_arcLength2SnapPt) < ABS(v_arcLength2Mid) ) Then
                -- DEBUG dbms_output.put_line('Circular Arc: length to point IS < length to midpoint?');
                -- Vertices that define:
                -- First circular arc are Start/New/Mid
                -- Second circular arc are Snap/Mid/End

                -- Need to calculate a point on the curve between start point and snap point
                v_segment := &&INSTALL_SCHEMA..T_Segment(
                                 p_element_id    => v_rec.line.element_id,
                                 p_subelement_id => v_rec.line.subelement_id,
                                 p_Segment_id    => v_rec.line.segment_id,
                                 p_startCoord    => v_rec.line.startCoord,
                                 p_midCoord      => v_centre.ST_FromBearingAndDistance(v_bearing - ABS(v_arcAngle2SnapPt / 2.0),v_centre.z,p_projected=>SELF.projected),
                                 p_endCoord      => v_rec.line.midCoord,
                                 p_sdo_gtype     => SELF.geom.sdo_gtype,
                                 p_sdo_srid      => SELF.ST_Srid());

                -- DEBUG dbms_output.put('  Add this first half to ...');
                If ( v_return_geom is null) Then
                   -- DEBUG dbms_output.put_line(' Start of new line');
                   v_return_geom := &&INSTALL_SCHEMA..T_Geometry(v_segment.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);
                Else
                   -- DEBUG dbms_output.put_line(' Existing geometry');
                   v_return_geom := v_return_geom.ST_Add_Segment(v_segment);
                End If;
                -- DEBUG dbms_output.put_line(' Write Out Geometry');
                v_geometries.EXTEND(1);
                v_geometries(v_geometries.COUNT) := &&INSTALL_SCHEMA..T_GEOMETRY_ROW(v_geometries.COUNT,v_return_geom.geom,SELF.tolerance,SELF.dPrecision,SELF.projected);
                v_return_geom := NULL;

                -- Now create second circular arc and add it to a new return geometry
                v_segment := &&INSTALL_SCHEMA..T_Segment(
                                  p_element_id    => v_rec.line.element_id,
                                  p_subelement_id => v_rec.line.subelement_id,
                                  p_Segment_id     => v_rec.line.segment_id,
                                  p_startCoord    => v_arcSnapPoint,
                                  p_midCoord      => v_rec.line.midCoord,
                                  p_endCoord      => v_rec.line.endCoord,
                                  p_sdo_gtype     => SELF.geom.sdo_gtype,
                                  p_sdo_srid      => SELF.ST_Srid());
                v_return_geom := &&INSTALL_SCHEMA..T_Geometry(v_segment.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);

              ElsIf ( ROUND(v_arcLength2SnapPt,SELF.dPrecision) = ROUND(v_arcLength2Mid,SELF.dPrecision)) Then
                -- DEBUG dbms_output.put_line('Circular arc: length to point IS = length to midpoint?');
                -- Vertices that define:
                -- First circular arc are Start/New/Mid
                -- Second circular arc are Mid/New/End

                -- Need to calculate a point on the curve between start point and snap point
                v_segment := &&INSTALL_SCHEMA..T_Segment(
                                  p_element_id    => v_rec.line.element_id,
                                  p_subelement_id => v_rec.line.subelement_id,
                                  p_Segment_id    => v_rec.line.segment_id,
                                  p_startCoord    => v_rec.line.startCoord,
                                  p_midCoord      => v_centre.ST_FromBearingAndDistance(v_bearing - ABS(v_arcAngle2SnapPt / 2.0),v_centre.z,p_projected=>SELF.projected),
                                  p_endCoord      => v_rec.line.midCoord,
                                  p_sdo_gtype     => SELF.ST_sdo_gtype(),
                                  p_sdo_srid      => SELF.ST_Srid());

                addToGeomList(v_geometries,v_return_geom,v_segment);

                -- Now create second circular arc and add it to a new return geometry
                v_segment := &&INSTALL_SCHEMA..T_Segment(
                                  p_element_id    => v_rec.line.element_id,
                                  p_subelement_id => v_rec.line.subelement_id,
                                  p_Segment_id    => v_rec.line.segment_id,
                                  p_startCoord    => v_rec.line.midCoord,
                                  p_midCoord      => v_centre.ST_FromBearingAndDistance(v_bearing + ABS(v_arcAngle2SnapPt / 2.0),v_centre.z,p_projected=>SELF.projected),
                                  p_endCoord      => v_rec.line.endCoord,
                                  p_sdo_gtype     => SELF.ST_sdo_gtype(),
                                  p_sdo_srid      => SELF.ST_Srid());
                v_return_geom := &&INSTALL_SCHEMA..T_Geometry(v_segment.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);

              Else
                -- DEBUG dbms_output.put_line('Circular arc: length to point IS > length to midpoint?');
                -- Vertices that define
                -- First circular arc are Start/Mid/Snap
                -- Second circular arc are SnapPoint/NewPoint/EndPoint

                -- need point on curve between snap point and end point
                v_segment := &&INSTALL_SCHEMA..T_Segment(
                                   p_element_id    => v_rec.line.element_id,
                                   p_subelement_id => v_rec.line.subelement_id,
                                   p_Segment_id     => v_rec.line.segment_id,
                                   p_startCoord    => v_rec.line.startCoord,
                                   p_midCoord      => v_rec.line.midCoord,
                                   p_endCoord      => v_arcSnapPoint,
                                   p_sdo_gtype     => SELF.ST_sdo_gtype(),
                                   p_sdo_srid      => SELF.ST_Srid());

                addToGeomList(v_geometries,v_return_geom,v_segment);

                -- Now create second circular arc and add it to a new return geometry
                v_arcAngle2End := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_arcSnapPoint,v_rec.line.EndCoord));
                v_segment := &&INSTALL_SCHEMA..T_Segment(
                                   p_element_id    => v_rec.line.element_id,
                                   p_subelement_id => v_rec.line.subelement_id,
                                   p_Segment_id    => v_rec.line.segment_id,
                                   p_startCoord    => v_arcSnapPoint,
                                   p_midCoord      => v_centre.ST_FromBearingAndDistance(v_bearing + ABS(v_arcAngle2End / 2.0),v_centre.z,p_projected=>SELF.projected),
                                   p_endCoord      => v_rec.line.endCoord,
                                   p_sdo_gtype     => SELF.ST_sdo_gtype(),
                                   p_sdo_srid      => SELF.ST_Srid());
               -- DEBUG dbms_output.put_line(' Add Second segment (' || v_segment.ST_AsText(SELF.dPrecision)||') to new geom');
                v_return_geom := &&INSTALL_SCHEMA..T_Geometry(v_segment.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);

              End If;

           Else
               -- DEBUG dbms_output.put_line('Ordinary linestring: Point is ON segment between start and end point');
               -- Even if p_vertex has measure z/w it can't be assumed to be same as linestring so we recompute base on distances
               v_ratio := v_rec.startDist2Vertex / (v_rec.startDist2Vertex+v_rec.endDist2Vertex);
               -- DEBUG dbms_output.put_line('V_Ratio is: ' || v_ratio); dbms_output.put_line('    v_rec.line: ' || v_rec.line.ST_AsText(SELF.dPrecision));
               v_vertex.x := ROUND(v_rec.line.startCoord.x+((v_rec.line.endCoord.x-v_rec.line.startCoord.x)*v_ratio),SELF.dPrecision);
               -- DEBUG dbms_output.put_line('New X Point is: ' || v_vertex.x);
               v_vertex.y := ROUND(v_rec.line.startCoord.y+((v_rec.line.endCoord.y-v_rec.line.startCoord.y)*v_ratio),SELF.dPrecision);
               If (v_rec.line.startCoord.z is not null ) then -- SELF.ST_Lrs_Dim()=3) Then
                 v_vertex.z := v_rec.line.startCoord.z+(v_rec.line.endCoord.z-v_rec.line.startCoord.z)*v_ratio;
               ElsIf (v_rec.line.startCoord.w is not null ) then -- SELF.ST_Lrs_Dim()=3) Then
                  v_vertex.w := v_rec.line.startCoord.w+(v_rec.line.endCoord.w-v_rec.line.startCoord.w)*v_ratio;
               End If;
               -- DEBUG dbms_output.put_line('   Intersecting Vertex: ' || v_vertex.ST_AsText(SELF.dPrecision));
               v_segment := &&INSTALL_SCHEMA..T_Segment(
                                   p_element_id    => v_rec.line.element_id,
                                   p_subelement_id => v_rec.line.subelement_id,
                                   p_Segment_id     => v_rec.line.segment_id,
                                   p_startCoord    => v_rec.line.startCoord,
                                   p_endCoord      => v_vertex,
                                   p_sdo_gtype     => SELF.ST_sdo_gtype(),
                                   p_sdo_srid      => SELF.ST_Srid());
               -- DEBUG dbms_output.put_line('    First segment: ' || v_segment.ST_AsText(SELF.dPrecision));

                addToGeomList(v_geometries,v_return_geom,v_segment);

                -- Set up second half
                v_segment := &&INSTALL_SCHEMA..T_Segment(
                                   p_element_id    => v_rec.line.element_id,
                                   p_subelement_id => v_rec.line.subelement_id,
                                   p_Segment_id     => v_rec.line.segment_id,
                                   p_startCoord    => v_vertex,
                                   p_endCoord      => v_rec.line.endCoord,
                                   p_sdo_gtype     => SELF.ST_sdo_gtype(),
                                   p_sdo_srid      => SELF.ST_Srid());
               -- DEBUG dbms_output.put_line(' Add Second segment (' || v_segment.ST_AsText(SELF.dPrecision)||') to new geom');
                v_return_geom := &&INSTALL_SCHEMA..T_Geometry(v_segment.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);

           End If;
        Else
           -- DEBUG dbms_output.put_line('ELSE');
           If ( v_rec.line.midCoord is not null ) Then
             -- DEBUG dbms_output.put_line('Circular arc: Point is off of a circular arc line');
             -- is length to point < length to midpoint?
             v_arcAngle2SnapPt  := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_rec.line.startCoord,v_arcSnapPoint));
             v_arcLength2SnapPt := ROUND(&&INSTALL_SCHEMA..COGO.ComputeArcLength(v_centre.z ,v_arcAngle2SnapPt),SELF.dPrecision);
             v_arcAngle2Mid     := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_rec.line.startCoord,v_rec.line.midCoord));
             v_arcLength2Mid    := ROUND(&&INSTALL_SCHEMA..COGO.ComputeArcLength(v_centre.z ,v_arcAngle2Mid),SELF.dPrecision);
             -- DEBUG dbms_output.put_line('&&INSTALL_SCHEMA..COGO.ST_Degrees(v_arcAngle2SnapPt)=' || v_arcAngle2SnapPt || ' v_arcLength2SnapPt= ' || v_arcLength2SnapPt );
             -- DEBUG dbms_output.put_line('&&INSTALL_SCHEMA..COGO.ST_Degrees(v_arcAngle2Mid)   =' || v_arcAngle2Mid    || ' v_arcLength2Mid   = ' || v_arcLength2Mid );
             if (ABS(ROUND(v_arcLength2SnapPt,SELF.dPrecision)) < ABS(ROUND(v_arcLength2Mid,SELF.dPrecision)) ) Then
                -- DEBUG dbms_output.put_line('Circular arc: length to snap point IS < length to midpoint');

                -- Vertices that define First circular arc are Start/New/Snap
                -- Need to calculate a point on the curve between start point and snap point
                v_segment := &&INSTALL_SCHEMA..T_Segment(
                                  p_element_id    => v_rec.line.element_id,
                                  p_subelement_id => v_rec.line.subelement_id,
                                  p_Segment_id    => v_rec.line.segment_id,
                                  p_startCoord    => v_rec.line.startCoord,
                                  p_midCoord      => v_centre.ST_FromBearingAndDistance(v_bearing - ABS(v_arcAngle2SnapPt / 2.0),v_centre.z,p_projected=>SELF.projected),
                                  p_endCoord      => v_arcSnapPoint,
                                  p_sdo_gtype     => SELF.ST_sdo_gtype(),
                                  p_sdo_srid      => SELF.ST_Srid());

                addToGeomList(v_geometries,v_return_geom,v_segment);

                -- Vertices that define Second circular arc are Snap/Mid/End
                v_segment := &&INSTALL_SCHEMA..T_Segment(
                                  p_element_id    => v_rec.line.element_id,
                                  p_subelement_id => v_rec.line.subelement_id,
                                  p_Segment_id     => v_rec.line.segment_id,
                                  p_startCoord    => v_arcSnapPoint,
                                  p_midCoord      => v_rec.line.midCoord,
                                  p_endCoord      => v_rec.line.endCoord,
                                  p_sdo_gtype     => SELF.ST_sdo_gtype(),
                                  p_sdo_srid      => SELF.ST_Srid());
               -- DEBUG dbms_output.put_line(' Add Second segment (' || v_segment.ST_AsText(SELF.dPrecision)||') to new geom');
                v_return_geom := &&INSTALL_SCHEMA..T_Geometry(v_segment.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);
              Else
                -- DEBUG dbms_output.put_line('circular arc: length to snap point IS > length to midpoint');
                -- Vertices that define
                -- First circular arc are Start/Mid/Snap

                -- need point on curve between snap point and end point
                v_arcAngle2End := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_arcSnapPoint,v_rec.line.EndCoord));
                v_segment := &&INSTALL_SCHEMA..T_Segment(
                                   p_element_id    => v_rec.line.element_id,
                                   p_subelement_id => v_rec.line.subelement_id,
                                   p_Segment_id     => v_rec.line.segment_id,
                                   p_startCoord    => v_rec.line.startCoord,
                                   p_midCoord      => v_rec.line.midCoord,
                                   p_endCoord      => v_arcSnapPoint,
                                   p_sdo_gtype     => SELF.st_sdo_gtype(),
                                   p_sdo_srid      => SELF.ST_Srid());

                addToGeomList(v_geometries,v_return_geom,v_segment);

                -- Second circular arc are SnapPoint/NewPoint/EndPoint
                v_segment := &&INSTALL_SCHEMA..T_Segment(
                                   p_element_id    => v_rec.line.element_id,
                                   p_subelement_id => v_rec.line.subelement_id,
                                   p_Segment_id    => v_rec.line.segment_id,
                                   p_startCoord    => v_arcSnapPoint,
                                   p_midCoord      => v_centre.ST_FromBearingAndDistance(v_bearing + ABS(v_arcAngle2End / 2.0),v_centre.z,p_projected=>SELF.projected),
                                   p_endCoord      => v_rec.line.endCoord,
                                   p_sdo_gtype     => SELF.st_sdo_gtype(),
                                   p_sdo_srid      => SELF.ST_Srid());
                -- DEBUG dbms_output.put_line('Create new geometry from second half of the segment');
                v_return_geom := &&INSTALL_SCHEMA..T_Geometry(v_segment.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);

              End If;
           Else
             -- DEBUG dbms_output.put_line('Ordinary linestring: point is off a straight line but between first and last vertex so split point is ratio of start/end distances');
             v_ratio := /* distance start to drop point / total length of segment */
                      SQRT(POWER(v_rec.startDist2Vertex,2) -
                           POWER(v_rec.lineDist2Vertex,2)) /
                      v_rec.line.ST_Length(p_unit=>p_unit);
             -- DEBUG dbms_output.put_line('distance start to drop point: ' || SQRT(POWER(v_rec.startDist,2)-POWER(v_rec.lineDist,2)));
             -- DEBUG dbms_output.put_line('total length of segment: ' || v_rec.line.ST_Length(SELF.tolerance,p_unit));
             -- DEBUG dbms_output.put_line('V_Ratio is: ' || v_ratio);
             v_vertex.x := ROUND(v_rec.line.startCoord.x+((v_rec.line.endCoord.x-v_rec.line.startCoord.x)*v_ratio),SELF.dPrecision);
             -- DEBUG dbms_output.put_line('New X Point is: ' || v_vertex.x);
             v_vertex.y := ROUND(v_rec.line.startCoord.y+((v_rec.line.endCoord.y-v_rec.line.startCoord.y)*v_ratio),SELF.dPrecision);
             if (SELF.ST_Lrs_Dim()<>0) Then
                -- Even if p_vertex has measure z/w it can't be assumed to be same as linestring so we recompute base on distances
                v_ratio := v_rec.startDist2Vertex / (v_rec.startDist2Vertex+v_rec.endDist2Vertex);
                If (SELF.ST_Lrs_Dim()=3) Then
                   v_vertex.z := v_rec.line.startCoord.z+(v_rec.line.endCoord.z-v_rec.line.startCoord.z)*v_ratio;
                Else
                   v_vertex.w := v_rec.line.startCoord.w+(v_rec.line.endCoord.w-v_rec.line.startCoord.w)*v_ratio;
                End If;
             End If;
             v_vertex.id := 2;
             -- DEBUG dbms_output.put_line('Writing out segments split by computed v_vertex = ' || v_vertex.ST_AsText(3));
             v_segment := &&INSTALL_SCHEMA..T_Segment(
                                   p_element_id    => v_rec.line.element_id,
                                   p_subelement_id => v_rec.line.subelement_id,
                                   p_Segment_id     => v_rec.line.segment_id,
                                   p_startCoord    => v_rec.line.startCoord,
                                   p_endCoord      => v_vertex,
                                   p_sdo_gtype     => SELF.st_sdo_gtype(),
                                   p_sdo_srid      => SELF.ST_Srid());

             -- DEBUG dbms_output.put_line('v_segment=' || v_segment.ST_AsText(3));
             addToGeomList(v_geometries,v_return_geom,v_segment);

             v_segment := &&INSTALL_SCHEMA..T_Segment(
                                   p_element_id    => v_rec.line.element_id,
                                   p_subelement_id => v_rec.line.subelement_id,
                                   p_Segment_id     => v_rec.line.segment_id,
                                   p_startCoord    => v_vertex,
                                   p_endCoord      => v_rec.line.endCoord,
                                   p_sdo_gtype     => SELF.st_sdo_gtype(),
                                   p_sdo_srid      => SELF.ST_Srid());
             -- DEBUG dbms_output.put_line('v_segment=' || v_segment.ST_AsText(3));
             -- Create new geometry from second half of the segment
             v_return_geom := &&INSTALL_SCHEMA..T_Geometry(v_segment.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);
           End If;
        End If;
        -- DEBUG dbms_output.put_line('END LOOP');
    END LOOP process_nearest_Segments;
    IF ( v_return_geom is not null ) Then
       v_geometries.EXTEND(1);
       v_geometries(v_geometries.COUNT) := &&INSTALL_SCHEMA..T_GEOMETRY_ROW(v_geometries.COUNT,v_return_geom.geom,SELF.tolerance,SELF.dPrecision,SELF.projected);
    End If;
    -- DEBUG dbms_output.put_line('</ST_Split>');
    return v_geometries;
  End ST_Split;

  /** ----------------------------------------------------------------------------------------
  * @function   : ST_Split
  * @precis     : A Function that splits a line geometry at a known point
  * @version    : 1.2
  * @description: This procedure will split a linestring or multi-linestring mdsys.sdo_geometry object
  *               at a supplied (known) point. Normally the point should lie on the linestring at
  *               a vertex or between two vertices but the algorithm used will split a line even if
  *               the point does not lie on the line. Where the point does not lie on the linestring
  *               the algorithm approximates the nearest point on the linestring to the supplied point
  *               and splits it there. The algorithm supports the situation where a point may split the line
  *               at more than one point. The algorithm being ratio based will not necessarily be accurate
  *               for geodetic data. Circular arcs are supported.
  * @usage      : Function ST_Split(p_vertex in T_Vertex,
  *                                 p_unit   in varchar2 default null)
  *                 &&INSTALL_SCHEMA..T_GEOMETRIES Pipelined
  * @param      : p_vertex    : T_Vertex .vertex_type : The vertex describing the point for splitting the linestring.
  * @return     : mdsys.sdo_geometry: One or more linestrings
  * @history    : Simon Greener - Jan 2008 - Original coding.
  * @history    : Simon Greener - Nov 2012 - Recoded for including in T_GEOMETRY type
  * @copyright  : Simon Greener, 2008, 2009, 2010, 2012
  * @License    : Creative Commons Attribution-Share Alike 2.5 Australia License.
  **/
  -- Wrapper
  Member Function ST_Split(p_point in mdsys.sdo_geometry,
                           p_unit  in varchar2 DEFAULT null)
           Return &&INSTALL_SCHEMA..T_GEOMETRIES
  As
    c_i_not_geom CONSTANT INTEGER       := -20121;
    c_s_not_geom CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
  Begin
    -- Only makes sense to split a linestring with a point
    If ( p_point.get_gtype() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(C_S_NOT_GEOM,
                                         '*GTYPE1*',mdsys.ST_GEOMETRY(p_point).ST_GeometryType()),
                                         '*GTYPE2*','Point'),TRUE);
    End If;
    Return SELF.ST_SPLIT(P_VERTEX => &&INSTALL_SCHEMA..T_VERTEX(p_point => p_point),
                         P_UNIT   => P_UNIT);
  End ST_Split;

  -- Wrapper
  Member Function ST_Split(p_measure in number,
                           p_unit    in varchar2 DEFAULT null)
           Return &&INSTALL_SCHEMA..T_GEOMETRIES
  As
    c_i_null_measure CONSTANT INTEGER       := -20120;
    c_s_null_measure CONSTANT VARCHAR2(100) := 'Measure must not be null';
    v_vertex         &&INSTALL_SCHEMA..t_Vertex;
    v_geom           mdsys.sdo_geometry;
    v_geometries     &&INSTALL_SCHEMA..T_Geometries := &&INSTALL_SCHEMA..T_Geometries(&&INSTALL_SCHEMA..T_GEOMETRY_ROW(0,NULL,SELF.tolerance,SELF.dPrecision,SELF.projected));
  Begin
    if ( p_measure is null ) Then
       raise_application_error(c_i_null_measure,
                               c_s_null_measure,TRUE);
    End If;
    If ( p_measure not between SELF.ST_LRS_Start_Measure() 
                           and SELF.ST_LRS_End_Measure(p_unit) ) Then
       Return null;
    End If;
    v_geometries.DELETE;
    v_geometries.EXTEND(2);
    v_geometries(1) := &&INSTALL_SCHEMA..T_GEOMETRY_ROW(
                         1,
                         SELF.ST_LRS_Locate_Measures(
                             p_start_measure => 0.0,
                             p_end_measure   => p_measure,
                             p_offset        => 0.0,
                             p_unit          => p_unit).geom,
                         SELF.tolerance,SELF.dPrecision,SELF.projected
                       );
    v_geometries(2) := &&INSTALL_SCHEMA..T_GEOMETRY_ROW(
                         2,
                         SELF.ST_LRS_Locate_Measures(
                             p_start_measure => p_measure,
                             p_end_measure   => SELF.ST_LRS_End_Measure(p_unit),
                             p_offset        => 0.0,
                             p_unit          => p_unit).geom,
                         SELF.tolerance,SELF.dPrecision,SELF.projected
                       );
                             
   return v_geometries;
  End ST_Split;

  Member Function ST_Snap(p_point in mdsys.sdo_geometry,
                          p_unit  in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_geometries
  Is
    c_i_not_geom       CONSTANT INTEGER       := -20121;
    c_s_not_geom       CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance CONSTANT INTEGER       := -20122;
    c_s_null_tolerance CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';

    v_ratio            number;
    v_bearing          number;
    v_segments         &&INSTALL_SCHEMA..T_Segments:= &&INSTALL_SCHEMA..T_Segments();
    v_point            &&INSTALL_SCHEMA..T_Vertex  := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(), p_sdo_srid  => SELF.ST_SRID());
    v_centre           &&INSTALL_SCHEMA..T_Vertex  := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(), p_sdo_srid  => SELF.ST_SRID());
    v_vertex           &&INSTALL_SCHEMA..T_Vertex  := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(), p_sdo_srid  => SELF.ST_SRID());
    v_snap_vertex      &&INSTALL_SCHEMA..T_Vertex  := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(), p_sdo_srid  => SELF.ST_SRID());
    v_prev_vertex      &&INSTALL_SCHEMA..T_Vertex  := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(), p_sdo_srid  => SELF.ST_SRID());
    v_geometries       &&INSTALL_SCHEMA..T_GEOMETRIES;
    v_geom             &&INSTALL_SCHEMA..T_GEOMETRY;
    v_distance         NUMBER;
    v_found_measure    NUMBER;
  Begin
    -- Only makes sense to snap a point to a linestring
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_geometryType()),
                                         '*GTYPE2*','Linestring'),TRUE);
    End If;
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;

    -- DEBUG dbms_output.put_line('<ST_SNAP ST_DB_Version='||TOOLS.ST_DB_Version||' ST_Lrs_Dim=' || SELF.ST_Lrs_Dim()||'>');

    -- Check inputs: constructor also validates
    -- DEBUG dbms_output.put_line(' p_point: ' || &&INSTALL_SCHEMA..PRINT.sdo_geometry(p_point,SELF.dPrecision));
    v_point      := &&INSTALL_SCHEMA..T_Vertex(p_point => p_point); -- sets gtype and srid from p_point
    -- DEBUG dbms_output.put_line('Point being moved is: ' || v_point.ST_AsText(3));
    v_geometries := new &&INSTALL_SCHEMA..T_GEOMETRIES(NULL);
    v_geometries.DELETE;

    -- SDO_CLOSEST_POINTS does not return measure.
    -- Snaps 2D to 2D or 3D (Z) to 3D(Z)
    -- If try snapping Measured Point to measured Line function treats M as Z.
    --
    If (&&INSTALL_SCHEMA..TOOLS.ST_DB_Version() >= 11.1
        AND
        SELF.ST_hasCircularArcs()=0 ) Then
      -- DEBUG dbms_output.put_line(' Using Short Circuited segment Code');

      v_vertex  := &&INSTALL_SCHEMA..T_Vertex(p_point);
      v_segments := SELF.ST_Segmentize(p_filter => 'DISTANCE',
                                       p_vertex => v_vertex,
                                       p_unit   => p_unit);
      IF ( v_segments IS NOT NULL and v_segments.COUNT > 0 ) THEN
        -- DEBUG dbms_output.put_line('  v_segment.COUNT='||v_segments.COUNT);
        FOR rec in 1 .. v_segments.COUNT LOOP
          -- DEBUG dbms_output.put_line('  v_segment(rec)= ' || v_segments(rec).ST_AsText());
          v_snap_vertex := v_segments(rec)
                            .ST_ProjectPoint(p_vertex => v_Vertex,
                                        p_unit      => p_unit );
          -- Project Point sets measure.
          IF ( SELF.ST_Dims() = 2 ) Then
            v_snap_vertex := v_snap_vertex.ST_To2D(); -- remove it
          ElsIf ( SELF.ST_LRS_IsMeasured()=0 ) Then
            v_snap_vertex := v_snap_vertex.ST_To3D(p_keep_measure => 0, 
                                                   p_default_z    => NULL);
          END IF;
          v_geometries.EXTEND(1);
          v_geometries(v_geometries.count) := &&INSTALL_SCHEMA..T_GEOMETRY_ROW(rec,v_snap_vertex.ST_SdoGeometry(),self.tolerance,SELF.dPrecision,SELF.projected);
        END LOOP;
        IF ( ( v_geometries.COUNT <> 0 ) ) THEN
          -- DEBUG dbms_output.put_line('</ST_SNAP>' );
          RETURN v_geometries;
        END IF;
        -- Flow through to older code
      END IF;
    END IF;

    -- Find and process nearest segments
    --
    <<process_nearest_Segments>>
    FOR v_rec IN (SELECT g.line,g.startDist,g.midDist,g.endDist,g.lineDist
                    FROM (SELECT f.line,f.startDist,f.midDist,f.endDist,f.lineDist,min(f.lineDist) over (order by 1) as minDist
                            FROM (SELECT seg.ST_Self() as line,
                                         seg.StartCoord.ST_Distance(p_vertex=>v_point,p_tolerance=>SELF.tolerance,p_unit=>p_unit) as startDist,
                                         case when seg.midCoord is not null
                                              then seg.midCoord.ST_Distance(p_vertex=>v_point,p_tolerance=>SELF.tolerance,p_unit=>p_unit)
                                              else CAST(NULL as number)
                                          end as midDist,
                                         seg.EndCoord.ST_Distance(p_vertex=>v_point,p_tolerance=>SELF.tolerance,p_unit=>p_unit)as endDist,
                                         seg.ST_Distance(p_vertex    => &&INSTALL_SCHEMA..T_Vertex(p_point),
                                                         p_unit      => p_unit)
                                           as linedist
                                   FROM TABLE(SELF.ST_Segmentize(p_filter=>'ALL')) seg
                                  ORDER BY 5 /* linedist */
                                ) f
                         ) g
                   WHERE g.linedist = g.minDist
                     AND g.line is not null
                ORDER by g.line
    )
    LOOP
        -- DEBUG dbms_output.put_line('  Split segment is ' || v_rec.line.ST_AsText(3));
        -- DEBUG dbms_output.put_line('Start Distance is ' || v_rec.startDist);
        -- DEBUG dbms_output.put_line('  Mid Distance is ' || case when v_rec.midDist is not NULL then ''||v_rec.midDist else 'null' end);
        -- DEBUG dbms_output.put_line('  End Distance is ' || v_rec.endDist);
        -- DEBUG dbms_output.put_line(' Line Distance is ' || v_rec.lineDist);

        -- Now do the splitting/snapping
        --
        if ( ROUND(v_rec.startDist,SELF.dPrecision) = 0 )
        OR ( ROUND(v_rec.lineDist,SELF.dPrecision) = ROUND(v_rec.startDist,SELF.dPrecision) ) then
           -- DEBUG dbms_output.put_line('point can only split line at the start of the segment');
           -- DEBUG dbms_output.put_line('startCoord='||v_rec.line.startCoord.ST_AsText(3));
           v_vertex := &&INSTALL_SCHEMA..T_Vertex(p_vertex => v_rec.line.startCoord);
           -- DEBUG dbms_output.put_line('v_vertex='||v_vertex.ST_AsText(3));
        elsif ( ROUND(v_rec.midDist,SELF.dPrecision) = 0 ) Or ( ROUND(v_rec.lineDist,SELF.dPrecision) = ROUND(v_rec.midDist,SELF.dPrecision) ) Then
           -- DEBUG dbms_output.put_line('point Splits line at the mid point of the segment');
           -- DEBUG dbms_output.put_line('midCoord='||v_rec.line.midCoord.ST_AsText(3));
           v_vertex := &&INSTALL_SCHEMA..T_Vertex(p_vertex => v_rec.line.midCoord);
           -- DEBUG dbms_output.put_line('v_vertex='||v_vertex.ST_AsText(3));
        elsif ( ROUND(v_rec.endDist,SELF.dPrecision) = 0 ) Or ( ROUND(v_rec.lineDist,SELF.dPrecision) = ROUND(v_rec.endDist,SELF.dPrecision) ) then
           -- DEBUG dbms_output.put_line('point can only split line at the end of the segment');
           -- DEBUG dbms_output.put_line('endCoord='||v_rec.line.endCoord.ST_AsText(3));
           v_vertex := &&INSTALL_SCHEMA..T_Vertex(p_vertex => v_rec.line.endCoord);
           -- DEBUG dbms_output.put_line('v_vertex='||v_vertex.ST_AsText(3));
        elsif ( ROUND(v_rec.lineDist,SELF.dPrecision) = 0 ) then
           -- DEBUG dbms_output.put_line('point is on line/circular arc between start and end of segment');
           if ( v_rec.line.midCoord is not null ) Then
             -- DEBUG dbms_output.put_line('is three vertex circular arc');
             -- DEBUG dbms_output.put_line('v_rec.line.midCoord.x is ' || (case when v_rec.line.midCoord is not null and v_rec.line.midCoord.x is not null then 'NOT ' else '' end) ||'NULL');
             -- Compute centre and radius
             -- All calculations assume that the circular arc segment/segment is no larger than a semi-circle.
             --
             v_centre := v_rec.line.ST_FindCircle(); -- z holds radius
             -- DEBUG dbms_output.put_line('v_centre=(' || v_centre.x|| ',' || v_centre.y||','||v_centre.z||')');
             -- get bearing from centre to p_point
             v_vertex    := &&INSTALL_SCHEMA..T_vertex(p_point => p_point);
             -- DEBUG dbms_output.put_line('v_vertex='||v_vertex.ST_AsText(3));
             v_bearing   := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_Bearing(v_vertex,p_projected=>SELF.projected));  -- radians
             -- DEBUG dbms_output.put('ST_Azimuth bearing = ' || v_bearing);
             -- DEBUG dbms_output.put_line('v_bearing=' || v_bearing);
             -- Snap point is bearing+radius from centre
             -- Can't use sdo_util.point_at_bearing as """"The point geometry must be based on a geodetic coordinate system.""""
             v_vertex := v_centre.ST_FromBearingAndDistance(v_bearing,v_centre.z,p_projected=>SELF.projected);
             -- DEBUG dbms_output.put_line('v_vertex=(' || v_vertex.ST_AsText(SELF.dPrecision) || ')');
             -- DEBUG dbms_output.put_line('Between two end points');
             -- Compute Z/W values based on ratios of arcs if needed
             v_ratio    := v_rec.startDist / ( v_rec.startDist + v_rec.endDist );
             if (SELF.ST_Dims()>2) Then
                 v_vertex.sdo_gtype := TRUNC(SELF.geom.sdo_gtype/10)*10 + 1;
                 v_vertex.z := v_rec.line.startCoord.z+(v_rec.line.endCoord.z-v_rec.line.startCoord.z)*v_ratio;
                 if (SELF.ST_Dims()>3) Then
                    v_vertex.w := v_rec.line.startCoord.w+(v_rec.line.endCoord.w-v_rec.line.startCoord.w)*v_ratio;
                 End If;
             End If;
          Else
             -- DEBUG dbms_output.put_line('is ordinary two point segment');
             v_vertex := new &&INSTALL_SCHEMA..t_vertex(p_vertex => v_point);
             -- DEBUG dbms_output.put_line('v_vertex='||v_vertex.ST_AsText(3) || ' v_vertex.sdo_gtype='||v_vertex.sdo_gtype);
             -- Compute Z and M if needed
             v_ratio    := v_rec.startDist / ( v_rec.startDist + v_rec.endDist );
             -- DEBUG dbms_output.put_line('SELF.ST_Dims()='||SELF.ST_Dims() || ' gtype='||SELF.geom.sdo_gtype);
             if (SELF.ST_Dims()>2) Then
                 v_vertex.sdo_gtype := TRUNC(SELF.geom.sdo_gtype/10)*10 + 1;
                 v_vertex.z := v_rec.line.startCoord.z+(v_rec.line.endCoord.z-v_rec.line.startCoord.z)*v_ratio;
                 if (SELF.ST_Dims()>3) Then
                    v_vertex.w := v_rec.line.startCoord.w+(v_rec.line.endCoord.w-v_rec.line.startCoord.w)*v_ratio;
                 End If;
             End If;
           End If;
           -- DEBUG dbms_output.put_line(' between start and end: Computed v_vertex='||v_vertex.ST_AsText(3));
        elsif ( v_rec.line.midCoord is not null ) Then
           -- DEBUG dbms_output.put_line('v_rec.line.midCoord.x is ' || (case when v_rec.line.midCoord is not null and v_rec.line.midCoord.x is not null then 'NOT ' else '' end) ||'NULL');
           -- Compute centre and radius
           -- All calculations assume that the circular arc segment/segment is no larger than a semi-circle.
           --
           v_centre := v_rec.line.ST_FindCircle(); -- id holds radius
           -- DEBUG dbms_output.put_line('v_centre=(' || v_centre.x|| ',' || v_centre.y||','||v_centre.z||')');
           -- get bearing from centre to p_point
           v_vertex    := &&INSTALL_SCHEMA..T_vertex(p_point => p_point);
           -- DEBUG dbms_output.put_line('v_vertex='||v_vertex.ST_AsText(3));
           v_bearing   := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_Bearing(p_vertex=>v_vertex,p_projected=>SELF.projected));  -- radians
           -- DEBUG dbms_output.put('ST_Azimuth bearing = ' || v_bearing);
           -- Snap point is bearing+radius from centre
           -- Can't use sdo_util.point_at_bearing as """"The point geometry must be based on a geodetic coordinate system.""""
           v_vertex := v_centre.ST_FromBearingAndDistance(v_bearing,v_centre.z,SELF.projected);
           -- DEBUG dbms_output.put_line('v_vertex=(' || v_vertex.ST_AsText(SELF.dPrecision) || ')');
           -- DEBUG dbms_output.put_line('Between two end points');
           -- Compute Z/W values based on ratios of arcs if needed
           v_ratio    := v_rec.startDist / ( v_rec.startDist + v_rec.endDist );
           if (SELF.ST_Dims()>2) Then
               v_vertex.sdo_gtype := TRUNC(SELF.geom.sdo_gtype/10)*10 + 1;
               v_vertex.z := v_rec.line.startCoord.z+(v_rec.line.endCoord.z-v_rec.line.startCoord.z)*v_ratio;
               if (SELF.ST_Dims()>3) Then
                  v_vertex.w := v_rec.line.startCoord.w+(v_rec.line.endCoord.w-v_rec.line.startCoord.w)*v_ratio;
               End If;
           End If;
        else
           -- DEBUG dbms_output.put_line('point is between first and last vertex so split point is ratio of start/end distances  - Line Dims='||SELF.ST_Dims() || ' Point Dims=' || v_point.ST_dims());
           -- DEBUG dbms_output.put_line('v_rec.line=' || v_rec.line.ST_AsText(3) || '.ST_Length('||SELF.tolerance||','||p_unit||') = ' || v_rec.line.ST_Length(SELF.tolerance,p_unit));
           v_ratio := /* distance start to drop point / total length of segment */
                      SQRT(POWER(v_rec.startDist,2) -
                           POWER(v_rec.lineDist,2)) /
                      v_rec.line.ST_Length(p_unit=>p_unit);
           -- DEBUG dbms_output.put_line('distance start to drop point: ' || SQRT(POWER(v_rec.startDist,2)+POWER(v_rec.lineDist,2)));
           -- DEBUG dbms_output.put_line('total length of segment: ' || v_rec.line.ST_Length(SELF.tolerance,p_unit));
           -- DEBUG dbms_output.put_line('V_Ratio is: ' || v_ratio);
           v_vertex.x := ROUND(v_rec.line.startCoord.x+((v_rec.line.endCoord.x-v_rec.line.startCoord.x)*v_ratio),SELF.dPrecision);
           -- DEBUG dbms_output.put_line('New X Point is: ' || v_vertex.x);
           -- v_ratio    := ABS(v_point.y-v_rec.line.startCoord.y)/(ABS(v_rec.line.endCoord.y-v_point.y)+ABS(v_point.y-v_rec.line.startCoord.y));
           v_vertex.y := ROUND(v_rec.line.startCoord.y+((v_rec.line.endCoord.y-v_rec.line.startCoord.y)*v_ratio),SELF.dPrecision);
           -- DEBUG dbms_output.put_line('New Y Point is: ' || v_vertex.y);
           If (SELF.ST_Dims()>2) Then
               -- DEBUG dbms_output.put_line('v_rec.line='||v_rec.line.ST_AsText());
               -- DEBUG dbms_output.put_line('v_point='||v_point.ST_AsText(3));
               /* v_ratio := ABS(v_point.z-v_rec.line.startCoord.z)
                        /(ABS(v_rec.line.endCoord.z-                v_point.z)
                         +ABS(              v_point.z-v_rec.line.startCoord.z));
               */
               v_vertex.sdo_gtype := TRUNC(SELF.geom.sdo_gtype/10)*10 + 1;
               v_vertex.z := ROUND(v_rec.line.startCoord.z+((v_rec.line.endCoord.z-v_rec.line.startCoord.z)*v_ratio),SELF.dPrecision);
               -- DEBUG dbms_output.put_line('New Z Point is: ' || v_vertex.z);
               if (SELF.ST_Dims()>3) Then
                  /*v_ratio := ABS(v_point.w-v_rec.line.startCoord.w)
                           /(ABS(v_rec.line.endCoord.w-v_point.w)
                            +ABS(v_point.w-v_rec.line.startCoord.w));
                  */
                  v_vertex.w := v_rec.line.startCoord.w+(v_rec.line.endCoord.w-v_rec.line.startCoord.w)*v_ratio;
               End If;
           End If;
           -- DEBUG dbms_output.put_line('calculated point on straight line='||v_vertex.ST_AsText(3));
        End If;
        -- DEBUG dbms_output.put_line('ST_Snap: Checking equals');
        if ( v_vertex.ST_Equals(v_prev_vertex,SELF.dPrecision)=0 ) Then
           -- DEBUG dbms_output.put_line('ST_Snap: ... is NOT equal to v_prev_Vertex so add v_vertex to v_geometries');
           -- DEBUG dbms_output.put_line('  v_vertex.ST_Dims()=' || v_vertex.ST_Dims());
           -- DEBUG dbms_output.put_line('  v_vertex.z=' || v_vertex.z);
           v_geometries.EXTEND(1);
           -- DEBUG dbms_output.put_line('  v_geometries.COUNT=' || v_geometries.COUNT);
           v_geometries(v_geometries.COUNT) := &&INSTALL_SCHEMA..T_GEOMETRY_ROW(v_geometries.COUNT,v_vertex.ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);
           -- DEBUG dbms_output.put_line('v_geometries(COUNT)='||&&INSTALL_SCHEMA..PRINT.sdo_geometry(v_geometries(v_geometries.count).GEOMETRY,SELF.dPrecision));
           v_prev_vertex := &&INSTALL_SCHEMA..T_Vertex(p_vertex => v_vertex);
        End If;
    End Loop process_nearest_Segments;
    -- DEBUG dbms_output.put_line('</ST_SNAP>' );
    return v_geometries;
  end ST_Snap;

  Member Function ST_SnapN(p_point in mdsys.sdo_geometry,
                           p_id    in integer,
                           p_unit  in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    v_geometries &&INSTALL_SCHEMA..T_GEOMETRIES;
    v_point      mdsys.sdo_geometry;
    v_id         pls_integer;
  Begin
    v_geometries := SELF.ST_Snap(p_point,p_unit);
    if ( v_geometries is null
      or v_geometries.COUNT=0 ) Then
       Return null;
    end If;
    v_id := case when p_id = -1 or p_id > v_geometries.COUNT
                 then v_geometries.COUNT
                 when p_id is null or p_id <= 0
                 then 1
                 else p_id
            end;
    Return &&INSTALL_SCHEMA..T_GEOMETRY(v_geometries(v_id).geometry,SELF.tolerance,SELF.dPrecision,SELF.projected);
  End ST_SnapN;

  /* ************************************************************************/
  /* Conversion functions eg Point Encoding, Dimensionality 2D, 3D and Text */
  /* ************************************************************************/

  Member Function ST_Ord2SdoPoint
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  IS
     vGeometry  MDSYS.SDO_Geometry;
     vSdoPoint  MDSYS.SDO_Point_Type := MDSYS.SDO_Point_Type(0,0,NULL);
     vOrdinates MDSYS.SDO_Ordinate_Array;
     vSdoGType  pls_integer;
  Begin
    IF ( SELF.ST_Dimension() != 0 /*Point*/) Then
      vGeometry := SELF.geom;
    ELSIF ( SELF.geom.sdo_elem_info is null ) THEN
      vGeometry := SELF.geom;
    ELSE /* SELF.geom.sdo_point is removed as elem_info is not null */
      vSdoGtype   := SELF.ST_Sdo_GType();
      vSdoPoint.X := SELF.geom.sdo_ordinates(1);
      vSdoPoint.Y := SELF.geom.sdo_ordinates(2);
      vSdoPoint.Z := case when SELF.ST_Dims() = 2                                then NULL
                          when SELF.ST_Dims() = 3 and SELF.ST_Lrs_Dim() IN (0,3) then SELF.geom.sdo_ordinates(3)
                          when SELF.ST_Dims() = 4 and SELF.ST_Lrs_Dim() IN (0,3) then SELF.geom.sdo_ordinates(3)
                          when SELF.ST_Dims() = 4 and SELF.ST_Lrs_Dim() = 4      then SELF.geom.sdo_ordinates(4)
                        end;
      vSdoGType := case when SELF.ST_Dims() = 2
                        then 2001
                        else (case when SELF.ST_LRS_Dim() in (3,4)
                                   then 3301
                                   else 3001
                              end)
                    end;
      vGeometry := mdsys.sdo_geometry(vSdoGType,SELF.ST_Srid(),vSdoPoint,NULL,NULL);
    END IF;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(vGeometry,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  END ST_Ord2SdoPoint;

  Member Function ST_SdoPoint2Ord
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  IS
     vGeometry  MDSYS.SDO_Geometry;
     vOrdinates MDSYS.SDO_Ordinate_Array;
     vSdoGtype  pls_integer;
  Begin
    IF ( SELF.ST_Dimension() != 0 /*Point*/) Then
      vGeometry := SELF.geom;
    ELSIF ( SELF.geom.sdo_point is null ) THEN
      vGeometry := SELF.geom;
    ELSIF ( SELF.geom.sdo_elem_info is not null ) THEN
      -- Wipe out SDO_POINT data and return geometry
      vGeometry := mdsys.sdo_geometry(SELF.ST_Sdo_GType(),SELF.ST_Srid(),NULL,SELF.geom.sdo_elem_info,SELF.geom.sdo_ordinates);
    ELSIF ( SELF.geom.sdo_point is not null ) THEN
      vOrdinates  := new mdsys.sdo_ordinate_array(0);
      vOrdinates.DELETE;
      vOrdinates.EXTEND(SELF.ST_Dims());
      vOrdinates(1) := SELF.geom.Sdo_Point.X;
      vOrdinates(2) := SELF.geom.Sdo_Point.Y;
      IF ( SELF.ST_Dims() >= 3 ) THEN
        vOrdinates(3) := SELF.geom.Sdo_Point.Z;
      End If;
      vSdoGtype := 2001 + (case when SELF.ST_LRS_isMeasured()=1 then 1301 else 0 end);
      vGeometry := mdsys.sdo_geometry(
                             vSdoGtype,
                             SELF.ST_Srid(),
                             NULL,
                                      mdsys.sdo_elem_info_array(1,1,1),
                                      vOrdinates);
    ELSE
      vGeometry := SELF.geom;
    END IF;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(vGeometry,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  END ST_SdoPoint2Ord;

  Member Function ST_toMultiPoint
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    v_ordinates  mdsys.sdo_ordinate_array;
    v_ord        pls_integer;
    v_num_points pls_integer;
  Begin
    IF ( SELF.geom.sdo_point     is null   or
         SELF.geom.sdo_point.X   is null ) THEN
      RETURN SELF;
    ELSIF (SELF.geom.sdo_ordinates is null   or
           SELF.geom.sdo_ordinates.COUNT = 0 or
         SELF.geom.sdo_ordinates(1) is null ) Then
      Return SELF.ST_SdoPoint2Ord();
    END IF;
    v_Ordinates := SELF.geom.sdo_ordinates;
    v_ord       := SELF.geom.sdo_ordinates.COUNT;
    v_Ordinates.EXTEND(SELF.ST_Dims());
    v_Ordinates(v_ord + 1) := SELF.geom.Sdo_Point.X;
    v_Ordinates(v_ord + 2) := SELF.geom.Sdo_Point.Y;
    IF ( SELF.ST_Dims() >= 3 ) THEN
      v_Ordinates(v_ord + 3) := SELF.geom.Sdo_Point.Z;
    End If;
    v_num_points := v_ordinates.COUNT / SELF.ST_Dims();
    Return &&INSTALL_SCHEMA..T_GEOMETRY (
                   sdo_geometry((SELF.ST_Dims() * 1000) + 5,
                               SELF.ST_Srid(),
                               NULL,
                               MDSYS.SDO_ELEM_INFO_ARRAY(1,1,v_num_points),
                               v_ordinates
                  ),
                  SELF.tolerance,
                  SELF.dPrecision,
                  SELF.projected);
  End ST_toMultiPoint;
  
  Member Function ST_To2D
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    v_2D_geom MDSYS.SDO_Geometry;
    v_i       PLS_INTEGER;
    v_j       PLS_INTEGER;
    v_offset  PLS_INTEGER;
  Begin
    IF (SELF.ST_Dims() = 2) THEN
      -- Nothing to do, SELF.geom is already 2D
      RETURN &&INSTALL_SCHEMA..T_GEOMETRY(SELF.geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
    END IF;
    -- Construct output object ...
    v_2D_geom :=  MDSYS.SDO_GEOMETRY(2000 + SELF.ST_Gtype(),
                                     SELF.ST_srid(),
                                     SElf.geom.sdo_point,
                                     SELF.geom.sdo_elem_info,
                                     New MDSYS.sdo_ordinate_array ()
                                    );
    -- Does geometry have a valid sdo_point?
    If ( V_2d_Geom.Sdo_Point Is Not Null ) Then
        -- It's a point - possibly with sdo_ordinates.... fix this first...
        V_2d_Geom.Sdo_Point.Z := Null;
    End If;
    If ( SELF.ST_GType() = 1 And SELF.Geom.Sdo_Ordinates Is Not Null ) Then
        V_2d_Geom.Sdo_Ordinates := SELF.Geom.Sdo_Ordinates;
        v_2d_geom.sdo_ordinates.trim(1);
    ElsIf ( self.st_gtype() = 1 ) then
       -- Debug dbms_output.put_line(v_2d_geom.sdo_ordinates.count);
       v_2d_geom.sdo_elem_info := null;
       v_2d_geom.sdo_ordinates := null;
    ElsIF ( SELF.ST_GType() != 1 AND v_2D_geom.sdo_ordinates is not null ) THEN
        -- It's not a single point ...
        -- Process the geometry's ordinate array
        v_2D_geom.sdo_ordinates.EXTEND ( SELF.ST_NumVertices() * 2 );
        -- Copy the ordinates array
        v_i := SELF.geom.sdo_ordinates.FIRST;   -- index into input ordinate array
        v_j := 1;                               -- index into output ordinate array
        FOR i IN 1 .. SELF.ST_NumVertices() LOOP
          v_2D_geom.sdo_ordinates (v_j)     := SELF.geom.sdo_ordinates (v_i);      -- copy X
          v_2D_geom.sdo_ordinates (v_j + 1) := SELF.geom.sdo_ordinates (v_i + 1);  -- copy Y
          v_i := v_i + SELF.ST_Dims();
          v_j := v_j + 2;
        END LOOP;
        -- Process the element info array
        -- by adjust the offsets
        v_i := v_2D_geom.sdo_elem_info.FIRST;
        WHILE v_i < v_2D_geom.sdo_elem_info.LAST LOOP
          If Not ( v_2D_geom.sdo_elem_info (v_i + 1) in (4,5,1005,2005) ) Then
            -- Adjust Elem Info offsets
            v_offset := v_2D_geom.sdo_elem_info (v_i);
            v_2D_geom.sdo_elem_info(v_i) := (v_offset - 1) / SELF.ST_Dims() * 2 + 1;
          End If;
          v_i := v_i + 3;
        END LOOP;
    END IF;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(v_2D_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  END ST_To2D;

  Member Function ST_To3D(p_zordtokeep IN INTEGER)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    c_i_z_ord    Constant Integer       := -20121;
    c_s_z_ord    Constant VarChar2(100) := 'p_zordtokeep should be either 3 or 4';
    c_i_mismatch Constant Integer       := -20121;
    c_s_mismatch Constant VarChar2(100) := 'p_zordtokeep is 4 but geometry is ';
    v_offset     PLS_INTEGER;
    v_count      PLS_Integer;
    v_coord      PLS_INTEGER;
    v_coords     MDSYS.VERTEX_SET_TYPE;
    v_3D_geom    MDSYS.SDO_Geometry := SELF.geom;
  Begin
    IF ( p_zordtokeep not in (3,4) ) THEN
      raise_application_error(c_i_z_ord,c_s_z_ord,true);
    END IF;
    IF ( p_zordtokeep = 4 AND SELF.ST_Dims() < 4) THEN
      raise_application_error(c_i_mismatch,c_s_mismatch||SELF.ST_Dims(),true);
    END IF;
    IF ( SELF.ST_Dims() = 3 ) THEN
      -- Nothing to do, p_geom is already 3D
      Return &&INSTALL_SCHEMA..T_GEOMETRY(SELF.geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
    END IF;
    -- If Single Point, nothing to do ...
    If ( SELF.geom.sdo_ordinates Is Null ) Then
      return &&INSTALL_SCHEMA..T_GEOMETRY(SELF.geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
    End If;
    -- Construct output object ...
    v_3D_geom.sdo_gtype := 3000 + SELF.ST_GType();
    IF ( SELF.ST_Lrs_Dim() = p_zordtokeep ) Then
       v_3D_geom.sdo_gtype := v_3D_geom.sdo_gtype + 300;
    End If;
    v_coords := Mdsys.Sdo_Util.GetVertices(SELF.geom);

    -- If Single Point described by ordinates, convert to 3D sdo_point
    IF ( v_coords.COUNT = 1) Then
      IF (p_zordtokeep = 3) Then
         v_3D_geom.sdo_point := mdsys.sdo_point_type(v_coords(1).x, v_coords(1).y, v_coords(1).z);
      Else
         v_3D_geom.sdo_point := mdsys.sdo_point_type(v_coords(1).x, v_coords(1).y, v_coords(1).w);
      End If;
      v_3D_geom.sdo_elem_info := null;
      v_3D_geom.sdo_ordinates := null;
      Return &&INSTALL_SCHEMA..T_GEOMETRY(v_3D_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
    End If;

    v_3D_geom.sdo_ordinates := MDSYS.sdo_ordinate_array ();
    -- Create space in ordinate array for 3D coordinates
    v_3D_geom.sdo_ordinates.EXTEND ( SELF.ST_NumVertices() * 3 );
    v_coord := 1;
    For i in 1..v_coords.COUNT Loop
      V_3d_Geom.Sdo_Ordinates (v_coord)     := v_coords(i).X;
      v_3D_geom.sdo_ordinates (v_coord + 1) := v_coords(i).y;
      V_3d_Geom.Sdo_Ordinates (v_coord + 2) := case when p_zordtokeep=3
                                                    then v_coords(i).z
                                                    else v_coords(i).w
                                                end;
      v_coord := v_coord + 3;
    END LOOP;
    -- Process the element info array and adjust the offsets
    V_Count := 1;
    V_Offset := 0;
    For v_i in v_3D_geom.sdo_Elem_Info.First .. v_3D_geom.sdo_Elem_Info.Last Loop
        -- IsCompoundElement?
        If ( Mod(v_count,3) = 1 ) Then -- Ordinate count to adjust
           -- Adjust Elem Info offsets
           If Not ( v_3D_geom.sdo_Elem_Info (V_I + 1) In (4,5,1005,2005) ) Then
              V_Offset := v_3D_geom.sdo_Elem_Info (V_I);
              v_3D_geom.sdo_elem_info(v_i) := ( v_offset - 1 ) / SELF.ST_Dims() * 3 + 1;
           End If;
        End If;
        v_count := v_count + 1;
    End Loop;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(v_3d_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_To3D;

  Member Function ST_To3D(p_start_z IN NUMBER,
                          p_end_z   IN NUMBER,
                          p_unit    IN VARCHAR2 DEFAULT NULL)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    v_count      PLS_Integer;
    v_coords     MDSYS.VERTEX_SET_TYPE;
    v_i          PLS_INTEGER;
    v_j          PLS_INTEGER;
    v_offset     PLS_INTEGER;
    v_start_z    number;
    v_end_z      number;
    v_range      NUMBER := 0;
    v_length     NUMBER := 0;
    v_cum_length NUMBER := 0;
    v_3D_geom    MDSYS.SDO_Geometry;
    v_t_geom     &&INSTALL_SCHEMA..T_GEOMETRY;
  Begin
    IF ( SELF.ST_Dims() = 3 ) THEN
      -- Nothing to do, p_geom is already 3D
      Return &&INSTALL_SCHEMA..T_GEOMETRY(SELF.geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
    ElsIf ( SELF.ST_Dims() = 4 ) Then
      v_t_geom := SELF.ST_To3D(3);
      Return v_t_geom;
    END IF;
    v_start_z := NVL(p_start_z,0);
    v_length  := SELF.ST_Length(p_unit);
    v_end_z   := NVL(p_end_z,v_length);
    v_range   := v_end_z - v_start_z;
    -- Construct output object ...
    v_3D_geom := MDSYS.SDO_GEOMETRY(3000 + SELF.ST_GType(),
                                    SELF.geom.sdo_srid,
                                    SELF.geom.sdo_point,
                                    SELF.geom.sdo_elem_info,
                                    MDSYS.sdo_ordinate_array ()
                                  );
    -- Does geometry have a valid sdo_point?
    IF ( v_3D_geom.sdo_point is not null ) Then
      -- It's a point, there's not much to it...
      v_3D_geom.sdo_point.Z := v_start_z;
    END IF;
    -- If Single Point, all done, else...
    If ( V_3d_Geom.Sdo_Elem_Info Is Null ) Then
      return &&INSTALL_SCHEMA..T_GEOMETRY(v_3d_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
    End If;
    -- It's not a single point ...
    -- Process the geometry's ordinate array
    -- Create space in ordinate array for 3D coordinates
    v_3D_geom.sdo_ordinates.EXTEND(SELF.ST_NumVertices() * 3);
    -- Copy the ordinates array
    -- index into output ordinate array
    V_J          := 1;
    v_cum_length := 0;
    v_coords     := mdsys.sdo_util.getVertices(SELF.geom);
    For i in 1..v_coords.COUNT Loop
      V_3d_Geom.Sdo_Ordinates (V_J)        := v_coords(i).X;
      v_3D_geom.sdo_ordinates (v_j + 1)    := v_coords(i).y;
      -- Compute new Z
      If ( i = 1 ) Then
         V_3d_Geom.Sdo_Ordinates (V_J + 2) := v_Start_Z;
      Else
         v_cum_length := v_cum_length +
               ROUND(&&INSTALL_SCHEMA..T_Segment(
                             p_Segment_id  => 0,
                                   p_startCoord => &&INSTALL_SCHEMA..T_Vertex(
                                                        p_vertex    => v_coords(i-1),
                                                        p_id        => i,
                                                        p_sdo_gtype => SELF.ST_Sdo_GType(),
                                                        p_sdo_srid  => SELF.ST_SRID()),
                                   p_endCoord   => &&INSTALL_SCHEMA..T_Vertex(
                                                        p_vertex    => V_Coords(i),
                                                        p_id        => i,
                                                        p_sdo_gtype => SELF.ST_Sdo_GType(),
                                                        p_sdo_srid  => SELF.ST_SRID()),
                                   p_sdo_gtype  => 2002,
                             p_sdo_srid   => SELF.ST_SRID(),
                             p_projected  => SELF.projected,
                             p_precision  => SELF.dPrecision,
                             p_tolerance  => SELF.tolerance
                    )
                    .ST_Length(p_unit),
                     SELF.dPrecision);
         v_3D_geom.sdo_ordinates (v_j + 2) :=
               case when v_end_z is null
                    then v_start_z
                    when v_length <> 0
                    then v_start_z + ROUND(v_range * (v_cum_length/v_length),SELF.dPrecision)
                    else v_start_z
                end;
      End If;
      v_j := v_j + 3;
    END LOOP;
    -- Process the element info array
    -- by adjust the offsets
    V_Count  := 1;
    V_Offset := 0;
    For v_i in v_3D_geom.sdo_Elem_Info.First .. v_3D_geom.sdo_Elem_Info.Last Loop
          -- IsCompoundElement?
          If ( Mod(v_count,3) = 1 ) Then -- Ordinate count to adjust
             -- Adjust Elem Info offsets
             If Not ( v_3D_geom.sdo_Elem_Info (V_I + 1) In (4,5,1005,2005) ) Then
                V_Offset := v_3D_geom.sdo_Elem_Info (V_I);
                v_3D_geom.sdo_elem_info(v_i) := ( v_offset - 1 ) / SELF.ST_Dims() * 3 + 1;
             End If;
          End If;
          v_count := v_count + 1;
    End Loop;
    -- DEBUG dbms_output.put_line(&&INSTALL_SCHEMA..PRINT.sdo_ordinates(p_ordinates=>v_3D_geom.sdo_ordinates,p_coordDim=>3,p_round=>7));
    Return &&INSTALL_SCHEMA..T_GEOMETRY(V_3d_Geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_To3d;

  Member Function ST_FixZ(p_default_z IN NUMBER := -9999)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    v_3D_Geom mdsys.sdo_geometry := SELF.geom;
    v_isEmpty varchar2(5);
  begin
    if ( SELF.ST_Dims()<>3 ) then
      -- Nothing to do, geometry is not 3D
      Return &&INSTALL_SCHEMA..T_GEOMETRY(SELF.geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
    end if;
    -- Process the point structure
    if ( v_3D_Geom.sdo_point is not null ) then
      if ( v_3D_Geom.sdo_point.z is null) then
        v_3D_Geom.SDO_Point.Z := p_default_z;
      end if;
    end if;
    -- Process object replacing NULL Z values with p_default_z
    FOR i in 1..SELF.ST_NumVertices() LOOP
      IF (v_3D_Geom.sdo_ordinates(i*SELF.ST_Dims()) is null) THEN
        v_3D_geom.sdo_ordinates(i*SELF.ST_Dims()) := p_default_z;
      END IF;
    end loop;
    return &&INSTALL_SCHEMA..T_GEOMETRY(v_3D_Geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  END ST_FixZ;

  Member Function ST_Add_Segment(p_Segment in &&INSTALL_SCHEMA..T_Segment)
           Return &&INSTALL_SCHEMA..T_Geometry
  As
    v_last_vertex &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(), p_sdo_srid  => SELF.ST_SRID());
    v_ords        mdsys.sdo_ordinate_array;
    v_elem_info   mdsys.sdo_elem_info_array;
    v_gtype       pls_integer;
    v_ord_count   pls_integer;

    -- PRAGMA INLINE (appendVertex, 'YES');
    Procedure appendVertex(p_ordinates in out nocopy mdsys.sdo_ordinate_array,
                           p_vertex    in &&INSTALL_SCHEMA..T_vertex)
    Is
      v_ord_count pls_integer;
    Begin
      -- DEBUG dbms_output.put_line('      <appendVertex vertex=' ||p_vertex.ST_AsText(3) || '>');
      v_ord_count := p_ordinates.COUNT + 1;
      -- DEBUG dbms_output.put_line('        v_ord_count =' || v_ord_count || ' SELF.ST_Dims()=' || SELF.ST_Dims() || ' p_ordinates.COUNT Before=' || p_ordinates.COUNT);
      p_ordinates.EXTEND(SELF.ST_Dims());
      -- DEBUG dbms_output.put_line('        p_ordinates.COUNT AFTER=' || p_ordinates.COUNT);
      -- Insert first vertex
      p_ordinates(v_ord_count)   := p_vertex.X;
      p_ordinates(v_ord_count+1) := p_vertex.Y;
      If (SELF.ST_Dims()>=3) Then
         p_ordinates(v_ord_count+2) := p_vertex.z;
         if ( SELF.ST_Dims() > 3 ) Then
             p_ordinates(v_ord_count+3) := p_vertex.w;
         End If;
      End If;
      -- DEBUG dbms_output.put_line('      </appendVertex>');
    End appendVertex;

    -- PRAGMA INLINE (checkCompoundHeader, 'YES');
    Procedure checkCompoundHeader(p_elem_info in out nocopy mdsys.sdo_elem_info_array)
    As
    Begin
       -- DEBUG dbms_output.put_line('      <checkCompoundHeader>');
       if ( p_elem_info(2) <> 4 ) Then
          p_elem_info.EXTEND(3);
          <<Reverse_Fill_Loop>>
          FOR v_i IN REVERSE p_elem_info.FIRST..p_elem_info.LAST LOOP
             if (v_i = 1) Then
                p_elem_info(v_i) := 1;
             ElsIf (v_i = 2) Then
                p_elem_info(v_i) := 4;
             ELSIF (V_I = 3) THEN
                p_elem_info(v_i) := ((p_elem_info.COUNT - 3) / 3); -- Number elements
             Else
                p_elem_info(v_i) := p_elem_info(v_i - 3);
             End If;
          END LOOP Reverse_Fill_Loop;
       Else
          p_elem_info(3) := p_elem_info(3) + 1; -- Increment Number elements
       End If;
       -- DEBUG dbms_output.put_line('      </checkCompoundHeader>');
    End checkCompoundHeader;

  Begin
    -- DEBUG dbms_output.put_line('<ST_Add_Segment>');
    If (p_Segment is null) Then
        return SELF;
    End If;
    If (SELF.geom is null) Then
        return &&INSTALL_SCHEMA..T_Geometry(p_Segment.ST_SdoGeometry(),SELF.tolerance,SELF.dPrecision,SELF.projected);
    End If;
    -- We support linestrings and points only
    -- DEBUG dbms_output.put_line('      SELF.ST_AsTText()=' ||SELF.ST_AsTText());
    -- DEBUG dbms_output.put_line('      p_Segment is ' || p_Segment.ST_AsText(3));
    If (SELF.ST_Dimension() <> 1 ) Then
      Return SELF;
    End If;
    v_gtype       := SELF.geom.sdo_gtype;
    v_elem_info   := SELF.geom.sdo_elem_info;
    v_ords        := SELF.geom.sdo_ordinates;
    v_ord_count   := SELF.geom.sdo_ordinates.COUNT;
    -- Test if segment is extending an existing line
    v_last_vertex := SELF.ST_EndVertex();
    -- DEBUG dbms_output.put_line('      Geometry''s Last Vertex is ' || v_last_vertex.ST_AsText());
    -- DEBUG dbms_output.put_line('      p_Segment.startCoord    is ' || p_Segment.startCoord.ST_AsText()); dbms_output.put_line('      p_Segment.startCoord.ST_isEmpty() = ' || p_Segment.startCoord.ST_isEmpty());
    if (    v_last_vertex.ST_Equals(p_Segment.startCoord,SELF.dPrecision)=1
        or p_Segment.startCoord.ST_isEmpty()=1) Then
      -- DEBUG dbms_output.put_line('      StartCoord (Equals) v_last_vertex - Do Nothing');
      -- No nothing as we don't want duplicate coordinates
      NULL;
    Else
      -- DEBUG dbms_output.put_line('      StartCoord (not Equals) v_last_vertex= ' || p_Segment.startCoord.ST_AsText());
      -- This means that the linestring becomes a multi-linestring?
      appendVertex(v_ords,p_Segment.startCoord);
    End If;
    if ( p_Segment.midCoord is not null and p_Segment.midCoord.ST_isEmpty()=0) Then
      -- DEBUG dbms_output.put_line('      addVertex mid = ' || p_Segment.midCoord.ST_AsText());
      appendVertex(v_ords,p_Segment.midCoord);
    End If;
    -- Add EndCoord
    if ( p_Segment.endCoord is not null and p_Segment.endCoord.ST_isEmpty()=0 ) Then
       -- DEBUG dbms_output.put_line('      addVertex end= ' || p_Segment.endCoord.ST_AsText());
       appendVertex(v_ords,p_Segment.endCoord);
    End If;
    -- Check sdo_elem_info_array if not now multilinestring
    --
    if (v_last_vertex.ST_Equals(p_Segment.startCoord,SELF.dPrecision)=1) Then -- startCoord?
       if ( p_Segment.midCoord is not null  and p_Segment.midCoord.ST_isEmpty()=0) Then
         IF ( v_elem_info(v_elem_info.COUNT-1) = 2 ) Then
           -- Add new element for this arc
           v_elem_info.EXTEND(3);
           v_elem_info(v_elem_info.COUNT  ) := 2;               -- arc interpretation
           v_elem_info(v_elem_info.COUNT-1) := 2;               -- linestring etype
           v_elem_info(v_elem_info.COUNT-2) := v_ord_count - (SELF.geom.get_dims() - 1); -- offset is last coordinate of existing
           checkCompoundHeader(v_elem_info);
         End If;
       Else
         IF ( v_elem_info(v_elem_info.COUNT) = 2 ) Then
           -- Previous was arc so we need new element
           v_elem_info.EXTEND(3);
           v_elem_info(v_elem_info.COUNT  ) := 1;               -- linestring interpretation
           v_elem_info(v_elem_info.COUNT-1) := 2;               -- linestring etype
           v_elem_info(v_elem_info.COUNT-2) := v_ord_count - (SELF.geom.get_dims() - 1); -- offset is last coordinate of existing
           checkCompoundHeader(v_elem_info);
         End If;
       End If;
    Else
       v_gtype := case when mod(v_gtype,10)=2 then v_gtype + 4 else v_gtype end;
       -- DEBUG dbms_output.put_line('      Extending elem_info for multilinestring');
       v_elem_info.EXTEND(3);
       v_elem_info(v_elem_info.COUNT  ) := case when p_Segment.midCoord is not null
                                                then 2
                                                else 1
                                            end;            -- interpretation
       v_elem_info(v_elem_info.COUNT-1) := 2;               -- linestring etype
       v_elem_info(v_elem_info.COUNT-2) := v_ord_count + 1; -- new offset
    End If;
    -- DEBUG dbms_output.put_line('      v_gtype=' || nvl(v_gtype,0));
    -- DEBUG dbms_output.put_line('</ST_Add_Segment>');
    Return &&INSTALL_SCHEMA..T_Geometry(mdsys.sdo_geometry(v_gtype,SELF.geom.sdo_srid,SELF.geom.sdo_point,v_elem_info,v_ords),
                           SELF.tolerance,
                           SELF.dPrecision,
                           SELF.projected);
  End ST_Add_Segment;

  Member Function ST_Reverse_Linestring
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    c_i_null_tolerance CONSTANT INTEGER       := -20122;
    c_s_null_tolerance CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';
    c_i_not_geom       CONSTANT INTEGER       := -20121;
    c_s_not_geom       CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';

    v_segments         &&INSTALL_SCHEMA..T_Segments;
    v_num_elements     pls_integer := 0;
    v_return_tgeom     &&INSTALL_SCHEMA..T_geometry;
    v_reverse_geom     &&INSTALL_SCHEMA..T_Geometry;
    v_extract_geom     mdsys.sdo_geometry;
    v_geom             mdsys.sdo_geometry;
  Begin
    -- Only makes sense to snap a point to a linestring
    If ( SELF.ST_Dimension() <> 1 ) Then
      raise_application_error(c_i_not_geom,
                              REPLACE(
                                REPLACE(c_s_not_geom,
                                        '*GTYPE1*',SELF.ST_GeometryType()),
                                        '*GTYPE2*','(Multi)Linestring'),TRUE);
    End If;
    if ( SELF.tolerance is null ) Then
      raise_application_error(c_i_null_tolerance,
                              c_s_null_tolerance,TRUE);
    End If;

    -- Create gtype of returned object based on this dimension
    v_num_elements := SELF.ST_NumElements();
    <<for_all_elements>>
    For v_element IN Reverse 1..v_num_elements Loop
      v_extract_geom := mdsys.sdo_util.extract(SELF.geom,v_element,0);
      -- iterate over segments
      -- Current segment is in v_extract_geom
      SELECT seg.ST_Reverse() as line
        BULK COLLECT
        INTO v_segments
        FROM TABLE(&&INSTALL_SCHEMA..T_GEOMETRY(
                      v_extract_geom,
                      SELF.tolerance,
                      SELF.dPrecision,
                      SELF.projected
                    ).ST_Segmentize(p_filter=>'ALL')
                  ) seg
       ORDER BY seg.element_id,
                seg.subelement_id,
                seg.segment_id desc;

      If (v_segments is null or v_segments.COUNT = 0 ) Then
          return null;
      end if;

      v_reverse_geom := null;
      <<for_all_arcSegments_in_element>>
      For i IN v_segments.First..v_segments.Last Loop
        -- Add segment to return geometry
        --
        IF (V_REVERSE_GEOM IS NULL) THEN
           -- DEBUG dbms_output.PUT_LINE('v_segment(' || I || ')=' || v_segments(i).ST_ASTEXT());
           -- DEBUG dbms_output.put_line('ST_SdoGeometry: ' );
           v_reverse_geom := &&INSTALL_SCHEMA..T_GEOMETRY(v_segments(i).ST_SdoGeometry(),SELF.tolerance,SELF.dPrecision,SELF.projected);
           -- DEBUG dbms_output.put_line('  v_reverse_geom was null and now is ='||v_reverse_geom.ST_AsEWKT());
           -- v_return_tgeom.geom.sdo_gtype := SELF.geom.sdo_gtype;
        Else
           -- DEBUG dbms_output.put_line('v_segment=' || v_segments(i).ST_AsText());
           v_geom := v_reverse_geom.ST_Add_Segment(v_segments(i)).geom;
           -- DEBUG dbms_output.put_line('v_geom (' || v_geom.sdo_gtype || ') is ' || case when v_geom is null then 'NULL' else 'NOT NULL' || &&INSTALL_SCHEMA..T_GEOMETRY(v_geom,SELF.tolerance,SELF.dPrecision,SELF.projected).ST_Validate() end );
           v_reverse_geom := &&INSTALL_SCHEMA..T_GEOMETRY(v_geom,SELF.tolerance,SELF.dPrecision,SELF.projected);
           -- DEBUG dbms_output.put_line('  v_return_tgeom='||v_return_tgeom.ST_AsEWKT());
        End If;
      End Loop for_all_arcSegments_in_element;

      v_return_tgeom := &&INSTALL_SCHEMA..T_Geometry(
                         case when v_return_tgeom is null
                              then v_reverse_geom.geom
                              else mdsys.sdo_util.append(v_return_tgeom.geom,v_reverse_geom.geom)
                          end,
                         SELF.tolerance,SELF.dPrecision,SELF.projected);

    end loop for_all_elements;
    v_return_tgeom.geom.sdo_gtype := SELF.geom.sdo_gtype;
    Return v_return_tgeom;
  End ST_Reverse_Linestring;

  Member Function ST_Reverse_Geometry
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    v_ordinates mdsys.sdo_ordinate_array;
    v_ord       pls_integer;
    v_dims      pls_integer;
    v_vertex    pls_integer;
    v_vertices  mdsys.vertex_set_type;
  Begin
    If ( SELF.geom.get_gtype() not in (2,3,5,6,7) OR SELF.geom.sdo_ordinates is null ) Then
       return SELF;
    End If;
    IF ( SELF.ST_Gtype() in (2,6) ) THEN
      RETURN SELF.ST_Reverse_Linestring();
    END IF;
    v_dims      := SELF.geom.get_dims();
    v_vertices  := sdo_util.getVertices(SELF.geom);
    v_ordinates := new mdsys.sdo_ordinate_array(1);
    v_ordinates.DELETE;
    v_ordinates.EXTEND(SELF.geom.sdo_ordinates.count);
    v_ord    := 1;
    v_vertex := v_vertices.LAST;
    WHILE (v_vertex >= 1 ) LOOP
        v_ordinates(v_ord) := v_vertices(v_vertex).x; v_ord := v_ord + 1;
        v_ordinates(v_ord) := v_vertices(v_vertex).y; v_ord := v_ord + 1;
        if ( v_dims >= 3 ) Then
           v_ordinates(v_ord) := v_vertices(v_vertex).z; v_ord := v_ord + 1;
        end if;
        if ( v_dims >= 4 ) Then
           v_ordinates(v_ord) := v_vertices(v_vertex).w; v_ord := v_ord + 1;
        end if;
        v_vertex := v_vertex - 1;
    END LOOP;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(
             mdsys.sdo_geometry(SELF.geom.sdo_gtype,
                                SELF.geom.sdo_srid,
                                SELF.geom.sdo_point,
                                SELF.geom.sdo_elem_info,
                                v_ordinates),
             SELF.tolerance,
             SELF.dPrecision,
             SELF.projected);
  End ST_Reverse_Geometry;

  Member Function ST_AsTText(p_linefeed     in integer  default 1,
                             p_format_model in varchar2 default 'TM9')
           Return CLOB
  As
    v_ord_format varchar2(100) := NVL(p_format_model,'TM9');
    v_text       Clob;
    v_linefeed   char(1) := case when NVL(p_linefeed,1) = 0 then '' else CHR(10) end;
  Begin
    SYS.DBMS_LOB.CreateTemporary( v_text, TRUE, SYS.DBMS_LOB.CALL );
    SYS.DBMS_LOB.APPEND(v_text,'&&INSTALL_SCHEMA..T_GEOMETRY(');
    SYS.DBMS_LOB.APPEND(v_text,'MDSYS.SDO_GEOMETRY('||
                               Case When SELF.geom.sdo_gtype Is Null
                                    Then 'NULL'
                                    Else To_Char(SELF.geom.sdo_gtype,'FM9999')
                                End || ',' ||
                               CASE WHEN SELF.ST_SRID() IS NULL
                                    THEN 'NULL'
                                    ELSE TO_CHAR(SELF.ST_SRID())
                                END || ',' ||
                               CASE WHEN SELF.geom.SDO_POINT IS NULL
                                    THEN 'NULL,'
                                    ELSE 'MDSYS.SDO_POINT_TYPE(' ||
                                         NVL(TO_CHAR(SELF.geom.sdo_point.x,v_ord_format),'NULL') || ',' ||
                                         NVL(TO_CHAR(SELF.geom.sdo_point.y,v_ord_format),'NULL') || ',' ||
                                         NVL(TO_CHAR(SELF.geom.sdo_point.z,v_ord_format),'NULL') ||
                                         '),'
                                END );
    IF ( SELF.geom.sdo_elem_info IS NULL ) THEN
      SYS.DBMS_LOB.APPEND(v_text,'NULL,');
    ELSE
      SYS.DBMS_LOB.APPEND(v_text,'MDSYS.SDO_ELEM_INFO_ARRAY(');
      FOR i IN SELF.geom.sdo_elem_info.FIRST..SELF.geom.sdo_elem_info.LAST LOOP
          SYS.DBMS_LOB.APPEND(v_text,''||SELF.geom.sdo_elem_info(i));
          If ( i <> SELF.geom.sdo_elem_info.LAST ) THEN
            If ( 0 = MOD(i,3) ) Then
               SYS.DBMS_LOB.APPEND(v_text,',');
            Else
               SYS.DBMS_LOB.APPEND(v_text,',');
            End If;
          END IF;
      END LOOP;
      SYS.DBMS_LOB.APPEND(v_text,'),');
    END IF;
    IF ( SELF.geom.sdo_ordinates IS NULL ) THEN
      SYS.DBMS_LOB.APPEND(v_text,'NULL);');
    ELSE
      SYS.DBMS_LOB.APPEND(v_text,'MDSYS.SDO_ORDINATE_ARRAY(');
      FOR i IN SELF.geom.sdo_ordinates.FIRST..SELF.geom.sdo_ordinates.LAST LOOP
          SYS.DBMS_LOB.APPEND(v_text,
                              case when SELF.geom.sdo_ordinates(i) is null
                                   then 'NULL'
                                   else TO_CHAR(SELF.geom.sdo_ordinates(i),v_ord_format)
                               end);
          IF ( I <> SELF.GEOM.SDO_ORDINATES.LAST ) THEN
             If ( 0 = MOD(i,SELF.ST_Dims() ) ) Then
                SYS.DBMS_LOB.APPEND(v_text,',');
             Else
                SYS.DBMS_LOB.APPEND(v_text,',');
             End If;
          END IF;
      END LOOP;
      SYS.DBMS_LOB.APPEND(v_text,'));');
    END IF;
    SYS.DBMS_LOB.APPEND(v_text,
                       'TOLERANCE(' || NVL(TO_CHAR(SELF.tolerance),'NULL') || '),' ||
                       'PRECISION(' || NVL(TO_CHAR(SELF.dPrecision),'NULL') || '),' ||
                       'PROJECTED(' || NVL(TO_CHAR(SELF.projected),'NULL') || ')'
                       );
    Return v_text;
  End ST_AsTText;

-- ========================================================================================
-- ============================= GeoProcessing Functions ==================================
-- ========================================================================================

  Member Function ST_Intersection(p_geometry in mdsys.sdo_geometry,
                                  p_order    in varchar2 Default 'FIRST')
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    c_i_spatial    CONSTANT pls_integer   := -20102;
    c_s_spatial    CONSTANT VARCHAR2(100) := 'MDSYS.SDO_GEOM.SDO_INTERSECTION only supported for Locator users from 12C onwards.';
    v_result_geom mdsys.sdo_geometry;
  Begin
    -- p_order should be FIRST or SECOND but if not SECOND all are treated as FIRST (Standard/Default)
    IF (  &&INSTALL_SCHEMA..TOOLS.ST_DB_Version() >= 12.0
       OR &&INSTALL_SCHEMA..TOOLS.ST_isLocator()   = 0 ) THEN
      v_result_geom := MDSYS.SDO_GEOM.sdo_intersection(
                         case when UPPER(NVL(p_order,'FIRST')) <> 'SECOND'
                              then SELF.geom
                              else p_geometry
                          end,
                         case when UPPER(NVL(p_order,'FIRST')) <> 'SECOND'
                              then p_geometry
                              else SELF.geom
                          end,
                         SELF.tolerance
                       );
    ELSE
      -- TODO: Implement intersection that is Locator 11g compliant.
      raise_application_error(c_i_spatial,c_s_spatial,true);
    END IF;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(v_result_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_Intersection;

  Member Function ST_Difference(p_geometry in mdsys.sdo_geometry,
                                p_order    in varchar2 Default 'FIRST')
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    c_i_spatial   CONSTANT pls_integer   := -20102;
    c_s_spatial   CONSTANT VARCHAR2(100) := 'MDSYS.SDO_GEOM.SDO_DIFFERENCE only supported for Locator users from 12C onwards.';
    v_result_geom mdsys.sdo_geometry;
  Begin
    -- p_order should be FIRST or SECOND but if not SECOND all are treated as FIRST (Standard/Default)
    IF (  &&INSTALL_SCHEMA..TOOLS.ST_DB_Version() >= 12.0
       OR &&INSTALL_SCHEMA..TOOLS.ST_isLocator()   = 0 ) THEN
      v_result_geom := MDSYS.SDO_GEOM.sdo_difference(
                         case when UPPER(NVL(p_order,'FIRST')) <> 'SECOND'
                              then SELF.geom
                              else p_geometry
                          end,
                         case when UPPER(NVL(p_order,'FIRST')) <> 'SECOND'
                              then p_geometry
                              else SELF.geom
                          end,
                         SELF.tolerance
                       );
    ELSE
      -- TODO: Implement intersection that is Locator 11g compliant.
      raise_application_error(c_i_spatial,c_s_spatial,true);
    END IF;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(v_result_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_Difference;


  Member Function ST_Buffer(p_distance in number,
                            p_unit     in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  Is
    c_i_spatial   Constant pls_integer   := -20102;
    c_s_spatial   Constant VARCHAR2(100) := 'MDSYS.SDO_GEOM.SDO_BUFFER only supported for Locator users from 11g onwards.';
    c_i_distance  Constant Integer       := -20121;
    c_s_distance  Constant VarChar2(100) := 'p_distance must not be null.';
    v_result_geom mdsys.sdo_geometry;
  Begin
    If (p_distance is null) Then
       raise_application_error(c_i_distance,c_s_distance,true);
    End If;
    IF (  &&INSTALL_SCHEMA..TOOLS.ST_DB_Version() >= 11.0
       OR &&INSTALL_SCHEMA..TOOLS.ST_isLocator()   = 0 ) THEN
      -- DEBUG dbms_output.put_line('ST_Buffer of ' || SELF.ST_AsEWKT() || ' by ' || p_distance);
      v_result_geom := case when p_unit is not null and SELF.ST_Srid() is not null
                            then MDSYS.SDO_GEOM.sdo_buffer(SELF.geom,p_distance,SELF.tolerance,p_unit)
                            else MDSYS.SDO_GEOM.sdo_buffer(SELF.geom,p_distance,SELF.tolerance)
                        end;
    ELSE
      -- TODO: Implement buffer that is Locator 10g compliant.
      raise_application_error(c_i_spatial,c_s_spatial,true);
    END IF;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(v_result_geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_Buffer;

  Member Function ST_SquareBuffer(p_distance in number,
                                  p_curved   in number default 0,
                                  p_unit     in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  AS
    v_extract_geom &&INSTALL_SCHEMA..T_GEOMETRY;
    v_temp_tgeom   &&INSTALL_SCHEMA..T_GEOMETRY;
    v_geoml        mdsys.sdo_geometry;
    v_geomr        mdsys.sdo_geometry;
    v_rgeom        mdsys.sdo_geometry;
    v_tgeom        mdsys.sdo_geometry;
    v_elem_info    mdsys.sdo_elem_info_array;
    v_vertex       mdsys.vertex_type;
    v_vertices     mdsys.vertex_set_type;
  Begin
    -- DEBUG dbms_output.put_line('<ST_SquareBuffer>: ' || sdo_geom.validate_geometry(SELF.geom,self.tolerance));
    IF ( NVL(p_distance,0.0) <= 0.0 ) Then
       Return SELF;
    End If;
    If ( SELF.ST_Gtype() IN (1,5) ) Then
       v_vertices := mdsys.sdo_util.getVertices(SELF.geom);
       if ( v_vertices is null or v_vertices.COUNT = 0 ) Then
          return SELF;
       End If;
       v_rgeom := null;
       FOR v IN 1..v_vertices.COUNT LOOP
          v_tgeom := mdsys.sdo_geometry(
                                 (SELF.ST_Dims()*1000) + (SELF.ST_Gtype()+2),
                                 SELF.ST_SRID(),
                                 NULL,
                                 mdsys.sdo_elem_info_array(1,1003,3),
                                 case SELF.ST_Dims()
                                      WHEN 3
                                      THEN mdsys.sdo_ordinate_array(v_vertices(v).x - p_distance,
                                                                    v_vertices(v).y - p_distance,
                                                                    v_vertices(v).z,
                                                                    v_vertices(v).x + p_distance,
                                                                    v_vertices(v).y + p_distance,
                                                                    v_vertices(v).z)
                                      WHEN 4
                                      THEN mdsys.sdo_ordinate_array(v_vertices(v).x - p_distance,
                                                                    v_vertices(v).y - p_distance,
                                                                    v_vertices(v).z,v_vertices(v).w,
                                                                    v_vertices(v).x + p_distance,
                                                                    v_vertices(v).y + p_distance,
                                                                    v_vertices(v).z,v_vertices(v).w)
                                      ELSE mdsys.sdo_ordinate_array(v_vertices(v).x - p_distance,
                                                                    v_vertices(v).y - p_distance,
                                                                    v_vertices(v).x + p_distance,
                                                                    v_vertices(v).y + p_distance)
                                end);
          If ( SELF.ST_GType() = 1 OR v_rGeom is null) Then
             v_rgeom := v_tgeom;
          Else
             v_rgeom := mdsys.sdo_util.APPEND(v_rgeom, v_tgeom);
          End If;
       END LOOP;
       Return &&INSTALL_SCHEMA..T_GEOMETRY(v_rgeom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
    End If;
    If ( SELF.ST_Dimension() <> 1 ) Then
       return SELF;
    End If;
    <<for_all_linestrings_in_multi>>
    FOR v_element IN 1..SELF.ST_NumElements() LOOP
      v_extract_geom := &&INSTALL_SCHEMA..T_GEOMETRY(mdsys.sdo_util.Extract(SELF.geom,v_element),SELF.tolerance,SELF.dPrecision,SELF.projected);  -- Extract linestring
      -- v_geoml     := v_extract_geom.ST_Parallel(ABS(p_distance),p_curved,p_unit).geom;
      -- DEBUG dbms_output.put_line('v_extract_geom is ' || case when v_extract_geom is null then 'NULL' else 'NOT NULL' end);
      -- Use ST_LRS_Locate_Measures to move whole linestring
      If ( SELF.ST_LRS_isMeasured()=1 ) Then
         if ( SELF.ST_Dims()=3 ) Then
            v_geoml  := v_extract_geom.ST_LRS_Locate_Measures(NULL,NULL,ABS(p_distance),p_unit).ST_To2D().geom;
         else
            -- throw away LRS but keep other dim
            v_geoml  := v_extract_geom.ST_LRS_Locate_Measures(NULL,NULL,ABS(p_distance),p_unit).ST_To3D(SELF.ST_Dims()-SELF.ST_Lrs_Dim()+3).geom;
         End If;
      Else
        -- DEBUG dbms_output.put_line('SELF.ST_LRS_isMeasured()=0');
        v_geoml  := v_extract_geom.ST_LRS_Locate_Measures(NULL,NULL,ABS(p_distance),p_unit).geom;
      End If;
      -- DEBUG dbms_output.put('  Left: ');
      -- v_geomr    := v_extract_geom.ST_Parallel(0-ABS(p_distance),p_curved,p_unit).ST_Reverse_Linestring().geom;
      -- Use ST_LRS_Locate_Measures to move whole linestring
      If ( SELF.ST_LRS_isMeasured()=1 ) Then
         if ( SELF.ST_Dims()=3 ) Then
            v_geomr := v_extract_geom.ST_LRS_Locate_Measures(NULL,NULL,0-ABS(p_distance),p_unit).ST_Reverse_Linestring().ST_To2D().geom;
         else
            v_geomr := v_extract_geom.ST_LRS_Locate_Measures(NULL,NULL,0-ABS(p_distance),p_unit).ST_Reverse_Linestring().ST_To3D(SELF.ST_Dims()-SELF.ST_Lrs_Dim()+ 3).geom;
         end If;
      Else
         -- DEBUG dbms_output.put_line('v_extract_geom is ' || case when v_extract_geom is null then 'NULL' else 'NOT NULL' end);
         v_temp_tgeom := v_extract_geom.ST_LRS_Locate_Measures(NULL,NULL,0-ABS(p_distance),p_unit);
         -- DEBUG dbms_output.put_line('v_temp_tgeom is ' || case when v_temp_tgeom is null then 'NULL' else 'NOT NULL' end);
         v_geomr := v_temp_tgeom.ST_Reverse_Linestring().geom;
      End If;
      -- DEBUG dbms_output.put('  Right: ');
      /* CONCAT_LINES destroys compound element descriptions, so use APPEND.
         Kills measure gtype which we don't want anyway */
      v_tgeom        := mdsys.sdo_util.Append(v_geoml,v_geomr);
      -- DEBUG dbms_output.put('  Append: ');
      v_vertex       := mdsys.sdo_util.getVertices(v_tgeom)(1);
      -- Add starting vertex on to end to close polygon
      v_vertex.id    := -1;
      -- DEBUG dbms_output.put_line('  v_tgeom := T_GEOMETRY(v_tgeom)');
      v_tgeom := &&INSTALL_SCHEMA..T_GEOMETRY(v_tgeom,SELF.tolerance,SELF.dPrecision,SELF.projected).ST_InsertVertex(&&INSTALL_SCHEMA..T_Vertex(v_vertex)).geom;
      if ( &&INSTALL_SCHEMA..T_GEOMETRY(v_tgeom,SELF.tolerance,SELF.dPrecision,SELF.projected).ST_hasCircularArcs()>0 ) Then
         v_elem_info := mdsys.sdo_elem_info_array(1,1005,v_rgeom.sdo_elem_info.COUNT/3);
         v_elem_info.EXTEND(v_rgeom.sdo_elem_info.COUNT);
         FOR i IN 4..v_rgeom.sdo_elem_info.COUNT LOOP
            v_elem_info(i) := v_rgeom.sdo_elem_info(i-3);
         END LOOP;
         v_tgeom.sdo_gtype     := case when SELF.ST_LRS_isMeasured()=1 then 2003 else SELF.ST_Dims()*1000+3 end;
         v_tgeom.sdo_elem_info := v_elem_info;
      Else
         v_tgeom.sdo_gtype     := case when SELF.ST_LRS_isMeasured()=1 then 2003 else SELF.ST_Dims()*1000+3 end;
         v_tgeom.sdo_elem_info := mdsys.sdo_elem_info_array(1,1003,1);
      End If;
      if ( v_rgeom is null ) then
         v_rgeom := v_tgeom;
      Else
         /* CONCAT_LINES destroys compound element descriptions, so use APPEND.
            But Append destroys sdo_gtype measures which is lost in this function anyway. */
         v_rgeom := MDSYS.SDO_UTIL.APPEND(v_rgeom,v_tgeom);
      End If;
    END LOOP for_all_linestrings_in_multi;
    -- DEBUG dbms_output.put_line('</ST_SquareBuffer>: ' || sdo_geom.validate_geometry(v_rgeom,SELF.tolerance,SELF.dPrecision,SELF.projected));
    Return &&INSTALL_SCHEMA..T_GEOMETRY(v_rgeom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_SquareBuffer;

  Member Function ST_OneSidedBuffer(p_distance in number,
                                    p_curved   in number default 0,
                                    p_unit     in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  AS
    v_extract_geom mdsys.sdo_geometry;
    v_sgeom        mdsys.sdo_geometry;
    v_rgeom        mdsys.sdo_geometry;
    v_tgeom        mdsys.sdo_geometry;
    v_elem_info    mdsys.sdo_elem_info_array;
    v_vertex       &&INSTALL_SCHEMA..T_Vertex;
  Begin
    If ( SELF.ST_Gtype() NOT IN (2,6) or NVL(p_distance,0.0) = 0.0 ) Then
       return SELF;
    End If;

    <<for_all_linestrings_in_multi>>
    FOR v_element IN 1..SELF.ST_NumElements() LOOP
      v_extract_geom := mdsys.sdo_util.Extract(SELF.geom,v_element);  -- Extract linestring
      -- Get First vertex of extracted linestring geometry
      v_vertex := &&INSTALL_SCHEMA..T_GEOMETRY(v_extract_geom,SELF.tolerance,SELF.dPrecision,SELF.projected).ST_VertexN(1);
      if ( SIGN(p_distance) = -1 ) Then -- left
         v_sgeom := &&INSTALL_SCHEMA..T_GEOMETRY(v_extract_geom,SELF.tolerance,SELF.dPrecision,SELF.projected)
                        .ST_Parallel(
                            p_offset=>p_distance,
                            p_curved=>p_curved,
                            p_unit  =>p_unit)
                        .ST_Reverse_Linestring()
                        .geom;
         -- Stitch together
         v_tgeom  := mdsys.sdo_util.Append(v_extract_geom,v_sgeom);
         -- Vertex will be inserted at the end...
         v_vertex.id := -1;
      Else
         v_sgeom := &&INSTALL_SCHEMA..T_GEOMETRY(v_extract_geom,SELF.tolerance,SELF.dPrecision,SELF.projected)
                      .ST_Parallel(
                          p_offset=>p_distance,
                          p_curved=>p_curved,
                          p_unit  =>p_unit)
                      .geom;
         -- Stitch together
         v_tgeom  := mdsys.sdo_util.Append(v_sgeom,
                                           &&INSTALL_SCHEMA..T_GEOMETRY(v_extract_geom,SELF.tolerance,SELF.dPrecision,SELF.projected)
                                               .ST_Reverse_Linestring()
                                               .geom);

         -- Vertex will be inserted at the beginning ...
         v_vertex.id := 1;
      End If;
      -- Convert sdo_gtype and sdo_elem_info based on whether parallel created circular arcs
      if ( &&INSTALL_SCHEMA..T_GEOMETRY(v_tgeom,SELF.tolerance,SELF.dPrecision,SELF.projected).ST_hasCircularArcs()>0 ) Then
         v_elem_info := mdsys.sdo_elem_info_array(1,1005,v_rgeom.sdo_elem_info.COUNT/3);
         v_elem_info.EXTEND(v_tgeom.sdo_elem_info.COUNT);
         FOR i IN 4..v_tgeom.sdo_elem_info.COUNT LOOP
            v_elem_info(i) := v_tgeom.sdo_elem_info(i-3);
         END LOOP;
         v_tgeom.sdo_gtype     := SELF.ST_Dims()*1000+3;
         v_tgeom.sdo_elem_info := v_elem_info;
      Else
         v_tgeom.sdo_gtype     := SELF.ST_Dims()*1000+3;
         v_tgeom.sdo_elem_info := mdsys.sdo_elem_info_array(1,1003,1);
      End If;
      v_tgeom  := &&INSTALL_SCHEMA..T_GEOMETRY(v_tgeom,SELF.tolerance,SELF.dPrecision,SELF.projected)
                     .ST_InsertVertex(&&INSTALL_SCHEMA..T_Vertex(v_vertex)).geom;
      if ( v_rgeom is null ) then
         v_rgeom := v_tgeom;
      Else
         /* CONCAT_LINES destroys compound element descriptions, so use APPEND */
         v_rgeom := MDSYS.SDO_UTIL.APPEND(v_rgeom,v_tgeom);
      End If;
    END LOOP for_all_linestrings_in_multi;
    Return &&INSTALL_SCHEMA..T_GEOMETRY(v_rgeom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_OneSidedBuffer;

-- ========================================================================================
-- =========================== LRS Related Functions ======================================
-- ========================================================================================

  Member Function ST_Lrs_Dim
           Return Integer
  As
  Begin
     return case when SELF.geom is not null then SELF.GEOM.Get_LRS_Dim() else null end;
  End ST_Lrs_Dim;

  Member Function ST_LRS_isMeasured
           Return Integer
  Is
  Begin
     return case when SELF.geom is not null
            then CASE WHEN SELF.Geom.Get_LRS_Dim() <> 0
                      THEN 1
                      ELSE 0
                  END
            else null
        end;
  End ST_LRS_isMeasured;

  Member Function ST_LRS_Start_Measure
           Return Number
  As
    c_i_not_geom       CONSTANT INTEGER       := -20121;
    c_s_not_geom       CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance CONSTANT INTEGER       := -20122;
    c_s_null_tolerance CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';
  Begin
    -- Only makes sense to snap a point to a linestring
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','(Multi)Linestring'),TRUE);
    End If;
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;
    if ( SELF.ST_Lrs_Dim() = 0 ) Then
       return 0.0;
       -- raise_application_error(c_i_not_measured,c_s_not_measured,true);
    End If;
    return SELF.geom.sdo_ordinates(SELF.ST_Lrs_Dim());
  End ST_LRS_Start_Measure;

  Member Function ST_LRS_End_Measure(p_unit in varchar2 default null)
           Return Number
  As
    c_i_not_geom       CONSTANT INTEGER       := -20121;
    c_s_not_geom       CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance CONSTANT INTEGER       := -20122;
    c_s_null_tolerance CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';
  Begin
    -- Only makes sense to snap a point to a linestring
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','(Multi)Linestring'),TRUE);
    End If;
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;
    if ( SELF.ST_Lrs_Dim() = 0 ) Then
       return SELF.ST_Length(p_unit);
       --raise_application_error(c_i_not_measured,c_s_not_measured,true);
    End If;
    return SELF.geom.sdo_ordinates(SELF.geom.sdo_ordinates.COUNT-(SELF.ST_Dims()-SELF.ST_Lrs_Dim()));
  End ST_LRS_End_Measure;

  Member Function ST_LRS_Measure_Range(p_unit in varchar2 default null)
           Return Number
  As
    c_i_not_geom       CONSTANT INTEGER       := -20121;
    c_s_not_geom       CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance CONSTANT INTEGER       := -20122;
    c_s_null_tolerance CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';
    v_s_measure        number;
    v_e_measure        number;
    v_s_vertex         &&INSTALL_SCHEMA..T_Vertex;
    v_e_vertex         &&INSTALL_SCHEMA..T_vertex;
  Begin
    -- Only makes sense to measure a linestring
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','(Multi)Linestring'),TRUE);
    End If;
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;
    v_s_vertex := SELF.ST_StartVertex();
    v_e_vertex := SELF.ST_EndVertex();
    v_s_measure := case SELF.ST_Lrs_Dim()
                   when 0 then 0.0
                   when 3 then v_s_vertex.z
                   when 4 then v_s_vertex.w
                   end;
    v_e_measure := case SELF.ST_Lrs_Dim()
                   when 0 then NVL(SELF.ST_LRS_End_Measure(p_unit),0.0)
                   when 3 then v_e_vertex.z
                   when 4 then v_e_vertex.w
                   end;
    -- dbms_output.put_line('ST_LRS_Measure_Range(' || SELF.ST_Lrs_Dim() || ' ' || v_e_measure ||' - ' || v_s_measure);
    Return ( v_e_measure - v_s_measure);
  End ST_LRS_Measure_Range;

  Member Function ST_LRS_Measure_To_Percentage(p_measure IN NUMBER   DEFAULT 0,
                                               p_unit    in varchar2 default null)
           Return Number
  As
    c_i_not_geom       CONSTANT INTEGER       := -20121;
    c_s_not_geom       CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance CONSTANT INTEGER       := -20122;
    c_s_null_tolerance CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';
    v_s_measure        number;
    v_e_measure        number;
    v_s_vertex         &&INSTALL_SCHEMA..T_Vertex;
    v_e_vertex         &&INSTALL_SCHEMA..T_Vertex;
  Begin
    -- Only makes sense to snap a point to a linestring
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','(Multi)Linestring'),TRUE);
    End If;
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;
    v_s_vertex := SELF.ST_StartVertex();
    v_e_vertex := SELF.ST_EndVertex();
    v_s_measure := case SELF.ST_Lrs_Dim()
                   when 0 then SELF.ST_LRS_Start_Measure()
                   when 3 then v_s_vertex.z
                   when 4 then v_s_vertex.w
                   end;
    v_e_measure := case SELF.ST_Lrs_Dim()
                   when 0 then SELF.ST_LRS_End_Measure(p_unit)
                   when 3 then v_e_vertex.z
                   when 4 then v_e_vertex.w
                   end;
    return ( ( NVL(p_measure,0) - v_s_measure )
           / (      v_e_measure - v_s_measure /* range */ ) ) * 100.0;
  End ST_LRS_Measure_To_Percentage;

  Member Function ST_LRS_Percentage_To_Measure(p_percentage IN NUMBER DEFAULT 0,
                                               p_unit       in varchar2 default null)
           Return Number
  As
  Begin
    Return SELF.ST_LRS_Start_Measure() + ( (p_percentage / 100.0 ) * SELF.ST_LRS_Measure_Range(p_unit) );
  End ST_LRS_Percentage_To_Measure;

  Member Function ST_LRS_Is_Measure_Increasing
           Return varchar2
  As
    c_i_not_geom       CONSTANT INTEGER       := -20121;
    c_s_not_geom       CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance CONSTANT INTEGER       := -20122;
    c_s_null_tolerance CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';
    v_vertices         mdsys.vertex_set_type;
    v_prev             number := -99999999999999999999999;
    v_measure          number;
  Begin
    -- Only makes sense to snap a point to a linestring
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','(Multi)Linestring'),TRUE);
    End If;
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;
    if ( SELF.ST_Lrs_Dim() = 0 ) Then
        return 'TRUE';
    End If;
    v_vertices := mdsys.sdo_util.getVertices(SELF.geom);
    FOR i IN v_vertices.FIRST..v_vertices.LAST LOOP
       If ( SELF.ST_Lrs_Dim() = 3 ) then
          v_measure := v_vertices(i).z;
       else
          v_measure := v_vertices(i).w;
       end if;
       if ( v_measure < v_prev ) then
          return 'FALSE';
       end If;
       v_prev := v_measure;
    END LOOP;
    RETURN 'TRUE';
  End ST_LRS_Is_Measure_Increasing;

  Member Function ST_LRS_Is_Measure_Decreasing
           Return varchar2
  As
  Begin
    RETURN case when SELF.ST_LRS_Is_Measure_Increasing() = 'TRUE'
                then 'FALSE'
                else 'TRUE'
            end;
  End ST_LRS_Is_Measure_Decreasing ;

  Member Function ST_LRS_Is_Shape_Pt_Measure(p_measure IN NUMBER)
           Return Varchar2
  As
    c_i_not_geom   CONSTANT INTEGER       := -20121;
    c_s_not_geom   CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    v_lrs_ordinate          pls_integer;
    v_num_coordinates       pls_integer;
    v_ord_dims              pls_integer;
    v_ord                   pls_integer;
    v_Is_Measure_Increasing varchar2(10);
    v_Is_Measure_Decreasing varchar2(10);
  Begin
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','(Multi)Linestring'),TRUE);
    End If;
    IF ( p_measure is null ) THEN
      RETURN 'FALSE';
    END IF;
    v_lrs_ordinate := SELF.ST_Lrs_Dim();
    IF (v_lrs_ordinate = 0) THEN
      RETURN 'FALSE';
    END IF;
    v_Is_Measure_Increasing := SELF.ST_lrs_Is_Measure_Increasing();
    v_Is_Measure_Decreasing := SELF.ST_lrs_Is_Measure_Decreasing();
    v_ord_dims              := SELF.ST_Dims();
    v_num_coordinates       := SELF.ST_NumVertices();
    v_ord                   := v_lrs_ordinate;
    FOR i IN 1..v_num_coordinates loop
      IF ( SELF.geom.sdo_ordinates(v_ord) = p_measure ) THEN
        RETURN 'TRUE';
      ELSIF ( v_Is_Measure_Increasing='TRUE' ) THEN
        IF (p_measure < SELF.geom.sdo_ordinates(v_ord) ) THEN
          RETURN 'FALSE';
        END IF;
      ELSIF ( v_Is_Measure_Decreasing='TRUE' ) THEN 
        IF ( p_measure > SELF.geom.sdo_ordinates(v_ord) ) THEN
          RETURN 'FALSE';
        END IF;
      END IF;
      v_ord := v_ord + v_ord_dims;
    END LOOP;
    RETURN 'FALSE';
  End ST_LRS_Is_Shape_Pt_Measure;

  Member Function ST_LRS_Reverse_Measure
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    c_i_not_geom       Constant Integer       := -20121;
    c_s_not_geom       Constant Varchar2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance Constant Integer       := -20122;
    c_s_null_tolerance Constant Varchar2(100) := 'Geometry tolerance must not be null';
    c_i_not_measured   Constant Integer       := -20123;
    c_s_not_measured   Constant Varchar2(100) := 'Geometry is not measured.';
  Begin
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;
    -- Only makes sense to snap a point to a linestring
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','(Multi)Linestring'),TRUE);
    End If;
    if ( SELF.ST_Lrs_Dim() = 0 ) Then
       raise_application_error(c_i_not_measured,
                               c_s_not_measured,true);
    End If;
    RETURN SELF.ST_LRS_Scale_Measures(SELF.ST_LRS_End_Measure(),
                                      SELF.ST_LRS_Start_Measure());
  End ST_LRS_Reverse_Measure;

  Member Function ST_LRS_Reset_Measure
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    c_i_not_geom       CONSTANT INTEGER       := -20121;
    c_s_not_geom       CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance CONSTANT INTEGER       := -20122;
    c_s_null_tolerance CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';
    c_i_not_measured   CONSTANT INTEGER       := -20123;
    c_s_not_measured   CONSTANT VARCHAR2(100) := 'Geometry is not measured.';
    V_Ordinates        mdsys.Sdo_Ordinate_Array;
    v_ord              pls_integer;
  Begin
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;
    -- Only makes sense to reset measure on a measured linestring
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','(Multi)Linestring'),TRUE);
    End If;
    if ( SELF.ST_Lrs_Dim() = 0 ) Then
       raise_application_error(c_i_not_measured,c_s_not_measured,true);
    End If;
    IF ( SELF.geom.sdo_ordinates is not null ) THEN
      v_ordinates   := new mdsys.sdo_ordinate_array(1);
      v_ordinates.DELETE;
      v_ordinates.EXTEND(SELF.geom.sdo_ordinates.count);
      -- Process all coordinates
      <<while_vertex_to_process>>
      FOR v_i IN 1..(v_ordinates.COUNT/SELF.ST_Dims()) LOOP
         v_ord := (v_i-1)*SELF.ST_Dims() + 1;
         v_ordinates(v_ord) := SELF.geom.sdo_ordinates(v_ord);
         v_ord := v_ord + 1; v_ordinates(v_ord) := SELF.geom.sdo_ordinates(v_ord);
         if ( SELF.ST_Dims() >= 3 ) Then
            v_ord := v_ord + 1;
            V_Ordinates(v_ord) := Case when SELF.ST_Lrs_Dim() = 3
                                       then NULL
                                       else SELF.geom.sdo_ordinates(v_ord)
                                    End;
            if ( SELF.ST_Dims() > 3 ) Then
               v_ord := v_ord + 1;
               v_ordinates(v_ord) := Case when SELF.ST_Lrs_Dim() = 4
                                          then NULL
                                          else SELF.geom.sdo_ordinates(v_ord)
                                      End;
            End If;
         End If;
      END LOOP while_vertex_to_process;
    END IF;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(mdsys.sdo_geometry(SELF.geom.sdo_gtype,
                                         SELF.geom.sdo_srid,
                                         SELF.geom.sdo_point,
                                         SELF.geom.sdo_elem_info,
                                         V_Ordinates),
                      SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_LRS_Reset_Measure;

  Member Function ST_LRS_Update_Measures(p_start_measure IN NUMBER,
                                         p_end_measure   IN NUMBER,
                                         p_unit          IN VARCHAR2 DEFAULT NULL)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    c_i_not_geom        CONSTANT INTEGER       := -20121;
    c_s_not_geom        CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance  CONSTANT INTEGER       := -20122;
    c_s_null_tolerance  CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';
    c_i_not_measured    CONSTANT INTEGER       := -20123;
    c_s_not_measured    CONSTANT VARCHAR2(100) := 'Geometry is not measured.';
    v_return_geom       &&INSTALL_SCHEMA..T_GEOMETRY;
    v_ord               pls_integer;
    v_measure_range     number;
    v_previous_measure  number := 0.0;
    v_line_length       number;
    v_segment_length    number;
    v_cumulative_length number;
    v_segments           &&INSTALL_SCHEMA..t_Segments;
  Begin
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','(Multi)Linestring'),TRUE);
    End If;
    if ( SELF.ST_Lrs_Dim() = 0 ) Then
       raise_application_error(c_i_not_measured,c_s_not_measured,true);
    End If;

    If ( p_start_measure is null and p_end_measure is null ) Then
      RETURN SELF.ST_LRS_Reset_Measure;
    End If;

    v_measure_range     := p_end_measure - p_start_measure;
    v_line_length       := SELF.ST_Length(p_unit);
    v_cumulative_length := 0.0;

    -- Get all segments
    v_segments := SELF.ST_Segmentize(p_filter=>'ALL');
    -- Now process the results
    If ( v_segments is not null and v_segments.COUNT > 0 ) Then
      -- DEBUG dbms_output.put_line('v_segments.COUNT=' || v_segments.COUNT);
      FOR v_i in v_segments.FIRST..v_segments.LAST LOOP
        -- DEBUG dbms_output.put_line('PIPE ROW ' || v_segments(v_segment).ST_AsText());
        v_segment_length := v_segments(v_i).ST_Length(p_unit=>p_unit);
        IF (v_i = v_segments.FIRST) Then
          v_previous_measure := p_start_measure + ( v_measure_range * ( v_segment_Length / v_line_length ) );
          IF (SELF.ST_Lrs_Dim() = 3) THEN
            v_segments(v_i).startCoord.z := p_start_measure;
            v_segments(v_i).endCoord.z   := v_previous_measure;
          ELSIF (SELF.ST_Lrs_Dim() = 4) THEN
            v_segments(v_i).startCoord.w := p_start_measure;
            v_segments(v_i).startCoord.w := v_previous_measure;
          END IF;
          v_return_geom := &&INSTALL_SCHEMA..T_Geometry(v_segments(v_i).ST_SdoGeometry(SELF.ST_Dims()),SELF.tolerance,SELF.dPrecision,SELF.projected);
          CONTINUE;
        ELSIF (v_i = v_segments.LAST) Then
          IF (SELF.ST_Lrs_Dim() = 3) THEN
            v_segments(v_i).startCoord.z := v_previous_measure;
            v_segments(v_i).endCoord.z   := p_end_measure;
          ELSIF (SELF.ST_Lrs_Dim() = 4) THEN
            v_segments(v_i).startCoord.w := v_previous_measure;
            v_segments(v_i).endCoord.w   := p_end_measure;
          END IF;
          v_return_geom := v_return_geom.ST_Add_Segment(v_segments(v_i));
        ELSE
          v_cumulative_length := v_cumulative_length + v_segment_length;
          IF (SELF.ST_Lrs_Dim() = 3) THEN
            v_segments(v_i).startCoord.z := v_previous_measure;
            v_segments(v_i).endCoord.z   := p_start_measure + ( v_measure_range * ( v_cumulative_length / v_line_length ) );
            v_previous_measure := v_segments(v_i).endCoord.z;
          ELSIF (SELF.ST_Lrs_Dim() = 4) THEN
            v_segments(v_i).startCoord.w := v_previous_measure;
            v_segments(v_i).endCoord.w   := p_start_measure + ( v_measure_range * ( v_cumulative_length / v_line_length ) );
            v_previous_measure := v_segments(v_i).endCoord.w;
          END IF;
          v_return_geom := v_return_geom.ST_Add_Segment(v_segments(v_i));
        END IF;
      END LOOP;
    End If;  -- v_segments not null and count > 0
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(v_return_geom.geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_LRS_Update_Measures;

  Member Function ST_LRS_Scale_Measures(p_start_measure IN NUMBER,
                                        p_end_measure   IN NUMBER ,
                                        p_shift_measure IN NUMBER DEFAULT 0.0 )
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    c_i_not_geom          Constant Integer       := -20121;
    c_s_not_geom          Constant Varchar2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance    Constant Integer       := -20122;
    c_s_null_tolerance    Constant Varchar2(100) := 'Geometry tolerance must not be null';
    c_i_not_measured      Constant Integer       := -20123;
    c_s_not_measured      Constant Varchar2(100) := 'Geometry is not measured.';
    c_i_start_end_measure Constant Integer       := -20124;
    c_s_start_end_measure Constant Varchar2(100) := 'Start/End measures must be provided.';

    v_ordinates          mdsys.sdo_ordinate_array;
    v_ord                pls_integer;
    v_vertex             pls_integer;
    v_num_vertices       pls_integer;
    v_shift_measure      number := NVL(p_shift_measure,0.0);
    v_delta_measure      number;
    v_measure_range      number;
    v_new_measure_range  number;
    v_sum_new_measure    number := 0.0;
    v_orig_start_measure number;
    v_orig_end_measure   number;
  Begin
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','(Multi)Linestring'),TRUE);
    End If;
    if ( SELF.ST_Lrs_Dim() = 0 ) Then
       raise_application_error(c_i_not_measured,c_s_not_measured,true);
    End If;
    If ( p_start_measure is null OR p_end_measure is null ) Then
       raise_application_error(c_i_start_end_measure,
                               c_s_start_end_measure,TRUE);
    End If;

    v_num_vertices       := mdsys.sdo_util.GetNumVertices(SELF.geom);

    v_new_measure_range  := p_end_measure - p_start_measure;
    v_orig_start_measure := SELF.geom.sdo_ordinates(SELF.ST_Lrs_Dim())  /* first measure */;
    v_orig_end_measure   := SELF.geom.sdo_ordinates(SELF.geom.sdo_ordinates.COUNT-(SELF.ST_Dims()-SELF.ST_Lrs_Dim())); /* Last measure */
    If ( v_orig_end_measure is null and v_orig_start_measure is null ) Then
      RETURN SELF.ST_LRS_Update_Measures(p_start_measure => p_start_measure,
                                         p_end_measure   => p_end_measure,
                                         p_unit          => NULL);
    End If;

    v_measure_range := v_orig_end_measure - v_orig_start_measure;

    v_ordinates     := new mdsys.sdo_ordinate_array(1);
    v_ordinates.DELETE;
    v_ordinates.EXTEND(SELF.geom.sdo_ordinates.count);
    v_ordinates(1) := SELF.geom.sdo_ordinates(1);  -- X
    v_ordinates(2) := SELF.geom.sdo_ordinates(2);  -- Y
    if ( SELF.ST_Lrs_Dim() = 3 ) Then
       v_ordinates(3) := p_start_measure + v_shift_measure;
       if ( SELF.ST_Dims() > 3 ) Then
          v_ordinates(4) := SELF.geom.sdo_ordinates(4);
       End If;
    ElsIf ( SELF.ST_Lrs_Dim() = 4 ) Then
       v_ordinates(3) := SELF.geom.sdo_ordinates(3);
       v_ordinates(4) := p_start_measure  + v_shift_measure;
    end if;
    v_ord := SELF.ST_Dims() + 1;

    FOR i IN 2..v_num_vertices LOOP
        v_ordinates(v_ord) := SELF.geom.sdo_ordinates(v_ord); v_ord := v_ord + 1;
        v_ordinates(v_ord) := SELF.geom.sdo_ordinates(v_ord); v_ord := v_ord + 1;
        -- DEBUG dbms_output.put_line('((i-1)*SELF.ST_Dims() + SELF.ST_Lrs_Dim())='||to_char(((i-1)*SELF.ST_Dims() + SELF.ST_Lrs_Dim())));
        v_delta_measure    := SELF.geom.sdo_ordinates((i-1)*SELF.ST_Dims() + SELF.ST_Lrs_Dim()) -
                              SELF.geom.sdo_ordinates((i-2)*SELF.ST_Dims() + SELF.ST_Lrs_Dim());
        v_sum_new_measure  := v_sum_new_measure + ( v_delta_measure / v_measure_range ) * v_new_measure_range;
        IF ( SELF.ST_Lrs_Dim() = 3 ) THEN
           v_ordinates(v_ord) := p_start_measure + v_shift_measure + v_sum_new_measure; v_ord := v_ord + 1;
           IF ( SELF.ST_Dims() > 3 ) Then
              v_ordinates(v_ord) := SELF.geom.sdo_ordinates(v_ord); v_ord := v_ord + 1;
           End If;
        ElsIf ( SELF.ST_Lrs_Dim() = 4 ) Then
           v_ordinates(v_ord) := SELF.geom.sdo_ordinates(v_ord); v_ord := v_ord + 1;
           v_ordinates(v_ord) := p_start_measure + v_shift_measure + v_sum_new_measure; v_ord := v_ord + 1;
        end if;
    END LOOP;
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(mdsys.sdo_geometry(SELF.geom.sdo_gtype,
                                         SELF.geom.sdo_srid,
                                         SELF.geom.sdo_point,
                                         SELF.geom.sdo_elem_info,
                                         V_Ordinates),
                      SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_LRS_Scale_Measures;

  Member Function ST_LRS_Concatenate(p_lrs_segment IN mdsys.sdo_geometry,
                                     p_unit        in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    c_i_not_geom     Constant Integer       := -20121;
    c_s_not_geom     Constant Varchar2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_not_measured Constant Integer       := -20123;
    c_s_not_measured Constant Varchar2(100) := 'Geometry is not measured.';
    c_i_srid_unequal Constant Integer       := -20124;
    c_s_srid_unequal Constant Varchar2(100) := 'SRIDs are not equal.';
    v_lrs_geometry   &&INSTALL_SCHEMA..T_GEOMETRY;
    v_new_geometry   &&INSTALL_SCHEMA..T_GEOMETRY;
  Begin
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','(Multi)Linestring'),TRUE);
    End If;
    If ( SELF.ST_Lrs_Dim() = 0 ) Then
       raise_application_error(c_i_not_measured,c_s_not_measured,true);
    End If;

    -- Check input
    IF ( p_lrs_segment is null ) THEN
      Return SELF;
    END IF;

    v_lrs_geometry := &&INSTALL_SCHEMA..T_GEOMETRY(p_lrs_segment,SELF.tolerance,SELF.dPrecision,SELF.projected);
    If ( v_lrs_geometry.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',v_lrs_geometry.ST_GeometryType()),
                                         '*GTYPE2*','(Multi)Linestring'),TRUE);
    End If;
    If ( v_lrs_geometry.ST_Lrs_Dim() = 0 ) Then
       raise_application_error(c_i_not_measured,c_s_not_measured,true);
    End If;
    IF ( NVL(SELF.ST_SRID(),-1) <> NVL(v_lrs_geometry.ST_SRID(),-1) ) THEN
       raise_application_error(c_i_srid_unequal,c_s_srid_unequal,true);
    END IF;

    v_new_geometry := SELF.ST_Concat_Line(p_lrs_segment);
    /* SGG Removed Measure Update
    IF ( SELF.ST_LRS_Start_Measure() = v_new_geometry.ST_LRS_Start_Measure() ) THEN
      -- p_lrs_segment was appended to SELF
      RETURN v_new_geometry.ST_LRS_Update_Measures(p_start_measure => SELF.ST_LRS_Start_Measure(),
                                                   p_end_measure   => (SELF.ST_LRS_Measure_Range() + v_lrs_geometry.ST_LRS_Measure_Range()),
                                                   p_unit          => p_unit);
    ELSIF ( v_lrs_geometry.ST_LRS_Start_Measure() = v_new_geometry.ST_LRS_Start_Measure() ) THEN
      -- SELF was appended to end of p_lrs_segment
      RETURN v_new_geometry.ST_LRS_Update_Measures(p_start_measure => v_lrs_geometry.ST_LRS_Start_Measure(),
                                                   p_end_measure   => (SELF.ST_LRS_Measure_Range() + v_lrs_geometry.ST_LRS_Measure_Range()),
                                                   p_unit          => p_unit);
    END IF;
    */
    RETURN &&INSTALL_SCHEMA..T_GEOMETRY(v_new_geometry.geom,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_LRS_Concatenate;

  Member Function ST_LRS_Find_Offset(p_point in mdsys.sdo_geometry,
                                     p_unit  in varchar2 default null)
          Return Number
  As
    c_i_not_geom       CONSTANT INTEGER       := -20121;
    c_s_not_geom       CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance CONSTANT INTEGER       := -20122;
    c_s_null_tolerance CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';
    v_radius           number := 0;
    v_offset           number := 0;
    v_vertices         mdsys.vertex_set_type;
    v_vertex           &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(), p_sdo_srid  => SELF.ST_SRID());
    v_centre           &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(), p_sdo_srid  => SELF.ST_SRID());
    v_segment          &&INSTALL_SCHEMA..T_Segment;
    v_segments         &&INSTALL_SCHEMA..T_Segments;
    v_lineDist         number;
    v_geom             &&INSTALL_SCHEMA..T_GEOMETRY;
    v_segment_bearing  NUMBER;
    v_vertex_bearing   NUMBER;
  Begin
    -- Check inputs
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;
    -- Only makes sense to snap a point to a linestring
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','Linestring'),TRUE);
    End If;
    If ( p_point  is null ) Then
       return null;
    End If;

    If (p_point.get_gtype()=1 And p_point.sdo_point is not null) Then
      v_vertex := &&INSTALL_SCHEMA..T_Vertex(
                    p_point     => p_point.sdo_point,
                    p_sdo_gtype => p_point.sdo_gtype,
                    p_sdo_srid  => p_point.sdo_srid);
    Else
      v_vertex := &&INSTALL_SCHEMA..T_Vertex(p_point); -- sdo_gtype/sdo_srid set from sdo_geometry; first vertex if geometry <> x001
    End If;

    -- DEBUG dbms_output.put_line('v_point vertex is ' || v_point.ST_AsText());
    -- Find nearest segment and compute offset
    --
    If (&&INSTALL_SCHEMA..TOOLS.ST_DB_Version() >= 11.1
        AND
        SELF.ST_hasCircularArcs()=0 ) Then
      v_segments := SELF.ST_Segmentize(p_filter => 'DISTANCE',
                                       p_vertex => v_vertex,
                                       p_unit   => p_unit);
      IF ( v_segments IS NOT NULL and v_segments.COUNT > 0 ) THEN
        -- Find minimum
        v_offset := v_segments(1).ST_Distance(p_vertex    => v_vertex,
                                              p_unit      => p_unit);
        v_offset := SIGN(v_segments(1).startCoord.ST_SubtendedAngle(v_vertex,v_segments(1).endCoord)) * v_offset;
        IF ( v_segments.COUNT > 1 ) THEN
          FOR rec in 1 .. v_segments.COUNT LOOP
            v_lineDist :=
              v_segments(rec).ST_Distance(p_vertex    => v_vertex,
                                          p_unit      => p_unit);
            v_offset := LEAST(SIGN(v_segments(rec).startCoord.ST_SubtendedAngle(v_vertex,v_segments(rec).endCoord)) * v_lineDist);
          END LOOP;
        END IF;
        RETURN v_offset;
      END IF;
    END IF;

    SELECT      line,   lineDist
      INTO v_segment, v_lineDist
      FROM (SELECT f.line,f.lineDist,min(f.lineDist) over (order by 1) as minDist
              FROM (SELECT seg.ST_Self() as line,
                           seg.ST_Distance(p_vertex    => &&INSTALL_SCHEMA..T_Vertex(p_point),
                                           p_unit      => p_unit) as linedist
                     FROM TABLE(SELF.ST_Segmentize(p_filter=>'ALL')) seg
                  ) f
           ) g
     WHERE g.linedist = g.minDist
       AND g.line is not null
       AND ROWNUM < 2;

    -- DEBUG dbms_output.put_line('v_lineDist is ' || v_lineDist);
    If ( v_lineDist = 0 ) THen
       Return 0;
    ElsIf (v_segment.midCoord is not null and v_segment.midCoord.x is not null) Then
       -- Compute left/right via radius
       v_centre := v_segment.ST_FindCircle(); -- z holds radius
       v_radius := v_centre.z;
       v_centre.z := null;
       -- compute distance from centre to p_geom ie v_point
       -- If distance to vertex from centre is > radius it is on the left else right
       -- TOBEDONE: EXCEPT we have to take into account which way circular arc is curving...
       --
       v_offset := SIGN(v_radius -
                        v_centre.ST_Distance(p_vertex=>v_vertex,p_tolerance=>SELF.tolerance,p_unit=>p_unit)) * v_lineDist;
    Else
       v_offset := SIGN(v_segment.startCoord.ST_SubtendedAngle(v_vertex,v_segment.endCoord)) * v_lineDist;
    End If;
    Return v_offset;
  End ST_LRS_Find_Offset;

  -- p_measureN  : PLS_INTEGER : Particular measure to be returned. 0 = all possible measures, 1 is the first etc.
  Member Function ST_LRS_Find_Measure(p_geom     in mdsys.sdo_geometry,
                                      p_measureN in integer  default 1,
                                      p_unit     in varchar2 default null)
           Return mdsys.sdo_ordinate_array
  Is
    c_i_not_geom       CONSTANT INTEGER       := -20121;
    c_s_not_geom       CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance CONSTANT INTEGER       := -20122;
    c_s_null_tolerance CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';
    c_i_wrong_measure  Constant Integer       := -20123;
    c_s_wrong_measure  Constant VarChar2(100) := 'p_measureN must be greater or equal to 0.';

    v_geom             &&INSTALL_SCHEMA..T_GEOMETRY;
    v_geometry         &&INSTALL_SCHEMA..T_GEOMETRY;
    v_geometries       &&INSTALL_SCHEMA..T_GEOMETRIES;
    v_vertices         mdsys.vertex_set_type;
    v_point            mdsys.sdo_geometry;
    v_snap_point       &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(), p_sdo_srid  => SELF.ST_SRID());
    v_vertex           &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(), p_sdo_srid  => SELF.ST_SRID());
    v_measure          number;
    v_measures         mdsys.sdo_ordinate_array := new mdsys.sdo_ordinate_array();
    v_measureN         pls_integer := NVL(p_measureN,1);
  Begin
    -- DEBUG dbms_output.put_line('START: ST_LRS_Find_Measure(p_geom,'||v_measureN||','||NVL(p_unit,'NULL')||')');
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;
    if ( v_measureN < 0 ) Then
       raise_application_error(c_i_wrong_measure,
                               c_s_wrong_measure,TRUE);
    End If;
    -- We only sense snap a point to a linestring
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','Linestring'),TRUE);
    End If;
    -- test p_geom using constructor
    v_geom := &&INSTALL_SCHEMA..T_GEOMETRY(p_geom,SELF.tolerance,SELF.dPrecision,SELF.projected);
    -- DEBUG dbms_output.put_line('ST_LRS_Find_Measure: ' || p_geom.sdo_gtype || ' ' || v_geom.ST_Dimension());
    If ( v_geom.ST_Dimension() <> 0 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','Point'),TRUE);
    End If;

    -- Use getVertices to convert passed in point/multipoint to a set of single vertices
    --
    v_vertices := mdsys.sdo_util.getVertices(p_geom);
    if ( v_vertices is null or v_vertices.COUNT = 0 ) Then
       -- DEBUG dbms_output.put_line('v_vertices is null or 0');
       RETURN null;
    End If;
    -- DEBUG dbms_output.put_line('v_vertices.COUNT='||v_vertices.COUNT);

    -- v_vertices.COUNT is 1 if single point, or N when N points in a multipoint
    FOR v IN 1..v_vertices.COUNT LOOP
      v_vertex := &&INSTALL_SCHEMA..T_Vertex(
                    p_vertex    => v_vertices(v),
                    p_sdo_gtype => p_geom.sdo_gtype,
                    p_sdo_srid  => p_geom.sdo_SRID);
      -- DEBUG dbms_output.put_line('v_vertex is ' || v_vertex.ST_AsText());
      -- DEBUG dbms_output.put_line('v_measureN=' || v_measureN);
      v_geometries := SELF.ST_Snap(v_vertex.ST_SdoGeometry(),p_unit);
      -- DEBUG dbms_output.put_line('v_vertex point (' || v_vertex.ST_AsText(SELF.dPrecision) || ') has been snapped returning ' || v_geometries.COUNT || ' points.');
      IF ( v_geometries is not null AND v_geometries.COUNT > 0 ) THEN
        IF ( v_geometries.COUNT = 1 ) Then
          -- DEBUG dbms_output.put_line('SELF.ST_Lrs_Dim() = ' || SELF.ST_Lrs_Dim());
          v_snap_point := &&INSTALL_SCHEMA..T_Vertex(p_point => v_geometries(1).geometry); -- gtype/srid set from geom; extracts first point only
          -- DEBUG dbms_output.put_line('v_snap_point=' || v_snap_point.St_AsText() || ' Returning: ' || case when v_snap_point.ST_Lrs_Dim() in (0,3) then v_snap_point.z else v_snap_point.w end);
          -- DEBUG dbms_output.put_line('END ST_LRS_Find_Measure()');
          Return new mdsys.sdo_ordinate_array(case when v_snap_point.ST_Lrs_Dim() in (0,3) then v_snap_point.z else v_snap_point.w end);
        ELSIF ( v_geometries.COUNT > 1 ) THEN
          FOR i IN v_geometries.FIRST..v_geometries.LAST
          LOOP
            -- DEBUG dbms_output.put_line('v_geometries('||i||')');
            IF ( v_measureN = 0 or v_measureN = i ) Then
              -- DEBUG dbms_output.put_line('Constructing v_snap_point ' || case when v_geometries(i).geometry is null then 'NULL' else 'NN' end);
              v_snap_point := &&INSTALL_SCHEMA..T_Vertex(p_point => v_geometries(i).geometry); -- gtype/srid set from geom; extracts first point only
              -- DEBUG dbms_output.put_line('v_snap_point=' || v_snap_point.ST_AsText());
              -- DEBUG dbms_output.put_line('v_snap_point ST_Lrs_Dim=' ||  SELF.ST_Lrs_Dim() || ' measure =' || case when SELF.ST_Lrs_Dim() in (0,3) then 'Z='||v_snap_point.z else 'W='||v_snap_point.w end);
              v_measures.EXTEND(1);
              v_measures(v_measures.COUNT) := case when v_snap_point.ST_Lrs_Dim() in (0,3) then v_snap_point.z else v_snap_point.w end;
              IF ( v_measureN = i ) Then -- Terminate as we have found the required measure
                 return new mdsys.sdo_ordinate_array(v_measures(v_measures.COUNT));
              End If;
            End If;
          END LOOP;
        END IF;
      END If;
    END LOOP;
    -- DEBUG dbms_output.put_line('END ST_LRS_Find_Measure()');
    Return v_measures;
  End ST_LRS_Find_Measure;

  Member Function ST_LRS_Find_MeasureN(p_geom     in mdsys.sdo_geometry,
                                       p_measureN in integer  default 1,
                                       p_unit     in varchar2 default null)
           Return Number
  As
    v_measureN  pls_integer := NVL(p_measureN,1);
    v_measure   Number;
  BEGIN
    -- Inputs checked in ST_LRS_Find_Measure
    select t.column_value
      into v_measure
      from Table(SELF.ST_LRS_Find_Measure(p_geom,v_measureN,p_unit)) t
     where rownum < 2;
    Return v_measure;
  End ST_LRS_Find_MeasureN;

  Member Function ST_LRS_Get_Measure
           Return number
  As
    c_i_not_geom CONSTANT INTEGER       := -20121;
    c_s_not_geom CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
  Begin
    -- Only work on points
    If ( SELF.ST_Dimension() <> 0 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','Point'),TRUE);
    End If;
    IF ( SELF.ST_LRS_isMeasured() <> 1 ) THEN
      RETURN NULL;
    END IF;
    IF ( SELF.ST_LRS_Dim() = 3 ) THEN
      IF (SELF.geom.SDO_POINT is not null) Then
        RETURN SELF.geom.SDO_POINT.Z;
      END IF;
    END IF;
    IF ( SELF.geom.SDO_ORDINATES is null ) THEN
      RETURN NULL;
    END IF;
    RETURN SELF.geom.sdo_ordinates(SELF.ST_LRS_Dim());
  End ST_LRS_Get_Measure;

  Member Function ST_LRS_Project_Point(P_Point In Mdsys.Sdo_Geometry,
                                       p_unit  In varchar2    Default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    c_i_not_geom       CONSTANT INTEGER       := -20121;
    c_s_not_geom       CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance CONSTANT INTEGER       := -20122;
    c_s_null_tolerance CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';

    v_geom       &&INSTALL_SCHEMA..T_GEOMETRY;
    v_geometries &&INSTALL_SCHEMA..T_GEOMETRIES;
    v_point      mdsys.sdo_geometry;
  Begin
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;
    -- Only makes sense to snap a geom to a linestring
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','Linestring'),TRUE);
    End If;
    v_geometries := SELF.ST_Snap(p_point,p_unit);
    if ( v_geometries is null or v_geometries.COUNT=0 ) Then
       Return null;
    end If;
    Return &&INSTALL_SCHEMA..T_GEOMETRY(v_geometries(1).geometry,SELF.Tolerance,SELF.dPrecision,SELF.Projected);
  End ST_LRS_Project_Point;

  Member Function ST_LRS_Locate_Measure(p_measure in number,
                                        p_offset  in number default 0,
                                        p_unit    in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    c_i_not_geom       CONSTANT INTEGER       := -20121;
    c_s_not_geom       CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance CONSTANT INTEGER       := -20122;
    c_s_null_tolerance CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';

    v_extract_geom      mdsys.sdo_geometry;
    v_num_elements      pls_integer := 0;
    v_centre            &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
    v_offset            &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
    v_vertex            &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
    v_coord             &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
    v_ratio_along_line  number;
    v_segment_length     number;
    v_cum_measure       number := 0;
    v_start_measure     number := 0;
    v_mid_measure       number;
    v_end_measure       number;
    v_measure_ord       pls_integer;
    v_coord_dimension   pls_integer;
    v_segments           &&INSTALL_SCHEMA..T_Segments;
  Begin
    -- DEBUG dbms_output.put_line('ST_LRS_Locate_Measure');
    -- Only makes sense to snap a point to a linestring
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','(Multi)Linestring'),TRUE);
    End If;
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;
    v_coord_dimension := SELF.ST_Dims();
    v_measure_ord     := SELF.ST_Lrs_Dim();
    v_num_elements    := SELF.ST_NumElements();
    <<for_all_elements>>
    for v_element in 1..v_num_elements loop
        v_extract_geom := mdsys.sdo_util.extract(SELF.geom,v_element,0);
        -- Get candidate set of segments from v_extract_geom
        --
        v_segments := &&INSTALL_SCHEMA..T_GEOMETRY(v_extract_geom,SELF.tolerance,SELF.dPrecision,SELF.projected)
                          .ST_Segmentize(p_filter=>'ALL');
        If (v_segments is null or v_segments.COUNT = 0 ) Then
            return null;
        End If;
        -- iterate over candidate segments
        <<for_all_arcSegments_in_element>>
        FOR i IN v_segments.FIRST..v_segments.LAST
        LOOP
            -- DEBUG dbms_output.put_line('v_segment(' || i || ')=' || v_segments(i).ST_AsText());
            if (  v_measure_ord = 0 ) Then
               v_start_measure := v_cum_measure;
               v_segment_length := v_segments(i).ST_Length(p_unit=>p_unit);
               v_cum_measure   := v_cum_measure + v_segment_length;
               v_end_measure   := v_cum_measure;
               if ( v_segments(i).midCoord is not null ) Then
                  v_ratio_along_line := v_segment_length *
                                       (&&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_segments(i).startCoord,v_segments(i).midCoord)) /
                                        &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_segments(i).startCoord,v_segments(i).EndCoord)));
                  v_mid_measure   := v_ratio_along_line * v_segment_length;
               end if;
            Elsif ( v_measure_ord = 3 ) Then
               v_start_measure := v_segments(i).startCoord.z;
               v_mid_measure   := case when v_segments(i).midCoord is not null then v_segments(i).midCoord.z else null end;
               v_end_measure   := v_segments(i).endCoord.z;
            Elsif ( v_measure_ord = 4 ) Then
               v_start_measure := v_segments(i).startCoord.w;
               v_mid_measure   := case when v_segments(i).midCoord is not null then v_segments(i).midCoord.w else null end;
               v_end_measure   := v_segments(i).endCoord.w;
            End If;

            -- Is measure at start point of a segment?
            --
            If ( ROUND(p_measure,SELF.dPrecision) = ROUND(v_start_measure, SELF.dPrecision) ) Then
                -- DEBUG dbms_output.put_line('p_measure (' ||p_measure || ') = ROUND(v_start_measure, SELF.dPrecision) (' || ROUND(v_start_measure, SELF.dPrecision)|| ')');
                If ( i = 1 ) Then
                    v_ratio_along_line := 0.0;
                    -- DEBUG dbms_output.put_line('Falls on starting vertex of whole linestring');
                    v_vertex := v_segments(i).ST_OffsetPoint(p_ratio     => v_ratio_along_line,
                                                             p_offset    => p_offset,
                                                             p_unit   => p_unit);
                    if ( v_measure_ord=0 ) Then
                       If ( v_coord_dimension=2 ) Then
                           v_vertex.z := p_measure;
                           v_vertex.sdo_gtype := 3001;
                       ElsIf ( v_coord_dimension=3 ) Then
                           v_vertex.w := p_measure;
                           v_vertex.sdo_gtype := 4001;
                       End If;
                    Elsif ( v_measure_ord=3 ) Then
                       v_vertex.z := p_measure;
                    ElsIf ( v_measure_ord=4 ) Then
                       v_vertex.w := p_measure;
                    End If;
                    -- DEBUG dbms_output.put_line('START v_vertex=' || v_vertex.ST_AsText());
                    return &&INSTALL_SCHEMA..T_GEOMETRY(v_vertex.ST_SdoGeometry(),SELF.Tolerance,SELF.dPrecision,SELF.Projected);
                Else
                    -- DEBUG dbms_output.put_line('Starts on vertex between two segments need to calculate bisector');
                    If ( NVL(p_offset,0) <> 0) Then
                        -- DEBUG dbms_output.put_line('Calculating ST_OffsetBetween');
                        v_offset := v_segments(i-1).ST_OffsetBetween(v_segments(i),
                                                                     p_offset,
                                                                     p_unit);
                        return &&INSTALL_SCHEMA..T_GEOMETRY(v_offset.ST_SdoGeometry(),SELF.Tolerance,SELF.dPrecision,SELF.Projected);
                     Else -- no offset just return point
                        return &&INSTALL_SCHEMA..T_GEOMETRY(v_segments(i).startCoord.ST_SdoGeometry(),SELF.Tolerance,SELF.dPrecision,SELF.Projected);
                     End If;
                End If;

            -- Is measure at mid point of circular arc?
            --
            ElsIf ( ROUND(p_measure,SELF.dPrecision) = ROUND(v_mid_measure,SELF.dPrecision) ) Then
                -- DEBUG dbms_output.put_line('p_measure (' ||p_measure || ') = ROUND(v_mid_measure, SELF.dPrecision) (' || ROUND(v_mid_measure, SELF.dPrecision)|| ')');
                -- DEBUG dbms_output.put_line('v_mid_measure (' ||v_mid_measure || ') - v_start_measure (' || v_start_measure || ') = ' || (v_mid_measure - v_start_measure));
                -- DEBUG dbms_output.put_line('v_end_measure (' ||v_end_measure || ') - v_start_measure (' || v_start_measure || ') = ' || (v_end_measure - v_start_measure));
                v_ratio_along_line := (v_mid_measure - v_start_measure) / (v_end_measure - v_start_measure);
                v_vertex := v_segments(i).ST_OffsetPoint(v_ratio_along_line,
                                                         p_offset,
                                                         p_unit
                                           );
                if ( v_measure_ord=0 ) Then
                   If ( v_coord_dimension=2 ) Then
                       v_vertex.z := p_measure;
                       v_vertex.sdo_gtype := 3001;
                   ElsIf ( v_coord_dimension=3 ) Then
                       v_vertex.w := p_measure;
                       v_vertex.sdo_gtype := 4001;
                   End If;
                Elsif ( v_measure_ord=3 ) Then
                   v_vertex.z := p_measure;
                ElsIf ( v_measure_ord=4 ) Then
                   v_vertex.w := p_measure;
                End If;
                -- DEBUG dbms_output.put_line('MID v_vertex=' || v_vertex.ST_AsText());
                return &&INSTALL_SCHEMA..T_GEOMETRY(v_vertex.ST_SdoGeometry(),SELF.Tolerance,SELF.dPrecision,SELF.Projected);

            -- Is measure at end point?
            --
            ElsIf ( ROUND(p_measure,SELF.dPrecision) = ROUND(v_end_measure,SELF.dPrecision) ) Then

                -- If last segment return end point offset
                -- Else leave till next loop for processing as a startCoord
                --
                If ( i = v_segments.COUNT ) Then
                    -- DEBUG dbms_output.put_line('p_measure (' ||p_measure || ') = ROUND(v_end_measure, SELF.dPrecision) (' || ROUND(v_end_measure, SELF.dPrecision)|| ')');

                    -- Falls on End Vertex of whole linestring
                    v_ratio_along_line := 1.0;
                    -- DEBUG dbms_output.put_line('BEFORE ST_OffsetPoint - v_vertex=' || v_vertex.ST_AsText());
                    v_vertex := v_segments(i).ST_OffsetPoint(v_ratio_along_line,
                                                             p_offset,
                                                             p_unit
                                              );
                    if ( v_measure_ord=0 ) Then
                       If ( v_coord_dimension=2 ) Then
                           v_vertex.z := p_measure;
                           v_vertex.sdo_gtype := 3001;
                       ElsIf ( v_coord_dimension=3 ) Then
                           v_vertex.w := p_measure;
                           v_vertex.sdo_gtype := 4001;
                       End If;
                    Elsif ( v_measure_ord=3 ) Then
                       v_vertex.z := p_measure;
                    ElsIf ( v_measure_ord=4 ) Then
                       v_vertex.w := p_measure;
                    End If;
                    -- DEBUG dbms_output.put_line('AFTER ST_OffsetPoint v_vertex=' || v_vertex.ST_AsText());
                    return &&INSTALL_SCHEMA..T_GEOMETRY(v_vertex.ST_SdoGeometry(),SELF.Tolerance,SELF.dPrecision,SELF.Projected);
                End If;

            ElsIf ( ROUND(p_measure,SELF.dPrecision)
                    BETWEEN    LEAST(ROUND(v_start_measure,SELF.dPrecision),ROUND(v_end_measure,SELF.dPrecision))
                        AND Greatest(ROUND(v_start_measure,SELF.dPrecision),ROUND(v_end_measure,SELF.dPrecision) ) ) Then
                -- DEBUG dbms_output.put_line('BETWEEN: Calculating new position (measure - cumulative) / segment_length');
                v_ratio_along_line := (p_measure - v_start_measure ) / (v_end_measure - v_start_measure);
                -- DEBUG dbms_output.put_line('         v_ratio_along_line='|| v_ratio_along_Line);
                -- DEBUG dbms_output.put_line('BEFORE ST_OffsetPoint - v_vertex=' || case when v_vertex is null then 'NULL' else v_vertex.ST_AsText() end);
                v_vertex := v_segments(i).ST_OffsetPoint(v_ratio_along_line,
                                                         p_offset,
                                                         p_unit);
                IF ( v_vertex is null ) Then
                  -- DEBUG dbms_output.put_line('AFTER ST_OffsetPoint - v_vertex IS NULL');
                  CONTINUE;
                END IF;
                -- DEBUG dbms_output.put_line('BETWEEN p_measure = ' || p_measure ||  ' v_start_measure=' || v_start_measure ||  ' v_end_measure=' || v_end_measure || ' v_vertex=' || v_vertex.ST_AsText());
                if ( v_measure_ord=0 ) Then
                   If ( v_coord_dimension=2 ) Then
                       v_vertex.z := p_measure;
                       v_vertex.sdo_gtype := 3001;
                   ElsIf ( v_coord_dimension=3 ) Then
                       v_vertex.w := p_measure;
                       v_vertex.sdo_gtype := 4001;
                   End If;
                Elsif ( v_measure_ord=3 ) Then
                   v_vertex.z := p_measure;
                ElsIf ( v_measure_ord=4 ) Then
                   v_vertex.w := p_measure;
                End If;
                -- DEBUG dbms_output.put_line('AFTER ST_OffsetPoint v_vertex=' || v_vertex.ST_AsText());
                Return &&INSTALL_SCHEMA..T_GEOMETRY(v_vertex.ST_SdoGeometry(),SELF.Tolerance,SELF.dPrecision,SELF.Projected);
            End If;
        End Loop for_all_arcSegments_in_element;
    end loop for_all_elements;
    return NULL;
  End ST_LRS_Locate_Measure;

  /* Wrapper */
  Member Function ST_LRS_Locate_Point(p_measure in number,
                                      p_offset  in number default 0)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
  Begin
    RETURN SELF.ST_LRS_Locate_Measure(p_measure=>p_measure,p_offset=>p_offset);
  ENd ST_LRS_Locate_Point;

  /** Internal Utility Function */
  Member Function ST_LRS_Locate_Measures(p_start_measure in number,
                                         p_end_measure   in number,
                                         p_offset        in number default 0,
                                         p_unit          in varchar2 default null)
  Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    c_i_not_geom       CONSTANT INTEGER       := -20121;
    c_s_not_geom       CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';
    c_i_null_tolerance CONSTANT INTEGER       := -20122;
    c_s_null_tolerance CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';
    c_i_rev_measured   CONSTANT INTEGER       := -20123;
    c_s_rev_measured   CONSTANT VARCHAR2(100) := 'Geometries with reversed measured currently not handled. Reverse before use.';

    v_num_elements            pls_integer := 0;
    v_centre                  &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
    v_offset                  &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
    v_vertex                  &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
    v_coord                   &&INSTALL_SCHEMA..T_Vertex := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype => SELF.ST_sdo_gtype(),p_sdo_srid  => SELF.ST_SRID());
    v_start_ratio_along_line  number;
    v_end_ratio_along_line    number;
    v_ratio_along_line        number;
    v_segment_length          number;
    v_cum_measure             number := 0;
    v_start_measure           number;
    v_mid_measure             number;
    v_end_measure             number;
    v_user_start_measure      number;
    v_user_end_measure        number;
    v_LineEndMeasure          number       := SELF.ST_LRS_End_Measure(p_unit);
    v_LineMeasureIncreasing   varchar2(10) := SELF.ST_LRS_Is_Measure_Increasing();
    v_tolerance               number       := NVL(SELF.tolerance, case when SELF.projected = 1 then 0.0005 else 0.005 end);
    v_precision               pls_integer  := NVL(SELF.dPrecision,case when SELF.projected = 1 then 3 else 8 end);
    v_cDimensions             pls_integer  := SELF.ST_Dims();
    v_mDimension              pls_integer  := SELF.ST_LRS_Dim();
    v_numSegments             pls_integer;
    v_ord                     pls_integer;
    v_segments                &&INSTALL_SCHEMA..T_Segments;
    v_segment                 &&INSTALL_SCHEMA..T_Segment := &&INSTALL_SCHEMA..T_Segment(
                                      p_sdo_gtype => SELF.ST_sdo_gtype(),
                                      p_sdo_srid  => SELF.ST_SRID(),
                                      p_projected => SELF.projected,
                                      p_precision => SELF.dPrecision,
                                      p_tolerance => SELF.tolerance );
    v_prev_segment            &&INSTALL_SCHEMA..T_Segment := &&INSTALL_SCHEMA..T_Segment(
                                      p_sdo_gtype => SELF.ST_sdo_gtype(),
                                      p_sdo_srid  => SELF.ST_SRID(),
                                      p_projected => SELF.projected,
                                      p_precision => SELF.dPrecision,
                                      p_tolerance => SELF.tolerance );
    v_return_geom             &&INSTALL_SCHEMA..T_geometry;
    v_tgeometry               &&INSTALL_SCHEMA..T_geometry;
    v_extract_geom            mdsys.sdo_geometry;
    v_geom                    mdsys.sdo_geometry;
  Begin
    -- Only makes sense to snap a point to a linestring
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','(Multi)Linestring'),TRUE);
    End If;
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;

    if ( v_LineMeasureIncreasing <> 'TRUE' ) Then
       raise_application_error(c_i_rev_measured,
                               c_s_rev_measured,true);
    End If;

    v_user_start_measure := NVL(p_start_measure,0);
    If ( ( v_LineEndMeasure     < v_user_start_measure ) OR
         ( NVL(p_end_measure,0) < v_user_start_measure ) ) Then
       -- Nothing to do.
       Return NULL;
    End If;

    v_user_end_measure := NVL(p_end_measure,v_LineEndMeasure);
    If ( v_user_start_measure =  v_user_end_measure ) Then
       -- Single point
       Return SELF.ST_LRS_Locate_Measure(p_measure => p_start_measure,
                                         p_offset  => p_offset,
                                         p_unit    => p_unit);
    End If;

    v_num_elements := SELF.ST_NumElements();
    -- DEBUG dbms_output.put_line('ST_LRS_Locate_Measures(' || p_start_measure || ',' || p_end_measure ||','||NVL(p_offset,0)||','||NVL(p_unit,'NO UNIT')||'), dPrecision=' || v_precision || ', tolerance=' || v_tolerance);
    -- DEBUG dbms_output.put_line('<FOR_ALL_ELEMENTS>');
    <<for_all_elements>>
    for v_element in 1..v_num_elements loop
        v_extract_geom := mdsys.sdo_util.Extract(SELF.geom,v_element,0);
        -- DEBUG dbms_output.put_line('.. Processing Element ' || v_element || ' of ' || v_num_elements);
        v_tGeometry := &&INSTALL_SCHEMA..T_GEOMETRY(v_extract_geom,v_tolerance,v_precision,SELF.projected);

        -- Do we need to processing this element?
        If ( SELF.ST_GType() = 6 AND v_tGeometry.ST_LRS_End_Measure(p_unit) < NVL(p_start_measure,0) ) Then  -- What if Measure Descending /ascending
          -- DEBUG dbms_output.put_line('... Element does not need processing...');
          v_return_geom := &&INSTALL_SCHEMA..T_GEOMETRY(case when v_element = 1 Then v_extract_geom else mdsys.sdo_util.Append(v_return_geom.geom,v_extract_geom) end,
                                               v_tolerance,v_precision,SELF.projected);
          v_return_geom.geom.sdo_gtype := SELF.geom.sdo_gtype;
          CONTINUE;
          -- DEBUG dbms_output.put_line('... v_return_geom = ' || v_return_geom.ST_AsText(2));
        End If;

        If ( v_tGeometry.ST_HasCircularArcs() = 0 ) Then
          -- Short Circular segment generation to improve speed.
          v_segments := SELF.ST_Segmentize(p_filter      =>'RANGE',
                                           p_start_value =>v_user_start_measure,
                                           p_end_value   =>v_user_end_measure,
                                           p_unit        =>p_unit);
        Else /* v_tGeometry.ST_HasCircularArcs() = 1 */
          -- DEBUG dbms_output.put_line('... Extract Candidate segments from extracted geometry (Segment Count=TO BE DONE)'); -- ' || v_tGeometry.ST_NumSegments() || ')');
          SELECT f.line
            BULK COLLECT
            INTO v_segments
            FROM (SELECT v.line,
                         case when v.isM = 1
                              then &&INSTALL_SCHEMA..T_GEOMETRY(v.line.ST_SdoGeometry(),v_tolerance).ST_LRS_Start_Measure()
                              else cumLength - v.line.ST_Length(p_unit=>p_unit)
                          end as start_m,
                         case when v.isM = 1
                              then &&INSTALL_SCHEMA..T_GEOMETRY(v.line.ST_SdoGeometry(),v_tolerance).ST_LRS_End_Measure(p_unit)
                              else cumLength
                          end as end_m
                    FROM (SELECT v_tgeometry.ST_LRS_isMeasured() isM,
                                 seg.ST_Self() as line,
                                 SUM(seg.ST_Length(p_unit=>p_unit))
                                    Over (partition by 1 order by seg.segment_Id) as cumLength
                            FROM TABLE( v_tgeometry.ST_Segmentize(p_filter=>'ALL') ) seg
                          ) v
                 ) f
           WHERE  /* measure Range Overlap = max(start1, start2) < min(end1, end2) */
                 (   v_LineMeasureIncreasing = 'TRUE'
                 AND Greatest(f.start_m,v_user_start_measure)
                      < Least(f.end_m,  v_user_end_measure) );

        End If;

        -- DEBUG dbms_output.put_line('.... Candidate segment Count: ' || case when v_segments is null then 0 else v_segments.count end);

        -- Test result
        If (v_segments is null or v_segments.COUNT = 0 ) Then
          -- Move to next element ...
          continue;
        End If;

        -- iterate over segments of this extracted geom
        -- DEBUG dbms_output.put_line(' <FOR_ALL_ARCSegmentS_IN_ELEMENT 1 .. ' || v_segments.count||'>');
        <<for_all_arcSegments_in_element>>
        FOR i IN 1 .. v_segments.COUNT
        LOOP
            -- DEBUG dbms_output.put_line('  v_segments(' || i || ').ST_AsText(4)='||v_segments(i).ST_AsText(3));
            -- DEBUG If ( v_prev_segment.ST_isEmpty() = 0 ) Then dbms_output.put_line('        v_prev_segment.ST_AsText(3)='||v_prev_segment.ST_AsText(3)); End If;
            if ( SELF.ST_Lrs_Dim() = 0 ) Then  -- Length based
               v_start_measure  := v_cum_measure;
               v_segment_length := v_segments(i).ST_Length(p_unit=>p_unit);
               v_cum_measure    := v_cum_measure + v_segment_length;
               v_end_measure    := v_cum_measure;
               if ( v_segments(i).midCoord is not null ) Then
                  v_ratio_along_line := v_segment_length *
                                       (&&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_segments(i).startCoord,v_segments(i).midCoord)) /
                                        &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_segments(i).startCoord,v_segments(i).EndCoord)));
                  v_mid_measure   := v_ratio_along_line * v_segment_length;
               end if;
            Elsif (  SELF.ST_Lrs_Dim() = 3 ) Then
               v_start_measure := v_segments(i).startCoord.z;
               v_mid_measure   := case when v_segments(i).midCoord is not null then v_segments(i).midCoord.z else null end;
               v_end_measure   := v_segments(i).endCoord.z;
            Else
               v_start_measure := v_segments(i).startCoord.w;
               v_mid_measure   := case when v_segments(i).midCoord is not null then v_segments(i).midCoord.w else null end;
               v_end_measure   := v_segments(i).endCoord.w;
            End If;

            -- DEBUG dbms_output.put_line('  v_start_measure='||v_start_measure || ' p_start_measure=' || NVL(p_start_measure,0));
            -- DEBUG dbms_output.put_line('    v_end_measure='||v_end_measure   || '   p_end_measure=' || NVL(p_end_measure,SELF.ST_LRS_End_Measure(p_unit)));

            v_start_ratio_along_line := ROUND((v_user_start_measure-v_start_measure) / (v_end_measure-v_start_measure),6);
            v_end_ratio_along_line   := ROUND((v_user_end_measure  -v_start_measure) / (v_end_measure-v_start_measure),6);

            -- DEBUG dbms_output.put_line('  Process start measure which is somewhere along this segment');
            --
            If ( v_start_ratio_along_line <= 0.0 ) Then
               -- Start of segment
               If ( i = 1 ) Then
                 -- start of whole line just offset the point
                 v_segment.startCoord := v_segments(i)
                                         .ST_OffsetPoint(0.0,
                                                         p_offset,
                                                         p_unit)
                                         .ST_Round(v_precision);
               Else
                  -- A previous segment is split by the start measure so adopt its last endCoord
                  -- DEBUG if ( v_prev_segment.ST_isEmpty() = 1 ) Then dbms_output.put_line('  v_prev_segment is EMPTY'); End If;
                  v_segment.startCoord := v_prev_segment.endCoord;
               End If;
               -- DEBUG dbms_output.put_line('  v_start_ratio_along_line('||v_start_ratio_along_line||') <= 0.0');
            ElsIf ( v_start_ratio_along_line < 1.0 ) Then
               -- start measure splits this segment along itself so create/offset calcualted point
               v_segment.startCoord := v_segments(i)
                                       .ST_OffsetPoint(v_start_ratio_along_line,
                                                       p_offset,
                                                       p_unit)
                                       .ST_Round(v_precision);
               -- DEBUG dbms_output.put_line('  v_start_ratio_along_line('||v_start_ratio_along_line||') < 1.0 =>');
            ElsIf ( v_start_ratio_along_line = 1.0 ) Then
               -- measure is at end of segment.
               if ( i = v_segments.COUNT ) Then
                   -- There is no next segment, so return offset at the end point
                   v_segment.startCoord := v_segments(i)
                                           .ST_OffsetPoint(1.0,
                                                           p_offset,
                                                           p_unit)
                                           .ST_Round(v_precision);
              Else
                 -- There is a next segment so compute new endCoord that can be used by next segment
                 v_segment.endCoord := v_segments(i)
                                       .ST_OffsetBetween(v_segments(i+1),
                                                         p_offset,
                                                         p_unit)
                                      .ST_Round(v_precision);
                 -- start coord of this segment becomes same as endCoord reducing it to a single point
                 v_segment.startCoord := v_segment.endCoord;
               End If;
               -- DEBUG dbms_output.put_line('  v_start_ratio_along_line('||v_start_ratio_along_line||') = 1.0');
            ELse -- ratio > 1.0 means this segment is not affected by start measure
               NULL;
            End If;
            -- DEBUG dbms_output.put_line('  segment After StartCoord Processing=' || v_segment.ST_AsText(3));

            If ( v_segments(i).midCoord is not null and v_segments(i).midCoord.x is not null) Then
               -- DEBUG dbms_output.put_line('  Process midCoord...');
               If ( v_mid_measure between v_start_measure and v_end_measure )  Then
                 v_segment.midCoord := v_segments(i)
                                       .ST_OffsetPoint((v_mid_measure - v_start_measure) / (v_end_measure - v_start_measure),
                                                       p_offset,
                                                       p_unit)
                                       .ST_Round(v_precision);
               End If;
              -- DEBUG dbms_output.put_line('  v_segment After MidCoord Processing='||v_segment.midCoord.ST_AsText());
            End If;

            -- DEBUG dbms_output.put_line('  Process EndPoint ...');
            If ( v_end_ratio_along_line < 0.0 ) Then
                -- Should be impossible given SQL
                NULL;
            ElsIf ( v_end_ratio_along_line = 0.0 ) Then
                -- Same as start coord for this segment
                v_segment.endCoord := v_segment.startCoord;
                -- DEBUG dbms_output.put_line('  v_end_ratio_along_line('||v_end_ratio_along_line||') = 0.0');
            ElsIf ( v_end_ratio_along_line < 1.0 ) Then
               -- Along line just offset the point
               v_segment.endCoord := v_segments(i)
                                     .ST_OffsetPoint(v_end_ratio_along_line,
                                                     p_offset,
                                                     p_unit)
                                     .ST_Round(v_precision);
               -- DEBUG dbms_output.put_line('  v_end_ratio_along_line('||v_end_ratio_along_line||') < 1.0');
            ElsIf ( v_end_ratio_along_line >= 1.0 ) Then
               -- On end point or in next segment (so includes this end point)
               -- But possibly two segments
               If ( i = v_segments.COUNT ) Then
                  -- End measure is at end of whole line with no next segment
                  v_segment.endCoord := v_segments(i)
                                        .ST_OffsetPoint(1.0,
                                                        p_offset,
                                                        p_unit)
                                       .ST_Round(v_precision);
               Else
                   -- Compute new end position based on offset
                  If ( NVL(p_offset,0) = 0 ) Then
                      -- just return end coordinate
                      v_segment.endCoord := v_segments(i).endCoord;
                  Else
                      -- compute new point at angle between two segments
                      v_segment.endCoord := v_segments(i)
                                            .ST_OffsetBetween(v_segments(i+1),
                                                              p_offset,
                                                              p_unit)
                                            .ST_Round(v_precision);
                  End If;
               End If;
               -- DEBUG dbms_output.put_line('  v_end_ratio_along_line('||v_end_ratio_along_line||') >= 1.0');
            End If;

            -- DEBUG dbms_output.put_line('  segment After End Processing=' || v_segment.ST_AsText(3));

            -- DEBUG dbms_output.put_line(' Add segment to return geometry');
            --
            if (v_return_geom is null) Then
               v_return_geom := &&INSTALL_SCHEMA..T_GEOMETRY(v_segment);
               -- DEBUG dbms_output.put_line('  v_return_geom was null and now is ='||v_return_geom.ST_AsEWKT());
               v_return_geom.geom.sdo_gtype := SELF.geom.sdo_gtype;
            Else
               -- DEBUG dbms_output.put_line('v_return_geom.ST_Add_Segment(' || v_segment.ST_AsText(3) || ')');
               v_geom := v_return_geom.ST_Add_Segment(v_segment).geom;
               -- DEBUG dbms_output.put_line('v_geom (' || v_geom.sdo_gtype || ') is ' || case when v_geom is null then 'NULL' else 'NOT NULL ' || sdo_geom.validate_geometry(v_geom,v_tolerance) end );
               v_return_geom := &&INSTALL_SCHEMA..T_GEOMETRY(v_geom,v_tolerance,v_precision,SELF.projected);
            End If;
            v_prev_segment := v_segment;
            -- DEBUG IF ( i < 3 ) Then dbms_output.put_line('  v_return_geom='||v_return_geom.ST_AsEWKT()); End If;
         End Loop for_all_arcSegments_in_element;
         -- DEBUG dbms_output.put_line(' </FOR_ALL_ARCSegmentS_IN_ELEMENT>');
    end loop for_all_elements;
    -- DEBUG dbms_output.put_line('</FOR_ALL_ELEMENTS>');
    return v_return_geom;
  End ST_LRS_Locate_Measures;

  Member Function ST_LRS_Locate_Along(p_measure in number,
                                      p_offset  in number   default 0,
                                      p_unit    in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
  Begin
     Return ST_LRS_Locate_Measure(
                          p_measure => p_measure,
                          p_offset  => p_offset,
                          p_unit    => p_unit);
  End ST_LRS_Locate_Along;

  Member Function ST_LRS_Locate_Between(p_start_measure in number,
                                        p_end_measure   in number,
                                        p_offset        in number   default 0,
                                        p_unit          in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
  Begin
     Return ST_LRS_Locate_Measures(
                   p_start_measure => p_start_measure,
                   p_end_measure   => p_end_measure,
                   p_offset        => p_offset,
                   p_unit          => p_unit);
  End ST_LRS_Locate_Between;

  Member Function ST_LRS_Add_Measure(p_start_measure IN NUMBER Default NULL,
                                     p_end_measure   IN NUMBER Default NULL,
                                     p_unit          IN VARCHAR2 Default NULL)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    c_i_null_tolerance CONSTANT INTEGER       := -20122;
    c_s_null_tolerance CONSTANT VARCHAR2(100) := 'Geometry tolerance must not be null';
    c_i_not_geom       CONSTANT INTEGER       := -20121;
    c_s_not_geom       CONSTANT VARCHAR2(100) := 'Geometry (*GTYPE1*) is not a (*GTYPE2*)';

    v_measure_ord      pls_integer := 0;
    v_start_measure    number;
    v_end_measure      number;
    v_range_measure    NUMBER := 0;
    v_segment          &&INSTALL_SCHEMA..T_Segment := &&INSTALL_SCHEMA..T_Segment(
                                      p_sdo_gtype => SELF.ST_sdo_gtype(),
                                      p_sdo_srid  => SELF.ST_SRID(),
                                      p_projected => SELF.projected,
                                      p_precision => SELF.dPrecision,
                                      p_tolerance => SELF.tolerance );
    v_prev_segment     &&INSTALL_SCHEMA..T_Segment := &&INSTALL_SCHEMA..T_Segment(
                                      p_sdo_gtype => SELF.ST_sdo_gtype(),
                                      p_sdo_srid  => SELF.ST_SRID(),
                                      p_projected => SELF.projected,
                                      p_precision => SELF.dPrecision,
                                      p_tolerance => SELF.tolerance );
    v_centre           &&INSTALL_SCHEMA..T_Vertex  := &&INSTALL_SCHEMA..T_Vertex(p_id=>0,p_sdo_gtype=>SELF.ST_sdo_gtype(),p_sdo_srid=>SELF.ST_SRID());
    v_geom_length      NUMBER := 0;
    v_length           NUMBER := 0;
    v_arc_Angle2Mid    NUMBER := 0;
    v_arc_Length2Mid   NUMBER := 0;
    v_return_dims      pls_integer := 3;
    v_return_geom      &&INSTALL_SCHEMA..T_geometry;
    v_geom             mdsys.sdo_geometry;
    v_segment_geom     &&INSTALL_SCHEMA..T_geometry;
  Begin
    -- Only makes sense to snap a point to a linestring
    If ( SELF.ST_Dimension() <> 1 ) Then
       raise_application_error(c_i_not_geom,
                               REPLACE(
                                 REPLACE(c_s_not_geom,
                                         '*GTYPE1*',SELF.ST_GeometryType()),
                                         '*GTYPE2*','(Multi)Linestring'),TRUE);
    End If;
    if ( SELF.tolerance is null ) Then
       raise_application_error(c_i_null_tolerance,
                               c_s_null_tolerance,TRUE);
    End If;
    IF ( SELF.ST_LRS_isMeasured()=1 ) Then
       RETURN SELF;
    End If;
    -- DEBUG dbms_output.put_line('<ST_LRS_Add_Measure>');

    v_measure_ord   := SELF.ST_Dims() + 1;
    v_start_measure := NVL(p_start_measure,0);
    v_geom_length   := SELF.ST_Length(p_unit);
    v_end_measure   := NVL(p_end_measure,v_geom_length);
    v_range_measure := v_end_measure-v_start_measure;
    v_return_dims   := SELF.ST_Dims()+1;
    <<arcSegments_in_linear_geometry>>
    FOR v_rec IN (SELECT seg.ST_Self() as line
                    FROM TABLE(SELF.ST_Segmentize(p_filter=>'ALL')) seg
                   ORDER BY seg.element_id,
                            seg.subelement_id,
                            seg.segment_id )
    LOOP
        -- Compute measures for this segment
        --
        v_segment := &&INSTALL_SCHEMA..T_Segment(v_rec.line);

        -- First coord
        --
        if ( v_segment.element_id = 1 and v_segment.segment_id = 1 ) Then
           -- First segment
           if ( v_measure_ord = 3 ) Then
              v_segment.startCoord.z := v_start_measure;
           ElsIf ( v_measure_ord = 4 ) Then
              v_segment.startCoord.w := v_start_measure;
           End If;
        else
           if ( v_measure_ord = 3 ) Then
              v_segment.startCoord.z := v_prev_segment.endCoord.z;
           ElsIf ( v_measure_ord = 4 ) Then
              v_segment.startCoord.w := v_prev_segment.endCoord.w;
           End If;
        End If;

        -- v_length will be arc length if circular arc segment or just line length otherwise
        --
        v_segment_geom := &&INSTALL_SCHEMA..T_Geometry(v_rec.line.ST_SdoGeometry(),SELF.tolerance);
        v_length      := v_segment_geom.ST_Length(p_unit);
        if ( v_segment.midCoord is not null and v_segment.midCoord.x is not null ) Then
           -- Mid and End Coords.
           v_centre         := v_segment.ST_FindCircle(); -- z holds radius
           v_arc_Angle2Mid  := &&INSTALL_SCHEMA..COGO.ST_Degrees(v_centre.ST_SubtendedAngle(v_segment.startCoord,v_segment.midCoord));
           v_arc_Length2Mid := ROUND(&&INSTALL_SCHEMA..COGO.ComputeArcLength(v_centre.z,v_arc_Angle2Mid),SELF.dPrecision);
           if ( v_measure_ord = 3 ) Then
              v_segment.midCoord.z := v_segment.startCoord.z + (v_range_measure * (v_arc_length2mid/v_length));
              v_segment.endCoord.z := v_length;
           ElsIf ( v_measure_ord = 4 ) Then
              v_segment.midCoord.w := v_segment.startCoord.w + (v_range_measure * (v_arc_length2mid/v_length));
              v_segment.endCoord.w := v_length;
           End If;
        End If;
        If ( v_measure_ord = 3 ) Then
            v_segment.endCoord.z := v_segment.startCoord.z + (v_length * (v_range_measure/v_geom_length));
        ElsIf ( v_measure_ord = 4 ) Then
            v_segment.endCoord.w := v_segment.startCoord.w + (v_length * (v_range_measure/v_geom_length));
        End If;
        -- Add segment to return geometry
        --
        if (v_return_geom is null) Then
           -- DEBUG dbms_output.put_line('   Creating geometry from first segment ' || v_segment.ST_AsText());
           v_segment.sdo_gtype := (v_return_dims*1000)+(v_measure_ord*100)+SELF.ST_Gtype();
           v_return_geom := &&INSTALL_SCHEMA..T_GEOMETRY(v_segment.ST_SdoGeometry(),SELF.tolerance,SELF.dPrecision,SELF.projected);
           -- DEBUG dbms_output.put_line('  v_return_geom was null and now is ='||v_return_geom.ST_AsEWKT());
        Else
           -- DEBUG dbms_output.put_line('   Adding additional segment to geometry ' || v_segment.ST_AsText());
           -- DEBUG dbms_output.put_line('v_segment=' || v_segments(i).ST_AsText());
           v_geom := v_return_geom.ST_Add_Segment(v_segment).geom;
           -- DEBUG dbms_output.put_line('v_geom (' || v_geom.sdo_gtype || ') is ' || case when v_geom is null then 'NULL ' else 'NOT NULL ' || &&INSTALL_SCHEMA..T_GEOMETRY(v_geom,SELF.tolerance,SELF.dPrecision,SELF.projected).ST_Validate() end );
           v_return_geom := &&INSTALL_SCHEMA..T_GEOMETRY(v_geom,SELF.tolerance,SELF.dPrecision,SELF.projected);
           -- DEBUG dbms_output.put_line('  v_return_geom='||v_return_geom.ST_AsEWKT());
        End If;
        v_prev_segment := &&INSTALL_SCHEMA..T_Segment(v_segment);
      END LOOP arcSegments_in_linear_geometry;
      v_return_geom.geom.sdo_gtype := (v_return_dims*1000)+(v_measure_ord*100)+SELF.ST_Gtype();
      -- DEBUG dbms_output.put_line('</ST_LRS_Add_Measure>=' || v_return_geom.ST_AsEWKT());
      return v_return_geom;
  End ST_LRS_Add_Measure;

  Member Function ST_LRS_Valid_Measure(p_measure in number)
             Return varchar2
  As
  Begin
    RETURN case when SELF.ST_LRS_isMeasured()=1
                 and SELF.ST_LRS_Dim()>2
                 and p_measure BETWEEN SELF.ST_LRS_Start_Measure() And SELF.ST_LRS_End_Measure()
                 then 'TRUE'
                 else 'FALSE'
            end;
  End ST_LRS_Valid_Measure;

  Member Function ST_LRS_Valid_Point(p_diminfo in mdsys.sdo_dim_array)
           Return varchar2
  As
  Begin
    RETURN CASE WHEN SELF.ST_LRS_isMeasured() = 1
                 AND SELF.ST_LRS_Dim() > 0
                 AND SELF.ST_GeometryType() IN ('ST_MULTIPOINT','ST_POINT')
                 THEN CASE WHEN SELF.ST_LRS_DIM() = 3
                           THEN CASE WHEN &&INSTALL_SCHEMA..T_VERTEX(SELF.GEOM).Z IS NOT NULL
                                     THEN 'TRUE'
                                     ELSE '13335'
                                 END
                           WHEN SELF.ST_LRS_DIM() = 4
                           THEN CASE WHEN &&INSTALL_SCHEMA..T_VERTEX(SELF.GEOM).W IS NOT NULL
                                     THEN 'TRUE'
                                     ELSE '13335'
                                 END
                      END
                ELSE 'FALSE'
            END;
  End ST_LRS_Valid_Point;

  /* This function only checks for geometry type and number of dimensions of the geometric segment. */
  Member Function ST_LRS_Valid_Segment(p_diminfo in mdsys.sdo_dim_array)
           Return varchar2
  As
  Begin
    RETURN CASE WHEN SELF.ST_LRS_isMeasured() = 1
                 AND SELF.ST_LRS_Dim() > 2
                 AND SELF.ST_GeometryType() IN ('ST_MULTILINESTRING','ST_LINESTRING')
                 AND SELF.ST_LRS_Start_Measure() IS NOT NULL
                 AND SELF.ST_LRS_End_Measure()   IS NOT NULL
                THEN 'TRUE'
                ELSE CASE WHEN SELF.ST_LRS_Start_Measure() is null
                            OR SELF.ST_LRS_End_Measure() IS NULL
                          THEN '13335'  -- (measure information not defined)
                          ELSE '13331'  -- (invalid LRS segment)
                      END
            END;
  End ST_LRS_Valid_Segment;

  Member Function ST_LRS_Valid_Geometry(p_diminfo in mdsys.sdo_dim_array)
             Return varchar2
  As
  Begin
    RETURN case when SELF.ST_LRS_isMeasured()=1
                 and SELF.ST_LRS_Dim()>2
                 AND SELF.ST_GeometryType() IN ('ST_MULTILINESTRING','ST_LINESTRING')
                 AND SELF.ST_LRS_Start_Measure() is not null
                 AND SELF.ST_LRS_End_Measure() IS NOT NULL
                 then 'TRUE'
                 else 'FALSE'
             end;
  End ST_LRS_Valid_Geometry;

  Member Function ST_LRS_Intersection(p_geom In Mdsys.Sdo_Geometry,
                                      p_unit in varchar2 default null)
           Return &&INSTALL_SCHEMA..T_GEOMETRY
  As
    c_i_spatial    CONSTANT pls_integer   := -20102;
    c_s_spatial    CONSTANT VARCHAR2(100) := 'SDO_GEOM.RELATE only supported for Locator users from 12C onwards.';
    v_result_tgeom &&INSTALL_SCHEMA..T_Geometry;
    v_vertex       &&INSTALL_SCHEMA..T_Vertex;
    v_measure      number;
  Begin
    -- Underlying geometry object must be measured
    IF ( SELF.ST_LRS_isMeasured() <> 1) THEN
      RETURN SELF;
    END IF;
    -- Underlying geometry object must be a linestring
    IF ( SELF.ST_Dimension() <> 1 /*LINESTRING*/ ) THEN
      RETURN SELF;
    END IF;
    IF ( p_geom is null ) THEN
      RETURN SELF;
    END IF;
    -- DEBUG dbms_output.put_line(SELF.ST_Sdo_GType() || ',' || p_geom.sdo_gtype);
    v_result_tgeom:= SELF.ST_Intersection(p_geom,'FIRST');
    -- DEBUG dbms_output.put_line(' Result MDSYS.SDO_GEOM.sdo_intersection: '||&&INSTALL_SCHEMA..PRINT.sdo_geometry(v_result_tgeom.geom,v_result_tgeom.dPrecision));
    -- Test dimensionality of result.
    -- Will always be 3d even if point is 2D
    -- But SDO_Intersection returns 3D point with zero measure
    -- DEBUG dbms_output.put_line('v_result_tgeom.ST_Sdo_Gtype()='||v_result_tgeom.ST_Sdo_Gtype() || ' v_result_tgeom.ST_Dimension()='||v_result_tgeom.ST_Dimension() || ' v_result_tgeom.ST_AsEWKT()='||v_result_tgeom.ST_AsText(0) );
    IF ( v_result_tgeom.ST_Dimension() = 0 ) THEN
      v_result_tgeom.geom.sdo_gtype := (v_result_tgeom.ST_Dims() * 1000) +
                                       (p_geom.get_lRS_Dim() * 100) +
                                        v_result_tgeom.ST_GType();
      -- DEBUG dbms_output.put_line('v_result_tgeom.ST_Sdo_Gtype()='||v_result_tgeom.ST_Sdo_Gtype());
      -- Get measure ...
      v_measure := SELF.ST_LRS_Find_MeasureN(p_geom     => v_result_tgeom.geom,
                                             p_measureN => 1,
                                             p_unit     => p_unit);
      -- DEBUG dbms_output.put_line('v_measure='||v_measure);
      -- Assign to vertex
      v_vertex := &&INSTALL_SCHEMA..T_Vertex(v_result_tgeom.geom);
      -- DEBUG dbms_output.put_line('v_vertex='||v_vertex.ST_AsText());
      v_vertex := v_vertex.ST_LRS_Set_Measure(p_measure=>v_measure);
      -- DEBUG dbms_output.put_line('v_vertex='||v_vertex.ST_AsText()|| CHR(10));
      RETURN &&INSTALL_SCHEMA..T_Geometry(v_vertex.ST_SdoGeometry(),SELF.tolerance,SELF.dPrecision,SELF.projected);
    ELSIF ( v_result_tgeom.ST_Dims() = 3 ) THEN
      RETURN v_result_tgeom.ST_SetSdoGType(v_result_tgeom.geom.sdo_gtype + (SELF.ST_lrs_dim() * 100) );
    ELSIF ( v_result_tgeom.ST_Dims() = 4 ) THEN
      RETURN v_result_tgeom.ST_SetSdoGType(v_result_tgeom.geom.sdo_gtype + (SELF.ST_lrs_dim() * 100));
    END IF;
    RETURN &&INSTALL_SCHEMA..T_Geometry(SELF.geom,SELF.tolerance,SELF.dPrecision,SELF.projected);
  End ST_LRS_Intersection;

  -- *************************************************************************
  -- *************************************************************************
  -- *************************************************************************

  Member Function ST_Sdo_Point_Equal(p_sdo_point   in mdsys.sdo_point_type,
                                     p_z_precision in integer default 2)
           Return Integer
  As
    c_Min         CONSTANT NUMBER := -1E38;
    v_z_precision pls_integer     := NVL(p_z_precision,2);
  Begin
    If (SELF.geom.sdo_point is null and p_sdo_point is null) THEN
     Return 1;
    ElsIf ( (SELF.geom.sdo_point is     null and p_sdo_point is not null)
         or (SELF.geom.sdo_point is not null and p_sdo_point is     null) ) Then
      Return 0;
    End If;
    RETURN
      CASE WHEN ( ROUND(SELF.geom.sdo_point.x,SELF.dPrecision) = ROUND(p_sdo_point.x,SELF.dPrecision)
              AND ROUND(SELF.geom.sdo_point.y,SELF.dPrecision) = ROUND(p_sdo_point.y,SELF.dPrecision)
              AND NVL(ROUND(SELF.geom.sdo_point.z,v_z_precision),c_Min)
                = NVL(ROUND(p_sdo_point.z,        v_z_precision),c_Min))
           THEN 1
           ELSE -1
        END;
  End ST_Sdo_Point_Equal;

  Member Function ST_Elem_Info_Equal(p_elem_info in mdsys.sdo_elem_info_array)
           Return integer
  As
  Begin
    If (SELF.geom.sdo_elem_info is null and p_elem_info is null) THEN
      Return 1;
    ElsIf ( (SELF.geom.sdo_elem_info is null and p_elem_info is not null)
         or (SELF.geom.sdo_elem_info is not null AND p_elem_info is null)
         or (SELF.geom.sdo_elem_info is not null AND p_elem_info is not null
             and
             SELF.geom.sdo_elem_info.COUNT <> p_elem_info.COUNT) )  Then
      Return 0;
    End If;
    -- Compare values
    for i in 1..SELF.geom.sdo_elem_info.COUNT Loop
      IF ( SELF.geom.sdo_elem_info(i) <> p_elem_info(i) ) Then
        Return -1;
      End If;
    End Loop;
    Return 1;
  End ST_Elem_Info_Equal;

  Member Function ST_Ordinates_Equal(p_ordinates   in mdsys.sdo_ordinate_array,
                                     p_z_precision in integer default 2,
                                     p_m_precision in integer default 3)
           Return Integer
  As
    c_Min         CONSTANT NUMBER := -1E38;
    v_z_precision pls_integer     := NVL(p_z_precision,2);
    v_m_precision pls_integer     := NVL(p_m_precision,3);
  Begin
    If (SELF.geom.sdo_ordinates is null and p_ordinates is null) THEN
     Return 1;
    ElsIf ( (SELF.geom.sdo_ordinates is     null and p_ordinates is not null)
         or (SELF.geom.sdo_ordinates is not null and p_ordinates is     null)
         or (SELF.geom.sdo_ordinates is not null and p_ordinates is not null
             and
             SELF.geom.sdo_ordinates.COUNT <> p_ordinates.COUNT) ) Then
      Return 0;
    End If;
    -- Compare values
    For i in 1..SELF.geom.sdo_ordinates.COUNT Loop
      IF ( ROUND(SELF.geom.sdo_ordinates(i),SELF.dPrecision) <> 
           ROUND(p_ordinates(i),            SELF.dPrecision) ) THEN
        -- DEBUG dbms_output.put_line('SELF.geom.sdo_ordinates('||i||')=' || SELF.geom.sdo_ordinates(i) || ' <> p_ordinates('||i||')='|| p_ordinates(i));
        Return -1;
      END IF;
    End Loop;
    Return 1;
  End ST_Ordinates_Equal;

  Member Function ST_Equals(p_geometry    in mdsys.sdo_Geometry,
                            p_z_precision in integer default 2,
                            p_m_precision in integer default 3)
           Return varchar2
  As
    -- Returns EQUAL or FAIL:DIMS,SDO_GTYPE,SDO_SRID,SDO_POINT,SDO_ELEM_INFO,SDO_ORDINATES
    c_i_dims  CONSTANT pls_integer   := -20101;
    c_s_dims  CONSTANT VARCHAR2(100) := 'Coordinate Dimensions are not equal';
    not_licensed EXCEPTION;
    PRAGMA       EXCEPTION_INIT(not_licensed,-20102);
    v_determine varchar2(50);
  Begin
    IF ( p_geometry is null and SELF.geom is null ) THEN
      Return 'EQUAL';
    END IF;

    IF ( ( SELF.geom is     null and p_geometry is not null)
      or ( SELF.geom is not null and p_geometry is     null) ) THEN
      Return 'FAIL:NULL';
    END IF;

    IF ( SELF.ST_Dims() <> p_geometry.get_dims() ) THEN
      Return 'FAIL:DIMS';
    End If;

    IF ( SELF.ST_Dims() < 3 ) THEN
     BEGIN
      v_determine := SUBSTR(
                        SELF.ST_Relate(p_geom      => p_geometry,
                                       p_Determine => 'DETERMINE'),
                        1,50);
      Return case when v_determine = 'EQUAL'
                  then 'EQUAL'
                  else 'FAIL:' || v_determine
              end ;
      EXCEPTION
        WHEN not_licensed THEN
          NULL;  -- Fall through to comparison below.
     END;
    END IF;

    IF ( SELF.geom.sdo_gtype is null
      OR p_geometry.sdo_gtype is null
      OR NVL(SELF.geom.sdo_gtype,-1) <> NVL(p_geometry.sdo_gtype,-1) ) THEN
      Return 'FAIL:SDO_GTYPE';
    END IF;
    IF NVL(SELF.geom.sdo_srid,   -1) <> NVL(p_geometry.sdo_srid,-1) THEN
      Return 'FAIL:SDO_SRID';
    END IF;
    IF ( SELF.ST_Sdo_Point_Equal(p_sdo_point => p_geometry.sdo_point) IN (-1,0) ) THEN
      Return 'FAIL:SDO_POINT';
    End If;
    IF ( SELF.ST_Elem_Info_Equal(p_elem_info => p_geometry.sdo_elem_info) IN (-1,0) ) Then
      Return 'FAIL:SDO_ELEM_INFO';
    End If;
    IF ( SELF.ST_Ordinates_Equal(p_ordinates   => p_geometry.sdo_ordinates,
                                 p_z_precision => p_z_precision,
                                 p_m_precision => p_m_precision) IN (-1,0) ) THEN
      Return 'FAIL:SDO_ORDINATES';
    End If;
    RETURN 'EQUAL';
  End ST_Equals;

  Order Member Function orderBy(p_compare_geom in &&INSTALL_SCHEMA..T_GEOMETRY)
                 Return number
  Is
     v_point         sdo_point_type;
     v_compare_point sdo_point_type;
  Begin
        If (SELF.geom is null)      Then return -1;
     ElsIf (p_compare_geom is null) Then return 1;
     End If;
     -- get Sort Point
     if ( SELF.geom.sdo_point is not null ) then
       v_point := sdo_point_type(SELF.geom.sdo_point.x,
                                 SELF.geom.sdo_point.y,
                                 null);
     else
       v_point := sdo_point_type(SELF.geom.sdo_ordinates(1),
                                 SELF.geom.sdo_ordinates(2),
                                 null);
     end if;
     if ( p_compare_geom.geom.sdo_point is not null ) then
       v_compare_point := sdo_point_type(p_compare_geom.geom.sdo_point.x,
                                         p_compare_geom.geom.sdo_point.y,
                                         null);
     else
       v_compare_point := sdo_point_type(p_compare_geom.geom.sdo_ordinates(1),
                                         p_compare_geom.geom.sdo_ordinates(2),
                                         null);
     end if;
     -- Where x or y < compared x y, return negative number
     -- Where x or y > compared x y, return positive number
        If ( V_Point.X < V_Compare_Point.X ) Then Return -2;
     ElsIf ( V_Point.X = V_Compare_Point.X
         AND V_Point.Y < V_Compare_Point.Y ) Then Return -1;
     ElsIf ( V_Point.X > V_Compare_Point.X ) Then Return  1;
     Else                                         Return  2;
     End If;
  End orderBy;

END;

/
SHOW ERRORS

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := FALSE;
   v_obj_name varchar2(30) := 'T_GEOMETRY';
BEGIN
   FOR rec IN (select object_name,object_Type, status
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'TYPE BODY'
               order by object_type
              )
   LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is valid.');
         v_ok := TRUE;
      ELSE
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is invalid.');
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

EXIT SUCCESS;
