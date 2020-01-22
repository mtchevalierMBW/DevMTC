/**
 * WMK, LLC (c) - 2018 
 *
 * ChassisMasterTriggerHandlerTest
 * 
 * Created By:   Alexander Miller
 * Created Date: 10/29/2018 
 * Work Item:    W-000464
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1        IR-0044212   11/19/2018  Disabling this functionality for a moment in Production. Can't reproduce in sandbox.
 */
 @isTest(SeeAllData=true)
public class ChassisMasterTriggerHandlerTest {

    public static testMethod void testOpportunityAllocation()
    {
        Test.StartTest();

        User tempUser = RootStockDataFactory.createSalesUser();
		
        // AMM1
        //insert tempUser;
        // AMM1

        Opportunity__c tempOpportunity = RootStockDataFactory.createGenericCustomOpportunity(
                                                                                            RootStockDataFactory.generateRandomString(10),
                                                                                            'MBW',
                                                                                            System.Today(),
                                                                                            tempUser.Id);

        insert tempOpportunity;

        

        List<Chassis_Master__c> listOfChassis = new List<Chassis_Master__c>();

        for(Integer i = 0; i < 10; i++)
        {
            String vin = RootStockDataFactory.generateRandomString(17);

            Chassis_Master__c tempChassis = RootStockDataFactory.createChassisMaster('2017', 'Ford', vin, vin.substring(0, 6), RootStockDataFactory.getDivisionMaster('AK').Id);

            tempChassis.Opportunity_custom__c = tempOpportunity.Id;

            listOfChassis.add(tempChassis);
        }

        insert listOfChassis;   

        update listOfChassis;

        tempOpportunity = [SELECT Id, 
                            Number_Of_Vehicles_Allocated__c 
                        FROM Opportunity__c
                        WHERE Id = :tempOpportunity.Id
                        LIMIT 1];

        System.debug(tempOpportunity.Number_Of_Vehicles_Allocated__c);

        //System.assertNotEquals(0, tempOpportunity.Number_Of_Vehicles_Allocated__c);

        Test.StopTest();
    }
}