({
    getDocuments : function(component) {
		console.log("getDocuments");
		let listdocs = component.get("c.ListOfDocuments");
		listdocs.setParams({vehicleId : component.get("v.recordId")});
		listdocs.setCallback(this, function(response) {
			console.log('getDocuments process response');
			var state = response.getState();
			let stocknbr = component.get("v.vehInvFields.dealer__Stock_Number__c");
			let docnames = [stocknbr+'-lien-release.pdf', stocknbr+'-power-of-attorney.pdf', stocknbr+'-mso-title.pdf', stocknbr+'-proof-payment-trade.pdf',
				stocknbr+'-invoice.pdf', stocknbr+'-rental-registration.pdf', stocknbr+'-rental-insurance.pdf'];
			if (state==="SUCCESS") {
				let doclist = response.getReturnValue();
				console.log('getDocuments doclist'); 
				console.log(JSON.stringify(doclist)); 
				let titledocs = [];
				for(let i=0; i<doclist.length; i++) {
					console.log(i + ': ' + JSON.stringify(doclist[i]));
					if (docnames.includes(doclist[i].FileName)) titledocs[titledocs.length] = doclist[i];
				}
				component.set("v.documents",titledocs);
				this.markCheckmarks(component);
			} else if (state==="INCOMPLETE") { 
			} else { // if (state==="ERROR") 
			}
		});
		$A.enqueueAction(listdocs);
	},

	markCheckmarks : function(component) {4
		console.log("markCheckmarks");
		let doclist = component.get("v.documents");
		let stocknbr = component.get("v.vehInvFields.dealer__Stock_Number__c");
		console.log(doclist);
		let docnames=[];
		for(let i=0; i<doclist.length; i++) {
			docnames[docnames.length] = doclist[i].FileName;
		}
		console.log(docnames);
		//console.log(stocknbr);
		let documentDefs = [
			{filename:"-lien-release.pdf", label:"Lien Release", fieldname:"v.vehInvFields.Lien_Release__c",haveIt:false},
			{filename:"-power-of-attorney.pdf", label:"Power of Attorney", fieldname:"v.vehInvFields.Power_of_Attorney__c",haveIt:false},
			{filename:"-mso-title.pdf", label:"MSO/Title", fieldname:"v.vehInvFields.MSO_Title__c",haveIt:false},
			{filename:"-proof-payment-trade.pdf", label:"Payment/Trade", fieldname:"v.vehInvFields.Proof_of_Payment_Trade__c",haveIt:false}
		];
		let updateflags = false;
		for(let i=0; i<documentDefs.length; i++) {
			let doc = documentDefs[i];
			let testName = stocknbr + doc.filename;
			console.log(testName);
			let valuefieldname = doc.fieldname;
			console.log(valuefieldname);
			let checkmark = component.get(valuefieldname);
			if(docnames.includes(testName)) {
				console.log('Have document ' + testName);
				doc.haveIt = true;
			}
			component.set(valuefieldname, doc.haveIt);
			console.log(component.get(valuefieldname));
		updateflags = updateflags || (checkmark!=doc.haveIt);	// flag changed & needs updated on vehicle record
		}
		if (updateflags) this.saveInvRcd(component);
	},

	renameFile : function(component, docId, newName) {
		console.log('renameFile');
		let rename = component.get("c.renameFile");
		rename.setParams({documentId : docId, newFileName : newName});
		rename.setCallback(this, function(response) {
			console.log('renameFile response:');
			console.log(response);
			var state = response.getState();
			if (state==="SUCCESS") {
				this.getDocuments(component);
			} else if (state==="INCOMPLETE") { 
			} else { // if (state==="ERROR") 
			}
		});
		$A.enqueueAction(rename);
	},

	saveInvRcd : function(component) {
		console.log('saveInvRcd');
		component.find("vehInvRcdEditor").saveRecord(
			$A.getCallback(function(saveResult) {
            	if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
            	    console.log("Save completed successfully.");
            	} else if (saveResult.state === "INCOMPLETE") {
            	    console.log("User is offline, device doesn't support drafts.");
            	} else if (saveResult.state === "ERROR") {
            	    console.log("Problem saving record, error: " +  JSON.stringify(saveResult.error));
            	} else {
            	    console.log("Unknown problem, state: " + saveResult.state + ", error: " + JSON.stringify(saveResult.error));
            	}
			}
			)
		);
	},

	// BLL1
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
				component.set('v.titleLocations', returnval.titlelocations);
				component.set('v.canDeleteVehicleFiles', returnval.candeletefiles)
				console.log('Got title locations picklist');
				let currentlocation = component.get("v.vehInvFields.Title_Location__c");
				if (currentlocation) {
					//console.log('Setting title location to record value: ' + component.get("v.vehInvFields.Title_Location__c"));
					//let titleloc = component.find('titlelocation');
					//titleloc.set('v.value', component.get("v.vehInvFields.Title_Location__c"));
					console.log('Reloading record now that we have picklist values');
					component.find('vehInvRcdEditor').reloadRecord();
				} else {
					console.log('Do not have current location yet');
				}
			} else if (state==='INCOMPLETE') { 
				console.log('settings was incomplete');
			} else { // if (state==='ERROR') 
				console.log('settings error:' + JSON.stringify(response));
		}
		});
		$A.enqueueAction(method);
	},
	// BLL1 end
	
	/* Toast shortcuts */
	toastMessage : function(toasttype, toasttitle, toastmessage) {
		let toastEvent = A.get("e.force:showToast");
		toastEvent.setParams({
			title:toasttitle,
			type:toasttype,
			message:toastmessage
		});
		toastEvent.fire();
	},
})