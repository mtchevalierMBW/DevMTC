/**
 * WMK, LLC (c) - 2019 
 *
 * partsKitFavoriteTrigger
 * 
 * Created By:   Alexander Miller
 * Created Date: 03/26/2019
 * Tested By:    partsKitFavoriteTriggerControllerTest
 * Work Item:    W-000582
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
trigger partsKitFavoriteTrigger on Parts_Kit_Favorite__c (before insert, before update) {

    partsKitFavoriteTriggerController tempHandler = new partsKitFavoriteTriggerController(); 

    if(Trigger.isBefore)
    {
        if(Trigger.isInsert || Trigger.isUpdate)
        {
            tempHandler.checkDuplicate(Trigger.new);
        }   
    }
}