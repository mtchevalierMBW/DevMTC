/**
 * WMK, LLC (c) - 2018 
 *
 * ContentTagTriggerHandlerTest
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/8/2018 
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
@isTest
public class ContentTagTriggerHandlerTest {

    @testSetup
    public static void setup()
    {
        Content__c tempContent = new Content__c();
        tempContent.Group__c = 'Group1';
        tempContent.Title__c = 'Testing';
        insert tempContent;

        Tag__c tempTag = new Tag__c();
        tempTag.Name = 'Test1';
        insert tempTag;

        Content_Tag__c tempContentTag = new Content_Tag__c();
        tempContentTag.Content__c = tempContent.Id;
        tempContentTag.Tag__c = tempTag.Id;
        insert tempContentTag;
    }

    public static testMethod void testDuplicateTagInsert()
    {
        Test.StartTest();

        Tag__c tempTag = [SELECT Id
                        FROM Tag__c
                        LIMIT 1];
        Content__c tempContent = [SELECT Id 
                                FROM Content__c
                                LIMIT 1];
        
        Content_Tag__c tempContentTag = new Content_Tag__c();
        tempContentTag.Content__c = tempContent.Id;
        tempContentTag.Tag__c = tempTag.Id;

        try{
            insert tempContentTag;
        } catch(Exception e)
        {
            System.assert(e.getMessage().contains('This Content Tag is identical to another one'));
        }

        Test.StopTest();
    }
}