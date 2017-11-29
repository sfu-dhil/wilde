xquery version "3.0";

module namespace meta="http://nines.ca/exist/wilde/meta";

declare namespace wilde = "http://dhil.lib.sfu.ca/wilde";

declare function meta:city($meta as node(), $publisher as xs:string) as xs:string? {
  $meta//wilde:newspaper[@title = $publisher]/@city/string()
};

declare function meta:language($meta as node(), $publisher as xs:string) as xs:string? {
  $meta//wilde:newspaper[@title = $publisher]/@language/string()
};

declare function meta:region($meta as node(), $publisher as xs:string) as xs:string? {
  substring-before($meta//wilde:newspaper[@title = $publisher]/@region/string(), ' Reports')
};

declare function meta:url($meta as node(), $publisher as xs:string) as xs:string? {
  $meta//wilde:newspaper[@title = $publisher]/@url/string()
};

declare function meta:sources($meta as node(), $publisher as xs:string) as xs:string* {
  for $source in $meta//wilde:newspaper[@title = $publisher]/wilde:source/@name/string()
  return $source
};

