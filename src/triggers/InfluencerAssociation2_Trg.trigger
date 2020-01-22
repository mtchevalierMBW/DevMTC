/**
 * InfluencerAssociation2_Trg
 * Tested by: InfluencerAssociation_TEST
 * Programmer: Bryan Leaman
 * Date: July 6, 2018
 *
 *
**/

trigger InfluencerAssociation2_Trg on InfluencerAssociation2__c (before insert, before update) {
	Set<Id> contactIds = new Set<Id>();
	
	// List of contacts being specified
	for(InfluencerAssociation2__c ia : Trigger.new) {
		if (ia.InfluencerContact__c!=null) contactIds.add(ia.InfluencerContact__c);
	}   

	// Get associated account for each contact (if there is one)
	Map<Id,Contact> contactMap = new Map<Id,Contact>();
	if (contactIds.size()>0) contactMap = new Map<Id,Contact>([
		select Id, AccountId
		from Contact
		where Id in :contactIds
	]);
	
	// Assign associated account based on contact's account (if not already specified)
	for(InfluencerAssociation2__c ia : Trigger.new) {
		Contact c;
		if (ia.InfluencerContact__c!=null && contactMap.containsKey(ia.InfluencerContact__c)) c = contactMap.get(ia.InfluencerContact__c); 
		if (ia.InfluencerAccount__c==null && c!=null) ia.InfluencerAccount__c = c.AccountId;
	}
	
}