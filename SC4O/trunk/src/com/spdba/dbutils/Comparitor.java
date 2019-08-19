package com.spdba.dbutils;


import com.spdba.dbutils.tools.Strings;
import com.spdba.dbutils.tools.Tools;
import com.spdba.dbutils.spatial.SDO;

import org.locationtech.jts.algorithm.match.AreaSimilarityMeasure;
import org.locationtech.jts.algorithm.match.HausdorffSimilarityMeasure;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.IntersectionMatrix;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.io.ora.OraReader;
import org.locationtech.jts.operation.relate.RelateOp;

import java.sql.SQLException;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.StringTokenizer;

import oracle.sql.STRUCT;

import org.locationtech.jts.precision.GeometryPrecisionReducer;


public class Comparitor {

    private static final int HAUSDORFF = 1;
    private static final int AREA      = 2;
    
    /**
     * ST_HausdorffSimilarityMeasure
     * Measures the degree of similarity between two sdo_geometrys
     * using SC4O's Hausdorff distance metric.
     * The measure is normalized to lie in the range [0, 1].
     * Higher measures indicate a great degree of similarity.
     * <p>
     * The measure is computed by computing the Hausdorff distance
     * between the input geometries, and then normalizing
     * this by dividing it by the diagonal distance across
     * the envelope of the combined geometries.
     *
     * @param _geom1 : STRUCT : first geometry subject to comparison
     * @param _geom2 : STRUCT : second geometry subject to comparison
     * @param _precision : int    : number of decimal places of precision
     * @return double     : The Hausdorff similarity measure value as number
     * @history Simon Greener, September 2011, Original Coding
     * @copyright : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     * http://creativecommons.org/licenses/by-sa/2.5/au/
     */
  public static double ST_HausdorffSimilarityMeasure(STRUCT _geom1, 
                                                     STRUCT _geom2, 
                                                     int    _precision)
  throws SQLException
  {
        Tools.setPrecisionScale(_precision);
        return _SimilarityMeasure(_geom1, _geom2, _precision, Comparitor.HAUSDORFF);
  }

    /**
    * ST_AreaSimilarityMeasure
    * Measures the degree of similarity between two {@link Geometry}s
    * using the area of intersection between the geometries.
    * The measure is normalized to lie in the range [0, 1].
    * Higher measures indicate a great degree of similarity.
    * <p>
    * NOTE: Currently experimental and incomplete.
    *
    * @param  _geom1     : STRUCT : First geometry subject to comparison
    * @param  _geom2     : STRUCT : Second geometry subject to comparison
    * @param  _precision : int    : Number of decimal places of precision
    * @return  double    : The area similarity measure as a number.
    * @history Simon Greener, September 2011, Original Coding
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
    **/
   public static double ST_AreaSimilarityMeasure(STRUCT _geom1, 
                                                 STRUCT _geom2, 
                                                 int    _precision)
  throws SQLException
  {
        Tools.setPrecisionScale(_precision);
        return _SimilarityMeasure(_geom1, _geom2, _precision, Comparitor.AREA);
  }
  
  /**
   * Compare
   * @param _geom1 : sdo_geometry : first geometry subject to comparitor action
   * @param _geom2 : sdo_geometry : second geometry subject to comparitor action
   * @param _operationType : int : See Comparitor.HAUSENDORFF or Comparitor.AREA 
   * @return double : Result of comparitor
   * @throws SQLException
   * @history Simon Greener, September 2011, Original Coding
   */
  private static double _SimilarityMeasure(STRUCT _geom1,
                                           STRUCT _geom2,
                                           int    _precision,
                                           int    _operationType)
   throws SQLException
  {
      // Check geometry parameters
      //
      if ( _geom1 == null || _geom2 == null ) {
          throw new SQLException("One or other of supplied Sdo_Geometries is NULL.");
      }
      double result = -1;
      try
      {
          // Check SRIDs
          //
          int SRID = SDO.getSRID(_geom1,0);
          if ( SRID != SDO.getSRID(_geom2,0) ) {
              throw new SQLException("SRIDs of Sdo_Geometries must be equal");
          }
          
          // Convert Geometries
          //
          GeometryFactory gf = new GeometryFactory(new PrecisionModel(Tools.getPrecisionScale(_precision)),SRID); // PrecisionModel will be FIXED
          OraReader       or = new OraReader(gf);
          Geometry      geo1 = or.read(_geom1);
          Geometry      geo2 = or.read(_geom2);
          
          // Check converted geometries are valid
          //
          if ( geo1 == null )     { throw new SQLException("Converted first geometry is NULL."); }
          if ( ! geo1.isValid() ) { throw new SQLException("Converted first geometry is invalid."); }
          if ( geo2 == null )     { throw new SQLException("Converted second geometry is NULL."); }
          if ( ! geo2.isValid() ) { throw new SQLException("Converted second geometry is invalid." ); }
          
          // Now do the operation
          //
          try {
              switch (_operationType) {
              case Comparitor.HAUSDORFF :
                  HausdorffSimilarityMeasure hsm = new HausdorffSimilarityMeasure();
                  result = hsm.measure(geo1, geo2);
                  break;
              case Comparitor.AREA :
                  // Both geometries must polygons
                  //
                  if ( ! ( geo1.getGeometryType().equalsIgnoreCase("Polygon") || 
                           geo1.getGeometryType().equalsIgnoreCase("MultiPolygon") ) ) {
                     throw new SQLException("First geometry is not a polygon.");
                  }
                  if ( ! ( geo2.getGeometryType().equalsIgnoreCase("Polygon") || 
                           geo2.getGeometryType().equalsIgnoreCase("MultiPolygon") ) ) {
                     throw new SQLException("Second geometry is not a polygon.");
                  }
                  AreaSimilarityMeasure asm = new AreaSimilarityMeasure();
                  result = asm.measure(geo1, geo2); 
                  break;
              }
          } catch (Exception e) {
              return -1;
          }
      } catch(SQLException sqle) {
          System.err.println(sqle.getMessage());
      }
      return result;
  }

    /**
     * ST_Relate
     *
     * Implements a license free version of sdo_geom.RELATE.
     * @note Supports SC4O named topological relationships and not Oracle specific keywords like OVERLAPBDYDISJOINT
     * @param _geom1     : STRUCT : First geometry
     * @param _mask      : String : Mask containing DETERMINE, ANYINTERACT or a list of comma separated topological relationships,
     *                              or DE-9IM Matrix string.
     * @param _geom2     : STRUCT : Second geometry
     * @param _precision : int    : Number of decimal places of precision of a geometry
     * @return String    : Result of comparison.
     * @throws SQLException
     * @history Simon Greener, November 2011, Original coding.
     * @copyright : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
     * http://creativecommons.org/licenses/by-sa/2.5/au/
     */
    public static String ST_Relate(STRUCT _geom1,
                                   String _mask,
                                   STRUCT _geom2,
                                   int    _precision)
    throws SQLException 
    {
        // Check parameters
        //
        if ( _geom1 == null || _geom2 == null ) {
            throw new SQLException("One or other of supplied Sdo_Geometries is NULL.");
        }
        String mask = _mask;
        if (Strings.isEmpty(_mask) ) {
          // make same as determine
          // 
          mask = "DETERMINE"; 
        }
        String returnString = "";
        try
        {  
          // Extract SRIDs from SDO_GEOMETRYs make sure same
          //
          int SRID = SDO.getSRID(_geom1, SDO.SRID_NULL);
          if ( SRID != SDO.getSRID(_geom2, SDO.SRID_NULL) ) {
              throw new SQLException("SRIDs of Sdo_Geometries must be equal");
          }
          
          // Convert Geometries
          //
          // Check if have CircularArcs
          //
          if (SDO.hasArc(_geom1) ) {throw new SQLException("First geometry has circular arcs that JTS does not support.");}
          if (SDO.hasArc(_geom2) ) {throw new SQLException("Second geometry has circular arcs that JTS does not support.");}

          PrecisionModel  pm = new PrecisionModel(Tools.getPrecisionScale(_precision));
          GeometryFactory gf = new GeometryFactory(pm,SRID); 
          OraReader       or = new OraReader(gf);
          Geometry      geo1 = or.read(_geom1);
          Geometry      geo2 = or.read(_geom2);
          
          // Check converted geometries are valid
          //
          if (   geo1 == null  ) { throw new SQLException("Converted first geometry is NULL."); }
          if ( ! geo1.isValid()) { throw new SQLException("Converted first geometry is invalid."); }
          if (   geo2 == null  ) { throw new SQLException("Converted second geometry is NULL."); }
          if ( ! geo2.isValid()) { throw new SQLException("Converted second geometry is invalid." ); }

          // Reduce each geometry to common precision
          geo1 = GeometryPrecisionReducer.reduce(geo1,pm);
          geo2 = GeometryPrecisionReducer.reduce(geo2,pm);
          
          /* The pattern is a 9-character string, with symbols drawn from the following set:
           *  <UL>
           *    <LI> 0 (dimension 0)
           *    <LI> 1 (dimension 1)
           *    <LI> 2 (dimension 2)
           *    <LI> T ( matches 0, 1 or 2)
           *    <LI> F ( matches FALSE)
           *    <LI> * ( matches any value)
           *  </UL>
          */
          if ( _mask.length() == 9 && 
               (_mask.contains("0") ||
                _mask.contains("1") ||
                _mask.contains("2") ||
                _mask.contains("F") ||
                _mask.contains("*") ) ) {
              boolean equalsMask = geo1.relate(geo2,_mask);
              return equalsMask ? "TRUE" : "FALSE";
          }

          // Now get relationship mask
          IntersectionMatrix im = RelateOp.relate(geo1,geo2);
          // Process relationship mask
          int dimGeo1 = geo1.getDimension();
          int dimGeo2 = geo2.getDimension();
          if ( im.isEquals(dimGeo1,dimGeo2)) {
              returnString = "EQUAL";
          } else if ( im == null ) {
              returnString = "UNKNOWN";
          } else {
              ArrayList al = new ArrayList();
              if ( im.isContains())                al.add("CONTAINS");
              if ( im.isCoveredBy())               al.add("COVEREDBY");
              if ( im.isCovers())                  al.add("COVERS");
              if ( im.isCrosses( dimGeo1,dimGeo2)) al.add("CROSS"); 
              if ( im.isDisjoint())                al.add("DISJOINT"); 
              if ( im.isIntersects())              al.add("INTERSECTS");
              if ( im.isOverlaps(dimGeo1,dimGeo2)) al.add("OVERLAP");
              if ( im.isTouches( dimGeo1,dimGeo2)) al.add("TOUCH");
              if ( im.isWithin())                  al.add("WITHIN");
              // Now compare to user mask
              //
              if ( mask.equalsIgnoreCase("ANYINTERACT") ) {
                  // If the ANYINTERACT keyword is passed in mask, the
                  // function returns TRUE if two geometries not disjoint.
                  //
                  return al.size()==0
                         ?"UNKNOWN"
                         :(al.contains("DISJOINT")?"FALSE":"TRUE");
              } else if ( mask.equalsIgnoreCase("DETERMINE") ) {
                  // If the DETERMINE keyword is passed in mask, return
                  // the one relationship keyword that best matches the geometries.
                  // 
                  Iterator iter = al.iterator();
                  returnString = "";
                  while (iter.hasNext()) {
                      returnString += (String)iter.next() +",";
                  }
                  // remove unwanted end ","
                  returnString = returnString.substring(0, returnString.length()-1);
              } else {
                  // If a mask listing one or more relationships is passed in, 
                  // the function returns the name of the relationship if it
                  // is true for the pair of geometries. If all relationships 
                  // are false, the procedure returns FALSE.
                  //
                  StringTokenizer st = new StringTokenizer(mask.toUpperCase(),",");
                  String token = "";
                  returnString = "";
                  while ( st.hasMoreTokens() ) {
                      token = st.nextToken();
                      if ( al.contains(token) )
                          returnString += token + ",";
                  }
                  if ( returnString.length()==0 ) {
                      // Passed in relationships do not exist 
                      returnString = "FALSE";  
                  } else {
                      // remove unwanted end ","
                      returnString = returnString.substring(0, returnString.length()-1);
                  }
              }
          }
        } catch (Exception e) {
            returnString = "ERROR: " + e.toString();
        }
      return returnString;
    }
    
}
