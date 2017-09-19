xquery version "3.0";

module namespace graph="http://nines.ca/exist/wilde/graph";

import module namespace config="http://nines.ca/exist/wilde/config" at "config.xqm";
import module namespace functx='http://www.functx.com';

declare namespace gexf='http://www.gexf.net/1.1draft';
declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare default element namespace "http://www.w3.org/1999/xhtml";

declare function graph:filename($node as node()) as xs:string {
  util:document-name(root($node))
};

declare function graph:title($node as node()) as xs:string {
  let $filename := graph:filename($node)
  return fn:substring-before($filename, '.gexf')
};

declare function graph:description($node as node()) as xs:string {
  let $text := root($node)//gexf:meta/gexf:description/text()
  return if($text) then
    $text
  else
    'No description provided.'
};

declare function graph:modified($node as node()) as xs:string {
  root($node)//gexf:meta[@lastmodifieddate]/string()
};

declare function graph:creator($node as node()) as xs:string {
  root($node)//gexf:meta/gexf:creator/text()
};
