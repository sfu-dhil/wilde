
(function ($) {
    
    var config = {
        search: true,
        trimOnSearch: false,
        clickToSelect: true,
        sortable: false,
        filterStrictSearch: false,
        filterControl: true,
        
        columns:[ {
            // The date field must be configured explicitly or the select widget doesn't show up.
            field: "date",
            title: "Date",
            filterControl: "select",
            filterDataCollector: function (fieldValue, data, formattedValue) {
                var date = $(fieldValue).text();
                return date;
            }
        }]
    };
    
    $("#tbl-browser").bootstrapTable(config);
})(jQuery);
