@ECHO OFF

SET ORACLE_DB_HOME=%1
IF %ORACLE_DB_HOME%_ EQU _    GOTO QUITDB
IF NOT EXIST %ORACLE_DB_HOME% GOTO QUITORAHOME
SET ousr=%2
IF %ousr%_ EQU _ GOTO QUITUSR
SET opwd=%3
IF %opwd%_ EQU _ GOTO QUITPWD
SET osid=%4
IF %osid%_ EQU _ GOTO QUITSID

SET CLASSPATH=%ORACLE_DB_HOME%\jdk\jre\lib
SET JAVA_HOME=%ORACLE_DB_HOME%\jdk
SET PATH=%JAVA_HOME%\bin;%ORACLE_DB_HOME%\bin

IF NOT EXIST log mkdir log

ECHO Running ncomp ....
ECHO Uncomment follow line IF you have set up the necessary compilers and environment
ECHO See http://download.oracle.com/docs/cd/B19306_01/java.102/b14187/chten.htm
ECHO ncomp -force -verbose -user %ousr%/%opwd%@%osid% SC4O.jar > log/SC4O_compile.log
GOTO SUCCESS

:QUITORAHOME
ECHO Oracle DB Home - %ORACLE_DB_HOME% - does not exist: terminating
GOTO END
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
ECHO usage: run_ncomp OracleHome username password Oracle_Sid 
:SUCCESS
pause
exit
