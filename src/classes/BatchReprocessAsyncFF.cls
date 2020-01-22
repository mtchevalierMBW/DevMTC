/**
 * BatchReprocessAsyncFF
 * Tested by: BatchReprocessAsyncFF_TEST
 * Date: Sep 20, 2016
 * Programmer: Bryan Leaman
 *
 *	2016-09-30	B. Leaman	BLL1 - Keep track of records processed in the batch and don't run the same
 *							action on the same record twice. Just mark as reprocessed and flag as a duplicate.
 * 
 * Run via: 
 	BatchReprocessAsyncFF ba = new BatchReprocessAsyncFF('100', true);	// process up to 100 records
 	Database.executeBatch(ba,1);	// Process them 1 at a time! (in case of varying companies)
 */
global class BatchReprocessAsyncFF implements Database.Batchable<sObject>, Database.Stateful {
    
	global final String query;
	global boolean doUpdate;
    global String errmsgs;
    global String results;
    global Set<String> processlog;	// BLL1a
    
	global BatchReprocessAsyncFF(String rcdlimit, boolean doUpd) {
		doUpdate = doUpd;

		String soql = 'select Id, Name, Action__c, Payload__c, ReprocessDateTime__c, ReprocessUser__c, SourceObjectId__c '	// BLL1c
			+ ' from FFAccountingFailure__c'
			+ ' where ReprocessDateTime__c=null and ReprocessUser__c=null';
		soql += ' Order by CreatedDate desc ';
		if (rcdlimit!=null && !String.isBlank(rcdlimit)) soql += ' Limit ' + rcdlimit + ' ';
		query = soql;
		errmsgs = '';
		results = '';
		processlog = new Set<String>();	// BLL1a
	}

	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<FFAccountingFailure__c> objs = (List<FFAccountingFailure__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		// Update
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
		mail.setSubject('Batch update Reprocess Async FF complete - UPDATES');
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
			Messaging.sendEmail(emailMsgs);
		} catch(Exception e) {}
		
	}
	

}