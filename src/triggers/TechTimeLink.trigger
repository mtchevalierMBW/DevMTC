/**
 * TechTimeLink
 * Tested by: ServiceRepairOrder2_TC
 *
 * Coverage:
 *	2018-10-22	80%	(32/40)
 *	2019-12-12	90%	(9/10)
 *  
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
 */
trigger TechTimeLink on dealer__Technician_Job_Time__c (before insert, before update, after insert, after update, before delete) {

	// BLL2a - Tech time this month validations
	//MW_TriggerControls__c TechTimeDate = MW_TriggerControls__c.getInstance('TechTimeDate');
	if (Trigger.isBefore && Trigger.isDelete) {
		TechnicianJobTimeProcess.RestrictTechnicianDate(Trigger.old, null);
		//System.debug('Check for deleting prior month time');
		//for(dealer__Technician_Job_Time__c t : Trigger.old) { 
		//	Date thismonth = Date.today().toStartOfMonth();
		//	Date tt = t.dealer__Date__c!=null ? t.dealer__Date__c.toStartOfMonth() : thismonth;
		//	System.debug(thismonth);
		//	System.debug(tt);
		//	if ((TechTimeDate==null || TechTimeDate.Enabled__c) && tt < thismonth)
		//		//BLL5 
		//		//t.addError('Cannot remove time recorded in a prior month');
		//		if (!RepairOrderTechTimeDate) t.addError('Cannot remove time recorded in a prior month');
		//		// BLL5
		//}
	}
	if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
		TechnicianJobTimeProcess.RecordTimeClockEntryUser(Trigger.new);
		TechnicianJobTimeProcess.PreventNegativeTechnicianTime(Trigger.new);
		TechnicianJobTimeProcess.RestrictTechnicianDate(Trigger.new, Trigger.oldMap);
		//System.debug('Check for adjusting prior month time');
		//for(dealer__Technician_Job_Time__c t : Trigger.new) {
		//	dealer__Technician_Job_Time__c oldt = (Trigger.oldMap!=null) ? Trigger.oldMap.get(t.Id) : null;
		//	if (oldt==null || t.dealer__Date__c!=oldt.dealer__Date__c || t.dealer__Actual_Time_Entry__c!=oldt.dealer__Actual_Time_Entry__c) {
		//		Date thismonth = Date.today().toStartOfMonth();
		//		Date tt = t.dealer__Date__c!=null ? t.dealer__Date__c.toStartOfMonth() : thismonth;
		//		Date ot = (oldt!=null && oldt.dealer__Date__c!=null) ? oldt.dealer__Date__c.toStartOfMonth() : thismonth; 
		//		System.debug(thismonth);
		//		System.debug(tt);
		//		System.debug(ot);
		//		if ((tt<thismonth || ot<thismonth) && (TechTimeDate==null || TechTimeDate.Enabled__c==true)) {	// BLL3a 
		//			// BLL5
		//			//t.addError('Cannot adjust time recorded in a prior month');
		//			if (!RepairOrderTechTimeDate) t.addError('Cannot adjust time recorded in a prior month');
		//			// BLL5 end
		//		}
		//	}
		//}
	}
	// BLL2a end

	// Calculate labor totals and apply to the RO Line
	// BLL6
	// if(Trigger.isAfter && !Trigger.isDelete && trigger.size==1 && Limits.getQueries() < 85 ) {	// BLL2c (add && !Trigger.isDelete)
	if(Trigger.isAfter && !Trigger.isDelete && trigger.size==1) {	
	// BLL6 end
		TechnicianJobTimeProcess.AccumulateLaborToJobLine(Trigger.New);
	}


	// BLL7
	if (Trigger.isAfter && Trigger.isInsert) {
		TechnicianJobTimeProcess.DeleteEstimateTechTimeFromERO(Trigger.new);
	}
	// BLL7 end
}