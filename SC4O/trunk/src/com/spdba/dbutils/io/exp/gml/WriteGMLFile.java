package com.spdba.dbutils.io.exp.gml;

import com.spdba.dbutils.Constants;
import com.spdba.dbutils.Constants.XMLAttributeFlavour;
import com.spdba.dbutils.io.exp.ExportTask;
import com.spdba.dbutils.spatial.Envelope;
import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.sql.DBConnection;
import com.spdba.dbutils.sql.SQLConversionTools;
import com.spdba.dbutils.tools.FileUtils;
import com.spdba.dbutils.tools.LOGGER;
import com.spdba.dbutils.tools.Strings;

import java.io.IOException;

import java.sql.Connection;
import java.sql.SQLException;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleResultSetMetaData;
import oracle.jdbc.OracleTypes;

public class WriteGMLFile {

    protected static int       precisionModelScale = 3;
    private static int             geomColumnIndex = -1;
    private static String           geomColumnName = "";
    private static Constants.XMLAttributeFlavour XMLFlavour = Constants.XMLAttributeFlavour.OGR;

    /**
     * Main execution method.
     * <p>
     * Writes the given result as GML file
     * public method
     *
     * @param _resultSet
     * @param _outputDirectory
     * @param _fileName
     * @param _geomColumnName
     * @param _polygonOrientation
     * @param _GMLVersion
     * @param _geomRenderFormat
     * @param _decimalDigitsOfPrecision
     * @param _commit
     * 
     * @throws SQLException if anything goes wrong.
     * @throws IOException
     * @throws IllegalArgumentException
     * @param resultSet the result set, including a geometry column.
     * @param outputDirectory the directory to write output files to.
     * @param fileName the file name of output files.
     * @param shapeType the type of shapefile eg polygon etc.
     * @param geometryIndex the column index of the geometry column.
     */
    public static void write(java.sql.ResultSet _resultSet, 
                             java.lang.String   _outputDirectory, 
                             java.lang.String   _fileName, 
                             java.lang.String   _geomColumnName,
                             java.lang.String   _polygonOrientation,
                             java.lang.String   _GMLVersion,
                             java.lang.String   _attributeFlavour,
                             java.lang.String   _attributeGroupName,                             
                             java.lang.String   _geomRenderFormat,
                             int                _decimalDigitsOfPrecision,
                             int                _commit )
    throws  SQLException, 
            IOException, 
            IllegalArgumentException 
    {  
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

        DBConnection.setConnection((OracleConnection)_resultSet.getStatement().getConnection());        
        OracleResultSet oResultSet = (OracleResultSet)_resultSet;
        
        setGeometryColumnIndexAndName((OracleResultSetMetaData) _resultSet.getMetaData(),
                                      _geomColumnName);

        GMLExporter geoExporter;
        String fullFileName = FileUtils.FileNameBuilder(_outputDirectory,_fileName,"gml");
        Connection conn = DBConnection.getConnection();
        geoExporter = new GMLExporter(conn,
                                      fullFileName,
                                      _resultSet.getStatement().getMaxRows(),
                                      SDO.getPolygonRingOrientation(),
                                      _decimalDigitsOfPrecision);
        //geoExporter.setConnection(DBConnection.getConnection());
        geoExporter.setBaseName(Strings.isEmpty(_attributeGroupName)?FileUtils.getFileNameFromPath(_fileName,true) : _attributeGroupName);
        
        geoExporter.setResultSet(oResultSet);
        geoExporter.setGeoColumnIndex(geomColumnIndex);
        geoExporter.setGeoColumnName(geomColumnName);
        geoExporter.setGeometryFormat(_geomRenderFormat);
        geoExporter.setXMLFlavour(_attributeFlavour);
        SDO.setPolygonRingOrientation(_polygonOrientation.toUpperCase());
        geoExporter.setPolygonOrientation(SDO.getPolygonRingOrientation());
        if (_decimalDigitsOfPrecision >= 0) {
            geoExporter.setPrecisionScale(_decimalDigitsOfPrecision );
        }
        geoExporter.setGMLVersion(_GMLVersion);
        geoExporter.setCommit(_commit <= 0 ? 100 : _commit);
        boolean hasAttributes = SQLConversionTools.hasAttributeColumns(oResultSet,geomColumnIndex);
        geoExporter.setGenerateIdentifier(! hasAttributes );
        // Now process the resultset and create gml file...
        try {
            ExportTask et = new ExportTask(geoExporter);
            et.Export();
            Envelope resultExtent = geoExporter.getExtent();
        } catch (Exception e) {
            e.printStackTrace();
            LOGGER.info("WriteGMLFile: Error Writing GML file(" + e.getLocalizedMessage() + ")");
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
