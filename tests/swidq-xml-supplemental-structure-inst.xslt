<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:swidq="http://adelton.fedorapeople.org/swidq"
  exclude-result-prefixes="swidq"
>

<xsl:import href="/usr/share/swidq/stylesheets/swidq-xml.xslt"/>

<xsl:template match="swidq:*">
  <xsl:element name="{local-name()}" namespace="http://adelton.fedorapeople.org/swidq">
    <xsl:apply-templates select="@*|node()"/>
  </xsl:element>
</xsl:template>

</xsl:stylesheet>
