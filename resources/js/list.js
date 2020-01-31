
(function($){

	var config = {
		filterControl: true,
		search: true,
		trimOnSearch: false,
		clickToSelect: true,

		columns: [
			{
				field: "date",
				sortable: true,
				filterControl: "select",
				filterStrictSearch: false,
				filterDataCollector: function(fieldValue, data, formattedValue) {
					var date = $(fieldValue).text();
					return date;
				}
			}
		]
	};

	$("#tbl-browser").bootstrapTable(config);

})(jQuery);
