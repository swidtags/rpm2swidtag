<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:swid="http://standards.iso.org/iso/19770/-2/2015/schema.xsd"
  xmlns="http://standards.iso.org/iso/19770/-2/2015/schema.xsd"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:f="http://adelton.fedorapeople.org/rpm2swidtag"
  extension-element-prefixes="f"
  exclude-result-prefixes="swid f"
  >

<xsl:import href="swidtag.xslt"/>

<xsl:param name="name" select="f:package_tag('name')"/>
<xsl:param name="version" select="f:package_tag('version')"/>
<xsl:param name="release" select="f:package_tag('release')"/>
<xsl:param name="epoch" select="f:package_tag('epoch')"/>
<xsl:param name="arch" select="f:package_tag('arch')"/>
<xsl:param name="summary" select="f:package_tag('summary')"/>

<xsl:template match="swid:Payload">
  <xsl:copy>
    <xsl:apply-templates select="@*"/>
    <f:generate-payload />
  </xsl:copy>
</xsl:template>

</xsl:stylesheet>
