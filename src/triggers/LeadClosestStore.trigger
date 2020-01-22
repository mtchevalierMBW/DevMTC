/**
 * LeadClosestStore
 * Tested by: Location_MW_TEST
 * 
 * Uses MW_TriggerControls__c custom list settings for:
 * LeadClearLatLng, LeadClosestStore
 * 
 *	2016-04-25	B. Leaman	Don't run future method to assign lat/lng & store if there are 
 *							25 or more records in the trigger. (Arbitrary # to skip large data loads.)
 *	2016-09-21	B. Leaman	BLL2 - Don't run geolocation for larger batches of updates or if user is DealerTeam,
 *							because the Pardot connector runs as DealerTeam and we don't want mass updates when
 *							Pardot syncs (they come as batches of 1 record, so batch size limit doesn't help).
 *	2016-09-23	B. Leaman	BLL3 - Always try to locate the closest store if it's missing, don't skip if it's DealerTeam
 *							since that's how leads come in from Pardot.
 *	2016-11-01	B. Leaman	BLL4 - Get better at re-setting lat/lng.
 *	2018-09-07	B. Leaman	BLL5 - Also for commercial leads (for city/state auto-populate).
 */
trigger LeadClosestStore on Lead (before update, after insert, after update) {

    System.debug('LeadClosestStore invoked for ' + String.valueOf(Trigger.new.size()) + ' records');
 
    // Before updates!
    // 1. Clear out geolocation if address changed and Lat/Lng did not
    if (Trigger.isBefore && Trigger.isUpdate) {
        MW_TriggerControls__c clearLatLng = MW_TriggerControls__c.getInstance('LeadClearLatLng');
        if (clearLatLng==null || clearLatLng.Enabled__c) {
    	    for(Lead newlead : Trigger.new) {
   		        Lead oldlead = Trigger.oldMap.get(newlead.Id);
   		        System.debug('Lead record type was ' + oldlead.RecordTypeId + '; now is ' + newlead.RecordTypeId);
   		        // Remove latitude/longitude
   		        if ( (oldlead.Street<>newlead.Street
   		              || (oldlead.City<>newlead.City) //BLL4d && !String.isBlank(oldlead.City)) 
   		              || (oldlead.State<>newlead.State) //BLL4d && !String.isBlank(oldlead.State)) 
   		              || (oldlead.PostalCode<>newlead.PostalCode) //BLL4d && !String.isBlank(oldlead.PostalCode)) 
   		              || (oldlead.Country<>newlead.Country) //BLL4d && !String.isBlank(oldlead.Country))
   		             )
   		            && (oldlead.Latitude==newlead.Latitude && oldlead.Longitude==newlead.Longitude)) {
   		            newlead.Latitude = null;
   		            newlead.Longitude = null;
   		            //System.debug('Before: Address changed -- Reset lat/lng');
   		        } 
    	    }
        } // if trigger function enabled    	
    }

    // After insert or update:
    // 1. Find closest store for retail leads    
    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {

        MW_TriggerControls__c closestStore = MW_TriggerControls__c.getInstance('LeadClosestStore');
        if ((closestStore==null || closestStore.Enabled__c) && Trigger.new.size()<5) {	// BLL3c rmv Test for DealerTeam

            List<Id> findStoreFor = new List<Id>(); 

	        //RecordType rt = [select Id from RecordType where SObjectType='Lead' and Name like 'Retail%' limit 1];
	        //Id retailRcd = rt.Id;
	        Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.Lead.getRecordTypeInfosByName();
	        Id retailRcd = RcdTypes.get('Retail').getRecordTypeId();
	        System.debug('Retail record type id='+retailRcd);
			// BLL5a
	        Id twRcdId = null;
	        for(String k : RcdTypes.keySet()) if (k.startsWith('Transit')) twRcdId = RcdTypes.get(k).getRecordTypeId();
	        // BLL5a end
	        
	        // New Leads need to have the closest store assigned 
	        if (Trigger.isInsert && Trigger.isAfter) {
	            for(Lead newlead:Trigger.new) {
	            	System.debug('Lead record type id='+newlead.RecordTypeId);
	    		    /* BLL5d if (newlead.Store_Location__c==null && newlead.RecordTypeId==retailRcd */
	    		    if (newlead.Store_Location__c==null && newlead.RecordTypeId!=twRcdId	// BLL5a
	    		        && (newlead.PostalCode <> null || newlead.City<>null || newlead.State<>null)) {
	    	            findStoreFor.add(newlead.Id);
	                    System.debug('Find store for new Lead: '+newlead.Id);
	    		    } 
	    		    // BLL5a TransitWorks leads with city, state or zip, but with one or more missing...
	    		    // TW leads don't fill in the closest store, but could have other addr info filled in automatically
	    		    if (newLead.RecordTypeId==twRcdId  
	    		    	&& (newlead.PostalCode<>null || newlead.City<>null || newlead.State<>null)
	    		    	&& (newlead.PostalCode==null || newlead.City==null || newlead.State==null)) {
	    		    	findStoreFor.add(newlead.Id);
    		    	}
    		    	// BLL5a end
	    	    } 
	        }
	
	        // Only update the closest store if the city/state/zip changed 
	        // *and* location is still null! (Don't move a client from their assigned store automatically)
	        if (Trigger.isAfter && Trigger.isUpdate) {
	    	    for(Lead newlead : Trigger.new) {
	            	System.debug('Lead record type id='+newlead.RecordTypeId);
	    		    if (/*newlead.Store_Location__c==null &&*/ /*BLL5d newlead.RecordTypeId==retailRcd && */	// BLL4c get Lat/Lng whether or not location is set  
	    		        (newlead.PostalCode <> null || newlead.City<>null || newlead.State<>null )) {
	    		        //BLL3dLead oldlead = Trigger.oldMap.get(newlead.Id);
	
	                    //BLL3d if (oldlead.City <> newlead.City || oldlead.State <> newlead.State 
	    		        //BLL3d     || oldlead.PostalCode <> newlead.PostalCode || oldlead.RecordTypeId <> newlead.RecordTypeId) {
	    		        if (newlead.Latitude == null || newlead.Longitude == null || (newlead.Store_Location__c==null&& newlead.RecordTypeId!=twRcdId)) {	// BLL3a - always try if missing lat/lng, BLL4c or store, BLL5c only check missing store if NOT TransitWorks
	                        findStoreFor.add(newlead.Id);
	                        System.debug('Find store for changed Lead: '+newlead.Id);
	    		        } 
	    		    } 
	    	    } 
	        } 
	
	        // Find the closest store (in the future) for all leads needing it
	        //System.debug('Number of leads to find stores for = ' + findStoreFor.size());
	        if (!System.isBatch() && !System.isFuture() && (findStoreFor.size()>0 || Test.isRunningTest())) {
	        	System.debug('ClosestStoreFuture.Lead_LocateAddress invoked');
	    	    ClosestStoreFuture.Lead_LocateAddress(findStoreFor);
	        }
        } // closestStore enabled
        
    } // isAfter and (isInsert or isUpdate)
    
}