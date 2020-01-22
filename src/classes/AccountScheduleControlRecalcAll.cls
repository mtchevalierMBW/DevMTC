/**
 * AccountScheduleControlRecalcAll
 * Tested by: AccountScheduleControlRecalcAll_TEST
 * Date: Jul 10, 2017
 * Programmer: Bryan Leaman
 * 
 * Run it now:
Database.executeBatch(new AccountScheduleControlRecalcAll(null, true));

 * Set standard schedule:
AccountScheduleControlRecalcAll.scheduleMe();

 * Set custom schedule:
System.schedule('AccountScheduleControlRecalcAll', 'sec min hr day mth wd year', new AccountScheduleControlRecalcAll(null,true));
 
 */
global class AccountScheduleControlRecalcAll implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
	global final String query;
	global boolean doUpdate;
    global String errmsgs;
    global String results;
    public static final List<String> CRON_LIST = new List<String>{
    	'0 0 22 1 1/1 ? *'	// 10 p.m. 1st of every month - 0=sec 0=min 1=hr 1=dayOfMth 1/1=Jan & every 1 mth ?=dayOfWk *=yr
    };
	
    

	// AccountScheduleControlRecalcAll constructor - generate query string & initialize
	global AccountScheduleControlRecalcAll(String rcdlimit, boolean doUpd) {
		doUpdate = doUpd;
		String soql = 
			'Select Id, Name '
			+ 'From AccountScheduleControl__c ';
		soql += 'Order by LastModifiedDate ';
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
		List<AccountScheduleControl__c> objs = (List<AccountScheduleControl__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		// Update
		List<Id> updObjIds =new List<Id>();
		for(AccountScheduleControl__c o : objs) updObjIds.add(o.Id);

		System.debug('Number of records to update: ' + String.valueOf(updObjIds.size()));
		
		// Do updates!
		if (updObjIds.size()>0 && doUpdate)  {
			new AccountScheduleControlProcess().updateControlTotal(updObjIds);
		}

		// Reset results & error messages if getting too large
		if (results.length() + errmsgs.length() > 10000000) {
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
		//String csvheader = 'col1,col2,etc\n';
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		List<String> recipients = new List<String>{ UserInfo.getUserEmail() };
		//if (!org.isSandbox) recipients.add('another.email@mobilityworks.com');
		mail.setToAddresses(recipients); 
		mail.setSubject('Batch update {describe} complete - UPDATES');
		String body = 'Batch update {describe} has completed.\n\n';
		if (!doUpdate) body += 'Test only! NOT Updated!\n\n';
		mail.setPlainTextBody(body);
		
		//Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
		//	resultcsv.setContentType('text/csv');
		//	resultcsv.setFileName('results.csv');
		//	resultcsv.setInline(false);
		//	resultcsv.Body = Blob.valueOf(csvheader + results);
		//	if (!String.isBlank(results)) listOfAttachments.add(resultcsv);
		//Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
		//	upderrors.setContentType('text/plain');
		//	upderrors.setFileName('UpdateErrors.txt');
		//	upderrors.setInline(false);
		//	upderrors.Body = Blob.valueOf(errmsgs);
		//	if (!String.isBlank(errmsgs)) listOfAttachments.add(upderrors);
		//mail.setFileAttachments(listOfAttachments);
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
   	
		AccountScheduleControlRecalcAll b = new AccountScheduleControlRecalcAll(maxrcds, true);
		Database.executeBatch(b, 1);
	}

	// scheduleMe self-scheduler
	public static List<String> scheduleMe() {
		List<String> jobIds = new List<String>();
		AccountScheduleControlRecalcAll m = new AccountScheduleControlRecalcAll(null, true);
		Integer i = 0;
		for(String cron : AccountScheduleControlRecalcAll.CRON_LIST) {
			System.debug(cron);
			String jobname = 'AccountScheduleControlRecalcAll_' + String.valueOf(++i);
			if (Test.isRunningTest()) jobname += '_TEST';
			jobIds.add(System.schedule(jobname, cron, m));
		}
		return jobIds;
	}


}