@ECHO OFF

IF EXIST log\NUL (
del /F /Q log\*.log
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
SET ORACLE_HOME=%ohome%
SET Path=%ohome%\bin;C:\WINDOWS\system32;C:\WINDOWS;c:\WINDOWS\system32\WBEM

SET ousr=
SET opwd=
SET /P ousr=Enter username holding existing types and packages (codesys):
IF %ousr%_ EQU _ SET ousr=codesys
SET /P opwd=Enter %ousr% password (%ousr%):
IF %opwd%_ EQU _ SET opwd=%ousr%
IF %ORACLE_SID%_ EQU _ SET ORACLE_SID=GISDB12
SET /P osid=Enter TNSName (%ORACLE_SID%):
IF %osid%_ EQU _ SET osid=%ORACLE_SID%

:TESTPERMS
ECHO Checking permissions ...
sqlplus -L "%ousr%/%opwd%@%osid%" @CHECK_Permissions %ousr% > log\CHECK_Permissions.log
IF %errorlevel% EQU 0 GOTO DROPOBJECTS
ECHO ___ %ousr% has insufficient privileges for uninstall. Check log for details.
GOTO EXIT

:DROPOBJECTS
ECHO ___ %ousr% has correct privileges for uninstall. 

:DROPQN
SET /P dropExist=Are you sure you want to drop all existing objects (Y/N)? (N):
IF %dropExist%_ EQU _  SET dropExist=N
IF %dropExist%_ EQU n_ SET dropExist=N
IF %dropExist%_ EQU y_ SET dropExist=Y
IF %dropExist%_ EQU Y_ GOTO DODROP
IF NOT %dropExist%_ EQU N_ GOTO DROPQN
:DODROP
ECHO Dropping Types, Packages, Tables etc 
ECHO __ Dropping installed Tables and any sequences...
sqlplus -L "%ousr%/%opwd%@%osid%" @DROP_Tables                %ousr% > log\DROP_Tables.log
ECHO __ Dropping Packages ...
sqlplus -L "%ousr%/%opwd%@%osid%" @DROP_Packages              %ousr% > log\DROP_Packages.log
ECHO __ Dropping Types ...
sqlplus -L "%ousr%/%opwd%@%osid%" @DROP_Types                 %ousr% > log\DROP_Types.log
IF %dropExist%_ EQU Y_ GOTO EXIT

:END

ECHO Finished Uninstalling packages and tables.
ECHO If you find any bugs please let me know at simon@spatialdbadvisor.com
ECHO ================================================

:EXIT
PAUSE
