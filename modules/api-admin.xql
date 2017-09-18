xquery version "3.0";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare namespace api="http://nines.ca/exist/wilde/api-admin";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json="http://www.json.org";

declare option output:method "json";
declare option output:media-type "text/javascript";

import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace functx='http://www.functx.com';
import module namespace config="http://nines.ca/exist/wilde/config" at "config.xqm";
import module namespace collection="http://nines.ca/exist/wilde/collection" at "collection.xql";
import module namespace document="http://nines.ca/exist/wilde/document" at "document.xql";
import module namespace index="http://nines.ca/exist/wilde/index" at "index.xql";
import module namespace app="http://nines.ca/exist/wilde/templates" at "app.xql";
import module namespace lang="http://nines.ca/exist/wilde/lang" at "lang.xql";
import module namespace util="http://exist-db.org/xquery/util";

declare function api:documents() {
    let $documents := collection:documents()
    for $document in $documents
        return
            <document id="{document:id($document)}" 
               title="{document:title($document)}" 
               status="{document:status($document)}" 
               index-document="{document:indexed-document($document)}"
               index-paragraph="{document:indexed-paragraph($document)}" />
};

declare function api:save-document() {
  let $docId := request:get-parameter('docId', '')
  let $doc := collection:fetch($docId)
  
  let $result := try {
    let $node := util:parse-html('<div xmlns="http://www.w3.org/1999/xhtml">' || request:get-parameter('content', '') || '</div>')  
    
    let $actions := (      
      update value $doc//title with request:get-parameter('title', ''),
      
      update value $doc//meta[@name='dc.date']/@content with request:get-parameter('date', ''),
      update value $doc//meta[@name='dc.publisher']/@content with request:get-parameter('publisher', ''),
      update value $doc//meta[@name='status']/@content with request:get-parameter('status', ''),
      update value $doc//meta[@name='dc.region']/@content with request:get-parameter('region', ''),
      update value $doc//meta[@name='wr.wordcount']/@content with '',
      update value $doc//meta[@name='dc.language']/@content with lang:lang2code(request:get-parameter('language', '')),
      update value $doc//meta[@name='dc.region.city']/@content with request:get-parameter('city', ''),
      
      if(exists($doc//meta[@name='dc.source']/@content)) then
        update value $doc//meta[@name='dc.source']/@content with request:get-parameter('source', '')
      else
        update insert <meta name='dc.source' content='{request:get-parameter('source', '')}'/> into $doc//head
      ,
      
      
      update value $doc//meta[@name='wd.translated']/@content with 'no',
      update delete $doc//div[@class='translation'],
      update delete $doc//div[@id='original']/node(),
      update insert $node//div/node() into $doc//div[@id='original'],
      
      update delete collection:collection()//a[@class='similarity'][@data-document=$docId],
      update delete collection:collection()//link[@class='similarity'][@data-document=$docId]
    )
  
    return "All changes saved."
  } catch * {
    "Error saving changes: " || $err:code || ": " || $err:description || ". Data: " || $err:value
  }
  
  return
    <result>{$result}</result>
};

let $functionName := request:get-attribute('function')
let $function := 
    try {
        function-lookup(QName("http://nines.ca/exist/wilde/api-admin", $functionName), 0)
    } catch * {
        ()
    }

return    
if(exists($function)) then
    <root> { 
        $function() 
    } </root>
else
    let $null := response:set-status-code(404)
    return <error status="404">The API function {$functionName} cannot be found.</error>