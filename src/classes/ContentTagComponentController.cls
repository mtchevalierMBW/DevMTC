/**
 * WMK, LLC (c) - 2018 
 *
 * ContentTagComponentController
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/13/2018 
 * Tested By: ContentTagComponentControllerTest
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
public with sharing class ContentTagComponentController {

    @AuraEnabled
    public static List<Content_Tag__c> getContentTags(Id contentId)
    {
        return [SELECT Id,
                    Name,
                    Tag__c,
                    Tag__r.Name,
                    Content__c,
                    Tag_Name__c
                FROM Content_Tag__c 
                WHERE Content__c = :contentId
                ORDER By Name DESC];
    }

    @AuraEnabled
    public static List<Tag__c> getTags(Id contentId)
    {
        List<Content_Tag__c> listOfContentTags = getContentTags(contentId);

        List<Id> listOfUsedTagIds = new List<Id>();

        for(Content_Tag__c tempContentTag : listOfContentTags)
        {
            listOfUsedTagIds.add(tempContentTag.Tag__c);
        }

        return [SELECT Id,
                    Name
                FROM Tag__c
                WHERE Id NOT IN :listOfUsedTagIds
                ORDER By Name DESC];
    }

    @AuraEnabled
    public static void updateSelectedTags(Id contentId, Id tagId)
    {
        Content_Tag__c tempContentTag = new Content_Tag__c();

        tempContentTag.Tag__c = tagId;
        tempContentTag.Content__c = contentId;

        insert tempContentTag;
    }

    @AuraEnabled
    public static void removeSelectedTags(List<Content_Tag__c> tempList)
    {
        delete tempList;
    }
}