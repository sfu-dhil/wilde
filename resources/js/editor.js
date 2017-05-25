
(function (window) {    
    var state;
    var editor;
    
    function init() {
        state = 'clean';
        $("#btn-save").click(save_btn_click);
        $(window).on("beforeunload", window_unload);
        
        editor = CKEDITOR.replace('articlecontent');
        editor.on('change', function() {state='dirty';});
    }
    
    function window_unload(e) {
        if (state === 'dirty') {
            return "This page contains unsaved changes.";
        }
    }
    
    function save_btn_click(e) {
        $("body").addClass("saving");
        editor.setReadOnly(true);
        $.ajax({
            data: {
                content: editor.getData(),
                status: $("#doc-status").val(),
                change: $("#change").val(),
                title: $("#title").val(),
                subtitle: $("#subtitle").val()
            },
            dataType: 'xml',
            complete: save_complete,
            error: save_error,
            success: save_success,
            type: 'POST'
        });
        e.preventDefault();
    }
        
    function save_complete(xhr, status) {
        $("body").removeClass('saving');
        editor.setReadOnly(false);
    }
    
    function save_success(data, status, xhr) {
        alert('The changes have been saved.');
        state = 'clean';
    }
    
    function save_error(xhr, status, error) {
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
    
    $(document).ready(init);
})(window, document);