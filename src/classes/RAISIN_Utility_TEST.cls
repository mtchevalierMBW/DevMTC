/**
 * RAISIN_Utility_TEST
 * Tests: RAISIN_Utility_TEST
 * Date: Feb 12, 2018
 * Programmer: Bryan Leaman
 *
 * Modifications
 *	2019-09-17	B. Leaman 	W-000730 BLL1- Fix failing tests with DT 5.x upgrade.
 *
 */
@isTest
private class RAISIN_Utility_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		//FFAdata.refresh(); 
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        TestHelper_MW th = new TestHelper_MW();
        
	    Account a = th.getPersonAccount('1');
	    
	    dealer__Dealer_Location__c loc = new dealer__Dealer_Location__c(
	    	Id=FFAdata.DealerLocation.Id,
	    	Raisin_Id__c = '1'
	    );
	    update(loc);
	    
	    dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
	    dsv.dealer__VIN__c ='Test963';
	    dsv.Name='Test';
	    dsv.dealer__Body_Style__c = 'Test';
	    dsv.dealer__Company_Number__c='12123';
	    //dsv.dealer__Veh_Owner_Contact__c = con.id;
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


        List<c2g__codaGeneralLedgerAccount__c> cgdlist = new List<c2g__codaGeneralLedgerAccount__c>();  // BLL4a
        c2g__codaGeneralLedgerAccount__c cgd = new c2g__codaGeneralLedgerAccount__c();
        cgd.c2g__ReportingCode__c ='52';
        cgd.c2g__Type__c = 'Manual Journal';
        cgd.Name = 'Test';
        //BLL4d insert cgd;
        cgdlist.add(cgd);   // BLL4a
	    
	    ServicePaymentType__c spt = new ServicePaymentType__c();
	        spt.Default_Labor_Rate__c = 12;
	        spt.Payment_Type__c = 'C'; 
	        spt.Labor_Sale_Account__c = cgd.Id; 	//cgd.id; 
	        spt.Labor_Cost_of_Sale_Account__c = cgd.Id;	//cgd3.id;	// was cgd
	        spt.Warranty_Receivable_Account__c = cgd.Id;	// cgd2.id;
	        spt.Description__c = 'Test';
	        spt.Shop_Supplies_Rate__c = 12;
	        spt.Hazmat_Fee__c = 12;
	        spt.Freight_Rate__c = 12;
	        spt.Parts_Cost_of_Sale__c = cgd.Id;	// cgd4.id;	// was cgd
	        spt.Parts_Inventory__c = cgd.Id;	// cgd5.id;	// was cgd
	        spt.Work_In_Process__c = cgd.Id;	// cgd6.id;	// was cgd
	        //spt.Warranty_Billing_Account__c=a.id; 
	        //spt.Labor_Sale_Account__c = cgd.id; 
	        spt.Parts_Sales__c = cgd.Id;	// cgd.id; 
	        //spt.Parts_Cost_of_Sale__c = cgd.id;   
	        spt.Internal_Sales__c = cgd.Id;	// cgd.id;  
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
	    
	    //dealer__Time_Clock__c dtc = new dealer__Time_Clock__c();
	    // dtc.dealer__Clock_Out__c =system.today();
	    // dtc.dealer__Clock_In__c =system.today();
	    // dtc.dealer__User__c =UserInfo.getUserId();
	    // //dtc.Date__c =system.today(); 
	    //insert dtc;
	    //
	    //dealer__Technician_Job_Time__c  dtj = new dealer__Technician_Job_Time__c ();
	    //    dtj.Name ='Test';
	    //    dtj.dealer__Service_Job_Line__c =dsj.id;
	    //    dtj.dealer__Start_Time__c=DateTime.now();	// BLL3c system.today();
	    //    dtj.dealer__End_Time__c =DateTime.now().addHours(1);	// BLL3c system.today();
	    //    dtj.Time_Clock_Entry__c =dtc.id;
	    //    dtj.dealer__Time_Clock__c =dtc.id;
	    //    dtj.Labor_Total__c =23;
	    //insert dtj;
	    
	    //ServiceMiscCharges__c smc1 = new ServiceMiscCharges__c (
	    //   Type__c = 'Freight',
	    //   Amount__c = 1.00,
	    //   Service_Job_Line__c = dsj.Id
	    //);
	    //insert(smc1);
		// BLL2a
	    //ServiceMiscCharges__c smc2 = new ServiceMiscCharges__c (
	    //   Type__c = 'Shop Supplies',
	    //   Amount__c = 2.00,
	    //   Service_Job_Line__c = dsj.Id,
	    //   General_Ledger_Account__c = glMap.get('4500').Id	// cgd.Id
	    //);
	    //insert(smc2);
	    // BLL2a end

        dealer__Parts_Master__c pm = new dealer__Parts_Master__c();
            pm.Name = 'Test';
            pm.dealer__Retail_Price__c = 0;
            pm.dealer__Manufacturer__c = 'KIT'; 
            pm.dealer__Cost__c = 100;          
            pm.dealer__Part_Description__c = 'Test description'; 
            pm.dealer__Raw_Part_Number__c = 'Raw-Test';
            insert pm; 
            
            dealer__Parts_Inventory__c part = new dealer__Parts_Inventory__c();
            part.dealer__Description__c = 'Oil Filter';
            part.dealer__Cost__c = 10;
            part.dealer__Source__c = 'Stocking';
            part.dealer__On_Hand__c = 100;
            part.dealer__Part_No__c = 'FL1A-XX';
            part.dealer__List__c = 22;
            part.dealer__Parts_Master__c = pm.Id;
            part.dealer__Location__c=loc.Id;
            part.dealer__On_Order__c = 10;
            insert part;  

        dealer__Parts_Invoice__c dv = new dealer__Parts_Invoice__c();
        dv.dealer__Comments__c = 'TestInvoice1';
        dv.dealer__Invoice_Number__c = 'TestInvoice1';
		// BLL1
		dv.dealer__Location__c = FFAdata.DealerLocation.Id;
		dv.dealer__Company_Number__c = FFAdata.DealerLocation.dealer__Company_Number__c;
		// BLL1 end
        insert dv;

        dealer__Parts_Invoice_Line__c dpi = new dealer__Parts_Invoice_Line__c();
        dpi.dealer__Bin__c ='Test1';
        dpi.dealer__Parts_Invoice__c = dv.id; 
        dpi.dealer__Service_Repair_Order__c = dsr.Id;
        dpi.dealer__Job_Line__c = dsj.Id;  
        dpi.dealer__Part_Number__c = 'Test1';
        dpi.dealer__Quantity_Sold__c = 12;
        dpi.dealer__Cost__c= 100; 
        dpi.dealer__Price__c= 150;
        dpi.dealer__Part__c = part.id;
        insert dpi;

	    MW_TriggerControls__c RAISIN_Hash = new MW_TriggerControls__c(Name='RAISIN_Hash', Enabled__c=true);
	    insert(RAISIN_Hash);
		
	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			RAISIN_Utility raisin = new RAISIN_Utility();
		}
	}
	
	static testMethod void batchTest() {

		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			RAISIN_Utility ba = new RAISIN_Utility();
			Map<Id, dealer__Service_Repair_Order__c> romap = new Map<Id, dealer__Service_Repair_Order__c>(
				[ select Id, Name from dealer__Service_Repair_Order__c ]
			); 
			ba.SendUpdateForJobIds(new List<Id>(romap.keySet()));
			Database.executeBatch(ba);
		}
		
	}
		
	static testMethod void TestCRON() {
		Test.startTest();
		List<String> jobIds = RAISIN_Utility.scheduleMe();
		String firstJobId = jobIds[0];

		// Get the information from the CronTrigger API object
		CronTrigger ct = [
			SELECT Id, CronExpression, TimesTriggered, NextFireTime
        	FROM CronTrigger 
        	WHERE id = :firstJobId
        ];
 
		// Verify the expressions are the same
		System.assertEquals(RAISIN_Utility.CRON_LIST[0], ct.CronExpression);
 
		// Verify the job has not run
		System.assertEquals(0, ct.TimesTriggered);
		
		Test.stopTest();
		
	}

}