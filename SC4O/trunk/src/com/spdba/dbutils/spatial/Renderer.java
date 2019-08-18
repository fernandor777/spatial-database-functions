package com.spdba.dbutils.spatial;

import com.spdba.dbutils.Constants;
import com.spdba.dbutils.sql.DBConnection;
import com.spdba.dbutils.tools.LOGGER;
import com.spdba.dbutils.tools.Strings;
import com.spdba.dbutils.tools.Tools;

import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.io.WKTWriter;
import org.locationtech.jts.io.oracle.OraReader;

import java.sql.Connection;
import java.sql.SQLException;

import java.text.DecimalFormat;

import oracle.spatial.geometry.JGeometry;
import oracle.spatial.util.GML2;
import oracle.spatial.util.GML3;
import oracle.spatial.util.KML;
import oracle.spatial.util.KML2;

import oracle.sql.ARRAY;
import oracle.sql.Datum;
import oracle.sql.NUMBER;
import oracle.sql.STRUCT;

public class Renderer {
    
    private static final LOGGER LOGGER = new LOGGER("com.spdba.dbutils.tools.SpatialRenderer");
    
    /**
     * dbConnection
     */
    private static Connection dbConnection; 
    private static WKTWriter   wktWriter = null;
    private static OraReader     oReader = null;

    // Formats for output of geometry objects as text (See Renderer.java)    
    public static enum GEO_RENDERER_FORMAT {
        SDOGEOMETRY,
        STGEOMETRY,
        EWKT,
        WKT,
        GML,
        GML2,
        GML3,
        KML,
        KML2,
        GEOJSON;
        
        public static Renderer.GEO_RENDERER_FORMAT getRendererFormat(String _rFormat) {
            if (Strings.isEmpty(_rFormat) ) {
                return Renderer.GEO_RENDERER_FORMAT.WKT;
            }
            for (Renderer.GEO_RENDERER_FORMAT rFormat : Renderer.GEO_RENDERER_FORMAT.values()) {
                if (rFormat.toString().equalsIgnoreCase(_rFormat) ) {
                    return rFormat;
                }
            }
            return Renderer.GEO_RENDERER_FORMAT.WKT;
        }

    };

    private static WKTWriter getWKTWriter() {
        if ( wktWriter==null ) {
            wktWriter = new WKTWriter();
        }
        return wktWriter;
    }

    private static OraReader getOraReader() {
        if ( oReader==null ) {
            oReader = new OraReader();
        }
        return oReader;
    }
    
    /**
     * Processes Object which could be SDO_GEOMETRY, VERTEX_TYPE, SDO_ELEM_INFO_ARRAY, POINT_TYPE etc 
     * and returns representational (normally coloured) string.
     * @param _value
     * @param _allowColouring
     * @return
     * @history Simon Greener, 2010
     */
    public static String renderGeoObject(Object _value) 
    {
        String    clipText = "",
               sqlTypeName = "";
        try
        {
            // is this really geometry / vertex type column?
              boolean colourSDOGeomElems = false;
              if ( _value instanceof oracle.sql.STRUCT ) {
                STRUCT stValue = (STRUCT)_value;
                sqlTypeName = stValue.getSQLTypeName();
                if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
                    clipText =  renderSdoGeometry(stValue, GEO_RENDERER_FORMAT.STGEOMETRY);
                } else if (sqlTypeName.equals(SDO.TAG_MDSYS_SDO_GEOMETRY) ) {
                    clipText = renderSdoGeometry(stValue, GEO_RENDERER_FORMAT.SDOGEOMETRY);
                } else if ( sqlTypeName.equals(SDO.TAG_MDSYS_VERTEX_TYPE) ) {
                    clipText = renderVertexType(stValue);
                } else if ( sqlTypeName.equals(SDO.TAG_MDSYS_SDO_POINT_TYPE) ) {
                    clipText = renderSdoPoint(SDO.asDoubleArray(stValue,Double.NaN), Constants.MAX_PRECISION);
                }
            } else if (_value instanceof oracle.sql.ARRAY) {
                ARRAY aryValue = (ARRAY)_value;
                sqlTypeName =  aryValue.getSQLTypeName();
                if (sqlTypeName.equals(SDO.TAG_MDSYS_SDO_ELEM_ARRAY)) {
                    clipText = renderElemInfoArray(SDO.asIntArray(aryValue,Integer.MIN_VALUE));
                } else if (sqlTypeName.equals(SDO.TAG_MDSYS_SDO_ORD_ARRAY)) {
                    clipText = renderSdoOrdinates(SDO.asDoubleArray(aryValue,Double.NaN),
                                                  0,  /* We don't know its dimensionality to let function know to simply render the ordinates as is */
                                                  Constants.MAX_PRECISION);
                }
            } else {
                clipText = Constants.NULL;
            }
        } catch (Exception _e) {
            clipText = sqlTypeName + " rendering Failed (" + _e.getMessage() + ")";
        }
        return clipText;
    }
    
    /**
     * Renders SDO_GEOMETRY object in to appropriate string.
     * @param _colValue
     * @param _allowColouring
     * @return
     * @method @method
     * @history @history
     */
    public static  String renderSdoGeometry(STRUCT              _colValue,
                                            GEO_RENDERER_FORMAT _geoFormat) 
    throws SQLException 
    {
        String clipText = "";
        if (_colValue==null) {
            return "NULL";
        }
        String sqlTypeName;
        try { sqlTypeName = _colValue.getSQLTypeName(); } catch (SQLException e) {LOGGER.error("renderSdoGeometry: Failed to get sqlTypeName of Struct:\n"+e.toString()); return ""; }
        STRUCT stValue = _colValue;
        
        // If visualisation is not SDO_GEOMETRY we need a connection
        // to use sdoutl.jar conversion routines so grab first available
        //
        if (getDbConnection() == null )
        {
            return "NULL";
        }

        GEO_RENDERER_FORMAT geoFormat = _geoFormat;
        try 
        {
            int coordDim = SDO.getDimension(stValue, 2);
            if ( (   _geoFormat.equals(GEO_RENDERER_FORMAT.KML) 
                  || _geoFormat.equals(GEO_RENDERER_FORMAT.KML2) ) 
                  && coordDim > 3 ) 
            {
                geoFormat = GEO_RENDERER_FORMAT.SDOGEOMETRY;
            }
            
            // CircularArcs only written as SDO_GEOMETRY
            if (SDO.hasArc(stValue) ) {
                geoFormat = GEO_RENDERER_FORMAT.SDOGEOMETRY;
            }
            
            // get SRID
            int SRID = SDO.getSRID(stValue, SDO.SRID_NULL);
            if ( SRID == SDO.SRID_NULL && geoFormat.toString().startsWith(GEO_RENDERER_FORMAT.KML.toString()) ) {
                  //LOGGER.warn("Geometry's SRID is NULL: No KML written.");
                  return null;
            }
            Geometry         geom = null;
            WKTWriter   wktWriter = null;
            OraReader     oReader = null;
            if ( geoFormat.equals(GEO_RENDERER_FORMAT.SDOGEOMETRY) || 
                 geoFormat.equals(GEO_RENDERER_FORMAT.STGEOMETRY) ) {
                clipText = renderSTRUCT(stValue, Constants.MAX_PRECISION);
            } else if ( geoFormat.equals(GEO_RENDERER_FORMAT.WKT) ) {
                oReader    = getOraReader();
                wktWriter  = getWKTWriter();
                geom       = oReader.read(stValue);
                clipText   = wktWriter.write(geom);
            } else if (geoFormat.equals(GEO_RENDERER_FORMAT.EWKT)) {
                oReader    = getOraReader();
                wktWriter  = getWKTWriter();
                geom       = oReader.read(stValue);
                clipText   = wktWriter.write(geom);
            } else if (geoFormat.equals(GEO_RENDERER_FORMAT.KML2) ||
                       geoFormat.equals(GEO_RENDERER_FORMAT.KML) ) {
                KML2.setConnection(getDbConnection());
                clipText = KML2.to_KMLGeometry(stValue);
            } else if (geoFormat.equals(GEO_RENDERER_FORMAT.GML2) ) {
                GML2.setConnection(getDbConnection());
                clipText = GML2.to_GMLGeometry(stValue);
            } else if (geoFormat.equals(GEO_RENDERER_FORMAT.GML) ||
                       geoFormat.equals(GEO_RENDERER_FORMAT.GML3)) { 
                GML3.setConnection(getDbConnection());
                clipText = GML3.to_GML3Geometry(stValue);
            }
            
        } catch (Exception _e) {
          LOGGER.error("SpatailRenderer.renderGeometry(): Caught exception when rendering geometry as " + _geoFormat + " (" + _e.getMessage() + ")");
        }
        if ( ! geoFormat.equals(GEO_RENDERER_FORMAT.SDOGEOMETRY) && Strings.isEmpty(clipText) ) 
        { 
            try 
            {
                clipText = renderSTRUCT(stValue, Constants.MAX_PRECISION);
            } catch (SQLException e) {
                return null;
            }
        }
        return clipText;
    }
    
    /**
     * @param _struct
     * @return
     * @throws SQLException
     * @author Simon Greener April 13th 2010
     *          Changed to use Constants class
     * @author Simon Greener May 28th 2010
     *          Changed GTYPE assignment so that it defaults to 2D if not provided.
     */
    public static String renderSTRUCT(STRUCT _struct,
                                      int    _ordPrecision) 
    throws SQLException 
    {
        // Note Returning null for null sdo_geometry structure
        if (_struct == null) {
            return null;
        }
        STRUCT stGeom = _struct;
        String sqlTypeName = _struct.getSQLTypeName();
        if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
            stGeom = SDO.getSdoFromST(_struct);
        } 
        final int          GTYPE = SDO.getFullGType(stGeom,0);
        final int           SRID = SDO.getSRID(stGeom);
        final double     POINT[] = SDO.getSdoPoint(stGeom);
        final int     ELEMINFO[] = SDO.getSdoElemInfo(stGeom);
        final double ORDINATES[] = SDO.getSdoOrdinates(stGeom);
        return renderGeometryElements(sqlTypeName, 
                                      GTYPE, 
                                      SRID, 
                                      POINT, 
                                      ELEMINFO, 
                                      ORDINATES, 
                                      _ordPrecision) ;
    }

    private static String renderGeometry(JGeometry _geom, 
                                         String    _sqlTypeName,
                                         int       _ordPrecision) 
    {
        int GTYPE = 0;
        try {
             GTYPE = ((_geom.getDimensions() * 1000) + 
                     ((_geom.isLRSGeometry() && _geom.getDimensions()==3) ? 300 
                   : ((_geom.isLRSGeometry() && _geom.getDimensions()==4) ? 400
                   : 0)) + _geom.getType());
        } catch (Exception e) {
          GTYPE = 0;
        }
        int SRID = SDO.SRID_NULL; try { SRID = _geom.getSRID();                } catch (Exception e) { SRID = SDO.SRID_NULL; }
        double POINT[]     = null;                try { POINT = _geom.getLabelPointXYZ()==null ? _geom.getPoint() : _geom.getLabelPointXYZ(); } catch (Exception e) { }
        int ELEMINFO[]     = null;                try { ELEMINFO = _geom.getElemInfo();        } catch (Exception e) { }
        double ORDINATES[] = null;                try { ORDINATES = _geom.getOrdinatesArray(); } catch (Exception e) { }
        return renderGeometryElements(_sqlTypeName, 
                                      GTYPE, 
                                      SRID, 
                                      POINT, 
                                      ELEMINFO, 
                                      ORDINATES, 
                                      _ordPrecision);
    }

    /**
     * @param _sdo_gtype from sdo_geometry 
     * @param _sdo_srid from sdo_geometry 
     * @param _sdo_point (as array) from sdo_geometry 
     * @param _sdo_elem_info (array) from sdo_geometry 
     * @param _sdo_ordinates (array) from sdo_geometry 
     * @return sdo_geometry in string form
     * @author Simon Greener, 31st March 2010
     *          Changed method and rendering of sdo_gtype and sdo_srid.
     * @author Simon Greener, 1th April 2010
     *          Changed to use of Constants
     * @author Simon Greener, 27th May 2010
     *          Put space between coordinates in output.
     *          Added bracketing around coordinate sets in sdo_ordinate_array
     */
    private static String renderGeometryElements(String   _sqlTypeName,
                                                 int      _sdo_gtype, 
                                                 int      _sdo_srid,
                                                 double[] _sdo_point,
                                                 int[]    _sdo_elem_info,
                                                 double[] _sdo_ordinates,
                                                 int      _ordPrecision)
    {
        StringBuffer labelBuffer = new StringBuffer();
        
        if ( _sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
            labelBuffer.append(_sqlTypeName + "(" );
        }

        // Render Geometry
        // GType and SRID
        //
        labelBuffer.append(SDO.TAG_MDSYS_SDO_GEOMETRY +
                           "(" + 
                           ((_sdo_gtype<=0) ? Constants.NULL : String.valueOf(_sdo_gtype) ) + 
                           "," + 
                           ((_sdo_srid<=0||_sdo_srid == SDO.SRID_NULL) ? Constants.NULL : String.valueOf(_sdo_srid) ) + 
                           "," );
    
        // ***********************************************************
        // Render SDO Point based data
        if (_sdo_point != null) {
            labelBuffer.append(renderSdoPoint(_sdo_point,_ordPrecision) + "," );
        } else {
          labelBuffer.append(Constants.NULL + ",");
        }
    
        // ***********************************************************
        // Render Element Info data
        //
        if (_sdo_elem_info != null) 
            labelBuffer.append(renderElemInfoArray(_sdo_elem_info) + ",") ;
        else
            labelBuffer.append(Constants.NULL + ",");

        // ***********************************************************
        // Render SDO_ORDINATE_ARRAY data
        // 
        if (_sdo_ordinates != null) 
        {
          labelBuffer.append(renderSdoOrdinates(_sdo_ordinates,
                                                _sdo_gtype,
                                                _ordPrecision));
        } else {
            labelBuffer.append(Constants.NULL);
        }
        return labelBuffer.toString() + ")" + (_sqlTypeName.indexOf("MDSYS.ST_")==0?")":"");
    }
    
    public static String renderSdoPoint(double[] _sdo_point,
                                        int      _ordPrecision) 
    {
        DecimalFormat df = Tools.getDecimalFormatter(_ordPrecision); 
        StringBuffer labelBuffer = new StringBuffer(100);
        if (_sdo_point != null && _sdo_point.length == 3) 
        {
            if (Double.isNaN(_sdo_point[0]) && Double.isNaN(_sdo_point[1]) && Double.isNaN(_sdo_point[2])) {
                labelBuffer.append(Constants.NULL );
            } else {
                labelBuffer.append(SDO.TAG_MDSYS_SDO_POINT_TYPE + "(");
                for (int i = 0; i < _sdo_point.length; i++) {
                    labelBuffer.append((i > 0 ? "," : "") + 
                                       (Double.isNaN(_sdo_point[i]) ? Constants.NULL : df.format(_sdo_point[i])) );
                }
                labelBuffer.append(")");
            }
        } else {
            labelBuffer.append(Constants.NULL);
        }
        return labelBuffer.toString();
    }
    
    public static String renderElemInfoArray(int[] _sdo_elem_info)
    {

        if (_sdo_elem_info == null && _sdo_elem_info.length < 1) {
            return "";
        }
     
        StringBuffer labelBuffer = new StringBuffer();
            
        labelBuffer.append(SDO.TAG_MDSYS_SDO_ELEM_ARRAY + "(" );
        for (int ecount = 0;
             ecount < _sdo_elem_info.length;
             ecount += 3) 
        {
          labelBuffer.append((ecount > 0 ? ", " : "") +
                             ((Integer.MIN_VALUE==_sdo_elem_info[ecount]  ) ? Constants.NULL:String.valueOf(_sdo_elem_info[ecount]  )) + "," +
                             ((Integer.MIN_VALUE==_sdo_elem_info[ecount+1]) ? Constants.NULL:String.valueOf(_sdo_elem_info[ecount+1])) + "," +
                             ((Integer.MIN_VALUE==_sdo_elem_info[ecount+2]) ? Constants.NULL:String.valueOf(_sdo_elem_info[ecount+2])) );
        }
        labelBuffer.append(")");
        return labelBuffer.toString(); 
    }
    
    public static String renderSdoOrdinates(double[] _sdo_ordinates,
                                            int      _sdo_gtype,
                                            int      _ordPrecision) 
    {
        DecimalFormat df = Tools.getDecimalFormatter(_ordPrecision); 
        StringBuffer labelBuffer = new StringBuffer();
        
        // If dimension == 0 we don't know what the dimensionality is
        int dimension = (int)Math.floor(_sdo_gtype / 1000);
        int numberOfCoordinates = dimension==0?0:(_sdo_ordinates.length / dimension);
        
        int ordIndex  = -1;
        int ordOffset = -1;
        
        labelBuffer.append(SDO.TAG_MDSYS_SDO_ORD_ARRAY +  "(");
        // Following duplication is done for speed purposes
        switch (dimension) {
          case 0 : {
            for (int i = 0; i < _sdo_ordinates.length; i++) {
                labelBuffer.append(( i!=0 ? "," : "") + 
                (Double.isNaN(_sdo_ordinates[i]) ? Constants.NULL : df.format(_sdo_ordinates[i]).toString() ));
            }
            break;
          }
            case 2 : {
                for (int i = 0; i < numberOfCoordinates; i++) {
                    ordOffset = i * dimension;
                    labelBuffer.append(( i!=0 ? ", " : "") +
                                       (Double.isNaN(_sdo_ordinates[ordOffset]) ? Constants.NULL : df.format(_sdo_ordinates[ordOffset]).toString()) +
                                       "," + 
                                       (Double.isNaN(_sdo_ordinates[ordOffset+1]) ? Constants.NULL : df.format(_sdo_ordinates[ordOffset+1]).toString()) );
                }
                break;
            }
            case 3 : {
                for (int i = 0; i < numberOfCoordinates; i++) {
                    ordOffset = i * dimension;
                    labelBuffer.append(( i!=0 ? ", " : "") +
                                       (Double.isNaN(_sdo_ordinates[ordOffset]) ? Constants.NULL : df.format(_sdo_ordinates[ordOffset]).toString()) +
                                       "," + 
                                       (Double.isNaN(_sdo_ordinates[ordOffset+1]) ? Constants.NULL : df.format(_sdo_ordinates[ordOffset+1]).toString()) +
                                       "," +
                                       (Double.isNaN(_sdo_ordinates[ordOffset+2]) ? Constants.NULL : df.format(_sdo_ordinates[ordOffset+2]).toString()) );
                }
                break;
            }
            case 4 :
            default : {
                for (int i = 0; i < numberOfCoordinates; i++) {
                    ordOffset = i * dimension;
                    labelBuffer.append(( i!=0 ? ", " : "") +
                                       (Double.isNaN(_sdo_ordinates[ordOffset]) ? Constants.NULL : df.format(_sdo_ordinates[ordOffset]).toString()) +
                                       "," + 
                                       (Double.isNaN(_sdo_ordinates[ordOffset+1]) ? Constants.NULL : df.format(_sdo_ordinates[ordOffset+1]).toString()) +
                                       "," +
                                       (Double.isNaN(_sdo_ordinates[ordOffset+2]) ? Constants.NULL : df.format(_sdo_ordinates[ordOffset+2]).toString())  +
                                       "," +
                                       (Double.isNaN(_sdo_ordinates[ordOffset+3]) ? Constants.NULL : df.format(_sdo_ordinates[ordOffset+3]).toString()) 
                                    );
                }
                break;
            }
        }
        labelBuffer.append(")");
        return labelBuffer.toString();
    }
    
    /**
     * @method renderVertexType
     * @param _colValue
     * @param _renderAsHTML
     * @return
     * @author Simon Greener, June 8th 2010 - Original coding
     */
    public static String renderVertexType(STRUCT  _colValue)
    {
        StringBuffer labelBuffer = new StringBuffer();
        try 
        {
            Datum data[] = _colValue.getOracleAttributes();
            double x = ((NUMBER)data[0]).doubleValue();
            double y = ((NUMBER)data[1]).doubleValue();
            double z = (data[2] != null) ? ((NUMBER)data[2]).doubleValue() : Double.NaN;
            double w = (data[3] != null) ? ((NUMBER)data[3]).doubleValue() : Double.NaN;

            labelBuffer.append(SDO.TAG_MDSYS_VERTEX_TYPE + "(" );
            if ( Double.isInfinite(x) || Double.isNaN(x) ) {
                labelBuffer.append(Constants.NULL + ",");
            } else {
                labelBuffer.append( String.valueOf(x) + ",");
            }
            if ( Double.isInfinite(y) || Double.isNaN(y) ) {
                labelBuffer.append(Constants.NULL + ",");
            } else {
                labelBuffer.append(String.valueOf(y) + ",");
            }
            if ( Double.isInfinite(z) || Double.isNaN(z) ) {
                labelBuffer.append(Constants.NULL + ",");
            } else {
                labelBuffer.append(String.valueOf(z) + ",");
            }
            if ( Double.isInfinite(w) || Double.isNaN(w) ) {
                labelBuffer.append(Constants.NULL + ")");
            } else {
                labelBuffer.append(String.valueOf(w) + ")");
            }

        } catch (SQLException _e) {
          labelBuffer.append(_e.getLocalizedMessage());
        }
        return labelBuffer.toString();      
    }

    public static Connection getDbConnection() {
        try {
            if ( dbConnection == null ) {
                dbConnection = DBConnection.getConnection();
            }
        } catch (SQLException e) {
        }
        return dbConnection;
    }

    public static void setDbConnection(Connection dbConnection) {
        Renderer.dbConnection = dbConnection;
    }
}
