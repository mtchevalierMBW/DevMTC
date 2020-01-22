/**
 * VehicleBatchRemovePack
 * Tested by: VehicleBatchRemovePack_TEST
 * Date: Oct 10, 2016
 * Programmer: Bryan Leaman
 * Batch & Schedulable: Remove pack on any used vehicle over 120 days.
 * Note: "execute" method is defined for both batch operation and schedulable.
 *
 *	2016-11-04	B. Leaman	BLL1 - Ignore Archive and Template record types.

 * Run it now:
Database.executeBatch(new VehicleBatchRemovePack(null, true));

 * Set standard schedule:
VehicleBatchRemovePack.scheduleMe();

 * Set custom schedule:
System.schedule('VehicleBatchRemovePack', 'sec min hr day mth wd year', new VehicleBatchRemovePack(null,true));
 */
global class VehicleBatchRemovePack implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

	public static List<String> CRON_LIST = new List<String>{'0 0 7 * * ?'};	// Daily at 7:00 a.m. EST))

	global final String query;
	global boolean doUpdate;
    global String errmsgs;
    global String results;
    
	global VehicleBatchRemovePack(String rcdlimit, boolean doUpd) {
		doUpdate = doUpd;
		String soql = 
			'Select Id, Name, dealer__Pack__c, Pack_Override__c, dealer__Status_Code__c, New_Used_Other__c, Days_In_Current_Status__c, dealer__Days_In_Stock__c, dealer__Vehicle_Cost__c, Conversion_Cost__c, Total_Vehicle_Cost__c,  dealer__Store_Location__r.Name '
			+ ' From dealer__Vehicle_Inventory__c ';
		if (!Test.isRunningTest()) soql += ' where New_Used_Other__c=\'Used\' and dealer__Days_In_Stock__c>120 and dealer__Pack__c!=0 '
				+ ' and dealer__Status_Code__c=\'Ready for Sale\' '
				+ ' and RecordType.Name!=\'Vehicle Template\' and RecordType.Name!=\'Archived\' ';	// BLL1a
		soql += ' Order by CreatedDate asc ';
		if (!String.isBlank(rcdlimit))	soql += ' Limit ' + rcdlimit + ' ';
		query = soql;
		errmsgs = '';
		results = '';
	}

	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<dealer__Vehicle_Inventory__c> objs = (List<dealer__Vehicle_Inventory__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		// Update
		List<dealer__Vehicle_Inventory__c> updObjs =new List<dealer__Vehicle_Inventory__c>();
		for(dealer__Vehicle_Inventory__c o : objs) {
			// skip if pack matches pack override value
			if (o.dealer__Pack__c!=o.Pack_Override__c) {
				results += '"' + o.dealer__Store_Location__r.Name + '"' + ',"' + o.Name + '",' 
					+ '"http://mbw.my.salesforce.com/' + o.Id + '",'
					+ o.dealer__Status_Code__c + ',' + o.New_Used_Other__c + ',' + String.valueOf(o.dealer__Days_In_Stock__c)
					+ ',' + String.valueOf(o.dealer__Vehicle_Cost__c) + ',' + String.valueOf(o.Conversion_Cost__c) + ',' + String.valueOf(o.dealer__Pack__c)
					+ ',' + String.valueOf(o.Total_Vehicle_Cost__c) + '\n'; 
				updObjs.add(new dealer__Vehicle_Inventory__c(
					Id=o.Id, dealer__Pack__c=null
				));
			}
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
						errmsgs += '[' + String.join(de.getFields(),',') + '] '
							+ de.getMessage() + '\r';
					}
				}
			}
			System.debug('List complete.');
		}

	}
	
	
	global void finish(Database.BatchableContext bc) {
		Organization org = [select Id, Name, isSandbox from Organization limit 1];
		String csvheader = 'Location,Vehicle,URL,Status,New/Used/Other,Days in stock,Chassis cost,Conversion Cost,Pack,Total Vehicle Cost\n';
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String subject = 'Batch update VehicleInventory Remove Pack complete - UPDATES';
		//List<String> recipients = new List<String>();
		//if (!org.isSandbox) recipients.add('anson.cross@mobilityworks.com');
		//else recipients.add(UserInfo.getUserEmail());
		List<String> sendTo = new List<String>(Utility.getGroupMbrUserEmails('Vehicle_Remove_Pack_Used_Veh'));
		if (sendTo.size()==0 || org.isSandbox) sendTo = new List<String>{UserInfo.getUserEmail()};
		if (org.isSandbox) subject += ' from Org : ' + UserInfo.getOrganizationName();
		mail.setToAddresses(sendTo); 
		mail.setSubject(subject);
		String body = 'Batch update Vehicle Inventory Remove Pack on Used vehicles over 120 days has completed.\n\n';
		if (!doUpdate) body += 'Test only! NOT Updated!\n\n';
		mail.setPlainTextBody(body);
		
		Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
			resultcsv.setContentType('text/csv');
			resultcsv.setFileName('PackRemoved.csv');
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

		// Only send email if there were updates!
		if (!String.isBlank(results)) Messaging.sendEmail(emailMsgs);
		
	}
	

	// Schedulable context
	global void execute(SchedulableContext ctx) {
   		//CronTrigger ct = [
   		//	SELECT Id, CronExpression, TimesTriggered, NextFireTime
		//	FROM CronTrigger 
		//	WHERE Id = :ctx.getTriggerId()
		//];
		String maxrcds = Test.isRunningTest() ? '1' : null;
   	
		VehicleBatchRemovePack b = new VehicleBatchRemovePack(maxrcds, true);
		Database.executeBatch(b, 1);
	}

	// self-scheduler
	public static List<String> scheduleMe() {
		List<String> jobIds = new List<String>();
		VehicleBatchRemovePack m = new VehicleBatchRemovePack(null, true);
		Integer i = 0;
		for(String cron : VehicleBatchRemovePack.CRON_LIST) {
			System.debug(cron);
			String jobname = 'VehicleBatchRemovePack_' + String.valueOf(++i);
			if (Test.isRunningTest()) jobname += '_TEST';
			jobIds.add(System.schedule(jobname, cron, m));
		}
		return jobIds;
	}

}