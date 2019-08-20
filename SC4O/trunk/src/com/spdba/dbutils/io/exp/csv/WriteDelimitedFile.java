package com.spdba.dbutils.io.exp.csv;

import com.spdba.dbutils.Constants;
import com.spdba.dbutils.spatial.Renderer.GEO_RENDERER_FORMAT;
import com.spdba.dbutils.sql.DBConnection;
import com.spdba.dbutils.sql.OraRowSetMetaDataImpl;
import com.spdba.dbutils.sql.SQLConversionTools;
import com.spdba.dbutils.tools.FileUtils;
import com.spdba.dbutils.tools.Strings;
import com.spdba.dbutils.tools.Tools;

import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.io.oracle.OraReader;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;

import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;

import java.text.SimpleDateFormat;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleResultSetMetaData;


/**
 * Exports a resultSet to a delimited file
 * <p>
 * Supports all Oracle types except LONG, LONG RAW, BLOB, VARRAY and STRUCT
 * <p>
 *
 * @author Simon Greener, The SpatialDB Advisor, May 2008
 *
 */
public class WriteDelimitedFile {

    protected static final String SDO_GEOMETRY_TYPE = "MDSYS.SDO_GEOMETRY";

    protected static String DATEFORMAT = "yyyy/MM/dd hh:mm:ss a";
    
    public static void setDateFormat( String dateFormat) {
        DATEFORMAT = dateFormat;
    }
    
    public static String getDateFormat() {
        return DATEFORMAT;
    }

    protected static char FIELD_SEPARATOR = ',';
    
    public static void setFieldSeparator( char ch ) {
        FIELD_SEPARATOR = ch;
    }
    
    public static char getFieldSeparator() {
        return FIELD_SEPARATOR;
    }

    protected static char TEXT_DELIMITER = ',';

    public static void getTextDelimiter( char ch ) {
        TEXT_DELIMITER = ch;
    }
    
    public static char getTextDelimiter() {
        return TEXT_DELIMITER;
    }

    public static final String WKT_FORMAT = "WKT";
    public static final String GML_FORMAT = "GML";
    protected static String GEOMETRY_FORMAT = WKT_FORMAT;

    public static void setGeometryFormat( String sFormat ) {
        if ( sFormat.equalsIgnoreCase(WKT_FORMAT) ||
             sFormat.equalsIgnoreCase(GML_FORMAT) )
            GEOMETRY_FORMAT = sFormat.toUpperCase();  // Locale
    }
    
    public static String getGeometryFormat() {
        return GEOMETRY_FORMAT;
    }
    
    /**
     * Creates the file header corresponding to the metadata of the given result set
     * @param metaData the result set's metadata to create the delimited file's header from.
     * @return separator - the character string that holds the single character field separator
     * @throws SQLException if there is an error reading the result set metadata. 
     */
    protected static String getHeadings(ResultSetMetaData metaData,
                                        java.lang.String separator) 
    throws SQLException 
    { 
        String header = "";
        for (int i = 1; i <= metaData.getColumnCount(); i++) 
        {
             if (SQLConversionTools.isSupportedType(metaData.getColumnType(i),
                                 metaData.getColumnTypeName(i)))
             {
                header += (i == 1 ) ? 
                            metaData.getColumnName(i) : 
                            separator + 
                            metaData.getColumnName(i);
             }
        } // for 
        return header + "\n";
    }

    /**
     * Main execution method.
     * <p>
     * Writes the given result as delimited text files 
     *  
     * @param resultSet the result set, including a geometry column.
     * @param outputDirectory the directory to write output files to.
     * @param fileName the file name of output files.
     * @param cSeparator the character between the values in the output file (could be a comma, or a pipe etc)
     * @param cDelimiter the character used to enclose text strings (especially where contain cSeparator)
     * @throws SQLException if anything goes wrong.
     */
    public static void write(java.sql.ResultSet _resultSet, 
                             java.lang.String   _outputDirectory, 
                             java.lang.String   _fileName, 
                             java.lang.String   _cSeparator,
                             java.lang.String   _cDelimiter,
                             java.lang.String   _sDateFormat,
                             java.lang.String   _geomRenderFormat,
                             int                _decimalDigitsOfPrecision )
    throws  SQLException, 
            IllegalArgumentException,
            FileNotFoundException, 
            IOException {
        try {
            // Check input
            if ( _resultSet == null )  {
                throw new IllegalArgumentException("resultSet must exist.");
            }
            if (Strings.isEmpty(_outputDirectory) ) {
                // though this may not work inside Oracle if user calling procedure has not had granted write permissions
                throw new IllegalArgumentException("Output directory must be provided and Oracle user must have write permission.");
            }
            if (Strings.isEmpty(_fileName) ) {
                throw new IllegalArgumentException("Filename must be provided");
            }
            if ( String.valueOf(_cSeparator).length() > 0 ) {
                FIELD_SEPARATOR = _cSeparator.charAt(0);
            }
            if ( String.valueOf(_cDelimiter).length() > 0) {
                TEXT_DELIMITER = _cDelimiter.charAt(0);
            }
            if (Strings.isEmpty(_sDateFormat) ) {
                DATEFORMAT = _sDateFormat;
            }
            
            // Assign to local variables
            GEO_RENDERER_FORMAT geoRenderFormat = GEO_RENDERER_FORMAT.getRendererFormat(_geomRenderFormat);
            SimpleDateFormat sdf = new SimpleDateFormat(DATEFORMAT); 
            String    sSeparator = String.valueOf(FIELD_SEPARATOR);
            String    sDelimiter = String.valueOf(TEXT_DELIMITER);
            File     delimitedFile = new File(FileUtils.FileNameBuilder(_outputDirectory,
                                                                        _fileName,
                                                                        "csv"));
            Writer delimitedOutput = new BufferedWriter(new FileWriter(delimitedFile));

            OracleConnection            conn = (OracleConnection)_resultSet.getStatement().getConnection();
            DBConnection.setConnection((oracle.jdbc.driver.OracleConnection) conn); // Will find default if conn==null
            OracleResultSetMetaData metaData = (OracleResultSetMetaData)_resultSet.getMetaData();
            OracleResultSet     oraResultSet = (OracleResultSet)        _resultSet;
            oraResultSet.setFetchDirection(ResultSet.FETCH_FORWARD);
            OraRowSetMetaDataImpl       rsMD = new OraRowSetMetaDataImpl();

            // construct the delimited header header object from the result set metadata
            String header = getHeadings(metaData,sSeparator);
            
            //FileWriter always assumes default encoding is OK!
            delimitedOutput.write( header );

            // sort through resultset
            String outValue = "";
            int    fieldNum = -1;
            
            while (oraResultSet.next()) 
            {
                fieldNum = 0;
                for (int i = 1; i <= metaData.getColumnCount(); i++) 
                {
                    // skip geometry column and any undefined column types
                    if (SQLConversionTools.isSupportedType(metaData.getColumnType(i),
                                                           metaData.getColumnTypeName(i)))                    
                    {
                        fieldNum++;
                        outValue =
                            SQLConversionTools.toString((OracleConnection)           conn,
                                                        (OracleResultSet)    oraResultSet,
                                                        rsMD, 
                                                        /* columnIndex */               i,
                                                        /* _geomFormat */ geoRenderFormat,
                                                        /* _sDelimiter */      sDelimiter,
                                                        /* SimpleDateFormat*/         sdf);
                        if (oraResultSet.wasNull()) { 
                             outValue = "NULL";
                        }
                        //FileWriter always assumes default encoding is OK!
                        delimitedOutput.write( (fieldNum == 1 ) ? outValue : sSeparator + outValue );
                    } // if
               } // for
               delimitedOutput.write("\n");
            } // while
            delimitedOutput.close();
        }
        catch (SQLException sqle) {
            throw new SQLException("Error executing SQL: " + sqle);
        }
        catch (IOException ioe) {
            throw new IOException(ioe.getMessage());
        }
        catch (IllegalArgumentException iae) {
            throw new IllegalArgumentException(iae.getMessage());
        }
        catch (Exception e) {
            throw new RuntimeException("Error generating delimited file." + e.getMessage());
        }
    }
        
}
