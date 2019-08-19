package org.xBaseJ.micro.fields;
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


import java.io.IOException;
import java.io.RandomAccessFile;

import org.xBaseJ.micro.xBaseJException;


public class FloatField extends NumField{

public byte decPosition = 0;

public FloatField() {super();}

public  FloatField(String iName, int iLength, int DecPoint, RandomAccessFile infile)
throws xBaseJException
  {
  super(iName, iLength, DecPoint, infile);
  decPosition = (byte) DecPoint;
  }

/**
 * public method for creating a numeric field object.  It is not associated with a database
 * but can be when used with some DBF methods.
 * @param iName the name of the field
 * @param iLength the length of Field. range is 1 to 19 bytes
 * @param DecPoint the number of decimal positions range from 2 to 17 bytes. Relative to Length.
 * @exception xBaseJException
 *                     bad name, length or decimal positions specified
 * @exception IOException
 *                     can not occur but defined for calling methods
 * @see Field
 *
*/

public FloatField(String iName, int iLength, int DecPoint) throws xBaseJException, IOException
  {
  super(iName, iLength, DecPoint);
  decPosition = (byte) DecPoint;
  }

/**
 * return the character 'F' indicating a float field
 * @deprecated use getType
*/
public char type()
{
return 'F';
}
/**
 * return the character 'F' indicating a float field
*/
public char getType()
{
return 'F';
}
/**
 * sets the field contents.
 * @exception xBaseJException
 *                    most likely a format exception
 * @param inValue String
*/
public void put(String inValue) throws xBaseJException
  {

   boolean signOn = false;
   if (inValue.trim().length() == 0)
      { super.put("");
         return;
      }

   int i;

  for (i=0; i<inValue.length(); i++) {
     if (inValue.charAt(i) == '-')
        signOn = true;
     if (Character.isDigit(inValue.charAt(i)) || inValue.charAt(i) == '.')
        break;
     }

  if (i == inValue.length())
      { super.put(" ");
        return;
      }

   int start = i;

  for (; i<inValue.length(); i++) {
     if (!Character.isDigit(inValue.charAt(i)) && inValue.charAt(i) != '.')
        break;
     }


   String workstring = inValue.substring(start,i);

   char charray[] = new char[Length];

   Double inDouble = new Double(workstring);
   double duble  = inDouble.doubleValue();

   for (i = 0; i < decPosition; i++)
     {
      duble *= 10;
     }


   inDouble = new Double(duble);
   long longv = inDouble.longValue();

   if (longv < 0){
      longv *= -1;
      signOn = true;
      }

   long longleft;
   int whatsleft;

   int realdp = Length - decPosition;
   String numstring = new String("0123456789");

   for (i = Length; i > 0; i--)
      {
         if ((realdp == i) && (decPosition > 0)) {
            charray[i-1] = '.';
            continue;
         }

         longleft =  longv % 10;
         whatsleft = (int) longleft;
         if (whatsleft < 0) whatsleft *= -1;

         charray[i-1] = numstring.charAt(whatsleft);
         longv /= 10;
      }

  if (signOn) charray[0] = '-';
  for (i = 0; i < charray.length-1; i++)
    {
      if (charray[i] != '0')
          break;
      charray[i] = ' ';
    }
  super.put(new String(charray));
  }

/**
 * sets the field contents.
 * @param inValue long
 * @exception xBaseJException
 *                    most likely a format exception
*/
public void put(long inValue) throws xBaseJException
  {
   put (String.valueOf(inValue));
  }


/**
 * sets the field contents.
 * @param inValue int
 * @exception xBaseJException
 *                    most likely a format exception
*/
public void put(int inValue) throws xBaseJException
  {
   put (String.valueOf(inValue));
  }


/**
 * sets the field contents.
 * @param inValue float
 * @exception xBaseJException
 *                    most likely a format exception
*/
public void put(float inValue) throws xBaseJException
  {
   put (String.valueOf(inValue));
  }


/**
 * sets the field contents.
 * @param inValue double
 * @exception xBaseJException
 *                    most likely a format exception
*/
public void put(double inValue) throws xBaseJException
  {
   put (String.valueOf(inValue));
  }



}
