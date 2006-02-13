@echo off
cd ..
echo Making installer...
cd installer
"C:\Program Files\NSIS\makensis.exe" ignitionServer.nsi
cd ..
cd tools