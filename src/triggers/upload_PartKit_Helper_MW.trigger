// PartKit upload helper
// Tested by: upload_PartKit_Helper_MW_TEST.cls
// Category, SubCategory, Manufacturer lookup by external ids
// Uses MW_TriggerControls__c custom list settings for:
// uploadPartKitHelper
// Moved to KitProcess class, invoked from KitMaintenance trigger
trigger upload_PartKit_Helper_MW on dealer__Parts_Kit__c (before insert, before update) {

//    if (Trigger.isBefore) {
//        MW_TriggerControls__c uploadHelper = MW_TriggerControls__c.getInstance('uploadPartKitHelper');
//        if (uploadHelper==null || uploadHelper.Enabled__c || Test.isRunningTest()) {
//    	
//	    	// Get list of unique id codes included in new records
//	    	Set<String> kitcatcodes = new Set<String>();
//	    	for(dealer__Parts_Kit__c k : Trigger.new) {
//	    		if (!String.isBlank(k.Upload_Category__c) && !kitcatcodes.contains(k.Upload_Category__c)) {
//	    			kitcatcodes.add(k.Upload_Category__c);
//	    		}
//	    		if (!String.isBlank(k.Upload_Sub_Category__c) && !kitcatcodes.contains(k.Upload_Sub_Category__c)) {
//	    			kitcatcodes.add(k.upload_Sub_Category__c);
//	    		}
//	    		if (!String.isBlank(k.Upload_Manufacturer__c) && !kitcatcodes.contains(k.upload_Manufacturer__c)) {
//	    			kitcatcodes.add(k.Upload_Manufacturer__c);
//	    		}
//	    	}
//	    	System.debug(kitcatcodes);
//	    	
//	    	// Get map of external id code & salesforce id from Kit Categories
//	    	Map<String, Id> kcmap = new Map<String, Id>();
//	    	if (kitcatcodes.size()>0) {
//		    	for (Kit_Category__c kc : [select Id, External_ID__c from Kit_Category__c 
//		    	                           where External_ID__c in :kitcatcodes]) {
//		    		kcmap.put(kc.External_ID__c, kc.Id);
//		    		System.debug('Mapping ' + kc.External_ID__c + ' to id ' + kc.Id);
//		    	}
//	    	}
//	    	    	
//	    	// Loop through new records and assign lookup references where the upload ids exist
//	    	for(dealer__Parts_Kit__c k : Trigger.new) {
//	    		if (String.isBlank(k.Category__c) && !String.isBlank(k.Upload_Category__c)) {
//	    			k.Category__c = kcmap.get(k.Upload_Category__c);
//	    			k.Upload_Category__c = null;
//	    		}
//	    		if (String.isBlank(k.Sub_Category__c) && !String.isBlank(k.Upload_Sub_Category__c)) {
//	    			k.Sub_Category__c = kcmap.get(k.Upload_Sub_Category__c);
//	    			k.Upload_Sub_Category__c = null;
//	    		}
//	    		if (String.isBlank(k.Manufacturer__c) && !String.isBlank(k.Upload_Manufacturer__c)) {
//	    			k.Manufacturer__c = kcmap.get(k.Upload_Manufacturer__c);
//	    			k.Upload_Manufacturer__c = null;
//	    		}
//	    	}
//	    	
//        } // if uploadAccountHelper enabled
//        
//    } // if isBefore
    
}