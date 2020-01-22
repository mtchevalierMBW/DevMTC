// upload_Task_Helper_MW
// Assist in uploading tasks by looking up Account by C-record and Owner by name
// If no owner, try to use GM from account, if not found, default to user running upload
// Tested by: upload_Task_Helper_MW_TEST
trigger upload_Task_Helper_MW on Task (before insert, before update) {
    if (Trigger.isBefore) {

        MW_TriggerControls__c uploadHelper = MW_TriggerControls__c.getInstance('uploadTaskHelper');
        if (uploadHelper==null || uploadHelper.Enabled__c || Test.isRunningTest()) {

	        List<String> usernames = new List<String>();
	        List<String> accountcds = new List<String>();
	        // get lists of text to translate to ids
	        for(Task t: Trigger.new) {
	            String o = t.Upload_Owner__c;
	            if (!String.isBlank(o)) {
	                usernames.add(o);
	            }
	            //System.debug(usernames);
	            String ref = t.Upload_Account__c;
	            if (!String.isBlank(ref)) {
	                accountcds.add(ref);
	            }
	            //System.debug(accountcds);
	        } // end for task
	
	        // generate Map to users by Id
	        Map<String, Id> usermap = new Map<String, Id>();
	        if (usernames.size()>0) {
	            for(User u: [select Id, Name, isActive From User
	                         where Name in :usernames and isActive=true ]) {
	            usermap.put(u.Name.toLowerCase(), u.Id);
	            } // end for User
	        }
	        
	        // generate Map to accounts by dealer__External_ID__c and list of locations for the accounts
	        Map<String, Id> acctmap = new Map<String, Id>();
	        Map<Id, Id> acctStoreMap = new Map<Id, Id>();
	        List<Id> storelocs = new List<Id>();
	        if (accountcds.size()>0) {
		        for(Account a: [select Id, Name, dealer__External_ID__c, Store_Location__c 
		                     From Account
		                     where dealer__External_ID__c in :accountcds ]) {
		            acctmap.put(a.dealer__External_ID__c, a.Id);
		            if (a.Store_Location__c != null) {
		                storelocs.add(a.Store_Location__c);
		                acctStoreMap.put(a.Id, a.Store_Location__c);
		                System.debug('Account id=' + a.Id + ', externalid=' + a.dealer__External_ID__c + ', store id=' + a.Store_Location__c);
		            } 
		        } // end for Account 
	        }
	         
	        // generate Map to General Managers by Location Id
	        Map<Id, Id> storegm = new Map<Id, Id>();
	        if (storelocs.size()>0) {
	        	for(dealer__Dealer_Location__c loc : [select Id, Name, dealer__General_Manager__c
	        	              from dealer__Dealer_Location__c 
	        	              where Id in :storelocs ]) {
	        	   storegm.put(loc.Id, loc.dealer__General_Manager__c);
	        	   System.debug('Location ' + loc.Name + ' has gm id ' + loc.dealer__General_Manager__c);
	        	}
	        } // end if storelocs.size()>0
	
	        // Modify all new records, replacing Ids based on names (if specified)
	        for(Task t : Trigger.new) {
	        	Id whatid = null;   // account Id
	            // Get location and set location ID
	            if (!String.isBlank(t.Upload_Account__c)) {
	                String arcadiumId = t.Upload_Account__c;
	                if (acctmap.containsKey(arcadiumId)) {
	                    whatid = acctmap.get(arcadiumId);
	                    t.WhatId = whatid;
	                    System.debug('Assigning account to task for arcadium Id ' + arcadiumId + ', id=' + whatid);
	                }
                    t.Upload_Account__c = null;
	            } // end if using upload_account__c
	
	            // Get owner code (external ID) and set location ID
	            if (!String.isBlank(t.Upload_Owner__c)) {
	                String lcname = t.Upload_Owner__c.toLowercase();
	                if (usermap.containsKey(lcname)) {
	                    Id uid = usermap.get(lcname);
	                    t.OwnerId = uid;
	                    System.debug('Assigning ID for owner ' + lcname);
	                } else if (whatid != null) {
	               	    Id locid = acctStoreMap.get(whatid);  // location for this account 
	               	    System.debug('Account id ' + whatid + ' has location id ' + locid);
	               	    Id gmid = storegm.get(locid);         // gm for this location
	               	    System.debug('Location id ' + locid + ' has general manager id ' + gmid);
	               	    if (gmid<>null) {
	               	        t.OwnerId = gmid;
	               	        System.debug('Assigning general manager as owner. Account=' + whatid + ', Location=' + locid+ ', gm=' + gmid);
	               	    } else {
	               	  	    System.debug('No general manager');
	               	    } // end if-else gmid
	               } // end if usermap else-if whatid
                   t.Upload_Owner__c = null;
	            }  // end if using upload_owner__c
	            
	   	    } // for Trigger.new 
	   	    
        } // if uploadAccountHelper enabled
        
    } // end if isBefore
    
}