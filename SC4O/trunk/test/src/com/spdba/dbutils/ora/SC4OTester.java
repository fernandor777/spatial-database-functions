package com.spdba.dbutils.ora;

import com.spdba.dbutils.Comparitor;
import com.spdba.dbutils.Constants;
import com.spdba.dbutils.JTS;
import com.spdba.dbutils.Space;
import com.spdba.dbutils.io.exp.wkt.EWKTExporter;
import com.spdba.dbutils.io.imp.wkt.EWKTImporter;
import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.sql.DBConnection;
import com.spdba.dbutils.sql.SQLConversionTools;
import com.spdba.dbutils.tools.MathUtils;
import com.spdba.dbutils.tools.Tools;

import java.io.IOException;

import java.math.BigDecimal;

import java.sql.Array;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import java.sql.Struct;

import oracle.jdbc.OracleResultSet;
import oracle.jdbc.driver.OracleConnection;

import oracle.sql.ARRAY;
import oracle.sql.CLOB;
import oracle.sql.Datum;
import oracle.sql.NUMBER;
import oracle.sql.STRUCT;

import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.io.WKTReader;
import org.locationtech.jts.io.WKTWriter;
import org.locationtech.jts.io.oracle.OraReader;
import org.locationtech.jts.io.oracle.OraWriter;
import org.locationtech.jts.operation.overlay.OverlayOp;
import org.locationtech.jts.precision.GeometryPrecisionReducer;

//import org.geotools.data.oracle.sdo.GeometryConverter;

// Referenced classes of package com.spatialdbadvisor.dbutils.ora:
//            Space, JTS

public class SC4OTester
{

    public static void main()
    {
        try
        {
            TestStruct();
            //TestUpdatePoint();
            //TestAddPoint();
            //TestRemovePoint();
            //ST_OffsetLine    (-5.0,3);
            //ST_OneSidedBuffer(-5.0,3);
            //ST_Buffer(5.0,3);
            //ST_LineDissolver(2);
            //Dissolve();
            //TestFromEWKT();
            //TestAsText();
            //TestRelate();
            //TestConversion();
            //TestEnvelope();
            //TestCollect();
            //TestLineMerger();
            //TestRound();
            //TestInterpolateZ();
            
/*          TestInvalid();
            TestAsText();
            TestPointLineIntersection();
            TestLineLine(1); // Intersection
            TestLineLine(2); // Union
            TestLineBuffer();
            TestPolygonBuilder();
            TestUnion();
            RegularGrid(0f,0f,160f,160f,10,10);
            TestLineMaker();
            TestFromGML();
            //FastExporter();
            TestInterpolateZ();
            TestMultiPointClip();
            TestMultiPointGeomCollectionClip(1);
            TestMultiPointGeomCollectionClip(2);
            TestLineSimplifier(1); // ST_DouglasPeuckerSimplifier
            TestLineSimplifier(2); // ST_VisvalingamWhyattSimplify
*/
            System.out.println("Finished");
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }
    }
    
    public static void TestEnvelope() throws SQLException {
        try {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            OracleConnection database = (OracleConnection)DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12", "gis", "GISMGR");
            DBConnection.setConnection(database);
            STRUCT g = JTS.ST_MakeEnvelope(0.1, 0.1, 10.1, 10.1, -1, 3);
            CLOB c = EWKTExporter.ST_AsText(g);
            displayCLOB(" Envelope: ", c);
            database.close();
        } catch (IOException e) {
        } catch (ClassNotFoundException e) {
        }
    }

    public static void TestRound() 
    throws SQLException 
    {
        try {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            OracleConnection database = (OracleConnection)DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12", "gis", "GISMGR");
            DBConnection.setConnection(database);            
            String wkt = "BOX3D(-32 147 1.2343,-33 148 2.523544)";
            System.out.println("wkt="+wkt);
            STRUCT sGeom = EWKTImporter.ST_GeomFromEWKT(wkt,8307);
            CLOB ewkt = EWKTExporter.ST_AsEWKT(JTS.ST_Round(sGeom,2));
            try { displayCLOB("ST_Round: ", ewkt); } catch(Exception e) { System.out.println(e.getMessage()); }
            database.close();
        } catch (ClassNotFoundException e) {
        }
    }
    
    public static void TestConversion()
        throws Exception
    {
        System.out.println("TestConversion");
        try
        {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            OracleConnection database = (OracleConnection)DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12", "gis", "GISMGR");
            Statement statement = database.createStatement();
            DBConnection.setConnection(database);
            ResultSet results = statement.executeQuery(
            "SELECT 1 as gid, MDSYS.SDO_GEOMETRY(NULL,NULL,NULL,NULL,NULL) AS GEOM FROM DUAL UNION ALL " +
            "SELECT 2 as gid, MDSYS.SDO_GEOMETRY(2001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(10.0,5.0, 11.0,6.0)) AS GEOM FROM DUAL UNION ALL " +
            "SELECT 3 as gid, MDSYS.SDO_GEOMETRY(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,2),SDO_ORDINATE_ARRAY(10.0,15.0, 15.0,20.0, 20.0,15.0)) AS GEOM FROM DUAL UNION ALL "+
            "SELECT 4 as gid, mdsys.sdo_geometry(2001,8307,SDO_POINT_TYPE(5,5,NULL),NULL,NULL) as GEOM FROM DUAL UNION ALL " +
            "SELECT 5 as gid, mdsys.sdo_geometry(2001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(50,50)) as GEOM FROM DUAL UNION ALL " +
            "SELECT 6 as gid, mdsys.sdo_geometry(3001,NULL,SDO_POINT_TYPE(50,50,100),NULL,NULL) as GEOM FROM DUAL UNION ALL " +
            "SELECT 7 as gid, mdsys.sdo_geometry(3001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(50,50,100)) as GEOM FROM DUAL UNION ALL " +
            "SELECT 8 as gid, mdsys.sdo_geometry(4001,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(50,50,100,200)) as GEOM FROM DUAL UNION ALL " +
            "SELECT 9 as gid, mdsys.sdo_geometry(3005,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,2),SDO_ORDINATE_ARRAY(50,50,5, 100,200,300)) as GEOM FROM DUAL UNION ALL " +
            "SELECT 10 as gid, mdsys.sdo_geometry(2002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,50,50)) as GEOM FROM DUAL UNION ALL " +
            "SELECT 11 as gid, mdsys.sdo_geometry(3002,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,0,50,50,100)) as GEOM FROM DUAL UNION ALL " +
            "SELECT 12 as gid, mdsys.sdo_geometry(3302,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,0,50,50,100)) as GEOM FROM DUAL  UNION ALL " +
            "SELECT 13 as gid, mdsys.sdo_geometry(4302,8307,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,2,3,50,50,100,200)) as GEOM FROM DUAL UNION ALL " +
            "SELECT 14 as gid, mdsys.sdo_geometry(4306,8307,NULL,SDO_ELEM_INFO_ARRAY(1,2,1,9,2,1),SDO_ORDINATE_ARRAY(0,0,2,3,50,50,100,200,10,10,12,13,150,150,110,210)) as GEOM FROM DUAL UNION ALL " +
            "SELECT 15 as gid, mdsys.sdo_geometry(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3),SDO_ORDINATE_ARRAY(0,0,50,50)) as GEOM FROM DUAL UNION ALL " +
            "SELECT 16 as gid, mdsys.sdo_geometry(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3,5,2003,3),SDO_ORDINATE_ARRAY(0,0,50,50,40,40,20,20)) as GEOM FROM DUAL UNION ALL " +
            "SELECT 17 as gid, mdsys.sdo_geometry(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,1),SDO_ORDINATE_ARRAY(0,0,50,0,50,50,0,50,0,0)) as GEOM FROM DUAL UNION ALL " +
            "SELECT 18 as gid, mdsys.sdo_geometry(2007,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3,5,2003,3,9,1003,3),SDO_ORDINATE_ARRAY(0,0,50,50,40,40,20,20,60,0,70,10)) as GEOM FROM DUAL " 
            );
            // Convert Geometries
            //
            PrecisionModel      pm = new PrecisionModel(Tools.getPrecisionScale(2));
            GeometryFactory     gf = new GeometryFactory(pm); 
            OraWriter           ow = new OraWriter();
            OraReader           or = new OraReader(gf);
            Geometry           geo = null;
                
            Tools.setPrecisionScale(3);
            Integer gid = -1;
            int i=0;
            STRUCT geom = null;
            while (results.next()) {
                try {
                    gid  = ((BigDecimal)results.getObject("GID")).intValue();
                    System.out.println("Testing geometry gid=" + gid);
                    geom = (STRUCT)results.getObject("GEOM");
                    int SRID      = SDO.getSRID(geom,-1);
                    int GTYPE     = SDO.getGType(geom, 2001);
                    int FullGType = SDO.getFullGType(geom, 2001);
                    int DIM       = SDO.getDimension(geom,2);
                    System.out.println(DIM + "D geometry of type " + GTYPE + " (" + FullGType + ") read from result set.");
                    or.setDimension(DIM); 
                    geo = or.read(geom);
                    System.out.println("    Geometry Read from SDO_GEOMETRY has type " + geo.getGeometryType() + " with dimension " + DIM + ". is Valid?=" + geo.isValid() );
                    // Now Convert from JTS Geometry to SDO_GEOMETRY
                    STRUCT jGeom = null;
                    ow.setDimension(DIM); 
                    ow.setSRID(SRID);
                    jGeom = ow.write(geo,database);
                    displayCLOB("     JTS oraWriter STRUCT (" + SDO.getGType(jGeom, 2001) + "): ",EWKTExporter.ST_AsEWKT(jGeom)); 
                } catch (Exception e) {
                    e.printStackTrace();
                    System.out.println("     Conversion error " + e.toString());
                }
            }
            results.close();
            statement.close();
            database.close();
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }
    }

    public static void TestMultiPointClip()
        throws Exception
    {
        System.out.println("TestMultiPointClip");
        try
        {
            PrecisionModel  pm              = new PrecisionModel(3);
            GeometryFactory geometryFactory = new GeometryFactory(pm); 
            WKTReader reader = new WKTReader(geometryFactory);
            Geometry poly = reader.read("POLYGON ((755438.136705691 3679051.52458636 9.86999999918044, 755441.542258283 3678850.38541675 9.14999999944121, 755639.275877972 3679054.93014137 10, 755438.136705691 3679051.52458636 9.86999999918044))");
            Geometry mPoint = reader.read("MULTIPOINT ((755445.0 3678855.0), (755445.0 3678865.0), (755445.0 3678875.0), (755445.0 3678885.0), (755445.0 3678895.0), (755445.0 3678905.0), (755445.0 3678915.0), (755445.0 3678925.0), (755445.0 3678935.0), (755445.0 3678945.0), (755445.0 3678955.0), (755445.0 3678965.0), (755445.0 3678975.0), (755445.0 3678985.0), (755445.0 3678995.0), (755445.0 3679005.0), (755445.0 3679015.0), (755445.0 3679025.0), (755445.0 3679035.0), (755445.0 3679045.0), (755455.0 3678865.0), (755455.0 3678875.0), (755455.0 3678885.0), (755455.0 3678895.0), (755455.0 3678905.0), (755455.0 3678915.0), (755455.0 3678925.0), (755455.0 3678935.0), (755455.0 3678945.0), (755455.0 3678955.0), (755455.0 3678965.0), (755455.0 3678975.0), (755455.0 3678985.0), (755455.0 3678995.0), (755455.0 3679005.0), (755455.0 3679015.0), (755455.0 3679025.0), (755455.0 3679035.0), (755455.0 3679045.0), (755465.0 3678875.0), (755465.0 3678885.0), (755465.0 3678895.0), (755465.0 3678905.0), (755465.0 3678915.0), (755465.0 3678925.0), (755465.0 3678935.0), (755465.0 3678945.0), (755465.0 3678955.0), (755465.0 3678965.0), (755465.0 3678975.0), (755465.0 3678985.0), (755465.0 3678995.0), (755465.0 3679005.0), (755465.0 3679015.0), (755465.0 3679025.0), (755465.0 3679035.0), (755465.0 3679045.0), (755475.0 3678885.0), (755475.0 3678895.0), (755475.0 3678905.0), (755475.0 3678915.0), (755475.0 3678925.0), (755475.0 3678935.0), (755475.0 3678945.0), (755475.0 3678955.0), (755475.0 3678965.0), (755475.0 3678975.0), (755475.0 3678985.0), (755475.0 3678995.0), (755475.0 3679005.0), (755475.0 3679015.0), (755475.0 3679025.0), (755475.0 3679035.0), (755475.0 3679045.0), (755485.0 3678905.0), (755485.0 3678915.0), (755485.0 3678925.0), (755485.0 3678935.0), (755485.0 3678945.0), (755485.0 3678955.0), (755485.0 3678965.0), (755485.0 3678975.0), (755485.0 3678985.0), (755485.0 3678995.0), (755485.0 3679005.0), (755485.0 3679015.0), (755485.0 3679025.0), (755485.0 3679035.0), (755485.0 3679045.0), (755495.0 3678915.0), (755495.0 3678925.0), (755495.0 3678935.0), (755495.0 3678945.0), (755495.0 3678955.0), (755495.0 3678965.0), (755495.0 3678975.0), (755495.0 3678985.0), (755495.0 3678995.0), (755495.0 3679005.0), (755495.0 3679015.0), (755495.0 3679025.0), (755495.0 3679035.0), (755495.0 3679045.0), (755505.0 3678925.0), (755505.0 3678935.0), (755505.0 3678945.0), (755505.0 3678955.0), (755505.0 3678965.0), (755505.0 3678975.0), (755505.0 3678985.0), (755505.0 3678995.0), (755505.0 3679005.0), (755505.0 3679015.0), (755505.0 3679025.0), (755505.0 3679035.0), (755505.0 3679045.0), (755515.0 3678935.0), (755515.0 3678945.0), (755515.0 3678955.0), (755515.0 3678965.0), (755515.0 3678975.0), (755515.0 3678985.0), (755515.0 3678995.0), (755515.0 3679005.0), (755515.0 3679015.0), (755515.0 3679025.0), (755515.0 3679035.0), (755515.0 3679045.0), (755525.0 3678945.0), (755525.0 3678955.0), (755525.0 3678965.0), (755525.0 3678975.0), (755525.0 3678985.0), (755525.0 3678995.0), (755525.0 3679005.0), (755525.0 3679015.0), (755525.0 3679025.0), (755525.0 3679035.0), (755525.0 3679045.0), (755535.0 3678955.0), (755535.0 3678965.0), (755535.0 3678975.0), (755535.0 3678985.0), (755535.0 3678995.0), (755535.0 3679005.0), (755535.0 3679015.0), (755535.0 3679025.0), (755535.0 3679035.0), (755535.0 3679045.0), (755545.0 3678965.0), (755545.0 3678975.0), (755545.0 3678985.0), (755545.0 3678995.0), (755545.0 3679005.0), (755545.0 3679015.0), (755545.0 3679025.0), (755545.0 3679035.0), (755545.0 3679045.0), (755555.0 3678975.0), (755555.0 3678985.0), (755555.0 3678995.0), (755555.0 3679005.0), (755555.0 3679015.0), (755555.0 3679025.0), (755555.0 3679035.0), (755555.0 3679045.0), (755565.0 3678985.0), (755565.0 3678995.0), (755565.0 3679005.0), (755565.0 3679015.0), (755565.0 3679025.0), (755565.0 3679035.0), (755565.0 3679045.0), (755575.0 3678995.0), (755575.0 3679005.0), (755575.0 3679015.0), (755575.0 3679025.0), (755575.0 3679035.0), (755575.0 3679045.0), (755585.0 3679005.0), (755585.0 3679015.0), (755585.0 3679025.0), (755585.0 3679035.0), (755585.0 3679045.0), (755595.0 3679015.0), (755595.0 3679025.0), (755595.0 3679035.0), (755595.0 3679045.0), (755605.0 3679025.0), (755605.0 3679035.0), (755605.0 3679045.0), (755615.0 3679035.0), (755615.0 3679045.0), (755625.0 3679045.0))");
            System.out.println("Intersection");
            Geometry iPoints = OverlayOp.overlayOp(mPoint, poly, OverlayOp.INTERSECTION);
            if (iPoints != null)  {
                System.out.println(iPoints.toText());
                System.out.println("Difference");
                Geometry difference = OverlayOp.overlayOp(iPoints, mPoint, OverlayOp.DIFFERENCE);
                if (difference != null) 
                    System.out.println(difference.toText());
            }
        } catch (Exception e) {
            System.out.println("Error " + e.getMessage());
        }
    }

    public static void TestCollect() 
    throws Exception
    {
        Class.forName("oracle.jdbc.driver.OracleDriver");
        Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","GIS","GISMGR");
        Statement statement = database.createStatement();
        ResultSet results = statement.executeQuery(
            "with data as (\n" + 
            "  select mdsys.sdo_geometry (2001, 28355, sdo_point_type(50,5,null),null,null) as point from dual union all\n" + 
            "  select mdsys.sdo_geometry (2001, 28355, sdo_point_type(55,7,null),null,null) as point from dual union all\n" + 
            "  select mdsys.sdo_geometry (2001, 28355, sdo_point_type(60,5,null),null,null) as point from dual\n" + 
            ")\n" + 
            "select CAST(COLLECT(a.point) as mdsys.sdo_geometry_array) as geomarray " + 
            "  from data a"
            );
        DBConnection.setConnection((OracleConnection)database);
        results.next();
        oracle.sql.ARRAY array = ((OracleResultSet)results).getARRAY(1);
        STRUCT geom = JTS.ST_Collect(array, 1);
        try { displayCLOB("collection: ",EWKTExporter.ST_AsText(geom)); } catch(Exception e) { System.out.println(e.getMessage()); }
        results.close();
        database.close();
    }
    
    public static void TestLineMerger() 
    throws Exception
    {
        Class.forName("oracle.jdbc.driver.OracleDriver");
        Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","GIS","GISMGR");
        Statement statement = database.createStatement();
        ResultSet results = statement.executeQuery(
                    "with data as ( " + 
                    "select sdo_geometry('LINESTRING (160 310, 160 280, 160 250, 170 230)',NULL) as geom from dual union all " +
                    "select sdo_geometry('LINESTRING (170 230, 180 210, 200 180, 220 160)',NULL) as geom from dual union all " +
                    "select sdo_geometry('LINESTRING (160 310, 200 330, 220 340, 240 360)',NULL) as geom from dual union all " +
                    "select sdo_geometry('LINESTRING (240 360, 260 390, 260 410, 250 430)',NULL) as geom from dual )" + 
                   "select CAST(COLLECT(a.geom) as mdsys.sdo_geometry_array) as geomarray " + 
                   "  from data a"
        );
        DBConnection.setConnection((OracleConnection)database);
        results.next();
        oracle.sql.ARRAY array = ((OracleResultSet)results).getARRAY(1);
        STRUCT geom = JTS.ST_LineMerger(array, 2);
        try { displayCLOB("collection: ",EWKTExporter.ST_AsText(geom)); } catch(Exception e) { System.out.println(e.getMessage()); }
        results.close();
        database.close();
    }
    
    public static void TestMultiPointGeomCollectionClip(int which)
        throws Exception
    {
        System.out.println("\nTestMultiPointGeomCollectionClip\n================================");
        try
        {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","codesys","CODEMGR");
            Statement statement = database.createStatement();
            ResultSet results = statement.executeQuery(
            which==1?
            "select MDSYS.SDO_GEOMETRY(3003, 32615, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1), MDSYS.SDO_ORDINATE_ARRAY(755438.136705691, 3679051.52458636, 9.86999999918044, 755441.542258283, 3678850.38541675, 9.14999999944121, 755639.275877972, 3679054.93014137, 10.0, 755438.136705691, 3679051.52458636, 9.86999999918044)) as facet, " +
                   "MDSYS.SDO_GEOMETRY(2005, 32615, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,1,194),  MDSYS.SDO_ORDINATE_ARRAY(755445.0, 3678855.0, 755445.0, 3678865.0, 755445.0, 3678875.0, 755445.0, 3678885.0, 755445.0, 3678895.0, 755445.0, 3678905.0, 755445.0, 3678915.0, 755445.0, 3678925.0, 755445.0, 3678935.0, 755445.0, 3678945.0, 755445.0, 3678955.0, 755445.0, 3678965.0, 755445.0, 3678975.0, 755445.0, 3678985.0, 755445.0, 3678995.0, 755445.0, 3679005.0, 755445.0, 3679015.0, 755445.0, 3679025.0, 755445.0, 3679035.0, 755445.0, 3679045.0, 755455.0, 3678865.0, 755455.0, 3678875.0, 755455.0, 3678885.0, 755455.0, 3678895.0, 755455.0, 3678905.0, 755455.0, 3678915.0, 755455.0, 3678925.0, 755455.0, 3678935.0, 755455.0, 3678945.0, 755455.0, 3678955.0, 755455.0, 3678965.0, 755455.0, 3678975.0, 755455.0, 3678985.0, 755455.0, 3678995.0, 755455.0, 3679005.0, 755455.0, 3679015.0, 755455.0, 3679025.0, 755455.0, 3679035.0, 755455.0, 3679045.0, 755465.0, 3678875.0, 755465.0, 3678885.0, 755465.0, 3678895.0, 755465.0, 3678905.0, 755465.0, 3678915.0, 755465.0, 3678925.0, 755465.0, 3678935.0, 755465.0, 3678945.0, 755465.0, 3678955.0, 755465.0, 3678965.0, 755465.0, 3678975.0, 755465.0, 3678985.0, 755465.0, 3678995.0, 755465.0, 3679005.0, 755465.0, 3679015.0, 755465.0, 3679025.0, 755465.0, 3679035.0, 755465.0, 3679045.0, 755475.0, 3678885.0, 755475.0, 3678895.0, 755475.0, 3678905.0, 755475.0, 3678915.0, 755475.0, 3678925.0, 755475.0, 3678935.0, 755475.0, 3678945.0, 755475.0, 3678955.0, 755475.0, 3678965.0, 755475.0, 3678975.0, 755475.0, 3678985.0, 755475.0, 3678995.0, 755475.0, 3679005.0, 755475.0, 3679015.0, 755475.0, 3679025.0, 755475.0, 3679035.0, 755475.0, 3679045.0, 755485.0, 3678905.0, 755485.0, 3678915.0, 755485.0, 3678925.0, 755485.0, 3678935.0, 755485.0, 3678945.0, 755485.0, 3678955.0, 755485.0, 3678965.0, 755485.0, 3678975.0, 755485.0, 3678985.0, 755485.0, 3678995.0, 755485.0, 3679005.0, 755485.0, 3679015.0, 755485.0, 3679025.0, 755485.0, 3679035.0, 755485.0, 3679045.0, 755495.0, 3678915.0, 755495.0, 3678925.0, 755495.0, 3678935.0, 755495.0, 3678945.0, 755495.0, 3678955.0, 755495.0, 3678965.0, 755495.0, 3678975.0, 755495.0, 3678985.0, 755495.0, 3678995.0, 755495.0, 3679005.0, 755495.0, 3679015.0, 755495.0, 3679025.0, 755495.0, 3679035.0, 755495.0, 3679045.0, 755505.0, 3678925.0, 755505.0, 3678935.0, 755505.0, 3678945.0, 755505.0, 3678955.0, 755505.0, 3678965.0, 755505.0, 3678975.0, 755505.0, 3678985.0, 755505.0, 3678995.0, 755505.0, 3679005.0, 755505.0, 3679015.0, 755505.0, 3679025.0, 755505.0, 3679035.0, 755505.0, 3679045.0, 755515.0, 3678935.0, 755515.0, 3678945.0, 755515.0, 3678955.0, 755515.0, 3678965.0, 755515.0, 3678975.0, 755515.0, 3678985.0, 755515.0, 3678995.0, 755515.0, 3679005.0, 755515.0, 3679015.0, 755515.0, 3679025.0, 755515.0, 3679035.0, 755515.0, 3679045.0, 755525.0, 3678945.0, 755525.0, 3678955.0, 755525.0, 3678965.0, 755525.0, 3678975.0, 755525.0, 3678985.0, 755525.0, 3678995.0, 755525.0, 3679005.0, 755525.0, 3679015.0, 755525.0, 3679025.0, 755525.0, 3679035.0, 755525.0, 3679045.0, 755535.0, 3678955.0, 755535.0, 3678965.0, 755535.0, 3678975.0, 755535.0, 3678985.0, 755535.0, 3678995.0, 755535.0, 3679005.0, 755535.0, 3679015.0, 755535.0, 3679025.0, 755535.0, 3679035.0, 755535.0, 3679045.0, 755545.0, 3678965.0, 755545.0, 3678975.0, 755545.0, 3678985.0, 755545.0, 3678995.0, 755545.0, 3679005.0, 755545.0, 3679015.0, 755545.0, 3679025.0, 755545.0, 3679035.0, 755545.0, 3679045.0, 755555.0, 3678975.0, 755555.0, 3678985.0, 755555.0, 3678995.0, 755555.0, 3679005.0, 755555.0, 3679015.0, 755555.0, 3679025.0, 755555.0, 3679035.0, 755555.0, 3679045.0, 755565.0, 3678985.0, 755565.0, 3678995.0, 755565.0, 3679005.0, 755565.0, 3679015.0, 755565.0, 3679025.0, 755565.0, 3679035.0, 755565.0, 3679045.0, 755575.0, 3678995.0, 755575.0, 3679005.0, 755575.0, 3679015.0, 755575.0, 3679025.0, 755575.0, 3679035.0, 755575.0, 3679045.0, 755585.0, 3679005.0, 755585.0, 3679015.0, 755585.0, 3679025.0, 755585.0, 3679035.0, 755585.0, 3679045.0, 755595.0, 3679015.0, 755595.0, 3679025.0, 755595.0, 3679035.0, 755595.0, 3679045.0, 755605.0, 3679025.0, 755605.0, 3679035.0, 755605.0, 3679045.0, 755615.0, 3679035.0, 755615.0, 3679045.0, 755625.0, 3679045.0)) as clipPoints from dual"
            : 
            "select MDSYS.SDO_GEOMETRY(2003, 32615, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3),MDSYS.SDO_ORDINATE_ARRAY(755458.35,3678981.136, 755538.041,3679027.802)) as facet, " +
                   "MDSYS.SDO_GEOMETRY(2005, 32615, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,1,194),  MDSYS.SDO_ORDINATE_ARRAY(755445.0, 3678855.0, 755445.0, 3678865.0, 755445.0, 3678875.0, 755445.0, 3678885.0, 755445.0, 3678895.0, 755445.0, 3678905.0, 755445.0, 3678915.0, 755445.0, 3678925.0, 755445.0, 3678935.0, 755445.0, 3678945.0, 755445.0, 3678955.0, 755445.0, 3678965.0, 755445.0, 3678975.0, 755445.0, 3678985.0, 755445.0, 3678995.0, 755445.0, 3679005.0, 755445.0, 3679015.0, 755445.0, 3679025.0, 755445.0, 3679035.0, 755445.0, 3679045.0, 755455.0, 3678865.0, 755455.0, 3678875.0, 755455.0, 3678885.0, 755455.0, 3678895.0, 755455.0, 3678905.0, 755455.0, 3678915.0, 755455.0, 3678925.0, 755455.0, 3678935.0, 755455.0, 3678945.0, 755455.0, 3678955.0, 755455.0, 3678965.0, 755455.0, 3678975.0, 755455.0, 3678985.0, 755455.0, 3678995.0, 755455.0, 3679005.0, 755455.0, 3679015.0, 755455.0, 3679025.0, 755455.0, 3679035.0, 755455.0, 3679045.0, 755465.0, 3678875.0, 755465.0, 3678885.0, 755465.0, 3678895.0, 755465.0, 3678905.0, 755465.0, 3678915.0, 755465.0, 3678925.0, 755465.0, 3678935.0, 755465.0, 3678945.0, 755465.0, 3678955.0, 755465.0, 3678965.0, 755465.0, 3678975.0, 755465.0, 3678985.0, 755465.0, 3678995.0, 755465.0, 3679005.0, 755465.0, 3679015.0, 755465.0, 3679025.0, 755465.0, 3679035.0, 755465.0, 3679045.0, 755475.0, 3678885.0, 755475.0, 3678895.0, 755475.0, 3678905.0, 755475.0, 3678915.0, 755475.0, 3678925.0, 755475.0, 3678935.0, 755475.0, 3678945.0, 755475.0, 3678955.0, 755475.0, 3678965.0, 755475.0, 3678975.0, 755475.0, 3678985.0, 755475.0, 3678995.0, 755475.0, 3679005.0, 755475.0, 3679015.0, 755475.0, 3679025.0, 755475.0, 3679035.0, 755475.0, 3679045.0, 755485.0, 3678905.0, 755485.0, 3678915.0, 755485.0, 3678925.0, 755485.0, 3678935.0, 755485.0, 3678945.0, 755485.0, 3678955.0, 755485.0, 3678965.0, 755485.0, 3678975.0, 755485.0, 3678985.0, 755485.0, 3678995.0, 755485.0, 3679005.0, 755485.0, 3679015.0, 755485.0, 3679025.0, 755485.0, 3679035.0, 755485.0, 3679045.0, 755495.0, 3678915.0, 755495.0, 3678925.0, 755495.0, 3678935.0, 755495.0, 3678945.0, 755495.0, 3678955.0, 755495.0, 3678965.0, 755495.0, 3678975.0, 755495.0, 3678985.0, 755495.0, 3678995.0, 755495.0, 3679005.0, 755495.0, 3679015.0, 755495.0, 3679025.0, 755495.0, 3679035.0, 755495.0, 3679045.0, 755505.0, 3678925.0, 755505.0, 3678935.0, 755505.0, 3678945.0, 755505.0, 3678955.0, 755505.0, 3678965.0, 755505.0, 3678975.0, 755505.0, 3678985.0, 755505.0, 3678995.0, 755505.0, 3679005.0, 755505.0, 3679015.0, 755505.0, 3679025.0, 755505.0, 3679035.0, 755505.0, 3679045.0, 755515.0, 3678935.0, 755515.0, 3678945.0, 755515.0, 3678955.0, 755515.0, 3678965.0, 755515.0, 3678975.0, 755515.0, 3678985.0, 755515.0, 3678995.0, 755515.0, 3679005.0, 755515.0, 3679015.0, 755515.0, 3679025.0, 755515.0, 3679035.0, 755515.0, 3679045.0, 755525.0, 3678945.0, 755525.0, 3678955.0, 755525.0, 3678965.0, 755525.0, 3678975.0, 755525.0, 3678985.0, 755525.0, 3678995.0, 755525.0, 3679005.0, 755525.0, 3679015.0, 755525.0, 3679025.0, 755525.0, 3679035.0, 755525.0, 3679045.0, 755535.0, 3678955.0, 755535.0, 3678965.0, 755535.0, 3678975.0, 755535.0, 3678985.0, 755535.0, 3678995.0, 755535.0, 3679005.0, 755535.0, 3679015.0, 755535.0, 3679025.0, 755535.0, 3679035.0, 755535.0, 3679045.0, 755545.0, 3678965.0, 755545.0, 3678975.0, 755545.0, 3678985.0, 755545.0, 3678995.0, 755545.0, 3679005.0, 755545.0, 3679015.0, 755545.0, 3679025.0, 755545.0, 3679035.0, 755545.0, 3679045.0, 755555.0, 3678975.0, 755555.0, 3678985.0, 755555.0, 3678995.0, 755555.0, 3679005.0, 755555.0, 3679015.0, 755555.0, 3679025.0, 755555.0, 3679035.0, 755555.0, 3679045.0, 755565.0, 3678985.0, 755565.0, 3678995.0, 755565.0, 3679005.0, 755565.0, 3679015.0, 755565.0, 3679025.0, 755565.0, 3679035.0, 755565.0, 3679045.0, 755575.0, 3678995.0, 755575.0, 3679005.0, 755575.0, 3679015.0, 755575.0, 3679025.0, 755575.0, 3679035.0, 755575.0, 3679045.0, 755585.0, 3679005.0, 755585.0, 3679015.0, 755585.0, 3679025.0, 755585.0, 3679035.0, 755585.0, 3679045.0, 755595.0, 3679015.0, 755595.0, 3679025.0, 755595.0, 3679035.0, 755595.0, 3679045.0, 755605.0, 3679025.0, 755605.0, 3679035.0, 755605.0, 3679045.0, 755615.0, 3679035.0, 755615.0, 3679045.0, 755625.0, 3679045.0)) as clipPoints from dual"
            );
            DBConnection.setConnection((OracleConnection)database);
            results.next();
            STRUCT facet = ((OracleResultSet)results).getSTRUCT(1);
            try { displayCLOB("ST_AsText(facet)=",EWKTExporter.ST_AsText(facet)); } catch(Exception e) { System.out.println(e.getMessage()); }
            STRUCT clipPoints = ((OracleResultSet)results).getSTRUCT(2);
            try { displayCLOB("clipPoints(" + SDO.getNumberCoordinates(clipPoints) + ") ",EWKTExporter.ST_AsText(clipPoints)); } catch(Exception e) { System.out.println(e.getMessage()); }
            
            System.out.println("\nST_Intersection");
            STRUCT intersectedPoints = JTS.ST_Intersection(clipPoints, facet, 3);
            if (intersectedPoints != null) {
                try { displayCLOB("intersectedPoints(" + SDO.getNumberCoordinates(intersectedPoints) + ") ",EWKTExporter.ST_AsText(intersectedPoints)); } catch(Exception e) { System.out.println(e.getMessage()); }
               System.out.print("\nST_Difference(clipPoints,intersectedPoints,3)");
               
               STRUCT difference = JTS.ST_Difference(clipPoints,intersectedPoints, 0);
               System.out.println(" - Number Of Points in Result = " +  SDO.getNumberCoordinates(difference));
               if (difference != null) 
                   try { displayCLOB("difference: ",EWKTExporter.ST_AsText(difference)); } catch(Exception e) { System.out.println(e.getMessage()); }
            }
            results.close();
            statement.close();
            database.close();
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }
    }

    public static void TestFromGML() 
    throws Exception
    {
        System.out.println("TestFromGML");
        try
        {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","codesys","CODEMGR");
            DBConnection.setConnection((OracleConnection)database);
            STRUCT res = JTS.ST_GeomFromGML("<gml:Polygon xmlns:gml=\"http://www.opengis.net/gml/3.2\" gml:id=\"bp1\" srsName=\"EPSG:4326\" srsDimension=\"2\"> <gml:exterior> <gml:LinearRing><gml:posList>115.25 4.5 115.25 4.25 115.5 4.25 115.5 4.5 115.25 4.5</gml:posList></gml:LinearRing></gml:exterior></gml:Polygon>");
            if ( res == null )
                System.out.println("Could not create sdo_geometry from ST_GeomFromGML");
            else
              try { displayCLOB("result: ",EWKTExporter.ST_AsText(res)); } catch(Exception e) { System.out.println(e.getMessage()); }
            database.close();
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }   
    }
    
    private static void displayCLOB(String _prefix, CLOB _clob) 
    throws SQLException,
           IOException 
    {
        if (_clob == null ) {
            return;
        }
        String value = "";
        java.io.InputStream is = _clob.getAsciiStream();
        byte[] buffer = new byte[4096];
        java.io.OutputStream outputStream = new java.io.ByteArrayOutputStream();
        while (true) {
            int read = is.read(buffer);
            if (read == -1) {
                break;
            }
            outputStream.write(buffer, 0, read);
            }
        outputStream.close();
        is.close();
        value = _prefix + outputStream.toString();
        System.out.println(value);
    }
    
    public static void TestAsText() 
    throws Exception
    {
        System.out.println("TestAsText\n==========");
        try
        {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","GIS","GISMGR");
            DBConnection.setConnection((OracleConnection)database);

            STRUCT sGeom = null;
            String wkt = null;
            CLOB c = null;

            wkt = "SRID=4283;BOX(-32 147,-33 148)";
            System.out.println("wkt="+wkt);
            sGeom = EWKTImporter.ST_GeomFromEWKT(wkt,8307);
            System.out.println("BOX SRID is " + SDO.getSRID(sGeom) + 
                               " dimensions=" + SDO.getDimension(sGeom,-1));
            c = EWKTExporter.ST_AsEWKT(sGeom);
            try { displayCLOB("ST_AsEWKT: BOX result: ", c); } catch(Exception e) { System.out.println(e.getMessage()); }
            sGeom = null;

            wkt = "BOX3D(-32 147 45.3,-33 148 67.54)";
            System.out.println("wkt="+wkt);
            sGeom = EWKTImporter.ST_GeomFromEWKT(wkt,8307);
            System.out.println("BOX SRID is " + SDO.getSRID(sGeom) + 
                               " dimensions="    + SDO.getDimension(sGeom,-1));
            c = EWKTExporter.ST_AsEWKT(sGeom);
            try { displayCLOB("ST_AsEWKT: BOX result: ", c); } catch(Exception e) { System.out.println(e.getMessage()); }
            c = EWKTExporter.ST_AsText(sGeom);
            try { displayCLOB("ST_AsText: BOX result: ", c); } catch(Exception e) { System.out.println(e.getMessage()); }
            sGeom = null;

            sGeom = EWKTImporter.ST_GeomFromEWKT("POINTZ(-32 147 1.1)",8307);
            System.out.println("POINT (with Z) SRID is " + SDO.getSRID(sGeom) + 
            " dimensions="            + SDO.getDimension(sGeom,-1) +
            " hasZ="                  + SDO.hasZ(sGeom)  +
            " hasM="                  + SDO.hasMeasure(sGeom)
            );
            c = EWKTExporter.ST_AsEWKT(sGeom);
            try { displayCLOB("ST_AsEWKT: POINTZ: ",c); } catch(Exception e) { System.out.println(e.getMessage()); }
            sGeom = null;

            wkt = "POINTZM(-32 147 0.1 1.1)";
            sGeom = EWKTImporter.ST_GeomFromEWKT(wkt,8307);
            System.out.println("POINT (with M) SRID is " + SDO.getSRID(sGeom) + 
                               " dimensions="            + SDO.getDimension(sGeom,-1) +
                               " hasZ="                  + SDO.hasZ(sGeom)  +
                               " hasM="                  + SDO.hasMeasure(sGeom)
                               );
            try { displayCLOB("ST_AsEWKT: POINTM: ",EWKTExporter.ST_AsEWKT(sGeom)); } catch(Exception e) { System.out.println(e.getMessage()); }

            sGeom = null;            

            database.close();
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }   
    }

    public static void TestFromEWKT() 
    throws Exception
    {
        System.out.println("TestFromEWKT\n============");
        try
        {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","GIS","GISMGR");
            DBConnection.setConnection((OracleConnection)database);
            Tools.setPrecisionScale(6); 
            
            System.out.println("Construct SDO_GEOMETRY from EWKT");
            String ewkt = "SRID=8307;POLYGONZ ((-76.57418668 38.91891451 0, -76.5766114 38.91881851 0, -76.57484114 38.91758725 0, -76.57418668 38.91891451 0))";
        System.out.println(ewkt);
            STRUCT sGeom = null;
            for (int i=-1;i<2;i++) {
                sGeom = EWKTImporter.ST_GeomFromEWKT(ewkt,i==1?4283:i);
                System.out.println("SRID is " + SDO.getSRID(sGeom) + " dimensions="+SDO.getDimension(sGeom,-1));
                //STRUCT res = EWKTImporter.ST_GeomFromEWKT("POLYGON((-76.57418668270113 38.91891450597657 0, -76.57484114170074 38.91758725401061 0, -76.57661139965057 38.91881851059802 0, -76.57418668270113 38.91891450597657 0))",8307);
                //STRUCT res = JTS.ST_GeomFromEWKT("BOX(-76.57418668270113 38.91891450597657, -76.57484114170074 38.91758725401061)",8307);
                //STRUCT res = SC4O.ST_GeomFromEWKT("POINT EMPTY",8307);
                try { displayCLOB("ST_AsEWKT(sdo_geometry): ",EWKTExporter.ST_AsEWKT(sGeom)); } catch(Exception e) { System.out.println(e.getMessage()); }
            }                
             
            System.out.println("CLOB Test");
            ewkt = "SRID=8307;POLYGON ((-76.57418668 38.91891451, -76.5766114 38.91881851, -76.57484114 38.91758725, -76.57418668 38.91891451))";
            System.out.println(ewkt);
            CLOB clob = SQLConversionTools.string2Clob(ewkt);
            try { displayCLOB("ST_GeomFromEWKT: ",EWKTExporter.ST_AsEWKT(EWKTImporter.ST_GeomFromEWKT(clob))); } catch(Exception e) { System.out.println(e.getMessage()); }
            
            database.close();
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }
        
    }

    public static void TestLineMaker()     
    throws Exception
    {
        System.out.println("TestLineMaker");
        try
        {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","codesys","CODEMGR");
            Statement statement = database.createStatement();
            /* ResultSet results = statement.executeQuery(
        "select mdsys.SDO_Geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1.1,1.1,2.2,2.2,3.3,3.3)) as line from dual " + 
        "union all select mdsys.SDO_Geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(3.3,3.3,4.4,4.4)) as line from dual " + 
        "union all select mdsys.SDO_Geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(5.5,5.5,6.6,6.6)) as line from dual"); */
            ResultSet results = statement.executeQuery("select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638231.54,7954538.73,638235.33,7954554.09)) as geom from dual \n" + 
            "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638235.33,7954554.09,638231.54,7954538.73)) as geom from dual \n" + 
            "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638468.8,7954896.58,638475.76,7954881.4)) as geom from dual \n" + 
            "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638475.76,7954881.4,638468.8,7954896.58)) as geom from dual \n" + 
            "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638516.88,7954033.95,638519.55,7954026.82)) as geom from dual \n" + 
            "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638519.55,7954026.82,638516.88,7954033.95)) as geom from dual \n" + 
            "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638990.21,7954450.62,639001.62,7954445.53)) as geom from dual \n" + 
            "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(639001.62,7954445.53,638990.21,7954450.62)) as geom from dual \n" + 
            "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(639420.74,7953960.97,639430.32,7953973.29)) as geom from dual \n" + 
            "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(639430.32,7953973.29,639420.74,7953960.97)) as geom from dual \n" + 
            "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638516.88,7954033.95,638556.17,7954046.26,638478.8,7954424.3,638442.6,7954441.05,638231.54,7954538.73)) as geom from dual \n" + 
            "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638468.8,7954896.58,638442.6,7954843.36,638314.26,7954582.66,638287.67,7954528.63,638276.26,7954534.17,638235.33,7954554.09)) as geom from dual \n" + 
            "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638475.76,7954881.4,638453.5,7954836.67,638828.78,7954704.55,638769.1,7954582.66,638741.72,7954526.76,638719.24,7954480.84,638971.43,7954390.81,638990.21,7954450.62)) as geom from dual \n" + 
            "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(639430.32,7953973.29,639380.5,7953996.59,639526.83,7954192.63,639242.81,7954293.49,639242.6,7954293.99,638982.83,7954386.74,639001.62,7954445.53)) as geom from dual \n" + 
            "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638519.55,7954026.82,638698.9,7954082.66,638991.52,7954171.75,638996.74,7954168.49,639003.12,7954163.42,639017.59,7954147.08,639028.14,7954134.75,639034.33,7954127.23,639042.73,7954120.35,639051.74,7954114.53,639064.05,7954108.85,639076.59,7954107.04,639088.23,7954106.72,639093.85,7954106.11,639102.77,7954101.85,639139.16,7954082.66,639184.34,7954056.68,639187.97,7954055.01,639191.73,7954053.66,639195.59,7954052.65,639199.53,7954051.99,639203.51,7954051.68,639207.5,7954051.73,639211.48,7954052.13,639215.4,7954052.88,639219.24,7954053.98,639222.96,7954055.42,639420.74,7953960.97)) from dual");
            DBConnection.setConnection((OracleConnection)database);
            STRUCT struct = JTS.ST_LineMerger(results,2);
            if (struct != null) 
               try { displayCLOB("LineMerger Result: ",EWKTExporter.ST_AsText(struct)); } catch(Exception e) { System.out.println(e.getMessage()); }
            else
                System.out.println("linemerger result is null");
            /*
            ARRAY ary = JTS.ST_LineMerger(results,2);
            Object[] lines = (Object[])ary.getArray();
            for (int i=0;i<ary.length();i++) {
                struct = (oracle.sql.STRUCT)lines[i];
                if (struct == null)
                    continue;
                try { displayCLOB(JTS.ST_AsText(struct)); } catch(Exception e) { System.out.println(e.getMessage()); }
            }
            */
            results.close();
            statement.close();
            database.close();
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }
    }

    public static void TestInterpolateZ()     
    throws Exception
    {
        System.out.println("TestInterpolateZ");
        try
        {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","codesys","CODEMGR");
            Statement statement = database.createStatement();
            ResultSet results = statement.executeQuery(
        "select MDSYS.SDO_GEOMETRY(3003, 32615, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1), MDSYS.SDO_ORDINATE_ARRAY(755438.136705691, 3679051.52458636, 9.86999999918044, 755441.542258283, 3678850.38541675, 9.14999999944121, 755639.275877972, 3679054.93014137, 10.0, 755438.136705691, 3679051.52458636, 9.86999999918044)) as facet, " + 
        "MDSYS.SDO_GEOMETRY(2005, 32615, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,1,194), MDSYS.SDO_ORDINATE_ARRAY(755445.0, 3678855.0, 755445.0, 3678865.0, 755445.0, 3678875.0, 755445.0, 3678885.0, 755445.0, 3678895.0, 755445.0, 3678905.0, 755445.0, 3678915.0, 755445.0, 3678925.0, 755445.0, 3678935.0, 755445.0, 3678945.0, 755445.0, 3678955.0, 755445.0, 3678965.0, 755445.0, 3678975.0, 755445.0, 3678985.0, 755445.0, 3678995.0, 755445.0, 3679005.0, 755445.0, 3679015.0, 755445.0, 3679025.0, 755445.0, 3679035.0, 755445.0, 3679045.0, 755455.0, 3678865.0, 755455.0, 3678875.0, 755455.0, 3678885.0, 755455.0, 3678895.0, 755455.0, 3678905.0, 755455.0, 3678915.0, 755455.0, 3678925.0, 755455.0, 3678935.0, 755455.0, 3678945.0, 755455.0, 3678955.0, 755455.0, 3678965.0, 755455.0, 3678975.0, 755455.0, 3678985.0, 755455.0, 3678995.0, 755455.0, 3679005.0, 755455.0, 3679015.0, 755455.0, 3679025.0, 755455.0, 3679035.0, 755455.0, 3679045.0, 755465.0, 3678875.0, 755465.0, 3678885.0, 755465.0, 3678895.0, 755465.0, 3678905.0, 755465.0, 3678915.0, 755465.0, 3678925.0, 755465.0, 3678935.0, 755465.0, 3678945.0, 755465.0, 3678955.0, 755465.0, 3678965.0, 755465.0, 3678975.0, 755465.0, 3678985.0, 755465.0, 3678995.0, 755465.0, 3679005.0, 755465.0, 3679015.0, 755465.0, 3679025.0, 755465.0, 3679035.0, 755465.0, 3679045.0, 755475.0, 3678885.0, 755475.0, 3678895.0, 755475.0, 3678905.0, 755475.0, 3678915.0, 755475.0, 3678925.0, 755475.0, 3678935.0, 755475.0, 3678945.0, 755475.0, 3678955.0, 755475.0, 3678965.0, 755475.0, 3678975.0, 755475.0, 3678985.0, 755475.0, 3678995.0, 755475.0, 3679005.0, 755475.0, 3679015.0, 755475.0, 3679025.0, 755475.0, 3679035.0, 755475.0, 3679045.0, 755485.0, 3678905.0, 755485.0, 3678915.0, 755485.0, 3678925.0, 755485.0, 3678935.0, 755485.0, 3678945.0, 755485.0, 3678955.0, 755485.0, 3678965.0, 755485.0, 3678975.0, 755485.0, 3678985.0, 755485.0, 3678995.0, 755485.0, 3679005.0, 755485.0, 3679015.0, 755485.0, 3679025.0, 755485.0, 3679035.0, 755485.0, 3679045.0, 755495.0, 3678915.0, 755495.0, 3678925.0, 755495.0, 3678935.0, 755495.0, 3678945.0, 755495.0, 3678955.0, 755495.0, 3678965.0, 755495.0, 3678975.0, 755495.0, 3678985.0, 755495.0, 3678995.0, 755495.0, 3679005.0, 755495.0, 3679015.0, 755495.0, 3679025.0, 755495.0, 3679035.0, 755495.0, 3679045.0, 755505.0, 3678925.0, 755505.0, 3678935.0, 755505.0, 3678945.0, 755505.0, 3678955.0, 755505.0, 3678965.0, 755505.0, 3678975.0, 755505.0, 3678985.0, 755505.0, 3678995.0, 755505.0, 3679005.0, 755505.0, 3679015.0, 755505.0, 3679025.0, 755505.0, 3679035.0, 755505.0, 3679045.0, 755515.0, 3678935.0, 755515.0, 3678945.0, 755515.0, 3678955.0, 755515.0, 3678965.0, 755515.0, 3678975.0, 755515.0, 3678985.0, 755515.0, 3678995.0, 755515.0, 3679005.0, 755515.0, 3679015.0, 755515.0, 3679025.0, 755515.0, 3679035.0, 755515.0, 3679045.0, 755525.0, 3678945.0, 755525.0, 3678955.0, 755525.0, 3678965.0, 755525.0, 3678975.0, 755525.0, 3678985.0, 755525.0, 3678995.0, 755525.0, 3679005.0, 755525.0, 3679015.0, 755525.0, 3679025.0, 755525.0, 3679035.0, 755525.0, 3679045.0, 755535.0, 3678955.0, 755535.0, 3678965.0, 755535.0, 3678975.0, 755535.0, 3678985.0, 755535.0, 3678995.0, 755535.0, 3679005.0, 755535.0, 3679015.0, 755535.0, 3679025.0, 755535.0, 3679035.0, 755535.0, 3679045.0, 755545.0, 3678965.0, 755545.0, 3678975.0, 755545.0, 3678985.0, 755545.0, 3678995.0, 755545.0, 3679005.0, 755545.0, 3679015.0, 755545.0, 3679025.0, 755545.0, 3679035.0, 755545.0, 3679045.0, 755555.0, 3678975.0, 755555.0, 3678985.0, 755555.0, 3678995.0, 755555.0, 3679005.0, 755555.0, 3679015.0, 755555.0, 3679025.0, 755555.0, 3679035.0, 755555.0, 3679045.0, 755565.0, 3678985.0, 755565.0, 3678995.0, 755565.0, 3679005.0, 755565.0, 3679015.0, 755565.0, 3679025.0, 755565.0, 3679035.0, 755565.0, 3679045.0, 755575.0, 3678995.0, 755575.0, 3679005.0, 755575.0, 3679015.0, 755575.0, 3679025.0, 755575.0, 3679035.0, 755575.0, 3679045.0, 755585.0, 3679005.0, 755585.0, 3679015.0, 755585.0, 3679025.0, 755585.0, 3679035.0, 755585.0, 3679045.0, 755595.0, 3679015.0, 755595.0, 3679025.0, 755595.0, 3679035.0, 755595.0, 3679045.0, 755605.0, 3679025.0, 755605.0, 3679035.0, 755605.0, 3679045.0, 755615.0, 3679035.0, 755615.0, 3679045.0, 755625.0, 3679045.0)) as clipPoints from dual");
            DBConnection.setConnection((OracleConnection)database);
            results.next();
            STRUCT st1 = ((OracleResultSet)results).getSTRUCT(1);
            try { displayCLOB("st1: ",EWKTExporter.ST_AsText(st1)); } catch(Exception e) { System.out.println(e.getMessage()); }
            STRUCT st2 = ((OracleResultSet)results).getSTRUCT(2);
            try { displayCLOB("st2: ",EWKTExporter.ST_AsText(st2)); } catch(Exception e) { System.out.println(e.getMessage()); }
            STRUCT result = JTS.ST_InterpolateZ(st2, st1);
            if (result != null) 
               try { displayCLOB("result: ",EWKTExporter.ST_AsText(result)); } catch(Exception e) { System.out.println(e.getMessage()); }

            results.close();
            statement.close();
            database.close();
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }
    }

    public static void TestAddPoint()
        throws Exception
    {
        System.out.println("TestAddPoint");
        try
        {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","GIS","GISMGR");
            Statement statement = database.createStatement();
            ResultSet results = statement.executeQuery(
// "select mdsys.SDO_Geometry(2005,null,null,sdo_elem_info_array(1,1,3),sdo_ordinate_array(1.12345,1.3445,2.43534,2.03998398,3.43513,3.451245)) as geom," +
"select mdsys.SDO_Geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1.12345,1.3445,2.43534,2.03998398,3.43513,3.451245)) as geom," +
      " mdsys.SDO_Geometry(2001,null,sdo_point_type(4.4,4.5,null),null,null) as point" +
"  from dual");
            DBConnection.setConnection((OracleConnection)database);
            results.next();
            STRUCT st1 = ((OracleResultSet)results).getSTRUCT(1);
            try { displayCLOB("st1: ",EWKTExporter.ST_AsText(st1)); } catch(Exception e) { System.out.println(e.getMessage()); }
            STRUCT st2 = ((OracleResultSet)results).getSTRUCT(2);
            try { displayCLOB("st2: ",EWKTExporter.ST_AsText(st2)); } catch(Exception e) { System.out.println(e.getMessage()); }
            STRUCT result = null;
            for (int i=1;i<=3;i++) {
                System.out.println("Add at Position " + i);
                result = JTS.ST_InsertPoint(st1,st2,i);
                try { displayCLOB("result: ",EWKTExporter.ST_AsText(result)); } catch(Exception e) { System.out.println(e.getMessage()); }
            }
            System.out.println("Position -1");
            result = JTS.ST_InsertPoint(st1,st2,-1);
            try { displayCLOB("Result: ",EWKTExporter.ST_AsText(result)); } catch(Exception e) { System.out.println(e.getMessage()); }
            results.close();
            statement.close();
            database.close();
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }
    }
    
    public static void TestRemovePoint()
        throws Exception
    {
        System.out.println("TestRemovePoint");
        try
        {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","GIS","GISMGR");
            Statement statement = database.createStatement();
            DBConnection.setConnection((OracleConnection)database);
            // ResultSet results = statement.executeQuery("select mdsys.SDO_Geometry(2005,null,null,sdo_elem_info_array(1,1,3),sdo_ordinate_array(1.12345,1.3445,2.43534,2.03998398,3.43513,3.451245)) as geom from dual");
                           
            System.out.println("Delete point from single point");
            ResultSet results = statement.executeQuery("SELECT mdsys.SDO_Geometry(3001,null,null,sdo_elem_info_array(1,1,1),sdo_ordinate_array(1.1,2.4,3.5)) as geom FROM dual");
            results.next();
            STRUCT st1 = ((OracleResultSet)results).getSTRUCT(1);
            try { displayCLOB("... st1: ",EWKTExporter.ST_AsText(st1)); } catch(Exception e) { System.out.println(e.getMessage()); }
            STRUCT result = null;
            try { result = JTS.ST_DeletePoint(st1,1); displayCLOB("... Result: ",EWKTExporter.ST_AsText(result)); } catch(Exception e) { System.out.println(e.getMessage()); }
            results.close();

            System.out.println("Delete point from 2 point linestring");
            results = statement.executeQuery("select mdsys.sdo_geometry('LINESTRING(1.1 1.1,2.2 2.2)',null) as geom from dual");
            results.next();
            st1 = ((OracleResultSet)results).getSTRUCT(1);
            try { displayCLOB("st1: ",EWKTExporter.ST_AsText(st1)); } catch(Exception e) { System.out.println(e.getMessage()); }
            try { result = JTS.ST_DeletePoint(st1,1); displayCLOB("... Result: ",EWKTExporter.ST_AsText(result)); } catch(Exception e) { System.out.println(e.getMessage()); } 
            results.close();

            System.out.println("Deleting each point in a multipoint");
            results = statement.executeQuery("select mdsys.SDO_Geometry(2005,null,null,sdo_elem_info_array(1,1,3),sdo_ordinate_array(1.1,1.1,2.2,2.2,3.2,3.2)) as geom from dual");
            results.next();
            st1 = ((OracleResultSet)results).getSTRUCT(1);
            try { displayCLOB("... st1: ",EWKTExporter.ST_AsText(st1)); } catch(Exception e) { System.out.println(e.getMessage()); }
            result = null;
            int pointN = 0;
            for (int i=1;i<=4;i++) {
                pointN = i;
                if ( i == 4 ) 
                    pointN = -1;
                System.out.println("......  Remove at Position " + pointN);
                result = JTS.ST_DeletePoint(st1,pointN);
                try { displayCLOB(".........   Result: ",EWKTExporter.ST_AsText(result)); } catch(Exception e) { System.out.println(e.getMessage()); }
            }
            results.close();

            System.out.println("Deleting each point in a multi-point linestring");
            results = statement.executeQuery("select mdsys.SDO_Geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1.12345,1.3445,2.43534,2.03998398,3.43513,3.451245)) as geom from dual");
            results.next();
            st1 = ((OracleResultSet)results).getSTRUCT(1);
            try { displayCLOB("... st1: ",EWKTExporter.ST_AsText(st1)); } catch(Exception e) { System.out.println(e.getMessage()); }
            result = null;
            for (int i=1;i<=3;i++) {
                System.out.println("......  Remove at Position " + i);
                result = JTS.ST_DeletePoint(st1,i);
                try { displayCLOB(".........   Result: ",EWKTExporter.ST_AsText(result)); } catch(Exception e) { System.out.println(e.getMessage()); }
            }
            System.out.println("... Remove at Position -1");
            result = JTS.ST_DeletePoint(st1,-1);
            try { displayCLOB("......  Result: ",EWKTExporter.ST_AsText(result)); } catch(Exception e) { System.out.println(e.getMessage()); }
            results.close();
            
            results = statement.executeQuery("select sdo_geometry('POLYGON((2 2, 12 2, 12 7, 2 7, 2 2))',NULL) as geom from dual");
            results.next();
            st1 = ((OracleResultSet)results).getSTRUCT(1);
            try { displayCLOB("st1: ",EWKTExporter.ST_AsText(st1)); } catch(Exception e) { System.out.println(e.getMessage()); }
            result = JTS.ST_DeletePoint(st1,3);
            try { displayCLOB("... Result: ",EWKTExporter.ST_AsText(result)); } catch(Exception e) { System.out.println(e.getMessage()); }            
            statement.close();
            database.close();
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }
    }

    public static void TestUpdatePoint()
        throws Exception
    {
        System.out.println("TestSTUpdate");
        try
        {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","GIS","GISMGR");
            Statement statement = database.createStatement();
            ResultSet results = statement.executeQuery(
//            "select mdsys.SDO_Geometry(2005,null,null,sdo_elem_info_array(1,1,3),sdo_ordinate_array(1.12345,1.3445,2.43534,2.03998398,3.43513,3.451245)),\n" + 
            "select mdsys.SDO_Geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1.12345,1.3445,2.43534,2.03998398,3.43513,3.451245)),\n" + 
            "       mdsys.SDO_Geometry(2001,null,sdo_point_type(3.43513,3.451245,null),null,null),\n" + 
            "       mdsys.SDO_Geometry(2001,null,sdo_point_type(4.555,4.666,null),null,null)\n" + 
            "  from dual");
            DBConnection.setConnection((OracleConnection)database);
            results.next();
            
            STRUCT st1 = ((OracleResultSet)results).getSTRUCT(1);
            try { displayCLOB("st1: ",EWKTExporter.ST_AsText(st1)); } catch(Exception e) { System.out.println(e.getMessage()); }
            STRUCT st2 = ((OracleResultSet)results).getSTRUCT(2);
            try { displayCLOB("st2: ",EWKTExporter.ST_AsText(st2)); } catch(Exception e) { System.out.println(e.getMessage()); }
            STRUCT st3 = ((OracleResultSet)results).getSTRUCT(3);
            try { displayCLOB("st3: ",EWKTExporter.ST_AsText(st3)); } catch(Exception e) { System.out.println(e.getMessage()); }
            
            STRUCT result = null;
            System.out.println("Update 3.43513,3.451245 to 4.555,4.666");
            result = JTS.ST_UpdatePoint(st1,st2,st3);
            try { displayCLOB("Result: ",EWKTExporter.ST_AsText(result)); } catch(Exception e) { System.out.println(e.getMessage()); }
            
            for (int i=1;i<=3;i++) {
                System.out.println("Set at Position " + i);
                result = JTS.ST_UpdatePoint(st1,st2,i);
                try { displayCLOB("Result: ",EWKTExporter.ST_AsText(result)); } catch(Exception e) { System.out.println(e.getMessage()); }
            }
            System.out.println("Set at Position -1");
            result = JTS.ST_UpdatePoint(st1,st2,-1);
            try { displayCLOB("Result: ",EWKTExporter.ST_AsText(result)); } catch(Exception e) { System.out.println(e.getMessage()); }

            results.close();
            statement.close();
            database.close();
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }
    }

  public static void TestPolygonBuilder()
      throws Exception
  {
      System.out.println("TestPolygonBuilder");
      try
      {
          Class.forName("oracle.jdbc.driver.OracleDriver");
          Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","GIS","GISMGR");
          Statement statement = database.createStatement();
          // ResultSet results = statement.executeQuery("select mdsys.sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,10,10)) as geom from dual");
          ResultSet results = statement.executeQuery("select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638235.33,7954554.09,638231.54,7954538.73)) as geom from dual \n" +
          "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638475.76,7954881.4,638468.8,7954896.58)) as geom from dual \n" +
          "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638516.88,7954033.95,638519.55,7954026.82)) as geom from dual \n" +
          "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(639001.62,7954445.53,638990.21,7954450.62)) as geom from dual \n" +
          "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(639420.74,7953960.97,639430.32,7953973.29)) as geom from dual \n" +
          "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638516.88,7954033.95,638556.17,7954046.26,638478.8,7954424.3,638442.6,7954441.05,638231.54,7954538.73)) as geom from dual \n" + 
          "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638468.8,7954896.58,638442.6,7954843.36,638314.26,7954582.66,638287.67,7954528.63,638276.26,7954534.17,638235.33,7954554.09)) as geom from dual \n" + 
          "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638475.76,7954881.4,638453.5,7954836.67,638828.78,7954704.55,638769.1,7954582.66,638741.72,7954526.76,638719.24,7954480.84,638971.43,7954390.81,638990.21,7954450.62)) as geom from dual \n" + 
          "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(639430.32,7953973.29,639380.5,7953996.59,639526.83,7954192.63,639242.81,7954293.49,639242.6,7954293.99,638982.83,7954386.74,639001.62,7954445.53)) as geom from dual \n" + 
          "union all select SDO_GEOMETRY(2002,29182,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638519.55,7954026.82,638698.9,7954082.66,638991.52,7954171.75,638996.74,7954168.49,639003.12,7954163.42,639017.59,7954147.08,639028.14,7954134.75,639034.33,7954127.23,639042.73,7954120.35,639051.74,7954114.53,639064.05,7954108.85,639076.59,7954107.04,639088.23,7954106.72,639093.85,7954106.11,639102.77,7954101.85,639139.16,7954082.66,639184.34,7954056.68,639187.97,7954055.01,639191.73,7954053.66,639195.59,7954052.65,639199.53,7954051.99,639203.51,7954051.68,639207.5,7954051.73,639211.48,7954052.13,639215.4,7954052.88,639219.24,7954053.98,639222.96,7954055.42,639420.74,7953960.97)) from dual");
//"select mdsys.sdo_geometry(2002,82469,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(t.startCoord.x,t.startCoord.y,t.endCoord.x,t.endCoord.y)) as line \n" + 
//"  from table(geom.getVector(geom.rectangle2polygon(mdsys.sdo_geometry(2003,82469,NULL,sdo_elem_info_array(1,1003,3),sdo_ordinate_array(1,1,10,10))),0.05)) t");
          DBConnection.setConnection((OracleConnection)database);
          STRUCT struct = JTS.ST_PolygonBuilder(results,1);
          if (struct != null) 
             try { displayCLOB("PolygonBuilder Result: ",EWKTExporter.ST_AsText(struct)); } catch(Exception e) { System.out.println(e.getMessage()); }
          else
              System.out.println("PolygonBuilder result is null");
          results.close();
          statement.close();
          database.close();
      }
      catch(Exception e)
      {
          e.printStackTrace();
      }
  }

    public static void Dissolve()
    {
        int _numDecPlaces = 2;
        try
        {            
            double scale = Math.pow(10, _numDecPlaces);
            PrecisionModel  pm = new PrecisionModel(scale);
            
            WKTReader wktr = new WKTReader();
            Geometry line1 = wktr.read("LINESTRING (548845.37 3956342.94, 548840.24 3956243.07, 548861.63 3956241.98, 548881.28 3956242.9, 548900.36 3956247.66, 548918.14 3956256.06, 548933.94 3956267.77, 548947.13 3956282.36, 548957.22 3956299.24, 548963.81 3956317.77, 548966.65 3956337.23, 548965.62 3956356.87, 548960.77 3956375.93, 548952.28 3956393.67, 548940.48 3956409.4, 548925.83 3956422.53, 548825.48 3956496.01,548766.41  3956415.33,  548866.75  3956341.84,  548845.37  3956342.94)");
            Geometry line2 = wktr.read("LINESTRING (548845.371 3956342.942, 548866.753 3956341.844, 548766.411 3956415.332)");

            line1 = GeometryPrecisionReducer.reduce(line1,pm);
            line2 = GeometryPrecisionReducer.reduce(line2,pm);
            Geometry rLine = line1.difference(line2);

            WKTWriter wktw = new WKTWriter(2);
            String rLineWkt = wktw.write(rLine);
            System.out.println(rLineWkt);

        } catch (Exception e) {
        }
    }
    
    public static void TestRelate()
    {
        STRUCT sGeom1 = null;
        STRUCT sGeom2 = null;
        for (int i=0;i<=5; i++)
        try
        {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","GIS","GISMGR");
            DBConnection.setConnection((OracleConnection)database);

            sGeom1 = EWKTImporter.ST_GeomFromEWKT("POINT (250.001 150.0)",0);
            sGeom2 = EWKTImporter.ST_GeomFromEWKT("POINT (250.0   150.002)",0);
            String mask=i==5 ? "0FFFFFFF2" : "EQUAL";
            String result = Comparitor.ST_Relate(sGeom1,mask,sGeom2,i==5?2:i);
            System.out.println("Precision " + String.valueOf(i) + ", mask " + mask + " result: " + result);

        } catch (Exception e) {
        }
    }
    
    public static void ST_LineDissolver(int _digitsOfPrecision) 
    throws Exception
    {
        System.out.println("ST_LineDissolver");
        try
        {
          Class.forName("oracle.jdbc.driver.OracleDriver");
          Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","GIS","GISMGR");
          DBConnection.setConnection((OracleConnection)database);

          STRUCT sLine1 = null;
          STRUCT sLine2 = null;

          sLine1 = EWKTImporter.ST_GeomFromEWKT("LINESTRING (548831.667 3956474.449, 548832.593 3956429.519, 548833.519 3956408.676, 548827.498 3956391.074, 548812.213 3956381.347, 548797.854 3956385.053, 548804.338 3956402.191, 548818.697 3956406.823, 548833.519 3956408.676)",32639);
            // "LINESTRING (548845.37 3956342.94, 548840.24 3956243.07, 548861.63 3956241.98, 548881.28 3956242.9, 548900.36 3956247.66, 548918.14 3956256.06, 548933.94 3956267.77, 548947.13 3956282.36, 548957.22 3956299.24, 548963.81 3956317.77, 548966.65 3956337.23, 548965.62 3956356.87, 548960.77 3956375.93, 548952.28 3956393.67, 548940.48 3956409.4, 548925.83 3956422.53, 548825.48 3956496.01,548766.41  3956415.33,  548866.75  3956341.84,  548845.37  3956342.94)",32639);
          sLine2 = EWKTImporter.ST_GeomFromEWKT("LINESTRING (548804.338 3956402.191, 548818.697 3956406.823, 548833.519 3956408.676)",32639);
            // "LINESTRING (548845.371 3956342.942, 548866.753 3956341.844, 548766.411 3956415.332)",32639);
            
          STRUCT result = JTS.ST_LineDissolver(
                    /* _line1              */ sLine1,
                    /* _line2              */ sLine2,
                    /* _precision          */ _digitsOfPrecision,
                    /* _keepBoundaryPoints */ 0
                  );
            
          if (result != null) {
             try { displayCLOB(".... result is ",EWKTExporter.ST_AsEWKT(result)); } catch(Exception e) { System.out.println(e.getMessage()); }
          } else {
              System.out.println("ST_LineDissolver failed.");
          }
        }
        catch(Exception e)
        {
          e.printStackTrace();
        }
    }
    
    public static void ST_OffsetLine(double _offset,
                                     int    _digitsOfPrecision)
    throws Exception
    {
        System.out.println("ST_OffsetLine");
        try
        {
          Class.forName("oracle.jdbc.driver.OracleDriver");
          Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","codesys","codemgr");
          DBConnection.setConnection((OracleConnection)database);

          STRUCT sGeom = EWKTImporter.ST_GeomFromEWKT("LINESTRING (548845.366 3956342.941, 548866.753 3956341.844, 548766.398 3956415.329)",32639);
    
          STRUCT result = JTS.ST_OffsetLine(
                    /* _geom          */ sGeom,
                    /* _distance      */ _offset,
                    /* _precision     */ _digitsOfPrecision,
                    /* _endCapStyle   */ 1,
                    /* _joinStyle     */ 1,
                    /* _quadrantSegs  */ 8
                  );
          if (result != null) {
             try { displayCLOB("ST_OffsetLine Result: ",EWKTExporter.ST_AsEWKT(result)); } catch(Exception e) { System.out.println(e.getMessage()); }
          } else {
              System.out.println("No Offset Line created.");
          }
      }
      catch(Exception e)
      {
          e.printStackTrace();
      }
  }

    public static void ST_OneSidedBuffer(double _offset,
                                         int    _digitsOfPrecision)
    throws Exception
    {
        System.out.println("ST_OneSidedBuffer");
        try
        {
          Class.forName("oracle.jdbc.driver.OracleDriver");
          Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","codesys","codemgr");
          DBConnection.setConnection((OracleConnection)database);

          STRUCT sGeom = EWKTImporter.ST_GeomFromEWKT("LINESTRING (548845.366 3956342.941, 548866.753 3956341.844, 548766.398 3956415.329)",32639);
    
          STRUCT result = JTS.ST_OneSidedBuffer(
                    /* _geom          */ sGeom,
                    /* _distance      */ _offset,
                    /* _precision     */ _digitsOfPrecision,
                    /* _endCapStyle   */ 1,
                    /* _joinStyle     */ 1,
                    /* _quadrantSegs  */ 8
                  );
          if (result != null) {
             try { displayCLOB("ST_OneSidedBuffer Result: ",EWKTExporter.ST_AsEWKT(result)); } catch(Exception e) { System.out.println(e.getMessage()); }
          } else {
              System.out.println("No Offset Buffer created.");
          }
      }
      catch(Exception e)
      {
          e.printStackTrace();
      }
    }

    public static void ST_Buffer(double _offset,
                                 int    _digitsOfPrecision)
    throws Exception
    {
        System.out.println("ST_Buffer");
        try
        {
          Class.forName("oracle.jdbc.driver.OracleDriver");
          Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12","codesys","codemgr");
          DBConnection.setConnection((OracleConnection)database);
          String wkt;
          STRUCT sGeom;
          STRUCT result;
          for (int i=0; i<2;i++) {
                wkt = (i==0) 
                    ? "LINESTRING (548845.366 3956342.941, 548866.753 3956341.844, 548766.398 3956415.329)"
                    : "POINT(548845.366 3956342.941)";
              sGeom = EWKTImporter.ST_GeomFromEWKT(wkt,28355);    
              result = JTS.ST_Buffer(
                    /* _geom          */ sGeom,
                    /* _distance      */ Math.abs(_offset),
                    /* _precision     */ _digitsOfPrecision,
                    /* _endCapStyle   */ 1,
                    /* _joinStyle     */ 1,
                    /* _quadrantSegs  */ 8
                  );
              if (result != null) {
                  try { displayCLOB("ST_Buffer Result: ",EWKTExporter.ST_AsEWKT(result)); } catch(Exception e) { System.out.println(e.getMessage()); }
              } else {
                  System.out.println("No Buffer created.");
              }
          }
      }
      catch(Exception e)
      {
          e.printStackTrace();
      }
    }

    public static void TestPointLineIntersection()
        throws Exception
    {
        System.out.println("TestPointLineIntersection");
        try
        {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12", "codesys", "CODEMGR");
            Statement statement = database.createStatement();
            ResultSet results = statement.executeQuery("SELECT MDSYS.SDO_GEOMETRY(2001, 28355, MDSYS.SDO_POINT_TYPE(548810.444888164,3956383.07564365,NULL), NULL, NULL) as GEOM1, " +
                                                       "       MDSYS.SDO_GEOMETRY(2002, 28355, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1), MDSYS.SDO_ORDINATE_ARRAY(548766.398, 3956415.329, 548866.753, 3956341.844, 548845.366, 3956342.941)) as GEOM2 " +
                                                       "  FROM DUAL");
            results.next();
            STRUCT geom1 = (STRUCT)results.getObject("GEOM1");
            STRUCT geom2 = (STRUCT)results.getObject("GEOM2");
            results.close();
            statement.close();
            DBConnection.setConnection((OracleConnection)database);
            STRUCT result = JTS.ST_Intersection(geom1, geom2, 1);
            database.close();
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }
    }

    public static void TestLineLine(int opType)
        throws Exception
    {
        System.out.println("TestLineLine");
        try
        {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12", "codesys", "CODEMGR");
            Statement statement = database.createStatement();
            ResultSet results = statement.executeQuery(
            "SELECT mdsys.sdo_geometry(4302,8307,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(0,0,2,3,50,50,100,200)) as GEOM1," +
            "       mdsys.sdo_geometry(4302,8307,NULL,SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(25,0,4,5,0,50,150,180)) as GEOM2 FROM DUAL");
            results.next();
            STRUCT geom1 = (STRUCT)results.getObject("GEOM1");
            STRUCT geom2 = (STRUCT)results.getObject("GEOM2");
            results.close();
            statement.close();
            DBConnection.setConnection((OracleConnection)database);
            STRUCT result = null;
            if ( opType == 1 ) {
                result = JTS.ST_Intersection(geom1, geom2, 3);
            } else {
                result = JTS.ST_Union(geom1, geom2, 3);
            }
            System.out.println(SDO.getGType(result,0));
            displayCLOB("Result: ",EWKTExporter.ST_AsEWKT(result));
            database.close();
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }
    }

    public static void TestInvalid() 
    throws Exception
    {
      System.out.println("TestInvalid");
      try {
          Class.forName("oracle.jdbc.driver.OracleDriver");
          Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12", "codesys", "CODEMGR");
          Statement statement = database.createStatement();
          ResultSet results = statement.executeQuery("select SDO_GEOMETRY(2003, NULL, NULL, MDSYS.SDO_ELEM_INFO_ARRAY (1,1003,3, 5,2003,3), MDSYS.SDO_ORDINATE_ARRAY (50,135, 60,140, 51,136, 59,139)) GEOM1, \n" + 
                                                     "       SDO_GEOMETRY(2003, NULL, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1), MDSYS.SDO_ORDINATE_ARRAY(58.048, 137.595, 60.758, 139.284, 57.744, 138.276, 60.709, 138.324, 58.048, 137.595)) GEOM2 \n" + 
                                                     "  from dual");
          results.next();
          STRUCT geom1 = (STRUCT)results.getObject("GEOM1");
          STRUCT geom2 = (STRUCT)results.getObject("GEOM2");
          results.close();
          statement.close();
          DBConnection.setConnection((OracleConnection)database);
          STRUCT result = JTS.ST_Union(geom1, geom2, 2);
          database.close();
      }
      catch(Exception e)
      {
          System.out.println(e.getMessage());
      }
    }
    
    public static void TestUnion()
        throws Exception
    {
        System.out.println("TestUnion");
        try
        {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12", "codesys", "CODEMGR");
            Statement statement = database.createStatement();
            ResultSet results = statement.executeQuery("SELECT mdsys.sdo_geometry(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3),SDO_ORDINATE_ARRAY(0,0,100,100)) as GEOM1, " +
                                                       "       mdsys.sdo_geometry(2003,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1003,3),SDO_ORDINATE_ARRAY(50,50,150,150)) as GEOM2 " +
                                                       "  FROM DUAL");
            results.next();
            STRUCT geom1 = (STRUCT)results.getObject("GEOM1");
            STRUCT geom2 = (STRUCT)results.getObject("GEOM2");
            results.close();
            statement.close();
            DBConnection.setConnection((OracleConnection)database);
            STRUCT result = JTS.ST_Union(geom1, geom2, 2);
            database.close();
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }
    }

    public static void RegularGrid(double llX, double llY, double urX, double urY, int tileX, int tileY)
    {
        System.out.println("RegularGrid");
        try {
          Class.forName("oracle.jdbc.driver.OracleDriver");
          Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12", "codesys", "CODEMGR");
          Statement statement = database.createStatement();
          DBConnection.setConnection((OracleConnection)database);

          int v_loCol = (int)(llX / (double)tileX);
          int v_hiCol = (int)Math.ceil(urX / (double)tileX) - 1;
          int v_loRow = (int)(llY / (double)tileY);
          int v_hiRow = (int)Math.ceil(urY / (double)tileY) - 1;
          try { statement.execute("drop table peano"); } catch (SQLException sqle) { sqle.printStackTrace();}
          statement.execute("create table peano(id integer, label varchar2(20), peano integer, morton integer, geom sdo_geometry)");
          int i = 0;
          for(int v_col = v_loCol; v_col <= v_hiCol; v_col++)
          {
              for(int v_row = v_loRow; v_row <= v_hiRow; v_row++)
              {
                  i++;
                  statement.execute("insert into peano values(" + 
                                    i + ",'" +
                                    String.valueOf(Space.Peano(v_row, v_col)) + "/" + String.valueOf(Space.Morton(v_row, v_col)) + "'," +
                                    Space.Peano(v_row, v_col) + "," + 
                                    Space.Morton(v_row, v_col) + 
                                    ",sdo_geometry(2003,null,mdsys.sdo_point_type(" +
                                    String.valueOf(((v_col * tileX) + (v_col * tileX + tileX)) / 2f) + "," +
                                    String.valueOf( ( (v_row * tileY) + (v_row * tileY + tileY)) / 2f) + 
                                    ",null),sdo_elem_info_array(1,1003,3),sdo_ordinate_array("+ 
                                    (v_col * tileX) + "," + 
                                    (v_row * tileY) + "," + 
                                    (v_col * tileX + tileX) + "," + 
                                    (v_row * tileY + tileY) + ")))");
              }
          }
          statement.close();
          if ( ! database.getAutoCommit() ) database.commit();
          database.close();
      }
      catch(Exception e)
      {
        e.printStackTrace();
      }
    }

    public static void TestLineSimplifier(int which) 
    throws Exception
    {
        System.out.println("\nTestLineSimplifier\n==================");
        try {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            OracleConnection database = (OracleConnection)DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12", "codesys", "CODEMGR");
            DBConnection.setConnection(database);
            STRUCT oGeom = EWKTImporter.ST_GeomFromEWKT("SRID=29182;LINESTRING (638519.55 7954026.82, 638698.9 7954082.66, 638991.52 7954171.75, 638996.74 7954168.49, 639003.12 7954163.42, 639017.59 7954147.08, 639028.14 7954134.75, 639034.33 7954127.23, 639042.73 7954120.35, 639051.74 7954114.53, 639064.05 7954108.85, 639076.59 7954107.04, 639088.23 7954106.72, 639093.85 7954106.11, 639102.77 7954101.85, 639139.16 7954082.66, 639184.34 7954056.68, 639187.97 7954055.01, 639191.73 7954053.66, 639195.59 7954052.65, 639199.53 7954051.99, 639203.51 7954051.68, 639207.5 7954051.73, 639211.48 7954052.13, 639215.4 7954052.88, 639219.24 7954053.98, 639222.96 7954055.42, 639420.74 7953960.97)");
            displayCLOB("LineString BEFORE Simplification ",EWKTExporter.ST_AsEWKT(oGeom)); 
            STRUCT sGeom;
            if (which == 1) {
                sGeom = JTS.ST_DouglasPeuckerSimplifier(oGeom, 20, 2);
            } else {
                sGeom = JTS.ST_VisvalingamWhyattSimplifier(oGeom, 20, 2);
            }
            displayCLOB("LineString AFTER Simplification ",EWKTExporter.ST_AsEWKT(sGeom)); 
         }
         catch(Exception e)
         {
              System.out.println(e.getMessage());
         }
    }
    
    public static void TestStruct()
        throws Exception
    {
        System.out.println("TestConversion");
        try
        {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            OracleConnection database = (OracleConnection)DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB12", "spdba", "sPdbA");
            Statement statement = database.createStatement();
            DBConnection.setConnection(database);
            ResultSet results = statement.executeQuery(
              "select 1 as gid, SDO_GEOMETRY(2002,29182,MDSYS.SDO_POINT_TYPE(638254,7954500,NULL),SDO_ELEM_INFO_ARRAY(1,2,1),SDO_ORDINATE_ARRAY(638231.54,7954538.73,638235.33,7954554.09)) as geom from dual"
           );
            // Convert Geometries
            //
            PrecisionModel      pm = new PrecisionModel(Tools.getPrecisionScale(2));
            GeometryFactory     gf = new GeometryFactory(pm); 
            OraWriter           ow = new OraWriter();
            OraReader           or = new OraReader(gf);
            Geometry           geo = null;
                
            Tools.setPrecisionScale(3);
            Integer gid = -1;
            int i=0;
            Struct geom = null;
            while (results.next()) {
                try {
                    gid  = ((BigDecimal)results.getObject("GID")).intValue();
                    System.out.println("Testing geometry gid=" + gid);
                    geom = (Struct)results.getObject("GEOM");
                    int SRID      = getSRID(geom,-1);
                    int GTYPE     = getGType(geom, 2001);
                    int FullGType = getFullGType(geom, 2001);
                    int DIM       = getDimension(geom,2);
                    System.out.println(DIM + "D geometry of type " + GTYPE + " (" + FullGType + ") read from result set.");
                    or.setDimension(DIM); 
                    geo = or.read((STRUCT)geom);
                    System.out.println("    Geometry Read from SDO_GEOMETRY has type " + geo.getGeometryType() + " with dimension " + DIM + ". is Valid?=" + geo.isValid() );
                    // Now Convert from JTS Geometry to SDO_GEOMETRY
                    Struct jGeom = null;
                    ow.setDimension(DIM);
                    ow.setSRID(SRID);
                    jGeom = (Struct)ow.write(geo,database);
                    displayCLOB("     JTS oraWriter STRUCT (" + SDO.getGType((STRUCT)jGeom, 2001) + "): ",EWKTExporter.ST_AsEWKT((STRUCT)jGeom)); 
                } catch (Exception e) {
                    e.printStackTrace();
                    System.out.println("     Conversion error " + e.toString());
                }
            }
            results.close();
            statement.close();
            database.close();
        }
        catch(Exception e)
        {
            e.printStackTrace();
        }
    }

}