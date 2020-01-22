/**
 * WMK, LLC (c) - 2018 
 *
 * ChassisMasterDallocationbuttonController
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/1/2018 
 * Tested By:    ChassisMasterDallocationbuttonTest
 * Work Item:    W-000464
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
@isTest(SeeAllData=true)
public class ChassisMasterDallocationbuttonTest {

    public static testMethod void testOpportunityDeallocate()
    {
        Test.StartTest();

        User tempUser = RootStockDataFactory.createSalesUser();

        Opportunity__c tempOpp = RootStockDataFactory.createGenericCustomOpportunity('ChassisMasterDallocationbuttonTest', 'MBW', System.Today(), tempUser.Id);

        String VIN = RootStockDataFactory.generateRandomString(17);

        Chassis_Master__c tempChassis = RootStockDataFactory.createChassisMaster('2017', 'Ford', VIN, VIN.substring(0,6), RootStockDataFactory.getDivisionMaster('AK').Id);

        tempChassis.Opportunity_Allocation__c = tempOpp.Id;

        insert tempChassis;

        List<Id> listOfChassisId = new List<Id>();

        listOfChassisId.add(tempChassis.Id);

        ChassisMasterDallocationbuttonController.opportunityDeallocate(listOfChassisId);

        tempChassis = [SELECT Id, 
                        Opportunity_Allocation__c 
                    FROM Chassis_Master__c 
                    WHERE Id = :tempChassis.Id 
                    LIMIT 1];

        System.assertEquals(null, tempChassis.Opportunity_Allocation__c);

        Test.StopTest();
    }
}