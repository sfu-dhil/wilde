<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  exclude-result-prefixes="#all"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Mar 9, 2024</xd:p>
      <xd:p><xd:b>Author:</xd:b> takeda</xd:p>
      <xd:p>Simple-ish stylesheet for converting all of the reports into a set of very basic JSON
      for text analysis.</xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:param name="reports.dir"/>
  <xsl:param name="dist.dir"/>
  
  <xsl:variable name="allReports" select="collection($reports.dir || '?select=*.html;recurse=yes')"/>
  
  <xsl:template name="go">
    <xsl:apply-templates select="$allReports"/>
  </xsl:template>
  
  <xsl:template match="/">
    <xsl:result-document href="{$dist.dir}/data/{//html/@id}.json">
        
      
    </xsl:result-document>
  </xsl:template>
  

</xsl:stylesheet>