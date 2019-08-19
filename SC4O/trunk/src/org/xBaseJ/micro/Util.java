package org.xBaseJ.micro;
/**
 *xBaseJ - java access to dBase files
 *<p>&copy;Copyright 1997-2006 - American Coders, LTD  - Raleigh NC USA
 *<p>All rights reserved
 *<p>Currently supports only dBase III format DBF, DBT and NDX files
 *<p>                        dBase IV format DBF, DBT, MDX and NDX files

 *<p>American Coders, Ltd
 *<br>P. O. Box 97462
 *<br>Raleigh, NC  27615  USA
 *<br>1-919-846-2014
 *<br>http://www.americancoders.com
@author Joe McVerry, American Coders Ltd.
@version 3.0.0
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library Lesser General Public
 * License along with this library; if not, write to the Free
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
*/

import java.io.File;
import java.io.InputStream;

import org.xBaseJ.micro.fields.DateField;


public class Util extends Object {


    static java.util.Properties props = new java.util.Properties();

    static File propFile = null;

    static InputStream propIS = null;

    static long lastUpdate = -1;

    static boolean recheckProperties;

	public static String servletContextPath = null;

    public static long x86(long in) {
        if ((System.getProperty("os.arch").indexOf("86") == 0)
                && (System.getProperty("os.arch").compareTo("vax") != 0))
            return in;

        boolean negative = false;
        long is;
        long first, second, third, fourth, fifth, sixth, seventh, eigth, isnt, save;
        save = in;
        if (in < 0) {
            negative = true;
            //          in = ((byte) in & 0x7fffffffffffffff);
        }
        first = in >>> 56;
        if (negative)
            first = (byte) in & 0x7f;
        if (negative == true)
            first |= 0x80;
        isnt = first << 56;
        save = in - isnt;
        second = save >>> 48;
        isnt = second << 48;
        save = save - isnt;
        third = save >>> 40;
        isnt = third << 40;
        save = save - isnt;
        fourth = save >>> 32;
        isnt = fourth << 32;
        save = save - isnt;
        fifth = save >>> 24;
        isnt = fifth << 24;
        save = save - isnt;
        sixth = save >>> 16;
        isnt = sixth << 16;
        save = save - isnt;
        seventh = save >>> 8;
        isnt = seventh << 8;
        save = save - isnt;
        eigth = save; //- seventh;
        is = (eigth << 56) + (seventh << 48) + (sixth << 40) + (fifth << 32)
                + (fourth << 24) + (third << 16) + (second << 8) + first;
        return is;
    }

    public static int x86(int in) {
        if ((System.getProperty("os.arch").indexOf("86") == 0)
                && (System.getProperty("os.arch").compareTo("vax") != 0)) {
            return in;
        }
        boolean negative = false;
        int is;
        int first, second, third, fourth, save;
        save = in;
        if (in < 0) {
            negative = true;
            in &= 0x7fffffff;
        }
        first = in >>> 24;
        if (negative == true)
            first |= 0x80;
        in = save & 0x00ff0000;
        second = in >>> 16;
        in = save & 0x0000ff00;
        third = in >>> 8;
        fourth = save & 0x000000ff;
        is = (fourth << 24) + (third << 16) + (second << 8) + first;
        return is;
    }

    public static short x86(short in) {
        if ((System.getProperty("os.arch").indexOf("86") == 0)
                && (System.getProperty("os.arch").compareTo("vax") != 0))
            return in;
        short is, save = in;
        boolean negative = false;
        int first, second;
        if (in < 0) {
            negative = true;
            in &= 0x7fff;
        }
        first = in >>> 8;
        if (negative == true)
            first |= 0x80;
        second = save & 0x00ff;
        is = (short) ((second << 8) + first);
        return is;
    }

    public static double doubleDate(DateField d) {
        return doubleDate(d.get());
    }

    public static double doubleDate(String s) {
        int i;

        if (s.trim().length() == 0)
            return 1e100;

        int year = Integer.parseInt(s.substring(0, 4));
        if (year == 0)
            return 1e100;

        int days[] = { 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

        int month = Integer.parseInt(s.substring(4, 6));
        int day = Integer.parseInt(s.substring(6, 8));

        int daydif = 2378497;

        if ((year / 4) == 0)
            days[2] = 29;

        if (year > 1799) {
            daydif += day - 1;
            for (i = 2; i <= month; i++)
                daydif += days[i - 1];
            daydif += (year - 1800) * 365;
            daydif += ((year - 1800) / 4);
            daydif -= ((year - 1800) % 100); // leap years don't occur in 00
                                             // years
            if (year > 1999) // except in 2000
                daydif++;
        } else {
            daydif -= (days[month] - day + 1);
            for (i = 11; i >= month; i--)
                daydif -= days[i + 1];
            daydif -= (1799 - year) * 365;
            daydif -= (1799 - year) / 4;
        }

        Integer retInt = new Integer(daydif);

        return retInt.doubleValue();
    }



}
