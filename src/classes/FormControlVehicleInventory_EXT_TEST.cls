/**
 * FormControlVehicleInventory_EXT_TEST
 * Tests: FormControlVehicleInventory_EXT
 * Date: May 11, 2017
 * Programmer: Bryan Leaman
 *
 */
@isTest
private class FormControlVehicleInventory_EXT_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        
        // ? create a vehicle inventory record
        
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
		dealer__Vehicle_Inventory__c v = new dealer__Vehicle_Inventory__c(dealer__Store_Location__c=FFAdata.DealerLocation.Id); 
		//[
		//	select Id from dealer__Vehicle_Inventory__c limit 1
		//];
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();

	        ApexPages.StandardController sc = new ApexPages.StandardController(v);
    	    FormControlVehicleInventory_EXT q = new FormControlVehicleInventory_EXT(sc);
						
		}
	}

}