package org.xBaseJ.micro.indexes;
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
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.RandomAccessFile;

import org.xBaseJ.micro.DBF;
import org.xBaseJ.micro.xBaseJException;

public class MDXFile {

public File file;
public RandomAccessFile nfile;
String name;
public MDXAnchor anchor;
public TagDescriptor tags[];
public MDX MDXes[];
public final short maxTags=47;
DBF database;

public MDXFile(String Name, DBF inDBF, char readonly) throws IOException, xBaseJException
{

  short i;
  database = inDBF;

  //  MDXFileData  ;		/* set in BeginInitializer */  ????????
  name = Name.substring(0,Name.lastIndexOf('.'))+".mdx";

  file = new File(name);

  if (!file.exists())
     throw new xBaseJException("Missing mdx file:" + name);

  if (readonly == 'r')
    nfile = new RandomAccessFile(file, "r");
  else
    nfile = new RandomAccessFile(file, "rw");

  anchor = new MDXAnchor(nfile);
  anchor.read();
  tags = new TagDescriptor[maxTags];
  MDXes = new MDX[maxTags];
  for (i=0; i<anchor.indexes; i++){
     tags[i] = new TagDescriptor(nfile, (short) (i+1));
     MDXes[i] = new MDX(this, inDBF, i);
    }
  for (; i<maxTags; i++) {
     MDXes[i] = null;
     tags[i] = null;
    }

}

public MDXFile(String Name, DBF inDBF, boolean destroy) throws IOException
{

  int i;
  database = inDBF;

  //  MDXFileData  ;		/* set in BeginInitializer */  ????????

  name = Name.substring(0,Name.lastIndexOf('.'))+".mdx";

  file = new File(name);

  FileOutputStream tFOS = new FileOutputStream(file);
  tFOS.close();


  nfile = new RandomAccessFile(file, "rw");
  anchor = new MDXAnchor(nfile);
  anchor.set(Name.substring(0,Name.lastIndexOf('.')));

  anchor.write();

  byte wb[] = new byte[32];

  for (i = 0; i < 32; i++) wb[i] = 0;
  nfile.seek(512);
  nfile.write(wb);

  tags = new TagDescriptor[maxTags];
  MDXes = new MDX[maxTags];
}

public void close() throws IOException
{
  nfile.close();
}


public MDX getMDX(String Name) throws xBaseJException
{
  int i;
  for (i=0; i<anchor.indexes; i++)
   {
     if ( tags[i].name.equalsIgnoreCase(Name) )
        return MDXes[i];
    }

  throw new xBaseJException("Unknown tag named " + Name);
}


public TagDescriptor getTagDescriptor(int i)
{
        return tags[i];
}



public TagDescriptor getTagDescriptor(String Name) throws xBaseJException
{
  int i;
  for (i=0; i<anchor.indexes; i++)
   {
     if ( tags[i].name.equalsIgnoreCase(Name) )
        return tags[i];
    }

  throw new xBaseJException("Unknown tag named " + Name);
}



public MDX createTag(String Name, String Index, boolean unique) throws IOException,  xBaseJException
{

  Name = Name.toUpperCase();
  if (anchor.indexes >= maxTags)
     throw new xBaseJException("Can't create another tag. Maximum of " + maxTags + " reached");

  try
    {
       getTagDescriptor(Name);
       throw new xBaseJException("Tag name already in use");
    }
  catch (xBaseJException e)
    {
       if (!e.getMessage().startsWith("Unknown tag named"))
         throw e;
    }

  short i = (short) (anchor.indexes+1);
  tags[i-1] = new TagDescriptor(this,  i, Name);
  MDX newMDX = new MDX(Name, Index, database, this, tags[i-1],  i, unique);
  anchor.indexes = i;
  anchor.write();
  MDXes[i-1] = newMDX;


  if (i > 1)
     tags[i-2].updateForwardTag(i);

  return newMDX;

}

public short  get_tag_count()
{
  return anchor.indexes;
}





public void  set_blockbytes(short bytes)
{
  anchor.blockbytes = bytes;

}




 public void  drop_tag_count() throws IOException
{
  anchor.indexes--;
  anchor.write();
}



void  write_create_header() throws IOException
{
  byte wb[] = new byte[32];

  for (int i = 0; i < 32; i++) wb[i] = 0;

  nfile.seek(512);

  nfile.write(wb);

}



public void reIndex() throws IOException, xBaseJException
{
  short oldIndexCount = anchor.indexes;
  short i;
  nfile.close();
  file.delete();
  nfile = new RandomAccessFile(file, "rw");
  anchor.reset(nfile);
  anchor.write();
  for (i = 0; i < oldIndexCount; i++)
    {
      MDXes[i].tagDesc.indheaderpage = anchor.next_available;
      MDXes[i].tagDesc.reset(nfile);
      MDXes[i].tagDesc.write();
      MDXes[i].tagHead.reset(nfile);
      MDXes[i].tagHead.setPos((short) anchor.next_available);
      MDXes[i].tagHead.write();
      if (i > 1)
          tags[i-2].updateForwardTag(i);
      anchor.update_nextavailable();
    }
  anchor.indexes = oldIndexCount;
  anchor.write();

}


}

