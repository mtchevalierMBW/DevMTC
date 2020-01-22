/**
 * AccountScheduleControlRecalcAll_TEST
 * Tests: AccountScheduleControlRecalcAll
 * Date: Jul 10, 2017
 * Programmer: Bryan Leaman
 * 
 * 
 */
@isTest
private class AccountScheduleControlRecalcAll_TEST {

	static testMethod void unitTest() {

			AccountScheduleControlRecalcAll ba = new AccountScheduleControlRecalcAll('1', false);
			Database.executeBatch(ba);
		
	}
	
	
	static testMethod void TestCRON() {
		Test.startTest();
		List<String> jobIds = AccountScheduleControlRecalcAll.scheduleMe();
		String firstJobId = jobIds[0];

		// Get the information from the CronTrigger API object
		CronTrigger ct = [
			SELECT Id, CronExpression, TimesTriggered, NextFireTime
        	FROM CronTrigger 
        	WHERE id = :firstJobId
        ];
 
		// Verify the expressions are the same
		System.assertEquals(AccountScheduleControlRecalcAll.CRON_LIST[0], ct.CronExpression);
 
		// Verify the job has not run
		System.assertEquals(0, ct.TimesTriggered);
		
		Test.stopTest();
		
	}
	
}