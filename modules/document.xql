xquery version "3.0";

module namespace document="http://nines.ca/exist/wilde/document";

import module namespace config="http://nines.ca/exist/wilde/config" at "config.xqm";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace functx='http://www.functx.com';

declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare default element namespace "http://www.w3.org/1999/xhtml";

declare function document:id($node as node()) as xs:string {
    let $id := root($node)/html/@id
    return if(empty($id)) then
        let $null := console:log('No id for ' || document-uri($node))
        return ''
    else
        $id
};

declare function document:apply-paragraph-ids($node as node()) {
    for $p in root($node)//p[not(@id)]
    return update insert attribute id {generate-id($p)} into $p
};

declare function document:title($node as node() ) as xs:string {
    string(root($node)//title)
};

declare function document:subtitle($node as node()) as xs:string {
    string(root($node)//body/p[1])
};

declare function document:status($node as node()) as xs:string {
  let $statuses := root($node)//meta[@name='status']/@content
  return 
    if(count($statuses) >= 1) then 
      string($statuses[1])
    else 
      'draft'
};

declare function document:path($node as node()) as xs:string {
  string(root($node)//meta[@name='wr.path']/@content)
};

declare function document:word-count($node as node()) as xs:string {
    string(root($node)//meta[@name='wr.wordcount']/@content)
};

declare function document:uri($node as node()) as xs:string {
    replace(document-uri(root($node)), $config:data-root, '')
};

declare function document:filename($node as node()) as xs:string {
    util:document-name(root($node))
};

declare function document:date($node as node()) as xs:string {
    string(root($node)//meta[@name='dc.date']/@content)
};

declare function document:publisher($node as node()) as xs:string {
    string(root($node)//meta[@name='dc.publisher']/@content)
};

declare function document:region($node as node()) as xs:string {
    string(root($node)//meta[@name='dc.region']/@content)
};

declare function document:document-matches($node as node()) as node()* {
    root($node)//link[@rel='similarity']
};

declare function document:paragraph-matches($node as node()) as node()* {
    root($node)//a[@class='similarity']
};

declare function document:city($node as node()) as xs:string {
    string(root($node)//meta[@name='dc.region.city']/@content)
};

declare function document:language($node as node()) as xs:string {
    string(root($node)//meta[@name='dc.language']/@content)
};

declare function document:collection($node as node()) as xs:string {
    let $uri := document:uri($node)
    let $parts := tokenize($uri, '/')
    return string-join(subsequence($parts,2, count($parts) - 2), '/')  
};

declare function document:modified($node as node()) as xs:dateTime {
    xmldb:last-modified($config:data-root || '/' || document:collection($node), document:filename($node))
};

declare function document:indexed-document($node as node()) as xs:string* {
    let $c := root($node)//meta[@name="index.document"]/@content
    return
        if($c = 'true') then
            'Yes'
        else
            'No'
};

declare function document:similar-documents($node as node()) as node()* {
    for $node in root($node)//link[@rel='similarity']
    order by $node/@data-similarity descending
    return $node
};

declare function document:indexed-paragraph($node as node()) as xs:string* {
    let $c := root($node)//meta[@name="index.paragraph"]/@content
    return
        if($c = 'true') then
            'Yes'
        else
            'No'
};

declare function document:similar-paragraphs($node as node()) as node()* {
    for $node in root($node)//a[@class='similarity']
    order by $node/@data-similarity descending
    return $node
};
