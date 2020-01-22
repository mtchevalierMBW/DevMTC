/**
 * WMK, LLC (c) - 2018 
 *
 * ContentMediaListControllerTest
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
public class ContentMediaListControllerTest {

    @testSetup
    public static void testSetup()
    {
        Content__c tempContent = new Content__c();
        tempContent.Title__c = 'ContentMediaListControllerTest';
        insert tempContent;
        
        Media__c tempMedia = new Media__c();
        tempMedia.Content__c = tempContent.Id;
        tempMedia.Title__c = 'ContentMediaListControllerTest';
        insert tempMedia;

        LightningFileUtility tempUtility = new LightningFileUtility();
        tempUtility.addFile('Title.docx', 'Body', tempMedia.Id, false, null);
        tempUtility.commitFiles();
    }

    public static testMethod void testGetMediaRecord()
    {
        Content__c tempContent = [SELECT Id 
                                  FROM Content__c 
                                  LIMIT 1];
        
        System.assert(ContentMediaListController.getMediaRecord(tempContent.Id) != null);
    }

    public static testMethod void testUpdateContentFileExtension()
    {
        Media__c tempMedia = [SELECT Id,
                                Media_Type__c 
                            FROM Media__c
                            LIMIT 1];

        System.assertEquals(null, tempMedia.Media_Type__c);

        LightningFileUtility tempUtility = new LightningFileUtility();
        List<ContentDocument> listOfContentDocuments = tempUtility.getContentDocumentsByParentId(tempMedia.Id);

        ContentMediaListController.updateContentFileExtension(tempMedia, listOfContentDocuments.get(0));

        tempMedia = [SELECT Id,
                        Media_Type__c 
                    FROM Media__c
                    LIMIT 1];

        System.assertNotEquals(null, tempMedia.Media_Type__c);
    }

    public static testMethod void testGetContentDocumentList()
    {
        Media__c tempMedia = [SELECT Id 
                            FROM Media__c
                            LIMIT 1];

        System.assertNotEquals(null, ContentMediaListController.getContentDocumentList(tempMedia.Id));
    }

    public static testMethod void testUpdateMediaURL()
    {
        Media__c tempMedia = [SELECT Id,
                                Content__c 
                            FROM Media__c
                            LIMIT 1];

        ContentMediaListController.updateMediaURL(tempMedia.Id, 'www.google.com', tempMedia.Content__c);
    }
}