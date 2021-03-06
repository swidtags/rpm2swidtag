<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:swid="http://standards.iso.org/iso/19770/-2/2015/schema.xsd"
  xmlns:swidq="http://adelton.fedorapeople.org/swidq"
>

<xsl:output method="text" omit-xml-declaration="yes" indent="no" encoding="utf8"/>

<xsl:param name="file"/>

<xsl:template match="/">
  <xsl:if test="$file">File [<xsl:value-of select="$file"/>]
</xsl:if>
  <xsl:apply-templates select="/swid:*"/>
</xsl:template>

<xsl:template name="newline">
  <xsl:text>
</xsl:text>
</xsl:template>

<xsl:template name="quote-value" match="@*" mode="quote-value">
  <xsl:param name="prefix"/>
  <xsl:param name="value" select="."/>
  <xsl:value-of select="$prefix"/>
  <xsl:text>[</xsl:text>
  <xsl:value-of select="$value"/>
  <xsl:text>]</xsl:text>
</xsl:template>

<xsl:template name="indent-level">
  <xsl:param name="level"/>
  <xsl:param name="string" select="'  '"/>
  <xsl:if test="$level > 0">
    <xsl:value-of select="$string"/>
    <xsl:call-template name="indent-level">
      <xsl:with-param name="level" select="$level - 1"/>
      <xsl:with-param name="string" select="$string"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<xsl:template name="indent">
  <xsl:param name="char" select="'-'"/>
  <xsl:variable name="indent" select="count(ancestor::*)"/>
  <xsl:call-template name="indent-level">
    <xsl:with-param name="level" select="$indent"/>
  </xsl:call-template>
  <xsl:if test="$indent > 0">
    <xsl:value-of select="$char"/>
    <xsl:text> </xsl:text>
  </xsl:if>
</xsl:template>

<xsl:template name="attr-indent">
  <xsl:variable name="indent" select="count(ancestor::*)"/>
  <xsl:call-template name="indent-level">
    <xsl:with-param name="level" select="$indent"/>
  </xsl:call-template>
</xsl:template>

<xsl:template match="swid:*">
  <xsl:call-template name="indent"/>
  <xsl:value-of select="name()"/>
  <xsl:apply-templates select="./swidq:element-source" mode="supplemental-info"/>
  <xsl:call-template name="newline"/>
  <xsl:apply-templates select="@*"/>
  <xsl:apply-templates select="*"/>
</xsl:template>

<xsl:template match="swid:*/@*">
  <xsl:call-template name="attr-indent"/>
  <xsl:text>@</xsl:text>
  <xsl:value-of select="name()"/>
  <xsl:text>: </xsl:text>
  <xsl:apply-templates select="." mode="quote-value"/>
  <xsl:variable name="name" select="name()"/>
  <xsl:apply-templates select="../swidq:attr-source[@name = $name]" mode="supplemental-info"/>
  <xsl:call-template name="newline"/>
</xsl:template>

<xsl:template match="swidq:supplemental">
  <xsl:call-template name="indent">
    <xsl:with-param name="char" select="'+'"/>
  </xsl:call-template>
  <xsl:text>Supplemented by </xsl:text>
  <xsl:apply-templates select="@path" mode="quote-value"/>
  <xsl:call-template name="newline"/>
  <xsl:apply-templates select="@*[name() != 'path']"/>
  <xsl:apply-templates select="*"/>
</xsl:template>

<xsl:template match="swidq:supplemental[@break-loop]">
  <xsl:call-template name="indent">
    <xsl:with-param name="char" select="'!'"/>
  </xsl:call-template>
  <xsl:text>Supplemented by </xsl:text>
  <xsl:apply-templates select="@path" mode="quote-value"/>
  <xsl:text> ... breaking loop</xsl:text>
  <xsl:call-template name="newline"/>
</xsl:template>

<xsl:template match="swidq:attr-source | swidq:element-source" mode="supplemental-info">
  <xsl:if test="position() = 1">
    <xsl:text> &lt;&lt;</xsl:text>
  </xsl:if>
  <xsl:text> </xsl:text>
  <xsl:apply-templates select="@path" mode="quote-value"/>
</xsl:template>

</xsl:stylesheet>
