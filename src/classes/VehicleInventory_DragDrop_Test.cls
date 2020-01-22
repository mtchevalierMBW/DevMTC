/**
* VehicleInventory_DragDrop_Test
* Tests: VehicleInventory_DragDrop.apxc
 *
* 	Date       	Programmer  Description
*	2016-12-01  A. Bangle   Created Test Class
*	2018-07-31	B. Leaman	Cannot update stock# without special permission; difficult to chg setup data and other data in setup method;
*/

@isTest
private class VehicleInventory_DragDrop_Test {
    @testSetup static void setupdata() {
        TestHelper_MW th = new TestHelper_MW();

        //Add a vehicle
		dealer__Vehicle_Inventory__c veh1 = th.getVehicleInventory('1'); 
        veh1.dealer__Status_Code__c = 'Ready for Sale';
        veh1.dealer__New_Used_Other__c = 'New';
        //BLL1d veh1.dealer__Stock_Number__c = 'AB123456';
        veh1.dealer__Inventory_Date__c = date.today();
        update veh1;

    }
    static testmethod void dragdropTest() {
        dealer__Vehicle_Inventory__c veh = [select Id, Name from dealer__Vehicle_Inventory__c limit 1];
        VehicleInventory_DragDrop dragdrop = new VehicleInventory_DragDrop();
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.addParameter('FileName','test');
        req.addParameter('parId',veh.Id);
        req.requestBody = Blob.valueof('test doc');
        
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        VehicleInventory_DragDrop.attachDoc();

    }

}