({
	doInit : function(component, event, helper) {
		console.log("doInit");
		console.log(component.get("v.recordId"));
		helper.getSettings(component);	// BLL1a
		//let method = component.get("c.canDeleteVehicleFiles");
		//method.setCallback(this, function(response) {
		//	console.log('canDeleteVehicleFiles response');
		//	var state = response.getState();
		//	if (state==="SUCCESS") {
		//		let returnval = response.getReturnValue();
		//		console.log("canDeleteVehicleFiles returnval = " + JSON.stringify(returnval)); 
		//		component.set("v.canDeleteVehicleFiles", returnval);
		//	} else if (state==="INCOMPLETE") { 
		//		console.log("canDeleteVehicleFiles was incomplete");
		//	} else { // if (state==="ERROR") 
		//		console.log("canDeleteVehicleFiles error:" + JSON.stringify(response));
		//	}
		//});
		//$A.enqueueAction(method);
	},

	// BLLx - force ignoring cached data
	loadInvRcd: function(component, event, helper) {
		console.log('loadInvRcd');
		console.log(event);
		component.find('vehInvRcdEditor').reloadRecord(true);
	},
	// BLLx end

	handleRecordUpdated: function(component, event, helper) {
		console.log('handleRecordUpdated');
		let eventParams = event.getParams();
		console.log(eventParams);
		console.log(eventParams.changeType);

		if (eventParams.changeType === "LOADED") {
			// record is loaded (render other component which needs record data value)
			console.log("Record is loaded successfully.");
			console.log("You loaded stock record for " + component.get("v.vehInvFields.dealer__Stock_Number__c"));
			console.log(component.get("v.vehInvFields"));
			console.log('Got title location from record: ' + component.get("v.vehInvFields.Title_Location__c"));
			//console.log(component.get("v.vehInvRecord"));
			// get list of attached documents
			helper.getDocuments(component);
		} else if(eventParams.changeType === "CHANGED") {
			// record is changed
			let toastEvent = $A.get("e.force:showToast");
			toastEvent.setParams({
				"title": "Title Document/Notes",
				"type": "success",
				"message": "Title document flags and notes have been saved!"
			});
			toastEvent.fire();
			// refresh the page
			//$A.get('e.force:refreshView').fire();
			component.find('vehInvRcdEditor').reloadRecord(true);
		} else if(eventParams.changeType === "REMOVED") {
			// record is deleted
		} else if(eventParams.changeType === "ERROR") {
			// there’s an error while loading, saving, or deleting the record
		}
	}, 

	docTypeChanged: function(component, event, helper) {
		let docType = component.get("v.documentType");
		if (docType!=null && docType.length>0) {
			component.set("v.filedisabled", false);
		} else {
			component.set("v.filedisabled", true);
		}
	},

	handleUploadFinished : function(component, event, helper) {
		console.log('handleUploadFinished');
		var uploadedFiles = event.getParam("files");
        var documentId = uploadedFiles[0].documentId;
        var fileName = uploadedFiles[0].name;
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "File "+fileName+" Uploaded successfully."
        });
		toastEvent.fire();
		let stocknbr = component.get("v.vehInvFields.dealer__Stock_Number__c");
		console.log(stocknbr);
		let filenamesfx = component.get("v.documentType");
		console.log(filenamesfx);
		let newname = stocknbr + '-' + filenamesfx;
		console.log(newname);
		helper.renameFile(component, documentId, newname);
		component.set("v.documentType", null);
		component.set("v.filedisabled", true);
		helper.saveInvRcd(component);
		//helper.getDocuments(component);
		// open file preview
        //$A.get('e.lightning:openFiles').fire({
        //    recordIds: [documentId]
        //});
        
    },

	viewDocument: function(component, event, helper) {
		//console.log(JSON.stringify(event));
		//console.log(JSON.stringify(event.currentTarget));
		console.log(JSON.stringify(event.currentTarget.dataset));
		var docId = event.currentTarget.dataset.docid;
		var docType = event.currentTarget.dataset.doctype;
		if (docType=='file') {
			// FILE : open file preview
        	$A.get('e.lightning:openFiles').fire({
        	    recordIds: [docId]
			});
		}
		if (docType=='attachment') {
			// ATTACHMENT : open in new window?
			let url = '/servlet/servlet.FileDownload?file=' + docId;
			window.open(url, '_blank');
		}
	},

	deleteDocument: function(component, event, helper) {
		//console.log(JSON.stringify(event));
		//console.log(JSON.stringify(event.currentTarget));
		console.log(JSON.stringify(event.currentTarget.dataset));
		let docId = event.currentTarget.dataset.docid;
		let docType = event.currentTarget.dataset.doctype;
		let docName = event.currentTarget.dataset.docname;

		if (confirm('Delete ' + docName + '?')) {
			let method = component.get("c.deleteFile");
			method.setParams({filetype : docType, fileid : docId});
			method.setCallback(this, function(response) {
				console.log('deleteFile response');
				var state = response.getState();
				if (state==="SUCCESS") {
					let returnval = response.getReturnValue();
					//helper.toastMessage('success', docName, docName + ' has been deleted');
					helper.getDocuments(component);
				} else if (state==="INCOMPLETE") { 
					console.log("deleteFile was incomplete");
				} else { // if (state==="ERROR") 
					console.log("deleteFile error:" + JSON.stringify(response));
					helper.toastMessage('error', 'Error', 'Could not delete ' + docName + '\n' + JSON.stringify(response));
				}
			});
			$A.enqueueAction(method);
		}
	},

	saveData: function(component, event, helper) {
		console.log('saveData');
		helper.saveInvRcd(component);
	}
})