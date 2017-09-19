xquery version "3.0";

module namespace lang="http://nines.ca/exist/wilde/lang";

(:
    Language names must not contain spaces - they are used as
    attribute names in app:browse-date.
:)
declare function lang:code2lang($code) {
  switch($code) 
    case 'de' return 'German'
    case 'en' return 'English'
    case 'es' return 'Spanish'
    case 'fr' return 'French'
    case 'it' return 'Italian'
    default return 'Unknown code ' || $code
};

declare function lang:lang2code($code) {
  switch($code) 
    case 'German' return 'de'
    case 'English' return 'en'
    case 'Spanish' return 'es'
    case 'French' return 'fr'
    case 'Italian' return 'it'
    default return 'Unknown name' || $code
};

