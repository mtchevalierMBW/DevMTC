/**
 * BatchReprocessAsyncFFSchedule_TEST
 * Tests: BatchReprocessAsyncFFSchedule_TEST
 * Date: Sep 26, 2016
 * Programmer: Bryan Leaman
 * 
 * 
 */
@isTest
private class BatchReprocessAsyncFFSchedule_TEST {

	static testMethod void unitTest() {
		Test.startTest();
		//BatchReprocessAsyncFFSchedule m = new BatchReprocessAsyncFFSchedule();
		//String sched = BatchReprocessAsyncFFSchedule.CRON_EXP; // Daily at 12:05:00 a.m. GMT (8:05 p.m. EST))
		//String jobID = system.schedule('BatchReprocessAsyncFFSchedule', sched, m);
		List<String> jobIds = BatchReprocessAsyncFFSchedule.scheduleMe();
		String firstJobId = jobIds[0];

		// Get the information from the CronTrigger API object
		CronTrigger ct = [
			SELECT Id, CronExpression, TimesTriggered, NextFireTime
        	FROM CronTrigger 
        	WHERE id = :firstJobId
        ];
 
		// Verify the expressions are the same
		System.assertEquals(BatchReprocessAsyncFFSchedule.CRON_LIST[0], ct.CronExpression);
 
		// Verify the job has not run
		System.assertEquals(0, ct.TimesTriggered);
		
		Test.stopTest();
		
	}
}