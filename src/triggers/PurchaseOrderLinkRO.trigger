/**
 * PurchaseOrderLinkRO
 * Tested by: PurchaseOrderLinkRO_TC
 * 
 * Coverage:
 *	2017-10-17	89% (39/44)
 *
 *  2016-05-02  RedTeal     RT1 - if a PO line belongs to an RO line with an internal labor type, the customer total of the PO line should
 *                                be the same as the total amount of the PO line. 
 *  2016-06-17  B. Leaman   BLL1 IT#26798 - when a PO is moved to a different line of an RO, both old and new RO lines need to be updated.
 *                          Rewrite/bulkify after trigger section.
 *  2016-11-21  S. Utture   SSU1 #Case2198 - Update Parts Replenishment Date from recent purchase order accepted date
 *Case2198 commented out until reviewed.
 *  2017-10-16	B. Leaman	BLL2 - Don't query po lines where the job line is null -- causing apex limit warning about querying > 200000 rows.
 *	2019-07-15	W-000524	BLL3 - improve efficiency so tests can succeed.
 */

trigger PurchaseOrderLinkRO on dealer__Purchase_Order_Line__c (before insert, before update, after insert, after update) {
    //RT1
    if(trigger.isBefore) {
        List<Id> jobLineIds = new List<Id>();
        for(dealer__Purchase_Order_Line__c poLine : Trigger.new) {
            if (poLine.dealer__Service_Job_Line__c!=null) jobLineIds.add(poLine.dealer__Service_Job_Line__c);	// BLL2c
        }

        Map<Id, dealer__Service_Job__c> jobLinesMap = new Map<Id, dealer__Service_Job__c>([SELECT Id FROM dealer__Service_Job__c WHERE Id IN :jobLineIds AND dealer__Labor_Type__c = 'I']);
        if(jobLinesMap.values().size() > 0) {
            for(dealer__Purchase_Order_Line__c poLine : Trigger.new) {
                if(jobLinesMap.get(poLine.dealer__Service_Job_Line__c) != null) {
                    poLine.dealer__Customer_Total__c = poLine.dealer__Amount__c;
                }
            }
        }
    } //End RT1

    // BLL1
    if (trigger.isAfter) {

        // List of affected RO lines
        Set<Id> joblines = new Set<Id>();
        for (dealer__Purchase_Order_Line__c poline : Trigger.new) {
            dealer__Purchase_Order_Line__c oldpoline = (Trigger.oldMap!=null) ? Trigger.oldMap.get(poline.Id) : null;
			// BLL3 - only care about sublets!
			if (poline.RecordType__c=='Sublet' || (oldpoline!=null && oldpoline.RecordType__c=='Sublet')) {
			// BLL3 end
            	if (poline.dealer__Service_Job_Line__c!=null) joblines.add(poline.dealer__Service_Job_Line__c);	// BLL2c
            	if (oldpoline!=null && oldpoline.dealer__Service_Job_Line__c!=null) joblines.add(oldpoline.dealer__Service_Job_Line__c);
			// BLL3
			}
			// BLL3 end
        }
        
        // Sub all sublet POs for affected lines (sum by line)
        List<AggregateResult> sumsublets = new List<AggregateResult>();	// BLL3c
		// BLL3c - only query if there are sublets
		if (joblines.size()>0) sumsublets = [
            select dealer__Service_Job_Line__c, dealer__Service_Job_Line__r.dealer__Service_Repair_Order__c sroid, 
                sum(dealer__Amount__c) cost, sum(dealer__Customer_Total__c) total
            from dealer__Purchase_Order_Line__c 
            where dealer__Service_Job_Line__c in :joblines and RecordType__c='Sublet'
            group by dealer__Service_Job_Line__c, dealer__Service_Job_Line__r.dealer__Service_Repair_Order__c
        ];
        // Existing sublet totals on each RO line  
        Map<Id,dealer__Service_Job__c> jobMap = new Map<Id,dealer__Service_Job__c>([
            select Id, dealer__Sublet_Cost__c, dealer__Sublet_Total__c, dealer__Service_Repair_Order__c 
            from dealer__Service_Job__c
            where Id in :joblines
        ]);
        
        Set<Id> subletJobIds = new Set<Id>();
        List<dealer__Service_Job__c> updJobs = new List<dealer__Service_Job__c>();
        Map<Id,dealer__Service_Repair_Order__c> updROmap = new Map<Id,dealer__Service_Repair_Order__c>();
        // Update any RO lines whose sublet totals have changed
        for(AggregateResult ar : sumsublets) {
            System.debug(ar);
            Id joblineId = (Id) ar.get('dealer__Service_Job_Line__c');
            Id roId = (Id) ar.get('sroid');
            if (joblineId!=null) subletJobIds.add(joblineId);	// BLL2c (should not happen)
            Decimal newcost = (Decimal) ar.get('cost');
            Decimal newtotal = (Decimal) ar.get('total');
            dealer__Service_Job__c job = jobMap.get(joblineId);
            // only update the line & RO if the amounts have changed
            if (job!=null && (job.dealer__Sublet_Cost__c!=newcost || job.dealer__Sublet_Total__c!=newtotal)) {
                System.debug('Update job line: ' + joblineId);
                updJobs.add(new dealer__Service_Job__c(
                    Id=joblineId,
                    dealer__Sublet_Cost__c = (Decimal) ar.get('cost'),
                    dealer__Sublet_Total__c = (Decimal) ar.get('total')
                ));
                System.debug('Update RO: ' + roId);
                if (roId!=null) updROmap.put(roId, new dealer__Service_Repair_Order__c(Id=roId));	// BLL2c (should not happen?)
            } 
        }
        // Any RO lines without any POs anymore need to be reset
        for(dealer__Service_Job__c jline : jobMap.values()) {
            if (!subletJobIds.contains(jline.Id)) {
                System.debug('Update job line: ' + jline.Id);
                updJobs.add(new dealer__Service_Job__c(
                    Id=jline.Id,
                    dealer__Sublet_Cost__c = null,
                    dealer__Sublet_Total__c = null
                ));
                System.debug('Update RO: ' + jline.dealer__Service_Repair_Order__c);
                if (jline.dealer__Service_Repair_Order__c!=null) updROmap.put(jline.dealer__Service_Repair_Order__c, new dealer__Service_Repair_Order__c(Id=jline.dealer__Service_Repair_Order__c));	// BLL2c (dealer__Service_Repair_Order__c==null should not happen)
            }
        }
        
        if (updJobs.size()>0) update(updJobs);
        if (updROmap.size()>0) update(updROmap.values());	// BLL2? Doesn't updating the lines automatically update the ROs?
        
        
        //Case# 2198: Code added to update Replenishment Date for recent purchase order accepted date
/** BLL2d until reviewed again 
        Set<Id> partIds = new Set<Id>();
        for(dealer__Purchase_Order_Line__c objPartLine : Trigger.New){
            if (objPartLine.dealer__Part__c!=null) partIds.add(objPartLine.dealer__Part__c);	// BLL2c (should not happen)
        }     
              
        List<dealer__Parts_Inventory__c> parts = new List<dealer__Parts_Inventory__c>();
        for(dealer__Parts_Inventory__c objPart :[select id, dealer__Replenishment_Date__c,(select dealer__Part__c,dealer__Purchase_Order_Accepted_Date__c from dealer__Purchase_Order_Line__r order by createdDate desc limit 1) from dealer__Parts_Inventory__c where Id in : partIds and dealer__On_Hand__c>0]){
            if(objPart.dealer__Purchase_Order_Line__r!=null && objPart.dealer__Purchase_Order_Line__r.size()>0){
                objPart.dealer__Replenishment_Date__c = objPart.dealer__Purchase_Order_Line__r[0].dealer__Purchase_Order_Accepted_Date__c;
                if(objPart.dealer__Replenishment_Date__c!=null)
                    parts.add(objPart);
            }
        }
        if(parts.size()>0)
            update parts;
**/        
    }
    // BLL1a end
    
}