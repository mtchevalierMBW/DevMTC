/**
 * BatchPurgeTasks_TEST
 * Tests: BatchPurgeTasks
 * Date: Oct 17, 2017
 * Programmer: Bryan Leaman
 * 
 * 
 */
@isTest
private class BatchPurgeTasks_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	private static void setupTestData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		
		System.runAs(FFAdata.TestUser) {

		}
	}


	static testMethod void unitTest() {

			BatchPurgeTasks ba = new BatchPurgeTasks(0, null, '1', false);
			Database.executeBatch(ba);
		
	}
	
	
	static testMethod void TestCRON() {
		Test.startTest();
		List<String> jobIds = BatchPurgeTasks.scheduleMe();
		String firstJobId = jobIds[0];

		// Get the information from the CronTrigger API object
		CronTrigger ct = [
			SELECT Id, CronExpression, TimesTriggered, NextFireTime
        	FROM CronTrigger 
        	WHERE id = :firstJobId
        ];
 
		// Verify the expressions are the same
		System.assertEquals(BatchPurgeTasks.CRON_LIST[0], ct.CronExpression);
 
		// Verify the job has not run
		System.assertEquals(0, ct.TimesTriggered);
		
		Test.stopTest();
		
	}
	
}