/**
 * ServiceRepairOrder2_TC
 * Tests: ServiceROCalc trigger, ServiceRepairOrder2 controller, ServiceMiscChargeController, ServiceMiscManagedToCustomCopy
 *
 * 2015-09-11   B. Leaman   BLL1 - increase code coverage for ServiceROCalc trigger.
 * 2015-11-17   B. Leaman   BLL2 - Too many soql queries -- use Test.startTest() & Test.stopTest() to reduce #.
 * 2016-01-07	B. Leaman	BLL3 - create custom setting MW_TriggerControls__c.getInstance('RepairOrderProtect') to improve code coverage
 * 2016-06-08	B. Leaman	Bulk insert lines & misc chgs to reduce SOQL. Add test for delete of RO (ServiceROCalc trigger)
 * 2016-12-19	B. Leaman 	BLL4 - Standardize location & authority for Myunittest method.
 * 2017-04-20 	B. Leaman 	BLL6 - need servicepaymenttype on job lines for tech time to be valid.
 * 2017-07-25	B. Leaman	BLL6 - new class to test.
 * 2017-10-17	B. Leaman	BLL7 - additional code coverage.
 * 2018-04-06	B. Leaman	BLL9 - Added tests for ServiceMiscChargeController and ServiceMiscManagedToCustomCopy trigger.
 * 2018-11-18	B. Leaman	W-000530 BLL10 - additional code coverage for getready & updating vehicle. causing issues in production.
 * 2019-08-20	B. Leaman	W-000728 BLL11 - additional code coverage
 */
@isTest
Public Class ServiceRepairOrder2_TC{

	@testsetup static void setup() {

        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        
   		insert(new MW_TriggerControls__c(Name='RepairOrderProtect', Enabled__c=true));  // BLL3a

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


		TestHelper_MW th = TestHelper_MW.getInstance();
		Account a = th.getPersonAccount('1');
		dealer__Dealer_Location__c ddl = th.getDealerLocation('1');

      // BLL6a need this for new tech time validation rule
      List<ServicePaymentType__c> spts = new List<ServicePaymentType__c>();
      spts.add(new ServicePaymentType__c(Name='CR',Default_Labor_Rate__c=52,Description__c='Test ABC', Payment_Type__c='C'));
      spts.add(new ServicePaymentType__c(Name='CR80',Default_Labor_Rate__c=52,Description__c='Test DEF', Payment_Type__c='C'));
      spts.add(new ServicePaymentType__c(Name='CR15',Default_Labor_Rate__c=52,Description__c='Test GHI', Payment_Type__c='C'));
	  // BLL10
      spts.add(new ServicePaymentType__c(Name='GRUV',Default_Labor_Rate__c=52,Description__c='Test GRUV', Payment_Type__c='I'));
      spts.add(new ServicePaymentType__c(Name='MCEO',Default_Labor_Rate__c=52,Description__c='Test MCEO', Payment_Type__c='I'));
	  // BLL10 end
      insert(spts);            
      // BLL6a end
   
	}


    static testmethod void Myunittest(){
		dealer__Dealer_Location__c ddl = [select Id, Name, dealer__Company_Number__c from dealer__Dealer_Location__c limit 1];
        //Account a = new Account();
        //a.LastName ='Test';
        //a.AccountSource ='Dealer';
        //a.BillingState = 'CA';
        //insert a;
		TestHelper_MW th = TestHelper_MW.getInstance();
		Account a = th.getBusinessAccount('2');
        
        contact con = new contact();
        con.Phone = '8888888';
        con.LastName = 'Test';
        insert con;
        
        dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
        dsv.dealer__VIN__c ='TestAB';
        dsv.Name='TestA';
        dsv.dealer__Body_Style__c = 'TestA';
        dsv.dealer__Company_Number__c=ddl.dealer__Company_Number__c;	// BLL4c '12131';
        dsv.dealer__Veh_Owner_Contact__c = con.id;
        dsv.dealer__Carline__c ='TestA';
        dsv.dealer__Make__c  ='TestA';
        dsv.dealer__Year__c  ='2014';
        insert dsv;
        
        //dealer__Dealer_Location__c ddl = new dealer__Dealer_Location__c();
        //ddl.Name ='Test';
        //ddl.dealer__City__c ='Test';
        //ddl.dealer__Postal_Code__c='301352';
        //ddl.dealer__State__c='Te';
        //ddl.dealer__Company_Number__c='12345';
        //ddl.dealer__Service_Director__c =Userinfo.getuserid();
        //insert ddl;

		List<ServicePaymentType__c> spts = [select Id from ServicePaymentType__c ORDER BY Name];
        
        Test.startTest(); // BLL2a moved here to test trigger ServiceROCalc
        
        dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
        dsr.dealer__Customer__c =a.id;
        dsr.dealer__Mileage_In__c =12;
        dsr.dealer__RO_Number__c ='11';
        dsr.dealer__VIN__c = dsv.dealer__VIN__c;
        dsr.dealer__Vehicle__c = dsv.Id;
        dsr.dealer__Company__c=ddl.id;
		dsr.dealer__Discount_Type__c='5%';	// BLL4a
        insert dsr;
         
		// BLL7a
        dealer__StandardOpCode__c dso = new dealer__StandardOpCode__c();
        dso.Name ='Test1';
		dso.Default_Payment_Method__c = spts[0].Id;
		dso.dealer__Pay_Type__c = 'W';
        insert dso;
        // BLL7a
         
        List<dealer__Service_Job__c> dsjlist = new List<dealer__Service_Job__c>();
        dealer__Service_Job__c dsj = new dealer__Service_Job__c();
         dsj.dealer__Cause__c ='Test';
         dsj.dealer__Labor_Charges__c =12;
         dsj.dealer__Service_Repair_Order__c =dsr.id;
         dsj.dealer__Labor_Type__c = 'C';  // BLL1a
        //insert dsj;
		dsj.Payment_Method__c=spts[0].Id;  // BLL6a                           
        dsjlist.add(dsj);
        
        dealer__Service_Job__c dsj2 = new dealer__Service_Job__c();
         dsj2.dealer__Cause__c ='Test2';
         dsj2.dealer__Labor_Charges__c = 14;
         dsj2.dealer__Service_Repair_Order__c = dsr.id;
         dsj2.dealer__Labor_Type__c = 'I';
        //insert dsj2;
		//dsj2.Payment_Method__c=spts[spts.size()-1].Id; // BLL6a
		dsj2.Payment_Method__c=spts[0].Id;                           
        dsjlist.add(dsj2);

        dealer__Service_Job__c dsj3 = new dealer__Service_Job__c();
         dsj3.dealer__CauseExtended__c = 'Test2: This is an extended cause';	// BLL7a
         dsj3.dealer__Labor_Charges__c = 15;
         dsj3.dealer__Service_Repair_Order__c = dsr.id;
        // dsj3.dealer__Labor_Type__c = 'W';
        //insert dsj3;
		////BLL7d dsj3.Payment_Method__c=spts[0].Id;  // BLL6a
		dsj3.dealer__Standard_Operation_Code__c = dso.Id;	// BLL7a
        dsjlist.add(dsj3);

		insert(dsjlist);
	        
        dealer__Time_Clock__c dtc = new dealer__Time_Clock__c();
         dtc.dealer__Clock_Out__c =system.today();
         dtc.dealer__Clock_In__c =system.today();
         dtc.dealer__User__c =UserInfo.getUserId();
         //dtc.Date__c =system.today(); 
        insert dtc;
        
        dealer__Technician_Job_Time__c  dtj = new dealer__Technician_Job_Time__c ();
            dtj.Name ='Test';
            dtj.dealer__Service_Job_Line__c =dsj.id;
            dtj.dealer__Start_Time__c=system.today();
            dtj.dealer__End_Time__c =system.today();
            dtj.Time_Clock_Entry__c =dtc.id;
            dtj.dealer__Time_Clock__c =dtc.id;
            dtj.Labor_Total__c =23;
        insert dtj;
        
        // BLL1a begin
        List<ServiceMiscCharges__c> miscchgs = new List<ServiceMiscCharges__c>();
        miscchgs.add(new ServiceMiscCharges__c (
           Type__c = 'Freight',
           Amount__c = 1.00,
           Service_Job_Line__c = dsj.Id
        ));
        //insert(smc1);
        miscchgs.add(new ServiceMiscCharges__c (
           Type__c = 'Other',
           Amount__c = 2.00,
           Service_Job_Line__c = dsj.Id
        ));
        //insert(smc2);
        miscchgs.add(new ServiceMiscCharges__c (
           Type__c = 'Hazardous Materials',
           Amount__c = 3.00,
           Service_Job_Line__c = dsj.Id
        ));
        //insert(smc3);
        miscchgs.add(new ServiceMiscCharges__c (
           Type__c = 'Shop Supplies',
           Amount__c = 4.00,
           Service_Job_Line__c = dsj.Id
        ));
        //insert(smc4);
        
        miscchgs.add(new ServiceMiscCharges__c (
           Type__c = 'Other',
           Amount__c = 2.00,
           Service_Job_Line__c = dsj2.Id
        ));
        //insert(smc5);

        //miscchgs.add(new ServiceMiscCharges__c (
        //   Type__c = 'Other',
        //   Amount__c = 2.00,
        //   Service_Job_Line__c = dsj3.Id
        //));
        //insert(smc6);
        
        insert(miscchgs); 
        
        
        // BLL1a end
        ApexPages.StandardController sc = new ApexPages.StandardController(dsr);
        ApexPages.currentPage().getParameters().put('id', dsr.id);
        ServiceRepairOrder2  sr = new ServiceRepairOrder2(new ApexPages.StandardController(dsr));
        
        sr.save();
        sr.detailUpdate();
        ServiceRepairOrder2.loadServiceJobLines(dsr.id);
        ServiceRepairOrder2.laborTotal(dsr.id);
        sr.returnToRo();
        
        // The following generates an error:
        //		GetTax You have uncommitted work pending. Please commit or rollback before calling out
        //Test.setMock(WebServiceMock.class, new AvaTaxRequestMock());
        //sr.calcTax();
        //sr.pageCalcTax();
        //sr.getTaxes();
        
       Test.stopTest(); // BLL2a

    }

	// BLL4a
    static testmethod void deleteRO(){
		Account a = [select Id, Name from Account limit 1];
		dealer__Dealer_Location__c ddl = [select Id, Name, dealer__Company_Number__c from dealer__Dealer_Location__c limit 1];
		
        dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
        dsr.dealer__Customer__c =a.id;
        dsr.dealer__Mileage_In__c =12;
        dsr.dealer__RO_Number__c ='11';
        dsr.dealer__VIN__c = null;
        dsr.dealer__Vehicle__c = null;
        dsr.dealer__Company__c=ddl.id;
        insert dsr;

        delete dsr;

    }

    static testmethod void taxRO(){

		Account a = [select Id, Name from Account limit 1];
		dealer__Dealer_Location__c ddl = [select Id, Name, dealer__Company_Number__c from dealer__Dealer_Location__c limit 1];
		
		TaxRuleSetting__c rules = new TaxRuleSetting__c(Name='Default', ProposalAutomaticCalc__c=true,
        	RepairAutomaticCalc__c=true, RentalAutomaticCalc__c=true);
        insert rules;
		
        dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
        dsr.dealer__Customer__c =a.id;
        dsr.dealer__Mileage_In__c =12;
        dsr.dealer__RO_Number__c ='11';
        dsr.dealer__VIN__c = null;
        dsr.dealer__Vehicle__c = null;
        dsr.dealer__Company__c=ddl.id;
        insert dsr;

        ApexPages.StandardController sc = new ApexPages.StandardController(dsr);
        ApexPages.currentPage().getParameters().put('id', dsr.id);
        ServiceRepairOrder2  sr = new ServiceRepairOrder2(new ApexPages.StandardController(dsr));

        Test.setMock(WebServiceMock.class, new AvaTaxRequestMock());
        sr.calcTax();
        sr.pageCalcTax();
        sr.getTaxes();
        Decimal taxamt = sr.TaxTotal;
        sr.checkTaxRecalc();
        sr.checkTaxUpdate(false);
        sr.ro.id=dsr.id;
        sr.getNeedToRecalcTax();

    }

    // BLL4a end

	// BLL5a test ensure all parts ordered routine
	static testmethod void testPartsOrdered() {

		Account a = [select Id, Name, PersonContactId from Account limit 1];
		dealer__Dealer_Location__c ddl = [select Id, Name, dealer__Company_Number__c from dealer__Dealer_Location__c limit 1];
		List<ServicePaymentType__c> spts = [select Id from ServicePaymentType__c ORDER BY Name];

        dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
        dsv.dealer__VIN__c ='TestAB';
        dsv.Name='TestA';
        dsv.dealer__Body_Style__c = 'TestA';
        dsv.dealer__Company_Number__c=ddl.dealer__Company_Number__c;	// BLL4c '12131';
        dsv.dealer__Veh_Owner_Contact__c = a.PersonContactId;
        dsv.dealer__Carline__c ='TestA';
        dsv.dealer__Make__c  ='TestA';
        dsv.dealer__Year__c  ='2014';
        insert dsv;
        
        dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
        dsr.dealer__Customer__c =a.id;
        dsr.dealer__Mileage_In__c =12;
        dsr.dealer__RO_Number__c ='11';
        dsr.dealer__VIN__c = dsv.dealer__VIN__c;
        dsr.dealer__Vehicle__c = dsv.Id;
        dsr.dealer__Company__c=ddl.id;
        insert dsr;
         
        List<dealer__Service_Job__c> dsjlist = new List<dealer__Service_Job__c>();
        dealer__Service_Job__c dsj = new dealer__Service_Job__c();
         dsj.dealer__Cause__c ='Test';
         dsj.dealer__Labor_Charges__c =12;
         dsj.dealer__Service_Repair_Order__c =dsr.id;
         dsj.dealer__Labor_Type__c = 'C';  
		dsj.Payment_Method__c=spts[0].Id;                             
        dsjlist.add(dsj);
        insert(dsjlist);
            
            dealer__Parts_Invoice__c pi = new dealer__Parts_Invoice__c();
            pi.dealer__Customer__c = a.Id;
            pi.dealer__Customer_Contact__c = a.PersonContactId;
            pi.Name = 'Test Invoice';
            pi.dealer__Comapny_Number__c = ddl.dealer__Company_Number__c;
            pi.dealer__Location__c = ddl.Id;
            pi.dealer__Deposit__c = 100;
            pi.dealer__Invoice_Number__c = 'inv1234';            
            insert pi;            
            
            //For loop to insert Parts Lines for SRO and Service Job
        	List<dealer__Parts_Invoice_Line__c> partslines = new List<dealer__Parts_Invoice_Line__c>();	// BLL1a
        	for(Integer i=0; i<1;i++){
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
		
			Map<Id,dealer__Service_Repair_Order__c> oldMap = new Map<Id,dealer__Service_Repair_Order__c>();
			dealer__Service_Repair_Order__c dsrcopy = dsr.clone(true,false,true,true);
			oldMap.put(dsr.Id,dsrcopy);
			dsr.dealer__Status__c='Posted';
			dsr.dealer__Posted_Date_Time__c = DateTime.now();
			List<dealer__Service_Repair_Order__c> newList = new List<dealer__Service_Repair_Order__c>();
			newList.add(dsr);

		Test.startTest();
		ServiceROHandler sroh = new ServiceROHandler(newList, oldMap);
		try {
			sroh.ensureAllPartsOrdered();
		} catch(Exception e) {
			System.debug(e);
		}
		Test.stopTest();
		
	}

	// BLL9a
	static testmethod void miscChargeTests() {

		Account a = [select Id, Name, PersonContactId from Account limit 1];
		dealer__Dealer_Location__c ddl = [select Id, Name, dealer__Company_Number__c from dealer__Dealer_Location__c limit 1];
		List<ServicePaymentType__c> spts = [select Id from ServicePaymentType__c ORDER BY Name];

        dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
        dsv.dealer__VIN__c ='TestAB';
        dsv.Name='TestA';
        dsv.dealer__Body_Style__c = 'TestA';
        dsv.dealer__Company_Number__c=ddl.dealer__Company_Number__c;	// BLL4c '12131';
        dsv.dealer__Veh_Owner_Contact__c = a.PersonContactId;
        dsv.dealer__Carline__c ='TestA';
        dsv.dealer__Make__c  ='TestA';
        dsv.dealer__Year__c  ='2014';
        insert dsv;
        
        dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
        dsr.dealer__Customer__c =a.id;
        dsr.dealer__Mileage_In__c =12;
        dsr.dealer__RO_Number__c ='11';
        dsr.dealer__VIN__c = dsv.dealer__VIN__c;
        dsr.dealer__Vehicle__c = dsv.Id;
        dsr.dealer__Company__c=ddl.id;
        insert dsr;
         
        List<dealer__Service_Job__c> dsjlist = new List<dealer__Service_Job__c>();
        dealer__Service_Job__c dsj = new dealer__Service_Job__c();
         dsj.dealer__Cause__c ='Test';
         dsj.dealer__Labor_Charges__c =12;
         dsj.dealer__Service_Repair_Order__c =dsr.id;
         dsj.dealer__Labor_Type__c = 'C';  
		dsj.Payment_Method__c=spts[0].Id;                             
        dsjlist.add(dsj);
        insert(dsjlist);

		List<dealer__Service_Misc_Charge__c> miscchgs = new List<dealer__Service_Misc_Charge__c>();
		miscchgs.add(new dealer__Service_Misc_Charge__c(
			dealer__Service_Job_Lines__c = dsj.id,
			dealer__Amount__c = 5,
			dealer__Type__c = 'Shop Supplies'
		));
		insert(miscchgs);
		miscchgs[0].dealer__Type__c = 'Freight';
		update(miscchgs);
		delete(miscchgs);            
		
	}


	// BLL10
    static testmethod void chgPmtMethod(){
		dealer__Dealer_Location__c ddl = [select Id, Name, dealer__Company_Number__c from dealer__Dealer_Location__c limit 1];

        //Account a = new Account();
        //a.LastName ='Test';
        //a.AccountSource ='Dealer';
        //a.BillingState = 'CA';
        //insert a;
		TestHelper_MW th = TestHelper_MW.getInstance();
		Account a = th.getBusinessAccount('2');
        
        contact con = new contact();
        con.Phone = '8888888';
        con.LastName = 'Test';
        insert con;
        
		// BLL10
		dealer__Vehicle_Inventory__c dvi = new dealer__Vehicle_Inventory__c(
			dealer__Stock_Number__c = 'TestABC',
        	dealer__VIN__c ='TestAB',
        	Name='TestA',
        	dealer__Company_Number__c = ddl.dealer__Company_Number__c,
        	dealer__Model__c ='TestA',
        	dealer__Make__c  ='TestA',
        	dealer__Year__c  ='2014'
		);
		insert(dvi);
		// BLL10 end
        dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
        dsv.dealer__VIN__c ='TestAB';
        dsv.Name='TestA';
        dsv.dealer__Body_Style__c = 'TestA';
        dsv.dealer__Company_Number__c=ddl.dealer__Company_Number__c;	
        dsv.dealer__Veh_Owner_Contact__c = con.id;
        dsv.dealer__Carline__c ='TestA';
        dsv.dealer__Make__c  ='TestA';
        dsv.dealer__Year__c  ='2014';
		// BLL10
        //insert dsv;
		Database.insert(dsv, false); // allow to fail in case it was created from dvi insert
		// BLL10 end
		dsv = [select Id, dealer__VIN__c from dealer__Service_Vehicle__c where dealer__VIN__c = :dvi.dealer__VIN__c limit 1];
		// BLL10 end
        
		List<ServicePaymentType__c> spts = [select Id, Name from ServicePaymentType__c ORDER BY Name];
		Map<String,ServicePaymentType__c> sptmap = new Map<String,ServicePaymentType__c>();
		for(ServicePaymentType__c s : spts) sptmap.put(s.Name, s);
        
        dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
        dsr.dealer__Customer__c =a.id;
        dsr.dealer__Mileage_In__c =12;
        dsr.dealer__RO_Number__c ='11';
        dsr.dealer__VIN__c = dsv.dealer__VIN__c;
        dsr.dealer__Vehicle__c = dsv.Id;
		dsr.dealer__Vehicle_Inventory__c = dvi.Id;	// BLL10
        dsr.dealer__Company__c=ddl.id;
        insert dsr;
         
        dealer__StandardOpCode__c dso = new dealer__StandardOpCode__c();
        dso.Name ='Test1';
		dso.Default_Payment_Method__c = sptMap.get('CR').Id;    
		dso.dealer__Pay_Type__c = 'W';
        insert dso;

        Test.startTest(); 

        List<dealer__Service_Job__c> dsjlist = new List<dealer__Service_Job__c>();
        dealer__Service_Job__c dsj = new dealer__Service_Job__c();
         dsj.dealer__Cause__c ='Test';
         dsj.dealer__Labor_Charges__c =12;
         dsj.dealer__Service_Repair_Order__c =dsr.id;
         dsj.dealer__Labor_Type__c = 'C';  
		dsj.Payment_Method__c=sptMap.get('CR').Id;                           
        dsjlist.add(dsj);
        
        dealer__Service_Job__c dsj2 = new dealer__Service_Job__c();
         dsj2.dealer__Cause__c ='Test2';
         dsj2.dealer__Labor_Charges__c = 14;
         dsj2.dealer__Service_Repair_Order__c = dsr.id;
         dsj2.dealer__Labor_Type__c = 'I';
		dsj2.Payment_Method__c=sptMap.get('CR').Id;                       
        dsjlist.add(dsj2);

		insert(dsjlist);

		dsj.Payment_Method__c = sptMap.get('GRUV').Id;
		dsj2.Payment_Method__c = sptMap.get('MCEO').Id;
		update(dsjlist);
		dsj.Payment_Method__c = sptMap.get('CR').Id;
		dsj2.Payment_Method__c = sptMap.get('CR').Id;
		update(dsjlist);

       Test.stopTest(); 

    }
	// BLL10 end 

	// BLL11
    static testmethod void updateROHeader() {
		dealer__Dealer_Location__c ddl = [select Id, Name, dealer__Company_Number__c from dealer__Dealer_Location__c limit 1];

        //Account a = new Account();
        //a.LastName ='Test';
        //a.AccountSource ='Dealer';
        //a.BillingState = 'CA';
        //insert a;
		TestHelper_MW th = TestHelper_MW.getInstance();
		Account a = th.getBusinessAccount('2');
        
        contact con = new contact();
        con.Phone = '8888888';
        con.LastName = 'Test';
        insert con;
        
        dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
        dsv.dealer__VIN__c ='TestAB';
        dsv.Name='TestA';
        dsv.dealer__Body_Style__c = 'TestA';
        dsv.dealer__Company_Number__c=ddl.dealer__Company_Number__c;	// BLL4c '12131';
        dsv.dealer__Veh_Owner_Contact__c = con.id;
        dsv.dealer__Carline__c ='TestA';
        dsv.dealer__Make__c  ='TestA';
        dsv.dealer__Year__c  ='2014';
        insert dsv;
        
		List<ServicePaymentType__c> spts = [select Id from ServicePaymentType__c ORDER BY Name];
        
        Test.startTest(); 
        
        dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
        dsr.dealer__Customer__c =a.id;
        dsr.dealer__Mileage_In__c =12;
        dsr.dealer__RO_Number__c ='11';
        dsr.dealer__VIN__c = dsv.dealer__VIN__c;
        dsr.dealer__Vehicle__c = dsv.Id;
        dsr.dealer__Company__c=ddl.id;
		dsr.dealer__Discount_Type__c='5%';	
        insert dsr;

		MW_TriggerControls__c sro = MW_TRiggerControls__c.getInstance('SROTriggers');
		sro.Enabled__c=true;
        update(sro);

		update dsr;
		
		Test.stopTest();

	}
	// BLL11 end

	// test tech job line deletion
	static testmethod void testDeleteTechTimeFromEstimate() {
		TestHelper_MW th = TestHelper_MW.getInstance();

		Account a = th.getPersonAccount('1');
		dealer__Dealer_Location__c ddl = th.getDealerLocation('2');
		//FFAdata.refresh();
		ServicePaymentType__c cpt = [select Id, Name from ServicePaymentType__c where Payment_Type__c = 'C' limit 1];
		//ServicePaymentType__c wpt = [select Id, Name from ServicePaymentType__c where Payment_Type__c = 'W' limit 1];
		//ServicePaymentType__c spt =  [select Name, Default_Labor_Rate__c from ServicePaymentType__c where Name=:cpt.Name limit 1];	// BLL1a
        
        //Service Estimate
        dealer__Service_Estimate__c se = new dealer__Service_Estimate__c(dealer__Cosmetic_Notes__c='Repair / Repaint Bumper');
        insert(se);
        
        //Service Estimate Line
        dealer__Service_Estimate_Line__c sel = new dealer__Service_Estimate_Line__c(
            		dealer__Service_Estimate__c=se.Id,
                	dealer__Labor_Type__c = cpt.Name);	// BLL1c 'C');
        insert(sel);

        // Sub Line
        dealer__Service_Estimate_SubLine__c newSubLine = new dealer__Service_Estimate_SubLine__c(
                    dealer__Labor_Rate__c=90,
                    dealer__Line_Type__c='Labor',
                    dealer__Service_Estimate_Line__c=sel.Id);
		insert(newSubLine);

        dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c(
			dealer__Customer__c = a.Id, dealer__Customer_Contact__c = a.PersonContactId, 
			dealer__Mileage_In__c=10, 
            dealer__Company__c = ddl.Id ,dealer__RO_Number__c='10001');
        insert dsr;
		List<ServicePaymentType__c> spts = [select Id, Name from ServicePaymentType__c ORDER BY Name];
		Map<String,ServicePaymentType__c> sptmap = new Map<String,ServicePaymentType__c>();
		for(ServicePaymentType__c s : spts) sptmap.put(s.Name, s);
        dealer__Service_Job__c dsj = new dealer__Service_Job__c(
        	dealer__Cause__c ='Test',
        	dealer__Labor_Charges__c =12,
			dealer__Service_Repair_Order__c =dsr.id,
			dealer__Labor_Type__c = 'C',
			Payment_Method__c = sptMap.get('CR').Id
		);
        insert dsj;
		
		//System.runAs(FFAdata.TestUser) {
			Test.startTest();

			insert(new dealer__Technician_Job_Time__c(
				dealer__Service_Job_Line__c  =   dsj.Id,
				dealer__Technician__c        =   null,
				dealer__Actual_Time_Entry__c =   1.0,
				Labor_Total__c               =   90.0,
				dealer__Date__c              =   Date.today(),
				dealer__Service_Estimate_Subline_Creator__c = newSubLine.Id
			));

			Test.stopTest();
			List<dealer__Technician_Job_Time__c> tt = [
				select id from dealer__Technician_Job_Time__c
				where dealer__Service_Job_Line__c = :dsj.Id
			];
			System.assert(tt.size()==0, 'Technician job time records from an estimate were not deleted');
		//}
	}

}