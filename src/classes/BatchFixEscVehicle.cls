/**
 * BatchFixEscVehicle
 * Tested by: BatchFixEscVehicle_TEST
 * Date: Sep 12, 2017
 * Programmer: Bryan Leaman
 * 
 * Code coverage:
 *	2017-09-13	86% (88/102)
 *
 * Run it now:
Database.executeBatch(new BatchFixEscVehicle(null, true));

 * Set standard schedule:
BatchFixEscVehicle.scheduleMe();

 * Set custom schedule:
System.schedule('BatchFixEscVehicle', 'sec min hr day mth wd year', new BatchFixEscVehicle(null,true));
 
 */
global class BatchFixEscVehicle implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
	global final String query;
	global boolean doUpdate;
    global String errmsgs;
    //global String results;
    global Map<Id,String> resultmap; 
    public static final List<String> CRON_LIST = new List<String>{
    	'0 0 7 * * ? *'		// 7 a.m. daily
    };
	
    

	// BatchFixEscVehicle constructor - generate query string & initialize
	global BatchFixEscVehicle(String rcdlimit, boolean doUpd) {
		doUpdate = doUpd;
		String soql = 'select Id, Name, dealer__Service_Vehicle__c, dealer__Service_Vehicle__r.Name, '
			+ 	'dealer__Vehicle_Inventory__c, dealer__Customer__c, dealer__Customer_Contact__c, '
			+	'dealer__Car_Deal__c, dealer__Car_Deal__r.Name, dealer__Car_Deal__r.dealer__Status__c, '
			+	'dealer__Car_Deal__r.dealer__Service_Vehicle__c, dealer__Car_Deal__r.dealer__Service_Vehicle__r.Name, '
			+	'dealer__Car_Deal__r.dealer__Vehicle__c, dealer__Car_Deal__r.dealer__Vehicle__r.Name, ' 
			+	'dealer__Car_Deal__r.dealer__Buyer__c, dealer__Car_Deal__r.dealer__Buyer__r.Name, '
			+	'dealer__Car_Deal__r.dealer__Buyer_Contact__c, dealer__Car_Deal__r.dealer__Buyer_Contact__r.Name, '
			+	'dealer__Car_Deal__r.dealer__Deal_Type__c, dealer__Car_Deal__r.dealer__VIN__c, '
			+ 	'dealer__Vehicle_Inventory__r.Name, dealer__Customer__r.Name, dealer__Customer_Contact__r.Name '
			+ 'from dealer__Service_Contract__c '
			+ 'where dealer__Car_Deal__c!=null and dealer__Service_Vehicle__c!=null and dealer__Contract_Template__c=false ';

		//if (!Test.isRunningTest()) soql += 'and (condition) ';
		//soql += 'Order by CreatedDate desc ';
		if (!String.isBlank(rcdlimit))	soql += 'Limit ' + rcdlimit + ' ';
		query = soql;
		errmsgs = '';
		//results = '';
		resultmap = new Map<Id,String>();
	}


	// start - query the database
	global Database.QueryLocator start(Database.BatchableContext bc) {
		System.debug(query);
		return Database.getQueryLocator(query);
	}


	// execute for a batch of records
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<dealer__Service_Contract__c> objs = (List<dealer__Service_Contract__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		Set<Id> stkVehIds = new Set<Id>();
		Map<Id,Id> stkSvcVehMap = new Map<Id,Id>();
		Set<String> vinSet = new Set<String>();
		Map<String,dealer__Service_Vehicle__c> vinSvcVehMap = new Map<String,dealer__Service_Vehicle__c>();
		for(dealer__Service_Contract__c o : objs) {
			if (o.dealer__Car_Deal__r.dealer__Service_Vehicle__c==null && o.dealer__Car_Deal__r.dealer__Vehicle__c!=null) 
				stkVehIds.add(o.dealer__Car_Deal__r.dealer__Vehicle__c);
			if (!String.isBlank(o.dealer__Car_Deal__r.dealer__VIN__c))
				vinSet.add(o.dealer__Car_Deal__r.dealer__VIN__c);
		}
		// Map stock vehicles to related service vehicle
		for(dealer__Vehicle_Inventory__c stkv : [
				select Id, Name, dealer__Service_Vehicle__c from dealer__Vehicle_Inventory__c where Id in :stkVehIds
			]) {
			stkSvcVehMap.put(stkv.Id, stkv.dealer__Service_Vehicle__c);
		}
		// Map vins to service vehicles
		for(dealer__Service_Vehicle__c sv : [
			select Id, Name, dealer__VIN__c
			from dealer__Service_Vehicle__c
			where dealer__VIN__c in :vinSet
		]) {
			vinSvcVehMap.put(sv.dealer__VIN__c, sv);
		}

		// Update
		List<dealer__Service_Contract__c> updObjs =new List<dealer__Service_Contract__c>();
		for(dealer__Service_Contract__c o : objs) {
			Id ProposalSvcVehId = o.dealer__Car_Deal__r.dealer__Service_Vehicle__c;
			if (ProposalSvcVehId==null && o.dealer__Car_Deal__r.dealer__Vehicle__c!=null) 
				ProposalSvcVehId = stkSvcVehMap.get(o.dealer__Car_Deal__r.dealer__Vehicle__c);

			// Get svc veh from VIN on proposal
			if (ProposalSvcVehId==null && o.dealer__Car_Deal__c!=null && !String.isBlank(o.dealer__Car_Deal__r.dealer__VIN__c)) {
				dealer__Service_Vehicle__c sv = vinSvcVehMap.get(o.dealer__Car_Deal__r.dealer__VIN__c);
				if (sv!=null) ProposalSvcVehId = sv.Id;
			}
			
			// update esc if svc veh, custom or contact has changed
			if (o.dealer__Service_Vehicle__c != ProposalSvcVehId
				|| o.dealer__Customer__c != o.dealer__Car_Deal__r.dealer__Buyer__c
				|| o.dealer__Customer_Contact__c != o.dealer__Car_Deal__r.dealer__Buyer_Contact__c 
				) {
				
				updObjs.add(new dealer__Service_Contract__c(
					Id=o.Id, dealer__Service_Vehicle__c=ProposalSvcVehId,
					dealer__Vehicle_Inventory__c=o.dealer__Car_Deal__r.dealer__Vehicle__c,
					dealer__Customer__c=o.dealer__Car_Deal__r.dealer__Buyer__c,
					dealer__Customer_Contact__c=o.dealer__Car_Deal__r.dealer__Buyer_Contact__c
				));
				//results += 
				resultmap.put(o.Id,	o.Id + ',' + o.Name + ','
					+ o.dealer__Service_Vehicle__c + ',"' + o.dealer__Service_Vehicle__r.Name + '",'
					+ o.dealer__Car_Deal__r.Name + ',' + o.dealer__Car_Deal__r.dealer__Status__c + ','
					+ ProposalSvcVehId + ',"' + o.dealer__Car_Deal__r.dealer__Service_Vehicle__r.Name + '","'
					+ o.dealer__Vehicle_Inventory__r.Name + '","' + o.dealer__Car_Deal__r.dealer__Vehicle__r.Name + '","'
					+ o.dealer__Customer__r.Name + '","' + o.dealer__Car_Deal__r.dealer__Buyer__r.Name + '"');
			}
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
				dealer__Service_Contract__c o = updObjs[i];
				Database.SaveResult sr = saveresults.size()>i ? saveresults[i] : null;
				if (sr!=null && !sr.isSuccess()) {
					//System.debug(sr);
					String resultline = resultmap.get(o.Id);
					String errmsg = '';
					String errmsgline = o.Id + ','
					+ o.dealer__Service_Vehicle__c + ',' + o.dealer__Vehicle_Inventory__c + ','
					+ o.dealer__Customer__c + ',' + o.dealer__Customer_Contact__c + ',';
					for(Database.Error de : sr.getErrors()) {
						errmsgline += '[' + String.join(de.getFields(), ', ') + '] '
							+ de.getMessage() + '\r';
						errmsg += de.getMessage() + '; ';
					}
					System.debug(errmsgline);
					errmsgs += errmsgline;
					errmsg = errmsg.replaceAll('\\s',' ');
					if (o.Id!=null && resultline!=null) resultmap.put(o.Id,resultline+',"Error:'+errmsg+'"');
				}
			}
			System.debug('List complete.');
		}

		// Reset results & error messages if getting too large
		//if (results.length() + errmsgs.length() > 10000000) {
		if (Limits.getLimitHeapSize() - Limits.getHeapSize() < 1000000){  // if less that 1 meg left
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
		String csvheader = 'ESC Id, ESC Name, ESC Veh Id, ESC Veh, Proposal, Proposal Status, Proposal Svc Veh Id, Proposal Svc Veh,'
			+ 'ESC Stock Veh, Proposal Stock Veh, ESC Customer, Proposal Customer\n';
		String errheader = 'ESC Id, Svc Veh Id, Stk Veh Id, Customer Account Id, Contact Id\n';
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		List<String> recipients = new List<String>{ UserInfo.getUserEmail() };
		//if (!org.isSandbox) recipients.add('another.email@mobilityworks.com');
		mail.setToAddresses(recipients); 
		System.debug(recipients);
		mail.setSubject('Batch update Fix ESC vehicle complete - UPDATES');
		String body = 'Batch update Fix ESC vehicle has completed.\n\n';
		if (!doUpdate) body += 'Test only! NOT Updated!\n\n';
		mail.setPlainTextBody(body);
		
		Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
			resultcsv.setContentType('text/csv');
			resultcsv.setFileName('SvcContractResults.csv');
			resultcsv.setInline(false);
			resultcsv.Body = Blob.valueOf(csvheader + String.join(resultmap.values(),'\n'));
			if (resultmap.size()>0) listOfAttachments.add(resultcsv);
		Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
			upderrors.setContentType('text/plain');
			upderrors.setFileName('SvcContractErrors.csv');
			upderrors.setInline(false);
			upderrors.Body = Blob.valueOf(errheader + errmsgs);
			if (!String.isBlank(errmsgs)) listOfAttachments.add(upderrors);
		mail.setFileAttachments(listOfAttachments);
		emailMsgs.add(mail);

		// Only send if records were selected for processing...
		if (resultmap.size()>0 || !String.isBlank(errmsgs)) Messaging.sendEmail(emailMsgs);
		
		// Reset to clear HEAP
		//results = '';
		resultmap = new Map<Id,String>();
		errmsgs = '';
		
	}


	// Schedulable context
	global void execute(SchedulableContext ctx) {
		String maxrcds = Test.isRunningTest() ? '1' : null;
   	
		BatchFixEscVehicle b = new BatchFixEscVehicle(maxrcds, true);
		Database.executeBatch(b, 1);
	}

	// scheduleMe self-scheduler
	public static List<String> scheduleMe() {
		List<String> jobIds = new List<String>();
		BatchFixEscVehicle m = new BatchFixEscVehicle(null, true);
		Integer i = 0;
		for(String cron : BatchFixEscVehicle.CRON_LIST) {
			System.debug(cron);
			String jobname = 'BatchFixEscVehicle_' + String.valueOf(++i);
			if (Test.isRunningTest()) jobname += '_TEST';
			jobIds.add(System.schedule(jobname, cron, m));
		}
		return jobIds;
	}


}