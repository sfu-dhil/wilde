xquery version "3.1";

import module namespace collection="http://dhil.lib.sfu.ca/exist/wilde-app/collection" at "modules/collection.xql";

declare namespace exist="http://exist.sourceforge.net/NS/exist";
declare namespace request="http://exist-db.org/xquery/request";

declare default element namespace 'http://exist.sourceforge.net/NS/exist';

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

if ($exist:path eq '') then
    <dispatch>
        <redirect url="{request:get-uri()}/index.html"/>
    </dispatch>

else if ($exist:path eq "/") then
    <dispatch>
        <redirect url="index.html"/>
    </dispatch>

else if($exist:path eq "/list.html") then
    <dispatch>
        <cache-control cache="yes"/>
    </dispatch>
  
else if (ends-with($exist:resource, ".html")) then
    (: the html page is run through view.xql to expand templates :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <view>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </view> 
    </dispatch>

else if (ends-with($exist:resource, ".gexf")) then
  collection:graph($exist:resource)

else if(contains($exist:path, "/export/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/export.xql">
            <set-attribute name="function" value="{substring-after($exist:path, '/export/')}"/>
        </forward>
    </dispatch>

else if(contains($exist:path, "/api/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/api-public.xql">
            <set-attribute name="function" value="{substring-after($exist:path, '/api/')}"/>
        </forward>
    </dispatch>

else
    (: everything else is passed through :)
    <dispatch>
        <cache-control cache="yes"/>
    </dispatch>
