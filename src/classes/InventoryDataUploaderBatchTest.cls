/**
* InventoryDataUploaderBatchTest
*
* MobilityWorks (c) - 2018
*
* Tested By: InventoryDataUploaderBatchTest
* Developer: Alexander Miller
* Date 3/6/2018
*/
@isTest
public class InventoryDataUploaderBatchTest {

    public static String exampleVIN = 'JA3AJ26E23U057585';
    public static String exampleVIN2 = '2HGFG3A53CH042357';
    public static String statusDelivered = 'Delivered';
    public static String stagAtSeller = 'At Seller';

    public static testMethod void testRun()
    {
		Test.startTest();

        Account tempAccount = new Account();
        tempAccount.Name = 'test1235123';
        insert tempAccount;

		// BLL1
		List<dealer__Vehicle_Inventory__c> vehInvs = new List<dealer__Vehicle_Inventory__c>();
		// BLL1 end
        dealer__Vehicle_Inventory__c tempVehicle = new dealer__Vehicle_Inventory__c();
        tempVehicle.dealer__VIN__c = exampleVIN;
        tempVehicle.dealer__Stock_Number__c = 'TEST12345';
        tempVehicle.dealer__Make__c = 'CHEVROLET';
        tempVehicle.dealer__Model__c = 'Suburban';
        tempVehicle.dealer__Year__c = '2011';
        tempVehicle.RecordTypeId = Schema.SObjectType.dealer__Vehicle_Inventory__c.getRecordTypeInfosByName().get('New').getRecordTypeId();
        tempVehicle.Stage__c = stagAtSeller;
        tempVehicle.dealer__Status_Code__c = statusDelivered;
		// BLL1
        //insert tempVehicle;
		vehInvs.add(tempVehicle);
		// BLL1 end

        dealer__Vehicle_Inventory__c tempVehicle2 = new dealer__Vehicle_Inventory__c();
        tempVehicle2.dealer__VIN__c = exampleVIN2;
        tempVehicle2.dealer__Stock_Number__c = 'TEST12346';
        tempVehicle2.dealer__Make__c = 'CHEVROLET';
        tempVehicle2.dealer__Model__c = 'Suburban';
        tempVehicle2.dealer__Year__c = '2011';
        tempVehicle2.RecordTypeId = Schema.SObjectType.dealer__Vehicle_Inventory__c.getRecordTypeInfosByName().get('New').getRecordTypeId();
        tempVehicle2.Stage__c = stagAtSeller;
        tempVehicle2.dealer__Status_Code__c = statusDelivered;
		// BLL1
        //insert tempVehicle2;
		vehInvs.add(tempVehicle2);
		insert(vehInvs);
		// BLL1 end

        InventoryDataUploaderController.InventoryItem tempItem1 = new InventoryDataUploaderController.InventoryItem();
        tempItem1.vehicle = tempVehicle;
        tempItem1.willUpdate = true;

        InventoryDataUploaderController.InventoryItem tempItem2 = new InventoryDataUploaderController.InventoryItem();
        tempItem2.vehicle = tempVehicle2;
        tempItem2.willUpdate = false;

        List<InventoryDataUploaderController.InventoryItem> listOfInventory = new List<InventoryDataUploaderController.InventoryItem>();
        listOfInventory.add(tempItem1);
        listOfInventory.add(tempItem2);

		InventoryDataUploaderBatch temp = new InventoryDataUploaderBatch();
        // BLL1
		//temp.jsonString = JSON.serialize(temp);
		temp.jsonString = JSON.serialize(listOfInventory);
		// BLL1 end
		database.executeBatch(temp,2);

		Test.stopTest();
	}
}