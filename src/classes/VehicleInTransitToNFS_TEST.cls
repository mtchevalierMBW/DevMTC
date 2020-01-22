/**
 * VehicleInTransitToNFS_TEST
 * Tests: VehicleInTransitToNFS
 * Date: Apr 3, 2018
 * Programmer: Bryan Leaman
 * 
 * 
 */
@isTest
private class VehicleInTransitToNFS_TEST {

    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

    @testSetup
    private static void setupTestData() {
        TestHelper_MW.createBaseFFAData(FFAdata);
        //FFAdata.refresh(); 
        System.runAs(FFAdata.TestUser) {
        
            // Create 3 vehicles
            List<dealer__Vehicle_Inventory__c> vehs = new List<dealer__Vehicle_Inventory__c>();
            vehs.add(new dealer__Vehicle_Inventory__c(
                dealer__VIN__c = 'TEST1234567890AB1',
                dealer__Stock_Number__c = '890AB1',
                dealer__Make__c = 'Toyota',
                dealer__Model__c = 'FutureVan',
                dealer__Year__c = '2020',
                dealer__Store_Location__c = FFAdata.DealerLocation.Id,
                dealer__Inventory_Date__c = null,
                dealer__Status_Code__c = 'In Transit',
                dealer__Status_Code_Assignment_Date__c = Date.today().addDays(-8)
            ));
            vehs.add(new dealer__Vehicle_Inventory__c(
            dealer__VIN__c = 'TEST1234567890AB2',
            dealer__Stock_Number__c = '890AB2',
            dealer__Make__c = 'Toyota',
                dealer__Model__c = 'FutureVan',
                dealer__Year__c = '2020',
                dealer__Store_Location__c = FFAdata.DealerLocation.Id,
                dealer__Inventory_Date__c = null,
                dealer__Status_Code__c = 'In Transit',
                dealer__Status_Code_Assignment_Date__c = Date.today().addDays(-6)
            ));
            vehs.add(new dealer__Vehicle_Inventory__c(
                dealer__VIN__c = 'TEST1234567890AB3',
                dealer__Stock_Number__c = '890AB3',
                dealer__Make__c = 'Toyota',
                dealer__Model__c = 'FutureVan',
                dealer__Year__c = '2020',
                dealer__Store_Location__c = FFAdata.DealerLocation.Id,
                dealer__Inventory_Date__c = null,
                dealer__Status_Code__c = 'Ready For Sale',
                dealer__Status_Code_Assignment_Date__c = Date.today().addDays(-12)
            ));
            insert(vehs);
        }
        
    }


    static testMethod void unitTest() {

        FFAdata.refresh(); 
        System.runAs(FFAdata.TestUser) {
            TestHelper_MW th = new TestHelper_MW();
            Test.startTest();
            VehicleInTransitToNFS ba = new VehicleInTransitToNFS(null, true);
            Database.executeBatch(ba);
            Test.stopTest();
            
            // assertions
            boolean veh1 = false;
            boolean veh2 = false;
            boolean veh3 = false;
            for (dealer__Vehicle_Inventory__c v : [
                select Id, Name, dealer__Stock_Number__c, dealer__Status_Code__c, dealer__Status_Code_Assignment_Date__c, 
                    dealer__Store_Location__c, dealer__Store_Location__r.Name, dealer__Store_Location__r.ManufacturingLocation__c
                from dealer__Vehicle_Inventory__c
            ]) {
                System.debug(v);
                System.debug(v.dealer__Store_Location__r.Name);
                System.debug(v.dealer__Store_Location__r.ManufacturingLocation__c);
                if (v.dealer__Stock_Number__c=='890AB1') {
                    veh1 = true;
                    System.assertEquals(v.dealer__Status_Code__c, 'Not For Sale', 'Older in-transit vehicle did not switch to NFS.');
                    System.assertEquals(v.dealer__Status_Code_Assignment_Date__c, Date.today(), 'Older in-transit vehicle NFS assignment date was not set.');
                }
                if (v.dealer__Stock_Number__c=='890AB2') {
                    veh2 = true;
                    System.assertEquals(v.dealer__Status_Code__c, 'In Transit', 'Newer in-transit vehicle status did not remain In Transit.');
                    System.assert(v.dealer__Status_Code_Assignment_Date__c!=Date.today(), 'Older in-transit vehicle assignment date was changed.');
                }
                if (v.dealer__Stock_Number__c=='890AB3') {
                    veh3 = true;
                    System.assertEquals(v.dealer__Status_Code__c, 'Ready For Sale', 'Non- in-transit vehicle status did not retain status.');
                    System.assert(v.dealer__Status_Code_Assignment_Date__c!=Date.today(), 'Non- in-transit vehicle assignment date was changed.');
                }
            }
            System.assert(veh1==true, 'Did not find test vehicle 1');
            System.assert(veh2==true, 'Did not find test vehicle 2');
            System.assert(veh3==true, 'Did not find test vehicle 3');
            
        }
        
    }
    
    
    static testMethod void TestCRON() {
        Test.startTest();
        List<String> jobIds = VehicleInTransitToNFS.scheduleMe();
        String firstJobId = jobIds[0];

        // Get the information from the CronTrigger API object
        CronTrigger ct = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime
            FROM CronTrigger 
            WHERE id = :firstJobId
        ];
 
        // Verify the expressions are the same
        System.assertEquals(VehicleInTransitToNFS.CRON_LIST[0], ct.CronExpression);
 
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        Test.stopTest();
        
    }
    
}