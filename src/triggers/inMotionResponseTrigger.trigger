/**
 * WMK, LLC (c) - 2019 
 *
 * InMotionCampaignQuestionnaireController
 * 
 * Created By:   Alexander Miller
 * Created Date: 2/28/2019 
 * Work Item:    W-000603
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -------------- ---------------------------------------------------
 */ 
trigger inMotionResponseTrigger on In_Motion_Response__c (before insert) {

    if(Trigger.isBefore) 
    {
        if(Trigger.isInsert)
        {
            inMotionResponseTriggerHandler.createCampaignMembers(Trigger.new);
            inMotionResponseTriggerHandler.setAccountNextPurchaseTimeframe(Trigger.new);
            inMotionResponseTriggerHandler.createFollowUpTasks(Trigger.new);
            inMotionResponseTriggerHandler.stickerTaskCreation(Trigger.new); 
        }
    }
}