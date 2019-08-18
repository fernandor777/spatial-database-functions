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

package es.upv.jaspa;

import java.util.List;


import org.locationtech.jts.geom.Geometry;

import es.upv.jaspa.exceptions.JASPAGeomMismatchException;

import java.util.Arrays;
import java.util.Iterator;

/**
 * @author Jose Martinez-Llario
 *
 */
public class GeomProperties {
	private boolean hasValues;
	private int srid;
	private int coorDimension;

	public GeomProperties(int srid, int coorDimension) {

		this.srid = srid;
		this.coorDimension = coorDimension;
		hasValues = true;
	}

	public GeomProperties(Geometry geom) {

		if (Core.isNullGeometry(geom)) {
			hasValues = false;
		} else {
			this.srid = geom.getSRID();
			this.coorDimension = Core.calculateDimensionOfGeometryCoordinates(geom);
		}
	}

	public boolean errorIfDifferentSRIDorCoorDim(Geometry geom)
			throws JASPAGeomMismatchException {

		if (Core.isNullGeometry(geom)) return true;

		return errorIfDifferentSRIDorCoorDim(geom.getSRID(),
				Core.calculateDimensionOfGeometryCoordinates(geom));
	}

	public boolean errorIfDifferentSRIDorCoorDim(int srid, int coorDimension)
			throws JASPAGeomMismatchException {

		if (!hasValues) return true;

		errorIfDifferentSRIDs(this.srid, srid);
		errorIfDifferentCoorDims(this.coorDimension, coorDimension);

		return false;
	}

	public int getSrid() {

		return srid;
	}

	public void setSrid(int srid) {

		this.srid = srid;
	}

	public int getCoorDimension() {

		return coorDimension;
	}

	public void setCoorDimension(int coorDimension) {

		this.coorDimension = coorDimension;
	}

	private static void errorIfDifferentSRIDs(int SRID0, int SRID1)
			throws JASPAGeomMismatchException {

		if (SRID0 != SRID1) { throw new JASPAGeomMismatchException(
				"The geometries must have the same SRID: found SRIDs " + SRID0 + " and " + SRID1); }

		return;
	}

	private static void errorIfDifferentCoorDims(int dim0, int dim1)
			throws JASPAGeomMismatchException {

		if (dim0 != dim1) { throw new JASPAGeomMismatchException(
				"The geometries must have the same coordinate dimension: found dimensions " + dim0
						+ " and " + dim1); }

		return;
	}

	/**
	 * @param geom0
	 *           Might be null or empty
	 * @param geom1
	 *           Might be null or empty
	 * @return True if the list is null or all the geometries are null or empty. False if there is
	 *         one geometry or more than one but with compatible srid and coordinate dimensions even
	 *         if there are some null geometry
	 * @throws JASPAGeomMismatchException
	 */
	public static boolean errorIfDifferentSRIDorCoorDim(Geometry geom0, Geometry geom1)
			throws JASPAGeomMismatchException {

		if (Core.isNullGeometry(geom0)) return true;
		if (Core.isNullGeometry(geom1)) return true;

		errorIfDifferentSRIDs(geom0.getSRID(), geom1.getSRID());

		int dim0 = Core.calculateDimensionOfGeometryCoordinates(geom0);
		int dim1 = Core.calculateDimensionOfGeometryCoordinates(geom1);

		errorIfDifferentCoorDims(dim0, dim1);

		return false;
	}
	
	public static boolean errorIfDifferentSRID(Geometry geom0, Geometry geom1)
	throws JASPAGeomMismatchException {

		if (Core.isNullGeometry(geom0)) return true;
		if (Core.isNullGeometry(geom1)) return true;

		errorIfDifferentSRIDs(geom0.getSRID(), geom1.getSRID());

		return false;
	}
	

	/**
	 * @param geomList
	 * @return True if the list is null or all the geometries are null or empty. False if there is
	 *         one geometry or more than one but with compatible srid and coordinate dimensions even
	 *         if there are some null geometry
	 * @throws JASPAGeomMismatchException
	 */
	public static boolean errorIfDifferentSRIDorCoorDim(List/*SGG<Geometry>*/ geomList)
			throws JASPAGeomMismatchException {

		if (geomList == null) return true;

		GeomProperties geomProperties = null;
		int nNotNullOrEmptyGeoms = 0;

		if (geomList.size() > 0) {
                    Iterator geomIter = geomList.iterator();
                    Geometry geom = null;
                    while (geomIter.hasNext())  {
                        geom = (Geometry)geomIter.next();
                        if (!Core.isEmptyOrNullGeometry(geom)) {
                            if (geomProperties != null) {
				geomProperties.errorIfDifferentSRIDorCoorDim(geom);
				nNotNullOrEmptyGeoms++;
			    } else {
				geomProperties = new GeomProperties(geom);
				nNotNullOrEmptyGeoms++;
			    }
			}
                    }
		}

		if (nNotNullOrEmptyGeoms == 0) return true;
		return false;
	}

	/**
	 * Same than errorIfDifferentSRIDorCoorDim (List<Geometry> geomList) but taking a geometry array
	 * 
	 * @param geomArray
	 * @return
	 * @throws JASPAGeomMismatchException
	 */
	public static boolean errorIfDifferentSRIDorCoorDim(Geometry[] geomArray)
			throws JASPAGeomMismatchException {
		
		return errorIfDifferentSRIDorCoorDim (Arrays.asList(geomArray));
	}

}
