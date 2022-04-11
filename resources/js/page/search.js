(function ($) {
  $(document).ready(function () {
    $('#clear').click(function (e) {
      $('input.facet').prop('checked', false);
    });
  });
})(jQuery);