xquery version "3.0";

import module namespace console="http://exist-db.org/xquery/console";
import module namespace config="http://nines.ca/exist/wilde/config" at "../modules/config.xqm";
import module namespace login="http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace functx="http://www.functx.com";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

let $logout := request:get-parameter('logout', ())
let $set-user := login:set-user($config:login-domain, '/exist/apps/wilde', 'P14D', false())

return
if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>
    
    
else if ($exist:path eq "/") then
    (: forward root path to index.xql :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>

else if (ends-with($exist:resource, ".html")) then
    if (request:get-attribute($config:login-user)) then
    (: the html page is run through view.xql to expand templates :)
      <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <view>
            <forward url="{$exist:controller}/../modules/view.xql">
                <set-attribute name="isAdmin" value="true"/>
                <set-attribute name="$exist:prefix" value="{$exist:prefix}"/>
                <set-attribute name="$exist:controller" value="{$exist:controller}"/>
            </forward>
        </view>
    		<error-handler>
    			<forward url="{$exist:controller}/../error-page.html" method="get"/>
    			<forward url="{$exist:controller}/../modules/view.xql"/>
    		</error-handler>
      </dispatch>
    else
      <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
          <!-- This forwards the entry to the content page blog.html -->
          <forward url="{$exist:controller}/security.html"/>
          <!-- This send the page through the templating process -->
          <view>
              <forward url="{$exist:controller}/../modules/view.xql">
                  <set-attribute name="$exist:prefix" value="{$exist:prefix}"/>
                  <set-attribute name="$exist:controller" value="{$exist:controller}"/>
              </forward>
          </view>
          <error-handler>
              <forward url="{$exist:controller}/../error-page.html" method="get"/>
              <forward url="{$exist:controller}/../modules/view.xql"/>
          </error-handler>
      </dispatch>
        
(: Resource paths starting with $shared are loaded from the shared-resources app :)
else if (contains($exist:path, "/$shared/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/shared-resources/{substring-after($exist:path, '/$shared/')}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>
    
else if(contains($exist:path, "/api/")) then
  if(request:get-attribute($config:login-user)) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/../modules/api.xql">
            <set-attribute name="function" value="{substring-after($exist:path, '/api/')}"/>
        </forward>
    </dispatch>
  else
    <result code="403">403 - NOT AUTHORIZED.</result>

else if(contains($exist:path, "/export/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/export.xql">
            <set-attribute name="function" value="{substring-after($exist:path, '/export/')}"/>
        </forward>
    </dispatch>


else
    (: everything else is passed through :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
