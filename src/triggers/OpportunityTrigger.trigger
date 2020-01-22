/**
* TransitWorks (c) - 2018
* 
* OpportunityTrigger
* 
* CreatedBy: Alexander Miller
* CreatedDate: 9-21-2018
* Tested By:
* Work Item: W-000361
*
* Primary trigger to handle the custom TransitWorks Opportunity Object
*
* Alexander Miller - AMILLER1 - W-000449 - Update to copy the Account reference to the custom Opp
*/
trigger OpportunityTrigger on Opportunity__c (before insert, before update, after insert) {

    OpportunityTriggerHandlerCustom controller = new OpportunityTriggerHandlerCustom();

    if(Trigger.isBefore)
    {
        if(Trigger.isInsert)
        {
            controller.createOpportunityForNewSlops(Trigger.new);
        }
        else if(Trigger.isUpdate)
        {
            controller.checkStatusLegalStatusChange(Trigger.new, Trigger.oldMap);
            controller.createOpportunityForNewSlops(Trigger.new);
            controller.syncChangedFields(Trigger.newMap, Trigger.oldMap);
        }

        controller.updateOpportunityIdTextField(Trigger.new);
        // AMILLER1
        controller.updateAccountReference(Trigger.new);
        // AMILLER1
    }
    else 
    {
        if(Trigger.isInsert)
        {
            controller.syncOpportunityAfterSlopCreation(Trigger.newMap); 
        }
    }
}