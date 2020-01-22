/**
 * VehicleProcess
 * Tested by: VehicleProcess_TEST
 * Date: Mar 13, 2018
 * Programmer: Bryan Leaman
 *
 * Code coverage:
 *	2018-03-13	96% (199/206)
 *	2018-10-16	96%	(214/222)
 *	2019-01-22	96% (216/223)
 *	2019-08-19	91%	(228/250)
 *	2019-12-02	89%	(239/268)
 * 
 *-------------------- Mods from VehicleInventorySetCompanyNumber trigger ------------------
 * 2015-09-25   B. Leaman   BLL1 - Update GM from location. Used for workflow email to GM when SRP changes.
 *                          Since trigger will run before workflow, when SRP changes, the record will have
 *                          the latest GM on it.
 *  2015-11-11   RedTeal    RT1 - Changes to cost will also update the associated costs on deals
 *  2015-12-15  B. Leaman   BLL2 - prevent vehicle move (unless protected "FixVehicleLocation" flag is set). Always reset that flag!
 *                          Also keep company & company number in sync and Physical Location (if store location changes and physical location did not change)
 *  2016-05-16  B. Leaman   BLL3 - Fix RT1 - should not update posted deals, add trigger flag for easy disable in case needed.
 *  2016-07-27  B. Leaman   BLL4 - Use CurrentUserSingleton instead of SOQL.
 *  2016-09-15  B. Leaman   BLL5 - allow location to be set initially when creating from a template.
 *  2016-09-26  B. Leaman   BLL6 - Do not apply location restriction to templates.
 *  2016-09-28  B. Leaman   BLL7 - Assign location's "tech" as owner of the record so "My Team" works for vehicle inventory reports.
 *  2016-12-19  B. Leaman   BLL8 - Ease restriction on changing vehicle location to help with cloning templates.
 *  2017-02-01  B. Leaman   BLL9 - Don't update lost proposals.
 *  2017-04-06  B. Leaman   BLL10 - don't wipe out conversion cost if it's not on the vehicle yet. Issue with timing of these
 *                          costs showing up and conversion GP getting inflated (issue identified on converted commercial proposals).
 *  2017-04-24  B. Leaman   BLL11 - don't remove vehicle chassis cost from proposal (commercial, especially) just becuase inv. value is $0 or null.
 *  2017-08-07  B. Leaman   BLL12 - clean up unnecessary update if veh cost didn't change from what's on the proposals.
 *	2018-01-02	B. Leaman	BLL13 - implement location singleton.
 *	2018-03-30	B. Leaman	BLL14 - Set home location.
 *	2018-10-15	B. Leaman	BLL15 W-000456 - Change GE curtailment, 10% month 6, 2% 7-12, 78% month 13;
 *							Increase next curtailment pmt calcs to current + 3 months instead of current + 2 months.
 *	2019-01-22	B. Leaman	W-000562 BLL16 set AdministrativeUpdate flag for deal updates to prevent errors (Rental depreciation process).
 *	2019-07-25	B. Leaman	W-000727 BLL17 - fix null pointer exception when missing floored amount.
 *	2019-08-14	B. Leaman	W-000729 BLL18 - Sync conversion kit fields to vehicle whenever kit is assigned/re-assigned or flag set to re-sync.
 *	2019-12-02	B. Leaman	W-000783 BLL19 - separate close (posted) RO count as well as open RO count.
 *--------------------------------------------------------------------------------------------
 * 
 */
public with sharing class VehicleProcess {

	public List<dealer__Vehicle_Inventory__c> newList;
	public Map<Id, dealer__Vehicle_Inventory__c> newMap;
	public Map<Id, dealer__Vehicle_Inventory__c> oldMap;
	// BLL18
	public static Map<Id,dealer__Parts_Kit__c> convKitMap = new Map<Id,dealer__Parts_Kit__c>();
	public static Set<String> NewVehicle = new Set<String>{'New','Fleet','New/Used'};
	// BLL18 end

	private List<CurtailmentRule> CurtailmentRules;
	private List<String> paymentFields = new List<String>{'chassispayment__c','chassispayment_1__c','chassispayment_2__c','chassispayment_3__c'};

	// VehicleProcess
	//---------------------------------------
	public VehicleProcess(List<dealer__Vehicle_Inventory__c> nlist, Map<Id, dealer__Vehicle_Inventory__c> nmap, Map<Id, dealer__Vehicle_Inventory__c> omap) {
		newList = nlist;
		newMap = nmap;
		oldMap = omap;
	}

	// CalculatePayments
	//-------------------------------
	public void CalculatePayments() {
		for(dealer__Vehicle_Inventory__c v : newList) {
			CalculatePaymentsForVeh(v);
		}
	}


	// curtailment rule matching criteria:
	// Floorplan pattern: 'Huntington.*'
	// NewUsedOther pattern: '(Used|New/Used)'
	// Conv MFG pattern: '.*' 
	// Pmtschedule by month [0,0,0,0,0,10,10,10,10,10,10,40]	(10% mths 6-11, 40% mth 12)
	//                      [0,0,0,0,0,10,0,0,0,0,0,0,30,30,30]	(10% mth 6, 30% mths 13-15)
	//                      [0,0,0,0,10,0,0,0,0,0,90]			(10% mth 5, 90% mth 11) (GE counts floored date as month 1!)
	//						[]	(no curtailments)
	// rentals				[2, ....] (repeated 49 more times until 100%)
	// NOTE: If a bank that considers the flooring date as month 1 ALSO requires a partial pmt in month 1, this process must be rewritten slightly.	

	public class CurtailmentRule {
		public String Name;
		public String Floorplan;
		public String VehicleNUO;
		public String Status;
		public String ConversionMFG;
		public List<Decimal> PaymentSchedule;
		public transient Pattern pFloorplan; 
		public transient Pattern pVehicleNUO; 
		public transient Pattern pConversionMFG;
		public transient Pattern pStatus; 
	}

	public List<CurtailmentRule> RtvCurtailmentRules() {
		List<CurtailmentRule> rules = new List<CurtailmentRule>();
		CurtailmentRule rule;
		// note: on payment schedule, last value repeats as long as vehicle is listed as floorplanned,
		// so if schedule pays in full at the end, an additional 0 is needed in the list!
		rule = new CurtailmentRule();
			rule.Name='Huntington Used';
			//rule.Floorplan = 'Huntington(?:(?!Rental))*';	// Huntington NOT followed by "Rental"
			rule.Floorplan = 'Huntington (New|Used|PPV)';	
			rule.VehicleNUO = '.*';		// was 'Used|New/Used';
			//rule.Status = '(?:(?!Rental))*';	// NOT a rental
			rule.Status = '.*';	
			rule.ConversionMFG = '.*';
			rule.PaymentSchedule = new List<Decimal>{0,0,0,0,0,10,10,10,10,10,10,40};
			rules.add(rule);
		rule = new CurtailmentRule();
			rule.Name='Huntington Rental';
			rule.Floorplan = 'Huntington Rental';
			rule.VehicleNUO = '.*';
			rule.Status = 'Rental.*';
			rule.ConversionMFG = '.*';
			rule.PaymentSchedule = new List<Decimal>{2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2};
			rules.add(rule);
		rule = new CurtailmentRule();
			rule.Name='TCF - Braun';
			rule.Floorplan = 'TCF.*';
			rule.VehicleNUO = '.*';
			rule.Status = '.*';
			rule.ConversionMFG = 'Braun.*';
			rule.PaymentSchedule = new List<Decimal>{0,0,0,0,0,10,0,0,0,0,0,0,30,30,30};
			rules.add(rule);
		rule = new CurtailmentRule();
			rule.Name='GE - VMI';
			rule.Floorplan = 'GE.*';
			rule.VehicleNUO = '.*';
			rule.Status = '.*';
			rule.ConversionMFG = 'VMI.*';
			//BLL15d rule.PaymentSchedule = new List<Decimal>{0,0,0,0,10,0,0,0,0,0,90};
			rule.PaymentSchedule = new List<Decimal>{0,0,0,0,0,10,2,2,2,2,2,2,78};	 // BLL15a
			rules.add(rule);
		rule = new CurtailmentRule();
			rule.Name='Tempe';
			rule.Floorplan = 'Tempe.*';
			rule.VehicleNUO = '.*';
			rule.Status = '.*';
			rule.ConversionMFG = '.*';
			rule.PaymentSchedule = new List<Decimal>{0};
			rules.add(rule);

		CurtailmentRules = rules;
		for(CurtailmentRule r : CurtailmentRules) {
			r.pFloorplan = Pattern.compile(r.Floorplan);
			r.pVehicleNUO = Pattern.compile(r.VehicleNUO);
			r.pConversionMFG = Pattern.compile(r.ConversionMFG);
			r.pStatus = Pattern.compile(r.Status);
		}
		return rules;
	}


	// PaymentScheduleForVeh
	// Required fields from vehicle inventory record: 
	//	Floorplanned__c, Paid__c, Original_Floored_Amount__c, Current_Floored_Amount__c, 
	//	Chassis_Floorplan__c, Chassis_Floored_Date__c, Conversion_Floorplan__c, Conv_Floored_Date__c, 
	//	New_Used_Other__c, dealer__Status_Code__c, Conv_MFG__c,
	//	ChassisPayment__c, ChassisPayment_1__c, ChassisPayment_2__c
	//BLL15a ChassisPayment_3__c
	public List<Decimal> PaymentScheduleForVeh(dealer__Vehicle_Inventory__c v) {
		String Floorplan = v.Chassis_Floorplan__c==null ? '' : v.Chassis_Floorplan__c;
		String NewUsedOther = v.New_Used_Other__c==null ? '' : v.New_Used_Other__c;
		String Status = v.dealer__Status_Code__c==null ? '' : v.dealer__Status_Code__c;
		String ConversionMfg = v.Conv_MFG__c==null ? '' : v.Conv_MFG__c;
		System.debug(v.Name + ': ' + Floorplan + ',' + NewUsedOther + ',' + Status + ',' + ConversionMfg); 

		List<Decimal> pmtsched = null;
		if (CurtailmentRules==null || CurtailmentRules.size()==0) RtvCurtailmentRules();

		for(CurtailmentRule r : CurtailmentRules) {
			if (pmtsched==null) {	// Look only until the first match is found
				if ( r.pFloorplan.matcher(Floorplan).matches()
					&& r.pVehicleNUO.matcher(NewUsedOther).matches()
					&& r.pStatus.matcher(Status).matches()
					&& r.pConversionMFG.matcher(ConversionMfg).matches()
				) {
					System.debug('Found matching rule: ' + JSON.serialize(r));
					pmtsched = r.PaymentSchedule;
				} else 	System.debug('Rule did not match: ' + JSON.serialize(r));
			}
		}
		return pmtsched;
	} 


	// CalculatePaymentsForVeh
	//-----------------------------------
	public void CalculatePaymentsForVeh(dealer__Vehicle_Inventory__c v) {
		Date runDate = Date.today();
		List<Decimal> schedule = PaymentScheduleForVeh(v);
		System.debug(schedule);
		//BLL15d List<Decimal> nextPmts = new List<Decimal>{0,0,0};
		List<Decimal> nextPmts = new List<Decimal>();	// BLL15a increase to current + 3 months
		for(Integer i=0; i<paymentFields.size(); i++) nextPmts.add(0);	// same size as number of fields to store data in
		
		if (schedule!=null && v.Chassis_Floored_Date__c!=null) {
			Integer mth = v.Chassis_Floored_Date__c.monthsBetween(runDate);
			for(Integer i=0; i<nextPmts.size(); i++) {
				System.debug(mth+i);
				// return pct for month
				// BLL17
				//if (mth>0 && v.Floorplanned__c==true && v.Paid__c==false) {
				if (mth>0 && v.Floorplanned__c==true && v.Paid__c==false && v.Original_Floored_Amount__c!=null) {
				// BLL17 end 
					Decimal pct = (mth+i)<=schedule.size() ? schedule[mth+i-1] : 0;
					nextPmts[i] = v.Original_Floored_Amount__c * (pct/100);
					System.debug(nextPmts[i]);
				}  
			}
			// BLL15a moving toward soft-coding fields
			for(Integer n=0; n<paymentFields.size(); n++) {
				v.put(paymentFields[n], nextPmts[n]);
			}
			//v.ChassisPayment__c = nextPmts[0];
			//v.ChassisPayment_1__c = nextPmts[1];
			//v.ChassisPayment_2__c = nextPmts[2];
			//v.ChassisPayment_3__c = nextPmts[3];	// BLL15a
		}
	}


	// SynchronizeFields - copy custom to managed fields
	//------------------------------- 
	public void SynchronizeFields() {
	    for(dealer__Vehicle_Inventory__c veh : newList) {
	        // BLL1a - copy custom fields to managed ones
	        veh.dealer__Conv_Mfg__c = veh.Conv_Mfg__c;
	        veh.dealer__Conversion_Cost__c = veh.Conversion_Cost__c;
	        veh.dealer__Conversion_Model__c = veh.Conversion_Model__c;
	        veh.dealer__Interior__c = veh.Interior__c;
	        // formula veh.dealer__Location_Region__c = veh.Location_Region__c;
	        veh.dealer__MV_Ramp_Type__c = veh.MV_Ramp_Type__c;
	        veh.dealer__MV_Ranp_Operation__c = veh.MV_Ranp_Operation__c;
	        veh.dealer__New_Used_Other__c = veh.New_Used_Other__c;
	        veh.dealer__Ramp_Location__c = veh.Ramp_Location__c;
	        // formula veh.dealer__Suggested_Retail_Price__c = veh.Suggested_Retail_Price__c;
	        veh.dealer__SuggestedRetailPrice__c = veh.SuggestedRetailPrice__c;
	        // formula veh.dealer__Total_Vehicle_Cost__c = veh.Total_Vehicle_Cost__c;
	        veh.dealer__Unit_Type__c = veh.Unit_Type__c;
	        // BLL1a end
	    }
	}


	// StandardizeColor 
	//------------------------------- 
	public void StandardizeColor() {
   	     Schema.DescribeFieldResult makePickList = dealer__Vehicle_Inventory__c.Make_Color_Filter__c.getDescribe();
   	     List<Schema.PicklistEntry> mPickValues = makePickList.getpicklistvalues();

	    for(dealer__Vehicle_Inventory__c veh : newList) {
   	    	dealer__Vehicle_Inventory__c oldveh = oldMap!=null ? oldMap.get(veh.Id) : null;  
			// ACB1
			// Update Custom Make picklist from Managed Make field
			Integer found; found = 0;
			for (Schema.PicklistEntry mPickVal : mPickValues) {
				if (mPickVal.getValue() == veh.dealer__Make__c) {
					veh.Make_Color_Filter__c = veh.dealer__Make__c;
					found = 1; //set var if we found match
				}
			}
			if (found == 0) { //if not match found we set picklist to Other
				veh.Make_Color_Filter__c = 'Other';
			}
			// Update Exterior Color field if Exterior Color picklist has changed
			if (oldveh != null && oldveh.Exterior_Color__c != veh.Exterior_Color__c && oldveh.dealer__Exterior_Color__c == veh.dealer__Exterior_Color__c) {
				veh.dealer__Exterior_Color__c = veh.Exterior_Color__c;
			}
			// ACB1 end
	    }		
	}


	// CalculatePaymentDueDate 
	//------------------------------- 
	public void CalculatePaymentDueDate() {
    	BusinessHours bh = null;
    
    	for(dealer__Vehicle_Inventory__c veh : newList) {
   	    	dealer__Vehicle_Inventory__c oldveh = oldMap!=null ? oldMap.get(veh.Id) : null;  
        
    	    if (veh.dealer__Sale_Date__c!=null && veh.PaymentDueDays__c!=null && veh.PaymentDueDays__c>0
    	        && (veh.PaymentDueDate__c==null 
    	        	|| (oldveh!=null && (veh.dealer__Sale_Date__c!=oldveh.dealer__Sale_Date__c || veh.PaymentDueDays__c!=oldveh.PaymentDueDays__c)))	// BLL3c
    	        ) {

    	        // Get the bank schedule (work days M-F & bank holidays)
    	        try {
    	            if(bh==null) bh = [select id from businesshours where Name='BankDays' limit 1];
    	        } catch(Exception e){
    	            bh = new BusinessHours();
    	        }

    	        if (bh!=null && bh.Id!=null) {
    	            Datetime deliverydt = Datetime.newInstanceGmt(veh.dealer__Sale_Date__c, Time.newInstance(12,0,0,0));
    	            System.debug(deliverydt);
    	            System.debug(veh.PaymentDueDays__c);
    	            // 1 hour less so we don't move too far if delivered on a non-work day
    	            Long ms = (Long) (veh.PaymentDueDays__c * 24L -1L) * 60L * 60L * 1000L;
    	            DateTime duedt = BusinessHours.addGmt(bh.Id, deliverydt, ms);
    	            System.debug(duedt);
    	            veh.PaymentDueDate__c = duedt.date(); 
    	        } // end if have bankdays businesshours

    	    } // end if have sale date and payment due days or change in either

    	}		
	}


	// CountOpenROs
	//------------------------------- 
	public void CountOpenROs() {
		Set<Id> vehIds = new Set<Id>();
		for(dealer__Vehicle_Inventory__c v : newList) if (v.Id!=null) vehIds.add(v.Id);

	    // BLL2a
    	Map<Id, dealer__Vehicle_Inventory__c> vehMap = new Map<Id,dealer__Vehicle_Inventory__c>();
    	if (vehIds.size()>0) {
			// BLL19
    		//vehMap = new Map<Id,dealer__Vehicle_Inventory__c>([
			//	select Id, dealer__Status_Code__c, Open_Service_Repair_Orders__c,
			//		(SELECT Id FROM dealer__Service_Repair_Orders__r WHERE dealer__Status__c != 'Posted' AND dealer__Status__c != 'Void') 
			//	from dealer__Vehicle_Inventory__c 
			//	where Id in :vehIds
    		//]);
    		vehMap = new Map<Id,dealer__Vehicle_Inventory__c>([
				select Id, dealer__Status_Code__c, Open_Service_Repair_Orders__c, Posted_Service_Repair_Orders__c, 
					(SELECT Id, dealer__Status__c FROM dealer__Service_Repair_Orders__r WHERE dealer__Status__c != 'Void') 
				from dealer__Vehicle_Inventory__c 
				where Id in :vehIds
    		]);
			// BLL19 end
    	}
    	// BLL2a end
    
		// BLL2a
		for(dealer__Vehicle_Inventory__c veh : newList) {
			dealer__Vehicle_Inventory__c v = vehMap.get(veh.Id);
			if (v!=null && v.dealer__Service_Repair_Orders__r!=null) { 
				// BLL19
				//veh.Open_Service_Repair_Orders__c = v.dealer__Service_Repair_Orders__r.size();
				Integer openRO = 0;
				Integer postedRO = 0;
				for(dealer__Service_Repair_Order__c ro : v.dealer__Service_Repair_Orders__r) {
					if (ro.dealer__Status__c=='Posted') postedRO++;
					else openRO++;
				}
				veh.Open_Service_Repair_Orders__c = openRO;
				veh.Posted_Service_Repair_Orders__c = postedRO;
				// BLL19 end
			}
		}
		// BLL2a end
	}
	
	// UpdateDealVehicleCosts
	//----------------------------------
	public void UpdateDealVehicleCosts() {
		Set<Id> changedIds = new Set<Id>();
     
		for(dealer__Vehicle_Inventory__c veh : newList) {
            dealer__Vehicle_Inventory__c oldVehicle = oldMap!=null ? oldMap.get(veh.Id) : null;
            if(oldVehicle!=null && (veh.Conversion_Cost__c!=oldVehicle.Conversion_Cost__c || veh.dealer__Vehicle_Cost__c != oldVehicle.dealer__Vehicle_Cost__c)) {
                changedIds.add(veh.Id);
            }
		}
     
    	//RT1
    	List<dealer__Deal__c> deals = new List<dealer__Deal__c>();
        	MW_TriggerControls__c updDealVehCosts = MW_TriggerControls__c.getInstance('UpdateDealVehCosts');    // BLL3a
    	if(!changedIds.isEmpty()) {
	        deals = [
            	SELECT Id, Conversion_Cost__c, Chassis_Cost__c, dealer__Vehicle__c 
            	FROM dealer__Deal__c 
            	WHERE dealer__Vehicle__c IN :changedIds
            	  AND dealer__Status__c!='Won - Posted' AND dealer__Status__c!='Lost'   // BLL3a, BLL9c
        	];
    	}
        List<dealer__Deal__c> updDeals = new List<dealer__Deal__c>();   // BLL12a        
		for(dealer__Deal__c deal : deals) {
			dealer__Vehicle_Inventory__c vehicle = newMap!=null ? newMap.get(deal.dealer__Vehicle__c) : null;
			Decimal newConvCost = null; // BLL12a
			Decimal newChassisCost = null;  // BLL12a
			boolean updateDeal = false; // BLL12a
			// BLL12d
			//if(vehicle.Conversion_Cost__c!=null && vehicle.Conversion_Cost__c!=0) deal.Conversion_Cost__c = vehicle.Conversion_Cost__c;   // BLL10a
			//if(vehicle.dealer__Vehicle_Cost__c!=null && vehicle.dealer__Vehicle_Cost__c!=0) deal.Chassis_Cost__c = vehicle.dealer__Vehicle_Cost__c;   // BLL11c
			// BLL12a
			if(vehicle.Conversion_Cost__c!=null && vehicle.Conversion_Cost__c!=0) newConvCost = vehicle.Conversion_Cost__c;
			if(vehicle.dealer__Vehicle_Cost__c!=null && vehicle.dealer__Vehicle_Cost__c!=0) newChassisCost = vehicle.dealer__Vehicle_Cost__c;
			updateDeal = (newConvCost!=null && newConvCost!=deal.Conversion_Cost__c)
					|| (newChassisCost!=null && newChassisCost!=deal.Chassis_Cost__c);
			if (updateDeal) {
				dealer__Deal__c updd = new dealer__Deal__c(Id=deal.Id);
				if (newConvCost!=null) updd.Conversion_Cost__c=newConvCost;
				if (newChassisCost!=null) updd.Chassis_Cost__c=newChassisCost;
				// BLL16
				updd.AdministrativeUpdate__c = true;
				// BLL16 end
				updDeals.add(updd);
			} 
			// BLL12a end
		}
		//BLL12d if (updDealVehCosts==null || updDealVehCosts.Enabled__c==true) update deals;        // BLL3c add condition
		// BLL16d if (updDeals.size()>0 && (updDealVehCosts==null || updDealVehCosts.Enabled__c==true)) update(updDeals); // BLL12a
		if (updDeals.size()>0 && (updDealVehCosts==null || updDealVehCosts.Enabled__c==true)) Database.update(updDeals, false); // BLL16a
    	//RT1 end   

	}
	
	
	// VehicleLocationAndOwner
	//----------------------------------
	public void VehicleLocationAndOwner() {
    	User u = CurrentUserSingleton.getInstance(); //BLL4c [Select Id, Division from User where Id=:UserInfo.getUserId() limit 1];
    	System.debug(u); // BLL4a

    	// BLL1a Get location info for each vehicle's location
    	Set<Id> locIds = new Set<Id>();
    	Map<Id, dealer__Dealer_Location__c> locmap = new Map<Id, dealer__Dealer_Location__c>();
    
    	// BLL2a
    	MW_TriggerControls__c restrictVehicleLocation = MW_TriggerControls__c.getInstance('RestrictVehicleLocation');
    	Set<String> locAbbrevs = new Set<String>(); // BLL2a location abbreviations
    	Map<String,dealer__Dealer_Location__c> locAbbvMap = new Map<String,dealer__Dealer_Location__c>(); // BLL2a locations by abbrev
    	// BLL2a end 
    
	    for(dealer__Vehicle_Inventory__c veh : newList) {
	        if (veh.dealer__Store_Location__c!=null) locIds.add(veh.dealer__Store_Location__c);
	        if (!String.isBlank(veh.dealer__Company_Number__c)) locAbbrevs.add(veh.dealer__Company_Number__c);  // BLL2a
	        if (String.isBlank(veh.dealer__Company_Number__c) && veh.dealer__Store_Location__c==null) locAbbrevs.add(u.Division);
	    }
	    // BLL13a
	    LocationsSingleton ls = LocationsSingleton.getInstance();
	    ls.addLocationIds(locIds);
	    ls.addLocationAbbrevs(locAbbrevs);
		// not needed ls.retrieveLocations();
		//if (locIds.size()>0) {
		//	locmap = ls.getLocationIdMap();	// BLL13a
		//locmap = new Map<Id, dealer__Dealer_Location__c>([
        //    select Id, Name, dealer__General_Manager__c, dealer__Company_Number__c,  // BLL2c add Company Nbr
        //        Service_Reporting_User__c // BLL7a
        //    from dealer__Dealer_Location__c
        //    where Id in :locIds
        //]);
		//}
		// BLL1a end

		// BLL2a add locations by abbreviation
		//if (locAbbrevs.size()>0) {
		//    for(dealer__Dealer_Location__c l : [
		//        select Id, Name, dealer__Company_Number__c
		//        from dealer__Dealer_Location__c
 		//        where dealer__Company_Number__c in :locAbbrevs
		//        ]) {
		//        locAbbvMap.put(l.dealer__Company_Number__c, l);
		//    }
		//}
		// BLL2a end

    	Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.dealer__Vehicle_Inventory__c.getRecordTypeInfosById(); // BLL6a
    	for(dealer__Vehicle_Inventory__c v : newList) {

   	    	dealer__Vehicle_Inventory__c oldveh = oldMap!=null ? oldMap.get(v.Id) : null;		// BLL14a
   	    	  
    	    if( v.dealer__Company_Number__c=='' || v.dealer__Company_Number__c==null) {
    	        v.dealer__Company_Number__c=u.Division;
    	        System.debug('Set company to user division: ' + u.Division);
    	    }
    	    // BLL1a assign GM of location to vehicle
    	    dealer__Dealer_Location__c loc = v.dealer__Store_Location__c!=null ? ls.getLocationById(v.dealer__Store_Location__c) : null;	// BLL13c locmap.get(v.dealer__Store_Location__c);
    	    System.debug(loc);
    	    Schema.RecordTypeInfo rtinfo = rtMapById.get(v.RecordTypeId);   // BLL8a
    	    if (loc!=null && rtinfo!=null && !rtinfo.getName().contains('Template')) {  // BLL8c - don't set on templates
    	        v.Location_GM_lastupd__c = loc.dealer__General_Manager__c;
    	        System.debug('Set Location GM last update to ' + v.Location_GM_lastupd__c);
    	    } else {
    	        v.Location_GM_lastupd__c = null;
    	        System.debug('Remove Location GM last update');
    	    }
    	    // BLL1a end
	
        	// BLL2a keep company number and store location in sync (no matter which one changed)
        	dealer__Vehicle_Inventory__c oldv = null;
        	if (oldMap!=null) oldv = oldMap.get(v.Id);
        	// If store location is not missing and company number is missing or the store location has been set or changed, set company number
        	//BLL13d dealer__Dealer_Location__c locinfo = null;
        	//BLL13d if (v.dealer__Store_Location__c!=null) locinfo = locMap.get(v.dealer__Store_Location__c);
        	System.debug(v.dealer__Company_Number__c);
        	if (oldv!=null) System.debug(oldv.dealer__Company_Number__c);
        	System.debug(v.dealer__Store_Location__c);
        	if (oldv!=null) System.debug(oldv.dealer__Store_Location__c);
        	if (loc!=null	// BLL13c was locinfo  
        	    && (v.dealer__Company_Number__c==null || oldv==null || oldv.dealer__Store_Location__c!=v.dealer__Store_Location__c)) {
        	    v.dealer__Company_Number__c = loc.dealer__Company_Number__c; 
				System.debug('Set vehicle company number to ' + v.dealer__Company_Number__c);
        	}
        	// If company number is not missing and store location is missing or the company number has been set or changed, set store location
        	if (v.dealer__Company_Number__c!=null && (v.dealer__Store_Location__c==null || oldv==null || oldv.dealer__Company_Number__c!=v.dealer__Company_Number__c)) {
        	    //dealer__Dealer_Location__c store = ls.getLocationByAbbreviation(v.dealer__Company_Number__c);	// BLL13d locAbbvMap.get(v.dealer__Company_Number__c);
        	    loc = ls.getLocationByAbbrev(v.dealer__Company_Number__c);
        	    if (loc!=null) v.dealer__Store_Location__c = loc.Id;	// BLL13a
				if (loc!=null) System.debug('Set vehicle store location to ' + loc.Name);
				if (loc==null) System.debug('Cannot set vehicle store location - not found');
        	    //BLL13d if (store!=null) v.dealer__Store_Location__c = store.Id;
        	    //BLL13d locinfo = locMap.get(v.dealer__Store_Location__c); // reset so next test has the new location info
        	}
        	// Always make sure company number is for the assigned store location!
        	if (loc!=null && v.dealer__Company_Number__c!=loc.dealer__Company_Number__c) {
        	    v.dealer__Company_Number__c = loc.dealer__Company_Number__c;
        	    System.debug('Set vehicle company number to ' + v.dealer__Company_Number__c);
        	}
        	// BLL2a end
        	
        	// BLL14a - set home location & assume it's a correction if the location change is already permitted without the "UpdateVehicleLocation" flag set
        	if (v.HomeLocation__c==null && v.dealer__Store_Location__c!=null && v.dealer__Status_Code__c!='Delivered' 
        		|| (v.dealer__Status_Code__c!='Delivered' && oldv!=null && v.dealer__Store_Location__c!=oldv.dealer__Store_Location__c && v.UpdateVehicleLocation__c==false)) {
        		// Only save location if it's NOT a manufacturing location!
				dealer__Dealer_Location__c l = ls.getLocationById(v.dealer__Store_Location__c);        		
        		if (l!=null && l.ManufacturingLocation__c==false) v.HomeLocation__c = v.dealer__Store_Location__c;
        		// Remove if not using home location GP sharing anymore
        		MW_TriggerControls__c homeLocGPSharing = MW_TriggerControls__c.getInstance('HomeLocGPSharing');
        		if (homeLocGPSharing!=null && homeLocGPSharing.Enabled__c==false) v.HomeLocation__c=null;
        	}
        	// BLL14a end

        	// Update the physical location to match *IF* the location has changed *AND* the physical location has NOT changed
        	if (loc!=null && oldv!=null && oldv.dealer__Store_Location__c!=v.dealer__Store_Location__c
        	    && oldv.Physical_Location__c==v.Physical_Location__c) {
        	    v.Physical_Location__c = loc.Name;
        	}

        	// BLL2a - prevent location change unless update location flag is set (Admin fixing bad data or vehicle move process running)
        	if (restrictVehicleLocation==null || restrictVehicleLocation.Enabled__c) {
            	//BLL8d Schema.RecordTypeInfo rtinfo = rtMapById.get(v.RecordTypeId);
            	if (v.UpdateVehicleLocation__c!=true && oldv!=null && v.dealer__Store_Location__c!=oldv.dealer__Store_Location__c && oldv.dealer__Store_Location__c!=null) {
            	    System.debug(oldv); // BLL5a
            	    System.debug(v);    // BLL5a
            	    Long crts = v.CreatedDate!=null ? v.CreatedDate.getTime() : 0;  // BLL8a
            	    Long mods = v.LastModifiedDate!=null ? v.LastModifiedDate.getTime() : crts; // BLL8a
            	    if (mods-crts < 300000) {   // allow changes within 5 minutes (300,000 milliseconds)    
            	        // it's all good - creating for first time
            	    } else if (rtinfo!=null && !rtinfo.getName().contains('Template')){ // BLL6c
            	        v.addError('Updating vehicle location is not allowed. Request a vehicle transfer to move a vehicle from one store to another.');
            	    }   // BLL5a
            	}
        	} // if restricting vehicle location updates 
        	v.UpdateVehicleLocation__c = false; // Always reset flag!
        	// BLL2a end
        
        	// BLL7a - assign owner based on current location
        	if (loc!=null && loc.Service_Reporting_User__c!=null) v.OwnerId = loc.Service_Reporting_User__c;
        	System.debug('Repair order owner: ' + v.OwnerId);
        	// BLL7a end
    	}
		
	}

	// BLL18
	// Load all referenced conversion kits by Id into static variable
	public void LoadConversionKits(Set<Id> convKitIds) {
		// ensure the map is not null
		if (convKitMap==null) convKitMap = new Map<Id,dealer__Parts_Kit__c>();
		if (!convKitMap.keySet().containsAll(convKitIds)) {
			// ensure previously-requested kits are still included in the map!
			convKitIds.addAll(convKitMap.keySet());
			// load em up!
			if (convKitIds.size()>0) convKitMap = new Map<Id,dealer__Parts_Kit__c>([
				select Id, Name, Conv_MFG__c, Conversion_Model__c, Conv_MFG_Code__c, 
					MV_Ramp_Operation__c, Ramp_Location__c, MV_Ramp_Type__c, Rubber_Flooring__c, 
					Dealer_Cost__c, Freight__c, NMEDA_Fee__c, Prep_Title_Fee__c, Front_End_Discount__c, Back_End_Discount__c,
					Total_Discount__c, MW_Cost__c, CMC_Inventory_Pack__c, Inventory_Cost__c, MarkUp__c, 
					Inventory_Price__c, Price_East__c, Price_West__c, 
					Removable_Driver_Seat__c, Removable_Passenger_Seat__c, Door_Usable_Height__c, Door_Usable_Width__c,
					Ramp_Weight_Capacity__c, Ramp_Length__c, Ramp_Width__c, Ramp_Angle__c, Ramp_Angle_Kneeled__c,
					Kneeling__c, Center_of_Van_Height__c, Front_Row_Pos_Height__c, 
					Flat_Floor_Length__c, Overall_Floor_Length__c, Width_at_B_Pillars__c, 
					Nbr_Wheelchair_Passengers__c, Nbr_Total_Passengers__c
				from dealer__Parts_Kit__c
				where Id in :convKitIds
			]);
		}
	}

	// SyncConversionKitFields: Sync fields from conversion kits to vehicle
	//--------------------------------------------
	public void SyncConversionKitFields() {
		// list of conversion kits we need to pull info from
		Set<Id> convKitIds = new Set<Id>();
	    for(dealer__Vehicle_Inventory__c veh : newList) {
			dealer__Vehicle_Inventory__c oldveh = (oldmap!=null) ? oldmap.get(veh.Id) : null;
			Boolean ConversionChanged = (oldveh==null && veh.Conversion__c!=null) || (oldveh!=null && veh.Conversion__c!=oldveh.Conversion__c);
			if (veh.Conversion__c!=null && (veh.UpdateFromConversionKit__c || ConversionChanged)) {
				convKitIds.add(veh.Conversion__c);
			}
		}

		// Retrieve conversion kit info (one time per request!)
		LoadConversionKits(convKitIds);

		// Copy conversion info into vehicle
	    for(dealer__Vehicle_Inventory__c veh : newList) {
			dealer__Vehicle_Inventory__c oldveh = (oldmap!=null) ? oldmap.get(veh.Id) : null;
			Boolean ConversionChanged = (oldveh==null && veh.Conversion__c!=null) || (oldveh!=null && veh.Conversion__c!=oldveh.Conversion__c);
			System.debug(ConversionChanged);
			System.debug(veh.UpdateFromConversionKit__c);
			System.debug(veh.Conversion__c);
			if (veh.Conversion__c!=null && (veh.UpdateFromConversionKit__c || ConversionChanged)) {
				dealer__Parts_Kit__c convKit = convKitMap.get(veh.Conversion__c);
				System.debug(convKit);
				if (convKit!=null) {
					if (!String.isBlank(convKit.Conv_MFG__c)) veh.Conv_MFG__c = convKit.Conv_MFG__c;
					if (!String.isBlank(convKit.Conv_MFG__c)) veh.dealer__Conv_MFG__c = convKit.Conv_MFG__c;
					if (!String.isBlank(convKit.Conversion_Model__c)) veh.Conversion_Model__c = convKit.Conversion_Model__c;
					if (!String.isBlank(convKit.Conversion_Model__c)) veh.dealer__Conversion_Model__c = convKit.Conversion_Model__c;
					if (!String.isBlank(convKit.Conv_MFG_Code__c)) veh.Conv_MFG_Code__c = convKit.Conv_MFG_Code__c;
					if (!String.isBlank(convKit.MV_Ramp_Operation__c)) veh.MV_Ranp_Operation__c = convKit.MV_Ramp_Operation__c;
					if (!String.isBlank(convKit.MV_Ramp_Operation__c)) veh.dealer__MV_Ranp_Operation__c = convKit.MV_Ramp_Operation__c;
					if (!String.isBlank(convKit.Ramp_Location__c)) veh.Ramp_Location__c = convKit.Ramp_Location__c;
					if (!String.isBlank(convKit.Ramp_Location__c)) veh.dealer__Ramp_Location__c = convKit.Ramp_Location__c;
					if (!String.isBlank(convKit.MV_Ramp_Type__c)) veh.MV_Ramp_Type__c = convKit.MV_Ramp_Type__c;
					if (!String.isBlank(convKit.MV_Ramp_Type__c)) veh.dealer__MV_Ramp_Type__c = convKit.MV_Ramp_Type__c;
					if (!String.isBlank(convKit.Conversion_Model__c)) veh.Rubber_Flooring__c = convKit.Rubber_Flooring__c;
					// Cost/price fields only if still null on vehicle to allow manual overrides
					// Only update cost/price on New conversions: Fleet, New, New/Used
					// and add pack into conversion cost
					System.debug(NewVehicle);
					if (NewVehicle.Contains(veh.New_Used_Other__c)) {
						System.debug(veh.Conversion_Cost__c);
						System.debug(veh.ConversionMSRP__c);
						System.debug(convKit.Inventory_Cost__c);
						System.debug(convKit.CMC_Inventory_Pack__c);
						System.debug(convKit.Price_East__c);
						if (convKit.CMC_Inventory_Pack__c==null) convKit.CMC_Inventory_Pack__c = 0.00;
						if (veh.Conversion_Cost__c==null) veh.Conversion_Cost__c = convKit.Inventory_Cost__c + convKit.CMC_Inventory_Pack__c;
						//if (veh.dealer__Pack__c==null) veh.dealer__Pack__c = convKit.CMC_Inventory_Pack__c;
						if (veh.ConversionMSRP__c==null) veh.ConversionMSRP__c = convKit.Price_East__c;
						System.debug(veh.Conversion_Cost__c);
						System.debug(veh.ConversionMSRP__c);
					}
					// Doug Curtis' fields???
				}
			}
			veh.UpdateFromConversionKit__c = false;
		}

	}
	// BLL18 end

}