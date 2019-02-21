var hash = window.location.hash;
hash && $('ul.nav a[href="' + hash + '"]').tab('show');

$('.nav-tabs a').click(function (e) {
  $(this).tab('show');
  var scrollmem = $('body').scrollTop();
  window.location.hash = this.hash;
  $('html,body').scrollTop(scrollmem);
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
