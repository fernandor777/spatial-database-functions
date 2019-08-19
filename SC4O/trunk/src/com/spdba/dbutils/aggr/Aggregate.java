package com.spdba.dbutils.aggr;

import com.spdba.dbutils.JTS;
import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.sql.DBConnection;
import com.spdba.dbutils.tools.Strings;
import com.spdba.dbutils.tools.Tools;

import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryCollection;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.MultiPolygon;
import org.locationtech.jts.geom.Polygon;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.geom.util.PolygonExtracter;
import org.locationtech.jts.io.ora.OraReader;
import org.locationtech.jts.io.ora.OraWriter;
import org.locationtech.jts.operation.union.CascadedPolygonUnion;
import org.locationtech.jts.operation.union.UnaryUnionOp;
import org.locationtech.jts.precision.GeometryPrecisionReducer;
import org.locationtech.jts.simplify.TopologyPreservingSimplifier;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleTypes;

import oracle.sql.STRUCT;

public class Aggregate {

    private static void log(String _message,
                            boolean _throw) 
    throws SQLException
    {
        if ( _throw ) {
            throw new SQLException(_message);
        } else {
            System.err.println(_message);            
        }
                           
    }    

    /* ================= ARRAY eg T_GEOMETRYSET based union ===============
     */
    public static STRUCT aggrUnionPolygons(oracle.sql.ARRAY _group,
                                           int              _precision,
                                           double           _distanceTolerance) 
    throws SQLException
    {
        return aggrUnion(_group,_precision,true,_distanceTolerance);
    }
    
    public static STRUCT aggrUnionMixed(oracle.sql.ARRAY _group,
                                        int              _precision,
                                        double           _distanceTolerance)
    throws SQLException
    {
        return aggrUnion(_group,_precision,false,_distanceTolerance);
    }

    public static STRUCT aggrUnion(oracle.sql.ARRAY _group,
                                   int              _precision,
                                   boolean          _polygons,
                                   double           _distanceTolerance) 
    throws SQLException
    {
      STRUCT resultSTRUCT = null;
      try
      {
          // Check geometry parameters
          //
          if ( _group == null )
              return null;

          if ( _group.length() == 0 )
              return null;

          Object[] nestedObjects = (Object[])_group.getArray();
          
          int SRID = SDO.getSRID((STRUCT)nestedObjects[0],0);

          // Create necessary factories etc
          //
          PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
          GeometryFactory gf = new GeometryFactory(pm,SRID); // PrecisionModel will be FIXED
          OraReader       or = new OraReader(gf);
          
          // Convert passed in array to Collection of JTS Geometries
          //
          STRUCT    struct = null;
          Collection geoms = new ArrayList(_group.length());
          Geometry    poly = null;
          for (int i=0;i<_group.length();i++) {
              struct = (oracle.sql.STRUCT)nestedObjects[i];
              if ( _polygons ) {
                  poly = or.read(struct);
                  if (poly instanceof Polygon || poly instanceof MultiPolygon ) {
                     geoms.add(poly);
                  }
              } else {
                  geoms.add(or.read(struct));
              }
          }
          if (geoms.size()==0)
              return null;
          
          // Use common method to do union
          //
          OraWriter ow = new OraWriter();
          resultSTRUCT = aggrUnion(geoms,gf,pm,ow,_polygons,_distanceTolerance);

      } catch (SQLException sqle) {
          System.err.println(sqle.getMessage());
      }
      return resultSTRUCT;
    }

    /* ================= ResultSet based union ===============
     */
    public static STRUCT aggrUnionPolygons(ResultSet _resultSet,
                                           int       _precision,
                                           double    _distanceTolerance) 
    throws SQLException
    {
        return aggrUnion(_resultSet,_precision,true,_distanceTolerance);
    }
    
    public static STRUCT aggrUnionMixed(ResultSet _resultSet,
                                        int       _precision,
                                        double    _distanceTolerance) 
    throws SQLException
    {
        return aggrUnion(_resultSet,_precision,false,_distanceTolerance);
    }

    /* ================= TableName based union ===============
     */
      public static STRUCT aggrUnionPolygons(String _tableName,
                                             String _columnName,
                                             int    _precision,
                                             double _distanceTolerance) 
      throws SQLException
      {
          if (Strings.isEmpty(_tableName) ) {
            Aggregate.log("No table/view name passed to ST_aggrUnionPolygons.",false); 
              return null;
          }
          if (Strings.isEmpty(_columnName) ) {
            Aggregate.log("No sdo_geometry column name passed to ST_aggrUnionPolygons.",false); 
              return null;
          }
          
          // Ensure global connection is a valid connection
          // Precision set
          // SRID exposed
          //
          OracleConnection conn = DBConnection.getConnection();
          PreparedStatement pStatement = conn.prepareStatement(
                                  "SELECT " + _columnName + 
                                   " FROM " + _tableName + " A " + 
                                  " WHERE a." + _columnName + " IS NOT NULL AND a." + _columnName + ".get_gtype() in (3,7)");
          OracleResultSet ors = (OracleResultSet)pStatement.executeQuery();
          return aggrUnion(ors,_precision,true,_distanceTolerance);
      }
      
      public static STRUCT aggrUnionMixed(String _tableName,
                                          String _columnName,
                                          int    _precision,
                                          double _distanceTolerance) 
      throws SQLException
      {
          if (Strings.isEmpty(_tableName) ) {
            Aggregate.log("No table/view name passed to ST_aggrUnionMixed.",false);
              return null;
          }
          if (Strings.isEmpty(_columnName) ) {
            Aggregate.log("No sdo_geometry column name passed to ST_aggrUnionMixed.",false);
              return null;
          }
          
          // Ensure global connection is a valid connection
          // Precision set
          // SRID exosed
          //
          OracleConnection conn = DBConnection.getConnection();
          PreparedStatement pStatement = conn.prepareStatement("SELECT " + _columnName + " FROM " + _tableName + " A WHERE a." + _columnName + " IS NOT NULL");
          OracleResultSet ors = (OracleResultSet)pStatement.executeQuery();
          return aggrUnion(ors,_precision,false,_distanceTolerance);
      }

      public static STRUCT aggrUnion(ResultSet _resultSet,
                                     int       _precision,
                                     boolean   _polygons,
                                     double    _distanceTolerance) 
      throws SQLException
      {
          if ( _resultSet == null ) {
            Aggregate.log("No ResultSet passed to aggrUnion.",false);
              return null;
          }
          STRUCT jGeoStruct = null;
          try
          {
              int geometryColumnIndex = JTS.firstSdoGeometryColumn(_resultSet.getMetaData());
              if (geometryColumnIndex == -1) {
                Aggregate.log("No SDO_GEOMETRY column can be found in data to be exported.",false);
                  return null; 
              }
      
              // Create necessary factories
              //
              OracleConnection conn = (OracleConnection)_resultSet.getStatement().getConnection(); // (OracleConnection)DriverManager.getConnection("jdbc:default:connection:");
              PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
              GeometryFactory gf = null;
              OraReader       or = null;
              
              Collection geoms           = new ArrayList();
              _resultSet.setFetchDirection(ResultSet.FETCH_FORWARD);
              _resultSet.setFetchSize(150);
              ResultSetMetaData metaData = _resultSet.getMetaData();
              while(_resultSet.next()) 
              {
                  if( metaData.getColumnType(geometryColumnIndex) != OracleTypes.STRUCT || 
                     !metaData.getColumnTypeName(geometryColumnIndex).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY))
                      continue;
                  jGeoStruct = (STRUCT)_resultSet.getObject(geometryColumnIndex);
                  if (jGeoStruct == null) {
                      continue;
                  }
                  // We create the geometryFactory when we have the first valid SDO_Geometry so we can get its SRID
                  //
                  if ( gf == null ) {
                    int SRID = SDO.getSRID(jGeoStruct,0);
                    // Create GeometryFactory with FIXED PrecisionModel with SRID
                    gf = new GeometryFactory(pm,SRID);
                    or = new OraReader(gf);
                  }
                  Geometry geom = or.read(jGeoStruct);
                  if(geom == null) {
                      continue;
                  }
                  // Add converted geometry to collection
                  //
                  geoms.add(geom);
              }
              if (geoms.size()==0) {
                  return null;
              }
              // Use common method do do union
              //
              OraWriter ow = new OraWriter();
              jGeoStruct   = aggrUnion(geoms,gf,pm,ow,_polygons,_distanceTolerance);
              
          } catch (SQLException sqle) {
              System.err.println(sqle.getMessage());
          }
          return jGeoStruct;
      }
      
      /** =============== Common Union method for ARRAY and ResultSet based methods ===============
       **/
    private static STRUCT aggrUnion(Collection      _geoms,
                                    GeometryFactory _gf,
                                    PrecisionModel  _pm,
                                    OraWriter       _ow,
                                    boolean         _polygons,
                                    double          _distanceTolerance) 
    throws SQLException
    {
        STRUCT resultSTRUCT = null;
        // Now execute union 
        //
        Geometry geo = null;
        if ( _polygons ) {
            geo = CascadedPolygonUnion.union(_geoms);
        } else {
            geo = UnaryUnionOp.union(_geoms,_gf);
        }
        
        // Do optional simplification and/or convert to STRUCT
        //
        if ( geo != null ) {
            if ( _polygons ) {
                if ( geo instanceof GeometryCollection ) {
                    List polyList = PolygonExtracter.getPolygons(geo);
                    if ( polyList.size()>0 ) {
                        Polygon[] polys = (Polygon[])polyList.toArray(new Polygon[0]);
                        geo = new MultiPolygon(polys,_gf);
                    } else { 
                        return resultSTRUCT; // null
                    }
                }
                if ( _distanceTolerance > (double)0.0 ) {
                   geo = GeometryPrecisionReducer.reduce(TopologyPreservingSimplifier.simplify(geo, _distanceTolerance),_pm);
                   resultSTRUCT = _ow.write(geo,
                                            DBConnection.getConnection());
                } else {
                   geo = GeometryPrecisionReducer.reduce(geo,_pm);
                   resultSTRUCT = _ow.write(geo,
                                            DBConnection.getConnection());
                }
            } else {
                geo = GeometryPrecisionReducer.reduce(geo,_pm);
                resultSTRUCT = _ow.write(geo,
                                         DBConnection.getConnection());
            }
        }
        return resultSTRUCT;
    }
    
}
