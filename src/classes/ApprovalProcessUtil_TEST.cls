/**
 * ApprovalProcessUtil_TEST
 * Tests: ApprovalProcessUtil
 * Date: Aug 5, 2016
 * Programmer: Bryan Leaman
 *
 *	2016-12-19	B. Leaman	BLL1 - adjustments for additional validations added in production.
 *	2016-12-29	B. Leaman	BLL2 - remove redundant lookup fields in favor of managed versions.
 *	2017-02-27	B. Leaman	BLL3 - adjust test for deal changes.
 *	2018-09-13	B. Leaman	BLL4 - reduce SOQL queries by setting start/stop test boundaries.
 *	2019-01-17	B. Leaman	W-000482 BLL5 - new routine to test "ApproveDocument"
 */
@isTest
private class ApprovalProcessUtil_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
       	TestHelper_MW th = new TestHelper_MW();
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        insert(new dealer__FixedOperationsSettings__c(dealer__Repair_Order_Index__c=1));
        insert(new RetailDefaults__c(ProposalNumber__c=7));  

		Account a = th.getPersonAccount('1');
        
       	// Need service pmt types
       	List<ServicePaymentType__c> spts = new List<ServicePaymentType__c>();
       	spts.add(new ServicePaymentType__c(Name='IEN',Default_Labor_Rate__c=52,Description__c='Test IEN'));
       	spts.add(new ServicePaymentType__c(Name='IEU',Default_Labor_Rate__c=52,Description__c='Test IEU'));
       	spts.add(new ServicePaymentType__c(Name='IEO',Default_Labor_Rate__c=52,Description__c='Test IEO'));
       	insert(spts);
        
        // create vehicle 
        dealer__Vehicle_Inventory__c veh = new dealer__Vehicle_Inventory__c(
            Name='(TESTX) 2020 Toyota Future',
            New_Used_Other__c='Used', Division__c='Commercial', 
            dealer__Stock_Number__c='TESTX',
            dealer__VIN__c='11234567890TUVWXY',
            dealer__Year__c='2020', dealer__Make__c='Toyota', dealer__Model__c='Future',
            dealer__Mileage__c=123000
        );
        insert(veh);

        dealer__Sales_Up__c  dsp = new dealer__Sales_Up__c(
        	dealer__Lead_Date__c=System.Today(),
			dealer__First_Store_Visit_Date__c = DateTime.now(), 	// BLL1a
        	dealer__Lead_Status__c='Pending',
        	dealer__Lead_Type__c='List',
        	dealer__Source__c ='Pride',
        	Solution_Type__c ='Chassis/Conversion',
        	dealer__Customer_Account__c =a.id,
			dealer__Trade_Year__c = '2016',
			dealer__Trade_Make__c = 'Toyota',
			dealer__Trade_Model__c = 'Greatness'
		);
        insert dsp;
	
		Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL1a
   	    dealer__Deal__c dd = new dealer__Deal__c(
   	    	Name = 'Test',
   	    	dealer__Deal_Type__c = 'Retail Vehicle Sale',	// BLL1a
   	    	//BLL3d RecordTypeId = RcdTypes.get('Retail Vehicle Sale').getRecordTypeId(), // BLL1a
   	    	RecordTypeId = RcdTypes.get('Retail').getRecordTypeId(),	// BLL3a
   	    	dealer__Auto_Insurance_Agent__c='Test',
	    	dealer__Deal_ID__c ='Test',
	    	dealer__Sales_Lead__c = dsp.id,
	    	dealer__Status__c ='Pending',
	    	dealer__Deal_Date__c =System.Today(),
	    	Proposed_Delivery_Date__c =System.Today(),
	    	dealer__Vehicle__c = veh.Id,
	    	dealer__Store_Location__c = FFAdata.DealerLocation.Id,
	    	TaxCalcDT__c = System.today(),
	    	Commission_Employee_1__c = UserInfo.getUserId(),
	    	dealer__Desk_Manager__c = UserInfo.getUserId(),
	    	dealer__F_I_Manager__c = UserInfo.getUserId(),
	    	Sales_Admin__c = UserInfo.getUserId(),
	    	dealer__Salesperson_1__c = UserInfo.getUserId(),
	    	dtmob__Service_Manager__c = UserInfo.getUserId()	// BLL2c
	    );
	    insert dd;

	}

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
        	Set<Id> ids = new Set<Id>();

			dealer__Deal__c dd = [select Id from dealer__Deal__c limit 1];
			ids.add(dd.Id);
			
			Test.startTest();	// BLL4a
			
			Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitrequest();
            app.setObjectId(dd.Id);
            //Submit the approval request for the Campaign
            Approval.ProcessResult result = Approval.process(app);

			ApprovalProcessUtil apu = new ApprovalProcessUtil(ids);
			apu.getObjectApproverMap();

			// BLL5 approve it
			ApprovalProcessUtil.ApproveDocument(dd.Id, null, null);
			// BLL5a
			
			Test.stopTest();	// BLL4a
		}
	}

}