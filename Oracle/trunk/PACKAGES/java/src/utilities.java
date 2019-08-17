package com.spatialdbadvisor.gis.oracle;

import java.io.IOException;

import java.sql.DriverManager;
import java.sql.SQLException;

// 10gR2 imports...
import oracle.spatial.geometry.JGeometry;
import oracle.spatial.util.GML;

import oracle.sql.STRUCT;

import oracle.xml.parser.v2.DOMParser;
import oracle.xml.parser.v2.XMLDocument;

import org.w3c.dom.Node;

public class utilities
{

    public static int RunCommand(String command)
    {
      int exitVal = 0;
      try
      {
        Runtime rt = Runtime.getRuntime();
        Process proc = rt.exec(command);
        proc.waitFor();
        exitVal = proc.exitValue();
      } catch (Exception e)
      {
        System.out.println(e.getMessage());
        exitVal = -1;
      }
      // By convention, 0 indicates normal termination.
      return exitVal;
    }

    public static oracle.sql.STRUCT gml2geometry(String aGeom)
           throws Exception
    {    
      STRUCT jstruct = null;
      try 
      { 
        DOMParser parser = new DOMParser();
        parser.parse(new java.io.ByteArrayInputStream(aGeom.getBytes()));
        XMLDocument doc  = parser.getDocument();
        Node nodeGeom    = doc.getFirstChild();
        JGeometry jgeom  = GML.fromNodeToGeometry(nodeGeom);
        jstruct = JGeometry.store(jgeom,DriverManager.getConnection("jdbc:default:connection:"));
      }
      catch (IOException ioe) {
          System.err.println(ioe.getMessage());
          System.err.println(ioe.toString());
      } catch (SQLException sqle) {
          System.err.println(sqle.getMessage());
          System.err.println(sqle.toString());
      } catch (Exception e) {
          System.err.println(e.getMessage());
          System.err.println(e.toString());
      }
      return jstruct;
    }
  
    public static oracle.sql.STRUCT gml2geometry(oracle.sql.CLOB aGeom)
           throws Exception
    {    
      STRUCT jstruct = null;
      try 
      { 
        DOMParser parser = new DOMParser();
        parser.parse(aGeom.getCharacterStream());
        XMLDocument doc  = parser.getDocument();
        Node nodeGeom    = doc.getFirstChild();
        JGeometry jgeom  = GML.fromNodeToGeometry(nodeGeom);
        jstruct          = JGeometry.store(jgeom,DriverManager.getConnection("jdbc:default:connection:"));
      }
      catch (IOException ioe) {
          System.err.println(ioe.getMessage());
          System.err.println(ioe.toString());
      } catch (SQLException sqle) {
          System.err.println(sqle.getMessage());
          System.err.println(sqle.toString());
      } catch (Exception e) {
          System.err.println(e.getMessage());
          System.err.println(e.toString());
      }
      return jstruct;
    }

}
