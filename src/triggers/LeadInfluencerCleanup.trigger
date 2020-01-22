/**
 * LeadInfluencerCleanup
 * Tested by: InfluencerAssociationIntegrity_TEST
 * Programmer: Bryan Leaman
 * Date: 2015-10-19
 * 
 * When a lead is deleted, remove all the influencer records that reference the lead. Even though the
 * lookup field is flagged to be cleared if the lead is deleted, it's not causing a trigger to fire on the
 * InfluencerAssociation__c object to handle the delete there.
 */
trigger LeadInfluencerCleanup on Lead (before delete) {

	//List<InfluencerAssociation__c> iaList = new List<InfluencerAssociation__c>();
	Set<Id> leadIds = new Set<Id>();
	List<InfluencerAssociation2__c> ia2List = new List<InfluencerAssociation2__c>();
   
	for(Lead l : Trigger.old) leadIds.add(l.Id);

	if (leadIds.size()>0) {
		//iaList = [select Id, Name from InfluencerAssociation__c where InfluencedLead__c in :leadIds limit 2000];
		//if (iaList.size()>0) delete(iaList);
		ia2List = [select Id, Name from InfluencerAssociation2__c where InfluencedLead__c in :leadIds limit 2000];
		if (ia2List.size()>0) delete(ia2List);
	}

}