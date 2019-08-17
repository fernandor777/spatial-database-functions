@ECHO OFF
SET ORACLE_HOME=C:\oracle\product\10.2.0\db_1
:ORAHOME
SET /P ORACLE_HOME=Enter Oracle_HOME (%ORACLE_HOME%):
IF NOT EXIST %ORACLE_HOME% GOTO ORAHOME

SET Path=%ORACLE_HOME%\bin;C:\WINDOWS\system32;C:\WINDOWS;C:\WINDOWS\system32\WBEM

SET /P ousr=Enter codesys username (codesys):
IF %ousr%_ EQU _ SET ousr=CODESYS
SET /P opwd=Enter %ouser% password (%ousr%):
IF %opwd%_ EQU _ SET opwd=%ousr%
IF %ORACLE_SID%_ EQU _ SET ORACLE_SID=GISDB
SET /P osid=Enter TNSName (%ORACLE_SID%):
IF %osid%_ EQU _ SET osid=%ORACLE_SID%

SET VERSION10=Y
SET /P VERSION10=Is database version 10 and above? (Y/N default=%VERSION10%):
IF %VERSION10%_ EQU y_ ( SET VERSION10=Y )

SET CENTROID=N
SET /P CENTROID=Install CENTROID package only ? (Y/N default=%CENTROID%):
IF %CENTROID%_ EQU y_ ( SET CENTROID=Y )
IF %CENTROID%_ EQU Y_ GOTO CREATESCHEMAQN

SET JAVAGEOM=N
IF NOT %VERSION10%_ EQU Y_  GOTO CREATESCHEMAQN
IF %ORACLE_SID%_    EQU XE_ GOTO CREATESCHEMAQN
SET /P JAVAGEOM=Install JavaGeom ? (Y/N default=%JAVAGEOM%):
IF %JAVAGEOM%_ EQU y_ ( SET JAVAGEOM=Y )

:CREATESCHEMAQN

IF EXIST log rmdir /s /q log
mkdir log

SET /P cschema=Create Schema (Y/N)? (Y):
IF %cschema%_ EQU _ SET cschema=Y
IF     %cschema%_ EQU y_ ( SET cschema=Y )
IF NOT %cschema%_ EQU Y_ GOTO INSTALLSCRIPTS
SET /P spwd=Enter SYS password:
sqlplus -s "sys/%spwd%@%osid% AS SYSDBA" @create_schema   %ousr% %opwd% > log\create_schema.log

:INSTALLSCRIPTS
REM Install Common Scripts (Order is important)...
ECHO Creating Oracle Test Data ...
ECHO __ Creating Oracle Test Geometries ...
sqlplus %ousr%/%opwd%@%osid% @Oracle_Test_Geometry_Tables       > log\Oracle_Test_Geometry_Tables.log
ECHO __ Creating Various Test Data ...
sqlplus %ousr%/%opwd%@%osid% @create_test_data     %CD%         > log\create_test_data.log
ECHO __ Creating Metadata Tables for use by functions in TOOLS package ...
sqlplus %ousr%/%opwd%@%osid% @create_metadata_tables     %ousr% > log\create_metadata_tables.log
ECHO __ Creating tables that hold Oracle error messages ...
sqlplus %ousr%/%opwd%@%osid% @sdo_geom_error             %ousr% > log\sdo_geom_error.log
ECHO __ Creating standalone debug package ...
sqlplus %ousr%/%opwd%@%osid% @DEBUG_package              %ousr% > log\DEBUG_package.log

ECHO Installing standalone CENTROID package ...
sqlplus %ousr%/%opwd%@%osid% @CENTROID_package           %ousr% > log\CENTROID_package.log
ECHO __ Test CENTROID package ...
sqlplus %ousr%/%opwd%@%osid% @CENTROID_package_test      %ousr% > log\CENTROID_package_test.log
REM Now we jump to end if we only to install the CENTROID package.
IF %CENTROID%_ EQU Y_ GOTO END

ECHO Creating Types used by all packages
sqlplus %ousr%/%opwd%@%osid% @DROP_required_types        %ousr% > log\drop_required_types.log
sqlplus %ousr%/%opwd%@%osid% @DROP_packages              %ousr% > log\drop_packages.log
ECHO __ Installing CONSTANTS Package ...
sqlplus %ousr%/%opwd%@%osid% @CONSTANTS_package          %ousr% > log\CONSTANTS_package.log
ECHO __ Installing ST_Point object ...
sqlplus %ousr%/%opwd%@%osid% @ST_POINT_type              %ousr% > log\ST_POINT_type.log
ECHO ____ Test ST_Point Type ...
sqlplus %ousr%/%opwd%@%osid% @ST_POINT_type_test         %ousr% > log\ST_POINT_package_test.log
ECHO __ Create required types ...
sqlplus %ousr%/%opwd%@%osid% @create_required_types      %ousr% > log\create_required_types.log

ECHO Installing packages for all versions ...
ECHO __ Installing Tokenizer Function ..
sqlplus %ousr%/%opwd%@%osid% @tokenizer                  %ousr% > log\Tokenizer.log
ECHO __ Installing COGO package ...
sqlplus %ousr%/%opwd%@%osid% @COGO_package               %ousr% > log\COGO_package.log
ECHO ____ Test COGO Package ...
sqlplus %ousr%/%opwd%@%osid% @COGO_package_test          %ousr% > log\COGO_package_test.log
ECHO __ Installing GF package ...
sqlplus %ousr%/%opwd%@%osid% @GF_package                 %ousr% > log\GF_package.log
ECHO __ Installing MBR object ...
sqlplus %ousr%/%opwd%@%osid% @MBR_type                   %ousr% > log\MBR_type.log
ECHO ____ Test MBR Object ...
sqlplus %ousr%/%opwd%@%osid% @MBR_type_test              %ousr% > log\MBR_package_test.log
ECHO __ Installing NETWORK package ...
sqlplus %ousr%/%opwd%@%osid% @NETWORK_package            %ousr% > log\NETWORK_package.log
ECHO __ Installing GEOM package ...
IF %VERSION10%_ EQU Y_ (
  REM Strip out 9i comments before compiling
  REM /B Matches pattern if at the beginning of a line.
  REM /X Prints lines that match exactly.
  REM /V Prints only lines that do not contain a match.
  findstr /b /v "\/\*\*9i" GEOM_package.sql | findstr /b /v "9i\*\*\/" > GEOM_package_10g.sql
  sqlplus %ousr%/%opwd%@%osid% @GEOM_package_10g           %ousr% > log\GEOM_package_10g.log
  del GEOM_package_10g.sql
) ELSE (
  sqlplus %ousr%/%opwd%@%osid% @GEOM_package               %ousr% > log\GEOM_package.log
)
ECHO ____ Testing GEOM Package ...
sqlplus %ousr%/%opwd%@%osid% @GEOM_package_test          %ousr% > log\GEOM_package_test.log
ECHO ____ Testing NETWORK package ...
sqlplus %ousr%/%opwd%@%osid% @NETWORK_package_test       %ousr% > log\NETWORK_package_test.log
ECHO __ Installing TESSELATE package ...
sqlplus %ousr%/%opwd%@%osid% @TESSELATE_package          %ousr% > log\TESSELATE_package.log
ECHO ____ Test TESSELATE Package ...
sqlplus %ousr%/%opwd%@%osid% @TESSELATE_package_test     %ousr% > log\TESSELATE_package_test.log

REM If 9iR2 and below skip following packages 
IF NOT %VERSION10%_ EQU Y_ GOTO INSTALLJAVA

ECHO Installing 10g and above packages ...
ECHO __ Installing KML package ...
sqlplus %ousr%/%opwd%@%osid% @KML_package                %ousr% > log\KML_package.log
ECHO ____ Test KML Object ...
sqlplus %ousr%/%opwd%@%osid% @KML_package_test           %ousr% > log\KML_package_test.log
ECHO __ Installing TOOLS package ...
sqlplus %ousr%/%opwd%@%osid% @TOOLS_package              %ousr% > log\TOOLS_package.log
ECHO ____ Test TOOLS package ...
sqlplus %ousr%/%opwd%@%osid% @TOOLS_package_test         %ousr% > log\TOOLS_package_test.log
ECHO __ Installing EMAIL package ...
sqlplus %ousr%/%opwd%@%osid% @EMAIL_package              %ousr% > log\EMAIL_package.log
ECHO __ Installing SQLMM type functions package ...
sqlplus %ousr%/%opwd%@%osid% @ST_GEOM_package            %ousr% > log\ST_GEOM_package.log
ECHO ____ Testing SQLMM type functions ...
sqlplus %ousr%/%opwd%@%osid% @ST_GEOM_package_test       %ousr% > log\ST_GEOM_package_test.log


:INSTALLJAVA
IF NOT %JAVAGEOM%_ EQU Y_ GOTO END
sqlplus.exe -s %ousr%/%opwd%@%osid% @JAVAGEOM_install %CD% %ousr% > log\JAVAGEOM_install.log
call java\compile.cmd %ORACLE_HOME% > log\javacompile.log
call java\load.cmd    %ORACLE_HOME% %osid% %ousr% %opwd% > log\javaload.log
sqlplus.exe -s %ousr%/%opwd%@%osid% @JAVAGEOM_package_test %CD% %ousr% > log\JAVAGEOM_test.log

:END

ECHO Finished installing tables and packages.
ECHO If you find any bugs or improve this code please send the changes to simon@spatialdbadvisor.com
ECHO ================================================

pause
