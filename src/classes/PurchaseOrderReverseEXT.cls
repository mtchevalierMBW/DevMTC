/**
 * PurchaseOrderReverseEXT
 * Tested by: PurchaseOrderReverseEXT_TEST
 * Date: 2019-07-11
 * Programmer: Bryan Leaman
 * Project: W-000524
 * Update proposal F&I overall status info when credit application statuses are updated.
 *
 * Coverage:
 *	2019-07-11	100%	(13/13)
 *
 * Modifications: 
 *
 */

public with sharing class PurchaseOrderReverseEXT {
	private ApexPages.StandardController stdController;
	public dealer__Purchase_Order__c obj;
	public boolean AllowSubletReversal {private set;get {
		return Utility.hasCustomPermission('DealerTeam_RO_Reversal');
	}}
	public List<dealer__Purchase_Order_Line__c> purchaseOrderLines {private set; get {
		return [
			select Id, dealer__Product__c, dealer__Description__c, dealer__Quantity__c, dealer__Amount__c
			from dealer__Purchase_Order_Line__c
			where dealer__Purchase_Order__c=:obj.Id
		];
	}}

	public PurchaseOrderReverseEXT(ApexPages.StandardController ctlr) {
		//List<String> fields = new List<String>();
		//fields.add('dealer__PO_Accounting_Name__c');
		//if(!Test.isRunningTest()) ctlr.addFields(fields);

		obj = (dealer__Purchase_Order__c) ctlr.getRecord();
		stdController = ctlr;
		validateReopenRequest();
	}

	public PageReference returnToRO() {
		return stdController.view();
	}

	// validateReopenRequest
	public boolean validateReopenRequest() {
		FFAccounting fa = new FFAccounting();

        // Obtain the record
        dealer__Purchase_Order__c po = fa.purchaseOrderSelector(obj.Id);

        // Preflight validation
        if(po.RecordType.DeveloperName!='Sublet') 
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Only sublet purchase orders may be re-opened.'));

        if(po.dealer__Status__c!='Accepted') 
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Only accepted POs can be re-opened.'));

        // Is payables processed
        if(fa.isSubletPayablesProcessed(po)) 
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Purchase Order already has a payable invoice attached.  Unable to re-open.'));

        // If the RO is posted, halt execution and alert user
        if(fa.isRepairOrderPosted(po)) 
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Associated Service Repair Order is Posted, you need to re-open the RO first.'));
		
		List<Apexpages.Message> msgs = ApexPages.getMessages();
		return msgs.size()==0;
	}

	// reverse sublet PO
	public PageReference reverseSubletPO() {
		PageReference pageref = null;


		if (validateReopenRequest()) {
			pageref = doReverseSubletPO();
			obj.dealer__Status__c = 'Reopening';
			Database.update(new dealer__Purchase_Order__c(Id=obj.Id, dealer__Status__c='Reopening'));
		}

		return pageref;
	}

	// do reverse sublet PO
	public Pagereference doReverseSubletPO() {
        String accountingPayload = '{"recordId" : "'+obj.Id+'", "orgId" : "'+UserInfo.getOrganizationId()+'", "requestedBy" : "'+UserInfo.getUserId()+'", "action" : "reverse_sublet_po"}';
        FFAccounting.emailAsyncHandler(accountingPayload);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Re-open sublet PO has been submitted for ' + obj.dealer__PO_Accounting_Name__c));	// BLL12a
		return null;
	}

}