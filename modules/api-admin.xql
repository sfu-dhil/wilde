xquery version "3.0";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare namespace api="http://nines.ca/exist/wilde/api-admin";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json="http://www.json.org";

declare option output:method "json";
declare option output:media-type "text/javascript";

import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace functx='http://www.functx.com';
import module namespace config="http://nines.ca/exist/wilde/config" at "config.xqm";
import module namespace collection="http://nines.ca/exist/wilde/collection" at "collection.xql";
import module namespace document="http://nines.ca/exist/wilde/document" at "document.xql";
import module namespace index="http://nines.ca/exist/wilde/index" at "index.xql";
import module namespace app="http://nines.ca/exist/wilde/templates" at "app.xql";

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

declare function api:generate-paragraph-ids() {
  let $collection := collection:documents()
  let $count := sum(
  for $p in $collection//p[not(@id)]
      let $null := update insert attribute { 'id' } { generate-id($p) } into $p
      return 1
  )
  return <result>{$count} IDs generated.</result>
};

declare function api:delete-indexes() {
    let $collection := collection:documents()
    return (
        update delete $collection//meta[starts-with(@name, 'index.')],
        update delete $collection//link[@rel='similarity'],
        update delete $collection//a[@class='similarity'],
        <result>deleted all indexes.</result>
    )
};

declare function api:reindex-document() {
    let $f := request:get-parameter('f', '')
    let $null := console:log("reindexing document " || $f)
    let $doc := collection:fetch($f)
    return index:reindex-document($doc)
};

declare function api:reindex-paragraphs() {
    let $f := request:get-parameter('f', '')
    let $null := console:log("reindexing paragraphs in " || $f)
    let $doc := collection:fetch($f)
    return index:reindex-paragraphs($doc)
};

declare function api:save-document() {
    let $f := request:get-parameter('f', '')
    let $doc := collection:fetch($f)

    let $null := update replace $doc//title/text() with request:get-parameter('title', '')
    let $null := update value $doc//meta[@name='dc.date']/@content with request:get-parameter('date', '')
    let $null := update value $doc//meta[@name='dc.publisher']/@content with request:get-parameter('publisher', '')
    let $null := update value $doc//meta[@name='status']/@content with request:get-parameter('status', '')
    let $null := update value $doc//meta[@name='dc.region']/@content with request:get-parameter('region', '')
    let $null := update value $doc//meta[@name='wr.wordcount']/@content with -1
    let $null := update value $doc//meta[@name='dc.language']/@content with request:get-parameter('language', '')
    let $null := update value $doc//meta[@name='dc.region.city']/@content with request:get-parameter('city', '')
    let $null := update value $doc//meta[@name='dc.region']/@content with request:get-parameter('region', '')
    
    let $null := update value $doc//meta[@name='index.document']/@content with "false"
    let $null := update value $doc//meta[@name='index.paragraph']/@content with "false"

    let $content := util:parse-html(request:get-parameter('content', ''))
    let $fixed := functx:change-element-ns-deep($content, 'http://www.w3.org/1999/xhtml', '')
    let $null := update replace $doc//body with <body>{$fixed//BODY/*}</body>

    let $null := update delete $doc//link
    let $null := update delete collection:documents()//a[@data-document=$f]
    let $null := update delete collection:documents()//link[@href=$f]

    return 
      <result>success</result>
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