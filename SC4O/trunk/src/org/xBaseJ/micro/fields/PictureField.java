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
import java.io.UnsupportedEncodingException;

import org.xBaseJ.micro.DBF;
import org.xBaseJ.micro.DBTFile;
import org.xBaseJ.micro.DBT_fpt;
import org.xBaseJ.micro.xBaseJException;

public class PictureField extends Field{

public RandomAccessFile file;
public DBT_fpt dbtobj;
public int originalSize;
public String value;
public byte[] byteValue;

public PictureField() {super();}

public void setDBTObj(DBTFile indbtobj)
{
 dbtobj = (DBT_fpt)indbtobj;

}

public Object clone() throws  CloneNotSupportedException
{
 try {
  PictureField tField = new PictureField(Name, null, null);
  return tField;
  }
  catch (xBaseJException e)
  {return null;}
  catch (IOException e)
  {return null;}
}

public PictureField(String Name, RandomAccessFile infile, DBTFile indbtobj) throws xBaseJException, IOException
  {
  super();
  super.setField(Name,  10, infile);
  dbtobj = (DBT_fpt) indbtobj;
  value = new String("");
  }

/**
 * public method for creating a picture field object.  It is not associated with a database
 * but can be when used with some DBF methods.
 * @param iName the name of the field
 * @exception xBaseJException
 *                     exception caused in calling methods
 * @exception IOException
 *                     can not occur but defined for calling methods
 * @see Field
 *
*/

public PictureField(String iName) throws xBaseJException, IOException
  {
  super();
  super.setField(iName,  10, (RandomAccessFile) null);
  dbtobj = null;
  originalSize = 0;
  buffer =  new byte[10];
  for (int i = 0; i < 10; i++) buffer[i] = DBTFile.BYTEZERO;
  value = new String("");
  }

/**
 * return the character 'P' indicating a picture field
*/
public char getType()
{
return 'P';
}

/**
 * return the contents of the picture Field, variant of the field.get method
*/
public String get()
  {
    if (byteValue == null) return "";
    try {return new String(byteValue, DBF.encodedType); }
    catch (UnsupportedEncodingException UEE){ return new String(byteValue);}
  }

/**
 * return the contents of the picture Field via its original byte array
 * @return byte[] - if not set a null is returned.
*/
public byte[] getBytes()
  {
    return byteValue;
  }

public void read()
     throws IOException, xBaseJException
  {
    super.read();
    byteValue = dbtobj.readBytes(super.buffer);
	if (byteValue == null)
	  originalSize =0;
	else
      originalSize = value.length();
  }


/**
 * sets the contents of the picture Field, variant of the field.put method
 * data not written into DBF until an update or write is issued.
 * @param invalue value to set Field to.
*/
public void put(String invalue) throws xBaseJException
 {
    throw new xBaseJException("use put(Bytes[])");
  }


/**
 * sets the contents of the picture Field, variant of the field.put method
 * data not written into DBF until an update or write is issued.
 * @param inBytes value to set Field to.
*/
public void put(byte inBytes[]) throws xBaseJException
 {
    byteValue = inBytes;
  }



public void write()
     throws IOException, xBaseJException
  {
    super.buffer = dbtobj.write(byteValue, originalSize, true, super.buffer);
    super.write();
  }

public void update()
     throws IOException, xBaseJException
  {
    super.buffer = dbtobj.write(byteValue, originalSize, false, super.buffer);
    super.write();
  }


}
