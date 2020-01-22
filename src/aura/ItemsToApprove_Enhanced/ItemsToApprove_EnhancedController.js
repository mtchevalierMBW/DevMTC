({
    doInit : function(component, event, helper) {
		helper.GetColumnLabels(component);
		helper.GetApprovalItems(component);
	},
	
	initFilter: function(component) {
		console.log('initPage');
		jQuery("document").ready(function(){
			console.log('jQuery ready');
			function enableFilter() {
				//console.log('enableFilter');
				//jQuery("input[id$=FilterTextBox]").focus(function() {
				//	// hide bottom button version of text search box
				//	// only showing top buttons; already hiding all bottom buttons; $jq("input[id$=bottom\\:FilterTextBox]").hide();
				//	// add index column with all content.
				//	if (jQuery(".filterable tr:has(td.indexColumn)".length==0)) {
				//		jQuery(".filterable tr:has(td)").each(function(){
				//			console.log(this);
				//			console.log(jQuery(this));
				//			console.log(jQuery(this).html());
				//			var t = jQuery(this).text().toLowerCase(); //all row text
				//			jQuery("<td class='indexColumn'></td>").hide().text(t).appendTo(this);
				//		});//each tr
				//	}
				//});
				jQuery("input[id$=FilterTextBox]").keyup(function(){
					console.log('keyup');
					var s = jQuery(this).val().toLowerCase().split(" ");
					//show all rows
					jQuery(".filterable tbody tr:hidden").show();
					jQuery.each(s, function() {
						console.log('looking for: ' + this);
						let term = this;
						jQuery(".filterable tbody tr:visible").each(function() {
							var t = jQuery(this).text().toLowerCase();
							//console.log(t);
							console.log('"'+term+'" found in "' + t + '"?');
							console.log(t.indexOf(term));
							if (t.indexOf(term)==-1) jQuery(this).hide();
						});
						//jQuery(".filterable tr:visible .indexColumn:not(:contains('"
						// + this + "'))").parent().hide();
					});//each
				});//key up.
			}
			enableFilter();	
		});
	},

})