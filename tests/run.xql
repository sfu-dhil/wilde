xquery version "3.1";

import module namespace xunit = "http://dhil.lib.sfu.ca/exist/xunit/xunit" at "lib/xunit.xql";

declare namespace inspect = "http://exist-db.org/xquery/inspection";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";
declare option output:indent "yes";

declare variable $serialization-opts := <output:serialization-parameters>
    <output:indent>yes</output:indent>
</output:serialization-parameters>;

declare function local:render-errors($results as element()) as element()? {
    let $testcases := $results//testcase[error]
    return
        if (count($testcases) > 0) then
            <div class="errors">
                <h3>Errors</h3>
                <ol> {
                    for $testcase in $testcases
                    return
                        <li>
                            In {$testcase/@module/string()} test {$testcase/@name/string()} at position {$testcase/error/@location/string()}<br/>
                            {$testcase/error/text()}
                        </li>
                } </ol>
            </div>
        else
            ()
};

declare function local:render-fails($results as element()) as element()? {
    let $testcases := $results//testcase[fail]
    return
        if (count($testcases) > 0) then
            <div class="fails">
                <h3>Failed Assertions</h3>
                <ol> {
                    for $testcase in $testcases
                    return
                        <li>In {$testcase/@module/string()} test {$testcase/@name/string()}:
                            <ol>{
                                for $fail in $testcase/fail
                                return
                                    <li>
                                        Assertion {$fail/@assert/string()} failed.<br/>
                                        {serialize($fail/expected, $serialization-opts)}<br/>
                                        {serialize($fail/actual, $serialization-opts)}
                                    </li>
                            } </ol>
                        </li>
                } </ol>
            </div>
        else
            ()
};

declare function local:render-skipped($results as element()) as element()? {
    let $testcases := $results//testcase[skipped]
    return
        if (count($testcases) > 0) then
            <div class="fails">
                <h3>Skipped Tests</h3>
                <ol> {
                    for $testcase in $results//testcase[skipped]
                    return
                        <li>
                            In {$testcase/@module/string()} test {$testcase/@name/string()}:<br/>
                            <i>{$testcase/skipped/@reason/string()}</i>
                        </li>
                } </ol>
            </div>
        else
            ()
};

let $tests := (
xs:anyURI('document-tests.xql'),
xs:anyURI('language-tests.xql'),
xs:anyURI('similarity-tests.xql')
)

let $results :=
try {
    xunit:test-suite($tests)
} catch * {
    <error
        uri="{namespace-uri-from-QName($err:code)}:{$err:code}">
        {$err:description}
        {$err:value}
    </error>
}

return
    <html>
        <head>
            <title>XUnit Test Suite</title>
        </head>
        <body>
            <h1>Results</h1>
            <ol> {
                for $test in $results/test
                return
                        <li>
                            {$test/@uri/string()}:
                            {$test/@count/string()} test cases.
                            {count($test/testcase[skipped])} skipped test cases.
                            {count($test/testcase[fail])} failed assertions.
                            {count($test/testcase[error])} errors.
                        </li>
            }</ol>
            {local:render-errors($results)}
            {local:render-fails($results)}
            {local:render-skipped($results)}
            <div style="display:none">
                <pre>
                    <code>
                        {serialize($results, $serialization-opts)}
                    </code>
                </pre>
            </div>
        </body>
    </html>