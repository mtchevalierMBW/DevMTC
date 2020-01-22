/**
 * BatchFixInventorySvcVeh_TEST
 * Tests: BatchFixInventorySvcVeh
 * Date: Sep 13, 2017
 * Programmer: Bryan Leaman
 * 
 * 
 */
@isTest
private class BatchFixInventorySvcVeh_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	private static void setupTestData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		
		System.runAs(FFAdata.TestUser) {
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
	        dealer__Service_Vehicle__c sv2 = new dealer__Service_Vehicle__c(
	        	dealer__VIN__c='ThisIsATestVIN123',
	        	dealer__Make__c='Toyota',
	        	dealer__Model_Code__c='Future',
	        	dealer__Year__c='2020'
	        );
	        insert(sv2);

		}
	}


	static testMethod void unitTest() {

			BatchFixInventorySvcVeh ba = new BatchFixInventorySvcVeh('1', false);
			Database.executeBatch(ba);
		
	}
	
	
	static testMethod void TestCRON() {
		Test.startTest();
		List<String> jobIds = BatchFixInventorySvcVeh.scheduleMe();
		String firstJobId = jobIds[0];

		// Get the information from the CronTrigger API object
		CronTrigger ct = [
			SELECT Id, CronExpression, TimesTriggered, NextFireTime
        	FROM CronTrigger 
        	WHERE id = :firstJobId
        ];
 
		// Verify the expressions are the same
		System.assertEquals(BatchFixInventorySvcVeh.CRON_LIST[0], ct.CronExpression);
 
		// Verify the job has not run
		System.assertEquals(0, ct.TimesTriggered);
		
		Test.stopTest();
		
	}
	
}