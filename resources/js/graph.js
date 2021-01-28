(function($) {

  function drawNetwork() {
    var container = document.getElementById('network');
    var options = {
      interaction: {
        keyboard: true,
        navigationButtons: true
      },
      edges: {
        smooth: {
          roundness: 0
        }
      },
      layout: {
        improvedLayout: false
      }      
    };

    $.ajax({
      url: "api/graph-data",
      type: "GET",
      dataType: "json",
      success: function(data) {
        var nodeData = data.root.node;
        nodeData.forEach(function(item){
          item.label = item.label.replace('\\n', "\n");
        });
        
        var edgeData = data.root.edge;
        var nodes = new vis.DataSet(nodeData);
        var edges = new vis.DataSet(edgeData);
        var graph = {
          nodes: nodes,
          edges: edges
        };
        var network = new vis.Network(container, graph, options);
      }
    });
  }
  
  $(document).ready(function(){drawNetwork()});  

})(jQuery);