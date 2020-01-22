/**
 * ReversingJournal_TEST
 * Tests: JournalCustom, JournalLineReferences
 * 
 * Uses seeAllData=true because I've been unable to create a reversing journal in a test.
 * Always get an error that the only kind of journal allowed in the context is a manual journal.
 *
 * 2017-02-28	B. Leaman	BLL1 - select journal from current authorized company for running user.
 */
@isTest
private class ReversingJournal_TEST {

    // BLL2a
    @isTest(seeAllData=true) 
    static void triggerReversingJournalTriggers() {
    	MW_TriggerControls__c reversingJournal = MW_TriggerControls__c.getInstance('ReversingJournal');
    	if (reversingJournal==null) 
    		insert(new MW_TriggerControls__c(Name='ReversingJournal',Enabled__c=true));
    	else {
    		reversingJournal.Enabled__c=true;
    		update(reversingJournal);
    	}
    	
    	// BLL1a Authorized company
    	List<c2g__codaCompany__c> mycomps = FinancialForce_MBW.getMyAuthorizedCompanies();
    	//Id compid = null;
    	//if (mycomps.size()>0) compid = mycomps[0].Id;
    	Set<Id> compids = new Set<Id>();
    	for(c2g__codaCompany__c c : mycomps) compids.add(c.Id); 
    	
        List<c2g__codaJournal__c> j = [
        	select Id, c2g__OwnerCompany__c from c2g__codaJournal__c
        	where (c2g__Type__c='Reversing Journal' or c2g__Type__c='Cancelling Journal')
        	  and (c2g__SourceJournal__c!=null or c2g__OriginalJournal__c!=null)  
        	  and c2g__OwnerCompany__c in :compids	// BLL1a
        	order by c2g__OwnerCompany__c, CreatedDate desc limit 2
        ];
        if (j.size()>1 && j[0].c2g__OwnerCompany__c!=j[1].c2g__OwnerCompany__c) j.remove(1);
        if (j.size()>0) update(j);
        
        List<c2g__codaJournalLineItem__c> l = [
        	select Id, c2g__OwnerCompany__c from c2g__codaJournalLineItem__c 
        	where (c2g__Journal__r.c2g__Type__c='Reversing Journal' or c2g__Journal__r.c2g__Type__c='Cancelling Journal')
        	  and (c2g__Journal__r.c2g__SourceJournal__c!=null or c2g__Journal__r.c2g__OriginalJournal__c!=null) 
        	  and c2g__OwnerCompany__c in :compids	// BLL1a
        	order by c2g__OwnerCompany__c, CreatedDate desc limit 2];
        if (l.size()>1 && l[0].c2g__OwnerCompany__c!=l[1].c2g__OwnerCompany__c) l.remove(1);
        if (l.size()>0) update(l);
        
        Set<Id> jids = new Set<Id>();
        for(c2g__codaJournal__c jrn : j) jids.add(jrn.Id); 
        TransactionLineProcess.FixReversingJournalLineRefs(jids);
        TransactionLineProcess.FixReversingTransactionLineRefs(jids);
    }
    // BLL2a end

}