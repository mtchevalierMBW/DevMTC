/**
 * OpportunityProcess
 * Tested by: CommercialQuote_TEST
 * Programmer: Bryan Leaman
 * Date: 2016-02-19
 *
 * AMILLER 9-14-2017 updating trigger to have a handler for extra logic
 * 9-21-2018 - Alexander Miller - AMILLER1 - W-000370 - Update to assign OpportunityContactRole so pardot will sync correctly. Commented out and moved to nightly batch
 */
trigger OpportunityProcess on Opportunity (before insert, after insert, before update, after update) {
    MW_TriggerControls__c lostOpportunity = MW_TriggerControls__c.getInstance('LostOpportunity');
        if (lostOpportunity==null || lostOpportunity.Enabled__c) {
        if (Trigger.isAfter && Trigger.isUpdate) CommercialQuoteProcess.LostOpportunity(Trigger.newMap, Trigger.oldMap);
    }

    OpportunityTriggerHandler controller = new OpportunityTriggerHandler(Trigger.new, Trigger.old);

    if(Trigger.isBefore){
        
        if (Trigger.isUpdate)
        {
            controller.onBeforeUpdate();
            controller.mbwBeforeUpdateDefaultOwner(Trigger.new);
        } 
    }
    // AMILLER1
    //else 
    //{
        //if(Trigger.isInsert)
        //{
            //controller.createOpportunityContactRoles(Trigger.new);
        //}
    //}
    // AMILLER1
}