package org.xBaseJ.micro;
/**
 *xBaseJ - java access to dBase files
 *<p>&copy;Copyright 1997-2007 - American Coders, LTD  - Raleigh NC USA
 *<p>All rights reserved
 *<p>Currently supports only dBase III format DBF, DBT and NDX files
 *<p>                        dBase IV format DBF, DBT, MDX and NDX files

*<p>American Coders, Ltd
*<br>P. O. Box 97462
*<br>Raleigh, NC  27615  USA
*<br>1-919-846-2014
*<br>http://www.americancoders.com
*<p>Package expires on 2007-06-01
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

import java.io.EOFException;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.io.UnsupportedEncodingException;

import java.util.Calendar;
import java.util.Random;
import java.util.Vector;

import org.xBaseJ.micro.fields.CharField;
import org.xBaseJ.micro.fields.DateField;
import org.xBaseJ.micro.fields.Field;
import org.xBaseJ.micro.fields.FloatField;
import org.xBaseJ.micro.fields.LogicalField;
import org.xBaseJ.micro.fields.MemoField;
import org.xBaseJ.micro.fields.NumField;
import org.xBaseJ.micro.fields.PictureField;
import org.xBaseJ.micro.indexes.Index;
import org.xBaseJ.micro.indexes.MDX;
import org.xBaseJ.micro.indexes.MDXFile;
import org.xBaseJ.micro.indexes.NDX;


public class DBF extends Object {

    public String dosname;
    public int current_record = 0;
    public short fldcount = 0;
    public File ffile;
    public RandomAccessFile file;
    public Vector fld_root;
    public DBTFile dbtobj = null;
    public byte delete_ind = (byte) ' ';

    /*  header  */

    public byte version = 3;
    public byte l_update[] = new byte[3];
    public int count = 0;
    public short offset = 0;
    public short lrecl = 0;
    public byte incomplete_transaction = 0;
    public byte encrypt_flag = 0;
    public byte reserve[] = new byte[12];
    public byte MDX_exist = 0;
    public byte language = 0;
    public byte reserve2[] = new byte[2];

    public int IndexCount = 0;
    public Index jNDX;
    public Vector jNDXes;
    public Vector jNDXID;

    public static long results = 0;
    public MDXFile MDXfile = null;
    public static final byte DBASEIII = 3;
    public static final byte DBASEIV = 4;
    public static final byte DBASEIII_WITH_MEMO = -125;
    public static final byte DBASEIV_WITH_MEMO = -117;
    public static final byte FOXPRO_WITH_MEMO = -11;
    public static final byte NOTDELETED = (byte) ' ';
    public static final byte DELETED = 0x2a;

    public static final char READ_ONLY = 'r';
    public boolean readonly = false;

    public static final String xBaseJVersion = "3.0.0";


    public static String encodedType = "8859_1";


    /**
     * creates a new DBF file or replaces an existing database file, w/o format assumes dbaseiii file format
     *
     * <h4>The unregistered package limitted to 5 open dbf's.</h4>
     *
     * @param DBFname          a new or existing database file, can be full or partial pathname
     * @exception xBaseJException
     *                                    File does exist and told not to destroy it.
     * @exception xBaseJException
     *                                    Told to destroy but operating system can not destroy
     * @exception IOException
     *                                    Java error caused by called methods
     * @exception SecurityException
     *                                    Java error caused by called methods, most likely trying to create on a remote system
     */

    public DBF(String DBFname, boolean destroy) throws xBaseJException, IOException, SecurityException

    {
        createDBF(DBFname, DBASEIII, destroy);
    }

    /**
     * creates a new DBF file or replaces an existing database file
     *
     * <h4>The unregistered package limitted to 5 open dbf's.</h4>
     *
     * @param DBFname          a new or existing database file, can be full or partial pathname
     * @param format             use class constants DBASEIII or DBASEIV
     * @param destroy            permission to destroy an existing database file
     * @exception xBaseJException
     *                                    File does exist and told not to destroy it.
     * @exception xBaseJException
     *                                    Told to destroy but operating system can not destroy
     * @exception IOException
     *                                    Java error caused by called methods
     * @exception SecurityException
     *                                    Java error caused by called methods, most likely trying to create on a remote system
     */

    public DBF(String DBFname, int format, boolean destroy) throws xBaseJException, IOException, SecurityException

    {
        createDBF(DBFname, format, destroy);
    }

    /**
     * creates an DBF object and opens existing database file in readonly mode
     *
     * <h4>The unregistered package limitted to 5 open dbf's.</h4>
     *
     * @param DBFname          an existing database file, can be full or partial pathname
     * @exception xBaseJException
     *                                    Can not find database
     * @exception xBaseJException
     *                                    database not dbaseIII format
     * @exception IOException
     *                                    Java error caused by called methods
     */

    public DBF(String DBFname, char readOnly) throws xBaseJException, IOException {
        if (readOnly != DBF.READ_ONLY)
            throw new xBaseJException("Unknown readOnly indicator <" + readOnly + ">");
        readonly = true;
        openDBF(DBFname);
    }


    /**
     * creates an DBF object and opens existing database file in read/write mode
     *
     * <h4>The unregistered package limitted to 5 open dbf's.</h4>
     *
     * @param DBFname          an existing database file, can be full or partial pathname
     * @exception xBaseJException
     *                                    Can not find database
     * @exception xBaseJException
     *                                    database not dbaseIII format
     * @exception IOException
     *                                    Java error caused by called methods
     */

    public DBF(String DBFname) throws xBaseJException, IOException {

        readonly = false;
        openDBF(DBFname);
    }

    /**
     * creates a new DBF file or replaces an existing database file, w/o format assumes dbaseiii file format
     *
     * <h4>The unregistered package limitted to 5 open dbf's.</h4>
     *
     * @param DBFname          a new or existing database file, can be full or partial pathname
     * @exception xBaseJException
     *                                    File does exist and told not to destroy it.
     * @exception xBaseJException
     *                                    Told to destroy but operating system can not destroy
     * @exception IOException
     *                                    Java error caused by called methods
     * @exception SecurityException
     *                                    Java error caused by called methods, most likely trying to create on a remote system
     */

    public DBF(String DBFname, boolean destroy, String inEncodeType) throws xBaseJException, IOException, SecurityException

    {
        setEncodingType(inEncodeType);
        createDBF(DBFname, DBASEIII, destroy);
    }

    /**
     * creates a new DBF file or replaces an existing database file
     *
     * <h4>The unregistered package limitted to 5 open dbf's.</h4>
     *
     * @param DBFname          a new or existing database file, can be full or partial pathname
     * @param format             use class constants DBASEIII or DBASEIV
     * @param destroy            permission to destroy an existing database file
     * @exception xBaseJException
     *                                    File does exist and told not to destroy it.
     * @exception xBaseJException
     *                                    Told to destroy but operating system can not destroy
     * @exception IOException
     *                                    Java error caused by called methods
     * @exception SecurityException
     *                                    Java error caused by called methods, most likely trying to create on a remote system
     */

    public DBF(String DBFname, int format, boolean destroy, String inEncodeType) throws xBaseJException, IOException, SecurityException

    {
        setEncodingType(inEncodeType);
        createDBF(DBFname, format, destroy);
    }

    /**
     * creates an DBF object and opens existing database file in readonly mode
     *
     * <h4>The unregistered package limitted to 5 open dbf's.</h4>
     *
     * @param DBFname          an existing database file, can be full or partial pathname
     * @exception xBaseJException
     *                                    Can not find database
     * @exception xBaseJException
     *                                    database not dbaseIII format
     * @exception IOException
     *                                    Java error caused by called methods
     */

    public DBF(String DBFname, char readOnly, String inEncodeType) throws xBaseJException, IOException {
        if (readOnly != DBF.READ_ONLY)
            throw new xBaseJException("Unknown readOnly indicator <" + readOnly + ">");
        readonly = true;
        setEncodingType(inEncodeType);
        openDBF(DBFname);
    }


    /**
     * creates an DBF object and opens existing database file in read/write mode
     *
     * <h4>The unregistered package limitted to 5 open dbf's.</h4>
     *
     * @param DBFname          an existing database file, can be full or partial pathname
     * @exception xBaseJException
     *                                    Can not find database
     * @exception xBaseJException
     *                                    database not dbaseIII format
     * @exception IOException
     *                                    Java error caused by called methods
     */

    public DBF(String DBFname, String inEncodeType) throws xBaseJException, IOException {

        readonly = false;
        setEncodingType(inEncodeType);
        openDBF(DBFname);
    }

    /**
     * opens an existing database file
     *
     *
     * @param DBFname          an existing database file, can be full or partial pathname
     * @exception xBaseJException
     *                                    Can not find database
     * @exception xBaseJException
     *                                    database not dbaseIII format
     * @exception IOException
     *                                    Java error caused by called methods
     */

    public void openDBF(String DBFname) throws IOException, xBaseJException {
        jNDX = null;
        int i;
        jNDXes = new Vector(1);
        jNDXID = new Vector(1);
        ffile = new File(DBFname);

        if (!ffile.exists() || !ffile.isFile()) {
            throw new xBaseJException("Unknown database file " + DBFname);
        } /* endif */

        if (readonly)
            file = new RandomAccessFile(DBFname, "r");
        else
            file = new RandomAccessFile(DBFname, "rw");

        dosname = DBFname;
        // ffile.getAbsolutePath(); // getName();

        read_dbhead();
        fldcount = (short) ((offset - 1) / 32 - 1);

        if ((version != DBASEIII) && (version != DBASEIII_WITH_MEMO) && (version != DBASEIV) &&
            (version != DBASEIV_WITH_MEMO) && (version != FOXPRO_WITH_MEMO)) {

            throw new xBaseJException("Wrong Version " + String.valueOf((short) version));
        }

        if (version == FOXPRO_WITH_MEMO)
            dbtobj = new DBT_fpt(this, readonly);
        else if (version == DBASEIII_WITH_MEMO)
            dbtobj = new DBT_iii(this, readonly);
        else if (version == DBASEIV_WITH_MEMO)
            dbtobj = new DBT_iv(this, readonly);

        fld_root = new Vector(new Long(fldcount).intValue());

        for (i = 0; i < fldcount; i++) {
            fld_root.addElement(read_Field_header());
        }


        if (MDX_exist == 1) {
            try {
                if (readonly)
                    MDXfile = new MDXFile(dosname, this, 'r');
                else
                    MDXfile = new MDXFile(dosname, this, ' ');
                for (i = 0; i < MDXfile.anchor.indexes; i++)
                    jNDXes.addElement(MDXfile.MDXes[i]);
            } catch (xBaseJException xbe) {


                System.err.println(xbe.getMessage());
                System.err.println("Processing continues without mdx file");
                MDX_exist = 0;

            }
        }


        try {
            file.readByte();
            file.readByte();
        } catch (EOFException IOE) {
            ; //nop some dbase clones don't uses the last two bytes
        }

        current_record = 0;

    }


    public void finalize() throws Throwable {
        try {
            close();
        } catch (Exception e) {
            ;
        }
    }


    public void createDBF(String DBFname, int format, boolean destroy) throws xBaseJException, IOException,
                                                                              SecurityException {

        jNDX = null;
        jNDXes = new Vector(1);
        jNDXID = new Vector(1);
        ffile = new File(DBFname);

        if (format != DBASEIII && format != DBASEIV && format != DBASEIII_WITH_MEMO && format != DBASEIV_WITH_MEMO &&
            format != FOXPRO_WITH_MEMO)
            throw new xBaseJException("Invalid format specified");

        if (destroy == false)
            if (ffile.exists())
                throw new xBaseJException("File exists, can't destroy");

        if (destroy == true) {
            if (ffile.exists())
                if (ffile.delete() == false)
                    throw new xBaseJException("Can't delete old DBF file");
            ffile = new File(DBFname);
        }


        FileOutputStream tFOS = new FileOutputStream(ffile);
        tFOS.close();

        file = new RandomAccessFile(DBFname, "rw");

        dosname = DBFname; //ffile.getAbsolutePath(); //getName();

        fld_root = new Vector(0);
        if (format != DBASEIII && format != DBASEIII_WITH_MEMO)
            MDX_exist = 1;

        boolean memoExists =
            (format == DBASEIII_WITH_MEMO || format == DBASEIV_WITH_MEMO || format == FOXPRO_WITH_MEMO);


        if (format == DBASEIV || format == DBASEIV_WITH_MEMO)
            MDX_exist = 1;

        db_offset(format, memoExists);


        update_dbhead();
        file.writeByte(13);
        file.writeByte(26);

        if (MDX_exist == 1)
            MDXfile = new MDXFile(DBFname, this, destroy);


    }

    /**
     * adds a new Field to a database
     * @param aField  a predefined Field object
     * @see Field
     * @exception xBaseJException
     *                                    xBaseJ error caused by called methods
     * @exception IOException
     *                                    Java error caused by called methods
     */

    public void addField(Field aField) throws xBaseJException, IOException {
        Field bField[] = new Field[1];
        bField[0] = aField;
        addField(bField);

    }


    /**
     * adds an array of new Fields to a database
     * @param aField  an array of  predefined Field object
     * @see Field
     * @exception xBaseJException
     *                                    passed an empty array or other error
     * @exception IOException
     *                                    Java error caused by called methods
     */

    public void addField(Field aField[]) throws xBaseJException, IOException {
        if (aField.length == 0)
            throw new xBaseJException("No Fields in array to add");


        if ((version == DBASEIII && MDX_exist == 0) || (version == DBASEIII_WITH_MEMO)) {
            if ((fldcount + aField.length) > 128)
                throw new xBaseJException("Number of fields exceed limit of 128.  New Field count is " +
                                          (fldcount + aField.length));
        } else {
            if ((fldcount + aField.length) > 255)
                throw new xBaseJException("Number of fields exceed limit of 255.  New Field count is " +
                                          (fldcount + aField.length));
        }

        int i, j;
        Field tField;

        boolean oldMemo = false;
        for (j = 0; j < aField.length; j++) {
            for (i = 1; i <= fldcount; i++) {
                tField = getField(i);
                if (tField instanceof MemoField || tField instanceof PictureField)
                    oldMemo = true;
                if (aField[j].getName().equalsIgnoreCase(tField.getName()))
                    throw new xBaseJException("Field: " + aField[j].getName() + " already exists.");
            }
        }

        short newRecl = lrecl;
        boolean newMemo = false;

        for (j = 1; j <= aField.length; j++) {
            newRecl += aField[j - 1].getLength();
            if ((dbtobj == null) && ((aField[j - 1] instanceof MemoField) || (aField[j - 1] instanceof PictureField)))
                newMemo = true;
            if (aField[j - 1] instanceof PictureField)
                version = FOXPRO_WITH_MEMO;
            else if ((aField[j - 1] instanceof MemoField) && (((MemoField) aField[j - 1]).isFoxPro()))
                version = FOXPRO_WITH_MEMO;
        }

        if (newRecl > 4000)
            throw new xBaseJException("Record length of 4000 exceeded.  New calculated length is " + newRecl);

        boolean createTemp = false;
        DBF tempDBF = null;
        String newName = "";

        if (fldcount > 0)
            createTemp = true;

        if (createTemp) {

            Random r = new Random();
            while (true) {


                int ir = r.nextInt();
                if (ir < 1000 || ir > 9999999)
                    continue;
                newName = ir + ".dbf";
                File f = new File(newName);
                if (f.exists() == false)
                    break;
            } // as of 12/27/2005


            //pos = dosname.toUpperCase().lastIndexOf(".DBF");
            //newName = new String(dosname.substring(0, pos) + ".tmd");
            int format = version;
            if ((format == DBASEIII) && (MDX_exist == 1))
                format = DBASEIV;

            tempDBF = new DBF(newName, format, true);


            tempDBF.version = (byte) format;
            tempDBF.MDX_exist = MDX_exist;

        }


        if (newMemo) {
            if (createTemp) {
                if ((version == DBASEIII || version == DBASEIII_WITH_MEMO) && (MDX_exist == 0))
                    tempDBF.dbtobj = new DBT_iii(this, newName, true);
                else if (version == FOXPRO_WITH_MEMO)
                    tempDBF.dbtobj = new DBT_fpt(this, newName, true);
                else
                    tempDBF.dbtobj = new DBT_iv(this, newName, true);
            } else {
                if ((version == DBASEIII || version == DBASEIII_WITH_MEMO) && (MDX_exist == 0))
                    dbtobj = new DBT_iii(this, dosname, true);
                else if (version == FOXPRO_WITH_MEMO)
                    dbtobj = new DBT_fpt(this, dosname, true);
                else
                    dbtobj = new DBT_iv(this, dosname, true);
            }
        } else if (createTemp && oldMemo) {
            if ((version == DBASEIII || version == DBASEIII_WITH_MEMO) && (MDX_exist == 0))
                tempDBF.dbtobj = new DBT_iii(this, newName, true);
            else if (version == FOXPRO_WITH_MEMO)
                tempDBF.dbtobj = new DBT_fpt(this, newName, true);
            else
                tempDBF.dbtobj = new DBT_iv(this, newName, true);
        }


        if (createTemp) {
            tempDBF.db_offset(version, newMemo || (dbtobj != null));
            tempDBF.update_dbhead();
            tempDBF.offset = offset;
            tempDBF.lrecl = newRecl;
            tempDBF.fldcount = fldcount;


            for (i = 1; i <= fldcount; i++) {
                try {
                    tField = (Field) getField(i).clone();
                } catch (CloneNotSupportedException e) {

                    throw new xBaseJException("Clone not supported logic error");
                }
                if (tField instanceof MemoField)
                    ((MemoField) tField).setDBTObj(tempDBF.dbtobj);
                if (tField instanceof PictureField)
                    ((PictureField) tField).setDBTObj(tempDBF.dbtobj);
                tField.setFile(tempDBF.file);
                tempDBF.fld_root.addElement(tField);
                tempDBF.write_Field_header(tField);
            }

            for (i = 0; i < aField.length; i++) {
                aField[i].setFile(tempDBF.file);
                tempDBF.fld_root.addElement(aField[i]);
                tempDBF.write_Field_header(aField[i]);
                tField = (Field) aField[i];
                if (tField instanceof MemoField)
                    ((MemoField) tField).setDBTObj(tempDBF.dbtobj);
                if (tField instanceof PictureField)
                    ((PictureField) tField).setDBTObj(tempDBF.dbtobj);

            }

            tempDBF.file.writeByte(13);
            tempDBF.file.writeByte(26);
            tempDBF.fldcount += aField.length;
            tempDBF.offset += (aField.length * 32);
        } else {
            lrecl = newRecl;
            int savefldcnt = fldcount;
            fldcount += aField.length;
            offset += (32 * aField.length);
            if (newMemo) {
                if (dbtobj instanceof DBT_iii)
                    version = DBASEIII_WITH_MEMO;
                else if (dbtobj instanceof DBT_iv) // if it's not dbase 3 format make it at least dbaseIV format.
                    version = DBASEIV_WITH_MEMO;
                else if (dbtobj instanceof DBT_fpt) // if it's not foxpro format make it at least dbaseIV format.
                    version = FOXPRO_WITH_MEMO;
            }
            update_dbhead();

            for (i = 1; i <= savefldcnt; i++) {
                tField = (Field) getField(i);
                if (tField instanceof MemoField)
                    ((MemoField) tField).setDBTObj(dbtobj);
                if (tField instanceof PictureField)
                    ((PictureField) tField).setDBTObj(tempDBF.dbtobj);
                write_Field_header(tField);
            }

            for (i = 0; i < aField.length; i++) {
                aField[i].setFile(file);
                tField = (Field) aField[i];
                if (tField instanceof MemoField)
                    ((MemoField) tField).setDBTObj(dbtobj);
                if (tField instanceof PictureField) {
                    ((PictureField) tField).setDBTObj(dbtobj);
                }
                fld_root.addElement(aField[i]);
                write_Field_header(aField[i]);
            }
            file.writeByte(13);
            file.writeByte(26);
            return; // nothing left to do, no records to write
        }


        for (j = 1; j <= count; j++) {
            Field old1;
            Field new1;
            gotoRecord(j);
            for (i = 1; i <= fldcount; i++) {
                old1 = getField(i);
                new1 = tempDBF.getField(i);
                new1.put(old1.get());
            }
            for (i = 0; i < aField.length; i++) {
                new1 = aField[i];
                new1.put("");
            }

            tempDBF.write();
        }


        tempDBF.update_dbhead();

        file.close();
        ffile.delete();

        if (dbtobj != null) {
            dbtobj.file.close();
            dbtobj.thefile.delete();
        }
        if (tempDBF.dbtobj != null) {
            tempDBF.dbtobj
                   .file
                   .close();
            tempDBF.dbtobj.rename(dosname);
            if ((version == DBASEIII || version == DBASEIII_WITH_MEMO) && (MDX_exist == 0))
                dbtobj = new DBT_iii(this, readonly);
            else if (version == FOXPRO_WITH_MEMO)
                dbtobj = new DBT_fpt(this, readonly);
            else
                dbtobj = new DBT_iv(this, readonly);
        }

        tempDBF.renameTo(dosname);


        tempDBF = null;

        ffile = new File(dosname);

        file = new RandomAccessFile(dosname, "rw");

        for (i = 0; i < aField.length; i++) {
            aField[i].setFile(file);
            fld_root.addElement(aField[i]);
        }

        //dosname = ffile.getName(); //AbsolutePath();

        read_dbhead();
        fldcount = (short) ((offset - 1) / 32 - 1);

        for (i = 1; i <= fldcount; i++) {
            tField = (Field) getField(i);
            tField.setFile(file);
            if (tField instanceof MemoField)
                ((MemoField) tField).setDBTObj(dbtobj);
            if (tField instanceof PictureField)
                ((PictureField) tField).setDBTObj(dbtobj);
        }

    }

    public void renameTo(String newname) throws IOException {
        file.close();
        File n = new File(newname);
        ffile.renameTo(n);
        dosname = newname;
    }


    /**
     * removes a Field from a database NOT FULLY IMPLEMENTED
     * @param aField  a field in the database
     * @see Field
     * @exception xBaseJException
     *                                    Field is not part of the database
     * @exception IOException
     *                                    Java error caused by called methods
     */

    public void dropField(Field aField) throws xBaseJException, IOException {
        int i;
        Field tField;
        for (i = 0; i < fldcount; i++) {
            tField = getField(i);
            if (aField.getName().equalsIgnoreCase(tField.getName()))
                break;
        }
        if (i > fldcount)
            throw new xBaseJException("Field: " + aField.getName() + " does not exist.");
    }


    /**
     * changes a Field in a database   NOT FULLY IMPLEMENTED
     * @param oldField  a Field object
     * @param newField  a Field object
     * @see Field
     * @exception xBaseJException
     *                                    xBaseJ error caused by called methods
     * @exception IOException
     *                                    Java error caused by called methods
     */
    public void changeField(Field oldField, Field newField) throws xBaseJException, IOException {
        int i, j;
        Field tField;
        for (i = 0; i < fldcount; i++) {
            tField = getField(i);
            if (oldField.getName().equalsIgnoreCase(tField.getName()))
                break;
        }
        if (i > fldcount)
            throw new xBaseJException("Field: " + oldField.getName() + " does not exist.");

        for (j = 0; j < fldcount; j++) {
            tField = getField(j);
            if (newField.getName().equalsIgnoreCase(tField.getName()) && (j != i))
                throw new xBaseJException("Field: " + newField.getName() + " already exists.");
        }

    }


    /**
     * returns the number of fields in a database
     */
    public int getFieldCount() {
        return fldcount;
    }

    /**
     * returns the number of records in a database
     */

    public int getRecordCount() {
        return count;
    }

    /**
     * returns the current record number
     */
    public int getCurrentRecordNumber() {
        return current_record;
    }

    /**
     * returns the number of known index files and tags
     */
    public int getIndexCount() {
        return jNDXes.size();
    }

    /**
     * gets an Index object associated with the database.  This index does not become the primary
     * index.  Written for the makeDBFBean application.  Position is relative to 1.
     * @param  indexPosition
     * @exception xBaseJException
     *                                    index value incorrect
     */
    public Index getIndex(int indexPosition) throws xBaseJException {
        if (indexPosition < 1)
            throw new xBaseJException("Index position too small");
        if (indexPosition > jNDXes.size())
            throw new xBaseJException("Index position too large");
        return (Index) jNDXes.elementAt(indexPosition - 1);

    }


    /**
     * opens an Index file associated with the database.  This index becomes the primary
     * index used in subsequent find methods.
     * @param filename      an existing ndx file(can be full or partial pathname) or mdx tag
     * @exception xBaseJException
     *                                    xBaseJ Fields defined in index do not match fields in database
     * @exception IOException
     *                                    Java error caused by called methods
     */
    public Index useIndex(String filename) throws xBaseJException, IOException {
        int i;
        Index NDXes;
        for (i = 1; i <= jNDXes.size(); i++) {
            NDXes = (Index) jNDXes.elementAt(i - 1);
            if (NDXes.getName().compareTo(filename) == 0) {
                jNDX = NDXes;
                return jNDX;
            }
        }
        if (readonly)
            jNDX = new NDX(filename, this, 'r');
        else
            jNDX = new NDX(filename, this, ' ');
        jNDXes.addElement(jNDX);
        return jNDX;
    }


    /**
     * opens an Index file associated with the database
     * @param filename      an existing Index file, can be full or partial pathname
     * @param ID      a unique id to define Index at run-time.
     * @exception xBaseJException
     *                                    xBaseJ Fields defined in Index do not match Fields in database
     * @exception IOException
     *                                    Java error caused by called methods
     */
    public Index useIndex(String filename, String ID) throws xBaseJException, IOException {
        useIndex(filename);
        jNDXID.addElement(ID);

        return useIndex(filename);
    }


    /**
     * used to indicate the primary Index
     * @param ndx  a Index object
     * @exception xBaseJException
     *                                    xBaseJ Index not opened or not part of the database
     * @exception IOException
     *                                    Java error caused by called methods
     */
    public Index useIndex(Index ndx) throws xBaseJException, IOException {
        int i;
        Index NDXes;
        for (i = 1; i <= jNDXes.size(); i++) {
            NDXes = (Index) jNDXes.elementAt(i - 1);
            if (NDXes == ndx) {
                jNDX = NDXes;
                return NDXes;
            }
        }
        throw new xBaseJException("Unknown Index " + ndx.getName());

    }

    /**
     * used to indicate the primary Index
     * @param ID  a string id
     * @exception xBaseJException
     *                                    xBaseJ Index not opened or not part of the database
     * @exception IOException
     *                                    Java error caused by called methods
     * @see DBF#useIndex(String,String)
     */
    public Index useIndexByID(String ID) throws xBaseJException {
        int i;
        String NDXes;
        for (i = 1; i <= jNDXID.size(); i++) {
            NDXes = (String) jNDXID.elementAt(i - 1);
            if (NDXes.compareTo(ID) == 0) {
                jNDX = (Index) jNDXes.elementAt(i - 1);
                return (Index) jNDXes.elementAt(i - 1);
            }
        }
        throw new xBaseJException("Unknown Index " + ID);

    }

    /**
     * associates all Index operations with an existing tag
     * @param tagname      an existing tag name in the production MDX file
     * @exception xBaseJException
     *                                    no MDX file
     *                                    tagname not found
     * @exception IOException
     *                                    Java error caused by called methods
     */
    public Index useTag(String tagname) throws xBaseJException {
        if (MDXfile == null)
            throw new xBaseJException("No MDX file associated with this database");
        jNDX = MDXfile.getMDX(tagname);
        return jNDX;
    }

    /**
     * associates all Index operations with an existing tag
     * @param tagname      an existing tag name in the production MDX file
     * @param ID      a unique id to define Index at run-time.
     * @exception xBaseJException
     *                                    no MDX file
     *                                    tagname not found
     * @exception IOException
     *                                    Java error caused by called methods
     */
    public Index useTag(String tagname, String ID) throws xBaseJException, IOException {
        useTag(tagname);
        jNDXID.addElement(ID);

        return useTag(tagname);
    }


    /**
     * creates a new Index as a NDX file, assumes NDX file does not exist
     * @param filename      a new Index file name
     * @param index          string identifying Fields used in Index
     * @param unique         boolean to indicate if the key is always unique
     * @exception xBaseJException
     *                                    NDX file already exists
     * @exception IOException
     *                                    Java error caused by called methods
     */
    public Index createIndex(String filename, String index, boolean unique) throws xBaseJException, IOException {
        return createIndex(filename, index, false, unique);
    }


    /**
     * creates a new Index as a NDX file
     * @param filename      a new Index file name
     * @param index          string identifying Fields used in Index
     * @param destroy       permission to destory NDX if file exists
     * @param unique         boolean to indicate if the key is always unique
     * @exception xBaseJException
     *                                    NDX file already exists
     * @exception IOException
     *                                    Java error caused by called methods
     */
    public Index createIndex(String filename, String index, boolean destroy, boolean unique) throws xBaseJException,
                                                                                                    IOException {
        jNDX = new NDX(filename, index, this, destroy, unique);
        jNDXes.addElement(jNDX);
        return jNDX;
    }


    /**
     * creates a tag in the MDX file
     * @param tagname      a non-existing tag name in the production MDX file
     * @param tagIndex      string identifying Fields used in Index
     * @param unique         boolean to indicate if the key is always unique
     * @exception xBaseJException
     *                                    no MDX file
     *                                    tagname already exists
     * @exception IOException
     *                                    Java error caused by called methods
     */
    public Index createTag(String tagname, String tagIndex, boolean unique) throws xBaseJException, IOException {
        if (MDXfile == null)
            throw new xBaseJException("No MDX file associated with this database");
        jNDX = MDXfile.createTag(tagname, tagIndex, unique);
        jNDXes.addElement(jNDX);
        return (MDX) jNDX;
    }

    /**
     * used to find a record with an equal or greater string value
     * when done the record pointer and field contents will be changed
     * @param keyString  a search string
     * @return boolean indicating if the record found contains the exact key
     * @exception xBaseJException
     *                                    xBaseJ no Indexs opened with database
     * @exception IOException
     *                                    Java error caused by called methods
     */
    public boolean find(String keyString) throws xBaseJException, IOException {
        if (jNDX == null)
            throw new xBaseJException("Index not defined");
        int r = jNDX.find_entry(keyString);
        if (r < 1)
            throw new xBaseJException("Record not found");

        gotoRecord(r);


        return jNDX.compareKey(keyString);

    }

    /**
     * used to find a record with an equal and at the particular record
     * when done the record pointer and field contents will be changed
     * @param keyString  a search string
     * @return boolean indicating if the record found contains the exact key
     * @exception xBaseJException
     *                                    xBaseJ Index not opened or not part of the database
     * @exception IOException
     *                                    Java error caused by called methods
     */
    public boolean find(String keyString, int recno) throws xBaseJException, IOException {
        if (jNDX == null)
            throw new xBaseJException("Index not defined");

        int r = jNDX.find_entry(keyString, recno);
        if (r < 1)
            throw new xBaseJException("Record not found");

        gotoRecord(r);

        return jNDX.compareKey(keyString);

    }

    /**
     * used to find a record with an equal string value
     * when done the record pointer and field contents will be changed only if the exact key is found
     * @param keyString  a search string
     * @return boolean indicating if the record found contains the exact key
     * @exception xBaseJException
     *                                    xBaseJ no Indexs opened with database
     * @exception IOException
     *                                    Java error caused by called methods
     */
    public boolean findExact(String keyString) throws xBaseJException, IOException {
        if (jNDX == null)
            throw new xBaseJException("Index not defined");
        int r = jNDX.find_entry(keyString);
        if (r < 1)
            return false;

        if (jNDX.didFindFindExact())
            gotoRecord(r);


        return jNDX.didFindFindExact();

    }


    /**
     * used to get the next  record in the index list
     * when done the record pointer and field contents will be changed
     * @exception xBaseJException
     *                                    xBaseJ Index not opened or not part of the database
     *                                    eof - end of file
     * @exception IOException
     *                                    Java error caused by called methods
     */

    public void findNext() throws xBaseJException, IOException {
        if (jNDX == null)
            throw new xBaseJException("Index not defined");
        int r = jNDX.get_next_key();
        if (r == -1)
            throw new xBaseJException("End Of File");

        gotoRecord(r);
    }

    /**
     * used to get the previous record in the index list
     * when done the record pointer and field contents will be changed
     * @exception xBaseJException
     *                                    xBaseJ Index not opened or not part of the database
     *                                    tof - top of file
     * @exception IOException
     *                                    Java error caused by called methods
     */
    public void findPrev() throws xBaseJException, IOException {
        if (jNDX == null)
            throw new xBaseJException("Index not defined");
        int r = jNDX.get_prev_key();
        if (r == -1)
            throw new xBaseJException("Top Of File");
        gotoRecord(r);

    }


    /**
     * used to read the next record, after the current record pointer, in the database
     * when done the record pointer and field contents will be changed
     * @exception xBaseJException
     *                                    usually the end of file condition
     * @exception IOException
     *                                    Java error caused by called methods
     */
    public void read() throws xBaseJException, IOException {
        /** reads the next record in the database */

        if (current_record == count)
            throw new xBaseJException("End Of File");

        current_record++;

        gotoRecord(current_record);

    }


    /**
     * used to read the previous record, before the current record pointer, in the database
     * when done the record pointer and field contents will be changed
     * @exception xBaseJException
     *                                    usually the top of file condition
     * @exception IOException
     *                                    Java error caused by called methods
     */


    public void readPrev() throws xBaseJException, IOException {
        /** reads the previous record in the database */

        if (current_record < 1)
            throw new xBaseJException("Top Of File");

        current_record--;
        gotoRecord(current_record);

    }


    /**
     * used to read a record at a particular place in the database
     * when done the record pointer and field contents will be changed
     * @param recno the relative position of the record to read
     * @exception xBaseJException
     *                                    passed an negative number, 0 or value greater than the number of records in database
     * @exception IOException
     *                                    Java error caused by called methods
     */


    public void gotoRecord(int recno) throws xBaseJException, IOException {
        /** goes to a specific record in the database */
        int i;
        Field tField;
        if ((recno > count) || (recno < 1)) {
            throw new xBaseJException("Invalid Record Number " + recno);
        }
        current_record = recno;

        seek(recno - 1);

        delete_ind = file.readByte();
        for (i = 0; i < fldcount; i++) {
            tField = (Field) fld_root.elementAt(i);
            tField.read();
        }

        Index NDXes;
        for (i = 1; i <= jNDXes.size(); i++) {
            NDXes = (Index) jNDXes.elementAt(i - 1);
            NDXes.set_active_key(NDXes.build_key());
        }

    }

    /**
     * used to position record pointer at the first record or index in the database
     * when done the record pointer will be changed.  NO RECORD IS READ.
     * Your program should follow this with either a read (for non-index reads) or findNext (for index processing)
     * @exception xBaseJException
     *                                    most likely no records in database
     * @exception IOException
     *                                    Java error caused by called methods
     */


    public void startTop() throws xBaseJException, IOException {
        if (jNDX == null)
            current_record = 0;
        else
            jNDX.position_at_first();
    }

    /**
     * used to position record pointer at the last record or index in the database
     * when done the record pointer will be changed. NO RECORD IS READ.
     * Your program should follow this with either a read (for non-index reads) or findPrev (for index processing)
     * @exception xBaseJException
     *                                    most likely no records in database
     * @exception IOException
     *                                    Java error caused by called methods
     */


    public void startBottom() throws xBaseJException, IOException {
        if (jNDX == null)
            current_record = count + 1;
        else
            jNDX.position_at_last();
    }

    /**
     * used to write a new record in the database
     * when done the record pointer is at the end of the database
     * @exception xBaseJException
     *                                    any one of several errors
     * @exception IOException
     *                                    Java error caused by called methods
     */
    public void write() throws xBaseJException, IOException {
        /** writes a new record in the database */
        int i;
        byte wb;
        Field tField;

        Index NDXes;
        for (i = 1; i <= jNDXes.size(); i++) {
            NDXes = (Index) jNDXes.elementAt(i - 1);
            NDXes.check_for_duplicates(Index.findFirstMatchingKey);
        }


        seek(count);
        delete_ind = NOTDELETED;
        file.writeByte(delete_ind);


        for (i = 0; i < fldcount; i++) {
            tField = (Field) fld_root.elementAt(i);
            tField.write();
        }


        wb = 0x1a;
        file.writeByte(wb);

        for (i = 1; i <= jNDXes.size(); i++) {
            NDXes = (Index) jNDXes.elementAt(i - 1);
            NDXes.add_entry((count + 1));
        }

        if (MDX_exist != 1 && (version == DBASEIII || version == DBASEIII_WITH_MEMO)) {
            byte array[] = new byte[lrecl];
            for (i = 0; i < lrecl; i++)
                array[i] = (byte) ' ';

            array[lrecl - 1] = wb;

            file.write(array);
        }


        count++;
        update_dbhead();

        current_record = count;


    }

    /**
     * updates the record at the current position
     * @exception xBaseJException
     *                                    any one of several errors
     * @exception IOException
     *                                    Java error caused by called methods
     */


    public void update() throws xBaseJException, IOException {

        /** updates the last record read */
        int i;
        Field tField;

        if ((current_record < 1) || (current_record > count)) {
            throw new xBaseJException("Invalid current record pointer");
        }

        seek(current_record - 1);
        file.readByte(); // don't change delete indicator let delete/undelete do that.

        Index NDXes;

        for (i = 1; i <= jNDXes.size(); i++) {
            NDXes = (Index) jNDXes.elementAt(i - 1);
            NDXes.check_for_duplicates(current_record);
        }

        for (i = 1; i <= jNDXes.size(); i++) //  reposition record pointer and current key for index update
        {
            NDXes = (Index) jNDXes.elementAt(i - 1);
            NDXes.find_entry(NDXes.get_active_key(), current_record);
        }


        for (i = 0; i < fldcount; i++) {
            tField = (Field) fld_root.elementAt(i);
            if (tField instanceof MemoField)
                tField.update();
            else
                tField.write();
        }

        for (i = 1; i <= jNDXes.size(); i++) {
            NDXes = (Index) jNDXes.elementAt(i - 1);
            NDXes.update(current_record);
        }


    }


    public void seek(long recno) throws IOException {

        long calcpos = (offset + (lrecl * recno));
        file.seek(calcpos);
    }


    /**
     * marks the current records as deleted
     * @exception xBaseJException
     *                                    usually occurs when no record has been read
     * @exception IOException
     *                                    Java error caused by called methods
     */


    public void delete() throws IOException, xBaseJException {
        /** marks current record as deleted */

        if ((current_record < 1) || (current_record > count)) {
            throw new xBaseJException("Invalid current record pointer");
        }

        seek(current_record - 1);
        delete_ind = DELETED;

        file.writeByte(delete_ind);

    }

    /**
     * marks the current records as not deleted
     * @exception xBaseJException
     *                                    usually occurs when no record has been read.
     * @exception IOException
     *                                    Java error caused by called methods
     */


    public void undelete() throws IOException, xBaseJException {

        /** marks current record as not deleted */

        if ((current_record < 1) || (current_record > count)) {
            throw new xBaseJException("Invalid current record pointer");
        }

        seek(current_record - 1);
        delete_ind = NOTDELETED;

        file.writeByte(delete_ind);

    }

    /**
     * closes the database
     * @exception IOException
     *                                    Java error caused by called methods
     */


    public void close() throws IOException {
        /** closes the DBF. Presently no method to reopen the database. */
        short i;


        if (dbtobj != null)
            dbtobj.close();

        Index NDXes;
        NDX n;

        for (i = 1; i <= jNDXes.size(); i++) {
            NDXes = (Index) jNDXes.elementAt(i - 1);
            if (NDXes instanceof NDX) {
                n = (NDX) NDXes;
                n.close();
            }
        }

        if (MDXfile != null)
            MDXfile.close();

        dbtobj = null;
        jNDXes = null;
        MDXfile = null;


        file.close();

    }

    /**
     * returns a Field object by its relative position
     * @param i Field number
     * @exception xBaseJException
     *                                    usually occurs when Field number is less than 1 or greater than the number of fields
     * @exception IOException
     *                                    Java error caused by called methods
     */


    public Field getField(int i) throws ArrayIndexOutOfBoundsException, xBaseJException {
        /** returns a Field object referred to by its position when defined */
        if ((i < 1) || (i > fldcount)) {
            throw new xBaseJException("Invalid Field number");
        }

        return (Field) fld_root.elementAt(i - 1);
    }

    /**
     * returns a Field object by its name in the database
     * @param name Field name
     * @exception xBaseJException
     *                                    Field name is not correct
     * @exception IOException
     *                                    Java error caused by called methods
     */

    public Field getField(String name) throws xBaseJException, ArrayIndexOutOfBoundsException {
        /** returns a Field object referred to by its name, not case sensitive */
        short i;
        Field tField;

        for (i = 0; i < fldcount; i++) {
            tField = (Field) fld_root.elementAt(i);
            if (name.toUpperCase().compareTo(tField.getName().toUpperCase()) == 0) {
                return tField;
            } /* endif */
        } /* endfor */

        throw new xBaseJException("Field not found " + name);
    }


    /**
     * returns the full path name of the database
     */

    public String getName() {
        /** returns operating system name of the database */
        return dosname;
    }


    /**
     * returns true if record is marked for deletion
     */


    public boolean deleted() {
        return (delete_ind == DELETED);
    }


    public void db_offset(int format, boolean memoPresent) {

        if (format == FOXPRO_WITH_MEMO)
            if (memoPresent)
                version = FOXPRO_WITH_MEMO;
            else
                version = DBASEIII;
        else if (format == DBASEIV_WITH_MEMO || format == DBASEIV || MDX_exist == 1)
            if (memoPresent)
                version = DBASEIV_WITH_MEMO;
            else
                version = DBASEIII; //DBASEIV;
        else if (memoPresent)
            version = DBASEIII_WITH_MEMO;
        else
            version = DBASEIII;


        count = 0; /* number of records in file */
        offset = 33; /* length of the offset includes the \r at end */
        lrecl = 1; /* length of a record includes the delete byte */
        incomplete_transaction = 0;
        encrypt_flag = 0;
        language = 0;

        // flip it back

    }

    public void read_dbhead() throws IOException {
        short currentrecord = 0; // not really used

        file.seek(0);
        version = file.readByte();
        file.read(l_update, 0, 3);

        count = Util.x86(file.readInt());
        offset = Util.x86(file.readShort());
        lrecl = Util.x86(file.readShort());

        currentrecord = Util.x86(file.readShort());
        current_record = Util.x86(currentrecord);

        incomplete_transaction = file.readByte();
        encrypt_flag = file.readByte();
        file.read(reserve, 0, 12);
        MDX_exist = file.readByte();
        language = file.readByte();
        file.read(reserve2, 0, 2);

    }

    public void update_dbhead() throws IOException {
        if (readonly)
            return;
        short currentrecord = 0;

        file.seek(0);

        Calendar d = Calendar.getInstance();

        if (d.get(Calendar.YEAR) < 2000)
            l_update[0] = (byte) (d.get(Calendar.YEAR) - 1900);
        else
            l_update[0] = (byte) (d.get(Calendar.YEAR) - 2000);

        l_update[1] = (byte) (d.get(Calendar.MONTH) + 1);
        l_update[2] = (byte) (d.get(Calendar.DAY_OF_MONTH));

        file.writeByte(version);
        file.write(l_update, 0, 3);
        file.writeInt(Util.x86(count));
        file.writeShort(Util.x86(offset));
        file.writeShort(Util.x86(lrecl));
        file.writeShort(Util.x86(currentrecord));

        file.write(incomplete_transaction);
        file.write(encrypt_flag);
        file.write(reserve, 0, 12);
        file.write(MDX_exist);
        file.write(language);
        file.write(reserve2, 0, 2);


    }


    public Field read_Field_header() throws IOException, xBaseJException {

        Field tField;
        int i;
        byte[] byter = new byte[15];
        String name;
        char type;
        byte length;
        int iLength;
        int decpoint;

        file.readFully(byter, 0, 11);
        for (i = 0; i < 12 && byter[i] != 0; i++)
            ;
        try {
            name = new String(byter, 0, i, DBF.encodedType);
        } catch (UnsupportedEncodingException UEE) {
            name = new String(byter, 0, i);
        }

        type = (char) file.readByte();

        file.readFully(byter, 0, 4);

        length = file.readByte();
        if (length > 0)
            iLength = (int) length;
        else
            iLength = 256 + (int) length;
        decpoint = file.readByte();
        file.readFully(byter, 0, 14);

        switch (type) {
        case 'C':
            tField = new CharField(name, iLength, file);
            break;
        case 'D':
            tField = new DateField(name, file);
            break;
        case 'F':
            tField = new FloatField(name, iLength, decpoint, file);
            break;
        case 'L':
            tField = new LogicalField(name, file);
            break;
        case 'M':
            tField = new MemoField(name, file, dbtobj);
            break;
        case 'N':
            tField = new NumField(name, iLength, decpoint, file);
            break;
        case 'P':
            tField = new PictureField(name, file, dbtobj);
            break;
        default:
            throw new xBaseJException("Unknown Field type for " + name);
        } /* endswitch */

        return tField;
    }


    public void write_Field_header(Field tField) throws IOException, xBaseJException {

        byte[] byter = new byte[15];


        int nameLength = tField.getName().length();
        int i = 0;
        byte b[];
        try {
            b = tField.getName()
                      .toUpperCase()
                      .getBytes(DBF.encodedType);
        } catch (UnsupportedEncodingException UEE) {
            b = tField.getName()
                      .toUpperCase()
                      .getBytes();
        }
        for (int x = 0; x < b.length; x++)
            byter[x] = b[x];

        file.write(byter, 0, nameLength);

        for (i = 0; i < 14; i++)
            byter[i] = 0;

        file.writeByte(0);
        if (nameLength < 10)
            file.write(byter, 0, 10 - nameLength);

        file.writeByte((int) tField.getType());

        file.write(byter, 0, 4);

        //file.skipBytes(4); this doesn't work in MACs when creating a file from scratch

        file.writeByte((int) tField.getLength());
        file.writeByte(tField.getDecimalPositionCount());


        if (version == DBASEIII || version == DBASEIII_WITH_MEMO)
            byter[2] = 1;


        file.write(byter, 0, 14);
        // file.skipBytes(14); this doesn't work in MACs when creating a file from scratch


    }


    public void setVersion(int b) {
        version = (byte) b;
    }


    /**
     * packs a DBF by removing deleted records and memo fields
     * @exception xBaseJException
     *                                    File does exist and told not to destroy it.
     * @exception xBaseJException
     *                                    Told to destroy but operating system can not destroy
     * @exception IOException
     *                                    Java error caused by called methods
     * @exception CloneNotSupportedException
     *                                    Java error caused by called methods
     */

    public void pack() throws xBaseJException, IOException, SecurityException, CloneNotSupportedException {
        Field Fields[] = new Field[fldcount];

        int i, j;
        for (i = 1; i <= fldcount; i++) {
            Fields[i - 1] = (Field) getField(i).clone();
        }


        String parent = ffile.getParent();
        if (parent == null)
            parent = ".";

        String tempname = new String(parent + File.separator + "temp.tmp");


        DBF tempDBF = new DBF(tempname, version, true);


        tempDBF.MDX_exist = MDX_exist;
        tempDBF.addField(Fields);

        Field t, p;
        for (i = 1; i <= count; i++) {
            gotoRecord(i);
            if (deleted()) {
                continue;
            }

            for (j = 1; j <= fldcount; j++) {
                t = tempDBF.getField(j);
                p = getField(j);
                t.put(p.get());
            }
            tempDBF.write();
        }


        file.close();
        ffile.delete();
        tempDBF.renameTo(dosname);

        //if (dbtobj != null && tempDBF.dbtobj == null) {
        if (dbtobj != null) {
            dbtobj.file.close();
            dbtobj.thefile.delete();
        }


        if (tempDBF.dbtobj != null) {
            //   tempDBF.dbtobj.file.close();
            tempDBF.dbtobj.rename(dosname);
            dbtobj = tempDBF.dbtobj;
            Field tField;
            MemoField mField;
            for (i = 1; i <= fldcount; i++) {
                tField = getField(i);
                if (tField instanceof MemoField) {
                    mField = (MemoField) tField;
                    mField.setDBTObj(dbtobj);
                }
            }
        }


        ffile = new File(dosname);

        file = new RandomAccessFile(dosname, "rw");

        //dosname = ffile.getName(); //AbsolutePath();

        read_dbhead();

        for (i = 1; i <= fldcount; i++)
            getField(i).setFile(file);

        Index NDXes;

        if (MDXfile != null)
            MDXfile.reIndex();

        if (jNDXes.size() == 0) {
            current_record = 0;
        } else {
            for (i = 1; i <= jNDXes.size(); i++) {
                NDXes = (Index) jNDXes.elementAt(i - 1);
                NDXes.reIndex();
            }
            NDXes = (Index) jNDXes.elementAt(0);
            if (count > 0)
                startTop();
        }


    }


    /** returns the dbase version field
     * @return int
     */


    public int getVersion() {
        return version;
    }

    /** sets the character encoding variable.
     * <br>  do this prior to opening any dbfs.
     * @param inType encoding type, default is "8859_1" could use "CP850" others
     */

    public static void setEncodingType(String inType) {
        encodedType = inType;
    }

    /** gets the character encoding string value
     * @return String "8859_1", "CP850", ...
     */

    public static String getEncodingType() {
        return encodedType;
    }


}
