({
	// getAuthorization
	// determine if user is authorized to see transaction line items (which is basis for this component)
	getAuthorization : function(component) {
		console.log('getAuthorization');
		let method = component.get("c.AuthorizedToTransactionLines");
		//method.setParams({paramname : component.get("v.attrname")});
		method.setCallback(this, function(response) {
			console.log('AuthorizedToTransactionLines response');
			var state = response.getState();
			if (state==="SUCCESS") {
				let returnval = response.getReturnValue();
				console.log("AuthorizedToTransactionLines returnval = " + JSON.stringify(returnval)); 
				component.set("v.authorized", returnval);
				this.getAccountBalances(component);
			} else if (state==="INCOMPLETE") { 
				console.log("AuthorizedToTransactionLines was incomplete");
			} else { // if (state==="ERROR") 
				console.log("AuthorizedToTransactionLines error:" + JSON.stringify(response));
			}
		});
		$A.enqueueAction(method);
	},

	// getReportURL
	// get the Account Balance report's url; this report accepts fv0=account name & fv1=company name
	getReportURL : function(component) {
		console.log('getReportURL');
		let method = component.get("c.ReportURL");
		//method.setParams({paramname : component.get("v.attrname")});
		method.setCallback(this, function(response) {
			console.log('ReportURL response');
			var state = response.getState();
			if (state==="SUCCESS") {
				let returnval = response.getReturnValue();
				console.log("ReportURL returnval = " + JSON.stringify(returnval)); 
				component.set("v.reporturl", returnval);
			} else if (state==="INCOMPLETE") { 
				console.log("ReportURL was incomplete");
			} else { // if (state==="ERROR") 
				console.log("ReportURL error:" + JSON.stringify(response));
			}
		});
		$A.enqueueAction(method);
	},

	// getAccountBalances
	// get list of all open balances for this account for each company
	getAccountBalances : function(component) {
		console.log('getAccountBalances');
		let method = component.get("c.AccountBalancesByCompany");
		method.setParams({accountId : component.get("v.recordId")});
		method.setCallback(this, function(response) {
			console.log('AccountBalancesByCompany response');
			var state = response.getState();
			component.set("v.spinner",false);
			if (state==="SUCCESS") {
				let returnval = response.getReturnValue();
				console.log("AccountBalancesByCompany returnval = " + JSON.stringify(returnval)); 
				component.set("v.balances", returnval);
				component.set("v.balancecount", returnval.length);
			} else if (state==="INCOMPLETE") { 
				console.log("AccountBalancesByCompany was incomplete");
			} else { // if (state==="ERROR") 
				console.log("AccountBalancesByCompany error:" + JSON.stringify(response));
			}
		});
		$A.enqueueAction(method);
    },
})