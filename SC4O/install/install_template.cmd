@ECHO OFF
SETLOCAL

IF EXIST "%CD%\log" GOTO START
mkdir "%CD%\log"

IF EXIST "%CD%\log" GOTO START
ECHO Could not delete/create log directory.
GOTO FINISHED

:START 
DEL /Q "%CD%\log\*.log"
IF %ORACLE_HOME%_ EQU _ GOTO ORAHOME
SET ohome=%ORACLE_HOME%
:ORAHOME
SET ohome=F:\oracle\product\12.1.0\dbhome_1
SET /P ohome=Enter ORACLE_HOME PATH (%ohome%):
IF EXIST %ohome% GOTO USERNAME
ECHO ORACLE_HOME %ohome% does not exist.
GOTO ORAHOME

:USERNAME
SET PATH=%ohome%\bin;%PATH%

SET /P ousr=Enter username:
IF %ousr%_ EQU _ GOTO :username

SET /P opwd=Enter Password for %ousr% (def:%ousr%):
IF %opwd%_ EQU _ SET opwd=%ousr%

IF %ORACLE_SID%_ EQU _ GOTO ORA_SID
SET osid=%ORACLE_SID%
GOTO TEST_PERMISSIONS
:ORA_SID
SET /P osid=Enter ORACLE_SID (%osid%):
IF %osid%_ EQU _ GOTO ORA_SID

SET ohost=localhost
:GET_HOST
SET /P ohost=Enter Database Host (%ohost%):
IF %ohost%_ EQU _ GOTO GET_HOST

SET oport=1521
:GET_PORT
SET /P oport=Enter Port Number (%oport%):
IF %oport%_ EQU _ GOTO GET_PORT

REM Testing connection ....
sqlplus -l -s %ousr%/%opwd%@//%ohost%:%oport%/%osid% @CHECK_Connection > log\CHECK_Connection.log
IF %errorlevel% EQU 0 GOTO CHOICE_INPUT
ECHO Either the supplied username (%ousr%), password (%opwd%) or TNSNAME (%osid%) is incorrect.
GOTO FINISHED

:CHOICE_INPUT
SET CHOICE=I
SET /P CHOICE=(U)ninstall, (I)nstall, (C)ompile, (T)est or Clea(N) (%CHOICE%):
if /i %CHOICE%_ EQU I_ GOTO TEST_PERMS
if /i %CHOICE%_ EQU U_ GOTO UNINSTALL
if /i %CHOICE%_ EQU C_ GOTO COMPILEJAR
if /i %CHOICE%_ EQU T_ GOTO TEST_SC4O
if /i %CHOICE%_ EQU N_ GOTO CLEANJAVA
ECHO "%CHOICE%" is not valid, try again
GOTO CHOICE_INPUT

:TEST_PERMS
REM Test schema permissions ....
sqlplus -l -s %ousr%/%opwd%@//%ohost%:%oport%/%osid% @CHECK_Permissions > log\CHECK_Permissions.log
IF %errorlevel% EQU 0 GOTO INSTALL
ECHO Either:
ECHO 1) %ousr% has insufficient privileges for installation eg JAVAUSERPRIV.
ECHO 2) The database is a non-JVM (eg XE) database. 
ECHO Check log/test_permissions.log for details.
GOTO FINISHED

:INSTALL
IF _XXXXXXXX_ NEQ _EXPORTER_ GOTO INSTALLSC4O
ECHO Creating EXPORTER package...
ECHO You may need to ensure %ousr% has correct permissions to write to system folders.
ECHO See permissions.sql and permissions_sample.sql for examples.
sqlplus -s %ousr%/%opwd%@//%ohost%:%oport%/%osid% @CREATE_EXPORTER_Package %ousr% > log/CREATE_EXPORTER_Package.log
IF %errorlevel% EQU 0 GOTO INSTALLSC4O
ECHO EXPORTER Package installation has errors: check log/CREATE_EXPORTER_Package.log for details

:INSTALLSC4O
IF _XXXX_ NEQ _SC4O_ GOTO INSTALLJAR
ECHO Creating SC4O package...
sqlplus -s %ousr%/%opwd%@//%ohost%:%oport%/%osid% @CREATE_SC4O_Package %ousr% > log/CREATE_SC4O_Package.log
IF %errorlevel% EQU 0 GOTO INSTALLJAR
ECHO SC4O package installation has errors: check log/CREATE_SC4O_Package.log for details

:INSTALLJAR
REM Loading java classes ....
start /WAIT /B load_jar.cmd JARFILE %ohome% %ousr% %opwd% %ohost% %oport% %osid%
GOTO FINISHED

:COMPILEJAR
ECHO Compiling loaded java classes log\COMPILE_Java_11g.log for details ....
sqlplus -s %ousr%/%opwd%@//%ohost%:%oport%/%osid% @COMPILE_Java_11g > log\COMPILE_Java_11g.log
IF %errorlevel% EQU 0 GOTO COMPILE_SUCCESS
ECHO Compile unsuccessful ... check log\COMPILE_Java_11g.log for details.
ECHO Trying 10gR2 ncomp ....
start /WAIT /B run_ncomp.cmd %ohome% %ousr% %opwd% %osid%
GOTO FINISHED
:COMPILE_SUCCESS
ECHO Compile successful....
GOTO FINISHED

:TEST_SC4O
IF _XXXX_ NEQ _SC4O_ GOTO FINISHED
ECHO Testing SC4O PLSQL and Java classes ....
sqlplus -s %ousr%/%opwd%@//%ohost%:%oport%/%osid% @TEST_SC4O %ousr% > log/TEST_SC4O.log
IF %errorlevel% EQU 0 (
  ECHO ---- Testing successful....
) else (
  ECHO ---- SC4O package testing failed: check log/TEST_SC4O.log for details
)
GOTO FINISHED

:CLEANJAVA
ECHO Cleaning %ousr% USER_JAVA_CLASSES ...
sqlplus -s %ousr%/%opwd%@//%ohost%:%oport%/%osid% @CLEAN_Java %ousr% > log/CLEAN_Java.log
IF %errorlevel% EQU 0 GOTO CLEAN_SUCCESS
ECHO Cleaning of user_java_classes produced an error: check log/CLEAN_java.log for details
GOTO FINISHED
:CLEAN_SUCCESS
ECHO Cleaning of %ousr% USER_JAVA_CLASSES successful....
GOTO FINISHED

:UNINSTALL
IF _XXXXXXXX_ NEQ _EXPORTER_ GOTO UNINSTALLSC4O
ECHO Dropping EXPORTER package ...
sqlplus -s %ousr%/%opwd%@//%ohost%:%oport%/%osid% @DROP_EXPORTER_Package %ousr% > log/DROP_EXPORTER_Package.log

:UNINSTALLSC4O
IF _XXXX_ NEQ _SC4O_ GOTO FINISHED
ECHO Dropping SC4O package ...
sqlplus -s %ousr%/%opwd%@//%ohost%:%oport%/%osid% @DROP_SC4O_Package %ousr% > log/DROP_SC4O_Package.log

ECHO Dropping Java classes...
start /WAIT /B drop_jar.cmd JARFILE %ohome% %ousr% %opwd% %ohost% %oport% %osid%

:FINISHED
ENDLOCAL
pause
