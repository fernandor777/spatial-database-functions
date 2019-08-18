/*
 * JASPA. JAva SPAtial for SQL.
 * 
 * Copyright (C) 2009-2011 Jose Martinez-Llario. 
 * 
 * This file is part of JASPA. 
 * JASPA is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *  
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *  
 * For more information, contact:
 *
 *   Jose Martinez-Llario
 *   Universidad Politecnica de Valencia
 *   Camino de Vera s/n
 *   46022 VALENCIA
 *   SPAIN
 *
 *   +34 963877007 ext 75599
 *   jomarlla@cgf.upv.es
 *   http://www.upv.es
 *   
 * Acknowledge:
 * 
 * JASPA is based on other open source projects. We are very grateful to:  
 * - PostGIS. http://postgis.refractions.net/
 * - Java Topology Suite (JTS). http://sourceforge.net/projects/jts-topo-suite/
 * - GeoTools. http://www.geotools.org/
 * - H2 and H2 Spatial 
 *   http://www.h2database.com
 *   http://geoserver.org/display/GEOS/H2+Spatial+Database 
 * - PL/Java. http://pgfoundry.org/projects/pljava/
 * - PostgreSQL. http://www.postgresql.org/
 * 
 */

package es.upv.jaspa;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Array;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.Properties;
import java.util.logging.Logger;

/* SGG import javax.measure.unit.SI;

import org.geotools.referencing.CRS;
import org.geotools.referencing.datum.DefaultEllipsoid;
import org.geotools.referencing.factory.AbstractAuthorityFactory;
import org.opengis.referencing.crs.CRSAuthorityFactory;
import org.opengis.referencing.crs.CoordinateReferenceSystem;
import org.opengis.referencing.datum.Ellipsoid;
*/

import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.CoordinateArrays;
import org.locationtech.jts.geom.CoordinateSequence;
import org.locationtech.jts.geom.CoordinateSequenceFactory;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryCollection;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.Lineal;
import org.locationtech.jts.geom.LinearRing;
import org.locationtech.jts.geom.MultiLineString;
import org.locationtech.jts.geom.MultiPoint;
import org.locationtech.jts.geom.MultiPolygon;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.Polygon;
import org.locationtech.jts.geom.Polygonal;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.geom.impl.CoordinateArraySequenceFactory;
import org.locationtech.jts.geom.impl.PackedCoordinateSequenceFactory;
import org.locationtech.jts.util.Assert;

/** SGG import es.upv.jaspa.calculation.Spheroid;
import es.upv.jaspa.datasource.JaspaJDBC;
**/
import es.upv.jaspa.exceptions.JASPAGeoToolsException;
import es.upv.jaspa.exceptions.JASPAGeomMismatchException;
import es.upv.jaspa.exceptions.JASPAGeomParseException;
import es.upv.jaspa.exceptions.JASPAIllegalArgumentException;
import es.upv.jaspa.exceptions.JASPAJTSException;
import es.upv.jaspa.io.BinaryFormat;
import es.upv.jaspa.io.GBLOB2JTS;
import es.upv.jaspa.io.JTS2GBLOB;
import es.upv.jaspa.io.JTS2WKT;
import es.upv.jaspa.io.WKT2JTS;

import org.locationtech.jts.geom.prep.PreparedGeometryFactory;

/**
 * @author Jose Martinez-Llario
 *
 */
public final class Core {
	// Suffix name for the column containing the spatial boxes (so far it is not used)
	//not used
	public static final String dedicatedColumnForSpatialIndex = "idx";

	// GeometryFactory
	private static final int factoryXYZM_notpackedDouble = 0; // Default
	private static final int factoryXYZ_packedFloat = 11;
	private static final int factoryXYZM_packedFloat = 12;
	private static final int factoryXYZ_packedDouble = 21;
	private static final int factoryXYZM_packedDouble = 22;
	private static CoordinateSequenceFactory defaultCoordinateSequenceFactory = getInstanceCoordinateSequenceFactory(Core.factoryXYZM_notpackedDouble);

	// JTS: GeometryFactory types and precision model
	private static final PrecisionModel INSTANCE_OF_PRECISIONMODEL_FLOAT;
	private static final PrecisionModel INSTANCE_OF_PRECISIONMODEL_DOUBLE;
	private static final PrecisionModel INSTANCE_OF_PRECISIONMODEL_FIXED[] = new PrecisionModel[16];

	static {
		INSTANCE_OF_PRECISIONMODEL_FLOAT = new PrecisionModel(PrecisionModel.FLOATING_SINGLE);
		INSTANCE_OF_PRECISIONMODEL_DOUBLE = new PrecisionModel(PrecisionModel.FLOATING);

		for (int i = 0; i < INSTANCE_OF_PRECISIONMODEL_FIXED.length; i++) {
			INSTANCE_OF_PRECISIONMODEL_FIXED[i] = new PrecisionModel(Math.pow(10, i));
		}
	}

	private static PrecisionModel defaultPrecisionModel = Core
			.getInstancePrecisionModel(PrecisionModel.FLOATING);
	private static int defaulPrecisionDecimalDigits = 10;

	// Log messages
	public static final int log_info = 0;
	public static final int log_warning = 1;
	public static final int log_debug = 2;
	public static final int log_error = 3; // not used

	/*
	 * Supported databases: 
	 * HSQLDB is not supported mainly: 4, 7 (HSQL 2.0.1 should support it) 
	 * Derby is not supported mainly: 4 
	 * H2 is supported: it does not have spatial indexes 8
	 * PostgreSQL plus PLJAVA support all the requirements
	 * 
	 * A database needs the following characteristics to be able to support JASPA: 
	 * 1. Stored procedures in java 
	 * 2. Binary type (byte[] in java)
	 * 3. Arrays of Binary types
	 * 4. User defined aggregates (e.g. ST_UNION(geometry))
	 * 5. Triggers 
	 * 6. Return arrays of binary types (e.g. ST_ACCUM(geom)) 
	 * 7. Return tables (e.g. ST_DUMP(geometry)) 
	 * 8. Spatial index (optional)
	 */
	// TODO
	// Change SQLCode because the array typeValue takes
	// in the second array this values directly
	public static final int dbPostgreSQL = 1;
	public static final int dbH2 = 2; // topology and spatial index are not supported
	public static final int dbHSQLDB = 3; // not supported
	public static final int dbDerby = 4; // not supported
	public static final int dbOracle = 5; // not supported

	private static int jaspa4db;

	public static final String buildDate = "18-07-2011 12:30";
	public static final String jaspaShortVersion = "0.2";
	public static final String jaspaVersion = jaspaShortVersion + ".0";

	public static final int googleEarthEPSG = 4326;

	/*
	 * =====================================================================================
	 * 
	 * Static initializer
	 * 
	 * =======================================================================================
	 */
	public static final String defaultJaspaSchema;
	public static final String defaultJaspaSchemaPath;
	public static final String publicSchema;
	public static final String geometryColumnsTable;
	public static final String geometryColumnsExtendTable;
	public static final String spatialRefSysTable;
	public static final String authorizationTable;
	public static final String lockTable;
	public static final String name_check_clause_srid;
	public static final String name_check_clause_dims;
	public static final String name_check_clause_geotype;
	public static final String name_trigger_log_transactions;

	static {
		/*
		 * =====================================================================================
		 * Define the SQL sentences case by default
		 * =======================================================================================
		 */
		Properties defaultProps = new Properties();
		InputStream in = ClassLoader.getSystemClassLoader().getResourceAsStream("jaspa.properties");		

		// Load the file properties
		boolean propertiesNotFound = true;
      /** SGG
		if (in != null) {
			try {
				defaultProps.load(in);
				propertiesNotFound = false;
			} catch (IOException e) {
				Core.log("jaspa.properties couldnt be loaded. Using default properties",Core.log_warning);
			}
		} else {
			Core.log("jaspa.properties not found. Using default properties", Core.log_warning);
		}
        **/
		
		//If the jaspa jar is used in a client mode then the jaspa.properties wont be found
		//and the user has to set up the connection type using the Core.setDB() method.

		// Assign the properties to the Core variables
		if (propertiesNotFound) {
			jaspa4db = dbPostgreSQL;
		} else {
                    String jaspa4db_prop = (String) defaultProps.get("jaspa4db");
                    
                    if (jaspa4db_prop.equalsIgnoreCase("postgresql")) {
                        jaspa4db = dbPostgreSQL;
                    } else if (jaspa4db_prop.equalsIgnoreCase("h2")) {
                        jaspa4db = dbH2;
                    } else if (jaspa4db_prop.equalsIgnoreCase("oracle")) {
                        jaspa4db = dbOracle;
                    } else {
			jaspa4db = dbPostgreSQL; // Default
                    }
		}

		/*
		 * =====================================================================================
		 * Default Schema and metadata table names
		 * =======================================================================================
		 */
		defaultJaspaSchema = "jaspa";
		defaultJaspaSchemaPath = "jaspa.";
		geometryColumnsTable = "geometry_columns";
		geometryColumnsExtendTable = "geometry_columns_extend";
		spatialRefSysTable = "spatial_ref_sys";
		authorizationTable = "authorization_table";
		lockTable = "temp_lock_have_table";
		publicSchema = "public";

		/*
		 * =====================================================================================
		 * Default names for the check restrictions in a geometry table
		 * =======================================================================================
		 */

		name_check_clause_srid = "enforce_srid";
		name_check_clause_dims = "enforce_dims";
		name_check_clause_geotype = "enforce_geotype";
		name_trigger_log_transactions = "check_auth";
	}

	/*
	 * =====================================================================================
	 * 
	 * E-WKB, E-WKT, JTS converters
	 * 
	 * =======================================================================================
	 */
	public static byte[] getWKBFromGBLOB(byte sgeom[], int byteOrder)
			throws JASPAGeomParseException {

		Geometry geom = Core.getJTSGeometryFromGBLOB(sgeom);
		if (geom == null) return null;

		return Core.getWKBFromJTSGeometry(geom, byteOrder);
	}

	public static byte[] getEWKBFromGBLOB(byte sgeom[], int byteOrder)
			throws JASPAGeomParseException {

		Geometry geom = Core.getJTSGeometryFromGBLOB(sgeom);
		if (geom == null) return null;

		return Core.getEWKBFromJTSGeometry(geom, byteOrder);
	}

	public static String getHexBinFromGBLOB(byte sgeom[], String byteOrder, int withSRID)
			throws JASPAGeomParseException, JASPAIllegalArgumentException {

		Geometry geom = getJTSGeometryFromGBLOB(sgeom);
		if (geom == null) return null;

		return getHexBinFromJTSGeometry(geom, byteOrder, withSRID);
	}

	public static String getHexBinFromJTSGeometry(Geometry geom, String byteOrder, int withSRID)
			throws JASPAIllegalArgumentException, JASPAGeomParseException {

		if (Core.isEmptyOrNullGeometry(geom)) return null;

		Integer order = Core.getByteOrderFromText(byteOrder);
		if (order == null) return null;

		return JTS2GBLOB.bytesToHex(JTS2GBLOB.instance(order.intValue()).write(geom, withSRID));
	}

	public static Geometry getJTSGeometryFromEWKTorWKT(String ewkt)
			throws JASPAGeomParseException {

		if (ewkt == null || ewkt.length() == 0) return null;

		Geometry geom = null;
		geom = WKT2JTS.instance().read(ewkt);

		if (isEmptyOrNullGeometry(geom)) return null;

		return geom;
	}

	public static Integer getByteOrderFromText(String byteOrder)
			throws JASPAIllegalArgumentException {

		if (byteOrder == null || byteOrder.length() == 0) return null;

		int order;

		if (byteOrder.equalsIgnoreCase("XDR")) {
			order = BinaryFormat.wkbXDR;
		} else if (byteOrder.equalsIgnoreCase("NDR")) {
			order = BinaryFormat.wkbNDR;
		} else {
			throw new JASPAIllegalArgumentException(
					"The byte order must be NDR (little-endian) or XDR (big-endian): found " + byteOrder);
		}

		return new Integer(order);
	}

	public static byte[] getWKBFromJTSGeometry(Geometry geom)
			throws JASPAGeomParseException {
		return getWKBFromJTSGeometry(geom, BinaryFormat.defaultByteOrder);
	}

	public static byte[] getGBLOBFromJTSGeometry(Geometry geom)
			throws JASPAGeomParseException {

		return getGBLOBFromJTSGeometry(geom, BinaryFormat.defaultByteOrder);
	}

	public static byte[] getGBLOBFromJTSGeometry(Geometry geom, int byteOrder)
			throws JASPAGeomParseException {

		return JTS2GBLOB.instance(byteOrder).write(geom, BinaryFormat.wkbJASPAFormatVectorial);
	}

	public static byte[] getEWKBFromJTSGeometry(Geometry geom)
			throws JASPAGeomParseException {

		return getEWKBFromJTSGeometry(geom, BinaryFormat.defaultByteOrder);
	}

	public static byte[] getEWKBFromJTSGeometry(Geometry geom, int byteOrder)
			throws JASPAGeomParseException {

		return JTS2GBLOB.instance(byteOrder).write(geom, BinaryFormat.wkbPostGISwithSRID);
	}

	public static byte[] getWKBFromJTSGeometry(Geometry geom, int byteOrder)
			throws JASPAGeomParseException {

		if (isEmptyOrNullGeometry(geom)) return null;

		return JTS2GBLOB.instance(byteOrder).write(geom, BinaryFormat.wkbPostGISwithoutSRID);
	}

	public static String getEWKTFromJTSGeometry(Geometry geom)
			throws JASPAGeomParseException 
    {
		if (isEmptyOrNullGeometry(geom)) return null;

		String geomString = getWKTFromJTSGeometry(geom);

		int SRID = geom.getSRID();
		String geomWithSRID = null;

		if (SRID != BinaryFormat.defaultSRID) {
		    /* SGG geomWithSRID = (new StringBuilder("SRID=")).append(geom.getSRID()).append(";").append(geomString).toString(); */
                    geomWithSRID = "SRID=" + String.valueOf(SRID) + ";" + geomString;
		} else {
		    geomWithSRID = geomString;
		}
		return geomWithSRID;
	}

	public static String getWKTFromJTSGeometry(Geometry geom)
			throws JASPAGeomParseException {

		if (isEmptyOrNullGeometry(geom)) return null;

		return JTS2WKT.instance().write(geom);
	}

	public static Geometry getJTSGeometryFromGBLOB(byte sgeom[])
			throws JASPAGeomParseException {

		if (sgeom == null) return null;

		if (Core.getDB() == Core.dbPostgreSQL) if (sgeom.length > 0) {
			// Normal Use: SELECT ST_NUMPOINTS(ST_GEOMFROMTEXT('POINT(10,10)'));

			// This code is necessary to support implicit casting to geometry
			// types, since PLJAVA does not support custom types.
			// This way the user can use automatic cast to geometry types, for
			// example:
			// SELECT ST_NUMPOINTS('POINT(10,10)'); will work
			// or after creating a domain: CREATE DOMAIN geometry as bytea;
			// SELECT ST_NUMPOINTS('POINT(10,10)'::geometry);
			// This behavior is implemented to enhance PostGIS compatibility
			// With other databases we must check this behavior or to create
			// custom types
			if (sgeom[0] == 'P' || sgeom[0] == 'L' || sgeom[0] == 'M' || sgeom[0] == 'G'
					|| sgeom[0] == 'S' || sgeom[0] == 'B' || sgeom[0] == '(') {
				String ewkt = new String(sgeom);
				return Core.getJTSGeometryFromEWKTorWKT(ewkt);
			}

			// First byte will be 0 or 1 if it is a wkb or ewkb string
			// It will be able to work directly with hex chains as:
			// select st_numpoints ('010100000000000000000024400000000000003440');
			if (sgeom[0] >= 48) {
				String hex = new String(sgeom);
				System.out.println(hex);
				sgeom = GBLOB2JTS.hexToBytes(hex);
			}
		}

		// Read binary
		Geometry geom;
		geom = GBLOB2JTS.instance().read(sgeom);

		// If the geometry arg0 is empty (GEOMETRYCOLLECTION EMPTY in JTS 1,10)
		// return null

		if (geom != null && (!geom.isEmpty())) return geom;

		return null;
	}

	/*
	 * ===================================================================================== End of
	 * E-WKB, E-WKT, JTS converters
	 * =======================================================================================
	 */

	/*
	 * =====================================================================================
	 * 
	 * Exception management
	 * 
	 * =======================================================================================
	 */

	public static void manageJTSExceptions(Exception e)
			throws JASPAJTSException {

		throw new JASPAJTSException(e);

		/*
		 * This method can be update to manage the different JTS exceptions: IllegalArgumentExcpetion
		 * (Geometry factories, null geometries,etc.) AssertionFailedException (runtime
		 * inconsistencies)
		 * 
		 * Example: a new JASPAJTSIllegalArgument could be extend JASPAJTSException and if (e instance
		 * IllegealArgumentException) throw new JASPAJTSIllegalArgument(e); ...
		 */
	}

	public static void manageGeoToolsExceptions(Exception e)
			throws JASPAGeoToolsException {

		// see manageJTSExceptions (RuntimeException e)
		throw new JASPAGeoToolsException(e);
	}

	private static void throwErrorWithTextArgument(String text, Geometry geom, int argument)
			throws JASPAIllegalArgumentException {

		StringBuffer buf = new StringBuffer();
		buf.append("The ");
		if (argument > 0) {
			if (argument == 1) {
				buf.append("first argument ");
			} else if (argument == 2) {
				buf.append("second argument ");
			} else if (argument == 3) {
				buf.append("third argument ");
			} else {
				buf.append("geometry ");
			}
		} else {
			buf.append("geometry ");
		}

		buf.append("must be a ").append(text).append(": found ");

		if (geom == null) {
			buf.append("a null reference");
		} else if (geom.isEmpty()) {
			buf.append("an empty ").append(text);
		} else {
			buf.append(geom.getGeometryType());
		}

		throw new JASPAIllegalArgumentException(buf.toString());
	}

	public static boolean errorIfNotPoint(Geometry geom, int argument)
			throws JASPAIllegalArgumentException {

		// Does not throw any exception with a null or empty geometry
		if (isNullGeometry(geom)) return true;

		if (geom instanceof Point) return false;

		throwErrorWithTextArgument("Point", geom, argument);

		return true; // not reached
	}

	public static boolean errorIfNotMPoint(Geometry geom, int argument)
			throws JASPAIllegalArgumentException {

		// Does not print any messages with a null or empty geometry
		if (isNullGeometry(geom)) return true;

		if (geom instanceof MultiPoint) return false;
		throwErrorWithTextArgument("MultiPoint", geom, argument);

		return true; // not reached
	}

	public static boolean errorIfNotLineal(Geometry geom, int argument)
			throws JASPAIllegalArgumentException {

		// Does not print any messages with a null or empty geometry
		if (isNullGeometry(geom)) return true;

		if (geom instanceof Lineal) return false;
		throwErrorWithTextArgument("LineString or MultiLineString", geom, argument);

		return true; // not reached
	}

	public static boolean errorIfNotPolygonal(Geometry geom, int argument)
			throws JASPAIllegalArgumentException {

		// Does not print any messages with a null or empty geometry
		if (isNullGeometry(geom)) return true;

		if (geom instanceof Polygonal) return false;
		throwErrorWithTextArgument("Polygon or MultiPolygon", geom, argument);

		return true; // not reached
	}

	/*
	 * ===================================================================================== End of
	 * Exception management
	 * =======================================================================================
	 */

	/*
	 * =====================================================================================
	 * 
	 * Checking geometries
	 * 
	 * =======================================================================================
	 */

	/**
	 * Check if the JTS Geometry is a GeometryCollection but not a multi-type geometry
	 * 
	 * @param geom
	 *           JTS Geometry
	 * @return true if geom is a GeometryCollection type (multi-types return false)
	 */
	public static Boolean isGeomColl(Geometry geom) {

		if (isNullGeometry(geom)) return null;

		if (!(geom instanceof GeometryCollection)) return Boolean.valueOf(false);
		if (geom instanceof MultiLineString) return Boolean.valueOf(false);
		if (geom instanceof MultiPoint) return Boolean.valueOf(false);
		if (geom instanceof MultiPolygon) return Boolean.valueOf(false);

		return Boolean.valueOf(true);
	}

	/**
	 * Check if the JTS Geometry or some of their component geometries are of the specified dimension
	 * 
	 * @param geom
	 *           JTS Geometry
	 * @param dimension
	 *           Geometry dimension (0 puntal, 1 lineal, 2 areal)
	 * @return true if geom contains any element with the specified dimension
	 */
	public static boolean containsDimension(Geometry geom, int dimension) {

		if (isNullGeometry(geom)) return false;

		if (!(geom instanceof GeometryCollection)) return (geom.getDimension() == dimension);

		int ngeom = geom.getNumGeometries();
		boolean hasDimension = false;
		if (ngeom > 0) {
			for (int i = 0; i < ngeom; i++) {
				hasDimension = containsDimension(geom.getGeometryN(i), dimension);
				if (hasDimension) {
					break;
				}
			}
		}

		return hasDimension;
	}

	public static Boolean isEqualsGBLOB(byte sgeom0[], byte sgeom1[]) {

		if ((sgeom0 == null) || (sgeom1 == null)) return Boolean.valueOf(false);
		return Boolean.valueOf(Arrays.equals(sgeom0, sgeom1));
	}

	/**
	 * Check if a JTS Geometry is null or empty. In JTS 1.10 a geometry might be empty
	 * ('GEOMETRYCOLLECTION EMPTY') or null. JASPA converts empty JTS geometries to null geometries
	 * 
	 * @param geom
	 *           JTS Geometry
	 * @return true if geom is null or empty false if geom contains at least one coordinate
	 */
	public static boolean isNullGeometry(Geometry geom) {

		if (geom == null) return true;
		return false;
	}

	public static boolean isEmptyOrNullGeometry(Geometry geom) {

		if (geom == null) return true;
		if (geom.isEmpty()) return true;

		return false;
	}

	public static Geometry setNullIfEmpty(Geometry geom) {

		if (isNullGeometry(geom)) return null;
		return geom;
	}

	/*
	 * ===================================================================================== End of
	 * Checking geometries
	 * =======================================================================================
	 */

	/*
	 * =====================================================================================
	 * 
	 * JTS Geometry Factory
	 * 
	 * =======================================================================================
	 */

	public static GeometryFactory getInstanceGeometryFactory(int decimalDigits, int SRID) {

		return new GeometryFactory(getInstancePrecisionModel(decimalDigits), SRID,
				Core.defaultCoordinateSequenceFactory);
	}

	public static GeometryFactory getInstanceGeometryFactory(int SRID) {

		return new GeometryFactory(defaultPrecisionModel, SRID, Core.defaultCoordinateSequenceFactory);
	}

	public static GeometryFactory getInstanceGeometryFactory() {
		return new GeometryFactory(defaultPrecisionModel, BinaryFormat.defaultSRID, Core.defaultCoordinateSequenceFactory);
	}

	private static PrecisionModel getInstancePrecisionModel(PrecisionModel.Type type) {

		if (type == PrecisionModel.FLOATING)
			return INSTANCE_OF_PRECISIONMODEL_DOUBLE;
		else if (type == PrecisionModel.FLOATING_SINGLE)
			return INSTANCE_OF_PRECISIONMODEL_FLOAT;
		else
			return INSTANCE_OF_PRECISIONMODEL_FIXED[defaulPrecisionDecimalDigits];
	}

	private static PrecisionModel getInstancePrecisionModel(int decimalDigits) {

		if (decimalDigits < 0 || decimalDigits > 15) decimalDigits = 0;
		return INSTANCE_OF_PRECISIONMODEL_FIXED[decimalDigits];
	}

	private static CoordinateSequenceFactory getInstanceCoordinateSequenceFactory(
			int coordinateSequenceType) {

		switch (coordinateSequenceType) {

		// DEFAULT: XYZM not packed, double
		// Core.factoryXYZM_notpackeddDouble
		default:
			return CoordinateArraySequenceFactory.instance();

			// XYZ packed, float
		case Core.factoryXYZ_packedFloat:
			PackedCoordinateSequenceFactory.FLOAT_FACTORY.setDimension(3);
			return PackedCoordinateSequenceFactory.FLOAT_FACTORY;

			// XYZM packed, float
		case Core.factoryXYZM_packedFloat:
			PackedCoordinateSequenceFactory.FLOAT_FACTORY.setDimension(4);
			return PackedCoordinateSequenceFactory.FLOAT_FACTORY;

			// XYZ packed, double
		case Core.factoryXYZ_packedDouble:
			PackedCoordinateSequenceFactory.DOUBLE_FACTORY.setDimension(3);
			return PackedCoordinateSequenceFactory.DOUBLE_FACTORY;

			// XYZ packed, double
		case Core.factoryXYZM_packedDouble:
			PackedCoordinateSequenceFactory.DOUBLE_FACTORY.setDimension(4);
			return PackedCoordinateSequenceFactory.DOUBLE_FACTORY;
		}
	}
    
    public static CoordinateSequenceFactory getCoordinateSequenceFactory() {
        return getInstanceCoordinateSequenceFactory(Core.factoryXYZM_notpackedDouble);
    }

	/*
	 * ===================================================================================== End of
	 * JTS Geometry Factory
	 * =======================================================================================
	 */

	/*
	 * =====================================================================================
	 * 
	 * Dump and Collect functions
	 * 
	 * 
	 * =======================================================================================
	 */

	// TODO: Implement inside collectJTSGeometry
	public static Geometry collectJTSGeometry(
			Geometry[] geomArray, boolean dontgroupgeometries, boolean returnsMulti,
			boolean checkNullOrEmptyGeometries)
			throws JASPAGeomMismatchException, JASPAJTSException {

		return collectJTSGeometry(Arrays.asList(geomArray), dontgroupgeometries, returnsMulti,
				checkNullOrEmptyGeometries);
	}

	// This function is taken from JTS Code (GeometryFactory.buildGeometry)
	// but it is modified to check SRID and coordinate dimension

	// Collect from just a MULTIGEOMETRY OR A GEOMETRYCOLLECTION RETURNS
	// PostGIS and JTS Build Geometry -> GEOMETRYCOLLECTION (MULTILINESTRING(..))
	// -> GEOMETRYCOLLECTION (GEOMETRYCOLLECTION(..))
	// JASPA -> MULTILINESTRING(..)
	// -> GEOMETRYCOLLECTION(..)
	// The rest of the behavior is the same:
	// A - HETEROGENEOUS -> GeomCollection
	// B - HOMOGENEOUS WITH > 1 Geometries
	// B1 - Polygon -> MultiPolygon //Could get an invalid Multipolygon
	// B1 - LineString -> MultiLineString //Could get an invalid Multilinestring
	// B1 - Point -> MultiPoint
	// B2 - MultiPoint -> GeometryCollection
	// B2 - MultiLineString -> GeometryCollection
	// B2 - MultiPolygon -> GeometryCollection
	// B2 - GeometryCollection -> GeometryCollection
	// C - HOMOGENEOUS WITH JUST 1 Geometry
	// RETURNS the original geometry

	/**
	 * @param geomList
	 *           List of geometries to be collected
	 * @param dontgroupgeometries
	 *           If it is true dont group simple geometries into multi-types.
	 * @param returnsMulti
	 *           If it is true always returns MultiGeometries. ST_COLLECT has a false behavior.
	 * @param checkNullOrEmptyGeometries
	 *           Check the geometries and reject the one which is null or empty. Use false just in
	 *           the case you are sure none of the geometries are null
	 * @return The collected geometry
	 * @throws JASPAGeomMismatchException
	 * @throws JASPAJTSException
	 */

	public static Geometry collectJTSGeometry(List geomList, /*ListSGG<Geometry> geomList,*/ 
                                                  boolean dontgroupgeometries, 
                                                  boolean returnsMulti,
                                                  boolean checkNullOrEmptyGeometries)
        throws JASPAGeomMismatchException, 
               JASPAJTSException 
        {

		Class geomClass = null;
		boolean isHeterogeneous = false;
		boolean hasGeometryCollection = false;

		List/*SGG<Geometry>*/ geomListValid;

		if (checkNullOrEmptyGeometries) {
			geomListValid = new ArrayList/*SGG<Geometry>*/();
		} else {
			geomListValid = geomList;
		}

		Iterator/*SGG<Geometry>*/ geomIterator = geomList.iterator();

		if (GeomProperties.errorIfDifferentSRIDorCoorDim(geomList)) return null;

		GeometryFactory factory = null;
		int SRID = BinaryFormat.defaultSRID;

		while (geomIterator.hasNext()) {
			Geometry geom = (Geometry)geomIterator.next();
			if (geom != null && (!geom.isEmpty())) {
				Class partClass = geom.getClass();
				if (geomClass == null) {
					geomClass = partClass;
					factory = geom.getFactory();
					SRID = geom.getSRID();
				}
				if (partClass != geomClass) {
					isHeterogeneous = true;
				}

				if (geom instanceof GeometryCollection) {
					hasGeometryCollection = true;
				}

				if (checkNullOrEmptyGeometries) {
					geomListValid.add(geom);
				}
			}
		}

		/**
		 * Now construct an appropriate geometry to return
		 */
		if (geomClass == null) return null;

		boolean isCollection = geomListValid.size() > 1;

		if (isHeterogeneous || dontgroupgeometries
				|| ((!isHeterogeneous) && isCollection && hasGeometryCollection)) {
			Geometry res = null;
			try {
				res = factory.createGeometryCollection(GeometryFactory.toGeometryArray(geomListValid));
			} catch (RuntimeException e) {
				// Catch the runtime JTS Exceptions
				Core.manageJTSExceptions(e);
			}

			res.setSRID(SRID);
			return res;
		}

		// at this point we know the collection is hetereogenous.
		// Determine the type of the result from the first Geometry in the list
		Geometry res = (Geometry)geomListValid.get(0);

		if ((isCollection) || (returnsMulti && !isCollection)) {
			try {
				if (res instanceof Polygon) {
					res = factory.createMultiPolygon(GeometryFactory.toPolygonArray(geomListValid));
				} else if (res instanceof LineString) {
					res = factory
							.createMultiLineString(GeometryFactory.toLineStringArray(geomListValid));
				} else if (res instanceof Point) {
					res = factory.createMultiPoint(GeometryFactory.toPointArray(geomListValid));
				}
			} catch (RuntimeException e) {
				// Catch the runtime JTS Exceptions
				Core.manageJTSExceptions(e);
			}

		}

		if (res != null) res.setSRID(SRID);
		return res;
	}

	/**
	 * Dump a JTS geometry to their sub-elements
	 * 
	 * @param arraygeom
	 *           Array of serialized geometries containing the dumped geometries
	 * @param geom
	 *           JTS Geometry to be dumped
	 * @param dumpMultiGeometries
	 *           Dump multigeometries
	 * @throws JASPAGeomParseException
	 */
	public static void dumpJTSGeometryToGBLOB(List arraygeom, /*List<byte[]> arraygeom,*/ 
                                                  Geometry geom, 
                                                  boolean dumpMultiGeometries)
        throws JASPAGeomParseException 
        {
	    dumpJTSGeometryToGBLOBWithDimensionFilter(arraygeom, geom, -1, geom.getSRID(), dumpMultiGeometries);
	}

	public static void dumpJTSGeometryToGBLOB(List arraygeom, /*List<byte[]> arraygeom,*/ 
                                                  Geometry geom, 
                                                  int dimension, 
                                                  boolean dumpMultiGeometries)
        throws JASPAGeomParseException 
        {
            dumpJTSGeometryToGBLOBWithDimensionFilter(arraygeom, geom, dimension, geom.getSRID(),dumpMultiGeometries);
	}

	/**
	 * Dump a JTS geometry to their sub-elements
	 * 
	 * @param arraysgeom
	 *           Array of serialized geometries containing the dumped geometries
	 * @param geom
	 *           JTS Geometry to be dumped
	 * @param dimension
	 *           Dimension of the Geometries to be dumped. 0 (puntal) 1 (lineal) 2 (areal) -1 (dump
	 *           all the geometries)
	 * @param SRID
	 *           SRID used to set up the dumped geometries
	 * @param dumpMultiGeometries
	 *           Dump multigeometries
	 * @throws JASPAGeomParseException
	 */
	private static void dumpJTSGeometryToGBLOBWithDimensionFilter(List arraysgeom, /*ListSGG<byte[]> arraysgeom,*/
                                                                      Geometry geom, 
                                                                      int dimension, 
                                                                      int SRID,
                                                                      boolean dumpMultiGeometries)
        throws JASPAGeomParseException 
        {
            if (Core.isNullGeometry(geom)) return;

            if (((!dumpMultiGeometries) && Core.isGeomColl(geom).booleanValue())
                            || (dumpMultiGeometries && (geom instanceof GeometryCollection))) {
                int ngeom = geom.getNumGeometries();
                if (ngeom > 0) {
                    for (int i = 0; i < ngeom; i++) {
                        dumpJTSGeometryToGBLOBWithDimensionFilter(arraysgeom, geom.getGeometryN(i),
                                        dimension, SRID, dumpMultiGeometries);
                    }
                }
            } else {
                if (!geom.isEmpty()) if ((dimension == -1) || (dimension == geom.getDimension())) {
                    geom.setSRID(SRID);
                    arraysgeom.add(getGBLOBFromJTSGeometry(geom));
                }
                return;
            }
	}

	/**
	 * Dump a JTS geometry to their sub-elements
	 * 
	 * @param arraygeom
	 *           Array of JTS geometries containing the dumped geometries
	 * @param geom
	 *           JTS Geometry to be dumped
	 * @param isMulti
	 *           is JTS Geometry a multigeometry
	 */
	public static void dumpJTSGeometry(List arraygeom, /*List<Geometry> arraygeom,*/
                                           Geometry geom, 
                                           boolean isMulti) 
        {
	    dumpJTSGeometryWithDimensionFilter(arraygeom, geom, -1, geom.getSRID(), isMulti);
	}

	public static void dumpJTSGeometry(List arraygeom, /*List<Geometry> arraygeom,*/
                                           Geometry geom, 
                                           int dimension, 
                                           boolean dumpMultiGeometries) 
        {
            dumpJTSGeometryWithDimensionFilter(arraygeom, geom, dimension, geom.getSRID(), dumpMultiGeometries);
	}

	/**
	 * Dump a JTS geometry to their sub-elements. If some subelement is a null or empty geometry then
	 * this subelement wont be dumped.
	 * 
	 * @param arraygeom
	 *           Array of JTS geometries containing the dumped geometries
	 * @param geom
	 *           JTS Geometry to be dumped
	 * @param dimension
	 *           Dimension of the Geometries to be dumped. 0 (puntal) 1 (lineal) 2 (areal) -1 (dump
	 *           all the geometries)
	 * @param SRID
	 *           SRID used to set up the dumped geometries
	 * @param dumpMultiGeometries
	 *           Dump multigeometries
	 */
	public static void dumpJTSGeometryWithDimensionFilter(List arraygeom, /*List<Geometry> arraygeom,*/
                                                              Geometry geom, 
                                                              int dimension, 
                                                              int SRID,
                                                              boolean dumpMultiGeometries) 
        {
            if (Core.isNullGeometry(geom)) return;

            if ((dumpMultiGeometries && (geom instanceof GeometryCollection))
            || ((!dumpMultiGeometries) && Core.isGeomColl(geom).booleanValue())) {
                int ngeom = geom.getNumGeometries();
                if (ngeom > 0) {
                    for (int i = 0; i < ngeom; i++) {
                        dumpJTSGeometryWithDimensionFilter(arraygeom, geom.getGeometryN(i), dimension, SRID,
                                        dumpMultiGeometries);
                    }
                }
            } else {
                if ((dimension == -1) || (dimension == geom.getDimension())) {
                        geom.setSRID(SRID);
                        arraygeom.add(geom);
                }
                return;
            }
	}

	/*
	 * ===================================================================================== End of
	 * Dump and Collect functions
	 * =======================================================================================
	 */

	/*
	 * =====================================================================================
	 * 
	 * Box functions
	 * 
	 * 
	 * =======================================================================================
	 */

	/**
	 * Make a JTS Polygon geometry that represents the box from the input coordinates. The output JTS
	 * polygon might be a degenerated polygon (a line, a point, etc).
	 * 
	 * @param factory
	 *           Factory used to create the output JTS geometry
	 * @param lb
	 *           Left bottom coordinate
	 * @param rt
	 *           Right top coordinate
	 * @param forceDimension
	 *           Coordinate dimension for the output JTS geometry. Can be 2 (xy), 3 (xyz) or -1 (will
	 *           take the coordinate dimension from the input lb coordinate).
	 * @return JTS Polygon geometry
	 * @throws JASPAJTSException
	 * @throws IllegalArgumentException
	 */
	public static Polygon getJTSPolygonFromBOX(GeometryFactory factory, 
                                                   Coordinate lb, 
                                                   Coordinate rt, 
                                                   int forceDimension)
        throws JASPAJTSException 
        {
		double minz = lb.z;
		double maxz = rt.z;
		if (forceDimension == 2) {
			minz = Double.NaN;
			maxz = Double.NaN;
		} else if (forceDimension == 3) {
			if (Double.isNaN(lb.z) || Double.isNaN(rt.z)) {
				minz = 0;
				maxz = 0;
			}
			// If forceDimension is any other value then take the dimension from
			// the coordinates passed by argument
		} else {
			if (Double.isNaN(lb.z) || Double.isNaN(rt.z)) {
				minz = Double.NaN;
				maxz = Double.NaN;
			}
		}

		Coordinate vertex[] = new Coordinate[5];
		vertex[0] = new Coordinate(lb.x, lb.y, minz);
		vertex[1] = new Coordinate(lb.x, rt.y, maxz);
		vertex[2] = new Coordinate(rt.x, rt.y, maxz);
		vertex[3] = new Coordinate(rt.x, lb.y, minz);
		vertex[4] = new Coordinate(lb.x, lb.y, minz);

		try {
                    LinearRing lr = factory.createLinearRing(vertex);
                    if (lr != null) {
                        // lr.setSRID(SRID);
                        Polygon pl = factory.createPolygon(lr, null);
                        // if (pl != null) pl.setSRID(SRID);
                        return pl;
                    }

		} catch (RuntimeException e) {
			Core.manageJTSExceptions(e);
		}

		return null;
	}

	/**
	 * Column name of the prefix used to store the box of the spatial index.
	 * 
	 * @return String with the prefix text.
	 */
	public static String getDedicatedColumnForSpatialIndex() {

		return Core.dedicatedColumnForSpatialIndex;
	}

	/*
	 * =====================================================================================
	 * 
	 * Other functions
	 * 
	 * 
	 * =======================================================================================
	 */

	/**
	 * @param message
	 *           Text to send to the log system
	 * @param level
	 *           Can be Core.log_info, Core.log_warning or Core.log_debug
	 * @return String containing the log time plus the text message
	 */
	public static String log(String message, int level) 
        {
		switch (Core.getDB()) {
		case Core.dbPostgreSQL:
			Logger log = Logger.getAnonymousLogger();

			if (level == Core.log_info) {
				log.info("\n" + message);
			}
			if (level == Core.log_warning) {
				log.warning("\n" + message);
			}
			if (level == Core.log_debug) {
				log.fine("\n" + message);
			}
			break;

		// H2 uses defailt configutation so far
		default:
			String text;
			if (level == Core.log_info) {
				text = "INFO:    ";
			} else if (level == Core.log_warning) {
				text = "WARNING:    ";
			} else if (level == Core.log_debug) {
				text = "DEBUG:    ";
			} else
				text = "";

			System.out.println(text + new Date().toString() + " - " + message);

			break;
		}

		return null;
	}

	/**
	 * @param message
	 *           Text to send to the log system using the level Core.log_info
	 * @return String containing the log time plus the text message
	 */
	public static String log(String message) 
        {
            return log(message, Core.log_info);
	}

	/**
	 * Order the coordinates c0, c1. 
         * c0 will store the minimum x,y,z,m and c1 the maximum x,y,z,m.
	 * 
	 * @param c0
	 *           First coordinate
	 * @param c1
	 *           Second coordinate
	 */
	public static void orderCoordinates(Coordinate c0, Coordinate c1) 
        {
            if (c0.x > c1.x) {
                    double tmp = c1.x;
                    c1.x = c0.x;
                    c0.x = tmp;
            }
            if (c0.y > c1.y) {
                    double tmp = c1.y;
                    c1.y = c0.y;
                    c0.y = tmp;
            }
            if (c0.z > c1.z) {
                    double tmp = c1.z;
                    c1.z = c0.z;
                    c0.z = tmp;
            }
            if (c0.m > c1.m) {
                    double tmp = c1.m;
                    c1.m = c0.m;
                    c0.m = tmp;
            }
	}

	/**
	 * Force the polygon pol to keep the right hand rule in their exterior and interior rings. 
         * This function changes the pol geometry. It does not create a new geometry.
	 * 
	 * @param pol
	 *           JTS Polygon geometry
	 */
	public static void forceRHRPolygon(Polygon pol) 
        {
		LineString ls = pol.getExteriorRing();
		if (isRHR(ls.getCoordinateSequence())) {
			CoordinateArrays.reverse(ls.getCoordinates());
		}

		int nHoles = pol.getNumInteriorRing();
		if (nHoles > 0) {
			for (int i = 0; i < nHoles; i++) {
				LineString hole = pol.getInteriorRingN(i);
				if (!isRHR(hole.getCoordinateSequence())) {
					CoordinateArrays.reverse(hole.getCoordinates());
				}
			}
		}
	}

	private static boolean isRHR(CoordinateSequence coor) {

		int points = coor.size();

		double area = 0;

		for (int i = 0; i < points - 1; i++) {
			area += (coor.getY(i) * coor.getX(i + 1) - coor.getX(i) * coor.getY(i + 1));
		}

		return (area < 0);
	}

	/**
	 * @param SRID
	 *           SRID which ellipsoid we want to get (EPSG >= 7000 && EPSG <=7100)
	 * @return The Ellipsoid (org.opengis.referecing.datum.Ellipsoid) that belongs to the specified
	 *         SRID.
	 * @throws JASPAGeoToolsException
	public static Ellipsoid getEllipsoidFromSRID(int SRID)
			throws JASPAGeoToolsException {

		Ellipsoid ell = null;

		try {
			if (SRID == -1) {
				// Sphere
				ell = DefaultEllipsoid.createEllipsoid("", Spheroid.earthRadius, Spheroid.earthRadius,
						SI.METER);
			} else {
				if ((SRID >= 7000) && (SRID <= 7100)) {
					CRSAuthorityFactory factory = CRS.getAuthorityFactory(false);

					if (factory instanceof AbstractAuthorityFactory) {
						ell = ((AbstractAuthorityFactory) factory).createEllipsoid("EPSG:" + SRID);
					}
				} else {
					CoordinateReferenceSystem crs = CRS.decode("EPSG:" + SRID);
					ell = CRS.getEllipsoid(crs);
				}
			}
		} catch (Exception e) {
			// Catch the GeoTools Exceptions
			Core.manageGeoToolsExceptions(e);
		}

		return ell;
	}
**/
	// From JTS examples
	// TODO: GeometryCollection

	/*
	 * public static Geometry getEndPoints(Geometry geom) { if (Core.isEmptyOrNullGeometry(geom))
	 * return null;
	 * 
	 * List endPtList = new ArrayList(); if (geom instanceof LineString) { LineString line =
	 * (LineString) geom;
	 * 
	 * endPtList.add(line.getCoordinateN(0)); endPtList.add(line.getCoordinateN(line.getNumPoints() -
	 * 1)); } else if (geom instanceof MultiLineString) { MultiLineString mls = (MultiLineString)
	 * geom; for (int i = 0; i < mls.getNumGeometries(); i++) { LineString line = (LineString)
	 * mls.getGeometryN(i); endPtList.add(line.getCoordinateN(0));
	 * endPtList.add(line.getCoordinateN(line.getNumPoints() - 1)); } } else return null;
	 * 
	 * Coordinate[] endPts = CoordinateArrays.toCoordinateArray(endPtList); Geometry res =
	 * geom.getFactory().createMultiPoint(endPts); if (res != null) { res.setSRID(geom.getSRID()); }
	 * 
	 * return res; }
	 */
	public static Geometry getEndPoints(Geometry geom) {

		if (Core.isNullGeometry(geom)) return null;

		List/*SGG<Coordinate>*/ endPtList = new ArrayList/*SGG<Coordinate>*/();
		getEndPoints(geom, endPtList);

		if (endPtList.size() > 0) {

			Coordinate[] endPts = CoordinateArrays.toCoordinateArray(endPtList);
			Geometry res = geom.getFactory().createMultiPoint(endPts);
			if (res != null) {
				res.setSRID(geom.getSRID());
			}

			return res;
		}

		return null;
	}

	// TODO: GeometryCollection
	public static void getEndPoints(Geometry geom, List/*SGG<Coordinate>*/ coordinateList) {

		if (Core.isNullGeometry(geom)) return;
		if (coordinateList == null) return;

		if (geom instanceof LineString) {
			LineString line = (LineString) geom;

			coordinateList.add(line.getCoordinateN(0));
			coordinateList.add(line.getCoordinateN(line.getNumPoints() - 1));
		} else if (geom instanceof MultiLineString) {
			MultiLineString mls = (MultiLineString) geom;
			for (int i = 0; i < mls.getNumGeometries(); i++) {
				LineString line = (LineString) mls.getGeometryN(i);
				coordinateList.add(line.getCoordinateN(0));
				coordinateList.add(line.getCoordinateN(line.getNumPoints() - 1));
			}
		}
	}

	/*
	 * ========================================================================== =========== End of
	 * other functions ========================================
	 * ===============================================
	 */

	public static void copyFileFromURL(URL url, File fileTarget) {

		URLConnection urlC = null;
		try {
			urlC = url.openConnection();
		} catch (IOException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}

		// Copy resource to local file, use remote file
		// if no local file name specified
		InputStream is = null;
		try {
			is = url.openStream();
		} catch (IOException e2) {
			// TODO Auto-generated catch block
			e2.printStackTrace();
		}

		// Print info about resource
		System.out.print("Copying resource (type: " + urlC.getContentType());
		Date date = new Date(urlC.getLastModified());
		System.out.println(", modified on: " + date.toLocaleString() + ")...");
		System.out.flush();

		FileOutputStream fos = null;

		try {
			fos = new FileOutputStream(fileTarget);

		} catch (FileNotFoundException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}
		int oneChar, count = 0;

		try {
			while ((oneChar = is.read()) != -1) {
				fos.write(oneChar);
				count++;
			}
			is.close();
			fos.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		System.out.println(count + " byte(s) copied");
	}

	public static void copyShapeFile(String urlSource) {

		String fileName = null;

		URL url = null;
		try {
			url = new URL(urlSource);
			File a = new File(url.getFile());
			fileName = a.getName();

		} catch (MalformedURLException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}

		// Get the temporary directory
		String property = "java.io.tmpdir";
		String tempDir = System.getProperty(property);

		String targetName = tempDir + File.separator + fileName;

		File fileTarget = new File(targetName);

		copyFileFromURL(url, fileTarget);

	}

	/*
	 * =====================================================================================
	 * 
	 * JTS Manage geometry functions
	 * 
	 * 
	 * =======================================================================================
	 */

	public static Geometry removeGeometriesWithEmptyElements(Geometry geom)
			throws JASPAJTSException {

		if (Core.isNullGeometry(geom)) return null;

		ArrayList/*SGG<Geometry>*/ res = null;

		if (geom instanceof GeometryCollection) {
			int nGeometries = geom.getNumGeometries();
			if (nGeometries == 0) return null;
			int nNotNullGeometries = 0;

			boolean hasChanged = false;

			for (int i = 0; i < nGeometries; i++) {
				Geometry geom1 = geom.getGeometryN(i);
				Geometry geom0 = removeGeometriesWithEmptyElements(geom1);

				if (geom0 != geom1) {
					hasChanged = true;
				}

				if (geom0 != null && (!geom0.isEmpty())) {
					nNotNullGeometries++;
					if (res == null) {
						res = new ArrayList/*SGG<Geometry>*/(nGeometries);
					}
					res.add(geom0);
				}
			}

			if (nNotNullGeometries == 0) return null;
			if (!hasChanged) return geom;

			Geometry geomres = null;

			try {
				if (geom instanceof MultiLineString) {
					geomres = geom.getFactory().createMultiLineString(
							GeometryFactory.toLineStringArray(res));
				} else if (geom instanceof MultiPolygon) {
					geomres = geom.getFactory().createMultiPolygon(GeometryFactory.toPolygonArray(res));
				} else if (geom instanceof MultiPoint) {
					geomres = geom.getFactory().createMultiPoint(GeometryFactory.toPointArray(res));
				} else {
					geomres = geom.getFactory().createGeometryCollection(
							GeometryFactory.toGeometryArray(res));
				}
			} catch (RuntimeException e) {
				// Catch the runtime JTS Exceptions
				Core.manageJTSExceptions(e);
			}

			geomres.setSRID(geom.getSRID());
			return geomres;
		} else {
			if (geom.isEmpty()) return null;
			return geom;
		}
	}

	public static boolean setDimensionCoordinate(CoordinateSequence seq, int coorDimension) {

		if (seq == null || seq.size() == 0) return false;

		// Add size()==4?
		double firstZValue = seq.getOrdinate(0, CoordinateSequence.Z);
		if (!Double.isNaN(firstZValue)) {
			double firstMValue = seq.getOrdinate(0, CoordinateSequence.M);
			if (!Double.isNaN(firstMValue)) {
				// Dimension 4
				if (coorDimension == 2) { // dim 4 to dim 2
					seq.setOrdinate(0, CoordinateSequence.Z, Double.NaN);
					seq.setOrdinate(0, CoordinateSequence.M, Double.NaN);
					return true;
				}
				if (coorDimension == 3) { // dim 4 to dim 3
					seq.setOrdinate(0, CoordinateSequence.M, Double.NaN);
					return true;
				}

				// dim4 to dim 4
				return false;
			}

			// Dimension 3
			if (coorDimension == 2) { // dim 3 to dim 2
				seq.setOrdinate(0, CoordinateSequence.Z, Double.NaN);
				return true;
			}
			if (coorDimension == 4) { // dim 3 to dim 4
				for (int i = 0; i < seq.size(); i++) {
					// if (Double.isNaN(seq.getOrdinate(i,
					// CoordinateSequence.M)))
					seq.setOrdinate(i, CoordinateSequence.M, 0);
				}
				return true;
			}
			// dim 3 to dim 3
			return false;
		} else {
			// Dimension 2
			if (coorDimension == 3) { // dim 2 to dim 3
				for (int i = 0; i < seq.size(); i++) {
					// if (Double.isNaN(seq.getOrdinate(i,
					// CoordinateSequence.Z)))
					seq.setOrdinate(i, CoordinateSequence.Z, 0);
				}
				return true;
			}
			if (coorDimension == 4) { // dim 2 to dim 4
				for (int i = 0; i < seq.size(); i++) {
					// if (Double.isNaN(seq.getOrdinate(i,
					// CoordinateSequence.Z)))
					seq.setOrdinate(i, CoordinateSequence.Z, 0);
					// if (Double.isNaN(seq.getOrdinate(i,
					// CoordinateSequence.M)))
					seq.setOrdinate(i, CoordinateSequence.M, 0);
				}
				return true;
			}

			// dim 2 to dim 2
			return false;
		}

	}

	/**
	 * @param geom
	 *           Geometry from which we want to know the dimension number. Must be not null or empty.
	 * @return Number of dimension of the coordinates Calculate the number of dimension (XY=2,XYZ=3)
	 *         of the coordinates of the geometry Does not support M values. by jomarlla
	 */
	public static int calculateDimensionOfGeometryCoordinates(Geometry geom) {

		if (geom instanceof LineString) {
			CoordinateSequence seq = (((LineString) geom).getCoordinateSequence());
			return Core.calculateDimensionCoordinate(seq);
		} else if (geom instanceof Point) {
			CoordinateSequence seq = (((Point) geom).getCoordinateSequence());
			return Core.calculateDimensionCoordinate(seq);
		} else if (geom instanceof Polygon) {
			CoordinateSequence seq = ((Polygon) geom).getExteriorRing().getCoordinateSequence();
			return Core.calculateDimensionCoordinate(seq);
		} else if (geom instanceof GeometryCollection) { 
                        return calculateDimensionOfGeometryCoordinates(((GeometryCollection) geom).getGeometryN(0)); 
                }

		Assert.shouldNeverReachHere();

		return 0; // never reached
	}

	public static boolean setDimensionOfGeometryCoordinates(Geometry geom, int coorDimension) {

		if (geom instanceof LineString) {
			CoordinateSequence seq = (((LineString) geom).getCoordinateSequence());
			return setDimensionCoordinate(seq, coorDimension);
		}
		if (geom instanceof Point) {
			CoordinateSequence seq = (((Point) geom).getCoordinateSequence());
			return setDimensionCoordinate(seq, coorDimension);
		}
		if (geom instanceof Polygon) {
			CoordinateSequence seq = ((Polygon) geom).getExteriorRing().getCoordinateSequence();
			boolean res;

			res = setDimensionCoordinate(seq, coorDimension);

			Polygon pol = ((Polygon) geom);
			int nrings = pol.getNumInteriorRing();

			if (nrings > 0) {
				for (int i = 0; i < nrings; i++) {
					if (setDimensionCoordinate(pol.getInteriorRingN(i).getCoordinateSequence(),
							coorDimension)) {
						res = true;
					}
				}
			}
			return res;
		}

		if (geom instanceof GeometryCollection) {
			if (((GeometryCollection) geom).getNumGeometries() > 0) {

				GeometryCollection geomcol = ((GeometryCollection) geom);
				int nelements = geomcol.getNumGeometries();

				boolean res = false;
				for (int i = 0; i < nelements; i++) {
					if (setDimensionOfGeometryCoordinates(geomcol.getGeometryN(i), coorDimension)) {
						res = true;
					}

				}
				return res;
			}
		}

		return false;
	}

	public static int calculateDimensionCoordinate(CoordinateSequence seq) {

		if (seq == null || seq.size() == 0) return 0;
		// Add size()==4?
		double firstZValue = seq.getOrdinate(0, CoordinateSequence.Z);
		if (!Double.isNaN(firstZValue)) {
			double firstMValue = seq.getOrdinate(0, CoordinateSequence.M);
			if (!Double.isNaN(firstMValue)) return 4;
			return 3;
		}

		return 2;
	}

	/*
	 * ===================================================================================== End of
	 * JTS Manage geometry functions
	 * =======================================================================================
	 */

	/*
	 * ===================================================================================== End of
	 * sgeom to geom, array and list converters and utils
	 * =======================================================================================
	 */

	//Generic to remove nulls entries in an array
	//makes a new array if it is necessary
	//It can be used to check arrays of geometries, arrays of coordinates
	//arrays of binary geometries byte[][], etc.
	public static /*SGG<U>*/ Object[] removeNulls(Object array[]) {

		int size = array.length;
		int nNulls = 0;
		for (int i = 0; i < size; i++)
			if (array[i] == null) {
				nNulls++;
			}
		return removeNulls(array, nNulls);
	}
		
	// SGG @SuppressWarnings("unchecked")
	private static Object[] removeNulls(Object[] array,
                                            int nNulls,
                                            Class/*SGG<? extends Object[]>*/ newType) 
        {
            if (nNulls == 0) return array;
            int size = array.length;
            if (size - nNulls == 0) return null;
            
            Object newArray[] = (Object[]) Array.newInstance(newType.getComponentType(), size - nNulls);
            
            int j = 0;
            for (int i = 0; i < size; i++) {
                if (array[i] != null) {
                    newArray[j++] = array[i];
                }
            }
            return newArray;
	}

	// SGG @SuppressWarnings("unchecked")
	public static Object[] removeNulls(Object[] array, 
                                           int nNulls) 
        {
		return (Object[]) removeNulls(array, nNulls, array.getClass());
	}
	

	// SGG @SuppressWarnings("unchecked")
	public static Object[] removeNullOrEmptyGeometries(Object[] array, int nNulls) {
		return (Object[]) removeNullOrEmptyGeometries(array, nNulls, array.getClass());
	}
	
	public static Object[] removeNullOrEmptyGeometries(Object array[]) {
		int size = array.length;
		int nNulls = 0;
		for (int i = 0; i < size; i++)
			if ((array[i] == null) || ((Geometry) array[i]).isEmpty()) {
				nNulls++;
			}
		return removeNullOrEmptyGeometries(array, nNulls);
	}
	
	// SGG @SuppressWarnings("unchecked")
	private static Object[] removeNullOrEmptyGeometries(Object[] array,
                                                            int nNulls,
                                                            Class/*SGG<? extends Object[]>*/ newType) {

		if (nNulls == 0) return array;
		int size = array.length;
		if (size - nNulls == 0) return null;

		Object newArray[] = (Object[]) Array.newInstance(newType.getComponentType(), size - nNulls);

		int j = 0;
		for (int i = 0; i < size; i++) {
			if ((array[i] != null) && (!((Geometry) array[i]).isEmpty())) {
				newArray[j++] = array[i];
			}
		}

		return newArray;
	}
	

	//---------------------------------------
	//Convert from/to a list from/to an array
	//---------------------------------------
	//usage:
	//Coordinate[] coors = ...
	//List<Coordinate> coorsList = array2List (coors);
        /*
	public static <U> List<U> array2List(Object[] array) {

		//This conversion is really fast because it just changes the pointer
		return Arrays.asList(array);
	}
        */

	//usage:
	//List/*SGG<Geometry>*/ geomList =...
	//Geometry[] geomArray = list2Array (geomList, new Geometry[]{});
	//usage: 
	//List <Point> point =...
	//Point[] pointArray = geomList2geomArray (point, new Point[]{});
	//usage:
	//List/*SGG<byte[]>*/ sgeomList = ...
	//byte sgeomArray[][] = Core.list2Array(sgeomList, new byte[][]{});
	//usage: this is allow too
	//List/*SGG<Geometry>*/ geometries = new ArrayList/*SGG<Geometry>*/();
	//fill the list with Point instances
	//factory.createMultiPoint((Point[]) Core.list2Array(geometries, new Point[]{}));}
        
        public static Object[] list2Array(List list, Object[] array) {
            //Use the method toArray which copy the array using java native methods
            return list.toArray(array);
        }
        
/** SGG
	public static Object[] list2Array(List<U> list, Object[] array) {

		//Use the method toArray which copy the array using java native methods
		return list.toArray(array);
	}
**/
	//without generics
	public static List/*SGG<Geometry>*/ geomArray2geomList (Geometry[] geometry) {
		//This conversion is really fast because it just changes the pointer
		return Arrays.asList(geometry);
	}

	//Use array2List instead
	public static List/*SGG<byte[]>*/ gblobArray2gblobList(byte[][] gblob) {

		//This conversion is really fast because it just changes the pointer
		return Arrays.asList(gblob);
	}

	//Use list2array instead
	public static byte[][] gblobList2gblobArray(List/*SGG<byte[]>*/ gblob) {

		//Use the method toArray which copy the array using java native methods
		return (byte[][])gblob.toArray(new byte[][] {});
	}

	//---------------------------------------
	//Convert from/to a list from/to an array
	//---------------------------------------

	//convert jts goemetry objects to serialized geometries, remove nulls and empty geometries
	public static byte[][] geomList2gblobArray(List/*SGG<Geometry>*/ geomList)
			throws JASPAGeomParseException {

		if (geomList == null) return null;

		int size = geomList.size();
		if (size == 0) return null;

		byte gblobArray[][] = new byte[size][];

		int nNulls = 0;
		int n = 0;
                /** SGG 
		for (Geometry geom : geomList) {
			gblobArray[n] = Core.getGBLOBFromJTSGeometry(geom);
			if (gblobArray[n++] == null) nNulls++;
		}
                **/
                Geometry geom = null;
                Iterator geomIter = geomList.iterator();
                while (geomIter.hasNext()) {
                    geom = (Geometry)geomIter.next();
                    gblobArray[n] = Core.getGBLOBFromJTSGeometry(geom);
                    if (gblobArray[n++] == null) nNulls++;
                }

		gblobArray = (byte[][])Core.removeNulls(gblobArray, nNulls);

		return gblobArray;
	}

	//convert jts goemetry objects to serialized geometries, remove nulls and empty geometries
	public static List/*SGG<byte[]>*/ geomList2gblobList(List/*SGG<Geometry>*/ geomList)
			throws JASPAGeomParseException {

		/*SGG return array2List(geomList2gblobArray(geomList));*/
                return Arrays.asList((byte[][])geomList2gblobArray(geomList));
	}

	//convert jts goemetry objects to serialized geometries, remove nulls and empty geometries
	public static byte[][] geomArray2gblobArray(Geometry[] geomArray)
			throws JASPAGeomParseException {

		return geomList2gblobArray(Arrays.asList(geomArray));
	}

	//convert jts goemetry objects to serialized geometries, remove nulls and empty geometries
	public static List/*SGG<byte[]>*/ geomArray2gblobList(Geometry[] geomArray)
			throws JASPAGeomParseException {

		return Arrays.asList(geomArray2gblobArray(geomArray));
	}

	//convert to geometry jts objects, remove nulls and empty geometries
	public static List/*SGG<Geometry>*/ gblobArray2geomList(byte[][] gblobArray)
			throws JASPAGeomParseException, JASPAIllegalArgumentException {
		return Arrays.asList(gblobArray2geomArray(gblobArray));
	}

	//convert to geometry jts objects, remove nulls and empty geometries
	/**
	 * Convert serialized geometries to jts object geometries.
	 * Remove null entries or empty geometries from the output array.
	 * @param gblobArray Array of serialized geometries
	 * @return Array of geometry objects
	 * @throws JASPAGeomParseException
	 * @throws JASPAIllegalArgumentException 
	 */
	public static Geometry[] gblobArray2geomArray(byte[][] gblobArray)
			throws JASPAGeomParseException, JASPAIllegalArgumentException {

		return gblobList2geomArray(Arrays.asList(gblobArray));
	}

	//convert to geometry jts objects, remove nulls and empty geometries
	// SGG @SuppressWarnings("unchecked")
	public static Object[] gblobArray2geomArray(byte[][] gblobArray, Object[] geom)
			throws JASPAGeomParseException, JASPAIllegalArgumentException {

		return (Object[]) gblobList2geomArray(Arrays.asList(gblobArray), geom.getClass());
	}

	//convert to geometry jts objects, remove nulls and empty geometries
	public static List/*SGG<Geometry>*/ gblobList2geomList(List/*SGG<byte[]>*/ gblobList)
			throws JASPAGeomParseException, JASPAIllegalArgumentException {

		return Arrays.asList(gblobList2geomArray(gblobList));
	}

	//convert to geometry jts objects, remove nulls and empty geometries
	// SGG @SuppressWarnings("unchecked")
	public static List/*SGG<U>*/ gblobList2geomList(List/*SGG<byte[]>*/ gblobList, Object[] geom)
			throws JASPAGeomParseException, JASPAIllegalArgumentException {

		return Arrays.asList(gblobList2geomArray(gblobList, geom.getClass()));
	}

	//convert to geometry jts objects, remove nulls and empty geometries
	public static Geometry[] gblobList2geomArray(List/*SGG<byte[]>*/ gblobList)
			throws JASPAGeomParseException, JASPAIllegalArgumentException {

		return (Geometry[])gblobList2geomArray(gblobList, new Geometry[] {});
	}

	//convert to geometry jts objects, remove nulls and empty geometries
	// SGG @SuppressWarnings("unchecked")
	public static Object[] gblobList2geomArray(List/*SGG<byte[]>*/ gblobList, 
                                                  Object[] geom)
			throws JASPAGeomParseException, JASPAIllegalArgumentException {

		return (Geometry[]) gblobList2geomArray(gblobList, geom.getClass());
	}

	//convert to geometry jts objects, remove nulls and empty geometries
	//e.g.: Geometry geom[] = Core.gblobList2geomArray (sgeomList, new Point[]{});
	// SGG @SuppressWarnings("unchecked")
	public static Object[] gblobList2geomArray(List/*SGG<byte[]>*/ gblobList, 
                                                  Class/*SGG <? extends Object[]>*/ geomType)
			throws JASPAGeomParseException, JASPAIllegalArgumentException {

		if (gblobList == null) return null;

		int size = gblobList.size();
		if (size == 0) return null;

		Object newArray[] = (Object[]) Array.newInstance(geomType.getComponentType(), size);

		int nNulls = 0;
		int n = 0;
	        Geometry geom = null;
                Iterator gblobIter = gblobList.iterator();
                while (gblobIter.hasNext() ) /*SGG for (byte[] gblob : gblobList) */ {
			geom = (Geometry)Core.getJTSGeometryFromGBLOB((byte[])gblobIter.next());
			if (geom != null) {
				if (geomType.getComponentType().isInstance(geom)) {
					newArray[n++] = (Geometry) geom;
				} else
					throw new JASPAIllegalArgumentException("unexpected geometry type");
			} else
				nNulls++;
		}

		newArray = Core.removeNulls(newArray, nNulls);

		return newArray;
	}
	
	//Some SGBD like H2 

	/*
	 * ===================================================================================== End of
	 * sgeom to geom, array and list converters
	 * =======================================================================================
	 */

	/*
	 * ===================================================================================== End of
	 * JTS Manage geometry functions
	 * =======================================================================================
	 */

	public static void checkIfDatabaseSupportTopologyRules()
			throws JASPAIllegalArgumentException {

		switch (Core.getDB()) {
		case Core.dbPostgreSQL:
			return;

		default:
			throw new JASPAIllegalArgumentException(
					"The database implementation does not support topology rules");
		}
	}
		
	public static int getDB () {
		return Core.jaspa4db;
	}
	
	//This method has to be called just when the client is an external JDBC connection
	public static void setDB (int jaspaDBType) throws JASPAIllegalArgumentException {
		if (jaspaDBType == Core.dbH2 || jaspaDBType == Core.dbPostgreSQL) {
			Core.jaspa4db = jaspaDBType;
		}
		else throw new JASPAIllegalArgumentException ("database not supported");
	}	
}
