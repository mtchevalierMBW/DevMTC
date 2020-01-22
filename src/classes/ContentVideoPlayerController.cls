/**
 * WMK, LLC (c) - 2018 
 *
 * ContentVideoPlayerController
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/15/2018 
 * Tested By: ContentVideoPlayerControllerTest
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1        W-000607      2/28/2019   Recording when a user views a Content record
 * Alexander Miller    AMM2        W-000644      04/05/2019  Logic to prevent the "New" icon from showing up if its already been viewed by the user
 */
public with sharing class ContentVideoPlayerController {

    @AuraEnabled
    public static String getVideoId(Id contentId){
        
        // 1. Get the Media tied to the content
        Media__c tempMedia = [SELECT Id, 
                                Video_URL__c 
                            FROM Media__c 
                            WHERE Content__c = :contentId];

        if(tempMedia.Video_URL__c != null && !String.isEmpty(tempMedia.Video_URL__c))
        {
            return tempMedia.Video_URL__c;
        }

        // 2. Get the ContentDocument tied to the Media
        LightningFileUtility tempUtility = new LightningFileUtility();
        List<ContentDocument> listOfContentDocuments = tempUtility.getContentDocumentsByParentId(tempMedia.Id);

        // 3. Get the ContentVersion tied to the ContentDocument
        ContentVersion tempVersion = [SELECT Id, 
                                        CreatedDate,
                                        FileType,
                                        ContentDocumentId
                                    FROM ContentVersion 
                                    WHERE ContentDocumentId = :listOfContentDocuments.get(0).Id
                                    ORDER BY CreatedDate DESC 
                                    LIMIT 1];

        return String.valueOf(tempVersion.Id) + ';' + String.valueOf(tempVersion.ContentDocumentId);
    }

    @AuraEnabled
    public static Media__c getMediaRecord(Id contentId){
        
        return [SELECT Id, 
                    Name,
                    Content__c,
                    Description__c,
                    Duration__c,
                    Title__c,
                    Video_Id__c,
                    Video_URL__c,
                    Media_Type__c
                FROM Media__c 
                WHERE Content__c = :contentId];
    }

    // AMM1
    @AuraEnabled
    public static void recordContentView(Id ContentId)
    {
        Content_View__c tempView = new Content_View__c();
        tempView.User__c = UserInfo.getUserId();
        tempView.Content__c = ContentId;

        insert tempView;
    }
    // AMM1

    @AuraEnabled
    public static Boolean isContentNew(Id contentId)
    {
        // 1. Build the cutoff date
        Decimal daysLimit = getCustomSettingNewContentDayLimit();
        daysLimit = daysLimit * -1;
        Date dateParam = System.Today();
        dateParam = dateParam.addDays(Integer.valueOf(daysLimit));

        // 2. Get the record
        Content__c tempContent = [SELECT Id,
                                    LastModifiedDate
                                FROM Content__c 
                                WHERE Id = :contentId];
        
        // AMM2
        Id currentUserId = UserInfo.getUserId();
        List<Content_View__c> listOfContentViews = ([SELECT Id,
                                                        CreatedDate
                                                    FROM Content_View__c 
                                                    WHERE Content__c = :contentId AND 
                                                        User__c = :currentUserId]);
        
        DateTime lastViewDate;

        if(listOfContentViews.size() > 0)
        {
            for(Content_View__c tempView : listOfContentViews)
            {
                if(lastViewDate == null || tempView.CreatedDate >= lastViewDate)
                {
                    lastViewDate = tempView.CreatedDate;
                }
            }
        }

        // AMM2

        // 3. Compare and return
        // AMM2
        //if(tempContent.LastModifiedDate >= dateParam)
        if(tempContent.LastModifiedDate >= dateParam && (lastViewDate == null || tempContent.LastModifiedDate >= lastViewDate))
        // AMM2
        {
            return true;
        }    
        else 
        {
            return false;
        }
    }

    public static Decimal getCustomSettingNewContentDayLimit()
    {
        MobilityForceSettings__c customSettingValue = MobilityForceSettings__c.getInstance();

        if (customSettingValue == null || customSettingValue.Content_Learning_New_Content_Day_Limit__c == null) 
        {
            return 0.0;
        }
        else 
        {
            return customSettingValue.Content_Learning_New_Content_Day_Limit__c;
        }
    }
}