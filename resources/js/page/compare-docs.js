(function ($) {
    function normalizeText(text) {
        return text.toLowerCase().replace(/[^a-z0-9 ]/g, '').replace(/\s+/g, ' ');
    }
    
    function getText(selector) {
        var $nodes = $(selector).clone().each(function () {
            var $this = $(this);
            $this.text(normalizeText($this.text()));
        });
        return $nodes.html();
    }
    
    $(document).ready(function () {
        var a = getText("#doc_a");
        var b = getText("#doc_b");
        
        var markup = diff(a, b);
        $("#diff").html(markup);
    });
})(jQuery);