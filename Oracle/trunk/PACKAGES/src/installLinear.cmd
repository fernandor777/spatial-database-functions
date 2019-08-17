@ECHO OFF

IF EXIST log\NUL (
del /F /Q log\*.log  > NUL
) else (
mkdir log
IF %errorlevel% EQU 0 GOTO START
ECHO Could not delete/create log directory.
GOTO EXIT
)

:START
IF %ORACLE_HOME%_ EQU _ GOTO ORAHOMESET
SET ohome=%ORACLE_HOME%
GOTO ORAHOME
:ORAHOMESET
IF %ohome%_ EQU _ SET ohome=F:\oracle\product\12.1.0\dbhome_1

:ORAHOME
SET /P ohome=Enter ORACLE_HOME path (%ohome%):
IF EXIST %ohome% GOTO SETPATH
ECHO ORACLE_HOME does not exist.
GOTO ORAHOME

:SETPATH 
SET Path=%ohome%\bin;C:\WINDOWS\system32;C:\WINDOWS;c:\WINDOWS\system32\WBEM

SET ousr=
SET opwd=
SET /P ousr=Enter username to hold LINEAR package and types (codesys):
IF %ousr%_ EQU _ SET ousr=codesys
SET /P opwd=Enter %ousr% password (%ousr%):
IF %opwd%_ EQU _ SET opwd=%ousr%
IF %ORACLE_SID%_ EQU _ SET ORACLE_SID=DBGIS2
SET /P osid=Enter TNSName (%ORACLE_SID%):
IF %osid%_ EQU _ SET osid=%ORACLE_SID%

SET /P cschema=Create Schema (Y/N)? (N):
IF %cschema%_ EQU _ SET cschema=N
IF     %cschema%_ EQU y_ ( SET cschema=Y )
IF NOT %cschema%_ EQU Y_ GOTO TESTPERMS
SET /P spwd=Enter SYS password:
sqlplus -s "sys/%spwd%@%osid% AS SYSDBA" @CREATE_schema %ousr% %opwd% > log\CREATE_schema.log

:TESTPERMS
ECHO Checking schema permissions ...
sqlplus -L %ousr%/%opwd%@%osid% @CHECK_Permissions %ousr%             > log\CHECK_Permissions.log
IF %errorlevel% EQU 0 GOTO DROPOBJECTS
ECHO ___ %ousr% has insufficient privileges for installation. Check log for details.
GOTO EXIT

:DROPOBJECTS
ECHO ___ %ousr% has correct privileges for installation. 

IF %cschema%_ EQU Y_ GOTO INSTALLSCRIPTS
:DROPQN
SET /P dropExistOnly=Drop Existing Objects Only (Y/N)? (N):
IF %dropExistOnly%_ EQU _  SET dropExistOnly=N
IF %dropExistOnly%_ EQU n_ SET dropExistOnly=N
IF %dropExistOnly%_ EQU y_ SET dropExistOnly=Y
IF %dropExistOnly%_ EQU Y_ GOTO DODROP
IF NOT %dropExistOnly%_ EQU N_ GOTO DROPQN
:DODROP
ECHO Dropping Types, Packages, Tables etc 
ECHO __ Dropping installed Tables and any sequences...
sqlplus -L %ousr%/%opwd%@%osid% @DROP_Tables             %ousr% > log\DROP_Tables.log
ECHO __ Dropping Packages ...
sqlplus -L %ousr%/%opwd%@%osid% @DROP_LINEAR_Package     %ousr% > log\DROP_LINEAR_Package.log
ECHO __ Dropping Types ...
sqlplus -L %ousr%/%opwd%@%osid% @DROP_Types              %ousr% > log\DROP_Types.log
IF %dropExistOnly%_ EQU Y_ GOTO EXIT

:INSTALLSCRIPTS
ECHO ___ %ousr% has correct privileges for installation. 
ECHO Creating Oracle Test Data ...
ECHO __ Creating Linear Test Geometries ...
sqlplus -L %ousr%/%opwd%@%osid% @CREATE_LINEAR_Tables           > log\CREATE_LINEAR_Tables.log

ECHO Installing COMMON Types ...
sqlplus %ousr%/%opwd%@%osid% @COMMON_types_and_functions %ousr% > log\COMMON_types_and_functions.log
ECHO Installing LINEAR package ...
sqlplus %ousr%/%opwd%@%osid% @LINEAR_package             %ousr% > log\LINEAR_package.log
IF %errorlevel% EQU 0 GOTO LINEARTEST
ECHO ___ %ousr% LINEAR_package failed installation (%errorlevel%). Check log for details.
GOTO EXIT
:LINEARTEST
ECHO __ Test LINEAR package ...
sqlplus %ousr%/%opwd%@%osid% @LINEAR_package_test        %ousr% > log\LINEAR_package_test.log

ECHO Finished installing LINEAR package.
ECHO If you find any bugs or improve this code please 
ECHO send the changes to simon@spatialdbadvisor.com
ECHO ================================================

:EXIT

pause
