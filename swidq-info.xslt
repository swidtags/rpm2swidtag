<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:swid="http://standards.iso.org/iso/19770/-2/2015/schema.xsd"
>

<xsl:import href="swidq-dump.xslt"/>

<xsl:template match="/">
  <xsl:apply-templates select="/swid:*"/>
</xsl:template>

<xsl:template match="swid:SoftwareIdentity">
  <xsl:text>Tag id			</xsl:text>
  <xsl:apply-templates select="@tagId"/>
  <xsl:if test="not(@tagId)">
    <xsl:text>not set</xsl:text>
    <xsl:call-template name="newline"/>
  </xsl:if>

  <xsl:for-each select="@tagVersion">
    <xsl:text>Tag version		</xsl:text>
    <xsl:apply-templates select="."/>
  </xsl:for-each>
  <xsl:apply-templates select="swid:Link[@rel = 'supplemental']"/>

  <xsl:if test="$file">
    <xsl:text>File			[</xsl:text>
    <xsl:value-of select="$file"/>
    <xsl:text>]</xsl:text>
    <xsl:call-template name="newline"/>
  </xsl:if>

  <xsl:text>Name			</xsl:text>
  <xsl:apply-templates select="@name"/>
  <xsl:if test="not(@name)">
    <xsl:text>not set</xsl:text>
    <xsl:call-template name="newline"/>
  </xsl:if>

  <xsl:for-each select="@version">
    <xsl:text>Version			</xsl:text>
    <xsl:apply-templates select="."/>
  </xsl:for-each>

  <xsl:for-each select="swid:Meta/@colloquialVersion">
    <xsl:text/>Colloquial version	<xsl:apply-templates select="."/>
  </xsl:for-each>

  <xsl:for-each select="swid:Meta/@revision">
    <xsl:text/>Revision		<xsl:apply-templates select="."/>
  </xsl:for-each>

  <xsl:for-each select="swid:Meta/@edition">
    <xsl:text/>Edition			<xsl:apply-templates select="."/>
  </xsl:for-each>

  <xsl:for-each select="swid:Meta/@arch">
    <xsl:text/>Architecture		<xsl:apply-templates select="."/>
  </xsl:for-each>

  <xsl:for-each select="@xml:lang">
    <xsl:text/>XML language		<xsl:apply-templates select="."/>
  </xsl:for-each>

  <xsl:for-each select="@media">
    <xsl:text/>Media			<xsl:apply-templates select="."/>
  </xsl:for-each>

  <xsl:apply-templates select="./@*[not(name() = 'tagId' or name() = 'name' or name() = 'version' or name() = 'versionScheme' or name() = 'media'
    or name() = 'xml:lang' or name() = 'xsi:schemaLocation' or name() = 'tagVersion')]"/>
  <xsl:apply-templates select="swid:Meta"/>
  <xsl:apply-templates select="swid:Entity"/>
  <xsl:apply-templates select="swid:Link[not(@rel = 'supplemental')]"/>
</xsl:template>

<xsl:template match="
  swid:SoftwareIdentity/@tagId
  | swid:SoftwareIdentity/@tagVersion
  | swid:SoftwareIdentity/@name
  | swid:SoftwareIdentity/@versionScheme
  | swid:SoftwareIdentity/swid:Meta/@colloquialVersion
  | swid:SoftwareIdentity/swid:Meta/@revision
  | swid:SoftwareIdentity/swid:Meta/@edition
  | swid:SoftwareIdentity/swid:Meta/@arch
  | swid:SoftwareIdentity/@media
  | swid:SoftwareIdentity/@xml:lang
  | swid:SoftwareIdentity/swid:Meta/@product
  | swid:SoftwareIdentity/swid:Meta/@entitlementDataRequired
  | swid:SoftwareIdentity/swid:Meta/@summary
  | swid:SoftwareIdentity/swid:Meta/@unspscVersion
  ">
  <xsl:call-template name="quoted-value"/>
  <xsl:call-template name="newline"/>
</xsl:template>

<xsl:template match="swid:SoftwareIdentity/@version">
  <xsl:call-template name="quoted-value"/>
  <xsl:for-each select="../@versionScheme">
    <xsl:text> version scheme </xsl:text>
    <xsl:apply-templates select="."/>
  </xsl:for-each>
  <xsl:if test="not(../@versionScheme)">
    <xsl:call-template name="newline"/>
  </xsl:if>
</xsl:template>

<xsl:template match="swid:SoftwareIdentity/@* | swid:Meta/@*">
  <xsl:variable name="title" select="concat('Attr ', name())"/>
  <xsl:value-of select="$title"/>
  <xsl:call-template name="indent-level">
    <xsl:with-param name="string" select="'&#x9;'"/>
    <xsl:with-param name="level" select="(24 - string-length($title)) div 8"/>
  </xsl:call-template>
  <xsl:call-template name="quoted-value"/>
  <xsl:call-template name="newline"/>
</xsl:template>

<xsl:template match="swid:Meta">
  <xsl:for-each select="@product">
    <xsl:text>Product			</xsl:text>
    <xsl:apply-templates select="."/>
  </xsl:for-each>

  <xsl:for-each select="@entitlementDataRequired">
    <xsl:text>Entitlement required	</xsl:text>
    <xsl:apply-templates select="."/>
  </xsl:for-each>

  <xsl:for-each select="@summary">
    <xsl:text>Summary			</xsl:text>
    <xsl:apply-templates select="."/>
  </xsl:for-each>

  <xsl:for-each select="@unspscCode">
    <xsl:text>United Nations Standard Products and Services Code </xsl:text>
    <xsl:apply-templates select="."/>
  </xsl:for-each>

  <xsl:apply-templates select="./@*[not(name() = 'colloquialVersion' or name() = 'revision' or name() = 'product' or name() = 'summary'
    or name() = 'edition' or name() = 'entitlementDataRequired' or name() = 'arch' or name() = 'unspscCode' or name() = 'unspscVersion')]"/>
</xsl:template>

<xsl:template match="swid:Entity">
  <xsl:if test="position() = 1">
    <xsl:call-template name="newline"/>
  </xsl:if>
  <xsl:text>Entity</xsl:text>

  <xsl:for-each select="@role">
    <xsl:text> </xsl:text>
    <xsl:call-template name="quoted-value"/>
  </xsl:for-each>

  <xsl:for-each select="@regid">
    <xsl:text> regid </xsl:text>
    <xsl:call-template name="quoted-value"/>
  </xsl:for-each>

  <xsl:for-each select="@name">
    <xsl:text> name </xsl:text>
    <xsl:call-template name="quoted-value"/>
  </xsl:for-each>
  <xsl:call-template name="newline"/>

  <xsl:apply-templates select="./@*[not(name() = 'role' or name() = 'regid' or name() = 'name')]"/>
</xsl:template>

<xsl:template match="swid:SoftwareIdentity/swid:Meta/@unspscCode">
  <xsl:call-template name="quoted-value"/>
  <xsl:for-each select="../@unspscVersion">
    <xsl:text> of version </xsl:text>
    <xsl:apply-templates select="."/>
  </xsl:for-each>
  <xsl:if test="not(../@unspscVersion)">
    <xsl:call-template name="newline"/>
  </xsl:if>
</xsl:template>

<xsl:template match="swid:Link">
  <xsl:call-template name="newline"/>
  <xsl:text>Link</xsl:text>

  <xsl:for-each select="@rel">
    <xsl:text> </xsl:text>
    <xsl:call-template name="quoted-value"/>
  </xsl:for-each>

  <xsl:for-each select="@href">
    <xsl:text> to </xsl:text>
    <xsl:call-template name="quoted-value"/>
  </xsl:for-each>
  <xsl:call-template name="newline"/>

  <xsl:apply-templates select="./@*[not(name() = 'rel' or name() = 'href')]"/>
</xsl:template>

<xsl:template match="swid:Link[@rel = 'supplemental']">
  <xsl:text>Supplemental</xsl:text>

  <xsl:for-each select="@href">
    <xsl:text> to		</xsl:text>
    <xsl:call-template name="quoted-value"/>
  </xsl:for-each>
  <xsl:if test="not(@href)">
    <xsl:text> but href not specified</xsl:text>
  </xsl:if>
  <xsl:call-template name="newline"/>

  <xsl:apply-templates select="./@*[not(name() = 'rel' or name() = 'href')]"/>
</xsl:template>

</xsl:stylesheet>
