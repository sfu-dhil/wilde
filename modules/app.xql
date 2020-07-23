xquery version "3.0";

module namespace app="http://dhil.lib.sfu.ca/exist/wilde-app/templates";

import module namespace kwic="http://exist-db.org/xquery/kwic";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace functx="http://www.functx.com";
import module namespace map="http://www.w3.org/2005/xpath-functions/map";
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
        <table class='table table-striped table-hover table-condensed' id="tbl-browser">
            <thead>
                <tr>
                    <th data-field="date">Date</th>
                    <th data-field="newspaper" data-filter-control="select" data-sortable="true" data-filter-strict-search="true">Newspaper</th>
                    <th data-field="region" data-filter-control="select" data-sortable="true" data-filter-strict-search="true">Region</th>
                    <th data-field="city" data-filter-control="select" data-sortable="true" data-filter-strict-search="true">City</th>
                    <th data-field="language" data-filter-control="select" data-sortable="true" data-filter-strict-search="true">Language</th>
                    <th data-field="document-matches" data-sortable="true">Document <br/>Matches</th>
                    <th data-field="paragraph-matches" data-sortable="true">Paragraph <br/>Matches</th>
                    <th data-field="words" data-sortable="true">Word Count</th>
                </tr>
            </thead>
            <tbody>{
                for $document in $documents
                return <tr>
                    <td>{app:link-view(document:id($document), document:date($document))}</td>
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

declare function app:browse-date($node as node(), $model as map(*)) as node()+ {
      let $collection := collection:documents()
      let $dates := $collection//xhtml:meta[@name="dc.date"]/string(@content)
      let $jDates := $dates[normalize-space(.) castable as xs:date]
      let $distinctJDates := distinct-values($jDates)
      let $months := distinct-values(for $date in $jDates return tokenize($date,'-')[2])
      let $cal-header:= for $n in 1 to 7 return  <div class="cal-cell">{format-date(xs:date('2020-03-0' || $n), '[FNn]')}</div>
      return
        for $month in $months order by xs:integer($month) return
            let $firstDay := xs:date('1895-' || $month || '-01')
            let $offset := app:weekday-from-date($firstDay)
            let $monthLength := app:last-day-of-month($month)
            return
            <div>
                <h2>{ format-date($firstDay,'[MNn]') }</h2>
                <div class="calendar offset-{$offset}">
                    <div class="cal-header">
                        {$cal-header}
                    </div>
                    <div class="cal-body">
                        {
                            for $n in 1 to $monthLength
                            let $date := string-join(('1895',$month,format-number($n,'00')),'-')
                            let $dateCount := count($dates[matches(.,$date)])
                            return
                            <div class="cal-cell count-{$dateCount}" data-date="{$date}">
                                <a href="date-details.html?date={$date}">
                                    <span class="day">{$n}</span>
                                    <span class="count">{$dateCount}</span>
                                </a>
                            </div>
                        }
                    </div>
                </div>
            </div>
};


declare function app:last-day-of-month($month as xs:string) as xs:integer{
let $one-day := xs:dayTimeDuration('P1D')
let $one-month := xs:yearMonthDuration('P1M')
let $month-date := xs:date('1895-' || $month || '-01')
    return xs:integer(day-from-date($month-date + $one-month - $one-day))
};



declare function app:weekday-from-date($date as xs:date) as xs:integer{
    xs:integer(format-date($date, '[F0]')) + 1
};

declare function app:details-date($node as node(), $model as map(*)) as node() {
  let $date := request:get-parameter('date', false())
      let $docs := collection:documents('dc.date', $date)
      return <ul> {
        for $document in $docs
        order by document:publisher($document)
        return <li>{app:link-view(document:id($document), document:title($document))} ({lang:code2lang(document:language($document))})</li>
      } </ul>
};



declare function app:browse-newspaper($node as node(), $model as map(*)) as node() {
  let $collection := collection:documents()
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
                    <td><a href="newspaper-details.html?publisher={$publisher}">{$publisher}</a></td>
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

declare function app:details-newspaper($node as node(), $model as map(*)) as node() {
  let $publisher := request:get-parameter('publisher', false())
      let $docs := collection:documents('dc.publisher', $publisher)
      return <ul> {
        for $document in $docs
        order by document:date($document)
        return <li>{app:link-view(document:id($document), document:title($document))}</li>
      } </ul>
};

declare function app:browse-language($node as node(), $model as map(*)) as node() {
  let $collection := collection:documents()
      let $languages := $collection//xhtml:meta[@name="dc.language"]/@content
      return
        <ul> {
          for $language in distinct-values($languages)
          let $count := local:count($languages, $language)
          order by $language
          return <li data-language="{lang:code2lang($language)}" data-count="{$count}">
              <a href="language-details.html?language={$language}">{lang:code2lang($language)}</a>:
              {$count}
            </li>
        } </ul>
};

declare function app:details-language($node as node(), $model as map(*)) as node() {
  let $language := request:get-parameter('language', false())
      let $docs := collection:documents('dc.language', $language)
      return <ul> {
        for $document in $docs
        order by document:publisher($document), document:date($document)
        return <li>{app:link-view(document:id($document), document:title($document))}</li>
      } </ul>
};


declare function app:browse-region($node as node(), $model as map(*)) as node() {
  let $collection := collection:documents()
      let $regions := $collection//xhtml:meta[@name="dc.region"]/@content
      return
        <ul> {
          for $region in distinct-values($regions)
          let $count := local:count($regions, $region)
          order by $region
          return <li data-region="{$region}" data-count="{$count}">
              <a href="region-details.html?region={$region}">{$region}</a>:
              {$count}
            </li>
        } </ul>
};

declare function app:details-region($node as node(), $model as map(*)) as node() {
  let $region := request:get-parameter('region', false())
      let $docs := collection:documents('dc.region', $region)
      return <ul> {
        for $document in $docs
        order by document:publisher($document), document:date($document)
        return <li>{app:link-view(document:id($document), document:title($document))}</li>
      } </ul>
};

declare function app:browse-source($node as node(), $model as map(*)) as node() {
  let $collection := collection:documents()
  return
      <div class='row'>
        <div class='col-md-6'>
          <h2>Databases</h2>
            <ul> {
              let $sources := $collection//xhtml:meta[@name="dc.source.database"]/@content
              for $source in distinct-values($sources)
              let $count := local:count($sources, $source)
              order by $source
              return <li>
                  <a href="source-details.html?source={$source}&amp;type=database">{$source}</a>: {$count}
                </li>
            } </ul>
        </div>
        <div class='col-md-6'>
          <h2>Institutions</h2>
            <ul> {
              let $sources := $collection//xhtml:meta[@name="dc.source.institution"]/@content
              for $source in distinct-values($sources)
              let $count := local:count($sources, $source)
              order by $source
              return <li>
                  <a href="source-details.html?source={$source}&amp;type=institution">{$source}</a>: {$count}
                </li>
            } </ul>
        </div>
      </div>
};

declare function app:details-source($node as node(), $model as map(*)) as node() {
  let $source := request:get-parameter('source', false())
  return
      let $docs := collection:documents('dc.source.' || request:get-parameter('type', 'db'), $source)
      return <ul> {
        for $document in $docs
        order by document:publisher($document), document:date($document)
        return <li>{app:link-view(document:id($document), document:title($document))}</li>
      } </ul>
};


declare function app:browse-city($node as node(), $model as map(*)) as node() {
  let $collection := collection:documents()
  let $city := request:get-parameter('city', false())
  return
      let $cities := $collection//xhtml:meta[@name="dc.region.city"]/@content
      return
        <ul> {
          for $city in distinct-values($cities)
          let $count := local:count($cities, $city)
          order by $city
          return <li data-city="{$city}" data-count="{$count}">
              <a href="city-details.html?city={$city}">{$city}</a>:
              {$count}
            </li>
        } </ul>
};

declare function app:parameter($node as node(), $model as map(*), $name as xs:string) as xs:string {
  let $p := request:get-parameter($name, false())
  return if($name = 'language') then
        lang:code2lang($p)
    else
        serialize($p)
};

declare function app:details-city($node as node(), $model as map(*)) as node() {
  let $city := request:get-parameter('city', false())
  return
      let $docs := collection:documents('dc.region.city', $city)
      return <ul> {
        for $document in $docs
        order by document:publisher($document), document:date($document)
        return <li>{app:link-view(document:id($document), document:title($document))}</li>
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

declare function app:doc-updated($node as node(), $model as map(*)) as xs:string {
    document:updated($model('document'))
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
    let $levens := $similarities[@data-type='lev']
    let $exact := $similarities[@data-type='exact']

    return
        if(count($similarities) = 0) then
            (<i>None found</i>)
        else
            <div>
                <div class='panel-body'>{
                    if(count($levens) = 0) then
                        <i>None found</i>
                    else
                        <ul> {
                            for $link in $levens
                            let $doc := collection:fetch($link/@href)
                            order by $link/@data-similarity descending
                            return
                                <li class="{$link/@class}">
                                    {app:link-view($link/@href, document:title($doc))} - {format-number($link/@data-similarity, "###.#%")}% <br/>
                                    <a href='compare-docs.html?a={document:id($model('document'))}&amp;b={document:id($doc)}'>Compare</a>
                                </li>
                        } </ul>
                }</div>
        </div>
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
                return
                    <li class="{$link/@class}">
                        {app:link-view($link/@data-document, document:title($doc))} ({format-number($link/@data-similarity, "###.#%")}%)
                    </li>
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
        </p>
};

declare function app:search-export($node as node(), $model as map(*)) {
    let $query := request:get-parameter('query', false())
    
    return    
        if($query) then
            <a href="export/search.csv?query={$query}" class='btn btn-primary'>Export Results</a>
        else
            ()
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

declare function app:compare-paragraphs($node as node(), $model as map(*)) {
    let $a := request:get-parameter('a', '')
    let $b := request:get-parameter('b', '')

    let $da := collection:fetch($a)
    let $db := collection:fetch($b)

    let $lang := $da//div[@id='original']/@lang

    let $pa := $da//div[@id='original']//p[not(@class='heading')]
    let $pb := $db//div[@id='original']//p[not(@class='heading')]
    
    let $la := app:link-view($a, document:title($da))
    let $lb := app:link-view($b, document:title($db))

    return
      <div>
        <div class="row compare-header">
            <div class='col-sm-4'>
                <b>Original paragraph in <br/>
                {$la}</b>
            </div>
            <div class='col-sm-4'>
                <b>Most similar paragraph from <br/>
                {$lb}</b>
            </div>
            <div class='col-sm-4'>
                <b>Difference</b>
            </div>
        </div> {
            for $other at $i in $pa
                let $q := local:find-similar("levenshtein", $pb, $other)
                return
                  <div class='row paragraph-compare' data-score="{format-number($q/@data-similarity, "###.#%")}%">
                    <div class="col-sm-4 paragraph-a">
                    <div class="compare-link">{$la}</div>
                    {string($other)}</div>
                    <div class="col-sm-4 paragraph-b">
                         <div class="compare-link">{$lb}</div>
                    {
                      if($q) then string($q) else '—'
                    } </div>
                    <div class="col-sm-4 paragraph-d" data-caption="Difference">
                    </div>
                </div>
            }
    </div>
};

declare function local:measure($name as xs:string) as xs:string {
    switch ($name)
        case 'lev' return 'Levenshtein'
        case 'cos' return 'Cosine'
        case 'exact' return 'Exact'
        default return 'Unknown'
};

declare function app:compare-documents($node as node(), $model as map(*)) {
    let $a := request:get-parameter('a', '')
    let $b := request:get-parameter('b', '')

    let $da := collection:fetch($a)
    let $db := collection:fetch($b)

    let $lang := $da//div[@id='original']/@lang

    let $pa := $da//div[@id='original']//p[not(@class='heading')]
    let $pb := $db//div[@id='original']//p[not(@class='heading')]
    let $links := $da//link[@href=$b]
    
    return
      <div>
        <div class='row'>
            <div class='col-sm-4'>
                <b>{app:link-view($a, document:title($da))}</b>
            </div>
            <div class='col-sm-4'>
                <b>{app:link-view($b, document:title($db))}</b>
            </div>
            <div class='col-sm-4'> 
                <b>Highlighted Differences</b> <br/> { 
                    if (count($links) gt 0) then
                        for $link in $links 
                        return 
                            <span style="display:block;">Match: {format-number($link/@data-similarity, "###.#%")}%</span>
                    else "Not significantly similar"
                } </div>
        </div>
        <div class='row'>
            <div class='col-sm-4' id="doc_a"> {
                for $p in $pa
                return <p>{$p/text()}</p>
            }
            </div>
            <div class='col-sm-4' id="doc_b"> {
                for $p in $pb
                return <p>{$p/text()}</p>
            }
            </div>
            <div class='col-sm-4' id="diff"></div>
        </div>
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
    
    let $lev :=
        if($c1 and $c2) then
            1 - $d div $m
          else
            0
    let $cos := similarity:similarity("cosine", $a, $b)

    return <div id="measure-results">
      <dl class='dl-horizontal'>
        <dt>Word counts</dt>
        <dd>First passage: {functx:word-count($a)}, Second passage: {functx:word-count($b)}</dd>
        <dt>Similarity</dt>
        <dd>{format-number($lev, "###.#%")}%</dd>
        <dt>Difference</dt>
        <dd id='difference'></dd>
      </dl>
      
      <div class="hidden">
        <div id='first'>{$a}</div>
        <div id='second'>{$b}</div>
      </div>
    </div>
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
      <dt><a href="graph.html?f={graph:filename($graph)}">{graph:title($graph)}</a></dt>,
      <dd>
        {graph:description($graph)}<br/>        
        {graph:modified($graph)}
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

declare function app:gallery($node as node(), $model as map(*)) as node() {

    let $filenames := collection:image-list()
    let $cols := 3
    let $empty := count($filenames) mod $cols
    let $metadata := collection:image-meta()
    let $tileCount := count($filenames) + $empty
    return 
        <div class="gallery">{
            for $index in  1 to $tileCount return
                if ($index <= count($filenames)) then
                    let $filename := $filenames[$index]
                    let $meta := $metadata//div[@data-filename=$filename]
                    let $title := if($meta) then $meta/@data-title/string() else ""
                    let $date := if($meta) then $meta/@data-date/string() else ""
                    let $descr := if($meta/node()/text()) then $meta/node() else <p>{$filename}</p>
                    return
                    <div class="img-tile">
                        <div class="thumbnail">
                            <div class="img-container">
                                <a href="#imgModal" data-toggle="modal" data-title="{$title}"  data-date="{$date}" data-target="#imgModal" data-img="images/{$filename}">
                                    <img alt="{normalize-space(string-join($meta,''))}" src="thumbs/{$filename}" class="img-thumbnail"/>
                                </a>
                            </div>
                            <div class="caption">                    
                                <div class="title"><i>{$title}</i><br/>{$date}<br/></div>                                    
                                {$descr}
                            </div>
                        </div>
                    </div>
                    else 
                    <div class="img-tile empty">
                    </div>
          }
      </div>
};
