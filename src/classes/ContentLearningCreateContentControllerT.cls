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
public class ContentLearningCreateContentControllerT {

    @testSetup
    public static void testSetup(){}

    public static testMethod void testCreateContentRecord()
    {        
        System.assertNotEquals(null, ContentLearningCreateContentController.createContentRecord('ContentLearningCreateContentControllerT', ''));
    }

    public static testMethod void testCreateMediaChildRecord()
    {   
        Content__c tempContent = ContentLearningCreateContentController.createContentRecord('ContentLearningCreateContentControllerT', '');    

        ContentLearningCreateContentController.createMediaChildRecord(tempContent.Id, 'ContentLearningCreateContentControllerT');
    }
}