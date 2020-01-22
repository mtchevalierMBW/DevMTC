/**
 * PayableCreditExpLineTrigger_TEST
 * Tests: PayableCreditExpLineTrigger_TEST
 * Date: Feb 22, 2017
 * Programmer: Bryan Leaman
 *
 */
@isTest
private class PayableCreditExpLineTrigger_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
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
        	Account a = th.getPersonAccount('1');
			
			c2g__codaPurchaseCreditNote__c pcn = new c2g__codaPurchaseCreditNote__c(
				c2g__Account__c = a.Id,
				c2g__AccountCreditNoteNumber__c = 'test123',
				c2g__CreditNoteDate__c = Date.today(),
				c2g__DeriveCurrency__c = true,
				ffap__DeriveCurrency__c = true,
				c2g__DeriveDueDate__c = true,
				ffap__DeriveDueDate__c = true,
				c2g__DerivePeriod__c = true,
				ffap__DerivePeriod__c = true
			);
			insert(pcn);
			c2g__codaPurchaseCreditNoteExpLineItem__c pce = new c2g__codaPurchaseCreditNoteExpLineItem__c(
				c2g__PurchaseCreditNote__c = pcn.Id,
				c2g__LineNumber__c = 1,
				c2g__Dimension1__c = FFAdata.Dimension1.Id,
				c2g__GeneralLedgerAccount__c = FFAdata.GLAMap.values()[0].Id,
				c2g__NetValue__c = 1
			);
			insert(pce);
		}
	}

}