
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
    if (state === 'dirty') {
        return "This page contains unsaved changes.";
    }
  }
  
  function save_click(e) {
    e.preventDefault();
    for ( instance in CKEDITOR.instances ) {
      CKEDITOR.instances[instance].updateElement();
    }
    var formData = {
      docId: $('#doc-id').val(),
      content: editor.getData(),
      date: $('#date').val(),
      publisher: $('#publisher').val(),
      status: $('#status').val(),
      region: $('#region').val(),
      title: $('#title').val(),
      language: $('#language').val(),
      city: $("#city").val(),
      source: $("#source").val()
    };

    $.ajax({
      url: 'api/save-document',
      method: 'post',
      dataType: 'json',
      data: formData,
      
      complete: function(xhr, status) {
        // $("#result").append('<p>complete: ' + status + '</p>');
      },
      success: function(data, status, xhr) {
        $("#result").append('<p>' + data.result + '</p>');
      },
      error: function(xhr, status, error) {
        $("#result").append('<p>' + error + '</p>');
      }
    });
  }

  function init() {
  
    editor = CKEDITOR.replace('editor', {
      customConfig: '../js/ckeditor-config.js' // relative to ckeditor.js
    });
    
    // check for unsaved changes
    state = 'clean';
    // $(window).on("beforeunload", window_unload);
    $("#wilde-editor input").change(function(){state = 'dirty';});
    editor.on('change', function(){state = 'dirty';})

    // do the typeahead thing.
    $(".typeahead").each(function () {
      typeahead($(this));
    });
    
    // save button do the thing.
    $("#btn-save").click(save_click);
  }
  
  $(document).ready(init);
})(jQuery, window, document);