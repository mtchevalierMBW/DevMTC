/**
 * BatchFixInventorySvcVeh
 * Tested by: BatchFixInventorySvcVeh_TEST
 * Date: Sep. 13, 2017
 * Programmer: Bryan Leaman
 * 
 * Code coverage:
 *	2017-09-13	 92% (87/94)
 *
 * Run it now:
Database.executeBatch(new BatchFixInventorySvcVeh(null, true));

 * Set standard schedule:
BatchFixInventorySvcVeh.scheduleMe();

 * Set custom schedule:
System.schedule('BatchFixInventorySvcVeh', 'sec min hr day mth wd year', new BatchFixInventorySvcVeh(null,true));
 
 */
global class BatchFixInventorySvcVeh implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
	global final String query;
	global boolean doUpdate;
    global String errmsgs;
    global String results;
    global String svresults;
    public static final List<String> CRON_LIST = new List<String>{
    	'0 0 7 * * ? *'		// 7 a.m. daily
    };
	
    

	// BatchFixInventorySvcVeh constructor - generate query string & initialize
	global BatchFixInventorySvcVeh(String rcdlimit, boolean doUpd) {
		doUpdate = doUpd;
		String soql = 
			'Select Id, Name, dealer__VIN__c, dealer__Service_Vehicle__c '
			+ 'From dealer__Vehicle_Inventory__c ';
		if (!Test.isRunningTest()) soql += 'Where dealer__Service_Vehicle__c = null ';
		soql += 'Order by dealer__VIN__c, CreatedDate asc ';
		if (!String.isBlank(rcdlimit))	soql += 'Limit ' + rcdlimit + ' ';
		query = soql;
		errmsgs = '';
		results = '';
		svresults = '';
	}


	// start - query the database
	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);
	}


	// execute for a batch of records
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<dealer__Vehicle_Inventory__c> objs = (List<dealer__Vehicle_Inventory__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		// List of referenced VINs
		Set<String> VINs = new Set<String>();
		for(dealer__Vehicle_Inventory__c o : objs) {
			if (!String.isBlank(o.dealer__VIN__c)) {
				VINs.add(o.dealer__VIN__c);
			}
		}
		// Map of service vehicles by VIN
		Map<String,dealer__Service_Vehicle__c> VinSvcMap = new Map<String,dealer__Service_Vehicle__c>();
		for(dealer__Service_Vehicle__c sv : [select Id, Name, dealer__VIN__c, dealer__Sales_Inventory__c, dealer__Stock_Number__c from dealer__Service_Vehicle__c where dealer__VIN__c in :VINs]) {
			VinSvcMap.put(sv.dealer__VIN__c, sv);
		}

		// Update
		List<dealer__Vehicle_Inventory__c> updObjs =new List<dealer__Vehicle_Inventory__c>();
		Map<Id,dealer__Service_Vehicle__c> updSVMap = new Map<Id,dealer__Service_Vehicle__c>();	// protect/reset SvcVeh pointer to Inventory 
		for(dealer__Vehicle_Inventory__c o : objs) {
			Id newsvid = null;
			if (VinSvcMap.containsKey(o.dealer__VIN__c)) {
				dealer__Service_Vehicle__c sv = VinSvcMap.get(o.dealer__VIN__c);
				newsvid = sv!=null ? sv.Id : null;
				// point stock vehicle to service vehicle
				if (newsvid!=null) updObjs.add(new dealer__Vehicle_Inventory__c(
					Id=o.Id, dealer__Service_Vehicle__c=newsvid
				));
				// to reset pointer back to veh inventory to current stock veh
				if (sv!=null && sv.dealer__Sales_Inventory__c!=null && sv.dealer__Sales_Inventory__c!=o.Id) {
					updSVMap.put(sv.Id, new dealer__Service_Vehicle__c(Id=sv.Id, dealer__Sales_Inventory__c=sv.dealer__Sales_Inventory__c, dealer__Stock_Number__c=sv.dealer__Stock_Number__c));
					svresults += sv.id + ',' + sv.Name + ',' + sv.dealer__VIN__c + ',' + sv.dealer__Sales_Inventory__c + ',' + sv.dealer__Stock_Number__c + '\r';
				}
			}
			results += o.Id + ',' + o.Name + ',' + o.dealer__VIN__c + ',' + newsvid + '\r';
		}
		
		System.debug('Number of records to update: ' + String.valueOf(updObjs.size()));
		
		// Do updates!
		if (updObjs.size()>0)  {
			Database.SaveResult[] saveresults = new List<Database.SaveResult>();
			if (doUpdate) saveresults = Database.update(updObjs, false); 
			//System.debug(saveresults);
			System.debug('List of failed updates:');
			//for(Database.SaveResult sr : saveresults) {
			for(Integer i=0; i<updObjs.size(); i++) {
				dealer__Vehicle_Inventory__c o = updObjs[i];
				Database.SaveResult sr = saveresults.size()>i ? saveresults[i] : null;
				if (sr!=null && !sr.isSuccess()) {
					//System.debug(sr);
					String errmsg = o.Id + ',' + o.Name + ',' + o.dealer__VIN__c + ',';
					for(Database.Error de : sr.getErrors()) {
						errmsg += '[' + String.join(de.getFields(), ':') + '] '
							+ de.getMessage() + '\r';
					}
					System.debug(errmsg);
					errmsgs += errmsg;
				}
			}
			// reset service vehicle pointers to original stock veh
			if (doUpdate && updSVMap.size()>0) Database.update(updSVMap.values(), false);	
			System.debug('List complete.');
		}

		// Reset results & error messages if getting too large
		if (results.length() + errmsgs.length() + svresults.length() > 10000000) {
			sendEmail();
		}

	}
	
	
	// finish - send results via email
	global void finish(Database.BatchableContext bc) {
		sendEmail();
	}


	// sendEmail of the results	
	global void sendEmail() {
		Organization org = [select Id, Name, isSandbox from Organization limit 1];
		String csvheader = 'Id,Name,VIN,Svc veh\n';
		String svcsvheader = 'Id,Name,VIN,Stock veh,Stock nbr\n';

		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		List<String> recipients = new List<String>{ UserInfo.getUserEmail() };
		//if (!org.isSandbox) recipients.add('another.email@mobilityworks.com');
		mail.setToAddresses(recipients); 
		mail.setSubject('Batch update stock missing svc veh complete - UPDATES');
		String body = 'Batch update stock missing svc veh has completed.\n\n';
		if (!doUpdate) body += 'Test only! NOT Updated!\n\n';
		mail.setPlainTextBody(body);
		
		Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
			resultcsv.setContentType('text/csv');
			resultcsv.setFileName('results.csv');
			resultcsv.setInline(false);
			resultcsv.Body = Blob.valueOf(csvheader + results);
			if (!String.isBlank(results)) listOfAttachments.add(resultcsv);
		Messaging.EmailFileAttachment svresultcsv = new Messaging.EmailFileAttachment();
			svresultcsv.setContentType('text/csv');
			svresultcsv.setFileName('svresults.csv');
			svresultcsv.setInline(false);
			svresultcsv.Body = Blob.valueOf(svcsvheader + svresults);
			if (!String.isBlank(svresults)) listOfAttachments.add(svresultcsv);
		Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
			upderrors.setContentType('text/csv');
			upderrors.setFileName('UpdateErrors.csv');
			upderrors.setInline(false);
			upderrors.Body = Blob.valueOf(errmsgs);
			if (!String.isBlank(errmsgs)) listOfAttachments.add(upderrors);
		mail.setFileAttachments(listOfAttachments);
		emailMsgs.add(mail);

		// Only send if records were selected for processing...
		if (!String.isBlank(results) || !String.isBlank(errmsgs)) Messaging.sendEmail(emailMsgs);
		
		// Reset to clear HEAP
		results = '';
		errmsgs = '';
		
	}


	// Schedulable context
	global void execute(SchedulableContext ctx) {
		String maxrcds = Test.isRunningTest() ? '1' : null;
   	
		BatchFixInventorySvcVeh b = new BatchFixInventorySvcVeh(maxrcds, true);
		Database.executeBatch(b, 1);
	}

	// scheduleMe self-scheduler
	public static List<String> scheduleMe() {
		List<String> jobIds = new List<String>();
		BatchFixInventorySvcVeh m = new BatchFixInventorySvcVeh(null, true);
		Integer i = 0;
		for(String cron : BatchFixInventorySvcVeh.CRON_LIST) {
			System.debug(cron);
			String jobname = 'BatchFixInventorySvcVeh_' + String.valueOf(++i);
			if (Test.isRunningTest()) jobname += '_TEST';
			jobIds.add(System.schedule(jobname, cron, m));
		}
		return jobIds;
	}


}