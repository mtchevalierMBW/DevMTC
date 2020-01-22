/** upload_RO_Invoice_Helper_MW
 * Assist in uploading RO Header by looking up Client Account ID by Arcadium Key and
 * company code from Store location name
 * Enable or Disable in "Develop / Custom Settings / MW Trigger Controls (Manage)
 * Tested by: upload_RO_Helpers_TEST
 *
 * 2016-03-22 RedTeal    RT1 - added a check to make sure trigger is enabled in custom setting before executing anything 
 */
trigger upload_RO_Invoice_Helper_MW on dealer__Service_Repair_Order__c (before insert, before update) {
	//RT1
	MW_TriggerControls__c triggerControl = MW_TriggerControls__c.getInstance('SROTriggers');
    if(triggerControl == null || triggerControl.Enabled__c) {

	    if (Trigger.isBefore) {
	        MW_TriggerControls__c uploadHelper = MW_TriggerControls__c.getInstance('upload_RO_Header');
	        if (uploadHelper==null || uploadHelper.Enabled__c || Test.isRunningTest()) {
	            List<String> accountcds = new List<String>();
	            List<String> locationnames = new List<String>();
	            
	            // get lists of text to translate to ids
	            for(dealer__Service_Repair_Order__c v: Trigger.new) {
	                String ref = v.upload_Customer__c;
	                if (!String.isBlank(ref)) {
	                    accountcds.add(ref);
	                    // System.debug('Added account external id='+ref);
	                } 
	   
	                String ref2 = v.upload_Location__c;
	                System.debug('test ref2: ' + ref2);  
	                if (!String.isBlank(ref2)) {
	                    locationnames.add(ref2);
	                    // System.debug('Added Location: ' + ref2);      
	                }
	                
	            } // end for Repair Order 
	  
	            // generate Map to accounts by dealer__External_ID__c  for the accounts
	            Map<String, Id> acctmap = new Map<String, Id>();
	            if (accountcds.size()>0) {
		            for(Account a: [select Id, dealer__External_ID__c
		                         From Account  
		                         where dealer__External_ID__c in :accountcds ])  {
		                         acctmap.put(a.dealer__External_ID__c, a.Id);
		                         //System.debug('External id ' + a.dealer__External_ID__c + ' is account id ' + a.Id);
		            } 
	            }
	            // end for Account 
	            
	            Map<String, String> locationmap = new Map<String, String>();  
	            Map<String, Id> locationIdMap = new Map<String, Id>();
	            if (locationnames.size()>0) {
		            for(dealer__Dealer_Location__c l:[select Name, dealer__Company_Number__c,id 
		                                              from dealer__Dealer_Location__c
		                                              where Name in :locationnames]) {
		                locationmap.put(l.Name.toLowerCase(), l.dealer__Company_Number__c);
		                // System.debug('Map Location: ' + l.Name + '  Company: ' + l.dealer__Company_Number__c);
		                locationIDmap.put(l.Name.toLowerCase(), l.Id);
		                // System.debug('Map Location: ' + l.Name + '  Company ID: ' + l.id);
		            }
	            }
	            
	             
	            // Modify all new records, replacing Id's based on Customer(Client) Arcadium Key (if specified in upload_customer__c)
	            // Only if there are records to modify
	            if (accountcds.size()>0 || locationnames.size()>0) {
	            	System.debug('upload_RO_Invoice_Helper_MW has work to do');
		            for(dealer__Service_Repair_Order__c  v : Trigger.new) {
		                // Get Account by Arcadium Key
		                if (!String.isBlank(v.Upload_Customer__c)) {
		                    if (acctmap.containsKey(v.Upload_Customer__c)) {
		                       v.dealer__Customer__c = acctmap.get(v.Upload_Customer__c);
		                       System.debug('Assigning account to Service RO for arcadium Client Id ' +   v.upload_Customer__c + ', id=' + v.dealer__Customer__c);
		                    }
		                    v.Upload_Customer__c = NULL; 
		                } // end if using upload_Customer__c
		                
		                // Modify all new records, replacing company code based on Location(Store name)  (if specified in upload_location__c)
		                if (!String.isBlank(v.upload_Location__c)) {
		                   String lcname = v.upload_Location__c.toLowercase();
		                   if (locationmap.containsKey(lcname)) {
		                        String co = locationmap.get(lcname);
		                        id coid = locationIdMap.get(lcname);
		                        v.dealer__company_number__c = co;
		                        v.dealer__Company__c=coid;
		                        System.debug('Assigning location id and Company for ' + lcname + '/' +   coid + ' '  + co);
		                   }
		                   v.upload_Location__c = NULL;
		                }        
		                
		            } // for Trigger.new
	            
	            } // BLL1a  
	            
	        } // if uploadAccountHelper enabled       
	    } // end if isBefore
	}//RT1 - end custom setting check
}   // End if Trigger.isBefore0