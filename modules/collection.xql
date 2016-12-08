xquery version "3.0";

module namespace collection="http://nines.ca/exist/wilde/collection";

import module namespace config="http://nines.ca/exist/wilde/config" at "config.xqm";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace functx='http://www.functx.com';
import module namespace document="http://nines.ca/exist/wilde/document" at "document.xql";

declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare default element namespace "http://www.w3.org/1999/xhtml";

declare function collection:collection() as node()* {
    collection($config:data-root)
};

declare function collection:fetch($id as xs:string) as node() {
    let $collection := collection($config:data-root)
    return $collection//html[@id=$id]
};

declare function collection:paragraph($doc-id as xs:string, $par-id as xs:string) as node() {
    let $collection := collection($config:data-root)
    return $collection//html[@id=$doc-id]//p[@id=$par-id]
};

declare function collection:next($document) as node()? {
  let $publisher := document:publisher($document)
  let $date := document:date($document)
  
  let $documents := 
    for $doc in collection($config:data-root)[.//meta[@name='dc.publisher' and @content=$publisher]]
    where document:date($doc) ge $date
    order by document:date($doc), document:id($doc)
    return $doc
  
  return $documents[2]
};

declare function collection:documents() as node()* {
    let $collection := collection:collection()
    return
        for $doc in $collection
        order by document:region($doc), document:publisher($doc), document:date($doc), document:id($doc)
        return $doc
};

declare function collection:documents($name as xs:string, $value as xs:string) as node()* {
    let $collection := collection($config:data-root)[.//meta[@name=$name and @content=$value]]
    return 
        for $doc in $collection
        order by document:region($doc), document:publisher($doc), document:date($doc)
        return $doc
};

declare function collection:publishers() as xs:string* {
    for $publisher in distinct-values(collection($config:data-root)//meta[@name='dc.publisher']/@content)
    order by $publisher
    return $publisher    
};

declare function collection:regions() as xs:string* {
    for $region in distinct-values(collection($config:data-root)//meta[@name='dc.region']/@content)
    order by $region
    return $region    
};

declare function collection:statuses() as xs:string* {
    ('candidate', 'draft')
};

declare function collection:search($query as xs:string) as node()* {
    if(empty($query) or $query = '') then
        ()
    else
        for $hit in collection($config:data-root)//p[ft:query(., $query)]
        order by ft:score($hit) descending
        return $hit        
};

declare function collection:similarities() as node()* {
    for $a in collection($config:data-root)//a[@class='similarity']
        let $da := xs:date(document:date($a))
        let $b := collection:paragraph($a/@data-document, $a/@data-paragraph)
        let $db := xs:date(document:date($b))
        where $da le $db
        order by  $a/@data-similarity descending, document:id($a)
        return $a
};
