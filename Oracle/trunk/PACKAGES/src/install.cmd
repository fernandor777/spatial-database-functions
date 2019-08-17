@ECHO OFF

ECHO =================================
ECHO Package Creation Script
ECHO =================================

ECHO This script only installs packages in an Empty Schema.
ECHO To Remove existing objects use the UNINSTALL.CMD script
SET cInstall=Y
SET /P cInstall=Continue Installation (Y/N)? (N):
IF     %cInstall%_ EQU _  GOTO EXIT
IF     %cInstall%_ EQU y_ GOTO FOLDERCHECK
IF NOT %cInstall%_ EQU Y_ GOTO EXIT

:FOLDERCHECK
ECHO LOG Folder Checks...
IF EXIST "%CD%\log" (
  ECHO Removing existing LOG folder and files
  DEL /S /Q "%CD%\log\*" > NUL
) else (
  mkdir "%CD%\log"
  IF %errorlevel% EQU 0 GOTO START
  ECHO Could not create LOG folder.
  GOTO EXIT
)

REM ------------------------- Oracle Home and Path Setting
:START
IF %ORACLE_HOME%_ EQU _ GOTO ORAHOMESET
SET ohome=%ORACLE_HOME%
GOTO ORAHOME
:ORAHOMESET
IF %ohome%_ EQU _ SET ohome=F:\oracle\product\12.1.0\dbhome_1
:ORAHOME
SET /P ohome=Enter ORACLE_HOME path (%ohome%):
IF EXIST %ohome% GOTO DOSETS
ECHO ORACLE_HOME does not exist.
GOTO ORAHOME

:DOSETS 
SET ORACLE_HOME=%ohome%
SET Path=%ohome%\bin;C:\WINDOWS\system32;C:\WINDOWS;c:\WINDOWS\system32\WBEM

REM ------------------------- Log on Information
SET ousr=
SET opwd=
SET /P ousr=Enter username for types and packages (codesys):
IF %ousr%_ EQU _ SET ousr=codesys
SET /P opwd=Enter %ousr% password (%ousr%):
IF %opwd%_ EQU _ SET opwd=%ousr%
IF %ORACLE_SID%_ EQU _ SET ORACLE_SID=GISDB
SET /P osid=Enter TNSName (%ORACLE_SID%):
IF %osid%_ EQU _ SET osid=%ORACLE_SID%

rem SET VERSION10=Y
rem SET /P VERSION10=Is this database version 10 or above (Y/N)? (%VERSION10%):
rem IF %VERSION10%_ EQU y_ ( SET VERSION10=Y )

REM ------------------------- Check Login 
:TESTPERMS
ECHO Testing connection parameters....
sqlplus -l -s "%ousr%/%opwd%@%osid%" @test_connection           > log\test_connection.log 
IF %errorlevel% EQU 0 GOTO CHECK_PERMS
ECHO Either the supplied username (%ousr%) doesn't exist, its password (%opwd%) wrong or TNSNAME (%osid%) is incorrect.
pause
GOTO EXIT
:CHECK_PERMS
REM ------------------------- Check Schema permissions
ECHO Checking schema permissions ...
sqlplus -L "%ousr%/%opwd%@%osid%" @CHECK_Permissions %ousr%     > log\CHECK_Permissions.log
IF %errorlevel% EQU 0 GOTO INSTALLSCRIPTS
ECHO ___ %ousr% has insufficient privileges for installation. Check log for details.
GOTO EXIT
:INSTALLSCRIPTS
ECHO ___ %ousr% has correct privileges for installation. 
ECHO _ Checking database version
sqlplus -L "%ousr%/%opwd%@%osid%" @CHECK_database_version       > log\CHECK_database_version.log
SET VERSION=%ERRORLEVEL%
ECHO ___ Version is %VERSION%

ECHO __ Creating tables ....
ECHO _____ Oracle error message table ...
sqlplus -L "%ousr%/%opwd%@%osid%" @CREATE_sdo_geom_error_table %ousr% > log\CREATE_sdo_geom_error_table.log
ECHO _____ Test Tables ...
sqlplus -L "%ousr%/%opwd%@%osid%" @CREATE_Test_Tables          %ousr% > log\CREATE_Test_Tables.log
ECHO _____ Oracle Documentation Test Tables ...
sqlplus -L "%ousr%/%opwd%@%osid%" @CREATE_Ora_Test_Tables      %ousr% > log\CREATE_Ora_Test_Tables.log
ECHO _____ Oracle LRS Tables ...
sqlplus -L "%ousr%/%opwd%@%osid%" @CREATE_LINEAR_Tables        %ousr% > log\CREATE_LINEAR_Tables.log

ECHO Installing All Common Objects ...
FOR %%f in (CONSTANTS_package ST_POINT_type COMMON_types_and_functions AFFINE_Package COGO_package GF_package MBR_Type DEBUG_package CENTROID_package LINEAR_package GEOM_Package TESSELATE_Package SDO_ERROR_package) do ( ECHO __ Installing %%f ...; && ( sqlplus -L "%ousr%/%opwd%@%osid%" @%%f %ousr% > log\%%f.log || ( ECHO %%f has errors: check log/%%f.log for details && GOTO EXIT ) ) )

REM If Oracle 9R2 or below skip following packages 
IF %VERSION% LSS 1000 GOTO END
ECHO __ Creating Metadata Tables for use by functions in TOOLS package ...
sqlplus -L "%ousr%/%opwd%@%osid%" @CREATE_Metadata_Tables      %ousr% > log\CREATE_Metadata_Tables.log
ECHO Installing 10g and above packages ...
FOR %%f in (KML_package TOOLS_package EMAIL_package ST_GEOM_package) do ( ECHO __ Installing %%f ...; && ( sqlplus -L "%ousr%/%opwd%@%osid%" @%%f %ousr% > log\%%f.log || ( ECHO %%f has errors: check log/%%f.log for details && GOTO EXIT ) ) )

:END

ECHO ================================================
ECHO Finished installing packages.
ECHO If you find any bugs or improve this code please 
ECHO send the changes to simon@spatialdbadvisor.com
ECHO ================================================

forfiles /m "%~nx0" /c "cmd /c echo 0x07"
timeout /t 1 /nobreak>nul
for /f %%i in ('forfiles /m "%~nx0" /c "cmd /c echo 0x07"') do set BEL=%%i
echo %BEL%
timeout /t 1 /nobreak>nul

ECHO ================================================
ECHO If you find these packages useful, please 
ECHO consider making a donation (eg USD10) on my
ECHO website via the PayPal Donate button.
ECHO http://www.spatialdbadvisor.com
ECHO ================================================

:EXIT
PAUSE
