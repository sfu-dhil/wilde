xquery version "3.0";

import module namespace config = "http://dhil.lib.sfu.ca/exist/wilde/config" at "config.xqm";

declare namespace request = "http://exist-db.org/xquery/request";
declare namespace session = "http://exist-db.org/xquery/session";
declare namespace system = "http://exist-db.org/xquery/system";

<debug>
  
  <config>
    <app-root>{$config:app-root}</app-root>
    <data-root>{$config:data-root}</data-root>
    <report-root>{$config:app-root}</report-root>
    <graph-root>{$config:graph-root}</graph-root>
    <thumb-root>{$config:thumb-root}</thumb-root>
    <image-root>{$config:image-root}</image-root>
    <pagination-window>{$config:pagination-window}</pagination-window>
    <pagination-size>{$config:pagination-size}</pagination-size>
    <repo-descriptor>{$config:repo-descriptor}</repo-descriptor>
    <expath-descriptor>{$config:expath-descriptor}</expath-descriptor>
  </config>
  
  <request>
    <context-path>{request:get-context-path()}</context-path>
    <effective-uri>{request:get-effective-uri()}</effective-uri>
    <hostname>{request:get-hostname()}</hostname>
    <path-info>{request:get-path-info()}</path-info>
    <query-string>{request:get-query-string()}</query-string>
    <scheme>{request:get-scheme()}</scheme>
    <uri>{request:get-uri()}</uri>
    <url>{request:get-url()}</url>
    <servlet-path>{request:get-servlet-path()}</servlet-path>
    
    <remote>
      <addr>{request:get-remote-addr()}</addr>
      <host>{request:get-remote-host()}</host>
      <port>{request:get-remote-port()}</port>
    </remote>
    <server>
      <name>{request:get-server-name()}</name>
      <port>{request:get-server-port()}</port>
    </server>
    
    <system>
      <instances-active>{system:count-instances-active()}</instances-active>
      <instances-available>{system:count-instances-available()}</instances-available>
      <instances-max>{system:count-instances-max()}</instances-max>
      <build>{system:get-build()}</build>
      <exist-home>{system:get-exist-home()}</exist-home>
      <module-path>{system:get-module-load-path()}</module-path>
      <revision>{system:get-revision()}</revision>
      <uptime>{system:get-uptime()}</uptime>
      <version>{system:get-version()}</version>
    </system>
    <attributes>
      {
        for $name in request:attribute-names()
          order by $name
        return
          <attribute name="{$name}" value="{request:get-attribute($name)}"/>
      }
    </attributes>
    
    <cookies>
      {
        for $name in request:get-cookie-names()
          order by $name
        return
          <cookie name="{$name}" value="{request:get-cookie-value($name)}"/>
      }
    </cookies>
    
    <headers>
      {
        for $name in request:get-header-names()
          order by $name
        return
          <header name="{$name}" value="{request:get-header($name)}"/>
      }
    </headers>
    
    <parameters>
      {
        for $name in request:get-parameter-names()
          order by $name
        return
          for $value in request:get-parameter($name, '')
            order by $value
          return
            <parameter name="{$name}" value="{$value}"/>
      }
    </parameters>
  
  </request>
</debug>
