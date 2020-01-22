/**
 * WMK, LLC (c) - 2018 
 *
 * ContentObjectFieldTrigger
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/8/2018 
 * Tested By:    ContentObjectFieldTriggerHandlerTest
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
trigger ContentObjectFieldTrigger on Content_Object_Field__c (before insert, before update) {

    ContentObjectFieldTriggerHandler tempHandler = new ContentObjectFieldTriggerHandler(); 

    if(Trigger.isBefore)
    {
        if(Trigger.isInsert || Trigger.isUpdate)
        {
            tempHandler.flagIfIdenticalContentObjectFieldExists(Trigger.new);
            tempHandler.getObjectAPINameIfNeeded(Trigger.new);
            tempHandler.getObjectFieldAPINameIfNeeded(Trigger.new);
        }
    }
}