/**
 * SalesAppointment_EXT
 * Tested by: SalesAppointment_EXT_TEST
 * Date Sep 10, 2018
 * Programmer: Bryan Leaman
 * Project: W-000549
 * 
 * Code coverage:
 *	2019-01-14	91% (32/35)
 *
 * Modification Log:
 *	
 *
 */

public with sharing class SalesAppointment_EXT {
    private ApexPages.StandardController stdController;
    public dealer__Sales_Appointment__c obj;
    public String UserTimeZone {
    	get {
    		Id uid = UserInfo.getUserId();
    		if (obj!=null && obj.dealer__Assigned_To__c!=null) uid = obj.dealer__Assigned_To__c;
    		User u = [select Id, TimeZoneSidKey from User where Id=:uid limit 1];
    		Timezone targettz = Timezone.getTimeZone(u.TimeZoneSidKey);
    		return targettz.getDisplayName();
    	}
    	private set;
    }
    
    public SalesAppointment_EXT(ApexPages.StandardController ctlr) {
		List<String> fields = new List<String>();
		//fields.add('Desired_Vehicles__c');
		//if(!Test.isRunningTest()) ctlr.addFields(fields);

		obj = (dealer__Sales_Appointment__c) ctlr.getRecord();
		stdController = ctlr;

	}

	public ApexPages.PageReference save() {

		// Adjust time to assignee's timezone
		Timezone currenttz = UserInfo.getTimeZone();
		User owner = [
			select Id, Name, TimeZoneSidKey, Email, Profile.Name, isActive, ManagerId 
			from User 
			where Id=:obj.dealer__Assigned_To__c limit 1];
		Timezone targettz = Timezone.getTimeZone(owner.TimeZoneSidKey);
		System.debug('Owner timezone=' + owner.TimeZoneSidKey);
		String t = obj.dealer__Time__c;
		boolean pm = t.endsWith('PM');
		t = t.removeEnd('PM').removeEnd('AM');
		List<String> hhmm = t.split(':');
		Integer h = hhmm.size()>=1 ? Integer.valueOf(hhmm[0].trim()) : 0;
		if (pm) h += 12;
		Integer m = hhmm.size()>=1 ? Integer.valueOf(hhmm[1].trim()) : 0;
		Time timefield = Time.newInstance(h, m, 0, 0);
		System.debug(timefield);
		DateTime dt = DateTime.newInstance(obj.dealer__Date__c, timefield);
		System.debug(dt);
		System.debug('DateTime=' + dt.format('yyyy-MM-dd HH:mm:ss z'));
		System.debug('Timezone=' + currenttz.getID() + ' offset seconds=' + String.valueOf(currenttz.getOffset(dt)/1000));
		System.debug('Timezone=' + targettz.getID() + ' offset seconds=' + String.valueOf(targettz.getOffset(dt)/1000));
		System.debug('Adjust by ' + String.valueOf((currenttz.getOffset(dt)-targettz.getOffset(dt))/1000) + ' seconds');
		dt = dt.AddSeconds((currenttz.getOffset(dt)-targettz.getOffset(dt))/1000);
		System.debug('DateTime=' + dt.format('yyyy-MM-dd HH:mm:ss z'));
		//obj.dealer__Time__c = dt.format('hh:mm a', targettz.getID());
		obj.dealer__DateTime__c = dt;

		try {
			// Use standard controller's save method
			upsert(obj);
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			return null;
		}
		ApexPages.StandardController supctl = new ApexPages.StandardController(new dealer__Sales_Up__c(Id=obj.dealer__Sales_Up__c));
        PageReference nextpage = supctl.view(); 
        return nextpage;
	}

	public PageReference cancel() {
		ApexPages.StandardController objctl = new ApexPages.StandardController(new dealer__Sales_Appointment__c(Id=obj.Id));
        PageReference nextpage = objctl.view(); 
        return nextpage;		
	}

}