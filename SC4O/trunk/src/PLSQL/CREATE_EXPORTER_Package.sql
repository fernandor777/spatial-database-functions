DEFINE defaultSchema='&1'

SET VERIFY OFF;

WHENEVER SQLERROR EXIT FAILURE;

CREATE OR REPLACE PACKAGE Exporter
AUTHID CURRENT_USER
AS
  /****h* PACKAGE/EXPORTER
  *  NAME
  *    EXPORTER - This package exposes Java stored procedures that provide spatial data export.
  *  DESCRIPTION
  *    A package that allows for spatial data to be exported from within the database to a number of formats.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - January 2008 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
******/

  /****v* EXPORTER/ATTRIBUTES
  *  ATTRIBUTES
  *  SOURCE
  */

  Type refcur_t  Is Ref Cursor;
  Type tablist_t Is Table Of user_tab_columns.TABLE_NAME%Type;

  -- ==========================================================
  -- Excel Spreadssheet export
  -- ========================================================== 

  -- ---------
  -- Constants
  -- ----------
  -- 1. Stratification
  --
  c_HORIZONTAL_STRATIFICATION CONSTANT varchar2(1)  := 'H';
  c_VERTICAL_STRATIFICATION   CONSTANT varchar2(1)  := 'V';
  c_NO_STRATIFICATION         CONSTANT varchar2(1)  := 'N';

  -- 2. Date/Time formats
  --
  c_DATEFORMAT                CONSTANT varchar2(20) := 'yyyyMMdd';
  c_DATEFORMAT1               CONSTANT varchar2(20) := 'M/d/yy';
  c_DATEFORMAT2               CONSTANT varchar2(20) := 'd-MMM-yy';
  c_DATEFORMAT3               CONSTANT varchar2(20) := 'd-MMM';
  c_DATEFORMAT4               CONSTANT varchar2(20) := 'MMM-yy';

  c_TIMEFORMAT                CONSTANT varchar2(20) := 'h:mm a';
  c_TIMEFORMAT1               CONSTANT varchar2(20) := 'h:mm:ss a';
  c_TIMEFORMAT2               CONSTANT varchar2(20) := 'H:mm';
  c_TIMEFORMAT3               CONSTANT varchar2(20) := 'H:mm:ss';
  c_TIMEFORMAT4               CONSTANT varchar2(20) := 'mm:ss';
  c_TIMEFORMAT5               CONSTANT varchar2(20) := 'H:mm:ss';
  c_TIMEFORMAT6               CONSTANT varchar2(20) := 'H:mm:ss';

  -- 3. Shapefile
  --
  c_Point              CONSTANT varchar2(20) := 'point';
  c_Point_Z            CONSTANT varchar2(20) := 'pointz';
  c_Point_M            CONSTANT varchar2(20) := 'pointm';
  c_LineString         CONSTANT varchar2(20) := 'linestring';
  c_LineString_Z       CONSTANT varchar2(20) := 'linestringz';
  c_LineString_M       CONSTANT varchar2(20) := 'linestringm';
  c_Polygon            CONSTANT varchar2(20) := 'polygon';
  c_Polygon_Z          CONSTANT varchar2(20) := 'polygonz';
  c_Polygon_M          CONSTANT varchar2(20) := 'polygonm';
  c_Multi_Point        CONSTANT varchar2(20) := 'multipoint';
  c_Multi_Point_Z      CONSTANT varchar2(20) := 'multipointz';
  c_Multi_Point_M      CONSTANT varchar2(20) := 'multipointm';
  c_Multi_LineString   CONSTANT varchar2(20) := 'multilinestring';
  c_Multi_LineString_Z CONSTANT varchar2(20) := 'multilinestringz';
  c_Multi_LineString_M CONSTANT varchar2(20) := 'multilinestringm';
  c_Multi_Polygon      CONSTANT varchar2(20) := 'multipolygon';
  c_Multi_Polygon_Z    CONSTANT varchar2(20) := 'multipolygonz';
  c_Multi_Polygon_M    CONSTANT varchar2(20) := 'multipolygonm';

  -- 4. Polygon Ring Ordering
  --
  c_Ring_Oracle        CONSTANT varchar2(20) := 'ORACLE';
  c_Ring_Inverse       CONSTANT varchar2(20) := 'INVERSE';
  c_Ring_Clockwise     CONSTANT varchar2(20) := 'CLOCKWISE';
  c_Ring_AntiClockwise CONSTANT varchar2(20) := 'ANTICLOCKWISE';

  -- 5. DBASE file type choice
  --
  c_DBASEIII           CONSTANT varchar2(20) := 'DBASEIII';
  c_DBASEIII_WITH_MEMO CONSTANT varchar2(20) := 'DBASEIII_WITH_MEMO';
  c_DBASEIV            CONSTANT varchar2(20) := 'DBASEIV';
  c_DBASEIV_WITH_MEMO  CONSTANT varchar2(20) := 'DBASEIV_WITH_MEMO';
  c_FOXPRO_WITH_MEMO   CONSTANT varchar2(20) := 'FOXPRO_WITH_MEMO';

  -- 6. Shapefile and MapInfo Tab File ID NAMES
  --
  c_mapinfo_pk         CONSTANT varchar2(8)  := 'MI_PRINX'; -- For use when recordset or table has only a geometry
  c_shapefile_pk       CONSTANT varchar2(3)  := 'GID';      -- For use when recordset or table has only a geometry

  -- 7. Supported SDO_GEOMETRY as TEXT formats.
  --
  c_SDOGeometry CONSTANT varchar2(20) := 'SDO_GEOMETRY';
  c_STGeometry  CONSTANT varchar2(20) := 'ST_GEOMETRY';
  c_KML2        CONSTANT varchar2(20) := 'KML2';
  c_GML2        CONSTANT varchar2(20) := 'GML2';
  c_GML3        CONSTANT varchar2(20) := 'GML3';
  c_KML         CONSTANT varchar2(20) := 'KML';
  c_WKT         CONSTANT varchar2(20) := 'WKT';
  c_GEOJSON     CONSTANT varchar2(20) := 'GeoJSON';

  -- 8. XML Flavours for handling attributes of KML files ....
  --
  c_OGR          CONSTANT varchar2(20) := 'OGR';
  c_FME          CONSTANT varchar2(20) := 'FME';
  c_GML          CONSTANT varchar2(20) := 'GML';

  -- 9. CharSet names
  --
  c_UTF8        CONSTANT varchar2(128):= 'UTF-8';
  /*******/

  /****f* EXPORTER/WriteShapefile(refCursor)
  *  NAME
  *    WriteShapefile -- Procedure that writes an ESRI shapefile from an existing refcursor
  *  SYNOPSIS
  *  ARGUMENTS
  *    p_RefCursor           - Open Oracle ref cursor.
  *    p_output_dir          - the directory to write output files to.
  *    p_file_name           - the file name of output files.
  *    p_shape_type          - the type of shapefile eg polygon etc. See constants eg &&defaultSchema..EXPORTER.c_LineString
  *    p_geometry_name       - the name of the geometry column.
  *    p_ring_orientation    - Ring orientation to be applied to Polygon exports.
  *    p_dbase_type          - This exporter supports DBASEIII/DBASEIV With Memo.
  *                            Memo useful for exporting varchar2/clobs > 255 charaters.
  *    p_geometry_format     - Format for non-SHP sdo_geometry eg WKT, GML, GML3
  *    p_prj_string          - An ESRI PRJ file's contents.
  *                            PRJ writing. To have the shapefile writer create a correct PRJ file,
  *                            supply the contents of an existing PRJ file to the p_prj_string parameter.
  *                            If you do not have a valid PRJ file/string visit http://www.spatialreference.org/
  *    p_digits_of_precision - number of decimal places of ordinates
  *    p_commit              - When to write batch to disk
  *  DESCRIPTION
  *  NOTES
  *    Throws Exception if anything goes wrong.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2011, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Procedure WriteShapefile(p_RefCursor           in &&defaultSchema..EXPORTER.refcur_t,
                           p_output_dir          in VarChar2,
                           p_file_name           in VarChar2,
                           p_shape_type          in VarChar2,
                           p_geometry_name       in VarChar2,
                           p_ring_orientation    in VarChar2,
                           p_dbase_type          in VarChar2,
                           p_geometry_format     in VarChar2,
                           p_prj_string          in VarChar2,
                           p_digits_of_precision in Number,
                           p_commit              in Number );

 /****f* EXPORTER/WriteShapefile(varchar2)
  *  NAME
  *    WriteShapefile -- Procedure that writes an ESRI shapefile from a SQL SELECT statement (string)
  *  SYNOPSIS
  *  ARGUMENTS
  *    p_sql                 - A SELECT Statement that include a geometry column.
  *    p_output_dir          - the directory to write output files to.
  *    p_file_name           - the file name of output files.
  *    p_shape_type          - the type of shapefile eg polygon etc. See constants eg &&defaultSchema..EXPORTER.c_LineString
  *    p_geometry_name       - the name of the geometry column.
  *    p_ring_orientation    - Ring orientation to be applied to Polygon exports.
  *    p_dbase_type          - This exporter supports DBASEIII/DBASEIV With Memo.
  *                            Memo useful for exporting varchar2/clobs > 255 charaters.
  *    p_geometry_format     - Format for non-SHP sdo_geometry eg WKT, GML, GML3
  *    p_prj_string          - An ESRI PRJ file's contents.
  *                            PRJ writing. To have the shapefile writer create a correct PRJ file,
  *                            supply the contents of an existing PRJ file to the p_prj_string parameter.
  *                            If you do not have a valid PRJ file/string visit http://www.spatialreference.org/
  *    p_digits_of_precision - number of decimal places of ordinates
  *    p_commit              - When to write batch to disk
  *  DESCRIPTION
  *  NOTES
  *    Throws Exception if anything goes wrong.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2011, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Procedure WriteShapefile(p_sql                 in VarChar2,
                           p_output_dir          in VarChar2,
                           p_file_name           in VarChar2,
                           p_shape_type          in VarChar2,
                           p_geometry_name       in VarChar2,
                           p_ring_orientation    in VarChar2 := &&defaultSchema..EXPORTER.c_Ring_Inverse,
                           p_dbase_type          in VarChar2 := &&defaultSchema..EXPORTER.c_DBASEIII,
                           p_geometry_format     in VarChar2 := &&defaultSchema..EXPORTER.c_WKT,
                           p_prj_string          in VarChar2 := NULL,
                           p_digits_of_precision in Number   := 3,
                           p_commit              in Number   := 100 );

 /****f* EXPORTER/WriteTabFile(RefCursor)
  *  NAME
  *    WriteTabFile -- Procedure that writes a MapInfo TAB from an existing refCursor
  *  SYNOPSIS
  *  ARGUMENTS
  *    p_RefCursor           - the result set, including a geometry column.
  *    p_output_dir          - the directory to write output files to.
  *    p_file_name           - the file name of output files.
  *    p_shape_type          - the type of shapefile eg polygon etc. See constants eg &&defaultSchema..EXPORTER.c_LineString
  *    p_geometry_name       - The name of the sdo_geometry column to export.
  *    p_ring_orientation    - Ring orientation to be applied to Polygon exports.
  *    p_dbase_type          - This exporter supports DBASEIII/DBASEIV With Memo.
  *                            Memo useful for exporting varchar2/clobs > 255 charaters.
  *    p_geometry_format     - Format for non-SHP sdo_geometry eg WKT, GML, GML3
  *    p_coordsys            - MapInfo CoordSys string for writing to TAB file parameter.
  *    p_symbolisation       - A MapInfo symbol string for styling all geometry objects in tab file.
  *    p_digits_of_precision - number of decimal places of ordinates
  *    p_commit              - When to write batch to disk
  *  DESCRIPTION
  *  NOTES
  *    Throws Exception if anything goes wrong.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2011, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Procedure WriteTabfile(p_RefCursor           in &&defaultSchema..EXPORTER.refcur_t,
                         p_output_dir          in VarChar2,
                         p_file_name           in VarChar2,
                         p_shape_type          in VarChar2,
                         p_geometry_name       in VarChar2,
                         p_ring_orientation    in VarChar2,
                         p_dbase_type          in VarChar2,
                         p_geometry_format     in VarChar2,
                         p_coordsys            in VarChar2,
                         p_symbolisation       in VarChar2,
                         p_digits_of_precision in Number,
                         p_commit              in Number );

 /****f* EXPORTER/WriteTabFile(varchar2)
  *  NAME
  *    WriteTabFile -- Procedure that writes a MapInfo TAB from a SQL SELECT statement (string)
  *  SYNOPSIS
  *  ARGUMENTS
  *    p_sql                 - A SELECT Statement that include a geometry column.
  *    p_output_dir          - the directory to write output files to.
  *    p_file_name           - the file name of output files.
  *    p_shape_type          - the type of shapefile eg polygon etc. See constants eg &&defaultSchema..EXPORTER.c_LineString
  *    p_ring_orientation    - Ring orientation to be applied to Polygon exports.
  *    p_dbase_type          - This exporter supports DBASEIII/DBASEIV With Memo.
  *                            Memo useful for exporting varchar2/clobs > 255 charaters.
  *    p_geometry_format     - Format for non-SHP sdo_geometry eg WKT, GML, GML3
  *    p_coordsys            - MapInfo CoordSys string for writing to TAB file parameter.
  *    p_symbolisation       - A MapInfo symbol string for styling all geometry objects in tab file.
  *    p_digits_of_precision - number of decimal places of ordinates
  *    p_commit              - When to write batch to disk
  *  DESCRIPTION
  *  NOTES
  *    THrows Exception if anything goes wrong.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2011, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Procedure WriteTabfile(p_sql                 in VarChar2,
                         p_output_dir          in VarChar2,
                         p_file_name           in VarChar2,
                         p_shape_type          in VarChar2,
                         p_geometry_name       in VarChar2,
                         p_ring_orientation    in VarChar2 := &&defaultSchema..EXPORTER.c_Ring_Inverse,
                         p_dbase_type          in VarChar2 := &&defaultSchema..EXPORTER.c_DBASEIII,
                         p_geometry_format     in VarChar2 := &&defaultSchema..EXPORTER.c_WKT,
                         p_coordsys            in VarChar2 := NULL,
                         p_symbolisation       in VarChar2 := NULL,
                         p_digits_of_precision in Number   := 3,
                         p_commit              in Number   := 100 );

 /****f* EXPORTER/ExportTables
  *  NAME
  *    ExportTables -- Procedure that writes a collection of tables with geometry columns to disk
  *  SYNOPSIS
  *  ARGUMENTS
  *    p_tables     - list of tables to export
  *    p_output_dir - the directory to write output files to.
  *    p_digits_of_precision - number of decimal places of ordinates
  *    p_commit              - When to write batch to disk
  *    p_mi_coordsys         - MapInfo CoordSys string for writing to TAB file parameter.
  *    p_mi_style            - A MapInfo symbol string for styling all geometry objects in tab file.
  *    p_prj_string          - An ESRI PRJ file's contents.
  *    p_geomFormat          - Format for non-SHP sdo_geometry eg WKT, GML, GML3
  *  DESCRIPTION
  *  NOTES
  *    Throws Exception if anything goes wrong.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2011, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Procedure ExportTables(p_tables       In &&defaultSchema..EXPORTER.tablist_t,
                         p_output_dir   In VarChar2,
                         p_mi_coordsys  In VarChar2 := NULL,
                         p_mi_style     In VarChar2 := NULL,
                         p_prj_string   In VarChar2 := NULL);

 /****f* EXPORTER/WriteKMLFile(RefCursor)
  *  NAME
  *    WriteKMLFile -- Exports SQL Select refCursor to KML file.
  *  SYNOPSIS
  *  ARGUMENTS
  *  RETURNS
  *  DESCRIPTION
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2011, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Procedure WriteKMLFile(  p_RefCursor           in &&defaultSchema..EXPORTER.refcur_t,
                           p_output_dir          in VarChar2,
                           p_file_name           in VarChar2,
                           p_geometry_name       in VarChar2,
                           p_date_format         in VarChar2, /* Java SimpleDateFormat */
                           p_geometry_format     in VarChar2,
                           p_digits_of_precision in Number,
                           p_commit              in Number);

 /****f* EXPORTER/WriteGeoJson(RefCursor)
  *  NAME
  *    WriteGeoJson - Writes result of SQL Select to a GeoJson file.
  *  SYNOPSIS
  *  ARGUMENTS
  *  RETURNS
  *  DESCRIPTION
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2011, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Procedure WriteGeoJson(  p_RefCursor             in &&defaultSchema..EXPORTER.refcur_t,
                           p_output_dir            in VarChar2,
                           p_file_name             in VarChar2,
                           p_geometry_name         in VarChar2,
                           p_id_column             in VarChar2,
                           p_date_format           in VarChar2,
                           p_geometry_format       in VarChar2,
                           p_Agg_Multi_Geo_Columns in Number,
                           p_bbox                  in Number,
                           p_digits_of_precision   in Number,
                           p_commit                in Number);

 /****f* EXPORTER/WriteGMLFile(RefCursor)
  *  NAME
  *    WriteGMLFile - Writes result of SQL Select to a GML file.
  *  SYNOPSIS
  *  ARGUMENTS
  *  RETURNS
  *  DESCRIPTION
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2011, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Procedure WriteGMLFile(  p_RefCursor            in &&defaultSchema..EXPORTER.refcur_t,
                           p_output_dir           in VarChar2,
                           p_file_name            in VarChar2,
                           p_geometry_name        in VarChar2,
                           p_ring_orientation     in VarChar2,
                           p_GML_version          in VarChar2,
                           p_Attribute_flavour    in varchar2,
                           p_Attribute_group_name in varchar2,
                           p_geometry_format      in VarChar2,
                           p_digits_of_precision  In Number,
                           p_commit               In Number );

 /****f* EXPORTER/WriteTextFile(RefCursor)
  *  NAME
  *    WriteTextFile -- Writes result set to a delimited text file.
  *  SYNOPSIS
  *  DESCRIPTION
  *    Procedure that writes a result set (including one or more sdo_geometry objects - as a delimited text file eg csv.
  *    Supports all Oracle types except LONG, LONG RAW, BLOB, VARRAY and STRUCT (non SDO_GEOMETRY)
  *  ARGUMENTS
  *    p_RefCursor           - The result set, including a geometry column.
  *    p_outputDirectory     - The directory to write output files to.
  *    p_fileName            - The file name of output files.
  *    p_FieldSeparator      - The character between the values in the output file (could be a comma, or a pipe etc)
  *                            Default if NULL is a comma ','
  *    p_TextDelimiter       - The character used to enclose text strings (especially where contain cSeparator)
  *                            Default if NULL is a double quote '''
  *    p_DateFormat          - Format for output dates
  *                            DEFAULT of NULL is 'yyyy/MM/dd hh:mm:ss a'
  *    p_geomFormat          - Format for non-SHP sdo_geometry eg WKT, GML, GML3
  *                            Default if NULL is WKT
  *    p_charset             - CharSet of file being written
  *                            Default if NULL is US-ASCII
  *    p_digits_of_precision - Number of decimal places of ordinates
  *                            Default if NULL is 3
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - May 2008, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Procedure WriteTextFile(p_RefCursor           In &&defaultSchema..EXPORTER.refcur_t,
                          p_output_dir          In VarChar2,
                          p_file_name           In VarChar2,
                          p_field_separator     In char,
                          p_Text_Delimiter      In char,
                          p_date_format         In varchar2,
                          p_geometry_format     In Varchar2,
                          p_digits_of_precision in Number );

 /****f* EXPORTER/writeSpreadsheet(RefCursor)
  *  NAME
  *    writeSpreadsheet - Writes data in result set to spreadsheet.
  *  SYNOPSIS
  *  ARGUMENTS
  *    p_resultSet           - the result set, including a geometry column.
  *    p_outputDirectory     - the directory to write output files to.
  *    p_fileName            - the file name of output files.
  *    p_sheetName           - Name of base or first sheet. Prefix for all others.
  *    p_stratification      - Horizontal (H), Vertical (V) or None (N).
  *    p_geomFormat          - Text format for sdo_geometry columns eg WKT, GML, GML3
  *    p_dateFormat          - Format for output dates
  *    p_timeFormat          - Format for output times
  *    p_digits_of_precision - Number of decimal places of coordinates
  *  DESCRIPTION
  *    Creates and writes an Excel XLS format spreadsheet from the passed in resultSet.
  *    Overflow of resultSet across Sheets is controlled by _stratification.
  *    If number of rows in _resultSet is > MAX_ROWS (65535) and _stratification
  *    is N (NONE) or V (VERTICAL) then the resultSet processing will only output MAX_ROWS
  *    in the first sheet. No more sheets will be created.
  *
  *    If _stratification is H (HORIZONTAL) a new sheet is created for the next MAX_ROWS (65535).
  *    If the resultSet contains > MAX_COLS (255) and _stratification is set to V (VERTICAL) then
  *    the first 255 columns will be in the first sheet, the next 255 in the second sheet etc up
  *    to the maxiumum number of rows that can be output in a SELECT statement.
  *
  *    If > MAX_COLS exist and _stratification is H or N then only 255 columns will be output in
  *    the first sheet: if > MAX_ROWS also exists then overflow is controlled by _stratification = H or N.
  *  NOTES
  *    Does not write any modern XML format spreadsheets.
  *    Maximum size of an Excel spreadsheet cell is 32768 characters.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - October 2011, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Procedure writeSpreadsheet(p_RefCursor           In &&defaultSchema..EXPORTER.refcur_t,
                             p_outputDirectory     In VarChar2,
                             p_fileName            In VarChar2,
                             p_sheetName           In VarChar2,
                             p_stratification      In VarChar2 default &&defaultSchema..EXPORTER.c_HORIZONTAL_STRATIFICATION,
                             p_geomFormat          In Varchar2 default &&defaultSchema..EXPORTER.c_WKT,
                             p_DateFormat          In varchar2 default &&defaultSchema..EXPORTER.c_DATEFORMAT,
                             p_TimeFormat          In varchar2 default &&defaultSchema..EXPORTER.c_TIMEFORMAT,
                             p_charSetName         In varchar  default 'US-ASCII',
                             p_digits_of_precision In number   default 7
                           );

  /****f* EXPORTER/writeSpreadsheet(varchar2)
  *  NAME
  *    writeSpreadsheet - Executes SQL statement and writes resultset to an Excel spreadsheet.
  *  SYNOPSIS
  *  ARGUMENTS
  *    p_sql                 - A SELECT Statement that include a geometry column.
  *    p_outputDirectory     - the directory to write output files to.
  *    p_fileName            - the file name of output files.
  *    p_sheetName           - Name of base or first sheet. Prefix for all others.
  *    p_stratification      - Horizontal (H), Vertical (V) or None (N).
  *    p_geomFormat          - Text format for sdo_geometry columns eg WKT, GML, GML3 ...
  *    p_dateFormat          - Format for output dates
  *    p_timeFormat          - Format for output times
  *    p_digits_of_precision - Number of decimal places of coordinates
  *  DESCRIPTION
  *    Creates and writes an Excel XLS format spreadsheet from the passed in resultSet.
  *    Overflow of resultSet across Sheets is controlled by _stratification.
  *    If number of rows in _resultSet is > MAX_ROWS (65535) and _stratification
  *    is N (NONE) or V (VERTICAL) then the resultSet processing will only output MAX_ROWS
  *    in the first sheet. No more sheets will be created.
  *
  *    If _stratification is H (HORIZONTAL) a new sheet is created for the next MAX_ROWS (65535).
  *    If the resultSet contains > MAX_COLS (255) and _stratification is set to V (VERTICAL) then
  *    the first 255 columns will be in the first sheet, the next 255 in the second sheet etc up
  *    to the maxiumum number of rows that can be output in a SELECT statement.
  *
  *    If > MAX_COLS exist and _stratification is H or N then only 255 columns will be output in
  *    the first sheet: if > MAX_ROWS also exists then overflow is controlled by _stratification = H or N.
  *  NOTES
  *    Does not write any modern XML format spreadsheets.
  *    Maximum size of an Excel spreadsheet cell is 32768 characters.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - October 2011, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Procedure writeSpreadsheet(p_sql                 In VarChar2,
                             p_outputDirectory     In VarChar2,
                             p_fileName            In VarChar2,
                             p_sheetName           In VarChar2,
                             p_stratification      In VarChar2 default &&defaultSchema..EXPORTER.c_HORIZONTAL_STRATIFICATION,
                             p_geomFormat          In Varchar2 default &&defaultSchema..EXPORTER.c_WKT,
                             p_DateFormat          In varchar2 default &&defaultSchema..EXPORTER.c_DATEFORMAT,
                             p_TimeFormat          In varchar2 default &&defaultSchema..EXPORTER.c_TIMEFORMAT,
                             p_charSetName         In varchar  default 'US-ASCII',
                             p_digits_of_precision In number   default 7);

 /****f* EXPORTER/RunCommand
  *  NAME
  *    RunCommand -- Method that allows an Oracle stored procedure to execute an external program (eg ogr2ogr) from within the database.
  *  SYNOPSIS
  *  ARGUMENTS
  *  RETURNS
  *    Error code: 0 if OK, otherwise error code.
  *  DESCRIPTION
  *    This function allows an Oracle stored procedure to execute an external program from within the database.
  *    An example might be the ability to execute ogr2ogr to convert a shapefile written by the WriteShapefile procedure
  *    to another spatial format.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2011, Original Coding
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Function RunCommand( p_command in varchar2 )
    Return Number Deterministic;

End Exporter;
/
SHOW ERRORS

create or replace 
PACKAGE BODY Exporter
AS

  c_module_name          CONSTANT varchar2(256) := 'Exporter';

  Procedure WriteShapefile(p_RefCursor           in &&defaultSchema..EXPORTER.refcur_t,
                           p_output_dir          in VarChar2,
                           p_file_name           in VarChar2,
                           p_shape_type          in VarChar2,
                           p_geometry_name       in VarChar2,
                           p_ring_orientation    in VarChar2,
                           p_dbase_type          in VarChar2,
                           p_geometry_format     in VarChar2,
                           p_prj_string          in VarChar2,
                           p_digits_of_precision in Number,
                           p_commit              in Number )
  As language java name
     'com.spdba.dbutils.io.exp.shp.WriteSHPFile.write(java.sql.ResultSet,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,int,int)';

  Procedure WriteShapefile(p_sql                 in VarChar2,
                           p_output_dir          in VarChar2,
                           p_file_name           in VarChar2,
                           p_shape_type          in VarChar2,
                           p_geometry_name       in VarChar2,
                           p_ring_orientation    in VarChar2 := &&defaultSchema..EXPORTER.c_Ring_Inverse,
                           p_dbase_type          in VarChar2 := &&defaultSchema..EXPORTER.c_DBASEIII,
                           p_geometry_format     in VarChar2 := &&defaultSchema..EXPORTER.c_WKT,
                           p_prj_string          in VarChar2 := NULL,
                           p_digits_of_precision in Number   := 3,
                           p_commit              in Number   := 100 )
  As
    c_refcursor GIS.EXPORTER.refcur_t;
  Begin
    OPEN c_refcursor FOR p_sql;
    &&defaultSchema..EXPORTER.WriteShapefile(
              p_RefCursor           => c_refcursor,
              p_output_dir          => p_output_dir,
              p_file_name           => p_file_name,
              p_shape_type          => p_shape_type,
              p_geometry_name       => p_geometry_name,
              p_ring_orientation    => p_ring_orientation,
              p_dbase_type          => p_dbase_type,
              p_geometry_format     => p_geometry_format,
              p_prj_string          => p_prj_string,
              p_digits_of_precision => p_digits_of_precision,
              p_commit              => p_commit
    );
  End WriteShapefile;

  Procedure WriteTabfile(p_RefCursor           in &&defaultSchema..EXPORTER.refcur_t,
                         p_output_dir          in VarChar2,
                         p_file_name           in VarChar2,
                         p_shape_type          in VarChar2,
                         p_geometry_name       in VarChar2,
                         p_ring_orientation    in VarChar2,
                         p_dbase_type          in VarChar2,
                         p_geometry_format     in VarChar2,
                         p_coordsys            in VarChar2,
                         p_symbolisation       in VarChar2,
                         p_digits_of_precision in Number,
                         p_commit              in Number)
  As language java name
     'com.spdba.dbutils.io.exp.tab.WriteTABFile.write(java.sql.ResultSet,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,int,int)';

  Procedure WriteTabfile(p_sql                 in VarChar2,
                         p_output_dir          in VarChar2,
                         p_file_name           in VarChar2,
                         p_shape_type          in VarChar2,
                         p_geometry_name       in VarChar2,
                         p_ring_orientation    in VarChar2 := &&defaultSchema..EXPORTER.c_Ring_Inverse,
                         p_dbase_type          in VarChar2 := &&defaultSchema..EXPORTER.c_DBASEIII,
                         p_geometry_format     in VarChar2 := &&defaultSchema..EXPORTER.c_WKT,
                         p_coordsys            in VarChar2 := NULL,
                         p_symbolisation       in VarChar2 := NULL,
                         p_digits_of_precision in Number   := 3,
                         p_commit              in Number   := 100)
  As
    c_refcursor GIS.EXPORTER.refcur_t;
  Begin
    OPEN c_refcursor FOR p_sql;
    &&defaultSchema..EXPORTER.WriteTabfile(
                 p_RefCursor           => c_RefCursor,
                 p_output_dir          => p_output_dir,
                 p_file_name           => p_file_name,
                 p_shape_type          => p_shape_type,
                 p_geometry_name       => p_geometry_name,
                 p_ring_orientation    => p_ring_orientation,
                 p_dbase_type          => p_dbase_type,
                 p_geometry_format     => p_geometry_format,
                 p_coordsys            => p_coordsys,
                 p_symbolisation       => p_symbolisation,
                 p_digits_of_precision => p_digits_of_precision,
                 p_commit              => p_commit
    );
  End WriteTabfile;

  Procedure WriteKMLFile(  p_RefCursor           in &&defaultSchema..EXPORTER.refcur_t,
                           p_output_dir          in VarChar2,
                           p_file_name           in VarChar2,
                           p_geometry_name       in VarChar2,
                           p_date_format         in VarChar2, /* Java SimpleDateFormat */
                           p_geometry_format     in VarChar2,
                           p_digits_of_precision in NUMBER,
                           p_commit              in Number)
  As language java name
     'com.spdba.dbutils.io.exp.kml.WriteKMLFile.write(java.sql.ResultSet,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,int,int)';

  Procedure WriteGeoJson(  p_RefCursor             in &&defaultSchema..EXPORTER.refcur_t,
                           p_output_dir            in VarChar2,
                           p_file_name             in VarChar2,
                           p_geometry_name         in VarChar2,
                           p_id_column             in VarChar2,
                           p_date_format           in VarChar2,
                           p_geometry_format       in VarChar2,
                           p_Agg_Multi_Geo_Columns in Number,
                           p_bbox                  in Number,
                           p_digits_of_precision   in Number,
                           p_commit                in Number)
  As language java name
     'com.spdba.dbutils.io.exp.geojson.WriteGeoJSONFile.write(java.sql.ResultSet,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,int,int,int,int)';

  Procedure WriteGMLFile(  p_RefCursor            in &&defaultSchema..EXPORTER.refcur_t,
                           p_output_dir           in VarChar2,
                           p_file_name            in VarChar2,
                           p_geometry_name        in VarChar2,
                           p_ring_orientation     in VarChar2,
                           p_GML_version          in VarChar2,
                           p_Attribute_flavour   in varchar2,
                           p_Attribute_group_name in varchar2,
                           p_geometry_format      in VarChar2,
                           p_digits_of_precision  in Number,
                           p_commit               in Number )
  As language java name
          'com.spdba.dbutils.io.exp.gml.WriteGMLFile.write(java.sql.ResultSet,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,int,int)';

  Procedure WriteTextFile(p_RefCursor           In GIS.EXPORTER.refcur_t,
                          p_output_dir          In VarChar2,
                          p_file_name           In VarChar2,
                          p_field_separator     In char,
                          p_Text_Delimiter      In char,
                          p_date_format         In varchar2,
                          p_geometry_format     In Varchar2,
                          p_digits_of_precision in Number )
  As language java name
     'com.spdba.dbutils.io.exp.csv.WriteDelimitedFile.write(java.sql.ResultSet,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,int)';

  /* ==========================================================
  ** Excel Spreadssheet export
  ** ========================================================== */

  Procedure WriteSpreadsheetIMPL(p_RefCursor           In &&defaultSchema..EXPORTER.refcur_t,
                                 p_outputDirectory     In VarChar2,
                                 p_fileName            In VarChar2,
                                 p_sheetName           In VarChar2,
                                 p_stratification      In VarChar2,
                                 p_geomFormat          In Varchar2,
                                 p_DateFormat          In varchar2,
                                 p_TimeFormat          In varchar2,
                                 p_charSetName         In varchar,
                                 p_digits_of_precision In number)
  As language java name
     'com.spdba.dbutils.io.exp.spreadsheet.WriteExcelFile.write(java.sql.ResultSet,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,java.lang.String,int)';

  Procedure writeSpreadsheet(p_RefCursor            In &&defaultSchema..EXPORTER.refcur_t,
                             p_outputDirectory     In VarChar2,
                             p_fileName            In VarChar2,
                             p_sheetName           In VarChar2,
                             p_stratification      In VarChar2 default &&defaultSchema..EXPORTER.c_HORIZONTAL_STRATIFICATION,
                             p_geomFormat          In Varchar2 default &&defaultSchema..EXPORTER.c_WKT,
                             p_DateFormat          In varchar2 default &&defaultSchema..EXPORTER.c_DATEFORMAT,
                             p_TimeFormat          In varchar2 default &&defaultSchema..EXPORTER.c_TIMEFORMAT,
                             p_charSetName         In varchar  default 'US-ASCII',
                             p_digits_of_precision In number   default 7)
  As
  Begin
    WriteSpreadsheetIMPL(p_RefCursor,
                         p_outputDirectory,
                         p_fileName,
                         p_sheetName,
                         p_stratification,
                         p_geomFormat,
                         p_DateFormat,
                         p_TimeFormat,
                         p_charSetName,
                         p_digits_of_precision);
  End writeSpreadsheet;

  Procedure writeSpreadsheet(p_sql                 In VarChar2,
                             p_outputDirectory     In VarChar2,
                             p_fileName            In VarChar2,
                             p_sheetName           In VarChar2,
                             p_stratification      In VarChar2 default &&defaultSchema..EXPORTER.c_HORIZONTAL_STRATIFICATION,
                             p_geomFormat          In Varchar2 default &&defaultSchema..EXPORTER.c_WKT,
                             p_DateFormat          In varchar2 default &&defaultSchema..EXPORTER.c_DATEFORMAT,
                             p_TimeFormat          In varchar2 default &&defaultSchema..EXPORTER.c_TIMEFORMAT,
                             p_charSetName         In varchar  default 'US-ASCII',
                             p_digits_of_precision In number   default 7)
  As
    c_refcursor GIS.EXPORTER.refcur_t;
  Begin
    OPEN c_refcursor FOR p_sql;
    WriteSpreadsheetIMPL(c_RefCursor,
                         p_outputDirectory,
                         p_fileName,
                         p_sheetName,
                         p_stratification,
                         p_geomFormat,
                         p_DateFormat,
                         p_TimeFormat,
                         p_charSetName,
                         p_digits_of_precision);
  End writeSpreadsheet;

  Procedure ExportTables(p_tables       In &&defaultSchema..EXPORTER.tablist_t,
                         p_output_dir   In VarChar2,
                         p_mi_coordsys  In VarChar2 := NULL,
                         p_mi_style     In VarChar2 := NULL,
                         p_prj_string   In VarChar2 := NULL)
  As

    v_geom_col user_tab_columns.COLUMN_NAME%Type;
    v_posn number;
    v_i    number;
    v_sql  varchar2(4000);
    v_upper_shape varchar2(4000) := 'select case gtype
              when 7 then ''' || c_Multi_Polygon || '''
              when 6 then ''' || c_Multi_Linestring || '''
              when 5 then ''' || c_Multi_Point || '''
              when 3 then ''' || c_Polygon || '''
              when 2 then ''' || c_Linestring || '''
              when 1 then ''' || c_Point || '''
              else NULL
          end as shapetype
    from (select distinct mod(a.';
    v_mid_shape   varchar2(4000) := '.sdo_gtype,10) as gtype from ';
    v_lower_shape varchar2(4000) := ' a order by 1 desc) where rownum = 1';
    v_shape_type  varchar2(4000);

    Cursor c_export_list(p_table in user_tab_columns.table_name%type,
                         p_geom_col in user_tab_columns.column_name%type)
    Is
      Select column_name
        from user_tab_columns u
       where u.table_name = UPPER(p_table)
         and u.column_name <> UPPER(p_geom_col)
         and u.data_type <> 'SDO_GEOMETRY';

    Procedure DoExport(p_sql             in varchar2,
                       p_shape_filename  in varchar2,
                       p_geometry_column in varchar2,
                       p_shape_type      in varchar2)
    As
      c_refcur &&defaultSchema..EXPORTER.refcur_t;
    Begin
      open c_refcur for p_sql;
      If ( p_mi_coordSys is not null ) Then
        &&defaultSchema..EXPORTER.WriteTabfile(
                     p_RefCursor           => c_refcur,
                     p_output_dir          => p_output_dir,
                     p_file_name           => p_shape_filename,
                     p_shape_type          => p_shape_type,
                     p_geometry_name       => p_geometry_column,
                     p_ring_orientation    => &&defaultSchema..EXPORTER.c_Ring_Inverse,
                     p_dbase_type          => &&defaultSchema..EXPORTER.c_DBASEIII,
                     p_geometry_format     => &&defaultSchema..EXPORTER.c_WKT,
                     p_coordsys            => p_mi_coordSys,
                     p_symbolisation       => p_mi_style,
                     p_digits_of_precision => 7,
                     p_commit              => 100
        );
      Else
        &&defaultSchema..EXPORTER.WriteShapefile(
                  p_RefCursor           => c_refcur,
                     p_output_dir          => p_output_dir,
                     p_file_name           => p_shape_filename,
                     p_shape_type          => p_shape_type,
                     p_geometry_name       => p_geometry_column,
                     p_ring_orientation    => &&defaultSchema..EXPORTER.c_Ring_Inverse,
                     p_dbase_type          => &&defaultSchema..EXPORTER.c_DBASEIII,
                     p_geometry_format     => &&defaultSchema..EXPORTER.c_WKT,
                     p_prj_string          => p_prj_string,
                     p_digits_of_precision => 7,
                     p_commit              => 100
        );
      End If;
      EXCEPTION
         WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE(p_shape_filename || ' ' || SQLERRM);
    End DoExport;

    Function CollectionIsOK
      Return Boolean
    Is
      v_OK Boolean := True;
    Begin
      If ( p_tables.COUNT < 1 ) Then
         v_OK := False;
      End If;
      Return v_OK;
      Exception
         When COLLECTION_IS_NULL Then
            Return False;
    End;

  begin
    If CollectionIsOK Then
    for v_i in p_tables.FIRST..p_tables.LAST loop
      begin
        -- Check if table has a geometry column (pick first if more than one)
        select a.column_name
          into v_geom_col
          from (select rownum as selposn,column_name,data_type
                  from (select utc.column_name,utc.data_type
                          from user_tab_columns utc
                         where utc.table_name = UPPER(p_tables(v_i))
                        order by utc.column_name
                       )
                ) a
         where a.data_type = 'SDO_GEOMETRY'
           and rownum = 1;
        -- Now get type of geometries in the column
        execute immediate v_upper_shape || v_geom_col || v_mid_shape || p_tables(v_i) || v_lower_shape
           into v_shape_type;
        If ( v_shape_type is not null ) Then
          -- Now, construct the select statement to be used to export the data.
          v_sql := 'SELECT ' || v_geom_col || ',';
          For rec In c_export_list(p_tables(v_i),v_geom_col) Loop
            v_sql := v_sql || rec.column_name || ',';
          End Loop;
          IF ( v_sql = 'SELECT ' || v_geom_col || ',' ) Then
             -- No columns other than SDO_GEOMETRY column, add in ROWNUM
             v_sql := v_sql || 'CAST(rownum AS Number(10)) AS ' ||
                      Case When p_mi_coordSys is not null
                           Then c_mapinfo_pk
                           Else c_shapefile_pk
                       End;
          ELSE
             v_sql := SUBSTR(v_sql,1,LENGTH(v_sql)-1);
          END IF;
          v_sql := v_sql ||
                    ' FROM ' || p_tables(v_i) ||
                   ' WHERE ' || v_geom_col || ' IS NOT NULL';
          DoExport(v_sql,p_tables(v_i),v_geom_col,v_shape_type);
        End If;
        Exception
           When No_Data_Found Then
             NULL; -- Skip this table
      end;
    end loop;
    End If;
  end ExportTables;

  Function RunCommand( p_command in varchar2 )
    Return Number
        As language java name
           'com.spdba.dbutils.tools.FileUtils.RunCommand(java.lang.String) return int';

END Exporter;
/
SHOW ERRORS

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'EXPORTER';
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

EXIT SUCCESS;
