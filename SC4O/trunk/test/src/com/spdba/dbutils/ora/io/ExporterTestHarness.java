package com.spdba.dbutils.ora.io;

import com.spdba.dbutils.Constants;
import com.spdba.dbutils.io.exp.csv.WriteDelimitedFile;
import com.spdba.dbutils.io.exp.geojson.WriteGeoJSONFile;
import com.spdba.dbutils.io.exp.gml.WriteGMLFile;
import com.spdba.dbutils.io.exp.kml.WriteKMLFile;
import com.spdba.dbutils.io.exp.shp.WriteSHPFile;
import com.spdba.dbutils.io.exp.spreadsheet.WriteExcelFile;
import com.spdba.dbutils.io.exp.tab.WriteTABFile;
import com.spdba.dbutils.io.exp.xbase.WriteXBaseFile;
import com.spdba.dbutils.spatial.Renderer;
import com.spdba.dbutils.tools.FileUtils;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;

import java.nio.CharBuffer;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;

import oracle.jdbc.pool.OracleDataSource;

import oracle.sql.ARRAY;
import oracle.sql.Datum;
import oracle.sql.STRUCT;

import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryCollection;
import org.locationtech.jts.geom.LineSegment;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.MultiLineString;
import org.locationtech.jts.geom.MultiPolygon;
import org.locationtech.jts.geom.Polygon;
import org.locationtech.jts.io.oracle.OraReader;

import org.xBaseJ.micro.DBFTypes;
import org.xBaseJ.micro.xBaseJException; //Standard JDBC packages.

/**
 * Not so much a test case, more like a sample.
 * 
 */
public class ExporterTestHarness {

    public static void main() 
    {
        try {

            String sSQL = "";
            sSQL = "select ID,GROUNDHEIGHT,HEIGHT,POLEHEIGHT,WITHINSANDFLYLOS,NAME,0 as open," +
                          "rownum || ' Cliff View Drive, Allens Rivulet, Tas, 7150' as address," +
                          "'0362396397' as phoneNumber, " +
                          "sdo_geometry(3001,28355,sdo_point_type(309783,52394856,78.345),null,null) as otherPoint," +
                          "sdo_cs.transform(a.GEOMETRY,8311) as geometry " +
                   " from codesys.house_locations a " +
                   "where rownum <= 100";
            String sAllTypesSQL = 
                "select rowid, short_col, geom, int_col," +
                       "num021_col,num042_col,num063_col,num084_col,num106_col,num128_col,num1810_col,num2012_col, num1_col," +
                       "num2_col, num3_col, num4_col, num5_col, num6_col, num7_col, num8_col, num9_col, num10_col, real_col, real2_col, double_col,  float_col,  bigdecimal_col, " +
                       "string_col, bigstr_col, nstr_col, charstream_col, " +
                       "bytes_col, binarystream_col, " +
                       "date_col, timestamp_col, " +
                       "clob_col, blob_col, bfile_col, array_col, object_col " +
                  "from oracle_all_types";

            String projPoint2DSQL = "select id,label,symbolsize,angledegrees,geom from codesys.projpoint2d order by id";
            
            char testType = 'K';
            switch (testType) {
            case 'C' :  CSV(sAllTypesSQL, WriteDelimitedFile.WKT_FORMAT,"oracle_all_types");
                        CSV("select rowid, geometry from gis.coupe_p where oid < 1000", WriteDelimitedFile.GML_FORMAT, "coupe_p");
                        CSV("select id,geom from codesys.projpoint3d",WriteDelimitedFile.WKT_FORMAT,"wktpoint3d");
                        CSV("select id,geom from codesys.projpoint3d",WriteDelimitedFile.GML_FORMAT,"gmlpoint3d");
                        CSV("select sdo_geometry(3003,null,null,sdo_elem_info_array(1,1003,1),sdo_ordinate_array(50,105,1,55,105,2,60,110,3,50,110,4,50,105,5)) as geom from dual",WriteDelimitedFile.GML_FORMAT,"gmlpoly3d");
                        CSV("select sdo_geometry(3003,null,null,sdo_elem_info_array(1,1003,1),sdo_ordinate_array(50,105,1,55,105,2,60,110,3,50,110,4,50,105,5)) as geom from dual",WriteDelimitedFile.WKT_FORMAT,"wktpoly3d");
                        CSV("select sdo_geometry(3007,null,null,sdo_elem_info_array(1,1003,1,16,2003,1),sdo_ordinate_array(50,105,1,55,105,2,60,110,3,50,110,4,50,105,5,51,105,1,54,105,2,59,110,3,51,110,4,51,105,5)) as geom from dual",WriteDelimitedFile.GML_FORMAT,"gmlpolyh3d");
                        CSV("select sdo_geometry(3007,null,null,sdo_elem_info_array(1,1003,1,16,2003,1),sdo_ordinate_array(50,105,1,55,105,2,60,110,3,50,110,4,50,105,5,51,105,1,54,105,2,59,110,3,51,110,4,51,105,5)) as geom from dual",WriteDelimitedFile.WKT_FORMAT,"wktpolyh3d");
                        break;
            case 'D' : dimarray();            break;
            case 'E' : Excel(sAllTypesSQL,"c:\\temp","oracle_all_types","first",WriteExcelFile.NONE,WriteExcelFile.getGeometryFormat().KML.toString());
                        sSQL = "SELECT FID,CODESYS.LINEAR.ST_Start_Point(a.GEOM) as geom_p FROM book.road_clines a where rownum < 1000 order by FID"; // 65535";
                        Excel(sSQL,"c:\\temp","geometry","first",WriteExcelFile.HORIZONTAL,WriteExcelFile.getGeometryFormat().GML3.toString());
                        sSQL = "SELECT ";
                        for (int i = 0; i < (256 * 4); i++)
                            sSQL += (i == 0) ? "F," : "F AS " + "F" + String.valueOf(i) + 
                                                ( (i < (256*4)-1 ) ? "," : " FROM (SELECT FID AS F FROM book.road_clines WHERE ROWNUM < 100)");
                        Excel(sSQL,
                              "c:\\temp",
                              "stratify_vertically",
                              "first",
                              WriteExcelFile.VERTICAL,
                              WriteExcelFile.getGeometryFormat().KML.toString());
                        sSQL = "SELECT FID,ROAD_ID, LF_FADD || ' ' || STREETNAME || ', ' || NHOOD || ', ' || ZIP_CODE as address, CLASSCODE, GEOM FROM book.road_clines a where rownum < ROUND(65536 * 2.1) order by FID"; // 65535";
                        Excel(sSQL,
                              "c:\\temp",
                              "stratify_horizontally",
                              "first",
                              WriteExcelFile.HORIZONTAL,
                              WriteExcelFile.getGeometryFormat().KML.toString());
                        break;
            case 'G' : General();             break;
            case 'J' : GeoJSON();             break;
            case 'K' : KML();                 break;
            case 'M' : sSQL = "select sdo_cs.transform(sdo_geometry(3001,28355,sdo_point_type(309783,52394856,78.345),null,null),8311) as GEOM from dual";
                       sSQL = "select rownum || ' Cliff View Drive, Allens Rivulet, Tas, 7150' as address," +
                                     "sdo_cs.transform(sdo_geometry(3001,28355,sdo_point_type(309783,52394856,78.345),null,null),8311) as GEOM from dual";
                       GML(sSQL,"GEOM","houseLocationsFME.gml",Renderer.GEO_RENDERER_FORMAT.GML3.toString(),Constants.XMLAttributeFlavour.FME);
                       GML(sSQL,"GEOM","houseLocationsOGR.gml",Renderer.GEO_RENDERER_FORMAT.GML3.toString(),Constants.XMLAttributeFlavour.OGR);
                       GML(sSQL,"GEOM","houseLocationsGML.gml",Renderer.GEO_RENDERER_FORMAT.GML3.toString(),Constants.XMLAttributeFlavour.GML);
                       //GML(Renderer.GEO_RENDERER_FORMAT.GML2.toString());
                       break;
            case 'R' : dataTypeExamination(); break;
            case 'S' : shape();               break;
            case 'T' : TAB();                 break;
            case 'V' : Vectorize();           break;
            case 'X' : XBase(projPoint2DSQL,"Point",5,"c:\\temp","projpoint2d"); break;
            } 
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void FastExporter() 
    {
        System.out.println("FastExporter");
        try { 
            // connect to test database
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12", "codesys", "codemgr");
            Statement statement;
            statement = database.createStatement();
            ResultSet results = statement.executeQuery ("SELECT x || ',' || y || ',' || z as \"X,Y,Z\" FROM source_data WHERE x < 10");
            String outFile = "C:/temp/fastExporter.csv"; 
            String CharsetValue = "US-ASCII";
            FastExporter.write(results,outFile,CharsetValue);
            results.close();
            statement.close();
            database.close();
            
            Charset     charset = Charset.forName(CharsetValue);
            FileInputStream fis = new FileInputStream("C:/temp/fastExporter.csv");
            FileChannel      fc = fis.getChannel();
            System.out.println("File size : "+ fc.size());
            MappedByteBuffer in = fc.map(FileChannel.MapMode.READ_ONLY, 0, fc.size());
            CharsetDecoder decoder = charset.newDecoder();
            CharBuffer          cb = decoder.decode(in);
    System.out.println(cb.toString());
            int i = 0;
            while (i < fc.size()-1) // fc.size())
               System.out.print(in.get(i++));
            System.out.println(in.get(i++));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void General() {
        System.out.println(FileUtils.FileNameBuilder("c:\\temp", "myfile", "..shp"));
        System.out.println("POINT ".replaceAll(" ", "") + "ZM");
        String ext = "Only With Latest Full Version";
        //ext = Util.getxBaseJProperty("memoFileExtension");
        String coordinate = "(1212.1212,121212)".replaceAll("[(,)]", "");
        System.out.println(coordinate);
        String wkt = "LINESTRINGZ (0 0,1 1)";
        String wktTag = wkt.substring(0, wkt.indexOf("(") );
        System.out.println(wktTag + "*****");
    }
    	    
    public static void dataTypeExamination() 
    {
        try {
            // connect to test database
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:GISDB", "codesys", "codemgr");
            Statement statement;
            statement = database.createStatement();
            ResultSet results; 
            results = statement.executeQuery("select BDBL_COL,BFLOAT_COL from oracle_all_types");
            double dbl = -1;
            float flt = -1;
            while (results.next()) {
                ResultSetMetaData meta = results.getMetaData();
                for (int i=1; i<=meta.getColumnCount();i++) {
                    System.out.println(meta.getColumnName(i) + "/" + meta.getColumnLabel(i) + "," + meta.getColumnType(i) + "," + meta.getColumnTypeName(i));
                    if ( meta.getColumnTypeName(i).equalsIgnoreCase("BINARY_DOUBLE")) {
                        dbl = ((Double)results.getObject(i)).doubleValue();
                        System.out.println(dbl);
                    }
                  if ( meta.getColumnTypeName(i).equalsIgnoreCase("BINARY_FLOAT")) {
                      flt = ((Float)results.getObject(i)).floatValue();
                      System.out.println(flt);
                  }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
          
    public static void shape() 
    throws SQLException, 
           ClassNotFoundException, 
           IOException, 
           FileNotFoundException
    {
        try {
            String filename = "";
            // connect to test database
            Class.forName("oracle.jdbc.driver.OracleDriver");
            //Connection database = DriverManager.getConnection("jdbc:oracle:thin:@DELL:1521:XE", "gis", "gis");
            //Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","codesys","codemgr");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:GISDB","codesys","codemgr");

            String shapefiletype = "";
            String       gFormat = "";
            String     outputDir = "C:\\temp"; // ShapeFileWriter.DEFAULT_OUTPUT_DIRECTORY;
            String     prjString = "PROJCS[\"GDA_1994_MGA_Zone_54\",GEOGCS[\"GCS_GDA_1994\",DATUM[\"D_GDA_1994\",SPHEROID[\"GRS_1980\",6378137,298.257222101]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.017453292519943295]],PROJECTION[\"Transverse_Mercator\"],PARAMETER[\"False_Easting\",500000],PARAMETER[\"False_Northing\",10000000],PARAMETER[\"Central_Meridian\",141],PARAMETER[\"Scale_Factor\",0.9996],PARAMETER[\"Latitude_Of_Origin\",0],UNIT[\"Meter\",1]]";
            String           SQL = null;
            Statement statement;
            ResultSet results; 
            for (int i =-5;
                     i<= 0;
                     i++) 
            {
                gFormat = "WKT";
                switch (i) {
                
                   case -5 : gFormat="KML";         filename="GeoPoint3dKML"; shapefiletype="pointz"; SQL="select CAST(id as Integer) as fid, geom, CAST('Point' As VarChar2(10)) as PointType, geom as geom4KML from codesys.GeodPoint3D";  break; 
                   case -4 : gFormat="WKT";         filename="Point3dWKT";    shapefiletype="pointz"; SQL="select CAST(id as Integer) as fid, geom, CAST('Point' As VarChar2(10)) as PointType, geom as geom4WKT from codesys.ProjPoint3D";  break; 
                   case -3 : gFormat="EWKT";        filename="Point3dEWKT";   shapefiletype="pointz"; SQL="select CAST(id as Integer) as fid, geom, CAST('Point' As VarChar2(10)) as PointType, geom as geom4ekwt from codesys.ProjPoint3D";  break; 
                   case -2 : gFormat="GML3";        filename="Point3dGML3";   shapefiletype="pointz"; SQL="select CAST(id as Integer) as fid, geom, CAST('Point' As VarChar2(10)) as PointType, geom as geom4gml3 from codesys.ProjPoint3D";  break; 
                   case -1 : gFormat="KML2";        filename="GeoPoint3dKML2";shapefiletype="pointz"; SQL="select CAST(id as Integer) as fid, geom, CAST('Point' As VarChar2(10)) as PointType, geom as geom4KML from codesys.GeodPoint3D";  break; 
                   case 0  : gFormat="SDOGEOMETRY"; filename="Point3dSDO";    shapefiletype="pointz"; SQL="select CAST(id as Integer) as fid, geom, CAST('Point' As VarChar2(10)) as PointType, geom as geom4sdo from codesys.ProjPoint3D";  break; 
                
                   case 1  : filename="ProjLine3d";  shapefiletype="linestringz"; SQL = "select rownum as fid, codesys.GEOM.To_2D(geom) as geom, geom as geom3d, LineType from codesys.ProjLine3D a where linetype = 'VERTEX'";  break;
                             
                   case 2  : SQL = "select rownum as fid, geom, PolyType from codesys.ProjPoly3D where polytype = 'VERTEXNOHOLE'"; 
                             filename="ProjPoly3dNoHoles"; shapefiletype="polygonz"; break;
                   case 3  : SQL = "SELECT ROWNUM AS OID,SDO_GEOM.SDO_ARC_DENSIFY(SDO_GEOMETRY(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1005,2,1,2,1,5,2,2,11,2005,2,11,2,1,15,2,2),SDO_ORDINATE_ARRAY(6,10,10,1,14,10,10,14,6,10,13,10,10,2,7,10,10,13,13,10)),0.1,'arc_tolerance=0.1') as geom FROM DUAL";  filename="my_1005"; shapefiletype="polygon"; break;
                   case 4  : SQL = "select * from (select ROWNUM AS OID, sdo_geometry(2005,null,null,sdo_elem_info_array(1,1,2),sdo_ordinate_array(1,1,2,2)) as geom, 'X' as att from dual)";   filename="mpoint"; shapefiletype="multipoint"; break;
                   case 5  : SQL = "select ROWNUM AS OID, sdo_geometry(2003,null,null,sdo_elem_info_array(1,1003,1),sdo_ordinate_array(50,105,55,105,60,110,50,110,50,105)) as geom,'Polygon' as shptype from dual";  filename="spoly"; shapefiletype="polygon"; break;
                   case 6  : SQL = "select ROWNUM AS OID, sdo_geometry(2003,null,null,sdo_elem_info_array(1,1003,1,11,2003,3),sdo_ordinate_array(50,105,55,105,60,110,50,110,50,105,52,106,54,108)) as geom,CAST('Polygon with hole' as varchar(50)) as shpDescptn from dual";  filename="hpoly"; shapefiletype="polygon";  break;
                   case 7  : SQL = "select ROWNUM AS OID, sdo_geometry(2007,null,null,sdo_elem_info_array(1,1003,1,11,1003,1),sdo_ordinate_array(50,105,55,105,60,110,50,110,50,105,62,108,65,108,65,112,62,112,62,108)) as geom,'Multipolygon - disjoint' as shptype from dual";  filename="mpoly"; shapefiletype="multipolygon"; break;
                   case 8  : SQL = "select * from (select ROWNUM AS OID, sdo_geometry(2006,null,null,sdo_elem_info_array(1,2,1,5,2,1),sdo_ordinate_array(1,1,2,2,10,10,20,20)) as geom,'X' as att from dual)"; filename="mlinedual"; shapefiletype="multilinestring";  break;
                   case 9  : SQL = "select * from (select ROWNUM AS OID, sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,2,2)) as geom, 'X' as att, SYSDATE as createdate, rowid as rid, cast(1000 as Integer) as i, cast(11111 as Number(5)) as n5, cast(1234 as SMALLINT) as si, CAST(1234.235 as NUMBER(8,3)) as n83 from dual)"; filename="linedual"; shapefiletype="linestring";  break;
                   case 10 : SQL = "select CAST(ROWNUM AS Number(10)) as OID, GEOM from CODESYS.LOCALLINE2D"; filename="localline2d"; shapefiletype="linestring"; break;
                   case 11 : SQL = "select geom, " +
                                          "geom_p," +
                                          "short_col, int_col,num021_col,num042_col,num063_col,num084_col,num106_col,num128_col,num1810_col,num2012_col, num1_col, num2_col, num3_col, num4_col, num5_col, num6_col, num7_col, num8_col, num9_col, num10_col, " +
                                          "real_col, real2_col, double_col,float_col, bigdecimal_col, date_col, timestamp_col, " +
                                          "string_col, bigstr_col, nstr_col, TO_CLOB(bigstr_col) as clob_col, blob_col," +
                                          "charstream_col, bytes_col, binarystream_col, bfile_col, array_col, object_col " +
                                    " from oracle_all_types"; 
                             filename="Oracle_All_Types"; shapefiletype="polygon";  break;
                   case 12 : SQL = "select * from BOOK.BASE_ADDRESSES"; filename="BASE_ADDRESSES"; shapefiletype="point";  break;
                   case 13 : SQL = "select * from BOOK.LAND_PARCELS";   filename="LAND_PARCELS";   shapefiletype="polygon";  break;
                   case 14 : SQL = "select CAST(10 as Number(10)) as featureid, sdo_geometry(2001,28355,sdo_point_type(309783,52394856,null),null,null) as GEOM FROM dual CONNECT BY LEVEL < 1000"; 
                                   filename="rid_test"; 
                                   shapefiletype="point";
                             break;
                   case 15 : SQL  = "SELECT CAST(rownum AS INTEGER) as FID,\n" + 
                              "             CHR(dbms_random.value(65,90)) || to_char(round(dbms_random.value(0,1000),0),'FM9999') as label,\n" + 
                              "             ROUND(dbms_random.value(0,359.9),1) as angleDegs,\n" + 
                              "             mdsys.sdo_geometry(2001,NULL,\n" + 
                              "                   MDSYS.SDO_POINT_TYPE(\n" + 
                              "                         ROUND(dbms_random.value(358880  - ( 10000 / 2 ),  \n" + 
                              "                                                 358880  + ( 10000 / 2 )),2),\n" + 
                              "                         ROUND(dbms_random.value(5407473 - (  5000 / 2 ), \n" + 
                              "                                                 5407473 + (  5000 / 2 )),2),\n" + 
                              "                         NULL),\n" + 
                              "                   NULL,NULL) as GEOM\n" + 
                              "       FROM DUAL\n" + 
                              "     CONNECT BY LEVEL <= 500"; 
                              filename="random_test"; shapefiletype="point";
                              break; 
                }
                System.out.println("Testing (" + i + ") = " +SQL);
                statement = database.createStatement();
                results = statement.executeQuery(SQL);   
                WriteSHPFile.write (
                    /* java.sql.ResultSet _resultSet                */ results, 
                    /* java.lang.String   _outputDirectory          */ outputDir, 
                    /* java.lang.String   _fileName                 */ filename, 
                    /* java.lang.String   _shapeType                */ shapefiletype,
                    /* java.lang.String   _geometryName             */ "GEOM", 
                    /* java.lang.String   _polygonOrientation       */ "INVERTED",
                    /* java.lang.String   _dbaseType                */ (filename.equalsIgnoreCase("Oracle_All_Types") ? "DBASEIII_WITH_MEMO" : "BASE"),
                    /* java.lang.String   _geomRenderFormat         */ gFormat, 
                    /* java.lang.String   _prjString                */ prjString,
                    /* int                _decimalDigitsOfPrecision */ 3,
                    /* int                _commit                   */ 1000
                ) ;
                results.close();
                statement.close();
            }
            database.close();
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void TAB() throws SQLException, ClassNotFoundException, IOException, FileNotFoundException
    {
        try {
            String filename = "";
            // connect to test database
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","codesys","codemgr");
          //Connection database = DriverManager.getConnection("jdbc:oracle:thin:@DELL:1521:XE", "gis", "gis");

            Statement statement;
            statement = database.createStatement();
            ResultSet results; 
            String outputDir = "C:\\temp"; // ShapeFileWriter.DEFAULT_OUTPUT_DIRECTORY;
            filename="all_types"; 
            String shapefiletype = "";
            shapefiletype="point"; 
            String coordSysString = "CoordSys Earth Projection 8, 33, \"\"m\"\", 153, 0, 0.9996, 500000, 10000000  Bounds (9999,9999) (-9999,-9999)";
            // coordsys="CoordSys NonEarth Units \"\"m\"\"";
            // 3D
            results = statement.executeQuery("select id as fid, geom, CAST('Point' As VarChar2(5)) as PointType from codesys.ProjPoint3D"); filename="Point3d"; shapefiletype="pointz";

            // test as application
            WriteTABFile.write(
            /* java.sql.ResultSet _resultSet                */ results, 
            /* java.lang.String   _outputDirectory          */ outputDir, 
            /* java.lang.String   _fileName                 */ filename, 
            /* java.lang.String   _shapeType                */ shapefiletype,
            /* java.lang.String   _geometryName             */ "GEOM", 
            /* java.lang.String   _polygonOrientation       */ "INVERTED",
            /* java.lang.String   _dbaseType                */ "DBASEIII",
            /* java.lang.String   _geomRenderFormat         */ "WKT",
            /* java.lang.String   _prjString                */ coordSysString,
            /* java.lang.String   _symbolisationString      */ null,
            /* int                _decimalDigitsOfPrecision */ 3,
            /* int                _commit                   */ 100
            );         

            results.close();
            statement.close();
            database.close();
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static int getSegCount(MultiLineString geom) {
        int numSegments = 0;
        for (int s = 0; s < geom.getNumGeometries(); s++)
            numSegments += ((LineString) geom.getGeometryN(s)).getNumPoints() - 1;
        return numSegments;
    }

    private static int getSegCount(Polygon geom) {
        int numSegments = geom.getExteriorRing().getNumPoints() - 1;
        for (int s = 0; s < geom.getNumInteriorRing(); s++)
            numSegments += ((LineString) geom.getInteriorRingN(s)).getNumPoints() - 1;
        return numSegments;
    }

    private static LineSegment[] getSegments(Polygon pGeom) {
        int numSegments = getSegCount(pGeom);
        LineSegment[] segs = new LineSegment[numSegments];

        int segCount = 0;
        // Process outer ring
        LineString ring = pGeom.getExteriorRing();
        for (int i = 0; i < ring.getNumPoints() - 1; i++, segCount++)
            segs[segCount] = new LineSegment(ring.getCoordinateN(i), ring.getCoordinateN(i + 1));
        // Now process all other rings
        for (int i = 0; i < pGeom.getNumInteriorRing(); i++) {
            ring = pGeom.getInteriorRingN(i);
            for (int j = 0; j < ring.getNumPoints() - 1; j++, segCount++)
                segs[segCount] = new LineSegment(ring.getCoordinateN(j), ring.getCoordinateN(j + 1));
        }
        return segs;
    }

    private static LineSegment[] getSegments(MultiPolygon mPoly) {
        int numSegments = 0;
        for (int s = 0; s < mPoly.getNumGeometries(); s++)
            numSegments += getSegCount((Polygon) mPoly.getGeometryN(s));
        LineSegment[] segs = new LineSegment[numSegments];
        int segCount = 0;
        for (int i = 0; i < mPoly.getNumGeometries(); i++) {
            Polygon pGeom = (Polygon) mPoly.getGeometryN(i);
            // Process outer ring
            LineString ring = pGeom.getExteriorRing();
            for (int j = 0; j < ring.getNumPoints() - 1; j++, segCount++)
                segs[segCount] = new LineSegment(ring.getCoordinateN(j), ring.getCoordinateN(j + 1));
            // Now process all other rings
            for (int k = 0; k < pGeom.getNumInteriorRing(); k++) {
                ring = pGeom.getInteriorRingN(k);
                for (int l = 0; l < ring.getNumPoints() - 1; l++, segCount++)
                    segs[segCount] = new LineSegment(ring.getCoordinateN(l), ring.getCoordinateN(l + 1));
            }
        }
        return segs;
    }

    private static LineSegment[] getSegments(LineString line) {
        LineSegment[] segs = new LineSegment[line.getNumPoints() - 1];
        for (int i = 0; i < line.getNumPoints() - 1; i++)
            segs[i] = new LineSegment(line.getCoordinateN(i), line.getCoordinateN(i + 1));
        return segs;
    }

    private static LineSegment[] getSegments(MultiLineString mLine) {
        // Calculate number of segments in geometry
        int numSegments = getSegCount(mLine);
        LineSegment[] segs = new LineSegment[numSegments];
        int segCount = 0;
        for (int i = 0; i < mLine.getNumGeometries(); i++) {
            LineString line = (LineString) mLine.getGeometryN(i);
            for (int j = 0; j < line.getNumPoints() - 1; j++, segCount++)
                segs[segCount] = new LineSegment(line.getCoordinateN(j), line.getCoordinateN(j + 1));
        }
        return segs;
    }

    private static LineSegment[] getSegments(Geometry geom) {
        if (geom.getClass().equals(Polygon.class)) {
            return getSegments((Polygon) geom);
        } else if (geom.getClass().equals(MultiPolygon.class)) {
            return getSegments((MultiPolygon) geom);
        } else if (geom.getClass().equals(MultiLineString.class)) {
            return getSegments((MultiLineString) geom);
        } else if (geom.getClass().equals(LineString.class)) {
            return getSegments((LineString) geom);
        } else if (geom.getClass().equals(GeometryCollection.class)) {
            // not yet implemented
            // return getSegments((GeometryCollection)geom);

        }
        return null;
    }

    public static void Vectorize() {
        try {

            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database =
                DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:GISDB", "CODESYS", "CODEMGR");

            Statement statement;
            statement = database.createStatement();
            ResultSet results;
            results =
                statement.executeQuery("select sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,2,2)) as geom from dual " +
                                       "union all " +
                                       "select sdo_geometry(2006,null,null,sdo_elem_info_array(1,2,1,5,2,1),sdo_ordinate_array(1,1,2,2,10,10,20,20)) as geom from dual " +
                                       "union all " +
                                       "select sdo_geometry(2003,null,null,sdo_elem_info_array(1,1003,1),sdo_ordinate_array(50,105,55,105,60,110,50,110,50,105)) as geom from dual " +
                                       "union all " +
                                       "select sdo_geometry(2003,null,null,sdo_elem_info_array(1,1003,1,11,2003,3),sdo_ordinate_array(50,105,55,105,60,110,50,110,50,105,52,106,54,108)) as geom from dual " +
                                       "union all " +
                                       "select sdo_geometry(2007,null,null,sdo_elem_info_array(1,1003,1,11,1003,1),sdo_ordinate_array(50,105,55,105,60,110,50,110,50,105,62,108,65,108,65,112,62,112,62,108)) as geom from dual");

            Geometry geom;
            OraReader converter = new OraReader(null);
            while (results.next()) {
                // read in geometry object
                geom = converter.read((STRUCT) results.getObject(1));
                System.out.println(geom.getClass().toString());
                LineSegment[] segs = getSegments(geom);
                for (int i = 0; i < segs.length; i++)
                    System.out.println("(" + segs[i].p0.x + "," + segs[i].p0.y + ")(" + segs[i].p1.x + "," +
                                       segs[i].p1.y + ")");
            }
            results.close();
            statement.close();
            database.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void CSV(String sSQL, String sFormat, String sFileName) throws SQLException, ClassNotFoundException,
                                                                                 IOException, FileNotFoundException {
        try {
            // connect to test database
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:GISDB", "gis", "gis");
            Statement statement;
            statement = database.createStatement();
            ResultSet results = statement.executeQuery(sSQL);
            String outputDir = "C:\\temp"; // ShapeFileWriter.DEFAULT_OUTPUT_DIRECTORY;
            String ch = ",",
                   st = "\"";
            if (sFormat != null) {
                WriteDelimitedFile.setGeometryFormat(sFormat);
            }
            WriteDelimitedFile.write( /*java.sql.ResultSet _resultSet*/results,
                                      /*java.lang.String   _outputDirectory*/outputDir,
                                      /*java.lang.String   _fileName*/sFileName,
                                      /*java.lang.String   _cSeparator*/st,
                                      /*java.lang.String   _cDelimiter*/ch,
                                      /*java.lang.String   _sDateFormat*/(String)null,
                                      /*java.lang.String   _geomRenderFormat*/"WKT",
                                      /*int                _decimalDigitsOfPrecision*/3
                                     );

            results.close();
            statement.close();
            database.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void XBase(String sSQL, 
                             String _type, 
                             int geomPosition, 
                             String sDirectory, 
                             String sFileName) {
        try {
            // connect to test database
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database =
                DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:GISDB", "codesys", "codemgr");
            Statement statement;
            statement = database.createStatement();
            ResultSet rSet = statement.executeQuery(sSQL);
            DBFTypes dbType = DBFTypes.DBASEIII_WITH_MEMO.getDBFType(_type);
            //ResultSetXBaseWriter.writeDbaseIII(results,outputDir,sFileName,true);
            // ResultSetXBaseWriter.writeDbaseIV(results,sDirectory,sFileName,true);
            
            WriteXBaseFile.writeXBaseFile(rSet, 
                                          sDirectory, 
                                          sFileName, 
                                          new Integer(100), 
                                          dbType.toString(),
                                          Renderer.GEO_RENDERER_FORMAT.WKT.toString()
                                        );
            //ResultSetXBaseWriter.write(results,outputDir,sFileName);
            rSet.close();
            statement.close();
            database.close();
        } catch (xBaseJException xe) {
            xe.printStackTrace();
        } catch (IOException ioe) {
            ioe.printStackTrace();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void Excel(java.lang.String sSQL, java.lang.String outputDirectory, java.lang.String fileName,
                             java.lang.String sheetName, char stratification, String geomFormat) {
        try {
            // connect to test database
            Class.forName("oracle.jdbc.driver.OracleDriver");
            // Connection database = getConnection("localhost","GISDB12",1522,"codesys","codemgr");
            Connection database =
                DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12", "codesys", "codemgr");
            Statement statement;
            statement = database.createStatement();
            ResultSet results = statement.executeQuery(sSQL);
            /*
                WriteExcelFile.setPrecisionScale(1);
                WriteExcelFile.setGeometryFormat(geomFormat);
                WriteExcelFile.setStratification(stratification.charAt(1));
                */
            WriteExcelFile.write( /*java.sql.ResultSet _resultSet       */results,
                                  /*java.lang.String   _outputDirectory */outputDirectory,
                                  /*java.lang.String   _fileName        */fileName,
                                  /*java.lang.String   _sheetName       */sheetName,
                                  /*java.lang.String   _stratification  */String.valueOf(stratification),
                                  /*java.lang.String   _geomFormat      */"WKT",
                                  /*java.lang.String   _dateFormat      */"yyyyMMdd",
                                  /*java.lang.String   _timeFormat      */"h:mm:ss a",
                                  /*java.lang.String   _charSetName     */null,
                                  /*int                _precision       */3);
            results.close();
            statement.close();
            database.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void dimarray() {
        try {
            // connect to test database
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:GISDB", "gis", "gis");
            Statement statement;
            statement = database.createStatement();
            ResultSet results = statement.executeQuery("SELECT DIMINFO FROM USER_SDO_GEOM_METADATA WHERE ROWNUM < 2");
            results.next();
            results.getMetaData().getColumnType(1);
            oracle.sql.ARRAY ary = (ARRAY) results.getArray(1);
            System.out.println(ary.getDescriptor()
                                  .getSQLName()
                                  .getName()
                                  .equals("MDSYS.SDO_DIM_ARRAY"));
            Datum[] objs = ary.getOracleArray();
            for (int i = 0; i < objs.length; i++) {
                STRUCT dimElement = (STRUCT) objs[i];
                Datum data[] = dimElement.getOracleAttributes();
                final String DIM_NAME = data[0].stringValue();
                final double SDO_LB = data[1].doubleValue();
                final double SDO_UB = data[2].doubleValue();
                final double SDO_TOL = data[3].doubleValue();
            }
            results.close();
            statement.close();
            database.close();
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    private static Connection getConnection(String server, String databaseName, int portNumber, String userName,
                                            String password) {
        OracleDataSource dataSource;
        try {
            dataSource = new OracleDataSource();
            dataSource.setServerName(server);
            dataSource.setUser(userName);
            dataSource.setPassword(password);
            dataSource.setDatabaseName(databaseName);
            dataSource.setPortNumber(portNumber);
            dataSource.setDriverType("thin");
            return dataSource.getConnection();
        } catch (SQLException e) {
        }
        return null;
    }

    public static void GML(String _SQL,
                           String _geoColumn,
                           String _fileName, 
                           String _gmlType,
                           Constants.XMLAttributeFlavour _attributeFlavour ) 
    throws SQLException, ClassNotFoundException, IOException, FileNotFoundException
    {
        try 
        { 
            // connect to test database
            Class.forName("oracle.jdbc.driver.OracleDriver");
            // Connection database = getConnection("localhost","GISDB12",1522,"codesys","codemgr");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","codesys","codemgr");
            //Connection database = DriverManager.getConnection("jdbc:oracle:oci8:@GISDB12","codesys","codemgr");
            Statement statement = null;
            statement = database.createStatement();
            java.sql.ResultSet results = statement.executeQuery (_SQL);
            String outputDir = "C:\\temp"; 
            //int i = 0; while (results.next()) { i++; } System.out.println("Processed " + i + " rows.");
            WriteGMLFile.write(
                /*_resultSet              */ results, 
                /*_outputDirectory        */ outputDir, 
                /*_fileName               */ _fileName, 
                /*_geomColumnName         */ _geoColumn,
                /*_polygonOrientation     */ "INVERSE",
                /*_GMLVersion             */ "GML3",
                /* _attributeFlavour      */ _attributeFlavour.toString(),
                /* _attributeGroupName    */ "Attributes",
                /*_geomRenderFormat       */ _gmlType,
                /*_decimalDigitsOfPrecision*/ 7,
                /*_commit                  */ 100
            );
            results.close();
            statement.close();
            database.close(); 
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static void KML() 
    throws SQLException, ClassNotFoundException, IOException, FileNotFoundException
    {
        try { 
            System.out.println("Writing KML file.");
            String sSQL = "select ID,GROUNDHEIGHT,HEIGHT,POLEHEIGHT,WITHINSANDFLYLOS,NAME,0 as open," +
                                 "rownum || ' Cliff View Drive, Allens Rivulet, Tas, 7150' as address," +
                                 "'0362396397' as phoneNumber, " +
                                 "sdo_geometry(3001,28355,sdo_point_type(309783,52394856,78.345),null,null) as otherPoint," +
                                 "sdo_cs.transform(a.GEOMETRY,8311) as geometry " +
                          " from codesys.house_locations a " +
                          "where rownum <= 100";
            // connect to test database
            Class.forName("oracle.jdbc.driver.OracleDriver");
            // Connection database = getConnection("localhost","GISDB12",1522,"codesys","codemgr");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","codesys","codemgr");
            //Connection database = DriverManager.getConnection("jdbc:oracle:oci8:@GISDB12","codesys","codemgr");
            Statement statement = null;
            statement = database.createStatement();
            java.sql.ResultSet results = statement.executeQuery (sSQL);
            String outputDir = "C:\\temp"; 
            String sFileName = "house_locations.kml";
            /* int i = 0; while (results.next()) { i++; } System.out.println("Processed " + i + " rows."); */
            WriteKMLFile.write(/*java.sql.ResultSet _resultSet              */ results, 
                               /*java.lang.String   _outputDirectory        */ outputDir, 
                               /*java.lang.String   _fileName               */ sFileName, 
                               /*java.lang.String   _geomColumnName         */ "GEOMETRY",
                               /*java.lang.String   _sDateFormat            */ "yyyy/MM/dd hh:mm:ss a",
                               /*java.lang.String   _geomRenderFormat        */ "WKT",
                               /*int                _decimalDigitsOfPrecision*/ 7,
                               /*int                _commit                  */ 100);
            results.close();
            statement.close();
            database.close(); 
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
          
    public static void GeoJSON() 
    throws SQLException, ClassNotFoundException, IOException, FileNotFoundException
    {
        try { 
            String sSQL = "select ID,GROUNDHEIGHT,HEIGHT,POLEHEIGHT,WITHINSANDFLYLOS,NAME,0 as open,rownum || ' Cliff View Drive, Allens Rivulet, Tas, 7150' as address," +
                "'0362396397' as phoneNumber, " +
                "sdo_geometry(2001,28355,sdo_point_type(309783,52394856,null),null,null) as otherPoint," +
                "sdo_geometry(2002,28355,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(309783,52394856,309800,52394900)) as otherLine," +
                "sdo_cs.transform(a.GEOMETRY,8311) as geometry from codesys.house_locations a where rownum <= 2";
            sSQL = "select ID,sdo_cs.transform(a.GEOMETRY,8311) as geometry from codesys.house_locations a where rownum <= 2";
            sSQL = "select ID,GROUNDHEIGHT,sdo_cs.transform(a.GEOMETRY,8311) as geometry from codesys.house_locations a where rownum <= 2";
            sSQL = "select ID,GROUNDHEIGHT," +
                           "sdo_cs.transform(sdo_geometry(2001,28355,sdo_point_type(309783,52394856,null),null,null),8311) as otherPoint," +
                "sdo_cs.transform(a.GEOMETRY,8311) as geometry from codesys.house_locations a where rownum <= 2";
            sSQL = "select sdo_cs.transform(sdo_geometry(2001,28355,sdo_point_type(309783,52394856,null),null,null),8311) as otherPoint," +
                          "sdo_cs.transform(a.GEOMETRY,8311) as geometry from codesys.house_locations a where rownum <= 2";
            sSQL = "select ID, GROUNDHEIGHT,sdo_cs.transform(sdo_geometry(2001,28355,sdo_point_type(309783,52394856,null),null,null),8311) as otherPoint," +
                          "sdo_cs.transform(a.GEOMETRY,8311) as geometry from codesys.house_locations a where rownum <= 2";
            // connect to test database
            Class.forName("oracle.jdbc.driver.OracleDriver");
            // Connection database = getConnection("localhost","GISDB12",1522,"codesys","codemgr");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","codesys","codemgr");
            //Connection database = DriverManager.getConnection("jdbc:oracle:oci8:@GISDB12","codesys","codemgr");
            Statement statement = null;
            statement = database.createStatement();
            java.sql.ResultSet results = statement.executeQuery (sSQL);
            String outputDir = "C:\\temp"; 
            String sFileName = "house_locations.kml";
            /* int i = 0; while (results.next()) { i++; } System.out.println("Processed " + i + " rows."); */
            WriteGeoJSONFile.write(/*java.sql.ResultSet _resultSet                       */results, 
                                   /*java.lang.String   _outputDirectory                 */outputDir, 
                                   /*java.lang.String   _fileName                        */sFileName, 
                                   /*java.lang.String   _geomColumn                      */ "GEOMETRY",
                                   /*java.lang.String   _idColumn                        */ "ID",
                                   /*java.lang.String   _sDateFormat                     */ "yyyy/MM/dd hh:mm:ss a", 
                                   /*java.lang.String   _geomRenderFormat                */ "WKT",
                                   /*int                _aggregateMultipleGeometryColumns*/ 1,
                                   /*int                _decimalDigitsOfPrecision        */ 7,
                                   /*int                _bbox                            */ 1,
                                   /*int                _commit                          */ 10
                                );
            results.close();
            statement.close();
            database.close();        
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }


    /**
     * Export to SHP format
     *
     * @throws SQLException
     * @throws ClassNotFoundException
     * @throws IOException
     */
    public static void shape2() throws SQLException, ClassNotFoundException, IOException {
        Connection database = null;
        // connect to test database
        Class.forName("oracle.jdbc.driver.OracleDriver");
        try {
            String filename = "";
            database =
                DriverManager.getConnection("jdbc:oracle:thin:@(description=(address=(host=**********)(protocol=tcp)(port=1521))(connect_data=(service_name=****)))",
                                            "****", "****");
            Statement statement;
            ResultSet results;
            String shapefiletype = "";
            String outputDir = "C:\\Temp"; // ShapeFileWriter.DEFAULT_OUTPUT_DIRECTORY;
            String prjString = "PROJCS[\"LKS_1994_Lithuania_TM\",GEOGCS[\"GCS_LKS_1994\",DATUM[\"D_Lithuania_1994\",SPHEROID[\"GRS_1980\",6378137.0,298.257222101]],PRIMEM[\"Greenwich\",0.0],UNIT[\"Degree\",0.0174532925199433]],PROJECTION[\"Transverse_Mercator\"],PARAMETER[\"False_Easting\",500000.0],PARAMETER[\"False_Northing\",0.0],PARAMETER[\"Central_Meridian\",24.0],PARAMETER[\"Scale_Factor\",0.9998],PARAMETER[\"Latitude_Of_Origin\",0.0],UNIT[\"Meter\",1.0]]";
            String SQL = "select rownum as fid, SDO_UTIL.FROM_WKTGEOMETRY(sde.st_astext(shape)) as geom from mati_sde.skl_pol a where a.geo_id = 94868 and a.anul_tipas is null";
            filename = "LAND_PARCELS";
            shapefiletype = "polygon";
            statement = database.createStatement();
            results = statement.executeQuery(SQL);
            WriteSHPFile.write(
                /* java.sql.ResultSet _resultSet */results,
                /* java.lang.String _outputDirectory */outputDir,
                /* java.lang.String _fileName */filename,
                /* java.lang.String _shapeType */shapefiletype,
                /* java.lang.String _geometryName */"GEOM",
                /* java.lang.String _polygonOrientation */"INVERTED",
                /* java.lang.String _dbaseType        */ "BASE",
                /* java.lang.String _geomRenderFormat */"WKT",
                /* java.lang.String _prjString        */prjString,
                /* int _decimalDigitsOfPrecision */3,
                /* int _commit */1000
            );
            results.close();
            statement.close();
            database.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }    
}
