/**
 * AccountTools_TEST
 * Tests: AccountTools
 * Date: Mar 3, 2016
 * Programmer: Bryan Leaman
 *
 */
@isTest
private class AccountTools_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
       	TestHelper_MW th = new TestHelper_MW();
		Account a = th.getBusinessAccount('1');
		AccountTools.convertToCommercialAccount(a.Id);
		Account check1 = [select RecordType.Name from Account where Id=:a.Id];
		AccountTools.convertToPersonAccount(a.Id);
		Account check2 = [select RecordType.Name from Account where Id=:a.Id];
		AccountTools.convertToBusinessAccount(a.Id);
		Account check3 = [select RecordType.Name from Account where Id=:a.Id];
		
		System.assert(check1.RecordType.Name=='Commercial', 'Did not convert to a commercial account');
		System.assert(check2.RecordType.Name=='PersonAccount', 'Did not convert to a person account');
		System.assert(check3.RecordType.Name=='Business Account', 'Did not convert to a business account');
		
	}

}