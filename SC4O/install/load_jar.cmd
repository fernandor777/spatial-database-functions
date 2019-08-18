@ECHO OFF
SETLOCAL

SET JARFILE=%1
IF %JARFILE%_ EQU _ GOTO QUITJAR
SET ORACLE_DB_HOME=%2
IF %ORACLE_DB_HOME%_ EQU _ GOTO QUITDB
SET ousr=%3
SET ousr=%ousr: =%
IF %ousr%_ EQU _ GOTO QUITUSR
SET opwd=%4
SET opwd=%opwd: =%
IF %opwd%_ EQU _ GOTO QUITPWD
SET ohost=%5 
SET ohost=%ohost: =%
IF %ohost%_ EQU _ GOTO QUITHOST
SET oport=%6
SET oport=%oport: =%
IF %oport%_ EQU _ GOTO QUITPORT
SET osid=%7
SET osid=%osid: =%
IF %osid%_ EQU _ GOTO QUITSID

SET CLASSPATH=%ORACLE_DB_HOME%\jdk\jre\lib
SET JAVA_HOME=%ORACLE_DB_HOME%\jdk
SET PATH=%JAVA_HOME%\bin;%ORACLE_DB_HOME%\bin

IF NOT EXIST log mkdir log

ECHO Loading %JARFILE% classes ...
loadjava -force -oci -stdout -verbose -user %ousr%/%opwd%@//%ohost%:%oport%/%osid% -resolve -grant PUBLIC -f %JARFILE% > log/load_%JARFILE%.log
GOTO SUCCESS

:QUITJAR
ECHO Jar file not provided: terminating
GOTO USAGE
:QUITDB
ECHO Oracle DB Home directory not set: terminating
GOTO USAGE
:QUITSID
ECHO Oracle SID not set: terminating
GOTO USAGE
:QUITUSR
ECHO Oracle Username not provided: terminating
GOTO USAGE
:QUITPWD
ECHO Oracle Password not provided: terminating
GOTO USAGE
:QUITHOST
ECHO Oracle Host, eg localhost, not provided.
GOTO USAGE
:QUITPORT
ECHO Oracle Database port number not provided.
:USAGE
ECHO usage: load_jar JARFILE ORACLE_HOME username password host port SID 

:SUCCESS
ENDLOCAL
exit
