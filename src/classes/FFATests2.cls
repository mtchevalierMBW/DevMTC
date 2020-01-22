/**
 * FFATests2
 * Tests: FFAccounting
 *
 *	2019-07-11	W-000712	B. Leaman - moved 2 failing classes out of FFATests to reduce SOQL queries in setup
**/
@isTest(seeAllData=false)
public with sharing class FFATests2 
{

	// BLL6
    //private static TestData testData = new TestData();
	private static TestHelper_MW.FFATestData testData = new TestHelper_MW.FFATestData(); 
	private static TestHelper_MW th;

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(testData);
		th = TestHelper_MW.getInstance();

		// BLL8
		update(new c2g__codaCompany__c(Id=testData.currentCompany.Id, BatchCashPosting__c=true));
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();

		System.runAs(testData.TestUser) {

			// turn off triggers to spare SOQL queries
			TurnOffTriggers();

			th.createGeneralLedgerAccounts(new List<String>{'1100','1200','1220','1225','1270','1271','1272','1274','2000','2115','2100','2200','4000','4855','4905','4950','4960','5100','5304','8014','DONOTUSE'});
			for(c2g__codaGeneralLedgerAccount__c g : [select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c]) {
				testData.GLAMap.put(g.c2g__ReportingCode__c, g);
			}
			testData.refresh(); 

			dealer__Dealer_Location__c loc2 = th.getDealerLocation('2');
			loc2.Company__c = testData.CurrentCompany.Id;
        	loc2.Financial_Force_Dimension_1__c = testData.Dimension1.Id;
			update(loc2);

			th.suspendDupeCatcher();
            LocationsSingleton ls = LocationsSingleton.getInstance();
			ls.retrieveAllLocations();
			GeneralLedgerAccountsSingleton glas = GeneralLedgerAccountsSingleton.getInstance();
			glas.retrieveAllGLAccounts();

			//Account vendor = th.getVendorAccount('1');
			//th.CreateTestPOData('Parts Purchase', testData.DealerLocation, vendor, 995);			

            //createPartsPO();
	        createMiscPO();

   		}

	}


	// BLL8
    @isTest
    static void testSubletPOReversal() {
        
        testData.refresh();

        System.runAs(testData.TestUser)
        {            

            createRepairOrder();
            createSubletPO();
            dealer__Purchase_Order__c sublet = [Select Id, dealer__PO_Amount__c from dealer__Purchase_Order__c where RecordType.Name = 'Sublet' limit 1];

			Test.startTest();
            FFAccounting.receiveSubletPO(sublet.Id);                         

			FFAccounting fa = new FFAccounting();
			FFAccounting.reverseSubletPurchaseOrder(sublet.Id);
			//dealer__Purchase_Order__c po = fa.purchaseOrderSelector(sublet.Id);
			//fa.reverseSubletPurchaseOrderExec(po, fa.journalQuerySelectorByPurchaseOrder(po.Id));

            Test.stopTest();
        }            
    }
	// BLL8 end

    @isTest
    static void testReverseTransferPO(){
        testData.refresh();
        
        System.runAs(testData.TestUser){    

            dealer__Parts_Invoice__c pi = new dealer__Parts_Invoice__c();
            //pi.dealer__Customer__c = accRec.Id;
            //pi.dealer__Customer_Contact__c = conRec.Id;
			pi.dealer__Customer__c = testData.Account.Id;
			pi.dealer__Customer_Contact__c = testData.Account.PersonContactId;
            pi.Name = 'Test Invoice';
            //pi.dealer__Comapny_Number__c = 'Location 1';
			pi.dealer__Company_Number__c = testData.DealerLocation.dealer__Company_Number__c;
			pi.dealer__Location__c = testData.DealerLocation.Id;
            pi.dealer__Deposit__c = 100;
            pi.dealer__Invoice_Number__c = 'inv1234';            
            insert pi;            
            
            dealer__Purchase_Order__c misc = [Select Id, dealer__PO_Amount__c from dealer__Purchase_Order__c where RecordType.Name = 'Miscellaneous' limit 1];
            
			dealer__PartTransfer__c transfer = new dealer__PartTransfer__c();            
			// BLL6
            //BLL6d transfer.dealer__From_Location__c = [Select Id from dealer__Dealer_Location__c where dealer__Company_Number__c = 'AKR' limit 1].Id;
            //BLL6d transfer.dealer__To_Location__c = [Select Id from dealer__Dealer_Location__c where dealer__Company_Number__c = 'MKR' limit 1].Id;
			List<dealer__Dealer_Location__c> dealerLocations = [select Id, Name, dealer__Company_Number__c from dealer__Dealer_Location__c limit 2];
			transfer.dealer__From_Location__c = dealerLocations[0].Id;
			transfer.dealer__To_Location__c = dealerLocations[1].Id;
			// BLL6 end
            transfer.dealer__Purchase_Order__c = misc.Id;
            transfer.dealer__Parts_Invoice__c = pi.Id;
            insert transfer;
            
            FFAccounting.commitTransferPO(misc.Id); 

            Test.startTest();	
            FFAccounting.receiveTransferPO(transfer.Id);
            try { 
            	FFAccounting.reverseTransferPO(transfer.Id);
            } catch(Exception e) { }
            Test.stopTest(); // BLL3a
        }
    }   


    /**
     * Create Vendor Account (DT)
     */
    public static Id createVendorAccount() {
        
        //Account accRec = new Account();
        //accRec.Name = 'Test Account';
        //accRec.Type = 'Customer - Direct';
        //accRec.dealer__Vendor__c = true;
        //insert accRec;
		System.debug('CreateVendorAccount');
		th = TestHelper_MW.getInstance();
		Account accRec = th.getVendorAccount('3');
		System.debug(accRec);
		System.debug(accRec.Id);
        return accRec.Id;
    }

    public static void createMiscPO() {
        // Create MISC Purchase Order
        dealer__Purchase_Order__c misc = new dealer__Purchase_Order__c();
        misc.dealer__Vendor__c = createVendorAccount();
        misc.dealer__Vendor_Email__c = 'test@blackhole.org';
        misc.RecordTypeId=Schema.SObjectType.dealer__Purchase_Order__c.getRecordTypeInfosByName().get('Miscellaneous').getRecordTypeId();
        // BLL6
		//misc.dealer__Company__c=[Select Id from dealer__Dealer_Location__c where dealer__Company_Number__c = 'AKR' limit 1].Id;
		misc.dealer__Company__c = testData.DealerLocation.Id;
		// BLL6 end

        insert misc;

        // Create First Line
        dealer__Purchase_Order_Line__c poline = new dealer__Purchase_Order_Line__c();
        poline.dealer__Purchase_Order__c = misc.id;
        poline.GeneralLedgerAcct__c = [Select Id from GeneralLedgerAcctMW__c limit 1].Id;
        poline.dealer__Amount__c = 227;
            
        insert poline;        
    }


    /**
     * Create Parts Purchase Order with Lines
     */
    public static void createPartsPO() {

        // Create Parts Purchase Order
        dealer__Purchase_Order__c parts_po = new dealer__Purchase_Order__c();
        parts_po.dealer__Vendor__c = createVendorAccount();
        parts_po.dealer__Vendor_Email__c = 'test@blackhole.org';
        parts_po.RecordTypeId=Schema.SObjectType.dealer__Purchase_Order__c.getRecordTypeInfosByName().get('Parts Purchase').getRecordTypeId();
        //BLL6d parts_po.dealer__Company__c=[Select Id from dealer__Dealer_Location__c where dealer__Company_Number__c = 'AKR' limit 1].Id;
		parts_po.dealer__Company__c = testData.DealerLocation.Id;	// BLL6

        insert parts_po;

        // Create First Line
        dealer__Purchase_Order_Line__c poline = new dealer__Purchase_Order_Line__c();
        poline.dealer__Purchase_Order__c = parts_po.id;
        poline.dealer__Part__c = createPart();
        poline.dealer__Part_Quantity__c = 9;
		// BLL5
        //poline.dealer__Amount__c = 227;
		poline.dealer__Amount__c = 225;
		// BLL5
            
        insert poline;

    }


    /**
     * Create Part
     */
    public static Id createPart() {

        // Create a Parts Master Entry
        dealer__Parts_Master__c pm = new dealer__Parts_Master__c();
        pm.Name = 'FL1A__TEST_PART';
        pm.dealer__Retail_Price__c = 99.99;
        pm.dealer__Manufacturer__c = 'FD';
        insert pm;      

        dealer__Parts_Inventory__c inventory = new dealer__Parts_Inventory__c();
        inventory.dealer__Part_No__c = '9963777777';
        inventory.dealer__Cost__c = 70;
        inventory.dealer__List__c = 70;
        inventory.dealer__MFG__c = 'MFG';
        inventory.dealer__Parts_Master__c = pm.Id;
        // BLL6
		// inventory.dealer__Location__c=[Select Id from dealer__Dealer_Location__c where dealer__Company_Number__c = 'AKR' limit 1].Id;       
		inventory.dealer__Location__c = testData.DealerLocation.Id;
		// BLL6 end
        insert inventory; 

        return inventory.Id;       
    }


    public static void createSubletPO() {
        // Create Sublet Purchase Order
        dealer__Purchase_Order__c sublet = new dealer__Purchase_Order__c();
        sublet.dealer__Vendor__c = createVendorAccount();
        sublet.dealer__Vendor_Email__c = 'test@blackhole.org';
        sublet.RecordTypeId=Schema.SObjectType.dealer__Purchase_Order__c.getRecordTypeInfosByName().get('Sublet').getRecordTypeId();
        // BLL6
		//sublet.dealer__Company__c=[Select Id from dealer__Dealer_Location__c where dealer__Company_Number__c = 'AKR' limit 1].Id;
		sublet.dealer__Company__c = testData.DealerLocation.Id;
		// BLL6 end
        sublet.dealer__Service_Repair_Order__c = [Select Id from dealer__Service_Repair_Order__c limit 1].Id;

        insert sublet;

        // Create First Line
        dealer__Purchase_Order_Line__c poline = new dealer__Purchase_Order_Line__c();
        poline.dealer__Purchase_Order__c = sublet.id;
        poline.dealer__Amount__c = 227;
        poline.dealer__Service_Job_Line__c = [Select Id from dealer__Service_Job__c limit 1].Id;
            
        insert poline;        
    }    

    public static void createRepairOrder() {
        Account a = new Account();
        a.LastName ='Test';
        a.AccountSource ='Dealer';
        a.BillingState = 'CA';
        insert a;
        
        contact con = new contact();
        con.Phone = '8888888';
        con.LastName = 'Test';
        insert con;
        
        dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
        dsv.dealer__VIN__c ='Test';
        dsv.Name='Test';
        dsv.dealer__Body_Style__c = 'Test';
        dsv.dealer__Company_Number__c='12123';
        dsv.dealer__Veh_Owner_Contact__c = con.id;
        dsv.dealer__Carline__c ='Test';
        dsv.dealer__Make__c  ='Test';
        dsv.dealer__Year__c  ='2013';
        insert dsv;
        
        dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
        dsr.dealer__Customer__c =a.id;
        dsr.dealer__Mileage_In__c =12;
        dsr.dealer__RO_Number__c ='11';
        dsr.dealer__VIN__c = dsv.dealer__VIN__c;
        dsr.dealer__Vehicle__c = dsv.Id;
        // BLL6
		//dsr.dealer__Company__c=[Select Id from dealer__Dealer_Location__c where dealer__Company_Number__c = 'AKR' limit 1].Id;
		dsr.dealer__Company__c = testData.DealerLocation.Id;
		// BLL6 end
        insert dsr;
        
        dealer__Service_Job__c dsj = new dealer__Service_Job__c();
         dsj.dealer__Cause__c ='Test';
         dsj.dealer__Labor_Charges__c =12;
         dsj.dealer__Service_Repair_Order__c =dsr.id;
         dsj.dealer__Labor_Type__c = 'C';  // BLL1a
        insert dsj;
    }


	static void TurnOffTriggers() {
        // disable custom triggers to reduce number of SOQL queries
        List<MW_TriggerControls__c> turnoff = new List<MW_TriggerControls__c>();
        turnoff.add(new MW_TriggerControls__c(Name='AccountCounty', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='AccountLastService', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='AccountLastSale', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='AccountRcdType', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='AvataxDeal', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='AvataxRental', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='AvataxRepair', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='DealBuyerAccount', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='DealCustomFDF', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='DealLocationLatLng', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='DealerTradeIntegrity', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='DealerTradeStatusChange', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='DealerQuoteValidation', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='DealerStatusValidation', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='DefaultDimension1', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='LastAccountSale', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='LeadBusHrsElapsed', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='LeadClearLatLng', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='LeadClosestStore', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='LeadMWCommercial', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='LinkApptToSlop', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='LinkProposalToSlop', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='NoCommVehOnDeal', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='ProposalPostTax', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='ProposalPreventDelete', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='ProtectPostedDeal', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='ProtectPostedQuote', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='ProtectSROLocation', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='RentalPostTax', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='RepairPostTax', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='RestrictVehicleLocation', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='ReversingJournal', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='SalesUpUpdateContactInfo', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='Sales_Appt_First_Visit', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='SolutionOppDeals', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='Solution_Opp_Open_Chassis', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='SROTriggers', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='TechTimeCredit', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='TechTimeDate', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='uploadAccountHelper', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='uploadContactHelper', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='uploadPartKitHelper', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='uploadPartKitItemHelper', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='uploadTaskHelper', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='upload_Service_Vehicle_Helper', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='WonCommercialQuote', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='rstkSinScrDftControl', Enabled__c=false));
        turnoff.add(new MW_TriggerControls__c(Name='rstkPORcptControl', Enabled__c=false));
		
	}

}