package com.spdba.dbutils.io.imp.wkt;

import com.spdba.dbutils.Constants;
import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.sql.DBConnection;
import com.spdba.dbutils.sql.SQLConversionTools;
import com.spdba.dbutils.tools.Strings;
import com.spdba.dbutils.tools.Tools;

import es.upv.jaspa.Core;
import es.upv.jaspa.exceptions.JASPAGeomParseException;
import es.upv.jaspa.exceptions.JASPAJTSException;

import java.sql.SQLException;

import java.util.StringTokenizer;

import oracle.sql.CLOB;
import oracle.sql.STRUCT;

import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Polygon;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.io.WKTReader;
import org.locationtech.jts.io.oracle.OraWriter;

public class EWKTImporter{

    private static final String SRID = "SRID";
    private static final String EMPTY = "EMPTY";
    private static final String BOX = "BOX";
    private static final String BOX3D = "BOX3D";
    private static final String SEMICOLON = ";"; // For embedded SRID
    private static final String EQUAL = "="; // For embedded SRID
    
    /* ============================== Private Methods ======================================= */

    private static Coordinate getCoordinate(String coordString) 
    {
        StringTokenizer st = new StringTokenizer(coordString, " ", false /* returnDelims*/) ;
        int dimensions = st.countTokens();
        String dX = st.nextToken();
        String dY = st.nextToken();
        String dZ = null;
        if (dimensions>2) {
            dZ = st.nextToken();
        }
        Coordinate c = 
            dimensions == 2 
            ? new Coordinate(Double.valueOf(dX),
                             Double.valueOf(dY))
            :  new Coordinate(Double.valueOf(dX),
                              Double.valueOf(dY),
                              Double.valueOf(dZ));
        return c;
    }

    private static int getSridFromPrefix(String _wkt) {
        int iSrid = SDO.SRID_NULL;
        if (_wkt.startsWith(SRID) || 
            _wkt.startsWith(SRID.toLowerCase()) ) {
            String srid = null;
                   srid = _wkt.substring(_wkt.indexOf(EQUAL)+1,
                                         _wkt.indexOf(SEMICOLON));
            if ( srid.equalsIgnoreCase(Constants.NULL)) {
                return SDO.SRID_NULL;
            }
           iSrid = Integer.valueOf(srid).intValue(); 
        }
        return iSrid;
    }
    
    private static Polygon readBox(String _boxWkt)
    throws JASPAGeomParseException, 
           JASPAJTSException 
    {
        try {    
            if ( _boxWkt.contains(EMPTY) ) {
                return null;
            }
            String coords = _boxWkt.substring(_boxWkt.indexOf('(')+1,_boxWkt.indexOf(')'));
            if ( Strings.isEmpty(coords) ) return null;
            
            String leftBottomCoord = coords.substring(0,coords.indexOf(','));
            String rightTopCoord   = coords.substring(coords.indexOf(',')+1);

            Coordinate leftBottom = getCoordinate(leftBottomCoord);
            Coordinate   rightTop = getCoordinate(rightTopCoord);

            Core.orderCoordinates(leftBottom, rightTop);
            GeometryFactory gf = new GeometryFactory(
                                         new PrecisionModel(PrecisionModel.FIXED));
            Polygon res = Core.getJTSPolygonFromBOX(gf, leftBottom, rightTop, _boxWkt.contains(BOX3D) ? 3 : 2);
            return res;            
        } finally {
        }
    }
        
    /* ============================== IMPORT ======================================= */

    public static STRUCT ST_GeomFromEWKT(String _ewkt)
    throws SQLException
    {
        if (Strings.isEmpty(_ewkt) ) {
           throw new SQLException("Supplied WKT is NULL.");
        }
        return ST_GeomFromText(_ewkt, SDO.SRID_NULL);
    }

    public static STRUCT ST_GeomFromEWKT(String _ewkt, int _SRID)
    throws SQLException
    {
        if (Strings.isEmpty(_ewkt) ) {
           throw new SQLException("Supplied WKT is NULL.");
        }
        return ST_GeomFromText(_ewkt,_SRID);
    }

    public static STRUCT ST_GeomFromText(String _wkt)
    throws SQLException
    {
        if (Strings.isEmpty(_wkt) ) {
           throw new SQLException("Supplied WKT is NULL.");
        }
        return ST_GeomFromText(_wkt, SDO.SRID_NULL);
    }

    public static STRUCT ST_GeomFromEWKT(CLOB _ewkt)
    throws SQLException
    {
        if ( _ewkt == null || _ewkt.length()==0 ) {
            return null;
        }
        return ST_GeomFromText(SQLConversionTools.clob2string(_ewkt));
    }

    public static STRUCT ST_GeomFromEWKT(CLOB _ewkt, int _SRID)
    throws SQLException
    {
        if ( _ewkt == null || _ewkt.length()==0 ) {
            return null;
        }
        return ST_GeomFromText(SQLConversionTools.clob2string(_ewkt),_SRID);
    }
    
    public static STRUCT ST_GeomFromText(CLOB _wkt)
    throws SQLException
    {
        if ( _wkt == null || _wkt.length()==0 ) {
            return null;
        }
        return ST_GeomFromText(SQLConversionTools.clob2string(_wkt), SDO.SRID_NULL);
    }

    public static STRUCT ST_GeomFromText(CLOB _wkt, 
                                         int _SRID)
    throws SQLException
    {
        // Check geometry parameters
        //
        if ( _wkt == null || _wkt.length()==0 ) {
            return null;
        }
        return ST_GeomFromText(SQLConversionTools.clob2string(_wkt),
                               _SRID);
    }

    public static STRUCT ST_GeomFromText(String _wkt, 
                                         int    _SRID)
    throws SQLException 
    {
        String wkt = null;
               wkt = _wkt.replaceFirst(" Z", "Z")
                         .replaceFirst(" M","M"); 
        if (Strings.isEmpty(wkt) ) {
           throw new SQLException("ST_GeomFromEWKT: Supplied WKT is NULL.");
        }
        
        STRUCT resultSDOGeom = null;
        try
        {
            int srid = _SRID;
            // We keep EWKT SRID=<value> only if _SRID is 0, otherwise _SRID over-writes EWKT SRID
            if ( srid == SDO.NO_SRID ) {
                // Get EWKT SRID (no SRID= means NULL)
                srid = getSridFromPrefix(wkt);
            }
            // Remove SRID=XXXX; prefix.
            if ( wkt.startsWith(SRID)) {
                wkt = wkt.substring(wkt.indexOf(SEMICOLON)+1);
            }

            // PostGIS BOX WKT types
            if (wkt.contains(BOX) || wkt.contains(BOX3D) ) {
                Polygon     p = readBox(wkt);
                p.setSRID(srid);
                OraWriter  ow = new OraWriter(Tools.getCoordDim(p));
                resultSDOGeom = ow.write(p,
                                         DBConnection.getConnection());
                return resultSDOGeom;
            }

            // Same as ST_GeometryFromEWKT but overrides the SRID information with
            // the argument SRID
            WKTReader wktr = new WKTReader();
            Geometry  geom = null;
            geom           = wktr.read(wkt);
            geom.setSRID(srid);
            //Geometry geom = WKT2JTS.instance().read(_wkt);
            if (geom==null && wkt.contains("EMPTY") ) {
                OraWriter  ow = new OraWriter(Tools.getCoordDim(geom));
                resultSDOGeom = ow.write(geom,
                                         DBConnection.getConnection());
            } else if (geom != null && !geom.isEmpty()) {
                OraWriter  ow = new OraWriter(Tools.getCoordDim(geom));
                resultSDOGeom = ow.write(geom,
                                         DBConnection.getConnection());
            }
        } catch(Exception e) {
            System.err.println(e.getMessage()); 
            throw new SQLException("ST_GeomFromEWKT: " + e.getMessage());
        }
        return resultSDOGeom;
    }
    
}
