********************************************************************************

             PLDoc utility for documenting PL/SQL code
             =========================================

Copyright (C) 2002  Albert Tumanov (altumano@users.sourceforge.net)

$Id: readme.txt,v 1.33 2005/11/29 08:25:00 gpaulissen Exp $

Project directory: http://pldoc.sourceforge.net

********************************************************************************

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

********************************************************************************

This product includes software developed by the Apache Software Foundation:
  http://www.apache.org
See file xalan/license for information on redistribution.

********************************************************************************


	INSTALLATION AND USE


1) Install Java runtime version 1.2 or above, if not yet installed
   (available from http://java.sun.com).
2) Unpack the pldoc zip file into a new directory.
3) Run pldoc_example.bat (on Windows) or pldoc_example.sh (on UNIX) to verify installation
   and get sample output. It generates html output from the sample files
   into SampleApplicationDoc directory.
4) Edit pldoc_example.bat to try out your own files.


	CONVENTIONS FOR FORMAL COMMENTS IN THE CODE


The same rules for writing formal comments apply as for javadoc tool:
  http://java.sun.com/j2se/javadoc/writingdoccomments/index.html
Then only addition is the @headcom tag that allows a comment on package to be
placed after the "PACKAGE ... IS" keywords.
NB: the @headcom tag must be placed AFTER the main comment text.


	KNOWN PROBLEMS AND LIMITATIONS


* Currently, only package specs can be processed.
  You should not have package bodies, standalone function/procedures or types in the input files.
* PLDoc mostly conforms to PL/SQL 9.0.1 specification.
* PLDoc tries to read and understand informal comments like (--...) and (/*...*/)
  in those places where documentation comments are expected.
  But for the best results, use formal comments (/**...*/).
  Future versions of PLDoc are likely to ignore informal comments altogether.
* Some SQL*Plus commands and variables in the source may cause PLDoc to fail.
* Comment texts are treated as HTML, but only well-formed XHTML tags
  are allowed (must use <br/> instead of <br> etc).
* Only @headcom, @deprecated, @param, @return and @throws tags are supported at the moment.
* Deprecated and Index pages not generated.
* One-line comments are ignored except before package members.


	BUILDING FROM SOURCE


Both binaries and source are included in the distribution.
You need not to rebuild the source unless you have it modified.
If you have modified only the .xsl files, no rebuild is necessary.
But you must rebuild after modifying .java or .jj files.
To rebuild, you must first install the Ant utility (http://ant.apache.org/).
Also, download and install the JavaCC utility from https://javacc.dev.java.net/.
(Do NOT add any JavaCC files to the classpath).
Then, run the make.bat (or make.sh on UNIX) from the build directory and check the output for errors.
The make.bat assumes that Ant utility is in your path
and also that you have defined environment variable JAVACC_HOME pointing
to the JavaCC directory. The environment variable ORACLE_HOME must point
to the Oracle home directory where JDBC and SQLJ jar files are located.
Either define appropriate variables or make changes in the make.bat file.


	GETTING THE LATEST SOURCE


To get the latest source, you must have CVS client installed.
The basic command for getting the very latest source is:

cvs -d:pserver:anonymous@cvs.sourceforge.net:/cvsroot/pldoc login
cvs -d:pserver:anonymous@cvs.sourceforge.net:/cvsroot/pldoc checkout sources

If you need source from specific branch (say, "branchXYZ"), use:

cvs -d:pserver:anonymous@cvs.sourceforge.net:/cvsroot/pldoc checkout -r branchXYZ sources

See also SourceForge CVS usage instructions:
http://sourceforge.net/cvs/?group_id=38875

********************************************************************************
