(function ($) {
    
    var running = 0;
    
    var ajaxQueue = $({});   
    
    $.ajaxQueue = function (ajaxOpts) {
        running++;
        var oldComplete = ajaxOpts.complete;
        ajaxQueue.queue(function (next) {
            ajaxOpts.complete = function (xhr, status) {
                running--;
                if (oldComplete) {
                    oldComplete.apply(this, arguments);
                }
                if(status === 'error') {
                  ajaxQueue.stop( true );
                }
                next();
            };
            $.ajax(ajaxOpts);
        });
    };
    
    function processDocuments(data) {
        running++;
        
        var $output = $("div#output");
        
        var documents = data.document.filter(function(item){
          return item['index-document'] == 'No' && item.status != 'draft';
        });
        
        $output.append('Found ' + documents.length + ' documents to process.');
        $output.append('<ol id="progress" reversed="reversed"></ol>');
        var $progress = $('#progress');
        
        for (var i = 0; i < documents.length; i++) {
            var document = documents[i];
            $.ajaxQueue({
                url: 'api/reindex-document',
                data: {
                    f: document.id
                },
                type: 'GET',
                dataType: 'json',
                success: function (data) {
                  if(data.error) {
                    $progress.prepend('<li>' + data.error + '</li>');
                  } else {
                    $progress.prepend('<li>' + data.result.title + ' (' + data.result.id + ')' + ': ' + data.result.matches + ' matches in ' + data.result.duration + ' seconds.</li>');
                  }
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
        
        
        var documents = data.document.filter(function(item){
          return item['index-paragraph'] == 'No' && item.status != 'draft';
        });
        
        var $output = $("div#output");
        $output.append('Found ' + documents.length + ' documents with paragraphs to process.');
        $output.append('<ol id="progress" reversed="reversed"></ol>');
        var $progress = $('#progress');
        
        var $progress = $('#progress');
        for (var i = 0; i < documents.length; i++) {
            var document = documents[i];
            $.ajaxQueue({
                url: 'api/reindex-paragraphs',
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
        console.log("Reindexing " + type);
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
            url: "api/documents",
            type: "GET",
            dataType: "json",
            success: fn,
            error: errorHandler,
        });
    }
    
    function doParagraphIds() {
        event.preventDefault();
        console.log("generating paragraph ids.");
        $.ajax({
            url: "api/generate-paragraph-ids",
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
        console.log("deleting indexes.");
        $.ajax({
            url: "api/delete-indexes",
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