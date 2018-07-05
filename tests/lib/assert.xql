xquery version "3.0";

module namespace assert="http://dhil.lib.sfu.ca/exist/xunit/assert";

declare function assert:equals($expected as item()*, $actual as item()*) as element() {
    if(deep-equal($expected, $actual)) then
        <pass />
    else
        <fail assert="equals">
            <expected>{$expected}</expected>
            <actual>{$actual}</actual>
        </fail>
};

declare function assert:not-equal($expected as item()*, $actual as item()*) as element() {
    if( not(deep-equal($expected, $actual))) then
        <pass />
    else
        <fail assert="not-equals">
            <expected>{$expected}</expected>
            <actual>{$actual}</actual>
        </fail>
};

declare function assert:count($expected as xs:int, $actual as item()*) as element() {
    if( $expected = count($actual)) then
        <pass />
    else
        <fail assert="count">
            <expected>{$expected}</expected>
            <actual>{$actual}</actual>
        </fail>
};

declare function assert:close($expected as xs:double, $tolerance as xs:double, $actual as xs:double) as element() {
    if(abs($expected - $actual) < $tolerance) then
        <pass />
    else
        <fail assert="close">
            <expected>{$expected} with tolerance {$tolerance}</expected>
            <actual>{$actual}</actual>
        </fail>
};

declare function assert:error($function as function(*), $error as xs:QName) as element() {
    let $out := try { 
        $function() 
    } catch * {
        if($error = $err:code) then
            <pass/>
        else
            <fail assert="error">
                <expected>{namespace-uri-from-QName($error)}:{$error}</expected>
                <actual>{namespace-uri-from-QName($err:code)}:{$err:code}</actual>
            </fail>
    }
    return
        if($out) then 
            $out
        else
            <fail>
                <exected>{$error}</exected>
                <actual></actual>
            </fail>            
};

declare function assert:error($function as function(*)) as element() {
    let $out := try { 
        $function() 
    } catch * {
        <pass/>
    }
    return
        if($out) then 
            $out
        else
            <fail assert="error">
                <exected>any error</exected>
                <actual></actual>
            </fail>            
};