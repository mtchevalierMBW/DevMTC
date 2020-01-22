({
	/* get list of credit applications related to this proposal */
	getCreditApplications : function(component) {
		console.log('getCreditApplications');
		let method = component.get("c.ProposalCreditApplications");
		method.setParams({ProposalId : component.get("v.recordId")});
		let me=this;
		method.setCallback(this, function(response) {
			console.log('getCreditApplications->callback');
			component.set("v.showNewCreditAppForm", true);	// re-create form 
			console.log('getCreditApplications response');
			var state = response.getState();
			if (state==="SUCCESS") {
				let returnval = response.getReturnValue();
				//console.log("getCreditApplications returnval = " + JSON.stringify(returnval)); 
				component.set("v.creditapps", returnval);
				//let statusBar = component.find("statusBar");
				//if (statusBar!=null) statusBar.signalProposalUpdated();	// refresh status bar
				//console.log(returnval[0].Decision_Received__c);
			} else if (state==="INCOMPLETE") { 
				console.log("getCreditApplications was incomplete");
			} else { // if (state==="ERROR") 
				console.log("getCreditApplications error:" + JSON.stringify(response));
				me.toastMessage("error", "Unable to get list of credit applications", JSON.stringify(response));
			}
			console.log('getCreditApplications callback ended');
		});
		$A.enqueueAction(method);
	},

	/* Fill in proposal info for new credit application */
	defaultFieldsFromDeal : function(component) {
		console.log("defaultFieldsFromDeal");
		/* Set default values from deal */
		let dealId = component.get("v.dealFields.Id");
		let soloppId = component.get("v.dealFields.dealer__Sales_Lead__c");
		let dealAppRcvd = component.get("v.dealFields.Credit_Application_Received__c");
		let dealVIN = component.get("v.dealFields.dealer__VIN__c");
		console.log(dealId);
		console.log(soloppId);
		console.log(dealAppRcvd);
		console.log(dealVIN);
		component.find("newca_proposal").set("v.value", dealId);
		component.find("newca_solopp").set("v.value", soloppId);
		component.find("newca_status").set("v.value", "Not Submitted");
		component.find("newca_apprcvd").set("v.value", dealAppRcvd);
		component.find("newca_vin").set("v.value", dealVIN);
	},

	/* Delete a credit application */
	deleteCreditApplication : function(component, targetid) {
		console.log('deleteCreditApplication');
		let method = component.get("c.deleteCreditAppRcd");
		method.setParams({recordid : targetid});
		let me=this;
		method.setCallback(this, function(response) {
			console.log('deleteCreditAppRcd response');
			var state = response.getState();
			if (state==="SUCCESS") {
				let returnval = response.getReturnValue();
				console.log("deleteCreditApplication returnval = " + JSON.stringify(returnval)); 
				let statusBar = component.find("statusBar");
				if (statusBar!=null) statusBar.signalProposalUpdated();	// refresh status bar
			} else if (state==="INCOMPLETE") { 
				console.log("deleteCreditApplication was incomplete");
			} else { // if (state==="ERROR") 
				console.log("deleteCreditApplication error:" + JSON.stringify(response));
				me.toastMessage("error", "Unable to delete credit application", JSON.stringify(response));
			}
			me.getCreditApplications(component);
			console.log('deleteCreditApplication callback ended');
		});
		$A.enqueueAction(method);
	},

	/* submit credit app */
	submitCreditApplication : function(component, targetid) {
		console.log('submitCreditApplication');
		let method = component.get("c.submitCreditAppRcd");
		method.setParams({recordid : targetid});
		let me=this;
		method.setCallback(this, function(response) {
			console.log('submitCreditAppRcd response');
			var state = response.getState();
			if (state==="SUCCESS") {
				let returnval = response.getReturnValue();
				console.log("submitCreditApplication returnval = " + JSON.stringify(returnval)); 
				let statusBar = component.find("statusBar");
				if (statusBar!=null) statusBar.signalProposalUpdated();	// refresh status bar
			} else if (state==="INCOMPLETE") { 
				console.log("submitCreditApplication was incomplete");
			} else { // if (state==="ERROR") 
				console.log("submitCreditApplication error:" + JSON.stringify(response));
				me.toastMessage("error", "Unable to submit credit application", JSON.stringify(response));
			}
			me.getCreditApplications(component);
			console.log('submitCreditApplication callback ended');
		});
		$A.enqueueAction(method);
	},

	/* accept credit application */
	acceptCreditApplication : function(component, targetid) {
		console.log('acceptCreditApplication');
		let method = component.get("c.acceptCreditAppRcd");
		method.setParams({recordId : targetid});
		let me=this;
		method.setCallback(this, function(response) {
			console.log('acceptCreditAppRcd response');
			var state = response.getState();
			if (state==="SUCCESS") {
				let returnval = response.getReturnValue();
				console.log("acceptCreditApplication returnval = " + JSON.stringify(returnval)); 
				component.find("dealEditor").reloadRecord({ skipCache: true }); // doesn't always get the new data!
				// didn't help: setTimeout(function(){component.find("dealEditor").reloadRecord();},750);
				let statusBar = component.find("statusBar");
				if (statusBar!=null) statusBar.signalProposalUpdated();	// refresh status bar
			} else if (state==="INCOMPLETE") { 
				console.log("acceptCreditApplication was incomplete");
			} else { // if (state==="ERROR") 
				console.log("acceptCreditApplication error:" + JSON.stringify(response));
				me.toastMessage("error", "Unable to accept credit application", JSON.stringify(response));
			}
			me.getCreditApplications(component);
			console.log('acceptCreditApplication callback ended');
		});
		$A.enqueueAction(method);
	},

	/* set lease/loan section visibility */
	setLeaseLoanVisibility : function(component) {
		console.log('setLeaseLoanVisibility');
		let financetype = component.get("v.dealFields.Contract_Type__c");
		//console.log(financetype);
		let lease = component.find("leaseSection");
		//console.log(lease.getElement().id);
		let loan = component.find("loanSection");
		//console.log(loan.getElement().id);
		if (financetype=='Lease') {
			console.log('unhide lease');
			if ($A.util.hasClass(lease, "hidden")) $A.util.removeClass(lease, "hidden");
			if (!$A.util.hasClass(loan, "hidden")) $A.util.addClass(loan, "hidden");
		} else if (financetype=='Loan') {
			console.log('unhide loan');
			if (!$A.util.hasClass(lease, "hidden")) $A.util.addClass(lease, "hidden");
			if ($A.util.hasClass(loan, "hidden")) $A.util.removeClass(loan, "hidden");
		} else {
			console.log('hide both lease and loan');
			if (!$A.util.hasClass(lease, "hidden")) $A.util.addClass(lease, "hidden");
			if (!$A.util.hasClass(loan, "hidden")) $A.util.addClass(loan, "hidden");
		}
	},

	/* show decision modal */
	helpShowDecisionModal : function(component) {
		console.log('helpShowDecisionModal');
		let modal = component.find("ca_modal");
		$A.util.removeClass(modal, 'hidden');
	},
	/* hide decision modal */
	helpHideDecisionModal : function(component) {
		console.log('helpHideDecisionModal');
		component.set("v.decisionspinner", false);
		let modal = component.find("ca_modal");
		$A.util.addClass(modal, 'hidden');
	},
	/* record approved/declined decision */
	recordDecision : function(component, decision) {
		console.log('recordDecision');
		let dealVIN = component.get("v.dealFields.dealer__VIN__c");
		component.set("v.decisionspinner", true);
		component.set("v.creditappFields.Application_Status__c", decision);
		component.set("v.creditappFields.VIN__c", dealVIN);
		let rightnow = new Date();
		let rightnowstr = rightnow.toISOString();
		component.set("v.creditappFields.Decision_Received__c", rightnowstr);
		//console.log(JSON.stringify(component.get("v.creditappFields")));
		// Works, but generates error msg: component.find("creditappEditor").saveRecord();
		// Try apex controller:
		let method = component.get("c.updateCreditApplication");
		method.setParams({jsonstr : JSON.stringify(component.get("v.creditappFields"))});
		let me=this;
		method.setCallback(this, function(response) {
			console.log('updateCreditApplication response');
			var state = response.getState();
			if (state==="SUCCESS") {
				me.helpHideDecisionModal(component);
				let status = component.get("v.creditappFields.Application_Status__c");
				me.toastMessage("success", "Credit " + status, "Application has been " + status + ".");
				me.getCreditApplications(component);	// refresh list of credit apps to show new data
				let statusBar = component.find("statusBar");
				if (statusBar!=null) statusBar.signalProposalUpdated();	// refresh status bar
			} else if (state==="INCOMPLETE") { 
				console.log("updateCreditApplication was incomplete");
			} else { // if (state==="ERROR") 
				console.log("updateCreditApplication error:" + JSON.stringify(response));
				me.toastMessage("error", "Unable to save credit application", JSON.stringify(response));
			}
		});
		$A.enqueueAction(method);

	},

	/* Toast shortcuts */
	toastMessage : function(toasttype, toasttitle, toastmessage) {
		let toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
			title:toasttitle,
			type:toasttype,
			message:toastmessage
		});
		toastEvent.fire();
	},

})