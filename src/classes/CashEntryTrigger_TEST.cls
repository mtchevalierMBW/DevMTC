/**
* CashEntryTrigger_TEST
* Tests: CashEntryTrigger,CashEntryLineDefaultDim1
* Date: 2019-05-15
* Programmer: Bryan Leaman
* Project: W-000575
* Update proposal F&I overall status info when credit application statuses are updated.
*
* Coverage:
*
* Modifications: 
*
*/
@isTest
private class CashEntryTrigger_TEST {

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
		update(new dealer__Dealer_Location__c(Id=FFAData.DealerLocation.Id, Manual_Cash_Entry__c=true));
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			Test.startTest();
			Account a = th.getPersonAccount('1');
			update(new Account(Id=a.Id, 
				c2g__CODAAccountsPayableControl__c = FFAdata.GLAMap.values()[0].Id,
			    c2g__CODAAccountsReceivableControl__c = FFAdata.GLAMap.values()[0].Id,
        		c2g__CODADimension1__c = FFAdata.Dimension1.Id
			));

			// Create cash entry
        	c2g__codaBankAccount__c ba = new c2g__codaBankAccount__c(
			Name='Test bank',
			c2g__AccountName__c = 'Test account',
				c2g__AccountNumber__c = '123',
				c2g__BankName__c = 'Test bank name',
				c2g__ReportingCode__c = '123',
				c2g__GeneralLedgerAccount__c = FFAData.GLAMap.values()[0].Id
        	);
			insert(ba);
			c2g__codaCashEntry__c ce = new c2g__codaCashEntry__c(
        	   	c2g__BankAccount__c = ba.Id,
        	   	c2g__Type__c='Receipt',
				c2g__Date__c=Date.today(),
				Automated_Entry__c = true
			);
			insert(ce);
			List<c2g__codaCashEntryLineItem__c> celines = new List<c2g__codaCashEntryLineItem__c>();
			celines.add(new c2g__codaCashEntryLineItem__c(
				c2g__CashEntry__c = ce.Id,
				c2g__Account__c = a.Id,
				c2g__CashEntryValue__c = 100.00,
				Control__c = 'TestCashEntryLine 1',
				c2g__AccountDimension1__c = FFAdata.Dimension1.Id,
				ffcash__DeriveAccountDimensions__c = false
			));
			insert(celines);

			// force failure ... unless special permission was granted to the user
			update(new dealer__Dealer_Location__c(Id=FFAData.DealerLocation.Id, Manual_Cash_Entry__c=true));
			boolean updated = false;
			try {
				update(ce);
				updated = true;
			} catch(Exception e) {}
			try {
				update(celines);
				updated = true;
			} catch(Exception e) {}

			Test.stopTest();
		}
	}

}