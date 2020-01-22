/**
* CashEntryAutoPostDT_TEST
* Tests: CashEntryAutoPostDT
* Date: 2019-04-11
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
private class CashEntryAutoPostDT_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		update(new c2g__codaCompany__c(Id=FFAdata.currentCompany.Id, BatchCashPosting__c=true));
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();

		System.runAs(FFAdata.TestUser) {

			TestHelper_MW th = new TestHelper_MW();
			th.createGeneralLedgerAccounts(new List<String>{'1100'});
			FFAdata.refresh(); 

			List<c2g__codaGeneralLedgerAccount__c> glalist = new List<c2g__codaGeneralLedgerAccount__c>(); 
			Integer i = 0;
			for(c2g__codaGeneralLedgerAccount__c gl : FFAdata.GLAMap.values()) {
				glalist.add(gl);
			}

       		Account pa = th.getPersonAccount('1');
       		pa.c2g__CODAAccountsPayableControl__c = glalist[0].Id;
       		pa.c2g__CODAAccountsReceivableControl__c = glalist[0].Id;
       		pa.c2g__CODADimension1__c = FFAdata.Dimension1.Id;
       		update(pa);
	
			update(new dealer__Dealer_Location__c(Id=FFAdata.DealerLocation.Id, Financial_Force_Dimension_1__c=FFAdata.Dimension1.Id));

			// Create cash entry
        	c2g__codaBankAccount__c ba = new c2g__codaBankAccount__c(
			Name='Test bank',
			c2g__AccountName__c = 'Test account',
				c2g__AccountNumber__c = '123',
				c2g__BankName__c = 'Test bank name',
				c2g__ReportingCode__c = '123',
				c2g__GeneralLedgerAccount__c = glalist[0].Id
        	);
			insert(ba);
			c2g__codaCashEntry__c ce = new c2g__codaCashEntry__c(
        	   	c2g__BankAccount__c = ba.Id,
        	   	c2g__Type__c='Payment',
				c2g__Date__c=Date.today(),
				Automated_Entry__c = true
			);
			insert(ce);
			List<c2g__codaCashEntryLineItem__c> celines = new List<c2g__codaCashEntryLineItem__c>();
			celines.add(new c2g__codaCashEntryLineItem__c(
				c2g__CashEntry__c = ce.Id,
				c2g__Account__c = pa.Id,
				c2g__CashEntryValue__c = 100.00,
				Control__c = 'TestCashEntryLine 1',
				c2g__AccountDimension1__c = FFAdata.Dimension1.Id,
				ffcash__DeriveAccountDimensions__c = false
			));
			insert(celines);
			
		}

	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			Test.startTest();
			CashEntryAutoPostDT.ScheduleMe();
			Database.executeBatch(new CashEntryAutoPostDT(null, true, null, '= TODAY', null, null));
			Test.stopTest();
		}
	}

}