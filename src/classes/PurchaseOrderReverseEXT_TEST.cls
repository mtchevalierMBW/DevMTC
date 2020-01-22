/**
* PurchaseOrderReverseEXT_TEST
* Tests: PurchaseOrderReverseEXT
* Date: 2019-07-11
* Programmer: Bryan Leaman
* Project: W-000524
*
* Coverage:
*
* Modifications: 
*
*/
@isTest
private class PurchaseOrderReverseEXT_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();

		TestHelper_MW th = new TestHelper_MW();
		Account v = th.getVendorAccount('1');
        dealer__Purchase_Order__c sublet = new dealer__Purchase_Order__c(
	        RecordTypeId=Schema.SObjectType.dealer__Purchase_Order__c.getRecordTypeInfosByName().get('Sublet').getRecordTypeId(),
        	dealer__Vendor__c = v.Id,
        	dealer__Vendor_Email__c = 'test@example.org',
			dealer__Company__c = FFAdata.DealerLocation.Id
		);
        insert sublet;

	}


	// ctrlExtTest
	//---------------------------------------
	static testMethod void ctrlExtTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();

			PageReference pgRef = Page.PurchaseOrderReverse; 
			Test.setCurrentPage(pgRef); //Set the page for Test Method
			dealer__Purchase_Order__c po = [select Id, dealer__PO_Accounting_Name__c from dealer__Purchase_Order__c limit 1];
			ApexPages.currentPage().getParameters().put('id', po.id);
			ApexPages.StandardController sc = new ApexPages.StandardController(po);
			Test.startTest();
			PurchaseOrderReverseEXT ext = new PurchaseOrderReverseEXT(sc);
			boolean isallowed = ext.AllowSubletReversal;
			List<dealer__Purchase_Order_Line__c> pol = ext.purchaseOrderLines;
			ext.reverseSubletPO();
			ext.returnToRO();
			ext.doReverseSubletPO();
			Test.stopTest();
		}
	}

}