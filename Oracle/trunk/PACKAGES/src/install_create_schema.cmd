@ECHO OFF

ECHO =================================
ECHO Schema Creation Script
ECHO =================================

IF EXIST "%CD%\log" GOTO START
mkdir "%CD%\log"
IF %errorlevel% EQU 0 GOTO START
ECHO Could not delete/create log directory.
GOTO EXIT

:START
IF %ORACLE_HOME%_ EQU _ GOTO ORAHOMESET
SET ohome=%ORACLE_HOME%
GOTO ORAHOME
:ORAHOMESET
IF %ohome%_ EQU _ SET ohome=G:\oracle\product\11.2.0.3\dbhome_1

:ORAHOME
SET /P ohome=Enter ORACLE_HOME path (%ohome%):
IF EXIST %ohome% GOTO SETPATH
ECHO ORACLE_HOME does not exist.
GOTO ORAHOME

:SETPATH 
SET Path=%ORACLE_HOME%\bin;C:\WINDOWS\system32;C:\WINDOWS;c:\WINDOWS\system32\WBEM

SET ousr=
SET opwd=
SET /P ousr=Enter username for types and packages (codesys):
IF %ousr%_ EQU _ SET ousr=codesys
SET /P opwd=Enter %ousr% password (%ousr%):
IF %opwd%_ EQU _ SET opwd=%ousr%
IF %ORACLE_SID%_ EQU _ SET ORACLE_SID=GISDB
SET /P osid=Enter TNSName (%ORACLE_SID%):
IF %osid%_ EQU _ SET osid=%ORACLE_SID%

SET /P cschema=Create Schema (Y/N)? (N):
IF     %cschema%_ EQU _  SET cschema=N
IF     %cschema%_ EQU y_ SET cschema=Y
IF NOT %cschema%_ EQU Y_ GOTO TESTPERMS
SET /P spwd=Enter SYS password:
REM Testing sys connection ....
sqlplus -l -s "sys/%spwd%@%osid% AS SYSDBA" @TEST_connection           > log\TEST_connection.log
IF %errorlevel% EQU 0 GOTO DO_CHOICE
ECHO The supplied SYS password (%opwd%) or TNSNAME (%osid%) is incorrect.
pause
GOTO EXIT

sqlplus -L "sys/%spwd%@%osid% AS SYSDBA" @CREATE_schema  %ousr% %opwd% > log\CREATE_schema.log

ECHO Finished creating schema 
ECHO =================================

:EXIT
PAUSE
