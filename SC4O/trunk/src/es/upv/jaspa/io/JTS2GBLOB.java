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
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.MultiLineString;
import org.locationtech.jts.geom.MultiPoint;
import org.locationtech.jts.geom.MultiPolygon;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.Polygon;
import org.locationtech.jts.io.OutStream;
import org.locationtech.jts.io.WKBReader;
import org.locationtech.jts.util.Assert;

import es.upv.jaspa.Core;
import es.upv.jaspa.exceptions.JASPAGeomParseException;
import es.upv.jaspa.exceptions.JASPAIllegalArgumentException;
import es.upv.jaspa.exceptions.JASPAJTSException;

/**
 * 
 * @author JTS, Jose Martinez-Llario
 * 
 *         This class is based on the class WKBReaderFast from JTS This class has been modified by
 *         jomarlla
 * 
 *         This class is threadsafe
 * 
 *         JASPA extensions: M coordinate Remove empty geometries Embedded SRID Using arrays instead
 *         streams (twice faster) Estimate the size of the binary array Remove instance variables
 *         and pass them by method arguments (in order to use static classes)
 * 
 * @see WKBReader
 */
public class JTS2GBLOB {

	private final byte byteOrder;

	/*
	 * =====================================================================================
	 * Singleton
	 * =======================================================================================
	 */
	public static JTS2GBLOB instance(int byteOrder) {

		if (byteOrder == ByteOrderValues.LITTLE_ENDIAN) return INSTANCE_LITTLE_ENDIAN;
		return INSTANCE_BIG_ENDIAN;
	}

	public static JTS2GBLOB instance() {

		if (BinaryFormat.defaultByteOrder == ByteOrderValues.LITTLE_ENDIAN)
			return INSTANCE_LITTLE_ENDIAN;
		return INSTANCE_BIG_ENDIAN;
	}

	private static final JTS2GBLOB INSTANCE_LITTLE_ENDIAN = new JTS2GBLOB(
			ByteOrderValues.LITTLE_ENDIAN);
	private static final JTS2GBLOB INSTANCE_BIG_ENDIAN = new JTS2GBLOB(ByteOrderValues.BIG_ENDIAN);

	private JTS2GBLOB() {

		this(BinaryFormat.defaultByteOrder);
	}

	private JTS2GBLOB(int byteOrder) {

		this.byteOrder = (byte) byteOrder;
	}

	/*
	 * ===================================================================================== End of
	 * Singleton
	 * =======================================================================================
	 */

	public static String bytesToHex(byte[] bytes)
			throws JASPAIllegalArgumentException {

		StringBuffer buf = new StringBuffer();
		for (int i = 0; i < bytes.length; i++) {
			byte b = bytes[i];
			buf.append(toHexDigit((b >> 4) & 0x0F));
			buf.append(toHexDigit(b & 0x0F));
		}
		return buf.toString();
	}

	private static char toHexDigit(int n)
			throws JASPAIllegalArgumentException {

		if (n < 0 || n > 15)
			throw new JASPAIllegalArgumentException("Nibble value out of range: " + n);
		if (n <= 9) return (char) ('0' + n);
		return (char) ('A' + (n - 10));
	}

	// By default the writer will write the default version of the jaspa vectorial format
	// To write another version use:
	// write (geom, WKBConstants.wkbJASPAVectorialVersionStartAt + num)
	// where num is an integer between 0 and 50 specifying the jaspa version
	public byte[] write(Geometry geom)
			throws JASPAGeomParseException {

		return write(geom, BinaryFormat.wkbJASPAFormatVectorial,
				BinaryFormat.wkbJASPADefaultFormatVectorial);
	}

	public byte[] write(Geometry geom, int formatType)
			throws JASPAGeomParseException {

		return write(geom, formatType, 0);
	}

	/**
	 * Writes a {@link Geometry} into a byte array.
	 * 
	 * @param geom
	 *           the geometry to write
	 * @return the byte array containing the WKB
	 * @throws JASPAGeomParseException
	 * @throws JASPAJTSException
	 */
	public byte[] write(Geometry geom, int formatType, int formatVersion)
			throws JASPAGeomParseException {

		if (Core.isEmptyOrNullGeometry(geom)) return null;

		try {
			geom = Core.removeGeometriesWithEmptyElements(geom);
		} catch (JASPAJTSException e) {
			throw new JASPAGeomParseException(e);
		}

		byte[] sgeom;

		/*
		 * The SRID from the parent geometry is the one used to write the WKB of all the srid of the
		 * sublements (Geometrycollections)
		 */

		int SRID = BinaryFormat.defaultSRID;
		boolean isEmbeddedSRID = BinaryFormat.isEmbeddedSRID(geom.getSRID(), formatType);
		if (isEmbeddedSRID) {
			SRID = geom.getSRID();
		}

		/*
		 * The coodinate dimension from the parent geometry is the one used to write the WKB of all
		 * the dimension coordinates of the sublements (Geometrycollections)
		 */

		int dimensionOfCS = Core.calculateDimensionOfGeometryCoordinates(geom);

		int size = 0;
		if (BinaryFormat.isJASPABinaryFormat(formatType)) {
			if (formatVersion == 0) {
				size = 1 + // byteorder + isJASPABinaryFormat
				1 + // jaspa version format + RasterOrVectorial
				1; // hasz, hasm, hassrid

				if (isEmbeddedSRID) size += 4; // SRID
				size = getSize(geom, dimensionOfCS, size, SRID, formatType);
			} else
				Assert.shouldNeverReachHere();
		} else {
			size = getSize(geom, dimensionOfCS, 0, SRID, -formatType);
		}

		sgeom = new byte[size];

		ByteOrderValues dis = new ByteOrderValues(sgeom);
		dis.setByteOrder(this.byteOrder);

		if (BinaryFormat.isJASPABinaryFormat(formatType)) {
			// FIRST BYTE
			// Write byte order
			// bit 4 marks if it is jaspa binary format
			dis.putByte((byte) (byteOrder | 0x08));

			// Will write the SRID and the PRECISON, and the byteorder information
			// just one for each geometry

			// SECOND BYTE
			// Write the JASPA binary version
			int build = formatVersion | 0x20; // bit 5 marks vectorial format (1 vectorial 0 raster)
			dis.putByte((byte) build);

			// JASPA VECTORIAL FORMAT: VERSION 0
			if (formatVersion == 0) {
				// THIRD BYTE
				// Write if the geometry hasz, hasm and hassrid

				build = 0;
				// bit 7 marks if thereis SRID information (0 no information 1 there is information)
				if (isEmbeddedSRID) build |= 0x80;
				// bit 0 marks if the geom has z (1 has 0 hasnt)
				if (dimensionOfCS == 3) build |= 0x01;
				// bit 1 marks if the geom has m (1 has 0 hasnt)
				if (dimensionOfCS == 4) build |= 0x03; // XYM not supported
				dis.putByte((byte) build);

				// WRITE SRID
				if (isEmbeddedSRID) dis.putInt(SRID);
				write(geom, dis, dimensionOfCS, SRID, formatVersion);
			} else {
				Assert.shouldNeverReachHere("Unknow jaspa binary format");
			}
			// WKB or EWKB formats
		} else {
			// formatype < 0 means it is not jaspa binary format, so it will be wkb or ewkb format
			write(geom, dis, dimensionOfCS, SRID, -formatType);
		}

		if (dis.getIndex() != size) {
			Assert.shouldNeverReachHere();
		}

		return sgeom;
	}

	/**
	 * Writes a {@link Geometry} to an {@link OutStream}.
	 * 
	 * @param geom
	 *           the geometry to write
	 * @param dis
	 *           the out stream to write to
	 * @throws JASPAGeomParseException
	 * @throws IOException
	 *            if an I/O error occurs
	 */
	private void write(Geometry geom, ByteOrderValues dis, int dimensionOfCS, int SRID, int format)
			throws JASPAGeomParseException {

		if (geom instanceof Point) {
			writePoint((Point) geom, dis, dimensionOfCS, SRID, format);
		} else if (geom instanceof LineString) {
			writeLineString((LineString) geom, dis, dimensionOfCS, SRID, format);
		} else if (geom instanceof Polygon) {
			writePolygon((Polygon) geom, dis, dimensionOfCS, SRID, format);
		} else if (geom instanceof MultiPoint) {
			writeGeometryCollection(BinaryFormat.wkbMultiPoint, (MultiPoint) geom, dis, dimensionOfCS,
					SRID, format);
		} else if (geom instanceof MultiLineString) {
			writeGeometryCollection(BinaryFormat.wkbMultiLineString, (MultiLineString) geom, dis,
					dimensionOfCS, SRID, format);
		} else if (geom instanceof MultiPolygon) {
			writeGeometryCollection(BinaryFormat.wkbMultiPolygon, (MultiPolygon) geom, dis,
					dimensionOfCS, SRID, format);
		} else if (geom instanceof GeometryCollection) {
			writeGeometryCollection(BinaryFormat.wkbGeometryCollection, (GeometryCollection) geom,
					dis, dimensionOfCS, SRID, format);
		} else {
			// Assert.shouldNeverReachHere("Unknown Geometry type");
			throw new JASPAGeomParseException("Unknown JTS Geometry type " + geom.getClass().getName());
		}
	}

	private int getSize(Geometry geom, int dimensionOfCS, int size, int SRID, int format)
			throws JASPAGeomParseException {

		if (geom instanceof Point) {
			size = getPointSize((Point) geom, dimensionOfCS, size, SRID, format);
		} else if (geom instanceof LineString) {
			size = getLineStringSize((LineString) geom, dimensionOfCS, size, SRID, format);
		} else if (geom instanceof Polygon) {
			size = getPolygonSize((Polygon) geom, dimensionOfCS, size, SRID, format);
		} else if (geom instanceof GeometryCollection) {
			size = getGeometryCollectionSize((GeometryCollection) geom, dimensionOfCS, size, SRID,
					format);
		} else {
			throw new JASPAGeomParseException("Unknown JTS Geometry type" + geom.getClass().getName());
			// Assert.shouldNeverReachHere("Unknown Geometry type");
		}

		return size;
	}

	private void writePoint(Point pt, ByteOrderValues dis, int dimensionOfCS, int SRID, int format)
			throws JASPAGeomParseException {

		if (pt.getCoordinateSequence().size() == 0)
			throw new JASPAGeomParseException("Empty Points cannot be represented in WKB");

		if (format >= 0) {
			// JASPA VECTORIAL FORMAT: VERSION 0
			if (format == 0) {
				writeGeometryTypeAndOrSRID(BinaryFormat.wkbPoint, dis, dimensionOfCS, SRID, format);
				writeCoordinateSequence(pt.getCoordinateSequence(), false, dis, dimensionOfCS);
			}
			// WKB or EWKB formats
		} else {
			dis.putByte(byteOrder);
			writeGeometryTypeAndOrSRID(BinaryFormat.wkbPoint, dis, dimensionOfCS, SRID, format);
			writeCoordinateSequence(pt.getCoordinateSequence(), false, dis, dimensionOfCS);
		}
	}

	private int getPointSize(Point pt, int dimensionOfCS, int size, int SRID, int format) {

		// Calculate the size of the binary array. The reason is to use a byte[]
		// instead an OutStream to store the binary objects
		// This way, the writer will be able to be a static class in a easier
		// way

		if (format >= 0) {
			// JASPA VECTORIAL FORMAT: VERSION 0
			if (format == 0) {
				size += 1 + // GeometryType
				dimensionOfCS * 8; // Point Coordinates
			}
			// WKB or EWKB formats
		} else {
			size += 1 + // ByteOrder
			4 + // GeometryType
			dimensionOfCS * 8; // Point Coordinates

			if (BinaryFormat.isEmbeddedSRID(SRID, format)) {
				size += 4; // SRID
			}
		}

		return size;
	}

	private void writeLineString(
			LineString line, ByteOrderValues dis, int dimensionOfCS, int SRID, int format) {

		if (format >= 0) {
			// JASPA VECTORIAL FORMAT: VERSION 0
			if (format == 0) {
				writeGeometryTypeAndOrSRID(BinaryFormat.wkbLineString, dis, dimensionOfCS, SRID, format);
				writeCoordinateSequence(line.getCoordinateSequence(), true, dis, dimensionOfCS);
			}
			// WKB or EWKB formats
		} else {
			dis.putByte(byteOrder);

			writeGeometryTypeAndOrSRID(BinaryFormat.wkbLineString, dis, dimensionOfCS, SRID, format);

			writeCoordinateSequence(line.getCoordinateSequence(), true, dis, dimensionOfCS);
		}
	}

	private int getLineStringSize(LineString line, int dimensionOfCS, int size, int SRID, int format) {

		if (format >= 0) {
			// JASPA VECTORIAL FORMAT: VERSION 0
			if (format == 0) {
				size += 1 + // GeometryType
						4 + // CoordinateSequence size
						dimensionOfCS * 8 * line.getNumPoints(); // Point Coordinates
			}
			// WKB or EWKB formats
		} else {
			size += 1 + // ByteOrder
					4 + // GeometryType
					4 + // CoordinateSequence size
					dimensionOfCS * 8 * line.getNumPoints(); // Point Coordinates

			if (BinaryFormat.isEmbeddedSRID(SRID, format)) {
				size += 4; // SRID
			}

		}

		return size;
	}

	private void writePolygon(
			Polygon poly, ByteOrderValues dis, int dimensionOfCS, int SRID, int format) {

		if (format >= 0) {
			// JASPA VECTORIAL FORMAT: VERSION 0
			if (format == 0) {
				writeGeometryTypeAndOrSRID(BinaryFormat.wkbPolygon, dis, dimensionOfCS, SRID, format);
				dis.putInt(poly.getNumInteriorRing() + 1);

				writeCoordinateSequence(poly.getExteriorRing().getCoordinateSequence(), true, dis,
						dimensionOfCS);
				for (int i = 0; i < poly.getNumInteriorRing(); i++) {
					writeCoordinateSequence(poly.getInteriorRingN(i).getCoordinateSequence(), true, dis,
							dimensionOfCS);
				}
			}
			// WKB or EWKB formats
		} else {
			dis.putByte(byteOrder);
			writeGeometryTypeAndOrSRID(BinaryFormat.wkbPolygon, dis, dimensionOfCS, SRID, format);
			dis.putInt(poly.getNumInteriorRing() + 1);

			// Rings are not stored as independent elements but just
			// (numcoor,coordinates..)
			// This is OGC compatible
			writeCoordinateSequence(poly.getExteriorRing().getCoordinateSequence(), true, dis,
					dimensionOfCS);
			for (int i = 0; i < poly.getNumInteriorRing(); i++) {
				writeCoordinateSequence(poly.getInteriorRingN(i).getCoordinateSequence(), true, dis,
						dimensionOfCS);
			}
		}
	}

	private int getPolygonSize(Polygon poly, int dimensionOfCS, int size, int SRID, int format) {

		if (format >= 0) {
			// JASPA VECTORIAL FORMAT: VERSION 0
			if (format == 0) {
				size += 1 + // GeometryType
						4 + // (NRings + 1)

						4 + poly.getNumInteriorRing() * 4 + // 4 Extrings + 4 * Int rings
						// rings:
						// CoordinateSequence
						// size
						dimensionOfCS * 8 * poly.getNumPoints(); // total numpoints
			}
			// WKB or EWKB formats
		} else {
			size += 1 + // ByteOrder
					4 + // GeometryType
					4 + // (NRings + 1)

					4 + poly.getNumInteriorRing() * 4 + // 4 Extrings + 4 * Int rings
					// rings:
					// CoordinateSequence
					// size
					dimensionOfCS * 8 * poly.getNumPoints(); // total numpoints

			if (BinaryFormat.isEmbeddedSRID(SRID, format)) {
				size += 4; // SRID
			}
		}

		return size;
	}

	private void writeGeometryCollection(
			int geometryType, GeometryCollection gc, ByteOrderValues dis, int dimensionOfCS, int SRID,
			int format)
			throws JASPAGeomParseException {

		if (format >= 0) {
			// JASPA VECTORIAL FORMAT: VERSION 0
			if (format == 0) {
				writeGeometryTypeAndOrSRID(geometryType, dis, dimensionOfCS, SRID, format);

				int nGeometries = gc.getNumGeometries();
				int nNotNullGeometries = 0;

				// Write just not empty geometries
				for (int i = 0; i < nGeometries; i++) {
					if (!gc.getGeometryN(i).isEmpty()) {
						nNotNullGeometries++;
					}
				}

				dis.putInt(nNotNullGeometries);

				for (int i = 0; i < nGeometries; i++) {
					Geometry geom = gc.getGeometryN(i);
					// Write just not empty geometries
					if (!geom.isEmpty()) {
						write(geom, dis, dimensionOfCS, SRID, format);
					}
				}

			}
			// WKB or EWKB formats
		} else {

			dis.putByte(byteOrder);
			writeGeometryTypeAndOrSRID(geometryType, dis, dimensionOfCS, SRID, format);

			int nGeometries = gc.getNumGeometries();
			int nNotNullGeometries = 0;

			// Write just not empty geometries
			for (int i = 0; i < nGeometries; i++) {
				if (!gc.getGeometryN(i).isEmpty()) {
					nNotNullGeometries++;
				}
			}

			dis.putInt(nNotNullGeometries);

			for (int i = 0; i < nGeometries; i++) {
				Geometry geom = gc.getGeometryN(i);
				// Write just not empty geometries
				if (!geom.isEmpty()) {
					write(geom, dis, dimensionOfCS, SRID, format);
				}
			}
		}
	}

	private int getGeometryCollectionSize(
			GeometryCollection gc, int dimensionOfCS, int size, int SRID, int format)
			throws JASPAGeomParseException {

		if (format >= 0) {
			// JASPA VECTORIAL FORMAT: VERSION 0
			if (format == 0) {
				size += 1 + // GeometryType
				4; // Number of elements

				for (int i = 0; i < gc.getNumGeometries(); i++) {
					Geometry geom = gc.getGeometryN(i);

					// Write just not empty geometries
					if (!geom.isEmpty()) {
						size = getSize(geom, dimensionOfCS, size, SRID, format);
					}
				}
			}
			// WKB or EWKB formats
		} else {

			size += 1 + // ByteOrder
			4 + // GeometryType
			4; // Number of elements

			if (BinaryFormat.isEmbeddedSRID(SRID, format)) {
				size += 4; // SRID
			}

			for (int i = 0; i < gc.getNumGeometries(); i++) {
				Geometry geom = gc.getGeometryN(i);

				// Write just not empty geometries
				if (!geom.isEmpty()) {
					size = getSize(geom, dimensionOfCS, size, SRID, format);
				}
			}
		}

		return size;
	}

	// Added by jomarlla: write different types of binary formats
	private void writeGeometryTypeAndOrSRID(
			int geometryType, ByteOrderValues dis, int dimensionOfCS, int SRID, int format) {

		// JASPA binary format version 0
		if (format >= 0) {
			int typeInt = geometryType;
			// Does not write the SRID information here
			// Does not write the coor dimension here
			dis.putByte((byte) typeInt);
		} else

		// PostGIS WKB or EWKB binary format
		{
			int typeInt = geometryType;

			if (dimensionOfCS == 3) {
				typeInt |= 0x80000000; // haz Z
			} else if (dimensionOfCS == 4) {
				typeInt |= 0x80000000; // has Z
				typeInt |= 0x40000000; // has M
			}
			// XYM type is not supported

			// SRID
			if (BinaryFormat.isEmbeddedSRID(SRID, format)) {
				typeInt |= 0x20000000; // hasS
				dis.putInt(typeInt);
				dis.putInt(SRID);
			} else {
				dis.putInt(typeInt);
			}
		}
	}

	private void writeCoordinateSequence(
			CoordinateSequence seq, boolean writeSize, ByteOrderValues dis, int dimensionOfCS) {

		int seqsize = seq.size();

		if (writeSize) {
			dis.putInt(seqsize);
		}

		for (int i = 0; i < seqsize; i++) {
			writeCoordinate(seq, i, dis, dimensionOfCS);
		}
	}

	// Modified by jomarlla: writes Z and ZM coordinates
	private void writeCoordinate(
			CoordinateSequence seq, int index, ByteOrderValues dis, int dimensionOfCS) {

		dis.putDouble(seq.getX(index));
		dis.putDouble(seq.getY(index));

		double ordVal;

		// Write Z value in the case CS (coordinate sequence) has 3 (XYZ) or 4
		// (XYZM) dimension
		// It does not allow to write XYM coordinates, but the JTS library does
		// not consider XYM coordinates either
		if (dimensionOfCS >= 3) {
			if (seq.getDimension() >= 3) {
				ordVal = seq.getOrdinate(index, 2);
			} else {
				ordVal = Double.NaN;
			}

			dis.putDouble(ordVal);
		}

		// Write M value in the case CS (coordinate sequence) has 3 (XYZ) or 4
		// (XYZM) dimension
		if (dimensionOfCS >= 4) {
			if (seq.getDimension() >= 4) {
				ordVal = seq.getOrdinate(index, 3);
			} else {
				ordVal = Double.NaN;
			}
			dis.putDouble(ordVal);
		}
	}
}