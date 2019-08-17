set PLDOC_HOME=.
@if "%PLDOC_HOME%" == "" ( echo ERROR: Environment variable PLDOC_HOME not set. 1>&2 && exit /b 1 )

set ANT_OPTS=-Djava.endorsed.dirs=%PLDOC_HOME%\xalan\bin 
call ant -f ant_example.xml
pause