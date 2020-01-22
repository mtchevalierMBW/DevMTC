/**
 * BatchUpdateROLiftInfo_TEST
 * Tests: BatchUpdateROLiftInfo_TEST
 * Date: 2019-12-05
 * Programmer: Bryan Leaman
 * Project: W-000787
 *
 * Modifications: 
 *
 */
 @isTest
 private class BatchUpdateROLiftInfo_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	private static void setupTestData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
		TestHelper_MW th = new TestHelper_MW();
		System.runAs(FFAdata.TestUser) {
			Account a = th.getPersonAccount('1');
			dealer__Service_Repair_Order__c ro = new dealer__Service_Repair_Order__c(
				dealer__Customer__c = a.Id,
				dealer__Mileage_In__c = 1,
				Lift_MFG__c = 'Test MFG',
				Lift_Model__c = 'Newest one',
				Lift_Serial_Number__c = 'S12345678',
				Lift_Cycle_Count__c = 1234
			);
			insert(ro);
		}
	}


	static testMethod void unitTest() {

		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			Test.startTest();
			BatchUpdateROLiftInfo ba = new BatchUpdateROLiftInfo('1', false);
			Database.executeBatch(ba);
			Test.stopTest();
		}
		
	}
	
	
 }