/**
 * WMK, LLC (c) - 2018 
 *
 * ChassisMasterTrigger
 * 
 * Created By:   Alexander Miller
 * Created Date: 10/29/2018 
 * Tested By:    ChassisMasterTriggerHandlerTest
 * Work Item:    W-000464
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1        IR-0044212   11/19/2018  Disabling this functionality for a moment in Production. Can't reproduce in sandbox.
 */
trigger ChassisMasterTrigger on Chassis_Master__c (before update) {

    ChassisMasterTriggerHandler tempHandler = new ChassisMasterTriggerHandler();

    if(Trigger.isBefore)
    {
        if(Trigger.isUpdate)
        {
            tempHandler.opportunityAllocationRollup(Trigger.new);
            tempHandler.updateMaps();
        }
    }
}