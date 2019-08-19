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

public class LogicalField extends Field{

public final static byte BYTETRUE = (byte) 'T';
public final static byte BYTEFALSE = (byte) 'F';

public Object clone() throws  CloneNotSupportedException
{
  LogicalField tField = (LogicalField) super.clone();
  tField.Name = new String(Name);
  tField.Length = 1;
  return tField;
}

public LogicalField() {super();}

public LogicalField(String iName, RandomAccessFile infile) throws xBaseJException
  {
  super();
  super.setField(iName, 1, infile);
  put('F');

  }

/**
 * public method for creating a LogicalField object.  It is not associated with a database
 * but can be when used with some DBF methods.
 * @param iName the name of the field
 * @exception xBaseJException
 *                     exception caused in calling methods
 * @exception IOException
 *                     can not occur but defined for calling methods
 * @see Field
 *
*/

public LogicalField(String iName) throws xBaseJException, IOException
  {
  super();
  super.setField(iName, 1, (RandomAccessFile) null);
  }

/**
 * return the character 'L' indicating a logical Field
 * @deprecated use getType
*/

public char type()
{
return 'L';
}
/**
 * return the character 'L' indicating a logical Field
*/

public char getType()
{
return 'L';
}

/**
 *allows input of Y, y, T, t  and 1 for true, N, n, F, f, and 0 for false
 * @exception xBaseJException
 *                    most likely a format exception
*/

public void put(String inValue) throws xBaseJException
  {

  String value = inValue.trim();
  if (value.length() == 0)
    value = "F";
  if (value.length() != 1)
      throw new xBaseJException("Field length incorrect");
  put(value.charAt(0));

  }

/**
 *allows input of Y, y, T, t  and 1 for true, N, n, F, f, and 0 for false
 * @exception xBaseJException
 *                    most likely a format exception
*/
public void put(char inValue) throws xBaseJException
 {
  switch (inValue)
   {
     case 'Y':
     case 'y':
     case 'T':
     case 't':
     case '1':
        buffer[0] = BYTETRUE;
        break;
     case 'N':
     case 'n':
     case 'F':
     case 'f':
     case '0':
        buffer[0] = BYTEFALSE;
        break;
     default:
            throw new xBaseJException("Invalid logical Field value");
    }
  }

/**
 * allows input true or false
*/
public void put(boolean inValue)
  {
    if (inValue) buffer[0] = BYTETRUE;
    else buffer[0] = BYTEFALSE;
  }

/**
 * returns T for true and F for false
*/
public char getChar()
{
   return (char) buffer[0];
}

/**
 * returns true or false
*/
public boolean getBoolean()
{
   return((buffer[0] == BYTETRUE));
}

}
