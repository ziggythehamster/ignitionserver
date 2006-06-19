@echo off
cd ..
echo Removing previously generated binaries...
del ignitionServer.exe
del monitor.exe
del PassCrypt.exe
del migwiz.exe
del control.exe
echo Compiling ignitionServer.exe...
"C:\Program Files\Microsoft Visual Studio\VB98\VB6" /make ignitionServer.vbp
echo Compiling monitor.exe...
"C:\Program Files\Microsoft Visual Studio\VB98\VB6" /make prjMonitor.vbp
echo Compiling PassCrypt.exe...
"C:\Program Files\Microsoft Visual Studio\VB98\VB6" /make prjPassCrypt.vbp
echo Compiling migwiz.exe...
"C:\Program Files\Microsoft Visual Studio\VB98\VB6" /make prjMigWiz.vbp
echo Compiling control.exe...
"C:\Program Files\Microsoft Visual Studio\VB98\VB6" /make prjControl.vbp
echo Compilation complete.
cd tools