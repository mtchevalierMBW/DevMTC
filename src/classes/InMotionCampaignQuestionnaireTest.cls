/**
 * WMK, LLC (c) - 2019 
 *
 * InMotionCampaignQuestionnaireTest
 * 
 * Created By:   Alexander Miller
 * Created Date: 2/28/2019 
 * Work Item:    W-000603
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 */
@isTest
public class InMotionCampaignQuestionnaireTest {

    @TestSetup
    public static void setup()
    {
        Account tempAccount = new Account();
        tempAccount.Name = 'InMotionAccountSelectorControllerTest';
        insert tempAccount;

        Campaign tempCampaign = new Campaign();
        tempCampaign.Name = 'InMotionAccountSelectorControllerTest';
        insert tempCampaign;

        In_Motion_Question__c tempQuestion = new In_Motion_Question__c();
        tempQuestion.Campaign__c = tempCampaign.Id;
        tempQuestion.Order__c = 0;
        tempQuestion.Question__c = 'test question';
        tempQuestion.Type__c = 'Options';
        insert tempQuestion; 

        In_Motion_Option__c tempOption = new In_Motion_Option__c();
        tempOption.In_Motion_Question__c = tempQuestion.Id;
        tempOption.Value__c = 'Test';
        insert tempOption;

        In_Motion_Action__c tempAction = new In_Motion_Action__c();
        tempAction.In_Motion_Option__c = tempOption.Id;
        tempAction.Mode__c = 'True';
        tempAction.Object__c = 'Task';
        tempAction.Task_Description__c = 'This IS a test';
        tempAction.Task_Due_Date_In_Days__c = 10;
        tempAction.Task_Subject__c = 'Test Subject';
        insert tempAction;
    }

    public static testMethod void testGetQuestions()
    {
        Test.StartTest();

        Campaign tempCampaign = [SELECT Id FROM Campaign LIMIT 1];

        List<In_Motion_Question__c> listOfQuestions = InMotionCampaignQuestionnaireController.getQuestions(tempCampaign.Id);

        System.assertNotEquals(0, listOfQuestions.size());

        Test.StopTest();
    }

    public static testMethod void testProcessResponses()
    {
        Test.StartTest();
        
        Id tempQuestionId = [SELECT ID FROM In_Motion_Question__c LIMIT 1].Id;
        Id tempCampaignId = [SELECT ID FROM Campaign LIMIT 1].Id;
        Id tempAccountId = [SELECT ID FROM Account LIMIT 1].Id;

        //String tempJSON = '[{"questionId":"a0cq00000002AhmAAE","campaignId":"7011T000001BPOrQAO","accountId":"0015000001WMIhyAAH","questionBoolean":true}]';

        String tempJSON = '[{"questionId":"';

        tempJSON = tempJSON + String.valueOf(tempQuestionId) + '","campaignId":"';

        tempJSON = tempJSON + String.valueOf(tempCampaignId) + '","accountId":"';

        tempJSON = tempJSON + String.valueOf(tempAccountId) + '","questionBoolean":true}]';

        InMotionCampaignQuestionnaireController.processResponses(tempJSON);

        Test.StopTest();
    }
}