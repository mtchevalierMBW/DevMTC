/**
 * EmailServiceLog
 * Tested by: EmailServiceLog_TEST
 * Date: Oct 19, 2017
 * Programmer: Bryan Leaman
 * Coverage:
 *	2017-10-19	100% (28/28)
 *
 * Usage:
 * EmailServiceLog esl = new EmailServiceLog('MyEmailService');
 * esl.uptick();
 * 
 * EmailServiceLog.resetAll();
 *
 */
public with sharing class EmailServiceLog {

	public MW_EmailServiceLog__c log;
	public Decimal Count {get {return log.Count__c;} private set;}
	public DateTime LastReceiptDateTime {get {return log.LastReceiptDateTime__c;} private set;}
	public DateTime ResetDateTime {get {return log.ResetDateTime__c;} private set;}
	public String Name {get {return log.Name;} private set;}

	// EmailServiceLog
	//---------------------------------------
	public EmailServiceLog(String servicename) {
		//log = MW_EmailServiceLog.getInstance(servicename);
		List<MW_EmailServiceLog__c> logs = [
			select Id, Name, Count__c, LastReceiptDateTime__c, ResetDateTime__c 
			from MW_EmailServiceLog__c 
			where Name=:servicename
			FOR UPDATE];
		if (logs.size()>=1) log = logs[0];
		if (log==null) log = new MW_EmailServiceLog__c(
			Name=servicename, Count__c=0, LastReceiptDateTime__c=null, 
			ResetDateTime__c = DateTime.now()
		);
	}

	public void increment() {
		log.Count__c++;
		log.LastReceiptDateTime__c = DateTime.now();
		upsert(log);
		return;
	}

	public void reset() {
		log.Count__c=0;
		log.ResetDateTime__c = DateTime.now();
		upsert(log);
		return;
	}
	
	public static void resetAll() {
		for(List<MW_EmailServiceLog__c> logs : [
				select Id, Name, Count__c, ResetDateTime__c 
				from MW_EmailServiceLog__c 
				FOR UPDATE]) {
			for(MW_EmailServiceLog__c l : logs) {
				l.ResetDateTime__c = DateTime.now();
				l.Count__c = 0;
			}		
			Database.update(logs, false);
		}
		
	}

}