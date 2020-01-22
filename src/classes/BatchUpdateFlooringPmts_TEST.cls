/**
 * BatchUpdateFlooringPmts_TEST
 * Tests: BatchUpdateFlooringPmts
 * Date: Mar 14, 2018
 * Programmer: Bryan Leaman
 * 
 * 
 */
@isTest
private class BatchUpdateFlooringPmts_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	private static void setupTestData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		//FFAdata.refresh(); 
		//System.runAs(FFAdata.TestUser) {
	        dealer__Vehicle_Inventory__c veh = new dealer__Vehicle_Inventory__c(
	        	dealer__Year__c='2021', dealer__Make__c='Unknown', dealer__Model__c='Futuristic',
	        	dealer__VIN__c='12345698765ABCZYX', dealer__Stock_Number__c='ABCZYX',
	        	Chassis_Floorplan__c='Huntington Used', Floorplanned__c=true, Paid__c=false,
	        	Original_Floored_Amount__c=10000, Chassis_Floored_Date__c=Date.today().addDays(-180), 
	        	dealer__Store_Location__c=FFAdata.DealerLocation.Id 
	        );
	        insert(veh);

		//}
	}


	static testMethod void unitTest() {

		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			BatchUpdateFlooringPmts ba = new BatchUpdateFlooringPmts('1', false);
			Database.executeBatch(ba);
		}
		
	}
	
	
	static testMethod void TestCRON() {
		Test.startTest();
		List<String> jobIds = BatchUpdateFlooringPmts.scheduleMe();
		String firstJobId = jobIds[0];

		// Get the information from the CronTrigger API object
		CronTrigger ct = [
			SELECT Id, CronExpression, TimesTriggered, NextFireTime
        	FROM CronTrigger 
        	WHERE id = :firstJobId
        ];
 
		// Verify the expressions are the same
		System.assertEquals(BatchUpdateFlooringPmts.CRON_LIST[0], ct.CronExpression);
 
		// Verify the job has not run
		System.assertEquals(0, ct.TimesTriggered);
		
		Test.stopTest();
		
	}
	
}