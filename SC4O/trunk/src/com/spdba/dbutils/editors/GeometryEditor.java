package com.spdba.dbutils.editors;

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
import org.locationtech.jts.util.Assert;

/**
 * A class which supports creating new {@link Geometry}s which are modifications of existing ones.
 * Geometry objects are intended to be treated as immutable. This class "modifies" Geometrys by
 * traversing them, applying a user-defined {@link GeometryEditOperation} or
 * {@link CoordinateOperation} and creating new Geometrys with the same structure but (possibly)
 * modified components.
 * <p>
 * Examples of the kinds of modifications which can be made are:
 * <ul>
 * <li>the values of the coordinates may be changed. The editor does not check whether changing
 * coordinate values makes the result Geometry invalid
 * <li>the coordinate lists may be changed (e.g. by adding or deleting coordinates). The modifed
 * coordinate lists must be consistent with their original parent component (e.g. a LinearRing must
 * always have at least 4 coordinates, and the first and last coordinate must be equal)
 * <li>components of the original geometry may be deleted ( e.g. holes may be removed from a
 * Polygon, or LineStrings removed from a MultiLineString). Deletions will be propagated up the
 * component tree appropriately.
 * </ul>
 * All changes must be consistent with the original Geometry's structure (e.g. a <tt>Polygon</tt>
 * cannot be collapsed into a <tt>LineString</tt>). If changing the structure is required, use a
 * {@link GeometryTransformer}.
 * <p>
 * This class supports the case where an edited Geometry needs to be created under a new
 * GeometryFactory, via the {@link GeometryEditor(GeometryFactory)} constructor. Examples of
 * situations where this is required is if the geometry is transformed to a new SRID and/or a new
 * PrecisionModel.
 * <p>
 * The resulting Geometry is not checked for validity. If validity needs to be enforced, the new
 * Geometry's {@link #isValid} method should be called.
 * 
 * @see GeometryTransformer
 * @see Geometry#isValid
 * 
 * @version 1.7
 */
public class GeometryEditor {
	/**
	 * The factory used to create the modified Geometry. If <tt>null</tt> the GeometryFactory of the
	 * input is used.
	 */
	private GeometryFactory factory = null;

	/**
	 * Creates a new GeometryEditor object which will create edited {@link Geometry}s with the same
	 * {@link GeometryFactory} as the input Geometry.
	 */
	public GeometryEditor() {

	}

	/**
	 * Creates a new GeometryEditor object which will create edited {@link Geometry}s with the given
	 * {@link GeometryFactory}.
	 * 
	 * @param factory
	 *           the GeometryFactory to create edited Geometrys with
	 */
	public GeometryEditor(GeometryFactory factory) {

		this.factory = factory;
	}

	/**
	 * Edit the input {@link Geometry} with the given edit operation. Clients can create subclasses
	 * of {@link GeometryEditorOperation} or {@link CoordinateOperation} to perform required
	 * modifications.
	 * 
	 * @param geometry
	 *           the Geometry to edit
	 * @param operation
	 *           the edit operation to carry out
	 * @return a new {@link Geometry} which is the result of the editing
	 */
	public Geometry edit(Geometry geometry, GeometryEditorOperation operation) {
		// nothing to do
		if (geometry == null) return null;

		// if client did not supply a GeometryFactory, use the one from the
		// input Geometry
		if (factory == null) {
			factory = geometry.getFactory();
		}

		if (geometry instanceof GeometryCollection) { 
                    return editGeometryCollection((GeometryCollection) geometry, operation); 
                }

		if (geometry instanceof Polygon) { 
                    return editPolygon((Polygon) geometry, operation); 
                }

		if (geometry instanceof Point) { 
                    return operation.edit(geometry, factory); 
                }

		if (geometry instanceof LineString) { 
                    return operation.edit(geometry, factory); 
                }

		Assert.shouldNeverReachHere("Unsupported Geometry class: " + geometry.getClass().getName());
		return null;
	}

	private Polygon editPolygon(Polygon polygon, GeometryEditorOperation operation) {

		Polygon newPolygon = (Polygon) operation.edit(polygon, factory);

		/*
		 * if (newPolygon.isEmpty()) { //RemoveSelectedPlugIn relies on this behaviour. [Jon Aquino]
		 * return newPolygon; }
		 */
		// jomarlla
		if ((newPolygon == null) || (newPolygon.isEmpty())) return null;

		LinearRing shell = (LinearRing) edit(newPolygon.getExteriorRing(), operation);

		/*
		 * if (shell.isEmpty()) { //RemoveSelectedPlugIn relies on this behaviour. [Jon Aquino] return
		 * factory.createPolygon(null, null); }
		 */
		// jomarlla
		if (shell.isEmpty()) return null;

		List/*SGG<LinearRing>*/ holes = new ArrayList/*SGG<LinearRing>*/();

		for (int i = 0; i < newPolygon.getNumInteriorRing(); i++) {
                    LinearRing hole = (LinearRing) edit(newPolygon.getInteriorRingN(i), operation);
                    if (hole.isEmpty()) {
                        continue;
                    }
                    holes.add(hole);
		}

		return factory.createPolygon(shell, (LinearRing[])holes.toArray(new LinearRing[] {}));
	}

	private GeometryCollection editGeometryCollection(GeometryCollection collection, 
                                                          GeometryEditorOperation operation) 
        {
            GeometryCollection newCollection = (GeometryCollection) operation.edit(collection, factory);
            if ((newCollection) == null || (newCollection.isEmpty())) return null; // jomarlla

		List/*SGG<Geometry>*/ geometries = new ArrayList/*SGG<Geometry>*/();

		for (int i = 0; i < newCollection.getNumGeometries(); i++) {
                    Geometry geometry = edit(newCollection.getGeometryN(i), operation);
                    if ((geometry == null) || (geometry.isEmpty())) { // jomarlla
                        continue;
                    }
                    if ( newCollection.getClass() == MultiPoint.class ) {
                        if ( geometry.getNumPoints() == 1 ) {
                            geometries.add(geometry);
                        } else {
                            for (int p=0;p<geometry.getNumPoints();p++)
                                geometries.add(geometry.getGeometryN(p));
                        }
                    } else {
                        geometries.add(geometry);
                    }
		}

		if (newCollection.getClass() == MultiPoint.class) { 
                    return factory.createMultiPoint((Point[]) geometries.toArray(new Point[] {})); }

		if (newCollection.getClass() == MultiLineString.class) { 
                    return factory.createMultiLineString((LineString[]) geometries.toArray(new LineString[] {})); }

		if (newCollection.getClass() == MultiPolygon.class) { 
                    return factory.createMultiPolygon((Polygon[]) geometries.toArray(new Polygon[] {})); }

		return factory.createGeometryCollection((Geometry[]) geometries.toArray(new Geometry[] {}));
	}

	/**
	 * A interface which specifies an edit operation for Geometries.
	 * 
	 * @version 1.7
	 */
	public interface GeometryEditorOperation {
		/**
		 * Edits a Geometry by returning a new Geometry with a modification. The returned Geometry
		 * might be the same as the Geometry passed in.
		 * 
		 * @param geometry
		 *           the Geometry to modify
		 * @param factory
		 *           the factory with which to construct the modified Geometry (may be different to
		 *           the factory of the input geometry)
		 * @return a new Geometry which is a modification of the input Geometry
		 */
		Geometry edit(Geometry geometry, GeometryFactory factory);
	}

	// Original class from JTS
	/*
	 * public abstract static class CoordinateOperation implements GeometryEditorOperation { public
	 * final Geometry edit(Geometry geometry, GeometryFactory factory) { if (geometry instanceof
	 * LinearRing) { return factory.createLinearRing(edit(geometry.getCoordinates(), geometry)); }
	 * 
	 * if (geometry instanceof LineString) { return
	 * factory.createLineString(edit(geometry.getCoordinates(), geometry)); }
	 * 
	 * if (geometry instanceof Point) { Coordinate[] newCoordinates = edit(geometry.getCoordinates(),
	 * geometry);
	 * 
	 * return factory.createPoint((newCoordinates.length > 0) ? newCoordinates[0] : null); }
	 * 
	 * return geometry; }
	 * 
	 * 
	 * public abstract Coordinate[] edit(Coordinate[] coordinates, Geometry geometry); }
	 */
	/**
	 * A {@link GeometryEditorOperation} which modifies the coordinate list of a {@link Geometry}.
	 * Operates on Geometry subclasses which contains a single coordinate list.
	 */
	public abstract static class CoordinateOperation implements GeometryEditorOperation {
            
		public final Geometry edit(Geometry geometry, GeometryFactory factory) {

			if (geometry instanceof LinearRing) {
				Coordinate source[] = geometry.getCoordinates();
				Coordinate modifiedSource[] = edit(source, geometry);
				if (modifiedSource == null) return null;

				if (source != modifiedSource)
					return factory.createLinearRing(modifiedSource);
				else
					return geometry;
			}

			if (geometry instanceof LineString) {
				Coordinate source[] = geometry.getCoordinates();
				Coordinate modifiedSource[] = edit(source, geometry);
				if (modifiedSource == null) return null;

				if (source != modifiedSource)
					return factory.createLineString(modifiedSource);
				else
					return geometry;
			}

			if (geometry instanceof Point) {
				Coordinate source[] = geometry.getCoordinates();
				Coordinate modifiedSource[] = edit(source, geometry);
				if (modifiedSource == null) return null;

                                if (source != modifiedSource) {
                                    if ( modifiedSource.length == 0 ) return geometry; 
                                    if ( modifiedSource.length == 1 ) return factory.createPoint(modifiedSource[0]); 
                                    return factory.createMultiPoint(modifiedSource); 
                                } else {
                                    return geometry;
                                }
			}

			return geometry;
		}

		/**
		 * Edits the array of {@link Coordinate}s from a {@link Geometry}.
		 * <p>
		 * If it is desired to preserve the immutability of Geometrys, if the coordinates are changed
		 * a new array should be created and returned.
		 * 
		 * @param coordinates
		 *           the coordinate array to operate on
		 * @param geometry
		 *           the geometry containing the coordinate list
		 * @return an edited coordinate array (which may be the same as the input)
		 */
		public abstract Coordinate[] edit(Coordinate[] coordinates, Geometry geometry);
	}

}