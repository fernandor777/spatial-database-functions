package com.spdba.dbutils.io.exp.shp;

import com.spdba.dbutils.Constants;
import com.spdba.dbutils.io.IOConstants.EXPORT_TYPE;
import com.spdba.dbutils.spatial.Renderer.GEO_RENDERER_FORMAT;
import com.spdba.dbutils.spatial.SDO.POLYGON_RING_ORIENTATION;
import com.spdba.dbutils.Constants.XMLAttributeFlavour;
import com.spdba.dbutils.io.GeometryProperties;
import com.spdba.dbutils.io.exp.IExporter;
import com.spdba.dbutils.io.exp.xbase.DBaseWriter;
import com.spdba.dbutils.spatial.Envelope;
import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.sql.DBConnection;
import com.spdba.dbutils.sql.OraRowSetMetaDataImpl;
import com.spdba.dbutils.sql.SQLConversionTools;
import com.spdba.dbutils.tools.FileUtils;
import com.spdba.dbutils.tools.Strings;

import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.io.oracle.OraReader;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;

import java.text.SimpleDateFormat;

import java.util.Date;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.logging.Logger;

import javax.sql.RowSetMetaData;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.OracleResultSet;

import oracle.jdbc.OracleTypes;

import oracle.sql.STRUCT;

import org.geotools.data.shapefile.shp.ShapeType;
import org.geotools.data.shapefile.shp.ShapefileException;
import org.geotools.util.logging.Logging;

import org.xBaseJ.micro.DBFTypes;
import org.xBaseJ.micro.fields.CharField;
import org.xBaseJ.micro.fields.DateField;
import org.xBaseJ.micro.fields.Field;
import org.xBaseJ.micro.fields.LogicalField;
import org.xBaseJ.micro.fields.MemoField;
import org.xBaseJ.micro.fields.NumField;
import org.xBaseJ.micro.fields.PictureField;
import org.xBaseJ.micro.xBaseJException;

public class SHPExporter 
implements IExporter 
{

    private static final Logger LOGGER = Logging.getLogger("com.spdba.io.export.shp");
    
    private Connection                                      conn = null;
    private ResultSet                                  resultSet = null;
    private int                                   geoColumnIndex = -1;
    private String                                 geoColumnName = "";
    private GEO_RENDERER_FORMAT                  geoRenderFormat = GEO_RENDERER_FORMAT.WKT;
    private GeometryProperties                geometryProperties = null;
    private int                                              row = 0;
    private int                                        totalRows = 0;    
    private LinkedHashMap<Integer,RowSetMetaData> exportMetadata = null;
    
    private Constants.XMLAttributeFlavour                      XMLFlavour = Constants.XMLAttributeFlavour.OGR;
    private DBFTypes                                   xBaseType = DBFTypes.DBASEIII;
    
    protected LinkedHashSet<Geometry>                    geomSet = null;
    private Geometry                                        geom = null;
    private int                                           commit = 100;
    private OraReader                              geomConverter = null; 
    private GeometryFactory                          geomFactory = null;
    private String                                   SHPFilename = "";
    private String                                   prjContents = "";
    private POLYGON_RING_ORIENTATION             polyOrientation = POLYGON_RING_ORIENTATION.ORACLE;
    private int                         decimalDigitsOfPrecision = 3;
    public Envelope                                   fileExtent = null;
    private boolean                             skipNullGeometry = true;
    public String                               recordIdentifier = null;

    protected ShapefileWriter                          shpWriter = null;
    protected DBaseWriter                            dbaseWriter = null;

    public SHPExporter (Connection               _conn,
                        String                   _fileName,
                        int                      _shapeCount,
                        POLYGON_RING_ORIENTATION _polygonOrientation,
                        int                      _decimalDigitsOfPrecision) 
    {
        super();
        conn = _conn;
        this.totalRows = _shapeCount;
        setFileName(_fileName);
        polyOrientation = (_polygonOrientation==null) ? POLYGON_RING_ORIENTATION.INVERSE : _polygonOrientation;
        SDO.setPolygonRingOrientation(polyOrientation);
        decimalDigitsOfPrecision = _decimalDigitsOfPrecision;
        geometryProperties = new GeometryProperties();
    }

    /* *****************************************************************************************
     * IExporter Getters and Setters
     **/
    
    @Override
    public void setConnection(Connection _conn) {
        if (_conn != null) {
            DBConnection.setConnection((OracleConnection)_conn);
        }
        try {
            this.conn = DBConnection.getConnection();  // Handles Null case when executing in DBMS JVM
        } catch (SQLException e) {
        }
    }

    @Override
    public Connection getConnection() 
    {
        try {
            return this.conn == null ? DBConnection.getConnection() : this.conn;
        } catch (SQLException e) {
        }
        return this.conn;
    }

    @Override
    public ResultSet getResultSet() {
        return this.resultSet;
    }

    @Override
    public void setResultSet(ResultSet _rSet) {
        this.resultSet = _rSet;
    }


    @Override
    public boolean skipNullGeometry() {
        return this.skipNullGeometry;
    }

    @Override
    public void setSkipNullGeometry(boolean _skip) {
        this.skipNullGeometry = _skip;
    }

    @Override
    public boolean generateIdentifier() {
        return !Strings.isEmpty(this.recordIdentifier);
    }
    @Override
    public void setRecordIdentifier(String _recordIdentifier) {
//System.out.println("SHPExporter.setRecordIdentifier(" + _recordIdentifier + ")");
        this.recordIdentifier = _recordIdentifier;
    }
    @Override
    public String getRecordIdentifier() {
        return recordIdentifier;
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
    public EXPORT_TYPE getExportType() {
      return EXPORT_TYPE.SHP;
    }

    @Override
    public GeometryProperties getGeometryProperties() {
        return geometryProperties;
    }
    
    @Override
    public void setGeometryProperties(GeometryProperties _geometryProperties) {
        this.geometryProperties.setProperties(_geometryProperties);
    }

    @Override
    public String getFileName() {
        return this.SHPFilename ; 
    }
  
    @Override
    public void setFileName(String _fileName) {
        SHPFilename = _fileName; 
    }

    @Override
    public void setBaseName(String _baseName) {
    }

    @Override
    public String getBaseName() {
        return FileUtils.getFileNameFromPath(this.SHPFilename,true);
    }

    @Override
    public String getFileExtension() {
        return "shp";
    }

    @Override
    public void setCommit(int _commit) {
      this.commit = _commit;
    }
    
    @Override
    public int getCommit() {
        return this.commit; 
    }

    @Override
    public void setGeometryFormat(String _renderFormat) {
        this.geoRenderFormat = GEO_RENDERER_FORMAT.getRendererFormat(_renderFormat);
    }

    @Override
    public GEO_RENDERER_FORMAT getGeometryFormat() {
        return this.geoRenderFormat;
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
        polyOrientation = _polyOrientation;
    }

    @Override
    public POLYGON_RING_ORIENTATION getPolygonOrientation() {
        return polyOrientation;
    }

    @Override
    public void setXMLFlavour(String _flavour) {
        if ( Strings.isEmpty(_flavour) ) {
            XMLFlavour = Constants.XMLAttributeFlavour.FME;
        } else {
            try {
                this.XMLFlavour = Constants.XMLAttributeFlavour.valueOf(_flavour); 
            } catch (Exception e) {
                this.XMLFlavour = Constants.XMLAttributeFlavour.OGR;
            }
        }
    }

    @Override
    public void setXMLFlavour(Constants.XMLAttributeFlavour _flavour) {
        XMLFlavour = _flavour;
    }

    @Override
    public Constants.XMLAttributeFlavour getXMLFlavour() {
        return XMLFlavour;
    }

    @Override
    public void setGeoColumnIndex(int _geoColumnIndex) {
        this.geoColumnIndex = _geoColumnIndex;
    }

    @Override
    public int getGeoColumnIndex() {
        return this.geoColumnIndex;
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
    public int getRowCount() {
        return this.row;
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
    public void setShapefileType(ShapeType _shapeType) {
        if ( _shapeType == null ) {
            return;
        }
        this.geometryProperties.setShapefileType(_shapeType);
    }
    
    @Override
    public ShapeType getShapefileType() {
        return this.geometryProperties.getShapefileType();
    }

    @Override
    public boolean hasAttributes() {
        if ( this.resultSet != null ) {
            return SQLConversionTools.hasAttributeColumns((OracleResultSet) this.resultSet, this.geoColumnIndex);
        }
        return false;
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
    public void updateExtent(Envelope _e) {
       if (fileExtent == null)
         fileExtent = new Envelope(_e);
       else
         fileExtent.setMaxMBR(_e);
    }

    @Override
    public void start(String _encoding) 
         throws Exception
    {
//System.out.println("SHPExporter: SHPExporter.start");
        this.row = 0;
        try {
            if ( this.geomSet == null ) {
                this.geomSet = new LinkedHashSet<Geometry>(this.getCommit());
            }
            // Create required sdo_geometry to shape conversion functions
            //
            this.geomFactory   = new GeometryFactory(new PrecisionModel(decimalDigitsOfPrecision));
            this.geomConverter = new OraReader(this.geomFactory);
            // Check file name 
            if (Strings.isEmpty(SHPFilename) ) {
                throw new Exception("Shape filename not set");
            }
            ShapeType SHPFileType = getShapefileType();
            boolean   hasMeasures = SHPFileType.hasMeasure();
            boolean   hasZ        = SHPFileType.hasZ();
            // Temporarily force measured shape output ordinate to the z ordinate
            if ( hasMeasures && ( ! hasZ) ) {
                // A z always has an id value 10 less than m
                this.setShapefileType(ShapeType.forID(SHPFileType.id-10));
                //LOGGER.info("Writing " + ShapeType.forID(this.shpType.id+10).toString() + " shapes as " + this.shpType.toString());
            } else if ( SHPFileType.equals(ShapeType.UNDEFINED) ) {
                throw new Exception("ShapefileWriter: Unknown or unsupported shapeType (" + SHPFileType.toString() + ") provided.");
            }
            String dirName = FileUtils.getDirectory(this.SHPFilename);
            String fNameNoExt = FileUtils.getFileNameFromPath(this.SHPFilename,true);
            this.shpWriter   = new ShapefileWriter(dirName, 
                                                   fNameNoExt, 
                                                   SHPFileType, 
                                                   this.getTotalRows());
            this.dbaseWriter = new DBaseWriter();
            this.dbaseWriter.setRecordIdentiferName(this.getRecordIdentifier());
            this.dbaseWriter.setXBaseType(this.xBaseType);
            this.dbaseWriter.createDBF(FileUtils.FileNameBuilder(dirName, fNameNoExt, "dbf"),_encoding);
            this.dbaseWriter.createHeader(this.exportMetadata,this.geoColumnName);
//System.out.println("this.dbasewriter FieldsListCount: " + this.dbaseWriter.getFields().size());
        } catch (ShapefileException se) {
            throw new Exception("SHPExporter.start: Shapefile Exception " + se.getMessage());
        } catch (FileNotFoundException fnfe) {
            throw new Exception("SHPExporter.start: Unable to access directory for writing."+fnfe.getMessage());
        } catch (IOException ioe) {
            throw new Exception(Strings.isEmpty(ioe.getMessage()) ? "SHPExporter.start: Error initialising output streams for writing." : ioe.getMessage());
        } catch (xBaseJException xbJe) {
            throw new Exception("SHPExporter.start: (XBase) Problem creating DBase file: "+xbJe.getMessage());          
        } 
    }

    @Override
    public void startRow() 
    throws IOException 
    {
        if ( this.dbaseWriter.needsRecordIdentifier() ) {
            Field field;
            try {
                field = this.dbaseWriter.getField(this.dbaseWriter.getRecordIdentiferName());
                if (field!=null) {
                    ((NumField)field).put(row+1);
                    this.dbaseWriter.setField(field);
                }
            } catch (Exception e) {
                throw new IOException("SHP: Exception writing " + this.dbaseWriter.getRecordIdentiferName() + " value " + e.getMessage());
            }
        }
    }

    private String getStringValue(Object                _object,
                                  OraRowSetMetaDataImpl _rsMD) 
    throws SQLException 
    {
        String columnValue = "";
        columnValue =
            SQLConversionTools.toString((OracleConnection)this.conn,
                                                  _object,
                                                  _rsMD,
                                                  this.getGeometryFormat());
        if ( columnValue == null ) {
            columnValue = SQLConversionTools.getDefaultNullValue(_rsMD.getColumnType(1));
        }
        return columnValue;
    }

    @Override    
    public void printColumn(String _object,
                            String _columnName,
                            String _columnTypeName) 
    throws SQLException 
    {
        if ( ! Strings.isEmpty(_object) ) {
            // To Be Done when needed
        } 
    }

    @Override
    public void printColumn(Object                _object, 
                            OraRowSetMetaDataImpl _columnMetaData) 
    throws SQLException
    {
        // Check if Mappable column
        // Catalog name holds name of actual Geometry column 
        //
        if (Strings.isEmpty(_columnMetaData.getCatalogName(1))==false 
             && _columnMetaData.getCatalogName(1).equalsIgnoreCase(this.getGeoColumnName() ) )
        {
            // We may have a non-null geoStruct
            if ( _object == null ) {
                this.addToGeomSet((STRUCT)_object);
                return;                    
            }
            // Certain geometry types cannot be written to a shapefile/tab file as are unsupported
            // Measured geometries cannot be written to KML/GML
            //
            ShapeType       shpType = this.getShapefileType();
            int          FULL_GTYPE = this.geometryProperties.getFullGType();
            boolean hasCircularArcs = SDO.hasArc((STRUCT)_object);
            if (SDO.getShapeType(FULL_GTYPE,true).equals(shpType)==false || hasCircularArcs )
            {
                throw new SQLException("Cannot write (" + getGeoColumnName() + ") SDO_GEOMETRY object with CircularArcs to a shapefile.");
            } 
            this.addToGeomSet((STRUCT)_object);
            return;
        } 
        
        // Is not mappable column, so process the supplied attribute column
        // 
        String columnName =
            Strings.isEmpty(_columnMetaData.getColumnLabel(1)) 
                                            ? _columnMetaData.getColumnName(1) 
                                            : _columnMetaData.getColumnLabel(1);

        // Regardless as to xBase dbField data type all dbField data are put as strings
        // So, convert Oracle ResultSet Column object to String.
        //
        String objectString = this.getStringValue(_object,_columnMetaData);
        char      fieldType = ' ';
        Field       dbField = null;
        try {
            dbField = this.dbaseWriter.getField(_columnMetaData.getColumnName(1));                    
            if ( dbField == null ) {
                LOGGER.info("SHPExporter.printColumn: Cannot find field in dBase file for column " + columnName);
                return;
            }
        } catch (Exception e) {
            throw new SQLException("SHPExporter.printColumn: Error retrieving field for " + columnName + " of type " + _columnMetaData.getColumnTypeName(1) + "(" +_columnMetaData.getScale(1)+ ")/" + fieldType + e.getMessage());
        }
        
        try {
            fieldType = dbField.getType();
            switch (dbField.getType())
            {
              case 'C': ((CharField)dbField).put(objectString.substring(0,Math.min(dbField.getLength(),objectString.length()))); break;
              case 'F': ((NumField)dbField).put(objectString);        break;
              case 'L': ((LogicalField)dbField).put(Strings.isEmpty(objectString)?false:Boolean.valueOf(objectString)); break;
              case 'M': ((MemoField)dbField).put(objectString);       break;
              case 'P': ((PictureField)dbField).put((byte[])_object); break;
              case 'N': if (_columnMetaData.getPrecision(1)!=0 && _columnMetaData.getScale(1)==0) {
                          ((NumField)dbField).put(objectString); 
                        } else {
                          ((NumField)dbField).put(objectString);   
                        }
                        break;
              case 'D': String dateString = (objectString.indexOf(' ')!=-1 ? objectString.substring(0, objectString.indexOf(' ')) : objectString); 
                        // Date.valueOf() expects "yyyy-mm-dd"
                        ((DateField)dbField).put(this.dbaseWriter.getDateFormat().format(this.dbaseWriter.getDateFormat().parseObject(dateString))); 
                        break;
            }
            this.dbaseWriter.setField(dbField);
        } catch (Exception e) {
            throw new SQLException("SHPExporter.printColumn: Conversion of DBase Attribute " + 
                         columnName + "/" + _columnMetaData.getColumnTypeName(1) + "(" +_columnMetaData.getScale(1)+ ")/" + fieldType + 
                         " failed at row " + (row+1) + ": " + 
                         e.getMessage());
        }
    }

    @Override
    public void endRow() 
    throws IOException 
    {
        this.row++;
        
        // Write geometry objects only if we have hit the commit point
        //
        //LOGGER.info("endRow: this.row="+this.row+" geomSet.size= " + this.geomSet.size() + "  " + getCommit());
        if ( this.geomSet.size() == getCommit() ) {
            this.writeGeomSet();
        }
        // For now, write each and every DBF record
        //
        try {
            this.dbaseWriter.write();
        } catch (xBaseJException e) {
            throw new IOException("DBase file write error " + e.getMessage());
        }
    }

    @Override
    public void end() 
    throws IOException 
    {
      // make sure to write the last Geometry set feature...
      //
      if ( this.geomSet.size() > 0 ) {
          this.writeGeomSet();
      }
      
      if ( !Strings.isEmpty(this.prjContents) ) {
          String dirName = FileUtils.getDirectory(this.SHPFilename);
          String fNameNoExt = FileUtils.getFileNameFromPath(this.SHPFilename,true);
          // Only write Prj is SRID is value
          // Should be in ExporterDialog
          if ( getGeometryProperties().getSRID() != SDO.SRID_NULL ) {
              writePrjFile(FileUtils.FileNameBuilder(dirName,
                                                     fNameNoExt,
                                                     "prj"),
                           this.prjContents);
          }
      }
    }

    @Override
    public void close() {
        try {
            // Close shapefile (writes header)
            //
            if (this.shpWriter != null) {
                this.shpWriter.close(); 
                this.shpWriter = null;
            }
            if (this.dbaseWriter != null) {
                this.dbaseWriter.close();
                this.dbaseWriter = null;
            }
        } catch ( IOException ioe ) {
          LOGGER.info("Failed to close shpWriter or dbaseWriter: " + ioe.getMessage());
        }
    }

    /* ****************************************************************************************
     * Methods specific to SHPExporter
     *
     * @param _fullyQualifiedFileName - filename including directory path and extension. 
     * @param _prjString - Actual string containing PRJ file's contents.
     * @throws FileNotFoundException - if there is an error creating the file.
     * @throws IOException - if there is an error writing to the file.
     * @name writePrjFile() 
     * @description Writes actual PRJ file 
    */
    protected static void writePrjFile(String _fullyQualifiedFileName,
                                       String _prjString ) 
    throws IOException {        
        File prjFile;
        prjFile = new File(_fullyQualifiedFileName);
        Writer prjOutput = new BufferedWriter(new FileWriter(prjFile));
        try {
             //FileWriter always assumes default encoding is OK!
             prjOutput.write( _prjString );
        }
        catch (IOException ioe) {
            throw new IOException("Error writing PRJ file.", ioe);
        }
        finally {
            try {prjOutput.close();} catch (Exception e) { }
            prjOutput = null;
            prjFile = null;
        }
    }
    
    public DBaseWriter getDBaseWriter() {
        return this.dbaseWriter;
    }
    
    public void setXBaseType(DBFTypes _flavour) {
        this.xBaseType = _flavour;
    }

    public void setXBaseType(String _xType) {
      if (Strings.isEmpty(_xType) )
          return;
      try {
          this.xBaseType = DBFTypes.valueOf(_xType); 
      } catch (Exception e) {
          this.xBaseType = DBFTypes.DBASEIII;
      }
    }
    
    public DBFTypes getXBaseType() {
        return this.xBaseType;
    }
    
    public void setPrjContents(String _prjString) {
        this.prjContents = _prjString;
    }

    public String getPrjContents() {
        return this.prjContents;
    }
    
    protected void add(STRUCT _shape) 
    {
        this.geom = SDO.Struct2Geometry(this.geomConverter, 
                                                 this.geomFactory,
                                                 _shape);
    }
    
    protected void addToGeomSet(STRUCT _shape) 
    {
        Geometry geom = SDO.Struct2Geometry(this.geomConverter, 
                                                     this.geomFactory,
                                                     _shape);
        if ( geom == null ) {
          this.geomSet.add((Geometry)null);
        } else {
          this.geomSet.add(geom);
        }
    }
    
    protected void writeGeomSet() 
    throws IOException 
    {
        // Write the collection
        //
        this.shpWriter.write(this.geomSet);
        this.geomSet = new LinkedHashSet<Geometry>(this.getCommit());
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
        return this.dbaseWriter.isSupportedType(columnType,columnTypeName);
    }
    
    public static boolean getDbaseNullWriteString() {
        return true;  // Write NULL values 
    }
        
}
