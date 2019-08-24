@ECHO ON
SETLOCAL ENABLEDELAYEDEXPANSION

ECHO Delete any files that might be in the documentation\MULTI directory.
DEL /Q documentation\MULTI\* 

ECHO Generate new documentation html ...
F:\Projects\database\code\robodoc-win32-4.99.36\robodoc ^
      --src src ^
      --doc documentation\MULTI ^
      --multidoc ^
      --toc ^
      --index ^
      --html ^
      --syntaxcolors ^
      --sections ^
      --no_subdirectories ^
      --documenttitle "SPDBA Object Types and Methods Documentation" 

ECHO Change to documentation\MULTI directory
cd documentation\MULTI
ECHO Copy down SED script that modifies HTML ...
COPY ..\..\head_favicon.sed .
ECHO Set Path...
SET PATH=%PATH%;"C:\Program Files (x86)\GnuWin32\bin"
ECHO Modify HEAD of files to include icon ...
sed -r -f head_favicon.sed COGO_sql.html                > COGO.html
sed -r -f head_favicon.sed Package_COGO_sql.html        > Package_COGO.html
sed -r -f head_favicon.sed Package_DEBUG_sql.html       > Package_DEBUG.html
sed -r -f head_favicon.sed Package_PRINT_sql.html       > Package_PRINT.html
sed -r -f head_favicon.sed Package_ST_LRS_sql.html      > Package_ST_LRS.html
sed -r -f head_favicon.sed Package_TOOLS_sql.html       > Package_TOOLS.html
sed -r -f head_favicon.sed T_Bearing_Distance_sql.html  > T_Bearing_Distance.html
sed -r -f head_favicon.sed T_ElemInfo_sql.html          > T_ElemInfo.html
sed -r -f head_favicon.sed T_Geometry_sql.html          > T_Geometry.html
sed -r -f head_favicon.sed T_Grid_sql.html              > T_Grid.html
sed -r -f head_favicon.sed T_MBR_sql.html               > T_MBR.html
sed -r -f head_favicon.sed T_Segment_sql.html           > T_Segment.html
sed -r -f head_favicon.sed T_Vector3D_sql.html          > T_Vector3D.html
sed -r -f head_favicon.sed T_VertexList_sql.html        > T_VertexList.html
sed -r -f head_favicon.sed T_Vertex_sql.html            > T_Vertex.html
sed -r -f head_favicon.sed t_PrecisionModel_sql.html    > T_PrecisionModel.html
sed -r -f head_favicon.sed masterindex.html             > c_masterindex.html
DEL /Q masterindex.html
RENAME c_masterindex.html masterindex.html
ECHO Delete old files ...
DEL *_sql.html
ECHO Change back to starting directory ...
cd ../..
ECHO Quitting ...
ENDLOCAL
pause

