({
	// get settings
	getSettings : function(component) {	
		console.log('getSettings');
		let method = component.get('c.settings');
		//method.setParams({paramname : component.get('v.attrname')});
		method.setCallback(this, function(response) {
			console.log('settings response');
			let state = response.getState();
			if (state==='SUCCESS') {
				let returnval = response.getReturnValue();
				console.log('settings returnval = ' + JSON.stringify(returnval)); 
				component.set('v.settings', returnval);
				component.set("v.showForm", true);
			} else if (state==='INCOMPLETE') { 
				console.log('settings was incomplete');
			} else { // if (state==='ERROR') 
				console.log('settings error:' + JSON.stringify(response));
			}
		});
		$A.enqueueAction(method);
	},

})