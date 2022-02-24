xquery version "3.0";

module namespace tx = "http://dhil.lib.sfu.ca/exist/wilde-app/transform";

import module namespace collection = "http://dhil.lib.sfu.ca/exist/wilde-app/collection" at "collection.xql";
import module namespace document = "http://dhil.lib.sfu.ca/exist/wilde-app/document" at "document.xql";
import module namespace kwic = "http://exist-db.org/xquery/kwic";

declare namespace xhtml = 'http://www.w3.org/1999/xhtml';

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function tx:count-matches($node, $type) {
    count($node/a[@data-type=$type])
};

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
            <div class="col-sm-3"> {
                if($match-count gt 0) then
                        <a class="btn btn-primary" onclick="$(this).parent().parent().toggleClass('viewing-matches'); $('#{$id}_matches').toggle();" title="Show matches">
                            {$match-count} match{ if ($match-count gt 1) then 'es' else ''}
                        </a>
                    else
                        ""
            } </div>
            <div class='col-sm-8'>
                <p id="{$node/@id}" class="text-justify {$node/@class/string()}">
                    { tx:document($node/node()[local-name() != 'a']) }
                </p>
                
                <div id="{$id}_matches" class='similarity'> 
                    <div class="panel panel-default"> {
                      if($match-count gt 0) then
                        <div role="tabpanel" class="tab-pane" id="{$id}_lev"> { tx:matches($node, "lev")} </div>
                      else
                        ""
                      }
                    </div>
               </div>
                <div class="col-sm-1"></div>
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
                                  <a href='compare.html?a={document:id($node)}&amp;b={$node/@data-document}'>Compare Paragraphs</a> | <a href='compare-docs.html?a={document:id($node)}&amp;b={$node/@data-document}'>Compare Documents</a>
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
