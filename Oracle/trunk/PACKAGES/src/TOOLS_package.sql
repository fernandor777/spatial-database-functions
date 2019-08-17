DEFINE defaultSchema='&1'

SET VERIFY OFF;

ALTER SESSION SET plsql_optimize_level=1;

CREATE OR REPLACE PACKAGE TOOLS
AUTHID CURRENT_USER
Is

   TYPE T_Strings IS TABLE OF VARCHAR2(4000);
    
   Function isCompound( p_sdo_elem_info in mdsys.sdo_elem_info_array )
     return integer deterministic;

   /*** @function    Execute_Statement
   **   @description Executes a SQL statement capturing errors.
   **   @param       p_sql     The SQL statement to be executed.
   **   @param       p_display Whether to write any errors to dbms_output.
   **/
   Procedure Execute_Statement( p_sql     IN VarChar2,
                                p_display IN Boolean := FALSE);

   /*** @function    GeometryCheck
   **   @description Procedure that processes the supplied object looking
   **                for errors and correcting where possible.
   **                Writes activity to FEATURE_ERRORS table.
   **   @param       p_schema      The owner of the table/geometry column data.
   **   @param       p_tableName   The table holding the geometry data to be checked.
   **   @param       p_ColumnName  The sdo_geometry column in the table to be checked.
   **   @param       p_whereClause A predicate to limit the activity to specific rows.
   **/
   Procedure GeometryCheck( p_schema        IN VarChar2,
                            p_tableName     IN VarChar2,
                            p_ColumnName    IN VarChar2,
                            p_whereClause   IN VarChar2);

   /** @function    VertexAnalyzer
   *   @description Function that computes basic statistics about the geometries in a table.
   *   The stats computed are:
   *     - Max,
   *     - Min
   *     - Avg number of vertices.
   * @param p_owner       Schema that owns the table.
   * @param p_table_regex Regular expression of the tables to be processed.
   **/
   Procedure VertexAnalyzer( p_owner       In VarChar2 := NULL,
                             p_table_regex IN VarChar2 := '*',
                             p_activity    In Out NoCopy &&defaultSchema..TOOLS.T_Strings );

   /** @function    hasData
   *   @description Simply checks if the table has any data in it.
   *   @param       p_table_name : varchar2 : Object name.
   *   @param       p_owner      : varchar2 : The schema that holds the table.
   */
   Function hasData( p_table_name In VarChar2,
                     p_owner      In VarChar2 := NULL)
     Return Boolean Deterministic;

   /** @function    Generate_Object_Name
   *   @description Generates index/constraint name following a fixed pattern.
   *   @param       p_object_name   : varchar2 : Object name normally a table.
   *   @param       p_column_name   : varchar2 : Normally the name of a column.
   *   @param       p_obj_shortname : varchar2 : An abbreviation of the object
   *   @param       p_col_shortname : varchar2 : An abbreviation of the column
   *   @param       p_prefix        : varchar2 : A prefix normally of a few chars in length.
   *   @param       p_suffix        : varchar2 : A suffix normally of a few chars in length.
   *   @param       p_name_length   : varchar2 : Max length of the desired name.
   **/
   Function Generate_Object_Name ( p_object_name   IN VARCHAR2,
                                   p_column_name   IN VARCHAR2,
                                   p_obj_shortname IN VARCHAR2,
                                   p_col_shortname IN VARCHAR2,
                                   p_prefix        IN VARCHAR2,
                                   p_suffix        IN VARCHAR2,
                                   p_name_length   IN PLS_INTEGER := 30 )
     Return VarChar2 Deterministic;

   /** @function    NonLeaf_Spatial_IndexName
   *   @description Gets name of Spatal Index NonLeaf component as well as its size.
   *   @param       p_spindex_name : varchar2 : The user's name of the spatial index.
   *   @param       p_nl_size      : NUMBER : The size of the non-leaf index.
   *   @param       p_owner        : varchar2 : The schema that owns the object.
   *   @param       p_pin          : boolean : Flag saying whether to pin the index in memory.
   */
   Function NonLeaf_Spatial_IndexName( p_spindex_name IN VARCHAR2,
                                       p_nl_size      In Out NoCopy Number,
                                       p_owner        In VarChar2 := NULL,
                                       p_pin          In BOOLEAN  := FALSE )
     Return VarChar2 Deterministic;

   /** @function    Discover_SpatialType
   *   @description Processes table/sdo_geometry column to discover type of spatial data it contains.
   *   @param       p_table_name  : varchar2 : The object containing the spatal data.
   *   @param       p_column_name : varchar2 : The sdo_geometry column to be analyzed.
   *   @param       p_owner       : varchar2 : Schema that owns the table.
   *   @param       p_activity    : T_TokenSet : Array of debug activities that can be used to discover how the procedure processed its data.
   */
   Function Discover_SpatialType( p_table_name  In VarChar2,
                                  p_column_name In VarChar2,
                                  p_owner       In VarChar2 := NULL,
                                  p_activity    In Out NoCopy &&defaultSchema..TOOLS.T_Strings )
     Return VarChar2 Deterministic;

   /** @function    Discover_Dimensions
   *   @description Processes table/sdo_geometry column to discover dimensionality of the spatial data
   *   @param       p_table_name  The object containing the spatal data.
   *   @param       p_column_name The sdo_geometry column to be analyzed.
   *   @param       p_owner       Schema that owns the table.
   *   @param       p_default_dim Default to return if no data.
   *   @param       p_activity    Array of debug activities that can be used to discover how the procedure processed its data.
   */
   Function Discover_Dimensions( p_table_name  IN VarChar2,
                                 p_column_name IN VarChar2,
                                 p_owner       IN VarChar2 := NULL,
                                 p_default_dim IN Number   := 2,
                                 p_activity    In Out NoCopy &&defaultSchema..TOOLS.T_Strings )
     Return Number Deterministic;

   /** @function    Discover_SRID
   *   @description Processes table/sdo_geometry column to discover SRID of the spatial data
   *   @param       p_table_name  : varchar2 : The object containing the spatal data.
   *   @param       p_column_name : varchar2 : The sdo_geometry column to be analyzed.
   *   @param       p_owner       : varchar2 : Schema that owns the table.
   *   @param       p_activity    : T_TokenSet : Array of debug activities that can be used to discover how the procedure processed its data.
   */
   Function Discover_SRID( p_table_name  In VarChar2,
                           p_column_name In VarChar2,
                           p_owner       In VarChar2 := NULL,
                           p_activity    In Out NoCopy &&defaultSchema..TOOLS.T_Strings )
     Return Number Deterministic;

   /** @function    UpdateSdoMetadata
   *   @description Updates 2D spatial extent of DIMINFO associated with table/column in all_sdo_geom_metadata
   *   @param       p_table_name  : varchar2 : The object containing the spatal data.
   *   @param       p_column_name : varchar2 : The sdo_geometry column to be analyzed.
   *   @param       p_mbr_factor  : number   : Expansion/Shrinkage amount for MBR of current data.
   *   @param       p_commit      : boolean  : Whether to commit the update.
   */
   Procedure UpdateSdoMetadata( p_table_name  in varchar2,
                                p_column_name in varchar2,
                                p_mbr_factor  in number,
                                p_commit      in boolean := false );

   /** @function    GetSpatialIndexName
   *   @description Gets name of the spatial index associated with a table/column
   *   @param       p_table_name  : varchar2 : The object containing the spatal data.
   *   @param       p_column_name : varchar2 : The sdo_geometry column to be analyzed.
   *   @param       p_owner       : varchar2 : Schema that owns the table.
   */
   Function GetSpatialIndexName( p_table_name  In VarChar2,
                                 p_column_name In VarChar2,
                                 p_owner       In VarChar2 := NULL )
     Return VarChar2 Deterministic;

   /** @function    DropSpatialIndex
   *   @description Finds and drops spatial index associated with a table/column.
   *   @param       p_table_name  : varchar2 : The object containing the spatal data.
   *   @param       p_column_name : varchar2 : The sdo_geometry column whose index we want to drop.
   *   @param       p_owner       : varchar2 : Schema that owns the table.
   */
   Procedure DropSpatialIndex( p_table_name  In VarChar2,
                               p_column_Name In VarChar2,
                               p_owner       In VarChar2 := NULL);

   /** @function    SpatialIndexer
   *   @description Procedure that can be used to spatially index a
   *                single table/sdo_geometry column.
   *                Will also analyze the index.
   *   @param       p_table_name      : varchar2 : The object containing the spatal data.
   *   @param       p_column_name     : varchar2 : The sdo_geometry column to be analyzed.
   *   @param       p_owner           : varchar2 : Schema that owns the table.
   *   @param       p_spatial_type    : varchar2 : layer_gtype parameter string value. If NULL Discover_SpatialType is called.
   *   @param       p_check           : boolean  : Check table has metadata and has data before indexing.
   *   @param       p_dimensions      : number   : Dimensionality of data in p_column_name (see Discover_Dimensions)
   *   @param       p_tablespace      : varchar2 : For 10g and above, tablespace to hold index data.
   *   @param       p_work_tablespace : varchar2 : For 10g and above, work tablespace as index is built.
   *   @param       p_pin_non_leaf    : boolean  : If set non leaf index is created and pinned into memory.
   *   @param       p_stats_percent   : number   : If > 0 causes index to be analyzed.
   *   @param       p_activity        : T_TokenSet : Array of debug activities that can be used to discover how the procedure processed its data.
   */
   Procedure SpatialIndexer( p_table_name      In VarChar2,
                             p_column_name     In VarChar2,
                             p_owner           In VarChar2    := NULL,
                             p_spatial_type    In VarChar2    := NULL,
                             p_check           In Boolean     := FALSE,
                             p_dimensions      In Number      := 2,
                             p_tablespace      In VarChar2    := NULL,
                             p_work_tablespace In VarChar2    := NULL,
                             p_pin_non_leaf    In Boolean     := FALSE,
                             p_stats_percent   In PLS_INTEGER := 0,
                             p_activity        In Out NoCopy &&defaultSchema..TOOLS.T_Strings );

   /** @function    SpatialIndexUnindexed
   *   @description Procedure that can be used to spatially index those objects with no existing index.
   *   @param       p_owner           : varchar2 : Schema that owns the objects to be indexed. If NULL the sys_context(...,CurrentUser)
   *   @param       p_check           : varchar2 : Check table has metadata and has data before indexing.
   *   @param       p_tablespace      : varchar2 : For 10g and above, tablespace to hold index data.
   *   @param       p_work_tablespace : varchar2 : For 10g and above, work tablespace as index is built.
   *   @param       p_pin_non_leaf    : booelan  : If set non leaf index is created and pinned into memory.
   *   @param       p_stats_percent   : number   : If > 0 causes index to be analyzed.
   **/
   Procedure SpatialIndexUnindexed( p_owner           In VarChar2    := NULL,
                                    p_check           In Boolean     := FALSE,
                                    p_tablespace      In VarChar2    := NULL,
                                    p_work_tablespace In VarChar2    := NULL,
                                    p_pin_non_leaf    In Boolean     := FALSE,
                                    p_stats_percent   In PLS_INTEGER := 0 );

   /** @function    MeadataAnalyzer
   *   @description Procedure that can be used to discover sdo_geom_metadata including sdo_tolerance, generates spatial indexes etc.
   *   @param       p_owner           : varchar2 : Schema that owns the objects to be indexed. If NULL the sys_context(...,CurrentUser)
   *   @param       p_table_regex     : varchar2 : Regular expression used to select tables for processing (10g and above)
   *   @param       p_fixed_srid      : varchar2 : If data is from one SRID, user can set it.
   *   @param       p_fixed_diminfo   : SDO_DIM_ARRAY : If user wants to apply a single diminfo structure to processed tables.
   *   @param       p_tablespace      : varchar2 : For 10g and above, tablespace to hold index data.
   *   @param       p_work_tablespace : varchar2 : For 10g and above, work tablespace as index is built.
   *   @param       p_pin_non_leaf    : boolean  : If set non leaf index is created and pinned into memory.
   *   @param       p_stats_percent   : PLS_Integer : If > 0 causes index to be analyzed.
   *   @param       p_min_projected_tolerance : boolean : The smallest tolerance after which tolerance discovery stops.
   *   @param       p_rectify_geometry : boolean  : Attempt to correct invalid geometries
   **/
   Procedure MetadataAnalyzer( p_owner                   IN VARCHAR2            := NULL,
                               p_table_regex             IN VARCHAR2            := '*',
                               p_column_regex            IN VARCHAR2            := '*',
                               p_fixed_srid              IN NUMBER              := -9999,
                               p_fixed_diminfo           IN MDSYS.SDO_DIM_ARRAY := NULL,
                               p_tablespace              IN VARCHAR2            := NULL,
                               p_work_tablespace         IN VARCHAR2            := NULL,
                               p_pin_non_leaf            IN BOOLEAN             := FALSE,
                               p_stats_percent           IN PLS_INTEGER         := 100,
                               p_min_projected_tolerance IN NUMBER              := 0.00005,
                               p_rectify_geometry        IN BOOLEAN             := FALSE );

   /** @function    RandomSearchByExtent
   *   @description Procedure that can help for independent testing of the performance of a table/geometry column
   *                perhaps when spatially indexing, reorganising data, rounding ordinates etc.
   *   @param       p_schema          : varchar2 : Schema that owns the object to be searched.
   *   @param       p_table_name      : varchar2 : The object containing the spatal data for which we want to gather stats.
   *   @param       p_column_name     : varchar2 : The sdo_geometry column to be searched.
   *   @param       p_number_searches : number : Number of times to execute each search.
   *   @param       p_window_set      : T_WindowSet : Set of search "windows"
   *   @param       p_no_zeros        : boolean : TRUE => zero features searches ignored
   *   @param       p_sdo_anyinteract : boolean : Use Sdo_AnyInteract rather than SDO_FILTER
   *   @param       p_count_vertices  : boolean : Force code to actually process geometry data.
   *   @param       p_debug_detail    : boolean : Don't bother displaying individual search stats
   *   @param       p_min_pixel_size  : number  : Include min_resolution=p_min_pixel_size in search  (only when SDO_FILTERing)
   **/
   Procedure RandomSearchByExtent(p_schema          In VarChar2,
                                  p_table_name      In VarChar2,
                                  p_column_name     In VarChar2,
                                  p_number_searches In Number  := 100,
                                  p_window_set      In &&defaultSchema..T_WindowSet := &&defaultSchema..T_WindowSet(500,1000,2000,3000,4000,5000,10000,20000,50000),
                                  p_no_zeros        In Boolean := TRUE,
                                  p_sdo_anyinteract In Boolean := FALSE,
                                  p_count_vertices  in Boolean := FALSE,
                                  p_debug_detail    In Boolean := FALSE,
                                  p_min_pixel_size  In Number  := NULL );

END TOOLS;
/
SHOW ERRORS

Prompt ------------------------------0000000000000000000000000000------------------------

CREATE OR REPLACE PACKAGE BODY TOOLS
AS
   c_discover_srid        CONSTANT Number        := -9999;
   c_module_name          CONSTANT varchar2(256) := 'TOOLS';
   c_max_number           CONSTANT Number        := 9999999999.9999;
   c_min_number           CONSTANT Number        := -9999999999.9999;
   c_max_tolerance        CONSTANT Number        := 500;
   c_Collection           CONSTANT varchar2(20)  := 'COLLECTION';

   c_spindex_suffix       VARCHAR2(6)            := '$X';  -- Set to NULL if don't want it.
   c_spindex_prefix       VARCHAR2(6)            := NULL;  -- Set to a value (eg SP) if want it

   -- *****************************************************************************************
   -- Private functions for use in Spatial Indexing and Metadata Analyzer
   --

   PROCEDURE Execute_Statement( p_sql     In VarChar2,
                                p_display In Boolean := FALSE)
   IS
   BEGIN
      EXECUTE IMMEDIATE p_sql;
      EXCEPTION
        WHEN OTHERS THEN
          IF ( p_display ) THEN
            dbms_output.put_line(SUBSTR(LPAD('_',6,'_')||p_sql,1,255));
            dbms_output.put_line(SUBSTR(LPAD('_',8,'_')||'Error ('|| SQLCODE ||') of ' || SQLERRM(SQLCODE),1,255));
          END IF;
   END Execute_Statement;

   FUNCTION Managed_Column_Id( p_table_Name  IN VarChar2,
                               p_Column_Name IN VarChar2,
                               p_owner       IN VarChar2 := NULL )
     Return Integer
   Is
     v_id      INTEGER;
     v_owner   VARCHAR2(32);
   Begin
      If ( p_owner Is NULL ) Then
        v_owner := sys_context('userenv','session_user');
      Else
        v_owner := UPPER(SUBSTR(p_owner,1,32));
      End If;
     SELECT ID
       INTO v_id
       FROM &&defaultSchema..MANAGED_COLUMNS
      WHERE owner       = v_owner
        AND table_name  = UPPER(p_table_name)
        AND column_name = UPPER(p_column_name);
     RETURN v_id;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
          SELECT &&defaultSchema..MANAGED_COLUMNS_ID.NEXTVAL INTO v_id FROM DUAL;
          INSERT INTO &&defaultSchema..MANAGED_COLUMNS (ID,owner,table_name,column_name)
            VALUES (v_id,v_owner,UPPER(p_table_name),UPPER(p_column_name));
          RETURN v_id;
   End Managed_Column_Id;

   Function Get_Diminfo( p_table_Name  IN VarChar2,
                         p_Column_Name IN VarChar2,
                         p_owner       IN VarChar2 := NULL )
     Return MDSYS.SDO_DIM_ARRAY
   Is
     v_diminfo       MDSYS.SDO_DIM_ARRAY;
     v_owner         VARCHAR2(32);
   Begin
      If ( p_owner Is NULL ) Then
        v_owner := sys_context('userenv','session_user');
      Else
        v_owner := UPPER(SUBSTR(p_owner,1,32));
      End If;
     SELECT   diminfo
       INTO v_diminfo
       FROM ALL_SDO_GEOM_METADATA
      WHERE owner       = v_Owner
        AND table_name  = UPPER(p_Table_Name)
        AND column_name = UPPER(p_Column_Name);
     RETURN v_DimInfo;
     EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RETURN NULL;
   END Get_Diminfo;

   /** @function    Get_Spatial_Index_Extent
   *   @description Uses SDO_TUNE.EXTENT_OF to get extent of data in the spatial index
   *   @param       p_table_name  The object with the sdo_geometry column.
   *   @param       p_column_name The sdo_geometry column.
   *   @param       p_diminfo     The dimarray into which the new extent data will be written.
   */
   FUNCTION Get_Spatial_Index_Extent( p_table_name  IN VARCHAR2,
                                      p_column_name IN VARCHAR2,
                                      p_diminfo     IN OUT NOCOPY MDSYS.SDO_DIM_ARRAY )
     RETURN BOOLEAN
   IS
     v_geometry  MDSYS.SDO_GEOMETRY;
     v_ordinates MDSYS.SDO_ORDINATE_ARRAY;
   BEGIN
      -- Note only returns extent of 2D indexed data up to 10gR2.
      v_geometry := MDSYS.SDO_TUNE.EXTENT_OF(p_table_name,p_column_name);
      If ( v_geometry is not null ) Then
        v_ordinates := v_geometry.sdo_ordinates;
        If ( v_ordinates.COUNT = 4 ) Then
          p_diminfo(1).sdo_lb := v_ordinates(1);
          p_diminfo(1).sdo_ub := v_ordinates(3);
          p_diminfo(2).sdo_lb := v_ordinates(2);
          p_diminfo(2).sdo_ub := v_ordinates(4);
        End If;
      End If;
      IF ( p_diminfo(1).sdo_lb IS NULL ) OR
         ( p_diminfo(1).sdo_ub IS NULL ) OR
         ( p_diminfo(2).sdo_lb IS NULL ) OR
         ( p_diminfo(2).sdo_ub IS NULL ) THEN
         RETURN FALSE;
      END IF;
      RETURN TRUE;
      EXCEPTION
        WHEN OTHERS THEN
          dbms_output.put_line(SUBSTR('GET_SPATIAL_INDEX_EXTENT: ('|| SQLCODE ||') of ' || SQLERRM(SQLCODE) || ')',1,255));
          RETURN FALSE;
   END Get_Spatial_Index_Extent;

   /* =================== Public Rountine =============== */

  Function isCompound( p_sdo_elem_info in mdsys.sdo_elem_info_array )
     return integer
  Is
    v_compound_element_count number := 0;
  Begin
    SELECT count(*) as c_element_count
      INTO v_compound_element_count
      FROM (SELECT e.id,
                   e.etype,
                   e.offset,
                   e.interpretation
              FROM (SELECT trunc((rownum - 1) / 3,0) as id,
                           sum(case when mod(rownum,3) = 1 then sei.column_value else null end) as offset,
                           sum(case when mod(rownum,3) = 2 then sei.column_value else null end) as etype,
                           sum(case when mod(rownum,3) = 0 then sei.column_value else null end) as interpretation
                      FROM TABLE(p_sdo_elem_info) sei
                     GROUP BY trunc((rownum - 1) / 3,0)
                    ) e
           ) i
     WHERE i.etype = 2
       AND i.interpretation = 2;
    Return case when v_compound_element_count > 0 then 1 else 0 end;
   End isCompound;

   Procedure GeometryCheck( p_schema        IN VarChar2,
                            p_tableName     IN VarChar2,
                            p_ColumnName    IN VarChar2,
                            p_whereClause   IN VarChar2)
   IS
     v_Ok            NUMBER;
     v_version       number;
     v_shape         MDSYS.SDO_GEOMETRY;
     c_shape         MDSYS.SDO_GEOMETRY;
     v_managed_id    INTEGER;
     v_sequence_id   INTEGER;
     v_OwnerName     VARCHAR2(30);
     v_TableName     VARCHAR2(30);
     v_ColumnName    VARCHAR2(30);
     c_rowid         UROWID;
     v_error_code    FEATURE_ERRORS.ERROR_CODE%TYPE;
     v_error_status  FEATURE_ERRORS.ERROR_STATUS%TYPE;
     v_error_context FEATURE_ERRORS.ERROR_CONTEXT%TYPE;
     v_error_count   NUMBER;
     v_error_found   NUMBER;
     v_fixed_count   NUMBER;
     v_count         NUMBER;
     v_diminfo       MDSYS.SDO_DIM_ARRAY;
     v_start_date    DATE;
     v_end_date      DATE;
     v_tolerance     NUMBER;
     v_query         VARCHAR2(1024);
     TYPE shapeCursorType IS REF CURSOR;
     shapeCursor     shapeCursorType;
   Begin
      v_version := DBMS_DB_VERSION.VERSION;
      If ( p_schema Is NULL ) Then
        v_ownerName := sys_context('userenv','session_user');
      Else
        v_ownerName := UPPER(SUBSTR(p_schema,1,32));
      End If;
     v_TableName   := UPPER(p_tablename);
     v_ColumnName  := UPPER(p_ColumnName);
     SELECT COUNT(*)
       INTO v_count
       FROM ALL_TAB_COLUMNS
      WHERE owner       = v_OwnerName
        AND  table_name = v_TableName
        AND column_name = v_ColumnName
        AND   data_type = 'SDO_GEOMETRY';
     If ( v_count = 0 ) Then
        raise_application_error(&&defaultSchema..CONSTANTS.c_i_table_geometry,&&defaultSchema..CONSTANTS.c_s_table_geometry,TRUE);
     End If;
     v_managed_id         := Managed_Column_Id( v_TableName, v_ColumnName, v_OwnerName);
     v_diminfo            := Get_Diminfo( v_TableName, v_ColumnName, v_OwnerName);
     If ( v_diminfo IS NULL ) Then
        dbms_output.put_line(SUBSTR('No diminfo found in all_sdo_geom_metadata for '||v_OwnerName||'.'||v_TableName||'.'||v_ColumnName,1,255));
        raise_application_error(&&defaultSchema..CONSTANTS.c_i_no_diminfo,&&defaultSchema..CONSTANTS.c_s_no_diminfo,TRUE);
     End If;
     v_tolerance   := v_diminfo(1).sdo_tolerance;
     v_count       := 0;
     v_error_count := 0;
     v_fixed_count := 0;
     IF ( p_whereClause is not null ) THEN
       v_query := 'SELECT ROWID,' ||v_ColumnName|| ' FROM ' ||v_OwnerName|| '.' ||v_TableName|| ' WHERE ' ||p_whereClause;
     ELSE
       v_query := 'SELECT ROWID,' ||v_ColumnName|| ' FROM ' ||v_OwnerName|| '.' ||v_TableName;
     END IF;
     v_start_date := SYSDATE;
     OPEN shapeCursor
      FOR v_query;
     LOOP
      FETCH shapeCursor INTO c_rowid, c_shape;
      EXIT WHEN shapeCursor%NOTFOUND;
      IF ( c_shape IS NULL ) THEN
        v_error_code := 'NULL';
      ELSE
        v_error_code := SUBSTR(MDSYS.SDO_GEOM.VALIDATE_GEOMETRY( c_shape, v_diminfo ),1,5);
      END IF;
      IF ( v_error_code <> 'TRUE' ) THEN
        v_error_count := v_error_count + 1;
        v_error_status  := 'E'; -- if exception raised in following block this will remain 'E'
        IF ( v_error_code <> 'NULL' ) THEN
          BEGIN  -- Exception block in case any of the functions trying to fix the shape fail...
            IF ( v_error_code = '13356' ) THEN
              v_shape := mdsys.sdo_util.remove_duplicate_vertices(c_shape,v_tolerance);
            ELSIF c_shape.sdo_gtype in (2003,2007) THEN  -- only try to fix bad polygons
              If ( v_version >= 10 ) Then
                EXECUTE IMMEDIATE 'SELECT MDSYS.SDO_UTIL.RECTIFY_GEOMETRY(:1,:2) FROM DUAL'
		             INTO v_shape
		            USING c_shape, v_tolerance;
              Else
                Begin
                  -- Can only use this if Enterprise Edition and SDO, or 12c and above
                  SELECT 1
                    INTO v_Ok
                    FROM v$version
                   WHERE v_version > 11
                      OR ( banner like '%Enterprise Edition%'
                           AND EXISTS (SELECT 1
                                         FROM all_objects ao
                                        WHERE ao.owner       = 'MDSYS'
                                          AND ao.object_type = 'TYPE'
                                          AND ao.object_name = 'SDO_GEORASTER'
                                      )
                         );
                  IF ( v_ok = 1) THEN
                    v_shape := MDSYS.SDO_GEOM.SDO_UNION(c_shape,v_diminfo,c_shape,v_diminfo);
                  ELSE
                    v_shape := c_shape;
                  END IF;
                  EXCEPTION
                    WHEN OTHERS THEN
                      v_shape := c_shape;
                End;
              End If;
              IF ( v_shape.sdo_gtype = 2004 ) THEN
                v_shape := &&defaultSchema..geom.ExtractPolygon(v_shape);
              END IF;
            END IF;
            -- Update shape to reflect whatever happened...
            EXECUTE IMMEDIATE 'UPDATE ' || v_OwnerName||'.'||v_TableName || ' A SET A.'||v_ColumnName||' = :1 WHERE rowid = :2 '
                        USING v_shape,c_rowid;
            -- Check whether it was corrected or not...
            v_error_context := SUBSTR(MDSYS.SDO_GEOM.VALIDATE_GEOMETRY_WITH_CONTEXT(v_shape,v_diminfo),1,2000);
            v_error_code    := SUBSTR(v_error_context,1,5);
            v_error_context := SUBSTR(v_error_context,6,2000);
            IF v_error_code = 'TRUE' THEN
              v_error_status  := 'F';
              v_fixed_count := v_fixed_count + 1;
            END IF;
            EXCEPTION
              WHEN OTHERS THEN
                NULL;
          END;
        END IF;  -- v_error_code = NULL
        SELECT &&defaultSchema..FEATURE_ERRORS_ID.NEXTVAL INTO v_sequence_id FROM DUAL;
        INSERT INTO &&defaultSchema..Feature_Errors
                    (id,Managed_Column_Id,feature_rowid,error_code,error_status,error_context,error_date)
             VALUES (v_sequence_id,v_managed_id,c_rowid,v_error_code,v_error_status,v_error_context,SYSDATE);
      END IF;
     END LOOP;
     v_count := shapeCursor%ROWCOUNT;
     CLOSE shapeCursor;
     v_end_date := SYSDATE;
     SELECT &&defaultSchema..FEATURE_ERRORS_SUMMARIES_ID.NEXTVAL INTO v_sequence_id FROM DUAL;
     INSERT INTO &&defaultSchema..FEATURE_ERROR_SUMMARIES
                 (id,Managed_Column_Id,predicate,process_start,process_end,process_count,error_total,error_fixed)
          VALUES (v_sequence_id,v_managed_id,p_whereClause,v_start_date,v_end_date,v_count,v_error_count,v_fixed_count);
   END GeometryCheck;

   Procedure VertexAnalyzer( p_owner       In VarChar2 := NULL,
                             p_table_regex In VarChar2 := '*',
                             p_activity    In Out NoCopy &&defaultSchema..TOOLS.T_Strings )
   IS
      CURSOR c_geom_columns ( p_owner In VarChar2,
                              p_regex In VarChar2 ) IS
         SELECT atc.TABLE_NAME,
                atc.COLUMN_NAME
           FROM ALL_TAB_COLUMNS atc
          WHERE atc.owner     = p_owner
            AND atc.DATA_TYPE = 'SDO_GEOMETRY'
            AND REGEXP_LIKE(atc.TABLE_NAME,p_regex);

      v_managed_id INTEGER;
      v_min        NUMBER;
      v_avg        NUMBER;
      v_max        NUMBER;
      v_rubbish    VARCHAR2(4000);
      v_owner      VARCHAR2(32);
   BEGIN
      If ( p_owner Is NULL ) Then
        v_owner := sys_context('userenv','session_user');
      Else
        v_owner := UPPER(SUBSTR(p_owner,1,32));
      End If;
      p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Processing tables like '|| p_table_regex ||' in schema ('|| v_owner || ') ...';

      <<user_tab_columns_loop>>
      FOR geomcolrec IN c_geom_columns( v_owner, p_table_regex ) LOOP  -- process each row one at a time
        p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Processing: ' || geomcolrec.table_name || '.' || geomcolrec.column_name;
        v_managed_id := Managed_Column_Id(geomcolrec.Table_Name, geomcolrec.Column_Name, v_owner);
        BEGIN
          EXECUTE IMMEDIATE 'SELECT ''NO'' FROM '||geomcolrec.table_name || ' WHERE ROWNUM = 1'
                       INTO v_rubbish;
          p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Data exists.';
          p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Computing Minimum, Average and Maximum vertex count';
          EXECUTE IMMEDIATE 'SELECT MIN(VERTEXCOUNT), AVG(VERTEXCOUNT), MAX(VERTEXCOUNT) '||
                              'FROM ( SELECT MDSYS.SDO_UTIL.GETNUMVERTICES(A.'||geomcolrec.column_name||') as VERTEXCOUNT '||
                                      ' FROM '||geomcolrec.table_name || ' A )'
                       INTO v_min, v_avg, v_max;
          p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'MIN('||v_min||') AVG('||v_avg||') MAX('||v_max||')';
          UPDATE &&defaultSchema..Managed_Columns
             SET Vertex_Date  = SYSDATE,
                 min_vertices = v_min,
                 avg_vertices = v_avg,
                 max_vertices = v_max
           WHERE ID = v_managed_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'No data or vertex count can be generated.';
            WHEN OTHERS THEN
              p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Error ('|| SQLCODE ||') of ' || SQLERRM(SQLCODE);
        END;
      END LOOP user_tab_columns_loop;
      COMMIT;
      p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Done';
   END VertexAnalyzer;

   Function hasData( p_table_name In VarChar2,
                     p_owner      In VarChar2 := NULL)
     Return Boolean
   Is
     v_rubbish VarChar2(100);
     v_owner   VARCHAR2(32);
   BEGIN
     If ( p_owner Is NULL ) Then
       v_owner := sys_context('userenv','session_user');
     Else
       v_owner := UPPER(SUBSTR(p_owner,1,32));
     End If;
     dbms_output.put_line(LPAD('_',4,'_')||'Check if any data in table...');
     EXECUTE IMMEDIATE 'SELECT ''NO'' FROM ' || v_owner || '.' || p_table_name || ' WHERE ROWNUM = 1'
        INTO v_rubbish;
     dbms_output.put_line(LPAD('_',6,'_')||'Yes.');
     Return TRUE;
     EXCEPTION
         WHEN OTHERS THEN
           dbms_output.put_line(LPAD('_',6,'_')||'No.');
           Return False;
   END hasData;

   Function Generate_Object_Name ( p_object_name   IN VARCHAR2,
                                   p_column_name   IN VARCHAR2,
                                   p_obj_shortname IN VARCHAR2,
                                   p_col_shortname IN VARCHAR2,
                                   p_prefix        IN VARCHAR2,
                                   p_suffix        IN VARCHAR2,
                                   p_name_length   IN PLS_INTEGER := 30 )
     Return VarChar2
   IS
     v_temp_name        VARCHAR2(4000);
     v_table_len        PLS_INTEGER;
     v_colmn_len        PLS_INTEGER;
   BEGIN
     IF ( p_suffix is not null ) THEN
       -- Try pure name concatenation ...
       v_temp_name := p_object_name || '_' || p_column_name || '_' || p_suffix;
       IF ( LENGTH( v_temp_name ) > p_name_length ) THEN
         -- Try using table short name with normal column name...
         v_temp_name := p_obj_shortname || '_' || p_column_name || '_' || p_suffix;
         IF ( LENGTH( v_temp_name ) > p_name_length ) THEN
           -- Try shortening both names
           v_temp_name := p_obj_shortname || '_' || p_col_shortname || '_' || p_suffix;
           IF ( LENGTH( v_temp_name ) > p_name_length ) THEN
             -- Try table name and suffix
             v_temp_name := p_object_name || '_' || p_suffix;
             IF ( LENGTH( v_temp_name ) > p_name_length ) THEN
               -- Try table short name and suffix
               v_temp_name := p_obj_shortname || '_' || p_suffix;
               IF ( LENGTH( v_temp_name ) > p_name_length ) THEN
                 -- Truncate table short name with suffix
                 v_temp_name := SUBSTR(p_obj_shortname,1,(p_name_length-1-LENGTH(p_suffix))) || '_' || p_suffix;
               END IF;
             END IF;
           END IF;
         END IF;
       END IF;
     ELSIF ( p_prefix is not null ) THEN
       -- Try pure name concatenation ...
       v_temp_name := p_prefix || '_' || p_object_name || '_' || p_column_name;
       IF ( LENGTH( v_temp_name ) > p_name_length ) THEN
         -- Try using table short name with normal column name...
         v_temp_name := p_prefix || '_' || p_obj_shortname || '_' || p_column_name;
         IF ( LENGTH( v_temp_name ) > p_name_length ) THEN
           -- Try shortening both names
           v_temp_name := p_prefix || '_' || p_obj_shortname || '_' || p_col_shortname;
           IF ( LENGTH( v_temp_name ) > p_name_length ) THEN
             -- Try prefix and table name ...
             v_temp_name := p_prefix || '_' || p_object_name;
             IF ( LENGTH( v_temp_name ) > p_name_length ) THEN
               -- Try prefix and table short name ...
               v_temp_name := p_prefix || '_' || p_obj_shortname;
               IF ( LENGTH( v_temp_name ) > p_name_length ) THEN
                 -- Try prefix and truncated table short name ...
                 v_temp_name := p_prefix || '_' || SUBSTR(p_obj_shortname,1,(p_name_length-1-LENGTH(p_suffix)));
               END IF;
             END IF;
           END IF;
         END IF;
       END IF;
     ELSE
       -- Try pure name concatenation ...
       v_temp_name := p_object_name || '_' || p_column_name;
       IF ( LENGTH( v_temp_name ) > p_name_length ) THEN
         -- Try using table short name with normal column name...
         v_temp_name := p_obj_shortname || '_' || p_column_name;
         IF ( LENGTH( v_temp_name ) > p_name_length ) THEN
           -- Try shortening both names
           v_temp_name := p_obj_shortname || '_' || p_col_shortname;
           IF ( LENGTH( v_temp_name ) > p_name_length ) THEN
             -- Generate name from short table name truncated with length of the short column name
             v_temp_name := SUBSTR(p_obj_shortname,1,(p_name_length-1-LENGTH(p_col_shortname))) || '_' || p_col_shortname;
             IF ( LENGTH( v_temp_name ) > p_name_length ) THEN
               -- Generate name by truncating short table and column names in a 2/3 to 1/3 ratio ...
               v_table_len := TRUNC(p_name_length * 2 / 3);
               v_colmn_len := TRUNC(p_name_length / 3) - 1;
               v_temp_name := SUBSTR(p_obj_shortname,1,v_table_len) || '_' || SUBSTR(p_col_shortname,1,v_colmn_len);
             END IF;
           END IF;
         END IF;
       END IF;
     END IF;
     RETURN SUBSTR(v_temp_name,1,p_name_length);
   END Generate_Object_Name;

   Function NonLeaf_Spatial_IndexName( p_spindex_name In VARCHAR2,
                                       p_nl_size      In Out NoCopy Number,
                                       p_owner        In VarChar2 := NULL,
                                       p_pin          In BOOLEAN  := FALSE )
     Return VarChar2
   IS
     v_nl_name   USER_SDO_INDEX_METADATA.SDO_NL_INDEX_TABLE%TYPE;
     v_sql       varchar2(4000);
     v_owner   VARCHAR2(32);
   BEGIN
     If ( p_owner Is NULL ) Then
       v_owner := sys_context('userenv','session_user');
     Else
       v_owner := UPPER(SUBSTR(p_owner,1,32));
     End If;
     BEGIN
       SELECT sdo_nl_index_table
         INTO v_nl_name
         FROM ALL_SDO_INDEX_METADATA
        WHERE sdo_index_owner = v_owner
          AND sdo_index_name  = p_spindex_name ;
       EXCEPTION
         WHEN OTHERS THEN
           RETURN NULL;
     END;
     -- Retrieve Size
     BEGIN
       SELECT sum(bytes)/1024/1024
         INTO p_nl_size
         FROM user_extents
        WHERE segment_name = v_nl_name
           OR segment_name IN
              (SELECT segment_name
                 FROM user_lobs
                WHERE table_name = v_nl_name );
       EXCEPTION
         WHEN OTHERS THEN
           RETURN v_nl_name;
     END;
     v_sql := 'ALTER TABLE '||v_nl_name||' STORAGE(BUFFER_POOL KEEP)';
     IF ( p_pin ) THEN
       Execute_Statement(v_sql,TRUE);
     END IF;
     Return v_nl_name;
   END NonLeaf_Spatial_IndexName;

   Function Discover_SpatialType( p_table_name  In VarChar2,
                                  p_column_name In VarChar2,
                                  p_owner       In VarChar2 := NULL,
                                  p_activity    In Out NoCopy &&defaultSchema..TOOLS.T_Strings )
     Return VarChar2
   IS
     TYPE t_SpatialTypes IS TABLE OF VARCHAR2(20);
     v_SpatialTypes t_SpatialTypes;
     v_spatial_type VARCHAR2(20) := 'NO_DATA';
     v_base_type    VARCHAR2(20) := NULL;
     v_sql          VARCHAR2(4000);
     v_rowcount     NUMBER;
     v_owner        VarChar2(32);
   BEGIN
      If ( p_owner Is NULL ) Then
        v_owner := sys_context('userenv','session_user');
      Else
        v_owner := UPPER(SUBSTR(p_owner,1,32));
      End If;
      v_sql :=          'SELECT SUBSTR(spatialtype,1,20) AS spatialtype';
      v_sql := v_sql || '  FROM (SELECT DISTINCT a.' || p_column_name|| '.sdo_gtype AS gtype, ';
      v_sql := v_sql || '               CASE MOD(a.' || p_column_name|| '.sdo_gtype,10) ';
      v_sql := v_sql || '               WHEN 0 THEN ''UNKNOWN''';
      v_sql := v_sql || '               WHEN 1 THEN ''POINT''      WHEN 5 THEN ''MULTIPOINT'' ';
      v_sql := v_sql || '               WHEN 2 THEN ''LINE''       WHEN 6 THEN ''MULTILINE'' ';
      v_sql := v_sql || '               WHEN 3 THEN ''POLYGON''    WHEN 7 THEN ''MULTIPOLYGON'' ';
      v_sql := v_sql || '               WHEN 4 THEN ''' || c_Collection || ''' ELSE ''NULL'' END AS SpatialType ';
      v_sql := v_sql || '          FROM ' || v_owner || '.' || p_table_name || ' a ';
      v_sql := v_sql || '         WHERE a.' || p_column_name ||' IS NOT NULL ';
      v_sql := v_sql || '       ) ORDER BY gtype DESC';
      EXECUTE IMMEDIATE v_sql
        BULK COLLECT INTO v_SpatialTypes;
      v_rowcount := v_SpatialTypes.COUNT;
      p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Number of Spatial Types in table is ' || v_rowcount;
      IF ( v_rowcount = 0 ) THEN
        RETURN 'NO_DATA';
      ELSIF ( v_rowcount = 1 ) THEN
        v_spatial_type := v_SpatialTypes(1);
        p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Single spatial type of table is: ' || v_spatial_type;
        IF ( v_Spatial_type IN ('NULL','UNKNOWN') ) THEN
          p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Fix spatial types immediately and then re-run Analyzer (Set to COLLECTION).';
          v_spatial_type := c_Collection;
        END IF;
      ELSE
        p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Spatial Types in table are:';
        -- Set to first of the types as this is probably the MULTI...
        v_spatial_type := v_SpatialTypes(1);
        <<list_spatial_types>>
        FOR i IN v_SpatialTypes.First..v_SpatialTypes.Last LOOP
          p_activity(p_activity.LAST) := p_activity(p_activity.LAST) || ' ' || v_SpatialTypes(i);
          -- Update value only if not a COLLECTION
          IF ( v_spatial_type <> c_Collection ) THEN
            IF ( v_SpatialTypes(i) = c_Collection ) THEN
              v_spatial_type := c_Collection;
            -- If NULL or UNKNOWN and not of the same initial type... set to COLLECTION
            ELSIF ( v_SpatialTypes(i) IN ('NULL','UNKNOWN') ) THEN
              p_activity(p_activity.LAST) := p_activity(p_activity.LAST) || '(Fix and re-run Analyzer)';
              v_spatial_type := c_Collection;
            ELSE
              IF ( v_base_type IS NULL ) THEN
                -- Extract base type
                IF ( INSTR(v_SpatialTypes(i),'MULTI') > 0 ) THEN
                  v_base_type := SUBSTR(v_SpatialTypes(i),6,LENGTH(v_SpatialTypes(i)));
                ELSE
                  v_base_type := v_SpatialTypes(i);
                END IF;
                p_activity(p_activity.LAST) := p_activity(p_activity.LAST) || '(Base spatial type is '|| v_base_type || ')';
              ELSE
                -- compare base type to the current object for type conflict
                IF ( INSTR(v_SpatialTypes(i),v_base_type) = 0 ) THEN
                  p_activity(p_activity.LAST) := p_activity(p_activity.LAST) || '(Base spatial type conflict)';
                  v_spatial_type := c_Collection;
                END IF;
              END IF;
            END IF;
          END IF;
        END LOOP list_spatial_types;
      END IF;
      RETURN v_spatial_type;
      EXCEPTION
         WHEN OTHERS THEN
           RETURN c_Collection;
   END Discover_SpatialType;

   Function Discover_Dimensions( p_table_name  IN VarChar2,
                                 p_column_name IN VarChar2,
                                 p_owner       IN VarChar2 := NULL,
                                 p_default_dim IN Number   := 2,
				 p_activity    In Out NoCopy &&defaultSchema..TOOLS.T_Strings )
     Return Number
   IS
     v_sql        VarChar2(4000);
     v_dimensions Number;
     v_owner      VarChar2(32);
     v_version    number;
   BEGIN
     If ( p_owner Is NULL ) Then
       v_owner := sys_context('userenv','session_user');
     Else
       v_owner := UPPER(SUBSTR(p_owner,1,32));
     End If;
     p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Discovering if geometry contains 2D or 3D data...';
     -- Check to see if all sdo_geometry objects are coded with same GTYPE ...
     v_version := DBMS_DB_VERSION.VERSION;
     If ( v_version >= 10 ) Then
       EXECUTE IMMEDIATE 'SELECT DISTINCT A.'||p_column_name||'.Get_Dims() FROM '|| v_owner || '.' || p_table_name || ' A'
                    INTO v_dimensions;
     ELSE
       EXECUTE IMMEDIATE 'SELECT DISTINCT TRUNC(A.'||p_column_name||'.Get_GType / 1000) AS Dim FROM '|| v_owner || '.' || p_table_name || ' A'
                    INTO v_dimensions;
       -- In case of single digit gtypes (from 8i)...
       IF ( v_dimensions = 0 ) THEN
         v_dimensions := p_default_dim;
       END IF;
     END IF;
     p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Geometry is '||v_dimensions || 'D';
     RETURN v_dimensions;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
         p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'No data in table (Assume ' || p_default_dim || 'D)';
         RETURN p_default_dim;
       WHEN TOO_MANY_ROWS THEN
         p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Multiple dimensions exist within the table (Assume ' || p_default_dim || 'D)';
         RETURN p_default_dim;
       WHEN OTHERS THEN
         p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'When determining geometry dimensionality an error ('|| SQLCODE ||') of ' || SQLERRM(SQLCODE) || ' was encountered (Assume ' || p_default_dim || 'D)';
         RETURN p_default_dim;
   END Discover_Dimensions;

   FUNCTION Discover_SRID( p_table_name  In VarChar2,
                           p_column_name In VarChar2,
                           p_owner       In VarChar2 := NULL,
                           p_activity    In Out NoCopy &&defaultSchema..TOOLS.T_Strings )
     RETURN NUMBER
   IS
     TYPE t_SRIDs IS TABLE OF VARCHAR2(20);
     v_SRIDs      t_SRIDs;
     v_srid       VarChar2(20);
     v_rowcount   Number;
     v_owner      VarChar2(32);
     v_report     VarChar2(1000);
     v_sql        VarChar2(4000);
   BEGIN
     If ( p_owner Is NULL ) Then
       v_owner := sys_context('userenv','session_user');
     Else
       v_owner := UPPER(SUBSTR(p_owner,1,32));
     End If;
     --
     -- Start message
     --
     p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Discovering SRID...';
     --
     -- Check to see if all sdo_geometry objects are coded with same SRID ...
     --
     EXECUTE IMMEDIATE 'SELECT DISTINCT NVL(TO_CHAR(A.'||p_column_name||'.SDO_SRID),''NULL'') AS SRID FROM ' || v_owner || '.' || p_table_name || ' A'
        BULK COLLECT INTO v_SRIDs;
     v_rowcount := v_SRIDs.COUNT;
     IF ( v_rowcount = 1 ) THEN
       v_srid := v_SRIDs(1);
     ELSE
       v_report := '(';
       <<list_SRIDs>>
       FOR i IN v_SRIDs.First..v_SRIDs.Last LOOP
          v_report := v_report || v_SRIDs(i) || ',';
       END LOOP list_SRIDs;
       v_report := TRIM(TRAILING ',' FROM v_report) || ')';
       --
       -- Report multi-srid result
       --
       p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Multiple SRIDs ' || v_report || ' exist within table. Discovering most prevalent.';
       --
       -- Get most prevalent srid
       --
       v_sql := 'SELECT SRID
                   FROM ( SELECT NVL(TO_CHAR(A.'||p_column_name||'.SDO_SRID),''NULL'') AS SRID,
                                 COUNT(*) AS SRIDCount
                            FROM '||p_table_name||' a
                           GROUP BY NVL(TO_CHAR(A.'||p_column_name||'.SDO_SRID),''NULL'')
                           ORDER BY 2 DESC
                        )
                  WHERE ROWNUM = 1';
       EXECUTE IMMEDIATE v_sql
                    INTO v_srid;
     END IF;
     --
     -- Report result
     --
     IF ( v_srid = 'NULL' ) THEN
       p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Discovered SRID IS NULL.';
     ELSE
       p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Discovered SRID = ' || v_srid;
     END IF;
     --
     -- Return result
     --
     RETURN CASE WHEN v_srid = 'NULL' THEN NULL ELSE TO_NUMBER(v_srid) END;
   END Discover_SRID;

   Procedure UpdateSdoMetadata( p_table_name  in varchar2,
                                p_column_name in varchar2,
                                p_mbr_factor  in number,
                                p_commit      in boolean := false )
   As
     v_mbr_factor number := case when p_mbr_factor is null then 0 else p_mbr_factor end;
     v_diminfo    mdsys.sdo_dim_array;
   Begin
     -- Check if something to process
     If ( p_table_name is null or p_column_name is null ) Then
       Return;
     End If;

     -- Get existing record (checks if one even exists)
     --
     SELECT diminfo
       INTO v_diminfo
       FROM user_sdo_geom_metadata
      WHERE table_name  = UPPER(p_table_name)
        AND column_name = UPPER(p_column_name);

     -- Update the diminfo with the MBR of the existing data
     EXECUTE IMMEDIATE 'SELECT MDSYS.SDO_DIM_ARRAY(
                                MDSYS.SDO_DIM_ELEMENT(''X'', minx, maxx, :1),
                                MDSYS.SDO_DIM_ELEMENT(''Y'', miny, maxy, :2)) as diminfo
                     FROM ( SELECT TRUNC( MIN( v.x ) - :3,0) as minx,
                                   ROUND( MAX( v.x ) + :4,0) as maxx,
                                   TRUNC( MIN( v.y ) - :5,0) as miny,
                                   ROUND( MAX( v.y ) + :6,0) as maxy
                              FROM (SELECT SDO_AGGR_MBR(a.' || p_column_name || ') as mbr
                                      FROM ' || p_table_name || ' a) b,
                                           TABLE(mdsys.sdo_util.getvertices(b.mbr)) v
                           )'
                 INTO v_diminfo
                USING v_diminfo(1).sdo_tolerance,
                      v_diminfo(2).sdo_tolerance,
                      v_mbr_factor,v_mbr_factor,v_mbr_factor,v_mbr_factor;

     -- Now update the existing record
     --
     UPDATE user_sdo_geom_metadata
        SET diminfo     = v_diminfo
      WHERE table_name  = UPPER(p_table_name)
        AND column_name = UPPER(p_column_name);

    -- Commit if requested
    If ( p_commit ) Then
      commit;
    End If;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         raise_application_error(-20000, 'No SDO_METADATA record exists for ' || p_table_name || '.' || p_column_name || '. Run MetadataAnalayzer');
   End UpdateSdoMetadata;

   Function GetSpatialIndexName( p_table_name  In VarChar2,
                                 p_column_name In VarChar2,
                                 p_owner       In VarChar2 := NULL )
     Return VarChar2
   IS
      v_index_name  ALL_INDEXES.INDEX_NAME%TYPE;
      v_owner       VarChar2(32);
   BEGIN
      If ( p_owner Is NULL ) Then
        v_owner := sys_context('userenv','session_user');
      Else
        v_owner := UPPER(SUBSTR(p_owner,1,32));
      End If;
      /*** I have seen this SQL break because an entry for a spatial index existed in all_indexes BUT the metadata entry in all_sdo_index_metadata didn't!
      SELECT INDEX_NAME
        INTO v_index_name
        FROM all_indexes ai
             INNER JOIN
             all_sdo_index_metadata asi
             ON ( asi.sdo_index_owner = ai.owner
                  AND
                  asi.sdo_index_name  = ai.index_name
                )
       WHERE ai.owner            = UPPER(v_owner)
         AND ai.table_name       = UPPER(p_table_name)
         AND ai.index_type       = 'DOMAIN'
         AND asi.sdo_column_name = '"' || UPPER(p_column_name) || '"';
      So... go for simplicity itself...
      **/
      SELECT INDEX_NAME
        INTO v_index_name
        FROM all_indexes ai
       WHERE ai.owner      = UPPER(v_owner)
         AND ai.table_name = UPPER(p_table_name)
         AND ai.index_type = 'DOMAIN'
         AND ai.ITYP_OWNER = 'MDSYS'
         AND ai.ITYP_NAME  = 'SPATIAL_INDEX';
      RETURN v_index_name;
      EXCEPTION
        WHEN OTHERS THEN
          RETURN NULL;
   END GetSpatialIndexName;

   Procedure DropSpatialIndex( p_table_name  In VarChar2,
                               p_column_Name In VarChar2,
                               p_owner       In VarChar2 := NULL )
   Is
     v_index_name VarChar2(32);
     v_owner      VarChar2(32);
   Begin
     If ( p_owner Is NULL ) Then
       v_owner := sys_context('userenv','session_user');
     Else
       v_owner := UPPER(SUBSTR(p_owner,1,32));
     End If;
     v_index_name := GetSpatialIndexName( p_table_name, p_column_name, v_owner );
     If ( v_Index_Name IS NOT NULL ) Then
       EXECUTE IMMEDIATE 'DROP INDEX ' || v_owner || '.' || v_index_name || ' FORCE';
     End If;
     EXCEPTION
       WHEN OTHERS THEN
            NULL;
   End DropSpatialIndex;

   Procedure SpatialIndexer( p_table_name      In VarChar2,
                             p_column_name     In VarChar2,
                             p_owner           In VarChar2    := NULL,
                             p_spatial_type    In VarChar2    := NULL,
                             p_check           In Boolean     := FALSE,
                             p_dimensions      In Number      := 2,
                             p_tablespace      In VarChar2    := NULL,
                             p_work_tablespace In VarChar2    := NULL,
                             p_pin_non_leaf    In Boolean     := FALSE,
                             p_stats_percent   In PLS_INTEGER := 0,
                             p_activity        In Out NoCopy &&defaultSchema..TOOLS.T_Strings)
   Is
      v_spindex_name  VarChar2(32);
      v_sql           VarChar2(1000);
      v_parameters    VarChar2(1000);
      v_spatial_type  VarChar2(100) := p_spatial_type;
      v_name_length   Number        := 30;
      v_owner         VarChar2(32);
      v_stats_percent PLS_INTEGER   := p_stats_percent;

      FUNCTION Generate_Spatial_Index_Params( p_spatial_type    IN VARCHAR2,
                                              p_tablespace      IN VARCHAR2 := NULL,
                                              p_work_tablespace IN VARCHAR2 := NULL,
                                              p_transactional   IN BOOLEAN  := FALSE,
                                              p_3D              IN BOOLEAN  := FALSE )
        RETURN varchar2
      IS
        v_parameters VARCHAR2(1000);
        v_version    number;
      BEGIN
         v_version := DBMS_DB_VERSION.VERSION;
         v_parameters := 'sdo_indx_dims=2';
         IF ( p_3D And v_version >= 11 ) THEN
           v_parameters := 'sdo_indx_dims=3';
         END IF;
         IF ( p_spatial_type <> c_Collection ) THEN
           v_parameters := v_parameters || ', layer_gtype='||p_spatial_type;
         END IF;
         If ( v_version >= 10 ) Then
           v_parameters := v_parameters || ', sdo_non_leaf_tbl=true';
           IF ( p_transactional ) THEN
              v_parameters := v_parameters || ', sdo_rtr_pctfree=40, sdo_dml_batch_size=1000';
           ELSE
              v_parameters := v_parameters || ', sdo_rtr_pctfree=1';
           END IF;
           IF ( p_tablespace IS NOT NULL ) THEN
             v_parameters := v_parameters || ', tablespace='||p_tablespace;
           END IF;
           IF ( p_work_tablespace IS NOT NULL ) THEN
             v_parameters := v_parameters || ', work_tablespace='||p_work_tablespace;
           END IF;
         End If;
        RETURN v_parameters;
      END Generate_Spatial_Index_Params;

      Function CheckMetadata
        Return Boolean
      Is
        v_diminfo MDSYS.SDO_DIM_ARRAY;
      Begin
        -- Check if USER_SDO_GEOM_METADATA record exists
        SELECT diminfo
          INTO v_diminfo
          FROM ALL_SDO_GEOM_METADATA
         WHERE       owner = v_owner
           AND  table_name = UPPER(p_table_name)
           AND column_name = UPPER(p_column_name);
        Return True;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
             Return False;
      End CheckMetadata;

   Begin
      If ( p_owner Is NULL ) Then
        v_owner := sys_context('userenv','session_user');
      Else
        v_owner := UPPER(SUBSTR(p_owner,1,32));
      End If;
      If ( p_check ) Then
         If ( Not CheckMetadata ) Then
            p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'No user_sdo_geom_metadata record exists: Run MetadataAnalyzer.';
	          Return;
         End If;
         If ( NOT hasData( p_table_name, v_owner ) ) Then
            p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'No data in table: Skipping object.';
            Return;
         End If;
      End If;
      p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Dropping existing index.';
      DropSpatialIndex( p_table_name  => p_table_name,
                        p_column_name => p_column_name,
                        p_owner       => v_owner );
      v_spindex_name := Generate_Object_Name(p_object_name   => p_table_name,
                                             p_column_name   => p_column_name,
                                             p_obj_shortname => REPLACE(TRANSLATE(p_table_name ,'AEIOU','_'),'_'),
                                             p_col_shortname => REPLACE(TRANSLATE(p_column_name,'AEIOU','_'),'_'),
                                             p_prefix        => c_spindex_prefix,
                                             p_suffix        => c_spindex_suffix,
                                             p_name_length   => v_name_length );
      p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Generated object name is ' || v_spindex_name;
      If ( p_spatial_type IS NULL ) Then
        v_spatial_type := Discover_SpatialType(p_table_name, p_column_name, v_owner, p_activity);
        p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Discovered spatial type is ' || v_spatial_type;
        If ( v_spatial_type = 'NO_DATA' ) Then
          p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Indexing terminated';
          Return;
        End If;
      End If;
      v_parameters := Generate_Spatial_Index_Params( p_spatial_type     => v_spatial_type,
                                                     p_tablespace       => p_tablespace,
                                                     p_work_tablespace  => p_work_tablespace,
                                                     p_transactional    => FALSE,
                                                     p_3D               => ( p_dimensions <> 2 ) );
      p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Generated spatial index parameters are ('|| v_parameters ||')';
      v_sql := 'CREATE INDEX ' || v_owner || '.' || v_spindex_name ||
                        ' ON ' || v_owner || '.' || p_table_name || '(' || p_column_name||')' ||
                        ' INDEXTYPE IS MDSYS.SPATIAL_INDEX PARAMETERS(''' || v_parameters || ''')';
      Execute_Statement(v_sql,TRUE);
      --
      -- Check if exists
      --
      If ( GetSpatialIndexName( p_table_name  => p_table_name,
                                p_column_name => p_column_name,
                                p_owner       => v_owner )
           IS NOT NULL ) Then
        p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Index successfully created.';
        --
        -- Get Non-Leaf details if created
        --
        If ( p_pin_non_leaf ) Then
          v_sql := NonLeaf_Spatial_IndexName( p_spindex_name => v_spindex_name,
                                              p_nl_size      => v_name_length,
                                              p_owner        => v_owner,
                                              p_pin          => p_pin_non_leaf );
          p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Non-Leaf Name(Size MB): ' || v_sql || '(' || v_name_length || ') and pinned into memory.';
        End If;
        --
        -- Generate statistics on created index
        --
        If ( v_stats_percent Is Not NULL ) Then
          If ( v_stats_percent > 100 ) Then
             v_stats_percent := 100;
          ElsIf ( v_stats_percent < 0 ) Then
             v_stats_percent := 0;
          End If;
          If ( v_stats_percent Between 1 And 100 ) Then
            BEGIN
              DBMS_STATS.GATHER_INDEX_STATS( v_owner,
                                             v_spindex_name,
                                             estimate_percent => v_stats_percent );
              p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Statistics gathered on '||v_stats_percent||'% of the spatial index.';
              EXCEPTION
                WHEN OTHERS THEN
                    p_activity.EXTEND(1); p_activity(p_activity.LAST) :=  'Error ('|| SQLCODE ||') of ' || SQLERRM(SQLCODE) || ': Terminate spatial index stats.';
            END;
          End If;
        End If;
      Else
        p_activity.EXTEND(1); p_activity(p_activity.LAST) := 'Index did not build.';
      End If;
   End SpatialIndexer;

   Procedure SpatialIndexUnindexed( p_owner           In VarChar2    := NULL,
                                    p_check           In Boolean     := FALSE,
                                    p_tablespace      In VarChar2    := NULL,
                                    p_work_tablespace In VarChar2    := NULL,
                                    p_pin_non_leaf    In Boolean     := FALSE,
                                    p_stats_percent   In PLS_INTEGER := 0 )
   Is
     v_owner    VarChar2(32);
     v_activity &&defaultSchema..TOOLS.T_Strings:= &&defaultSchema..TOOLS.T_Strings(' ');

     -- Declare cursor for all table/column pairs with no index...
     CURSOR c_no_index_table_columns( p_owner In VarChar2 ) Is
       SELECT atc.table_name,
              atc.column_name
         FROM all_objects ao
              INNER JOIN
              all_tab_cols atc ON ( atc.owner      = ao.owner
                                    AND
                                    atc.table_name = ao.object_name )
        WHERE ao.owner        = p_owner
          AND ao.object_type  = 'TABLE'
          AND ( atc.data_type = 'SDO_GEOMETRY'
                AND
                atc.hidden_column  = 'NO'
                AND
                atc.virtual_column = 'NO' )
      MINUS
      SELECT atc.table_name,
             atc.column_name
        FROM all_objects ao
             INNER JOIN all_tab_cols atc ON ( atc.owner =  ao.owner AND atc.table_name =  ao.object_name )
             INNER JOIN all_indexes   ai ON (  ai.owner = atc.owner AND  ai.table_name = atc.table_name )
             INNER JOIN all_sdo_index_metadata asim
             ON ( asim.sdo_index_owner = ai.owner
                  AND
                  asim.sdo_index_name = ai.index_name
                  AND
                  REPLACE(asim.sdo_column_name,'"','') = atc.column_name
                )
       WHERE ao.owner        = p_owner
         AND ao.object_type  = 'TABLE'
         AND ( atc.data_type = 'SDO_GEOMETRY'
               AND
               atc.hidden_column  = 'NO'
               AND
               atc.virtual_column = 'NO'
             )
         AND ai.index_type = 'DOMAIN'
         ORDER BY 1, 2;

   Begin
     If ( p_owner IS NULL ) Then
        v_owner := sys_context('userenv','session_user');
     Else
        v_owner := UPPER(SUBSTR(p_owner,1,32));
     End If;
     dbms_output.put_line('Processing table/sdo_geometry columns for ' || p_owner || ' ... ');
     FOR rec IN c_no_index_table_columns(v_owner) Loop
       dbms_output.put_line(LPAD('_',2,'_')|| rec.table_name || '.' || rec.column_name);
       SpatialIndexer( p_table_name      => rec.table_name,
                       p_column_name     => rec.column_name,
                       p_owner           => v_owner,
                       p_spatial_type    => NULL,
                       p_check           => p_check,
                       p_dimensions      => NULL,
                       p_tablespace      => p_tablespace,
                       p_work_tablespace => p_work_tablespace,
                       p_pin_non_leaf    => p_pin_non_leaf,
                       p_stats_percent   => p_stats_percent,
                       p_activity        => v_activity );
     End Loop;
   End SpatialIndexUnindexed;

   /***
   **  @History : Simon Greener - January 2007 - Updated for 3D data
   **  @History : Simon Greener -  August 2007 - Moved common indexing functions out so new Spatial Indexing function can use them...
   ***/
   Procedure MetadataAnalyzer( p_owner                   IN VARCHAR2            := NULL,
                               p_table_regex             IN VARCHAR2            := '*',
                               p_column_regex            IN VARCHAR2            := '*',
                               p_fixed_srid              IN NUMBER              := -9999,
                               p_fixed_diminfo           IN MDSYS.SDO_DIM_ARRAY := NULL,
                               p_tablespace              IN VARCHAR2            := NULL,
                               p_work_tablespace         IN VARCHAR2            := NULL,
                               p_pin_non_leaf            IN BOOLEAN             := FALSE,
                               p_stats_percent           IN PLS_INTEGER         := 100,
                               p_min_projected_tolerance IN NUMBER              := 0.00005,
                               p_rectify_geometry        IN BOOLEAN             := FALSE )
   IS
      -- Some constants
      c_geographic             MDSYS.SDO_COORD_REF_SYS.coord_ref_sys_kind%TYPE := 'GEOGRAPHIC';
      c_commit_interval        NUMBER := 1000;
      -- Variables
      v_owner                  VarChar2(32);
      v_activity               &&defaultSchema..TOOLS.T_Strings:= &&defaultSchema..TOOLS.T_Strings(' ');
      action                   PLS_INTEGER;
      v_geom_metadata_rec      USER_SDO_GEOM_METADATA%ROWTYPE;
      v_data                   BOOLEAN;
      v_discover_data_extent   BOOLEAN;
      v_id                     INTEGER;
      v_managed_id             INTEGER;
      v_srid                   NUMBER;
      v_dimensions             NUMBER;
      v_start_date             DATE;
      v_rowtext                VARCHAR2(4000);
      v_sql                    VARCHAR2(4000);
      v_spatial_type           VARCHAR2(20);
      v_spindex_name           USER_INDEXES.INDEX_NAME%TYPE;
      v_coord_ref              MDSYS.SDO_COORD_REF_SYS.coord_ref_sys_kind%TYPE;
      v_rubbish                VARCHAR2(4000);
      BAD_STATS_PARAMETER      EXCEPTION;

      CURSOR c_geom_columns ( p_owner In VarChar2,
                              p_regex IN VARCHAR2 ) IS
       SELECT atc.table_name,
              atc.column_name
         FROM all_objects ao
              INNER JOIN
              all_tab_cols atc ON ( atc.owner      = ao.owner
                                    AND
                                    atc.table_name = ao.object_name )
        WHERE ao.owner       = p_owner
          AND ao.object_type = 'TABLE'
          AND REGEXP_LIKE(ao.object_name,p_regex)
          /** SGG Removed 27th October 2015
          AND NOT EXISTS (SELECT 1
                            FROM SYS.DBA_RECYCLEBIN AR  -- Need to GRANT SELECT ON DBA_RECYCLEBIN TO codetest; in SYS schema to work
                           WHERE ar.owner = ao.owner
                             AND ar.object_name = ao.object_name )
          **/
          AND ( atc.data_type = 'SDO_GEOMETRY'
                AND
                atc.hidden_column  = 'NO'
                AND
                atc.virtual_column = 'NO' );

      Function Create_Diminfo( p_dimensions  IN NUMBER,
                               p_lb          IN NUMBER,
                               p_ub          IN NUMBER,
                               p_tolerance   IN NUMBER )
        Return MDSYS.SDO_DIM_ARRAY
      Is
         v_diminfo MDSYS.SDO_DIM_ARRAY;
      Begin
        v_diminfo := MDSYS.SDO_DIM_ARRAY( MDSYS.SDO_DIM_ELEMENT('X',p_lb,p_ub,p_tolerance),
                                          MDSYS.SDO_DIM_ELEMENT('Y',p_lb,p_ub,p_tolerance));
        If p_dimensions > 2 Then
          v_diminfo.EXTEND(1);
          v_diminfo(3) := MDSYS.SDO_DIM_ELEMENT('Z',p_lb,p_ub,p_tolerance);
          If ( p_dimensions > 3 ) Then
             v_diminfo.EXTEND(1);
             v_diminfo(4) := MDSYS.SDO_DIM_ELEMENT('M',p_lb,p_ub,p_tolerance);
          End If;
        End If;
        Return v_diminfo;
      End Create_Diminfo;

      /** @function    Analysis_Report_Row
      *   @description Simply writes a row to the COLUMN_ANALYSES table that reports what actions occured.
      *   @param       p_tabsize  Integer of the amount of padding to use when writing to dbms_output.
      *   @param       p_text     Text to be written to table/dbms_output.
      */
      Procedure Analysis_Report_Row( p_tabsize     In PLS_Integer,
                                     p_text        In VarChar2 )
      Is
         v_id     INTEGER;
         v_ts     &&defaultSchema..COLUMN_ANALYSES.ANALYSIS_DATE%type := SYSTIMESTAMP;
      Begin
         SELECT &&defaultSchema..COLUMN_ANALYSES_ID.NEXTVAL INTO v_id FROM DUAL;
         INSERT INTO &&defaultSchema..COLUMN_ANALYSES ( ID, Managed_Column_ID, analysis_date, result )
                VALUES ( v_id, v_managed_id, v_ts, p_text );
         dbms_output.put_line(SUBSTR(LPAD('_',p_tabsize,'_') || p_text,1,255));
      End Analysis_Report_Row;

      Function Check_DimInfo_Dimensions( p_dimensions  IN NUMBER,
                                         p_diminfo     IN MDSYS.SDO_DIM_ARRAY )
        Return MDSYS.SDO_DIM_ARRAY
      Is
        v_dimcount Integer;
        v_diminfo  MDSYS.SDO_DIM_ARRAY := p_diminfo;
      Begin
        v_dimcount := p_diminfo.COUNT;
        If ( v_dimcount < 2 ) Then
          v_diminfo := Create_Diminfo( p_dimensions, c_min_number, c_max_number, c_max_tolerance );
        Else
          If v_dimcount = p_dimensions Then
            v_diminfo := p_diminfo;
          ElsIf ( v_dimcount < p_dimensions ) Then
            v_diminfo := p_diminfo;
            v_diminfo.EXTEND(p_dimensions - v_dimcount);
            If ( v_dimcount = 2 ) Then
              v_diminfo(3) := MDSYS.SDO_DIM_ELEMENT('Z',c_min_number,c_max_number,c_max_tolerance);
            Else
              v_diminfo(4) := MDSYS.SDO_DIM_ELEMENT('M',c_min_number,c_max_number,c_max_tolerance);
            End If;
            Analysis_Report_Row( 5, 'DimInfo modified to include '||to_char(p_dimensions - v_dimcount)||' extra dim_elements.' );
          End If;
        End If;
        Return v_diminfo;
      End Check_DimInfo_Dimensions;

      Procedure Update_Table_Column_SRID( p_table_name  IN VARCHAR2,
                                          p_column_name IN VARCHAR2,
                                          p_srid        IN NUMBER )
      IS
      BEGIN
        Analysis_Report_Row( 4, 'Updating SRID...');
        EXECUTE IMMEDIATE 'UPDATE '     || p_table_name  || ' a ' ||
                            ' SET a.'   || p_column_name || '.sdo_srid  = :1 ' ||
                            ' WHERE a.' || p_column_name || '.sdo_srid <> :2'
                    USING p_srid,
                          p_srid;
        COMMIT;
        Analysis_Report_Row( 8, 'SRID updated.' );
        EXCEPTION
          WHEN OTHERS THEN
            Analysis_Report_Row(6,'Error updating SRID ('|| SQLCODE ||') of ' || SQLERRM(SQLCODE));
            RETURN ;
      END Update_Table_Column_SRID;

      FUNCTION Discover_Data_Extent( p_owner        IN VARCHAR2,
                                     p_spatial_type IN VARCHAR2,
                                     p_table_name   IN VARCHAR2,
                                     p_column_name  IN VARCHAR2,
                                     p_coord_ref    IN VARCHAR2,
                                     p_diminfo      IN OUT NOCOPY MDSYS.SDO_DIM_ARRAY )
        RETURN BOOLEAN
      IS
        v_sql    VARCHAR2(4000);
        v_x_lb   NUMBER;
        v_x_ub   NUMBER;
        v_y_lb   NUMBER;
        v_y_ub   NUMBER;
        v_z_lb   NUMBER;
        v_z_ub   NUMBER;
      BEGIN
         Analysis_Report_Row( 4, 'Discovering Data Extent...');
         -- Get maximum extent of the actual data into our record (plus a bit)....
         -- Need to modify for > 3D data discovery...
         v_sql := 'SELECT min(c.x) as x_lb, ' ||
                         'max(c.x) as x_ub, ' ||
                         'min(c.y) as y_lb, ' ||
                         'max(c.y) as y_ub';
         Analysis_Report_Row( 6, 'p_DimInfo count is = ' || p_diminfo.COUNT || ' x sdo_tolerance is ' || p_diminfo(1).sdo_tolerance);
         If ( p_diminfo.COUNT > 2 ) Then
           v_sql := v_sql || ', ' ||
                         'min(c.z) as z_lb, ' ||
                         'max(c.z) as z_ub';
         End If;
         v_sql := v_sql || '
                   FROM ' || p_table_name||' g,
                        TABLE( mdsys.sdo_util.getvertices(mdsys.sdo_3gl.mbr_geometry(g.' || p_column_name||',:1) )) c
                  WHERE g.'||p_column_name||' IS NOT NULL';
/* This wasn't cause of problem                    AND &&defaultSchema..TOOLS.isCompound(g.geom.sdo_elem_info) = 0'; */

         If ( p_diminfo.COUNT = 2 ) Then
           EXECUTE IMMEDIATE v_sql
                        INTO v_x_lb, v_x_ub, v_y_lb, v_y_ub
                        USING p_diminfo;
         Else
           EXECUTE IMMEDIATE v_sql
                        INTO v_x_lb, v_x_ub, v_y_lb, v_y_ub, v_z_lb, v_z_ub
                        USING p_diminfo;
         End If;

         -- Generate some wiggle room...
         -- If geodetic we will not subtract/add 1 to the extents in case we turn things like -90 to -91!
         IF ( p_coord_ref <> c_geographic ) THEN
           p_diminfo(1).sdo_lb := v_x_lb - 1;
           p_diminfo(1).sdo_ub := v_x_ub - 1;
           p_diminfo(2).sdo_lb := v_y_lb + 1;
           p_diminfo(2).sdo_ub := v_y_ub + 1;
         ELSE
           p_diminfo(1).sdo_lb := v_x_lb;
           p_diminfo(1).sdo_ub := v_x_ub;
           p_diminfo(2).sdo_lb := v_y_lb;
           p_diminfo(2).sdo_ub := v_y_ub;
         END IF;

         If ( p_diminfo.COUNT = 2 ) Then
           Analysis_Report_Row( 5,
                                'Discovered Extent is (' ||
                                p_diminfo(1).sdo_lb || ',' ||
                                p_diminfo(2).sdo_lb ||
                                ')(' ||
                                p_diminfo(1).sdo_ub || ',' ||
                                p_diminfo(2).sdo_ub  ||
                                ')'
                              );
         Else
           p_diminfo(3) := MDSYS.SDO_DIM_ELEMENT('Z',v_z_lb,v_z_ub,0.5);
           Analysis_Report_Row( 5,
                                'Discovered Extent is (' ||
                                p_diminfo(1).sdo_lb || ',' ||
                                p_diminfo(2).sdo_lb || ',' ||
                                p_diminfo(3).sdo_lb ||
                                ')(' ||
                                p_diminfo(1).sdo_ub || ',' ||
                                p_diminfo(2).sdo_ub || ',' ||
                                p_diminfo(3).sdo_ub  ||
                                ')'
                              );
         End If;
         RETURN TRUE;
         EXCEPTION
          WHEN OTHERS THEN
            Analysis_Report_Row( 6, 'Error ('|| SQLCODE ||') of ' || SQLERRM(SQLCODE) || ' encountered when discovering extent with ' || v_sql);
            RETURN FALSE;
      END Discover_Data_Extent;

      FUNCTION GetC2M( p_SRID IN NUMBER )
        RETURN NUMBER
      IS
        v_c2m           NUMBER; -- Metric conversion from SRID unit to meters
      BEGIN
         v_c2m := 1;
         IF ( p_SRID IS NOT NULL ) THEN
           BEGIN
             SELECT TO_NUMBER(TRIM(substr(comma_pair,INSTR(comma_pair,',')+1))) AS c2m
               INTO v_c2m
               FROM (SELECT REPLACE(SUBSTR(remainder,1,INSTR(remainder,']')-1),'"') as comma_pair
                       FROM (SELECT SUBSTR(wktext,INSTR(wktext,'UNIT ["',-1) + LENGTH('UNIT ["')) as remainder
                               FROM mdsys.cs_srs
                              WHERE SRID = p_SRID
                                AND wktext IS NOT NULL )
                    );
             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                 v_c2m := 1;
           END;
         END IF;
         RETURN v_c2m;
      END GetC2M;

      PROCEDURE Check_GType_Is_Current( p_table_name  IN VARCHAR2,
                                        p_column_name IN VARCHAR2 )
      IS
        v_current NUMBER;
      BEGIN
        EXECUTE IMMEDIATE 'SELECT /*+FIRST_ROWS(1)*/ 0 ' ||
                            'FROM '||p_table_name || ' A ' ||
                           'WHERE A.'||p_column_name||'.sdo_gtype IS NOT NULL ' ||
                           '  AND A.'||p_column_name||'.sdo_gtype < 2000 ' ||
                           ' AND ROWNUM = 1'
                     INTO v_current;
        Analysis_Report_Row( 4, 'Geometry sdo_gtype is not current - Executing SDO_MIGRATE.TO_CURRENT.');
        MDSYS.SDO_MIGRATE.TO_CURRENT( p_table_name, p_column_name, c_commit_interval);
        Analysis_Report_Row( 5, 'Done.');
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            Analysis_Report_Row( 4, 'Geometry sdo_gtype is current.');
          WHEN OTHERS THEN
            Analysis_Report_Row( 4, 'Error ('|| SQLCODE ||') of ' || SQLERRM(SQLCODE) || ' when checking if geometry sdo_gtype is current' );
      END Check_Gtype_Is_Current;

      FUNCTION Discover_Tolerance( p_table_name  IN VARCHAR2,
                                   p_column_name IN VARCHAR2,
                                   p_coord_ref   IN VARCHAR2 )
        RETURN NUMBER
      IS
        v_c2m             NUMBER; -- Metric conversion from SRID unit to meters
        v_tolerance       NUMBER;
        v_min_tolerance   NUMBER;
        v_validate_result VARCHAR2(200);
        v_rectify_sql     VARCHAR2(4000) := '
UPDATE ' || p_table_name || ' r
   SET r.' || p_column_name || ' = MDSYS.SDO_UTIL.RECTIFY_GEOMETRY(r.' || p_column_name || ',:1)
 WHERE MDSYS.SDO_GEOM.VALIDATE_GEOMETRY(r.' || p_column_name || ',:2) <> ''TRUE''';
        v_validate_sql    VARCHAR2(4000) := '
SELECT SUBSTR(sdo_geom.validate_geometry(A.'||p_column_name||',:1),1,20)
  FROM ' || p_table_name || ' A
 WHERE A.'||p_column_name||' IS NOT NULL
   AND mdsys.sdo_geom.validate_geometry(A.'||p_column_name||',:2) <> ''TRUE''
   AND rownum = 1';
      BEGIN
         Analysis_Report_Row( 4, 'Discovering Best Tolerance.');
         -- From the Oracle Spatial documentation.
         -- * For geodetic data (such as data identified by longitude and latitude coordinates), the tolerance value
         --   is a number of meters. For example, a tolerance value of 100 indicates a tolerance of 100 meters.
         --   The tolerance value for geodetic data should not be smaller than 0.05 (5 centimeters), and in most cases
         --   it should be larger. Spatial uses 0.05 as the tolerance value for geodetic data if you specify a smaller value.
         -- * For non-geodetic data, the tolerance value is a number of the units that are associated with the
         --   coordinate system associated with the data. For example, if the unit of measurement is miles,
         --   a tolerance value of 0.005 indicates a tolerance of 0.005 (that is, 1/200) mile (approximately 26 feet),
         --   and a tolerance value of 2 indicates a tolerance of 2 miles.
         --

         -- Set starting tolerance to be large relative to the coordinate system's unit of measure ...
         IF ( p_coord_ref <> c_geographic ) THEN
            Analysis_Report_Row( 5, 'Provided minimum tolerance = ' || p_min_projected_tolerance);
            v_min_tolerance := p_min_projected_tolerance;  -- eg 0.00005 x unit of measurement. Eg if miles then 1/20000 = .26 feet.
            v_tolerance     := 5;                          -- 5 x unit of measure ie if MILE then 5 miles, if CM then 5 CM...
         ELSE
            v_min_tolerance := 0.05;     -- As per documentation ie 5cm
            v_tolerance     := 5000;     -- About 3.1 miles
         END IF;

         -- Let's have a look at the data and do some validate_geometry tests
         v_validate_result := 'FALSE';
         <<validity_tests_loop>>
         WHILE ( v_validate_result <> 'TRUE' ) LOOP
            v_tolerance := v_tolerance / 10;
            Analysis_Report_Row( 6, 'Testing ' || v_tolerance || ' ... ' );
            BEGIN
              EXECUTE IMMEDIATE v_validate_sql
                           INTO v_validate_result
                          USING v_tolerance,
                                v_tolerance;
              IF ( v_validate_result IS NULL ) THEN
                Analysis_Report_Row(8,'Null result (sdo_geometry object error most likely): Terminating discovery.');
                v_validate_result := 'TRUE';
              ELSE
                Analysis_Report_Row(8,'Result is ' || v_validate_result );
              END IF;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  Analysis_Report_Row( 8,'Result OK.' );
                  v_validate_result := 'TRUE';
                WHEN OTHERS THEN
                  Analysis_Report_Row( 8,'Error ('|| SQLCODE ||') of ' || SQLERRM(SQLCODE) || ': Terminating discovery.');
                  v_validate_result := 'TRUE';
            END;
            IF ( v_validate_result <> 'TRUE' AND v_tolerance = v_min_tolerance ) THEN
              Analysis_Report_Row( 8,'Can''t discover tolerance as still getting errors at minimum of ' || v_min_tolerance);
              If ( p_rectify_geometry ) Then
                Analysis_Report_Row(10,'Attempting to Rectify the Geometry.');
                EXECUTE IMMEDIATE v_rectify_sql
                            USING v_tolerance,
                                  v_tolerance;
                Analysis_Report_Row(12,'Done.');
                Analysis_Report_Row(12, 'Testing for errors after rectification using mdsys.sdo_geom.validate_geometry().' );
                v_validate_result := 'FALSE';
                BEGIN
                EXECUTE IMMEDIATE v_validate_sql
                             INTO v_validate_result
                            USING v_tolerance,
                                  v_tolerance;
                Analysis_Report_Row(14,'Failed: Data still invalid with errors like ' || v_validate_result || ', consider fixing manually or using Tools.GeometryCheck');
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    Analysis_Report_Row(14,'Passed: Data is clean');
                END;
              Else
                Analysis_Report_Row(14,'Failed: Data still invalid with errors like ' || v_validate_result || ', consider fixing manually or using Tools.GeometryCheck');
              End If;
              -- STOP
              v_validate_result := 'TRUE';
            END IF;
         END LOOP validity_tests_loop;
         Analysis_Report_Row( 5,'Best calculated tolerance is ' || v_tolerance );
         RETURN v_tolerance;
      END Discover_Tolerance;

      FUNCTION Apply_Tolerance_To_Extent( p_diminfo MDSYS.SDO_DIM_ARRAY )
        RETURN MDSYS.SDO_DIM_ARRAY
      IS
        v_diminfo      MDSYS.SDO_DIM_ARRAY := p_diminfo;
        v_x_tolerance  NUMBER;
        v_y_tolerance  NUMBER;
        v_z_tolerance  NUMBER;  -- Not currently implemented.
      BEGIN
         v_x_tolerance := round(log(10,1/v_diminfo(1).sdo_tolerance))+1;
         v_y_tolerance := round(log(10,1/v_diminfo(2).sdo_tolerance))+1;
         v_diminfo(1).sdo_lb := round(v_diminfo(1).sdo_lb,v_x_tolerance);
         v_diminfo(1).sdo_ub := round(v_diminfo(1).sdo_ub,v_x_tolerance);
         v_diminfo(2).sdo_lb := round(v_diminfo(2).sdo_lb,v_y_tolerance);
         v_diminfo(2).sdo_ub := round(v_diminfo(2).sdo_ub,v_y_tolerance);
         If ( p_diminfo.COUNT = 2 ) Then
           Analysis_Report_Row( 4,
                                'Extent after rounding by tolerance is (' ||
                                v_diminfo(1).sdo_lb||','||v_diminfo(2).sdo_lb ||
                                ')('||
                                v_diminfo(1).sdo_ub||','||v_diminfo(2).sdo_ub ||
                                ')'
                                );
         Else
           Analysis_Report_Row( 4,
                                'Extent after rounding by tolerance is (' ||
                                p_diminfo(1).sdo_lb || ',' ||
                                p_diminfo(2).sdo_lb || ',' ||
                                p_diminfo(3).sdo_lb ||
                                ')(' ||
                                p_diminfo(1).sdo_ub || ',' ||
                                p_diminfo(2).sdo_ub || ',' ||
                                p_diminfo(3).sdo_ub  ||
                                ')'
                              );
         End If;
         RETURN v_diminfo;
      END Apply_Tolerance_To_Extent;

      Procedure Update_Metadata( p_record IN USER_SDO_GEOM_METADATA%ROWTYPE )
      Is
       RECORD_ALREADY_EXISTS EXCEPTION;
       PRAGMA                EXCEPTION_INIT(RECORD_ALREADY_EXISTS, -13223);
      BEGIN
        Analysis_Report_Row( 4, 'USER_SDO_GEOM_METADATA for (' || p_record.table_name || ',' || p_record.column_name || ') updated.');
        INSERT INTO USER_SDO_GEOM_METADATA VALUES p_record;
        COMMIT;
        EXCEPTION
          WHEN RECORD_ALREADY_EXISTS THEN
            UPDATE USER_SDO_GEOM_METADATA
               SET diminfo = p_record.diminfo,
                   srid = p_record.SRID
             WHERE table_name = p_record.table_name
               AND column_name = p_record.column_name;
            COMMIT;
      END Update_Metadata;

      Function Format_Metadata_Record( p_record IN USER_SDO_GEOM_METADATA%ROWTYPE )
         Return VarChar2
      Is
         v_line  VarChar2(4000);

         Function Null_String_Check( p_value IN VarChar2 )
           Return VarChar2
         Is
            v_value VarChar2(4000);
         Begin
            If ( p_value is NULL ) Then
              v_value := 'NULL';
            Else
              v_value := p_value;
            End If;
            Return v_value;
         End Null_String_Check;

         Function Null_Number_Check( p_value IN NUMBER )
           Return VarChar2
         Is
            v_value VarChar2(4000);
         Begin
            If ( p_value is NULL ) Then
              v_value := 'NULL';
            Else
              v_value := To_Char(p_value);
            End If;
            Return v_value;
         End Null_Number_Check;

      Begin
          v_line := 'Metadata Record: ' ||
                       'SRID(' || Null_Number_Check(p_record.srid) ||
                       ') DimInfo(';
          If ( p_record.diminfo is NULL ) Then
            v_line := v_line || 'NULL';
          Else
            v_line := v_line || ' DimNames(' ||
                         Null_String_Check(p_record.diminfo(1).sdo_dimname) ||
                         ',' ||
                         Null_String_Check(p_record.diminfo(2).sdo_dimname);
            If p_record.diminfo.count > 2 Then
               v_line := v_line || ',' || Null_String_Check(p_record.diminfo(3).sdo_dimname);
            End If;
            v_line := v_line || ') Extent((' ||
                      Null_Number_Check(p_record.diminfo(1).sdo_lb) ||
                      ',' ||
                      Null_Number_Check(p_record.diminfo(2).sdo_lb);
            If p_record.diminfo.count > 2 Then
               v_line := v_line || ',' || Null_Number_Check(p_record.diminfo(3).sdo_lb);
            End If;
            v_line := v_line || ')(' ||
                         Null_Number_Check(p_record.diminfo(1).sdo_ub) ||
                         ',' ||
                         Null_Number_Check(p_record.diminfo(2).sdo_ub);
            If p_record.diminfo.count > 2 Then
               v_line := v_line || ',' || Null_Number_Check(p_record.diminfo(3).sdo_ub);
            End If;
            v_line := v_line ||
                      ')) Tolerance(' ||
                      Null_Number_Check(p_record.diminfo(1).sdo_tolerance) ||
                      ',' ||
                      Null_Number_Check(p_record.diminfo(2).sdo_tolerance);
            If p_record.diminfo.count > 2 Then
               v_line := v_line || ',' || Null_Number_Check(p_record.diminfo(3).sdo_tolerance);
            End If;
            v_line := v_line || ')';
          End If;
          v_line := v_line || ')';
          Return v_line;
     End Format_Metadata_Record;

      FUNCTION Write_Sdo_Geom_Record
        RETURN BOOLEAN
      IS
      BEGIN
         INSERT INTO USER_SDO_GEOM_METADATA
                   (table_name,
                    column_name,
                    diminfo,
                    srid)
             VALUES(v_geom_metadata_rec.table_name,
                    v_geom_metadata_rec.column_name,
                    v_geom_metadata_rec.diminfo,
                    v_geom_metadata_rec.srid);
         COMMIT;
         Analysis_Report_Row( 5,'USER_SDO_GEOM_METADATA row inserted.' );
         RETURN TRUE;
         EXCEPTION
            WHEN OTHERS THEN
              Analysis_Report_Row(6,'Failed to insert new user_sdo_geom_metadata record ('|| SQLCODE ||') of ' || SQLERRM(SQLCODE));
              RETURN FALSE;
      END Write_Sdo_Geom_Record;

      Function Create_Geom_Metadata_Record( p_table_name    in user_sdo_geom_metadata.table_name%type,
                                            p_column_name   in user_sdo_geom_metadata.column_name%type,
                                            p_srid          IN INTEGER)
        Return USER_SDO_GEOM_METADATA%ROWTYPE DETERMINISTIC
      Is
        v_geom_metadata_rec USER_SDO_GEOM_METADATA%ROWTYPE;
      BEGIN
        Analysis_Report_Row(4,'Is there an existing user_sdo_geom_metadata entry?');
        SELECT *
          INTO v_geom_metadata_rec
          FROM USER_SDO_GEOM_METADATA
         WHERE  table_name = p_table_name
           AND column_name = p_column_name;
        --
        -- If we have been passed a fixed SRID update it
        --
        IF ( p_srid <> c_discover_srid ) THEN
          v_geom_metadata_rec.srid := p_srid;
          Analysis_Report_Row(5,'Yes (but SRID updated to ' || p_srid || ')');
        Else
          Analysis_Report_Row(5,'Yes');
        END IF;
        Return v_geom_metadata_rec;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            Analysis_Report_Row(5,'No');
            --
            -- Let's create a basic metadata entry
            --
            Analysis_Report_Row( 4,'Generating user_sdo_geom_metadata record ...');
            v_geom_metadata_rec.srid        := p_srid;
            v_geom_metadata_rec.table_name  := UPPER(p_table_name);
            v_geom_metadata_rec.column_name := UPPER(p_column_name);
            v_geom_metadata_rec.diminfo     := Create_Diminfo( 2, c_min_number, c_max_number, c_max_tolerance );
            Return v_geom_metadata_rec;
      END Create_Geom_Metadata_Record;

      PROCEDURE Print_Activity( p_indent in number )
      Is
      BEGIN
          --
          -- Report activities added to activity array
          --
          If ( v_activity.COUNT > 0 ) Then
            For action IN v_activity.FIRST..v_activity.LAST Loop
               If ( v_activity.EXISTS(action) AND LENGTH(TRIM(v_activity(action))) > 0 ) Then
                 Analysis_Report_Row( p_indent,v_activity(action) );
               End If;
            End Loop;
            v_activity.TRIM(v_activity.COUNT);
          End If;
      END Print_Activity;

   BEGIN -- MetadataAnalyzer

      --
      -- Check variables and parameters
      --
      v_activity.TRIM(v_activity.COUNT);
      If ( p_owner Is NULL ) Then
        v_owner := sys_context('userenv','session_user');
      Else
        v_owner := UPPER(SUBSTR(p_owner,1,32));
      End If;

      IF NOT ( p_stats_percent BETWEEN 0 AND 100 ) THEN
        RAISE BAD_STATS_PARAMETER;
        Analysis_Report_Row(1,'p_stats_percent parameter value ('||p_stats_percent||') not between 1 and 100');
        RETURN;
      END IF;

      Analysis_Report_Row(1,'Processing tables or materialized views like '|| p_table_regex ||' for user ('|| v_owner || ') ...');

      --
      -- Create list of table/geometry columns for processing/checking
      --
      <<user_tab_columns_loop>>
      FOR geomcolrec IN c_geom_columns( v_owner, p_table_regex ) LOOP
        v_start_date := SYSDATE;
        v_managed_id := Managed_Column_Id(geomcolrec.Table_Name, geomcolrec.Column_Name, v_owner);
        Analysis_Report_Row(2,geomcolrec.table_name || '.' || geomcolrec.column_name);

        --
        -- Is there any data in this table?
        --
        v_data := hasData( geomcolrec.table_name, v_owner );

        --
        -- ================ USER_SDO_GEOM_METADATA PROCESSING =======================
        --
        -- Create new USER_SDO_GEOM_METADATA record (may start with any existing record)
        --
        v_geom_metadata_rec := Create_Geom_Metadata_Record(geomcolrec.table_name,
                                                           geomcolrec.column_name,
                                                           CASE WHEN p_fixed_srid = c_discover_srid
                                                                THEN NULL
                                                                ELSE p_fixed_srid
                                                            END );

        --
        -- Print out the starting metadata ...
        --
        v_rubbish := Format_Metadata_Record( v_geom_metadata_rec );
        Analysis_Report_Row(6, 'STARTING ' || v_rubbish );

        -- Now, we process the actual data to determine what the actual metadata record should be
        --
        -- Use Discover_SRID to get most common SRID in table...
        --
        IF ( v_Data ) THEN
            v_geom_metadata_rec.srid := Discover_SRID( p_table_name  => geomcolrec.table_name,
                                                       p_column_name => geomcolrec.column_name,
                                                       p_activity    => v_activity );
            Print_Activity( 6 );
        ELSIF ( p_fixed_srid = c_discover_srid ) THEN
          v_geom_metadata_rec.srid := NULL;
        END IF;

        --
        -- Now we have the SRID, let's discover if the data is projected or geodetic
        --
        v_coord_ref := 'PROJECTED';
        IF ( v_geom_metadata_rec.SRID IS NOT NULL ) THEN
          SELECT CASE WHEN coord_ref_sys_kind LIKE 'GEO%' THEN c_geographic
                      ELSE coord_ref_sys_kind
                  END as Coord_Ref
            INTO v_coord_ref
            FROM MDSYS.SDO_COORD_REF_SYS
           WHERE SRID = v_geom_metadata_rec.SRID;
        END IF;
        Analysis_Report_Row( 5, 'Table contains '||v_coord_ref||' data.' );

        --
        -- We need to know the actual data dimensions ie 2D, 3D etc for indexing ie sdo_indx_dims=2
        --
        IF ( v_data ) THEN
          v_dimensions := Discover_Dimensions( p_table_name  => geomcolrec.table_name,
                                               p_column_name => geomcolrec.column_name,
                                               p_activity    => v_activity );
          Print_Activity( 6 );
          --
          -- If 2D then diminfo should contain 2 sdo_dim_elements etc...
          --
          v_geom_metadata_rec.diminfo := Check_DimInfo_Dimensions( v_dimensions, v_geom_metadata_rec.diminfo );
        End If;

        --
        -- Now get Spatial Index Name (if exists)
        --
        v_spindex_name := GetSpatialIndexName( p_table_name  => geomcolrec.table_name,
                                               p_column_name => geomcolrec.column_name,
                                               p_owner       => p_owner );
        If ( v_spindex_name IS NOT NULL ) Then
           Analysis_Report_Row( 4,'Spatial Index name = ' || v_spindex_name );
        Else
           Analysis_Report_Row( 4,'No spatial index exists.' );
        End If;

        --
        -- Examine the actual data to determine the sdo_tolerance of the data
        -- This must be done before spatial extent as spatial extent needs valid tolerance value
        --
        IF ( p_fixed_diminfo IS NULL OR p_fixed_diminfo(1).sdo_tolerance IS NULL ) THEN
          v_geom_metadata_rec.diminfo(1).sdo_tolerance :=
                Discover_Tolerance( p_table_name  => geomcolrec.table_name,
                                    p_column_name => geomcolrec.column_name,
                                    p_coord_ref   => v_coord_ref );
          v_geom_metadata_rec.diminfo(2).sdo_tolerance := v_geom_metadata_rec.diminfo(1).sdo_tolerance;
        ELSIF ( p_fixed_diminfo IS NOT NULL AND p_fixed_diminfo(1).sdo_tolerance IS NOT NULL ) THEN
          v_geom_metadata_rec.diminfo(1).sdo_tolerance := p_fixed_diminfo(1).sdo_tolerance;
          v_geom_metadata_rec.diminfo(2).sdo_tolerance := p_fixed_diminfo(2).sdo_tolerance;
        END IF;
        --
        -- Because Z/M tolerance is not yet discoverable by the tool....
        --
        If ( p_fixed_diminfo IS NOT NULL ) Then
          If ( v_dimensions > 2 ) AND ( p_fixed_diminfo.COUNT > 2 ) Then
            v_geom_metadata_rec.diminfo(3).sdo_tolerance := p_fixed_diminfo(3).sdo_tolerance;
            If ( v_dimensions > 3 ) AND ( p_fixed_diminfo.COUNT > 3 ) Then
               v_geom_metadata_rec.diminfo(4).sdo_tolerance := p_fixed_diminfo(4).sdo_tolerance;
            End If;
          End If;
        End If;

        --
        -- Now set sdo_lb/sdo_ub of diminfo structure from real data (if possible)
        --
        v_discover_data_extent := TRUE;
        IF ( v_data
             AND
             p_fixed_diminfo IS NULL ) THEN
           -- No fixed diminfo supplied...
           -- Can we use the spatial index to get the extent?
           IF ( v_spindex_name IS NOT NULL ) THEN
             -- Only if data is 2D and non-geodetic
             IF ( v_dimensions = 2 ) AND ( v_coord_ref <> c_geographic ) THEN
                v_discover_data_extent := NOT Get_Spatial_Index_Extent( p_table_name  => geomcolrec.table_name,
                                                                        p_column_name => geomcolrec.column_name,
                                                                        p_diminfo     => v_geom_metadata_rec.diminfo );
                If v_discover_data_extent Then
                    Analysis_Report_Row( 4,
                           'SDO_TUNE.EXTENT_OF returned extent of (' ||
                           v_geom_metadata_rec.diminfo(1).sdo_lb||','||v_geom_metadata_rec.diminfo(2).sdo_lb ||
                           ')('||
                           v_geom_metadata_rec.diminfo(1).sdo_ub||','||v_geom_metadata_rec.diminfo(2).sdo_ub ||
                           ')'
                         );
                Else
                  Analysis_Report_Row( 4, 'SDO_TUNE.EXTENT_OF returned empty extent.');
                End If;
             END IF;
           END IF;
           --
           -- Do we still need to access the raw data to get the extent?
           --
           IF ( v_discover_data_extent ) THEN
              IF Discover_Data_Extent( p_owner        => v_owner,
                                       p_spatial_type => v_spatial_type,
                                       p_table_name   => geomcolrec.table_name,
                                       p_column_name  => geomcolrec.column_name,
                                       p_coord_ref    => v_coord_ref,
                                       p_diminfo      => v_geom_metadata_rec.diminfo ) THEN
                 IF ( v_coord_ref <> c_geographic ) THEN
                    v_geom_metadata_rec.diminfo := Apply_Tolerance_To_Extent( v_geom_metadata_rec.diminfo );
                 END IF;
              END IF;
            END IF;

        ELSIF ( p_fixed_diminfo is not null ) THEN
          v_geom_metadata_rec.diminfo(1).sdo_lb := p_fixed_diminfo(1).sdo_lb;
          v_geom_metadata_rec.diminfo(1).sdo_ub := p_fixed_diminfo(1).sdo_ub;
          v_geom_metadata_rec.diminfo(2).sdo_lb := p_fixed_diminfo(2).sdo_lb;
          v_geom_metadata_rec.diminfo(2).sdo_ub := p_fixed_diminfo(2).sdo_ub;
          If ( v_dimensions > 2 ) AND ( p_fixed_diminfo.COUNT > 2 ) Then
            v_geom_metadata_rec.diminfo(3).sdo_lb := p_fixed_diminfo(3).sdo_lb;
            v_geom_metadata_rec.diminfo(3).sdo_ub := p_fixed_diminfo(3).sdo_ub;
            If ( v_dimensions > 3 ) AND ( p_fixed_diminfo.COUNT > 3 ) Then
              v_geom_metadata_rec.diminfo(4).sdo_lb := p_fixed_diminfo(4).sdo_lb;
              v_geom_metadata_rec.diminfo(4).sdo_ub := p_fixed_diminfo(4).sdo_ub;
            End If;
          End If;
        END IF /* p_fixed_diminfo is not null */;

        --
        -- Regardless of result we will now drop the spatial index because we are about to update the table.
        --
        If ( v_spindex_name IS NOT NULL ) Then
          Execute_Statement('DROP INDEX ' || v_spindex_name || ' FORCE',TRUE);
          Analysis_Report_Row( 7, 'Existing Index (' || v_spindex_name || ') dropped.' );
        END IF;

        --
        -- Update SRID of table if different to supplied/calculated
        --
        Update_Table_Column_SRID( p_table_name  => geomcolrec.table_name,
                                  p_column_name => geomcolrec.column_name,
                                  p_srid        => v_geom_metadata_rec.srid );

        --
        -- Assign Dimension names to all sdo_dim_elements based on whether data is Projected or Geodetic
        --
        IF ( v_coord_ref = 'PROJECTED' ) THEN
          v_rubbish := 'X,Y';
          v_geom_metadata_rec.diminfo(1).sdo_dimname := 'X';
          v_geom_metadata_rec.diminfo(2).sdo_dimname := 'Y';
        ELSE
          v_rubbish := 'Long,Lat';
          v_geom_metadata_rec.diminfo(1).sdo_dimname := 'Long';
          v_geom_metadata_rec.diminfo(2).sdo_dimname := 'Lat';
        END IF;
        If ( v_dimensions > 2 ) Then
          v_rubbish := v_rubbish || ',Z';
          v_geom_metadata_rec.diminfo(3).sdo_dimname := 'Z';
        End If;
        If ( v_dimensions > 3 ) Then
          v_rubbish := v_rubbish || ',M';
          v_geom_metadata_rec.diminfo(4).sdo_dimname := 'M';
        End If;
        Analysis_Report_Row( 4, 'Assigned Dimension Names (' || v_rubbish || ').' );

        --
        If ( v_data ) Then
          --
          -- Discover geometry types within table/column
          --
          Analysis_Report_Row( 4,'Discovering spatial type...');
          v_spatial_type := Discover_SpatialType( p_table_name  => geomcolrec.table_name,
                                                  p_column_name => geomcolrec.column_name,
                                                  p_owner       => v_owner,
                                                  p_activity    => v_activity );
          Print_Activity( 6 );
          Analysis_Report_Row( 6,'Discovered spatial type is ' || v_spatial_type);
          --
          -- We don't want any SDO_GTYPEs < 2000 ie old SDO_GTYPES for which we need to run MDSYS.SDO_MIGRATE.TO_CURRENT()
          --
          Check_GType_Is_Current( p_table_name => geomcolrec.table_name,
                                  p_column_name => geomcolrec.column_name );
        End If /* v_data */;
        --
        -- Need to update metadata before building spatial index...
        --
        Update_Metadata( p_record => v_geom_metadata_rec );
        --
        -- Print out the Final metadata ...
        --
        v_rubbish := Format_Metadata_Record( v_geom_metadata_rec );
        Analysis_Report_Row( 6, 'FINAL ' || v_rubbish );

        --
        -- Now rebuild index if we can
        --
        IF ( v_data
             AND
             v_spatial_type <> 'NO_DATA' ) THEN
            Analysis_Report_Row(4,'Creating new index...');
            SpatialIndexer( p_table_name      => geomcolrec.table_name,
                            p_column_name     => geomcolrec.column_name,
                            p_owner           => p_owner,
                            p_spatial_type    => NULL,
                            p_check           => FALSE,
                            p_dimensions      => v_dimensions,
                            p_tablespace      => p_tablespace,
                            p_work_tablespace => p_work_tablespace,
                            p_pin_non_leaf    => p_pin_non_leaf,
                            p_stats_percent   => p_stats_percent,
                            p_activity        => v_activity );
            Print_Activity( 6 );
            DBMS_STATS.GATHER_TABLE_STATS(v_owner, geomcolrec.table_name, estimate_percent => p_stats_percent );
            Analysis_Report_Row( 8, 'Statistics gathered on '||p_stats_percent||'% of the table.');
        END IF;
        Analysis_Report_Row( 1, 'Metadata Analysis of table completed.' );
        SELECT &&defaultSchema..COLUMN_ANALYSIS_SUMMARIES_ID.NEXTVAL INTO v_id FROM DUAL;
        INSERT INTO &&defaultSchema..COLUMN_ANALYSIS_SUMMARIES (
             ID,   Managed_Column_ID, analysis_process_start, analysis_process_end
	) VALUES(
           v_id, v_managed_id,                  v_start_date, SYSDATE );
      END LOOP user_tab_columns_loop;
      COMMIT;
      Analysis_Report_Row( 2, 'Metadata Analysis completed.' );
   END MetadataAnalyzer;

  PROCEDURE RandomSearchByExtent( p_schema          In VarChar2,
                                  p_table_name      In VarChar2,
                                  p_column_name     In VarChar2,
                                  p_number_searches In Number  := 100,
                                  p_window_set      In &&defaultSchema..T_WindowSet := &&defaultSchema..T_WindowSet(500,1000,2000,3000,4000,5000,10000,20000,50000),
                                  p_no_zeros        In Boolean := TRUE,
                                  p_sdo_anyinteract In Boolean := FALSE,
                                  p_count_vertices  in Boolean := FALSE,
                                  p_debug_detail    In Boolean := FALSE,
                                  p_min_pixel_size  In Number  := NULL )
   IS
     v_rand_x            number := 0;
     v_rand_y            number := 0;
     v_searchWindowList  &&defaultSchema..T_WindowSet := p_window_set;
     v_searchWindowSize  number;
     v_searchShape       mdsys.sdo_geometry;
     v_diminfo           mdsys.sdo_dim_array;
     v_srid              number;
     v_lower_x           number;
     v_lower_y           number;
     v_upper_x           number;
     v_upper_y           number;
     v_range_x           number;
     v_range_y           number;
     v_ll_x              number;
     v_ll_y              number;
     v_ur_x              number;
     v_ur_y              number;
     v_Start_Time        number;
     v_End_Time          number;
     v_totalFeatures     PLS_INTEGER;
     v_totalVertices     PLS_INTEGER;
     v_totalSeconds      Number;
     v_fcount            pls_integer;
     v_vcount            pls_integer;
     v_seconds           number;
     v_schema_table      varchar2(100);
     v_sql               varchar2(4000);
     v_owner             varchar2(32);
   BEGIN
     If ( p_schema Is NULL ) Then
        v_owner := sys_context('userenv','session_user');
     Else
        v_owner := UPPER(SUBSTR(p_schema,1,32));
     End If;
     V_schema_table := v_owner || '.' || UPPER(p_table_name);
     DBMS_OUTPUT.ENABLE ( 100000 );
     BEGIN
       SELECT diminfo, srid
         INTO v_diminfo, v_srid
         FROM all_sdo_geom_metadata
        WHERE table_name  = UPPER(p_table_name)
          AND column_name = UPPER(p_column_name)
          AND owner       = v_owner;
       v_lower_x := v_diminfo(1).SDO_LB;
       v_upper_x := v_diminfo(1).SDO_UB;
       v_lower_y := v_diminfo(2).SDO_LB;
       v_upper_y := v_diminfo(2).SDO_UB;
       EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
              dbms_output.put_line('No metadata record found for '||v_schema_table||'.'||p_column_name || ' manually computing MBR');
              execute immediate 'select min(t.x),min(t.y), max(t.x),max(t.y)
                                   from table(sdo_util.getVertices((SELECT sdo_aggr_mbr(' || p_column_name || ') from ' || v_schema_table || '))) t'
              into v_lower_x,v_lower_y,v_upper_x,v_upper_y;
     END;

     v_range_x := v_upper_x - v_lower_x;
     v_range_y := v_upper_y - v_lower_y;

     if ( p_count_vertices ) then
        v_sql := 'SELECT count(*), sum(mdsys.sdo_util.getNumVertices(a.' || p_column_name || ')) FROM '||v_schema_table||' A WHERE ';
     Else
        v_sql := 'SELECT count(*), 0 FROM '||v_schema_table||' A WHERE ';
     End If;
     IF ( p_Sdo_AnyInteract ) THEN
       v_sql := v_sql || 'MDSYS.SDO_RELATE(A.'||p_column_name||',:1,''mask=ANYINTERACT ';
     ELSE
       v_sql := v_sql || 'MDSYS.SDO_FILTER(A.'||p_column_name||',:1,''';
     END IF;
     IF p_min_pixel_size IS NOT NULL THEN
       v_sql := v_sql || ' min_resolution=' || p_min_pixel_size ;
     END IF;
     v_sql := v_sql || ' querytype=WINDOW'') = ''TRUE''';

     dbms_output.put_line(SUBSTR('Search SQL = ' || v_Sql,1,255));

     dbms_output.put_line('SearchWindow,Searches,TotalFeatures,TotalSeconds,FeaturesPerSecond' || case when p_count_vertices then ',AverageVertices' else '' end);

     FOR searchSizeCounter IN v_searchWindowList.FIRST..v_searchWindowList.LAST LOOP
       v_totalFeatures := 0;
       v_totalVertices := 0;
       v_totalSeconds  := 0;
       v_searchWindowSize := v_searchWindowList(searchSizeCounter);
       FOR r IN 1..p_number_searches LOOP
         v_fcount := -1;
         -- Loop until we get a valid search
         IF ( p_debug_detail ) THEN
           dbms_output.put_line('RandX,RandY,Count,Seconds');
         END IF;
         WHILE ( v_fcount = -1 ) OR ( v_fcount = 0 AND p_no_zeros ) LOOP
           v_rand_x := dbms_random.value(v_lower_x,v_upper_x);
           v_rand_y := dbms_random.value(v_lower_y,v_upper_y);
           v_ll_x := v_rand_x - ( v_searchWindowSize / 2 );
           v_ll_y := v_rand_y - ( v_searchWindowSize / 2 );
           v_ur_x := v_rand_x + ( v_searchWindowSize / 2 );
           v_ur_y := v_rand_y + ( v_searchWindowSize / 2 );
           v_searchShape := MDSYS.SDO_GEOMETRY(2003,v_srid,NULL,
                             MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3),
                             MDSYS.SDO_ORDINATE_ARRAY(v_ll_X,v_ll_y,v_ur_x,v_ur_y));
           v_Start_Time := dbms_utility.get_time;
           EXECUTE IMMEDIATE v_sql
                        INTO v_fcount, v_vcount
                       USING v_searchShape;
           v_End_Time := dbms_utility.get_time;
         END LOOP;
         v_totalFeatures := v_totalFeatures + v_fcount;
         v_totalVertices := v_totalVertices + v_vcount;
         v_seconds       := ( v_End_Time - v_Start_Time ) / 100;
         v_totalSeconds  := v_totalSeconds + v_seconds;
         IF ( p_debug_detail ) THEN
           dbms_output.put_line(round(v_rand_x,3)||','||round(v_rand_y,3)||','||round(v_fcount,1)||','||TO_CHAR(round(v_seconds,2),'FM999.99'));
         END IF;
       END LOOP;
       dbms_output.put_line(SUBSTR(v_searchWindowSize || ',' ||
                            p_number_Searches || ',' ||
                            trim(TO_CHAR(v_totalFeatures,'9999999')) || ',' ||
                            round(v_Totalseconds,2) || ',' ||
                            trim(TO_CHAR(round(v_totalFeatures / v_TotalSeconds,1),'999999.9')),1,255) ||
                            case when p_count_vertices then ',' || TO_CHAR(round(v_totalVertices / v_totalFeatures,1),'FM999,999,999.9') else '' end );
     END LOOP;
   END RandomSearchByExtent;

BEGIN
  DBMS_OUTPUT.ENABLE ( buffer_size => NULL );
END TOOLS;
/
SHOW ERRORS

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'TOOLS';
BEGIN
   FOR rec IN (select object_name || '.' || object_Type as package_name, status 
                 from user_objects
                where object_name = v_obj_name) LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line('Package ' || USER || '.' || rec.package_name || ' is valid.');
      ELSE
         dbms_output.put_line('Package ' || USER || '.' || rec.package_name || ' is invalid.');
         v_ok := false;
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

grant execute on &&defaultSchema..TOOLS to public;

quit;


