xquery version "3.0";

module namespace doctest="http://dhil.lib.sfu.ca/exist/wilde-app/doctest";

import module namespace console="http://exist-db.org/xquery/console";

import module namespace xunit="http://dhil.lib.sfu.ca/exist/xunit/xunit" at "xunit.xql";
import module namespace assert="http://dhil.lib.sfu.ca/exist/xunit/assert" at "assert.xql";

import module namespace doc="http://dhil.lib.sfu.ca/exist/wilde-app/document" at "../../modules/document.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare 
    %xunit:test
function doctest:id() {
    let $doc := <html id="abc"><head><title>T1</title></head></html>
    return (
        assert:equals('abc', doc:id($doc)),
        assert:equals('abc', doc:id($doc//title))        
    )
};

declare 
    %xunit:test
function doctest:id-child() {
    let $doc := <html id='cheese'><head><title>T1</title></head></html>
    return assert:equals('cheese', doc:id($doc//title))
};

declare 
    %xunit:test
    %xunit:skip('XML IDs are not implemented yet.')
function doctest:xmlids() {
    let $doc := <html xml:id='cheese'><head><title>T1</title></head></html>
    return assert:equals('cheese', doc:id($doc))
};

declare
    %xunit:test
function doctest:title() {
    let $doc := <html><head><title>T1</title></head><body></body></html>
    return (
        assert:equals('T1', doc:title($doc)),
        assert:equals('T1', doc:title($doc//body))
    )
};

declare
    %xunit:test
function doctest:empty-title() {
    let $doc := <html><head><title></title></head><body><p>foo</p></body></html>
    return (
        assert:equals('(unknown title)', doc:title($doc)),
        assert:equals('(unknown title)', doc:title($doc//p))
    )
};

declare
    %xunit:test
function doctest:missing-title() {
    let $doc := <html><head></head><p>foo</p></html>
    return (
        assert:equals('(unknown title)', doc:title($doc)),
        assert:equals('(unknown title)', doc:title($doc//p))
    )
};

declare 
    %xunit:test
function doctest:subtitle() {
    let $doc := <html><head></head><body><p>foo</p><p>bar</p></body></html>
    return (
        assert:equals('foo', doc:subtitle($doc)),
        assert:equals('foo', doc:subtitle($doc//p[2]))
    )
};
    
declare 
    %xunit:test
function doctest:path() {
    let $doc := <html><head><meta name="wr.path" content="foo"/></head><body></body></html>
    return (
        assert:equals('foo', doc:path($doc)),
        assert:equals('foo', doc:path($doc//body))
    )
};

declare 
    %xunit:test
function doctest:missing-path() {
    let $doc := <html><head></head><body></body></html>
    return (
        assert:equals('', doc:path($doc)),
        assert:equals('', doc:path($doc//body))
    )
};

declare 
    %xunit:test
function doctest:word-count() {
    let $doc := <html><head><meta name="wr.wordcount" content="foo"/></head><body></body></html>
    return (
        assert:equals('foo', doc:word-count($doc)),
        assert:equals('foo', doc:word-count($doc//body))
    )
};

declare 
    %xunit:test
function doctest:missing-word-count() {
    let $doc := <html><head></head><body></body></html>
    return (
        assert:equals('', doc:word-count($doc)),
        assert:equals('', doc:word-count($doc//body))
    )
};

declare 
    %xunit:test
function doctest:date() {
    let $doc := <html><head><meta name="dc.date" content="foo"/></head><body></body></html>
    return (
        assert:equals('foo', doc:date($doc)),
        assert:equals('foo', doc:date($doc//body))
    )
};

declare 
    %xunit:test
function doctest:missing-date() {
    let $doc := <html><head></head><body></body></html>
    return (
        assert:equals('', doc:date($doc)),
        assert:equals('', doc:date($doc//body))
    )
};

declare 
    %xunit:test
function doctest:publisher() {
    let $doc := <html><head><meta name="dc.publisher" content="foo"/></head><body></body></html>
    return ( 
        assert:equals('foo', doc:publisher($doc)),
        assert:equals('foo', doc:publisher($doc//body))
    )
};

declare 
    %xunit:test
function doctest:missing-publisher() {
    let $doc := <html><head></head><body></body></html>
    return (
        assert:equals('', doc:publisher($doc)),
        assert:equals('', doc:publisher($doc//body))
    )
};

declare 
    %xunit:test
function doctest:edition() {
    let $doc := <html><head><meta name="dc.publisher.edition" content="foo"/></head><body></body></html>
    return (
        assert:equals('foo', doc:edition($doc)),
        assert:equals('foo', doc:edition($doc//body))
    )
};

declare 
    %xunit:test
function doctest:missing-edition() {
    let $doc := <html><head></head><body></body></html>
    return (
        assert:equals('', doc:edition($doc)),
        assert:equals('', doc:edition($doc//body))
    )
};


declare 
    %xunit:test
function doctest:region() {
    let $doc := <html><head><meta name="dc.region" content="foo"/></head><body></body></html>
    return (
        assert:equals('foo', doc:region($doc)),
        assert:equals('foo', doc:region($doc//body))
    )
};

declare 
    %xunit:test
function doctest:missing-region() {
    let $doc := <html><head></head><body></body></html>
    return (
        assert:equals('', doc:region($doc)),
        assert:equals('', doc:region($doc//body))
    )
};

declare 
    %xunit:test
function doctest:document-matches() {
    let $doc := 
        <html>
            <head>
                <link rel='similarity' href='foo'/>
                <link rel='other' href="bar"/>
            </head>
            <body/>
        </html>
    let $matches := doc:document-matches($doc)
    return (
        assert:count(1, $matches),
        assert:equals('foo', $matches[1]/@href/string())
    )        
};
 
declare 
    %xunit:test
function doctest:paragraph-matches() {
    let $doc := 
        <html>
            <body>
                <div id="original">
                    <a href="bar"/>
                    <a href="foo" class="similarity"/>
                </div>
                <div class="translated">
                    <a href="bario"/>
                    <a href="foorio" class="similarity"/>
                </div>
            </body>
        </html>
    let $matches := doc:paragraph-matches($doc)
    return (
        assert:count(1, $matches),
        assert:equals('foo', $matches[1]/@href/string())
    )
        
};
    
declare 
    %xunit:test
function doctest:city() {
    let $doc := <html><head><meta name="dc.region.city" content="foo"/></head><body></body></html>
    return (
        assert:equals('foo', doc:city($doc)),
        assert:equals('foo', doc:city($doc//body))
    )
};

declare 
    %xunit:test
function doctest:city-multiple() {
    let $doc := <html><head><meta name="dc.region.city" content="foo"/><meta name="dc.region.city" content="bar"/></head><body></body></html>
    return (
        assert:equals('foo', doc:city($doc)),
        assert:equals('foo', doc:city($doc//body))
    )
};

declare 
    %xunit:test
function doctest:source() {
    let $doc := <html><head><meta name="dc.source" content="foo"/></head><body></body></html>
    return (
        assert:equals(('foo'), doc:source($doc)),
        assert:count(1, doc:source($doc//body))
    )
};


declare 
    %xunit:test
function doctest:source-multiple() {
    let $doc := <html><head><meta name="dc.source" content="foo"/><meta name="dc.source" content="bar"/></head><body></body></html>
    return (
        assert:equals(('foo', 'bar'), doc:source($doc)),
        assert:equals(('foo', 'bar'), doc:source($doc//body))
    )
};

declare 
    %xunit:test
function doctest:source-institution() {
    let $doc := <html><head><meta name="dc.source.institution" content="foo"/></head><body></body></html>
    return (
        assert:equals(('foo'), doc:source-institution($doc)),
        assert:count(1, doc:source-institution($doc//body))
    )
};


declare 
    %xunit:test
function doctest:source-institution-multiple() {
    let $doc := <html><head><meta name="dc.source.institution" content="foo"/><meta name="dc.source.institution" content="bar"/></head><body></body></html>
    return (
        assert:equals(('foo', 'bar'), doc:source-institution($doc)),
        assert:equals(('foo', 'bar'), doc:source-institution($doc//body))
    )
};


declare 
    %xunit:test
function doctest:source-url() {
    let $doc := <html><head><meta name="dc.source.url" content="foo"/></head><body></body></html>
    return (
        assert:equals(('foo'), doc:source-url($doc)),
        assert:count(1, doc:source-url($doc//body))
    )
};

declare 
    %xunit:test
function doctest:source-url-multiple() {
    let $doc := <html><head><meta name="dc.source.url" content="foo"/><meta name="dc.source.url" content="bar"/></head><body></body></html>
    return (
        assert:equals(('foo', 'bar'), doc:source-url($doc)),
        assert:equals(('foo', 'bar'), doc:source-url($doc//body))
    )
};

declare 
    %xunit:test
function doctest:source-database() {
    let $doc := <html><head><meta name="dc.source.database" content="foo"/></head><body></body></html>
    return (
        assert:equals(('foo'), doc:source-database($doc)),
        assert:count(1, doc:source-database($doc//body))
    )
};

declare 
    %xunit:test
function doctest:source-database-multiple() {
    let $doc := <html><head><meta name="dc.source.database" content="foo"/><meta name="dc.source.database" content="bar"/></head><body></body></html>
    return (
        assert:equals(('foo', 'bar'), doc:source-database($doc)),
        assert:equals(('foo', 'bar'), doc:source-database($doc//body))
    )
};

declare 
    %xunit:test
function doctest:facsimile() {
    let $doc := <html><head><meta name="dc.source.facsimile" content="foo"/></head><body></body></html>
    return (
        assert:equals(('foo'), doc:facsimile($doc)),
        assert:count(1, doc:facsimile($doc//body))
    )
};


declare 
    %xunit:test
function doctest:facsimile-multiple() {
    let $doc := <html><head><meta name="dc.source.facsimile" content="foo"/><meta name="dc.source.facsimile" content="bar"/></head><body></body></html>
    return (
        assert:equals(('foo', 'bar'), doc:facsimile($doc)),
        assert:equals(('foo', 'bar'), doc:facsimile($doc//body))
    )
};

declare 
    %xunit:test
function doctest:language() {
    let $doc := <html><head><meta name="dc.language" content="foo"/></head><body></body></html>
    return (
        assert:equals('foo', doc:language($doc)),
        assert:equals('foo', doc:language($doc//body))
    )
};

declare 
    %xunit:test
function doctest:language-multiple() {
    let $doc := <html><head><meta name="dc.language" content="foo"/><meta name="dc.language" content="bar"/></head><body></body></html>
    return (
        assert:equals('foo', doc:language($doc)),
        assert:equals('foo', doc:language($doc//body))
    )
};


declare 
    %xunit:test
function doctest:translations() {
    let $doc := <html><head></head><body><div class='translation' lang='foo'/></body></html>
    return (
        assert:equals(('foo'), doc:translations($doc)),
        assert:equals(('foo'), doc:translations($doc//body))
    )
};

declare 
    %xunit:test
function doctest:translations-multiple() {
    let $doc := <html><head></head><body><div class='translation' lang='foo'/><div class='translation' lang='bar'/></body></html>
    return (
        assert:equals(('foo', 'bar'), doc:translations($doc)),
        assert:equals(('foo', 'bar'), doc:translations($doc//body))
    )
};

declare 
    %xunit:test
function doctest:count-translations() {
    let $doc := <html><head></head><body><div class='translation' lang='foo'/><div class='translation' lang='bar'/></body></html>
    return (
        assert:equals(2, doc:count-translations($doc)),
        assert:equals(2, doc:count-translations($doc//body))
    )
};

declare
    %xunit:test
function doctest:indexed-document() {
    (
        let $doc := <html><head><meta name="index.document" content="foo"/></head><body></body></html>
        return (
        assert:equals(('foo'), doc:indexed-document($doc)),
        assert:count(1, doc:indexed-document($doc//body))
        )
    )
};

declare
    %xunit:test
function doctest:indexed-paragraph() {
    (
        let $doc := <html><head><meta name="index.paragraph" content="foo"/></head><body></body></html>
        return (
        assert:equals(('foo'), doc:indexed-paragraph($doc)),
        assert:count(1, doc:indexed-paragraph($doc//body))
        )
    )
};

declare
    %xunit:test
function doctest:similar-documents() {
    (
        let $doc := 
            <html>
                <head>
                    <link rel='similarity' href='foo'/>
                    <link rel='other' href="bar"/>
                </head>
                <body/>
            </html>
            
        let $ranking := doc:similar-documents($doc)
        
        return (
                 assert:count(1, $ranking),
                 assert:equals('similarity', $ranking[1]/@rel/string()),
                 assert:equals('foo', $ranking[1]/@href/string())
                )
    )
};

declare
    %xunit:test
function doctest:similar-paragraphs() {
    (
    let $doc := 
        <html>
            <body>
                <div id="original">
                    <a href="bar"/>
                    <a href="foo" class="similarity"/>
                </div>
                <div class="translated">
                    <a href="bario"/>
                    <a href="foorio" class="similarity"/>
                </div>
            </body>
        </html>
            
        let $ranking := doc:similar-paragraphs($doc)
        
        return (
                 assert:count(1, $ranking),
                 assert:equals('similarity', $ranking[1]/@class/string()),
                 assert:equals('foo', $ranking[1]/@href/string())
                )
    )
};

declare 
    %xunit:test
    %xunit:error("http://dhil.lib.sfu.ca/exist/wilde-app/doctest", 'PT')
function doctest:err() {
    let $doc := <html id='cheese'><head><title>T1</title></head></html>    
    return 
        fn:error(QName('http://dhil.lib.sfu.ca/exist/wilde-app/doctest', 'PT'))
};