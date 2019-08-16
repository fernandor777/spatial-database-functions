set path=%path%;C:\gnuwin32\bin

rename install.cmd install_cmd

mkdir documentation
copy F:\Projects\database\code\Documentation\SQLServer\SQLServer*.html Documentation
copy F:\Projects\database\code\Documentation\SQLServer\SQLServer*.css Documentation

del SC4SSSE_SQL_Server_Spatial_Base_Edition.zip
del SC4SSSE_SQL_Server_Spatial_LRS_Edition.zip

zip -r SC4SSBE_SQL_Server_Spatial_Base_Edition.zip ^
       install_cmd ^
       Function_Count.sql ^
       src\General\*.* ^
       Documentation\SQLServer.html ^
       Documentation\SQLServer.css

zip -r SC4SSLRSE_SQL_Server_Spatial_LRS_Edition.zip ^
       install_cmd ^
       Function_Count.sql ^
       src\General\*.* ^
       src\LRS\*.* ^
       test\LRS_End_To_End_Testing.sql ^
       Documentation\SQLServer*.*

rename install_cmd install.cmd

del    Documentation\SQLServer*.html 
del    Documentation\SQLServer*.css
rmdir  Documentation
 
pause
