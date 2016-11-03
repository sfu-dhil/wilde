xquery version "3.0";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare namespace api="http://nines.ca/exist/wilde/api";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json="http://www.json.org";

declare option output:method "json";
declare option output:media-type "text/javascript";

import module namespace console="http://exist-db.org/xquery/console";
import module namespace config="http://nines.ca/exist/wilde/config" at "config.xqm";
import module namespace collection="http://nines.ca/exist/wilde/collection" at "collection.xql";
import module namespace document="http://nines.ca/exist/wilde/document" at "document.xql";
import module namespace index="http://nines.ca/exist/wilde/index" at "index.xql";

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
    let $title := request:get-parameter('title', '')
    let $publisher := request:get-parameter('publisher', '')
    let $region := request:get-parameter('region', '')
    let $date := request:get-parameter('date', '')
    let $status := request:get-parameter('status', '')
    let $content := request:get-parameter('content', '')
    
    let $result := 
        try {
            let $doc := collection:fetch($f)
            let $node := util:parse-html('<div xmlns="http://www.w3.org/1999/xhtml">' || $content || '</div>')
            
            let $actions := (
                update value $doc//title with $title,
                
                update value $doc//meta[@name='dc.date']/@content with $date,
                update value $doc//meta[@name='dc.publisher']/@content with $publisher,
                update value $doc//meta[@name='status']/@content with $status,
                update value $doc//meta[@name='dc.region']/@content with $region,
                update delete $doc//meta[@name='index.document'],
                update delete $doc//meta[@name='index.paragraph'],
                
                update delete $doc//link[@rel='similarity'],
                
                update delete $doc//body/node(),
                update insert $node//div/node() into $doc//body,
                
                update delete collection:collection()//a[@class='similarity'][@data-document=$f],
                update delete collection:collection()//link[@class='similarity'][@data-document=$f]
            )
            return "success " || string-join($actions, '/')
        } catch * {
            "failed: " || ' ' || $err:code || ' ' || ' ' || $err:description || ' ' || $err:value
        }
        
    let $null := console:log('result is ' || $result)
    return <result>{$result}</result>
};

let $functionName := request:get-attribute('function')
let $function := 
    try {
        function-lookup(QName("http://nines.ca/exist/wilde/api", $functionName), 0)
    } catch * {
        ()
    }
    
return    
if(exists($function)) then
    <root> { $function() } </root>
else
    let $null := response:set-status-code(404)
    return <error status="404">The API function {$functionName} cannot be found.</error>