/**
 * GLAccountSchedule_TEST
 * Tests: GLAccountingSchedule_CTLR
 * Programmer: Bryan Leaman
 * Date: 2015-08-31
 * 
 * 	   Date   	Programmer	Comments
 * 	---------- 	----------	-------------------------------------------------------------------------------
 * 	2016-04-06	B. Leaman	BLL2 - updates related to using select2 drop-down.
 *	2016-06-02	B. Leaman	BLL3 - remove references to ffgl__ (for FFv14)
 */
@isTest

private class GLAccountSchedule_TEST {

    // BLL2a
    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

    @testSetup
    static void setupFFA() {
        TestHelper_MW.createBaseFFAData(FFAdata);
        System.runAs(FFAdata.TestUser) {
            
	        TestHelper_MW th = new TestHelper_MW();
            Account a = th.getPersonAccount('1');
          
	        c2g__codaGeneralLedgerAccount__c gla1 = new c2g__codaGeneralLedgerAccount__c();
	        gla1.c2g__ReportingCode__c ='12';
	        gla1.c2g__Type__c='Balance Sheet';
	        gla1.Name='12 - Test';
	        insert gla1;
	        c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c();
	        dim1.c2g__ReportingCode__c = '111';
	        dim1.Name = '111 Dim';
   		    insert(dim1);

            
            c2g__codaJournal__c newj = new c2g__codaJournal__c();
            newj.c2g__JournalDate__c =system.today();
            newj.Source__c ='GE';
            newj.c2g__Type__c='Manual Journal';
            //BLL3d newj.ffgl__DeriveCurrency__c=true;
            //BLL3d newj.ffgl__DerivePeriod__c=true;
            newj.c2g__JournalStatus__c='In Progress';
            newj.Customer__c = a.Id;
            insert(newj);
    
            List<c2g__codaJournalLineItem__c> newl = new List<c2g__codaJournalLineItem__c>();
            newl.add(new c2g__codaJournalLineItem__c());
            newl[0].c2g__Journal__c = newj.Id;
            newl[0].c2g__Value__c = 1.00;
            newl[0].c2g__GeneralLedgerAccount__c = gla1.Id;  
            newl[0].c2g__LineType__c = 'General Ledger Account'; 
            newl[0].c2g__LineNumber__c = 1;
            newl[0].Control__c = 'TestJournalLine 1';
            newl[0].Sales_Person__c = UserInfo.getUserId();
            newl[0].c2g__Dimension1__c = dim1.Id; 
            newl.add(new c2g__codaJournalLineItem__c());
            newl[1].c2g__Journal__c = newj.Id;
            newl[1].c2g__Value__c = -1.00;
            newl[1].c2g__GeneralLedgerAccount__c = gla1.Id;  
            newl[1].c2g__LineType__c = 'General Ledger Account'; 
            newl[1].c2g__LineNumber__c = 2;
            newl[1].Control__c = 'TestJournalLine 2';
            newl[1].c2g__Dimension1__c = dim1.Id; 
            insert(newl);
            
            c2g.CODAAPICommon.Reference ref = new c2g.CODAAPICommon.Reference();
            ref.Id = newj.Id;
            c2g.CODAAPIJournal_9_0.PostJournal(null, ref);
        }
    }     
	// BLL2a end

    static testMethod void testController() {
        FFAdata.refresh();	// BLL2a 
    
    	//BLL2d begin
        //c2g__codaGeneralLedgerAccount__c cgd = new c2g__codaGeneralLedgerAccount__c();
        //cgd.c2g__ReportingCode__c ='52';
        //cgd.c2g__Type__c='Manual Journal';
        //cgd.Name='Test';
        //insert cgd;
        
        //c2g__codaDimension1__c cdm1 = new c2g__codaDimension1__c();
        //cdm1.Name ='Test';
        //cdm1.c2g__ReportingCode__c ='Test';
        //insert cdm1; 
        //c2g__codaCompany__c comp = new c2g__codaCompany__c();
        //comp.Name = 'Test';
        //comp.c2g__CODADescription1__c ='Test';
        //insert comp;  
    	//c2g__codaTransactionLineItem__c trn = New c2g__codaTransactionLineItem__c();
   		//trn.c2g__GeneralLedgerAccount__c=cgd.id;
   		//trn.c2g__Dimension1__c=cdm1.id;
   		//trn.c2g__LineNumber__c=12;
   		//trn.c2g__HomeValue__c=11;
   		//trn.c2g__OwnerCompany__c=comp.id;
   		//insert trn;       
        //BLL2d end
            
		//c2g__codaDimension1__c cgd1 = new c2g__codaDimension1__c();
		//    cgd1.c2g__ExternalId__c='Test';
		//    cgd1.c2g__ReportingCode__c='Test';
		//    cgd1.c2g__UnitOfWork__c =12;
		//    insert cgd1;
    
		//c2g__codaTransactionLineItem__c trn = new c2g__codaTransactionLineItem__c();
		//trn.c2g__LineNumber__c=12;
		//trn.c2g__HomeValue__c=11;
		//trn.c2g__Dimension1__c=cgd1.id;
		//insert trn;

		c2g__codaTransactionLineItem__c trn = [
			select Id, Name, c2g__GeneralLedgerAccount__c, c2g__GeneralLedgerAccount__r.Name, c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c, 
				c2g__Dimension1__c, c2g__Dimension1__r.Name, c2g__Dimension1__r.c2g__ReportingCode__c, Transaction_Date__c,
				c2g__LineNumber__c, c2g__HomeValue__c, c2g__OwnerCompany__c, Control__c, c2g__Account__c, c2g__Account__r.Name,  
				c2g__Transaction__r.Source__c, c2g__Transaction__r.Name, c2g__LineReference__c, c2g__LineDescription__c
			from c2g__codaTransactionLineItem__c
			limit 1
		]; 

        Test.startTest();

        PageReference pgRef = Page.GLAccountSchedule; 
        Test.setCurrentPage(pgRef); //Set the page for Test Method
        //ApexPages.currentPage().getParameters().put('id', lead.id);

        GLAccountSchedule_CTLR ctlr = new GLAccountSchedule_CTLR();
        //ctlr.lookupd.c2g__GeneralLedgerAccount__c = trn.c2g__GeneralLedgerAccount__c;
        //ctlr.lookupd.c2g__Dimension1__c = trn.c2g__Dimension1__c;
        //ctlr.selectedGLAcctIds.add(trn.c2g__GeneralLedgerAccount__c);
        //ctlr.selectedDim1Ids.add(trn.c2g__Dimension1__c);
        //BLL1d ctlr.selectedGLAcct.add(new SelectOption(trn.c2g__GeneralLedgerAccount__c, 'TestAcct'));
        //BLL1d ctlr.selectedDim1.add(new SelectOption(trn.c2g__Dimension1__c, 'TestDim1'));
        ctlr.selectedGLAcctIds.add(trn.c2g__GeneralLedgerAccount__c);	// BLL1a
        ctlr.selectedDim1Ids.add(trn.c2g__Dimension1__c);	// BLL1a
        ctlr.lookuph.c2g__JournalDate__c = Date.today();
        ctlr.validateInputs();
        ApexPages.PageReference xlspage = ctlr.downloadXLS();
        ctlr.getReport();
        ctlr.getPrintPdfUrl();
        ctlr.downloadPDF();
        ctlr.noAction();
         GLAccountSchedule_CTLR.ScheduleLine ctlrs = new GLAccountSchedule_CTLR.ScheduleLine(trn);
         GLAccountSchedule_CTLR.ScheduleLine ctlrs2 = new GLAccountSchedule_CTLR.ScheduleLine(ctlrs,11.0,12.0);
        // ctlrs.ScheduleLine();
        // ctlrs.ScheduleLine(,11.0,12.0);
        //List<ctr.ScheduleLine> lines = ctlr.getReport();
        //if (lines.size()>0) {
        //  ctlr.ScheduleLine line = lines[0];
        //  String v;
        //  Decimal d;
        //  Date dat;
        //  v = line.getTrnDate();
        //  v = line.getTrnLineReference();
        //  v = line.getTrnLineDescription();
        //  v = line.getGlaName();
        //  v = line.getGlaReportingCode();
        //  v = line.getAccountName();
        //  d = line.getTrnValue();
        //  d = line.getControlTotal();
        //  dat = line.getCrtDate();
        //}

        Test.stopTest();

    }
    
    
    static testMethod void testBatchXLS() {
    	c2g__codaTransactionLineItem__c trn = [
			select Id, Name, c2g__GeneralLedgerAccount__c, c2g__GeneralLedgerAccount__r.Name, c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c, 
				c2g__Dimension1__c, c2g__Dimension1__r.Name, c2g__Dimension1__r.c2g__ReportingCode__c, Transaction_Date__c,
				c2g__LineNumber__c, c2g__HomeValue__c, c2g__OwnerCompany__c, Control__c, c2g__Account__c, c2g__Account__r.Name,  
				c2g__Transaction__r.Source__c, c2g__Transaction__r.Name, c2g__LineReference__c, c2g__LineDescription__c
			from c2g__codaTransactionLineItem__c
			limit 1
		]; 
    	GLAccountScheduleXLSBatch ba = new GLAccountScheduleXLSBatch('1', Date.today(), true, new List<Id>{trn.c2g__GeneralLedgerAccount__c}, new List<Id>());
    	Database.executeBatch(ba);
    }

}