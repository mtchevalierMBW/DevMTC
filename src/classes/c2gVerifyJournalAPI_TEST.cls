/**
 * c2gVerifyJournalAPI_TEST
 * Tests: c2gVerifyJournalAPI
 * Date: Dec 8, 2017
 * Programmer: Bryan Leaman
 *
 */
@isTest
private class c2gVerifyJournalAPI_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		//FFAdata.refresh(); 
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        List<SObject> testdata = new List<SObject>();
        testdata.add(new c2g__codaGeneralLedgerAccount__c(
        	Name='8000 - test misc account',
        	c2g__ReportingCode__c='8000',
        	c2g__Type__c='Balance Sheet'
        ));
        testdata.add(new c2g__codaDimension1__c(
        	Name='183 - IT Dept',
        	c2g__ReportingCode__c='183'
        ));
        insert(testdata);
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			c2gVerifyJournalAPI vja = new c2gVerifyJournalAPI();
			vja.createPostRollbackJournal();
		}
	}

}