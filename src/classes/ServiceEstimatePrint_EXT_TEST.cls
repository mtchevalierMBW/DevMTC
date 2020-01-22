/**
* ServiceEstimatePrint_EXT_TEST
* Tests: ServiceEstimatePrint_EXT
* Date: 2019-04-05
* Programmer: Bryan Leaman
 * Project: W-000645
 * Update proposal F&I overall status info when credit application statuses are updated.
 *
 * Coverage:
 *
 * Modifications: 
 *
*/
@isTest
private class ServiceEstimatePrint_EXT_TEST {

	@testSetup
	static void setupData() {
		TestHelper_MW th = new TestHelper_MW();
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
		Account a = th.getPersonAccount('1');
		insert(new dealer__Service_Estimate__c(
			dealer__Customer__c=a.Id
		));
	}


	// ctrlExtTest
	//---------------------------------------
	static testMethod void ctrlExtTest() {
		TestHelper_MW th = new TestHelper_MW();

		dealer__Service_Estimate__c se = [select Id from dealer__Service_Estimate__c limit 1];
		ApexPages.StandardController sc = new ApexPages.StandardController(se);
		ServiceEstimatePrint_EXT lc = new ServiceEstimatePrint_EXT(sc);
		String test = lc.PrintDateTimeLocal;
		System.assert(!String.isBlank(test), 'Did not get a printable date and time');
	}

}