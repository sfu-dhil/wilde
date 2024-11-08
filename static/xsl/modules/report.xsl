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
      <xd:p><xd:b>Created on:</xd:b> Jun 9, 2023</xd:p>
      <xd:p><xd:b>Author:</xd:b> takeda</xd:p>
      <xd:p></xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:mode name="report" on-no-match="shallow-skip"/>
  
  <!--Since we can't do typing and object properties 
      until XSLT 4.0, this is a sample object of what we should expect-->
   
<!--  <xsl:variable name="REPORT_SCHEMA" select="map{
      'id': 'string',
      'title': 'string',
      'doc-similarity': 
    
    
    
    }"-->
  
  
  <xsl:template match="/" mode="report">
    <!--<xsl:sequence select="dhil:debug('Processing data: ' || document-uri(.))"/>-->
    <xsl:map>
      <xsl:apply-templates select="*" mode="#current"/> 
    </xsl:map>
  </xsl:template>
  
  <xsl:template match="html/@id" mode="report">
    <xsl:map-entry key="'id'" select="string(.)"/>
  </xsl:template>
  
  <xsl:template match="head" mode="report">
    <xsl:apply-templates select="* except (meta, link)" mode="#current"/>
    <xsl:apply-templates select="meta" mode="#current"/>
    <xsl:where-populated>
      <xsl:map-entry key="'dc.source'" select="array{distinct-values(meta[matches(@name,'^dc\.source(\.(database|institution))?$')] ! @content)}"/>
    </xsl:where-populated>
  
    
<!--    {
      'publisher':
      'newspaper':
      'language':
      'facsimile':
      'headlines':
      'translations': [
        {
          'id':
          'lang':
          'original':
          'heading':
          'content': [
            {
              p
            
            }
          ],
        }
      ]
    }-->
    <!--
    <xsl:for-each-group select="meta" group-by="@name">
      <xsl:map-entry key="current-grouping-key()" select="current-group()/@content ! string(.)"/>
    </xsl:for-each-group>-->
    <xsl:map-entry key="'doc-similarity'">
      <xsl:apply-templates select="link[@rel='similarity']" mode="#current"/>
    </xsl:map-entry>
  </xsl:template>
  
  <xsl:template match="head/title" mode="report">
    <xsl:map-entry key="'title'" select="string(.)"/>
  </xsl:template>
  
  <!--We have to skip source given that it's a multi category-->
  <xsl:template match="meta[@name='dc.source']" mode="report" priority="2"/>
  
  <xsl:template match="meta" mode="report">
    <xsl:map-entry key="string(@name)" select="string(@content)"/>
  </xsl:template>
  
  <xsl:template match="body" mode="report">
    <xsl:map-entry key="'headlines'" select="./div/p[contains-token(@class,'heading')]"/>
    <xsl:map-entry key="'translations'">
      <xsl:map>
        <xsl:apply-templates select="div" mode="#current"/>
      </xsl:map>
    </xsl:map-entry>
    <xsl:variable name="similarParas" select="//p[@id][*[dhil:isSimilarityLink(.)]]" as="element(p)*"/>
    <xsl:where-populated>
      <xsl:map-entry key="'paragraph-similarity'">
        <xsl:map>
          <xsl:apply-templates select="$similarParas" mode="#current"/>
        </xsl:map>
      </xsl:map-entry>
    </xsl:where-populated>
  </xsl:template>
  
  
  <!--Currently this produces a map, but should really be map-entries, by lang, I think-->
  <xsl:template match="div" mode="report">    
    <xsl:map-entry key="string(@id)">
      <xsl:map>
        <xsl:map-entry key="'lang'" select="xs:string(@lang)"/>
        <xsl:map-entry key="'id'" select="string(@id)"/>
        <xsl:map-entry key="'original'" select="@id = 'original'"/>
        <xsl:map-entry key="'heading'" select="p[contains-token(@class,'heading')]"/>
        <xsl:map-entry key="'content'" select="."/>
      </xsl:map>
    </xsl:map-entry>
  </xsl:template>
    
    
  <xsl:template match="p[contains-token(@class,'heading')]" mode="report">
    <xsl:map-entry key="'heading'" select="."/>
  </xsl:template>
  
  <xsl:template match="p[@id][*[dhil:isSimilarityLink(.)]]" mode="report">
    <xsl:map-entry key="string(@id)">
        <xsl:apply-templates select="*[dhil:isSimilarityLink(.)]" mode="#current"/>
    </xsl:map-entry>
  </xsl:template>
  
  <xsl:template
    match="*[dhil:isSimilarityLink(.)]" mode="report">
      <xsl:map>
          <xsl:apply-templates select="@*" mode="#current"/>
        
      </xsl:map>
  </xsl:template>
  
  <xsl:template match="*[dhil:isSimilarityLink(.)]/@href" mode="report">
    <xsl:map-entry key="'href'" select="string(.)"/>      
  </xsl:template>
  
  <xsl:template match="@*[matches(local-name(), '^data-')]" mode="report">
     <xsl:map-entry key="substring-after(local-name(), 'data-')" select="if (. castable as xs:float) then xs:float(.) else string(.)"/>
  </xsl:template>

  <xsl:function name="dhil:isSimilarityLink" as="xs:boolean">
    <xsl:param name="el" as="element()"/>
    <xsl:sequence select="($el/self::a or $el/self::link) and contains-token($el/@class, 'similarity')"/>
  </xsl:function>
  
  
  
  
  
</xsl:stylesheet>