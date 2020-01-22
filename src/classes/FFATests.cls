/**
 * FFATests
 * Tests: FFAccounting
 *
 *  2016-04-06  B. Leaman   BLL2 - Add test coverage for vehicle POs.
 *  2016-04-06  D. Ray      DR1 - Commented for deployment
 *  2016-12-12  Gaurav      #W 000799 - Increased test coverage for deployment
 *	2017-11-01	B. Leaman	BLL3 - too many soql queries
 *	2018-12-11	B. Leaman	W-000524 BLL4 - discovered an error in testMisc trying to run createVehicle method & corrected it
 *	2018-12-21	B. Leaman	BLL5 - test failures due to new DealerTeam code enforcing po line amt divisible by qty (to 2 decimals)
 * 	2019-04-12	B. Leaman	W-000575 BLL6 - refactor to use TestHelper_MW with FFA support, 
 *							increase coverage including new methods.
 *	2019-06-11	B. Leaman	W-000706 BLL7 - better handling of vehicle po test.
 *	2019-09-11	B. Leaman	W-000524 BLL8 - test reversesubletpo, postcashentry
 *	2019-09-24	B. Leaman	W-000730 BLL9 - DT 5.x new requirements

 receivepartsfrompo (po.Part_Quantity_OPutstanding__c==0)
 receivetransferpo across companies
 try/catch/rollback/throw is redundant.
 try/catch/throw is redundant
 reverseServiceRepairOrder
 emailAsyncHandler doesn't run with actual email address during tests, but it can.
 acceptvehiclepurchaseorder journal fails to create
 createVehicle restructure to a single return point?
 createPayableInvoices (concurPayableProcess)
  */
@isTest(seeAllData=false)

public with sharing class FFATests 
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

			List<c2g__codaGeneralLedgerAccount__c> glalist = new List<c2g__codaGeneralLedgerAccount__c>(); 
			for(c2g__codaGeneralLedgerAccount__c gl : testData.GLAMap.values()) glalist.add(gl);

       		Account pa = th.getPersonAccount('1');
       		pa.c2g__CODAAccountsPayableControl__c = glalist[0].Id;
       		pa.c2g__CODAAccountsReceivableControl__c = glalist[0].Id;
       		pa.c2g__CODADimension1__c = testData.Dimension1.Id;
       		update(pa);
	
			update(new dealer__Dealer_Location__c(Id=testData.DealerLocation.Id, Financial_Force_Dimension_1__c=testData.Dimension1.Id));

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
				c2g__AccountDimension1__c = testData.Dimension1.Id,
				ffcash__DeriveAccountDimensions__c = false
			));
			insert(celines);
		// BLL8 end

			dealer__Dealer_Location__c loc2 = th.getDealerLocation('2');
			loc2.Company__c = testData.CurrentCompany.Id;
        	loc2.Financial_Force_Dimension_1__c = testData.Dimension1.Id;
			update(loc2);

			th.suspendDupeCatcher();
            LocationsSingleton ls = LocationsSingleton.getInstance();
			ls.retrieveAllLocations();
			GeneralLedgerAccountsSingleton glas = GeneralLedgerAccountsSingleton.getInstance();
			glas.retrieveAllGLAccounts();

			Account vendor = th.getVendorAccount('1');
			th.CreateTestPOData('Parts Purchase', testData.DealerLocation, vendor, 995);			

            createPartsPO();
	        createMiscPO();
            createRepairOrder();
            createSubletPO();

   		}

		// BLL6
		// disable a few triggers
		MW_TriggerControls__c reversingJournal = MW_TriggerControls__c.getInstance('ReversingJournal');
		if (reversingJournal==null) reversingJournal = new MW_TriggerControls__c(Name='ReversingJournal',Enabled__c=false);
		reversingJournal.Enabled__c=false;
		upsert(reversingJournal);
		// BLL6 end

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
        insert(turnoff);
	}
	// BLL6 end

    @isTest
    static void testFFAController() {
        FFAccounting ffa = new FFAccounting();
    }
        
    @isTest// (SeeAllData=false) // look mum, no hands!
    static void MyTLITest()
    {
        // @testSetup will not retain static variables
        testData.refresh();
        
        System.runAs(testData.TestUser)
        {            
            Test.startTest();

			System.debug(Utility.MemberOfGroupHierarchy(testData.TestUser.Id));

            // Create Invoice
            c2g__codaInvoice__c invoice = createSalesInvoice(testData.Account.Id, testData.CurrentCompany.Id, testData.HomeCurrency.Id, testData.CurrentPeriod.Id);
            createSalesInvoiceLine(invoice.Id, testData.Product.Id);

            // Post Invoice
            /*
            AutoPost.DocumentToPost invoiceToPost = new AutoPost.DocumentToPost();
            invoiceToPost.DocumentId = invoice.Id;
            invoiceToPost.post();

            Integer rows = Database.countQuery('Select count() From c2g__codaTransactionLineItem__c');
            
            System.assert(rows > 0);
            */
        
            // DealerTeam Test Includes
            dealer__Purchase_Order__c po = [Select Id, dealer__PO_Amount__c from dealer__Purchase_Order__c where RecordType.Name = 'Parts Purchase' limit 1];
            FFAccounting.receivePartsFromPO(po.Id, po.dealer__PO_Amount__c);

    /*#W 000799 Begin*/ 
               
            try{
                FFAccounting.receivePartsFromPO(po.Id, 0);            
                //assert for error condition                       
                System.assert(false, 'Error receiving part, the value to apply is 0');
            }catch (Exception e) {
                String message = e.getMessage();
                System.assert(message.contains('Error receiving part, the value to apply is 0'), 'message=' + message);            
            }                         

            dealer__Parts_Inventory__c objPartInventory = [SELECT Id, Name, dealer__Location__c FROM dealer__Parts_Inventory__c LIMIT 1];
            FFAccounting.adjustPartsInventory(objPartInventory.Id, 100.5);
            
            FFAccounting.objectType(po.Id);

            //dealer__Purchase_Order__c sublet = [Select Id, dealer__PO_Amount__c from dealer__Purchase_Order__c where RecordType.Name = 'Sublet' limit 1];
            //FFAccounting.receiveSubletPO(sublet.Id);           

            Test.stopTest();

        }
    }

    @isTest
    static void testSubletMiscPO() {
        
        testData.refresh();

        System.runAs(testData.TestUser)
        {            
            Test.startTest();

            dealer__Purchase_Order__c misc = [Select Id, dealer__PO_Amount__c from dealer__Purchase_Order__c where RecordType.Name = 'Miscellaneous' limit 1];
            FFAccounting.receiveMiscPO(misc.Id);
            
            //FFAccounting.emailAsyncHandler('Test Payload'); // DR1
            FFAccounting.credit(null);
            FFAccounting.credit(1);
            FFAccounting.debit(null);
            FFAccounting.debit(1);
            
            //List <String> emailAsyncOverload = new List<String>{ 'Test Payload 1', 'Test Payload 2', 'Test Payload 3' }; // DR1
            //FFAccounting.emailAsyncHandler(emailAsyncOverload); // DR1

            c2g__codaJournal__c journal = [SELECT Id from c2g__codaJournal__c limit 1];
            FFAccounting.applyTransactionToRegister(misc.Id, journal.Id);

            dealer__Purchase_Order__c sublet = [Select Id, dealer__PO_Amount__c from dealer__Purchase_Order__c where RecordType.Name = 'Sublet' limit 1];
            FFAccounting.receiveSubletPO(sublet.Id);                         

            Test.stopTest();
        }            
    }


    @isTest
    static void testVehiclePO() {
        
        testData.refresh();

        System.runAs(testData.TestUser)
        {            
            Test.startTest();

            createVehiclePO();
            dealer__Purchase_Order__c vehiclePO = [Select Id, dealer__PO_Amount__c from dealer__Purchase_Order__c where RecordType.Name = 'Vehicle Purchase' limit 1];
            List<dealer__Purchase_Order_Line__c> vehiclePOLines = [Select Id, Name, Add_to_Chassis__c, Add_to_Conversion__c,dealer__Amount__c from dealer__Purchase_Order_Line__c where dealer__Purchase_Order__c=:vehiclePO.Id];
            FFAccounting.addsToCost(vehiclePO.Id, vehiclePOLines);
            FFAccounting.acceptVehiclePurchaseOrder(vehiclePO.Id);  // BLL2a
            
            Test.stopTest();
        }            
    }

    @isTest
    static void testCommitTransferPO(){
        testData.refresh();
		th = TestHelper_MW.getInstance();
        
        System.runAs(testData.TestUser){    
            
            //Account accRec = new Account();
            //accRec.Name = 'Test Account';
            //accRec.Type = 'Customer - Direct';
            //insert accRec;            
			Account accRec = th.getBusinessAccount('1');
            
            Contact conRec = new Contact();
            conRec.AccountId = accRec.Id;
            conRec.LastName = 'TestContact';
            conRec.FirstName = 'testFirstName';
            conRec.Email = 'nicki.allen@me.com';
            conRec.HomePhone = '8099306664';
            conRec.MobilePhone = '8099306664';
            
            insert conRec;    
            
            dealer__Parts_Invoice__c pi = new dealer__Parts_Invoice__c();
            pi.dealer__Customer__c = accRec.Id;
            pi.dealer__Customer_Contact__c = conRec.Id;
            pi.Name = 'Test Invoice';
            // BLL9
			//pi.dealer__Comapny_Number__c = 'Location 1';
			pi.dealer__Location__c = testData.DealerLocation.Id;
			pi.dealer__Company_Number__c = testData.DealerLocation.dealer__Company_Number__c;
			// BLL9 end
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
            
            Test.startTest();	// BLL3a
            
            FFAccounting.commitTransferPO(misc.Id); 
            FFAccounting.receiveTransferPO(transfer.Id);
            //BLL3d try{ 
            //BLL3d FFAccounting.reverseTransferPO(transfer.Id);
            //BLL3d  }
            //BLL3d  catch(Exception e)
            //BLL3d  {
            //BLL3d  
            //BLL3d  }
            Test.stopTest(); // BLL3a
        }
    }   

/** BLL8 moved to FFATests2
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

            Test.startTest();	// BLL3a
            FFAccounting.receiveTransferPO(transfer.Id);
            try { 
            	FFAccounting.reverseTransferPO(transfer.Id);
            } catch(Exception e) { }
            Test.stopTest(); // BLL3a
        }
    }   
**/
    
    @isTest
    static void testMisc(){
        testData.refresh();
        
        System.runAs(testData.TestUser){
			// BLL4
            //dealer__Purchase_Order__c misc = [Select Id, dealer__PO_Amount__c from dealer__Purchase_Order__c where RecordType.Name = 'Miscellaneous' limit 1];
            dealer__Purchase_Order__c misc = [Select Id, dealer__PO_Amount__c, dealer__StockNumber__c from dealer__Purchase_Order__c where RecordType.Name = 'Miscellaneous' limit 1];
			// BLL4 end
            
            misc.dealer__Year__c = '2011';
            misc.dealer__Make__c = 'TEST1';
            misc.dealer__Model__c = 'TESTModel';
            update misc;
			Test.startTest();
            
            FFAccounting.createVehicle(misc, 100.55, 201.10);
            
            createVehiclePO();
            dealer__Purchase_Order__c vehiclePO = [Select Id, dealer__PO_Amount__c, dealer__StockNumber__c from dealer__Purchase_Order__c where RecordType.Name = 'Vehicle Purchase' limit 1];            
            FFAccounting.getvehicleInv(vehiclePO);
            
            dealer__Vehicle_Inventory__c objVI = [SELECT Id FROM dealer__Vehicle_Inventory__c LIMIT 1];
            FFAccounting.depreciateRental(testData.CurrentCompany.Id, objVI.Id,'test@blackhole.org');
            
            FFAccounting.emailAsyncHandler('Test Payload 0');
            
            List <String> emailAsyncOverload = new List<String>{ 'Test Payload 1', 'Test Payload 2', 'Test Payload 3' };
            FFAccounting.emailAsyncHandler(emailAsyncOverload);        
			Test.stopTest();

        }

    } 
    /*#W 000799 End*/            


    @isTest
    static void testPayables() {

        testData.refresh();

        System.runAs(testData.TestUser)
        {    
            Test.startTest();

            // BLL6
			//dealer__Dealer_Location__c loc = [Select Id, Name, Financial_Force_Dimension_1__c from dealer__Dealer_Location__c where dealer__Company_Number__c = 'AKR' Limit 1];
			dealer__Dealer_Location__c loc = testData.DealerLocation;
			// BLL6 end

            Account a = [Select Id from Account where dealer__Vendor__c = true limit 1];
			System.debug(a);

            c2g__codaPurchaseInvoice__c pi = FFAccounting.createPayableInvoice(loc.Id, loc.Financial_Force_Dimension_1__c, a.Id, Date.today(), 'Test Invoice', '12345'); 

            dealer__Purchase_Order__c po = [Select Id from dealer__Purchase_Order__c where RecordType.Name = 'Sublet' limit 1];
            List<dealer__Purchase_Order_Line__c> poLines = [Select Id, Name, Add_to_Chassis__c, Add_to_Conversion__c, dealer__Amount__c, dealer__Description__c, General_Ledger_Account__c, Dimension_1__c from dealer__Purchase_Order_Line__c where dealer__Purchase_Order__c=:po.Id];

            FFAccounting.createPayableInvoiceLines(pi.Id, loc.Financial_Force_Dimension_1__c, poLines);

            FFAccounting.createJournal(loc.Id, 'TestDescription', 'A123', 'REF1', 'PUR', Date.today());

            Test.stopTest();
        }
    }

    /*
    @isTest
    static void testServiceDepartment() {
        testData.refresh();

        System.runAs(testData.TestUser)
        {    
            Test.startTest();

                dealer__Service_Repair_Order__c sro = [Select Id from dealer__Service_Repair_Order__c limit 1];
                FFA_ServiceDepartment.postRepairOrder(sro.Id);

            Test.stopTest();
        }        
    }
    */

    /**
     *
     *  FF TEsting
     * 
     */
    /**
     * Create Vehicle Inventory and Inventory PO
     */
    public static void createVehiclePO() {

        // Create the Vehicle Inventory Record
        dealer__Vehicle_Inventory__c VI = new dealer__Vehicle_Inventory__c();
        VI.Name = 'Test Vehicle Inventory';
        VI.dealer__Model__c = 'Civic';
        VI.dealer__Stock_Number__c = 'B042364';
        VI.dealer__VIN__c = '5FNRL5H90BB042364';
        VI.dealer__Company_Number__c = 'Location 1';
        VI.dealer__Year__c = '2014';
        VI.dealer__Make__c = 'Honda';
        
        insert VI;

        // Create Parts Purchase Order
        dealer__Purchase_Order__c po = new dealer__Purchase_Order__c();
        po.dealer__Vendor__c = createVendorAccount();
		System.debug(po.dealer__Vendor__c);
        po.dealer__Vendor_Email__c = 'test@blackhole.org';
        po.RecordTypeId=Schema.SObjectType.dealer__Purchase_Order__c.getRecordTypeInfosByName().get('Vehicle Purchase').getRecordTypeId();
        //BLL6
		//po.dealer__Company__c=[Select Id from dealer__Dealer_Location__c where dealer__Company_Number__c = 'AKR' limit 1].Id;
		po.dealer__Company__c = testData.DealerLocation.Id;
		// BLL6 end
        po.dealer__Vehicle_Inventory__c = VI.Id;

        insert po;

		// BLL6
		List<dealer__Purchase_Order_Line__c> polines = new List<dealer__Purchase_Order_Line__c>();
		// BLL6 end

        // Create First Line
        dealer__Purchase_Order_Line__c poline1 = new dealer__Purchase_Order_Line__c();
        poline1.dealer__Purchase_Order__c = po.id;
        poline1.dealer__Amount__c = 227;
        poline1.Add_to_Chassis__c = true;
		poline1.General_Ledger_Account__c = testData.GLAMap.get('1220').Id;	// BLL7
            
        // BLL6
		//insert poline1;    
		polines.add(poline1);
		// BLL6 end

        // Create Second Line
        dealer__Purchase_Order_Line__c poline2 = new dealer__Purchase_Order_Line__c();
        poline2.dealer__Purchase_Order__c = po.Id;
        poline2.dealer__Amount__c = 9000;
        poline2.Add_to_Conversion__c = true;
		poline2.General_Ledger_Account__c = testData.GLAMap.get('1220').Id;	// BLL7
		//insert poline2;    
		polines.add(poline2);

		// BLL7
        dealer__Purchase_Order_Line__c poline3 = new dealer__Purchase_Order_Line__c();
        poline3.dealer__Purchase_Order__c = po.Id;
        poline3.dealer__Amount__c = -9227;
		poline3.General_Ledger_Account__c = testData.GLAMap.get('2115').Id;
		polines.add(poline3);
		// BLL7 end

        // BLL6
		insert(polines);
		// BLL6 end

    }

    /**
     * Create Parts Purchase Order with Lines
     */
    public static void createPartsPO() {

        // Create Parts Purchase Order
        dealer__Purchase_Order__c parts_po = new dealer__Purchase_Order__c();
        parts_po.dealer__Vendor__c = createVendorAccount();
		System.debug(parts_po.dealer__Vendor__c);
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

    public static void createMiscPO() {
        // Create MISC Purchase Order
        dealer__Purchase_Order__c misc = new dealer__Purchase_Order__c();
        misc.dealer__Vendor__c = createVendorAccount();
		System.debug(misc.dealer__Vendor__c);
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

    public static void createSubletPO() {
        // Create Sublet Purchase Order
        dealer__Purchase_Order__c sublet = new dealer__Purchase_Order__c();
        sublet.dealer__Vendor__c = createVendorAccount();
		System.debug(sublet.dealer__Vendor__c);
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
		th = TestHelper_MW.getInstance();
        //Account a = new Account();
        //a.LastName ='Test';
        //a.AccountSource ='Dealer';
        //a.BillingState = 'CA';
        //insert a;
		Account a = th.getBusinessAccount('1');
        
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

/** BLL6d
    public static void createLocation() {

        c2g__codaDimension1__c cgd1 = new c2g__codaDimension1__c();
    
        cgd1.c2g__ExternalId__c='172';
        cgd1.c2g__ReportingCode__c='Akron Ohio';
        cgd1.c2g__UnitOfWork__c =12;

        insert cgd1;

        c2g__codaCompany__c company = testData.CurrentCompany;

        dealer__Dealer_Location__c loc = new dealer__Dealer_Location__c();
        loc.Name = 'Test Location xyz ';
        loc.dealer__Company_Number__c = 'AKR';
        loc.Region__c = '1';
        loc.dealer__General_Manager__c = UserInfo.getUserId();
        loc.Rental_Manager__c = UserInfo.getUserId();
        loc.dealer__City__c = 'Richfield';
        loc.dealer__State__c = 'OH';
        loc.dealer__Postal_Code__c = '44286';
        loc.Financial_Force_Dimension_1__c = cgd1.Id;
        loc.Company__c=company.Id;

        insert loc;        
        
        dealer__Dealer_Location__c locOne = new dealer__Dealer_Location__c();
        locOne.Name = 'Test Location One';
        locOne.dealer__Company_Number__c = 'MKR';
        locOne.Region__c = '2';
        locOne.dealer__General_Manager__c = UserInfo.getUserId();
        locOne.Rental_Manager__c = UserInfo.getUserId();
        locOne.dealer__City__c = 'WhiteField';
        locOne.dealer__State__c = 'CA';
        locOne.dealer__Postal_Code__c = '44826';
        locOne.Financial_Force_Dimension_1__c = cgd1.Id;
        locOne.Company__c = company.Id;
        
        insert locOne;   
    }
**/

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
		Account accRec = th.getVendorAccount('1');
		System.debug(accRec);
        return accRec.Id;
    }

    /**
     * Test Inbound email service
     */
     @isTest
     static void testEmailService() {
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
       
        // setup the data for the email
        email.subject = 'Async Posting Test';
        email.fromAddress = 'fake@blackhole.org';
        email.plainTextBody = '{ "recordId" : "a1nW0000000dOkV", "orgId" : "' + UserInfo.getOrganizationId() + '", "requestedBy" : "' + UserInfo.getUserId() + '", "action" : "purchase_order_misc_test", "partsReceiptValue" : null }';
          
        AccountingEmailService  testInbound = new AccountingEmailService ();

        testInbound.handleInboundEmail(email, env);
     }

     @isTest
     static void testEmailHandlerExceptions() {
        AccountingEmailService  testInbound = new AccountingEmailService ();
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = 'Async Posting Test';
        email.fromAddress = 'fake@blackhole.org';
        // Org Invalid
        System.assert(testInbound.orgValid('NotValid')==false);

        // CreateInvoiceRegisterFail
        testInbound.createInvoiceRegister(null);

        try {

             email.plainTextBody = '{ "recordId" : "a1nW0000000dOkV", "orgId" : "BAD", "requestedBy" : "' + UserInfo.getUserId() + '", "action" : "purchase_order_misc_test", "partsReceiptValue" : null }';
             testInbound.handleInboundEmail(email, env);

        } Catch(Exception e) {}

     }

     @isTest
     static void testEmailHandlerforDepreciation() {
        AccountingEmailService  testInbound = new AccountingEmailService ();
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        email.subject = 'Asyncnronous Processing Request - Depreciation';
        email.fromAddress = 'fake@blackhole.org';
        // Org Invalid
        System.assert(testInbound.orgValid('NotValid')==false);

        // CreateInvoiceRegisterFail
        testInbound.createInvoiceRegister(null);

        try {

             email.plainTextBody = '{ "recordId" : "a1nW0000000dOkV", "orgId" : "BAD", "requestedBy" : "' + UserInfo.getUserId() + '", "action" : "purchase_order_misc_test", "partsReceiptValue" : null }';
             testInbound.handleInboundEmail(email, env);

        } Catch(Exception e) {}

     }

    static User createUser()
    {
        Profile p = [select id from profile where name='System Administrator'];

        User u = new User();
        u.FirstName = 'FFA';
        u.LastName = 'User';
        u.Alias = 'FFAUSER';
        u.Username = 'ffdeveloper@nowhere.com';
        u.Email = 'ffdeveloper@nowhere.com';
        u.CommunityNickname = 'ffd';
        u.Phone = '555.555.5555';
        u.IsActive = true;
        u.ProfileId = p.Id;
        u.TimeZoneSidKey = 'America/New_York';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'ISO-8859-1';
        u.LanguageLocaleKey = 'en_US';
        u.Title = 'The enlightened one';
        u.CompanyName = 'FF Test Company';
        u.Division = 'AKR';

        insert u;

        return u;
    }

    

    /**
        *   Create FFA Queue (FinancialForce)
        *   No @Parms required
    **/
/** BLL6d
    public static Group createFFAQueue(Id userId) 
    {
        //Create queue
        Group grp = new Group(Type = 'Queue', Name = 'FF FinancialForce');
        insert grp;

        //Create list of all FinancialForce Objctes
        List<String> queueObjectNames =  getQueueObjectNames();

        //Assign Objects to Queue
        List<QueueSObject> newQueueObjects = new List<QueueSObject>();
        for (String queueObjectName : queueObjectNames) 
        {
            newQueueObjects.add(new QueueSObject(QueueId = grp.id, SobjectType = queueObjectName));
        }
        insert newQueueObjects;

        //Assign group to a current user
        insert new GroupMember(GroupId = grp.id, UserOrGroupId = userId); 

        return grp;   
    }
**/
   
    /**
        *   Create FFA Company (FinancialForce Test Company)
        *   No @Parms required
    **/
/** BLL6d 
    public static c2g__codaCompany__c createFFACompany(String name, Id queueMemberId) 
    {        
        c2g__codaCompany__c testCompany = new c2g__codaCompany__c();
        testCompany.put('Name', name);
        testCompany.put('OwnerId', queueMemberId);
        testCompany.put('c2g__Street__c', 'Cardale Park');
        testCompany.put('c2g__StateProvince__c', 'Beckwith Head Road');
        testCompany.put('c2g__City__c', 'Harrogate');
        testCompany.put('c2g__ZipPostCode__c', 'HG3 1RY');
        testCompany.put('c2g__Country__c', 'United Kingdom');
        testCompany.put('c2g__Phone__c', '+44 (0)1423 537728)');      
             
        insert  testCompany;  

        return testCompany;    

    }
**/
/** BLL6d 
    public static void createUserCompany(Id companyId, Id userId)
    {
        insert new c2g__codaUserCompany__c(c2g__Company__c = companyId, c2g__User__c = userId);        
    }
**/
   
    /**
        *   Create FFA Currency (USD)
        *   No @Parms required
    **/
/** BLL6d 
    public static c2g__codaAccountingCurrency__c createHomeCurrency(String name) 
    {
        c2g__codaAccountingCurrency__c testCurrency = new c2g__codaAccountingCurrency__c();
        testCurrency.put('Name', name);
        //testCurrency.put('c2g__UnitOfWork__c', 1);
        testCurrency.put('c2g__DecimalPlaces__c', 2);
        testCurrency.put('c2g__Home__c', true);
        testCurrency.put('c2g__Dual__c', true);

        insert testCurrency;

        return testCurrency;
    }
**/

/** BLL6d 
    public static c2g__codaPeriod__c createYearPeriods() 
    {
        String currentYear = String.valueOf(Date.today().year());  

        c2g__codaYear__c yr = new c2g__codaYear__c();
        yr.put('Name', currentYear);
        yr.put('c2g__NumberOfPeriods__c', 12);
        yr.put('c2g__AutomaticPeriodList__c', true);
        yr.put('c2g__StartDate__c', Date.valueOf(currentYear + '-01-01 00:00:00'));
        yr.put('c2g__EndDate__c', Date.valueOf(currentYear + '-12-31 00:00:00'));
        yr.put('c2g__PeriodCalculationBasis__c', 'Month End');

        insert yr;

        String currentMth = String.valueOf(Date.today().month());
        if(currentMth.length() == 1) 
            currentMth = '0' + currentMth;

        List<c2g__codaPeriod__c> periods = new List<c2g__codaPeriod__c>();        

        c2g__codaPeriod__c currentTestPeriod;
        List<String> monthNumbers = new List<String>{'01','02','03','04','05','06','07','08','09','10','11','12','01','12','12'};
        for (String monthNumber : monthNumbers) 
        {
            c2g__codaPeriod__c period = new c2g__codaPeriod__c();
            period.put('Name', currentYear + '/' + '0' + monthNumber);
            period.put('c2g__YearName__c', yr.id);
            period.put('c2g__PeriodNumber__c', '0' + monthNumber);
            period.put('c2g__Description__c', 'Trading Period');                   
            period.put('c2g__StartDate__c', Date.valueOf(currentYear + '-' + monthNumber + '-01 00:00:00'));
            period.put('c2g__EndDate__c', Date.valueOf(currentYear + '-' + monthNumber + '-01 00:00:00').addMonths(1).addDays(-1));
            periods.add(period);

            //returns current period
            if (monthNumber == currentMth) 
                currentTestPeriod = period; 
        }
        // fix the opening period
        periods[12].put('Name', currentYear + '/000');
        periods[12].put('c2g__PeriodNumber__c', '000');
        periods[12].put('c2g__Description__c', 'Opening (B/fwd)');
        periods[12].put('c2g__EndDate__c', periods[12].c2g__StartDate__c); 

        // fix the closing period
        periods[13].put('Name' , currentYear + '/101');
        periods[13].put('c2g__PeriodNumber__c', '101');
        periods[13].put('c2g__Description__c', 'Closing (C/fwd)');
        periods[13].put('c2g__StartDate__c', periods[13].c2g__EndDate__c);

        // fix the adjustment period
        periods[14].put('Name' , currentYear + '/100');
        periods[14].put('c2g__PeriodNumber__c', '100');
        periods[14].put('c2g__Description__c', 'Adjustment Period');
        periods[14].put('c2g__StartDate__c', periods[14].c2g__EndDate__c);
                    
        insert periods;
        
        return currentTestPeriod;
    }
**/


    /**
    *   Create Dimension 
    */
/** BLL6d 
    public static c2g__codaDimension1__c createDimension() {
        
        c2g__codaDimension1__c cgd1 = new c2g__codaDimension1__c();
    
        cgd1.c2g__ExternalId__c='Company 1';
        cgd1.c2g__ReportingCode__c='Company 1';
        cgd1.c2g__UnitOfWork__c =12;

        insert cgd1;

        return cgd1;
    }
**/

    /**
    *   Create GLA Accounts
    *   No @Parms required
    **/
/**
    public static Map<String,c2g__codaGeneralLedgerAccount__c> createGLAccounts()
    {    
        c2g__codaGeneralLedgerAccount__c accountsPayableControl, accountsReceivableControl, grossRevenue, bankAccCurUK, bankCharges, bankInterest, deferredIncome, salesTaxA, cogs, unbilledPurchases, partsInventory, prePaidExpenses;
        
        List<c2g__codaGeneralLedgerAccount__c> glaList;

        deferredIncome = new c2g__codaGeneralLedgerAccount__c();
        deferredIncome.put('Name' , '2200 - Deferred Income');
        deferredIncome.put('c2g__ReportingCode__c' , '2200t');
        deferredIncome.put('c2g__Type__c' , 'Balance Sheet');
        deferredIncome.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        deferredIncome.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        deferredIncome.put('c2g__TrialBalance3__c' , 'Accruals and Deferred Income');
        deferredIncome.put('c2g__TrialBalance4__c' , '-');
        deferredIncome.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        deferredIncome.put('c2g__BalanceSheet2__c' , 'Current Liabilities');
        deferredIncome.put('c2g__BalanceSheet3__c' , 'Accruals and Deferred Income');

        accountsPayableControl = new c2g__codaGeneralLedgerAccount__c();
        accountsPayableControl.put('Name' , '2000 - Accounts Payable Control');
        accountsPayableControl.put('c2g__ReportingCode__c' , '2000t');
        accountsPayableControl.put('c2g__Type__c' , 'Balance Sheet');
        accountsPayableControl.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        accountsPayableControl.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        accountsPayableControl.put('c2g__TrialBalance3__c' , 'Creditors');
        accountsPayableControl.put('c2g__TrialBalance4__c' , '-');
        accountsPayableControl.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        accountsPayableControl.put('c2g__BalanceSheet2__c' , 'Current Liabilities');
        accountsPayableControl.put('c2g__BalanceSheet3__c' , 'Creditors');

        accountsReceivableControl = new c2g__codaGeneralLedgerAccount__c();
        accountsReceivableControl.put('Name' , '1200 - Accounts Receivable Control');
        accountsReceivableControl.put('c2g__ReportingCode__c' , '1200t');
        accountsReceivableControl.put('c2g__Type__c' , 'Balance Sheet');
        accountsReceivableControl.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        accountsReceivableControl.put('c2g__TrialBalance2__c' , 'Current Assets');
        accountsReceivableControl.put('c2g__TrialBalance3__c' , 'Debtors');
        accountsReceivableControl.put('c2g__TrialBalance4__c' , '-');
        accountsReceivableControl.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        accountsReceivableControl.put('c2g__BalanceSheet2__c' , 'Current Assets');
        accountsReceivableControl.put('c2g__BalanceSheet3__c' , 'Debtors');

        grossRevenue = new c2g__codaGeneralLedgerAccount__c();
        grossRevenue.put('Name' , '4000 - Gross revenue');
        grossRevenue.put('c2g__ReportingCode__c' , '4000t');
        grossRevenue.put('c2g__Type__c' , 'Profit and Loss');
        grossRevenue.put('c2g__TrialBalance1__c' , 'Profit and Loss');
        grossRevenue.put('c2g__TrialBalance2__c' , 'Gross Profit');
        grossRevenue.put('c2g__TrialBalance3__c' , 'Sales Revenue');
        grossRevenue.put('c2g__TrialBalance4__c' , 'Sales - Direct');
        grossRevenue.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        grossRevenue.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        grossRevenue.put('c2g__BalanceSheet3__c' , '-');

        //Bank Account - Current UK
        bankAccCurUK = new c2g__codaGeneralLedgerAccount__c();
        bankAccCurUK.put('Name' , '24000 - Customer Prepaids (MPS)');
        bankAccCurUK.put('c2g__ReportingCode__c' , 'BNK001 UKt');
        bankAccCurUK.put('c2g__Type__c' , 'Balance Sheet');
        bankAccCurUK.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        bankAccCurUK.put('c2g__TrialBalance2__c' , 'Current Assets');
        bankAccCurUK.put('c2g__TrialBalance3__c' , 'Bank and Cash');
        bankAccCurUK.put('c2g__TrialBalance4__c' , '');
        bankAccCurUK.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        bankAccCurUK.put('c2g__BalanceSheet2__c' , 'Current Assets');
        bankAccCurUK.put('c2g__BalanceSheet3__c' , 'Bank and Cash');

        //Bank Charges
        bankCharges = new c2g__codaGeneralLedgerAccount__c();
        bankCharges.put('Name' , 'Bank Charges');
        bankCharges.put('c2g__ReportingCode__c' , '61620');
        bankCharges.put('c2g__Type__c' , 'Profit and Loss');
        bankCharges.put('c2g__TrialBalance1__c' , 'Profit and Loss');
        bankCharges.put('c2g__TrialBalance2__c' , 'Operating Expenses');
        bankCharges.put('c2g__TrialBalance3__c' , 'Administration Costs');
        bankCharges.put('c2g__TrialBalance4__c' , '');
        bankCharges.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        bankCharges.put('c2g__BalanceSheet2__c' , 'Current Assets');
        bankCharges.put('c2g__BalanceSheet3__c' , 'Profit and Loss');

        //Bank Charges
        bankInterest = new c2g__codaGeneralLedgerAccount__c();
        bankInterest.put('Name' , 'Bank Interest');
        bankInterest.put('c2g__ReportingCode__c' , '64740');
        bankInterest.put('c2g__Type__c' , 'Profit and Loss');
        bankInterest.put('c2g__TrialBalance1__c' , 'Profit and Loss');
        bankInterest.put('c2g__TrialBalance2__c' , 'Interest and Taxation');
        bankInterest.put('c2g__TrialBalance3__c' , 'Finance Costs');
        bankInterest.put('c2g__TrialBalance4__c' , '');
        bankInterest.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        bankInterest.put('c2g__BalanceSheet2__c' , 'Current Assets');
        bankInterest.put('c2g__BalanceSheet3__c' , 'Profit and Loss');

        //Tax Code
        salesTaxA = new c2g__codaGeneralLedgerAccount__c();
        salesTaxA.put('Name' , '2160 - Sales Tax A');
        salesTaxA.put('c2g__ReportingCode__c' , '2160t');
        salesTaxA.put('c2g__Type__c' , 'Balance Sheet');
        salesTaxA.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        salesTaxA.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        salesTaxA.put('c2g__TrialBalance3__c' , 'Tax Liability');
        salesTaxA.put('c2g__TrialBalance4__c' , '');
        salesTaxA.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        salesTaxA.put('c2g__BalanceSheet2__c' , 'Current Liabilities');
        salesTaxA.put('c2g__BalanceSheet3__c' , 'Tax Liability');

        cogs = new c2g__codaGeneralLedgerAccount__c();
        cogs.put('Name' , '5100 - COGS - Materials');
        cogs.put('c2g__ReportingCode__c' , '5100t');
        cogs.put('c2g__Type__c' , 'Profit and Loss');
        cogs.put('c2g__TrialBalance1__c' , 'Profit and Loss');
        cogs.put('c2g__TrialBalance2__c' , 'Gross Profit');
        cogs.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        cogs.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        cogs.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        cogs.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        cogs.put('c2g__BalanceSheet3__c' , '');

        unbilledPurchases = new c2g__codaGeneralLedgerAccount__c();
        unbilledPurchases.put('Name' , '2115 - Unbilled Purchases');
        unbilledPurchases.put('c2g__ReportingCode__c' , '2115');
        unbilledPurchases.put('c2g__Type__c' , 'Balance Sheet');
        unbilledPurchases.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        unbilledPurchases.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        unbilledPurchases.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        unbilledPurchases.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        unbilledPurchases.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        unbilledPurchases.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        unbilledPurchases.put('c2g__BalanceSheet3__c' , '');

        partsInventory = new c2g__codaGeneralLedgerAccount__c();
        partsInventory.put('Name' , '1220 - Unbilled Purchases');
        partsInventory.put('c2g__ReportingCode__c' , '1220');
        partsInventory.put('c2g__Type__c' , 'Balance Sheet');
        partsInventory.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        partsInventory.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        partsInventory.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        partsInventory.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        partsInventory.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        partsInventory.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        partsInventory.put('c2g__BalanceSheet3__c' , '');  

        prePaidExpenses = new c2g__codaGeneralLedgerAccount__c();
        prePaidExpenses.put('Name' , '4960 - Unbilled Purchases');
        prePaidExpenses.put('c2g__ReportingCode__c' , '4960');
        prePaidExpenses.put('c2g__Type__c' , 'Balance Sheet');
        prePaidExpenses.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        prePaidExpenses.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        prePaidExpenses.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        prePaidExpenses.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        prePaidExpenses.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        prePaidExpenses.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        prePaidExpenses.put('c2g__BalanceSheet3__c' , '');                  
        

        c2g__codaGeneralLedgerAccount__c prePaidExpensesOne = new c2g__codaGeneralLedgerAccount__c();
        prePaidExpensesOne.put('Name' , '1274 - Unbilled Purchases');
        prePaidExpensesOne.put('c2g__ReportingCode__c' , '1274');
        prePaidExpensesOne.put('c2g__Type__c' , 'Balance Sheet');
        prePaidExpensesOne.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        prePaidExpensesOne.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        prePaidExpensesOne.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        prePaidExpensesOne.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        prePaidExpensesOne.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        prePaidExpensesOne.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        prePaidExpensesOne.put('c2g__BalanceSheet3__c' , '');  
        

        c2g__codaGeneralLedgerAccount__c commitTransfer = new c2g__codaGeneralLedgerAccount__c();
        commitTransfer.put('Name' , '1225 - Unbilled Purchases');
        commitTransfer.put('c2g__ReportingCode__c' , '1225');
        commitTransfer.put('c2g__Type__c' , 'Balance Sheet');
        commitTransfer.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        commitTransfer.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        commitTransfer.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        commitTransfer.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        commitTransfer.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        commitTransfer.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        commitTransfer.put('c2g__BalanceSheet3__c' , ''); 
        
        c2g__codaGeneralLedgerAccount__c recieveTransferPO = new c2g__codaGeneralLedgerAccount__c();
        recieveTransferPO.put('Name' , '2903 - Unbilled Purchases');
        recieveTransferPO.put('c2g__ReportingCode__c' , '2903');
        recieveTransferPO.put('c2g__Type__c' , 'Balance Sheet');
        recieveTransferPO.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        recieveTransferPO.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        recieveTransferPO.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        recieveTransferPO.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        recieveTransferPO.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        recieveTransferPO.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        recieveTransferPO.put('c2g__BalanceSheet3__c' , '');    
                
        c2g__codaGeneralLedgerAccount__c gl_1270 = new c2g__codaGeneralLedgerAccount__c();
        gl_1270.put('Name' , '1270 - Unbilled Purchases');
        gl_1270.put('c2g__ReportingCode__c' , '1270');
        gl_1270.put('c2g__Type__c' , 'Balance Sheet');
        gl_1270.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        gl_1270.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        gl_1270.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        gl_1270.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        gl_1270.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        gl_1270.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        gl_1270.put('c2g__BalanceSheet3__c' , '');       
                                                      
        c2g__codaGeneralLedgerAccount__c gl_4855 = new c2g__codaGeneralLedgerAccount__c();
        gl_4855.put('Name' , '4855 - Unbilled Purchases');
        gl_4855.put('c2g__ReportingCode__c' , '4855');
        gl_4855.put('c2g__Type__c' , 'Balance Sheet');
        gl_4855.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        gl_4855.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        gl_4855.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        gl_4855.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        gl_4855.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        gl_4855.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        gl_4855.put('c2g__BalanceSheet3__c' , '');       
        
        c2g__codaGeneralLedgerAccount__c gl_8014 = new c2g__codaGeneralLedgerAccount__c();
        gl_8014.put('Name' , '8014 - Unbilled Purchases');
        gl_8014.put('c2g__ReportingCode__c' , '8014');
        gl_8014.put('c2g__Type__c' , 'Balance Sheet');
        gl_8014.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        gl_8014.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        gl_8014.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        gl_8014.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        gl_8014.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        gl_8014.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        gl_8014.put('c2g__BalanceSheet3__c' , ''); 
        
        c2g__codaGeneralLedgerAccount__c gl_1242 = new c2g__codaGeneralLedgerAccount__c();
        gl_1242.put('Name' , '1242 - Unbilled Purchases');
        gl_1242.put('c2g__ReportingCode__c' , '1242');
        gl_1242.put('c2g__Type__c' , 'Balance Sheet');
        gl_1242.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        gl_1242.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        gl_1242.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        gl_1242.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        gl_1242.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        gl_1242.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        gl_1242.put('c2g__BalanceSheet3__c' , ''); 
                
        glaList = new List<c2g__codaGeneralLedgerAccount__c>{accountsPayableControl, accountsReceivableControl, grossRevenue, bankAccCurUK, bankCharges, bankInterest, deferredIncome, salesTaxA, cogs, unbilledPurchases, partsInventory, prePaidExpenses, prePaidExpensesOne, commitTransfer, recieveTransferPO, gl_1270, gl_4855, gl_8014, gl_1242};
        insert glaList;
        
        return new Map<String,c2g__codaGeneralLedgerAccount__c>{
            'accountsPayableControl'=>accountsPayableControl,
            'accountsReceivableControl'=>accountsReceivableControl,
            'grossRevenue'=>grossRevenue,
            'bankAccCurUK'=>bankAccCurUK,
            'bankCharges'=>bankCharges,
            'bankInterest'=>bankInterest,
            'deferredIncome'=>deferredIncome,
            'salesTaxA'=>salesTaxA,
            'cogs'=>cogs,
            'unbilledPurchases'=>unbilledPurchases,
            'partsInventory'=>partsInventory,
            'prePaidExpenses'=>prePaidExpenses
        };
        
    }

**/

    /**
    *   Create or Insert Account
    *   No @Parms required
    **/
/** BLL6d 
    public static Account createAccount(String name, Id accountsReceivableControlId, Id accountsPayableControlId)
    {
        Account productServices = new Account();
        productServices.put('Name', name);
        // productServices.put('CurrencyIsoCode', 'USD');
        productServices.put('Type', 'Customer - Direct');
        productServices.put('Industry', 'Apparel');
        productServices.put('AnnualRevenue', 350000000);
        productServices.put('Ownership', 'Public');
        productServices.put('Rating', 'Warm');
        productServices.put('Phone', '(336) 222-7000');
        productServices.put('Fax', '(336) 222-8000');
        productServices.put('Website', 'http://www.financialforce.com');
        productServices.put('TickerSymbol', 'BTXT');
        productServices.put('NumberOfEmployees', 9000);
        productServices.put('SIC', '546732');
        productServices.put('c2g__CODAReportingCode__c', 'ABC123t');
        productServices.put('c2g__CODAAccountsReceivableControl__c', accountsReceivableControlId);
        productServices.put('c2g__CODAAccountsPayableControl__c', accountsPayableControlId);
        productServices.put('c2g__CODASalesTaxStatus__c', 'Exempt');
        productServices.put('c2g__CODAVATStatus__c', 'EC Registered');
        productServices.put('c2g__CODAECCountryCode__c', 'FR');
        productServices.put('c2g__CODAVATRegistrationNumber__c', '123 43223 3');
        productServices.put('c2g__CODATaxCalculationMethod__c', 'Gross');
        productServices.put('c2g__CODAInvoiceEmail__c', 'productservices@financialforce.com');
        productServices.put('c2g__CODADescription1__c', 'Standard Terms');
        productServices.put('c2g__CODADaysOffset1__c', 30);
        productServices.put('c2g__CODABaseDate1__c', 'Invoice Date');
        productServices.put('c2g__CODADiscount1__c', 0);
        productServices.put('c2g__CODAAccountTradingCurrency__c', 'USD');

        insert productServices;

        return productServices;
    }   
**/

    /**
        *   Create Product
        *   No @Parms required
    **/
/** BLL6d
    public static Product2 createProduct(Id cogsId, Id grossRevenueId)
    {
        Product2 prod = new Product2();
        prod.put('Name' , 'Titanium');
        prod.put('ProductCode' , 'TIT101');
        prod.put('IsActive' , true);
        prod.put('c2g__CODAPurchaseAnalysisAccount__c' , cogsId);
        prod.put('c2g__CODASalesRevenueAccount__c' , grossRevenueId);
        prod.put('c2g__CODASalesTaxStatus__c' , 'Taxable');

        insert prod;
        return prod;
    }
**/

    /**
        *   Create PricebookEntry
        *   One Param required 
        *       - Id prodId - Product2 Id
    **/
/** BLL6d
    public static PricebookEntry createPriceBook(Id prodId)
    {
        // Get Pricebook
        Pricebook2 priceBook = Database.query('select id from Pricebook2 where IsStandard = true');
        priceBook.put('IsActive' , true);
        update priceBook;  

        PricebookEntry priceBookEntry = new PricebookEntry();
        priceBookEntry.put('Pricebook2Id' , priceBook.Id);
        priceBookEntry.put('Product2Id' , prodId); 
        priceBookEntry.put('UnitPrice' , 5000);
        priceBookEntry.put('IsActive' , true);
        priceBookEntry.put('UseStandardPrice' , false);

        insert priceBookEntry;

        return priceBookEntry;
    }
**/

    /**
    *   Create Sales Invoice Header
    *   One Param required 
    *       - Id accId - Account Id
    **/
    public static c2g__codaInvoice__c createSalesInvoice(Id accId, Id ownercompId, Id currencyId, Id periodId)
    {
        c2g__codaInvoice__c invoice = new c2g__codaInvoice__c();
        invoice.put('c2g__Account__c' , accId);
		invoice.put('c2g__OwnerCompany__c', ownercompId);
        invoice.put('c2g__InvoiceDate__c' , System.today());
        invoice.put('c2g__InvoiceCurrency__c' , currencyId);
        invoice.put('c2g__Period__c' , periodId);

        insert invoice;
        return invoice;
    }
    /**
    *   Create Sales Invoice Line
    *   Two Param required 
    *       - Id prodId - Product2 Id
    *       - Id headerId - Sales Invoice Header Id
    **/
    public static c2g__codaInvoiceLineItem__c createSalesInvoiceLine(Id headerId, Id prodId)
    {
        c2g__codaInvoiceLineItem__c invoiceLine = new c2g__codaInvoiceLineItem__c();
        invoiceLine.put('c2g__Quantity__c' ,500);
        invoiceLine.put('c2g__LineDescription__c' , 'Testing123CoolDude123Income');
        invoiceLine.put('c2g__UnitPrice__c' , 1);
        invoiceLine.put('c2g__Product__c' , prodId);
        invoiceLine.put('c2g__DeriveUnitPriceFromProduct__c' , false);
        invoiceLine.put('c2g__Invoice__c' , headerId);

        insert invoiceLine;
        return invoiceLine;
    }
    
    /**
        *   Create List of Object Queue Names
        *   No @Parms required
    **/
/**	BLL6d 
    public static List<String> getQueueObjectNames()
    {
        List<String> objectNames = new List<String>();

        //Financial Objects
        objectNames.add('c2g__codaCompany__c');
        objectNames.add('c2g__codaYear__c');
        objectNames.add('c2g__codaCurrencyRevaluation__c');
        objectNames.add('c2g__ReportingBalance__c');
        objectNames.add('c2g__codaBudget__c');
        objectNames.add('c2g__codaBankAccount__c');
        objectNames.add('c2g__codaBankStatement__c');
        objectNames.add('c2g__codaPaymentMediaControl__c');
        objectNames.add('c2g__codaBankReconciliation__c');
        objectNames.add('c2g__codaPaymentMediaSummary__c');
        objectNames.add('c2g__codaMatchingReference__c');
        objectNames.add('c2g__codaAccountingCurrency__c');
        objectNames.add('c2g__codaGroupingReference__c');
        objectNames.add('c2g__codaPaymentTemplate__c');

        //Document Objects
        objectNames.add('c2g__codaTransaction__c');
        objectNames.add('c2g__codaInvoice__c');
        objectNames.add('c2g__codaJournal__c');
        objectNames.add('c2g__codaCreditNote__c');
        objectNames.add('c2g__codaCashEntry__c');
        objectNames.add('c2g__codaPurchaseInvoice__c');
        objectNames.add('c2g__codaPurchaseCreditNote__c');
        objectNames.add('c2g__codaPayment__c');
        //objectNames.add('c2g__CancelPayment__c');
        objectNames.add('c2g__codaCashMatchingHistory__c');

        //Random Objects
        objectNames.add('c2g__codaTextDefinition__c');
        objectNames.add('c2g__codaIntercompanyDefinition__c');
        //objectNames.add('c2g__AsOfAging__c');
        objectNames.add('c2g__codaIntercompanyTransfer__c');
        objectNames.add('c2g__codaYear__c');

        return objectNames;     
    }
**/
    
    public static  testmethod void depreciateRental_TC(){
        
        // BLL6
        testData.refresh();
		//TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData();
		//try{
		// BLL6 end
        System.runAs(testData.testUser) {
	        FFAccounting ffa = new FFAccounting();
			th = TestHelper_MW.getInstance();
	        //  BLL6
			//testData.CurrentCompany = createFFACompany('FinancialForce', createFFAQueue(testData.TestUser.Id).Id);
			// BLL6 end
	        dealer__Vehicle_Inventory__c vehicle1 = th.getVehicleInventory('3');
	        dealer__Vehicle_Inventory__c vehicle2 = th.getVehicleInventory('4');
	        String vehicleIds = '';
	        if(vehicle1 != null){
	            vehicleIds += vehicle1.Id + '+';
	        }
	        if(vehicle2 != null){
	            vehicleIds += vehicle2.Id + '+';
	        }
			Test.startTest();
	        FFAccounting.depreciateRental(testData.CurrentCompany.Id, vehicleIds,'test@blackhole.org');
			Test.stopTest();
	    }
		// BLL6
	       //}catch(System.NullPointerException e){
	       //    System.Debug('Null Exception Error: ' + e);
	       //}
		// BLL6 end
    }


	// BLL24
	@IsTest
	static void testconcurpayables() {
		List<dealer__Purchase_Order__c> POList = [
			select Id, Name, dealer__PO_Number__c, dealer__Status__c, dealer__Post_Date_Time__c,   
				dealer__Vendor__c, dealer__Vendor__r.Name, dealer__Vendor__r.c2g__CODADaysOffset1__c, dealer__PO_Accounting_Name__c, dealer__Invoice_Number__c, 
				Payable_Invoice__c, dealer__Invoice_Amount__c, dealer__Invoice_Date__c,
				dealer__Company__c, dealer__Company__r.Financial_Force_Dimension_1__c,
				dealer__Company__r.Company__c, dealer__Company__r.Company__r.DefaultPayableDimension1__c, 
				Parts_Amount__c, dealer__Freight__c, NMEDA_Fee__c, Misc_Charge__c,
				dealer__PO_Amount__c, dealer__Type__c, RecordTypeId
			from dealer__Purchase_Order__c
		];	
        testData.refresh();
		System.runAs(testData.TestUser){
			Test.startTest();
			FFAccounting.createPayableInvoices(JSON.serialize(POList), UserInfo.getUserEmail());
			Test.stopTest();
		}
		
	}

	// BLL8
	@IsTest
	static void testPostCashEntry() {
        testData.refresh();
		th = TestHelper_MW.getInstance();
		FinancialForce_MBW.selectCompanyFor(testData.TestUser.Id, testData.CurrentCompany.Id);
		System.runAs(testData.TestUser){

			List<c2g__codaGeneralLedgerAccount__c> glalist = new List<c2g__codaGeneralLedgerAccount__c>(); 
			Integer i = 0;
			for(c2g__codaGeneralLedgerAccount__c gl : testData.GLAMap.values()) {
				glalist.add(gl);
			}

       		Account pa = th.getPersonAccount('1');
       		pa.c2g__CODAAccountsPayableControl__c = glalist[0].Id;
       		pa.c2g__CODAAccountsReceivableControl__c = glalist[0].Id;
       		pa.c2g__CODADimension1__c = testData.Dimension1.Id;
       		update(pa);
	
			update(new dealer__Dealer_Location__c(Id=testData.DealerLocation.Id, Financial_Force_Dimension_1__c=testData.Dimension1.Id));

			// Create cash entry
			Test.startTest();
        	c2g__codaBankAccount__c ba = [select Id from c2g__codaBankAccount__c limit 1];
			c2g__codaCashEntry__c ce = [select Id from c2g__codaCashEntry__c limit 1];
			FFAccounting.postCashEntry(ce.Id);
			Test.stopTest();
		}
		
	}
	// BLL8 end

/** BLL6
    public class TestData
    {
        public Account Account {get;set;}
        public c2g__codaCompany__c CurrentCompany {get;set;}
        public c2g__codaPeriod__c CurrentPeriod {get;set;}
        public c2g__codaAccountingCurrency__c HomeCurrency {get;set;}
        public Product2 Product {get;set;}
        public Map<String,c2g__codaGeneralLedgerAccount__c> GLAMap {get;set;}
        public User TestUser {get;set;}
        public void refresh()
        {
            this.TestUser = [Select Id From User Where Username = 'ffdeveloper@nowhere.com'];
            this.Account = [Select Id From Account limit 1];
            this.CurrentCompany = [Select Id From c2g__codaCompany__c];
            this.HomeCurrency = [Select Id From c2g__codaAccountingCurrency__c];
            this.Product = [Select Id From Product2];
                       
            this.CurrentPeriod = [Select Id From c2g__codaPeriod__c Where c2g__Description__c = 'Trading Period' And c2g__StartDate__c <= :System.today() And c2g__EndDate__c >= :System.today() limit 1];
        }
    }    
**/

}