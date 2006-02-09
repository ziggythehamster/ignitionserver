<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0">
  <xsl:import href="/usr/share/docbook-xsl/xhtml/chunk.xsl"/>
  <xsl:param name="generate.legalnotice.link" select="0"/>
  <xsl:param name="suppress.navigation" select="0"/>
  <xsl:param name="admon.graphics" select="1"/>
  <xsl:param name="admon.graphics.path">images/</xsl:param>
  <xsl:param name="html.stylesheet" select="'ircx-draft.css'" />
  <xsl:param name="toc.section.depth" select="4"/>
</xsl:stylesheet>