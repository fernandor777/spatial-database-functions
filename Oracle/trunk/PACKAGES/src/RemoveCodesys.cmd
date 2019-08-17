rmdir /S /Q temp

mkdir temp

SET PATH=%PATH%;"C:\Program Files (x86)\GnuWin32\bin"

FOR %%S IN (*_package.sql *_type.sql *_test.sql) DO sed "s/[Cc][Oo][Dd][Ee][Ss][Yy][Ss]/\&\&defaultSchema\./g" %%S | sed "s/[Cc][Oo][Dd][Ee][Tt][Ee][Ss][Tt]/\&\&defaultSchema\./g" > temp\%%S

GOTO END

mv temp\*.sql .

rmdir /S /Q temp

:END
