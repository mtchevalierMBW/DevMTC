/**
 * MiscChargeOption_Trigger_TEST
 * Tests: MiscChargeOption_Trigger
 * Date: 2016-09-08
 * Programmer: Bryan Leaman
 *
 */
@isTest
private class MiscChargeOption_Trigger_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
	}

	// FF_Account
	//---------------------------------------
	static testMethod void FF_GlAccount() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
        	c2g__codaGeneralLedgerAccount__c gl = [select Id from c2g__codaGeneralLedgerAccount__c limit 1];
			Misc_Charge_Option__c mco = new Misc_Charge_Option__c(
				Name = 'Test',
				Location__c = FFAdata.DealerLocation.Id,
				Quantity__c = 1,
				Rate__c = 1.25,
				General_Ledger_Account__c = gl.Id
			);
			insert(mco);
			Misc_Charge_Option__c mcocheck = [select General_Ledger_Account__c, General_Ledger_Acct_MW__c from Misc_Charge_Option__c limit 1];
			System.assert(mcocheck.General_Ledger_Acct_MW__c!=null, 'Did not get a MW GL account assigned');
		}
	}

	// MW_Account
	//---------------------------------------
	static testMethod void MW_GlAccount() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
        	GeneralLedgerAcctMW__c mwgl = [select Id from GeneralLedgerAcctMW__c limit 1];
			Misc_Charge_Option__c mco = new Misc_Charge_Option__c(
				Name = 'Test',
				Location__c = FFAdata.DealerLocation.Id,
				Quantity__c = 1,
				Rate__c = 1.25,
				General_Ledger_Acct_MW__c = mwgl.Id
			);
			insert(mco);
			Misc_Charge_Option__c mcocheck = [select General_Ledger_Account__c, General_Ledger_Acct_MW__c from Misc_Charge_Option__c limit 1];
			System.assert(mcocheck.General_Ledger_Account__c!=null, 'Did not get a FF GL account assigned');
		}
	}
}