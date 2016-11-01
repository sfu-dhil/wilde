xquery version "3.0";

declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare namespace export="http://nines.ca/exist/wilde/export";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json="http://www.json.org";

declare option output:method "text";
declare option output:media-type "text/csv";

import module namespace console="http://exist-db.org/xquery/console";
import module namespace config="http://nines.ca/exist/wilde/config" at "config.xqm";
import module namespace collection="http://nines.ca/exist/wilde/collection" at "collection.xql";
import module namespace document="http://nines.ca/exist/wilde/document" at "document.xql";
import module namespace index="http://nines.ca/exist/wilde/index" at "index.xql";

declare function export:volume() {
    let $headers := 
        <row>
            <item>Id</item>
            <item>Date</item>
            <item>Word count</item>
            <item>Document matches</item>
            <item>Paragraph matches</item>
            <item>Newspaper Title</item>
            <item>Region</item>
            <item>City</item>
            <item>Language</item>
            <item>Status</item>
        </row>

    let $body := for $document in collection:documents()
    return
        <row>
            <item>{document:id($document)}</item>
            <item>{document:date($document)}</item>
            <item>{document:word-count($document)}</item>
            <item>{count(document:document-matches($document))}</item>
            <item>{count(document:paragraph-matches($document))}</item>
            <item>{document:publisher($document)}</item>
            <item>{document:region($document)}</item>
            <item>{document:city($document)}</item>
            <item>{document:language($document)}</item>
            <item>{document:status($document)}</item>
        </row>
        
    return ($headers, $body)
};

declare function export:matching-paragraphs() {
    let $headers := 
        <row>
            <item>Source Id</item>
            <item>Source date</item>
            <item>Source paper</item>
            <item>Source region</item>
            <item>Source city</item>
            <item>Source language</item>
            <item>Target Id</item>
            <item>Target date</item>
            <item>Target paper</item>
            <item>Target region</item>
            <item>Target city</item>
            <item>Target language</item>
            <item>Match</item>
        </row>
    
    let $documents := collection:documents()
    let $body := 
        for $link in $documents//xhtml:a[@class='similarity']
        let $target := collection:fetch($link/@data-document/string())
        order by document:date($link), document:date($target), $link/@data-similarity descending
        return
            if((document:date($link) = document:date($target)) and (document:id($link) gt document:id($target))) then ()
            else if(document:date($link) gt document:date($target)) then ()
            else
        <row>
            <item>{document:id($link)}</item>
            <item>{document:date($link)}</item>
            <item>{document:publisher($link)}</item>
            <item>{document:region($link)}</item>
            <item>{document:city($link)}</item>
            <item>{document:language($link)}</item>
            <item>{document:id($target)}</item>
            <item>{document:date($target)}</item>
            <item>{document:publisher($target)}</item>
            <item>{document:region($target)}</item>
            <item>{document:city($target)}</item>
            <item>{document:language($target)}</item>
            <item>{$link/@data-similarity/string()}</item>
        </row>
        
    return ($headers, $body)
};

declare function export:matching() {
    let $headers := 
        <row>
            <item>Source Id</item>
            <item>Source date</item>
            <item>Source paper</item>
            <item>Source region</item>
            <item>Target Id</item>
            <item>Target date</item>
            <item>Target paper</item>
            <item>Target region</item>
            <item>Match</item>
        </row>
    
    let $documents := collection:documents()
    let $body := 
        for $link in $documents//xhtml:link[@rel='similarity']
        let $target := collection:fetch($link/@href/string())
        order by document:date($link), document:date($target), $link/@data-similarity descending
        return
            if((document:date($link) = document:date($target)) and (document:id($link) gt document:id($target))) then ()
            else if(document:date($link) gt document:date($target)) then ()
            else
        <row>
            <item>{document:id($link)}</item>
            <item>{document:date($link)}</item>
            <item>{document:publisher($link)}</item>
            <item>{document:region($link)}</item>
            <item>{document:id($target)}</item>
            <item>{document:date($target)}</item>
            <item>{document:publisher($target)}</item>
            <item>{document:region($target)}</item>
            <item>{$link/@data-similarity/string()}</item>
        </row>
        
    return ($headers, $body)
};

declare function local:quote($str) {
  '"' || $str || '"'
};

declare function local:rows2csv($rows) {
    for $row in $rows
      let $items := for $item in $row/item
        return local:quote(normalize-space($item/text()))
      return string-join($items, ',') || codepoints-to-string(10)
};

let $functionName := request:get-attribute('function')
let $function := 
    try {
        function-lookup(QName("http://nines.ca/exist/wilde/export", $functionName), 0)
    } catch * {
        ()
    }
    
return    
if(exists($function)) then
    let $rows := $function()
    return local:rows2csv($rows)
else
    let $null := response:set-status-code(404)
    return "The export function " || $functionName || " cannot be found."
