({
	resetNewCashierForm : function(component, acctid, docid) {
		console.log('resetNewCashierForm');
		let newcustomer = component.find("customer");
		if (typeof newcustomer!=='undefined') newcustomer.set('v.value',acctid);
		let newdeal = component.find("deal");
		if (typeof newdeal!=='undefined') newdeal.set('v.value',null);
		let newsro = component.find("sro");
		if (typeof newsro!=='undefined') newsro.set('v.value',null);
		let newrental = component.find("rental");
		if (typeof newrental!=='undefined') newrental.set('v.value',null);
		let newdeposit = component.find("deposit");
		if (typeof newdeposit!=='undefined') newdeposit.set('v.value',false);
		let newamount = component.find("amount");
		if (typeof newamount!=='undefined') newamount.set('v.value',null);
		let newmethod = component.find("methodofpay");
		if (typeof newmethod!=='undefined') newmethod.set('v.value',null);
		let newpayment = component.find("paymentmethod");
		if (typeof newpayment!=='undefined') newpayment.set('v.value','tbd');
		let newauthcode = component.find("authcode");
		if (typeof newauthcode!=='undefined') newauthcode.set('v.value',null);
		if (typeof docid !== 'undefined' && docid!=null) {
			if (docid.substr(0,3)=='a1Y' && typeof newdeal!=='undefined') newdeal.set('v.value',docid);
			if (docid.substr(0,3)=='a2M' && typeof newsro!=='undefined') newsro.set('v.value',docid);
			if (docid.substr(0,3)=='a27' && typeof newrental!=='undefined') newrental.set('v.value',docid);
		}
	},

	validateData: function(component, event) {
		console.log('validateData');
		let requiredFields = ['customer', 'methodofpay', 'amount'];
		let errmsg = '';
		for(let i=0; i<requiredFields.length; ++i) {
			let cmp = component.find(requiredFields[i]);
			if (cmp.get('v.value')==null) errmsg += requiredFields[i] + ' is required.\n';
		}
		if (errmsg>'') this.toastMessage('error', 'Please correct the following', errmsg);
		return (errmsg=='');
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