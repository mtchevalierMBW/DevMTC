/**
 * WMK, LLC (c) - 2018 
 *
 * ContentVideoPlayerControllerTest
 * 
 * Created By:   Alexander Miller
 * Created Date: 12/7/2018 
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1        W-000644      04/05/2019  Logic to prevent the "New" icon from showing up if its already been viewed by the user
 */
 @isTest
public class ContentVideoPlayerControllerTest {

    @testSetup
    public static void testSetup()
    {
        Content__c tempContent = new Content__c();
        tempContent.Title__c = 'ContentVideoPlayerControllerTest';
        insert tempContent;

        Media__c tempMedia = new Media__c();
        tempMedia.Title__c = 'ContentVideoPlayerControllerTest';
        tempMedia.Content__c = tempContent.Id;
        insert tempMedia;
    }

    public static testMethod void testGetMediaRecord()
    {        
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        System.assertNotEquals(null, ContentVideoPlayerController.getMediaRecord(tempContent.Id));
    }

    public static testMethod void testGetVideoId_URL()
    {        
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Media__c tempMedia = [SELECT Id FROM Media__c LIMIT 1];
        tempMedia.Video_URL__c = 'www.google.com';
        update tempMedia;

        System.assertNotEquals(null, ContentVideoPlayerController.getVideoId(tempContent.Id));
    }

    public static testMethod void testGetVideoId_ID()
    {        
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Media__c tempMedia = [SELECT Id FROM Media__c LIMIT 1];

        LightningFileUtility tempUtility = new LightningFileUtility();
        tempUtility.addFile('Title.docx', 'Body', tempMedia.Id, false, null);
        tempUtility.commitFiles();

        System.assertNotEquals(null, ContentVideoPlayerController.getVideoId(tempContent.Id));
    }

    // AMM1
    public static testMethod void testRecordContentView()
    {
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];
        Test.StartTest();
        ContentVideoPlayerController.recordContentView(tempContent.Id);
        List<Content_View__c> listOfContentViews = ([SELECT Id FROM Content_View__c WHERE Content__c = :tempContent.Id]);
        System.assertNotEquals(0, listOfContentViews.size());
        Test.StopTest();
    }

    public static TestMethod void testIsContentNew()
    {
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Test.StartTest();

        Boolean result = ContentVideoPlayerController.isContentNew(tempContent.Id);
        System.assertEquals(true, result);

        ContentVideoPlayerController.recordContentView(tempContent.Id);
        
        result = ContentVideoPlayerController.isContentNew(tempContent.Id);
        System.assertEquals(false, result);

        Test.StopTest();
    }
    // AMM1
}