xquery version "3.0";

module namespace tx = "http://dhil.lib.sfu.ca/exist/wilde-app/transform";

import module namespace kwic = "http://exist-db.org/xquery/kwic";
import module namespace collection = "http://dhil.lib.sfu.ca/exist/wilde-app/collection" at "collection.xql";
import module namespace document = "http://dhil.lib.sfu.ca/exist/wilde-app/document" at "document.xql";

declare namespace xhtml = 'http://www.w3.org/1999/xhtml';
declare default element namespace "http://www.w3.org/1999/xhtml";

declare function tx:matches($node, $type) {
    let $matches :=
        for $a in $node/a[@data-type=$type]
        order by $a/@data-similarity descending
        return $a

    return if(count($matches) gt 0) then
        tx:document($matches)
    else
        <blockquote class="no-matches-found"><p>No matches found.</p></blockquote>
};

declare function tx:paragraph($node as node()) as node() {
    let $id := $node/@id/string()
    let $match-count := count($node/a)

    return
        <div class="row matches matches-{$match-count}">
            <div class="col-sm-2"> {
                if($match-count gt 0) then
                        <a class="btn btn-primary" onclick="$(this).parent().parent().toggleClass('viewing-matches'); $('#{$id}_matches').toggle();" title="Show matches">
                            {$match-count} match{ if ($match-count gt 1) then 'es' else ''}
                        </a>
                    else
                        ""
            } </div>
            <div class='col-sm-10'>
                <p id="{$node/@id}">
                    { tx:document($node/node()[local-name() != 'a']) }
                </p>
                <div id="{$id}_matches" class='similarity'> {
                  if($match-count gt 0) then
                      <ul class="nav nav-tabs" role="tablist">
                          <li role="presentation" class="active"><a href="#{$id}_exact" aria-controls="home" role="tab" data-toggle="tab">Exact</a></li>
                          <li role="presentation"><a href="#{$id}_lev" aria-controls="home" role="tab" data-toggle="tab">Levenshtein</a></li>
                          <li role="presentation"><a href="#{$id}_cos" aria-controls="home" role="tab" data-toggle="tab">Cosine</a></li>
                      </ul>
                  else
                    ""
                  }
                  {
                  if($match-count gt 0) then
                    <div class="tab-content">
                        <div role="tabpanel" class="tab-pane active" id="{$id}_exact"> { tx:matches($node, "exact")} </div>
                        <div role="tabpanel" class="tab-pane" id="{$id}_lev"> { tx:matches($node, "lev")} </div>
                        <div role="tabpanel" class="tab-pane" id="{$id}_cos"> { tx:matches($node, "cos")} </div>
                   </div>
                  else
                    ""
                  }
               </div>

            </div>
    </div>
};

declare function tx:document($nodes as node()*) as node()* {
    let $query := request:get-parameter('query', '')

    for $node in $nodes
    return
        typeswitch ($node)
            case text()
                return
                    $node

            case element(p)
                return tx:paragraph($node)

            case element(exist:match)
                return
                    <strong
                        class='match'>
                        {tx:document($node/node())}
                    </strong>

            case element(a)
                return
                    if (contains($node/@class, 'similarity')) then
                        let $document := collection:fetch($node/@data-document)
                        let $paragraph := $document//p[@id = $node/@data-paragraph]
                        return
                            <blockquote class="matches-found">
                                <p>{string($paragraph[1])}</p>
                                <div class="comparison-links">
                                  <a href='view.html?f={document:id($document)}#{$paragraph/@id}'>
                                      {document:title($document)}
                                  </a> ({format-number($node/@data-similarity, "###.#%")}%) <br/>
                                  <a href='compare.html?a={document:id($node)}&amp;b={$node/@data-document}'>Compare two documents</a>
                                </div>
                            </blockquote>
                    else
                        $node
            case element(*)
                return
                    element {local-name($node)} {$node/@*, tx:document($node/node())}
            default
                return
                    $node/string()
};
