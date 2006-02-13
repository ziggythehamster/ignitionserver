@echo off
echo ignitionServer Release Automation Utility
echo -----------------------------------------
echo.
cd ..
echo Removing previously generated binaries...
del ignitionServer.exe
del monitor.exe
del PassCrypt.exe
del migwiz.exe
del control.exe
echo Removing previously generated installer-related files...
del installer\ignitionServer-bin.7z
del installer\ignitionServer-bin.zip
del installer\Setup.exe
echo Making source archives...
echo Making ignitionServer-source.7z...
"C:\Program Files\7-Zip\7z" a ignitionServer-source.7z *
echo Making ignitionServer-source.zip...
"C:\Program Files\7-Zip\7z" a -tzip ignitionServer-source.zip *
echo Done.
pause