@echo off
echo ignitionServer Release Automation Utility
echo -----------------------------------------
echo.
call compile.bat
call make-archives.bat
call make-installer.bat
echo ignitionServer binary archives and installer files have been created.
pause