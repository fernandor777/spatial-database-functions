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
import java.text.DecimalFormat;

import org.xBaseJ.micro.xBaseJException;


public class NumField extends Field{

public byte decPosition = 0;

public NumField() {super();}

public Object clone() throws  CloneNotSupportedException
{
  NumField tField = (NumField) super.clone();
  tField.Name = new String(Name);
  tField.Length = Length;
  tField.decPosition = decPosition;
  return tField;
}

public  NumField(String iName, int iLength, int idecPosition, RandomAccessFile infile)
throws xBaseJException
  {
  super();
  super.setField(iName, iLength, infile);
  decPosition = (byte) idecPosition;
  put("");

  }

/**
 * public method for creating a numeric field object.  It is not associated with a database
 * but can be when used with some DBF methods.
 * @param iName the name of the field
 * @param iLength the length of Field. range is 1 to 19 bytes
 * @param inDecPosition the number of decimal positions range from 2 to 17 bytes. Relative to Length.
 * @exception xBaseJException
 *                     bad name, length or decimal positions specified
 * @exception IOException
 *                     can not occur but defined for calling methods
 * @see Field
 *
*/

public NumField(String iName, int iLength, int inDecPosition) throws xBaseJException, IOException
  {
  super();
  super.setField(iName, iLength, (RandomAccessFile) null);
  decPosition = (byte) inDecPosition;
  }

/**
 * return the character 'N' indicating a numeric field
 * @deprecated use getType
*/
public char type()
{
return 'N';
}

/**
 * return the character 'N' indicating a numeric field
*/
public char getType()
{
return 'N';
}

/**
 * return the number of decimal positions
 * @deprecated use getDecimalPositionCount
*/
public int decPosition()
{
  return (int) decPosition;
}

/**
 * @return int - the number of decimal positions
*/
public int getDecimalPositionCount()
{
    return (int) decPosition;
}


/**
 * public method for getting field value
 * @return String of field value
 *
*/

public String get()
{
int i;
char c;
String value = super.get();

if (value.trim().length() ==0) return "";

for (i=0; i<value.length(); i++)
  {
    c = value.charAt(i);
    if ( c != ' ')
       return value;
  }

StringBuffer format = new StringBuffer();

int decoffset = Length - decPosition - 1;
for (i = 0; i < (decoffset-1);  i++)
  format.append(' ');

if (decoffset > 0)
  format.append('0');

if (decPosition > 0)  {
  format.append('.');
  for (i=0; i<decPosition; i++)  format.append('0');
  }

return format.toString();
}

/**
 * sets the field contents.
 * @exception xBaseJException
 *                    most likely a format exception
 * @param inValue String
*/
public void put(String inValue) throws xBaseJException
  {


	try { Double.valueOf(inValue); }
	  catch  (NumberFormatException nfe) {super.put(""); return; }



  int worklen;

  if (Length > inValue.length()) worklen = Length;
  else worklen = inValue.length();

  char charArray[] = new char[Length];

  int i1, i2, i3, i4;

  for (i1=0; i1 < Length; i1++)  charArray[i1] = ' ';


  for (i1=0; i1<inValue.length(); i1++)
     {
      if (inValue.charAt(i1) == '-') break;
      if (inValue.charAt(i1) == '.') break;
      if (inValue.charAt(i1) < '0') continue;
      if (inValue.charAt(i1) > '9') continue;
      break;
	 }

   boolean neg = false;

   if (inValue.charAt(i1) == '-') {
      neg = true;
      i1++;
    }

   char intForm[] = new char[worklen];
   int breaklen = decPosition == 0 ? worklen : worklen - 1; // if there is a decimal then leave room for it

   for (i2=0; i2<breaklen; i2++)
     {
      if (i1 >= inValue.length()) break;
      if (inValue.charAt(i1) < '0') break;
      if (inValue.charAt(i1) > '9') break;
      intForm[i2] = inValue.charAt(i1);
      i1++;
	 }

    if ( (i1 < inValue.length())  &&  (inValue.charAt(i1) == '.') )       i1++;


    char decForm[] = new char[worklen];
    for (i3=0; i3 <breaklen; i3++)   decForm[i3] = '0';


    for (i3=0; i3 <breaklen; i3++)
	 {
       if (i1 >= inValue.length()) break;
       if (inValue.charAt(i1) < '0') break;
       if (inValue.charAt(i1) > '9') break;
       decForm[i3] = inValue.charAt(i1);
       i1++;
     }

    int startpos = Length-decPosition-1;

    if (decPosition > 0)
	 {
      charArray[startpos] = '.';
      startpos--;
     }

    for (i4=startpos; i4>-1; i4--)
	   {
        i2--;
        if (i2 < 0) break;
        charArray[i4] = intForm[i2];
	   }


    if (neg)
	  {
      if (i4<0) charArray[0] = '-';
      else charArray[i4] = '-';
	  }



    if ( decPosition > 0 )
	  {
        startpos += 2;
        for (i4=1; i4<=decPosition; i4++)
		  {
            charArray[startpos] = decForm[i4-1];
	        startpos++;
		  }
      }


  super.put(new String(charArray));

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
 * @throws xBaseJException
 *                    most likely a format exception
*/
public void put(float inValue) throws xBaseJException
  {
    StringBuffer sb = new StringBuffer(getLength()+1);
    sb.append("#");
    for (int i = 0; i < getLength(); i++)
        sb.append("#");
    DecimalFormat df = new DecimalFormat(sb.toString());
    String s = df.format(inValue).trim();
    put(s);
  }


/**
 * sets the field contents.
 * @param inValue double
 * @throws xBaseJException
 *                    most likely a format exception
*/
public void put(double inValue) throws xBaseJException
  {
    StringBuffer sb = new StringBuffer(getLength()+1);
    sb.append("#");
    for (int i = 0; i < getLength(); i++)
        sb.append("#");
    if (decPosition > 0)
    {
        int pos = getLength()-getDecimalPositionCount();
        sb.setCharAt(pos,'.');

        for (pos++; pos < getLength()+1; pos++)
            sb.setCharAt(pos,'0');
    }

    DecimalFormat df = new DecimalFormat(sb.toString());
    String s = df.format(inValue).trim();
    put(s);
  }

}
