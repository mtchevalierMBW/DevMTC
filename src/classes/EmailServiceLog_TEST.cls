/**
 * EmailServiceLog_TEST
 * Tests: EmailServiceLog_TEST
 * Date: Oct 19, 2017
 * Programmer: Bryan Leaman
 *
 */
@isTest
private class EmailServiceLog_TEST {

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {

		EmailServiceLog esl = new EmailServiceLog('tester-123');
		System.assert(esl.Name=='tester-123', 'test log entry name does not match');
		System.assert(esl.LastReceiptDateTime==null, 'test log entry previously existed');
		System.assert(esl.ResetDateTime!=null, 'test log entry reset timestamp was not established');
		System.assert(esl.Count==0, 'test log entry usage count was not 0 before increment');	
		esl.increment();
		System.assert(esl.Count==1, 'test log entry usage count was not 1 after increment');	
		esl.reset();
		System.assert(esl.Count==0, 'test log entry usage count was not reset');	
	}


	// massResetTest
	//---------------------------------------
	static testMethod void massResetTest() {

		EmailServiceLog esl = new EmailServiceLog('tester-123');
		esl.increment();
		EmailServiceLog.resetAll();
		for(MW_EmailServiceLog__c l : [
			select Name, Count__c, ResetDateTime__c, LastReceiptDateTime__c
			from MW_EmailServiceLog__c
			where Count__c!=0
			]) System.assert(l.Count__c==0, esl.Name + ': was not reset to 0');
	}

}