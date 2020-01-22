/**
* TransitWorks (c) - 2018
*
* LeadTimeTriggerHandlerTest
*
* Created By: Alexander Miller
* Created Date: 8/20/2018
*/
@isTest(SeeAllData = true)
public class LeadTimeTriggerHandlerTest {

    public static testMethod void testConstructor()
    {
        Test.StartTest();

        LeadTimeTriggerHandler tempHandler = new LeadTimeTriggerHandler();

        LeadTimeTriggerHandler tempHandler2 = new LeadTimeTriggerHandler(new List<Lead_Time__c>(), new List<Lead_Time__c>(), new Map<Id, Lead_Time__c>(), new Map<Id, Lead_Time__c>());

        Test.StopTest();
    }

    public static testMethod void testFlagIfIdenticalLeadTimeExistsInsert()
    {
        Test.StartTest();

        // 1. One in Akron
        Lead_Time__c tempLeadTime1 = new Lead_Time__c();

        tempLeadTime1.Make__c = 'Ford';
        tempLeadTime1.Model__c = 'T-150';
        tempLeadTime1.Model_Ext__c = '';
        tempLeadTime1.Floor_Style__c = 'Wood Floor';
        tempLeadTime1.Frame__c = 'Cargo';
        tempLeadTime1.Division_Master__c = RootStockDataFactory.getDivisionMaster('AK').Id;

        insert tempLeadTime1;

        // duplicate in Akron
        Lead_Time__c tempLeadTime = new Lead_Time__c();

        tempLeadTime.Make__c = 'Ford';
        tempLeadTime.Model__c = 'T-150';
        tempLeadTime.Model_Ext__c = '';
        tempLeadTime.Floor_Style__c = 'Wood Floor';
        tempLeadTime.Frame__c = 'Cargo';
        tempLeadTime.Division_Master__c = RootStockDataFactory.getDivisionMaster('AK').Id;

        try{
            insert tempLeadTime;
        } catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('This lead time is identical to another one') ? true : false;
            system.assertEquals(expectedExceptionThrown,true);    
        }

        Test.StopTest();
    }

    public static testMethod void testFlagIfIdenticalLeadTimeExistsUpdate()
    {
        Test.StartTest();

        // 1. One in Akron
        Lead_Time__c tempLeadTime1 = new Lead_Time__c();

        tempLeadTime1.Make__c = 'Ford';
        tempLeadTime1.Model__c = 'T-150';
        tempLeadTime1.Model_Ext__c = '';
        tempLeadTime1.Floor_Style__c = 'Wood Floor';
        tempLeadTime1.Frame__c = 'Cargo';
        tempLeadTime1.Division_Master__c = RootStockDataFactory.getDivisionMaster('AK').Id;

        insert tempLeadTime1;

        // duplicate in Akron
        Lead_Time__c tempLeadTime = new Lead_Time__c();

        tempLeadTime.Make__c = 'Ford';
        tempLeadTime.Model__c = 'T-150';
        tempLeadTime.Model_Ext__c = '';
        tempLeadTime.Floor_Style__c = 'Wood Floor';
        tempLeadTime.Frame__c = 'Wagon';
        tempLeadTime.Division_Master__c = RootStockDataFactory.getDivisionMaster('AK').Id;

        insert tempLeadTime;

        tempLeadTime.Frame__c = 'Cargo';

        try{
            update tempLeadTime;
        } catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('This lead time is identical to another one') ? true : false;
            system.assertEquals(expectedExceptionThrown,true);    
        }

        Test.StopTest();
    }
}