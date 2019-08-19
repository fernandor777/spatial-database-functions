package com.spdba.dbutils.io.exp.geojson;

import com.spdba.dbutils.spatial.Renderer;
import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.sql.DBConnection;
import com.spdba.dbutils.sql.SQLConversionTools;
import com.spdba.dbutils.tools.FileUtils;
import com.spdba.dbutils.tools.Strings;
import com.spdba.dbutils.tools.Tools;

import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryCollection;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.PrecisionModel;
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

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleResultSetMetaData;
import oracle.jdbc.OracleTypes;

import oracle.sql.STRUCT;

public class WriteGeoJSONFile {

    private static String DATEFORMAT =  "yyyy/MM/dd hh:mm:ss a";

    /** JSON Writer Specific variables 
    */

    private static final    int     idColumnDoesNotExist = -1;
    private static       String             idColumnName = "";
    private static          int            idColumnIndex = idColumnDoesNotExist;
    private static final String      geomColumnFindFirst = "FIRST";
    private static final String     geomColumnNamePrefix = "NAME:";
    private static       String           geomColumnName = "";
    private static final String    geomColumnIndexPrefix = "INDEX:";
    private static          int          geomColumnIndex = Integer.MIN_VALUE;
    
    private static         List       geomCollectionList = null;
    private static         List        geomColumnIndices = null;
    private static         List        attrColumnIndices = null;
    
    public  static final String   geometryCollectionOption = "GEOMETRY_COLLECTION";
    private static final String             geometryOption = "GEOMETRY";
    private static       String      geoJsonGeometryOption = null;

    public  static final String            noFeatureOption = "NO_FEATURES";
    public  static final String    featureCollectionOption = "FEATURE_COLLECTION";
    public  static final String              featureOption = "FEATURE";
    private static       String       geoJsonFeatureOption = noFeatureOption;
    
    private static      boolean                       bbox = false;    
    private static SimpleDateFormat                    sdf = null; 

    private static       String                    newLine = System.getProperty("line.separator");
    private static          int                     commit = 100;
    private static          int                        row = 0;
    private static       String               jsonFileName = "";
    private static       String          jsonFileExtension = "geojson";
    private static       Writer             jsonFileWriter = null;
    private static StringBuffer             jsonFileBuffer = null;

    private static void setGeometryProcessingOptions(OracleResultSetMetaData _metadata,
                                                     boolean                 _aggregateMultipleGeomColumns) 
    throws SQLException 
    {
        // All processing of result set will be via indexes in following lists.
        geomColumnIndices = new ArrayList(); 
        attrColumnIndices = new ArrayList(); 
        
        // And confirm name of required colummn        
        for (int i = 1; i <= _metadata.getColumnCount(); i++)
        {
            if ( _metadata.getColumnType(i) == OracleTypes.STRUCT && 
                 (_metadata.getColumnTypeName(i).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY) ||
                 (_metadata.getColumnTypeName(i).indexOf("MDSYS.ST_")==0) ) ) 
            {
                // If Main Geometry Column is found by index, then record it.
                if ( geomColumnIndex != Integer.MIN_VALUE ) {
                    if ( geomColumnIndex == i ) {
                        geomColumnName = _metadata.getCatalogName(i);
                        // Save at start of all geometry column indices
                        geomColumnIndices.add(0,new Integer(geomColumnIndex));
                    } else {
                        // While this column is not of interest as main geometry column we still need it
                        geomColumnIndices.add(new Integer(i));
                    }
                } else /* geomColumnIndex == Integer.MIN_VALUE */ {
                    // We are required to find first geometry column by name
                    if ( geomColumnName.equalsIgnoreCase(geomColumnFindFirst) ) {
                        geomColumnIndex = i;
                        geomColumnName = _metadata.getCatalogName(i);
                        // Save at start of all geometry column indices
                        geomColumnIndices.add(0,new Integer(geomColumnIndex));
                    } else if ( _metadata.getCatalogName(i).equalsIgnoreCase(geomColumnName) ) {
                        geomColumnIndex = i;
                        // Save at start of all geometry column indices
                        geomColumnIndices.add(0,new Integer(geomColumnIndex));
                    } else {
                        // While this column is not of interest as main geometry column we still need it
                        geomColumnIndices.add(new Integer(i));
                    }
                }
            } 
            else /* Is not a geometry object by an attribute */
            {
                if (SQLConversionTools.isSupportedType(_metadata.getColumnType(i),
                                                       _metadata.getColumnTypeName(i)))
                {
                    if ( _metadata.getColumnLabel(i).equalsIgnoreCase(idColumnName) ) {
                        idColumnIndex = i;
                    }
                    attrColumnIndices.add(new Integer(i));
                }
            }
        }
        
        if ( geomColumnIndices.size() == 0 ) {
            throw new IllegalArgumentException("No geometry objects exist in provided query result set.");
        }
        
        // If we have no attributes, we don't have features
        //
        if ( attrColumnIndices.size() == 0 ) {
            setGeoJsonFeatureOption(noFeatureOption);                    // There are no features 
            if ( _aggregateMultipleGeomColumns ) {
                setGeoJsonGeometryOption(geometryCollectionOption);       // Single GeometryCollection for all columns 
            } else {
                setGeoJsonGeometryOption(geometryOption);                 // AssNo aggregation
            }
            
        } else if (attrColumnIndices.size() > 0) // If we have attributes we have features .. 
        {
            // Whether Feature/FeatureCollection depends on the number of geometry columns and user aggregation setting
            //
            if ( geomColumnIndices.size() == 1 ) {
                setGeoJsonFeatureOption(featureOption);              // Single geometry == single feature
                setGeoJsonGeometryOption(geometryOption);
            } else {
                setGeoJsonFeatureOption(featureCollectionOption);    // Multiple geometries == single feature collection
                // Whether to use aggreate all geometries in rowset to a single GeometryCollection depends on parameter
                setGeoJsonGeometryOption(_aggregateMultipleGeomColumns 
                                         ? geometryCollectionOption
                                         : geometryOption);
            }
        } 
        
    }

    /**
     * Main execution method.
     * <p>
     * Writes the given result as delimited text files 
     *  For GeoJSON, Polygon rings MUST follow the right-hand rule for orientation
     *  (counterclockwise external rings, clockwise internal rings).
     * @param _resultSet the result set, including a geometry column.
     * @param _outputDirectory the directory to write output files to.
     * @param _fileName the file name of output files.
     * @param _sDateFormat SimpleDateFormat string.
     * @param _commit Commit interval (default 100).
     * @throws SQLException if anything goes wrong.
     */
    public static void write(java.sql.ResultSet _resultSet, 
                             java.lang.String   _outputDirectory, 
                             java.lang.String   _fileName, 
                             java.lang.String   _geomColumn,
                             java.lang.String   _idColumn,
                             java.lang.String   _sDateFormat,
                             java.lang.String   _geomRenderFormat,
                             int                _aggregateMultipleGeometryColumns,
                             int                _bbox,
                             int                _decimalDigitsOfPrecision,
                             int                _commit) 
    throws  SQLException, 
            IllegalArgumentException,
            IOException 
    {
        if ( _resultSet == null )  {
            // though this may not work inside Oracle if user calling procedure has not had granted write permissions
            throw new IllegalArgumentException("resultSet must exist.");
        }
        
        OracleConnection            conn = (OracleConnection)_resultSet.getStatement().getConnection();
        DBConnection.setConnection((oracle.jdbc.driver.OracleConnection) conn); // Will find default if conn==null
        OracleResultSetMetaData metaData = (OracleResultSetMetaData)_resultSet.getMetaData();
        OracleResultSet     oraResultSet = (OracleResultSet)        _resultSet;
        oraResultSet.setFetchDirection(ResultSet.FETCH_FORWARD);

        // Check input
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
        
        // Process idColumn parameters...
        //
        idColumnIndex = idColumnDoesNotExist;
        if ( !Strings.isEmpty(_idColumn)) {
            idColumnName  = _idColumn.toUpperCase();
        }
        
        // Process geometry column Paramters:
        // null -> FIRST
        // NAME:<<Name>>
        // INDEX:<<index integer>>
        
        if (Strings.isEmpty(_geomColumn) ) {
            geomColumnName = geomColumnFindFirst; // Find First geometry column
        } else if ( _geomColumn.toUpperCase().startsWith(geomColumnNamePrefix) ) {
            // Extract main column name
            geomColumnName = _geomColumn.toUpperCase().replaceFirst(geomColumnNamePrefix,"");
        } else if ( _geomColumn.toUpperCase().startsWith(geomColumnIndexPrefix) ) {
            // Extract main column name
            geomColumnIndex =
                                     Strings.isEmpty(_geomColumn.toUpperCase().replaceFirst(geomColumnIndexPrefix,""))
                              ? -1 /* Find it **/
                              : Integer.valueOf(_geomColumn.toUpperCase().replaceFirst(geomColumnIndexPrefix,""),-1).intValue();
        } 
        
        Renderer.GEO_RENDERER_FORMAT geoRenderFormat = Renderer.GEO_RENDERER_FORMAT.getRendererFormat(_geomRenderFormat);

        // Now set options before processing data.
        //
        setGeometryProcessingOptions(metaData,
                                     /* aggregate */ ( _aggregateMultipleGeometryColumns > 0 ));
        
/**
System.out.print("Number of columns in result set = " + metaData.getColumnCount());
System.out.print("Indexes of Geometry Columns: ");
        Iterator geoIter = geomColumnIndices.iterator();
        int geoIndex = 1;
        while (geoIter.hasNext()) {
            geoIndex = ((Integer)geoIter.next()).intValue();
System.out.print(geoIndex + " ");
        }
System.out.println(" ");
System.out.print("Indexes of Geometry Columns: ");
                Iterator attIter = attrColumnIndices.iterator();
                int attIndex = 1;
                while (attIter.hasNext()) {
                    attIndex = ((Integer)attIter.next()).intValue();
System.out.print(attIndex + " ");
                }
System.out.println("");
**/
        bbox           = (_bbox == 0 ? false : true);
        commit         = (_commit==0 ?   100 : Math.abs(_commit));
        sdf            = new SimpleDateFormat(DATEFORMAT); 
        jsonFileName = FileUtils.FileNameBuilder(_outputDirectory,_fileName,jsonFileExtension); 
        jsonFileWriter = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(new File(jsonFileName)),"UTF-8"));
        
        // Turn provided number of decimal digits of precision to something JTS can use.
        double              precision = Tools.getPrecisionScale(_decimalDigitsOfPrecision);
        PrecisionModel precisionModel = new PrecisionModel(precision);
        GeoJSONWriter.setFormatter(precisionModel);
        GeometryFactory   geomFactory = new GeometryFactory(precisionModel);
        OraReader        oracleReader = new OraReader(geomFactory);
        
        // sort through resultset
        Object                    idValue = null;
        String                   outValue = "";
        STRUCT                  oraStruct = null;
        Geometry                 geometry = null;
        GeometryCollection geomCollection = null;
        Geometry          featureEnvelope = null;
        int                     geomIndex = 0;
        int                     attrIndex = 0;
        boolean             hasAttributes = !( attrColumnIndices.size()==1 && idColumnIndex != idColumnDoesNotExist);
        
        try {
            start(DBConnection.getCharacterSet(conn)); // "UTF-8");
            while (oraResultSet.next()) 
            {
                startRow();
                
                // Process geometry columns independently of attributes as may aggregate multiple columns
                //
                
                // Feature/FeatureCollections can have ID ...
                //
                if (getGeoJsonFeatureOption().toUpperCase().startsWith(featureOption) 
                    && 
                    idColumnIndex != idColumnDoesNotExist ) 
                {
                    idValue = oraResultSet.getObject(idColumnIndex).toString();
                }
System.out.println(getGeoJsonFeatureOption());
System.out.println("NumGeoms=" + geomColumnIndices.size());
System.out.println("ID (index,Value)=(" + idColumnIndex + "," + (idValue!=null?idValue.toString():"null") + ")");
                if ( geomColumnIndices.size()==1 ) 
                {
                    geomIndex = ((Integer)geomColumnIndices.get(0)).intValue();
                    oraStruct = (STRUCT)oraResultSet.getObject(geomIndex);
                    geometry = SDO.asJTSGeometry(oraStruct, 
                                                           oracleReader, 
                                                           geomFactory);
                    
                    // If Feature (can't be Collection as size==1) we need to wrap geometry in Feature tags.
                    // if not, standard GeoJSON geometry written completely by GeoJSONWriter.write function.
                    //
                    if (getGeoJsonFeatureOption().toUpperCase().startsWith(featureOption) ) 
                    {
                        featureEnvelope = bbox ? geometry.getEnvelope() : null;
                        GeoJSONWriter.appendFeatureBeginText(featureEnvelope,
                                                             idValue,
                                                             jsonFileBuffer);
                    } else {
                        GeoJSONWriter.setCURRENT(GeoJSONWriter.getCURRENT()+1);
                    }
                    
                    // Convert geometry to GeoJSON.
                    // Create BBOX for individual geometry only if not already created at feature level
                    //
                    GeoJSONWriter.write(/* JTS Geometry */                geometry,
                                        /* _featureType*/getGeoJsonFeatureOption(),
                                        /* _bbox       */                     bbox,
                                        /* _writer     */           jsonFileBuffer);
                    
                    /* Terminate Feature tags if Feature */
                    if (getGeoJsonFeatureOption().toUpperCase().startsWith(featureOption) ) {
                        GeoJSONWriter.appendFeatureEndText(hasAttributes,
                                                           jsonFileBuffer);
                    } else {
                        GeoJSONWriter.setCURRENT(GeoJSONWriter.getCURRENT()-1);
                    }
                    
                } else { // Multiple Geometry Columns 
                    
                    // Cache all geometries regardless as to bbox or collection processing options.
                    //
                    geomCollection     = null;
                    geomCollectionList = new ArrayList/*<Geometry>*/(geomColumnIndices.size());
                    Iterator/*<Integer>*/ geomIter = geomColumnIndices.iterator();
                    int collectionIndex = 0;
                    while (geomIter.hasNext()) {
                        int geomIndexIndex = ((Integer)geomIter.next()).intValue();
                        oraStruct = (STRUCT)oraResultSet.getObject(geomIndexIndex);
                        geometry = SDO.asJTSGeometry(oraStruct, 
                                                               oracleReader, 
                                                               geomFactory);
                        geomCollectionList.add(collectionIndex++, 
                                               geometry);
                    }

                    // If BBOX needed at feature/featureCollection level we need geomCollection
                    //
                    featureEnvelope = null;
                    if ( bbox 
                         ||
                         (getGeoJsonGeometryOption().equalsIgnoreCase(geometryCollectionOption) &&
                          getGeoJsonFeatureOption().equalsIgnoreCase(featureOption)
                         )
                       )
                    {
                        geomCollection = new GeometryCollection((Geometry[])geomCollectionList.toArray(new Geometry[] {}), 
                                                                geomFactory);
                        featureEnvelope = geomCollection.getEnvelope();
                    }
                    
                    // Now write cached geometries according to requirements
                    //    
                    if (getGeoJsonFeatureOption().toUpperCase().equalsIgnoreCase(featureOption) ) {
                        // Writing as Feature so all columns written as a single Geometrycollection
                        //
                        GeoJSONWriter.appendFeatureBeginText(bbox ? featureEnvelope : null,
                                                             idValue,
                                                             jsonFileBuffer);
                        GeoJSONWriter.write(/* JTS Geometry */                  geomCollection,
                                            /* _featureType*/        getGeoJsonFeatureOption(),
                                            /* _bbox       */bbox && (featureEnvelope == null),
                                            /* _writer     */                  jsonFileBuffer);
                        GeoJSONWriter.appendFeatureEndText(hasAttributes,
                                                           jsonFileBuffer);
                    } else { 
                        // Write Header
                        GeoJSONWriter.appendFeatureCollectionBeginText(bbox ? featureEnvelope : null,
                                                                       idValue,
                                                                       jsonFileBuffer);
                        
                        // Write Individual geometries within FeatureCollection wrapper
                        // 
                        Iterator/*<Geometry>*/ geomObjectsIter = geomCollectionList.iterator();
                        geomIndex = 0;
                        while (geomObjectsIter.hasNext()) {
                            geometry = (Geometry)geomObjectsIter.next();
                            GeoJSONWriter.write(/* JTS Geometry */                          geometry, 
                                                /* _featureType */         getGeoJsonFeatureOption(),
                                                /* _bbox        */ bbox && (featureEnvelope == null),
                                                /* _writer      */                    jsonFileBuffer);
                            if ( geomIndex == 0 ) {
                                jsonFileBuffer.append(",");
                            }
                            geomIndex++;
                        }
                        GeoJSONWriter.appendFeatureCollectionEndText(jsonFileBuffer);
                    }
                }

                // Write Properties if have attributes but not single ID in feature set
                //
                if ( getGeoJsonFeatureOption().toUpperCase().startsWith(featureOption) 
                     &&
                     hasAttributes )
                {
                    int first = 0;
                    Iterator/*<Integer>*/ attrIter = attrColumnIndices.iterator();
                    attrIndex = 0;
                    jsonFileBuffer.append(newLine);
                    GeoJSONWriter.setCURRENT(GeoJSONWriter.getCURRENT()+1);
                    GeoJSONWriter.indent(GeoJSONWriter.getCURRENT(),
                                         jsonFileBuffer,
                                         "\"properties\": { ",
                                         true);
                    GeoJSONWriter.setCURRENT(GeoJSONWriter.getCURRENT()+1);
                    while (attrIter.hasNext()) {
                        attrIndex = ((Integer)attrIter.next()).intValue();
                        if ( attrIndex == idColumnIndex ) {
                            continue;
                        }
                        outValue = SQLConversionTools.toString(conn,
                                                               oraResultSet,
                                                               null,//metaData,
                                                               attrIndex,
                                                               /* _geomFormat      */ geoRenderFormat,
                                                               /* _sDelimiter      */  "",
                                                               /* SimpleDateFormat */sdf);
                        if (oraResultSet.wasNull()) { 
                            outValue = "NULL";
                        }
                        printColumn(outValue, SQLConversionTools.isString(metaData.getColumnType(attrIndex)),
                                       first==0,
                                       metaData.getColumnLabel(attrIndex) );
                        first++;
                   } // while
                    GeoJSONWriter.setCURRENT(GeoJSONWriter.getCURRENT()-1);
                   jsonFileBuffer.append(newLine);
                    GeoJSONWriter.indent(GeoJSONWriter.getCURRENT(), jsonFileBuffer, "}", true);
                } // Has properties to write
                endRow();
            } // while
            end();
        }
        catch (SQLException sqle) {
            throw new SQLException("Error executing SQL: " + sqle);
        }
    }
    
    public static void start(String _encoding) 
    {
        row = 0;
        jsonFileBuffer = new StringBuffer(100000);
        GeoJSONWriter.startDocument(jsonFileBuffer);
   }

    public static void startRow() 
    throws IOException 
    {
        if ( row > 0) {
            jsonFileBuffer.append(","+newLine);
        }
    }

    public static void printColumn(String  _object,
                                   boolean _isString,
                                   boolean _firstAttribute,
                                   String  _columnName) 
    throws IOException 
    {
        /**
        *      "properties": {
        *        "prop0": "value0",
        *        "prop1": 0.0
        *      }
        */
        jsonFileBuffer.append( _firstAttribute ? "" : (","+ newLine) );
        GeoJSONWriter.indent(GeoJSONWriter.getCURRENT(),
                             jsonFileBuffer,
                             "\"" + _columnName + "\": " + 
                               (_isString?"\"":"")  + _object + (_isString?"\"":""),
                             false);
    }

    public static void endRow() throws IOException {
        row++;
        GeoJSONWriter.setCURRENT(GeoJSONWriter.getCURRENT()-1);
        GeoJSONWriter.indent(GeoJSONWriter.getCURRENT(), jsonFileBuffer, "}", false);
        if ( (row % getCommit()) == 0 ) {
            jsonFileWriter.write(jsonFileBuffer.toString());
            jsonFileBuffer = new StringBuffer(100000);
            jsonFileWriter.flush();
        }
    }

    public static void end() 
    throws IOException 
    {
        GeoJSONWriter.endDocument(jsonFileBuffer);
        if ( jsonFileBuffer.length() > 0 ) {
            jsonFileWriter.write(jsonFileBuffer.toString());
        }  
        jsonFileWriter.flush();
    }

    public static  void close() {
        try {
            jsonFileWriter.close();
            jsonFileWriter = null;
        } catch (IOException ioe) {
          // Do nothing.
        }
    }

    private static int getCommit() {
        return commit;
    }

    public static String getGeoJsonGeometryOption() {
        return geoJsonGeometryOption;
    }

    public static void setGeoJsonGeometryOption(String geoJsonGeometryOption) {
        WriteGeoJSONFile.geoJsonGeometryOption = geoJsonGeometryOption;
    }

    public static String getGeoJsonFeatureOption() {
        return geoJsonFeatureOption;
    }

    public static void setGeoJsonFeatureOption(String geoJsonFeatureOption) {
        WriteGeoJSONFile.geoJsonFeatureOption = geoJsonFeatureOption;
    }
}
