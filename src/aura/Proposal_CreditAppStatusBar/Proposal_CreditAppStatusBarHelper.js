({
	/* get list of credit applications related to this proposal */
	getCreditApplications : function(component) {
		let method = component.get("c.ProposalCreditApplications");
		method.setParams({ProposalId : component.get("v.recordId")});
		let me=this;
		method.setCallback(this, function(response) {
			component.set("v.showNewCreditAppForm", true);	// re-create form 
			console.log('getCreditApplications response');
			var state = response.getState();
			console.log('getCreditApplications state=' + state);
			if (state==="SUCCESS") {
				let returnval = response.getReturnValue();
				//console.log("getCreditApplications returnval = " + JSON.stringify(returnval)); 
				component.set("v.creditapps", returnval);
				me.setPathStepStatuses(component);
			} else if (state==="INCOMPLETE") { 
				console.log("getCreditApplications was incomplete");
			} else { // if (state==="ERROR") 
				console.log("getCreditApplications error:" + JSON.stringify(response));
				me.toastMessage("error", "Unable to load credit applications", JSON.stringify(response));
			}
		});
		$A.enqueueAction(method);
	},

	setPathStepStatuses : function(component) {
		console.log('setPathStepStatuses');
		let capps = component.get("v.creditapps");
		if (capps==null) capps=[];
		let dealVIN = component.get("v.dealFields.dealer__VIN__c");
		let nbrsubmitted = 0;
		let nbrdeclined = 0;
		let nbrapproved = 0;
		let delivered = false;
		//Status__c,Credit_App_Submitted__c, Decision_Received__c,
		for(let i=0; i<capps.length; i++) {
			if (capps[i].VIN__c==dealVIN) {
				if (capps[i].Credit_App_Submitted__c!=null) ++nbrsubmitted;
				if (capps[i].Application_Status__c=='Approved') ++nbrapproved;
				if (capps[i].Application_Status__c=='Declined') ++nbrdeclined;
				if (capps[i].Application_Status__c=='Delivered') ++nbrapproved; 
				if (capps[i].Application_Status__c=='Delivered') delivered=true; 
			}
		}
		let creditApplicationReceived = component.get("v.dealFields.Credit_Application_Received__c");
		let creditApplication = component.get("v.dealFields.Credit_Application__c");
		console.log(creditApplicationReceived);
		console.log(creditApplication);
		let alldeclined = nbrdeclined==nbrsubmitted;
		let receivedcls = 'slds-path__item' + (creditApplicationReceived==null ? ' slds-is-incomplete' : ' slds-is-complete');
		let incomplete = component.get("v.dealFields.Credit_App_Incomplete__c");
		console.log(incomplete);
		let missingcls = 'slds-path__item' + (incomplete?' slds-is-lost':' hidden');
		let submittedcls = 'slds-path__item';
		if (nbrsubmitted==0) submittedcls += ' slds-is-incomplete';
		else if (nbrsubmitted<capps.length) submittedcls += ' slds-is-complete yellow';
		else submittedcls += ' slds-is-complete';
		let decisioncls = 'slds-path__item';
		if (nbrapproved>0) decisioncls += ' slds-is-complete';
		else if (nbrdeclined==0) decisioncls += ' slds-is-incomplete';
		else if (!delivered && nbrdeclined>0 && nbrdeclined<nbrsubmitted) decisioncls += ' slds-is-complete yellow';
		else if (!delivered && nbrdeclined>0 && nbrdeclined==nbrsubmitted) decisioncls += ' slds-is-lost';
		let deliveredcls = 'slds-path__item ' + (delivered==true ? ' slds-is-won' : ' slds-is-incomplete');
		component.set("v.received", receivedcls);
		component.set("v.missing", missingcls);
		component.set("v.submitted", submittedcls);
		component.set("v.decision", decisioncls);
		component.set("v.delivered", deliveredcls);
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