<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:log="http://dhil.lib.sfu.ca/log"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Jun 19, 2023</xd:p>
      <xd:p><xd:b>Author:</xd:b> takeda</xd:p>
      <xd:p></xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:variable name="logLevels"  
    as="xs:string+" 
    visibility="private" 
    select="'NONE', 'FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE', 'ALL'"/>
  <xsl:variable name="logInt" select="log:toInt($log)" as="xs:integer"/>
  <xsl:variable name="log.error" select="$logger('error')" visibility="final"/>
  <xsl:variable name="log.warn" select="$logger('warn')" visibility="final"/>
  <xsl:variable name="log.info" select="$logger('info')" visibility="final"/>
  <xsl:variable name="log.debug" select="$logger('debug')" visibility="final"/>
  
  <xsl:variable name="logger" visibility="private" 
  select="function($thisLoggerLevel){
    let $thisLoggerLevelInt := log:toInt($thisLoggerLevel)
      return
        if ($thisLoggerLevelInt gt $logInt)
        then
          function($msg){
            (: Do nothing :)
          }
        else
          function($msg){
            log:log($msg, $thisLoggerLevelInt)
          }
    }"/>
  
  
  <xsl:function name="log:log" visibility="private">
    <xsl:param name="msg" as="item()*"/>
    <xsl:param name="level" as="xs:integer"/>
    <xsl:variable name="output" 
      select="'[' || log:toStr($level) || '] ' || string-join($msg) => normalize-space()"/>
    <xsl:choose>
      <xsl:when test="$level lt (log:toInt('ERROR') + 1)">
        <xsl:message select="$output"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message select="$output"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  
  <xsl:function name="log:toStr" visibility="private">
    <xsl:param name="int" as="item()?"/>
    <xsl:choose>
      <xsl:when test="empty($int)">
        <xsl:message terminate="yes">ERROR: No parameter defined for
          log:toStr</xsl:message>
      </xsl:when>
      <xsl:when test="$int castable as xs:integer and $int lt count($logLevels)">
        <xsl:sequence select="$logLevels[$int]"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="log:toInt($int)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="log:toInt" visibility="private">
    <xsl:param name="str" as="item()"/>
    <xsl:choose>
      <xsl:when test="$str castable as xs:integer">
        <xsl:choose>
          <xsl:when test="xs:integer($str) lt count($logLevels)">
            <xsl:sequence select="xs:integer($str)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message terminate="yes">ERROR (log:toInt):
              <xsl:value-of select="$str"/> out of bounds.
            </xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="norm" 
          select="upper-case($str) => normalize-space()"/>
        <xsl:variable name="idx" 
          select="index-of($logLevels, $norm)" as="xs:integer"/>
        <xsl:choose>
          <xsl:when test="empty($idx)">
            <xsl:message terminate="yes">ERROR: Log level <xsl:value-of select="$str"/> undefined.</xsl:message>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="$idx"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>