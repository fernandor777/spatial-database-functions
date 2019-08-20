package com.spdba.dbutils.io.exp.wkb;


import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.sql.DBConnection;
import com.spdba.dbutils.sql.SQLConversionTools;
import com.spdba.dbutils.tools.Strings;
import com.spdba.dbutils.tools.Tools;

import es.upv.jaspa.Core;
import es.upv.jaspa.exceptions.JASPAGeomParseException;
import es.upv.jaspa.exceptions.JASPAIllegalArgumentException;
import es.upv.jaspa.io.JTS2WKT;
import es.upv.jaspa.io.WKT2JTS;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

import java.sql.SQLException;

import oracle.sql.BLOB;
import oracle.sql.CLOB;
import oracle.sql.STRUCT;

import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.io.oracle.OraReader;
import org.locationtech.jts.io.oracle.OraWriter;


public class EWKBExporter {
            
    public static BLOB ST_AsBinary(STRUCT _geom)
    throws SQLException 
    {
        // Check geometry parameters
        //
        if ( _geom == null ) {
           throw new SQLException("Supplied Sdo_Geometry is NULL.");
        }
        try
        {
            // Convert Geometries
            //
            int SRID = SDO.getSRID(_geom, SDO.SRID_NULL);
            PrecisionModel  pm = new PrecisionModel();
            GeometryFactory gf = new GeometryFactory(pm,SRID); 
            OraReader       or = new OraReader(gf);
            Geometry       geo = or.read(_geom);
            
            // Check converted geometries are valid
            //
            if ( geo == null ) {
               throw new SQLException("SDO_Geometry conversion to JTS geometry returned NULL.");
            }

            // read geometry into a byte array 
            byte[] bGeom = Core.getWKBFromJTSGeometry(geo);
            // write the array of binary data to a BLOB
            BLOB outBlob;
            outBlob = new BLOB(DBConnection.getConnection(),bGeom);
            return outBlob;
        } catch (JASPAGeomParseException ge ) {
            throw new SQLException(ge.getMessage());
        }
    }

    public static BLOB ST_AsBinary(STRUCT _geom, String _byteOrder)
    throws SQLException 
    {
        // Check geometry parameters
        //
        if ( _geom == null ) {
           throw new SQLException("Supplied Sdo_Geometry is NULL.");
        }
        try
        {
            // Convert Geometries
            //
            int SRID = SDO.getSRID(_geom, SDO.SRID_NULL);
            PrecisionModel  pm = new PrecisionModel();
            GeometryFactory gf = new GeometryFactory(pm,SRID); 
            OraReader       or = new OraReader(gf);
            Geometry       geo = or.read(_geom);
            
            // Check converted geometries are valid
            //
            if ( geo == null ) {
               throw new SQLException("SDO_Geometry conversion to JTS geometry returned NULL.");
            }

            // Now convert to WKB
            Integer order = Core.getByteOrderFromText(_byteOrder);
            if (order == null) {
                return null;
            }
            
            // read geometry into a byte array 
            byte[] bGeom = Core.getWKBFromJTSGeometry(geo, order.intValue());
            // write the array of binary data to a BLOB
            BLOB outBlob;
            outBlob = new BLOB(DBConnection.getConnection(),bGeom);
            return outBlob;
        } catch (JASPAIllegalArgumentException e) {
            throw new SQLException(e.getMessage());
        } catch (JASPAGeomParseException ge ) {
            throw new SQLException(ge.getMessage());
        }
    }
    
    public static BLOB ST_AsEWKB(STRUCT _geom)
    throws SQLException {
        // Check geometry parameters
        //
        if ( _geom == null ) {
           throw new SQLException("Supplied Sdo_Geometry is NULL.");
        }
        try
        {
            // Convert Geometries
            //
            int SRID = SDO.getSRID(_geom, SDO.SRID_NULL);
            PrecisionModel  pm = new PrecisionModel();
            GeometryFactory gf = new GeometryFactory(pm,SRID); 
            OraReader       or = new OraReader(gf);
            Geometry       geo = or.read(_geom);
            
            // Check converted geometries are valid
            //
            if ( geo == null ) {
               throw new SQLException("SDO_Geometry conversion to JTS geometry returned NULL.");
            }
            // read geometry into a byte array 
            byte[] bGeom = Core.getEWKBFromJTSGeometry(geo);
            // write the array of binary data to a BLOB
            BLOB outBlob;
            outBlob = new BLOB(DBConnection.getConnection(),bGeom);
            return outBlob;
        } catch (JASPAGeomParseException ge ) {
            throw new SQLException(ge.getMessage());
        }
    }

    public static BLOB ST_AsEWKB(STRUCT _geom, String _byteOrder)
    throws SQLException
    {
        // Check geometry parameters
        //
        if ( _geom == null ) {
           throw new SQLException("Supplied Sdo_Geometry is NULL.");
        }
        try
        {
            // Convert Geometries
            //
            int SRID = SDO.getSRID(_geom, SDO.SRID_NULL);
            PrecisionModel  pm = new PrecisionModel();
            GeometryFactory gf = new GeometryFactory(pm,SRID); 
            OraReader       or = new OraReader(gf);
            Geometry       geo = or.read(_geom);
            
            // Check converted geometries are valid
            //
            if ( geo == null ) {
               throw new SQLException("SDO_Geometry conversion to JTS geometry returned NULL.");
            }

            // Now convert to WKT/EWKT
            Integer order = Core.getByteOrderFromText(_byteOrder);
            if (order == null) return null;
            // read geometry into a byte array 
            byte[] bGeom = Core.getEWKBFromJTSGeometry(geo, order.intValue());
            // write the array of binary data to a BLOB
            BLOB outBlob;
            outBlob = new BLOB(DBConnection.getConnection(),bGeom);
            return outBlob;
        } catch (JASPAIllegalArgumentException e) {
            throw new SQLException(e.getMessage());
        } catch (JASPAGeomParseException ge ) {
            throw new SQLException(ge.getMessage());
        }
    }

}
