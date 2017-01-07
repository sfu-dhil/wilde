
(function ($, window, document) {
  var state;
  var editor;
  
  function init() {
    
    editor = CKEDITOR.replace('editor', {
      customConfig: '/exist/apps/wilde/resources/js/ckeditor-config.js'
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
    
    state = 'clean';
    $(window).on("beforeunload", window_unload);
    $("#editForm input").each(function () {
      var $this = $(this);
      $this.on("input", function (e) {
        state = 'dirty';
      });
    });
    
    $("#save").click(save_changes);
  }
  
  function save_changes(e) {
    e.preventDefault();
    editor.setReadOnly(true);
    editData = {
      content: editor.getData()
    }; 
    $("#editForm :input").each(function(index, element) {
      editData[element.name] = $(element).val();
    });
    $.ajax('api/save-document', {
      data: editData,
      dataType: 'json',
      complete: save_complete,
      error: save_error,
      success: save_success,
      type: 'POST'
    });
  }
  
  function save_complete(xhr, status) {
    console.log('complete');
    console.log({}, status, xhr);
    $("body").removeClass('saving');
    editor.setReadOnly(false);
  }
  
  function save_success(data, status, xhr) {
    console.log('success');
    console.log(data, status, xhr);
    
    alert('The changes have been saved.');
    state = 'clean';
  }
  
  function save_error(xhr, status, error) {
    console.log('error');
    console.log(xhr, status, xhr);
    
    var message = 'The changes have not been saved.';
    alert(message);
    if (status !== null) {
      message += ' ' + status;
    }
    if (error !== null) {
      message += ' ' + error;
    }
    $('.app-errors').append($('<div/>').html(message));
    $('.app-errors').append($('<div/>').html(xhr.responseText).find('pre.error'));
  }
  
  function window_unload(e) {
    if (editor.checkDirty() || state != 'clean') {
      return "This page contains unsaved changes.";
    }
  }
  
  
  
  $(document).ready(init);
})(jQuery, window, document);