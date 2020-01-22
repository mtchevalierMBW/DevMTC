({
	
	/* show the spinner during long-running operations (like posting) */
	showSpinner : function(component) {
		console.log('showSpinner');
		component.set('v.spinner',true);
	},
	
	/* hide the spinner after long-running operations have completed */
	hideSpinner : function(component) {
		console.log('hideSpinner');
		component.set('v.spinner',false);
	},

})