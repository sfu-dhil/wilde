xquery version "3.0";

module namespace index="http://nines.ca/exist/wilde/index";

import module namespace functx="http://www.functx.com"; 
import module namespace console="http://exist-db.org/xquery/console";
import module namespace config="http://nines.ca/exist/wilde/config" at "config.xqm";
import module namespace collection="http://nines.ca/exist/wilde/collection" at "collection.xql";
import module namespace document="http://nines.ca/exist/wilde/document" at "document.xql";
import module namespace similarity="http://nines.ca/exist/wilde/similarity" at "similarity.xql";

declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare default element namespace "http://www.w3.org/1999/xhtml";

declare variable $index:initialIndex := true;

declare function index:comparable-documents($document as node()) as node()* {
    let $id := document:id($document)
    return 
    for $document in collection:documents()
      where
        (document:id($document) != $id) and
        (document:status($document) != 'draft')
      return $document
};

declare function index:reindex-paragraphs($document as node()) as node() {
    let $metric := $config:similarity-metric
    let $threshold := $config:similarity-threshold
    let $startTime := util:system-time()
    
    let $comparables := index:comparable-documents($document)
    let $null := console:log('Comparing ' || document:id($document) || ' against ' || count($comparables))
    let $matches := 
        if(count($comparables) eq 0) then
            (0)
        else
            for $comp in $comparables
                return
                    for $pa in $comp//p
                    for $pb in $document//p
                        let $m := similarity:similarity($metric, string($pa), string($pb))
                        return if($m > $threshold) then (
                            1,
                            update insert <a class="similarity" data-type="levenshtein" data-document="{document:id($comp)}" data-paragraph="{string($pa/@id)}" data-similarity="{$m}" /> into $pb,
                            update insert <a class="similarity" data-type="levenshtein" data-document="{document:id($document)}" data-paragraph="{string($pb/@id)}" data-similarity="{$m}" /> into $pa
                        ) else (
                            0
                        )
    let $status := update insert <meta name="index.paragraph" content="true"/> into $document//head

    let $endTime := util:system-time()
    let $duration :=  functx:total-seconds-from-duration($endTime - $startTime)
    
    return <result id="{document:id($document)}" title="{document:title($document)}" matches="{sum($matches)}" duration="{$duration}"/>
};

declare function index:reindex-document($document as node()) as node() {
    let $metric := $config:similarity-metric
    let $threshold := $config:similarity-threshold
    let $startTime := util:system-time()
    
    let $comparables := index:comparable-documents($document)
    let $null := console:log('Comparing ' || document:id($document) || ' against ' || count($comparables))
    
    let $matches := 
        if(count($comparables) eq 0) then
            (0)
        else
            for $comp in $comparables
              let $null := console:log("comparing " || document:id($document) || " against " || document:id($comp))
                return
                    let $m := similarity:similarity($metric, string($document/xhtml:html/xhtml:body), string($comp/xhtml:html/xhtml:body))
                    return if($m > $threshold) then (
                        1,
                        update insert <link rel="similarity" class="levenshtein" href="{document:id($comp)}" data-similarity="{$m}" /> into $document//head,
                        update insert <link rel="similarity" class="levenshtein" href="{document:id($document)}" data-similarity="{$m}" /> into $comp//head
                    ) else (
                        0
                    )
    let $status := update insert <meta name="index.document" content="true"/> into $document//head
    let $endTime := util:system-time()
    let $duration :=  functx:total-seconds-from-duration($endTime - $startTime)
    
    return <result id="{document:id($document)}" title="{document:title($document)}" matches="{sum($matches)}" duration="{$duration}"/>
};

