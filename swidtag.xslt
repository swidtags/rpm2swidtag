<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:swid="http://standards.iso.org/iso/19770/-2/2015/schema.xsd"
  xmlns="http://standards.iso.org/iso/19770/-2/2015/schema.xsd"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  exclude-result-prefixes="swid"
  >

<xsl:param name="name" />
<xsl:param name="version" />
<xsl:param name="release" />
<xsl:param name="arch" />

<xsl:template match="/">
  <xsl:if test="not($name)">
    <xsl:message terminate="yes">Parameter name was not provided.</xsl:message>
  </xsl:if>
  <xsl:if test="not($version)">
    <xsl:message terminate="yes">Parameter version was not provided.</xsl:message>
  </xsl:if>
  <xsl:if test="not($release)">
    <xsl:message terminate="yes">Parameter release was not provided.</xsl:message>
  </xsl:if>
  <xsl:if test="not($arch)">
    <xsl:message terminate="yes">Parameter arch was not provided.</xsl:message>
  </xsl:if>
  <xsl:apply-templates select="node()"/>
</xsl:template>

<xsl:template match="node()|@*">
  <xsl:copy>
    <xsl:apply-templates select="node()|@*"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="swid:SoftwareIdentity/@name">
  <xsl:attribute name="name">
    <xsl:value-of select="$name" />
  </xsl:attribute>
</xsl:template>

<xsl:template match="swid:SoftwareIdentity/@version">
  <xsl:attribute name="version">
    <xsl:value-of select="$version" />-<xsl:value-of select="$release" />.<xsl:value-of select="$arch" />
  </xsl:attribute>
</xsl:template>

<xsl:template match="swid:Meta/@product">
  <xsl:attribute name="product">
    <xsl:value-of select="$name" />
  </xsl:attribute>
</xsl:template>

<xsl:template match="swid:SoftwareIdentity/@versionScheme">
  <xsl:attribute name="versionScheme">rpm</xsl:attribute>
</xsl:template>

<xsl:template match="swid:Meta/@colloquialVersion">
  <xsl:attribute name="colloquialVersion">
    <xsl:value-of select="$version" />
  </xsl:attribute>
</xsl:template>

<xsl:template match="swid:Meta/@revision">
  <xsl:attribute name="revision">
    <xsl:value-of select="$release" />
  </xsl:attribute>
</xsl:template>

<xsl:template match="swid:SoftwareIdentity/@tagId">
  <xsl:attribute name="tagId">
    <xsl:value-of select="$name" />-<xsl:value-of select="$version" />
    <xsl:if test="$release">-<xsl:value-of select="$release" /></xsl:if>
    <xsl:value-of select="'.'" /><xsl:value-of select="$arch" />
  </xsl:attribute>
</xsl:template>

</xsl:stylesheet>
