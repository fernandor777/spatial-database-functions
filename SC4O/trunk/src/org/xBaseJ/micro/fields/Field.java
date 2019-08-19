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


import java.io.Externalizable;
import java.io.IOException;
import java.io.ObjectInput;
import java.io.ObjectOutput;
import java.io.RandomAccessFile;
import java.io.UnsupportedEncodingException;

import org.xBaseJ.micro.DBF;
import org.xBaseJ.micro.xBaseJException;


public abstract class Field extends Object implements Cloneable, Externalizable {

    public String Name;
    public int Length = 0;

    public byte[] buffer;
    public boolean Deleted;
    public RandomAccessFile file;

    public long myoffset;


    /** used by externalize methods
     * @param in ObjectInput stream
     * @exception IOException - most likely class changed since written
     * @exception ClassNotFoundException - only when dummy constructro not found
     */

    public void readExternal(ObjectInput in) throws IOException, ClassNotFoundException {
        Name = in.readUTF();
        Length = in.readInt();
        in.readFully(buffer);
        Deleted = in.readBoolean();
    }

    /** used by externalize methods
     * @param out ObjectOutput stream
     * @exception IOException Java.io error
     */

    public void writeExternal(ObjectOutput out) throws IOException {
        out.writeUTF(Name);
        out.writeInt(Length);
        out.write(buffer);
        out.writeBoolean(Deleted);
    }


    public Object clone() throws CloneNotSupportedException {
        Field tField = (Field) super.clone();
        tField.Name = new String(Name);
        tField.Length = Length;
        return tField;
    }


    public void validateName(String iName) throws xBaseJException {

        if (iName == null)
            throw new xBaseJException("Missing field name");
        if (iName.length() == 0)
            throw new xBaseJException("Missing field name");
        if (iName.length() > 10)
            throw new xBaseJException("Invalid field name " + iName);

        for (int i = 0; i < iName.length(); i++) {
            if (Character.isLetter(iName.charAt(i)))
                continue;
            if (Character.isDigit(iName.charAt(i)))
                continue;
            if (iName.charAt(i) == '_')
                continue;

            throw new xBaseJException("Invalid field name " + iName + ", character invalid at " + i);
        }

    }

    /**
     * creates a Field object.
     * not useful for the abstract Field class
     * @see CharField
     * @see DateField
     * @see LogicalField
     * @see MemoField
     * @see NumField
     */
    public Field() {
        int tlength;

        if (Length == 0)
            tlength = 1;
        else
            tlength = Length;

        buffer = new byte[tlength];
        buffer[0] = (byte) ' ';
    }


    public void setField(String iName, int iLength, RandomAccessFile infile) throws xBaseJException {

        Name = iName.trim();
        validateName(Name);
        Length = iLength;
        setFile(infile);
        buffer = new byte[Length];

    }

    public void setFile(RandomAccessFile infile) {
        file = infile;
    }


    /**
     * @return String contianing the field name
     * @deprecated use getName
     */

    public String name() {
        return Name;
    }

    /**
     * @return String contianing the field name
     */

    public String getName() {
        return Name;
    }

    /**
     * @return int - the field length
     * @deprecated use getLength
     */

    public int length() {
        return Length;
    }

    /**
     * @return int - the field length
     */

    public int getLength() {
        return Length;
    }

    /**
     * @return char field type
     * @deprecated use getType
     * @exception xBaseJException
     *                       undefined field type
     */
    public char type() throws xBaseJException {
        if (true)
            throw new xBaseJException("Undefined field");
        return '_';
    }

    /**
     * @return char field type
     * @exception xBaseJException
     *                       undefined field type
     */
    public char getType() throws xBaseJException {
        if (true)
            throw new xBaseJException("Undefined field");
        return '_';
    }

    /**
     * @return int - the number of decimal positions for numeric fields, zero returned otherwise
     * @deprecated use getDecimalPositionCount
     */
    public int decPoint() {
        return 0;
    }

    /**
     * @return int - the number of decimal positions for numeric fields, zero returned otherwise
     */
    public int getDecimalPositionCount() {
        return 0;
    }

    public void read() throws IOException, xBaseJException {
        file.readFully(buffer, 0, Length);
    }

    /**
     * @return String field contents after any type of read.
     */
    public String get() {
        int k;
        for (k = 0; k < Length && buffer[k] != 0; k++)
            ;
        if (k == 0) // no data
            return "";
        //if (k < Length) // found a trailing binary zero
        //  k--;

        String s;
        try {
            s = new String(buffer, 0, k, DBF.encodedType);
        } catch (UnsupportedEncodingException UEE) {
            s = new String(buffer, 0, k);
        }
        return s;
    }

    /**
     * returns the original byte array as stored in the file.
     * @return byte[] - may return a null if not set
     */
    public byte[] getBytes() {
        return buffer;
    }

    public void write() throws IOException, xBaseJException {
        file.write(buffer, 0, Length);
    }

    public void update() throws IOException, xBaseJException {
        file.write(buffer, 0, Length);
    }

    /**
     * set field contents, no database updates until a DBF update or write is issued
     * @param inValue value to set
     * @exception  xBaseJException
     *                     value length too long
     */

    public void put(String inValue) throws xBaseJException {
        byte b[];
        int i;

        if (inValue.length() > Length)
            throw new xBaseJException("Field length too long");

        i = Math.min(inValue.length(), Length);

        try {
            b = inValue.getBytes(DBF.encodedType);
        } catch (UnsupportedEncodingException UEE) {
            b = inValue.getBytes();
        }

        for (i = 0; i < b.length; i++)
            buffer[i] = b[i];

        for (i = inValue.length(); i < Length; i++)
            buffer[i] = (byte) 0;

    }

    /**
     * set field contents with binary data, no database updates until a DBF update or write is issued
     * if inValue is too short buffer is filled with binary zeros.
     * @param inValue byte array
     * @exception  xBaseJException
     *                     value length too long
     */

    public void put(byte inValue[]) throws xBaseJException {
        int i;

        if (inValue.length > Length)
            throw new xBaseJException("Field length too long");

        for (i = 0; i < inValue.length; i++)
            buffer[i] = inValue[i];

        for (; i < Length; i++)
            buffer[i] = 0;

    }

}
