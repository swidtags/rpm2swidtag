<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:swid="http://standards.iso.org/iso/19770/-2/2015/schema.xsd"
  xmlns="http://standards.iso.org/iso/19770/-2/2015/schema.xsd"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:f="http://adelton.fedorapeople.org/rpm2swidtag"
  xmlns:date="http://exslt.org/dates-and-times"
  extension-element-prefixes="f date"
  exclude-result-prefixes="swid f"
  >

<xsl:import href="swidtag.xslt"/>

<xsl:param name="name" select="f:package_tag('name')"/>
<xsl:param name="version" select="f:package_tag('version')"/>
<xsl:param name="release" select="f:package_tag('release')"/>
<xsl:param name="epoch" select="f:package_tag('epoch')"/>
<xsl:param name="arch" select="f:package_tag('arch')"/>
<xsl:param name="summary" select="f:package_tag('summary')"/>
<xsl:param name="arch" select="f:package_tag('arch')"/>

<xsl:param name="sha256header" select="f:package_tag('sha256header')"/>

<xsl:param name="authoritative" select="'false'"/>
<xsl:param name="deviceid" select="'localhost.localdomain'"/>

<xsl:template match="swid:Payload">
  <xsl:choose>
    <xsl:when test="$authoritative = 'true'">
      <xsl:copy>
        <xsl:apply-templates select="@*"/>
        <f:generate-payload />
        <xsl:apply-templates select="text()|*"/>
      </xsl:copy>
    </xsl:when>
    <xsl:otherwise>
      <Evidence>
        <xsl:attribute name="date"><xsl:value-of select="date:add('1970-01-01T00:00:00Z', date:difference('1970-01-01T00:00:00Z', date:date-time()))"/></xsl:attribute>
        <xsl:attribute name="deviceId"><xsl:value-of select="$deviceid"/></xsl:attribute>
        <xsl:apply-templates select="@*"/>
        <f:generate-payload />
        <xsl:apply-templates select="text()|*"/>
      </Evidence>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="swid:Payload/swid:Resource[@type = 'rpm']">
  <xsl:if test="$arch and not($arch = 'src.rpm')">
    <xsl:copy>
      <xsl:apply-templates select="@type"/>
      <xsl:if test="not(@rpm)">
        <xsl:attribute name="rpm"><xsl:call-template name="nevra"/></xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="@*[name(.) != 'type']"/>
    </xsl:copy>
  </xsl:if>
</xsl:template>

<xsl:template match="swid:Payload/swid:Resource[@type = 'rpm']/@rpm">
  <xsl:attribute name="rpm"><xsl:call-template name="nevra"/></xsl:attribute>
</xsl:template>

<xsl:template match="swid:Payload/swid:Resource[@type = 'rpm']/@sha256header">
  <xsl:if test="$sha256header">
    <xsl:attribute name="sha256header"><xsl:value-of select="$sha256header"/></xsl:attribute>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
