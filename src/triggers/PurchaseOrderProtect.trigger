/**
* PurchaseOrderProtect
* Tested by: PurchaseOrderLinkRO_TC
*
* Coverage:
* 	2017-10-17	82% (9/11)	
*	2018-04-20	100% (2/2)
* 
*  ChangeLog
*
*   2016-04-08     J.Kuljis    JVK1 : Add System Admin as allowed user to modify profile
*	2017-05-04	B. Leaman	BLL1 - use Managed object instead of Dealer_Location_Users__c.
*	2017-10-16	B. Leaman	BLL2 - eliminate profile query in favor of currentusersingleton;
*							ensure no nulls in list for soql.
*	2018-04-20	B. Leaman	BLL3 - refactor: use handler so it can avoid re-querying things like dealer location users.
*/
trigger PurchaseOrderProtect on dealer__Purchase_Order__c (before insert, before update) {
   
   PurchaseOrderProcess pop = new PurchaseOrderProcess();
   pop.PreventUnauthorizedUsers(Trigger.new);	// BLL3a

/**	BLL3d
  	//BLL2d Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
  	User u = CurrentUserSingleton.getInstance();	// BLL2a
    
	List<dealer__Dealer_Location_User__c> dlus = [Select Id, dealer__User__c, dealer__Dealer_Location__c from dealer__Dealer_Location_User__c where dealer__User__c =:UserInfo.getUserId()];
	Set<Id> userLocationIds = new Set<Id>();
	for(dealer__Dealer_Location_User__c dlu : dlus) if (dlu.dealer__Dealer_Location__c!=null) userLocationIds.add(dlu.dealer__Dealer_Location__c);	// BLL2c
	for(dealer__Purchase_Order__c po : Trigger.new) {
		// BLL2d consolidate code
		//if (!userLocationIds.contains(po.dealer__Company__c)) {
		//	if(!Test.isRunningTest() && UserInfo.getProfileId()!=p.Id)
		//		po.addError('Only users authorized to the location of the purchase order may modify the purchase order.');
		//}
		// BLL2a
		if (!userLocationIds.contains(po.dealer__Company__c) && u.Profile.Name!='System Administrator') 
				po.addError('Only users authorized to the location of the purchase order may modify the purchase order.');
	}
    
    // Add before context trigger to pre-flight the PO and ensure it is in Open Status.
    //if(Trigger.isUpdate && Trigger.size==1) {
    //    
    //    for(dealer__Purchase_Order__c p : Trigger.new) {
    //        if(p.dealer__Status__c == 'Accepted' && Trigger.oldMap.get(p.Id).dealer__Status__c == 'Accepted') {
    //     		p.addError('Purchase Order already accepted');       
    //        }    
    //    }
    //}
	// End Before context
**/

}