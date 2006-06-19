@echo off
cd ..
echo Cleaning previous binary archives...
del installer\ignitionServer-bin.7z
del installer\ignitionServer-bin.zip
echo Making ignitionServer-bin.7z...
"C:\Program Files\7-Zip\7z" a installer\ignitionServer-bin.7z ignitionServer.exe changelog.txt control.exe ircx.conf ircx.motd docs\credits.txt docs\license.html docs\license.rtf docs\license.txt docs\readme.rtf docs\readme.txt docs\releasenotes.txt monitor.exe PassCrypt.exe migwiz.exe migwiz.cftpl
echo Making ignitionServer-bin.zip...
"C:\Program Files\7-Zip\7z" a -tzip installer\ignitionServer-bin.zip ignitionServer.exe changelog.txt control.exe ircx.conf ircx.motd docs\credits.txt docs\license.html docs\license.rtf docs\license.txt docs\readme.rtf docs\readme.txt docs\releasenotes.txt monitor.exe PassCrypt.exe migwiz.exe migwiz.cftpl
cd tools