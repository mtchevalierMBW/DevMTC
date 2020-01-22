/**
* TransitWorks (c) - 2018
* 
* OpportunityTriggerHandlerCustomTest
* 
* CreatedBy: Alexander Miller
* CreatedDate: 9-26-2018
* Work Item: W-000361
* Modified By         Alias       Work Item       Date         Reason
* ---------------------------------------------------------------------
* Alexander Miller    AMM1        IR-0050229      3.6.2019     Test class failure due to related updates
*/
@isTest(SeeAllData=true)
public class OpportunityTriggerHandlerCustomTest {

    public static testMethod void testInsert()
    {
        Test.startTest();
        
        // AMM1
        //rstk__socust__c customerMaster = [SELECT Id FROM rstk__socust__c LIMIT 1];
        //
        //Opportunity__c tempOpp = new Opportunity__c();
        //tempOpp.Name = 'OpportunityTriggerHandlerCustomTest1';
        //tempOpp.Customer_Master__c = customerMaster.Id;
        //tempOpp.Close_Date__c = System.Today();
        //tempOpp.Status__c = 'Initial Contact';
        //tempOpp.Number_Of_Orders__c = 1;
        //tempOpp.Sales_Channel__c = 'Bid';
        //
        //insert tempOpp;
        User salesUser = RootStockDataFactory.createSalesUser();
        Opportunity__c customOpp = RootStockDataFactory.createGenericCustomOpportunity('testCustomOpp', 'MBW', System.Today(), salesUser.Id);
        insert customOpp;
        
        // AMM1
        
        Test.stopTest();
    }
    
    public static testMethod void testUpdate()
    {
        Test.startTest();
        
        // AMM1
        //rstk__socust__c customerMaster = [SELECT Id FROM rstk__socust__c LIMIT 1];
        //
        //Opportunity__c tempOpp = new Opportunity__c();
        //tempOpp.Name = 'OpportunityTriggerHandlerCustomTest1';
        //tempOpp.Customer_Master__c = customerMaster.Id;
        //tempOpp.Close_Date__c = System.Today();
        //tempOpp.Status__c = 'Initial Contact';
        //tempOpp.Number_Of_Orders__c = 1;
        //tempOpp.Sales_Channel__c = 'Bid';
        //
        //insert tempOpp;
        User salesUser = RootStockDataFactory.createSalesUser();
        Opportunity__c tempOpp = RootStockDataFactory.createGenericCustomOpportunity('testCustomOpp', 'MBW', System.Today(), salesUser.Id);
        insert tempOpp;
        
        // AMM1
        
        rstk__socust__c customerMaster2 = [SELECT Id FROM rstk__socust__c WHERE Id != :tempOpp.Customer_Master__c LIMIT 1];
        
        tempOpp.Sales_Channel__c = 'MBW';
        tempOpp.Close_Date__c = System.Today().addDays(1);
        tempOpp.Customer_Master__c = customerMaster2.Id;
        tempOpp.Status__c = 'Lost';
        tempOpp.Lost_Reason__c = 'Lost Bid';
        
        update tempOpp;
        
        Test.stopTest();
    }
}