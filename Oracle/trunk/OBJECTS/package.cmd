REM @ECHO OFF

Echo Rename CMD files ...
rename install.sh                   install_sh 
rename install.cmd                  install_cmd
rename install_with_st_geometry.cmd install_with_st_geometry_cmd

echo Creating Documentation HTML and css files ...
F:\Projects\database\code\robodoc-win32-4.99.36\robodoc ^
      --src src
      --doc documentation\OracleObjects ^
      --singledoc ^
      --toc ^
      --index ^
      --html ^
      --syntaxcolors ^
      --sections ^
      --no_subdirectories ^
      --documenttitle "SPDBA Object Types and Methods Documentation" 

SET PATH=%PATH%;C:\gnuwin32\bin

echo Remove comments from all BODIES and write to package directory...
echo ... Package_DEBUG_Body.sql
sed -r -f comment_strip.sed src/Package_DEBUG_Body.sql > Package_DEBUG_body.sql
echo ... Package_TOOLS_Body.sql
sed -r -f comment_strip.sed src/Package_TOOLS_Body.sql > Package_TOOLS_body.sql
echo ... Package_COGO_Body.sql
sed -r -f comment_strip.sed src/Package_COGO_Body.sql  > Package_COGO_body.sql
echo ... Package_ST_LRS_Body.sql
sed -r -f comment_strip.sed src/Package_ST_LRS_Body.sql  > Package_ST_LRS_Body.sql
echo ... T_Vector3D_Body.sql
sed -r -f comment_strip.sed src/T_Vector3D_Body.sql    > T_Vector3D_body.sql
echo ... T_Vertex_Body.sql
sed -r -f comment_strip.sed src/T_Vertex_Body.sql      > T_Vertex_Body.sql
echo ... T_Segment_Body.sql
sed -r -f comment_strip.sed src/T_Segment_Body.sql     > T_Segment_Body.sql
echo ... T_Geometry_Body.sql
sed -r -f comment_strip.sed src/T_Geometry_Body.sql    > T_Geometry_Body.sql

echo Copy all other SQL files to package directory ...
copy src\Package_DEBUG.sql .
copy src\Package_TOOLS.sql .
copy src\Package_COGO.sql .
copy src\Package_ST_LRS.sql .
copy src\Package_ST_LRS_Body.sql .
copy src\ST_Geometry_Type.sql .
copy src\T_ElemInfo.sql .
copy src\T_Bearing_Distance.sql .
copy src\T_Bearing_Distance_Body.sql .
copy src\T_MBR.sql .
copy src\T_MBR_Body.sql .
copy src\T_Grid.sql .
copy src\T_Geometry.sql .
copy src\T_Segment.sql .
copy src\T_Vertex.sql .
copy src\T_Vector3D.sql .

Echo SC4O PLSQL Object Edition ...
zip -r -D dist\SC4OPOE_PLSQL_Object_Edition.zip ^
       COPYING.LESSER ^
       Check_Installation.sql ^
       Create_Schema.sql ^
       Drop_all.sql ^
       install_cmd ^
       install_sh ^
       install_with_st_geometry_cmd ^
       Install_Check.sql ^
       Test_permissions.sql ^
       Package_COGO.sql ^
       Package_COGO_Body.sql ^
       Package_DEBUG.sql ^
       Package_DEBUG_Body.sql ^
       Package_ST_LRS.sql ^
       Package_ST_LRS_Body.sql ^
       Package_TOOLS.sql ^
       Package_TOOLS_Body.sql ^
       ST_Geometry_Type.sql ^
       T_Bearing_Distance.sql ^
       T_Bearing_Distance_Body.sql ^
       T_ElemInfo.sql ^
       T_Geometry.sql ^
       T_Geometry_Body.sql ^
       T_Grid.sql ^
       T_MBR.sql ^
       T_MBR_Body.sql ^
       T_Segment.sql ^
       T_Segment_Body.sql ^
       T_Vector3D.sql ^
       T_Vector3D_Body.sql ^
       T_Vertex.sql ^
       T_Vertex_Body.sql ^
       tests\*.sql ^
       documentation\OracleObjects.css ^
       documentation\OracleObjects.html

del Package_COGO.sql 
del Package_COGO_Body.sql 
del Package_DEBUG.sql 
del Package_DEBUG_Body.sql 
del Package_ST_LRS.sql 
del Package_ST_LRS_Body.sql 
del Package_TOOLS.sql 
del Package_TOOLS_Body.sql 
del ST_Geometry_Type.sql 
del T_Bearing_Distance.sql
del T_Bearing_Distance_Body.sql 
del T_ElemInfo.sql 
del T_Geometry.sql 
del T_Geometry_Body.sql 
del T_Grid.sql 
del T_MBR.sql 
del T_MBR_Body.sql 
del T_Segment.sql 
del T_Segment_Body.sql
del T_Vector3D.sql 
del T_Vector3D_Body.sql
del T_Vertex.sql 
del T_Vertex_Body.sql

rename install_sh                   install.sh 
rename install_cmd                  install.cmd
rename install_with_st_geometry_cmd install_with_st_geometry.cmd

echo Packaging of Common Source Code Complete...
pause


