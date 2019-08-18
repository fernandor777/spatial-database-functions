/*
 * Created on aug-2009
 *
 * JASPA. JAva SPAtial for SQL.
 * 
 * Copyright (C) 2009 Jose Martinez-Llario. 
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
 *   http://cartosig.upv.es
 *   
 * Acknowledge:
 * 
 * JASPA is based on other projects which I want to say thanks to:
 * - PostGIS. http://postgis.refractions.net/
 * - Java Topology Suite (JTS). http://sourceforge.net/projects/jts-topo-suite/
 * - GeoTools. http://www.geotools.org/
 * - H2 and H2 Spatial (small spatial extension for H2) 
 *   http://www.h2database.com
 *   http://geoserver.org/display/GEOS/H2+Spatial+Database 
 * - PL/Java. http://pgfoundry.org/projects/pljava/
 * - PostgreSQL. http://www.postgresql.org/
 * 
 */

/*
 * The JTS Topology Suite is a collection of Java classes that
 * implement the fundamental operations required to validate a given
 * geo-spatial data set to a known topological specification.
 *
 * Copyright (C) 2001 Vivid Solutions
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * For more information, contact:
 *
 *     Vivid Solutions
 *     Suite #1A
 *     2328 Government Street
 *     Victoria BC  V8T 5G5
 *     Canada
 *
 *     (250)385-6040
 *     www.vividsolutions.com
 */

package es.upv.jaspa.io;

import java.io.IOException;


import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.CoordinateSequence;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryCollection;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.LinearRing;
import org.locationtech.jts.geom.MultiLineString;
import org.locationtech.jts.geom.MultiPoint;
import org.locationtech.jts.geom.MultiPolygon;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.Polygon;
import org.locationtech.jts.io.WKBWriter;
import org.locationtech.jts.util.Assert;

import es.upv.jaspa.Core;
import es.upv.jaspa.exceptions.JASPAGeomParseException;

/**
 * 
 * @author JTS, Jose Martinez-Llario
 * 
 *         This class is based on the class WKBReader from JTS This class has been modified by
 *         jomarlla
 * @see WKBWriter jomarlla: Changes to JTS source code: Reads embedded SRID (EWKB Format) or without
 *      SRID (WKB Format) Read PostGIS format with and without embedded SRID Read JASPA format with
 *      and without embedded SRID JASPA format without SRID and XY, XYZ, XYZM coordinates IS OGC
 *      compliance JASPA format without SRID and XY coordinates IS OGC compliance Use an array of
 *      bytes instead a stream to increase the performance
 * 
 *      WKBWriter can not write XYM coordinates so WKBReader can not read XYM coordinates either
 * 
 *      The class has now all its methods statics using stack memory instead heap memory so the
 *      variables SRID, inputDimension and dis are passed as method arguments.
 * 
 *      In geometrycollections and multi geometries the factory used for the first geometry is the
 *      one used for all the sub-geometries.
 * 
 */

public class GBLOB2JTS {
	private static final String INVALID_GEOM_TYPE_MSG = "Invalid geometry type encountered in ";

	/*
	 * =====================================================================================
	 * Singleton
	 * =======================================================================================
	 */
	public static GBLOB2JTS instance() {

		return INSTANCE;
	}

	private static final GBLOB2JTS INSTANCE = new GBLOB2JTS();

	private GBLOB2JTS() {

	}

	/*
	 * ===================================================================================== End of
	 * Singleton
	 * =======================================================================================
	 */

	/**
	 * Converts a hexadecimal string to a byte array.
	 * 
	 * @param hex
	 *           a string containing hex digits
	 */
	public static byte[] hexToBytes(String hex) {

		int byteLen = hex.length() / 2;
		byte[] bytes = new byte[byteLen];

		for (int i = 0; i < hex.length() / 2; i++) {
			int i2 = 2 * i;
			if (i2 + 1 > hex.length())
				throw new IllegalArgumentException("Hex string has odd length");

			int nib1 = hexToInt(hex.charAt(i2));
			int nib0 = hexToInt(hex.charAt(i2 + 1));
			byte b = (byte) ((nib1 << 4) + (byte) nib0);
			bytes[i] = b;
		}
		return bytes;
	}

	private static int hexToInt(char hex) {

		int nib = Character.digit(hex, 16);
		if (nib < 0) throw new IllegalArgumentException("Invalid hex digit: '" + hex + "'");
		return nib;
	}

	/**
		 * Reads a {@link Geometry} from an {@link InStream).
		 * 
		 * @param is
		 *            the stream to read from
		 * @return the Geometry read
		 * @throws IOException
		 * @throws JASPAGeomParseException
		 */
	public Geometry read(byte[] bytes)
			throws JASPAGeomParseException {

		return read(bytes, null);
	}

	public Geometry read(byte[] bytes, int geomInfo[])
			throws JASPAGeomParseException {

		ByteOrderValues dis;
		dis = new ByteOrderValues(bytes);

		Geometry g;
		int SRID = BinaryFormat.defaultSRID;
		;
		int inputDimension = 2;

		try {
			// First byte: byte order, isjaspaversion
			boolean isJASPABinaryFormat = dis.readByteOrder();

			int version = -1;

			if (isJASPABinaryFormat) {
				// Second byte: jaspa binary version, isvectorial or raster format
				int value = dis.getByte();
				version = value & 0x1F;
				boolean isVectorialFormat = ((value & 0x20) != 0);
				if (!isVectorialFormat) {
					Assert.shouldNeverReachHere("Raster format not supported");
				}

				if (version == 0) {
					// Third byte: hasEmbedded SRID, hasZ, hasM
					value = dis.getByte();
					boolean isEmbeddedSRID = (value & 0x80) != 0;
					if ((value & 0x01) != 0) inputDimension = 3;
					if ((value & 0x02) != 0) inputDimension = 4;
					// Does not support XYM

					if (isEmbeddedSRID) SRID = dis.getInt();

					// If geomInfo is not null then just some information about the geometry is requested
					// so it not necessary to parse the whole geometry
					if (geomInfo != null) {
						geomInfo[0] = SRID;
						geomInfo[1] = inputDimension;
					}
				} else
					Assert.shouldNeverReachHere("Unknow jaspa binary format");
			} else
				dis.pushByte();

			g = readGeometry(dis, null, version, SRID, inputDimension, geomInfo);

		} catch (IllegalArgumentException e) {
			// RunTimeException throws by JTS Geometry Factories
			throw new JASPAGeomParseException(e);
		}
		return g;
	}

	private Geometry readGeometry(
			ByteOrderValues dis, GeometryFactory factory, int version, int SRID, int inputDimension)
			throws JASPAGeomParseException {

		return readGeometry(dis, factory, version, SRID, inputDimension, null);
	}

	private Geometry readGeometry(
			ByteOrderValues dis, GeometryFactory factory, int version, int SRID, int inputDimension,
			int geomInfo[])
			throws JASPAGeomParseException {

		int geometryType = 0;
		int typeInt;

		// JASPA binary format
		if (version >= 0) {
			if (version == 0) {
				geometryType = dis.getByte();

				// If geomInfo is not null then just some information about the geometry is requested
				// so it not necessary to parse the whole geometry
				if (geomInfo != null) {
					geomInfo[2] = geometryType;
					return null;
				}
			} else {
				Assert.shouldNeverReachHere("Unknow jaspa binary format");
			}
		}
		// This is WKB or EWKB (PostGIS) formats
		else {

			dis.readByteOrder();

			typeInt = dis.getInt();

			boolean isEmbeddedSRID = false;
			SRID = BinaryFormat.defaultSRID;

			geometryType = typeInt & 0x1FFFFFFF;

			boolean haveZ = (typeInt & 0x80000000) != 0;
			boolean haveM = (typeInt & 0x40000000) != 0;
			boolean haveS = (typeInt & 0x20000000) != 0;

			if (haveZ && (!haveM)) {
				// XYZ coordinates
				inputDimension = 3;
			}
			if (haveZ && haveM) {
				// XYZM coordinates
				inputDimension = 4;
			}
			if ((!haveZ) && (!haveM)) {
				// XY coordinates
				inputDimension = 2;
			}
			if ((!haveZ) && (haveM)) {
				// XYM coordinates are not implemented in JTS and WKBReader can
				// not read it either
				inputDimension = 3;
				throw new JASPAGeomParseException("XYM coordinates are not implemented in JASPA");
			}

			if (haveS) {
				isEmbeddedSRID = true;
			} else {
				isEmbeddedSRID = false;
			}

			if (isEmbeddedSRID) {
				SRID = dis.getInt();
			} else {
				// Default value for SRID
				// SRID = -1 in PostGIS
				SRID = BinaryFormat.defaultSRID;
			}

			// If geomInfo is not null then just some information about the geometry is requested
			// so it not necessary to parse the whole geometry
			if (geomInfo != null) {
				geomInfo[0] = SRID;
				geomInfo[1] = inputDimension;
				geomInfo[2] = geometryType;
				return null;
			}
		}

		if (factory == null) factory = Core.getInstanceGeometryFactory(SRID);

		switch (geometryType) {
		case BinaryFormat.wkbPoint:
			return readPoint(dis, inputDimension, factory, version);
		case BinaryFormat.wkbLineString:
			return readLineString(dis, inputDimension, factory, version);
		case BinaryFormat.wkbPolygon:
			return readPolygon(dis, inputDimension, factory, version);
		case BinaryFormat.wkbMultiPoint:
			return readMultiPoint(dis, inputDimension, factory, version, SRID);
		case BinaryFormat.wkbMultiLineString:
			return readMultiLineString(dis, inputDimension, factory, version, SRID);
		case BinaryFormat.wkbMultiPolygon:
			return readMultiPolygon(dis, inputDimension, factory, version, SRID);
		case BinaryFormat.wkbGeometryCollection:
			return readGeometryCollection(dis, inputDimension, factory, version, SRID);
		}
		throw new JASPAGeomParseException("Unknown WKB type " + geometryType);
	}

	/**
	 * Sets the SRID, if it was specified in the WKB
	 * 
	 * @param g
	 *           the geometry to update
	 * @return the geometry with an updated SRID value, if required
	 */
	private Geometry setSRID(Geometry g, int SRID) {

		// PostGIS Default SRID
		// if (SRID == -1) SRID = 0;
		g.setSRID(SRID);

		return g;
	}

	private Point readPoint(
			ByteOrderValues dis, int inputDimension, GeometryFactory factory, int version) {

		Coordinate coor = readCoordinate(dis, inputDimension, factory);
		return factory.createPoint(coor);
	}

	private LineString readLineString(
			ByteOrderValues dis, int inputDimension, GeometryFactory factory, int version) {

		int size = dis.getInt();
		CoordinateSequence pts = readCoordinateSequence(size, dis, inputDimension, factory);
		return factory.createLineString(pts);
	}

	private LinearRing readLinearRing(
			ByteOrderValues dis, int inputDimension, GeometryFactory factory, int version) {

		int size = dis.getInt();
		CoordinateSequence pts = readCoordinateSequence(size, dis, inputDimension, factory);
		return factory.createLinearRing(pts);
	}

	private Polygon readPolygon(
			ByteOrderValues dis, int inputDimension, GeometryFactory factory, int version) {

		int numRings = dis.getInt();
		LinearRing[] holes = null;
		if (numRings > 1) {
			holes = new LinearRing[numRings - 1];
		}

		LinearRing shell = readLinearRing(dis, inputDimension, factory, version);

		for (int i = 0; i < numRings - 1; i++) {
			holes[i] = readLinearRing(dis, inputDimension, factory, version);
		}
		return factory.createPolygon(shell, holes);
	}

	private MultiPoint readMultiPoint(
			ByteOrderValues dis, int inputDimension, GeometryFactory factory, int version, int SRID)
			throws JASPAGeomParseException {

		int numGeom = dis.getInt();
		Point[] geoms = new Point[numGeom];
		for (int i = 0; i < numGeom; i++) {
			Geometry g = readGeometry(dis, factory, version, SRID, inputDimension);
			if (!(g instanceof Point))
				throw new JASPAGeomParseException(INVALID_GEOM_TYPE_MSG + "MultiPoint");
			geoms[i] = (Point) g;
		}
		return factory.createMultiPoint(geoms);
	}

	private MultiLineString readMultiLineString(
			ByteOrderValues dis, int inputDimension, GeometryFactory factory, int version, int SRID)
			throws JASPAGeomParseException {

		int numGeom = dis.getInt();
		LineString[] geoms = new LineString[numGeom];
		for (int i = 0; i < numGeom; i++) {
			Geometry g = readGeometry(dis, factory, version, SRID, inputDimension);
			if (!(g instanceof LineString))
				throw new JASPAGeomParseException(INVALID_GEOM_TYPE_MSG + "MultiLineString");
			geoms[i] = (LineString) g;
		}
		return factory.createMultiLineString(geoms);
	}

	private MultiPolygon readMultiPolygon(
			ByteOrderValues dis, int inputDimension, GeometryFactory factory, int version, int SRID)
			throws JASPAGeomParseException {

		int numGeom = dis.getInt();
		Polygon[] geoms = new Polygon[numGeom];
		for (int i = 0; i < numGeom; i++) {
			Geometry g = readGeometry(dis, factory, version, SRID, inputDimension);
			if (!(g instanceof Polygon))
				throw new JASPAGeomParseException(INVALID_GEOM_TYPE_MSG + "MultiPolygon");
			geoms[i] = (Polygon) g;
		}
		return factory.createMultiPolygon(geoms);
	}

	private GeometryCollection readGeometryCollection(
			ByteOrderValues dis, int inputDimension, GeometryFactory factory, int version, int SRID)
			throws JASPAGeomParseException {

		int numGeom = dis.getInt();
		Geometry[] geoms = new Geometry[numGeom];
		for (int i = 0; i < numGeom; i++) {
			geoms[i] = readGeometry(dis, factory, version, SRID, inputDimension);
		}
		return factory.createGeometryCollection(geoms);
	}

	private CoordinateSequence readCoordinateSequence(
			int size, ByteOrderValues dis, int inputDimension, GeometryFactory factory) {

		CoordinateSequence seq = factory.getCoordinateSequenceFactory().create(size, inputDimension);

		for (int i = 0; i < size; i++) {
			for (int j = 0; j < inputDimension; j++) {
				seq.setOrdinate(i, j, dis.getDouble());
				// Precision model is not used yet
				// It spends 20% of runtime . Add up when a precision system is
				// used.
				// seq.setOrdinate(i, j,
				// factory.getPrecisionModel().makePrecise(dis.getDouble()));
			}
		}

		return seq;
	}

	private Coordinate readCoordinate(
			ByteOrderValues dis, int inputDimension, GeometryFactory factory) {

		Coordinate res = null;

		double x = dis.getDouble();
		double y = dis.getDouble();
		if (inputDimension == 2) {
			res = new Coordinate(x, y);
		} else {
			double z = dis.getDouble();

			if (inputDimension == 3) {
				res = new Coordinate(x, y, z);
			} else {
				double m = dis.getDouble();
				res = new Coordinate(x, y, z, m);
			}
			// Precision model is not used yet
			// It spends 20% of runtime . Add up when a precision system is
			// used.
			// seq.setOrdinate(i, j,
			// factory.getPrecisionModel().makePrecise(dis.getDouble()));
		}

		return res;
	}

}