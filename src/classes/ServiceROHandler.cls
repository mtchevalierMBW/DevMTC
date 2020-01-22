/**
 * ServiceROHandler
 * Tested by: ServiceRepairOrder2_TC, TestTriggers, SROCreate_TC
 * Date: Jul 12, 2017
 * Programmer: Bryan Leaman
 *
 * Test coverage log:
 *	prior		78%
 *	2017-07-25	71% (182/254)
 *	2017-10-24	87% (226/258)
 *	2018-01-03	79% (205/259)
 *	2018-03-19	81% (213/262)
 *	2018-04-20	78% (206/262)
 *	2018-09-06	76% (220/288)
 *	2019-12-02	82%	(290/351)
 *
 *	Date		Developer	Description
 *	2017-07-13	B. Leaman	Create from ServiceROCalc trigger.
 *	2017-07-13	B. Leaman	BLL1 IR-0015235 Reset vehicle status from NFS to RFS when GetReady RO closes; 
 *								Don't change veh status when RFS;
 *								email alert to Anson when GetReady opened on RFS vehicle. 
 *	2017-07-13  J. Kuljis	JVK4 - Prevent posting of RO if Parts w/ Orders have not had a PO Associated.  If the PO is associated RO can not close until PO is received.
 *	2017-07-24	B. Leaman	BLL2 IR-0016527: only change to 'Ready For Sale' if priced, published and no open ROs.
 *	2017-08-08	B. Leaman	BLL3 - change updatevehicles to handle after delete context (no Trigger.new / newlist).
 *  2017-08-18  J. Kuljis	JVK5 - corrected query on ServiceMiscCharges to use indexed fields, avoiding the nonselective query error. The object had grown beyon 200K records.
 *	2017-10-23	B. Leaman	BLL4 - additional fields that are getting updated during post that must be permitted.
 *	2018-01-03	B. Leaman	BLL5 - Improve handling of WIP update.
 *	2018-03-19	B. Leaman	BLL6 - also update vehicle status for GetReady RO when vehicle is changed.
 *	2018-04-20	B. Leaman	BLL7 - use locationssingleton for service reporting user (RO owner)
 *	2018-05-02	B. Leaman	BLL8 - validate misc charges (need GL account) before invoice/post;
 *	2018-08-08	B. Leaman	BLL9 - Move update & email OUTSIDE the loop over trigger records in the updatevehicles method.
 *	2018-09-06	B. Leaman	BLL10 - automatically populate new header-level warranty account field on RO from first warranty job line.
 *	2018-10-02	B. Leaman	BLL11 - allow docutrack fields to be updated after posting (just in case).
 *	2018-10-15	B. Leaman	BLL12 IR-0041960 - don't send inventory team notice of GetReady on RFS vehicle if the group is empty (and remove Anson from the group, leaving it empty).
 *	2018-10-18	B. Leaman	BLL13 W-000461 - reduce SOQL queries by using singletons for unchanging data (organization).
 *	2018-11-12	B. Leaman	BLL14 W-000486 - Unable to re-open ROs after DT 4.14 upgrade. Change how to detect re-open.
 *	2019-05-02	B. Leaman	BLL15 W-000575 - Additional fields unprotected after posting due to recalculation
 *							when additional payments are recorded after posting.
 *	2019-05-24	B. Leaman	BLL16 W-000473 - set warranty deductible if missing (SWNW & client has "Active" MobilityGuard); 
 *							remove if it does not apply (No SWNW or no MobilityGuard at all (don't check exp. for removal in case of re-open old RO)).
 *	2019-08-09	B. Leaman	W-000734 BLL17 - support for last declined service date.
 *	2019-08-23	B. Leaman	W-000674 BLL18 - protect additional vehicle statuses from changes to NFS
 *	2019-09-24	B. Leaman	W-000730 BLL19 - reduce soql queries for new DealerTeam 5.x
 *	2019-11-11	B. Leaman	W-000730 BLL20 - error entering POS payments because dealer__taxable__c is being updated by DealerTeam.
 *	2019-12-02	B. Leaman	W-000783 BLL21 - separate close (posted) RO count as well as open RO count.
 *	2019-12-05	B. Leaman	W-000787 BLL22 - Copy lift & ramp info from service vehicle to RO when created or svc veh changed;
 *									 Copy back to service vehicle when posted;
 *	2019-12-18	B. Leaman	W-000788 BLL23 - improve SOQL efficiency
 */
public with sharing class ServiceROHandler {

	List<dealer__Service_Repair_Order__c> newList;
	Map<Id,dealer__Service_Repair_Order__c> oldMap;
	
	// BLL19 - static veh inv map so we don't need to requery if we already have all the vehicle records
	//Map<Id,dealer__Vehicle_Inventory__c> vehMap;
	static Map<Id, dealer__Vehicle_Inventory__c> vimap = new Map<Id, dealer__Vehicle_Inventory__c>();
	static Map<Id,dealer__Service_Job__c> svcJobMap = new Map<Id,dealer__Service_Job__c>();
	// BLL19 end
	// BLL23
	public static boolean AddingMiscCharges = false;
	static Set<Id> jobLineIds = new Set<Id>();
	static List<AggregateResult> MiscChgSummary = new List<AggregateResult>();
	static List<AggregateResult> JobLbrTypeSummary = new List<AggregateResult>();
	static List<AggregateResult> JobTechTimeSummary = new List<AggregateResult>();
	// BLL23 end
	Map<Id,dealer__Service_Repair_Order__c> rfsMap;
	Set<String> ClosedROSts = new Set<String>{'Void','Posted'};
	Set<String> ProtectedVehicleStatus = new Set<String>{'Sold - Not Delivered', 'Delivered', // BLL18c 'Ready For Sale' };	// BLL1c
		'Company Vehicle', 'Demo', 'Demo - Not for Sale', 'Rental', 'Rental - Not for Sale'};

	// BLL22
	private static Map<Id,dealer__Service_Vehicle__c> srvVehMap = new Map<Id,dealer__Service_Vehicle__c>();
	// BLL22 end

	// if needed: private static boolean warrdeductibleRan = false; 	// BLL16a

	//list of fields allowed to be updated
	// Just lastmodified* fields means an empty update (just to fire the trigger) & TaxPostDT/TaxCommitDT
	Set<String> allowedfieldupdates = new Set<String>{'lastmodifieddate','lastmodifiedbyid', 
		'taxpostdt__c','taxcommitdt__c','dealer__tax__c', 
		'dealer__status__c','dealer__internal_charges__c','dealer__posted_date_time__c','journal__c', 
		'dealer__customer_sublet_charges__c', 'dealer__discount_total__c',	
		'dealer__customer_misc_charges__c', 'dealer__internal_misc_charges__c', 'dealer__warranty_misc_charges__c',	// BLL4a
		'raisin_needs_update__c', 'raisin_sent_hash__c', 'raisin_last_sent_dt__c',	// BLL11 added
		'dealer__customer_charges__c','dealer__warranty_charges__c', 'internallaborrate__c',
		'total_collected__c', // BLL15
		'dealer__taxable__c', // BLL20
		'lift_mfg__c', 'lift_model__c', 'lift_serial_number__c', 'lift_cycle_count__c', // BLL22
		'dealer__lift_mfg__c', 'dealer__lift_model__c', 'dealer__lift_serial_number__c', 'dealer__lift_cycle_count__c', // BLL22
		'dealer__deposit__c', 'dealer__payments_total__c'	// BLL15
		}; 
        // added dealer__tax__c because we're not using it and it seems to change whether it needs to or not in sandbox


	// ServiceROHandler
	//---------------------------------------
	public ServiceROHandler(List<dealer__Service_Repair_Order__c> newL, Map<Id,dealer__Service_Repair_Order__c> oldM) {
		newList = newL;
		oldMap = oldM;
	}	// end constructor


	public void postROSalesTax() {
        Set<Id> postTaxRepairIds = new Set<Id>(); 
		for(dealer__Service_Repair_Order__c sro : newList) {
			dealer__Service_Repair_Order__c oldro = null;
			if (oldMap!=null) oldro = oldMap.get(sro.Id);
			if (sro.dealer__Status__c=='Posted' && sro.TaxPostDT__c==null && oldro!=null && oldro.dealer__Status__c!='Posted') {
   				System.debug('Post tax for repair ' + sro.Id);
   				postTaxRepairIds.add(sro.Id);
   			}
		}
       	System.debug(postTaxRepairIds);
       	if (postTaxRepairIds.size()>0) Avatax_MBW.postServiceFuture(postTaxRepairIds);
	}	// end postROSalesTax


	// BLL19
	// LoadServiceJobsForROs
	public void LoadServiceJobsForROs(Set<Id> roIds) {
		if (svcJobMap==null) svcJobMap = new Map<Id,dealer__Service_Job__c>();
		// ensure all existing & newly-needed RO Ids are included
		Set<Id> mappedROs = new Set<Id>();
		for(dealer__Service_Job__c sj : svcJobMap.values()) {
			if (sj.dealer__Service_Repair_Order__c!=null) mappedROs.add(sj.dealer__Service_Repair_Order__c);
		}
		if (roIds.size()>0 && !mappedROs.containsAll(roIds)) {
			roIds.addAll(mappedROs);
			svcJobMap = new Map<Id, dealer__Service_Job__c>([
				SELECT Id, dealer__Service_Repair_Order__c, Payment_Method__c, Payment_Method__r.Name, 
					Payment_Method__r.Payment_Type__c, Payment_Method__r.Warranty_Billing_Account__c
				FROM dealer__Service_Job__c 
				WHERE dealer__Service_Repair_Order__c IN:roIds
			]);
			// BLL23
			JobLbrTypeSummary  = [
				select dealer__Service_Repair_Order__c, dealer__Labor_Type__c, sum(dealer__Labor_Charges__c) lsum, sum(dealer__Parts_Total__c) psum, sum(dealer__Sublet_Total__c) ssum
				from dealer__Service_Job__c 
				where dealer__Service_Repair_Order__c  in :roIds 
				group by dealer__Service_Repair_Order__c, dealer__Labor_Type__c 
			];
			JobTechTimeSummary = [
				select dealer__Service_Job_Line__r.dealer__Service_Repair_Order__c roId, dealer__Service_Job_Line__r.dealer__Labor_Type__c paytype, 
					sum(dealer__Actual_Time_Entry__c) laborhours
				from dealer__Technician_Job_Time__c
				where dealer__Service_Job_Line__r.dealer__Service_Repair_Order__c  in :roIds 
				group by dealer__Service_Job_Line__r.dealer__Service_Repair_Order__c, dealer__Service_Job_Line__r.dealer__Labor_Type__c
			];
			// BLL23 end
		}

		// BLL23
		if (!jobLineIds.containsAll(svcJobMap.keySet()) || AddingMiscCharges==true) {
			jobLineIds.addAll(svcJobMap.keySet());
			MiscChgSummary = [
				select Service_Job_Line__r.dealer__Service_Repair_Order__c roName, 
                	Service_Job_Line__r.dealer__Labor_Type__c labortype, 
                	sum(Amount__c) msum 
				from ServiceMiscCharges__c 
				where Service_Job_Line__c in :jobLineIds //JVK5
				group by Service_Job_Line__r.dealer__Service_Repair_Order__c, Service_Job_Line__r.dealer__Labor_Type__c 
			];
			AddingMiscCharges = false;
		}
		// BLL23 end
	}
	// BLL19 end

	// BLL16
	// ApplyWarrantyDeductible
	//---------------------------------------
	public void ApplyWarrantyDeductible() {
		System.debug('ApplyWarrantyDeductible');
		// run only 1 time per request cycle
		// if (!warrdeductibleRan) {
		// 	warrdeductibleRan = true;			

		// list of ROs to update summary fields for
		Set<Id> roIds = new Set<Id>();
		Set<Id> svcVehIds = new Set<Id>();
		Set<Id> clientIds = new Set<Id>();
		for (dealer__Service_Repair_Order__c sro : newList) {
			if (sro.dealer__Status__c!='Posted') roIds.add(sro.Id);
			if (sro.dealer__Status__c!='Posted' && sro.dealer__Vehicle__c!=null) svcVehIds.add(sro.dealer__Vehicle__c);
			if (sro.dealer__Status__c!='Posted' && sro.dealer__Customer__c!=null) clientIds.add(sro.dealer__Customer__c);
		}
		System.debug(roids);
		
		// build map of ROs with NWAN on them
		Set<Id> roWithNWAN = new Set<Id>();
		// BLL19
		LoadServiceJobsForROs(roIds);
        //for(dealer__Service_Job__c sj : [
		//	SELECT Id, dealer__Service_Repair_Order__c, Payment_Method__c, Payment_Method__r.Payment_Type__c, 
		//		Payment_Method__r.Warranty_Billing_Account__c, Payment_Method__r.Name
		//	FROM dealer__Service_Job__c 
		//	WHERE dealer__Service_Repair_Order__c IN:roIds]) {
		for(dealer__Service_Job__c sj : svcJobMap.values()) {
		// BLL19
			if (sj.Payment_Method__r.Name=='SWNW') roWithNWAN.add(sj.dealer__Service_Repair_Order__c);
		}
		System.debug(roWithNWAN);
		
		// build map of service vehicles for the RO clients to mobilityguard service contracts
		Map<Id,dealer__Service_Contract__c> escMap = new Map<Id,dealer__Service_Contract__c>();
		for(dealer__Service_Contract__c esc : [
			select Id, Name, Active__c, dealer__Service_Vehicle__c, dealer__Customer__c, dealer__Deductable__c,
				dealer__Start_Date__c, dealer__End_Date__c, dealer__Expiration_Mileage__c, dealer__Expiration_Months__c,
				dealer__Odometer_at_Sale__c, dealer__Plan_Code__c, dealer__Product_Code__c,
				dealer__Status__c, dealer__Type__c
			from dealer__Service_Contract__c
			where dealer__Service_Vehicle__c in :svcVehIds
			  and dealer__Customer__c in :clientIds
			  and dealer__Plan_Code__c='MGP'
			order by dealer__Start_Date__c desc
		]) {
			System.debug(esc);
			if (!escMap.containsKey(esc.dealer__Service_Vehicle__c)) escMap.put(esc.dealer__Service_Vehicle__c, esc);
		}
		System.debug(escMap);

		// determin if RO should have a deductible or have it removed
		for(dealer__Service_Repair_Order__c ro : newlist) {
			dealer__Service_Contract__c esc = escMap.get(ro.dealer__Vehicle__c);
			boolean hasNWAN = roWithNWAN.contains(ro.Id);
			System.debug(esc);
			System.debug(hasNWAN);
			// add deductible if RO has NWAN and vehicle has active MGP on it for this customer
			if (ro.dealer__Warranty_Deductible__c==null && hasNWAN && esc!=null && esc.dealer__Status__c=='Active'
				&& ro.dealer__Customer__c==esc.dealer__Customer__c) {
				ro.dealer__Warranty_Deductible__c = esc.dealer__Deductable__c;
			}
			// remove deductible if no NWAN or no MGP at all (don't check active for removal to allow manual entry)
			if (ro.dealer__Status__c!='Posted' && ro.dealer__Warranty_Deductible__c!=null && (!hasNWAN || esc==null)) {
				ro.dealer__Warranty_Deductible__c = null;
			}
		} 

		//}

	}
	// BLL16 end

    /** JVK4a
     * ensureAllPartsOrdered - This Method provides a sanity check to validate that any parts sold negative are processed before the RO is Posted
     * 
     */
    public void ensureAllPartsOrdered() {
        Set<Id> roSanity = new set<Id>();
		for(dealer__Service_Repair_Order__c sro : newList) {
			dealer__Service_Repair_Order__c oldro = null;
			if (oldMap!=null) oldro = oldMap.get(sro.Id);
			if (sro.dealer__Status__c=='Posted' && oldro!=null && oldro.dealer__Status__c!='Posted') {
   				roSanity.add(sro.Id);
   			}
		}        
        
        if(!roSanity.isEmpty()) {
            for(dealer__Parts_Invoice_Line__c pil : [SELECT Id, dealer__Service_Repair_Order__c, dealer__Service_Repair_Order__r.Name, Parts_Order__c,
                                                     		dealer__Purchase_Order_Line__c, Parts_Order__r.dealer__Purchase_Order__c 	
                                                        FROM dealer__Parts_Invoice_Line__c 
                                                        WHERE dealer__Service_Repair_Order__c IN:roSanity]) {
                    
                    // If we have an Order Number but no PO, Error (pil.dealer__Purchase_Order_Line__c)
                    if(pil.Parts_Order__c!=null && pil.Parts_Order__r.dealer__Purchase_Order__c == null) {  
                        // Everything goes through the CPT so this should always catch if an Order Exists.
                        newList[0].addError(pil.dealer__Service_Repair_Order__r.Name +' contains parts requested to be ordered that have not been processed or have no Purchase Order assigned.  Please contact your CPT Coordinator.');
                    }
            }
        }        
    }


// BLL10a - also update RO header warranty account with first warranty found on job lines
// added here to eliminate a new SOQL query or DML operation.
public void rollupSummaryFields() {

		// Get Sum of Job Lines and Save
		System.debug('Query limit count: ' + String.valueOf(Limits.getQueries()) + ' Sum of Job lines ');

		// list of ROs to update summary fields for
		Set<Id> roIds = new Set<Id>();
		for (dealer__Service_Repair_Order__c sro : newList) roIds.add(sro.Id);
		
        // JVK5 - Get the assocaited Job Lines for selective query
		// BLL23 Set<Id> jobLineIds = new Set<Id>();
		Map<Id,Id> warrantyAcctIdMap = new Map<Id,Id>();	// BLL10a
		// BLL19
        LoadServiceJobsForROs(roIds);
		//for(dealer__Service_Job__c sj : [SELECT Id, dealer__Service_Repair_Order__c, Payment_Method__c, Payment_Method__r.Payment_Type__c, Payment_Method__r.Warranty_Billing_Account__c FROM dealer__Service_Job__c WHERE dealer__Service_Repair_Order__c IN:roIds]) {	// BLL10c
		for(dealer__Service_Job__c sj : svcJobMap.values()) {
		// BLL19 end
            // BLL23d if(!jobLineIds.contains(sj.Id)) { jobLineIds.add(sj.Id); }
            // BLL10a 
            if (sj.Payment_Method__r.Payment_Type__c=='W' && sj.Payment_Method__r.Warranty_Billing_Account__c!=null && !warrantyAcctIdMap.containsKey(sj.dealer__Service_Repair_Order__c))
            	warrantyAcctIdMap.put(sj.dealer__Service_Repair_Order__c, sj.Payment_Method__r.Warranty_Billing_Account__c);
            // BLL10a end 
        }
		// /JVK5
        
		// BLL19
		//if(Limits.getQueries() < 60 && !jobLineIds.isEmpty() /*JVK5 just the joblineIds size */) { 
		if(!jobLineIds.isEmpty() /*JVK5 just the joblineIds size */) { 
		// BLL19 end

			// summary queries bulkified - only 3 queries needed
			// Misc charges by pay type
			Map<String, Decimal> sumPayType = new Map<String, Decimal>();
			//BLL23 
			//for(AggregateResult ar1 : [
			//		select Service_Job_Line__r.dealer__Service_Repair_Order__c roName, 
            //    		Service_Job_Line__r.dealer__Labor_Type__c labortype, 
            //    		sum(Amount__c) msum 
			//		from ServiceMiscCharges__c 
			//		where Service_Job_Line__c in :jobLineIds //JVK5
			//		group by Service_Job_Line__r.dealer__Service_Repair_Order__c, Service_Job_Line__r.dealer__Labor_Type__c 
			//	]) {
			// BLL23 end
			for(AggregateResult ar1 : MiscChgSummary) {
				sumPayType.put((String) ar1.get('roName')+'-'+(String) ar1.get('labortype'), (Decimal) ar1.get('msum'));
			}
			System.debug(sumPayType);

			// Labor parts & sublet costs for all lines
			Map<String, Decimal> sumLabor = new Map<String, Decimal>();
			Map<String, Decimal> sumParts = new Map<String, Decimal>();
			Map<String, Decimal> sumSublet = new Map<String, Decimal>();
			// BLL23
			//for(AggregateResult ar2 : [
			//		select dealer__Service_Repair_Order__c, dealer__Labor_Type__c, sum(dealer__Labor_Charges__c) lsum, sum(dealer__Parts_Total__c) psum, sum(dealer__Sublet_Total__c) ssum
			//		from dealer__Service_Job__c where dealer__Service_Repair_Order__c  in :roIds 
			//		group by dealer__Service_Repair_Order__c, dealer__Labor_Type__c 
			//	]) {
			for(AggregateResult ar2 : JobLbrTypeSummary) {
			// BLL23 end
				String key = (String) ar2.get('dealer__Service_Repair_Order__c') + '-' + (String) ar2.get('dealer__Labor_Type__c');
				sumLabor.put(key, (Decimal) ar2.get('lsum'));
				sumParts.put(key, (Decimal) ar2.get('psum'));
				sumSublet.put(key, (Decimal) ar2.get('ssum'));
			}
			System.debug(sumLabor);
			System.debug(sumParts);
			System.debug(sumSublet);

			// Tech time by labor type 
			Map<String, Decimal> sumTechTime = new Map<String, Decimal>();
			// BLL23
			//for(AggregateResult ar3 : [
			//		select dealer__Service_Job_Line__r.dealer__Service_Repair_Order__c roId, dealer__Service_Job_Line__r.dealer__Labor_Type__c paytype, 
			//				sum(dealer__Actual_Time_Entry__c) laborhours
			//		from dealer__Technician_Job_Time__c
			//		where dealer__Service_Job_Line__r.dealer__Service_Repair_Order__c  in :roIds 
			//		group by dealer__Service_Job_Line__r.dealer__Service_Repair_Order__c, dealer__Service_Job_Line__r.dealer__Labor_Type__c
			//	]) {
			for(AggregateResult ar3 : JobTechTimeSummary) {
			// BLL23 end
				sumTechTime.put((String) ar3.get('roId') + '-' + (String) ar3.get('paytype'), (Decimal) ar3.get('laborhours'));
			}
			System.debug(sumTechTime);

			// Apply roll-up summary info
			for(dealer__Service_Repair_Order__c d : newList) {

				Decimal sumC = sumPayType.containsKey(d.id + '-C') ? sumPayType.get(d.Id+'-C') : 0.00;
				Decimal sumW = sumPayType.containsKey(d.id + '-W') ? sumPayType.get(d.Id+'-W') : 0.00;
				Decimal sumI = sumPayType.containsKey(d.id + '-I') ? sumPayType.get(d.Id+'-I') : 0.00;

				// BLL4a Semi-bulkified - BLL7 changed to bulkified
				Decimal laborC = sumLabor.containsKey(d.Id+'-C') ? sumLabor.get(d.Id + '-C') : 0.00;
				Decimal partC = sumParts.containsKey(d.Id+'-C') ? sumParts.get(d.Id + '-C') : 0.00;
				Decimal subletC = sumSublet.containsKey(d.Id+'-C') ? sumSublet.get(d.Id + '-C') : 0.00;
                    
				Decimal laborW = sumLabor.containsKey(d.Id+'-W') ? sumLabor.get(d.Id + '-W') : 0.00;
				Decimal partW = sumParts.containsKey(d.Id+'-W') ? sumParts.get(d.Id + '-W') : 0.00;
				Decimal subletW = sumSublet.containsKey(d.Id+'-W') ? sumSublet.get(d.Id + '-W') : 0.00;
                    
				Decimal laborI = sumLabor.containsKey(d.Id+'-I') ? sumLabor.get(d.Id + '-I') : 0.00;
				Decimal partI = sumParts.containsKey(d.Id+'-I') ? sumParts.get(d.Id + '-I') : 0.00;
				Decimal subletI = sumSublet.containsKey(d.Id+'-I') ? sumSublet.get(d.Id + '-I') : 0.00;

                    // begin summarize hours by pay type 
				Decimal hoursC = sumTechTime.containsKey(d.Id + '-C') ? sumTechTime.get(d.Id + '-C') : 0.00;
				Decimal hoursW = sumTechTime.containsKey(d.Id + '-W') ? sumTechTime.get(d.Id + '-W') : 0.00;
				Decimal hoursI = sumTechTime.containsKey(d.Id + '-I') ? sumTechTime.get(d.Id + '-I') : 0.00;
				d.LaborHoursCustomer__c = hoursC;
				d.LaborHoursWarranty__c = hoursW;
				d.LaborHoursInternal__c = hoursI;

				// Ensure all summary fields have a value (not null)
				if(sumC==null) sumC=0;
				if(sumW==null) sumW=0;
				if(sumI==null) sumI=0;

				if(laborC==null) laborC=0;
				if(laborW==null) laborW=0;
				if(laborI==null) laborI=0;

				if(partC==null) partC=0;
				if(partW==null) partW=0;
				if(partI==null) partI=0;

				if(subletC==null) subletC=0;
				if(subletW==null) subletW=0;
				if(subletI==null) subletI=0;

     
				System.debug('SRO Update Customer_Charges='+String.valueOf(d.dealer__Customer_Charges__c));
				if (d.dealer__Customer_Charges__c != (sumC + laborC + partC + subletC)) d.dealer__Customer_Charges__c = sumC + laborC + partC + subletC;
				System.debug('SRO Update Warranty_Charges='+String.valueOf(d.dealer__Warranty_Charges__c));
				if (d.dealer__Warranty_Charges__c != (sumW + laborW + partW + subletW)) d.dealer__Warranty_Charges__c = sumW + laborW + partW + subletW;
				System.debug('SRO Update Internal_Charges='+String.valueOf(d.dealer__Internal_Charges__c));
				if (d.dealer__Internal_Charges__c != (sumI + laborI + partI + subletI)) d.dealer__Internal_Charges__c = sumI + laborI + partI + subletI;

				// Toggle Open/Cashier based on whether any lines are open
				System.debug('Open lines = ' + String.valueOf(d.dealer__Open_Job_Lines__c) + ' of ' + String.valueOf(d.dealer__Number_of_Repair_Lines__c));
				if (d.dealer__Open_Job_Lines__c==0 && d.dealer__Number_of_Repair_Lines__c!=0 && d.dealer__Status__c=='Open') {
					d.dealer__Status__c = 'Cashier';
					System.debug('Set to cashier status');
				} else {
					if (d.dealer__Open_Job_Lines__c>0 && d.dealer__Status__c=='Cashier') {
						d.dealer__Status__c = 'Open';
						System.debug('Set to open status');
					}
				}

				// BLL10a - assign warranty account if there are warranty charges
				if (d.dealer__Warranty_Charges__c!=null && d.dealer__Warranty_Charges__c!=0) {
					d.dealer__Warranty_Account__c = warrantyAcctIdMap.get(d.Id);
				} else {	// otherwise remove warranty account reference
					d.dealer__Warranty_Account__c = null;
				}
				// BLL10a end


			}	// end for newList

		}	// end if Limits.getQueries()       

	}


	public void applyDiscount() {

		for(dealer__Service_Repair_Order__c d : newList) {
			// Check for Discount as a percentage 
			if(d.dealer__Discount_Type__c != null) {
				if(d.dealer__Customer_Charges__c==null) { d.dealer__Customer_Charges__c = 0;}
				if(d.dealer__Discount_Type__c=='5%') { d.dealer__Discount_Total__c = (d.dealer__Customer_Charges__c * -.05); }
				if(d.dealer__Discount_Type__c=='10%') { d.dealer__Discount_Total__c = (d.dealer__Customer_Charges__c * -.10); }
				if(d.dealer__Discount_Type__c=='15%') { d.dealer__Discount_Total__c = (d.dealer__Customer_Charges__c * -.15); }
				if(d.dealer__Discount_Type__c=='20%') { d.dealer__Discount_Total__c = (d.dealer__Customer_Charges__c * -.20); }
				if(d.dealer__Discount_Type__c=='25%') { d.dealer__Discount_Total__c = (d.dealer__Customer_Charges__c * -.25); }
				// BLL17
				if (d.dealer__Discount_Type__c.endsWith('20%')) d.dealer__Discount_Total__c = (d.dealer__Customer_Charges__c * -0.20); 	
				// BLL17 end 
				if (d.dealer__Discount_Total__c!=null) d.dealer__Discount_Total__c = d.dealer__Discount_Total__c.setScale(2, System.roundingMode.HALF_UP);  // BLL9a	// BLL12c only if not still null!
			}
		}	// end for newList
		
	}	// end applyDiscount


	public void protectPostedROs() {
		MW_TriggerControls__c roProtection = MW_TriggerControls__c.getInstance('RepairOrderProtect');
		boolean postProtected = true;
		if(roProtection!=null) postProtected = roProtection.Enabled__c;

		for(dealer__Service_Repair_Order__c r : newList) {
			dealer__Service_Repair_Order__c oldro = null;
			if (oldMap!=null) oldro = oldMap.get(r.Id);	// BLL12 moved outside if stmt
			// BLL14a
			boolean ReOpenRO = oldro!=null && oldro.dealer__Status__c=='Posted' && oldro.dealer__Posted_Date_Time__c!=null
				&& r.dealer__Status__c!='Posted' && r.dealer__Posted_Date_Time__c == null;
			//BLL14d if (oldro!=null && oldro.dealer__Posted_Date_Time__c !=null) {
			if (!ReOpenRO && oldro!=null && oldro.dealer__Posted_Date_Time__c !=null) {
			// BLL14 end
				// allow if it's an update with no real changes (just to fire trigger)!
				System.debug('List of changed fields');
				System.debug(SObjectChangedFields.getChangedFieldList(r, oldro));
				if (!SObjectChangedFields.OnlyAllowedFieldsChanged(r, oldro, allowedfieldupdates)) {
					System.debug(r.dealer__Status__c);
					System.debug(r.dealer__Posted_Date_Time__c);
					System.debug(oldro.dealer__Status__c);

					if(postProtected!=false) r.addError('Posted Repair Orders cannot be edited (' 
						+ JSON.serialize(SObjectChangedFields.getChangedFieldList(r, oldro)) +')');
				}	// end if onlyallowedfieldschanged


				if (oldro.dealer__Status__c=='Posted' && r.dealer__Status__c!=oldro.dealer__Status__c && r.dealer__Posted_Date_Time__c!=null
					&& r.dealer__Status__c!='GL Error') {	// BLL15c allow change to "GL Error"
					if(postProtected) r.addError('Posted Repair Orders cannot be re-opened by simply changing the status (' + r.dealer__Status__c + ')');	// BLL24c add status changing to value in msg
				}	// end if posted

			}	// end if dealer__Posted_Date_Time__c!=null
			
		}	// end for newList
		
	}	// end protectPostedROs
	
	
	public void protectDeleteWithCharges() {
		// Check the delete methods to ensure there can not be deletion of an RO with Line Totals
		for(dealer__Service_Repair_Order__c ro : oldMap.values()) {
			if(ro.dealer__Customer_Pay_Labor__c>0 
                    || ro.dealer__Customer_Pay_Parts__c>0
                    || ro.dealer__Customer_Sublet_Charges__c>0
                    || ro.dealer__Deposit__c>0
                    || ro.dealer__Internal_Charges__c>0
                    || ro.dealer__Hazardous_Materials__c>0
                    || ro.dealer__Shop_Supplies__c>0
                    || ro.dealer__Tax__c>0
                    || ro.dealer__Customer_Tax__c>0  
                    || ro.dealer__Warranty_Charges__c>0) {
				ro.addError('Delete Failed : Unable to Delete this Repair Order, charges still exist.');
			}
		}
	}	// end protectDeleteWithCharges
		
		
	public void protectLocation() {
		for(dealer__Service_Repair_Order__c s : newList) {
			dealer__Service_Repair_Order__c sro_old = null;
			if (oldMap!=null) sro_old = oldMap.get(s.Id);
			if(s.dealer__Company__c != null && sro_old!=null && s.dealer__Company__c != sro_old.dealer__Company__c) {
					s.addError('Repair order company location may not be changed once set.');
			}	// end if company changed
		}	// end for newList
	}
		
		
	// BLL8a
	// ValidateMiscCharges
	public void ValidateCompletedROs() {
		// Set of ROs being posted or invoiced
		Set<Id> roIds = new Set<Id>();
		for(dealer__Service_Repair_Order__c ro : newList) {
			dealer__Service_Repair_Order__c oldro = oldMap!=null ? oldMap.get(ro.Id) : null;
			if (oldro!=null && (ro.dealer__Status__c=='Posted' || ro.dealer__Status__c=='Invoiced')
				&& ro.dealer__Status__c!=oldro.dealer__Status__c) {
				roIds.add(ro.Id);
			}
		}
		// List of misc charges that will cause a problem with posting...
		Map<Id,String> problems = new Map<Id,String>();
		if (roIds.size()>0) {
			for(ServiceMiscCharges__c mc : [select Id, Type__c, Service_Job_Line__c, Service_Job_Line__r.Name,
				Service_Job_Line__r.dealer__Service_Repair_Order__c
				from  ServiceMiscCharges__c
				where Service_Job_Line__r.dealer__Service_Repair_Order__c in :roIds
				  and General_Ledger_Account__c=null
			]) {
				String txt = problems.get(mc.Service_Job_Line__r.dealer__Service_Repair_Order__c);
				if (txt==null) txt = '';
				else txt += '; ';
				txt += mc.Service_Job_Line__r.Name + ' : ' + mc.Type__c;
				problems.put(mc.Service_Job_Line__r.dealer__Service_Repair_Order__c, txt); 
			}
		}
		// Issue error messages on the RO, preventing move to invoiced or posted status
		for(dealer__Service_Repair_Order__c ro : newList) {
			String msg = problems.get(ro.Id);
			if (!String.isBlank(msg)) ro.addError('Invalid misc. charges on RO [' + msg +  ']');
		}		
	}
	// BLL8a end

	public void repairOrderDefaults() {
		User u = null;  
		Set<Id> acctIds = new Set<Id>(); 
		Map<Id, Account> acctmap = new Map<Id, Account>();
		Set<Id> companyIds = new Set<Id>();
		//BLL7d Map<Id, dealer__Dealer_Location__c> locations = new Map<Id, dealer__Dealer_Location__c>();		
		Set<Id> vehInvIds = new Set<Id>();	

		for(dealer__Service_Repair_Order__c sro : newList) {
			// BLL16 - set warranty deductible to null on insert!
			if (sro.Id==null) sro.dealer__Warranty_Deductible__c = null;
			// BLL16 end
			companyIds.add(sro.dealer__Company__c);
			if (sro.dealer__Vehicle_Inventory__c!=null) vehInvIds.add(sro.dealer__Vehicle_Inventory__c);
			dealer__Service_Repair_Order__c oldro = null;
			if (oldMap!=null) oldro = oldMap.get(sro.Id);
			// only if new or customer was changed!
			if ((oldro==null || oldro.dealer__Customer__c!=sro.dealer__Customer__c)) acctIds.add(sro.dealer__Customer__c);
		}	// end for newList

		// Referenced Accounts (used to assign person contact as buyer contact, if missing)
		if (acctIds.size()>0) acctmap = new Map<Id, Account>([select Id, Name, isPersonAccount, PersonContactId from Account where Id in :acctIds]); 

		// referenced locations with service reporting user (RO owner to assign)
		//BLL7d locations = new Map<Id, dealer__Dealer_Location__c>([SELECT Id, Service_Reporting_User__c, dealer__Company_Number__c FROM dealer__Dealer_Location__c WHERE Id IN :companyIds]);
		LocationsSingleton ls = LocationsSingleton.getInstance();	// BLL7a
		ls.addLocationIds(companyIds);	// BLL7a

		// map of referenced inventory veh with referenced service vehicles
		// BLL19 - reduce re-querying vehicle records
		//vehMap = new Map<Id,dealer__Vehicle_Inventory__c>(); 
		//if (vehInvIds.size()>0) {
		//	vehMap = new Map<Id,dealer__Vehicle_Inventory__c>([
		//		select Id, Name, dealer__Stock_Number__c,
		//			(select Id, Name, dealer__VIN__c from dealer__Service_Vehicles__r)
		//		from dealer__Vehicle_Inventory__c
		//		where Id in :vehInvIds
		//	]);
		//}
		LoadStockVehRcdMap(vehInvIds); 
		// BLL19

		// BLL22 - get all referenced service vehicles, cached as static variable to
		// eliminate redundant SOQL query on multiple invocations of trigger handler
		RetrieveServiceVehicles();
		// BLL22

		for(dealer__Service_Repair_Order__c sro : newList) {
			//BLL7d dealer__Dealer_Location__c location = locations.get(sro.dealer__Company__c);
			dealer__Dealer_Location__c location = ls.getLocationById(sro.dealer__Company__c);	// BLL7a
			if (location!=null) sro.dealer__Company_Number__c=location.dealer__Company_Number__c;	// BLL1a
			if(sro.dealer__Company_Number__c==''||sro.dealer__Company_Number__c==null) {
				if (u==null) u = CurrentUserSingleton.getInstance(); 
				System.debug(u); 
				sro.dealer__Company_Number__c=u.Division; 
			}
			// fill in contact when account is a person account
			Account a = acctmap.get(sro.dealer__Customer__c);
			System.debug(a);
			System.debug(sro.dealer__Customer_Contact__c);
			if (a!=null && a.isPersonAccount && sro.dealer__Customer_Contact__c!=a.PersonContactId) {
				sro.dealer__Customer_Contact__c = a.PersonContactId;
			}
			// owned by special user associated with the location so "My team" reporting works
			if(location != null && location.Service_Reporting_User__c != null && sro.OwnerId != location.Service_Reporting_User__c) {
				sro.OwnerId = location.Service_Reporting_User__c;
			}
			// supply related service vehicle if missing or not related to current inventory veh
			if (sro.dealer__Vehicle_Inventory__c!=null) {
				//BLL19
				//dealer__Vehicle_Inventory__c v = vehMap.get(sro.dealer__Vehicle_Inventory__c);
				dealer__Vehicle_Inventory__c v = vimap.get(sro.dealer__Vehicle_Inventory__c);
				// BLL19 end
				if (v!=null && v.dealer__Service_Vehicles__r!=null) {
					Set<Id> srvVeh = new Set<Id>();
					for(dealer__Service_Vehicle__c sv : v.dealer__Service_Vehicles__r) srvVeh.add(sv.Id);
					if (v.dealer__Service_Vehicles__r.size()>0 && (sro.dealer__Vehicle__c==null || !srvVeh.contains(sro.dealer__Vehicle__c))) {
						sro.dealer__Vehicle__c = v.dealer__Service_Vehicles__r[0].Id;
					}
				}	// end if v!=null
			}	// end if sro.dealer__Vehicle_Inventory__c!=null

			// BLL22 - copy service vehicle lift & ramp info into RO whenever service vehicle is changed
			// If they changed it manually, then change service vehicle, it'll be overwritten and need updated again
			dealer__Service_Repair_Order__c oldro = null;
			if (oldMap!=null) oldro = oldMap.get(sro.Id);
			if (sro.dealer__Vehicle__c!=null && (oldro==null || oldro.dealer__Vehicle__c!=sro.dealer__Vehicle__c)) {
				dealer__Service_Vehicle__c sv = srvVehMap.get(sro.dealer__Vehicle__c);
				if (sv!=null) {
					//sro.Lift_MFG__c = sv.Lift_MFG__c;
					sro.dealer__Lift_MFG__c = sv.Lift_MFG__c;
					//sro.Lift_Model__c = sv.Lift_Model__c;
					sro.dealer__Lift_Model__c = sv.Lift_Model__c;
					//sro.Lift_Serial_Number__c = sv.Lift_Serial_Number__c;
					sro.dealer__Lift_Serial_Number__c = sv.Lift_Serial_Number__c;
					//sro.Lift_Cycle_Count__c = sv.Lift_Cycle_Count__c;
					sro.dealer__Lift_Cycle_Count__c = sv.Lift_Cycle_Count__c;
					sro.MV_Ramp_Operation__c = sv.MV_Ramp_Operation__c;
					sro.Ramp_Location__c = sv.Ramp_Location__c;
					sro.MV_Ramp_Type__c = sv.MV_Ramp_Type__c;
				}
			}
			// BLL22 end

		}	// end for newList

	}	// end repairOrderDefaults
	

	// BLL19
	// LoadStockVehRcdMap - reduce re-querying same records
	public void LoadStockVehRcdMap(Set<Id> vehIds) {
		if (vimap==null) vimap = new Map<Id, dealer__Vehicle_Inventory__c>();
		if (vehIds.size()>0 && !vimap.keySet().containsAll(vehIds)) { 
			vehIds.addAll(vimap.keySet());	// ensure previously-queried records are included
			// BLL21
			//vimap = new Map<Id, dealer__Vehicle_Inventory__c>([
			//	select Id, Name, dealer__Stock_Number__c, dealer__Status_Code__c, dealer__Work_in_Process__c, Open_Service_Repair_Orders__c,
			//		dealer__Inventory_Date__c,	dealer__Status_Code_Assignment_Date__c,
			//		Images_Published__c, dealer__Publish_Vehicle_Info_To_Web__c, SuggestedRetailPrice__c, 
			//		(select Id, Name, dealer__VIN__c from dealer__Service_Vehicles__r),
			//		(SELECT Id FROM dealer__Service_Repair_Orders__r WHERE dealer__Status__c != 'Posted' AND dealer__Status__c != 'Void') 
			//	from dealer__Vehicle_Inventory__c 
			//	where Id in :vehIds
			//]);	
			vimap = new Map<Id, dealer__Vehicle_Inventory__c>([
				select Id, Name, dealer__Stock_Number__c, dealer__Status_Code__c, dealer__Work_in_Process__c, Open_Service_Repair_Orders__c, Posted_Service_Repair_Orders__c, 
					dealer__Inventory_Date__c,	dealer__Status_Code_Assignment_Date__c,
					Images_Published__c, dealer__Publish_Vehicle_Info_To_Web__c, SuggestedRetailPrice__c, 
					(select Id, Name, dealer__VIN__c from dealer__Service_Vehicles__r),
					(SELECT Id, dealer__Status__c FROM dealer__Service_Repair_Orders__r WHERE dealer__Status__c != 'Void') 
				from dealer__Vehicle_Inventory__c 
				where Id in :vehIds
			]);	
			// BLL21 end
		}	
	}	
	// BLL19 end

	// BLL22 - update service vehicle lift & ramp info when RO is posted
	private void RetrieveServiceVehicles() {
		System.debug('RetrieveServiceVehicles');
		Set<Id> srvVehIds = new Set<Id>(); // BLL22

		for(dealer__Service_Repair_Order__c sro : newList) {
			dealer__Service_Repair_Order__c oldro = null;
			if (oldMap!=null) oldro = oldMap.get(sro.Id);
			if (sro.dealer__Vehicle__c!=null 
				&& (oldro==null || oldro.dealer__Vehicle__c!=sro.dealer__Vehicle__c || oldro.dealer__Status__c!=sro.dealer__Status__c)) {
				srvVehIds.add(sro.dealer__Vehicle__c);
			}
		}	// end for newList

		if (srvVehIds.size()>0 && !srvVehMap.keySet().containsAll(srvVehIds)) {
			srvVehIds.addAll(srvVehMap.keySet());
			srvVehMap = new Map<Id, dealer__Service_Vehicle__c>([
				select Id, Lift_MFG__c, Lift_Model__c, Lift_Serial_Number__c, Lift_Cycle_Count__c, 
					MV_Ramp_Operation__c, Ramp_Location__c, MV_Ramp_Type__c
				from dealer__Service_Vehicle__c
				where Id in :srvVehIds
			]);
		}
		System.debug(srvVehMap);
	}

	// PostedROUpdatesSrvVeh
	public void PostedROUpdatesSrvVeh() {
		System.debug('PostedROUpdatesSrvVeh');
		Map<Id, dealer__Service_Vehicle__c> updSrvVehMap = new Map<Id, dealer__Service_Vehicle__c>();

		// BLL22 - get all referenced service vehicles, cached as static variable to
		// eliminate redundant SOQL query on multiple invocations of trigger handler
		RetrieveServiceVehicles();

		for(dealer__Service_Repair_Order__c sro : newList) {
			boolean updateSrvVeh = false;
			// BLL22 - copy service vehicle lift & ramp info to service vehicle when RO is posted
			dealer__Service_Repair_Order__c oldro = null;
			if (oldMap!=null) oldro = oldMap.get(sro.Id);
			System.debug(sro);
			System.debug(oldro);
			if (sro.dealer__Vehicle__c!=null && sro.dealer__Status__c=='Posted'
				&& (oldro==null || oldro.dealer__Status__c!='Posted')) {
				dealer__Service_Vehicle__c sv = srvVehMap.get(sro.dealer__Vehicle__c);
				System.debug(sv);
				if (sv!=null) {
					updateSrvVeh = sv.Lift_MFG__c != sro.dealer__Lift_MFG__c 
						|| sv.Lift_Model__c != sro.dealer__Lift_Model__c
						|| sv.Lift_Serial_Number__c != sro.dealer__Lift_Serial_Number__c
						|| sv.Lift_Cycle_Count__c != sro.dealer__Lift_Cycle_Count__c
						|| sv.MV_Ramp_Operation__c != sro.MV_Ramp_Operation__c
						|| sv.Ramp_Location__c != sro.Ramp_Location__c
						|| sv.MV_Ramp_Type__c != sro.MV_Ramp_Type__c;
					System.debug(updateSrvVeh);
					sv.Lift_MFG__c = sro.dealer__Lift_MFG__c; // dealer__Lift_MFG__c
					sv.Lift_Model__c = sro.dealer__Lift_Model__c;	// dealer__Lift_Model__c
					sv.Lift_Serial_Number__c = sro.dealer__Lift_Serial_Number__c;	// dealer__Lift_Serial_Number__c
					sv.Lift_Cycle_Count__c = sro.dealer__Lift_Cycle_Count__c;	// dealer__Lift_Cycle_Count__c
					sv.MV_Ramp_Operation__c = sro.MV_Ramp_Operation__c;
					sv.Ramp_Location__c = sro.Ramp_Location__c;
					sv.MV_Ramp_Type__c = sro.MV_Ramp_Type__c;
					if (updateSrvVeh) {
						updSrvVehMap.put(sv.Id, sv);
						System.debug(sv);
					}
				}
			}
		}
		// Update only if something needs updated
		System.debug(updSrvVehMap);
		if (updSrvVehMap.size()>0) update(updSrvVehMap.values());
	}
	// BLL22 end

	public void updateVehicles() {
		MW_TriggerControls__c VehicleStsGetRdy = MW_TriggerControls__c.getInstance('VehicleStsGetRdy');  // BLL21a
		
		// BLL3a
		List<dealer__Service_Repair_Order__c> sroList;
		if (newList!=null) sroList = newList;
		else if (oldMap!=null) sroList = oldMap.values();
		// BLL3a end
		
		// Build list of vehicles (vehicle inventory) referenced on ROs
		// Use same conditions used when deciding whether to update vehicle in building list, so if
		// none meet the criteria, the SOQL to retrieve the vehicles is not run.
		Set<Id> vehids = new Set<Id>();
		for(dealer__Service_Repair_Order__c ro : sroList) {	// BLL3c  newList
			if (ro.dealer__Vehicle_Inventory__c!=null) vehids.add(ro.dealer__Vehicle_Inventory__c);
			// Also need to adjust removed vehicles!
			dealer__Service_Repair_Order__c oldro = (oldMap!=null) ? oldMap.get(ro.Id) : null;
			if (oldro!=null && oldro.dealer__Vehicle_Inventory__c!=null && ro.dealer__Vehicle_Inventory__c!=oldro.dealer__Vehicle_Inventory__c) vehids.add(oldro.dealer__Vehicle_Inventory__c);
		}

		// BLL19 - remove duplication of soql queries during a single request
		LoadStockVehRcdMap(vehids);
		//Map<Id, dealer__Vehicle_Inventory__c> vimap = new Map<Id, dealer__Vehicle_Inventory__c>();
		//if (vehids.size()>0) vimap = new Map<Id, dealer__Vehicle_Inventory__c>([
		//	vimap = new Map<Id, dealer__Vehicle_Inventory__c>([
		//		select Id, Name, dealer__Status_Code__c, dealer__Work_in_Process__c, Open_Service_Repair_Orders__c,
		//			dealer__Inventory_Date__c,	dealer__Status_Code_Assignment_Date__c,
		//			Images_Published__c, dealer__Publish_Vehicle_Info_To_Web__c, SuggestedRetailPrice__c, 
		//			(SELECT Id FROM dealer__Service_Repair_Orders__r WHERE dealer__Status__c != 'Posted' AND dealer__Status__c != 'Void') 
		//		from dealer__Vehicle_Inventory__c 
		//		where Id in :vehids
		//]);		
		//BLL9d List<dealer__Vehicle_Inventory__c> updVehicle = new List<dealer__Vehicle_Inventory__c>();	
		Map<Id,dealer__Vehicle_Inventory__c> updVehicle = new Map<Id,dealer__Vehicle_Inventory__c>();
            
		for(dealer__Service_Repair_Order__c s : sroList) {	// BLL3c  newList
			boolean updateVehicle = false;	
			dealer__Service_Repair_Order__c oldro = (oldMap!=null) ? oldMap.get(s.Id) : null;
			dealer__Vehicle_Inventory__c v = s.dealer__Vehicle_Inventory__c!=null ? vimap.get(s.dealer__Vehicle_Inventory__c) : null;
			// BLL5a - Consolidate logic such that multiple updates on a posted RO won't update the vehicle unnecessarily
			Decimal customerCharges = s.dealer__Customer_Charges__c;
			// clear WIP charges if RO is changing to posted
			if (s.dealer__Status__c=='Posted' && oldro!=null &&  s.dealer__Status__c!=oldro.dealer__Status__c) 
				customerCharges = 0;
			// BLL5a end 
						  
			if(v!=null) { 
				//System.debug(s.Name + ':' + s.Id);
				//System.debug(v.Name + ':' + v.Id);
				// set vehicle WIP to the customer charges on this RO 
				if (v.dealer__Work_in_Process__c!=customerCharges) {	// BLL5c 
					System.debug('dealer__Vehicle_Inventory__c updated WIP from ' + String.valueOf(v.dealer__Work_in_Process__c) + ' to ' + String.valueOf(customerCharges));	// BLLc
					v.dealer__Work_in_Process__c = customerCharges;	// BLL5c
					// BLL1a ? clear WIP charges if RO is changing to posted
					//BLL5d if (s.dealer__Status__c=='Posted' && s.dealer__Status__c!=oldro.dealer__Status__c) 
					//BLL5d	v.dealer__Work_in_Process__c = 0;
					updateVehicle = true;	
				} 

				// BLL1a When RO is closed and it's a get-ready, restore vehicle status to "Ready For Sale" IFF it's "Not For Sale"
				// BLL18 only if not in a protected status!
				if (ClosedROSts.contains(s.dealer__Status__c) && s.dealer__Status__c!=oldro.dealer__Status__c
					&& v!=null && v.dealer__Status_Code__c=='Not For Sale'
					&& (s.GetReady_RO__c==true || s.CommercialConversionEquip__c==true)) {
					//BLL2a - additional checks
					if (v.Images_Published__c>0 && v.dealer__Publish_Vehicle_Info_To_Web__c==true && v.SuggestedRetailPrice__c!=null && v.SuggestedRetailPrice__c>0 && v.dealer__Service_Repair_Orders__r.size()==0) {
						if (v.dealer__Status_Code__c!='Ready For Sale') v.dealer__Status_Code_Assignment_Date__c = Date.today();	// BLL6a	
						v.dealer__Status_Code__c='Ready For Sale';
						updateVehicle = true;
					}	// BLL2a
				} 

				// update status to "Not For Sale" if RO is open & Changed to GetReady
				System.debug('RO Status=' + s.dealer__Status__c);
				if ((VehicleStsGetRdy==null || VehicleStsGetRdy.Enabled__c==true) && !ClosedROSts.contains(s.dealer__Status__c)) {
					System.debug(v.dealer__Status_Code__c);	// BLL6a
					System.debug('GetReady='+s.GetReady_RO__c + '/' + (oldro!=null ? String.valueOf(oldro.GetReady_RO__c) : 'null'));
					System.debug('CommercialConvEquip='+s.CommercialConversionEquip__c + '/' + (oldro!=null ? String.valueOf(oldro.CommercialConversionEquip__c) : 'null'));
					if (oldro!=null) System.debug('Veh='+oldro.dealer__Vehicle_Inventory__c+'/' + s.dealer__Vehicle_Inventory__c);
					if (oldro!=null && ((s.GetReady_RO__c==true && oldro.GetReady_RO__c==false)
						|| (s.CommercialConversionEquip__c==true && oldro.CommercialConversionEquip__c==false)
						|| (s.GetReady_RO__c==true && oldro.dealer__Vehicle_Inventory__c!=s.dealer__Vehicle_Inventory__c))) {	// BLL6a - *or* vehicle changed!
						updateVehicle = updateVehicle || !ProtectedVehicleStatus.contains(v.dealer__Status_Code__c);
						System.debug(updateVehicle);	// BLL6a
						if (v.dealer__Status_Code__c=='Ready For Sale') AddInventoryNotification(s);	// BLL1a
						if (!ProtectedVehicleStatus.contains(v.dealer__Status_Code__c)) {
							if (v.dealer__Status_Code__c!='Not For Sale') v.dealer__Status_Code_Assignment_Date__c = Date.today();	
							v.dealer__Status_Code__c = 'Not For Sale';
						}
						updateVehicle = updateVehicle || v.dealer__Inventory_Date__c==null;
                   		if (v.dealer__Inventory_Date__c==null) v.dealer__Inventory_Date__c = Date.today();
                   		System.debug('Update vehicle='+updateVehicle);
					}	// if changed to GetReady RO or Commercial Equipment RO
				}	// if getready updates to vehicle are enabled

				// update open RO count on vehicle
				// BLL21
				//if (v.Open_Service_Repair_Orders__c != v.dealer__Service_Repair_Orders__r.size()) {
				//	v.Open_Service_Repair_Orders__c = v.dealer__Service_Repair_Orders__r.size();
				//	updateVehicle = true;	
				//}	// end open RO count changed
				Integer openRO = 0;
				Integer postedRO = 0;
				for(dealer__Service_Repair_Order__c ro : v.dealer__Service_Repair_Orders__r) {
					if (ro.dealer__Status__c=='Posted') postedRO++;
					else openRO++;
				}
				if (v.Open_Service_Repair_Orders__c != openRO || v.Posted_Service_Repair_Orders__c != postedRO) {
					v.Open_Service_Repair_Orders__c = openRO;
					v.Posted_Service_Repair_Orders__c = postedRO;
					updateVehicle = true;	
				}	// end open RO count changed
				// BLL21 end

				// if vehicle is set for update, add to list of records to update
				//BLL9d if (updateVehicle && v!=null) updVehicle.add(v);
				if (updateVehicle && v!=null) updVehicle.put(v.Id,v);	// BLL9a

				// inventory vehicle changed...also need to update removed vehicle!
				if (oldro!=null && oldro.dealer__Vehicle_Inventory__c!=null && s.dealer__Vehicle_Inventory__c!=oldro.dealer__Vehicle_Inventory__c) {
					v = vimap.get(oldro.dealer__Vehicle_Inventory__c);
					if (v!=null) {
						// BLL21
						//v.Open_Service_Repair_Orders__c = v.dealer__Service_Repair_Orders__r.size();
						Integer openRO2 = 0;
						Integer postedRO2 = 0;
						for(dealer__Service_Repair_Order__c ro : v.dealer__Service_Repair_Orders__r) {
							if (ro.dealer__Status__c=='Posted') postedRO2++;
							else openRO2++;
						}
						if (v.Open_Service_Repair_Orders__c != openRO2 || v.Posted_Service_Repair_Orders__c != postedRO2) {
							v.Open_Service_Repair_Orders__c = openRO2;
							v.Posted_Service_Repair_Orders__c = postedRO2;
							updateVehicle = true;	
							updVehicle.put(v.Id, v);	// BLL9a
						}	// end open RO count changed
						// BLL21 end
						//BLL9d updVehicle.add(v);
						//BLL21d updVehicle.put(v.Id, v);	// BLL9a
					}
				}	// end if vehicle removed from RO

			}	// end if v!=null

            //BLL9d System.debug('Updating vehicle(s): ' + String.valueOf(updVehicle.size()));
            //BLL9d if (updVehicle.size()>0) System.debug(updVehicle[0]);
            //BLL9d if (updVehicle.size()>0) update(updVehicle); 

			//BLL9d NotifyInventoryTeam();	// BLL1a

        }	// end for sroList

		// BLL9a - was inside the loop over trigger records!
            System.debug('Updating vehicle(s): ' + String.valueOf(updVehicle.size()));
            if (updVehicle.size()>0) System.debug(updVehicle.values()[0]);
            if (updVehicle.size()>0) update(updVehicle.values()); 

			NotifyInventoryTeam();	// BLL1a

	}	// end updateVehicles


	// BLL1a inventory notifications of GetReady (or commercial equip) on a RFS vehicle
	public void AddInventoryNotification(dealer__Service_Repair_Order__c s) {
		if (rfsMap==null) rfsMap = new Map<Id,dealer__Service_Repair_Order__c>();
		rfsMap.put(s.Id, s);
	}	// end AddInventoryNotification
	
	public void NotifyInventoryTeam() {
		if (rfsMap==null) rfsMap = new Map<Id,dealer__Service_Repair_Order__c>();
		// BLL13a Organization org = [select Id, Name, isSandbox from Organization limit 1];
		Organization org = OrganizationSingleton.getInstance();	// BLL13a
		String subject = 'GetReady RO for RFS vehicle ';
		String message = '';
		// BLL13 only query to build sros if there are Ids to select!
		//List<dealer__Service_Repair_Order__c> sros = [
		//	select Id, Name, GetReady_RO__c, CommercialConversionEquip__c, dealer__Company__c, dealer__Company__r.Name,
		//		dealer__Vehicle_Inventory__c, dealer__Vehicle_Inventory__r.Name, 
		//		( select Id, Payment_Method__c, Payment_Method__r.Name, dealer__Concern__c, dealer__CustomerConcern__c,
		//			dealer__Standard_Operation_Code__c, dealer__Standard_Operation_Code__r.Name, dealer__Operation_Code_Description__c 
		//		  from dealer__Job_Lines__r
		//		)
		//	from dealer__Service_Repair_Order__c
		//	where Id in :rfsMap.keySet()
		//];
		List<dealer__Service_Repair_Order__c> sros = new List<dealer__Service_Repair_Order__c>();
		if (rfsMap.size()>0) sros = [
			select Id, Name, GetReady_RO__c, CommercialConversionEquip__c, dealer__Company__c, dealer__Company__r.Name,
				dealer__Vehicle_Inventory__c, dealer__Vehicle_Inventory__r.Name, 
				( select Id, Payment_Method__c, Payment_Method__r.Name, dealer__Concern__c, dealer__CustomerConcern__c,
					dealer__Standard_Operation_Code__c, dealer__Standard_Operation_Code__r.Name, dealer__Operation_Code_Description__c 
				  from dealer__Job_Lines__r
				)
			from dealer__Service_Repair_Order__c
			where Id in :rfsMap.keySet()
		];
		// BLL13 end
		if (sros.size()==1) {
			dealer__Service_Repair_Order__c sro = sros[0];
			subject = 'GetReady RO ' + sro.Name; 
			subject += ' for RFS vehicle ' + sro.dealer__Vehicle_Inventory__r.Name;
		} 

		Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
		for(dealer__Service_Repair_Order__c sro : sros) {
			message += sro.Name + ' at ' + sro.dealer__Company__r.Name;
			message += ' for vehicle ' + sro.dealer__Vehicle_Inventory__r.Name;
			message += '<br/>\r';
			for(dealer__Service_Job__c j : sro.dealer__Job_Lines__r) {
				message += j.dealer__Standard_Operation_Code__r.Name + ' : ' + j.dealer__Operation_Code_Description__c
					+ ' (' + j.Payment_Method__r.Name + ') ' + j.dealer__CustomerConcern__c + '<br/>\r';
			}
			message += '<br/>\r';
		}

		List<String> sendTo = new List<String>(Utility.getGroupMbrUserEmails('GetReady_RO_RFS_Veh_Notification'));
		//BLL12d if (sendTo.size()==0 || org.isSandbox) sendTo = new List<String>{UserInfo.getUserEmail()};
		if (sendTo.size()>0 && org.isSandbox) sendTo = new List<String>{UserInfo.getUserEmail()};	// BLL12a
		if (org.isSandbox) subject = 'Sandbox: ' + subject;
		mail.setToAddresses(sendTo);
		mail.setSubject(subject);
		mail.setHTMLBody(message);
		//BLL12d if (sros.size()>0) Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });		
		if (sros.size()>0 && sendTo.size()>0) Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });	// BLL12a
		
	}	// end NotifyInventoryTeam
	// BLL1a end
	
}