/**
 * WMK, LLC (c) - 2018 
 *
 * ContentTagComponentControllerTest
 * 
 * Created By:   Alexander Miller
 * Created Date: 12/7/2018 
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
 @isTest
public class ContentTagComponentControllerTest {

    @testSetup
    public static void testSetup()
    {
        Content__c tempContent = new Content__c();
        tempContent.Title__c = 'ContentObjectFieldMappingController';
        insert tempContent;
        
        Tag__c tempTag = new Tag__c();
        tempTag.Name = 'ContentTag';
        insert tempTag;
    }

    public static testMethod void testGetContentTags()
    {        
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        System.assertNotEquals(null, ContentTagComponentController.getContentTags(tempContent.Id));
    }

    public static testMethod void testGetTags()
    {        
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Tag__c tempTag = [SELECT Id FROM Tag__C LIMIT 1];

        ContentTagComponentController.updateSelectedTags(tempContent.Id, tempTag.Id);

        System.assertNotEquals(null, ContentTagComponentController.getTags(tempContent.Id));
    }

    public static testMethod void testRemoveSelectedTags()
    {        
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Tag__c tempTag = [SELECT Id FROM Tag__C LIMIT 1];

        ContentTagComponentController.updateSelectedTags(tempContent.Id, tempTag.Id);

        List<Content_Tag__c> listOfContentTag = ([SELECT Id FROM Content_Tag__c WHERE Tag__c = :tempTag.Id AND Content__c = :tempContent.Id]);

        ContentTagComponentController.removeSelectedTags(listOfContentTag);
    }
}