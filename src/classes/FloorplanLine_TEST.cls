/**
 * FloorplanLine_TEST
 * Tests: FloorplanLine_CTLR
 * Date: Jan 18, 2016
 * Programmer: Bryan Leaman
 * 
 * 
 */
@isTest
private class FloorplanLine_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); // BLL1

	@testSetup
	static void floorplanTestData() {
		TestHelper_MW.createBaseFFAData(FFAdata);

		FloorplanLine__c fpl = new FloorplanLine__c(
			Name='TestFloorplan', 
			LineAmount__c=1000000,
			Active__c=true);
		insert(fpl);
		FloorplanLine__c fpl2 = new FloorplanLine__c(
			Name='TestFloorplan2', 
			LineAmount__c=2000000,
			Active__c=true);
		insert(fpl2);

	}

	// controllerTest
	static testMethod void controllerTest() {
		FFAdata.refresh();
		System.runAs(FFAdata.TestUser) {
	        dealer__Vehicle_Inventory__c veh = new dealer__Vehicle_Inventory__c(
	        	dealer__Year__c='2021', dealer__Make__c='Toyota', dealer__Model__c='Futuristic',
	        	dealer__VIN__c='12345698765ABCZYX', dealer__Stock_Number__c='ABCZYX', 
	        	PaymentDueDays__c=1, PaymentDueDate__c=null, dealer__Sale_Date__c = Date.today(),
	        	Chassis_Floorplan__c='TestFloorplan', Conversion_Floorplan__c='TestFloorplan',
	        	Floorplanned__c=true, Paid__c=false, Current_Floored_Amount__c=5000
	        );
	        insert(veh);
	        dealer__Vehicle_Inventory__c veh2 = new dealer__Vehicle_Inventory__c(
	        	dealer__Year__c='2021', dealer__Make__c='Toyota', dealer__Model__c='Futuristic',
	        	dealer__VIN__c='12345698765ABCZZZ', dealer__Stock_Number__c='ABCZZZ', 
	        	PaymentDueDays__c=1, PaymentDueDate__c=null, dealer__Sale_Date__c = Date.today(),
	        	Chassis_Floorplan__c='TestFloorplan2', Conversion_Floorplan__c='TestFloorplan2',
	        	Floorplanned__c=true, Paid__c=false, Current_Floored_Amount__c=35000
	        );
	        insert(veh2);
	        Test.startTest();
			FloorplanLine_CTLR ctl = new FloorplanLine_CTLR();
			Test.stopTest();
		}
	}
}