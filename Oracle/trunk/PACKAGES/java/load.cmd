@ECHO OFF
SET ORACLE_DB_HOME=%1
IF %ORACLE_DB_HOME%_ EQU _ GOTO QUITDB
SET osid=%2
IF %osid%_ EQU _ GOTO QUITSID
SET ousr=%3
IF %ousr%_ EQU _ GOTO QUITUSR
SET opwd=%4
IF %opwd%_ EQU _ GOTO QUITPWD

SET CLASSPATH=%ORACLE_DB_HOME%\jdk\jre\lib
SET JAVA_HOME=%ORACLE_DB_HOME%\jdk
SET PATH=%JAVA_HOME%\bin;%ORACLE_DB_HOME%\bin

loadjava -user %ousr%/%opwd%@%osid% -r -v -grant public -f %CD%\java\classes\com\spatialdbadvisor\gis\oracle\utilities.class 
GOTO SUCCESS

:QUITDB
ECHO Oracle DB Home not set: terminating
GOTO END
:QUITSID
ECHO Oracle SID not set: terminating
GOTO END
:QUITUSR
ECHO Oracle Username not provided: terminating
GOTO END
:QUITPWD
ECHO Oracle Password not provided: terminating
GOTO END
:END
ECHO usage: load OracleHome Oracle_Sid username password
:SUCCESS
