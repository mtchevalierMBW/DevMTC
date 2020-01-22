/**
 * PurchaseOrderProcess
 * Tested by: PurchaseOrderLinkRO_TC	// PurchaseOrderProcess_TEST
 * Date: Apr 20, 2018
 * Programmer: Bryan Leaman
 *
 * Coverage:
 *	2018-04-20	80% (12/15)
 *
 */
public with sharing class PurchaseOrderProcess {

	private static User u;
	private static List<dealer__Dealer_Location_User__c> dlus;
	private static Set<Id> userLocationIds;


	// PurchaseOrderProcess
	//---------------------------------------
	public PurchaseOrderProcess() {
	}

	// PreventUnauthorizedUsers
	//---------------------------------------
	public void PreventUnauthorizedUsers(List<dealer__Purchase_Order__c> newList) {
		rtvUserAuthorizedLocations();
		for(dealer__Purchase_Order__c po : newList) {
			if (!userLocationIds.contains(po.dealer__Company__c) && u.Profile.Name!='System Administrator') 
					po.addError('Only users authorized to the location of the purchase order may modify the purchase order.');
		}
	}

	// rtvUserAuthorizations
	//---------------------------------------
	public void rtvUserAuthorizedLocations() {
		if (u==null) PurchaseOrderProcess.u = CurrentUserSingleton.getInstance();
		if (PurchaseOrderProcess.dlus==null) { 
			PurchaseOrderProcess.dlus = [
				Select Id, dealer__User__c, dealer__Dealer_Location__c 
				from dealer__Dealer_Location_User__c 
				where dealer__User__c =:UserInfo.getUserId()
			];
			PurchaseOrderProcess.userLocationIds = new Set<Id>();
			for(dealer__Dealer_Location_User__c dlu : PurchaseOrderProcess.dlus) 
				if (dlu.dealer__Dealer_Location__c!=null) 
					PurchaseOrderProcess.userLocationIds.add(dlu.dealer__Dealer_Location__c);
		}
	}

	

}