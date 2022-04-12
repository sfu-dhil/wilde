xquery version "3.0";

module namespace csv = "http://dhil.lib.sfu.ca/exist/wilde/csv";

declare variable $csv:nl := '&#x0d;&#x0a;';
declare variable $csv:comma := ',';

declare function csv:records($records as xs:string*) as xs:string {
  if (count($records) gt 0) then
    string-join(distinct-values($records), $csv:nl)
  else
    ()
};

declare function csv:comma-record($values as xs:string*) as xs:string? {
  if (count($values) gt 0) then
    string-join(($values), $csv:comma)
  else
    ()
};

declare function csv:string-value($value as xs:string?) as xs:string {
  if (exists($value)) then
    concat('"', replace(replace($value, '&#x0a;', ''), '"', '\\"'), '"')
  else
    ''
};

declare function csv:row($values as xs:string*) as xs:string {
  let $encoded := for $v in $values return csv:string-value($v)
  return csv:comma-record($encoded)
};
