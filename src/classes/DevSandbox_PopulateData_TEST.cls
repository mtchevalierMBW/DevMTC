/**
 * DevSandbox_PopulateData_TEST
 * Tests: DevSandbox_PopulateData
 * Date: Sep 26, 2017
 * Programmer: Bryan Leaman
 * 
 * 
 */
@isTest
private class DevSandbox_PopulateData_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	private static void setupTestData() {
		//TestHelper_MW.createBaseFFAData(FFAdata);
		//System.runAs(FFAdata.TestUser) {
		//}
	}


	static testMethod void unitTest() {
		//FFAdata.refresh(); 
		//System.runAs(FFAdata.TestUser) {
		//	TestHelper_MW th = new TestHelper_MW();
		
			MW_TriggerControls__c DevPopulateData = new MW_TriggerControls__c(Name='DevPopulateData',Enabled__c=true);
			insert(DevPopulateData);

			DevSandbox_PopulateData ba = new DevSandbox_PopulateData('devSandboxSampleData', false);
			Test.startTest();
			Database.executeBatch(ba);
			Test.stopTest();
			
		//}
	}
	
}