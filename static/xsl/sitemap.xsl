<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  exclude-result-prefixes="#all"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Nov 12, 2024</xd:p>
      <xd:p><xd:b>Author:</xd:b> takeda</xd:p>
      <xd:p></xd:p>
    </xd:desc>
  </xd:doc>
  <xsl:include href="./modules/log.xsl"/>
  
  <xsl:param name="dist.dir"/>
  <xsl:param name="log" as="xs:string" select="'info'"/>
  <xsl:param name="base" select="'https://wilde.dhil.lib.sfu'"/>
  
  <xsl:variable name="today" as="xs:string"
    select="current-date() => format-date('[Y0001]-[M01]-[D01]')"/>
  <xsl:variable name="uris"  as="xs:anyURI+"
    select="uri-collection($dist.dir || '?select=*.html;recurse=no')"/>
  <xsl:variable name="docsURIs" as="xs:anyURI+"
    select="uri-collection($dist.dir || '/docs/?select=*.html;recurse=no')"/>
  <xsl:variable name="basenames" as="xs:string+"
    select="$uris ! tokenize(., '[/\.]')[last() - 1]"/>
  <xsl:variable name="docsBasenames" as="xs:string+"
    select="$docsURIs ! ('/docs' || tokenize(., '[/\.]')[last() - 1])"/>
  <xsl:variable name="allURIs" select="($uris, $docsURIs)" as="xs:anyURI+"/>
  <xsl:variable name="allBasenames" select="($basenames, $docsBasenames)" as="xs:string+"/>
  <xsl:template name="go" expand-text="yes">
    <xsl:sequence 
      select="$log.info('Processing ' || count($allURIs) || ' pages')"/>
    <xsl:call-template name="createXMLSitemap"/>
    <xsl:call-template name="createJSONSitemap"/>
  </xsl:template>
  
  <xsl:template name="createXMLSitemap" expand-text="yes">
    <xsl:result-document href="{$dist.dir}/sitemap.xml" method="xml">
      <xsl:sequence 
        select="$log.info('Creating ' || current-output-uri())"/>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <xsl:for-each select="$allBasenames">
          <url>
            <loc>{$base}/{.}.html</loc>
            <lastmod>{$today}</lastmod>
          </url>
        </xsl:for-each>
      </urlset>
    </xsl:result-document>
  </xsl:template>
  
  <xsl:template name="createJSONSitemap">
    <xsl:result-document href="{$dist.dir}/resources/sitemap.json" method="json">
      <xsl:sequence 
        select="$log.info('Creating ' || current-output-uri())"/>
      <xsl:sequence select="map:merge($basenames ! map{.: 1})"/>
    </xsl:result-document>
  </xsl:template>
 
</xsl:stylesheet>