/**
 * InfluencerAssociation_Test
 * Test: InfluencerAssociation_Trg, AccountProcess
 * Programmer: Bryan Leaman
 * Date: 2018-07-06
 * 
 * Ensure association is deleted if the influenced account is removed (null). The records will
 * already by removed if the influencer is deleted, since that is a master-detail relationship.
 *
 */
@isTest
private class InfluencerAssociation_Test {

	static testMethod void emptytest() {
		
	}

/**
    static testMethod void removeInfluencedAccount() {
    	// BLL1a
		Map<String, Schema.RecordTypeInfo> IARcdTypes = Schema.SObjectType.InfluencerAssociation2__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo LeadIaRti = IARcdTypes.get('Lead');
		Schema.RecordTypeInfo AcctIaRti = IARcdTypes.get('Account');
		Id LeadIaRtId = LeadIaRti.getRecordTypeId();
		Id AcctIaRtId = AcctIaRti.getRecordTypeId();
		// BLL1a end
		
		TestHelper_MW th = new TestHelper_MW();
		
        Account master = th.getInfluencerAccount('1');
        Account person  = th.getPersonAccount('1');
        
        InfluencerAssociation2__c ia = new InfluencerAssociation2__c(RecordTypeId=AcctIaRtId, InfluencerAccount__c=master.id, InfluencedAccount__c=person.id);
        
        Test.startTest();
        insert(ia);
        delete(person);
        Test.stopTest();
        
        List<InfluencerAssociation2__c> iaList = [
           select Name, InfluencerAccount__c, InfluencedAccount__c
           from InfluencerAssociation2__c
           where InfluencerAccount__c=:master.id
        ];
        
        System.assert(iaList.size()==0, 'Influencer association was not removed when influenced account was deleted.');
        if (iaList.size()>0) {
        	System.debug(iaList[0]);
        }
    }

    static testMethod void missingInfluencedAccount() {
    	// BLL1a
		Map<String, Schema.RecordTypeInfo> IARcdTypes = Schema.SObjectType.InfluencerAssociation2__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo LeadIaRti = IARcdTypes.get('Lead');
		Schema.RecordTypeInfo AcctIaRti = IARcdTypes.get('Account');
		Id LeadIaRtId = LeadIaRti.getRecordTypeId();
		Id AcctIaRtId = AcctIaRti.getRecordTypeId();
		// BLL1a end

		TestHelper_MW th = new TestHelper_MW();
		
        Account master = th.getInfluencerAccount('1');
        
        InfluencerAssociation2__c ia = new InfluencerAssociation2__c(RecordTypeId=AcctIaRtId, InfluencerAccount__c=master.id);
        
        Test.startTest();
        try {
        	insert(ia);
        } catch(Exception e) {
        	System.debug(e.getMessage());
        }
        Test.stopTest();
        
        List<InfluencerAssociation2__c> iaList = [
           select Name, InfluencerAccount__c, InfluencedAccount__c
           from InfluencerAssociation2__c
           where InfluencerAccount__c=:master.id
        ];
        
        System.assert(iaList.size()==0, 'Influencer association was created with no influenced account specified.');
    }

   	// BLL1a
    static testMethod void InfluencerForLead() {
		Map<String, Schema.RecordTypeInfo> IARcdTypes = Schema.SObjectType.InfluencerAssociation2__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo LeadIaRti = IARcdTypes.get('Lead');
		Schema.RecordTypeInfo AcctIaRti = IARcdTypes.get('Account');
		Id LeadIaRtId = LeadIaRti.getRecordTypeId();
		Id AcctIaRtId = AcctIaRti.getRecordTypeId();

		TestHelper_MW th = new TestHelper_MW();
		
        Account master = th.getInfluencerAccount('1');
        Lead l = new Lead(FirstName='TestLead', LastName='Leader', Phone='(212) 555-1229');
        insert(l);
        InfluencerAssociation2__c ia = new InfluencerAssociation2__c(RecordTypeId=LeadIaRtId, InfluencerAccount__c=master.id, InfluencedLead__c=l.Id);
        
        Test.startTest();
        insert(ia);
        Test.stopTest();
        
        List<InfluencerAssociation2__c> iaList = [
           select Name, InfluencerAccount__c, InfluencedAccount__c
           from InfluencerAssociation2__c
           where InfluencerAccount__c=:master.id
        ];
        
        System.assert(iaList.size()==1, 'Influencer association was NOT created for a lead.');
    }


    static testMethod void removeInfluencedLead() {
    	// BLL1a
		Map<String, Schema.RecordTypeInfo> IARcdTypes = Schema.SObjectType.InfluencerAssociation2__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo LeadIaRti = IARcdTypes.get('Lead');
		Schema.RecordTypeInfo AcctIaRti = IARcdTypes.get('Account');
		Id LeadIaRtId = LeadIaRti.getRecordTypeId();
		Id AcctIaRtId = AcctIaRti.getRecordTypeId();
		// BLL1a end
		
		TestHelper_MW th = new TestHelper_MW();
		
        Account master = th.getInfluencerAccount('1');
        Lead l = new Lead(FirstName='TestLead', LastName='Leader', Phone='(212) 555-1229');
        insert(l);
        InfluencerAssociation2__c ia = new InfluencerAssociation2__c(RecordTypeId=LeadIaRtId, InfluencerAccount__c=master.id, InfluencedLead__c=l.Id);
        
        Test.startTest();
        insert(ia);
        delete(l);
        Test.stopTest();
        
        List<InfluencerAssociation2__c> iaList = [
           select Name, InfluencerAccount__c, InfluencedLead__c
           from InfluencerAssociation2__c
           where InfluencerAccount__c=:master.id
        ];
        
        System.assert(iaList.size()==0, 'Influencer association was not removed when influenced lead was deleted.');
        if (iaList.size()>0) {
        	System.debug(iaList[0]);
        }
    }
	// BLL1a end
**/
}