xquery version "3.0";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace export="http://dhil.lib.sfu.ca/exist/wilde-app/export";
declare namespace json="http://www.json.org";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace xhtml='http://www.w3.org/1999/xhtml';

import module namespace collection="http://dhil.lib.sfu.ca/exist/wilde-app/collection" at "collection.xql";
import module namespace config="http://dhil.lib.sfu.ca/exist/wilde-app/config" at "config.xqm";
import module namespace document="http://dhil.lib.sfu.ca/exist/wilde-app/document" at "document.xql";
import module namespace kwic="http://exist-db.org/xquery/kwic";
import module namespace lang="http://dhil.lib.sfu.ca/exist/wilde-app/lang" at "lang.xql";
import module namespace util="http://exist-db.org/xquery/util";

declare option output:method "text";
declare option output:media-type "text/csv";

declare function export:search() {
    let $query := request:get-parameter('query', '')
    let $page := request:get-parameter('p', 1)
    let $hits := collection:search($query)

    let $headers := (
      <row>
          <item>ID</item>
          <item>Title</item>
          <item>Result</item>
        </row>,
        <row>
          <item>Found {count($hits)} results for search query {$query}.</item>
        </row>
    )

    let $body := for $hit in $hits
        let $did := document:id($hit)
        let $title := document:title($hit)
        let $config := <config xmlns='' width="60" table="no" />
        let $kwic := kwic:summarize($hit, $config)
        for $node in $kwic
            return
                <row>
                    <item>{$did}</item>
                    <item>{$title}</item>
                    <item>{$node//text()}</item>
                </row>

    return ($headers, $body)
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
    util:binary-to-string(util:binary-doc($config:data-root || "/tables/gephi-document-edges.csv"))
};

declare function export:gephi-papers() {
    util:binary-to-string(util:binary-doc($config:data-root || "/tables/gephi-newspaper-nodes.csv"))
};

declare function export:gephi-papers-matches() {
    util:binary-to-string(util:binary-doc($config:data-root || "/tables/gephi-newspaper-edges.csv"))
};

let $request := request:get-attribute('function')
let $functionName :=
    if(ends-with($request, '.csv')) then 
        substring-before($request, '.csv')
    else 
        $request
let $function :=
    try {
        function-lookup(QName("http://dhil.lib.sfu.ca/exist/wilde-app/export", $functionName), 0)
    } catch * {
        ()
    }

return
if(exists($function)) then
    $function()
else
    let $null := response:set-status-code(404)
    return "The export function " || $functionName || " cannot be found."
