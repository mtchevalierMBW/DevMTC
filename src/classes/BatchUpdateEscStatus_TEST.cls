/**
 * BatchUpdateEscStatus_TEST
 * Tests: BatchUpdateEscStatus
 * Date: Dec 19, 2017
 * Programmer: Bryan Leaman
 * 
 *	2018-09-13	B. Leaman	BLL4 - reduce SOQL queries by setting start/stop test boundaries.
 * 
 */
@isTest
private class BatchUpdateEscStatus_TEST {

    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

    @testSetup
    private static void setupTestData() {
        TestHelper_MW.createBaseFFAData(FFAdata);
        FFAdata.refresh(); 
        System.runAs(FFAdata.TestUser) {

        TestHelper_MW th = new TestHelper_MW();
        Account a = th.getPersonAccount('1');
        
        List<SObject> testdata = new List<SObject>();
        dealer__Service_Vehicle__c sv = new dealer__Service_Vehicle__c(
            dealer__VIN__c = '5TDYK3DC1ES000000',
            dealer__Year__c = '1899',
            dealer__Make__c = 'Toyota',
            dealer__Carline__c = 'Pasada',
            dealer__Last_Odometer__c = 123456,
            dealer__Sale_Date__c = Date.today(),
            dealer__Veh_Owner__c = a.Id,
            dealer__Veh_Owner_Contact__c = a.PersonContactId
        );
        insert(sv);
        
        dealer__Sales_Up__c sup = new dealer__Sales_Up__c(
            dealer__Lead_Date__c=System.Today(),
            dealer__First_Store_Visit_Date__c = DateTime.now(),     
            dealer__Lead_Status__c='Pending',
            dealer__Lead_Type__c='List',
            dealer__Source__c ='Pride',
            Solution_Type__c ='Chassis/Conversion',
            dealer__Customer_Account__c =a.id,
            dealer__Trade_Year__c = '2016',
            dealer__Trade_Make__c = 'Toyota',
            dealer__Trade_Model__c = 'Greatness'
        );
        insert(sup);
        
        dealer__Deal__c deal = new dealer__Deal__c(
            dealer__Deal_ID__c = 'TestDeal123',
            Name = 'TestDeal123',
            dealer__Status__c = 'Won - Delivered',
            dealer__Buyer__c = a.Id,
            Proposed_Delivery_Date__c = Date.today(),
            dealer__Deal_Type__c='Equipment',
            AdministrativeUpdate__c=true,
            dealer__Sales_Lead__c=sup.Id
        );
        insert(deal);
        
        dealer__Service_Contract__c esc = new dealer__Service_Contract__c(
            dealer__Description__c='Test ESC package',
            dealer__Car_Deal__c=deal.Id,
            dealer__Service_Vehicle__c=sv.Id,
            dealer__Start_Date__c = Date.newInstance(2015,1,1),
            dealer__End_Date__c = Date.newInstance(2016,12,31),
            dealer__Expiration_Mileage__c = 120000,
            dealer__Expiration_Months__c = 24
        );
        Database.insert(esc);

        }

    }


    static testMethod void unitTest() {

        FFAdata.refresh(); 
        System.runAs(FFAdata.TestUser) {
            TestHelper_MW th = new TestHelper_MW();
			Test.startTest();	// BLL1a
            BatchUpdateEscStatus ba = new BatchUpdateEscStatus('1', false);
            Database.executeBatch(ba);
            Test.stopTest();	// BLL1a
        }
        
    }
    
    
    static testMethod void TestCRON() {
        Test.startTest();
        List<String> jobIds = BatchUpdateEscStatus.scheduleMe();
        String firstJobId = jobIds[0];
        Test.stopTest();

        // Get the information from the CronTrigger API object
        CronTrigger ct = [
            SELECT Id, CronExpression, TimesTriggered, NextFireTime
            FROM CronTrigger 
            WHERE id = :firstJobId
        ];
 
        // Verify the expressions are the same
        System.assertEquals(BatchUpdateEscStatus.CRON_LIST[0], ct.CronExpression);
 
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        
    }
    
}