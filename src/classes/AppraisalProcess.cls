/**
 * AppraisalProcess
 * Tested by: AppraisalProcess_TEST
 * Date: Feb 16, 2018
 * Programmer: Bryan Leaman
 *
 * Code coverage:
 *	2018-02-16	82% (28/34)
 */
public with sharing class AppraisalProcess {

	List<dealer__Appraisal__c> newList;
	Map<Id,dealer__Appraisal__c> oldMap;

	// AppraisalProcess
	//---------------------------------------
	public AppraisalProcess(List<dealer__Appraisal__c> newL, Map<Id,dealer__Appraisal__c> oldM) {
		newList = newL;
		oldMap = oldM;
	}

	// ProcessWonAppraisals
	//--------------------------------------
	public void ProcessWonAppraisals() {
		MonitorExecution mon = new MonitorExecution('WonAppraisals');

		Set<Id> svIds = new Set<Id>();
		Map<Id,dealer__Service_Vehicle__c> updSrvVehOwn = new Map<Id,dealer__Service_Vehicle__c>();
		Set<Id> locIds = new Set<Id>();
		LocationsSingleton ls = LocationsSingleton.getInstance();
		
		for(dealer__Appraisal__c a : newList) {
			dealer__Appraisal__c oldApp = oldMap.get(a.Id);
			if (oldApp!=null && a.dealer__Status__c=='Won' && oldApp.dealer__Status__c!=a.dealer__Status__c) svIds.add(a.dealer__Service_Vehicle__c);
			if (a.dealer__Store_Location__c!=null) locIds.add(a.dealer__Store_Location__c);
		}
		ls.addLocationIds(locIds);
		mon.log('Service vehicle ids: ' + JSON.serialize(svIds));
		
		Map<Id, dealer__Service_Vehicle__c> svMap = new Map<Id, dealer__Service_Vehicle__c>([
			select Id, Name, dealer__Veh_Owner__c, dealer__Last_Odometer__c
			from dealer__Service_Vehicle__c
			where Id in :svIds
		]);
		
		for(dealer__Appraisal__c a : newList) {
			System.debug('Appraisal: ' + a.Name);
			dealer__Dealer_Location__c loc = ls.getLocationById(a.dealer__Store_Location__c);
			dealer__Service_Vehicle__c srvVeh = svMap.get(a.dealer__Service_Vehicle__c);
			dealer__Service_Vehicle__c sv = new dealer__Service_Vehicle__c();
			mon.log('Appraisal: ' + a.Name);
			mon.log('Location: ' + JSON.serialize(loc));
			mon.log('Service vehicle: ' + JSON.serialize(srvVeh));
			if (srvVeh!=null) sv.Id=a.dealer__Service_Vehicle__c;
			if (loc!=null && srvVeh!=null && a.dealer__Service_Vehicle__c!=null && a.dealer__Service_Vehicle__r.dealer__Veh_Owner__c==null) {
				sv.dealer__Veh_Owner__c=loc.dealer__Location_Account__c;
				sv.dealer__Veh_Owner_Contact__c = null;
				System.debug('Update owner of service veh: ' + a.dealer__Service_Vehicle__r.Name);	// BLL33a
				updSrvVehOwn.put(a.dealer__Service_Vehicle__c, sv);
			}
			if (srvVeh!=null && a.dealer__Service_Vehicle__c!=null && a.dealer__Service_Vehicle__r.dealer__Last_Odometer__c==null) {
				sv.dealer__Last_Odometer__c = a.dtmob__Trade_In__r.dealer__Odometer_at_Trade_In__c;
				System.debug('Update odometer of service veh: ' + a.dealer__Service_Vehicle__r.Name);	// BLL33a
				updSrvVehOwn.put(a.dealer__Service_Vehicle__c, sv);
			}
		}
		mon.log('Updates: ' + JSON.serialize(updSrvVehOwn));
		try {
			System.debug('Updating service vehicles');
			if (updSrvVehOwn.size()>0) update(updSrvVehOwn.values()); 
			if (mon.AlwaysNotify) mon.notifyAdmin();
		} catch(Exception e) {
			System.debug('Error updating service vehicles: ' + e.getMessage());
			mon.log('Unable to update appraisals to "Won"');
           	mon.log('EXCEPTION: ' + e.getTypeName() + '; ' + e.getMessage() + '; ' + e.getCause() + '; line ' + String.valueOf(e.getLineNumber()) + ';\n' + e.getStackTraceString()); 
			mon.log(JSON.serialize(updSrvVehOwn)); 
			mon.notifyAdmin();
		}

	}

}