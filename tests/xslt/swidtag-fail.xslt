<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:f="http://adelton.fedorapeople.org/rpm2swidtag"
  exclude-result-prefixes="f"
  >

<xsl:import href="../../rpm2swidtag.xslt"/>

<xsl:param name="broken" select="f:package_tag('broken')"/>

</xsl:stylesheet>
