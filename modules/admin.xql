xquery version "3.0";

module namespace admin="http://nines.ca/exist/wilde/admin";

import module namespace kwic="http://exist-db.org/xquery/kwic";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://nines.ca/exist/wilde/config" at "config.xqm";
import module namespace collection="http://nines.ca/exist/wilde/collection" at "collection.xql";
import module namespace document="http://nines.ca/exist/wilde/document" at "document.xql";
import module namespace similarity="http://nines.ca/exist/wilde/similarity" at "similarity.xql";
import module namespace index="http://nines.ca/exist/wilde/index" at "index.xql";
import module namespace tx="http://nines.ca/exist/wilde/transform" at "transform.xql";
import module namespace lang="http://nines.ca/exist/wilde/lang" at "lang.xql";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";

declare namespace xhtml='http://www.w3.org/1999/xhtml';
declare default element namespace "http://www.w3.org/1999/xhtml";

(:Check if the HTTP request has the named attribute and is true.:)
declare function admin:if-attribute-set($node as node(), $model as map(*), $attribute as xs:string) {
    let $isSet :=
        (exists($attribute) and request:get-attribute($attribute))
    return
        if ($isSet) then
            templates:process($node/node(), $model)
        else
            ()
};

(:Check if the HTTP request does not have the named attribute:)
declare function admin:if-attribute-unset($node as node(), $model as map(*), $attribute as xs:string) { 
    let $isSet :=
        (exists($attribute) and request:get-attribute($attribute))
    return
        if (not($isSet)) then
            templates:process($node/node(), $model)
        else
            ()
};

(:Return the current user name.:)
declare function admin:username($node as node(), $model as map(*)) {
    let $user:= request:get-attribute($config:login-user)
    let $name := if ($user) then sm:get-account-metadata($user, xs:anyURI('http://axschema.org/namePerson')) else 'Guest'
    return if ($name) then $name else $user
};

(:Return the current user info as a map.:)
declare 
    %templates:wrap
function admin:userinfo($node as node(), $model as map(*)) as map(*) {
    let $user:= request:get-attribute($config:login-user)
    let $name := if ($user) then sm:get-account-metadata($user, xs:anyURI('http://axschema.org/namePerson')) else 'Guest'
    let $group := if ($user) then sm:get-user-groups($user) else 'guest'
    return
        map { "user-id" := $user, "user-name" := $name, "user-groups" := $group}
};

declare function admin:load($node as node(), $model as map(*)) {
    let $f := request:get-parameter('f', '')
    let $doc := collection:fetch($f)
    
    (: the parse/serialize is necessary here, as a document may be deleted,
       and this frees the variable from the deletion. :)
    return map {
        "doc-id" := $f,
        "document" := parse-xml(serialize($doc))
    }
};

declare function admin:link-view($id as xs:string, $content) as node() {
    <a href="view.html?f={$id}">{$content}</a>
};

declare function admin:link-edit($node as node(), $model as map(*)) as node() {
    let $document := $model('document')
    return <a class='btn btn-primary' href="edit.html?f={document:id($document)}">Edit</a>
};

declare function admin:link-save($node as node(), $model as map(*)) as node() {
    let $document := $model('document')
    return <a class='btn btn-primary' href="save.html?f={document:id($document)}">Save</a>
};

declare function admin:link-delete($node as node(), $model as map(*)) as node() {
    let $document := $model('document')
    return <a class='btn btn-danger' href="delete.html?f={document:id($document)}">Delete</a>
};

declare function admin:browse($node as node(), $model as map(*)) as node() {
    let $documents := collection:documents()
    return
        <table class='table table-striped table-hover table-condensed' id="tbl-browser">
            <thead>
                <tr>
                    <th>Date</th>
                    <th>Language</th>
                    <th>Region</th>
                    <th>Title</th>
                    <th>Indexed</th>
                </tr>
            </thead>
            <tbody>{
                for $document in $documents
                return <tr>
                    <td>{admin:link-view(document:id($document), string(document:date($document)))}</td>
                    <td>{document:language($document)}</td>
                    <td>{document:region($document)}</td>
                    <td>{document:title($document)}</td>
                    <td>{document:indexed-document($document)}/{document:indexed-paragraph($document)}</td>
                </tr>
            }</tbody>
        </table>
};

declare function admin:doc-translation-tabs($node as node(), $model as map(*)) as node()* {
  <ul class="nav nav-tabs" role="tablist">
    <li role="presentation" class="active">
      <a href="#original" role="tab" data-toggle="tab">
        {lang:code2lang(document:language($model('document')))}
      </a>
    </li> 
    { 
      for $lang in document:translations($model('document'))
      return   
        <li role="presentation">
          <a href="#{$lang}" role="tab" data-toggle="tab">{lang:code2lang($lang)}</a>
        </li>
    }
  </ul>
};

declare function admin:doc-translations($node as node(), $model as map(*)) as node()* {
  let $doc := $model('document')
  return  
    <div class="tab-content">
      <div role="tabpanel" class="tab-pane active" id="original">
        { $doc//div[@id='original'] }
      </div>
      { 
        for $lang in document:translations($model('document'))
        return   
        <div role="tabpanel" class="tab-pane" id="{$lang}">
          { $doc//div[@lang=$lang] }
        </div>
      }
    </div>
};


declare function admin:doc-content($node as node(), $model as map(*)) as node()* {
    $model('document')//body/div[@id='original']/node()
};

declare function admin:doc-delete($node as node(), $model as map(*)) {
  let $f := request:get-parameter('f', '')
  let $document := collection:fetch($f)
  let $filename := document:filename($document)
  let $collection-path := $config:data-root || '/' || document:collection($document)
  
  let $collection := collection:collection()
  let $null := update delete $collection//link[@href=$f]
  let $null := update delete $collection//a[@data-document=$f]
  
  let $return := xmldb:remove($collection-path, $filename)
  
  return "The document has been deleted. It is shown here for your records."
};

declare function admin:id-input($node as node(), $model as map(*)) {
  <input type='hidden' name='doc-id' id='doc-id' value='{document:id($model('document'))}'/>
};

declare function admin:date-input($node as node(), $model as map(*)) {
  let $date := 
    if($model('document')) then document:date($model('document')) else '1895-04-01'
  
  return
    <div class='form-group'>
      <label for='date'>Date Published</label>
      <input type='date' class='form-control' name='date' id='date' value='{$date}' />
    </div>
};

declare function admin:publisher-input($node as node(), $model as map(*)) {
  let $publisher :=
    if($model('document')) then document:publisher($model('document')) else ''

  return
    <div class='form-group'>
      <label for='publisher'>Publisher</label>
      <input type='text' class='form-control typeahead' name='publisher' id='publisher' value='{$publisher}' data-typeahead-url="../api/publishers"/>
    </div>
};

declare function admin:status-input($node as node(), $model as map(*)) {
  let $status :=
    if($model('document')) then document:status($model('document')) else 'draft'
    
  return  
  <div class='form-group'>
    <label for='status'>Status</label>
    <input type='text' class='form-control typeahead' name='status' id='status' value='{$status}' data-typeahead-url="../api/statuses" />
  </div>
};
declare function admin:region-input($node as node(), $model as map(*)) {
  let $region :=
    if($model('document')) then document:region($model('document')) else ''
    
  return  
  <div class='form-group'>
    <label for='region'>Region</label>
    <input type='text' class='form-control typeahead' name='region' id='region' value='{$region}' data-typeahead-url="../api/regions" />
  </div>
};

declare function admin:title-input($node as node(), $model as map(*)) {
  let $title :=
    if($model('document')) then document:title($model('document')) else ''
    
  return
  <div class='form-group'>
    <label for='title'>Title</label>
    <input type='text' class='form-control' name='title' id='title'  value='{$title}' />
  </div>
};

declare function admin:language-input($node as node(), $model as map(*)) {
  let $language :=
    if($model('document')) then document:language($model('document')) else ''
    
  return
  <div class='form-group'>
    <label for='language'>Language</label>
    <input type='text' class='form-control typeahead' name='language' id='language'  value='{lang:code2lang($language)}' data-typeahead-url="../api/languages" />
  </div>
};

declare function admin:city-input($node as node(), $model as map(*)) {
  let $city :=
    if($model('document')) then document:city($model('document')) else ''
    
  return
  <div class='form-group'>
    <label for='city'>City</label>
    <input type='text' class='form-control typeahead' name='city' id='city'  value='{$city}' data-typeahead-url="../api/cities" />
  </div>
};

declare function admin:source-input($node as node(), $model as map(*)) {
  let $source :=
    if($model('document')) then document:source($model('document')) else ''
    
  return
  <div class='form-group'>
    <label for='city'>Source</label>
    <input type='text' class='form-control' name='source' id='source'  value='{$source}' />
  </div>
};
