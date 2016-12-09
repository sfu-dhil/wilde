xquery version "3.0";

module namespace app="http://nines.ca/exist/wilde/templates";

import module namespace kwic="http://exist-db.org/xquery/kwic";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://nines.ca/exist/wilde/config" at "config.xqm";
import module namespace collection="http://nines.ca/exist/wilde/collection" at "collection.xql";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace document="http://nines.ca/exist/wilde/document" at "document.xql";
import module namespace similarity="http://nines.ca/exist/wilde/similarity" at "similarity.xql";
import module namespace index="http://nines.ca/exist/wilde/index" at "index.xql";
import module namespace tx="http://nines.ca/exist/wilde/transform" at "transform.xql";
import module namespace stats="http://nines.ca/exist/wilde/stats" at "stats.xql";

declare namespace string="java:org.apache.commons.lang3.StringUtils";

declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare default element namespace "http://www.w3.org/1999/xhtml";

declare function app:link-view($id as xs:string, $content) as node() {
    <a href="view.html?f={$id}">{$content}</a>
};

declare function app:browse($node as node(), $model as map(*)) as node() {
    let $documents := collection:documents()
    return
        <table class='table table-striped table-hover table-condensed' id="tbl-browser">
            <thead>
                <tr>
                    <th>Date</th><th>Publisher</th><th>Region</th><th>City</th><th>Language</th>
                    <th>Indexed</th><th>Matches</th><th>Words</th>
                </tr>
            </thead>
            <tbody>{
                for $document in $documents
                return <tr>
                    <td>{app:link-view(document:id($document), string(document:date($document)))}</td>
                    <td>{document:publisher($document)}</td>
                    <td>{document:region($document)}</td>
                    <td>{document:city($document)}</td>
                    <td>{document:language($document)}</td>
                    <td>{document:indexed-document($document)}/{document:indexed-paragraph($document)}</td>
                    <td>{count(document:document-matches($document))}/{count(document:paragraph-matches($document))}</td>
                    <td>{document:word-count($document)}</td>
                </tr>
            }</tbody>
        </table>
};

declare function app:count-documents($node as node(), $model as map(*), $name, $value) as xs:integer {
    if(empty($name) and empty($value)) then
        count(collection:documents())
    else
        count(collection:documents($name, $value))
};

declare function app:load($node as node(), $model as map(*)) {
    let $f := request:get-parameter('f', '')
    let $doc := collection:fetch($f)
    
    return map {
        "doc-id" := $f,
        "document" := $doc
    }
};

declare function app:doc-title($node as node(), $model as map(*)) as xs:string {
    document:title($model('document'))
};

declare function app:doc-subtitle($node as node(), $model as map(*)) as xs:string {
    document:subtitle($model('document'))
};

declare function app:doc-status($node as node(), $model as map(*)) as xs:string {
    document:status($model('document'))
};

declare function app:doc-next($node as node(), $model as map(*)) as node()? {
  let $next := collection:next($model('document'))  
  return 
    if($next) then
      <a href="view.html?f={document:id($next)}">{document:title($next)}</a>
    else
      text { "No next document" }
};

declare function app:doc-previous($node as node(), $model as map(*)) as node()? {
  let $previous := collection:previous($model('document'))  
  let $null := console:log("previous: " || $previous)
  return 
    if($previous) then
      <a href="view.html?f={document:id($previous)}">{document:title($previous)}</a>
    else
      text { "No previous document" }
};

declare function app:doc-word-count($node as node(), $model as map(*)) as xs:string {
    document:word-count($model('document'))
};

declare function app:doc-date($node as node(), $model as map(*)) as xs:string {
    string(document:date($model('document')))
};

declare function app:doc-publisher($node as node(), $model as map(*)) as xs:string {
    document:publisher($model('document'))
};

declare function app:doc-region($node as node(), $model as map(*)) as xs:string {
    document:region($model('document'))
};

declare function app:doc-city($ndoe as node(), $model as map(*)) as xs:string {
    document:city($model('document'))
};

declare function app:doc-modified($node as node(), $model as map(*)) as xs:string {
    string(document:modified($model('document')))
};

declare function app:doc-content($node as node(), $model as map(*)) as node()* {
    tx:document($model('document')//body/*)
};

declare function app:doc-language($node as node(), $model as map(*)) as xs:string {
    document:language($model('document'))
};

declare function app:document-indexed($node as node(), $model as map(*)) as xs:string {
    document:indexed-document($model('document'))
};

declare function app:paragraph-indexed($node as node(), $model as map(*)) as xs:string {
    document:indexed-paragraph($model('document'))
};

declare function app:document-similarities($node as node(), $model as map(*)) as node()* {
    let $similarities := document:similar-documents($model('document'))
    return
        if(count($similarities) = 0) then
            ()
        else
            <ul> {
                for $link in $similarities
                let $doc := collection:fetch($link/@href)
                return <li>{app:link-view($link/@href, document:title($doc))} ({format-number($link/@data-similarity, "###.#%")}%)</li>
            } </ul>
};

declare function app:paragraph-similarities($node as node(), $model as map(*)) as node()* {
    let $similarities := document:similar-paragraphs($model('document'))
    return
        if(count($similarities) = 0) then
            ()
        else
            <ul> {
                for $link in $similarities
                let $doc := collection:fetch($link/@data-document)
                return <li>{app:link-view($link/@data-document, document:title($doc))} ({format-number($link/@data-similarity, "###.#%")}%)</li>
            } </ul>
};

declare function app:search($node as node(), $model as map(*)) {
    let $query := request:get-parameter('query', '')
    let $page := request:get-parameter('p', 1)
    let $hits := collection:search($query)
    return map {
        'hits' := $hits,
        'query' := $query,
        'page' := $page
    }
};

declare function app:search-summary($node as node(), $model as map(*)) {
    if(empty($model('query')) or $model('query') = '') then
        ()
    else
        <p>Found {count($model('hits'))} for search query <kbd>{$model('query')}</kbd>.</p>
};

declare function app:search-paginate($node as node(), $model as map(*)) {
    let $query := $model('query')
    let $page := $model('page') cast as xs:integer
    let $span := 3
    let $hit-count := count($model('hits')) cast as xs:integer
    let $pages := xs:integer($hit-count div $config:search-results-per-page) + 1
    let $start := max((1, $page - $span))
    let $end := min(($pages, $page + $span))
    let $next := min(($pages, $page + 1))
    let $prev := max((1, $page - 1))
    
    return
        if($hit-count <= $config:search-results-per-page) then
            ()
        else
            <nav>
                <ul class='pagination'>
                    <li><a href="?query={$query}&amp;p=1">⇐</a></li>
                    <li><a href="?query={$query}&amp;p={$prev}" id='prev-page'>←</a></li> 

                    { 
                        for $pn in ($start to $end)
                        let $selected := if($page = $pn) then 'active' else '' 
                        return <li class="{$selected}"><a href="?query={$query}&amp;p={$pn}">{$pn}</a></li>
                    } 

                    <li><a href="?query={$query}&amp;p={$next}" id='next-page'>→</a></li>
                    <li><a href="?query={$query}&amp;p={$pages}">⇒</a></li>
                </ul>
            </nav>
};

declare function app:search-results($node as node(), $model as map(*)) {
    if(empty($model('query'))) then
        ()
    else
        let $page := $model('page') cast as xs:integer - 1
        let $offset := $page * $config:search-results-per-page + 1
        let $hits := subsequence($model('hits'), $offset, $config:search-results-per-page)
        
        return 
            for $hit at $p in $hits
                let $did := document:id($hit)
                let $pid := string($hit/@id)
                let $title := document:title($hit)
                let $config := <config xmlns='' width="60" table="no" 
                                link="view.html?f={$did}&amp;query={$model('query')}#{$pid}"/>
                return (<p><a href="view.html?f={$did}&amp;query={$model('query')}"><b>{$title}</b></a></p>, kwic:summarize($hit, $config))
};

declare function local:find-similar($measure as xs:string, $p as node()+, $q as node()) {
    let $matches := 
        for $t in $p 
            let $score := similarity:similarity($measure, $t, $q)
            order by $score descending
            return <div data-similarity="{$score}">{$t}</div>
    return $matches[1]
};

declare function app:compare-documents($node as node(), $model as map(*)) {
    let $a := request:get-parameter('a', '')
    let $b := request:get-parameter('b', '')
    
    let $da := collection:fetch($a)
    let $db := collection:fetch($b)
    
    let $pa := $da//p
    let $pb := $db//p
    
    return <div>
        <div class='row'>
            <div class='col-sm-4'>
                Original paragraph in <br/>
                {app:link-view($a, document:title($da))}
            </div>
            <div class='col-sm-4'>
                Most similar paragraph from <br/>
                {app:link-view($b, document:title($db))}
            </div>                
            <div class='col-sm-4'>Difference</div>
        </div> {
            for $other at $i in $pa
                let $q := local:find-similar("levenshtein", $pb, $other)
                return <div class='row paragraph-compare' data-score="{format-number($q/@data-similarity, "###.#%")}%">
                    <div class='col-sm-4 paragraph-a'>{string($other)}</div>
                    <div class='col-sm-4 paragraph-b'>{string($q)}</div>
                    <div class='col-sm-4 paragraph-d'> </div>
                </div>
            }
    </div>
};

declare function app:similarities($node as node(), $model as map(*)) {
    let $page := request:get-parameter('p', 1)
    let $similarities := collection:similarities()
    return map {
        'similarities' := $similarities,
        'page' := $page
    }
};

declare function app:similarities-summary($node as node(), $model as map(*)) {
    <p>Found {count($model('similarities'))} similarities in the collection of reports.</p>
};

declare function app:similarities-paginate($node as node(), $model as map(*)) {
    let $page := $model('page') cast as xs:integer
    let $span := 3
    let $hit-count := count($model('similarities')) cast as xs:integer
    let $pages := xs:integer($hit-count div $config:similarities-per-page) + 1
    let $start := max((1, $page - $span))
    let $end := min(($pages, $page + $span))
    let $next := min(($pages, $page + 1))
    let $prev := max((1, $page - 1))
    
    return 
        <nav>
            <ul class='pagination'>
                <li><a href="?p=1">⇐</a></li>
                <li><a href="?p={$prev}" id='prev-page'>←</a></li> 

                { 
                    for $pn in ($start to $end)
                    let $selected := if($page = $pn) then 'active' else '' 
                    return <li class="{$selected}"><a href="?p={$pn}">{$pn}</a></li>
                } 

                <li><a href="?p={$next}" id='next-page'>→</a></li>
                <li><a href="?p={$pages}">⇒</a></li>
            </ul>
        </nav>
};

declare function app:similarities-results($node as node(), $model as map(*)) {
    let $page := $model('page') cast as xs:integer - 1
    let $offset := $page * $config:search-results-per-page + 1
    
    let $hits := subsequence($model('similarities'), $offset, $config:search-results-per-page)
    
    return
        <div>
            <div class='row paragraph-compare'>
                <div class='col-sm-4'>
                    Earlier
                </div>
                <div class='col-sm-4'>
                    Later (or same date)
                </div>                
                <div class='col-sm-4'>Difference</div>
            </div> {
                for $a in $hits
                    let $pa := $a/ancestor::p
                    let $pb := collection:paragraph($a/@data-document, $a/@data-paragraph)
                    return 
                        <div> 
                            <div class='row paragraph-head'>
                                <div class='col-sm-4'>
                                {app:link-view(document:id($pa), <strong>{document:title($pa)}</strong>)}
                                </div>
                                <div class='col-sm-4'>
                                {app:link-view(document:id($pb), <strong>{document:title($pb)}</strong>)}
                                </div>
                                <div class='col-sm-4'>
                                <strong>difference</strong>
                                </div>
                            </div>
                            <div class='row paragraph-compare' data-score="{format-number($a/@data-similarity, "###.#%")}%">
                                <div class='col-sm-4 paragraph-a'>
                                    {string($pa)}
                                </div>
                                <div class='col-sm-4 paragraph-b'>
                                    {string($pb)}
                                </div>
                                <div class='col-sm-4 paragraph-d'> </div>
                            </div>
                        </div>
                }
        </div>

};

declare function app:measure($node as node(), $model as map(*)) {
    let $c1 := request:get-parameter('c1', '')
    let $c2 := request:get-parameter('c2', '')
    
    return <dl class='dl-horizontal'>
        <dt>levenshtein</dt>
        <dd>{
          if($c1 and $c2) then
            let $a := similarity:normalize($c1)
            let $b := similarity:normalize($c2)
            let $d := string:getLevenshteinDistance($a, $b)
            let $m := max((string-length($a), string-length($b)))
            return 1 - $d div $m
          else 
            ()
        } </dd>
        <dt>cosine</dt>
        <dd>{similarity:similarity("cosine", $c1, $c2)}</dd>
        <dt>jaccard</dt>
        <dd>{similarity:similarity("jaccard", $c1, $c2)}</dd>
        <dt>overlap</dt>
        <dd>{similarity:similarity("overlap", $c1, $c2)}</dd>
        <dt>compression</dt>
        <dd>{similarity:similarity("compression", $c1, $c2)}</dd>
        <dt>first</dt>
        <dd id='first'>{similarity:normalize($c1)}</dd>
        <dt>second</dt>
        <dd id='second'>{similarity:normalize($c2)}</dd>
        <dt>difference</dt>
        <dd id='difference'></dd>
    </dl>
};

declare 
    %templates:wrap
function app:measure-textarea($node as node(), $model as map(*), $name) {
    request:get-parameter($name, '')
};

declare function app:statistics($node as node(), $model as map(*)) {
    <dl>
        <dt>Word count</dt>
        <dd>{stats:count-words()}</dd>
        <dt>Paragraph count</dt>
        <dd>{stats:count-paragraphs()}</dd>
        <dt>Document count</dt>
        <dd>{stats:count-documents()}</dd>
        <dt>Paragraphs with one or more matches</dt>
        <dd>{stats:count-paragraphs-with-matches()}</dd>
        <dt>Total paragraph matches</dt>
        <dd>{stats:count-paragraph-matches()}</dd>
        <dt>Documents with one or more matches</dt>
        <dd>{stats:count-documents-with-matches()}</dd>
        <dt>Total document matches</dt>
        <dd>{stats:count-document-matches()}</dd>
    </dl>
};
