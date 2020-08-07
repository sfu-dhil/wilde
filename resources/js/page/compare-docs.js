(function ($) {

    function normalize(string) {
        var lower = string.toLowerCase().normalize('NFC');
        var lbs = lower.replace(/(\r\n|\n|\r)/gm, " ");
        var clean = lbs.replace(/\s+/g, ' ');        
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

        var markup = htmldiff(a,b);
        $("#diff").html(markup);
    });
})(jQuery);
