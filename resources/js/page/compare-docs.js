(function ($) {
  function normalize(string) {
    var lower = string.toLowerCase().normalize("NFC");
    var lbs = lower.replace(/(\r\n|\n|\r)/gm, " ");
    var clean = lbs.replace(/\s+/g, " ");
    return clean;
  }

  function select(selector) {
    var html = "";
    $(selector)
      .children("p")
      .each(function () {
        html += "<p>" + normalize($(this).text()) + "</p>";
      });
    return html;
  }

  function nav() {
    var buttons = $(".doc-compare-nav a");
    buttons.first().addClass("active");
    buttons.each(function () {
      var btn = $(this);
      $(this).on("click", function (e) {
        e.preventDefault();
        buttons.each(function () {
          $(this).removeClass("active");
        });
        $(this).addClass("active");
        var pos = $(this).parent().index();
        console.log(pos);
        $(".doc-compare").attr("data-pos", pos);
      });
    });
  }

  $(document).ready(function () {
    var a = select("#doc_a");
    var b = select("#doc_b");

    var markup = htmldiff(a, b);
    $("#diff").html(markup);
    nav();
  });
})(jQuery);
