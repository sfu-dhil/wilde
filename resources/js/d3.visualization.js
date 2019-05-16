// function responsivefy(svg) {
//     // get container + svg aspect ratio
//     var container = d3.select(svg.node().parentNode),
//         width = parseInt(svg.style("width")),
//         height = parseInt(svg.style("height")),
//         aspect = width / height;
//
//     // add viewBox and preserveAspectRatio properties,
//     // and call resize so that svg resizes on inital page load
//     svg.attr("viewBox", "0 0 " + width + " " + height)
//         .attr("perserveAspectRatio", "xMinYMid")
//         .call(resize);
//
//     // to register multiple listeners for same event type,
//     // you need to add namespace, i.e., 'click.foo'
//     // necessary if you call invoke this function for multiple svgs
//     // api docs: https://github.com/mbostock/d3/wiki/Selections#on
//     d3.select(window).on("resize." + container.attr("id"), resize);
//
//     // get width of container and resize svg to fit it
//     function resize() {
//         var targetWidth = parseInt(container.style("width"));
//         svg.attr("width", targetWidth);
//         svg.attr("height", Math.round(targetWidth / aspect));
//     }
//
//     console.log("resizing: " + width + "/" + height);
//
// }

var aspect_ratio = 2;

function resizeMap() {
  console.log("resizing");
  var new_width = $('#content').width() - 1,
      new_height = new_width / aspect_ratio;

  console.log(new_width);

  // Sometimes when scaling the window, the content width doesn't have time to
  // catch up and it sets the svg width greater than the window size.
  // This overrides that.
  if ($(window).width() < new_width) {
    new_width = $(window).width() - 30;
    console.log('Window is wider than content. Resizing content.' + new_width);
    $('#content').width(new_width);
  }
  else {
    $('#content').css('width', '');
  }

  new_height = new_width / aspect_ratio;
  $('.map-wrapper svg').attr('width', new_width)
                       .attr('height', new_height)
                       .attr('viewBox', '0 0 ' + new_width + ' ' + new_height);
}

$(window).resize(function() {
  resizeMap();
});

$(document).ready(function() {
  console.log("loaded map javascript");
    var width = 1160;//$('#content').width(),
        height = width / aspect_ratio;

    var color = d3.scale.category10();

    var projection = d3.geo.bromley()
      .scale(170)
      .translate([width / 2, height / 2])
      .center([0, 15]) // set centre to further North
      .precision(.1);

    var path = d3.geo.path()
      .projection(projection);

    var newspaperCountries = ["Algeria", "Australia", "Belgium", "Britain", "Egypt", "France",
      "Germany", "Italy", "Jamaica", "Malta", "Mauritius", "Mexico", "Panama", "Puerto Rico",
      "Spain", "Sri Lanka", "Switzerland", "Turkey", "United States",
      "Ottoman Empire", "Lombardy", "United Kingdom", "Ceylon", "United States of America"];

    var graticule = d3.geo.graticule();

    // var svg = d3.select("#content").append("div").attr("class","map-wrapper").append("svg")
    var svg = d3.select(".map-wrapper").append("svg")
      // .attr("width", width)
      // .attr("height", height)
      // .attr("x","0")
      // .attr("y", "0")
      // .attr("class", "city-map")
      .attr('viewBox', '0 0 ' + width + ' ' + height)
      .attr('preserveAspectRatio', "xMidYMid meet");
      // .call(responsivefy);

    svg.append("defs").append("path")
      .datum({type: "Sphere"})
      .attr("id", "sphere")
      .attr("d", path);

    svg.append("use")
      .attr("class", "stroke")
      .attr("xlink:href", "#sphere");

    svg.append("use")
      .attr("class", "fill")
      .attr("xlink:href", "#sphere");

    svg.append("path")
      .datum(graticule)
      .attr("class", "graticule")
      .attr("d", path);

    d3.json("https://gist.githubusercontent.com/catherineomega/0c048a632020c8f91dc465ad674d49e6/raw/world-110m2.json", function(error, world, i) {
      if (error) throw error;

      var countries = topojson.feature(world, world.objects.countries).features,
          neighbors = topojson.neighbors(world.objects.countries.geometries);

      svg.selectAll(".country")
        .data(countries)
        .enter().insert("path", ".graticule")
        // .attr("class", "country")
        .attr("d", path)
        .attr("name", function(d, i) {
          return countries[i].properties.NAME;
        })
        .attr("class", function(d, i) {
          // console.log(countries[i].properties);
          if (newspaperCountries.includes(countries[i].properties.NAME)) {
            return "country newspaper-countries";
          }
          else {
            return "country";
          }
        });
        // .attr("id", function(d) { return d.id;})
        // .style("fill", function(d, i) { return color(d.color = d3.max(neighbors[i], function(n) { return countries[n].color; }) + 1 | 0); });
        // .style("fill", "#B7B6B2" )
        // .on('mouseover', function(d, i) {
        //   var currentCountry = this;
        //   d3.select(this).classed("newspaper-country").style({
        //     'fill': 'red'
        //   });
        //   // console.log(countries[i].properties);
        // })
        // .on('mouseout', function(d, i) {
        //   d3.select(this).classed("newspaper-country") //.style({
        //   //  'fill': '#CBC9C5'
        //   // });
        // });

      svg.insert("path", ".graticule")
        .datum(topojson.mesh(world, world.objects.countries, function(a, b) { return a !== b; }))
        .attr("class", "boundary")
        .attr("d", path);

    // d3.tsv("resources/d3_data/rest_777.txt")
    //   .row(function(d) {
    //     return {
    //       permalink: d.permalink,
    //       lat: parseFloat(d.lat),
    //       lng: parseFloat(d.long),
    //       city: d.city,
    //       created_at: moment(d.created_at,"YYYY-MM-DD HH:mm:ss").unix()
    //     };
    //   })
    //   .get(function(err, rows) {
    //     if (err) return console.error(err);
    //
    //     window.window.site_data = rows;
    //   });
    });


    var displaySites = function(data) {
    var sites = svg.selectAll(".site")
        .data(data, function(d) {
          return d.permalink;
        });

    sites.enter().append("circle")
        .attr("class", "site")
        .attr("cx", function(d) {
          return projection([d.lng, d.lat])[0];
        })
        .attr("cy", function(d) {
          return projection([d.lng, d.lat])[1];
        })
        .attr("r", 1)
        .transition().duration(400)
          .attr("r", 5);

    sites.exit()
      .transition().duration(200)
        .attr("r",1)
        .remove();
    };

    // var minDateUnix = moment('2014-07-01', "YYYY MM DD").unix();
    // var maxDateUnix = moment('2015-07-21', "YYYY MM DD").unix();
    // var secondsInDay = 60 * 60 * 24;

    // var mySliderStart = 18950401;
    // var mySliderEnd = 18950615;
    // var mySlider = d3.slider()
    //   .axis(true)
    //   .min(mySliderStart)
    //   .max(mySliderEnd)
    //   .step(1)
    //   .on("slide", function(evt, value) {
    //     var newData = _(site_data).filter( function(site) {
    //       return site.created_at < value;
    //     })
    //     // console.log("New set size ", newData.length);
    //
    //     displaySites(newData);
    // });
    // d3.select('#slider3').call(mySlider);
    //
    //
    //
    // // timer start
    // var myTimer;
    // var myTimerDuration = 5000; // 5 seconds
    // var myTimerInterval = 300;


    // d3.select("#slider-play").on("click", function() {
    //   clearInterval(myTimer);
    //   myTimer = setInterval (function() {
    //     var b = mySlider;
    //     // var t = (mySlider.value() + 100000) % (mySliderEnd + 1);
    //     var t = (mySlider.value()) % (mySliderEnd + 1);
    //     if (t == 0) {
    //       t = +b.property("min");
    //     }
    //
    //     updateSlider(t);
    //
    //   }, myTimerInterval);
    // });
    // d3.select("#slider-pause").on("click", function() {
    //   clearInterval(myTimer);
    //   // updateSlider(1415000000);
    // });
    // // timer end
    //
    //
    // function updateSlider(new_value) {
    //   console.log("setting slider value to " + new_value);
    //   mySlider.value(new_value);
    //   // d3.select('#slider3').dispatchEvent('click');
    //   // moveHandle(new_value);
    // }


    // We aappenddd the tooltip elements here because Xquery doesn't like it.
    var tooltip = d3.select('.map-wrapper').append('div').attr('class', 'tooltip js-tooltip');

    // todo: get the largest number of reports for this function.
    var length = 123,
      color = d3.scale.linear().domain([1,length])
        .interpolate(d3.interpolateHcl)
        .range([d3.rgb("#FFC4BA"), d3.rgb('#F9292E')]);

    // load and display the cities
    var g = svg.append("g");
    d3.csv("resources/d3_data/wilde_cities_no_countries.csv", function(error, data) {
      // console.log(data);
      g.selectAll("circle")
        .data(data)
        .enter()
        .append("a")
    	  .attr("xlink:href", function(d) {
    		  return "list.html?&search=" + d.name;
    	  })
        .append("circle")
        .attr("cx", function(d) {
          return projection([d.longitude, d.latitude])[0];
        })
        .attr("cy", function(d) {
          return projection([d.longitude, d.latitude])[1];
        })
        .attr("r", 5)
        .style("fill", function(d) {
          return color([d.reports]);
        })
        .on('mouseover', function(d) {
          var mouse = d3.mouse(svg.node()).map(function(d) {
            return parseInt(d);
          });
          //
          // var this_node = svg.node().map(function(d) {
          //   return parseInt(d);
          // });
          //
          console.log(mouse);

          var x = mouse[0];
          var y = mouse[1];
          console.log(x + " " + y);

          // var svg_original_width = $('.map-wrapper svg').attr('viewBox').split(/\s+|,/)[2],
          //     svg_original_height = $('.map-wrapper svg')
          //     wrapper_current_width = $('.map-wrapper').width(),
          //     wrapper_current_height = $('.map-wrapper').height(),.attr('viewBox').split(/\s+|,/)[3],
          //     scaled_width = x / svg_original_width * wrapper_current_width,
          //     scaled_height = y / svg_original_height * wrapper_current_height;
          // console.log(scaled_width);

          var cursor_x = (window.Event) ? event.pageX : event.clientX + (document.documentElement.scrollLeft ? document.documentElement.scrollLeft : document.body.scrollLeft);
          var cursor_y = (window.Event) ? event.pageY : event.clientY + (document.documentElement.scrollTop ? document.documentElement.scrollTop : document.body.scrollTop);
          console.log(cursor_x + " " + cursor_y);


          // // The magic function.
          // function getScreenCoords(x, y, ctm) {
          //   var xn = ctm.e + x*ctm.a + y*ctm.c;
          //   var yn = ctm.f + x*ctm.b + y*ctm.d;
          //   return { x: xn, y: yn };
          // }
          // //
          // var circle = this,
          // cx = +circle.getAttribute('cx'),
          // cy = +circle.getAttribute('cy'),
          // ctm = circle.getCTM(),
          // coords = getScreenCoords(cx, cy, ctm);
          // console.log(coords.x, coords.y); // shows coords relative to my svg container
          // console.log('current tooltip dimensions: ' + $('.map-wrapper .tooltip').width() + ", " + $('.map-wrapper .tooltip').height());
          tooltip.classed('hidden', false)
            .attr('style', 'left:' + (cursor_x - $('.map-wrapper .tooltip').width()) + 'px; top:' + (cursor_y - 180) + 'px; opacity: 1;')
            .html('<div class="tooltip-wrapper">' + d.name + " (" + d.reports + " reports)</div>");
          tooltip.classed('hidden', false)
            .attr('style', 'left:' + (cursor_x - $('.map-wrapper .tooltip').width()) + 'px; top:' + (cursor_y - 180) + 'px; opacity: 1;')
            .html('<div class="tooltip-wrapper">' + d.name + " (" + d.reports + " reports)</div>");
        })
        .on('mouseout', function() {
          tooltip.classed('hidden', true).attr('style', 'opacity: 0;');
        })
    });
  });
