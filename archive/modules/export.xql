xquery version "3.0";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace export = "http://dhil.lib.sfu.ca/exist/wilde/export";
declare namespace json = "http://www.json.org";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace xhtml = 'http://www.w3.org/1999/xhtml';

import module namespace collection = "http://dhil.lib.sfu.ca/exist/wilde/collection" at "collection.xql";
import module namespace config = "http://dhil.lib.sfu.ca/exist/wilde/config" at "config.xqm";
import module namespace csv = "http://dhil.lib.sfu.ca/exist/wilde/csv" at "csv.xql";
import module namespace document = "http://dhil.lib.sfu.ca/exist/wilde/document" at "document.xql";
import module namespace kwic = "http://exist-db.org/xquery/kwic";
import module namespace lang = "http://dhil.lib.sfu.ca/exist/wilde/lang" at "lang.xql";
import module namespace util = "http://exist-db.org/xquery/util";

declare option output:method "text";
declare option output:media-type "text/csv";

declare function export:search() {
  let $query := request:get-parameter('query', '')
  let $options := map {
    "facets": map {
      "lang": request:get-parameter('facet-lang', ()),
      "region": request:get-parameter('facet-region', ()),
      "publisher": request:get-parameter('facet-publisher', ())
    }
  }
  let $hits := collection:search($query, $options)
  let $config := <config xmlns='' width="60" table="no"/>
  
  let $headers := csv:row(('ID', 'Date', 'Publisher', 'Title', 'Region', 'City', 'Language', 'Result'))

  let $rows := for $hit in $hits
    let $did := document:id($hit)
    let $date := document:date($hit)
    let $publisher := document:publisher($hit)
    let $title := document:title($hit)
    let $region := document:region($hit)
    let $city := document:city($hit)
    let $lang := lang:code2lang(document:language($hit))
    let $kwic := kwic:summarize($hit, $config)[1]
    for $node in $kwic
    return csv:row(($did, $date, $publisher, $title, $region, $city, $lang, $kwic))
  
  let $count := csv:row("Found " || count($rows) || " results for search query " || $query || ".")
  let $filters := (
    csv:row("Filter Language=" || string-join(lang:code2lang(request:get-parameter('facet-lang', ('any'))), ' or ')),
    csv:row("Filter Region=" || string-join(request:get-parameter('facet-region', ('any')), ' or ')),
    csv:row("Filter Publisher=" || string-join(request:get-parameter('facet-publisher', ('any')), ' or '))
  )
  let $export := ($headers, $count, $filters, $rows)
  
  return csv:records($export)
};

declare function export:volume() {
  util:binary-to-string(util:binary-doc($config:data-root || "/tables/volume.csv"))
};

declare function export:matching-paragraphs() {
  util:binary-to-string(util:binary-doc($config:data-root || "/tables/paragraph-matches.csv"))
};

declare function export:matching() {
  util:binary-to-string(util:binary-doc($config:data-root || "/tables/document-matches.csv"))
};

declare function export:signatures() {
  util:binary-to-string(util:binary-doc($config:data-root || "/tables/signatures.csv"))
};

declare function export:bibliography() {
  util:binary-to-string(util:binary-doc($config:data-root || "/tables/bibliography.csv"))
};

declare function export:gephi-documents() {
  util:binary-to-string(util:binary-doc($config:data-root || "/tables/gephi-document-nodes.csv"))
};

declare function export:gephi-document-matches() {
  util:binary-to-string(util:binary-doc($config:data-root || "/tables/gephi-document-matches.csv"))
};

declare function export:gephi-papers() {
  util:binary-to-string(util:binary-doc($config:data-root || "/tables/gephi-newspaper-nodes.csv"))
};

declare function export:gephi-papers-matches() {
  util:binary-to-string(util:binary-doc($config:data-root || "/tables/gephi-newspaper-edges.csv"))
};

let $request := request:get-attribute('function')
let $functionName :=
if (ends-with($request, '.csv')) then
  substring-before($request, '.csv')
else
  $request
let $function :=
try {
  function-lookup(QName("http://dhil.lib.sfu.ca/exist/wilde/export", $functionName), 0)
} catch * {
  ()
}

return
  if (exists($function)) then
    $function()
  else
    let $null := response:set-status-code(404)
    return
      "The export function " || $functionName || " cannot be found."
