(function($){
        function htmlize(diffs) {
          var html = [];
          var pattern_amp = /&amp;/g;
          var pattern_lt = /</g;
          var pattern_gt = />/g;
          var pattern_para = /\n/g;
          
          for (var x = 0; x < diffs.length; x++) {
            var op = diffs[x][0];    // Operation (insert, delete, equal)
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
      function normalize(string) {
        var lower = string.toLowerCase().normalize("NFC");
        var lbs = lower.replace(/(\r\n|\n|\r)/gm," ");
        var clean = lbs.replace(/\s+/g, ' ');
        return clean;
      }
    
      $(document).ready(function(){
        var dmp = new diff_match_patch();
        
        var a = normalize($("#first").text());
        var b = normalize($("#second").text());
        var $d = $("#difference");
        
        var diff = dmp.diff_main(a, b);
        dmp.diff_cleanupSemantic(diff);
        var html = htmlize(diff);            
        $d.html(html);
      });
        
})(jQuery);