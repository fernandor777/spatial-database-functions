package com.spdba.dbutils.io;

import java.io.*;
import java.sql.DriverManager;
import java.sql.SQLException;
import oracle.spatial.geometry.JGeometry;
import oracle.spatial.util.GML;
import oracle.sql.CLOB;
import oracle.sql.STRUCT;
import oracle.xml.parser.v2.DOMParser;
import oracle.xml.parser.v2.XMLDocument;

public class GMLConversion
{

    public static STRUCT gml2geometry(String aGeom)
        throws Exception
    {
        STRUCT jstruct = null;
        try
        {
            DOMParser parser = new DOMParser();
            parser.parse(new ByteArrayInputStream(aGeom.getBytes()));
            XMLDocument doc = parser.getDocument();
            org.w3c.dom.Node nodeGeom = doc.getFirstChild();
            JGeometry jgeom = GML.fromNodeToGeometry(nodeGeom);
            jstruct = JGeometry.store(jgeom, DriverManager.getConnection("jdbc:default:connection:"));
        }
        catch(IOException ioe)
        {
            System.err.println(ioe.getMessage());
            System.err.println(ioe.toString());
        }
        catch(SQLException sqle)
        {
            System.err.println(sqle.getMessage());
            System.err.println(sqle.toString());
        }
        catch(Exception e)
        {
            System.err.println(e.getMessage());
            System.err.println(e.toString());
        }
        return jstruct;
    }

    public static STRUCT gml2geometry(CLOB aGeom)
        throws Exception
    {
        STRUCT jstruct = null;
        try
        {
            DOMParser parser = new DOMParser();
            parser.parse(aGeom.getCharacterStream());
            XMLDocument doc = parser.getDocument();
            org.w3c.dom.Node nodeGeom = doc.getFirstChild();
            JGeometry jgeom = GML.fromNodeToGeometry(nodeGeom);
            jstruct = JGeometry.store(jgeom, DriverManager.getConnection("jdbc:default:connection:"));
        }
        catch(IOException ioe)
        {
            System.err.println(ioe.getMessage());
            System.err.println(ioe.toString());
        }
        catch(SQLException sqle)
        {
            System.err.println(sqle.getMessage());
            System.err.println(sqle.toString());
        }
        catch(Exception e)
        {
            System.err.println(e.getMessage());
            System.err.println(e.toString());
        }
        return jstruct;
    }

}
