({
	/* clear error message text */
	clearErrorMessages: function(component) {
		component.set("v.recordErrors", []);
	},
	
	/* append an error message to the error message text on-screen */
	appendErrorMessage: function(component, msgtext) {
		let existingmsgs = component.get("v.recordErrors");
		if (typeof existingmsg==='undefined') existingmsgs = [];
		existingmsgs.push(msgtext);
		component.set("v.recordErrors", existingmsgs);
	},
	appendErrorMessages: function(component, msgtexts) {
		let existingmsgs = component.get("v.recordErrors");
		if (typeof existingmsg==='undefined') existingmsgs = [];
		existingmsgs = existingmsgs.concat(msgtexts);
		component.set("v.recordErrors", existingmsgs);
	},
	
	/* show the spinner during long-running operations (like posting) */
	showSpinner : function(component) {
		component.set("v.Spinner",true);
	},
	
	/* hide the spinner after long-running operations have completed */
	hideSpinner : function(component) {
		component.set("v.Spinner",false);
	},
	
	/* recalculate running totals like total charges and amount due */
	recalcTotals : function(component, event) {
		console.log('recalcTotals');
		// BLL4
		//let c_dailyrate = component.find("daily_rental_rate");
		//let c_numberdays = component.find("number_of_days");
		//let c_rentalfee = component.find("rental_fee");
		//console.log(c_dailyrate);
		//console.log(c_numberdays);
		//console.log(c_rentalfee);
		//let dailyrate = this.decimalvalue(c_dailyrate.get("v.value"));
		//let numberdays = this.decimalvalue(c_numberdays.get("v.value"));
		//let rentalfee = this.decimalvalue(c_rentalfee.get("v.value"));
		//if (dailyrate!=null && dailyrate!=0 && numberdays!=null && numberdays!=0) {
		//	rentalfee = dailyrate * numberdays;
		//	component.find("rental_fee").set("v.value",rentalfee);
		//}
		let c_rentalfee = component.find("rental_fee");
		let rentalfee = this.decimalvalue(c_rentalfee.get("v.value"));
		// BLL4 end
		let charges = 0;
		charges += rentalfee;
		charges += this.decimalvalue(component.find("pickup_delivery_fee").get("v.value"));
		charges += this.decimalvalue(component.find("excess_miles_charge").get("v.value"));
		charges += this.decimalvalue(component.find("refueling_fee").get("v.value"));
		charges += this.decimalvalue(component.find("adjustment_charges").get("v.value"));
		charges += this.decimalvalue(component.find("discount").get("v.value"));
		charges += this.decimalvalue(component.find("totalperdiemtax").get("v.value"));
		charges += this.decimalvalue(component.find("sales_tax").get("v.value"));
		charges += this.decimalvalue(component.find("countysalestax").get("v.value"));
		charges += this.decimalvalue(component.find("citysalestax").get("v.value"));
		charges += this.decimalvalue(component.find("thirdtierrentaltax").get("v.value"));

		let c_totalcharges = component.find("totalcharges");
		c_totalcharges.set("v.value",charges);
		 
		let c_deposit = component.find("deposit_amount");
		let c_totalamountdue = component.find("totalamountdue");

		let c_payoramount = component.find("payor_pay_amount")
		let c_customeramount = component.find("customer_pay_amount");
		let deposit = this.decimalvalue(c_deposit.get("v.value"));
		let totalamountdue = charges-deposit;

		// BLL5 - customer portion
		let c_customerportion = component.find("customer_portion");
		let customerportion = c_customerportion!=null ? this.decimalvalue(c_customerportion.get("v.value")) : 0.00;
		// BLL5 end

		let payoramount = this.decimalvalue(c_payoramount.get("v.value"));
		let c_thirdpartypayor = component.find("thirdpartypayor");
		//if (c_thirdpartypayor.get("v.value")!=null) payoramount = totalamountdue;
		// BLL5
		let c_otherpayor = component.find("otherpayor");
		console.log('check other payor status');
		if ((c_thirdpartypayor.get("v.value")==null || c_thirdpartypayor.get("v.value")=="")
		 	&& (c_otherpayor.get("v.value")==null || c_otherpayor.get("v.value")=="" )) {
			payoramount = 0.00;
			component.set("v.payorselected",false);
			console.log('no payor selected');
		} else {
			component.set("v.payorselected",true);
			payoramount = totalamountdue - customerportion;
			console.log('payor selected');
		}
		// BLL5 end


		let customeramount = totalamountdue - payoramount
		//console.log(totalamountdue);
		c_totalamountdue.set("v.value",totalamountdue);
		//console.log(c_customeramount);
		//console.log(customeramount);
		c_payoramount.set("v.value",payoramount);
		c_customeramount.set("v.value",customeramount);
		console.log('recalcTotals complete');
	},
	
	/* cast nulls to 0 for numeric calculations */
	decimalvalue : function(val) {
		let rtn = 0; 
		if (typeof val==='number') rtn=val;
		else rtn = (val==null || val.trim().length==0) ? 0.00 : parseFloat(val);
		return rtn;
	},
	
	/* validate a single form field - note that showHelpMessageIfInvalid isn't yet supported on inputfield */
	validComponent : function(inputCmp) {
			//$A.util.hasClass(inputCmp, "required");
			console.log(inputCmp);
			console.log(inputCmp.get("v.required"));
            // Displays error messages for invalid fields
            //inputCmp.showHelpMessageIfInvalid();

            let cmpValidity = inputCmp.get('v.validity');
            // component type supports isValid but does not have a validity property, fake it...
            if (typeof cmpValidity === 'undefined' && inputCmp.isValid) cmpValidity = {"valid":inputCmp.isValid()};
            
            let cmpValid = (typeof cmpValidity === 'undefined') ? true : cmpValidity.valid;
            return cmpValid; 
	},

	/* check if component is required and that it has a value */
	hasRequiredData : function(inputCmp) {
		console.log('hasRequiredData for component...');
		console.log(inputCmp);
		let required = $A.util.hasClass(inputCmp, 'mw_required');
		let v = inputCmp.get("v.value");
		console.log(v);
		let missingdata = required && ((typeof v==='undefined') || v===null);
		if (missingdata) console.log('Missing component value!');
		return !missingdata;
	},
	
	/*  */
	validateData : function(component, event) {
		console.log('validateData');
		this.clearErrorMessages(component);
        let newerrors = [];
		
		let validForm = true;
		let form = component.find("newrecordform");

		// may want to re-activate this block if inputfield within recordeditform starts supporting "validComponent"
		// for attributes specified on the inputfield component itself (like required, min/max, etc that input components support)
		//let helper = this;
		// cascade through all input fields -- selection by aura:id isn't very helpful
		// since I need separate IDs to grab individual values to accumulate for total charges.
		// [].concat(...) forces single elements into an array so that reduce will work :)
		//validForm &= [].concat(component.find("charges")).reduce(function (validSoFar, inputCmp) {
        //    return validSoFar && this.validComponent(inputCmp);
        //}, validForm);

        // specific required fields
        // would like to iterate through all form fields, but don't know how yet
        let hasRequiredData = true;
        let requiredfields = [
        	{"fieldid":"rentcentric_contract","fieldlabel":"Rentcentric contract"},
        	{"fieldid":"return_date","fieldlabel":"Return date"},
			{"fieldid":"location","fieldlabel":"Location"},
			{"fieldid":"rental_vehicle", "fieldlabel":"Rental Vehicle"},
			//{"fieldid":"return_mileage", "fieldlabel":"Return Mileage"},
        	{"fieldid":"account","fieldlabel":"Account"},
        	{"fieldid":"contact","fieldlabel":"Contact"},
        	{"fieldid":"rental_fee","fieldlabel":"Rental fee"},
        	{"fieldid":"totalperdiemtax","fieldlabel":"Per Diem Tax"},
        	{"fieldid":"sales_tax","fieldlabel":"State sales tax"},
        	{"fieldid":"countysalestax","fieldlabel":"County sales tax"},
        	{"fieldid":"citysalestax","fieldlabel":"City sales tax"},
        	{"fieldid":"thirdtierrentaltax","fieldlabel":"Third tier rental tax"}
        	//{"fieldid":"deposit_amount","fieldlabel":"Deposit amount"},
        ];
        console.log('required fields');
        for(let rf in requiredfields) {
        	console.log(requiredfields[rf]);
        	let cmp = component.find(requiredfields[rf].fieldid);
        	if (typeof cmp !== 'undefined' && cmp!==null) {
        		let v = cmp.get("v.value");
        		console.log(v);
        		if (v===null || (typeof v === 'string' && v.trim().length===0)) {
        			newerrors.push(requiredfields[rf].fieldlabel + " is required.");
        			hasRequiredData = false;
        		}
        	} else {
        		console.log('Did not find component for ' + requiredfields[rf].fieldlabel);
        	}
        }
        
        // general required fields
        /** can't use this since each inputfield has a unique aura:id
 		hasRequiredData = [].concat(component.find("formitem")).reduce(function (validSoFar, inputCmp) {
        	return validSoFar && this.hasRequiredData(inputCmp);
        }, hasRequiredData);
		**/
        
        // require third party payor *or* other payor when there's an other payor amount
        let cmpPayoramt = component.find("payor_pay_amount");
        let cmpTpp = component.find("thirdpartypayor");
        let cmpOther = component.find("otherpayor");
        let payoramt = cmpPayoramt.get("v.value");
        let thirdparty = cmpTpp.get("v.value");
        let other = cmpOther.get("v.value");
        if (payoramt!=null && payoramt!=0 && thirdparty===null && other===null) {
        	validForm=false;
        	newerrors.push("Other payor amount requires a Third Party Payor or Other Payor.");
        }
        if (thirdparty!==null && thirdparty!=="" && other!=null && other!="") {
        	validForm=false;
        	newerrors.push("Only 1 Third Party Payor or Other Payor is allowed.");
        }

        this.appendErrorMessages(component, newerrors);
        validForm = validForm & hasRequiredData;
        console.log("validForm = " + validForm);
		console.log('validateData end');
        return validForm;
	},
	
	// test that rental is not dated into the future when posting
	readyToPost: function(component) {
		let newerrors = [];
		console.log('notFutureDated');
		let returndatecmp = component.find('return_date');
		console.log(returndatecmp);
		let returndate = returndatecmp.get('v.value');
		console.log(returndate);
		let today = new Date();
		let todaystr = String(today.getFullYear()) + '-' + String(today.getMonth()+1).padStart(2,'0') + '-' + String(today.getDate()).padStart(2, '0');
		console.log(todaystr);
		if (returndate > todaystr) {
			newerrors.push('You can not post rental agreements with a return date in the future');
		}
		//let returnmileagecmp = component.find('return_mileage');
		//let returnmileage = returnmileagecmp.get('v.value');
		//console.log(returnmileage);
		//if (typeof returnmileage==='undefined' || returnmileage<=0) {
		//	newerrors.push('Return mileage is required before posting rental');
		//}
		this.appendErrorMessages(component, newerrors);
		return newerrors.length==0;
	},

	/* retrieve associated account from a contact and set the account form field */
	rtvContactsAccountId : function(component, event) {
		console.log('rtvContactsAccountId');
		let contactsAccountId = component.get("c.AccountForContact");
		contactsAccountId.setParams({contactId : component.find("contact").get("v.value")});
		contactsAccountId.setCallback(this, function(response) {
			console.log('rtvContactsAccountId response');
			console.log(response);
			var state = response.getState();
			console.log('rtvContactsAccountId state='+state);
			if (state==="SUCCESS") {
				let contactaccountid = response.getReturnValue();
				let cmpaccount = component.find("account");
				if (cmpaccount!=null && contactaccountid!=null) 
					cmpaccount.set("v.value", contactaccountid);	
			} else if (state==="INCOMPLETE") { 
			} else { /* if (state==="ERROR") */
			}
		});
		$A.enqueueAction(contactsAccountId);
	},
	
	/* retrieve personcontactid from account (if there is one) and set the contact id */
	rtvPersonContactId : function(component, event) {
		console.log('rtvPersonContactId');
		let personContactId = component.get("c.ContactForAccount");
		personContactId.setParams({accountId : component.find("account").get("v.value")});
		personContactId.setCallback(this, function(response) {
			console.log('rtvPersonContactId response');
			console.log(response);
			var state = response.getState();
			console.log('rtvPersonContactId state='+state);
			if (state==="SUCCESS") {
				let cmpcontact = component.find("contact");
				let contactid=response.getReturnValue();
				if (cmpcontact!=null && contactid!=null) 
					cmpcontact.set("v.value", contactid);	
			} else if (state==="INCOMPLETE") { 
			} else { /* if (state==="ERROR") */
			}
		});
		$A.enqueueAction(personContactId);
	},
	
	/* retrieve personcontactid from account (if there is one) and set the contact id */
	rtvUserDefaultLocation : function(component, event) {
		console.log('rtvUserDefaultLocation');
		let usersDefaultLocation = component.get("c.UsersDefaultLocation");
		usersDefaultLocation.setCallback(this, function(response) {
			console.log('usersDefaultLocation response');
			console.log(response);
			var state = response.getState();
			console.log('usersDefaultLocation state='+state);
			if (state==="SUCCESS") {
				try {
					let cmplocation = component.find("location");
					console.log(cmplocation);
					let cmplocationid = cmplocation.get("v.value");
					console.log(cmplocationid);
					let locationid=response.getReturnValue();
					console.log(locationid);
					if (cmplocation!=null && cmplocationid==null && locationid!=null) {
						cmplocation.set("v.value", locationid);	
						console.log('setlocation to:' + locationid);
					} else {
						console.log('Location field not found or already has value or no default location found');
					}
				} catch(e) {
					console.log('Error setting location to user default: ' + e);
					console.log(response);
				}
			} else if (state==="INCOMPLETE") { 
				console.log(state);
			} else { /* if (state==="ERROR") */
				console.log(state);
			}
		});
		$A.enqueueAction(usersDefaultLocation);
		console.log('rtvUserDefaultLocation enqueued');
	},

})