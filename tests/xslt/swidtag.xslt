<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:swid="http://standards.iso.org/iso/19770/-2/2015/schema.xsd"
  exclude-result-prefixes="swid"
  >

<xsl:import href="../../rpm2swidtag.xslt"/>

<xsl:template name="si_tagid_attr" match="swid:SoftwareIdentity/@tagId">
  <xsl:attribute name="tagId">
    <xsl:value-of select="$name" />
    <xsl:text>:</xsl:text>
    <xsl:value-of select="$epoch"/>
    <xsl:text>:</xsl:text>
    <xsl:value-of select="$version" />
    <xsl:text>:</xsl:text>
    <xsl:value-of select="$release" />
    <xsl:text>:</xsl:text>
    <xsl:value-of select="$arch" />
  </xsl:attribute>
</xsl:template>

</xsl:stylesheet>
