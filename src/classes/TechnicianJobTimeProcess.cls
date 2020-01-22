/**
 * TechnicianJobTimeProcess
 * Tested by: ServiceRepairOrder2_TC	//, TechnicianJobTimeProcess_TEST
 * Date: 2019-12-12
 * Programmer: Bryan Leaman
 * Project: 
 *
 * Coverage:
 *	2019-12-12	90%	(65/72)
 *
 * Modifications (initially from TechTimeLink trigger): 
 *	2015-09-11	B. Leaman	BLL1 Do not update line if there is no change, move SOQL dealer__Time_Clock__c outside loop.
 *	2016-12-28	B. Leaman	BLL2 IR#0005043 & IR#0005070 - Prevent tech time delete if prior month and negative hours.
 *  2017-07-17	B. Leaman	BLL3 Condition tech time protections so they can be turned off.
 *	2018-10-22	B. Leaman	IR-0042441	BLL4 - Looks like both DealerTeam and custom code are issueing DML to update service job lines.
 *										Update custom code to implement a flag to disable our update (and re-enable easily if this doesn't work).
 *	2019-04-15	B. Leaman	W-000647 BLL5 - special permission to allow updating older tech time.
 *	2019-08-05	B. Leaman	W-000728 BLL6 - trying to remove SOQL limit tests to ensure updates occur.
 *	2019-12-06	B. Leaman	W-000788 BLL7 - split actual time from book time (conditioned by location flag)
 *							Move logic to TechnicianJobTimeProcess class.
 *
**/
public with sharing class TechnicianJobTimeProcess {
 
	// Allows people with special permission (Duane McCord) to adjust prior month technician time
	public static boolean RepairOrderTechTimeDate = FeatureManagement.checkPermission('RepairOrderTechTimeDate'); // BLL5
	
	// static data retrieved to prevent subsequent soql queries
	public static LocationsSingleton ls = LocationsSingleton.getInstance();	// BLL8
	public static List<dealer__Time_Clock__c> payrollClock;

	// Record current user as the user who made the entry
	//------------------------------------------------------------------------------
	public static void RecordTimeClockEntryUser(List<dealer__Technician_Job_Time__c> newlist) {
		if (payrollClock==null) payrollClock = [
			Select Id 
			from dealer__Time_Clock__c 
			where dealer__User__c=:UserInfo.getUserId() and Date__c =:Date.Today() 
			limit 1
		]; // BLL1a
		for(dealer__Technician_Job_Time__c t : newlist) {
			if(payrollClock.size()==1) t.Time_Clock_Entry__c = payrollClock[0].Id;
		}
	}

	// Accumulate single tech time entry labor to job line - only supports updates to 1 record at a time!
	//------------------------------------------------------------------------------
	public static void AccumulateLaborToJobLine(List<dealer__Technician_Job_Time__c> newlist) {
		// BLL4
		MW_TriggerControls__c TechTimeUpdatesJob = MW_TriggerControls__c.getInstance('TechTimeUpdatesJob');	
		System.debug('AccumulateLaborToJobLine');
		System.debug(TechTimeUpdatesJob);
		if (TechTimeUpdatesJob==null || TechTimeUpdatesJob.Enabled__c==true) {
		// BLL4 end

			Decimal lTotal = 0;
			// BLL7
			Set<Id> locIds = new Set<Id>();
			//for(dealer__Technician_Job_Time__c times : [Select Labor_Total__c from dealer__Technician_Job_Time__c 
			//													where dealer__Service_Job_Line__c =:Trigger.new[0].dealer__Service_Job_Line__c
			//													Limit 500]){
			for(dealer__Technician_Job_Time__c times : [
				Select Labor_Total__c, dealer__Service_Job_Line__r.dealer__Service_Repair_Order__r.dealer__Company__c
				from dealer__Technician_Job_Time__c 
				where dealer__Service_Job_Line__c =:newlist[0].dealer__Service_Job_Line__c
				Limit 500
			]){
			// BLL7 end
				if(times.Labor_Total__c==null) { times.Labor_Total__c=0;}
				lTotal+=times.Labor_Total__c;
				// BLL7
				if (times.dealer__Service_Job_Line__r.dealer__Service_Repair_Order__r.dealer__Company__c!=null) {
					locIds.add(times.dealer__Service_Job_Line__r.dealer__Service_Repair_Order__r.dealer__Company__c);
				}
				// BLL7 end
			}

			// BLL7 get locations
			ls.addLocationIds(locIds);
			ls.retrieveLocations();
			dealer__Dealer_Location__c loc = null;
			if (ls.locationIdMap.size()>0) loc = ls.locationIdMap.values()[0];
			System.debug('Roll tech time to book time?');
			System.debug(loc);
			if (loc!=null && loc.LaborBookEqualsActualTime__c) {
			// BLL7 end
				// BLL1d dealer__Service_Job__c line = [Select Id from dealer__Service_Job__c 
				dealer__Service_Job__c line = [Select Id, dealer__Labor_Charges__c from dealer__Service_Job__c  // BLL1a 
														where Id=:newlist[0].dealer__Service_Job_Line__c 
														Limit 1];
				System.debug(line);
				System.debug(lTotal);
				if (line.dealer__Labor_Charges__c!=lTotal) { // BLL1a
					System.debug('Updating service job line labor from ' + String.valueOf(line.dealer__Labor_Charges__c) + ' to ' + String.valueOf(lTotal)); // BLL1a
					line.dealer__Labor_Charges__c = lTotal;
					ServiceProcess.ReloadROLines = true;	// BLL7
					System.debug('DML Update->'+JSON.serialize(line));
					update line;
				}  // BLL1a
			// BLL7
			}
			// BLL7 end
		// BLL4
		}
		// BLL4 end
	}

	// Do not allow negative values in actual time
	//------------------------------------------------------------------------------
	public static void PreventNegativeTechnicianTime(List<dealer__Technician_Job_Time__c> newlist) {
		MW_TriggerControls__c TechTimeCredit = MW_TriggerControls__c.getInstance('TechTimeCredit');
		System.debug('Check for negative time');
		for(dealer__Technician_Job_Time__c t : newlist) {
			System.debug(t.dealer__Actual_Time_Entry__c);
			if (t.dealer__Actual_Time_Entry__c<0 && (TechTimeCredit==null || TechTimeCredit.Enabled__c==true))	// BLL3c
				t.addError('Cannot record negative hours of labor');
		}		
	}

	// Do not allow back-dating to prior month (or deleting from a prior month)
	//------------------------------------------------------------------------------
	public static void RestrictTechnicianDate(List<dealer__Technician_Job_Time__c> ttlist, Map<Id,dealer__Technician_Job_Time__c> oldMap) {
		MW_TriggerControls__c TechTimeDate = MW_TriggerControls__c.getInstance('TechTimeDate');
		System.debug('Check for adjusting prior month time');
		for(dealer__Technician_Job_Time__c t : ttlist) {
			dealer__Technician_Job_Time__c oldt = (oldMap!=null) ? oldMap.get(t.Id) : null;
			if (oldt==null || t.dealer__Date__c!=oldt.dealer__Date__c || t.dealer__Actual_Time_Entry__c!=oldt.dealer__Actual_Time_Entry__c) {
				Date thismonth = Date.today().toStartOfMonth();
				Date tt = t.dealer__Date__c!=null ? t.dealer__Date__c.toStartOfMonth() : thismonth;
				Date ot = (oldt!=null && oldt.dealer__Date__c!=null) ? oldt.dealer__Date__c.toStartOfMonth() : thismonth; 
				System.debug(thismonth);
				System.debug(tt);
				System.debug(ot);
				if ((tt<thismonth || ot<thismonth) && (TechTimeDate==null || TechTimeDate.Enabled__c==true)) {	// BLL3a 
					// BLL5
					//t.addError('Cannot adjust time recorded in a prior month');
					if (!RepairOrderTechTimeDate) t.addError('Cannot adjust or delete time recorded in a prior month');
					// BLL5 end
				}
			}
		}
	}


	// Delete estimate tech time that is copied to RO when location uses separate book & actual times
	//--------------------------------------------------------------------------------
	public static void DeleteEstimateTechTimeFromERO(List<dealer__Technician_Job_Time__c> newlist) {
		MW_TriggerControls__c TechTimeERODelete = MW_TriggerControls__c.getInstance('TechTimeERODelete');
		Set<Id> locIds = new Set<Id>();
		Set<Id> jobIds = new Set<Id>();
		List<dealer__Technician_Job_Time__c> techTimeToDelete = new List<dealer__Technician_Job_Time__c>();
		Map<Id,dealer__Service_Job__c> updBook = new Map<Id,dealer__Service_Job__c>();

		// allow easy switch to stop this process
		if (TechTimeERODelete==null || TechTimeERODelete.Enabled__c) {

			for(dealer__Technician_Job_Time__c tt : newlist) {
				if (tt.dealer__Technician__c==null && tt.dealer__Service_Estimate_Subline_Creator__c!=null) {
					jobIds.add(tt.dealer__Service_Job_Line__c);
				}
			}

			// if there are any RO lines (jobs) for tech time that came from an estimate conversion...
			if (jobIds.size()>0) {
				// map to jobs with related location setting
				Map<Id,dealer__Service_Job__c> jobMap = new Map<Id,dealer__Service_Job__c>([
					select Id, dealer__Service_Repair_Order__c, dealer__Service_Repair_Order__r.dealer__Company__c, 
						dealer__Service_Repair_Order__r.dealer__Company__r.LaborBookEqualsActualTime__c
					from dealer__Service_Job__c
					where Id in :jobIds
				]);
				// get all referenced locations
				for(dealer__Service_Job__c j : jobMap.values()) {
					locIds.add(j.dealer__Service_Repair_Order__r.dealer__Company__c);
				}
				ls.addLocationIds(locIds);
				// find tech time lines to be deleted based on location setting and having come from an estimate
				for(dealer__Technician_Job_Time__c tt : newlist) {
					if (tt.dealer__Technician__c==null && tt.dealer__Service_Estimate_Subline_Creator__c!=null) {
						dealer__Service_Job__c job = tt.dealer__Service_Job_Line__c==null ? null : jobMap.get(tt.dealer__Service_Job_Line__c);
						dealer__Dealer_Location__c loc = job==null ? null : ls.getLocationById(job.dealer__Service_Repair_Order__r.dealer__Company__c);
						// need to delete tech time that comes from an estimate if the location is set to split book & actual labor
						if (loc!=null && loc.LaborBookEqualsActualTime__c==false) {
							techTimeToDelete.add(tt);
							dealer__Service_Job__c updj = updBook.get(tt.dealer__Service_Job_Line__c);
							if (updj==null) updj = new dealer__Service_Job__c(Id=tt.dealer__Service_Job_Line__c, dealer__Book_Time__c=0.00);
							updj.dealer__Book_Time__c += tt.dealer__Book_Time_Entry__c==null ? 0.00 : tt.dealer__Book_Time_Entry__c;
							updBook.put(updj.Id, updj);
						}
					}
				}
			}
			// delete tech time in a future method
			//if (updBook.size()>0) Utility.updateSObjectsFuture(JSON.serialize(updBook.values()));
			if (updBook.size()>0) update updBook.values();
			if (techTimeToDelete.size()>0) Utility.deleteSObjectsFuture(JSON.serialize(techTimeToDelete));
		}
	}

}