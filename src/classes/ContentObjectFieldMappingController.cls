/**
 * WMK, LLC (c) - 2018 
 *
 * ContentObjectFieldMappingController
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/9/2018 
 * Tested By: ContentObjectFieldMappingControllerTest
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
public with sharing class ContentObjectFieldMappingController {

    @AuraEnabled
	public static List<Content_Object_Field__c> getContentObjectFieldList(Id contentId)
    {
        return ([SELECT Id,
                    Name,
                    Content__c,
                    Object_Field_Name__c,
                    Object_Field_Name_API__c,
                    Object_Name__c, 
                    Object_Name_API__c,
                    Value__c,
                    Operator__c,
                    Page_Name__c,
                    New_Record_Page__c
                FROM Content_Object_Field__c
                WHERE Content__c = :contentId
                ORDER BY Object_Name__c, Object_Field_Name__c DESC]);
    }

    @AuraEnabled
	public static List<String> getObjectNames()
    {
        List<String> listOfTestingObjects = new List<String>();

        Content_Learning_Objects__c tempCustomSetting = Content_Learning_Objects__c.getInstance();

        List<Content_Learning_Objects__c> listOfObjects = Content_Learning_Objects__c.getAll().values();

        for(Content_Learning_Objects__c tempItem : listOfObjects)
        {
            if(tempItem.Enabled__c)
            {
                listOfTestingObjects.add(tempItem.Name);
            }
        }

        listOfTestingObjects.sort();

        System.debug(listOfTestingObjects);

        return listOfTestingObjects;
    }

    @AuraEnabled
	public static List<String> getObjectFieldOperators()
    {
        List<String> listOfOperators = new List<String>();
        
        Schema.DescribeFieldResult fieldResult = Content_Object_Field__c.Operator__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple)
        {
            listOfOperators.add(f.getLabel());
        }       

        return listOfOperators;
    }

    public static String getObjectAPIName(String objectName)
    {
        String apiName = '';

        Content_Learning_Objects__c tempCustomSetting = Content_Learning_Objects__c.getInstance();

        List<Content_Learning_Objects__c> listOfObjects = Content_Learning_Objects__c.getAll().values();

        for(Content_Learning_Objects__c tempItem : listOfObjects)
        {
            if(tempItem.Enabled__c && tempItem.Name == objectName)
            {
                apiName = tempItem.API_Name__c;
                break;
            }
        }

        return apiName;
    }

    @AuraEnabled
	public static List<String> getObjectFields(String objectName)
    {
        // 1. Load the org list
        String apiName = getObjectAPIName(objectName);

        List<String> listOfFields = new List<String>();
        
        System.debug(apiName);

        Schema.DescribeSObjectResult objResult = Schema.getGlobalDescribe().get(apiName).getDescribe();
        String objectName2 = objResult.getName();

        SObjectType accountType = Schema.getGlobalDescribe().get(apiName);

        System.debug(accountType);

        Map<String,Schema.SObjectField> mfields = accountType.getDescribe().fields.getMap();

        System.debug(mfields);

        for(String tempField : mfields.keySet())
        {
            listOfFields.add(mfields.get(tempField).getDescribe().getLabel());
        }
        
        listOfFields.sort();

        return listOfFields;
    }

    @AuraEnabled
	public static void createContentObjectMapping(Id contentId, String objectName, String objectFieldName, String objectOperator, String operatorValue)
    {
        Content_Object_Field__c tempContentObject = new Content_Object_Field__c();
        tempContentObject.Content__c = contentId;
        tempContentObject.Object_Name__c = objectName;
        tempContentObject.Object_Field_Name__c = objectFieldName;
        tempContentObject.Operator__c = objectOperator;
        tempContentObject.Value__c = operatorValue;

        insert tempContentObject;
    }

    @AuraEnabled
	public static void createContentObjectPageMapping(Id contentId, String pageName)
    {
        Content_Object_Field__c tempContentObject = new Content_Object_Field__c();
        tempContentObject.Content__c = contentId;
        tempContentObject.Page_Name__c = pageName;

        System.debug(tempContentObject);

        insert tempContentObject;
    }

    @AuraEnabled
	public static void createContentObjectNewRecordMapping(Id contentId, String objectName)
    {
        Content_Object_Field__c tempContentObject = new Content_Object_Field__c();
        tempContentObject.Content__c = contentId;
        tempContentObject.Object_Name__c = objectName;
        tempContentObject.New_Record_Page__c = true;

        System.debug(tempContentObject);

        insert tempContentObject;
    }

    @AuraEnabled
	public static void deleteContentObjectMapping(List<Content_Object_Field__c> listContentObjectFieldId)
    {
        delete listContentObjectFieldId;
    }
}