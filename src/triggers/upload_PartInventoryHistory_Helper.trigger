/**
 * upload_PartInventoryHistory_Helper
 * Tested by: upload_PartInventoryHistory_Helper_TEST
 * If an uploadPart__c field is specified, use it to lookup the corresponding Id from dealer__Parts_Inventory__c. 
 */
trigger upload_PartInventoryHistory_Helper on dealer__Part_Inventory_History__c (before insert) {

    if (Trigger.isBefore) {
        MW_TriggerControls__c uploadHelper = MW_TriggerControls__c.getInstance('uploadPartHistoryHelper');
        if (uploadHelper==null || uploadHelper.Enabled__c || Test.isRunningTest()) {
        	Set<String> locMfgPart = new Set<String>();
        	
        	// List of part numbers Loc:Mfg:Part format
            for(dealer__Part_Inventory_History__c h : Trigger.new) {
            	if (!String.isBlank(h.uploadPart__c)) {
            	    locMfgPart.add(h.uploadPart__c);
                    System.debug('Added uploadPart ' + h.uploadPart__c);
            	} 
            }
            
            // Get Map Loc:Mfg:Part to Id
            Map<String, Id> partMap = new Map<String, Id>();
            if (locMfgPart.size()>0) {
	            for(dealer__Parts_Inventory__c i : [select Id, dealer__Part_No__c 
	                                               from dealer__Parts_Inventory__c
	                   	                           where dealer__Part_No__c in :locMfgPart ]) {
	                partMap.put(i.dealer__Part_No__c, i.Id);
	                System.debug('Map ' + i.dealer__Part_No__c + ' to id ' + i.Id);
	            }
            }
            
            // Update record with looked-up Id and clear out upload field
            for(dealer__Part_Inventory_History__c h : Trigger.new) {
            	if (!String.isBlank(h.uploadPart__c)) {
            	    Id locMfgPartId = partMap.get(h.uploadPart__c);
            	    h.dealer__Part__c = locMfgPartId;
            	    System.debug('Mapped ' + h.uploadPart__c + ' to id ' + locMfgPartId);
            	    h.uploadPart__c = null;
            	} 
            }
             
        } // end if uploadHelper enabled
        
    } // end if Trigger.isBefore
    
} // end trigger