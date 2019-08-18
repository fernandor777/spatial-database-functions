package com.spdba.dbutils.io.exp.kml;

import com.spdba.dbutils.Constants;
import com.spdba.dbutils.io.GeometryProperties;
import com.spdba.dbutils.io.IOConstants;
import com.spdba.dbutils.io.IOConstants.EXPORT_TYPE;
import com.spdba.dbutils.io.exp.IExporter;
import com.spdba.dbutils.spatial.Envelope;
import com.spdba.dbutils.spatial.Renderer;
import com.spdba.dbutils.spatial.Renderer.GEO_RENDERER_FORMAT;
import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.spatial.SDO.POLYGON_RING_ORIENTATION;
import com.spdba.dbutils.sql.OraRowSetMetaDataImpl;

import com.spdba.dbutils.sql.SQLConversionTools;

import org.geotools.data.shapefile.shp.ShapeType;

import org.locationtech.jts.io.kml.KMLWriter;

import com.spdba.dbutils.tools.FileUtils;
import com.spdba.dbutils.tools.LOGGER;
import com.spdba.dbutils.tools.Strings;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.text.SimpleDateFormat;

import java.util.Hashtable;
import java.util.LinkedHashMap;

import javax.sql.RowSetMetaData;

import oracle.spatial.util.GML3;

import oracle.sql.STRUCT;

import org.locationtech.jts.io.WKTWriter;


public class KMLExporter 
implements IExporter 
{

    private static final LOGGER LOGGER = new LOGGER("com.spdba.dbutils.io.export.kml.KMLExporter");
    
    private Connection            conn = null;
    private ResultSet        resultSet = null;

    private static String DATEFORMAT =  "yyyy/MM/dd hh:mm:ss a";
    private static Hashtable     PlaceMarkAttributes = new Hashtable();
    private final static String         KmlNameSpace = "\"http://www.opengis.net/kml/2.2\"";
    private final static String            placeMark = "<Placemark id=\"PMID%d\">";
    private static String                    newLine = System.getProperty("line.separator");
    private static String            defaultSyleName = "SPDBADefaultSyles";
    private static int                styleUrlColumn = Integer.MIN_VALUE;
    private int                       geoColumnIndex = -1;
    private String                     geoColumnName = "";
    private static String               extendedData = "";
    private static String               geometryData = "";
    private static int                           row = 0;
    private int                            totalRows = 0;    
    private boolean                  needsIdentifier = false;

    private static SimpleDateFormat              sdf = null; 
    // Main KML Writer
    private KMLWriter                      kmlWriter = null;
    private static String                kmlFilename = "";
    private static BufferedWriter            kmlFile = null;
    private static StringBuffer            rowBuffer = null;
    private static int                        commit = 100;
 
    protected static int         precisionModelScale = 3;
    private POLYGON_RING_ORIENTATION polyOrientation = POLYGON_RING_ORIENTATION.ORACLE;
    private int             decimalDigitsOfPrecision = 3;
    private WKTWriter                      wktWriter = null;
    private GEO_RENDERER_FORMAT      geoRenderFormat = GEO_RENDERER_FORMAT.WKT;
    private GEO_RENDERER_FORMAT           kmlVersion = GEO_RENDERER_FORMAT.KML2;
    private Constants.XMLAttributeFlavour XMLFlavour = Constants.XMLAttributeFlavour.OGR;

    // Writer for handling other sdo_geometry objects than the required object
    public KMLExporter (Connection               _conn,
                        String                   _fileName,
                        int                      _rowsToProcess,
                        POLYGON_RING_ORIENTATION _polygonOrientation,
                        int                      _decimalDigitsOfPrecision) 
    {
        super();
        conn = _conn;
        totalRows = _rowsToProcess;
        setFileName(_fileName);
        polyOrientation = (_polygonOrientation==null) ? POLYGON_RING_ORIENTATION.INVERSE : _polygonOrientation;
        SDO.setPolygonRingOrientation(polyOrientation);
        decimalDigitsOfPrecision = _decimalDigitsOfPrecision;
        GML3.setConnection(this.conn);
        // Main KML Writer
        kmlWriter = new KMLWriter();
        kmlWriter.setAltitudeMode(KMLWriter.ALTITUDE_MODE_CLAMPTOGROUND);
        kmlWriter.setPrecision(_decimalDigitsOfPrecision);
        kmlWriter.setMaximumCoordinatesPerLine(10);
        kmlWriter.setLinePrefix("      "); // 6 chars
        wktWriter = new WKTWriter(); 
        wktWriter.setMaxCoordinatesPerLine(10);
        wktWriter.setFormatted(true);
    }

    @Override
    public void setConnection(Connection _conn) {
        this.conn = _conn;
    }

    @Override
    public Connection getConnection() {
        return this.conn;
    }

    @Override
    public void setResultSet(ResultSet _rSet) {
        this.resultSet = _rSet;
    }

    @Override
    public ResultSet getResultSet() {
        return this.resultSet;
    }

    @Override
    public IOConstants.EXPORT_TYPE getExportType() {
        return EXPORT_TYPE.KML;
    }

    @Override
    public String getFileName() {
        return this.kmlFilename;
    }

    @Override
    public void setFileName(String _fileName) {
        this.kmlFilename = _fileName;
    }

    @Override
    public String getBaseName() {
        return FileUtils.getFileNameFromPath(this.kmlFilename,true);
    }

    @Override
    public String getFileExtension() {
        return "kml";
    }

    @Override
    public void setPolygonOrientation(SDO.POLYGON_RING_ORIENTATION _polyOrientation) {
        this.polyOrientation = _polyOrientation;
    }

    @Override
    public SDO.POLYGON_RING_ORIENTATION getPolygonOrientation() {
        return this.polyOrientation;
    }

    @Override
    public void setXMLFlavour(String _flavour) {
        if (Strings.isEmpty(_flavour) ) {
            this.XMLFlavour = Constants.XMLAttributeFlavour.OGR;
        }
        try {
            this.XMLFlavour = Constants.XMLAttributeFlavour.valueOf(_flavour); 
        } catch (Exception e) {
            this.XMLFlavour = Constants.XMLAttributeFlavour.OGR;
        }
    }

    @Override
    public void setXMLFlavour(Constants.XMLAttributeFlavour _flavour) {
        if ( _flavour == null ) {
            this.XMLFlavour = Constants.XMLAttributeFlavour.OGR;
        } else {
            this.XMLFlavour = _flavour;
        }
    }

    @Override
    public Constants.XMLAttributeFlavour getXMLFlavour() {
        return this.XMLFlavour;
    }

    @Override
    public void setGeometryFormat(String _renderFormat) {
        if (Strings.isEmpty(_renderFormat) ) {
            this.geoRenderFormat = Renderer.GEO_RENDERER_FORMAT.WKT;
        }
        try {
            this.geoRenderFormat = Renderer.GEO_RENDERER_FORMAT.WKT.valueOf(_renderFormat); 
        } catch (Exception e) {
            this.geoRenderFormat = Renderer.GEO_RENDERER_FORMAT.WKT;
        }
    }

    @Override
    public GEO_RENDERER_FORMAT getGeometryFormat() {
        return this.geoRenderFormat;
    }

    public void setKMLVersion(String _GMLVersion) {
        this.kmlVersion = GEO_RENDERER_FORMAT.getRendererFormat(_GMLVersion);
        if ( kmlVersion.toString().startsWith("KML") ) {
          this.kmlVersion = GEO_RENDERER_FORMAT.KML2;
        }
    }

    public GEO_RENDERER_FORMAT getGMLVersion() {
        return this.kmlVersion;
    }

    @Override
    public boolean hasAttributes() {
        // TODO Implement this method
        return false;
    }

    @Override
    public void setTotalRows(int _totalRows) {
        this.totalRows = _totalRows;
    }

    @Override
    public int getTotalRows() {
        return this.totalRows;
    }

    @Override
    public int getRowCount() {
        return this.row;
    }

    @Override
    public String getFieldSeparator() {
        return null;
    }

    @Override
    public String getTextDelimiter() {
        return null;
    }

    @Override
    public void setCommit(int _commit) {
        KMLExporter.commit = _commit;
    }

    @Override
    public int getCommit() {
        return KMLExporter.commit;

    }

    @Override
    public void setPrecisionScale(int _precisionScale) {
        // TODO Implement this method
    }

    @Override
    public int getPrecisionScale() {
        // TODO Implement this method
        return 0;
    }

    @Override    
    public void setGeoColumnIndex(int _geoColumnIndex) {
        this.geoColumnIndex = _geoColumnIndex;
    }

    @Override    
    public void setGeoColumnName(String _geoColumnName) {
        this.geoColumnName = _geoColumnName;
    }


    @Override
    public String getGeoColumnName() {
        return this.geoColumnName;
    }

    @Override
    public boolean isSupportedType(int columnType, String columnTypeName) {
        return SQLConversionTools.isSupportedType(columnType,columnTypeName);
    }

    @Override
    public boolean generateIdentifier() {
        // TODO Implement this method
        return false;
    }

    @Override
    public void setRecordIdentifier(String _recordIdentifier) {
        // TODO Implement this method
    }

    @Override
    public String getRecordIdentifier() {
        // TODO Implement this method
        return null;
    }

    @Override
    public Envelope getExtent() {
        // TODO Implement this method
        return null;
    }

    @Override
    public void setExtent(Envelope _extent) {
        // TODO Implement this method
    }

    @Override
    public void updateExtent(Envelope _e) {
        // TODO Implement this method
    }

    @Override
    public boolean skipNullGeometry() {
        // TODO Implement this method
        return false;
    }

    @Override
    public void setSkipNullGeometry(boolean _skip) {
        // TODO Implement this method
    }

    @Override
    public GeometryProperties getGeometryProperties() {
        // TODO Implement this method
        return null;
    }

    @Override
    public void setGeometryProperties(GeometryProperties _geometryProperties) {
        // TODO Implement this method
    }

    @Override
    public LinkedHashMap<Integer, RowSetMetaData> getExportMetadata() {
        // TODO Implement this method
        return null;
    }

    @Override
    public void setExportMetadata(LinkedHashMap<Integer, RowSetMetaData> _exportMetadata) {
        // TODO Implement this method
    }

    public void setGenerateIdentifier(Boolean _hasAttributes ) {
        this.needsIdentifier = _hasAttributes;                                         
    }

    @Override
    public void start(String _encoding) throws Exception 
    {
        this.kmlFile    = new BufferedWriter(new FileWriter(this.kmlFilename));
        this.row        = 0;
        this.rowBuffer  = new StringBuffer(100000);
        String baseName = Strings.isEmpty(kmlFilename)
                          ? ""
                          : "    <name>" + kmlFilename + "</name>" + newLine;            
        this.rowBuffer.append("<?xml version='1.0'  encoding='" + _encoding + "' ?>" + newLine +
                             "<kml xmlns= " + KmlNameSpace + ">" + newLine +
                             "  <Document>" + newLine +
                             baseName );
            
        // Default Styling depending on geometryType
        String defaultStyles = 
                "    <Style id=\"" + defaultSyleName + "\">" + newLine +
                "      <IconStyle>" + newLine + 
                "        <color>a1ff00ff</color>" + newLine + 
                "        <scale>1.0</scale>" + newLine + 
                "        <Icon>" + newLine + 
                "          <href>http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png</href>" + newLine + 
                "        </Icon>" + newLine + 
                "      </IconStyle>" + newLine + 
                "      <LabelStyle>" + newLine + 
                "        <color>7fffaaff</color>" + newLine + 
                "        <scale>1.0</scale>" + newLine + 
                "      </LabelStyle>" + newLine +
                "      <LineStyle>" + newLine + 
                "        <color>ffffffff</color>" + newLine + 
                "        <colorMode>random</colorMode>" + newLine + 
                "        <width>2</width>" + newLine + 
                "      </LineStyle>" + newLine +
                "      <PolyStyle>" + newLine + 
                "        <color>ffffffff</color>" + newLine + 
                "        <colorMode>random</colorMode>" + newLine + 
                "      </PolyStyle>" + newLine + 
                "    </Style>" + newLine;
            
        rowBuffer.append(defaultStyles);    
    }

    @Override
    public void startRow() throws IOException {
        PlaceMarkAttributes.clear();
        geometryData = "";
        extendedData = "";
    }

    @Override    
    public void printColumn(Object                _object, 
                            OraRowSetMetaDataImpl _columnMetaData) 
    {
        String kmlText = "";
        STRUCT stValue = null; 
        try {
            
            boolean isGeometryColumn = ! Strings.isEmpty(_columnMetaData.getCatalogName(1));
            // Mappable column?
            // System.out.println("CatalogName: ****"+_columnMetaData.getCatalogName(1)+"*** Type: " + _columnMetaData.getColumnTypeName(1) + " => isGeometryColumn=" + String.valueOf(isGeometryColumn) );
            if ( isGeometryColumn )   // Catalog name holds name of actual geometry column 
            {
                if ( _columnMetaData.getColumnTypeName(1).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY) ) 
                {
                    kmlText = "";
                    stValue = (STRUCT)_object; 
                    if ( stValue == null ) {
                        LOGGER.warn("NULL Geometry: No featureMember element written for row " + (row+1));
                       return;
                    }                    
                } 
            } else { // Process Attribute column
                // Passed in _object is already a string
                //
                try {
                    printColumn ( _object.toString(),
                                  _columnMetaData.getColumnName(1),
                                  _columnMetaData.getColumnTypeName(1)
                                  );
                } catch (Exception e) {
                    LOGGER.warn("Conversion of " + _columnMetaData.getColumnName(1) + "/" + " failed at row " + (this.row+1) + " - " + e.getMessage());
                }
            }
        } catch (Exception e) {
            LOGGER.warn("GMLExporter.printColumn(object,ResultSetMetadata) = " + e.getMessage());
        }
    }

    @Override
    public void printColumn(String _object, 
                            String _columnName, 
                            String _columnTypeName) 
    throws SQLException 
    {
        if ( (_columnTypeName.equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY) || 
              _columnTypeName.indexOf("MDSYS.ST_")>=0 
             ) 
             &&
             _columnName.equalsIgnoreCase(geoColumnName) ) {
                // System.out.println("    printColumn->"+_columnTypeName+"->" +_columnName);
                geometryData += _object.replaceFirst(" </altitudeMode>",
                                                     "</altitudeMode>");
        } else { // Process Attribute column
            // System.out.println("    printColumn->" + _columnName);
            // Passed in object is already a string
            //
            String columnName = _columnName;
                   if ( columnName.equalsIgnoreCase("id") )             { PlaceMarkAttributes.put( "id",           (String)_object);
            } else if ( columnName.equalsIgnoreCase("name") )           { PlaceMarkAttributes.put( "name",         "      <name>" + ((String)_object) + "</name>"  );
            } else if ( columnName.equalsIgnoreCase("visibility") )     { PlaceMarkAttributes.put( "visibility",   "      <visibility>" + ((String)_object) + "</visibility>" );
            } else if ( columnName.equalsIgnoreCase("open") )           { PlaceMarkAttributes.put( "open",         "      <open>" + ((String)_object) + "</open>" );
            } else if ( columnName.equalsIgnoreCase("author") )         { PlaceMarkAttributes.put( "author",       "      <atom:author>" + ((String)_object) + "</atom:author>" );
            } else if ( columnName.equalsIgnoreCase("link") )           { PlaceMarkAttributes.put( "link",         "      <atom:link>" + ((String)_object) + "</atom:link>" );
            } else if ( columnName.equalsIgnoreCase("address") )        { PlaceMarkAttributes.put( "address",      "      <address>" + ((String)_object) + "</address>" );
            } else if ( columnName.equalsIgnoreCase("phoneNumber") )    { PlaceMarkAttributes.put( "phoneNumber",  "      <phoneNumber>" + ((String)_object) + "</phoneNumber>" );
            } else if ( columnName.equalsIgnoreCase("Snippet") )        { PlaceMarkAttributes.put( "Snippet",      "      <Snippet maxLines=\"2\">" + ((String)_object) + "</phoneNumber>" );
            } else if ( columnName.equalsIgnoreCase("description") )    { PlaceMarkAttributes.put( "description",  "      <description>" + ((String)_object) + "</description>"   );
            } else if ( columnName.equalsIgnoreCase("styleUrl")    )    { PlaceMarkAttributes.put( "styleUrl",     "      <styleUrl>" + ((String)_object) + "</styleUrl>" );
            } else {
                    /**
                    * <ExtendedData>             OR  <ExtendedData xmlns:prefix="camp">           OR <ExtendedData>
                    *   <Data name="holeNumber">       <camp:number>14</camp:number>                   <SchemaData schemaUrl="#TrailHeadTypeId">
                    *     <value>1</value>             <camp:parkingSpaces>2</camp:parkingSpaces>        <SimpleData name="TrailHeadName">Mount Everest</SimpleData>
                    *   </Data>                        <camp:tentSites>4</camp:tentSites>                <SimpleData name="TrailLength">347.45</SimpleData>
                    *   <Data name="holePar">                                                            <SimpleData name="ElevationGain">10000</SimpleData>
                    *     <value>4</value>                                                             </SchemaData>
                    *   </Data>
                    * </ExtendedData>                </ExtendedData>                                 </ExtendedData> 
                    *                                // Where camp will be the tablename/filename 
                    */
                    extendedData += "        <Data name=" + "\"" + columnName + "\">" + newLine +
                                    "          <value>" +
                    Strings.escapeHTML((String)_object) + "</value>" + newLine +
                                    "        </Data>" + newLine;
            }
        }
    }

    @Override
    public void endRow() throws IOException {
        row++;

        String idValue = "";
        if ( !Strings.isEmpty((String)PlaceMarkAttributes.get("id")) ) { 
            idValue = (String)PlaceMarkAttributes.get("id");
        } else {
            idValue = String.valueOf(row);
        }
        rowBuffer.append("    " + placeMark.replaceFirst("%d",idValue) + newLine);
        
        if ( styleUrlColumn == Integer.MIN_VALUE) {
            PlaceMarkAttributes.put( "styleUrl","      <styleUrl>#" + defaultSyleName + "</styleUrl>");
        } 

        // Print out attributes in correct order for placemark
        
        if ( !Strings.isEmpty((String)PlaceMarkAttributes.get("name"))        ) { rowBuffer.append(PlaceMarkAttributes.get("name"        ) + newLine); }
        if ( !Strings.isEmpty((String)PlaceMarkAttributes.get("visibility"))  ) { rowBuffer.append(PlaceMarkAttributes.get("visibility"  ) + newLine); }
        if ( !Strings.isEmpty((String)PlaceMarkAttributes.get("open"))        ) { rowBuffer.append(PlaceMarkAttributes.get("open"        ) + newLine); }
        if ( !Strings.isEmpty((String)PlaceMarkAttributes.get("author"))      ) { rowBuffer.append(PlaceMarkAttributes.get("author"      ) + newLine); }
        if ( !Strings.isEmpty((String)PlaceMarkAttributes.get("link"))        ) { rowBuffer.append(PlaceMarkAttributes.get("link"        ) + newLine); }
        if ( !Strings.isEmpty((String)PlaceMarkAttributes.get("address"))     ) { rowBuffer.append(PlaceMarkAttributes.get("address"     ) + newLine); }
        if ( !Strings.isEmpty((String)PlaceMarkAttributes.get("phoneNumber")) ) { rowBuffer.append(PlaceMarkAttributes.get("phoneNumber" ) + newLine); }
        if ( !Strings.isEmpty((String)PlaceMarkAttributes.get("Snippet"))     ) { rowBuffer.append(PlaceMarkAttributes.get("Snippet"     ) + newLine); }
        if ( !Strings.isEmpty((String)PlaceMarkAttributes.get("description")) ) { rowBuffer.append(PlaceMarkAttributes.get("description" ) + newLine); }
        if ( !Strings.isEmpty((String)PlaceMarkAttributes.get("styleUrl"))    ) { rowBuffer.append(PlaceMarkAttributes.get("styleUrl"    ) + newLine); }
        
        if ( extendedData.length() > 0 ) {
            rowBuffer.append("      <ExtendedData>" + newLine +
                             extendedData + 
                             "      </ExtendedData>" + newLine);
        }

        rowBuffer.append(geometryData);

        rowBuffer.append("    </Placemark>" + newLine);
        
        if ( (row % getCommit()) == 0 ) {
            kmlFile.write(rowBuffer.toString());
            rowBuffer = new StringBuffer(100000);
            kmlFile.flush();
        }
    }

    @Override
    public void end() throws IOException {
        if ( rowBuffer.length() > 0 ) {
            kmlFile.write(rowBuffer.toString());
        }  
        kmlFile.write("  </Document>" + newLine + 
                           "</kml>" + newLine);
        kmlFile.flush();
    }

    @Override
    public void close() {
        try {
            kmlFile.close();
            kmlFile = null;
        } catch (IOException ioe) {
          // Do nothing.
        }
    }

    @Override
    public void setBaseName(String _baseName) {
    }

    @Override
    public void setShapefileType(ShapeType _shapeType) {
    }

    @Override
    public ShapeType getShapefileType() {
        return null;
    }

    @Override
    public int getGeoColumnIndex() {
        return this.geoColumnIndex;
    }

    private String getXMLFlavourPrefix(Constants.XMLAttributeFlavour _flavour) {
        switch (_flavour) {
        case OGR : return "ogr";
        case FME : return "fme";
        case GML :
        default  : return "gml";
        }
    }
    
}
