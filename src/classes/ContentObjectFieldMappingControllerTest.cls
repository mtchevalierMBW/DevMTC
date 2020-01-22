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
public class ContentObjectFieldMappingControllerTest {

    @testSetup
    public static void testSetup()
    {
        Content__c tempContent = new Content__c();
        tempContent.Title__c = 'ContentObjectFieldMappingController';
        insert tempContent;
        
        Media__c tempMedia = new Media__c();
        tempMedia.Content__c = tempContent.Id;
        tempMedia.Title__c = 'ContentObjectFieldMappingController';
        insert tempMedia;

        insert new Content_Learning_Objects__c(Name = 'Account', API_Name__c='Account', Enabled__c=true);
        insert new Content_Learning_Objects__c(Name = 'Contact', API_Name__c='Contact', Enabled__c=true);
    }

    public static testMethod void testGetContentObjectFieldList()
    {
        Content__c tempContent = [SELECT Id 
                                  FROM Content__c 
                                  LIMIT 1];

        Content_Object_Field__c tempObjField = new Content_Object_Field__c();   
        tempObjField.Content__c = tempContent.Id;
        tempObjField.New_Record_Page__c = true;
        insert tempObjField;
        
        System.assertNotEquals(null, ContentObjectFieldMappingController.getContentObjectFieldList(tempContent.Id));
    }

    public static testMethod void testGetObjectNames()
    {
        ContentObjectFieldMappingController.getObjectNames();
    }

    public static testMethod void testGetObjectFieldOperators()
    {
        ContentObjectFieldMappingController.getObjectFieldOperators();
    }

    public static testMethod void testGetObjectAPIName()
    {
        System.assertNotEquals(null, ContentObjectFieldMappingController.getObjectAPIName('Account'));
    }

    public static testMethod void testGetObjectFields()
    {
        System.assertNotEquals(null, ContentObjectFieldMappingController.getObjectFields('Contact'));
    }

    public static testMethod void testCreateContentObjectMapping()
    {
         Content__c tempContent = [SELECT Id 
                                  FROM Content__c 
                                  LIMIT 1];

        ContentObjectFieldMappingController.createContentObjectMapping(tempContent.Id, 'Account', null, null, null);
    }

    public static testMethod void testCreateContentObjectPageMapping()
    {
        Content__c tempContent = [SELECT Id 
                                  FROM Content__c 
                                  LIMIT 1];

        ContentObjectFieldMappingController.createContentObjectPageMapping(tempContent.Id, 'funnypage');
    }

    public static testMethod void testCreateContentObjectNewRecordMapping()
    {
        Content__c tempContent = [SELECT Id 
                                  FROM Content__c 
                                  LIMIT 1];

        ContentObjectFieldMappingController.createContentObjectNewRecordMapping(tempContent.Id, 'Account');
    }

    public static testMethod void testDeleteContentObjectMapping()
    {
        Content__c tempContent = [SELECT Id 
                                  FROM Content__c 
                                  LIMIT 1];

        ContentObjectFieldMappingController.createContentObjectNewRecordMapping(tempContent.Id, 'Account');

        ContentObjectFieldMappingController.deleteContentObjectMapping(([SELECT Id FROM Content_Object_Field__c LIMIT 1]));
    }
}