@ECHO OFF
SETLOCAL 
F:\Projects\database\code\robodoc-win32-4.99.36\robodoc ^
      --src export ^
      --doc documentation\MULTI ^
      --multidoc ^
      --toc ^
      --index ^
      --html ^
      --syntaxcolors ^
      --sections ^
      --no_subdirectories ^
      --documenttitle "SPDBA Object Types and Methods Documentation" 

Echo Now modifying HEAD part of html
del html
rmdir /S /Q html
mkdir html
copy head_favicon.sed html
cd html

SET PATH=%PATH%;"C:\Program Files (x86)\GnuWin32\bin"

SET fname=_
FOR %%a IN ( ..\documentation\MULTI\*.html ) DO (
  ECHO Copying %%a to create c_%%~nxa ...
  copy %%a c_%%~nxa
  IF EXIST c_%%~nxa (
    sed -r -f head_favicon.sed c_%%~nxa > %%~nxa
    IF EXIST %%~nxa (
      copy %%~nxa ..\documentation\Oracle\MULTI
    ) 
  )
)
cd ..
rmdir /S /Q html
ENDLOCAL
