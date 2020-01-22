/**
 * BatchTouchRecordsSOQL
 * Tested by: BatchTouchRecordsSOQL_TEST
 * Date: Sep 29, 2016
 * Programmer: Bryan Leaman
 *
 * Coverage: 
 *	2018-09-19	86% (53/61)
 * 
 * Issue an update to all records without changing anything for the purpose of causing a trigger to fire
 * to effect some change or other. 
 * 
 * Usage: 
 	BatchTouchRecordsSOQL ba = new BatchTouchRecordsSOQL('select Id, Name from User where Id=\''+UserInfo.getUserId+'\'', false);
	Database.executeBatch(ba);
	// sample json obj template: {"attributes":{"type":"dealer__Deal__c"},"AdministrativeUpdate__c":true}
	BatchTouchRecordsSOQL ba = new BatchTouchRecordsSOQL('select Id, Name from User where Id=\''+UserInfo.getUserId()+'\'', true,
		JSON.serialize(new User(Division='COR')));
	Database.executeBatch(ba);
 *	 
 */
global class BatchTouchRecordsSOQL implements Database.Batchable<sObject>, Database.Stateful {
    
	global final String query;
	global boolean doUpdate;
    global String errmsgs;
    global String results;
    global SObject sObjTemplate;
    global Map<String, Object> TemplateMap;
    
	global BatchTouchRecordsSOQL(String soqlstmt, boolean doUpd) {
		this(soqlstmt, doUpd, null);
	}
	global BatchTouchRecordsSOQL(String soqlstmt, boolean doUpd, String objtemplate) {
		doUpdate = doUpd;
		query = soqlstmt;
		if (!String.isBlank(objtemplate)) sObjTemplate = (SObject) JSON.deserialize(objtemplate, SObject.class);
		if (!String.isBlank(objtemplate)) TemplateMap = (Map<String,Object>) JSON.deserializeUntyped(objtemplate);
		errmsgs = '';
		results = '';
	}

	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		Set<String> ignorefields = new Set<String>{'attributes'};
		Set<String> mapfields = new Set<String>();
		if (TemplateMap!=null) mapfields = TemplateMap.keySet();
		mapfields.removeAll(ignorefields);
		
		List<SObject> objs = (List<SObject>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		// Update log
		for(SObject o : objs) {
			for(String k : mapfields) {
				try {
					o.put(k, sObjTemplate.get(k));
				} catch(Exception e) {errmsgs += 'field ' + k + ': ' + e.getMessage() + '\r';}
			}
			results += JSON.serialize(o) + '\n';
		}
		
		System.debug('Number of records to update: ' + String.valueOf(objs.size()));
		
		// Do updates!
		//if (objs.size()>0)  {
		if (objs.size()>0) {
			Database.SaveResult[] saveresults = new List<Database.SaveResult>();
			//if (doUpdate) saveresults = Database.update(objs, false);
			if (doUpdate) saveresults = Database.update(objs, false); 
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

		// If heap size getting too large, send the email now and restart the detail lists
		if (results.length() + errmsgs.length() > 10000000)	sendEmail();

	}
	
	global void sendEmail() {
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(new String[] { UserInfo.getUserEmail() }); 
		mail.setSubject('Batch update touch records complete - UPDATES');
		String body = 'Batch update touch records has completed.\n\n';
		body += 'SOQL statement:\n' + query + '\n\n';
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

		Messaging.sendEmail(emailMsgs);
		results = '';
		errmsgs = '';
	}
	
	global void finish(Database.BatchableContext bc) {
		sendEmail();
	}
	

}