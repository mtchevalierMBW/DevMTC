/** Link Proposal to Slop on Upload - JPritt 10/2/2015 updated 12/15/15,12/29/15
 * Tested by: upload_Link_Proposal_to_SLOP_TEST
 * Uses MW_TriggerControls__c custom list settings : LinkToSlop
 */
trigger Upload_Link_Proposal_to_SLOP on dealer__Deal__c(before insert, before update) {
   if (Trigger.isBefore) {
      // System.debug('DEBUG LINK PROPOSAL TO SLOP');
      MW_TriggerControls__c LinkProposalToSlop = MW_TriggerControls__c.getInstance('LinkProposalToSlop');
      if (LinkProposalToSlop==null || LinkProposalToSlop.Enabled__c) {
         List<String> OppIDs = new List<String>();                      
         // get list of Opportunities to Link to
         for(dealer__deal__c d: Trigger.new) {
            String ref = d.legacy_Opportunity__c;
            if (!String.isblank(ref)) {
               OppIDs.add(ref);
               // System.debug('DEBUG Legacy Proposal=' + ref);
            }                  
         } // end for dealer__Deal__c 

         if (OppIDs.size()>0) {
            // generate Map to Slop
            Map<String,dealer__Sales_Up__c> slopmap = new Map<string,dealer__Sales_Up__c>();
            for(dealer__sales_up__c a:[select Id, Legacy_ID__c,OwnerID,dealer__Customer_Account__c,Company__c,dealer__Salesperson_1__c from dealer__sales_up__c 
                      where  Legacy_ID__c in :OppIDs]) {
              slopmap.put(a.Legacy_ID__c,a);
            }  // end-for
            // System.debug('DEBUG SLOP Map=' + slopmap);

            for(dealer__deal__c d : Trigger.new) {
                if (!String.isblank(d.Legacy_Opportunity__c)) { 
                    System.debug('Proposal/Deal=' + d.name);
                    if (slopmap.containsKey(d.legacy_opportunity__c)) {
                       dealer__sales_Up__c  slop  = slopmap.get(d.legacy_opportunity__c);
                        // System.debug('DEBUG SLOP ID:'+ slop.id);
                        if (Slop != Null)  {
                           d.OwnerID=slop.OwnerID; 
                           d.dealer__Salesperson_1__c=slop.dealer__Salesperson_1__c;
                           d.dealer__Store_Location__c=slop.Company__c;
                           d.dealer__Buyer__c=slop.dealer__Customer_Account__c;
                           d.dealer__Sales_Lead__c=slop.ID;
                        } // End-IF SLop !=Null
                    }  // end-if
                }   
            } // end-for dealer__deal__d trigger.new

         }  // end-if OppIDs.size>0
      } // end-of LinkToSlop==null
   } // end-if trigger.isbefore
} // end trigger