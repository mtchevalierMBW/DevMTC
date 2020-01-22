/**
 * ServiceEstimateCustomControls
 * Tested by: TestServiceEstimateCustomControls
 *
 * Code coverage:
 *	2018-04-19	92% (50/54)
 *	2018-09-25	92% (52/56)
 *
 *	2018-04-09	B. Leaman	BLL1 - Use our existing part price routine and eliminate the new PartPriceMatrix class.
 *	2018-09-25	B. Leaman	BLL2 IR-0040926 - Customer pay parts pricing minimum to be our cost, no maximum.
**/

public class ServiceEstimateCustomControls {
    
    /**
     * This method determines if a value has changed in a way that 
     * our custom business logic requires a line recalc
     */
    public static boolean isMeaningfullyChanged(List<dealer__Service_Estimate_Line__c> newLines, Map<Id, dealer__Service_Estimate_Line__c> oldLines) {
        Boolean isChanged = false;
        
        	// Iterate the lines and check before and after values
            for(dealer__Service_Estimate_Line__c sel : newLines){
              	
                // Isolated old data values
                dealer__Service_Estimate_Line__c oldLine = oldLines.get(sel.Id);
                
                // If Labor Rate is Changed, let's recalc... Yes Duane!!
                if(sel.dealer__Labor_Type__c != oldLine.dealer__Labor_Type__c) {
                    isChanged=true;
                }
            }
        	
        return isChanged;
    }
    
    
    /**
     * Simple re-save event to trigger managed/non-managed routines on the sublines (Domain Layer Logic)
     * 
     */
    public static void recomputeSubLines(List<dealer__Service_Estimate_Line__c> estLines){
        
        // Get a set of affected IDs
		Set<Id> estimateLineIds = new Set<Id>();
        for(dealer__Service_Estimate_Line__c sel : estLines){
            estimateLineIds.add(sel.Id);
        }
        
		List<dealer__Service_Estimate_SubLine__c> subLines = [SELECT Id 
                                                              	FROM dealer__Service_Estimate_Subline__c 
                                                              	WHERE dealer__Service_Estimate_Line__c IN:estimateLineIds];
        try {
            update subLines;
        } Catch(DmlException e) {
            throw new EstimateException(e.getMessage());
        }
    }
    
    /**
     * This method takes a list of sublines and performs mandatory labor rate specifiucation based on the business rules
     * 
     */
    public static void setForcedLaborRate(List<dealer__Service_Estimate_SubLine__c> subLines) {
        
            
        // Get the assocaited custom Payment Types
        Map<String, ServicePaymentType__c> paymentTypes = new Map<String, ServicePaymentType__c>();
        Map<String, Map<Id, Decimal>> laborRateOverrides = new Map<String, Map<Id, Decimal>>();
        for(ServicePaymentType__c spt : [
        	select Id, Name, Default_Labor_Rate__c, 
        		(select Id, Location__c, Labor_Rate__c 
        		 from LaborRateDefaults__r) 
			from ServicePaymentType__c
		]) {
    
            // Base Payment Method 
            paymentTypes.put(spt.Name, spt);
    
            // Location Override
            Map<Id, Decimal> innerLaborMap = new Map<Id, Decimal>();
            for(ServiceLaborRateDefaults__c lrd : spt.LaborRateDefaults__r) {
                innerLaborMap.put(lrd.Location__c, lrd.Labor_Rate__c);
            }
            laborRateOverrides.put(spt.Name, innerLaborMap);
        }
        
        // Set the Labor Rate on the Estimate Line
        for(dealer__Service_Estimate_SubLine__c sesbl : subLines) { 
            
            String lineType = sesbl.dealer__Line_Type__c; // Laobr / Misc / Parts
            String laborType = sesbl.dealer__Labor_Type__c; // C,W,I,CR,CR80
    
            if(lineType=='Labor') { 
    
                System.debug('Forcing labor rate based on Payment Method');
    
                Map<Id, Decimal> locationOverride = laborRateOverrides.get(laborType);
                Id locationId = sesbl.dealer__Location_Id__c;
                Decimal defaultRate = (paymentTypes.get(laborType)!=null) ? paymentTypes.get(laborType).Default_Labor_Rate__c : 0;
                sesbl.dealer__Labor_Rate__c = (locationOverride!=null && locationOverride.get(locationId)!=null) ? locationOverride.get(locationId) : defaultRate;
    
                System.debug(sesbl);
            
            }
        }  
    }
    
    /**
     * Recalculate parts pricing based on Payment Type
     * 
     */
    public static void setForcedPartsPricing(List<dealer__Service_Estimate_Subline__c> subLines){
    	
        Set<Id> partIds = new Set<Id>();
        Set<String> paymentTypesUsed = new Set<String>();
        
        // Iterate sublines and inspect values for associated parts
        for(dealer__Service_Estimate_Subline__c subl : subLines) {
            if(subl.dealer__Parts_Master__c != null){
                partIds.add(subl.dealer__Parts_Master__c);
                paymentTypesUsed.add(subl.dealer__Labor_Type__c);
            }
        }
        
        
        // Return if we have nothing to process
        if(partIds.isEmpty()) {
            return;
        }
        
        // Get relevant data
		Map<String, ServicePaymentType__c> paymentMethods = new Map<String, ServicePaymentType__c>();
        for(ServicePaymentType__c spm : [
        	select Id, Name, Payment_Type__c 
        	from ServicePaymentType__c 
        	where Name IN:paymentTypesUsed
        ]) {
            paymentMethods.put(spm.Name, spm);
        }
		Map<Id, dealer__Parts_Master__c> partsUsed = new Map<Id, dealer__Parts_Master__c>([SELECT Id, dealer__Cost__c FROM dealer__Parts_Master__c WHERE Id IN:partIds]);
        for(dealer__Service_Estimate_Subline__c subl : subLines) {
            if(subl.dealer__Parts_Master__c != null) {
                if(paymentMethods.get(subl.dealer__Labor_Type__c).Payment_Type__c == 'C') {
                    //BLL1d subl.dealer__Part_Price__c = PartPriceMatrix.calculate(partsUsed.get(subl.dealer__Parts_Master__c).dealer__Cost__c);	
                    // subl.dealer__Part_Price__c = PartsProcess.RetailPriceMarkUpFromCost(partsUsed.get(subl.dealer__Parts_Master__c).dealer__Cost__c);	// BLL1a
					
					/* 
					 * Bryan, I am working with Duane on this for testing to see if it meets his business needs 
					 * He and I reviewed the following logic on 4/19 and it meets his requirements.
					 * Sale Price may not exceed matrix and may not be lower than replenishment cost (part master cost)
					*/
					// BLL2d per Duane McCord, don't impose a max price. Also, I verified that ROs don't impose a max price.
                    //BLL2d if(subl.dealer__Part_Price__c > PartsProcess.RetailPriceMarkUpFromCost(partsUsed.get(subl.dealer__Parts_Master__c).dealer__Cost__c)) {
                    //BLL2d     subl.dealer__Part_Price__c = PartsProcess.RetailPriceMarkUpFromCost(partsUsed.get(subl.dealer__Parts_Master__c).dealer__Cost__c);
                    //BLL2d }
					
					// BLL2 NOTE: ROs don't impose a minimum price either, but Duane didn't want to change this yet.
                    if(partsUsed.get(subl.dealer__Parts_Master__c).dealer__Cost__c > subl.dealer__Part_Price__c) {
                        subl.dealer__Part_Price__c = partsUsed.get(subl.dealer__Parts_Master__c).dealer__Cost__c;
                    }
                    
                } else {
                    subl.dealer__Part_Price__c = partsUsed.get(subl.dealer__Parts_Master__c).dealer__Cost__c;
                }
            }
        }
    }
    
    /* Exception Class */
    public class EstimateException extends Exception {}
}