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
  xmlns:xso="dummy"
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
  <xsl:param name="debug" select="'true'"/>
  
  <!--Includes-->
  <xsl:include href="modules/_app.xsl"/>
  <xsl:include href="modules/_report.xsl"/>
  <xsl:include href="modules/_templates.xsl"/>
  
  <xsl:variable name="templates" as="map(xs:string, item()*)+">
    <xsl:for-each select="collection($templates.dir || '?select=*.html&amp;metadata=yes')">
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
   <xsl:map>
     <xsl:for-each select="collection($reports.dir || '?select=*.xml;recurse=yes;metadata=yes')">
       <xsl:variable name="curr" select="." as="map(*)"/>
       <xsl:variable name="doc" select="$curr?fetch()" as="document-node()"/>
       <xsl:variable name="reportData" as="map(*)">
         <xsl:apply-templates select="$doc" mode="report"/>
       </xsl:variable>
       <xsl:map-entry key="$reportData?id">
         <xsl:map>
           <xsl:map-entry key="'doc'" select="$doc"/>
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
                  <xsl:map-entry key="current-grouping-key()" select="current-group() ! .?id"/>
                </xsl:for-each-group>
              </xsl:map>
           </xsl:map-entry>
         </xsl:otherwise>
       </xsl:choose>
     </xsl:for-each-group>
   </xsl:map> 
  </xsl:variable>
  
  <xsl:variable name="fieldMap" select="map{
    'region': 'dc.region',
    'language': 'dc.language',
    'city': 'dc.region.city',
    'date': 'dc.date',
    'facsimile': 'dc.source.facsimile',
    'title': 'title',
    'word-count': 'wr.word-count',
    'edition': 'dc.publisher.edition',
    'newspaper': 'dc.publisher',
    'publisher': 'dc.publisher',
    'updated': 'dc.date.updated',
    'source': 'dc.source'
    }
    "/>
  
  <xsl:variable name="linkedFields" 
    select="$templates[matches(.?basename,'-details')] ! substring-before(.?basename, '-details')"/>
  
  <xsl:template name="go">
    <xsl:call-template name="controller"/>
  </xsl:template>
  
  <xsl:template name="controller">
    <xsl:for-each select="$templates">
      <xsl:variable name="template" select="." as="map(*)"/>
      <xsl:variable name="basename" select=".?basename" as="xs:string"/>

        <xsl:choose>
          <xsl:when test="$basename = 'view'">
             <xsl:for-each select="dhil:map-entries($reports)">
                 <xsl:apply-templates select="$template" mode="app">
                   <xsl:with-param name="data" select="." tunnel="yes" as="map(*)"/>
                 </xsl:apply-templates>
             </xsl:for-each>
          </xsl:when>
          <xsl:when test="matches($basename, '-details')">
            <xsl:variable name="field" select="substring-before($basename, '-details')" as="xs:string"/>
            <xsl:for-each-group select="dhil:map-entries($reports)" group-by="map:get(., $fieldMap($field))">
               <xsl:variable name="param" select="current-grouping-key()"/>
               <xsl:apply-templates select="$template" mode="app">
                 <xsl:with-param name="data" tunnel="yes" select="map{
                    $field: $param,
                    'id': dhil:getIdForField($field, $param),
                    'reports': current-group()
                   }"/>
               </xsl:apply-templates>
            </xsl:for-each-group>
            
          <!--  <xsl:choose>
              <xsl:when test="$entity = 'region'">
                 <xsl:for-each-group select="dhil:map-entries($reports)" group-by=".?dc.region">
                    <xsl:variable name="region" select="current-grouping-key()"/>
                    <xsl:apply-templates select="$template" mode="app">
                       <xsl:with-param name="data" tunnel="yes" select="map{
                          'region': $region,
                          'id': 'region-' || $region,
                          'reports': current-group()
                          }"/>
                    </xsl:apply-templates>
                 </xsl:for-each-group> 
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="$template" mode="app"/>
              </xsl:otherwise>
            </xsl:choose>
            -->
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="$template" mode="app"/>
          </xsl:otherwise>
        </xsl:choose> 
    </xsl:for-each>
  </xsl:template>
  
  
  <xsl:function name="dhil:getIdForField" as="xs:string">
    <xsl:param name="field"/>
    <xsl:param name="param"/>
    <xsl:sequence select="$field || '-' || $param"/>
  </xsl:function>
  
  <xsl:function name="dhil:map-entries" as="item()*">
    <xsl:param name="map" as="map(*)"/>
    <xsl:for-each select="map:keys($map)">
      <xsl:sequence select="$map(.)"/> 
    </xsl:for-each>
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
  
  <xd:doc>
    <xd:desc>
      <xd:ref name="dhil:msg" type="function"/>
      <xd:p>Wrapper function for xsl:message to control
        logging level</xd:p>
    </xd:desc>
    <xd:param name="msg">The message to be output to the console.</xd:param>
    <!--NOTE: Need to investigate why the AVT version of use-when doesn't
            work for xsl:message anymore (I swear it used to, pre Saxon11)-->
  </xd:doc>
  <xsl:function name="dhil:debug" as="empty-sequence()">
    <xsl:param name="msg" as="item()*"/>
    <xsl:if test="$debug = 'true'">
      <xsl:message select="string-join($msg)"/>
    </xsl:if>
  </xsl:function>
  
  
</xsl:stylesheet>