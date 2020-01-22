trigger ServiceEstimateLineDefaults on dealer__Service_Estimate_Line__c (after update) {
  
    /* 
     * 12-10-2017  JVK2   If labor rate is changed, recalc lines. 
     *
     */ 
    
    /* After Context */
    if(Trigger.isAfter && !Trigger.isDelete) {
        
        System.debug('Trigger Executed');
    // Looks like this trigger fires if sublines are affected.  
    // Add LineTotal Methods here.
        
        // <JVK2>
        if(ServiceEstimateCustomControls.isMeaningfullyChanged(Trigger.new, Trigger.oldMap)) {
            ServiceEstimateCustomControls.recomputeSubLines(Trigger.new);
        }
        // </JVK2>
    }
}