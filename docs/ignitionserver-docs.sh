#!/bin/sh
echo "Copying temporary files"
cp -f ignitionserver-docs.dsl /tmp/ignitionserver-docs.dsl

#do our HTML processing here
xsltproc --nonet --stringparam chunker.output.encoding iso-8859-1 ignitionserver-docs.xsl ignitionserver-docs.xml
echo "Writing license.html for book"
xsltproc -o license.html --nonet --stringparam chunker.output.encoding iso-8859-1 gpl-docbook/gpl.xsl gpl-docbook/gpl.xml

#and now our RTF processing (and, God knows, TXT too?)
echo "Writing license.rtf for book (ignore errors)"
# for some reason, docbook2rtf won't handle paths with spaces...
cp -f gpl-docbook/gpl.xml /tmp/gpl.xml
docbook2rtf -d /tmp/ignitionserver-docs.dsl /tmp/gpl.xml
mv -f gpl.rtf license.rtf
