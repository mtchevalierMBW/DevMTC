Trigger ServiceEstimateSubLineDefaults on dealer__Service_Estimate_SubLine__c (BEFORE INSERT, BEFORE UPDATE) {

    /* 
     *   12-10-2017  JVK1   Perform Labor Rate Calculation on Labor Time added
     *  12-10-2017  JVK2  Force Parts Matrix Pricing on all Parts Edited
     */ 
    
    /* Before Context */
    if(Trigger.isBefore && !Trigger.isDelete){
        
        // <JVK1>
        ServiceEstimateCustomControls.setForcedLaborRate(Trigger.new);
        // </JVK1>

        // <JVK2>
    	ServiceEstimateCustomControls.setForcedPartsPricing(Trigger.new);
        // </JVK2>

    }
}