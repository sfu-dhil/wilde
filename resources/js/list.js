
(function ($) {
    
    var config = {
        search: true,
        trimOnSearch: false,
        clickToSelect: true,
        sortable: false,
        filterStrictSearch: false,
        filterControl: true,
        filterDataCollector: function (fieldValue, data, formattedValue) {
            var date = $(fieldValue).text();
            return date;
        },
        
        columns:[ {
            // The date field must be configured explicitly or the select widget doesn't show up.
            field: "date",
            filterControl: "select"
        }]
    };
    
    $("#tbl-browser").bootstrapTable(config);
})(jQuery);
