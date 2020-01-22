/**
 * TransactionReferences_TEST
 * Tests: TransactionReferences, TransactionLineItemReferences
 *
 * 2015-09-09   B. Leaman   BLL1 - Dimension1 is now required
 * 2015-12-14   B. Leaman   BLL2 - Test reversing journal
 * 2016-02-02	B. Leaman	BLL3 - chg cash entry type for Dimension1Default test
 * 2016-02-04	B. Leaman	BLL4 - Specify acct payable ctl GL # on account for cash entry test.
 * 2016-03-14	B. Leaman	BLL5 - Add tests for custom fields on reversing journal transaction lines.
 * 2016-06-02	B. Leaman	BLL6 - Don't specify ffgl__ & ffap__ (FF v14)
 * 2017-05-08	B. Leaman	BLL7 - increase code coverage in JournalLineReferences
 * 2018-04-26	B. Leaman	BLL8 - test journal line control# defaults (for SIN & SCR)
 */
@isTest
private class TransactionReferences_TEST {

    // BLL2a
    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 
    @testSetup
    static void setupFFA() {
        TestHelper_MW.createBaseFFAData(FFAdata);
    }
    // BLL2a end

    static testMethod void CopyJournalReferencesToTransaction() {

        FFAdata.refresh(); // BLL2a
                        
        System.runAs(FFAdata.TestUser) {
            
        TestHelper_MW th = new TestHelper_MW();
        //User u = th.getTestUser('1');
        //System.runAs(u) {
            Account a = th.getPersonAccount('1');
          
        // setting company & currency like this is not working - they are derived  
        //c2g__codaCompany__c cgmpy = new c2g__codaCompany__c();
        //cgmpy.c2g__Country__c='Test';
        //insert cgmpy;
        
        //c2g__codaAccountingCurrency__c cgc = new c2g__codaAccountingCurrency__c();
        //cgc.c2g__Dual__c=true;
        //insert cgc;
        
            //c2g__codaPeriod__c cp = new c2g__codaPeriod__c();
            //cp.c2g__Description__c='Test';
            //insert cp;

        // BLL2a
        c2g__codaGeneralLedgerAccount__c gla1 = new c2g__codaGeneralLedgerAccount__c();
        gla1.c2g__ReportingCode__c ='12';
        gla1.c2g__Type__c='Balance Sheet';
        gla1.Name='Test';
        insert gla1;
        c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c();
        dim1.c2g__ReportingCode__c = '111';
        dim1.Name = '111 Dim';
        insert(dim1);
        // BLL2a end

            
            c2g__codaJournal__c newj = new c2g__codaJournal__c();
            //newj.c2g__OwnerCompany__c=cgmpy.id;
            newj.c2g__JournalDate__c =system.today();
            newj.Source__c ='GE';
            newj.c2g__Type__c='Manual Journal';
            //newj.c2g__JournalCurrency__c=cgc.id;
            //newj.c2g__Period__c=cp.id;
            //BLL6d newj.ffgl__DeriveCurrency__c=true;
            //BLL6d newj.ffgl__DerivePeriod__c=true;
            newj.c2g__JournalStatus__c='In Progress';
            //newj.OwnerId= UserInfo.getUserId();
            newj.c2g__JournalDescription__c = 'PORCPT';	// BLL7a
            newj.Customer__c = a.Id;
            insert(newj);
    
            //BLL2d c2g__codaGeneralLedgerAccount__c gl = [select Id, Name from c2g__codaGeneralLedgerAccount__c limit 1];
            //BLL2d c2g__codaDimension1__c dim1 = [select Id, Name from c2g__codaDimension1__c limit 1]; // BLL1a
            
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
            newl[0].c2g__LineDescription__c = 'Test PIN12345';	// BLL7a
            //insert(newl1);
            newl.add(new c2g__codaJournalLineItem__c());
            newl[1].c2g__Journal__c = newj.Id;
            newl[1].c2g__Value__c = -1.00;
            newl[1].c2g__GeneralLedgerAccount__c = gla1.Id;  //BLL2c gl.Id;
            newl[1].c2g__LineType__c = 'General Ledger Account'; 
            newl[1].c2g__LineNumber__c = 2;
            newl[1].Control__c = 'TestJournalLine 2';
            newl[1].c2g__Dimension1__c = dim1.Id; // BLL1a
            newl[0].c2g__LineDescription__c = 'Test PIN12345';	// BLL7a
            insert(newl);
            
            //newj.Customer__c = a.Id;
            //update(newj);
            Test.startTest();	// BLL5a
            
            c2g.CODAAPICommon.Reference ref = new c2g.CODAAPICommon.Reference();
            ref.Id = newj.Id;
            c2g.CODAAPIJournal_9_0.PostJournal(null, ref);
            
            // BLL2a reverse journal
            // Doesn't work. Getting "Manual Journal is the only valid journal type in this context.
            // refresh from database to get period
            //Id jid = newj.Id;
            //newj = [select Id, Name, c2g__Period__c from c2g__codaJournal__c where Id=:jid];
            //List<c2g.CODAAPIJournalTypes_12_0.ReversingInformation> revlist = new List<c2g.CODAAPIJournalTypes_12_0.ReversingInformation>();
            //c2g.CODAAPIJournalTypes_12_0.ReversingInformation rev1 = new c2g.CODAAPIJournalTypes_12_0.ReversingInformation();
            //rev1.OriginalJournalRef = new c2g.CODAAPICommon.Reference();
            //rev1.OriginalJournalRef.Id=newj.Id;
            //rev1.ReversingDate = Date.today();
            //rev1.ReversingDescription = 'Test reversal';
            //rev1.ReversingPeriod = new c2g.CODAAPICommon.Reference();
            //rev1.ReversingPeriod.Id = newj.c2g__Period__c;
            //rev1.ReversingReference = 'Test reversal ref';
            //revlist.add(rev1);
            //c2g.CODAAPICommon_10_0.Context ctx = new c2g.CODAAPICommon_10_0.Context();
			//ctx.CompanyName = FFAdata.CurrentCompany.Name;
            //c2g.CODAAPIJournal_12_0.BulkReverseJournal(ctx, revlist);
            
            //c2g__codaJournal__c jrn = [select Id, Name from c2g__codaJournal__c where c2g__SourceJournal__c=:newj.Id];
            //List<c2g__codaJournalLineItem__c> jlines = [select Id, Name, Control__c from c2g__codaJournalLineItem__c where c2g__Journal__c=:jrn.Id];
			//System.assert(jlines.size()>0, 'Did not create reversing lines');
			//System.assert(jlines[0].Control__c!=null, 'Did not get control number on reversing entry');
            // BLL2a end

			// BLL5a
			c2g__codaJournal__c jrn = [select Id, Name, c2g__Type__c, c2g__SourceJournal__c, c2g__Transaction__c from c2g__codaJournal__c where Id=:newj.Id limit 1];
			//c2g__codaTransaction__c newt = [select Id, Name, c2g__DocumentNumber__c from c2g__codaTransaction__c where Id=:jrn.c2g__Transaction__c limit 1];
			//Map<Id,c2g__codaTransaction__c> newMap = new Map<Id,c2g__codaTransaction__c>();
			//Map<Id,c2g__codaTransaction__c> oldMap = new Map<Id,c2g__codaTransaction__c>();
			//newMap.put(newt.Id, newt);
			//c2g__codaTransaction__c oldt = newt.clone(true,false,true,true);
			//oldt.c2g__DocumentNumber__c=null;
			//TransactionLineProcess.checkReversingTransaction(newMap, oldMap);
			
			//Map<Id,c2g__codaJournal__c> newMap = new Map<Id,c2g__codaJournal__c>();
			List<c2g__codaJournal__c> newList = new List<c2g__codaJournal__c>();
			Map<Id,c2g__codaJournal__c> oldMap = new Map<Id,c2g__codaJournal__c>();
			c2g__codaJournal__c oldjrn = jrn.clone(true,false,true,true);
			jrn.c2g__SourceJournal__c=jrn.Id;
			//newMap.put(jrn.Id, jrn);
			newList.add(jrn);
			oldMap.put(oldjrn.Id,oldjrn);
			//TransactionLineProcess.checkReversingJournal(newMap, oldMap);
			TransactionLineProcess.checkReversingJournal(newList, oldMap);
			Set<Id> jrnIds = new Set<Id>();
			jrnIds.add(newj.Id);
			TransactionLineProcess.FixReversingTransactionLineRefs(jrnIds);
			TransactionLineProcess.FixReversingJournalLineRefs(jrnIds);
			Test.stopTest();
			// BLL5a

        }
           
    }
    

    static testMethod void CopyCashEntryReferencesToTransaction() {

        FFAdata.refresh(); // BLL2a
        System.runAs(FFAdata.TestUser) { // BLL2a

            TestHelper_MW th = new TestHelper_MW();
            Account a = th.getPersonAccount('1');
            
            //c2g__codaDimension1__c dim1 = [select Id, Name from c2g__codaDimension1__c limit 1]; // BLL1a
        // BLL2a
        c2g__codaGeneralLedgerAccount__c gla1 = new c2g__codaGeneralLedgerAccount__c();
        gla1.c2g__ReportingCode__c ='12';
        gla1.c2g__Type__c='Balance Sheet';
        gla1.Name='Test';
        insert gla1;
        c2g__codaGeneralLedgerAccount__c gla2 = new c2g__codaGeneralLedgerAccount__c();
        gla2.c2g__ReportingCode__c ='13';
        gla2.c2g__Type__c='Balance Sheet';
        gla2.Name='Test2';
        insert gla2;
        c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c();
        dim1.c2g__ReportingCode__c = '111';
        dim1.Name = '111 Dim';
        insert(dim1);
        c2g__codaBankAccount__c ba = new c2g__codaBankAccount__c();
        ba.Name='Test bank';
        ba.c2g__AccountName__c = 'Test account';
        ba.c2g__AccountNumber__c = '123';
        ba.c2g__BankName__c = 'Test bank name';
        ba.c2g__ReportingCode__c = '123';
        ba.c2g__GeneralLedgerAccount__c = gla1.Id;
        insert(ba);
        a.c2g__CODAAccountsReceivableControl__c = gla2.Id;
        a.c2g__CODAAccountsPayableControl__c = gla1.Id;	// BLL4a
        update(a);
        //BLL2a            
            
            c2g__codaCashEntry__c ce = new c2g__codaCashEntry__c();
            c2g__codaCashEntryLineItem__c cel = new c2g__codaCashEntryLineItem__c();
            ce.Deposit_Total__c = 1.00;
            //try {
            //    ce.c2g__BankAccount__c = [select Id from c2g__codaBankAccount__c limit 1].Id;
            //} catch(Exception e) {}
            ce.c2g__BankAccount__c = ba.Id;
            ce.c2g__Type__c='Payment'; // BLL3a added for Dimension1Default_TEST
            insert(ce);
            cel.c2g__CashEntry__c = ce.Id;
            cel.c2g__Account__c = a.Id;
            cel.Third_Party_Payor__c = a.Id;
            cel.c2g__CashEntryValue__c = 1.00;
            cel.Control__c = 'TestCashEntryLine 1';
            cel.c2g__AccountDimension1__c = dim1.Id;  // BLL1a
            cel.ffcash__DeriveAccountDimensions__c = false;
            insert(cel);
            c2g.CODAAPICommon.Reference cref = new c2g.CODAAPICommon.Reference();
            cref.Id = ce.Id;
            c2g.CODAAPICashEntry_7_0.PostCashEntry(null, cref);

        } // BLL2a
    }
    

    static testMethod void CopyPurchInvReferencesToTransaction() {

        FFAdata.refresh(); // BLL2a
        System.runAs(FFAdata.TestUser) { // BLL2a
            
            TestHelper_MW th = new TestHelper_MW();
            Account a = th.getVendorAccount('1');
            //c2g__codaDimension1__c dim1 = [select Id, Name from c2g__codaDimension1__c limit 1]; // BLL1a
            //c2g__codaGeneralLedgerAccount__c gl = [select Id, Name from c2g__codaGeneralLedgerAccount__c limit 1];
            //Product2 prod = [select Id, Name from Product2 limit 1];
        // BLL2a
        c2g__codaGeneralLedgerAccount__c gla1 = new c2g__codaGeneralLedgerAccount__c();
        gla1.c2g__ReportingCode__c ='12';
        gla1.c2g__Type__c='Balance Sheet';
        gla1.Name='Test';
        insert gla1;
        c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c();
        dim1.c2g__ReportingCode__c = '111';
        dim1.Name = '111 Dim';
        insert(dim1);
        // BLL2a end

        a.c2g__CODAAccountsPayableControl__c = gla1.Id;
        update(a);
            
            c2g__codaPurchaseInvoice__c pi = new c2g__codaPurchaseInvoice__c();
            c2g__codaPurchaseInvoiceExpenseLineItem__c pel = new c2g__codaPurchaseInvoiceExpenseLineItem__c();
            c2g__codaPurchaseInvoiceLineItem__c pil = new c2g__codaPurchaseInvoiceLineItem__c();
            pi.c2g__AccountInvoiceNumber__c = 'PAYINVTEST1';
            pi.c2g__Account__c = a.Id;
            pi.Source__c = 'PB';
            pi.c2g__Dimension1__c = dim1.Id;
            //BLL6d pi.ffap__CopyAccountValues__c = false;
            pi.c2g__CopyAccountValues__c = false;
            insert(pi);
            pel.Control__c = 'TestPurchExpLine 1';
            pel.c2g__GeneralLedgerAccount__c = 
            pel.c2g__Dimension1__c = dim1.Id;  
            pel.c2g__GeneralLedgerAccount__c = gla1.Id;
            pel.c2g__NetValue__c = 1.00;
            pel.ffap__SetGLAToDefault__c = false;
            pel.c2g__SetGLAToDefault__c = false;
            pel.c2g__PurchaseInvoice__c = pi.Id;
            insert(pel);
            //pil.Control__c = 'TestPurchLine 2';
            //pil.c2g__Quantity__c = 1;
            //pil.c2g__UnitPrice__c = 2.00;
            //pil.c2g__Dimension1__c = dim1.Id;  
            //pil.c2g__Product__c = prod.Id;  // requires product has c2g__CODAPurchaseAnalysisAccount__c filled in
            //pil.c2g__PurchaseInvoice__c = pi.Id;
            //insert(pil);
            
            c2g.CODAAPICommon.Reference cref = new c2g.CODAAPICommon.Reference();
            cref.Id = pi.Id;
            c2g.CODAAPIPurchaseInvoice_9_0.PostPurchaseInvoice(null, cref);
        } // BLL2a
    }
    
	// BLLxa
	static testmethod void TestControlNbrDft() {
        FFAdata.refresh(); 
        System.runAs(FFAdata.TestUser) {

	        List<c2g__codaGeneralLedgerAccount__c> glas = new List<c2g__codaGeneralLedgerAccount__c>();
	        glas.add(new c2g__codaGeneralLedgerAccount__c(
	        	c2g__ReportingCode__c ='12',
	        	c2g__Type__c='Balance Sheet',
	        	Name='Test'
	        ));
	        insert glas;

			List<c2g__codaJournal__c> jlist = new List<c2g__codaJournal__c>();
			jlist.add(new c2g__codaJournal__c(
				c2g__Reference__c = 'SIN123456',
				c2g__JournalDate__c = Date.today()
			));
			jlist.add(new c2g__codaJournal__c(
				c2g__Reference__c = null,
				c2g__JournalDate__c = Date.today()
			));
			jlist.add(new c2g__codaJournal__c(
				c2g__Reference__c = 'OTHER VALUE',
				c2g__JournalDate__c = Date.today()
			));
			jlist.add(new c2g__codaJournal__c(
				c2g__Reference__c = 'SCR123456 for SIN123456',
				c2g__JournalDate__c = Date.today()
			));
			jlist.add(new c2g__codaJournal__c(
				c2g__Reference__c = 'SIN012345',
				c2g__JournalDate__c = Date.today()
			));
			insert(jlist);
			
			List<c2g__codaJournalLineItem__c> jllist = new List<c2g__codaJournalLineItem__c>();
			jllist.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = jlist[0].Id,
				c2g__LineType__c = 'General Ledger Account',
				c2g__GeneralLedgerAccount__c = glas[0].Id,
				Control__c = null
			)); 
			jllist.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = jlist[1].Id,
				c2g__LineType__c = 'General Ledger Account',
				c2g__GeneralLedgerAccount__c = glas[0].Id,
				Control__c = null
			)); 
			jllist.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = jlist[2].Id,
				c2g__LineType__c = 'General Ledger Account',
				c2g__GeneralLedgerAccount__c = glas[0].Id,
				Control__c = null
			)); 
			jllist.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = jlist[3].Id,
				c2g__LineType__c = 'General Ledger Account',
				c2g__GeneralLedgerAccount__c = glas[0].Id,
				Control__c = null
			)); 
			jllist.add(new c2g__codaJournalLineItem__c(
				c2g__Journal__c = jlist[4].Id,
				c2g__LineType__c = 'General Ledger Account',
				c2g__GeneralLedgerAccount__c = glas[0].Id,
				Control__c = 'Something else'
			));
			Test.startTest();
			insert(jllist);
			Test.stopTest();
			 
			for(c2g__codaJournalLineItem__c jl : [select Id, c2g__Journal__c, Control__c, JournalReference__c from c2g__codaJournalLineItem__c]) {
				if (jl.JournalReference__c=='SIN123456') 
					System.assertEquals('SIN123456', jl.Control__c, 'Journal line did not get SIN# for control#');		
				if (jl.JournalReference__c==null) 
					System.assertEquals(null, jl.Control__c, 'Journal line control# did not remain empty');
				if (jl.JournalReference__c=='OTHER VALUE')		
					System.assertEquals(null, jl.Control__c, 'Journal line control# dir not remain empty for OTHER VALUE in reference');
				if (jl.JournalReference__c=='SCR123456 for SIN123456')		
					System.assertEquals('SCR123456', jl.Control__c, 'Journal line did not get SCR# for control#');
				if (jl.JournalReference__c=='SIN012345')		
					System.assertEquals('Something else', jl.Control__c, 'Journal line control# was changed from existing value');		
			}

        }
	}
	// BLLxa end
    
}