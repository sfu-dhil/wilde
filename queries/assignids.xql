xquery version "3.0";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare namespace api="http://nines.ca/exist/wilde/api";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json="http://www.json.org";

declare option output:method "json";
declare option output:media-type "text/javascript";

import module namespace console="http://exist-db.org/xquery/console";
import module namespace config="http://nines.ca/exist/wilde/config" at "../modules/config.xqm";
import module namespace collection="http://nines.ca/exist/wilde/collection" at "../modules/collection.xql";
import module namespace document="http://nines.ca/exist/wilde/document" at "../modules/document.xql";
import module namespace index="http://nines.ca/exist/wilde/index" at "../modules/index.xql";

let $collection := collection:collection()
let $paras := 
    for $p in $collection//p[not(@id)]
    let $null := update insert attribute { 'id' } { generate-id($p) } into $p
    return $p
    
return "updated " || count($paras)