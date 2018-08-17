xquery version "3.0";

module namespace simtest="http://dhil.lib.sfu.ca/exist/wilde-app/similarity-test";

import module namespace xunit="http://dhil.lib.sfu.ca/exist/xunit/xunit" at "xunit.xql";
import module namespace assert="http://dhil.lib.sfu.ca/exist/xunit/assert" at "assert.xql";

import module namespace similarity="http://dhil.lib.sfu.ca/exist/wilde-app/similarity" at "../../modules/similarity.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare
    %xunit:test
function simtest:normalize() {
    (
        assert:equals('abc', similarity:normalize('abc')),
        assert:equals('abc', similarity:normalize('ABC')),
        assert:equals('a b c', similarity:normalize('a  b c')),
        assert:equals('abc', similarity:normalize(' abc ')),
        assert:equals('latte&#769;', similarity:normalize('latt&#xE9;')),
        assert:equals('latte&#769;', similarity:normalize('latte&#769;')),
        assert:equals('latte', similarity:normalize('latt&#xE9;', true())),
        assert:equals('latte', similarity:normalize('latte&#769;', true())),
        assert:equals('la-te', similarity:normalize('la-te', true())),
        assert:equals('late', similarity:normalize('la.te', true()))
    )
};

declare
    %xunit:test
function simtest:word-list() {
    (
        assert:equals((), similarity:word-list('')),
        assert:equals(('abc'), similarity:word-list('abc')),
        assert:equals(('abc', 'def'), similarity:word-list('abc def')),
        assert:equals(('abc', 'def'), similarity:word-list(' abc   def  ')),
        assert:equals(('abc', 'def'), similarity:word-list('abc-def')),
        assert:equals(('abc', 'def'), similarity:word-list('abc---def')),
        assert:equals(('don', 't'), similarity:word-list("don't"))
    )
};

declare
    %xunit:test
function simtest:levenshtein() {
    let $a := 'I am the very model of a modern major general I know the fights historical'
    let $b := 'I am also the very model of a modern major general I know the figures historical'
    return
    (
        assert:equals(0.9, similarity:levenshtein($a, $b)),
        assert:equals(0, similarity:levenshtein('', $a)),
        assert:equals(1, similarity:levenshtein($a, $a)),
        assert:equals(0, similarity:levenshtein($a, $a || $a))
    )
};

declare
    %xunit:test
function simtest:dot-product() {
    (
        assert:equals(5, similarity:dot-product((1,3), (2,1))),
        assert:equals(5, similarity:dot-product((1,3), (2,1,3,4))),
        assert:equals(0, similarity:dot-product((), (2,1)))
    )
};

declare
    %xunit:test
function simtest:magnitude() {
    (
        assert:equals(5, similarity:magnitude((2,1))),
        assert:equals(9, similarity:magnitude((3))),
        assert:equals(0, similarity:magnitude(()))
    )
};

declare
    %xunit:test
function simtest:cosine() {
    (
        assert:close(0.77, 0.005, similarity:cosine('a b c', 'a a c')),
        assert:equals('NaN', string(similarity:cosine('', 'a a c')))
    )
};

declare
    %xunit:test
function simtest:jaccard() {
    (
        assert:close(0.66, 0.007, similarity:jaccard('a b c', 'a a c')),
        assert:equals(0, similarity:jaccard('', 'a a c'))
    )
};

declare
    %xunit:test
function simtest:overlap() {
    (
        assert:close(0.66, 0.007, similarity:overlap('a b c', 'a a c')),
        assert:equals(0, similarity:overlap('', 'a a c'))
    )
};

declare
    %xunit:test
function simtest:compressed-string-size() {
    (
        assert:equals(108, similarity:compressed-string-size('I am the very model of a modern major general I know the fights historical'))
    )
};


declare
    %xunit:test
function simtest:compression() {
    let $a := 'I am the very model of a modern major general I know the fights historical'
    let $b := 'I am also the very model of a modern major general I know the figures historical'
    return
    (
        assert:close(0.857, 0.0002, similarity:compression($a, $b))
    )
};

declare
    %xunit:test
function simtest:available() {
    assert:equals(('compression', 'jaccard', 'cosine', 'levenshtein', 'overlap'), similarity:available())
};

declare
    %xunit:test
function simtest:similarity() {
    let $a := 'I am the very model of a modern major general I know the fights historical'
    let $b := 'I am also the very model of a modern major general I know the figures historical'
    return
    (
        assert:close(0.857, 0.0002, similarity:similarity('compression', $a, $b)),
        assert:equals(0, similarity:similarity('compression', '', $b)),
        assert:close(0.8, 0.0002, similarity:similarity('jaccard', $a, $b)),
        assert:equals(0, similarity:similarity('jaccard', '', $b)),
        assert:close(0.923, 0.0004, similarity:similarity('cosine', $a, $b)),
        assert:equals(0, similarity:similarity('cosine', '', $b)),
        assert:close(0.9, 0.0004, similarity:similarity('levenshtein', $a, $b)),
        assert:equals(0, similarity:similarity('levenshtein', '', $b)),
        assert:close(0.8, 0.0005, similarity:similarity('overlap', $a, $b)),
        assert:equals(0, similarity:similarity('overlap', '', $b)),
        assert:equals(-1, similarity:similarity('potato', $a, $b)),
        assert:equals(0, similarity:similarity('potato', '', $b))
    )
};
