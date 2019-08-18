package com.spdba.dbutils.io.exp.gml;

import com.spdba.dbutils.Constants;
import com.spdba.dbutils.io.IOConstants.EXPORT_TYPE;
import com.spdba.dbutils.spatial.Renderer.GEO_RENDERER_FORMAT;
import com.spdba.dbutils.spatial.SDO.POLYGON_RING_ORIENTATION;
import com.spdba.dbutils.Constants.XMLAttributeFlavour;
import com.spdba.dbutils.io.GeometryProperties;
import com.spdba.dbutils.io.exp.IExporter;
import com.spdba.dbutils.spatial.Envelope;
import com.spdba.dbutils.spatial.Renderer;
import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.sql.DBConnection;
import com.spdba.dbutils.sql.OraRowSetMetaDataImpl;
import com.spdba.dbutils.sql.SQLConversionTools;
import com.spdba.dbutils.tools.FileUtils;
import com.spdba.dbutils.tools.LOGGER;
import com.spdba.dbutils.tools.Strings;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;

import java.sql.Connection;
import java.sql.ResultSet;

import java.sql.SQLException;

import java.util.LinkedHashMap;

import javax.sql.RowSetMetaData;

import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleResultSetMetaData;

import oracle.spatial.util.GML3;

import oracle.sql.STRUCT;

import org.geotools.data.shapefile.shp.ShapeType;

public class GMLExporter 
implements IExporter 
{
    private static final LOGGER LOGGER = new LOGGER("com.spdba.dbutils.io.export.gml.GMLExporter");

    private final static String GmlNameSpace = "xmlns:gml=\"http://www.opengis.net/gml\"";
    private String                   newLine = System.getProperty("line.separator");
  
    private Connection                              conn = null;
    private ResultSet                          resultSet = null;
    private int                           geoColumnIndex = -1;
    private String                         geoColumnName = "";
    private static int                            commit = 100;
    private GeometryProperties        geometryProperties = null;
    private LinkedHashMap<Integer,
                          RowSetMetaData> exportMetadata = null;
    private String                              baseName = "";
    private int                                      row = 0;
    private int                                totalRows = 0;    
    
    private String                               srsName = null;
    private String                          srsNameSpace = null;
    private int                             srsDimension = 2;
    private int                                 prevSRID = SDO.SRID_NULL;
    private Envelope                          fileExtent = null;
    private String                           gmlFilename = "";
    private StringBuffer                       rowBuffer = null;
    private BufferedWriter                       gmlFile = null;
    private boolean                      needsIdentifier = false;
    private POLYGON_RING_ORIENTATION     polyOrientation = POLYGON_RING_ORIENTATION.ORACLE;
    private int                 decimalDigitsOfPrecision = 3;
    private GEO_RENDERER_FORMAT          geoRenderFormat = GEO_RENDERER_FORMAT.WKT;
    private GEO_RENDERER_FORMAT               gmlVersion = GEO_RENDERER_FORMAT.GML3;
    private Constants.XMLAttributeFlavour     XMLFlavour = Constants.XMLAttributeFlavour.OGR;
    
    public GMLExporter (Connection               _conn,
                        String                   _fileName,
                        int                      _rowsToProcess,
                        POLYGON_RING_ORIENTATION _polygonOrientation,
                        int                      _decimalDigitsOfPrecision) 
    {
        super();
        conn = _conn;
        this.totalRows = _rowsToProcess;
        setFileName(_fileName);
        polyOrientation = (_polygonOrientation==null) ? POLYGON_RING_ORIENTATION.INVERSE : _polygonOrientation;
        SDO.setPolygonRingOrientation(polyOrientation);
        decimalDigitsOfPrecision = _decimalDigitsOfPrecision;
        GML3.setConnection(this.conn);
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
    public int getRowCount() {
      return this.row;
    }

    @Override
    public void setTotalRows(int _totalRows) {
        this.totalRows = _totalRows;
    }

    @Override
    public int getTotalRows() {
        return this.totalRows ;
    }

    @Override
    public EXPORT_TYPE getExportType() {
        return EXPORT_TYPE.GML;
    }

    @Override
    public String getBaseName() {
        return FileUtils.getFileNameFromPath(this.gmlFilename,true);
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

    @Override
    public boolean hasAttributes() {
        if ( this.resultSet != null ) {
            return SQLConversionTools.hasAttributeColumns((OracleResultSet) this.resultSet, this.geoColumnIndex);
        }
        return false;
    }

    @Override
    public int getGeoColumnIndex() {
        return geoColumnIndex;
    }

    @Override
    public String getGeoColumnName() {
        return geoColumnName;
    }

    @Override
    public Envelope getExtent() {
        return fileExtent;
    }

    @Override
    public void setExtent(Envelope _extent) {
        fileExtent = _extent;
    }

    @Override
    public void updateExtent(Envelope _extent) {
        fileExtent.setMaxMBR(_extent);
    }

    @Override
    public boolean skipNullGeometry() {
        return true;
    }

    @Override
    public void setSkipNullGeometry(boolean _skip) {
        // TODO Implement this method
    }
    
    @Override
    public void setPrecisionScale(int _precisionScale) {
        decimalDigitsOfPrecision = _precisionScale;
    }

    @Override
    public int getPrecisionScale() {
        return decimalDigitsOfPrecision;
    }

    @Override
    public void setPolygonOrientation(POLYGON_RING_ORIENTATION _polyOrientation) {
        this.polyOrientation = _polyOrientation;
    }

    @Override
    public POLYGON_RING_ORIENTATION getPolygonOrientation() {
        return this.polyOrientation;
    }

    @Override    
    public void setExportMetadata(LinkedHashMap<Integer, RowSetMetaData> _exportMetadata) {
      this.exportMetadata = _exportMetadata;
    }
    
    @Override    
    public LinkedHashMap<Integer, RowSetMetaData> getExportMetadata() {
      return this.exportMetadata;
    }

    @Override    
    public GeometryProperties getGeometryProperties() {
        return this.geometryProperties;
    }
    
    @Override    
    public void setGeometryProperties(GeometryProperties _geometryProperties) {
        this.geometryProperties = _geometryProperties;
    }

    @Override    
    public String getFileName() {
        return this.gmlFilename; 
    }
    
    @Override    
    public void setFileName(String _fileName) {
        this.gmlFilename = _fileName;    
    }
    
    @Override    
    public void setBaseName(String _baseName) {
        this.baseName = _baseName;
    }

    @Override    
    public String getFileExtension() {
        return "gml";
    }
    
    @Override    
    public void setCommit(int _commit) {
        GMLExporter.commit = _commit;
    }
    
    @Override    
    public int getCommit() {
        return GMLExporter.commit;      
    }
        
    @Override    
    public void setGeoColumnIndex(int _geoColumnIndex) {
        this.geoColumnIndex = _geoColumnIndex;
    }

    @Override    
    public void setGeoColumnName(String _geoColumnName) {
        this.geoColumnName = _geoColumnName;
    }

    /** PROCESSING ENTRY POINTS */
    
    @Override    
    public void start(String _encoding) throws Exception {
        
        writeXSD((OracleResultSet)this.resultSet);
        
        this.rowBuffer = new StringBuffer(10000);
        if (Strings.isEmpty(gmlFilename) ) {
            throw new IOException("Filename not set");
        }
        this.gmlFile      = new BufferedWriter(new FileWriter(this.gmlFilename));
        this.row          = 0;
        this.fileExtent   = new Envelope(Constants.MAX_PRECISION);
        this.srsName      = null;
        this.srsNameSpace = null; 
        this.prevSRID     = SDO.SRID_NULL;
        this.srsDimension = 2;
        this.gmlFile.write("<?xml version='1.0'  encoding='" + _encoding + "' ?>" + newLine);
        if ( this.XMLFlavour.equals(Constants.XMLAttributeFlavour.OGR) ) {
          this.gmlFile.write("<ogr:FeatureCollection" + newLine + 
                              "     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"" + newLine +
                              "     " + GmlNameSpace + newLine +
                              "     xmlns:ogr=\"http://ogr.maptools.org/\"" + newLine +
                              "     xsi:schemaLocation=\"http://ogr.maptools.org/" + this.baseName + ".xsd\">" + newLine );
        } else if (this.XMLFlavour.equals(Constants.XMLAttributeFlavour.FME)) {
          this.gmlFile.write("<gml:FeatureCollection" + newLine + 
                              "     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"" + newLine +
                              "     xmlns:xlink=\"http://www.w3.org/1999/xlink\"" + newLine +
                              "     " + GmlNameSpace + newLine +
                              "     xmlns:fme=\"http://www.safe.com/gml/fme\"" + newLine +
                              "     xsi:schemaLocation=\"http://www.safe.com/gml/fme/" + this.baseName + ".xsd\">" + newLine); 
        } else {
          this.gmlFile.write("<gml:FeatureCollection " + newLine + 
                              "     xmlns:xlink=\"http://www.w3.org/1999/xlink\" " + newLine +
                              "     " + GmlNameSpace + " " + newLine +
                              "     xsi:schemaLocation=\"file:///" + this.gmlFilename.replace(".gml",".xsd").replace("\\","/") + "\"" + newLine + 
                              "     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">" + newLine );
        }
    }

    @Override    
    public void startRow() throws IOException {
        this.rowBuffer.append("  <gml:featureMember>" + newLine);
        if ( this.hasAttributes() ) {
            if ( this.XMLFlavour.equals(Constants.XMLAttributeFlavour.OGR)  ) {
                this.rowBuffer.append("    <ogr:" + this.baseName + /* " ogr:fid=\"F" + String.valueOf(row) + "\""*/ ">" + newLine);
            } else if ( this.XMLFlavour.equals(Constants.XMLAttributeFlavour.FME) ) {
                this.rowBuffer.append("    <fme:" + this.baseName + /* " fme:id=\"" + String.valueOf(row) + "\"" */ ">" + newLine);
            }
        }
    }

    @Override    
    public void printColumn(Object                _object, 
                            OraRowSetMetaDataImpl _columnMetaData) 
    {
        String gmlText = "";
        STRUCT stValue = null; 
        try {
            boolean isGeometryColumn = ! Strings.isEmpty(_columnMetaData.getCatalogName(1));
            // Mappable column?
            // System.out.println("CatalogName: ****"+_columnMetaData.getCatalogName(1)+"*** Type: " + _columnMetaData.getColumnTypeName(1) + " => isGeometryColumn=" + String.valueOf(isGeometryColumn) );
            if ( isGeometryColumn )   // Catalog name holds name of actual geometry column 
            {
                if ( _columnMetaData.getColumnTypeName(1).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY) ) 
                {
                    gmlText = "";
                    stValue = (STRUCT)_object; 
                    if ( stValue == null ) {
                        LOGGER.warn("NULL Geometry: No featureMember element written for row " + (row+1));
                        // Will produce an empty featureMember
                       return;
                    }
                    
                    // get SRID
                    int SRID = SDO.getSRID(stValue, SDO.SRID_NULL);
                    if ( SRID == SDO.SRID_NULL ) {
                        LOGGER.warn("Geometry's SRID is NULL: No featureMember element written for row " + (row+1));
                        return;
                    }
                    
                    // Check if we have already gotten the SrsNames from the database
                    if ( SRID != this.prevSRID ) {
                        // Get srsName and srsNamespace from SrsNameSpace_Table
                        String srsNames = DBConnection.getSrsNames(conn,
                                                                   SRID,
                                                                   "@",
                                                                   true);
                        if ( !Strings.isEmpty(srsNames) ) {
                            this.srsName      = srsNames.substring(0,srsNames.indexOf("@"));
                            this.srsNameSpace = srsNames.substring(srsNames.indexOf("@")+1);
                        }
                        this.prevSRID = SRID;
                    }
                    
                    int dim = SDO.getDimension(stValue, 2);
                    if ( dim != this.srsDimension ) {
                        this.srsDimension = dim; 
                    }
                    // Use SDO Exporter.
                    // TODO: Support for JTS's GMLWriter
                    //
                    gmlText = GML3.to_GML3Geometry(stValue);
                    if ( this.XMLFlavour.equals(Constants.XMLAttributeFlavour.FME) ) {
                        gmlText = gmlText.replaceAll(GmlNameSpace,"");
                        gmlText = gmlText.replace("srsName=\"SDO:" + String.valueOf(SRID) + "\"",
                                                  "srsName=\"EPSG:" + String.valueOf(SRID) + "\"");
                    } else {
                        gmlText = gmlText.replaceAll(GmlNameSpace, "xmlns:urn=\"" + this.srsNameSpace + "\"");
                        gmlText = gmlText.replace("srsName=\"SDO:" + String.valueOf(SRID) + "\"", "srsName=\"urn:" + this.srsName + "\" ");
                    }

                    // Update GML file's envelope
                    //
                    Envelope geomMBR = SDO.getGeoMBR(stValue);
                    this.fileExtent.setMaxMBR(geomMBR);
                    this.rowBuffer.append("      <" + this.getXMLFlavourPrefix(this.XMLFlavour) + ":geometryProperty>" + newLine + 
                                          "        " + gmlText + newLine + 
                                          "      </" + this.getXMLFlavourPrefix(this.XMLFlavour) + ":geometryProperty>" + newLine);
                } 
            } else { // Process Attribute column
                // Passed in _object is already a string
                //
                try {
                    String line2Write = 
                         "      <" + this.getXMLFlavourPrefix(this.XMLFlavour) + ":" + _columnMetaData.getColumnName(1) + ">" +
                                   _object.toString() +
                               "</" + this.getXMLFlavourPrefix(this.XMLFlavour) + ":" + _columnMetaData.getColumnName(1) + ">" + newLine;
                    this.rowBuffer.append(line2Write);
                } catch (Exception e) {
                    LOGGER.warn("Conversion of " + _columnMetaData.getColumnName(1) + "/" + _columnMetaData.getColumnTypeName(1) + " failed at row " + (this.row+1) + " - " + e.getMessage());
                }
            }
        } catch (Exception e) {
            LOGGER.warn("GMLExporter.printColumn(object,ResultSetMetadata) = " + e.getMessage());
        }
    }

    /**
     * Method for printing generated, as against rowset data, eg rowIdentifier
     * @param _object
     * @param _columnName
     * @param _columnTypeName
     */
    @Override    
    public void printColumn(String _object,
                            String _columnName,
                            String _columnTypeName) 
    throws SQLException 
    {
        if ( ! Strings.isEmpty(_object) ) {
            try {
                this.gmlFile.write(_object);
            } catch (IOException e) {
                System.err.println("GMLExporter.printColumn() failed with " + e.getLocalizedMessage());
            }
        } 
    }

    @Override    
    public void endRow() throws IOException {        
        this.row++;
        if ( this.hasAttributes() ) {
            this.rowBuffer.append("    </" + this.getXMLFlavourPrefix(this.XMLFlavour) + ":" + this.baseName + ">" + newLine);
        }
        this.rowBuffer.append("  </gml:featureMember>" + newLine);
        if ( this.row % this.getCommit() == 0 ) {
            this.gmlFile.write(this.rowBuffer.toString());
            this.rowBuffer = new StringBuffer(10000);
        }
    }

    @Override    
    public void end() throws IOException {
        if ( this.rowBuffer.length() > 0 ) {
            this.gmlFile.write(this.rowBuffer.toString());
        } 
        String srsNameEnv = "";
        if ( this.XMLFlavour.equals(Constants.XMLAttributeFlavour.FME) ) {
            srsNameEnv = "srsName=\"EPSG:" + this.prevSRID +  "\" ";
        } else {
            srsNameEnv = "srsName=\"urn:" + this.srsName + "\" ";
        }
        String srsDimEnv = this.XMLFlavour.equals(Constants.XMLAttributeFlavour.FME) ? "" : ("srsDimension=\"" + srsDimension + "\"");
        gmlFile.write(
              "<gml:boundedBy>" + newLine +                        
              "  <gml:Envelope " + srsNameEnv + srsDimEnv + ">" + newLine + 
              "    <gml:lowerCorner>" + this.fileExtent.getMinX() + " " + fileExtent.getMinY() + "</gml:lowerCorner>" + newLine + 
              "    <gml:upperCorner>" + this.fileExtent.getMaxX() + " " + fileExtent.getMaxY() + "</gml:upperCorner>" + newLine + 
              "  </gml:Envelope>" + newLine + 
              "</gml:boundedBy>" + newLine
        );
        // Should be one line </ogr/fme:
        if ( this.XMLFlavour.equals(Constants.XMLAttributeFlavour.OGR) ) {
            this.gmlFile.write("</ogr:FeatureCollection>");
        } else {
            this.gmlFile.write("</gml:FeatureCollection>");
        }
        this.gmlFile.flush();
    }
    
    @Override    
    public void close() {
        try {
            this.gmlFile.close();
            this.gmlFile = null;
        } catch (IOException ioe) {
          // Do nothing.
        }
    }

    public void setGenerateIdentifier(Boolean _hasAttributes ) {
        this.needsIdentifier = _hasAttributes;                                         
    }

    /* *****************************************************************************
     * Private Members
     **/

    private String getXMLFlavourPrefix(Constants.XMLAttributeFlavour _flavour) {
        switch (_flavour) {
        case OGR : return "ogr";
        case FME : return "fme";
        case GML :
        default  : return "gml";
        }
    }
    
    public void setGMLVersion(String _GMLVersion) {
        this.gmlVersion = GEO_RENDERER_FORMAT.getRendererFormat(_GMLVersion);
        if ( this.gmlVersion.toString().startsWith("GML") ) {
          this.gmlVersion = GEO_RENDERER_FORMAT.GML3;
        }
    }

    public GEO_RENDERER_FORMAT getGMLVersion() {
        return this.gmlVersion;
    }

    private void writeXSD(OracleResultSet _rSet) 
    {
        if (Strings.isEmpty(this.getFileName()) || Strings.isEmpty(this.getBaseName()) )
            return;
        try {
            String xsdFileName = this.getFileName().replace("."+this.getExportType().toString().toLowerCase(),".xsd");
            BufferedWriter xsdFile = null;
            String newLine = System.getProperty("line.separator");
            
            String xmlns_xs  = "  xmlns:xs=\"http://www.w3.org/2001/XMLSchema\"";
            String xmlns_gml = "  xmlns:gml=\"http://www.opengis.net/gml\"";
            String import_gml = "<xs:import namespace=\"http://www.opengis.net/gml\" schemaLocation=\"http://schemas.opengis.net/gml/3.1.1/base/gml.xsd\"/>";
            String xmlns_flavour = this.getXMLFlavour().equals(Constants.XMLAttributeFlavour.FME)
                                   ? "  xmlns:fme=\"http://www.safe.com/gml/fme\""
                                   : "  xmlns:ogr=\"http://ogr.maptools.org/\"";
            String targetNamespace_flavour = this.getXMLFlavour().equals(Constants.XMLAttributeFlavour.FME)
                                             ? "  targetNamespace=\"http://www.safe.com/gml/fme\""
                                             : "  targetNamespace=\"http://ogr.maptools.org/\"";
    
            xsdFile = new BufferedWriter(new FileWriter(xsdFileName)); 
            xsdFile.write("<?xml version='1.0'  encoding='" + DBConnection.getCharacterSet(this.getConnection()) + "' ?>" + newLine);
            xsdFile.write("<xs:schema " + newLine +
                          xmlns_xs + newLine +
                          xmlns_gml + newLine +
                          xmlns_flavour  + newLine +
                          targetNamespace_flavour + newLine + "  elementFormDefault=\"qualified\" version=\"1.0\">" + newLine +
                          import_gml + newLine);
            if ( this.getXMLFlavour().equals(Constants.XMLAttributeFlavour.OGR) ) {
                // Feature collection type is entirely OGR
                //
                xsdFile.write("<xs:element name=\"FeatureCollection\" type=\"ogr:FeatureCollectionType\" substitutionGroup=\"gml:_FeatureCollection\"/>" + newLine +
                              " <xs:complexType name=\"FeatureCollectionType\">" + newLine +
                              "  <xs:complexContent>" + newLine +
                              "    <xs:extension base=\"gml:AbstractFeatureCollectionType\">" + newLine +
                              "      <xs:attribute name=\"lockId\" type=\"xs:string\" use=\"optional\"/>" + newLine +
                              "      <xs:attribute name=\"scope\" type=\"xs:string\" use=\"optional\"/>" + newLine +
                              "    </xs:extension>" + newLine +
                              "  </xs:complexContent>" + newLine +
                              " </xs:complexType>" + newLine);                              
            }
            // Everything else is common
            //
            xsdFile.write(   "<xs:element name=\"" + this.getBaseName() + 
                             "\" type=\"" + 
                                this.getXMLFlavour().toString().toLowerCase() + ":" +
                                this.getBaseName() + 
                                "Type\" substitutionGroup=\"gml:_Feature\"/>" + newLine +
                             " <xs:complexType name=\"" + this.getBaseName() + "Type\">" + newLine + 
                              "  <xs:complexContent>" + newLine + 
                              "    <xs:extension base=\"gml:AbstractFeatureType\">" + newLine + 
                              "      <xs:sequence>" + newLine);
            
            // Write common attribute XSD elements
            //
            String columnName = "";
            OracleResultSetMetaData meta = (OracleResultSetMetaData)_rSet.getMetaData();
            for (int col = 1; col < meta.getColumnCount(); col++) 
            {
                columnName = meta.getColumnName(col).replace("\"","");
                if ( columnName.equalsIgnoreCase(getGeoColumnName()) ) {
                    xsdFile.write("    <xs:element name=\"geometryProperty\" type=\"gml:GeometryPropertyType\"" +
                                               "   nillable=\""  + (meta.isNullable(col)==OracleResultSetMetaData.columnNullable) +
                                               "\" minOccurs=\"" + (meta.isNullable(col)==OracleResultSetMetaData.columnNullable?"0":"1") +
                                               "\" maxOccurs=\"1\"/>" + newLine);
                } else {
                    String xsdDataType = "";
                    for (int rCol=1;rCol<=meta.getColumnCount();rCol++) {
                      // Is a supported column?
                      if ( meta.getColumnLabel(rCol).equalsIgnoreCase(columnName) ) {
                          if (SQLConversionTools.isSupportedType(meta.getColumnType(rCol),meta.getColumnTypeName(rCol))==false) 
                              continue;
                          xsdDataType = SQLConversionTools.dataTypeToXSD(meta,rCol);
                          xsdFile.write("    <xs:element name=\"" + columnName + 
                                                      "\" nillable=\""  + (meta.isNullable(rCol)==OracleResultSetMetaData.columnNullable) +
                                                      "\" minOccurs=\"" + (meta.isNullable(rCol)==OracleResultSetMetaData.columnNullable?"0":"1") + 
                                                      "\" maxOccurs=\"1\">" + newLine + 
                                        "      <xs:simpleType>" + newLine +
                                        "        <xs:restriction base=\"xs:");
                          
                          int prec = meta.getPrecision(rCol);
                          int scale = meta.getScale(rCol);
                          if ( prec <= 0 ) {
                              prec = meta.getColumnDisplaySize(rCol);
                              scale = 0;
                          }
                          if ( xsdDataType.equalsIgnoreCase("string") ) {
                              xsdFile.write(xsdDataType + "\">" + newLine + 
                                            "          <xs:maxLength value=\"" + prec + "\" fixed=\"false\"/>" + newLine +
                                            "        </xs:restriction>" + newLine);
                          } else if ( xsdDataType.equalsIgnoreCase("clob") ) {
                              xsdFile.write("string" + "\">" + newLine + 
                                            "          <xs:minLength value=\"1\"/>" + newLine +
                                            "        </xs:restriction>" + newLine);
                          } else if ( xsdDataType.equalsIgnoreCase("float") || 
                                      xsdDataType.equalsIgnoreCase("double") ||
                                      xsdDataType.equalsIgnoreCase("date")   || 
                                      xsdDataType.equalsIgnoreCase("time")   || 
                                      xsdDataType.equalsIgnoreCase("dateTime") ) {
                              xsdFile.write(xsdDataType + "\"/>" + newLine);
                          } else {
                              xsdFile.write(xsdDataType + "\">" + newLine + 
                                                 "               <xs:totalDigits value=\"" + prec + "\"/>" + newLine +
                                (scale==0 ? "" : "               <xs:fractionDigits value=\"" + scale + "\"/>" + newLine ) +
                                                 "        </xs:restriction>" + newLine );
                          }
                          xsdFile.write( 
                            "      </xs:simpleType>" + newLine + 
                            "    </xs:element>" + newLine);
                          break;
                      }
                  }
                }
            }            
            xsdFile.write("      </xs:sequence>" + newLine +
                          "    </xs:extension>" + newLine +
                          "  </xs:complexContent>" + newLine +
                          " </xs:complexType>" + newLine +
                          "</xs:schema>");
            xsdFile.flush();
            xsdFile.close();
      } catch (IOException e) {
          LOGGER.severe("IOException in ExporterWriter.writeXSD() " + e.getMessage());
      } catch (SQLException e) {
          LOGGER.severe("SQLException in ExporterWriter.writeXSD() " + e.getMessage());
      } catch (Exception e) {
          LOGGER.severe("Exception in ExporterWriter.writeXSD() " + e.getMessage());
      }
    }
                                
    /** UnNeeded IExplorer Methods
     **/
    
    @Override
    public void setShapefileType(ShapeType _shapeType) {
    }

    @Override
    public ShapeType getShapefileType() {
        return null;
    }

    @Override
    public boolean generateIdentifier() {
        return false;
    }

    @Override
    public void setRecordIdentifier(String _recordIdentifier) {
    }

    @Override
    public String getRecordIdentifier() {
        return null;
    }

    @Override
    public String getTextDelimiter() {
        return null;
    }

    @Override
    public String getFieldSeparator() {
        return null;
    }

    @Override
    public boolean isSupportedType(int columnType, String columnTypeName) {
        return SQLConversionTools.isSupportedType(columnType,columnTypeName);
    }
}
