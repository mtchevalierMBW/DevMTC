/**
 * VehicleInventoryUpdate
 * Tested by: VehicleProcess_TEST		// DealMBW_TC, VehicleInventory_TEST 
 * Programmer: Bryan Leaman
 * Date: Jan 21, 2016
 * 
 * Code coverage:
 * 2017-09-01	VehicleInventory_TEST	85% (30/35)
 * 2018-03-13	VehicleProcess_TEST		100% (7/7)
 * 
 * IT17887 Determine payment due date based on bank holiday schedule.
 * BankDays version of BusinessHours object Has Mon-Fri all day so that we can add 24 hours per day and get the correct results.
 * The BankDays BusinessHours object has bank holidays attached so they are accounted for.
 *
 * 2016-09-27	B. Leaman	BLL1 - Copy custom fields to managed copies so they are available on forms. 
 * 2017-02-06   A. Bangle   ACB1 - Create logic for copying managed make field to custom make picklist field
 * 2017-09-01	B. Leaman	BLL2 - Recalculate open RO count (Open_Service_Repair_Orders__c).
 * 2017-09-28	B. Leaman	BLL3 - Handle error inserting vehicle with payment due days & sale date already populated.
 * 2018-03-13	B. Leaman	BLL4 - move logic to VehicleProcess class; implement next 3 flooring payment calculations;
 * 2019-08-14	B. Leaman	W-000729 BLL5 - Copy fields from conversion kit whenever assigned or changed.
 */
trigger VehicleInventoryUpdate on dealer__Vehicle_Inventory__c (before insert, before update, after update) {

	VehicleProcess vp = new VehicleProcess(Trigger.new, Trigger.newMap, Trigger.oldMap);

	if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {	// BLL4a
		vp.CalculatePayments();
		vp.SynchronizeFields();
		vp.SyncConversionKitFields();	// BLL5
		vp.StandardizeColor();
		vp.CalculatePaymentDueDate();
		vp.CountOpenROs();
		vp.VehicleLocationAndOwner();
	}
	
	if (Trigger.isAfter && Trigger.isUpdate) {
		vp.UpdateDealVehicleCosts();
	}
    
}