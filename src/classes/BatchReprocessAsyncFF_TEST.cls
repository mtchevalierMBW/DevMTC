/**
 * BatchReprocessAsyncFF_TEST
 * Tests: BatchReprocessAsyncFF
 * Date: Sep 20, 2016
 * Programmer: Bryan Leaman
 * 
 * 
 */
@isTest(seeAllData=true)
private class BatchReprocessAsyncFF_TEST {

	static testMethod void unitTest() {
		insert(new FFAccountingFailure__c(Payload__c='{"recordId"=' + UserInfo.getUserId() + ',"action":"do_nothing"}'));
		BatchReprocessAsyncFF ba = new BatchReprocessAsyncFF('1', false);
		Database.executeBatch(ba,1);
	}
}