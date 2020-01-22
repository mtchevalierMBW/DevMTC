/**
 * WMK, LLC (c) - 2018 
 *
 * ContentObjectFieldTriggerHandlerTest
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/8/2018 
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 */
@isTest
public class ContentObjectFieldTriggerHandlerTest {
    
    @testSetup
    public static void setup()
    {
        Content__c tempContent = new Content__c();
        tempContent.Title__c = 'Testing';
        insert tempContent;

        insert new Content_Learning_Objects__c(Name = 'Account', API_Name__c='Account', Enabled__c=true);
        insert new Content_Learning_Objects__c(Name = 'Contact', API_Name__c='Contact', Enabled__c=true);

        Content_Object_Field__c tempObjField = new Content_Object_Field__c();
        tempObjField.Content__c = tempContent.Id;
        tempObjField.Object_Name__c = 'Account';
        tempObjField.Object_Field_Name__c = 'Employee';
        tempObjField.Operator__c = 'Equals';
        tempObjField.Value__c = 'Test';
        insert tempObjField;        
    }

    public static testMethod void testDuplicateTagInsert()
    {
        Test.StartTest();

        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Content_Object_Field__c tempObjField = new Content_Object_Field__c();
        tempObjField.Content__c = tempContent.Id;
        tempObjField.Object_Name__c = 'Account';
        tempObjField.Object_Field_Name__c = 'Employee';
        tempObjField.Operator__c = 'Equals';
        tempObjField.Value__c = 'Test';
        
        try{
            insert tempObjField;
        } catch(Exception e)
        {
            System.assert(e.getMessage().contains('This Content Object Field is identical to another one'));
        }

        Test.StopTest();
    }

    public static testMethod void testDuplicateTagUpdate()
    {
        Test.StartTest();

        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Content_Object_Field__c tempObjField = new Content_Object_Field__c();
        tempObjField.Content__c = tempContent.Id;
        tempObjField.Object_Name__c = 'Account';
        tempObjField.Object_Field_Name__c = 'Employee';
        tempObjField.Operator__c = 'Equals';
        tempObjField.Value__c = 'Test1';
        insert tempObjField;

        tempObjField.Value__c = 'Test';

        try{
            update tempObjField;    
        } catch(Exception e)
        {
            System.assert(e.getMessage().contains('This Content Object Field is identical to another one'));
        }

        Test.StopTest();
    }

    public static testMethod void testGetObjectAPINameIfNeededFail()
    {
        Test.StartTest();

        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Content_Object_Field__c tempObjField = new Content_Object_Field__c();
        tempObjField.Content__c = tempContent.Id;
        tempObjField.Object_Name__c = 'TestObject123';
        
        try{
            insert tempObjField;    
        } catch(Exception e)
        {
            System.assert(e.getMessage().contains('Could not find the API name for'));
        }

        Test.StopTest();
    }

    public static testMethod void testGetObjectFieldAPINameIfNeeded()
    {
        Test.StartTest();

        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Content_Object_Field__c tempObjField = new Content_Object_Field__c();
        tempObjField.Content__c = tempContent.Id;
        tempObjField.Object_Name__c = 'Chassis Master';
        tempObjField.Object_Field_Name__c = 'Make';
        tempObjField.Operator__c = 'Equals';
        tempObjField.Value__c = 'Test1';
        
        try{
            insert tempObjField;    
        } catch(Exception e)
        {
            System.assert(e.getMessage().contains('Could not find the API name for'));
        }

        Test.StopTest();
    }

    public static testMethod void testGetObjectFieldAPINameIfNeededFail()
    {
        Test.StartTest();

        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Content_Object_Field__c tempObjField = new Content_Object_Field__c();
        tempObjField.Content__c = tempContent.Id;
        tempObjField.Object_Name__c = 'Chassis Master';
        tempObjField.Object_Field_Name__c = 'Make';
        tempObjField.Operator__c = 'Equals';
        tempObjField.Value__c = 'Test1';
        
        try{
            insert tempObjField;    
        } catch(Exception e)
        {
            System.assert(e.getMessage().contains('Could not find the API name for'));
        }

        Test.StopTest();
    }
}