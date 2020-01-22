({
    doInit : function(component, event, helper) {
		console.log('proposal_F_and_IController->doInit');
		helper.getCreditApplications(component);
	},
	refreshCreditApplications: function(component,event,helper) {
		console.log('proposal_F_and_IController->refreshCreditApplications');
		helper.getCreditApplications(component);
	},
	
	/* mark credit application as submitted (or re-submitted) */
	submitCreditApp : function(component, event, helper) {
		console.log('proposal_F_and_IController->submitCreditApp');
		let targetid = event.currentTarget.dataset.targetid;
		let fincomp = event.currentTarget.dataset.fincomp;
		console.log(targetid);
		let submitdate = event.currentTarget.dataset.submitdate;
		//console.log(submitdate);
		if (submitdate==null || confirm('Re-submit application to ' + fincomp + '?')) {
			console.log('Submit/Resubmit');
			helper.submitCreditApplication(component, targetid);
		}
	},

	/* credit application decision details */
	decisionModal: function(component, event, helper) {
		console.log('proposal_F_and_IController->decisionModal');
		let targetid = event.currentTarget.dataset.targetid;
		console.log('Reloading credit app for id: ' + targetid);
		component.set("v.creditappId", targetid);
		component.find("creditappEditor").reloadRecord({ skipCache: true });
		helper.helpShowDecisionModal(component);
	},
	hideDecisionModal: function(component, event, helper) {
		console.log('proposal_F_and_IController->hideDecisionModal');
		helper.helpHideDecisionModal(component);
	},
	decisionDeclined: function(component, event, helper) {
		console.log('proposal_F_and_IController->decisionDeclined');
		helper.recordDecision(component, 'Declined');
	},
	decisionApproved: function(component, event, helper) {
		console.log('proposal_F_and_IController->decisionApproved');
		let newsts = 'Approved';
		if (component.get('v.creditappFields.Counter_Offer__c')==true) {
			newsts = 'Countered';
		}
		helper.recordDecision(component, newsts);
	},

	/* credit application decision details */
	acceptOffer: function(component, event, helper) {
		console.log('proposal_F_and_IController->acceptOffer');
		let targetid = event.currentTarget.dataset.targetid;
		console.log(targetid);
		let financecomp = event.currentTarget.dataset.fincomp;
		//console.log(financecomp);
		if (confirm('Accept offer from ' + financecomp + '?')) {
			console.log('accept confirmed');
			helper.acceptCreditApplication(component, targetid);
		}
	},
	
	/* contractType changed */
	contractTypeChange : function(component, event, helper) {
		console.log('proposal_F_and_IController->contractTypeChange');
		helper.setLeaseLoanVisibility(component);
	},

	/* Proposal updated */
	dealRcdUpdated: function(component, event, helper) { 
		console.log('proposal_F_and_IController->dealRcdUpdated'); 
		let eventParams = event.getParams(); 
		//console.log(eventParams); 
		console.log(eventParams.changeType); 
		
		if (eventParams.changeType === "LOADED") { 
			console.log("proposal_F_and_IController->Deal record is loaded successfully."); 
			console.log('Deal Credit App Status=' + component.get('v.dealFields.Credit_Application_Status__c'));
			// changed solution opp ... (don't reload solution opp if id is unchanged as that would reload old fico score)
			if (component.get("v.dealFields.dealer__Sales_Lead__c")!=component.get("v.solutionoppId")) {
				component.set("v.solutionoppId", component.get("v.dealFields.dealer__Sales_Lead__c"));
				console.log("Set solution opp Id: " + component.get("v.solutionoppId"));
				component.find("soloppEditor").reloadRecord({ skipCache: true });
			}
			// Show appropriate lease/loan section
			helper.setLeaseLoanVisibility(component);
			component.set("v.overallStatus",component.get("v.dealFields.Credit_Application_Status__c"));
		} else if(eventParams.changeType === "CHANGED") { 
			console.log("proposal_F_and_IController->Deal record is changed (saved)"); 
			let statusBar = component.find("statusBar");
			if (statusBar!=null) statusBar.signalProposalUpdated();
		} else if(eventParams.changeType === "REMOVED") { 
			console.log("The proposal was deleted"); 
		} else if(eventParams.changeType === "ERROR") { 
			console.log("Error loading proposal");
			var params = eventParams;
			for (var f in params) console.log(f + ' = ' + params[f])
			console.log(event);
			helper.toastMessage("error", "Unable to load or save proposal", JSON.stringify(event));
		} 
		console.log('dealRcdUpdated completed');
	},  

	/* Solution opportunity updated */
	soloppRcdUpdated: function(component, event, helper) { 
		console.log('proposal_F_and_IController->soloppRcdUpdated'); 
		let eventParams = event.getParams(); 
		//console.log(eventParams); 
		console.log(eventParams.changeType); 
		
		if (eventParams.changeType === "LOADED") { 
			console.log("Solution Opp record is loaded successfully."); 
		} else if(eventParams.changeType === "CHANGED") { 
			console.log("Solution Opp record is changed (saved)"); 
			// refresh the page 
			// $A.get('e.force:refreshView').fire(); 
		} else if(eventParams.changeType === "REMOVED") { 
			console.log("Solution Opportunity record was deleted"); 
		} else if(eventParams.changeType === "ERROR") { 
			console.log("Error loading solution opportunity");
			var params = eventParams;
			for (var f in params) console.log(f + ' = ' + params[f])
			console.log(event);
			helper.toastMessage("error", "Unable to load or save solution opportunity", JSON.stringify(event));
		} 
		console.log('soloppRcdUpdated completed');
	},  

	/* Credit Application Updated - used on decision modal, so show modal when record is loaded */
	creditappRcdUpdated: function(component, event, helper) {
		console.log('proposal_F_and_IController->creditappRcdUpdated'); 
		let eventParams = event.getParams(); 
		//console.log(eventParams); 
		console.log(eventParams.changeType); 
		
		if (eventParams.changeType === "LOADED") { 
			console.log("Credit Application record is loaded successfully."); 
			console.log(component.get("v.creditappId"));
			//if (component.get("v.creditappId")!=null) {
			//	helper.helpShowDecisionModal(component);
			//}
		} else if(eventParams.changeType === "CHANGED") { 
			console.log("Credit Application record is changed (saved)"); 
			helper.helpHideDecisionModal(component);
			let status = component.get("v.creditappFields.Application_Status__c");
			helper.toastMessage("success", "Credit " + status, "Application has been " + status + ".");
			helper.getCreditApplications(component);	// refresh list of credit apps to show new data
			component.find("dealEditor").reloadRecord({ skipCache: true });
			let statusBar = component.find("statusBar");
			if (statusBar!=null) statusBar.signalProposalUpdated();	// refresh status bar
	} else if(eventParams.changeType === "REMOVED") { 
			console.log("Credit Application record was deleted"); 
		} else if(eventParams.changeType === "ERROR") { 
			console.log("Error loading Credit Application ");
			var params = eventParams;
			for (var f in params) console.log(f + ' = ' + params[f])
			console.log(event);
			helper.toastMessage("error", "Unable to load or save credit application", JSON.stringify(event));
		} 
		console.log('creditappRcdUpdated complete');
	},

	/* new Credit Application */
	addNewCreditApp: function(component, event, helper) {
		let financecomp = component.find("newca_financecompany");
		let fcvalue = financecomp.get("v.value");
		if (fcvalue==null) alert("Finance company is required");
		else component.find("newcreditapp").submit();
	},
	newCreditAppSave : function(component, event, helper) {
		console.log("proposal_F_and_IController->newCreditAppSave");
		// default amount financed from proposal - handle in trigger
		// component.set("v.creditappFields.Offer_Principle__c",component.get("v.dealFields.Contract_Amount_Financed__c"));
		let dealAppRcvd = component.get("v.dealFields.Credit_Application_Received__c");
		component.find("newca_apprcvd").set(dealAppRcvd);
	},
	newCreditAppSuccess : function(component, event, helper) {
		console.log("proposal_F_and_IController->newCreditAppSuccess");
		component.find("newca_financecompany").set("v.value", "");
		component.set("v.showNewCreditAppForm", false);
		// refresh list of credit applications
		helper.getCreditApplications(component);	
		
	},
	newCreditAppError : function(component, event, helper) {
		console.log("proposal_F_and_IController->newCreditAppError");
		
	},
	loadedCreditApp : function(component, event, helper) {
		console.log("proposal_F_and_IController->loadedCreditApp");
		helper.defaultFieldsFromDeal(component);
	},

	/* select-list-based actions on credit applications */
	editCreditApp : function(component, event, helper) {
		console.log('proposal_F_and_IController->editCreditApp');
		let targetid = event.currentTarget.dataset.targetid;
		$A.get("e.force:editRecord").setParams({
			"recordId":targetid
		}).fire();
	},
	deleteCreditApp : function(component, event, helper) {
		console.log('proposal_F_and_IController->deleteCreditApp');
		let targetid = event.currentTarget.dataset.targetid;
		// get finance company name for confirmation dialog
		let financecomp = event.currentTarget.dataset.fincomp;
		//console.log(financecomp);
		if (confirm('Remove ' + financecomp + ' from list?')) {
			console.log('delete confirmed');
			helper.deleteCreditApplication(component, targetid);
		}
	},
	/*selectAction : function(component, event, helper) {
		console.log('proposal_F_and_IController->selectAction');
		console.log(event.currentTarget.selectedIndex);
		let action = ['', 'Edit', 'Delete'][event.currentTarget.selectedIndex];
		console.log(action);
		let targetid = event.currentTarget.dataset.targetid;
		console.log(targetid);
		event.currentTarget.selectedIndex = 0;
		if (action=='Edit') {
			$A.get("e.force:editRecord").setParams({
				"recordId":targetid
			}).fire();
		} else if(action=='Delete') {
			let fcs = component.get("v.creditapps");
			let fc = null;
			for(let i=0; i<fcs.length; i++) {
				if (fcs[i].Id==targetid) fc = fcs[i];
			}
			console.log(fc);
			if (fc==null) {
				alert('Did not find credit application record id ' + targetid);
			} else {
				console.log('confirming - delete');
				if (confirm('Remove ' + fc.Finance_Company__r.Name + ' from list?')) {
					console.log('delete confirmed');
					helper.deleteCreditApplication(component, targetid);
				}
			}
		}
	},
	*/

	/* take over f&i for this proposal */
	takeOverFandI : function(component, event, helper) {
		console.log('proposal_F_and_IController->takeOverFandI');
		let updated = [];
		let userId = $A.get("$SObjectType.CurrentUser.Id");
		component.set("v.dealFields.dealer__F_I_Manager__c", userId);
		// Save proposal fields 
		component.find("dealEditor").saveRecord($A.getCallback(function(saveResult) {
			console.log('proposal_F_and_IController->takeOverFandI callback');
			if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
				// handle component related logic in event handler
				component.find("dealEditor").reloadRecord({ skipCache: true });
				updated[updated.length] = 'Proposal';
				helper.toastMessage("success","Changes saved", "Changes to " + updated.join(" and ") + " have been saved.");
			} else if (saveResult.state === "INCOMPLETE") {
				console.log("User is offline, device doesn't support drafts.");
			} else if (saveResult.state === "ERROR") {
				console.log('Problem saving record, error: ' + JSON.stringify(saveResult.error));
				helper.toastMessage("error", "Unable to save change to proposal", JSON.stringify(saveResult));
			} else {
				console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
			}
		}));
	},

	/* save proposal and solution opp fields */
	saveData : function(component, event, helper) {
		console.log('proposal_F_and_IController->saveData');
		component.set("v.mainspinner","true");
		let updated = [];
		// Save solution opp first
		component.find("soloppEditor").saveRecord($A.getCallback(function(saveResult) {
			console.log('proposal_F_and_IController->saveData sol opp callback');
			component.set("v.mainspinner","false");
			if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
				// handle component related logic in event handler
				updated[updated.length] = 'Solution Opportunity';
				if (updated.length==2) helper.toastMessage("success","Changes saved", "Changes to " + updated.join(" and ") + " have been saved.");
			} else if (saveResult.state === "INCOMPLETE") {
				console.log("User is offline, device doesn't support drafts.");
			} else if (saveResult.state === "ERROR") {
				console.log('Problem saving record, error: ' + JSON.stringify(saveResult.error));
				helper.toastMessage("error", "Unable to save solution opportunity", JSON.stringify(saveResult));
			} else {
				console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
			}
		}));
		// Save proposal fields next
		component.find("dealEditor").saveRecord($A.getCallback(function(saveResult) {
			console.log('proposal_F_and_IController->saveData deal callback');
			component.set("v.mainspinner","false");
			if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
				// handle component related logic in event handler
				updated[updated.length] = 'Proposal';
				if (updated.length==2) helper.toastMessage("success","Changes saved", "Changes to " + updated.join(" and ") + " have been saved.");
				// reload to show calculations & triggered updates
				component.find("dealEditor").reloadRecord({ skipCache: true });
				let statusBar = component.find("statusBar");
				if (statusBar!=null) statusBar.signalProposalUpdated();	// refresh status bar
			} else if (saveResult.state === "INCOMPLETE") {
				console.log("User is offline, device doesn't support drafts.");
			} else if (saveResult.state === "ERROR") {
				console.log('Problem saving record, error: ' + JSON.stringify(saveResult.error));
				helper.toastMessage("error", "Unable to save proposal", JSON.stringify(saveResult));
			} else {
				console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
			}
		}));
	},

	/* Credit application received - udpate proposal and credit application records */
	applicationReceived : function(component, event, helper) {
		console.log("proposal_F_and_IController->applicationReceived");
		let receivedate = event.currentTarget.dataset.receivedate;
		if (receivedate==='null') receivedate = null;
		//let receivedate = component.get("v.dealFields.Credit_Application_Received__c");
		if (receivedate==null || confirm('Re-set application received to today?')) {
			component.set("v.mainspinner","true");
			let method = component.get("c.markCreditAppReceived");
			method.setParams({recordId : component.get("v.recordId")});
			method.setCallback(this, function(response) {
				console.log('proposal_F_and_IController->applicationReceived callback');
				component.set("v.mainspinner","false");
				var state = response.getState();
				if (state==="SUCCESS") {
					let returnval = response.getReturnValue();
					console.log("markCreditAppReceived returnval = " + JSON.stringify(returnval)); 
					//component.set("v.attrname", returnval);
				} else if (state==="INCOMPLETE") { 
					console.log("markCreditAppReceived was incomplete");
				} else { // if (state==="ERROR") 
					console.log("markCreditAppReceived error:" + JSON.stringify(response));
					helper.toastMessage("error", "Unable to record application receipt", JSON.stringify(response));
				}
				console.log('applicationReceived callback ended');
				// attempt to reload everything
				console.log('reload proposal');
				component.find("dealEditor").reloadRecord({ skipCache: true });
				console.log('refresh statusBar');
				let statusBar = component.find("statusBar");
				if (statusBar!=null) statusBar.signalProposalUpdated();
				console.log('reload credit applications');
				helper.getCreditApplications(component);
				// force refresh (? BETA)
				//console.log('Refresh component view');
				//$A.get('e.force:refreshView').fire(); //not working
			});
			$A.enqueueAction(method);
		}
	},

	fimanagerLoaded: function(component, event, helper) {
		console.log('pageload');
		let id = component.get('v.recordId');
		component.find('reassignbtn').set('v.disabled',true);
		console.log(id);
	},
	
	/* when record is saved, show confirmation - or - continue to posting if that was requested */
	fimanagerSaved : function(component, event, helper) {
		console.log('recordSaved');
		let response = event.getParams().response;
		console.log(response);
		component.find('reassignbtn').set('v.disabled',true);
		//helper.hideSpinner(component);
		helper.toastMessage("success", "Proposal updated" ,"Reassigned F&I manager");
	},

	fimanagerChanged : function(component, event, helper) {
		console.log('recordChanged');
		component.find('reassignbtn').set('v.disabled',false);
		//helper.hideSpinner(component);
	},
	
	/* show error message if record save failed */
	fimanagerSaveError : function(component, event, helper) {
		console.log('recordSaveError');
		// re-enable buttons
		component.find('reassignbtn').set('v.disabled',false);
		//helper.hideSpinner(component);
	},
})