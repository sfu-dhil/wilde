(:~
 : I don't think this module is used at all. 
 :)
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
        <p>No matches found.</p>
};

declare function tx:paragraph($node as node()) as node() {
    let $id := $node/@id/string()    
    
    return 
    <div class="container">
        <div class="row">
            <div class="col-sm-1">
                controls
            </div>
            <div class='col-sm-11'>
                <p id="{$node/@id}">
                    { tx:document($node/node()[local-name() != 'a']) }
                </p>
        
                <div>
                    <ul class="nav nav-tabs" role="tablist">
                        <li role="presentation" class="active"><a href="#{$id}_exact" aria-controls="home" role="tab" data-toggle="tab">Exact</a></li>
                        <li role="presentation"><a href="#{$id}_lev" aria-controls="home" role="tab" data-toggle="tab">Levenshtein</a></li>
                        <li role="presentation"><a href="#{$id}_cos" aria-controls="home" role="tab" data-toggle="tab">Cosine</a></li>
                        <li role="presentation"><a href="#{$id}_vsm" aria-controls="home" role="tab" data-toggle="tab">VSM</a></li>
                    </ul>
                    
                    <div class="tab-content">
                        <div role="tabpanel" class="tab-pane active" id="{$id}_exact"> { tx:matches($node, "exact")} </div>
                        <div role="tabpanel" class="tab-pane" id="{$id}_lev"> { tx:matches($node, "lev")} </div>
                        <div role="tabpanel" class="tab-pane" id="{$id}_cos"> { tx:matches($node, "cos")} </div>
                        <div role="tabpanel" class="tab-pane" id="{$id}_vsm"> { tx:matches($node, "vsm")} </div>
                    </div>
                </div>
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
                            <blockquote
                                class='similarity'>
                                <p>{string($paragraph[1])}</p>
                                {
                                    if (count($paragraph) ne 1) then
                                        <div>
                                            <b>DUPLICATE.</b>
                                            {
                                                for $p in $paragraph
                                                return
                                                    <div>
                                                        {$node/@data-paragraph/string()}::{document:id($p)} - {$p/@id/string()} - {string($p)}</div>
                                            }
                                        </div>
                                    else
                                        ()
                                }
                                <a
                                    href='view.html?f={document:id($document)}#{$paragraph/@id}'>{document:title($document)}</a>
                                ({format-number($node/@data-similarity, "###.#%")}% {$node/@data-type/string()})<br/>
                                <a
                                    href='compare.html?a={document:id($node)}&amp;b={$node/@data-document}'>Compare two documents</a>
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
