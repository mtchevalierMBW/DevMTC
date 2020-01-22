/**
 * BatchUpdateFlooringPmts
 * Tested by: BatchUpdateFlooringPmts_TEST
 * Date: Mar 14, 2018
 * Programmer: Bryan Leaman
 * 
 * Run it now:
Database.executeBatch(new BatchUpdateFlooringPmts(null, true));

 * Set standard schedule:
BatchUpdateFlooringPmts.scheduleMe();

 * Set custom schedule:
System.schedule('BatchUpdateFlooringPmts', 'sec min hr day mth wd year', new BatchUpdateFlooringPmts(null,true));
 
 *
 * Code coverage:
 *	2018-03-14	92% (71/77)
 *
 */
global class BatchUpdateFlooringPmts implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
	global final String query;
	global boolean doUpdate;
    global String errmsgs;
    global String results;
    public static final List<String> CRON_LIST = new List<String>{
    	'0 30 0 1 * ? *'		// 12:30 a.m. 1st of every month
    };
	
    

	// BatchUpdateFlooringPmts constructor - generate query string & initialize
	global BatchUpdateFlooringPmts(String rcdlimit, boolean doUpd) {
		doUpdate = doUpd;
		String soql = 
			'Select Id, Name '
			+ 'From dealer__Vehicle_Inventory__c '
			+ 'Where Chassis_Floorplan__c!=null and Floorplanned__c=true and Paid__c=false and Original_Floored_Amount__c!=null ';
		//if (!Test.isRunningTest()) soql += 'and (condition) ';
		soql += 'Order by CreatedDate desc ';
		if (!String.isBlank(rcdlimit))	soql += 'Limit ' + rcdlimit + ' ';
		query = soql;
		errmsgs = '';
		results = '';
	}


	// start - query the database
	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);
	}


	// execute for a batch of records
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<dealer__Vehicle_Inventory__c> objs = (List<dealer__Vehicle_Inventory__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		// Update
		List<dealer__Vehicle_Inventory__c> updObjs =new List<dealer__Vehicle_Inventory__c>();
		for(dealer__Vehicle_Inventory__c o : objs) {
				updObjs.add(new dealer__Vehicle_Inventory__c(
					Id=o.Id
				));
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
					String errmsg = o.Id + ',' + o.Name + ': ';
					for(Database.Error de : sr.getErrors()) {
						errmsg += '[' + String.join(de.getFields(), ', ') + '] '
							+ de.getMessage() + '\r';
					}
					System.debug(errmsg);
					errmsgs += errmsg;
				}
			}
			System.debug('List complete.');
		}

		// Reset results & error messages if getting too large
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
		String csvheader = 'col1,col2,etc\n';
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		List<String> recipients = new List<String>{ UserInfo.getUserEmail() };
		//if (!org.isSandbox) recipients.add('another.email@mobilityworks.com');
		mail.setToAddresses(recipients); 
		mail.setSubject('Batch update vehicle flooring payments complete - UPDATES');
		String body = 'Batch update vehicle flooring payments has completed.\n\n';
		if (!doUpdate) body += 'Test only! NOT Updated!\n\n';
		mail.setPlainTextBody(body);
		
		Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
			resultcsv.setContentType('text/csv');
			resultcsv.setFileName('results.csv');
			resultcsv.setInline(false);
			resultcsv.Body = Blob.valueOf(csvheader + results);
			if (!String.isBlank(results)) listOfAttachments.add(resultcsv);
		Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
			upderrors.setContentType('text/plain');
			upderrors.setFileName('UpdateErrors.txt');
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
   	
		BatchUpdateFlooringPmts b = new BatchUpdateFlooringPmts(maxrcds, true);
		Database.executeBatch(b, 1);
	}

	// scheduleMe self-scheduler
	public static List<String> scheduleMe() {
		List<String> jobIds = new List<String>();
		BatchUpdateFlooringPmts m = new BatchUpdateFlooringPmts(null, true);
		Integer i = 0;
		for(String cron : BatchUpdateFlooringPmts.CRON_LIST) {
			System.debug(cron);
			String jobname = 'BatchUpdateFlooringPmts_' + String.valueOf(++i);
			if (Test.isRunningTest()) jobname += '_TEST';
			jobIds.add(System.schedule(jobname, cron, m));
		}
		return jobIds;
	}


}