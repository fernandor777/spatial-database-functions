// Decompiled by DJ v3.10.10.93 Copyright 2007 Atanas Neshkov  Date: 21/03/2010 4:39:40 PM
// Home Page: http://members.fortunecity.com/neshkov/dj.html  http://www.neshkov.com/dj.html - Check often for new version!
// Decompiler options: packimports(3) 
// Source File Name:   Space.java

package com.spdba.dbutils;

public class Space
{

  /**
   * Function must be fed row and col(umn) indexes NOT raw X,Y coordinates.
   * It is up to the caller to determine size of grid and conversion of
   * X,Y coordinates into grid row/col address.
   * @note Space curve grid computed with origin bottom left.
  */
    public static long Peano(long ygrid, long xgrid)
    {
        long curveaddr = 0L;
        long curvemask = 1L;
        for(int i = 64; i-- != 0;)
        {
            curveaddr |= (ygrid & 1L) == 0L ? 0L : curvemask;
            curvemask <<= 1;
            ygrid >>= 1;
            curveaddr |= (xgrid & 1L) == 0L ? 0L : curvemask;
            curvemask <<= 1;
            xgrid >>= 1;
        }

        return curveaddr;
    }

    /**
     * Function must be fed row and col(umn) indexes NOT raw X,Y coordinates.
     * It is up to the caller to determine size of grid and conversion of
     * X,Y coordinates into grid row/col address.
     * @note Space curve grid computed with origin bottom left.
    */
    public static long Morton(long col, long row)
    {
        long key = 0L;
        long left_bit;
        long right_bit;
        long quadrant;
        for(long level = 0L; row > 0L || col > 0L; level++)
        {
            left_bit = row % 2L;
            right_bit = col % 2L;
            quadrant = right_bit + 2L * left_bit;
            key += quadrant << (int)(2L * level);
            row /= 2L;
            col /= 2L;
        }
        return key;
    }

}
