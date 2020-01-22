/** PartsInventoryPriceControl
 * Tested by: PartsPricing_TEST 
 * 2016-03-14   RedTeal     RT1 - Moved logic out of trigger to the PartsInventoryTriggerHandler
 * 2017-04-26	J. Kuljis	JVK1 - Update the register copy table, temporary code.  See comments in the TriggerHandler	
 * 2019-07-18	B. Leaman	W-000554 BLL2 - Ensure uppercase part numbers
 * 2019-07-26	B. Leaman	W-000703 BLL3 - set static price when new record is created
 */
trigger PartsInventoryPriceControl on dealer__Parts_Inventory__c (before insert, before update, after insert, after update) {
	// BLL2
	if (!Trigger.isDelete) PartsProcess.ensureUppercasePart(Trigger.new);
	// BLL2

	// BLL3
	if (Trigger.isBefore && Trigger.isInsert) PartsProcess.NewPartStaticPrice(Trigger.new);
	// BLL3 end

	if(PartsInventoryTriggerHandler.allowTrigger) {
		if(Trigger.isBefore) {
			if(Trigger.isUpdate || Trigger.isInsert) {
				PartsInventoryTriggerHandler.beforeHandler(Trigger.new);
			}
		}
		else {
			if(Trigger.isUpdate || Trigger.isInsert) {
				PartsInventoryTriggerHandler.afterHandler(Trigger.new);

				// JVK1
				PartsInventoryTriggerHandler.performRegisterSync(Trigger.new, Trigger.oldMap);
			}
		}
	}
		
}