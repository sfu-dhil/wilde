(function ($) {
  $(document).ready(function () {
    $('#clear').click(function (e) {
      $('input.facet').prop('checked', false);
    });
    $('#export').click(function(e) {
      $('#search-form').attr('action', 'export/search.csv');
    });
  });
})(jQuery);