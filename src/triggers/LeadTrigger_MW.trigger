// LeadTrigger:
// Concatenate desired vehicles (coming from Pardot)
// Calculate queue time & response time for BDC measurements
// Record queue name and first user id to take from the queue
// Uses MW_TriggerControls__c custom list settings for:
// LeadMWCommercial, LeadBusHrsElapsed
/** Tested by: LeadTrigger_MW_TEST, LeadConversion_TEST
 * Coverage:
 *	2018-04-10	86% (93/108)
 *
 *	Date        Programmer  Description
 *	2015-08-12	B. Leaman	BLL1 - Change owner to change open task owner too.
 *	2015-10-13	B. Leaman	BLL2 - Don't set task owner to a group.
 *	2016-01-05	B. Leaman	BLL3 - Handle overflow on desired vehicles 
 *	2016-09-21	B. Leaman	BLL4 - Add New Influencer support.
 *	2018-04-11	B. Leaman	BLL5 - upload lead record type (for Pardot integration)
 *	2018-04-18	B. Leaman	BLL6 - only assign lead record type on creation, not update.
 */
trigger LeadTrigger_MW on Lead (before insert, before update, after update) {

    // Set initial queue?
    MW_TriggerControls__c originalQueue = MW_TriggerControls__c.getInstance('LeadOriginalQueueAndRep');
    // Build queue Id/Name map
    Map<Id, String> queueMap = new Map<Id, String>();
    if (originalQueue==null || originalQueue.Enabled__c || Test.isRunningTest()) {
    	for(Group q : [select Id, Name from Group Where Type='Queue']) {
    		queueMap.put(q.Id, q.Name);
    	}
    }

	// BLL5a Use new upload_RecordType__c field to set record type from Pardot or other sources
	if (Trigger.isBefore && Trigger.isInsert) {	// BLL6a
		MW_TriggerControls__c uploadHelper = MW_TriggerControls__c.getInstance('uploadLeadHelper');
		Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.Lead.getRecordTypeInfosByName();
		for(Lead l : Trigger.new) {
			// Override record type - could be problematic
			if (!String.isBlank(l.upload_RecordType__c)) {
				Schema.RecordTypeInfo rtinfo = RcdTypes.get(l.upload_RecordType__c);
				if (rtinfo<>null) {
					Id rtid = rtinfo.getRecordTypeId();
					if (rtid!=null && (uploadHelper==null || uploadHelper.Enabled__c)) { 
						l.RecordTypeId = rtid;
						System.debug('Assigned lead ' + l.Name + ' record type ' + l.upload_RecordType__c);
					}
				} 
				l.upload_RecordType__c = null;
			}
		}
	}
	// BLL5a end

    // Before insert
    // New leads from MobilityWorks Commercial website should be commercial leads (so assignment rules fire)
    // Record queue name (if assigned to a queue right away) 
    if (Trigger.isBefore && Trigger.isInsert) {
        MW_TriggerControls__c mwcWebForm = MW_TriggerControls__c.getInstance('LeadMWCommercial');
        if (mwcWebForm==null || mwcWebForm.Enabled__c) {

	    	RecordType commercialrt = [select Id, Name from RecordType where SObjectType='Lead' and Name = 'Commercial'];
	        //Database.DMLOptions dmo = new Database.DMLOptions();
	        //dmo.assignmentRuleHeader.useDefaultRule = true;         // use leadAssignment rules when updating
	    	for(Lead newlead : Trigger.new) {
	    		if (newlead.LeadSource != null && commercialrt!=null && newlead.LeadSource.startsWith('MWC') ) {
	    			newlead.RecordTypeId = commercialrt.Id;
	    			//newlead.setOptions(dmo);
	    		}
	    	}
        } // mwcWebForm enabled

        // Other misc updates
        if (originalQueue==null || originalQueue.Enabled__c || Test.isRunningTest()) {
        	for(Lead newlead : Trigger.new) {
                // Log original queue
        		if (Schema.Group.SObjectType==newlead.OwnerId.getSObjectType() 
        		    && String.isBlank(newlead.Lead_Queue_Name__c)) {
        			newlead.Lead_Queue_Name__c = queueMap.get(newlead.OwnerId);
        		}
        		// Fix phone# format
        		if (newlead.Phone != null) {
        			newlead.Phone = FormattingUtility.formatPhoneNbr(newlead.Phone);
        		}
        		if (newlead.MobilePhone != null) {
        			newlead.MobilePhone = FormattingUtility.formatPhoneNbr(newlead.MobilePhone);
        		}
        	}
        } // originalQueue    

    } // before insert


    // Before updates
    // 1. Concatenate desired vehicle stock numbers (to retain full list of stock numbers from Pardot)
    // 2. Calculate queue time business hours and response time business hours
    if (Trigger.isBefore && Trigger.isUpdate) {

        MW_TriggerControls__c busHours = MW_TriggerControls__c.getInstance('LeadBusHrsElapsed');
   	    BusinessHours bh = [select Id from BusinessHours where IsDefault=true limit 1];

		// BLL4a
		//Map<String, Schema.RecordTypeInfo> IARcdTypes = Schema.SObjectType.InfluencerAssociation__c.getRecordTypeInfosByName();
		Map<String, Schema.RecordTypeInfo> IARcdTypes = Schema.SObjectType.InfluencerAssociation2__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo LeadIaRti = IARcdTypes.get('Lead');
		//Schema.RecordTypeInfo AcctIaRti = IARcdTypes.get('Account');
		Id LeadIaRtId = LeadIaRti.getRecordTypeId();
		//Id AcctIaRtId = AcctIaRti.getRecordTypeId();
		//List<InfluencerAssociation__c> ialist = new List<InfluencerAssociation__c>();
		List<InfluencerAssociation2__c> ialist = new List<InfluencerAssociation2__c>();
		// BLL4a
	
        // Concatenate stock numbers from Pardot if new is not already in old list 
    	for(Lead newlead : Trigger.new) {
    		Lead oldlead = Trigger.oldMap.get(newlead.Id);

			// BLL4a - AddNewInfluencer support
			//if (Trigger.isUpdate && newlead.AddNewInfluencer__c!=null) { 
			//	ialist.add(new InfluencerAssociation__c(
			//		RecordTypeId=LeadIaRtId, Account__c=newlead.AddNewInfluencer__c,
			//		InfluencedLead__c=newlead.Id
			//	));
			//	newlead.AddNewInfluencer__c = null;
			//}
			//if (Trigger.isUpdate && newlead.AddNewInfluencerContact__c!=null) {
			//	ialist.add(new InfluencerAssociation__c(
			//		RecordTypeId=LeadIaRtId, Contact__c=newlead.AddNewInfluencerContact__c,
			//		InfluencedLead__c=newlead.Id
			//	));
			//	newlead.AddNewInfluencerContact__c = null;
			//}
			if (newlead.Id!=null && (newlead.AddNewInfluencer__c!=null || newlead.AddNewInfluencerContact__c!=null)) { 
				InfluencerAssociation2__c newia2 = new InfluencerAssociation2__c(
					RecordTypeId=LeadIaRtId, InfluencerAccount__c=newlead.AddNewInfluencer__c,
					InfluencedLead__c=newlead.Id
				);
				newlead.AddNewInfluencer__c = null;
				if (newlead.AddNewInfluencerContact__c!=null) {
					newia2.InfluencerContact__c=newlead.AddNewInfluencerContact__c;
					newlead.AddNewInfluencerContact__c = null;
				}
				ialist.add(newia2);
			}
			// BLL4a end

            // Concatenate stock numbers (Desired_Vehicels__c) if changed from one or more to only 1
    		if (!String.isBlank(oldlead.Desired_Vehicles__c)
    		    && !String.isBlank(newlead.Desired_Vehicles__c)
    		    && !newlead.Desired_Vehicles__c.contains(';')) {

				String vehicles = newlead.Desired_Vehicles__c.trim(); // BLL3a
                // If NOT adding a duplicate stock#, append it    		    	
    		    if (!oldlead.Desired_Vehicles__c.toUpperCase().trim().contains(newlead.Desired_Vehicles__c.toUpperCase().trim())) {
    			    //BLL3d newlead.Desired_Vehicles__c = oldlead.Desired_Vehicles__c.trim() + '; ' + newlead.Desired_Vehicles__c;
    			    vehicles = oldlead.Desired_Vehicles__c.trim() + '; ' + vehicles; // BLL3a
    		    } else {
    		    	// Adding a duplicate stock number, so just keep the old list
    		    	//BLL3d newlead.Desired_Vehicles__c = oldlead.Desired_Vehicles__c.trim();
    		    	vehicles = oldlead.Desired_Vehicles__c.trim();  // BLL3a
    		    }
    		    // BLL3a
    		    while(vehicles.length()>255 && vehicles.contains(';')) {
    		    	vehicles = vehicles.substring(vehicles.indexOf(';')+1).trim();
    		    }
    		    if (vehicles.length()>255) vehicles = vehicles.right(255); // drop off earlier/older information
    		    newlead.Desired_Vehicles__c = vehicles; 
    		    // BLL3a end
    		}
	
            if (busHours==null || busHours.Enabled__c || Test.isRunningTest()) {
	            // Elapsed queue and response times - raw & business hours
	            if (newlead.BusHrs_Time_In_Queue__c==null || newlead.BusHrs_Response_Time_BDC__c==null) {	
	  			    DateTime rightnow = DateTime.Now();
	  			    Long elapsed_msec = rightnow.getTime() - newlead.CreatedDate.getTime();
	  			    Integer elapsed_min = Math.min(99999, (Integer) ((elapsed_msec / 1000) / 60));
	                Long bh_elapsed_msec = BusinessHours.diff(bh.Id, newlead.CreatedDate, rightnow);
	  			    Integer bh_elapsed_min = Math.min(99999, (Integer) ((bh_elapsed_msec / 1000) / 60));
	  			
	  			
	    		    // Queue time (owner changed & haven't previously calculated queue time)
	    		    if ((newlead.BusHrs_Time_In_Queue__c==null) 
	    		        && (oldlead.OwnerId != newlead.OwnerId && newLead.OwnerId.getSObjectType()!=Schema.Group.SObjectType) ) {
	    			    newlead.Time_In_Queue__c = elapsed_min; 
	    			    newlead.BusHrs_Time_In_Queue__c = bh_elapsed_min; 
	    		    }
	    		    // Response time (activity recorded and response time not previously calculated)
	    		    if (newlead.BusHrs_Response_Time_BDC__c==null 
	    		        && newlead.Status=='Unqualified') {
	    			    newlead.Response_Time_BDC__c = elapsed_min; 
	    			    newlead.BusHrs_Response_Time_BDC__c = bh_elapsed_min;
	    		    } 
	            } 
	            
    	    } // busHours enabled
    	    
	        // Log original queue
	        if (originalQueue==null || originalQueue.Enabled__c || Test.isRunningTest()) {
        		// Original queue
        		if (Schema.Group.SObjectType==newlead.OwnerId.getSObjectType() 
        		    && String.isBlank(newlead.Lead_Queue_Name__c)) {
        			newlead.Lead_Queue_Name__c = queueMap.get(newlead.OwnerId);
        		}
        		// Rep who took off queue
        		if (Schema.User.SObjectType==newlead.OwnerId.getSObjectType()
        		   && Schema.Group.SObjectType==oldlead.OwnerId.getSObjectType()
        		   && String.isBlank(newlead.Responsible_Rep__c)) {
        			newlead.Responsible_Rep__c = newlead.OwnerId;
        			// catch after-the-fact if taken off a queue & queue name is still blank!
        			if (String.isBlank(newlead.Lead_Queue_Name__c)) {
        				newlead.Lead_Queue_Name__c = queueMap.get(oldlead.OwnerId);
        			}
        		}
	        } // originalQueue & rep    
    	    
    	} // end for each newly updated lead

		if (ialist.size()>0) Database.insert(ialist, false);	// BLL4a
    	
    } // end if isBefore && isUpdate 

    
    // BLL1a Ownership change
    if (Trigger.isAfter && Trigger.isUpdate) {
    	Set<Id> leads = new Set<Id>();
    	Map<Id, Id> oldowner = new Map<Id, Id>();
    	Map<Id, Id> newowner = new Map<Id, Id>();
    	for(Lead newlead : Trigger.new) {
            Lead oldlead = Trigger.oldMap.get(newlead.Id);
            if (oldlead!=null) {
            	if (oldlead.OwnerId != newlead.OwnerId) {
            		leads.add(newlead.Id);
            		oldowner.put(newlead.Id, oldlead.OwnerId);
            		newowner.put(newlead.Id, newlead.OwnerId);
            	}
            }
    	}
   	    	
    	// Tasks
    	List<Task> updTasks = new List<Task>();
    	for(Task t : [select Id, Subject, OwnerId, WhoId from Task where WhoId in :leads and Status!='Completed']) {
    		t.ownerId = newowner.get(t.WhoId);
    		if (t.ownerId!=null && t.ownerId.getSObjectType() != Schema.Group.SObjectType) {  // BLL2c
    			updTasks.add(t);
    		}
    	} // end for Task
        if (updTasks.size()>0) {
        	try {  // BLL2a ignore errors if owner is still a group
        		update(updTasks);
        	} catch(Exception e) {}  // BLL2a
        }
    	
    }
    // BLL1a end
    


}