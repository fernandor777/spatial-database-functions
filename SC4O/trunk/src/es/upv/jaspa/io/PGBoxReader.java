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

package es.upv.jaspa.io;

import java.io.IOException;
import java.io.Reader;
import java.io.StreamTokenizer;
import java.io.StringReader;


import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.LinearRing;
import org.locationtech.jts.geom.Polygon;
import org.locationtech.jts.util.AssertionFailedException;

import es.upv.jaspa.Core;
import es.upv.jaspa.exceptions.JASPAGeomParseException;

/**
 * @author Jose Martinez-Llario
 * 
 */
public class PGBoxReader {
	private static final String COMMA = ",";
	private static final String NAN_SYMBOL = "NaN";

	private static final PGBoxReader INSTANCE = new PGBoxReader();

	public static PGBoxReader getInstance() {

		return INSTANCE;
	}

	private PGBoxReader() {

	}

	public Geometry read(String wellKnownText)
			throws JASPAGeomParseException {

		if (!(wellKnownText == null || wellKnownText.equals(""))) {

			StringReader reader = new StringReader(wellKnownText);
			try {
				return read(reader);
			} finally {
				reader.close();
			}
		}

		return null;
	}

	private Geometry read(Reader reader)
			throws JASPAGeomParseException {

		StreamTokenizer tokenizer = new StreamTokenizer(reader);
		tokenizer.resetSyntax();
		tokenizer.wordChars('0', '9');
		tokenizer.wordChars('.', '.');
		tokenizer.whitespaceChars(0, ' ');
		tokenizer.whitespaceChars(',', ',');
		tokenizer.whitespaceChars('(', '(');
		tokenizer.whitespaceChars(')', ')');

		try {
			return readBoxText(tokenizer);
		} catch (IOException e) {
			throw new JASPAGeomParseException(e.toString());
		}
	}

	private Geometry readBoxText(StreamTokenizer tokenizer)
			throws IOException, JASPAGeomParseException {

		double xmax;
		double ymax;
		double xmin;
		double ymin;

		xmax = getNextNumber(tokenizer);
		ymax = getNextNumber(tokenizer);
		xmin = getNextNumber(tokenizer);
		ymin = getNextNumber(tokenizer);

		// create a factory using default values (e.g. floating precision)
		GeometryFactory fact = Core.getInstanceGeometryFactory();

		Coordinate vertex[] = new Coordinate[5];
		vertex[0] = new Coordinate(xmin, ymax);
		vertex[1] = new Coordinate(xmax, ymax);
		vertex[2] = new Coordinate(xmax, ymin);
		vertex[3] = new Coordinate(xmin, ymin);
		vertex[4] = new Coordinate(xmin, ymax);

		LinearRing lr = fact.createLinearRing(vertex);
		Polygon pl = fact.createPolygon(lr, null);

		return pl;

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
			throws IOException, JASPAGeomParseException {

		int type = tokenizer.nextToken();
		switch (type) {
		case StreamTokenizer.TT_WORD: {
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
	private String getNextComma(StreamTokenizer tokenizer)
			throws IOException, JASPAGeomParseException {

		String nextWord = getNextWord(tokenizer);
		if (nextWord.equals(COMMA)) return nextWord;
		parseError(COMMA, tokenizer);
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
			return word;

		case ',':
			return COMMA;
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
}
