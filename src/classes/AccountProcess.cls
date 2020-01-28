/**
 * AccountProcess
 * Tested by: AccountProcess_TEST
 * Date: Apr 11, 2016
 * Programmer: Bryan Leaman
 *
 * Code coverage:
 *	2018-07-16	85% (322/376)
 *	2019-01-15	92%	(350/380)
 *	2019-01-21	91% (343/373)
 *	2019-08-09	86% (not currently testing AMM7 new routine)
 * 	2020-01-28	4 tests failing (100% test coverage for new development lines 904-960)
 * 
 * Modification log:
 *	2017-02-09	B. Leaman	BLL1 - Change how last sale types are determinied due to change in commercial process.
 *	2017-08-07	B. Leaman	BLL2 - Reduce SOQL by not querying when lists are empty. 
 *	2018-07-06	B. Leaman	BLL3 - Consolidate account triggers & push processes into this class.
 *	2019-01-15	B. Leaman	W-000551 BLL4 If PersonHomePhone is removed, also remove it from the account's Phone field.
 *	2019-01-21	B. Leaman	W-000560 BLL5 don't transfer opportunities. SF does this automatically if the old owner matches.
 *							Transferring all open opps doesn't work since almost nobody has authority to opportunities anymore.
 *  2019-03-28  A. Miller   W-000555 AMM6 Update to handle sycning the Mobile and Other phone numbers
// AMM7 won't load into qa since there are no record types for the opportunity__c object there.
// *  2019-03-20  A. Miller   W-000580 AMM7 Update for the new TransitWorks Account Record Type for Lead tracking. 
// *                              Translates all child Opportunities__c to the sales record type on record Account Record Type change
// *                              Update Child Opportunities with Customer Master once the lookup is not null
 *	2019-04-12	B. Leaman	W-000575 BLL6 - reduce soql queries.
 *	2019-08-09	B. Leaman	W-000734 BLL7 - support for last declined service date; also add last customer pay service;
 *							and do not record last service if everything was declined (no charges whatsoever);
 *	2019-10-08	B. Leaman	W-000764 BLL27 - newly-created accounts are not always getting the creating user's store assigned to them.
 *	2019-12-04	B. Leaman	W-000799 BLL28 Count Customer Pay ROs and Rentals and store on account.
 *								Also record last Home Access sale date.
*	2020-01-28	M. Chevalier MTC29 Added updateClosestStorePerAccount call stack and BuildDefaultDataValuesValidationsSummaries
*/
public with sharing class AccountProcess {

	static Map<Id, Account> acctRLMap;

	// BLL28
	public static void RecordRelatedRcdCounts(List<Account> newList) {
		Set<Id> acctIds = new Set<Id>();
		for(Account a : newList) {
			if (a.Id!=null) acctIds.add(a.Id);
		}
		if (acctRLMap==null) acctRLMap = new Map<Id, Account>();
		if (acctIds.size()>0 && !acctRLMap.keySet().containsAll(acctIds)) {
			acctIds.addAll(acctRLMap.keySet());	// ensure previously-read records are included too
			acctRLMap = new Map<Id, Account>([
				select Id, Name,
					(select Id, Name, Account__c, dealer__Agreement_Status__c, dealer__Return_Date__c from Rental_Agreements2__r where dealer__Agreement_Status__c='Paid' order by dealer__Return_Date__c),
					(select Id, Name, dealer__Customer__c, dealer__Status__c, dealer__Posted_Date_Time__c from dealer__Service_Repair_Orders__r where dealer__Customer_Charges__c>0 and dealer__Status__c='Posted')
				from Account
				where Id in :acctIds
			]);
		}
		for(Account a : newList) {
			if (a.Id!=null) {
				Account acct = acctRLMap.get(a.Id);
				if (acct!=null) {
					a.Customer_Pay_SRO_Count__c = acct.dealer__Service_Repair_Orders__r.size();
					a.Rental_Agreement_Count__c = acct.Rental_Agreements2__r.size();
					if (acct.Rental_Agreements2__r.size()>0) a.Last_Rental_Return__c = acct.Rental_Agreements2__r[0].dealer__Return_Date__c;
				}
			}
		}
	}
	// BLL28

	// LastServiceAndSale - NOT USED! code not implemented in favor of the next two routines!
	// invoked from before update account trigger
	// sets the LastServiceDate and LastVehicleSaleDate fields on the account
	//------------------------------------------
	public static void LastServiceAndSale(Map<Id,Account> acctMap) {
		if (acctMap!=null) {
			Set<Id> acctIds = acctMap.keySet();
			List<AggregateResult> lastServSale = [
				select dealer__Veh_Owner__c, max(dealer__Last_Service__c) lastservice, 
					max(dealer__Sales_Inventory__r.dealer__Sale_Date__c) lastsale
				from dealer__Service_Vehicle__c
				where dealer__Veh_Owner__c in :acctIds
				group by dealer__Veh_Owner__c
			];
			Map<Id, AggregateResult> lastMap = new Map<Id, AggregateResult>();
			for(AggregateResult r : lastServSale) lastMap.put((Id) r.get('dealer__Veh_Owner__c'), r);

			for(Account a : acctMap.values()) {
				Date lastService = null;
				Date lastSale = null;
				if (lastMap.containsKey(a.Id)) lastService = (Date) lastMap.get(a.Id).get('lastservice');
				if (lastMap.containsKey(a.Id)) lastSale = (Date) lastMap.get(a.Id).get('lastsale');
				if (a.LastServiceDate__c==null || a.LastServiceDate__c<lastService) a.LastServiceDate__c = lastService;
				if (a.LastVehicleSaleDate__c==null || a.LastVehicleSaleDate__c<lastSale) a.LastVehicleSaleDate__c = lastSale;
			}
		}
	}


	// RecordLastSale
	// Record last vehicle or equipment sale dates on account
	//------------------------------------------
	public static void RecordLastSale(Map<Id,dealer__Deal__c> dealMap) {
		Set<String> vehicleSaleTypes = new Set<String>{'Retail Vehicle Sale','Wholesale','Chassis/Conversion'};	// BLL1a
		//Set<String> customerVehicleSaleTypes = new Set<String>{'Equipment Only','Equipment Only Sale','Financial Products'};	// BLL1a
		Set<String> equipmentSaleTypes = new Set<String>{'Equipment Only','Equipment Only Sale','DME/Other'};	// BLL1a
		Set<String> homeaccessSaleTypes = new Set<String>{'Home Access'};	// BLL28
		
		if (dealMap!=null) {
			// Get current account last sale dates
			Set<Id> accountIds = new Set<Id>();
			for(dealer__Deal__c d : dealMap.values()) {
				if (d.dealer__Buyer__c!=null) accountIds.add(d.dealer__Buyer__c);
			}
			Map<Id,Account> acctMap = new Map<Id,Account>();
			// BLL28 add LastHomeAccessSaleDate__c
			if (accountIds.size()>0) acctMap = new Map<Id,Account>([
				select Id, LastEquipmentSaleDate__c, LastVehicleSaleDate__c, LastHomeAccessSaleDate__c
				from Account
				where Id in :accountIds
			]);

			Map<Id,Account> updAccounts = new Map<Id,Account>();

			for(dealer__Deal__c d : dealMap.values()) {
				Account a = acctMap.get(d.dealer__Buyer__c);
				if (a!=null && d.dealer__Status__c=='Won - Posted' && d.Proposed_Delivery_Date__c!=null) {
					//BLL1d if (d.dealer__Deal_Type__c=='Equipment Only Sale') {
					if (equipmentSaleTypes.contains(d.dealer__Deal_Type__c)) {	// BLL1a
						if (a.LastEquipmentSaleDate__c==null || d.Proposed_Delivery_Date__c>a.LastEquipmentSaleDate__c) a.LastEquipmentSaleDate__c = d.Proposed_Delivery_Date__c;
					//BLL1d } else if (d.dealer__Deal_Type__c=='Retail Vehicle Sale' || d.dealer__Deal_Type__c=='Wholesale') {
					} else if (vehicleSaleTypes.contains(d.dealer__Deal_Type__c)) {	// BLL1a
						if (a.LastVehicleSaleDate__c==null || d.Proposed_Delivery_Date__c>a.LastVehicleSaleDate__c) a.LastVehicleSaleDate__c = d.Proposed_Delivery_Date__c;
					// BLL28
					} else if (homeaccessSaleTypes.contains(d.dealer__Deal_Type__c)) {	
						if (a.LastHomeAccessSaleDate__c==null || d.Proposed_Delivery_Date__c>a.LastHomeAccessSaleDate__c) a.LastHomeAccessSaleDate__c = d.Proposed_Delivery_Date__c;
					// BL28 end
					}
					if (a.LastEquipmentSaleDate__c!=null && a.LastEquipmentSaleDate__c>Date.today()) a.LastEquipmentSaleDate__c=Date.today();
					if (a.LastVehicleSaleDate__c!=null && a.LastVehicleSaleDate__c>Date.today()) a.LastVehicleSaleDate__c=Date.today();
					if (a.LastHomeAccessSaleDate__c!=null && a.LastHomeAccessSaleDate__c>Date.today()) a.LastHomeAccessSaleDate__c=Date.today();	// BLL28
					if (a.LastEquipmentSaleDate__c!=null || a.LastVehicleSaleDate__c!=null || a.LastHomeAccessSaleDate__c!=null) updAccounts.put(a.Id,a);	// BLL28c
				}
			}

			if (updAccounts.size()>0) Database.update(updAccounts.values());
		}
	}


	// RecordLastService
	// Last service date (an RO not related to a proposal)
	//------------------------------------------
	public static void RecordLastService(Map<Id,dealer__Service_Repair_Order__c> roMap) {
		// BLL7 which ROs have a declined service op-code
		Set<Id> declinedSRO = new Set<Id>();
		if (roMap!=null) {
			for(dealer__Service_Job__c declined : [
				select Id, dealer__Service_Repair_Order__c
				from dealer__Service_Job__c
				where dealer__Service_Repair_Order__c in :roMap.keySet()
				  and dealer__Standard_Operation_Code__r.Name like '%Decline%'
			]) {
				declinedSRO.add(declined.dealer__Service_Repair_Order__c);
			}

			// Map of accounts
			Set<Id> accountIds = new Set<Id>();
			for(dealer__Service_Repair_Order__c ro : roMap.values()) {
				if (ro.dealer__Customer__c!=null) accountIds.add(ro.dealer__Customer__c);
			}
			Map<Id,Account> acctMap = new Map<Id,Account>();
			if (accountIds.size()>0) acctMap = new Map<Id,Account>([
					select Id, LastServiceDate__c, LastDeclinedServiceDate__c, LastCustPayServiceDate__c 
					from Account
					where Id in :accountIds
			]);
			// BLL7 end
			Map<Id, Account> updAccounts = new Map<Id,Account>();
			for(dealer__Service_Repair_Order__c ro : roMap.values()) {
				if (ro.dealer__Status__c=='Posted' && ro.dealer__Posted_Date_Time__c!=null) { 	
					Account a = acctMap.get(ro.dealer__Customer__c);
					Boolean updateServiceDate = false;
					// BLL7 end
					if (a!=null && ro.Deal__c==null && ro.CommercialQuote__c==null && ro.dealer__Posted_Date_Time__c!=null) {
						// BLL7
						//if (a.LastServiceDate__c==null || ro.dealer__Posted_Date_Time__c.date() > a.LastServiceDate__c) a.LastServiceDate__c = ro.dealer__Posted_Date_Time__c.date();
						// BLL7
						//if (a.LastServiceDate__c==null || ro.dealer__Posted_Date_Time__c.date() > a.LastServiceDate__c) {
						if (ro.dealer__Total_Repair_Order_Charges__c>0 && (a.LastServiceDate__c==null || ro.dealer__Posted_Date_Time__c.date() > a.LastServiceDate__c)) {
						// BLL7
							a.LastServiceDate__c = ro.dealer__Posted_Date_Time__c.date();
							updateServiceDate = true;
						}
						// BLL7 last customer pay service
						if (ro.dealer__Customer_Charges__c>0 && (a.LastCustPayServiceDate__c==null || ro.dealer__Posted_Date_Time__c.date() > a.LastCustPayServiceDate__c)) {
							a.LastCustPayServiceDate__c = ro.dealer__Posted_Date_Time__c.date();
							updateServiceDate = true;
						}
						// BLL7 end
						if (declinedSRO.contains(ro.Id) && (a.LastDeclinedServiceDate__c==null || ro.dealer__Posted_Date_Time__c.date() > a.LastDeclinedServiceDate__c)) {
							a.LastDeclinedServiceDate__c = ro.dealer__Posted_Date_Time__c.date();
							updateServiceDate = true;
						}
						// BLL7 end
					}
					// BLL7
					//if (a.LastServiceDate__c!=null) acctDateMap.put(a.Id,a);
					if (updateServiceDate) updAccounts.put(a.Id,a);
					// BLL7 end
				}
			}
			if (updAccounts.size()>0) Database.update(updAccounts.values());
		}
	}


	// Update open tasks, open solution opportunities and open opportunities to new account owner
	//------------------------------------------
	public static void UpdateRelatedObjectOwners(List<Account> newlist, Map<Id,Account> oldmap) {
    	Set<Id> accountIds = new Set<Id>();
    	Map<Id, Id> oldownermap = new Map<Id, Id>();
    	Map<Id, Id> newownermap = new Map<Id, Id>();
    	for(Account newacct : newlist) {
            Account oldacct = oldmap.get(newacct.Id);
System.debug(newacct.OwnerId);
if (oldacct!=null) System.debug(oldacct.OwnerId);
            if (oldacct!=null && oldacct.OwnerId != newacct.OwnerId) {
           		accountIds.add(newacct.Id);
           		oldownermap.put(newacct.Id, oldacct.OwnerId);
           		newownermap.put(newacct.Id, newacct.OwnerId);
            }
    	}

System.debug(oldownermap);
System.debug(newownermap);

        // Only run if there are accounts whose owners have changed
        if (accountIds.size()>0) {
	   	    	
	    	// Tasks
	    	List<Task> updTasks = new List<Task>();
	    	for(Task t : [select Id, Subject, OwnerId, WhatId from Task where WhatId in :accountIds and Status!='Completed']) {
	    		Id newOwnerId = newownermap.get(t.WhatId);	// BLL2a
	    		Id oldOwnerId = oldownermap.get(t.WhatId);	// BLL2a
	    		System.debug('Change owner ' + oldOwnerId + ' to ' + newOwnerId + '? Task owner='+t.ownerId);
	    		if (newOwnerId!=null && oldOwnerId==t.ownerId) {	// BLL2a
	    			t.ownerId = newOwnerId;	// BLL2a
	    			updTasks.add(t);
	    			System.debug('Change task owner to ' + t.ownerId);
	    		}
	    	} // end for Task
	        if (updTasks.size()>0) update(updTasks);
	   	    	
	    	// Solution opportunities
	    	List<dealer__Sales_Up__c> updSolOpps = new List<dealer__Sales_Up__c>();
	    	for(dealer__Sales_Up__c s : [
	    		select Id, Name, OwnerId, dealer__Customer_Account__c
				from dealer__Sales_Up__c
				where dealer__Customer_Account__c in :accountIds
				  and dealer__Lead_Status__c='Pending'
			]) {
	    		s.OwnerId = newownermap.get(s.dealer__Customer_Account__c);
	    		if (s.OwnerId!=null) updSolOpps.add(s);
	   	   	} // end for dealer__Sales_Up__c
	   	    if (updSolOpps.size()>0) update(updSolOpps);
	
			// BLL5 - new logic would be identical to what SF already does. Don't need this section at all
	   	   	//// Opportunities
	   	   	//List<Opportunity> updOpps = new List<Opportunity>();
	   	   	//for(Opportunity o : [
	   	   	//	select Id, Name, OwnerId, AccountId 
	   	   	//	from Opportunity 
	   	   	//	where AccountId in :accountIds 
	   	   	//	  and StageName='Pending'
	   	   	//]) {
			//	// BLL5 - new logic would be identical to what SF already does. Don't need this section at all
			//	Id oldOwnerId = oldownermap.get(t.WhatId);
			//	if (oldOwnerId!=null && o.ownerId==oldOwnerId) {
			//	// BLL5 end
	   	   	//		o.ownerId = newownermap.get(o.AccountId);
		   	//		if (o.ownerId!=null) updOpps.add(o);
			//	// BLL5
			//	}
			//	// BLL5 end
	   	   	//} // end for Opportunity
	        //if (updOpps.size()>0) update(updOpps);
			// BLL5 end of delete

        } // BLL1a end if accounts.size()>0
		
	}	// end UpdateRelatedObjectOwners
	
	
	// AddInfluencerAssociation (from lookup fields on account)
	//------------------------------------------
	public static void AddInfluencerAssociation(List<Account> newlist) {
		//Map<String, Schema.RecordTypeInfo> IARcdTypes = Schema.SObjectType.InfluencerAssociation__c.getRecordTypeInfosByName();
		//Schema.RecordTypeInfo AcctIaRti = IARcdTypes.get('Account');
		//Id AcctIaRtId = AcctIaRti.getRecordTypeId();
		//List<InfluencerAssociation__c> ialist = new List<InfluencerAssociation__c>();
		Map<String, Schema.RecordTypeInfo> IA2RcdTypes = Schema.SObjectType.InfluencerAssociation2__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo AcctIa2Rti = IA2RcdTypes.get('Account');
		Id AcctIa2RtId = AcctIa2Rti.getRecordTypeId();
		List<InfluencerAssociation2__c> ia2list = new List<InfluencerAssociation2__c>();
		for(Account a : newlist) {
			// BLL23a - AddNewInfluencer suppoort
			if (a.Id!=null && (a.AddNewInfluencer__c!=null || a.AddNewInfluencerContact__c!=null)) { 
				//BLL26d InfluencerAssociation__c newia = new InfluencerAssociation__c(
				//BLL26d 	RecordTypeId=AcctIaRtId, Account__c=a.AddNewInfluencer__c,
				//BLL26d 	InfluencedAccount__c=a.Id
				//BLL26d );
				InfluencerAssociation2__c newia2 = new InfluencerAssociation2__c(
					RecordTypeId=AcctIa2RtId, InfluencerAccount__c=a.AddNewInfluencer__c,
					InfluencedAccount__c=a.Id
				);
				a.AddNewInfluencer__c = null;
				if (a.AddNewInfluencerContact__c!=null) {
				//BLL26d 	newia.Contact__c=a.AddNewInfluencerContact__c;
					newia2.InfluencerContact__c=a.AddNewInfluencerContact__c;
					a.AddNewInfluencerContact__c = null;
				}
				//BLL26d ialist.add(newia);
				ia2list.add(newia2);
			}
			// BLL23a end

		}
		if (ia2list.size()>0) insert(ia2list);
		
	}
	
	// Clean up orphaned influencer associations
	//------------------------------------------
	public static void CleanUpInfluencerAssociations(List<Account> oldlist) {
		// before delete - clean up InfluencerAssociations
 		List<InfluencerAssociation2__c> ia2List = new List<InfluencerAssociation2__c>();
		Set<Id> accountIds = new Set<Id>();
		for(Account a : oldlist) accountIds.add(a.Id);
		if (accountIds.size()>0) {
			ia2List = [select Id, Name from InfluencerAssociation2__c where InfluencedAccount__c in :accountIds or (InfluencerAccount__c in :accountIds and InfluencerContact__c=null) limit 2000];
			if (ia2List.size()>0) delete(ia2List);
		}
	}	// end CleanUpInfluencerAssociations
	
	
	// UploadReferencesByName - upload record type, location and account owner by name rather than by Id
	//------------------------------------------
	public static void UploadReferencesByName(List<Account> newlist) {
        // For upload helper (users & locations)
		List<String> usernames = new List<String>();
        List<String> locationnames = new List<String>();

        // Upload helper -- get list of users and locations for later assignment by name lookup
        Map<String, Id> locationmap = new Map<String, Id>();
        Map<Id, Id> gmmap = new Map<Id, Id>();
        Map<String, Id> usermap = new Map<String, Id>();
        Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();

		// get lists of text to translate to ids
		for(Account a : newlist) {
			String o = a.upload_Owner__c;
			if (!String.isBlank(o)) usernames.add(o);
			//System.debug(usernames);
			String l = a.upload_Location__c;
			if (!String.isBlank(l)) locationnames.add(l);
		}
    
		// generate Map to locations by external ID
		if (locationnames.size()>0) {
			for(dealer__Dealer_Location__c l:[
				select Id, Name, dealer__Company_Number__c, dealer__General_Manager__c 
				from dealer__Dealer_Location__c
				where Name in :locationnames
			]) {
				locationmap.put(l.Name.toLowerCase(), l.Id);
				gmmap.put(l.id, l.dealer__General_Manager__c);
			}
		}
            
		// generate Map to users by Id
		if (usernames.size()>0) {
			for(User us: [
				select Id, Name, isActive 
				from User
				where Name in :usernames and isActive=true 
			]) {
				usermap.put(us.Name.toLowerCase(), us.Id);
			} 
		} 
		
		// Apply referenced object Ids
		for(Account a : newlist) {
			
			// Override record type - could be problematic
			if (!String.isBlank(a.upload_RecordType__c)) {
				Schema.RecordTypeInfo rtinfo = RcdTypes.get(a.upload_RecordType__c);
				if (rtinfo<>null) {
					Id rtid = rtinfo.getRecordTypeId();
					if (rtid!=null) {
						a.RecordTypeId = rtid;
						System.debug('Assigned record type for ' + a.upload_RecordType__c);
					}
				} 
				a.upload_RecordType__c = null;
			}
    
			// Get location and set location ID
			if (!String.isBlank(a.upload_Location__c)) {
				String lcname = a.upload_Location__c.toLowercase();
				if (locationmap.containsKey(lcname)) {
					Id locid = locationmap.get(lcname);
					a.Store_Location__c = locid;
					System.debug('Assigning location id for ' + lcname);
				}
				a.upload_Location__c = null;
			}
    
			// Get owner code (external ID) and set location ID
			System.debug(a.OwnerId);
			if (!String.isBlank(a.upload_Owner__c)) {
				String lcname = a.upload_Owner__c.toLowercase();
				if (usermap.containsKey(lcname)) {
					Id uid = usermap.get(lcname);
					a.OwnerId = uid;
					System.debug('Assigning ID for owner ' + lcname);
				} else if (a.Store_Location__c != null) {
					Id gmid = gmmap.get(a.Store_Location__c);
					if (gmid<>null) {
						a.OwnerId = gmid;
						System.debug('Assigning general manager as owner');
					} else {
						System.debug('No general manager');
					}
				}
				a.upload_Owner__c = null;
			}

		}

	}


	// StandardizePersonName
	//------------------------------------------
	public static void StandardizePersonName(List<Account> newlist) {
		for(Account a : newlist) {
			// Standardize first & last names if present (person accounts)
			if(!String.isBlank(a.FirstName)) {
				if (a.FirstName.isAllUpperCase()) a.FirstName = a.FirstName.toLowerCase().capitalize();
				if(a.FirstName.isAllLowerCase())  a.FirstName = a.FirstName.capitalize();
			}
			if(!String.isBlank(a.LastName)) {
				if (a.LastName.isAllUpperCase()) a.LastName = a.LastName.toLowerCase().capitalize();
				if(a.LastName.isAllLowerCase())  a.LastName = a.LastName.capitalize();
			}
		}	// end for
	}


	// SynchFFTaxFields
	//------------------------------------------
	public static void SynchFFTaxFields(List<Account> newlist, Map<Id,Account> oldmap) {
		for(Account a : newlist) {
            // BLL12a
            Account oldaccount = null;
            if (oldmap!=null) oldaccount = oldmap.get(a.Id);
            // BLL12a end

            // BLL13a - keep custom and FF exemption info in sync, prefer FF field value if both specified/changed
            if (oldaccount==null) { // FF field value has priority
                if (a.c2g__CODASalesTaxStatus__c!=null) a.SalesTaxStatus__c = a.c2g__CODASalesTaxStatus__c;
                else if (a.SalesTaxStatus__c!=null) a.c2g__CODASalesTaxStatus__c = a.SalesTaxStatus__c;
                if (a.c2g__CODAExemptionCertificate__c!=null) a.ExemptionCertificate__c = a.c2g__CODAExemptionCertificate__c;
                else if (a.ExemptionCertificate__c!=null) a.c2g__CODAExemptionCertificate__c = a.ExemptionCertificate__c;
            } else { // Field that changed has priority (FF or custom)
                if (a.c2g__CODASalesTaxStatus__c!=oldaccount.c2g__CODASalesTaxStatus__c) 
                    a.SalesTaxStatus__c = a.c2g__CODASalesTaxStatus__c;
                else if (a.SalesTaxStatus__c!=oldaccount.SalesTaxStatus__c) 
                    a.c2g__CODASalesTaxStatus__c = a.SalesTaxStatus__c;
                if (a.SalesTaxStatus__c==null && a.c2g__CODASalesTaxStatus__c!=null) a.SalesTaxStatus__c=a.c2g__CODASalesTaxStatus__c;
                if (a.SalesTaxStatus__c!=null && a.c2g__CODASalesTaxStatus__c==null) a.c2g__CODASalesTaxStatus__c=a.SalesTaxStatus__c;
                if (a.c2g__CODAExemptionCertificate__c!=oldaccount.c2g__CODAExemptionCertificate__c) 
                    a.ExemptionCertificate__c = a.c2g__CODAExemptionCertificate__c;
                else if (a.ExemptionCertificate__c!=oldaccount.ExemptionCertificate__c) 
                    a.c2g__CODAExemptionCertificate__c = a.ExemptionCertificate__c;
                if (a.ExemptionCertificate__c==null && a.c2g__CODAExemptionCertificate__c!=null) a.ExemptionCertificate__c=a.c2g__CODAExemptionCertificate__c;
                if (a.ExemptionCertificate__c!=null && a.c2g__CODAExemptionCertificate__c==null) a.c2g__CODAExemptionCertificate__c=a.ExemptionCertificate__c;
            }
            // BLL13a end
		}		
	}


	// AppendNewStockNumber
	// Pardot replaces the Desired_Vehciles__c field with the new stock number; Append to existing list instead!
	//------------------------------------------
	public static void AppendNewStockNumber(List<Account> newlist, Map<Id,Account> oldmap) {
		for(Account a : newlist) {
            // BLL12a
            Account oldaccount = null;
            if (oldmap!=null) oldaccount = oldmap.get(a.Id);
            // BLL12a end

            // BLL14a
            // Concatenate stock numbers (Desired_Vehicels__c) if changed from one or more to only 1
            if (oldaccount!=null && !String.isBlank(oldaccount.Desired_Vehicles__c)
                && !String.isBlank(a.Desired_Vehicles__c)
                && !a.Desired_Vehicles__c.contains(';')) {

                String vehicles = a.Desired_Vehicles__c.trim(); 
                // If NOT adding a duplicate stock#, append it                  
                if (!oldaccount.Desired_Vehicles__c.toUpperCase().trim().contains(a.Desired_Vehicles__c.toUpperCase().trim())) {
                    vehicles = oldaccount.Desired_Vehicles__c.trim() + '; ' + vehicles; 
                } else {
                    // Adding a duplicate stock number, so just keep the old list
                    vehicles = oldaccount.Desired_Vehicles__c.trim(); 
                }
                // BLL3a
                while(vehicles.length()>255 && vehicles.contains(';')) {
                    vehicles = vehicles.substring(vehicles.indexOf(';')+1).trim();
                }
                if (vehicles.length()>255) vehicles = vehicles.right(255); // drop off earlier/older information
                a.Desired_Vehicles__c = vehicles; 
                // BLL3a end
            }
            // BLL14a end

            // BLL17a
            // Person account: Concatenate stock numbers (Desired_Vehicles__pc) if changed from one or more to only 1
            if (a.isPersonAccount && oldaccount!=null && !String.isBlank(oldaccount.Desired_Vehicles__pc)
                && !String.isBlank(a.Desired_Vehicles__pc)
                && !a.Desired_Vehicles__pc.contains(';')) {

                String vehicles = a.Desired_Vehicles__pc.trim(); 
                // If NOT adding a duplicate stock#, append it                  
                if (!oldaccount.Desired_Vehicles__pc.toUpperCase().trim().contains(a.Desired_Vehicles__pc.toUpperCase().trim())) {
                    vehicles = oldaccount.Desired_Vehicles__pc.trim() + '; ' + vehicles; 
                } else {
                    // Adding a duplicate stock number, so just keep the old list
                    vehicles = oldaccount.Desired_Vehicles__pc.trim(); 
                }
                // BLL3a
                while(vehicles.length()>255 && vehicles.contains(';')) {
                    vehicles = vehicles.substring(vehicles.indexOf(';')+1).trim();
                }
                if (vehicles.length()>255) vehicles = vehicles.right(255); // drop off earlier/older information
                a.Desired_Vehicles__pc = vehicles;
            }
            // BLL17a end 

		}	// end for
		
	}


	// RequiredFieldDefaults
	//------------------------------------------
	public static void RequiredFieldDefaults(List<Account> newlist) {

		MW_TriggerControls__c defaultExpAcct = MW_TriggerControls__c.getInstance('DefaultExpAcct');	// BLL25a

        // GL Account mapping
        String vendorAcct = '2100';
        String payorAcct = '1100'; //'1110'; BLL15 Just like customerAcct per Michele Swindell 1/22/2016
        String customerAcct = '1100';
        String dftexpacct = 'DONOTUSE';	// BLL25
        Map<String, Id> acctMap = null;

		// BLL6
		GeneralLedgerAccountsSingleton glas = GeneralLedgerAccountsSingleton.getInstance();
		glas.addReportingCodes(new Set<String>{vendorAcct, payorAcct, customerAcct, dftexpacct});
		glas.retrieveGLAccounts();
		// BLL6 end

        Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();

        // Get Vendor record type to set "Vendor" checkbox if it's a vendor account record type
        String vendorName = 'Vendor';
        String payorName = 'Third Party Payor';
        Id vendorRtId;
        Id payorRtId;
        Schema.RecordTypeInfo vendorRtInfo = RcdTypes.get(vendorName);
        if (vendorRtInfo!=null) vendorRtId = vendorRtInfo.getRecordTypeId();
        Schema.RecordTypeInfo payorRtInfo = RcdTypes.get(payorName);
        if (payorRtInfo!=null) payorRtId = payorRtInfo.getRecordTypeId();

		// Had to move back here for now
        Map<String, Id> GLAcctMap = new Map<String, Id>();
        // BLL6
        //for(c2g__codaGeneralLedgerAccount__c gl : [select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c 
        //    where c2g__ReportingCode__c in (:vendorAcct, :payorAcct, :customerAcct, :dftexpacct)]) {	// BLL25c dftexpacct
        //    //BLL25d GLAcctMap.put(gl.c2g__ReportingCode__c, gl.Id);
        //    if (!GLAcctMap.containsKey(gl.c2g__ReportingCode__c)) GLAcctMap.put(gl.c2g__ReportingCode__c, gl.Id);	// BLL25a 
        //}
		Map<String,c2g__codaGeneralLedgerAccount__c> glm = glas.reportingCodeMap;
		if (glm!=null) for(c2g__codaGeneralLedgerAccount__c gl : glm.values()) GLAcctMap.put(gl.c2g__ReportingCode__c, gl.Id);
		// BLL6 end
        
		// Loop through accounts & assign required fields
		for(Account a : newlist) {
			// Set Vendor flag for vendor record types
			//if (vendorRt!=null && a.RecordTypeId==vendorRt.Id) {
			if(a.c2g__CODAAccountTradingCurrency__c==null) { a.c2g__CODAAccountTradingCurrency__c = 'USD'; }
			if(a.c2g__CODABaseDate1__c==null) { a.c2g__CODABaseDate1__c = 'Invoice Date'; }
			if (a.RecordTypeId==vendorRtId) {
				a.dealer__Vendor__c = true;	// DealerTeam required flag for use on a PO
				if (String.isBlank(a.c2g__CODAPaymentMethod__c)) a.c2g__CODAPaymentMethod__c = 'Check'; // BLL10a
				if (a.c2g__CODAAccountsPayableControl__c==null)  a.c2g__CODAAccountsPayableControl__c = GLAcctMap.get(vendorAcct);
				if ((defaultExpAcct==null || defaultExpAcct.Enabled__c==true) && a.c2g__CODADefaultExpenseAccount__c!=null) a.c2g__CODADefaultExpenseAccount__c = GLAcctMap.get('DONOTUSE');	// BLL25a 
				// BLL11c - Set all 3 fields based on whether Description1 is null because others default to 0
				if(a.c2g__CODADescription1__c==null) { 
					a.c2g__CODADescription1__c = 'Net 30 Days'; 
					a.c2g__CODADaysOffset1__c = 30; 
					a.c2g__CODADiscount1__c = 0; 
				}
			} else if (a.RecordTypeId==payorRtId) {
				//a.dealer__Vendor__c = false;  // BLL9a
				if (a.c2g__CODAAccountsReceivableControl__c==null) a.c2g__CODAAccountsReceivableControl__c = GLAcctMap.get(payorAcct);
				if(a.c2g__CODADescription1__c==null) { a.c2g__CODADescription1__c = 'Due on Receipt'; }
				if(a.c2g__CODADaysOffset1__c==null) { a.c2g__CODADaysOffset1__c = 0; }
				// Need this for issuing refunds BLL6a - removed by BLL8!
				//if (a.c2g__CODAAccountsPayableControl__c==null) {
				//  a.c2g__CODAAccountsPayableControl__c = GLAcctMap.get(vendorAcct);
				//}
			} else {
				//a.dealer__Vendor__c = false;  // BLL9a
				if (a.c2g__CODAAccountsReceivableControl__c==null) a.c2g__CODAAccountsReceivableControl__c = GLAcctMap.get(customerAcct);
				if(a.c2g__CODADescription1__c==null) { a.c2g__CODADescription1__c = 'Due on Receipt'; }
				if(a.c2g__CODADaysOffset1__c==null) { a.c2g__CODADaysOffset1__c = 0; }
				// Need this for issuing refunds BLL6a - removed by BLL8
				//if (a.c2g__CODAAccountsPayableControl__c==null) {
				//  a.c2g__CODAAccountsPayableControl__c = GLAcctMap.get(vendorAcct);
				//}
			}
		}	// end for Account a : newlist
		
	}	// end RequiredFieldDefaults
	
	
	
	// DefaultCompanyAssignment
	//------------------------------------------
	public static void DefaultCompanyAssignment(List<Account> newlist) {

        // User's default location code (AKR, CIN, etc) and the Id for that location
        Id defaultLocId = null;
        User u = null;

		// BLL6
		u = CurrentUserSingleton.getInstance();
        LocationsSingleton ls = LocationsSingleton.getInstance();
        ls.addLocationAbbrevs(new List<String>{u.Division});
		ls.retrieveLocations();
		// BLL6 end

        Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();

        // Get Vendor & Payor record types
        String vendorName = 'Vendor';
        String payorName = 'Third Party Payor';
        Id vendorRtId;
        Id payorRtId;
        Schema.RecordTypeInfo vendorRtInfo = RcdTypes.get(vendorName);
        if (vendorRtInfo!=null) vendorRtId = vendorRtInfo.getRecordTypeId();
        Schema.RecordTypeInfo payorRtInfo = RcdTypes.get(payorName);
        if (payorRtInfo!=null) payorRtId = payorRtInfo.getRecordTypeId();
	
		for(Account a : newlist) {

			// Set Default Company Number if missing
			//if(a.Store_Location__c == null && u.Division!=null) {
			//    a.Store_Location__c = u.Division;
			// Only on insert & NOT Vendor or 3rd party payor - BLL 7/21/2015
			if (a.Id==null && a.RecordTypeId!=vendorRtId && a.RecordTypeId!=payorRtId) {
				// BLL27
				//if (a.Store_Location__c==null && u==null) {
				if (a.Store_Location__c==null) {
				// BLL27 end
					// Get User's default location code (AKR, CIN, etc) and the Id for that location
					if (u==null) u = CurrentUserSingleton.getInstance(); //BLL18c [Select Id, Division from User where Id=:UserInfo.getUserId() limit 1];
					System.debug('user id='+u.Id+', division='+u.Division);
					// BLL27
					//if (u != null && u.Division != null) {
					if (u != null && !String.isBlank(u.Division) && defaultLocId==null) {
					// BLL27 end
						//BLL6 
						//List<dealer__Dealer_Location__c> loc = [select Id from dealer__Dealer_Location__c where dealer__Company_Number__c=:u.Division];
						//if (loc.size()>0) defaultLocId = loc[0].Id;
						dealer__Dealer_Location__c loc = ls.getLocationByAbbrev(u.Division);
						if (loc!=null) defaultLocId = loc.Id;
						// BLL6 end
					} 
				//}
					if (a.Store_Location__c == null && defaultLocId != null) {
						a.Store_Location__c = defaultLocId;
					}
				}
			}
		}	// end for
		
	}	// end DefaultCompanyAssignment



	// SyncPersonAccountFields
	//------------------------------------------
	public static void SyncPersonAccountFields(List<Account> newlist, Map<Id,Account> oldmap) {
        
        // For each account being inserted or updated
        // Apply logic & lookups    
        for(Account a : newlist) {

            // BLL12a
            Account oldaccount = null;
            if (oldmap!=null) oldaccount = oldmap.get(a.Id);
            // BLL12a end

            // Set the PersonsAccount details from the new account dialog
            // persons account fields do no match the "Billing" context
            if(a.IsPersonAccount) {

                //BLL20d if(a.PersonMailingStreet==null) {
                // BLL20c set person mailing address to billing address if completely missing
                if(oldAccount==null && a.PersonMailingStreet==null && a.PersonMailingCity==null && a.PersonMailingState==null && a.PersonMailingPostalCode==null) {	// BLL20a
                    a.PersonMailingStreet       =   a.BillingStreet;
                    a.PersonMailingCity         =   a.BillingCity;
                    a.PersonMailingState        =   a.BillingState;
                    a.PersonMailingPostalCode   =   a.BillingPostalCode;
                }
                //BLL4d if (a.PersonHomePhone==null && (oldaccount==null || oldaccount.PersonHomePhone==null)) {    // BLL16c 
				if (oldaccount==null && a.PersonHomePhone==null) { // BLL4a
                    a.PersonHomePhone = a.Phone;
                }   
                //if (a.PersonEmail==null) { 
                //  a.PersonEmail = a.Email;
                //}                 
				// BLL4 - If home phone changed, change copy
				if (oldaccount!=null && oldaccount.PersonHomePhone!=a.PersonHomePhone) {
					a.Phone = a.PersonHomePhone;
				}
				// AMM6				
				if (oldaccount!=null && (oldaccount.PersonMobilePhone !=a.PersonMobilePhone || a.PersonMobilePhone != a.BusinessMobilePhone__c)) {
					a.BusinessMobilePhone__c  = a.PersonMobilePhone;
				}
				if (oldaccount!=null && (oldaccount.PersonOtherPhone !=a.PersonOtherPhone ||  a.BusinessOtherPhone__c != a.PersonOtherPhone)) {
					a.BusinessOtherPhone__c  = a.PersonOtherPhone;
				}
				// AMM6
				// If Phone changed, update Person Home Phone (similar to address updates below)
				if (oldaccount!=null && oldaccount.Phone!=a.Phone) {
					a.PersonHomePhone = a.Phone;
				}
				// BLL4 end                

				// BLL20a Determine if Person mailing address changed & prefer that one if it did
				boolean PersonMailingAddrChange=false;
				if (oldaccount==null) PersonMailingAddrChange = true;	// BLL21a - new account should always copy addr.
				if (oldaccount!=null && (a.PersonMailingStreet!=oldaccount.PersonMailingStreet
					|| a.PersonMailingCity!=oldaccount.PersonMailingCity || a.PersonMailingState!=oldaccount.PersonMailingState
					|| a.PersonMailingPostalCode!=oldaccount.PersonMailingPostalCode)) {
					PersonMailingAddrChange = true;
				}
				boolean BusinessAddrChange=false;
				if (oldaccount!=null && (a.BillingStreet!=oldaccount.BillingStreet
					|| a.BillingCity!=oldaccount.BillingCity || a.BillingState!=oldaccount.BillingState
					|| a.BillingPostalCode!=oldaccount.BillingPostalCode)) {
					BusinessAddrChange = true;
				}
				// BLL20a end
                //BLL20d if(a.PersonMailingStreet!=null) {
                if (PersonMailingAddrChange) {
                    a.BillingStreet = a.PersonMailingStreet;
                    a.BillingCity = a.PersonMailingCity;
                    a.BillingState = a.PersonMailingState;
                    a.BillingPostalCode = a.PersonMailingPostalCode;
                    a.Phone = a.PersonHomePhone;                    
                }
                // BLL20a
                if (BusinessAddrChange) {
                	a.PersonMailingStreet = a.BillingStreet;
                	a.PersonMailingCity = a.BillingCity;
                	a.PersonMailingState = a.BillingState;
                	a.PersonMailingPostalCode = a.BillingPostalCode;
                }
                // BLL20a end
                if (a.PersonHomePhone!=null) { 
                    a.Phone = a.PersonHomePhone;
                }                   
                //if(a.PersonEmail!=null) {
                //  a.Email = a.PersonEmail;
                //}

                // Sync DealerTeam's "individual account" custom fields from native person account fields
                a.dealer__B2CRecord__c = true;
                a.dealer__PersonEmail__c = a.PersonEmail;
                a.dealer__Billing_Email__c = a.PersonEmail;
                a.dealer__EmailOptOut__c = a.PersonHasOptedOutOfEmail;
                a.dealer__PersonBirthDate__c = a.PersonBirthdate;
                a.dealer__PersonsDoNotCall__c = a.PersonDoNotCall;
                a.dealer__Salutation__c = a.Salutation;
                a.dealer__FirstName__c = a.FirstName;
                a.dealer__LastName__c = a.LastName;
                a.dealer__PersonMobilePhone__c = a.PersonMobilePhone;
                a.dealer__PersonContactId__c = null;
            }
            // Other syncing to dealer team's fields
            a.dealer__Tax_ID__c = a.Tax_ID_Number__c;
            
            // BLL12a
            // Do not mail, call or email deceased or out of business
            if (a.Account_Status__c=='Deceased' || a.Account_Status__c=='Out Of Business') {
                if (a.isPersonAccount) {
                    a.PersonDoNotCall = true;
                    a.PersonHasOptedOutOfEmail = true;
                }
                a.dealer__PersonsDoNotCall__c = true;
                a.dealer__EmailOptOut__c = true;
                a.Mail_Opt_Out__c = true;
            }
            // BLL12a end

        } // end for Account a : newlist 
		
	}	// end SyncPersonAccountFields


	// RestrictRecordTypeChanges	
	//------------------------------------------
	public static void RestrictRecordTypeChanges(List<Account> newlist, Map<Id,Account> oldmap) {
		User u;
        Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();
		// BLL24a
		// Business & Commercial accounts
		Schema.RecordTypeInfo MW_BusinessRtInfo = RcdTypes.get('Business Account');
		Schema.RecordTypeInfo MW_CommercialRtInfo = RcdTypes.get('Commercial');
		Id MW_BusinessRt = null;
		Id MW_CommercialRt = null;
		if (MW_BusinessRtInfo!=null) MW_BusinessRt = MW_BusinessRtInfo.getRecordTypeId();
		if (MW_CommercialRtInfo!=null) MW_CommercialRt = MW_CommercialRtInfo.getRecordTypeId();
		// BLL24a end
		
        for(Account a : newlist) {

            // BLL12a
            Account oldaccount = null;
            if (oldmap!=null) oldaccount = oldmap.get(a.Id);

            // BLL24 - restrict changing account record types
            if (oldaccount!=null && a.RecordTypeId!=oldaccount.RecordTypeId	// Record type changed
            	&& ((a.RecordTypeId!=MW_BusinessRt && a.RecordTypeId!=MW_CommercialRt)	// Record types NOT just moving between Bus & Comm
            		|| (oldaccount.RecordTypeId!=MW_BusinessRt && oldaccount.RecordTypeId!=MW_CommercialRt))
            ) {
            	if (u==null) u = CurrentUserSingleton.getInstance();
            	if (u!=null && u.Profile.Name!='System Administrator') a.addError('Contact your system administrator to change the account record type.');
           	}
            // BLL24a end
        }	// end for            
		
	}	// end restrict record type changes
	

	// ClearFieldsOnAddressChange
	//------------------------------------------
	public static void ClearFieldsOnAddressChange(List<Account> newlist, Map<Id,Account> oldmap) {
            
        for(Account a : newlist) {

            // BLL12a
            Account oldaccount = null;
            if (oldmap!=null) oldaccount = oldmap.get(a.Id);

            // BLL19a
            // Clear out Lat/Lng if address changed. 
            // Note test for old value not being blank is to skip re-locate if missing info added but already have lat/lng
            // BLL22c note: Clear out county, lat, lng if addr changed regardless of batch size or user
			if ( oldaccount!=null && (oldaccount.BillingStreet<>a.BillingStreet
				|| (oldaccount.BillingCity<>a.BillingCity && !String.isBlank(oldaccount.BillingCity)) 
				|| (oldaccount.BillingState<>a.BillingState && !String.isBlank(oldaccount.BillingState)) 
				|| (oldaccount.BillingPostalCode<>a.BillingPostalCode && !String.isBlank(oldaccount.BillingPostalCode)) 
				|| (oldaccount.BillingCountry<>a.BillingCountry && !String.isBlank(oldaccount.BillingCountry))
				)
				&& (oldaccount.BillingLatitude==a.BillingLatitude && oldaccount.BillingLongitude==a.BillingLongitude)) {
				a.BillingLatitude = null;
				a.BillingLongitude = null;
				a.PersonMailingCounty__c = null;
			} 
            // BLL19a end
            
        }	// end for
		
	}
	
	// AssignCountyJurisdiction	
	//------------------------------------------
	public static void AssignCountyJurisdiction(List<Account> newlist, Boolean accountCountyEnabled) {
		if (accountCountyEnabled && newlist.size()<5 && !UserInfo.getName().contains('DealerTeam')) {
			List<Id> needCounty = new List<Id>();
			for(Account a : newlist) {
				if (String.isBlank(a.PersonMailingCounty__c) && !String.isBlank(a.BillingStreet) && !String.isBlank(a.BillingCity)
						&& (!String.isBlank(a.BillingState) || !String.isBlank(a.BillingPostalCode))) needCounty.add(a.Id);
			}
			System.debug(needCounty.size());
			if (needCounty.size()>0 && !System.isBatch() && !System.isFuture()) ClosestStoreFuture.Account_LocateAddress(needCounty);
		}
	}

	// MTC29 start
	public static void BuildDefaultDataValuesValidationsSummaries (List<Account> accountsNew, Map<Id, Account> accountsOldMap, Map<String, Boolean> controlFeatures) {
		AccountProcess.AddInfluencerAssociation(accountsNew);
		if (controlFeatures.get('uploadHelperEnabled')){ AccountProcess.UploadReferencesByName(accountsNew);}
		AccountProcess.StandardizePersonName(accountsNew);
		AccountProcess.SynchFFTaxFields(accountsNew, accountsOldMap);
		AccountProcess.RequiredFieldDefaults(accountsNew);
		AccountProcess.AppendNewStockNumber(accountsNew, accountsOldMap);
		if (controlFeatures.get('accountRcdTypeEnabled')){ AccountProcess.SyncPersonAccountFields(accountsNew, accountsOldMap);}
		AccountProcess.ClearFieldsOnAddressChange(accountsNew, accountsOldMap);
		if (controlFeatures.get('accountRLCountsEnabled')){ AccountProcess.RecordRelatedRcdCounts(accountsNew);}
	}

	public static void updateClosestStorePerAccount (List<Account> accounts) {
		List<dealer__Dealer_Location__c> storeLocations = getStoreLocations();
		for(Account account : accounts) {
			setClosestStore(account, storeLocations);
		}
	}

	private static List<dealer__Dealer_Location__c> getStoreLocations () {
		List<dealer__Dealer_Location__c> storeLocationsAll = invokeLocationSingletonToFetchAllLocations();
		List<dealer__Dealer_Location__c> storeLocationsValid = new List<dealer__Dealer_Location__c>();
		for(dealer__Dealer_Location__c loc : storeLocationsAll) {
			if(locationFulfillsBusinessRequirements(loc)) {
				storeLocationsValid.add(loc);
			}
		}
		return storeLocationsValid;
	}

	private static Boolean locationFulfillsBusinessRequirements (dealer__Dealer_Location__c loc) {
		return loc.AutoAssignRetail__c == TRUE && loc.dealer__IsClosed__c == FALSE;
	}

	private static List<dealer__Dealer_Location__c> invokeLocationSingletonToFetchAllLocations() {
		LocationsSingleton locationsSingletonInstance = LocationsSingleton.getInstance();
		locationsSingletonInstance.retrieveAllLocations();
		return locationsSingletonInstance.locationIdMap.values();
	}

	private static void setClosestStore (Account account, List<dealer__Dealer_Location__c> storeLocations) {
		Location accountLocation = Location.newInstance(account.BillingLatitude, account.BillingLongitude);
		account.Closest_Store_Location__c = getClosestStoreId(accountLocation, storeLocations);
	}

	@TestVisible
	private static Id getClosestStoreId(Location accountLocation, List<dealer__Dealer_Location__c> storeLocations) {
		Id closestStoreId = null;
		Double minimumDistance = null;
		for(dealer__Dealer_Location__c storeLocation : storeLocations) {
			Double distance = Location.getDistance(accountLocation, storeLocation.dealer__Physical_Location__c, 'mi');
			if(minimumDistance == null || distance < minimumDistance) {
				minimumDistance = distance;
				closestStoreId = storeLocation.Id;
			}
		}
		return closestStoreId;
	}
	// MTC29 end


//	// AMM7
//	public static void updateChildOpportunitiesCustomerMasterEnabled(List<Account> newlist, Map<Id, Account> oldMap, Map<Id, Account> newMap)
//	{
//		List<Id> listOfAccountIds = new List<Id>();
//
//		Map<Id, Opportunity__c> mapOfOpportunitiesToUpdate = new Map<Id, Opportunity__c>();
//
//		for(Account tempAccount : newList)
//		{            
//			if(oldMap != null &&  
//				oldMap.get(tempAccount.Id) != null && 
//				tempAccount.rstk__Rootstock_Customer__c == true && 
//				oldMap.get(tempAccount.Id).rstk__Rootstock_Customer__c != tempAccount.rstk__Rootstock_Customer__c)
//			{
//				listOfAccountIds.add(tempAccount.Id);
//			}
//		}
//        
//        System.debug(listOfAccountIds);
//        
//        List<Opportunity__c> listOfOpportunities = ([SELECT Id,
//                                                     Account__c,
//                                                     Customer_Master__c,
//                                                     RecordTypeId
//                                                     FROM Opportunity__c 
//                                                     WHERE Account__c IN :listOfAccountIds AND
//                                                     Customer_Master__c = NULL]);
//         
//        for(Opportunity__c tempOpp : listOfOpportunities)
//        {                 
//            if(newMap != null && 
//               newMap.get(tempOpp.Account__c) != null && 
//               newMap.get(tempOpp.Account__c).rstk__Rootstock_Customer__c == true)
//            {
//                tempOpp.RecordTypeId = Schema.SObjectType.Opportunity__c.getRecordTypeInfosByName().get('Sale').getRecordTypeId();
//                tempOpp.Customer_Master__c = newMap.get(tempOpp.Account__c).rstk__Rootstock_Socust__c;
//                mapOfOpportunitiesToUpdate.put(tempOpp.Id, tempOpp);
//            }
//        }
//        
//        update mapOfOpportunitiesToUpdate.values();
//	}
//	// AMM7

}