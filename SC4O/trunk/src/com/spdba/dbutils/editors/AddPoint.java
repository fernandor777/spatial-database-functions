package com.spdba.dbutils.editors;

import com.spdba.dbutils.editors.GeometryEditor.GeometryEditorOperation;

import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.Geometry;

/*
 * Since JASPA is no longer maintained, the AddPoint class has been moved in to the main SC4O hierarchy.
 */
/**
 * @author Jose Martinez-Llario
 * 
 */
public class AddPoint 
     extends GeometryEditor.CoordinateOperation 
  implements GeometryEditorOperation
{

	private int nVertex;
	private int nCurrentVertex;
	private Coordinate newVertex;
	private boolean found;
	private boolean afterIndex;

	public AddPoint(int nVertex, 
                        Coordinate newVertex, 
                        boolean afterIndex) 
        {
		this.nVertex = nVertex;
		this.nCurrentVertex = 0;
		this.newVertex = newVertex;
		this.found = false;
		this.afterIndex = afterIndex;
	}

	@Override
	public Coordinate[] edit(Coordinate[] coordinates, Geometry geometry) 
        {
		if (found) return coordinates;

		if ((nVertex >= nCurrentVertex) && 
                    (nVertex < (nCurrentVertex + coordinates.length))) 
                {
		    Coordinate coor[] = null;

                    int idxVertex = nVertex - nCurrentVertex;

		    coor = new Coordinate[coordinates.length + 1];
                    if (afterIndex) {
                        idxVertex++;
                    }

		    if (idxVertex > 0) {
                        System.arraycopy(coordinates, 0, coor, 0, idxVertex);
                    }
		    coor[idxVertex] = newVertex;
		    System.arraycopy(coordinates, idxVertex, 
                                     coor,        idxVertex + 1, 
                                     coordinates.length - idxVertex);
                    found = true;
                    return coor;
		}

		nCurrentVertex += coordinates.length;

		return coordinates;
	}
}