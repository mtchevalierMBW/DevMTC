/**
 * WMK, LLC (c) - 2019 
 *
 * EventTrigger
 * 
 * Created By:   Alexander Miller
 * Created Date: 1/31/2019 
 * Tested By: EventTriggerHandlerTest
 * Work Item:    W-000571
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
trigger EventTrigger on Event (before insert, before update) {

    EventTriggerHandler tempHandler = new EventTriggerHandler();

    if(Trigger.isBefore)
    {
        if(Trigger.isInsert || Trigger.isUpdate)
        {
            tempHandler.setAccountField(Trigger.new); 
        }
    }
}