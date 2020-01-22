/** 
 * upload_Service_Vehicle_Helper_MW
 * Tested by: upload_Service_Vehicle_Helper_MW_Test
 * Assist in uploading Service Vehicles by looking up lient Account by Arcadium Key
 * Enable or Disable in "Develop / Custom Settings / MW Trigger Controls (Manage)
 * 
 * Modification log:
 * 2015-09-08	B. Leaman	BLL1 - also set owner contact if it's a person account
 */
trigger upload_Service_Vehicle_Helper_MW on dealer__Service_Vehicle__c (before insert, before update) {
    if (Trigger.isBefore) {
        MW_TriggerControls__c uploadHelper = MW_TriggerControls__c.getInstance('upload_Service_Vehicle_Helper');
        if (uploadHelper==null || uploadHelper.Enabled__c || Test.isRunningTest()) {
            List<String> accountcds = new List<String>();
            
            // get lists of text to translate to ids
            for(dealer__Service_Vehicle__c v: Trigger.new) {
                String ref = v.Upload_Account__c;
                if (!String.isBlank(ref)) {
                    accountcds.add(ref);
                    System.debug('Added account external id='+ref);
                }              
            } // end for ServiceVehicle 
  
            // generate Map to accounts by dealer__External_ID__c  for the accounts
            //Map<String, Id> acctmap = new Map<String, Id>();  BLL1d
            Map<String, Account> acctmap = new Map<String, Account>();  // BLL1a
            if (accountcds.size()>0) {
	            for(Account a: [select Id, dealer__External_ID__c, PersonContactId  // BLL1c add person contact id 
	                         From Account  
	                         where dealer__External_ID__c in :accountcds ])  {
	                         //acctmap.put(a.dealer__External_ID__c, a.Id);  // BLL1d
	                         acctmap.put(a.dealer__External_Id__c, a);  // BLL1a
	                         //System.debug('External id ' + a.dealer__External_ID__c + ' is account id ' + a.Id);
	            } 
            }
            // end for Account 
             
            // Modify all new records, replacing Id's based on Client Arcadium Key (if specified)
            for(dealer__Service_Vehicle__c  v : Trigger.new) {
                //id accountid = null; // account id
                // Get Account by Arcadium Key
                if (!String.isBlank(v.Upload_Account__c)) {
                    if (acctmap.containsKey(v.Upload_Account__c)) {
                    	Account a = acctmap.get(v.Upload_Account__c);  // BLL1a
                    	if (a!=null) {
                            // v.dealer__Veh_Owner__c = acctmap.get(arcadiumId);
                            // v.dealer__Veh_Owner__c = acctmap.get(v.Upload_Account__c); // BLL1d
                            // System.debug('Assigning account to ServiceVehicle for arcadium Id ' + v.upload_Account__c + ', id=' + v.dealer__Veh_Owner__c);
                            // BLL1a begin
                            v.dealer__Veh_Owner__c = a.Id;  
                            if (a.PersonContactId!=null) {
                                v.dealer__Veh_Owner_Contact__c = a.PersonContactId;
                            }
                            // BLL1a end 
                    	} 
                    }
                    v.Upload_Account__c = NULL;
                } // end if using upload_account__c
                
            } // for Trigger.new 
            
        } // if uploadAccountHelper enabled       
    } // end if isBefore
}