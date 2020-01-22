// Link Sales Appt  to Slop on Upload 
// Tested by: SalesAppointment_Trigger_TEST,UploadSalesAppt_TEST
// Created: 12/15/2015 JPritt
// Updated: 12/19/2015 JPritt Set select fields from SLOP
// 2015-12-22	B. Leaman	BLL1 - Add lookup to location to pull in and use GM if appt owner is not valid.
// 2016-07-05	B. Leaman	BLL2 - always clear out the upload owner!
//
// Uses MW_TriggerControls__c custom list settings : LinkApptToSlop
trigger Upload_Link_Sales_Appt_to_SLOP on dealer__Sales_Appointment__c(before insert, before update) {
   if (Trigger.isBefore) {

      MW_TriggerControls__c LinkApptToSlop = MW_TriggerControls__c.getInstance('LinkApptToSlop');
      if (LinkApptToSlop==null || LinkApptToSlop.Enabled__c || Test.isRunningTest()) {
         List<String> OppIDs = new List<String>();                      
		 Set<String> locSet = new Set<String>(); // BLL1a
		 Map<String,dealer__Dealer_Location__c> locMap = new Map<String,dealer__Dealer_Location__c>(); // BLL1a
		 Set<String> ownSet = new Set<String>(); // BLL1a
		 Map<String,User> ownMap = new Map<String,User>(); // BLL1a
         // get list of Opportunities to Link to
         for(dealer__Sales_Appointment__c d: Trigger.new) {
            String ref = d.legacy_Opportunity__c;
            if (!String.isblank(ref)) {
               OppIDs.add(ref);
               System.debug('SLOP = ' + ref);
            }
            if (!String.isBlank(d.Upload_Location__c)) locSet.add(d.Upload_Location__c); // BLL1a
            if (!String.isBlank(d.Upload_Owner__c)) ownSet.add(d.Upload_Owner__c); // BLL1a
         } // end for dealer__Sales_Appointment__c 

         Map<String,dealer__Sales_Up__c> slopmap = new Map<string,dealer__Sales_Up__c>();
         if (OppIDs.size()>0) {
            // generate Map to Slop
            for(dealer__sales_up__c a:[select Id, Legacy_ID__c,OwnerID,dealer__Buyer_Contact__c,dealer__CCC_Rep__c from dealer__sales_up__c 
                  where  Legacy_ID__c in :OppIDs]) {
              slopmap.put(a.Legacy_ID__c,a);
            }  // end-for
            // System.debug('SLOPMAP = ' + slopmap);
         }
         // BLL1a
         if (locSet.size()>0) {
			for(dealer__Dealer_Location__c l : [select Id, Name, dealer__General_Manager__c from dealer__Dealer_Location__c where Name in :locSet]) {
				locMap.put(l.Name, l);
			}
         }
         if (ownSet.size()>0) {
         	for(User u : [select Id, Name from User where Name in :ownSet]) {
         		ownMap.put(u.Name, u);
         	}
         }
         // BLL1a end
         for(dealer__Sales_Appointment__c d : Trigger.new) {
             // System.debug('Legacy Opportunity: ' + d.Legacy_Opportunity__c);
             if (!String.isblank(d.Legacy_Opportunity__c)) { 
                 if (slopmap.containsKey(d.legacy_opportunity__c)) {
                     dealer__sales_Up__c  slop  = slopmap.get(d.legacy_opportunity__c);
                     // System.debug('SLOP ID:'+ slop.id);
                     if (Slop != Null)  {
                           d.OwnerID=slop.OwnerID; 
                           d.dealer__Assigned_To__c=slop.OwnerID;
                           d.dealer__Customer__c=slop.dealer__Buyer_Contact__c;
                           d.dealer__Sales_up__c=slop.ID;
                           d.ccc_Rep__c=slop.dealer__CCC_Rep__c;
                     }
                 }  // end-if
             } // end-if Legacy_Opportunity__c is not blank
             // BLL1a - if AssignedTo is missing, use location GM
             if(!String.isBlank(d.Upload_Owner__c)) {
             	User own = ownMap.get(d.Upload_Owner__c);
             	if (own!=null) {
             		d.OwnerId = own.Id;
             		d.dealer__Assigned_To__c = own.Id;
             		System.debug('Assigned owner ' + d.Upload_Owner__c + ' id ' + own.Id);
             	} else if (!String.isBlank(d.upload_Location__c)) {
	            	dealer__Dealer_Location__c loc = locMap.get(d.upload_Location__c);
	            	System.debug('Set owner to location GM for ' + d.upload_Location__c);
	            	if (loc.dealer__General_Manager__c!=null) {
	            		d.OwnerId = loc.dealer__General_Manager__c;
	            		d.dealer__Assigned_To__c = loc.dealer__General_Manager__c;
	            		System.debug('Assigned GM user id ' + loc.dealer__General_Manager__c);
	            	}
	            }
             }
             d.Upload_Owner__c = null;	// BLL2a
             d.Upload_Location__c = null;	// BLL2a
             // BLL1a end
         } // end-for dealer__Sales_Appointment__c d trigger.new

      } // end-of LinkToSlop==null
   } // end-if trigger.isbefore
} // end trigger