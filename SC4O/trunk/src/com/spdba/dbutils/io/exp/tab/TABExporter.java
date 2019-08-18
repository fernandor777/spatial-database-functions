package com.spdba.dbutils.io.exp.tab;

import com.spdba.dbutils.Constants;
import com.spdba.dbutils.spatial.Renderer.GEO_RENDERER_FORMAT;
import com.spdba.dbutils.spatial.SDO.POLYGON_RING_ORIENTATION;
import com.spdba.dbutils.io.GeometryProperties;
import com.spdba.dbutils.io.exp.IExporter;
import com.spdba.dbutils.io.exp.shp.SHPExporter;
import com.spdba.dbutils.io.exp.xbase.DBaseWriter;
import com.spdba.dbutils.spatial.Envelope;
import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.sql.OraRowSetMetaDataImpl;

import com.spdba.dbutils.sql.SQLConversionTools;
import com.spdba.dbutils.tools.FileUtils;

import com.spdba.dbutils.tools.Strings;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;

import java.io.Writer;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;

import java.util.Iterator;
import java.util.LinkedHashMap;

import java.util.prefs.Preferences;

import javax.sql.RowSetMetaData;

import org.geotools.data.shapefile.shp.ShapeType;

import org.xBaseJ.micro.DBF;
import org.xBaseJ.micro.fields.Field;

public class TABExporter 
    extends SHPExporter 
{

    private String      coordSysString = null;
    private String symbolisationString = null;
    
    public TABExporter (Connection               _conn,
                        String                   _fileName,
                        int                      _shapeCount,
                        POLYGON_RING_ORIENTATION _polygonOrientation,
                        int                      _decimalDigitsOfPrecision) 
    {
        super(_conn,
              _fileName,
              _shapeCount,
              _polygonOrientation,
              _decimalDigitsOfPrecision
             );
    }

    @Override
    public String getFileExtension() {
        return "tab";
    }

    public void setCoordSysString(String coordSysString) {
        this.coordSysString = coordSysString;
    }

    public String getCoordSysString() {
        return coordSysString;
    }

    public void setSymbolisationString(String symbolisationString) {
        this.symbolisationString = symbolisationString;
    }

    public String getSymbolisationString() {
        return symbolisationString;
    }
    
    @Override
    public void end() throws IOException {
        
        try {
            // make sure to write the last Geometry set feature...
            //
            if ( super.geomSet.size() > 0 ) {
                super.writeGeomSet();
            }

            String directoryName = FileUtils.getDirectory(super.getFileName());
            String fileName = FileUtils.getFileNameFromPath(super.getFileName(), true);

            String tabContents = createTabString(super.dbaseWriter,
                                                 fileName  + ".dbf",
                                                 getCoordSysString(), 
                                                 getSymbolisationString(),
                                                 super.getShapefileType(),
                                                 fileExtent
                                                 );
            writeTabFile(FileUtils.FileNameBuilder(directoryName, 
                                                   fileName, 
                                                   "tab"),
                         tabContents);
        } catch (Exception e) {
            throw new IOException("Failed to create TAB file wrapper over SHP file (" + e.getMessage() + ")");
        }
    }

    /**
     * writeTabFile() 
     * @description Writes actual TAB file 
     * @param _fullyQualifiedFileName - filename including directory path and extension. 
     * @param _tabString - Actual string containing TAB file's contents.
     * @throws FileNotFoundException - if there is an error creating the file.
     * @throws IOException  - if there is an error writing to the file.
     */
    protected static void writeTabFile(String _fullyQualifiedFileName,
                                       String _tabString ) 
    throws FileNotFoundException, 
           IOException 
    {
        File tabFile;
        tabFile = new File(_fullyQualifiedFileName);
        Writer tabOutput = new BufferedWriter(new FileWriter(tabFile));
        try {
             //FileWriter always assumes default encoding is OK!
             tabOutput.write( _tabString );
        }
        catch (IOException ioe) {
            tabOutput.close();
            tabOutput = null;
            throw new RuntimeException("Error writing TAB file.", ioe);
        }
        finally {
             tabOutput.close();
             tabOutput = null;
         }
    }

    @Override
    public void close() {
        // TODO Implement this method
    }

    /**
    * @name   createTabString() 
    * @description Creates the contents of a TAB file that can "wrap" a shapefile allowing it to be used with MapInfo
    * @param header the result set, including a geometry column.
    * @param coordSys - A MapInfo CoordSys string. 
    * @param shpEnvelope - An envelope or MBR covering all the shapes in the shapefile.
    * @return String that is the contents of the TAB file.
    * @throws SQLException if there is an error reading the result set metadata.
    */
    protected static String createTabString(DBaseWriter dbaseWriter,
                                            String      dbfFileName,
                                            String      coordSys,
                                            String      symbolisationString,
                                            ShapeType   sType,
                                            Envelope    shpEnvelope) 
    throws Exception {
        Envelope localEnv = shpEnvelope;
        if ( localEnv != null && ! localEnv.isNull() ) {
            // Should one do this for "CoordSys Earth Projection" ie Lat/Long?
            if ( localEnv.getMinX() == localEnv.getMaxX() && 
                 localEnv.getMinY() == localEnv.getMaxY() ) {
                // expand this baby...
                localEnv.increaseByPercent( 10 ); // ie 10% eg 10m / 10 = 1; 1 degree / 10 = 1.1 degree
            }
            /* Check if supplied CoordSys already has Bounds() element. 
             * If so, remove it before adding in shapefile's actual bounds */
            if (coordSys.indexOf("Bound") > 0)
                coordSys = coordSys.substring(0,coordSys.indexOf("Bound")-1);
            /* Add computed Bounds to coordSys string */
            coordSys += " Bounds (" + 
                        localEnv.getMinX() + "," + localEnv.getMinY() +
                        ") (" + 
                        localEnv.getMaxX() + "," + localEnv.getMaxY() + 
                        ")";
        }
        String mapInfoTabdbaseWriter = "!table\n" + 
        "!version 700\n" + 
        "!charset WindowsLatin1\n" + 
        "\n" + 
        "Definition Table\n" + 
        "  File \"" + dbfFileName + "\"\n" +
        "  Type SHAPEFILE Charset \"WindowsLatin1\"\n  Fields ";
        String mapInfoTabContents = "";
        String mapInfoTabFooter = "begin_metadata\n" + 
        "\"\\IsReadOnly\" = \"FALSE\"\n" + 
        "\"\\Shapefile\" = \"\"\n" + 
        "\"\\Shapefile\\PersistentCache\" = \"FALSE\"\n" + 
        "\"\\Spatial Reference\" = \"\"\n" + 
        "\"\\Spatial Reference\\Geographic\" = \"\"\n" + 
        "\"\\Spatial Reference\\Geographic\\Projection\" = \"\"\n" + 
        "\"\\Spatial Reference\\Geographic\\Projection\\Clause\" = \"" + coordSys + "\"\n";
        
        /** The following needs to be improved via parameterization */
        if ( !Strings.isEmpty(symbolisationString) ) {
            mapInfoTabFooter += symbolisationString;
        } else {
            mapInfoTabFooter += "\"\\DefaultStyles\" = \"\"\n" ;
            if (sType.isPointType() || 
                sType.isMultiPointType()) {
                mapInfoTabFooter += 
                "\"\\DefaultStyles\\Symbol\" = \"\"\n" + 
                "\"\\DefaultStyles\\Symbol\\Type\" = \"0\"\n" + 
                "\"\\DefaultStyles\\Symbol\\Pointsize\" = \"12\"\n" + 
                "\"\\DefaultStyles\\Symbol\\Color\" = \"0\"\n" + 
                "\"\\DefaultStyles\\Symbol\\Code\" = \"35\"\n";
            } else {
                /* must be lines and polygons.
                 * only brush polygons */
                if ( sType.isPolygonType() ) {
                    mapInfoTabFooter += 
                    "\"\\DefaultStyles\\Brush\" = \"\"\n" + 
                    "\"\\DefaultStyles\\Brush\\Pattern\" = \"2\"\n" + 
                    "\"\\DefaultStyles\\Brush\\Forecolor\" = \"16777215\"\n" + 
                    "\"\\DefaultStyles\\Brush\\Backcolor\" = \"16777215\"\n" ;
                }
                /* But add line style to both polygons and lines */
                mapInfoTabFooter += 
                    "\"\\DefaultStyles\\Pen\" = \"\"\n" + 
                    "\"\\DefaultStyles\\Pen\\LineWidth\" = \"1\"\n" + 
                    "\"\\DefaultStyles\\Pen\\LineStyle\" = \"0\"\n" + 
                    "\"\\DefaultStyles\\Pen\\Color\" = \"0\"\n" + 
                    "\"\\DefaultStyles\\Pen\\Pattern\" = \"2\"\n";
            }
        }
        
        mapInfoTabFooter += "end_metadata";
        
        Iterator<String> iter = dbaseWriter.fields.keySet().iterator();
        while (iter.hasNext() ) {
            Field f = dbaseWriter.getField(iter.next());
            // write the field name
            int tabPrecision = 0;
            try {
                mapInfoTabContents += "\t" + f.getName();
                for (int j = 1; j < 10 - f.getName().length(); j++)
                    mapInfoTabContents += " ";
                mapInfoTabContents += "\t";
                switch (f.getType()) {
                    case 'C' : mapInfoTabContents += "Char (" + f.getLength() + ")"; break;
                    case 'F' : mapInfoTabContents += "Float"; break;
                    /*case 'N' : mapInfoTabContents += "Decimal (" + dbaseWriter.getFieldLength(i) + "," + dbaseWriter.getFieldDecimalCount(i) + ")";*/
                    case 'N' : 
                       /** A dbase column is defined N n m but MapInfo's TAB file wrapper
                        *  wants n + m + 1. So, N 3 2 becomes Decimal (6,2).
                        */
                       tabPrecision = ( f.getDecimalPositionCount() == 0 ) ? 
                                        f.getLength() : 
                                        f.getLength() + 1 + f.getDecimalPositionCount();
                       /** Need to check resultant precision to see if need to upscale N data type to Float
                        **/
                      if ( tabPrecision > DBaseWriter.MAX_NUMERIC_LENGTH )
                           mapInfoTabContents += "Float";
                      else
                           mapInfoTabContents += "Decimal (" +  tabPrecision + "," + f.getDecimalPositionCount() + ")"; 
                      break;
                    case 'D' : mapInfoTabContents += "Date";
                }
                mapInfoTabContents += " ;\n";
            }
            catch (Exception e) {
                throw new RuntimeException("Error constructing Tab file string", e);
            }
        }
        return mapInfoTabdbaseWriter + String.valueOf(dbaseWriter.fields.size()) + "\n" + 
               mapInfoTabContents + 
               mapInfoTabFooter;
    }

    @Override
    public String getTextDelimiter() {
        return null;
    }

    @Override
    public String getFieldSeparator() {
        return null;
    }

}