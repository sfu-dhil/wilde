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
  
  <xsl:mode name="app" on-no-match="shallow-copy"/>
  
  <xsl:template match=".[. instance of map(*)]" mode="app">
    <xsl:param name="data" tunnel="yes" as="map(*)?"/>
    <xsl:variable name="outputId" select="if (exists($data)) then $data?id else .?basename"/>
    <xsl:variable name="template" select="(.?template)/html" as="element(html)"/>
    <xsl:result-document href="{$dist.dir}/{$outputId}.html" method="xhtml" version="5.0">
       <xsl:sequence select="dhil:debug('Building ' || current-output-uri())"/>
       <xsl:apply-templates select="$template" mode="#current">
         <xsl:with-param name="data" select="$data" tunnel="yes"/>
       </xsl:apply-templates>
    </xsl:result-document>
  </xsl:template>
  
  <!--
    
       <meta content="1895-06-08" name="dc.date" />
    <meta content="2022-04-22" name="dc.date.updated" />
    <meta content="fr" name="dc.language" />
    <meta content="Le Socialiste de la Manche" name="dc.publisher" data-sortable="socialiste de la manche" />
    <meta content="f_lsdlm_161" name="dc.publisher.id" />
    <meta content="socialiste de la manche" name="dc.publisher.sortable" />
    <meta content="France" name="dc.region" />
    <meta content="Cherbourg" name="dc.region.city" />
    <meta content="Gallica" name="dc.source.database" />
    <meta content="https://gallica.bnf.fr/ark:/12148/bpt6k63893370/f2.item.r=%22oscar%20wilde%22" name="dc.source.facsimile" />
    <meta content="Bibliothèque nationale de France" name="dc.source.institution" />
    <meta content="https://gallica.bnf.fr/ark:/12148/cb32868966m/date1895" name="dc.source.url" />
    <meta content="socialiste de la manche - 1895-06-08" name="wr.sortable" />
    <meta content="yes" name="wr.translated" />
    <meta content="20" name="wr.word-count" />-->
  
  <xsl:template match="app:doc-title" mode="app">
    <xsl:param name="data" tunnel="yes" as="map(*)?"/>
    <xsl:apply-templates select="$data?title" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="app:doc-word-count" mode="app">
    <xsl:param name="data" tunnel="yes" as="map(*)?"/>
    <xsl:apply-templates select="$data?wr.word-count"/>
  </xsl:template> 
  
  <xsl:template match="app:doc-language" mode="app">
     <xsl:param name="data" tunnel="yes" as="map(*)?"/>
     <xsl:apply-templates select="dhil:link($data?dc.language)"/>
  </xsl:template>
  
  <xsl:template match="app:doc-edition" mode="app">
    <xsl:param name="data" tunnel="yes" as="map(*)?"/>
    <xsl:sequence select="$data?dc.publisher.edition"/>
  </xsl:template>
  
  <xsl:template match="app:doc-publisher" mode="app">
    <xsl:param name="data" tunnel="yes" as="map(*)?"/>
    <xsl:sequence select="$data?dc.publisher"/>
  </xsl:template>
  
  <xsl:template match="app:doc-region" mode="app">
    <xsl:param name="data" tunnel="yes" as="map(*)?"/>
    <xsl:sequence select="$data?dc.region"/>
  </xsl:template>
  
  <xsl:template match="app:doc-city" mode="app">
    <xsl:param name="data" tunnel="yes" as="map(*)?"/>
    <xsl:sequence select="$data?dc.region.city"/>
  </xsl:template>
  
  <xsl:template match="app:doc-date" mode="app">
    <xsl:param name="data" tunnel="yes" as="map(*)?"/>
    <xsl:sequence select="$data?dc.date"/>
  </xsl:template>
  
  <xsl:template match="app:doc-updated" mode="app">
    <xsl:param name="data" tunnel="yes" as="map(*)?"/>
    <xsl:sequence select="$data?dc.date.updated"/>
  </xsl:template>
  
  <xsl:template match="app:doc-source" mode="app">
    <xsl:param name="data" tunnel="yes" as="map(*)?"/>
    <xsl:sequence select="$data?dc.source"/>
  </xsl:template>
  
  <xsl:template match="app:doc-facsimile" mode="app">
    <xsl:param name="data" tunnel="yes" as="map(*)?"/>
    <xsl:sequence select="$data?dc.source.facsimile"/>
  </xsl:template>
  
  <xsl:template match="app:parameter[@data-template-name = 'region']" mode="app">
    <xsl:param name="data" tunnel="yes" as="map(*)?"/>
    <xsl:sequence select="$data?region"/>
  </xsl:template>
  
  <xsl:template match="app:details-region" mode="app">
    <xsl:param name="data" tunnel="yes" as="map(*)?"/>
    <xsl:sequence select="dhil:report-table($data?reports, 'region')"/>
  </xsl:template>
  
  <xsl:function name="dhil:report-table">
    <xsl:param name="reports" as="map(*)*"/>
    <xsl:param name="param" as="xs:string?"/>
    <xsl:variable name="fields" select="('date', 'publisher', 'region', 'city', 'language')[not(. = $param)]"/>
    <table class="table table-striped table-hover table-condensed" id="tbl-browser">
      <thead>
        <tr>
          <th>Headline</th>
          <xsl:for-each select="$fields">
            <th>
              <xsl:sequence select="dhil:capitalize(.)"/>
            </th>
          </xsl:for-each>
          <th class="count">Document <br/>Matches</th>
          <th class="count">Paragraph <br/>Matches</th>
          <th class="count">Word Count</th>
        </tr>
      </thead>
      <tbody>
        <xsl:for-each select="$reports">
            <tr>
              <td data-name="Headline"></td>
              <xsl:for-each select="$fields">
                <td data-name="{dhil:capitalize(.)}">
                  <!--Get data-->
                </td>
              </xsl:for-each>
            </tr>
        </xsl:for-each>
      </tbody>
    </table>
  </xsl:function>
 
  <xsl:template match="app:load" mode="app">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template match="app:*" priority="-1" mode="app">
    <xsl:message>WARNING: <xsl:value-of select="name()"/> unmatched</xsl:message>
    <xsl:next-match/>
  </xsl:template>
  
  
  
  <xsl:function name="dhil:link">
    <xsl:param name="id"/>
    <xsl:sequence select="dhil:link($id, $id)"/> 
  </xsl:function>
  
  <xsl:function name="dhil:link">
    <xsl:param name="id"/>
    <xsl:param name="text"/>
    <a href="{$id}.html"><xsl:value-of select="$text"/></a>
  </xsl:function>
  
  <xsl:function name="dhil:capitalize">
    <xsl:param name="str"/>
    <xsl:sequence select="upper-case(substring($str,1,1)) || substring($str, 2)"/>
  </xsl:function>
  
</xsl:stylesheet>