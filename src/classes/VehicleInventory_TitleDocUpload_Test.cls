/**
* VehicleInventory_TitleDocUpload_Test
* Tests: VehicleInventory_TitleDocUpload.apxc
*
* 	Date       	Programmer  Description
*	2016-12-01 	A. Bangle   Created Test Class
*	2018-07-31	B. Leaman	Cannot change stock# w/out permission set, and cannot add in same method.
*/

@isTest
private class VehicleInventory_TitleDocUpload_Test {
	
	
    @testSetup static void setupdata() {
        TestHelper_MW th = new TestHelper_MW();
        
        //Add a vehicle
		dealer__Vehicle_Inventory__c veh1 = th.getVehicleInventory('1'); 
        veh1.dealer__Status_Code__c = 'Ready for Sale';
        veh1.dealer__New_Used_Other__c = 'New';
        //veh1.dealer__Stock_Number__c = 'AB123456';
        veh1.dealer__Inventory_Date__c = date.today();
        update veh1;
        //Add an attachment to vehicle
        Attachment attach = new Attachment();
        attach.Name = veh1.dealer__Stock_Number__c+'lien-release.pdf';
        Blob bodyBlob = Blob.valueOf('Test Lien Release');
        attach.body = bodyBlob;
        attach.ParentId = veh1.Id;
        insert attach;
    }
    
    static testmethod void unitTest() {

        //
        //VehicleInventory_TitleDocUpload vehdoc = new VehicleInventory_TitleDocUpload();
        dealer__Vehicle_Inventory__c veh = [select Id, Name from dealer__Vehicle_Inventory__c limit 1];
        VehicleInventory_TitleDocUpload vehdoc = new VehicleInventory_TitleDocUpload(new ApexPages.StandardController(veh));
        vehdoc.updateFlags();
        vehdoc.getItems();
        vehdoc.docSelection();
        vehdoc.getTitleDocItems();
        vehdoc.lienRelease = '';
        vehdoc.powerofAttorney = '';
        vehdoc.msoTitle = '';
        vehdoc.proofPaymentTrade = ''; 
        vehdoc.invoice = '';
    }

}