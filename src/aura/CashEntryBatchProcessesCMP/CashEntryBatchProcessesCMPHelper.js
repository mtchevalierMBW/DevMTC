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
	
	/* Toast shortcuts */
	toastMessage : function(toasttype, toasttitle, toastmessage) {
		console.log('toastMessage');
		let toastEvent = $A.get('e.force:showToast');
		toastEvent.setParams({
			title:toasttitle,
			type:toasttype,
			message:toastmessage
		});
		toastEvent.fire();
	},
})