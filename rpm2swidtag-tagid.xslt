<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:swid="http://standards.iso.org/iso/19770/-2/2015/schema.xsd"
  xmlns="http://standards.iso.org/iso/19770/-2/2015/schema.xsd"
  exclude-result-prefixes="swid"
  >

<xsl:import href="rpm2swidtag.xslt"/>

<xsl:output method="text" omit-xml-declaration="yes" indent="no" encoding="utf8"/>

<xsl:template match="swid:SoftwareIdentity">
<xsl:text></xsl:text>
  <xsl:call-template name="si_tagid_value" /><xsl:text>
</xsl:text>
</xsl:template>

</xsl:stylesheet>
