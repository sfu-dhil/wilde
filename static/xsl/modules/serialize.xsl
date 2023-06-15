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
      <xd:p><xd:b>Created on:</xd:b> Jun 15, 2023</xd:p>
      <xd:p><xd:b>Author:</xd:b> takeda</xd:p>
      <xd:p>Stylesheet for serializing a JSON map into something usable</xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:mode name="serialize" on-no-match="shallow-copy"/>
  
  <xsl:template match=".[. instance of map(*)]" mode="serialize">
    <xsl:variable name="curr" select="." as="map(*)"/>
    <xsl:map>
      <xsl:for-each select="map:keys($curr)">
        <xsl:variable name="value" select="map:get($curr, .)" as="item()*"/>
        <xsl:map-entry key=".">
          <xsl:iterate select="$value">
            <xsl:param name="outputSeq" as="item()*"/>
            <xsl:on-completion>
              <xsl:choose>
                <xsl:when test="count($outputSeq) gt 1">
                  <xsl:sequence select="[$outputSeq]"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:sequence select="$outputSeq"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:on-completion>
            <xsl:next-iteration>
              <xsl:with-param name="outputSeq">
                <xsl:sequence select="$outputSeq"/>
                <xsl:apply-templates select="." mode="#current"/>
              </xsl:with-param>
            </xsl:next-iteration>
          </xsl:iterate>
        </xsl:map-entry>
      </xsl:for-each>
    </xsl:map>
  </xsl:template>
 
  <xsl:function name="dhil:mapToJson" as="item()*">
    <xsl:param name="item" as="item()*"/>
    <xsl:choose>
      <xsl:when test="count($item) gt 1">
        <xsl:sequence select="array{$item ! dhil:mapToJson(.)}"/>
      </xsl:when>
      <xsl:when test="$item instance of map(*)">
        <xsl:map>
          <xsl:for-each select="map:keys($item)">
            <xsl:map-entry key="." select="dhil:mapToJson($item(.))"/>
          </xsl:for-each>
        </xsl:map>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$item"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
</xsl:stylesheet>