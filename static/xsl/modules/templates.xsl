<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:xh="http://www.w3.org/1999/xhtml"
  xmlns:dhil="https://dhil.lib.sfu.ca"
  xmlns:app="http://dhil.lib.sfu.ca/exist/wilde/templates"
  xmlns:collection="http://dhil.lib.sfu.ca/exist/wilde/collection"
  xmlns:config="http://dhil.lib.sfu.ca/exist/wilde/config"
  xmlns:document="http://dhil.lib.sfu.ca/exist/wilde/document"
  xmlns:graph="http://dhil.lib.sfu.ca/exist/wilde/graph"
  xmlns:lang="http://dhil.lib.sfu.ca/exist/wilde/lang"
  xmlns:publisher="http://dhil.lib.sfu.ca/exist/wilde/publisher"
  xmlns:similarity="http://dhil.lib.sfu.ca/exist/wilde/similarity"
  xmlns:stats="http://dhil.lib.sfu.ca/exist/wilde/stats"
  xmlns:tx="http://dhil.lib.sfu.ca/exist/wilde/transform"
  xmlns:wilde="http://dhil.lib.sfu.ca/wilde"
  xmlns:templates="http://dhil.lib.sfu.ca/templates"
  exclude-result-prefixes="#all"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="3.0">
  
  
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Jun 8, 2023</xd:p>
      <xd:p><xd:b>Author:</xd:b> takeda</xd:p>
      <xd:p>Module for taking the eXist templating system and resolving into a set of XSLT transformations; note that this only handles the simplest of templates (i.e. data-template</xd:p>
    </xd:desc>
  </xd:doc>
  
  
  <xsl:mode name="templates" on-no-match="shallow-copy"/>
  <xsl:mode name="surround" on-no-match="shallow-copy"/>
  
  <xsl:template name="templates:surround">
    <xsl:param name="doc" select="." as="document-node()"/>
    <xsl:choose>
      <xsl:when test="$doc//*[@data-template = 'templates:surround']">
        <xsl:call-template name="templates:surround">
          <xsl:with-param name="doc" as="document-node()">
            <xsl:apply-templates select="$doc" mode="templates"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="$doc" mode="templates"/>
      </xsl:otherwise>
    </xsl:choose> 
  </xsl:template>
  
  
  <xsl:template match="*[@data-template = 'templates:surround']" priority="2" mode="templates">
    <xsl:variable name="template" select="@data-template-with" as="xs:string"/>
    <xsl:variable name="uri" select="resolve-uri($template,base-uri(root(.)))"/>
    <xsl:variable name="doc" select="document($uri)" as="document-node()"/>
    <xsl:variable name="at" select="@data-template-at" as="xs:string"/>
    <xsl:apply-templates select="$doc/*" mode="surround">
      <xsl:with-param name="include" as="element()" select="." tunnel="yes"/>
      <xsl:with-param name="at" select="$at" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="*[@data-template]" mode="templates">
    <xsl:element name="{@data-template}" >
       <xsl:apply-templates select="@* except @data-template" mode="#current"/>
       <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="*[@id]" mode="surround">
    <xsl:param name="include" as="element()" tunnel="yes"/>
    <xsl:param name="at" as="xs:string?" tunnel="yes"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:choose>
        <xsl:when test="@id = $at">
           <xsl:element name="{$include/local-name()}">
             <xsl:sequence select="$include/@*[not(matches(local-name(),'data-template'))]"/>
             <xsl:sequence select="$include/node()"/>
           </xsl:element>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:otherwise>
      </xsl:choose> 
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>