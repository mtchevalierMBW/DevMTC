/**
 * BatchUpdateInactiveDeals_TEST
 * Tests: BatchUpdateInactiveDeals_TEST
 * Date: Mar 2, 2018
 * Programmer: Bryan Leaman
 * 
 * 
 */
@isTest
private class BatchUpdateInactiveDeals_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	private static void setupTestData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
       	TestHelper_MW th = new TestHelper_MW();
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        insert(new dealer__FixedOperationsSettings__c(dealer__Repair_Order_Index__c=1));
        insert(new RetailDefaults__c(ProposalNumber__c=7));  

		Account a = th.getPersonAccount('1');
        
        // create vehicle 
        dealer__Vehicle_Inventory__c veh = new dealer__Vehicle_Inventory__c(
            Name='(TESTX) 2020 Toyota Future',
            New_Used_Other__c='Used', Division__c='Commercial',
            dealer__Status_Code__c = 'Ready For Sale', 
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
	    dealer__Deal__c deal = new dealer__Deal__c(
	    	Name = 'Test',
   	    	dealer__Deal_Type__c = 'Chassis/Conversion',
	    	RecordTypeId = RcdTypes.get('Retail').getRecordTypeId(), 
	    	TaxCalcDT__c = DateTime.now(), 
	    	dealer__Auto_Insurance_Agent__c='Test',
	    	dealer__Deal_ID__c ='Test',
	    	dealer__Sales_Lead__c = dsp.id,
	    	dealer__Status__c ='Pending',
	    	dealer__Deal_Date__c =System.Today(),
	    	Proposed_Delivery_Date__c = null,
	    	dealer__Vehicle__c = veh.Id,
	    	Vehicle_Source__c='Inventory',
	    	dealer__Store_Location__c = FFAdata.DealerLocation.Id,
	    	Funding_option__c = 'Cash', 
	    	dealer__Salesperson_1__c = UserInfo.getUserId(),
	    	dealer__DeliveryRepairOrder__c = null
	    );
	    insert deal;

	}


	static testMethod void unitTest() {

		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
			BatchUpdateInactiveDeals ba = new BatchUpdateInactiveDeals('1', false);
			Database.executeBatch(ba);
		}
		
	}
	
	
	static testMethod void TestCRON() {
		Test.startTest();
		List<String> jobIds = BatchUpdateInactiveDeals.scheduleMe();
		String firstJobId = jobIds[0];

		// Get the information from the CronTrigger API object
		CronTrigger ct = [
			SELECT Id, CronExpression, TimesTriggered, NextFireTime
        	FROM CronTrigger 
        	WHERE id = :firstJobId
        ];
 
		// Verify the expressions are the same
		System.assertEquals(BatchUpdateInactiveDeals.CRON_LIST[0], ct.CronExpression);
 
		// Verify the job has not run
		System.assertEquals(0, ct.TimesTriggered);
		
		Test.stopTest();
		
	}
	
}