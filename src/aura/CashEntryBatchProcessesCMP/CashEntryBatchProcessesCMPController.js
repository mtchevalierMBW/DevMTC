({

	create : function(component, event, helper) {
		console.log('create cash entries');
		helper.showSpinner(component);
		let method = component.get("c.launchCreateCashEntries");
		method.setParams({selectcriteria : component.get("v.createcriteria")});
		method.setCallback(this, function(response) {
			console.log('launchCreateCashEntries response');
			helper.hideSpinner(component);
			let state = response.getState();
			if (state==="SUCCESS") {
				let returnval = response.getReturnValue();
				console.log("launchCreateCashEntries returnval = " + JSON.stringify(returnval)); 
				helper.toastMessage('success', 'Cash Entry Create', 'Submitted job to automatically create cash entries.');
			} else if (state==="INCOMPLETE") { 
				console.log("launchCreateCashEntries was incomplete");
			} else { // if (state==="ERROR") 
				console.log("launchCreateCashEntries error:" + JSON.stringify(response));
			}
		});
		$A.enqueueAction(method);
		console.log('running c.launchCreateCashEntries');
	},

	post : function(component, event, helper) {
		console.log('post cash entries');
		helper.showSpinner(component);
		let method = component.get("c.launchPostCashEntries");
		//method.setParams({paramname : component.get("v.attrname")});
		method.setCallback(this, function(response) {
			console.log('launchPostCashEntries response');
			helper.hideSpinner(component);
			let state = response.getState();
			if (state==="SUCCESS") {
				let returnval = response.getReturnValue();
				console.log("launchPostCashEntries returnval = " + JSON.stringify(returnval)); 
				helper.toastMessage('success', 'Cash Entry Posting', 'Submitted job to automatically post cash entries.');
			} else if (state==="INCOMPLETE") { 
				console.log("launchPostCashEntries was incomplete");
			} else { // if (state==="ERROR") 
				console.log("launchPostCashEntries error:" + JSON.stringify(response));
			}
		});
		$A.enqueueAction(method);
		console.log('running c.launchPostCashEntries');
	},

	match : function(component, event, helper) {
		console.log('match cash');
		helper.showSpinner(component);
		let method = component.get("c.launchCashMatching");
		//method.setParams({paramname : component.get("v.attrname")});
		method.setCallback(this, function(response) {
			console.log('launchCashMatching response');
			helper.hideSpinner(component);
			let state = response.getState();
			if (state==="SUCCESS") {
				let returnval = response.getReturnValue();
				console.log("launchCashMatching returnval = " + JSON.stringify(returnval)); 
				helper.toastMessage('success', 'Cash Matching', 'Submitted job to automatically match automated cash entries.');
			} else if (state==="INCOMPLETE") { 
				console.log("launchCashMatching was incomplete");
			} else { // if (state==="ERROR") 
				console.log("launchCashMatching error:" + JSON.stringify(response));
			}
		});
		$A.enqueueAction(method);
		console.log('running c.launchCashMatching');
	},

})