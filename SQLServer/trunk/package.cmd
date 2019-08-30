@ECHO OFF

set path=%path%;C:\gnuwin32\bin

ECHO rename install.cmd to install_cmd ...
rename install.cmd install_cmd

ECHO Remove old deploy zip files ...
del deploy\SC4SSSBE_SQL_Server_Spatial_Base_Edition.zip
del deploy\SC4SSSCE_SQL_Server_Spatial_Complete_Edition.zip

ECHO Create SC4SSSBE_SQL_Server_Spatial_Base_Edition.zip ...
..\..\Tools\bin\zip ^
    -r deploy\SC4SSSBE_SQL_Server_Spatial_Base_Edition.zip ^
       README.txt ^
       install_cmd ^
       Function_Count.sql ^
       src\General\*.* ^
       Documentation\SQLServer.html ^
       Documentation\SQLServer.css > NUL

ECHO Create SC4SSSCE_SQL_Server_Spatial_Complete_Edition.zip ...
..\..\Tools\bin\zip ^
    -r deploy\SC4SSSCE_SQL_Server_Spatial_Complete_Edition.zip ^
       README.txt ^
       install_cmd ^
       Function_Count.sql ^
       src\General\*.* ^
       src\LRS\*.* ^
       test\LRS_End_To_End_Testing.sql ^
       Documentation\SQLServer*.* > NUL

ECHO rename install_cmd to back to install.cmd ...
rename install_cmd install.cmd

pause
