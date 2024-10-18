<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array"
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
  xmlns:log="http://dhil.lib.sfu.ca/log"
  exclude-result-prefixes="#all"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Jun 8, 2023</xd:p>
      <xd:p><xd:b>Author:</xd:b> takeda</xd:p>
      <xd:p>Initial implementation of a static version of Wilde, building into HTML.</xd:p>
    </xd:desc>
  </xd:doc>
 
 
 
  <!--Basic parameters-->
  <xsl:param name="reports.dir"/>
  <xsl:param name="templates.dir"/>
  <xsl:param name="dist.dir"/>
  <xsl:param name="log" as="xs:string" select="'info'"/>
  <xsl:param name="docsToBuild" as="xs:string" select="''" static="yes"/>
  
  <xsl:variable name="isSubset" 
    select="string-length(normalize-space($docsToBuild)) gt 0" 
    static="yes"/>
 
  <!--Includes-->

  <xsl:include href="modules/app.xsl"/>
  <xsl:include href="modules/log.xsl"/>
  <xsl:include href="modules/report.xsl"/>
  <xsl:include href="modules/templates.xsl"/>
  <xsl:include href="modules/serialize.xsl"/>
  
  <!--Top level collection variables-->
  <xsl:variable name="templates.collection"
    select="collection($templates.dir || '?select=*.html&amp;metadata=yes')"
    as="map(*)+"/>
  
  <xsl:variable name="reports.collection" 
    select="collection($reports.dir || '?select=*.xml;recurse=yes;metadata=yes')"
    as="map(*)+"/>
  
  
  <xsl:variable name="templates" as="map(xs:string, item()*)+">
    <xsl:sequence 
      select="$log.info('Processing ' || count($templates.collection) || ' templates in ' || $templates.dir)"/>
    <xsl:for-each select="$templates.collection">
        <xsl:variable name="curr" select="." as="map(*)"/>
        <xsl:map>
            <xsl:sequence select="map:remove($curr,'fetch')"/>
            <xsl:sequence select="dhil:uri($curr?canonical-path)"/>
            <xsl:map-entry key="'template'">
              <xsl:call-template name="templates:surround">
                <xsl:with-param name="doc" select="$curr?fetch()"/>
              </xsl:call-template>
            </xsl:map-entry>
        </xsl:map>
    </xsl:for-each>
  </xsl:variable>
  
  <xsl:variable name="reports" as="map(*)">
   <xsl:sequence 
     select="$log.info('Creating map of ' || count($reports.collection) || ' reports in ' || $reports.dir)"/>
   <xsl:map>
     <xsl:for-each select="$reports.collection">
       <xsl:variable name="curr" select="." as="map(*)"/>
       <xsl:variable name="doc" select="$curr?fetch()" as="document-node()"/>
       <xsl:variable name="reportData" as="map(*)">
         <xsl:apply-templates select="$doc" mode="report"/>
       </xsl:variable>
       <xsl:map-entry key="$reportData?id">
         <xsl:map>
<!--           <xsl:map-entry key="'doc'" select="$doc"/>-->
           <xsl:sequence select="dhil:uri($curr?canonical-path)"/>
           <xsl:sequence select="$reportData"/>
         </xsl:map>
       </xsl:map-entry>
     </xsl:for-each>
   </xsl:map> 
  </xsl:variable>
  
  <xsl:variable name="reportsByMeta" as="map(*)">
   <xsl:map>
     <xsl:for-each-group select="dhil:map-entries($reports)" group-by="map:keys(.)[matches(.,'^(dc|wr)\.')]">
       <xsl:variable name="key" select="current-grouping-key()"/>
       <xsl:choose>
         <xsl:when test="$key = ('dc.source.facsimile', 'dc.source.url', 'wr.sortable', 'wr.word-count')"/>
         <xsl:otherwise>
           <xsl:map-entry key="$key">
              <xsl:map>
                <xsl:for-each-group select="current-group()" group-by="map:get(., $key)">
                  <xsl:map-entry key="current-grouping-key()" 
                    select="sort(current-group(), (), function($report){
                                    if ($report?dc.date castable as xs:date)
                                      then xs:date($report?dc.date)
                                      else $report?dc.date
                                   }) ! string(.?id)"/>
                </xsl:for-each-group>
              </xsl:map>
           </xsl:map-entry>
         </xsl:otherwise>
       </xsl:choose>
     </xsl:for-each-group>
   </xsl:map> 
  </xsl:variable>
  
  <xsl:variable name="publisherToPubId" as="map(*)">
    <xsl:map>
      <xsl:for-each select="map:keys($reportsByMeta?dc.publisher)">
          <xsl:map-entry key=".">
            <xsl:variable name="reportId" select="map:get($reportsByMeta?dc.publisher, .)[1]"/>
            <xsl:variable name="report" select="map:get($reports, $reportId)"/>
            <xsl:variable name="pubId" select="$report?dc.publisher.id"/>
            <xsl:sequence select="$pubId"/>
          </xsl:map-entry>
      </xsl:for-each>
    </xsl:map>
  </xsl:variable>
  
  <xsl:variable name="construct" select="
    function($map as map(*)) as function(xs:string) as item()*{
    function($key as xs:string) as item()*{
        dhil:getFromReport($map, $key)
    }}"/>
  
  
  <xsl:function name="dhil:getFromReport" new-each-time="no">
    <xsl:param name="map" as="map(*)"/>
    <xsl:param name="key" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$key = 'this'">
        <xsl:sequence select="$map"/>
      </xsl:when>
      <xsl:when test="$key = 'paragraphs'">
        <xsl:sequence select="let $translations := dhil:map-entries($map?translations)
          return map:merge($translations?content/p[@id] ! map{string(./@id) : .})"/>
      </xsl:when>
      <xsl:when test="map:contains($map, $key)">
        <xsl:sequence select="map:get($map, $key)"/>
      </xsl:when>
      <xsl:when test="not(map:contains($fieldMap, $key))">
        <xsl:sequence select="error((), 'No field found for ' || $key)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="dcTerm" select="$fieldMap($key)"/>
        <xsl:variable name="val" select="$map($dcTerm)"/>
        <xsl:choose>
          <xsl:when test="$key='language'">
            <xsl:sequence select="$code2lang($val)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="$val"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>    
  </xsl:function>
  
  
  <xsl:variable name="fieldMap" select="map{
    'region': 'dc.region',
    'language': 'dc.language',
    'langCode': 'dc.language',
    'city': 'dc.region.city',
    'date': 'dc.date',
    'facsimile': 'dc.source.url',
    'title': 'title',
    'word-count': 'wr.word-count',
    'edition': 'dc.publisher.edition',
    'newspaper': 'dc.publisher',
    'publisher': 'dc.publisher',
    'updated': 'dc.date.updated',
    'source': 'dc.source',
    'institution': 'dc.source.institution',
    'database': 'dc.source.database'
    }
    "/>

  <xsl:variable name="code2lang" as="map(xs:string, xs:string)" select="map{
      'de': 'German',
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'it': 'Italian'
    }"/>
  
  <xsl:variable name="lang2code" select="map:merge(map:keys($code2lang) ! map{$code2lang(.): .})"/>
  
  <xsl:variable name="linkedFields" 
    select="($templates[matches(.?basename,'-details')] ! substring-before(.?basename, '-details'), 'publisher')"/>
  
  <xsl:template name="go">
    <xsl:sequence select="$log.info('Building subset of documents: ' || $docsToBuild)" use-when="$isSubset"/>
    <xsl:if test="map:size($reports) = 0">
      <xsl:message terminate="yes">No reports found</xsl:message>
    </xsl:if>
    <xsl:call-template name="controller"/>
<!--    <xsl:call-template name="exports"/>-->
    <xsl:result-document href="tmp/reports.json" method="json">
      <xsl:choose>
        <xsl:when test="$isSubset">
          <xsl:variable name="keys" select="map:keys($reports)[matches(.,$docsToBuild)]"/>
          <xsl:variable name="submap" select="map:merge($keys ! map:get($reports, .))"/>
          <xsl:sequence select="dhil:mapToJson($submap)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence
            select="dhil:mapToJson($reports)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:result-document>
  </xsl:template>
  
  <xsl:template name="export">
    <xsl:for-each select="map:keys($reports)">
      <xsl:result-document href="{$dist.dir}/_data/{.}.json" method="json">
        <xsl:sequence select="dhil:mapToJson($reports(.))"/>
      </xsl:result-document>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template name="controller">
    <xsl:for-each select="$templates">
      <xsl:variable name="template" select="." as="map(*)"/>
      <xsl:variable name="basename" select=".?basename" as="xs:string"/>
      <xsl:variable name="templateDoc" select="(.?template)/html" as="element(html)"/>
      <xsl:choose>
        <xsl:when test="not(dhil:isDocToBuild($basename))" use-when="$isSubset"/>
        
        <xsl:when test="$basename = 'view'">
          <xsl:call-template name="view"/>
        </xsl:when>
        <xsl:when test="matches($basename, '-details')">
          <xsl:call-template name="details"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="dhil:addIdToTemplate($templateDoc, $basename)" mode="app">
            <xsl:with-param name="template" select="$template" tunnel="yes"/>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose> 
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template name="view">
    <xsl:param name="template" select="." as="map(*)"/>
    <xsl:variable name="templateDoc" select="(.?template)/html" as="element(html)"/>
    <xsl:for-each select="map:keys($reports)">
      <xsl:variable name="newTemplate" select="dhil:addIdToTemplate($templateDoc,.)"/>
      <xsl:apply-templates select="$newTemplate" mode="app">
        <xsl:with-param name="template" select="$template" tunnel="yes"/>
        <xsl:with-param name="data" select="$reports(.)" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template name="details">
    <xsl:param name="template" select="." as="map(*)"/>
    <xsl:variable name="templateDoc" select="(.?template)/html" as="element(html)"/>
    <xsl:variable name="field" select="substring-before($template?basename, '-details')" as="xs:string"/>
    <xsl:for-each-group select="dhil:map-entries($reports)" group-by="map:get(., $fieldMap($field))">
      <xsl:variable name="param" select="current-grouping-key()"/>
      <xsl:variable name="id" select="dhil:getIdForField($field, $param)"/>
      <xsl:variable name="newTemplate" select="dhil:addIdToTemplate($templateDoc, $id)"/>
      <xsl:apply-templates select="$newTemplate" mode="app">
        <xsl:with-param name="template" select="$template" tunnel="yes"/>
        <xsl:with-param name="data" tunnel="yes" select="map{
          $field: $param,
          'id': dhil:getIdForField($field, $param),
          'reports': current-group()
          }"/>
      </xsl:apply-templates>
    </xsl:for-each-group>
  </xsl:template>
  
  
  
  <xsl:function name="dhil:addIdToTemplate" as="element(html)">
    <xsl:param name="templateDoc" as="element(html)"/>
    <xsl:param name="id" as="xs:string"/>
    <html id="{$id}">
      <xsl:sequence select="$templateDoc/(@*|node())"/>
    </html>
  </xsl:function>
  
  
  <xsl:function name="dhil:getIdForField" as="xs:string">
    <xsl:param name="field"/>
    <xsl:param name="param"/>
    <xsl:variable name="prefix" select="if ($field = 'publisher') then 'newspaper' else $field"/>
    <xsl:variable name="val" as="xs:string">
      <xsl:choose>
        <xsl:when test="$field = 'language'">
          <xsl:variable name="langCode" select="($lang2code($param), $param)[1]" as="xs:string"/>
          <xsl:sequence select="$langCode"/>
        </xsl:when>
        <xsl:when test="$field = ('publisher','newspaper')">
          <xsl:variable name="pubId" select="$publisherToPubId($param)" as="xs:string"/>
          <xsl:sequence select="$pubId"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$param"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="$prefix || '-' || $val"/>
  </xsl:function>
  
  <xsl:function name="dhil:map-entries" as="item()*">
    <xsl:param name="map" as="map(*)"/>
    <xsl:for-each select="map:keys($map)">
      <xsl:sequence select="$map(.)"/> 
    </xsl:for-each>
  </xsl:function>
  
  <xsl:function name="dhil:empty" as="xs:boolean">
    <xsl:param name="item" as="item()*"/>
    <xsl:choose>
      <xsl:when test="empty($item)">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:when test="count($item) = 1 and $item instance of xs:string">
        <xsl:choose>
          <xsl:when test="string-length(normalize-space(string-join($item))) = 0">
            <xsl:sequence select="true()"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="false()"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="dhil:uri" as="map(xs:string, xs:string*)+">
    <xsl:param name="_uri" as="xs:string"/>
    <xsl:variable name="uri" select="replace($_uri,'^file:','')"/>
    <xsl:variable name="parts" select="tokenize($uri,'/')" as="xs:string+"/>
    <xsl:variable name="dir" select="string-join($parts[not(last())],'/')"/>
    <xsl:variable name="filename" select="$parts[last()]" as="xs:string"/>
    <xsl:variable name="ext" select="replace($filename,'^[^\.]+\.','')" as="xs:string"/>
    <xsl:variable name="basename" select="replace($filename,('\.' || $ext || '.*$'), '')" as="xs:string"/>
    <xsl:map>
      <xsl:map-entry key="'uri'" select="$uri"/>
      <xsl:map-entry key="'dir'" select="$dir"/>
      <xsl:map-entry key="'basename'" select="$basename"/>
      <xsl:map-entry key="'ext'" select="$ext"/>
      <xsl:map-entry key="'filename'" select="$filename"/>
    </xsl:map>
  </xsl:function>
  
  <xsl:function name="dhil:isDocToBuild" as="xs:boolean">
    <xsl:param name="id" as="xs:string"/>
    <xsl:sequence select="$id = tokenize($docsToBuild,'\s*,\s*')"/>
  </xsl:function>
  
  
</xsl:stylesheet>