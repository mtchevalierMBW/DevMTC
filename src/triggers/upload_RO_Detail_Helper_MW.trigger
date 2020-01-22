/** upload_RO_Detail_Helper_MW
 * Assist in uploading Op code ID & Op Code Description by Op Code
 * Tested by: upload_RO_Helpers_TEST
 *
 * Enable or Disable in "Develop / Custom Settings / MW Trigger Controls (Manage)
 * 2015-09-11	B. Leaman	BLL1 Skip code if there are no uploaded pay types
 */
trigger upload_RO_Detail_Helper_MW on dealer__Service_Job__c (before insert, before update) {
    if (Trigger.isBefore) {
        MW_TriggerControls__c uploadHelper = MW_TriggerControls__c.getInstance('upload_RO_Detail');
        if (uploadHelper==null || uploadHelper.Enabled__c || Test.isRunningTest()) {
                        
            // Load Pay types  into List for Processing
            List<String> PayTypes = new List<String>();
            
            for(dealer__Service_Job__c t:Trigger.new) {
               String pRef=t.upload_Pay_method__c;
               if (!String.isBlank(pRef)) {
                    PayTypes.add(pRef);
                    // System.debug('Added Pay Method = '+pref);
                } 
 
            } // end for Service Job 
  

            // generate Map to Pay Method ID's and Pay Types 
            Map<String, Id> idmap = new Map<String, Id>();
            Map<String, String> typemap = new Map<String, String>();
            if (PayTypes.size()>0) {
	            for(ServicePaymentType__c  p:[Select name, id, Payment_Type__c
	                         From ServicePaymentType__c  
	                         where name in :PayTypes ])  {
	                idmap.put(p.name, p.Id);
	                typemap.put(p.name, p.Payment_Type__c);
	                // System.debug('Type ' + p.name + ' is id ' + p.Id + ' and Method is ' +  p.peyment_type__c);
	            } 
            }
            // end for Service Payment Type


                     
            // Modify all new records, storing RO Id's based on RO Numberf specified in dealer__RO_Number__c)
            if (PayTypes.size()>0) { // BLL1a
            	System.debug('upload_RO_Detail_Helper_MW has work to do');
	            for(dealer__Service_Job__c  t : Trigger.new) {
	       
	                // Get  id & Description by Pay method
	                if (!String.isBlank(t.Upload_Pay_Method__c)) {
	                    if (idmap.containsKey(t.Upload_Pay_Method__c)) {
	                       t.Payment_Method__c = idmap.get(t.Upload_Pay_Method__c);
	                       t.dealer__Labor_Type__c = TypeMap.get(t.Upload_Pay_Method__c);
	                       System.debug('Updated Payment_Method__c and dealer__Labor_Type__c for ' + t.Id);
	                    }     
	                    t.upload_Pay_Method__c=null;
	
	                }  // end for Payment type
	                
	                
	            } // for Trigger.new 
            
            } // BLL1a don't bother if there were no paytypes
            
        } // if uploadAccountHelper enabled       
    } // end if isBefore
}   // End if Trigger.isBefore