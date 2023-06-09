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
  
  <xd:doc>
    <xd:desc>
      <xd:ref name="self" type="variable">$self</xd:ref>
      <xd:p>The current XSLT (as document-node), which is necessary
        for resolving functions into QNames (see
        <xd:ref name="dhil:resolveQName" type="function"/>).</xd:p>
    </xd:desc>
  </xd:doc>
  <xsl:variable name="self" select="document(static-base-uri())" as="document-node()"/>
  
  
  
  <xsl:mode name="templates" on-no-match="shallow-copy"/>
  <xsl:mode name="surround" on-no-match="shallow-copy"/>
  
  <xsl:template name="templates:surround">
    <xsl:param name="doc" select="." as="document-node()"/>
    <xsl:message>Processing <xsl:value-of select="document-uri($doc)"/></xsl:message>
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
    <xsl:variable name="uri" select="resolve-uri($template,document-uri(root(.)))"/>
    <xsl:variable name="doc" select="document($uri)" as="document-node()"/>
    <xsl:variable name="at" select="@data-template-at" as="xs:string"/>
    <xsl:apply-templates select="$doc/*" mode="surround">
      <xsl:with-param name="include" as="element()" select="." tunnel="yes"/>
      <xsl:with-param name="at" select="$at" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <!--We construct a new element using the QName from the template,
    so that it is easily usable later on-->
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
  
  
  <!--
  
  <xd:doc>
    <xd:desc>
      <xd:p>Main template for matching any of the data-templates from eXist. This processes
        the template and investigates whether a function exists with that name (with cardinality
        of 0-2).</xd:p>
    </xd:desc>
    <xd:param name="data">The poem or object data, if specified. Otherwise, false.</xd:param>
    <xd:param name="content">The *content* that is being processed; in most cases, this means
      the fragment, not the outer HTML that is meant to surround it.</xd:param>
    <xd:param name="template">THe template name being called.</xd:param>
  </xd:doc>
  <xsl:template match="*[@data-template]" priority="2" mode="templates">
    <xsl:param name="data" tunnel="yes" as="item()*" select="false()"/>
    <xsl:param name="content" tunnel="yes" as="element()?"/>
    <xsl:param name="template" select="string(@data-template)" as="xs:string"/>
    <xsl:variable name="self" select="." as="element()"/>
    <xsl:variable name="QName" select="dhil:QName($template)" as="xs:QName"/>
    <xsl:sequence select="dhil:debug('Processing ' || $template)"/>
    <xsl:choose>
      <xsl:when test="function-available($template, 0)">
        <xsl:sequence select="apply(function-lookup($QName, 0), [])"/>
      </xsl:when>
      <xsl:when test="function-available($template, 1)">
        <xsl:sequence select="apply(function-lookup($QName, 1), 
          [if ($data) then $data else if (exists($content)) then $content else $self])"/>
      </xsl:when>
      <xsl:when test="function-available($template, 2)">
        <xsl:sequence select="apply(function-lookup($QName,2),[$self, $data])"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">Unknown function: <xsl:value-of select="$template"/></xsl:message>
        <xsl:sequence select="dhil:debug('No ' || $template)"/>
        <xsl:apply-templates select="$self/node()" mode="#current"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  
  <xd:doc>
    <xd:desc>
      <xd:p>Template for matching the spot in a template at which to inject
        a specified fragment. For instance, if resources/poem/view.html might use
        something like:
        <xd:pre>
                &lt;div
                    data-template="templates:surround" 
                    data-template-with="templates/base.html"
                    data-template-at="foo"&gt;
                    <!-\-Other stuff-\->
                &lt;/div&gt;
            </xd:pre>
        That node is first matched by the template above and then calls the function
        <xd:ref name="templates:surround" type="function"/>, which processes 
        the template (templates/base.html) and then injects the content 
        at an element with an id='foo'.
      </xd:p>
    </xd:desc>
    <xd:param name="at">The id at which $content should be injected</xd:param>
    <xd:param name="content">The content to be injected at this point.</xd:param>
  </xd:doc>
  <xsl:template match="*[@id]" priority="1" mode="templates">
    <xsl:param name="at" as="xs:string?" tunnel="yes" select="()"/>
    <xsl:param name="content" as="element()?" tunnel="yes" select="()"/>
    <xsl:choose>
      <xsl:when test="$at = string(@id)">
        <xsl:copy>
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:apply-templates select="$content/node()" mode="html"/>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>
      <xd:ref name="dhil:QName" type="function"/>
      <xd:p>Resolved a string as a QName using the namespace
        declarations from *this* stylesheet.</xd:p>
    </xd:desc>
    <xd:param name="string">The string name (in standard ns:name syntax)
      to be resolved as a QName.</xd:param>
  </xd:doc>
  <xsl:function name="dhil:QName" as="xs:QName" new-each-time="no">
    <xsl:param name="string" as="xs:string"/>
    <xsl:sequence select="resolve-QName($string, $self/xsl:stylesheet)"/>
  </xsl:function>
  
  
  <xd:doc>
    <xd:desc>
      <xd:ref name="dhil:identity#2" type="function"/>
      <xd:p>There are multiple functions that are called in eXist-db
        that are not necessary in this XSLT implementation. For instance,
        the templates here contain template invocations to load
        and subsequently pass requested data (which is done
        using tunnelled parameters here). Rather than silently
        ignore these templates, the dhil:identity function is
        called explicitly from functions that are unused and
        thus can be processed silently.</xd:p>
    </xd:desc>
    <xd:param name="content">The element whose content should be processed</xd:param>
    <xd:param name="data">The data (unused, but passed as a parameter)</xd:param>
  </xd:doc>
  <xsl:function name="dhil:identity">
    <xsl:param name="content"/>
    <xsl:param name="data"/>
    <xsl:apply-templates select="$content/node()" mode="html">
      <xsl:with-param name="data" select="$data" tunnel="yes" as="item()*"/>
    </xsl:apply-templates>
  </xsl:function>
  
  <xd:doc>
    <xd:desc>
      <xd:ref name="dhil:identity#3" type="function"/>
      <xd:p>Three parameter version of dhil:identity#2, 
        which replicates the %wrapped% instruction in eXist-db
        by retaining the calling element.</xd:p>
    </xd:desc>
    <xd:param name="content">The source content to be processed</xd:param>
    <xd:param name="data">The data (unused, but passed as parameter)</xd:param>
    <xd:param name="retain">A retention parameter to differentiate from dhil:identity#2</xd:param>
  </xd:doc>
  <xsl:function name="dhil:identity">
    <xsl:param name="content"/>
    <xsl:param name="data"/>
    <xsl:param name="retain" as="xs:boolean"/>
    <xsl:element name="{$content/local-name()}">
      <xsl:sequence select="$content/@*"/>
      <xsl:sequence select="dhil:identity($content, $data)"/>
    </xsl:element>
  </xsl:function>-->
  
  
</xsl:stylesheet>