/**
 * TransactionDownloadBatch_TEST
 * Tests: TransactionDownloadBatch
 * 
 *	2016-06-02	B. Leaman	BLL1 - Do not need to specify ffgl__ fields (prep for FFv14)
 */
@isTest
private class TransactionDownloadBatch_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 
	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
	}

	static testMethod void testBatchProcess() {

		FFAdata.refresh(); 
		                
    	System.runAs(FFAdata.TestUser) {
    		
    		TestHelper_MW th = new TestHelper_MW();

			// Create and post journal so we have a transaction to download
			Account a = th.getPersonAccount('1');
			
			c2g__codaGeneralLedgerAccount__c gla1 = new c2g__codaGeneralLedgerAccount__c();
			gla1.c2g__ReportingCode__c ='12';
			gla1.c2g__Type__c='Balance Sheet';
			gla1.Name='Test';
			insert gla1;
			c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c();
			dim1.c2g__ReportingCode__c = '111';
			dim1.Name = '111 Dim';
			insert(dim1);
            
			c2g__codaJournal__c newj = new c2g__codaJournal__c();
			newj.c2g__JournalDate__c =system.today();
			newj.Source__c ='GE';
			newj.c2g__Type__c='Manual Journal';
			//BLL1d newj.ffgl__DeriveCurrency__c=true;
			//BLL1d newj.ffgl__DerivePeriod__c=true;
			newj.c2g__JournalStatus__c='In Progress';
			newj.Customer__c = a.Id;
			insert(newj);
    
			List<c2g__codaJournalLineItem__c> newl = new List<c2g__codaJournalLineItem__c>();
			newl.add(new c2g__codaJournalLineItem__c());
			newl[0].c2g__Journal__c = newj.Id;
			newl[0].c2g__Value__c = 1.00;
			newl[0].c2g__GeneralLedgerAccount__c = gla1.Id;  //BLL2c gl.Id;
			newl[0].c2g__LineType__c = 'General Ledger Account'; 
			newl[0].c2g__LineNumber__c = 1;
			newl[0].Control__c = 'TestJournalLine 1';
			newl[0].Sales_Person__c = UserInfo.getUserId();
			newl[0].c2g__Dimension1__c = dim1.Id; // BLL1a

			newl.add(new c2g__codaJournalLineItem__c());
			newl[1].c2g__Journal__c = newj.Id;
			newl[1].c2g__Value__c = -1.00;
			newl[1].c2g__GeneralLedgerAccount__c = gla1.Id;  //BLL2c gl.Id;
			newl[1].c2g__LineType__c = 'General Ledger Account'; 
			newl[1].c2g__LineNumber__c = 2;
			newl[1].c2g__Dimension1__c = dim1.Id; // BLL1a
			insert(newl);
            
			c2g.CODAAPICommon.Reference ref = new c2g.CODAAPICommon.Reference();
			ref.Id = newj.Id;
			c2g.CODAAPIJournal_9_0.PostJournal(null, ref);

			DownloadTransactionsControl__c lastDownload;
        
			List<c2g__codaTransaction__c> trn = [
				Select Id, Name
				From c2g__codaTransaction__c
				Order by CreatedDate desc
				limit 5
			];
        
			String trnName = trn[trn.size()-1].Name;
			trnName = trnName.left(trnName.length()-2); // BLL
			String toTrnName = trn[0].Name;
			lastDownload = DownloadTransactionsControl__c.getOrgDefaults();
			if (lastDownload==null) {
				lastDownload = new DownloadTransactionsControl__c(LastTransactionName__c=trnName);
				insert(lastDownload);
			}
        
			TransactionDownloadBatch tdb = new TransactionDownloadBatch(trnName, toTrnName, false, '', false);
			Database.executeBatch(tdb);

    	}
    	
	}
	
	// Test the controller
	static testMethod void testController() {
		TransactionDownload_CTLR tdc = new TransactionDownload_CTLR();
		tdc.sinceTransaction = null;
		tdc.untilTransaction = null;
		tdc.saveLastTransaction = false;
		tdc.overrideSelection = false;
		String dt = tdc.lastSubmittedDT;
		dt = tdc.lastCompletedDT;
		boolean admin = tdc.isAdmin;
		tdc.logSubmit();
		tdc.submitDownload();
		tdc.dummyProc(); 
	}
   
}