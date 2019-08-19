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

public class CharField extends Field {

    public Object clone() throws CloneNotSupportedException {
        CharField tField = (CharField) super.clone();
        tField.Name = new String(Name);
        tField.Length = Length;
        return tField;
    }


    public CharField() {
        super();
    }

    public CharField(String iName, int iLength, RandomAccessFile infile) throws xBaseJException, IOException {
        super();
        super.setField(iName, iLength, infile);
        put("");
    }

    /**
     * public method for creating a CharacterField object.  It is not associated with a database
     * but can be when used with some DBF methods.
     * @param iName the name of the field
     * @param iLength length of Field, range 1 to 254 bytes
     * @exception xBaseJException
     *                     invalid length
     * @exception IOException
     *                     can not occur but defined for calling methods
     * @see Field
     *
     */
    public CharField(String iName, int iLength) throws xBaseJException, IOException {
        super();
        super.setField(iName, iLength, null);
    }

    /**
     * return the character 'C' indicating a character Field
     * @deprecated use getType
     */
    @Deprecated
    public char type() {
        return 'C';
    }

    /**
     * return the character 'C' indicating a character Field
     */

    public char getType() {
        return 'C';
    }


}
