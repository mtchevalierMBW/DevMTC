({
	doInit : function(component, event, helper) {
		let today = new Date();
		component.set('v.taxdate', today.toISOString());
	},

    CalculateTaxes : function(component, event, helper) {
		console.log('CalculateTaxes');
		let abbrevs = component.get('v.locabbrevs').split(',');
		let params = {
			companyAbbrevs : abbrevs,
			amount  : component.get('v.amount'),
			taxCode : component.get('v.taxcode'),
			taxDate : component.get('v.taxdate'),
			testCompany : component.get('v.testcompany')
		};
		console.log(params);
		let method = component.get('c.CalculateTaxesForLocations');
		method.setParams(params);
		method.setCallback(this, function(response) {
			helper.hideSpinner(component);
			console.log('CalculateTaxesForLocations response');
			let state = response.getState();
			if (state==='SUCCESS') {
				let returnval = response.getReturnValue();
				console.log('CalculateTaxesForLocations returnval = ' + JSON.stringify(returnval)); 
				component.set('v.result', returnval);
			} else if (state==='INCOMPLETE') { 
				console.log('CalculateTaxesForLocations was incomplete');
			} else { // if (state==='ERROR') 
				console.log('CalculateTaxesForLocations error:' + JSON.stringify(response));
			}
		});
		helper.showSpinner(component);
		$A.enqueueAction(method);
	},

})