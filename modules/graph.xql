xquery version "3.0";

module namespace graph="http://dhil.lib.sfu.ca/exist/wilde-app/graph";

import module namespace config="http://dhil.lib.sfu.ca/exist/wilde-app/config" at "config.xqm";
import module namespace functx='http://www.functx.com';

import module namespace console="http://exist-db.org/xquery/console";

declare namespace gexf='http://www.gexf.net/1.3';
declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare default element namespace "http://www.w3.org/1999/xhtml";

declare function graph:filename($node as node()) as xs:string {
  util:document-name(root($node))
};

declare function graph:title($node as node()) as xs:string {
  let $filename := graph:filename($node)
  let $basename := fn:substring-before($filename, '.gexf')
  let $decoded := util:unescape-uri($basename, 'utf-8')
  return $decoded
};

declare function graph:description($node as node()) as xs:string {
  let $text := root($node)//gexf:meta/gexf:description/text()
  return if($text) then
    $text
  else
    'No description provided.'
};

declare function graph:modified($node as node()) as xs:string* {
    let $null := console:log(graph:filename($node))
    
  let $text := root($node)//gexf:meta/@lastmodifieddate
  return if($text) then
    $text
  else
    'No description provided.'
};

declare function graph:creator($node as node()) as xs:string {
  root($node)//gexf:meta/gexf:creator/text()
};
