/**
 * DealProcessTrigger
 * Tested by: DealProcess_TEST
 *
 * Coverage:
 *	2018-01-23	100%	(35/35)
 *
 * 2016-08-05	B. Leaman	Written to consolidate and clean up other DealSetCompanyNumber and DealApprovalCreateRepairOrder triggers.
 * 2016-09-21	B. Leaman	BLL1 - Added code to synchronize managed package fields with same names as custom fields.
 * 2016-12-05	B. Leaman	BLL2 - move other object updates to "After" update.
 * 2017-02-10	B. Leaman	BLL3 - Administrative update flag & enforce calculations on all proposal updates.
 * 2017-02-20	B. Leaman	BLL4 - Mark appraisals won when proposal is Won - Posted.
 * 2017-03-02	B. Leaman	BLL5 - Changes for commercial proposals (mark quote Ordered & Received)
 * 2017-03-21	B. Leaman	BLL6 - Only run some of the actions on an update (not during conversion of quotes to proposals).
 * 2017-09-06	B. Leaman	NOT YET: BLL7 - Update service vehicle reference on ESCs (when delivered, remove if not Won)
 *							DealerTeam forces a value in there when it can, so we can't blank the vehicle until delivered yet.
 * 2017-09-18	B. Leaman	BLL8 - Add ready for delivery processes. (IR-0016771 remove parts notification)
 * 2018-01-14	B. Leaman	BLL9 - Set ESC status based on proposal being delivered; update service vehicle owner & trade-in service veh owner;
 * 2018-03-07	B. Leaman	BLL10 - Vehicles no longer sold (proposal moves from Won* to Pending or Lost (or null)). 
 * 2019-02-26	B. Leaman	BLL11 - credit application status updates; eliminate redundant conditions;
 * 2019-05-09	B. Leaman	W-000575 BLL12 update total collected amount from cashiering records.
 */
trigger DealProcessTrigger on dealer__Deal__c (after insert, before insert, before update, after update, before delete) {
	DealProcess dp = new DealProcess(Trigger.new, Trigger.oldMap);
	
	MW_TriggerControls__c ProposalPreventDelete = MW_TriggerControls__c.getInstance('ProposalPreventDelete');  // BLL9a
    if (Trigger.isBefore && Trigger.isDelete && (ProposalPreventDelete==null || ProposalPreventDelete.Enabled__c)) dp.DeleteProtection();
	
	if (Trigger.isBefore && !Trigger.isDelete) {
		dp.ProposalIntegrity();
		dp.ProposalCalculations();	// BLL3a
	// BLL11d }		

		if (Trigger.isUpdate) CashierProcess.dealTotalCollected(Trigger.new);	// BLL12a

	// BLL11d if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
 		MW_TriggerControls__c AccountLastSale = MW_TriggerControls__c.getInstance('AccountLastSale');  // BLL9a
 		if (AccountLastSale==null || AccountLastSale.Enabled__c==true) AccountProcess.RecordLastSale(Trigger.newMap);
	// BLL11d }

	// BLL11d if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
		dp.StatusChangeValidation();
		//BLL2d Updates to related objects should be *after* triggers	
		//BLL2d dp.WonSolutionOpportunities();
		//BLL2d dp.VehiclesSoldNotDelivered();
		//BLL2d dp.VehiclesDelivered();

		if (Trigger.isUpdate) {	// BLL6a
		    MW_TriggerControls__c postTax = MW_TriggerControls__c.getInstance('ProposalPostTax');
		    if (postTax==null || postTax.Enabled__c) dp.PostSalesTax();
			dp.DeliveryRepairOrders();
			dp.ReadyForDelivery();	// BLL8a
			dp.PostingEntries();
			dp.PostingProposals();	// NEW: only accounting can approve final status of Won - Posted
			// BLL11
		    MW_TriggerControls__c ProposalCreditAppSts = MW_TriggerControls__c.getInstance('ProposalCreditAppSts');
			if (ProposalCreditAppSts==null || ProposalCreditAppSts.Enabled__c) {
				CreditApplicationProcess.flagMissingItems(Trigger.new, Trigger.oldMap);
				CreditApplicationProcess.updateProposalFandIStatus(Trigger.new);
			}
			// BLL11 end
		}	// BLL6a
		
		dp.SyncManagedFields();	// BLL1a (moved to last step)
	}

	// BLL2a
	if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
		dp.WonSolutionOpportunities();
		dp.ConversionOrderStatus();	// BLL5a
		dp.VehiclesSoldNotDelivered();
		dp.VehiclesDelivered();
		dp.VehiclesNotSoldAnymore();	// BLL10a
	    MW_TriggerControls__c ProposalWonAppraisals = MW_TriggerControls__c.getInstance('ProposalWonAppraisals');	// BLL4a
		if (ProposalWonAppraisals==null || ProposalWonAppraisals.Enabled__c==true) dp.WonAppraisals();	// BLL4a
	}
	// BLL2a end
	// BLL9a
	if (Trigger.isAfter && (Trigger.isUpdate)) {
	    MW_TriggerControls__c ProposalESCStatus = MW_TriggerControls__c.getInstance('ProposalESCStatus');	
		if (ProposalESCStatus==null || ProposalESCStatus.Enabled__c==true) dp.ProposalESCStatus();
	    MW_TriggerControls__c ProposalVehicleOwner = MW_TriggerControls__c.getInstance('ProposalVehicleOwner');	
		if (ProposalVehicleOwner==null || ProposalVehicleOwner.Enabled__c==true) dp.ProposalVehicleOwner();
	}
	// BLL9a end
	if (Trigger.isAfter && Trigger.isInsert && trigger.size==1 && Trigger.new[0].dealer__Sales_Lead__c!=null) {
		dp.CreateTradeFromSalesUp();	 
	}
	// BLL7a
	//if (Trigger.isAfter && Trigger.isUpdate) {
	//	dp.ServiceContractVehicles();	// assign when delivered, remove if no longer a won proposal
	//}
	// BLL7a end
	
	// BLL3a lastly, remove "administrative update" flag
	if (Trigger.isBefore && !Trigger.isDelete) {
		for(dealer__Deal__c d : Trigger.new) d.AdministrativeUpdate__c = false;
	}
    
}