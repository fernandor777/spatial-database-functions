REM $Id: pldoc_test.bat,v 1.3 2003/10/20 19:37:46 altumano Exp $

call pldoc.bat -doctitle \"TEST\" -overview testinput/overview1.html -d TestDoc1 testinput/*.sql
call pldoc.bat -doctitle \"TEST\" -overview testinput/overview1.html -d TestDoc2 -inputencoding utf-8 testinput/chinese.pks

PAUSE

