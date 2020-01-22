/**
 * WMK, LLC (c) - 2018 
 *
 * ContentTagTriggerHandler
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/8/2018 
 * Tested By:    ContentTagTriggerHandlerTest
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
public class ContentTagTriggerHandler {

    public ContentTagTriggerHandler(){}

    /**
    * flagIfIdenticalContentTagsExists
    *
    * Function which flags the trigger context if the 
    * record is identical to another record in the system
    * in the following way:
    *
    * - Id
    * - Content
    * - Tag
    */
    public void flagIfIdenticalContentTagsExists(List<Content_Tag__c> tempList)
    {
        List<Content_Tag__c> listOfCurrentTags = new List<Content_Tag__c>([SELECT Id,
                                                                            Content__c,
                                                                            Tag__c
                                                                            FROM Content_Tag__c]);

        for(Content_Tag__c tempTag : tempList)
        {
            for(Content_Tag__c currentTag : listOfCurrentTags)
            {
                if((tempTag.Id == null || currentTag.Id != tempTag.Id) &&
                    (tempTag.Content__c == currentTag.Content__c) &&
                    (tempTag.Tag__c == currentTag.Tag__c) )
                {
                    tempTag.addError('This Content Tag is identical to another one: ' + tempTag.Id + ' Name: ' + tempTag.Name + ' and is therefore not allowed.');
                }
            }
        } 
    }
}