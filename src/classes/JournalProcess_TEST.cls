/**
 * JournalProcess_TEST
 * Tests: JournalProcess
 * Date: May 12, 2017
 * Programmer: Bryan Leaman
 *
 *	2019-07-11	W-000712	BLL1 - adjustments with TW company name change
 */
@isTest
private class JournalProcess_TEST {

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
			c2g__codaCompany__c comp = [select Id, Name from c2g__codaCompany__c limit 1];
			
			
			c2g__codaJournal__c jrn = new c2g__codaJournal__c(
				c2g__OwnerCompany__c = comp.Id,
				c2g__JournalDescription__c = 'SOISS',
				Source__c = 'GE'
			);
			JournalProcess jp = new JournalProcess(new List<c2g__codaJournal__c>{jrn}, null);
			jp.TransitWorksCompany();
			// BLL1
			//jp.TW = comp; 
			JournalProcess.TW = comp;
			// BLL1 end
			
			jp.RootstockSourceCode();
		
			System.assertEquals('SI',jrn.Source__c,'Journal source was not updated to SI');	
		}
	}


	// JournalReferenceSCR
	//---------------------------------------
	static testMethod void JournalReferenceSCR() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
        	Account a = th.getPersonAccount('1');
			c2g__codaCompany__c comp = [select Id, Name from c2g__codaCompany__c limit 1];
			
			c2g__codaInvoice__c sin = new c2g__codaInvoice__c(
				c2g__OwnerCompany__c = comp.Id,
				c2g__Account__c = a.Id
			);
			insert(sin);
			c2g__codaCreditNote__c scr = new c2g__codaCreditNote__c(
				c2g__OwnerCompany__c = comp.Id,
				c2g__Account__c = a.Id,
				c2g__Invoice__c = sin.Id
			);
			insert(scr);
			
			c2g__codaJournal__c jrn = new c2g__codaJournal__c(
				c2g__OwnerCompany__c = comp.Id,
				c2g__JournalDescription__c = 'SOISS',
				c2g__Reference__c = null,
				Sales_Credit_Note__c = scr.Id,
				Source__c = 'GE'
			);
			JournalProcess jp = new JournalProcess(new List<c2g__codaJournal__c>{jrn}, null);
			jp.RootstockSalesCreditReference();
			System.debug(jrn);		
			System.assert(!String.isBlank(jrn.c2g__Reference__c),'Journal reference was not updated to SCR and SIN');	
		}
	}



	// JournalReferenceSCR
	//---------------------------------------
	static testMethod void ReversingJournalRefs() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			c2g__codaCompany__c comp = [select Id, Name from c2g__codaCompany__c limit 1];
			
			c2g__codaJournal__c jrn = new c2g__codaJournal__c(
				c2g__OwnerCompany__c = comp.Id,
				c2g__JournalDescription__c = 'SOISS',
				c2g__Reference__c = null,
				Source__c = 'GE'
			);
			insert(jrn);

			c2g__codaJournal__c revj = new c2g__codaJournal__c(
				c2g__SourceJournal__c = jrn.Id,
				c2g__Type__c='Reversing Journal'
			);

			c2g__codaJournal__c cnlj = new c2g__codaJournal__c(
				c2g__OriginalJournal__c = jrn.Id,
				c2g__Type__c='Cancelling Journal'
			);
			
			
			JournalProcess jp = new JournalProcess(new List<c2g__codaJournal__c>{revj, cnlj}, null);
			jp.ReversingJournal();
			System.debug(revj);		
			System.debug(cnlj);		
			System.assertEquals(jrn.Source__c, revj.Source__c, 'Reversing journal source was not updated from source journal');	
			System.assertEquals(jrn.Source__c, cnlj.Source__c, 'Cancelling journal source was not updated from source journal');	
		}
	}


	//static testMethod void reversingJournalTest() {
	//	FFAdata.refresh(); 
    //                    
	//	System.runAs(FFAdata.TestUser) {
    //    	TestHelper_MW th = new TestHelper_MW();
	//		Account a = th.getPersonAccount('1');
	//
	//		c2g__codaGeneralLedgerAccount__c gla1 = new c2g__codaGeneralLedgerAccount__c();
    //   	gla1.c2g__ReportingCode__c ='12';
    //    	gla1.c2g__Type__c='Balance Sheet';
    //    	gla1.Name='Test';
    //    	insert gla1;
    //    	c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c();
    //    	dim1.c2g__ReportingCode__c = '111';
    //    	dim1.Name = '111 Dim';
    //    	insert(dim1);
    //        
    //		c2g__codaJournal__c newj = new c2g__codaJournal__c();
	//		newj.c2g__JournalDate__c =system.today();
	//		newj.Source__c ='PU';
	//		newj.c2g__Type__c='Manual Journal';
	//		newj.c2g__JournalStatus__c='In Progress';
	//		newj.c2g__JournalDescription__c = 'PORCPT';	
	//		newj.Customer__c = a.Id;
	//		insert(newj);
	//		
	//		Test.startTest();
	//		
	//		c2g__codaJournal__c revjrn = new c2g__codaJournal__c(
	//			c2g__Type__c = 'Reversing Journal',
	//			c2g__SourceJournal__c = newj.Id
	//		);
	//		JournalProcess jp = new JournalProcess(new List<c2g__codaJournal__c>{revjrn},null);
	//		jp.ReversingJournal();
	//		insert(revjrn);
	//		
	//		Test.stopTest();
	//		
	//		System.assertEquals('PU', revjrn.Source__c, 'Reversing journal did not update source');
	//	}
	//}

}