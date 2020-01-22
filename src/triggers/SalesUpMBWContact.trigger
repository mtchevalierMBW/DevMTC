/**
* 2016-02-21 B. Leaman   BLL15 - Lost solution opportunity logic for commercial quotes.
* 2016-03-15   RedTeal   RT1 - Moved old trigger code to SalesUpTriggerHandler
* 2018-7-20  A. Miller   AMILLER1 - Added on standard Opportunity Syncing logic
* 2019-04-01	B. Leaman	W-000528 BLL16 - Implementing SolutionOppFollowUpTasks batch process to replace process builder.
*/
trigger SalesUpMBWContact on dealer__Sales_Up__c (before insert, after insert, before update, after update) {
    
	// BLL16 - reset follow-up-stage whenever latest appointment date changes
	if (Trigger.isBefore && !Trigger.isDelete) SolutionOppFollowUpTasks.resetFollowupStageIfChanged(Trigger.new, Trigger.oldMap);
	// BLL16

    if(SalesUpTriggerHandler.allowTrigger) 
    {
        if(Trigger.isBefore) 
        {
            SalesUpTriggerHandler.beforeHandler(Trigger.new, Trigger.newMap, Trigger.oldMap, Trigger.isInsert);

            // AMILLER1
            if(SalesUpMBWContactOppHandler.isAllowedToRun())
            {
                SalesUpMBWContactOppHandler.createOpportunityForNewSlops(Trigger.new);
            }
            // AMILLER1
        }
        else 
        {
            // AMILLER1
            if(SalesUpMBWContactOppHandler.isAllowedToRun() && SalesUpMBWContactOppHandler.runOnce())
            {
                SalesUpMBWContactOppHandler.createOpportunityForNewSlops(Trigger.new);
                SalesUpMBWContactOppHandler.syncOpportunityAfterSlopCreation(Trigger.newMap);
                SalesUpMBWContactOppHandler.syncOpportunity(Trigger.newMap, Trigger.oldMap); 
            }
            else if(SalesUpMBWContactOppHandler.isAllowedToRun())
            {
                // Call this a second time since there is a lag in syncing the standard opportunity data
                SalesUpMBWContactOppHandler.syncOpportunity(Trigger.newMap, Trigger.oldMap); 
            }
            // AMILLER1

            if(Trigger.isUpdate) 
            {
                SalesUpTriggerHandler.afterUpdateHandler(Trigger.new, Trigger.newMap, Trigger.oldMap, Trigger.size);
                
                //BLL15a
                MW_TriggerControls__c lostSolutionOpp = MW_TriggerControls__c.getInstance('LostSolutionOpp');
                if (lostSolutionOpp==null || lostSolutionOpp.Enabled__c) {
                     CommercialQuoteProcess.LostSolutionOpportunity(Trigger.newMap, Trigger.oldMap);
                }
                //BLL15a end
            }
        }    
    }    
}