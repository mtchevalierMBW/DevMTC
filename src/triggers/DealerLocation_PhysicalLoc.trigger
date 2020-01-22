/**
 * DealerLocation_PhysicalLoc
 * Tested by: Location_MW_TEST
 * Programmer: Bryan Leaman
 * Date: 2015-04-28
 *
 * 	2016-01-29	B. Leaman	BLL1	Add ability to disable (during CustomInvoice_TC)
 *	2016-05-16	B. Leaman	BLL2	Try/catch around future method - just ignore, but log in debug log.
 *	2019-08-02	B. Leaman	BLL3 	Clear out physical location lat/lng if address is changed.
 */
trigger DealerLocation_PhysicalLoc on dealer__Dealer_Location__c (after insert, before update, after update) {

	// BLL3
	// Before insert - clear out lat/lng if the address changed
	if (Trigger.isBefore && Trigger.isUpdate) {
		for(dealer__Dealer_Location__c newloc : Trigger.new) {
			if (newloc.dealer__Postal_Code__c <> null || newloc.dealer__City__c<>null || newloc.dealer__State__c<>null ) {
				dealer__Dealer_Location__c oldloc = Trigger.oldMap.get(newloc.Id);
				if (oldloc!=null && 
					(oldloc.dealer__Address__c <> newloc.dealer__Address__c  
					|| oldloc.dealer__City__c <> newloc.dealer__City__c
					|| oldloc.dealer__State__c <> newloc.dealer__State__c 
					|| oldloc.dealer__Postal_Code__c <> newloc.dealer__Postal_Code__c )) {
					newloc.dealer__Physical_Location__Latitude__s = null;
					newloc.dealer__Physical_Location__Longitude__s = null;
				} 
			} 
		} 
	}
	// BLL3 end

    // After insert or update:
    // 1. Find closest store for retail leads    
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        List<Id> findLatLngFor = new List<Id>(); 

        // New Leads need to have the closest store assigned 
        if (Trigger.isInsert && Trigger.isAfter) {
            for(dealer__Dealer_Location__c newloc : Trigger.new) {
  	            findLatLngFor.add(newloc.Id);
    	    } 
        }
    
        // Only update the closest store if the city/state/zip changed 
        // *and* location is still null! (Don't move a client from their assigned store automatically)
        if (Trigger.isUpdate && Trigger.isAfter) {
    	    for(dealer__Dealer_Location__c newloc : Trigger.new) {
    		    if (newloc.dealer__Postal_Code__c <> null || newloc.dealer__City__c<>null || newloc.dealer__State__c<>null ) {
                    if (newloc.dealer__Physical_Location__Latitude__s==null 
						|| newloc.dealer__Physical_Location__Longitude__s==null) {
                        findLatLngFor.add(newloc.Id);
    		        } 
    		    } 
    	    } 
        } 

        // Find the closest store (in the future) for all leads needing it
        MW_TriggerControls__c DealerLocationLatLng = MW_TriggerControls__c.getInstance('DealerLocationLatLng');
        if (DealerLocationLatLng==null || DealerLocationLatLng.Enabled__c) {
        	if (findLatLngFor.size()>0 || Test.isRunningTest()) {
        		System.debug(findLatLngFor.size());
        		try { // BLL2a
    		    ClosestStoreFuture.Location_AssignLatLng(findLatLngFor);
        		} catch(Exception e) {System.debug('Cannot assign Lat/Lng: '+e.getMessage());}	// BLL2a
        	}
        }
    }

}