/**
 * BatchRunTests_TEST
 * Tests: BatchRunTests_TEST
 * Date: Mar 15, 2018
 * Programmer: Bryan Leaman
 * 
 * 
 */
@isTest
private class BatchRunTests_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	private static void setupTestData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		//FFAdata.refresh(); 
		//System.runAs(FFAdata.TestUser) {
		//}
	}


	static testMethod void unitTest() {

		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			BatchRunTests ba = new BatchRunTests('1', false);
			Database.executeBatch(ba);
		}
		
	}
	
	
	static testMethod void TestCRON() {
		Test.startTest();
		List<String> jobIds = BatchRunTests.scheduleMe();
		String firstJobId = jobIds[0];

		// Get the information from the CronTrigger API object
		CronTrigger ct = [
			SELECT Id, CronExpression, TimesTriggered, NextFireTime
        	FROM CronTrigger 
        	WHERE id = :firstJobId
        ];
 
		// Verify the expressions are the same
		System.assertEquals(BatchRunTests.CRON_LIST[0], ct.CronExpression);
 
		// Verify the job has not run
		System.assertEquals(0, ct.TimesTriggered);
		
		Test.stopTest();
		
	}
	
}