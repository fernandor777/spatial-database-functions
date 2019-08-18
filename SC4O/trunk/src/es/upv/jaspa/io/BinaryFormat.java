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

public final class BinaryFormat {
	public final static int wkbXDR = ByteOrderValues.BIG_ENDIAN;
	public final static int wkbNDR = ByteOrderValues.LITTLE_ENDIAN;

	// This is the default byteorder and the JASPA vectorial format byte order
	public static final int defaultByteOrder = ByteOrderValues.LITTLE_ENDIAN;

	// Default SRID
	// In PostGIS is -1
        // In Oracle is 0
	public static final int defaultSRID = -1;

	// ---------------------------------------
	// Geometry types
	// ---------------------------------------
	// must not be greater than 255
	public final static int wkbPoint = 1;
	public final static int wkbLineString = 2;
	public final static int wkbPolygon = 3;
	public final static int wkbMultiPoint = 4;
	public final static int wkbMultiLineString = 5;
	public final static int wkbMultiPolygon = 6;
	public final static int wkbGeometryCollection = 7;

	// ---------------------------------------
	// Binary formats
	// ---------------------------------------
	// WKB and WKB with SRID embedded
	public final static int wkbJASPAFormatVectorial = 0; // This is jaspa binary format
	public final static int wkbJASPAFormatRaster = 1; // This is jaspa binary format
	public final static int wkbPostGISwithSRID = 2; // This format is NOT OGC compatible
	public final static int wkbPostGISwithoutSRID = 3; // This format IS OGC compatible

	public final static int wkbJASPADefaultFormatVectorial = 0; // format version 0-31
	public final static int wkbJASPADefaultFormatRaster = 0; // format version 0-31

	// JASPA internal binary formats

	// Vectorial formats:
	// version 0:
	// Notes: one byteorder information for all the geometry
	// extra byte for storing the format version
	// one SRID for all the geometry
	// one byte instead of for for writing the geometry type
	// ---- Bytes 0 and 1 are not expected to change in all jaspa life
	// byte 0 - bit 0 - byte order, bit 4 (1 jaspa binary format, 0 wkb or ewkb formats) , bits 1,2,3
	// (not used)
	// bits 4-7 (MUST be 0).
	// byte 1 - bits 0-4 (jaspa binary version 0-31)
	// bit 5 (1 vectorial format, 0 raster format), bit 6-7 (not used)
	// ---- From here other jaspa versions might change the storage
	// byte 2 - bit 0 (1 has Z 0 hasnt)
	// bit 1 (1 has M 0 hasnt)
	// bit 2-6 (not used)
	// bit 7 (0 there is not srid, 1 there is srid information),
	// byte 3-6 SRID information if it is the case
	// ---- geometries
	// version 1:
	// future version: tolerance information?, BBOX?

	// Raster formats:

	public static boolean isJASPABinaryFormat(int formatType) {

		if (formatType == wkbJASPAFormatVectorial || formatType == wkbJASPAFormatRaster) return true;
		return false;
	}

	public static boolean isEmbeddedSRID(int SRID, int formatType) {

		if (formatType < 0) formatType = -formatType;

		if (isJASPABinaryFormat(formatType) || (formatType == BinaryFormat.wkbPostGISwithSRID)) {

			// If the SRID is defaultSRID then do not embed the SRID
			if (SRID != BinaryFormat.defaultSRID) return true;
		}
		return false;
	}

}
