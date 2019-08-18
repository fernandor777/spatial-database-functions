package com.spdba.dbutils.filters;

import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.CoordinateSequence;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.geom.GeometryComponentFilter;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.LinearRing;
import org.locationtech.jts.geom.Point;

/*
 * Since JASPA is no longer maintained, the JTSChangePointFilter class has been moved in to the main SC4O hierarchy.
 */
public class ChangePointFilter 
  implements GeometryComponentFilter 
{
	private int nCurrentVertex;
	private int nVertex;
	private Coordinate coorPoint;
	private boolean ringNotClosed;

	public ChangePointFilter(int nVertex, Coordinate coorPoint) 
        {
            if (nVertex < 0) {
                nVertex = 0;
            }
            this.nVertex = nVertex;
            this.coorPoint = coorPoint;
            nCurrentVertex = 0;
            ringNotClosed = false;
	}

	public boolean hasRingNotClosed() 
        {
            return ringNotClosed;
	}

	// GeometryComponentFilter repeats the element and sub-elements in a
	// geometry. A Multipolygon with 2 polygons (1 shell 1 hole) will call this function nine times :
        //
	public void filter(Geometry geom) 
        {
            // System.out.println ("Visited: " + geom.getClass().getName());
            if (geom instanceof LineString) {
                CoordinateSequence coor = ((LineString) geom).getCoordinateSequence();
            
                if ((nVertex >= nCurrentVertex) && (nVertex < nCurrentVertex + coor.size())) {
                    int idxVertex = nVertex - nCurrentVertex;
                    coor.setOrdinate(idxVertex, CoordinateSequence.X, coorPoint.x);
                    coor.setOrdinate(idxVertex, CoordinateSequence.Y, coorPoint.y);
                    coor.setOrdinate(idxVertex, CoordinateSequence.Z, coorPoint.z);
                    coor.setOrdinate(idxVertex, CoordinateSequence.M, coorPoint.m);
                    
                    if (geom instanceof LinearRing) {
                        if (!((LineString) geom).isClosed()) {
                            ringNotClosed = true;
                        }
                    }
                }
                nCurrentVertex += coor.size();
            }
            
            if (geom instanceof Point) {
                Coordinate coor = ((Point) geom).getCoordinate();
                
                if ((nVertex >= nCurrentVertex) && (nVertex < nCurrentVertex + 1)) {
                    coor.x = coorPoint.x;
                    coor.y = coorPoint.y;
                    coor.z = coorPoint.z;
                    coor.m = coorPoint.m;
                }
                nCurrentVertex++;
            }
	}
}
