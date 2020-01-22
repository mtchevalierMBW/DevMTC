/**
 * FFA_ServiceDepartment_TC
 * Tests: FFA_ServiceDepartment
 *
 * 	2016-01-25	B. Leaman	BLL1 - add test for error notification, chg m1 routine to use FFA setup data;
 *	2016-03-07	B. Leaman	BLL2 - increase coverage.
 *	2016-12-14	B. Leaman	BLL3 - Adjust for new validation rule that discount cannot exceed customer charges.
 *							Increase code coverage.
 *	2017-11-14	B. Leaman	BLL4 - need to turn on deletion override flag in dealerteam so ROs can be re-opened.
 *	2018-05-08	B. Leaman	BLL5 - new requirement of gl account on freight misc charges.
 *	2018-07-31	B. Leaman	BLL6 - re-open RO test was failing.
 *	2018-12-13	B. Leaman	W-000487 BLL7 - change in parts return process required GL accts (2114 instead of 1112).
 *
 */
//@isTest(seealldata=true)
@isTest
public  class FFA_ServiceDepartment_TC
{
	
	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); // BLL1
    
    @testSetup
    static void setupFFA() {
        TestHelper_MW.createBaseFFAData(FFAdata);
         
        List<c2g__codaGeneralLedgerAccount__c> glaccts = new List<c2g__codaGeneralLedgerAccount__c>();	// BLL3a
	    c2g__codaGeneralLedgerAccount__c cgd = new c2g__codaGeneralLedgerAccount__c();
	    cgd.c2g__ReportingCode__c ='5202';
	    cgd.c2g__Type__c='Manual Journal';
	    cgd.Name='Test';
	    cgd.VehicleRequired__c=true;	// BLL3a
	    glaccts.add(cgd);	// BLL3a
	    //BLL3d insert cgd;
	    c2g__codaGeneralLedgerAccount__c cgd2 = new c2g__codaGeneralLedgerAccount__c();
	    cgd2.c2g__ReportingCode__c ='4905';
	    cgd2.c2g__Type__c='Manual Journal';
	    cgd2.Name='Test';
	    cgd.VehicleRequired__c=true;	// BLL3a
	    glaccts.add(cgd2);	// BLL3a
	    //BLL3d insert cgd2;
		// BLL2a
	    c2g__codaGeneralLedgerAccount__c cgd3 = new c2g__codaGeneralLedgerAccount__c(
	    	Name='Test3301',
	    	c2g__ReportingCode__c ='3301',
	    	c2g__Type__c='Manual Journal'
	    );
	    glaccts.add(cgd3);	// BLL3a
	    //BLL3d insert cgd3;
	    c2g__codaGeneralLedgerAccount__c cgd4 = new c2g__codaGeneralLedgerAccount__c(
	    	Name='Test1100',
	    	c2g__ReportingCode__c ='1100',
	    	c2g__Type__c='Manual Journal'
	    );
	    glaccts.add(cgd4);	// BLL3a
	    //BLL3d insert cgd4;
	    c2g__codaGeneralLedgerAccount__c cgd5 = new c2g__codaGeneralLedgerAccount__c(
	    	Name='Test1110',
	    	c2g__ReportingCode__c ='1110',
	    	c2g__Type__c='Manual Journal'
	    );
	    glaccts.add(cgd5);	// BLL3a
	    //BLL3d insert cgd5;
	    c2g__codaGeneralLedgerAccount__c cgd6 = new c2g__codaGeneralLedgerAccount__c(
	    	Name='Test1111',
	    	c2g__ReportingCode__c ='1111',
	    	c2g__Type__c='Manual Journal'
	    );
	    glaccts.add(cgd6);	// BLL3a
	    //BLL3d insert cgd6;
	    c2g__codaGeneralLedgerAccount__c cgd7 = new c2g__codaGeneralLedgerAccount__c(
	    	Name='Test4500',
	    	c2g__ReportingCode__c ='4500',
	    	c2g__Type__c='Manual Journal'
	    );
	    glaccts.add(cgd7);	// BLL3a
	    //BLL3d insert cgd7;
	    c2g__codaGeneralLedgerAccount__c cgd8 = new c2g__codaGeneralLedgerAccount__c(
	    	Name='Test1112',
	    	c2g__ReportingCode__c ='1112',
	    	c2g__Type__c='Manual Journal'
	    );
	    glaccts.add(cgd8);	// BLL3a
	    //BLL3d insert cgd8;
	    c2g__codaGeneralLedgerAccount__c cgd9 = new c2g__codaGeneralLedgerAccount__c(
	    	Name='Test1113',
	    	c2g__ReportingCode__c ='1113',
	    	c2g__Type__c='Manual Journal'
	    );
	    glaccts.add(cgd9);	// BLL3a
	    //BLL3d insert cgd9;
	    // BLL2a end
	    c2g__codaGeneralLedgerAccount__c cgd10 = new c2g__codaGeneralLedgerAccount__c(
	    	Name='Test1220',
	    	c2g__ReportingCode__c ='1220',
	    	c2g__Type__c='Manual Journal'
	    );
	    glaccts.add(cgd10);	// BLL3a

		// BLL7
	    c2g__codaGeneralLedgerAccount__c cgd11 = new c2g__codaGeneralLedgerAccount__c(
	    	Name='Test2114',
	    	c2g__ReportingCode__c ='2114',
	    	c2g__Type__c='Manual Journal'
	    );
	    glaccts.add(cgd11);	
		// BLL7 end

	    insert(glaccts);	// BLL3a

		// BLL7
		MobilityForceSettings__c mfs = MobilityForceSettings__c.getOrgDefaults();
		mfs.Parts_Return_Credit_Acct__c = '2114';
		mfs.Parts_Return_Debit_Acct__c = '1220';
		upsert(mfs);
		// BLL7 end

        dealer__FixedOperationsSettings__c fos= new dealer__FixedOperationsSettings__c();
        fos.Name='Test';
        fos.dealer__Repair_Order_Index__c=12.45;
        insert fos;
            
	     dealer.TestClassUtil tc = new dealer.TestClassUtil();
	     tc.insertDMSSettings();

		// BLL4a
		dealer__TriggerControl__c dttc = dealer__TriggerControl__c.getOrgDefaults();
		dttc.dealer__DeletionOverride__c = true;
		upsert(dttc);
		// BLL4a end
		     
    }
    
	
	static testmethod void m2() {
    
    
    Group g= new Group();
    g.Type='Queue';
    g.name='test';
    //g.ownerid=UserInfo.getUserId();
    insert g;
    
    GroupMember gm= new GroupMember();
    gm.Groupid=g.id;
    gm.UserOrGroupId =UserInfo.getUserId();
    insert gm;
    
    }

    static testmethod void m1() {
    
    	Map<String,c2g__codaGeneralLedgerAccount__c> glMap = new Map<String,c2g__codaGeneralLedgerAccount__c>();
    	for(c2g__codaGeneralLedgerAccount__c g : [select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c limit 100]) { 
    		glMap.put(g.c2g__ReportingCode__c, g);
    	}
    
    	FFAdata.refresh();
    	System.runAs(FFAdata.TestUser) {
    		TestHelper_MW th = new TestHelper_MW();
    		
    		dealer__Dealer_Location__c loc = FFAdata.DealerLocation;
    		loc.Sales_Tax_Account__c = glMap.get('1220').Id; 
    		update(loc);
    
     	//dealer.TestClassUtil tc = new dealer.TestClassUtil();
     	//tc.insertDMSSettings();

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
	    dsv.dealer__VIN__c ='Test963';
	    dsv.Name='Test';
	    dsv.dealer__Body_Style__c = 'Test';
	    dsv.dealer__Company_Number__c='12123';
	    dsv.dealer__Veh_Owner_Contact__c = con.id;
	    dsv.dealer__Carline__c ='Test';
	    dsv.dealer__Make__c  ='Test';
	    dsv.dealer__Year__c  ='2013';
	    dsv.dealer__Stock_Number__c='1235';
	    insert dsv;
    
	    dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
	    dsr.dealer__Customer__c= a.id;
	    dsr.dealer__Mileage_In__c=10000;
	    dsr.dealer__Service_Advisor__c=UserInfo.getUserid();
	    dsr.dealer__Vehicle__c=dsv.id;
	    dsr.dealer__Status__c='Open';
	    dsr.dealer__Tag__c='1244';
	    dsr.dealer__RO_Number__c='abc0013444'; 
	    // BLL1d dsr.dealer__Company__c=ddl.id;
	    dsr.dealer__Company__c = FFAdata.DealerLocation.Id; // BLL1a
	    dsr.dealer__Discount_Total__c = 0; 	//BLL3c 10; // BLL2a
	    dsr.dealer__Customer_Tax__c = 1;	// BLL3a
	    insert dsr ;  
	    
	    ServicePaymentType__c spt = new ServicePaymentType__c();
	        spt.Default_Labor_Rate__c = 12;
	        spt.Payment_Type__c = 'C'; 
	        spt.Labor_Sale_Account__c = glMap.get('5202').Id; 	//cgd.id; 
	        spt.Labor_Cost_of_Sale_Account__c = glMap.get('3301').Id;	//cgd3.id;	// was cgd
	        spt.Warranty_Receivable_Account__c = glMap.get('4905').Id;	// cgd2.id;
	        spt.Description__c = 'Test';
	        spt.Shop_Supplies_Rate__c = 12;
	        spt.Hazmat_Fee__c = 12;
	        spt.Freight_Rate__c = 12;
	        spt.Parts_Cost_of_Sale__c = glMap.get('1100').Id;	// cgd4.id;	// was cgd
	        spt.Parts_Inventory__c = glMap.get('1110').Id;	// cgd5.id;	// was cgd
	        spt.Work_In_Process__c = glMap.get('1111').Id;	// cgd6.id;	// was cgd
	        //spt.Warranty_Billing_Account__c=a.id; 
	        //spt.Labor_Sale_Account__c = cgd.id; 
	        spt.Parts_Sales__c = glMap.get('1112').Id;	// cgd.id; 
	        //spt.Parts_Cost_of_Sale__c = cgd.id;   
	        spt.Internal_Sales__c = glMap.get('1113').Id;	// cgd.id;  
	        insert spt; 
	
	     dealer__Service_Job__c dsj = new dealer__Service_Job__c();
	     dsj.dealer__Cause__c ='Test';
	     dsj.dealer__Labor_Charges__c =12;
	     dsj.dealer__Service_Repair_Order__c =dsr.id;
	     dsj.dealer__Labor_Type__c = 'C';  // BLL1a
	     dsj.Payment_Method__c = spt.id;
	     dsj.dealer__Parts_Total__c=4;
	     dsj.dealer__Misc_Charges__c =5;
	     dsj.dealer__Actual_Time__c = 1;	// BLL3a
	     dsj.dealer__Parts_Total__c = 10;	// BLL3a
	    insert dsj;
	    
	    dealer__Time_Clock__c dtc = new dealer__Time_Clock__c();
	     dtc.dealer__Clock_Out__c =system.today();
	     dtc.dealer__Clock_In__c =system.today();
	     dtc.dealer__User__c =UserInfo.getUserId();
	     //dtc.Date__c =system.today(); 
	    insert dtc;
	    
	    dealer__Technician_Job_Time__c  dtj = new dealer__Technician_Job_Time__c ();
	        dtj.Name ='Test';
	        dtj.dealer__Service_Job_Line__c =dsj.id;
	        dtj.dealer__Start_Time__c=DateTime.now();	// BLL3c system.today();
	        dtj.dealer__End_Time__c =DateTime.now().addHours(1);	// BLL3c system.today();
	        dtj.Time_Clock_Entry__c =dtc.id;
	        dtj.dealer__Time_Clock__c =dtc.id;
	        dtj.Labor_Total__c =23;
	    insert dtj;
	    
	    ServiceMiscCharges__c smc1 = new ServiceMiscCharges__c (
	       Type__c = 'Freight',
	       Amount__c = 1.00,
	       Service_Job_Line__c = dsj.Id,
	       General_Ledger_Account__c = glMap.get('4905').Id	// BLL5a	
	    );
	    insert(smc1);
		// BLL2a
	    ServiceMiscCharges__c smc2 = new ServiceMiscCharges__c (
	       Type__c = 'Shop Supplies',
	       Amount__c = 2.00,
	       Service_Job_Line__c = dsj.Id,
	       General_Ledger_Account__c = glMap.get('4500').Id	// cgd.Id
	    );
	    insert(smc2);
	    // BLL2a end
	
	   /* dealer__Cashering__c  dcg= [select id from dealer__Cashering__c limit 1];
	     Map<Id, c2g__codaJournalLineItem__c> jLines = new Map<Id, c2g__codaJournalLineItem__c>(); 
	     jLines.get(cgd.id); */

	   // Cashiering entries
	   List<dealer__Cashering__c> ces = new List<dealer__Cashering__c>();
	   ces.add(new dealer__Cashering__c(dealer__Service_Repair_Order__c=dsr.Id, dealer__Amount__c=1,dealer__Payment_Method__c='Cash',dealer__Customer__c=a.Id,dealer__Deposit__c=true ));
	   ces.add(new dealer__Cashering__c(dealer__Service_Repair_Order__c=dsr.Id, dealer__Amount__c=2,dealer__Payment_Method__c='Cash',dealer__Customer__c=a.Id,dealer__Deposit__c=false ));
	   Account tpp = th.getThirdPartyAccount('1');
	   ces.add(new dealer__Cashering__c(dealer__Service_Repair_Order__c=dsr.Id, dealer__Amount__c=3,dealer__Payment_Method__c='Cash',dealer__Customer__c=tpp.Id,dealer__Deposit__c=false ));
	   insert(ces);
	   System.debug(ces[0]);
	    List<dealer__Cashering__c> checkces = [select Id, Name from dealer__Cashering__c where dealer__Service_Repair_Order__c=:dsr.Id];
		System.debug(checkces);

		Test.startTest();
	    System.debug('PostRepairOrder-begin');
	    FFA_ServiceDepartment.postRepairOrder(dsr.Id);
		System.debug('PostRepairOrder-complete');
		Test.stopTest();
	    
    	} // BLL1a
    	
    }
    
    // BLL1a
    private static testMethod void testNotification() {
         String r = 'testingNotification';
         Id uid = UserInfo.getUserId();
         c2g__codaJournal__c j = new c2g__codaJournal__c();
         List<c2g__codaJournalLineItem__c> l = new List<c2g__codaJournalLineItem__c>();
         Integer x = 1;
         Integer y = 0;
         Test.startTest();
         try {
             x = x/y;    // Cause div/0 error!
         } catch(Exception e) {
             FFA_ServiceDepartment.notifyException(r, e, uid, j, l);
         }
         Test.stopTest();
    }
    // BLL1a end
    
	// BLL3a
    static testmethod void testWarrantyAcct()
    {
    
    	Map<String,c2g__codaGeneralLedgerAccount__c> glMap = new Map<String,c2g__codaGeneralLedgerAccount__c>();
    	for(c2g__codaGeneralLedgerAccount__c g : [select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c limit 100]) { 
    		glMap.put(g.c2g__ReportingCode__c, g);
    	}
    
    	FFAdata.refresh();
    	System.runAs(FFAdata.TestUser) {
    
		    //dealer.TestClassUtil tc = new dealer.TestClassUtil();
	     	//tc.insertDMSSettings();
	     	TestHelper_MW th = new TestHelper_MW();
	        
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
	
	    	Account w = th.getVendorAccount('1');
	    
		    dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
		    dsv.dealer__VIN__c ='Test963';
		    dsv.Name='Test';
		    dsv.dealer__Body_Style__c = 'Test';
		    dsv.dealer__Company_Number__c='12123';
		    dsv.dealer__Veh_Owner_Contact__c = con.id;
		    dsv.dealer__Carline__c ='Test';
		    dsv.dealer__Make__c  ='Test';
		    dsv.dealer__Year__c  ='2013';
		    dsv.dealer__Stock_Number__c='1235';
		    insert dsv;
	    
		    dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
	    	dsr.dealer__Customer__c= a.id;
	    	dsr.dealer__Mileage_In__c=10000;
	    	dsr.dealer__Service_Advisor__c=UserInfo.getUserid();
	    	dsr.dealer__Vehicle__c=dsv.id;
	    	dsr.dealer__Status__c='Open';
	    	dsr.dealer__Tag__c='1244';
	    	dsr.dealer__RO_Number__c='abc0013444'; 
	    	dsr.dealer__Company__c = FFAdata.DealerLocation.Id; // BLL1a
	    	dsr.dealer__Discount_Total__c = 0; //BLL3c 10; // BLL2a
	    	insert dsr ;  
	    
	    	ServicePaymentType__c spt = new ServicePaymentType__c();
	        spt.Default_Labor_Rate__c = 12;
	        spt.Payment_Type__c = 'W'; 
	        spt.Labor_Sale_Account__c = glMap.get('5202').Id; 	//cgd.id; 
	        spt.Labor_Cost_of_Sale_Account__c = glMap.get('3301').Id;	//cgd3.id;	// was cgd
	        spt.Warranty_Receivable_Account__c = glMap.get('4905').Id;	// cgd2.id;
	        spt.Description__c = 'Test';
	        spt.Shop_Supplies_Rate__c = 12;
	        spt.Hazmat_Fee__c = 12;
	        spt.Freight_Rate__c = 12;
	        spt.Parts_Cost_of_Sale__c = glMap.get('1100').Id;	// cgd4.id;	// was cgd
	        spt.Parts_Inventory__c = glMap.get('1110').Id;	// cgd5.id;	// was cgd
	        spt.Work_In_Process__c = glMap.get('1111').Id;	// cgd6.id;	// was cgd
	        spt.Warranty_Billing_Account__c=w.id; 
	        spt.Parts_Sales__c = glMap.get('1112').Id;	// cgd.id; 
	        spt.Internal_Sales__c = glMap.get('1113').Id;	// cgd.id;  
	        insert spt; 
	
	     	dealer__Service_Job__c dsj = new dealer__Service_Job__c();
	     	dsj.dealer__Cause__c ='Test';
	     	dsj.dealer__Labor_Charges__c =12;
	     	dsj.dealer__Service_Repair_Order__c =dsr.id;
	     	dsj.dealer__Labor_Type__c = 'C';  // BLL1a
	     	dsj.Payment_Method__c = spt.id;
	     	dsj.dealer__Parts_Total__c=4;
	     	dsj.dealer__Misc_Charges__c =5;
	     	dsj.dealer__Actual_Time__c = 1;	// BLL3a
	     	dsj.dealer__Parts_Total__c = 10;	// BLL3a
	    	insert dsj;
	    
	    	dealer__Time_Clock__c dtc = new dealer__Time_Clock__c();
	     	dtc.dealer__Clock_Out__c =system.today();
	     	dtc.dealer__Clock_In__c =system.today();
	     	dtc.dealer__User__c =UserInfo.getUserId();
	     	//dtc.Date__c =system.today(); 
	    	insert dtc;
	    
	    	dealer__Technician_Job_Time__c  dtj = new dealer__Technician_Job_Time__c ();
		    dtj.Name ='Test';
	        dtj.dealer__Service_Job_Line__c =dsj.id;
	        dtj.dealer__Start_Time__c=DateTime.now();	// BLL3c system.today();
	        dtj.dealer__End_Time__c =DateTime.now().addHours(1);	// BLL3c system.today();	// BLL3a add 1 hour
	        dtj.Time_Clock_Entry__c =dtc.id;
	        dtj.dealer__Time_Clock__c =dtc.id;
	        dtj.Labor_Total__c =23;
	    	insert dtj;
	    
	    	List<ServiceMiscCharges__c> miscchgs = new List<ServiceMiscCharges__c>(); 
	    	ServiceMiscCharges__c smc1 = new ServiceMiscCharges__c (
	       	Type__c = 'Freight',
	       	Amount__c = 1.00,
	       	Service_Job_Line__c = dsj.Id,
	        General_Ledger_Account__c = glMap.get('4905').Id	// BLL5a	
	    	);
	    	miscchgs.add(smc1);
	    	//insert(smc1);
			// BLL2a
	    	ServiceMiscCharges__c smc2 = new ServiceMiscCharges__c (
	       	Type__c = 'Shop Supplies',
	       	Amount__c = 2.00,
	       	Service_Job_Line__c = dsj.Id,
	       	General_Ledger_Account__c = glMap.get('4500').Id	// cgd.Id
	    	);
	    	miscchgs.add(smc2);
	    	//insert(smc2);
	    	// BLL2a end
	    	insert(miscchgs);
	    Test.startTest();
		    FFA_ServiceDepartment.postRepairOrder(dsr.Id);
    	Test.stopTest();
    	} // BLL1a
    	
    }

    static testmethod void testInternalChgs()
    {
    
    	Map<String,c2g__codaGeneralLedgerAccount__c> glMap = new Map<String,c2g__codaGeneralLedgerAccount__c>();
    	for(c2g__codaGeneralLedgerAccount__c g : [select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c limit 100]) { 
    		glMap.put(g.c2g__ReportingCode__c, g);
    	}
    
    	FFAdata.refresh();
    	System.runAs(FFAdata.TestUser) {
    
		    //dealer.TestClassUtil tc = new dealer.TestClassUtil();
	     	//tc.insertDMSSettings();
	        
	    	//Account a = new Account();
		    //a.LastName ='Test';
		    //a.AccountSource ='Dealer';
		    //a.BillingState = 'CA';
	    	//insert a;
			TestHelper_MW th = new TestHelper_MW();
			Account a = th.getBusinessAccount('1');
	    
		    contact con = new contact();
		    con.Phone = '8888888';
		    con.LastName = 'Test';
		    insert con;
	
		    dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
		    dsv.dealer__VIN__c ='Test963';
		    dsv.Name='Test';
		    dsv.dealer__Body_Style__c = 'Test';
		    dsv.dealer__Company_Number__c='12123';
		    dsv.dealer__Veh_Owner_Contact__c = con.id;
		    dsv.dealer__Carline__c ='Test';
		    dsv.dealer__Make__c  ='Test';
		    dsv.dealer__Year__c  ='2013';
		    dsv.dealer__Stock_Number__c='1235';
		    insert dsv;
	    
		    dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
	    	dsr.dealer__Customer__c= a.id;
	    	dsr.dealer__Mileage_In__c=10000;
	    	dsr.dealer__Service_Advisor__c=UserInfo.getUserid();
	    	dsr.dealer__Vehicle__c=dsv.id;
	    	dsr.dealer__Status__c='Open';
	    	dsr.dealer__Tag__c='1244';
	    	dsr.dealer__RO_Number__c='abc0013444'; 
	    	dsr.dealer__Company__c = FFAdata.DealerLocation.Id; // BLL1a
	    	dsr.dealer__Discount_Total__c = 0; //BLL3c 10; // BLL2a
	    	insert dsr ;  
	    
	    	ServicePaymentType__c spt = new ServicePaymentType__c();
	        spt.Default_Labor_Rate__c = 12;
	        spt.Payment_Type__c = 'I'; 
	        spt.Labor_Sale_Account__c = glMap.get('5202').Id; 	//cgd.id; 
	        spt.Labor_Cost_of_Sale_Account__c = glMap.get('3301').Id;	//cgd3.id;	// was cgd
	        spt.Warranty_Receivable_Account__c = glMap.get('4905').Id;	// cgd2.id;
	        spt.Description__c = 'Test';
	        spt.Shop_Supplies_Rate__c = 12;
	        spt.Hazmat_Fee__c = 12;
	        spt.Freight_Rate__c = 12;
	        spt.Parts_Cost_of_Sale__c = glMap.get('1100').Id;	// cgd4.id;	// was cgd
	        spt.Parts_Inventory__c = glMap.get('1110').Id;	// cgd5.id;	// was cgd
	        spt.Work_In_Process__c = glMap.get('1111').Id;	// cgd6.id;	// was cgd
	        spt.Parts_Sales__c = glMap.get('1112').Id;	// cgd.id; 
	        spt.Internal_Sales__c = glMap.get('1113').Id;	// cgd.id;  
	        insert spt; 
	
	     	dealer__Service_Job__c dsj = new dealer__Service_Job__c();
	     	dsj.dealer__Cause__c ='Test';
	     	dsj.dealer__Labor_Charges__c =12;
	     	dsj.dealer__Service_Repair_Order__c =dsr.id;
	     	dsj.dealer__Labor_Type__c = 'C';  // BLL1a
	     	dsj.Payment_Method__c = spt.id;
	     	dsj.dealer__Parts_Total__c=4;
	     	dsj.dealer__Misc_Charges__c =5;
	     	dsj.dealer__Actual_Time__c = 1;	// BLL3a
	     	dsj.dealer__Parts_Total__c = 10;	// BLL3a
	    	insert dsj;
	    
	    	dealer__Time_Clock__c dtc = new dealer__Time_Clock__c();
	     	dtc.dealer__Clock_Out__c =system.today();
	     	dtc.dealer__Clock_In__c =system.today();
	     	dtc.dealer__User__c =UserInfo.getUserId();
	     	//dtc.Date__c =system.today(); 
	    	insert dtc;
	    
	    	dealer__Technician_Job_Time__c  dtj = new dealer__Technician_Job_Time__c ();
		    dtj.Name ='Test';
	        dtj.dealer__Service_Job_Line__c =dsj.id;
	        dtj.dealer__Start_Time__c=DateTime.Now();	// BLL3c system.today();
	        dtj.dealer__End_Time__c =DateTime.Now().addHours(1);	// BLL3c system.today();	// BLL3a add 1 hour
	        dtj.Time_Clock_Entry__c =dtc.id;
	        dtj.dealer__Time_Clock__c =dtc.id;
	        dtj.Labor_Total__c =23;
	    	insert dtj;
	    
	    	List<ServiceMiscCharges__c> miscchgs = new List<ServiceMiscCharges__c>(); 
	    	ServiceMiscCharges__c smc1 = new ServiceMiscCharges__c (
	       	Type__c = 'Freight',
	       	Amount__c = 1.00,
	       	Service_Job_Line__c = dsj.Id,
	        General_Ledger_Account__c = glMap.get('4905').Id	// BLL5a	
	    	);
	    	miscchgs.add(smc1);
	    	//insert(smc1);
			// BLL2a
	    	ServiceMiscCharges__c smc2 = new ServiceMiscCharges__c (
	       	Type__c = 'Shop Supplies',
	       	Amount__c = 2.00,
	       	Service_Job_Line__c = dsj.Id,
	       	General_Ledger_Account__c = glMap.get('4500').Id	// cgd.Id
	    	);
	    	miscchgs.add(smc2);
	    	//insert(smc2);
	    	// BLL2a end
	    	insert(miscchgs);
	    Test.startTest();
		    FFA_ServiceDepartment.postRepairOrder(dsr.Id);
    	Test.stopTest();
    	} // BLL1a
    	
    }

    /* Added 10/2/17 - JVK */
    private static testmethod void testRepairOrderReversal() {
    
    	Map<String,c2g__codaGeneralLedgerAccount__c> glMap = new Map<String,c2g__codaGeneralLedgerAccount__c>();
    	for(c2g__codaGeneralLedgerAccount__c g : [select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c limit 100]) { 
    		glMap.put(g.c2g__ReportingCode__c, g);
    	}

        // Create the custom setting to allow re-opening
		MW_TriggerControls__c tc = new MW_TriggerControls__c();
        tc.Name = 'RepairOrderProtect';
        tc.Enabled__c = false;
        insert tc;       
    
    	FFAdata.refresh();
    	System.runAs(FFAdata.TestUser) {
    
		    //dealer.TestClassUtil tc = new dealer.TestClassUtil();
	     	//tc.insertDMSSettings();
	        
	    	//Account a = new Account();
		    //a.LastName ='Test';
		    //a.AccountSource ='Dealer';
		    //a.BillingState = 'CA';
	    	//insert a;
			TestHelper_MW th = new TestHelper_MW();
			Account a = th.getBusinessAccount('1');
	    
		    contact con = new contact();
		    con.Phone = '8888888';
		    con.LastName = 'Test';
		    insert con;
	
		    dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
		    dsv.dealer__VIN__c ='Test963';
		    dsv.Name='Test';
		    dsv.dealer__Body_Style__c = 'Test';
		    dsv.dealer__Company_Number__c='12123';
		    dsv.dealer__Veh_Owner_Contact__c = con.id;
		    dsv.dealer__Carline__c ='Test';
		    dsv.dealer__Make__c  ='Test';
		    dsv.dealer__Year__c  ='2013';
		    dsv.dealer__Stock_Number__c='1235';
		    insert dsv;
	    
		    dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
	    	dsr.dealer__Customer__c= a.id;
	    	dsr.dealer__Mileage_In__c=10000;
	    	dsr.dealer__Service_Advisor__c=UserInfo.getUserid();
	    	dsr.dealer__Vehicle__c=dsv.id;
	    	dsr.dealer__Status__c='Open';
	    	dsr.dealer__Tag__c='1244';
	    	dsr.dealer__RO_Number__c='RO12345X'; 
	    	dsr.dealer__Company__c = FFAdata.DealerLocation.Id;
	    	dsr.dealer__Discount_Total__c = 0;
	    	insert dsr ;  
	    
	    	ServicePaymentType__c spt = new ServicePaymentType__c();
	        spt.Default_Labor_Rate__c = 12;
	        spt.Payment_Type__c = 'I'; 
	        spt.Labor_Sale_Account__c = glMap.get('5202').Id; 	
	        spt.Labor_Cost_of_Sale_Account__c = glMap.get('3301').Id;	
	        spt.Warranty_Receivable_Account__c = glMap.get('4905').Id;
	        spt.Description__c = 'Test';
	        spt.Shop_Supplies_Rate__c = 12;
	        spt.Hazmat_Fee__c = 12;
	        spt.Freight_Rate__c = 12;
	        spt.Parts_Cost_of_Sale__c = glMap.get('1100').Id;
	        spt.Parts_Inventory__c = glMap.get('1110').Id;
	        spt.Work_In_Process__c = glMap.get('1111').Id;
	        spt.Parts_Sales__c = glMap.get('1112').Id;
	        spt.Internal_Sales__c = glMap.get('1113').Id;  
	        insert spt; 
	
	     	dealer__Service_Job__c dsj = new dealer__Service_Job__c();
	     	dsj.dealer__Cause__c ='Test';
	     	dsj.dealer__Labor_Charges__c =12;
	     	dsj.dealer__Service_Repair_Order__c =dsr.id;
	     	dsj.dealer__Labor_Type__c = 'I'; 
	     	dsj.Payment_Method__c = spt.id;
	     	dsj.dealer__Parts_Total__c=4;
	     	//BLL6d dsj.dealer__Misc_Charges__c =5;	// journal doesn't add up w/out actual misc charge lines  
	     	dsj.dealer__Actual_Time__c = 1;	// BLL3a
	     	dsj.dealer__Parts_Total__c = 10;	// BLL3a
	     	dsj.dealer__Stat__c = 'Complete';	// BLL6a
	    	insert dsj;
	    
	    Test.startTest();
		    System.debug('PostRepairOrderForReversal-begin');
		    FFA_ServiceDepartment.postRepairOrder(dsr.Id);
		    System.debug('PostRepairOrderForReversal-end');
		    update(new dealer__Service_Repair_Order__c(Id=dsr.Id, dealer__Status__c='Posted', dealer__Posted_Date_Time__c=DateTime.now()));
		    System.debug([select Id, dealer__Status__c from dealer__Service_Repair_Order__c where Id=:dsr.Id]);
		    System.debug('ReverseServiceRepairOrder-begin');
            FFAccounting.reverseServiceRepairOrder(dsr.Id);
		    System.debug('ReverseServiceRepairOrder-end');
    	Test.stopTest();
    	} // BLL1a
    	        
    }

	private static testmethod void testPartsReturn() {
		FFA_ServiceDepartment ffasd = new FFA_ServiceDepartment();	// Just call the constructor
        FFAdata.refresh();
        TestHelper_MW th = new TestHelper_MW();

    	Map<String,c2g__codaGeneralLedgerAccount__c> glMap = new Map<String,c2g__codaGeneralLedgerAccount__c>();
    	for(c2g__codaGeneralLedgerAccount__c g : [select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c limit 100]) { 
    		glMap.put(g.c2g__ReportingCode__c, g);
    	}

        c2g__codaDimension1__c cgd1 = new c2g__codaDimension1__c();
    
        cgd1.c2g__ExternalId__c='172';
        cgd1.c2g__ReportingCode__c='Akron Ohio';
        cgd1.c2g__UnitOfWork__c =12;
        insert cgd1;

        c2g__codaCompany__c company = FFAdata.CurrentCompany;

		List<dealer__Dealer_Location__c> locs = new List<dealer__Dealer_Location__c>();
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
   		loc.Sales_Tax_Account__c = glMap.get('1220').Id; 
		locs.add(loc);
        
        dealer__Dealer_Location__c loc2 = new dealer__Dealer_Location__c();
        loc2.Name = 'Test Location One';
        loc2.dealer__Company_Number__c = 'MKR';
        loc2.Region__c = '2';
        loc2.dealer__General_Manager__c = UserInfo.getUserId();
        loc2.Rental_Manager__c = UserInfo.getUserId();
        loc2.dealer__City__c = 'WhiteField';
        loc2.dealer__State__c = 'CA';
        loc2.dealer__Postal_Code__c = '44826';
        loc2.Financial_Force_Dimension_1__c = cgd1.Id;
        loc2.Company__c = company.Id;
   		loc2.Sales_Tax_Account__c = glMap.get('1220').Id; 
        locs.add(loc2);
        insert(locs);

        System.runAs(FFAdata.TestUser){    

            Account accRec = th.getPersonAccount('1');
            Id conId = accRec.PersonContactId;

            dealer__Vehicle_Inventory__c dvi = new dealer__Vehicle_Inventory__c();
            dvi.dealer__VIN__c ='test';
            dvi.dealer__Vehicle_Order_Number__c ='Test';
            dvi.dealer__Make__c='Test';
            dvi.dealer__Model__c='Test';
            dvi.dealer__Stock_Number__c='1';
            dvi.dealer__Year__c='2014';
            insert dvi;

            dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
            dsv.Name='Test';
            dsv.dealer__VIN__c ='2C4RDGBG2FR581207';
            dsv.dealer__Body_Style__c = 'Test';
            dsv.dealer__Company_Number__c=FFAdata.DealerLocation.dealer__Company_Number__c;	// BLL2a
            dsv.dealer__Veh_Owner_Contact__c = conId;
            dsv.dealer__Carline__c ='Test';
            dsv.dealer__Make__c  ='Test';
            dsv.dealer__Year__c  ='2013';
            dsv.dealer__Last_Odometer__c =1;
            dsv.dealer__Sales_Inventory__c =dvi.id;
            insert dsv;

		    dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
		    dsr.dealer__Customer__c= accRec.id;
		    dsr.dealer__Mileage_In__c=10000;
		    dsr.dealer__Service_Advisor__c=UserInfo.getUserid();
		    dsr.dealer__Vehicle__c=dsv.id;
		    dsr.dealer__Status__c='Open';
		    dsr.dealer__Tag__c='1244';
		    dsr.dealer__RO_Number__c='abc0013444'; 
		    dsr.dealer__Company__c = FFAdata.DealerLocation.Id; // BLL1a
		    dsr.dealer__Discount_Total__c = 0; 	//BLL3c 10; // BLL2a
		    dsr.dealer__Customer_Tax__c = 1;	// BLL3a
		    insert dsr ;  
	    
		    ServicePaymentType__c spt = new ServicePaymentType__c();
	        spt.Default_Labor_Rate__c = 12;
	        spt.Payment_Type__c = 'C'; 
	        spt.Labor_Sale_Account__c = glMap.get('5202').Id; 	//cgd.id; 
	        spt.Labor_Cost_of_Sale_Account__c = glMap.get('3301').Id;	//cgd3.id;	// was cgd
	        spt.Warranty_Receivable_Account__c = glMap.get('4905').Id;	// cgd2.id;
	        spt.Description__c = 'Test';
	        spt.Shop_Supplies_Rate__c = 12;
	        spt.Hazmat_Fee__c = 12;
	        spt.Freight_Rate__c = 12;
	        spt.Parts_Cost_of_Sale__c = glMap.get('1100').Id;	// cgd4.id;	// was cgd
	        spt.Parts_Inventory__c = glMap.get('1110').Id;	// cgd5.id;	// was cgd
	        spt.Work_In_Process__c = glMap.get('1111').Id;	// cgd6.id;	// was cgd
	        spt.Parts_Sales__c = glMap.get('1112').Id;	// cgd.id; 
	        spt.Internal_Sales__c = glMap.get('1113').Id;	// cgd.id;  
	        insert spt; 
	
		    dealer__Service_Job__c dsj = new dealer__Service_Job__c();
		    dsj.dealer__Cause__c ='Test';
		    dsj.dealer__Labor_Charges__c =12;
		    dsj.dealer__Service_Repair_Order__c =dsr.id;
		    dsj.dealer__Labor_Type__c = 'C';  // BLL1a
		    dsj.Payment_Method__c = spt.id;
		    dsj.dealer__Parts_Total__c=4;
		    dsj.dealer__Misc_Charges__c =5;
		    dsj.dealer__Actual_Time__c = 1;	// BLL3a
		    dsj.dealer__Parts_Total__c = 10;	// BLL3a
			insert dsj;
            
            dealer__Parts_Invoice__c pi = new dealer__Parts_Invoice__c();
            pi.dealer__Customer__c = accRec.Id;
            pi.dealer__Customer_Contact__c = conId;
            pi.Name = 'Test Invoice';
            pi.dealer__Comapny_Number__c = loc.dealer__Company_Number__c;
            pi.dealer__Location__c = loc.Id;
            pi.dealer__Deposit__c = 100;
            pi.dealer__Invoice_Number__c = 'inv1234';            
            insert pi;            
            
            //For loop to insert Parts Lines for SRO and Service Job
        	List<dealer__Parts_Invoice_Line__c> partslines = new List<dealer__Parts_Invoice_Line__c>();	// BLL1a
        	for(Integer i=0; i<2;i++){
        		System.debug('Line loop count='+String.valueOf(i));	// BLL1a
        	    dealer__Parts_Invoice_Line__c objPartLine = new dealer__Parts_Invoice_Line__c();
        	    objPartLine.Name = dsj.Name;            
        	    objPartLine.dealer__Service_Repair_Order__c = dsr.Id;
        	    objPartLine.dealer__Job_Line__c = dsj.Id;    
        	    objPartLine.dealer__Price__c = 10+i;
        	    objPartLine.dealer__Quantity_Sold__c = 1+i;
        	    objPartLine.dealer__Core__c = 5+i;
        	    objPartLine.dealer__Part_Number__c='12'+i;
        	    objPartLine.dealer__Parts_Invoice__c =pi.Id;
        	    objPartLine.dealer__Cost__c = 10.0;	// BLL1a
        	    partslines.add(objPartLine);	// BLL1a                
        	} 
			insert(partslines);	// BLL1a
            
            //dealer__Purchase_Order__c misc = [Select Id, dealer__PO_Amount__c from dealer__Purchase_Order__c where RecordType.Name = 'Miscellaneous' limit 1];
            //dealer__Purchase_Order__c po = new dealer__Purchase_Order__c();
	        //po.RecordTypeId = rtInfo.getRecordTypeId();	// BLL1a
	        //po.dealer__Vendor__c = a.Id;
	        //po.dealer__Service_Repair_Order__c = dsr.Id;
	        //insert po;

	        //dealer__Purchase_Order_Line__c poline = new dealer__Purchase_Order_Line__c();
	        //poline.dealer__Purchase_Order__c = po.Id;
	        //poline.dealer__Service_Job_Line__c = dsj.Id;
	        //poline.dealer__Amount__c = 100;
   		    //insert poline;
            
            
			Test.startTest();
			FFA_ServiceDepartment.postPartsReturn(pi.Id);
            Test.stopTest();
        }

	}
	// BLL3a end
    
}