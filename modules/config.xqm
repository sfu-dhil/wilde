xquery version "3.0";

(:~
 : A set of helper functions and variables to access the application context from
 : within a module.
 :)
module namespace config="http://nines.ca/exist/wilde/config";

declare namespace templates="http://exist-db.org/xquery/templates";
declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";

(: 
  User auth variables 
:)
declare variable $config:login-domain := 'ca.nines.wilde';
declare variable $config:login-user := $config:login-domain || '.user';

(: 
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root := 
    let $rawPath := system:get-module-load-path()
	return 
       if(starts-with($rawPath, '/Applications/eXist-db/webapp')) then
         'file://' || substring-before($rawPath, '/modules')
       else 
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

(:
    Default string metric.
:)
declare variable $config:similarity-metric := 'levenshtein';

(:
    Minimum similarity level. Similarities less than this are discarded.
:)
declare variable $config:similarity-threshold := 0.6;

(:
    Minimum length for strings to be considered.
:)
declare variable $config:minimum-length := 25;

(:
    Number of search results per page.
:)
declare variable $config:search-results-per-page := 20;

(:
    Similarities to display per page. I think it's unused.
:)
declare variable $config:similarities-per-page := 50;

(:
    Path to the data collection.
:)
declare variable $config:data-root := "/db/apps/wilde-data/data/reports";

declare variable $config:graphs-root := "/db/apps/wilde-data/data/graphs";

declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
    if (starts-with($config:app-root, "/db")) then
        doc(concat($config:app-root, "/", $relPath))
    else
        doc(concat("file://", $config:app-root, "/", $relPath))
};

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    $config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    $config:expath-descriptor
};

(:~
 : Insert the application title into some HTML.
 : @param $node HTML node in the DOM to replace
 : @param $model Data model.
 : @return Content for the DOM as text.
 :)
declare 
    %templates:wrap 
function config:app-title($node as node(), $model as map(*)) as text() {
    $config:expath-descriptor/expath:title/text()
};

(:~
 : Insert the application configuration into some HTML.
 : @param $node HTML node in the DOM to replace
 : @param $model Data model.
 : @return Content for the DOM as HTML meta elements.
 :)
declare function config:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
declare function config:app-info($node as node(), $model as map(*)) {
    let $expath := config:expath-descriptor()
    let $repo := config:repo-descriptor()
    return
        <table class="app-info">
            <tr>
                <td>app collection:</td>
                <td>{$config:app-root}</td>
            </tr>
            {
                for $attr in ($expath/@*, $expath/*, $repo/*)
                return
                    <tr>
                        <td>{node-name($attr)}:</td>
                        <td>{$attr/string()}</td>
                    </tr>
            }
            <tr>
                <td>Controller:</td>
                <td>{ request:get-attribute("$exist:controller") }</td>
            </tr>
        </table>
};