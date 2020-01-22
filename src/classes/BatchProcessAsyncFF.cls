/**
 * BatchProcessAsyncFF
 * Tested by: BatchProcessAsyncFF_TEST
 * Date: 2019-03-15
 * Programmer: Bryan Leaman
 * Project: W-000575
 *
 * Coverage:
 *	2019-03-15	92%	(144/156)
 * 
 * Modifications: 
 *
**/

global class BatchProcessAsyncFF implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

	public static final List<String> CRON_LIST = new List<String>{
		'0 0 * * * ? *',		// x:00 - on the hour
		'0 5 * * * ? *',		// x:05
		'0 10 * * * ? *',		// x:10
		'0 15 * * * ? *',		// x:15
		'0 20 * * * ? *',		// x:20
		'0 25 * * * ? *',		// x:25
		'0 30 * * * ? *',		// x:30
		'0 35 * * * ? *',		// x:35
		'0 40 * * * ? *',		// x:40
		'0 45 * * * ? *',		// x:45
		'0 50 * * * ? *',		// x:50
		'0 55 * * * ? *'		// x:55
	};
	public static final List<String> CRON_MAXAGEMINUTES = new List<String>{ 
		'6' 
	};
	public static final List<String> CRON_MAXREQUESTS = new List<String>{
		''
	};
	public static final List<String> CRON_RESCHEDULE = new List<String>{
		''
	};

	global final String query;
	global String errmsgs;
	global String results;
	global Set<String> processlog;
    
	global boolean doUpdate;
	global String maxageminutes;
	global String maxrequests;
	global String reschedulemin;

	global BatchProcessAsyncFF(String minutesold, String rcdlimit, String resched, boolean doUpd) {
		doUpdate = doUpd;
		maxageminutes = minutesold;
		maxrequests = rcdlimit;
		reschedulemin = resched;

		DateTime oldest = DateTime.now();

		String soql = 'select Id, Name, Action__c, Payload__c, ReprocessDateTime__c, ReprocessUser__c, SourceObjectId__c '	// BLL1c
			+ ' from FFAccountingFailure__c'
			+ ' where ReprocessDateTime__c=null and ReprocessUser__c=null ';
		if (!String.isBlank(minutesold)) {
			oldest = oldest.addMinutes(Integer.valueOf(minutesold));
			soql += ' and CreatedDate >= ' + oldest.format('yyyy-MM-dd\'T\'hh:mm:ss.SSS\'Z\'') + ' ';
		}
		soql += ' Order by CreatedDate desc ';
		if (!String.isBlank(rcdlimit)) soql += ' Limit ' + rcdlimit + ' ';
		query = soql;
		System.debug(soql);
		errmsgs = '';
		results = '';
		processlog = new Set<String>();	
	}

	global Database.QueryLocator start(Database.BatchableContext bc) {
		System.debug(query);
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<FFAccountingFailure__c> objs = (List<FFAccountingFailure__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		// Update records to process so another batch process will not pick them up!
		List<FFAccountingFailure__c> updObjs =new List<FFAccountingFailure__c>();
		for(FFAccountingFailure__c o : objs) {
			FFAccountingFailure__c updrcd = new FFAccountingFailure__c(	// BLL1c
				Id=o.Id, ReprocessDateTime__c = DateTime.now(), ReprocessUser__c = UserInfo.getUserId()
			);
			String logitem = o.SourceObjectId__c + '-' + o.Action__c;
			if (processlog.contains(logitem)) {
				updrcd.Action__c = o.Action__c + ':DUP';
			} else {
				processlog.add(logitem);	// BLL1a
				AccountingEmailService aes = new AccountingEmailService();
				Messaging.InboundEmail email = new Messaging.InboundEmail();
				email.Subject = 'Reprocess Posting';
				email.plainTextBody = o.Payload__c;
				Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
				if (doUpdate) aes.handleInboundEmail(email, envelope);
			}	// BLL1a
			
			results += '[' + updrcd.Action__c + ';' + updrcd.SourceObjectId__c + '] ' + o.Payload__c + '\n';
			updObjs.add(updrcd);	// BLL1a
		}
		
		System.debug('Number of records to update: ' + String.valueOf(updObjs.size()));
		
		// Do updates!
		if (updObjs.size()>0)  {
			Database.SaveResult[] saveresults = new List<Database.SaveResult>();
			if (doUpdate) saveresults = Database.update(updObjs, false); 
			//System.debug(saveresults);
			System.debug('List of failed updates:');
			for(Database.SaveResult sr : saveresults) {
				if (!sr.isSuccess()) {
					System.debug(sr);
					errmsgs += sr.getId() + ': ';
					for(Database.Error de : sr.getErrors()) {
						errmsgs += '[' + String.join(de.getFields(),', ') + '] '
							+ de.getMessage() + '\r';
					}
				}
			}
			System.debug('List complete.');
		}

	}
	
	
	global void finish(Database.BatchableContext bc) {
		
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(new String[] { UserInfo.getUserEmail() }); 

		// get recipient overrides from custom setting
		MobilityForceSettings__c mfs = MobilityForceSettings__c.getOrgDefaults();
		if (!String.isBlank(mfs.BatchRecipientsAsyncFF__c)) mail.setToAddresses(mfs.BatchRecipientsAsyncFF__c.split(','));

		mail.setSubject('Batch update Reprocess Async FF complete - ERRORS');
		String body = 'Batch update Reprocess Async FF has completed.\n\n';
		if (!doUpdate) body += 'Test only! NOT Updated!\n\n';
		mail.setPlainTextBody(body);
		
		Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
			resultcsv.setContentType('text/plain');
			resultcsv.setFileName('results.txt');
			resultcsv.setInline(false);
			resultcsv.Body = Blob.valueOf(results);
			if (!String.isBlank(results)) listOfAttachments.add(resultcsv);
		Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
			upderrors.setContentType('text/plain');
			upderrors.setFileName('UpdateErrors.txt');
			upderrors.setInline(false);
			upderrors.Body = Blob.valueOf(errmsgs);
			if (!String.isBlank(errmsgs)) listOfAttachments.add(upderrors);
		mail.setFileAttachments(listOfAttachments);
		emailMsgs.add(mail);

		// Try to send an email confirmation -- will succeed if sent after the salesforce limit resets at midnight GMT
		try {
			if (!String.isBlank(errmsgs)) Messaging.sendEmail(emailMsgs);
		} catch(Exception e) {}

		// reschedule self in 'n' minutes
		if (!String.isBlank(reschedulemin)) {
			String jobname = 'BatchProcessAsyncFF_' + DateTime.now().format('yyyyMMdd_hh:mm');
			BatchProcessAsyncFF b = new BatchProcessAsyncFF(maxageminutes, maxrequests, reschedulemin, true);
			System.scheduleBatch(b, jobname, Integer.valueOf(reschedulemin));
		}
		
	}


	// Schedulable context
	global void execute(SchedulableContext ctx) {
		String maxrcds = Test.isRunningTest() ? '1' : '';
		List<BatchSchedule__c> bss = [
			select Name, ClassName__c, CronSchedule__c, Parameters__c, ScheduledJobId__c, Active__c, BatchSize__c
			from BatchSchedule__c
			where ScheduledJobId__c=:ctx.getTriggerId()
		];
		BatchSchedule__c bs = bss.size()>0 ? bss[0] : new BatchSchedule__c(Parameters__c='');
		
		// default run params (no dynamic params specified)
		List<Object> runparams = new List<Object>();
		ScheduleParameters sp = new ScheduleParameters(maxageminutes, maxrequests, reschedulemin);
		runparams.add(sp);
		
		// dynamic run params
		if (!String.isBlank(bs.Parameters__c)) runparams = (List<Object>) JSON.deserializeUntyped(bs.Parameters__c);

		// Apply run parameters & submit job...
		for(Object o : runparams) {
			Map<String,Object> params = (Map<String,Object>) o; 
			String maxageminutes = (String) params.get('MaxAgeMinutes');
			String maxrequests = (String) params.get('MaxRequests');
			String reschedulemin = (String) params.get('RescheduleMinutes');
			if (bs==null || bs.Active__c) {
				BatchProcessAsyncFF b = new BatchProcessAsyncFF(maxageminutes, maxrequests, reschedulemin, true);
				Database.executeBatch(b, Integer.valueOf(bs.BatchSize__c));
			}
		}
	}


	// scheduleMe self-scheduler
	public static List<String> scheduleMe() {
		String thisClassName = BatchProcessAsyncFF.class.getName();
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
			for(String cron : BatchProcessAsyncFF.CRON_LIST) {
				String params = '';
				Integer p1 = i<BatchProcessAsyncFF.CRON_MAXAGEMINUTES.size() ? i : BatchProcessAsyncFF.CRON_MAXAGEMINUTES.size()-1;
				Integer p2 = i<BatchProcessAsyncFF.CRON_MAXREQUESTS.size() ? i : BatchProcessAsyncFF.CRON_MAXREQUESTS.size()-1;
				Integer p3 = i<BatchProcessAsyncFF.CRON_RESCHEDULE.size() ? i : BatchProcessAsyncFF.CRON_RESCHEDULE.size()-1;
				params += '{"MaxAgeMinutes":"' + BatchProcessAsyncFF.CRON_MAXAGEMINUTES[p1] + '", '
					+ '"MaxRequests":"' + BatchProcessAsyncFF.CRON_MAXREQUESTS[p2] + '", '
					+ '"RescheduleMinutes":"' + BatchProcessAsyncFF.CRON_RESCHEDULE[p3] + '"}';
				String devname = thisClassName.left(37) + '_' + String.valueOf(i);
				bss.add(new BatchSchedule__c(
					Name = devname,
					ClassName__c = thisClassName,
					CronSchedule__c = cron,
					Parameters__c = '[' + params + ']',
					BatchSize__c = 1,	// must run 1 at a time due to company changes
					Active__c=true
				));
				++i;
			}
		}
		
		// Now schedule the jobs that are in the BatchSchedule list for this class
		List<String> jobIds = new List<String>();
		BatchProcessAsyncFF m = new BatchProcessAsyncFF('8', '100', '', true);
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
		public String MaxAgeMinutes {get;set;}
		public String MaxRequests {get;set;}
		public String RescheduleMinutes {get;set;}
		public ScheduleParameters(String minutes, String requests, String resched) { 
			MaxAgeMinutes = minutes; 
			MaxRequests = requests;
			RescheduleMinutes = resched;
		}
	}

}