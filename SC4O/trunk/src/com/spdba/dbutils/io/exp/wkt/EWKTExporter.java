package com.spdba.dbutils.io.exp.wkt;

import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.sql.SQLConversionTools;
import com.spdba.dbutils.tools.Strings;

import es.upv.jaspa.io.JTS2WKT;

import java.sql.SQLException;

import oracle.sql.CLOB;
import oracle.sql.STRUCT;

import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.io.ora.OraReader;

public class EWKTExporter {
    
    public EWKTExporter () {
        super();
    }
    
    public static CLOB ST_AsText(STRUCT _geom)
    throws SQLException 
    {
        // Knock out SRID as ordinary ST_AsText WKT does not support it
        //
        STRUCT geom = SDO.setSRID(_geom, -9);
        return ST_AsEWKT(geom);
    }

    public static CLOB ST_AsEWKT(STRUCT _geom)
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
            int           SRID = SDO.getSRID(_geom, SDO.SRID_NULL);
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
            // 
            //String geomString = JTS2WKT.instance().write(geo);
            int coordDimension = SDO.getDimension(_geom, 2);
            String geomString = JTS2WKT.instance().write(geo, coordDimension);
            //EWKTWriter ewktWriter = new EWKTWriter(coordDimension);
            //String geomString = ewktWriter.write(geo);
            if (Strings.isEmpty(geomString) ) {
                return null;
            }
            // Since EWKT add SRID= to front of string if not WKT
            if ( SRID != -9 ) {
                geomString = "SRID=" + (SRID==SDO.SRID_NULL?"NULL":String.valueOf(SRID)) + ";" + geomString;
            }
            return SQLConversionTools.string2Clob(geomString);

        } catch(Exception e) {
            System.err.println(e.getMessage()); 
            throw new SQLException(e.getMessage());
        }
    }
    
}
