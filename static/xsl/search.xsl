<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  exclude-result-prefixes="#all"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Oct 25, 2024</xd:p>
      <xd:p><xd:b>Author:</xd:b> takeda</xd:p>
      <xd:p>Fixes up the staticSearch output</xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:mode on-no-match="shallow-copy"/>
  
  <xsl:variable name="filters" select="//div[matches(@class,'ss(Desc|Date|Num|Bool)Filters')]" as="element(div)+"/>
  <xsl:variable name="secondaryButtons" select="//span[matches(@class, '(clearButton|postFilterSearchBtn)')]" as="element(span)+"/>
  <xsl:variable name="helpRow" select="//div[@id='search_help']" as="element(div)?"/>
  
 <!-- <xsl:template match="div[@id='staticSearch']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
   
      <div class="ss-search">
        <xsl:apply-templates/>
      </div>
    </xsl:copy>
  </xsl:template>-->
  
  <xsl:template match="div[@id='staticSearch']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="form"/>
      <div class="ss-filters">
        <h3>Filters</h3>
        <div class="input-group">
          <xsl:apply-templates select="$secondaryButtons">
            <xsl:sort select="@class" order="descending"/>
          </xsl:apply-templates>
        </div>
        <xsl:apply-templates select="$filters"/>        
      </div>
      <div class="ss-content">
        <xsl:apply-templates select="div"/>
      </div>
    </xsl:copy>
    <xsl:apply-templates select="script | noscript"/>
  </xsl:template>
  
  <!--Delete initialization script, since we'll do it ourselves-->
  <xsl:template match="script[matches(@src,'ssInitialize')]"/>
  
  <xsl:template match="$helpRow"/>
  
  <xsl:template match="fieldset" priority="2">
    <details class="accordion panel panel-default">
      <summary class="panel-heading">
        <xsl:apply-templates select="legend/node()"/>
      </summary>
      <div class="accordion_content panel-body panel-facet">
        <xsl:next-match/>
      </div>
    </details>
  </xsl:template>
  
  <xsl:template match="fieldset/legend">
    <xsl:copy>
      <xsl:call-template name="atts">
        <xsl:with-param name="classes" select="'sr-only'"/>
      </xsl:call-template>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="fieldset[ancestor::div[contains-token(@class,'ssDateFilters')]]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="legend"/>
      <div class="date-range">
        <xsl:apply-templates select="span"/>
      </div>
    </xsl:copy>
    
  </xsl:template>
  
  <xsl:template match="form[@id='ssForm']">

    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="* except ($filters, $secondaryButtons)"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="span[@class='ssQueryAndButton']">
    <div class="input-group">
      <xsl:next-match/>
    </div>
    <div>
      <xsl:apply-templates select="$helpRow/@*"/>
      <xsl:apply-templates select="$helpRow/node()"/>
    </div>
  </xsl:template>
  
  <xsl:template match="button">
    <xsl:copy>
      <xsl:call-template name="atts">
        <xsl:with-param name="classes" select="('btn','btn-default')"/>
      </xsl:call-template>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="button[@id='ssDoSearch2']/text()">
    <xsl:text>Apply</xsl:text>
  </xsl:template>
  
  <xsl:template name="atts">
    <xsl:param name="classes" as="xs:string*"/>
    <xsl:apply-templates select="@*"/>
    <xsl:attribute name="class" select="((@class, $classes) ! tokenize(.,' ')) => string-join(' ')"/>
  </xsl:template>
  
  
  
  
</xsl:stylesheet>