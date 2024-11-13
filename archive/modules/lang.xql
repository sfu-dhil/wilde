xquery version "3.0";

module namespace lang = "http://dhil.lib.sfu.ca/exist/wilde/lang";

import module namespace functx = 'http://www.functx.com';

(:
    Language codes must not contain spaces - they are used as
    attribute names in app:browse-date.
:)
declare function lang:code2lang($codes as xs:string*) as xs:string* {
  let $names :=
    for $code in $codes
      return
        switch ($code)
          case 'de'
            return 
              'German'
          case 'en'
            return
              'English'
          case 'es'
            return
              'Spanish'
          case 'fr'
            return
              'French'
          case 'it'
            return
              'Italian'
          case 'any'
            return
              'any'
          default return
            'Unknown code ' || $code
  return
    functx:sort($names)
};

declare function lang:lang2code($codes as xs:string*) as xs:string* {
  let $codes :=
    for $code in $codes
      return
        switch ($code)
          case 'German'
            return
              'de'
          case 'English'
            return
              'en'
          case 'Spanish'
            return
              'es'
          case 'French'
            return
              'fr'
          case 'Italian'
            return
              'it'
          default return
            'Unknown name ' || $code
  return
    functx:sort($codes)
};
