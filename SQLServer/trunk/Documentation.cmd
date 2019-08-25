F:\Projects\database\code\robodoc-win32-4.99.36\robodoc ^
     --src src\general ^
     --doc documentation\SQLServer    ^
     --singledoc ^
     --index ^
     --html ^
     --toc ^
     --sections ^
     --documenttitle "SPDBA General Function Documentation"

F:\Projects\database\code\robodoc-win32-4.99.36\robodoc ^
     --src src\LRS     ^
     --doc documentation\SQLServerLrs ^
     --singledoc ^
     --index ^
     --html ^
     --toc ^
     --sections ^
     --documenttitle "SPDBA LRS Function Documentation"

ECHO Fix header icon....
cd documentation
ECHO Copy SED script ...
copy ..\head_favicon.sed .
SET PATH=%PATH%;"C:\Program Files (x86)\GnuWin32\bin"
ECHO Modify SQLServer.html
copy SQLServer.html    c_SQLServer.html 
sed -r -f head_favicon.sed c_SQLServer.html > SQLServer.html
ECHO Modify SQLServerLrs.html
copy SQLServerLrs.html c_SQLServerLrs.html
sed -r -f head_favicon.sed c_SQLServerLrs.html > SQLServerLrs.html
ECHO Clean up ...
del c_SQLServer.html 
del c_SQLServerLrs.html
del head_favicon.sed 
cd ..

pause
