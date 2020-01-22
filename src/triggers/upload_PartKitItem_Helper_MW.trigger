// PartKitItem upload helper
// Tested by: upload_PartKit_MW_TEST.cls
// Uses MW_TriggerControls__c custom list settings for:
// uploadPartKitItemHelper
trigger upload_PartKitItem_Helper_MW on dealer__Parts_Kit_Item__c (before insert, before update) {

    if (Trigger.isBefore) {
        MW_TriggerControls__c uploadHelper = MW_TriggerControls__c.getInstance('uploadPartKitItemHelper');
        if (uploadHelper==null || uploadHelper.Enabled__c || Test.isRunningTest()) {
    	
	    	// Get list of unique id codes included in new records
	    	Set<String> kits  = new Set<String>();
	    	Set<String> parts = new Set<String>();
	    	
	    	for(dealer__Parts_Kit_Item__c k : Trigger.new) {
	    		if (!String.isBlank(k.upload_Kit__c) && !kits.contains(k.upload_Kit__c)) {
	    			kits.add(k.upload_Kit__c);
	    		}
	    		if (!String.isBlank(k.upload_Part__c) && !parts.contains(k.upload_Part__c)) {
	    			parts.add(k.upload_Part__c);
	    		}
	    	}
	    	
	    	// Get map of external id code & salesforce id from Kit Categories
	    	Map<String, Id> kitmap = new Map<String, Id>();
		    	if (kits.size()>0) {
		    	for (dealer__Parts_Kit__c k : [select Id, Name from dealer__Parts_Kit__c
		    	     where Name in :kits ]) {
		    		kitmap.put(k.Name, k.Id);
		    	}
	    	}
	    	//Map<String, Id> partmap = new Map<String, Id>();
	    	Map<String, Id> partmstrmap = new Map<String, Id>();
	    	//for (dealer__Parts_Inventory__c p : [select Id, Name, dealer__Part_No__c, dealer__Parts_Master__c
	    	//                                     from dealer__Parts_Inventory__c
	    	//                                     where dealer__Part_No__c in :parts]) {
	    	//	partmap.put(p.dealer__Part_No__c, p.Id);
	    	if (parts.size()>0) {
		    	for (dealer__Parts_Master__c p : [select Id, Name, dealer__Part_No__c from dealer__Parts_Master__c
		    	     where dealer__Part_No__c in :parts]) {
		    		partmstrmap.put(p.dealer__Part_No__c, p.Id);
		    		System.debug('Part_No = ' + p.dealer__Part_No__c + '; Id='+p.Id);
		    	}
	    	}
	    	
	    	// Loop through new records and assign lookup references where the upload ids exist
	    	for(dealer__Parts_Kit_Item__c k : Trigger.new) {
	           if (String.isBlank(k.dealer__Parts_Kit__c) && !String.isBlank(k.upload_Kit__c)) {
	           	  k.dealer__Parts_Kit__c = kitmap.get(k.upload_Kit__c);
	           	  k.upload_Kit__c = null;
	           }
	           if (String.isBlank(k.dealer__Part__c) && !String.isBlank(k.upload_Part__c)) {
	           	  //k.dealer__Part__c = partmap.get(k.upload_Part__c);
	           	  k.dealer__Parts_Master__c = partmstrmap.get(k.upload_Part__c);
	           	  System.debug('upload_part=' + k.upload_Part__c + '; Part id=' + k.dealer__Part__c+'; master='+k.dealer__Parts_Master__c);
	           	  k.upload_Part__c = null;
	           }
	    	}
	    	
        } // if uploadPartKitItemHelper enabled
    	
    } // if isBefore

}