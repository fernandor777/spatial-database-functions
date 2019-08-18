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
import java.io.Reader;
import java.io.StreamTokenizer;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.List;


import org.locationtech.jts.geom.Coordinate;
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
import org.locationtech.jts.util.AssertionFailedException;

import es.upv.jaspa.Core;
import es.upv.jaspa.exceptions.JASPAGeomParseException;
import es.upv.jaspa.exceptions.JASPAJTSException;

import java.util.Arrays;

import oracle.sql.STRUCT;

/**
 *
 * @author JTS, Jose Martinez-Llario
 *
 *         This class is based on the class WKTReader from JTS This class has been modified by
 *         jomarlla
 *
 *         jomarlla: Extends to read WKT with Z according to OGC SFS 1.2.0. Embedded SRID in WKT
 *         (EWKT PostGIS compatible) Change SRID in all the subelements of MultiGeometries (not just
 *         in the parent object) Empty geometries are interpreted as null geometries. Thread sage
 *         class. Instance variables pass by arguments to use stack memory
 */

public class WKT2JTS 
{
    private static final String EMPTY = "EMPTY";
    private static final String COMMA = ",";
    private static final String L_PAREN = "(";
    private static final String R_PAREN = ")";
    private static final String SEMICOLON = ";"; // For embedded SRID
    private static final String EQUAL = ";"; // For embedded SRID
    private static final String NAN_SYMBOL = "NaN";

    private static final String BOX = "BOX";
    private static final String BOX3D = "BOX3D";

    private static final String POINT = "POINT";
    private static final String LINESTRING = "LINESTRING";
    private static final String LINEARRING = "LINEARRING";
    private static final String POLYGON = "POLYGON";
    private static final String MULTIPOINT = "MULTIPOINT";
    private static final String MULTILINESTRING = "MULTILINESTRING";
    private static final String MULTIPOLYGON = "MULTIPOLYGON";
    private static final String GEOMETRYCOLLECTION = "GEOMETRYCOLLECTION";

    private static final String POINTZ = "POINTZ";
    private static final String LINESTRINGZ = "LINESTRINGZ";
    private static final String LINEARRINGZ = "LINEARRINGZ";
    private static final String POLYGONZ = "POLYGONZ";
    private static final String MULTIPOINTZ = "MULTIPOINTZ";
    private static final String MULTILINESTRINGZ = "MULTILINESTRINGZ";
    private static final String MULTIPOLYGONZ = "MULTIPOLYGONZ";
    private static final String GEOMETRYCOLLECTIONZ = "GEOMETRYCOLLECTIONZ";
    
    private static final String POINTM = "POINTM";
    private static final String LINESTRINGM = "LINESTRINGM";
    private static final String LINEARRINGM = "LINEARRINGM";
    private static final String POLYGONM = "POLYGONM";
    private static final String MULTIPOINTM = "MULTIPOINTM";
    private static final String MULTILINESTRINGM = "MULTILINESTRINGM";
    private static final String MULTIPOLYGONM = "MULTIPOLYGONM";
    private static final String GEOMETRYCOLLECTIONM = "GEOMETRYCOLLECTIONM";

	/*
	 * =====================================================================================
	 * Singleton
	 * =======================================================================================
	 */
	public static WKT2JTS instance() {

		return INSTANCE;
	}

	private static final WKT2JTS INSTANCE = new WKT2JTS();

	private WKT2JTS() {

	}

	/*
	 * ===================================================================================== End of
	 * Singleton
	 * =======================================================================================
	 */

	/**
	 * Reads a Well-Known Text representation of a {@link Geometry} from a {@link String}.
	 * 
	 * @param wellKnownText
	 *           one or more <Geometry Tagged Text>strings (see the OpenGIS Simple Features
	 *           Specification) separated by whitespace
	 * @return a <code>Geometry</code> specified by <code>wellKnownText</code>
	 * @throws JASPAGeomParseException
	 *            if a parsing problem occurs
	 */
	public Geometry read(String wellKnownText)
        throws JASPAGeomParseException 
        {
            StringReader reader = new StringReader(wellKnownText);
            try {
                Geometry geom = read(reader, null);
                return geom;
            } finally {
                reader.close();
            }
	}

	/**
	 * Reads a Well-Known Text representation of a {@link Geometry} from a {@link Reader}.
	 * 
	 * @param reader
	 *           a Reader which will return a <Geometry Tagged Text> string (see the OpenGIS Simple
	 *           Features Specification)
	 * @return a <code>Geometry</code> read from <code>reader</code>
	 * @throws JASPAGeomParseException
	 *            if a parsing problem occurs
	 */
	private Geometry read(Reader reader, 
                              GeometryFactory factory)
        throws JASPAGeomParseException 
        {
            StreamTokenizer tokenizer = new StreamTokenizer(reader);
            // set tokenizer to NOT parse numbers
            tokenizer.resetSyntax();
            tokenizer.wordChars('a', 'z');
            tokenizer.wordChars('A', 'Z');
            tokenizer.wordChars(128 + 32, 255);
            tokenizer.wordChars('0', '9');
            tokenizer.wordChars('-', '-');
            tokenizer.wordChars('+', '+');
            tokenizer.wordChars('.', '.');
            tokenizer.whitespaceChars(0, ' ');
            tokenizer.commentChar('#');

            try {
                int SRID[] = new int[1];
                boolean hasSRIDEmbedded = readGeometrySRIDTaggedText(tokenizer, SRID);

                if (factory == null) factory = Core.getInstanceGeometryFactory(SRID[0]);
                return readGeometryTaggedText(tokenizer, factory, hasSRIDEmbedded);
            } catch (IOException e) {
                    throw new JASPAGeomParseException(e);
            } catch (IllegalArgumentException e) {
                    // RunTimeException throws by JTS Geometry Factories
                    throw new JASPAGeomParseException(e);
            } catch (JASPAJTSException e) {
                    throw new JASPAGeomParseException(e);
            }
	}

	/**
	 * Returns the next array of <code>Coordinate</code>s in the stream.
	 * 
	 * @param tokenizer
	 *           tokenizer over a stream of text in Well-known Text format. The next element returned
	 *           by the stream should be L_PAREN (the beginning of "(x1 y1, x2 y2, ..., xn yn)") or
	 *           EMPTY.
	 * @return the next array of <code>Coordinate</code>s in the stream, or an empty array if EMPTY
	 *         is the next element returned by the stream.
	 * @throws IOException
	 *            if an I/O error occurs
	 * @throws JASPAGeomParseException
	 *            if an unexpected token was encountered
	 */
	private Coordinate[] getCoordinates(
			StreamTokenizer tokenizer, 
                        boolean isPostGIS_XYM, 
                        boolean hasLeftParen)
        throws IOException, 
               JASPAGeomParseException 
        {
            String nextToken = null;
            if (hasLeftParen) {
                nextToken = getNextEmptyOrOpener(tokenizer);
                if (nextToken.equals(EMPTY)) // JASPA converts EMPTY geometries to null geometries
                    return null;
                // return new Coordinate[] {};
            }
            List /*SGG<Coordinate>*/ coordinates = new ArrayList/*SGG<Coordinate>*/();
            coordinates.add(getPreciseCoordinate(tokenizer, isPostGIS_XYM));
            nextToken = getNextCloserOrComma(tokenizer);
            while (nextToken.equals(COMMA)) {
                coordinates.add(getPreciseCoordinate(tokenizer, isPostGIS_XYM));
                nextToken = getNextCloserOrComma(tokenizer);
            }
            return (Coordinate[])coordinates.toArray(new Coordinate[] {});
	}

	// jomarlla: support for m coordinate
	private Coordinate getPreciseCoordinate(StreamTokenizer tokenizer, 
                                                boolean isPostGIS_XYM)
        throws IOException, 
               JASPAGeomParseException 
        {
            
            Coordinate coor = null;
            coor = new Coordinate(getNextNumber(tokenizer), getNextNumber(tokenizer));
            
            if (isNumberNext(tokenizer)) {
                coor.z = getNextNumber(tokenizer);
                if (isNumberNext(tokenizer)) {
                    coor.m = getNextNumber(tokenizer);
                }
            }
            
            if (isPostGIS_XYM) {
                if (Double.isNaN(coor.z)) {
                    parseError("number", tokenizer);
                }
                if (!Double.isNaN(coor.m)) {
                    parseError(COMMA + " or " + R_PAREN, tokenizer);
                }
                coor.m = coor.z;
                coor.z = 0;
            }
            
            // TODO
            // factory.getPrecisionModel().makePrecise(coor);
            return coor;
	}

	private boolean isNumberNext(StreamTokenizer tokenizer)
        throws IOException 
        {
            int type = tokenizer.nextToken();
            tokenizer.pushBack();
            return type == StreamTokenizer.TT_WORD;
	}

	/**
	 * Returns the next word in the stream.
	 * 
	 * @param tokenizer
	 *           tokenizer over a stream of text in Well-known Text format. The next token must be a
	 *           word.
	 * @return the next word in the stream as uppercase text
	 * @throws JASPAGeomParseException
	 *            if the next token is not a word
	 * @throws IOException
	 *            if an I/O error occurs
	 */
	private String lookaheadWord(StreamTokenizer tokenizer)
	throws IOException, 
               JASPAGeomParseException 
        {
            String nextWord = getNextWord(tokenizer);
            tokenizer.pushBack();
            return nextWord;
	}

	/**
	 * Parses the next number in the stream. Numbers with exponents are handled. <tt>NaN</tt> values
	 * are handled correctly, and the case of the "NaN" symbol is not significant.
	 * 
	 * @param tokenizer
	 *           tokenizer over a stream of text in Well-known Text format. The next token must be a
	 *           number.
	 * @return the next number in the stream
	 * @throws JASPAGeomParseException
	 *            if the next token is not a valid number
	 * @throws IOException
	 *            if an I/O error occurs
	 */
	private double getNextNumber(StreamTokenizer tokenizer)
        throws IOException, JASPAGeomParseException 
        {
            int type = tokenizer.nextToken();
            switch (type) {
            case StreamTokenizer.TT_WORD: 
                {
                    if (tokenizer.sval.equalsIgnoreCase(NAN_SYMBOL))
                        return Double.NaN;
                    else {
                        try {
                            return Double.parseDouble(tokenizer.sval);
                        } catch (NumberFormatException ex) {
                            throw new JASPAGeomParseException("Invalid number: " + tokenizer.sval);
                        }
                    }
                }
            }
            parseError("number", tokenizer);
            return 0.0;
	}

	/**
	 * Returns the next EMPTY or L_PAREN in the stream as uppercase text.
	 * 
	 * @param tokenizer
	 *           tokenizer over a stream of text in Well-known Text format. The next token must be
	 *           EMPTY or L_PAREN.
	 * @return the next EMPTY or L_PAREN in the stream as uppercase text.
	 * @throws JASPAGeomParseException
	 *            if the next token is not EMPTY or L_PAREN
	 * @throws IOException
	 *            if an I/O error occurs
	 */
	private String getNextEmptyOrOpener(StreamTokenizer tokenizer)
        throws IOException, 
               JASPAGeomParseException 
        {
            String nextWord = getNextWord(tokenizer);
            if (nextWord.equals(EMPTY) || nextWord.equals(L_PAREN)) return nextWord;
            parseError(EMPTY + " or " + L_PAREN, tokenizer);
            return null;
	}

	/**
	 * Returns the next R_PAREN or COMMA in the stream.
	 * 
	 * @param tokenizer
	 *           tokenizer over a stream of text in Well-known Text format. The next token must be
	 *           R_PAREN or COMMA.
	 * @return the next R_PAREN or COMMA in the stream
	 * @throws JASPAGeomParseException
	 *            if the next token is not R_PAREN or COMMA
	 * @throws IOException
	 *            if an I/O error occurs
	 */
	private String getNextCloserOrComma(StreamTokenizer tokenizer)
        throws IOException, JASPAGeomParseException 
        {
            String nextWord = getNextWord(tokenizer);
            if (nextWord.equals(COMMA) || nextWord.equals(R_PAREN)) return nextWord;
            parseError(COMMA + " or " + R_PAREN, tokenizer);
            return null;
	}

	private void getNextComma(StreamTokenizer tokenizer)
			throws IOException, JASPAGeomParseException {

		String nextWord = getNextWord(tokenizer);
		if (nextWord.equals(COMMA)) return;
		parseError(COMMA, tokenizer);
		return;
	}

	private void getNextOpener(StreamTokenizer tokenizer)
			throws IOException, JASPAGeomParseException {

		String nextWord = getNextWord(tokenizer);
		if (nextWord.equals(L_PAREN)) return;
		parseError(L_PAREN, tokenizer);
		return;
	}

	/**
	 * Returns the next R_PAREN in the stream.
	 * 
	 * @param tokenizer
	 *           tokenizer over a stream of text in Well-known Text format. The next token must be
	 *           R_PAREN.
	 * @return the next R_PAREN in the stream
	 * @throws JASPAGeomParseException
	 *            if the next token is not R_PAREN
	 * @throws IOException
	 *            if an I/O error occurs
	 */
	private String getNextCloser(StreamTokenizer tokenizer)
			throws IOException, JASPAGeomParseException {

		String nextWord = getNextWord(tokenizer);
		if (nextWord.equals(R_PAREN)) return nextWord;
		parseError(R_PAREN, tokenizer);
		return null;
	}

	/**
	 * Returns the next word in the stream.
	 * 
	 * @param tokenizer
	 *           tokenizer over a stream of text in Well-known Text format. The next token must be a
	 *           word.
	 * @return the next word in the stream as uppercase text
	 * @throws JASPAGeomParseException
	 *            if the next token is not a word
	 * @throws IOException
	 *            if an I/O error occurs
	 */
	private String getNextWord(StreamTokenizer tokenizer)
			throws IOException, JASPAGeomParseException {

		int type = tokenizer.nextToken();
		switch (type) {
		case StreamTokenizer.TT_WORD:

			String word = tokenizer.sval;
			if (word.equalsIgnoreCase(EMPTY)) return EMPTY;
			return word;

		case '(':
			return L_PAREN;
		case ')':
			return R_PAREN;
		case ',':
			return COMMA;
		case ';':
			return SEMICOLON;
		case '=':
			return EQUAL;
		}
		parseError("word", tokenizer);
		return null;
	}

	/**
	 * Throws a formatted ParseException for the current token.
	 * 
	 * @param expected
	 *           a description of what was expected
	 * @throws JASPAGeomParseException
	 * @throws AssertionFailedException
	 *            if an invalid token is encountered
	 */
	private void parseError(String expected, StreamTokenizer tokenizer)
			throws JASPAGeomParseException {

		// throws Asserts for tokens that should never be seen
		if (tokenizer.ttype == StreamTokenizer.TT_NUMBER) { throw new JASPAGeomParseException(
				"Unexpected NUMBER token"); }
		if (tokenizer.ttype == StreamTokenizer.TT_EOL) { throw new JASPAGeomParseException(
				"Unexpected EOL token"); }

		String tokenStr = tokenString(tokenizer);
		throw new JASPAGeomParseException("Expected " + expected + " but found " + tokenStr);
	}

	/**
	 * Gets a description of the current token
	 * 
	 * @return a description of the current token
	 */
	private String tokenString(StreamTokenizer tokenizer) {

		switch (tokenizer.ttype) {
		case StreamTokenizer.TT_NUMBER:
			return "<NUMBER>";
		case StreamTokenizer.TT_EOL:
			return "End-of-Line";
		case StreamTokenizer.TT_EOF:
			return "End-of-Stream";
		case StreamTokenizer.TT_WORD:
			return "'" + tokenizer.sval + "'";
		}
		return "'" + (char) tokenizer.ttype + "'";
	}

	/**
	 * Creates a <code>Geometry</code> using the next token in the stream.
	 * 
	 * @param tokenizer
	 *           tokenizer over a stream of text in Well-known Text format. The next tokens must form
	 *           a &lt;Geometry Tagged Text&gt;.
	 * @return a <code>Geometry</code> specified by the next token in the stream
	 * @throws JASPAGeomParseException
	 *            if the coordinates used to create a <code>Polygon</code> shell and holes do not
	 *            form closed linestrings, or if an unexpected token was encountered
	 * @throws IOException
	 *            if an I/O error occurs
	 * 
	 *            jomarlla: includes WKT geometries with Z values according to OGC SFS 1.2.0
	 *            jomarlla: Reads embedded SRID (EWKT PostGIS compatible)
	 * @throws JASPAJTSException
	 */
	private Geometry readGeometryTaggedText(
			StreamTokenizer tokenizer, GeometryFactory factory, boolean hasSRIDEmbedded)
        throws IOException, 
               JASPAGeomParseException, 
               JASPAJTSException 
        {
            String type = null;
            
            try {
                type = getNextWord(tokenizer);
            } catch (IOException e) {
                return null;
            } catch (JASPAGeomParseException e) {
                return null;
            }
            
            boolean isPostGIS_XYM = false;
            
            // PostGIS BOX WKT types
            if (type.equalsIgnoreCase(BOX))
                return readBoxPostGISText(false, tokenizer, factory, isPostGIS_XYM, hasSRIDEmbedded); // read
            
            if (type.equalsIgnoreCase(BOX3D))
                return readBoxPostGISText(true, tokenizer, factory, isPostGIS_XYM, hasSRIDEmbedded); 
            // read a two or three dimensional box
            // A geometry that starts with '(' should be a PostgreSQL Box type.
            // Example: (0,0),(10,10)
            if (type.equalsIgnoreCase(this.L_PAREN)) return readBoxPostGresSQLText(tokenizer, factory);

	    if (type.equalsIgnoreCase(POINT) || type.equalsIgnoreCase(POINTZ))
	        return readPointText(tokenizer, factory, isPostGIS_XYM);
	    else if (type.equalsIgnoreCase(LINESTRING) || type.equalsIgnoreCase(LINESTRINGZ))
	        return readLineStringText(tokenizer, factory, isPostGIS_XYM);
	    else if (type.equalsIgnoreCase(LINEARRING) || type.equalsIgnoreCase(LINEARRINGZ))
	        return readLinearRingText(tokenizer, factory, isPostGIS_XYM);
	    else if (type.equalsIgnoreCase(POLYGON) || type.equalsIgnoreCase(POLYGONZ))
	        return readPolygonText(tokenizer, factory, isPostGIS_XYM);
	    else if (type.equalsIgnoreCase(MULTIPOINT) || type.equalsIgnoreCase(MULTIPOINTZ))
	        return readMultiPointText(tokenizer, factory, isPostGIS_XYM);
	    else if (type.equalsIgnoreCase(MULTILINESTRING) || type.equalsIgnoreCase(MULTILINESTRINGZ))
	        return readMultiLineStringText(tokenizer, factory, isPostGIS_XYM);
	    else if (type.equalsIgnoreCase(MULTIPOLYGON) || type.equalsIgnoreCase(MULTIPOLYGONZ))
	        return readMultiPolygonText(tokenizer, factory, isPostGIS_XYM);
	    else if (type.equalsIgnoreCase(GEOMETRYCOLLECTION) || type.equalsIgnoreCase(GEOMETRYCOLLECTIONZ))
	        return readGeometryCollectionText(tokenizer, factory, hasSRIDEmbedded);
            else if (type.equalsIgnoreCase(POINTM)) {
                isPostGIS_XYM = true;
		return readPointText(tokenizer, factory, isPostGIS_XYM);
            } else if (type.equalsIgnoreCase(LINESTRINGM)) {
                isPostGIS_XYM = true;
                return readLineStringText(tokenizer, factory, isPostGIS_XYM);
            } else if (type.equalsIgnoreCase(LINEARRINGM)) {
                isPostGIS_XYM = true;
                return readLinearRingText(tokenizer, factory, isPostGIS_XYM);
            } else if (type.equalsIgnoreCase(POLYGONM)) {
                isPostGIS_XYM = true;
		return readPolygonText(tokenizer, factory, isPostGIS_XYM);
            } else if (type.equalsIgnoreCase(MULTIPOINTM)) {
                isPostGIS_XYM = true;
                return readMultiPointText(tokenizer, factory, isPostGIS_XYM);
            } else if (type.equalsIgnoreCase(MULTILINESTRINGM)) {
                isPostGIS_XYM = true;
                return readMultiLineStringText(tokenizer, factory, isPostGIS_XYM);
            } else if (type.equalsIgnoreCase(MULTIPOLYGONM)) {
                isPostGIS_XYM = true;
                return readMultiPolygonText(tokenizer, factory, isPostGIS_XYM);
            } else if (type.equalsIgnoreCase(GEOMETRYCOLLECTIONM)) {
                isPostGIS_XYM = true;
                return readGeometryCollectionText(tokenizer, factory, hasSRIDEmbedded);
            }
            throw new JASPAGeomParseException("Unknown geometry type: " + type);
	}

	/**
	 * Creates a <code>Point</code> using the next token in the stream.
	 * 
	 * @param tokenizer
	 *           tokenizer over a stream of text in Well-known Text format. The next tokens must form
	 *           a &lt;Point Text&gt;.
	 * @return a <code>Point</code> specified by the next token in the stream
	 * @throws JASPAGeomParseException
	 * @throws IOException
	 * @throws
	 * @throws IOException
	 * @throws IOException
	 *            if an I/O error occurs
	 * @throws JASPAGeomParseException
	 *            if an unexpected token was encountered
	 */
	private Point readPointText(
			StreamTokenizer tokenizer, GeometryFactory factory, boolean isPostGIS_XYM)
			throws IOException, JASPAGeomParseException {

		String nextToken = getNextEmptyOrOpener(tokenizer);
		if (nextToken.equals(EMPTY)) // JASPA converts EMPTY geometries to null geometries
			return null;
		Point point = factory.createPoint(getPreciseCoordinate(tokenizer, isPostGIS_XYM));

		// if (point != null) point.setSRID(SRID);

		getNextCloser(tokenizer);

		return point;
	}

	private Polygon readBoxPostGISText(
			boolean is3D, StreamTokenizer tokenizer, GeometryFactory factory, boolean isPostGIS_XYM,
			boolean hasSRIDEmbedded)
			throws IOException, JASPAGeomParseException, JASPAJTSException {

		if (hasSRIDEmbedded)
			throw new JASPAGeomParseException("PostGIS BOX types can not have an embedded SRID");

		String nextToken = getNextEmptyOrOpener(tokenizer);
		if (nextToken.equals(EMPTY)) return null;

		Coordinate leftBottom = null;
		Coordinate rightTop = null;

		leftBottom = getPreciseCoordinate(tokenizer, isPostGIS_XYM);
		nextToken = getNextCloserOrComma(tokenizer);
		if (nextToken.equals(COMMA)) {
			rightTop = getPreciseCoordinate(tokenizer, isPostGIS_XYM);
		}

		getNextCloser(tokenizer);
		if (!is3D) {
			// hasZ value in a two dimensional box
			if ((!Double.isNaN(leftBottom.z)) || (!Double.isNaN(rightTop.z)))
				throw new JASPAGeomParseException(
						"PostGIS BOX is a two dimensional type. It should look like: BOX(xmin ymin,xmax ymax)");
		}

		Core.orderCoordinates(leftBottom, rightTop);

		Polygon res = Core.getJTSPolygonFromBOX(factory, leftBottom, rightTop, (is3D) ? 3 : 2);

		return res;
	}

	private Polygon readBoxPostGresSQLText(StreamTokenizer tokenizer, GeometryFactory factory)
			throws IOException, JASPAGeomParseException, JASPAJTSException {

		double xmin = getNextNumber(tokenizer);
		getNextComma(tokenizer);
		double ymin = getNextNumber(tokenizer);
		getNextCloser(tokenizer);
		getNextComma(tokenizer);
		getNextOpener(tokenizer);
		double xmax = getNextNumber(tokenizer);
		getNextComma(tokenizer);
		double ymax = getNextNumber(tokenizer);
		getNextCloser(tokenizer);

		Coordinate leftBottom = new Coordinate(xmin, ymin);
		Coordinate rightTop = new Coordinate(xmax, ymax);

		Polygon res = Core.getJTSPolygonFromBOX(factory, leftBottom, rightTop, 2);

		return res;
	}

	/**
	 * Creates a <code>LineString</code> using the next token in the stream.
	 * 
	 * @param tokenizer
	 *           tokenizer over a stream of text in Well-known Text format. The next tokens must form
	 *           a &lt;LineString Text&gt;.
	 * @return a <code>LineString</code> specified by the next token in the stream
	 * @throws JASPAGeomParseException
	 * @throws IOException
	 * @throws IOException
	 *            if an I/O error occurs
	 * @throws JASPAGeomParseException
	 *            if an unexpected token was encountered
	 */
	private LineString readLineStringText(
			StreamTokenizer tokenizer, GeometryFactory factory, boolean isPostGIS_XYM)
			throws IOException, JASPAGeomParseException {

		Coordinate[] coordinates = getCoordinates(tokenizer, isPostGIS_XYM, true);

		// EMTPY Geometry
		if (coordinates == null) return null;

		LineString geom = factory.createLineString(coordinates);
		// LineString geom = geometryFactory.createLineString(getCoordinates(tokenizer,
		// isPostGIS_XYM));

		// if (geom != null) geom.setSRID(SRID);
		return geom;
	}

	/**
	 * Creates a <code>LinearRing</code> using the next token in the stream.
	 * 
	 * @param tokenizer
	 *           tokenizer over a stream of text in Well-known Text format. The next tokens must form
	 *           a &lt;LineString Text&gt;.
	 * @return a <code>LinearRing</code> specified by the next token in the stream
	 * @throws IOException
	 *            if an I/O error occurs
	 * @throws JASPAGeomParseException
	 *            if the coordinates used to create the <code>LinearRing</code> do not form a closed
	 *            linestring, or if an unexpected token was encountered
	 */
	private LinearRing readLinearRingText(
			StreamTokenizer tokenizer, GeometryFactory factory, boolean isPostGIS_XYM)
			throws IOException, JASPAGeomParseException {

		Coordinate[] coordinates = getCoordinates(tokenizer, isPostGIS_XYM, true);

		if (coordinates == null) return null;

		LinearRing geom = factory.createLinearRing(coordinates);
		// if (geom != null) geom.setSRID(SRID);
		return geom;
	}

	private static final boolean ALLOW_OLD_JTS_MULTIPOINT_SYNTAX = true;

	/**
	 * Creates a <code>MultiPoint</code> using the next token in the stream.
	 * 
	 * @param tokenizer
	 *           tokenizer over a stream of text in Well-known Text format. The next tokens must form
	 *           a &lt;MultiPoint Text&gt;.
	 * @return a <code>MultiPoint</code> specified by the next token in the stream
	 * @throws IOException
	 *            if an I/O error occurs
	 * @throws JASPAGeomParseException
	 *            if an unexpected token was encountered
	 */
	private MultiPoint readMultiPointText(
			StreamTokenizer tokenizer, GeometryFactory factory, boolean isPostGIS_XYM)
			throws IOException, JASPAGeomParseException {

		String nextToken = getNextEmptyOrOpener(tokenizer);
		if (nextToken.equals(EMPTY)) // JASPA converts EMPTY geometries to null geometries
			return null;

		// check for old-style JTS syntax and parse it if present
		// MD 2009-02-21 - this is only provided for backwards compatibility for a few versions
		if (ALLOW_OLD_JTS_MULTIPOINT_SYNTAX) {
			String nextWord = lookaheadWord(tokenizer);
			if (nextWord != L_PAREN) {
				Coordinate[] coordinates = getCoordinates(tokenizer, isPostGIS_XYM, false);

				if (coordinates == null) return null;

				factory.createMultiPoint(coordinates);
				MultiPoint res = factory.createMultiPoint(coordinates);
				// if (res != null) res.setSRID(SRID);

				return res;
			}
		}

		List/*SGG<Point>*/ points = new ArrayList/*SGG<Point>*/();
		Point point = readPointText(tokenizer, factory, isPostGIS_XYM);
		if (point != null) {
                    points.add(point);
		}

		nextToken = getNextCloserOrComma(tokenizer);
		while (nextToken.equals(COMMA)) {
			point = readPointText(tokenizer, factory, isPostGIS_XYM);
			if (point != null) {
				points.add(point);
			}
			nextToken = getNextCloserOrComma(tokenizer);
		}

		if (points.size() == 0) return null;

		Point[] array = (Point[])points.toArray(new Point[] {});
		MultiPoint res = factory.createMultiPoint(array);
		/*
		Point[] array = new Point[points.size()];
		MultiPoint res = factory.createMultiPoint((Point[]) points.toArray(array));
		/*
		 * 
		 */
		// if (res != null) res.setSRID(SRID);

		return res;
	}

	/**
	 * Creates an array of <code>Point</code>s having the given <code>Coordinate</code> s.
	 * 
	 * @param coordinates
	 *           the <code>Coordinate</code>s with which to create the <code>Point</code>s
	 * @return <code>Point</code>s created using this <code>WKTReader</code> s
	 *         <code>GeometryFactory</code>
	 */
	private Point[] toPoints(Coordinate[] coordinates, GeometryFactory factory) {

		List/*SGG<Point>*/ points = new ArrayList/*SGG<Point>*/();
		for (int i = 0; i < coordinates.length; i++) {
                    Point geom = factory.createPoint(coordinates[i]);
		    // geom.setSRID(SRID);
		    points.add(geom);
		}
		return (Point[])points.toArray(new Point[] {});
                /* SGG Core.list2Array(points, new Point[] {});*/
	}

	/**
	 * Creates a <code>Polygon</code> using the next token in the stream.
	 * 
	 * @param tokenizer
	 *           tokenizer over a stream of text in Well-known Text format. The next tokens must form
	 *           a &lt;Polygon Text&gt;.
	 * @return a <code>Polygon</code> specified by the next token in the stream
	 * @throws JASPAGeomParseException
	 *            if the coordinates used to create the <code>Polygon</code> shell and holes do not
	 *            form closed linestrings, or if an unexpected token was encountered.
	 * @throws IOException
	 *            if an I/O error occurs
	 */
	private Polygon readPolygonText(
			StreamTokenizer tokenizer, GeometryFactory factory, boolean isPostGIS_XYM)
			throws IOException, JASPAGeomParseException {

		String nextToken = getNextEmptyOrOpener(tokenizer);
		if (nextToken.equals(EMPTY)) // JASPA converts EMPTY geometries to null geometries
			return null;
		/*
		 * return geometryFactory .createPolygon(geometryFactory .createLinearRing(new Coordinate[]
		 * {}), new LinearRing[] {});
		 */
		List/*SGG<LinearRing>*/ holes = new ArrayList/*SGG<LinearRing>*/();
		LinearRing shell = readLinearRingText(tokenizer, factory, isPostGIS_XYM);

		// If the LinearRingText is empty then readLinearRingText will return null
		if (shell == null) return null;
		// shell.setSRID(SRID);

		nextToken = getNextCloserOrComma(tokenizer);
		while (nextToken.equals(COMMA)) {
			LinearRing hole = readLinearRingText(tokenizer, factory, isPostGIS_XYM);
			if (hole != null) {
				// hole.setSRID(SRID);
				holes.add(hole);
			}
			nextToken = getNextCloserOrComma(tokenizer);
		}

                // SGG Polygon geom = factory.createPolygon(shell, Core.list2Array(holes, new LinearRing[] {}));
                Polygon geom = factory.createPolygon(shell, (LinearRing[])holes.toArray(new LinearRing[] {}));
		// if (geom != null) geom.setSRID(SRID);
		return geom;
	}

	/**
	 * Creates a <code>MultiLineString</code> using the next token in the stream.
	 * 
	 * @param tokenizer
	 *           tokenizer over a stream of text in Well-known Text format. The next tokens must form
	 *           a &lt;MultiLineString Text&gt;.
	 * @return a <code>MultiLineString</code> specified by the next token in the stream
	 * @throws IOException
	 *            if an I/O error occurs
	 * @throws JASPAGeomParseException
	 *            if an unexpected token was encountered
	 */
	private MultiLineString readMultiLineStringText(
			StreamTokenizer tokenizer, GeometryFactory factory, boolean isPostGIS_XYM)
			throws IOException, JASPAGeomParseException {

		String nextToken = getNextEmptyOrOpener(tokenizer);
		if (nextToken.equals(EMPTY)) // JASPA converts EMPTY geometries to null geometries
			return null;
		// return geometryFactory.createMultiLineString(new LineString[] {});
		List/*SGG<LinearRing>*/ lineStrings = new ArrayList/*SGG<LinearRing>*/();
		LineString lineString = readLineStringText(tokenizer, factory, isPostGIS_XYM);

		// If the lineString is empty then readLineStringText will return null
		if (lineString != null) {
			lineStrings.add(lineString);
		}
		nextToken = getNextCloserOrComma(tokenizer);
		while (nextToken.equals(COMMA)) {
			lineString = readLineStringText(tokenizer, factory, isPostGIS_XYM);
			if (lineString != null) {
				lineStrings.add(lineString);
			}

			nextToken = getNextCloserOrComma(tokenizer);
		}

		if (lineStrings.size() == 0) return null;

		MultiLineString geom = factory.createMultiLineString((LineString[])lineStrings.toArray(new LineString[] {}));
		// if (geom != null) geom.setSRID(SRID);
		return geom;
	}

	/**
	 * Creates a <code>MultiPolygon</code> using the next token in the stream.
	 * 
	 * @param tokenizer
	 *           tokenizer over a stream of text in Well-known Text format. The next tokens must form
	 *           a &lt;MultiPolygon Text&gt;.
	 * @return a <code>MultiPolygon</code> specified by the next token in the stream, or if if the
	 *         coordinates used to create the <code>Polygon</code> shells and holes do not form
	 *         closed linestrings.
	 * @throws IOException
	 *            if an I/O error occurs
	 * @throws JASPAGeomParseException
	 *            if an unexpected token was encountered
	 */
	private MultiPolygon readMultiPolygonText(
			StreamTokenizer tokenizer, GeometryFactory factory, boolean isPostGIS_XYM)
			throws IOException, JASPAGeomParseException {

		String nextToken = getNextEmptyOrOpener(tokenizer);
		if (nextToken.equals(EMPTY)) // JASPA converts EMPTY geometries to null geometries
			return null;
		// return geometryFactory.createMultiPolygon(new Polygon[] {});
		List/*SGG<Polygon>*/ polygons = new ArrayList/*SGG<Polygon>*/();
		Polygon polygon = readPolygonText(tokenizer, factory, isPostGIS_XYM);
		if (polygon == null) return null;

		polygons.add(polygon);
		nextToken = getNextCloserOrComma(tokenizer);
		while (nextToken.equals(COMMA)) {
			polygon = readPolygonText(tokenizer, factory, isPostGIS_XYM);

			// If the polygon is empty then readPolygonText will return null
			if (polygon != null) {
				polygons.add(polygon);
			}
			nextToken = getNextCloserOrComma(tokenizer);
		}
		if (polygons.size() == 0) return null;

		MultiPolygon geom = factory.createMultiPolygon((Polygon[])polygons.toArray(new Polygon[] {}));
		// if (geom != null) geom.setSRID(SRID);
		return geom;
	}

	/**
	 * Creates a <code>GeometryCollection</code> using the next token in the stream.
	 * 
	 * @param tokenizer
	 *           tokenizer over a stream of text in Well-known Text format. The next tokens must form
	 *           a &lt;GeometryCollection Text&gt;.
	 * @return a <code>GeometryCollection</code> specified by the next token in the stream
	 * @throws JASPAGeomParseException
	 *            if the coordinates used to create a <code>Polygon</code> shell and holes do not
	 *            form closed linestrings, or if an unexpected token was encountered
	 * @throws IOException
	 *            if an I/O error occurs
	 * @throws JASPAJTSException
	 */
	private GeometryCollection readGeometryCollectionText(
			StreamTokenizer tokenizer, GeometryFactory factory, boolean hasSRIDEmbedded)
			throws IOException, JASPAGeomParseException, JASPAJTSException {

		String nextToken = getNextEmptyOrOpener(tokenizer);
		if (nextToken.equals(EMPTY)) // JASPA converts EMPTY geometries to null geometries
			return null;
		// return geometryFactory.createGeometryCollection(new Geometry[] {});
		List/*SGG<Geometry>*/ geometries = new ArrayList/*SGG<Geometry>*/();
		Geometry geometry = readGeometryTaggedText(tokenizer, factory, hasSRIDEmbedded);

		// If the geometry is empty then readGeometryTaggedText will return null
		if (geometry != null) {
			geometries.add(geometry);
		}

		nextToken = getNextCloserOrComma(tokenizer);
		while (nextToken.equals(COMMA)) {
			geometry = readGeometryTaggedText(tokenizer, factory, hasSRIDEmbedded);
			// If the geometry is empty then readGeometryTaggedText will return null
			if (geometry != null) {
				geometries.add(geometry);
			}
			nextToken = getNextCloserOrComma(tokenizer);
		}

		if (geometries.size() == 0) return null;

        GeometryCollection geom = factory.createGeometryCollection((Geometry[])geometries.toArray(new Geometry[] {}));
		// if (geom != null) geom.setSRID(SRID);
		return geom;
	}

	// Extended functionality by jomarlla
	private String getNextEqual(StreamTokenizer tokenizer)
			throws IOException, JASPAGeomParseException {

		String nextWord = getNextWord(tokenizer);
		if (nextWord.equals(EQUAL)) return nextWord;
		parseError(EQUAL, tokenizer);
		return null;
	}

	private String getNextSemiColon(StreamTokenizer tokenizer)
			throws IOException, JASPAGeomParseException {

		String nextWord = getNextWord(tokenizer);
		if (nextWord.equals(SEMICOLON)) return nextWord;
		parseError(SEMICOLON, tokenizer);
		return null;
	}

	private int readSRID(StreamTokenizer tokenizer)
			throws IOException, JASPAGeomParseException {

		getNextEqual(tokenizer);

		int SRID = getNextIntegerNumber(tokenizer);

		// PostGIS Default SRID
		// if (SRID == -1) SRID = 0;
		getNextSemiColon(tokenizer);

		return SRID;
	}

	private int getNextIntegerNumber(StreamTokenizer tokenizer)
			throws IOException, JASPAGeomParseException {

		int type = tokenizer.nextToken();
		switch (type) {
		case StreamTokenizer.TT_WORD: {
			if (tokenizer.sval.equalsIgnoreCase(NAN_SYMBOL))
				return -1;
			else {
				try {
					return Integer.parseInt(tokenizer.sval);
				} catch (NumberFormatException ex) {
					throw new JASPAGeomParseException("Invalid Integer number: " + tokenizer.sval);
				}
			}
		}
		}

		parseError("number", tokenizer);
		return -1;
	}

	private boolean readGeometrySRIDTaggedText(StreamTokenizer tokenizer, int SRID[])
			throws IOException, JASPAGeomParseException {

		String type = null;

		// PostGIS Default SRID = -1
		SRID[0] = BinaryFormat.defaultSRID;

		try {
			type = getNextWord(tokenizer);
		} catch (IOException e) {
			return false;
		} catch (JASPAGeomParseException e) {
			return false;
		}

		if (type.equalsIgnoreCase("SRID")) {
			SRID[0] = readSRID(tokenizer);

			// hasSRIDEmbedded = true;
			return true;
		} else {
			tokenizer.pushBack();
			// hasSRIDEmbedded = false;
			return false;
		}
	}
}
