/** Provide a future method so that a trigger can assign the closest mobility store
 * ClosestStoreFuture
 * Tested by: Location_MW_TEST
 * Coverage:
 *	2017-10-30	76% (110/143)
 *	2018-09-07	78%	(118/151)
 * 
 *	2015-07-23  B. Leaman    BLL1 - Only auto-assign stores with new flag set (AutoAssignRetail__c=true)
 * 	2016-10-11	B. Leaman	BLL2 - monitor city/state assignments; Don't append USA by default -- causing issues
 *							where PuertoRico ZIP + USA results in a NJ result. Also only update lead if the result
 * 							appears to be trustworthy (only 1 city/locality matches).
 *	2016-11-07	B. Leaman	BLL3 skip city name "Unknown"
 *	2016-11-14	B. Leaman	BLL4 - enhanced trustworthiness tests for partial matches from google api. Only use these
 *							if either the city+state match or the zip code matches.
 *	2017-07-19	B. Leaman	BLL5 - Always try to assign a lat/lng to the a store, even if Google doesn't like the address very well.
 *	2017-08-01	B. Leaman	BLL6 - improve error notification.
 *	2017-10-30	B. Leaman	BLL7 - improve zip+4 handling.
 *	2018-09-07	B. Leaman 	BLL8 - running geocode routine for more lead types, but don't assign store for TransitWorks.
 */
public with sharing class ClosestStoreFuture {
    //@future
    //public static void AssignLeadClosestStoreGP(List<Id> leadids) {
    //    List<Lead> toUpdate = new List<Lead>();
    //    List<Lead> leads = [select Id, Name, Store_Location__c
    //                        from Lead
    //                        where Id in :leadids];
    //    for(Lead l : leads) {
    //        geopointe.API.radialSearchResult gpresult =
    //                 geopointe.API.radialSearchMapObject(
    //                       l.Id, 'dealer__dealer_location__c', 
    //                       null, 100.0, geopointe.API.units.MILES
    //        );
    //        if (gpresult.recordCount>0) {
    //          l.Store_Location__c = (Id) gpresult.recordsInDistanceOrder[0];
    //          toUpdate.add(l); 
    //        }
    //    }
    //    if (toUpdate.size()>0 || Test.isRunningTest()) {
    //        update(toUpdate);
    //    }
    //}

    // Updates lead with lat/lng,
    // searches for closest store (within 100 miles) and assigns it
    @future(callout=true)
    public static void Lead_LocateAddress(List<Id> leadids) {
    	MonitorExecution mon = new MonitorExecution('Lead_LocateAddress');	// BLLa
    	boolean error = false;	// BLL6a
    	
		// BLL8a
		Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.Lead.getRecordTypeInfosByName();
		Id twRcdId = null;
		for(String k : RcdTypes.keySet()) if (k.startsWith('Transit')) twRcdId = RcdTypes.get(k).getRecordTypeId();
		System.debug('TW record type id='+twRcdId);
		// BLL8a end
    	
        List<Lead> toUpdate = new List<Lead>();
        List<Lead> leads = [select Id, Name, Store_Location__c, RecordTypeId, 	// BLL8c add RecordTypeId
                                   Street, City, State, PostalCode, Country, County__c, 
                                   Latitude, Longitude
                            from Lead 
                            where Id in :leadids];
        for(Lead l : leads) {
            boolean updateLead = false;
            try {	// BLL6a
            if (l.Latitude==null || l.Longitude==null) {
                String address = '';
                if (l.City=='Unknown') l.City = null;	// BLL3a Skip this city name
                if (l.Street <> null) 	address = address + l.Street;
                if (l.City <> null) 	address = address + ' ' + l.City;
                if (l.State <> null) 	address = address + ' ' + l.State;
                if (l.PostalCode <> null) address = address + ' ' + l.PostalCode;
                if (l.Country <> null) address = address + ' ' + l.Country;
                //BLL2d } else {
                //BLL2d     address = address + ' ' + 'USA';
                //BLL2d }
                address = address.trim();
                //BLL2d GeoLocationResult loc = GeoLocationHelper.getAddressLocation(address);
                GeoLocationResult loc = null;	// BLL2a
                // BLL2a - only try to get a geolocation if we have at least a city or a zip code
                if (!String.isBlank(l.City) || !String.isBlank(l.PostalCode)) loc = GeoLocationHelper.getAddressLocation(address);	// BLL2a
                if (loc != null) {
					//BLL7a only trustworthy if specified zip matches return zip  
					System.debug(loc.Trustworthy);	// BLL7a
					Integer zipsize = Math.min((l.PostalCode!=null ? l.PostalCode.length() : 0), (loc.PostalCode!=null ? loc.PostalCode.length() : 0) );
					if (zipsize>=5 && l.PostalCode!=null && loc.PostalCode!=null) loc.Trustworthy = loc.Trustworthy && l.PostalCode.substring(0,zipsize)==loc.PostalCode.substring(0,zipsize);
					System.debug(zipsize);	// BLL7a
					if (zipsize>=5 && l.PostalCode!=null && loc.PostalCode!=null) system.debug(l.PostalCode + ' =? ' + loc.PostalCode); // BLL7a
					System.debug(loc.Trustworthy);	// BLL7a
					// BLL7a end 
					// BLL4a - not a trustworthy result if it's a partial match and either the city+state don't match or the postal code doesn't match
        			System.debug(loc.City + ' ?= ' + l.City);
        			System.debug(loc.StateCode + ' ?= ' + l.State);
                	if (loc.PartialMatch!=null && loc.PartialMatch) {
                		if ((loc.City==l.City && (loc.StateCode==l.State || loc.State==l.State))) {	// BLL7c || (loc.PostalCode!=null && loc.PostalCode.startsWith(l.PostalCode)))  {
                			loc.Trustworthy = loc.Trustworthy && true;
                		} else {
                			loc.Trustworthy = false;
                		}
                	}
					// BLL4a 
                	mon.log('Lead address: ' + address + ' = ' + JSON.serialize(loc));	// BLL2a
                	// BLL4c Only update if city and/or state was specified *or* return zip matches starting zip
                	// Update if city and/or state and/or zip was specified
					updateLead = !String.isBlank(l.City) || !String.isBlank(l.State) || !String.isBlank(l.PostalCode); // BLL7c || l.PostalCode==loc.PostalCode;	// BLL2a
					updateLead = updateLead && loc.Trustworthy;	// BLL2a
                    if (updateLead) l.Latitude = loc.Latitude;		// BLL2c only set lat/lng if we had enough info to get a reliable result
                    if (updateLead) l.Longitude = loc.Longitude;	// BLL2c only set lat/lng if we had enough info to get a reliable result
                    if (String.isBlank(l.City) && !String.isBlank(loc.City)) {
                        l.City = loc.City;
                        System.debug('Assigned city ' + l.City + ' from geo location result');
                    }
                    if (String.isBlank(l.State) && !String.isBlank(loc.StateCode)) {
                        l.State = loc.StateCode;
                        System.debug('Assigned state ' + l.State + ' from geo location result');
                    }
                    //BLL3a
                    if (String.isBlank(l.County__c) && !String.isBlank(loc.County)) {
                        l.County__c = loc.County;
                        System.debug('Assigned county ' + l.County__c + ' from geo location result');
                    }
                    //if (String.isBlank(l.PostalCode) && !String.isBlank(loc.PostalCode)) {
                    //    l.PostalCode = loc.PostalCode;
                    //    System.debug('Assigned postal code ' + l.PostalCode + ' from ' + loc.PostalCode);
                    //}
                    //BLL2d updateLead = true;
                    System.debug('Assigned latitude and longitude');
                } else {
                    System.debug('Could not retrieve location for address: ' + address);
                }
            }
            } catch(Exception e) {	// BLL6a
            	mon.log('EXCEPTION: ' + e.getTypeName() + '; ' + e.getMessage() + '; ' + e.getCause() + '; line ' + String.valueOf(e.getLineNumber()) + ';\n' + e.getStackTraceString());	// BLL6a
            	error = true;	// BLL6a
            }	// BLL6a
            
            // Only assign to a store if null and found location is within 100 miles
            // BLL1a:  and store is auto-assignable (AutoAssignRetail__c=true)
            // BLL8a: and not a transitworks lead
            if (l.Store_Location__c==null && l.RecordTypeId!=twRcdId) {	// BLL8c skip for transitworks
                String sqlstmt = '';
                if (l.Latitude<>null && l.Longitude<>null) {
                    sqlstmt = 'select Id, Name '
                        + 'from dealer__Dealer_Location__c '
                        + 'where AutoAssignRetail__c=true ' 
                        + ' and DISTANCE(dealer__Physical_Location__c, '
                        + 'GEOLOCATION(' + l.Latitude + ', ' + l.Longitude + '), \'mi\') < 100.0 '
                        + 'order by DISTANCE(dealer__Physical_Location__c, ' 
                        + 'GEOLOCATION(' + l.Latitude + ', ' + l.Longitude + '), \'mi\') '
                        + 'limit 1 '; 
                } else {
                    sqlstmt = 'select Id, Name from dealer__Dealer_Location__c where Name=null';  // dummy statement
                    System.debug('Do not have lat/lng to search for closest store');
                }
                dealer__Dealer_Location__c dealer = null;
                try {
                    dealer = database.query(sqlstmt);
                } catch (Exception e) {
	            	mon.log('EXCEPTION: ' + e.getTypeName() + '; ' + e.getMessage() + '; ' + e.getCause() + '; line ' + String.valueOf(e.getLineNumber()) + ';\n' + e.getStackTraceString());	// BLL6a
	            	error = true;	// BLL6a
                    System.debug('Error searching for closest store: ' + e);
                }

                if (dealer<>null) {
                    l.Store_Location__c = dealer.Id;
                    updateLead = true;
                    System.debug('Assigned location ' + dealer.Id + ' to lead ' + l.Id);
                }

            } 
            
            // Update lead if either lat/lng changed or store assigned
			if (updateLead) mon.log('Update Lead: ' + JSON.serialize(l));	// BLL2a
            if (updateLead) toUpdate.add(l);
        }
        
        if (toUpdate.size()>0 || Test.isRunningTest()) {
            try {
               update(toUpdate);
            } catch(Exception e) {
            	mon.log('EXCEPTION: ' + e.getTypeName() + '; ' + e.getMessage() + '; ' + e.getCause() + '; line ' + String.valueOf(e.getLineNumber()) + ';\n' + e.getStackTraceString());	// BLL6a
            	error = true;	// BLL6a
                System.debug('Error in Lead_AssignClosestStore: ' + e);
            }
        }
        
        if (error || mon.AlwaysNotify) mon.notifyAdmin();	// BLL2, BLL6c
        
   }


    // Updates dealer__Dealer_Location__c with lat/lng,
    @future(callout=true)
    public static void Location_AssignLatLng(List<Id> locids) {
        List<dealer__Dealer_Location__c> toUpdate = new List<dealer__Dealer_Location__c>();
        List<dealer__Dealer_Location__c> locs = [
			select Id, Name,  
				dealer__Address__c, dealer__City__c, dealer__State__c,
				dealer__Postal_Code__c, Country__c, 
				dealer__Physical_Location__Latitude__s, dealer__Physical_Location__Longitude__s
				from  dealer__Dealer_Location__c
			where Id in :locids
		];
        
        for(dealer__Dealer_Location__c l : locs) {
            boolean updateLoc = false;
            if (l.dealer__Physical_Location__Latitude__s==null || l.dealer__Physical_Location__Longitude__s==null) {
                String address = '';
                if (l.dealer__City__c=='Unknown') l.dealer__City__c = null;	// BLL3a Skip this city name
                if (l.dealer__Address__c <> null) address = address + l.dealer__Address__c;
                if (l.dealer__City__c <> null) address = address + ' ' + l.dealer__City__c;
                if (l.dealer__State__c <> null) address = address + ' ' + l.dealer__State__c;
                if (l.dealer__Postal_Code__c <> null) address = address + ' ' + l.dealer__Postal_Code__c;
                if (l.Country__c <> null) address = address + ' ' + l.Country__c;
                //BLL3d } else {
                //BLL3d    address = address + ' ' + 'USA';
                address = address.trim();
                GeoLocationResult loc = GeoLocationHelper.getAddressLocation(address);
					//BLL7a only trustworthy if specified zip matches return zip  
					Integer zipsize = Math.min((l.dealer__Postal_Code__c!=null ? l.dealer__Postal_Code__c.length() : 0), (loc.PostalCode!=null ? loc.PostalCode.length() : 0) );
					if (zipsize>=5 && l.dealer__Postal_Code__c!=null && loc.PostalCode!=null) loc.Trustworthy = loc.Trustworthy && l.dealer__Postal_Code__c.substring(0,zipsize)==loc.PostalCode.substring(0,zipsize);
					System.debug(zipsize);	// BLL7a
					if (zipsize>=5 && l.dealer__Postal_Code__c!=null && loc.PostalCode!=null) system.debug(l.dealer__Postal_Code__c + ' =? ' + loc.PostalCode); // BLL7a
					System.debug(loc.Trustworthy);	// BLL7a
					// BLL7a end 
				// BLL4a - not a trustworthy result if it's a partial match and either the city+state don't match or the postal code doesn't match
    			System.debug(loc.City + ' ?= ' + l.dealer__City__c);
    			System.debug(loc.StateCode + ' ?= ' + l.dealer__State__c);
               	if (loc!=null && loc.PartialMatch!=null && loc.PartialMatch) {
               		if ((loc.City==l.dealer__City__c && (loc.StateCode==l.dealer__State__c || loc.State==l.dealer__State__c))) { 	// BLL7c || (loc.PostalCode!=null && loc.PostalCode.startsWith(l.dealer__Postal_Code__c)))  {
               			loc.Trustworthy = loc.Trustworthy && true;
               		} else {
               			loc.Trustworthy = false;
               		}
               	}
				// BLL4a 
                if (loc <> null) { // BLL5c Always try to assign lat/lng on stores!	 && loc.Trustworthy) {	// BLL2c
                    l.dealer__Physical_Location__Latitude__s = loc.Latitude;
                    l.dealer__Physical_Location__Longitude__s = loc.Longitude;
                    updateLoc = true;
                }  
            }
            if (updateLoc) {
                toUpdate.add(l);
            } 
        }
        
        if (toUpdate.size()>0 || Test.isRunningTest()) {
            try {
                update(toUpdate);
            } catch(Exception e) {
                System.debug('Error in Location_AssignLatLng: ' + e);
            }
        }
        
   }


    // Updates account with lat/lng, county
    @future(callout=true)
    public static void Account_LocateAddress(List<Id> acctids) {
    	MonitorExecution mon = new MonitorExecution('Account_LocateAddress');	// BLLa
    	boolean error = false;	// BLL6a

        List<Account> toUpdate = new List<Account>();
        List<Account> accounts = [
            select Id, BillingStreet, BillingCity, BillingState, BillingPostalCode,  
                   BillingLatitude, BillingLongitude, BillingCountry, PersonMailingCounty__c 
            from Account
            where Id in :acctids];
        for(Account a : accounts) {
            boolean updateAcct = false;
            try {	// BLL6a
            if (String.isBlank(a.PersonMailingCounty__c) || a.BillingLatitude==null || a.BillingLongitude==null) {
                String address = '';
                if (a.BillingCity=='Unknown') a.BillingCity = null;	// BLL3a Skip this city name
                if (a.BillingStreet <> null) address = address + a.BillingStreet;
                if (a.BillingCity <> null) address = address + ' ' + a.BillingCity;
                if (a.BillingState <> null) address = address + ' ' + a.BillingState;
                if (a.BillingPostalCode <> null) address = address + ' ' + a.BillingPostalCode;
                if (a.BillingCountry <> null) address = address + ' ' + a.BillingCountry;
                //BLL3d } else {
                //BLL3d     address = address + ' ' + 'USA';
                address = address.trim();
                GeoLocationResult loc = GeoLocationHelper.getAddressLocation(address);
               	mon.log('Account address: ' + address + ' = ' + JSON.serialize(loc));	// BLL2a
					//BLL7a only trustworthy if specified zip matches return zip  
					Integer zipsize = Math.min((a.BillingPostalCode!=null ? a.BillingPostalCode.length() : 0), (loc.PostalCode!=null ? loc.PostalCode.length() : 0) );
					if (zipsize>=5 && a.BillingPostalCode!=null && loc.PostalCode!=null) loc.Trustworthy = loc.Trustworthy && a.BillingPostalCode.substring(0,zipsize)==loc.PostalCode.substring(0,zipsize);
					System.debug(zipsize);	// BLL7a
					if (zipsize>=5 && a.BillingPostalCode!=null && loc.PostalCode!=null) system.debug(a.BillingPostalCode + ' =? ' + loc.PostalCode); // BLL7a
					System.debug(loc.Trustworthy);	// BLL7a
					// BLL7a end 
				// BLL4a - not a trustworthy result if it's a partial match and either the city+state don't match or the postal code doesn't match
    			System.debug(loc.City + ' ?= ' + a.BillingCity);
    			System.debug(loc.StateCode + ' ?= ' + a.BillingState);
               	if (loc!=null && loc.PartialMatch!=null && loc.PartialMatch) {
               		if ((loc.City==a.BillingCity && (loc.StateCode==a.BillingState||loc.State==a.BillingState))) {	// BLL7c  || (loc.PostalCode!=null && a.BillingPostalCode!=null && loc.PostalCode.startsWith(a.BillingPostalCode)))  {
               			loc.Trustworthy = loc.Trustworthy && true;
               		} else {
               			loc.Trustworthy = false;
               		}
               	}
				// BLL4a 
                if (loc!=null && loc.Trustworthy!=null && loc.Trustworthy) {	// BLL2c
                    a.BillingLatitude = loc.Latitude;
                    a.BillingLongitude = loc.Longitude;
                    if (String.isBlank(a.BillingCity) && !String.isBlank(loc.City)) {
                        a.BillingCity = loc.City;
                        System.debug('Assigned city ' + a.BillingCity + ' from geo location result');
                    }
                    if (String.isBlank(a.BillingState) && !String.isBlank(loc.StateCode)) {
                        a.BillingState = loc.StateCode;
                        System.debug('Assigned state ' + a.BillingState + ' from geo location result');
                    }
                    //BLLxa
                    if (String.isBlank(a.PersonMailingCounty__c) && !String.isBlank(loc.County)) {
                        a.PersonMailingCounty__c = loc.County;
                        System.debug('Assigned county ' + a.PersonMailingCounty__c + ' from geo location result');
                    }
                    updateAcct = true;
                    System.debug('Assigned latitude and longitude');
                } else {
                    System.debug('Could not retrieve location for address: ' + address);
                }
            }
            } catch(Exception e) {	// BLL6a
            	mon.log('EXCEPTION: ' + e.getTypeName() + '; ' + e.getMessage() + '; ' + e.getCause() + '; line ' + String.valueOf(e.getLineNumber()) + ';\n' + e.getStackTraceString());	// BLL6a
            	error = true;	// BLL6a
            }	// BLL6a
            
            // Update lead if either lat/lng changed or store assigned
            if (updateAcct) toUpdate.add(a);

        }
        
        if (toUpdate.size()>0 || Test.isRunningTest()) {
            try {
               update(toUpdate);
            } catch(Exception e) {
            	mon.log('EXCEPTION: ' + e.getTypeName() + '; ' + e.getMessage() + '; ' + e.getCause() + '; line ' + String.valueOf(e.getLineNumber()) + ';\n' + e.getStackTraceString());	// BLL6a
            	error = true;	// BLL6a
                System.debug('Error in Account_LocateAddress: ' + e);
            }
        }

        if (error || mon.AlwaysNotify) mon.notifyAdmin();	// BLL6a
        
   }


}