#!/bin/bash
# Mon Aug 24 13:34:36 2009 SEC
# Bash script to install SpatialDB Advisor codesys schema and objects
# Translating from install.cmd
# UNIX is case sensitive .. some naming mismatches noted
# SEC
# Testing from Linux Oracle 10.1.0.5 client to
# AIX 11.1.0.7 Oracle server
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/11.1.0/db_1
export ORACLE_SID=cdobkup
echo ""
echo "Installing SpatialDB Advisor Code"
echo "================================="

yn() {
read -p "Reply [y/n]: " yn
 case $yn in
        [Yy]* ) yn="Y";;
        [Nn]* ) yn="N";;
        * ) echo "Please answer yes or no."; yn;
    esac
}

# Get user
ousr=""
echo $N "Enter install username (codesys): $C"
read ousr
if [ "$ousr" ] 
then
    echo "Setting install username to $ousr"
else
ousr="codesys"
    echo "Setting install username to $ousr"
fi
echo

# Get Password
opwd=""
echo $N "Enter $ousr password (codesys): $C"
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

# Determine if DB is 10+
echo "Is database version 10 and above?"
yn
VERSION10=$yn
    echo "Setting VERSION10 to $VERSION10"
echo ""

CENTROID=""
echo "Install CENTROID package only ? (Y/N default=N):"
yn
CENTROID=$yn

#Setup or clean log dir
if [ -d ./codesyslog ]; then
#echo "Removing codesyslog directory contents"
rm -f ./codesyslog/*
else
mkdir ./codesyslog
fi

# Create Schema Y/N ?
echo "Create Schema? (Y/N default=Y)"
yn
cschema=$yn
    echo "Setting cschema to $cschema"
echo ""

if [ $cschema = "Y" ]
then
  echo $N "Enter SYS password: $C"
  read spwd
  echo "Creating codesys schema..."
  sqlplus -s sys/$spwd@$osid AS SYSDBA @CREATE_schema  $ousr  $opwd > ./codesyslog/CREATE_schema.log
else
  echo "Dropping any existing Types, Tables and Packages... "
  echo "__ Dropping installed Tables ..."
  sqlplus $ousr/$opwd@$osid @DROP_Tables                $ousr > ./codesyslog/DROP_Tables.log
  echo "__ Dropping Packages ..."
  sqlplus $ousr/$opwd@$osid @DROP_Packages              $ousr > ./codesyslog/DROP_Packages.log
  echo "__ Dropping Types ..."
  sqlplus $ousr/$opwd@$osid @DROP_Types                 $ousr > ./codesyslog/DROP_Types.log
fi

# Install Common Scripts (Order is important)...
echo "Creating Oracle Test Data ..."
echo "__ Creating Oracle Test Geometries ..."
sqlplus $ousr/$opwd@$osid @CREATE_Ora_Test_Tables > ./codesyslog/CREATE_Ora_Test_Tables.log
echo "__ Creating Various Test Data ..."
sqlplus $ousr/$opwd@$osid @CREATE_Test_Tables  $ousr > ./codesyslog/CREATE_Test_Tables.log
echo "__ Creating Metadata Tables for use by functions in TOOLS package ..."
sqlplus $ousr/$opwd@$osid @CREATE_Metadata_Tables $ousr > ./codesyslog/CREATE_Metadata_Tables.log
echo "__ Creating tables that hold Oracle error messages ..."
sqlplus $ousr/$opwd@$osid @CREATE_sdo_geom_error_table $ousr> ./codesyslog/CREATE_sdo_geom_error_table.log

echo "Installing CENTROID package ..."
echo "__ Create required types ..."
sqlplus $ousr/$opwd@$osid @COMMON_types_and_functions $ousr > ./codesyslog/COMMON_types_and_functions.log
# Changed CENTROID_package to CENTROID_Package
sqlplus $ousr/$opwd@$osid @CENTROID_Package           $ousr > ./codesyslog/CENTROID_Package.log
echo "__ Test CENTROID package ..."
sqlplus $ousr/$opwd@$osid @CENTROID_package_test      $ousr > ./codesyslog/CENTROID_package_test.log

#Now we exit if we only want to install the CENTROID package.
if [ $CENTROID = "Y" ]; then
  echo "Centroid package installed... exiting"
  exit
fi

echo "__ Installing CONSTANTS Package ..."
# CONSTANTS_Package
sqlplus $ousr/$opwd@$osid @CONSTANTS_Package          $ousr > ./codesyslog/CONSTANTS_Package.log
echo "__ Installing ST_Point object ..."
# ST_Point_type
sqlplus $ousr/$opwd@$osid @ST_Point_type              $ousr > ./codesyslog/ST_Point_type.log
echo "____ Test ST_Point Type ..."
sqlplus $ousr/$opwd@$osid @ST_POINT_type_test         $ousr > ./codesyslog/ST_POINT_package_test.log

echo "Installing packages for all versions ..."
echo "__ Installing COGO package ..."
# COGO_PACKAGE
sqlplus $ousr/$opwd@$osid @COGO_PACKAGE               $ousr > ./codesyslog/COGO_PACKAGE.log
echo "____ Test COGO Package ..."
sqlplus $ousr/$opwd@$osid @COGO_package_test          $ousr > ./codesyslog/COGO_package_test.log
echo "__ Installing GF package ..."
# GF_Package
sqlplus $ousr/$opwd@$osid @GF_Package                 $ousr > ./codesyslog/GF_Package.log
echo "__ Installing MBR object ..."
sqlplus $ousr/$opwd@$osid @MBR_type                   $ousr > ./codesyslog/MBR_type.log
echo "____ Test MBR Object ..."
sqlplus $ousr/$opwd@$osid @MBR_type_test              $ousr > ./codesyslog/MBR_package_test.log
echo "__ Installing GEOM package ..."
sqlplus $ousr/$opwd@$osid @GEOM_Package               $ousr > ./codesyslog/GEOM_Package.log
echo "____ Testing GEOM Package ..."
sqlplus $ousr/$opwd@$osid @GEOM_package_test          $ousr > ./codesyslog/GEOM_package_test.log
echo "__ Installing TESSELATE package ..."
# TESSELATE_Package
sqlplus $ousr/$opwd@$osid @TESSELATE_Package          $ousr > ./codesyslog/TESSELATE_Package.log
echo "____ Test TESSELATE Package ..."
sqlplus $ousr/$opwd@$osid @TESSELATE_package_test     $ousr > ./codesyslog/TESSELATE_package_test.log
echo "__ Installing SDO_ERROR package ..."
sqlplus $ousr/$opwd@$osid @SDO_ERROR_Package          $ousr > ./codesyslog/SDO_ERROR_Package.log
echo "____ Test SDO_ERROR Package ..."
sqlplus $ousr/$opwd@$osid @SDO_ERROR_package_test     $ousr > ./codesyslog/SDO_ERROR_package_test.log
echo "__ Installing LINEAR package ..."
sqlplus $ousr/$opwd@$osid @LINEAR_Package             $ousr > ./codesyslog/LINEAR_Package.log
echo "____ Test LINEAR Package ..."
sqlplus $ousr/$opwd@$osid @LINEAR_package_test        $ousr > ./codesyslog/LINEAR_package_test.log

# REM If 9iR2 and below skip following packages 
# IF NOT %VERSION10%_ EQU Y_ GOTO INSTALLJAVA
if [ $VERSION10 = "N" ]; then
  echo "Installing 10g and above packages ..."
  echo "__ Installing KML package ..."
  # KML_Package
  sqlplus $ousr/$opwd@$osid @KML_Package                $ousr > ./codesyslog/KML_Package.log
  echo "____ Test KML Object ..."
  sqlplus $ousr/$opwd@$osid @KML_package_test           $ousr > ./codesyslog/KML_package_test.log
  echo "__ Installing TOOLS package ..."
  sqlplus $ousr/$opwd@$osid @TOOLS_package              $ousr > ./codesyslog/TOOLS_package.log
  echo "____ Test TOOLS package ..."
  sqlplus $ousr/$opwd@$osid @TOOLS_package_test         $ousr > ./codesyslog/TOOLS_package_test.log
  echo "__ Installing EMAIL package ..."
  sqlplus $ousr/$opwd@$osid @EMAIL_package              $ousr > ./codesyslog/EMAIL_package.log
  echo "__ Installing SQLMM type functions package ..."
  sqlplus $ousr/$opwd@$osid @ST_GEOM_package            $ousr > ./codesyslog/ST_GEOM_package.log
  echo "____ Testing SQLMM type functions ..."
  sqlplus $ousr/$opwd@$osid @ST_GEOM_package_test       $ousr > ./codesyslog/ST_GEOM_package_test.log
fi

echo "Finished installing tables and packages."

echo "If you find any bugs or improve this code please send the"
echo "changes to simon@spatialdbadvisor.com"

echo "================================================"

