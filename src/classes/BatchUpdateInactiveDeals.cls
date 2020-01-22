/**
 * BatchUpdateInactiveDeals
 * Tested by: BatchUpdateInactiveDeals_TEST
 * Date: Mar 2, 2018
 * Programmer: Bryan Leaman
 * Purpose: Mark in-active proposals "Lost" after 30 days of no activity; email CMCs.
 * Inactive definition: No proposed delivery date and lastModifiedDate over 30 days old.
 *	(Question: what about still pending with a delivery date over 30 days past?)
*	// Similar Appraisal logic in BatchUpdateInactiveDeals, Deal_MBW2, DealProcess
 * 
 * Coverage:
 *	2018-03-12	87% (77/88)
 * 
 * Run it now:
Database.executeBatch(new BatchUpdateInactiveDeals(null, true), 50);

 * Set standard schedule:
BatchUpdateInactiveDeals.scheduleMe();

 * Set custom schedule:
System.schedule('BatchUpdateInactiveDeals', 'sec min hr day mth wd year', new BatchUpdateInactiveDeals(null,true));
 
 */
global class BatchUpdateInactiveDeals implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    public static final Integer DAYS_OLD = 30;
    public final Date lastChangedBefore;
	global final String query;
	global boolean doUpdate;
    global String errmsgs;
    global String results;
    public static final List<String> CRON_LIST = new List<String>{
    	'0 45 6 ? * MON-FRI *'		// 6:45 a.m. daily, Mon-Fri
    };

	global Map<String,String> emailMap;	
    
	// BatchUpdateInactiveDeals constructor - generate query string & initialize
	global BatchUpdateInactiveDeals(String rcdlimit, boolean doUpd) {
		doUpdate = doUpd;
		lastChangedBefore = Date.today().addDays(-DAYS_OLD);	// subtract days
		String soql = 
			'Select Id, Name, dealer__Deal_Type__c, dealer__Status__c, dealer__Deal_Date__c, Proposed_Delivery_Date__c, LastModifiedDate, '
			+ 'dealer__Buyer__c, dealer__Buyer__r.Name, dealer__Sales_Lead__c, dealer__Sales_Lead__r.Name, '
			+ 'dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name, dealer__Salesperson_1__r.Email, '
			+ 'dealer__Desk_Manager__c, dealer__Desk_Manager__r.Name, dealer__Desk_Manager__r.Email, '
			+ 'dealer__Store_Location__c, dealer__Store_Location__r.Name, '
			+ ' (select Id, Name from dealer__Trade_Ins__r), '
			+ ' (select Id, Name, dealer__Status__c, Lost_Reason__c, dtmob__Trade_In__c, dtmob__Trade_In__r.Name from dtmob__Appraisals__r where dealer__Status__c!=\'Lost\') ' 
			+ 'From dealer__Deal__c '
			+ 'Where dealer__Status__c=\'Pending\' '
			+ '  and RecordType.Name!=\'Commercial\' '
			+ '  and dealer__Deal_Type__c=\'Chassis/Conversion\' and Vehicle_Source__c=\'Inventory\' '
			+ '  and Proposed_Delivery_Date__c=null ';

		// don't require an old record in a test scenario!
		if (!Test.isRunningTest()) soql += '  and LastModifiedDate<:lastChangedBefore ';

		// so a single salesperson is likely to be processed all at once
		soql += 'Order by dealer__Salesperson_1__c ';	
		
		if (!String.isBlank(rcdlimit))	soql += 'Limit ' + rcdlimit + ' ';
		query = soql;
		
		emailMap = new Map<String,String>();
		errmsgs = '';
		results = '';
	}


	// start - query the database
	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);
	}

	// addEmailNotification
	// group notifications by CMC so they just get 1 email with all their automatically-closed proposals
	private void addEmailNotification(String recipient, dealer__Deal__c d) {
		String body = emailMap.get(recipient);
		if (body==null) body = 'The following proposals are being marked "Lost" due to inactivity:\n\n';
		body += 'Proposal# ' 
			+ '<a href="https://mbw.my.salesforce.com/' + d.Id + '">'+ d.Name + '</a>'  
			+ ' (' + d.dealer__Deal_Type__c + ')' + ' for ' + d.dealer__Buyer__r.Name + '\n\n'; 
		if (!String.isBlank(recipient)) emailMap.put(recipient, body);
	}

	// execute for a batch of records
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<dealer__Deal__c> objs = (List<dealer__Deal__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		MW_TriggerControls__c AppraisalsMarkLost = MW_TriggerControls__c.getInstance('AppraisalsMarkLost');
		boolean markAppraisalsLost = AppraisalsMarkLost==null || AppraisalsMarkLost.Enabled__c==true;

		// Update
		List<dealer__Deal__c> updObjs = new List<dealer__Deal__c>();
		List<dealer__Appraisal__c> updAppr = new List<dealer__Appraisal__c>();
		for(dealer__Deal__c o : objs) {
			updObjs.add(new dealer__Deal__c(
				Id=o.Id, dealer__Status__c='Lost',
				AdministrativeUpdate__c = true
			));
			addEmailNotification(o.dealer__Salesperson_1__r.Email, o);
			if (o.dealer__Salesperson_1__r.Email != o.dealer__Desk_Manager__r.Email)
				addEmailNotification(o.dealer__Desk_Manager__r.Email, o);

			// handle associated appraisals
			// Similar logic in BatchUpdateInactiveDeals, Deal_MBW2, DealProcess
			for(dealer__Appraisal__c a  : o.dtmob__Appraisals__r) {
				if (a.dealer__Status__c=='Pending') {
					updAppr.add(new dealer__Appraisal__c(
						Id = a.Id,
						dealer__Status__c = 'Lost',
						Lost_Reason__c = String.isBlank(a.Lost_Reason__c) ? 'No Activity on Appraisal' : a.Lost_Reason__c
					));
				}
			}
		}
		
		System.debug('Number of records to update: ' + String.valueOf(updObjs.size()));
		
		// Do updates!
		if (updObjs.size()>0)  {
			Database.SaveResult[] saveresults = new List<Database.SaveResult>();
			if (doUpdate && markAppraisalsLost) Database.update(updAppr, false);
			if (doUpdate) saveresults = Database.update(updObjs, false); 
			//System.debug(saveresults);
			System.debug('List of failed updates:');
			//for(Database.SaveResult sr : saveresults) {
			for(Integer i=0; i<updObjs.size(); i++) {
				dealer__Deal__c o = updObjs[i];
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
		if (Limits.getLimitHeapSize() - Limits.getHeapSize() < 1000000){  // if less that 1 meg left
			sendEmails();
		}

	}
	
	
	// finish - send results via email
	global void finish(Database.BatchableContext bc) {
		sendEmails();
	}


	// sendEmail of the results	
	global void sendEmails() {
		Organization org = [select Id, Name, isSandbox from Organization limit 1];
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		
		for(String e : emailMap.keySet()) { 
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setSubject('Proposals lost due to inactivity');
			String body = emailMap.get(e);
			if (!doUpdate) body += '\nTest only! NOT Updated!\n\n';
			if (org.isSandbox) body = 'Original recipient: ' + e + '\n\n' + body;

			List<String> recipients = new List<String>{ e };
			// in sandbox, send to person running the job instead!
			if (org.isSandbox) recipients = new List<String>{UserInfo.getUserEmail()};
			mail.setToAddresses(recipients); 
			mail.setPlainTextBody(body);
			if (recipients.size()==0) recipients.add('bryan.leaman@mobilityworks.com');
			emailMsgs.add(mail);
		}

		// Only send if records were selected for processing...
		if (emailMsgs.size()>0) Messaging.sendEmail(emailMsgs);
		
		// Reset to clear HEAP
		results = '';
		errmsgs = '';
		emailMap = new Map<String,String>();
	}


	// Schedulable context
	global void execute(SchedulableContext ctx) {
		String maxrcds = Test.isRunningTest() ? '1' : null;
   	
		BatchUpdateInactiveDeals b = new BatchUpdateInactiveDeals(maxrcds, true);
		Database.executeBatch(b, 25);
	}

	// scheduleMe self-scheduler
	public static List<String> scheduleMe() {
		List<String> jobIds = new List<String>();
		BatchUpdateInactiveDeals m = new BatchUpdateInactiveDeals(null, true);
		Integer i = 0;
		for(String cron : BatchUpdateInactiveDeals.CRON_LIST) {
			System.debug(cron);
			String jobname = 'BatchUpdateInactiveDeals_' + String.valueOf(++i);
			if (Test.isRunningTest()) jobname += '_TEST';
			jobIds.add(System.schedule(jobname, cron, m));
		}
		return jobIds;
	}


}