(function($){
    
    var uri = 'graph/dot.xq';
    
    var pzOpt = {
        $zoomIn: $('.zoom-in'),
        $zoomOut: $('.zoom-out'),
        contain: 'invert',
        minScale: 0
    };
    
    var graphData = null;    
    var graphEngine = 'fdp';
    
    function render() {
        console.log('Rendering with ' + graphEngine)
        var viz = Viz(graphData, {
            engine: graphEngine,
            format: 'png-image-element'
        });
        
        console.log(viz);
        
        viz.onload = function(){
            $(viz).cropbox({
                width: 408,
                height: 390,
                showControls: 'always'
            });
        };
        $("#graph img").remove();
        $("#graph").append(viz);
        console.log('Finished rendering.');
    }
    
    function ajaxComplete(jqXHR, status) {
    }
    
    function ajaxError(jqXhr, status, error) {
        console.log('ajax error: ' + status + ' ' + error);
    }
    
    function ajaxSuccess(data, status, jqXhr) {
        graphData = data;
        render();
    }
    
    $(document).ready(function(){
        $.ajax({
            method: 'GET',
            dataType: 'text',
            complete: ajaxComplete,
            error: ajaxError,
            success: ajaxSuccess,
            url: uri
        });
        
        $('.download').click(function(event){
            event.preventDefault();
            window.location = $("#graph img").attr('src');
        });
        
        $(".engines a").each(function(){
            $(this).click(function(event){
                event.preventDefault();
                graphEngine = $(this).data('engine');
                render();
            });
        });
        
    });
    
})(jQuery);