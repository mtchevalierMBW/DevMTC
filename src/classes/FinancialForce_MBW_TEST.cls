/**
 * FinancialForce_MBW_TEST
 * Tests: FinancialForce_MBW
 * Programmer: Bryan Leaman
 * Date: 2015-12-07
 *
 *	2016-12-06	B. Leaman	BLL1 - Fix index out of bounds when testing user has no authorized companies.
 *	2017-08-31	B. Leaman	BLL2 - failing to find open period using first company -- try user's current company.
 * 
 * Uses seeAllData.
 */
@isTest
private class FinancialForce_MBW_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	private static void setupTestData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		//FFAdata.refresh(); 
		//System.runAs(FFAdata.TestUser) {
		//}
	}

    static testMethod void testCompanyInterfaces() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			
    	List<c2g__codaCompany__c> authCmps = FinancialForce_MBW.getMyAuthorizedCompanies();
    	Set<Id> mcc = FinancialForce_MBW.getMyCurrentCompanyOwnerIds();
    	FinancialForce_MBW.selectCompanies(mcc);
		List<c2g__codaCompany__c> cc = FinancialForce_MBW.getMyCurrentCompanies();
		if (cc.size()>0) {
			FinancialForce_MBW.selectCompany(cc[0].Id);
		}
		Set<Id> us = new Set<Id>();
		us.add(UserInfo.getUserId());
		Set<Id> cs = new Set<Id>();
		if (authCmps!=null && authCmps.size()>0) cs.add(authCmps[0].Id);	// BLL1c
		FinancialForce_MBW.GrantUserCompanyAuth(us, cs);
		Set<Id> ownerIds = FinancialForce_MBW.getCompanyOwnerIds();
		List<c2g__codaCompany__c> ac = FinancialForce_MBW.getAllCompanies();
		//if (ac.size()>0) FinancialForce_MBW.getOpenPeriod(ac[0], Date.today());
		if (cc.size()>0) FinancialForce_MBW.getOpenPeriod(cc[0], Date.today());	// BLL2a
		
		}
    }

	static testMethod void testCreateJournalApi() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {

    	List<c2g__codaCompany__c> authCmps = FinancialForce_MBW.getMyCurrentCompanies();
		c2g__codaJournal__c j = new c2g__codaJournal__c();
		j.c2g__OwnerCompany__c = (authCmps!=null && authCmps.size()>0) ? authCmps[0].Id : null;	// BLL1c
		j.c2g__JournalDate__c = Date.today();
		j.c2g__Reference__c = 'Test ref';
		j.c2g__JournalDescription__c = 'Test description';
		List<c2g__codaAccountingCurrency__c> currs = [
			select Id 
			from c2g__codaAccountingCurrency__c 
			where c2g__OwnerCompany__c=:j.c2g__OwnerCompany__c 
		];
		c2g__codaAccountingCurrency__c curr = currs.size()>0 ? currs[0] : null;
		j.c2g__JournalCurrency__c = curr!=null ? curr.Id : null;
		j.Source__c = 'TST';
		
		List<c2g__codaGeneralLedgerAccount__c> gla = [
			select Id 
			from c2g__codaGeneralLedgerAccount__c 
			limit 5
		];
		List<c2g__codaDimension1__c> dim1 = [
			select Id 
			from c2g__codaDimension1__c 
			limit 5
		];
		
		List<c2g__codaJournalLineItem__c> lines = new List<c2g__codaJournalLineItem__c>();
		lines.add(new c2g__codaJournalLineItem__c());
		lines[0].c2g__LineType__c = 'General Ledger Account';
		lines[0].c2g__GeneralLedgerAccount__c = gla.size()>0 ? gla[0].Id : null;
		lines[0].c2g__Dimension1__c = dim1.size()>0 ? dim1[0].Id : null;
		lines[0].Control__c = 'TST';
		lines[0].c2g__Value__c = 1.00;
		
		Id rsltid = gla.size()>0 ? FinancialForce_MBW.createJournalApi(j, lines) : null;
		
		}
	}

}