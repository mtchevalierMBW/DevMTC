/**
* AvalaraSalesTaxValidator_TEST
* Tests: AvalaraSalesTaxValidator
* Date: 2019-08-01
* Programmer: Bryan Leaman
* Project: #
*
* Coverage:
*
* Modifications: 
*
*/
@isTest
private class AvalaraSalesTaxValidator_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			TaxSvc.GetTaxResult fakeResult = new TaxSvc.GetTaxResult();
			AvaTaxRequestMock gettaxMock = new AvaTaxRequestMock();
			Test.setMock(WebServiceMock.class, new WebServiceCalloutMock(gettaxMock));
			Test.startTest();
			AvalaraSalesTaxValidator.CalculateTaxesForLocations(
				new List<String>{FFAdata.DealerLocation.dealer__Company_Number__c},
				1000,
				'PH050302',
				Date.today(), 
				true
			);			
			Test.stopTest();
		}
	}

}