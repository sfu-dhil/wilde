(function ($) {

    function normalize(string) {
        var lower = string.toLowerCase().normalize('NFC');
        var lbs = lower.replace(/(\r\n|\n|\r)/gm, " ");
        var clean = lbs.replace(/\s+/g, ' ');        
        return clean;
    }
    
    function htmlize(diffs) {
        var html =[];
        var pattern_amp = /&amp;/g;
        var pattern_lt = /&lt;/g;
        var pattern_gt = /&gt;/g;
        var pattern_para = /\n/g;
        
        for (var x = 0; x < diffs.length; x++) {
            var op = diffs[x][0];
            // Operation (insert, delete, equal)
            var text = diffs[x][1];
            switch (op) {
                case DIFF_INSERT:
                html[x] = '<ins>' + text + '</ins>';
                break;
                case DIFF_DELETE:
                html[x] = '<del>' + text + '</del>';
                break;
                case DIFF_EQUAL:
                html[x] = '<span>' + text + '</span>';
                break;
            }
        }
        return html.join('');
    };
    
    $(document).ready(function () {
        var dmp = new diff_match_patch();
        
        $("div.paragraph-compare").each(function () {
            var $this = $(this);
            var a = normalize($this.find('.paragraph-a .content').text());
            var b = normalize($this.find('.paragraph-b .content').text());
            var $d = $this.find('.paragraph-d');
            
            if (! b) {
                $d.html("<em>No similar paragraph</em>");
            } else {
                var diff = dmp.diff_main(a, b);
                dmp.diff_cleanupSemantic(diff);
                var html = htmlize(diff);
                $d.html('<p>' + html + '</p>');
                if($this.data('score') !== '%') {
                  $d.append("<em>Match: " + $this.data('score') + "</em>");
                } else {
                  $d.append("<em>Too short to calculate match</em>");
                }
            }
        });
    });
})(jQuery);