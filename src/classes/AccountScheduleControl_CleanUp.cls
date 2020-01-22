/**
 * AccountScheduleControl_CleanUp
 * Tested by: AccountScheduleControl_CleanUp_TEST
 * Date: May 26, 2017
 * Programmer: Bryan Leaman
 * 
 * Run it now:
Database.executeBatch(new AccountScheduleControl_CleanUp(null, true));

 * Set standard schedule:
AccountScheduleControl_CleanUp.scheduleMe();

 * Set custom schedule:
System.schedule('AccountScheduleControl_CleanUp', 'sec min hr day mth wd year', new AccountScheduleControl_CleanUp(null,true));
 
 */
global class AccountScheduleControl_CleanUp implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
	global final String query;
	global boolean doUpdate;
    global String errmsgs;
    global String results;
    public static final List<String> CRON_LIST = new List<String>{
    	'0 0 3 ? * 1 *'		// 2 a.m. Sun
    };
	
    

	// AccountScheduleControl_CleanUp constructor - generate query string & initialize
	global AccountScheduleControl_CleanUp(String rcdlimit, boolean doUpd) {
		doUpdate = doUpd;
		String soql = 
			'Select Id, Name, Control__c, Balance__c, BeginDate__c, EndDate__c, '
			+ '(select Id from Transaction_Line_Items__r) '
			+ 'From AccountScheduleControl__c ';
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
		List<AccountScheduleControl__c> objs = (List<AccountScheduleControl__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		// List control records with NO related transaction lines
		List<AccountScheduleControl__c> dltCtl =new List<AccountScheduleControl__c>();
		for(AccountScheduleControl__c o : objs) {
			if (o.Transaction_Line_Items__r.size()==0) dltCtl.add(new AccountScheduleControl__c(Id=o.Id));
		}
		
		System.debug('Number of records to update: ' + String.valueOf(dltCtl.size()));
		
		// Do delete control records with no transaction lines
		if (dltCtl.size()>0)  {
			Database.DeleteResult[] dltresults = new List<Database.DeleteResult>();
			if (doUpdate) dltresults = Database.delete(dltCtl, false); 
			//System.debug(saveresults);
			System.debug('List of failed updates:');
			//for(Database.SaveResult sr : saveresults) {
			for(Integer i=0; i<dltCtl.size(); i++) {
				AccountScheduleControl__c o = dltCtl[i];
				Database.DeleteResult dr = dltresults[i];
				String errmsg = o.Id + ',' + o.Name + ': ';
				if (!dr.isSuccess()) {
					for(Database.Error de : dr.getErrors()) {
						errmsg += '[' + String.join(de.getFields(), ', ') + '] ' + de.getMessage() + '\r';
					}
					System.debug(errmsg);
					errmsgs += errmsg;
				}
			}
			System.debug('List complete.');
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
		String csvheader = 'col1,col2,etc\n';
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
		//if (!String.isBlank(results) || !String.isBlank(errmsgs)) Messaging.sendEmail(emailMsgs);
		if  (!String.isBlank(errmsgs)) Messaging.sendEmail(emailMsgs);
		
		// Reset to clear HEAP
		results = '';
		errmsgs = '';
		
	}


	// Schedulable context
	global void execute(SchedulableContext ctx) {
		String maxrcds = Test.isRunningTest() ? '1' : null;
   	
		AccountScheduleControl_CleanUp b = new AccountScheduleControl_CleanUp(maxrcds, true);
		Database.executeBatch(b, 1);
	}

	// scheduleMe self-scheduler
	public static List<String> scheduleMe() {
		List<String> jobIds = new List<String>();
		AccountScheduleControl_CleanUp m = new AccountScheduleControl_CleanUp(null, true);
		Integer i = 0;
		for(String cron : AccountScheduleControl_CleanUp.CRON_LIST) {
			System.debug(cron);
			String jobname = 'AccountScheduleControl_CleanUp_' + String.valueOf(++i);
			if (Test.isRunningTest()) jobname += '_TEST';
			jobIds.add(System.schedule(jobname, cron, m));
		}
		return jobIds;
	}


}