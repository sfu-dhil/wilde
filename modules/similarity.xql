xquery version "3.0";

module namespace similarity="http://nines.ca/exist/wilde/similarity";

import module namespace functx="http://www.functx.com"; 
import module namespace math="http://exist-db.org/xquery/math";
import module namespace config="http://nines.ca/exist/wilde/config" at "config.xqm";

(: 
  Sadly, the eXist 2.2 normalize-unicode() function is broken. So we call out
  to the java one.
:)
declare namespace normalizer = "java:java.text.Normalizer";
declare namespace form = "java:java.text.Normalizer$Form";

declare namespace string="java:org.apache.commons.lang3.StringUtils";
declare namespace locale="java:java.util.Locale";

declare function similarity:normalize($string as item(), $clean) as xs:string {
    (:  Sigh. eXist 2.2 has a bug that mucks up encoded entities when going to/from 
        java. So to work around it, text must have double-encoded entities. :) 
    let $doubleEncoded := replace($string, '&amp;', '&amp;amp;')
    let $unicode := normalizer:normalize($doubleEncoded, form:value-of('NFD'))
    let $space := normalize-space($unicode)
    let $lower := lower-case($space)
    return 
      if( not($clean)) then
        $lower
      else
        replace($lower, '[^a-zA-Z0-9 -]', '')
};

declare function similarity:normalize($string as item()) as xs:string {
  similarity:normalize($string, false())
};

declare function similarity:word-list($str as xs:string) as xs:string* {
    for $w in tokenize($str, '\W+')
    return if(string-length($w) gt 0) then $w else ()
};

declare function similarity:levenshtein($a, $b) as xs:double { 
    let $maxLength := max((string-length($a), string-length($b)))
    let $minLength := min((string-length($a), string-length($b)))
    let $limit := $maxLength * (1.0 - $config:similarity-threshold)
    
    return 
        if(($maxLength - $minLength) gt ((1 - $config:similarity-threshold) * $maxLength)) then
            (: the paragraphs differ in size by too much. :)
            0
        else if($minLength lt $config:minimum-length) then
            (: small paragraphs not worth it. :)
            0
        else
            let $d := string:getLevenshteinDistance($a, $b, $limit)
            return 
                if($d < 0) then
                    (: string:getLevenshteinDistance will return -1 if there are more changes that $limit :)
                    0
                else
                    (: convert the distance into a similarity percentage. :)
                    1 - $d div $maxLength
};

declare function similarity:dot-product($x as xs:double*, $y as xs:double*) as xs:double {
    let $p := 
        for $i in 1 to min((count($x), count($y)))
        return $x[$i] * $y[$i]
    return sum($p)
};

declare function similarity:magnitude($x as xs:double*) as xs:double {
    sum(for $v in $x return $v * $v)
};

declare function similarity:cosine($p as xs:string, $q as xs:string) {
    let $w1 := similarity:word-list($p)
    let $w2 := similarity:word-list($q)
    let $W := distinct-values(($w1, $w2))
    let $v1 := for $w in $W return count(index-of($w1, $w))
    let $v2 := for $w in $W return count(index-of($w2, $w))
    let $dot := similarity:dot-product($v1, $v2)
    let $V1 := similarity:magnitude($v1)
    let $V2 := similarity:magnitude($v2)        
    return $dot div math:sqrt($V1 * $V2)
};

declare function similarity:jaccard($p as xs:string, $q as xs:string) as xs:double {
    let $w1 := similarity:word-list($p)
    let $w2 := similarity:word-list($q)
    let $union := distinct-values(($w1, $w2))
    let $intersect := functx:value-intersect($w1, $w2)
    return count($intersect) div count($union) 
};

(: http://en.wikipedia.org/wiki/Overlap_coefficient :)
declare function similarity:overlap($p as xs:string, $q as xs:string) as xs:double {
    let $w1 := similarity:word-list($p)
    let $w2 := similarity:word-list($q)
    let $intersect := functx:value-intersect($w1, $w2)
    return count($intersect) div min((count($w1), count($w2)))
};

declare function similarity:compressed-string-size($x as xs:string) as xs:integer {
    let $x := similarity:normalize($x, true())
    
    let $bx := util:base64-encode($x) cast as xs:base64Binary
    let $cx := compression:gzip($bx)
    let $sx := $cx cast as xs:string
    let $lx := string-length($sx)
    return $lx
};

declare function similarity:compression($x as xs:string, $y as xs:string) {
    let $cxy := similarity:compressed-string-size($x || $y)
    let $cx :=  similarity:compressed-string-size($x)
    let $cy :=  similarity:compressed-string-size($y)
    
    return 1 - ($cxy - min(($cx, $cy))) div max(($cx, $cy))   
};

declare function similarity:available() {
    ('compression', 'jaccard', 'cosine', 'levenshtein', 'overlap')
};

declare function similarity:similarity($type as xs:string, $a, $b) as xs:double {
    let $ta := similarity:normalize($a, true())
    let $tb := similarity:normalize($b, true())
    return 
        if($ta = '' or $tb ='') then
            0
        else 
            switch($type)
                case 'compression' 
                    return similarity:compression($ta, $tb)
                case 'jaccard' 
                    return similarity:jaccard($ta, $tb)
                case 'cosine' 
                    return similarity:cosine($ta, $tb)
                case 'levenshtein' 
                    return similarity:levenshtein($ta, $tb)
                case 'overlap'
                    return similarity:overlap($ta, $tb)
                default 
                    return -1
};

