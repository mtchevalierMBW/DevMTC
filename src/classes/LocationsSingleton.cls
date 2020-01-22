/**
 * LocationsSingleton
 * Tested by: VehicleUnitTest, AccountManagement_TEST	// ? LocationsSingleton_TEST
 * Date: Jan 2, 2018
 * Programmer: Bryan Leaman
 *
 * Code Coverage:
 *	2018-01-03	86% (38/44)
 * 
 *	2018-01-24	B. Leaman	BLL1 - new routine for finding by name; reduce code size by re-using set routines for lists;	
 *	2019-04-12	B. Leaman	W-000575 BLL2 - reduce soqls in test methods
 */
public with sharing class LocationsSingleton {

	public static LocationsSingleton ls;
	public Set<Id> locationIds;
	public Set<String> locationAbbrevs;
	public Set<String> locationNames;	// BLL1a
	public Map<Id,dealer__Dealer_Location__c> locationIdMap;
	public Map<String,dealer__Dealer_Location__c> locationAbbrevMap;
	public Map<String,dealer__Dealer_Location__c> locationNameMap;

	// LocationsSingleton
	//---------------------------------------
	public LocationsSingleton() {
		locationIds = new Set<Id>();
		locationAbbrevs = new Set<String>();
		locationNames = new Set<String>();
	}
	
	public static LocationsSingleton getInstance() {
		if (ls==null) ls = new LocationsSingleton();
		return ls;
	}

	public void addLocationIds(List<Id> ids) {
		addLocationIds(new Set<Id>(ids));	// BLL1a
		//System.debug(ids);
		//if (locationIdMap!=null && !locationIdMap.keySet().containsAll(ids)) locationIdMap=null;
		//locationIds.addAll(ids);
		//System.debug(locationIdMap);
		//System.debug(locationIds);
	}

	public void addLocationIds(Set<Id> ids) {
		System.debug(ids);
		if (locationIdMap!=null && !locationIdMap.keySet().containsAll(ids)) locationIdMap=null;
		locationIds.addAll(ids);
		System.debug(locationIdMap);
		System.debug(locationIds);
	}
	
	public void addLocationAbbrevs(List<String> abbrevs) {
		addLocationAbbrevs(new Set<String>(abbrevs));	// BLL1a
		//System.debug(abbrevs);
		//if (locationAbbrevMap!=null && !locationAbbrevMap.keySet().containsAll(abbrevs)) locationIdMap = null;
		//locationAbbrevs.addAll(abbrevs);
		//System.debug(locationIdMap);
		//System.debug(locationAbbrevs);
	}
	
	public void addLocationAbbrevs(Set<String> abbrevs) {
		System.debug(abbrevs);
		if (locationAbbrevMap!=null && !locationAbbrevMap.keySet().containsAll(abbrevs)) locationIdMap = null;
		locationAbbrevs.addAll(abbrevs);
		System.debug(locationIdMap);
		System.debug(locationAbbrevs);
	}

	// BLL1a
	public void addLocationNames(List<String> names) {
		addLocationNames(new Set<String>(names));
	}
	
	public void addLocationNames(Set<String> names) {
		System.debug(names);
		Set<String> nameslc = new Set<String>();
		for(String n : names) nameslc.add(n.toLowerCase());
		if (locationNameMap!=null && !locationNameMap.keySet().containsAll(nameslc)) locationIdMap = null;
		locationNames.addAll(nameslc);
		System.debug(locationIdMap);
		System.debug(locationNames);
	}
	// BLL1a end

	public void retrieveLocations() {
		System.debug('retrieveLocations');
		System.debug(locationIds);
		System.debug(locationAbbrevs);
		if (locationIdMap==null) {
	   		// Select all fields from dealer__Dealer_Location__c
			Map<String, Schema.SObjectField> dlFieldMap =  Schema.dealer__Dealer_Location__c.SObjectType.getDescribe().fields.getMap();
			List<String> dlFieldList = new List<String>();
			for(string f : dlFieldMap.keySet()) /* if (trsFieldMap.get(f).getDescribe().isAccessible()) */ dlFieldList.add(f);
			String dlfields = String.join(dlFieldList,',');

			String soql = 'select ' + dlfields + ' from dealer__Dealer_Location__c ';
			String junct = ' WHERE ';
			if (locationIds.size()>0) {
				System.debug(locationIds);
				soql += junct + ' Id in :locationIds ';
				junct = ' or ';
			}
			if (locationAbbrevs.size()>0) {
				System.debug(locationAbbrevs);
				soql += junct + ' dealer__Company_Number__c in :locationAbbrevs ';
				junct = ' or ';
			}
			// BLL1a
			if (locationNames.size()>0) {
				System.debug(locationNames);
				soql += junct + ' Name in :locationNames ';
				junct = ' or ';
			}
			// BLL1a end
			System.debug('retrieveLocations: (soql) ' + soql);
			List<dealer__Dealer_Location__c> loclist = Database.query(soql);
			System.debug(loclist);
			locationIdMap = new Map<Id,dealer__Dealer_Location__c>();
			locationAbbrevMap = new Map<String,dealer__Dealer_Location__c>();
			locationNameMap = new Map<String,dealer__Dealer_Location__c>();	// BLL1a
			for(dealer__Dealer_Location__c dl : locList) { 
				locationIdMap.put(dl.Id, dl);
				locationAbbrevMap.put(dl.dealer__Company_Number__c, dl);
				locationNameMap.put(dl.Name.toLowerCase(), dl);	// BLL1a
			} 
			// BLL2 - if requested name, id or abbrev is NOT in the results, store it as a null location to 
			// prevent re-querying for same missing location later in the request cycle.
			for(String k : locationNames) {
				if (!locationNameMap.containsKey(k)) 
					locationNameMap.put(k.toLowerCase(), null);
			}
			for(String k : locationAbbrevs) {
				if (!locationAbbrevMap.containsKey(k)) 
					locationAbbrevMap.put(k, null);
			}
			for(String k : locationIds) {
				if (!locationIdMap.containsKey(k)) 
					locationIdMap.put(k, null);
			}
			// BLL2 end
			// BLL1a - ensure Id, Abbrev & Name sets contain all entries so future invocation knows they've been retrieved
			locationIds.addAll(locationIdMap.keySet());
			locationAbbrevs.addAll(locationAbbrevMap.keySet());
			locationNames.addAll(locationNameMap.keySet());
			System.debug(locationIdMap);
			System.debug(locationAbbrevMap);
			System.debug(locationNameMap);
			// BLL1a end
		}
	}

	// BLL2
	public void retrieveAllLocations() {
		System.debug('retrieveAllLocations');
		if (locationIdMap==null) {
	   		// Select all fields from dealer__Dealer_Location__c
			Map<String, Schema.SObjectField> dlFieldMap =  Schema.dealer__Dealer_Location__c.SObjectType.getDescribe().fields.getMap();
			List<String> dlFieldList = new List<String>();
			for(string f : dlFieldMap.keySet()) /* if (trsFieldMap.get(f).getDescribe().isAccessible()) */ dlFieldList.add(f);
			String dlfields = String.join(dlFieldList,',');

			String soql = 'select ' + dlfields + ' from dealer__Dealer_Location__c ';
			System.debug('retrieveLocations: (soql) ' + soql);
			List<dealer__Dealer_Location__c> loclist = Database.query(soql);
			locationIdMap = new Map<Id,dealer__Dealer_Location__c>();
			locationAbbrevMap = new Map<String,dealer__Dealer_Location__c>();
			locationNameMap = new Map<String,dealer__Dealer_Location__c>();	// BLL1a
			for(dealer__Dealer_Location__c dl : locList) { 
				locationIdMap.put(dl.Id, dl);
				locationAbbrevMap.put(dl.dealer__Company_Number__c, dl);
				locationNameMap.put(dl.Name.toLowerCase(), dl);	// BLL1a
			} 
			locationIds.addAll(locationIdMap.keySet());
			locationAbbrevs.addAll(locationAbbrevMap.keySet());
			locationNames.addAll(locationNameMap.keySet());
		}
	}
	// BLL2 end

	public dealer__Dealer_Location__c getLocationById(Id locid) {
		if (locationIdMap==null) retrieveLocations();
		System.debug(locid); System.debug(locationIdMap.get(locid));
		return locationIdMap.get(locid);
	}

	public dealer__Dealer_Location__c getLocationByAbbrev(String abbrev) {
		if (locationIdMap==null) retrieveLocations();	// the id map controls whether retrieval has run & is up-to-date 
		System.debug(abbrev); System.debug(locationAbbrevMap.get(abbrev));
		return locationAbbrevMap.get(abbrev);
	}

	// BLL1a
	public dealer__Dealer_Location__c getLocationByName(String locname) {
		if (locname!=null) locname = locname.toLowerCase();
		if (locationIdMap==null) retrieveLocations();	// the id map controls whether retrieval has run & is up-to-date 
		System.debug(locname); System.debug(locationNameMap.get(locname));
		return locationNameMap.get(locname);
	}
	// BLL1a end

}