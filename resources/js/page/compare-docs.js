(function ($) {

    function normalize(string) {
        var lower = string.toLowerCase();
        var lbs = lower.replace(/(\r\n|\n|\r)/gm, " ");
        var clean = lbs.replace(/\s+/g, ' ').replace(/[^a-zA-Z0-0 ]/gm, '');        
        return clean;
    }

    function select(selector) {
        var html = '';
        $(selector).children("p").each(function(){
            html += '<p>' + normalize($(this).text()) + '</p>';
        });
        return html;
    }

    $(document).ready(function () {
        var a = select("#doc_a");
        var b = select("#doc_b");
        console.log(a);
        console.log(b);
        
        var markup = htmldiff(a,b);
        $("#diff").html(markup);
    });
})(jQuery);
