/**
 * LocationsSingleton
 * Tested by: AccountManagement_TEST, FFATests, VehicleTransfer_TEST
 * Date: Jan 2, 2018
 * Programmer: Bryan Leaman
 *
 * Code Coverage:
 *  2018-01-03  86% (38/44)
 *  2020-01-24  83%  (76/91)
 *  2020-01-28	90%	(71/79)
 *
 *  2018-01-24  B. Leaman  BLL1 - new routine for finding by name; reduce code size by re-using set routines for lists;
 *  2019-04-12  B. Leaman  W-000575 BLL2 - reduce soqls in test methods
 *  2020-01-24  B. Leaman  W-000813 BLL3 - Fix potential flaw in RetrieveAllLocations logic when used in a trigger context.
 *  2020-01-28	M. Chevalier W-000813 MTC4 - Ported queries out to DealerLocationDA.cls
 */
public with sharing class LocationsSingleton {

	private static DealerLocationDAInterface dealerLocationDA; // MTC4

	public static LocationsSingleton ls;
	public Set<Id> locationIds;
	public Set<String> locationAbbrevs;
	public Set<String> locationNames;  // BLL1a
	public Map<Id,dealer__Dealer_Location__c> locationIdMap;
	public Map<String,dealer__Dealer_Location__c> locationAbbrevMap;
	public Map<String,dealer__Dealer_Location__c> locationNameMap;
	// BLL3
	public static boolean AllLocationsRetrieved = false;
	// BLL3

	// LocationsSingleton
	//---------------------------------------
	public LocationsSingleton() {
		locationIds = new Set<Id>();
		locationAbbrevs = new Set<String>();
		locationNames = new Set<String>();
		// MTC4
		if(Test.isRunningTest()) {
			dealerLocationDA = new DealerLocationDAMock();
		} else {
			dealerLocationDA = new DealerLocationDA();
		}
		// MTC4
	}

	public static LocationsSingleton getInstance() {
		if (ls==null) ls = new LocationsSingleton();
		return ls;
	}

	public void addLocationIds(List<Id> ids) {
		addLocationIds(new Set<Id>(ids));  // BLL1a
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
		addLocationAbbrevs(new Set<String>(abbrevs));  // BLL1a
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
	private Boolean queryFilterCriteriaIsEmpty(){
		return locationIds.isEmpty() && locationAbbrevs.isEmpty() && locationNames.isEmpty();
	}

	public void retrieveLocations() {
		System.debug('retrieveLocations');
		System.debug(locationIds);
		System.debug(locationAbbrevs);
		if (locationIdMap==null) {
			// MTC4
			List<dealer__Dealer_Location__c> loclist;
			if(queryFilterCriteriaIsEmpty()) {
				loclist = dealerLocationDA.getAllLocations();
			} else {
				loclist = dealerLocationDA.getConditionallyFilteredLocations(locationIds, locationAbbrevs, locationNames);

			}
			// MTC4
			System.debug(loclist);
			locationIdMap = new Map<Id,dealer__Dealer_Location__c>();
			locationAbbrevMap = new Map<String,dealer__Dealer_Location__c>();
			locationNameMap = new Map<String,dealer__Dealer_Location__c>();  // BLL1a
			for(dealer__Dealer_Location__c dl : locList) {
				locationIdMap.put(dl.Id, dl);
				locationAbbrevMap.put(dl.dealer__Company_Number__c, dl);
				locationNameMap.put(dl.Name.toLowerCase(), dl);  // BLL1a
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
		// BLL3
		//if (locationIdMap==null) {
		if (AllLocationsRetrieved==false) {
			// BLL3 end
			// MTC4
			List<dealer__Dealer_Location__c> loclist = dealerLocationDA.getAllNonClosedLocations();
			// MTC4
			locationIdMap = new Map<Id,dealer__Dealer_Location__c>();
			locationAbbrevMap = new Map<String,dealer__Dealer_Location__c>();
			locationNameMap = new Map<String,dealer__Dealer_Location__c>();  // BLL1a
			for(dealer__Dealer_Location__c dl : locList) {
				locationIdMap.put(dl.Id, dl);
				locationAbbrevMap.put(dl.dealer__Company_Number__c, dl);
				locationNameMap.put(dl.Name.toLowerCase(), dl);  // BLL1a
			}
			locationIds.addAll(locationIdMap.keySet());
			locationAbbrevs.addAll(locationAbbrevMap.keySet());
			locationNames.addAll(locationNameMap.keySet());
			// BLL3
			AllLocationsRetrieved = true;
			// BLL3 end
		}
	}
	// BLL2 end

	public dealer__Dealer_Location__c getLocationById(Id locid) {
		if (locationIdMap==null) retrieveLocations();
		System.debug(locid); System.debug(locationIdMap.get(locid));
		return locationIdMap.get(locid);
	}

	public dealer__Dealer_Location__c getLocationByAbbrev(String abbrev) {
		if (locationIdMap==null) retrieveLocations();  // the id map controls whether retrieval has run & is up-to-date
		System.debug(abbrev); System.debug(locationAbbrevMap.get(abbrev));
		return locationAbbrevMap.get(abbrev);
	}

	// BLL1a
	public dealer__Dealer_Location__c getLocationByName(String locname) {
		if (locname!=null) locname = locname.toLowerCase();
		if (locationIdMap==null) retrieveLocations();  // the id map controls whether retrieval has run & is up-to-date
		System.debug(locname); System.debug(locationNameMap.get(locname));
		return locationNameMap.get(locname);
	}
	// BLL1a end

}