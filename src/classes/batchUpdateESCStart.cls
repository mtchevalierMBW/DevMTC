/**
 * batchUpdateESCStart
 * Tested by: batchUpdateESCStart_TEST
 * Date: Feb 5, 2018
 * Programmer: Bryan Leaman
 * *
 * Code coverage:
 *	2018-02-05	85% (60/71)
 * 
 * Run it now:
Database.executeBatch(new batchUpdateESCStart(null, true));
 
 */
global class batchUpdateESCStart implements Database.Batchable<sObject>, Database.Stateful {
	global final String query;
	global boolean doUpdate;
    global String errmsgs;
    //global String results;
    global Map<Id,String> resultmap;

	// BatchFixEscVehicle constructor - generate query string & initialize
	global batchUpdateESCStart(String rcdlimit, boolean doUpd) {
		doUpdate = doUpd;
		String soql = 'select Id, Name, '
			+	'dealer__Start_Date__c, dealer__Odometer_at_Sale__c, ' 
			+	'dealer__Service_Vehicle__c, dealer__Service_Vehicle__r.Name, '
			+ 	'dealer__Vehicle_Inventory__c, dealer__Customer__c, dealer__Customer_Contact__c, '
			+	'dealer__Car_Deal__c, dealer__Car_Deal__r.Name, '
			+	'dealer__Car_Deal__r.dealer__Mileage__c, dealer__Car_Deal__r.Proposed_Delivery_Date__c, '
			+	'dealer__Car_Deal__r.dealer__Service_Vehicle__c, dealer__Car_Deal__r.dealer__Status__c, '
			+	'dealer__Car_Deal__r.dealer__Service_Vehicle__r.Name, '
			+	'dealer__Car_Deal__r.dealer__Vehicle__c, dealer__Car_Deal__r.dealer__Vehicle__r.Name, ' 
			+	'dealer__Car_Deal__r.dealer__Buyer__c, dealer__Car_Deal__r.dealer__Buyer__r.Name, '
			+	'dealer__Car_Deal__r.dealer__Buyer_Contact__c, dealer__Car_Deal__r.dealer__Buyer_Contact__r.Name, '
			+	'dealer__Car_Deal__r.dealer__Deal_Type__c, '
			+ 	'dealer__Vehicle_Inventory__r.Name, dealer__Customer__r.Name, dealer__Customer_Contact__r.Name '
			+ 'from dealer__Service_Contract__c '
			+ 'where dealer__Car_Deal__c!=null and dealer__Contract_Template__c=false '
			+ ' and dealer__Car_Deal__r.dealer__Status__c in (\'Won - Posted\', \'Won - Delivered\') ';

		//if (!Test.isRunningTest()) soql += 'and (condition) ';
		//soql += 'Order by CreatedDate desc ';
		if (!String.isBlank(rcdlimit))	soql += 'Limit ' + rcdlimit + ' ';
		query = soql;
		errmsgs = '';
		//results = '';
		resultmap = new Map<Id,String>();
	}


	// start - query the database
	global Database.QueryLocator start(Database.BatchableContext bc) {
		System.debug(query);
		return Database.getQueryLocator(query);
	}


	// execute for a batch of records
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<dealer__Service_Contract__c> objs = (List<dealer__Service_Contract__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		List<dealer__Service_Contract__c> updescs = new List<dealer__Service_Contract__c>();
		for(dealer__Service_Contract__c o : objs) {
			if (o.dealer__Start_Date__c==null || o.dealer__Odometer_at_Sale__c==null || o.dealer__Odometer_at_Sale__c<2) {
				dealer__Service_Contract__c updrcd = new dealer__Service_Contract__c(
					Id = o.Id
				);
				if (o.dealer__Start_Date__c==null)
					updrcd.dealer__Start_Date__c = o.dealer__Car_Deal__r.Proposed_Delivery_Date__c; 
				if (o.dealer__Odometer_at_Sale__c==null || o.dealer__Odometer_at_Sale__c<2)
					updrcd.dealer__Odometer_at_Sale__c = o.dealer__Car_Deal__r.dealer__Mileage__c;
				updescs.add(updrcd);
				//results += 
				resultmap.put(o.Id, o.Id + ',' + o.Name + ',' + updrcd.dealer__Start_Date__c + ',' + updrcd.dealer__Odometer_at_Sale__c
					+ ',' + o.dealer__Customer__c + ',' + o.dealer__Customer_Contact__c);
			}
		}

		// Update
		System.debug('Number of records to update: ' + String.valueOf(updEscs.size()));
		
		// Do updates!
		if (updEscs.size()>0)  {
			Database.SaveResult[] saveresults = new List<Database.SaveResult>();
			if (doUpdate) saveresults = Database.update(updEscs, false); 
			//System.debug(saveresults);
			System.debug('List of failed updates:');
			//for(Database.SaveResult sr : saveresults) {
			for(Integer i=0; i<updEscs.size(); i++) {
				dealer__Service_Contract__c o = updEscs[i];
				Database.SaveResult sr = saveresults.size()>i ? saveresults[i] : null;
				if (sr!=null && !sr.isSuccess()) {
					//System.debug(sr);
					String resultline = resultmap.get(o.Id);
					String errmsg = '';
					String errmsgline = o.Id + ',' 
					+ (o.dealer__Start_Date__c!=null ? DateTime.newInstance(o.dealer__Start_Date__c, Time.newInstance(0,0,0,0)).format('yyyy-MM-dd') : '' ) + ',' 
					+ o.dealer__Odometer_at_Sale__c + ',';
					for(Database.Error de : sr.getErrors()) {
						errmsgline += '[' + String.join(de.getFields(), ', ') + '] '
							+ de.getMessage() + '\r';
						errmsg += de.getMessage() + '; ';
					}
					System.debug(errmsgline);
					errmsgs += errmsgline;
					errmsg = errmsg.replaceAll('\\s',' ');
					if (o.Id!=null && resultline!=null) resultmap.put(o.Id,resultline+',"Error:'+errmsg+'"');
				}
			}
			System.debug('List complete.');
		}
 
		// Reset results & error messages if getting too large
		if (Limits.getLimitHeapSize() - Limits.getHeapSize() < 4000000){  // if less that 1 meg left
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
		String csvheader = 'ESC Id, ESC Name, Start Date, Odometer, Customer Id, Contact Id\n';
		String errheader = 'ESC Id, Start Date, Odometer\n';
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		List<String> recipients = new List<String>{ UserInfo.getUserEmail() };
		//if (!org.isSandbox) recipients.add('another.email@mobilityworks.com');
		mail.setToAddresses(recipients); 
		System.debug(recipients);
		mail.setSubject('Batch update ESC start date mileage - UPDATES');
		String body = 'Batch update ESC start date mileage has completed.\n\n';
		if (!doUpdate) body += 'Test only! NOT Updated!\n\n';
		mail.setPlainTextBody(body);
		
		Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
			String results = String.join(resultmap.values(),'\n');
			resultcsv.setContentType('text/csv');
			resultcsv.setFileName('SvcContractResults.csv');
			resultcsv.setInline(false);
			resultcsv.Body = Blob.valueOf(csvheader + String.join(resultmap.values(),'\n'));
			if (resultmap.size()>0) listOfAttachments.add(resultcsv);
		Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
			upderrors.setContentType('text/plain');
			upderrors.setFileName('SvcContractErrors.csv');
			upderrors.setInline(false);
			upderrors.Body = Blob.valueOf(errheader + errmsgs);
			if (!String.isBlank(errmsgs)) listOfAttachments.add(upderrors);
		mail.setFileAttachments(listOfAttachments);
		emailMsgs.add(mail);

		// Only send if records were selected for processing...
		if (resultmap.size()>0 || !String.isBlank(errmsgs)) Messaging.sendEmail(emailMsgs);
		
		// Reset to clear HEAP
		//results = '';
		resultmap = new Map<Id,String>();
		errmsgs = '';
		
	}

}