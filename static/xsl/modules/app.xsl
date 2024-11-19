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
  xmlns:log="http://dhil.lib.sfu.ca/log"
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
  <xsl:mode name="translation" on-no-match="shallow-copy"/>
  
  
  
  <xsl:accumulator name="currentReport" initial-value="()">
    <xsl:accumulator-rule match="html[@id]">
      <xsl:sequence select="map:get($reports, @id)"/>
    </xsl:accumulator-rule>
  </xsl:accumulator>
  
  <xsl:variable name="getReport" 
    select="function($node) {
         let $report := $node/accumulator-before('currentReport')
         return $construct($report)
    }"/>
  
  <xsl:variable name="searchFieldsMap" select="map{
    'dc.region': 'desc',
    'dc.region.city': 'desc',
    'dc.language': 'desc',
    'dc.publisher': 'desc',
    'wr.word-count': 'num',
    'dc.date': 'date'
    }"/>
  
  
  <!--MAIN HTML TEMPLATES-->
  <xsl:template match="html[@id]" mode="app" priority="3">
      <xsl:if test="empty($docsToBuild) or matches(@id, $docsToBuild)">
        <xsl:next-match/>
      </xsl:if>
  </xsl:template>
  
  <xsl:template match="html[@id]" mode="app">
    <xsl:result-document href="{$dist.dir}/{@id}.html" method="xhtml" version="5.0">
       <xsl:sequence select="$log.debug('Building ' || current-output-uri())"/>
       <xsl:copy>
         <xsl:apply-templates select="@*|node()" mode="#current"/>
       </xsl:copy>
    </xsl:result-document>
  </xsl:template>
  
  <xsl:template match="html/head/title" mode="app">
    <xsl:variable name="title" as="element(h1)?">
      <xsl:apply-templates select="(root(.)//h1)[1]" mode="#current"/>
    </xsl:variable>
    <xsl:copy>
      <xsl:choose>
        <xsl:when test="exists($title)">
          <xsl:sequence select="string-join($title/descendant::text(),'') => normalize-space()"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="span[@id='version']" mode="app">
    <span id="version"><xsl:value-of select="$VERSION"/></span>
  </xsl:template>
  
  <xsl:template match="time[@id='revision']" mode="app">
    <a href="https://github.com/sfu-dhil/wilde/tree/{$COMMIT}">
      <time 
        datetime="{format-dateTime($now,'[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]')}">
        <xsl:value-of 
          select="format-dateTime($now, '[MNn] [D01], [Y0001]')"/>
        (<xsl:value-of select="$now"/>)
      </time>
    </a>
  </xsl:template>
  
  
  <!--Remove config:app-meta-->
  <xsl:template match="config:app-meta" mode="app">
    <xsl:variable name="report" select="accumulator-before('currentReport')" as="map(*)?"/>
    <xsl:choose>
      <xsl:when test="exists($report)">
          <xsl:apply-templates select="$report?meta" mode="meta"/>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="meta[@name]" mode="meta">
    <xsl:variable name="searchClass" select="map:get($searchFieldsMap, string(@name))" as="xs:string?"/>
    <xsl:choose>
      <xsl:when test="@name = 'wr.sortable'">
        <meta name="docSortKey" class="staticSearch_docSortKey" content="{@content}"/>
      </xsl:when>
      <xsl:when test="exists($searchClass)">
        <meta>
          <xsl:sequence select="@*"/>
          <xsl:attribute name="class" 
            select="'staticSearch_' || $searchClass"/>
        </meta>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="."/>
      </xsl:otherwise>     
    </xsl:choose>
  </xsl:template>
  
  <!--Templates matching in the app: namespace-->
  <xsl:template match="app:doc-source" priority="3" mode="app">
    <xsl:variable name="report" select="$getReport(.)" as="function(*)"/>
    <xsl:variable name="institution" select="$report('institution')"/>
    <xsl:variable name="database" select="$report('database')"/>
    <xsl:if test="$institution">
      <dd>
        <a href="source-{$sourceToSourceId($institution)}.html"><xsl:value-of select="$institution"/></a>
      </dd>
    </xsl:if>
    <xsl:if test="$database">
      <dd>
        <a href="source-{$sourceToSourceId($database)}.html"><xsl:value-of select="$database"/></a>
      </dd>
    </xsl:if>
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
  
  <xsl:template match="app:doc-translation-tabs" priority="3" mode="app">
    <xsl:variable name="report" select="$getReport(.)"/>
    <xsl:variable name="translations" select="$report('translations')" as="map(*)"/>
    <ul class="nav nav-tabs" role="tablist">
      <xsl:for-each select="dhil:map-entries($translations)">
        <li role="presentation">
          <xsl:if test=".?original">
            <xsl:attribute name="class">active</xsl:attribute>
          </xsl:if>
          <a href="#{.?id}" role="tab" data-toggle="tab">
            <b><xsl:value-of select="$code2lang(.?lang)"/></b>
          </a>
        </li>
      </xsl:for-each>
    </ul>
  </xsl:template>
  
  <xsl:template match="app:doc-translations" priority="3" mode="app">
    <xsl:variable name="report" select="$getReport(.)"/>
    <xsl:variable name="translations" select="$report('translations')" as="map(*)"/> 
    <div class="tab-content">
      <xsl:for-each select="dhil:map-entries($translations)">
        <div class="tab-pane{if (.?original) then ' active' else ()}" id="{.?id}">
          <xsl:apply-templates select=".?content" mode="translation"/>
        </div>
      </xsl:for-each>
    </div>
  </xsl:template>
  
  
  <xsl:template match="app:document-similarities" mode="app">
    <xsl:variable name="report" select="$getReport(.)"/>
    <xsl:variable name="simDocLinks" 
      select="$report('doc-similarity')"
      as="map(*)*"/>
      <div class="panel-body">
        <xsl:sequence>
          <xsl:where-populated>
            <ul>
              <xsl:for-each select="$simDocLinks">
                <xsl:sort select="xs:double(.?similarity)" order="descending"/>
                <li class="{.?type}">
                  <a href="{.?href || '.html'}">
                    <xsl:value-of select="$reports(.?href)?title"/>
                  </a>
                  <xsl:text> - </xsl:text>
                  <xsl:value-of select="format-number(xs:double(.?similarity), '###.#%')"/>
                  <!--TODO: Fix BR-->
                  <br/>
                  <a href="compare-docs.html?a={$report('id')}&amp;b={.?href}">Compare</a>
                </li>
              </xsl:for-each>
            </ul>
          </xsl:where-populated>
          <xsl:on-empty>
            <i>None found</i>
          </xsl:on-empty>
        </xsl:sequence>  
      </div>
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
  
  <xsl:template match="app:parameter[@data-template-name = 'publisher']" priority="2" mode="app">
    <xsl:next-match>
      <xsl:with-param name="name" select="'newspaper'"/>
    </xsl:next-match>
  </xsl:template>
  
  <xsl:template match="app:parameter[@data-template-name = 'language']" priority="2" mode="app">
    <xsl:param name="data" tunnel="yes"/>
    <xsl:sequence select="map:get($code2lang, map:get($data, 'language'))"/>
  </xsl:template>
  
  <xsl:template match="app:parameter" mode="app">
    <xsl:param name="data" tunnel="yes"/>
    <xsl:param name="name" select="string(@data-template-name)" as="xs:string"/>
    <xsl:sequence select="map:get($data, $name)"/>
  </xsl:template>
  
  <xsl:template match="app:breadcrumb" mode="app">
    <xsl:param name="data" tunnel="yes"/>
    <xsl:param name="template" tunnel="yes" as="map(*)"/>
    <xsl:variable name="basename" select="$template?basename" as="xs:string"/>
    <xsl:variable name="report" select="$getReport(.)"/>
    <xsl:choose>
      <!--Don't make index -->
      <xsl:when test="$basename = 'index'"/>
      <xsl:otherwise>
        <nav aria-label="breadcrumb" class="col-md-12">
          <ol class="breadcrumb">
            <li class="breadcrumb-item">
              <a href="index.html">Home</a>
            </li>
            <xsl:choose>
              <!--We're in a report-->
              <xsl:when test="$basename = 'view'">
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
              <xsl:when test="starts-with($basename, 'compare')">
                <li class="breadcrumb-item">
                  <a href="newspaper.html">Browse by Newspaper</a>
                </li>
              </xsl:when>
              <xsl:when test="ends-with($basename, '-details')">
                <xsl:variable name="type" select="substring-before($basename,'-details')"/>
                <xsl:variable name="value" select="$data($type)"/>
                <li class="breadcrumb-item">
                  <a href="{$type}.html">Browse by <xsl:value-of select="dhil:capitalize($type)"/></a>
                </li>
                <li class="breadcrumb-item active" aria-current="page">
                  <xsl:value-of select="
                    if ($type='language') then $code2lang($value) else $value"/>
                </li>
              </xsl:when>
              <xsl:when test="some $template in $templates satisfies $template?basename = ($basename || '-details')">
                <li class="breadcrumb-item active" aria-current="page">
                  Browse by <xsl:value-of select="dhil:capitalize($basename)"/>
                </li>
              </xsl:when>
              <xsl:otherwise>
                <!--<xsl:sequence select="$log.warn('Unknown breadcrumb path for ' || $template?basename)"/>-->
                <li class="breadcrumb-item active" aria-current="page">
                  <xsl:value-of select="$template?template//*:h1[1]"/>
                </li>
              </xsl:otherwise>
            </xsl:choose>
          </ol>
        </nav>
        
      </xsl:otherwise>
      
    </xsl:choose>

    
        
  </xsl:template>

  
  <!--Main browse for list-->
  
  <xsl:template match="app:browse" mode="app">
    <xsl:sequence select="dhil:report-table(dhil:map-entries($reports), ())"/>
  </xsl:template> 
  
  <!--Most of the browse lists require a special JS-->
  <!--TODO: Move this into the actual JavaScript to bundle-->
  <xsl:template match="app:*[matches(local-name(), '^browse-')]" priority="2" mode="app">
    <xsl:next-match/>
    <script src="resources/js/browse.js"></script>
  </xsl:template>
  
  <xsl:template match="app:browse-date" mode="app">
    <xsl:variable name="items" select="dhil:groupReportsBy('date')"/>
    <xsl:call-template name="browseToggle">
      <xsl:with-param name="default" select="'Date'"/>
    </xsl:call-template>
    <xsl:for-each-group select="$items" group-by="tokenize(map:get(.,'sortKey'),'-')[2]">
      <xsl:sort select="xs:integer(current-grouping-key())"/>
      <xsl:variable name="thisMonthReports" select="current-group()"/>
      <xsl:variable name="dateInfo" 
        select="dhil:getDateInfo('1895-' || current-grouping-key())" 
        as="map(*)"/>
      <div class="browse-div">
        <h2><xsl:sequence select="$dateInfo?monthName"/></h2>
        <div class="calendar offset-{$dateInfo?offset}">
          <div class="cal-header">
            <xsl:for-each select="1 to 7">
              <!--March 2020 is arbitrary insofar as it starts on a Sunday-->
              <xsl:variable name="date" 
                select="xs:date('2020-03-0' || .)" as="xs:date"/>
              <div class="cal-cell">
                <span class="month-text">
                  <xsl:value-of select="format-date($date,'[FNn]')"/>
                </span>
              </div>
            </xsl:for-each>
          </div>
          <div class="cal-body">
            <xsl:for-each select="1 to $dateInfo?lastDay">
              <xsl:variable name="dayNum" select="." as="xs:integer"/>
              <xsl:variable name="thisDate" 
                select="($dateInfo('getDay'))(.)" as="xs:date"/>
              <xsl:variable name="reports"
                select="current-group()[.?sortKey = xs:string($thisDate)]"
                as="map(*)?"/>
              <xsl:variable name="count" 
                select="if (exists($reports)) 
                then $reports?count 
                else 0"/>
              <div class="cal-cell count-{$count}" 
                data-date="{$thisDate}">
                <a href="date-{$thisDate}.html"
                  data-count="{$count}">
                  <span class="day" data-month="{$dateInfo?monthName}">
                    <xsl:sequence select="$dayNum"/>
                  </span>
                  <span class="count">
                    <xsl:sequence select="$count"/>
                  </span>
                </a>
              </div>
            </xsl:for-each>
          </div>
        </div>
      </div>
    </xsl:for-each-group>
  </xsl:template>
  
  <xsl:template match="app:browse-region" mode="app">
    <div>
      <xsl:call-template name="browseToggle">
        <xsl:with-param name="default" select="'Name'"/>
      </xsl:call-template>
      <xsl:call-template name="browseList"/>
    </div>
  </xsl:template>
  
  <xsl:template match="app:browse-city" mode="app">
    <xsl:variable name="items" select="dhil:groupReportsBy('city')"/>
    <div>
      <xsl:call-template name="browseToggle">
        <xsl:with-param name="default">City</xsl:with-param>
      </xsl:call-template>
      <xsl:for-each-group select="$items" group-by="substring(map:get(.,'sortKey'), 1, 1)">
        <xsl:sort select="current-grouping-key()"/>
        <xsl:variable name="subset" select="current-group()"/>
        <div class="browse-div alpha-browse-div">
          <h3><xsl:value-of select="upper-case(current-grouping-key())"/></h3>
          <xsl:call-template name="browseList">
            <xsl:with-param name="items" select="$subset"/>
            <xsl:with-param name="page" select="'city'"/>
            <xsl:with-param name="atts" select="map{'letter': current-grouping-key()}"/>
          </xsl:call-template>
        </div>
        
        
      </xsl:for-each-group>
    </div>
  </xsl:template>
  
  <xsl:template match="app:browse-language" mode="app">
    <div>
      <xsl:call-template name="browseToggle"/>
      <xsl:call-template name="browseList"/>
    </div>
  </xsl:template>
  
  <xsl:template match="app:browse-newspaper" mode="app">
    <xsl:variable name="items" select="dhil:groupReportsBy('newspaper')"/>
    <div>
      <xsl:call-template name="browseToggle">
        <xsl:with-param name="default">Region</xsl:with-param>
      </xsl:call-template>
      <xsl:for-each-group select="$items" group-by="
          let $firstReport := map:get(.,'reports')[1]
          return ($construct($firstReport))('region')">
        <xsl:sort select="current-grouping-key()"/>
        <xsl:variable name="subset" select="current-group()"/>
        <div class="browse-div">
          <h3><xsl:value-of select="upper-case(current-grouping-key())"/></h3>
          <xsl:call-template name="browseList">
            <xsl:with-param name="items" select="$subset"/>
            <xsl:with-param name="page" select="'newspaper'"/>
            <xsl:with-param name="atts" select="map{'region': current-grouping-key()}"/>
          </xsl:call-template>
        </div>        
      </xsl:for-each-group>  
    </div>
  </xsl:template>
 
  
  <xsl:template match="app:browse-source" mode="app">
    <div>
       <div>
         <h2>Databases</h2>
         <xsl:call-template name="browseList">
           <xsl:with-param name="items" select="dhil:groupReportsBy('database')"/>
         </xsl:call-template>
       </div>
      <div>
        <h2>Institutions</h2>
        <xsl:call-template name="browseList">
          <xsl:with-param name="items" select="dhil:groupReportsBy('institution')"/>
        </xsl:call-template>
      </div>      
    </div>
  </xsl:template>
  
  <xsl:template name="browseToggle">
    <xsl:param name="default" select="local-name() => substring-after('browse-') => dhil:capitalize()"/>
    <div class="browse-toggle">
      <label for="browse-toggle">Order by</label>
      <select name="browse-toggle" class="form-control">
        <option value="default"><xsl:value-of select="$default"/></option>
        <option value="count">Count</option>
      </select>
    </div>    
  </xsl:template>
  
  <xsl:template name="browseList">
    <xsl:param name="page" select="local-name() => substring-after('browse-')"/>
    <xsl:param name="items" select="dhil:groupReportsBy($page)"/>
    <xsl:param name="atts" select="map{}" as="map(*)?"/>
    <div class="browse-div">
      <ul class="browse-list">
        <xsl:for-each select="$items">
          <xsl:sort select=".?sortKey"/>
          <li data-count="{.?count}" data-value="{.?label}" style="--height: {.?percent * 100}%">
            <xsl:for-each select="map:keys($atts)">
              <xsl:attribute name="data-{.}" select="$atts(.)"/>
            </xsl:for-each>
            <!--TODO ADD REGION-->
            <a href="{.?id}.html">
              <span class="name"><xsl:value-of select=".?label"/></span>
              <span class="count"><xsl:value-of select=".?count"/></span>
            </a>
          </li>
        </xsl:for-each>
      </ul>
    </div>
  </xsl:template>
  
  <!--HOW THIS WORKS:
     * The goal is to determine a logarithmic ratio of proportion
     * So this first groups everything by a meta field (i.e. by language, by region) and stores that
       in a map ($groups) from which the $max (log10) can be calculated
     * From there, the map is iterated through again to determine the percentages
    -->
  
  <xsl:function name="dhil:groupReportsBy" as="map(*)+">
    <xsl:param name="field"/>
    <xsl:variable name="groups" as="map(*)">
      <xsl:map>
        <xsl:for-each-group select="dhil:map-entries($reports)" group-by="($construct(.))($field)">
          <xsl:map-entry key="current-grouping-key()" select="current-group()"/>
        </xsl:for-each-group>
      </xsl:map>
    </xsl:variable>
    <xsl:variable name="max" 
      select="max(map:keys($groups) ! count($groups(.))) 
              => math:log10()"/>
    <xsl:for-each select="map:keys($groups)">
      <xsl:variable name="key" select="."/>
      <xsl:variable name="reports" select="$groups(.)"/>
      <xsl:variable name="count" select="count($reports)"/>
      <xsl:variable name="percent" select="(math:log10($count) div $max)"/>
      <xsl:variable name="id" select="dhil:getIdForField($field, .)"/>
      <xsl:map>
        <xsl:map-entry key="'count'" select="$count"/>
        <xsl:map-entry key="'percent'" select="$percent"/>
        <xsl:map-entry key="'label'" select="$key"/>
        <xsl:map-entry key="'id'" select="$id"/>
        <xsl:map-entry key="'reports'" select="$reports"/>
        <xsl:map-entry key="'sortKey'" select="if ($field = ('newspaper')) then $id else $key"/>
      </xsl:map>
    </xsl:for-each>
  </xsl:function>
  
  
  
  
  <!--Comparison templates-->
  
  <xsl:template match="app:compare-paragraphs | app:compare-documents" priority="3"
    mode="app">
    <div class="compare-content {local-name()}">
      <xsl:next-match/>
    </div>
  </xsl:template>
  
  <xsl:template match="app:compare-paragraphs" mode="app">
    
      <div class="row compare-header">
        <div class="col-sm-4">
          <b>Original paragraph in <br/>
            <span class="compare-a"/></b>
        </div>
        <div class="col-sm-4">
          <b>Most similar paragraph from <br/>
            <span class="compare-b"/></b>
        </div>
        <div class="col-sm-4">
          <b>Highlighted Differences</b>
        </div>
      </div>
      <!--Slot for each paragraph-->
  </xsl:template>
  
  <xsl:template match="app:compare-documents" mode="app">
      <div class="compare-col" id="col1">
        <h3><span class="compare-a"/></h3>
        <div id="doc_a"></div>
      </div>
      <div class="compare-col" id="col2">
        <h3><span class="compare-b"/></h3>
        <div id="doc_b"></div>
      </div>
      <div id="col3">
        <h3>
          <span>Highlighted Differences</span>
        </h3>
        <div id="diff"></div>
      </div>
  </xsl:template>
  

  
  
  <xsl:template match="app:*[matches(local-name(),'details-')]" mode="app">
    <xsl:param name="data" tunnel="yes" as="map(*)?"/>
    <xsl:variable name="field" select="substring-after(local-name(), 'details-')"/>
    <xsl:sequence select="dhil:report-table($data?reports, $field)"/>
  </xsl:template>
  
  
  <!--Special template to handle the documentation page-->
  <xsl:template match="app:toc" mode="app">
    <xsl:where-populated>
      <ul>
        <xsl:apply-templates select="root(.)//div[@id='article']"
          mode="toc"/>
      </ul>
    </xsl:where-populated>
  </xsl:template>
  
  <xsl:template match="div[@id]" mode="toc">
    <xsl:where-populated>
      <li>
        <xsl:apply-templates select="h1 | h2 | h3 | h4 | h5 | h6 | h7" mode="#current"/>
        <xsl:where-populated>
          <ul>
            <xsl:apply-templates select="./div[@id]" mode="#current"/>
          </ul>
        </xsl:where-populated>
      </li>
    </xsl:where-populated>
  </xsl:template>
  
  <xsl:template match="div[@id]/(h1 | h2 | h3 | h4 | h5 | h6 | h7)" mode="toc">
    <a href="#{../@id}"><xsl:value-of select="."/></a>
  </xsl:template>
  
  
  <xsl:variable name="reportFields" select="('date', 'newspaper', 'region', 'city', 'language')"/>
  
  <xsl:function name="dhil:report-table">
    <xsl:param name="reports" as="map(*)*"/>
    <xsl:param name="field" as="xs:string?"/>
    <table class="table table-striped table-hover table-condensed table-{$field}" id="tbl-browser">
      <thead>
        <tr>
          <th>Headline</th>
          <xsl:for-each select="$reportFields">
            <th class="cell-{.}">
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
          <xsl:sequence select="dhil:report-row(.)"/>
        </xsl:for-each>
      </tbody>
    </table>
  </xsl:function>
  
  <xsl:function name="dhil:report-row" as="element(tr)" new-each-time="no">
    <xsl:param name="rep" as="map(*)"/>
    <xsl:variable name="report" select="$construct($rep)" as="function(*)"/>
    <tr>
      <td data-name="Headline">
        <a href="{$report('id')}.html">
          <xsl:sequence 
            select="($report('headlines')[1],$report('title'))[matches(.,'\S')][1] => string()"/>
        </a>
      </td>
      <xsl:for-each select="$reportFields">
        <xsl:variable name="currField" select="."/>
        <td class="cell-{$currField}" data-name="{dhil:capitalize($currField)}">
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
      <td class="count"><xsl:value-of select="count($report('doc-similarity'))"/></td>
      <td class="count"><xsl:value-of select="count($report('paragraph-similarity'))"/></td>
      <td class="count"><xsl:value-of select="$report('word-count')"/></td>
    </tr>
  </xsl:function>
 
  <xsl:template match="app:load" mode="app">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <!--Remove search: We'll do this with staticSearch-->
  <xsl:template match="form[@id='search-form']" mode="app">
    <div id="staticSearch"/>
  </xsl:template>
  
  
  <!--Handling for the gallery -->
  <xsl:template match="app:gallery" mode="app">
    <div class="gallery">
      <xsl:for-each select="$image.index//div[@data-filename]">
        <xsl:variable name="filename" select="normalize-space(@data-filename)"
          as="xs:string"/>
        <xsl:variable name="title" select="normalize-space(@data-title)"
          as="xs:string"/>
        <xsl:variable name="date" select="normalize-space(@data-date)"
          as="xs:string"/>
        <xsl:variable name="desc"
          as="xs:string"
          select="string-join(descendant::text()) => normalize-space()"/>
        <div class="img-tile">
          <div class="thumbnail">
            <div class="img-container">
              <a href="#imgModal" data-toggle="modal"
                data-target="#imgModal"
                data-title="{$title}" data-date="{$date}"
                data-img="images/{@data-filename}"
                class="img-thumbnail">
                <img alt="{$desc}" src="thumbs/{$filename}" class="img-thumbnail"/>
              </a>
          </div>
            <div class="caption">
              <div class="title"><i><xsl:value-of select="$title"/></i><br/><xsl:value-of select="$date"/></div>
              <xsl:apply-templates select="node()" mode="#current"/>
            </div>
          </div>
        </div>
      </xsl:for-each>
    </div>
  </xsl:template>

  
  <xsl:template match="app:*" priority="-1" mode="app">
    <xsl:sequence select="$log.debug(name() || ' unmatched')"/>
    <xsl:next-match/>
  </xsl:template>
  
  <xsl:template match="div[@id][parent::body]/@id" mode="translation"/>
  
  <xsl:template match="p" priority="3" mode="translation">
    <xsl:param name="isMatch" tunnel="yes" select="false()"/>
    <xsl:choose>
      <xsl:when test="$isMatch">
        <xsl:copy>
          <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="p" priority="2" mode="translation">
    <xsl:variable name="id" select="string(@id)" as="xs:string"/>
    <xsl:variable name="matches" select="child::*[dhil:isSimilarityLink(.)]" as="element()*"/>
    <xsl:variable name="matchCount" select="count($matches)" as="xs:integer"/>
    <div class="row matches matches-{$matchCount}">
      <div class="col-sm-3">
        <xsl:if test="exists($matches)">
          <!--TODO: Fix this!-->
          <a class="btn btn-primary"
            onclick="$(this).parent().parent().toggleClass('viewing-matches'); $('#{$id}_matches').toggle();"
            title="Show matches">
            <xsl:value-of select="$matchCount || ' ' || (if ($matchCount gt 1) then 'matches' else 'match')"/>
          </a>
        </xsl:if>
      </div>
      <div class="col-sm-8">
        <xsl:copy>
          <xsl:apply-templates
            select="@* | (node() except $matches)" mode="#current"/>
        </xsl:copy>
        <xsl:where-populated>
          <div id="{$id}_matches" class="similarity">
            <xsl:for-each-group select="$matches" group-by="@data-type">
              <xsl:if test="current-grouping-key() = 'lev'">
                <div class="panel panel-default">
                  <xsl:if test="$matchCount gt 0">
                    <div role="tabpanel" class="tab-pane" id="{$id}_{current-grouping-key()}">
                      <xsl:apply-templates select="current-group()" mode="#current">
                        <xsl:sort select="xs:double(@data-similarity)" order="descending"/>
                      </xsl:apply-templates>
                    </div>
                  </xsl:if>
                </div>
              </xsl:if>
            </xsl:for-each-group>  
          </div>
        </xsl:where-populated>
      </div>
    </div>
  </xsl:template>
  
  <xsl:template match="p/a[dhil:isSimilarityLink(.)]" priority="2" mode="translation">
    <xsl:param name="isMatch" tunnel="yes" select="false()"/>
    <xsl:if test="not($isMatch)">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="p/a[dhil:isSimilarityLink(.)]" mode="translation">
    <xsl:variable name="currDocId" select="ancestor::html/@id"/>
    <xsl:variable name="docId" select="xs:string(@data-document)"/>
    <xsl:variable name="paragraphId" select="xs:string(@data-paragraph)"/>
    <xsl:variable name="compReport"
      select="$construct($reports($docId))"/>
    <xsl:variable name="compPara" select="map:get($compReport('paragraphs'), $paragraphId)"/>
    <blockquote class="matches-found">
      <xsl:apply-templates 
        select="$compPara/node()" mode="#current">
        <xsl:with-param name="isMatch" tunnel="yes" select="true()"/>
      </xsl:apply-templates>
      <div class="comparison-links">
        <!--TODO: FIX BR-->
        <a href="{$docId}.html#{$paragraphId}">
          <xsl:sequence select="$compReport('title')"/>
        </a> (<xsl:value-of select="format-number(@data-similarity, '###.#%')"/>) <br/>
        <!--Now compare paragraph-->
        <a href="compare.html?a={$currDocId}&amp;b={$docId}">Compare Paragraphs</a>
        <xsl:text> | </xsl:text>
        <!--Compare documents-->
        <a href="compare-docs.html?a={$currDocId}&amp;b={$docId}">Compare Documents</a>
      </div>
    </blockquote>
  </xsl:template>
  
  <!--Function to return a map of relevant info for a given year
    and month-->
  <xsl:function name="dhil:getDateInfo" as="map(xs:string, item()*)">
    <xsl:param name="YYYY-MM" as="xs:string"/>
    <xsl:variable name="firstDay" as="xs:date" 
      select="xs:date($YYYY-MM || '-01')"/>    
    <xsl:map>
      <xsl:map-entry key="'monthName'" select="format-date($firstDay, '[MNn]')"/>
      <xsl:map-entry key="'offset'" select="xs:integer(format-date($firstDay, '[F0]')) + 1"/>
      <xsl:map-entry key="'lastDay'" select="($firstDay +
        xs:yearMonthDuration('P1M') -
        xs:dayTimeDuration('P1D'))
        => day-from-date()
        => xs:integer()"/>
      <xsl:map-entry key="'getDay'" select="function($day){
          let $int := xs:integer($day),
          $fint := format-integer($int, '00')
          return xs:date($YYYY-MM || '-' || $fint)
        }"/>
    </xsl:map>
  </xsl:function>
  
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