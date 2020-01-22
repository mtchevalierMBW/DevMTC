/**
 * ContactTrigger
 * Tested by: AccountManagement_TEST
 * Date: May 2, 2016
 * Programmer: Bryan Leaman
 * 
 */
trigger ContactTrigger on Contact (before insert, before update, before delete) {
	if (Trigger.isBefore && !Trigger.isDelete) {
	    for (Contact c : Trigger.new) {
	    	Contact oldcontact = Trigger.oldMap!=null ? Trigger.oldMap.get(c.Id) : null;
	    	
			// Concatenate stock numbers (Desired_Vehicels__c) if changed from one or more to only 1
			if (oldcontact!=null && !String.isBlank(oldcontact.Desired_Vehicles__c)
				&& !String.isBlank(c.Desired_Vehicles__c)
				&& !c.Desired_Vehicles__c.contains(';')) {
	
				String vehicles = c.Desired_Vehicles__c.trim(); 
				// If NOT adding a duplicate stock#, append it    		    	
				if (!oldcontact.Desired_Vehicles__c.toUpperCase().trim().contains(c.Desired_Vehicles__c.toUpperCase().trim())) {
					vehicles = oldcontact.Desired_Vehicles__c.trim() + '; ' + vehicles; 
				} else {
					// Adding a duplicate stock number, so just keep the old list
					vehicles = oldcontact.Desired_Vehicles__c.trim(); 
			}
   			    while(vehicles.length()>255 && vehicles.contains(';')) {
   			    	vehicles = vehicles.substring(vehicles.indexOf(';')+1).trim();
   			    }
				if (vehicles.length()>255) vehicles = vehicles.right(255); // drop off earlier/older information
				c.Desired_Vehicles__c = vehicles; 
		    }
    		
    	}
	}
	
	// Delete influencer associations with no influencer
	if (Trigger.isBefore && Trigger.isDelete) {
		List<InfluencerAssociation2__c> ia2List = new List<InfluencerAssociation2__c>();	// BLL1a
		Set<Id> contactIds = new Set<Id>();
		for(Contact c : Trigger.old) contactIds.add(c.Id);
	
		if (contactIds.size()>0) {
			ia2List = [select Id, Name from InfluencerAssociation2__c where InfluencerContact__c in :contactIds and InfluencerAccount__c=null limit 2000];
			if (ia2List.size()>0) delete(ia2List);
		}
		
	}
	
}