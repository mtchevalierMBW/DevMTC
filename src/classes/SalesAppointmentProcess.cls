/**
 * SalesAppointmentProcess
 * Test by: SalesAppointment_Trigger_TEST 
 * Date: May 14, 2018
 * Programmer: Bryan Leaman
 *
 * Code coverage:
 *	2018-05-14	96% (55/57)
 *	2018-10-03	96%	(63/65)
 *
 * Modification log:
 *	2018-10-03	B. Leaman	BLL1 W-000448 - auto-populate account from contact (where possible)
 */
public with sharing class SalesAppointmentProcess {

	List<dealer__Sales_Appointment__c> newList;
	Map<Id,dealer__Sales_Appointment__c> oldMap;

	// SalesAppointmentProcess
	//---------------------------------------
	public SalesAppointmentProcess(List<dealer__Sales_Appointment__c> nlist, Map<Id,dealer__Sales_Appointment__c> omap) {
		newList = nlist;
		oldMap = omap;
	}


	public void BdcTracking() {
	   	MW_BDC_Settings__c bdcSettings = MW_BDC_Settings__c.getInstance();	// BLL6a
		//BLL5d Id uId = UserInfo.getUserId();
        //BLL5d Id pId = UserInfo.getProfileId(); 
        //BLL5d Profile p = [select Id, Name from Profile where Id=:pId];
        User u = CurrentUserSingleton.getInstance();	// BLL5a
        for(dealer__Sales_Appointment__c a : newList) { 
	        // BDC flags
	        //BLL5d if (p.Name.contains('BDC')) {
	        //BLL6d if (u.Profile.Name.contains('BDC')) {	// BLL5a  
	        if (bdcSettings.BDC_Created_SalesAppt__c) {	// BLL6a
	            a.BDC_Created__c = true;   
	            if (a.CCC_Rep__c==null) {
	                //BLL5d a.CCC_Rep__c = uId;
	                a.CCC_Rep__c = u.Id;	// BLL5a
	            } 
	        }
        }
	}

	// AssigneeAsOwner - Set owner id to assignedto id
	public void AssigneeAsOwner() {
	    for (dealer__Sales_Appointment__c app : newList) {
            // BLL2a - Set owner from assigned-to user id
            if (app.dealer__Assigned_To__c!=null) app.OwnerId = app.dealer__Assigned_To__c;
	    }                
	}
	
	
	// FirstVisitControls
	// Only 1 first visit
	// Force 1st appt to be a first visit
	// No first visit on a quote
	public void FirstVisitControls() {

		// Only 1 "First Visit" allowed
		Map<Id, Integer> firstVisits = new Map<Id, Integer>();
		List<Id> solopps = new List<Id>();
		List<Id> appts = new List<Id>();
		for (dealer__Sales_Appointment__c appt : newList) {
			if (appt.dealer__Sales_Up__c!=null) solopps.add(appt.dealer__Sales_Up__c);	// BLL4c (should not happen)
			if (appt.Id!=null) appts.add(appt.Id);	// BLL4c appt.Id is null on insert
		}

		// Map of solution opportunity Ids and count of first visits
		for(dealer__Sales_Appointment__c a : [
			select Id, dealer__Sales_Up__c
			from dealer__Sales_Appointment__c 
			where dealer__Appointment_Type__c='First Visit'
			  and dealer__Sales_Up__c in :solopps	// does not include null
		]) {
			if (firstVisits.containsKey(a.dealer__Sales_Up__c)) {
				firstVisits.put(a.dealer__Sales_Up__c, firstVisits.get(a.dealer__Sales_Up__c) + 1);
			} else {
				firstVisits.put(a.dealer__Sales_Up__c, 1);
			}
		} // for dealer__Sales_Appointment__c's
	    	
		// BLL3a
		Map<Id,dealer__Sales_Up__c> soloppMap = new Map<Id,dealer__Sales_Up__c>();
		if (solopps.size()>0) soloppMap = new Map<Id,dealer__Sales_Up__c>([select Id, dealer__Lead_Status__c from dealer__Sales_Up__c where Id in :solopps]);
		// BLL3a end	
	    	
		// Process trigger records 
		for(dealer__Sales_Appointment__c app : newList) {

			Integer cnt = 0;
			if (firstVisits.containsKey(app.dealer__Sales_Up__c)) cnt = firstVisits.get(app.dealer__Sales_Up__c);
			dealer__Sales_Appointment__c old = new dealer__Sales_Appointment__c(dealer__Appointment_Type__c = ' ');
			if (oldMap!=null) old = oldMap.get(app.Id);
			
			// Removing first visit designation
			if (old.dealer__Appointment_Type__c=='First Visit'
				&& app.dealer__Appointment_Type__c!='First Visit') {
				cnt--;
				if (cnt<0) cnt=0;
			}
			
			// Adding first visit designation (or new record)
			if (old.dealer__Appointment_Type__c!='First Visit'
				&& app.dealer__Appointment_Type__c=='First Visit') {
				//throw new SalesAppointmentException('Only one first visit allowed');
				if (cnt>=1) app.addError('Only one first visit allowed');
				else cnt++;
			}
			
			// No exception is type did not change, even if there already were multiples
			if (old.dealer__Appointment_Type__c==app.dealer__Appointment_Type__c) {
				// do nothing
			}
			if (app.dealer__Sales_Up__c!=null) firstVisits.put(app.dealer__Sales_Up__c, cnt);	// BLL4c (should not happen)

			// BLL3a
			dealer__Sales_Up__c sup = soloppMap.get(app.dealer__Sales_Up__c);
			if (sup!=null && sup.dealer__Lead_Status__c=='Quote') {
				app.addError('You cannot create an appointment for a "Quote" solution opportunity.');
			}
			// If this is the only appt and it's not a first visit, make it a first visit
			if (cnt==0 && Trigger.isInsert) app.dealer__Appointment_Type__c = 'First Visit';
			// BLL3a end

		} // for Trigger.new
	}


	// MarketingScore - save the pardot score of the contact when the appt is made
	public void MarketingScore() {
		Set<Id> contactIds = new Set<Id>();
		for(dealer__Sales_Appointment__c sappt : newList) {
			contactIds.add(sappt.dealer__Customer__c);
		}
		Map<Id,Contact> contMap = new Map<Id,Contact>([
			select Id, pi__score__c
			from Contact
			where Id in :contactIds
		]);
		for(dealer__Sales_Appointment__c sappt : newList) {
			Contact c = contMap.get(sappt.dealer__Customer__c);
			if (c!=null) sappt.MarketingScore__c = c.pi__score__c;
		}
	}

	// BLL1a
	// auto-populate account Id from the specified contact
	public void PopulateAccountFromContact() {
		Set<Id> contactIds = new Set<Id>();
	    for (dealer__Sales_Appointment__c app : newList) if (app.dealer__Customer__c!=null) contactIds.add(app.dealer__Customer__c);
		Map<Id,Contact> contactMap = new Map<Id,Contact>([select Id, AccountId from Contact where Id in :contactIds]);
		for(dealer__Sales_Appointment__c app : newList) {
			if (contactMap.containsKey(app.dealer__Customer__c)) {
				Id accountId = contactMap.get(app.dealer__Customer__c).AccountId;
				if (accountId!=null) app.dealer__Customer_Account__c = accountId;
			}
		}		
	}
	// BLL1a end
	
}