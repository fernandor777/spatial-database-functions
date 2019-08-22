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
echo "Installing SpatialDB Advisor Oracle Object Code"
echo "==============================================="

rm -f -r log
mkdir log 

# Get user
ousr="codesys"
read -p "Enter install username ($ousr):" ousr
if [ -z "$ousr" ] 
then
  ousr="codesys"
fi
echo "Setting install username to $ousr"
echo

# Get Password
opwd=$ousr
read -p "Enter $ousr password ($ousr): " opwd
if [ -z "$opwd" ] 
then
  opwd="$ousr"
fi
echo "Setting $ousr password to $opwd"
echo

# Get SID
echo ""
if [ ${ORACLE_HOME:-0} = 0 ]
then
  OLDHOME=$PATH
else
  OLDHOME=$ORACLE_HOME
fi
echo "ORACLE_HOME is $OLDHOME"

case ${ORAENV_ASK:-""} in                       #ORAENV_ASK suppresses prompt when set

  NO) NEWSID="$ORACLE_SID" ;;
  *)  case "$ORACLE_SID" in
          "") ORASID=$LOGNAME ;;
          *)  ORASID=$ORACLE_SID ;;
      esac
      echo $N "Enter TNSName ($ORASID): $C"
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

# Get server
ohost="localhost"
read -p "Enter Server eg $ohost (localhost):" ohost
if [ -z "$ohost" ] 
then
  ohost="localhost"
fi
echo "Setting Server to $ohost"
echo

# Get post
oport="1521"
read -p "Enter Port Number ($oport): " oport
if [ -z "$oport" ] 
then
  oport="1521"
fi
echo "Setting Port Number to $oport"
echo

echo Testing connection ...
echo __Using: $ousr/$opwd@//$ohost:$oport/$osid 
sqlplus -s $ousr/$opwd@//$ohost:$oport/$osid @Test_Permissions.sql > log/Test_Permissions.log
if [ $? -eq 0 ]
then
  echo "____ Supplied Connection Parameters are correct."
else
  echo "_______ Cannot connect with supplied information, or has insufficient privileges for installation..."
  echo "_______ Check log/test_permissions.log for details."
  exit 1;
fi

# Drop Objects?
DROP=""

echo "Drop Existing Installed Database Objects? (Y/N default=N):" 
select yn in "Yes" "No"; 
do
 echo $REPLY 
 if [ $REPLY -eq 1 ]
 then
   sqlplus -s $ousr/$opwd@//$ohost:$oport/$osid @Drop_All.sql $ousr > log/Drop_All.log; 
   echo "Existing objects dropped ($?).";
   break;
 else
   break;
 fi
done

echo "Installing All Types, Packages and Functions..."
echo "... Package and Type Headers ..."
TYPEHEADERS=(
  Package_TOOLS 
  Package_COGO 
  T_Grid 
  T_ElemInfo 
  T_Vertex 
  T_MBR 
  T_Segment 
  T_Bearing_Distance 
  T_Vector3D 
  T_Geometry 
  Package_PRINT
)
for F in "${TYPEHEADERS[@]}"; do
  echo "Installing $F.sql will create log/$F.log ...";
  if [ -f "$F.sql" ]
  then
    sqlplus -s $ousr/$opwd@//$ohost:$oport/$osid @$F.sql $ousr > log/$F.log
    if [ $? -eq 0 ]
    then
      echo "... Successful."
    else 
      echo "... Failed. Check log/$F.log for details..."
      exit 1;
    fi
  else
    echo "... SQL file $F.sql does not exist, skipping ..."
  fi
done

echo ... "Type Bodies and Debug/ST_LRS packages ..."
BODIES=(
  Package_TOOLS_Body 
  Package_PRINT_Body 
  Package_COGO_Body 
  Package_ST_LRS 
  T_Vector3D_Body 
  T_Vertex_Body 
  T_MBR_Body 
  T_Segment_Body 
  T_Bearing_Distance_Body 
  T_Geometry_Body
)
for F in "${BODIES[@]}"; do
  echo "Installing $F.sql will create log/$F.log ..."
  if [ -f "$F.sql" ]
  then
    sqlplus -s $ousr/$opwd@//$ohost:$oport/$osid @$F.sql $ousr > log/$F.log
    if [ $? -eq 0 ]
    then
      echo "... Successful."
    else 
      echo "... Failed. Check log/$F.log for details."
      exit 1;
    fi
  else
    echo "... SQL file $F.sql does not exist, skipping ..."
  fi
done

echo "Checking status of installation..."
sqlplus -s $ousr/$opwd@//$ohost:$oport/$osid @Check_Installation.sql $ousr > log/Check_Installation.log
if [ $? -eq 0 ]
then
  echo "Installation of Types And Packages Successful..."
else 
  echo "Installation Failed Check log/install_check.log for details..."
fi

more log/Check_Installation.log

exit 0;
