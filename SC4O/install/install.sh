#!/bin/bash
# Bash script to install SpatialDB Advisor SC4O objects
# 
echo ""
echo "SC4O installer"
echo "=============="
echo ""
echo "************************************************"
echo "MAY NOT BE UP TO DATE CHECK AGAINST install.cmd"
echo "************************************************"

# Common function
yn() {
  read -p "Reply [y/n]: " yn
  case $yn in
       [Yy]* ) yn="Y";;
       [Nn]* ) yn="N";;
       * ) echo "Please answer yes or no."; yn;
  esac
}

# Get Oracle Home
#
ohome=""
if [ "${ORACLE_HOME}_" != _ ]
then
   if [ -e ${ORACLE_HOME} ]
   then
      ohome=${ORACLE_HOME}
   fi
fi
if [ "${ohome}_" = _ ]
then
   ohome="/oracle/product/10.2.0/db_1"
   uhome="_"
   while ! [ -d ${uhome} ] ; do
      # Don't display message first time around
      if [ "${uhome}_" = _ ] 
      then
         echo "ORACLE_HOME does not exist.";
      fi
      echo "Enter ORACLE_HOME path ($ohome):";
      read uhome;
   done
   ohome=${uhome}
fi

echo Oracle Home directory is: ${ohome}

# Get user
ousr=""
echo $N "Enter installation username (codesys): $C"
read ousr
if [ "$ousr" ] 
then
   echo "Setting installation username to $ousr"
else
   ousr="codesys"
   echo "Setting installation username to $ousr"
fi
echo ""

# Get Password
opwd=""
echo $N "Enter $ousr password (${ousr}): $C"
read opwd
if [ "$opwd" ] 
then
    echo "Setting $ousr password to $opwd"
else
    opwd="codesys"
    echo "Setting $ousr password to $opwd"
fi

# Get SID
echo ""
if [ ${ORACLE_HOME:-0} = 0 ]; then
   OLDHOME=$PATH
else
   OLDHOME=$ORACLE_HOME
fi

case ${ORAENV_ASK:-""} in                       #ORAENV_ASK suppresses prompt when set

    NO) NEWSID="$ORACLE_SID" ;;
    *)  case "$ORACLE_SID" in
            "") ORASID=$LOGNAME ;;
            *)  ORASID=$ORACLE_SID ;;
        esac
        echo $N "Enter TNSName ($ORASID): $C"
        #echo $N "ORACLE_SID = [$ORASID] ? $C"
        read NEWSID
        case "$NEWSID" in
            "")         ORACLE_SID="$ORASID" ;;
            *)          ORACLE_SID="$NEWSID" ;;         
        esac ;;
esac
export ORACLE_SID
echo "Setting ORACLE_SID to $ORACLE_SID"
echo
osid=$ORACLE_SID

CLASSPATH=${ohome}/jdk/jre/lib
export CLASSPATH
JAVA_HOME=${ohome}/jdk
export JAVA_HOME
PATH=${PATH}:${JAVA_HOME}/bin:${ohome}/bin
export PATH

#Setup or clean log dir
if [ -d ./log ]; then
   echo "Removing log directory contents"
   rm -f ./log/*
else
   mkdir ./log
fi

read -p "Drop, Install, Compile or CleaN [D/I/C/N]: " choice
case $choice in
     [Dd]* ) choice="D";;
     [Ii]* ) choice="I";;
     [Cc]* ) choice="C";;
     [Nn]* ) choice="N";;
     * ) echo "Please enter D,I,C or N."; choice;
esac

echo "Test schema permissions ...."
sqlplus -s $ousr/$opwd@$osid @test_permissions          > log/Test_Permissions.log
if [ $? != 0 ]; then
  echo "$ousr either has insufficient privileges for installation or is a non-JVM XE database. "
  echo "Check log/test_permissions.log for details."
  exit
fi

if [ $choice = "I" ]; then
  echo "Creating EXPORTER package..."
  echo "You may need to ensure ${ousr} has correct permissions to write to system folders."
  echo "See permissions.sql and permissions_sample.sql for examples."
  sqlplus -s $ousr/$opwd@$osid @EXPORTER_Package   $ousr > log/exporter_package.log
  if [ $? != 0 ]; then
     echo "EXPORTER package installation has errors: check log/exporter_package.log for details"
  fi
  echo "Creating SC4O package..."
  sqlplus -s $ousr/$opwd@$osid @SC4O_Package $ousr > log/SC4O_package.log
  if [ $? != 0 ]; then
     echo "SC4O package installation has errors: check log/SC4O_package.log for details"
  fi
  echo "Loading java classes ...."
  loadjava -force -oci -stdout -verbose -user ${ousr}/${opwd}@${osid} -resolve -grant PUBLIC -f SC4O.jar > log/SC4O_load.log
  echo "Install completed"
  exit
fi

if [ $choice = "C" ]; then
   echo "Compiling loaded java classes log/compile_java_11g.log for details ...."
   sqlplus -s $ousr/$opwd@$osid @compile_java_11g > log/compile_java_11g.log
   if [ $? != 0 ]; then
      echo "Compile unsuccessful ... check log/compile_java_11g.log for details."
      exit
   fi
   echo "Compile successful...."
fi

if [ $choice = "D" ]; then
   echo "Dropping EXPORTER and SC4O packages..."
   sqlplus -s $ousr/$opwd@$osid @Drop_Packages $ousr > log/drop_packages.log
   echo Dropping DBUtils.jar classes ...
   dropjava -verbose -force -oci -stdout -user ${ousr}/${opwd}@${osid} SC4O.jar > log/SC4O_drop.log
   echo "Drop successful...."
fi

if [ $choice = "N" ]; then
   echo "Cleaning $ousr USER_JAVA_CLASSES ..."
   sqlplus -s $ousr/$opwd@$osid @CLEAN_java $ousr > log/CLEAN_java.log
   if [ $? != 0 ]; then
      echo "Cleaning of user_java_classes produced an error: check log/CLEAN_java.log for details..."
      exit
   fi
   echo "Cleaning of $ousr USER_JAVA_CLASSES successful...."
fi
