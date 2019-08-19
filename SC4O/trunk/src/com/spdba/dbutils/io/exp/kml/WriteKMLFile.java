package com.spdba.dbutils.io.exp.kml;

import com.spdba.dbutils.Constants;
import com.spdba.dbutils.io.exp.ExportTask;
import com.spdba.dbutils.io.exp.gml.GMLExporter;
import com.spdba.dbutils.spatial.Envelope;
import com.spdba.dbutils.spatial.Renderer;
import com.spdba.dbutils.spatial.Renderer.GEO_RENDERER_FORMAT;
import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.sql.DBConnection;
import com.spdba.dbutils.sql.OraRowSetMetaDataImpl;
import com.spdba.dbutils.sql.SQLConversionTools;
import com.spdba.dbutils.tools.FileUtils;
import com.spdba.dbutils.tools.LOGGER;
import com.spdba.dbutils.tools.Strings;
import com.spdba.dbutils.tools.Tools;

import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.io.WKTWriter;
import org.locationtech.jts.io.kml.KMLWriter;
import org.locationtech.jts.io.ora.OraReader;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.Writer;

import java.sql.ResultSet;
import java.sql.SQLException;

import java.text.SimpleDateFormat;

import java.util.Hashtable;
import java.util.LinkedHashMap;
import java.util.logging.Logger;

import javax.sql.RowSetMetaData;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleResultSetMetaData;
import oracle.jdbc.OracleTypes;

import oracle.sql.STRUCT;

import org.geotools.util.logging.Logging;

public class WriteKMLFile 
{

    private static final Logger LOGGER = Logging.getLogger("com.spdba.io.export.WriteKMLFile");

    private static String DATEFORMAT =  "yyyy/MM/dd hh:mm:ss a";

    /** KML Writer Specific variables 
    */
    private static Hashtable     PlaceMarkAttributes = new Hashtable();

    private final static String         KmlNameSpace = "\"http://www.opengis.net/kml/2.2\"";
    private final static String            placeMark = "<Placemark id=\"PMID%d\">";
    private static String                    newLine = System.getProperty("line.separator");
    private static String            defaultSyleName = "SPDBADefaultSyles";
    private static int                styleUrlColumn = Integer.MIN_VALUE;
    private static int               geomColumnIndex = Integer.MIN_VALUE;
    private static String             geomColumnName = null;
    private static String               extendedData = "";
    private static String               geometryData = "";
    private static int                           row = 0;
    private static String                kmlFilename = "";
    private static SimpleDateFormat              sdf = null; 
    private static Writer                    kmlFile = null;
    private static StringBuffer            rowBuffer = null;
    private static int                        commit = 100;
    protected static int         precisionModelScale = 3;

    public static void setPrecisionScale ( int scale ) {
        precisionModelScale = scale;
    }    
 
    /**
     * Main execution method.
     * <p>
     * Writes the given result as delimited text files
     *
     * @param _resultSet the result set, including a geometry column.
     * @param _outputDirectory the directory to write output files to.
     * @param _fileName the file name of output files.
     * @param _geomColumnName
     * @param _sDateFormat SimpleDateFormat string.
     * @param _geomRenderFormat
     * @param _decimalDigitsOfPrecision
     * @param _commit Commit interval (default 100).
     * @throws SQLException if anything goes wrong.
     * @throws IllegalArgumentException
     * @throws IOException
     */
    public static void write(java.sql.ResultSet _resultSet, 
                             java.lang.String   _outputDirectory, 
                             java.lang.String   _fileName, 
                             java.lang.String   _geomColumnName,
                             java.lang.String   _sDateFormat,
                             java.lang.String   _geomRenderFormat,
                             int                _decimalDigitsOfPrecision,
                             int                _commit)
    throws  SQLException, 
            IllegalArgumentException,
            IOException 
    {
/* Add
_KMLVersion
_attributeFlavour,
_polygonOrientation.toUpperCase()
*/
        // Check input
        if ( _resultSet == null )  {
            throw new IllegalArgumentException("ResultSet must exist.");
        }
        if (Strings.isEmpty(_outputDirectory) ) {
            // though this may not work inside Oracle if user calling procedure has not had granted write permissions
            throw new IllegalArgumentException("Output directory must be provided and Oracle user must have write permission.");
        }
        if (Strings.isEmpty(_fileName) ) {
            throw new IllegalArgumentException("Filename must be provided");
        }
        if ( !Strings.isEmpty(_sDateFormat) ) {
            DATEFORMAT = _sDateFormat;
        }
        
        commit = (_commit<=0) ? 100 : _commit;
        
        sdf = new SimpleDateFormat(DATEFORMAT);
        
        kmlFilename = FileUtils.FileNameBuilder(_outputDirectory,
                                                _fileName,
                                                "kml");
        kmlFile = new BufferedWriter(
                      new OutputStreamWriter(
                          new FileOutputStream(
                              new File(kmlFilename)
                          ),
                       "UTF-8") // GetDBCharSet
                  );
        double precision    = Tools.getPrecisionScale(_decimalDigitsOfPrecision);        
        String fullFileName = FileUtils.FileNameBuilder(_outputDirectory,_fileName,"kml");

        DBConnection.setConnection((OracleConnection)_resultSet.getStatement().getConnection());        
        OracleResultSet oResultSet = (OracleResultSet)_resultSet;
        setGeometryColumnIndexAndName((OracleResultSetMetaData) _resultSet.getMetaData(),
                                      _geomColumnName);
        
        KMLExporter kmlExporter;
        kmlExporter = new KMLExporter(
                             DBConnection.getConnection(),
                             fullFileName,
                             _resultSet.getStatement().getMaxRows(),
                             SDO.getPolygonRingOrientation(),
                             _decimalDigitsOfPrecision
                      );
String _attributeGroupName = null;
        kmlExporter.setBaseName(Strings.isEmpty(_attributeGroupName)?FileUtils.getFileNameFromPath(_fileName,true) : _attributeGroupName);
        kmlExporter.setResultSet(oResultSet);
        kmlExporter.setGeoColumnIndex(geomColumnIndex);
        kmlExporter.setGeoColumnName(geomColumnName);
        kmlExporter.setGeometryFormat(_geomRenderFormat);
        kmlExporter.setXMLFlavour("KML");  //_attributeFlavour);
        SDO.setPolygonRingOrientation("INVERSE"); // _polygonOrientation.toUpperCase());
        kmlExporter.setPolygonOrientation(SDO.getPolygonRingOrientation());
        if (_decimalDigitsOfPrecision >= 0) {
            kmlExporter.setPrecisionScale(_decimalDigitsOfPrecision );
        }
        kmlExporter.setKMLVersion("KML2"); // _KMLVersion);
        kmlExporter.setCommit(_commit <= 0 ? 100 : _commit);
        boolean hasAttributes = SQLConversionTools.hasAttributeColumns(oResultSet,geomColumnIndex);
        kmlExporter.setGenerateIdentifier(! hasAttributes );
        // Now process the resultset and create gml file...
        try {
            ExportTask et = new ExportTask(kmlExporter);
            et.Export();
            Envelope resultExtent = kmlExporter.getExtent();
        } catch (Exception e) {
            e.printStackTrace();
            LOGGER.info("WriteKMLFile: Error Writing KML file(" + e.getLocalizedMessage() + ")");
        }        
    }

    private static void setGeometryColumnIndexAndName(OracleResultSetMetaData _metaData,
                                                      String                  _geomColumn) 
    {
        // Validate passed in name.
        // If not exist, find first geometry column
        //
        geomColumnIndex = Integer.MIN_VALUE;
        try {
            String colName;
            colName = "";
            for (int i = 1; i <= _metaData.getColumnCount(); i++) {
                if (_metaData.getColumnType(i) == OracleTypes.STRUCT &&
                   (_metaData.getColumnTypeName(i).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY) ||
                    _metaData.getColumnTypeName(i).indexOf("MDSYS.ST_") == 0)) 
                {
                    colName = Strings.isEmpty(_metaData.getCatalogName(i)) 
                              ? _metaData.getColumnLabel(i)
                              : _metaData.getCatalogName(i);
                    if (Strings.isEmpty(_geomColumn)) {
                        geomColumnIndex = i;
                        geomColumnName = _metaData.getCatalogName(i);
                        break;
                    } else if (_geomColumn.equalsIgnoreCase(colName)) {
                        geomColumnIndex = i;
                        geomColumnName = colName;
                        break;
                    }
                }
            }
        } catch (SQLException e) {
            throw new IllegalArgumentException("Exception Analysing ResultSet for an SDO_GEOMETRY object.");
        }
        if ( geomColumnIndex == Integer.MIN_VALUE ) {
            throw new IllegalArgumentException("ResultSet must contain an SDO_GEOMETRY object.");
        }
    }
    
}
