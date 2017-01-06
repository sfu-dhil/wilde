(:~
 : Simple text statistics for documents. Assumes the documents are 
 : very simple XHTML (just paragraphs).
 :)
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

(:~
 : Count the words in the in the collection.
 : @return Integer count of the words.
 :)
declare function stats:count-words() as xs:int {
  let $wc := 
	 for $p in collection($config:data-root)//p 
	 return count(tokenize($p, '\s'))

  return sum($wc)
};

(:~
 : Count the paragraphs in the in the collection.
 : @return Integer count of the paragraphs.
 :)
declare function stats:count-paragraphs() as xs:int {
  let $wc := 
    for $d in collection:documents()
    return count($d//p)
  return sum($wc)
};

(:~
 : Count the documents in the in the collection.
 : @return Integer count of the documents.
 :)
declare function stats:count-documents() as xs:int {
  count(collection:collection()//html)
};

(:~
 : Count the paragraphs in the in the collection which contain one or
 : more matches.
 : @return Integer count of the paragraphs with matches.
 :)
declare function stats:count-paragraphs-with-matches() as xs:int {
  let $wc := 
    for $d in collection:documents()
    return count($d//p[a])
  return sum($wc)
};

(:~
 : Count the paragraph matches in the in the collection which contain one or
 : more matches.
 : @return Integer count of the paragraph matches.
 :)
declare function stats:count-paragraph-matches() as xs:int {
  let $wc := 
    for $d in collection:documents()
    return count($d//a[@class='similarity'])
  return sum($wc) / 2
};

(:~
 : Count the documents which contain one or more document-level matches.
 : @return Integer count of the documents with matches.
 :)
declare function stats:count-documents-with-matches() as xs:int {
  count(collection:collection()//html[.//link])
};

(:~
 : Count the document-level matches in the in the collection.
 : @return Integer count of the documents with matches.
 :)
declare function stats:count-document-matches() as xs:int {
  count(collection:collection()//link)
};
