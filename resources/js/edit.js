
(function ($, window, document) {
  var state;
  var editor;
  
  function init() {
    CKEDITOR.replace('editor', {
      customConfig: '../js/ckeditor-config.js' // relative to ckeditor.js
    });

    $(".typeahead").each(function () {
      var $this = $(this);
      var dataSource = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.whitespace,
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        prefetch: $this.data('typeahead-url')
      });
      $this.typeahead(null, {
        name: $this.attr('name'),
        source: dataSource
      });
    });
  }
  
  $(document).ready(init);
})(jQuery, window, document);