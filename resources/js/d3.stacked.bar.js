// we do this here because eXist doesn't like that it's not valid XML.
$(document).ready(function() {

var dates_en = [];
var dates_fr = [];
var dates_es = [];
var dates_it = [];

var num_dates = $('#languages li').length;

var all_days = [];

$('#languages li').each(function(i) {
  var date = $(this).data('date');
  all_days.push(date);

  var num_en = $(this).data('en');
  var num_fr = $(this).data('fr');
  var num_es = $(this).data('es');
  var num_it = $(this).data('it');

  date = i;

  // var pair = {"x": date, "y": num_en};
  dates_en.push({"x":date,"y":num_en});
  dates_fr.push({"x":date,"y":num_fr});
  dates_es.push({"x":date,"y":num_es});
  dates_it.push({"x":date,"y":num_it});
});

var language_by_day = [{"name": "English", "values": dates_en}, {"name": "French", "values": dates_fr}, {"name": "Spanish", "values": dates_es}, {"name": "Italian", "values": dates_it}];

// Start stacked bar chart
var seriesNames = ["Italian", "Spanish", "French", "English"],
  numSamples = 22,
  numSeries = seriesNames.length,
  bar_chart_data = seriesNames.map(function (name) {
    return {
      name: name,
      values: bumpLayer(numSamples, 0.1)
    };
  }),
  stack = d3.layout.stack().values(function (d) { return d.values; });

numSamples = num_dates;
bar_chart_data = language_by_day;

stack(bar_chart_data);

var chartMode = "stacked",
  numEnabledSeries = numSeries,
  lastHoveredBarIndex,
  containerWidth = $(".js-stacked-chart-container").width(),
  containerHeight = 300,
  margin = {top: 40, right: 30, bottom: 20, left: 30},
  width = containerWidth - margin.left - margin.right,
  height = containerHeight - margin.top - margin.bottom,
  widthPerStack = width / numSamples,
  animationDuration = 400,
  delayBetweenBarAnimation = 10,
  numYAxisTicks = 8,
  maxStackY = d3.max(bar_chart_data, function (series) { return d3.max(series.values, function (d) { return d.y0 + d.y; }); }),
  paddingBetweenLegendSeries = 5,
  legendSeriesBoxX = 0,
  legendSeriesBoxY = 0,
  legendSeriesBoxWidth = 15,
  legendSeriesBoxHeight = 15,
  legendSeriesHeight = legendSeriesBoxHeight + paddingBetweenLegendSeries,
  legendSeriesLabelX = -5,
  legendSeriesLabelY = legendSeriesBoxHeight / 2,
  legendMargin = 20,
  legendX = containerWidth - legendSeriesBoxWidth - legendMargin,
  legendY = legendMargin,
  tooltipTemplate = _.template("<table><% _.each(bars, function (bar) { %><tr><td><%= bar.name %></td><td><%= Math.round(bar.value) %></td></tr><% }); %></table>"),
  overlayTopPadding = 20,
  tooltipBottomMargin = 12;

var binsScale = d3.scale.ordinal()
    .domain(d3.range(numSamples))
    .rangeBands([0, width], 0.1, 0.05);

var xScale = d3.scale.linear()
    .domain([0, numSamples])
    .range([0, width]);

var yScale = d3.scale.linear()
    .domain([0, maxStackY])
    .range([height, 0]);

var heightScale = d3.scale.linear()
    .domain([0, maxStackY])
    .range([0, height]);

var xAxis = d3.svg.axis()
    .scale(xScale) //binsScale)
    // .ticks(numSamples)
    .tickFormat(function (d) {
  		return all_days[d];
  	})
    .orient("bottom");

var yAxis = d3.svg.axis()
    .scale(yScale)
    .orient("left");

var enabledSeries = function () { return _.reject(bar_chart_data, function (series) { return series.disabled; }); };

var seriesClass = function (seriesName) { return "series-" + seriesName.toLowerCase(); };

var layerClass = function (d) { return "layer " + seriesClass(d.name); };

var legendSeriesClass = function (d) { return "clickable " + seriesClass(d); };

var barDelay = function (d, i) { return i * delayBetweenBarAnimation; };

var joinKey = function (d) { return d.name; };

var stackedBarX = function (d) { return binsScale(d.x); };

var stackedBarY = function (d) { return yScale(d.y0 + d.y); };

var stackedBarBaseY = function (d) { return yScale(d.y0); };

var stackedBarWidth = binsScale.rangeBand();

var groupedBarX = function (d, i, j) { return binsScale(d.x) + j * groupedBarWidth(); };

var groupedBarY = function (d) { return yScale(d.y); };

var groupedBarBaseY = height;

var groupedBarWidth = function () { return binsScale.rangeBand() / numEnabledSeries; };

var barHeight = function (d) { return heightScale(d.y); };

var transitionStackedBars = function (selection) {
    selection.transition()
        .duration(animationDuration)
        .delay(barDelay)
        .attr("y", stackedBarY)
        .attr("height", barHeight);
};

var svg = d3.select(".js-stacked-chart")
    .attr("width", containerWidth)
    .attr("height", containerHeight);

var mainArea = svg.append("g")
    .attr("class", "main-area")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

mainArea.append("g")
    .attr("class", "grid-lines")
    .selectAll(".grid-line").data(yScale.ticks(numYAxisTicks))
        .enter().append("line")
            .attr("class", "grid-line")
            .attr("x1", 0)
            .attr("x2", width)
            .attr("y1", yScale)
            .attr("y2", yScale);

var layersArea = mainArea.append("g")
    .attr("class", "layers");

var layers = layersArea.selectAll(".layer").data(bar_chart_data)
    .enter().append("g")
        .attr("class", layerClass);

layers.selectAll("rect").data(function (d) { return d.values; })
    .enter().append("rect")
        .attr("x", stackedBarX)
        .attr("y", height)
        .attr("width", stackedBarWidth)
        .attr("height", 0)
        .call(transitionStackedBars);

mainArea.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis);

mainArea.append("g")
    .attr("class", "y axis")
    .call(yAxis);

svg.append("rect")
    .attr("class", "overlay")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")")
    .attr("x", 0)
    .attr("y", 0)
    .attr("width", width)
    .attr("height", height)
    .on("mousemove", showTooltip)
    .on("mouseout", hideTooltip);

var legend = svg.append("g")
    .attr("class", "legend")
    .attr("transform", "translate(" + legendX + "," + legendY + ")");

var legendBackground = legend.append("rect")
    .attr("class", "legend-background")
    // .attr("transform", "translate(" + legendX + "," + legendY + ")")
    .attr("x", '-60px')
    .attr("y", 0)
    .attr("width", '80px')
    .attr("height", '90px');

var legendSeries = legend.selectAll("g").data(seriesNames.reverse())
        .enter().append("g")
            .attr("class", legendSeriesClass)
            .attr("transform", function (d, i) { return "translate(0," + (i * legendSeriesHeight) + ")"; })
            .on("click", toggleSeries);

legendSeries.append("rect")
    .attr("class", "series-box")
    .attr("x", legendSeriesBoxX)
    .attr("y", legendSeriesBoxY)
    .attr("width", legendSeriesBoxWidth)
    .attr("height", legendSeriesBoxHeight);

legendSeries.append("text")
    .attr("class", "series-label")
    .attr("x", legendSeriesLabelX)
    .attr("y", legendSeriesLabelY)
    .text(String);


d3.selectAll(".js-stacked-chart-container input").on("change", changeChartMode);

/**
 * Toggles a certain series.
 * @param {String} seriesName The name of the series to be toggled
 */
function toggleSeries (seriesName) {
    var series,
        isDisabling,
        newData;

    series = _.findWhere(bar_chart_data, { name: seriesName });
    isDisabling = !series.disabled;

    if (isDisabling === true && numEnabledSeries === 1) {
        return;
    }

    d3.select(this).classed("disabled", isDisabling);

    series.disabled = isDisabling;
    newData = stack(enabledSeries());
    numEnabledSeries = newData.length;
    layers = layers.data(newData, joinKey);

    if (isDisabling === true) {
        removeSeries();
    }
    else {
        addSeries();
    }
}

/**
 * Removes a certain series.
 */
function removeSeries () {
    var layerToBeRemoved;

    layerToBeRemoved = layers.exit();
    if (chartMode === "stacked") {
        removeStackedSeries(layerToBeRemoved);
    }
    else {
        removeGroupedSeries(layerToBeRemoved);
    }
}

/**
 * Smoothly transitions and then removes a certain series when the chart is in `stacked` mode.
 * @param {d3.selection} layerToBeRemoved The layer that contains the series' bars
 */
function removeStackedSeries (layerToBeRemoved) {
    layerToBeRemoved.selectAll("rect").transition()
        .duration(animationDuration)
        .delay(barDelay)
        .attr("y", stackedBarBaseY)
        .attr("height", 0)
        .call(endAll, function () {
            layerToBeRemoved.remove();
        });

    transitionStackedBars(layers.selectAll("rect"));
}

/**
 * Smoothly transitions and then removes a certain series when the chart is in `grouped` mode.
 * @param {d3.selection} layerToBeRemoved The layer that contains the series' bars
 */
function removeGroupedSeries (layerToBeRemoved) {
    layerToBeRemoved.selectAll("rect").transition()
        .duration(animationDuration)
        .delay(barDelay)
        .attr("y", groupedBarBaseY)
        .attr("height", 0)
        .call(endAll, function () {
            layerToBeRemoved.remove();

            layers.selectAll("rect").transition()
                .duration(animationDuration)
                .delay(barDelay)
                .attr("x", groupedBarX)
                .attr("width", groupedBarWidth);
        });
}

/**
 * Adds a certain series.
 */
function addSeries () {
    var newLayer;

    newLayer = layers.enter().append("g")
        .attr("class", layerClass);

    if (chartMode === "stacked") {
        addStackedSeries(newLayer);
    }
    else {
        addGroupedSeries(newLayer);
    }
}

/**
 * Smoothly transitions and adds a certain series when the chart is in `stacked` mode.
 * @param {d3.selection} newLayer The new layer to be added
 */
function addStackedSeries (newLayer) {
    newLayer.selectAll("rect").data(function (d) { return d.values; })
        .enter().append("rect")
            .attr("x", stackedBarX)
            .attr("y", stackedBarBaseY)
            .attr("width", stackedBarWidth)
            .attr("height", 0);

    transitionStackedBars(layers.selectAll("rect"));
}

/**
 * Smoothly transitions and adds a certain series when the chart is in `grouped` mode.
 * @param {d3.selection} newLayer The new layer to be added
 */
function addGroupedSeries (newLayer) {
    var newBars;

    layers.selectAll("rect").transition()
        .duration(animationDuration)
        .delay(barDelay)
        .attr("x", groupedBarX)
        .attr("width", groupedBarWidth)
        .call(endAll, function () {
            newBars = newLayer.selectAll("rect").data(function (d) { return d.values; })
                .enter().append("rect")
                    .attr("y", groupedBarBaseY)
                    .attr("width", groupedBarWidth)
                    .attr("height", 0);

            layers.selectAll("rect").attr("x", groupedBarX);

            newBars.transition()
                .duration(animationDuration)
                .delay(barDelay)
                .attr("y", groupedBarY)
                .attr("height", barHeight);
        });
}

/**
 * Changes the chart to the selected mode: `stacked` or `grouped`.
 * In `stacked` mode, the bars of each bin are stacked together.
 * In `grouped` mode, the bars of each bin are placed side by side.
 */
function changeChartMode() {
    chartMode = this.value;
    if (chartMode === "stacked") {
        stackBars();
    }
    else {
        groupBars();
    }
}

/**
 * Smoothly transitions the chart to `stacked` mode.
 * In this mode, the bars of each bin are stacked together.
 */
function stackBars() {
    layers.selectAll("rect").transition()
        .duration(animationDuration)
        .delay(barDelay)
        .attr("y", stackedBarY)
        .transition()
            .duration(animationDuration)
            .attr("x", stackedBarX)
            .attr("width", stackedBarWidth);
}

/**
 * Smoothly transitions the chart to `grouped` mode.
 * In this mode, the bars of each bin are placed side by side.
 */
function groupBars() {
    layers.selectAll("rect").transition()
        .duration(animationDuration)
        .delay(barDelay)
        .attr("x", groupedBarX)
        .attr("width", groupedBarWidth)
        .transition()
            .duration(animationDuration)
            .attr("y", groupedBarY);
}

/**
 * Shows the tooltip.
 */
function showTooltip() {
    var hoveredBarIndex,
        tooltip;

    hoveredBarIndex = (d3.mouse(this)[0] / widthPerStack) | 0;
    if (hoveredBarIndex === lastHoveredBarIndex) {
        return;
    }
    lastHoveredBarIndex = hoveredBarIndex;

    layers.selectAll("rect").classed("highlighted", function (d, i) { return (i === hoveredBarIndex); });

    tooltip = $(".js-tooltip");
    tooltip.find(".js-tooltip-table").html(tooltipContent());
    tooltip.css({
        top:  margin.top  + highestBinBarHeight() - tooltip.outerHeight() - tooltipBottomMargin,
        left: margin.left + (hoveredBarIndex * widthPerStack) + (widthPerStack / 2) - (tooltip.outerWidth() / 2),
        opacity: 1,
        // filter: alpha(opacity=1)
    }).fadeIn();
}

function tooltipContent () {
    var bars;

    bars = [];
    layers.each(function (d) {
        bars.unshift({ name: d.name, value: d.values[lastHoveredBarIndex].y.toFixed(4) });
    });

    return tooltipTemplate({ bars: bars });
}

/**
 * Hides the tooltip.
 */
function hideTooltip () {
    $(".js-tooltip").stop().hide();

    layers.selectAll("rect")
        .filter(function (d, i) { return (i === lastHoveredBarIndex); })
        .classed("highlighted", false);

    lastHoveredBarIndex = undefined;
}

/**
 * Calculates the height of the highest (not tallest) bar within a certain bin.
 * @return {Number} The height, in pixels, of the highest bar within a certain bin
 */
function highestBinBarHeight() {
    var bars,
        highestGroupBar;

    if (chartMode === "stacked") {
        highestGroupBar = _.last(layers.data()).values[lastHoveredBarIndex];
        return yScale(highestGroupBar.y0 + highestGroupBar.y);
    }
    else {
        bars = _.map(layers.data(), function (series) { return series.values[lastHoveredBarIndex]; });
        highestGroupBar = _.max(bars, function (bar) { return bar.y; });
        return yScale(highestGroupBar.y);
    }
}

/**
 * Calls a function at the end of **all** transitions.
 * @param {d3.transition} transition A D3 transition
 * @param {Function}      callback   The function to be called at the end of **all** transitions
 */
function endAll (transition, callback) {
    var n;

    if (transition.empty()) {
        callback();
    }
    else {
        n = transition.size();
        transition.each("end", function () {
            n--;
            if (n === 0) {
                callback();
            }
        });
    }
}

// Inspired by Lee Byron's test data generator.
function bumpLayer(n, o) {
  function bump(a) {
    var x = 1 / (.1 + Math.random()),
        y = 2 * Math.random() - .5,
        z = 10 / (.1 + Math.random());
    for (var i = 0; i < n; i++) {
        var w = (i / n - y) * z;
        a[i] += x * Math.exp(-w * w);
    }
  }
  var a = [], i;
  for (i = 0; i < n; ++i) a[i] = o + o * Math.random();
  for (i = 0; i < 5; ++i) bump(a);
  return a.map(function (d, i) { return {x: i, y: Math.max(0, d)}; });
}



  $('.js-stacked-chart-container .controls label:first-of-type').find('input').attr('checked', 'true');
});
