xquery version "3.0";

(: use dot -T png tmp.dot -o tmp.png -Kfdp to render the graph to a png. :)

import module namespace config="http://nines.ca/exist/wilde/config" at "../modules/config.xqm";
import module namespace collection="http://nines.ca/exist/wilde/collection" at "../modules/collection.xql";
import module namespace document="http://nines.ca/exist/wilde/document" at "../modules/document.xql";

declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace graph="http://nines.ca/exist/wilde/graph";

declare option exist:serialize "method=text ";
(: The tags are dropped during serialization. They are present to make things easier to understand. :)

declare function graph:documents() {
    for $document in collection:documents()
    where count($document//xhtml:link[@rel='similarity']) > 0
    return $document    
};

declare function graph:node-label($document) {
    'label="' || document:publisher($document) || '\n' || document:date($document) || '"'
};

declare function graph:node-color($document) {
    let $color := 
        switch(document:region($document))
            case 'American' return 'chartreuse'
            case 'Australian' return 'cyan'
            case 'British' return 'bisque'
            case 'French' return 'darkolivegreen1'
            default return 'white'
    return "color=" || $color
};

declare function graph:nodes($documents) {
    for $document in $documents
    return document:id($document) || '[' || graph:node-label($document) || ' ' || graph:node-color($document) || '];'
};

declare function graph:edges($documents) {
    for $document in $documents
        for $id in $document//xhtml:link[@rel='similarity']/@href
        let $similar := collection:fetch($id)
        return
            if((document:date($document) = document:date($similar)) and (document:id($document) < document:id($similar))) then
                    document:id($document) || ' -> ' || $id || '[dir=none];'
            else if(document:date($document) < document:date($similar)) then
                document:id($document) || ' -> ' || $id || ';'
            else
                ()
};

let $documents := graph:documents()
return
    <graph>
    strict digraph {{
        node [ style=filled ];
        <nodes> {
            graph:nodes($documents)
        } </nodes>
        <edges> {
            graph:edges($documents)
        }</edges>
    }}
    </graph>
