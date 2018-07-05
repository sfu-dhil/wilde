xquery version "3.0";

module namespace xunit="http://dhil.lib.sfu.ca/exist/xunit/xunit";

import module namespace console="http://exist-db.org/xquery/console";

import module namespace assert="http://dhil.lib.sfu.ca/exist/xunit/assert" at "assert.xql";

declare namespace inspect="http://exist-db.org/xquery/inspection";

declare variable $xunit:skip := QName('http://dhil.lib.sfu.ca/exist/xunit/xunit', 'xunit:skip');
declare variable $xunit:test := QName('http://dhil.lib.sfu.ca/exist/xunit/xunit', 'xunit:test');
declare variable $xunit:error := QName('http://dhil.lib.sfu.ca/exist/xunit/xunit', 'xunit:error');

declare function xunit:find-annotation($function as function(*), $name as xs:QName) as element()* {
    let $meta := inspect:inspect-function($function)
    return
        for $annotation in $meta/annotation
            let $qn := QName($annotation/@namespace, $annotation/@name)
            where $qn = $name
            return $annotation
};

declare function xunit:function-uri($function as function(*)) as xs:string {
    let $meta := inspect:inspect-function($function)
    let $qname := QName($meta/@module, $meta/@name)
    return namespace-uri-from-QName($qname) || ":" || $qname
};

declare function xunit:call-skip($function as function(*), $skip as element()) {
    <skipped reason="{$skip ! string(value)}"/>
};

declare function xunit:call-error($function as function(*), $error as element()) {
    if(count($error/value) = 2) then
        let $name := QName($error/value[1], $error/value[2])
        return assert:error($function, $name)
    else
        assert:error($function)
};

declare function xunit:call-test($function as function(*)) {
    try {
        $function()
    } catch * {
        <error uri="{namespace-uri-from-QName($err:code)}:{$err:code}" module="{$err:module}" location="{$err:line-number}:{$err:column-number}">
            {$err:description}
            {$err:value}
        </error>
    }
};

declare function xunit:call($function as function(*)) {
    let $skip := xunit:find-annotation($function, $xunit:skip)
    let $error := xunit:find-annotation($function, $xunit:error)
    let $meta := inspect:inspect-function($function)
    
    return
        <testcase module="{$meta/@module}" name="{$meta/@name}"> {
            if(count($skip) > 0) then
                xunit:call-skip($function, $skip)            
            else if(count($error) > 0) then
                xunit:call-error($function, $error)
            else
                xunit:call-test($function)
        } </testcase>
};

declare function xunit:find-tests($uri as xs:anyURI) {
    for $function in inspect:module-functions($uri)
        let $test-annotations := xunit:find-annotation($function, $xunit:test)
        return
            if(count($test-annotations) = 0) then
                ()
            else
                $function
};

declare function xunit:test($uri as xs:anyURI) {
    let $functions := xunit:find-tests($uri)
    let $results := 
        for $function in $functions 
        return xunit:call($function)
    return 
        <test count="{count($functions)}" uri="{$uri}">
            { $results }
        </test>
};

declare function xunit:test-suite($uris as xs:anyURI*) as element() {
    <testsuite files="{count($uris)}"> {
        for $uri in $uris
        return xunit:test($uri)
    } </testsuite>
};
