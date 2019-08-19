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




class BinaryTree extends Object
{
public BinaryTree lesser;
public BinaryTree greater;
public BinaryTree above;
public NodeKey key;
public int where;

NodeKey getKey()
{
return key;
}

int getWhere()
{
return where;
}

public void setLesser(BinaryTree inTree)
{
lesser = inTree;
}

public void setGreater(BinaryTree inTree)
{
greater = inTree;
}

public BinaryTree(NodeKey inkey, int inWhere, BinaryTree top)
{
above = null;
lesser = null;
greater = null;
key = inkey;
where = inWhere;

if (top != null) {
  above = top.findPos(key);
  if (above.getKey().compareKey(inkey) > 0) above.setLesser(this);
  else above.setGreater(this);
 }


}

//public void dump()
//{
//System.out.println(key);
//if (above == null) System.out.println("no above"); else System.out.println("above is " + above.getKey());
//if (lesser == null)  System.out.println("no lesser"); else System.out.println("lesser is " + lesser.getKey());
//if (greater == null) System.out.println("no greater"); else System.out.println("greater is " + greater.getKey());
//}

public BinaryTree findPos(NodeKey inkey)
{

if (key.compareKey(inkey) > 0)
   if (lesser == null) return this;
   else return(lesser.findPos(inkey));
else
   if (greater == null) return this;
return(greater.findPos(inkey));
}

public BinaryTree getLeast()
{
  if (lesser != null) {
     return (lesser.getLeast());
     }
  return this;
}

public BinaryTree getNext()
{
  if (greater == null)
       if (above == null) return null;
       else return above.goingUp(key);
  return greater.getLeast();
}

public BinaryTree goingUp(NodeKey inKey)
{
  if (key.compareKey(inKey) <= 0)
     if (above == null) return null;
     else return above.goingUp(key);
  return this;
}


}
