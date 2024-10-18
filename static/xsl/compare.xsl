<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  exclude-result-prefixes="#all"
  xpath-default-namespace="http://www.w3.org/1999/xhtml"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array"
  xmlns:my="bar"
  xmlns:wilde="foo"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> Mar 11, 2024</xd:p>
      <xd:p><xd:b>Author:</xd:b> takeda</xd:p>
      <xd:p>Levenshtein Comparator</xd:p>
    </xd:desc>
  </xd:doc>
  
  <xsl:param name="reports.dir"/>
  <xsl:param name="threshold" select="0.6"/>
  
  <xsl:variable name="reports" select="collection($reports.dir || '?select=*.xml;recurse=yes')"/>
  <xsl:variable name="paras" select="$reports//p" as="element(p)+"/>
  
  <xsl:variable name="TEST" select="'hello','goodbye','kitten','sitting'"/>
  
<!--  <xsl:template name="go">
    <xsl:message select="my:lev2(string-to-codepoints('gumbo'),string-to-codepoints('gambol'))"/>
  </xsl:template>-->
  
  <xsl:template name="go">
    <xsl:for-each-group select="$reports" group-by="//meta[@name='dc.language']/@content">
      <xsl:variable name="allParas" 
        select="current-group()//p[not(contains-token(@class,'heading'))][wilde:getLang(.) = current-grouping-key()]"
        as="element(p)*"/>
      <xsl:variable name="paraMap"
        select="map:merge($allParas ! map{string(./@id) : map{
        'text': wilde:normalize(.),
        'node': .
        }})"/>
      <xsl:variable name="keys" select="map:keys($paraMap)"/>
      <xsl:variable name="comparisons" select="(count($keys) * (count($keys) - 1) div 2)"/>
      <xsl:message select="'Running ' || $comparisons || ' comparisons'"/>
      <xsl:iterate select="$keys">
       <!-- <xsl:param name="seq" select="tail($keys)"/>-->
        <xsl:param name="i" select="0"/>
        <xsl:variable name="seq" select="subsequence($keys, position())"/>
        <xsl:variable name="a.id" select="."/>
        <xsl:variable name="a" select="$paraMap(.)?text"/>
        <xsl:choose>
          <xsl:when test="not(empty($seq))">
            <xsl:for-each select="$seq">
              <xsl:variable name="b.id" select="."/>
              <xsl:variable name="b" select="$paraMap($b.id)?text"/>
              <xsl:variable name="j" select="$i + position()"/>
              <xsl:message select="'[' || $j || '/' || $comparisons || '] ' || $a.id|| ' == ' || $b.id"/>
              <xsl:variable name="distance" select="my:lev2(string-to-codepoints($a), string-to-codepoints($b))"/>
              <xsl:choose>
                <xsl:when test="$distance = 2"/>
                <xsl:when test="$distance = 1 or $distance = $threshold or $distance gt $threshold">
                  <xsl:message>MATCH</xsl:message>
                </xsl:when>
                <xsl:otherwise/>
              </xsl:choose>
            </xsl:for-each>
            <xsl:next-iteration>
              <!--<xsl:with-param name="seq" select="tail($seq)"/>-->
              <xsl:with-param name="i" select="$i + count($seq)"/>
            </xsl:next-iteration>
          </xsl:when>
          <xsl:otherwise/>
        </xsl:choose>
      </xsl:iterate>
    </xsl:for-each-group>
  </xsl:template>
  
  <xsl:function name="wilde:normalize" as="xs:string" new-each-time="no">
    <xsl:param name="para"/>
    <xsl:sequence select="string-join($para) => normalize-unicode('NFKD') => lower-case() => replace('[^a-z0-9\s-]',' ') => normalize-space()"/>
  </xsl:function>
  
  <xsl:function name="wilde:getLang" as="xs:string">
    <xsl:param name="node"/>
    <xsl:value-of select="$node/ancestor-or-self::*[@lang][1]/@lang"/>
  </xsl:function>
  
  
  <xsl:function name="my:lev" as="xs:float">
    <xsl:param name="string1" as="xs:string" />
    <xsl:param name="string2" as="xs:string" />
    <xsl:variable name="str1len" select="string-length($string1)"/>
    <xsl:variable name="str2len" select="string-length($string2)"/>
    <xsl:variable name="maxLen" 
      select="max(($str1len, $str2len))" as="xs:integer"/>
    <xsl:variable name="limit" select="ceiling($maxLen * (1.0 - $threshold))"/>
    <xsl:choose>
      <xsl:when test="$string1 = ''">
        <xsl:sequence select="string-length($string2)" />
      </xsl:when>
      <xsl:when test="$string2 = ''">
        <xsl:sequence select="string-length($string1)" />
      </xsl:when>
      <xsl:when test="$string1 = $string2">
        <xsl:sequence select="1"/>
      </xsl:when>
      <xsl:when test="abs($str1len - $str2len) gt $limit">
        <xsl:sequence select="2"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="val" select="my:lev(
          string-to-codepoints($string1),
          string-to-codepoints($string2),
          string-length($string1),
          string-length($string2),
          (1, 0, 1),
          2)" />
        <xsl:sequence select="1 - ($val div max(($str1len, $str2len)))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!--Assume s1 and s2 are sorted -->
  <xsl:function name="my:lev2" as="xs:integer*">
    <xsl:param name="s" as="xs:integer*"/>
    <xsl:param name="t" as="xs:integer*"/>
    
    <!--	Set n to be the length of s. ("GUMBO")-->
    <xsl:variable name="n" select="count($s)"/>
    <!-- Set m to be the length of t. ("GAMBOL") -->
    <xsl:variable name="m" select="count($t)"/>
    <xsl:variable name="max" select="max(($n,$m))"/>
    
    <!--So I need to remember the previous COLUMN
      and then current results -->
    <xsl:iterate select="2 to $n + 1">
      <xsl:param name="v0" select="array{0 to $m}" as="array(*)"/>
      <xsl:on-completion>
        <xsl:sequence select="array:flatten($v0)[last()]"/>
      </xsl:on-completion>
      <!--<xsl:message select="serialize($v0)"/>-->
      <xsl:variable name="i" select="."/>
      <xsl:next-iteration>
        <xsl:with-param name="v0" as="array(*)">
          <xsl:iterate select="2 to $m">
            <xsl:param name="v1" select="array{0 to $m}" as="array(*)"/>
            <xsl:on-completion select="$v1"/>
            <xsl:variable name="j" select="."/>
            <xsl:variable name="cost" select="if ($s[$i - 1] = $t[$j - 1]) then 0 else 1"/>
            <xsl:variable name="above" select="$v1($j - 1) + 1"/>
            <xsl:variable name="left" select="$v0($j - 1) + 1"/>
            <xsl:variable name="diagonal" select="$v0($j - 1) + $cost"/>
            <xsl:variable name="val" select="min(($above, $left, $diagonal))"/>
            <!--<xsl:message select="'$i: ' || $i || '; $j: ' || $j || '$above: ' || $above || '; $left: ' || $left ||';  $diagonal: ' || $diagonal || '; $val: ' || $val"/>-->
            <xsl:next-iteration>
              <xsl:with-param name="v1" as="array(*)" select="array:put($v1, $j, $val)"/>
            </xsl:next-iteration>
          </xsl:iterate>
        </xsl:with-param>
      </xsl:next-iteration>
      
      
    </xsl:iterate>
    
  </xsl:function>
  
  <xsl:function name="my:lev" as="xs:integer">
    <xsl:param name="chars1" as="xs:integer*" />
    <xsl:param name="chars2" as="xs:integer*" />
    <xsl:param name="length1" as="xs:integer" />
    <xsl:param name="length2" as="xs:integer" />
    <xsl:param name="lastDiag" as="xs:integer*" />
    <xsl:param name="total" as="xs:integer" />
    <xsl:variable name="shift" as="xs:integer" 
      select="if ($total > $length2) then ($total - ($length2 + 1)) else 0" />
    <xsl:variable name="diag" as="xs:integer*">
      <xsl:for-each select="max((0, $total - $length2)) to 
        min(($total, $length1))">
        <xsl:variable name="i" as="xs:integer" select="." />
        <xsl:variable name="j" as="xs:integer" select="$total - $i" />
        <xsl:variable name="d" as="xs:integer" select="($i - $shift) * 2" />
        <xsl:if test="$j &lt; $length2">
          <xsl:sequence select="$lastDiag[$d - 1]" />
        </xsl:if>
        <xsl:choose>
          <xsl:when test="$i = 0">
            <xsl:sequence select="$j" />
          </xsl:when>
          <xsl:when test="$j = 0">
            <xsl:sequence select="$i" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence 
              select="min(($lastDiag[$d - 1] + 1,
              $lastDiag[$d + 1] + 1,
              $lastDiag[$d] +
              (if ($chars1[$i] eq $chars2[$j]) then 0 else 1)))" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$total = $length1 + $length2">
        <xsl:sequence select="exactly-one($diag)" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="my:lev(
          $chars1, $chars2, 
          $length1, $length2, 
          $diag, $total + 1)" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  
</xsl:stylesheet>