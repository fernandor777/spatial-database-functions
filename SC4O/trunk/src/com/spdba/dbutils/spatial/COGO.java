package com.spdba.dbutils.spatial;

import java.awt.geom.Point2D;

public class COGO {
    
    
    /**
     * @method computeAngle
     * @param _startPoint
     * @param _endPoint
     * @return double Angle in Radians
     * @method @method
     * @note    Point data has to be in world coordinates
     * @author @author
     */
    public static double computeAngle(Point2D _startPoint, Point2D _endPoint) {
        double dBearing;
        double dEast;
        double dNorth;

        if (_startPoint == null || _endPoint == null)
            return 0.0f;

        if ((_startPoint.getX() == _endPoint.getX()) && (_startPoint.getY() == _endPoint.getY()))
            return 0.0f;

        dEast = _endPoint.getX() - _startPoint.getX();
        dNorth = _endPoint.getY() - _startPoint.getY();
        if (dEast == 0.0f) {
            if (dNorth < 0) {
                dBearing = Math.PI;
            } else {
                dBearing = 0.0f;
            }
        } else {
            dBearing = (0.0f - Math.atan(dNorth / dEast)) + (Math.PI / 2.0f);
        }
        if (dEast < 0)
            dBearing += Math.PI;
        // -90 is to compensate for bearings being clockwise from north and Java2D is 90 degree different
        return dBearing - (Math.PI / 2.0f);
    }

}
