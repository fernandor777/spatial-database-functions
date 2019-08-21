@ECHO ON
SETLOCAL ENABLEDELAYEDEXPANSION

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

Echo Remove any html directory not deleted by previous processing.
mkdir html 
REM >nul 2>&1
ECHO Copy head_favicon.sed to html directory ...
copy /S head_favicon.sed html
ECHO Change to html directory ...
cd html
ECHO Delete any files that might be in the html directory.
DEL /Q .\* 

SET PATH=%PATH%;"C:\Program Files (x86)\GnuWin32\bin"

ECHO Rename documentation files to remove _sql in name...
ECHO And modify HEAD of files.
SET fname=_
FOR %%a IN ( ..\documentation\MULTI\T_*.html ) DO CALL :BODY %%a
GOTO :EOF

:BODY
  ECHO BODY....
  SET fName=%~n1
  ECHO ... old file name is %fName% ...
  SET newFName=%fname:_sql=%
  ECHO ... new file name is %newFName% ...
  ECHO .........Copying %fName% to create %newFName%
  COPY ..\documentation\MULTI\%fName%.html c_%newFName%.html
  IF EXIST %newFName%.html (
    sed -r -f head_favicon.sed c_%newFName%.html > %fName%.html
    IF EXIST %fName%.html (
      copy %fileName%.html ..\documentation\Oracle\MULTI
      del  %fileName%.html 
    ) 
  )
GOTO :EOF

:EOF
cd ..
rmdir html 

ENDLOCAL
pause
exit

