/**
 * SolutionOppFollowUpTasks
 * Tested by: SolutionOppFollowUpTasks_TEST
 * Date: 2019-04-01
 * Programmer: Bryan Leaman
 * Project: W-000528
 *
 * Replace process builder that keeps generating "Too many SOQL Queries" errors.
 * Relies on trigger to call resetFollowupStageIfChanged to reset the followup stage to null 
 * whenever dealer__Latest_Appointment_Date_Time__c changes and Follow_Up_Stage__c!=null.
 *
 * This process creates follow-up tasks for Pending solution opportunities according to a schedule based on the 
 * number of days since the latest appointment date:
 *	1 day: CMC call client and thank them
 *	2 days: CMC Email client to offer additional info
 *	6 days: GM Call client to offer solution 
 *	13 days: CMC Call Client to engage them (community event, etc)
 *	29 days: GM follow up on solution still pending
 *
 * Coverage:
 *	2019-04-02	89%	(178/198)
 *
 * Modifications: 
 *
 * Run it now:
Database.executeBatch(new SolutionOppFollowUpTasks(null, true, false));
 * parms: null or rcd limit '100'; true=perform updates; false=log dml 

 * Set standard schedule:
SolutionOppFollowUpTasks.scheduleMe();

 * Set custom schedule:
System.schedule('SolutionOppFollowUpTasks', 'sec min hr day mth wd year', new SolutionOppFollowUpTasks(null,true));

 */
 global class SolutionOppFollowUpTasks implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

	global final String query;
	global boolean doUpdate;
	global boolean logDMLOpps;
	global String errmsgs;
	global Map<Id,String> resultmap;
	global List<String> taskmsgs;
	global Map<Id,Id> StoreGM;
	public static final List<String> CRON_LIST = new List<String>{
		'0 0 6 * * ? *'		// 6 a.m. daily
	};

	// resetFollowupStageIfChanged - called from trigger on dealer__Sales_Up__c
	// Called from trigger to reset the followup stage when last appointment date/time changes
	public static void resetFollowupStageIfChanged(List<dealer__Sales_Up__c> newlist, Map<Id, dealer__Sales_Up__c> oldMap) {
		for(dealer__Sales_Up__c sup : newlist) {
			dealer__Sales_Up__c oldsup = oldMap!=null ? oldMap.get(sup.Id) : null;
			if ((oldsup==null && sup.dealer__Latest_Appointment_Date_Time__c!=null) 
				|| (oldsup!=null && sup.dealer__Latest_Appointment_Date_Time__c!=oldsup.dealer__Latest_Appointment_Date_Time__c)) {
				sup.Follow_Up_Stage__c = null;
			}
		}	
	}


	// SolutionOppFollowUpTasks constructor - generate query string & initialize
	global SolutionOppFollowUpTasks(String rcdlimit, boolean doUpd, boolean logdml) {
		doUpdate = doUpd;
		logDMLOpps = logdml;

		// Tasks are generated for Pending opportunities with no existing follow-up tasks and that haven't
		// gone through the full range of follow-ups.
		String soql = 
			'Select Id, Name, dealer__Latest_Appointment_Date_Time__c, Follow_Up_Stage__c, '
			+	'dealer__Customer_Account__c, dealer__Salesperson_1__c, dealer__Buyer_Contact__c, '
			+	'OwnerId, Company__c '
			+ 'From dealer__Sales_Up__c '
			+ 'Where dealer__Lead_Status__c=\'Pending\' '
			+   'and dealer__Incomplete_Tasks__c=false '
			+   'and dealer__First_Visit__c=true '
			+	'and dealer__Latest_Appointment_Date_Time__c!=null '
			+   'and (Follow_Up_Stage__c=null or Follow_Up_Stage__c in (\'1\', \'2\', \'3\', \'4\', \'5\') ) ';
		soql += 'Order by dealer__Latest_Appointment_Date__c ';
		if (!String.isBlank(rcdlimit))	soql += 'Limit ' + rcdlimit + ' ';
		query = soql;
		errmsgs = '';
		resultmap = new Map<Id, String>();
		taskmsgs = new List<String>();
	}


	// start - query the database
	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);
	}


	// generate map to store GMs
	public void MapStoreGMs(List<dealer__Sales_Up__c> objs) {
		StoreGM = new Map<Id,Id>();
		Set<Id> StoreIds = new Set<Id>();
		for(dealer__Sales_Up__c s : objs) {
			if (s.Company__c!=null) StoreIds.add(s.Company__c);
		}
		// link store GM id to location id for easy reference when assigning tasks
		for(dealer__Dealer_Location__c l : [select Id, dealer__General_Manager__c from dealer__Dealer_Location__c where Id in :StoreIds]) {
			StoreGM.put(l.Id, l.dealer__General_Manager__c);
		}
	}

	// execute for each batch of records
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<dealer__Sales_Up__c> objs = (List<dealer__Sales_Up__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		// Get Store GMs for all stores referenced in this batch
		MapStoreGMs(objs);

		// Generate followup tasks according to schedule and update the solution opportunity's follow-up stage
		List<dealer__Sales_Up__c> updObjs = new List<dealer__Sales_Up__c>();	// to update the follow-up stage
		List<Task> newTasks = new List<Task>();	// list of new tasks to generate
		for(dealer__Sales_Up__c o : objs) {
			Integer dayspast = o.dealer__Latest_Appointment_Date_Time__c.date().daysBetween(Date.today());
			String stage = o.Follow_Up_Stage__c;
			String newStage = stage;

			// Note that all solution opportunities in a follow-up stage are examined, 
			// but a new task is generated only if the number of days meets or exceeds
			// the defined schedule based on the current follow-up stage
			if (stage==null || stage=='1') {
				if (dayspast>=1) {
					newTasks.add(generateTask(o));
					newStage = '2';
				} else {
					newStage = '1';
				}
			}
			if (stage=='2' && dayspast>=2) {
				newTasks.add(generateTask(o));
				newStage = '3';
			}
			if (stage=='3' && dayspast>=6) {
				newTasks.add(generateTask(o));
				newStage = '4';
			}
			if (stage=='4' && dayspast>=13) {
				newTasks.add(generateTask(o));
				newStage = '5';
			}
			if (stage=='5' && dayspast>=29) {
				newTasks.add(generateTask(o));
				newStage = 'DONE';
			}
			// update the solution opportunity's follow-up stage
			if (newstage!=stage) {
				updObjs.add(new dealer__Sales_Up__c(
					Id=o.Id, Follow_Up_Stage__c=newstage
				));
			}
		}
		
		System.debug('Number of records to update: ' + String.valueOf(updObjs.size()));
		
		// Do updates!
		Database.SaveResult[] taskresults = new List<Database.SaveResult>();
		Database.SaveResult[] supresults = new List<Database.SaveResult>();
		if (newTasks.size()>0) {
			if (doUpdate) taskresults = Database.insert(newTasks, false); 
		}
		if (updObjs.size()>0)  {
			if (doUpdate) supresults = Database.update(updObjs, false);
		}

		// Report errors and optionally successes of new tasks
		for(Integer i=0; i<newTasks.size(); i++) {
			Task o = newTasks[i];
			String resultline = '';
			String errmsg = '';
			Database.SaveResult sr = taskresults.size()>i ? taskresults[i] : null;
			if (sr!=null && !sr.isSuccess()) {
				String errmsgline = o.Id + ',' + o.Subject + ': ';
				for(Database.Error de : sr.getErrors()) {
					errmsgline += '[' + String.join(de.getFields(), ', ') + '] '
						+ de.getMessage() + '\r';
					errmsg += de.getMessage() + '; ';
				}
				System.debug(errmsgline);
				errmsgs += errmsgline;
				errmsg = errmsg.replaceAll('\\s',' ');
				if (o.Id!=null && resultline!=null) taskmsgs.add(resultline+',"Error:'+errmsg+'"');
			} else {
				if (!doUpdate || logDMLOpps) taskmsgs.add(JSON.serialize(o));
			}
		}

		// Report errors and optionally successes of solution opportunity updates
		for(Integer i=0; i<updObjs.size(); i++) {
			dealer__Sales_Up__c o = updObjs[i];
			String resultline = resultmap.get(o.Id);
			String errmsg = '';
			Database.SaveResult sr = supresults.size()>i ? supresults[i] : null;
			if (sr!=null && !sr.isSuccess()) {
				String errmsgline = o.Id + ',' + o.Name + ': ';
				for(Database.Error de : sr.getErrors()) {
					errmsgline += '[' + String.join(de.getFields(), ', ') + '] '
						+ de.getMessage() + '\r';
					errmsg += de.getMessage() + '; ';
				}
				System.debug(errmsgline);
				errmsgs += errmsgline;
				errmsg = errmsg.replaceAll('\\s',' ');
				if (o.Id!=null && resultline!=null) resultmap.put(o.Id,resultline+',"Error:'+errmsg+'"');
			} else {
				if (!doUpdate || logDMLOpps) resultmap.put(o.Id, JSON.serialize(o));
			}
		}

		// Reset results & error messages if getting too large
		if (Limits.getLimitHeapSize() - Limits.getHeapSize() < 1000000)	sendEmail();

	}
	

	// Generate task based on current follow-up stage
	global Task generateTask(dealer__Sales_Up__c sup) {
		Task t = new Task(
			ActivityDate = Date.today().addDays(1),
			Priority = 'Normal',
			Status = 'Not Started',
			WhatId = sup.Id,
			Account__c = sup.dealer__Customer_Account__c,
			WhoId = sup.dealer__Buyer_Contact__c
		);
		if (sup.Follow_Up_Stage__c==null || sup.Follow_Up_Stage__c=='1') {
			t.Subject = 'Call Client';
			t.Description = 'Call the client to  thank them for their visit and follow up on yesterdays appointment.';
			t.OwnerId = sup.dealer__Salesperson_1__c;
		}
		if (sup.Follow_Up_Stage__c=='2') {
			t.Subject = 'Email Client';
			t.Description = 'Email the client to see if we can provide any additional information to them.';
			t.OwnerId = sup.dealer__Salesperson_1__c;
		}
		if (sup.Follow_Up_Stage__c=='3') {
			t.Subject = 'Call Client';
			t.Description = 'Information push.  Where are we at with providing this client a solution.  Are we on the right solution?  Did we provide the client with the right information to make a decision.';
			t.OwnerId = StoreGM.get(sup.Company__c);
		}
		if (sup.Follow_Up_Stage__c=='4') {
			t.Subject = 'Call Client';
			t.Description = 'Send your client a relational email of value that has nothing to do with the proposal or purchase of a WAV.  Ex. send them a link to a community event, or something of interest to keep nurturing the relationship. ';
			t.OwnerId = sup.dealer__Salesperson_1__c;
		}
		if (sup.Follow_Up_Stage__c=='5') {
			t.Subject = 'Update Solution Status';
			t.Description = 'Status the Solution Opportunity, set to Lost or keep as Pending and setup a new client TASK for continued follow up';
			t.OwnerId = StoreGM.get(sup.Company__c);
		}
		if (t.OwnerId==null) t.OwnerId = sup.OwnerId;	// default value
		return t;
	}

	
	// finish - send results via email
	global void finish(Database.BatchableContext bc) {
		sendEmail();
	}


	// sendEmail of the results	
	global void sendEmail() {
		Organization org = [select Id, Name, isSandbox from Organization limit 1];
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		List<String> recipients = new List<String>{ UserInfo.getUserEmail() };
		mail.setToAddresses(recipients); 
		mail.setSubject('Solution Opp Follow Up Tasks complete - UPDATES');
		String body = 'Solution Opp Follow Up Tasks has completed.\n\n';
		if (!doUpdate) body += 'Test only! NOT Updated!\n\n';
		mail.setPlainTextBody(body);
		
		Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
			resultcsv.setContentType('text/csv');
			resultcsv.setFileName('soloppupdates.csv');
			resultcsv.setInline(false);
			resultcsv.Body = Blob.valueOf(String.join(resultmap.values(),'\n'));
			if (resultmap.size()>0) listOfAttachments.add(resultcsv);
		Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
			upderrors.setContentType('text/plain');
			upderrors.setFileName('taskerrors.txt');
			upderrors.setInline(false);
			upderrors.Body = Blob.valueOf(String.join(taskmsgs,'\n'));
			if (!String.isBlank(errmsgs)) listOfAttachments.add(upderrors);
		mail.setFileAttachments(listOfAttachments);
		emailMsgs.add(mail);

		// Only send if records were selected for processing...
		if (resultmap.size()>0 || taskmsgs.size()>0) Messaging.sendEmail(emailMsgs);
		
		// Reset to clear HEAP
		resultmap = new Map<Id,String>();
		taskmsgs = new List<String>();
		errmsgs = '';
	}


	// Schedulable context
	global void execute(SchedulableContext ctx) {
		String maxrcds = Test.isRunningTest() ? '1' : null;
		BatchSchedule__c bs = [
			select Name, ClassName__c, CronSchedule__c, Parameters__c, ScheduledJobId__c, Active__c, BatchSize__c
			from BatchSchedule__c
			where ScheduledJobId__c=:ctx.getTriggerId()
		];
		Set<String> trueValues = new Set<String> {'1','true','TRUE','True'};

		// Apply run-time parameters from BatchSchedule__c settings 
		// Run-time parms are a list of objects and the batch job runs once for each list
		// e.g. [{"parm1name":"parm1value", "parm2name":"parm2value"}, {...next run parms...}]
		// This specific use-case only makes sense for there to be 1 array element
		List<Object> runparams = new List<Object>();
		runparams.add(new Map<String,Object>());
		if (!String.isBlank(bs.Parameters__c)) runparams = (List<Object>) JSON.deserializeUntyped(bs.Parameters__c);
		for(Object o : runparams) {
			Map<String,Object> params = (Map<String,Object>) o;
			boolean logDML = trueValues.contains((String) params.get('LogDML'));
			// Execute for this instance of run parameters
			SolutionOppFollowUpTasks b = new SolutionOppFollowUpTasks(maxrcds, true, logDML);
			Database.executeBatch(b, Integer.valueOf(bs.BatchSize__c));
		}

	}

	// scheduleMe self-scheduler
	public static List<String> scheduleMe() {
		String thisClassName = SolutionOppFollowUpTasks.class.getName();
		// Get current schedule from schedule custom settings
		List<BatchSchedule__c> bss = [
			select Name, ClassName__c, CronSchedule__c, Parameters__c, ScheduledJobId__c, Active__c, BatchSize__c
			from BatchSchedule__c 
			where ClassName__c=:thisClassName
		];

		// First remove existing scheduled jobs from the existing schedule custom settings... 
		for(BatchSchedule__c bs : bss) {
			try {
				if (!String.isBlank(bs.ScheduledJobId__c)) System.abortJob((Id) bs.ScheduledJobId__c);
			} catch(Exception e) {System.debug(e);}
		}

		// set default schedule if none found
		Integer i = 0;
		if (bss.size()==0) {
			for(String cron : SolutionOppFollowUpTasks.CRON_LIST) {
				String devname = thisClassName.left(37) + '_' + String.valueOf(i);
				bss.add(new BatchSchedule__c(
					Name = devname,
					ClassName__c = thisClassName,
					CronSchedule__c = cron,
					BatchSize__c = 5,	// may need to be very small due to cascading trigger dml operations
					Active__c=true
				));
				++i;
			}
		}
		
		// Now (re-)schedule the jobs that are in the BatchSchedule list for this class
		List<String> jobIds = new List<String>();
		SolutionOppFollowUpTasks m = new SolutionOppFollowUpTasks(null, true, false);
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

}