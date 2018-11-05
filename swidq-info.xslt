<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:swid="http://standards.iso.org/iso/19770/-2/2015/schema.xsd"
  xmlns:t="display-template"
>

<xsl:import href="swidq-dump.xslt"/>

<xsl:param name="label-width" select="'24'"/>

<xsl:template match="/">
  <xsl:apply-templates select="/swid:*"/>
</xsl:template>

<t:SoftwareIdentity>
  <line attr="tagId" required="true">Tag id</line>
  <line attr="tagVersion">Tag version</line>
  <line attr="supplemental">Tag is supplemental</line>
  <display-supplemental>Supplemental to</display-supplemental>
  <display-file>File</display-file>
  <line attr="name" required="true">Name</line>
  <line attr="version">Version</line>
  <line attr="versionScheme"/>
  <line meta_attr="colloquialVersion">Colloquial version</line>
  <line meta_attr="revision">Revision</line>
  <line meta_attr="arch">Architecture</line>
  <line attr="xml:lang">XML language</line>
  <line meta_attr="edition">Edition</line>
  <line meta_attr="product">Product</line>
  <line meta_attr="entitlementDataRequired">Entitlement required</line>
  <line meta_attr="summary">Summary</line>
  <line meta_attr="unspscCode">United Nations Standard Products and Services Code</line>
  <line meta_attr="unspscVersion"/>
  <line attr="media">Media</line>
  <line attr="xsi:schemaLocation"/>
  <display-rpm>RPM resource</display-rpm>
</t:SoftwareIdentity>

<xsl:variable name="display" select="document('')/xsl:stylesheet/t:SoftwareIdentity"/>

<xsl:template name="display-label" match="t:SoftwareIdentity/*" mode="display-label">
  <xsl:param name="label" select="text()"/>
  <xsl:value-of select="$label"/>
  <xsl:call-template name="indent-level">
    <xsl:with-param name="string" select="'&#x9;'"/>
    <xsl:with-param name="level" select="($label-width - string-length($label)) div 8"/>
  </xsl:call-template>
</xsl:template>


<xsl:template match="t:SoftwareIdentity/line[@attr]">
  <xsl:param name="source"/>
  <xsl:variable name="attr" select="@attr"/>
  <xsl:apply-templates select="$source/@*[name() = $attr]" mode="label-and-quote">
    <xsl:with-param name="label" select="."/>
  </xsl:apply-templates>
  <xsl:if test="@required = 'true' and not($source/@*[name() = $attr])">
    <xsl:apply-templates select="." mode="display-label"/>
    <xsl:text>not set</xsl:text>
    <xsl:call-template name="newline"/>
  </xsl:if>
</xsl:template>

<xsl:template match="t:SoftwareIdentity/line[@meta_attr]">
  <xsl:param name="source"/>
  <xsl:variable name="attr" select="@meta_attr"/>
  <xsl:apply-templates select="$source/swid:Meta/@*[name() = $attr]" mode="label-and-quote">
    <xsl:with-param name="label" select="."/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="t:SoftwareIdentity/line[@attr = 'supplemental']">
  <xsl:param name="source"/>
  <xsl:if test="$source[@supplemental = 'true']">
    <xsl:value-of select="text()"/>
    <xsl:call-template name="newline"/>
  </xsl:if>
</xsl:template>

<xsl:template match="t:SoftwareIdentity/display-supplemental">
  <xsl:param name="source"/>
  <xsl:apply-templates select="$source/swid:Link[@rel = 'supplemental']">
    <xsl:with-param name="label" select="."/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="t:SoftwareIdentity/display-file">
  <xsl:if test="$file">
    <xsl:apply-templates select="." mode="display-label"/>
    <xsl:call-template name="quote-value">
      <xsl:with-param name="value" select="$file"/>
    </xsl:call-template>
    <xsl:call-template name="newline"/>
  </xsl:if>
</xsl:template>

<xsl:template match="t:SoftwareIdentity/display-rpm">
  <xsl:param name="source"/>
  <xsl:apply-templates select="$source/swid:Evidence/swid:Resource[@type = 'rpm']">
    <xsl:with-param name="label" select="."/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="t:SoftwareIdentity/*">
  <xsl:message terminate="no">Unknown entry in display template.</xsl:message>
  <xsl:value-of select="text()"/>
  <xsl:text>: ERROR: info stylesheet broken</xsl:text>
  <xsl:call-template name="newline"/>
</xsl:template>

<xsl:template match="t:SoftwareIdentity/line[not(text())]"/>


<xsl:template match="swid:SoftwareIdentity">
  <xsl:apply-templates select="$display/*">
    <xsl:with-param name="source" select="."/>
  </xsl:apply-templates>

  <xsl:apply-templates select="@*[not(name() = $display/line/@attr)]"/>
  <xsl:apply-templates select="swid:Meta/@*[not(name() = $display/line/@meta_attr)]"/>
  <xsl:apply-templates select="swid:Entity"/>
  <xsl:apply-templates select="swid:Link[not(@rel = 'supplemental')]"/>
  <xsl:apply-templates select="swid:Evidence"/>
</xsl:template>

<xsl:template match="swid:*/@*" mode="label-and-quote">
  <xsl:param name="label"/>
  <xsl:call-template name="display-label">
    <xsl:with-param name="label" select="$label"/>
  </xsl:call-template>
  <xsl:apply-templates select="." mode="quote-value"/>
  <xsl:call-template name="newline"/>
</xsl:template>

<xsl:template match="swid:SoftwareIdentity/@version" mode="quote-value">
  <xsl:apply-imports select="." mode="quote-value"/>
  <xsl:apply-templates select="../@versionScheme" mode="quote-value">
  </xsl:apply-templates>
</xsl:template>

<xsl:template match="swid:SoftwareIdentity/@versionScheme" mode="quote-value">
  <xsl:text> version scheme </xsl:text>
  <xsl:apply-imports select="." mode="quote-value"/>
</xsl:template>

<xsl:template match="swid:Entity">
  <xsl:if test="position() = 1">
    <xsl:call-template name="newline"/>
  </xsl:if>
  <xsl:text>Entity</xsl:text>
  <xsl:apply-templates select="@role" mode="quote-value">
    <xsl:with-param name="prefix" select="' '"/>
  </xsl:apply-templates>
  <xsl:apply-templates select="@regid" mode="quote-value">
    <xsl:with-param name="prefix" select="' regid '"/>
  </xsl:apply-templates>
  <xsl:apply-templates select="@name" mode="quote-value">
    <xsl:with-param name="prefix" select="' name '"/>
  </xsl:apply-templates>
  <xsl:call-template name="newline"/>
  <xsl:apply-templates select="./@*[not(name() = 'role' or name() = 'regid' or name() = 'name')]"/>
</xsl:template>

<xsl:template match="swid:Link">
  <xsl:if test="position() = 1">
    <xsl:call-template name="newline"/>
  </xsl:if>
  <xsl:text>Link </xsl:text>
  <xsl:apply-templates select="@rel" mode="quote-value"/>
  <xsl:if test="not(@rel)">
    <xsl:text>with unspecified @rel</xsl:text>
  </xsl:if>
  <xsl:apply-templates select="@href" mode="quote-value">
    <xsl:with-param name="prefix" select="' to '"/>
  </xsl:apply-templates>
  <xsl:if test="not(@href)">
    <xsl:text>with unspecified @href</xsl:text>
  </xsl:if>
  <xsl:call-template name="newline"/>
  <xsl:apply-templates select="./@*[not(name() = 'rel' or name() = 'href')]"/>
</xsl:template>

<xsl:template match="swid:Link[@rel = 'supplemental']">
  <xsl:param name="label"/>
  <xsl:apply-templates select="@href" mode="label-and-quote">
    <xsl:with-param name="label" select="$label"/>
  </xsl:apply-templates>
  <xsl:if test="not(@href)">
    <xsl:text>Supplemental but href not specified</xsl:text>
    <xsl:call-template name="newline"/>
  </xsl:if>
  <xsl:apply-templates select="./@*[not(name() = 'rel' or name() = 'href')]"/>
</xsl:template>

<xsl:template match="swid:Resource[@type = 'rpm']">
  <xsl:param name="label"/>
  <xsl:apply-templates select="@rpm" mode="label-and-quote">
    <xsl:with-param name="label" select="$label"/>
  </xsl:apply-templates>
  <xsl:if test="not(@rpm)">
    <xsl:text>Supplemental but href not specified</xsl:text>
    <xsl:call-template name="newline"/>
  </xsl:if>
  <xsl:apply-templates select="./@*[not(name() = 'type' or name() = 'rpm')]"/>
</xsl:template>

<xsl:template match="swid:Evidence">
  <xsl:call-template name="newline"/>

  <xsl:text>Evidence gathered at </xsl:text>
  <xsl:apply-templates select="@date" mode="quote-value"/>
  <xsl:if test="not(@date)">
    <xsl:text>unknown time</xsl:text>
  </xsl:if>
  <xsl:text> from </xsl:text>
  <xsl:apply-templates select="@deviceId" mode="quote-value"/>
  <xsl:if test="not(@deviceId)">
    <xsl:text>unknown device</xsl:text>
  </xsl:if>
  <xsl:call-template name="newline"/>
  <xsl:apply-templates select="./@swid:*[not(name() = 'date' or name() = 'deviceId')]"/>
</xsl:template>

</xsl:stylesheet>
