FOR %%S IN (*_package.sql *_type.sql) DO cat %%S | sed "s/\&\&//g" | grep "^[^D] " > pldoc\%%S

call E:\Oracle\pldoc-0.8.3.1exp\pldoc.bat -doctitle 'SpatialDB Advisor PL/SQL Packages' -overview e:\projects\oracle\packages\pldoc\overview.html -d e:\projects\oracle\packages\pldoc\SpatialDBAdvisor pldoc\*_package.sql pldoc\*_type.sql > pldoc\spatialdbadvisor.log

del pldoc\*.sql

pause
