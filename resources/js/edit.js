
(function ($, window, document) {
  var state;
  var editor;
  
  function typeahead($input) {
      var dataSource = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.whitespace,
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        prefetch: $input.data('typeahead-url')
      });
      $input.typeahead(null, {
        name: $input.attr('name'),
        source: dataSource
      });
  }

  function window_unload(e) {
    if (state !== 'clean') {
        return "This page contains unsaved changes.";
    }
  }
  
  function message(text) {
    $("#result").append("<p>" + text + "</p>");
  }
  
  function save_click(e) {
    e.preventDefault();
    for ( instance in CKEDITOR.instances ) {
      CKEDITOR.instances[instance].updateElement();
    }
    var formData = {
      docId: $('#doc-id').val(),
      content: editor.getData()
    };

    $.ajax({
      url: 'api/save-document',
      method: 'post',
      dataType: 'json',
      data: formData,
      
      success: function(data, status, xhr) {
        state = 'clean';
        message("Changes saved.");
      },
      error: function(xhr, status, error) {
        message("Failed to save changes. " + error);
      }
    });
  }
  
  function cancel_click(e) {
    e.preventDefault();
    window.history.go(-1);
  }

  function init() {
  
    editor = CKEDITOR.replace('editor', {
      customConfig: '../../js/ckeditor-config.js' // relative to ckeditor.js
    });
    
    // check for unsaved changes
    state = 'clean';
    $(window).on("beforeunload", window_unload);
    $("#wilde-editor input").change(function(){state = 'dirty';});
    editor.on('change', function(){state = 'dirty';})

    // do the typeahead thing.
    $(".typeahead").each(function () {
      typeahead($(this));
    });
    
    // save button do the thing.
    $("#btn-save").click(save_click);
    
    $("#btn-cancel").click(cancel_click);
  }
  
  $(document).ready(init);
})(jQuery, window, document);