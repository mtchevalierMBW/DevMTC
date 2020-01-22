/**
* CashEntryBatchProcesses_TEST
* Tests: CashEntryBatchProcesses
* Date: 2019-06-10
* Programmer: Bryan Leaman
* Project: W-000575
*
* Coverage:
*
* Modifications: 
*
*/
@isTest
private class CashEntryBatchProcesses_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
		TestHelper_MW th = new TestHelper_MW();
		th.createGeneralLedgerAccounts(new List<String>{'1001t','1100'});
		FFAdata.refresh(); 
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			Test.startTest();
			CashEntryBatchProcesses.launchCreateCashEntries(null);
			CashEntryBatchProcesses.launchPostCashEntries();
			CashEntryBatchProcesses.launchCashMatching();
			Test.stopTest();
		}
	}

}