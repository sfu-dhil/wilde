xquery version "3.0";

module namespace extest="http://dhil.lib.sfu.ca/exist/wilde-app/extest";

import module namespace console="http://exist-db.org/xquery/console";

import module namespace xunit="http://dhil.lib.sfu.ca/exist/xunit/xunit" at "xunit.xql";
import module namespace assert="http://dhil.lib.sfu.ca/exist/xunit/assert" at "assert.xql";

import module namespace export="http://dhil.lib.sfu.ca/exist/wilde-app/export" at "../../modules/export.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare
    %xunit:test
function extest:volume() {
    (
    
    )
};