(function ($) {
    
    var ajaxQueue = $({
    });
    var running = 0;
    
    $.ajaxQueue = function (ajaxOpts) {
        running++;
        var oldComplete = ajaxOpts.complete;
        ajaxQueue.queue(function (next) {
            ajaxOpts.complete = function () {
                running--;
                if (oldComplete) {
                    oldComplete.apply(this, arguments);
                }
                next();
            };
            $.ajax(ajaxOpts);
        });
    };
    
    function processDocuments(data) {
        running++;
        
        var $output = $("div#output");
        $output.append('Found ' + data.document.length + ' documents to process.');
        $output.append('<ol id="progress" reversed="reversed"></ol>');
        var $progress = $('#progress');
        
        for (var i = 0; i < data.document.length; i++) {
            var document = data.document[i];
            $.ajaxQueue({
                url: '../api/reindex-document',
                data: {
                    f: document.id
                },
                type: 'GET',
                dataType: 'json',
                success: function (data) {
                    $progress.prepend('<li>' + data.result.title + ' (' + data.result.id + ')' + ': ' + data.result.matches + ' matches in ' + data.result.duration + ' seconds.</li>');
                },
                error: function (xhr, status, errorThrown) {
                    $progress.prepend('<li>' + document.title + ' error: ' + xhr.status + ' - ' + errorThrown + '<br/>' + xhr.responseText + '</li>');
                }
            });
        }
        running--;
    }
    
    function processParagraphs(data) {
        running++;
        
        var $output = $("div#output");
        $output.append('Found ' + data.document.length + ' documents with paragraphs to process.');
        $output.append('<ol id="progress" reversed="reversed"></ol>');
        var $progress = $('#progress');
        for (var i = 0; i < data.document.length; i++) {
            var document = data.document[i];
            $.ajaxQueue({
                url: '../api/reindex-paragraphs',
                data: {
                    f: document.id
                },
                type: 'GET',
                dataType: 'json',
                beforeSend: function () {
                    //console.log('sending query.')
                },
                success: function (data) {
                    $progress.prepend('<li>' + data.result.title + ' (' + data.result.id + ')' + ': ' + data.result.matches + ' matches in ' + data.result.duration + ' seconds.</li>');
                },
                error: function (xhr, status, errorThrown) {
                    $progress.prepend('<li>' + document.title + ' error: ' + xhr.status + ' - ' + errorThrown + '<br/>' + xhr.responseText + '</li>');
                }
            });
        }
        running--;
    }
    
    function doReindex(event) {
        event.preventDefault();
        
        
        type = $(this).data('level');
        fn = null;
        switch (type) {
            case 'document':
            fn = processDocuments;
            break;
            case 'paragraph':
            fn = processParagraphs;
            break;
            default:
            console.log('Unknown index level ' + type);
            return;
        }
        
        $.ajax({
            url: "../api/documents",
            type: "GET",
            dataType: "json",
            success: fn,
            error: errorHandler,
        });
    }
    
    function doParagraphIds() {
        event.preventDefault();
        $.ajax({
            url: "../api/generate-paragraph-ids",
            type: "GET",
            dataType: "json",
            success: function (data) {
                //console.log(data);
                var $output = $("div#output");
                $output.prepend('<li>' + data.result + '</li>');
            },
            error: errorHandler,
        });
    }
    
    function deleteIndexes (event) {
        event.preventDefault();
        
        $.ajax({
            url: "../api/delete-indexes",
            type: "GET",
            dataType: "json",
            success: function (data) {
                //console.log(data);
                var $output = $("div#output");
                $output.prepend('<li>' + data.result + '</li>');
            },
            error: errorHandler,
        });
    }
    
    function errorHandler(xhr, status, errorThrown) {
        var $output = $("div#output");
        $output.append('Error: ' + xhr.status + ' - ' + errorThrown + '<br/>');
        $output.append(xhr.responseText);
        console.log(xhr);
    }
    
    function window_unload() {
        console.log('window_unload' + running);
        if (running > 0) {
            return "There is a reindex operation in progress on this page. If you leave the page or reload it, the reindex operation will be cancelled.";
        }
    }
    
    $(document).ready(function () {
        $(window).on("beforeunload", window_unload);
        $("a.delindex").click(deleteIndexes);
        $("a.reindex").click(doReindex);
        $("a.genids").click(doParagraphIds);
    });
})(jQuery);