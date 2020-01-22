/**
 * FindClosestStore_TEST
 * Tests: FindClosestStore_CTLR
 * 
 *
 */
@isTest
private class FindClosestStore_TEST {

    static testMethod void unitTest() {
    	TestHelper_MW th = new TestHelper_MW();
    	dealer__Dealer_Location__c loc = th.getDealerLocation('1');
    	loc.dealer__Physical_Location__latitude__s = 40.83;
		loc.dealer__Physical_Location__longitude__s = -81.25;
		update(loc);
        FindClosestStore_CTLR fcs = new FindClosestStore_CTLR();
        fcs.address = 'Akron Ohio';
        fcs.GeoLookup();
        fcs.getLocationsByDistance();
    }
}