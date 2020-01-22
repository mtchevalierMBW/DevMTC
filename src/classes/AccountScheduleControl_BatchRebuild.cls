/**
 * AccountScheduleControl_BatchRebuild
 * Tested by: AccountScheduleControlProcess_TEST
 * Date: May 26, 2017
 * Programmer: Bryan Leaman
 *
 * NOTE: This is the starting point to rebuild account schedule controls.
 * This step clears the account schedules and then launches a build job to build them back up.
 *  
 * Run it now:
Database.executeBatch(new AccountScheduleControl_BatchRebuild(null, true, null, null, null));
Database.executeBatch(new AccountScheduleControl_BatchRebuild(null, true, {'1208'}, null, null));  // acct 1208, all dim1s
Database.executeBatch(new AccountScheduleControl_BatchRebuild(null, true, {'1208'}, {'112'}, null));  // acct 1208 for AKR
Database.executeBatch(new AccountScheduleControl_BatchRebuild(null, true, null, null, {'1234B','RO#AKR001234'}));  // Two control nbrs

 * Set standard schedule:
AccountScheduleControl_BatchRebuild.scheduleMe();

 * Set custom schedule:
System.schedule('AccountScheduleControl_BatchRebuild', 'sec min hr day mth wd year', 
	new AccountScheduleControl_BatchRebuild(null,true,null,null,null));  // only null allowed -- parms are ignored
 
 */
global class AccountScheduleControl_BatchRebuild implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
	global final String query;
	global String maxRecords;
	global boolean doUpdate;
    global String errmsgs;
    global String results;
    global List<String> selected_GL_Accounts;
    global List<String> selected_Dimension1s;
    global List<String> selected_Controls;
    public static final List<String> CRON_LIST = new List<String>{
    	'0 0 1 1 1/1 ? *'	// 1 a.m. 1st of every month - 0=sec 0=min 1=hr 1=dayOfMth 1/1=Jan & every 1 mth ?=dayOfWk *=yr
    };
	
    

	// AccountScheduleControl_BatchRebuild constructor - generate query string & initialize
	global AccountScheduleControl_BatchRebuild(String rcdlimit, boolean doUpd, List<String> GLAccts, List<String> Dim1s, List<String> Ctrls) {
		doUpdate = doUpd;
		maxRecords = rcdlimit;
		selected_GL_Accounts = GLAccts;
		selected_Dimension1s = Dim1s;
		selected_Controls = Ctrls;

		List<String> whereClauses = new List<String>();
		String soql = 
			'Select Id, Name, Balance__c, BeginDate__c, EndDate__c '
			+ 'From AccountScheduleControl__c ';
		if (GLAccts!=null && GLAccts.size()>0) 
			whereClauses.add(' GeneralLedgerAccount__r.c2g__ExternalId__c in (\'' +  String.join(GLAccts, '\',\'') + '\') '); 
		if (Dim1s!=null && Dim1s.size()>0) 
			whereClauses.add(' Dimension1__r.c2g__ExternalId__c in (\'' +  String.join(Dim1s, '\',\'') + '\') ');
		if (Ctrls!=null && Ctrls.size()>0) 
			whereClauses.add(' Control__c in (\'' +  String.join(Ctrls, '\',\'') + '\') ');
		if (whereClauses.size()>0) soql += ' where ' + String.join(whereClauses,' and '); 
		soql += 'Order by CreatedDate desc '
			 + (!String.isBlank(rcdlimit) ? ('Limit ' + rcdlimit) : '') + ' ';
		query = soql;
		errmsgs = '';
		results = '';
	}


	// start - query the database
	global Database.QueryLocator start(Database.BatchableContext bc) {
		// Turn off account schedule control trigger until this process is complete
		MW_TriggerControls__c AccountScheduleControl = MW_TriggerControls__c.getInstance('AccountScheduleControl');
		if (AccountScheduleControl==null) AccountScheduleControl=new MW_TriggerControls__c(Name='AccountScheduleControl');
		AccountScheduleControl.Enabled__c = false;
		upsert(AccountScheduleControl);
		
		return Database.getQueryLocator(query);
	}


	// execute for a batch of records
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<AccountScheduleControl__c> objs = (List<AccountScheduleControl__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		// Update
		for(AccountScheduleControl__c ctl : objs) {
			ctl.Balance__c = 0.00;
			ctl.BeginDate__c = null;
			ctl.EndDate__c = null;
			//asc.ResetDateTime__c = resetDT;	// When accumulating (next step), ignore any records created after this timestamp 
		}
		
		System.debug('Number of records to update: ' + String.valueOf(objs.size()));
		
		// Do updates!
		if (objs.size()>0)  {
			Database.SaveResult[] saveresults = new List<Database.SaveResult>();
			if (doUpdate) saveresults = Database.update(objs, false); 
			//System.debug(saveresults);
			System.debug('List of failed updates:');
			for(Database.SaveResult sr : saveresults) {
				if (!sr.isSuccess()) {
					System.debug(sr);
					errmsgs += sr.getId() + ': ';
					for(Database.Error de : sr.getErrors()) {
						errmsgs += '[' + String.join(de.getFields(), ',') + '] '
							+ de.getMessage() + '\r';
					}
				}
			}
			System.debug('List complete.');
		}

	}
	
	
	// finish - send results via email
	global void finish(Database.BatchableContext bc) {
		sendEmail();
		// now that they're cleared out, launch rebuild
		AccountScheduleControl_BatchBuild ba = 
			new AccountScheduleControl_BatchBuild('', doUpdate, selected_GL_Accounts, selected_Dimension1s, selected_Controls);
		Database.executeBatch(ba);
	}


	// sendEmail of the results	
	global void sendEmail() {
		Organization org = [select Id, Name, isSandbox from Organization limit 1];
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(new String[] { UserInfo.getUserEmail() }); 
		mail.setSubject('Batch clear AccountScheduleControl complete');
		String body = 'Batch clear AccountScheduleControl has completed.\n\n';
		if (!doUpdate) body += 'Test only! NOT Updated!\n\n';
		mail.setPlainTextBody(body);
		
		//Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
		//	resultcsv.setContentType('text/csv');
		//	resultcsv.setFileName('results.csv');
		//	resultcsv.setInline(false);
		//	resultcsv.Body = Blob.valueOf(results);
		//	if (!String.isBlank(results)) listOfAttachments.add(resultcsv);
		Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
			upderrors.setContentType('text/plain');
			upderrors.setFileName('UpdateErrors.txt');
			upderrors.setInline(false);
			upderrors.Body = Blob.valueOf(errmsgs);
			if (!String.isBlank(errmsgs)) listOfAttachments.add(upderrors);
		mail.setFileAttachments(listOfAttachments);
		emailMsgs.add(mail);

		Messaging.sendEmail(emailMsgs);
	}


	// Schedulable context
	global void execute(SchedulableContext ctx) {
		String maxrcds = Test.isRunningTest() ? '1' : null;
   	
		//AccountScheduleControl_BatchRebuild b = new AccountScheduleControl_BatchRebuild(maxrcds, true, null, null);
		AccountScheduleControl_BatchRebuild b = new AccountScheduleControl_BatchRebuild(maxRecords, doUpdate, selected_GL_Accounts, selected_DImension1s, selected_Controls);
		Database.executeBatch(b, 1);
	}

	// scheduleMe self-scheduler
	public static List<String> scheduleMe() {
		List<String> jobIds = new List<String>();
		AccountScheduleControl_BatchRebuild m = new AccountScheduleControl_BatchRebuild(null, true, null, null, null);
		Integer i = 0;
		for(String cron : AccountScheduleControl_BatchRebuild.CRON_LIST) {
			System.debug(cron);
			String jobname = 'AccountScheduleControl_BatchRebuild_' + String.valueOf(++i);
			if (Test.isRunningTest()) jobname += '_TEST';
			jobIds.add(System.schedule(jobname, cron, m));
		}
		return jobIds;
	}


}