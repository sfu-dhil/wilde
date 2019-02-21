(function ($) {
  var $dataItems = $('li[data-count]');
  if ($dataItems.length === 0) {
    return;
  }
  
  google.charts.load('current', {
    'packages':[ 'corechart']
  });
  google.charts.setOnLoadCallback(drawChart);
  
  function drawChart() {
    var data = new google.visualization.DataTable();
    data.addColumn({
      type: 'string', label: 'region'
    });
    data.addColumn({
      type: 'number', label: 'Number of Reports'
    });
    
    $('li[data-count]').each(function () {
      var $item = $(this);
      data.addRow([$item.data('region'), $item.data('count')]);
    });
    
    var options = {
      title: 'Reports by region'
    };
    var chart = new google.visualization.PieChart(document.getElementById('chart'));
    chart.draw(data, options);
  }
})(jQuery);
