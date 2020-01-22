/**
 * WMK, LLC (c) - 2018 
 *
 * ContentTagTrigger
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
trigger ContentTagTrigger on Content_Tag__c (before insert, before update) {

    ContentTagTriggerHandler tempHandler = new ContentTagTriggerHandler();

    if(Trigger.isBefore)
    {
        if(Trigger.isInsert || Trigger.isUpdate)
        {
            tempHandler.flagIfIdenticalContentTagsExists(Trigger.new);
        }
    }
}