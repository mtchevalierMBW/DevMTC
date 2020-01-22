/**
 * c2gVerifyJournalAPI
 * Tested by: c2gVerifyJournalAPI_TEST
 * Date: Dec 5, 2017
 * Programmer: Bryan Leaman
 *
 * new c2gVerifyJournalAPI().createPostRollbackJournal();
 *
 */
public with sharing class c2gVerifyJournalAPI {

	// c2gVerifyJournalAPI
	//---------------------------------------
	public c2gVerifyJournalAPI() {
	}
	
	public void createPostRollbackJournal() {	
		String exceptioninfo = '';
		
		SavePoint sp = Database.setSavepoint();

			List<c2g__codaCompany__c> companies = FinancialForce_MBW.getMyCurrentCompanies();
		
			c2g__codaGeneralLedgerAccount__c gla = [
				select Id, Name, c2g__ReportingCode__c
				from c2g__codaGeneralLedgerAccount__c
				where c2g__ReportingCode__c='8000' 
				limit 1
			]; 
			c2g__codaDimension1__c dim1 = [
				select Id, Name, c2g__ReportingCode__c
				from c2g__codaDimension1__c
				where c2g__ReportingCode__c = '183'
				limit 1
			];
		
            c2g__codaJournal__c newj = new c2g__codaJournal__c(
            	c2g__JournalDate__c =system.today(),
            	Source__c ='GE',
            	c2g__Type__c='Manual Journal',
            	c2g__JournalStatus__c='In Progress',
            	c2g__OwnerCompany__c=companies[0].Id
            );
    
            List<c2g__codaJournalLineItem__c> newl = new List<c2g__codaJournalLineItem__c>();
            newl.add(new c2g__codaJournalLineItem__c(
            	c2g__Value__c = 1.00,
            	c2g__GeneralLedgerAccount__c = gla.Id,
            	c2g__LineType__c = 'General Ledger Account',
            	c2g__LineNumber__c = 1,
            	Control__c = 'VerifyJournalAPI',
            	c2g__Dimension1__c = dim1.Id
            )); 
            newl.add(new c2g__codaJournalLineItem__c(
            	c2g__Value__c = -1.00,
            	c2g__GeneralLedgerAccount__c = gla.Id,  
            	c2g__LineType__c = 'General Ledger Account', 
            	c2g__LineNumber__c = 2,
            	Control__c = 'VerifyJournalAPI',
            	c2g__Dimension1__c = dim1.Id
			));
            
			try {
				System.debug(newj);
				System.debug(newl);
            	Id journalId = FinancialForce_MBW.createJournalApi(newj, newl);
            	System.debug(newj);
            	c2g.CODAAPICommon.Reference ref = new c2g.CODAAPICommon.Reference();
            	ref.Id = journalId;
            	c2g.CODAAPIJournal_9_0.PostJournal(null, ref);
            	System.debug('Posted');
			} catch(Exception e) {
				System.debug('Operation failed');
           		exceptioninfo = e.getTypeName() + ' : ' + e.getMessage() + '\n' 
           			+ e.getStackTraceString();
           		System.debug(exceptioninfo);
			}
		
		System.debug('Rollback initiated');
		Database.rollback(sp);
		System.debug('Rollback completed');
		
		String subject = 'c2gVerifyJournalAPI completed '
			+ (String.isBlank(exceptioninfo) ? 'successfully' : 'with errors');
		String msgbody = ''; 
		if (String.isBlank(exceptioninfo)) msgbody = 'Test journal created and posted fine.';
		else msgbody = exceptioninfo;

		List<Messaging.SingleEmailMessage> emails=new List<Messaging.SingleEmailMessage>();
		Messaging.SingleEmailMessage em = new Messaging.SingleEmailMessage();
		em.setToAddresses(new String[] {UserInfo.getUserEmail()});
		em.setSubject(subject);
		em.setPlainTextBody(msgbody);
		emails.add(em);
		Messaging.sendEmail(emails);		

	}

}