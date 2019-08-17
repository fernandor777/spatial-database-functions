#!/bin/sh
#
# pldoc.sh - Unix start script
# $Id: pldoc.sh,v 1.8 2006/01/24 16:13:56 gpaulissen Exp $
#
# Normally, editing this script should not be required.
#
# The installation idea is to unpack the PLDoc tar/zip in lets say:
# /usr/local/pldoc
# and then make a symbolic link to pldoc.sh in /usr/local/bin, ex.
# $ cd /usr/local/bin ; ln -s /usr/local/pldoc/pldoc.sh pldoc

PRG=$0

#
# Resolve the location of the pldoc installation
# resolve symlinks (idea taken from Netbean's runide.sh)
#
while [ -h "$PRG" ]; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '^.*-> \(.*\)$' 2>/dev/null`
    if expr "$link" : '^/' 2> /dev/null >/dev/null; then
	PRG="$link"
    else
	PRG="`dirname "$PRG"`/$link"
    fi
done

pldir=`dirname "$PRG"`

# absolutize pldir
oldpwd=`pwd` ; cd "${pldir}"; pldir=`pwd`; cd "${oldpwd}"; unset oldpwd

# Set bootclasspath.
# NB: this is needed to make JDK1.4 use our Xerces version instead of internal parser
bcp="${pldir}/xalan/bin/xalan.jar:${pldir}/xalan/bin/xml-apis.jar:${pldir}/xalan/bin/xercesImpl.jar"
#
# Set classpath
# NB: classpath must contain the pldoc directory to be able to locate .xsl files
cp="${pldir}:${pldir}/pldoc.jar"

# Save arguments
args=$*

# Are the Oracle jars needed?
while test -n "$1"
do
  if [ "$1" = "-url" ]
  then
    if [ -z "$ORACLE_HOME" ]
    then
      echo ERROR: Environment variable ORACLE_HOME not set. 1>&2
      exit 1
    else
      cp="${cp}:$ORACLE_HOME/jdbc/lib/ojdbc14.jar:$ORACLE_HOME/jdbc/lib/classes12.jar"
    fi
    break
  fi
  shift
done

#
# Call PLDoc
java -Xbootclasspath/p:"$bcp" -cp "$cp" net.sourceforge.pldoc.PLDoc $args
