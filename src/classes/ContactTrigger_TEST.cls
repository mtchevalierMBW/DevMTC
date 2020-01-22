/**
 * ContactTrigger_TEST
 * Tests: ContactTrigger
 * Date: May 2, 2016
 * Programmer: Bryan Leaman
 *
 */
@isTest
private class ContactTrigger_TEST {

	//private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		//TestHelper_MW.createBaseFFAData(FFAdata);
	}

	// unitTest
	//---------------------------------------
	static testMethod void desiredVehiclesTest() {
		//FFAdata.refresh(); 
                        
		//System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();

		Test.startTest();
		Contact c = new Contact(FirstName='AdminTest', LastName='DesiredVehicleTest', Desired_Vehicles__c='12345B');
		insert(c);
		c.Desired_Vehicles__c = 'This is going to be a long vehicle description, so be ready';
		update(c);
		c.Desired_Vehicles__c = '23456C';
		update(c);
		Test.stopTest();
		Contact check_c = [
			select Id, Name, Desired_Vehicles__c 
			from Contact where Id=:c.Id 
			limit 1
		];
		System.assertEquals('12345B; This is going to be a long vehicle description, so be ready; 23456C', 
			check_c.Desired_Vehicles__c, 'Did not properly concatenate desired vehicles on account record');
			
		//}
	}

}