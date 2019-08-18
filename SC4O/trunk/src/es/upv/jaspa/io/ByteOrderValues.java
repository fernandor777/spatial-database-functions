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

/**
 * @author JTS, Jose Martinez-Llario
 * 
 *         This class is based on the class ByteOrderValues from JTS This class has been modified by
 *         jomarlla to work with byte arrays instead of streams
 * 
 *         2X faster according to some benchmark (jomarlla) then java.nio.ByteBuffer
 * 
 */
public final class ByteOrderValues {
	public static final int BIG_ENDIAN = 0; // jomarlla according to OGC
	public static final int LITTLE_ENDIAN = 1; // jomarlla according to OGC

	private int index;
	private byte[] buf;
	private int byteOrder = -1;

	public ByteOrderValues(byte[] buf) {

		this.buf = buf;
	}

	public boolean isNDROrder() {

		if (byteOrder == ByteOrderValues.LITTLE_ENDIAN)
			return true;
		else
			return false;
	}

	/**
	 * @return true if the format is a jaspa binary format, false if the format is WKB or
	 *         EWKB(postgis) format.
	 */

	public final boolean readByteOrder() {

		boolean isJASPABinaryFormat = false;

		byte order = getByte();
		// bit 4 marks if it is jaspa binary format
		isJASPABinaryFormat = (order & 0x08) != 0; // bit
		order &= 0xF7; // reset all but bit 4

		// default is big endian
		if (order == BinaryFormat.wkbNDR) {
			byteOrder = ByteOrderValues.LITTLE_ENDIAN;
		} else {
			byteOrder = ByteOrderValues.BIG_ENDIAN;
		}

		return isJASPABinaryFormat;
	}

	public void setByteOrder(byte byteOrder) {

		this.byteOrder = byteOrder;
	}

	public int getByOrder() {

		return byteOrder;
	}

	public byte getByte() {

		return buf[index++];
	}

	public int getIndex() {

		return index;
	}

	public void pushByte() {

		if (index > 0) index--;
	}

	public void putByte(byte byteValue) {

		buf[index++] = byteValue;
	}

	public int getInt() {

		if (byteOrder == BIG_ENDIAN)
			return ((buf[index++] & 0xff) << 24) | ((buf[index++] & 0xff) << 16)
					| ((buf[index++] & 0xff) << 8) | ((buf[index++] & 0xff));
		else
			return ((buf[index++] & 0xff)) | ((buf[index++] & 0xff) << 8)
					| ((buf[index++] & 0xff) << 16) | ((buf[index++] & 0xff) << 24);
	}

	public void putInt(int intValue) {

		if (byteOrder == BIG_ENDIAN) {
			buf[index++] = (byte) (intValue >> 24);
			buf[index++] = (byte) (intValue >> 16);
			buf[index++] = (byte) (intValue >> 8);
			buf[index++] = (byte) intValue;
		} else {// LITTLE_ENDIAN
			buf[index++] = (byte) intValue;
			buf[index++] = (byte) (intValue >> 8);
			buf[index++] = (byte) (intValue >> 16);
			buf[index++] = (byte) (intValue >> 24);
		}
	}

	public short getShortInt() {

		if (byteOrder == BIG_ENDIAN)
			return (short) (((buf[index++] & 0xff) << 8) | ((buf[index++] & 0xff)));
		else
			return (short) ((buf[index++] & 0xff) | ((buf[index++] & 0xff) << 8));
	}

	public void putShortInt(int intValue) {

		if (byteOrder == BIG_ENDIAN) {
			buf[index++] = (byte) (intValue >> 8);
			buf[index++] = (byte) intValue;
		} else {// LITTLE_ENDIAN
			buf[index++] = (byte) intValue;
			buf[index++] = (byte) (intValue >> 8);
		}
	}

	public long getLong() {

		if (byteOrder == BIG_ENDIAN)
			return (long) (buf[index++] & 0xff) << 56 | (long) (buf[index++] & 0xff) << 48
					| (long) (buf[index++] & 0xff) << 40 | (long) (buf[index++] & 0xff) << 32
					| (long) (buf[index++] & 0xff) << 24 | (long) (buf[index++] & 0xff) << 16
					| (long) (buf[index++] & 0xff) << 8 | (buf[index++] & 0xff);
		else
			return (buf[index++] & 0xff) | (long) (buf[index++] & 0xff) << 8
					| (long) (buf[index++] & 0xff) << 16 | (long) (buf[index++] & 0xff) << 24
					| (long) (buf[index++] & 0xff) << 32 | (long) (buf[index++] & 0xff) << 40
					| (long) (buf[index++] & 0xff) << 48 | (long) (buf[index++] & 0xff) << 56;
	}

	public void putLong(long longValue) {

		if (byteOrder == BIG_ENDIAN) {
			buf[index++] = (byte) (longValue >> 56);
			buf[index++] = (byte) (longValue >> 48);
			buf[index++] = (byte) (longValue >> 40);
			buf[index++] = (byte) (longValue >> 32);
			buf[index++] = (byte) (longValue >> 24);
			buf[index++] = (byte) (longValue >> 16);
			buf[index++] = (byte) (longValue >> 8);
			buf[index++] = (byte) longValue;
		} else { // LITTLE_ENDIAN
			buf[index++] = (byte) longValue;
			buf[index++] = (byte) (longValue >> 8);
			buf[index++] = (byte) (longValue >> 16);
			buf[index++] = (byte) (longValue >> 24);
			buf[index++] = (byte) (longValue >> 32);
			buf[index++] = (byte) (longValue >> 40);
			buf[index++] = (byte) (longValue >> 48);
			buf[index++] = (byte) (longValue >> 56);
		}
	}

	public double getDouble() {

		return Double.longBitsToDouble(getLong());
	}

	public void putDouble(double doubleValue) {

		putLong(Double.doubleToLongBits(doubleValue));
	}

}