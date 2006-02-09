@echo off
echo Processing XML...
C:\cygwin\bin\xsltproc.exe --nonet --stringparam chunker.output.encoding iso-8859-1 --output license.html gpl.xsl gpl.xml
pause