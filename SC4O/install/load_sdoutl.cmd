@ECHO OFF
SET ORACLE_DB_HOME=C:\oracle\product\10.2.0\db_1
SET CLASSPATH=%ORACLE_DB_HOME%\jdk\jre\lib
SET JAVA_HOME=%ORACLE_DB_HOME%\jdk
SET PATH=%JAVA_HOME%\bin;%ORACLE_DB_HOME%\bin;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem

IF %ORACLE_SID%_ EQU _ SET ORACLE_SID=GISDB

SET /P ousr=Enter codesys username (codesys):
IF %ousr%_ EQU _ SET ousr=CODESYS
SET /P opwd=Enter %ouser% password (codemgr):
IF %opwd%_ EQU _ SET opwd=CODEMGR

SET /P osid=Enter TNSName (%ORACLE_SID%):
IF %osid%_ EQU _ SET osid=%ORACLE_SID%

loadjava -user %ousr%/%opwd%@%osid% -r -v -grant public -f sdoutl.jar 

pause
