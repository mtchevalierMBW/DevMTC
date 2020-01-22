({
	/* general page initializations */
	doInit : function(component, event, helper) {
		console.log('doInit');
		// initialize that we're not in the process of posting
		component.set("v.posting", false);

		// following requires implements: lightning:isUrlAddressable
		//console.log(component.get("v.pageReference"));
		//if (component.get("v.pageReference")!=null) console.log(component.get("v.pageReference").state);

		// determine if "New Rental Agreement" came from an account or contact page's rental related list 
		let id = component.get("v.recordId");
		if (id==null) { // new rental only!
			console.log('New rental (no Id): check for coming from account or contact');
			console.log(window.location.search.substring(1));
			let pageURL = decodeURIComponent(window.location.search.substring(1));
			console.log(pageURL);
			let urlParams = pageURL.split('&');
			let accountid = null;
			let contactid = null;
			for(let p in urlParams) {
				let pary = urlParams[p].split("=");
				if (pary[0]=="inContextOfRef") {
					let b64 = pary[1].substring(2);
					let pjson = JSON.parse(window.atob(b64));
					console.log(pjson);
					if (pjson && pjson.attributes && pjson.attributes.objectApiName==="Account")
						accountid = pjson.attributes.recordId;
					if (pjson && pjson.attributes && pjson.attributes.objectApiName==="Contact")
						contactid = pjson.attributes.recordId;
				}
			} 
			console.log('from account id: ' + accountid);
			console.log('from contact id: ' + contactid);
			if (accountid!==null) component.set("v.fromaccount", accountid);
			if (contactid!==null) component.set("v.fromcontact", contactid);
		}
		/* end if coming from account or contact page */
		console.log('doInit complete');
	},

	/* initializations when recordeditform is loaded */
	pageload: function(component, event, helper) {
		console.log('pageload');
		let id = component.get("v.recordId");
		console.log(id);

		//let sts = id==null ? null : component.get("v.recordData.dealer__Agreement_Status__c");
		let sts = (id==null) ? null : component.find("agreement_status").get("v.value");
		console.log(sts);
		// in doInit: let name = id==null ? null : component.get("v.recordData.Name");
		if (id==null) {
			console.log('Setting defaults for new record');
			sts = 'Open';	// default value
			// in doInit: name = 'New Rental Agreement';
			let stscmp = component.find("agreement_status");
			if (stscmp!=null) stscmp.set("v.value", sts);
			component.set("v.status", sts);	// also init record data status
			component.find("deposit_amount").set("v.value",0.00);	// default value
			component.find("excess_miles_charge").set("v.value",0.00);	// default value
			component.set("v.title","New Rental Agreement");
			component.find("totalperdiemtax").set("v.value",0.00);	// default value
			component.find("sales_tax").set("v.value",0.00);	// default value
			component.find("countysalestax").set("v.value",0.00);	// default value
			component.find("citysalestax").set("v.value",0.00);	// default value
			component.find("thirdtierrentaltax").set("v.value",0.00);	// default value
		} else {
			console.log('Record is not new');
		}
		// in doInit: component.set("v.title", name);
		let isopen = sts!='Paid';
		let posting = component.get("v.posting");
		console.log('isopen = ' + isopen);
		if (isopen) component.set("v.alreadyposted", false);
		else component.set("v.alreadyposted", true);

		// enable/disable buttons based on rental status
		if (!posting && isopen) component.find("submitbutton").set("v.disabled", false);
		if (!posting && id!=null && isopen) component.find("postbutton").set("v.disabled",false);
		//if (!posting && id!=null && isopen && helper.validateData(component, event)) component.find("postbutton").set("v.disabled",false);

		// if coming from account or contact page, prefill account and/or contact lookups
		let fromaccount = component.get("v.fromaccount");
		if (fromaccount!==null) {
			console.log('Setting account from url');
			component.find("account").set("v.value",fromaccount);
			helper.rtvPersonContactId(component, event);
		}
		let fromcontact = component.get("v.fromcontact");
		if (fromcontact!==null) {
			console.log('Setting contact from url');
			component.find("contact").set("v.value",fromcontact);
			helper.rtvContactsAccountId(component, event);
		}

		// set default location
		let c_location = component.find("location");
		let location = null;
		if (c_location!=null) location = c_location.get("v.value");
		console.log('is location filled in?');
		console.log(c_location);
		console.log(location);
		if (id==null && c_location!=null && location==null) {
			helper.rtvUserDefaultLocation(component, event);
		} else {
			console.log('Did not try to retrieve default location');
			console.log(id);
			console.log(c_location);
			console.log(location);
		}

		// initialize running totals
		helper.recalcTotals(component, event);

		console.log('pageLoad complete');
	},

	/* recalculate runnign totals (total charges, amount due, etc) */
	recalc : function(component, event, helper) {
		console.log('recalc');
		helper.recalcTotals(component, event);
	},

	/* perform validations before submitting recordeditform to update data */
	saveNewRecord : function(component, event, helper) {
		event.preventDefault();
		console.log('saveNewRecord');
		// prevent double-clicks by disabling buttons
		component.find("submitbutton").set("v.disabled",true);
		component.find("postbutton").set("v.disabled",true);
		helper.clearErrorMessages(component);

		// validate data before submitting form
		if (helper.validateData(component, event)) {
			helper.showSpinner(component);
			// done in trigger now: component.find("dealerlocation").set("v.value",component.find("location").get("v.value"));

			// The following generates "Cannot set property value of undefined" after the vehicle was set once
			//let c_dealer_rental_vehicle = component.find("dealer_rental_vehicle");
			//let c_rental_vehicle = component.find("rental_vehicle");
			//console.log(c_dealer_rental_vehicle);
			//console.log(c_rental_vehicle);
			//let vehicle = c_rental_vehicle.get("v.value");
			//c_dealer_rental_vehicle.set("v.value", vehicle);

			let form = component.find("newrecordform");
			let result = form.submit();
		} else {	// if there were errors, re-enable the save button
			component.find("submitbutton").set("v.disabled",false);
			let toastEvent = $A.get("e.force:showToast");
			toastEvent.setParams({
            	"title": "Errors",
            	"type": "error",
            	"message": "Not saved! Please correct errors."
        	});
        	toastEvent.fire();
		}
	},
	
	/* when record is saved, show confirmation - or - continue to posting if that was requested */
	recordSaved : function(component, event, helper) {
		let response = event.getParams().response;
		console.log('recordSaved response');
		console.log(response);
		let toastEvent = $A.get("e.force:showToast");
		
		// if record save came from a request to post the rental, invoke the posting process
		if (component.get("v.posting")==true) {
			console.log('posting...');
			let post = component.get("c.postRentalAgreement");
			post.setParams({rentalAgreementId : component.get("v.recordId")});
			post.setCallback(this, function(response) {
				helper.hideSpinner(component);
				console.log('posting response');
				console.log(response);
				var state = response.getState();
				if (state==="SUCCESS") {
					toastEvent.setParams({
        				"title": "Rental Posting",
        				"type": "success",
        				"message": "Post request has been submitted!"
        			});
					component.set("v.alreadyposted", true);
					component.find("agreement_status").set("v.value","Paid");
				} else if (state==="INCOMPLETE") { 
					toastEvent.setParams({
        				"title": "Unexpected response",
        				"message": "The rental post request may not have been processed. Contact IT Help."
        			});
					component.set("v.alreadyposted", true);
					component.find("agreement_status").set("v.value","Paid");
				} else { /* if (state==="ERROR") */
					toastEvent.setParams({
        				"title": "Rental Posting Error",
        				"type": "error",
        				"message": "Post request has not completed!"
        			});
					component.set("v.alreadyposted", false);
				}
				toastEvent.fire();

				// attempt to delay the refresh a bit to see if it's more consistent this way
				//setTimeout(function () {
				//	$A.get("e.force:navigateToSObject").setParams({
				//		"recordId":component.get("v.recordId"), "slideDevName":"detail"
				//	}).fire();
				//}, 1000);
			});
			$A.enqueueAction(post);
		} else {	// post wasn't requested, so just show confirmation msg
			console.log('save only, not posting');
			helper.hideSpinner(component);
        	toastEvent.setParams({
        		"title": "Saved",
        		"type": "success",
        		"message": "The record was saved!"
        	});
        	toastEvent.fire();
			// navigate to view page
			$A.get("e.force:navigateToSObject").setParams({
				"recordId":response.id, "slideDevName":"detail"
			}).fire();
		}
	},
	
	/* show error message if record save failed */
	recordSaveError : function(component, event, helper) {
		helper.hideSpinner(component);

		// recordEditForm displays a specific message, so I don't
		// need to do it myself. Also, the actual cause of the error isn't
		// available yet. See issue: https://success.salesforce.com/issues_view?id=a1p3A000000FmjRQAS
		//var eventName = event.getName();
        //var eventDetails = event.getParam("message");
		//console.log(JSON.stringify(event.getParams()));
        //console.log('Error Event received' + eventName)
        //let toastEvent = $A.get("e.force:showToast");
        //toastEvent.setParams({
        //    "title": "Error!",
        //    "type": "error",
        //    "message": "The record was NOT saved!\n"
        //});
        //toastEvent.fire();
		//helper.appendErrorMessage(component, eventName + ' : ' + eventDetails);
		
		// re-enable buttons
		component.find("submitbutton").set("v.disabled",false);
		component.find("postbutton").set("v.disabled",false);
		component.set("v.posting", false);
	},
	
	/* save and post the rental agreement */
	postRental : function(component, event, helper) {
		event.preventDefault();
		console.log('postRental');
		// disable buttons to prevent double-click
		component.find("submitbutton").set("v.disabled",true);
		component.find("postbutton").set("v.disabled",true);
		helper.clearErrorMessages(component);
		
		// validate form before submitting
		if (helper.validateData(component, event) && helper.readyToPost(component)) {
			component.set("v.posting", true);
			helper.showSpinner(component);
			let form = component.find("newrecordform");
			let result = form.submit();
		} else {	// notify there were errors and re-enable the form's buttons
			component.set("v.posting", false);
			component.find("submitbutton").set("v.disabled",false);
			component.find("postbutton").set("v.disabled",false);
			let toastEvent = $A.get("e.force:showToast");
			toastEvent.setParams({
            	"title": "Errors",
            	"type": "error",
            	"message": "Not saved! Please correct errors."
        	});
        	toastEvent.fire();
		}
	},
	
	/* when account lookup is set to a value, auto-fill contact (if it's a person account) */
	accountChange : function(component, event, helper) {
		let accountid = component.find("account").get("v.value");
		if (accountid!=null && accountid>"") 
			helper.rtvPersonContactId(component, event);
	},
	
	/* when contact lookup is set to a value, auto-fill account (if contact is related to one) */
	contactChange : function(component, event, helper) {
		let contactid = component.find("contact").get("v.value");
		if (contactid!=null && contactid>"") 
			helper.rtvContactsAccountId(component, event);
	},

	/* after loading jquery, use it to disable the mouse wheel on input boxes */
	//afterScriptsLoaded : function(component, event, helper) {
	//	console.log('afterScriptsLoaded');
	//	//helper.disableMousewheel();
	//},

	ignoreMousewheel : function(component, event, helper) {
		//console.log('ignoreMousewheel');
		event.preventDefault();
		//? event.stopPropagation();
		//not needed: component.find("submitbutton").focus();
		//does not work: event.target.blur();
		//does not work: event.getSource().blur();
	},

})