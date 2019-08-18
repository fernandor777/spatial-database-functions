package com.spdba.dbutils.tools;

import com.spdba.dbutils.Constants;

import org.locationtech.jts.geom.Geometry;

import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;

import java.util.Locale;

import java.util.logging.Logger;

import org.geotools.util.logging.Logging;

public class Tools {

    private static final Logger LOGGER = Logging.getLogger("com.spdba.dbutils.tools.Tools");

    public static String getVersion() {
        return Constants.VERSION;
    }

    private String minuteSeconds(long _seconds) {
        String returnString = "";
        long minutes = _seconds / 60;
        if (minutes != 0)
            returnString = minutes + " minutes ";
        long seconds = _seconds - (minutes * 60);
        return returnString + seconds + " seconds";
    }

    public static String milliseconds2Time(long _time) {
        float time = (float) _time / (float) Constants.MILLISECONDS;
        float seconds = (time % Constants.SECONDS);
        time /= Constants.SECONDS;
        int minutes = (int) (time % Constants.MINUTES);
        time /= Constants.MINUTES;
        int hours = (int) (time % 24);
        int  days = (int) (time / 24);
        String timeString = "";
        if (days == 0) {
            // String.format("%d:%02d:%05.3f", hours, minutes, seconds);
            timeString = hours + ":" + minutes + ":" + MathUtils.round(seconds,3);
        } else {
            // String.format("%dd%d:%02d:%05.3f", days, hours, minutes, seconds);
            timeString = days + hours + ":" + minutes + ":" + MathUtils.round(seconds,3);
        }
        return timeString;
    }

    public static DecimalFormat getDecimalFormatter(int _maxFractionDigits) {
        String dfPattern = "###0.0#####";
        if (_maxFractionDigits == 1) {
            dfPattern = "###0.0";
        } else if (_maxFractionDigits > 1) {
            dfPattern = "###0.0" + "####################".substring(0, _maxFractionDigits - 1);
        }
        DecimalFormat df = new DecimalFormat(dfPattern, new DecimalFormatSymbols(Locale.US));
        // Ensure we get a leading and trailing 0
        //
        df.setMinimumFractionDigits(_maxFractionDigits >= 0 ? _maxFractionDigits : df.getMaximumFractionDigits());
        df.setMinimumFractionDigits(1);
        df.setMinimumIntegerDigits(1);
        return df;

    }

    public static DecimalFormat getDecimalFormatter() {
        // Method with no arguments should be used whenever a double is to be used directly in SQL
        return new DecimalFormat("###0.0#####", new DecimalFormatSymbols(Locale.US));
    }

    /**
     * @function formatCoord
     * @param _X
     * @param _Y
     * @return String (?,?)
     * @author Simon Greener, May 2010
     */
    public static String formatCoord(double _X, double _Y, int _precision) {
        // Don't use NLS settings as this may use comma as decimal separator which is not supported due to SDO_ORDINATE_ARRAY using comma as separator
        // dFormat = Tools.getNLSDecimalFormat(_precision, false);
        DecimalFormat dFormat = Tools.getDecimalFormatter(_precision);
        return "(" + dFormat.format(_X) + "," + dFormat.format(_Y) + ")";
    }

    protected static double precisionModelScale = Math.pow(10,3);
    
    /**
     * setPrecisionScale
     * For example, to specify 3 decimal places of precision, use a scale factor
     * of 1000. To specify -3 decimal places of precision (i.e. rounding to
     * the nearest 1000), use a scale factor of 0.001.
     *
     * @param _numDecPlaces : int : Number of digits of precision
     * @since Simon Greener, August 2011, Original Coding
     */
    public static void setPrecisionScale(int _numDecPlaces)
    {
        precisionModelScale = _numDecPlaces < 0 
                              ? (double)(1.0/Math.pow(10, Math.abs(_numDecPlaces))) 
                              : (double)Math.pow(10, _numDecPlaces);
    }

    /**
     * getTolerance 
     * Turns decimal places of precision into tolerance eg 3 is 0.001
     *
     * @param _numDecPlaces : int : Number of digits of precision
     * @since Simon Greener, August 2018, Original Coding
     */
    public static double getTolerance(int _numDecPlaces)
    {
        return 1.0 / Math.pow(10,_numDecPlaces);
    }

    /**
     * getPrecisionScale
     * For 3 decimal places of precision, the required JTS scale factor
     * is 1000. If -3 decimal places of precision (i.e. rounding to
     * the nearest 1000), then a scale factor of 0.001 is required.
     * @param _numDecPlaces : int : Number of digits of precision
     * @since             : Simon Greener, August 2011, Original Coding
     * @copyright           : Simon Greener, 2011 - 2013
     * @license             : Creative Commons Attribution-Share Alike 2.5 Australia License. 
     *                        http://creativecommons.org/licenses/by-sa/2.5/au/
     */
    public static double getPrecisionScale(int _numDecPlaces)
    {
        return _numDecPlaces < 0 
               ? (double)(1.0/Math.pow(10, Math.abs(_numDecPlaces))) 
               : (double)Math.pow(10, _numDecPlaces);
    }

    /**
     * getPrecisionScale
     * Gets current value of class property.
     * @return
     */
    public static double getPrecisionScale()
    {
        return precisionModelScale;
    }

    /**
     * getCoordDim
     * Determines coordinate dimension of a Geometry object.
     * Makes determination based one whether Z or M ordinate is null.
     * May not be correct if observed Z/M value is actually null.
     * @param _geom - Any valid JTS Geometry
     * @return 0, 2, 3 or 4
     * @author Simon Greener, April 20th 2010, Original coding
     */
    public static int getCoordDim(Geometry _geom) {
        return _geom==null 
               ? 0
               : ( Double.isNaN(_geom.getCoordinate().z) &&
                   Double.isNaN(_geom.getCoordinate().m)
                   ? 2 
                   : ( ! Double.isNaN(_geom.getCoordinate().z) &&
                       ! Double.isNaN(_geom.getCoordinate().m)
                       ? 4 : 3 ) );
    }

}
