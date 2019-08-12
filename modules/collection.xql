(:~
 : Functions for interacting with a collection.
 :)
xquery version "3.0";

module namespace collection="http://dhil.lib.sfu.ca/exist/wilde-app/collection";

import module namespace config="http://dhil.lib.sfu.ca/exist/wilde-app/config" at "config.xqm";
import module namespace functx='http://www.functx.com';
import module namespace document="http://dhil.lib.sfu.ca/exist/wilde-app/document" at "document.xql";

declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare default element namespace "http://www.w3.org/1999/xhtml";

(:~
 : Fetch a node for the root of the data.
 : @return Node representing the data collection
 :)
declare function collection:collection() as node()* {
    collection($config:data-root || '/reports')
   
};

declare function collection:graph($filename as xs:string) as node() {
  if(not(matches($filename, '^[a-zA-Z0-9% .-]*$'))) then
    ()
  else
    let $path := $config:graph-root || '/' || $filename
    return
      if(doc-available($path)) then
        doc($path)
      else
        ()
};

declare function collection:graph-list() as node()* {
    let $collection := collection($config:graph-root)
    return
        for $doc in $collection
        where fn:ends-with(util:document-name($doc), '.gexf')
        order by util:document-name($doc)
        return $doc
};

declare function collection:image-list() as xs:string* {
    let $collection := collection($config:thumb-root)
    return 
        for $doc in $collection
        let $filename := xmldb:decode(util:document-name($doc))
        order by $filename
        return $filename
};

(:~
 : Fetch a document from the collection.
 : @param $id the string ID of the document to fetch
 : @return The HTML root node of the document or a blank HTML document.
 :)
declare function collection:fetch($id as xs:string) as node() {
    let $collection := collection($config:data-root)
    let $document := $collection//html[@id=$id]
    return
      if($document) then
        $document
      else
        <html>
          <head>
            <title>Cannot find {$id}.</title>
          </head>
          <body>
            <p>Cannot find {$id}.</p>
          </body>
        </html>
};

(:~
 : Fetch one paragraph from the collection.
 : @param $doc-id The document ID containing the paragraph.
 : @param $par-id The ID of the paragraph in $doc-id.
 : @return Node representing the paragraph or null.
 :)
declare function collection:paragraph($doc-id as xs:string, $par-id as xs:string) as node() {
    let $collection := collection($config:data-root)
    return $collection//html[@id=$doc-id]//p[@id=$par-id]
};

(:~
 : Fetch the next document by date and publisher from the collection, or
 : an empty node if there isn't a next document for the publisher.
 : @param $document The document to find the next one.
 : @return Node representing the document.
 :)
declare function collection:next($document) as node()? {
  let $publisher := document:publisher($document)
  let $date := document:date($document)

  let $documents :=
    for $doc in collection($config:data-root)/html[.//meta[@name='dc.publisher' and @content=$publisher]]
    order by document:date($doc), document:id($doc)
    return $doc

  let $idx := functx:index-of-node($documents, $document)
  return
    if($idx lt count($documents)) then
      $documents[$idx + 1]
    else
      ()
};

(:~
 : Fetch the previous document by date and publisher from the collection, or
 : an empty node if there isn't a previous document for the publisher.
 : @param $document The document to find the previous one.
 : @return Node representing the document.
 :)
declare function collection:previous($document) as node()? {
  let $publisher := document:publisher($document)
  let $date := document:date($document)

  let $documents :=
    for $doc in collection($config:data-root)/html[.//meta[@name='dc.publisher' and @content=$publisher]]
    order by document:date($doc), document:id($doc)
    return $doc

  let $idx := functx:index-of-node($documents, $document)
  return
    if($idx ge 2) then
      $documents[$idx - 1]
    else
      ()
};

(:~
 : Fetch the documents from the collection, ordered by region, publisher, and date.
 : @return Sequence of nodes for the roots of the documents.
 :)
declare function collection:documents() as node()* {
    let $collection := collection:collection()
    return
        for $doc in $collection
        order by document:region($doc), document:publisher($doc), document:date($doc), document:id($doc)
        return $doc
};

(:~
 : Fetch documents from the collection which have an HTML meta tag with
 : which matches the $name and $value parameters. The documents
 : are ordered by region, publisher, and date.
 : @param $name The name attribute's value
 : @param $value The value attribute's value
 : @return Sequence of nodes for the roots of the documents.
 :)
declare function collection:documents($name as xs:string, $value as xs:string) as node()* {
    let $collection := collection($config:data-root)[.//meta[@name=$name and @content=$value]]
    return
        for $doc in $collection
        order by document:region($doc), document:publisher($doc), document:date($doc)
        return $doc
};

(:~
 : Fetch a list of publishers, ordered by name.
 : @return Sequence of strings.
 :)
declare function collection:publishers() as xs:string* {
    for $publisher in distinct-values(collection($config:data-root)//meta[@name='dc.publisher']/@content)
    order by $publisher
    return $publisher
};

(:~
 : Fetch a list of regions, ordered by name.
 : @return Sequence of strings.
 :)
declare function collection:regions() as xs:string* {
    for $region in distinct-values(collection($config:data-root)//meta[@name='dc.region']/@content)
    order by $region
    return $region
};

declare function collection:regions($publisher as xs:string) as xs:string* {
    let $heads := collection:collection()//head[meta[@name='dc.publisher'][@content=$publisher]]    
    let $regions := $heads//meta[@name='dc.region']/@content/string()
    return distinct-values($regions)
};

(:~
 : Fetch a list of languages, ordered by name.
 : @return Sequence of strings.
 :)
declare function collection:languages() as xs:string* {
    for $language in distinct-values(collection($config:data-root)//meta[@name='dc.language']/@content)
    order by $language
    return $language
};

declare function collection:languages($publisher as xs:string) as xs:string* {
    let $heads := collection:collection()//head[meta[@name='dc.publisher'][@content=$publisher]]    
    let $languages := $heads//meta[@name='dc.language']/@content/string()
    return distinct-values($languages)
};

(:~
 : Fetch a list of languages, ordered by name.
 : @return Sequence of strings.
 :)
declare function collection:sources() as xs:string* {
    for $source in distinct-values(collection($config:data-root)//meta[@name='dc.source']/@content)
    order by $source
    return $source
};

(:~
 : Fetch a list of cities, ordered by name.
 : @return Sequence of strings.
 :)
declare function collection:cities() as xs:string* {
    for $city in distinct-values(collection($config:data-root)//meta[@name='dc.region.city']/@content)
    order by $city
    return $city
};

declare function collection:cities($publisher as xs:string) as xs:string* {
    let $heads := collection:collection()//head[meta[@name='dc.publisher'][@content=$publisher]]    
    let $cities := $heads//meta[@name='dc.region.city']/@content/string()
    return distinct-values($cities)
};

(:~
 : Search the collection for the query string.
 : @return Sequence of hits ordered by score.
 :)
declare function collection:search($query as xs:string) as node()* {
    if(empty($query) or $query = '') then
        ()
    else
        for $hit in collection($config:data-root)//div[@id="original"]//p[ft:query(., $query)]
        order by ft:score($hit) descending
        return $hit
};

(:~
 : Fetch all of the paragraph level similarities, ordered by similarity.
 : @return Sequence of nodes.
 :)
declare function collection:similarities() as node()* {
    for $a in collection($config:data-root)//a[@class='similarity']
        let $da := xs:date(document:date($a))
        let $b := collection:paragraph($a/@data-document, $a/@data-paragraph)
        let $db := xs:date(document:date($b))
        where $da le $db
        order by  $a/@data-similarity descending, document:id($a)
        return $a
};
