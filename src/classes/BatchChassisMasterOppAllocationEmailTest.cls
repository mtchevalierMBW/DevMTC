/**
 * BatchChassisMasterOppAllocationEmailTest
 * 
 * Created By: Alexander Miller
 * Created Date: 11/2/2018 
 * Work Item: W-000464
 *
 * Modified By         Alias       Work Item       Date         Reason
 * ---------------------------------------------------------------------
 * Alexander Miller    AMM1        IR-0050229      3.6.2019     Test class failure due to related updates
 */
 @isTest(SeeAllData=true)
public class BatchChassisMasterOppAllocationEmailTest {

    public static testMethod void testSchedule()
    {
        Test.startTest();        
        BatchChassisMasterOppAllocationEmail sh1 = new BatchChassisMasterOppAllocationEmail();
        String sch = '0 0 23 * * ?'; 
        system.schedule('BatchChassisMasterOppAllocationEmailTest', sch, sh1);
        Test.stopTest();
    }

    public static testMethod void testRun()
    {
        Test.startTest();  

        // AMM1
        // User tempUser = RootStockDataFactory.createSalesUser();
        // 
        // insert tempUser;
        User tempUser = [SELECT Id FROM User WHERE Profile.Name = 'RS TW Sales' LIMIT 1];
        // AMM1

        String Vin = RootStockDataFactory.generateRandomString(17);

        Chassis_Master__c tempChassis = RootStockDataFactory.createChassisMaster('2017', 'Ford', Vin, Vin.substring(0,6), RootStockDataFactory.getDivisionMaster('AK').Id);

        insert tempChassis;

        Opportunity__c tempOpp = RootStockDataFactory.createGenericCustomOpportunity('BatchChassisMasterOppAllocationEmailTest', 'MBW', System.Today(), tempUser.Id);

        insert tempOpp;

        tempChassis.Opportunity_Allocation__c = tempOpp.Id;

        update tempChassis;

        BatchChassisMasterOppAllocationEmail sh1 = new BatchChassisMasterOppAllocationEmail();
        database.executeBatch(sh1,1);
        Test.stopTest();
    }
}