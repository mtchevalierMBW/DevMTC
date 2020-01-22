/**
 * BatchUpdateROLiftInfo
 * Tested by: BatchUpdateROLiftInfo_TEST
 * Date: 2019-12-05
 * Programmer: Bryan Leaman
 * Project: W-000787
 *
 * Coverage:
 *	2019-12-05	87%	(74/85)
 *
 * Modifications: 
 *
 * Run it now:
Database.executeBatch(new BatchUpdateROLiftInfo(null, true));

 */
 global class BatchUpdateROLiftInfo implements Database.Batchable<sObject>, Database.Stateful {

	global final String query;
	global boolean doUpdate;
	global Map<String,String> errormap;
	global Map<String,String> resultmap;


	// BatchUpdateROLiftInfo constructor - generate query string & initialize
	global BatchUpdateROLiftInfo(String rcdlimit, boolean doUpd) {
		doUpdate = doUpd;
		String soql = 
			'Select Id, Name, Lift_MFG__c, dealer__Lift_MFG__c, Lift_Serial_Number__c, dealer__Lift_Serial_Number__c, '
			+ 'Lift_Model__c, dealer__Lift_Model__c, Lift_Cycle_Count__c, dealer__Lift_Cycle_Count__c '
			+ 'From dealer__Service_Repair_Order__c '
			+ 'Where Lift_MFG__c!=null or Lift_Model__c!=null or Lift_Serial_Number__c!=null ';
		soql += 'Order by CreatedDate desc ';
		if (!String.isBlank(rcdlimit)) soql += 'Limit ' + rcdlimit + ' ';
		query = soql;
		errormap = new Map<String, String>();
		resultmap = new Map<String, String>();
	}


	// start - query the database
	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);
	}

	// execute for a batch of records
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<dealer__Service_Repair_Order__c> objs = (List<dealer__Service_Repair_Order__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		// Update
		List<dealer__Service_Repair_Order__c> updObjs =new List<dealer__Service_Repair_Order__c>();
		for(dealer__Service_Repair_Order__c o : objs) {
			dealer__Service_Repair_Order__c updObj = new dealer__Service_Repair_Order__c(
				Id=o.Id
			);
			if (!String.isBlank(o.Lift_MFG__c)) updObj.dealer__Lift_MFG__c=o.Lift_MFG__c;
			if (!String.isBlank(o.Lift_Model__c)) updObj.dealer__Lift_Model__c=o.Lift_Model__c;
			if (!String.isBlank(o.Lift_Serial_Number__c)) updObj.dealer__Lift_Serial_Number__c=o.Lift_Serial_Number__c;
			if (o.Lift_Cycle_Count__c!=null && o.Lift_Cycle_Count__c!=0) updObj.dealer__Lift_Cycle_Count__c=o.Lift_Cycle_Count__c;
			updObj.Lift_MFG__c = null;
			updObj.Lift_Model__c = null;
			updObj.Lift_Serial_Number__c = null;
			updObj.Lift_Cycle_Count__c = null;
			updObjs.add(updObj);
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
				dealer__Service_Repair_Order__c o = updObjs[i];
				String resultstring = String.join(new List<String>{o.Id, o.Name, 
					o.dealer__Lift_MFG__c, 
					o.dealer__Lift_Model__c, 
					o.dealer__Lift_Serial_Number__c, 
					String.valueOf(o.dealer__Lift_Cycle_Count__c)
					}, ','); 
				String sts = 'Posted'; 
				String errmsg = '';
				Database.SaveResult sr = saveresults.size()>i ? saveresults[i] : null;
				if (sr!=null && sr.isSuccess()) {
					resultmap.put(o.Id, resultstring + ',"' + sts + '"'); 
				} else if (sr!=null) { 
					//System.debug(sr);
					String errmsgline = o.Id + ',' + o.Name + ': ';
					for(Database.Error de : sr.getErrors()) {
						errmsgline += '[' + String.join(de.getFields(), ', ') + '] '
							+ de.getMessage() + '';
						errmsg += de.getMessage() + '; ';
					}
					System.debug(errmsgline);
					errmsg += errmsgline;
					errmsg = errmsg.replaceAll('\\s',' ');
					if (o.Id!=null && resultstring!=null) resultmap.put((String) o.Id, resultstring+',"Error:'+errmsg+'"');
					if (o.Id!=null && resultstring!=null) errormap.put((String) o.Id, resultstring+',"Error:'+errmsg+'"');
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
		//Organization org = [select Id, Name, isSandbox from Organization limit 1];
		Organization org = OrganizationSingleton.getInstance();
		String csvheader = 'Id,Name,Lift MFG, Lift Model, Lift Serial, Lift Cycle Count\n';
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		List<String> recipients = new List<String>{ UserInfo.getUserEmail() };
		//if (!org.isSandbox) recipients.add('another.email@mobilityworks.com');
		mail.setToAddresses(recipients); 
		mail.setSubject('Batch update RO Lift Info complete - UPDATES');
		String body = 'Batch update RO Lift Info has completed.\n\n';
		if (!doUpdate) body += 'Test only! NOT Updated!\n\n';
		mail.setPlainTextBody(body);

		Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
			resultcsv.setContentType('text/csv');
			resultcsv.setFileName('results.csv');
			resultcsv.setInline(false);
			resultcsv.Body = Blob.valueOf(csvheader + String.join(resultmap.values(),'\n'));
			if (resultmap.size()>0) listOfAttachments.add(resultcsv);
		Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
			upderrors.setContentType('text/csv');
			upderrors.setFileName('UpdateErrors.csv');
			upderrors.setInline(false);
			upderrors.Body = Blob.valueOf(csvheader + String.join(errormap.values(),'\n'));
			if (errormap.size()>0) listOfAttachments.add(upderrors);
		mail.setFileAttachments(listOfAttachments);
		emailMsgs.add(mail);

		// Only send if records were selected for processing...
		if (resultmap.size()>0 || errormap.size()>0) Messaging.sendEmail(emailMsgs);
		
		// Reset to clear HEAP
		resultmap = new Map<String,String>();
		errormap = new Map<String,String>();
		
	}


}