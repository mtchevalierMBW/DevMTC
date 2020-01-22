/**
 * BatchUpdateVehicleMediaCDN
 * Tested by: BatchUpdateVehicleMediaCDN_TEST
 * Date: Jun 20, 2017
 * Programmer: Bryan Leaman
 *
 * https://s3.amazonaws.com/vehicle-images/	961c3a8d-f1b2-4ae2-9b5d-ab1fdf2de1a3.JPG
 * https://invcdn.dealerteam.com/			961c3a8d-f1b2-4ae2-9b5d-ab1fdf2de1a3.JPG
 *
 * https://s3.amazonaws.com/vehicle-images/	961c3a8d-f1b2-4ae2-9b5d-ab1fdf2de1a3_thumb.JPG
 * https://invcdn.dealerteam.com/			961c3a8d-f1b2-4ae2-9b5d-ab1fdf2de1a3_thumb.JPG
 * 
 * Run it now:
Database.executeBatch(new BatchUpdateVehicleMediaCDN(null, true));

 */
global class BatchUpdateVehicleMediaCDN implements Database.Batchable<sObject>, Database.Stateful {
    
	global final String query;
	global boolean doUpdate;
    global String errmsgs;
    global String results;
    

	// BatchUpdateVehicleMediaCDN constructor - generate query string & initialize
	global BatchUpdateVehicleMediaCDN(String rcdlimit, boolean doUpd) {
		doUpdate = doUpd;
		String soql = 
			'Select Id, Name, dealer__Image_URL__c, dealer__CDNURL__c, dealer__Thumbnail_URL__c, dealer__CDNThumbnailURL__c '
			+ 'From dealer__Inventory_Images__c ';
		if (!Test.isRunningTest()) soql += 'Where dealer__CDNURL__c=null or dealer__CDNThumbnailURL__c=null ';
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
		List<dealer__Inventory_Images__c> objs = (List<dealer__Inventory_Images__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		String s3host = 'https://s3.amazonaws.com/vehicle-images/';
		String cdnhost = 'https://invcdn.dealerteam.com/';

		// Update
		List<dealer__Inventory_Images__c> updObjs =new List<dealer__Inventory_Images__c>();
		for(dealer__Inventory_Images__c media : objs) {
				System.debug(media);
				if (media.dealer__CDNURL__c==null 
					&& media.dealer__Image_URL__c!=null 
					&& media.dealer__Image_URL__c.startsWith(s3host)) 
					media.dealer__CDNURL__c = cdnhost + media.dealer__Image_URL__c.removeStart(s3host);
				if (media.dealer__CDNThumbnailURL__c==null
					&& media.dealer__Thumbnail_URL__c!=null 
					&& media.dealer__Thumbnail_URL__c.startsWith(s3host)) 
					media.dealer__CDNThumbnailURL__c = cdnhost + media.dealer__Thumbnail_URL__c.removeStart(s3host);
			
				updObjs.add(new dealer__Inventory_Images__c(
					Id=media.Id,
					dealer__CDNURL__c=media.dealer__CDNURL__c,
					dealer__CDNThumbnailURL__c=media.dealer__CDNThumbnailURL__c
				));
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
				dealer__Inventory_Images__c o = updObjs[i];
				Database.SaveResult sr = saveresults.size()>i ? saveresults[i] : null;
				if (sr!=null && !sr.isSuccess()) {
					//System.debug(sr);
					String errmsg = o.Id + ',' + o.Name + ': ';
					for(Database.Error de : sr.getErrors()) {
						errmsg += '[' + String.join(de.getFields(), ', ') + '] '
							+ de.getMessage() + '\r';
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
		if (!String.isBlank(results) || !String.isBlank(errmsgs)) Messaging.sendEmail(emailMsgs);
		
		// Reset to clear HEAP
		results = '';
		errmsgs = '';
		
	}

}