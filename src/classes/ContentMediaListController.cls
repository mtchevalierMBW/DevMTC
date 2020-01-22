/**
 * WMK, LLC (c) - 2018 
 *
 * ContentMediaListController
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/12/2018 
 * Tested By: ContentMediaListControllerTest
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
public with sharing class ContentMediaListController {

    @AuraEnabled
    public static Media__c getMediaRecord(Id contentId){
        
        List<Media__c> listOfMedia = ([SELECT Id,
                                        CreatedDate,
                                        Video_URL__c,
                                        Video_Id__c
                                    FROM Media__c
                                    WHERE Content__c = :contentId
                                    ORDER By CreatedDate DESC
                                    LIMIT 1]);
        
        if(listOfMedia.size() > 0)
        {
            return listOfMedia.get(0);
        }
        else {
            return null;
        }
    }

    @AuraEnabled
    public static void updateContentFileExtension(Media__c tempMedia, ContentDocument tempDocument)
    {
        // update the file type of media if they're null or don't match
        if(tempMedia.Media_Type__c == null ||
            (tempMedia.Media_Type__c != null && tempMedia.Media_Type__c != tempDocument.FileExtension))
        {
            tempMedia.Media_Type__c = tempDocument.FileExtension;
            update tempMedia;
        }
    }

    @AuraEnabled
    public static List<ContentDocument> getContentDocumentList(Id contentMediaId)
    {
        LightningFileUtility tempUtility = new LightningFileUtility();

        List<ContentDocument> tempDocumentList = tempUtility.getContentDocumentsByParentId(contentMediaId);

        Media__c tempMedia = [SELECT Id, 
                                Media_Type__c 
                            FROM Media__c 
                            WHERE Id = :contentMediaId];

        if(tempDocumentList != null && tempDocumentList.size() >= 1)
        {
            setMediaAttachmentId(contentMediaId, tempDocumentList.get(0).Id); 
            updateContentFileExtension(tempMedia, tempDocumentList.get(0));
        }

        // only show the 5 most recent files
        List<ContentDocument> returningList = new List<ContentDocument>();

        for(Integer i = 0; i < tempDocumentList.size() && i < 5; i++)
        {
            returningList.add(tempDocumentList.get(i));
        }

        return returningList;
    }

    @AuraEnabled
    public static void setMediaAttachmentId(Id contentMediaId, Id documentId)
    {
        Media__c tempMedia = new Media__c();
        tempMedia.Id = contentMediaId;
        tempMedia.Video_Id__c = documentId;

        update tempMedia;
    }

    @AuraEnabled
    public static void updateMediaURL(Id mediaId, String urlParam, Id contentId)
    {
        Media__c tempMedia = new Media__c();
        tempMedia.Id = mediaId;
        tempMedia.Video_URL__c = urlParam;

        update tempMedia;

        updateContentForMostRecentEdit(contentId);
    }

    @AuraEnabled
    public static void updateContentForMostRecentEdit(Id contentId)
    {
        Content__c tempContent = new Content__c();
        tempContent.Id = contentId;

        update tempContent;
    }
}