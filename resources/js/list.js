// var hash = window.location.hash;
// hash && $('ul.nav a[href="' + hash + '"]').tab('show');
//
// $('.nav-tabs a').click(function (e) {
//   $(this).tab('show');
//   var scrollmem = $('body').scrollTop();
//   window.location.hash = this.hash;
//   $('html,body').scrollTop(scrollmem);
// });


$(".bootstrap-table").on('change','.search input',function () { alert('helo'); });

$(document).keyup(function(event) {
    if ($(".search input").is(":focus") && event.key == "Enter") {
      // Do work
      console.log("third time's the charm");
    }
});

$('.search input.form-control').each(function(i) {
  console.log(i)
});

$('.search input.form-control').change(function() {
  var new_search_value = $(this).val();
  console.log(new_search_value);
});


// debugging bootstraptable.
// console.log("Started.");
// $('#tbl-browser').on('onAll.bs.table', function (e, arg1, arg2) {
//     console.log("event");
// });

// $('#tbl-browser').bootstrapTable({
//   filterStrictSearch: true,
//   onAll: function (whatChanged, changedTo) {
//     if (whatChanged == "column-search.bs.table") {
//       console.log("The table changed!");
//
//       var field_that_changed = changedTo[0];//changedTo.split(',').slice(0).join(',')
//       console.log(field_that_changed);
//
//       // if
//       // "bootstrap-table-filter-control-city"
//       if (field_that_changed == "region") {
//         $('.bootstrap-table-filter-control-city').val("");
//       }
//     }
//     // console.log(whatChanged + " !!! " + changedTo);
//   }
// });
//   onAll: function (whatChanged, changedTo) {
