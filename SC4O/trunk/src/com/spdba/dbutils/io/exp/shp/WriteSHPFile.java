package com.spdba.dbutils.io.exp.shp;

import com.spdba.dbutils.io.IOConstants;
import com.spdba.dbutils.io.exp.ExportTask;
import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.sql.DBConnection;
import com.spdba.dbutils.tools.FileUtils;
import com.spdba.dbutils.tools.LOGGER;
import com.spdba.dbutils.tools.Strings;

import java.io.IOException;

import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Types;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleResultSetMetaData;
import oracle.jdbc.OracleTypes;

import org.geotools.data.shapefile.shp.ShapeType;

import org.xBaseJ.micro.DBFTypes;

/**
 * Shape file generator given a result set.  It also creates the required associated
 * .shx and .dbf files.
 * <p>
 * Expects a geometry object as one of the selected attributes, as optionally specified.
 * Only Oracle SDO_GEOMETRY is supported currently.  If no column is given as the gemoetry
 * object, then the writer will use the first STRUCT type encountered.  Other geometry types
 * are ignored.  All other values are added as metadata in the .dbf file.
 * <p>
 * The actual underlying generation is handled by the Geotools library.
 *
 * @author anita, Department of Primary Industries and Water, Tasmania, Original Coding
 * @author Simon Greener, The SpatialDB Advisor, Converted to run inside Oracle JVM
 *
 */
public class WriteSHPFile {

    private static int   geomColumnIndex = -1;
    private static String geomColumnName = "";
    
    private static void setGeometryColumnIndexAndName(OracleResultSetMetaData _metaData,
                                                      String                  _geomColumn) 
    {
        // Validate passed in name.
        // If not exist, find first geometry column
        //
        geomColumnIndex = Integer.MIN_VALUE;
        try {
            for (int i = 1; i <= _metaData.getColumnCount(); i++) {
                if (_metaData.getColumnType(i) == OracleTypes.STRUCT &&
                    (_metaData.getColumnTypeName(i).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY) ||
                     _metaData.getColumnTypeName(i).indexOf("MDSYS.ST_") == 0)) {
                    String colName =
                        Strings.isEmpty(_metaData.getCatalogName(i)) ? _metaData.getColumnLabel(i) :
                        _metaData.getCatalogName(i);
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

    /**
     * Ensures we have a geometry column for the extract. If the specified geometry column index is not
     * valid, then the first STRUCT type encounted in the result set is assumed to be the geometry column.
     * @param _resultSet the result set to validate.
     * @param _geoColumnIndex the user specified geometry column index.
     * @throws SQLException if there is an error reading the result set metadata.
     */
    protected static void validateResultSet(ResultSet   _resultSet, 
                                            int _geoColumnIndex) 
    throws SQLException 
    {
        if (_resultSet == null)
          throw new IllegalArgumentException("Must specify result set for generating the output.");

        // ensure it is a geometry type if index has been specified
        ResultSetMetaData metaData = _resultSet.getMetaData();
        if (_geoColumnIndex > 0) {
                int type = metaData.getColumnType(_geoColumnIndex);
                if (type != Types.STRUCT) {
                        throw new IllegalArgumentException("Specified geometry column index "+
                                                           _geoColumnIndex+
                                                           " is not a STRUCT type: "+
                                                           metaData.getColumnTypeName(_geoColumnIndex));
                }
                // column type at index is acceptable
                geomColumnIndex = _geoColumnIndex;
                geomColumnName  = metaData.getColumnLabel(_geoColumnIndex);
                return;
        }
        // index hasn't been specified, so default to the first geometry type encountered
        for (int i = 1; i <= metaData.getColumnCount(); i++) {
                if ((Types.STRUCT == metaData.getColumnType(i)) &&
                    metaData.getColumnTypeName(i).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY) ) {
                        geomColumnIndex = i;
                        return;
                }
        }
        // haven't found an acceptable type
        throw new IllegalArgumentException("Given result set appears not to have an SDO_GEOMETRY column");
    }

    /**
     * Main execution method.
     * <p>
     * Writes the given result as shape files with PRJ 
     *  
     * @param _resultSet the result set, including a geometry column.
     * @param _outputDirectory the directory to write output files to.
     * @param _fileName the file name of output files.
     * @param _shapeType the type of shapefile eg polygon etc.
     * @param _polygonOrientation Orientation of polygon shells and holes.
     * @param _commit Commit interval
     * @param _decimalDigitsOfPrecision round ordinates to decimal places eg 3 = mm
     * @param _geometryIndex the column index of the geometry column.
     * @param _prjString - An ESRI PRJ file's contents. 
     * @throws SQLException or IOException or IllegalArgumentException if anything goes wrong.
     */
    public static void write(java.sql.ResultSet _resultSet, 
                             java.lang.String   _outputDirectory, 
                             java.lang.String   _fileName, 
                             java.lang.String   _shapeType,
                             java.lang.String   _geomColumnName,
                             java.lang.String   _polygonOrientation,
                             java.lang.String   _dbaseType,
                             java.lang.String   _geomRenderFormat,
                             java.lang.String   _prjString,
                             int                _decimalDigitsOfPrecision,
                             int                _commit )
    throws  SQLException, 
            IOException, 
            IllegalArgumentException 
    {  
        // Check input
        if (Strings.isEmpty(_outputDirectory) ) {
            // though this may not work inside Oracle if user calling procedure has not had granted write permissions
            throw new IllegalArgumentException("Output directory must be provided and Oracle user must have write permission.");
        }
        
        if (Strings.isEmpty(_fileName) ) {
            throw new IllegalArgumentException("Filename must be provided");
        }
        
        if (Strings.isEmpty(_shapeType) ) {
            throw new IllegalArgumentException("shapeType must be provided");
        }
        ShapeType sType = IOConstants.SHAPE_TYPE.validateShapeType(_shapeType);
        if ( sType == ShapeType.UNDEFINED) {
            throw new IllegalArgumentException("Unknown shapeType (" + _shapeType + ") provided.");
        }

        DBConnection.setConnection((OracleConnection)_resultSet.getStatement().getConnection());
        OracleResultSet oResultSet = (OracleResultSet)_resultSet;
        setGeometryColumnIndexAndName((OracleResultSetMetaData) _resultSet.getMetaData(),
                                      _geomColumnName);

        SHPExporter geoExporter;
        String fullFileName = FileUtils.FileNameBuilder(_outputDirectory,_fileName,"shp");
        geoExporter = new SHPExporter(
                             DBConnection.getConnection(),
                             fullFileName,
                             _resultSet.getStatement().getMaxRows(),
                             SDO.getPolygonRingOrientation(),
                             _decimalDigitsOfPrecision
                      );
        //geoExporter.setConnection(DBConnection.getConnection());
        geoExporter.setBaseName(FileUtils.getFileNameFromPath(_fileName,true));
        geoExporter.setResultSet(oResultSet);
        geoExporter.setPrecisionScale(_decimalDigitsOfPrecision);
        geoExporter.setPrjContents(_prjString);
        geoExporter.setGeometryFormat(_geomRenderFormat);
        geoExporter.setGeoColumnIndex(geomColumnIndex);
        geoExporter.setGeoColumnName(geomColumnName);
        geoExporter.setShapefileType(sType);
        if (_decimalDigitsOfPrecision >= 0) {
            geoExporter.setPrecisionScale(_decimalDigitsOfPrecision );
        }
        SDO.setPolygonRingOrientation(SDO.POLYGON_RING_ORIENTATION.fromString(_polygonOrientation.toUpperCase()));
        geoExporter.setPolygonOrientation(SDO.getPolygonRingOrientation());
        geoExporter.setXBaseType(DBFTypes.getDBFType(_dbaseType));
        geoExporter.setCommit(_commit <= 0 ? 100 : _commit);
        geoExporter.setRecordIdentifier(geoExporter.hasAttributes() ? null : "FID");
        // Now process the resultset and create SHP file...
        try {
            ExportTask et = new ExportTask(geoExporter);
            et.Export();
        } catch (Exception e) {
            e.printStackTrace();
            LOGGER.info("WriteSHPFile: Error Writing Shapefile (" + e.getLocalizedMessage() + ")");
        }
    }    

}
