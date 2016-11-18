xquery version "3.0";

module namespace stats="http://nines.ca/exist/wilde/stats";

import module namespace functx="http://www.functx.com"; 
import module namespace console="http://exist-db.org/xquery/console";
import module namespace math="http://exist-db.org/xquery/math";
import module namespace config="http://nines.ca/exist/wilde/config" at "config.xqm";
import module namespace collection="http://nines.ca/exist/wilde/collection" at "collection.xql";


declare namespace string="java:org.apache.commons.lang3.StringUtils";
declare namespace locale="java:java.util.Locale";
declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare default element namespace "http://www.w3.org/1999/xhtml";

(:
Total number of words: 1,053,155
x Total number of paragraphs: 9,281
x Total number of documents: 1,108
x Total number of paragraphs which match one or more other paragraphs: 3,763.
x Total number of paragraph matches:  8,733
x Total number of documents which contain a match: 334
x Total number of document matches: 1,141.
:)

declare function stats:count-words() as xs:int {
  let $wc := 
	 for $p in collection('/db/apps/wilde-data/data')//p 
	 return count(tokenize($p, '\s'))

  return sum($wc)
};

declare function stats:count-paragraphs() as xs:int {
  let $wc := 
    for $d in collection:documents()
    return count($d//p)
  return sum($wc)
};

declare function stats:count-documents() as xs:int {
  count(collection:collection()//html)
};

declare function stats:count-paragraphs-with-matches() as xs:int {
  let $wc := 
    for $d in collection:documents()
    return count($d//p[a])
  return sum($wc)
};

declare function stats:count-paragraph-matches() as xs:int {
  let $wc := 
    for $d in collection:documents()
    return count($d//a[@class='similarity'])
  return sum($wc)
};

declare function stats:count-documents-with-matches() as xs:int {
  count(collection:collection()//html[.//link])
};

declare function stats:count-document-matches() as xs:int {
  count(collection:collection()//link)
};
