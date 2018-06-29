(:~
 : I don't think this module is used at all. 
 :)
xquery version "3.0";

module namespace tx="http://dhil.lib.sfu.ca/exist/wilde-app/transform";

import module namespace kwic="http://exist-db.org/xquery/kwic";
import module namespace collection="http://dhil.lib.sfu.ca/exist/wilde-app/collection" at "collection.xql";
import module namespace document="http://dhil.lib.sfu.ca/exist/wilde-app/document" at "document.xql";

declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare default element namespace "http://www.w3.org/1999/xhtml";

declare function tx:document($nodes as node()*) as node()* {
    let $query := request:get-parameter('query', '')
    
    for $node in $nodes return
        typeswitch($node)
            case text() return
                $node
                
            case element(p) return
                if($query = '') then
                    element { local-name($node) } { $node/@*, tx:document($node/node()) }
                else
                    let $hits := ft:query($node, $query)
                    return 
                        if($hits) then
                            element { local-name($node) } { $node/@*, tx:document(kwic:expand($hits)/node()) }
                        else
                            element { local-name($node) } { $node/@*, tx:document($node/node()) }

            case element(exist:match) return
                <strong class='match'> { tx:document($node/node()) } </strong>

            case element(a) return
                if(contains($node/@class, 'similarity')) then
                    let $document := collection:fetch($node/@data-document)
                    let $paragraph := $document//p[@id=$node/@data-paragraph]
                    return 
                    <blockquote class='similarity'> 
                        <p>{string($paragraph[1])}</p> 
                        { 
                          if (count($paragraph) ne 1) then 
                          <div>
                            <b>DUPLICATE.</b>
                            { 
                              for $p in $paragraph
                              return <div> {$node/@data-paragraph/string()}::{document:id($p)} - {$p/@id/string()} - {string($p)}</div>
                            }
                          </div> 
                          else () 
                        }
                        <a href='view.html?f={document:id($document)}#{$paragraph/@id}'>{document:title($document)}</a> 
                        ({format-number($node/@data-similarity, "###.#%")}%)<br/>
                        <a href='compare.html?a={document:id($node)}&amp;b={$node/@data-document}'>Compare two documents</a>
                    </blockquote>
                else
                    $node
            case element(*) return
                element { local-name($node) } { $node/@*, tx:document($node/node()) }
            default
                return $node/string()
};
