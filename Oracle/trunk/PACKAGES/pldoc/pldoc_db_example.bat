set ORACLE_HOME=c:\albie\pldoc\oracle
call pldoc.bat -url jdbc:oracle:thin:@devdb.crebit.ee:1535:alvar_1 -user CREBIT -password crebitc -sql HOIUS% -d SampleFromDB
PAUSE
