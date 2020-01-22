/**
 * RentalAgreements_MW
 *
 * Sets Customer Pay & ThirdParty Pay amount fields (which are referenced by the posting template)
 * Current rule is 'If there is a third-party payor, they pay the amount due; otherwise the client does.'
 * 
 * The posting template logic already handles changing the referenced account from the client 
 * to another funding source if specified. But third party payors go to a whole different GL acct,
 * so they need their own field value to map.
 *
 * Tested by RentalAgreementMW_EXT_TEST
 * Coverage
 *	2019-12-02	87%	(29/33)
 *
 * Modifications
 *	2018-10-23	B. Leaman	W-000439 & W-000412	BLL1 - protect rentals (except for tax post & commit datetime & last updated info).
 *	2018-12-10	B. Leaman	W-000513 BLL2 - copy rental vehicle to managed field
 *	2019-05-09	B. Leaman	W-000575 BLL3 update total collected amount from cashiering records.
 *	2019-06-13	B. Leaman	W-000707 BLL4 IN00064674 need ability to re-open a rental, fix & repost after manually reversing journal.
 *	2019-06-24	B. Leaman	W-000711 BLL5 - need to be able to split AR for rentals (also changed FFA_RentalDepartment and RentalAgreementMW.cmp & .page)
 *	2019-07-16	B. Leaman	W-000718 BLL6 - unable to enter payments on older RAs
 *	2019-12-02	B. Leaman	W-000733 BLL7 - set owner to location's service reporting user
 * 2019-12-04	B. Leaman	W-000799 BLL28 Count Rentals and store on account.
 */
trigger RentalAgreements_MW on dealer__Rental_Agreements__c (before insert, before update, after insert, after update, after delete) {

	// BLL1 - protect paid rentals (except for tax posting info & last updated & new cshier total collected)
	Set<String> allowedfieldupdates = new Set<String>{'lastmodifieddate','lastmodifiedbyid', 
		'dealer__discount__c', 'dealer__total_payments__c', 'dealer__subtotal__c',	// BLL6a
		'ownerid', // BLL7
		'taxpostdt__c','taxcommitdt__c', 'total_collected__c', 'dealer__total_payments__c', 'dealer__total_mileage_limit__c', 'dealer__discount__c'};
	if (Trigger.isBefore && Trigger.isUpdate) {
		for(dealer__Rental_Agreements__c ra : Trigger.new) {
			dealer__Rental_Agreements__c oldra = Trigger.oldMap!=null && ra.Id!=null ? Trigger.oldMap.get(ra.Id) : null;
			if (oldra!=null && oldra.dealer__Agreement_Status__c=='Paid' && !SObjectChangedFields.OnlyAllowedFieldsChanged(ra, oldra, allowedfieldupdates)) {
				if (!ra.Administrative_update__c) // BLL4a
					ra.addError('Posted (paid) Rental Agreements cannot be edited ('
						+ JSON.serialize(SObjectChangedFields.getChangedFieldList(ra, oldra)) +')');
			}				
		}
				
		CashierProcess.rentalTotalCollected(Trigger.new);	// BLL3a

	}
	// BLL1 end

    if (Trigger.isBefore) {
		// BLL7 - get list of all locations needed
		Set<Id> locIds = new Set<Id>();
    	for(dealer__Rental_Agreements__c ra : Trigger.new) {
			if (ra.Location__c!=null) locIds.add(ra.Location__c);
		}
		LocationsSingleton ls = LocationsSingleton.getInstance();
		ls.addLocationIds(locIds);
		// BLL7 end
    	for(dealer__Rental_Agreements__c ra : Trigger.new) {
			// BLL5
			if (ra.Customer_portion__c==null) ra.Customer_portion__c = 0.00;
			// BLL5 end
	    	// Set customer pay amount & payor pay amount
	    	if (ra.ThirdPartyPayor__c==null && ra.Other_payor__c==null) {
				ra.Customer_portion__c = 0.00;	// BLL5a
	    		ra.dealer__Customer_Pay_Amount__c = ra.Total_Amount_Due__c;
	    		ra.Payor_Pay_Amount__c = 0.00;
	    	} else {
				// BLL5
	    		//ra.dealer__Customer_Pay_Amount__c = 0.00;
	    		//ra.Payor_Pay_Amount__c = ra.Total_Amount_Due__c;
				ra.dealer__Customer_Pay_Amount__c = ra.Customer_portion__c;
				ra.Payor_Pay_Amount__c = ra.Total_Amount_Due__c - ra.dealer__Customer_Pay_Amount__c;
				// BLL5 end
	    	}
			// BLL2 - copy to managed field (managed veh field has incompatible filter for us to use on-screen)
			ra.dealer__Rental_Vehicle__c = ra.Rental_Vehicle__c;
			ra.dealer__Location__c = ra.Location__c;
			// BLL2 end
			// BLL7 - assign owner based on location
			dealer__Dealer_Location__c loc = ls.getLocationById(ra.Location__c);
			if (loc!=null && loc.Service_Reporting_User__c!=null && loc.Service_Reporting_User__c!=ra.OwnerId) {
				ra.OwnerId = loc.Service_Reporting_User__c;
			}
			// BLL7 end
    	}
    }

	// BLL4
	if (Trigger.isBefore && !Trigger.isDelete) {
		for(dealer__Rental_Agreements__c ra : Trigger.new) ra.Administrative_update__c = false;
	}
	// BLL4 end

	// BLL28
	// Update accounts related to paid rentals, this will update the rental count on the account records
	MW_TriggerControls__c accountRLCounts = MW_TriggerControls__c.getInstance('AccountRLCounts'); // BLL28
	if (Trigger.isAfter && (accountRLCounts==null || accountRLCounts.Enabled__c)) {
		Map<Id,Account> updAcctMap = new Map<Id,Account>();
		if (!Trigger.isDelete) {
			for(dealer__Rental_Agreements__c ra : Trigger.new) {
				dealer__Rental_Agreements__c oldra = Trigger.oldMap!=null ? Trigger.oldMap.get(ra.Id) : null;
				if (ra.dealer__Agreement_Status__c=='Paid' && (oldra==null || oldra.dealer__Agreement_Status__c!='Paid')) {
					updAcctMap.put(ra.Account__c, new Account(Id=ra.Account__c));
				}
				if (ra.dealer__Agreement_Status__c=='Paid' && oldra!=null && oldra.Account__c!=ra.Account__c) {
					updAcctMap.put(oldra.Account__c, new Account(Id=oldra.Account__c));
					updAcctMap.put(ra.Account__c, new Account(Id=ra.Account__c));
				}
			}
		}
		if (Trigger.isDelete) {
			for(dealer__Rental_Agreements__c ra : Trigger.old) {
				updAcctMap.put(ra.Account__c, new Account(Id=ra.Account__c));
			}
		}
		if (updAcctMap.size()>0) update(updAcctMap.values());
	}
	// BLL28 end

}