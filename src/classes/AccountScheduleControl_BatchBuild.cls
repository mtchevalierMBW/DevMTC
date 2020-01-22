/**
 * AccountScheduleControl_BatchBuild
 * Tested by: AccountScheduleControlProcess_TEST
 * Date: May 26, 2017
 * Programmer: Bryan Leaman
 * 
 * NOTE: This is the second step of the AccountScheduleControl_BatchRebuild process and launches
 * automatically when the first step has completed!
 * 
 * Test -- Run it now:
Database.executeBatch(new AccountScheduleControl_BatchBuild(null, true, null, null, null));  // all accts & dim1s
Database.executeBatch(new AccountScheduleControl_BatchBuild(null, true, {'1208'}, null, null));  // acct 1208, all dim1s
Database.executeBatch(new AccountScheduleControl_BatchBuild(null, true, {'1208'}, {'112'}, null));  // acct 1208 for AKR
Database.executeBatch(new AccountScheduleControl_BatchBuild(null, true, null, null, {'1234B','RO#AKR-001234'}));  // two control nbrs

 */
global class AccountScheduleControl_BatchBuild implements Database.Batchable<sObject>, Database.Stateful {
    
	global final String query;
	global boolean doUpdate;
    global String errmsgs;
    global String results;
    global List<String> selected_GL_Accounts;
    global List<String> selected_Dimension1s;
    global List<String> selected_Controls;
    global DateTime lastTransactionDateTime;
    global AccountScheduleControlProcess ascp;
    

	// AccountScheduleControl_BatchBuild constructor - generate query string & initialize
	global AccountScheduleControl_BatchBuild(String rcdlimit, boolean doUpd, List<String> GLAccts, List<String> Dim1s, List<String> Ctrls) {
		doUpdate = doUpd;
		selected_GL_Accounts = GLAccts;
		selected_Dimension1s = Dim1s;
		selected_Controls = Ctrls;

		// Re-enable transaction line trigger so any new transactions can begin updating the account schedule control object
		MW_TriggerControls__c AccountScheduleControl = MW_TriggerControls__c.getInstance('AccountScheduleControl');
		if (AccountScheduleControl==null) AccountScheduleControl=new MW_TriggerControls__c(Name='AccountScheduleControl');
		AccountScheduleControl.Enabled__c = true;
		upsert(AccountScheduleControl);

		// Create account schedule control process once (contains list of accounts enabled)
		ascp = new AccountScheduleControlProcess();

		// Keep track of current date/time and don't include new transactions (after that date/time) since the trigger will
		// handle them.
		lastTransactionDateTime = DateTime.now();	// Don't accumulate for any transactions created after now! The trigger already did it!

		// Process all existing transactions!
		String soql = 'select Id, Name, c2g__HomeValue__c, c2g__GeneralLedgerAccount__c, c2g__Dimension1__c, Control__c, AccountScheduleControl__c, Transaction_Date__c '
			+ 'from c2g__codaTransactionLineItem__c '
			+ 'where c2g__GeneralLedgerAccount__r.ScheduledAccount__c=true '	// only scheduled accounts
			+ '  and CreatedDate < :lastTransactionDateTime ';  //lastTransactionDateTime.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
			
		// Optional rebuild of selected accounts or dimensions only
		if (GLAccts!=null && GLAccts.size()>0) 
			soql += ' and c2g__GeneralLedgerAccount__r.c2g__ExternalId__c in (\'' +  String.join(GLAccts, '\',\'') + '\') '; 
		if (Dim1s!=null && Dim1s.size()>0) 
			soql += ' and c2g__Dimension1__r.c2g__ExternalId__c in (\'' +  String.join(Dim1s, '\',\'') + '\') ';
		if (Ctrls!=null && Ctrls.size()>0) 
			soql += ' and Control__c in (\'' +  String.join(Ctrls, '\',\'') + '\') ';

		soql += 'Order by CreatedDate '
			 + (!String.isBlank(rcdlimit) ? ('Limit ' + rcdlimit) : '') + ' ';

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
		List<c2g__codaTransactionLineItem__c> objs = (List<c2g__codaTransactionLineItem__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		// Update

		// Build set of all referenced account schedule control keys
		Set<String> controlkeys = new Set<String>();
		for(c2g__codaTransactionLineItem__c t : objs) {
			String ctlkey = ascp.constructControlKey(t.c2g__GeneralLedgerAccount__c, t.c2g__Dimension1__c, t.Control__c);
			controlkeys.add(ctlkey);
		}
		
		// Build map of all existing account schedule control records by key
		Map<String, AccountScheduleControl__c> addCtls = new Map<String, AccountScheduleControl__c>();
		Map<String, AccountScheduleControl__c> ctlmap = new Map<String, AccountScheduleControl__c>();
		for(AccountScheduleControl__c ctl : [
			select Id, GeneralLedgerAccount__c, Dimension1__c, Control__c, BeginDate__c, EndDate__c, Balance__c, ScheduleKey__c
			from AccountScheduleControl__c
			where ScheduleKey__c in :controlkeys
		]) { 
			ctlmap.put(ctl.ScheduleKey__c, ctl);
		}
		
		// Process all transaction lines, accumulating balance and recording begin and end dates
		for(c2g__codaTransactionLineItem__c t : objs) {
			String ctlkey = ascp.constructControlKey(t.c2g__GeneralLedgerAccount__c, t.c2g__Dimension1__c, t.Control__c);
			// String.valueOf(t.c2g__GeneralLedgerAccount__c).substring(0,15) + ':' + String.valueOf(t.c2g__Dimension1__c).substring(0,15) + ':' + (t.Control__c!=null ? t.Control__c.toUpperCase() : '');
			AccountScheduleControl__c ctl = ctlmap.get(ctlkey);
			if (ctl==null) ctl = addCtls.get(ctlkey);	// Try list of new control#s already identified
			if (ctl==null) {	// Need to create a new account schedule control record!
				ctl = new AccountScheduleControl__c(Control__c=(t.Control__c!=null ? t.Control__c.toUpperCase() : ''), 
					GeneralLedgerAccount__c = t.c2g__GeneralLedgerAccount__c, Dimension1__c = t.c2g__Dimension1__c,
					BeginDate__c = t.Transaction_Date__c, EndDate__c = t.Transaction_Date__c, Balance__c = t.c2g__HomeValue__c,
					ScheduleKey__c = ctlkey	);
				System.debug('New Account Control ' + ctlkey);
				addCtls.put(ctlkey, ctl);
				ctlmap.put(ctlkey, ctl);
			} else {	// Update existing account schedule control record!
				//if (t.CreatedDate < ctl.ResetDateTime__c) {	// new transaction should already be reflected in ctl (?)
					if (ctl.BeginDate__c==null || t.Transaction_Date__c < ctl.BeginDate__c) ctl.BeginDate__c = t.Transaction_Date__c;
					if (ctl.EndDate__c==null || t.Transaction_Date__c > ctl.EndDate__c) ctl.EndDate__c = t.Transaction_Date__c;
					ctl.Balance__c += t.c2g__HomeValue__c;
					if (ctlkey!=null) ctlmap.put(ctlkey,ctl);
					System.debug('Update Account Control ' + ctlkey);
				//}
			}
		}

		results += 'Number of records to insert: ' + String.valueOf(addCtls.size()) + '\n';
		if (!addCtls.isEmpty() && doUpdate) Database.insert(addCtls.values());
		results += 'Number of records to update: ' + String.valueOf(ctlmap.size()) + '\n';
		if (!ctlmap.isEmpty() && doUpdate) Database.update(ctlmap.values());

		// Now update transaction line link to control rcd (if the control id changed)
		ctlmap.putAll(addCtls);
		
		List<c2g__codaTransactionLineItem__c> updTrans = new List<c2g__codaTransactionLineItem__c>();
	
		for(c2g__codaTransactionLineItem__c t : objs) {
			String ctlkey = ascp.constructControlKey(t.c2g__GeneralLedgerAccount__c, t.c2g__Dimension1__c, t.Control__c);
			//String.valueOf(t.c2g__GeneralLedgerAccount__c).substring(0,15) + ':' + String.valueOf(t.c2g__Dimension1__c).substring(0,15) + ':' + (t.Control__c!=null ? t.Control__c.toUpperCase() : '');
			AccountScheduleControl__c ctl = ctlmap.get(ctlkey);
			if (ctl.Id!=t.AccountScheduleControl__c) updTrans.add(new c2g__codaTransactionLineItem__c(Id=t.Id, AccountScheduleControl__c=ctl.Id));
		}
		
		results += 'Number of transaction lines to update: ' + String.valueOf(updTrans.size()) + '\n\n';
		if (updTrans.size()>0 && doUpdate) Database.update(updTrans);

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
		mail.setToAddresses(new String[] { UserInfo.getUserEmail() }); 
		mail.setSubject('Batch ReBuild AccountScheduleControl complete');
		String body = 'Batch ReBuild AccountScheduleControl has completed.\n\n';
		if (!doUpdate) body += 'Test only! NOT Updated!\n\n';
		mail.setPlainTextBody(body);
		
		//Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
		//	resultcsv.setContentType('text/csv');
		//	resultcsv.setFileName('results.csv');
		//	resultcsv.setInline(false);
		//	resultcsv.Body = Blob.valueOf(results);
		//	if (!String.isBlank(results)) listOfAttachments.add(resultcsv);
		//Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
		//	upderrors.setContentType('text/plain');
		//	upderrors.setFileName('UpdateErrors.txt');
		//	upderrors.setInline(false);
		//	upderrors.Body = Blob.valueOf(errmsgs);
		//	if (!String.isBlank(errmsgs)) listOfAttachments.add(upderrors);
		//mail.setFileAttachments(listOfAttachments);
		emailMsgs.add(mail);

		Messaging.sendEmail(emailMsgs);

		// Reset to clear HEAP
		results = '';
		errmsgs = '';
		
	}

}