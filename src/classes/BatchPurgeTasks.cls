/**
 * BatchPurgeTasks
 * Tested by: BatchPurgeTasks_TEST
 * Date: Oct 17, 2017
 * Programmer: Bryan Leaman
 *
 * Coverage:
 *	2017-10-17	77% (61/79)
 *	2018-06-06	82% (105/127)
 *
 * Purge selected tasks if closed and over {n} days old.
 * 
 * Run it now:
Database.executeBatch(new BatchPurgeTasks(180, ' subject like \'Pardot%email:%\' ', null, true));

 * Set standard schedule: 
BatchPurgeTasks.scheduleMe();

 * Set custom schedule:
System.schedule('BatchPurgeTasks_custom', 'sec min hr day mth wd year', 
	new BatchPurgeTasks(6, ' subject like \'Pardot%email:%\' ',null, true));

 */
global class BatchPurgeTasks implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
	global final String query;
	global boolean doUpdate;
    global String errmsgs;
    global String results;
    global Integer daysold;
    global String selection;
    global Date olderthan;
    global Integer recordcount;
    public static final List<String> CRON_LIST = new List<String>{
    	'0 0 2 1 * ? *'		// 2 a.m. 1st of each month
    };
	public static final List<Integer> CRON_RETENTION = new List<Integer>{ 90 };
	public static final List<String> CRON_SELECTION = new List<String>{' subject like \'Pardot%Email:%\' '};
	
    

	// BatchPurgeTasks constructor - generate query string & initialize
	global BatchPurgeTasks(Integer days, String sel, String rcdlimit, boolean doUpd) {
		doUpdate = doUpd;
		daysold = days;
		selection = sel;
		olderthan = Date.today().addDays(-daysold);
		String soql = 
			'Select Id, Subject, WhoId, WhatId, ActivityDate, Status, Priority, OwnerId, Type, Description, '
			+ 'AccountId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, CallType, CallDisposition, CallObject, '
			+ 'TaskSubtype, Source_type__c, CallNeed__c, LastReopenedBy__c, LastReopened__c '
			+ 'From Task '
			+ 'Where activitydate < :olderthan '
			+ ' and isClosed=true ';
		if (!String.isBlank(selection)) soql += ' and ' + selection + ' ';			
		soql += ' Order by CreatedDate desc ';
		if (!String.isBlank(rcdlimit))	soql += 'Limit ' + rcdlimit + ' ';
		query = soql;
		errmsgs = '';
		results = '';
		recordcount=0;
	}


	// start - query the database
	global Database.QueryLocator start(Database.BatchableContext bc) {
		System.debug(query);
		return Database.getQueryLocator(query);
	}


	// execute for a batch of records
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<Task> objs = (List<Task>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		// Update
		List<Task> dltObjs =new List<Task>();
		for(SObject o : objs) dltObjs.add(new Task(Id=o.Id));
		
		System.debug('Number of records to delete: ' + String.valueOf(dltObjs.size()));
		
		// Do updates!
		if (dltObjs.size()>0)  {
			Database.DeleteResult[] saveresults = new List<Database.DeleteResult>();
			if (doUpdate) saveresults = Database.delete(dltObjs, false); 
			//System.debug(saveresults);
			System.debug('List of failed deletes:');
			//for(Database.SaveResult sr : saveresults) {
			for(Integer i=0; i<dltObjs.size(); i++) {
				Task o = dltObjs[i];
				Database.DeleteResult sr = saveresults.size()>=i ? saveresults[i] : null;
				if (sr!=null && !sr.isSuccess()) {
					//System.debug(sr);
					String errmsg = o.Id + ',' + o.Subject + ': ';
					for(Database.Error de : sr.getErrors()) {
						errmsg += '[' + String.join(de.getFields(), ', ') + '] '
							+ de.getMessage() + '\r';
					}
					System.debug(errmsg);
					errmsgs += errmsg;
				}
			}
			recordcount += dltObjs.size();
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
		String csvheader = '\n';
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		List<String> recipients = new List<String>{ UserInfo.getUserEmail() };
		//if (!org.isSandbox) recipients.add('another.email@mobilityworks.com');
		mail.setToAddresses(recipients); 
		mail.setSubject('Batch delete old closed tasks complete - UPDATES');
		String body = 'Batch delete old closed tasks has completed.\n\n';
		if (!doUpdate) body += 'Test only! NOT Updated!\n\n';
		body += 'Requested delete of ' + String.valueOf(recordcount) 
			+ ' tasks older than ' + olderthan 
			+ ' using selection criteria: ' + selection + '\n';
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
		recordcount = 0;
		
	}



	// Schedulable context
	global void execute(SchedulableContext ctx) {
		String maxrcds = Test.isRunningTest() ? '1' : null;
		BatchSchedule__c bs = [
			select Name, ClassName__c, CronSchedule__c, Parameters__c, ScheduledJobId__c, Active__c, BatchSize__c
			from BatchSchedule__c
			where ScheduledJobId__c=:ctx.getTriggerId()
		];
		
		// default run params (no dynamic params specified)
		List<Object> runparams = new List<Object>();
		ScheduleParameters sp = new ScheduleParameters(180, 'subject like \'Pardot%Email:%\' ');
		runparams.add(sp);
		
		// dynamic run params
		if (!String.isBlank(bs.Parameters__c)) runparams = (List<Object>) JSON.deserializeUntyped(bs.Parameters__c);

		// Apply run parameters & submit job...
		for(Object o : runparams) {
			Map<String,Object> params = (Map<String,Object>) o; 
			Integer daysold = Integer.valueOf(params.get('Retention'));
			String selection = (String) params.get('Selection');
			BatchPurgeTasks b = new BatchPurgeTasks(daysold, selection, maxrcds, true);
			Database.executeBatch(b, Integer.valueOf(bs.BatchSize__c));
		}
	}

	// scheduleMe self-scheduler
	public static List<String> scheduleMe() {
		String thisClassName = BatchPurgeTasks.class.getName();
		// from schedule custom settings
		List<BatchSchedule__c> bss = [
			select Name, ClassName__c, CronSchedule__c, Parameters__c, ScheduledJobId__c, Active__c, BatchSize__c
			from BatchSchedule__c 
			where ClassName__c=:thisClassName
		];
		// First remove existing scheduled jobs ... 
		for(BatchSchedule__c bs : bss) {
			try {
				if (!String.isBlank(bs.ScheduledJobId__c)) System.abortJob((Id) bs.ScheduledJobId__c);
			} catch(Exception e) {System.debug(e);}
		}

		// set default schedule if none found
		Integer i = 0;
		if (bss.size()==0) {
			for(String cron : BatchPurgeTasks.CRON_LIST) {
				String params = '';
				params += '{"Retention":"' + BatchPurgeTasks.CRON_RETENTION[i] + '", '
						+ '"Selection":"' + BatchPurgeTasks.CRON_SELECTION[i] + '"}';
				String devname = thisClassName.left(37) + '_' + String.valueOf(i);
				bss.add(new BatchSchedule__c(
					Name = devname,
					ClassName__c = thisClassName,
					CronSchedule__c = cron,
					Parameters__c = '[' + params + ']',
					BatchSize__c = 500,
					Active__c=true
				));
				++i;
			}
		}
		
		// Now schedule the jobs that are in the BatchSchedule list for this class
		List<String> jobIds = new List<String>();
		BatchPurgeTasks m = new BatchPurgeTasks(180, ' subject like \'Pardot%Email:%\' ', null, true);
		for(BatchSchedule__c bs : bss) {
			System.debug(bs.CronSchedule__c);
			String jobname = bs.Name;
			if (Test.isRunningTest()) jobname += '_TEST';
			if (bs.Active__c) {
				Id jobId = System.schedule(jobname, bs.CronSchedule__c, m);
				bs.ScheduledJobId__c = jobId;
				jobIds.add(jobId);
			}
		}
		upsert(bss);
		return jobIds;
	}

	class ScheduleParameters {
		public Integer Retention {get;set;}
		public String Selection {get;set;}
		public ScheduleParameters(Integer days, String sel) { 
			Retention = days; 
			Selection = sel;
		}
	}

}