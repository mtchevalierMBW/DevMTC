/**
 * TechTimeLink_TC
 * Tests: 
 *
 *  2017-04-06  B. Leaman  BLL1 - need servicepaymenttype on job lines for tech time to be valid.
 */
@isTest(Seealldata= True)
Public Class TechTimeLink_TC{
	Static testmethod Void UnitMilestone(){
	
	//Account a = new Account();
	//a.LastName ='Test';
	//a.AccountSource ='Dealer';
	//insert a;
	TestHelper_MW th = new TestHelper_MW();
	Account a = th.getBusinessAccount('2');
	
	dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
	dsr.dealer__Customer__c =a.id;
	dsr.dealer__Mileage_In__c =12;
	dsr.dealer__RO_Number__c ='11';
	insert dsr;

      // BLL1a need this for new tech time validation rule
      List<ServicePaymentType__c> spts = new List<ServicePaymentType__c>();
      spts.add(new ServicePaymentType__c(Name='ABC',Default_Labor_Rate__c=52,Description__c='Test ABC'));
      //spts.add(new ServicePaymentType__c(Name='DEF',Default_Labor_Rate__c=52,Description__c='Test DEF'));
      //spts.add(new ServicePaymentType__c(Name='GHI',Default_Labor_Rate__c=52,Description__c='Test GHI'));
      insert(spts);            
      // BLL1a end
	
	dealer__Service_Job__c dsj = new dealer__Service_Job__c();
	 dsj.dealer__Cause__c ='Test';
	 dsj.dealer__Labor_Charges__c =12;
	 dsj.dealer__Service_Repair_Order__c =dsr.id;
	dsj.Payment_Method__c=spts[0].Id;  // BLL1a                           
	insert dsj;
	
	dsj.dealer__Labor_Charges__c =14;
	update dsj;
	
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
	
	}
}