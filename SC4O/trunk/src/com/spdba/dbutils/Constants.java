package com.spdba.dbutils;

import com.spdba.dbutils.tools.Strings;

public class Constants {

    public static final String                VERSION = "2.0.0";

    public static final String                   NULL = "NULL";
    public static final int             MAX_PRECISION = 10; // decimal places
    public static final int         DEFAULT_PRECISION = 3;
    public static final double      DEFAULT_TOLERANCE = 0.05;  // 5 cm is default for geodetic
    public static final long             MILLISECONDS = 1000;
    public static final long                  SECONDS = 60;
    public static final long                  MINUTES = 60;    
    public static final String TABLE_COLUMN_SEPARATOR = ".";
    
    public static String SRID_TYPE_UNKNOWN = "UNKNOWN";
    public static String SRID_TYPE_COMPOUND = "COMPOUND";
    public static String SRID_TYPE_ENGINEERING= "ENGINEERING";
    public static String SRID_TYPE_GEODETIC_COMPOUND= "GEODETIC_COMPOUND";
    public static String SRID_TYPE_GEODETIC_GEOCENTRIC= "GEODETIC_GEOCENTRIC";
    public static String SRID_TYPE_GEODETIC_GEOGRAPHIC2D= "GEODETIC_GEOGRAPHIC2D";
    public static String SRID_TYPE_GEODETIC_GEOGRAPHIC3D= "GEODETIC_GEOGRAPHIC3D";
    public static String SRID_TYPE_GEOGRAPHIC2D= "GEOGRAPHIC2D";
    public static String SRID_TYPE_PROJECTED= "PROJECTED";
    public static String SRID_TYPE_VERTICAL= "VERTICAL";
                   
    public static String GEOMETRY_TYPE_UNKNOWN      = "UNKNOWN";
    public static String GEOMETRY_TYPE_POINT        = "POINT";
    public static String GEOMETRY_TYPE_MULTIPOINT   = "MULTIPOINT";
    public static String GEOMETRY_TYPE_LINE         = "LINE";
    public static String GEOMETRY_TYPE_MULTILINE    = "MULTILINE";
    public static String GEOMETRY_TYPE_POLYGON      = "POLYGON";
    public static String GEOMETRY_TYPE_MULTIPOLYGON = "MULTIPOLYGON";
    public static String GEOMETRY_TYPE_COLLECTION   = "COLLECTION";
    public static String GEOMETRY_TYPE_SOLID        = "SOLID";
    public static String GEOMETRY_TYPE_MULTISOLID   = "MULTISOLID";
    public static String GEOMETRY_TYPE_IMAGE        = "IMAGE";
    
    public static enum GEOMETRY_TYPES { 
        UNKNOWN,
        POINT,
        MULTIPOINT,
        LINE,
        MULTILINE,
        POLYGON,
        MULTIPOLYGON,
        COLLECTION,
        SOLID,
        MULTISOLID,
        IMAGE 
    };

    public static enum XMLAttributeFlavour { 
        OGR, 
        FME, 
        GML,
        SHP;
        
        public static Constants.XMLAttributeFlavour getXMLFlavour(String _xFlavour) {
            if (Strings.isEmpty(_xFlavour) ) {
                return Constants.XMLAttributeFlavour.OGR;
            }
            for (Constants.XMLAttributeFlavour xFlavour : Constants.XMLAttributeFlavour.values()) {
                if (xFlavour.toString().equalsIgnoreCase(_xFlavour) ) {
                    return xFlavour;
                }
            }
            return Constants.XMLAttributeFlavour.OGR;
        }

    };
    
}
