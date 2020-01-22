/**
* AccountBalance_TEST
* Tests: AccountBalance
* Date: 2019-01-31
* Programmer: Bryan Leaman
* Project: W-000574
*
*/
@isTest
private class AccountBalance_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		//FFAdata.refresh(); 
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
		TestHelper_MW th = new TestHelper_MW();
		th.getPersonAccount('1');
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			Account pa = [select Id, Name from Account limit 1];
			List<AccountBalance.BalanceByCompany> bbc = AccountBalance.AccountBalancesByCompany(pa.Id);
			AccountBalance.BalanceByCompany b = new AccountBalance.BalanceByCompany(null, 'Fake company', 'fake', 1.00);
			String reporturl = AccountBalance.ReportURL();
			boolean auth = AccountBalance.AuthorizedToTransactionLines();
		}
	}

}