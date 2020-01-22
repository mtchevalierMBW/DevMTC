/**
 * VehicleBatchRemovePack_TEST
 * Tests: VehicleBatchRemovePack
 * Date: Oct 10, 2016
 * Programmer: Bryan Leaman
 * 
 * 
 */
@isTest(seeAllData=true)
private class VehicleBatchRemovePack_TEST {

	static testMethod void unitTest() {

			VehicleBatchRemovePack ba = new VehicleBatchRemovePack('1', false);
			Database.executeBatch(ba);
		
	}
	
	
	static testMethod void TestCRON() {
		Test.startTest();
		List<String> jobIds = VehicleBatchRemovePack.scheduleMe();
		String firstJobId = jobIds[0];

		// Get the information from the CronTrigger API object
		CronTrigger ct = [
			SELECT Id, CronExpression, TimesTriggered, NextFireTime
        	FROM CronTrigger 
        	WHERE id = :firstJobId
        ];
 
		// Verify the expressions are the same
		System.assertEquals(VehicleBatchRemovePack.CRON_LIST[0], ct.CronExpression);
 
		// Verify the job has not run
		System.assertEquals(0, ct.TimesTriggered);
		
		Test.stopTest();
		
	}
	
}