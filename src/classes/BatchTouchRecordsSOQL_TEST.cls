/**
 * BatchTouchRecordsSOQL_TEST
 * Tests: BatchTouchRecordsSOQL_TEST
 * Date: Sep 29, 2016
 * Programmer: Bryan Leaman
 * 
 * 
 */
@isTest
private class BatchTouchRecordsSOQL_TEST {

	static testMethod void unitTest() {

			BatchTouchRecordsSOQL ba = new BatchTouchRecordsSOQL('select Id, Name from User where Id=\''+UserInfo.getUserId()+'\'', false);
			Database.executeBatch(ba);
		
	}
}