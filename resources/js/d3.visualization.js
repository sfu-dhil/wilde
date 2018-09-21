  $(window).ready(function() {

    console.log("ready");

    var width = 900,
        height = 450;

    var color = d3.scale.category10();

    var projection = d3.geo.bromley()
      .scale(180)
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

    var svg = d3.select("#content").append("svg")
      .attr("width", width)
      .attr("height", height);

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
        })
        // .attr("id", function(d) { return d.id;})
        //.style("fill", function(d, i) { return color(d.color = d3.max(neighbors[i], function(n) { return countries[n].color; }) + 1 | 0); });
        // .style("fill", "#B7B6B2" )
        // .on('mouseover', function(d, i) {
        //   var currentCountry = this;
        //   d3.select(this).classed("newspaper-country").style({
        //     'fill': 'red'
        //   });
        //   // console.log(countries[i].properties);
        // })
        // .on('mouseout', function(d, i) {
        //   d3.select(this).classed("newspaper-country").style({
        //    'fill': '#CBC9C5'
        //   });
        // });

      svg.insert("path", ".graticule")
        .datum(topojson.mesh(world, world.objects.countries, function(a, b) { return a !== b; }))
        .attr("class", "boundary")
        .attr("d", path);

    d3.tsv("resources/d3_data/rest_777.txt")
      .row(function(d) {
        return {
          permalink: d.permalink,
          lat: parseFloat(d.lat),
          lng: parseFloat(d.long),
          city: d.city,
          created_at: moment(d.created_at,"YYYY-MM-DD HH:mm:ss").unix()
        };
      })
      .get(function(err, rows) {
        if (err) return console.error(err);

        window.window.site_data = rows;
      });


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

    var minDateUnix = moment('2014-07-01', "YYYY MM DD").unix();
    var maxDateUnix = moment('2015-07-21', "YYYY MM DD").unix();
    var secondsInDay = 60 * 60 * 24;

    var mySliderStart = minDateUnix;
    var mySliderEnd = maxDateUnix;
    var mySlider = d3.slider()
      .axis(true)
      .min(mySliderStart)
      .max(mySliderEnd)
      .step(secondsInDay)
      .on("slide", function(evt, value) {
        var newData = _(site_data).filter( function(site) {
          return site.created_at < value;
        })
        console.log("New set size ", newData.length);

        displaySites(newData);
    });
    d3.select('#slider3').call(mySlider);



    // timer start
    var myTimer;
    var myTimerDuration = 5000; // 5 seconds
    var myTimerInterval = 300;


    d3.select("#slider-play").on("click", function() {
      clearInterval(myTimer);
      myTimer = setInterval (function() {
        var b = mySlider;
        var t = (mySlider.value() + 100000) % (mySliderEnd + 1);
        if (t == 0) {
          t = +b.property("min");
        }

        updateSlider(t);

      }, myTimerInterval);
    });
    d3.select("#slider-pause").on("click", function() {
      clearInterval(myTimer);
      updateSlider(1415000000);
    });
    // timer end


    function updateSlider(new_value) {
      console.log("setting slider value to " + new_value);
      mySlider.value(new_value);
      // d3.select('#slider3').dispatchEvent('click');
      // moveHandle(new_value);
    }


    d3.select(self.frameElement).style("height", height + "px");

    // load and display the cities
    var g = svg.append("g");
    d3.csv("resources/d3_data/cities.csv", function(error, data) {
      g.selectAll("circle")
        .data(data)
        .enter()
        .append("a")
    	  .attr("xlink:href", function(d) {
    		  return "https://www.google.com/search?q="+d.city;}
    	  )
        .append("circle")
        .attr("cx", function(d) {
          return projection([d.lon, d.lat])[0];
        })
        .attr("cy", function(d) {
          return projection([d.lon, d.lat])[1];
        })
        .attr("r", 5)
        .style("fill", "red");
    });
  });
