/**
 * WMK, LLC (c) - 2018 
 *
 * ContentListController
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/9/2018 
 * Tested By: ContentLearningControllerTest
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date         Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1        IR-0047287    1/28/2019      The logic for "all objects" wasn't pulling the right field
 * Alexander Miller    AMM2        W-000601      2/25/2019      Update to handle changing the Title automatically
 * Alexander Miller    AMM3        W-000578      03/28/2019     Logic to handle profile-sensitive content
 * Alexander Miller    AMM4        IR-0052205    04/04/2019     Logic to bring the last modified Content to the top "newest". Should've been part of the last work item.
 * Alexander Miller    AMM5        IR-0052242    04/04/2019     Logic to exclude Approval Process Items. They break this logic.
 * Alexander Miller    AMM6        W-000644      04/05/2019     Logic to handle counting new Content
 * Alexander Miller    AMM7        IR-0052646    04/12/2019     Addition to help handle record deletions
 */
public with sharing class ContentLearningController {

    public static String operatorEquals = 'Equals';
    public static String operatorNotEquals = 'Not Equals';
    public static String operatorGreatThan = 'Greater Than';
    public static String operatorLessThan = 'Less Than';
    public static String operatorGreaterEqual = 'Greater or Equal';
    public static String operatorLessEqual = 'Less or Equal';
    public static String operatorContains = 'Contains';

    @AuraEnabled
    public static List<Content__c> getContentListPageName(String pageName){

        List<Content_Object_Field__c> listOfMapping = ([SELECT Id,
                                                            Content__c,
                                                            Object_Name_API__c,
                                                            Object_Field_Name_API__c,
                                                            Operator__c,
                                                            Value__c
                                                        FROM Content_Object_Field__c 
                                                        WHERE Page_Name__c = :pageName
                                                        ORDER BY CreatedDate DESC
                                                        LIMIT :((Integer)getCustomSettingVideoLimit())]);

        List<Id> listOfContentIds = new List<Id>();

        for(Content_Object_Field__c tempContent : listOfMapping)
        {
            listOfContentIds.add(tempContent.Content__c);
        }

        // AMM3
        // return ([SELECT Id,
        //             Name,
        //             OwnerId,
        //             Owner.Name,
        //             Group__c,
        //             Title__c,
        //             Description__c,
        //             Sub_Group__c, 
        //             LastModifiedDate
        //         FROM Content__c
        //         WHERE Id IN :listOfContentIds AND
        //             Id IN (SELECT Content__c 
        //                     FROM Media__c 
        //                     WHERE ( Video_URL__c != null AND Video_Id__c = null ) OR
        //                             ( Video_Id__c != null AND Video_URL__c = null ) OR
        //                             ( Video_Id__c != null AND Video_URL__c != null ) )]);

        List<Content__c> listOfContent = ([SELECT Id,
                                            Name,
                                            OwnerId,
                                            Owner.Name,
                                            Group__c,
                                            Title__c,
                                            Description__c,
                                            Sub_Group__c, 
                                            LastModifiedDate
                                        FROM Content__c
                                        WHERE Id IN :listOfContentIds AND
                                            Id IN (SELECT Content__c 
                                                    FROM Media__c 
                                                    WHERE ( Video_URL__c != null AND Video_Id__c = null ) OR
                                                            ( Video_Id__c != null AND Video_URL__c = null ) OR
                                                            ( Video_Id__c != null AND Video_URL__c != null ) )
                                        // AMM4
                                        ORDER BY LastModifiedDate DESC]);
                                        // AMM4

        return getProfileSensitiveContent(listOfContent);

        // AMM3
    }

    @AuraEnabled
    public static List<Content__c> getContentListNewRecord(String objectName){

        System.debug(objectName);

        List<Content_Object_Field__c> listOfMapping = ([SELECT Id,
                                                            Content__c,
                                                            Object_Name_API__c,
                                                            Object_Field_Name_API__c,
                                                            Operator__c,
                                                            Value__c
                                                        FROM Content_Object_Field__c 
                                                        WHERE Object_Name_API__c = :objectName AND
                                                            New_Record_Page__c = TRUE
                                                        ORDER BY CreatedDate DESC
                                                        LIMIT :((Integer)getCustomSettingVideoLimit())]);
        
        List<Id> listOfContentIds = new List<Id>();

        for(Content_Object_Field__c tempContent : listOfMapping)
        {
            listOfContentIds.add(tempContent.Content__c);
        }

        System.debug(listOfContentIds);
        
        // AMM3
        // return ([SELECT Id,
        //             Name,
        //             OwnerId,
        //             Owner.Name,
        //             Group__c,
        //             Title__c,
        //             Description__c,
        //             Sub_Group__c,
        //             LastModifiedDate
        //         FROM Content__c
        //         WHERE Id IN :listOfContentIds AND
        //             Id IN (SELECT Content__c 
        //                     FROM Media__c 
        //                     WHERE ( Video_URL__c != null AND Video_Id__c = null ) OR
        //                             ( Video_Id__c != null AND Video_URL__c = null ) OR
        //                             ( Video_Id__c != null AND Video_URL__c != null ) )]);

        List<Content__c> listOfContent = ([SELECT Id,
                                            Name,
                                            OwnerId,
                                            Owner.Name,
                                            Group__c,
                                            Title__c,
                                            Description__c,
                                            Sub_Group__c,
                                            LastModifiedDate
                                        FROM Content__c
                                        WHERE Id IN :listOfContentIds AND
                                            Id IN (SELECT Content__c 
                                                    FROM Media__c 
                                                    WHERE ( Video_URL__c != null AND Video_Id__c = null ) OR
                                                            ( Video_Id__c != null AND Video_URL__c = null ) OR
                                                            ( Video_Id__c != null AND Video_URL__c != null ) )
                                        // AMM4
                                        ORDER BY LastModifiedDate DESC]);
                                        // AMM4

        return getProfileSensitiveContent(listOfContent);
        // AMM3
    }

    @AuraEnabled
	public static List<Content__c> getContentlist(Id recordId)
    {
        // 1. Get first three characters of Id
        String objectName = recordId.getSObjectType().getDescribe().getName(); 

        System.debug(objectName);

        // AMM5
        if(objectName == 'ProcessInstanceWorkitem')
        {
            return new List<Content__c>();
        }
        // AMM5

        List<String> listOfFields = getListOfFieldsByObject(objectName);

        System.debug(recordId);

        // 2. Get the Content Object Field mapping referenced in the record Id  
        // AMM3
        // List<Content_Object_Field__c> listOfMapping = ([SELECT Id,
        //                                                     Content__c,
        //                                                     Object_Name__c,
        //                                                     Object_Name_API__c,
        //                                                     Object_Field_Name__c,
        //                                                     Object_Field_Name_API__c,
        //                                                     Operator__c,
        //                                                     New_Record_Page__c,
        //                                                     Value__c
        //                                                 FROM Content_Object_Field__c 
        //                                                 WHERE Object_Name_API__c = :objectName AND
        //                                                     Content__c IN (SELECT Content__c 
        //                                                                     FROM Media__c 
        //                                                                     WHERE ( Video_URL__c != null AND Video_Id__c = null ) OR
        //                                                                          ( Video_Id__c != null AND Video_URL__c = null ) OR
        //                                                                          ( Video_Id__c != null AND Video_URL__c != null ) )]);
        
        // Should only have to process mappings of records which are allowed to be viewed in the first place
        
        List<Content__c> profileCleansedContent = new List<Content__c>();

        List<Content_Object_Field__c> pre_mappingList = ([SELECT Id,
                                                            Content__c
                                                        FROM Content_Object_Field__c 
                                                        WHERE Object_Name_API__c = :objectName]);

        for(Content_Object_Field__c tempObjField : pre_mappingList)
        {
            profileCleansedContent.add(new Content__c(Id = tempObjField.Content__c));
        }

        List<Content__c> listOfCleansedProfileContent = getProfileSensitiveContent(profileCleansedContent);

        List<Content_Object_Field__c> listOfMapping = ([SELECT Id,
                                                            Content__c,
                                                            Object_Name__c,
                                                            Object_Name_API__c,
                                                            Object_Field_Name__c,
                                                            Object_Field_Name_API__c,
                                                            Operator__c,
                                                            New_Record_Page__c,
                                                            Value__c
                                                        FROM Content_Object_Field__c 
                                                        WHERE Object_Name_API__c = :objectName AND
                                                            Content__c IN (SELECT Content__c 
                                                                            FROM Media__c 
                                                                            WHERE ( Video_URL__c != null AND Video_Id__c = null ) OR
                                                                                 ( Video_Id__c != null AND Video_URL__c = null ) OR
                                                                                 ( Video_Id__c != null AND Video_URL__c != null ) ) AND
                                                            Content__c IN :listOfCleansedProfileContent]);
        // AMM3

        System.debug(listOfMapping);

        // 3. Get all the field values for evaluation
        sObject recordValues = getRecordValues(listOfFields, objectName, recordId);

        System.debug(recordValues);

        Map<Id, Decimal> mapOfContentGoodness = new Map<Id, Decimal>();

        // 4. Cycle through the list and see if the field values match
        List<Id> listOfContentIds = new List<Id>();
        for(Content_Object_Field__c tempContentObjectField : listOfMapping)
        {
            // its an object reference with no value or field mapping meaning its a generic object match
            if( tempContentObjectField.Object_Name__c != null &&

                    (tempContentObjectField.Object_Field_Name__c == null || 
                    tempContentObjectField.Object_Field_Name__c == '') && 

                    (tempContentObjectField.Operator__c == null || 
                    tempContentObjectField.Operator__c == '') &&

                    (tempContentObjectField.Value__c == null || 
                    tempContentObjectField.Value__c == '') &&

                    tempContentobjectField.New_Record_Page__c == false &&
                    // AMM1 
                    // recordValues.Id.getSObjectType().getDescribe().getName().equalsIgnoreCase(tempContentObjectField.Object_Name__c))
                    recordValues.Id.getSObjectType().getDescribe().getName().equalsIgnoreCase(tempContentObjectField.Object_Name_API__c))
                    // AMM1
            {
                mapOfContentGoodness = updateMapGoodnessFieldMatch(tempContentObjectField.Content__c, mapOfContentGoodness);
            } else if(tempContentObjectField.Object_Field_Name_API__c != null && 
                recordValues.get((String) tempContentObjectField.Object_Field_Name_API__c) != null)
            {
                // Equals
                if(tempContentObjectField.Operator__c == operatorEquals &&
                    isEqual(recordValues, tempContentObjectField, (String) tempContentObjectField.Object_Field_Name_API__c))
                {
                    mapOfContentGoodness = updateMapGoodnessFieldMatch(tempContentObjectField.Content__c, mapOfContentGoodness);
                } 

                // Not Equals
                else if(tempContentObjectField.Operator__c == operatorNotEquals &&
                    isNotEqual(recordValues, tempContentObjectField, (String) tempContentObjectField.Object_Field_Name_API__c))
                {
                    mapOfContentGoodness = updateMapGoodnessFieldMatch(tempContentObjectField.Content__c, mapOfContentGoodness);
                } 

                // Is Greater
                else if(tempContentObjectField.Operator__c == operatorGreatThan &&
                    isGreaterThan(recordValues, tempContentObjectField, (String) tempContentObjectField.Object_Field_Name_API__c))
                {
                    mapOfContentGoodness = updateMapGoodnessFieldMatch(tempContentObjectField.Content__c, mapOfContentGoodness);
                } 
                
                // Is Less
                else if(tempContentObjectField.Operator__c == operatorLessThan &&
                    isLessThan(recordValues, tempContentObjectField, (String) tempContentObjectField.Object_Field_Name_API__c))
                {
                    mapOfContentGoodness = updateMapGoodnessFieldMatch(tempContentObjectField.Content__c, mapOfContentGoodness);
                } 

                // Is Greater or Equal
                else if(tempContentObjectField.Operator__c == operatorGreaterEqual &&
                    isGreaterOrEqual(recordValues, tempContentObjectField, (String) tempContentObjectField.Object_Field_Name_API__c))
                {
                    mapOfContentGoodness = updateMapGoodnessFieldMatch(tempContentObjectField.Content__c, mapOfContentGoodness);
                } 

                // Is Less or Equal
                else if(tempContentObjectField.Operator__c == operatorLessEqual &&
                    isLessOrEqual(recordValues, tempContentObjectField, (String) tempContentObjectField.Object_Field_Name_API__c))
                {
                    mapOfContentGoodness = updateMapGoodnessFieldMatch(tempContentObjectField.Content__c, mapOfContentGoodness);
                } 

                // Contains
                else if(tempContentObjectField.Operator__c == operatorContains &&
                    doesContains(recordValues, tempContentObjectField, (String) tempContentObjectField.Object_Field_Name_API__c))
                {
                    mapOfContentGoodness = updateMapGoodnessFieldMatch(tempContentObjectField.Content__c, mapOfContentGoodness);
                } 
            }
        }

        // 5. Sort the "goodness" while keeping the minimum threshold in mind

        System.debug(mapOfContentGoodness);

        List<ContentLearningWrapper> listOfContentWrapper = new List<ContentLearningWrapper>();

        Map<Id, Content__c> listOfContentLastModified = new Map<Id, Content__c>([SELECT Id,
                                                                                    LastModifiedDate
                                                                                FROM Content__c
                                                                                WHERE Id IN :mapOfContentGoodness.keySet()
                                                                                // AMM4
                                                                                ORDER BY LastModifiedDate DESC]);
                                                                                // AMM4]);

        for(Id tempId : mapOfContentGoodness.keySet() )
        {
            listOfContentWrapper.add(new ContentLearningWrapper(new Content__c(Id = tempId, 
                                                                                LastModifiedDate = listOfContentLastModified.get(tempId).LastModifiedDate
                                                                ), 
                                                                mapOfContentGoodness.get(tempId)));
        }

        listOfContentWrapper.sort(); 

        listOfContentWrapper = getTrimmedList(listOfContentWrapper);

        listOfContentWrapper = getDoublySortedList(listOfContentWrapper);

        // 6. Fill in the datapoints to be returned
        for(Integer i = 0; i < listOfContentWrapper.size(); i++)
        {
            listOfContentIds.add(listOfContentWrapper.get(i).content.Id);
        }

        System.debug(listOfContentIds);

        Map<Id, Content__c> mapOfContent = new Map<Id, Content__c>([SELECT Id,
                                                                        Name,
                                                                        OwnerId,
                                                                        Owner.Name,
                                                                        Group__c,
                                                                        Title__c,
                                                                        Description__c,
                                                                        Sub_Group__c,
                                                                        LastModifiedDate
                                                                    FROM Content__c
                                                                    WHERE Id IN :listOfContentIds]);

        List<Content__c> sortedWeightedContentList = new List<Content__c>();

        for(Integer i = 0; i < listOfContentWrapper.size(); i++)
        {
            sortedWeightedContentList.add(mapOfContent.get(listOfContentWrapper.get(i).content.Id));
        }

        System.debug(sortedWeightedContentList);

        return sortedWeightedContentList;
    }

    // AMM2
    /** 
    * getNewContentCount 
    * 
    * Function which looks at the Content Record and 
    * Media record to see the last modified to see 
    * if it falls in the "New" content threshhold
    *
    * @listOfContent - List<Content__c> evaulauted list to be returned eventually
    */
    @AuraEnabled
    public static Integer getNewContentCount(List<Content__c> listOfContent) 
    {
        Integer count = 0;
        
        // AMM6
        Id currentUserId = UserInfo.getUserId();
        List<Content_View__c> listOfContentViews = ([SELECT Id,
                                                        CreatedDate,
                                                        Content__c
                                                    FROM Content_View__c 
                                                    WHERE Content__c IN :listOfContent AND 
                                                        User__c = :currentUserId]);
        
        Map<Id, List<Content_View__c>> mapOfViewsByContent = new Map<Id, List<Content_View__c>>();
        
        for(Content_View__c tempContentView : listOfContentViews)
        {
            if(mapOfViewsByContent.get(tempContentView.Content__c) == null)
            {
                List<Content_View__c> listOfContentRetrieved = new List<Content_View__c>();

                listOfContentRetrieved.add(tempContentView);

                mapOfViewsByContent.put(tempContentView.Content__c, listOfContentRetrieved);
            }   
            else
            {
                List<Content_View__c> listOfContentRetrieved = mapOfViewsByContent.get(tempContentView.Content__c);

                listOfContentRetrieved.add(tempContentView);

                mapOfViewsByContent.put(tempContentView.Content__c, listOfContentRetrieved);
            }
        }   
        // AMM6

        for(Content__c tempContent : listOfContent)
        {
            Decimal daysLimit = getCustomSettingNewContentDayLimit();
            daysLimit = daysLimit * -1;
            Date dateParam = System.Today();
            dateParam = dateParam.addDays(Integer.valueOf(daysLimit));

            // AMM6
            DateTime lastViewDate;

            if(mapOfViewsByContent.get(tempContent.Id) != null)
            {
                for(Content_View__c tempView : mapOfViewsByContent.get(tempContent.Id))
                {
                    if(lastViewDate == null || tempView.CreatedDate >= lastViewDate)
                    {
                        lastViewDate = tempView.CreatedDate;
                    }
                }
            }
            // AMM6

            // AMM6
            // if(tempContent.LastModifiedDate >= dateParam)
            if(tempContent.LastModifiedDate >= dateParam && (lastViewDate == null || tempContent.LastModifiedDate >= lastViewDate))
            // AMM6
            {
                count++;
            }
        }

        return count;
    }
    // AMM2

    // AMM3
    /**
    * getProfileSensitiveContent
    *
    * Function which takes the user's profile and 
    * figures out if certain Content should be removed
    * from their view. 
    * - If no restriction is found, all Content is shown. 
    * - If some restriction is found, only those matching Content records are shown.
    *
    * @param List<Content__c> - List of content being evaluated
    * @return List<Content__c> - Cleansed list based on results found from Content_Profile__c
    */
    public static List<Content__c> getProfileSensitiveContent(List<Content__c> listOfContent)
    {
        List<Content__c> returningList = new List<Content__c>();

        // 1. Get the running user's profile
        id currentUserProfileId = userinfo.getProfileId();

        // 2. compile Content Ids into list
        List<Id> listOfContentIds = new List<Id>();

        for(Content__c tempContent : listOfContent)
        {
            listOfContentIds.add(tempContent.Id);
        }

        // 3. Query the related profile restrictions by Content Ids
        List<Content_Profile__c> listOfContentProfiles = ([SELECT Id,
                                                            Name,
                                                            Content__c,
                                                            Profile_Id__c,
                                                            Profile_Name__c,
                                                            CreatedById,
                                                            LastModifiedById
                                                        FROM Content_Profile__c
                                                        WHERE Content__c IN :listOfContentIds]);

        // 4. Map Content Profiles to Content Ids for simpler processing
        Map<Id, List<Content_Profile__c>> mapOfContentProfilesByContent = new Map<Id, List<Content_Profile__c>>();

        for(Content_Profile__c tempContentProfile : listOfContentProfiles)
        {
            if(mapOfContentProfilesByContent.get(tempContentProfile.Content__c) == null)
            {
                List<Content_Profile__c> tempList = new List<Content_Profile__c>();

                tempList.add(tempContentProfile); 

                mapOfContentProfilesByContent.put(tempContentProfile.Content__c, tempList);
            }
            else 
            {   
                List<Content_Profile__c> tempList = mapOfContentProfilesByContent.get(tempContentProfile.Content__c);

                tempList.add(tempContentProfile);

                mapOfContentProfilesByContent.put(tempContentProfile.Content__c, tempList);
            }
        }

        // 5. If content does not have any restrictions, allow all. If restriction is found, remove all except the specific Content
        for(Content__c tempContent : listOfContent)
        {
            // No mappings
            if(mapOfContentProfilesByContent.get(tempContent.Id) == null)
            {
                returningList.add(tempContent);
            }
            // Mappings found
            else
            {
                for(Content_Profile__c tempContentProfile : mapOfContentProfilesByContent.get(tempContent.Id))
                {
                    if(tempContentProfile.Profile_Id__c == currentUserProfileId)
                    {
                        returningList.add(tempContent);
                    }
                }
            }
        }

        return returningList;
    }
    // AMM3

    /**
    * getDoublySortedList
    * 
    * Function which takes the list of Content learning records
    * and sorts them in the following way.
    *
    * Record #1: Weight .20, Modified 10 days ago
    * Record #2: Weight .30, Modified 11 days ago
    * Record #3: Weight .25, Modified 35 days ago
    * Record #4: Weight .20, Modified 1 day ago
    * Record #5: Weight .10, Modified 40 day ago
    *
    *   "NEW CONTENT"       |     "OLD CONTENT"
    *     ______________________________
    *   [   #2 |  #4 |  #1  |  #3 | #5  ]
    *   ---------------------------------
    *
    * There is an implicit "first section" of the array which is dedicated to anything 
    * modified in the last 30 days. This is considered new content. The parameter list should already 
    * be sorted by weight but needs moved around once more to handle date modifications.
    */
    public static List<ContentLearningWrapper> getDoublySortedList(List<ContentLearningWrapper> tempList)
    {
        // 1. Set up the date backtracking
        Decimal daysLimit = getCustomSettingNewContentDayLimit();
        daysLimit = daysLimit * -1;
        Date dateParam = System.Today();
        dateParam = dateParam.addDays(Integer.valueOf(daysLimit));

        List<ContentLearningWrapper> listToReturn = new List<ContentLearningWrapper>();

        // 2. get the list of content within the threshold day limit
        List<ContentLearningWrapper> listOfContentWithinThreshold = new List<ContentLearningWrapper>();

        for(ContentLearningWrapper tempWrapper : tempList)
        {
            if(tempWrapper.content.LastModifiedDate >= dateParam)
            {
                listOfContentWithinThreshold.add(tempWrapper);
            }
        }

        // 3. cycle through the rest with their current order by weight and add them to the tail
        List<ContentLearningWrapper> listOfContentOutsideThreshold = new List<ContentLearningWrapper>();

        for(ContentLearningWrapper tempWrapper : tempList)
        {
            if(tempWrapper.content.LastModifiedDate < dateParam)
            {
                listOfContentOutsideThreshold.add(tempWrapper);
            }
        }

        // 4. Combine the lists in Order
        for(ContentLearningWrapper tempWrapper : listOfContentWithinThreshold)
        {
            listToReturn.add(tempWrapper);
        }

        for(ContentLearningWrapper tempWrapper : listOfContentOutsideThreshold)
        {
            listToReturn.add(tempWrapper);
        }

        return listToReturn;
    }

    /**
    * getTrimmedList
    *
    * Function which gets the maximum number of videos to be displayed on the Utiltiy Bar
    */
    public static List<ContentLearningWrapper> getTrimmedList(List<ContentLearningWrapper> tempList)
    {

        List<ContentLearningWrapper> listOfContentRecordsToRemove = new List<ContentLearningWrapper>();

        // Clear out any below the threshold immediately
        for(ContentLearningWrapper tempWrapper : tempList)
        {
            if(tempWrapper.getWeight() < getCustomSettingThreshold())
            {   
                listOfContentRecordsToRemove.add(tempWrapper);
            }
        }

        for(ContentLearningWrapper tempWrapper : listOfContentRecordsToRemove)
        {
            tempList.remove(tempList.indexOf(tempWrapper));
        }

        // Check if list size is correct
        if(getCustomSettingVideoLimit() >= tempList.size())
        {

            return tempList;
        }
        else 
        {
            List<ContentLearningWrapper> mList = tempList;

            while(mList.size() > getCustomSettingVideoLimit())
            {
                mList.remove(mList.size()-1);
            }

            return mList;
        }
    }
    
    /**
    * updateMapGoodnessFieldMatch
    *
    * modular function for recording which 
    * content mapping has the most "goodness"
    */
    public static Map<Id, Decimal> updateMapGoodnessFieldMatch(Id recordId, Map<Id, Decimal> mapParam)
    {
        if(mapParam.get(recordId) == null)
        {
            mapParam.put(recordId, getCustomSettingObjectFieldMatchVal());
        }
        else 
        {
           Decimal tempVal = mapParam.get(recordId);

           tempVal = tempVal + getCustomSettingObjectFieldMatchVal();

           mapParam.put(recordId, tempVal);
        }

        return mapParam;
    }

    public static Decimal getCustomSettingObjectFieldMatchVal()
    {
        MobilityForceSettings__c customSettingValue = MobilityForceSettings__c.getInstance(); 

        if (customSettingValue == null || customSettingValue.Content_Learning_Weight_ObjField_Match__c == null) 
        {
            return 0.0;
        }
        else 
        {
            return customSettingValue.Content_Learning_Weight_ObjField_Match__c;
        }
    }

    public static Decimal getCustomSettingVideoLimit() 
    {
        MobilityForceSettings__c customSettingValue = MobilityForceSettings__c.getInstance();

        if (customSettingValue == null || customSettingValue.Content_Learning_Video_Limit__c == null) 
        {
            return 0.0;
        }
        else 
        {
            return customSettingValue.Content_Learning_Video_Limit__c;
        }
    }

    public static Decimal getCustomSettingThreshold()
    {
        MobilityForceSettings__c customSettingValue = MobilityForceSettings__c.getInstance();

        if (customSettingValue == null || customSettingValue.Content_Learning_Threshold__c == null) 
        {
            return 0.0;
        }
        else 
        {
            return customSettingValue.Content_Learning_Threshold__c;
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

    public static Boolean isEqual(sObject recordObject, Content_Object_Field__c contentFieldObject, String fieldName)
    {
        if(String.valueOf(recordObject.get((String) contentFieldObject.Object_Field_Name_API__c)).equalsIgnoreCase(contentFieldObject.Value__c))
        {
            return true;
        }
        else {
            return false;
        }
    }

    public static Boolean isNotEqual(sObject recordObject, Content_Object_Field__c contentFieldObject, String fieldName)
    {
        if(! String.valueOf(recordObject.get((String) contentFieldObject.Object_Field_Name_API__c)).equalsIgnoreCase(contentFieldObject.Value__c))
        {
            return true;
        }
        else {
            return false;
        }
    }

    public static Boolean isGreaterThan(sObject recordObject, Content_Object_Field__c contentFieldObject, String fieldName)
    {
        Integer recordValue = Integer.valueOf(recordObject.get((String) contentFieldObject.Object_Field_Name_API__c));

        if(recordValue > Integer.valueOf(contentFieldObject.Value__c))
        {
            return true;
        }
        else {
            return false;
        }
    }

    public static Boolean isLessThan(sObject recordObject, Content_Object_Field__c contentFieldObject, String fieldName)
    {
        Integer recordValue = Integer.valueOf(recordObject.get((String) contentFieldObject.Object_Field_Name_API__c));

        if(recordValue < Integer.valueOf(contentFieldObject.Value__c))
        {
            return true;
        }
        else {
            return false;
        }
    }

    public static Boolean isGreaterOrEqual(sObject recordObject, Content_Object_Field__c contentFieldObject, String fieldName)
    {
        Integer recordValue = Integer.valueOf(recordObject.get((String) contentFieldObject.Object_Field_Name_API__c));

        if(recordValue >= Integer.valueOf(contentFieldObject.Value__c))
        {
            return true;
        }
        else {
            return false;
        }
    }

    public static Boolean isLessOrEqual(sObject recordObject, Content_Object_Field__c contentFieldObject, String fieldName)
    {
        Integer recordValue = Integer.valueOf(recordObject.get((String) contentFieldObject.Object_Field_Name_API__c));

        if(recordValue <= Integer.valueOf(contentFieldObject.Value__c))
        {
            return true;
        }
        else {
            return false;
        }
    }

    public static Boolean doesContains(sObject recordObject, Content_Object_Field__c contentFieldObject, String fieldName)
    {
        String recordValue = String.valueOf(recordObject.get((String) contentFieldObject.Object_Field_Name_API__c)).toLowerCase();

        String objVal = contentFieldObject.Value__c.toLowerCase();

        if(recordValue.contains(contentFieldObject.Value__c))
        {
            return true;
        }
        else {
            return false;
        }
    }

    /**
    * getListOfFieldsByObject
    *
    * Function which looks at the current setup of an object and 
    * returns the field API names
    */
    public static List<String> getListOfFieldsByObject(String objectName)
    {
        Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();

        List<String> listOfFields = new List<String>();

        for(String tempField : objectFields.keySet())
        {
            listOfFields.add(tempField);
        }

        return listOfFields;
    }

    /**
    * getRecordValues
    *
    * Function which dynamically queries the database
    * for all values of a given object by Record Id
    */
    public static sObject getRecordValues(List<String> listOfFields, String objectName, Id recordId)
    {
        String query = 'SELECT '+ String.join(listOfFields, ',') + ' FROM ' + objectName + ' WHERE Id = ' + '\'' + recordId + '\'';

        System.debug(query);
        
        // AMM7
       	//sObject tempRecord = Database.query(query);
        // return tempRecord;
       	List<sObject> tempRecords = Database.query(query);
        
        if(tempRecords.size() > 0)
        {
            return tempRecords.get(0);
		}
        else
        {
            return null;
        }
        // AMM7
    }

    public class ContentLearningWrapper implements Comparable{

        public Content__c content {get;set;}

        public Decimal weight {get;set;}

        public ContentLearningWrapper(){}

        public ContentLearningWrapper(Content__c tempCon, Decimal tempWeight)
        {
            this.content = tempCon;
            this.weight = tempWeight;
        }

        public Integer compareTo(Object c1) {
            ContentLearningWrapper compareTo = (ContentLearningWrapper) c1;

            if(weight < compareTo.getWeight())
            {
                return 1;
            }
            else if(weight == compareTo.getWeight())
            {
                return 0;
            }
            else 
            {
               return -1;
            }
        }

        public Decimal getWeight()
        {
            return this.weight;
        }
    }
}