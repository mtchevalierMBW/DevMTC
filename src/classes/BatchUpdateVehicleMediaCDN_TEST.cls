/**
 * BatchUpdateVehicleMediaCDN_TEST
 * Tests: BatchUpdateVehicleMediaCDN_TEST
 * Date: Jun 20, 2017
 * Programmer: Bryan Leaman
 * 
 * 
 */
@isTest
private class BatchUpdateVehicleMediaCDN_TEST {

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	private static void setupTestData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		
		System.runAs(FFAdata.TestUser) {
	        dealer__Vehicle_Inventory__c veh = new dealer__Vehicle_Inventory__c(
	        	dealer__Year__c='2021', dealer__Make__c='Unknown', dealer__Model__c='Futuristic',
	        	dealer__VIN__c='12345698765ABCZYX', dealer__Stock_Number__c='ABCZYX', 
	        	PaymentDueDays__c=1, PaymentDueDate__c=null, dealer__Sale_Date__c = Date.today()
	        );
	        insert(veh);
	        dealer__Inventory_Images__c img = new dealer__Inventory_Images__c(
	        	dealer__Vehicle_Inventory__c=veh.Id,
	        	dealer__Image_Name__c='Test.jpg',
	        	dealer__Photographer__c=UserInfo.getUserId(),
	        	dealer__MIME_Type__c='image/jpeg',
	        	dealer__Image_URL__c='https://s3.amazonaws.com/vehicle-images/961c3a8d-f1b2-4ae2-9b5d-ab1fdf2de1a3.JPG',
	        	dealer__Thumbnail_URL__c='https://s3.amazonaws.com/vehicle-images/961c3a8d-f1b2-4ae2-9b5d-ab1fdf2de1a3_thumb.JPG'
	        );
	        insert(img);
		}
	}


	static testMethod void unitTest() {
		BatchUpdateVehicleMediaCDN ba = new BatchUpdateVehicleMediaCDN('1', false);
		Database.executeBatch(ba);
	}
	
	
}