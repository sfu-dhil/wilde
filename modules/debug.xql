xquery version "3.0";

module namespace debug="http://nines.ca/exist/wilde/debug";

declare namespace request="http://exist-db.org/xquery/request";
declare namespace session="http://exist-db.org/xquery/session";
declare namespace system="http://exist-db.org/xquery/system";

declare function debug:debug() as node() {
  <debug>
    <request>
      <context-path>{ request:get-context-path() }</context-path>
      <effective-uri>{ request:get-effective-uri() }</effective-uri>
      <hostname>{ request:get-hostname() }</hostname>
      <path-info>{ request:get-path-info() }</path-info>
      <query-string>{ request:get-query-string() }</query-string>
      <scheme>{ request:get-scheme() }</scheme>
      <uri>{ request:get-uri() }</uri>
      <url>{ request:get-url() }</url>
      <servlet-path>{ request:get-servlet-path() }</servlet-path>
      
      <remote>
        <addr>{ request:get-remote-addr() }</addr>
        <host>{ request:get-remote-host() }</host>
        <port>{ request:get-remote-port() }</port>
      </remote>
      <server>
        <name>{ request:get-server-name() }</name>
        <port>{ request:get-server-port() }</port>
      </server>
      
      <session>
        <created>{ session:get-creation-time() }</created>
        <id>{ session:get-id() }</id>
        <last-accessed>{ session:get-last-accessed-time() }</last-accessed>
        <max-inactive>{ session:get-max-inactive-interval() } seconds</max-inactive>
        <attributes> {
            for $name in session:get-attribute-names()
            return <attribute name="{$name}" value="{session:get-attribute($name)}"/>
        } </attributes>
      </session>
      <system>
        <instances-active>{ system:count-instances-active() }</instances-active>
        <instances-available>{ system:count-instances-available() }</instances-available>
        <instances-max>{ system:count-instances-max() }</instances-max>
        <build>{ system:get-build() }</build>
        <exist-home>{ system:get-exist-home() }</exist-home>
        <module-path>{ system:get-module-load-path() }</module-path>
        <revision>{ system:get-revision() }</revision>
        <uptime>{ system:get-uptime() }</uptime>
        <version>{ system:get-version() }</version>
      </system>
      <attributes> {
        for $name in request:attribute-names()
        order by $name
        return <attribute name="{$name}" value="{request:get-attribute($name)}"/>
      } </attributes>
      
      <cookies> {
        for $name in request:get-cookie-names()
        order by $name
        return <cookie name="{$name}" value="{request:get-cookie-value($name)}"/>
      } </cookies>
      
      <headers> {
        for $name in request:get-header-names()
        order by $name
        return <header name="{$name}" value="{request:get-header($name)}"/>
      } </headers>
      
      <parameters> {
        for $name in request:get-parameter-names()
        order by $name
        return
          for $value in request:get-parameter($name, '')
          order by $value
          return <parameter name="{$name}" value="{$value}" />
      } </parameters>
      
    </request>
  </debug>
};