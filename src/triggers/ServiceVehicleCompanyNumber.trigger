/**
 * ServiceVehicleCompanyNumber
 * Tested by: upload_Service_Vehicle_Helper_MW_Test 
 * 
 * Coverage:
 *	2017-10-17	86%	(13/15)
 *	2019-07-30	100% (4/4) 
 * 
 * 2015-08-12	B. Leaman	BLL1 - Force VINs to uppercase.
 * 2015-09-08	B. Leaman	BLL2 - Set contact if missing and account is a person account
 * 2016-07-27	B. Leaman	BLL3 - Use CurrentUserSingleton instead of SOQL.
 * 2017-08-07	B. Leaman	BLL4 - reduce soql if nothing to query.
 * 2017-10-16	B. Leaman	BLL5 - don't allow null in Account Id selection (non-selective query)
 * 2019-07-30	B. Leaman	W-000678 BLL6 rewrite to use handler class.
 */
trigger ServiceVehicleCompanyNumber on dealer__Service_Vehicle__c (before insert, before update) {

	ServiceVehicleProcess.UppercaseVINs(Trigger.new);
	ServiceVehicleProcess.DefaultStoreCode(Trigger.new);
	ServiceVehicleProcess.VehicleOwnerContact(Trigger.new);
	ServiceVehicleProcess.SyncFromVehicleInventory(Trigger.new);

}