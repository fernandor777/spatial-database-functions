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

import es.upv.jaspa.Core;
import es.upv.jaspa.exceptions.JASPAGeomParseException;

import java.io.IOException;
import java.io.StringWriter;
import java.io.Writer;

import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;

import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.CoordinateSequence;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryCollection;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.LinearRing;
import org.locationtech.jts.geom.MultiLineString;
import org.locationtech.jts.geom.MultiPoint;
import org.locationtech.jts.geom.MultiPolygon;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.Polygon;
import org.locationtech.jts.geom.PrecisionModel;

/**
 *
 * @author JTS, Jose Martinez-Llario
 *
 *         This class is based on the class WKBWriter from JTS This class has been modified by
 *         jomarlla
 *
 *         jomarlla: Do not mix coordinate dimension
 */
public class JTS2WKT 
{
    
    private static String tagZ = "Z"; 
    private static String tagM = "M"; 
    private static String tagZM = "ZM"; 

	/**
	 * Generates the WKT for a <code>Point</code>.
	 * 
	 * @param p0
	 *           the point coordinate
	 * 
	 * @return the WKT
	 */
	public static String toPoint(Coordinate p0) {

		return "POINT ( " + p0.x + " " + p0.y + " )";
	}

	/**
	 * Generates the WKT for a N-point <code>LineString</code>.
	 * 
	 * @param seq
	 *           the sequence to outpout
	 * 
	 * @return the WKT
	 */
	public static String toLineString(CoordinateSequence seq) {

		StringBuffer buf = new StringBuffer();
		buf.append("LINESTRING ");
		if (seq.size() == 0) {
			buf.append(" EMPTY");
		} else {
			buf.append("(");
			for (int i = 0; i < seq.size(); i++) {
				if (i > 0) {
					buf.append(", ");
				}
				buf.append(seq.getX(i) + " " + seq.getY(i));
			}
			buf.append(")");
		}
		return buf.toString();
	}

	/**
	 * Generates the WKT for a 2-point <code>LineString</code>.
	 * 
	 * @param p0
	 *           the first coordinate
	 * @param p1
	 *           the second coordinate
	 * 
	 * @return the WKT
	 */
	public static String toLineString(Coordinate p0, Coordinate p1) {
		return "LINESTRING ( " + p0.x + " " + p0.y + ", " + p1.x + " " + p1.y + " )";
	}

	/**
	 * Creates the <code>DecimalFormat</code> used to write <code>double</code>s with a sufficient
	 * number of decimal places.
	 * 
	 * @param precisionModel
	 *           the <code>PrecisionModel</code> used to determine the number of decimal places to
	 *           write.
	 * @return a <code>DecimalFormat</code> that write <code>double</code> s without scientific
	 *         notation.
	 */
	private static DecimalFormat createFormatter(PrecisionModel precisionModel) {

		// the default number of decimal places is 16, which is sufficient
		// to accomodate the maximum precision of a double.
		int decimalPlaces = precisionModel.getMaximumSignificantDigits();
		if (decimalPlaces < 0) {
			decimalPlaces = 0;
		}
		if (decimalPlaces > MAX_DECIMAL_PLACES) {
			decimalPlaces = MAX_DECIMAL_PLACES;
			// specify decimal separator explicitly to avoid problems in other
			// locales
		}

		/*
		 * DecimalFormatSymbols symbols = new DecimalFormatSymbols();
		 * symbols.setDecimalSeparator('.'); return new DecimalFormat("0" + (decimalPlaces > 0 ? "." :
		 * "") + stringOfChar('#', decimalPlaces), symbols);
		 */

		return DECIMALFORMAT[decimalPlaces];
	}

	/*
	 * =====================================================================================
	 * Singletons
	 * =======================================================================================
	 */
	public static final int MAX_DECIMAL_PLACES = 15;

	private static final DecimalFormat[] DECIMALFORMAT = new DecimalFormat[MAX_DECIMAL_PLACES + 1];
	private static final DecimalFormatSymbols symbols = new DecimalFormatSymbols();

	static {
		symbols.setDecimalSeparator('.');
		for (int i = 0; i <= MAX_DECIMAL_PLACES; i++) {
			DECIMALFORMAT[i] = new DecimalFormat("0" + (i > 0 ? "." : "") + stringOfChar('#', i),
					symbols);
		}
	}

	private static final JTS2WKT INSTANCE_WITHFORMAT = new JTS2WKT(true);
	private static final JTS2WKT INSTANCE_WITHOUTFORMAT = new JTS2WKT(false);

	public static JTS2WKT instance(boolean useFormatting) {

		if (useFormatting) return INSTANCE_WITHFORMAT;
		return INSTANCE_WITHOUTFORMAT;
	}

	public static JTS2WKT instance() {

		return instance(false);
	}

	/**
	 * Creates a new WKTWriter with default settings
	 */
	private JTS2WKT(boolean useFormatting) {

		this.useFormatting = useFormatting;
	}

	/*
	 * ===================================================================================== End of
	 * Singleton
	 * =======================================================================================
	 */

	/**
	 * Returns a <code>String</code> of repeated characters.
	 * 
	 * @param ch
	 *           the character to repeat
	 * @param count
	 *           the number of times to repeat the character
	 * @return a <code>String</code> of characters
	 */
	public static String stringOfChar(char ch, int count) {

		StringBuffer buf = new StringBuffer();
		for (int i = 0; i < count; i++) {
			buf.append(ch);
		}
		return buf.toString();
	}

	// private int outputDimension = 2; // to static

	// private DecimalFormat formatter; // to static
	private final boolean useFormatting;

	// Todo:
	private final int coordsPerLine = -1;

	private static final String indentTabStr = "  ";

	public String write(Geometry geometry)
        throws JASPAGeomParseException 
        {
            int outputDimension = Core.calculateDimensionOfGeometryCoordinates(geometry);
            if (outputDimension < 2 || outputDimension > 4)
                throw new JASPAGeomParseException("Invalid output dimension (must be 2, 3 or 4)");
            return write(geometry, outputDimension);
	}

	/**
	 * Converts a <code>Geometry</code> to its Well-known Text representation.
	 * 
	 * @param geometry
	 *           a <code>Geometry</code> to process
	 * @return a <Geometry Tagged Text> string (see the OpenGIS Simple Features Specification)
	 * @throws JASPAGeomParseException
	 */
	public String write(Geometry geometry, 
                            int outputDimension)
        throws JASPAGeomParseException 
        {
            if (outputDimension < 2 || outputDimension > 4)
                throw new JASPAGeomParseException("Invalid output dimension (must be 2, 3 or 4)");
            
            Writer sw = new StringWriter();
            try {
                writeFormatted(geometry, sw, outputDimension);
            } catch (IOException ex) {
                throw new JASPAGeomParseException(ex.toString());
            }
            return sw.toString();
	}

	/**
	 * Converts a <code>Geometry</code> to its Well-known Text representation.
	 * 
	 * @param geometry
	 *           a <code>Geometry</code> to process
	 * @return a <Geometry Tagged Text> string (see the OpenGIS Simple Features Specification)
	 * @throws JASPAGeomParseException
	 */
	private void writeFormatted(Geometry geometry, 
                                    Writer writer, 
                                    int outputDimension)
        throws IOException, JASPAGeomParseException 
        {
            DecimalFormat formatter = createFormatter(geometry.getPrecisionModel());
            appendGeometryTaggedText(geometry, 0, writer, outputDimension, formatter);
	}

	/**
	 * Converts a <code>Geometry</code> to &lt;Geometry Tagged Text&gt; format, then appends it to
	 * the writer.
	 * 
	 * @param geometry
	 *           the <code>Geometry</code> to process
	 * @param writer
	 *           the output writer to append to
	 * @throws JASPAGeomParseException
	 */
	private void appendGeometryTaggedText(Geometry geometry, 
                                              int level, 
                                              Writer writer, 
                                              int outputDimension,
                                              DecimalFormat formatter)
        throws IOException, 
               JASPAGeomParseException 
        {
            indent(level, writer);
            
            if (geometry instanceof Point) {
                Point point = (Point) geometry;
                appendPointTaggedText(point.getCoordinate(), level, writer, point.getPrecisionModel(),outputDimension, formatter);
            } else if (geometry instanceof LinearRing) {
                appendLinearRingTaggedText((LinearRing) geometry, level, writer, outputDimension,formatter);
            } else if (geometry instanceof LineString) {
                appendLineStringTaggedText((LineString) geometry, level, writer, outputDimension,formatter);
            } else if (geometry instanceof Polygon) {
                appendPolygonTaggedText((Polygon) geometry, level, writer, outputDimension, formatter);
            } else if (geometry instanceof MultiPoint) {
                appendMultiPointTaggedText((MultiPoint) geometry, level, writer, outputDimension,formatter);
            } else if (geometry instanceof MultiLineString) {
                appendMultiLineStringTaggedText((MultiLineString) geometry, level, writer,outputDimension, formatter);
            } else if (geometry instanceof MultiPolygon) {
                appendMultiPolygonTaggedText((MultiPolygon) geometry, level, writer, outputDimension,formatter);
            } else if (geometry instanceof GeometryCollection) {
                appendGeometryCollectionTaggedText((GeometryCollection) geometry, level, writer,outputDimension, formatter);
            } else {
                throw new JASPAGeomParseException("Unsupported JTS Geometry implementation:"+ geometry.getClass());
            }
	}

	/**
	 * Converts a <code>Coordinate</code> to &lt;Point Tagged Text&gt; format, then appends it to the
	 * writer.
	 * 
	 * @param coordinate
	 *           the <code>Coordinate</code> to process
	 * @param writer
	 *           the output writer to append to
	 * @param precisionModel
	 *           the <code>PrecisionModel</code> to use to convert from a precise coordinate to an
	 *           external coordinate
	 */
	private void appendPointTaggedText(Coordinate coordinate, 
                                           int level, 
                                           Writer writer, 
                                           PrecisionModel precisionModel,
                                           int outputDimension, 
                                           DecimalFormat formatter)
        throws IOException 
        {
            String geoTag = "POINT";
            if ( level == 0) {
                switch ( outputDimension ) {
                  case 3 : geoTag = geoTag + ( coordinate.hasM() ? tagM : tagZ ) + " "; break;
	          case 4 : geoTag = geoTag + tagZM + " ";                   break;
	          case 2 : 
	         default : geoTag = geoTag + " "; 
                }
            } else {
                geoTag = geoTag + " ";
            }
	    writer.write(geoTag);
            appendPointText(coordinate, level, writer, precisionModel, outputDimension, formatter);
	}

	/**
	 * Converts a <code>LineString</code> to &lt;LineString Tagged Text&gt; format, then appends it
	 * to the writer.
	 * 
	 * @param lineString
	 *           the <code>LineString</code> to process
	 * @param writer
	 *           the output writer to append to
	 */
	private void appendLineStringTaggedText(
			LineString lineString, 
                        int level, 
                        Writer writer, 
                        int outputDimension,
			DecimalFormat formatter)
	throws IOException 
        {
	    String geoTag = "LINESTRING";
	    if ( level == 0) {
                switch ( outputDimension ) {
	          case 3 : geoTag = geoTag + ( lineString.getCoordinate().hasM() 
                                    ? tagM 
                                    : tagZ ) + " "; break;
                  case 4 : geoTag = geoTag + tagZM + " ";                   break;
	          case 2 : 
	          default : geoTag = geoTag + " "; 
                }
            } else {
                geoTag = geoTag + " ";
            }
	    writer.write(geoTag);
            appendLineStringText(lineString, level, false, writer, outputDimension, formatter);
	}

	/**
	 * Converts a <code>LinearRing</code> to &lt;LinearRing Tagged Text&gt; format, then appends it
	 * to the writer.
	 * 
	 * @param linearRing
	 *           the <code>LinearRing</code> to process
	 * @param writer
	 *           the output writer to append to
	 */
	private void appendLinearRingTaggedText(
			LinearRing linearRing, 
                        int level, 
                        Writer writer, 
                        int outputDimension,
			DecimalFormat formatter)
			throws IOException 
        {
	    String geoTag = "LINEARRING";
	    if ( level == 0) {
	        switch ( outputDimension ) {
	        case 3 : geoTag = geoTag + ( linearRing.getCoordinate().hasM() 
	                                     ? tagM 
	                                     : tagZ ) + " "; break;
	        case 4 : geoTag = geoTag + tagZM + " ";                   break;
	        case 2 : 
	        default : geoTag = geoTag + " "; 
                }
	    } else {
	        geoTag = geoTag + " ";
	    }
	    writer.write(geoTag);

            appendLineStringText(linearRing, level, false, writer, outputDimension, formatter);
	}

	/**
	 * Converts a <code>Polygon</code> to &lt;Polygon Tagged Text&gt; format, then appends it to the
	 * writer.
	 * 
	 * @param polygon
	 *           the <code>Polygon</code> to process
	 * @param writer
	 *           the output writer to append to
	 */
	private void appendPolygonTaggedText(
			Polygon polygon, int level, Writer writer, int outputDimension, DecimalFormat formatter)
        throws IOException 
        {            
	    String geoTag = "POLYGON";
	    if ( level == 0) {
	        switch ( outputDimension ) {
	        case 3 : geoTag = geoTag + ( polygon.getCoordinate().hasM() 
	                                     ? tagM 
	                                     : tagZ ) + " "; break;
	        case 4 : geoTag = geoTag + tagZM + " ";                   break;
	        case 2 : 
	        default : geoTag = geoTag + " "; 
                }
            } else {
                geoTag = geoTag + " ";
            }
	    writer.write(geoTag);
            appendPolygonText(polygon, level, false, writer, outputDimension, formatter);
	}

	/**
	 * Converts a <code>MultiPoint</code> to &lt;MultiPoint Tagged Text&gt; format, then appends it
	 * to the writer.
	 * 
	 * @param multipoint
	 *           the <code>MultiPoint</code> to process
	 * @param writer
	 *           the output writer to append to
	 */
	private void appendMultiPointTaggedText(
			MultiPoint multipoint, 
                        int level, 
                        Writer writer, 
                        int outputDimension,
			DecimalFormat formatter)
        throws IOException 
        {
	    String geoTag = "MULTIPOINT";
	    if ( level == 0) {
	        switch ( outputDimension ) {
	        case 3 : geoTag = geoTag + ( multipoint.getCoordinate().hasM() 
	                                     ? tagM 
	                                     : tagZ ) + " "; break;
	        case 4 : geoTag = geoTag + tagZM + " ";                   break;
	        case 2 : 
	        default : geoTag = geoTag + " "; 
                }
            } else {
                geoTag = geoTag + " ";
            }
	    writer.write(geoTag);
            appendMultiPointText(multipoint, level, writer, outputDimension, formatter);
	}

	/**
	 * Converts a <code>MultiLineString</code> to &lt;MultiLineString Tagged Text&gt; format, then
	 * appends it to the writer.
	 * 
	 * @param multiLineString
	 *           the <code>MultiLineString</code> to process
	 * @param writer
	 *           the output writer to append to
	 */
	private void appendMultiLineStringTaggedText(
			MultiLineString multiLineString, 
                        int level, 
                        Writer writer, 
                        int outputDimension,
			DecimalFormat formatter)
        throws IOException 
        {
	    String geoTag = "MULTILINESTRING";
	    if ( level == 0) {
	        switch ( outputDimension ) {
	        case 3 : geoTag = geoTag + ( multiLineString.getCoordinate().hasM() 
	                                     ? tagM 
	                                     : tagZ ) + " "; break;
	        case 4 : geoTag = geoTag + tagZM + " ";                   break;
	        case 2 : 
	        default : geoTag = geoTag + " "; 
                }
            } else {
                geoTag = geoTag + " ";
            }
	    writer.write(geoTag);
            appendMultiLineStringText(multiLineString, level, false, writer, outputDimension, formatter);
	}

	/**
	 * Converts a <code>MultiPolygon</code> to &lt;MultiPolygon Tagged Text&gt; format, then appends
	 * it to the writer.
	 * 
	 * @param multiPolygon
	 *           the <code>MultiPolygon</code> to process
	 * @param writer
	 *           the output writer to append to
	 */
	private void appendMultiPolygonTaggedText(
			MultiPolygon multiPolygon, 
                        int level, 
                        Writer writer, 
                        int outputDimension,
			DecimalFormat formatter)
        throws IOException 
        {
	    String geoTag = "MULTIPOLYGON";
	    if ( level == 0) {
	        switch ( outputDimension ) {
	        case 3 : geoTag = geoTag + ( multiPolygon.getCoordinate().hasM() 
	                                     ? tagM 
	                                     : tagZ ) + " "; break;
	        case 4 : geoTag = geoTag + tagZM + " ";                   break;
	        case 2 : 
	        default : geoTag = geoTag + " "; 
                }
            } else {
                geoTag = geoTag + " ";
            }
	    writer.write(geoTag);
            appendMultiPolygonText(multiPolygon, level, writer, outputDimension, formatter);
	}

	/**
	 * Converts a <code>GeometryCollection</code> to &lt;GeometryCollection Tagged Text&gt; format,
	 * then appends it to the writer.
	 * 
	 * @param geometryCollection
	 *           the <code>GeometryCollection</code> to process
	 * @param writer
	 *           the output writer to append to
	 * @throws JASPAGeomParseException
	 */
	private void appendGeometryCollectionTaggedText(
			GeometryCollection geometryCollection, 
                        int level, 
                        Writer writer, 
                        int outputDimension,
			DecimalFormat formatter)
        throws IOException, 
               JASPAGeomParseException 
        {
	    String geoTag = "GEOMETRYCOLLECTION ";
	    if ( level == 0) {
	        switch ( outputDimension ) {
	        case 3 : geoTag = geoTag + ( geometryCollection.getCoordinate().hasM() 
	                                     ? tagM 
	                                     : tagZ ) + " "; break;
	        case 4 : geoTag = geoTag + tagZM + " ";                   break;
	        case 2 : 
	        default : geoTag = geoTag + " "; 
	        }
	    } else {
	        geoTag = geoTag + " ";
	    }
	    writer.write(geoTag);
	    appendGeometryCollectionText(geometryCollection, level, writer, outputDimension, formatter);
	}

	/**
	 * Converts a <code>Coordinate</code> to &lt;Point Text&gt; format, then appends it to the
	 * writer.
	 * 
	 * @param coordinate
	 *           the <code>Coordinate</code> to process
	 * @param writer
	 *           the output writer to append to
	 * @param precisionModel
	 *           the <code>PrecisionModel</code> to use to convert from a precise coordinate to an
	 *           external coordinate
	 */
	private void appendPointText(Coordinate coordinate, 
                                     int level, 
                                     Writer writer, 
                                     PrecisionModel precisionModel,
                                     int outputDimension, 
                                     DecimalFormat formatter)
        throws IOException 
        {
            if (coordinate == null) {
                writer.write("EMPTY");
            } else {
                writer.write("(");
                appendCoordinate(coordinate, writer, outputDimension, formatter);
                writer.write(")");
            }
	}

	/**
	 * Appends the i'th coordinate from the sequence to the writer
	 * 
	 * @param seq
	 *           the <code>CoordinateSequence</code> to process
	 * @param i
	 *           the index of the coordinate to write
	 * @param writer
	 *           the output writer to append to jomarlla: if z is NaN and the geometry has Z then
	 *           writes 0 as Z value.
	 */

	private void appendCoordinate(
			CoordinateSequence seq, 
                        int i, 
                        Writer writer, 
                        int outputDimension, 
                        DecimalFormat formatter)
        throws IOException 
        {
            writer.write(writeNumber(seq.getX(i), formatter) + " " + writeNumber(seq.getY(i), formatter));
            if (outputDimension == 3 && seq.getDimension() >= 3) {
                double z = seq.getOrdinate(i, CoordinateSequence.Z);
                
                /*
		 * // Orignal JTS1.10. if (! Double.isNaN(z)) { writer.write(" ");
		 * writer.write(writeNumber(z)); }
                 **/
                // adds by jomarlla
		if (Double.isNaN(z)) {
                    z = 0.0;
                }
                writer.write(" ");
                writer.write(writeNumber(z, formatter));
            }
            
            // adds by jomarlla
            if (outputDimension == 4 && seq.getDimension() >= 4) {
                double m = seq.getOrdinate(i, CoordinateSequence.M);
                if (Double.isNaN(m)) {
                    m = 0.0;
                }
                writer.write(" ");
		writer.write(writeNumber(m, formatter));
            }
	}

	/**
	 * Converts a <code>Coordinate</code> to <code>&lt;Point&gt;</code> format, then appends it to
	 * the writer.
	 * 
	 * @param coordinate
	 *           the <code>Coordinate</code> to process
	 * @param writer
	 *           the output writer to append to jomarlla: if z is NaN and the geometry has Z then
	 *           writes 0.0 as Z value. jomarlla: support m coordianate jomarlla: if m is NaN and the
	 *           geometry has M then writes 0.0 as M value.
	 */

	private void appendCoordinate(
			Coordinate coordinate, Writer writer, int outputDimension, DecimalFormat formatter)
			throws IOException {

		writer.write(writeNumber(coordinate.x, formatter) + " "
				+ writeNumber(coordinate.y, formatter));

		double z = coordinate.z;

		if (Double.isNaN(z)) {
			z = 0.0;
		}

		if (outputDimension >= 3) {
			writer.write(" ");
			writer.write(writeNumber(z, formatter));
		}

		double m = coordinate.m;

		if (Double.isNaN(m)) {
			m = 0.0;
		}

		if (outputDimension >= 4) {
			writer.write(" ");
			writer.write(writeNumber(m, formatter));
		}
	}

	/**
	 * Converts a <code>double</code> to a <code>String</code>, not in scientific notation.
	 * 
	 * @param d
	 *           the <code>double</code> to convert
	 * @return the <code>double</code> as a <code>String</code>, not in scientific notation
	 */
	private String writeNumber(double d, DecimalFormat formatter) {

		return formatter.format(d);
	}

	/**
	 * Converts a <code>LineString</code> to &lt;LineString Text&gt; format, then appends it to the
	 * writer.
	 * 
	 * @param lineString
	 *           the <code>LineString</code> to process
	 * @param writer
	 *           the output writer to append to
	 */
	private void appendSequenceText(
			CoordinateSequence seq, 
                        int level, 
                        boolean doIndent, 
                        Writer writer, 
                        int outputDimension,
			DecimalFormat formatter)
        throws IOException 
        {
            if (seq.size() == 0) {
                writer.write("EMPTY");
            } else {
                if (doIndent) {
                    indent(level, writer);
                }
                writer.write("(");
                for (int i = 0; i < seq.size(); i++) {
                    if (i > 0) {
                        writer.write(", ");
                        if (coordsPerLine > 0 && i % coordsPerLine == 0) {
                            indent(level + 1, writer);
                        }
                    }
                    appendCoordinate(seq, i, writer, outputDimension, formatter);
                }
		writer.write(")");
            }
	}

	/**
	 * Converts a <code>LineString</code> to &lt;LineString Text&gt; format, then appends it to the
	 * writer.
	 * 
	 * @param lineString
	 *           the <code>LineString</code> to process
	 * @param writer
	 *           the output writer to append to
	 */
	private void appendLineStringText(
			LineString lineString, 
                        int level, 
                        boolean doIndent, 
                        Writer writer, 
                        int outputDimension,
			DecimalFormat formatter)
        throws IOException 
        {
            if (lineString.isEmpty()) {
                writer.write("EMPTY");
            } else {
                if (doIndent) {
                    indent(level, writer);
                }
                writer.write("(");
                for (int i = 0; i < lineString.getNumPoints(); i++) {
                    if (i > 0) {
                        writer.write(", ");
                        if (coordsPerLine > 0 && i % coordsPerLine == 0) {
                            indent(level + 1, writer);
                        }
                    }
                    appendCoordinate(lineString.getCoordinateN(i), writer, outputDimension, formatter);
		}
		writer.write(")");
            }
	}

	/**
	 * Converts a <code>Polygon</code> to &lt;Polygon Text&gt; format, then appends it to the writer.
	 * 
	 * @param polygon
	 *           the <code>Polygon</code> to process
	 * @param writer
	 *           the output writer to append to
	 */
	private void appendPolygonText(
			Polygon polygon, 
                        int level, 
                        boolean indentFirst, 
                        Writer writer, 
                        int outputDimension,
			DecimalFormat formatter)
        throws IOException 
        {
            if (polygon.isEmpty()) {
                writer.write("EMPTY");
            } else {
                if (indentFirst) {
                    indent(level, writer);
                }
                writer.write("(");
                appendLineStringText(polygon.getExteriorRing(), 
                                     level, 
                                     false, 
                                     writer, 
                                     outputDimension,
                                     formatter);
                for (int i = 0; i < polygon.getNumInteriorRing(); i++) {
                    writer.write(", ");
                    appendLineStringText(polygon.getInteriorRingN(i), 
                                         level + 1, 
                                         true, 
                                         writer,
					outputDimension, 
                                         formatter);
                }
                writer.write(")");
            }
	}

	/**
	 * Converts a <code>MultiPoint</code> to &lt;MultiPoint Text&gt; format, then appends it to the
	 * writer.
	 * 
	 * @param multiPoint
	 *           the <code>MultiPoint</code> to process
	 * @param writer
	 *           the output writer to append to
	 */
	private void appendMultiPointText(
			MultiPoint multiPoint, 
                        int level, 
                        Writer writer, 
                        int outputDimension,
			DecimalFormat formatter)
        throws IOException 
        {
            if (multiPoint.isEmpty()) {
                writer.write("EMPTY");
            } else {
                writer.write("(");
                for (int i = 0; i < multiPoint.getNumGeometries(); i++) {
                    if (i > 0) {
                        writer.write(", ");
                        indentCoords(i, level + 1, writer);
                    }
                    writer.write("(");
                    appendCoordinate(((Point) multiPoint.getGeometryN(i)).getCoordinate(), 
                                     writer,
                                     outputDimension, 
                                     formatter);
                    writer.write(")");
		}
		writer.write(")");
            }
	}

	/**
	 * Converts a <code>MultiLineString</code> to &lt;MultiLineString Text&gt; format, then appends
	 * it to the writer.
	 * 
	 * @param multiLineString
	 *           the <code>MultiLineString</code> to process
	 * @param writer
	 *           the output writer to append to
	 */
	private void appendMultiLineStringText(
			MultiLineString multiLineString, 
                        int level, 
                        boolean indentFirst, 
                        Writer writer,
			int outputDimension, 
                        DecimalFormat formatter)
        throws IOException 
        {
            if (multiLineString.isEmpty()) {
                writer.write("EMPTY");
            } else {
                int level2 = level;
                boolean doIndent = indentFirst;
                writer.write("(");
                for (int i = 0; i < multiLineString.getNumGeometries(); i++) {
                    if (i > 0) {
                        writer.write(", ");
                        level2 = level + 1;
                        doIndent = true;
                    }
                    appendLineStringText((LineString) multiLineString.getGeometryN(i), 
                                         level2, 
                                         doIndent,
					 writer, 
                                         outputDimension, 
                                         formatter);
                }
                writer.write(")");
            }
	}

	/**
	 * Converts a <code>MultiPolygon</code> to &lt;MultiPolygon Text&gt; format, then appends it to
	 * the writer.
	 * 
	 * @param multiPolygon
	 *           the <code>MultiPolygon</code> to process
	 * @param writer
	 *           the output writer to append to
	 */
	private void appendMultiPolygonText(
			MultiPolygon multiPolygon, 
                        int level, 
                        Writer writer, 
                        int outputDimension,
			DecimalFormat formatter)
        throws IOException 
        {
            if (multiPolygon.isEmpty()) {
                writer.write("EMPTY");
            } else {
                int level2 = level;
                boolean doIndent = false;
                writer.write("(");
                for (int i = 0; i < multiPolygon.getNumGeometries(); i++) {
                    if (i > 0) {
                        writer.write(", ");
                        level2 = level + 1;
                        doIndent = true;
                    }
                    appendPolygonText((Polygon) multiPolygon.getGeometryN(i), 
                                      level2, 
                                      doIndent, 
                                      writer,
                                      outputDimension, 
                                      formatter);
                }
		writer.write(")");
            }
	}

	/**
	 * Converts a <code>GeometryCollection</code> to &lt;GeometryCollectionText&gt; format, then
	 * appends it to the writer.
	 * 
	 * @param geometryCollection
	 *           the <code>GeometryCollection</code> to process
	 * @param writer
	 *           the output writer to append to
	 * @throws JASPAGeomParseException
	 */
	private void appendGeometryCollectionText(
			GeometryCollection geometryCollection, 
                        int level, 
                        Writer writer, 
                        int outputDimension,
			DecimalFormat formatter)
        throws IOException, 
               JASPAGeomParseException 
        {
            if (geometryCollection.isEmpty()) {
                writer.write("EMPTY");
            } else {
                int level2 = level;
                writer.write("(");
                for (int i = 0; i < geometryCollection.getNumGeometries(); i++) {
                    if (i > 0) {
                        writer.write(", ");
                        level2 = level + 1;
                    }
                    appendGeometryTaggedText(geometryCollection.getGeometryN(i), 
                                             level2, 
                                             writer,
                                             outputDimension, formatter);
                }
		writer.write(")");
            }
	}

	private void indentCoords(int coordIndex, int level, Writer writer)
			throws IOException {

		if (coordsPerLine <= 0 || coordIndex % coordsPerLine != 0) return;
		indent(level, writer);
	}

	private void indent(int level, Writer writer)
			throws IOException {

		if (!useFormatting || level <= 0) return;
		writer.write("\n");
		for (int i = 0; i < level; i++) {
			writer.write(indentTabStr);
		}
	}
}
