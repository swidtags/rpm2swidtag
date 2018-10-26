<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:swid="http://standards.iso.org/iso/19770/-2/2015/schema.xsd"
  xmlns:n8060="http://csrc.nist.gov/ns/swid/2015-extensions/1.0"
>

<xsl:output method="text" omit-xml-declaration="yes" indent="no" encoding="utf8"/>

<xsl:variable name="separator">
  <xsl:choose>
    <xsl:when test="/swid:SoftwareIdentity/swid:Evidence/@n8060:pathSeparator != ''">
      <xsl:value-of select="/swid:SoftwareIdentity/swid:Evidence/@n8060:pathSeparator"/>
    </xsl:when>
    <xsl:when test="/swid:SoftwareIdentity/swid:Payload/@n8060:pathSeparator != ''">
      <xsl:value-of select="/swid:SoftwareIdentity/swid:Payload/@n8060:pathSeparator"/>
    </xsl:when>
    <xsl:otherwise>/</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/swid:SoftwareIdentity">
  <xsl:apply-templates select="swid:Payload | swid:Evidence"/>
</xsl:template>

<xsl:template match="swid:Evidence | swid:Payload">
  <xsl:apply-templates select="swid:File | swid:Directory"/>
</xsl:template>

<xsl:template name="newline">
  <xsl:text>
</xsl:text>
</xsl:template>

<xsl:template match="swid:File/@location | swid:Directory/@location | swid:File/@root | swid:Directory/@root">
  <xsl:if test="normalize-space(.) != ''">
    <xsl:value-of select="."/>
    <xsl:if test=". != $separator">
      <xsl:value-of select="$separator"/>
    </xsl:if>
  </xsl:if>
</xsl:template>

<xsl:template name="display-dir-file">
  <xsl:for-each select="parent::swid:Directory">
    <xsl:call-template name="display-dir-file"/>
    <xsl:value-of select="$separator"/>
  </xsl:for-each>
  <xsl:apply-templates select="@root"/>
  <xsl:apply-templates select="@location"/>
  <xsl:apply-templates select="@name"/>
</xsl:template>

<xsl:template match="swid:File | swid:Directory">
  <xsl:if test="@name">
    <xsl:call-template name="display-dir-file"/>
    <xsl:call-template name="newline"/>
  </xsl:if>
  <xsl:if test="name() = 'Directory'">
    <xsl:apply-templates select="swid:File | swid:Directory"/>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>
