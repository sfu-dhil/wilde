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
  
  <xsl:mode name="app" on-no-match="shallow-copy" use-accumulators="currentReport"/>
  
  <xsl:accumulator name="currentReport" initial-value="()">
    <xsl:accumulator-rule match="html[@id]">
      <xsl:sequence select="map:get($reports, @id)"/>
    </xsl:accumulator-rule>
  </xsl:accumulator>
  
  <xsl:variable name="getReport" 
    select="function($node) {
         let $report := $node/accumulator-before('currentReport')
         return $hydrate($report)
    }"/>
  
  <xsl:template match="html[@id]" mode="app">
<!--    <xsl:param name="data" tunnel="yes" as="map(*)?"/>-->
   <!-- <xsl:variable name="outputId" select="if (exists($data)) then $data?id else .?basename"/>-->
<!--    <xsl:variable name="template" select="(.?template)/html" as="element(html)"/-->
    <xsl:result-document href="{$dist.dir}/{@id}.html" method="xhtml" version="5.0">
       <xsl:sequence select="dhil:debug('Building ' || current-output-uri())"/>
       <xsl:copy>
         <xsl:apply-templates select="@*|node()" mode="#current"/>
       </xsl:copy>
    </xsl:result-document>
  </xsl:template>
  

  <xsl:template match="app:doc-source" priority="3" mode="app">
    <xsl:variable name="report" select="$getReport(.)" as="function(*)"/>
    <xsl:where-populated>
      <dd><xsl:value-of select="$report('institution')"/></dd>
    </xsl:where-populated>
    <xsl:where-populated>
      <dd><xsl:value-of select="$report('database')"/></dd>
    </xsl:where-populated>
    <xsl:for-each select="$report('this')?dc.source.url">
      <dd>
        <xsl:sequence select="dhil:ext-link(.)"/>
      </dd>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="app:doc-facsimile" priority="3" mode="app">
    <xsl:variable name="report" select="$getReport(.)"/>
    <xsl:sequence>
      <xsl:for-each select="$report('facsimile')">
        <dd class="facsimile">
          <xsl:sequence select="dhil:ext-link(.)"/>
        </dd>
      </xsl:for-each>
      <xsl:on-empty>
        <dd><i>None found</i></dd>
      </xsl:on-empty>
    </xsl:sequence>
  </xsl:template>
 
  <xsl:template match="app:doc-previous | app:doc-next" priority="3" mode="app">
    <xsl:param name="report" select="$getReport(.)"/>
    <xsl:variable name="publisher" select="$report('publisher')"/>
    <xsl:variable name="id" select="$report('id')"/>
    <xsl:variable name="sequence" select="map:get($reportsByMeta?dc.publisher, $publisher)"/>
    <xsl:variable name="idx" select="index-of($sequence, $id)"/>
    <xsl:variable name="prevId" select="if ($idx = 1) then () else $sequence[$idx - 1]"/>
    <xsl:variable name="nextId" select="if ($idx = count($sequence)) then () else $sequence[$idx + 1]"/>
    <xsl:choose>
      <xsl:when test="local-name() = 'doc-previous'">
        <xsl:choose>
          <xsl:when test="exists($prevId)">
            <a href="{$prevId}.html"><xsl:value-of select="$reports($prevId)?title"/></a>
          </xsl:when>
          <xsl:otherwise>No previous document</xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="exists($nextId)">
            <a href="{$nextId}.html"><xsl:value-of select="$reports($nextId)?title"/></a>
          </xsl:when>
          <xsl:otherwise>No next document</xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
  <xsl:template match="app:*[matches(local-name(),'doc-')]" priority="2" mode="app">
    <xsl:variable name="report" select="$getReport(.)"/>
    <xsl:variable name="field" select="substring-after(local-name(),'doc-')"/>
    <xsl:choose>
      <xsl:when test="not(map:keys($fieldMap) = $field)">
        <xsl:next-match/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="val" select="$report($field)"/>
        <xsl:choose>
          <xsl:when test="empty($val)"/>
          <xsl:when test="$linkedFields = $field">
            <xsl:sequence 
              select="dhil:getIdForField($field, $val) => 
              dhil:link($val)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="$val"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="app:parameter" mode="app">
    <xsl:param name="data" tunnel="yes"/>
    <xsl:variable name="name" select="@data-template-name"/>
    <xsl:sequence select="map:get($data, $name)"/>
  </xsl:template>
  
  
  
  <xsl:template match="app:breadcrumb" mode="app">
    <xsl:param name="data" tunnel="yes"/>
    <xsl:param name="template" tunnel="yes" as="map(*)"/>
    <xsl:variable name="report" select="$getReport(.)"/>
    <nav aria-label="breadcrumb" class="col-md-12">
      <ol class="breadcrumb">
        <li class="breadcrumb-item">
          <a href="index.html">Home</a>
        </li>
        <xsl:choose>
          <!--We're in a report-->
          <xsl:when test="$template?basename = 'view'">
            <li class="breadcrumb-item">
              <a href="newspaper.html">Browse by Newspaper</a>
            </li>
            <li class="breadcrumb-item">
              <a href="{dhil:getIdForField('newspaper', $report('newspaper'))}.html"><xsl:value-of select="$report('newspaper')"/></a>
            </li>
            <li class="breadcrumb-item active" aria-current="page">
              <xsl:choose>
                <xsl:when test="$report('date') castable as xs:date">
                  <xsl:sequence select="$report('date') => xs:date() => format-date('[MNn] [D1], [Y0001]')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$report('date')"/>
                </xsl:otherwise>
              </xsl:choose>
            </li>
          </xsl:when>
        </xsl:choose>
      </ol>
    </nav>
  </xsl:template>
  
<!--  <xsl:template match="app:breadcrumb" mode="app">
    <xsl:param name="data" tunnel="yes"/>
    <xsl:param name="template" tunnel="yes"/>
    <xsl:choose>
      <!-\-We're in a report-\->
      <xsl:when test="$template?basename = 'view'">
        
      </xsl:when>
    </xsl:choose> 
  </xsl:template>-->
  
  
<!--  <xsl:function name="dhil:breadcrumbDetails">
    <xsl:param name="field"/>
    <xsl:param name="value"/>
    
    
  </xsl:function>
  
  -->
   
  <xsl:template match="app:browse" mode="app">
    <xsl:sequence select="dhil:report-table(dhil:map-entries($reports))"/>
  </xsl:template> 
  
  <xsl:template match="app:*[matches(local-name(),'details-')]" mode="app">
    <xsl:param name="data" tunnel="yes" as="map(*)?"/>
    <xsl:variable name="field" select="substring-after(local-name(), 'details-')"/>
    <xsl:sequence select="dhil:report-table($data?reports, $field)"/>
  </xsl:template>
   
   <xsl:function name="dhil:report-table">
     <xsl:param name="reports" as="map(*)*"/>
     <xsl:sequence select="dhil:report-table($reports,())"/>
   </xsl:function>
  
  <xsl:function name="dhil:report-table">
    <xsl:param name="reports" as="map(*)*"/>
    <xsl:param name="field" as="xs:string?"/>
    <xsl:variable name="fields" select="('date', 'publisher', 'region', 'city', 'language')[not(. = $field)]"/>
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
          <xsl:variable name="report" select="$hydrate(.)" as="function(*)"/>
            <tr>
              <td data-name="Headline">
                <a href="{$report('id')}.html">
                  <xsl:sequence select="($report('headlines')[1],$report('title'))[1] => string()"/>
                </a>
              </td>
              <xsl:for-each select="$fields">
                <xsl:variable name="currField" select="."/>
                <td data-name="{dhil:capitalize($currField)}">
                  <xsl:variable name="val" select="$report($currField)"/>
                  <xsl:choose>
                    <xsl:when test="empty($val)"/>
                    <xsl:when test="$linkedFields = $currField">
                      <xsl:sequence 
                        select="dhil:getIdForField($currField, $val) => 
                        dhil:link($val)"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:sequence select="$val"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </td>
              </xsl:for-each>
              <td><xsl:value-of select="count($report('doc-similarity'))"/></td>
              <td><xsl:value-of select="count($report('paragraph-similarity'))"/></td>
              <td><xsl:value-of select="$report('word-count')"/></td>
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
  
  
  <xsl:function name="dhil:ext-link">
    <xsl:param name="url"/>
    <a href="{$url}" rel="nofollow" target="_blank">
      <xsl:sequence select="replace($url, '^https?://([^/]+)/.+$', '$1')"/>
    </a>
  </xsl:function>
  
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