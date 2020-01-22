({
	// Transfer record Id to selected document Id
	doInit : function(component, event, helper) {
		console.log('doInit');
		component.set("v.documentId", component.get("v.recordId"));
		component.find("docViewer").reloadRecord();
		component.set('v.csColumns', [
            {label: 'Account', fieldName: 'Payor.Name', type: 'text'},
            {label: 'Charged', fieldName: 'Charged', type: 'currency', typeAttributes: { currencyCode: 'USD'}},
            {label: 'Collected', fieldName: 'Collected', type: 'currency', typeAttributes: { currencyCode: 'USD'}},
            {label: 'Total Owed', fieldName: 'AmountOwed', type: 'currency', typeAttributes: { currencyCode: 'USD'}},
            {label: 'Total Due', fieldName: 'AmountDue', type: 'currency', typeAttributes: { currencyCode: 'USD'}},
		]);
		let method = component.get("c.userLocation");
		//method.setParams({paramname : component.get("v.attrname")});
		method.setCallback(this, function(response) {
			console.log('userLocation response');
			let state = response.getState();
			if (state==="SUCCESS") {
				let returnval = response.getReturnValue();
				console.log("userLocation returnval = " + JSON.stringify(returnval)); 
				component.set("v.location", returnval);
				if (returnval.Manual_Cash_Entry__c==true) component.set("v.locationEnabled", false);
			} else if (state==="INCOMPLETE") { 
				console.log("userLocation was incomplete");
			} else { // if (state==="ERROR") 
				console.log("userLocation error:" + JSON.stringify(response));
			}
		});
		$A.enqueueAction(method);

	},
	
	docHandleRecordUpdated : function(component, event, helper) { 
		console.log('docHandleRecordUpdated'); 
		component.set("v.showNewCashierForm", true);
		if (component.get("v.documentId")!=null) {
			let method = component.get("c.documentInfo");
			method.setParams({documentId : component.get("v.documentId")});
			method.setCallback(this, function(response) {
				console.log('documentInfo response');
				let state = response.getState();
				console.log('documentinfo state='+state);
				if (state==="SUCCESS") {
					let returnval = response.getReturnValue();
					//console.log("documentInfo returnval = " + JSON.stringify(returnval)); 
					//console.log(returnval.Payors);
					component.set("v.documentData", returnval.recordData);
					component.set("v.clientAccount", returnval.Client);
					component.set("v.accountList", returnval.Payors);
					component.set("v.cashierList", returnval.Cashiering);
					component.set("v.cashierSummary", returnval.CashieringSummary);
					component.set("v.totalCharged", returnval.TotalChargedToAccount);
					component.set("v.totalCollected", returnval.TotalCollected);
					component.set("v.totalOwed", returnval.TotalOwed);
					component.set("v.totalDue", returnval.TotalDue);
				} else if (state==="INCOMPLETE") { 
					console.log("documentInfo was incomplete");
				} else { // if (state==="ERROR") 
					console.log("documentInfo error:" + JSON.stringify(response));
				}
			});
			$A.enqueueAction(method);
		}
	},  

	searchDocuments : function(component, event, helper) {
		console.log('searchDocuments');
	},

	backToSearch : function(component, event, helper) {
		console.log('backToSearch');
		component.set("v.documentId",null);
	},

	newCashiering : function(component, event, helper) {
		console.log('newCashiering');
		let accountId = event.currentTarget.dataset.accountid;
		let documentId = event.currentTarget.dataset.documentid;
		let amountDue = parseFloat(event.currentTarget.dataset.amountdue);
		let payorname = event.currentTarget.dataset.payorname;
		console.log('newCashiering accountId='+accountId+ ' documentId='+documentId);

		if (amountDue>0 || confirm('It looks like ' + payorname + ' does NOT owe us any more money for this invoice. Are you sure you want to post cash for ' + payorname+'?')) {
			let modalBody=null;
			$A.createComponent(
				"c:CashierNewRecordCMP",
				{ "accountId":accountId, "documentId":documentId, "recordId":null, "inmodal":true },
				function(content, status, errmsg) {
					if (status === "SUCCESS") {
						modalBody = content;
						component.find('overlayLib').showCustomModal({
							header: 'New Payment',
							body: modalBody, 
							showCloseButton: false,
							cssClass: "modal_right",
							closeCallback: function() {
								component.find('docViewer').reloadRecord();
							}
						})
					} else {
						console.log(status + ':' + errmsg);
					}                            
				}
			);
		}
	},

	/* Cashier entry actions */
	editItem : function(component, event, helper) {
		console.log('editItem');
		let targetId = event.currentTarget.dataset.targetid;
		let targetName = event.currentTarget.dataset.targetname;
		//let navToSObject = $A.get('e.force:editRecord');
		//navToSObject.setParams({'recordId':targetId});
		//navToSObject.fire();
		let modalBody=null;
		$A.createComponent(
			"c:CashierNewRecordCMP",
			{ "cashierId":targetId, "inmodal":true },
			function(content, status, errmsg) {
				if (status === "SUCCESS") {
					modalBody = content;
					component.find('overlayLib').showCustomModal({
						header: 'Edit ' + targetName,
						body: modalBody, 
						showCloseButton: false,
						cssClass: "mymodal",
						closeCallback: function() {
							component.find('docViewer').reloadRecord();
						}
					})
				} else {
					console.log(status + ':' + errmsg);
				}
			} 
		);
	},

	deleteItem : function(component, event, helper) {
		console.log('deleteItem');
		let targetId = event.currentTarget.dataset.targetid;
		let targetName = event.currentTarget.dataset.targetname;
		if (confirm('Delete '+targetName)) {
			let method = component.get("c.deleteCashier");
			method.setParams({cashierId : targetId});
			method.setCallback(this, function(response) {
				console.log('deleteCashier response');
				let state = response.getState();
				if (state==="SUCCESS") {
					//let returnval = response.getReturnValue();
					//console.log("deleteCashier returnval = " + JSON.stringify(returnval)); 
					//component.set("v.attrname", returnval);
					component.find('docViewer').reloadRecord();
				} else if (state==="INCOMPLETE") { 
					console.log("deleteCashier was incomplete");
				} else { // if (state==="ERROR") 
					helper.toastMessage('error', 'Error Deleting Payment', 'The payment was not able to be deleted');
					console.log("deleteCashier error:" + JSON.stringify(response));
				}
			});
			$A.enqueueAction(method);
		}
	},
		
})