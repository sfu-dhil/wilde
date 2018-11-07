xquery version "3.0";

module namespace app="http://dhil.lib.sfu.ca/exist/wilde-app/templates";

import module namespace kwic="http://exist-db.org/xquery/kwic";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://dhil.lib.sfu.ca/exist/wilde-app/config" at "config.xqm";
import module namespace collection="http://dhil.lib.sfu.ca/exist/wilde-app/collection" at "collection.xql";
import module namespace document="http://dhil.lib.sfu.ca/exist/wilde-app/document" at "document.xql";
import module namespace similarity="http://dhil.lib.sfu.ca/exist/wilde-app/similarity" at "similarity.xql";
import module namespace tx="http://dhil.lib.sfu.ca/exist/wilde-app/transform" at "transform.xql";
import module namespace stats="http://dhil.lib.sfu.ca/exist/wilde-app/stats" at "stats.xql";
import module namespace lang="http://dhil.lib.sfu.ca/exist/wilde-app/lang" at "lang.xql";
import module namespace graph="http://dhil.lib.sfu.ca/exist/wilde-app/graph" at "graph.xql";

declare namespace wilde="http://dhil.lib.sfu.ca/wilde";
declare namespace string="java:org.apache.commons.lang3.StringUtils";
declare namespace array="http://www.w3.org/2005/xpath-functions/array";

declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare default element namespace "http://www.w3.org/1999/xhtml";

declare function app:link-view($id as xs:string, $content) as node() {
    <a href="view.html?f={$id}">{$content}</a>
};

declare function app:browse($node as node(), $model as map(*)) as node() {
    let $documents := collection:documents()
    return
        <table class='table table-striped table-hover table-condensed' id="tbl-browser" data-toggle="table" data-filter-control="true" data-filter-show-clear="true" data-search="true" data-show-export="true" data-click-to-select="true" data-total-field='total'>
            <thead>
                <tr>
                    <th></th>
                    <th data-field="date" data-filter-control="select" data-sortable="true">Date</th>
                    <th data-field="newspaper" data-filter-control="select" data-sortable="true">Newspaper</th>
                    <th data-field="region" data-filter-control="select" data-sortable="true">Region</th>
                    <th data-field="city" data-filter-control="select" data-sortable="true">City</th>
                    <th data-field="language" data-filter-control="select" data-sortable="true">Language</th>
                    <th data-field="document-matches" data-sortable="true">Document Matches</th>
                    <th data-field="paragraph-matches" data-sortable="true">Paragraph Matches</th>
                    <th data-field="words" data-sortable="true">Words</th>
                </tr>
            </thead>
            <tbody>{
                for $document in $documents
                return <tr>
                    <td>{app:link-view(document:id($document)), 'View')}</td>
                    <td>{document:date($document)}</td>
                    <td>{document:publisher($document)}</td>
                    <td>{document:region($document)}</td>
                    <td>{document:city($document)}</td>
                    <td>{lang:code2lang(document:language($document))}</td>
                    <td>{count(document:document-matches($document))}</td>
                    <td>{count(document:paragraph-matches($document))}</td>
                    <td>{document:word-count($document)}</td>
                </tr>
            }</tbody>
        </table>
};

declare function local:count($list, $item) as xs:integer {
  let $matches := for $i in $list
    return if($item = $i) then 1 else 0
  return sum($matches)
};

declare function app:browse-date($node as node(), $model as map(*)) as node() {
  let $collection := collection:documents()
  let $date := request:get-parameter('date', false())
  return
    if($date) then
      let $docs := collection:documents('dc.date', $date)
      return <ul> {
        for $document in $docs
        order by document:publisher($document)
        return <li>{app:link-view(document:id($document), document:title($document))} ({document:language($document)})</li>
      } </ul>
    else
      let $dates := $collection//xhtml:meta[@name="dc.date"]/@content
      let $languages := distinct-values($collection//xhtml:meta[@name="dc.language"]/@content)
      return
        <ul data-languages="{string-join($languages, ',')}" id='languages'> {
            for $date in distinct-values($dates)
            let $dateCount := count($dates[ . = $date ])
            order by $date
            return
              <li> {
                attribute data-date { $date },
                attribute data-count { $dateCount },
                for $language in $languages
                return attribute
                  { "data-" || $language }
                  { count($collection//xhtml:head[./xhtml:meta[@name='dc.date'][@content=$date]][./xhtml:meta[@name='dc.language'][@content=$language]]) }
              }
                <a href="?date={$date}">{$date}</a>: { $dateCount }
              </li>
        } </ul>
};

declare function app:browse-newspaper($node as node(), $model as map(*)) as node() {
  let $collection := collection:documents()
  let $publisher := request:get-parameter('publisher', false())
  return
    if($publisher) then
      let $docs := collection:documents('dc.publisher', $publisher)
      return <ul> {
        for $document in $docs
        order by document:date($document)
        return <li>{app:link-view(document:id($document), document:title($document))}</li>
      } </ul>
    else
      let $publishers := $collection//xhtml:meta[@name="dc.publisher"]/@content
      return
        <table class='table table-striped table-hover table-condensed' id="tbl-browser">
            <thead>
                <tr>
                   <th>Newspaper</th>
                   <th>Region</th>
                   <th>City</th>
                   <th>Language</th>
                   <th>Count</th>
                </tr>
            </thead>
            <tbody>{
              for $publisher in distinct-values($publishers)
              order by $publisher
                return <tr>
                    <td><a href="?publisher={$publisher}">{$publisher}</a></td>
                    <td>{ collection:regions($publisher) }</td>
                    <td>{ collection:cities($publisher) }</td>
                    <td>{
                      string-join(lang:code2lang(collection:languages($publisher)), ', ')
                    }</td>
                    <td>{ local:count($publishers, $publisher) }</td>
                </tr>
            }</tbody>
        </table>
};

declare function app:browse-language($node as node(), $model as map(*)) as node() {
  let $collection := collection:documents()
  let $language := request:get-parameter('language', false())
  return
    if($language) then
      let $docs := collection:documents('dc.language', $language)
      return <ul> {
        for $document in $docs
        order by document:title($document)
        return <li>{app:link-view(document:id($document), document:title($document))}</li>
      } </ul>
    else
      let $languages := $collection//xhtml:meta[@name="dc.language"]/@content
      return
        <ul> {
          for $language in distinct-values($languages)
          let $count := local:count($languages, $language)
          order by $language
          return <li data-language="{lang:code2lang($language)}" data-count="{$count}">
              <a href="?language={$language}">{lang:code2lang($language)}</a>:
              {$count}
            </li>
        } </ul>
};

declare function app:browse-origin($node as node(), $model as map(*)) as node() {
  let $collection := collection:documents()
  let $name := request:get-parameter('name', 'dc.source')
  let $origin := request:get-parameter('origin', 'none')
  return
    if($origin ne 'none') then
      let $docs := collection:documents($name, $origin)
      return <ul> {
        for $document in $docs
        order by document:publisher($document), document:date($document)
        return <li>{app:link-view(document:id($document), document:title($document))}</li>
      } </ul>
    else
      <div class='row'>
          <div class='col-sm-6'>
            <h3>Source Database</h3>
          <ul> {
            let $origins := $collection//xhtml:meta[@name="dc.source.database"]/@content
            for $origin in distinct-values($origins)
            let $count := local:count($origins, $origin)
            order by $origin
            return <li data-source="{$origin}">
                <a href="?origin={$origin}&amp;name=dc.source.database">{
                  if(string-length($origin) gt 1) then $origin else '(unknown)'
                }</a>:
                {$count}
              </li>
          } </ul>
          </div>
          <div class='col-sm-6'>
            <h3>Source Institution</h3>
          <ul> {
            let $origins := $collection//xhtml:meta[@name="dc.source.institution"]/@content
            for $origin in distinct-values($origins)
            let $count := local:count($origins, $origin)
            order by $origin
            return <li data-source="{$origin}">
                <a href="?origin={$origin}&amp;name=dc.source.institution">{
                  if(string-length($origin) gt 1) then $origin else '(unknown)'
                }</a>:
                {$count}
              </li>
          } </ul>
          </div>
      </div>
};

declare function app:browse-region($node as node(), $model as map(*)) as node() {
  let $collection := collection:documents()
  let $region := request:get-parameter('region', false())
  return
    if($region) then
      let $docs := collection:documents('dc.region', $region)
      return <ul> {
        for $document in $docs
        order by document:title($document)
        return <li>{app:link-view(document:id($document), document:title($document))}</li>
      } </ul>
    else
      let $regions := $collection//xhtml:meta[@name="dc.region"]/@content
      return
        <ul> {
          for $region in distinct-values($regions)
          let $count := local:count($regions, $region)
          order by $region
          return <li data-region="{$region}" data-count="{$count}">
              <a href="?region={$region}">{$region}</a>:
              {$count}
            </li>
        } </ul>
};

declare function app:browse-city($node as node(), $model as map(*)) as node() {
  let $collection := collection:documents()
  let $city := request:get-parameter('city', false())
  return
    if($city) then
      let $docs := collection:documents('dc.region.city', $city)
      return <ul> {
        for $document in $docs
        order by document:title($document)
        return <li>{app:link-view(document:id($document), document:title($document))}</li>
      } </ul>
    else
      let $cities := $collection//xhtml:meta[@name="dc.region.city"]/@content
      return
        <ul> {
          for $city in distinct-values($cities)
          let $count := local:count($cities, $city)
          order by $city
          return <li data-city="{$city}" data-count="{$count}">
              <a href="?city={$city}">{$city}</a>:
              {$count}
            </li>
        } </ul>
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

declare function app:doc-edition($node as node(), $model as map(*)) as xs:string {
  let $edition := document:edition($model('document'))
  return if(string-length($edition) gt 0) then " - " || document:edition($model('document')) else ""
};

declare function app:doc-region($node as node(), $model as map(*)) as xs:string {
    document:region($model('document'))
};

declare function app:doc-city($ndoe as node(), $model as map(*)) as xs:string {
    document:city($model('document'))
};

declare function app:doc-translation-tabs($node as node(), $model as map(*)) as node()* {
  <ul class="nav nav-tabs" role="tablist">
    <li role="presentation" class="active">
      <a href="#original" role="tab" data-toggle="tab">
        <b>{lang:code2lang(document:language($model('document')))}</b>
      </a>
    </li>
    {
      for $lang in document:translations($model('document'))
      return
        <li role="presentation">
          <a href="#{$lang}" role="tab" data-toggle="tab">{lang:code2lang($lang)}</a>
        </li>
    }
  </ul>
};

declare function app:doc-translations($node as node(), $model as map(*)) as node()* {
  let $doc := $model('document')
  return
    <div class="tab-content">
      <div role="tabpanel" class="tab-pane active" id="original">
        { tx:document($doc//div[@id='original']) }
      </div>
      {
        for $lang in document:translations($model('document'))
        return
        <div role="tabpanel" class="tab-pane" id="{$lang}">
          { tx:document($doc//div[@lang=$lang]) }
        </div>
      }
    </div>
};

declare function app:doc-content($node as node(), $model as map(*)) as node()* {
    tx:document($model('document')//body/*)
};

declare function app:doc-language($node as node(), $model as map(*)) as xs:string {
    lang:code2lang(document:language($model('document')))
};

(:
* British Library (dc.source.institution if present)
* British Library Newspapers (dc.source.database if present)
* explore.bl.uk (the name part of dc.source.url, if present. Linked to the complete URL. May be repeated.)
:)

declare function app:doc-source($node as node(), $model as map(*)) as node()* {
  (
    for $institution in document:source-institution($model('document'))
    return <dd>{$institution}</dd>
  ),
  (
    for $database in document:source-database($model('document'))
    return <dd>{$database}</dd>
  ),
  (
    for $url in document:source-url($model('document'))
      return
        <dd>
          <a href="{ $url }" target="_blank"> {
            analyze-string($url,'^https?://([^/]*)')//fn:group[@nr=1]
          } </a>
        </dd>
  )
};

declare function app:doc-facsimile($node as node(), $model as map(*)) as node()* {
      for $url in document:facsimile($model('document'))
      return
        <dd>
          <a href="{ $url }" target="_blank"> {
            analyze-string($url,'^https?://([^/]*)')//fn:group[@nr=1]
          } </a>
        </dd>
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
            (<i>None found</i>)
        else
            <ul> {
                for $link in $similarities
                let $doc := collection:fetch($link/@href)
                return <li class="{$link/@class}">{app:link-view($link/@href, document:title($doc))} ({format-number($link/@data-similarity, "###.#%")}%)</li>
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
                return <li class="{$link/@class}">{app:link-view($link/@data-document, document:title($doc))} ({format-number($link/@data-similarity, "###.#%")}%)</li>
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
        <p>
          Found {count($model('hits'))} for search
          query <kbd>{$model('query')}</kbd>.
          <a href="export/search?query={$model('query')}" class='btn btn-default pull-right'>Export Results</a>
        </p>
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
            where $score > 0
            order by $score descending
            return <div data-similarity="{$score}">{$t}</div>
    return $matches[1]
};

declare function app:compare-documents($node as node(), $model as map(*)) {
    let $a := request:get-parameter('a', '')
    let $b := request:get-parameter('b', '')

    let $da := collection:fetch($a)
    let $db := collection:fetch($b)

    let $lang := $da//div[@id='original']/@lang

    let $pa := $da//div[@id='original']//p[not(@class='heading')]
    let $pb := $db//div[@lang=$lang]//p[not(@class='heading')]

    return
      <div>
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
                return
                  <div class='row paragraph-compare' data-score="{format-number($q/@data-similarity, "###.#%")}%">
                    <div class='col-sm-4 paragraph-a'>{string($other)}</div>
                    <div class='col-sm-4 paragraph-b'> {
                      if($q) then string($q) else ''
                    } </div>
                    <div class='col-sm-4 paragraph-d'> </div>
                </div>
            }
    </div>
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
    let $clean := request:get-parameter('clean', 'no') = "yes"
    let $a := similarity:normalize($c1, $clean)
    let $b := similarity:normalize($c2, $clean)

    let $d := string:getLevenshteinDistance($a, $b)
    let $m := max((string-length($a), string-length($b)))

    return <dl class='dl-horizontal'>
        <dt>levenshtein</dt>
        <dd>{
          if($c1 and $c2) then
            1 - $d div $m
          else
            0
        } </dd>
        <dt>lengths</dt>
        <dd>first passage: {string-length($a)}, second passage: {string-length($b)}</dd>
        <dt>cosine</dt>
        <dd>{similarity:similarity("cosine", $a, $b)}</dd>
        <dt>jaccard</dt>
        <dd>{similarity:similarity("jaccard", $a, $b)}</dd>
        <dt>overlap</dt>
        <dd>{similarity:similarity("overlap", $a, $b)}</dd>
        <dt>compression</dt>
        <dd>{similarity:similarity("compression", $a, $b)}</dd>
        <dt>first</dt>
        <dd id='first'>{$a}</dd>
        <dt>second</dt>
        <dd id='second'>{$b}</dd>
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

declare function app:graph-list($node as node(), $model as map(*)) as node() {
  <dl>{
    for $graph in collection:graph-list()
    return (
      <dt>{graph:title($graph)}</dt>,
      <dd>
        {graph:description($graph)}<br/>
        <a href="graph.html?f={graph:filename($graph)}">View</a>
      </dd>
      )
  }</dl>
};

declare function app:load-graph($node as node(), $model as map(*)) {
    let $f := request:get-parameter('f', '')
    let $doc := collection:graph($f)

    return map {
        "graph-id" := $f,
        "graph" := $doc
    }
};

declare function app:graph-view($node as node(), $model as map(*)) as node() {
    let $f := request:get-parameter('f', '')
    return
      <iframe src="gefx.html#{$f}" style="width: 100%; height: 700px;" />
};
