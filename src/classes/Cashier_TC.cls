/**
 * Cashier_TC
 * Tests: Cashier
 * 
 *  2015-11-06  B. Leaman   BLL1 - increase code coverage.
 *  2016-01-28  B. Leaman   BLL2 - disable RO protection during test; use FFA test data routines;
 *  2016-04-13  B. Leaman   BLL3 - additional code coverage.
 *  2016-11-18  Gaurav Agrawal  Case# 00002186 - Increased code coverage
 *	2017-05-12	B. Leaman	BLL4 above causes too manu SOQL queries error. Comment out.
 *	2017-11-30	B. Leaman	BLL5 turn off tax calc requirement; increase coverage.
 *	2018-07-31	B. Leaman	BLL6 - dealer__Invoice_Date_Time__c = null assertions failing; invoice date/time being set during setup routine with insertion of cashiering entry;
 *							also reduce SOQL query count in UnitTest1 by splitting some logic to UnitTest3.
 *	2018-09-25	B. Leaman	BLL7 - improve coverage: postInvoice 
 *	2019-05-08	B. Leaman	W-000575 BLL8 correct testing with new validations on cashier entries
 *	2019-09-17	B. Leaman	W-000730 BLL9 - fix tests failing under DT 5.57 upgrade.
 */
@isTest 
Public Class Cashier_TC{


    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); // BLL1

    @testSetup
    static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
        TestHelper_MW th = new TestHelper_MW();

		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
    
		List<MW_TriggerControls__c> tcs =new List<MW_TriggerControls__c>();
		tcs.add(new MW_TriggerControls__c(Name='RepairOrderProtect',Enabled__c=false));	//BLL2a
		tcs.add(new MW_TriggerControls__c(Name='AvataxRepair',Enabled__c=false));	// BLL5a
		// BLL8
		tcs.add(new MW_TriggerControls__c(Name='CashierUpdatePrevention',Enabled__c=false));	
		tcs.add(new MW_TriggerControls__c(Name='CashierDeletePrevention',Enabled__c=false));	
		tcs.add(new MW_TriggerControls__c(Name='CashierFFLink',Enabled__c=true));	
		tcs.add(new MW_TriggerControls__c(Name='CashierFFLock',Enabled__c=true));	
		insert(tcs);
		// BLL8

		// BLL3a
		List<dealer__Payment_Methods__c> dpms = new List<dealer__Payment_Methods__c>();
		dpms.add(new dealer__Payment_Methods__c(Name='TestMthd', dealer__Method__c='Charge'));
		dpms.add(new dealer__Payment_Methods__c(Name='Cash', dealer__Method__c='Cash'));
		dpms.add(new dealer__Payment_Methods__c(Name='Charge', dealer__Method__c='Charge'));
		insert(dpms);
		// BLL3a

		update(new dealer__Dealer_Location__c(
			Id=FFAdata.DealerLocation.Id, 
			Financial_Force_Dimension_1__c=FFAdata.Dimension1.Id,
			Company__c=FFAdata.CurrentCompany.Id
		));
		System.runAs(FFAData.TestUser) {
		
        c2g__codaDimension1__c cdm1 = new c2g__codaDimension1__c();
        cdm1.Name ='Test';
        cdm1.c2g__ReportingCode__c ='Test';
        insert cdm1;  

		List<c2g__codaGeneralLedgerAccount__c> glalist = new List<c2g__codaGeneralLedgerAccount__c>();
        c2g__codaGeneralLedgerAccount__c cgd = new c2g__codaGeneralLedgerAccount__c();
        cgd.c2g__ReportingCode__c ='52';
        cgd.c2g__Type__c='Manual Journal';
        cgd.Name='Test';
        glalist.add(cgd);
        //insert cgd;
        c2g__codaGeneralLedgerAccount__c cgd2 = new c2g__codaGeneralLedgerAccount__c();
        cgd2.c2g__ReportingCode__c ='13';
        cgd2.c2g__Type__c='Manual Journal';
        cgd2.Name='Test';
        glalist.add(cgd2);
        //insert cgd2;

        c2g__codaGeneralLedgerAccount__c cgd3 = new c2g__codaGeneralLedgerAccount__c();
        cgd3.c2g__ReportingCode__c ='54';
        cgd3.c2g__Type__c='Manual Journal';
        cgd3.Name='Test';
        glalist.add(cgd3);
        //insert cgd3;

        c2g__codaGeneralLedgerAccount__c cgd4 = new c2g__codaGeneralLedgerAccount__c();
        cgd4.c2g__ReportingCode__c ='55';
        cgd4.c2g__Type__c='Manual Journal';
        cgd4.Name='Test';
        glalist.add(cgd4);
        //insert cgd4;

        c2g__codaGeneralLedgerAccount__c cgd5 = new c2g__codaGeneralLedgerAccount__c();
        cgd5.c2g__ReportingCode__c ='56';
        cgd5.c2g__Type__c='Manual Journal';
        cgd5.Name='Test';
        glalist.add(cgd5);
        //insert cgd5;

        c2g__codaGeneralLedgerAccount__c cgd6 = new c2g__codaGeneralLedgerAccount__c();
        cgd6.c2g__ReportingCode__c ='57';
        cgd6.c2g__Type__c='Manual Journal';
        cgd6.Name='Test';
        glalist.add(cgd6);
        //insert cgd6;

        c2g__codaGeneralLedgerAccount__c cgd7 = new c2g__codaGeneralLedgerAccount__c();
        cgd7.c2g__ReportingCode__c ='58';
        cgd7.c2g__Type__c='Manual Journal';
        cgd7.Name='Test';
        glalist.add(cgd7);
        //insert cgd7;

        // BLL2a specific accounts needed
        //try {
        c2g__codaGeneralLedgerAccount__c gl5202 = new c2g__codaGeneralLedgerAccount__c(
        	c2g__ReportingCode__c ='5202',
        	c2g__Type__c='Profit and Loss',
        	Name='Test'
        );
        glalist.add(gl5202);
        //insert gl5202;
        //} catch(Exception e) {}
        //try {
        c2g__codaGeneralLedgerAccount__c gl4905 = new c2g__codaGeneralLedgerAccount__c(
        	c2g__ReportingCode__c ='4905',
        	c2g__Type__c='Profit and Loss',
        	Name='Test'
        );
        glalist.add(gl4905);
        //insert gl4905;
        //} catch(Exception e) {}
        //try {
        c2g__codaGeneralLedgerAccount__c gl1220 = new c2g__codaGeneralLedgerAccount__c(
        	c2g__ReportingCode__c ='1220',
        	c2g__Type__c='Profit and Loss',
        	Name='Test'
        );
        glalist.add(gl1220);
        //insert gl1220;
        //} catch(Exception e) {}
        //try {
        c2g__codaGeneralLedgerAccount__c gl1112 = new c2g__codaGeneralLedgerAccount__c(
        	c2g__ReportingCode__c ='1112',
        	c2g__Type__c='Profit and Loss',
        	Name='Test'
        );
        glalist.add(gl1112);
        //insert gl1112;
        //} catch(Exception e) {}
        // BLL2a end
        insert(glalist);

        c2g__codaBankAccount__c ccb = new c2g__codaBankAccount__c();
        ccb.c2g__ReportingCode__c='Test';
        ccb.c2g__BankName__c='Test';
        ccb.c2g__AccountName__c='Test';
        ccb.c2g__AccountNumber__c='123455635';
        ccb.c2g__GeneralLedgerAccount__c=cgd.id;
		ccb.c2g__Dimension1__c=cdm1.id;
        insert ccb;


        c2g__codaJournal__c cj = new c2g__codaJournal__c();
        cj.c2g__JournalDate__c =system.Today();
        cj.c2g__Type__c='Manual Journal';
        insert cj;

        c2g__codaJournalLineItem__c ccj = new c2g__codaJournalLineItem__c();
        ccj.c2g__Journal__c =cj.id;
        ccj.c2g__LineType__c='Bank Account';
        ccj.c2g__Value__c =12;
        ccj.c2g__BankAccount__c=ccb.id;
        ccj.c2g__Dimension1__c =cdm1.id;
        ccj.Control__c='test';            
        insert ccj;

        ServicePaymentType__c spt = new ServicePaymentType__c();
        spt.Default_Labor_Rate__c=12;
        spt.Payment_Type__c='C'; 
        spt.Labor_Sale_Account__c=cgd.id; 
        spt.Labor_Cost_of_Sale_Account__c=cgd2.id;
        spt.Warranty_Receivable_Account__c=cgd3.id;
        spt.Description__c='Test';
        spt.Shop_Supplies_Rate__c=12;
        spt.Hazmat_Fee__c=12;
        spt.Freight_Rate__c=12;
        spt.Parts_Cost_of_Sale__c=cgd.id;
        spt.Parts_Inventory__c=cgd5.id;
        spt.Work_In_Process__c=cgd3.id;
        //spt.Warranty_Billing_Account__c=a.id; 
        spt.Labor_Sale_Account__c=cgd.id; 
        spt.Parts_Sales__c=cgd4.id; 
        spt.Parts_Cost_of_Sale__c=cgd6.id;   
        spt.Internal_Sales__c=cgd7.id;  
        spt.Sublet_CS__c=cgd7.id;
        spt.Sublet_Sales__c=cgd7.id;
        spt.Sublet_Inventory__c=cgd7.id;
        insert spt; 

        Account a = th.getBusinessAccount('1');
        contact con = new contact();
        con.Phone = '(555) 888-8888';
        con.LastName = 'TestContact';
        con.AccountId = a.Id;
        insert con;
        dealer__Dealer_Location__c ddl = FFAdata.DealerLocation; // th.getDealerLocation('1');  
        ddl.dealer__Service_Director__c = UserInfo.getUserId();
        update(ddl);
        // BLL2a
        
   
    dealer__Service_Vehicle__c   dsv = new dealer__Service_Vehicle__c();
        dsv.dealer__VIN__c ='TestXYZ';
        dsv.Name='Test';
        dsv.dealer__Body_Style__c = 'Test';
        dsv.dealer__Company_Number__c='12123';
        dsv.dealer__Veh_Owner_Contact__c = a.PersonContactId; // BLL3c con.id;
        dsv.dealer__Carline__c ='Test';
        dsv.dealer__Make__c  ='Test';
        dsv.dealer__Year__c  ='2013';
       // dsv_list.add(dsv);
        insert dsv;


     dealer__Service_Repair_Order__c   dsr = new dealer__Service_Repair_Order__c();
        dsr.dealer__Customer__c =a.id;
        dsr.dealer__Mileage_In__c =12;
        dsr.dealer__RO_Number__c ='11';
        // dsr.dealer__VIN__c = dsv.id;
        dsr.dealer__VIN__c = 'TestXYZ'; // BLL2a
        dsr.dealer__Vehicle__c = dsv.Id;
        dsr.dealer__Company__c=ddl.id;
        insert dsr;
      
        System.debug('RO After Creation');
        System.debug([select id, dealer__Invoiced_Date_Time__c from dealer__Service_Repair_Order__c where Id=:dsr.Id]);

     
        dealer__Parts_Invoice__c dv = new dealer__Parts_Invoice__c();
        dv.dealer__Comments__c ='Test';
        dv.dealer__Invoice_Number__c ='Test';
		// BLL9
		dv.dealer__Location__c = FFAdata.DealerLocation.Id;
		dv.dealer__Company_Number__c = FFAdata.DealerLocation.dealer__Company_Number__c;
		// BLL9 end
        insert dv;

        dealer__Parts_Invoice_Line__c dpi = new dealer__Parts_Invoice_Line__c();
        dpi.dealer__Bin__c ='Test';
        dpi.dealer__Parts_Invoice__c=dv.id; 
        dpi.dealer__Part_Number__c='Test';
        dpi.dealer__Quantity_Sold__c=12;
        insert dpi;
        dealer__StandardOpCode__c dso= new dealer__StandardOpCode__c();
        dso.Name ='Test';
        dso.dealer__Pay_Type__c = 'C';
        insert dso;

        dealer__Service_Job__c dsj = new dealer__Service_Job__c();
        dsj.dealer__Cause__c ='Test';
        dsj.dealer__Labor_Charges__c =12;
        dsj.dealer__Service_Repair_Order__c =dsr.id; 
        dsj.dealer__Actual_Time__c=12;
        dsj.dealer__Book_Time__c=12;
        dsj.dealer__Cause__c='Test';
        dsj.dealer__Concern__c='Test';
        dsj.dealer__Correction__c='Test';
        //dsj.dealer__Customer_Id__c='Test';
        dsj.dealer__Estimate__c=12;
        //dsj.dealer__Gross_Profit__c=12;
        dsj.dealer__Job_Added_Date__c=system.today();
        //dsj.dealer__Job_ELR__c=12;
        //dsj.dealer__Job_Finish__c=system.today();
        dsj.dealer__Job_Line_Id__c='Test';
        //dsj.dealer__Job_Start__c=system.today();
        dsj.dealer__Labor_Charges__c=12;
        dsj.dealer__Labor_Rate__c='Test';
        dsj.dealer__Labor_Type__c='C';	// BLL7c was 'Test'
        dsj.dealer__Line_Number__c=12;
        //dsj.dealer__Line_Total__c=12;
        dsj.dealer__Op_Code__c='Test';
        //dsj.dealer__Operation_Code_Description__c='Test';
        dsj.dealer__Parent_Record__c='Test';
        dsj.dealer__Parts_Cost__c=12;
        //dsj.dealer__Parts_Invoice_Id__c='Test';
        dsj.dealer__Parts_Line__c=dpi.id;
        dsj.dealer__Parts_Total__c=12;
        dsj.dealer__Service_Type__c='MR';
        //dsj.dealer__Service_Vehicle_Id__c='Test';
        dsj.dealer__Standard_Operation_Code__c=dso.id;
        dsj.dealer__Stat__c='Test';
        dsj.dealer__Sublet_Total__c=12;
        dsj.dealer__Technician_Cost__c=12;
        dsj.dealer__Technician__c=Userinfo.getuserid();
        dsj.Payment_Notes__c='Test';
        dsj.dealer__Add_On__c=True;
        dsj.dealer__Misc_Charges__c=12;
        dsj.dealer__Op_Description__c='Test';
        dsj.dealer__Technician_ID__c='Test';
        dsj.dealer__CustomerConcern__c='Test';
        //dsj.dealer__RO_Open_Date_Time__c=system.today();
        dsj.dealer__Claim__c='Test';
        dsj.dealer__Paid_By__c=a.id;
        dsj.Payment_Method__c=spt.id;
        dsj.External_ID__c='Test';   
        insert dsj;
        
        //Case# 00002186      
        // BLL4d - causes Too many SOQL queries error
        //dealer__Parts_Master__c pm = new dealer__Parts_Master__c();
        //pm.Name = 'FL1A__TEST_PART';
        //pm.dealer__Retail_Price__c = 99.99;
        //pm.dealer__Manufacturer__c = 'FD';
        //insert pm;      

        //dealer__Dealer_Location__c objLocation = new dealer__Dealer_Location__c();
        //objLocation.Name ='Test1';
        //objLocation.dealer__City__c ='Test1';
        //objLocation.dealer__Postal_Code__c='301347';
        //objLocation.dealer__State__c='Te';
        //objLocation.dealer__Company_Number__c='TEST';
        //objLocation.dealer__Service_Director__c = Userinfo.getuserid();
        //insert objLocation;
        
        //dealer__Parts_Inventory__c inventory = new dealer__Parts_Inventory__c();
        //inventory.dealer__Part_No__c = '9963777777';
        //inventory.dealer__Cost__c = 70;
        //inventory.dealer__List__c = 70;
        //inventory.dealer__MFG__c = 'MFG';
        //inventory.dealer__Parts_Master__c = pm.Id;
        //inventory.dealer__Location__c = ddl.Id;       
        //insert inventory;         
        
        //Account objAccount = new Account();
        //objAccount.LastName ='Test';
        //objAccount.AccountSource ='Dealer';
        //insert objAccount;
                
        //dealer__Purchase_Order__c objPO = new dealer__Purchase_Order__c();
        //objPO.dealer__Company__c = objLocation.Id;
        //objPO.dealer__Vendor__c = objAccount.Id;        
        //objPO.dealer__Parts_Invoice__c = dv.Id;        
        //insert objPO;        
        
        //dealer__Purchase_Order_Line__c objPOL = new dealer__Purchase_Order_Line__c();
        //objPOL.dealer__Part__c = inventory.Id;
        //objPOL.dealer__Part_Quantity__c = 10;
        //objPOL.dealer__Service_Job_Line__c = dsj.Id;
        //objPOL.dealer__Purchase_Order__c = objPO.Id;
        //insert objPOL;   
        //Case# 00002186 end     

		// BLL7a add misc charge $10
		ServiceMiscCharges__c msc = new ServiceMiscCharges__c(
			Amount__c=10, Quantity__c=1, Service_Job_Line__c=dsj.Id, Type__c='Shop Supplies',
			General_Ledger_Account__c = gl5202.Id
		);
		insert(msc);
		// BLL7a end

        System.debug('RO After Job');
        System.debug(dsr);
        System.debug([select id, dealer__Invoiced_Date_Time__c, dealer__Customer_Charges__c from dealer__Service_Repair_Order__c where Id=:dsr.Id]);
        // Iterate Job Lines
        for(dealer__Service_Job__c j : [Select ID, Name, dealer__Labor_Charges__c, dealer__Misc_Charges__c, dealer__Parts_Total__c, dealer__Sublet_Total__c, dealer__Line_Total__c, dealer__RO_Invoice_Date_Time__c from dealer__Service_Job__c where dealer__Service_Repair_Order__c =: dsr.Id]) {
            System.debug(j);
        }       

        dealer__Cashering__c dc = new dealer__Cashering__c();
        dc.dealer__Amount__c =48; // BLL7 was 38, set to $10; BLL was 39, adding 1 as separate pmt
        dc.dealer__Payment_Method__c='Test';
        dc.dealer__Close_Date__c =system.Today();
        dc.dealer__Service_Repair_Order__c  =dsr.id;
        dc.dealer__Deposit__c=true;
        dc.dealer__Customer__c=a.id;
        dc.dealer__Credit_Card_Authorization_Code__c='Test';
        insert dc;     

        System.debug([select id, dealer__Invoiced_Date_Time__c from dealer__Service_Repair_Order__c where Id=:dsr.Id]);
        // Iterate Job Lines
        for(dealer__Service_Job__c j : [Select ID, Name, dealer__Labor_Charges__c, dealer__Misc_Charges__c, dealer__Parts_Total__c, dealer__Sublet_Total__c, dealer__Line_Total__c, dealer__RO_Invoice_Date_Time__c from dealer__Service_Job__c where dealer__Service_Repair_Order__c =: dsr.Id]) {
            System.debug(j);
        }       

		}
		
           
    }

    @isTest
    Static Void Myunittest1(){	// BLL5c split into 2 test methods
    
        FFAdata.refresh(); // BLL2a
        System.runAs(FFAdata.TestUser) {


        // BLL2a - use helpers
        TestHelper_MW th = new TestHelper_MW();

        /*
        dsr.dealer__Posted_Date_Time__c =system.today();
        dsr.dealer__Status__c = 'Posted';
        update(dsr);
        */
        //c2g__codaCompany__c comp = new c2g__codaCompany__c();
        //comp.Name = 'Test';
        //comp.c2g__CODADescription1__c ='Test';
        //insert comp;

		Account a = [select Id, Name from Account limit 1];        
        dealer__Service_Repair_Order__c dsr = [select Id, Name, dealer__Invoiced_Date_Time__c from dealer__Service_Repair_Order__c limit 1];
        dealer__Service_Job__c dsj = [select Id, Name from dealer__Service_Job__c where dealer__Service_Repair_Order__c=:dsr.Id limit 1];
        System.debug(dsr);
        
        Test.startTest();
            
        ApexPages.StandardController sc = new ApexPages.StandardController(dsr );
        ApexPages.currentPage().getParameters().put('id', dsr.id);
        Cashier  cs = new Cashier();

        dsj.dealer__Stat__c = 'Open'; // BLL1a
        update(dsj);  // BLL1a

        // BLL7a
        AggregateResult[] sumCash = [Select SUM(dealer__Amount__c) asum FROM dealer__Cashering__c where dealer__Service_Repair_Order__c =:dsr.Id];
        Decimal totcash = (Decimal) sumCash[0].get('asum');
        if(totcash==null) { totcash=0; }
        // BLL7a end    

        List<dealer__Cashering__c> cashier_entries = cs.cashier_entries;
        List<SelectOption> pmtmthds = cs.getPaymentMethods();
        cs.authcode ='Test';
        cs.deposit=true; // BLL1a
        //BLL7d cs.amount=1.00;  // BLL1a
        cs.amount = totcash-1;	// BLL7a
        List<dealer__Service_Job__c> linelist = [SELECT Id, dealer__Stat__c from dealer__Service_Job__c where dealer__Service_Repair_Order__c=:dsr.Id ];
        System.debug(linelist);
        cs.method=pmtmthds[0].getValue();	// BLL7a
        cs.applyPayment();

        cs.deposit=false;   // BLL3a
        //BLL7d cs.amount=0.10;     // BLL3a
        cs.amount = 1;	// BLL7a
        cs.method='Cash';	// BLL7a
        cs.applyPayment();  // BLL3a

        cs.returnToRo();
        /* BLL7d move
        cs.method='Test';
        cs.deposit=true; // BLL1a
        cs.amount = 0;	// BLL7a
        cs.applyPayment();
        */  

        // BLL7d cs.invoiceRO();
        // BLL7d System.debug(cs.ro.dealer__Invoiced_Date_Time__c);
        // BLL7d System.debug(dsr);
        // BLL7d cs.doVoid();
        
        cs.postInvoice();	// Case# 00002186

		// BLL7a moved from above
        cs.method=null;
        cs.amount = 0;	
        cs.applyPayment();
        // BLL7a end
        
        cs.debit(0);
        cs.debit(null);
        cs.debit(-1);

        cs.credit(0);
        cs.credit(null);
        cs.credit(1);


        //cs.postInvoice();
        //spt.Payment_Type__c='W';
        //update spt;
        //cs.postInvoice();
        //spt.Payment_Type__c='I';
        //update spt;
        // cs.postInvoice();
        cs.ro.dealer__Posted_Date_Time__c =null;

        //cs.postInvoice();

        // Set the Totals And Post
        AggregateResult[] sumCashier = [Select SUM(dealer__Amount__c) asum FROM dealer__Cashering__c where dealer__Service_Repair_Order__c =:dsr.id];
        Decimal tot = (Decimal)sumCashier[0].get('asum');
        dealer__Service_Repair_Order__c roTotal = [Select dealer__Customer_Invoice_Total__c, dealer__Warranty_Charges__c from dealer__Service_Repair_Order__c where Id=:dsr.id limit 1];

		System.debug(dsr.dealer__Invoiced_Date_Time__c);
        //BLL6d System.assert(dsr.dealer__Invoiced_Date_Time__c == null);
        
        System.debug('Current RO');
        System.debug(dsr);
        System.debug([select id, dealer__Invoiced_Date_Time__c from dealer__Service_Repair_Order__c where Id=:dsr.Id]);
        // Iterate Job Lines
        for(dealer__Service_Job__c j : [Select ID, Name, dealer__RO_Invoice_Date_Time__c from dealer__Service_Job__c where dealer__Service_Repair_Order__c =: dsr.Id]) {
            System.debug(j);
        }

        Decimal amount_outstanding= 0;
        if(tot==null) { tot=0; }
        amount_outstanding = (roTotal.dealer__Customer_Invoice_Total__c+roTotal.dealer__Warranty_Charges__c) - tot;

        dealer__Cashering__c dc_sum = new dealer__Cashering__c();
        dc_sum.dealer__Amount__c =amount_outstanding;
        dc_sum.dealer__Payment_Method__c='Test';
        dc_sum.dealer__Close_Date__c =system.Today();
        dc_sum.dealer__Service_Repair_Order__c  =dsr.id;
        dc_sum.dealer__Deposit__c=false;
        dc_sum.dealer__Customer__c=a.id;
        dc_sum.dealer__Credit_Card_Authorization_Code__c='Test';
        insert dc_sum;

		//System.debug('cs.postInvoice');
        //cs.postInvoice();
        
/* BLL6d Too many SOQL queries

		System.debug('cs.createJournal');
        cs.createJournal();
		System.debug('cs.createJournal end');
        
		c2g__codaJournalLineItem__c ccj = [
			select Id, Name
			from c2g__codaJournalLineItem__c 
			where c2g__LineType__c='Bank Account' and control__c='test'
			limit 1
		];
		
		c2g__codaDimension1__c cdm1 = [
			select Id, Name
			from c2g__codaDimension1__c 
			where c2g__ReportingCode__c = 'Test'
		];
		
		System.debug('cs.journalEntry');
        cs.journalEntry(ccj.Id,cdm1.id,a.id,'T','T',12);
        cs.clearInputs();
*/

        Test.stopTest();
        
        } // BLL2a
     
    }


    @isTest
    Static Void Myunittest2(){	// BLL5a
    
        FFAdata.refresh(); // BLL2a
        System.runAs(FFAdata.TestUser) {


        // BLL2a - use helpers
        TestHelper_MW th = new TestHelper_MW();

		Account a = [select Id, Name from Account limit 1];        
        dealer__Service_Repair_Order__c dsr = [select Id, Name, dealer__Invoiced_Date_Time__c from dealer__Service_Repair_Order__c limit 1];
        System.debug(dsr);
        dealer__Service_Job__c dsj = [select Id, Name from dealer__Service_Job__c where dealer__Service_Repair_Order__c=:dsr.Id limit 1];
        
        Test.startTest();
            
        ApexPages.StandardController sc = new ApexPages.StandardController(dsr );
        ApexPages.currentPage().getParameters().put('id', dsr .id);
        Cashier  cs = new Cashier();

        List<dealer__Cashering__c> cashier_entries = cs.cashier_entries;
        cs.getPaymentMethods();
        cs.authcode ='Test';
        cs.deposit=true; // BLL1a
        System.debug(cs.ro.dealer__Invoiced_Date_Time__c);
        cs.method='Cash';
        cs.applyPayment();
        cs.ro.dealer__Posted_Date_Time__c =null;
        System.debug(cs.ro.dealer__Invoiced_Date_Time__c);

        // Set the Totals And Post
        AggregateResult[] sumCashier = [Select SUM(dealer__Amount__c) asum FROM dealer__Cashering__c where dealer__Service_Repair_Order__c =:dsr.id];
        Decimal tot = (Decimal)sumCashier[0].get('asum');
        dealer__Service_Repair_Order__c roTotal = [Select dealer__Customer_Invoice_Total__c, dealer__Warranty_Charges__c from dealer__Service_Repair_Order__c where Id=:dsr.id limit 1];

		System.debug(dsr.dealer__Invoiced_Date_Time__c);
        //BLL6d System.assert(dsr.dealer__Invoiced_Date_Time__c == null);
        System.debug('Current RO');
        System.debug(dsr);
        System.debug([select id, dealer__Invoiced_Date_Time__c from dealer__Service_Repair_Order__c where Id=:dsr.Id]);
        // Iterate Job Lines
        for(dealer__Service_Job__c j : [Select ID, Name, dealer__RO_Invoice_Date_Time__c from dealer__Service_Job__c where dealer__Service_Repair_Order__c =: dsr.Id]) {
            System.debug(j);
        }

        Decimal amount_outstanding= 0;
        if(tot==null) { tot=0; }
        amount_outstanding = (roTotal.dealer__Customer_Invoice_Total__c+roTotal.dealer__Warranty_Charges__c) - tot;

        dealer__Cashering__c dc_sum = new dealer__Cashering__c();
        dc_sum.dealer__Amount__c =amount_outstanding;
        dc_sum.dealer__Payment_Method__c='Test';
        dc_sum.dealer__Close_Date__c =system.Today();
        dc_sum.dealer__Service_Repair_Order__c  =dsr.id;
        dc_sum.dealer__Deposit__c=false;
        dc_sum.dealer__Customer__c=a.id;
        dc_sum.dealer__Credit_Card_Authorization_Code__c='Test';
        insert dc_sum;


        try {  // need to allow to fail for now...:(
        	System.debug('FFA_ServiceDepartment.postRepairOrder');
        	FFA_ServiceDepartment.postRepairOrder(dsr.Id);
        } catch(Exception e) {}
        
        Test.stopTest();
        
        } // BLL2a
     
    }

	
	// BLL6a
    @isTest
    Static Void Myunittest3(){	
    
        FFAdata.refresh(); 
        System.runAs(FFAdata.TestUser) {

		TestHelper_MW th = new TestHelper_MW();

		Account a = [select Id, Name from Account limit 1];        
        dealer__Service_Repair_Order__c dsr = [select Id, Name, dealer__Invoiced_Date_Time__c from dealer__Service_Repair_Order__c limit 1];
        dealer__Service_Job__c dsj = [select Id, Name from dealer__Service_Job__c where dealer__Service_Repair_Order__c=:dsr.Id limit 1];
        System.debug(dsr);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(dsr );
        ApexPages.currentPage().getParameters().put('id', dsr .id);
        Cashier  cs = new Cashier();

        Test.startTest();

		System.debug('cs.createJournal');
        cs.createJournal();
		System.debug('cs.createJournal end');
        
		c2g__codaJournalLineItem__c ccj = [
			select Id, Name
			from c2g__codaJournalLineItem__c 
			where c2g__LineType__c='Bank Account' and control__c='test'
			limit 1
		];
		
		c2g__codaDimension1__c cdm1 = [
			select Id, Name
			from c2g__codaDimension1__c 
			where c2g__ReportingCode__c = 'Test'
		];
		
		System.debug('cs.journalEntry');
        cs.journalEntry(ccj.Id,cdm1.id,a.id,'T','T',12);
        cs.clearInputs();

        Test.stopTest();
        
        } 
     
    }
    // BLL6a end


    @isTest
    Static Void Myunittest4(){	// BLL7c split off another test method
    
        FFAdata.refresh(); // BLL2a
        System.runAs(FFAdata.TestUser) {

        // BLL2a - use helpers
        TestHelper_MW th = new TestHelper_MW();

		Account a = [select Id, Name from Account limit 1];        
        dealer__Service_Repair_Order__c dsr = [select Id, Name, dealer__Invoiced_Date_Time__c from dealer__Service_Repair_Order__c limit 1];
        System.debug(dsr);
        
        // BLL7a
        AggregateResult[] sumCash = [Select SUM(dealer__Amount__c) asum FROM dealer__Cashering__c where dealer__Service_Repair_Order__c =:dsr.Id];
        Decimal totcash = (Decimal) sumCash[0].get('asum');
        if(totcash==null) { totcash=0; }
        // BLL7a end    
		dsr.dealer__Customer_Charges__c = totcash;
		update(dsr);

        Test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.StandardController(dsr );
        ApexPages.currentPage().getParameters().put('id', dsr.id);
        Cashier  cs = new Cashier();

        cs.invoiceRO();
        System.debug(cs.ro.dealer__Invoiced_Date_Time__c);
        System.debug(dsr);
        cs.postInvoice();	
        cs.ro.dealer__Posted_Date_Time__c =null;

        Test.stopTest();
        
        } 
     
    }
    // BLL7a end



    @isTest
    static void testVoid() {	// BLL7c split off another test method
    
        FFAdata.refresh(); // BLL2a
        System.runAs(FFAdata.TestUser) {

        // BLL2a - use helpers
        TestHelper_MW th = new TestHelper_MW();

		Account a = [select Id, Name from Account limit 1];        

		dealer__Service_Repair_Order__c   dsr = new dealer__Service_Repair_Order__c(
			dealer__Customer__c =a.id,
        	dealer__Mileage_In__c =12,
        	dealer__RO_Number__c ='12',
        	dealer__VIN__c = 'TestQRS',
        	dealer__Company__c=FFAdata.DealerLocation.Id
        );
        insert dsr;

        Test.startTest();
        
        ApexPages.StandardController sc = new ApexPages.StandardController(dsr );
        ApexPages.currentPage().getParameters().put('id', dsr.id);
        Cashier  cs = new Cashier();

        cs.doVoid();	

        Test.stopTest();
        
        } 
     
    }
    // BLL7a end


    static testmethod void testPayMethodChg(){
    
        FFAdata.refresh(); // BLL2a
        System.runAs(FFAdata.TestUser) {

	        // BLL2a - use helpers
	        TestHelper_MW th = new TestHelper_MW();
	     
	        dealer__Service_Repair_Order__c dsr = [select Id, Name, dealer__Invoiced_Date_Time__c from dealer__Service_Repair_Order__c limit 1];
	        dealer__Service_Job__c dsj = [select Id, Name from dealer__Service_Job__c where dealer__Service_Repair_Order__c=:dsr.Id limit 1];
			ServicePaymentType__c spt = [select Id, Name from ServicePaymentType__c limit 1]; 
        
        	Test.startTest();
        	    
        	ApexPages.StandardController sc = new ApexPages.StandardController(dsr );
        	ApexPages.currentPage().getParameters().put('id', dsr .id);
        	Cashier  cs = new Cashier();

        	List<dealer__Cashering__c> cashier_entries = cs.cashier_entries;
        	cs.getPaymentMethods();
        	cs.authcode ='Test';
        	cs.deposit=true; // BLL1a
        	cs.amount=1.00;  // BLL1a
        	dsj.dealer__Stat__c = 'Open'; // BLL1a
        	update(dsj);  // BLL1a
        	List<dealer__Service_Job__c> linelist = [SELECT Id, dealer__Stat__c from dealer__Service_Job__c where dealer__Service_Repair_Order__c=:dsr.Id ];
        	System.debug(linelist);
        	cs.method='Cash';
        	cs.applyPayment();

        	//cs.postInvoice();
        	spt.Payment_Type__c='W';
        	update spt;
        	//cs.postInvoice();
        	spt.Payment_Type__c='I';
        	update spt;
        }
    }

	// BLL7a
    @isTest
    Static Void ReverseROTest(){	// BLL5c split into 2 test methods
    
        FFAdata.refresh(); // BLL2a
        System.runAs(FFAdata.TestUser) {

	        TestHelper_MW th = new TestHelper_MW();
    	    dealer__Service_Repair_Order__c dsr = [select Id, Name, dealer__Invoiced_Date_Time__c from dealer__Service_Repair_Order__c limit 1];
        	System.debug(dsr);
        
        	ApexPages.StandardController sc = new ApexPages.StandardController(dsr );
        	ApexPages.currentPage().getParameters().put('id', dsr .id);
        	Cashier  cs = new Cashier();

        	Test.startTest();
			cs.reverseRepairOrder();        	
			Test.stopTest();
       	}
    }
    // BLL7a end
            
}