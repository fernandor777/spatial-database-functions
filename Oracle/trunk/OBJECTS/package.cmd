REM @ECHO OFF

Echo Rename CMD files ...
copy install.sh  dist\install_sh 
copy install.cmd dist\install_cmd

echo Refresh Documentation HTML and css files ...
F:\Projects\database\code\robodoc-win32-4.99.36\robodoc ^
      --src src ^
      --doc documentation\OracleObjects ^
      --singledoc ^
      --toc ^
      --index ^
      --html ^
      --syntaxcolors ^
      --sections ^
      --no_subdirectories ^
      --documenttitle "SPDBA Object Types and Methods Documentation" 

echo Remove comments from all BODIES and write to package directory...
echo ... Package_DEBUG_Body.sql
sed -r -f comment_strip.sed src/Package_DEBUG_Body.sql > dist\Package_DEBUG_body.sql
echo ... Package_TOOLS_Body.sql
sed -r -f comment_strip.sed src/Package_TOOLS_Body.sql > dist\Package_TOOLS_body.sql
echo ... Package_COGO_Body.sql
sed -r -f comment_strip.sed src/Package_COGO_Body.sql  > dist\Package_COGO_body.sql
echo ... Package_ST_LRS_Body.sql
sed -r -f comment_strip.sed src/Package_ST_LRS_Body.sql  > dist\Package_ST_LRS_Body.sql
echo ... T_Vector3D_Body.sql
sed -r -f comment_strip.sed src/T_Vector3D_Body.sql    > dist\T_Vector3D_body.sql
echo ... T_Vertex_Body.sql
sed -r -f comment_strip.sed src/T_Vertex_Body.sql      > dist\T_Vertex_Body.sql
echo ... T_Segment_Body.sql
sed -r -f comment_strip.sed src/T_Segment_Body.sql     > dist\T_Segment_Body.sql
echo ... T_Geometry_Body.sql
sed -r -f comment_strip.sed src/T_Geometry_Body.sql    > dist\T_Geometry_Body.sql

echo Copy other files ...

copy COPYING.LESSER         dist
copy Check_Installation.sql dist
copy Create_Schema.sql      dist
copy Drop_all.sql           dist
copy Install_Check.sql      dist
copy Test_Permissions.sql   dist

echo Copy all other SQL files to package directory ...
copy src\Package_DEBUG.sql  dist
copy src\Package_TOOLS.sql  dist
copy src\Package_COGO.sql   dist
copy src\Package_ST_LRS.sql dist
copy src\Package_ST_LRS_Body.sql     dist
copy src\ST_Geometry_Type.sql        dist
copy src\T_Bearing_Distance.sql      dist
copy src\T_Bearing_Distance_Body.sql dist
copy src\T_ElemInfo.sql dist
copy src\T_MBR.sql      dist
copy src\T_MBR_Body.sql dist
copy src\T_Grid.sql     dist
copy src\T_Geometry.sql dist
copy src\T_Segment.sql  dist
copy src\T_Vector3D.sql dist
copy src\T_Vertex.sql   dist

cd dist

del /Q test\*.sql
rmdir /Q test
mkdir test
del /Q documentation\*.*
rmdir /Q documentation
mkdir documentation

copy ..\test\*.sql test
copy ..\documentation\OracleObjects.css documentation
copy ..\documentation\OracleObjects.html documentation

Echo SC4O PLSQL Object Edition ...
del /Q SC4OPOE_PLSQL_Object_Edition.zip

SET PATH=%PATH%;C:\gnuwin32\bin

zip SC4OPOE_PLSQL_Object_Edition.zip ^
       COPYING.LESSER ^
       Check_Installation.sql ^
       Create_Schema.sql ^
       Drop_all.sql ^
       install_cmd ^
       install_sh ^
       Install_Check.sql ^
       Test_Permissions.sql ^
       Package_DEBUG.sql ^
       Package_DEBUG_Body.sql ^
       Package_TOOLS.sql ^
       Package_TOOLS_Body.sql ^
       Package_COGO.sql ^
       Package_COGO_Body.sql ^
       Package_ST_LRS.sql ^
       Package_ST_LRS_Body.sql ^
       ST_Geometry_Type.sql ^
       T_Bearing_Distance.sql ^
       T_Bearing_Distance_Body.sql ^
       T_ElemInfo.sql ^
       T_MBR.sql ^
       T_MBR_Body.sql ^
       T_Grid.sql ^
       T_Geometry.sql ^
       T_Geometry_Body.sql ^
       T_Segment.sql ^
       T_Segment_Body.sql ^
       T_Vector3D.sql ^
       T_Vector3D_Body.sql ^
       T_Vertex.sql ^
       T_Vertex_Body.sql ^
       test\*.sql ^
       documentation\OracleObjects.css ^
       documentation\OracleObjects.html

del /Q COPYING.LESSER
del /Q Check_Installation.sql
del /Q Create_Schema.sql
del /Q Drop_all.sql
del /Q Test_Permissions.sql
del /Q install_cmd
del /Q install_sh 
del /Q install_check.sql
del /Q Package_DEBUG.sql 
del /Q Package_DEBUG_Body.sql 
del /Q Package_TOOLS.sql 
del /Q Package_TOOLS_Body.sql 
del /Q Package_COGO.sql 
del /Q Package_COGO_Body.sql 
del /Q Package_ST_LRS.sql 
del /Q Package_ST_LRS_Body.sql 
del /Q ST_Geometry_Type.sql 
del /Q T_Bearing_Distance.sql
del /Q T_Bearing_Distance_Body.sql 
del /Q T_ElemInfo.sql 
del /Q T_MBR.sql 
del /Q T_MBR_Body.sql 
del /Q T_Grid.sql 
del /Q T_Geometry.sql 
del /Q T_Geometry_Body.sql 
del /Q T_Segment.sql 
del /Q T_Segment_Body.sql
del /Q T_Vector3D.sql 
del /Q T_Vector3D_Body.sql
del /Q T_Vertex.sql 
del /Q T_Vertex_Body.sql

del /Q test\*.sql
rmdir /Q test
del /Q documentation\*.*
rmdir /Q documentation

cd ..

echo Packaging of Common Source Code Complete...
pause


