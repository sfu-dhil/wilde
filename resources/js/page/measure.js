(function ($) {
  
  function htmlize(diffs) {
    var html =[];
    
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
  function normalize(string, clean) {
    var lower = string.toLowerCase().normalize("NFC");
    var lbs = lower.replace(/(\r\n|\n|\r)/gm, " ");
    var ws = lbs.replace(/\s+/g, ' ');
    if(clean) {
      return ws.replace(/[^a-zA-Z0-9 -]/g, '');
    }
    return ws;
  }
  
  function countWords(str) {
    return str.trim().split(/\s+/).length;
  }
  
  $(document).ready(function () {
    $("input[name=measure]").click(function (e) {
      e.preventDefault();

      var clean = $("input[name=clean]").is(":checked");
      var a = normalize($("#c1").val(), clean);
      var b = normalize($("#c2").val(), clean);      
      var lev = LevDist(a, b);
      
      var fmt = new Intl.NumberFormat('default', {
        style: 'percent',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      });
      $("#similarity").text(fmt.format(1 - lev / Math.max(a.length, b.length)));
      $("#wordcount").text('First passage: ' + countWords(a) + ", Second passage: " + countWords(b));
      
      var dmp = new diff_match_patch();
      var diff = dmp.diff_main(a, b);
      dmp.diff_cleanupSemantic(diff);
      var html = htmlize(diff);
      $("#difference").html(html);
    });
  });
})(jQuery);
