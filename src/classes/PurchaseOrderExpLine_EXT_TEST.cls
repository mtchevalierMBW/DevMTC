/**
* PurchaseOrderExpLine_EXT_TEST
* Tests: PurchaseOrderExpLine_EXT
* Date: 2018-12-04
* Programmer: Bryan Leaman
* Project: W-000520
*
* Modifications:
*	
*/
@isTest
private class PurchaseOrderExpLine_EXT_TEST {

	 private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	 @testSetup
	 static void setupFFA() {
		 TestHelper_MW.createBaseFFAData(FFAdata);
		 //FFAdata.refresh(); 
		 dealer.TestClassUtil tc = new dealer.TestClassUtil();
		 tc.insertDMSSettings();

		 insert(new c2g__codaGeneralLedgerAccount__c(
			 Name='Test',
			 c2g__Type__c='Balance Sheet',
			 c2g__ReportingCode__c = 'Test'
		 ));
	 }


	 // ctrlExtTest
	 //---------------------------------------
	 static testMethod void ctrlExtTest() {
		 FFAdata.refresh(); 
		 System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			Account v = th.getVendorAccount('1');
			dealer__Purchase_Order__c po = new dealer__Purchase_Order__c(
				dealer__Vendor__c = v.Id
			);
			insert(po);
			GeneralLedgerAcctMW__c gl = [select Id from GeneralLedgerAcctMW__c limit 1];

			PageReference pgRef = Page.PurchaseOrderLineMisc; 
			Test.setCurrentPage(pgRef); //Set the page for Test Method
			ApexPages.currentPage().getParameters().put('Id',null);
			// setup various parm styles
			ApexPages.currentPage().getParameters().put('poId', po.Id);
			ApexPages.currentPage().getParameters().put('test_lkid', po.Id);
			String jsonstr = '{"type":"standard__recordPage","attributes":{"objectApiName":"dealer__Purchase_Order__c","recordId":"' + po.Id + '","actionName":"view"},"state":{}}';
			String b64 = EncodingUtil.base64Encode(Blob.valueOf(jsonstr));
			ApexPages.currentPage().getParameters().put('inContextOfRef', '1.'+b64);
			ApexPages.StandardController sc = new ApexPages.StandardController(new dealer__Purchase_Order_Line__c());
			PurchaseOrderExpLine_EXT lc = new PurchaseOrderExpLine_EXT(sc);
			lc.save();
			lc.obj.GeneralLedgerAcct__c = gl.Id;
			lc.save();
			lc.cancel();

		 }
	 }

}