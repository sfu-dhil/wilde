(function ($, cookies) {

  function matching_show(e) {
    if (e) {
      e.preventDefault()
      cookies.set('similarity', 'shown');
    }
    $('div.similarity').show();
    $('#pm-show').hide();
    $('#pm-hide').show();
  }

  function matching_hide(e) {
    if (e) {
      e.preventDefault()
      cookies.set('similarity', 'hidden');
    }
    $('div.similarity').hide();
    $('#pm-hide').hide();
    $('#pm-show').show();
  }

  $(function () {
    $('#pm-show').click(matching_show);
    $('#pm-hide').click(matching_hide);

    if (cookies.get('similarity') && cookies.get('similarity') === 'shown') {
      matching_show(null);
    } else {
      matching_hide(null);
    }
  });
})(jQuery, Cookies);
