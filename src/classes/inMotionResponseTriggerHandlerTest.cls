/**
 * WMK, LLC (c) - 2019  
 *
 * InMotionCampaignQuestionnaireController
 * 
 * Created By:   Alexander Miller
 * Created Date: 2/28/2019 
 * Work Item:    W-000603
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 */
 @isTest
public class inMotionResponseTriggerHandlerTest {

    @TestSetup
    public static void setup()
    {
		Account tempAccount = new Account();
        tempAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
        tempAccount.LastName = 'test';
        insert tempAccount;
        
        Campaign tempCampaign = new Campaign();
        tempCampaign.Name = 'inMotionResponseTriggerHandlerTest';
        insert tempCampaign;

        In_Motion_Question__c tempQuestion = new In_Motion_Question__c();
        tempQuestion.Campaign__c = tempCampaign.Id;
        tempQuestion.Order__c = 0;
        tempQuestion.Type__c = 'Options';
        tempQuestion.Question__c = 'Test?';
        insert tempQuestion;

        In_Motion_Option__c tempOption = new In_Motion_Option__c();
        tempOption.In_Motion_Question__c = tempQuestion.Id;
        tempOption.Value__c = 'test 1';
        insert tempOption;

        In_Motion_Action__c tempAction = new In_Motion_Action__c();
        tempAction.In_Motion_Option__c = tempOption.Id;
        tempAction.Mode__c = 'Not Null'; 
        tempAction.Object__c = 'Task';
        tempAction.Task_Due_Date_In_Days__c = 1;
        insert tempAction; 
    }

    public static TestMethod void testInsertion(){        
        
        Account tempAccount = [SELECT Id FROM Account LIMIT 1];
        
        In_Motion_Response__c tempResponse = new In_Motion_Response__c();
        In_Motion_Question__c tempQuestion = [SELECT Id FROM In_Motion_Question__c LIMIT 1];
        In_Motion_Action__c tempAction = [SELECT Id FROM In_Motion_Action__c LIMIT 1];
        In_Motion_Option__c tempOption = [SELECT Id, Value__c FROM In_Motion_Option__c LIMIT 1];

        tempResponse.In_Motion_Question__c = tempQuestion.Id;
        tempResponse.In_Motion_Action__c = tempAction.Id;
        tempResponse.Answer__c = tempOption.Value__c;
        tempResponse.Account__c = tempAccount.Id;

        Test.startTest();

        insert tempResponse;

        Test.stopTest();
    }
    
    public static TestMethod void testInsertionZeroToSixMonths(){        
        
        Account tempAccount = [SELECT Id FROM Account LIMIT 1];
        
        In_Motion_Response__c tempResponse = new In_Motion_Response__c();
        In_Motion_Question__c tempQuestion = [SELECT Id FROM In_Motion_Question__c LIMIT 1];
        In_Motion_Action__c tempAction = [SELECT Id FROM In_Motion_Action__c LIMIT 1];
        In_Motion_Option__c tempOption = [SELECT Id, Value__c FROM In_Motion_Option__c LIMIT 1];

        tempResponse.In_Motion_Question__c = tempQuestion.Id;
        tempResponse.In_Motion_Action__c = tempAction.Id;
        tempResponse.Answer__c = '0 - 6 Months';
        tempResponse.Account__c = tempAccount.Id;

        Test.startTest();

        insert tempResponse;

        Test.stopTest();
    }
    
    public static TestMethod void testInsertionSevenToTwelveMonths(){        
        
        Account tempAccount = [SELECT Id FROM Account LIMIT 1];
        
        In_Motion_Response__c tempResponse = new In_Motion_Response__c();
        In_Motion_Question__c tempQuestion = [SELECT Id FROM In_Motion_Question__c LIMIT 1];
        In_Motion_Action__c tempAction = [SELECT Id FROM In_Motion_Action__c LIMIT 1];
        In_Motion_Option__c tempOption = [SELECT Id, Value__c FROM In_Motion_Option__c LIMIT 1];

        tempResponse.In_Motion_Question__c = tempQuestion.Id;
        tempResponse.In_Motion_Action__c = tempAction.Id;
        tempResponse.Answer__c = '0 - 6 Months';
        tempResponse.Account__c = tempAccount.Id;

        Test.startTest();

        insert tempResponse;

        Test.stopTest();
    }
}