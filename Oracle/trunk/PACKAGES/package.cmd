set path=%path%;C:\gnuwin32\bin

cd src

rename install.sh          install_sh
rename uninstall.cmd       uninstall_cmd
rename install.cmd         install_cmd
rename installCentroid.cmd installCentroid_cmd
rename installLinear.cmd   installLinear_cmd

Echo SC4O Affine Edition
del    ..\SC4OA_Affine_Edition.zip
zip -r ..\SC4OAE_Affine_Edition.zip ^
    AFFINE_Package.sql ^
    AFFINE_Package_tests.sql ^
    AFFINE_Package_Install_Notes.txt ^
    COPYING.LESSER

Echo SC4O LRS Legacy Edition
del    ..\SC4OLRSLE_LRS_Legacy_Edition.zip
zip -r ..\SC4OLRSLE_LRS_Legacy_Edition.zip ^
    DROP_LINEAR_package.sql ^
    DROP_Types.sql ^
    COMMON_types_and_functions.sql ^
    LINEAR_Package.sql ^
    LINEAR_Package_Test.sql ^
    installLinear_cmd ^
    CREATE_schema.sql ^
    CHECK_Permissions.sql ^
    CREATE_LINEAR_Tables.sql  ^
    COPYING.LESSER

Echo SC4O Centroid Legacy Edition
del    ..\SC4OCLE_Centroid_Legacy_Edition.zip
zip -r ..\SC4OCLE_Centroid_Legacy_Edition.zip ^
    DROP_CENTROID_package.sql ^
    DROP_Types.sql ^
    COMMON_types_and_functions.sql ^
    CENTROID_Package.sql ^
    CENTROID_Package_Test.sql ^
    ReadMeCentroid.txt ^
    installCentroid_cmd ^
    CREATE_schema.sql ^
    CHECK_Permissions.sql  ^
    COPYING.LESSER

Echo SC4O PLSQL Package Legacy Edition
del    ..\SC4OPPLE_PLSQL_Package_Legacy_Edition.zip
zip -r ..\SC4OPPLE_PLSQL_Package_Legacy_Edition.zip ^
    AFFINE_package.sql ^
    AFFINE_package_tests.sql ^
    CENTROID_Package.sql ^
    CENTROID_package_test.sql ^
    CHECK_database_version.sql ^
    CHECK_Dependencies.sql ^
    CHECK_Package_Dates.sql ^
    CHECK_Permissions.sql ^
    COGO_PACKAGE.sql ^
    COGO_package_test.sql ^
    COMMON_types_and_functions.sql ^
    CONSTANTS_Package.sql ^
    CREATE_LINEAR_Tables.sql ^
    CREATE_Managed_Columns_Database.sql ^
    CREATE_Metadata_Tables.sql ^
    CREATE_Ora_Test_Tables.sql ^
    CREATE_Test_Tables.sql ^
    CREATE_schema.sql ^
    CREATE_sdo_geom_error_table.sql ^
    DEBUG_Package.sql ^
    DROP_Packages.sql ^
    DROP_Tables.sql ^
    DROP_Types.sql ^
    EMAIL_package.sql ^
    GEOM_Package.sql ^
    GEOM_package_test.sql ^
    GF_Package.sql ^
    GML_Package.sql ^
    KML_Package.sql ^
    KML_package_test.sql ^
    LINEAR_package.sql ^
    LINEAR_package_test.sql ^
    MBR_type.sql ^
    MBR_type_test.sql ^
    ReadMe.txt ^
    SDO_ERROR_package.sql ^
    SDO_ERROR_package_test.sql ^
    ST_GEOM_package.sql ^
    ST_GEOM_package_test.sql ^
    ST_POINT_type_test.sql ^
    ST_POINT_type.sql ^
    ST_POINT_test.sql ^
    TESSELATE_Package.sql ^
    TESSELATE_package_test.sql ^
    TEST_Connection.sql ^
    TIN_package.sql ^
    TIN_package_test.sql ^
    TOOLS_package.sql ^
    TOOLS_package_test.sql ^
    install_cmd ^
    install_sh ^
    uninstall_cmd ^
    TomKyte\* ^
    datamodel\* ^
    Managed_Columns.png ^
    COPYING.LESSER

rename install_sh          install.sh
rename install_cmd         install.cmd
rename uninstall_cmd       uninstall.cmd
rename installCentroid_cmd installCentroid.cmd
rename installLinear_cmd   installLinear.cmd

cd ..

pause
