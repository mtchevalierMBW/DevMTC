/**
* VehicleInventory_TitleReport_Test
* Tests: VehicleInventory_TitleReport.apxc
 *
*  Date        Programmer  Description
*  2016-12-1  A. Bangle   Created Class
*/

@isTest
private class VehicleInventory_TitleReport_Test {
    @testSetup static void setupdata() {
        TestHelper_MW th = new TestHelper_MW();
        dealer__Vehicle_Inventory__c veh1 = th.getVehicleInventory('1'); 
        veh1.dealer__Status_Code__c = 'Ready for Sale';
        veh1.dealer__New_Used_Other__c = 'New';
        veh1.dealer__Inventory_Date__c = date.today();
        update veh1;
    }
    static testmethod void unitTest(){
        //
        VehicleInventory_TitleReport vehrep = new VehicleInventory_TitleReport();
        vehrep.vehicles_query();
        List<SelectOption> locopt = vehrep.location_options;
        vehrep.test = '';
    }

}