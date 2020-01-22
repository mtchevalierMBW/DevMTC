({
	doInit : function(component, event, helper) {
		console.log('Proposal_CreditAppStatusBarController->doInit');
	},

	/* Proposal updated */
	dealHandleRecordUpdated: function(component, event, helper) { 
		console.log('Proposal_CreditAppStatusBarController->dealHandleRecordUpdated'); 
		let eventParams = event.getParams(); 
		//console.log(eventParams); 
		console.log(eventParams.changeType); 
		
		if (eventParams.changeType === "LOADED") { 
			console.log("Deal record is loaded successfully."); 
			helper.getCreditApplications(component);
		} else if(eventParams.changeType === "CHANGED") { 
			console.log("Deal record is changed (saved)"); 
			helper.getCreditApplications(component);
		} else if(eventParams.changeType === "REMOVED") { 
			console.log("The proposal was deleted"); 
		} else if(eventParams.changeType === "ERROR") { 
			console.log("Error loading proposal");
			var params = eventParams;
			for (var f in params) console.log(f + ' = ' + params[f])
			console.log(event);
			helper.toastMessage("error", "Unable to load or save proposal", JSON.stringify(event));
		} 
	},  
  
	signalProposalUpdated : function(component, event) {
		console.log("Proposal_CreditAppStatusBarController->handleProposalUpdatedEvent");
		component.find("dealEditor").reloadRecord({ skipCache: true });
	},

})