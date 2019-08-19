package com.spdba.dbutils.io.imp.wkb;

import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.sql.DBConnection;
import com.spdba.dbutils.tools.Tools;

import es.upv.jaspa.Core;
import es.upv.jaspa.exceptions.JASPAGeomParseException;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

import java.sql.SQLException;

import oracle.sql.BLOB;
import oracle.sql.STRUCT;

import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.io.ora.OraWriter;

public class EWKBImporter {

    public static STRUCT ST_GeomFromEWKB(BLOB _ewkb)
    throws SQLException
    {
        return ST_GeomFromEWKB(_ewkb, SDO.SRID_NULL);
    }
    
    public static STRUCT ST_GeomFromEWKB(BLOB _ewkb, int _SRID)
    throws SQLException 
    {
        if ( _ewkb == null ) {
           throw new SQLException("Supplied EWKB is NULL.");
        }
        STRUCT resultSDOGeom = null;
        try {
            BLOB outBlob = BLOB.createTemporary(DBConnection.getConnection(), true, BLOB.DURATION_SESSION);
            InputStream inputStream = _ewkb.getBinaryStream();
            int inByte;
            byte[] geomBytes;
            ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
            while ((inByte = inputStream.read()) != -1)
            {
                byteArrayOutputStream.write(inByte);
            }
            geomBytes = byteArrayOutputStream.toByteArray();
            Geometry geom = Core.getJTSGeometryFromGBLOB(geomBytes);
            // Convert to SDO_GEOMETRY            
            if (geom != null && !geom.isEmpty()) {
                if (geom.getSRID() == SDO.SRID_NULL && _SRID != SDO.SRID_NULL ) {
                    geom.setSRID(_SRID);
                }
                // Now convert new JTS Geometry to STRUCT
                // 
                OraWriter  ow = new OraWriter(Tools.getCoordDim(geom));
                resultSDOGeom = ow.write(geom,
                                         DBConnection.getConnection());
                return resultSDOGeom;
            }
        } catch (IOException ioe) {
            throw new SQLException("Failed to read EWKB: " + ioe.getMessage());
        } catch (JASPAGeomParseException e) {
            throw new SQLException(e.getMessage());
        }
        return resultSDOGeom;
    }

}
