xquery version "3.0";

module namespace publisher = "http://dhil.lib.sfu.ca/exist/wilde-app/publisher";

import module namespace collection = "http://dhil.lib.sfu.ca/exist/wilde-app/collection" at "collection.xql";

declare function publisher:list() as xs:string* {
  for $name in collection:publisher-index()//item/@name
    order by $name
  return
    $name
};

declare function publisher:name($id as xs:string) as xs:string? {
  collection:publisher-index()//item[@id = $id]/@name
};
