xquery version "3.0";

module namespace langtest="http://dhil.lib.sfu.ca/exist/wilde-app/langtest";

import module namespace xunit="http://dhil.lib.sfu.ca/exist/xunit/xunit" at "xunit.xql";
import module namespace assert="http://dhil.lib.sfu.ca/exist/xunit/assert" at "assert.xql";

import module namespace lang="http://dhil.lib.sfu.ca/exist/wilde-app/lang" at "../../modules/lang.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare
    %xunit:test
function langtest:lang2code() {
    (
        assert:equals((), lang:lang2code(())),
        assert:equals('en', lang:lang2code('English')),
        assert:equals('fr', lang:lang2code('French')),
        assert:equals(('de', 'en'), lang:lang2code(('English', 'German'))),       
        assert:equals(('de', 'en'), lang:lang2code(('German', 'English'))),
        assert:equals(('es', 'fr', 'it'), lang:lang2code(('French', 'Italian', 'Spanish'))),        
        assert:equals('Unknown name foo', lang:lang2code('foo'))
    )
};

declare
    %xunit:test
function langtest:code2lang() {
    (
        assert:equals((), lang:code2lang(())), 
        assert:equals('English', lang:code2lang('en')),
        assert:equals('French', lang:code2lang('fr')),
        assert:equals(('English', 'German'), lang:code2lang(('en', 'de'))),       
        assert:equals(('English', 'German'), lang:code2lang(('de', 'en'))),
        assert:equals(('French', 'Italian', 'Spanish'), lang:code2lang(('fr', 'it', 'es'))),
        assert:equals('Unknown code foo', lang:code2lang('foo'))        
    )
};
