@ECHO OFF

setlocal 

set path=%path%;C:\gnuwin32\bin

del /F /Q dist\SC4OJTSE_Java_Topology_Suite_Edition.zip
del /F /Q dist\SC4OJEE_Java_Exporter_Edition.zip 
del /F /Q dist\SC4OCJE_Java_Complete_Edition.zip 

rename install\run_ncomp.cmd run_ncomp_cmd
rename install\install.sh    install_sh
rename install\drop_jar.cmd  drop_jar_cmd
rename install\load_jar.cmd  load_jar_cmd

copy /V trunk\src\PLSQL\CHECK_Connection.sql                          install
copy /V trunk\src\PLSQL\CHECK_Database_Version.sql                    install
copy /V trunk\src\PLSQL\CHECK_Permissions.sql                         install
copy /V trunk\src\PLSQL\CLEAN_Java.sql                                install
copy /V trunk\src\PLSQL\COMPILE_Java_11g.sql                          install
copy /V trunk\src\PLSQL\CREATE_EXPORTER_Package.sql                   install
copy /V trunk\src\PLSQL\CREATE_MapInfo_MapCatalog.sql                 install
copy /V trunk\src\PLSQL\CREATE_Oracle_All_Types_Table.sql             install
copy /V trunk\src\PLSQL\CREATE_SC4O_Package.sql                       install
copy /V trunk\src\PLSQL\CREATE_SC4O_Package_With_Srid.sql             install
copy /V trunk\src\PLSQL\CREATE_Schema.sql                             install
copy /V trunk\src\PLSQL\DROP_EXPORTER_Package.sql                     install
copy /V trunk\src\PLSQL\DROP_SC4O_Package.sql                         install
copy /V trunk\src\PLSQL\GRANT_DIRECTORY_Permissions.sql               install
copy /V trunk\src\PLSQL\GRANT_EXPORTER_Permissions.sql                install
copy /V trunk\src\PLSQL\GRANT_Permissions_Sampler.sql                 install
copy /V trunk\src\PLSQL\INSERT_MapInfo_MapCatalog_Entries_Example.SQL install
copy /V trunk\src\PLSQL\TEST_EXPORTER.sql                             install
copy /V trunk\src\PLSQL\TEST_SC4O.sql                                 install

copy /V deploy\SC4OJTSE_Java_Topology_Suite_Edition.jar install
copy /V deploy\SC4OJEE_Java_Exporter_Edition.jar        install
copy /V deploy\SC4OCJE_Java_Complete_Edition.jar        install

echo Creating Documentation HTML and css files ...
F:\Projects\database\code\robodoc-win32-4.99.36\robodoc ^
      --src install/CREATE_SC4O_Package.sql ^
      --doc documentation/SC4O ^
      --singlefile ^
      --toc ^
      --index ^
      --html ^
      --syntaxcolors ^
      --sections ^
      --no_subdirectories ^
      --documenttitle "SPDBA Spatial Companion for Oracle (SC4O-JTS) Documentation" 

F:\Projects\database\code\robodoc-win32-4.99.36\robodoc ^
      --src install/CREATE_EXPORTER_Package.sql ^
      --doc documentation/EXPORTER ^
      --singlefile ^
      --toc ^
      --index ^
      --html ^
      --syntaxcolors ^
      --sections ^
      --no_subdirectories ^
      --documenttitle "SPDBA SC4O Exporter Documentation" 

copy /V documentation\SC4O.html     install
copy /V documentation\SC4O.css      install
copy /V documentation\EXPORTER.html install
copy /V documentation\EXPORTER.css  install

ECHO Creating SC4O Java Topology Suite Edition ...
sed "s/JARFILE/SC4OJTSE_Java_Topology_Suite_Edition.jar/" install/install_template.cmd | sed "s/_XXXX_/_SC4O_/" > install/install_cmd
zip -r dist/SC4OJTSE_Java_Topology_Suite_Edition.zip ^
       install/COPYING.LESSER ^
       install/README.txt ^
       install/SC4OJTSE_Java_Topology_Suite_Edition.jar ^
       install/drop_jar_cmd ^
       install/load_jar_cmd  ^
       install/install_cmd ^
       install/install_sh ^
       install/run_ncomp_cmd  ^
       install/CREATE_Schema.sql ^
       install/CHECK_Database_Version.sql ^
       install/CHECK_Permissions.sql ^
       install/CHECK_Connection.sql ^
       install/CHECK_Permissions.sql ^
       install/CLEAN_Java.sql ^
       install/COMPILE_Java_11g.sql ^
       install/GRANT_Permissions_Sampler.sql ^
       install/DROP_SC4O_Package.sql ^
       install/CREATE_SC4O_Package.sql ^
       install/CREATE_SC4O_Package_With_Srid.sql ^
       install/TEST_SC4O.sql ^
       install/SC4O.html ^
       install/SC4O.css

ECHO Creating SC4O Java Exporter Edition ...
sed "s/JARFILE/SC4OJEE_Java_Exporter_Edition.jar/" install/install_template.cmd | sed "s/_XXXXXXXX_/_EXPORTER_/" >  install/install_cmd
zip -r dist/SC4OJEE_Java_Exporter_Edition.zip ^
       install/COPYING.LESSER ^
       install/README.txt ^
       install/SC4OJEE_Java_Exporter_Edition.jar ^
       install/drop_jar_cmd ^
       install/load_jar_cmd  ^
       install/install_cmd ^
       install/install_sh ^
       install/run_ncomp_cmd  ^
       install/CREATE_Schema.sql ^
       install/CHECK_Database_Version.sql ^
       install/CHECK_Permissions.sql ^
       install/CHECK_Connection.sql ^
       install/CHECK_Permissions.sql ^
       install/CLEAN_Java.sql ^
       install/COMPILE_Java_11g.sql ^
       install/GRANT_Permissions_Sampler.sql ^
       install/CREATE_MapInfo_MapCatalog.sql ^
       install/INSERT_MapInfo_MapCatalog_Entries_Example.SQL ^
       install/CREATE_Oracle_All_Types_Table.sql ^
       install/DROP_EXPORTER_Package.sql ^
       install/CREATE_EXPORTER_Package.sql ^
       install/GRANT_EXPORTER_Permissions.sql ^
       install/TEST_EXPORTER.sql ^
       install/GRANT_DIRECTORY_Permissions.sql ^
       install/EXPORTER.html ^
       install/EXPORTER.css

ECHO Creating SC4O Complete Java Edition (12.1)...
sed "s/JARFILE/SC4OCJE_Java_Complete_Edition.jar/" install/install_template.cmd | sed "s/_XXXXXXXX_/_EXPORTER_/" | sed "s/_XXXX_/_SC4O_/" > install/install_cmd
zip -r dist/SC4OCJE_Java_Complete_Edition.zip ^
       install/COPYING.LESSER ^
       install/README.txt ^
       install/SC4OCJE_Java_Complete_Edition.jar ^
       install/load_jar_cmd  ^
       install/drop_jar_cmd ^
       install/install_cmd ^
       install/install_sh ^
       install/run_ncomp_cmd  ^
       install/CREATE_Schema.sql ^
       install/CHECK_Database_Version.sql ^
       install/CHECK_Permissions.sql ^
       install/CHECK_Connection.sql ^
       install/CHECK_Permissions.sql ^
       install/CLEAN_Java.sql ^
       install/COMPILE_Java_11g.sql ^
       install/GRANT_Permissions_Sampler.sql ^
       install/CREATE_MapInfo_MapCatalog.sql ^
       install/INSERT_MapInfo_MapCatalog_Entries_Example.SQL ^
       install/CREATE_Oracle_All_Types_Table.sql ^
       install/GRANT_DIRECTORY_Permissions.sql ^
       install/DROP_EXPORTER_Package.sql ^
       install/CREATE_EXPORTER_Package.sql ^
       install/GRANT_EXPORTER_Permissions.sql ^
       install/DROP_SC4O_Package.sql ^
       install/CREATE_SC4O_Package.sql ^
       install/CREATE_SC4O_Package_With_Srid.sql ^
       install/TEST_EXPORTER.sql ^
       install/TEST_SC4O.sql ^
       install/SC4O.html ^
       install/SC4O.css ^
       install/EXPORTER.html ^
       install/EXPORTER.css

del install\SC4OJTSE_Java_Topology_Suite_Edition.jar 
del install\SC4OJEE_Java_Exporter_Edition.jar 
del install\SC4OCJE_Java_Complete_Edition.jar
del install\install_cmd 
del install\CHECK_Connection.sql
del install\CHECK_Database_Version.sql
del install\CHECK_Permissions.sql
del install\CLEAN_Java.sql
del install\COMPILE_Java_11g.sql
del install\CREATE_EXPORTER_Package.sql
del install\CREATE_MapInfo_MapCatalog.sql
del install\CREATE_Oracle_All_Types_Table.sql
del install\CREATE_SC4O_Package.sql
del install\CREATE_SC4O_Package_With_Srid.sql
del install\CREATE_Schema.sql
del install\DROP_EXPORTER_Package.sql
del install\DROP_SC4O_Package.sql
del install\GRANT_DIRECTORY_Permissions.sql
del install\GRANT_EXPORTER_Permissions.sql
del install\GRANT_Permissions_Sampler.sql
del install\INSERT_MapInfo_MapCatalog_Entries_Example.SQL
del install\TEST_EXPORTER.sql
del install\TEST_SC4O.sql

rename install\run_ncomp_cmd run_ncomp.cmd
rename install\install_sh    install.sh
rename install\drop_jar_cmd drop_jar.cmd
rename install\load_jar_cmd load_jar.cmd

ENDLOCAL 
pause

