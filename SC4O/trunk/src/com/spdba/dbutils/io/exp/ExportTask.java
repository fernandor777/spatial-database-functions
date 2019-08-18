package com.spdba.dbutils.io.exp;

import com.spdba.dbutils.Constants;
import com.spdba.dbutils.io.GeometryProperties;
import com.spdba.dbutils.io.exp.gml.GMLExporter;
import com.spdba.dbutils.io.exp.shp.SHPExporter;
import com.spdba.dbutils.io.exp.tab.TABExporter;
import com.spdba.dbutils.io.exp.xbase.DBaseWriter;
import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.sql.DBConnection;
import com.spdba.dbutils.sql.OraRowSetMetaDataImpl;
import com.spdba.dbutils.sql.SQLConversionTools;
import com.spdba.dbutils.tools.Strings;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;

import java.sql.SQLException;

import java.text.SimpleDateFormat;

import java.util.LinkedHashMap;
import java.util.logging.Logger;

import javax.sql.RowSetMetaData;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleResultSetMetaData;
import oracle.jdbc.OracleTypes;

import oracle.sql.STRUCT;

import org.geotools.data.shapefile.shp.ShapeType;
import org.geotools.util.logging.Logging;

public class ExportTask {
    
    private static final Logger LOGGER = Logging.getLogger("com.spdba.export.io.export.ExportTask");

    private OracleConnection                            conn = null;
    private OracleResultSet                        resultSet = null;
    private OracleResultSetMetaData                     meta = null;
    private LinkedHashMap<Integer,RowSetMetaData> resultMeta = null;
    private int                               geoColumnIndex = -1;
    private String                             geoColumnName = "GEOM";
    private int                                totalRowCount = 0;
    private IExporter                            geoExporter = null;
    
    public ExportTask(IExporter _exporter) 
    throws Exception 
    {
        if ( _exporter == null ) {
            throw new Exception("No Exporter Object provided");
        }
        this.geoExporter = _exporter;
        this.conn = (OracleConnection)this.geoExporter.getConnection();
        if (this.conn == null )  {
            throw new Exception ("Export Task must be provided with a valid Oracle Connection via Exporter Object.");
        }
        this.resultSet = (OracleResultSet)this.geoExporter.getResultSet();
        if (this.resultSet == null )  {
            throw new Exception ("Export Task must be provided with a valid result set via Exporter Object.");
        }
    }
    
    public void Export() 
    {
        try 
        {
            if ( this.conn == null && geoExporter.getConnection()==null ) {
                this.conn = DBConnection.getConnection();
            }
            this.resultSet.setFetchDirection(OracleResultSet.FETCH_FORWARD);
            this.resultSet.setFetchSize(getFetchSize());
            this.meta           = (OracleResultSetMetaData)this.resultSet.getMetaData();           
            this.geoColumnIndex = geoExporter.getGeoColumnIndex();
            this.geoColumnName  = geoExporter.getGeoColumnName();
            this.resultMeta     = SQLConversionTools.getExportMetadata(this.meta);
            geoExporter.setExportMetadata(this.resultMeta);

            // Extract geometry metadata from first SDO_GEOMETRY structure in resultSet
            if ( this.resultSet.next()==false ) {
                throw new Exception ("Empty resultset: ");
            }
            STRUCT geoStruct = null;
            if ( this.meta.getColumnTypeName(geoExporter.getGeoColumnIndex()).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY) ) {
                geoStruct = (oracle.sql.STRUCT)this.resultSet.getOracleObject(geoExporter.getGeoColumnName());
            } else {
                // This should not happen as calling class checks provided geoColumnName and Index
                throw new Exception("Spatial Column " + geoExporter.getGeoColumnName() + " is not of type SDO_GEOMETRY (" + this.meta.getColumnTypeName(geoExporter.getGeoColumnIndex()) + ")");
            }
            geoExporter.setGeometryProperties(SDO.getGeometryProperties(geoStruct));
            OraRowSetMetaDataImpl rsMD = new OraRowSetMetaDataImpl();
            
            geoExporter.start(DBConnection.getCharacterSet(conn));
            do 
            {
                geoExporter.startRow();  // writes recordIdentifier if needed
                this.totalRowCount += 1;
                
                // Process geometry first to see if we can skip the whole row.
                //
                if (this.geoColumnIndex > 0 
                    &&
                    //geoExporter instanceof XSVExporter ||
                    //geoExporter instanceof DBFExporter ||
                    geoExporter instanceof GMLExporter ||
                    geoExporter instanceof SHPExporter ||
                    geoExporter instanceof TABExporter ) 
                {
                    try 
                    {
                        geoStruct = (oracle.sql.STRUCT)this.resultSet.getOracleObject(geoExporter.getGeoColumnName());
                        if ( this.resultSet.wasNull() || geoStruct == null ) {
                            if ( geoExporter.skipNullGeometry() ) {
                                continue;
                            } 
                        }
                        // Now write object to SHP File
                        // Data Type already validated.
                        //
                        rsMD = (OraRowSetMetaDataImpl)this.resultMeta.get(geoExporter.getGeoColumnIndex());
                        rsMD.setCatalogName(1,geoExporter.getGeoColumnName());
                        geoExporter.printColumn(geoStruct,rsMD);
                        geoExporter.updateExtent(SDO.getGeoMBR(geoStruct));
                    }
                    catch (SQLException sqle) {
                        LOGGER.warning(sqle.getLocalizedMessage());
                        continue;
                    }
                } 

                // If no attributes, recordIdentifier should be written
                if ( geoExporter.generateIdentifier() ) {
                    geoExporter.printColumn(
                         /* String _object         */ String.valueOf(this.totalRowCount),
                         /* String _columnName     */ geoExporter.getRecordIdentifier(),
                         /* String _columnTypeName */ ""
                    );
                } 
                
                // Now iterate over columns and export values
                //
                Object oracleObject = null;
                for (int col = 1; col <= this.meta.getColumnCount(); col++) 
                {
                    try 
                    {
                        rsMD = (OraRowSetMetaDataImpl)this.resultMeta.get(col);
                        if (rsMD.getColumnName(1).equalsIgnoreCase(geoExporter.getGeoColumnName()) )  {
                            // Already processed
                            continue;
                        }
                        
                        if ( geoExporter.isSupportedType(rsMD.getColumnType(1),
                                                         rsMD.getColumnTypeName(1)) ) 
                        {
                            oracleObject = this.resultSet.getObject(col);
                            geoExporter.printColumn(oracleObject,rsMD);
                        } else {
                            if ( geoExporter.getRowCount() == 0 ) {
                                LOGGER.severe("ExporterWriter.run(): Column " + rsMD.getColumnName(1) + " of type " + rsMD.getColumnTypeName(1) + " is not supported");
                            }
                        }
                    } catch (SQLException e) {
                      LOGGER.severe("ExporterWriter.run(): Error converting column/type " + rsMD.getColumnName(1) + "/" + rsMD.getColumnType(1));                      
                    }
                }
                // Write everything
                geoExporter.endRow();
            } while (this.resultSet.next());
            
        } catch (IOException ioe) {
            ioe.printStackTrace();
            LOGGER.severe("ExportTask: File Error: " + ioe.getMessage());
        } catch (SQLException sqle) {
            sqle.printStackTrace();
            LOGGER.severe("ExportTask: SQL Error\n"+sqle.getMessage());
        } catch (NullPointerException npe) {
            npe.printStackTrace();
            LOGGER.severe("ExportTask: Null pointer exception occurred "+ npe.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            LOGGER.severe("ExportTask: Error exporting " + geoExporter.getExportType().toString() + " (" + e.getMessage() +")");
        } finally {
            try { 
                if (this.resultSet!=null ) {
                    this.resultSet.close(); 
                }
            } catch (Exception _e) { }
            try {
                geoExporter.end();
                geoExporter.close();
            } catch (IOException e) { 
            }
        }
    }

    private void cancel() {
    }
    
    public int getTotalRows() {
      return this.totalRowCount;
    }

    private void setTotalRows(int _rowCount) {
        this.totalRowCount = _rowCount;
    }

    private int getFetchSize() {
        return 100;
    }
            
    protected void done() {
    }

    private String getSRID() {
        return null;
    }

}
