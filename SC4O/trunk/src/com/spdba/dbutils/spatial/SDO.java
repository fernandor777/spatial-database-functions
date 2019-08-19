package com.spdba.dbutils.spatial;

import com.spdba.dbutils.Constants;

import com.spdba.dbutils.Constants.GEOMETRY_TYPES;
import com.spdba.dbutils.spatial.SDO.POLYGON_RING_ORIENTATION;
import com.spdba.dbutils.io.GeometryProperties;
import com.spdba.dbutils.sql.DBConnection;

import com.spdba.dbutils.tools.LOGGER;
import com.spdba.dbutils.tools.Strings;

import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.LinearRing;
import org.locationtech.jts.geom.MultiPolygon;
import org.locationtech.jts.geom.Polygon;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.io.ora.OraReader;

import java.awt.geom.Point2D;

import java.sql.Connection;
import java.sql.SQLException;

import java.sql.Struct;

import java.text.DecimalFormat;

import java.util.Iterator;
import java.util.List;
import java.util.StringTokenizer;

import oracle.spatial.geometry.J3D_Geometry;
import oracle.spatial.geometry.JGeometry;

import oracle.sql.ARRAY;
import oracle.sql.Datum;
import oracle.sql.NUMBER;
import oracle.sql.STRUCT;
import oracle.sql.StructDescriptor;

import org.geotools.data.shapefile.shp.ShapeType;

public class SDO 
{  
    private static final LOGGER LOGGER = new LOGGER("com.spdba.dbutils.tools.SDO");

    public static final int                 SRID_NULL = -1;    
    public static final int                 NULL_SRID = -1;
    public static final int                   NO_SRID = 0;
    
    public static final String MDSYS_SCHEMA           = "MDSYS";   // In case 9i being used
    public static final String TAG_SDO_GEOMETRY       = "SDO_GEOMETRY";
    public static final String TAG_SDO_GTYPE          = "SDO_GTYPE";
    public static final String TAG_SDO_SRID           = "SDO_SRID";
    public static final String TAG_SDO_POINT_TYPE     = "SDO_POINT_TYPE";
    public static final String TAG_SDO_ELEM_ARRAY     = "SDO_ELEM_INFO_ARRAY";
    public static final String TAG_SDO_ORD_ARRAY      = "SDO_ORDINATE_ARRAY";
    public static final String TAG_VERTEX_TYPE        = "VERTEX_TYPE";    
    public static final String TAG_SDO_DIM_ARRAY      = "SDO_DIM_ARRAY";
    public static final String TAG_SDO_ELEMENT        = "SDO_DIM_ELEMENT";
    public static final String TAG_ST_GEOMETRY        = "ST_GEOMETRY";
    public static final String TAG_ST_CIRCULARSTRING  = "ST_CIRCULARSTRING";
    public static final String TAG_ST_COMPOUNDCURVE   = "ST_COMPOUNDCURVE";
    public static final String TAG_ST_CURVE           = "ST_CURVE";
    public static final String TAG_ST_CURVEPOLYGON    = "ST_CURVEPOLYGON";
    public static final String TAG_ST_GEOMCOLLECTION  = "ST_GEOMCOLLECTION";
    public static final String TAG_ST_LINESTRING      = "ST_LINESTRING";
    public static final String TAG_ST_MULTICURVE      = "ST_MULTICURVE";
    public static final String TAG_ST_MULTILINESTRING = "ST_MULTILINESTRING";
    public static final String TAG_ST_MULTIPOINT      = "ST_MULTIPOINT";
    public static final String TAG_ST_MULTIPOLYGON    = "ST_MULTIPOLYGON";
    public static final String TAG_ST_MULTISURFACE    = "ST_MULTISURFACE";
    public static final String TAG_ST_POINT           = "ST_POINT";
    public static final String TAG_ST_POLYGON         = "ST_POLYGON";
    public static final String TAG_ST_SURFACE         = "ST_SURFACE";
    public static final String TAG_MDSYS_SDO_GEOMETRY       = MDSYS_SCHEMA + "." + TAG_SDO_GEOMETRY;
    public static final String TAG_MDSYS_SDO_POINT_TYPE     = MDSYS_SCHEMA + "." + TAG_SDO_POINT_TYPE;
    public static final String TAG_MDSYS_SDO_ELEM_ARRAY     = MDSYS_SCHEMA + "." + TAG_SDO_ELEM_ARRAY;
    public static final String TAG_MDSYS_SDO_ORD_ARRAY      = MDSYS_SCHEMA + "." + TAG_SDO_ORD_ARRAY;
    public static final String TAG_MDSYS_VERTEX_TYPE        = MDSYS_SCHEMA + "." + TAG_VERTEX_TYPE;
    public static final String TAG_MDSYS_SDO_DIMARRAY       = MDSYS_SCHEMA + "." + TAG_SDO_DIM_ARRAY;
    public static final String TAG_MDSYS_SDO_ELEMENT        = MDSYS_SCHEMA + "." + TAG_SDO_ELEMENT;
    public static final String TAG_MDSYS_ST_CIRCULARSTRING  = MDSYS_SCHEMA + "." + TAG_ST_CIRCULARSTRING;
    public static final String TAG_MDSYS_ST_COMPOUNDCURVE   = MDSYS_SCHEMA + "." + TAG_ST_COMPOUNDCURVE;
    public static final String TAG_MDSYS_ST_CURVE           = MDSYS_SCHEMA + "." + TAG_ST_CURVE;
    public static final String TAG_MDSYS_ST_CURVEPOLYGON    = MDSYS_SCHEMA + "." + TAG_ST_CURVEPOLYGON;
    public static final String TAG_MDSYS_ST_GEOMCOLLECTION  = MDSYS_SCHEMA + "." + TAG_ST_GEOMCOLLECTION;
    public static final String TAG_MDSYS_ST_GEOMETRY        = MDSYS_SCHEMA + "." + TAG_ST_GEOMETRY;
    public static final String TAG_MDSYS_ST_LINESTRING      = MDSYS_SCHEMA + "." + TAG_ST_LINESTRING;
    public static final String TAG_MDSYS_ST_MULTICURVE      = MDSYS_SCHEMA + "." + TAG_ST_MULTICURVE;
    public static final String TAG_MDSYS_ST_MULTILINESTRING = MDSYS_SCHEMA + "." + TAG_ST_MULTILINESTRING;
    public static final String TAG_MDSYS_ST_MULTIPOINT      = MDSYS_SCHEMA + "." + TAG_ST_MULTIPOINT;
    public static final String TAG_MDSYS_ST_MULTIPOLYGON    = MDSYS_SCHEMA + "." + TAG_ST_MULTIPOLYGON;
    public static final String TAG_MDSYS_ST_MULTISURFACE    = MDSYS_SCHEMA + "." + TAG_ST_MULTISURFACE;
    public static final String TAG_MDSYS_ST_POINT           = MDSYS_SCHEMA + "." + TAG_ST_POINT;
    public static final String TAG_MDSYS_ST_POLYGON         = MDSYS_SCHEMA + "." + TAG_ST_POLYGON;
    public static final String TAG_MDSYS_ST_SURFACE         = MDSYS_SCHEMA + "." + TAG_ST_SURFACE;
    
    public static enum POLYGON_RING_ORIENTATION {
        ORACLE,
        INVERSE,
        CLOCKWISE,
        ANTICLOCKWISE;
        
        public static POLYGON_RING_ORIENTATION fromString(String _ringOrientation) {
            for (POLYGON_RING_ORIENTATION rOrientn : SDO.POLYGON_RING_ORIENTATION.values()) {
                if (rOrientn.toString().equalsIgnoreCase(_ringOrientation) ) {
                    return rOrientn;
                }
            }
            return SDO.POLYGON_RING_ORIENTATION.ORACLE;
        }

    }

    public static POLYGON_RING_ORIENTATION shapePolygonOrientation = POLYGON_RING_ORIENTATION.INVERSE;

    public static double[] reverseOrdinates(int      _dim,
                                            double[] _ordinates) 
    {
        if ( _ordinates == null || _ordinates.length==0 )
            return _ordinates;
        double[] ret = new double[_ordinates.length];
        int totalCoords = _ordinates.length/_dim;
        int fromCoord = totalCoords - 1;
        int fromOrd = 0,
            toOrd   = 0;
        for ( int i=0; i<totalCoords; i++, fromCoord-- ) 
        {
            toOrd   = i * _dim;
            fromOrd = fromCoord * _dim;
            for ( int k=0; k<_dim; k++) {
                ret[toOrd+k] = _ordinates[fromOrd+k];
                // LOGGER.info("ret["+(toOrd+k)+"] = " + ret[toOrd+k] + "  _ordinates["+(toOrd+k)+"] = " + _ordinates[toOrd+k]);
            }
        }
        return ret;
    } 
    
    public static JGeometry getGeometry(ARRAY _dimArray,
                                        int   _srid)
    throws SQLException
    {
        if ( _dimArray == null ) {
            return null;
        }
        ARRAY dimArray =  _dimArray;
        if ( dimArray.getDescriptor().getSQLName().getName().equals(SDO.TAG_MDSYS_SDO_DIMARRAY) ) 
        {
            String DIM_NAME = "";
            double SDO_LB   = Double.MAX_VALUE;
            double SDO_UB   = Double.MAX_VALUE;
            double SDO_TOL  = Double.MAX_VALUE;
            double minX = 0.0, minY = 0.0, maxX = 0.0, maxY = 0.0;
            Datum[] objs = dimArray.getOracleArray();
            for (int i =0; i < objs.length; i++) {
                STRUCT dimElement = (STRUCT)objs[i];
                Datum data[] = dimElement.getOracleAttributes();
                DIM_NAME = data[0].stringValue();
                SDO_LB   = data[1].doubleValue();
                SDO_UB   = data[2].doubleValue();
                SDO_TOL  = data[3].doubleValue();
                if ( i==0 ) {
                    minX = SDO_LB;
                    maxX = SDO_UB;
                } else if ( i==1 ) {
                    minY = SDO_LB;
                    maxY = SDO_UB;                    
                }
            }
            return new JGeometry(minX,minY,maxX,maxY,_srid>0?_srid : SDO.NULL_SRID);
        }
        return null;
    }

    public static JGeometry rectangle2Polygon2D(JGeometry _rectangle) {
        // We only map in 2D so don't worry about loss of other dimensions (yet)
        double[] LL = _rectangle.getFirstPoint();
        double[] UR = _rectangle.getLastPoint();
        int[] elemInfo = {1,1003,1};
        double[] ordArray = {LL[0],LL[1],
                             UR[0],LL[1],
                             UR[0],UR[1],
                             LL[0],UR[1],
                             LL[0],LL[1]};
        return new JGeometry(2003,_rectangle.getSRID(),elemInfo,ordArray);
    }

    public static Point2D getLabelPoint(JGeometry _geo) {
        if ( _geo.getLabelPoint()!=null )
            return _geo.getLabelPoint();
        else {
            double[] points = _geo.getFirstPoint();
            return new Point2D.Double(points[0],points[1]); // Only need X and Y ordinate
        } 
    }

    public static boolean hasMeasure(int _fullGType) {
        return ((_fullGType/100) % 10) == 0 ? (_fullGType > 4000 ? true : false) : true;
    }

    public static boolean hasMeasure(STRUCT _struct) {
        try {
            if ( _struct == null ||
                 ( _struct.getSQLTypeName().equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY) == false &&
                   _struct.getSQLTypeName().indexOf("MDSYS.ST_")==-1) ) {
                return false;
            }
            STRUCT stGeom = _struct;
            String sqlTypeName = _struct.getSQLTypeName();
            if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
                stGeom = SDO.getSdoFromST(_struct);
            } 
            return hasMeasure(SDO.getFullGType(stGeom,2000));
        } catch (SQLException sqle) {
          return false;
        }
    }

    public static boolean hasZ(int _fullGType ) {
        int numberOrdinates = _fullGType/1000;
        switch ( numberOrdinates ) {
          case 4 : return true;
          case 3 : return ! hasMeasure(_fullGType);
          default:
          case 2 : return false;
        }
    }  
  
    public static boolean hasZ(STRUCT _struct) {
        try {
            if ( _struct == null ||
                 ( _struct.getSQLTypeName().equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY) == false &&
                   _struct.getSQLTypeName().indexOf("MDSYS.ST_")==-1) ) {
                return false;
            }
            STRUCT stGeom = _struct;
            String sqlTypeName = _struct.getSQLTypeName();
            if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
                stGeom = SDO.getSdoFromST(_struct);
            } 
            return hasZ(SDO.getFullGType(_struct,2000));
        } catch (SQLException sqle) {
          return false;
        }
    }

    public static ShapeType getShapeType(int     _fullGType,
                                         boolean _measure)
    {
        int gType = 1;
        int fullGType = _fullGType;
        if ( _fullGType < 2000 ) {
            gType = _fullGType;
            fullGType += 2000;
        } else
            gType = _fullGType % 10;

        switch (gType) {
          case JGeometry.GTYPE_POINT         :      if (hasZ(fullGType) && hasMeasure(fullGType) ) return _measure ? ShapeType.POINTM : ShapeType.POINTZ;
                                               else if (hasZ(fullGType) )                      return ShapeType.POINTZ;
                                               else if (hasMeasure(fullGType) )                return ShapeType.POINTM;
                                               else                                            return ShapeType.POINT;
          case JGeometry.GTYPE_MULTIPOINT    :      if (hasZ(fullGType) && hasMeasure(fullGType) ) return _measure ? ShapeType.MULTIPOINTM : ShapeType.MULTIPOINTZ;
                                               else if (hasZ(fullGType) )                      return ShapeType.MULTIPOINTZ;
                                               else if (hasMeasure(fullGType) )                return ShapeType.MULTIPOINTM;
                                               else                                            return ShapeType.MULTIPOINT;
          case JGeometry.GTYPE_CURVE         : 
          case JGeometry.GTYPE_MULTICURVE    :      if (hasZ(fullGType) && hasMeasure(fullGType) ) return _measure ? ShapeType.ARCM : ShapeType.ARCZ;
                                               else if (hasZ(fullGType) )                      return ShapeType.ARCZ;
                                               else if (hasMeasure(fullGType) )                return ShapeType.ARCM;
                                               else                                            return ShapeType.ARC;
          case JGeometry.GTYPE_POLYGON       :  
          case JGeometry.GTYPE_MULTIPOLYGON  : 
          case J3D_Geometry.GTYPE_SOLID      : 
          case J3D_Geometry.GTYPE_MULTISOLID :      if (hasZ(fullGType) && hasMeasure(fullGType) ) return _measure ? ShapeType.POLYGONM : ShapeType.POLYGONZ;
                                               else if (hasZ(fullGType) )                      return ShapeType.POLYGONZ;
                                               else if (hasMeasure(fullGType) )                return ShapeType.POLYGONM;
                                               else                                            return ShapeType.POLYGON;
          case JGeometry.GTYPE_COLLECTION    :   
                                      default: return ShapeType.UNDEFINED;
        }
    }

    public static Constants.GEOMETRY_TYPES discoverGeometryType( int    _fullGType,
                                                                 String _existingGType) 
    {
        int gType = 1;
        int fullGType = _fullGType;
        if ( _fullGType < 2000 ) {
            gType = _fullGType;
            fullGType += 2000;
        } else {
            gType = _fullGType % 10;
        }
        Constants.GEOMETRY_TYPES existingGeometryType = com.spdba
                                                           .dbutils
                                                           .Constants
                                                           .GEOMETRY_TYPES
                                                           .valueOf(_existingGType.toUpperCase());
         Constants.GEOMETRY_TYPES geometryType = com.spdba
                                                   .dbutils
                                                   .Constants
                                                   .GEOMETRY_TYPES
                                                   .UNKNOWN;
         switch (gType) {
          case JGeometry.GTYPE_COLLECTION    : geometryType = com.spdba
                              .dbutils
                              .Constants
                              .GEOMETRY_TYPES
                              .COLLECTION;   break;
          case JGeometry.GTYPE_POINT         : geometryType = com.spdba
                              .dbutils
                              .Constants
                              .GEOMETRY_TYPES
                              .POINT;        break;
          case JGeometry.GTYPE_MULTIPOINT    : geometryType = com.spdba
                              .dbutils
                              .Constants
                              .GEOMETRY_TYPES
                              .MULTIPOINT;   break;
          case JGeometry.GTYPE_CURVE         : geometryType = com.spdba
                              .dbutils
                              .Constants
                              .GEOMETRY_TYPES
                              .LINE;         break;
          case JGeometry.GTYPE_MULTICURVE    : geometryType = com.spdba
                              .dbutils
                              .Constants
                              .GEOMETRY_TYPES
                              .MULTILINE;    break;
          case JGeometry.GTYPE_POLYGON       : geometryType = com.spdba
                              .dbutils
                              .Constants
                              .GEOMETRY_TYPES
                              .POLYGON;      break;
          case JGeometry.GTYPE_MULTIPOLYGON  : geometryType = com.spdba
                              .dbutils
                              .Constants
                              .GEOMETRY_TYPES
                              .MULTIPOLYGON; break;
          case J3D_Geometry.GTYPE_SOLID      : geometryType = com.spdba
                              .dbutils
                              .Constants
                              .GEOMETRY_TYPES
                              .SOLID;        break;
          case J3D_Geometry.GTYPE_MULTISOLID : geometryType = com.spdba
                              .dbutils
                              .Constants
                              .GEOMETRY_TYPES
                              .MULTISOLID;   break;
          default: LOGGER.warn("(SDO_Geometry.discoverGeometryType) Unsupported Geometry Type: " + gType );
        }
        // Now do comparison
        if ( existingGeometryType.equals(geometryType) )                                  // POINT.equal.POINT etc
            return geometryType;
        if ( existingGeometryType.equals(com.spdba
                                           .dbutils
                                           .Constants
                                           .GEOMETRY_TYPES
                                           .UNKNOWN) )
            return geometryType;
        if ( existingGeometryType.equals(com.spdba
                                           .dbutils
                                           .Constants
                                           .GEOMETRY_TYPES
                                           .COLLECTION) )
            return com.spdba
                      .dbutils
                      .Constants
                      .GEOMETRY_TYPES
                      .COLLECTION;
        if ( geometryType.toString().indexOf(geometryType.toString())!=-1 )  // MULTIPOINT.contains.POINT etc
            return geometryType;
        else 
            return com.spdba
                      .dbutils
                      .Constants
                      .GEOMETRY_TYPES
                      .COLLECTION;                       // MULTIPOINT and LINE etc 
     }
    
    /**
     * @method getOrientedPointMBR
     * @description MBR of oriented point has to be manually calculated from manipulation of sdo_ordinate_array
     * @param _geo
     * @return
     * @method @method
     * @author @author Simon Greener, June 2010
     */
    public static Envelope getOrientedPointMBR(JGeometry _geo) 
    {
        // Single oriented point uses sdo_ordinate array just as oriented multi point does
        //
        double points[] = _geo.getOrdinatesArray();
        int dim = _geo.getDimensions();
        int coord = 1;
        Envelope mbr = new Envelope(Constants.MAX_PRECISION);
        Point2D point = null;
        for ( int i = 0; i < points.length; i += dim ) {
            if ( coord%dim == 1 ) // Save first point for use with its oriented point
                point = new Point2D.Double(points[i], points[i + 1]);
            else /* oriented */ {
                // Calculate oriented point position
                // and then calc MBR of the pair and union its MBR
                //
                mbr.setMaxMBR(point.getX(),
                              point.getY(),
                              point.getX() + points[i],
                              point.getY() + points[i+1]);
            }
            coord++;
        }
        return mbr;
    }

    public static Envelope getOrdinatesMBR(JGeometry _geo) 
    {
        if ( _geo.isOrientedPoint() || _geo.isOrientedMultiPoint() ) {
            return getOrientedPointMBR(_geo);
        }
        
        // get ordinates
        //
        double points[] = _geo.getOrdinatesArray();
        if ( points==null || points.length==0 )
            return null;
        int dim         = _geo.getDimensions();
        Envelope mbr = new Envelope(Constants.MAX_PRECISION);
        for ( int i = 0; i < points.length; i += dim ) {
            mbr.setMaxMBR(points[i],points[i+1],
                          points[i],points[i+1]);
        }
        return mbr;
    }

    /**
     * Get MBR for select Geometry object
     * @param _st
     * @return geometry object MBR
     * @throws SQLException
     * @author Simon Greener, 1st June 2010
     *          Corrected MBR to reflect 3D etc objects
     *          getMBR does not honour oriented Points so constructed getOrientedPointMBR
     */
    public static Envelope getGeoMBR(STRUCT _struct) 
    {
        if (_struct == null) return null;
        try {
            STRUCT stGeom = _struct;
            String sqlTypeName = _struct.getSQLTypeName();
            if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
                stGeom = SDO.getSdoFromST(_struct);
            } 
            JGeometry geo = JGeometry.load(stGeom);
            return getGeoMBR(geo);
        } catch (SQLException sqle) {
           return null;
        }
    }

    public static Envelope getGeoMBR(JGeometry _geo) 
    {
        if (_geo == null) return null;
        
        // getMBR returns:
        // a double array containing the minX,minY, maxX,maxY value of the MBR for 2D or
        // a double array containing the minX,minY,minZ maxX,maxY, maxZ value of the MBR for 3D
        //
        int dims = _geo.getDimensions();
        if ( _geo.isOrientedPoint() || _geo.isOrientedMultiPoint() ) {
            return getOrientedPointMBR(_geo);
        } else {
            // getMBR() doesn't seem to return measures in MBR if of type 3302 etc
            //
            if ( _geo.getLRMDimension()==dims )
                dims = 2;
            double[] mbr = null;
            try {
                // getMBR() Gets the MBR of this geometry. When a JSDOGeoemtry is first instantiated from a 
                // db geometry STRUCT, no MBR is computed. The MBR exists only after the first call to this method. 
                // The MBR will be recalcuated only when the geoemtry's structure has been modified.
                //
                mbr = _geo.getMBR();
            } catch (Exception e) {
                try {
                  mbr = _geo.getMBR();
                } catch (Exception e2) {
                  mbr = null; 
                }
            }
            if ( mbr == null )
                return null;
            if ( mbr.length < 4 || Double.isInfinite(mbr[0]) || Double.isNaN(mbr[0]) )
                return getOrdinatesMBR(_geo);
            if ( mbr.length < 4 )
                return null;
            switch ( dims ) {
                case 4  : return new Envelope(mbr[0], mbr[1], mbr[2], mbr[3]);
                case 3  : return new Envelope(mbr[0], mbr[1], mbr[3], mbr[4]);
                case 2  : 
                default : return new Envelope(mbr[0], mbr[1], mbr[2], mbr[3]); 
            }
        }

    }

    public static Envelope getGeoMBR(List/*<JGeometry>*/ _geomSet) 
    {
        if (_geomSet == null || _geomSet.size() == 0) return null;

        Envelope mbr = new Envelope(Constants.MAX_PRECISION);
        Iterator/*<JGeometry>*/ iter = _geomSet.iterator();
        while (iter.hasNext()) {
            mbr.setMaxMBR(SDO.getGeoMBR((JGeometry)iter.next()));
        }
        return mbr;
    }

    public static double[] validateRectangle(int _dim,
                                             int _etype,
                                             double[] _ordinates) 
    {
        if ( _etype == 1003 ) {
            switch ( _dim ) {
                case 4  : return new double[] {Math.min(_ordinates[0],_ordinates[4]), Math.min(_ordinates[1],_ordinates[5]), _ordinates[2], _ordinates[3],
                                               Math.max(_ordinates[0],_ordinates[4]), Math.max(_ordinates[1],_ordinates[5]), _ordinates[6], _ordinates[7]};
                case 3  : return new double[] {Math.min(_ordinates[0],_ordinates[3]), Math.min(_ordinates[1],_ordinates[4]), _ordinates[2], 
                                               Math.max(_ordinates[0],_ordinates[3]), Math.max(_ordinates[1],_ordinates[4]), _ordinates[6], _ordinates[7]};
                case 2  : 
                default : return new double[] {Math.min(_ordinates[0],_ordinates[2]), Math.min(_ordinates[1],_ordinates[3]), 
                                               Math.max(_ordinates[0],_ordinates[2]), Math.max(_ordinates[1],_ordinates[3])}; 
            }
        } else if ( _etype == 2003 ) {
            switch ( _dim ) {
                case 4  : return new double[] {Math.max(_ordinates[0],_ordinates[4]), Math.max(_ordinates[1],_ordinates[5]), _ordinates[2], _ordinates[3],
                                               Math.min(_ordinates[0],_ordinates[4]), Math.min(_ordinates[1],_ordinates[5]), _ordinates[6], _ordinates[7]};
                case 3  : return new double[] {Math.max(_ordinates[0],_ordinates[3]), Math.max(_ordinates[1],_ordinates[4]), _ordinates[2], 
                                               Math.min(_ordinates[0],_ordinates[3]), Math.min(_ordinates[1],_ordinates[4]), _ordinates[6], _ordinates[7]};
                case 2  : 
                default : return new double[] {Math.max(_ordinates[0],_ordinates[2]), Math.max(_ordinates[1],_ordinates[3]), 
                                               Math.min(_ordinates[0],_ordinates[2]), Math.min(_ordinates[1],_ordinates[3])}; 
            }            
        }
        return _ordinates;
    }
    
    public static STRUCT setFullGType(STRUCT _struct, int _gType) 
    {
        if (_struct == null)
            return _struct;
        try {
            Datum data[] = _struct.getOracleAttributes();
            if (data == null) return _struct;
            Connection localConnection = DBConnection.getConnection(); 
            if ( localConnection==null )
                return _struct;
            NUMBER SDO_GTYPE = new NUMBER( _gType );            
            Datum attributes[] = new Datum[]{
                      SDO_GTYPE,
                      data[1],
                      data[2],
                      data[3],
                      data[4]
                  };
            return toSTRUCT( localConnection, attributes, SDO.TAG_MDSYS_SDO_GEOMETRY );      
        } catch (SQLException sqle) {
            return _struct;
        }
    }

    private static int discoverGType(STRUCT _struct) {
      if (_struct == null)
          return -1;
      return JGeometry.GTYPE_POINT;
    }

    public static int getFullGType(STRUCT _struct,
                                   int    _nullValue) 
    {
      // Note Returning null for null sdo_geometry structure
        if (_struct == null) {
          return _nullValue;
        }
      try {
          String sqlTypeName = _struct.getSQLTypeName();
          Datum data[] = _struct.getOracleAttributes();
          if (sqlTypeName.equalsIgnoreCase(SDO.TAG_MDSYS_VERTEX_TYPE) ) {
              return (data[2] != null) ? ( data[3] != null ? 4001 : 3001 ) : 2001;
          } else if ( sqlTypeName.equalsIgnoreCase(SDO.TAG_MDSYS_SDO_POINT_TYPE) ) {
              double[] ords = SDO.asDoubleArray(_struct,Double.NaN);
              return Double.isNaN(ords[2]) ? 2001 : 3001;
          } 
          // Else ST_ or SDO_
          STRUCT stGeom = _struct;
          if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
              stGeom = SDO.getSdoFromST(_struct);
          } 
          data = stGeom.getOracleAttributes();
          Datum datum = data[0];
          if (datum == null) {
              return _nullValue;
          }
          return ((NUMBER)datum).intValue();
      } catch (SQLException sqle) {
          return _nullValue;
      }
    }
    
    public static int getGType(STRUCT _struct) {
      return getGType(_struct,discoverGType(_struct));
    }
    
    public static int getGType(STRUCT _struct,
                               int    _nullValue) 
    {
        // Note Returning null for null sdo_geometry structure
        if (_struct == null) {
            return _nullValue;
        }
        try {
            STRUCT stGeom = _struct;
            String sqlTypeName = _struct.getSQLTypeName();
            if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
                stGeom = SDO.getSdoFromST(_struct);
            } 
            Datum data[] = stGeom.getOracleAttributes();
            Datum datum = data[0];
            if (datum == null) {
                return _nullValue;
            }
            return ((NUMBER)datum).intValue() % 10;
        } catch (SQLException sqle) {
            return _nullValue;
        }
    }

    public static int getMeasureDimension(STRUCT _struct) 
    {
        // Note Returning null for null sdo_geometry structure
        if (_struct == null) {
            return 0;
        }
        int fullGtype = getFullGType (_struct,0);
        int dimension = 0;
        if ( fullGtype != 0 ) {
            dimension = (int)((fullGtype % 1000) / 100);
        }
        return dimension;
    }

    public static int getDimension(STRUCT _struct,
                                   int    _nullValue) 
    {
        // Note Returning null for null sdo_geometry structure
        if (_struct == null)
            return _nullValue;
        try {
            STRUCT stGeom = _struct;
            String sqlTypeName = _struct.getSQLTypeName();
            if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
                stGeom = SDO.getSdoFromST(_struct);
            } 
            Datum data[] = stGeom.getOracleAttributes();
            Datum datum = data[0];
            if (datum == null) {
                return _nullValue;
            }
            return ((NUMBER)datum).intValue() / 1000;
        } catch (SQLException sqle) {
            return _nullValue;
        }
    }

    public static int getSRID(STRUCT _struct) {
      return getSRID(_struct, SDO.SRID_NULL);
    }
    
    public static int getSRID(STRUCT _struct,
                              int    _nullValue) 
    {
        if (_struct == null) {
            return _nullValue;
        }
        try {
            STRUCT stGeom = _struct;
            String sqlTypeName = _struct.getSQLTypeName();
            if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
                stGeom = SDO.getSdoFromST(_struct);
            } 
            Datum data[] = stGeom.getOracleAttributes();
            return asInteger(data[1], _nullValue);
        } catch (SQLException sqle) {
            return _nullValue;
        }
    }

    public static int getSRID(Struct _struct,
                              int    _nullValue) 
    {
        if (_struct == null) {
            return _nullValue;
        }
        try {
            Struct stGeom = _struct;
            String sqlTypeName = _struct.getSQLTypeName();
            if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
                stGeom = SDO.getSdoFromST(_struct);
            } 
            Object data[] = stGeom.getAttributes();
            return asInteger(data[1], _nullValue);
        } catch (SQLException sqle) {
            return _nullValue;
        }
    }

    public static STRUCT setSRID(STRUCT _struct, 
                                 int    _SRID) 
    {
        if (_struct == null) {
            return _struct;
        }
        try {
            Datum data[] = _struct.getOracleAttributes();
            if (data == null) return _struct;
            Connection localConnection = DBConnection.getConnection(); 
            if ( localConnection==null ) return _struct;
            NUMBER SDO_SRID = _SRID == SDO.SRID_NULL ? null : new NUMBER( _SRID );            
            Datum attributes[] = new Datum[]{
                      data[0],
                      SDO_SRID,
                      data[2],
                      data[3],
                      data[4]
                  };
            return toSTRUCT( localConnection, attributes, SDO.TAG_MDSYS_SDO_GEOMETRY );      
        } catch (SQLException sqle) {
            return _struct;
        }
    }
    
    /** Convience method for STRUCT construction. */
    private static STRUCT toSTRUCT( Connection _conn,
                                    Datum      _attributes[], 
                                    String     _dataType )
            throws SQLException
    {
        if( _dataType.startsWith("*.")){
            _dataType = "DRA."+_dataType.substring(2);
        }
        StructDescriptor descriptor = StructDescriptor.createDescriptor( _dataType, _conn );
        return new STRUCT( descriptor, _conn, _attributes );
    }

    public static Struct getSdoFromST(Struct _struct) 
    {
        if (_struct == null) {
            return null;
        }
        try {
            String sqlTypeName = _struct.getSQLTypeName();
            if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
                Datum[] data = (Datum[])_struct.getAttributes();
                if (data == null) return _struct;
                return (Struct)data[0];
            } else {
                return _struct;
            }
        } catch (SQLException sqle) {
            LOGGER.error("SDO_Geometry.getSdoFromST: " + sqle.toString());
            return null;
        }
    }

    public static STRUCT getSdoFromST(STRUCT _struct) 
    {
        if (_struct == null) {
            return null;
        }
        try {
            String sqlTypeName = _struct.getSQLTypeName();
            if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
                Datum data[] = _struct.getOracleAttributes();
                if (data == null) return _struct;
                return (STRUCT)data[0];
            } else {
                return _struct;
            }
        } catch (SQLException sqle) {
            LOGGER.error("SDO_Geometry.getSdoFromST: " + sqle.toString());
            return null;
        }
    }

    public static double[] getSdoPoint(STRUCT _struct) {
      return getSdoPoint(_struct,Double.NaN);
    }
    
    public static double[] getSdoPoint(STRUCT _struct,
                                       double _nullValue) 
    {
        if (_struct == null)
            return null;
        try {
            STRUCT stGeom = _struct;
            String sqlTypeName = _struct.getSQLTypeName();
            if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
                stGeom = SDO.getSdoFromST(_struct);
            } 
            Datum data[] = stGeom.getOracleAttributes();
            return asDoubleArray((STRUCT)data[2], _nullValue);
        } catch (SQLException sqle) {
            return null;
        }
    }

    public static int[] getSdoElemInfo(STRUCT _struct) {
      return getSdoElemInfo(_struct,0);
    }
    
    public static int[] getSdoElemInfo(STRUCT _struct,
                                       int    _nullValue) 
    {
        if (_struct == null) {
            return null;
        }
        try {
            STRUCT stGeom = _struct;
            String sqlTypeName = _struct.getSQLTypeName();
            if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
                stGeom = SDO.getSdoFromST(_struct);
            } 
            Datum data[] = stGeom.getOracleAttributes();
            return asIntArray((ARRAY)data[3], _nullValue);
        } catch (SQLException sqle) {
            return null;
        }
    }

    public static int getNumberCoordinates(STRUCT _struct) 
    {
        if (_struct == null) {
            return -1;
        }
        try {
            STRUCT stGeom = _struct;
            String sqlTypeName = _struct.getSQLTypeName();
            if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
                stGeom = SDO.getSdoFromST(_struct);
            } 
            Datum data[] = stGeom.getOracleAttributes();
          if (data[2]!=null && data[4]==null) {
                return 1;
            }
            return asDoubleArray((ARRAY)data[4], Double.NaN).length / 
                   getDimension(_struct, 2);
      } catch (SQLException sqle) {
          return -1;
      }
    }
    
    public static int getNumberOrdinates(STRUCT _struct) {
        if (_struct == null) {
            return -1;
        }
        try {
            STRUCT stGeom = _struct;
            String sqlTypeName = _struct.getSQLTypeName();
            if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
                stGeom = SDO.getSdoFromST(_struct);
            } 
            Datum data[] = stGeom.getOracleAttributes();
            if (data[2]!=null && data[4]==null) {
                // it is a point encoded in sdo_point_type
                STRUCT sdoPoint = (STRUCT)data[2];
                double[] ords = asDoubleArray(sdoPoint,Double.NaN);
                return Double.isNaN(ords[2]) ? 2 : 3;
            }
            return asDoubleArray((ARRAY)data[4], Double.NaN).length;
      } catch (SQLException sqle) {
          return -1;
      }
    }
    
    public static double[] getSdoOrdinates(STRUCT _struct) {
      return getSdoOrdinates(_struct,Double.NaN);
    }
    
    public static double[] getSdoOrdinates(STRUCT _struct,
                                           double _nullValue) 
    {
        if (_struct == null) {
            return null;
        }
        try {
            STRUCT stGeom = _struct;
            String sqlTypeName = _struct.getSQLTypeName();
            if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
                stGeom = SDO.getSdoFromST(_struct);
            } 
            Datum data[] = stGeom.getOracleAttributes();
            return asDoubleArray((ARRAY)data[4], _nullValue);
        } catch (SQLException sqle) {
            return null;
        }
    }

    public static String applyPrecision(String        _geom, 
                                        DecimalFormat _formatter, 
                                        int           _foldOrds) 
    {
        boolean valueConversion = false;
        boolean sdoOrdinateArray = false;
        double ordinate = 0.0;
        int ords = -1;
        int tokens = 0;
        boolean separatorHandling = false;
        String formatString = " )(,";
        if ( _formatter.getDecimalFormatSymbols().getDecimalSeparator() == ',' ) {
            // We have to splice the ordinates back together. 
            // Luckily the formatter will not have any groupingSymbol so numbers will be of the form 
            // left , right
            separatorHandling = true;
        }
        StringTokenizer dst = new StringTokenizer(_geom,formatString,true);
        String tok = "", prevTok = ""; 
        String output = "";
        while ( dst.hasMoreTokens() ) 
        {
            tokens++;
            tok = dst.nextToken();
            if (tok.indexOf("SDO_ELEM_INFO_ARRAY")!=-1) {
                if ( _foldOrds > 0 ) output += "\n";
            } if (tok.indexOf("SDO_ORDINATE_ARRAY")!=-1 ) {
                if ( _foldOrds > 0 ) output += "\n";
                valueConversion = true;
                sdoOrdinateArray = true;
                ords = -1;
            } else if ( tok.indexOf("SDO_POINT_TYPE")!=-1 ) {
                  valueConversion = true;
                  if ( _foldOrds > 0 ) output += "\n";
                  ords = -1;
            } else if ( tok.equals(")") ) {
                ords = -1;
                valueConversion = false;
            }
            if ( valueConversion ) 
            { 
                if ( tok.equals(",") ) 
                    continue;
                
                if ( Character.isDigit(tok.toCharArray()[0]) ||
                     tok.startsWith("-") ||
                     tok.startsWith("+") )
                {
                    try {
                        ords++;
                        if ( separatorHandling ) 
                        {
                            if ( ords > 0 && ords % 2 == 1 ) 
                            {
                              ordinate = Double.parseDouble(prevTok +"." + tok);
                              output += _formatter.format(ordinate) + "," ;
                              prevTok = "";
                            } else {
                              prevTok = tok;
                            }
                        } else {
                            prevTok = "";
                            ordinate = Double.parseDouble(tok);
                            output += _formatter.format(ordinate) + "," ;
                        }
                        if ( sdoOrdinateArray && Strings.isEmpty(prevTok) &&
                             ords  > 0 && 
                             (ords+1) % _foldOrds == 0 ) 
                        {
                          output += "\n";         
                        }
                    } catch(NumberFormatException e) {
                    }
                } else 
                    output += tok;
            } else 
              output += tok;
        }
        return output.replaceAll(",)",")").replaceAll(",\n)",")");
    }

    public static boolean isPoint(STRUCT _struct) {
        if ( _struct == null ) {
            return false;
        }
        return ( (getFullGType(_struct,1000) % 1000 ) == 1);
    }
    
    /**
     * @function isRectangle
     * @precis JGeometry.isRectangle does not work in all cases
     * @param _geo
     * @return
     * @author Simon Greener, April 4th 2010
     */
    public static boolean isRectangle(JGeometry _geo) {
        if (_geo == null)
            return false;
  
        if (_geo.isPoint() )
            return false;
        
        if (_geo.isRectangle())
            return true;
  
        int[] eia = _geo.getElemInfo();
        for (int i = 0; i < (eia.length / 3); i++) {
            if ((eia[(i * 3) + 1] == 1003 || eia[(i * 3) + 1] == 2003) &&
                eia[(i * 3) + 2] == 3) {
                return true;
            }
        }
        return false;
    }
  
    /**
     * @function hasArc
     * @precis JGeometry.hasCompoundArc/isCircle, are wrapped in a new function
     *         like isRectangle
     * @param _geo
     * @return
     * @author Simon Greener, April 4th 2010
     */
    public static boolean hasArc(JGeometry _geo) {
        if (_geo == null)
            return false;
  
        if (_geo.isPoint() )
            return false;
        
        if (_geo.hasCircularArcs() || _geo.isCircle())
            return true;
  
        int[] eia = _geo.getElemInfo();
        for (int i = 1; i < (eia.length / 3); i = (i * 3) + 1) {
            if ((eia[i] == 1005 || eia[i] == 2005 || eia[i] == 4) ||
                (eia[i] == 2 && eia[i + 1] == 2)) {
                return true;
            }
        }
        return false;
    }
  
    /**
     * @function hasArc
     * @precis wrapper over hasArc(JGeometry)
     * @param _struct
     * @return
     * @author Simon Greener, January 12th 2011
     */
    public static boolean hasArc(STRUCT _struct) {
      if (_struct == null) return false;
      try {
          STRUCT stGeom      = _struct;
          String sqlTypeName = _struct.getSQLTypeName();
          if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
              stGeom = SDO.getSdoFromST(_struct);
          } 
          JGeometry geo = JGeometry.load(stGeom);
          return hasArc(geo);
      } catch (SQLException sqle) {
        return false;
      }
    }
  
    /**
     * @function printGType
     * @param _gtype
     * @param _hasArc
     * @author Simon Greener, April 2010
     *          Useful function for debugging JGeometries
     */
    public static String printGType(int _gtype, boolean _hasArc) {
        String compound = _hasArc ? "(C)" : "";
        switch (_gtype) {
        case JGeometry.GTYPE_COLLECTION:
            return "COLLECTION" + compound;
        case JGeometry.GTYPE_CURVE:
            return "CURVE" + compound;
        case JGeometry.GTYPE_MULTICURVE:
            return "MULTICURVE" + compound;
        case JGeometry.GTYPE_MULTIPOINT:
            return "MULTIPOINT";
        case JGeometry.GTYPE_MULTIPOLYGON:
            return "MULTIPOLYGON" + compound;
        case JGeometry.GTYPE_POINT:
            return "POINT";
        case JGeometry.GTYPE_POLYGON:
            return "POLYGON" + compound;
        }
        return "UNKNOWN";
    }

    public static double getLength(STRUCT _struct, 
                                   int    _precision) {
        Geometry g = asJTSGeometry(_struct,
                                   _precision);
        if (g==null) {
            return Double.NaN;
        }
        return g.getLength();
    }

    public static double getArea(STRUCT _struct, 
                                 int    _precision) {
        Geometry g = asJTSGeometry(_struct,
                                   _precision);
        if (g==null) {
            return Double.NaN;
        }
        return g.getArea();
    }

    public static Geometry asJTSGeometry(STRUCT _struct, 
                                         int    _precision) 
    {
        // - construct conversion utility for Oracle geometry objects
        OraReader oracleConverter = new OraReader(null); // doesn't need the Oracle connection for what we're using it for        
        GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(_precision));
        Geometry g = asJTSGeometry(_struct, oracleConverter, geometryFactory);
        return g;
    }
    
    public static Geometry asJTSGeometry(STRUCT          _struct, 
                                         OraReader       _oraReader,
                                         GeometryFactory _geomFactory) 
    {
        if ( _oraReader == null || _geomFactory == null ) {
            return null;
        }
        Geometry geom = null;
        
        // Skip whole record IFF this geometry is for the SHP file and is NULL
        //
        try {
            STRUCT stGeom = _struct;
            String sqlTypeName = _struct.getSQLTypeName();
            if ( sqlTypeName.indexOf("MDSYS.ST_")==0 ) {
                stGeom = SDO.getSdoFromST(_struct);
            } 
            geom = _oraReader.read(stGeom);
            if (geom == null) {
                return null;   
            }
        } catch (SQLException e) {
            LOGGER.warn("(SDO_Geometry.asJTSGeometry) Error converting SDO_Geometry to JTS Geometry (" + e.getMessage() + ")");
            return null;
        }
        
        /**if (geom instanceof LineString) {
             geom = _geomFactory.createMultiLineString(new LineString[] { (LineString) geom });
           } else {
             geom = _geomFactory.createGeometry(geom); // do this to assign the PrecisionModel
           } **/
        geom = _geomFactory.createGeometry(geom); // do this to assign the PrecisionModel
        return geom;
    }

    /**
     * @function gType
     * @param _geom
     * @author Simon Greener, April 2010
     *          Useful function for creating SDO_GEOMETRY SDO_GTYPEs numbers
     *          as JGeometry class does not do this.
     */
    public static int gType(JGeometry _geom) 
    {
        if (_geom == null )
            return 0;
        return ((_geom.getDimensions() * 1000) +
                ((_geom.isLRSGeometry() && _geom.getDimensions() == 3) ? 300 :
                 ((_geom.isLRSGeometry() && _geom.getDimensions() == 4) ? 400 :
                  0)) + _geom.getType());
    }
    
    /** ======================================================================================== **/
    
    /** @description: These functions present an Oracle Datum (STRUCT) as appropriate Java types
     * @author     : Simon Greener - March 2010 - From JTS
     **/
    public static int[] asIntArray(ARRAY array, int DEFAULT) throws SQLException {
        if (array == null)
            return null;
        if (DEFAULT == 0)
            return array.getIntArray();
  
        return asIntArray(array.getOracleArray(), DEFAULT);
    }
  
    /** Presents Datum[] as a int[] */
    public static int[] asIntArray(Datum[] data,
                                   final int DEFAULT) throws SQLException {
        if (data == null)
            return null;
        int array[] = new int[data.length];
        for (int i = 0; i < data.length; i++) {
            array[i] = asInteger(data[i], DEFAULT);
        }
        return array;
    }
  
    /** Presents datum as an int */
    public static int asInteger(Datum datum,
                                final int DEFAULT) throws SQLException {
        if (datum == null)
            return DEFAULT;
        return ((NUMBER)datum).intValue();
    }
  
    public static int asInteger(Object datum,
                                final int DEFAULT) throws SQLException {
        if (datum == null)
            return DEFAULT;
        return ((NUMBER)datum).intValue();
    }
    
    /** Presents datum as a double */
    public static double asDouble(Datum datum,
                                  final double DEFAULT) throws SQLException {
        if (datum == null)
            return DEFAULT;
        return ((NUMBER)datum).doubleValue();
    }
  
    /** Presents struct as a double[] */
    public static double[] asDoubleArray(STRUCT struct,
                                         final double DEFAULT)
    throws SQLException {
        if (struct == null)
            return null;
        return asDoubleArray(struct.getOracleAttributes(), DEFAULT);
    }
  
    /** Presents array as a double[] */
    public static double[] asDoubleArray(ARRAY array,
                                         final double DEFAULT) 
    throws SQLException {
        if (array == null)
            return null;
        if (DEFAULT == 0)
            return array.getDoubleArray();
  
        return asDoubleArray(array.getOracleArray(), DEFAULT);
    }
  
    /** Presents Datum[] as a double[] */
    public static double[] asDoubleArray(Datum[] data,
                                         final double DEFAULT) 
    throws SQLException {
        if (data == null)
            return null;
        double array[] = new double[data.length];
        for (int i = 0; i < data.length; i++) {
            array[i] = asDouble(data[i], DEFAULT);
        }
        return array;
    }
    /** End of Oracle Datum (STRUCT) / Java type conversion functions
    */

    public static POLYGON_RING_ORIENTATION getPolygonRingOrientation() {
        return shapePolygonOrientation;
    }

    public static void setPolygonRingOrientation(String _ro) {
        if (Strings.isEmpty(_ro) ) {
            shapePolygonOrientation = POLYGON_RING_ORIENTATION.ORACLE;
        } else {
            String polygonOrientation = _ro.toUpperCase(); 
            for (POLYGON_RING_ORIENTATION b : POLYGON_RING_ORIENTATION.values()) {
                if (b.toString().equalsIgnoreCase(_ro)) {
                    shapePolygonOrientation = b;
                }
             }
        }
    }

    public static void setPolygonRingOrientation( POLYGON_RING_ORIENTATION _orientation) {
        shapePolygonOrientation = _orientation;
    }

    public static Geometry Struct2Geometry( OraReader         _geomConverter,
                                            GeometryFactory   _geomFactory,
                                            STRUCT            _shape) 
    {
        // Convert Struct to Geometry object
        // PrecisionModel is assigned during conversion
        //
        Geometry jGeom = null;
        if ( _shape != null ) {
            try {
                jGeom = _geomConverter.read(_shape);
            } catch (SQLException e) {
                jGeom = null;
            }
            if ( jGeom != null) 
            {
                if (jGeom instanceof LineString) {
                    jGeom = _geomFactory.createMultiLineString(new LineString[] { (LineString) jGeom });
                } else if (getPolygonRingOrientation() != POLYGON_RING_ORIENTATION.ORACLE) {
                    // LOGGER.debug("Shape2Geometry: " + getPolygonRingOrientation() + " Geometry is " + jGeom.getGeometryType() );
                    LinearRing    eRing = null;
                    LinearRing[] iRings = null;
                    Polygon        poly = null;
                    if (jGeom instanceof Polygon) {
                        poly = (Polygon) jGeom;
                        if (getPolygonRingOrientation() == POLYGON_RING_ORIENTATION.INVERSE ||
                            getPolygonRingOrientation() == POLYGON_RING_ORIENTATION.CLOCKWISE ) {
                          eRing = (LinearRing)poly.getExteriorRing().reverse(); 
                        } else if (getPolygonRingOrientation() == POLYGON_RING_ORIENTATION.ANTICLOCKWISE ) {
                          eRing = (LinearRing)poly.getExteriorRing(); 
                        }
                        iRings = new LinearRing[poly.getNumInteriorRing()];
                        for (int i=0; i < poly.getNumInteriorRing();  i++) {
                            // Oracle polygons inner rings have clockwise rotation
                            if ( getPolygonRingOrientation() == POLYGON_RING_ORIENTATION.INVERSE  ||
                                 getPolygonRingOrientation() == POLYGON_RING_ORIENTATION.ANTICLOCKWISE ) {
                                iRings[i] = (LinearRing)poly.getInteriorRingN(i).reverse(); 
                            } else if ( getPolygonRingOrientation() == POLYGON_RING_ORIENTATION.CLOCKWISE ) {
                                iRings[i] = (LinearRing)poly.getInteriorRingN(i); 
                           }
                        }
                        jGeom = _geomFactory.createPolygon(eRing, iRings);
                    } else if (jGeom instanceof MultiPolygon ) {
                        MultiPolygon mPoly = (MultiPolygon) jGeom;
                        Polygon[]    polys = new Polygon[mPoly.getNumGeometries()];
                        for (int p=0; p < mPoly.getNumGeometries(); p++ ) {
                            poly   = (Polygon)mPoly.getGeometryN(p);
                            if (getPolygonRingOrientation() == POLYGON_RING_ORIENTATION.INVERSE ||
                                getPolygonRingOrientation() == POLYGON_RING_ORIENTATION.CLOCKWISE ) {
                                eRing = (LinearRing)poly.getExteriorRing().reverse(); 
                            } else if (getPolygonRingOrientation() == POLYGON_RING_ORIENTATION.ANTICLOCKWISE ) {
                                eRing = (LinearRing)poly.getExteriorRing(); 
                            }
                            iRings = new LinearRing[poly.getNumInteriorRing()];
                            for (int i=0; i < poly.getNumInteriorRing();  i++) {
                                // Oracle polygons inner rings have clockwise rotation
                                if ( getPolygonRingOrientation() == POLYGON_RING_ORIENTATION.INVERSE  ||
                                     getPolygonRingOrientation() == POLYGON_RING_ORIENTATION.ANTICLOCKWISE ) {
                                  iRings[i] = (LinearRing)poly.getInteriorRingN(i).reverse(); 
                                } else if ( getPolygonRingOrientation() == POLYGON_RING_ORIENTATION.CLOCKWISE ) {
                                  iRings[i] = (LinearRing)poly.getInteriorRingN(i); 
                                }
                            }
                            polys[p] = _geomFactory.createPolygon(eRing, iRings);
                        }
                        jGeom = _geomFactory.createMultiPolygon(polys);
                    } 
                } else {
                    jGeom = _geomFactory.createGeometry(jGeom); // do this to assign the PrecisionModel                    
                }
            }   
        }
        return jGeom;
    }

    public static GeometryProperties getGeometryProperties(STRUCT _geoStruct) 
    {
        GeometryProperties geomMetadata = new GeometryProperties();
        try {
            int FULL_GTYPE                 = 2000;
            int DIMENSION                  = 2;
            int SRID = SDO.NULL_SRID;
            Constants.GEOMETRY_TYPES gtype = com.spdba
                                                .dbutils
                                                .Constants
                                                .GEOMETRY_TYPES
                                                .UNKNOWN;
            ShapeType shpType              = ShapeType.UNDEFINED;
            
            if ( _geoStruct != null ) {
                if ( _geoStruct.getSQLTypeName().indexOf("MDSYS.ST_")==0 ) {
                    _geoStruct = SDO.getSdoFromST(_geoStruct);
                }
                if ( _geoStruct.getSQLTypeName().equals(SDO.TAG_MDSYS_SDO_GEOMETRY) ) 
                {
                    FULL_GTYPE = SDO.getFullGType(_geoStruct, FULL_GTYPE);
                    DIMENSION = SDO.getDimension(_geoStruct,  DIMENSION);
                    shpType = SDO.getShapeType(FULL_GTYPE, SDO.hasMeasure(FULL_GTYPE)); 
                    geomMetadata.addShapeType(shpType);
                    SRID = SDO.getSRID(_geoStruct, geomMetadata.getSRID());
                    gtype = SDO.discoverGeometryType(FULL_GTYPE, com.spdba
                                                                    .dbutils
                                                                    .Constants
                                                                    .GEOMETRY_TYPES
                                                                    .UNKNOWN.toString());
                } else {
                  FULL_GTYPE = SDO.getFullGType(_geoStruct,FULL_GTYPE);
                  DIMENSION  = FULL_GTYPE / 1000;                            
                  SRID = SDO.NULL_SRID;
                  shpType = ShapeType.UNDEFINED;
                }
            }
            geomMetadata.setFullGType(FULL_GTYPE);
            geomMetadata.setDimension(DIMENSION);
            geomMetadata.setSRID(SRID);
            geomMetadata.addShapeType(shpType);
            geomMetadata.setShapefileType(shpType);
            geomMetadata.setGeometryType(gtype);
        } catch (SQLException sqle) {
            LOGGER.warn("SDO_GEOMETRY.GetGeometryProperties: Exception caught when examining geometry " + sqle.getMessage());
        }
        return geomMetadata;        
    }
    
}
