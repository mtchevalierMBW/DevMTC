/**
* MobilityWorks (c) - 2018
*
* vehicleInventoryQuickActionsTest
*
* Created: 8/30/2018
* Developer: Alexander Miller
*/
@istEst
public class vehicleInventoryQuickActionsTest {
	
    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();

        dealer__Vehicle_Inventory__c v = new dealer__Vehicle_Inventory__c(
			dealer__Make__c = 'Dodge',
			dealer__Model__c = 'Grand Caravan',
			dealer__Stock_Number__c = '	DR553597',
			dealer__VIN__c = '2C4RDGCG6DR553597', 
			dealer__Year__c = '2013'
		);

        insert v;
	}

    public static testMethod void testArvhiceVehicle()
    {
        Test.StartTest();

        dealer__Vehicle_Inventory__c tempVehicle = [SELECT Id, RecordTypeId FROM dealer__Vehicle_Inventory__c LIMIT 1];

        vehicleInventoryQuickActions.arvhiceVehicle(tempVehicle.Id);

        Id oldRecordType = tempVehicle.RecordTypeId;

        tempVehicle = [SELECT Id, RecordTypeId FROM dealer__Vehicle_Inventory__c WHERE Id = :tempVehicle.Id LIMIT 1];

        System.assertNotEquals(oldRecordType, tempVehicle.recordTypeId);

        Test.StopTest();
    }

    public static testMethod void testCloneTemplate()
    {
        Test.StartTest();

        dealer__Vehicle_Inventory__c tempVehicle = [SELECT Id, dealer__VIN__c FROM dealer__Vehicle_Inventory__c LIMIT 1];

        vehicleInventoryQuickActions.cloneTemplate(tempVehicle.Id, tempVehicle.dealer__VIN__c);

        Test.StopTest();
    }
}