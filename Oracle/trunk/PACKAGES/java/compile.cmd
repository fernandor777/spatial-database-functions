SET ORACLE_DB_HOME=%1
IF %ORACLE_DB_HOME%_ EQU _ GOTO QUIT
SET CLASSPATH=%ORACLE_DB_HOME%\jdk\jre\lib
SET JAVA_HOME=%ORACLE_DB_HOME%\jdk
SET PATH=%JAVA_HOME%\bin;%ORACLE_DB_HOME%\bin

%JAVA_HOME%\bin\javac -classpath .;%ORACLE_DB_HOME%\lib\xmlparserv2.jar;%ORACLE_DB_HOME%\jdbc\lib\ojdbc14.jar;%ORACLE_DB_HOME%\md\lib\sdoutl.jar;%ORACLE_DB_HOME%\md\lib\sdoapi.jar -d %CD%\java\classes %CD%\java\src\utilities.java 
GOTO END

:QUIT
ECHO Oracle DB Home not set: terminating

:END
