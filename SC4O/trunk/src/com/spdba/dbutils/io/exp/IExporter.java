package com.spdba.dbutils.io.exp;

import com.spdba.dbutils.Constants;
import com.spdba.dbutils.io.IOConstants.EXPORT_TYPE;
import com.spdba.dbutils.spatial.Renderer.GEO_RENDERER_FORMAT;
import com.spdba.dbutils.spatial.SDO.POLYGON_RING_ORIENTATION;
import com.spdba.dbutils.Constants.XMLAttributeFlavour;
import com.spdba.dbutils.io.GeometryProperties;
import com.spdba.dbutils.spatial.Envelope;
import com.spdba.dbutils.sql.OraRowSetMetaDataImpl;

import java.io.IOException;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.LinkedHashMap;

import javax.sql.RowSetMetaData;

import org.geotools.data.shapefile.shp.ShapeType;

public interface IExporter {

    public Connection                                      conn = null;
    public ResultSet                                  resultSet = null;
    public String                                      baseName = "";
    public int                                              row = 1;
    public int                                        totalRows = 0;
    public XMLAttributeFlavour                                XMLFlavour = Constants.XMLAttributeFlavour.OGR;
    public GEO_RENDERER_FORMAT                  geoRenderFormat = GEO_RENDERER_FORMAT.WKT;
    public POLYGON_RING_ORIENTATION             polyOrientation = POLYGON_RING_ORIENTATION.ORACLE;
    public LinkedHashMap<Integer,RowSetMetaData> exportMetadata = null;
    public String                                 geoColumnName = "";
    public int                                   geoColumnIndex = -1;
    public GeometryProperties                geometryProperties = null;
    public int                                           commit = 100;
    public Envelope                                  fileExtent = null;
    public boolean                             skipNullGeometry = true;
    public int                                   precisionScale =  7;
    public String                              recordIdentifier = null;
    
    public void setConnection(Connection _conn);
    public Connection getConnection();

    public void setResultSet(ResultSet _rSet);
    public ResultSet getResultSet();
    
    public EXPORT_TYPE getExportType(); 

    public String getFileName();
    public   void setFileName(String _fileName);
    public   void setBaseName(String _baseName);
    public String getBaseName();
    public String getFileExtension();

    public void setPolygonOrientation(POLYGON_RING_ORIENTATION _polyOrientation);
    public POLYGON_RING_ORIENTATION getPolygonOrientation();

    public void setXMLFlavour(String _flavour);
    public void setXMLFlavour(Constants.XMLAttributeFlavour _flavour);
    public Constants.XMLAttributeFlavour getXMLFlavour();
    
    public void setShapefileType(ShapeType _shapeType) ;
    public ShapeType getShapefileType();

    public void setGeometryFormat(String _renderFormat) ;
    public GEO_RENDERER_FORMAT getGeometryFormat();
    
    public boolean hasAttributes() ;
    public    void setTotalRows(int _totalRows);
    public     int getTotalRows();
    public     int getRowCount();

    public String getFieldSeparator();
    public String getTextDelimiter();
    public void setCommit(int _commit);
    public int getCommit();

    public void setPrecisionScale(int _precisionScale);
    public int getPrecisionScale();
    
    public void setGeoColumnIndex(int _geoColumnIndex);
    public int getGeoColumnIndex();
    public void setGeoColumnName(String _geoColumnName);
    public String getGeoColumnName();

    public boolean isSupportedType(int    columnType,
                                   String columnTypeName);
    
    public boolean generateIdentifier();
    public void setRecordIdentifier(String _recordIdentifier);
    public String getRecordIdentifier();
    
    public Envelope getExtent();
    public     void setExtent(Envelope _extent);
    public     void updateExtent(Envelope _e);

    public boolean skipNullGeometry() ;
    public void setSkipNullGeometry(boolean _skip);

    public GeometryProperties getGeometryProperties();
    
    public void setGeometryProperties(GeometryProperties _geometryProperties);

    public LinkedHashMap<Integer, RowSetMetaData> getExportMetadata();
    
    public void setExportMetadata(LinkedHashMap<Integer, RowSetMetaData> _exportMetadata);

    public void start(String _encoding) throws Exception;

    public void startRow() throws IOException;

    public void printColumn(Object _object, OraRowSetMetaDataImpl _columnMetaData)    throws SQLException;
    
    public void printColumn(String _object,String _columnName,String _columnTypeName) throws SQLException;

    public void endRow() throws IOException;

    public void end() throws IOException;
    
    public void close();
    
}
