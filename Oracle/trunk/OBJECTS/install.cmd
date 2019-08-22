@ECHO OFF
setlocal

IF EXIST "%CD%\log" GOTO START
mkdir "%CD%\log"

IF EXIST "%CD%\log" GOTO START
ECHO Could not delete/create log directory.
GOTO EXIT

:START 
DEL /Q "%CD%\log\*.log"
IF %ORACLE_HOME%_ EQU _ GOTO ORAHOME
SET ohome=%ORACLE_HOME%
:ORAHOME
SET ohome=NONE SET
SET /P ohome=Enter ORACLE_HOME PATH (%ohome%):
IF EXIST %ohome% GOTO USERNAME
ECHO ORACLE_HOME %ohome% does not exist.
GOTO ORAHOME

:USERNAME
SET PATH=C:\WINDOWS;C:\WINDOWS\system32;C:\WINDOWS\System32\Wbem\;C:\WINDOWS\System32\WindowsPowerShell\v1.0\;%ohome%\bin;

SET /P ousr=Enter username:
IF %ousr%_ EQU _ GOTO :username

SET /P opwd=Enter Password for %ousr% (def:%ousr%):
IF %opwd%_ EQU _ SET opwd=%ousr%

IF %ORACLE_SID%_ EQU _ GOTO ORA_SID
SET osid=%ORACLE_SID%
GOTO TEST_PERMISSIONS
:ORA_SID
SET /P osid=Enter ORACLE_SID (%osid%):
IF %osid%_ EQU _ GOTO ORA_SID

SET ohost=localhost
:GET_HOST
SET /P ohost=Enter Database Host (%ohost%):
IF %ohost%_ EQU _ GOTO GET_HOST

SET oport=1521
:GET_PORT
SET /P oport=Enter Port Number (%oport%):
IF %oport%_ EQU _ GOTO GET_PORT

:TEST_PERMISSIONS
ECHO Testing connection ...
sqlplus -s %ousr%/%opwd%@//%ohost%:%oport%/%osid% @Test_Permissions.sql > log/Test_Permissions.log
IF %errorlevel% EQU 0 GOTO WHAT_ACTION
ECHO %ousr% Cannot connect with supplied information, or has insufficient privileges for installation. Check log/test_permissions.log for details.
GOTO FINISHED

:WHAT_ACTION
SET DROP_INSTALL=B
REM SET DROP_INSTALL=B
REM SET /P DROP_INSTALL=(I)nstall, (D)rop or (B)oth (%DROP_INSTALL%):
REM IF %DROP_INSTALL%_ EQU b_ GOTO DROP
REM IF %DROP_INSTALL%_ EQU B_ GOTO DROP
REM IF %DROP_INSTALL%_ EQU d_ GOTO DROP
REM IF %DROP_INSTALL%_ EQU D_ GOTO DROP
REM IF %DROP_INSTALL%_ EQU i_ GOTO INSTALL
REM IF %DROP_INSTALL%_ EQU I_ GOTO INSTALL

:DROP
ECHO Dropping Types and Functions ...
sqlplus -s %ousr%/%opwd%@//%ohost%:%oport%/%osid% @Drop_all.sql %ousr% > log/drop_all.log
REM IF %DROP_INSTALL%_ EQU d_ GOTO FINISHED
REM IF %DROP_INSTALL%_ EQU D_ GOTO FINISHED

:INSTALL
ECHO Installing All Types and Packaged Functions...
ECHO ... Packages and Type Headers ...
FOR %%F IN (Package_TOOLS Package_COGO T_Grid T_ElemInfo T_Vector3D T_Vertex T_MBR T_Segment T_VertexList T_Bearing_Distance T_Geometry Package_PRINT) DO (
  echo Processing %%F.sql will create log/%%F.log ...
  IF EXIST %%F.sql (
    sqlplus -s %ousr%/%opwd%@//%ohost%:%oport%/%osid% @%%F.sql %ousr% > log/%%F.log
    IF %errorlevel% EQU 0 (
      ECHO Installation of %%F.sql Successful...
    ) ELSE (
      ECHO Installation of %%F.sql failed: check log/%%F.log for details...
      GOTO FINISHED
    )
  ) ELSE (
    ECHO SQL file %%F.sql does not exist, skipping ...
  )
)

ECHO ... Type Bodies and Debug/ST_LRS packages ...
FOR %%F IN (Package_TOOLS_body Package_PRINT_body Package_COGO_Body Package_ST_LRS T_Vector3D_Body T_Vertex_Body T_MBR_Body T_Segment_Body T_VertexList_Body T_Bearing_Distance_Body T_Geometry_Body) DO (
  echo Processing %%F.sql will create log/%%F.log ...
  IF EXIST %%F.sql (
    sqlplus -s %ousr%/%opwd%@//%ohost%:%oport%/%osid% @%%F.sql %ousr% > log/%%F.log
    IF %errorlevel% EQU 0 (
      ECHO Installation of %%F.sql Successful...
    ) ELSE (
      ECHO Installation of %%F.sql failed: check log/%%~F.log for details...
      GOTO FINISHED
    )
  ) ELSE (
    ECHO SQL file %%F.sql does not exist, skipping ...
  )
)

ECHO Checking status of installation...
sqlplus -s %ousr%/%opwd%@//%ohost%:%oport%/%osid% @Check_Installation.sql %ousr% > log/Check_Installation.log
rem sqlplus -s %ousr%/%opwd%@%osid% @Check_Installation.sql %ousr% > log/Check_Installation.log
IF %errorlevel% EQU 0 (
  ECHO Installation of Types And Packages Successful...
) ELSE (
  ECHO Installation Failed Check log/install_check.log for details...
)

more /S log\Check_Installation.log

GOTO FINISHED

:FINISHED
pause
