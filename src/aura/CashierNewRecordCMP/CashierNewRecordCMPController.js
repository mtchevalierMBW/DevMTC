({
    doInit : function(component, event, helper) {
		console.log('CashierNewRecordCMP-doInit');
		let rcdId = component.get('v.recordId');
		if (typeof rcdId!=='undefined' && rcdId!=null) {
			component.set('v.cashierId',rcdId);
		}
		component.set('v.settings', {
			corporateentry: false,
			showcorporateentry:false,
			location: null
		});
		helper.getSettings(component);
	},
	cancel : function(component, event, helper) {
		component.find("overlayLib").notifyClose();
	},
	
	// dealer__Cashering__c entry is loaded (or new entry is ready for input form)
	recordLoaded: function(component, event, helper) {
		console.log('pageload');
		let recordid = component.get('v.recordId');
		let cashierid = component.get('v.cashierId');
		console.log(recordid);
		console.log(cashierid);
		if (typeof cashierid == 'undefined' || cashierid==null) {
			let acctid = component.get('v.accountId');
			let docid = component.get('v.documentId');
			console.log('Account: ' + acctid + ', Document: ' + docid);
			component.find('customer').set('v.value',acctid);
			console.log('Set customer id');
			//component.find("location").set('v.value',component.get('v.location.Id'));
			//component.find("compabbrev").set('v.value', component.get('v.location.dealer__Company_Number__c'));
			//component.find("location").set('v.value',component.get('v.locationId'));
			//component.find("compabbrev").set('v.value', component.get('v.locAbbrev'));
			component.find('location').set('v.value', component.get('v.settings.location.Id'));
			component.find('compabbrev').set('v.value', component.get('v.settings.location.dealer__Company_Number__c'));
			//component.find("deal").set('v.value',null);
			//component.find("sro").set('v.value',null);
			//component.find("rental").set('v.value',null);
			//component.find("deposit").set('v.value',false);
			//component.find("amount").set('v.value',null);
			//component.find("methodofpay").set('v.value',null);
			component.find('paymentmethod').set('v.value','TBD');
			console.log('set corporate flag to ' + component.get('v.settings.corporateentry'));
			//console.log(component.find('corporate'));
			component.find('corporate').set('v.value',component.get('v.settings.corporateentry'));
			//console.log('done setting corporate flag');
			//component.find("authcode").set('v.value',null);
			if (typeof docid !== 'undefined' && docid!=null) {
				console.log('Setting document id');
				if (docid.substr(0,3)=='a1Y') component.find('deal').set('v.value',docid);
				if (docid.substr(0,3)=='a2M') component.find('sro').set('v.value',docid);
				if (docid.substr(0,3)=='a27') component.find('rental').set('v.value',docid);
				console.log('Set document id');
			} 
		}
	},
	
	// Explicitly save record
	saveRecord : function(component, event, helper) {
		console.log('saveRecord');
		event.preventDefault();
		// prevent double-clicks by disabling buttons
		component.find('recordsavebutton').set('v.disabled',true);
		//helper.clearErrorMessages(component);
	
		// Fill in DealerTeam required field from custom picklist field
		let methodofpay = component.find("methodofpay").get('v.value');
		component.find("paymentmethod").set('v.value',methodofpay);
		//component.find("compabbrev").set('v.value', component.get('v.locAbbrev'));
		//component.find("location").set('v.value', component.get('v.locationId'));
		console.log('Writing record for company:');
		//console.log(component.find("compabbrev").get('v.value'));
		//console.log(component.find("location").get('v.value'));
		console.log(component.find("location").get('v.value'));
		// validate data before submitting form
		//if (helper.validateData(component, event)) {
		//	//helper.showSpinner(component);
			let form = component.find('recordform');
			let result = form.submit();
		//} else {	// if there were errors, re-enable the save button
		//	component.find('recordsavebutton').set('v.disabled',false);
		//}

		// If launching from quick-action, close it:
        //let dismissActionPanel = $A.get("e.force:closeQuickAction"); 
		//dismissActionPanel.fire(); 
		
	},
	
	/* when record is saved, show confirmation - or - continue to posting if that was requested */
	recordSaved : function(component, event, helper) {
		console.log('recordSaved');
		let response = event.getParams().response;
		console.log(response);
		//helper.hideSpinner(component);
		// navigate to record page
		let dealid = component.find('deal').get('v.value');
		let sroid = component.find('sro').get('v.value');
		let rentalid = component.find('rental').get('v.value');
		let documentid = null;
		if (dealid!=null) documentid = dealid;
		if (sroid!=null) documentid = sroid;
		if (rentalid!=null) documentid = rentalid;

		component.find("overlayLib").notifyClose();

		if (component.get('v.inmodal')==false) {
			let navToSObject = $A.get('e.force:navigateToSObject');
			navToSObject.setParams({'recordId':documentid});
			navToSObject.fire();
		}
	},
	
	/* show error message if record save failed */
	recordSaveError : function(component, event, helper) {
		console.log('recordSaveError');
		// re-enable buttons
		component.find('recordsavebutton').set('v.disabled',false);
		//helper.hideSpinner(component);
	},

})