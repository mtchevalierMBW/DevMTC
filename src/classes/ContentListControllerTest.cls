/**
 * WMK, LLC (c) - 2018 
 *
 * ContentListControllerTest
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
public class ContentListControllerTest { 

    @testSetup
    public static void testSetup()
    {
        insert new Content_Learning_Objects__c(Name = 'Account', API_Name__c='Account', Enabled__c=true);
        insert new Content_Learning_Objects__c(Name = 'Contact', API_Name__c='Contact', Enabled__c=true);

        Content__c tempContent = new Content__c();
        tempContent.Title__c = 'ContentListControllerTest';
        insert tempContent;
    }

    public static testMethod void testGetContentList()
    {
        Test.startTest();
        System.assertNotEquals(0, ContentListController.getContentList().size());
        Test.stopTest();
    }

    public static testMethod void testGetFilteredContentList()
    {
        Test.startTest();
        ContentListController.getFilteredContentList('ContentListControllerTest').size();
        Test.stopTest();
    }
}