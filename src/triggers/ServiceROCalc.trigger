/** 
 * ServiceROCalc
 * Tested by: ServiceRepairOrder2_TC 
 * 2019-09-20	100%	(26/26)
 *
 * 2015-08-05   B. Leaman   BLL1 Don't allow vendor or 3rdParty for customer
 * 2015-09-02   J. Kuljis   JVK1 Prevent the dealership location from being changed.
 * 2015-09-03   B. Leaman   BLL2 Only check oldMap if this is an update - afterInsert causing null reference
 * 2015-09-08   B. Leaman   BLL3 Set RO contact from person account; 9/11 only run account query if customer changed or this is a new record
 * 2015-09-11   B. Leaman   BLL4 Semi-bulkify building of summary buckets. May need to make these even more bulkified later, grouping by ServiceRO and other fields.
 *                          Bulkify after trigger & only update vehicle inventory if the value is changing.
 *                          Fix moving updating status Open to Cashier or Cashier to Open based on open service jobs.
 *                          Only query for user if the value is needed. 
 * 2015-09-17   B. Leaman   BLL5 Add summary of hours to the RO, allow specified fields to be updated even though posted.
 * 2015-09-22   B. Leaman   BLL6 Ability to turn off RO location protection
 * 2015-09-22   J. Kuljis   JVK2 Override purchased order protection of posted repair orders
 * 2015-09-25   B. Leaman   BLL7 Change summary field updates so they can work in bulk.
 * 2015-09-28   J. Kuljis   JVK3 Changes to the trigger missed the total of Misc. charges on non-Customer Pay Charges
 * 2015-11-10   RedTeal		RT1  Update a field on vehicle inventory to equal the number of open repair orders it has
 * 2015-11-18   RedTeal     Rt2 Fixed a couple of issues that were causing the number of open ROs to be calculated incorrectly
 * 2015-11-30	B. Leaman	BLL8 - post tax when RO is posted.
 * 2016-01-07	B. Leaman	BLL9 - round discount.
 * 2016-01-27	B. Leaman	BLL10 - activate BLL5 to allow some fields to be updated when RO is already 'Posted'.
 * 2016-02-11	B. Leaman	BLL11 - Also need to allow changes to dealer__customer_charges__c and dealer__warranty_charges__c.
 * 2016-03-22   RedTeal     RT3   - Set the owner of an RO to the service user of the RO's location. Also added a check to make sure trigger 
 *                                  is enabled in custom setting before executing anything
 * 2016-03-31	B. Leaman	BLL12 IT#22678 - Fix issues with vehicle updates. 
 *							Need to update open RO count for all ROs, not just ones with customer charges. (Aka, GetReady & Internal charges only!)
 *							Don't create vehicle map and update all vehicles with every iteration of the the for-loop!
 *							Also, don't allow status change *from* posted when posted date/time is present.
 * 2016-04-11	B. Leaman	BLL13 IT#19606 - record last service date to account.
 * 2016-05-23	B. Leaman	BLL14 Need to adjust open ro count for vehicles removed from RO too.
 * 2016-07-12	B. Leaman	BLL15 Allow changing "Posted" to "GL Error".
 * 2016-07-27	B. Leaman	BLL16 - Use CurrentUserSingleton instead of SOQL.
 * 2016-07-28	B. Leaman	BLL17 - Provide related service vehicle when inventory vehicle is specified.
 * 2016-11-09	B. Leaman	BLL18 - Also allow updates to internallaborrate__c on posted ROs.
 * 2016-12-19	B. Leaman	BLL19 - Allow changes to 'dealer__customer_charges__c' on posted ROs too.
 * 2017-01-19	B. Leaman	BLL20 IR-0005736 - don't prevent dealerteam from changing RO status to 'Cashier' automatically.
 * 2017-02-20	B. Leaman	BLL21 IR-0005910 - set vehicle status to "Not For Sale" when GetReady (or Commercial MCEO) RO is open.
 * 2017-03-14	B. Leaman	BLL22 IR-0008615 - set vehicle inventory date when GetReady (or Commercial MCEO) RO is open and date is null.
 * 2017-03-17	B. Leaman	BLL23 IR-0009128 - Don't change from "Sold Not Deliverd" to "Not For Sale" when GRNV/GRUV/MCEO RO is opened.
 * 2017-04-27	B. Leaman	BLL24 - Show RO status attempting to change to from posted. 
 * 2017-06-19	B. Leaman	BLL25 - Reset the status code assignment date when updating the status code on vehicle inventory.
 *							Trigger execution order may be causing this to not be updated consistently.
 * 2017-07-12	B. Leaman	BLL26 Move logic to ServiceROHandler.  IR-0015235 - Don't update Ready for Sale or Sold Not Delivered to "Not for Sale" when
 *							a get-ready RO is opened.
 * 2017-07-13   J. Kuljis	JVK4 - Prevent posting of RO if Parts w/ Orders have not had a PO Associated.  If the PO is associated RO can not close until PO is received.
 * 2017-08-07	B. Leaman	BLL27 IR-0017270 - reduce soql by skipping some routines on insert, handle after delete to update vehicle open RO count.
 * 2018-02-15	B. Leaman	BLL28 RAISIN hash support to identify ROs that need updated in the RAISIN app.
 * 2018-05-02	B. Leaman	BLL29 - validate ROs prior to invoice/post.
 * 2019-05-09	B. Leaman	W-000575 BLL30 update total collected amount from cashiering records.
 * 2019-05-24	B. Leaman	BLL31 W-000473 - apply warranty deductible 
 * 2019-08-05	B. Leaman	W-000728 BLL32 - trying to remove SOQL limit tests to ensure updates occur.
 */

trigger ServiceROCalc on dealer__Service_Repair_Order__c (before insert, before update, after insert, after update, before delete, after delete) {

	ServiceROHandler sroh = new ServiceROHandler(Trigger.new, Trigger.oldMap);

	System.debug('******** ServiceROCalc TRIGGER FIRED *********');
	
	if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
		if (Trigger.isUpdate) sroh.protectPostedROs();	// check this first so subsequent actions won't cause the error message if they update a field, BLL27c
		sroh.repairOrderDefaults();

		if (Trigger.isUpdate) CashierProcess.serviceTotalCollected(Trigger.new);	// BLL30a
 
		MW_TriggerControls__c postTax = MW_TriggerControls__c.getInstance('RepairPostTax');
    	System.debug(postTax);
        if (Trigger.isUpdate && (postTax==null || postTax.Enabled__c)) sroh.PostROSalesTax();

 		MW_TriggerControls__c AccountLastService = MW_TriggerControls__c.getInstance('AccountLastService');  // BLL9a
 		if (AccountLastService==null || AccountLastService.Enabled__c==true) AccountProcess.RecordLastService(Trigger.newMap);

	    MW_TriggerControls__c RAISIN_Hash = MW_TriggerControls__c.getInstance('RAISIN_Hash');	// BLL28a
	    MW_TriggerControls__c triggerControl = MW_TriggerControls__c.getInstance('SROTriggers');
	    MW_TriggerControls__c warrantyDeductible = MW_TriggerControls__c.getInstance('WarrantyDeductible');	// BLL31
	    if(triggerControl == null || triggerControl.Enabled__c) { 
	        System.debug( 'Trigger Size:' + Trigger.size );
	        // NOTE: 2017-07-13 BLL: sequence of triggers means roll-up summary is not
	        // always up-to-date when misc charges are automatically added by ServiceROTransports.
	        // However, as soon as taxes are recalculated, it catches up (because RO header is updated).
			if (Trigger.isUpdate) sroh.rollupSummaryFields();	// BLL27c
			if (Trigger.isUpdate) sroh.applyDiscount();		// BLL27c
			if (Trigger.isUpdate) sroh.ensureAllPartsOrdered();	// JVK4, BLL27c
			if (Trigger.isUpdate && RAISIN_Hash!=null && RAISIN_Hash.Enabled__c) RAISIN_Utility.UpdateRoHashes(Trigger.new);	// BLL28a
			if (Trigger.isUpdate) sroh.ValidateCompletedROs();	// BLL29a
			// BLL31
			if (warrantyDeductible==null || warrantyDeductible.Enabled__c) {
				if (Trigger.isUpdate) sroh.ApplyWarrantyDeductible();
			}	
			// BLL31 end
	    }

		MW_TriggerControls__c protectSROLocation = MW_TriggerControls__c.getInstance('protectSROLocation');  
		if (Trigger.isUpdate && (protectSROLocation==null || protectSROLocation.Enabled__c)) sroh.protectLocation();	// BLL27c

	}
    
    if (Trigger.isBefore && Trigger.isDelete) {
		sroh.protectDeleteWithCharges();
    }	// end if isBefore && isDelete    	

	// BLL32 remove limits test
	if (Trigger.isAfter) System.debug('Query limit count: ' + String.valueOf(Limits.getQueries()) + ' After Context for WIP');
	//if(Trigger.isAfter && Limits.getQueries() < 70) {
	if (Trigger.isAfter && !Trigger.isDelete) {
		sroh.updateVehicles();	// open RO count, vehicle status
		if (Trigger.isUpdate) sroh.PostedROUpdatesSrvVeh();	// BLL22
	}
	// BLL32 end

}