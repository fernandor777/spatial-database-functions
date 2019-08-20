package com.spdba.dbutils.io.exp.spreadsheet;

import com.spdba.dbutils.Constants;
import com.spdba.dbutils.spatial.Renderer.GEO_RENDERER_FORMAT;
import com.spdba.dbutils.spatial.Renderer;
import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.sql.DBConnection;
import com.spdba.dbutils.sql.SQLConversionTools;
import com.spdba.dbutils.tools.FileUtils;
import com.spdba.dbutils.tools.Strings;

import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.io.WKTWriter;
import org.locationtech.jts.io.gml2.GMLWriter;
import org.locationtech.jts.io.oracle.OraReader;

import java.io.File;
import java.io.IOException;
import java.io.Reader;

import java.math.BigDecimal;

import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;

import java.sql.Date;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Time;
import java.sql.Timestamp;

import jxl.JXLException;
import jxl.Workbook;

import jxl.format.Colour;
import jxl.format.CellFormat;
import jxl.format.ScriptStyle;
import jxl.format.UnderlineStyle;

import jxl.write.Blank;
import jxl.write.Boolean;
import jxl.write.DateFormat;
import jxl.write.DateTime;
import jxl.write.Label;
import jxl.write.Number;
import jxl.write.NumberFormats;
import jxl.write.WritableCell;
import jxl.write.WritableCellFormat;
import jxl.write.WritableFont;
import jxl.write.WritableSheet;
import jxl.write.WritableWorkbook;
import jxl.write.WriteException;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleTypes;

import oracle.sql.CLOB;
import oracle.sql.RAW;
import oracle.sql.ROWID;
import oracle.sql.STRUCT;

public class WriteExcelFile {

    /** Spreadsheets have row and column limits for a single worksheet
     **/
    protected static final int MAX_ROWS = 65535;    
    protected static final int MAX_COLS = 255;  
    protected static final int MAX_CELL_SIZE = 32768;
    
    // Some date and time formats
    private static DateFormat dateTimeFormatter = null;
    private static String     DATETIMEFORMAT    = "yyyy/MM/dd hh:mm:ss a";
    
    protected static DateFormat timeFormatter = null;
    protected static String     TIMEFORMAT = "H:mm:ss.ssssss";

    protected static void setTimeFormatString(String _timeFormat) {
        TIMEFORMAT = Strings.isEmpty(_timeFormat) ? "yyyy/MM/dd hh:mm:ss a" : _timeFormat;
        DATETIMEFORMAT = (Strings.isEmpty(DATEFORMAT) ? "yyyyMMdd" : DATEFORMAT) + " " + TIMEFORMAT;
    }

    protected static String       charSetName = "UTF-8";
    protected static DateFormat dateFormatter = null;
    protected static String     DATEFORMAT    = "yyyyMMdd";

    protected static void setDateFormatString(String _dateFormat) {
        DATEFORMAT = Strings.isEmpty(_dateFormat) ? "yyyyMMdd" : _dateFormat;
        DATETIMEFORMAT = DATEFORMAT + " " + (Strings.isEmpty(TIMEFORMAT) ? "H:mm:ss.ssssss" : TIMEFORMAT);
    }
    
    /** If MAX_ROWS/MAX_COLS exceed we have a stratitifa ion policy
     **/
    protected static char STRATIFICATION = 'N'; // No stratification
    public static final char HORIZONTAL = 'H';
    public static final char VERTICAL = 'V';
    public static final char NONE = 'N';

    public static void setStratification(char cStratification) {
        switch (cStratification) {
            case 'n' :
            case 'N' :
            case 'h' :
            case 'H' :
            case 'v' :
            case 'V' :
                STRATIFICATION = Character.toUpperCase(cStratification);
                break;
            default : throw new IllegalArgumentException("Stratification can only be one of N,H or V");
        }
    }
    
    /** Geometry data can be output but only in a supported string format.
     **/
    protected static final String SDO_GEOMETRY_TYPE = "MDSYS.SDO_GEOMETRY";    
    
    /** Maximum coordinates per line for GML and KML writers **/    
    public static final int MAX_COORDS_PER_LINE = 20;

    protected static Renderer.GEO_RENDERER_FORMAT GEOMETRY_FORMAT = GEO_RENDERER_FORMAT.WKT;

    private static WKTWriter wktWriter = null;
    private static GMLWriter gmlWriter = null;
  
    public static void setGeometryFormat(String _sFormat ) {
        if (Strings.isEmpty(_sFormat) ) {
            GEOMETRY_FORMAT = Renderer.GEO_RENDERER_FORMAT.WKT;
        } else {
            GEOMETRY_FORMAT = Renderer.GEO_RENDERER_FORMAT.getRendererFormat(_sFormat);
        }
        if ( GEOMETRY_FORMAT.equals(Renderer.GEO_RENDERER_FORMAT.WKT) ) {
            wktWriter = new WKTWriter();
            wktWriter.setFormatted(false);
        } else if ( GEOMETRY_FORMAT.equals(Renderer.GEO_RENDERER_FORMAT.GML) ) {
            gmlWriter = new GMLWriter();                
        } else if ( GEOMETRY_FORMAT.equals(Renderer.GEO_RENDERER_FORMAT.GML2) ) {
            gmlWriter = new GMLWriter();                
        } else if ( GEOMETRY_FORMAT.equals(Renderer.GEO_RENDERER_FORMAT.GML3) ) {
            gmlWriter = new GMLWriter();
            // gmlWriter.setNamespace(true);
        } 
    }
    
    public static Renderer.GEO_RENDERER_FORMAT getGeometryFormat() {
        return GEOMETRY_FORMAT;
    }
    
    protected static double precisionModelScale = 3;
    
    /**
     * setPrecisionScale
     * From JTS: 
     * For example, to specify 3 decimal places of precision, use a scale factor
     * of 1000. To specify -3 decimal places of precision (i.e. rounding to
     * the nearest 1000), use a scale factor of 0.001.
     *
     * @param _numDecPlaces : int : Number of digits of precision
     * @history Simon Greener, August 2011, Original Coding
     */
    public static void setPrecisionScale(int _numDecPlaces) {
        precisionModelScale = _numDecPlaces < 0 
                              ? (double)(1.0/Math.pow(10, Math.abs(_numDecPlaces))) 
                              : (double)Math.pow(10, _numDecPlaces);
    }
    public static double getPrecision() {
        return precisionModelScale;
    }

    public static void setCharSetName(String             _charSetName,
                                      java.sql.ResultSet _resultSet) 
    {
        charSetName = _charSetName;
        if (Strings.isEmpty(_charSetName) ) {
            try {
                DBConnection.setConnection((OracleConnection) _resultSet.getStatement().getConnection());
                String charSetName;
                charSetName = DBConnection.getCharacterSet(null);
                if (Strings.isEmpty(charSetName) ) {
                    charSetName = "US-ASCII"; 
                }
            } catch (SQLException e) {
            }
        } else {
            charSetName.toUpperCase();
        }
    }

    /** ====================== Start Cell Formatting ===================== **/
    
    // We allow cell formatting based on generic type
    protected static WritableCellFormat numberFormat;
    protected static WritableCellFormat integerFormat;
    protected static WritableCellFormat stringFormat;
    protected static WritableCellFormat stringFormatWrapped;
    protected static WritableCellFormat geomFormat;
    protected static WritableCellFormat geomFormatWrapped;
    protected static WritableCellFormat dateFormat;
    protected static WritableCellFormat datetimeFormat;
    protected static WritableCellFormat timeFormat;
    protected static WritableCellFormat boolFormat;

    protected static boolean isValidFontName(String fontName) {
        return  (fontName != null &&
                 (fontName.equalsIgnoreCase(WritableFont.ARIAL.toString()) ||
                  fontName.equalsIgnoreCase(WritableFont.COURIER.toString())||
                  fontName.equalsIgnoreCase(WritableFont.TAHOMA.toString()) ||
                  fontName.equalsIgnoreCase(WritableFont.TIMES.toString())));
    }

    protected static int getStyleFromName(String styleName) {
        int iStyle = -1;
        if ( styleName == null )
            return iStyle;

        if ( styleName.equalsIgnoreCase(ScriptStyle.NORMAL_SCRIPT.toString()))
            iStyle = ScriptStyle.NORMAL_SCRIPT.getValue();
        else if ( styleName.equalsIgnoreCase(ScriptStyle.SUBSCRIPT.toString()))
            iStyle = ScriptStyle.SUBSCRIPT.getValue();
        else if ( styleName.equalsIgnoreCase(ScriptStyle.SUPERSCRIPT.toString()))
            iStyle = ScriptStyle.SUPERSCRIPT.getValue();
        return iStyle;
    }

    protected static int getUnderlineFromName(String underlineName) {
        int iName = -1;
        if ( underlineName == null )
            return iName;
        if ( underlineName.equalsIgnoreCase(UnderlineStyle.DOUBLE.toString()))
            iName = UnderlineStyle.DOUBLE.getValue();
        else if ( underlineName.equalsIgnoreCase(UnderlineStyle.DOUBLE_ACCOUNTING.toString()))
            iName = UnderlineStyle.DOUBLE_ACCOUNTING.getValue();
        else if ( underlineName.equalsIgnoreCase(UnderlineStyle.NO_UNDERLINE.toString()))
            iName = UnderlineStyle.NO_UNDERLINE.getValue();
        else if ( underlineName.equalsIgnoreCase(UnderlineStyle.SINGLE.toString()))
            iName = UnderlineStyle.SINGLE.getValue();
        else if ( underlineName.equalsIgnoreCase(UnderlineStyle.SINGLE_ACCOUNTING.toString()))
            iName = UnderlineStyle.SINGLE_ACCOUNTING.getValue();
        return iName;
    }
    
    protected static int getColourFromName(String colourName) {
        int iColour = -1;
        if ( colourName == null )
            return iColour;
        Colour colours[] = Colour.getAllColours();
        for (int i = 0; i < colours.length - 1; i++) {
            if (colours[i].getDescription().equalsIgnoreCase(colourName.replaceAll("_"," "))) {
                iColour = colours[i].getValue();
                break;
            }
        }
        return iColour;
    }
    
    public static boolean isValidPointSize(int ps) {
        return (ps >= 6 && 
                ps <= 96);
    }

    protected static WritableFont createFont(String     fontName, 
                                              int        pointSize,
                                              boolean    bold,
                                              boolean    italics,
                                              String     colourName,
                                              String     styleName,
                                              String     underlineName) 
    {
        int colourIndex     = getColourFromName(colourName);
        int styleIndex      = getStyleFromName(styleName);
        int underlineIndex  = getUnderlineFromName(underlineName);
        if (!isValidFontName(fontName))     fontName = WritableFont.ARIAL.toString();
        if (!isValidPointSize(pointSize))   pointSize = 10;
        if (colourIndex == -1)              colourIndex = Colour.BLACK.getValue();
        if (styleIndex == -1)               styleIndex = ScriptStyle.NORMAL_SCRIPT.getValue();
        if (underlineIndex == -1 )          underlineIndex = UnderlineStyle.NO_UNDERLINE.getValue();
        return new WritableFont(WritableFont.createFont(fontName), 
                                pointSize, 
                                (bold ? WritableFont.BOLD : WritableFont.NO_BOLD), 
                                italics, 
                                UnderlineStyle.getStyle(underlineIndex), 
                                Colour.getInternalColour(colourIndex), 
                                ScriptStyle.getStyle(styleIndex));
    }
    
    public static void setStringFormat(String     fontName, 
                                       int        pointSize,
                                       boolean    bold,
                                       boolean    italics,
                                       String     colourName,
                                       String     styleName,
                                       String     underlineName) 
    throws WriteException 
    {
        stringFormat = new WritableCellFormat(createFont(fontName,pointSize,bold,italics,colourName,styleName,underlineName),
                                              NumberFormats.TEXT);
        stringFormatWrapped = new WritableCellFormat(stringFormat);
        stringFormatWrapped.setWrap(true);
        stringFormatWrapped.setShrinkToFit(false);
    }
    
    public static void setGeomCellFormat(String     fontName, 
                                     int        pointSize,
                                     boolean    bold,
                                     boolean    italics,
                                     String     colourName,
                                     String     styleName,
                                     String     underlineName) 
    throws WriteException 
    {
        geomFormat = new WritableCellFormat(createFont(fontName,pointSize,bold,italics,colourName,styleName,underlineName),
                                            NumberFormats.TEXT);
        geomFormatWrapped = new WritableCellFormat(geomFormat);
        geomFormatWrapped.setWrap(true);
        geomFormatWrapped.setShrinkToFit(false);
    }

    public static void setDateFormat(String     fontName, 
                                      int        pointSize,
                                      boolean    bold,
                                      boolean    italics,
                                      String     colourName,
                                      String     styleName,
                                      String     underlineName) 
    throws WriteException 
    {
        dateFormatter = new DateFormat(DATEFORMAT);
        dateFormat    = new WritableCellFormat(createFont(fontName,pointSize,bold,italics,colourName,styleName,underlineName),
                                               dateFormatter);
    }

    public static void setDatetimeFormat(String     fontName, 
                                         int        pointSize,
                                         boolean    bold,
                                         boolean    italics,
                                         String     colourName,
                                         String     styleName,
                                         String     underlineName) 
    throws WriteException 
    {
        dateTimeFormatter = new DateFormat(DATETIMEFORMAT);
        datetimeFormat    = new WritableCellFormat(createFont(fontName,pointSize,bold,italics,colourName,styleName,underlineName),
                                                   dateTimeFormatter);
    }

    public static void setTimeFormat(String     fontName, 
                                     int        pointSize,
                                     boolean    bold,
                                     boolean    italics,
                                     String     colourName,
                                     String     styleName,
                                     String     underlineName) 
    throws WriteException 
    {
        timeFormatter = new DateFormat(TIMEFORMAT);
        timeFormat    = new WritableCellFormat(createFont(fontName,pointSize,bold,italics,colourName,styleName,underlineName),
                                               timeFormatter);
    }

    /** ============================== End Cell Formatting =============================*/
    
    /**
     * Counts resultSet fields that are supported in output Excel file
     * @param metaData the result set's metadata
     * @throws SQLException if there is an error reading the result set metadata. 
     */
    protected static int supportedColumnCount(ResultSetMetaData metaData) 
    throws SQLException
    {
        int fieldCount = 0;
        for (int i = 1; i <= metaData.getColumnCount(); i++) {
             if (SQLConversionTools.isSupportedType(metaData.getColumnType(i),
                                                    metaData.getColumnTypeName(i))) 
                 fieldCount++;
        }
        return fieldCount;
    }
    
    /**
     * Creates column names in to first row of the last sheet in a workbook
     * @throws SQLException if there is an error reading the result set metadata. 
     */
    protected static void writeColumnHeadings( ResultSetMetaData   metaData,
                                               WritableWorkbook    workbook,
                                               int                 sheetNumber) 
    throws SQLException, Exception
    { 
        try { 
            // Create font for use with header
            WritableFont headingFont = new WritableFont(WritableFont.ARIAL, 12, WritableFont.BOLD);         
            headingFont.setColour(Colour.GRAY_80);
            WritableCellFormat headingFormat = new WritableCellFormat(headingFont);
    
            WritableSheet sheet = workbook.getSheet(sheetNumber);
            int colCount = 0; 
            for (int i = 1; i <= metaData.getColumnCount(); i++) 
            {
                if (SQLConversionTools.isSupportedType(metaData.getColumnType(i),
                                                       metaData.getColumnTypeName(i)))
                {
                    Label label = new Label(colCount, 0, metaData.getColumnName(i),headingFormat);
                    sheet.addCell(label);
                    colCount++;
                    // Stop processing when MAX_COLS reached with no overflow to subsequent sheets
                    if ( ( colCount % WriteExcelFile.MAX_COLS) == 0 ) {
                        if  ( STRATIFICATION ==
                            WriteExcelFile.VERTICAL ) {
                            // Create another sheet using first sheet as template
                            sheet = workbook.createSheet(
                                        workbook.getSheet(0).getName() + "_" + String.valueOf(workbook.getNumberOfSheets()),
                                        workbook.getNumberOfSheets());
                            // Reset col count
                            colCount = 0;
                        }
                        else
                            return;                
                    }
                }  // isSupportedType
            } // for 
        }
        catch (Exception e) {
            throw new Exception(e.getLocalizedMessage());
        }
    }

    /**
     * Reads the value at the specified column index as an object of the given class type.
     * @param _resultSet the result set.
     * @param _column the column index to read in the result set.
     * @param _converter - sdo_geometry to JTS geometry converter
     * @param _geometryFactory - Actual factory that does the conversion
     * @return the value as the required type.
     * @throws SQLException if there is an error reading the result set.
     */
    protected static Object getValue(ResultSet       _resultSet,
                                     int             _column,
                                     OraReader       _converter,
                                     GeometryFactory _geometryFactory,
                                     String          _charsetName) 
    throws  SQLException,
            IOException
    {
        Object cellObject = null;
        ResultSetMetaData metaData = _resultSet.getMetaData();
        Geometry geom;
        STRUCT stGeom;
        switch (metaData.getColumnType(_column))
        {
            case OracleTypes.STRUCT :
                String sGeometry = "";
                // Must be SDO_GEOMETRY as the isSupportedType only allows SDO_GEOMETRY STRUCTs
                // Convert geometry object
                stGeom = (STRUCT) _resultSet.getObject(_column);
                geom = _converter.read(stGeom);
                if (geom == null) 
                    sGeometry = "NULL";
                else {
                    // Bug in MultiLineHandler forces me to ...
                    if (geom instanceof LineString) 
                        geom = _geometryFactory.createMultiLineString(new LineString[] { (LineString) geom });
                    else
                        geom = _geometryFactory.createGeometry(geom); // do this to assign the PrecisionModel
                    if ( GEOMETRY_FORMAT.equals(GEO_RENDERER_FORMAT.WKT) ) {
                        // wktWriter is set on load first time
                        sGeometry = wktWriter.write(geom);
                    } else if ( GEOMETRY_FORMAT.equals(GEO_RENDERER_FORMAT.GML) ||
                                GEOMETRY_FORMAT.equals(GEO_RENDERER_FORMAT.GML3) ) {
                        gmlWriter.setSrsName(String.valueOf(geom.getSRID()));
                        sGeometry = gmlWriter.write(geom);
                    } else {
                        sGeometry = Renderer.renderSdoGeometry(stGeom, GEOMETRY_FORMAT);
                    }
                    geom = null;
                }
                cellObject = sGeometry;
                break;
            case OracleTypes.CLOB:
                String sClob = "";
                CLOB clobVal = ((OracleResultSet)_resultSet).getCLOB(_column);
                if (!_resultSet.wasNull()) {
                    Reader in = clobVal.getCharacterStream(  ); 
                    int length = (int)clobVal.length(); 
                    char[] buffer = new char[1024]; 
                    while ((length = in.read(buffer)) != -1) { 
                        sClob += String.valueOf(buffer).substring(0,length);
                    } 
                    in.close( ); 
                    in = null; 
                }
                cellObject =  sClob;
                break;
            case -3:
            case OracleTypes.RAW:
                RAW rawval = ((OracleResultSet)_resultSet).getRAW(_column);
                String sRaw = rawval.stringValue();
                cellObject = sRaw;
                break;
            case OracleTypes.ROWID:
                // Obtain the ROWID as a ROWID objects(which is an Oracle Extension
                // datatype. Since ROWID is an Oracle extension, the getROWID method
                // is not available in the ResultSet class. Hence ResultSet has to be
                // cast to OracleResultSet
                String sRowid;
                ROWID rowid = ((OracleResultSet)_resultSet).getROWID(_column);
                // Oracle ROWIDs are coded in HEX which means that a delimiter can't appear in it unless delimiter 0-9,A-F
                ByteBuffer asciiBytes = ByteBuffer.wrap(rowid.getBytes());
                Charset charset = Charset.forName(_charsetName);
                CharsetDecoder decoder = charset.newDecoder();
                CharBuffer rowidChars = null;
                try {
                   rowidChars = decoder.decode(asciiBytes);
                } catch (CharacterCodingException e) {
                   System.err.println("Error decoding rowid");
                   System.exit(-1);
                }
                sRowid = rowidChars.toString();
                cellObject = sRowid;
                break;
            case OracleTypes.NUMERIC :
                // If scale == 0 then make it a Long otherwise a Double
                if ( metaData.getScale(_column) == 0 )
                    cellObject = new Long(_resultSet.getLong(_column));
                else
                    cellObject = new Double(_resultSet.getDouble(_column));
                 break;
            case OracleTypes.FLOAT     : cellObject = new Float(_resultSet.getFloat(_column));       break;
            case OracleTypes.DOUBLE    : cellObject = new Double(_resultSet.getDouble(_column));     break;
            case OracleTypes.SMALLINT  : cellObject = new Short(_resultSet.getShort(_column));       break;
            case OracleTypes.INTEGER   : cellObject = new Integer(_resultSet.getInt(_column));       break;
            case OracleTypes.DECIMAL   : cellObject = new BigDecimal(_resultSet.getDouble(_column)); break;
            case OracleTypes.CHAR      : //cellObject = String.valueOf(_resultSet.getByte(_column));   break;
            case OracleTypes.VARCHAR   : cellObject = _resultSet.getString(_column);                 break;
            case OracleTypes.TIME      : cellObject = _resultSet.getTime(_column);                   break;
            case -100: /* This is actually a TIMESTAMP */
            case OracleTypes.TIMESTAMP : cellObject = _resultSet.getTimestamp(_column);              break;
            case OracleTypes.DATE      : cellObject = _resultSet.getDate(_column);                   break;
            default: cellObject = _resultSet.getObject(_column);
        } // switch case
        return cellObject;
    }

    /**
     * Creates column names in to first row of spreadsheet
     * @throws SQLException if there is an error reading the result set metadata. 
     */
    protected static void writeData( java.sql.ResultSet _resultSet,
                                     WritableWorkbook   _workbook) 
    throws SQLException, Exception, JXLException
    { 
        try { 
            // Get first sheet in workbook
            WritableSheet sheet = _workbook.getSheet(0);
            if ( sheet.getColumns() == 0 )
                throw new Exception("No heading columns written to sheet " + 
                                    _workbook.getSheet(0).getName());

            // Create default fonts and Formats if null
            if (numberFormat   == null) numberFormat  = new WritableCellFormat(createFont("TIMES", 10, false, false, "BLUE", "NORMAL_SCRIPT", null),
                                                                               NumberFormats.DEFAULT);
            if (integerFormat  == null) integerFormat = new WritableCellFormat(createFont("TIMES", 10, false, false, "GREEN", "NORMAL_SCRIPT", null),
                                                                               NumberFormats.INTEGER);
            if (stringFormat   == null) setStringFormat(  "ARIEL",12, false,false, "BLACK",      "NORMAL_SCRIPT",null);;
            if (geomFormat     == null) setGeomCellFormat("TIMES", 8, false,false, "SEA_GREEN",  "NORMAL_SCRIPT",null);
            if (dateFormat     == null) setDateFormat(    "ARIEL", 10, true,false, "DARK_YELLOW","NORMAL_SCRIPT", null);
            if (datetimeFormat == null) setDatetimeFormat("ARIEL",10,  true,false, "DARK_YELLOW","NORMAL_SCRIPT", null);
            if (timeFormatter  == null) setDatetimeFormat("ARIEL",10,  true,false, "DARK_YELLOW","NORMAL_SCRIPT", null);
            if (boolFormat == null)     boolFormat = new WritableCellFormat(createFont("COURIER", 10, true, false, "OLIVE_GREEN", "NORMAL_SCRIPT",null));

            // Get ResultSet metdata to determine if a field is supported
            ResultSetMetaData metaData = _resultSet.getMetaData();

            // Bug in JTS 1.8.1 and previous in MultiLineHandler sees need to handle linestring differently from polygons in for loop below */                    
            GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(getPrecision()));
            // - Conversion utility for Oracle geometry objects
            OraReader converter = new OraReader(geometryFactory); // doesn't need the Oracle connection for what we're using it for

            // Generic object to hold all data
            Object fieldValue;
            
            // variables for cell positions
            int colCount = 0;
            int rowCount = 0; 

            // Now process actual rowset and add rows to our spreadsheet
            int sheetNum;
            while ( _resultSet.next() )
            {
                rowCount++;
                colCount = 0;
                
                // At start of each record we write to the first sheet if vertical stratification
                sheetNum = 0;
                if ( STRATIFICATION == WriteExcelFile.VERTICAL )
                    sheet = _workbook.getSheet(0);
                
                for (int i = 1; i <= metaData.getColumnCount(); i++) 
                {
                    if (SQLConversionTools.isSupportedType(metaData.getColumnType(i),
                                                           metaData.getColumnTypeName(i)))
                    {
                        fieldValue = getValue(_resultSet,
                                              i,
                                              converter,
                                              geometryFactory,
                                              charSetName);
                        WritableCell cellData = null;
                        if (_resultSet.wasNull()) {
                            cellData = new Blank(colCount,rowCount);
                        } else if (metaData.getColumnType(i) == OracleTypes.STRUCT) {
                            String fValue = fieldValue.toString();
                            cellData = new Label(colCount, rowCount,
                                                 fValue.substring(0,
                                                                  (fValue.length() < WriteExcelFile.MAX_CELL_SIZE) ?
                                                                  fValue.length() : WriteExcelFile.MAX_CELL_SIZE),
                                                 geomFormatWrapped);
                        } else if (fieldValue.getClass().equals(String.class)) {
                            String fValue = fieldValue.toString();
                            cellData = new Label(colCount, rowCount, 
                                                 fValue.substring(0,
                                                                  (fValue.length() < WriteExcelFile.MAX_CELL_SIZE) ? 
                                                                  fValue.length() : WriteExcelFile.MAX_CELL_SIZE),
                                                 fValue.length() > 255 ? stringFormatWrapped : stringFormat);
                        } else if ( fieldValue.getClass().equals(Date.class)) {
                            cellData = new DateTime(colCount, rowCount,((Date)fieldValue), dateFormat ); 
                        } else if ( fieldValue.getClass().equals(DateTime.class) ||
                                    fieldValue.getClass().equals(Timestamp.class) ) {
                            cellData = new DateTime(colCount, rowCount, ((Timestamp)fieldValue), datetimeFormat);
                        } else if ( fieldValue.getClass().equals(Time.class)) {
                            cellData = new DateTime(colCount, rowCount,((Time)fieldValue),timeFormat ); 
                        } else if (fieldValue.getClass().equals(Float.class)) {
                            cellData = new Number(colCount, rowCount, ((Float)fieldValue).doubleValue(),numberFormat ); 
                        } else if (fieldValue.getClass().equals(Boolean.class)) {
                            cellData = new Boolean(colCount, rowCount, ((Boolean)fieldValue).getValue(),boolFormat );
                        } else if (fieldValue.getClass().equals(Long.class) ) {
                            cellData = new Number(colCount, rowCount, ((Long)fieldValue).longValue(),integerFormat);
                        } else if (fieldValue.getClass().equals(Short.class)) {
                            cellData = new Number(colCount, rowCount, ((Short)fieldValue).intValue(),integerFormat);
                        } else if (fieldValue.getClass().equals(Double.class)) {
                            cellData = new Number(colCount, rowCount, ((Double)fieldValue).doubleValue(),numberFormat ); 
                        }
                        sheet.addCell(cellData);
                        colCount++;
                        // Stop processing column data when MAX_COLS reached AND no overflow to additional sheets
                        if ( colCount == WriteExcelFile.MAX_COLS ) {
                            if ( STRATIFICATION == WriteExcelFile.VERTICAL ) {
                                sheet = _workbook.getSheet(++sheetNum);
                                colCount = 0;
                            }
                            else
                                break;
                        }
                    }
                } // for
                if ( ( rowCount % WriteExcelFile.MAX_ROWS ) == 0 ) 
                {
                    if ( STRATIFICATION ==
                        WriteExcelFile.HORIZONTAL ) 
                    {
                        // Create another sheet using first sheet as template
                        // 
                        sheet = _workbook.createSheet(_workbook.getSheet(0).getName() + 
                                                     "_" + 
                                                     String.valueOf(_workbook.getNumberOfSheets()),
                                                     (rowCount / WriteExcelFile.MAX_ROWS));
                        // Add column headings
                        writeColumnHeadings(metaData,_workbook,(rowCount / WriteExcelFile.MAX_ROWS));
                        // Reset row count
                        rowCount = 0;
                    }
                    else
                        break;
                } // rowCount % MAX_ROWS
            } // while resultset
        }
        catch (Exception e) {
            throw new Exception(e.getLocalizedMessage());
        }
    }
    
    /**
     * Creates and writes an Excel spreadsheet from the passed in resultSet
     * Overflow of resultSet across Sheets is controlled by _stratification.
     * If number of rows in _resultSet is > MAX_ROWS (65535) and _stratification
     * is N (NONE) or V (VERTICAL) then the resultSet processing will only output MAX_ROWS
     * in the first sheet. No more sheets will be created. 
     * If _stratification is H (HORIZONTAL) a new sheet is created for the next MAX_ROWS (65535).
     * If the resultSet contains > MAX_COLS (255) and _stratification is set to V (VERTICAL) then
     * the first 255 columns will be in the first sheet, the next 255 in the second sheet etc up
     * to the maxiumum number of rows that can be output in a SELECT statement. If > MAX_COLS exist
     * and _stratification is H or N then only 255 columns will be output in the first sheet: if
     * > MAX_ROWS also exists then overflow is controlled by _stratification = H or N.
     * 
     * NOTE: Maximum size of an Excel spreadsheet cell is 32768 characters.
     * 
     * @param _resultSet       - the result set, including a geometry column.
     * @param _outputDirectory - the directory to write output files to.
     * @param _fileName        - the file name of output files.
     * @param _sheetName       - Name of base or first sheet. Prefix for all others. 
     * @param _stratification  - Horizontal (H), Vertical (V) or None (N).
     * @param _geomFormat      - Text format for sdo_geometry columns eg WKT, GML, GML3
     * @param _dateFormat      - Format for output dates
     * @param _timeFormat      - Format for output times
     * @param _precision       - Number of decimal places of coordinates 
     * @history Simon Greener, The SpatialDB Advisor, October 2011, Original coding 
     */
    public static void write(java.sql.ResultSet _resultSet, 
                             java.lang.String   _outputDirectory, 
                             java.lang.String   _fileName,
                             java.lang.String   _sheetName,
                             java.lang.String   _stratification,
                             java.lang.String   _geomFormat,
                             java.lang.String   _dateFormat,
                             java.lang.String   _timeFormat,
                             java.lang.String   _charSetName,
                             int                _precision) 
    throws IOException, Exception
    {
        // Check input
        if (Strings.isEmpty(_outputDirectory)) throw new IllegalArgumentException("Output directory must be provided and Oracle user must have write permission.");
        if (Strings.isEmpty(_fileName))        throw new IllegalArgumentException("Filename must be provided");
        setStratification(_stratification.charAt(0));   
        setGeometryFormat(_geomFormat);
        setDateFormatString(_dateFormat);
        setTimeFormatString(_timeFormat);
        setPrecisionScale(_precision);
        setCharSetName(_charSetName,_resultSet);
        
        File file = null;
        WritableWorkbook workbook = null;
        try {            
            file = new File(FileUtils.FileNameBuilder(_outputDirectory,_fileName,"xls"));
            
            workbook = Workbook.createWorkbook(file);
  
            // Create initial sheet
            workbook.createSheet(Strings.isEmpty(_sheetName)?"Sheet":_sheetName,0);
            
            // Write first row to first sheet
            writeColumnHeadings(_resultSet.getMetaData(),workbook,0);
        
            // Write data
            writeData(_resultSet,workbook);
            
            workbook.write();
            workbook.close();
            workbook = null;
            file     = null;
        }
        catch (IOException ioe) {
            throw new IOException(ioe.getLocalizedMessage());
        }
        catch (SQLException sqle) {
            throw new SQLException(sqle.getLocalizedMessage());
        } finally {
            integerFormat = null;
            numberFormat = null;
            stringFormat = null;
            geomFormat = null;
            dateFormat = null;
            datetimeFormat = null;
            timeFormat = null;
            boolFormat = null;
            if (workbook != null) {
                try {
                    workbook.close();
                } catch (Exception e) {
                }
                workbook = null;
                file = null;
            }
        }
    }

}
