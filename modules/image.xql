xquery version "3.0";

import module namespace config="http://dhil.lib.sfu.ca/exist/wilde-app/config" at "config.xqm";
import module namespace collection="http://dhil.lib.sfu.ca/exist/wilde-app/collection" at "collection.xql";

import module namespace console="http://exist-db.org/xquery/console";

let $filename := request:get-attribute('filename')
let $type := request:get-attribute('type')

return
  if(not(matches($filename, "^[a-zA-Z0-9% .'-]*$"))) then
    ()
  else
    let $path := switch($type)
        case 'thumb'
            return $config:thumb-root || '/' || $filename
        case 'image'
            return $config:image-root || '/' || $filename            
        default
            return ''

    let $image := util:binary-doc($path)
    let $mime := xmldb:get-mime-type($path)
    return response:stream-binary($image, $mime)
