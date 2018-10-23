<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:swid="http://standards.iso.org/iso/19770/-2/2015/schema.xsd"
  xmlns="http://standards.iso.org/iso/19770/-2/2015/schema.xsd"
  exclude-result-prefixes="swid"
>

<xsl:output method="xml" omit-xml-declaration="no" indent="yes" encoding="utf-8"/>
<xsl:strip-space elements="*"/>

<xsl:template match="/swid:SoftwareIdentity">
  <SoftwareIdentity xmlns="http://standards.iso.org/iso/19770/-2/2015/schema.xsd" xmlns:sha256="http://www.w3.org/2001/04/xmlenc#sha256" xmlns:n8060="http://csrc.nist.gov/ns/swid/2015-extensions/1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://standards.iso.org/iso/19770/-2/2015/schema.xsd http://standards.iso.org/iso/19770/-2/2015-current/schema.xsd     http://csrc.nist.gov/ns/swid/2015-extensions/1.0 https://csrc.nist.gov/schema/swid/2015-extensions/swid-2015-extensions-1.0.xsd">
    <xsl:apply-templates select="@*|node()"/>
  </SoftwareIdentity>
</xsl:template>

<xsl:template match="swid:*">
  <xsl:element name="{local-name()}" namespace="http://standards.iso.org/iso/19770/-2/2015/schema.xsd">
    <xsl:apply-templates select="@*|node()"/>
  </xsl:element>
</xsl:template>

<xsl:template match="@*|node()">
  <xsl:copy-of select="."/>
</xsl:template>

</xsl:stylesheet>
