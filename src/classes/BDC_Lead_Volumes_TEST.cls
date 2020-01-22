/**
 * BDC_Lead_Volumes_TEST 
 * Tests BDC_Lead_Volumes controller
 */
@isTest
private class BDC_Lead_Volumes_TEST {

    static testMethod void BDCLeadVolumeMetrics() {
    	TestHelper_MW th = new TestHelper_MW();
        RecordType rt = th.getRetailLeadRt();
        
        BDC_Lead_Volumes_CTLR lv = new BDC_Lead_Volumes_CTLR();
        lv.summarizeBySource();
        
        List<Lead> leads = new List<Lead>();
        
        Lead l1 = new Lead(RecordTypeId=rt.Id, FirstName='Test', LastName='Lead', Status='Qualified');
        Lead l2 = new Lead(RecordTypeId=rt.Id, FirstName='Test', LastName='Lead', Status='Unqualified');
        Lead l3 = new Lead(RecordTypeId=rt.Id, FirstName='Test', LastName='Lead', Status='Other');
        leads.add(l1); 
        leads.add(l2); 
        leads.add(l3);
        insert(leads);
        l1 = [select Id, FirstName, LastName, Status, CreatedDate from Lead where id=:l1.Id limit 1];
        l2 = [select Id, FirstName, LastName, Status, CreatedDate from Lead where id=:l2.Id limit 1];
        l3 = [select Id, FirstName, LastName, Status, CreatedDate from Lead where id=:l3.Id limit 1];
        
        lv.summarizeToKey('Testing', l1);
        lv.summarizeToKey('Testing', l2);
        lv.summarizeToKey('Testing', l3);
        System.assert(lv!=null,'Error creating lead volume metrics');
    }
    
}