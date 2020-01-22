/**
* BatchProcessAsyncFF_TEST
* Tests: BatchProcessAsyncFF
* Date: 2019-03-15
* Programmer: Bryan Leaman
 * Project: #
 * Update proposal F&I overall status info when credit application statuses are updated.
 *
 * Coverage:
 *
 * Modifications: 
 *
*/
@isTest
private class BatchProcessAsyncFF_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		//FFAdata.refresh(); 
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			Test.startTest();
			insert(new FFAccountingFailure__c(Payload__c='{"recordId"=' + UserInfo.getUserId() + ',"action":"do_nothing"}'));
			BatchProcessAsyncFF.scheduleMe();
			//BatchProcessAsyncFF ba = new BatchProcessAsyncFF('1', '1', '', false);
			//Database.executeBatch(ba,1);
			Test.stopTest();
		}
	}

}