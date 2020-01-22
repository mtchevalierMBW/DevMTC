/**
 * ServiceVehicleProcess
 * Tested by: upload_Service_Vehicle_Helper_MW_Test
 * Date: 2019-07-30
 * Programmer: Bryan Leaman
 * Project: W-000678
 * Update proposal F&I overall status info when credit application statuses are updated.
 *
 * Coverage:
 *	2019-07-30	90%	(27/30)
 *
 * Modifications: 
 *
**/
public with sharing class ServiceVehicleProcess {

	static Map<Id,dealer__Vehicle_Inventory__c> stockVehMap;
 
	// UppercaseVINs
	public static void UppercaseVINs(List<dealer__Service_Vehicle__c> newlist) {
		for(dealer__Service_Vehicle__c sv : newlist) {
			if (sv.dealer__VIN__c!=null) {
			    sv.dealer__VIN__c = sv.dealer__VIN__c.toUpperCase();
			}
		}
	}

	// DefaultStore
	public static void DefaultStoreCode(List<dealer__Service_Vehicle__c> newlist) {
		User u = CurrentUserSingleton.getInstance();
		for(dealer__Service_Vehicle__c sv : newlist) {
			if(String.isBlank(sv.dealer__Company_Number__c)) {
				sv.dealer__Company_Number__c=u.Division;
			}
		}
	}

	// VehicleOwnerContact
	public static void VehicleOwnerContact(List<dealer__Service_Vehicle__c> newlist) {
		Set<Id> acctIds = new Set<Id>();
		for(dealer__Service_Vehicle__c sv : newlist) {
			if (sv.dealer__Veh_Owner__c!=null) acctIds.add(sv.dealer__Veh_Owner__c);
		}
		AccountsSingleton accts = AccountsSingleton.getInstance();
		accts.addIds(acctIds);
		accts.retrieveAccounts();
		for(dealer__Service_Vehicle__c sv : newlist) {
			Account a = accts.getById(sv.dealer__Veh_Owner__c);
			if (a!=null && a.isPersonAccount) sv.dealer__Veh_Owner_Contact__c = a.PersonContactId;
		}
	}

	// SyncFromVehicleInventory
	public static void SyncFromVehicleInventory(List<dealer__Service_Vehicle__c> newlist) {
		if (stockVehMap==null) stockVehMap = new Map<Id,dealer__Vehicle_Inventory__c>();
		// get referenced stock records
		Set<Id> vehInvIds = new Set<Id>();
		for(dealer__Service_Vehicle__c sv : newlist) {
			if (sv.dealer__Sales_Inventory__c!=null) vehInvIds.add(sv.dealer__Sales_Inventory__c);
		}
		// build map of stock records only if we don't have them all already
		if (!stockVehMap.keySet().containsAll(vehInvIds)) {
			stockVehMap = new Map<Id,dealer__Vehicle_Inventory__c>([
				select Id, Name, Conv_MFG__c
				from dealer__Vehicle_Inventory__c
				where Id in :vehInvIds
			]);
		}
		// copy fields into the service vehicle records
		for(dealer__Service_Vehicle__c sv : newlist) {
			dealer__Vehicle_Inventory__c stock = sv.dealer__Sales_Inventory__c==null ? null : stockVehMap.get(sv.dealer__Sales_Inventory__c);
			if (stock!=null) sv.dealer__Conversion_MFG__c = stock.Conv_MFG__c;
		}
	}

}