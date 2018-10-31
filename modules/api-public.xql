xquery version "3.0";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare namespace api="http://dhil.lib.sfu.ca/exist/wilde-app/api-public";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json="http://www.json.org";
declare namespace request="http://exist-db.org/xquery/request";

declare option output:method "json";
declare option output:media-type "text/javascript";

import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace config="http://dhil.lib.sfu.ca/exist/wilde-app/config" at "config.xqm";
import module namespace collection="http://dhil.lib.sfu.ca/exist/wilde-app/collection" at "collection.xql";
import module namespace document="http://dhil.lib.sfu.ca/exist/wilde-app/document" at "document.xql";
import module namespace app="http://dhil.lib.sfu.ca/exist/wilde-app/templates" at "app.xql";
import module namespace lang="http://dhil.lib.sfu.ca/exist/wilde-app/lang" at "lang.xql";

declare function api:documents() {
    let $documents := collection:documents()
    for $document in $documents
        return
            <document id="{document:id($document)}"
               title="{document:title($document)}"
               index-document="{document:indexed-document($document)}"
               index-paragraph="{document:indexed-paragraph($document)}" />
};

declare function api:graph-data() {
  let $documents := collection:documents()

  return
  <root> {
    for $document in $documents
      return
        if(count(document:similar-documents($document)) eq 0) then
          ()
        else
          <node id="{document:id($document)}" label="{document:publisher($document)}\n{document:date($document)}" group="{document:region($document)}" />
  } {
    for $link in $documents//xhtml:link[@rel='similarity']
    let $target := collection:fetch($link/@href/string())
    order by document:date($link), document:date($target), $link/@data-similarity descending
    return
        if((document:date($link) = document:date($target)) and (document:id($link) gt document:id($target))) then ()
        else if(document:date($link) gt document:date($target)) then ()
        else
          <edge from="{document:id($link)}" to="{document:id($target)}" />
  }
  </root>
};

declare function api:publishers() {
    for $publisher in collection:publishers()
    return <json:value>{$publisher}</json:value>
};

declare function api:regions() {
    for $region in collection:regions()
    return <json:value>{$region}</json:value>
};

declare function api:languages() {
    for $language in collection:languages()
    return <json:value>{lang:code2lang($language)}</json:value>
};

declare function api:cities() {
  let $file := $config:data-root || '/cities.csv'
  let $raw := util:binary-doc($file)
  let $csv := util:binary-to-string($raw)
  let $lines := tokenize($csv,'\n')
  let $head := tokenize($lines[1], ',')
  let $body := remove($lines,1)
  let $q := request:get-parameter('q', false())

  for $row in $body
    let $fields := tokenize($row, ',')
    return
      if($q and $fields[1] != $q) then
        ()
      else
        <city name="{$fields[1]}" reports="{$fields[2]}" latitude="{$fields[3]}" longitude="{$fields[4]}" />
};

declare function api:sources() {
  for $city in collection:sources()
  return <json:value>{$city}</json:value>
};

let $functionName := request:get-attribute('function')
let $function :=
    try {
        function-lookup(QName("http://dhil.lib.sfu.ca/exist/wilde-app/api-public", $functionName), 0)
    } catch * {
        ()
    }

return
if(exists($function)) then
    <root> { $function() } </root>
else
    let $null := response:set-status-code(404)
    return <error status="404">The API function {$functionName} cannot be found.</error>
