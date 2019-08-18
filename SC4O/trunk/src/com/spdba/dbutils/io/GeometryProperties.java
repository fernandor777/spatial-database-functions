package com.spdba.dbutils.io;

import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.Constants;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import java.util.logging.Logger;

import org.geotools.data.shapefile.shp.ShapeType;
import org.geotools.util.logging.Logging;


public class GeometryProperties {

    private static final Logger LOGGER = Logging.getLogger("com.spdba.io.GeometryProperties");

    protected int                         FULL_GTYPE = 2001;    
    protected int                               SRID = SDO.SRID_NULL;
    protected int                          COORDINATE_DIMENSION = 2;
    protected Constants.GEOMETRY_TYPES GEOMETRY_TYPE = com.spdba
                                                          .dbutils
                                                          .Constants
                                                          .GEOMETRY_TYPES
                                                          .UNKNOWN;
    protected List                        shapeTypes = new ArrayList(20);
    protected ShapeType                shapefileType = ShapeType.UNDEFINED;
    
    public GeometryProperties() {
        super();
    }

    public void setProperties(GeometryProperties _gp) {
        this.FULL_GTYPE           = _gp.FULL_GTYPE;
        this.SRID                 = _gp.SRID;
        this.COORDINATE_DIMENSION = _gp.COORDINATE_DIMENSION;
        this.shapefileType        = _gp.shapefileType;
        this.GEOMETRY_TYPE        = _gp.GEOMETRY_TYPE;
        this.shapeTypes           = new ArrayList(_gp.shapeTypes.size());
        for (int i=0;i<_gp.shapeTypes.size();i++) {
            this.shapeTypes.add((String)_gp.shapeTypes.get(i));
        }
    }
    
    public boolean hasMeasure( ) {
        return ((this.FULL_GTYPE/100) % 10) == 0 ? false : true;
    }

    public boolean hasZ( ) {
        int numberOrdinates = this.FULL_GTYPE/1000;
        switch ( numberOrdinates ) {
          case 4 : return true;
          case 3 : return ! hasMeasure();
          default:
          case 2 : return false;
        }
    }  
    
    public int getFullGType() {
        return this.FULL_GTYPE;
    }

    public void setFullGType(int GTYPE) {
        this.FULL_GTYPE = GTYPE;
    }

    public int getGType() {
        return this.FULL_GTYPE % 10;
    }
  
    public int getDimension() {
        return this.COORDINATE_DIMENSION;
    }

    public void setDimension(int _dimension) {
        this.COORDINATE_DIMENSION = _dimension;
    }

    public int getSRID() {
        return this.SRID;
    }

    public void setSRID(int SRID) {
        this.SRID = SRID;
    }

    public Constants.GEOMETRY_TYPES getGeometryType() {
        return this.GEOMETRY_TYPE;
    }

    public void setGeometryType(Constants.GEOMETRY_TYPES _geometryType) {
        this.GEOMETRY_TYPE = _geometryType;
    }

    public void setShapefileType(ShapeType _shapeType) {
        this.shapefileType = _shapeType;
    }

    public ShapeType getShapefileType() {
        return this.shapefileType;
    }

    public IOConstants.SHAPE_TYPE getShape_Type()
    {
        int shapeType = SDO.getShapeType(this.getGType(),true).id;
        return com.spdba.dbutils.io.IOConstants.SHAPE_TYPE.getShapeType(shapeType);
    }

    public void addShapeType(ShapeType _shapeType) {
        if ( _shapeType.id != ShapeType.UNDEFINED.id ) {
            if ( ! shapeTypes.contains(_shapeType.toString().toUpperCase()) ) {
                shapeTypes.add(_shapeType.toString().toUpperCase());
            }
        }
    }

    public void alterShapeTypeByExportType(IOConstants.EXPORT_TYPE exportType,
                                           ShapeType             expShapeType)
    {
        // We don't care what sort of geometry type is written to a GML or KML files but we do for a shapefile/tabfile
        //
        if (exportType.compareTo(com.spdba.dbutils.io.IOConstants.EXPORT_TYPE
                                    .SHP)==0 || 
            exportType.compareTo(com.spdba.dbutils.io.IOConstants.EXPORT_TYPE.TAB)==0 ) 
        {
            setFullGType( ( expShapeType.id < 10 
                                        ? 2000 
                                        : expShapeType.id < 20 
                                          ? 3000 
                                          : 4000 
                                       ) +
                                          ( expShapeType.isPointType() 
                                          ? 1 : expShapeType.isMultiPointType()
                                                ? 5 : expShapeType.isLineType() 
                                                      ? 6 : expShapeType.isPolygonType() 
                                                            ? 7 : 1 )
                                      ); 
            setGeometryType(SDO.discoverGeometryType(getGType(), com.spdba
                                                                    .dbutils
                                                                    .Constants
                                                                    .GEOMETRY_TYPES
                                                                    .POINT.toString()));
            setDimension(getFullGType() / 1000); 
        }
    }

    public List<String> getShapeTypes() {
        return this.shapeTypes;
    }
    
    public String shapeTypesAsString() {
        String shpTypes = "";
        for (int i = 0; i < shapeTypes.size(); i++) {
            shpTypes += ((i>1)?",":"") + shapeTypes.get(i);
        }
        return shpTypes;        
    }
    
    public String toString() {
        return "SDO_GTYPE=" + FULL_GTYPE+"," +
               "DIMENSION="+COORDINATE_DIMENSION+"," +
               "SDO_SRID="+SRID+"," +
               "GEOMETRY_TYPE="+GEOMETRY_TYPE.toString()+"," +
               "SHAPE_TYPES={"+shapeTypesAsString()+"}";
    }
    
}
