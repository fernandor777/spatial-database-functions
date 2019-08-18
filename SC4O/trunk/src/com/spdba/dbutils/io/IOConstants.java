package com.spdba.dbutils.io;

import com.spdba.dbutils.tools.Strings;

import org.geotools.data.shapefile.shp.ShapeType;

public class IOConstants {
    
    public static enum EXPORT_TYPE { CSV, SPREADSHEET, GML, KML, SHP, TAB, GEOJSON };

    public static enum SHAPE_TYPE {
        
        // Note that all constants have same ID as related ShapeTypes to aid in conversion
        // Can't subclass ShapeType as is a final class
        //
        ARC(ShapeType.ARC.id),
        ARCM(ShapeType.ARCM.id),
        ARCZ(ShapeType.ARCZ.id),
        MULTIPOINT(ShapeType.MULTIPOINT.id),
        MULTIPOINTM(ShapeType.MULTIPOINTM.id),
        MULTIPOINTZ(ShapeType.MULTIPOINTZ.id),
        POINT(ShapeType.POINT.id),
        POINTM(ShapeType.POINTM.id),
        POINTZ(ShapeType.POINTZ.id),
        POLYGON(ShapeType.POLYGON.id),
        POLYGONM(ShapeType.POLYGONM.id),
        POLYGONZ(ShapeType.POLYGONZ.id),
        UNDEFINED(ShapeType.UNDEFINED.id);
        
        public final int id;

        SHAPE_TYPE(int id) {
            this.id = id;
        }

        public static SHAPE_TYPE getShapeType(int _shapeTypeId) {
            for (SHAPE_TYPE sType : com.spdba
                                       .dbutils
                                       .io
                                       .IOConstants
                                       .SHAPE_TYPE
                                       .values()) {
                if (sType.id == _shapeTypeId ) {
                    return sType;
                }
            }
            return null;
        }

        public static ShapeType getShapeType(SHAPE_TYPE _shapeType) {
            return ShapeType.forID(_shapeType.id);
        }
        
        public static ShapeType validateShapeType(String shapeType) 
        {
            if (Strings.isEmpty(shapeType) )
                return ShapeType.UNDEFINED;
            String lowerShapeType = shapeType.toLowerCase();
            SHAPE_TYPE sType = com.spdba
                                  .dbutils
                                  .io
                                  .IOConstants
                                  .SHAPE_TYPE
                                  .UNDEFINED;
            if ( shapeType.length() != 0 ) {
                 if ( lowerShapeType.startsWith("polygon") ||
                      lowerShapeType.startsWith("multipolygon") ) {
                     switch (lowerShapeType.charAt(lowerShapeType.length()-1)) {
                        case 'm' : sType = com.spdba
                                   .dbutils
                                   .io
                                   .IOConstants
                                   .SHAPE_TYPE
                                   .POLYGONM; break;
                        case 'z' : sType = com.spdba
                                   .dbutils
                                   .io
                                   .IOConstants
                                   .SHAPE_TYPE
                                   .POLYGONZ; break;
                        default  : sType = com.spdba
                                   .dbutils
                                   .io
                                   .IOConstants
                                   .SHAPE_TYPE
                                   .POLYGON; break;
                     }
                }
                 else if ( shapeType.startsWith("point") ) {
                     switch (lowerShapeType.charAt(lowerShapeType.length()-1)) {
                        case 'm' : sType = com.spdba
                                   .dbutils
                                   .io
                                   .IOConstants
                                   .SHAPE_TYPE
                                   .POINTM; break;
                        case 'z' : sType = com.spdba
                                   .dbutils
                                   .io
                                   .IOConstants
                                   .SHAPE_TYPE
                                   .POINTZ; break;
                        default  : sType = com.spdba
                                   .dbutils
                                   .io
                                   .IOConstants
                                   .SHAPE_TYPE
                                   .POINT; break;
                     }
                 }
                 else if ( shapeType.startsWith("multipoint") ) {
                     switch (lowerShapeType.charAt(lowerShapeType.length()-1)) {
                        case 'm' : sType = com.spdba
                                   .dbutils
                                   .io
                                   .IOConstants
                                   .SHAPE_TYPE
                                   .MULTIPOINTM; break;
                        case 'z' : sType = com.spdba
                                   .dbutils
                                   .io
                                   .IOConstants
                                   .SHAPE_TYPE
                                   .MULTIPOINTZ; break;
                        default  : sType = com.spdba
                                   .dbutils
                                   .io
                                   .IOConstants
                                   .SHAPE_TYPE
                                   .MULTIPOINT; break;
                     }  
                 }
                else if ( shapeType.startsWith("linestring") ||
                          shapeType.startsWith("multilinestring") ) {
                     switch (lowerShapeType.charAt(lowerShapeType.length()-1)) {
                        case 'm' : sType = com.spdba
                                   .dbutils
                                   .io
                                   .IOConstants
                                   .SHAPE_TYPE
                                   .ARCM; break;
                        case 'z' : sType = com.spdba
                                   .dbutils
                                   .io
                                   .IOConstants
                                   .SHAPE_TYPE
                                   .ARCZ; break;
                        default  : sType = com.spdba
                                   .dbutils
                                   .io
                                   .IOConstants
                                   .SHAPE_TYPE
                                   .ARC; break;
                     }
                }
            }
            return ShapeType.forID(sType.id);
        }
      
    };
    
}
