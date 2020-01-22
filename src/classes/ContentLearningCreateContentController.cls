/**
 * WMK, LLC (c) - 2018 
 *
 * ContentLearningCreateContentController
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/26/2018
 * Tested By: ContentLearningCreateContentControllerT 
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
public with sharing class ContentLearningCreateContentController {

    @AuraEnabled
    public static Content__c createContentRecord(String title, String description)
    {
        Content__c tempContent = new Content__c();

        tempContent.Title__c = title;
        tempContent.Description__c = description;
        
        insert tempContent;

        createMediaChildRecord(tempContent.Id, title);

        return tempContent;
    }

    @AuraEnabled
    public static void createMediaChildRecord(Id parentContentId, String title)
    {
        Media__c tempMedia = new Media__c();

        tempMedia.Content__c = parentContentId;
        tempMedia.Title__c = title;

        insert tempMedia;
    }
}