package com.spdba.dbutils;

import com.spdba.dbutils.editors.AddPoint;
import com.spdba.dbutils.editors.GeometryEditor;
import com.spdba.dbutils.editors.RemovePoint;
import com.spdba.dbutils.filters.ChangePointFilter;
import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.sql.DBConnection;
import com.spdba.dbutils.sql.SQLConversionTools;
import com.spdba.dbutils.tools.MathUtils;
import com.spdba.dbutils.tools.Strings;
import com.spdba.dbutils.tools.Tools;

import java.io.IOException;

import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;

import javax.xml.parsers.ParserConfigurationException;

import oracle.jdbc.OracleTypes;

import oracle.sql.ARRAY;
import oracle.sql.CLOB;
import oracle.sql.STRUCT;

import org.locationtech.jts.algorithm.MinimumBoundingCircle;
import org.locationtech.jts.densify.Densifier;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.CoordinateSequence;
import org.locationtech.jts.geom.Envelope;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryCollection;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.LinearRing;
import org.locationtech.jts.geom.MultiLineString;
import org.locationtech.jts.geom.MultiPoint;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.Polygon;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.geom.Triangle;
import org.locationtech.jts.io.gml2.GMLReader;
import org.locationtech.jts.io.gml2.GMLWriter;
import org.locationtech.jts.io.oracle.OraReader;
import org.locationtech.jts.io.oracle.OraWriter;
import org.locationtech.jts.operation.buffer.BufferOp;
import org.locationtech.jts.operation.buffer.BufferParameters;
import org.locationtech.jts.operation.buffer.OffsetCurveBuilder;
import org.locationtech.jts.operation.linemerge.LineMerger;
import org.locationtech.jts.operation.overlay.OverlayOp;
import org.locationtech.jts.operation.overlay.snap.GeometrySnapper;
import org.locationtech.jts.operation.polygonize.Polygonizer;
import org.locationtech.jts.operation.valid.IsValidOp;
import org.locationtech.jts.operation.valid.TopologyValidationError;
import org.locationtech.jts.precision.GeometryPrecisionReducer;
import org.locationtech.jts.simplify.DouglasPeuckerSimplifier;
import org.locationtech.jts.simplify.TopologyPreservingSimplifier;
import org.locationtech.jts.simplify.VWSimplifier;
import org.locationtech.jts.triangulate.DelaunayTriangulationBuilder;
import org.locationtech.jts.triangulate.VertexTaggedGeometryDataMapper;
import org.locationtech.jts.triangulate.VoronoiDiagramBuilder;

import org.xml.sax.SAXException;
//import org.locationtech.jts.geom.util.GeometryEditor;
// Visvalingam-Whyatt Simplifier

public class JTS
{

    protected static final int mixedCoordinateDimensions = -9;
    protected static final int                mixedSRIDs = -9;
    
    private static class Result {
        protected static GeometryFactory      gf = null;
        protected static Collection        geoms = null;
        protected static int                SRID = 0; // If -9 then mixedSRIDs in set
        protected static int coordinateDimension = 0; // If -9 then mixedCoordinateDimensions in set
    }

    protected static final boolean   THROW_SQL_EXCEPTION = true;
    protected static final boolean  WRITE_MESSAGE_TO_LOG = false;

    private static void log(String  _message,
                            boolean _throw) 
    throws SQLException
    {
        if ( _throw ) {
            throw new SQLException(_message);
        } else {
            System.err.println(_message);            
        }
                           
    }

    /**
    * Finds first sdo_geometry column in resultset metadata
    * @param _metaData : ResultSetMetaData : SQL Cursor holding a least one sdo_geometry
    * @return Integer pointing to column holding sdo_geometry object.
    **/
    public static int firstSdoGeometryColumn(ResultSetMetaData _metaData)
     throws SQLException 
    {
        int position = -1;
        try {
            for (int i = 1; i <= _metaData.getColumnCount(); i++) {
                if ( _metaData.getColumnType(i) == OracleTypes.STRUCT &&
                     _metaData.getColumnTypeName(i).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY) ) {
                    position = i;
                    break;
                }
            }
        }
        catch (SQLException sqle) {
            JTS.log("Error finding first Sdo Geometry Column: " + sqle.getSQLState(),THROW_SQL_EXCEPTION);
        }
        return position;
    }

    /* ============ Resultset/Array Conversion =========== */
    
    private static Result _convertArray(oracle.sql.ARRAY _group,
                                        int              _precision,
                                        boolean          _expandCollection)
    throws SQLException
    {
        // Check geometry parameters
        //
        if ( _group == null || _group.length() == 0 ) {
            return null;
        }
        try
        {
             // ArrayDescriptor geoms = ArrayDescriptor.createDescriptor("MDSYS.SDO_GEOMETRY_TYPE",DBConnection.getConnection());
             Object[] nestedObjects = (Object[])_group.getArray();
             // Create necessary factories etc
             //
             PrecisionModel pm = new PrecisionModel(Tools.getPrecisionScale(_precision)); // FIXED PrecisionModel
             Geometry     geom = null;
             Geometry    cGeom = null;
             STRUCT     struct = null;
             Result          r = new Result();
                       r.geoms = new ArrayList();
                        r.SRID = SDO.getSRID((STRUCT)nestedObjects[0], SDO.SRID_NULL);
                        r.SRID = r.SRID==0?SDO.SRID_NULL:r.SRID;
                          r.gf = new GeometryFactory(pm,r.SRID); 
             r.coordinateDimension = SDO.getDimension((STRUCT)nestedObjects[0],0);
             int geomCoordinateDimension = 0;
                            int geomSRID = r.SRID;
             OraReader      or = new OraReader(r.gf);
             // Convert passed in array to Collection of JTS Geometries
             for (int i=0;i<nestedObjects.length;i++) {
                 struct = (STRUCT)nestedObjects[i];
                 if (struct == null) { continue; }
                 if ( r.coordinateDimension != mixedCoordinateDimensions ) {
                     // Check
                     geomCoordinateDimension = SDO.getDimension(struct,0);
                     if ( geomCoordinateDimension != r.coordinateDimension ) {
                         r.coordinateDimension = mixedCoordinateDimensions;
                     }
                 }
                 geom = or.read(struct);
                 if (geom == null) { continue; }
                 if (r.SRID != mixedSRIDs) {
                     // Check is same as previous 
                     geomSRID = SDO.getSRID(struct,SDO.SRID_NULL);
                     geomSRID = geomSRID==0?SDO.SRID_NULL:geomSRID;
                     if (geomSRID != r.SRID) {
                         r.SRID = mixedSRIDs;
                     }
                 }
                 geom.setSRID(r.SRID);
                 if (_expandCollection && geom instanceof GeometryCollection) { 
                     // Extract any geometries in collection.
                     GeometryCollection gCollection = (GeometryCollection)geom;
                     for (int g=0; g<gCollection.getNumGeometries();g++) {
                         cGeom = gCollection.getGeometryN(g);
                         if (geom !=null) {
                             r.geoms.add(cGeom); // Add converted geometry to collection
                         }
                     }
                 } else {
                     r.geoms.add(geom); // Add converted geometry to collection
                 }
             }
             if (r.geoms.size()==0) {
                 return null;
             }
             return r;
         } catch (SQLException sqle) {
            JTS.log("(_convertArray) " + sqle.getMessage(),THROW_SQL_EXCEPTION);
         }
        return null;
    }

    private static Result _convertResultSet(ResultSet _resultSet,
                                            int       _precision,
                                            boolean   _expandCollection)
    throws SQLException
    {
        try
        {
            // ResultSet nullity checked in calling method
            //
            int geometryColumnIndex = firstSdoGeometryColumn(_resultSet.getMetaData());            
            if (geometryColumnIndex == -1) {
                JTS.log("(_convertResultSet) No SDO_GEOMETRY column can be found in resultset.",THROW_SQL_EXCEPTION);
            }

            Geometry cGeom = null;
            PrecisionModel   pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
            STRUCT        struct = null;
            Result            r = new Result();
                        r.geoms = new ArrayList();
            // Create GeometryFactory with FIXED PrecisionModel with NULL SRID 
            int            SRID = -9999;
            OraReader        or = null;
            _resultSet.setFetchDirection(ResultSet.FETCH_FORWARD);
            _resultSet.setFetchSize(150);
            ResultSetMetaData metaData = _resultSet.getMetaData();
            while(_resultSet.next()) 
            {
                if( metaData.getColumnType(geometryColumnIndex) != OracleTypes.STRUCT || 
                    !metaData.getColumnTypeName(geometryColumnIndex).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY)) {
                    continue;
                }
                struct = (STRUCT)_resultSet.getObject(geometryColumnIndex);
                if (struct == null) { continue; }
                if (SRID == -9999) {
                    SRID = SDO.getSRID(struct, SDO.SRID_NULL);
                    r.gf = new GeometryFactory(pm,SRID);
                    or = new OraReader(r.gf);
                }
                Geometry geom = or.read(struct);
                if (geom == null) { continue; }
                geom.setSRID(SDO.getSRID(struct, SDO.SRID_NULL));
                // Add converted geometry to collection
                if (_expandCollection && geom instanceof GeometryCollection) { 
                    // Extract any geometries in collection.
                    GeometryCollection gCollection = (GeometryCollection)geom;
                    for (int g=0; g<gCollection.getNumGeometries();g++) {
                        cGeom = gCollection.getGeometryN(g);
                        if (geom !=null) {
                            r.geoms.add(cGeom);
                        }
                    }
                } else {
                    r.geoms.add(geom);
                }
            }
            if (r.geoms.size()==0) {
                return null;
            }
            return r;
        } catch (SQLException sqle) {
            JTS.log("(_convertResultSet) " + sqle.getMessage(),THROW_SQL_EXCEPTION);
        }
        return null;
    }

    /* ================== GEOPROCESSING =================== */
    
     /**
     * Unions two geometries together using suppied p_precision to compare coordinates.
     *
     * @param _geom1     : STRUCT : First geometry subject to overlay action
     * @param _geom2     : STRUCT : Second geometry subject to overlay action
     * @param _precision : int    : Number of decimal places of precision when comparing ordinates.
     * @return STRUCT    : Result of Union as SDO_Geometry
     * @author Simon Greener 
     * @since  August 2011, Original Coding
     * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     *               http://creativecommons.org/licenses/by-sa/2.5/au/
     */ 
    public static STRUCT ST_Union(STRUCT _geom1, 
                                  STRUCT _geom2, 
                                  int    _precision)
    throws SQLException
    {
        Tools.setPrecisionScale(_precision);
        return _overlay(_geom1, _geom2, OverlayOp.UNION);
    }

    /**
    * Computes difference between two geometries using suppied p_precision to compare coordinates.
    *
    * @param _geom1     : STRUCT : First geometry subject to overlay action
    * @param _geom2     : STRUCT : Second geometry subject to overlay action
    * @param _precision : int    : Number of decimal places of precision when comparing ordinates.
    * @return STRUCT    : Result of Difference as SDO_Geometry
    * @author Simon Greener
    * @since August 2011, Original Coding
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
    */
    public static STRUCT ST_Difference(STRUCT _geom1, 
                                       STRUCT _geom2, 
                                       int    _precision)
    throws SQLException
    {
        Tools.setPrecisionScale(_precision);
        return _overlay(_geom1, _geom2, OverlayOp.DIFFERENCE);
    }

    /**
    * Computes intersection between two geometries using suppied p_precision to compare coordinates.
    *
    * @param _geom1     : STRUCT : First geometry subject to overlay action
    * @param _geom2     : STRUCT : Second geometry subject to overlay action
    * @param _precision : int    : Number of decimal places of precision when comparing ordinates.
    * @return STRUCT    : Result of Intersection as SDO_Geometry
    * @author Simon Greener
    * @since August 2011, Original Coding
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
    */
    public static STRUCT ST_Intersection(STRUCT _geom1, 
                                         STRUCT _geom2, 
                                         int    _precision)
    throws SQLException
    {
        Tools.setPrecisionScale(_precision);
        return _overlay(_geom1, _geom2, OverlayOp.INTERSECTION);
    }

    /**
    * Computes xor between two geometries using suppied p_precision to compare coordinates.
    *
    * @param _geom1     : STRUCT : First geometry subject to overlay action
    * @param _geom2     : STRUCT : Second geometry subject to overlay action
    * @param _precision : int    : Number of decimal places of precision when comparing ordinates.
    * @return STRUCT    : Result of Xor as Sdo_Geometry object
    * @author Simon Greener
    * @since August 2011, Original Coding
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
    */
    public static STRUCT ST_Xor(STRUCT _geom1,
                                STRUCT _geom2,
                                int    _precision)
    throws SQLException
    {
        Tools.setPrecisionScale(_precision);
        return _overlay(_geom1, _geom2, OverlayOp.SYMDIFFERENCE);
    }

    /**
     * @param _geom1         : STRUCT : First geometry subject to overlay action
     * @param _geom2         : STRUCT : Second geometry subject to overlay action
     * @param _operationType : int    : See OverlayOp eg INTERSECTION, UNION etc
     * @return SDO_GEOMETRY  : Result of overlay as SDO_Geometry
     * @throws SQLException
     * @author Simon Greener
     * @since August 2011, Original Coding
     */
    private static STRUCT _overlay(STRUCT _geom1,
                                   STRUCT _geom2,
                                   int    _operationType)
     throws SQLException
    {
        String opType = "ST_";
        switch (_operationType) {
            case OverlayOp.DIFFERENCE    : opType += "DIFFERENCE"; break;
            case OverlayOp.INTERSECTION  : opType += "INTERSECTION"; break;
            case OverlayOp.UNION         : opType += "UNION"; break;
            case OverlayOp.SYMDIFFERENCE : opType += "XOR"; break;
        }
        // Check geometry parameters
        //
        if ( _geom1 == null || _geom2 == null ) {
            JTS.log(opType + ": One or other of supplied Sdo_Geometries is NULL.",THROW_SQL_EXCEPTION);
        }
        STRUCT resultSDOGeom = null;
        try
        {
            // Extract and Check SRIDs from SDO_GEOMETYs
            //
            int SRID = SDO.getSRID(_geom1, SDO.SRID_NULL);
            if ( SRID != SDO.getSRID(_geom2, SDO.SRID_NULL) ) {
                JTS.log(opType + ": SDO_Geometry SRIDs not equal",THROW_SQL_EXCEPTION);
            }
            // Convert Geometries
            //
            PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale());
            GeometryFactory gf = new GeometryFactory(pm,SRID); 
            OraReader       or = new OraReader(gf);
            Geometry      geo1 = or.read(_geom1);
            Geometry      geo2 = or.read(_geom2);
            
            // Check converted geometries are valid
            //            
            if (   geo1 == null   ) { JTS.log(opType + ": Converted first geometry is NULL.",    THROW_SQL_EXCEPTION); return null; }
            if ( ! geo1.isValid() ) { JTS.log(opType + ": Converted first geometry is invalid.", THROW_SQL_EXCEPTION); return null; }
            if (   geo2 == null   ) { JTS.log(opType + ": Converted second geometry is NULL.",   THROW_SQL_EXCEPTION); return null; }
            if ( ! geo2.isValid() ) { JTS.log(opType + ": Converted second geometry is invalid.",THROW_SQL_EXCEPTION ); return null; }

            // Now do the overlay
            //
            try {
                Geometry resultGeom = null;
                resultGeom          = OverlayOp.overlayOp(geo1, geo2, _operationType);
                OraWriter        ow = new OraWriter(Math.min(Tools.getCoordDim(geo1), Tools.getCoordDim(geo2)));
                resultSDOGeom       = ow.write(resultGeom,
                                               DBConnection.getConnection());
            } catch (Exception e) {
                JTS.log(opType + ": " + e.toString(),THROW_SQL_EXCEPTION);
                return null;
            }
        } catch(SQLException sqle) {
            JTS.log(sqle.getMessage(),THROW_SQL_EXCEPTION);
        }
        return resultSDOGeom;
    }

    /**
     * Buffer a geometry using variety of parameters
     * @param _geom          : STRUCT : SDO_Geometry object subject to buffering
     * @param _distance      : number : Buffer distance
     *                                  _distance must be expressed in ordinate units eg m or decimal degrees
     * @param _precision     : int    : Number of decimal places of precision
     * @param _endCapStyle   : int    : One of BufferParameters.CAP_ROUND,
     *                                         BufferParameters.CAP_BUTT,
     *                                         BufferParameters.CAP_SQUARE
     * @param _joinStyle     : int    : One of BufferParameters.JOIN_ROUND, 
     *                                         BufferParameters.JOIN_MITRE, or 
     *                                         BufferParameters.JOIN_BEVEL
     * @param _quadrantSegs  : int    : Stroking of curves
     * @return SDO_GEOMETRY  : Result of buffer as SDO_Geometry object.
     * @throws SQLException
     * @author Simon Greener
     * @since August 2011, Original Coding
     * @copyright            : Simon Greener, 2011-2013
     * @license              : Creative Commons Attribution-Share Alike 2.5 Australia License. 
     *                         http://creativecommons.org/licenses/by-sa/2.5/au/
     */
    public static STRUCT ST_Buffer(STRUCT _geom,
                                   double _distance,
                                   int    _precision,
                                   int    _endCapStyle,
                                   int    _joinStyle,
                                   int    _quadrantSegs)
    throws SQLException
    {
        // Check geometry parameters
        //
        if ( _geom == null ) {
            JTS.log("ST_Buffer: Supplied Sdo_Geometry is NULL.",THROW_SQL_EXCEPTION);
        }
        /*
         * CAP_ROUND  The usual round end caps
         * CAP_FLAT   End caps are truncated flat at the line ends
         * CAP_SQUARE End caps are squared off at the buffer distance beyond the line ends
         */
        if ( _endCapStyle != BufferParameters.CAP_ROUND &&
             _endCapStyle != BufferParameters.CAP_FLAT &&
             _endCapStyle != BufferParameters.CAP_SQUARE ) {
            JTS.log("ST_Buffer: Supplied EndCapStyle parameter not one of ROUND("+BufferParameters.CAP_ROUND+
                                                                       "), FLAT("+BufferParameters.CAP_FLAT+
                                                                   ") or SQUARE("+BufferParameters.CAP_SQUARE+").",THROW_SQL_EXCEPTION);
        }         
        /*
        * JOIN_ROUND : Specifies a round join style.
        * JOIN_MITRE : Specifies a mitre join style.
        * JOIN_BEVEL : Specifies a bevel join style.
        */
        if ( _joinStyle != BufferParameters.JOIN_ROUND && 
             _joinStyle != BufferParameters.JOIN_MITRE &&
             _joinStyle != BufferParameters.JOIN_BEVEL ) {
            JTS.log("ST_Buffer: Supplied joinStyle parameter not one of ROUND("+BufferParameters.JOIN_ROUND+
                                                                    "), MITRE("+BufferParameters.JOIN_MITRE+
                                                                  ") or BEVEL("+BufferParameters.JOIN_BEVEL+").",THROW_SQL_EXCEPTION);
        }
        int quadrantSegments = _quadrantSegs==0 ? BufferParameters.DEFAULT_QUADRANT_SEGMENTS : Math.abs(_quadrantSegs);
        STRUCT resultSDOGeom = null;
        try
        {   
            // Convert Geometry
            //
            PrecisionModel      pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
            GeometryFactory     gf = new GeometryFactory(pm, SDO.getSRID(_geom, SDO.SRID_NULL)); 
            OraReader           or = new OraReader(gf);
            Geometry           geo = or.read(_geom);
            // Check converted geometry is valid
            //
            if (   geo == null )  {
                JTS.log("ST_Buffer: Conversion to JTS geometry failed.",THROW_SQL_EXCEPTION); return null; }
            if ( ! geo.isValid()) {
                JTS.log("ST_Buffer: Converted geometry is invalid.",THROW_SQL_EXCEPTION); return null; }
            // Now do the buffering
            //
            try {
                BufferParameters bufParam = new BufferParameters(quadrantSegments,
                                                                 _endCapStyle,
                                                                 _joinStyle,
                                                                 BufferParameters.DEFAULT_MITRE_LIMIT);
                bufParam.setSingleSided(false);
                Geometry buffer = BufferOp.bufferOp(geo,_distance,bufParam);
                OraWriter    ow = new OraWriter(SDO.getDimension(_geom,2));
                resultSDOGeom   = ow.write(buffer,
                                           DBConnection.getConnection());
            } catch (Exception e) {
                JTS.log("ST_Buffer: buffering failed with " + e.toString(),THROW_SQL_EXCEPTION);
            }
        } catch(SQLException sqle) {
            JTS.log(sqle.getMessage(),THROW_SQL_EXCEPTION);
        }
        return resultSDOGeom;
     }

    /**
    * Computes the Minimum Bounding Circle (MBC) for the points in a Geometry.
    * The MBC is the smallest circle which contains all the input points (this
    * is sometimes known as the Smallest Enclosing Circle). This is equivalent
    * to computing the Maximum Diameter of the input point set.
    * @param _geom : STRUCT : Geometry object subject to MBC action
    * @param _precision : int    : Number of decimal places of precision
    * @return STRUCT    : Result of MBC calculation as SDO_GEOMETRY object.
    * @throws SQLException
    * @author Martin Davis, Simon Greener
    * @since September 2011, Original Coding for use with Oracle.
    * @copyright : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
    *              http://creativecommons.org/licenses/by-sa/2.5/au/
    */
    public static STRUCT ST_MinimumBoundingCircle(STRUCT _geom,
                                                  int    _precision)
        throws SQLException
    {
        // Check geometry parameters
        //
        if ( _geom == null ) {
            JTS.log("ST_MinimumBoundingCircle: Supplied SDO_Geometry is NULL.",THROW_SQL_EXCEPTION);
        }
        STRUCT resultSDOGeom = null;
        try
        {
            // Convert Geometries
            //
            PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
            GeometryFactory gf = new GeometryFactory(pm, SDO.getSRID(_geom, SDO.SRID_NULL)); 
            OraReader       or = new OraReader(gf);
            Geometry       geo = or.read(_geom);
    
            // Check converted geometries are valid
            //
            if (   geo == null )  {
                JTS.log("ST_MinimumBoundingCircle: SDO_Geometry conversion to JTS geometry returned NULL.",THROW_SQL_EXCEPTION); } 
            if ( ! geo.isValid()) {
                JTS.log("ST_MinimumBoundingCircle: Converted geometry is invalid.",THROW_SQL_EXCEPTION);}
            
            // Now get MinimumBoundingCircle
            //
            try {
                MinimumBoundingCircle mbc = new MinimumBoundingCircle(geo);
                /*
                 * Gets a geometry which represents the Minimum Bounding Circle. 
                 * If the input is degenerate (empty or a single unique point), 
                 * this method will return an empty geometry or a single Point 
                 * geometry. Otherwise, a Polygon will be returned which approximates 
                 * the Minimum Bounding Circle. (Note that because the computed polygon 
                 * is only an approximation, it may not precisely contain all the 
                 * input points.)
                */
                Geometry circle = mbc.getCircle();
                OraWriter    ow = new OraWriter(Tools.getCoordDim(circle));
                resultSDOGeom   = ow.write(circle,
                                           DBConnection.getConnection());
            } catch (Exception e) {
                JTS.log("ST_MinimumBoundingCircle: creating circle failed with " + e.toString(),THROW_SQL_EXCEPTION);
                return null;
            }
          } catch(SQLException sqle) {
            JTS.log(sqle.getMessage(),THROW_SQL_EXCEPTION);
          }
          return resultSDOGeom;
       }

    /**
       * Densifies a geometry using a given distance tolerance,
       * and respecting the input geometry's PrecisionModel
       * @param _geom              : STRUCT : The sdo_geometry to densify
       * @param _precision         : int : number of decimal places of precision
       * @param _distanceTolerance : double : must be expressed in ordinate units eg m or decimal degrees
       * @return STRUCT            : The densified geometry as SDO_GEOMETRY object
       * @throws SQLException
       * @author Martin Davis, Simon Greener
       * @since September 2011, Original Coding for use with Oracle.
       * @copyright : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
       *              http://creativecommons.org/licenses/by-sa/2.5/au/
       */
    public static STRUCT ST_Densify(STRUCT _geom,
                                    int    _precision,
                                    double _distanceTolerance)
        throws SQLException
    {
        // Check geometry parameters
        //
        if ( _geom == null ) {
            JTS.log("ST_Densify: Supplied SDO_Geometry is NULL.",THROW_SQL_EXCEPTION);
        }
        STRUCT resultSDOGeom = null;
        try
        {
            // Convert Geometries
            //
            PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
            GeometryFactory gf = new GeometryFactory(pm, SDO.getSRID(_geom, SDO.SRID_NULL)); 
            OraReader       or = new OraReader(gf);
            Geometry       geo = or.read(_geom);
            // Check converted geometries are valid
            //
            if (   geo == null )   {
                JTS.log("ST_Densify: SDO_Geometry conversion to JTS geometry returned NULL.",THROW_SQL_EXCEPTION);}
            if ( ! geo.isValid() ) {
                JTS.log("ST_Densify: Converted geometry is invalid.",THROW_SQL_EXCEPTION); }
            // Now do densification
            //
            try {
                Densifier densifier = new Densifier(geo);
                densifier.setDistanceTolerance(_distanceTolerance);
                OraWriter  ow = new OraWriter(Tools.getCoordDim(geo));
                resultSDOGeom = ow.write(densifier.getResultGeometry(),
                                         DBConnection.getConnection());
            } catch (Exception e) {
                JTS.log("ST_Densify: Densifying geometry failed with " + e.toString(),THROW_SQL_EXCEPTION);
                return null;
            }
          } catch(SQLException sqle) {
            JTS.log(sqle.getMessage(),THROW_SQL_EXCEPTION);
          }
          return resultSDOGeom;
       }

    /* ================================ MEASURE ========================= */
    
     private static final int LENGTH   = 1;
     private static final int LENGTH3D = 2;
     private static final int AREA     = 3;

    /**
      * Computes area of supplied geometry.
      *
      * @param _geom       : STRUCT : sdo_geometry subject to area calculation
      * @param  _precision : int    : Number of decimal places of precision of resulting area
      * @return double     : Area of geometry as number
      * @author Simon Greener
      * @since September 2011, Original Coding
      * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
      *               http://creativecommons.org/licenses/by-sa/2.5/au/
      */
    public static double ST_Area(STRUCT _geom, 
                                 int    _precision)
    throws SQLException
    {
        return MathUtils.round(_AreaLength(_geom, JTS.AREA),_precision);
    }

      /**
      * Computes Length of supplied geometry.
      *
      * @param  _geom      : STRUCT : sdo_geometry subject to Length calculation
      * @param  _precision : int    : Number of decimal places of precision of resulting length
      * @return double     : Length of geometry as number
      * @author Simon Greener
      * @since September 2011, Original Coding
      * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
      *               http://creativecommons.org/licenses/by-sa/2.5/au/
      */
    public static double ST_Length(STRUCT _geom, 
                                   int    _precision)
    throws SQLException
    {
        return MathUtils.round(_AreaLength(_geom, JTS.LENGTH),_precision);
    }

    private static double _AreaLength(STRUCT _geom,
                                      int    _processingFlag )
      throws SQLException
    {
        // Check geometry parameters
        //
        if ( _geom == null ) {
            JTS.log("_AreaLength (private): Supplied SDO_Geometry is NULL.",THROW_SQL_EXCEPTION);
            return Double.NaN;
        }
        double result = 0.0;
        try
        {
            // Extract SRID from SDO_GEOEMTRY
            //
            int SRID = SDO.getSRID(_geom, SDO.SRID_NULL);
            
            // Convert Geometries
            //
            PrecisionModel  pm = new PrecisionModel();
            GeometryFactory gf = new GeometryFactory(pm,SRID); 
            OraReader       or = new OraReader(gf);
            Geometry       geo = or.read(_geom);
            
            // Check converted geometries are valid
            //
            if ( geo == null ) {
                JTS.log("_AreaLength (private): SDO_Geometry conversion to JTS geometry returned NULL.",THROW_SQL_EXCEPTION); return Double.NaN; }
            
            // Now do the calculation
            //
            try {
                switch (_processingFlag) {
                    case JTS.LENGTH   : result = geo.getLength(); break;
                    case JTS.LENGTH3D : result = geo.getLength(); break;  // For later.
                    case JTS.AREA     : result = geo.getArea(); break;
                }
            } catch (Exception e) {
                JTS.log("_AreaLength (private) failed with " + e.toString(),THROW_SQL_EXCEPTION);
                return 0.0;
            }
        } catch(SQLException sqle) {
            JTS.log(sqle.getMessage(),THROW_SQL_EXCEPTION);
        }
        return result;
     }

    /* ================================ Line Utils ============================================ */

    private static Geometry _convertToMultiPoint(LineString _lString) 
    {
        if ( _lString == null || ! ( _lString instanceof LineString) )  {
            return null;
        }
        GeometryFactory gf = new GeometryFactory(); 
        Coordinate[]    ca = _lString.getCoordinates();
        int numPoints = _lString.getNumPoints();
        Coordinate c = null;
        Collection points = new ArrayList();
        if (ca.length > 1) {
            for (int i=0;i<numPoints;i++) {
                c = ca[i];
                points.add(gf.createPoint(c));
            }
        }
        Geometry rLine = null;
        if ( points.size()>0) {
            Point[] pa = (Point[])points.toArray(new Point[0]);
            rLine = new MultiPoint(pa,gf);
            rLine.setSRID(_lString.getSRID());
        }
        return rLine; 
    }
    
    private static Geometry _pointsRemover(Geometry _line1,
                                           Geometry _line2,
                                           int      _precision) 
    {
        PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
        GeometryFactory gf = new GeometryFactory(pm, _line1.getSRID()); 

        Collection     newCoords = new ArrayList();
        Coordinate[] coordinates = null;

        Geometry line1 = GeometryPrecisionReducer.reduce(_line1,pm);
        Geometry line2 = GeometryPrecisionReducer.reduce(_line2,pm);
        
        int numPoints = line1.getNumPoints();
        coordinates   = line1.getCoordinates();        
        Coordinate  c = null;
        Point       p = null;
        if (coordinates.length > 1) {
            Geometry multiPoint2 = _convertToMultiPoint((LineString)line2);
            for (int i=0;i<numPoints;i++) {
                c = coordinates[i];
                p = gf.createPoint(c);
                boolean equals = p.relate(multiPoint2,"0FFFFFFF2");  // 0FFFFFFF2
                if ( ! equals ) {
                    newCoords.add(c);
                }
            }
        }
        Geometry rLine = null;
        if ( newCoords != null && newCoords.size() > 2 ) {
            Coordinate[] ca = (Coordinate[])newCoords.toArray(new Coordinate[0]);
            rLine = new LineString(gf.getCoordinateSequenceFactory().create(ca),gf);
            rLine.setSRID(_line1.getSRID());
        } 
        return rLine;
    }

    /**
     * ST_OneSidedBuffer -- Creates buffer on one side of the supplied linestring sdo_geometry
     *
     * @param  _geom         : STRUCT : LineString sdo_geometry object
     * @param  _offset       : double : Offset from line (+ve is left; -ve is right)
     * @param  _precision    : int    : Number of decimal places of precision of resulting length
     * @param  _endCapStyle  : int    : Specifies type of buffer and end cap: CAP_ROUND = 1; CAP_FLAT = 2; CAP_SQUARE = 3
     * @param  _joinStyle    : int    : Specifiies type of join style: JOIN_ROUND = 1; JOIN_MITRE = 2; JOIN_BEVEL = 3;
     * @param  _quadrantSegs : int    : The default number of facets into which to divide a fillet of 90 degrees.
     *                                  A value of 8 gives less than 2% max error in the buffer distance.
     *                                  For a max error of &lt; 1%, use QS = 12.
     *                                  For a max error of &lt; 0.1%, use QS = 18.
     * @return geometry      : Polygon on left or right of supplied line.
     * @author Simon Greener
     * @since September 2019, Original Coding
     * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     *               http://creativecommons.org/licenses/by-sa/2.5/au/
    */
    public static STRUCT ST_OneSidedBuffer(STRUCT _geom,
                                           double _offset,
                                           int    _precision,
                                           int    _endCapStyle,
                                           int    _joinStyle,
                                           int    _quadrantSegs) 
    throws SQLException
    {
        STRUCT resultSDOGeom = null;
        OraWriter ow = new OraWriter(SDO.getDimension(_geom,2));

        // Convert original linestring parameter
        PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
        GeometryFactory gf = new GeometryFactory(pm, SDO.getSRID(_geom));
        OraReader       or = new OraReader(gf);
        Geometry      line = or.read(_geom);
        
        // Check converted geometry is valid
        //
        if (   line == null   ) { JTS.log("ST_OneSidedBuffer: Converted geometry is NULL.",    THROW_SQL_EXCEPTION);  }
        if ( ! line.isValid() ) { JTS.log("ST_OneSidedBuffer: Converted geometry is invalid.", THROW_SQL_EXCEPTION);  }
        if ( ! (line instanceof LineString || line instanceof MultiLineString ) ) {
            JTS.log("ST_OneSidedBuffer: sdo_geometry parameter 1 can only be a (Multi)LineString.",THROW_SQL_EXCEPTION);
        }
        
        // Will only single side a Linestring
        if ( ! ( line instanceof LineString ||
                 line instanceof LinearRing || 
                 line instanceof MultiLineString ) 
           ) {
          return _geom;
        }

        // Get buffered Line as Geometry
        double      _mitreLimit = BufferParameters.DEFAULT_MITRE_LIMIT;
        BufferParameters     bp = new BufferParameters(
                                        _quadrantSegs,
                                        _endCapStyle,
                                        _joinStyle,
                                        _mitreLimit
                                 );
        bp.setSingleSided(true);
        OffsetCurveBuilder  ocb = new OffsetCurveBuilder(pm,bp);
        Coordinate[]     coords = ocb.getLineCurve(line.getCoordinates(),
                                                  _offset);
        Geometry oneSidedBuffer = gf.createPolygon(coords);
        if ( oneSidedBuffer == null ) {
            return _geom;
        }
        
        oneSidedBuffer.setSRID(line.getSRID());

        // Convert edited line back to STRUCT
        //
        resultSDOGeom = ow.write(oneSidedBuffer,
                                 DBConnection.getConnection());
        return resultSDOGeom;
    }

    /**
     * ST_OffsetLine -- Creates line on left or right of supplied line.
     *
     * @param  _geom         : STRUCT : LineString sdo_geometry object
     * @param  _offset       : double : Offset from line (+ve is left; -ve is right)
     * @param  _precision    : int    : Number of decimal places of precision of resulting length
     * @param  _endCapStyle  : int    : Specifies type of buffer and end cap: CAP_ROUND = 1; CAP_FLAT = 2; CAP_SQUARE = 3
     * @param  _joinStyle    : int    : Specifiies type of join style: JOIN_ROUND = 1; JOIN_MITRE = 2; JOIN_BEVEL = 3;
     * @param  _quadrantSegs : int    : The default number of facets into which to divide a fillet of 90 degrees.
     *                                  A value of 8 gives less than 2% max error in the buffer distance.
     *                                  For a max error of &lt; 1%, use QS = 12.
     *                                  For a max error of &lt; 0.1%, use QS = 18.
     * @return geometry      : LineString on left or right of supplied line.
     * @author Simon Greener
     * @since September 2019, Original Coding
     * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     *               http://creativecommons.org/licenses/by-sa/2.5/au/
    */    
    public static STRUCT ST_OffsetLine(STRUCT _geom,
                                       double _offset,
                                       int    _precision,
                                       int    _endCapStyle,
                                       int    _joinStyle,
                                       int    _quadrantSegs) 
    throws SQLException
    {
        STRUCT resultSDOGeom = null;
        OraWriter ow = new OraWriter(SDO.getDimension(_geom,2));

        // Convert original linestring parameter
        PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
        GeometryFactory gf = new GeometryFactory(pm, SDO.getSRID(_geom));
        OraReader       or = new OraReader(gf);
        Geometry      line = or.read(_geom);
        
        // Check converted geometry is valid
        //
        if (   line == null   ) { JTS.log("ST_OffsetLine: Converted geometry is NULL.",    THROW_SQL_EXCEPTION);  }
        if ( ! line.isValid() ) { JTS.log("ST_OffsetLine: Converted geometry is invalid.", THROW_SQL_EXCEPTION);  }
        if ( ! (line instanceof LineString || line instanceof MultiLineString ) ) {
            JTS.log("sdo_geometry parameter 1 can only be a (Multi)LineString.",THROW_SQL_EXCEPTION);
        }
        
        // Get buffered Line as Geometry
        double      _mitreLimit = BufferParameters.DEFAULT_MITRE_LIMIT;
        BufferParameters     bp = new BufferParameters(
                                        _quadrantSegs,
                                        _endCapStyle,
                                        _joinStyle,
                                        _mitreLimit
                                 );
        OffsetCurveBuilder ocb = new OffsetCurveBuilder(pm,bp);
        LineString  offsetLine = gf.createLineString(
                                    ocb.getOffsetCurve(line.getCoordinates(), 
                                                       _offset)
                                 );
        if ( offsetLine == null ) {
            return _geom;
        }
        
        offsetLine.setSRID(line.getSRID());

        // Convert edited line back to STRUCT
        //
        resultSDOGeom = ow.write(offsetLine,
                                 DBConnection.getConnection());
        return resultSDOGeom;
    }


    /**
     * Removes linear elements of _line from _geom.
     *
     * @param _line1     : sdo_geometry : linestring for whom _line points will be removed.
     * @param _line2     : sdo_geometry : linestring containing points to be removed.
     * @param _precision : int          : Number of decimal places of precision when comparing ordinates:
     *                                    Both geometries must have same precision so _precision is applied to both.
     * @param _keepBoundaryPoints : int : If 0 (false) end points of line2 linestring are also removed from line1; otherwise only interior line points are removed.
     * @return STRUCT    : Result of removal of _line2 from _line1
     * @throws SQLException
     * @since August 2018, Original Coding
     * @param _geom1 : STRUCT : First geometry subject to overlay action
     * @param _geom2 : STRUCT : Second geometry subject to overlay action
     * @author Simon Greener
     * @copyright : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     * http://creativecommons.org/licenses/by-sa/2.5/au/
     */
    public static STRUCT ST_LineDissolver(STRUCT _line1,
                                          STRUCT _line2,
                                          int    _precision,
                                          int    _keepBoundaryPoints) 
    throws SQLException
    {
        // Check geometry parameters
        //
        if ( _line1 == null || _line2 == null ) {
            JTS.log("ST_LineDissolver: One or other of supplied Sdo_Geometries is NULL.", THROW_SQL_EXCEPTION); 
        }
        
        // Extract and Check SRIDs from SDO_GEOMETYs
        //
        int SRID = SDO.getSRID(_line1, SDO.SRID_NULL);
        if ( SRID != SDO.getSRID(_line2, SDO.SRID_NULL) ) {
            JTS.log("ST_LineDissolver: SDO_Geometry SRIDs not equal.", THROW_SQL_EXCEPTION); 
        }
        
        int dims = SDO.getDimension(_line1,2);
        if ( dims != SDO.getDimension(_line2,2)) {
            JTS.log("ST_LineDissolver: SDO_Geometry dimensions are not equal.", THROW_SQL_EXCEPTION); 
        }
        
        STRUCT resultSDOGeom = null;
        try
        {
            Tools.setPrecisionScale(_precision);
            
            OraWriter       ow = new OraWriter(dims);
            PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
            GeometryFactory gf = new GeometryFactory(pm, SRID);
            OraReader       or = new OraReader(gf);
            Geometry     line1 = or.read(_line1);
            Geometry     line2 = or.read(_line2);

            // Check converted geometries are valid
            //
            if (   line1 == null   ) { JTS.log("ST_LineDissolver: Converted first geometry is NULL.",    THROW_SQL_EXCEPTION);  }
            if ( ! line1.isValid() ) { JTS.log("ST_LineDissolver: Converted first geometry is invalid.", THROW_SQL_EXCEPTION);  }
            if (   line2 == null   ) { JTS.log("ST_LineDissolver: Converted second geometry is NULL.",   THROW_SQL_EXCEPTION);  }
            if ( ! line2.isValid() ) { JTS.log("ST_LineDissolver: Converted second geometry is invalid.",THROW_SQL_EXCEPTION ); }

            // Only LineStrings are supported
            if ( ! (line1 instanceof LineString ) ) { JTS.log("ST_LineDissolver: _line1 can only be a LineString.",THROW_SQL_EXCEPTION); }
            if ( ! (line2 instanceof LineString ) ) { JTS.log("ST_LineDissolver: _line2 can only be a LineString.",THROW_SQL_EXCEPTION); }

            boolean isSimple = (ST_IsSimple(_line1) == "TRUE") ? true : false;

            // Remove original line's points from one sided buffer
            Geometry rLine = null;
            // First ensure common precision
            line1 = GeometryPrecisionReducer.reduce(line1,pm);
            line2 = GeometryPrecisionReducer.reduce(line2,pm);
            if ( Math.abs(_keepBoundaryPoints) == 0 ) {
                // Need to check if end point is not also duplicated elsewhere in the linestring.
                rLine = _pointsRemover(line1,
                                       line2,
                                       _precision);
            } else {
                rLine = line1.difference(line2);
            }
            // Convert modified line back to STRUCT
            resultSDOGeom = ow.write(rLine,
                                     DBConnection.getConnection());
            return resultSDOGeom;

        } catch (Exception e) {
            JTS.log(e.getMessage(),THROW_SQL_EXCEPTION);
        }
        return resultSDOGeom;
    }

     private static STRUCT _LineMerger(Collection      _lines,
                                       GeometryFactory _gf)
     throws SQLException
     {
        if (_lines == null || _lines.size()==0) {
              return null;
        }
        try
        {
            // Try to merges lines to form maximal-length linestrings.
            //
            LineMerger lm = new LineMerger();
            // Add will only add LineStrings to LineMerger
            //
            lm.add(_lines);
            Collection mlines = lm.getMergedLineStrings();
            if ( mlines == null || mlines.size() == 0 ) {
                return null;
            }
            // Construct an appropriate Geometry for return...
            //
            // GeometryCollection mergedLineStrings = new GeometryCollection(((Geometry[])mlines.toArray(new Geometry[0])),_gf);
            Geometry mergedLines = null;
            if ( mlines.size()==1) {
                Iterator ilines = mlines.iterator();
                mergedLines = (LineString)ilines.next();
            } else {
                mergedLines = new MultiLineString(((LineString[])mlines.toArray(new LineString[0])),_gf);
            }
            if (mergedLines==null || mergedLines.isEmpty()) {
                JTS.log("ST_LineMerger: Failed to convert merged line strings to suitable geometry type.",THROW_SQL_EXCEPTION);
                return null;
            } 
            
            OraWriter ow = new OraWriter(Tools.getCoordDim(mergedLines));
            return    ow.write(mergedLines,
                               DBConnection.getConnection());
          } catch (SQLException sqle) {
            JTS.log("_LineMerger: Failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
          }
          return null;
      }
     
     /**
      * Takes set of linestring geometries (eg mdsys.SDO_GEOMETRY_ARRAY) and constructs a collection 
      * of linear components to form maximal-length linestrings. The linear components are
      * returns as a MultiLineString.
      * @param _group     : ARRAY : Array of Linestring Geometries eg codesys.T_GEOMETRYSET or mdsys.SDO_GEOMETRY_ARRAY 
      * @param _precision : int   : Number of decimal places of precision when comparing ordinates.
      * @return STRUCT    : collection of linear sdo_geometries as MultiLineString.
      * @throws SQLException
      * @author Simon Greener
      * @since September 2011, Original Coding
      * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
      *               http://creativecommons.org/licenses/by-sa/2.5/au/
      */
     public static STRUCT ST_LineMerger(oracle.sql.ARRAY _group,
                                        int              _precision)
     throws SQLException
     {
         // Check geometry parameters
         //
         if ( _group == null || _group.length()==0) {
             JTS.log("ST_LineMerger: Empty array of sdo_geometries.",THROW_SQL_EXCEPTION);
         }
         try
         {
              // Convert passed in array to Collection of JTS Geometries
              //
              Result r = _convertArray(_group,_precision,true);
              if ( r==null || r.geoms == null || r.geoms.size()==0 ) {
                JTS.log("ST_LineMerger: Failed to extracted SDO_GEOMETRY objects from Array.",THROW_SQL_EXCEPTION);
              }
             // We know we have more than 0 geoms in the Result collection, so extract
             // first Geometry's SRID for use in creating GeometryFactory
             // 
             // GeometryFactory is set _convertArray
             return _LineMerger(r.geoms,r.gf);
          } catch (SQLException sqle) {
            JTS.log("ST_LineMerger: Failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
          }
          return null;
      }
     
       /**
        * Takes set of linestring geometries and constructs a collection of linear components to 
        * form maximal-length linestrings. The linear components are returns as a MultiLineString.
        * @param _resultSet : ResultSet : Cursor collection of Linestring Geometries in SELECT statement 
        * @param _precision : int       : Number of decimal places of precision when comparing ordinates.
        * @return STRUCT    : collection of linear sdo_geometries as MultiLineString.
        * @throws SQLException
        * @author Simon Greener
        * @since January 2012, Original Coding
        * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
        *               http://creativecommons.org/licenses/by-sa/2.5/au/
        */
       public static STRUCT ST_LineMerger(ResultSet _resultSet,
                                          int       _precision)
       throws SQLException
       {
           if ( _resultSet == null ) {
               JTS.log("ST_LineMerger: No ResultSet passed to ST_LineMerger.",THROW_SQL_EXCEPTION);
           }
           try { 
               Result linesObj = _convertResultSet(_resultSet,_precision,true);
               // Result GeometryFactory is created in _convertResultSet
               return _LineMerger(linesObj.geoms,linesObj.gf);
           } catch (SQLException sqle) {
               JTS.log("ST_LineMerger: Failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
           }
           return null;
       }
     
     private static STRUCT _nodeCollectionLinestrings(Collection _lines)
     throws SQLException
     {
        if (_lines == null || _lines.size()==0) {
            return null;
        }
        try
        {
            // Node the collection
            Geometry nodedLineStrings = null;
            Iterator iter = _lines.iterator();
            if ( iter.hasNext() ) {
                nodedLineStrings = (LineString)iter.next();
            }
            while (iter.hasNext() ) {
                nodedLineStrings = nodedLineStrings.union((LineString)iter.next());
            }
            if ( nodedLineStrings==null || nodedLineStrings.isEmpty() ) {
                return null;
            }
            OraWriter ow = new OraWriter(Tools.getCoordDim(nodedLineStrings));
            return ow.write(nodedLineStrings,
                            DBConnection.getConnection());
          } catch (SQLException sqle) {
            JTS.log("_nodeCollectionLinestrings: Failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
          }
          return null;
      }

    private static STRUCT _NodeLineStrings(Collection      _lines,
                                             GeometryFactory _gf)
    throws SQLException
    {
       if (_lines == null || _lines.size()==0 || _gf==null) {
           JTS.log("(_NodeLineStrings) collection is null or has no lines.",THROW_SQL_EXCEPTION);
       }
       try
       {
           // ------- Precision reduce collection ------------
           //
           Collection lineList = new ArrayList();
           Geometry geom = null;
           GeometryPrecisionReducer gpr = new GeometryPrecisionReducer(_gf.getPrecisionModel());
           Iterator iter = _lines.iterator();
           while (iter.hasNext() ) {
               geom = (Geometry)iter.next();
               if (geom instanceof LineString ||
                   geom instanceof LinearRing || 
                   geom instanceof MultiLineString ) {
                   geom = gpr.reduce(geom);
               } else if ( geom instanceof GeometryCollection) { 
                   // Extract any linestrings in collection.
                   GeometryCollection gCollection = (GeometryCollection)geom;
                   for (int g=0; g<gCollection.getNumGeometries();g++) {
                        geom = gCollection.getGeometryN(g);
                        if (geom instanceof LineString ||
                            geom instanceof LinearRing ||
                            geom instanceof MultiLineString ) {
                            geom = gpr.reduce(geom);
                        }
                   }
               } else {
                   JTS.log("(_NodeLineStrings): LineString/MultiLineString or GeometryCollection expected, " + geom.getGeometryType() + " found and skipped.",THROW_SQL_EXCEPTION);
                   continue;
               }
               if (geom!=null && geom.isValid()) {
                   lineList.add(geom);
               }
           }
           if ( lineList.isEmpty() ) {
               return null;
           }
           // ----- Node the precision reduced geometry collection --------
           //
           GeometryCollection nodedLineStrings = new GeometryCollection(((Geometry[])lineList.toArray(new Geometry[0])),_gf);
           geom = nodedLineStrings.union();
           if (geom==null || geom.isEmpty()) {
               return null;
           }
           OraWriter ow = new OraWriter(Tools.getCoordDim(nodedLineStrings));
           return ow.write(geom,DBConnection.getConnection());
         } catch (SQLException sqle) {
            JTS.log("(_NodeLineStrings) " + sqle.getMessage(),THROW_SQL_EXCEPTION);
         }
         return null;
     }

    /**
     * Takes set of linestring geometries and ensures all topological intersections not at a common
     * vertex are noded (ie a common vertex is inserted into each linestring).
     * @param _gCollection : STRUCT : Geometry collection (x004) or MultiLineStrings (x006)
     * @param _precision   : int    : Number of decimal places of precision when comparing ordinates.
     * @return STRUCT      : collection of linear sdo_geometries as MultiLineString.
     * @throws SQLException
     * @author Simon Greener
     * @since February 2013, Original Coding
     * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     *               http://creativecommons.org/licenses/by-sa/2.5/au/
     */
    public static STRUCT ST_NodeLineStrings(oracle.sql.STRUCT _gCollection,
                                            int               _precision)
    throws SQLException
    {
         // Check geometry parameters
         //
         if ( _gCollection == null ) {
             JTS.log("ST_NodeLinestrings: Supplied SDO_Geometry is NULL.",THROW_SQL_EXCEPTION);
         }
         try
         {
             PrecisionModel   pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
             GeometryFactory  gf = new GeometryFactory(pm, SDO.getSRID(_gCollection, SDO.SRID_NULL)); 
             OraReader        or = new OraReader(gf);
             Geometry        geo = or.read(_gCollection);
             // Check converted geometries are valid
             //
             if ( geo == null ) {
                 JTS.log("ST_NodeLinestrings: SDO_Geometry conversion to JTS geometry returned NULL.",THROW_SQL_EXCEPTION);
             }
             if ( ! ( geo instanceof GeometryCollection ||
                      geo instanceof MultiLineString ) ) {
                 JTS.log("ST_NodeLinestrings: SDO_Geometry is not a MultiLineString object or a GeometryCollection.",THROW_SQL_EXCEPTION);
             }
             // Extract geometry elements, checking each element, into a Collection of JTS Geometries
             //
             Collection lines = new ArrayList();
             Geometry    geom = null,
                         line = null;
             for (int i=0;i<geo.getNumGeometries();i++) {
                 geom = geo.getGeometryN(i);
                 if (geom == null) { continue; }
                 if (geom instanceof LineString ||
                     geom instanceof LinearRing  ) {
                     lines.add(geom);
                 } else if (geom instanceof MultiLineString) {
                     for (int j=0;i<geom.getNumGeometries();j++) {
                         line = geo.getGeometryN(j);
                         if (line == null) { continue; }
                         lines.add(line);                         
                     } 
                 } else {
                     JTS.log("ST_NodeLinestrings: LineString expected, " + geom.getGeometryType() + " found and skipped.",WRITE_MESSAGE_TO_LOG);
                     continue;
                 }
             }
             if (lines.isEmpty()) {
                 return null;
             }
             // -------------- Node the precision reduced geometry collection -------------------
             //
             return _NodeLineStrings(lines,gf);
         } catch (SQLException sqle) {
            JTS.log("ST_NodeLinestrings: failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
         }
         return null;
     }

     /**
      * Takes set of linestring geometries and ensures all topological intersections not at a common
      * vertex are noded (ie a common vertex is inserted into each linestring).
      * @param _group     : ARRAY : Array of Linestring Geometries eg codesys.T_GEOMETRYSET or mdsys.SDO_GEOMETRY_ARRAY 
      * @param _precision : int   : Number of decimal places of precision when comparing ordinates.
      * @return STRUCT    : collection of linear sdo_geometries as MultiLineString.
      * @throws SQLException
      * @author Simon Greener
      * @since February 2013, Original Coding
      * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
      *               http://creativecommons.org/licenses/by-sa/2.5/au/
      */
     public static STRUCT ST_NodeLineStrings(oracle.sql.ARRAY _group,
                                             int              _precision)
     throws SQLException
     {
          // Check geometry parameters
          //
          if ( _group == null || _group.length()==0 ) {
            JTS.log("ST_NodeLinestrings: Supplied geometry array is null or empty.",THROW_SQL_EXCEPTION);
          }
          try
          { 
              // Convert passed in array to Collection of JTS Geometries
              //
              Result r = _convertArray(_group,_precision,true);
              // Result GeometryFactory is created in _convertResultSet
              if ( r==null || r.geoms == null || r.geoms.size()==0 ) {
                  JTS.log("input array has no geometry objects.",THROW_SQL_EXCEPTION);
              }
              return _NodeLineStrings(r.geoms,r.gf);
          } catch (SQLException sqle) {
            JTS.log("ST_NodeLinestrings: failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
          }
          return null;
      }

       /**
        * Takes set of linestring geometries and ensures all topological intersections not at a common
        * vertex are noded (ie a common vertex is inserted into each linestring).
        * @param _resultSet : ResultSet : Cursor collection of Linestring Geometries in SELECT statement 
        * @param _precision : int       : Number of decimal places of precision when comparing ordinates.
        * @return STRUCT    : collection of linear sdo_geometries as MultiLineString.
        * @throws SQLException
        * @author Simon Greener
        * @since February 2013, Original Coding
        * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
        *               http://creativecommons.org/licenses/by-sa/2.5/au/
        */
       public static STRUCT ST_NodeLineStrings(ResultSet _resultSet,
                                               int       _precision)
       throws SQLException
       {
           if ( _resultSet == null ) {
            JTS.log("ST_NodeLinestrings: Supplied Result is null.",THROW_SQL_EXCEPTION);
               return null;
           }
           try {
               Result linesObj = _convertResultSet(_resultSet,_precision,true);
               if ( linesObj==null || linesObj.geoms == null || linesObj.geoms.size()==0 ) {
                   return null;
               }
               return _NodeLineStrings(linesObj.geoms,linesObj.gf);
           } catch (SQLException sqle) {
            JTS.log("ST_NodeLinestrings: Failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
           }
           return null;
       }

     /* =============================================================================================== */

     private static STRUCT _polygonBuilder(Collection      _lines,
                                           GeometryFactory _gf,
                                           OraWriter       _ow) 
     throws SQLException
     {
         STRUCT resultSDOGeom = null;
         // Now try and create polygons from linestrings in lines collection
         //
         int maxDimension = 2;
         Polygonizer polygonizer = new Polygonizer();
         polygonizer.add(_lines); // mlines);
         Collection polys = polygonizer.getPolygons();
         if ( polys != null && polys.size()>0 ) {
             Collection polygons = new ArrayList();
             // Iterate over all formed polygons and create single result
             //
             Iterator it = polys.iterator();
             if ( it != null ) {
                 int i = 0;
                 Object p = null; 
                 while ( it.hasNext() ) 
                 {
                     p = it.next();
                     // System.out.println("Type is " + ((Geometry)p).getGeometryType());
                     if ( p instanceof Polygon ) {
                         polygons.add(p);
                         maxDimension = Math.max(maxDimension,(Tools.getCoordDim((Geometry)p)));
                     }
                 }
                 _ow.setDimension(maxDimension);
                 if ( polygons.size()==0 ) {
                     return null;
                 } else if ( polygons.size() == 1 ) {
                     Geometry poly = (Geometry)polygons.toArray(new Geometry[0])[0];
                     resultSDOGeom = _ow.write(poly,DBConnection.getConnection());
                 } else if ( polygons.size() > 1 ) {
                     GeometryCollection coll = new GeometryCollection(((Geometry[])polygons.toArray(new Geometry[0])),_gf);
                     resultSDOGeom = _ow.write(coll,DBConnection.getConnection());
                 } 
             }
         } else {
             Collection remains = polygonizer.getDangles(); if (remains!=null) JTS.log("Dangles "+remains.size(),WRITE_MESSAGE_TO_LOG);
             remains = polygonizer.getCutEdges();           if (remains!=null) JTS.log("CutEdges "+remains.size(),WRITE_MESSAGE_TO_LOG);
             remains = polygonizer.getInvalidRingLines();   if (remains!=null) JTS.log("InvalidRings "+remains.size(),WRITE_MESSAGE_TO_LOG); 
         }
         return resultSDOGeom;
     }

    /**
    * Builds polygons from input linestrings (alll else are filtered out) in array. 
    * Result, if successful, is Polygon or MultiPolygon.
    * @param _resultSet : ResultSet : Cursor collection of Linestring Geometries in SELECT statement 
    * @param _precision : int       : Number of decimal places of precision when comparing ordinates.
    * @return STRUCT    : Polygon geometry or null as sdo_geometry 
    * @throws SQLException
    * @author Simon Greener
    * @since August 2011, Original Coding
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
    */
    public static STRUCT ST_PolygonBuilder(ResultSet _resultSet,
                                           int       _precision)
    throws SQLException
    {
       if ( _resultSet == null ) {
           JTS.log("ST_PolygonBuilder: Supplied ResultSet is NULL.",THROW_SQL_EXCEPTION);
       }
       STRUCT resultSDOGeom = null;
       try
       {           
           int geometryColumnIndex = firstSdoGeometryColumn(_resultSet.getMetaData());           
           if (geometryColumnIndex == -1) {
               JTS.log("No SDO_Geometry column can be found in ResultSet.",THROW_SQL_EXCEPTION);
           }
           // _convertResultSet assigned gf and conv
           Result r = _convertResultSet(_resultSet,_precision,true);
           if ( r == null || r.geoms == null || r.geoms.size() == 0 ) {
               JTS.log("Failed to extracted SDO_GEOMETRY objects from result set.",THROW_SQL_EXCEPTION);
           }
           OraWriter ow = new OraWriter();
           // Use common method for polygon building
           resultSDOGeom = _polygonBuilder(r.geoms,r.gf,ow);
       } catch (SQLException sqle) {
            JTS.log("ST_PolygonBuilder: failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
       }
       return resultSDOGeom;
    }

    /**
    * Builds polygons from input linestrings (all else are filtered out) in array. 
    * Result, if successful, is Polygon or MultiPolygon.
    * @note             : Input should be noded (see ST_NodeLineStrings).
    * @param _group     : ARRAY : Array of Linestring Geometries eg codesys.T_GEOMETRYSET or mdsys.SDO_GEOMETRY_ARRAY 
    * @param _precision : int   : Number of decimal places of precision when comparing ordinates.
    * @return STRUCT    : Polygon geometry or null as sdo_geometry 
    * @throws SQLException
    * @author Simon Greener
    * @since August 2011, Original Coding
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
    */
     public static STRUCT ST_PolygonBuilder(oracle.sql.ARRAY _group,
                                            int              _precision)
     throws SQLException
     {
         // Check geometry parameters
         //
         if ( _group == null || _group.length() == 0 ) {
             JTS.log("ST_PolygonBuilder: Supplied geometry array is NULL or empty.",THROW_SQL_EXCEPTION);
             return null;
         }
         Object[] nestedObjects = (Object[])_group.getArray();
         STRUCT resultSDOGeom = null;
         try
         {
             // Create necessary factories etc
             PrecisionModel      pm = new PrecisionModel(Tools.getPrecisionScale(_precision)); // FIXED PrecisionModel 
             GeometryFactory     gf = new GeometryFactory(pm, SDO.getSRID((oracle.sql.STRUCT)nestedObjects[0], SDO.SRID_NULL));
             OraReader           or = new OraReader(gf);
             STRUCT          struct = null;
             // Convert passed in array to Collection of JTS Geometries
             Collection       lines = new ArrayList();
             Geometry          geom = null;
             for (int i=0;i<nestedObjects.length;i++) {
                 struct = (oracle.sql.STRUCT)nestedObjects[i];
                 if (struct == null) { continue; }
                 geom = or.read(struct);
                 if (geom == null) { continue; }
                 if (geom instanceof LineString ||
                     geom instanceof LinearRing ||
                     geom instanceof MultiLineString ) {
                     lines.add(geom);
                 } else if ( geom instanceof GeometryCollection) { 
                     // Extract any linestrings in collection.
                     GeometryCollection gCollection = (GeometryCollection)geom;
                     for (int g=0; g<gCollection.getNumGeometries();g++) {
                         geom = gCollection.getGeometryN(g);
                         if (geom instanceof LineString ||
                             geom instanceof LinearRing ||
                             geom instanceof MultiLineString ) {
                             lines.add(geom);
                         }
                     }
                 } else {
                     JTS.log("LineString/MultiLineString or GeometryCollection expected, " + geom.getGeometryType() + " found and skipped.",WRITE_MESSAGE_TO_LOG);
                     continue;
                 }
             }
             if (lines.size()==0) {
                 return null;
             }
             // Use common method for polygon building
             //
             OraWriter ow = new OraWriter();
             resultSDOGeom = _polygonBuilder(lines,gf,ow);
         } catch (Exception e) {
            JTS.log("ST_PolygonBuilder: Failed with " + e.getMessage(),THROW_SQL_EXCEPTION);
         }
         return resultSDOGeom;
     }
     
    /**
     * Builds polygons from input collection of linestrings (all else are filtered out).
     * @param _gCollection : STRUCT : Geometry collection (x004) or MultiLineStrings (x006)
     * @param _precision   : int    : Number of decimal places of precision when comparing ordinates.
     * @return STRUCT      : Polygon or collection of Polygons
     * @throws SQLException
     * @author Simon Greener
     * @since February 2013, Original Coding
     * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     *               http://creativecommons.org/licenses/by-sa/2.5/au/
     */
    public static STRUCT ST_PolygonBuilder(oracle.sql.STRUCT _gCollection,
                                           int               _precision)
    throws SQLException
    {
         // Check geometry parameters
         //
         if ( _gCollection == null ) {
             JTS.log("ST_PolygonBuilder: Supplied SDO_Geometry is NULL.",THROW_SQL_EXCEPTION);
         }
         STRUCT resultSDOGeom = null;
         try
         {
             // Convert SDO_Geometry to Geometry
             //
             PrecisionModel   pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
             GeometryFactory  gf = new GeometryFactory(pm, SDO.getSRID(_gCollection, SDO.SRID_NULL)); 
             OraReader        or = new OraReader(gf);
             Geometry        geo = or.read(_gCollection);
             // Check converted geometries are valid
             //
             if ( geo == null ) {
                 JTS.log("SDO_Geometry conversion to JTS geometry returned NULL.",THROW_SQL_EXCEPTION);
             }
             if ( ! ( geo instanceof GeometryCollection ||
                      geo instanceof MultiLineString ||
                      geo instanceof LineString ||
                      geo instanceof LinearRing ) ) {
                 JTS.log("SDO_Geometry is not a suitable collection or linear ring.",THROW_SQL_EXCEPTION);
             }
             // Extract geometry elements, checking each element, into a Collection of JTS Geometries
             //
             Collection lines = new ArrayList();
             Geometry    geom = null,
                         line = null;
             for (int i=0;i<geo.getNumGeometries();i++) {
                 geom = geo.getGeometryN(i);
                 if (geom == null) { continue; }
                 if (geom instanceof LineString ||
                     geom instanceof LinearRing ) {
                     lines.add(geom);
                 } if (geom instanceof MultiLineString) {
                     for (int j=0;i<geom.getNumGeometries();j++) {
                         line = geo.getGeometryN(j);
                         if (line == null) { continue; }
                         lines.add(line);                         
                     } 
                 } else {
                    JTS.log("ST_PolygonBuilder: LineString expected, " + geom.getGeometryType() + " found and skipped.",WRITE_MESSAGE_TO_LOG);
                    continue;
                 }
             }
             if (lines.isEmpty()) {
                 return null;
             }
             // Use common method for polygon building
             //
             OraWriter ow = new OraWriter();
             resultSDOGeom = _polygonBuilder(lines,gf,ow);
         } catch (SQLException sqle) {
            JTS.log("ST_PolygonBuilder: Failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
         }
         return resultSDOGeom;
     }

    /* ================================= Snapping ================================== */

    private static final int SNAP       = 1;
    private static final int SNAPTO     = 2;
    private static final int SNAPTOSELF = 3;

    /**
     * Snaps both geometries to each other with both being able to move.
     * Returns compound sdo_geometry ie x004
     * 
     * @param _geom1         : STRUCT : first snapping geometry 
     * @param _geom2         : STRUCT : second snapping geometry 
     * @param _snapTolerance : double : Distance tolerance is used to control where snapping is performed.
     *                                  SnapTolerance must be expressed in ordinate units eg m or decimal degrees
     * @param _precision     : number of decimal places of precision of a geometry
     * @return STRUCT        : Result of snap as sdo_geometry
     * @throws SQLException
     * @author Simon Greener
     * @since September 2011, Original Coding
     * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     *               http://creativecommons.org/licenses/by-sa/2.5/au/
     */
     public static STRUCT ST_Snap(STRUCT _geom1,
                                  STRUCT _geom2,
                                  double _snapTolerance,
                                  int    _precision)
      throws SQLException {
        return _snapper(_geom1,_geom2,_snapTolerance,_precision, JTS.SNAP);
    }

    /**
     * Snaps first geometry to second (snap) geometry.
     * @param _geom1         : sdo_geometry : geometry which will be snapped to the second geometry
     * @param _snapGeom      : sdo_geometry : the snapTo geometry 
     * @param _snapTolerance : double : Distance tolerance is used to control where snapping is performed.
     *                                  SnapTolerance must be expressed in ordinate units eg m or decimal degrees
     * @param _precision     : number of decimal places of precision of a geometry
     * @return SDO_GEOMETRY  : Result of snapTo
     * @throws SQLException
     * @author Simon Greener
     * @since September 2011, Original Coding
     */
    public static STRUCT ST_SnapTo(STRUCT _geom1,
                                   STRUCT _snapGeom,
                                   double _snapTolerance,
                                   int    _precision)
     throws SQLException
    {
      return _snapper(_geom1,_snapGeom,_snapTolerance,_precision, JTS.SNAPTO);  
    }

    /**
     * ST_SnapToSelf
     * Snaps input geometry to itself.
     * @param _geom1         : sdo_geometry : geometry which will be snapped to itself
     * @param _snapTolerance : double : Distance tolerance is used to control where snapping is performed.
     *                                  SnapTolerance must be expressed in ordinate units eg m or decimal degrees
     * @param _precision     : number of decimal places of precision of a geometry
     * @return SDO_GEOMETRY  : Result of snapToSelf
     * @throws SQLException
     * @author Simon Greener
     * @since September 2011, Original Coding
     * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     *               http://creativecommons.org/licenses/by-sa/2.5/au/
     **/
    public static STRUCT ST_SnapToSelf(STRUCT _geom1,
                                       double _snapTolerance,
                                       int    _precision)
     throws SQLException
    {
      return _snapper(_geom1,null,_snapTolerance,_precision, JTS.SNAPTOSELF);  
    }
    
    /**
     * Snaps the vertices and segments of a Geometry to another Geometry's vertices. 
     * A snap distance tolerance is used to control where snapping is performed. 
     * Snapping one geometry to another can improve robustness for overlay operations by 
     * eliminating nearly-coincident edges (which cause problems during noding and intersection calculation). 
     * Too much snapping can result in invalid topology beging created, so the number and location of snapped 
     * vertices is decided using heuristics to determine when it is safe to snap. 
     * This can result in some potential snaps being omitted, however.
     * 
     * @param _geom1 : sdo_geometry : first snap geometry
     * @param _geom2 : sdo_geometry : second snap geometry
     * @param _snapTolerance : double : Distance tolerance is used to control where snapping is performed.
     *                                  SnapTolerance must be expressed in ordinate units eg m or decimal degrees
     * @param _precision     : number of decimal places of precision of a geometry
     * @param _snapType      : int : Type of Snapping: snap, snapTo, snapToSelf
     * @return SDO_GEOMETRY  : Result of snapToSelf
     * @throws SQLException
     * @author Simon Greener
     * @since September 2011, Original Coding
     * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     *               http://creativecommons.org/licenses/by-sa/2.5/au/
     **/
    private static STRUCT _snapper(STRUCT _geom1,
                                   STRUCT _geom2,
                                   double _snapTolerance,
                                   int    _precision,
                                   int    _snapType)
     throws SQLException
    { 
        
        String opType = "ST_";
        switch (_snapType) {
            case JTS.SNAPTOSELF : opType = opType += "SnapToSelf"; break;
            case JTS.SNAPTO     : opType = opType += "SnapTo";     break;
            case JTS.SNAP       : opType = opType += "Snap";       break;
        }
        // Check geometry parameters
        //
        if ( ( _geom1 == null ) || 
             ( _geom2 == null && _snapType != JTS.SNAPTOSELF ) ) {
            JTS.log(opType + 
                    (_snapType != JTS.SNAPTOSELF 
                      ? ": One or other of supplied Sdo_Geometries is null."
                      : ": Supplied Sdo_Geometry must not be null."),THROW_SQL_EXCEPTION);
        }

        STRUCT resultSDOGeom = null;
        try
        {
            // Extract SRIDs from SDO_GEOMETRYs and then check them
            //
            int SRID = SDO.getSRID(_geom1, SDO.SRID_NULL);
            if (_snapType != JTS.SNAPTOSELF ) {
                if ( SRID != SDO.getSRID(_geom2, SDO.SRID_NULL) ) {
                    JTS.log("SDO_Geometry SRIDs must be equal.",THROW_SQL_EXCEPTION);
                }
            }

            // Convert Geometries
            //
            PrecisionModel      pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
            GeometryFactory     gf = new GeometryFactory(pm,SRID); 
            OraReader           or = new OraReader(gf);
            Geometry          geo1 = or.read(_geom1);
            Geometry          geo2 = or.read(_geom2);
            
            // Check converted geometries are valid
            //
            if (   geo1 == null   ) { JTS.log("Converted first geometry is NULL.",THROW_SQL_EXCEPTION);    }
            if ( ! geo1.isValid() ) { JTS.log("Converted first geometry is invalid.",THROW_SQL_EXCEPTION); }
            if ( _snapType != JTS.SNAPTOSELF ) {
                if (   geo2 == null   ) { JTS.log("Converted second geometry is NULL.",THROW_SQL_EXCEPTION);     }
                if ( ! geo2.isValid() ) { JTS.log("Converted second geometry is invalid.",THROW_SQL_EXCEPTION ); }
            } 
            
            // Ensure both geometries have same precision 
            Geometry geom1 = null;
            Geometry geom2 = null;
            if (_snapType != JTS.SNAPTOSELF ) {
                geom1 = GeometryPrecisionReducer.reduce(geo1,pm);
                geom2 = GeometryPrecisionReducer.reduce(geo2,pm);
            } else {
                geom1 = geo1;
            }

            // Now do snapping
            //
            Geometry resultGeom = null;
            GeometrySnapper gs = null;
            // Don't need to create a new Snapper when JTS.SNAP as method is static
            if ( _snapType != JTS.SNAP ) {
               gs  = new GeometrySnapper(geom1);
            }
            switch (_snapType) {
              case JTS.SNAPTOSELF : resultGeom = gs.snapToSelf(_snapTolerance,true/*cleanResult*/); break;
              case JTS.SNAPTO     : resultGeom = gs.snapTo(geom2, _snapTolerance);                  break;
              case JTS.SNAP       : resultGeom = gf.createGeometryCollection(
                                                          GeometrySnapper.snap(geom1,
                                                                               geom2
                                                                               ,_snapTolerance)
                                                 ); break;
            }
            OraWriter ow  = new OraWriter(Tools.getCoordDim(resultGeom));
            resultSDOGeom = ow.write(resultGeom,DBConnection.getConnection());
        } catch(SQLException sqle) {
            JTS.log(opType + ": " + sqle.getMessage(),THROW_SQL_EXCEPTION);
        } catch (Exception e) {
            JTS.log(opType + ": " + e.getMessage(),THROW_SQL_EXCEPTION);
        }

        return resultSDOGeom;
    }

    // ---------------------------------------------------- Centroid

    /**
     * Gets centroid (mathematical or interior) of a geometry 
     * @param _geom      : sdo_geometry : Reqiore centroid for this geom.
     * @param _precision : int : number of decimal places of precision
     * @param _interior  : int : if +ve computes a Geometry interior point. 
     *                           An interior point is guaranteed to lie 
     *                           in the interior of the Geometry, if it 
     *                           possible to calculate such a point exactly.
     *                           Otherwise, the point may lie on the boundary
     *                           of the geometry.
     * @return    sdo_geometry : Result of centroid (point or null)
     * @throws SQLException
     * @author    Simon Greener
     * @since     November 2011, Original Coding
     * @copyright Simon Greener, 2011 - 2013
     * @license   Creative Commons Attribution-Share Alike 2.5 Australia License. 
     *            http://creativecommons.org/licenses/by-sa/2.5/au/
     */
    public static STRUCT ST_Centroid(STRUCT _geom,
                                     int    _precision,
                                     int    _interior)
      throws SQLException
    {
        // Check geometry parameters
        //
        if ( _geom == null ) {
            JTS.log("ST_Centroid: Supplied SDO_Geometry is NULL.",THROW_SQL_EXCEPTION);
        }
        STRUCT resultSDOGeom = null;  
        try
        {
            // Convert SDO_Geometry to Geometry
            //
            PrecisionModel   pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
            GeometryFactory  gf = new GeometryFactory(pm, SDO.getSRID(_geom, SDO.SRID_NULL)); 
            OraReader        or = new OraReader(gf);
            Geometry        geo = or.read(_geom);
            // Check converted geometries are valid
            //
            if ( geo == null )     { JTS.log("ST_Centroid: SDO_Geometry conversion to JTS geometry returned NULL.",THROW_SQL_EXCEPTION); return null; }
            if ( ! geo.isValid() ) { JTS.log("ST_Centroid: Converted geometry is invalid.",THROW_SQL_EXCEPTION);                         return null; }
            // Get the centroid and convert it back to SDO_GEOMETRY
            //
            OraWriter ow = new OraWriter(SDO.getDimension(_geom,2));
            if ( Math.abs(_interior) == 0 ) {
                resultSDOGeom = ow.write(geo.getCentroid(),DBConnection.getConnection());
            } else {
                resultSDOGeom = ow.write(geo.getInteriorPoint(),DBConnection.getConnection());
            }
          } catch(SQLException sqle) {
            JTS.log("ST_Centroid: Failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
              return null;
          }
        return resultSDOGeom;
     }

    // ---------------------------------------------------- ConvexHull
    /**
     * Get Convex Hull of a geometry 
     * @param _geom      : STRUCT : geometry for which ConvexHull is required 
     * @param _precision : int : number of decimal places of precision
     * @return STRUCT    : Result of centroid (point or null) as sdo_geometry
     * @throws SQLException
     * @author Simon Greener
     * @since November 2011, Original Coding
     * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. 
     *               http://creativecommons.org/licenses/by-sa/2.5/au/
     */
    public static STRUCT ST_ConvexHull(STRUCT _geom,
                                       int    _precision)
      throws SQLException
    {
        // Check geometry parameters
        //
        if ( _geom == null ) {
            JTS.log("ST_ConvexHull: Supplied SDO_Geometry is NULL.",THROW_SQL_EXCEPTION);
        }
        STRUCT resultSTRUCT = null;
        try
        {
            // Extract SRID from SDO_GEOEMTRY
            //
            int SRID = SDO.getSRID(_geom, SDO.SRID_NULL);
            
            // Convert Geometries
            //
            PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
            GeometryFactory gf = new GeometryFactory(pm,SRID); 
            OraWriter       ow = new OraWriter();
            OraReader       or = new OraReader(gf);
            Geometry       geo = or.read(_geom);
    
            // Check converted geometries are valid
            //
            if ( geo == null ) {
                JTS.log("ST_ConvexHull: SDO_Geometry conversion to JTS geometry returned NULL.",THROW_SQL_EXCEPTION); 
            }
            
            // Now do the calculation
            //
            Geometry cHull = geo.convexHull();
            resultSTRUCT = ow.write(cHull,
                                    DBConnection.getConnection());
            
        } catch(SQLException sqle) {
            JTS.log("ST_ConvexHull: Failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
        }
        return resultSTRUCT;
     }

    private static int DOUGLAS_PEUCKER_SIMPLIFIER     = 0;
    private static int TOPOLOGY_PRESERVING_SIMPLIFIER = 1;
    private static int VISVALINGAM_WHYATT_SIMPLIFIER = 2;

    /**
     * Simplifies a linestring using the Douglas Peucker algorithm.
     *
     * @param _geom : STRUCT : Geometry for which a Douglas Peucker based simplification is to be calculated by SC4O
     * @param _distanceTolerance : double : The maximum distance difference (similar to the one used in the Douglas-Peucker algorithm)
     *                                       _distanceTolerance must be expressed in ordinate units eg m or decimal degrees
     * @param _precision : int    : number of decimal places of precision when comparing ordinates.
     * @return STRUCT            : Simplified geometry as calculated by SC4O as sdo_geometry
     * @Notes: Simplifies a {@link Geometry}using the standard Douglas-Peucker algorithm.
     * Ensures that any polygonal geometries returned are valid.
     * In general D-P does not preserve topology e.g. polygons can be split, collapse to lines or disappear
     * holes can be created or disappear, and lines can cross. However, this implementation attempts always
     * to preserve topology. Switch to not preserve topology is not exposed to PL/SQL.
     * @author Simon Greener
     * @since January 2012, Original Coding
     * @copyright : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     * http://creativecommons.org/licenses/by-sa/2.5/au/
     */
    public static STRUCT ST_DouglasPeuckerSimplifier(STRUCT _geom,
                                                    double _distanceTolerance,
                                                    int    _precision)
      throws SQLException
    {
        return _simplifier(_geom,
                           _distanceTolerance,
                           _precision,
                           DOUGLAS_PEUCKER_SIMPLIFIER);
    }
    
    /**
    * Simplifies linestring/polygon boundary in such as way to to preserve its topology.
    *
    * @param _geom              : sdo_geometry : geometry for which simplification is to be calculated by JTS
    * @param _distanceTolerance : double       : The maximum distance difference (similar to the one used in the Douglas-Peucker algorithm)
    *                                             _distanceTolerance must be expressed in ordinate units eg m or decimal degrees
    * @param _precision         : int          : number of decimal places of precision when comparing ordinates.
    * @return sdo_geometry      : Simplified geometry as calculated by JTS
    * @Notes: The simplification uses a maximum distance difference algorithm
    * similar to the one used in the Douglas-Peucker algorithm.
    * In particular, if the input is an polygon geometry
    * - The result has the same number of shells and holes (rings) as the input, in the same order
    * - The result rings touch at no more than the number of touching point in the input
    *   (although they may touch at fewer points).  
    * (The key implication of this constraint is that the output will be topologically valid if the input was.) 
    * @author Simon Greener
    * @since January 2012, Original Coding
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
    **/
    public static STRUCT ST_TopologyPreservingSimplifier(STRUCT _geom,
                                                         double _distanceTolerance,
                                                         int    _precision)
      throws SQLException
    {
        return _simplifier(_geom,
                           _distanceTolerance,
                           _precision,
                           TOPOLOGY_PRESERVING_SIMPLIFIER);
    }

    /**
     * Simplifies a linestring or polygon boundary using Visvalingam-Whyatt Algorithm
     *
     * @param _geom : STRUCT : Geometry for which a Visvalingam-Whyatt based simplification is to be calculated by SC4O
     * @param _distanceTolerance : double : The distance tolerance (similar to the one used in the Douglas-Peucker algorithm)
     *                                       _distanceTolerance must be expressed in ordinate units eg m or decimal degrees
     * @param _precision : int    : number of decimal places of precision when comparing ordinates.
     * @return STRUCT            : Simplified geometry as calculated by SC4O as sdo_geometry
     * @Notes: Simplifies a {@link Geometry} using the Visvalingam-Whyatt algorithm.
     * The Visvalingam-Whyatt algorithm simplifies geometry by removing vertices while trying to minimize the area changed.
     * Ensures that any polygonal geometries returned are valid. Simple lines are not
     * guaranteed to remain simple after simplification. All geometry types are
     * handled. Empty and point geometries are returned unchanged. Empty geometry
     * components are deleted.
     * <p>
     * The simplification tolerance is specified as a distance. 
     * This is converted to an area tolerance by squaring it.
     * <p>
     * Note that in general this algorithm does not preserve topology - e.g. polygons can be split,
     * collapse to lines or disappear holes can be created or disappear, and lines can cross.
     * @author Simon Greener
     * @since November 2016, Original Coding
     * @copyright : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     * http://creativecommons.org/licenses/by-sa/2.5/au/
     */
    public static STRUCT ST_VisvalingamWhyattSimplifier(STRUCT _geom,
                                                        double _distanceTolerance,
                                                        int    _precision)
      throws SQLException
    {
        return _simplifier(_geom,
                           _distanceTolerance,
                           _precision,
                           VISVALINGAM_WHYATT_SIMPLIFIER);
    }
    
    /**
     * Implements all three simplification algorithms.
     * @param _geom : sdo_geometry : geometry for which with a DP or TP simplification is conducted.
     * @param _distanceTolerance : Number : The maximum distance difference
     *                                       _distanceTolerance must be expressed in ordinate units eg m or decimal degrees
     * @param _precision : int : number of decimal places of precision when comparing ordinates.
     * @param _simplifyType : int : Either DOUGLAS_PEUCKER_SIMPLIFIER, TOPOLOGY_PRESERVING_SIMPLIFIER or VISVALINGAM_WHYATT_SIMPLIFIER
     * @return sdo_geometry : Simplified geometry as calculated by SC4O
     * @Notes: The simplification uses either TopologyPreserving or pure Douglas-Peucker algorithms depending on switch.
     * @author Simon Greener
     * @since January 2012, Original Coding
     * @copyright : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     *              http://creativecommons.org/licenses/by-sa/2.5/au/
     */
    private static STRUCT _simplifier(STRUCT _geom,
                                      double _distanceTolerance,
                                      int    _precision,
                                      int    _simplifyType)
      throws SQLException
    {
         // Check geometry parameters
         //
        if ( _geom == null ) {
            JTS.log("_simplifier (private): Supplied SDO_Geometry is NULL.",THROW_SQL_EXCEPTION);
        }
        if (SDO.isPoint(_geom) ) {
            return _geom;
        }

        STRUCT resultSDOGeom = null;
        try
        {
            // Convert Geometries
            //
            PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
            GeometryFactory gf = new GeometryFactory(pm, SDO.getSRID(_geom, SDO.SRID_NULL)); 
            OraReader       or = new OraReader(gf);
            Geometry        geo = or.read(_geom);
            // Check converted geometry is valid
            //
            if (   geo == null )  { JTS.log("_simplifier (private): SDO_Geometry conversion to JTS geometry returned NULL.",THROW_SQL_EXCEPTION); }
            if ( ! geo.isValid()) { JTS.log("_simplifier (private): Converted geometry is invalid.",THROW_SQL_EXCEPTION); }
            // Now do the calculation
            //
            OraWriter ow = new OraWriter(Tools.getCoordDim(geo));
            if ( _simplifyType == DOUGLAS_PEUCKER_SIMPLIFIER ) {
                resultSDOGeom = ow.write(DouglasPeuckerSimplifier.simplify(geo, _distanceTolerance),DBConnection.getConnection());
            } else if ( _simplifyType == TOPOLOGY_PRESERVING_SIMPLIFIER ) {
                resultSDOGeom = ow.write(TopologyPreservingSimplifier.simplify(geo, _distanceTolerance),DBConnection.getConnection());
            } else /* VISVALINGAM_WHYATT_SIMPLIFIER */ {
                resultSDOGeom = ow.write(VWSimplifier.simplify(geo,_distanceTolerance),DBConnection.getConnection());
            }
        } catch(SQLException sqle) {
            JTS.log("_simplifier (private): Failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
      }
        return resultSDOGeom;
     }      
    
    public static STRUCT ST_MakeEnvelope(double _minx, double _miny,
                                         double _maxx, double _maxy,
                                         int    _srid, int    _precision) 
    throws SQLException
    {
        STRUCT resultSTRUCT = null;
        try
        {
            // Convert Geometries
            //
            PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
            GeometryFactory gf = new GeometryFactory(pm,_srid<=0?SDO.SRID_NULL:_srid);

            // Check validity (ie LL not > UR)
            //
            double minx = Math.min(_minx,_maxx);
            double miny = Math.min(_miny,_maxy);
            double maxx = Math.max(_minx,_maxx);
            double maxy = Math.max(_miny,_maxy);
            
            /* Note strange range based parameters */
            Envelope e = new Envelope(minx,maxx,
                                      miny,maxy);
            
            // Create Polygon
            //
            Geometry geom = gf.toGeometry(e);

            // Now return it
            //
            OraWriter ow = new OraWriter();
            resultSTRUCT = ow.write(geom,DBConnection.getConnection());
              
        } catch(SQLException sqle) {
            JTS.log("ST_MakeEnvelope: Failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
        }
        return resultSTRUCT;
    
    }
    public static STRUCT ST_Envelope(STRUCT _geom,
                                     int    _precision)
    throws SQLException
    {
        // Check geometry parameters
        //
        if ( _geom == null ) {
            JTS.log("ST_Envelope: Supplied Sdo_Geometry is NULL.",THROW_SQL_EXCEPTION);
        }
        STRUCT resultSTRUCT = null;
        try
        {
            // Extract SRID from SDO_GEOEMTRY
            //
            int SRID = SDO.getSRID(_geom, SDO.SRID_NULL);
              
            // Convert Geometries
            //
            PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
            GeometryFactory gf = new GeometryFactory(pm,SRID); 
            OraReader       or = new OraReader(gf);
            Geometry       geo = or.read(_geom);
      
            // Check converted geometries are valid
            //
            if ( geo == null ) {JTS.log("ST_MakeEnvelope: SDO_Geometry conversion to JTS geometry returned NULL.",THROW_SQL_EXCEPTION); }
              
            // Now do the calculation
            //
            OraWriter ow = new OraWriter();
            resultSTRUCT = ow.write(geo.getEnvelope(),DBConnection.getConnection());
              
        } catch(SQLException sqle) {
            JTS.log("ST_MakeEnvelope: Failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
      }
        return resultSTRUCT;
    }

    /**
    * Method for rounding the coordinates of a geometry to a particular precision
    *
    * @param _geom        : sdo_geometry : sdo_geometry object
    * @param _precision   : int          : number of decimal places of precision when rounding ordinates
    * @return SDO_GEOMETRY : all ordinates rounded to required decimal digits of precision
    * @author Simon Greener
    * @since January 2012, Original Coding
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
    */
    public static STRUCT ST_Round(STRUCT _geom,
                                  int    _precision)
    throws SQLException
    {
        // Check geometry parameters
        //
        if ( _geom == null ) {
            JTS.log("ST_Round: Supplied Sdo_Geometry is NULL.",THROW_SQL_EXCEPTION);
           return null;
        }
        STRUCT resultSDOGeom = null;
        try
        {      
            // Convert Geometries
            //
            PrecisionModel  pm = new com.spdba.dbutils.PrecisionModel(Tools.getPrecisionScale(_precision));
            GeometryFactory gf = new GeometryFactory(pm, SDO.getSRID(_geom, SDO.SRID_NULL)); 
            OraReader       or = new OraReader(gf);
            Geometry        geo = or.read(_geom);
            // Check converted geometries are valid
            //
            if ( geo == null ) {
                JTS.log("SDO_Geometry conversion to JTS geometry returned NULL.",THROW_SQL_EXCEPTION); } 
            // Now do the coordinate rounding
            //
            OraWriter  ow = new OraWriter(SDO.getDimension(_geom,2));
            resultSDOGeom = ow.write(GeometryPrecisionReducer.reduce(geo,pm),
                                     DBConnection.getConnection());
        } catch(SQLException sqle) {
            JTS.log("ST_Round: " + sqle.getMessage(),THROW_SQL_EXCEPTION);
        }
        return resultSDOGeom;
    }

    /* =============================== Properties =============================== */
    
    private static final int ISVALID  = 1;
    private static final int ISSIMPLE = 2;
    private static final int COORDDIM = 3;
    private static final int DIMENSION = 4;
    private static final int GEOMETRYTYPE = 5;

    private static final String TRUE = "TRUE";
    private static final String FALSE = "FALSE";
    
    public static String ST_GeometryType(STRUCT _geom)
    throws SQLException
    {
        return _getProperty( _geom, GEOMETRYTYPE );
    }
    
    public static String ST_IsValid(STRUCT _geom)
    throws SQLException
    {
        return _getProperty( _geom, ISVALID );
    }

    public static String ST_IsSimple(STRUCT _geom)
    throws SQLException
    {
        return _getProperty( _geom, ISSIMPLE );
    }

    public static String ST_Dimension(STRUCT _geom) 
    throws SQLException
    {
        return _getProperty(_geom,DIMENSION);
    }
    
    public static String ST_CoordDim(STRUCT _geom)
    throws SQLException
    {
        return _getProperty(_geom,COORDDIM);
    }
    
    private static String _getProperty(STRUCT _geom,
                                       int    _testType)
    throws SQLException
    {
        String callingFunction = "ST_";
        switch (_testType) 
        {
            case  ISVALID     : callingFunction += "isValid";    break;
            case ISSIMPLE     : callingFunction += "isSimple()"; break;
            case COORDDIM     : callingFunction += "getDimension"; break;
            case DIMENSION    : callingFunction += "getDimension"; break;
            case GEOMETRYTYPE : callingFunction += "getGeometryType"; break;
        }
        
        // Check geometry parameters
        //
        if ( _geom == null ) {
            JTS.log(callingFunction + " Supplied SDO_Geometry is NULL.",THROW_SQL_EXCEPTION);
        }
        try
        {      
            // Extract SRID from SDO_GEOEMTRY
            //
            int SRID = SDO.getSRID(_geom, SDO.SRID_NULL);
              
            // Convert Geometries
            //
            PrecisionModel  pm = new PrecisionModel();
            GeometryFactory gf = new GeometryFactory(pm,SRID); 
            OraReader       or = new OraReader(gf);
            Geometry        geo = or.read(_geom);
      
            // Check converted geometries are valid
            //
            if ( geo == null ) {JTS.log("_getProperty (private): SDO_Geometry conversion to JTS geometry returned NULL.",THROW_SQL_EXCEPTION);  }

            // Now do the appropriate operation
            //
            switch (_testType) 
            {
                case  ISVALID     : return geo.isValid()  ? TRUE : FALSE;
                case ISSIMPLE     : return geo.isSimple() ? TRUE : FALSE;
                case COORDDIM     : return String.valueOf(SDO.getDimension(_geom,2));
                case DIMENSION    : return String.valueOf(geo.getDimension());
                case GEOMETRYTYPE : return geo.getGeometryType();
                default : return "";
            }
    
        } catch(SQLException sqle) {
            String testType = "";
            switch (_testType) 
            {
                case  ISVALID     : testType = "ISVALID"; break;
                case ISSIMPLE     : testType = "ISVALID"; break;
                case COORDDIM     : testType = "ISVALID"; break;
                case DIMENSION    : testType = "ISVALID"; break;
                case GEOMETRYTYPE : testType = "ISVALID"; break;
                default : testType = "_none_"; break;
            }
            JTS.log(callingFunction + " Failed " + testType + " with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
        }
        return null;
    }
    
    public static String ST_IsValidReason(STRUCT _geom,
                                          int    _precision)
    {
        // Check geometry parameters
        //
        if ( _geom == null ) {
           return "NULL:SDO";
        }
        try
        {      
            // Extract SRID from SDO_GEOEMTRY
            //
            int SRID = SDO.getSRID(_geom, SDO.SRID_NULL); 
            // Convert Geometry
            //
            PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale(_precision)); // FIXED PrecisionModel
            GeometryFactory gf = new GeometryFactory(pm,SRID); 
            OraReader       or = new OraReader(gf);
            Geometry       geo = or.read(_geom); 
            // Check converted geometries are valid
            //
            if ( geo == null ) { 
              return "NULL:JTS";
            } else {
               IsValidOp valid = new IsValidOp(geo);
               TopologyValidationError tve = valid.getValidationError();
               return (tve==null?"VALID":tve.toString());
            }
        } catch(Exception sqle) {
          return "ST_IsValidReason: Failed with " + sqle.getMessage();
        }
    }
    
    /* ============= Delaunay/Voronoi etc methods =============== */
    
    private static STRUCT _createTriangles(Collection      _geoms,
                                           double          _tolerance,
                                           GeometryFactory _gf) 
    throws SQLException 
    {
        STRUCT retSTRUCT = null;
        try {
            /* Now do the triangulation */
            DelaunayTriangulationBuilder builder = new DelaunayTriangulationBuilder();
            builder.setTolerance(_tolerance);
            GeometryCollection gcIn = null;
            gcIn = new GeometryCollection(((Geometry[])_geoms.toArray(new Geometry[0])),_gf);
            builder.setSites(gcIn);
            Geometry gOut = builder.getTriangles(_gf);
            if ( gOut != null && gOut.getNumGeometries()>0 ) {
                OraWriter ow = new OraWriter(Tools.getCoordDim(gcIn));
                retSTRUCT    = ow.write(gOut,
                                        DBConnection.getConnection());
            }
        } catch (Exception e) {
            JTS.log("(_createTriangles) " + e.getMessage(),THROW_SQL_EXCEPTION);
        }
        return retSTRUCT;
    }
    
    /**
     * Takes an array of geometries and creates a Delaunay Trianglulation from collections of points 
     * and extract the resulting triangulation edges or triangles as geometries. 
     * @param _group     : ARRAY : Array of Geometries eg codesys.T_GEOMETRYSET or mdsys.SDO_GEOMETRY_ARRAY
     * @param _precision : int   : Number of decimal places of precision when comparing ordinates.
     * @return STRUCT    : Collection of polygon (triangle) sdo_geometries 
     * @throws SQLException
     * @author Simon Greener
     * @since March 2012, Original Coding
     * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     *               http://creativecommons.org/licenses/by-sa/2.5/au/
     */
    public static STRUCT ST_DelaunayTriangles(oracle.sql.ARRAY _group,
                                              double           _tolerance,
                                              int              _precision)
    throws SQLException
    {
         // Check geometry parameters
         //
        if ( _group == null ) {
            JTS.log("Supplied array is NULL.",THROW_SQL_EXCEPTION); 
        }
         STRUCT resultSDOGeom = null;
         try
         {
             // Convert passed in array to Collection of JTS Geometries
             //
             Result r = _convertArray(_group,_precision,THROW_SQL_EXCEPTION);
             if ( r==null || r.geoms == null || r.geoms.size() == 0 ) {
                 return null;
             }
             /* Now do the triangulation */
             resultSDOGeom = _createTriangles(r.geoms,_tolerance,r.gf);
         } catch (SQLException sqle) {
            JTS.log("ST_DelaunayTriangles: Failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
         }
         return resultSDOGeom;
     }
    
      /**
       * Takes an array of geometries and creates a Delaunay Trianglulation from collections of points 
       * and extract the resulting triangulation edges or triangles as geometries. 
       * @param _resultSet : ResultSet : A collection of Geometries in SELECT statement 
       * @param _precision : int       : Number of decimal places of precision when comparing ordinates.
       * @return STRUCT    : collection of polygon sdo_geometries 
       * @throws SQLException
       * @author Simon Greener
       * @since March 2012, Original Coding
       * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
       *               http://creativecommons.org/licenses/by-sa/2.5/au/
       */
      public static STRUCT ST_DelaunayTriangles(ResultSet _resultSet,
                                                double    _tolerance,
                                                int       _precision)
      throws SQLException
      {
          if ( _resultSet == null ) {
              JTS.log("Supplied ResultSet is null.",THROW_SQL_EXCEPTION);
          }
          STRUCT resultSDOGeom = null;
          try 
          {
              Result r = _convertResultSet(_resultSet,_precision,THROW_SQL_EXCEPTION);
              if ( r == null || r.geoms == null || r.geoms.size() == 0 ) {
                  return null;
              }
              /* Now do the triangulation */
              resultSDOGeom = _createTriangles(r.geoms,_tolerance,r.gf);
          } catch (SQLException sqle) {
            JTS.log("ST_DelaunayTriangles: Failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
          }
          return resultSDOGeom;
      }

    /**
     * Takes a single geometry (eg multipoint) and creates a Delaunay Trianglulation from 
     * its points, extracting the resulting triangulation edges or triangles as geometries. 
     * @param _geom      : SDO_GEOMETRY : A single geometry 
     * @param _precision : int          : Number of decimal places of precision when comparing ordinates.
     * @return STRUCT    : Collection of polygon (triangle) sdo_geometries 
     * @throws SQLException
     * @author Simon Greener
     * @since March 2012, Original Coding
     * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     *               http://creativecommons.org/licenses/by-sa/2.5/au/
     */
    public static STRUCT ST_DelaunayTriangles(STRUCT _geom,
                                              double _tolerance,
                                              int    _precision)
    throws SQLException
    {
        // Check geometry parameters
        //
        if ( _geom == null ) {
            JTS.log("Supplied SDO_Geometry is NULL.",THROW_SQL_EXCEPTION);
           return null;
        }
        
        if ( SDO.getGType(_geom) ==  1) {
            JTS.log("Cannot build a Delaunay Triangulation from a single point geometry.",THROW_SQL_EXCEPTION);
        }

        STRUCT resultSDOGeom = null;
        try
        {            
            // Convert Geometry
            //
            PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
            GeometryFactory gf = new GeometryFactory(pm, SDO.getSRID(_geom, SDO.SRID_NULL)); 
            OraReader       or = new OraReader(gf);
            Geometry       geo = or.read(_geom);
      
            // Check converted geometries are valid
            //
            if ( geo == null ) {
                JTS.log("SDO_Geometry conversion to JTS geometry returned NULL.",THROW_SQL_EXCEPTION);  
            }

            /* Now do the triangulation */
            DelaunayTriangulationBuilder builder = new DelaunayTriangulationBuilder();
            builder.setTolerance(_tolerance);
            builder.setSites(geo);
            Geometry gOut = builder.getTriangles(gf);
            if ( gOut != null && gOut.getNumGeometries()>0 ) {
                OraWriter       ow = new OraWriter(Tools.getCoordDim(gOut));
                resultSDOGeom = ow.write(gOut,
                                         DBConnection.getConnection());
            }

        } catch(SQLException sqle) {
            JTS.log("ST_DelaunayTriangles: " + sqle.getMessage(),THROW_SQL_EXCEPTION);
        }
        return resultSDOGeom;
    }

    /* ================= VORONOI ================== */
    
    private static STRUCT _createVoronoi(Collection      _geoms,
                                         Geometry        _clipGeom,
                                         double          _tolerance,
                                         GeometryFactory _gf) 
    throws SQLException 
    {
        STRUCT retSTRUCT = null;
        try {
            VertexTaggedGeometryDataMapper mapper = new VertexTaggedGeometryDataMapper();
            mapper.loadSourceGeometries(_geoms);
            VoronoiDiagramBuilder builder = new VoronoiDiagramBuilder();
            builder.setSites(mapper.getCoordinates());
            builder.setTolerance(_tolerance);
            if (_clipGeom != null && _clipGeom.isValid()) {
                builder.setClipEnvelope(_clipGeom.getEnvelopeInternal());
            } else {
                GeometryCollection gcIn = null;
                gcIn = new GeometryCollection(((Geometry[])_geoms.toArray(new Geometry[0])),_gf);
                Envelope e = gcIn.getEnvelopeInternal();  // SGG
                e.expandBy(gcIn.getEnvelopeInternal().getWidth()/0.25,
                           gcIn.getEnvelopeInternal().getHeight()/0.25);  // SGG
                builder.setClipEnvelope(e);  // SGG                
            }
            Geometry gOut = builder.getDiagram(_gf);
            if ( gOut != null && gOut.getNumGeometries()>0 ) {
                OraWriter ow = new OraWriter(Tools.getCoordDim(gOut));
                retSTRUCT    = ow.write(gOut,DBConnection.getConnection());
            }            
        } catch (Exception e) {
            JTS.log("(_createVoronoi) " + e.getMessage(),THROW_SQL_EXCEPTION);
        }
        return retSTRUCT;
    }
    
    /**
     * Takes an array of geometries and creates a Voronoi Diagram from the geometries' points 
     * and extract the resulting triangulation edges or triangles as geometries. 
     * @param _group     : ARRAY  : Array of Geometries eg codesys.T_GEOMETRYSET or mdsys.SDO_GEOMETRY_ARRAY
     * @param _tolerance : double : Snapping tolerance (coordinate sysstem units only) which will be used 
     *                              to improved the robustness of the computation.
     *                              _Tolerance must be expressed in ordinate units eg m or decimal degrees
     * @param _precision : int    : Number of decimal places of precision when comparing ordinates.
     * @return STRUCT    : Collection of polygon (triangle) sdo_geometries 
     * @throws SQLException
     * @author Simon Greener
     * @since March 2012, Original Coding
     * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     *               http://creativecommons.org/licenses/by-sa/2.5/au/
     */
    public static STRUCT ST_Voronoi(ARRAY  _group,
                                    STRUCT _clipGeom,
                                    double _tolerance,
                                    int    _precision)
    throws SQLException
    {
         // Check geometry parameters
         //
        if ( _group == null ) {
            JTS.log("ST_Voronoi: Supplied array is NULL.",THROW_SQL_EXCEPTION);
        }
         STRUCT resultSDOGeom = null;
         try
         {    
             // Convert passed in array to Collection of JTS Geometries
             // (This sets geometryFactory etc)
             //
             Result r = _convertArray(_group,_precision,THROW_SQL_EXCEPTION);
             if (r.geoms == null || r.geoms.size()==0) {
                 return null;
             }

             OraReader     or = new OraReader(r.gf);
             Geometry clipGeo = null;
             if ( _clipGeom != null ) {
                 clipGeo = or.read(_clipGeom);
                 if ( clipGeo == null ) {
                    JTS.log("Envelope (clip) sdo_geometry conversion to JTS geometry returned NULL.",THROW_SQL_EXCEPTION);
                    return null;
                 }
             }            
             /* Now do the triangulation */
             resultSDOGeom = _createVoronoi(r.geoms,clipGeo,_tolerance,r.gf);
         
         } catch (SQLException sqle) {
            JTS.log("ST_Voronoi: Failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
         }
         return resultSDOGeom;
     }
    
      /**
       * Takes an array of geometries and creates a Voronoi Diagram from the geometries' points 
       * and extract the resulting triangulation edges or triangles as geometries. 
       * @param _resultSet : ResultSet : A collection of Geometries in SELECT statement 
       * @param _tolerance : double : Snapping tolerance (coordinate sysstem units only) which will be used 
       *                              to improved the robustness of the computation.
       *                              _Tolerance must be expressed in ordinate units eg m or decimal degrees
       * @param _precision : int       : Number of decimal places of precision when comparing ordinates.
       * @return STRUCT    : Collection of polygon sdo_geometries 
       * @throws SQLException
       * @author Simon Greener
       * @since March 2012, Original Coding
       * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
       *               http://creativecommons.org/licenses/by-sa/2.5/au/
       */
      public static STRUCT ST_Voronoi(ResultSet _resultSet,
                                      STRUCT    _clipGeom,
                                      double    _tolerance,
                                      int       _precision)
      throws SQLException
      {
          if ( _resultSet == null ) {
            JTS.log("ST_Voronoi: Supplied ResultSet is null.",THROW_SQL_EXCEPTION);
          }
          STRUCT resultSDOGeom = null;
          try 
          {
              Result r = _convertResultSet(_resultSet,_precision,THROW_SQL_EXCEPTION);
              if ( r.geoms == null || r.geoms.size()==0 ) {
                  return null;
              }
              OraReader     or = new OraReader(r.gf);
              Geometry clipGeo = null;
              if ( _clipGeom != null ) {
                  clipGeo = or.read(_clipGeom);
                  if ( clipGeo == null ) {
                    JTS.log("Envelope (clip) sdo_geometry conversion to JTS geometry returned NULL.",THROW_SQL_EXCEPTION);
                  }
              }
              /* Now do the triangulation */
              resultSDOGeom = _createVoronoi(r.geoms,clipGeo,_tolerance,r.gf);

          } catch (SQLException sqle) {
            JTS.log("ST_Voronoi: Failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
          }
          return resultSDOGeom;
      }

    /**
     * Takes a single geometry (eg multipoint) and creates a Delaunay Trianglulation from 
     * its points, extracting the resulting triangulation edges or triangles as geometries. 
     * @param _geom      : SDO_GEOMETRY : A single geometry 
     * @param _tolerance : double : Snapping tolerance (coordinate sysstem units only) which will be used 
     *                              to improved the robustness of the computation.
     *                              _Tolerance must be expressed in ordinate units eg m or decimal degrees
     * @param _precision : int          : Number of decimal places of precision when comparing ordinates.
     * @return STRUCT    : Collection of polygon (triangle) sdo_geometries 
     * @throws SQLException
     * @author Simon Greener
     * @since March 2012, Original Coding
     * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     *               http://creativecommons.org/licenses/by-sa/2.5/au/
     */
    public static STRUCT ST_Voronoi(STRUCT _geom,
                                    STRUCT _clipGeom,
                                    double _tolerance,
                                    int    _precision)
    throws SQLException
    {
        // Check geometry parameters
        //
        if ( _geom == null ) {
            JTS.log("ST_Voronoi: Supplied SDO_Geometry is NULL.",THROW_SQL_EXCEPTION);
        }

        if ( SDO.getGType(_geom) ==  1) {
            JTS.log("ST_Voronoi: Cannot build a Voronoi Diagram a single point geometry.",THROW_SQL_EXCEPTION);
        }

        STRUCT resultSDOGeom = null;
        try
        { 
            /* Convert Geometry */ 
            PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
            GeometryFactory gf = new GeometryFactory(pm, SDO.getSRID(_geom, SDO.SRID_NULL));
            OraReader       or = new OraReader(gf);
            Geometry       geo = or.read(_geom);
            Geometry   clipGeo = geo.getEnvelope();
            if ( _clipGeom != null ) {
               clipGeo = or.read(_clipGeom);
            } 
            /* Check converted geometries are valid */ 
            if ( geo == null ) {
                JTS.log("sdo_geometry conversion to JTS geometry returned NULL.",THROW_SQL_EXCEPTION);
            }
            if ( clipGeo == null ) {
                JTS.log("Envelope (clip) SDO_Geometry conversion to JTS geometry returned NULL.",THROW_SQL_EXCEPTION);
            }
            VertexTaggedGeometryDataMapper mapper = new VertexTaggedGeometryDataMapper();
            mapper.loadSourceGeometries(geo);
            VoronoiDiagramBuilder builder = new VoronoiDiagramBuilder();
            builder.setSites(mapper.getCoordinates());
            builder.setTolerance(_tolerance);
            if (clipGeo != null) {
                builder.setClipEnvelope(clipGeo.getEnvelopeInternal());
            } else {
                Envelope e = geo.getEnvelopeInternal();  // SGG
                e.expandBy(geo.getEnvelopeInternal().getWidth()/0.25,
                           geo.getEnvelopeInternal().getHeight()/0.25);  // SGG
                builder.setClipEnvelope(e);  // SGG                
            }
            Geometry gOut = builder.getDiagram(gf);
            if ( gOut != null && gOut.getNumGeometries()>0 ) {
                OraWriter       ow = new OraWriter(Tools.getCoordDim(gOut));
                resultSDOGeom = ow.write(gOut,DBConnection.getConnection());
            }
        } catch(SQLException sqle) {
            JTS.log("ST_Voronoi: Failed with " + sqle.getMessage(),THROW_SQL_EXCEPTION);
        }
        return resultSDOGeom;
    }

    /* =================================== END ================================== */

    /**
     * @param _point         : STRUCT : Point for which Z ordinate's value is to be computed
     * @param _geom1         : STRUCT : First corner geometry 3D point
     * @param _geom2         : STRUCT : Second corner geometry 3D point
     * @param _geom3         : STRUCT : Third corner geometry 3D point 
     * @return double        : Result of Interpolation 
     * @throws SQLException
     * @author Simon Greener
     * @since March 2012, Original Coding
     */
    public static double ST_InterpolateZ(STRUCT _point,
                                         STRUCT _geom1,
                                         STRUCT _geom2,
                                         STRUCT _geom3)
     throws SQLException
    {
        // Check geometry parameters
        //
        if ( _point == null || _geom1 == null || _geom2 == null || _geom3 == null ) {
            JTS.log("ST_InterpolateZ: One or other of supplied Sdo_Geometries is NULL.",THROW_SQL_EXCEPTION);
        }
        double interpolatedZ = Double.MAX_VALUE;
        try
        {
            // Extract and Check SRIDs from SDO_GEOMETYs
            //
            int  SRID  = SDO.getSRID(_point, SDO.SRID_NULL);
            if ( SRID != SDO.getSRID(_geom1, SDO.SRID_NULL) || 
                 SRID != SDO.getSRID(_geom2, SDO.SRID_NULL) || 
                 SRID != SDO.getSRID(_geom3, SDO.SRID_NULL) ) {
                JTS.log("SRIDs of Sdo_Geometries must be equal.",THROW_SQL_EXCEPTION);
            }
            // Convert Geometries
            //
            PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale());
            GeometryFactory gf = new GeometryFactory(pm,SRID); 
            OraReader       or = new OraReader(gf);
            or.setDimension(SDO.getDimension(_point,2));
            Geometry     point = or.read(_point);
            or.setDimension(SDO.getDimension(_geom1,3));
            Geometry      geo1 = or.read(_geom1);
            or.setDimension(SDO.getDimension(_geom2,3));
            Geometry      geo2 = or.read(_geom2);
            or.setDimension(SDO.getDimension(_geom3,3));
            Geometry      geo3 = or.read(_geom3);
            
            // Check converted geometries are valid
            //
            if ( point == null )    {JTS.log("Converted point geometry is NULL.",THROW_SQL_EXCEPTION); }
            if ( ! point.isValid()) {JTS.log("Converted point geometry is invalid.",THROW_SQL_EXCEPTION); }
            if ( geo1 == null )     {JTS.log("Converted first geometry is NULL.",THROW_SQL_EXCEPTION); }
            if ( ! geo1.isValid() ) {JTS.log("Converted first geometry is invalid.",THROW_SQL_EXCEPTION);  }
            if ( geo2 == null )     {JTS.log("Converted second geometry is NULL.",THROW_SQL_EXCEPTION);  }
            if ( ! geo2.isValid() ) {JTS.log("Converted second geometry is invalid.",THROW_SQL_EXCEPTION); }
            if ( geo3 == null )     {JTS.log("Converted third geometry is NULL.",THROW_SQL_EXCEPTION); }
            if ( ! geo3.isValid() ) {JTS.log("Converted third geometry is invalid.",THROW_SQL_EXCEPTION); }
            
            // Now check geometry type
            //
            if ( ( point instanceof Point ) &&
                 ( geo1  instanceof Point ) && 
                 ( geo2  instanceof Point ) &&
                 ( geo3  instanceof Point ) ) 
            {
                // Are all three corner vertices 3D
                //
                if ( ( geo1.getCoordinate().z == Double.NaN ) ||
                     ( geo1.getCoordinate().z == Double.NaN ) ||
                     ( geo1.getCoordinate().z == Double.NaN ) ) {
                    JTS.log("The three facet geometries must have a Z value.",THROW_SQL_EXCEPTION); 
                }
                interpolatedZ = Triangle.interpolateZ(point.getCoordinate(),
                                                      geo1.getCoordinate(),
                                                      geo2.getCoordinate(),
                                                      geo3.getCoordinate()); 
            } else {
                JTS.log("All three facet geometries should be points.",THROW_SQL_EXCEPTION);
            }
        } catch(SQLException sqle) {
            JTS.log("ST_InterpolateZ: " + sqle.getMessage(),THROW_SQL_EXCEPTION);
        }
        return interpolatedZ;
    }

     /**
      * @param _point         : STRUCT : Point for which Z ordinate's value is to be computed
      * @param _facet         : STRUCT : 3 vertex triangular polygon
      * @return double        : Result of Interpolation 
      * @throws SQLException
      * @author Simon Greener
      * @since March 2012, Original Coding
      */
     public static STRUCT ST_InterpolateZ(STRUCT _point,
                                          STRUCT _facet)
      throws SQLException
     {
         // Check geometry parameters
         //
         if ( _point == null || _facet == null ) {
            JTS.log("ST_InterpolateZ: One or other of supplied SDO_Geometries is NULL.",THROW_SQL_EXCEPTION);
         }
         double interpolatedZ = Double.MAX_VALUE;
         STRUCT retSTRUCT = null;
         try
         { 
             // Extract and Check SRIDs from SDO_GEOMETYs
             //
             int SRID = SDO.getSRID(_point, SDO.SRID_NULL);
             if (  SRID != SDO.getSRID(_facet, SDO.SRID_NULL) ) {
                JTS.log("SRIDs of SDO_Geometries must be equal",THROW_SQL_EXCEPTION);
             }
             
             // Convert Geometries
             //
             PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale());
             GeometryFactory gf = new GeometryFactory(pm,SRID); 
             OraReader       or = new OraReader(gf);
             Geometry     point = or.read(_point);
             Geometry     facet = or.read(_facet);
             
             // Check converted geometries are valid
             //
             if ( point == null )                  { JTS.log("Converted point geometry is NULL.",THROW_SQL_EXCEPTION); }
             if ( ! point.isValid())               { JTS.log("Converted point geometry is invalid.",THROW_SQL_EXCEPTION); }
             if ( ! (point instanceof Point || 
                     point instanceof MultiPoint)) {JTS.log("Supplied point geometry (" + point.getGeometryType() + "), can ony be Point or MultiPoint.",THROW_SQL_EXCEPTION);  }
             
             MultiPoint mpoint = null;
             if ( point instanceof Point ) {
                 mpoint = new MultiPoint(new Point[] {(Point)point},gf);
             } else {
                 mpoint = (MultiPoint)point;
             }
             if ( facet == null )                 {JTS.log("Converted facet polygon is NULL.",THROW_SQL_EXCEPTION);    }
             if ( ! facet.isValid() )             {JTS.log("Converted facet polygon is invalid.",THROW_SQL_EXCEPTION); }
             if ( ! ( facet instanceof Polygon) ) {JTS.log("Facet geometry should be a polygon.",THROW_SQL_EXCEPTION); }
             if ( facet.getNumPoints() != 4 )     {JTS.log("Facet polygon must have 3 corner points (" + facet.getNumPoints() + ").",THROW_SQL_EXCEPTION); }

             Coordinate[] facetCoords = facet.getCoordinates();
             if ( ( facetCoords[0].z == Double.NaN ) ||
                  ( facetCoords[1].z == Double.NaN ) ||
                  ( facetCoords[2].z == Double.NaN ) ) {
                JTS.log("The three facet corners must have a Z value.",THROW_SQL_EXCEPTION); 
                 return null;
             }
             // Now compute Z value of all points inside facet
             //
             Coordinate[] coords = null;
             coords = mpoint.getCoordinates();
             for (int c=0;c<coords.length;c++) {
                 interpolatedZ = Triangle.interpolateZ(coords[c],
                                                       facetCoords[0],
                                                       facetCoords[1],
                                                       facetCoords[2]);
                 coords[c].setZ(interpolatedZ); // Update coord of mpoint
             } 
             OraWriter ow = new OraWriter(); 
             if ( coords.length == 1 ) { // Point
                retSTRUCT = ow.write(gf.createPoint(coords[0]),DBConnection.getConnection());
             } else {
                retSTRUCT = ow.write(gf.createMultiPointFromCoords(coords),DBConnection.getConnection());
             }
         } catch(SQLException sqle) {
            JTS.log("ST_InterpolateZ: " + sqle.getMessage(),THROW_SQL_EXCEPTION);
         }
         return retSTRUCT;
     }
     
     /* ================== JTS based import/export functions ================ */

    public static CLOB ST_AsGML(STRUCT _geom) 
    throws SQLException
    {
        // Check geometry parameters
        //
        if ( _geom == null ) {
            JTS.log("ST_AsGML: Supplied SDO_Geometry is NULL.",THROW_SQL_EXCEPTION);
        }
        try
        {
            // Convert Geometries
            //
            int           SRID = SDO.getSRID(_geom, SDO.SRID_NULL);
            PrecisionModel  pm = new PrecisionModel();
            GeometryFactory gf = new GeometryFactory(pm,SRID);
            OraReader       or = new OraReader(gf);
            Geometry        geo = or.read(_geom);
        
            // Check converted geometries are valid
            //
            if ( geo == null ) {
                JTS.log("ST_AsGML: SDO_Geometry conversion to JTS geometry returned NULL.",THROW_SQL_EXCEPTION);
            }
              
            // Now convert to GML 2
            //
            GMLWriter gml = new GMLWriter();
            if (SRID != SDO.SRID_NULL) {
                gml.setSrsName("EPSG:" + SRID);
            }
            return SQLConversionTools.string2Clob(gml.write(geo));
            
        } catch(Exception e) {
            JTS.log("ST_AsGML: Failed with " + e.getMessage(),THROW_SQL_EXCEPTION);
        }
        return null;
    }

    public static STRUCT ST_GeomFromGML(String _gml)
    throws SQLException 
    {
        if (Strings.isEmpty(_gml) ) {
            JTS.log("ST_GeomFromGML: Supplied GML is NULL.",THROW_SQL_EXCEPTION);
           return null;
        }
        // TODO: GML does not handle the SRID
        STRUCT resultSDOGeom = null;        
        try {
            // Convert Geometries
            //
            PrecisionModel  pm = new PrecisionModel(PrecisionModel.FIXED);
            GeometryFactory gf = new GeometryFactory(pm, SDO.SRID_NULL);
            GMLReader       gr = new GMLReader();
            try 
            {
                Geometry  geom = gr.read(_gml,gf);
                if (geom != null) {
                    OraWriter  ow = new OraWriter(Tools.getCoordDim(geom));
                    resultSDOGeom = ow.write(geom,DBConnection.getConnection());
                }
            } catch (NullPointerException npe) {
                npe.printStackTrace();
                throw new Exception("ST_GeomFromGMLNullPointerException caught: " + npe.toString());
            }
        } catch (IOException e) {
            JTS.log("ST_GeomFromGMLIOException caught: " + e.toString(),THROW_SQL_EXCEPTION);
        } catch (SAXException e) {
            JTS.log("ST_GeomFromGMLSAXException caught: " + e.toString(),THROW_SQL_EXCEPTION);
        } catch (ParserConfigurationException e) {
            JTS.log("ST_GeomFromGMLParserConfigurationException caught: " + e.toString(),THROW_SQL_EXCEPTION);
        } catch (Exception e) {
            JTS.log("ST_GeomFromGML: Failed with " + e.getMessage(),THROW_SQL_EXCEPTION);
        }
        return resultSDOGeom;
    }

    /**
     * @param _group       : List of geometries to be collected
     * @param _returnMulti : If it is true always returns MultiGeometries. 
     * @return The collected geometry
     * @throws SQLException
     */
    public static STRUCT ST_Collect(oracle.sql.ARRAY _group,
                                    int              _returnMulti)
    throws SQLException
    {
        // Check geometry parameters
        //
        boolean returnMulti = _returnMulti == 0 ? false : true;
        if ( _group == null || _group.length()==0) {
            JTS.log("ST_Collect: Empty array of SDO_Geometries.",THROW_SQL_EXCEPTION);
        }
        
        // Convert passed in array to Collection of JTS Geometries
        // _convertArray skips null geometries
        //
        Result geomList = _convertArray(_group,0,/*_expandCollection*/true);
        
        if ( geomList==null || geomList.geoms == null || geomList.geoms.size()==0 ) {
            JTS.log("ST_Collect: Failed to extracted SDO_Geometry objects from Array.",THROW_SQL_EXCEPTION);
        }
        
        if ( geomList.coordinateDimension == mixedCoordinateDimensions) {
            JTS.log("ST_Collect: Collection contains a mix of Coordinate Dimensions.",THROW_SQL_EXCEPTION);
        }
        if ( geomList.SRID == mixedSRIDs ) {
            JTS.log("ST_Collect: Collection contains a mix of SRIDs.",THROW_SQL_EXCEPTION);
        }

        Class          geomClass = null;
        boolean  isHeterogeneous = false;
        List       geomListValid = new ArrayList();
        try {
            Iterator   geomIterator  = geomList.geoms.iterator();
            while (geomIterator.hasNext()) {
                Geometry geom = (Geometry)geomIterator.next();
                if (geom!=null && (!geom.isEmpty())) {
                    Class partClass = geom.getClass();
                    if (geomClass == null)      { geomClass = partClass; }
                    if (partClass != geomClass) { isHeterogeneous = true; }
                    geomListValid.add(geom);
                }
            }
        } catch (Exception e) {
            JTS.log("ST_Collect: Geometry Collection error",THROW_SQL_EXCEPTION);
        }

        /* Now construct an appropriate geometry to return */
        if (geomClass == null && geomListValid.size()==0) {
            JTS.log("ST_Collect: No geometries to process.",THROW_SQL_EXCEPTION);
        }

        OraWriter ow = new OraWriter();
        Geometry res = null;
        if (geomListValid.size()==1) {
            res = (Geometry)geomListValid.get(0);
            if (res != null) {
                res.setSRID(geomList.SRID);
                return ow.write(res,DBConnection.getConnection());
            }
        } else if (isHeterogeneous || !returnMulti) {
            try {
                res = geomList.gf.createGeometryCollection(GeometryFactory.toGeometryArray(geomListValid));
            } catch (RuntimeException e) {
                // Catch the runtime JTS Exceptions
                JTS.log("ST_Collect: " + e.toString(),THROW_SQL_EXCEPTION);
            }
            if (res != null) {
                res.setSRID(geomList.SRID);
                return ow.write(res,
                                DBConnection.getConnection());
            }
        } else {
            // at this point we know the collection is not hetereogenous.
            // Determine the type of the result from the first Geometry in the list
            //
            res = (Geometry)geomListValid.get(0);
            try {
                if (res instanceof Polygon) {
                    res = geomList.gf.createMultiPolygon(GeometryFactory.toPolygonArray(geomListValid));
                } else if (res instanceof LineString) {
                    res = geomList.gf.createMultiLineString(GeometryFactory.toLineStringArray(geomListValid));
                } else if (res instanceof Point) {
                    res = geomList.gf.createMultiPoint(GeometryFactory.toPointArray(geomListValid));
                }
                if (res != null) {
                    res.setSRID(geomList.SRID);
                    return ow.write(res,
                                    DBConnection.getConnection());
                }
            } catch (RuntimeException e) {
                JTS.log("ST_Collect: Failed with " + e.getMessage(),THROW_SQL_EXCEPTION);
            }
        }
        return null;        
    }

    /* ============== Editors ================ */
    
    public static STRUCT ST_DeletePoint(STRUCT _geom, int _vertexIndex)
    throws SQLException
    {
        // Check geometry parameters
        //
        if ( _geom == null ) {
           throw new SQLException("Supplied Sdo_Geometry is NULL.");
        }
        if (_vertexIndex == 0 || _vertexIndex < -1) { 
            throw new SQLException("The index (" + _vertexIndex+ ") must be -1 (last coord) or greater or equal than 1" );
        }
        if ( SDO.isPoint(_geom) ) {
            throw new SQLException("Deleting vertex from an input point sdo_geometry is not supported." );
        }
        STRUCT resultSDOGeom = null;        
        // Convert Geometries
        //
        PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale());
        GeometryFactory gf = new GeometryFactory(pm, SDO.getSRID(_geom, SDO.SRID_NULL)); 
        OraReader       or = new OraReader(gf);
        Geometry       geo = or.read(_geom);
        
        // Check converted geometries are valid
        //
        if ( geo == null ) { throw new SQLException("SDO_Geometry conversion to JTS geometry returned NULL."); }
        
        int numPoints = geo.getNumPoints();
        if (_vertexIndex > numPoints) { throw new SQLException("Point index (" + _vertexIndex + ") out of range (1.." + numPoints + ")"); }

        // Index = -1 means change point at the end of the linestring
        //
        int pointIndex = _vertexIndex;
        if (pointIndex == -1) {
            pointIndex = numPoints - 1;
        } else {
            pointIndex--;   // Internally 0 based, externally 1 based
        }
        // Make the edit
        //
        GeometryEditor editor = new GeometryEditor(geo.getFactory());
        RemovePoint operation = new RemovePoint(pointIndex);
        Geometry      resGeom = editor.edit(geo,(RemovePoint)operation);
        // Convert back to STRUCT
        //
        OraWriter ow = new OraWriter(Tools.getCoordDim(resGeom));
        resultSDOGeom = ow.write(resGeom,
                                 DBConnection.getConnection());
        return resultSDOGeom;
    }

     public static STRUCT ST_UpdatePoint(STRUCT _geom, 
                                         STRUCT _vertex,
                                         int    _vertexIndex)
     throws SQLException
     {
          if ( _geom == null ) {
             return _vertex;
          }
          if (_vertex == null ) {
              return _geom;
          }
          if (_vertexIndex == 0 || _vertexIndex < -1) { 
              throw new SQLException("The index (" + _vertexIndex+ ") must be -1 (last coord) or greater or equal than 1" );
          } 
          if (SDO.getSRID(_geom, 2) != SDO.getSRID(_vertex, 2)) {
              throw new SQLException("SDO_Geometries have different SRIDs.");
          }
          if (SDO.getDimension(_geom, 2) != SDO.getDimension(_vertex,2)) {
              throw new SQLException("SDO_Geometries have different coordinate dimensions."); 
          }
    
          STRUCT resultSDOGeom = null;
          try {
              // Convert Geometries
              //
              PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale());
              GeometryFactory gf = new GeometryFactory(pm, SDO.getSRID(_geom, SDO.SRID_NULL)); 
              OraReader       or = new OraReader(gf);
              Geometry      geom = or.read(_geom); // The target geometry
              Geometry     point = or.read(_vertex); // The Point Geometry
              // Check converted geometries are valid
              //
              if ( geom  == null ) { throw new SQLException("SDO_Geometry conversion to JTS geometry returned NULL."); }
              if ( point == null ) { throw new SQLException("SDO_Geometry Point conversion to JTS geometry returned NULL."); }
              if (! (point instanceof Point) ) { throw new SQLException("Provided point is not a Point"); }
              
              Coordinate pointCoor = point.getCoordinate();
              if (pointCoor == null) { return _geom; }
              // Check index
              //
              int numPoints = geom.getNumPoints();
              if (_vertexIndex > numPoints) {
                  throw new SQLException("Point index (" + _vertexIndex + ") out of range (1.." + numPoints + ")");
              }

              // Index = -1 means change point at the end of the linestring
              //
              int pointIndex = _vertexIndex;
              if (pointIndex == -1) {
                  pointIndex = numPoints - 1;
              } else {
                  pointIndex--;  // 0 base not 1
              }
              ChangePointFilter filter = null;
              filter = new ChangePointFilter(pointIndex, pointCoor);
              geom.apply(filter);
              if (filter.hasRingNotClosed()) { 
                  throw new SQLException("LinearRings must be closed linestring"); 
              }
              // Convert back to STRUCT
              //
              OraWriter  ow = new OraWriter(Tools.getCoordDim(geom));
              resultSDOGeom = ow.write(geom,
                                       DBConnection.getConnection());
          } catch (Exception e) {
              JTS.log(e.getMessage(),THROW_SQL_EXCEPTION); 
          }
          return resultSDOGeom;
      }

    private static Geometry _updateVertex(GeometryFactory _gf,
                                          Geometry        _geom,
                                          Point           _fromPoint,
                                          Point           _toPoint ) 
    {
        if ( _geom == null || _fromPoint ==null || _toPoint == null ) {
            return _geom;
        }
        // update every vertex in geom with point
        Coordinate fromPointCoor = _fromPoint.getCoordinate();
        Coordinate toPointCoor   = _toPoint.getCoordinate();
        boolean modified = false;
        CoordinateSequence coordSeq = _gf.getCoordinateSequenceFactory().create(_geom.getCoordinates());
        for (int i=0; i<coordSeq.size(); i++) {
            if (coordSeq.getCoordinate(i).equals(fromPointCoor) ) {
                coordSeq.setOrdinate(i, CoordinateSequence.X, toPointCoor.getX());
                coordSeq.setOrdinate(i, CoordinateSequence.Y, toPointCoor.getY());
                coordSeq.setOrdinate(i, CoordinateSequence.Z, toPointCoor.getZ());
                coordSeq.setOrdinate(i, CoordinateSequence.M, toPointCoor.getM());
                modified = true;
            }
        }
        Geometry geom = null;
        if ( modified ) {
            if ( _geom instanceof LineString ) {
              geom = _gf.createLineString(coordSeq);
            } else if (_geom instanceof LinearRing) {
              geom = _gf.createLinearRing(coordSeq);
            } else if (_geom instanceof MultiPoint) {
              geom = _gf.createMultiPoint(coordSeq);
            } else if (_geom instanceof Polygon) {
              geom = _gf.createPolygon(coordSeq);
            } 
            return geom == null ? _geom : geom;
        }
        return _geom;
    }
    
    public static STRUCT ST_UpdatePoint(STRUCT _geom, 
                                         STRUCT _fromVertex,
                                         STRUCT _toVertex) 
    throws SQLException
    {
         if ( _geom == null ) {
            return _toVertex;
         }
         if (_fromVertex==null || _toVertex==null ) {
             return _geom;
         }
         if (  SDO.getSRID(_geom, 2) != SDO.getSRID(_fromVertex, 2) 
            || SDO.getSRID(_geom, 2) != SDO.getSRID(_toVertex, 2) 
         ) {
             throw new SQLException("SDO_Geometries have different SRIDs.");
         }
         if (SDO.getDimension(_geom, 2) != SDO.getDimension(_fromVertex,2)
             ||
             SDO.getDimension(_geom, 2) != SDO.getDimension(_toVertex,2)
         ) {
             throw new SQLException("SDO_Geometries have different coordinate dimensions."); 
         }
    
         STRUCT resultSDOGeom = null;
         try {
             // Convert Geometries
             //
             PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale());
             GeometryFactory gf = new GeometryFactory(pm, SDO.getSRID(_geom, SDO.SRID_NULL)); 
             OraReader       or = new OraReader(gf);
             Geometry      geom = or.read(_geom);       // The target geometry
             Geometry fromPoint = or.read(_fromVertex); // From Point Geometry
             Geometry   toPoint = or.read(_toVertex);   // To Point Geometry

             if (     geom  == null ) { throw new SQLException("SDO_Geometry conversion to JTS geometry returned NULL."); }
             if ( fromPoint == null ) { throw new SQLException("SDO_Geometry fromVertex conversion to JTS geometry returned NULL."); }
             if (   toPoint == null ) { throw new SQLException("SDO_Geometry toVertex conversion to JTS geometry returned NULL."); }
             if (! (fromPoint instanceof Point) ) { throw new SQLException("Provided fromVertex is not a Point"); }
             if (! (  toPoint instanceof Point) ) { throw new SQLException("Provided toVertex is not a Point"); }
             
             Coordinate fromPointCoor = fromPoint.getCoordinate();
             if (fromPointCoor == null) { return _geom; }
             Coordinate toPointCoor = toPoint.getCoordinate();
             if (toPointCoor == null) { return _geom; }
             // Check index
             //
             int numPoints = geom.getNumPoints();
             if (numPoints == 0) {
                 throw new SQLException("Geometry must have at least one point");
             }
             
             if ( geom instanceof Point ) {
                 // update a single point means to return itself.
                 if ( geom.equals(fromPoint) ) {
                     return _toVertex;
                 }
                 return _geom;
             }
             
             // Convert all geometry types
             Geometry returnGeom = null;
             if ( geom instanceof LineString ||
                  geom instanceof LinearRing ||
                  geom instanceof MultiPoint || 
                  geom instanceof Polygon ) {
                 returnGeom = _updateVertex(gf,geom,(Point)fromPoint,(Point)toPoint);
             } else {
                 // All are MultiTypes
                 Collection geometryList = new ArrayList(geom.getNumGeometries());
                 Geometry updatedGeom = null;
                 for (int i=0; i<geom.getNumGeometries();i++) {
                     updatedGeom = _updateVertex(gf,geom.getGeometryN(i),(Point)fromPoint,(Point)toPoint);
                     geometryList.add(updatedGeom);
                 }
                 // Create necessary object
                 returnGeom = gf.buildGeometry(geometryList);
             }
             // Convert back to STRUCT
             //
             OraWriter  ow = new OraWriter(Tools.getCoordDim(geom));
             resultSDOGeom = ow.write(geom,
                                      DBConnection.getConnection());
         } catch (Exception e) {
             JTS.log(e.getMessage(),THROW_SQL_EXCEPTION); 
         }
         return resultSDOGeom;
     }

     public static STRUCT ST_InsertPoint(STRUCT _geom, STRUCT _vertex, int _vertexIndex)
     throws SQLException 
     {
         return _ST_InsertPoint(_geom, _vertex, _vertexIndex, false);
     }

     private static STRUCT _ST_InsertPoint(STRUCT  _geom, 
                                            STRUCT  _vertex,
                                            int     _vertexIndex, 
                                            boolean _atTheEnd)
     throws SQLException 
     {
         if ( _geom  == null ) { return _vertex; }
         if (_vertex == null ) { return _geom;   }
         if (_vertexIndex == 0 || _vertexIndex < -1) { 
             throw new SQLException("The index (" + _vertexIndex+ ") must be -1 (last coord) or greater or equal than 1" );
         }
         if (SDO.getSRID(_geom, SDO.SRID_NULL) != SDO.getSRID(_vertex, SDO.SRID_NULL)) {
             throw new SQLException("SDO_Geometries have different SRIDs.");
         }
         if (SDO.getDimension(_geom, 2) != SDO.getDimension(_vertex,2)) {
             throw new SQLException("SDO_Geometries have different coordinate dimensions."); 
         }
         STRUCT resultSDOGeom = null;
         try {
             // Convert Geometries
             //
             PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale());
             GeometryFactory gf = new GeometryFactory(pm, SDO.getSRID(_geom, SDO.SRID_NULL)); 
             OraReader       or = new OraReader(gf);
             Geometry      geom = or.read(_geom);    // The target geometry
             Geometry     point = or.read(_vertex); // The Point Geometry
             // Check converted geometries are valid
             //
             if ( geom  == null ) { throw new SQLException("SDO_Geometry conversion to JTS geometry returned NULL."); }
             if ( point == null ) { throw new SQLException("SDO_Geometry Point conversion to JTS geometry returned NULL."); }
             if (! (point instanceof Point) ) { throw new SQLException("Provided point is not a Point"); }

             // Check index
             //
             boolean afterIndex = false;
             int numPoints = geom.getNumPoints();
             int pointIndex = _vertexIndex==-1?-1:(_vertexIndex-1);            
             // With index=-1 PostGIS located the point at the end of the linestring
             if (_atTheEnd || (pointIndex == -1)) {
                 pointIndex = numPoints;
             }
             if (pointIndex > numPoints) {
                 throw new SQLException("Point index (" + _vertexIndex + ") out of range (1.." + numPoints + ")");
             } else if (pointIndex == numPoints) {
                 afterIndex = true;
                 pointIndex--;
             }
             // Make the edit
             //
             GeometryEditor editor = new GeometryEditor(geom.getFactory());
             AddPoint    operation = new AddPoint(pointIndex, point.getCoordinate(), afterIndex);
             Geometry        eGeom = editor.edit(geom, operation);
             // Convert back to STRUCT
             //
             OraWriter  ow = new OraWriter(Tools.getCoordDim(eGeom));
             resultSDOGeom = ow.write(eGeom,
                                      DBConnection.getConnection());
         } catch (Exception e) {
             JTS.log(e.getMessage(),THROW_SQL_EXCEPTION);
         }
         return resultSDOGeom;
     }
}
