@CHO OFF

set path=%path%;C:\gnuwin32\bin

rename install.cmd install_cmd


del deploy\SC4SSSBE_SQL_Server_Spatial_Base_Edition.zip
del deploy\SC4SSSCE_SQL_Server_Spatial_Complete_Edition.zip

..\..\Tools\bin\zip ^
    -r deploy\SC4SSSBE_SQL_Server_Spatial_Base_Edition.zip ^
       README.txt ^
       install_cmd ^
       Function_Count.sql ^
       src\General\*.* ^
       Documentation\SQLServer.html ^
       Documentation\SQLServer.css

..\..\Tools\bin\zip ^
    -r deploy\SC4SSSCE_SQL_Server_Spatial_Complete_Edition.zip ^
       README.txt ^
       install_cmd ^
       Function_Count.sql ^
       src\General\*.* ^
       src\LRS\*.* ^
       test\LRS_End_To_End_Testing.sql ^
       Documentation\SQLServer*.*

rename install_cmd install.cmd

pause
