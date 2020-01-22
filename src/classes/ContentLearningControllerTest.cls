/**
 * WMK, LLC (c) - 2018 
 *
 * ContentLearningControllerTest
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
public class ContentLearningControllerTest {

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

        insert new Content_Learning_Objects__c(Name = 'Account', API_Name__c='Account', Enabled__c=true);
        insert new Content_Learning_Objects__c(Name = 'Contact', API_Name__c='Contact', Enabled__c=true);
    }

    public static testMethod void testGetContentListPageName()
    {        
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Content_Object_Field__c  tempObjField = new Content_Object_Field__c ();
        tempObjField.Content__c = tempContent.Id;
        tempObjField.Page_Name__c = 'funnyPage';
        insert tempObjField;

        System.assertNotEquals(null, ContentLearningController.getContentListPageName('funnyPage'));
    }

    public static testMethod void testGetContentListNewRecord()
    {        
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Content_Object_Field__c  tempObjField = new Content_Object_Field__c ();
        tempObjField.Content__c = tempContent.Id;
        tempObjField.Object_Name__c = 'Contact';
        tempObjField.New_Record_Page__c = true;
        insert tempObjField;

        System.assertNotEquals(null, ContentLearningController.getContentListNewRecord('Contact'));
    }

    public static testMethod void testGetContentlist_genericObject()
    {        
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Contact tempContact = new Contact();
        tempContact.FirstName = 'ContentVideoPlayerControllerTest';
        tempContact.LastName = 'Test';
        insert tempContact;

        Content_Object_Field__c  tempObjField = new Content_Object_Field__c ();
        tempObjField.Content__c = tempContent.Id;
        tempObjField.Object_Name__c = 'Contact';
        insert tempObjField;

        System.assertNotEquals(null, ContentLearningController.getContentlist(tempContact.Id));
    }

    public static testMethod void testGetContentlist_equals()
    {        
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Contact tempContact = new Contact();
        tempContact.FirstName = 'ContentVideoPlayerControllerTest';
        tempContact.LastName = 'Test';
        insert tempContact;

        Content_Object_Field__c  tempObjField = new Content_Object_Field__c ();
        tempObjField.Content__c = tempContent.Id;
        tempObjField.Object_Name__c = 'Contact';
        tempObjField.Object_Field_Name__c = 'First Name';
        tempObjField.Operator__c = 'Equals';
        tempObjField.Value__c = 'ContentVideoPlayerControllerTest';
        insert tempObjField;

        System.assertNotEquals(null, ContentLearningController.getContentlist(tempContact.Id));
    }

    public static testMethod void testGetContentlist_not_equals()
    {        
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Contact tempContact = new Contact();
        tempContact.FirstName = 'Happy';
        tempContact.LastName = 'Test';
        insert tempContact;

        Content_Object_Field__c  tempObjField = new Content_Object_Field__c ();
        tempObjField.Content__c = tempContent.Id;
        tempObjField.Object_Name__c = 'Contact';
        tempObjField.Object_Field_Name__c = 'First Name';
        tempObjField.Operator__c = 'Not Equals';
        tempObjField.Value__c = 'ContentVideoPlayerControllerTest';
        insert tempObjField;

        System.assertNotEquals(null, ContentLearningController.getContentlist(tempContact.Id));
    }

    public static testMethod void testGetContentlist_contains()
    {        
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Contact tempContact = new Contact();
        tempContact.FirstName = 'ContentVideoPlayerControllerTest';
        tempContact.LastName = 'Test';
        insert tempContact;

        Content_Object_Field__c  tempObjField = new Content_Object_Field__c ();
        tempObjField.Content__c = tempContent.Id;
        tempObjField.Object_Name__c = 'Contact';
        tempObjField.Object_Field_Name__c = 'First Name';
        tempObjField.Operator__c = 'Contains';
        tempObjField.Value__c = 'Content';
        insert tempObjField;

        System.assertNotEquals(null, ContentLearningController.getContentlist(tempContact.Id));
    }

    public static testMethod void testGetContentlist_greater_than()
    {        
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Account tempAccount = new Account();
        tempAccount.Name='MillerCorp';
        tempAccount.NumberOfEmployees = 1;
        insert tempAccount;

        Content_Object_Field__c  tempObjField = new Content_Object_Field__c ();
        tempObjField.Content__c = tempContent.Id;
        tempObjField.Object_Name__c = 'Account';
        tempObjField.Object_Field_Name__c = 'Employees';
        tempObjField.Operator__c = 'Greater Than';
        tempObjField.Value__c = '0';
        insert tempObjField;

        System.assertNotEquals(null, ContentLearningController.getContentlist(tempAccount.Id));
    }

    public static testMethod void testGetContentlist_less_than()
    {        
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Account tempAccount = new Account();
        tempAccount.Name='MillerCorp';
        tempAccount.NumberOfEmployees = 1;
        insert tempAccount;

        Content_Object_Field__c  tempObjField = new Content_Object_Field__c ();
        tempObjField.Content__c = tempContent.Id;
        tempObjField.Object_Name__c = 'Account';
        tempObjField.Object_Field_Name__c = 'Employees';
        tempObjField.Operator__c = 'Less Than';
        tempObjField.Value__c = '2';
        insert tempObjField;

        System.assertNotEquals(null, ContentLearningController.getContentlist(tempAccount.Id));
    }

    public static testMethod void testGetContentlist_greater_or_equal()
    {        
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Account tempAccount = new Account();
        tempAccount.Name='MillerCorp';
        tempAccount.NumberOfEmployees = 1;
        insert tempAccount;

        Content_Object_Field__c  tempObjField = new Content_Object_Field__c ();
        tempObjField.Content__c = tempContent.Id;
        tempObjField.Object_Name__c = 'Account';
        tempObjField.Object_Field_Name__c = 'Employees';
        tempObjField.Operator__c = 'Greater or Equal';
        tempObjField.Value__c = '1';
        insert tempObjField;

        System.assertNotEquals(null, ContentLearningController.getContentlist(tempAccount.Id));
    }

    public static testMethod void testGetContentlist_less_or_equal()
    {        
        Content__c tempContent = [SELECT Id FROM Content__c LIMIT 1];

        Account tempAccount = new Account();
        tempAccount.Name='MillerCorp';
        tempAccount.NumberOfEmployees = 1;
        insert tempAccount;

        Content_Object_Field__c  tempObjField = new Content_Object_Field__c ();
        tempObjField.Content__c = tempContent.Id;
        tempObjField.Object_Name__c = 'Account';
        tempObjField.Object_Field_Name__c = 'Employees';
        tempObjField.Operator__c = 'Less or Equal';
        tempObjField.Value__c = '1';
        insert tempObjField;

        System.assertNotEquals(null, ContentLearningController.getContentlist(tempAccount.Id));
    }
}