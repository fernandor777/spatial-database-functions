package com.spdba.dbutils.ora.io;

import com.spdba.dbutils.tools.Tools;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Statement;

import java.util.ArrayList;
import java.util.List;

import oracle.sql.ARRAY;
import oracle.sql.Datum;
import oracle.sql.STRUCT;

import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryCollection;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.LineSegment;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.LinearRing;
import org.locationtech.jts.geom.MultiLineString;
import org.locationtech.jts.geom.MultiPolygon;
import org.locationtech.jts.geom.Polygon;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.io.oracle.OraReader;

//Standard JDBC packages.

/**
 * Not so much a test case, more like a sample.
 *
 */
public class IOTest {

    public static void main(String _testType) 
    {
        try {
            char testType = _testType==null ? 'U' : _testType.charAt(0);
            switch (testType) {
            //case 'I' : importSHP(); break;
            case 'U' : testUnionGeomColl();   break;
            case 'R' : dataTypeExamination(); break;
            case 'D' : dimarray();            break;
            case 'V' : Vectorize();           break;
            case 'X':
                // "Polygon"
                // XBase(projPoint2DSQL,"Point",5,"c:\\temp","projpoint2d");
                break;
          }
          System.out.println("Tests completed");
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
	
    private static LinearRing createBox(double x, double dx, 
                                        double y, double dy, 
                                        int npoints, 
                                        GeometryFactory gf){

            //figure out the number of points per side
            int ptsPerSide = npoints/4;
            int rPtsPerSide = npoints%4;
            Coordinate[] coords = new Coordinate[npoints+1];
            coords[0] = new Coordinate(x,y); // start
            gf.getPrecisionModel().makePrecise(coords[0]);
            
            int cindex = 1;
            for(int i=0;i<4;i++){ // sides
                    int npts = ptsPerSide+(rPtsPerSide-->0?1:0);
                    // npts atleast 1
                    
                    if(i%2 == 1){ // odd vert
                            double cy = dy/npts;
                            if(i > 1) // down
                                    cy *=-1;
                            double tx = coords[cindex-1].x;
                            double sy = coords[cindex-1].y;
                            
                            for(int j=0;j<npts;j++){
                                    coords[cindex] = new Coordinate(tx,sy+(j+1)*cy);
                                    gf.getPrecisionModel().makePrecise(coords[cindex++]);
                            }
                    }else{ // even horz
                            double cx = dx/npts;
                            if(i > 1) // down
                                    cx *=-1;
                            double ty = coords[cindex-1].y;
                            double sx = coords[cindex-1].x;
                            
                            for(int j=0;j<npts;j++){
                                    coords[cindex] = new Coordinate(sx+(j+1)*cx,ty);
                                    gf.getPrecisionModel().makePrecise(coords[cindex++]);
                            }
                    }
            }
            coords[npoints] = new Coordinate(x,y); // end
            gf.getPrecisionModel().makePrecise(coords[npoints]);
            
            return gf.createLinearRing(coords);
    }

    public static void testUnionGeomColl() {
        GeometryFactory gf = new GeometryFactory();
        LinearRing outer = null;
        List polyList = new ArrayList();
        for (int i=0;i<4;i++) {
            outer = createBox((double)i*10,(double)10,
                              (double)i*10,(double)10,4,gf);
            System.out.println((double)i*10 + "," + (double)i*10  + "," + 
                               ((double)i*10 + (double)10) + "," + 
                               ((double)i*10 +(double)10));
            polyList.add(new Polygon(outer,null,gf));
        }
        System.out.println("polyList.size() = " + polyList.size());
        Geometry geo = null;
        if ( polyList.size()==1 ) {
            geo = (Polygon)polyList.get(0);
        } else if ( polyList.size()>1) {
            Polygon[] polys = (Polygon[])polyList.toArray(new Polygon[0]);
            geo = new MultiPolygon(polys,gf);
        }
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
    
  public static void dimarray() 
  {
      try {
          // connect to test database
          Class.forName("oracle.jdbc.driver.OracleDriver");
          Connection database = DriverManager.getConnection("jdbc:oracle:thin:@ST1:1521:GISDB", "gis", "gis");
          Statement statement;
          statement = database.createStatement();
          ResultSet results = statement.executeQuery ("SELECT DIMINFO FROM USER_SDO_GEOM_METADATA WHERE ROWNUM < 2");
          results.next();
          results.getMetaData().getColumnType(1);
          oracle.sql.ARRAY ary = (ARRAY)results.getArray(1);
          System.out.println(ary.getDescriptor().getSQLName().getName().equals("MDSYS.SDO_DIM_ARRAY"));
          Datum[] objs = ary.getOracleArray();
          for (int i =0; i < objs.length; i++) {
              STRUCT dimElement = (STRUCT)objs[i];
              Datum data[] = dimElement.getOracleAttributes();
              final String DIM_NAME = data[0].stringValue();
              final double SDO_LB   = data[1].doubleValue();
              final double SDO_UB   = data[2].doubleValue();
              final double SDO_TOL  = data[3].doubleValue();
          }
          results.close();
          statement.close();
          database.close();        
      }
      catch (Exception e) {
          e.printStackTrace();
      }

  }

/**
  public static void importSHP() {
      try {
          // connect to test database
          Class.forName("oracle.jdbc.driver.OracleDriver");
          Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522:GISDB", "codesys", "codemgr");
          ShapeFileReader.loadShapefile("localhost",
                                        1522,
                                        "GISDB",
                                        "codesys",
                                        "codemgr",
                                        "GUTNEW",
                                        "c:\\temp\\gutdata.shp",
                                        "fid",
                                        "8311",
                                        "geom",
                                        "100.05766136,-49.9707955",
                                        "159.9604259,-0.27929856",
                                        "0.05,0.05",
                                        0,
                                        1,
                                        1000);
      }
      catch (Exception e) {
          e.printStackTrace();
      }          
  }
**/
  
    private static int getSegCount(MultiLineString geom) {
        int numSegments = 0;
        for (int s = 0; s < geom.getNumGeometries(); s++)
            numSegments += ((LineString)geom.getGeometryN(s)).getNumPoints() - 1;
        return numSegments;
    }
    
    private static int getSegCount(Polygon geom) {
        int numSegments = geom.getExteriorRing().getNumPoints() - 1;
        for (int s = 0; s < geom.getNumInteriorRing(); s++)
            numSegments += ((LineString)geom.getInteriorRingN(s)).getNumPoints() - 1;
        return numSegments;
    }    

    private static LineSegment[] getSegments(Polygon pGeom) {
        int numSegments = getSegCount(pGeom);
        LineSegment[] segs = new LineSegment[numSegments];
        
        int segCount = 0;
        // Process outer ring
        LineString ring = pGeom.getExteriorRing();
        for (int i = 0; i < ring.getNumPoints() - 1; i++, segCount++ )
            segs[segCount] = new LineSegment(ring.getCoordinateN(i),
                                             ring.getCoordinateN(i + 1));
        // Now process all other rings
        for (int i = 0; i < pGeom.getNumInteriorRing(); i++) {
            ring = pGeom.getInteriorRingN(i);
            for (int j = 0; j < ring.getNumPoints() - 1; j++, segCount++ ) 
                segs[segCount] = new LineSegment(ring.getCoordinateN(j), 
                                                 ring.getCoordinateN(j + 1));
        }
        return segs;
    }

    private static LineSegment[] getSegments(MultiPolygon mPoly)
    {
        int numSegments = 0;
        for (int s = 0; s < mPoly.getNumGeometries(); s++) 
            numSegments += getSegCount((Polygon)mPoly.getGeometryN(s));
        LineSegment[] segs = new LineSegment[numSegments];
        int segCount = 0;
        for (int i = 0; i < mPoly.getNumGeometries(); i++) 
        {
            Polygon pGeom = (Polygon)mPoly.getGeometryN(i);
            // Process outer ring
            LineString ring = pGeom.getExteriorRing();
            for (int j = 0; j < ring.getNumPoints() - 1; j++, segCount++ )
                segs[segCount]  = new LineSegment(ring.getCoordinateN(j),
                                                  ring.getCoordinateN(j + 1));
            // Now process all other rings
            for (int k = 0; k < pGeom.getNumInteriorRing(); k++) {
                ring = pGeom.getInteriorRingN(k);
                for (int l = 0; l < ring.getNumPoints() - 1; l++, segCount++ )
                    segs[segCount] = new LineSegment(ring.getCoordinateN(l), 
                                                     ring.getCoordinateN(l + 1));
            }
        }
        return segs;
    }
    
    private static LineSegment[] getSegments(LineString line)
    {
        LineSegment[] segs = new LineSegment[line.getNumPoints() - 1];
        for (int i = 0; i < line.getNumPoints() - 1; i++) 
           segs[i] = new LineSegment(line.getCoordinateN(i), 
                                    line.getCoordinateN(i + 1));
        return segs;
    }

    private static LineSegment[] getSegments(MultiLineString mLine)
    {
        // Calculate number of segments in geometry
        int numSegments = getSegCount(mLine);
        LineSegment[] segs = new LineSegment[numSegments];
        int segCount = 0;
        for (int i = 0; i < mLine.getNumGeometries(); i++) 
        {
            LineString line = (LineString)mLine.getGeometryN(i);
            for (int j = 0; j < line.getNumPoints() - 1; j++, segCount++)
              segs[segCount] = new LineSegment(line.getCoordinateN(j), 
                                               line.getCoordinateN(j + 1));
        }
        return segs;
    }
    
    private static LineSegment[] getSegments(Geometry geom)
    {
      if ( geom.getClass().equals(Polygon.class) ) {
          return getSegments((Polygon) geom);
      } else if (geom.getClass().equals(MultiPolygon.class)) {
          return getSegments((MultiPolygon)geom);
      } else if (geom.getClass().equals(MultiLineString.class)) {
          return getSegments((MultiLineString)geom);
      } else if (geom.getClass().equals(LineString.class)) {
          return getSegments((LineString)geom);
      } else if (geom.getClass().equals(GeometryCollection.class)) {
          // not yet implemented 
          // return getSegments((GeometryCollection)geom);
      }
      return null;
    }

    public static void Vectorize() 
    {
        try {

        Class.forName("oracle.jdbc.driver.OracleDriver");
        Connection database = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:GISDB12", "CODESYS", "CODEMGR");

        Statement statement;
        statement = database.createStatement();
        ResultSet results; 
        results = statement.executeQuery("select sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,2,2)) as geom from dual " +
            "union all " +
            "select sdo_geometry(2006,null,null,sdo_elem_info_array(1,2,1,5,2,1),sdo_ordinate_array(1,1,2,2,10,10,20,20)) as geom from dual " +
            "union all " +
            "select sdo_geometry(2003,null,null,sdo_elem_info_array(1,1003,1),sdo_ordinate_array(50,105,55,105,60,110,50,110,50,105)) as geom from dual " +
            "union all " +
            "select sdo_geometry(2003,null,null,sdo_elem_info_array(1,1003,1,11,2003,3),sdo_ordinate_array(50,105,55,105,60,110,50,110,50,105,52,106,54,108)) as geom from dual " +
            "union all " +
            "select sdo_geometry(2007,null,null,sdo_elem_info_array(1,1003,1,11,1003,1),sdo_ordinate_array(50,105,55,105,60,110,50,110,50,105,62,108,65,108,65,112,62,112,62,108)) as geom from dual");
           
        PrecisionModel      pm = new PrecisionModel(Tools.getPrecisionScale(2));
        GeometryFactory     gf = new GeometryFactory(pm); 
        OraReader           or = new OraReader(gf);            
        Tools.setPrecisionScale(3);                    
        Geometry geom;
        while (results.next()) {
            try {
            // read in geometry object
                STRUCT sGeom = (STRUCT) results.getObject(1);
                geom = or.read(sGeom);
                System.out.println(geom.getClass().toString());
                LineSegment[] segs = getSegments(geom);
                for (int i = 0; i < segs.length; i++)
                    System.out.println("(" + segs[i].p0.x + "," +
                                             segs[i].p0.y + ")(" +
                                             segs[i].p1.x + "," +
                                             segs[i].p1.y + ")");
            } catch (Exception e) {
                e.printStackTrace();
                 System.out.println("     Conversion error " + e.toString());
            }
        }
        results.close();
        statement.close();
        database.close();
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
        
}
